import dynamic from "next/dynamic";
const LeaderBoard = dynamic(() => import("./components/LeaderBoard"), {
  ssr: false,
});
import Cloud from "../public/landing/Cloud.png";
import Image from "next/image";
export default function Home() {
  return (
    <main className=" h-full flex flex-col items-center justify-between px-28">
      <div className="absolute top-[4rem] left-[4rem] rotate-[-2deg]">
        <Image
          src={Cloud}
          fil="false"
          width={120}
          alt="promp-fighters-logo"
          priority={"false"}
        />
      </div>
      <h1 className=" text-4xl">Leaderboard</h1>
      <LeaderBoard />
    </main>
  );
}
