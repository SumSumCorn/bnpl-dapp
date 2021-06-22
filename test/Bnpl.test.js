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

contract('Bnpl', ([bnplCompany, feeAccount, payee, buyer, seller, deliveryMan]) => {
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
      PROCESSING: 3, // package, installment 진행중
      ONLYLOAN: 4,    // installment, latefee 만 진행중
      FINISHED: 5,   // 다 끝난 경우
      CANCELLED: 6   // package 계약 생성 안함 -> initcost 환불 -> 주문취소
  }

  beforeEach(async () => {
    // Deploy token
    token = await Token.new()
    datetime = await Datetime.new()

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

    it('checks installment order  is correct', async () => {
      let result2, result3

      result = await bnpl.orders(orderId)
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

    describe('simulate delivery and payback protocol', () => {
      beforeEach(async () => {
        result = await bnpl.acceptOrder(1, seller, 'channel','20210622', { from:seller })
        result = await bnpl.orderTimeSub(1)
        result = await bnpl.manageWay1and2(prodNum)
        result = await bnpl.installTimeSub(orderId)
      })

      describe('delivery protocol', () => {
        it('seller post package to delivery man', async () => {
          result = await bnpl.deliverPackage(orderId, seller,deliveryMan)
          result = await bnpl.receivePackage(orderId, deliveryMan)
          result = await bnpl.deliverPackage(orderId, deliveryMan, buyer)
          result = await bnpl.receivePackage(orderId, buyer)
          result = await bnpl.orders(orderId)
          result.orderStat.toString().should.equal(ORDERSTATS.ONLYLOAN.toString())
        })
      })

      describe('payback protocol', () => {

        describe('success', () => {
          beforeEach(async () => {
            result = await bnpl.payback(orderId)
          })

          it('when buyer installment correctly', async () => {
            result = await bnpl.orders(1)

          })

          it('finish bnpl process ', async () => {
            result = await bnpl.orders(1)
            result.orderStat.toString().should.equal(ORDERSTATS.FINISHED.toString(), 'order is not finished')
            result = await members.memberBnpls(buyer)
            result.stat.toString().should.equal(BNPLSTAT.NONE.toString(), 'stat does not changed!')
          })

          it('update member rank', async () => {
            result = await members.memberBnpls(buyer)
            result.rank.toString().should.equal(RANK.SILVER.toString())
            result.times.toString().should.equal('1')
            result.sum.toString().should.equal(tokens(1000).toString())
          })
        })
      })
    })
  })
})
