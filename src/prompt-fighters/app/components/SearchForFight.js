"use client";
import React from "react";
import { useContractWrite } from "wagmi";
import {
  SEPOLIA_PROMPT_FIGHTERS_NFT,
  SEPOLIA_FIGHT_MATCHERMAKER,
} from "../constants";
import * as IPromptFightersCollection from "../contracts-artifacts/IPromptFightersCollection.sol/IPromptFightersCollection.json";
import * as IFightMatchermaker from "../contracts-artifacts/IFightMatchmaker.sol/IFightMatchmaker.json";
import { getAccount } from "@wagmi/core";
import { getPublicClient } from "@wagmi/core";
import { useState } from "react";
import { useBlockNumber } from "wagmi";
import { useEffect } from "react";
import { getContract } from "@wagmi/core";
import { encodeAbiParameters } from "viem";

export default function SearchForFight() {
  const [yourFighters, setYourFighters] = useState([]);
  const account = getAccount();
  const publicClient = getPublicClient();
  const { data } = useBlockNumber();

  const contract = getContract({
    address: SEPOLIA_PROMPT_FIGHTERS_NFT,
    abi: IPromptFightersCollection.abi,
  });

  // FETCH YOUR NFTS FROM BLOCKCHAIN TO FILL OPTION DROPDOWN MENU
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

  useEffect(() => {
    getNftMintedEvents().then(async (logs) => {
      const nftIds = logs.map((log) => log.args.nftId);
      setYourFighters(
        await Promise.all(nftIds.map((nftId) => getFighter(nftId)))
      );
    });
  }, []);

  // SUBMIT FIGHT REQUEST

  const {
    isLoading: requestFightIsLoading,
    isSuccess: requestFightIsSuccess,
    write: requestFightWrite,
  } = useContractWrite({
    address: SEPOLIA_FIGHT_MATCHERMAKER,
    abi: IFightMatchermaker.abi,
    functionName: "requestFight",
  });

  async function submitRequestFight(e) {
    e.preventDefault();
    const t = e.target;
    const FightRequest = {
      challengerNftId: Number(e.target[0].value),
      minBet: Number(e.target[1].value),
      acceptanceDeadline: Number(e.target[2].value),
      challengee: e.target[3].value,
      challengeeNftId: Number(e.target[4].value),
    };
    requestFightWrite({ args: [FightRequest] });
  }

  async function submitAcceptFight(e) {

  }

  return (
    <>
      <div className=" flex flex-col justify-between h-full w-1/4">
        <div>
          <h1>Request Fight</h1>
          <div className="bg-white shadow-md rounded p-4">
            <form
              className=" flex flex-col gap-2"
              onSubmit={submitRequestFight}
            >
              <div>
                {/* challengerNftId */}
                <label
                  className="block text-gray-700 text-sm font-bold"
                  htmlFor="challengerNftId"
                >
                  Challenger Id
                </label>
                <select
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="challengerNftId"
                  name="challengerNftId"
                >
                  {yourFighters}
                </select>
              </div>
              <div>
                {/* minBet */}
                <label
                  className="block text-gray-700 text-sm font-bold"
                  htmlFor="minBet"
                >
                  Minimum Bet
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="minBet"
                  type="number"
                  placeholder="wei"
                />
              </div>
              <div>
                {/* acceptanceDeadline */}
                <label
                  className="block text-gray-700 text-sm font-bold"
                  htmlFor="acceptanceDeadline"
                >
                  Acceptance Deadline
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="acceptanceDeadline"
                  type="number"
                  placeholder="seconds"
                />
              </div>
              <div>
                {/* challengee */}
                <label
                  className="block text-gray-700 text-sm font-bold"
                  htmlFor="challengee"
                >
                  Challengee Address
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="challengee"
                  type="text"
                  placeholder="address"
                />
              </div>
              <div>
                {/* challengeeNftId */}
                <label
                  className="block text-gray-700 text-sm font-bold"
                  htmlFor="challengeeNftId"
                >
                  challengee Id
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="challengeeNftId"
                  type="number"
                  placeholder="NFT Id"
                />
              </div>
              <button
                className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
                type="submit"
              >
                Request Fight
              </button>
            </form>
          </div>
        </div>
        <div>
          {/* TODO: Fight ids requested to connected account and display as option list in Fight Id, */}
          <h1>Accept Fight Request</h1>
          <div className="bg-white shadow-md rounded p-4">
            <form
              className=" flex flex-col gap-2"
              onSubmit={submitAcceptFight}
            >
              <div>
                {/* fightId */}
                <label
                  className="block text-gray-700 text-sm font-bold"
                  htmlFor="fightId"
                >
                  Fight Id
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="fightId"
                  type="number"
                  placeholder="Fight Id"
                />
              </div>
              <div>
                {/* nftId */}
                <label
                  className="block text-gray-700 text-sm font-bold"
                  htmlFor="nftId"
                >
                  Challengee Id
                </label>
                <input
                  className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                  id="nftId"
                  type="number"
                  placeholder="NFT Id"
                />
              </div>
              <button
                className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
                type="submit"
              >
                Accept Fight
              </button>
            </form>
          </div>
        </div>
      </div>
    </>
  );
}
