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

contract Bnpl is Owned {
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
      DONE,       // 완전히 1 2 way 끝남
      PROCESSING, // package, installment 진행중
      ONLYLOAN,   // installment, latefee 만 진행중
      FINISHED,   // 다 끝난 경우
      CANCELLED   // package 계약 생성 안함 -> initcost 환불 -> 주문취소
  }

  // reference datecontract
  BokkyPooBahsDateTimeContract public dateTime;
  Members public members;
  Merchants public merchants;
  Exchange public exchange;


  // Variables
  address public feeAccount;
  uint public feePercent; // the fee percentage

  address public payee;

  mapping(uint => _Order) public orders;
  uint public orderCount;

  event Order(
      uint    id,
      address buyer,
      address seller,
      address tokenKind,
      uint    totalPrice,
      uint    installmentPeriod,
      uint    timestamp
  );

  event BlackListed(address indexed target);
  event DeleteFromBlacklist(address indexed target);

  event FinishBnplOrder(uint);
  event Late(uint);

  struct _Order {
    uint        id;
    address     buyer;
    address     seller;
    uint        productNum;
    uint        qty;
    address     tokenKind;
    uint        initCost;
    uint        totalPrice;
    Installment installmentCon;
    Package     packageCon;
    ORDERSTATS  orderStat;
    uint256     timestamp;
  } 

  constructor () Owned(msg.sender) public {
    
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

  function setExchange(address _exchange) public {
    exchange = Exchange(_exchange);
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
    require(_initCost <= exchange.balanceOf(_token,msg.sender), 'have enough money');

    // 처음 init 은 받는다. (1way)
    exchange.depositTokenTransfer(_token, msg.sender, payee, _initCost);

    orderCount = orderCount.add(1);

    uint totalPrice;
    uint installmentCnt;
    uint nextTimestamp;

    ( , , totalPrice) = merchants.getProduct(_seller, _prodNum);
    totalPrice = totalPrice.mul(_qty);

    orders[orderCount] = _Order(
      orderCount, 
      msg.sender,
      _seller, 
      _prodNum,
      _qty,
      _token,
      _initCost,
      totalPrice,
      Installment(0x0),
      Package(0x0),
      ORDERSTATS.CREATED,
      now);


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
    return  new Installment(_initCost, _totalPrice, _installmentCnt, _nextTimestamp);
  }

  function makePackageCon(address _from, string memory _name, uint256 _trackingNum) public returns(Package) {
    return new Package(_from, _name, _trackingNum);
  }

  // seller 가 주문을 보고 패키지를 등록함
  function acceptOrder(uint _id, address _from, string memory _name, uint _trackingNum) public {
    // 유효한 주문 번호여야 한다.
    require(_id <= orderCount);

    _Order storage order = orders[_id];

    //msg.sender 가 _id 의 seller 와 동일하다.
    require(msg.sender == order.seller);

    order.packageCon = makePackageCon(_from, _name, _trackingNum);

    order.orderStat = ORDERSTATS.LOADED;

  }
  // it is only for testing!!
  function orderTimeSub(uint _id) public {
    // 유효한 주문 번호여야 한다.
    require(_id <= orderCount);

    _Order storage order = orders[_id];

    uint timeMachine = order.timestamp;
    timeMachine = dateTime.subDays(timeMachine, 1);
    timeMachine = dateTime.subHours(timeMachine, 12);

    order.timestamp = timeMachine;
  }

  function installTimeSub(uint _id) public {
    // 유효한 주문 번호여야 한다.
    require(_id <= orderCount);

    _Order storage order = orders[_id];

    Installment curInstall = order.installmentCon;

    uint timeMachine = curInstall.getNextInstallDeadline();
    timeMachine = dateTime.subMonths(timeMachine, 1);
    timeMachine = dateTime.subHours(timeMachine, 12);
    
    curInstall.setNextInstallDeadline(timeMachine);
  }


  function manageWay1and2(uint _id) public {
    // 유효한 주문 번호여야 한다.
    require(_id <= orderCount);

    _Order storage order = orders[_id];
    require(dateTime.addDays(order.timestamp,1) < now, 'must execute in time!');

    uint afterPrice = order.totalPrice;

    afterPrice = afterPrice.div(feePercent);


    // seller에게 보내줌 (2way) 
    if(order.orderStat == ORDERSTATS.LOADED){
      // 수수료 제외한 total cost 보내줌
      // order 1,2 끝난거 저장
      exchange.depositTokenTransfer(order.tokenKind, payee, order.seller, afterPrice);
      order.orderStat = ORDERSTATS.DONE;

      // emit 
    }else{
      // (1way) 취소, order 취소
      _cancelOrder(_id);
      
      // member bnpl stat 변경
      members.setMemberBnplStat(order.buyer, uint(BNPLSTAT.NONE));

      // installcon 삭제
      order.installmentCon.kill();
    }
  }

  function _cancelOrder(uint _id) internal {
    _Order storage order = orders[_id];

    order.orderStat = ORDERSTATS.CANCELLED;
    _refund(_id);
  }

  function _refund(uint _id) internal {
    _Order storage order = orders[_id];

    exchange.depositTokenTransfer(order.tokenKind, payee, order.buyer, order.initCost);
  }

  function deliverPackage(uint _id, address _from, address _to) public {
    require(_id <= orderCount);

    _Order storage order = orders[_id];

    Package curPackage = order.packageCon;

    curPackage.send(_from, _to);

  }

  function receivePackage(uint _id, address _to) public {
    require(_id <= orderCount);

    _Order storage order = orders[_id];

    Package curPackage = order.packageCon;

    curPackage.receive(_to);

    if(_to == order.buyer){
      // finish delivery
      order.orderStat = ORDERSTATS.ONLYLOAN;
    }

  }



  function payback(uint _id) public {
    require(_id <= orderCount);

    _Order storage order = orders[_id];

    Installment curInstallCon = order.installmentCon;

    require(orders[_id].orderStat == ORDERSTATS.DONE 
      || orders[_id].orderStat == ORDERSTATS.PROCESSING 
      || orders[_id].orderStat == ORDERSTATS.ONLYLOAN);

    //require(curInstallCon.getNextInstallDeadline() < now, 'must in time!');

    // uint year; uint month; uint day;
    // uint curYear; uint curMonth; uint curDay;
    // // 정해진 시간에 실행했는지 확인
    // (year, month, day) = dateTime.timestampToDate(curInstallCon.getNextInstallDeadline());
    // (curYear, curMonth, curDay) = dateTime.timestampToDate(now);

    // require(year == curYear && month == curMonth && day == curDay, 'must in day!');

    uint paybackCost = curInstallCon.getPaybackCost();
    uint lateFeeCost = curInstallCon.getLateFeeCost();

    uint nextInstallTime = dateTime.addMonths(curInstallCon.getNextInstallDeadline(), 1);
    uint nextLateFeeTime = dateTime.addDays(curInstallCon.getNextInstallDeadline(), 1);


    if(curInstallCon.isLate() == false){
      // 연체료가 없을 때

      if(curInstallCon.getRemainCnt() == 1){
        // 다 갚은 경우
        if(exchange.balanceOf(order.tokenKind, order.buyer) >= paybackCost)  {
          //정상적으로 갚음
          exchange.depositTokenTransfer(order.tokenKind, order.buyer, payee, paybackCost) ;
          curInstallCon.balanceIntallment();

          // BNPL 마무리
          order.orderStat = ORDERSTATS.FINISHED;
          members.setMemberBnplStat(order.buyer, uint(BNPLSTAT.NONE));
          // update memberbnpls
          members.updateMemberBnpls(order.buyer, order.totalPrice);

          emit FinishBnplOrder(order.id);
        }else{
          // 마지막에서 연체
          curInstallCon.raiseLatefee();
          // 멤버 연체중인것 저장
          members.setMemberBnplStat(order.buyer, uint(BNPLSTAT.LATE));
          curInstallCon.setNextFeeDeadline(nextLateFeeTime);
        }
      }else{
        // 보통 갚은 경우
        if(exchange.balanceOf(order.tokenKind, order.buyer) >= paybackCost) {
          //정상적으로 갚음
          exchange.depositTokenTransfer(order.tokenKind, order.buyer, payee, paybackCost) ;
          curInstallCon.balanceIntallment();
          curInstallCon.setNextInstallDeadline(nextInstallTime);

        }else{
          // 보통에서 연체
          curInstallCon.raiseLatefee();
          // 멤버 연체중인것 저장
          members.setMemberBnplStat(order.buyer, uint(BNPLSTAT.LATE));
          curInstallCon.setNextFeeDeadline(nextLateFeeTime);
        }
      }

    }else {
      // 연체한 경우

      if(exchange.balanceOf(order.tokenKind, order.buyer) >= lateFeeCost){


        // 다 갚은 경우
        // 연체료 없앰
        curInstallCon.balanceLateFee();
        // 연체료 전송
        exchange.depositTokenTransfer(order.tokenKind, order.buyer, payee, lateFeeCost);
        // 맴버 상태 변경
        members.setMemberBnplStat(order.buyer, uint(BNPLSTAT.PROCESSING));

        //nextInstallTime = dateTime.addMonths(curInstallCon.getNextFeeDeadline(), 1);

        curInstallCon.setNextInstallDeadline(nextInstallTime);
        emit Late(order.id);

      } else{
        // 또못 갚은 경우
        curInstallCon.raiseLatefee();
        curInstallCon.setNextFeeDeadline(nextLateFeeTime);
      }
    }
  } 

}

