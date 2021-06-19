const Package = artifacts.require('./Package.sol')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Package', (accounts) => {
  let product, creator, sender, receiver

  const STATUSES = {
    CREATED: 0,
    SENT: 1,
    RECEIVED: 2
  }

  before(async () => {
    product = await Package.new('Channel', 1)
    creator = accounts[0]
  })

  describe('creation', async () => {
    it('deploys successfully', async () => {
      assert.notEqual(product.address, 0x0)
      assert.notEqual(product.address, '')
      assert.notEqual(product.address, null)
      assert.notEqual(product.address, undefined)
    })

    it('sets the name', async () => {
      const name = await product.name()
      assert.equal(name, 'Channel')
    })

    it('sets the manager', async () => {
      const manager = await product.manager()
      assert.equal(manager, creator)
    })

    it('sets the status', async () => {
      const status = await product.status()
      assert.equal(status, STATUSES.CREATED)
    })

    it('logs an state', async () => {
      const states = await product.getPastEvents('State', { fromBlock: 0, toBlock: 'latest' } )
      const state = states[states.length - 1].args
      assert.equal(state.name, 'CREATE')
      assert.equal(state.account, creator)
      assert.equal(state.manager, creator)
      assert.typeOf(state.timestamp, 'object')
    })
  })

  describe('send()', async () => {

    describe('SUCCESS', async() => {

      before(async () => {
        sender = accounts[0]
        receiver = accounts[1]
        await product.send(receiver, { from: sender })
      })

      it('sets the manager', async () => {
        const manager = await product.manager()
        assert.equal(manager, receiver)
      })

      it('sets the status', async () => {
        const status = await product.status()
        assert.equal(status, STATUSES.SENT)
      })

      it('logs an state', async () => {
        const states = await product.getPastEvents('State', { fromBlock: 0, toBlock: 'latest' } )
        const state = states[states.length - 1].args
        assert.equal(state.name, 'SEND')
        assert.equal(state.account, sender)
        assert.equal(state.manager, receiver)
        assert.typeOf(state.timestamp, 'object')
      })
    })

    describe('FAILURE', async() => {

      it('must be SENT by manager', async () => {
        sender = accounts[1] // Receiver cannot send
        receiver = accounts[1]
        await product.send(receiver, { from: sender }).should.be.rejected;
      })

      it('manager cannot be recipient', async () => {
        sender = accounts[0]
        receiver = accounts[0] // Cannot be manager
        await product.send(receiver, { from: receiver }).should.be.rejected;
      })

    })


  })

  describe('receive()', async () => {

    describe('SUCCESS', async() => {

      before(async () => {
        receiver = accounts[1]
        await product.receive({ from: receiver })
      })

      it('sets the manager', async () => {
        const manager = await product.manager()
        assert.equal(manager, receiver)
      })

      it('sets the status', async () => {
        const status = await product.status()
        assert.equal(status, STATUSES.RECEIVED)
      })

      it('logs an state', async () => {
        const states = await product.getPastEvents('State', { fromBlock: 0, toBlock: 'latest' } )
        const state = states[states.length - 1].args
        assert.equal(state.name, 'RECEIVE')
        assert.equal(state.account, receiver)
        assert.equal(state.manager, receiver)
        assert.typeOf(state.timestamp, 'object')
      })
    })

    describe('FAILURE', async() => {

      it('must be RECEIVED by manager', async () => {
        receiver = accounts[9] // Some other account
        await product.receive({ from: receiver }).should.be.rejected;
      })

    })


  })
})
