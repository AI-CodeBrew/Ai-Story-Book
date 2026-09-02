import type { Metadata } from "next";
import { Inter, Baloo_2, JetBrains_Mono } from "next/font/google";
import "./globals.css";
import { VisitTracker } from "@/components/VisitTracker";

const inter = Inter({ variable: "--font-inter", subsets: ["latin"] });
const baloo = Baloo_2({ variable: "--font-baloo", subsets: ["latin"], weight: ["500", "600", "700", "800"] });
const jetbrainsMono = JetBrains_Mono({ variable: "--font-jetbrains", subsets: ["latin"], weight: ["400", "500"] });

export const metadata: Metadata = {
  title: "StoryBook AI — Magical AI Storybooks in Seconds",
  description:
    "Generate illustrated, narrated children's stories with AI. Pick a theme, add a prompt, and get a shareable storybook with audio narration and a downloadable PDF.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${baloo.variable} ${jetbrainsMono.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col bg-[var(--void)] text-[var(--foreground)]">
        <VisitTracker />
        {children}
      </body>
    </html>
  );
}
