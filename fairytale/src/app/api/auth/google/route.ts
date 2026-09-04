import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { googleAuth } from "@/lib/api";

const USER_COOKIE = "user_token";
const TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30; // matches the Flask user JWT's 30-day expiry

export async function POST(request: Request) {
  try {
    const { idToken } = await request.json();
    if (!idToken) {
      return NextResponse.json({ success: false, error: "Missing idToken" }, { status: 400 });
    }

    const { token, user } = await googleAuth(idToken);

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
    return NextResponse.json({ success: false, error: e instanceof Error ? e.message : "Google sign-in failed" }, { status: 401 });
  }
}
