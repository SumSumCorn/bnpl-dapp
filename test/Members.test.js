import { tokens, ether, EVM_REVERT, ETHER_ADDRESS } from './helpers'

const Members = artifacts.require('./Members')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Members', ([bnplCompany, feeAccount, payee, buyer, seller, carrier]) => {
  let members
  let result

  beforeEach(async () => {
    members = await Members.new({from:bnplCompany})
  })

  describe('creation', async () => {
    it('deploys successfully', async () => {
      assert.notEqual(members.address, 0x0)
      assert.notEqual(members.address, '')
      assert.notEqual(members.address, null)
      assert.notEqual(members.address, undefined)
    })
  })

  describe('deployment', () => {
    it('check contract owner', async () => {
      result = await members.owner()
      result.should.equal(bnplCompany)
    })
  })

  describe('init member', () => {
    const _name = '허민권'
    const _socialNumber = '961125-1234567'
    const _phoneNumber = '010-1234-5678'
    const _bankName  = '농협'
    const _accountNumber = '123-456-789'
    beforeEach(async () => {
      result = await members.initMemberInfo(
        buyer,
        _name, 
        _socialNumber, 
        _phoneNumber, 
        _bankName,
        _accountNumber,
        { from:bnplCompany })
    })
    it('check init correctly', async () => {
      let info1, info2, info3, info4, info5
      info1, info2, info3, info4, info5 = await members.getMemberinfo(buyer)
      //console.log(info1)
      //info1.toString().should.equal(_name)
      assert.typeOf(info1, 'string')
    })

  })
})