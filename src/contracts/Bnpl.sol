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

  enum RANK {
    BRONZE,
    SILVER,
    GOLD
  }

  enum BNPLSTAT{
    //UNENROLLED,
    NONE,
    PROCESSING,
    LATE,
    BANNED
  }


  enum ORDERSTATS {
      CREATED,    // 계약생성 -> installment 계약생성
      LOADED,     // package 계약생성
      DONE,       // 완전히 bnpl 다 끝남
      CANCELLED   // package 계약 생성 안함 -> initcost 환불 -> 주문취소
  }

  // reference datecontract
  BokkyPooBahsDateTimeContract public dateTime;
  // make contracts
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

  struct _Order {
    uint        id;
    address     buyer;
    address     seller;
    uint        productNum;
    uint        qty;
    Installment installmentCon;
    Package     packageCon;
    ORDERSTATS  orderStat;
    uint256     timestamp;
  } 

  constructor () Exchange(msg.sender) public {
    
    // members = new Members(address(this));
    // merchants = new Merchants(address(this));
  }

  function setFee(address _feeAccount, uint _feePercent) public onlyOwner {
    feeAccount = _feeAccount;
    feePercent = _feePercent;
  }

  function setPayee(address _payee) public onlyOwner {
    payee = _payee; 
  }

  function setDatetime(address _dateTime) public onlyOwner {
    dateTime = BokkyPooBahsDateTimeContract(_dateTime);
  }

  function setMembers(address _members) public {
    members = Members(_members);
  }
  function setMerchants(address _merchants) public {
    merchants = Merchants(_merchants);
  }

  // 처음 bnpl 이용시 초기화한다.
  function registerMember(address _member) public onlyOwner {
    members.initMemberBnplInfo(_member);
  }

  function makeBnplOrder
  (
    address _seller,
    uint    _prodNum,
    uint    _qty,
    address _token,
    uint    _initCost
  ) public {
    // 연체하지 않은 사람만 주문할수 있다.
    require(members.canMemberBnpl(msg.sender) == true, 'member can bnpl');
    require(merchants.isAuth(_seller) == true, 'seller is authorized');

    // // initcost 보다 많이 있어야한다.
    require(_initCost <= tokens[_token][msg.sender], 'have enough money');

    // 처음 init 은 받는다. (1way)
    tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_initCost);
    tokens[_token][payee] = tokens[_token][payee].add(_initCost);

    orderCount = orderCount.add(1);

    orders[orderCount] = _Order(
      orderCount, 
      msg.sender,
      _seller, 
      _prodNum,
      _qty,
      Installment(0x0),
      Package(0x0),
      ORDERSTATS.CREATED,
      now);


    uint totalPrice;
    uint installmentCnt;
    uint nextTimestamp;

    ( , , totalPrice) = merchants.getProduct(_seller, _prodNum);
    totalPrice = totalPrice.mul(_qty);

    //  installment period 체크 member에서 등급따라 할수있는것
    installmentCnt = members.getMemberInstallments(msg.sender);

    nextTimestamp = dateTime.addMonths(now, 1);

    orders[orderCount].installmentCon = makeInstallmentCon(_initCost, totalPrice, installmentCnt, nextTimestamp);

    // msg.sender 가 bnpl 한다고 체크함
    members.setMemberBnplStat(msg.sender, uint(BNPLSTAT.PROCESSING));

    // event 생성
    // emit Order(orderCount, msg.sender, _seller, _token, _totalPrice, _initCost, now);
  }

  function makeInstallmentCon(uint _initCost, uint _totalPrice, uint _installmentCnt, uint _nextTimestamp) public returns(Installment) {
    return new Installment(_initCost, _totalPrice, _installmentCnt, _nextTimestamp);
  }

  function makePackageCon(string memory _name, uint256 _trackingNum) public returns(Package) {
    return new Package(_name, _trackingNum);
  }

  // seller 가 주문을 보고 패키지를 등록함
  function acceptOrder(uint _id, string memory _name, uint _trackingNum) public {
    // 유효한 주문 번호여야 한다.
    require(_id <= orderCount);

    _Order storage order = orders[_id];

    //msg.sender 가 _id 의 seller 와 동일하다.
    require(msg.sender == order.seller);

    order.packageCon = makePackageCon(_name, _trackingNum);

    order.orderStat = ORDERSTATS.LOADED;

  }
  // it is only for testing!!
  function orderTimeSub(uint _id) public {
    // 유효한 주문 번호여야 한다.
    require(_id <= orderCount);

    _Order storage order = orders[_id];

    uint timeMachine = order.timestamp;
    timeMachine = dateTime.subDays(timeMachine, 2);
    order.timestamp = timeMachine;
  }

  function manageWay1and2(uint _id) public {
    // 유효한 주문 번호여야 한다.
    require(_id <= orderCount);

    _Order storage order = orders[_id];
    require(dateTime.addDays(order.timestamp,1) < now, 'must execute in time!');


    // seller에게 보내줌 (2way) 
    if(order.orderStat == ORDERSTATS.LOADED){
      tokens[_token][msg.sender] = tokens[_token][msg.sender].sub(_initCost);
      tokens[_token][payee] = tokens[_token][payee].add(_initCost);
    }else{
      _cancelOrder(_id);
    }
  }

  function _cancelOrder(uint _id) internal {
    //
    _Order storage order = orders[_id];

    order.orderStat == ORDERSTATS.CANCELLED;
    _refund(_id, order.token, order.buyer, order.seller, order.initCost);
  }

  function _refund(uint _id, address _token, address _buyer, address _payee, uint _initCost) internal {
    _Order storage order = orders[_id];

    tokens[_token][_buyer] = tokens[_token][_buyer].add(_initCost);
    tokens[_token][_payee] = tokens[_token][_payee].payee(_initCost);
  }

  function packageSend() public {
    // 보내는 사람이랑 패키지 주인이랑 같아야함
  }

  function packageReceived() public {
    // 도착 함
  }

  function checkPayback() public {
    //
  }

  function executePayback() public {
    //
  }

  function payback() public onlyOwner {
    //
  }

}


    //require(members.memberInfos[msg.sender].rank);


    // string memory _name;
    // string memory _serial;
    // uint _prodPrice;
    // uint _totalPrice;

    // (_name, _serial, _prodPrice) = merchants.getProduct(_seller, _prodNum);


    // // struct _Order {
    // //   uint    id;
    // //   address buyer;
    // //   address seller;
    // //   uint    productNum;
    // //   uint    qty;
    // //   address token;
    // //   uint    initcost;
    // //   uint    initimestamp;
    // //   STATUSES  status;
    // // } 


	

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
 //        uint _initCost, 
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

