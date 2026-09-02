const REASONS = [
  {
    icon: "🛡️",
    title: "Family-friendly by design",
    body: "Prompts and themes are built around gentle, age-appropriate storytelling — adventure, friendship, and learning, not violence.",
    color: "var(--success)",
  },
  {
    icon: "💸",
    title: "Completely free",
    body: "No subscription, no paywall, no sign-up wall. Generate as many stories as you like.",
    color: "var(--gold)",
  },
  {
    icon: "⚡",
    title: "Made in under a minute",
    body: "A full 10-page illustrated storybook, written and painted, ready before bedtime.",
    color: "var(--coral)",
  },
  {
    icon: "📚",
    title: "Yours to keep",
    body: "Download it as a PDF, share the link, or come back and read it again anytime from the library.",
    color: "var(--violet)",
  },
] as const;

export function WhyChooseSection() {
  return (
    <section className="mx-auto max-w-6xl px-6 py-16">
      <p className="font-data text-center text-[11px] tracking-widest text-[var(--gold)] uppercase">Built for families</p>
      <h2 className="font-display mt-2 text-center text-2xl font-bold text-white sm:text-3xl">Why parents & teachers choose us</h2>

      <div className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2">
        {REASONS.map((r) => (
          <div
            key={r.title}
            className="flex gap-4 rounded-2xl border border-white/10 bg-white/5 p-6 backdrop-blur-lg transition-all duration-300 hover:border-[var(--gold)]/30"
          >
            <div
              className="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg border text-xl"
              style={{ backgroundColor: `${r.color}22`, borderColor: `${r.color}55` }}
            >
              {r.icon}
            </div>
            <div>
              <p className="font-display font-bold text-white">{r.title}</p>
              <p className="mt-1 text-sm text-[var(--muted)]">{r.body}</p>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
