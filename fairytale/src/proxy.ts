import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const ADMIN_COOKIE = "admin_token";
const USER_COOKIE = "user_token";

// Gate-check only: this just decides whether to bounce to a login page.
// Every protected API call is still independently verified by Flask's
// @require_admin / @require_user (JWT signature + expiry), so a forged/expired
// cookie can't actually reach protected data — this just improves the UX.
export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (pathname === "/admin/login") {
    return NextResponse.next();
  }

  if (pathname.startsWith("/admin")) {
    const hasToken = request.cookies.has(ADMIN_COOKIE);
    if (!hasToken) {
      return NextResponse.redirect(new URL("/admin/login", request.url));
    }
    return NextResponse.next();
  }

  if (pathname.startsWith("/generate") || pathname.startsWith("/profile")) {
    const hasToken = request.cookies.has(USER_COOKIE);
    if (!hasToken) {
      const url = new URL("/login", request.url);
      url.searchParams.set("next", pathname);
      return NextResponse.redirect(url);
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/generate/:path*", "/profile/:path*"],
};
