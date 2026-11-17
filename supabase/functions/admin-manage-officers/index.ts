
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";

export default {
  async fetch(req: Request): Promise<Response> {
    // Only allow POST requests.
    if (req.method !== "POST") {
      return Response.json(
        { success: false, message: "Method not allowed" },
        { status: 405 },
      );
    }

    // Extract the signed-in user's access token.
    const authorization = req.headers.get("Authorization");

    if (!authorization?.startsWith("Bearer ")) {
      return Response.json(
        { success: false, message: "Authentication required" },
        { status: 401 },
      );
    }

    const token = authorization.slice(7).trim();

    if (!token) {
      return Response.json(
        { success: false, message: "Invalid access token" },
        { status: 401 },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey =
      Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
      Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !supabaseKey) {
      return Response.json(
        { success: false, message: "Server configuration error" },
        { status: 500 },
      );
    }

    // Create a client using the caller's access token.
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Verify the token with Supabase Auth.
    const { data: userData, error: userError } =
      await supabase.auth.getUser(token);

    if (userError || !userData.user) {
      return Response.json(
        { success: false, message: "Invalid or expired session" },
        { status: 401 },
      );
    }

    // Check the authenticated user's Administrator role.
    const { data: isAdmin, error: roleError } =
      await supabase.rpc("is_safesense_admin");

    if (roleError) {
      console.error("Administrator authorization check failed");

      return Response.json(
        { success: false, message: "Authorization check failed" },
        { status: 500 },
      );
    }

    if (isAdmin !== true) {
      return Response.json(
        { success: false, message: "Administrator access required" },
        { status: 403 },
      );
    }

    // Authentication succeeds, but management is not enabled yet.
    return Response.json(
      {
        success: true,
        message: "SafeSense Administrator authenticated successfully.",
      },
      { status: 200 },
    );
  },
};
