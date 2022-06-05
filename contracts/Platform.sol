//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DAO.sol";
import "./ACDMToken.sol";
import "./Uniswap.sol";
import "./XXXCoin.sol";

/// @dev All error codes generated within the contract
error invalidrefere();
error invalidentry();
error roundinprogress();
error invalidmode();
error ownerOnly();
error incorrectValue();
error cannotSellinSaleMode();
error timeUp();
error notSeller();
error noBalance();

/// @title ACDM Platform for trading in ADCM Tokens via Sale and Trade Mode
/// @author Ikhlas
/// @notice The contract does not have the front end implemented
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract ACDMPlatform {
    using Counters for Counters.Counter;

/// @notice Counters used for counting round and the order numbers 
    Counters.Counter public round;
    Counters.Counter public orderNumber;


/// @notice ACDMTokenContract - ACDM Token contract
/// @notice XXXTokenContract - XXXToken Contract
/// @notice DAOContract - DAO Contract
/// @notice _owner - Owner address
/// @notice tradeRefOnePer - Trade referer 1 percentage 
/// @notice tradeRefTwoPer - Trade referer 2 percentage
/// @notice saleRefOnePer - Sale referer 1 percentage
/// @notice saleRefTwoPer - Sale referer 2 percentage
/// @notice currentRoundEndTime - current round time limit
/// @notice lastTradeETH - previous trade value in ETH
/// @notice currentPrice - round trade price
/// @notice saleSupply - Sale Round maximum quantity 
/// @notice specialBalance - Trade special comission account
/// @notice FACTORY - uniswap Factory
/// @notice ROUTER - uniswap Router
/// @notice WETH - address of WETH
    address public ACDMTokenContract;
    address public XXXTokenContract;
    address public DAOContract;
    address public _owner;
    uint256 public tradeRefOnePer;
    uint256 public tradeRefTwoPer;
    uint256 public saleRefOnePer;
    uint256 public saleRefTwoPer;
    uint256 public currentRoundEndTime;
    uint256 public lastTradeETH;
    uint256 public currentPrice;
    uint256 public saleSupply;
    uint256 public specialBalance;
    address private constant FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

/// @notice Traders record with referer 
    struct traders {
        address trader;
        address refereOne;
        address refereTwo;
    }

/// @notice Orders records with order number, tokens and ETH
    struct orders {
        uint256 _orderNumber;
        address seller;
        uint256 tokenQuantity;
        uint256 ethAmount;
    }

    mapping(address => traders) public Traders;
    mapping(uint256 => orders) public Orders;

/// @notice Round Status mode
    enum roundStatus {
        NONE,
        SALE,
        TRADE
    }

    roundStatus public Mode;

/// @notice Events 
    event Log(string _function, address _sender, uint256 _value, bytes _data);
    event Rec(string _function, address _sender, uint256 _value);

/// @notice Constructor with inputs of token contracts
    constructor(
        address _ACDMToken,
        address _XXXToken,
        address _DAOContract
    ) {
        _owner = msg.sender;
        ACDMTokenContract = _ACDMToken;
        XXXTokenContract = _XXXToken;
        DAOContract = _DAOContract;
        saleRefOnePer = 500;
        saleRefTwoPer = 300;
        tradeRefOnePer = 250;
        tradeRefTwoPer = 250;
    }

/// @notice Register of users on platform with refere
    function register(address _refere) public {
        if (_refere == msg.sender) revert invalidrefere();
        Traders[msg.sender] = traders(
            msg.sender,
            _refere,
            Traders[_refere].refereOne
        );
    }

/// @notice To start the next mode - SALE / TRADE
    function nextMode() public {
        if (msg.sender != _owner) revert ownerOnly();
        if (currentRoundEndTime > block.timestamp) revert roundinprogress();
        if (Mode == roundStatus.NONE) {
            Mode = roundStatus.SALE;
            sale();
        } else if (Mode == roundStatus.SALE) {
            Mode = roundStatus.TRADE;
        } else if (Mode == roundStatus.TRADE) {
            Mode = roundStatus.SALE;
            sale();
        }
        currentRoundEndTime = block.timestamp + (3 * 24 * 60 * 60);
    }

/// @notice Sale round internal functions for noticeeters
    function sale() private {
        if (round.current() == 0) {
            saleSupply = 100000000000;
            currentPrice = 10000000000000;
        } else {
            ACDMToken(ACDMTokenContract).burn(address(this), saleSupply);
            saleSupply = lastTradeETH / currentPrice;
            currentPrice = ((currentPrice * 103) / 100) + 4000000000000;
            lastTradeETH = 0;
        }
        ACDMToken(ACDMTokenContract).mint(address(this), saleSupply);
        round.increment();
    }

/// @notice Sale round - For purchasing tokens 
    function buy() public payable {
        if (Mode == roundStatus.SALE) {
            if (msg.value == 0) revert incorrectValue();
            if (currentRoundEndTime < block.timestamp) revert timeUp();
            uint256 _orderVol = (msg.value * 1000000) / currentPrice;
            if (_orderVol > saleSupply) {
                uint256 _balance = ((_orderVol - saleSupply) * currentPrice) /
                    1000000;
                uint256 _order = (saleSupply * currentPrice) / 1000000;
                payable(msg.sender).transfer(_balance);
                if (
                    Traders[msg.sender].refereOne !=
                    0x0000000000000000000000000000000000000000
                )
                    payable(Traders[msg.sender].refereOne).transfer(
                        (_order * saleRefOnePer) / 10000
                    );
                if (
                    Traders[msg.sender].refereTwo !=
                    0x0000000000000000000000000000000000000000
                )
                    payable(Traders[msg.sender].refereTwo).transfer(
                        (_order * saleRefTwoPer) / 10000
                    );
                ACDMToken(ACDMTokenContract).transfer(msg.sender, saleSupply);
                saleSupply = 0;
            } else {
                if (
                    Traders[msg.sender].refereOne !=
                    0x0000000000000000000000000000000000000000
                )
                    payable(Traders[msg.sender].refereOne).transfer(
                        (msg.value * saleRefOnePer) / 10000
                    );
                if (
                    Traders[msg.sender].refereTwo !=
                    0x0000000000000000000000000000000000000000
                )
                    payable(Traders[msg.sender].refereTwo).transfer(
                        (msg.value * saleRefTwoPer) / 10000
                    );
                ACDMToken(ACDMTokenContract).transfer(msg.sender, _orderVol);
                saleSupply -= _orderVol;
            }
            if (saleSupply == 0) {
                currentRoundEndTime = block.timestamp - 1;
            }
        } else revert invalidmode();
    }

/// @notice Trade round - For creating orders
    function createOrder(uint256 _tokenQuantity, uint256 _ethAmount) public {
        if (Mode == roundStatus.TRADE) {
            if (currentRoundEndTime < block.timestamp) revert timeUp();
            ACDMToken(ACDMTokenContract).transferFrom(
                msg.sender,
                address(this),
                _tokenQuantity
            );
            Orders[orderNumber.current()] = orders(
                orderNumber.current(),
                msg.sender,
                _tokenQuantity,
                _ethAmount
            );
            orderNumber.increment();
        } else revert invalidmode();
    }

/// @notice Trade round - For redeeming orders
    function redeemOrder(uint256 _orderNumber) public payable {
        if (Mode == roundStatus.TRADE) {
            if (currentRoundEndTime < block.timestamp) revert timeUp();
            if (msg.value == 0) revert incorrectValue();
            if (msg.value > Orders[_orderNumber].ethAmount)
                revert incorrectValue();
            uint256 purchaseQuantity = (msg.value *
                (Orders[_orderNumber].tokenQuantity)) /
                (Orders[_orderNumber].ethAmount);
            lastTradeETH += msg.value;
            Orders[_orderNumber].tokenQuantity -= purchaseQuantity;
            Orders[_orderNumber].ethAmount -= msg.value;
            ACDMToken(ACDMTokenContract).transfer(msg.sender, purchaseQuantity);
            payable(Orders[_orderNumber].seller).transfer(
                (msg.value *
                    (100 - ((tradeRefOnePer + tradeRefTwoPer) / 100))) / 100
            );
            if (
                Traders[Orders[_orderNumber].seller].refereOne !=
                0x0000000000000000000000000000000000000000
            )
                payable(Traders[Orders[_orderNumber].seller].refereOne)
                    .transfer((msg.value * tradeRefOnePer) / 10000);
            else specialBalance += (msg.value * tradeRefOnePer) / 10000;
            if (
                Traders[Orders[_orderNumber].seller].refereTwo !=
                0x0000000000000000000000000000000000000000
            )
                payable(Traders[Orders[_orderNumber].seller].refereTwo)
                    .transfer((msg.value * tradeRefTwoPer) / 10000);
            else specialBalance += (msg.value * tradeRefTwoPer) / 10000;
        } else revert invalidmode();
    }

/// @notice Trade round - For cancelling orders
    function cancelOrder(uint256 _orderNumber) public {
        if (currentRoundEndTime < block.timestamp) revert timeUp();
        if (Mode == roundStatus.TRADE) {
            if (msg.sender != Orders[_orderNumber].seller) revert notSeller();
            ACDMToken(ACDMTokenContract).transfer(
                msg.sender,
                Orders[_orderNumber].tokenQuantity
            );
            Orders[_orderNumber].tokenQuantity = 0;
            Orders[_orderNumber].ethAmount = 0;
        } else revert invalidmode();
    }

/// @notice Changing refere parameters - can only be done by DAO
    function tradeReferrerOneParam(uint256 _param) public {
        if (msg.sender != DAOContract) revert DAOonly();
        tradeRefOnePer = _param;
    }

/// @notice Changing refere parameters - can only be done by DAO
    function tradeReferrerTwoParam(uint256 _param) public {
        if (msg.sender != DAOContract) revert DAOonly();
        tradeRefTwoPer = _param;
    }

/// @notice Changing refere parameters - can only be done by DAO
    function saleReferrerOneParam(uint256 _param) public {
        if (msg.sender != DAOContract) revert DAOonly();
        saleRefOnePer = _param;
    }

/// @notice Changing refere parameters - can only be done by DAO
    function saleReferrerTwoParam(uint256 _param) public {
        if (msg.sender != DAOContract) revert DAOonly();
        tradeRefTwoPer = _param;
    }

/// @notice Trade comission to send to owner - can be done by DAO
    function tradeComissionOwner() public {
        if (msg.sender != DAOContract) revert DAOonly();
        if (specialBalance == 0) revert noBalance();
        payable(_owner).transfer(specialBalance);
        specialBalance = 0;
    }

/// @notice Trade comission to purchase XXXTokens and burn it - can be done by DAO
    function tradeComissionBurnToken() public {
        if (msg.sender != DAOContract) revert DAOonly();
        if (specialBalance == 0) revert noBalance();

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = XXXTokenContract;
        uint256[] memory amounts = IUniswapV2Router(ROUTER)
            .swapExactETHForTokens{value: specialBalance}(
            0,
            path,
            address(this),
            block.timestamp + 100
        );
        XXXToken(XXXTokenContract).burn(address(this), amounts[1]);
        specialBalance = 0;
    }

    fallback() external payable {
        emit Log("fallback message failed", msg.sender, msg.value, msg.data);
    }

    receive() external payable {
        emit Rec("fallback message failed", msg.sender, msg.value);
    }
}
