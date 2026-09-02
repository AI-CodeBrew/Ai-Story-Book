"use client";

import { useEffect, useRef, useState } from "react";

const SAMPLE_TEXT =
  "Deep in the Whispering Woods, a tiny fox named Ember found a door glowing beneath an old oak tree. \"I wonder where this leads,\" she whispered, and pushed it open.";

export function AudioDemo() {
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  // Defaults to true so server and client render the same markup on mount
  // (speechSynthesis doesn't exist during SSR); corrected right after mount,
  // matching the same pattern used by NarrationControls on the story page.
  const [supported, setSupported] = useState(true);
  const frameRef = useRef<number | null>(null);
  const startRef = useRef<number>(0);

  useEffect(() => {
    setSupported(typeof window !== "undefined" && "speechSynthesis" in window);
    return () => {
      window.speechSynthesis?.cancel();
      if (frameRef.current) cancelAnimationFrame(frameRef.current);
    };
  }, []);

  function tick() {
    const elapsed = Date.now() - startRef.current;
    const estimatedMs = (SAMPLE_TEXT.length / 14) * 1000; // rough speaking-rate estimate
    const pct = Math.min(100, (elapsed / estimatedMs) * 100);
    setProgress(pct);
    if (pct < 100) frameRef.current = requestAnimationFrame(tick);
  }

  function toggle() {
    if (!supported) return;
    if (playing) {
      window.speechSynthesis.cancel();
      setPlaying(false);
      if (frameRef.current) cancelAnimationFrame(frameRef.current);
      return;
    }
    const utterance = new SpeechSynthesisUtterance(SAMPLE_TEXT);
    utterance.lang = "en-US";
    utterance.rate = 0.9;
    utterance.onend = () => {
      setPlaying(false);
      setProgress(0);
      if (frameRef.current) cancelAnimationFrame(frameRef.current);
    };
    window.speechSynthesis.speak(utterance);
    startRef.current = Date.now();
    setProgress(0);
    setPlaying(true);
    frameRef.current = requestAnimationFrame(tick);
  }

  return (
    <div className="mx-auto max-w-2xl rounded-3xl border border-white/10 bg-white/5 p-6 shadow-[0_0_50px_-15px_rgba(201,166,255,0.2)] backdrop-blur-lg sm:p-8">
      <div className="flex items-center gap-2">
        <span className="text-lg">🎧</span>
        <p className="font-display font-bold text-white">Hear a story come to life</p>
      </div>
      <p className="mt-1 text-sm text-[var(--muted)]">Every storybook is narrated aloud, right in your browser.</p>

      <div className="mt-5 flex items-center gap-4">
        <button
          onClick={toggle}
          disabled={!supported}
          aria-label={playing ? "Stop sample narration" : "Play sample narration"}
          className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-[var(--violet)] to-[var(--coral)] text-lg text-[#1A1330] shadow-[0_0_20px_-5px_rgba(201,166,255,0.6)] transition-transform duration-300 hover:scale-105 disabled:opacity-40"
        >
          {playing ? "⏸" : "▶"}
        </button>
        <div className="flex-1">
          <p className="text-sm text-white/80 italic">&ldquo;{SAMPLE_TEXT}&rdquo;</p>
          <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-white/10">
            <div
              className="h-full rounded-full bg-gradient-to-r from-[var(--violet)] to-[var(--coral)] transition-[width] duration-150"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      </div>
      {!supported && <p className="mt-3 text-xs text-[var(--muted)]">Narration preview isn&apos;t supported in this browser.</p>}
    </div>
  );
}
