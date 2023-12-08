console.log("date is: ", Date.now());

function splitString(input) {
  return input.split("-");
}

const fullPrompt = args[0];
const parts = splitString(fullPrompt);

let result;
if (parts[0][0] == "a") {
  result = args[0];
} else {
  result = " ";
}
console.log(result);
return Functions.encodeString(result);
