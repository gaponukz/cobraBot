# cobraBot


| File | Description |
| :--- | :--- |
| `Contract.sol` | Main Solidity Smart contract for Cobra project |
| `tree_algorithm.py` | Python file to describe "winner payment" algorithm (will not use anywere) |
| `/test/Pyramid.js` | Mocha web3.js unit tests of `Contract.sol` (or `Pydamid.sol`) |
| `bot.py` | Telegram bot for notify all contract events |
| `db.py` | It used in `bot.py` as database. TODO: replace it with mongoDB |
| `signed_users.json` | It used in `db.py`, users list |
| `languages.json` | Config file with languages we will use in Telegram bot |
| `contract.json` | Smart contract address and abi |

## Smart contract usage

For play in game you need to be registered, so you can do it with that function (inviterId - id of user who invited you)
```solidity
function registerUserToGame(uint256 inviterId) external payable noContractAccess { }
```
Select you game (index start from zero) by gameId and join to game 
```solidity
function joinToGame(uint8 gameId) external payable onlyRegistered { }
```
Owner can add new game
```solidity
function addGameLevel(uint256 amountToPay) public onlyOwner { }
```
