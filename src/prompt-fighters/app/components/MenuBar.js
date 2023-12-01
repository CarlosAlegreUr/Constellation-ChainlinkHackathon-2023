"use client";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import Link from "next/link";
import { useAccount } from "wagmi";

export default function MenuBar() {
  const { isConnected } = useAccount();

  return (
    <>
      {isConnected && (
        <>
          <div className="flex flex-no-shrink items-stretch h-12">
            <Link
              href="/"
              className="flex-no-grow flex-no-shrink relative py-2 px-4 leading-normal text-white no-underline flex items-center hover:bg-grey-dark"
            >
              Home
            </Link>
            <Link
              href="/create"
              className="flex-no-grow flex-no-shrink relative py-2 px-4 leading-normal text-white no-underline flex items-center hover:bg-grey-dark"
            >
              Create a Fighter
            </Link>
            <Link
              href="/arena"
              className="flex-no-grow flex-no-shrink relative py-2 px-4 leading-normal text-white no-underline flex items-center hover:bg-grey-dark"
            >
              Arena
            </Link>
          </div>
          <div className="lg:flex lg:items-stretch lg:flex-no-shrink lg:flex-grow">
            <div className="lg:flex lg:items-stretch lg:justify-end ml-auto">
              <ConnectButton />
            </div>
          </div>
        </>
      )}
    </>
  );
}
