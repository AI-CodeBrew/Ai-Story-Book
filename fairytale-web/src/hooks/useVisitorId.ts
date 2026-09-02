"use client";

import { useEffect, useState } from "react";

const STORAGE_KEY = "storybook_visitor_id";
const COOKIE_KEY = "visitor_id";

function readCookie(name: string): string | null {
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return match ? decodeURIComponent(match[1]) : null;
}

function mintOrReadVisitorId(): string {
  const existing = localStorage.getItem(STORAGE_KEY) ?? readCookie(COOKIE_KEY);
  if (existing) {
    localStorage.setItem(STORAGE_KEY, existing);
    return existing;
  }
  const id = crypto.randomUUID();
  localStorage.setItem(STORAGE_KEY, id);
  document.cookie = `${COOKIE_KEY}=${id}; path=/; max-age=${60 * 60 * 24 * 365}`;
  return id;
}

/** A persistent, anonymous per-browser id used to count distinct visitors/users. */
export function useVisitorId(): string | null {
  const [visitorId, setVisitorId] = useState<string | null>(null);

  useEffect(() => {
    try {
      setVisitorId(mintOrReadVisitorId());
    } catch {
      setVisitorId(null);
    }
  }, []);

  return visitorId;
}
