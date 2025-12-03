// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StudyERC20 {

    mapping(address account => uint256 amount) private  _balances;//账户余额
    mapping(address account => mapping(address spender => uint256)) private _allowances; //授权代扣额度
    uint256 private _totalSupply;//总货币量
    string private _name = "MyToken";
    string private _symbol = "MKT";
    address private _owner ;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initTotalSupply){
        _totalSupply = initTotalSupply;
        _owner = msg.sender;
        _balances[_owner] = initTotalSupply;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function getOwner() public view returns (address){
        return _owner;
    }

    function mint(address account,uint256 value) public  {
        require(account == _owner,"not owner");
        _balances[_owner] += value;
        _totalSupply += value;
    }

    function totalSupply() external view  returns   (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) external  view returns (uint256){
         return _balances[account];
    }

    function transfer(address to, uint256 value) external  returns (bool){
        require(_balances[msg.sender] >= value,"Insufficient balance");
        _balances[msg.sender] -=value;
        _balances[to] +=value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view  returns (uint256){
         return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public  returns (bool){
        require(value < type(uint256).max,"value is great than max");
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool){
        require(_allowances[from][msg.sender] >=value,"Approve insufficient balance" );
        require(_balances[from] >= value,"Insufficient balance");
        _balances[from] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
        return false;
    }

}