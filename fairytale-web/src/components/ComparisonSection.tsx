const ROWS = [
  { label: "Writes a complete story", them: true, us: true },
  { label: "Illustrates every page", them: false, us: true },
  { label: "Reads the story aloud", them: false, us: true },
  { label: "Structured 10-page format", them: false, us: true },
  { label: "Downloadable PDF", them: false, us: true },
  { label: "Kid-friendly theme picker", them: false, us: true },
  { label: "Free, no account needed", them: false, us: true },
] as const;

export function ComparisonSection() {
  return (
    <section className="mx-auto max-w-3xl px-6 py-16">
      <p className="font-data text-center text-[11px] tracking-widest text-[var(--coral)] uppercase">The difference</p>
      <h2 className="font-display mt-2 text-center text-2xl font-bold text-white sm:text-3xl">
        Not just another <span className="text-gradient-warm">chat window</span>
      </h2>
      <p className="mx-auto mt-3 max-w-lg text-center text-[var(--muted)]">
        A general AI chatbot can write you a story. StoryBook AI builds the whole book.
      </p>

      <div className="mt-10 overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-lg">
        <div className="font-data grid grid-cols-[1fr_auto_auto] gap-4 border-b border-white/10 px-6 py-3 text-[11px] tracking-wide text-[var(--muted)] uppercase">
          <span />
          <span className="w-20 text-center">Generic chatbot</span>
          <span className="w-20 text-center text-[var(--gold)]">StoryBook AI</span>
        </div>
        {ROWS.map((row) => (
          <div key={row.label} className="grid grid-cols-[1fr_auto_auto] items-center gap-4 border-b border-white/5 px-6 py-4 last:border-0">
            <span className="text-sm text-white/90">{row.label}</span>
            <span className="w-20 text-center text-lg">{row.them ? "✅" : <span className="text-white/20">—</span>}</span>
            <span className="w-20 text-center text-lg">{row.us ? "✅" : <span className="text-white/20">—</span>}</span>
          </div>
        ))}
      </div>
    </section>
  );
}
