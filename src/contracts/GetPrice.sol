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
		//request_id = oraclize_query("URL",
  		//		"json(https://www.koreaexim.go.kr/site/program/financial/exchangeJSON?authkey=5nVgHObpKknHqEjMK1LQ0nA3CZALeAPp&searchdate=20180102&data=AP01&cur_unit=USD).0.deal_bas_r");

	}

	function __callback(uint256 _result) public {
		require(msg.sender == oraclize_cbAddress());

		randomNumber = _result;
	}

}

// pragma solidity ^0.4.25;
// import "github.com/oraclize/ethereum-api/oraclizeAPI_0.4.25.sol";

// contract 환율계산함수 is usingOraclize {
// string public exchage_rates;
// event NewOraclizeQuery(string description);
//      event NewSomeValue(string value);
// constructor() public {
//         update();
//     }
// function __callback(bytes32 myid, string result) public {
//         (myid);
//         require (msg.sender == oraclize_cbAddress());
//         exchage_rates = result;
//         emit NewSomeValue(exchage_rates);
//         // do something with exchage_rates
//     }
// function update() public payable {
//         if (oraclize_getPrice("URL") > address(this).balance) {
//             emit NewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
//         } else {
//             emit NewOraclizeQuery("Oraclize query was sent, standing by for the answer exchange_rate");
//             oraclize_query("URL", "[URL, 검색어, 수식 등]");
//         }
//     }
// }