// pages/api/generate-stories.ts

import type { NextApiRequest, NextApiResponse } from "next";
import fetch from "node-fetch";

const MINIMUM_NUMBER_TRANSACTIONS = 15
const ADDRESS_CONTRACT = ''

let counterTransact: number = 0

// the transactions will be stored here 
let _transactions /*: transaction[] */;

async function sendBatchOfTransaction() {
  // send batch of transactions that are in memory
  

  // if success {
  //    resset value of transactions to empty
  // } else {
  //    don't reset inform error
  // }

}

function constructTransaction(addrressTo: string, stories: string[]) {
  // construct the transactions
  
  // return transaction
}

// Function to make the HTTP call to OpenAI
async function fetchOpenAIResponse(id: string, content: string): Promise<any> {
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

    return [id, result]

  } catch (error) {
    console.error("Error fetching from OpenAI:", error);
    throw new Error("Error fetching from OpenAI");
  }
}

// API route handler
export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // Check if the request is a POST request and the content type is JSON
  if (req.method !== 'POST') {
    res.status(405).end('Method Not Allowed');
    return;
  }

  if (req.headers['content-type'] !== 'application/json') {
    res.status(415).end('Unsupported Media Type, please send a JSON content');
    return;
  }

  // Check if the body has the required keys
  const { id, content } = req.body;
  if (id === undefined || content === undefined) {
    res.status(400).end('Bad Request: JSON body must include both "id" and "content" fields');
    return;
  }

  const conts = content.split("-")
  if (conts.length != 10) {

    res.status(400).json({ error:'Bad Request: "content" must have 10 arguments'})
    return;
  }

  // Extract arguments from the request body or query
  // You should validate these arguments before using them

  // Template for the GPT prompt

  try {
  
    res.status(200).json({ id: id, args: content.split("-") });
    
    counterTransact += 1;
    console.log("numer of transaction standing by: ", counterTransact)
  
    // This returnes the two stories
    const openAIResponse = await fetchOpenAIResponse(id, content);

    // transactions += constructTransaction(ADDRESS_CONTRACT, openAIResponse)

    
    if (counterTransact === MINIMUM_NUMBER_TRANSACTIONS) {
  
      // sendBatchOfTransaction(transactions)

      console.log("batch transactions and send to blockchain");
      console.log("reset counter");


      counterTransact = 0;

    }


    // const openAIResponse = await fetchOpenAIResponse(id, request);
    //
    // if (openAIResponse.error) {
    //   throw new Error(JSON.stringify(openAIResponse.error));
    // }
    //
    // const result = openAIResponse.choices[0].message.content;
    // res.status(200).json({ stories: result });
  } catch (error) {
    console.error("Request failed:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
}
