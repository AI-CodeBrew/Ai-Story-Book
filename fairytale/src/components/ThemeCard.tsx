export function ThemeCard({ name, description, color }: { name: string; description: string; color: string }) {
  return (
    <div
      className="group relative rounded-2xl border border-white/10 bg-[var(--surface)] p-5 transition-all duration-300 hover:-translate-y-1 hover:shadow-[0_0_30px_-10px_var(--card-glow)]"
      style={{ "--card-glow": color } as React.CSSProperties}
    >
      {/* corner accents, "selected node" style */}
      <div
        className="absolute top-0 left-0 h-4 w-4 rounded-tl-2xl border-t-2 border-l-2 opacity-0 transition-opacity duration-300 group-hover:opacity-100"
        style={{ borderColor: color }}
      />
      <div
        className="absolute right-0 bottom-0 h-4 w-4 rounded-br-2xl border-r-2 border-b-2 opacity-0 transition-opacity duration-300 group-hover:opacity-100"
        style={{ borderColor: color }}
      />
      <p className="font-display text-lg font-semibold" style={{ color }}>
        {name}
      </p>
      <p className="mt-1 text-sm text-[var(--muted)]">{description}</p>
    </div>
  );
}
