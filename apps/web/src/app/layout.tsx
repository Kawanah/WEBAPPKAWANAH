import type { Metadata } from "next";
import "./globals.css";
import { inter } from "@/lib/fonts";

export const metadata: Metadata = {
  title: "Kawanah Console",
  description: "Tableau de bord hébergeur Kawanah"
};

export default function RootLayout({
  children
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="fr" className={inter.variable}>
      <body className="min-h-screen bg-neutral-200 text-neutral-900 antialiased">
        {children}
      </body>
    </html>
  );
}
