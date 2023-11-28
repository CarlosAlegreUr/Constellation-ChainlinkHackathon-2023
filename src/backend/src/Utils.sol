// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev A file with general data different contracts use,
 */

/**
 * @param source JavaScript source code
 * @param encryptedSecretsUrls Encrypted URLs where to fetch user secrets
 * @param donHostedSecretsSlotID Don hosted secrets slotId
 * @param donHostedSecretsVersion Don hosted secrets version
 * @param args List of arguments accessible from within the source code
 * @param bytesArgs Array of bytes arguments, represented as hex strings
 * @param subscriptionId Billing ID
 */
struct ChainlinkFuncsGist {
    string source;
    bytes encryptedSecretsUrls;
    uint8 donHostedSecretsSlotID; // NOT USING
    uint64 donHostedSecretsVersion; // NOT USING
    string[] args; // TODO: USING IN SIMPLE VERSION WITH PROMPTS STORED ON-CHAIN
    bytes[] bytesArgs; // NOT USING
    uint64 subscriptionId;
    uint32 gasLimit;
    bytes32 donID;
}

//******************** */
// SCRIPTS USED VALUES
//******************** */

//******************** */
// WHEN LOCAL SET-UP CHANGE THIS VALUES!!!
//******************** */

address constant DEPLOYER = 0x9B89eDB87D1219f21d4E33ad655da9CC542dF53c;
address constant DEPLOYED_SEPOLIA_COLLECTION = 0x626431cf60DA2319082831367d261b876D1De70f;
address constant DEPLOYED_FUJI_BARRACKS = 0xd4d3cF5De4C967D3fe6ac6cd8A3593b7e10c8fFD;

///////////////////////////////////////////////

string constant NFT_VALID_PROMPT = "Just answer VALID";
string constant NFT_INVALID_PROMPT = "Just answer INVALID";

//******************** */
// CHAIN IDS
//******************** */

uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
uint256 constant AVL_FUJI_CHAIN_ID = 43113;

//******************** */
// Chainlink Contracts
//******************** */

//******************** */
// LINK Token
//******************** */

address constant ETH_SEPOLIA_LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
address constant AVL_FUJI_LINK = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;

//******************** */
// Chainlink Functions
//******************** */

uint256 constant MINT_NFT_LINK_FEE = 2 ether;
uint64 constant ETH_SEPOLIA_FUNCS_SUBS_ID = 1739;
uint64 constant AVL_FUJI_FUNCS_SUBS_ID = 1378;

address constant ETH_SEPOLIA_FUNCTIONS_ROUTER = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
address constant AVL_FUJI_FUNCTIONS_ROUTER = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;

// fun-ethereum-sepolia-1 - in functions NPM package
bytes32 constant ETH_SEPOLIA_DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
// fun-avalanche-fuji-1 - in functions NPM package
bytes32 constant AVL_FUJI_DON_ID = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000;

// Propper gas limits should be tested and set, 35.000 is just a random first try.
uint32 constant GAS_LIMIT_FIGHT_GENERATION = 35_000;
uint32 constant GAS_LIMIT_NFT_GENERATION = 35_000;

// source.js - Files executed by CLFunctions at the end of this file.

//******************** */
// Chainlink VRF
//******************** */

address constant ETH_SEPOLIA_VRF_COORDINATOR = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
address constant AVL_FUJI_VRF_COORDINATOR = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;

// 150 gwei
bytes32 constant ETH_SEPOLIA_KEY_HASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
// 300 gwei
bytes32 constant AVL_FUJI_KEY_HASH = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;

uint16 constant ETH_SEPOLIA_REQ_CONFIRIMATIONS = 3;
uint16 constant AVL_FUJI_REQ_CONFIRIMATIONS = 3;

// Depends on execution cost of fullfillRandomWords().
// Estimate is 20.000 gas per word, we distribute bets "within" this function
// so lets keep it up. Proper testing of gas consumption should be made in order
// to assert a fitter value.
uint32 constant ETH_SEPOLIA_CALLBACK_GAS_LIMIT = 55_000;
uint32 constant AVL_FUJI_CALLBACK_GAS_LIMIT = 55_000;

//******************** */
// Chainlink CCIP
//******************** */

address constant ETH_SEPOLIA_CCIP_ROUTER = 0xD0daae2231E9CB96b94C8512223533293C3693Bf;
address constant AVL_FUJI_CCIP_ROUTER = 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8;

uint64 constant ETH_SEPOLIA_SELECTOR = 16015286601757825753;
uint64 constant AVL_FUJI_SELECTOR = 14767482510784806043;

//******************** */
// SHARED CONSTANTS
//******************** */

// @dev A value used in setFightState() calls to signal the function doesn't have to use
// the winner parameter.
uint256 constant NOT_DECIDING_WINNER_VALUE = 2;

//**************************** */
// CHAINLINK FUNCTIONS SCRIPTS
//**************************** */

// TODO: add final files
bytes32 constant GENERATE_FIGHT_SCRIPT_HASH = keccak256(abi.encode(FIGHT_GENERATION_SCRIPT));
bytes32 constant GENERATE_NFT_SCRIPT_HASH = keccak256(abi.encode(NFT_GENERATION_SCRIPT));

string constant NFT_GENERATION_SCRIPT = "console.log(\"date is: \", Date.now());\n\n"
    "const gptPrompt = `Take a deep breath and do 1 thing:\n\n" "1.- Deem the description VALID or INVALID\n\n"
    "------\n\n" "DETAILS ON HOW TO DO THE IMAGE:\n\n"
    "Be super artistic and create a REALISTIC image of a character that:\n\n" "- Name: A_NAME\n"
    "- Race: WRITE_ANYTHING_YOU_CAN_IMAGINE\n" "- Weapon: WRITE_ANYTHING_YOU_CAN_IMAGINE\n"
    "- Special skill: WRITE_ANYTHING_YOU_CAN_IMAGINE\n" "- Fear: WRITE_ANYTHING_YOU_CAN_IMAGINE\n\n"
    "You will always return the word VALID or INVALID, not other words, this is meant to be used for a script, and the script cannot support other text, only the words INVALID or INVALID, don't explain why you chose a certain option, just say if the character is valid or not with the following FILTERS:\n\n"
    "\n"
    "- If the character is too powerful return INVALID. Too powerful means that the character has in the description\n"
    "things like infinite power or, it always defeats enemies etc Things that can't make the prompt fight interesting to \n"
    "read.\n\n"
    "- We dont mind characters being gods or stuff very powerful like blackholes as fights can get as crazy as they must be \n"
    "so there is a winner. We just wanna filter texts saying things like my character always wins.\n\n"
    "- If the description of the character goes agains OpenAI DALL-3 image generation and the image generation fails then \n"
    "als return INVALID.\n\n"
    "- If the character is too crazy for being relaistic dont worry and deem the prompt VALID.\n\n" "\n"
    "This is the prompt deam it VALID or INVALID:\n\n" "- Name: ${args[0]}\n" "- Race: ${args[1]}\n"
    "- Weapon: ${args[2]}\n" "- Special skill: ${args[3]}\n" "- Fear: ${args[4]}\n\n" "`;\n\n"
    "function delay(milliseconds) {\n" "  return new Promise((resolve) => {\n" "    setTimeout(() => {\n"
    "      resolve();\n" "    }, milliseconds);\n" "  });\n" "}\n\n" "const postData = {\n"
    "  model: \"gpt-3.5-turbo\",\n" "  messages: [{ role: \"user\", content: gptPrompt }],\n" "  temperature: 0,\n"
    "};\n\n" "const openAIResponse = await Functions.makeHttpRequest({\n"
    "  url: \"https://api.openai.com/v1/chat/completions\",\n" "  method: \"POST\",\n" "  headers: {\n"
    "    Authorization: `Bearer ${secrets.apiKey}`,\n" "    \"Content-Type\": \"application/json\",\n" "  },\n"
    "  data: postData,\n" "});\n\n" "if (openAIResponse.error) {\n"
    "  throw new Error(JSON.stringify(openAIResponse));\n" "}\n\n"
    "const result = openAIResponse.data.choices[0].message.content;\n\n" "if (result != \"VALID\") {\n"
    "  return Functions.encodeString(\"\");\n" "} else {\n"
    "  const str = `${args[0]}-${args[1]}-${args[2]}-${args[3]}-${args[4]}`;\n\n"
    "  return Functions.encodeString(str);\n" "};";

string constant FIGHT_GENERATION_SCRIPT = "const gptPrompt = `\n" "Here are 2 characters:\n\n" "- CHARACTER 1:\n"
    "    - Name: ${args[0]}\n" "    - Race: ${args[1]}\n" "    - Weapon: ${args[2]}\n"
    "    - Special skill: ${args[3]}\n" "    - Fear: ${args[4]}\n\n" "- CHARACTER 2:\n" "    - Name: ${args[5]}\n"
    "    - Race: ${args[6]}\n" "    - Weapon: ${args[7]}\n" "    - Special skill: ${args[8]}\n"
    "    - Fear: ${args[9]}\n\n" "Take a deep breath and write 2 super interesting stories.\n"
    "These 2 stories describe a duel involving this 2 characters.\n"
    "In 1 of the fights CHARACTER 1 wins and in the other CHARACTER 2 wins.\n"
    "The stories musts be at most 6 lines of length. \n\n" "\n"
    "Between the stories as a way to sparate them you will put this string: \"---\",\n"
    "Your response will be use for a script and this is the only way that can be used by the script to separate the two stories.\n"
    "`;\n\n" "const postData = {\n" "  model: \"gpt-3.5-turbo\",\n"
    "  messages: [{ role: \"user\", content: gptPrompt }],\n" "  temperature: 0,\n" "};\n\n"
    "const openAIResponse = await Functions.makeHttpRequest({\n"
    "  url: \"https://api.openai.com/v1/chat/completions\",\n" "  method: \"POST\",\n" "  headers: {\n"
    "    Authorization: `Bearer ${secrets.apiKey}`,\n" "    \"Content-Type\": \"application/json\",\n" "  },\n"
    "  data: postData,\n" "});\n\n" "if (openAIResponse.error) {\n"
    "  throw new Error(JSON.stringify(openAIResponse));\n" "}\n\n"
    "const result = openAIResponse.data.choices[0].message.content;\n\n" "// return the two stories\n\n"
    "console.log(result);\n" "return Functions.encodeString(result);";
