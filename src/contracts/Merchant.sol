pragma solidity ^0.5.0;

import "./Owned.sol";
import "./Token.sol";
import "./Bnpl.sol";
import "./BokkyPooBahsDateTimeContract.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Merchant is Owned {
  using SafeMath for uint;

  // product list
  // supply
  mapping(address => bool) public auth; // 판매가능자
  
  mapping(address => mapping(uint => Product)) public Products; // 판매 리스트
  
  mapping(address => uint) public prodCnt;// 판매물건갯수 카운트


  struct Product {
    string name;
    uint256 price;
  }

  constructor(address _owner) Owned(_owner) public {
    //
  }

  function registerSeller(address _seller) onlyOwner public {
    
    auth[_seller] = true;
  }

  function isAuth(address _seller) public view returns(bool) {
    return auth[_seller];
  }

  function setProduct(string memory _name, uint256 _price) public {
    require(auth[msg.sender] == true);

    prodCnt[msg.sender] = prodCnt[msg.sender].add(1);
    Products[msg.sender][prodCnt[msg.sender]] = Product({name: _name, price: _price});
  }

  function getProduct(address _seller, uint _productNum) public view returns(string memory, uint256) {
    // 해당 물건이 있는가?
    require(isAuth(_seller) == true);
    require(prodCnt[_seller] >= _productNum);

    return (Products[_seller][_productNum].name, Products[_seller][_productNum].price);
  }

}
