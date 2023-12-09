"use client";
import React from "react";
import Image from "next/image";
import logo from "../../public/landing/Logo.png";
import PromptBubble from "../../public/landing/Prompt_bubble.png";
import Fire1 from "../../public/landing/Fire_1.png";
import Fire2 from "../../public/landing/Fire_2.png";
import Fire3 from "../../public/landing/Fire_3.png";

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
            <div className="absolute top-[8rem] left-[77rem]">
              <Image
                src={PromptBubble}
                fil="false"
                alt="promp-fighters-logo"
                priority={"false"}
              />
            </div>
            <div className="absolute top-[35rem] left-[35rem] rotate-[-20deg]">
              <Image
                src={Fire1}
                fil="false"
                alt="promp-fighters-logo"
                priority={"false"}
              />
            </div>
            <div className="absolute top-[35rem] left-[80rem] rotate-[20deg]">
              <Image
                src={Fire2}
                fil="false"
                alt="promp-fighters-logo"
                priority={"false"}
              />
            </div>
            <div className="absolute top-[9rem] left-[38rem] rotate-[-20deg]">
              <Image
                src={Fire3}
                fil="false"
                alt="promp-fighters-logo"
                priority={"false"}
              />
            </div>
            <div className="absolute h-screen w-screen flex items-center flex-col justify-center">
              <div className="flex flex-col items-center ">
                <Image
                  src={logo}
                  fil="false"
                  alt="promp-fighters-logo"
                  priority={"false"}
                />
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
