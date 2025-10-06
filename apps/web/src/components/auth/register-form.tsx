"use client";

import { useState, FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { User, Building2, Mail, Lock, CheckCircle2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export function RegisterForm() {
  const router = useRouter();
  const [fullName, setFullName] = useState("");
  const [hotelName, setHotelName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [hotelCode, setHotelCode] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(null);
    setHotelCode(null);

    try {
      const response = await fetch("/api/auth/register", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ fullName, hotelName, email, password })
      });

      const result = await response.json();

      if (!response.ok) {
        const fieldErrors = result?.errors;
        if (fieldErrors && typeof fieldErrors === "object") {
          const firstError = Object.values(fieldErrors).flat().filter(Boolean)[0];
          setError((firstError as string) ?? result.message ?? "Inscription impossible");
        } else {
          setError(result.message ?? "Inscription impossible");
        }
        return;
      }

      setSuccess(result.message ?? "Compte créé avec succès");
      setHotelCode(result.hotelCode ?? null);

      setTimeout(() => {
        router.push("/login");
      }, 2000);
    } catch (err) {
      console.error(err);
      setError("Erreur réseau inattendue");
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="w-full max-w-[420px] rounded-2xl bg-white shadow-lg ring-1 ring-neutral-300">
      <div className="flex flex-col gap-6 px-6 pb-10 pt-8">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-neutral-900">Inscription</h1>
          <p className="mt-2 text-base text-neutral-600">
            Créez votre compte hôtel (Accès Administrateur)
          </p>
        </div>

        {error ? (
          <div className="rounded-lg border border-danger/30 bg-danger/10 p-3 text-sm text-danger">
            {error}
          </div>
        ) : null}

        {success ? (
          <div className="flex items-start gap-3 rounded-lg border border-success/30 bg-success/10 p-3 text-sm text-success">
            <CheckCircle2 className="mt-0.5 h-5 w-5" aria-hidden />
            <div>
              <p>{success}</p>
              {hotelCode ? (
                <p className="mt-1 text-xs text-success/80">
                  Code hôtel à conserver : <span className="font-semibold">{hotelCode}</span>
                </p>
              ) : null}
            </div>
          </div>
        ) : null}

        <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
          <label className="space-y-2 text-sm font-medium text-neutral-900">
            <span>Nom complet</span>
            <Input
              name="fullName"
              placeholder="Votre nom"
              leftIcon={<User size={18} className="text-neutral-500" />}
              autoComplete="name"
              required
              value={fullName}
              onChange={(event) => setFullName(event.target.value)}
            />
          </label>

          <label className="space-y-2 text-sm font-medium text-neutral-900">
            <span>Nom de l&apos;hôtel</span>
            <Input
              name="hotelName"
              placeholder="Nom de votre hôtel"
              leftIcon={<Building2 size={18} className="text-neutral-500" />}
              autoComplete="organization"
              required
              value={hotelName}
              onChange={(event) => setHotelName(event.target.value)}
            />
          </label>

          <label className="space-y-2 text-sm font-medium text-neutral-900">
            <span>Email</span>
            <Input
              type="email"
              name="email"
              placeholder="votre@email.com"
              leftIcon={<Mail size={18} className="text-neutral-500" />}
              autoComplete="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
          </label>

          <label className="space-y-2 text-sm font-medium text-neutral-900">
            <span>Mot de passe</span>
            <Input
              type="password"
              name="password"
              placeholder="••••••••"
              leftIcon={<Lock size={18} className="text-neutral-500" />}
              autoComplete="new-password"
              required
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </label>

          <Button type="submit" className="mt-2 h-11 w-full" disabled={loading}>
            {loading ? "Création..." : "Créer le compte"}
          </Button>
        </form>

        <div className="text-center text-sm">
          <Link href="/login" className="font-medium text-primary hover:underline">
            Déjà inscrit ? Connectez-vous
          </Link>
        </div>
      </div>
    </section>
  );
}
