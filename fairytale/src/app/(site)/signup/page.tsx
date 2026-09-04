"use client";

import { Suspense, useState, useCallback } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { GoogleSignInButton } from "@/components/GoogleSignInButton";

function SignupForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const next = searchParams.get("next") ?? "/";

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/auth/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password, name }),
      });
      const body = await res.json();
      if (!res.ok || !body.success) throw new Error(body.error || "Signup failed");
      router.push(next);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Signup failed");
    } finally {
      setLoading(false);
    }
  }

  const handleGoogleToken = useCallback(
    async (idToken: string) => {
      setError(null);
      try {
        const res = await fetch("/api/auth/google", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ idToken }),
        });
        const body = await res.json();
        if (!res.ok || !body.success) throw new Error(body.error || "Google sign-in failed");
        router.push(next);
        router.refresh();
      } catch (err) {
        setError(err instanceof Error ? err.message : "Google sign-in failed");
      }
    },
    [router, next]
  );

  return (
    <div className="bg-void-texture flex min-h-screen items-center justify-center px-6 py-16">
      <form
        onSubmit={handleSubmit}
        className="relative w-full max-w-sm rounded-3xl border-2 border-white/10 bg-white/5 p-8 shadow-[0_0_50px_-10px_rgba(255,200,87,0.15)] backdrop-blur-lg"
      >
        <h1 className="font-display text-center text-2xl font-bold text-gradient-magic">Create your account</h1>
        <p className="mt-1 text-center text-sm text-[var(--muted)]">Save your stories and build your library.</p>

        <div className="mt-6 space-y-1">
          <input
            type="text"
            required
            placeholder="Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="h-12 w-full border-b-2 border-white/20 bg-black/30 px-4 text-sm text-white outline-none placeholder:text-white/30 focus:border-[var(--gold)]"
          />
          <input
            type="email"
            required
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="h-12 w-full border-b-2 border-white/20 bg-black/30 px-4 text-sm text-white outline-none placeholder:text-white/30 focus:border-[var(--gold)]"
          />
          <input
            type="password"
            required
            placeholder="Password (min. 6 characters)"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="h-12 w-full border-b-2 border-white/20 bg-black/30 px-4 text-sm text-white outline-none placeholder:text-white/30 focus:border-[var(--gold)]"
          />
        </div>

        {error && <p className="mt-3 text-sm text-[var(--error)]">{error}</p>}

        <button
          type="submit"
          disabled={loading}
          className="mt-6 w-full rounded-full bg-gradient-to-r from-[var(--coral)] to-[var(--gold)] py-3 font-display font-semibold text-[#1A1330] shadow-[0_0_20px_-5px_rgba(255,200,87,0.4)] transition-all duration-300 hover:scale-[1.02] disabled:opacity-60"
        >
          {loading ? "Creating account..." : "Sign up"}
        </button>

        <div className="my-5 flex items-center gap-3 text-xs text-[var(--muted)]">
          <div className="h-px flex-1 bg-white/10" />
          or
          <div className="h-px flex-1 bg-white/10" />
        </div>

        <GoogleSignInButton onIdToken={handleGoogleToken} />

        <p className="mt-6 text-center text-sm text-[var(--muted)]">
          Already have an account?{" "}
          <Link href="/login" className="font-semibold text-[var(--gold)]">
            Log in
          </Link>
        </p>
      </form>
    </div>
  );
}

export default function SignupPage() {
  return (
    <Suspense>
      <SignupForm />
    </Suspense>
  );
}
