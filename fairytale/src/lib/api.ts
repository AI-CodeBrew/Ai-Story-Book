import type { AdminStats, FeedbackOptions, Story, User } from "./types";

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
// Login-gated on the backend, so a bearer token is required — called only
// from the server-side /api/stories/generate BFF route, which holds it.
export async function generateStory(input: GenerateStoryInput, token: string): Promise<Story> {
  return apiFetch<Story>("/stories/generate", {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
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

// Login-gated on the backend; called only from the server-side
// /api/stories/save BFF route. The backend derives the real owner from the
// token, so visitorId here is kept only for anonymous analytics correlation.
export async function saveStory(story: Story, token: string, visitorId?: string): Promise<Story> {
  return apiFetch<Story>("/stories/save", {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
    body: JSON.stringify({ story, visitorId, source: "website" }),
  });
}

export async function getStory(id: string): Promise<Story> {
  return apiFetch<Story>(`/stories/${id}`);
}

export async function listStories(opts?: { isDefault?: boolean; theme?: string; limit?: number }): Promise<Story[]> {
  const params = new URLSearchParams();
  if (opts?.isDefault !== undefined) params.set("isDefault", String(opts.isDefault));
  if (opts?.theme) params.set("theme", opts.theme);
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

export async function adminListAllStories(token: string, opts?: { theme?: string; limit?: number }): Promise<Story[]> {
  const params = new URLSearchParams();
  if (opts?.theme) params.set("theme", opts.theme);
  params.set("limit", String(opts?.limit ?? 100));
  return apiFetch<Story[]>(`/stories?${params.toString()}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
}

// --- End-user auth (called server-side, via the /api/auth/* BFF routes) ---

export async function signup(email: string, password: string, name: string): Promise<{ token: string; user: User }> {
  return apiFetch("/auth/signup", { method: "POST", body: JSON.stringify({ email, password, name }) });
}

export async function login(email: string, password: string): Promise<{ token: string; user: User }> {
  return apiFetch("/auth/login", { method: "POST", body: JSON.stringify({ email, password }) });
}

export async function googleAuth(idToken: string): Promise<{ token: string; user: User }> {
  return apiFetch("/auth/google", { method: "POST", body: JSON.stringify({ idToken }) });
}

export async function me(token: string): Promise<User> {
  return apiFetch<User>("/auth/me", { headers: { Authorization: `Bearer ${token}` } });
}

export async function myStories(token: string, limit = 50): Promise<Story[]> {
  return apiFetch<Story[]>(`/stories/mine?limit=${limit}`, { headers: { Authorization: `Bearer ${token}` } });
}
