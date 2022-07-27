# cobraBot


| File | Description |
| :--- | :--- |
| `Contract.sol` | Main Solidity Smart contract for Cobra project |
| `tree_algorithm.py` | Python file to describe "winner payment" algorithm (will not use anywere) |
| `/test/Pyramid.js` | Mocha web3.js unit tests of `Contract.sol` (or `Pydamid.sol`) |
| `bot.py` | Telegram bot for notify all contract events |
| `db.py` | It used in `bot.py` as database. TODO: replace it with mongoDB |
| `signed_users.json` | It used in `db.py`, users list |
| `notify_scheduler.json` | List of notification we will send to users (new game soon etc) |
| `languages.json` | Config file with languages we will use in Telegram bot |
| `contract.json` | Smart contract address and abi |
| `logger.log` | Log file with all exception |

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
![contract_proof](https://user-images.githubusercontent.com/49754258/181386102-1bf8c22c-0288-4653-a65f-8b62a8033925.png)
