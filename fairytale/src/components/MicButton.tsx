"use client";

import { useEffect } from "react";
import { useSpeechToText } from "@/hooks/useSpeechToText";

/**
 * "Speak your story" button for the prompt box, so kids who can't type yet
 * can say their idea out loud. Renders nothing in browsers without speech
 * recognition (e.g. Firefox).
 */
export function MicButton({
  value,
  onChange,
  disabled = false,
}: {
  value: string;
  onChange: (text: string) => void;
  disabled?: boolean;
}) {
  const { supported, listening, error, start, stop } = useSpeechToText(onChange);

  // Stop listening once the form starts generating so late words can't
  // change the prompt mid-request.
  useEffect(() => {
    if (disabled && listening) stop();
  }, [disabled, listening, stop]);

  if (!supported) return null;

  return (
    <div className="flex items-center gap-2">
      <button
        type="button"
        onClick={() => (listening ? stop() : start(value))}
        disabled={disabled}
        aria-pressed={listening}
        aria-label={listening ? "Stop listening" : "Speak your story"}
        className={`relative flex h-10 shrink-0 items-center gap-2 rounded-full px-4 text-sm font-semibold transition disabled:opacity-60 ${
          listening
            ? "bg-[var(--error)] text-white"
            : "border border-[var(--gold)]/40 bg-[var(--gold)]/10 text-[var(--gold)] hover:bg-[var(--gold)]/20"
        }`}
      >
        {listening && <span className="absolute inset-0 animate-ping rounded-full bg-[var(--error)]/40" aria-hidden />}
        {listening ? (
          <svg viewBox="0 0 24 24" className="relative h-4 w-4" fill="currentColor" aria-hidden>
            <rect x="6" y="6" width="12" height="12" rx="2" />
          </svg>
        ) : (
          <svg viewBox="0 0 24 24" className="relative h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
            <rect x="9" y="3" width="6" height="11" rx="3" />
            <path d="M5 11a7 7 0 0 0 14 0M12 18v3" />
          </svg>
        )}
        <span className="relative">{listening ? "Listening… tap to stop" : "Speak your story"}</span>
      </button>
      {error && !listening && (
        <span role="status" className="text-xs text-[var(--error)]">
          {error}
        </span>
      )}
    </div>
  );
}
