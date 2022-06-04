//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

error ownersonly();

contract ACDMToken is ERC20 {

    address public Platform;
    address public owner;

    constructor() ERC20("ACADEM Coin", "ACDM"){
        owner = msg.sender;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function setACDMPlatformaddress (address _input) public {
        if((msg.sender != owner) && (msg.sender != Platform))
            revert ownersonly();
        Platform = _input;
    }

    function mint(address _account, uint _amount) public {
        if((msg.sender != owner) && (msg.sender != Platform))
            revert ownersonly();
        _mint(_account, _amount);
    }

    function burn(address _account, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != Platform))
            revert ownersonly();
        _burn(_account, _amount);
    }

    function _transferFrom(address _from, address _to, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != Platform))
            revert ownersonly();
        transferFrom(_from, _to, _amount);
    }

    function _transfer(address _to, uint _amount) public  {
        if((msg.sender != owner) && (msg.sender != Platform))
            revert ownersonly();
        transfer( _to, _amount);
    }
}


    