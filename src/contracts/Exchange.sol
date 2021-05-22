pragma solidity ^0.5.0;

import "./Token.sol";
import "./Owned.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Exchange is Owned {
    using SafeMath for uint;

    mapping(address => mapping(address => uint256)) public tokens;
    address constant ETHER = address(0); // store Ether in tokens mapping with blank address

    uint256 public ratio; // 1 이더당 원화 비율
    mapping(uint256 => _ExOrder) public exOrders;
    uint256 public exOrderCount;
    mapping(uint256 => bool) public exOrderCancelled;
    mapping(uint256 => bool) public exOrderFilled;


    // Events
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);

    event exOrder(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event exCancel(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );

    // Structs
    struct _ExOrder {
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 timestamp;
    }

    constructor(address _owner, uint256 _ratio) Owned(_owner) public {
        ratio = _ratio;
    }

    // Fallback: reverts if Ether is sent to this smart contract by mistake
    function() external {
        revert();
    }

    function depositEther() payable public {
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].add(msg.value);
        emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
    }

    function withdrawEther(uint _amount) public {
        require(tokens[ETHER][msg.sender] >= _amount);
        tokens[ETHER][msg.sender] = tokens[ETHER][msg.sender].sub(_amount);
        msg.sender.transfer(_amount);
        emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
    }

    function depositToken(address _token, uint _amount) public {
        require(_token != ETHER);
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_amount);
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function withdrawToken(address _token, uint256 _amount) public {
        require(_token != ETHER);
        require(tokens[_token][msg.sender] >= _amount);
        tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_amount);
        require(Token(_token).transfer(msg.sender, _amount));
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user) public view returns (uint256) {
        return tokens[_token][_user];
    }

    function makeExchange(address _tokenGet, address _tokenGive, uint256 _amountGive) public {
        uint256 _amountGet;

        exOrderCount = exOrderCount.add(1);

        if (_tokenGive == ETHER) { // ether -> token
            _amountGet = _amountGive.mul(ratio);
        } else {                   // token -> ether
            _amountGet = _amountGive.div(ratio);
        }
        
        tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].sub(_amountGive);
        tokens[_tokenGive][owner] = tokens[_tokenGive][owner].add(_amountGive);

        tokens[_tokenGet][owner] = tokens[_tokenGet][owner].sub(_amountGet);
        tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].add(_amountGet);

        exOrders[exOrderCount] = _ExOrder(exOrderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
        
        emit exOrder(exOrderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, now);
    }
}