import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "ROCHE :: Zero-Allocation EVM Invariant Engine",
  description: "Bare-silicon EVM invariant prover and real-time security engine. 118,000+ executions/sec, zero dynamic heap allocations.",
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
    <html lang="en" style={{ backgroundColor: "#0a0e27" }}>
      <head>
        <style dangerouslySetInnerHTML={{
          __html: `
            @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;700&display=swap');
            * { box-sizing: border-box; margin: 0; padding: 0; }
            html, body {
              background-color: #0a0e27 !important;
              color: #ffffff;
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
              line-height: 1.5;
            }
          `
        }} />
      </head>
      <body style={{ backgroundColor: "#0a0e27", margin: 0, padding: 0 }}>
        {children}
      </body>
    </html>
  );
}
