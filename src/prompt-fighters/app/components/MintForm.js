"use client";
import React from "react";
import { getContract } from '@wagmi/core'
import SEPOLIA_PROMPT_FIGHTERS_NFT from "../constants"


export default function MintForm() {
  const contract = getContract({
    address: '0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e',
    abi: ensRegistryABI,
  })
  
  async function handleSubmit(e) {
    e.preventDefault();

    // build string
    console.log(SEPOLIA_PROMPT_FIGHTERS_NFT);

    // connec
  }

  return (
    <>
      <div className=" w-3/6">
        <h1>Create a New Fighter</h1>
        <form
          className="h-full bg-white shadow-md rounded px-8 pt-6 pb-8"
          onSubmit={handleSubmit}
        >
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
          <div className="mb-6">
            <label
              className="block text-gray-700 text-sm font-bold mb-2"
              htmlFor="race"
            >
              Race
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="race"
              type="text"
              placeholder="Race"
            />
          </div>
          <div className="mb-6">
            <label
              className="block text-gray-700 text-sm font-bold mb-2"
              htmlFor="weapon"
            >
              Weapon
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="weapon"
              type="text"
              placeholder="Weapon"
            />
          </div>
          <div className="mb-6">
            <label
              className="block text-gray-700 text-sm font-bold mb-2"
              htmlFor="special-skill"
            >
              Special Skill
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="special-skill"
              type="text"
              placeholder="Special Skill"
            />
          </div>
          <div className="mb-6">
            <label
              className="block text-gray-700 text-sm font-bold mb-2"
              htmlFor="fear"
            >
              Fear
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="fear"
              type="text"
              placeholder="Fear"
            />
          </div>

          <div className="flex items-center justify-center">
            <button
              className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline"
              type="submit"
            >
              Mint
            </button>
          </div>
        </form>
      </div>
    </>
  );
}
