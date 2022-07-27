const Pyramid = artifacts.require("Pyramid")
const { solidity } = require('ethereum-waffle')
const chai = require('chai');

chai.use(solidity);
const accountsNumber = 1500

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Pyramid contract", () => {
    let accounts

    before(async () => {
        accounts = await web3.eth.getAccounts()
        // console.log(accounts.length)
    })

    describe("Deployment", () => {
        it("Should deploy with the right pyramid", async () => {
            const pyramid = await Pyramid.new()
            /**
             * @note After compiling contract we have 1 game
            */
            assert.equal(await pyramid.currentGameIdIndex(), 1)

            await pyramid.addGameLevel("100") // after adding new game
            assert.equal(await pyramid.currentGameIdIndex(), 2) // we should have 2 games
            /**
             * @note Check access (isContractOwner/isOwner)
            */
            assert.equal(await pyramid.hasAccess(accounts[0]), true)
            assert.equal(await pyramid.hasAccess(accounts[1]), false)

            /**
             * @note After compiling contract we have 1 user (owner)
            */   
            assert.equal(await pyramid.currentUserIdIndex(), 1)

            await pyramid.registerUserToGame(0, {from: accounts[accountsNumber+1], value: web3.utils.toWei('0.0001', 'ether')}) // afer adding new user
            assert.equal(await pyramid.currentUserIdIndex(), 2) // we should have 2 users
        })

        it("Should not giving access...", async () => {
            const pyramid = await Pyramid.new()

            /**
             * @dev Only owner can add new games
            */
            await expect(pyramid.addGameLevel("100", {from: accounts[1]})).to.be.revertedWith("You are not owner")

            /**
             * @dev You can not register for more than 1 time
            */
            await expect(pyramid.registerUserToGame(0, {from: accounts[0], value: web3.utils.toWei('0.0001', 'ether')})).to.be.revertedWith("You are already registered")

            /**
             * @dev You can not join to game if you have not enough amount
            */
            await expect(pyramid.joinToGame(0, {from: accounts[0], value: web3.utils.toWei('0.5', 'ether')})).to.be.revertedWith("Insufficient amount of contribution")
        })

        it("Should work without bugs", async () => {
            const pyramid = await Pyramid.new()
            /**
             * @note We will test game 1 with accountsNumber accounts
             * all users will register in game and join to game 1 (except owner, he already registered)
            */

            pyramid.joinToGame(0, {from: accounts[0], value: web3.utils.toWei('1', 'ether')}) // owner join to game

            for (let index = 1; index < accountsNumber; index++) {
                let account = accounts[index]

                await pyramid.registerUserToGame(0, {from: account, value: web3.utils.toWei('0.0001', 'ether')}) // register user to game
                await pyramid.joinToGame(0, {from: account, value: web3.utils.toWei('1', 'ether')}) // join to game
            }
            /**
             * @note Check if all accounts in game
            */   
            assert.equal(await pyramid.currentUserIdIndex(), accountsNumber)
            assert.equal(await pyramid.currentUserIndex(0), accountsNumber)
            /**
             * @note Check accounts balances
            */   
            // for (let index = 0; index < accountsNumber; index++) {
            //     console.log(index+1, web3.utils.fromWei(await web3.eth.getBalance(accounts[index])))
            // }
        })

        it("Should work without interface", async () => {
            /**
             * @dev Accounts can play in game even if site is not available, users will send bnb amount at contract address
             * Contract must find game by amount
            */  
            const accounts = await web3.eth.getAccounts()
            const pyramid = await Pyramid.new()

            pyramid.joinToGame(0, {from: accounts[0], value: web3.utils.toWei('1', 'ether')}) // it is not important for owner

            for (let index = 1; index < accountsNumber; index++) {
                /**
                 * @note Accounts can not register without interface (only join to game)!
                */  
                let account = accounts[index]
                await pyramid.registerUserToGame(0, {from: account, value: web3.utils.toWei('0.0001', 'ether')}) // register user to game
            }

            for (let index = 1; index < accountsNumber; index++) {
                let account = accounts[index]

                await web3.eth.sendTransaction({from: account, to: pyramid.address,value: web3.utils.toWei('1', 'ether')})
            }

            assert.equal(await pyramid.currentUserIdIndex(), accountsNumber)
            assert.equal(await pyramid.currentUserIndex(0), accountsNumber)
        })
    })
})
