"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";
import { recordVisit } from "@/lib/api";
import { useVisitorId } from "./useVisitorId";

/** Logs one pageview event per route change, keyed to the persistent visitorId. */
export function useVisitTracking() {
  const visitorId = useVisitorId();
  const pathname = usePathname();

  useEffect(() => {
    if (!visitorId || !pathname) return;
    recordVisit(visitorId, pathname, "pageview");
  }, [visitorId, pathname]);
}
