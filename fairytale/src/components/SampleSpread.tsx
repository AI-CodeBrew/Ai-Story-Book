import Image from "next/image";
import Link from "next/link";
import type { Story } from "@/lib/types";

export function SampleSpread({ story }: { story: Story | null }) {
  const page = story?.pages.find((p) => p.imageUrl);

  return (
    <section className="mx-auto max-w-6xl px-6 py-16">
      <div className="grid grid-cols-1 items-center gap-10 lg:grid-cols-2">
        <div>
          <p className="font-data text-[11px] tracking-widest text-[var(--violet)] uppercase">Real output, not a mockup</p>
          <h2 className="font-display mt-2 text-2xl font-bold text-white sm:text-3xl">
            Every page, <span className="text-gradient-magic">fully illustrated</span>
          </h2>
          <p className="mt-4 max-w-md text-[var(--muted)]">
            This is an actual page from a story generated on StoryBook AI — not a stock photo. Your storybook gets
            the same treatment: a unique illustration painted for every single page, matched to what&apos;s
            happening in the scene.
          </p>
          <Link
            href="/generate"
            className="mt-6 inline-flex items-center gap-1.5 rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] px-6 py-2.5 font-display font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,200,87,0.4)] transition-all duration-300 hover:scale-105"
          >
            ✨ Make your own
          </Link>
        </div>

        <div className="relative mx-auto aspect-[4/3] w-full max-w-md overflow-hidden rounded-3xl border border-white/10 bg-[var(--surface)] shadow-[0_0_60px_-15px_rgba(255,200,87,0.2)]">
          {page?.imageUrl ? (
            <>
              <Image src={page.imageUrl} alt="Sample illustrated storybook page" fill unoptimized className="object-cover" />
              <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/85 to-transparent p-5">
                <p className="line-clamp-2 text-sm text-white/90">{page.script}</p>
              </div>
            </>
          ) : (
            <div className="flex h-full w-full flex-col items-center justify-center gap-2 bg-gradient-to-br from-[var(--gold)]/20 to-[var(--violet)]/20 text-center">
              <span className="text-5xl">📖✨</span>
              <p className="px-8 text-sm text-[var(--muted)]">Your first illustrated page will appear here once you create a story.</p>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
