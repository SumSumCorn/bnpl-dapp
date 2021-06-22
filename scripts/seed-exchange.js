// Contracts
const Token = artifacts.require("Token")

const Exchange = artifacts.require("Exchange")
const Bnpl = artifacts.require("Bnpl")

const Datetime = artifacts.require("BokkyPooBahsDateTimeContract")

const Members = artifacts.require("Members")
const Merchants = artifacts.require("Merchants")

const Package = artifacts.require("Package")
const Installment = artifacts.require("Installment")

const usingOraclize = artifacts.require("usingOraclize")
const GetPrice = artifacts.require("GetPrice")

// Helpers
const ETHER_ADDRESS = '0x0000000000000000000000000000000000000000'
const ether = (n) => {
  return new web3.utils.BN(
    web3.utils.toWei(n.toString(), 'ether')
  )
}
const tokens = (n) => ether(n)

const wait = (seconds) => {
  const milliseconds = seconds * 1000
  return new Promise(resolve => setTimeout(resolve, milliseconds))
}

module.exports = async function(callback) {
  try {
    // Fetch accounts from wallet - these are unlocked
    const accounts = await web3.eth.getAccounts()

    // Fetch the deployed token
    const token = await Token.deployed()
    console.log('Token fetched', token.address)

    // Fetch the deployed exchange
    const exchange = await Exchange.deployed()
    console.log('Exchange fetched', exchange.address)

    // Fetch the deployed Datetime
    const datetime = await Datetime.deployed()
    console.log('Datetime fetched', datetime.address)

    const bnpl = await Bnpl.deployed()
    console.log('Bnpl fetched', bnpl.address)

    const members = await Members.deployed(Members, Bnpl.address)
    console.log('Members fetched', members.address)

    const merchants = await Merchants.deployed(Merchants, Bnpl.address)
    console.log('Merchants fetched', merchants.address)

    // Set up All participants
    const bnplCompany = accounts[0]
    const feeAccount = accounts[1]
    const payee = accounts[2]
    const buyer1 = accounts[3]
    const buyer2 = accounts[4]
    const seller1 = accounts[5]
    const seller2 = accounts[6]
    const deliveryMan = accounts[7]

    const feePercent = 10

    bnpl.setFee(feeAccount, feePercent, { from:bnplCompany })    
    bnpl.setPayee(payee, { from:bnplCompany })

    bnpl.setDatetime(datetime.address)
    bnpl.setExchange(exchange.address)

    bnpl.setMembers(members.address)
    bnpl.setMerchants(merchants.address)

    console.log('complete initial setting')

    console.log(' ')
    await wait(1)

    let amount = tokens(500)
    await merchants.registerSeller(seller1, {from:bnplCompany})
    await merchants.setProduct('Apple_Watch','2021',amount, {from:seller1})
    console.log('seller1 enroll product Apple_Watch')
    console.log('Apple_Watch price is 500,000 won')

    amount = tokens(1500)
    await merchants.registerSeller(seller2, {from:bnplCompany})
    await merchants.setProduct('MacBook_Air','2022',amount, {from:seller2})
    console.log('seller2 enroll product MacBook_Air')
    console.log('MacBook_Air price is 1,500,000 won')

    console.log(' ')
    await wait(1)

    await bnpl.registerMember(buyer1, {from:bnplCompany})
    console.log('buyer1 was registered!')
    await bnpl.registerMember(buyer2, {from:bnplCompany})
    console.log('buyer2 was registered!')

    console.log(' ')
    await wait(1)

    amount = tokens(250)
    await token.transfer(buyer1, amount, { from: bnplCompany })
    await token.approve(exchange.address, amount, { from: buyer1 })
    await exchange.depositToken(token.address, amount, { from: buyer1 })
    console.log('buyer1 deposit 250 tokens')

    amount = tokens(500)
    await token.transfer(buyer2, amount, { from: bnplCompany })
    await token.approve(exchange.address, amount, { from: buyer2 })
    await exchange.depositToken(token.address, amount, { from: buyer2 })
    console.log('buyer2 deposit 500 tokens')

    console.log(' ')
    await wait(1)

    const prodNum = 1 // seller1 의 첫 번 째 물품
    await bnpl.makeBnplOrder(
        seller1, 
        prodNum,
        1,
        token.address, 
        tokens(250), 
        { from : buyer1 })
    console.log('buyer1 make first bnpl order!')
    console.log('buyer1 wants to buy Apple_Watch!')
    console.log('buyer1 initcost is 250,000 won')
    console.log('buyer1 remain cost is 250,000 won')

    let orderId = 1
    bnpl.acceptOrder(orderId, seller1, 'Apple_Watch', 20210622)
    console.log('seller1 accepts order no.1 and load Apple_watch package')

    console.log(' ')
    await wait(1)

    bnpl.orderTimeSub(orderId)
    console.log('wait one day')
    bnpl.manageWay1and2(orderId)
    console.log('check package is loaded and keep going')
    //let seller1Money = exchange.balanceOf(token.address, seller1)
    //console.log('seller1 has ', seller1Money)

    console.log(' ')
    await wait(1)

    bnpl.installTimeSub(orderId)
    console.log('wait one month')
    bnpl.payback(orderId)
    console.log('buyer1 has done Sucessful bnpl!')
    console.log('buyer1 level is now Silver')

    console.log(' ')
    await wait(1)

    amount = tokens(500)
    await token.transfer(buyer1, amount, { from: bnplCompany })
    await token.approve(exchange.address, amount, { from: buyer1 })
    await exchange.depositToken(token.address, amount, { from: buyer1 })
    console.log('buyer1 deposit 500 tokens')

    console.log(' ')
    await wait(1)

    await bnpl.makeBnplOrder(
        seller2, 
        prodNum,
        1,
        token.address, 
        tokens(500), 
        { from : buyer1 })
    console.log('buyer1 make second bnpl order!')
    console.log('buyer1 wants to buy MacBook_Air!')
    console.log('buyer1 initcost is 500,000 won')
    console.log('buyer1 remain cost is 1,000,000 won')

    console.log(' ')
    await wait(1)

    bnpl.orderTimeSub(orderId)
    console.log('wait one day')
    bnpl.manageWay1and2(orderId)
    console.log('seller2 does not load package')
    console.log('so it cancelled')
    console.log('buyer1 gets initcost 500,000 won')

    console.log(' ')
    await wait(1)

    await bnpl.makeBnplOrder(
        seller2, 
        prodNum,
        1,
        token.address, 
        tokens(500), 
        { from : buyer2 })
    console.log('buyer2 make third bnpl order!')
    console.log('buyer2 wants to buy MacBook_Air!')
    console.log('buyer2 initcost is 500,000 won')
    console.log('buyer2 remain cost is 1,000,000 won')

    console.log(' ')
    await wait(1)

    orderId = 3
    bnpl.acceptOrder(orderId, seller2, 'MacBook_Air', 20220622)
    console.log('seller2 accepts order no.3 and load MacBook_Air package')

    console.log(' ')
    await wait(1)

    bnpl.orderTimeSub(orderId)
    console.log('wait one day')
    bnpl.manageWay1and2(orderId)
    console.log('check package is loaded and keep going')

    console.log(' ')
    await wait(1)

    bnpl.installTimeSub(orderId)
    console.log('wait one month')
    bnpl.payback(orderId)
    console.log('buyer2 cannot do bnpl!')
    console.log('buyer2 has no money!')
    console.log('he has latefee!')

    console.log(' ')
    await wait(1)

    amount = tokens(1003)
    await token.transfer(buyer2, amount, { from: bnplCompany })
    await token.approve(exchange.address, amount, { from: buyer2 })
    await exchange.depositToken(token.address, amount, { from: buyer2 })
    console.log('buyer2 deposit 1003 tokens')

    bnpl.payback(orderId)
    console.log('buyer2 pay LateFee!')

    bnpl.installTimeSub(orderId)
    console.log('wait one month')
    bnpl.payback(orderId)
    console.log('buyer2 has done Sucessful bnpl!')
  }
  catch(error) {
    console.log(error)
  }

  callback()
}
