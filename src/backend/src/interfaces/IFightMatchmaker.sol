// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IFightMatchmaker
 * @author PromptFighters team: Carlos
 * @dev Interface for the FightMatchmaker contract.
 */
interface IFightMatchmaker {
    //************************ */
    // Events
    //************************ */

    /**
     * @dev Event emitted just when challenging any address.
     */
    event FightMatchmaker__FightRequested(
        bytes32 indexed fightId, uint256 indexed nftId, uint256 indexed bet, address challenger, uint256 timestamp
    );
    /**
     * @dev Event emitted when challenging only specific address or nfts.
     */
    event FightMatchmaker__FightRequestedTo(
        address indexed challenger,
        address indexed challengee,
        uint256 nftIdChallenger,
        uint256 indexed nftIdChallengee,
        uint256 timestamp
    );

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

    /**
     * @dev Event emitted when and NFT starts the automated mode.
     */
    event FightMatchmaker__NftAutoamteStart(uint256 indexed nftId, uint256 startTimestamp);

    /**
     * @dev Event emitted when and NFT exits the automated mode.
     */
    event FightMatchmaker__NftAutomateStop(
        uint256 indexed nftId, uint256 indexed startTimestamp, uint256 indexed endTimestamp, uint256 earnings
    );

    //************************ */
    // Data Structures
    //************************ */

    /**
     * @param nftIdUsing The nft msg.sender will use
     * @param minBet The minimum ammount of Ether msg.sender is willing to accept
     * as the challengee's bet.
     * @param acceptanceDeadline In case the request is not accepted by anyone. This
     * parameter marks the amount of time to wait before msg.sender can
     * delete the fight request and recover its locked bet from `BetsVault`.
     * @param challengee The address you want to challenge, If == address(0) anyone can
     * accept your request. If not, only `challengee` address can accept it.
     * @param challengeeNftId The NFT id of the fighter you want to challenge, if 0 any NFT
     * is valid if != 0 then only that NFT's owner can accept the fight.
     * @notice NFT id 0 in PromptFighter's NFT contract is not possible to mint thus is treated
     * as the null NFT ID value.
     */
    struct FightRequest {
        uint256 nftIdUsing;
        uint256 minBet;
        uint256 acceptanceDeadline;
        address challengee;
        uint256 challengeeNftId;
    }

    /**
     * @dev AVAILBALE => Fight can be started
     *
     * @dev REQUESTED => A fight is waiting for someone else, player who requested it can't start more fights
     *
     * @dev ONGOING => A fight is being processed.
     */
    enum FightState {
        AVAILABLE,
        REQUESTED,
        ONGOING
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
        uint256 startedAt;
        FightState state;
    }

    //************************ */
    // Functions
    //************************ */

    //************************ */
    // Matchmaking
    //************************ */

    /**
     * @dev Emits an FightMatchmaker__FightRequested event.
     * Sets the fightState of the corresponding fightId to REQUESTED.
     * Locks bet with deadline to the BetsVault.
     * Creates new Fight struct on storage.
     * Set nftId to can't move from chain to chain in NFT collection or barracks.
     *
     * @notice Bet == msg.value. For simplicity this protocol only operates with
     * the native coin Ether.
     *
     * @notice msg.sender must be the owner of `nftId`'s NFT.
     * @notice the NFT has to be on the chain at the moment.
     * @notice if challengee != address(0) then challengee must own challengeeNftId
     * @notice if challengeeNftId != 0 && challengee == address(0) then the only
     * one who can accept that fight is ownerOf(challengeeNftId) but,
     * ownerOf(challengeeNftId) != address(0)
     *
     * @notice If requested a fight that anyone can accept, add it to the automated fights
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
     * @notice fightId must be in REQUESTED at the beginning of this function execution.
     *
     * @param fightId The fightId you want to accept. Retrieved from logs.
     * @param nftId The NFT you want to use. The NFT must be yours.
     *
     * TODO: maybe this function will have an extra parameter: bytes memory gistSecretsUrl
     * Only thing would need to change is that startFight() function of FightExecutor will
     * have to be passed this argument too.
     */
    function acceptFight(bytes32 fightId, uint256 nftId) external;

    /**
     * @dev Function callable by requestFight(), or the `FightExecutor` contract
     * to set the state of a finished fight to AVAILABLE, or by `BetsVault` to set
     * fights as AVAILABLE when user unlocks bet if no-one accepted a  request.
     *
     * @notice If called from `FightExecutor` then this must hold FightState == ONGOING
     * If called from `BetsVault` then this must hold FightState == REQUESTED or ONGOING
     * (ONGOING is an edge case where Chainlink Services stop operating so we need a way to
     * withdraw the money on ongoing fights)
     * If called from requestFight() then this must hold FightState == AVAILABLE
     *
     * @notice If called from `FightExecutor` then mark fight participants as "not fighting"
     * by setting the fightId assosiated with their addresses to bytes32(0). Also call BetsVault
     * and distribute the bets.
     *
     * @notice If called from Bets or Executor argument newState == AVAILABLE
     * otherwise revert.
     *
     * If final state is AVAILABLE sets nfts to can move in NFT collection or barracks.
     *
     * If any of the NFT was in automation mode, check if its funds allow him to keep being automated,
     * if not then take it out from the automated NFTs list.
     *
     * @param fightId Id of the fight to set its state to newState.
     * @param winner it is etiher 0 or 1, if any other value then ignore. 0 indicates requester won, 1 indicates acceptor won.
     * This param is only used when calling from FightExecutor and state changes from ONGOING to
     * AVAILABLE but the edge-case Chainlink services stop working is not given.
     */
    function setFightState(bytes32 fightId, FightState newState, uint256 winner) external;

    //********************************* */
    // Automated Matchmaking
    //********************************* */

    /**
     * @return bool saying if the nft is in automation mode.
     */
    function getIsNftAutomated(uint256 nftId) external returns (bool);

    /**
     * @return bool saying if the nft is in automation mode.
     */
    function setNftAutomated(uint256 nftId, bool isAutomated) external returns (bool);

    //************* */
    // Getters
    //************* */

    function getFigthId(address challenger, uint256 challengerNftId, address challengee, uint256 challengeeNftId)
        external
        returns (bytes32);

    function getUserCurrentFightId(address user) external returns (bytes32);

    function getFightDetails(bytes32 fightId) external returns (Fight memory);
}
