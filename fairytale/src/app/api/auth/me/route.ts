import { NextResponse } from "next/server";
import { me } from "@/lib/api";
import { getUserToken } from "@/lib/userAuth";

export async function GET() {
  const token = await getUserToken();
  if (!token) {
    return NextResponse.json({ success: false, error: "Not authenticated" }, { status: 401 });
  }
  try {
    const user = await me(token);
    return NextResponse.json({ success: true, data: user });
  } catch (e) {
    return NextResponse.json({ success: false, error: e instanceof Error ? e.message : "Failed to load user" }, { status: 401 });
  }
}
