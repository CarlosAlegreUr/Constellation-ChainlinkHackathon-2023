import { Figth } from "../generated/schema";

import { BetsVault__BetsSentToWinner as BetsSentToWinner } from "../generated/BetsVault/BetsVault";

export function handleFightSettled(event: BetsSentToWinner): void {
  // let figthId = event.params.fightId.toHexString();

  let figth = Figth.load(event.params.fightId.toHexString());
  figth = figth!;

  figth.status = "SETTLED";
  figth.winner = event.params.winner.toHexString();

  figth.save();
}
