import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll,
} from "matchstick-as/assembly/index";
import { Address, BigInt } from "@graphprotocol/graph-ts";
import { FightMatchmaker__FightAccepted } from "../generated/schema";
import { FightMatchmaker__FightAccepted as FightMatchmaker__FightAcceptedEvent } from "../generated/Contract/Contract";
import { handleFightMatchmaker__FightAccepted } from "../src/handleFightMatchmaker__FightAccepted";
import { createFightMatchmaker__FightAcceptedEvent } from "./contract-utils";

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let challenger = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    );
    let challengee = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    );
    let timestamp = BigInt.fromI32(234);
    let nftIdChallenger = BigInt.fromI32(234);
    let nftIdChallengee = BigInt.fromI32(234);
    let betChallenguer = BigInt.fromI32(234);
    let betChallenguee = BigInt.fromI32(234);
    let newFightMatchmaker__FightAcceptedEvent = createFightMatchmaker__FightAcceptedEvent(
      challenger,
      challengee,
      timestamp,
      nftIdChallenger,
      nftIdChallengee,
      betChallenguer,
      betChallenguee
    );
    handleFightMatchmaker__FightAccepted(
      newFightMatchmaker__FightAcceptedEvent
    );
  });

  afterAll(() => {
    clearStore();
  });

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("FightMatchmaker__FightAccepted created and stored", () => {
    assert.entityCount("FightMatchmaker__FightAccepted", 1);

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "FightMatchmaker__FightAccepted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "challenger",
      "0x0000000000000000000000000000000000000001"
    );
    assert.fieldEquals(
      "FightMatchmaker__FightAccepted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "challengee",
      "0x0000000000000000000000000000000000000001"
    );
    assert.fieldEquals(
      "FightMatchmaker__FightAccepted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "timestamp",
      "234"
    );
    assert.fieldEquals(
      "FightMatchmaker__FightAccepted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "nftIdChallenger",
      "234"
    );
    assert.fieldEquals(
      "FightMatchmaker__FightAccepted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "nftIdChallengee",
      "234"
    );
    assert.fieldEquals(
      "FightMatchmaker__FightAccepted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "betChallenguer",
      "234"
    );
    assert.fieldEquals(
      "FightMatchmaker__FightAccepted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "betChallenguee",
      "234"
    );

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  });
});
