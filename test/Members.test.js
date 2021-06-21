import { tokens, ether, EVM_REVERT, ETHER_ADDRESS } from './helpers'

const Members = artifacts.require('./Members')
const Bnpl = artifacts.require('./Bnpl')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('Members', ([bnplCompany, feeAccount, payee, buyer, seller, carrier]) => {
  let bnpl
  let members
  let result

  const RANK = {
    BRONZE: 0,
    SILVER: 1,
    GOLD: 2
  }


  beforeEach(async () => {
    bnpl = await Bnpl.new({ from:bnplCompany })
    members = await Members.new(bnpl.address, { from:bnplCompany })
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
      result = await members.owner1()
      result.should.equal(bnplCompany)
      result = await members.owner2()
      result.should.equal(bnpl.address)
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
      let result = await members.memberInfos(buyer)
      result.name.should.equal(_name)
      result.socialNumber.should.equal(_socialNumber)
      result.phoneNumber.should.equal(_phoneNumber)
      result.bankName.should.equal(_bankName)
      result.accountNumber.should.equal(_accountNumber)
    })
    // event

  })

  describe('member rank update', () => {
    beforeEach(async () => {
      await members.updateMemberBnpls(buyer,tokens(500))
      await members.updateMemberBnpls(buyer,tokens(500))
    })

    it('check it becomes bronze', async () => {
      result = await members.memberBnpls(buyer)
      //console.log(result)
      result.rank.toNumber().should.equal(RANK.BRONZE)

    })


    // it('check it becomes silver', () => {
        
        // emit check
    // })

    // it('check it becomes gold', () => {
      
        // emit check
    // })

  })
})