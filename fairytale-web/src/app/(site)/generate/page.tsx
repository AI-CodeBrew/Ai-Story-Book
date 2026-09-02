"use client";

import { Suspense, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { generatePageImage, generateStory, recordVisit, saveStory } from "@/lib/api";
import { THEME_OPTIONS } from "@/lib/types";
import { useVisitorId } from "@/hooks/useVisitorId";

const THEME_STYLES: Record<string, string> = {
  Adventure: "adventure, action, exploration",
  Fantasy: "fantasy, magical, mystical",
  Space: "sci-fi, futuristic, space",
  Nature: "nature, peaceful, beautiful",
  Friendship: "warm, friendly, heartwarming",
  Science: "educational, scientific, colorful",
};

const SUGGESTIONS = [
  "A curious fox who discovers a hidden garden behind the old oak tree",
  "Two rival dragons who must team up to save their mountain",
  "A shy robot who wants to make friends on the first day of school",
  "A little astronaut who gets lost on the way home from the moon",
];

function buildImagePrompt(scene: string, theme: string): string {
  const style = THEME_STYLES[theme] ?? "beautiful, colorful";
  return `Create a beautiful, detailed illustration for a children's story:\nScene: ${scene}\nStyle: ${style}, child-friendly, vibrant colors, detailed but simple\nFormat: High-quality digital art suitable for a storybook.`;
}

function GenerateForm() {
  const router = useRouter();
  const visitorId = useVisitorId();
  const searchParams = useSearchParams();

  const [prompt, setPrompt] = useState(searchParams.get("prompt") ?? "");
  const [theme, setTheme] = useState<string>(searchParams.get("theme") ?? THEME_OPTIONS[0].name);
  const [additionalContext, setAdditionalContext] = useState("");
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!prompt.trim()) {
      setError("Tell us what your story should be about.");
      return;
    }
    setError(null);
    setLoading(true);

    try {
      setStatus("Writing your 10-page story...");
      const story = await generateStory({ prompt, theme, additionalContext: additionalContext || undefined });

      setStatus("Painting the illustrations...");
      const images = await Promise.all(
        story.pages.map((page) => generatePageImage(buildImagePrompt(page.script, theme)))
      );
      story.pages = story.pages.map((page, i) => ({ ...page, imageUrl: images[i] ?? page.imageUrl }));

      setStatus("Saving your storybook...");
      const saved = await saveStory({ ...story, prompt, additionalContext }, visitorId ?? "anonymous");

      if (visitorId) recordVisit(visitorId, "/generate", "story_generated");

      router.push(`/story/${saved.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong generating your story.");
      setLoading(false);
    }
  }

  return (
    <div className="bg-void-texture min-h-screen">
      <div className="mx-auto max-w-2xl px-6 py-16">
        <h1 className="font-display text-center text-3xl font-bold text-white sm:text-4xl">Create your storybook</h1>
        <p className="mt-2 text-center text-[var(--muted)]">
          Describe an idea, pick a theme, and we&apos;ll write and illustrate a full 10-page story.
        </p>

        <form
          onSubmit={handleSubmit}
          className="mt-8 space-y-6 rounded-3xl border-2 border-white/10 bg-white/5 p-6 shadow-[0_0_50px_-10px_rgba(255,200,87,0.15)] backdrop-blur-lg transition-colors duration-300 focus-within:border-[var(--gold)]/40 sm:p-8"
        >
          <div>
            <label className="font-display text-sm font-semibold text-white">What&apos;s your story about?</label>
            <textarea
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              rows={3}
              placeholder="A curious fox who discovers a hidden garden behind the old oak tree"
              className="mt-2 w-full resize-none rounded-xl border border-white/10 bg-black/30 p-3 text-sm text-white outline-none placeholder:text-[var(--muted)] focus:border-[var(--gold)] focus:shadow-[0_0_20px_-8px_rgba(255,200,87,0.5)]"
              disabled={loading}
            />
            <div className="mt-3 flex flex-wrap gap-2">
              <span className="font-data text-[11px] tracking-wide text-[var(--muted)] uppercase">Need inspiration?</span>
              {SUGGESTIONS.map((s) => (
                <button
                  type="button"
                  key={s}
                  onClick={() => setPrompt(s)}
                  disabled={loading}
                  className="rounded-full border border-white/10 px-3 py-1 text-xs text-white/80 transition hover:border-[var(--gold)]/40 hover:text-white"
                >
                  {s.length > 42 ? s.slice(0, 42) + "…" : s}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="font-display text-sm font-semibold text-white">Theme</label>
            <div className="mt-2 grid grid-cols-2 gap-2 sm:grid-cols-3">
              {THEME_OPTIONS.map((t) => (
                <button
                  type="button"
                  key={t.name}
                  onClick={() => setTheme(t.name)}
                  disabled={loading}
                  className="rounded-xl border px-3 py-2 text-sm font-semibold transition"
                  style={
                    theme === t.name
                      ? { backgroundColor: t.color, borderColor: t.color, color: "white" }
                      : { backgroundColor: `${t.color}18`, borderColor: `${t.color}40`, color: t.color }
                  }
                >
                  {t.name}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="font-display text-sm font-semibold text-white">Extra details (optional)</label>
            <input
              value={additionalContext}
              onChange={(e) => setAdditionalContext(e.target.value)}
              placeholder="Character names, a lesson to teach, a favorite animal..."
              className="mt-2 h-12 w-full border-b-2 border-white/20 bg-black/30 px-4 text-sm text-white outline-none placeholder:text-white/30 focus:border-[var(--gold)] focus:shadow-[0_10px_20px_-10px_rgba(255,200,87,0.3)]"
              disabled={loading}
            />
          </div>

          {error && <p className="text-sm font-medium text-[var(--error)]">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="flex w-full items-center justify-center gap-2 rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] py-3.5 font-display font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,123,84,0.5)] transition-all duration-300 hover:scale-[1.01] hover:shadow-[0_0_30px_-5px_rgba(255,200,87,0.6)] disabled:opacity-60 disabled:hover:scale-100"
          >
            {loading ? status || "Generating..." : <>✨ Generate my story</>}
          </button>
          {loading && (
            <p className="text-center text-xs text-[var(--muted)]">
              This can take up to a minute — 10 pages of art take a moment to paint.
            </p>
          )}
        </form>
      </div>
    </div>
  );
}

export default function GeneratePage() {
  return (
    <Suspense>
      <GenerateForm />
    </Suspense>
  );
}
