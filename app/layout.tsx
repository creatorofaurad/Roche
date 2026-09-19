import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Roche — Bare-Silicon EVM Invariant Prover by Charles",
  description:
    "Zero-allocation bare-silicon EVM invariant verification engine in Zig 0.16. Built by Charles (Age 15). 1.84M SIMD execs/sec, SMT array theory solvency proofs in < 2µs.",
  keywords: [
    "Roche",
    "Charles",
    "EVM Invariant",
    "Formal Verification",
    "SMT Solver",
    "Zig EVM",
    "DeFi Security",
    "Smart Contract Audit",
  ],
  authors: [{ name: "Charles" }],
  openGraph: {
    title: "Roche — Bare-Silicon EVM Invariant Prover",
    description:
      "Zero-allocation bare-silicon EVM invariant verification engine. Built by Charles (Age 15).",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased bg-black`}
    >
      <body className="min-h-full flex flex-col bg-black text-white">{children}</body>
    </html>
  );
}
