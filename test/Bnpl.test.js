import { tokens, ether, EVM_REVERT, ETHER_ADDRESS } from './helpers'

const Token = artifacts.require('./Token')
const Exchange = artifacts.require('./Exchange')
const Bnpl = artifacts.require('./Bnpl')
const Merchants = artifacts.require('./Merchants')
const Members = artifacts.require('./Members')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Bnpl', ([bnplCompany, feeAccount, payee, buyer, seller, carrier]) => {
  let token
  let merchants
  let members
  let bnpl
  let result

  const feePercent = 10
  const gasPrice = ether(0.00206736)

  beforeEach(async () => {
    // Deploy token
    token = await Token.new()
    //members = await Members.new(bnplCompany)
    //merchants = await Merchants.new(bnplCompany)

    //await merchants.registerSeller(buyer, { from:bnplCompany })
    //await merchants.setProduct('Channel', 'no5', tokens(1000000), { from:seller })

    // // Transfer some tokens to user1
    // token.transfer(buyer, tokens(100), { from: bnplCompany })

    // Deploy exchange
    bnpl = await Bnpl.new()
    bnpl.setFee(feeAccount, feePercent, { from:bnplCompany })
    bnpl.setPayee(payee, { from:bnplCompany })

    //bnpl.merchants().registerMerchant(seller)
    //merchants = await bnpl.merchants
    //bnpl.setMerchants(merchants.address, { from:bnplCompany })
    //bnpl.setMembers(members.address, { from:bnplCompany })

    //console.log(bnpl.merchants())
    //merchants = await bnpl.merchants()



  })

  describe('creation', async () => {
    it('deploys successfully', async () => {
      // bnpl
      //console.log(bnpl)
      assert.notEqual(bnpl.address, 0x0)
      assert.notEqual(bnpl.address, '')
      assert.notEqual(bnpl.address, null)
      assert.notEqual(bnpl.address, undefined)

      // // members
      // assert.notEqual(merchants.address, 0x0)
      // assert.notEqual(merchants.address, '')
      // assert.notEqual(merchants.address, null)
      // assert.notEqual(merchants.address, undefined)

      // // merchants
      // assert.notEqual(members.address, 0x0)
      // assert.notEqual(members.address, '')
      // assert.notEqual(members.address, null)
      // assert.notEqual(members.address, undefined)
      //console.log(bnpl.registerMerchant(seller))

      //result = await bnpl.registerMerchant(seller, { from:bnplCompany })
      //console.log(await bnpl.merchants(Merchants.isAuth()))
      result = await bnpl.registerMerchant(seller)
    })
  })

  describe('deployment correctly', () => {
    it('checks Bnpl contract owner', async () => {
      const bnplCompanyAccount = await bnpl.owner()

      bnplCompanyAccount.should.equal(bnplCompany)
    })

    it('check fee info', async () => {
      const bnplfeeAccount = await bnpl.feeAccount()
      const bnplfeePercent = await bnpl.feePercent()

      bnplfeeAccount.should.equal(feeAccount)
      bnplfeePercent.toString().should.equal(feePercent.toString())
    })

    it('check payee account', async () => {
      const payeeAccount = await bnpl.payee()
      payeeAccount.should.equal(payee)
    })
  })

  // describe('making orders', () => {
  //   let result
  //   beforeEach(async () => {
  //     result = await bnpl.makeBnplOrder(seller, token.address, tokens(10), tokens(5), 1, { from : buyer })
  //   })

  //   // it('tracks the newly created order', async () => {
  //   //   const orderCount = await bnpl.orderCount()
  //   //   orderCount.toString().should.equal('1')

  //   //   const order = await bnpl.orders('1')
  //   //   order.id.toString().should.equal('1', 'id is correct')
  //   //   order.buyer.should.equal(buyer, 'buyer is correct')
  //   //   order.seller.should.equal(seller, 'seller is correct')
  //   //   order.token.should.equal(token.address, 'token is correct')
  //   //   order.totalPrice.toString().should.equal(tokens(10).toString(), 'totalPrice is correct')
  //   //   order.initcost.toString().should.equal(tokens(5).toString(), 'initcost is correct')
  //   //   order.installmentPeriod.toString().should.equal('1', 'amountGive is correct')
  //   //   order.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
  //   // })

  //   // it('emits an "Order" event', () => {
  //   //   const log = result.logs[0]
  //   //   log.event.should.eq('Order')
  //   //   const event = log.args
  //   //   event.id.toString().should.equal('1', 'id is correct')
  //   //   event.buyer.should.equal(buyer, 'buyer is correct')
  //   //   event.seller.should.equal(seller, 'seller is correct')
  //   //   event.totalPrice.toString().should.equal(tokens(10).toString(), 'totalPrice is correct')
  //   //   event.initcost.toString().should.equal(tokens(5).toString(), 'initcost is correct')
  //   //   event.installmentPeriod.toString().should.equal('1', 'amountGive is correct')
  //   //   event.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
  //   // })
  // })
  
  // describe('order actions', () => {
  //   let result

  //   beforeEach(async () => {
  //     // // user1 deposits ether only
  //     // await exchange.depositEther({ from: buyer, value: ether(1) })
  //     // give tokens to buyer
  //     await token.transfer(buyer, tokens(100), { from: bnplCompany })

  //     // buyer deposits tokens only
  //     await token.approve(bnpl.address, tokens(100), { from: buyer })
  //     await bnpl.depositToken(token.address, tokens(100), { from: buyer })

      
  //     // buyer fills order
  //     result = await bnpl.makeBnplOrder(seller, token.address, tokens(10), tokens(5), 1, { from : buyer })
  //   })

  //   describe('filling orders', () => {
  //     let result
  //     describe('success', () => {
  //       let targetNumber
  //       it('BNPL company fills orders', async () => {
  //         targetNumber = 1
  //         result = await bnpl.fillBnplOrder(targetNumber)

  //         const orderFilled = await bnpl.orderFilled(1)
  //         orderFilled.should.equal(true)

  //         let balance
  //         // buyer sub init cost
  //         balance = await bnpl.balanceOf(token.address, buyer)
  //         balance.toString().should.equal(tokens(95).toString(), 'buyer sub tokens')
  //         // defi company gets init cost 
  //         balance = await bnpl.balanceOf(token.address, feeAccount)
  //         balance.toString().should.equal(tokens(5).toString(), 'feeAccount get tokens')
  //       })

  //       it('check trade 1', async () => {

  //         // defi company gets init cost 
  //         //balance = await bnpl.balanceOf(token.address, feeAccount)
  //         //balance.toString().should.equal(tokens(5).toString(), 'feeAccount get tokens')

  //         //tokens

  //       })

  //       it('emits a "Fill" event', () => {
  //         const log = result.logs[0]
  //         log.event.should.eq('Fill')
  //         const event = log.args
  //         event.id.toString().should.equal('1', 'id is correct')
  //         event.buyer.should.equal(buyer, 'buyer is correct')
  //         event.seller.should.equal(seller, 'seller is correct')
  //         event.totalPrice.toString().should.equal(tokens(10).toString(), 'totalPrice is correct')
  //         event.initcost.toString().should.equal(tokens(5).toString(), 'initcost is correct')
  //         event.installmentPeriod.toString().should.equal('1', 'amountGive is correct')
  //         event.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
  //       })
  //     })
  //   })
  // })


})