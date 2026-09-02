"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Image from "next/image";
import type { FeedbackOptions, Story } from "@/lib/types";
import { themeColor } from "@/lib/types";
import { getFeedbackOptions, recordVisit, submitFeedback } from "@/lib/api";
import { useVisitorId } from "@/hooks/useVisitorId";

export function StoryViewerClient({ story }: { story: Story }) {
  const [pageIndex, setPageIndex] = useState(0);
  const visitorId = useVisitorId();
  const color = themeColor(story.theme);

  const page = story.pages[pageIndex];
  const isFirst = pageIndex === 0;
  const isLast = pageIndex === story.pages.length - 1;

  return (
    <div className="bg-void-texture min-h-screen">
      <div className="mx-auto max-w-3xl px-6 py-12">
        <div className="text-center">
          <span
            className="inline-block rounded-full px-3 py-1 text-xs font-semibold text-white shadow-[0_0_15px_-3px_rgba(0,0,0,0.4)]"
            style={{ backgroundColor: color }}
          >
            {story.theme}
          </span>
          <h1 className="font-display mt-3 text-3xl font-bold text-white">{story.title}</h1>
        </div>

        <div className="mt-8 overflow-hidden rounded-3xl border border-white/10 bg-white/5 shadow-[0_0_50px_-15px_rgba(255,200,87,0.15)] backdrop-blur-lg">
          <div className="relative aspect-[4/3] w-full bg-[var(--surface)]">
            {page.imageUrl ? (
              <Image src={page.imageUrl} alt={`Page ${page.pageNumber}`} fill unoptimized className="object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center text-5xl">📖</div>
            )}
          </div>
          <div className="p-6">
            <p className="text-lg leading-relaxed text-white/90">{page.script}</p>
          </div>
        </div>

        <div className="mt-4 flex items-center justify-between">
          <button
            onClick={() => setPageIndex((i) => Math.max(0, i - 1))}
            disabled={isFirst}
            className="rounded-full border border-white/10 bg-[var(--surface)] px-5 py-2 text-sm font-semibold text-white transition hover:border-[var(--gold)]/40 disabled:opacity-30"
          >
            ← Previous
          </button>
          <span className="font-data text-xs tracking-wide text-[var(--muted)] uppercase">
            Page {pageIndex + 1} / {story.pages.length}
          </span>
          <button
            onClick={() => setPageIndex((i) => Math.min(story.pages.length - 1, i + 1))}
            disabled={isLast}
            className="rounded-full border border-white/10 bg-[var(--surface)] px-5 py-2 text-sm font-semibold text-white transition hover:border-[var(--gold)]/40 disabled:opacity-30"
          >
            Next →
          </button>
        </div>

        <NarrationControls text={page.script} />

        <div className="mt-6 flex flex-wrap gap-3">
          <PdfExportButton story={story} visitorId={visitorId} />
          <ShareButton story={story} visitorId={visitorId} />
        </div>

        {isLast && <FeedbackForm storyId={story.id} visitorId={visitorId} />}
      </div>
    </div>
  );
}

function NarrationControls({ text }: { text: string }) {
  const [speaking, setSpeaking] = useState(false);
  const utteranceRef = useRef<SpeechSynthesisUtterance | null>(null);
  const [supported, setSupported] = useState(true);

  useEffect(() => {
    setSupported(typeof window !== "undefined" && "speechSynthesis" in window);
    return () => {
      window.speechSynthesis?.cancel();
    };
  }, []);

  useEffect(() => {
    // Stop narration whenever the page's text changes (i.e. the user navigated).
    window.speechSynthesis?.cancel();
    setSpeaking(false);
  }, [text]);

  function toggle() {
    if (!supported) return;
    if (speaking) {
      window.speechSynthesis.cancel();
      setSpeaking(false);
      return;
    }
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = "en-US";
    utterance.rate = 0.9;
    utterance.pitch = 1;
    utterance.onend = () => setSpeaking(false);
    utteranceRef.current = utterance;
    window.speechSynthesis.speak(utterance);
    setSpeaking(true);
  }

  if (!supported) return null;

  return (
    <div className="mt-4 flex justify-center">
      <button
        onClick={toggle}
        className="flex items-center gap-2 rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] px-5 py-2 text-sm font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,200,87,0.5)] transition-all duration-300 hover:scale-105"
      >
        {speaking ? "⏸ Stop narration" : "🔊 Read this page aloud"}
      </button>
    </div>
  );
}

async function toEmbeddableImage(imageUrl: string): Promise<string | null> {
  if (imageUrl.startsWith("data:image")) return imageUrl;
  try {
    const res = await fetch(imageUrl);
    if (!res.ok) return null;
    const blob = await res.blob();
    return await new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  } catch {
    // CORS or network failure fetching a remote (e.g. CDN) image — skip it
    return null;
  }
}

function PdfExportButton({ story, visitorId }: { story: Story; visitorId: string | null }) {
  const [exporting, setExporting] = useState(false);

  async function handleExport() {
    setExporting(true);
    try {
      const { jsPDF } = await import("jspdf");
      const doc = new jsPDF({ unit: "pt", format: "a4" });
      const pageWidth = doc.internal.pageSize.getWidth();
      const margin = 40;

      doc.setFontSize(24);
      doc.text(story.title, pageWidth / 2, 100, { align: "center" });
      doc.setFontSize(12);
      doc.text(story.theme, pageWidth / 2, 130, { align: "center" });

      for (const page of story.pages) {
        doc.addPage();
        let cursorY = margin + 20;
        const embeddable = page.imageUrl ? await toEmbeddableImage(page.imageUrl) : null;
        if (embeddable) {
          const imgWidth = pageWidth - margin * 2;
          const imgHeight = imgWidth * 0.75;
          try {
            doc.addImage(embeddable, "JPEG", margin, cursorY, imgWidth, imgHeight);
            cursorY += imgHeight + 24;
          } catch {
            // if the image can't be embedded, fall back to text-only page
          }
        }
        doc.setFontSize(13);
        const lines = doc.splitTextToSize(page.script, pageWidth - margin * 2);
        doc.text(lines, margin, cursorY);
      }

      doc.save(`${story.title.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}.pdf`);
      if (visitorId) recordVisit(visitorId, `/story/${story.id}`, "pdf_export");
    } finally {
      setExporting(false);
    }
  }

  return (
    <button
      onClick={handleExport}
      disabled={exporting}
      className="rounded-full border border-white/10 bg-[var(--surface)] px-5 py-2 text-sm font-semibold text-white transition hover:border-[var(--gold)]/40 disabled:opacity-60"
    >
      {exporting ? "Preparing PDF..." : "⬇ Download PDF"}
    </button>
  );
}

function ShareButton({ story, visitorId }: { story: Story; visitorId: string | null }) {
  const [copied, setCopied] = useState(false);
  const url = useMemo(() => (typeof window !== "undefined" ? `${window.location.origin}/story/${story.id}` : ""), [story.id]);

  async function handleShare() {
    if (visitorId) recordVisit(visitorId, `/story/${story.id}`, "share");
    if (navigator.share) {
      try {
        await navigator.share({ title: story.title, text: `Check out this AI storybook: ${story.title}`, url });
        return;
      } catch {
        // user cancelled the native share sheet; fall through to copy-link
      }
    }
    await navigator.clipboard.writeText(url);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <button
      onClick={handleShare}
      className="rounded-full border border-white/10 bg-[var(--surface)] px-5 py-2 text-sm font-semibold text-white transition hover:border-[var(--gold)]/40"
    >
      {copied ? "Link copied!" : "🔗 Share story"}
    </button>
  );
}

function FeedbackForm({ storyId, visitorId }: { storyId: string; visitorId: string | null }) {
  const [options, setOptions] = useState<FeedbackOptions | null>(null);
  const [feedbackType, setFeedbackType] = useState<"Positive" | "Negative">("Positive");
  const [selected, setSelected] = useState("");
  const [custom, setCustom] = useState("");
  const [rating, setRating] = useState(5);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    getFeedbackOptions()
      .then((opts) => {
        setOptions(opts);
        setSelected(opts.Positive[0] ?? "");
      })
      .catch(() => setOptions(null));
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await submitFeedback({
        feedbackType,
        selectedFeedback: selected,
        customFeedback: custom,
        storyId,
        rating,
        visitorId: visitorId ?? "anonymous",
      });
      if (visitorId) recordVisit(visitorId, `/story/${storyId}`, "feedback_submitted");
      setSubmitted(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to submit feedback.");
    } finally {
      setSubmitting(false);
    }
  }

  const choices = feedbackType === "Positive" ? options?.Positive : options?.Negative;

  if (submitted) {
    return (
      <div className="mt-10 rounded-2xl border border-[var(--success)]/30 bg-[var(--success)]/10 p-6 text-center">
        <p className="font-display font-semibold text-[var(--success)]">Thanks for your feedback! 🎉</p>
      </div>
    );
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="mt-10 rounded-2xl border border-white/10 bg-white/5 p-6 shadow-[0_0_40px_-15px_rgba(255,200,87,0.1)] backdrop-blur-lg"
    >
      <p className="font-display font-semibold text-white">How was this story?</p>

      <div className="mt-3 flex gap-2">
        {(["Positive", "Negative"] as const).map((t) => (
          <button
            type="button"
            key={t}
            onClick={() => setFeedbackType(t)}
            className={`rounded-full px-4 py-1.5 text-sm font-semibold transition ${
              feedbackType === t
                ? "bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] text-[#1A1330]"
                : "border border-white/10 text-white/80"
            }`}
          >
            {t === "Positive" ? "👍 I liked it" : "👎 Needs work"}
          </button>
        ))}
      </div>

      <div className="mt-3 flex gap-1">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            type="button"
            key={n}
            onClick={() => setRating(n)}
            className="text-2xl"
            style={{ color: n <= rating ? "var(--gold)" : "var(--muted)" }}
            aria-label={`${n} star`}
          >
            {n <= rating ? "★" : "☆"}
          </button>
        ))}
      </div>

      {choices && (
        <select
          value={selected}
          onChange={(e) => setSelected(e.target.value)}
          className="mt-3 h-12 w-full border-b-2 border-white/20 bg-black/30 px-3 text-sm text-white outline-none focus:border-[var(--gold)]"
        >
          {choices.map((c) => (
            <option key={c} value={c} className="bg-[var(--surface)]">
              {c}
            </option>
          ))}
        </select>
      )}

      {selected === "Other" && (
        <textarea
          value={custom}
          onChange={(e) => setCustom(e.target.value)}
          placeholder="Tell us more..."
          rows={2}
          className="mt-3 w-full rounded-xl border border-white/10 bg-black/30 p-2 text-sm text-white outline-none placeholder:text-[var(--muted)] focus:border-[var(--gold)]"
        />
      )}

      {error && <p className="mt-2 text-sm text-[var(--error)]">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="mt-4 rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] px-6 py-2 text-sm font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,200,87,0.4)] transition-all duration-300 hover:scale-105 disabled:opacity-60"
      >
        {submitting ? "Sending..." : "Submit feedback"}
      </button>
    </form>
  );
}
