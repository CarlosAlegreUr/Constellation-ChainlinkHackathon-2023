"use client";
import React from "react";
import { getContract } from "@wagmi/core";
import {
  SEPOLIA_PROMPT_FIGHTERS_NFT,
  SEPOLIA_FIGHT_MATCHERMAKER,
} from "../constants";
import * as IPromptFightersCollection from "../contracts-artifacts/IPromptFightersCollection.sol/IPromptFightersCollection.json";
import * as IFightMatchermaker from "../contracts-artifacts/IFightMatchmaker.sol/IFightMatchmaker.json";
import { useState } from "react";
import { getAccount } from "@wagmi/core";
import { getPublicClient } from "@wagmi/core";
import { useBlockNumber } from "wagmi";
import { useEffect } from "react";

export default function fightsHistory() {
  const [fights, setFights] = useState([]);
  const [yourFightersId, setYourFightersId] = useState([]);
  const account = getAccount();
  const publicClient = getPublicClient();
  const { data: currentBlock } = useBlockNumber();

  const contract = getContract({
    address: SEPOLIA_PROMPT_FIGHTERS_NFT,
    abi: IFightMatchermaker.abi,
  });

  async function getFightersEvents() {
    return await publicClient.getContractEvents({
      address: SEPOLIA_PROMPT_FIGHTERS_NFT,
      abi: IPromptFightersCollection.abi,
      eventName: "PromptFighters__NftMinted",
      args: {
        owner: account.address,
      },
      fromBlock: 4788494n,
      toBlock: currentBlock,
    });
  }
  // Load existent NFTs
  useEffect(() => {
    getFightersEvents().then(async (logs) => {
      const nftIds = logs.map((log) => log.args.nftId);
      setYourFightersId(nftIds);
    });
  }, []);

  async function getAllFights() {
    const fightsEvents = await publicClient.getContractEvents({
      address: SEPOLIA_FIGHT_MATCHERMAKER,
      abi: IFightMatchermaker.abi,
      eventName: "FightMatchmaker__UserToFightIdSet",
      fromBlock: 4788494n,
      toBlock: currentBlock,
    });
    const AllFights = await Promise.all(
      fightsEvents.map(async (fightEvent) => {
        const fightId = fightEvent.args.fightId;
        const fightInfo = await publicClient.readContract({
          address: SEPOLIA_FIGHT_MATCHERMAKER,
          abi: IFightMatchermaker.abi,
          functionName: "getFight",
          args: [fightId],
        });
        return { fightId, ...fightInfo };
      })
    );
    // Sort by timestamp
    AllFights.sort((a, b) => -Number(a.startedAt) - Number(b.startedAt));
    return AllFights;
  }

  useEffect(() => {
    getAllFights().then(async (AllFights) => {
      // filter only fights where my nfts are involved
      const myFights = AllFights.filter(
        (fight) =>
          yourFightersId.includes(fight.nftAcceptor) ||
          yourFightersId.includes(fight.nftRequester)
      );
      setFights(await Promise.all(myFights.map((fight) => getFight(fight))));
    });
  }, [yourFightersId]);

  async function fighterToName(nftId) {
    const prompt = await publicClient.readContract({
      address: SEPOLIA_PROMPT_FIGHTERS_NFT,
      abi: IPromptFightersCollection.abi,
      functionName: "getPromptOf",
      args: [nftId],
    });
    return prompt.split("-")[0];
  }

  async function getFight(fight) {
    // enum FightState {AVAILABLE, REQUESTED,ONGOING}
    const FightState = { 1: "AVAILABLE", 2: "REQUESTED", 3: "ONGOING" };
    return (
      <div
        key={fight.fightId}
        className=" flex flex-col justify-center p-2  border border-gray-400 rounded leading-tight focus:outline-none focus:shadow-outline"
      >
        <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
          Fight Id: {fight.fightId}
        </h1>
        <div className=" flex flex-row justify-center gap-3 items-center">
          <div className=" border border-gray-600 rounded w-80 py-1 ">
            <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
              {await fighterToName(fight.nftRequester)}
            </h1>
            <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
              Id: {Number(fight.nftRequester)}
            </h1>
          </div>
          <h1 className="text-gray-700 font-bold "> VS </h1>
          <div className=" border border-gray-600 rounded  w-80 py-1">
            <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
              {await fighterToName(fight.nftAcceptor)}
            </h1>
            <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
              Id: {Number(fight.nftAcceptor)}
            </h1>
          </div>
        </div>
        <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
          {FightState[fight.state]}
        </h1>
      </div>
    );
  }

  return (
    <div className=" flex flex-col relative h-full w-3/4">
      <h1>Fights history</h1>
      <div className=" h-full w-full flex flex-col gap-1 overflow-y-scroll bg-white shadow-md rounded px-8 pt-6 py-6">
        {fights}
      </div>
    </div>
  );
}
