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
  let exchange
  let datetime
  let merchants
  let members
  let bnpl
  let result

  const feePercent = 10
  const gasPrice = ether(0.00206736)

  const RANK = {
    BRONZE: 0,
    SILVER: 1,
    GOLD: 2
  }

  const BNPLSTAT = {
    //UNENROLLED,
    NONE: 0,
    PROCESSING: 1,
    LATE: 2,
    BANNED : 3
  }

  const ORDERSTATS = {
      CREATED: 0,    // 계약생성 -> installment 계약생성
      LOADED: 1,     // package 계약생성
      DONE: 2,       // 완전히 1 2 way 끝남
      PROCESSING: 3, // installment 진행중
      FINISHED: 4,
      CANCELLED: 5   // package 계약 생성 안함 -> initcost 환불 -> 주문취소
  }

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

    exchange = await Exchange.new()

    bnpl = await Bnpl.new()
    bnpl.setFee(feeAccount, feePercent, { from:bnplCompany })
    bnpl.setPayee(payee, { from:bnplCompany })

    bnpl.setDatetime(datetime.address)
    bnpl.setExchange(exchange.address)

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

    const prodNum = 1
    
    const orderId = 1
    beforeEach(async () => {

      await merchants.registerSeller(seller, {from:bnplCompany})
      await merchants.setProduct('channel','no5',amount, {from:seller})

      await bnpl.registerMember(buyer, {from:bnplCompany})
      

      await token.transfer(buyer, amount, { from: bnplCompany })
      await token.approve(exchange.address, amount, { from: buyer })
      await exchange.depositToken(token.address, amount, { from: buyer })

      // address _seller,
      // uint    _prodNum,
      // uint    _qty,
      // address _token,
      // uint    _initCost
      result = await bnpl.makeBnplOrder(
        seller, 
        prodNum,
        1,
        token.address, 
        tokens(500), 
        { from : buyer })

      //result = await bnpl.acceptOrder(1,'channel','20210622', { from:seller })

    })

    it('checks order no1 is correct', async () => {
      result = await bnpl.orders(orderId)

      result.id.toString().should.equal(orderId.toString())
      result.buyer.should.equal(buyer)
      result.seller.should.equal(seller)
      result.productNum.toString().should.equal(prodNum.toString())
      result.qty.toString().should.equal('1')
      result.tokenKind.should.equal(token.address)
      result.initCost.toString().should.equal(tokens(500).toString())
      result.totalPrice.toString().should.equal(tokens(1000).toString())

      assert.notEqual(result.installmentCon, 0x0)
      assert.equal(result.packageCon, 0x0)

      result.orderStat.toString().should.equal(ORDERSTATS.CREATED.toString())

      result.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')

    })

    it('checks after order1 is made', async () => {
      result = await exchange.balanceOf(token.address, buyer)
      result.toString().should.equal(tokens(500).toString())
    })

    describe('simulate refund protocol', () => {
      beforeEach(async () => {
        result = await bnpl.orderTimeSub(orderId)
      })
      it('stat roll back correctly', async () => {
        result = await bnpl.manageWay1and2(prodNum)

        result = await bnpl.orders(1)
        result.orderStat.toString().should.equal(ORDERSTATS.CANCELLED.toString())

        result = await members.memberBnpls(buyer)
        result.stat.toString().should.equal(BNPLSTAT.NONE.toString())
      })

      it('buyer gets init cost', async () => {
        const buyerOriginal = amount
        result = await exchange.balanceOf(token.address, buyer)
        result.toString().should.equal(tokens(500).toString())

        result = await bnpl.manageWay1and2(prodNum)
        result = await exchange.balanceOf(token.address, buyer)
        result.toString().should.equal(buyerOriginal.toString())
      })
    })

    describe('simulate payback protocol', () => {
      beforeEach(async () => {
        result = await bnpl.acceptOrder(1,'channel','20210622', { from:seller })
        result = await bnpl.orderTimeSub(1)
        result = await bnpl.manageWay1and2(prodNum)
        result = await bnpl.installTimeSub(orderId)
      })


      it('when buyer installment correctly', async () => {
        result = await bnpl.payback(orderId)
      })

      it('when buyer get debt', async() => {

      })


      it(' ready ', async () => {
        //result = await bnpl.execPayback(orderId)

      })
    })

    // describe('simulate delivery protocol', () => {
    //   it('package is being deliverd', async () => {

    //   })

    //   it('package has arrived', async () => {

    //   })

    // })

  })
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
    //})
  
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
