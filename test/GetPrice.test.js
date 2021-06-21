import { tokens, ether, EVM_REVERT, ETHER_ADDRESS } from './helpers'

const Token = artifacts.require('./Token')
const Exchange = artifacts.require('./Exchange')
const GetPrice = artifacts.require('./GetPrice')

require('chai')
  .use(require('chai-as-promised'))
  .should()


contract('GetPrice', ([deployer, deployer2, user1, user2]) => {
	let getPrice
	let result

	beforeEach(async () => {
		getPrice = await GetPrice.new()
		result = await getPrice.request()
	})

	describe('first', () => {
		it('get num between 1 to 6', async () => {
			const num = await getPrice.randomNumber()
			console.log(num.toString())	
		})
	})
})