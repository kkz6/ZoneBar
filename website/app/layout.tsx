import type { Metadata } from "next";
import { IBM_Plex_Mono, Manrope } from "next/font/google";
import "./globals.css";

const manrope = Manrope({
  variable: "--font-manrope",
  subsets: ["latin"],
});

const plexMono = IBM_Plex_Mono({
  variable: "--font-plex-mono",
  weight: ["400", "500", "600"],
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://zonebar.karti.dev"),
  title: "ZoneBar — World clocks, beautifully close",
  description:
    "A lightweight native macOS menu bar app for world clocks and effortless timezone coordination.",
  icons: {
    icon: "/zonebar-icon.png",
    shortcut: "/zonebar-icon.png",
  },
  openGraph: {
    title: "ZoneBar — Your team’s time, right on time",
    description:
      "Native world clocks and effortless timezone coordination, right in your macOS menu bar.",
    type: "website",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "ZoneBar world clock app for macOS",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "ZoneBar — Your team’s time, right on time",
    description: "Native world clocks for macOS.",
    images: ["/og.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${manrope.variable} ${plexMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
