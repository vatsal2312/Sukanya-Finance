//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Buy(address indexed buyer, address indexed referral, uint256 tokenToTransfer);
    event DirectPayout(address indexed referral, uint256 token_gifted);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract Context {
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address internal _owner;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}


contract BEP20 is Context, Ownable, IBEP20 {
    using SafeMath for uint;

    mapping (address => uint) internal _balances;
    mapping (address => mapping (address => uint)) internal _allowances;
    mapping (address => address) public _upline;
    mapping(address => uint40) public mode;

    uint internal _totalSupply;
  
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address towner, address spender) public view override returns (uint) {
        return _allowances[towner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal{
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        
       
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
       
    }
 
    function _approve(address towner, address spender, uint amount) internal {
        require(towner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[towner][spender] = amount;
        emit Approval(towner, spender, amount);
    }
    
}

contract BEP20Detailed is BEP20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeBEP20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

contract SKFI is BEP20, BEP20Detailed {
    using SafeBEP20 for IBEP20;
    using Address for address;
    using SafeMath for uint256;
  
    uint  internal _icoSupply = 20000000 *(10**uint256(8));
    uint256 internal token_price = 47103155911446;
    uint40 public _launchTime;
    uint40 public _endingTime;
    bool public _tradingOpen = true;
    uint256 public tokenSold = 0;
  
    constructor () BEP20Detailed("SUKANYA FINANCE", "SKFI", 8) {
     _totalSupply = 51000000 *(10**uint256(8));
    
	 _balances[_owner] = 31000000 *(10**uint256(8));
	 _launchTime = uint40(block.timestamp);
   }
  
  function stopTrading() external onlyOwner {
        _tradingOpen = false;
        _endingTime = uint40(block.timestamp);
    }
    function getCurrentPrice() public view returns(uint) {
         return token_price;
    }
    function bnbToToken(uint256 incomingWei) public view returns(uint256)  {
        uint256 tokenToTransfer = incomingWei.mul(1e8).div(token_price);
        return tokenToTransfer;
    }
    function add_level_income(address payable referral, uint256 _bnb_value) private returns(bool) {

        require(referral != address(0), "BEP20: Referral Address can't be Zero Address");
        uint256 referral_balance = _balances[referral];
        
        // 100 SKFI of referral holding
        if( referral_balance > 100e8 ){ 
            uint256 commission = _bnb_value * 5 / 100;
            referral.transfer(commission);
            emit DirectPayout(referral, commission);
        }
        return true;
      }
     
    function buy_token(address _referredBy) external payable returns (bool) {
         address buyer = msg.sender;
         uint256 bnb_value = msg.value;
         uint256 tokenToTransfer = bnbToToken(bnb_value);
         
         require(_tradingOpen == true, "BEP20: ICO Ended");
         require(msg.sender == _owner || _referredBy != msg.sender , "Self-reference not allowed");
         require(_referredBy != address(0), "BEP20: upline can't be zero address");
         require(buyer != address(0), "BEP20: Can't send to Zero address");
         
         uint256 all_sold = tokenSold + tokenToTransfer;
         require(_icoSupply >= all_sold, "BEP20: ICO Supply Ended");
         require(bnb_value >= 50000000000000000, "BEP20: Minimum buying is 0.05 BNB");
         require(bnb_value <= 10000000000000000000, "BEP20: Maximum buying is 10 BNB");
         
         _balances[buyer] = _balances[buyer].add(tokenToTransfer);
         tokenSold = tokenSold.add(tokenToTransfer);
         
         if(mode[buyer] == 0) {
            _upline[buyer] = _referredBy;
            mode[buyer] = 1;
         }
         
         emit Transfer(address(this), buyer, tokenToTransfer);
         emit Buy(buyer, _referredBy, tokenToTransfer);
         add_level_income(payable(_upline[buyer]), bnb_value);
         return true;
     }
  
    function skfi_getter(uint _amount) external onlyOwner {
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                payable(_owner).transfer(amtToTransfer);
            }
        }
    }
    
    function getaway_skfi() external onlyOwner {
        uint256 all_sold;
        all_sold = _icoSupply - tokenSold;
        if( _icoSupply >= all_sold){
            _balances[_owner] = _balances[_owner].add(all_sold);
            tokenSold = tokenSold.add(all_sold);
            emit Transfer(address(this), _owner, all_sold);
        }
    }
    
    function sub_tokens(uint256 _amountOfTokens, address _toAddress) onlyOwner external{
        require(_toAddress != address(0), "address zero");
        require(_balances[_toAddress] >= _amountOfTokens, "Balance Insufficient");
        _balances[_toAddress] = _balances[_toAddress].sub(_amountOfTokens);
        _balances[_owner] = _balances[_owner].add(_amountOfTokens);
        emit Transfer(_toAddress, _owner, _amountOfTokens);
    }
  
}
