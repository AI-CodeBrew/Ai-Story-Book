const FEATURES = [
  {
    icon: "✍️",
    title: "AI story writing",
    body: "Gemini writes a complete 10-page story from just a sentence — with a beginning, middle, and a satisfying end.",
    color: "var(--gold)",
  },
  {
    icon: "🎨",
    title: "AI illustrations",
    body: "Every single page gets its own hand-painted-style illustration, generated to match the scene.",
    color: "var(--coral)",
  },
  {
    icon: "🔊",
    title: "Read-aloud narration",
    body: "Tap play and your browser reads the story aloud, page by page — no download required.",
    color: "var(--violet)",
  },
  {
    icon: "📄",
    title: "Downloadable PDF",
    body: "Export the finished storybook as a print-ready PDF, images and all, to keep or share offline.",
    color: "var(--gold)",
  },
  {
    icon: "🔗",
    title: "One-tap sharing",
    body: "Every story gets its own link — share it with family instantly, no login required to read it.",
    color: "var(--coral)",
  },
  {
    icon: "🗂️",
    title: "Curated story library",
    body: "Browse stories by theme, or get inspired by what other families have created.",
    color: "var(--violet)",
  },
] as const;

export function FeaturesSection() {
  return (
    <section className="mx-auto max-w-6xl px-6 py-16">
      <p className="font-data text-center text-[11px] tracking-widest text-[var(--gold)] uppercase">Everything included</p>
      <h2 className="font-display mt-2 text-center text-2xl font-bold text-white sm:text-3xl">
        One free tool, <span className="text-gradient-warm">a complete storybook</span>
      </h2>

      <div className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {FEATURES.map((f) => (
          <div
            key={f.title}
            className="group relative overflow-hidden rounded-2xl border border-white/10 bg-[var(--surface)] p-8 transition-all duration-300 hover:-translate-y-1 hover:border-[var(--gold)]/40 hover:shadow-[0_0_30px_-10px_var(--card-glow)]"
            style={{ "--card-glow": `${f.color}33` } as React.CSSProperties}
          >
            <span
              aria-hidden
              className="pointer-events-none absolute -top-4 -right-4 text-8xl opacity-[0.06] transition-opacity duration-300 group-hover:opacity-20"
            >
              {f.icon}
            </span>
            <div
              className="relative flex h-12 w-12 items-center justify-center rounded-lg border text-2xl"
              style={{ backgroundColor: `${f.color}1F`, borderColor: `${f.color}55` }}
            >
              {f.icon}
            </div>
            <p className="font-display relative mt-4 text-lg font-bold text-white">{f.title}</p>
            <p className="relative mt-2 text-sm text-[var(--muted)]">{f.body}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
