"use client";
import React from "react";
import { useContractWrite } from "wagmi";
import SEPOLIA_PROMPT_FIGHTERS_NFT from "../constants";
import * as IPromptFightersCollection from "../contracts-artifacts/IPromptFightersCollection.sol/IPromptFightersCollection.json";
import { getAccount } from "@wagmi/core";

export default function SearchForBattle() {
  const account = getAccount();

  const { data, isLoading, isSuccess, write } = useContractWrite({
    address: SEPOLIA_PROMPT_FIGHTERS_NFT,
    abi: IPromptFightersCollection.abi,
    functionName: "safeMint",
  });

  async function handleSubmit(e) {
    e.preventDefault();

    const t = e.target;

    const prompt = [
      t[0].value,
      t[1].value,
      t[2].value,
      t[3].value,
      t[4].value,
    ].join("-");

    await write({ args: [account.address, prompt] });
  }

  return (
    <>
      <div className="h-[650px] w-1/2">
        <h1>Search Battle</h1>
        <div className="h-full bg-white shadow-md rounded px-8 pt-6 pb-8">
        <h1 className=" text-gray-700 text-l font-bold pt-8">Search Random Battle</h1>
          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label
                className="block text-gray-700 text-sm font-bold mb-2"
                htmlFor="name"
              >
                Name
              </label>
              <input
                className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                id="name"
                type="text"
                placeholder="Name"
              />
            </div>
          </form>

          <h1 className=" text-gray-700 text-l font-bold pt-8">Challenge a friend</h1>
          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label
                className="block text-gray-700 text-sm font-bold mb-2"
                htmlFor="name"
              >
                Name
              </label>
              <input
                className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
                id="name"
                type="text"
                placeholder="Name"
              />
            </div>
          </form>
        </div>
      </div>
    </>
  );
}
