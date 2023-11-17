// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IFightMatchmaker
 * @author PromptFighters team: Carlos
 * @notice This interface assumes that a player can only have 1 fight at a time.
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

    event FightMatchmaker__FightStateChange(
        bytes32 indexed fightId, FightState indexed oldState, FightState indexed newState, address calledFrom
    );

    event FightMatchmaker__NftAutoamteStart(uint256 indexed nftId, uint256 startTimestamp);
    event FightMatchmaker__NftAutomateStop(
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

    /**
     * Struct used for preserving fight components
     * required for logic but not emitted in logs.
     */
    struct Fight {
        uint256 nftOne;
        uint256 nftTwo;
        uint256 minBet;
        uint256 acceptanceDeadline;
        FightState state;
    }

    /**
     * @param nftIdUsing The nft msg.sender will use
     * @param minBet The minimum ammount of Ether msg.sender is willing to accept
     * as the challengee's bet.
     * @param acceptanceDeadline In case the request is not accepted by anyone. This
     * parameter marks the amount of time to wait before msg.sender can
     * delete the fight request and recover its bet.
     * @param challengee The address you want to challenge, If == address(0) anyone can
     * accept your request. If not, only `challengee` address can accept it.
     * @param challengeeNftId The NFT id of the fighter you want to challenge, if 0 any NFT
     * is valid if != 0 then only that NFT's owner can accept the fight.
     * @notice NFT id 0 in PromptFighter NFT contract is not possible to mint thus is the empty
     * NFT ID value.
     */
    struct FightRequest {
        uint256 nftIdUsing;
        uint256 minBet;
        uint256 acceptanceDeadline;
        address challengee;
        uint256 challengeeNftId;
    }

    //************************ */
    // Functions
    //************************ */

    //************************ */
    // Matchmaking
    //************************ */

    /**
     * @dev Calculates the fightId = keccack(fightRequest),
     * plus emits an FightMatchmaker__FightRequested event.
     *
     * Sets the fightState of the ID to REQUESTED.
     * Locks bet with deadline to the BetsVault.
     * Creates new Fight struct on storage.
     * Set nftId to can't move in NFT collection or barracks.
     *
     * @notice Bet == msg.value. For simplicity this protocol only operates with
     * the native coin Ether.
     *
     * @notice msg.sender must be the owner of `nftId`'s NFT.
     * @notice the NFT has to be on the chain at the moment.
     * @notice if challengee != address(0) then challengee must own challengeeNftId
     * @notice if challengeeNftId != 0  && challengee == address(0) then the only
     * one who can accept that fight is ownerOf(challengeeNftId) but,
     * ownerOf(challengeeNftId) != address(0)
     *
     * @notice If its a fight anyone can accept add it to the automated fights
     * system so automated nfts can accept it.
     *
     * @notice Proper events must be emitted depending on the case.
     *
     * @param fightRequest The fight request struct
     */
    function requestFight(FightRequest calldata fightRequest) external;

    /**
     * @dev This function gathers all the information necessary to call the
     * startFight() function at `FightExecutor` contract.
     *
     * If successful sets fight state to ONGOING.
     * Otherwise it reverts.
     *
     * Both participants are marked as fighting so they can't create more fights
     * until this one finishes.
     *
     * @notice fightId must be in REQUESTED state.
     *
     * @param fightId The fightId you want to accept. Retrieved from logs.
     * @param nftId The NFT you want to use.
     */
    function acceptFight(bytes32 fightId, uint256 nftId) external;

    /**
     * @dev Function callable by requestFight(), or the `FightExecutor` contract
     * to set the state of a finished fight to AVAILABLE, or by `BetsVault` to set
     * fights as AVAILABLE when user unlocks bet if request no-one accepted.
     *
     * @notice If called from `FightExecutor` then this must hold FightState == ONGOING
     * If called from `BetsVault` then this must hold FightState == REQUESTED or ONGOING
     * (ONGOING is an edge case where Chainlink Services stop operating so we need a way to
     * withdraw the money of ongoing fights)
     * If called from requestFight() then this must hold FightState == AVAILABLE
     *
     * @notice If called from `FightExecutor` then mark fight participants as not in fight
     * by setting the fightId assosiated with their addresses to bytes32(0). Also call BetsVault
     * and distribute the bets.
     *
     * @notice If called from Bets or Executor contracts then newState == AVAILABLE
     * otherwise revert.
     *
     * If final state is AVAILABLE sets nfts to can move in NFT collection or barracks.
     *
     * @param fightId Id of the fight to set its state to AVAILABLE
     */
    function setFightState(bytes32 fightId, FightState newState) external;

    //********************************* */
    // Automated Matchmaking
    //********************************* */

    function getIsNftAutomated(uint256 nftId) external returns (bool);

    function setNftAutomated(uint256 nftId, bool isAutomated) external returns (bool);

    //************* */
    // Getters
    //************* */

    function getFigthId(address challenger, uint256 challengerNftId, address challengee, uint256 challengeeNftId)
        external
        returns (bytes32);

    function getUserCurrentFightId(address user) external returns (bytes32);

    function getFightDetails(bytes32 fightId) external returns (Fight calldata);
}
