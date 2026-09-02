import Link from "next/link";

export function Navbar() {
  return (
    <header className="sticky top-0 z-40 border-b border-white/10 bg-[var(--void)]/80 backdrop-blur-lg">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/" className="font-display flex items-center gap-2 text-xl font-bold text-white">
          <span className="text-gradient-magic">✨ StoryBook AI</span>
        </Link>
        <nav className="flex items-center gap-6 text-sm font-medium text-[var(--muted)]">
          <Link href="/stories" className="font-data tracking-wide transition hover:text-[var(--gold)]">
            LIBRARY
          </Link>
          <Link
            href="/generate"
            className="rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] px-5 py-2 font-display font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,123,84,0.5)] transition-all duration-300 hover:scale-105 hover:shadow-[0_0_30px_-5px_rgba(255,200,87,0.6)]"
          >
            Create a Story
          </Link>
        </nav>
      </div>
    </header>
  );
}
