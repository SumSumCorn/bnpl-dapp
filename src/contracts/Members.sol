pragma solidity ^0.5.0;

import "./Owned.sol";
import "./Token.sol";
import "./Bnpl.sol";
import "./BokkyPooBahsDateTimeContract.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Members is Owned {
    using SafeMath for uint;


    //Token public token; // 토큰(가상 화폐) 주소
    Bnpl public bnpl;  // bnpl 주소
    BokkyPooBahsDateTimeContract public datetime;

    MemberStatus[3] public status; // 회원 등급 배열

    mapping(address => History) public bnplHistory; // 회원별 거래 이력

    mapping(address => MemberInfo) public MemberInfos; // 회원별 개인정보
    
    mapping(address => Installment) public memberInstallments; // 회원별 할부 내역

    mapping(address => Latefee) public memberLatefees; 

    // 개인정보 구조체
    struct MemberInfo {
        string name;
        string socialNumber;
        string phoneNumber;
        string bankName;
        string accountNumber;
        //bool blacklist;
    }

    // 할부 구조체
    struct Installment {
        //bool 
        uint256 remainCost;     // 앞으로 남은 할부 금액
        uint256 remainCnt;      // 앞으로 남은 할부 횟수
        uint256 paybackCost;    // 4주동안 내야할 금액
        uint256 nextDeadline;   // 다음 할부 결제 날짜
        bool    isLate;         // 연체하였는가
    }

    struct Latefee {
        uint256 remainFee;     // 앞으로 남은 연체료
        uint256 nextDeadline;   // 다음 연체 날짜
    }



    // 회원 등급용 구조체
    struct MemberStatus {
        string name; // 등급명
        uint256 times; // 최저 거래 회수
        uint256 sum; // 최저 거래 금액
        uint8 rate; // 한도
        uint8 installmentCount; // 최대 할부 기간
    }
    // 거래 이력용 구조체
    struct History {
        uint256 times; // 거래 회수
        uint256 sum; // 거래 금액
        uint256 statusIndex; // 등급 인덱스
    }
 
    constructor(address _owner) Owned(_owner) public {
        //
        status[0] = MemberStatus({
                name: "Gold",
                times: 1,
                sum: 1,
                rate: 1,
                installmentCount: 1
        });
        status[1] = MemberStatus({
                name: "Silver",
                times: 1,
                sum: 1,
                rate: 1,
                installmentCount: 1
        });
        status[2] = MemberStatus({
                name: "Bronze",
                times: 1,
                sum: 1,
                rate: 1,
                installmentCount: 1
        });

        //datetime = BokkyPooBahsDateTimeContract(_datetime);
    }

    // 사용할 계약 초기화
    function setBnpl(address _bnpl) public onlyOwner {
        bnpl = Bnpl(_bnpl);
    }
    
    function setDatetime(address _datetime) public onlyOwner {
        datetime = BokkyPooBahsDateTimeContract(_datetime);
    }

    // 토큰 한정 메서드용 수식자
    //modifier onlyToken() { require(msg.sender == token); _; }
     
    // // 토큰 주소 설정
    // function setToken(address _addr) public onlyOwner {
    //     //  token = _addr;
    // }

    function makeInstallmentPlan(
        address _buyer, 
        uint256 _remainCost, 
        uint8 _remainCnt,
        uint256 _paybackCost
    ) public onlyOwner {
        // 더 갚을 것이 없는데 빼내면 안된다.
        require(memberInstallments[_buyer].remainCost > 0);

        // memberInstallments[_buyer].remainCost = _remainCost;
        // memberInstallments[_buyer].remainPeriod = _remainPeriod;
        // memberInstallments[_buyer].paybackCost = _paybackCost;

        memberInstallments[_buyer] = Installment({
            remainCost : _remainCost,     // 앞으로 남은 할부 금액
            remainCnt : _remainCnt,   // 앞으로 남은 할부 기간
            paybackCost : _paybackCost,    // 4주동안 내야할 금액
            nextDeadline : now + 30 days,   // 다음 할부 결제 날짜
            isLate : false         // 연체하였는가
        });

    }
     
    function paybackInstallment(address _token, address _buyer) public onlyOwner {
        // nextDeadline 이랑 비교하는 것이 필요 즉 이 함수의 실행 날짜가 데드라인 날짜와 같은지 확인
        // require();        

        // 연체가 있는 동안에는 원금을 갚을 수가 없다.
        require(memberInstallments[_buyer].isLate == false);

        uint256 paycost = memberInstallments[_buyer].paybackCost;
        uint256 term = 30 days;

        // 자기 할부값보다 지금 자금이 많아야한다.
        if (bnpl.balanceOf(_token,_buyer) >= paycost) {
            memberInstallments[_buyer].remainCost = memberInstallments[_buyer].remainCost.sub(paycost);
            memberInstallments[_buyer].nextDeadline = memberInstallments[_buyer].nextDeadline.add(term);
        }
        else { // 자금이 없으므로 연체가 된다.
            memberInstallments[_buyer].isLate = true;

            // 수수료는 하루 당 0.03% 로 책정
            uint256 initfee = memberInstallments[_buyer].remainCost.mul(3).div(1000);
            term = 1 days;

            memberLatefees[_buyer] = Latefee({
                remainFee : initfee,
                nextDeadline : memberInstallments[_buyer].nextDeadline.add(term) 
            });
        }
    }

    function paybackLatefee(address _token, address _buyer, uint256 paybackFee) public {
        // 이 함수를 실행한 시간은 언제나 가능하다

        // 이 함수는 buyer 만 가능하다
        require(msg.sender == _buyer);

        // 연체료가 있을 때에만 실행가능
        require(memberInstallments[_buyer].isLate);
        // 연체료보다 지갑에 든게 많아야한다.
        require(bnpl.balanceOf(_token,_buyer) >= paybackFee 
            && memberLatefees[_buyer].remainFee >= paybackFee);

        memberLatefees[_buyer].remainFee = memberLatefees[_buyer].remainFee.sub(paybackFee);

        // 연체료 다 갚은 경우
        if(memberLatefees[_buyer].remainFee == 0) {
            memberInstallments[_buyer].isLate = false;
        }
    }

    function raiseLatefee(address _buyer) public onlyOwner {
        // 이 함수의 실행 시간은 nextdeadline 과 같은 날짜에만 실행이 가능하다.

        uint256 addFee = memberLatefees[_buyer].remainFee.mul(3).div(1000);
        uint256 term = 1 days;

        memberLatefees[_buyer].remainFee = memberLatefees[_buyer].remainFee.add(addFee);
        memberLatefees[_buyer].nextDeadline = memberLatefees[_buyer].nextDeadline.add(term);
    }

    function isBlacklist(address _buyer) public view onlyOwner returns(bool) {
        return memberInstallments[_buyer].isLate;
    }

    // // 회원 등급 추가
    // function pushStatus(string memory _name, uint256 _times, uint256 _sum, uint8 _rate) public onlyOwner {
    //     status.push(MemberStatus({
    //         name: _name,
    //         times: _times,
    //         sum: _sum,
    //         rate: _rate
    //     }));
    // }
 
    // 회원 등급 내용 변경
    function editStatus(uint256 _index, string memory _name, uint256 _times, uint256 _sum, uint8 _rate) public onlyOwner {
        if (_index < status.length) {
            status[_index].name = _name;
            status[_index].times = _times;
            status[_index].sum = _sum;
            status[_index].rate = _rate;
        }
    }
     
    // 거래 내역 갱신
    function updateHistory(address _member, uint256 _value) public onlyOwner {
        bnplHistory[_member].times += 1;
        bnplHistory[_member].sum += _value;
        // 새로운 회원 등급 결정(거래마다 실행)
        uint256 index;
        uint8 tmprate;
        for (uint i = 0; i < status.length; i++) {
            // 최저 거래 횟수, 최저 거래 금액 충족 시 가장 캐시백 비율이 좋은 등급으로 설정
            if (bnplHistory[_member].times >= status[i].times &&
                bnplHistory[_member].sum >= status[i].sum &&
                tmprate < status[i].rate) {
                index = i;
            }
        }
        bnplHistory[_member].statusIndex = index;
    }

    // 캐시백 비율 획득(회원의 등급에 해당하는 비율 확인)
    function getCashbackRate(address _member) public view returns (uint8 rate) {
        rate = status[bnplHistory[_member].statusIndex].rate;
    }
}