// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0.0;

contract Pyramid {
    uint256 currentUserIdIndex;
    uint8 public currentGameIdIndex;
    address contractOwner;

    struct User {
        uint256 userId;
        address payable userAdsress;
        uint256 invitedId;
    }

    struct Game {
        uint256 circleCount;
        uint256 amountToPay;
        uint256 sendWinnerAmount;
    }
    
    mapping (uint8 => Game) public levels;
    mapping (uint256 => address) public usersId;
    mapping (address => User) public registeredUsers;
    mapping (uint8 => uint256) public currentUserIndex;
    mapping (uint8 => mapping (uint256 => User)) public pools;
    mapping (address => mapping (uint8 => uint256)) public userPayments;
    mapping (address => mapping (uint8 => bool)) public userGames;

    event NewGame(Game game);
    event GamePaymentEvent(Game game, address account, bool success);

    modifier onlyRegistered {
        require(registeredUsers[msg.sender].userAdsress != address(0));
        _;
    }

    modifier noContractAccess {
        uint32 size;
        address sender = msg.sender;
        assembly { size := extcodesize(sender) }

        require(!(size > 0), "No contracts");
        _;
    }

    modifier onlyOwner {
        require(hasAccess(msg.sender));
        _;
    }

    constructor () {
        contractOwner = msg.sender;
        currentUserIdIndex = 1;
        addGameLevel({ 
            circleCount: 3, 
            amountToPay: 1 ether, 
            sendWinnerAmount: 1.5 ether 
        });
    }

    receive () external payable {
        bool success;
        uint8 gameId;

        for (uint8 index; index < currentGameIdIndex+1; index++) {
            if (levels[index].amountToPay == msg.value) {
                success = true;
                gameId = index;
                break;
            }
        }
        
        require(success, "Game not found");
        _joinToGame(gameId, msg.sender, msg.value);
    }

    function hasAccess(address userAdress) public view returns(bool) {
        return userAdress == contractOwner;
    }

    function getUserBalance(address userAdsress) public view returns(uint256) {
        return userAdsress.balance;
    }

    function addGameLevel(uint256 circleCount, uint256 amountToPay, uint256 sendWinnerAmount) public onlyOwner {
        levels[currentGameIdIndex] = Game({ circleCount: circleCount, amountToPay: amountToPay, sendWinnerAmount: sendWinnerAmount });
        emit NewGame(levels[currentGameIdIndex]);
        currentGameIdIndex += 1;
    }

    function registerUserToGame(uint256 inviterId) external payable noContractAccess returns(uint256) {
        require (msg.value == 1 ether, "For regiter in game you need pay 1 ether");

        registeredUsers[msg.sender] = User(currentUserIdIndex, payable(msg.sender), inviterId);
        usersId[currentUserIdIndex] = msg.sender;
        currentUserIdIndex += 1;

        return currentUserIdIndex - 1;
    }

    function joinToGame(uint8 gameId) public payable onlyRegistered {
        _joinToGame(gameId, msg.sender, msg.value);
    }

    function _joinToGame(uint8 gameId, address sender, uint256 value) internal {
        require (value >= levels[gameId].amountToPay, "Insufficient amount of contribution");

        uint256 index = currentUserIndex[gameId];

        pools[gameId][index] = registeredUsers[sender];
        currentUserIndex[gameId] += 1;
        userGames[sender][gameId] = true;

        if (index >= levels[gameId].circleCount) {
            for (uint circle = 1; circle <= index / levels[gameId].circleCount; circle++) {
                uint256 winnerIndex = index -  circle * levels[gameId].circleCount;
                address payable selectedAddress = pools[gameId][winnerIndex].userAdsress;

                if (userPayments[selectedAddress][gameId] <= 1 || userGames[selectedAddress][gameId+1]) {
                    (bool success, ) = selectedAddress.call{value: levels[gameId].amountToPay * 3 / 4}("");
                    userPayments[selectedAddress][gameId] += 1;

                    emit GamePaymentEvent(levels[gameId], selectedAddress, success);
                }

                // TODO: referal system
            }
        }
    }
}
