

import dynamic from "next/dynamic";
const MintFrom = dynamic(
  () => import("../components/MintForm"),
  { ssr: false }
);
const YourFighters = dynamic(
  () => import("../components/YourFighters"),
  { ssr: false }
);

export default function Create() {
  return (
    <main className="flex flex-col items-center justify-between">
      <h1 className=" text-4xl">Create Your Fighter</h1>
      <h2 className=" text-2xl pt-8">
        Fighters are customized NFTs stored on-chain
      </h2>
      <div className=" h-[750px] px-48 w-full flex flex-row justify-between pt-16 gap-8">
        <MintFrom />
        <YourFighters />
      </div>
    </main>
  );
}
