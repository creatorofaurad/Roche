import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ROCHE — Bare-Silicon Formal EVM Invariant Verifier",
  description: "A high-throughput formal invariant verifier and state fuzzer for the Ethereum Virtual Machine. Zero-allocation bare-silicon runtime written in Zig 0.16.0.",
  icons: {
    icon: "/icon.svg",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="h-full antialiased bg-[#0A0908]">
      <body className="min-h-full flex flex-col bg-[#0A0908] text-[#F4EBD9] selection:bg-[#C5A059] selection:text-[#0A0908]">
        {children}
      </body>
    </html>
  );
}
