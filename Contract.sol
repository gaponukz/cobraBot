// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0.0;

contract Pyramid {
    uint256 currentUserIdIndex; // how many users registered
    uint8 public currentGameIdIndex; // how many games aviable
    address contractOwner;

    uint constant baseAward = 74; // 74% circle award
    uint constant firstLevelReferal = 10; // 10% first level referal award
    uint constant secondLevelReferal = 6; // 6% second level referal award
    uint constant thirdLevelReferal = 4; // 4% third level referal award
    uint constant ownerReferal = 6; //6% award to owner

    struct User {
        uint256 userId;
        address payable userAddress;
        uint256 invitedId;
    }

    struct Game {
        uint256 circleCount;
        uint256 amountToPay;
    }
    
    mapping (uint8 => Game) public levels; // aviable games
    mapping (uint256 => address) public usersId; // key: user id, value: user address
    mapping (address => User) public registeredUsers; // key user address, value: user(id, invitedId)
    mapping (uint8 => uint256) public currentUserIndex; // user progress index in games
    mapping (uint8 => mapping (uint256 => User)) public pools; // user progress position in games
    mapping (address => mapping (uint8 => uint256)) public userPayments; // how mach user get payment from game
    mapping (address => mapping (uint8 => bool)) public userGames; // in what games user played

    event NewGame(Game game); // new game event
    event GamePaymentEvent(Game game, address account, bool success); // some get base game payment event
    event ReferalPaymentEvent(Game game, uint256 from, uint256 to, uint amount); // some get ref payment event

    modifier onlyRegistered {
        // access for registered users
        require(registeredUsers[msg.sender].userAddress != address(0));
        _;
    }

    modifier noContractAccess {
        // no access for contracts
        uint32 size;
        address sender = msg.sender;
        assembly { size := extcodesize(sender) }

        require(!(size > 0), "No contracts");
        _;
    }

    modifier onlyOwner {
        // access for owner
        require(hasAccess(msg.sender));
        _;
    }

    constructor () {
        contractOwner = msg.sender;
        usersId[0] = contractOwner;
        registeredUsers[contractOwner] = User(0, payable(contractOwner), 0);
        currentUserIdIndex = 1;

        addGameLevel({ circleCount: 3, amountToPay: 1 ether });
    }

    receive () external payable {
        /**
          * @dev This function allow to join the game by sending bnb on contract
          * select game by price
        */
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
        /**
          * @dev This function check in address userAdress in  contractOwner address
        */
        return userAdress == contractOwner;
    }

    function getUserBalance(address userAddress) public view returns(uint256) {
        return userAddress.balance;
    }

    function addGameLevel(uint256 circleCount, uint256 amountToPay) public onlyOwner {
        /**
          * @dev This function add new game level (only contract owner access)
        */
        levels[currentGameIdIndex] = Game({ circleCount: circleCount, amountToPay: amountToPay });
        emit NewGame(levels[currentGameIdIndex]);
        currentGameIdIndex += 1;
    }

    function registerUserToGame(uint256 inviterId) external payable noContractAccess {
        /**
          * @dev This function register user in game
        */
        require (msg.value == 1 ether, "For regiter in game you need pay 1 ether");

        registeredUsers[msg.sender] = User(currentUserIdIndex, payable(msg.sender), inviterId);
        usersId[currentUserIdIndex] = msg.sender;
        currentUserIdIndex += 1;
    }

    function joinToGame(uint8 gameId) public payable onlyRegistered {
        /**
          * @dev By this function user will join to game (gameId)
        */
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
                address payable selectedAddress = pools[gameId][winnerIndex].userAddress;

                if (userPayments[selectedAddress][gameId] <= 1 || userGames[selectedAddress][gameId+1]) {
                    (bool success, ) = selectedAddress.call{value: levels[gameId].amountToPay * baseAward / 100}("");
                    userPayments[selectedAddress][gameId] += 1;

                    emit GamePaymentEvent(levels[gameId], selectedAddress, success);

                    uint256 userId = pools[gameId][winnerIndex].userId;
                    uint256 invitedId = pools[gameId][winnerIndex].invitedId;
                    uint refValue = levels[gameId].amountToPay * firstLevelReferal / 100;

                    (success, ) = usersId[invitedId].call{value: refValue}(""); // 10% ref (1 level)

                    if (success) emit ReferalPaymentEvent(levels[gameId], userId, invitedId, refValue);

                    refValue = levels[gameId].amountToPay * secondLevelReferal / 100;
                    (success, ) = registeredUsers[usersId[invitedId]].userAddress.call{value: refValue}(""); // 2% ref (2 level)      

                    if (success) emit ReferalPaymentEvent(levels[gameId], invitedId, registeredUsers[usersId[invitedId]].userId, refValue);

                    refValue = levels[gameId].amountToPay * thirdLevelReferal / 100;
                    (success, ) = registeredUsers[usersId[registeredUsers[usersId[invitedId]].userId]].userAddress.call{value: refValue}("");

                    if (success) emit ReferalPaymentEvent(levels[gameId], registeredUsers[usersId[invitedId]].userId, registeredUsers[usersId[registeredUsers[usersId[invitedId]].userId]].userId, refValue);
                }

            }
        }
    }
}
