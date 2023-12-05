"use client";
import React from "react";
import { getContract } from "@wagmi/core";
import SEPOLIA_PROMPT_FIGHTERS_NFT from "../constants";
import * as IPromptFightersCollection from "../contracts-artifacts/IPromptFightersCollection.sol/IPromptFightersCollection.json";
import { useState } from "react";
import { getAccount } from "@wagmi/core";
import { getPublicClient } from "@wagmi/core";
import { useBlockNumber } from "wagmi";
import { useEffect } from "react";

export default function BattlesHistory() {
  const [fighters, setFighters] = useState([]);
  const account = getAccount();
  const publicClient = getPublicClient();
  const { data } = useBlockNumber();

  const contract = getContract({
    address: SEPOLIA_PROMPT_FIGHTERS_NFT,
    abi: IPromptFightersCollection.abi,
  });

  async function getEvents() {
    return await publicClient.getContractEvents({
      address: SEPOLIA_PROMPT_FIGHTERS_NFT,
      abi: IPromptFightersCollection.abi,
      eventName: "PromptFighters__NftMinted",
      args: {
        owner: account.address,
      },
      fromBlock: 4788494n,
      toBlock: data,
    });
  }

  async function getFighter(nftId) {
    //const prompt
    const prompt = await publicClient.readContract({
      address: SEPOLIA_PROMPT_FIGHTERS_NFT,
      abi: IPromptFightersCollection.abi,
      functionName: "getPromptOf",
      args: [nftId],
    });
    const name = prompt.split("-")[0];
    return (
      <div className=" flex flex-row gap-3 justify-center items-center">
        <div className="shadow appearance-none border rounded w-80 py-1 my-2 text-gray-700 leading-tight focus:outline-none focus:shadow-outline">
          <h1 className="block text-gray-700 text-xs font-bold m-1">
            Name: {name}
          </h1>
          <h1 className="block text-gray-700 text-xs font-bold m-1">
            Id: {Number(nftId)}
          </h1>
        </div>
        <h1 className="text-gray-700 font-bold "> VS </h1>
        <div className="shadow appearance-none border rounded w-80 py-1 my-2 text-gray-700 leading-tight focus:outline-none focus:shadow-outline">
          <h1 className="block text-gray-700 text-xs font-bold m-1">
            Name: {name}
          </h1>
          <h1 className="block text-gray-700 text-xs font-bold m-1">
            Id: {Number(nftId)}
          </h1>
        </div>
      </div>
    );
  }

  useEffect(() => {
    getEvents().then(async (logs) => {
      const nftIds = logs.map((log) => log.args.nftId);
      setFighters(await Promise.all(nftIds.map((nftId) => getFighter(nftId))));
    });
  }, [contract]);

  return (
    <div className="h-[650px] w-1/2">
      <h1>Battle history</h1>
      <div className=" w-full h-full  overflow-y-scroll bg-white shadow-md rounded px-8 pt-6 py-6">
        {fighters.map((fighter) => fighter)}
      </div>
    </div>
  );
}
