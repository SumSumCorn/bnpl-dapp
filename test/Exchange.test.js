import { tokens, ether, EVM_REVERT, ETHER_ADDRESS } from './helpers'

const Token = artifacts.require('./Token')
const Exchange = artifacts.require('./Exchange')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Exchange', ([deployer, feeAccount, user1, user2, rebalancer]) => {
  let token
  let exchange
  const EtherTokenRatio = 100
  const gasPrice = ether(0.00206736)

  beforeEach(async () => {
    // Deploy token
    token = await Token.new()

    // Transfer some tokens to user1
    token.transfer(user1, tokens(100), { from: deployer })

    // Deploy exchange
    exchange = await Exchange.new(deployer, EtherTokenRatio)
  }) 

  describe('fallback', () => {
   it('reverts when Ether is sent', () => {
      exchange.sendTransaction({ value: 1, from: user1 }).should.be.rejectedWith(EVM_REVERT)
   })
  })

  describe('depositing Ether', () => {
   let result
   let amount

   beforeEach(async () => {
     amount = ether(1)
     result = await exchange.depositEther({ from: user1, value: amount})
   })

   it('tracks the Ether deposit', async () => {
     const balance = await exchange.tokens(ETHER_ADDRESS, user1)
     balance.toString().should.equal(amount.toString())
   })

   it('emits a Deposit event', () => {
     const log = result.logs[0]
     log.event.should.eq('Deposit')
     const event = log.args
     event.token.should.equal(ETHER_ADDRESS, 'token address is correct')
     event.user.should.equal(user1, 'user address is correct')
     event.amount.toString().should.equal(amount.toString(), 'amount is correct')
     event.balance.toString().should.equal(amount.toString(), 'balance is correct')
   })
  })

  describe('withdrawing Ether', () => {
   let result
   let amount

   beforeEach(async () => {
     // Deposit Ether first
     amount = ether(1)
     await exchange.depositEther({ from: user1, value: amount })
   })

   describe('success', () => {
     beforeEach(async () => {
       // Withdraw Ether
       result = await exchange.withdrawEther(amount, { from: user1 })
     })

     it('withdraws Ether funds', async () => {
       const balance = await exchange.tokens(ETHER_ADDRESS, user1)
       balance.toString().should.equal('0')
     })

     it('emits a "Withdraw" event', () => {
       const log = result.logs[0]
       log.event.should.eq('Withdraw')
       const event = log.args
       event.token.should.equal(ETHER_ADDRESS)
       event.user.should.equal(user1)
       event.amount.toString().should.equal(amount.toString())
       event.balance.toString().should.equal('0')
     })
   })

   describe('failure', () => {
     it('rejects withdraws for insufficient balances', async () => {
       await exchange.withdrawEther(ether(100), { from: user1 }).should.be.rejectedWith(EVM_REVERT)
     })
   })
  })

  describe('depositing tokens', () => {
   let result
   let amount

   describe('success', () => {
     beforeEach(async () => {
       amount = tokens(10)
       await token.approve(exchange.address, amount, { from: user1 })
       result = await exchange.depositToken(token.address, amount, { from: user1 })
     })

     it('tracks the token deposit', async () => {
       // Check exchange token balance
       let balance
       balance = await token.balanceOf(exchange.address)
       balance.toString().should.equal(amount.toString())
       // Check tokens on exchange
       balance = await exchange.tokens(token.address, user1)
       balance.toString().should.equal(amount.toString())
     })

     it('emits a Deposit event', () => {
       const log = result.logs[0]
       log.event.should.eq('Deposit')
       const event = log.args
       event.token.should.equal(token.address, 'token address is correct')
       event.user.should.equal(user1, 'user address is correct')
       event.amount.toString().should.equal(amount.toString(), 'amount is correct')
       event.balance.toString().should.equal(amount.toString(), 'balance is correct')
     })
   })

   describe('failure', () => {
     it('rejects Ether deposits', () => {
       exchange.depositToken(ETHER_ADDRESS, tokens(10), { from: user1 }).should.be.rejectedWith(EVM_REVERT)
     })

     it('fails when no tokens are approved', () => {
       // Don't approve any tokens before depositing
       exchange.depositToken(token.address, tokens(10), { from: user1 }).should.be.rejectedWith(EVM_REVERT)
     })
   })
  })

  describe('withdrawing tokens', () => {
   let result
   let amount

   describe('success', async () => {
     beforeEach(async () => {
       // Deposit tokens first
       amount = tokens(10)
       await token.approve(exchange.address, amount, { from: user1 })
       await exchange.depositToken(token.address, amount, { from: user1 })

       // Withdraw tokens
       result = await exchange.withdrawToken(token.address, amount, { from: user1 })
     })

     it('withdraws token funds', async () => {
       const balance = await exchange.tokens(token.address, user1)
       balance.toString().should.equal('0')
     })

     it('emits a "Withdraw" event', () => {
       const log = result.logs[0]
       log.event.should.eq('Withdraw')
       const event = log.args
       event.token.should.equal(token.address)
       event.user.should.equal(user1)
       event.amount.toString().should.equal(amount.toString())
       event.balance.toString().should.equal('0')
     })
   })

   describe('failure', () => {
     it('rejects Ether withdraws', () => {
       exchange.withdrawToken(ETHER_ADDRESS, tokens(10), { from: user1 }).should.be.rejectedWith(EVM_REVERT)
     })

     it('fails for insufficient balances', () => {
       // Attempt to withdraw tokens without depositing any first
       exchange.withdrawToken(token.address, tokens(10), { from: user1 }).should.be.rejectedWith(EVM_REVERT)
     })
   })
  })

  describe('checking balances', () => {
   beforeEach(async () => {
    await exchange.depositEther({ from: user1, value: ether(1) })
   })

   it('returns user balance', async () => {
     const result = await exchange.balanceOf(ETHER_ADDRESS, user1)
     result.toString().should.equal(ether(1).toString())
   })
  })

  describe('making exchange orders', () => {
    let result
    let amount
    beforeEach(async () => {
      await exchange.depositEther({ from: user1, value: ether(1) })

      amount = tokens(100)
      await token.approve(exchange.address, amount, { from: deployer })
      result = await exchange.depositToken(token.address, amount, { from: deployer })
      amount = ether(1)
      result = await exchange.makeExchange(token.address, ETHER_ADDRESS, amount, { from: user1 })
    })

    it('tracks the newly created order', async () => {
      const exOrderCount = await exchange.exOrderCount()
      exOrderCount.toString().should.equal('1')
      const exOrder = await exchange.exOrders('1')
      exOrder.id.toString().should.equal('1', 'id is correct')
      exOrder.user.should.equal(user1, 'user is correct')
      exOrder.tokenGet.should.equal(token.address, 'tokenGet is correct')
      exOrder.amountGet.toString().should.equal(tokens(100).toString(), 'amountGet is correct')
      exOrder.tokenGive.should.equal(ETHER_ADDRESS, 'tokenGive is correct')
      exOrder.amountGive.toString().should.equal(ether(1).toString(), 'amountGive is correct')
      exOrder.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
    })

    it('emits an "exOrder" event', () => {
     const log = result.logs[0]
     log.event.should.eq('exOrder')
     const event = log.args
     event.id.toString().should.equal('1', 'id is correct')
     event.user.should.equal(user1, 'user is correct')
     event.tokenGet.should.equal(token.address, 'tokenGet is correct')
     event.amountGet.toString().should.equal(tokens(100).toString(), 'amountGet is correct')
     event.tokenGive.should.equal(ETHER_ADDRESS, 'tokenGive is correct')
     event.amountGive.toString().should.equal(ether(1).toString(), 'amountGive is correct')
     event.timestamp.toString().length.should.be.at.least(1, 'timestamp is present')
   })
  })
})