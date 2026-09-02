"use client";

import { useVisitTracking } from "@/hooks/useVisitTracking";

/** Mounted once in the root layout; has no UI, just fires pageview events. */
export function VisitTracker() {
  useVisitTracking();
  return null;
}
