"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { THEME_OPTIONS } from "@/lib/types";

const SUGGESTIONS = [
  "A curious fox who discovers a hidden garden",
  "Two rival dragons who team up to save their mountain",
  "A shy robot's first day at school",
];

export function HeroGenerator() {
  const router = useRouter();
  const [prompt, setPrompt] = useState("");
  const [theme, setTheme] = useState<string>(THEME_OPTIONS[0].name);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const params = new URLSearchParams({ theme });
    if (prompt.trim()) params.set("prompt", prompt.trim());
    router.push(`/generate?${params.toString()}`);
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="mx-auto max-w-2xl rounded-3xl border-2 border-white/10 bg-white/5 p-4 shadow-[0_0_50px_-10px_rgba(255,200,87,0.15)] backdrop-blur-lg transition-colors duration-300 focus-within:border-[var(--gold)]/50 focus-within:shadow-[0_0_40px_-5px_rgba(255,200,87,0.3)] sm:p-6"
    >
      <textarea
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        rows={2}
        placeholder="Write a story about a curious fox who finds a hidden garden..."
        className="w-full resize-none bg-transparent text-base text-white outline-none placeholder:text-[var(--muted)]"
      />
      <div className="mt-3 flex flex-wrap items-center justify-between gap-3 border-t border-white/10 pt-3">
        <div className="flex flex-wrap gap-1.5">
          {THEME_OPTIONS.map((t) => (
            <button
              type="button"
              key={t.name}
              onClick={() => setTheme(t.name)}
              className="rounded-full px-3 py-1 text-xs font-semibold transition"
              style={
                theme === t.name
                  ? { backgroundColor: t.color, color: "white" }
                  : { backgroundColor: `${t.color}22`, color: t.color }
              }
            >
              {t.name}
            </button>
          ))}
        </div>
        <button
          type="submit"
          className="flex shrink-0 items-center gap-1.5 rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] px-6 py-2.5 font-display font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,123,84,0.5)] transition-all duration-300 hover:scale-[1.03] hover:shadow-[0_0_30px_-5px_rgba(255,200,87,0.6)]"
        >
          ✨ Generate a story
        </button>
      </div>

      <div className="mt-4 flex flex-wrap items-center gap-2">
        <span className="font-data text-[11px] tracking-wide text-[var(--muted)] uppercase">Need inspiration?</span>
        {SUGGESTIONS.map((s) => (
          <button
            type="button"
            key={s}
            onClick={() => setPrompt(s)}
            className="rounded-full border border-white/10 px-3 py-1 text-xs text-white/80 transition hover:border-[var(--gold)]/40 hover:text-white"
          >
            {s}
          </button>
        ))}
      </div>
    </form>
  );
}
