import { NextResponse } from "next/server";
import { z } from "zod";
import { getServiceSupabase } from "@/lib/supabase";
import { generateHotelIdentifiers } from "@/lib/hotel-utils";

const payloadSchema = z.object({
  fullName: z.string().min(2, "Nom complet requis"),
  hotelName: z.string().min(2, "Nom de l'hôtel requis"),
  email: z.string().email("Email invalide"),
  password: z.string().min(8, "Mot de passe trop court")
});

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const parsed = payloadSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(
      {
        errors: parsed.error.flatten().fieldErrors
      },
      { status: 400 }
    );
  }

  const { fullName, hotelName, email, password } = parsed.data;
  const supabase = getServiceSupabase();
  const { slug, code } = generateHotelIdentifiers(hotelName);

  let userId: string | null = null;
  let hotelId: string | null = null;

  try {
    const createUser = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: fullName
      }
    });

    if (createUser.error || !createUser.data.user) {
      throw new Error(createUser.error?.message ?? "Impossible de créer l'utilisateur");
    }

    userId = createUser.data.user.id;

    const hotelInsert = await supabase
      .from("hotels")
      .insert({
        name: hotelName,
        slug,
        timezone: "UTC",
        settings: { code }
      })
      .select("id")
      .single();

    if (hotelInsert.error || !hotelInsert.data) {
      throw new Error(hotelInsert.error?.message ?? "Impossible de créer l'hôtel");
    }

    hotelId = hotelInsert.data.id;

    const staffInsert = await supabase
      .from("staff_profiles")
      .insert({
        hotel_id: hotelId,
        user_id: userId,
        full_name: fullName,
        email
      })
      .select("id")
      .single();

    if (staffInsert.error || !staffInsert.data) {
      throw new Error(staffInsert.error?.message ?? "Impossible de créer le profil staff");
    }

    const roleQuery = await supabase
      .from("roles")
      .select("id")
      .eq("code", "admin")
      .single();

    if (roleQuery.error || !roleQuery.data) {
      throw new Error("Rôle admin introuvable. Vérifiez les seeds Supabase.");
    }

    const roleInsert = await supabase.from("user_roles").insert({
      hotel_id: hotelId,
      user_id: userId,
      role_id: roleQuery.data.id
    });

    if (roleInsert.error) {
      throw new Error(roleInsert.error.message);
    }

    return NextResponse.json(
      {
        success: true,
        message: "Compte administrateur créé",
        hotelCode: code
      },
      { status: 201 }
    );
  } catch (error) {
    console.error("register error", error);

    if (userId) {
      await supabase.auth.admin.deleteUser(userId);
    }

    if (hotelId) {
      await supabase.from("hotels").delete().eq("id", hotelId);
    }

    return NextResponse.json(
      {
        success: false,
        message:
          error instanceof Error ? error.message : "Erreur inattendue lors de l'inscription"
      },
      { status: 500 }
    );
  }
}
