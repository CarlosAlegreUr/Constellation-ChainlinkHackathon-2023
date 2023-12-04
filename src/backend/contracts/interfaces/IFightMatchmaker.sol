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

    event FightMatchmaker__AutomatonRegistered(uint256 indexed upkeepId);

    event FightMatchmaker__FightRequested(
        address challenger, uint256 indexed nftId, bytes32 indexed fightId, uint256 indexed bet, uint256 timestamp
    );

    event FightMatchmaker__FightRequestedTo(
        address indexed challenger,
        address indexed challengee,
        uint256 nftIdChallenger,
        uint256 indexed nftIdChallengee,
        uint256 bet,
        uint256 timestamp
    );

    event FightMatchmaker__FightAccepted(
        address indexed challenger,
        address indexed challengee,
        uint256 nftIdChallenger,
        uint256 nftIdChallengee,
        uint256 betChallenger,
        uint256 betChallengee,
        uint256 indexed timestamp
    );

    event FightMatchmaker__FightAcceptedByUpkeep(
        address indexed challenger,
        uint256 indexed nftIdChallenger,
        uint256 nftIdChallengee,
        uint256 betChallenger,
        uint256 betChallengee,
        uint256 indexed timestamp
    );

    event FightMatchmaker__NftAutomateStart(uint256 indexed nftId, uint256 startTimestamp);

    event FightMatchmaker__NftAutomateStop(
        uint256 indexed nftId, uint256 indexed startTimestamp, uint256 indexed endTimestamp, uint256 earnings
    );

    event FightMatchmaker__FightStateChange(
        bytes32 indexed fightId, FightState indexed oldState, FightState indexed newState, address calledFrom
    );

    event FightMatchmaker__UserToFightIdSet(address indexed user, bytes32 indexed fightId);

    event FightMatchmaker__FightIdToFightSet(bytes32 indexed fightId, Fight indexed fight);

    event FightMatchmaker__UserNoLongerFighting(address indexed user);

    //************************ */
    // Data Structures
    //************************ */

    /**
     * @param nftIdUsing The nft msg.sender will use
     * @param minBet The minimum ammount of native coin msg.sender is willing to accept
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
        uint256 challengerNftId;
        uint256 minBet;
        uint256 acceptanceDeadline;
        address challengee;
        uint256 challengeeNftId;
    }

    /**
     * @dev Available => Fight can be started
     *
     * @dev Requested => A fight is waiting for someone else, player who requested it can't start more fights
     *
     * @dev Ongoing => A fight is being processed.
     */
    enum FightState {
        AVAILABLE,
        REQUESTED,
        ONGOING
    }

    /**
     * @dev Struct used for preserving fight data
     * required for execution but not emitted in logs.
     */
    struct Fight {
        uint256 nftRequester;
        uint256 nftAcceptor;
        uint256 minBet;
        uint256 acceptanceDeadline;
        uint256 startedAt;
        FightState state;
    }

    enum WinningAction {
        REQUESTER_WIN,
        ACCEPTOR_WIN
    }

    //************************ */
    // Functions
    //************************ */

    //************************ */
    // Matchmaking
    //************************ */

    /**
     * @dev Sets the fightState of the corresponding fightId to REQUESTED.
     * Locks bet with deadline to the BetsVault.
     * Creates new Fight struct on storage.
     * Sets nftId to isFighting on collection or barracks contracts.
     *
     * @notice Bet == msg.value. For simplicity this protocol only operates with
     * the native coin Ether.
     *
     * @notice msg.sender must be the owner of `nftId`'s NFT.
     * @notice the NFT has to be on the chain at the moment.
     * @notice If requested a fight that anyone can accept, add it to the automated fights
     * system so automated nfts can accept it.
     */
    function requestFight(FightRequest calldata fightRequest) external payable;

    /**
     * @dev This function gathers all the information necessary to call the
     * startFight() function at `FightExecutor` contract.
     *
     * If successful sets fight state to ONGOING.
     * Otherwise it reverts.
     *
     * Both participants are marked as fighting.
     *
     * @notice fightId must be in REQUESTED at the beginning of this function execution.
     * @param fightId The fightId you want to accept. Retrieved from logs.
     * @param nftId The NFT you want to use. The NFT must be yours.
     */
    function acceptFight(bytes32 fightId, uint256 nftId) external payable;

    /**
     * @dev Function callable by the `FightExecutor` contract
     * to set the state of a finished fight to AVAILABLE.
     *
     * Mark fight participants as "not fighting".     *
     * by setting the fightId assosiated with their addresses to bytes32(0).
     * Set nfts to not fighting in NFT collection or barracks.
     * Also call BetsVault and distribute the bets.
     *
     * If any of the NFT was in automation mode, check if its funds allow him to keep being automated,
     * if not then take it out from the automated NFTs list.
     *
     * @notice Every time called this must hold FightState == ONGOING
     */
    function settleFight(bytes32 fightId, WinningAction winner) external;

    //********************************* */
    // Automated Matchmaking
    //********************************* */

    /**
     * @dev Yout must approve linkFunds amount of LINK to the contract before calling this function.
     */
    function setNftAutomated(uint256 nftId, uint256 bet, uint256 minBet, uint256 linkFunds) external;

    //************* */
    // Getters
    //************* */

    function getFightId(address challenger, uint256 challengerNftId, address challengee, uint256 challengeeNftId)
        external
        returns (bytes32);

    function getUserCurrentFightId(address user) external returns (bytes32);

    function getFight(bytes32 fightId) external returns (Fight calldata);

    function getNftsFromFightId(bytes32 _fightId) external view returns (uint256, uint256);

    function getNftsPromptsFromFightId(bytes32 _fightId) external view returns (string memory, string memory);

    function getNftsOwnersFromFightId(bytes32 _fightId) external view returns (address, address);

    function getFightExecutorContract() external view returns (address);

    function getBetsVault() external view returns (address);

    function getPromptFightersNft() external view returns (address);

    function getLinkTokenInterface() external view returns (address);

    function getAutomationForwarder() external view returns (address);

    function getFightIdToFight(bytes32 fightId) external view returns (Fight memory);

    function getUserToFightId(address user) external view returns (bytes32);

    function getNftIdAutomated() external view returns (uint256);

    function getNftAutomationBalance() external view returns (uint256);

    function getApocalipsisSafetyNet() external pure returns (uint256);

    function getAutomationBalanceThreshold() external view returns (uint256);
}
