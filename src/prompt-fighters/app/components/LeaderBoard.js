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

export default function LeaderBoard() {
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
      fromBlock: 4788494n,
      toBlock: data,
    });
  }

  async function getFighter(nftId, owner) {
    //const prompt
    const prompt = await publicClient.readContract({
      address: SEPOLIA_PROMPT_FIGHTERS_NFT,
      abi: IPromptFightersCollection.abi,
      functionName: "getPromptOf",
      args: [nftId],
    });
    const name = prompt.split("-")[0];
    return (
      <div key={nftId} className=" flex flex-col border rounded w-full p-1 shadow appearance-none leading-tight focus:outline-none focus:shadow-outline">
        <h1 className=" text-gray-700 text-xs font-bold">
          Id: {Number(nftId)}
        </h1>
        <h1 className=" text-gray-700 text-xs font-bold">
          Name: {name}
        </h1>
        <h1 className=" text-gray-700 text-xs font-bold">
          Owner: {owner}
        </h1>
        <h1 className=" text-gray-700 text-xs font-bold">
          Prompt: {prompt}
        </h1>
        <h1 className=" text-gray-700 text-xs font-bold">
          Wins: 1000
        </h1>
      </div>
    );
  }

  useEffect(() => {
    getEvents().then(async (logs) => {
      const nftIdsAndOwners = logs.map((log) => [
        log.args.nftId,
        log.args.owner,
      ]);
      setFighters(
        await Promise.all(
          nftIdsAndOwners.map((nftIdsAndOwner) =>
            getFighter(nftIdsAndOwner[0], nftIdsAndOwner[1])
          )
        )
      );
    });
  }, [contract]);

  return (
      <div className=" flex overflow-y-scroll w-full h-full bg-white rounded my-8">
        <div className=" flex flex-col h-0 w-full m-4 gap-1">
          {fighters}
        </div>
      </div>
  );
}
