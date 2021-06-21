pragma solidity ^0.5.0;


import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./TwoOwned.sol";


contract Members is TwoOwned {
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

  MemberRank[3] public rank; // 회원 등급 배열 기준 저장

  mapping(address => MemberInfo) public memberInfos; // 회원별 개인정보

  mapping(address => memberBnpl) public memberBnpls; // 회원의 bnpl 거래상태 저장

  // 회원 등급용 구조체
  struct MemberRank {
      string name; // 등급명
      uint times; // 최저 거래 회수
      uint sum; // 최저 거래 금액
      uint rate; // 한도
      uint installmentCount; // 최대 할부 기간
  }

  // 개인정보 구조체
  struct MemberInfo {
    string name;
    string socialNumber;
    string phoneNumber;
    string bankName;
    string accountNumber;
  }

  // 거래 이력용 구조체
  struct memberBnpl{
    BNPLSTAT stat;
    uint targetOrder;
    uint times; // 거래 회수
    uint sum; // 거래 금액
    RANK rank; // 등급 인덱스
  }

  constructor(address _bnpl) public TwoOwned(msg.sender, _bnpl) {
      // 등급명
      // 최저 거래 회수
      // 최저 거래 금액
      // 한도
      // 최대 할부 기간
      uint money = (10 ** 18);

      rank[uint(RANK.GOLD)] = MemberRank({
              name: "Gold",
              times: 5,
              sum: 2000 * (money),
              rate: 2000  * (money), 
              installmentCount: 10
      });
      rank[uint(RANK.SILVER)] = MemberRank({
              name: "Silver",
              times: 3,
              sum: 1000  * (money),
              rate: 1000  * (money),
              installmentCount: 5
      });
      rank[uint(RANK.BRONZE)] = MemberRank({
              name: "Bronze",
              times: 0,
              sum: 0,
              rate: 500 * (money),
              installmentCount: 1
      });
  }

  function initMemberInfo
  (    
    address _member,
    string memory _name,
    string memory _socialNumber,
    string memory _phoneNumber,
    string memory _bankName,
    string memory _accountNumber
  ) public onlyOwner {
    memberInfos[_member] = MemberInfo(_name, _socialNumber, _phoneNumber, _bankName, _accountNumber);
    initMemberBnplInfo(_member);
  }

  function initMemberBnplInfo(address _member) public onlyOwner {
    memberBnpls[_member] = memberBnpl(BNPLSTAT.NONE, 0, 0, 0, RANK.BRONZE);
  }

  function getMemberinfo(address _member) public onlyOwner view returns(string memory, string memory, string memory, string memory, string memory) {
    MemberInfo storage info = memberInfos[_member];
    return (
      info.name, 
      info.socialNumber,
      info.phoneNumber,
      info.bankName,
      info.accountNumber
    );
  }

  function getMemberStat(address _buyer) public view returns(BNPLSTAT) {
    return memberBnpls[_buyer].stat;
  }

  function getMemberRank(address _buyer) public view returns(RANK) {
    return memberBnpls[_buyer].rank;
  }

  function getMemberInstallments(address _member) public view returns(uint) {
    uint _cnt;

    if(getMemberRank(_member) == RANK.BRONZE){
      _cnt = 1;
    }else if(getMemberRank(_member) == RANK.SILVER){
      _cnt = 5;
    }else{
      _cnt = 10;
    }

    return _cnt;
  }

  function canMemberBnpl(address _buyer) public view returns(bool) {
    return memberBnpls[_buyer].stat == BNPLSTAT.NONE;
  }

  function setMemberBnplStat(address _buyer, uint _set) public onlyOwner {
    memberBnpls[_buyer].stat = BNPLSTAT(_set);
  }

  // 끝마치면 stat 과 등급을 체크한다.
  function updateMemberBnpls(address _buyer, uint _money) public onlyOwner {
    memberBnpls[_buyer].times = memberBnpls[_buyer].times.add(1);
    memberBnpls[_buyer].sum = memberBnpls[_buyer].sum.add(_money);

    memberBnpls[_buyer].stat = BNPLSTAT.NONE;

    RANK _rank = memberBnpls[_buyer].rank;

    if( _rank == RANK.GOLD) {
      // already top
    }else if(_rank == RANK.SILVER) {
      if ( memberBnpls[_buyer].sum >= rank[uint(RANK.GOLD)].sum
          && memberBnpls[_buyer].times >= rank[uint(RANK.GOLD)].times){
        memberBnpls[_buyer].rank = RANK.GOLD;
        // emit
      }
    }else {
      if ( memberBnpls[_buyer].sum >= rank[uint(RANK.SILVER)].sum
          && memberBnpls[_buyer].times >= rank[uint(RANK.SILVER)].times){
        memberBnpls[_buyer].rank = RANK.SILVER;
        // emit
      }
    }
  }

}  
