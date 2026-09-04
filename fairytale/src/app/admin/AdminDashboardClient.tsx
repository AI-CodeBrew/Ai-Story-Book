"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from "recharts";
import type { AdminStats, Story } from "@/lib/types";
import { THEME_OPTIONS } from "@/lib/types";

type Granularity = "day" | "week" | "month";

function toInputDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export function AdminDashboardClient() {
  const router = useRouter();
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [granularity, setGranularity] = useState<Granularity>("day");
  const [start, setStart] = useState(() => toInputDate(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)));
  const [end, setEnd] = useState(() => toInputDate(new Date()));
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [stories, setStories] = useState<Story[]>([]);
  const [storiesLoading, setStoriesLoading] = useState(true);
  const [themeFilter, setThemeFilter] = useState<string>("");

  const loadStats = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const qs = new URLSearchParams({
        granularity,
        start: new Date(start).toISOString(),
        end: new Date(end + "T23:59:59").toISOString(),
      });
      const res = await fetch(`/api/admin/stats?${qs.toString()}`);
      if (res.status === 401) {
        router.push("/admin/login");
        return;
      }
      const body = await res.json();
      if (!body.success) throw new Error(body.error);
      setStats(body.data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load stats");
    } finally {
      setLoading(false);
    }
  }, [granularity, start, end, router]);

  useEffect(() => {
    loadStats();
  }, [loadStats]);

  const loadStories = useCallback(async () => {
    setStoriesLoading(true);
    try {
      const qs = new URLSearchParams({ limit: "100" });
      if (themeFilter) qs.set("theme", themeFilter);
      const res = await fetch(`/api/admin/stories?${qs.toString()}`);
      if (res.status === 401) {
        router.push("/admin/login");
        return;
      }
      const body = await res.json();
      setStories(body.success ? body.data : []);
    } catch {
      setStories([]);
    } finally {
      setStoriesLoading(false);
    }
  }, [themeFilter, router]);

  useEffect(() => {
    loadStories();
  }, [loadStories]);

  async function toggleDefault(story: Story) {
    const res = await fetch(`/api/admin/stories/${story.id}/default`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isDefault: !story.isDefault }),
    });
    if (res.status === 401) {
      router.push("/admin/login");
      return;
    }
    const body = await res.json();
    if (body.success) {
      setStories((prev) => prev.map((s) => (s.id === story.id ? { ...s, isDefault: body.data.isDefault } : s)));
    }
  }

  async function handleLogout() {
    await fetch("/api/admin/logout", { method: "POST" });
    router.push("/admin/login");
  }

  const chartData = (stats?.series ?? []).map((p) => ({
    period: new Date(p.period).toLocaleDateString(undefined, { month: "short", day: "numeric" }),
    visitors: p.visitors,
  }));

  return (
    <div className="mx-auto max-w-6xl px-6 py-10">
      <div className="flex items-center justify-between">
        <div>
          <p className="font-data text-[11px] tracking-widest text-[var(--muted)] uppercase">Control panel</p>
          <h1 className="font-display text-2xl font-bold text-gradient-magic">Admin Dashboard</h1>
        </div>
        <button
          onClick={handleLogout}
          className="rounded-full border border-white/10 px-4 py-2 text-sm font-semibold text-white transition hover:border-[var(--gold)]/40"
        >
          Log out
        </button>
      </div>

      {error && <p className="mt-4 text-sm text-[var(--error)]">{error}</p>}

      <div className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        <StatTile label="Total users" value={stats?.totalUsers} loading={loading} accent="var(--gold)" />
        <StatTile label="Total stories" value={stats?.totalStories} loading={loading} accent="var(--coral)" />
        <StatTile label="Total feedback" value={stats?.totalFeedback} loading={loading} accent="var(--violet)" />
        <StatTile label="Visitors (range)" value={stats?.rangeVisitors} loading={loading} accent="var(--success)" />
        <StatTile label="Visits (range)" value={stats?.rangeVisits} loading={loading} accent="var(--gold)" />
      </div>

      <div className="mt-10 rounded-2xl border border-white/10 bg-white/5 p-6 shadow-[0_0_50px_-15px_rgba(255,200,87,0.1)] backdrop-blur-lg">
        <div className="flex flex-wrap items-end gap-6">
          <div>
            <label className="font-data text-[11px] tracking-wide text-[var(--muted)] uppercase">Granularity</label>
            <select
              value={granularity}
              onChange={(e) => setGranularity(e.target.value as Granularity)}
              className="mt-1 h-10 w-32 border-b-2 border-white/20 bg-black/30 px-2 text-sm text-white outline-none focus:border-[var(--gold)]"
            >
              <option value="day">Day</option>
              <option value="week">Week</option>
              <option value="month">Month</option>
            </select>
          </div>
          <div>
            <label className="font-data text-[11px] tracking-wide text-[var(--muted)] uppercase">From</label>
            <input
              type="date"
              value={start}
              onChange={(e) => setStart(e.target.value)}
              className="mt-1 h-10 border-b-2 border-white/20 bg-black/30 px-2 text-sm text-white outline-none focus:border-[var(--gold)]"
            />
          </div>
          <div>
            <label className="font-data text-[11px] tracking-wide text-[var(--muted)] uppercase">To</label>
            <input
              type="date"
              value={end}
              onChange={(e) => setEnd(e.target.value)}
              className="mt-1 h-10 border-b-2 border-white/20 bg-black/30 px-2 text-sm text-white outline-none focus:border-[var(--gold)]"
            />
          </div>
          <button
            onClick={loadStats}
            className="h-10 rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] px-5 text-sm font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,200,87,0.4)] transition-all duration-300 hover:scale-105"
          >
            Run query
          </button>
        </div>

        <div className="mt-6 h-72 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData}>
              <defs>
                <linearGradient id="lineGlow" x1="0" y1="0" x2="1" y2="0">
                  <stop offset="0%" stopColor="#FF7B54" />
                  <stop offset="100%" stopColor="#FFC857" />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.08)" />
              <XAxis dataKey="period" fontSize={11} stroke="#A79FC7" tickLine={false} />
              <YAxis fontSize={11} allowDecimals={false} stroke="#A79FC7" tickLine={false} />
              <Tooltip
                contentStyle={{
                  backgroundColor: "#17152E",
                  border: "1px solid rgba(255,255,255,0.1)",
                  borderRadius: 8,
                  color: "white",
                  fontSize: 12,
                }}
                labelStyle={{ color: "#A79FC7" }}
              />
              <Line type="monotone" dataKey="visitors" stroke="url(#lineGlow)" strokeWidth={3} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="mt-10">
        <div className="flex flex-wrap items-end justify-between gap-4">
          <div>
            <h2 className="font-display text-xl font-bold text-white">All stories</h2>
            <p className="text-sm text-[var(--muted)]">Toggle which stories are public (homepage, Library, Flutter home).</p>
          </div>
          <div>
            <label className="font-data text-[11px] tracking-wide text-[var(--muted)] uppercase">Filter by type</label>
            <select
              value={themeFilter}
              onChange={(e) => setThemeFilter(e.target.value)}
              className="mt-1 block h-10 w-40 border-b-2 border-white/20 bg-black/30 px-2 text-sm text-white outline-none focus:border-[var(--gold)]"
            >
              <option value="">All types</option>
              {THEME_OPTIONS.map((t) => (
                <option key={t.name} value={t.name}>
                  {t.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="mt-4 overflow-x-auto rounded-2xl border border-white/10 bg-white/5 backdrop-blur-lg">
          <table className="w-full min-w-[500px] text-left text-sm">
            <thead className="font-data border-b border-white/10 text-[11px] tracking-wide text-[var(--muted)] uppercase">
              <tr>
                <th className="p-4">Title</th>
                <th className="p-4">Theme</th>
                <th className="p-4">Created</th>
                <th className="p-4">Public</th>
              </tr>
            </thead>
            <tbody>
              {storiesLoading && (
                <tr>
                  <td className="p-4 text-[var(--muted)]" colSpan={4}>
                    Loading stories...
                  </td>
                </tr>
              )}
              {!storiesLoading && stories.length === 0 && (
                <tr>
                  <td className="p-4 text-[var(--muted)]" colSpan={4}>
                    No stories yet.
                  </td>
                </tr>
              )}
              {stories.map((story) => (
                <tr key={story.id} className="border-b border-white/5 last:border-0">
                  <td className="p-4 font-medium text-white">{story.title}</td>
                  <td className="p-4 text-white/80">{story.theme}</td>
                  <td className="font-data p-4 text-xs text-[var(--muted)]">{new Date(story.createdAt).toLocaleDateString()}</td>
                  <td className="p-4">
                    <button
                      onClick={() => toggleDefault(story)}
                      className={`rounded-full px-3 py-1 text-xs font-semibold transition ${
                        story.isDefault
                          ? "bg-[var(--success)]/20 text-[var(--success)] shadow-[0_0_15px_-5px_rgba(110,231,183,0.6)]"
                          : "border border-white/10 text-white/70"
                      }`}
                    >
                      {story.isDefault ? "● Public" : "Make public"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

function StatTile({ label, value, loading, accent }: { label: string; value: number | undefined; loading: boolean; accent: string }) {
  return (
    <div
      className="rounded-2xl border border-white/10 bg-white/5 p-4 backdrop-blur-lg transition-all duration-300 hover:-translate-y-0.5"
      style={{ boxShadow: `0 0 0 rgba(0,0,0,0)` }}
      onMouseEnter={(e) => (e.currentTarget.style.boxShadow = `0 0 30px -10px ${accent}`)}
      onMouseLeave={(e) => (e.currentTarget.style.boxShadow = "0 0 0 rgba(0,0,0,0)")}
    >
      <p className="font-data text-[11px] tracking-wide text-[var(--muted)] uppercase">{label}</p>
      <p className="font-data mt-1 text-2xl font-bold" style={{ color: accent }}>
        {loading ? "—" : value ?? 0}
      </p>
    </div>
  );
}
