import Link from "next/link";

export default function HomePage() {
  return (
    <main className="flex min-h-screen items-center justify-center p-6">
      <div className="max-w-md rounded-xl bg-white p-8 shadow-md">
        <h1 className="text-2xl font-bold text-neutral-900">Bienvenue sur Kawanah</h1>
        <p className="mt-2 text-neutral-600">
          Accédez au tableau de bord hébergeur ou créez un nouveau compte administrateur.
        </p>
        <div className="mt-6 flex flex-col gap-3">
          <Link
            href="/login"
            className="rounded-lg bg-primary px-4 py-2 text-center text-sm font-medium text-white hover:bg-primary/90"
          >
            Connexion staff
          </Link>
          <Link
            href="/register"
            className="rounded-lg border border-primary px-4 py-2 text-center text-sm font-medium text-primary hover:bg-primary/10"
          >
            Créer un compte hôtel
          </Link>
        </div>
      </div>
    </main>
  );
}
