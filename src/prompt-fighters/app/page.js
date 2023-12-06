import dynamic from "next/dynamic";
const LeaderBoard = dynamic(() => import("./components/LeaderBoard"), {
  ssr: false,
});

export default function Home() {
  return (
    <main className=" h-full flex flex-col items-center justify-between px-10">
      <h1 className=" text-4xl">Leaderboard</h1>
      <LeaderBoard />
    </main>
  );
}
