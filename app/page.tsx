import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import FounderSection from "@/components/FounderSection";
import GrantDossier from "@/components/GrantDossier";
import FeaturesBento from "@/components/FeaturesBento";
import ComparisonSection from "@/components/ComparisonSection";
import FAQ from "@/components/FAQ";
import BottomCTA from "@/components/BottomCTA";

export default function Home() {
  return (
    <main className="min-h-screen bg-black text-zinc-100 selection:bg-emerald-950 selection:text-emerald-300">
      <Navbar />
      <Hero />
      <FounderSection />
      <GrantDossier />
      <FeaturesBento />
      <ComparisonSection />
      <FAQ />
      <BottomCTA />
    </main>
  );
}
