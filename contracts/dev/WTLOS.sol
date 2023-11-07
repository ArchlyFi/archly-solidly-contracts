// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

contract WTLOS {
    string public name     = "Wrapped TLOS";
    string public symbol   = "WTLOS";
    uint8  public decimals = 18;

    uint256 public constant ERR_NO_ERROR = 0x0;

    // Error Code: Non-zero value expected to perform the function.
    uint256 public constant ERR_INVALID_ZERO_VALUE = 0x01;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

    }

    receive() external payable {
        deposit();
    }
    function deposit() public payable returns (uint256) {
        if (msg.value == 0) {
            return ERR_INVALID_ZERO_VALUE;
        }
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
        return ERR_NO_ERROR;
    }

    function withdraw(uint wad) public returns (uint256) {
        if (wad == 0) {
            return ERR_INVALID_ZERO_VALUE;
        }

        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
        return ERR_NO_ERROR;
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}