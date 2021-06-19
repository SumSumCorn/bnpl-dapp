pragma solidity ^0.5.0;

import "./Owned.sol";
import "./Token.sol";
import "./Bnpl.sol";
import "./BokkyPooBahsDateTimeContract.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Merchants is Owned {
  using SafeMath for uint;

  // product list
  // supply
  mapping(address => bool) public auth; // 판매가능자
  
  mapping(address => mapping(uint => Product)) public products; // 판매 리스트
  
  mapping(address => uint) public prodCnt;// 판매물건갯수 카운트


  struct Product {
    string name;
    string serial;
    uint256 price;
  }

  event RegisterLicense(address licenser, address licensee);
  event RegisterProduct(address seller, uint prodCnt);


  constructor(address _owner) Owned(_owner) public {
    //
  }

  function registerSeller(address _seller) onlyOwner public {
    
    auth[_seller] = true;
    emit RegisterLicense(msg.sender, _seller);
  }

  function isAuth(address _seller) public view returns(bool) {
    return auth[_seller];
  }

  function setProduct(string memory _name, string memory _serial, uint256 _price) public {
    require(auth[msg.sender] == true);

    prodCnt[msg.sender] = prodCnt[msg.sender].add(1);
    products[msg.sender][prodCnt[msg.sender]] = Product({name: _name, serial: _serial, price: _price});

    emit RegisterProduct(msg.sender, prodCnt[msg.sender]);
  }

  function getProduct(address _seller, uint _productNum) public view returns(string memory, string memory, uint256) {
    // 해당 물건이 있는가?
    require(isAuth(_seller) == true);
    require(prodCnt[_seller] >= _productNum);

    return (products[_seller][_productNum].name, products[_seller][_productNum].serial, products[_seller][_productNum].price);
  }

}
