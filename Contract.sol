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

    struct Game { uint256 amountToPay; }
    
    mapping (uint8 => Game) public levels; // aviable games
    mapping (uint256 => address) public usersId; // key: user id, value: user address
    mapping (address => User) public registeredUsers; // key user address, value: user(id, invitedId)
    mapping (uint8 => uint256) public currentUserIndex; // user progress index in games
    mapping (uint8 => mapping (uint256 => User)) public pools; // user progress position in games
    mapping (address => mapping (uint8 => uint256)) public userPayments; // how mach user get payment from game
    mapping (address => mapping (uint8 => bool)) public userGames; // in what games user played

    event NewGame(uint256 amountToPay); // new game event
    event GamePaymentEvent(uint256 amountToPay, address account, bool success); // some get base game payment event
    event ReferalPaymentEvent(uint256 amountToPay, uint256 from, uint256 to, uint amount); // some get ref payment event

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

        addGameLevel({ amountToPay: 1 ether });
    }

    receive () external payable {
        _fallback(msg.sender, msg.value);
    }

    fallback () external payable {
        _fallback(msg.sender, msg.value);
    }

    function _fallback(address sender, uint256 value) internal {
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
        _joinToGame(gameId, sender, value);
    }

    function culcNextWinnerIndex(uint256 index) internal pure returns(uint256) {
        /**
            * @dev Python code example to generate winner indexes: 
            * def winner_generator(index: int) -> int:
            *     next_index = culcNextWinnerIndex(index)
            *     while (next_index != 0):
            *         yield next_index
            *         next_index = culcNextWinnerIndex(next_index)
            *
            * >>> winner_generator(31): 15, 7, 3, 1
        */   
        return index % 2 == 0 ? 0 : index / 2;
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

    function addGameLevel(uint256 amountToPay) public onlyOwner {
        /**
          * @dev This function add new game level (only contract owner access)
        */
        levels[currentGameIdIndex] = Game({ amountToPay: amountToPay });
        currentUserIndex[currentGameIdIndex] = 1;
        emit NewGame(levels[currentGameIdIndex].amountToPay);
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
        /**
          * @dev Add user to game, increase game procces index, set user already played in game
        */
        pools[gameId][currentUserIndex[gameId]] = registeredUsers[sender];
        userGames[sender][gameId] = true;
        /**
          * @dev If game progress more them game period start game logic
        */

        if (currentUserIndex[gameId] >= 3) {
            uint256 userIndex = culcNextWinnerIndex(currentUserIndex[gameId]);
            /**
                * @dev Using tree logic: after branche closing top user get payment.
            */       
            while (userIndex != 0) {
                address selectedAddress = pools[gameId][userIndex].userAddress;
                /**
                  * @dev User get payment if he alredy got payment for 2 times or bought next level
                */
                if (userPayments[selectedAddress][gameId] <= 1 || userGames[selectedAddress][gameId+1]) {
                    /**
                      * @dev There we distribute the award: circle user + referal (first/second/third levels) + owner payment
                    */
                    (bool success, ) = selectedAddress.call{value: levels[gameId].amountToPay * baseAward / 100}("");
                    userPayments[selectedAddress][gameId] += 1; // increase "how many payments get from game" value

                    emit GamePaymentEvent(levels[gameId].amountToPay, selectedAddress, success);

                    uint256 userId = pools[gameId][userIndex].userId; // user (who get payment) id
                    uint256 invitedId = pools[gameId][userIndex].invitedId; // person (who invited this user) id
                    uint refValue = levels[gameId].amountToPay * firstLevelReferal / 100; // first level referal

                    (success, ) = usersId[invitedId].call{value: refValue}("");

                    if (success) emit ReferalPaymentEvent(levels[gameId].amountToPay, userId, invitedId, refValue);

                    refValue = levels[gameId].amountToPay * secondLevelReferal / 100; // second level referal
                    (success, ) = registeredUsers[usersId[invitedId]].userAddress.call{value: refValue}(""); // 2% ref (2 level)      

                    if (success) emit ReferalPaymentEvent(levels[gameId].amountToPay, invitedId, registeredUsers[usersId[invitedId]].userId, refValue);

                    refValue = levels[gameId].amountToPay * thirdLevelReferal / 100; // third level referal
                    (success, ) = registeredUsers[usersId[registeredUsers[usersId[invitedId]].userId]].userAddress.call{value: refValue}("");

                    if (success) emit ReferalPaymentEvent(levels[gameId].amountToPay, registeredUsers[usersId[invitedId]].userId, registeredUsers[usersId[registeredUsers[usersId[invitedId]].userId]].userId, refValue);
                    /**
                      * @dev There contract owner get his 6% game award
                    */
                    refValue = levels[gameId].amountToPay * ownerReferal / 100; // owner referal
                    (success, ) = registeredUsers[contractOwner].userAddress.call{value: refValue}("");

                    if (success) emit ReferalPaymentEvent(levels[gameId].amountToPay, userId, registeredUsers[contractOwner].userId, refValue);

                    userIndex = culcNextWinnerIndex(userIndex);
                }
            }
        }
        /**
          * @dev Increase game procces index
        */
        currentUserIndex[gameId] += 1;
    }
}
