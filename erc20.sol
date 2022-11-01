// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

contract SolicyCoinERC20 is ERC20 {
    mapping(address => uint256) balances;
    mapping(address => bool) blackList;
    uint8 _decimal;
    uint8 _fee;
    address public owner;
    uint256 totalSupply_;

    string public constant name = "Solicy";
    string public constant symbol = "Sol";
    uint8 public constant decimals = 18;

    constructor(uint256 total, uint8 __decimal, uint8 __fee) ERC20("Solicy", "SOL"){
        owner = msg.sender;
        _decimal = __decimal;
        _fee = __fee;
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
        _mint(msg.sender, 10 ** 10);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier tockenOwner {
        require(balances[msg.sender] > 0);
        _;
    }

    function addToBlackList(address user) external {
        blackList[user] = true;
    }

    function delFromBlackList(address user) external {
        delete blackList[user];
    }

    function burn(address account, uint256 amount) external virtual {
        _burn(account, amount);
    }

    function mint() pure public {
        require(false, "Mint action blocked in this contract");
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(!blackList[recipient], "some message");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function decimals() public view override returns (uint8) {
        return _decimal;
    }

    function setFee(uint8 fee) public {
        require(msg.sender == owner, "Ownable: You are not the owner, Bye.");
        _fee = fee;
    }
}
