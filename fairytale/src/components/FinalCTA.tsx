import Link from "next/link";

export function FinalCTA() {
  return (
    <section className="mx-auto max-w-6xl px-6 pt-8 pb-20">
      <div className="bg-void-texture relative overflow-hidden rounded-3xl border border-white/10 px-6 py-16 text-center">
        <div className="pointer-events-none absolute top-1/2 left-1/2 h-72 w-72 -translate-x-1/2 -translate-y-1/2 rounded-full bg-[var(--gold)] opacity-10 blur-[100px]" />
        <div className="relative">
          <span className="text-4xl">✨</span>
          <h2 className="font-display mt-4 text-3xl font-bold text-white sm:text-4xl">
            Ready to write <span className="text-gradient-magic">tonight&apos;s story?</span>
          </h2>
          <p className="mx-auto mt-3 max-w-md text-[var(--muted)]">
            Free, illustrated, narrated, and yours in under a minute.
          </p>
          <Link
            href="/generate"
            className="mt-8 inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] px-8 py-3.5 font-display font-semibold text-[#1A1330] shadow-[0_0_30px_-5px_rgba(255,200,87,0.5)] transition-all duration-300 hover:scale-105 hover:shadow-[0_0_40px_-5px_rgba(255,200,87,0.7)]"
          >
            ✨ Create your story — it&apos;s free
          </Link>
        </div>
      </div>
    </section>
  );
}
