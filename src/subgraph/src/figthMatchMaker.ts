import {
  Address,
  dataSource,
  log,
  ethereum,
  Value,
} from "@graphprotocol/graph-ts";
import {
  FightMatchmaker__FightRequested as FigthRequestedEvent,
  FightMatchmaker__FightAccepted as FigthAcceptedEvent,
  FightMatchmaker__FightAcceptedByUpkeep as FigthAcceptedUpkeed,
  FigthMatchMaker as FigthMatchMakerContract,
} from "../generated/FigthMatchMaker/FigthMatchMaker";
import { PromptFigthers as PromptFigthersContract } from "../generated/PromptFigther/PromptFigthers";
import { Figth, Figther, User } from "../generated/schema";

import { BetsVault__BetsSentToWinner as BetsSentToWinner } from "../generated/BetsVault/BetsVault";

export function handleRequestedFigth(event: FigthRequestedEvent): void {
  log.info("Processing figth with id: {}", [
    event.params.fightId.toHexString(),
  ]);

  let context = dataSource.context();
  let promptAddress = context.get("prompt_figther_address");

  let promptFigthers = PromptFigthersContract.bind(
    Address.fromString(promptAddress!.toString())
  );

  let MatchMaker = FigthMatchMakerContract.bind(event.address);
  let figthObject = MatchMaker.getFight(event.params.fightId);
  // create figth entity
  let figth = new Figth(event.params.fightId.toHexString());

  //////////////////////
  /////  Figthers  /////
  //////////////////////
  let nftChallengerId = figthObject.nftRequester;
  let nftChallengeeId = figthObject.nftAcceptor;

  let nftChallenger = Figther.load(nftChallengerId.toString());
  let nftChallengee = Figther.load(nftChallengeeId.toString());

  // save figth in figthers
  nftChallenger!.save();
  nftChallengee!.save();

  //////////////////////
  /////   Users   //////
  //////////////////////
  let challengerAddress = promptFigthers.ownerOf(nftChallengerId);
  let challengeeAddress = promptFigthers.ownerOf(nftChallengeeId);

  let challengerUser = User.load(challengerAddress.toHexString());
  let challengeeUser = User.load(challengeeAddress.toHexString());

  challengerUser!.Figths!.push(event.params.fightId.toHexString());
  challengeeUser!.Figths!.push(event.params.fightId.toHexString());

  challengerUser!.save();
  challengeeUser!.save();

  //////////////////////
  /////   Figth   //////
  //////////////////////
  figth.status = "REQUESTED";
  figth.bet = event.params.bet;

  // assign users
  figth.challenger = challengerAddress.toHexString();
  figth.challengee = challengeeAddress.toHexString();

  // assign figthera
  figth.nftChallenger = nftChallengerId.toString();
  figth.nftChallengee = nftChallengerId.toString();

  figth.save();
}

export function handleAcceptedFigthUpkeep(event: FigthAcceptedUpkeed): void {
  // TODO: Tengo que hacer algo para la mutación de datos?? o esta todo bien?

  let context = dataSource.context();
  let promptAddress = context.get("prompt_figther_address");

  let promptFigthers = PromptFigthersContract.bind(
    Address.fromString(promptAddress!.toString())
  );

  let challengeeAddress = promptFigthers.getOwnerOf(
    event.params.nftIdChallenger
  );

  let MatchMaker = FigthMatchMakerContract.bind(event.address);

  // convert to HexString for convinience
  let figthId = MatchMaker.getFightId(
    event.params.challenger,
    event.params.nftIdChallenger,
    challengeeAddress,
    event.params.nftIdChallengee
  ).toHexString();

  log.info(
    "Processing accepted figth with __supossed__ id: {}, with the transaction hash: {}",
    [figthId, event.transaction.hash.toHexString()]
  );

  // asume that it won't fail
  let figth = Figth.load(figthId);
  figth!.status = "ACCEPTED";

  let challenger = User.load(event.params.challenger.toHexString());
  let challengee = User.load(challengeeAddress.toHexString());

  let nftChallenger = Figther.load(event.params.nftIdChallenger.toString());
  let nftChallengee = Figther.load(event.params.nftIdChallengee.toString());

  // add figth to users
  challenger!.Figths!.push(figthId);
  challengee!.Figths!.push(figthId);

  // add figth to figthers
  nftChallenger!.Figths!.push(figthId);
  nftChallengee!.Figths!.push(figthId);

  // save the state
  challenger!.save();
  challengee!.save();

  nftChallenger!.save();
  nftChallengee!.save();

  figth!.save();
}

export function handleAcceptedFigth(event: FigthAcceptedEvent): void {
  // TODO: Tengo que hacer algo para la mutación de datos?? o esta todo bien?

  let MatchMaker = FigthMatchMakerContract.bind(event.address);

  // convert to HexString for convinience
  let figthId = MatchMaker.getFightId(
    event.params.challenger,
    event.params.nftIdChallenger,
    event.params.challengee,
    event.params.nftIdChallengee
  ).toHexString();

  log.info(
    "Processing accepted figth with __supossed__ id: {}, with the transaction hash: {}",
    [figthId, event.transaction.hash.toHexString()]
  );

  // asume that it won't fail
  let figth = Figth.load(figthId);
  figth!.status = "ACCEPTED";

  let challenger = User.load(event.params.challenger.toHexString());
  let challengee = User.load(event.params.challengee.toHexString());

  let nftChallenger = Figther.load(event.params.nftIdChallenger.toString());
  let nftChallengee = Figther.load(event.params.nftIdChallengee.toString());

  // add figth to users
  challenger!.Figths!.push(figthId);
  challengee!.Figths!.push(figthId);

  // add figth to figthers
  nftChallenger!.Figths!.push(figthId);
  nftChallengee!.Figths!.push(figthId);

  // save the state
  challenger!.save();
  challengee!.save();

  nftChallenger!.save();
  nftChallengee!.save();

  figth!.save();
}

// hacer funccion para saber si vienen de sepolia o fuji los nfts

// export function handleNFTSentSepolia(event: Event): void {}
// export function handleNFTSenFuji(event: Event): void {}
