const Token = artifacts.require("Token")

const Exchange = artifacts.require("Exchange")
const Bnpl = artifacts.require("Bnpl")

const Datetime = artifacts.require("BokkyPooBahsDateTimeContract")

const Members = artifacts.require("Members")
const Merchants = artifacts.require("Merchants")
//const usingOraclize = artifacts.require("usingOraclize")
//const GetPrice = artifacts.require("GetPrice")


//const OraclizeAPI = artifacts.require("OraclizeAPI")

module.exports = async function(deployer) {
  const accounts = await web3.eth.getAccounts()

  await deployer.deploy(Token)
  await deployer.deploy(Datetime)

  const owner = accounts[0]

  await deployer.deploy(Members, owner)
  await deployer.deploy(Merchants, owner)

  // const feeAccount = accounts[0]
  // const feePercent = 10



  //await deployer.deploy(Exchange, feeAccount, feePercent)
  //await deployer.deploy(Bnpl, owner, feeAccount, feePercent)
  // await deployer.deploy(usingOraclize)
  // await deployer.deploy(GetPrice)
};
