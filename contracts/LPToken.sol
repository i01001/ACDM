//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

error owneronly();

/// @title LPTokens Contract only for simulating LP Tokens
/// @author Ikhlas
/// @notice The contract does not have the front end implemented
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract LPToken is ERC20 {
    address public Staking;
    address public owner;

    /// @notice Constructor
    constructor() ERC20("LPToken", "LP") {
        owner = msg.sender;
    }

    function setStakingaddress(address _input) public {
        if ((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        Staking = _input;
    }

    function mint(address _account, uint256 _amount) public {
        if ((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        if ((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        _burn(_account, _amount);
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        if ((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        transferFrom(_from, _to, _amount);
    }

    function _transfer(address _to, uint256 _amount) public {
        if ((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        transfer(_to, _amount);
    }
}
