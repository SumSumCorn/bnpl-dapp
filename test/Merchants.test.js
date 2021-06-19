import { tokens, EVM_REVERT } from './helpers'

const Merchants = artifacts.require('./Merchants')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Merchants', ([bnplCompany, seller1, seller2]) => {
  let merchants

  beforeEach(async () => {
    merchants = await Merchants.new(bnplCompany)
  })

  describe('deployment', () => {
    it('contract owner is correct', async () => {
      const result = await merchants.owner()
      result.should.equal(bnplCompany)
    })
  })

  describe('one is registering sellers', () => {
    let result
    describe('success', () => {
      beforeEach(async () => {
        result = await merchants.registerSeller(seller1, { from: bnplCompany } )
      })
      it('accepts when bnplCompany and emit event', async () => {
        const log = result.logs[0]
        log.event.should.eq('RegisterLicense')
        const event = log.args
        event.licenser.should.equal(bnplCompany, 'licenser is correct')
        event.licensee.should.equal(seller1, 'licensee is correct')
      })
    })

    describe('failure', () => {
      it('rejects invaild registering', async () => {
        result = await merchants.registerSeller(seller1, { from: seller1 } ).should.be.rejected
      })
    })
  })

  describe('check one is sellers or not', () => {
    let result
    beforeEach(async () => {
      merchants.registerSeller(seller1, { from: bnplCompany })
    })

    it('seller1 is auth and seller2 is not', async () => {
      result = await merchants.isAuth(seller1)
      result.should.equal(true)

      result = await merchants.isAuth(seller2)
      result.should.equal(false)
    })
  })

  describe('setting and getting product', () => {
    const prodName = 'channel'
    const serialNum = 'no5'
    const price = tokens(1000)

    let result
    beforeEach(async () => {
      result = await merchants.registerSeller(seller1, { from: bnplCompany })
      result = await merchants.setProduct(prodName, serialNum, price, { from: seller1 })
    })

    describe('success', () => {
      it('emits RegisterProduct', async () => {
        const log = result.logs[0]
        log.event.should.eq('RegisterProduct')
        const event = log.args
        event.seller.should.equal(seller1, 'seller is correct')
        event.prodCnt.toString().should.equal('1', 'prodCnt is correct') 
      })

      it('checks production count number of seller1', async () => {
        result = await merchants.prodCnt(seller1)
        result.toString().should.equal('1')
      })

      it('checks registerd product is alright', async () => {
        result = await merchants.products(seller1,1)
        result[0].should.equal(prodName)
        result[1].should.equal(serialNum)
        result[2].toString().should.equal(price.toString())
      })

      it('checks getProduct is correct', async () => {
        result = await merchants.getProduct(seller1, 1)
        result[0].should.equal(prodName)
        result[1].should.equal(serialNum)
        result[2].toString().should.equal(price.toString())
      })

    })

    describe('failure', () => {
      it('accesses wrong seller', async () => {
        result = await merchants.getProduct(seller2, 1).should.be.rejected
      })

      it('accesses wrong number', async () => {
        result = await merchants.getProduct(seller1, 2).should.be.rejected
      })
    })
  })
  
})