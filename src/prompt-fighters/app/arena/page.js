import dynamic from "next/dynamic";
const SearchForFight = dynamic(() => import("../components/SearchForFight"), {
  ssr: false,
});
const FightsHistory = dynamic(() => import("../components/FightsHistory"), {
  ssr: false,
});
import Dino from "../../public/landing/Dino.png";
import Image from "next/image";

export default function Arena() {
  return (
    <main className=" relative flex flex-col items-center justify-between">
      <div className="absolute top-[44rem] right-[7rem] rotate-[20deg] z-40">
        <Image
          src={Dino}
          fil="false"
          width={150}
          alt="promp-fighters-logo"
          priority={"false"}
        />
      </div>
      <h1 className=" text-4xl">Arena</h1>
      <h2 className=" text-2xl pt-8">Fight against other fighters</h2>
      <div className=" h-[750px] w-full px-48 flex flex-row justify-between pt-8 gap-8">
        <SearchForFight />
        <FightsHistory />
      </div>
    </main>
  );
}
