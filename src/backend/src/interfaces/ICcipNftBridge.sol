// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICcipNftBridge
 * @author PromtFighters team: Carlos
 * @dev Interface for all the contracts that move fighter NFTs around.
 */
interface ICcipNftBridge {
    // Events
    event ICCIPNftBridge__NftSent(
        address indexed user, uint64 indexed chainSelector, string indexed nftId, uint256 timestamp
    );
    event ICCIPNftBridge__NftReceived(
        address indexed user, uint256 indexed chain, uint256 indexed nftID, uint256 timestamp
    );

    // Functions

    /**
     * @dev Sends an NFT to the Fuji or Sepolia testnet so as to be able to fight on there.abi
     * Sepolia -> safest chain though more expensive
     * Fuji -> cheaper prices.
     *
     * You can only fight with your NFT on the chain it currently is.
     * For simplicity to use CCIP you have to pay with the native coin -> msg.value
     *
     * @param destinationChainSelector The identifier (aka selector) for the destination blockchain.
     * @param receiver The address of the recipient on the destination blockchain.
     * FighterBarracks.sol in this project or the NFT collection when moving to Sepolia.
     * @param nftId The text to be sent. In this case it must be the string version of your NFT ID.
     * @return messageId The ID of the CCIP message that was sent. Maybe there is no need for this.
     */
    function sendNft(uint64 destinationChainSelector, address receiver, string calldata nftId)
        external
        payable
        returns (bytes32 messageId);

    // Getters

    function isNftOnChain(uint256 nftId) external view returns (bool);

    /**
     * @dev Needed to have a generalized way trhough chains of checking for ownership.
     *
     * As in the main-chain ETH the classic ownerOf() exists but in other chains
     * where the collection is not deployed but just exists a track of ownershp via
     * ccip-transfer from main-chain.
     *
     * Therefore ownerOf() doesn't exist as those contracts are not ERC721 but just
     * ownership mappings assigned at transfered time. So we need a function to generalize
     * the way we access the ownership state and comfortable use the same Matchmaker contracts
     * in each chain.
     *
     * TODO: revise Matchmaker an associeted contracts to use getOwnerOf()
     */
    function getOwnerOf(uint256 _nftId) external view returns (address);
}
