//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error ownersonly();

contract XXXToken is ERC20 {

    address public Staking;
    address public owner;

    constructor() ERC20("XXXCoin", "XXX"){
        owner = msg.sender;
    }

    function setStakingaddress (address _input) public {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert ownersonly();
        Staking = _input;
    }

    function mint(address _account, uint _amount) public {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert ownersonly();
        _mint(_account, _amount);
    }

    function burn(address _account, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert ownersonly();
        _burn(_account, _amount);
    }

    function _transferFrom(address _from, address _to, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert ownersonly();
        transferFrom(_from, _to, _amount);
    }

    function _transfer(address _to, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != Staking))
            revert ownersonly();
        transfer( _to, _amount);
    }
}


    