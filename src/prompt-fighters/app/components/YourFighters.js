"use client";
import React from "react";
import { useAccount } from "wagmi";

export default function YourFighters() {
  const { isConnected } = useAccount();

  return (
    <div className="w-full">
      <h1>YourFighters</h1>
      <div className=" h-full bg-white shadow-md rounded px-8 pt-6">


      </div>
    </div>
  );
}
