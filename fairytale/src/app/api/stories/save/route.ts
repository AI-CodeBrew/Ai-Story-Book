import { NextResponse } from "next/server";
import { saveStory } from "@/lib/api";
import { getUserToken } from "@/lib/userAuth";

export async function POST(request: Request) {
  const token = await getUserToken();
  if (!token) {
    return NextResponse.json({ success: false, error: "Login required" }, { status: 401 });
  }
  try {
    const { story, visitorId } = await request.json();
    const saved = await saveStory(story, token, visitorId);
    return NextResponse.json({ success: true, data: saved });
  } catch (e) {
    return NextResponse.json({ success: false, error: e instanceof Error ? e.message : "Failed to save story" }, { status: 400 });
  }
}
