import { Bytes } from "@graphprotocol/graph-ts";
import { PromptFighters__NftMinted } from "../generated/RealContract/RealContract";
import { Figther } from "../generated/schema";

export function handleFigthers(event: PromptFighters__NftMinted): void {
  // Create a new FigthAccepted entity

  let id = event.params.nftId.toI64().toString();
  let entity = new Figther(id);

  entity.owner = event.params.owner;
  entity.funcResponse = event.params.funcsResponse.toString();
  entity.funcError = event.params.funcsError.toString();
  entity.timestamp = event.params.timestamp;
  entity.blockNumber = event.block.number;

  // Save the new entity
  entity.save();
}
