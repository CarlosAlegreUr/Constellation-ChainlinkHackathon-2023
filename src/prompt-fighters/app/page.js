import dynamic from "next/dynamic";
const LeaderBoard = dynamic(
  () => import("./components/LeaderBoard"),
  { ssr: false }
);

export default function Home() {
  return (
    <main className="flex flex-col items-center justify-between">
    <h1 className=" text-4xl">Leaderboard</h1>
    <div className=" h-full w-full px-48 flex flex-row justify-between pt-8 gap-8">
      <LeaderBoard />
    </div>
  </main>
  );
}
