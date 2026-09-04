import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { signup } from "@/lib/api";

const USER_COOKIE = "user_token";
const TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30; // matches the Flask user JWT's 30-day expiry

export async function POST(request: Request) {
  try {
    const { email, password, name } = await request.json();
    if (!email || !password) {
      return NextResponse.json({ success: false, error: "Missing credentials" }, { status: 400 });
    }

    const { token, user } = await signup(email, password, name);

    const cookieStore = await cookies();
    cookieStore.set(USER_COOKIE, token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      maxAge: TOKEN_TTL_SECONDS,
    });

    return NextResponse.json({ success: true, data: { user } });
  } catch (e) {
    return NextResponse.json({ success: false, error: e instanceof Error ? e.message : "Signup failed" }, { status: 400 });
  }
}
