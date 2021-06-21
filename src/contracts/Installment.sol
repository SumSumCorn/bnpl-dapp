pragma solidity ^0.5.0;

import "./Token.sol";
import "./Owned.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract Installment is Owned {
  using SafeMath for uint;

  bool avail;

	// 할부
  uint remainCost;     // 앞으로 남은 할부 금액
  uint remainCnt;      // 앞으로 남은 할부 횟수
  uint paybackCost;    // 4주동안 내야할 금액
  uint nextInstallDeadline;   // 다음 할부 결제 날짜


  // 연체료
  uint remainFee;     // 앞으로 남은 연체료
  uint nextFeeDeadline;   // 다음 연체 날짜

	constructor (
    uint _initCost, 
    uint _totalCost, 
    uint _installmentCnt, 
    uint _timestamp
  ) Owned(msg.sender) public {
		remainCost = _totalCost.sub(_initCost);
    remainCnt = _installmentCnt;
    paybackCost = remainCost.div(remainCnt);
    nextInstallDeadline = _timestamp;

    avail = true;
	}

  modifier onlyAvail() { require(avail == true); _; }

  function isAvail() public view returns(bool) {
    return avail;
  }

  function kill() public onlyOwner {
    avail = false;
  }

  function getRemainCnt() public view onlyAvail returns(uint) {
    return remainCnt;
  }

  function getRemainCost() public view onlyAvail returns(uint) {
    return remainCost;
  }

  function getPaybackCost() public view onlyAvail returns(uint) {
    if(remainCnt==0)
      return 0;

    if(remainCnt == 1){
      return remainCost;
    }else {
      return paybackCost;
    }
  }

  function getLateFeeCost() public view onlyAvail returns(uint) {
    return remainFee;
  }

  function getNextInstallDeadline() public view onlyAvail returns(uint) {
    return nextInstallDeadline;
  }

  // 한 달 후
  function setNextInstallDeadline(uint _timestamp) public onlyAvail{
    nextInstallDeadline = _timestamp;
  }

  // 하루 후
  function setNextFeeDeadline(uint _timestamp) public onlyAvail{
    nextFeeDeadline = _timestamp;
  }


  function isLate() public view onlyAvail returns(bool) {
    return remainFee >= 0;
  }

  // 정산하기
  function balanceIntallment() public onlyOwner onlyAvail {

    // 정산 완료
    remainCnt = remainCnt.sub(1);
    if(remainCnt == 0){
      remainCost = remainCost.sub(paybackCost);
    }else{
      remainCost = remainCost.sub(paybackCost);
    }

  }

  // 연체료 정산하기
  function balanceLateFee() public onlyOwner onlyAvail {

    // 정산 완료
    remainCnt = remainCnt.sub(1);
    if(remainCnt == 0){
      remainCost = remainCost.sub(paybackCost);
    }else{
      remainCost = remainCost.sub(paybackCost);
    }

  }

  function raiseLatefee() public onlyAvail {
      // 이 함수의 실행 시간은 nextdeadline 과 같은 날짜에만 실행이 가능하다.

      uint addFee = remainCost.add(remainFee);

      addFee = addFee.mul(3).div(1000);

      remainFee = remainFee.add(addFee);
  }



    // function paybackInstallment(address _token, address _buyer) public {
  //   // nextDeadline 이랑 비교하는 것이 필요 즉 이 함수의 실행 날짜가 데드라인 날짜와 같은지 확인
  //   // require();        



  //   uint256 paycost = memberInstallments[_buyer].paybackCost;
  //   uint256 term = 30 days;

  //   // 자기 할부값보다 지금 자금이 많아야한다.
  //   if (bnpl.balanceOf(_token,_buyer) >= paycost) {
  //       memberInstallments[_buyer].remainCost = memberInstallments[_buyer].remainCost.sub(paycost);
  //       memberInstallments[_buyer].nextDeadline = memberInstallments[_buyer].nextDeadline.add(term);
  //   }
  //   else { // 자금이 없으므로 연체가 된다.
  //       memberInstallments[_buyer].isLate = true;

  //       // 수수료는 하루 당 0.03% 로 책정
  //       uint256 initfee = memberInstallments[_buyer].remainCost.mul(3).div(1000);
  //       term = 1 days;

  //       memberLatefees[_buyer] = Latefee({
  //           remainFee : initfee,
  //           nextDeadline : memberInstallments[_buyer].nextDeadline.add(term) 
  //       });
  //   }
  // }

  // function paybackLatefee(address _token, address _buyer, uint256 paybackFee) public {
  //     // 이 함수를 실행한 시간은 언제나 가능하다

  //     // 이 함수는 buyer 만 가능하다
  //     require(msg.sender == _buyer);

  //     // 연체료가 있을 때에만 실행가능
  //     require(memberInstallments[_buyer].isLate);
  //     // 연체료보다 지갑에 든게 많아야한다.
  //     require(bnpl.balanceOf(_token,_buyer) >= paybackFee 
  //         && memberLatefees[_buyer].remainFee >= paybackFee);

  //     memberLatefees[_buyer].remainFee = memberLatefees[_buyer].remainFee.sub(paybackFee);

  //     // 연체료 다 갚은 경우
  //     if(memberLatefees[_buyer].remainFee == 0) {
  //         memberInstallments[_buyer].isLate = false;
  //     }
  // }


}