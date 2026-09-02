import Link from "next/link";
import Image from "next/image";
import type { Story } from "@/lib/types";
import { themeColor } from "@/lib/types";

export function StoryCard({ story }: { story: Story }) {
  const cover = story.pages.find((p) => p.imageUrl)?.imageUrl;
  const color = themeColor(story.theme);

  return (
    <Link
      href={`/story/${story.id}`}
      className="group relative block aspect-[3/4] overflow-hidden rounded-2xl border border-white/10 transition-all duration-300 hover:-translate-y-1 hover:shadow-[0_0_30px_-8px_var(--card-glow)]"
      style={{ "--card-glow": `${color}80` } as React.CSSProperties}
    >
      {cover ? (
        <Image
          src={cover}
          alt={story.title}
          fill
          unoptimized
          className="object-cover transition duration-300 group-hover:scale-105"
        />
      ) : (
        <div
          className="flex h-full w-full items-center justify-center text-5xl"
          style={{ background: `linear-gradient(160deg, ${color}33, ${color}66)` }}
        >
          📖
        </div>
      )}

      <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/85 via-black/40 to-transparent p-4 pt-12">
        <span
          className="inline-block rounded-full px-2.5 py-0.5 text-xs font-semibold text-white shadow-sm"
          style={{ backgroundColor: color }}
        >
          {story.theme}
        </span>
        <p className="font-display mt-2 text-lg font-bold leading-snug text-white line-clamp-3">{story.title}</p>
      </div>
    </Link>
  );
}
