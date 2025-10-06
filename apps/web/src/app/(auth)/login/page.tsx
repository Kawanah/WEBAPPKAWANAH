import { LoginForm } from "@/components/auth/login-form";

export default function LoginPage() {
  return (
    <main className="flex min-h-screen flex-col items-center bg-neutral-200 px-4 py-12">
      <header className="mb-10 w-full max-w-5xl">
        <div className="h-12 w-40 rounded-md bg-neutral-300" aria-hidden />
      </header>
      <LoginForm />
    </main>
  );
}
