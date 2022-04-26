// SPDX-License-Identifier: MIT

import './interfaces/IBEP20.sol';
import './libs/safe-math.sol';
import './libs/ownable.sol';

pragma solidity ^0.6.6;

contract MFuelToken is IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) _isExcludedFromFee;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    address public pool;
    address public pair;

    uint constant denominator = 100;
    uint public sellFee = 0;

    constructor() public {
        _name = "MetaFuel";
        _symbol = "MFUEL";
        _decimals = 18;
        _totalSupply = 1000000000 * 10 ** 18;
        _balances[msg.sender] = _totalSupply;
        pool = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function decimals() override external view returns (uint8) {
        return _decimals;
    }

    function symbol() override external view returns (string memory) {
        return _symbol;
    }

    function name() override external view returns (string memory) {
        return _name;
    }

    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) override external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) override external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) override external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    function mint(address account, uint256 amount) external onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        uint256 _amount;
        if (recipient == pair) {
            _amount = _beforeTokenTransfer(sender, recipient, amount);
        } else {
            _amount = amount;
        }

        _balances[sender] = _balances[sender].sub(_amount, "Transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(_amount);
        emit Transfer(sender, recipient, _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual returns (uint)  {
        uint fee = amount.sub(calculateFee(from, to, amount));
        if (fee > 0) {
            _balances[from] = _balances[from].sub(fee, "Transfer amount exceeds balance");
            _balances[pool] = _balances[address(pool)].add(fee);
            emit Transfer(from, address(pool), fee);
        }
        return calculateFee(from, to, amount);
    }

    function calculateFee(address _from, address _to, uint256 _amount) internal view returns (uint amount_without_fee){
        if (_isExcludedFromFee[_from] || _isExcludedFromFee[_to]) {
            return _amount;
        }
        return _amount.sub(_amount.mul(sellFee).div(denominator));
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function excludeFromFee(address account) external onlyOwner {
        emit ExcludeFromFee(account);
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        emit IncludeInFee(account);
        _isExcludedFromFee[account] = false;
    }


    function setSellFee(uint _number) external onlyOwner {
        require(_number <= denominator, "Sell fee great than 100");
        emit SetSellFee(_number);
        sellFee = _number;
    }

    function setPool(address _pool) external onlyOwner {
        require(_pool != address(0), "Pair address is zero");
        emit SetPool(_pool);
        pool = _pool;
    }

    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "Pair address is zero");
        emit SetPair(_pair);
        pair = _pair;
    }

    /* ========== EVENTS ========== */

    event ExcludeFromFee(address indexed account);
    event IncludeInFee(address indexed account);
    event SetPool(address indexed pool);
    event SetPair(address indexed pair);
    event SetSellFee(uint indexed number);
}
