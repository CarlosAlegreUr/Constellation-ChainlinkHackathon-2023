import {
  FightMatchmaker__FightAccepted as FightMatchmaker__FightAcceptedEvent
} from "../generated/Contract/Contract";
import { FigthAccepted } from "../generated/schema";
// import { Bytes } from "@graphprotocol/graph-ts";

export function handleFightMatchmaker__FightAccepted(
  event: FightMatchmaker__FightAcceptedEvent
): void {
  // Create a new FigthAccepted entity
  let entity = new FigthAccepted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );

  // Set properties from the FightMatchmaker__FightAccepted event
  entity.challenger = event.params.challenger;
  entity.challengee = event.params.challengee;
  entity.timestamp = event.params.timestamp;
  entity.betChallenguer = event.params.betChallenguer;
  entity.betChallenguee = event.params.betChallenguee;
  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  // Link to NewFighter entities
  let NftIdChallenger = event.params.nftIdChallenger;
  let Challenger = NftIdChallenger

  let NftIdChallengee = event.params.nftIdChallengee;
  let Challengee = NftIdChallengee

  entity.fighterChallengerId = Challenger;
  entity.fighterChallengeeId = Challengee;

  // Save the new entity
  entity.save();
}


