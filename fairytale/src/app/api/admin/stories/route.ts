import { NextResponse } from "next/server";
import { adminListAllStories } from "@/lib/api";
import { getAdminToken } from "@/lib/adminAuth";

export async function GET(request: Request) {
  const token = await getAdminToken();
  if (!token) {
    return NextResponse.json({ success: false, error: "Not authenticated" }, { status: 401 });
  }
  const { searchParams } = new URL(request.url);
  const theme = searchParams.get("theme") ?? undefined;
  const limit = searchParams.get("limit");
  try {
    const stories = await adminListAllStories(token, { theme, limit: limit ? Number(limit) : undefined });
    return NextResponse.json({ success: true, data: stories });
  } catch (e) {
    return NextResponse.json({ success: false, error: e instanceof Error ? e.message : "Failed to load stories" }, { status: 400 });
  }
}
