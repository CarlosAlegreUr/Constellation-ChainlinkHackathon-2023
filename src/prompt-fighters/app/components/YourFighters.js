"use client";
import React from "react";
import {SEPOLIA_PROMPT_FIGHTERS_NFT} from "../constants";
import * as IPromptFightersCollection from "../contracts-artifacts/IPromptFightersCollection.sol/IPromptFightersCollection.json";
import { useState, useEffect } from "react";
import { getAccount, getPublicClient } from "@wagmi/core";
import { useBlockNumber, useContractEvent } from "wagmi";

export default function YourFighters() {
  const [fighters, setFighters] = useState([]);
  const account = getAccount();
  const publicClient = getPublicClient();
  const { data: currentBlock } = useBlockNumber();

  // Get newly minted NFTs
  useContractEvent({
    address: SEPOLIA_PROMPT_FIGHTERS_NFT,
    abi: IPromptFightersCollection.abi,
    eventName: 'PromptFighters__NftMinted',
    listener(log) {
      console.log("New NFT created with ID", log[0].args.nftId);
      setFighters(prevFighters => [...prevFighters, getFighter(log[0].args.nftId)]);
    },
  })

  async function getEvents() {
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

  async function getFighter(nftId) {
    const prompt = await publicClient.readContract({
      address: SEPOLIA_PROMPT_FIGHTERS_NFT,
      abi: IPromptFightersCollection.abi,
      functionName: "getPromptOf",
      args: [nftId],
    });
    const name = prompt.split("-")[0];
    return (
      <div key={nftId} className="shadow appearance-none border rounded w-full py-1 my-2 text-gray-700 leading-tight focus:outline-none focus:shadow-outline">
        <h1 className="block text-gray-700 text-xs font-bold m-1">Id: {Number(nftId)}</h1>
        <h1 className="block text-gray-700 text-xs font-bold m-1">Name: {name}</h1>
        <h1 className="block text-gray-700 text-xs font-bold m-1 ">Prompt: {prompt}</h1>
      </div>
    );
  }

  // Load existent NFTs 
  useEffect(() => {
    getEvents().then(async (logs) => {
      const nftIds = logs.map((log) => log.args.nftId);
      console.log("NFTs fetched: ", nftIds);
      setFighters(await Promise.all(nftIds.map((nftId) => getFighter(nftId))));
    });
  }, []);

  return (
    <div className="flex flex-col h-full w-full">
      <h1>YourFighters</h1>
      <div className=" w-full h-full  overflow-y-scroll bg-white shadow-md rounded px-8 pt-6 py-6">
        {fighters}
      </div>
    </div>
  );
}