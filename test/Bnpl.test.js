import { tokens, ether, EVM_REVERT, ETHER_ADDRESS } from './helpers'

const Token = artifacts.require('./Token')
const Exchange = artifacts.require('./Exchange')
const Bnpl = artifacts.require('./Bnpl')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Bnpl', ([deployer, feeAccount, client, seller, rebalancer]) => {
  let token
  let bnpl
  const feePercent = 10
  const gasPrice = ether(0.00206736)

  beforeEach(async () => {
    // Deploy token
    token = await Token.new()

    // // Transfer some tokens to user1
    // token.transfer(client, tokens(100), { from: deployer })

    // Deploy exchange
    bnpl = await Bnpl.new(deployer, feeAccount, feePercent)
  })

  describe('deployment', () => {
    it('tracks the defiCompany account', async () => {
      const result = await bnpl.owner()
      result.should.equal(deployer)
    })

    it('tracks the fee percent', async () => {
     const result = await bnpl.feePercent()
     result.toString().should.equal(feePercent.toString())
    })
  })

  describe('making orders', () => {
    let result
    beforeEach(async () => {
      result = await bnpl.makeBnplOrder(seller, token.address, tokens(10), tokens(5), 1, { from : client })
    })

    it('tracks the newly created order', async () => {
      const orderCount = await bnpl.orderCount()
      orderCount.toString().should.equal('1')

      const order = await bnpl.orders('1')
      order.id.toString().should.equal('1', 'id is correct')
      order.buyer.should.equal(client, 'buyer is correct')
      order.seller.should.equal(seller, 'seller is correct')
      order.token.should.equal(token.address, 'token is correct')
      order.totalPrice.toString().should.equal(tokens(10).toString(), 'totalPrice is correct')
      order.initcost.toString().should.equal(tokens(5).toString(), 'initcost is correct')
      order.installmentPeriod.toString().should.equal('1', 'amountGive is correct')
      order.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
    })

    it('emits an "Order" event', () => {
      const log = result.logs[0]
      log.event.should.eq('Order')
      const event = log.args
      event.id.toString().should.equal('1', 'id is correct')
      event.buyer.should.equal(client, 'client is correct')
      event.seller.should.equal(seller, 'seller is correct')
      event.totalPrice.toString().should.equal(tokens(10).toString(), 'totalPrice is correct')
      event.initcost.toString().should.equal(tokens(5).toString(), 'initcost is correct')
      event.installmentPeriod.toString().should.equal('1', 'amountGive is correct')
      event.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
    })
  })
  
  describe('order actions', () => {
    let result

    beforeEach(async () => {
      // // user1 deposits ether only
      // await exchange.depositEther({ from: client, value: ether(1) })
      // give tokens to client
      await token.transfer(client, tokens(100), { from: deployer })

      // client deposits tokens only
      await token.approve(bnpl.address, tokens(100), { from: client })
      await bnpl.depositToken(token.address, tokens(100), { from: client })

      
      // client fills order
      result = await bnpl.makeBnplOrder(seller, token.address, tokens(10), tokens(5), 1, { from : client })
    })

    describe('filling orders', () => {
      let result
      describe('success', () => {
        let targetNumber
        it('BNPL company fills orders', async () => {
          targetNumber = 1
          result = await bnpl.fillBnplOrder(targetNumber)

          const orderFilled = await bnpl.orderFilled(1)
          orderFilled.should.equal(true)

          let balance
          // client sub init cost
          balance = await bnpl.balanceOf(token.address, client)
          balance.toString().should.equal(tokens(95).toString(), 'client sub tokens')
          // defi company gets init cost 
          balance = await bnpl.balanceOf(token.address, feeAccount)
          balance.toString().should.equal(tokens(5).toString(), 'feeAccount get tokens')
        })

        it('check trade 1', async () => {

          // defi company gets init cost 
          //balance = await bnpl.balanceOf(token.address, feeAccount)
          //balance.toString().should.equal(tokens(5).toString(), 'feeAccount get tokens')

          //tokens

        })

        it('emits a "Fill" event', () => {
          const log = result.logs[0]
          log.event.should.eq('Fill')
          const event = log.args
          event.id.toString().should.equal('1', 'id is correct')
          event.buyer.should.equal(client, 'client is correct')
          event.seller.should.equal(seller, 'seller is correct')
          event.totalPrice.toString().should.equal(tokens(10).toString(), 'totalPrice is correct')
          event.initcost.toString().should.equal(tokens(5).toString(), 'initcost is correct')
          event.installmentPeriod.toString().should.equal('1', 'amountGive is correct')
          event.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
        })
      })
    })
  })


})