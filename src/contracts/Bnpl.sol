pragma solidity ^0.5.0;

import "./Token.sol";
import "./Exchange.sol";
import "./Owned.sol";
import "./Members.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Bnpl is Exchange {
    using SafeMath for uint;

    // Variables
    address public owner;    // the account that receives exchange fees
    uint256 public feePercent; // the fee percentage

    mapping(uint256 => _Order) public orders;
    uint256 public orderCount;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;

    // BlackList
    mapping(address => int8) public blackLists;
    mapping (address => Members) public members; // 각 주소의 회원 정보


    modifier onlyOwner() { require(msg.sender == owner, 'Error, only BNPLcompay can'); _; }


    event Order(
        uint256 id,
        address buyer,
        address seller,
        address tokenkind,
        uint256 totalPrice,
        uint256 initcost,
        uint8 installmentPeriod,
        uint256 timestamp
    );
    event Cancel(
        uint256 id,
        address buyer,
        address seller,
        address tokenkind,
        uint256 totalPrice,
        uint256 initcost,
        uint8 installmentPeriod,
        uint256 timestamp
    );
    event Trade(
        uint256 id,
        address buyer,
        address seller,
        address tokenkind,
        uint256 totalPrice,
        uint256 initcost,
        uint8 installmentPeriod,
        uint256 timestamp
    );

    event BlackListed(address indexed target);
    event DeleteFromBlacklist(address indexed target);


    // Structs
    struct _Order {
        uint256 id;
        address buyer;
        address seller;
        address token;
        uint256 totalPrice;
        uint256 initcost;
        uint8 installmentPeriod;
        uint256 timestamp;
    }

    constructor (address _owner, address _feeAccount, uint256 _feePercent) public {
    	owner = _owner;
        owner = _feeAccount;
        feePercent = _feePercent;
    }

	function makeBnplOrder
    (
        address _seller,
        address _token, 
        uint256 _totalPrice, 
        uint256 _initcost, 
        uint8   _installmentPeriod
    ) public {
        orderCount = orderCount.add(1);
        orders[orderCount] = _Order(orderCount, msg.sender, _seller, _token, _totalPrice, _initcost, _installmentPeriod, now);
        emit Order(orderCount, msg.sender, _seller, _token, _totalPrice, _initcost, _installmentPeriod, now);
	}

	function cancelBnplOrder(uint256 _id) public {
		_Order storage _order = orders[_id];
        require(address(_order.buyer) == msg.sender || address(_order.seller) == msg.sender );
        require(_order.id == _id); // The order must exist

        orderCancelled[_id] = true;
        emit Cancel(_order.id, _order.buyer, _order.seller, _order.token, _order.totalPrice, _order.initcost, _order.installmentPeriod, now);
	}

	function fillBnplOrder(uint256 _id) public {
        require(_id > 0 && _id <= orderCount, 'Error, wrong id');
        require(!orderFilled[_id], 'Error, order already filled');
        require(!orderCancelled[_id], 'Error, order already cancelled');

        _Order storage _order = orders[_id];
        require(address(_order.seller) == msg.sender );

        _bnplTrade(_order.id, _order.buyer, _order.seller, _order.token, _order.totalPrice, _order.initcost, _order.installmentPeriod, now);
        orderFilled[_order.id] = true;
	}

	function _bnplTrade
    (   
        uint256 _id, 
        address _buyer, 
        address _seller, 
        address _token, 
        uint256 _totalPrice,  
        uint256 _initcost, 
        uint8   _installmentPeriod, 
        uint256 timestamp
    ) internal {
		uint256 _feeAmount = _totalPrice.mul(feePercent).div(100);

        //1 way
		tokens[_token][_buyer] = tokens[_token][_buyer].sub(_initcost);
		tokens[_token][owner] = tokens[_token][owner].add(_initcost);
		//2 way
		tokens[_token][_seller] = tokens[_token][_seller].add(_totalPrice.sub(_feeAmount));

		//3 way
		// _seller give token(product) to client

	}

    function blackListing(address _addr) public onlyOwner {
        blackLists[_addr] = 1;
        emit BlackListed(_addr);
    }



    // function cancelOrder(uint256 _id) public {
    //     _Order storage _order = orders[_id];
    //     require(address(_order.user) == msg.sender);
    //     require(_order.id == _id); // The order must exist
    //     orderCancelled[_id] = true;
    //     emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
    // }

    // function fillOrder(uint256 _id) public {
    //     require(_id > 0 && _id <= orderCount, 'Error, wrong id');
    //     require(!orderFilled[_id], 'Error, order already filled');
    //     require(!orderCancelled[_id], 'Error, order already cancelled');
    //     _Order storage _order = orders[_id];
    //     _trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
    //     orderFilled[_order.id] = true;
    // }

    // function _trade(uint256 _orderId, address _user, address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {
    //     // Fee paid by the user that fills the order, a.k.a. msg.sender.
    //     uint256 _feeAmount = _amountGet.mul(feePercent).div(100);

    //     tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
    //     tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);
    //     tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(_feeAmount);
    //     tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
    //     tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive);

    //     emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, now);
    // }


}
