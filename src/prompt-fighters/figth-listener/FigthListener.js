const { ethers } = require("ethers");
const {
  THE_GRAPH_URL,
  FIGTH_EXECUTION_ABI,
  FIGTH_EXECUTOR_ADDRESS,
} = require("./constants");
require('dotenv').config();

const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Create a contract instance
const figthExecutor = new ethers.Contract(FIGTH_EXECUTOR_ADDRESS, FIGTH_EXECUITION_ABI, signer);

Event listener for FightMatchmaker__FightAccepted
figthExecutor.on(
  "FightExecutor__started",
  async (
    figthId,
    requestId,
    nftChallengerPrompt,
    nftChallengeePrompt,
    _event
  ) => {

    submitTransaction(nftChallengerPrompt.toString(), nftChallengeePrompt.toString());
  
  }
);

console.log("Listening for FightMatchmaker__FightAccepted events...");
console.log("\n");

async function submitTransaction(prompt1, prompt2, resquestId) {
  try {

    // get prompts
    // const prompt1 = await getPromptNftById(id1); 
    // const prompt2 = await getPromptNftById(id2);

    // get stories from GPT
    let resp = await fetchOpenAIResponse(prompt1, prompt2);

    resp = resp[0] + "\n---\n" + resp[1];

    // submit stories to smart contract
    figthExecutor.fulfillRequestMock(requestId, resp, "");

    console.log("The transaction was sent succesfully!");

  } catch (e) {    
    console.log(e);
  }
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

I want this exact template (any element with these brackets "<>" it means that it's a placeholder is not meant to be in the response):


<story> 
---
<story>


Between the stories as a way to sparate them you will put this string: "---",
Your response will be use for a script and this is the only way that can be used by the script to 
separate the two stories.

I DON'T WANT ANY VARIATION OF IT RESPECT THE TEMPLATE

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

    const openAIResponse = await response.json();
  
    // console.log("openAIResponse: ", openAIResponse);


    let result = openAIResponse.choices[0].message.content;

    result = result.split("---")

    // trim the spaces for unnecesary bytes
    for (let i = 0; i < result.length ;i++) {
      result[i] = result[i].trim()
    }

    console.log(result);

    return result;

  } catch (error) {
    console.error("Error fetching from OpenAI:", error);
    throw new Error("Error fetching from OpenAI");
  }
}

// async function getPromptNftById(id) {
//   const query = `
//     query($idx: String) {
//       figther(id: $idx) {
//         funcResponse
//       }
//     }
//   `
//   let response = await fetch(THE_GRAPH_URL, {
//     method: "POST",
//     headers: {
//       "Content-Type": "application/json",
//       "Accept": "application/json",
//     },
//     body: JSON.stringify({
//       query,
//       variables: {
//         idx: id
//       }
//     })
//   })
//
//   response = await response.json();
//
//   // funcResponse corresponds with the prompt of the NFT
//   return response.data.figther.funcResponse
//
// }

