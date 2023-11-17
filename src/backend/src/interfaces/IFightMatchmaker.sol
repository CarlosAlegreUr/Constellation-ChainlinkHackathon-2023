// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IFightMatchmaker
 * @author PromptFighters team: Carlos
 * @notice This interface assumes that a player can only be having 1 fight at a time.
 */
interface IFightMatchmaker {
    //************************ */
    // Events
    //************************ */

    /**
     * @dev Event emitted just when challenging addresses at random.
     */
    event FightMatchmaker__FightRequested(
        bytes32 indexed fightId, uint256 indexed nftId, uint256 indexed bet, address challenger, uint256 timestamp
    );
    /**
     * @dev Event emitted when challenging address trhuogh ENS.
     */
    event FightMatchmaker__FightRequestedTo(
        address indexed challenger, address indexed challengee, uint256 nftIdChallenger, uint256 nftIdChallengee
    );
    /**
     * @dev Event emitted when a challenge is accepted.
     */
    event FightMatchmaker__FightAccepted(
        address indexed challenger,
        address indexed challengee,
        uint256 indexed timestamp,
        uint256 nftIdChallenger,
        uint256 nftIdChallengee,
        uint256 betChallenguer,
        uint256 betChallenguee
    );

    event IFightAutomator__NftAutoamteStart(uint256 indexed nftId, uint256 startTimestamp);
    event IFightAutomator__NftAutomateStop(
        uint256 indexed nftId, uint256 earnings, uint256 startTimestamp, uint256 endTimestamp
    );

    //************************ */
    // Data Structures
    //************************ */

    /**
     * @dev Available => Fight can be started
     *
     * @dev Requested => A fight is waiting for someone else, can't start more fights
     *
     * @dev Ongoing => A fight is being processed by chainlink functions.
     */
    enum FightState {
        Available,
        Requested,
        Ongoing
    }

    //************************ */
    // Functions
    //************************ */

    //************************ */
    // General Matchmaking
    //************************ */

    /**
     * @dev Calculates the fightId = keccack(msg.sender, bet, nftId),
     * plus emits an FightMatchmaker__FightRequested event.
     *
     * Sets the fightState of the ID to REQUESTED.
     *
     * @notice The bet parameter == msg.value. For simplicity this protocl only operates with
     * the native coin Ether bridged accross chains though Chainlink CCIP.
     *
     * @notice msg.sender must be the owner of `nftId`'s NFT.
     *
     * @param nftId The ID of the nft that will particiapte in the fight.
     * @param acceptanceDeadline is the time where the bet you put, if no-one accepted your challenge, can be withdrawed from
     * the `BetsVault`.
     */
    function requestFight(uint256 nftId, uint256 minimumBet, uint256 acceptanceDeadline) external;

    /**
     * @dev This function gathers all the information necessary to call the
     * startFight() function at `FightExecutor` contract.
     *
     * If successful sets fight state to ONGOING.
     * Otherwise it reverts.
     *
     * @notice fightId must have REQUESTED state.
     * @notice Both participants must be registered as busy fighting.
     *
     * @param fightId The ID of the fight you want to accept.
     */
    function acceptFight(bytes32 fightId) external;

    /**
     * @dev Function only callable by the `FightExecutor` to set the state
     * of a finished fight to AVAILABLE.
     *
     * And also only callable from BetsVault to set fights as AVAILABLE when
     * user unlocks bet if request is not accepted.
     *
     * @param fightId Id of the fight to set its state to AVAILABLE
     */
    function changeFightState(bytes32 fightId, FightState newState) external;

    //********************************* */
    // Challenge Addresses Matchmaking
    //********************************* */

    /**
     * @dev Requests a fight to someone. It creates a different fightId that includes
     * both participants
     *
     * @notice msg.value is the bet on the fight if desired.
     *
     * @param challengee The address you wanna fight.
     * @param opponentsNftId The id of your opponents nft.
     * @param nftId Id of the NFT you will be using.
     * @param minimumBet is the least amount of bet the challenger is willing to play against.
     */
    function requestFightTo(
        address challengee,
        uint256 opponentsNftId,
        uint256 nftId,
        uint256 minimumBet,
        uint256 acceptanceDeadline
    ) external;

    /**
     * @dev Accepts and starts a fight that has ben personally requested.
     *
     * @notice msg.value is the bet you are putting in the fight. It must be greater than the
     * minimum bet your challenger set.
     *
     * @param challenger The address challenging you.
     * @param nftId Nft Id of the challenger.
     */
    function acceptChallengeFrom(address challenger, uint256 nftId) external;

    //********************************* */
    // Automated Matchmaking
    //********************************* */

    function getNftIsAutomated(uint256 nftId) external returns (bool);

    function setNftToAutomatedMode(uint256 nftId, bool isAutomated) external returns (bool);

    //************* */
    // Getters
    //************* */

    function getUserCurrentFightId(address user) external returns (bytes32);

    function getFightState(bytes32 fightId) external returns (FightState);

    function getChallengeId(
        address challenger,
        address challengee,
        uint256 nftIdChallenger,
        uint256 nftIdChallengee,
        uint256 betChallenger,
        uint256 betChallengee
    ) external returns (bytes32);
}
