// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev A file with general data different contracts use.
 */

//******************** */
// SCRIPTS USED VALUES
//******************** */

//******************** */
// 🟢🟠 WHEN LOCAL SET-UP CHANGE ALONG THE VALUES WITH GREEN DOTS 🟠🟢
//******************** *

address constant DEPLOYER = 0x9B89eDB87D1219f21d4E33ad655da9CC542dF53c; // 🟢
address constant PLAYER_FOR_FIGHTS = 0x108d618c5baFFb6AE2b84094da4C8314BAD16D71; // 🟢
address constant BACKEND_DON_MOCK = 0x9B89eDB87D1219f21d4E33ad655da9CC542dF53c; // 🟢

address constant DEPLOYED_SEPOLIA_COLLECTION = 0x1074065732cc2CC945818483B2543105ed2BF8F3; // 🟢
// 0x8b20ADA3498ba4040DC4b353d7A1675699C18C05
address constant DEPLOYED_FUJI_BARRACKS = 0x300eEB65665EA82fb4d8E4c269F7Bea2F7701bC8; // 🟠

address constant SEPOLIA_FIGHT_MATCHMAKER = 0x9584C884454B7538C366592E0Ff1bDE1f88761f1; // 🟢
// 0xE6835F9799BBb4c7c891cc25b0A9210660E6c9af
address constant SEPOLIA_FIGHT_EXECUTOR = 0x666dC2a85634ef761C9aDDb5B545a8C9F070e133; // 🟢
// 0xa5941b5aC7FaD9bFBce7df46274aB926e26B8499

address constant FUJI_FIGHT_MATCHMAKER = 0x4AD4B2C31E53362A34D18221253a114fAfE0716a; // 🟠
address constant FUJI_FIGHT_EXECUTOR = 0x935836279FEb095b1bba2cb9258f6386457f9aDB; // 🟠

uint64 constant ETH_SEPOLIA_FUNCS_SUBS_ID = 1739; // 🟢
uint64 constant AVL_FUJI_FUNCS_SUBS_ID = 1378; // 🟠

// For a promt to be valid in the POC it must be short and start with lower-case "a"
// There must be 5 fields separated by "-"
string constant NFT_VALID_PROMPT = "aMrDog-Cat-super power-titties I mean kitties"; // 🟢
// "aMrDog-Cat-super power-titties I mean kitties"
// "aMrPenguin-Penguin-He is depresed-Fish"
// "anuelAA-An AA batery-DVD-Flow to spin up a party-poetry"
// "anaio-A pig-Flies-He distinguished-Falcons"
// "anastasio-A cool falcon-Flies-He is distinguished-Pigeons";

import {IFightMatchmaker} from "./interfaces/IFightMatchmaker.sol";

contract FightToExecuteInScripts {
    address public constant REQUESTER = DEPLOYER; // 🟢
    address public constant ACCEPTOR = PLAYER_FOR_FIGHTS; // 🟢
    uint256 public constant REQUESTER_NFT_ID = 1; // 🟢
    uint256 public constant ACCEPTOR_NFT_ID = 2; // 🟢

    // 🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑
    //
    // 🛑      HEY USER YOU DON'T REALLY NEED TO CHANGE VALUES DEEPER IN THE FILE       🛑
    //
    // 🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑

    IFightMatchmaker.FightRequest public s_fiqutRequest = IFightMatchmaker.FightRequest({
        challengerNftId: REQUESTER_NFT_ID,
        minBet: 0.001 ether,
        acceptanceDeadline: block.timestamp + 1 hours,
        challengee: ACCEPTOR,
        challengeeNftId: ACCEPTOR_NFT_ID
    });
    bytes32 public s_fighReqFightID = keccak256(
        abi.encode(REQUESTER, s_fiqutRequest.challengerNftId, s_fiqutRequest.challengee, s_fiqutRequest.challengeeNftId)
    );

    function getFReq() public view returns (IFightMatchmaker.FightRequest memory) {
        return s_fiqutRequest;
    }
}

string constant NFT_INVALID_PROMPT = "Just answer INVALID";

uint256 constant MIN_ETH_BET = 0.001 ether;

///////////////////////////////////////////////
///////////////////////////////////////////////

//******************** */
// OFFICIAL CONTRACTS
//******************** */

// POLY

address constant POLY_COLLECTION = 0x7755624f45e09967B1379Fd5c57C36779FD10e71;
address constant POLY_MATCHMAKER = 0xE1685DC978cbe491c138Ad365942AA423890fE3C;
address constant POLY_EXECUTOR = 0xA7c50f78b17618d69b3c053f486D334750E67A54;
address constant DEPLOYED_MUMBAI_BARRACKS = address(0);
uint64 constant PLY_MUMBAI_SUBS_ID = 1027;

//******************** */
// CHAIN IDS
//******************** */

uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
uint256 constant AVL_FUJI_CHAIN_ID = 43113;
uint256 constant PLY_MUMBAI_CHAIN_ID = 80001;

//******************** */
// Chainlink Contracts
//******************** */

//******************** */
// LINK Token
//******************** */

address constant ETH_SEPOLIA_LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
address constant AVL_FUJI_LINK = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
address constant PLY_MUMBAI_LINK = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

//*********************************** */
// Chainlink Services Funding Amounts
//*********************************** */
uint256 constant MINT_NFT_LINK_FEE = 0.6 ether;

uint96 constant LINK_AMOUNT_FOR_EXECUTOR_SERVICES = 12 ether;

// NOTE: random values, feature of minimum threshold not even tested
uint96 constant LINK_AMOUNT_FOR_REGISTRATION = 7 ether;
uint256 constant LINK_SEPOLIA_AUTOMATION_THRESHOLD_BALANCE = 0.5 ether;
uint256 constant LINK_FUJI_AUTOMATION_THRESHOLD_BALANCE = 0.5 ether;
uint256 constant LINK_PLY_MUMBAI_THRESHOLD_BALANCE = 10.5 ether;

uint256 constant SEND_NFT_PRICE = 0.008 ether;
uint256 constant SEND_NFT_PRICE_FUJI = 0.17 ether;
uint256 constant SEND_NFT_PRICE_MUMBAI = 0.18 ether;

//******************** */
// Chainlink Functions
//******************** */

address constant ETH_SEPOLIA_FUNCTIONS_ROUTER = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
address constant AVL_FUJI_FUNCTIONS_ROUTER = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0;
address constant PLY_MUMBAI_FUNCTIONS_ROUTER = 0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C;

// fun-ethereum-sepolia-1 - in functions NPM package
bytes32 constant ETH_SEPOLIA_DON_ID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
// fun-avalanche-fuji-1 - in functions NPM package
bytes32 constant AVL_FUJI_DON_ID = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000;
// fun-polygon-mumbai-1 - in functions NPM package
bytes32 constant PLY_MUMBAI_DON_ID = 0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000;

bytes constant FUNCTIONS_URL_SECRETS_ENDPOINT = abi.encode("https://01.functions-gateway.testnet.chain.link/");

// Propper gas limits should be tested and set, 300.000 is just a random first try.
uint32 constant GAS_LIMIT_FIGHT_GENERATION = 300_000;
uint32 constant GAS_LIMIT_NFT_GENERATION = 300_000;

// source.js - Files executed by CLFunctions at the end of this file.

//******************** */
// Chainlink VRF
//******************** */

address constant ETH_SEPOLIA_VRF_COORDINATOR = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
address constant AVL_FUJI_VRF_COORDINATOR = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
address constant PLY_MUMBAI_VRF_COORDINATOR = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

// 150 gwei
bytes32 constant ETH_SEPOLIA_KEY_HASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
// 300 gwei
bytes32 constant AVL_FUJI_KEY_HASH = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
// 500 gwei
bytes32 constant PLY_MUMBAI_KEY_HASH = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

uint16 constant ETH_SEPOLIA_REQ_CONFIRIMATIONS = 3;
uint16 constant AVL_FUJI_REQ_CONFIRIMATIONS = 3;
uint16 constant PLY_MUMBAI_REQ_CONFIRIMATIONS = 3;

uint32 constant ETH_SEPOLIA_CALLBACK_GAS_LIMIT_VRF = 250_000;
uint32 constant AVL_FUJI_CALLBACK_GAS_LIMIT_VRF = 300_000;
uint32 constant PLY_MUMBAI_CALLBACK_GAS_LIMIT_VRF = 350_000;

//********************** */
// Chainlink AUTOMATION
//********************** */

uint256 constant ETH_SEPOLIA_UPKEEP_ID = 106402147216017337972960404027226034932094583681968993079028192524993603665983;

address constant ETH_SEPOLIA_REGISTRY = 0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad;
address constant ETH_SEPOLIA_REGISTRAR = 0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976;

address constant AVL_FUJI_REGISTRY = 0x819B58A646CDd8289275A87653a2aA4902b14fe6;
address constant AVL_FUJI_REGISTRAR = 0xD23D3D1b81711D75E1012211f1b65Cc7dBB474e2;

address constant PLY_MUMBAI_REGISTRY = 0x08a8eea76D2395807Ce7D1FC942382515469cCA1;
address constant PLY_MUMBAI_REGISTRAR = 0x0Bc5EDC7219D272d9dEDd919CE2b4726129AC02B;

uint32 constant GAS_LIMIT_SEPOLIA_AUTOMATION = 680_000;
uint32 constant GAS_LIMIT_FUJI_AUTOMATION = 700_000;
uint32 constant GAS_LIMIT_PLY_MUMBAI_AUTOMATION = 700_000;

//******************** */
// Chainlink CCIP
//******************** */

address constant ETH_SEPOLIA_CCIP_ROUTER = 0xD0daae2231E9CB96b94C8512223533293C3693Bf;
address constant AVL_FUJI_CCIP_ROUTER = 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8;
address constant PLY_MUMBAI_CCIP_ROUTER = 0x70499c328e1E2a3c41108bd3730F6670a44595D1;

uint64 constant ETH_SEPOLIA_SELECTOR = 16015286601757825753;
uint64 constant AVL_FUJI_SELECTOR = 14767482510784806043;
uint64 constant PLY_MUMBAI_SELECTOR = 12532609583862916517;

//**************************** */
// CHAINLINK FUNCTIONS SCRIPTS
//**************************** */

// TODO: this 2 values can be deleted probably
bytes32 constant GENERATE_FIGHT_SCRIPT_HASH = keccak256(abi.encode(FIGHT_GENERATION_SCRIPT));
bytes32 constant GENERATE_NFT_SCRIPT_HASH = keccak256(abi.encode(NFT_GENERATION_SCRIPT));

string constant NFT_GENERATION_SCRIPT_MOCK = "console.log(\"date is: \", Date.now());\n\n"
    "function splitString(input) {\n" "  return input.split(\"-\");\n" "}\n\n" "const fullPrompt = args[0];\n"
    "const parts = splitString(fullPrompt);\n\n" "let result;\n" "if (parts[0][0] == \"a\") {\n" "  result = args[0];\n"
    "} else {\n" "  result = \" \";\n" "}\n" "console.log(result);\n" "return Functions.encodeString(result);";

string constant FIGHT_GENERATION_SCRIPT_MOCK = "function splitString(input) {\n" "  return input.split(\"-\");\n"
    "}\n\n" "const fullPrompt = args[0];\n" "const parts = splitString(fullPrompt);\n\n"
    "const fullPrompt2 = args[1];\n" "const parts2 = splitString(fullPrompt2);\n\n"
    "const result = `${parts[0]} fought against  \n" "    ${parts2[0]}. It was a fight so legendary that broke \n"
    "    OpenAIs API services. WOOOOOW!` \n" "    `${parts[1]} used its ${parts[3]} against\n"
    "    the ${parts2[3]} of ${parts[1]}. After the clash the winner was...`;\n\n" "console.log(result);\n"
    "return Functions.encodeString(result);";

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

//**************************** */
// FUNCTIONS USED IN SCRIPTS
//**************************** */

function intToString(uint256 _value) pure returns (string memory) {
    // Initial check for zero is not needed since _value is never zero

    uint256 length;
    uint256 temp = _value;

    // Calculate length of the string
    while (temp != 0) {
        length++;
        temp /= 10;
    }

    // Allocate memory for the string
    bytes memory buffer = new bytes(length);

    // Populate the string
    for (uint256 i = length; i > 0; i--) {
        buffer[i - 1] = bytes1(uint8(48 + _value % 10));
        _value /= 10;
    }

    return string(buffer);
}
