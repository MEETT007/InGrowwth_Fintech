import { NextRequest } from "next/server";
export const dynamic = "force-dynamic";
async function proxy(
  req: NextRequest,
  { params }: { params: Promise<{ path: string[] }> },
) {
  const { path } = await params;
  const base = process.env.JAVA_API_URL || "http://127.0.0.1:8080";
  const url = new URL(
    "/api/" + path.map(encodeURIComponent).join("/") + req.nextUrl.search,
    base,
  );
  const headers = new Headers();
  for (const key of ["cookie", "content-type", "x-xsrf-token", "accept"]) {
    const value = req.headers.get(key);
    if (value) headers.set(key, value);
  }
  try {
    const body = ["GET", "HEAD"].includes(req.method)
      ? undefined
      : await req.arrayBuffer();
    const result = await fetch(url, {
      method: req.method,
      headers,
      body,
      cache: "no-store",
      signal: req.signal,
    });
    const out = new Headers({
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
    });
    for (const key of ["content-type", "content-disposition"]) {
      const value = result.headers.get(key);
      if (value) out.set(key, value);
    }
    for (const cookie of result.headers.getSetCookie())
      out.append("set-cookie", cookie);
    return new Response(result.body, { status: result.status, headers: out });
  } catch {
    return Response.json(
      {
        error:
          "The lending service is unavailable. Your input has been retained; please try again.",
      },
      { status: 503 },
    );
  }
}
export { proxy as GET, proxy as POST };
