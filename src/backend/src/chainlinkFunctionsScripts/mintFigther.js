const gptPrompt = ```Take a deep breath and do 2 things:

1.- Deem the desciption VALID or INVALID-
2.- Generate an image.

------

DETAILS ON HOW TO DO THE IMAGE:

Be super artistic and create a REALISTIC image of a character that:

- Name: A_NAME
a- Race: WRITE_ANYTHING_YOU_CAN_IMAGINE
a- Weapon: WRITE_ANYTHING_YOU_CAN_IMAGINE
b- Special skill: WRITE_ANYTHING_YOU_CAN_IMAGINE
- Fear: WRITE_ANYTHING_YOU_CAN_IMAGINE

DONT ADD TEXT ON the image, just the character.
Only include in the image the traits marked with "a-".
The traits starting with "b-" only include them if they can be interestingly visualized.


These are the filters FILTERS:

- If the character is too powerful return INVALID. Too powerful means that the character has in the description
things like infinite power or, it always defeats enemies etc Things that can't make the prompt fight interesting to 
read.

- We dont mind characters being gods or stuff very powerful like blackholes as fights can get as crazy as they must be 
so there is a winner. We just wanna filter texts saying things like my character always wins.

- If the description of the character goes agains OpenAI DALL-3 image generation and the image generation fails then 
als return INVALID.

- If the character is too crazy for being relaistic dont worry and deem the prompt VALID.

```;

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
});

if (openAIResponse.error) {
  throw new Error(JSON.stringify(openAIResponse));
}

const result = openAIResponse.data.choices[0].message.content;

console.log(result);
return Functions.encodeString(result);
