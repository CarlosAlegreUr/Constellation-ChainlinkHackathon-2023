import dynamic from "next/dynamic";
const MintFrom = dynamic(() => import("../components/MintForm"), {
  ssr: false,
});
const YourFighters = dynamic(() => import("../components/YourFighters"), {
  ssr: false,
});
import Boxer from "../../public/landing/Boxer.png";
import Image from "next/image";

export default function Create() {
  return (
    <main className=" relative flex flex-col items-center justify-between overflow-hidden ">
      <div className="absolute top-[41rem] left-[13rem] rotate-[20deg]">
        <Image
          src={Boxer}
          fil="false"
          width={200}
          alt="promp-fighters-logo"
          priority={"false"}
        />
      </div>
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
