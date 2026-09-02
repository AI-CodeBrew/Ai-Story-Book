"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function AdminLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const body = await res.json();
      if (!res.ok || !body.success) throw new Error(body.error || "Invalid credentials");
      router.push("/admin");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center px-6">
      <form
        onSubmit={handleSubmit}
        className="relative w-full max-w-sm border border-white/10 bg-white/5 p-8 shadow-[0_0_50px_-10px_rgba(255,200,87,0.15)] backdrop-blur-lg"
        style={{ clipPath: "polygon(0 0, calc(100% - 24px) 0, 100% 24px, 100% 100%, 0 100%)" }}
      >
        <div className="absolute top-0 left-0 h-5 w-5 border-t-2 border-l-2 border-[var(--gold)]" />
        <div className="absolute right-0 bottom-0 h-5 w-5 border-r-2 border-b-2 border-[var(--violet)]" />

        <p className="font-data text-center text-[11px] tracking-widest text-[var(--muted)] uppercase">Restricted access</p>
        <h1 className="font-display mt-1 text-center text-2xl font-bold text-gradient-magic">Admin Login</h1>
        <div className="mt-6 space-y-1">
          <input
            type="email"
            required
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="h-12 w-full border-b-2 border-white/20 bg-black/30 px-4 text-sm text-white outline-none placeholder:text-white/30 focus:border-[var(--gold)] focus:shadow-[0_10px_20px_-10px_rgba(255,200,87,0.3)]"
          />
          <input
            type="password"
            required
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="h-12 w-full border-b-2 border-white/20 bg-black/30 px-4 text-sm text-white outline-none placeholder:text-white/30 focus:border-[var(--gold)] focus:shadow-[0_10px_20px_-10px_rgba(255,200,87,0.3)]"
          />
        </div>
        {error && <p className="mt-3 text-sm text-[var(--error)]">{error}</p>}
        <button
          type="submit"
          disabled={loading}
          className="mt-6 w-full rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] py-3 font-display font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,200,87,0.4)] transition-all duration-300 hover:scale-[1.02] disabled:opacity-60"
        >
          {loading ? "Signing in..." : "Sign in"}
        </button>
      </form>
    </div>
  );
}
