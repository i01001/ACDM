//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DAO.sol";
import "./ACDMToken.sol";
import "./Uniswap.sol";
import "./XXXCoin.sol";


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


contract ACDMPlatform {
    using Counters for Counters.Counter;

Counters.Counter public round; 
Counters.Counter public orderNumber;

address public ACDMTokenContract;
address public XXXTokenContract;
address public DAOContract;
address public _owner;
uint public tradeRefOnePer;
uint public tradeRefTwoPer;
uint public saleRefOnePer;
uint public saleRefTwoPer;
uint public currentRoundEndTime;
uint public lastTradeETH;
uint public currentPrice;
uint public saleSupply;
uint public specialBalance;
address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

struct traders {
    address trader;
    address refereOne;
    address refereTwo;
}

struct orders {
    uint _orderNumber;
    address seller;
    uint tokenQuantity;
    uint ethAmount;
}

mapping (address => traders) public Traders;
mapping (uint => orders) public Orders;

enum roundStatus {
    NONE,
    SALE,
    TRADE
    }

roundStatus public Mode;

event Log(string _function, address _sender, uint256 _value, bytes _data);
event Rec(string _function, address _sender, uint256 _value);


constructor (address _ACDMToken, address _XXXToken, address _DAOContract){
    _owner = msg.sender;
    ACDMTokenContract = _ACDMToken;
    XXXTokenContract = _XXXToken;
    DAOContract = _DAOContract;
    saleRefOnePer = 500;
    saleRefTwoPer = 300;
    tradeRefOnePer = 250;
    tradeRefTwoPer = 250;
}


function register (address _refere) public {
    if(_refere == msg.sender)
    revert invalidrefere();
    Traders[msg.sender] = traders (
        msg.sender,
        _refere,
        Traders[_refere].refereOne
    );
}

function nextMode () public {
    if(msg.sender != _owner)
    revert ownerOnly();
    if(currentRoundEndTime > block.timestamp)
    revert roundinprogress();
    if(Mode == roundStatus.NONE){
        Mode = roundStatus.SALE;
        sale();
    }
    else if(Mode == roundStatus.SALE){
        Mode = roundStatus.TRADE;
    }
    else if(Mode == roundStatus.TRADE){
        Mode = roundStatus.SALE;
        sale();
    }
    currentRoundEndTime = block.timestamp + (3*24*60*60);
}


function sale () private {
    if(round.current() == 0){
        saleSupply =   100000000000;
        currentPrice = 10000000000000;
    }
    else{
        ACDMToken(ACDMTokenContract).burn(address(this), saleSupply);
        saleSupply = lastTradeETH / currentPrice;
        currentPrice = (currentPrice * 103 / 100) + 4000000000000;
        lastTradeETH = 0;
    }
    ACDMToken(ACDMTokenContract).mint(address(this), saleSupply);
    round.increment();
}


function buy () public payable {
    if(Mode == roundStatus.SALE){
        if(msg.value == 0)
        revert incorrectValue();
        if(currentRoundEndTime < block.timestamp)
        revert timeUp();
        uint _orderVol = msg.value *1000000 / currentPrice;
        if(_orderVol > saleSupply){
            uint _balance = (_orderVol - saleSupply) * currentPrice;
            payable(msg.sender).transfer(_balance);
            if(Traders[msg.sender].refereOne != 0x0000000000000000000000000000000000000000)
            payable(Traders[msg.sender].refereOne).transfer(_balance*saleRefOnePer/10000);
            if(Traders[msg.sender].refereTwo != 0x0000000000000000000000000000000000000000)
            payable(Traders[msg.sender].refereTwo).transfer(_balance*saleRefTwoPer/10000);
            ACDMToken(ACDMTokenContract).transfer(msg.sender, _balance);
            saleSupply -= _balance;
        }
        else{
            if(Traders[msg.sender].refereOne != 0x0000000000000000000000000000000000000000)
            payable(Traders[msg.sender].refereOne).transfer(msg.value*saleRefOnePer/10000);
            if(Traders[msg.sender].refereTwo != 0x0000000000000000000000000000000000000000)
            payable(Traders[msg.sender].refereTwo).transfer(msg.value*saleRefTwoPer/10000);
            ACDMToken(ACDMTokenContract).transfer(msg.sender, _orderVol);
            saleSupply -= _orderVol;
        }
        if(saleSupply == 0){
        currentRoundEndTime = block.timestamp - 1;
    }
    }
    else
        revert invalidmode();
}

function createOrder (uint _tokenQuantity, uint _ethAmount) public {
    if(Mode == roundStatus.TRADE){
    if(currentRoundEndTime < block.timestamp)
    revert timeUp();
    ACDMToken(ACDMTokenContract).transferFrom(msg.sender, address(this), _tokenQuantity);
    Orders[orderNumber.current()] = orders(
        orderNumber.current(),
        msg.sender,
        _tokenQuantity,
        _ethAmount
    );
    orderNumber.increment();
    }
    else
        revert invalidmode();
}

function redeemOrder (uint _orderNumber) public payable {
    if(Mode == roundStatus.TRADE){
    if(currentRoundEndTime < block.timestamp)
    revert timeUp();
    if(msg.value == 0)
    revert incorrectValue();
    if(msg.value > Orders[_orderNumber].ethAmount)
    revert incorrectValue();
    uint purchaseQuantity = msg.value * (Orders[_orderNumber].tokenQuantity) / (Orders[_orderNumber].ethAmount);
    lastTradeETH += msg.value;
    Orders[_orderNumber].tokenQuantity -= purchaseQuantity;
    Orders[_orderNumber].ethAmount -= msg.value; 
    ACDMToken(ACDMTokenContract).transfer(msg.sender, purchaseQuantity);
    payable(Orders[_orderNumber].seller).transfer(msg.value*(100-((tradeRefOnePer + tradeRefTwoPer)/100))/100);
    if(Traders[Orders[_orderNumber].seller].refereOne != 0x0000000000000000000000000000000000000000)
    payable(Traders[Orders[_orderNumber].seller].refereOne).transfer(msg.value*tradeRefOnePer/10000);
    else
    specialBalance += msg.value*tradeRefOnePer/10000;
    if(Traders[Orders[_orderNumber].seller].refereTwo != 0x0000000000000000000000000000000000000000)
    payable(Traders[Orders[_orderNumber].seller].refereTwo).transfer(msg.value*tradeRefTwoPer/10000);
    else
    specialBalance += msg.value*tradeRefTwoPer/10000;
    }
    else
        revert invalidmode();
}

function cancelOrder (uint _orderNumber) public {
    if(currentRoundEndTime < block.timestamp)
    revert timeUp();
    if(Mode == roundStatus.TRADE){
    if(msg.sender != Orders[_orderNumber].seller)
    revert notSeller();
    ACDMToken(ACDMTokenContract).transfer(msg.sender, Orders[_orderNumber].tokenQuantity);
    Orders[_orderNumber].tokenQuantity = 0;
    Orders[_orderNumber].ethAmount = 0;
    }
    else
        revert invalidmode();
}

function tradeReferrerOneParam (uint _param) public {
    if(msg.sender != DAOContract)
    revert DAOonly();
    tradeRefOnePer = _param;
}

function tradeReferrerTwoParam (uint _param) public {
    if(msg.sender != DAOContract)
    revert DAOonly();
    tradeRefTwoPer = _param;
}

function saleReferrerOneParam (uint _param) public {
    if(msg.sender != DAOContract)
    revert DAOonly();
    saleRefOnePer = _param;
}

function saleReferrerTwoParam (uint _param) public {
    if(msg.sender != DAOContract)
    revert DAOonly();
    tradeRefTwoPer = _param;
}

function tradeComissionOwner () public {
    if(msg.sender != DAOContract)
    revert DAOonly();
    if(specialBalance == 0)
    revert noBalance();
    payable(_owner).transfer(specialBalance);
    specialBalance = 0;
}

function tradeComissionBurnToken () public {
    if(msg.sender != DAOContract)
    revert DAOonly();
    if(specialBalance == 0)
    revert noBalance();

    address[] memory path = new address[](2);
    path[0] = WETH;
    path[1] = XXXTokenContract;
    uint256[] memory amounts = IUniswapV2Router(ROUTER).swapExactETHForTokens{value: specialBalance}(0, path, address(this), block.timestamp + 100);
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