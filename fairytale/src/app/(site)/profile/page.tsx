import { redirect } from "next/navigation";
import { me, myStories } from "@/lib/api";
import { getUserToken } from "@/lib/userAuth";
import { StoryCard } from "@/components/StoryCard";

export default async function ProfilePage() {
  const token = await getUserToken();
  if (!token) redirect("/login?next=/profile");

  let user;
  try {
    user = await me(token);
  } catch {
    redirect("/login?next=/profile");
  }
  const stories = await myStories(token, 50).catch(() => []);

  return (
    <div className="bg-void-texture min-h-screen">
      <div className="mx-auto max-w-6xl px-6 py-16">
        <p className="font-data text-[11px] tracking-widest text-[var(--muted)] uppercase">Your account</p>
        <h1 className="font-display mt-1 text-3xl font-bold text-white">{user.name}</h1>
        <p className="mt-1 text-[var(--muted)]">{user.email}</p>

        <div className="mt-10 flex items-center justify-between">
          <h2 className="font-display text-xl font-bold text-white">My Stories</h2>
          <span className="font-data text-xs tracking-wide text-[var(--muted)] uppercase">
            {stories.length} {stories.length === 1 ? "story" : "stories"}
          </span>
        </div>

        {stories.length === 0 ? (
          <div className="mt-6 rounded-2xl border border-dashed border-white/10 bg-white/5 p-12 text-center backdrop-blur-lg">
            <p className="text-[var(--muted)]">You haven&apos;t created any stories yet.</p>
            <a
              href="/generate"
              className="mt-4 inline-block rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] px-6 py-2 font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,200,87,0.4)]"
            >
              Create a story
            </a>
          </div>
        ) : (
          <div className="mt-6 columns-1 gap-6 sm:columns-2 lg:columns-4 [&>*]:mb-6 [&>*]:break-inside-avoid">
            {stories.map((story) => (
              <StoryCard key={story.id} story={story} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
