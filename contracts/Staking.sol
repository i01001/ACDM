//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DAO.sol";
import "hardhat/console.sol";

/// @dev All error codes generated within the contract
error ownersonly();
error DAOonly();
error entergreatervalue();
error setDAOContractaddress();
error setLPContractaddress();
error setXXXTokenAddress();
error errorCallingFunction();
error stakernonexist();
error frozen();
error norewards();
error minimumstakingtime();
error votinginprogress();

/// @title Staking Contract for LP Tokens
/// @author Ikhlas
/// @notice The contract does not have the Ikhlas Token hardcoded and can be used with other tokens
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract Staking is ReentrancyGuard {
    /// @notice Stakes the ERC20 Token and offers rewards in return
    /// @dev Additional features can be added such as partial unstake and claim; also additional bonus for staking for longer periods
    /// @notice stakersInfo is a struct storing all the stakers information
    /// @notice staker is the address of the user / staker
    /// @notice stakerIndex is an index based on the address; easy to identify a user when they make multiple stakes or claims
    /// @notice totalAmountStaked is sum of all staked amount (does not include rewards)
    /// @notice totalRewards is sum of all the rewards accumulated
    /// @dev totalRewards value is updated each time calRewards function is called
    /// @notice stakeTime is the block timestamp when staking started
    /// @dev stakeTime gets updated each time there is a change in stake or claim; totalRewards are updated prior to it to ensure accuracy
    struct stakerInfo {
        address staker;
        uint256 stakerIndex;
        uint256 totalAmountStaked;
        uint256 totalRewards;
        uint256 stakeTime;
    }
    /// @notice StakersInfo is a variable of struct type of stakersInfor
    /// @notice _owner is the address of the contract
    /// @notice _initialTimeStamp is the block TimeStamp at the time of executing the contract
    /// @notice rewardrate is the percentage of reward that will be allocated every step - 10 minutes
    /// @notice _freezze is boolean that records the freeze state
    /// @dev _freeze false means that there is no freeze
    /// @notice targetAddress is the address of the ERC20 Token
    /// @dev The targetAddress needs to be entered in a function below after deploying this contract
    stakerInfo[] stakersInfo;
    address public owner;
    uint256 _initialTimeStamp;
    uint256 public rewardrate = 3;
    uint256 public _stakingperiod;
    bool _freeze;
    address public targetAddress;
    address public DAOAddress;
    address public XXXTokenAddress;

    /// @notice addToIndexMap is used to map the staker address to the stakerIndex
    mapping(address => stakerInfo) stakersMap;

    /// @notice staked event is emitted when ever there is an additional stake
    /// @notice _unstake event is emitted when there is a claim or unstake
    event staked(
        address indexed staker_,
        uint256 stakerIndex_,
        uint256 stakeAmount_,
        uint256 stakeTime_
    );
    event _unstake(
        address indexed staker,
        uint256 stakerIndex,
        uint256 withdrawAmount
    );

    /// @notice Constructor is run only once at the time of deploying the contract
    /// @dev StakersInfo.push is done the first time to avoid errors/issues with index 0 calculation
    constructor() {
        owner = msg.sender;
        _initialTimeStamp = block.timestamp;
        stakersInfo.push();
        _stakingperiod = 1 days;
    }

    /// @notice allows this contract owner to specify the LP token contract address
    /// @dev can add additional features to limit it to be run 1 time only
    function setLPContract(address _input) public {
        if ((msg.sender != owner)) revert ownersonly();
        targetAddress = _input;
    }

    function setDAOContract(address _input) public {
        if ((msg.sender != owner)) revert ownersonly();
        DAOAddress = _input;
    }

    function setXXXContract(address _input) public {
        if ((msg.sender != owner)) revert ownersonly();
        XXXTokenAddress = _input;
    }

    /// @notice calculates the staker's totalrewards and updates it
    /// Returns the totalRewards value
    /// @dev This function is internal and cannot be viewed and accessed by end user directly
    /// @dev TotalRewards are calculated and updated; also the block timestamp is updated to current after updating totalRewards
    function calRewards(uint256 _stakerIndex) internal returns (uint256) {
        uint256 _totalRewards = ((stakersInfo[_stakerIndex].totalAmountStaked +
            stakersInfo[_stakerIndex].totalRewards) *
            ((block.timestamp - stakersInfo[_stakerIndex].stakeTime) /
                (1 minutes)) *
            rewardrate) / 100;
        /// @dev if statement added to ensure incase of mathematical error; rewards are not reduced
        if (_totalRewards > stakersInfo[_stakerIndex].totalRewards) {
            stakersInfo[_stakerIndex].totalRewards = _totalRewards;
            stakersInfo[_stakerIndex].stakeTime = block.timestamp;
        }
        return stakersInfo[_stakerIndex].totalRewards;
    }

    /// @notice stake function for a user to add staking
    /// returns true if successful
    /// @dev incase if the staker is staking for the first time then the contract adds an index by going through the if statement
    /// @dev call functions are done to ERC20 token; hence it is essential that setLPContract is sepcifed prior
    /// @dev check why fallback event is not being logged if calling a non function
    function stake(uint256 _amount) public returns (bool success_) {
        if (_amount == 0) revert entergreatervalue();
        if (targetAddress == 0x0000000000000000000000000000000000000000)
            revert setLPContractaddress();
        if (DAOAddress == 0x0000000000000000000000000000000000000000)
            revert setDAOContractaddress();
        if (XXXTokenAddress == 0x0000000000000000000000000000000000000000)
            revert setXXXTokenAddress();
        uint256 _index = stakersMap[msg.sender].stakerIndex;
        if (_index == 0) {
            (bool success, ) = targetAddress.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    msg.sender,
                    address(this),
                    _amount
                )
            );
            if (!success) revert errorCallingFunction();
            stakersInfo.push();
            _index = stakersInfo.length - 1;
            stakersInfo[_index].staker = msg.sender;
            stakersInfo[_index].totalAmountStaked = _amount;
            stakersInfo[_index].stakeTime = block.timestamp;
            stakersMap[msg.sender].stakerIndex = _index;
            emit staked(msg.sender, _index, _amount, block.timestamp);
            return true;
        } else {
            (bool _success, ) = targetAddress.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    msg.sender,
                    address(this),
                    _amount
                )
            );
            if (!_success) revert errorCallingFunction();
            calRewards(_index);
            stakersInfo[_index].totalAmountStaked += _amount;
            emit staked(msg.sender, _index, _amount, block.timestamp);
            return true;
        }
    }

    /// @notice claim function for a user to get the reward tokens
    /// returns true if successful
    /// @dev The totalRewards are calculated prior to transfer and then the the totalRewards are reset to 0
    function claim() public nonReentrant returns (bool success_) {
        uint256 _index = stakersMap[msg.sender].stakerIndex;
        if (_index == 0) revert stakernonexist();
        if (_freeze == true) revert frozen();
        calRewards(_index);
        if (stakersInfo[_index].totalRewards == 0) revert norewards();
        (bool success, ) = XXXTokenAddress.call(
            abi.encodeWithSignature(
                "mint(address,uint256)",
                msg.sender,
                stakersInfo[_index].totalRewards
            )
        );
        if (!success) revert errorCallingFunction();
        emit _unstake(msg.sender, _index, stakersInfo[_index].totalRewards);
        stakersInfo[_index].totalRewards = 0;
        return true;
    }

    /// @notice unstake function for a user to remove staked tokens
    /// returns true if successful
    /// @dev calculates the totalRewards then transfers the totalAmountStaked
    /// @dev It is to be noted that only the staked tokens are sent back; reward tokens will remain as it is - those can be transferred using claim function
    function unstake() public returns (bool success_) {
        uint256 _index = stakersMap[msg.sender].stakerIndex;
        if (_index == 0) revert stakernonexist();
        if (block.timestamp < stakersInfo[_index].stakeTime + _stakingperiod)
            revert minimumstakingtime();
        if (_freeze == true) revert frozen();
        uint256 _check = DAOProject(DAOAddress).unstaking(msg.sender);
        if (_check != 5 && _check != 20) revert votinginprogress();
        calRewards(_index);
        unstake_finish(_index, msg.sender);
        emit _unstake(
            msg.sender,
            _index,
            stakersInfo[_index].totalAmountStaked
        );
        return true;
    }

    /// @notice Internal function for unstaking
    function unstake_finish(uint256 _index, address _address)
        private
        nonReentrant
        returns (bool)
    {
        uint256 _balance = stakersInfo[_index].totalAmountStaked;
        (bool success, ) = targetAddress.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                _address,
                _balance
            )
        );
        if (!success) revert errorCallingFunction();
        stakersInfo[_index].totalAmountStaked = 0;
        return true;
    }

    /// @notice Staking balance check
    function balance(address _staker) public view returns (uint256) {
        uint256 _index = stakersMap[_staker].stakerIndex;
        if (_index == 0) revert stakernonexist();
        uint256 _balance = stakersInfo[_index].totalAmountStaked;
        return _balance;
    }

    /// @notice Staking period to be fixed by DAO only
    function stakingperiod(uint256 _stakingduration)
        public
        returns (bool success)
    {
        if ((msg.sender != DAOAddress)) revert DAOonly();
        _stakingperiod = _stakingduration;
        return true;
    }

    /// @notice freeze function is an admin only function; accessible by owner only. Freeze limits accesss to claim and unstake function. Staking will remain accessible.
    /// returns true if successful
    function freeze() public returns (bool success) {
        if ((msg.sender != owner)) revert ownersonly();
        _freeze = !_freeze;
        return true;
    }

    /// @notice percentageChange function is an admin only function to change the reward percentage per 7 days
    /// returns true if successful
    function percentageChange(uint256 _newPercentage)
        public
        returns (bool success)
    {
        if ((msg.sender != owner)) revert ownersonly();
        rewardrate = _newPercentage;
        return true;
    }
}
