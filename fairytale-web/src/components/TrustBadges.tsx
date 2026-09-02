const BADGES = [
  { icon: "✅", label: "100% Free", sub: "No sign-up required", color: "var(--success)" },
  { icon: "🎨", label: "Illustrated", sub: "A picture for every page", color: "var(--gold)" },
  { icon: "🔊", label: "Read Aloud", sub: "Narration in your browser", color: "var(--violet)" },
  { icon: "👶", label: "Family-Friendly", sub: "Designed for kids", color: "var(--coral)" },
] as const;

export function TrustBadges() {
  return (
    <div className="mx-auto grid max-w-3xl grid-cols-2 gap-6 rounded-3xl border border-white/10 bg-white/5 p-6 shadow-[0_0_50px_-10px_rgba(255,200,87,0.1)] backdrop-blur-lg sm:grid-cols-4 sm:p-8">
      {BADGES.map((b) => (
        <div key={b.label} className="text-center">
          <div
            className="mx-auto flex h-12 w-12 items-center justify-center rounded-lg border text-xl"
            style={{ backgroundColor: `${b.color}22`, borderColor: `${b.color}55` }}
          >
            {b.icon}
          </div>
          <p className="font-display mt-2 text-sm font-bold text-white">{b.label}</p>
          <p className="font-data mt-0.5 text-[11px] tracking-wide text-[var(--muted)] uppercase">{b.sub}</p>
        </div>
      ))}
    </div>
  );
}
