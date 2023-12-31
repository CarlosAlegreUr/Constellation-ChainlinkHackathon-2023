console.log("date is: ", Date.now());

function splitString(input) {
  return input.split("-");
}

const fullPrompt = args[0];
const parts = splitString(fullPrompt);

const gptPrompt = `Take a deep breath and do 1 thing:

1.- Deem the description VALID or INVALID

------

DETAILS ON HOW TO DO THE IMAGE:

Be super artistic and create a REALISTIC image of a character that:

- Name: A_NAME
- Race: WRITE_ANYTHING_YOU_CAN_IMAGINE
- Weapon: WRITE_ANYTHING_YOU_CAN_IMAGINE
- Special skill: WRITE_ANYTHING_YOU_CAN_IMAGINE
- Fear: WRITE_ANYTHING_YOU_CAN_IMAGINE

You will always return the word VALID or INVALID, not other words, this is meant to be used for a script, and the script cannot support other text, only the words INVALID or INVALID, don't explain why you chose a certain option, just say if the character is valid or not with the following FILTERS:

- If the character is too powerful return INVALID. Too powerful means that the character has in the description
things like infinite power or, it always defeats enemies etc Things that can't make the prompt fight interesting to
read.

- We dont mind characters being gods or stuff very powerful like blackholes as fights can get as crazy as they must be
so there is a winner. We just wanna filter texts saying things like my character always wins.

- If the description of the character goes agains OpenAI DALL-3 image generation and the image generation fails then
als return INVALID.

- If the character is too crazy for being relaistic dont worry and deem the prompt VALID.

This is the prompt deam it VALID or INVALID:

- Name: ${parts[0]}
- Race: ${parts[1]}
- Weapon: ${parts[2]}
- Special skill: ${parts[3]}
- Fear: ${parts[4]}

`;

const postData = {
  model: "gpt-3.5-turbo",
  messages: [{ role: "user", content: gptPrompt }],
  temperature: 0,
};

const openAIResponse = await Functions.makeHttpRequest({
  url: "https://api.openai.com/v1/chat/completions",
  method: "POST",
  headers: {
    Authorization: `Bearer ${secrets.apiKey}`,
    "Content-Type": "application/json",
  },
  data: postData,
  timeout: 9000,
});

console.log("Executes till here");

if (openAIResponse.error) {
  throw new Error(JSON.stringify(openAIResponse));
}

const result = openAIResponse.data.choices[0].message.content;

if (result != "VALID") {
  return Functions.encodeString(args[0]); //args[0] is the whole prompt
} else {
  // TODO: return just a 0 or 1 so is easy to detect in smart contract
  return Functions.encodeString("INVALID");
}
