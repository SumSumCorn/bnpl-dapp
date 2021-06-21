import { tokens, ether, EVM_REVERT, ETHER_ADDRESS } from './helpers'

const Token = artifacts.require('./Token')
const Exchange = artifacts.require('./Exchange')

const Datetime = artifacts.require('./BokkyPooBahsDateTimeContract')

const Bnpl = artifacts.require('./Bnpl')
const Merchants = artifacts.require('./Merchants')
const Members = artifacts.require('./Members')


require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Bnpl', ([bnplCompany, feeAccount, payee, buyer, seller, carrier]) => {
  let token
  let datetime
  let merchants
  let members
  let bnpl
  let result

  const feePercent = 10
  const gasPrice = ether(0.00206736)

  beforeEach(async () => {
    // Deploy token
    token = await Token.new()
    datetime = await Datetime.new()
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

    bnpl.setDatetime(datetime.address)

    members = await Members.new(bnpl.address)
    merchants = await Merchants.new(bnpl.address)

    bnpl.setMembers(members.address)
    bnpl.setMerchants(merchants.address)

  })

  describe('creation', async () => {
    it('deploys successfully', async () => {
      // bnpl
      //console.log(bnpl)
      assert.notEqual(bnpl.address, 0x0)
      assert.notEqual(bnpl.address, '')
      assert.notEqual(bnpl.address, null)
      assert.notEqual(bnpl.address, undefined)

      // members
      assert.notEqual(bnpl.merchants, 0x0)
      assert.notEqual(bnpl.merchants, '')
      assert.notEqual(bnpl.merchants, null)
      assert.notEqual(bnpl.merchants, undefined)

      // merchants
      assert.notEqual(bnpl.members, 0x0)
      assert.notEqual(bnpl.members, '')
      assert.notEqual(bnpl.members, null)
      assert.notEqual(bnpl.members, undefined)
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

  describe('init bnplinfo', () => {
    let result
    it('initialize infomation about buyer', async () => {
      result = await bnpl.registerMember(buyer, { from:bnplCompany })
    })

    //event
  })

  describe('making bnplOrders', () => {
    let result
    let amount = tokens(1000)
    beforeEach(async () => {

      await merchants.registerSeller(seller, {from:bnplCompany})
      await merchants.setProduct('channel','no5',amount, {from:seller})

      await bnpl.registerMember(buyer, {from:bnplCompany})
      

      await token.transfer(buyer, amount, { from: bnplCompany })
      await token.approve(bnpl.address, amount, { from: buyer })
      await bnpl.depositToken(token.address, amount, { from: buyer })

      // address _seller,
      // uint    _prodNum,
      // uint    _qty,
      // address _token,
      // uint    _initCost
      result = await bnpl.makeBnplOrder(
        seller, 
        1,
        1,
        token.address, 
        tokens(500), 
        { from : buyer })

      //result = await bnpl.acceptOrder(1,'channel','20210622', { from:seller })

    })

    it('checks order no1 is correct', async () => {

    })

    describe('simulate refund protocol', () => {
      beforeEach(async () => {
        result = await bnpl.orderTimeSub(1);
      })
      it('seller does not accept order', async () => {

      })
    })

    // describe('simulate payback protocol', () => {

    //   it('when buyer installment correctly', async () => {

    //   })

    //   it('when buyer get debt', async() => {

    //   })

    // })

    // describe('simulate delivery protocol', () => {
    //   it('package is being deliverd', async () => {

    //   })

    //   it('package has arrived', async () => {

    //   })

    })
    // it('tracks the newly created order', async () => {
    //   const orderCount = await bnpl.orderCount()
    //   orderCount.toString().should.equal('1')

    //   const order = await bnpl.orders('1')
    //   order.id.toString().should.equal('1', 'id is correct')
    //   order.buyer.should.equal(buyer, 'buyer is correct')
    //   order.seller.should.equal(seller, 'seller is correct')
    //   order.token.should.equal(token.address, 'token is correct')
    //   order.totalPrice.toString().should.equal(tokens(10).toString(), 'totalPrice is correct')
    //   order.initcost.toString().should.equal(tokens(5).toString(), 'initcost is correct')
    //   order.installmentPeriod.toString().should.equal('1', 'amountGive is correct')
    //   order.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
    // })

    // it('emits an "Order" event', () => {
    //   const log = result.logs[0]
    //   log.event.should.eq('Order')
    //   const event = log.args
    //   event.id.toString().should.equal('1', 'id is correct')
    //   event.buyer.should.equal(buyer, 'buyer is correct')
    //   event.seller.should.equal(seller, 'seller is correct')
    //   event.totalPrice.toString().should.equal(tokens(10).toString(), 'totalPrice is correct')
    //   event.initcost.toString().should.equal(tokens(5).toString(), 'initcost is correct')
    //   event.installmentPeriod.toString().should.equal('1', 'amountGive is correct')
    //   event.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
    // })
  })
  
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