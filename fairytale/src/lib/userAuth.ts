import { cookies } from "next/headers";

/** Reads the httpOnly user JWT set by /api/auth/{login,signup,google}. Server-only. */
export async function getUserToken(): Promise<string | null> {
  const cookieStore = await cookies();
  return cookieStore.get("user_token")?.value ?? null;
}
