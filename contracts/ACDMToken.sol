//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

error Ownersonly();

/// @title ACDMToken Contract for ACDM Token 
/// @author Ikhlas
/// @notice The contract does not have the front end implemented
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract ACDMToken is ERC20 {
    address public Platform;
    address public owner;

/// @notice Constructor 
    constructor() ERC20("ACADEM Coin", "ACDM") {
        owner = msg.sender;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function setACDMPlatformaddress(address _input) public {
        if ((msg.sender != owner) && (msg.sender != Platform))
            revert Ownersonly();
        Platform = _input;
    }

    function mint(address _account, uint256 _amount) public {
        if ((msg.sender != owner) && (msg.sender != Platform))
            revert Ownersonly();
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        if ((msg.sender != owner) && (msg.sender != Platform))
            revert Ownersonly();
        _burn(_account, _amount);
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        if ((msg.sender != owner) && (msg.sender != Platform))
            revert Ownersonly();
        transferFrom(_from, _to, _amount);
    }

    function _transfer(address _to, uint256 _amount) public {
        if ((msg.sender != owner) && (msg.sender != Platform))
            revert Ownersonly();
        transfer(_to, _amount);
    }
}
