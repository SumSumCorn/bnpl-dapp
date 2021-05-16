pragma solidity ^0.5.0;
//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "./usingOraclize.sol";

contract GetPrice is usingOraclize {
	uint256 public randomNumber;
	bytes32 public request_id;

	constructor() public {
		OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
	}

	function request() public {
		request_id = oraclize_query("WolframAlpha", "random number between 1 and 6");
	}

	function __callback(uint256 _result) public {
		require(msg.sender == oraclize_cbAddress());

		randomNumber = _result;
	}

}