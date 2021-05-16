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

    // Transfer some tokens to user1
    token.transfer(client, tokens(100), { from: deployer })

    // Deploy exchange
    bnpl = await Bnpl.new(deployer, feeAccount, feePercent)
  })

  describe('deployment', () => {
    it('tracks the defiCompany account', async () => {
     const result = await bnpl.owner()
     result.should.equal(feeAccount)
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
  })
    // beforeEach(async () => {
    //   // user1 deposits ether only
    //   await exchange.depositEther({ from: user1, value: ether(1) })
    //   // give tokens to client
    //   await token.transfer(client, tokens(100), { from: deployer })

    //   // client deposits tokens only
    //   await token.approve(bnpl.address, tokens(100), { from: client })
    //   await bnpl.depositToken(token.address, tokens(100), { from: client })

    //   // client makes an order to buy tokens with Ether
    //   await bnpl.makeBnplOrder(token.address, tokens(1), ETHER_ADDRESS, ether(1), { from: user1 })

    // })

  //   describe('filling orders', () => {
  //     let result

  //     describe('success', () => {
  //       beforeEach(async () => {
  //         // user2 fills order
  //         result = await exchange.fillOrder('1', { from: user2 })
  //       })
  //       //user2 should receive 10% less ether
  //       it('executes the trade & charges fees', async () => {
  //         let balance
  //         balance = await exchange.balanceOf(token.address, user1)
  //         balance.toString().should.equal(tokens(1).toString(), 'user1 received tokens')
  //         balance = await exchange.balanceOf(ETHER_ADDRESS, user2)
  //         balance.toString().should.equal(ether(1).toString(), 'user2 received Ether')
  //         balance = await exchange.balanceOf(ETHER_ADDRESS, user1)
  //         balance.toString().should.equal('0', 'user1 Ether deducted')
  //         balance = await exchange.balanceOf(token.address, user2)
  //         balance.toString().should.equal(tokens(0.9).toString(), 'user2 tokens deducted with fee applied')
  //         const feeAccount = await exchange.feeAccount()
  //         balance = await exchange.balanceOf(token.address, feeAccount)
  //         balance.toString().should.equal(tokens(0.1).toString(), 'feeAccount received fee')
  //       })

  //       it('updates filled orders', async () => {
  //         const orderFilled = await exchange.orderFilled(1)
  //         orderFilled.should.equal(true)
  //       })

  //       it('emits a "Trade" event', () => {
  //         const log = result.logs[0]
  //         log.event.should.eq('Trade')
  //         const event = log.args
  //         event.id.toString().should.equal('1', 'id is correct')
  //         event.user.should.equal(user1, 'user is correct')
  //         event.tokenGet.should.equal(token.address, 'tokenGet is correct')
  //         event.amountGet.toString().should.equal(tokens(1).toString(), 'amountGet is correct')
  //         event.tokenGive.should.equal(ETHER_ADDRESS, 'tokenGive is correct')
  //         event.amountGive.toString().should.equal(ether(1).toString(), 'amountGive is correct')
  //         event.userFill.should.equal(user2, 'userFill is correct')
  //         event.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
  //       })
  //     })

  //     describe('failure', () => {

  //       it('rejects invalid order ids', () => {
  //         const invalidOrderId = 99999
  //         exchange.fillOrder(invalidOrderId, { from: user2 }).should.be.rejectedWith(EVM_REVERT)
  //       })

  //       it('rejects already-filled orders', () => {
  //         // Fill the order
  //         exchange.fillOrder('1', { from: user2 }).should.be.fulfilled
  //         // Try to fill it again
  //         exchange.fillOrder('1', { from: user2 }).should.be.rejectedWith(EVM_REVERT)
  //       })

  //       it('rejects cancelled orders', () => {
  //         // Cancel the order
  //         exchange.cancelOrder('1', { from: user1 }).should.be.fulfilled
  //         // Try to fill the order
  //         exchange.fillOrder('1', { from: user2 }).should.be.rejectedWith(EVM_REVERT)
  //       })
  //     })

    // describe('cancelling orders', () => {
    //   let result

    //   describe('success', async () => {
    //     beforeEach(async () => {
    //       result = await exchange.cancelOrder('1', { from: user1 })
    //     })

    //     it('updates cancelled orders', async () => {
    //       const orderCancelled = await exchange.orderCancelled(1)
    //       orderCancelled.should.equal(true)
    //     })

    //     it('emits a "Cancel" event', () => {
    //       const log = result.logs[0]
    //       log.event.should.eq('Cancel')
    //       const event = log.args
    //       event.id.toString().should.equal('1', 'id is correct')
    //       event.user.should.equal(user1, 'user is correct')
    //       event.tokenGet.should.equal(token.address, 'tokenGet is correct')
    //       event.amountGet.toString().should.equal(tokens(1).toString(), 'amountGet is correct')
    //       event.tokenGive.should.equal(ETHER_ADDRESS, 'tokenGive is correct')
    //       event.amountGive.toString().should.equal(ether(1).toString(), 'amountGive is correct')
    //       event.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
    //     })
    //   })

    //   describe('failure', () => {
    //     it('rejects invalid order ids', () => {
    //       const invalidOrderId = 99999
    //       exchange.cancelOrder(invalidOrderId, { from: user1 }).should.be.rejectedWith(EVM_REVERT)
    //     })

    //     it('rejects unauthorized cancelations', async () => {
    //       // Try to cancel the order from another user
    //       await exchange.cancelOrder('1', { from: user2 }).should.be.rejectedWith(EVM_REVERT)
    //     })
    //   })
    // })
  //})

  // describe('fillOrder()', () => {
  //   describe('Check balances after filling user1 buy Tokens order', () => {
  //     beforeEach(async () => {
  //       // user1 deposit 1 ETHER to the exchange
  //       await exchange.depositEther({from: user1, value: ether(1)})
  //       // user1 create order to buy 10 tokens for 1 ETHER
  //       await exchange.makeOrder(token.address, tokens(10), ETHER_ADDRESS, ether(1), {from: user1})
  //       // user2 gets tokens
  //       await token.transfer(user2, tokens(11), {from: deployer})
  //       // user2 approve exchange to spend his tokens
  //       await token.approve(exchange.address, tokens(11), {from: user2})
  //       // user2 deposit tokens + fee cost (1 token) to the exchange
  //       await exchange.depositToken(token.address, tokens(11), {from: user2})
  //       // user2 fills the order
  //       await exchange.fillOrder('1', {from: user2})
  //     })

  //     it('user1 tokens balance on exchange should eq. 10', async () => {
  //       await (await exchange.balanceOf(token.address, user1)).toString().should.eq(tokens(10).toString())
  //     })

  //     it('user1 ether balance on exchange should eq. 0', async () => {
  //       await (await exchange.balanceOf(ETHER_ADDRESS, user1)).toString().should.eq('0')
  //     })

  //     it('user2 tokens balance on exchange should eq. 0', async () => {
  //       await (await exchange.balanceOf(token.address, user2)).toString().should.eq('0')
  //     })

  //     it('user2 ether balance on exchange should eq. 1', async () => {
  //       await (await exchange.balanceOf(ETHER_ADDRESS, user2)).toString().should.eq(ether(1).toString())
  //     })
  //   })

  //   describe('Check balances after filling user1 buy Ether order', () => {
  //     beforeEach(async () => {
  //       // Uuser1 Gets the 10 tokens
  //       await token.transfer(user1, tokens(10), {from: deployer})
  //       // user1 approve exchange to spend his tokens
  //       await token.approve(exchange.address, tokens(10), {from: user1})
  //       // user1 approve send tokens to the exchange 
  //       await exchange.depositToken(token.address, tokens(10), {from: user1})
  //       // user1 create order to buy 1 Ether for 10 tokens
  //       await exchange.makeOrder(ETHER_ADDRESS, ether(1), token.address, tokens(10), {from: user1})
  //       // user2 deposit 1 ETHER + fee cost (.1 ETH) to the exchange
  //       await exchange.depositEther({from: user2, value: ether(1.1)})
  //       // user2 fills the order
  //       await exchange.fillOrder('1', {from: user2})
  //     })

  //     it('user1 tokens balance on exchange should eq. 0', async () => {
  //       await (await exchange.balanceOf(token.address, user1)).toString().should.eq('0')
  //     })

  //     it('user1 Ether balance on exchange should eq. 1', async () => {
  //       await (await exchange.balanceOf(ETHER_ADDRESS, user1)).toString().should.eq(ether(1).toString())
  //     })

  //     it('user2 tokens balance on exchange should eq. 10', async () => {
  //       await (await exchange.balanceOf(token.address, user2)).toString().should.eq(tokens(10).toString())
  //     })

  //     it('user2 ether balance on exchange should eq. 0', async () => {
  //       await (await exchange.balanceOf(ETHER_ADDRESS, user2)).toString().should.eq('0')
  //     })
  //   })
  // })

})