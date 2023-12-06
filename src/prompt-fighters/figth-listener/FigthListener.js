const { ethers } = require("ethers");
const {
  CONTRACT_ABI,
  CONTRACT_ADDRESS,
} = require("./constants");
require('dotenv').config();

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_PROVIDER_URL);
const signer = new ethers.Wallet(PRIVATE_KEY, provider);

// Create a contract instance
const contract = new ethers.Contract(process.emv.CONTRACT_ADDRESS, CONTRACT_ABI, signer);

// Event listener for FightMatchmaker__FightAccepted
contract.on(
  "FightMatchmaker__FightAccepted",
  async (
    _,
    _,
    _,
    nftIdChallenger,
    nftIdChallengee,
    _,
    _,
    _
  ) => {

    submitTransaction(nftIdChallenger.toString(), nftIdChallengee.toString());
  
  }
);

console.log("Listening for FightMatchmaker__FightAccepted events...");
console.log("\n");

async function submitTransaction(id1, id2) {
  try {

    // get prompts
    const prompt1 = getPromptNftById(id1); 
    const prompt2 = getPromptNftById(id2);

    // get stories from GPT
    resp = fetchOpenAIResponse(prompt1, prompt2);

    // submit stories to smart contract
    // contract.fulfillRequestMock(resp.requestId, res.body, resp.err);

    console.log("The transaction was sent succesfully!")
  } catch (e) {    
    console.log(e);
  }
}


async function getPromptNftById(id) {
  const query = `
    query($idx: String) {
      figther(id: $idx) {
        funcResponse
      }
    }
  `
  const url = "https://api.studio.thegraph.com/query/50966/promptfigthers/0.2.15"

  let response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify({
      query,
      variables: {
        idx: id
      }
    })
  })

  response = await response.json();


  // funcResponse corresponds with the prompt of the NFT
  return response.data.figther.funcResponse

}


// Function to make the HTTP call to OpenAI
async function fetchOpenAIResponse(prompt1, prompt2) {

  // prompt format: <Name>-<Race>-<Weapon>-<Special hability>-<Fear>

  const content = prompt1 + '-' + prompt2;
  const args = content.split("-");

  const gptPrompt = `
Here are 2 characters:

- CHARACTER 1:
- Name: ${args[0]}
- Race: ${args[1]}
- Weapon: ${args[2]}
- Special skill: ${args[3]}
- Fear: ${args[4]}

- CHARACTER 2:
- Name: ${args[5]}
- Race: ${args[6]}
- Weapon: ${args[7]}
- Special skill: ${args[8]}
- Fear: ${args[9]}

Take a deep breath and write a 2 super interesting stories.
These 2 stories describe a duel involving this 2 characters.
In 1 of the fights CHARACTER 1 wins and in the other CHARACTER 2 wins.
The stories musts be at most 6 lines of length. 


Between the stories as a way to sparate them you will put this string: "---",
Your response will be use for a script and this is the only way that can be used by the script to 
separate the two stories.

`;

  const postData = {
    model: "gpt-3.5-turbo",
    messages: [{ role: "user", content: gptPrompt }],
    temperature: 0,
  };

  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`, // Use environment variable for the API key
        "Content-Type": "application/json",
      },
      body: JSON.stringify(postData),
    });

    const openAIResponse = response.json();
    let result = openAIResponse.choices[0].message.content;

    result = result.split("---")

    // trim the spaces for unnecesary bytes
    for (let i = 0; i < result.length ;i++) {
      result[i] = result[i].trim()
    }

    return result;

  } catch (error) {
    console.error("Error fetching from OpenAI:", error);
    throw new Error("Error fetching from OpenAI");
  }
}



