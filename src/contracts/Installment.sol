pragma solidity ^0.5.0;

import "./Token.sol";
import "./Owned.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract Installment is Owned {
  using SafeMath for uint;

	// 할부
  uint256 remainCost;     // 앞으로 남은 할부 금액
  uint256 remainCnt;      // 앞으로 남은 할부 횟수
  uint256 paybackCost;    // 4주동안 내야할 금액
  uint256 nextInstallDeadline;   // 다음 할부 결제 날짜


  // 연체료
  uint256 remainFee;     // 앞으로 남은 연체료
  uint256 nextFeeDeadline;   // 다음 연체 날짜

	constructor(address _owner) Owned(_owner) public {
		//
	}

    // function paybackInstallment(address _token, address _buyer) public {
  //   // nextDeadline 이랑 비교하는 것이 필요 즉 이 함수의 실행 날짜가 데드라인 날짜와 같은지 확인
  //   // require();        

  //   // 연체가 있는 동안에는 원금을 갚을 수가 없다.
  //   require(memberInstallments[_buyer].isLate == false);

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

  // function raiseLatefee(address _buyer) public {
  //     // 이 함수의 실행 시간은 nextdeadline 과 같은 날짜에만 실행이 가능하다.

  //     uint256 addFee = memberLatefees[_buyer].remainFee.mul(3).div(1000);
  //     uint256 term = 1 days;

  //     memberLatefees[_buyer].remainFee = memberLatefees[_buyer].remainFee.add(addFee);
  //     memberLatefees[_buyer].nextDeadline = memberLatefees[_buyer].nextDeadline.add(term);
  // }

  // function getMemberRank(address _member) public view returns (RANK memberRank) {
  //   return memberInfos[_member].rank;
  // }


 
  // function editStatus(uint256 _index, string memory _name, uint256 _times, uint256 _sum, uint8 _rate) public {
  //     if (_index < rank.length) {
  //         rank[_index].name = _name;
  //         rank[_index].times = _times;
  //         rank[_index].sum = _sum;
  //         rank[_index].rate = _rate;
  //     }
  // }
   
  // function updateHistory(address _member, uint256 _value) public {
  //     bnplHistory[_member].times += 1;
  //     bnplHistory[_member].sum += _value;
  //     // 새로운 회원 등급 결정(거래마다 실행)
  //     uint256 index;
  //     uint8 tmprate;
  //     for (uint i = 0; i < rank.length; i++) {
  //         // 최저 거래 횟수, 최저 거래 금액 충족 시 가장 캐시백 비율이 좋은 등급으로 설정
  //         if (bnplHistory[_member].times >= rank[i].times &&
  //             bnplHistory[_member].sum >= rank[i].sum &&
  //             tmprate < rank[i].rate) {
  //             index = i;
  //         }
  //     }
  //     bnplHistory[_member].rankIndex = index;
  // }

   


}