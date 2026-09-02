import { cookies } from "next/headers";

/** Reads the httpOnly admin JWT set by /api/admin/login. Server-only. */
export async function getAdminToken(): Promise<string | null> {
  const cookieStore = await cookies();
  return cookieStore.get("admin_token")?.value ?? null;
}
