function splitString(input) {
  return input.split("-");
}

const fullPrompt = args[0];
const parts = splitString(fullPrompt);

const fullPrompt2 = args[1];
const parts2 = splitString(fullPrompt2);

const result = `${parts[0]} fought against  
    ${parts2[0]}. It was a fight so legendary that broke 
    OpenAIs API services. WOOOOOW!" \n
    ${parts[1]} used its ${parts[3]} against
    the ${parts2[3]} of ${parts[1]}. After the clash the winner was...`;

console.log(result);
return Functions.encodeString(result);
