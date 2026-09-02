import type { AdminStats, FeedbackOptions, Story } from "./types";

// Server-side code (Server Components, Route Handlers) talks to Flask over
// FLASK_INTERNAL_URL; the browser talks over NEXT_PUBLIC_API_BASE_URL. Both
// point at the same Flask instance in dev, but keeping them separate lets
// the server reach a private/internal address in production later.
export function apiBaseUrl(): string {
  if (typeof window !== "undefined") {
    return process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8080";
  }
  return process.env.FLASK_INTERNAL_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8080";
}

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${apiBaseUrl()}/api${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...(init?.headers ?? {}) },
    cache: "no-store",
  });
  const body = await res.json();
  if (!res.ok || body.success === false) {
    throw new Error(body.error || `Request failed: ${res.status}`);
  }
  return body.data as T;
}

export interface GenerateStoryInput {
  prompt: string;
  theme: string;
  additionalContext?: string;
}

// Mirrors the mobile app's flow: /stories/generate returns text + placeholder
// images, then each page's real illustration is generated separately.
export async function generateStory(input: GenerateStoryInput): Promise<Story> {
  return apiFetch<Story>("/stories/generate", {
    method: "POST",
    body: JSON.stringify(input),
  });
}

export async function generatePageImage(prompt: string): Promise<string | null> {
  const res = await fetch(`${apiBaseUrl()}/api/generate-image`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt }),
  });
  const body = await res.json();
  if (!res.ok || !body.success || !body.imageBase64) return null;
  return `data:image/jpeg;base64,${body.imageBase64}`;
}

export async function saveStory(story: Story, visitorId: string): Promise<Story> {
  return apiFetch<Story>("/stories/save", {
    method: "POST",
    body: JSON.stringify({ story, visitorId, source: "website" }),
  });
}

export async function getStory(id: string): Promise<Story> {
  return apiFetch<Story>(`/stories/${id}`);
}

export async function listStories(opts?: { isDefault?: boolean; limit?: number }): Promise<Story[]> {
  const params = new URLSearchParams();
  if (opts?.isDefault !== undefined) params.set("isDefault", String(opts.isDefault));
  if (opts?.limit) params.set("limit", String(opts.limit));
  const qs = params.toString();
  return apiFetch<Story[]>(`/stories${qs ? `?${qs}` : ""}`);
}

export async function getFeedbackOptions(): Promise<FeedbackOptions> {
  return apiFetch<FeedbackOptions>("/feedback/options");
}

export interface SubmitFeedbackInput {
  feedbackType: "Positive" | "Negative";
  selectedFeedback: string;
  customFeedback?: string;
  storyId: string;
  rating: number;
  visitorId: string;
}

export async function submitFeedback(input: SubmitFeedbackInput): Promise<void> {
  await apiFetch("/feedback", { method: "POST", body: JSON.stringify(input) });
}

export async function recordVisit(visitorId: string, path: string, event = "pageview"): Promise<void> {
  try {
    await fetch(`${apiBaseUrl()}/api/visits`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ visitorId, path, event, referrer: typeof document !== "undefined" ? document.referrer : undefined }),
    });
  } catch {
    // best-effort analytics; never block the UI on this
  }
}

// --- Admin (called server-side, via the BFF route handlers) ---

export async function adminLogin(email: string, password: string): Promise<{ token: string; email: string }> {
  return apiFetch("/admin/login", { method: "POST", body: JSON.stringify({ email, password }) });
}

export async function adminStats(token: string, params: { start?: string; end?: string; granularity?: string }): Promise<AdminStats> {
  const qs = new URLSearchParams();
  if (params.start) qs.set("start", params.start);
  if (params.end) qs.set("end", params.end);
  if (params.granularity) qs.set("granularity", params.granularity);
  return apiFetch<AdminStats>(`/admin/stats?${qs.toString()}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
}

export async function adminSetDefault(token: string, storyId: string, isDefault: boolean): Promise<Story> {
  return apiFetch<Story>(`/stories/${storyId}/default`, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${token}` },
    body: JSON.stringify({ isDefault }),
  });
}

export async function adminListAllStories(limit = 50): Promise<Story[]> {
  return listStories({ limit });
}
