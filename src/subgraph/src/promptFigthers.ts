import { BigInt, Address, dataSource } from "@graphprotocol/graph-ts";
import {
  PromptFighters__NftMinted as FigtherMintedEvent,
  ICCIPNftBridge__NftSent as NFTSentCCIP,
  ICCIPNftBridge__NftReceived as NFTRecieveCCIP,
} from "../generated/PromptFigther/PromptFigthers";
import { User, Figther } from "../generated/schema";

// for transfers and minting
export function handleFighterMinted(event: FigtherMintedEvent): void {
  let user = User.load(event.params.owner.toHexString());

  if (user === null) {
    user = new User(event.params.owner.toHexString());
    user.numberLosses = BigInt.fromI32(0);
    user.numberWins = BigInt.fromI32(0);
    user.numberOfFigths = BigInt.fromI32(0);
    user.created = event.block.timestamp;

    // user.Figthers = new Array<string>();
    user.Figths = new Array<string>();
    user.save();
  }

  let figther = new Figther(event.params.nftId.toString());

  // set defaults
  figther.created = event.block.timestamp;
  figther.inEthereum = true;
  figther.inAvalanche = false;
  figther.automatedFigthingActivated = false;
  figther.numberOfFights = BigInt.fromI32(0);
  figther.numberWins = BigInt.fromI32(0);
  figther.numberLosses = BigInt.fromI32(0);
  figther.Figths = new Array<string>();

  let fields = event.params.funcsResponse.toString().split("-");

  figther.Name = fields.length >= 1 ? fields[0] : "";
  figther.Fear = fields.length >= 2 ? fields[1] : "";
  figther.Race = fields.length >= 3 ? fields[2] : "";
  figther.SpecialSkill = fields.length >= 4 ? fields[3] : "";
  figther.Weapon = fields.length >= 5 ? fields[4] : "";

  // set owner
  figther.owner = user.id;
  figther.save();

  // user.Figthers!
}

// TODO: declarar los addresses en context subgraph.yaml
// hacer funccion para saber si vienen de sepolia o fuji los nfts

export function handleNFTSent(event: NFTSentCCIP): void {
  let figther = Figther.load(event.params.nftId.toString());
  figther = figther!;

  figther.inAvalanche = true;
  figther.inEthereum = false;

  figther.save();
}

export function handleNFTRecieved(event: NFTRecieveCCIP): void {
  let figther = Figther.load(event.params.nftID.toString());
  figther = figther!;

  figther.inAvalanche = false;
  figther.inEthereum = true;

  figther.save();
}
