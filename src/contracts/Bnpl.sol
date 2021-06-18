pragma solidity ^0.5.0;

import "./Token.sol";
import "./Exchange.sol";
import "./Owned.sol";
import "./Members.sol";
import "./Merchant.sol";
import "./BokkyPooBahsDateTimeContract.sol";
//import "./Installment.sol";
//import "./Product.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Bnpl is Exchange {
    using SafeMath for uint;

    Members public members;
    Merchant public merchant;
    //Installment public installment;
    //Product product;


    // Variables
    address public feeAccount;
    uint public feePercent; // the fee percentage

    mapping(uint => _Order) public orders;
    uint public orderCount;
    //mapping(uint => bool) public orderCancelled;
    //mapping(uint => bool) public orderFilled;

    //STATUSES public status;

    enum STATUSES {
        CREATED,    // make bnpl 계약
        PROCESSING, // fill bnpl 실행
        DONE,       // 완전히 bnpl 다 끝남
        CANCELLED   // bnpl 중간에 끝남
    }

    // address public exTokens = Exchange;
    // Exchange exchangeAddr;

    event Fill(
        uint    id,
        address buyer,
        address seller,
        address tokenkind,
        uint    totalPrice,
        uint    initcost,
        uint    installmentPeriod,
        uint    timestamp
    );
    event Order(
        uint    id,
        address buyer,
        address seller,
        address tokenkind,
        uint    totalPrice,
        uint    initcost,
        uint    installmentPeriod,
        uint    timestamp
    );
    event Cancel(
        uint    id,
        address buyer,
        address seller,
        address tokenkind,
        uint    totalPrice,
        uint    initcost,
        uint    installmentPeriod,
        uint    timestamp
    );
    event Trade(
        uint    id,
        address buyer,
        address seller,
        address tokenkind,
        uint    totalPrice,
        uint    initcost,
        uint    installmentPeriod,
        uint    timestamp

    );

    event BlackListed(address indexed target);
    event DeleteFromBlacklist(address indexed target);


    // Structs
    struct _Order {
        uint    id;
        address buyer;
        address seller;
        uint    productNum;
        uint    qty;
        address token;
        uint    totalPrice;
        uint    initcost;
        uint    installmentPeriod;
        uint    timestamp;
        STATUSES  status;
    }

    constructor (address _owner, address _feeAccount, uint _feePercent, address _datetime) Exchange(_owner, _feePercent) public {
        feeAccount = _feeAccount;
        feePercent = _feePercent;

        // 멤버계약 초기화
        members = new Members(_owner);
        members.setBnpl(address(this));
        members.setDatetime(_datetime);

        // 판매자계약 초기화
        merchant = new Merchant(_owner);
    }

	function makeBnplOrder
    (
        address _seller,
        uint    _prodNum,
        uint _qty,
        address _token,
        uint _initcost, 
        uint    _installmentPeriod
    ) public {
        // 연체하지 않은 사람만 주문할수 있다.
        require(members.isBlacklist(msg.sender) == false);

        require(merchant.isAuth(_seller) == true);

        string memory name;
        uint prodPrice;
        uint totalPrice;

        ( , prodPrice) = merchant.getProduct(_seller, _prodNum);
        totalPrice = _prodNum.mul(_qty);

        orderCount = orderCount.add(1);
        orders[orderCount] = _Order(orderCount, msg.sender, _seller, _prodNum, _qty, _token, totalPrice, _initcost, _installmentPeriod, now, STATUSES.CREATED);
        emit Order(orderCount, msg.sender, _seller, _token, totalPrice, _initcost, _installmentPeriod, now);
	}

	function cancelBnplOrder(uint _id) public {
		_Order storage _order = orders[_id];
        require(address(_order.buyer) == msg.sender || address(_order.seller) == msg.sender );
        require(_order.id == _id); // The order must exist

        // if(_order.status == CREATED){
        //     //
        // }else if(_order.status == PROCESSING){
        //     //
        // }else { // DONE, CANCELLED
        //     //
        // }

        _order.status = STATUSES.CANCELLED;
        //orderCancelled[_id] = true;
        emit Cancel(_order.id, _order.buyer, _order.seller, _order.token, _order.totalPrice, _order.initcost, _order.installmentPeriod, now);
	}

	function fillBnplOrder(uint _id) public onlyOwner {
        require(_id > 0 && _id <= orderCount, 'Error, wrong id');
        //require(!orderFilled[_id], 'Error, order already filled');
        //require(!orderCancelled[_id], 'Error, order already cancelled');


        //require(address(_order.seller) == msg.sender, "wrong caller" );
        _Order storage _order = orders[_id];
        
        require(_order.status == STATUSES.CREATED);

        _bnplTrade(_order.id, _order.buyer, _order.seller, _order.token, _order.totalPrice, _order.initcost, _order.installmentPeriod, now);
        _order.status = STATUSES.PROCESSING;

        emit Fill(_order.id, _order.buyer, _order.seller, _order.token, _order.totalPrice, _order.initcost, _order.installmentPeriod, now);
	}

	function _bnplTrade
    (   
        uint _id, 
        address _buyer, 
        address _seller, 
        address _token, 
        uint _totalPrice,  
        uint _initcost, 
        uint   _installmentPeriod, 
        uint timestamp
    ) internal {
		uint _feeAmount = _totalPrice.mul(feePercent).div(100);
        //uint _ratio = exchangeAddr.ratio();
        
        //1 way		
		tokens[_token][_buyer] = tokens[_token][_buyer].sub(_initcost);
        tokens[_token][feeAccount] = tokens[_token][feeAccount].add(_initcost);

        //2 way
		tokens[_token][_seller] = tokens[_token][_seller].add(_totalPrice.sub(_feeAmount));

		//3 way
		// _seller give product to client
        

	}

    
    // 할부체킹
    // if (now > 30 day) 할부 함수 실행 -> 돈이 없다 -> 블랙리스트 -> 있는경우에는 할부가 끝날 때까지 이함수를 정기적으로 실행한다.
    // block 1 -> block 2 -> block 3 timestamp 1달 뒤로 -> 테스팅



    // function blackListing(address _addr) public onlyOwner {
    //     blackLists[_addr] = 1;
    //     emit BlackListed(_addr);
    // }



    // function cancelOrder(uint _id) public {
    //     _Order storage _order = orders[_id];
    //     require(address(_order.user) == msg.sender);
    //     require(_order.id == _id); // The order must exist
    //     orderCancelled[_id] = true;
    //     emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, now);
    // }

    // function fillOrder(uint _id) public {
    //     require(_id > 0 && _id <= orderCount, 'Error, wrong id');
    //     require(!orderFilled[_id], 'Error, order already filled');
    //     require(!orderCancelled[_id], 'Error, order already cancelled');
    //     _Order storage _order = orders[_id];
    //     _trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
    //     orderFilled[_order.id] = true;
    // }

    // function _trade(uint _orderId, address _user, address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive) internal {
    //     // Fee paid by the user that fills the order, a.k.a. msg.sender.
    //     uint _feeAmount = _amountGet.mul(feePercent).div(100);

    //     tokens[_tokenGet][msg.sender] = tokens[_tokenGet][msg.sender].sub(_amountGet.add(_feeAmount));
    //     tokens[_tokenGet][_user] = tokens[_tokenGet][_user].add(_amountGet);
    //     tokens[_tokenGet][feeAccount] = tokens[_tokenGet][feeAccount].add(_feeAmount);
    //     tokens[_tokenGive][_user] = tokens[_tokenGive][_user].sub(_amountGive);
    //     tokens[_tokenGive][msg.sender] = tokens[_tokenGive][msg.sender].add(_amountGive);

    //     emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, now);
    // }

}
