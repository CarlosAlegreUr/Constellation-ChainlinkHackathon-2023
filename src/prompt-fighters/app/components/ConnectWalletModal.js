"use client";
import React from "react";
import Image from "next/image";
import logo from "../../public/landing/Logo.png";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount } from "wagmi";

export default function ConnectWalletModal() {
  const { isConnected } = useAccount();

  return (
    <>
      {!isConnected && (
        <div className="absolute">
          <div className="absolute w-screen h-screen z-20 bg-pf-blue opacity-60" />
          <div className="absolute w-screen h-screen z-30">
            <div className="absolute h-screen w-screen flex items-center flex-col justify-center">
              <div className="flex flex-col items-center ">
                <Image src={logo} fil="false" alt="promp-fighters-logo" priority={"false"}/>
                <h1 className=" mt-12 text-4xl font-medium">
                  Welcome to the Battlefield
                </h1>
                <h3 className=" mt-12 text-xl font-light">
                  Connect your wallet to start{" "}
                </h3>
                <div className=" mt-12">
                  <ConnectButton />
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
