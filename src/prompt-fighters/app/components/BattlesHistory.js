"use client";
import React from "react";
import { getContract } from "@wagmi/core";
import SEPOLIA_PROMPT_FIGHTERS_NFT from "../constants";
import * as IPromptFightersCollection from "../contracts-artifacts/IPromptFightersCollection.sol/IPromptFightersCollection.json";
import * as IFightMatchermaker from "../contracts-artifacts/IFightMatchmaker.sol/IFightMatchmaker.json";
import { useState } from "react";
import { getAccount } from "@wagmi/core";
import { getPublicClient } from "@wagmi/core";
import { useBlockNumber } from "wagmi";
import { useEffect } from "react";

export default function BattlesHistory() {
  const [battles, setBattles] = useState([]);
  const account = getAccount();
  const publicClient = getPublicClient();
  const { data } = useBlockNumber();

  const contract = getContract({
    address: SEPOLIA_PROMPT_FIGHTERS_NFT,
    abi: IFightMatchermaker.abi,
  });

  async function getEvents() {
    return await publicClient.getContractEvents({
      address: SEPOLIA_PROMPT_FIGHTERS_NFT,
      abi: IFightMatchermaker.abi,
      eventName: "FightMatchmaker__FightRequestedTo",
      args: {
        challengee: account.address,
      },
      fromBlock: 4788494n,
      toBlock: data,
    });
  }

  async function getBattle(battleId) {
    //const prompt
    const prompt = await publicClient.readContract({
      address: SEPOLIA_PROMPT_FIGHTERS_NFT,
      abi: IPromptFightersCollection.abi,
      functionName: "getPromptOf",
      args: [battleId],
    });
    const name = prompt.split("-")[0];
    return (
      <div key={nftId} className=" bg-green-400 flex flex-col justify-center p-2  border border-gray-400 rounded leading-tight focus:outline-none focus:shadow-outline">
        <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
          Battle Id: BATTLE ID
        </h1>
        <div className=" flex flex-row gap-3 items-center">
          <div className=" border border-gray-600 rounded w-80 py-1 ">
            <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
              {name}
            </h1>
            <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
              Id: {Number(nftId)}
            </h1>
          </div>
          <h1 className="text-gray-700 font-bold "> VS </h1>
          <div className=" border border-gray-600 rounded  w-80 py-1">
            <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
              {name}
            </h1>
            <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
              Id: {Number(nftId)}
            </h1>
          </div>
        </div>
        <h1 className="block text-gray-700 text-center text-xs font-bold m-1">
          YOU WON!
        </h1>
      </div>
    );
  }

  // EXTRACT FIGHT DATA FROM LOGS AND FOR EACH BATTLE AND SETS THE BATTLES ARRAY STATE
  useEffect(() => {
    getEvents().then(async (logs) => {
      const battleIds = logs.map((log) => log.args.nftId); // replace nftId with battleId
      console.log(logs)
      setBattles(await Promise.all(battleIds.map((battleId) => getBattle(battleId))));
    });
  }, []);

  return (
    <div className=" flex flex-col relative h-full w-1/2">
      <h1>Battle history</h1>
      <div className=" h-full w-full flex flex-col gap-1 overflow-y-scroll bg-white shadow-md rounded px-8 pt-6 py-6">
        {battles}
      </div>
    </div>
  );
}
