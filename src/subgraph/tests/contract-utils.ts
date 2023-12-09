import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  FightMatchmaker__FightAccepted,
  NewFighter
} from "../generated/Contract/Contract"

export function createFightMatchmaker__FightAcceptedEvent(
  challenger: Address,
  challengee: Address,
  timestamp: BigInt,
  nftIdChallenger: BigInt,
  nftIdChallengee: BigInt,
  betChallenguer: BigInt,
  betChallenguee: BigInt
): FightMatchmaker__FightAccepted {
  let fightMatchmakerFightAcceptedEvent = changetype<
    FightMatchmaker__FightAccepted
  >(newMockEvent())

  fightMatchmakerFightAcceptedEvent.parameters = new Array()

  fightMatchmakerFightAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "challenger",
      ethereum.Value.fromAddress(challenger)
    )
  )
  fightMatchmakerFightAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "challengee",
      ethereum.Value.fromAddress(challengee)
    )
  )
  fightMatchmakerFightAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "timestamp",
      ethereum.Value.fromUnsignedBigInt(timestamp)
    )
  )
  fightMatchmakerFightAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "nftIdChallenger",
      ethereum.Value.fromUnsignedBigInt(nftIdChallenger)
    )
  )
  fightMatchmakerFightAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "nftIdChallengee",
      ethereum.Value.fromUnsignedBigInt(nftIdChallengee)
    )
  )
  fightMatchmakerFightAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "betChallenguer",
      ethereum.Value.fromUnsignedBigInt(betChallenguer)
    )
  )
  fightMatchmakerFightAcceptedEvent.parameters.push(
    new ethereum.EventParam(
      "betChallenguee",
      ethereum.Value.fromUnsignedBigInt(betChallenguee)
    )
  )

  return fightMatchmakerFightAcceptedEvent
}

export function createNewFighterEvent(id: BigInt, prompt: string): NewFighter {
  let newFighterEvent = changetype<NewFighter>(newMockEvent())

  newFighterEvent.parameters = new Array()

  newFighterEvent.parameters.push(
    new ethereum.EventParam("id", ethereum.Value.fromUnsignedBigInt(id))
  )
  newFighterEvent.parameters.push(
    new ethereum.EventParam("prompt", ethereum.Value.fromString(prompt))
  )

  return newFighterEvent
}
