pragma solidity ^0.5.0;

import "./Token.sol";
import "./Exchange.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Bnpl is Exchange {
    using SafeMath for uint;

    address owner;
    enum state{}

    constructor (address _owner, address _feeAccount, uint256 _feePercent) public {
    	owner = _owner;
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

	function 3trade() public {

	}

	function _tradeclitodefi() {

	}

	function _tradedefitoclient() {

	}


}

contract timer{

}