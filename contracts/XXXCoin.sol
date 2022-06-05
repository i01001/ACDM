//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

error owneronly();

contract XXXToken is ERC20 {

    address public Staking;
    address public owner;

    constructor() ERC20("XXXCoin", "XXX"){
        owner = msg.sender;
    }

    function setStakingaddress (address _input) public {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        Staking = _input;
    }

    function mint(address _account, uint _amount) public {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        _mint(_account, _amount);
    }

    function burn(address _account, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        _burn(_account, _amount);
    }

    function _transferFrom(address _from, address _to, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        transferFrom(_from, _to, _amount);
    }

    function _transfer(address _to, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert owneronly();
        transfer( _to, _amount);
    }
}


    