import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { adminLogin } from "@/lib/api";

const ADMIN_COOKIE = "admin_token";
const TOKEN_TTL_SECONDS = 60 * 60 * 8; // matches the Flask JWT's 8h expiry

export async function POST(request: Request) {
  try {
    const { email, password } = await request.json();
    if (!email || !password) {
      return NextResponse.json({ success: false, error: "Missing credentials" }, { status: 400 });
    }

    const { token } = await adminLogin(email, password);

    const cookieStore = await cookies();
    cookieStore.set(ADMIN_COOKIE, token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: TOKEN_TTL_SECONDS,
    });

    return NextResponse.json({ success: true });
  } catch (e) {
    return NextResponse.json({ success: false, error: e instanceof Error ? e.message : "Login failed" }, { status: 401 });
  }
}
