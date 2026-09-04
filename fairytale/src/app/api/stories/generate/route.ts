import { NextResponse } from "next/server";
import { generateStory } from "@/lib/api";
import { getUserToken } from "@/lib/userAuth";

// The user's JWT lives in an httpOnly cookie (unreadable by client JS), so
// story generation — now login-gated — has to be proxied through here
// instead of the browser calling Flask directly.
export async function POST(request: Request) {
  const token = await getUserToken();
  if (!token) {
    return NextResponse.json({ success: false, error: "Login required" }, { status: 401 });
  }
  try {
    const input = await request.json();
    const story = await generateStory(input, token);
    return NextResponse.json({ success: true, data: story });
  } catch (e) {
    return NextResponse.json({ success: false, error: e instanceof Error ? e.message : "Failed to generate story" }, { status: 400 });
  }
}
