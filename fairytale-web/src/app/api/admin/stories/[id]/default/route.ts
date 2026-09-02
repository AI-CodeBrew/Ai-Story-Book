import { NextResponse } from "next/server";
import { adminSetDefault } from "@/lib/api";
import { getAdminToken } from "@/lib/adminAuth";

export async function PATCH(request: Request, ctx: RouteContext<"/api/admin/stories/[id]/default">) {
  const token = await getAdminToken();
  if (!token) {
    return NextResponse.json({ success: false, error: "Not authenticated" }, { status: 401 });
  }

  const { id } = await ctx.params;
  try {
    const { isDefault } = await request.json();
    const data = await adminSetDefault(token, id, Boolean(isDefault));
    return NextResponse.json({ success: true, data });
  } catch (e) {
    return NextResponse.json({ success: false, error: e instanceof Error ? e.message : "Failed to update story" }, { status: 400 });
  }
}
