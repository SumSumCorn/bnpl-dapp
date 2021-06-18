pragma solidity ^0.5.0;

import "./Token.sol";
import "./Owned.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract Installment is Owned {
	constructor(address _owner) Owned(_owner) public {
		//
	}
}