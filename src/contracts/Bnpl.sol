pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./BokkyPooBahsDateTimeContract.sol";
import "./usingOraclize.sol";

import "./Owned.sol";
import "./Token.sol";
import "./Exchange.sol";

import "./Members.sol";
import "./Merchants.sol";

import "./Installment.sol";
import "./Package.sol";

contract Bnpl is Exchange {
  using SafeMath for uint;

  //reference datecontract
  BokkyPooBahsDateTimeContract public dateTime;

  Members public members;
  Merchants public merchants;


  // Variables
  address public feeAccount;
  uint public feePercent; // the fee percentage

  address public payee;

  mapping(uint => _Order) public orders;
  uint public orderCount;

  //mapping(uint => bool) public orderCancelled;
  //mapping(uint => bool) public orderFilled;

  //STATUSES public status;

  enum ORDERSTATS {
      CREATED,    // installment 계약생성
      LOADED,     // package 계약생성
      DONE,       // 완전히 bnpl 다 끝남
      CANCELLED   // bnpl 중간에 끝남
  }

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
  // struct _Order {
  //     uint    id;
  //     address buyer;
  //     address seller;
  //     uint    productNum;
  //     uint    qty;

  //     address token;
  //     uint    totalPrice;
  //     uint    initcost;
  //     uint    installmentPeriod;
  //     uint    timestamp;
  //     STATUSES  status;
  // }

  struct _Order {
    uint        id;
    address     buyer;
    address     seller;
    uint        productNum;
    uint        qty;
    Installment installmentCon;
    Package     packageCon;
    ORDERSTATS  status;
  } 

  constructor (address _members, address _merchants) Exchange(msg.sender) public {
    
    members = Members(_members);
    merchants = Merchants(_merchants);
  }

  function setFee(address _feeAccount, uint _feePercent) public onlyOwner {
    feeAccount = _feeAccount;
    feePercent = _feePercent;
  }

  function setPayee(address _payee) public onlyOwner {
    payee = _payee; 
  }

  // function setMerchants(address _merchants) public onlyOwner {
  //   merchants = Merchants(_merchants);
  // }

  // function setMembers(address _members) public onlyOwner {
  //   members = Members(_members);
  // }

  function setDatetime(address _dateTime) public onlyOwner {
    dateTime = BokkyPooBahsDateTimeContract(_dateTime);
  }

}

	// function makeBnplOrder
 //  (
 //    address _seller,
 //    uint    _prodNum,
 //    uint    _qty,
 //    address _token,
 //    uint    _initcost
 //  ) public {
 //    // 연체하지 않은 사람만 주문할수 있다.
 //    //require(members.isBlacklist(msg.sender) == false);

 //    require(merchants.isAuth(_seller) == true);

 //    // initcost 보다 많이 있어야한다.
 //    require(_initcost <= tokens[_token][msg.sender]);

 //    // installment period 체크 member에서 등급따라 할수있는것
 //    require(members.memberInfos[msg.sender].rank);

 //    // 처음 init 은 받는다.
 //    tokens[_token][msg.sender] = tokens[_token][msg.sender].add(_initcost);
 //    tokens[_token][payee] = tokens[_token][payee].add(_initcost);

 //    string memory _name;
 //    string memory _serial;
 //    uint _prodPrice;
 //    uint _totalPrice;

 //    (_name, _serial, _prodPrice) = merchants.getProduct(_seller, _prodNum);
 //    _totalPrice = _prodPrice.mul(_qty);

 //    orderCount = orderCount.add(1);

 //    // struct _Order {
 //    //   uint    id;
 //    //   address buyer;
 //    //   address seller;
 //    //   uint    productNum;
 //    //   uint    qty;
 //    //   address token;
 //    //   uint    initcost;
 //    //   uint    initimestamp;
 //    //   STATUSES  status;
 //    // } 

 //    orders[orderCount] = _Order(orderCount, msg.sender, _seller, _prodNum, _qty, _token, _totalPrice, _initcost, now, STATUSES.CREATED);
 //    emit Order(orderCount, msg.sender, _seller, _token, _totalPrice, _initcost, now);
	// }

 //  function makePackage(uint id) public {
 //    // 유효한 id 인지 확인
 //    _Order storage _order  = orders[id];

 //    // 판매자가 작동시키는 것인지 확인

 //    // 상태가 작동시킬수 있는 것인지 확인

 //    string memory _name = 'channel';
 //    string memory _trackNum = 'no5';

 //    packages[id] = new Package(_name, _trackNum);
 //  }

 //  // // check it should be refunded
 //  function isPackageFilled(uint id) public onlyOwner view returns(bool) {
 //    // 유효한 id 인지 확인
 //    _Order storage _order  = orders[id];


 //  }

 //  function makeInstallmentPlan(
 //      address _buyer, 
 //      uint256 _remainCost, 
 //      uint8 _remainCnt,
 //      uint256 _paybackCost
 //  ) public onlyOwner {
 //      // 더 갚을 것이 없는데 빼내면 안된다.
 //      require(members.memberInstallments[_buyer].remainCost > 0);

 //      // memberInstallments[_buyer].remainCost = _remainCost;
 //      // memberInstallments[_buyer].remainPeriod = _remainPeriod;
 //      // memberInstallments[_buyer].paybackCost = _paybackCost;

 //      members.memberInstallments[_buyer] = Installment({
 //          remainCost : _remainCost,     // 앞으로 남은 할부 금액
 //          remainCnt : _remainCnt,       // 앞으로 남은 할부 기간
 //          paybackCost : _paybackCost,   // 4주동안 내야할 금액
 //          nextDeadline : dateTime.addMonths(now, 1), // 다음 할부 결제 날짜
 //          isLate : false                // 연체하였는가
 //      });

 //  }




  // if is not refunded
  // function

	// function cancelBnplOrder(uint _id) public {
	// 	_Order storage _order = orders[_id];
 //        require(address(_order.buyer) == msg.sender || address(_order.seller) == msg.sender );
 //        require(_order.id == _id); // The order must exist

 //        // if(_order.status == CREATED){
 //        //     //
 //        // }else if(_order.status == PROCESSING){
 //        //     //
 //        // }else { // DONE, CANCELLED
 //        //     //
 //        // }

 //        _order.status = STATUSES.CANCELLED;
 //        //orderCancelled[_id] = true;
 //        emit Cancel(_order.id, _order.buyer, _order.seller, _order.token, _order.totalPrice, _order.initcost, _order.installmentPeriod, now);
	// }




	// function fillBnplOrder(uint _id) public onlyOwner {
 //        require(_id > 0 && _id <= orderCount, 'Error, wrong id');
 //        //require(!orderFilled[_id], 'Error, order already filled');
 //        //require(!orderCancelled[_id], 'Error, order already cancelled');


 //        //require(address(_order.seller) == msg.sender, "wrong caller" );
 //        _Order storage _order = orders[_id];
        
 //        require(_order.status == STATUSES.CREATED);

 //        _bnplTrade(_order.id, _order.buyer, _order.seller, _order.token, _order.totalPrice, _order.initcost, _order.installmentPeriod, now);
 //        _order.status = STATUSES.PROCESSING;

 //        emit Fill(_order.id, _order.buyer, _order.seller, _order.token, _order.totalPrice, _order.initcost, _order.installmentPeriod, now);
	// }

	// function _bnplTrade
 //    (   
 //        uint _id, 
 //        address _buyer, 
 //        address _seller, 
 //        address _token, 
 //        uint _totalPrice,  
 //        uint _initcost, 
 //        uint   _installmentPeriod, 
 //        uint timestamp
 //    ) internal {
	// 	uint _feeAmount = _totalPrice.mul(feePercent).div(100);
 //        //uint _ratio = exchangeAddr.ratio();
        
 //        //1 way		
	// 	tokens[_token][_buyer] = tokens[_token][_buyer].sub(_initcost);
 //        tokens[_token][feeAccount] = tokens[_token][feeAccount].add(_initcost);

 //        //2 way
	// 	tokens[_token][_seller] = tokens[_token][_seller].add(_totalPrice.sub(_feeAmount));

	// 	//3 way
	// 	// _seller give product to client
        

	// }

    
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

