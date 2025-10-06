import { NextResponse } from "next/server";
import { z } from "zod";
import { getAnonSupabase, getServiceSupabase } from "@/lib/supabase";
import { codeToSlug } from "@/lib/hotel-utils";

const payloadSchema = z.object({
  email: z.string().email("Email invalide"),
  password: z.string().min(1, "Mot de passe requis"),
  hotelCode: z.string().min(2, "Code hôtel requis")
});

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const parsed = payloadSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(
      { errors: parsed.error.flatten().fieldErrors },
      { status: 400 }
    );
  }

  const { email, password, hotelCode } = parsed.data;
  const anonSupabase = getAnonSupabase();
  const serviceSupabase = getServiceSupabase();

  try {
    const signIn = await anonSupabase.auth.signInWithPassword({ email, password });

    if (signIn.error || !signIn.data.session || !signIn.data.user) {
      return NextResponse.json(
        {
          success: false,
          message: signIn.error?.message ?? "Identifiants invalides"
        },
        { status: 401 }
      );
    }

    const userId = signIn.data.user.id;
    const slug = codeToSlug(hotelCode);

    const hotelQuery = await serviceSupabase
      .from("hotels")
      .select("id, name, slug, settings")
      .eq("slug", slug)
      .single();

    if (hotelQuery.error || !hotelQuery.data) {
      return NextResponse.json(
        {
          success: false,
          message: "Code hôtel invalide"
        },
        { status: 404 }
      );
    }

    const hotelId = hotelQuery.data.id;

    const roleQuery = await serviceSupabase
      .from("user_roles")
      .select(
        `role_id,
        roles:roles(code)`
      )
      .eq("hotel_id", hotelId)
      .eq("user_id", userId)
      .single();

    if (roleQuery.error || !roleQuery.data) {
      return NextResponse.json(
        {
          success: false,
          message: "Vous n'avez pas accès à cet hôtel"
        },
        { status: 403 }
      );
    }

    return NextResponse.json(
      {
        success: true,
        message: "Connexion réussie",
        hotel: {
          id: hotelId,
          name: hotelQuery.data.name,
          code: hotelQuery.data.settings?.code ?? hotelQuery.data.slug
        },
        role: roleQuery.data.roles?.code ?? "staff",
        session: {
          access_token: signIn.data.session.access_token,
          refresh_token: signIn.data.session.refresh_token,
          expires_at: signIn.data.session.expires_at
        }
      },
      { status: 200 }
    );
  } catch (error) {
    console.error("login error", error);
    return NextResponse.json(
      {
        success: false,
        message: "Erreur inattendue lors de la connexion"
      },
      { status: 500 }
    );
  }
}
