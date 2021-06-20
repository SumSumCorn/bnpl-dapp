pragma solidity ^0.5.0;


// 소유자 관리용 계약
contract TwoOwned {
    // 상태 변수
    address public owner1; // bnpl
    address public owner2; // bnpl 계약 주소 위함

    // 소유자 변경 시 이벤트
    event TransferOwnership(address beforeAddress, address afterAddress);

    // 소유자 한정 메서드용 수식자
    modifier onlyOwner() { require(msg.sender==owner1 || msg.sender == owner2); _; }

    // 생성자
    constructor(address _owner1, address _owner2) public {
        owner1 = _owner1; // 처음에 계약을 생성한 주소를 소유자로 한다
        owner2 = _owner2;
    }
    
    // (1) 소유자 변경
    function transferOwnership(address _new) public onlyOwner {
        address beforeAddress = owner1;
        owner1 = _new;
        emit TransferOwnership(beforeAddress, owner1);
    }
}