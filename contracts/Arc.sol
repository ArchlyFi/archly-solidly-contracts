// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.22;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract Arc is Ownable2Step, Pausable {

    string public constant symbol = "Arc";
    string public constant name = "Archly";
    string constant public version = "2.0.0";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    mapping(address => bool) public minters;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        minters[msg.sender] = true;
        _mint(msg.sender, 0);
    }
    
    function pause() public onlyOwner
    {
        _pause();
    }
    
    function unpause() public onlyOwner
    {
        _unpause();
    }

    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
    }
    
    function removeMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
    }

    function approve(address _spender, uint _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint(address _to, uint _amount) internal returns (bool) {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }
    
    function _burn(address _from, uint _amount) internal returns (bool) {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0x0), _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        balanceOf[_from] -= _value;
        
        if(_to == address(0x0)) {
            totalSupply -= _value;
        } else {
            balanceOf[_to] += _value;
        }
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external whenNotPaused returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) external whenNotPaused returns (bool) {
        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function mint(address account, uint amount) external whenNotPaused returns (bool) {
        require(minters[msg.sender], 'Must be called by a minter');
        _mint(account, amount);
        return true;
    }
    
    function burn(uint amount) external whenNotPaused returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        _burn(msg.sender, amount);
        return true;
    }
}
