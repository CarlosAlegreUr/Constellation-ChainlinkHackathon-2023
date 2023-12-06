import dynamic from "next/dynamic";
const SearchForBattle = dynamic(
  () => import("../components/SearchForBattle"),
  { ssr: false }
);
const BattlesHistory = dynamic(
  () => import("../components/BattlesHistory"),
  { ssr: false }
);

export default function Arena() {
  return (
    <main className="flex flex-col items-center justify-between">
      <h1 className=" text-4xl">Arena</h1>
      <h2 className=" text-2xl pt-8">
       Fight against other fighters
      </h2>
      <div className=" h-[750px] w-full px-48 flex flex-row justify-between pt-8 gap-8">
        <SearchForBattle />
        <BattlesHistory />
      </div>
    </main>
  );
}
