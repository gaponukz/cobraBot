// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Pyramid {
    using SafeMath for uint256; 
    uint256 public currentUserIdIndex; // how many users registered
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

    struct Game { uint8 gameId; uint256 amountToPay; }
    /*
        * @note First registered user is owner, so registeredUsers starts from 1
    */
    mapping (uint8 => Game) public levels; // aviable games
    mapping (uint256 => address) public usersId; // key: user id, value: user address
    mapping (uint256 => uint256) userPartnersCount; // number of players invited by this user(id)
    mapping (address => User) public registeredUsers; // key user address, value: user(id, invitedId)
    mapping (uint8 => uint256) public currentUserIndex; // user progress index in games
    mapping (uint8 => mapping (uint256 => User)) public pools; // user progress position in games
    mapping (address => mapping (uint8 => uint256)) public userPayments; // how mach user get payment from game
    mapping (address => mapping (uint8 => bool)) public userGames; // in what games user played

    event NewGame(uint8 gameId, uint256 amount); // new game event
    event GamePaymentEvent(uint8 gameId, address account, bool success); // someone get base game payment event
    event ReferalPaymentEvent(uint8 gameId, uint256 from, uint256 to, uint amount); // someone get ref payment event
    event NewUserRegisteredEvent(uint256 userId, uint256 inviterId, uint256 partnersCount); // new user registered by referal

    modifier onlyRegistered {
        /**
          * @dev Access for registered users
        */
        require(registeredUsers[msg.sender].userAddress != address(0));
        _;
    }

    modifier noContractAccess {
        /**
          * @dev No access for contracts
        */
        uint32 size;
        address sender = msg.sender;
        assembly { size := extcodesize(sender) }

        require(!(size > 0), "No contracts");
        _;
    }

    modifier onlyOwner {
        /**
          * @dev Access for owner
        */
        require(hasAccess(msg.sender), "You are not owner");
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

    function culcNextWinnerIndex(uint256 index) public pure returns(uint256) {
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
        return index.mod(2) == 0 ? 0 : index.div(2);
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
        levels[currentGameIdIndex] = Game({ gameId: currentGameIdIndex, amountToPay: amountToPay });
        currentGameIdIndex += 1;
        emit NewGame( currentGameIdIndex-1, amountToPay );
    }

    function registerUserToGame(uint256 inviterId) external payable noContractAccess {
        /**
          * @dev This function register user in game
        */
        require(registeredUsers[msg.sender].userAddress == address(0), "You are already registered");
        require (msg.value == 0.0001 ether, "For regiter in game you need pay");

        registeredUsers[msg.sender] = User(currentUserIdIndex, payable(msg.sender), inviterId);
        usersId[currentUserIdIndex] = msg.sender;
        currentUserIdIndex += 1;
        userPartnersCount[inviterId] += 1;

        emit NewUserRegisteredEvent(currentUserIdIndex - 1, inviterId, userPartnersCount[inviterId]);
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
        currentUserIndex[gameId] += 1;
        /**
          * @dev If game progress more them game period start game logic
        */

        if (currentUserIndex[gameId] >= 3) {
            uint256 userIndex = culcNextWinnerIndex(currentUserIndex[gameId]);
            /**
                * @dev Using tree logic: after branche closing top user get payment.
            */       
            while (userIndex != 0) {
                address selectedAddress = pools[gameId][userIndex - 1].userAddress;
                /**
                  * @dev User get payment if he alredy got payment for 2 times or bought next level
                */
                if (userPayments[selectedAddress][gameId] <= 1 || userGames[selectedAddress][gameId+1]) {
                    /**
                      * @dev There we distribute the award: circle user + referal (first/second/third levels) + owner payment
                    */
                    (bool success, ) = selectedAddress.call{value: levels[gameId].amountToPay.mul(baseAward).div(100)}("");
                    userPayments[selectedAddress][gameId] += 1; // increase "how many payments get from game" value

                    emit GamePaymentEvent(levels[gameId].gameId, selectedAddress, success);

                    uint256 userId = pools[gameId][userIndex - 1].userId; // user (who get payment) id
                    uint256 invitedId = pools[gameId][userIndex - 1].invitedId; // person (who invited this user) id
                    uint refValue = levels[gameId].amountToPay.mul(firstLevelReferal).div(100); // first level referal

                    (success, ) = usersId[invitedId].call{value: refValue}("");

                    if (success) emit ReferalPaymentEvent(levels[gameId].gameId, userId, invitedId, refValue);

                    refValue = levels[gameId].amountToPay.mul(secondLevelReferal).div(100); // second level referal
                    (success, ) = registeredUsers[usersId[invitedId]].userAddress.call{value: refValue}(""); // 2% ref (2 level)      

                    if (success) emit ReferalPaymentEvent(levels[gameId].gameId, invitedId, registeredUsers[usersId[invitedId]].userId, refValue);

                    refValue = levels[gameId].amountToPay.mul(thirdLevelReferal).div(100); // third level referal
                    (success, ) = registeredUsers[usersId[registeredUsers[usersId[invitedId]].userId]].userAddress.call{value: refValue}("");

                    if (success) emit ReferalPaymentEvent(levels[gameId].gameId, registeredUsers[usersId[invitedId]].userId, registeredUsers[usersId[registeredUsers[usersId[invitedId]].userId]].userId, refValue);
                    /**
                      * @dev There contract owner get his 6% game award
                    */
                    refValue = levels[gameId].amountToPay.mul(ownerReferal).div(100); // owner referal
                    (success, ) = registeredUsers[contractOwner].userAddress.call{value: refValue}("");

                    if (success) emit ReferalPaymentEvent(levels[gameId].gameId, userId, registeredUsers[contractOwner].userId, refValue);
                }
                userIndex = culcNextWinnerIndex(userIndex);
            }
        }
    }
}
