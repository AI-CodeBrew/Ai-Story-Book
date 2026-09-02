import { NextResponse } from "next/server";
import { adminStats } from "@/lib/api";
import { getAdminToken } from "@/lib/adminAuth";

export async function GET(request: Request) {
  const token = await getAdminToken();
  if (!token) {
    return NextResponse.json({ success: false, error: "Not authenticated" }, { status: 401 });
  }

  const url = new URL(request.url);
  try {
    const data = await adminStats(token, {
      start: url.searchParams.get("start") ?? undefined,
      end: url.searchParams.get("end") ?? undefined,
      granularity: url.searchParams.get("granularity") ?? undefined,
    });
    return NextResponse.json({ success: true, data });
  } catch (e) {
    return NextResponse.json({ success: false, error: e instanceof Error ? e.message : "Failed to load stats" }, { status: 401 });
  }
}
