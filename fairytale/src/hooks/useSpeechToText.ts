"use client";

import { useCallback, useEffect, useRef, useState, useSyncExternalStore } from "react";

// Minimal typings for the browser Web Speech API — TypeScript's lib.dom
// doesn't ship them. Chrome/Edge/Safari expose it (Safari and older Chrome
// only under the webkit prefix); Firefox doesn't, so callers hide the mic.
interface SpeechRecognitionResultLike {
  readonly 0: { readonly transcript: string };
}
interface SpeechRecognitionEventLike {
  readonly results: ArrayLike<SpeechRecognitionResultLike>;
}
interface SpeechRecognitionLike {
  lang: string;
  continuous: boolean;
  interimResults: boolean;
  onresult: ((e: SpeechRecognitionEventLike) => void) | null;
  onerror: ((e: { error: string }) => void) | null;
  onend: (() => void) | null;
  start(): void;
  stop(): void;
  abort(): void;
}
type SpeechRecognitionCtor = new () => SpeechRecognitionLike;

function getRecognitionCtor(): SpeechRecognitionCtor | null {
  if (typeof window === "undefined") return null;
  const w = window as unknown as { SpeechRecognition?: SpeechRecognitionCtor; webkitSpeechRecognition?: SpeechRecognitionCtor };
  return w.SpeechRecognition ?? w.webkitSpeechRecognition ?? null;
}

const noopSubscribe = () => () => {};

function describeError(code: string): string {
  if (code === "not-allowed" || code === "service-not-allowed") return "Please allow the microphone to speak your story.";
  if (code === "no-speech") return "We didn't hear anything — try again!";
  if (code === "audio-capture") return "No microphone found.";
  if (code === "network") return "Voice needs an internet connection.";
  return "Voice input stopped. Try again!";
}

/**
 * Turns speech into text for the story prompt. `start(baseText)` keeps what
 * was already typed and appends the spoken words after it, reporting the
 * combined text through `onText` as the child talks.
 */
export function useSpeechToText(onText: (text: string) => void) {
  // false during SSR and hydration, then the real answer on the client.
  const supported = useSyncExternalStore(noopSubscribe, () => getRecognitionCtor() !== null, () => false);
  const [listening, setListening] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const recognitionRef = useRef<SpeechRecognitionLike | null>(null);
  const onTextRef = useRef(onText);

  useEffect(() => {
    onTextRef.current = onText;
  }, [onText]);

  useEffect(() => () => recognitionRef.current?.abort(), []);

  const stop = useCallback(() => {
    recognitionRef.current?.stop();
  }, []);

  const start = useCallback((baseText: string) => {
    const Ctor = getRecognitionCtor();
    if (!Ctor) return;
    recognitionRef.current?.abort();

    const recognition = new Ctor();
    recognition.lang = navigator.language || "en-US";
    // Kids pause mid-sentence while thinking; keep listening until they tap stop.
    recognition.continuous = true;
    recognition.interimResults = true;

    const base = baseText.trim();
    recognition.onresult = (e) => {
      let spoken = "";
      for (let i = 0; i < e.results.length; i++) spoken += e.results[i][0].transcript;
      spoken = spoken.trim();
      onTextRef.current(base && spoken ? `${base} ${spoken}` : base || spoken);
    };
    recognition.onerror = (e) => {
      if (e.error !== "aborted") setError(describeError(e.error));
    };
    recognition.onend = () => {
      if (recognitionRef.current === recognition) recognitionRef.current = null;
      setListening(false);
    };

    recognitionRef.current = recognition;
    setError(null);
    setListening(true);
    try {
      recognition.start();
    } catch {
      recognitionRef.current = null;
      setListening(false);
      setError(describeError("unknown"));
    }
  }, []);

  return { supported, listening, error, start, stop };
}
