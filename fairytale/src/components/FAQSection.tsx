"use client";

import { useState } from "react";

const FAQS = [
  {
    q: "Is StoryBook AI really free?",
    a: "Yes — generating, reading, narrating, and downloading a story as a PDF are all free, with no account or sign-up required.",
  },
  {
    q: "Is it safe for my child to use?",
    a: "Story themes and prompts are steered toward gentle, age-appropriate content — adventure, friendship, nature, and learning. We'd still recommend reading along together, since content is AI-generated.",
  },
  {
    q: "Can I download or print the story?",
    a: "Yes. Every story has a \"Download PDF\" button on its page that exports the full illustrated storybook, ready to print or save.",
  },
  {
    q: "How long does it take to generate a story?",
    a: "Usually under a minute — the AI writes all 10 pages first, then paints an illustration for each one.",
  },
  {
    q: "Can I share a story with family or friends?",
    a: "Yes — every story gets its own link. Anyone with the link can read it, no sign-up needed on their end either.",
  },
] as const;

export function FAQSection() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section className="mx-auto max-w-2xl px-6 py-16">
      <p className="font-data text-center text-[11px] tracking-widest text-[var(--gold)] uppercase">Questions</p>
      <h2 className="font-display mt-2 text-center text-2xl font-bold text-white sm:text-3xl">Frequently asked questions</h2>

      <div className="mt-10 space-y-3">
        {FAQS.map((item, i) => {
          const isOpen = open === i;
          return (
            <div
              key={item.q}
              className="overflow-hidden rounded-2xl border border-white/10 bg-white/5 backdrop-blur-lg transition-colors duration-300"
              style={isOpen ? { borderColor: "rgba(255,200,87,0.4)" } : undefined}
            >
              <button
                onClick={() => setOpen(isOpen ? null : i)}
                className="flex w-full items-center justify-between gap-4 px-6 py-4 text-left"
                aria-expanded={isOpen}
              >
                <span className="font-display font-semibold text-white">{item.q}</span>
                <span
                  className="font-data shrink-0 text-lg text-[var(--gold)] transition-transform duration-300"
                  style={{ transform: isOpen ? "rotate(45deg)" : "rotate(0deg)" }}
                >
                  +
                </span>
              </button>
              {isOpen && <p className="px-6 pb-4 text-sm text-[var(--muted)]">{item.a}</p>}
            </div>
          );
        })}
      </div>
    </section>
  );
}
