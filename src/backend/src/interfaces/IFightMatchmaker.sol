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

    event FightMatchmaker__FightRequested(
        address indexed challenger, uint256 indexed nftId, uint256 indexed bet, uint256 timestamp, bytes32 fightId
    );
    event FightMatchmaker__FightRequestedTo(
        address indexed challenger, address indexed challenged, uint256 nftIdChallenger, uint256 nftIdChallenged
    );
    event FightMatchmaker__FightAccepted(address indexed challenger, uint256 indexed bet, uint256 nftId);

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
     */
    function requestFight(uint256 nftId) external;

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
     * @param fightId Id of the fight to set its state to AVAILABLE
     */
    function declareFightFinished(bytes32 fightId) external;

    //********************************* */
    // Challenge Addresses Matchmaking
    //********************************* */

    /**
     * @dev Requests a fight to someone. It creates a different fightId that includes
     * both participants
     *
     * @notice msg.value is the bet on the fight if desired.
     *
     * @param challenged The address you wanna fight.
     * @param opponentsNftId The id of your opponents nft.
     * @param nftId Id of the NFT you will be using.
     */
    function requestFightTo(address challenged, uint256 opponentsNftId, uint256 nftId) external;

    /**
     * @dev First resolves the names using the `EnsOperator` and then calls requestFightTo()
     *
     * @param username ENS username of the address you wanna fight.
     * @param nftName Name of the opponents NFT you wanna fight.
     * @param nftId Your NFT ID you are gonna use in the battle.
     */
    function requestFightTo(string calldata username, string calldata nftName, uint256 nftId) external;

    /**
     * @dev Accepts and starts a fight that has ben personally requested.
     *
     * @notice msg.value is the bet you are putting in the fight. It must be greater than the
     * minimum bet your challenger set.
     *
     * @param challenger The address challenging you.
     * @param nftId Nft Id of the challenger.
     */
    function acceptFightFrom(address challenger, uint256 nftId) external;

    /**
     * @dev Resolves ENS addresses trhough `EnsOperator` adn then calls acceptFightFrom().
     *
     * @notice msg.value is the bet you are putting in the fight. It must be greater than the
     * minimum bet your challenger set.
     *
     * @param username The ENS username of the address challenging you.
     * @param nftName name of the challenger nft
     */
    function acceptFightFrom(string calldata username, string calldata nftName) external;

    // Getters
    function getFightState(bytes32 fightId) external returns (FightState);

    // Setters
    function setFightState(bytes32 fightId, FightState newState) external;
}
