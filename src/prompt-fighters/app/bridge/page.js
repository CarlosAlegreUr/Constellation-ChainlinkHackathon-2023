"use client";
import { useState } from "react";
import { useEffect } from "react";
import { getPublicClient } from "@wagmi/core";
import {
  SEPOLIA_PROMPT_FIGHTERS_NFT,
  SEPOLIA_FIGHT_MATCHERMAKER,
} from "../constants";
import { getAccount } from "@wagmi/core";
import * as IPromptFightersCollection from "../contracts-artifacts/IPromptFightersCollection.sol/IPromptFightersCollection.json";
import * as IFightMatchermaker from "../contracts-artifacts/IFightMatchmaker.sol/IFightMatchmaker.json";
import { useBlockNumber } from "wagmi";


export default function Bridge() {
  const [yourFighters, setYourFighters] = useState([]);
  const publicClient = getPublicClient();
  const account = getAccount();
  const { data } = useBlockNumber();

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
      <option
        key={nftId}
        value={nftId}
        className="block text-gray-700 text-xs font-bold m-1"
      >
        Id: {Number(nftId)} Name: {name}
      </option>
    );
  }


  async function getNftMintedEvents() {
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
  useEffect(() => {
    getNftMintedEvents().then(async (logs) => {
      const nftIds = logs.map((log) => log.args.nftId);
      setYourFighters(
        await Promise.all(nftIds.map((nftId) => getFighter(nftId)))
      );
    });
  }, []);

  async function submitBridgeRequest(e) {
    e.preventDefault();
  }

  return (
    <main className=" h-full flex flex-col items-center px-10">
      <h1 className=" text-4xl font-semibold">Bridge</h1>
      <div className="mt-8">
        <h1>Request Fight</h1>
        <div className="bg-white shadow-md rounded p-4">
          <form className=" flex flex-col gap-2" onSubmit={submitBridgeRequest}>
            <div>
              {/* NftId */}
              <label
                className="block text-gray-700 text-sm font-bold"
                htmlFor="NftId"
              >
                NFT Id
              </label>
              <select
                className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                id="NftId"
                name="NftId"
              >
                {yourFighters}
              </select>
            </div>
            <div>
              {/* Destination Chain */}
              <label
                className="block text-gray-700 text-sm font-bold"
                htmlFor="destinationChain"
              >
                Destination Chain
              </label>
              <input
                className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                id="destinationChain"
                type="number"
                placeholder="Chain ID"
              />
            </div>

            <button
              className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
              type="submit"
            >
              Bridge
            </button>
          </form>
        </div>
      </div>
    </main>
  );
}
