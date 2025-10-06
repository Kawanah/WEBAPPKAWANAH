"use client";

import { useState, FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Mail, Lock, Building2, AlertTriangle, ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

const demoAccounts = [
  {
    label: "Admin",
    credentials: "admin@moderne.fr / admin123",
    hotel: "MODERNE",
    email: "admin@moderne.fr",
    password: "admin123",
    hotelCode: "MODERNE"
  },
  {
    label: "Réception",
    credentials: "reception@moderne.fr / reception123",
    hotel: "MODERNE",
    email: "reception@moderne.fr",
    password: "reception123",
    hotelCode: "MODERNE"
  },
  {
    label: "Manager",
    credentials: "manager@palace.fr / manager123",
    hotel: "PALACE",
    email: "manager@palace.fr",
    password: "manager123",
    hotelCode: "PALACE"
  }
];

export function LoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [hotelCode, setHotelCode] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ email, password, hotelCode })
      });

      const result = await response.json();

      if (!response.ok) {
        setError(result.message ?? "Impossible de se connecter");
        return;
      }

      setSuccess(result.message ?? "Connexion réussie");

      if (typeof window !== "undefined") {
        window.localStorage.setItem("kawanah.session", JSON.stringify(result.session));
        window.localStorage.setItem("kawanah.hotel", JSON.stringify(result.hotel));
        window.localStorage.setItem("kawanah.role", result.role ?? "staff");
      }

      setTimeout(() => {
        router.push("/dashboard");
      }, 1500);
    } catch (err) {
      console.error(err);
      setError("Erreur réseau inattendue");
    } finally {
      setLoading(false);
    }
  };

  const handleDemoLogin = (data = demoAccounts[0]) => {
    setEmail(data.email);
    setPassword(data.password);
    setHotelCode(data.hotelCode);
  };

  return (
    <section className="relative w-full max-w-[420px] rounded-2xl bg-white shadow-lg ring-1 ring-neutral-300">
      <div className="flex flex-col gap-6 px-6 pb-10 pt-8">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-neutral-900">Connexion</h1>
          <p className="mt-1 text-base text-neutral-600">
            Connectez-vous à votre tableau de bord hôtel
          </p>
        </div>

        {error ? (
          <div className="rounded-lg border border-danger/30 bg-danger/10 p-3 text-sm text-danger">
            {error}
          </div>
        ) : null}

        {success ? (
          <div className="rounded-lg border border-success/30 bg-success/10 p-3 text-sm text-success">
            {success}
          </div>
        ) : null}

        <form className="flex flex-col gap-4" onSubmit={handleSubmit}>
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
              autoComplete="current-password"
              required
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </label>

          <label className="space-y-2 text-sm font-medium text-neutral-900">
            <span>Code hôtel</span>
            <div className="space-y-2">
              <Input
                name="hotelCode"
                placeholder="MODERNE-1234"
                leftIcon={<Building2 size={18} className="text-neutral-500" />}
                required
                value={hotelCode}
                onChange={(event) => setHotelCode(event.target.value)}
              />
              <p className="text-xs text-neutral-500">
                Code fourni lors de l&apos;inscription de votre hôtel
              </p>
            </div>
          </label>

          <Button type="submit" className="mt-2 h-11 w-full" disabled={loading}>
            {loading ? "Connexion..." : "Se connecter"}
          </Button>
        </form>

        <div className="text-center text-sm">
          <Link href="/register" className="font-medium text-primary hover:underline">
            Nouveau hôtel ? Créez votre compte
          </Link>
        </div>

        <div className="space-y-3 rounded-xl border-2 border-[#FEE685] bg-[#FFFBEB] p-4">
          <div className="flex items-center gap-3">
            <AlertTriangle className="h-5 w-5 text-[#973C00]" aria-hidden />
            <p className="text-sm font-medium text-[#973C00]">
              Connexion Admin Rapide (MODERNE)
            </p>
          </div>
          <p className="text-center text-xs text-[#BB4D00]">
            Accès direct compte administrateur
          </p>
          <Button
            type="button"
            variant="secondary"
            className="w-full border-[#973C00] text-[#973C00] hover:bg-[#973C00]/10"
            disabled={loading}
            onClick={() => handleDemoLogin()}
          >
            Préremplir les identifiants
          </Button>
        </div>

        <div className="rounded-xl bg-[#EFF6FF] p-4">
          <p className="text-sm font-medium text-[#193CB8]">Comptes de démonstration :</p>
          <ul className="mt-3 space-y-2 text-xs text-[#1447E6]">
            {demoAccounts.map((account) => (
              <li key={account.credentials} className="flex items-start gap-2">
                <ArrowRight className="mt-0.5 h-4 w-4" aria-hidden />
                <button
                  type="button"
                  className="text-left underline-offset-2 hover:underline"
                  onClick={() => handleDemoLogin(account)}
                  disabled={loading}
                >
                  {account.label}: {account.credentials} ({account.hotel})
                </button>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
