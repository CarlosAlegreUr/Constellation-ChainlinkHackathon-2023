const FIGTH_EXECUITION_ABI = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "challenger",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "challengee",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "nftIdChallenger",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "nftIdChallengee",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "betChallenguer",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "betChallenguee",
        type: "uint256",
      },
    ],
    name: "FightMatchmaker__FightAccepted",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint256",
        name: "id",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "string",
        name: "prompt",
        type: "string",
      },
    ],
    name: "NewFighter",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "nftId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "bytes",
        name: "funcsResponse",
        type: "bytes",
      },
      {
        indexed: false,
        internalType: "bytes",
        name: "funcsError",
        type: "bytes",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
    ],
    name: "PromptFighters__NftMinted",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "idx1",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "idx2",
        type: "uint256",
      },
    ],
    name: "figth",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "prompt",
        type: "string",
      },
    ],
    name: "mintFigther",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "string",
        name: "prompt",
        type: "string",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "index",
        type: "uint256",
      },
    ],
    name: "getPrompt",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];
const FIGTH_EXECUTOR_ADDRESS = "0x265B6dB2db073a64ca5Bb0b336e0A61162a25091";
const THE_GRAPH_URL = '';

module.exports = {
  THE_GRAPH_URL,
  FIGTH_EXECUITION_ABI,
  FIGTH_EXECUTOR_ADDRESS,
};
