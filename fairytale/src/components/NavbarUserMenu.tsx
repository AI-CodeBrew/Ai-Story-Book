"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import type { User } from "@/lib/types";

export function NavbarUserMenu({ user }: { user: User }) {
  const router = useRouter();

  async function handleLogout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/");
    router.refresh();
  }

  return (
    <div className="flex items-center gap-3">
      <Link href="/profile" className="flex items-center gap-2 text-sm font-medium text-white transition hover:text-[var(--gold)]">
        <span className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-[var(--coral)] to-[var(--gold)] font-display text-xs font-bold text-[#1A1330]">
          {user.name.charAt(0).toUpperCase()}
        </span>
        <span className="hidden sm:inline">{user.name}</span>
      </Link>
      <button
        onClick={handleLogout}
        className="font-data text-xs tracking-wide text-[var(--muted)] uppercase transition hover:text-[var(--gold)]"
      >
        Log out
      </button>
    </div>
  );
}
