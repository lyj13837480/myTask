// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StudyERC20 {

    mapping(address account => uint256 amount) private  balances;//账户余额
    mapping(address account => mapping(address spender => uint256)) private _allowances; //授权代扣额度
    uint256 private _totalSupply;//总货币量
    string private name = "MyToken";
    string private symbol = "MKT";
    address private _owner;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initTotalSupply){
        _totalSupply = initTotalSupply;
        _owner = msg.sender;
    }

    function getOwner() public view returns (address){
        return _owner;
    }

    function mint(address account,uint256 value) public  {
        require(account == _owner,"not owner");
        balances[_owner] += value;
        _totalSupply += value;
    }

    function totalSupply() external view  returns   (uint256){
        return _totalSupply;
    }

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external  view returns (uint256){
         return balances[account];
    }

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external  returns (bool){
        require(balances[msg.sender] >= value,"Insufficient balance");
        balances[msg.sender] -=value;
        balances[to] +=value;
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view  returns (uint256){
         return _allowances[owner][spender];
    }

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) public  returns (bool){
        require(value < type(uint256).max,"value is great than max");
        _allowances[msg.sender][spender] = value;
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
        require(balances[from] >= value,"Insufficient balance");
        balances[from] -= value;
        balances[from] -= value;
        balances[to] += value;
        return false;
    }

}