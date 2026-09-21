"use client";

import React, { useEffect, useMemo, useRef, useState } from "react";
import { motion, useScroll, useTransform, useSpring, AnimatePresence } from "framer-motion";

/* ═══════════════════════════════════════════════════════════════════════════
   PALETTE — THE COLOR CREED
   ═══════════════════════════════════════════════════════════════════════════ */
const C = {
  obsidian: "#0A0908",
  charcoal: "#141210",
  iron: "#1C1916",
  gold: "#C5A059",
  brass: "#D4AF37",
  goldDim: "rgba(197,160,89,0.32)",
  goldFaint: "rgba(197,160,89,0.12)",
  parchment: "#F4EBD9",
  vellum: "#E5D9C3",
  lapis: "#1B3B6F",
  lapisLit: "#2C5AA0",
  crimson: "#7A1C1C",
  crimsonLit: "#A82E2E",
  ash: "#8A8175",
};

const SERIF = `'Cormorant Garamond', 'EB Garamond', Georgia, serif`;
const SC = `'Cormorant SC', 'Cormorant Garamond', Georgia, serif`;
const MONO = `'JetBrains Mono', ui-monospace, monospace`;

/* ═══════════════════════════════════════════════════════════════════════════
   E8 ROOT SYSTEM — genuine Coxeter-plane projection, computed at module load
   ═══════════════════════════════════════════════════════════════════════════ */
const E8_CARTAN: number[][] = [
  [2, -1, 0, 0, 0, 0, 0, 0],
  [-1, 2, -1, 0, 0, 0, 0, 0],
  [0, -1, 2, -1, 0, 0, 0, 0],
  [0, 0, -1, 2, -1, 0, 0, 0],
  [0, 0, 0, -1, 2, -1, 0, -1],
  [0, 0, 0, 0, -1, 2, -1, 0],
  [0, 0, 0, 0, 0, -1, 2, 0],
  [0, 0, 0, 0, -1, 0, 0, 2],
];

const matVec8 = (M: number[][], v: number[]): number[] =>
  M.map((row) => row.reduce((acc, mij, j) => acc + mij * v[j], 0));

const unit8 = (v: number[]): number[] => {
  const mag = Math.sqrt(v.reduce((a, x) => a + x * x, 0)) || 1;
  return v.map((x) => x / mag);
};

/** Power iteration on B = 4I − A converges to the *smallest* eigenvalue of A. */
const powerIterate = (M: number[][], banned: number[][], iters: number): number[] => {
  let vec = unit8(Array.from({ length: 8 }, (_, i) => Math.sin(i * 1.7 + 0.3)));
  for (let step = 0; step < iters; step++) {
    let next = matVec8(M, vec);
    for (const prior of banned) {
      const dot = next.reduce((s, x, i) => s + x * prior[i], 0);
      next = next.map((x, i) => x - dot * prior[i]);
    }
    vec = unit8(next);
  }
  return vec;
};

const buildE8Projection = () => {
  // B = 4I − A  →  dominant eigenvector of B is the lowest eigenvector of A
  const B = E8_CARTAN.map((row, i) => row.map((v, j) => (i === j ? 4 - v : -v)));
  const axisU = powerIterate(B, [], 900);
  const axisV = powerIterate(B, [axisU], 900);

  const roots: number[][] = [];
  // 112 roots: permutations of (±1, ±1, 0,0,0,0,0,0)
  for (let p = 0; p < 8; p++) {
    for (let q = p + 1; q < 8; q++) {
      for (const sp of [1, -1]) {
        for (const sq of [1, -1]) {
          const r = new Array(8).fill(0);
          r[p] = sp;
          r[q] = sq;
          roots.push(r);
        }
      }
    }
  }
  // 128 roots: (±½)^8 with an even count of negative signs
  for (let mask = 0; mask < 256; mask++) {
    let negCount = 0;
    for (let b = 0; b < 8; b++) if (mask & (1 << b)) negCount++;
    if (negCount % 2 === 0) {
      roots.push(Array.from({ length: 8 }, (_, b) => (mask & (1 << b) ? -0.5 : 0.5)));
    }
  }

  return roots.map((r) => ({
    x: r.reduce((s, ri, i) => s + ri * axisU[i], 0),
    y: r.reduce((s, ri, i) => s + ri * axisV[i], 0),
    kind: r[0] === 0.5 || r[0] === -0.5 ? "spinor" : "vector",
  }));
};

const E8_ROOTS = buildE8Projection();

/* ═══════════════════════════════════════════════════════════════════════════
   ORNAMENT — copperplate furniture
   ═══════════════════════════════════════════════════════════════════════════ */
const Fleuron: React.FC<{ size?: number; tone?: string }> = ({ size = 22, tone = C.gold }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden>
    <path d="M12 1.6 L14.1 9.9 L22.4 12 L14.1 14.1 L12 22.4 L9.9 14.1 L1.6 12 L9.9 9.9 Z"
      stroke={tone} strokeWidth="0.55" fill="none" />
    <circle cx="12" cy="12" r="2.5" stroke={tone} strokeWidth="0.55" fill="none" />
    <circle cx="12" cy="12" r="0.85" fill={tone} />
  </svg>
);

const CornerAcanthus: React.FC<{ rot: number; size?: number }> = ({ rot, size = 96 }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" fill="none"
    style={{ transform: `rotate(${rot}deg)` }} aria-hidden>
    <path d="M2 2 L34 2 M2 2 L2 34" stroke={C.gold} strokeWidth="0.7" opacity="0.85" />
    <path d="M6 6 L28 6 M6 6 L6 28" stroke={C.gold} strokeWidth="0.4" opacity="0.45" />
    <path d="M6 6 Q22 8 30 22 Q26 12 6 6 Z" stroke={C.gold} strokeWidth="0.5"
      fill={C.gold} fillOpacity="0.07" />
    <path d="M10 10 Q24 12 34 30" stroke={C.gold} strokeWidth="0.4" opacity="0.5" fill="none" />
    <path d="M10 10 Q12 24 30 34" stroke={C.gold} strokeWidth="0.4" opacity="0.5" fill="none" />
    <circle cx="10" cy="10" r="1.7" fill={C.gold} opacity="0.9" />
    <circle cx="21" cy="21" r="0.9" fill={C.gold} opacity="0.6" />
  </svg>
);

const RuleDouble: React.FC<{ label?: string; tone?: string }> = ({ label, tone = C.gold }) => (
  <div className="flex items-center gap-4 w-full select-none">
    <div className="flex-1 h-px" style={{ background: `linear-gradient(90deg,transparent,${tone}66)` }} />
    <div className="flex items-center gap-2">
      <div className="h-px w-8" style={{ background: `${tone}55` }} />
      {label && (
        <span className="font-mono text-[9px] tracking-[0.34em] uppercase" style={{ color: tone }}>
          {label}
        </span>
      )}
      <div className="h-px w-8" style={{ background: `${tone}55` }} />
    </div>
    <div className="flex-1 h-px" style={{ background: `linear-gradient(270deg,transparent,${tone}66)` }} />
  </div>
);

/* ═══════════════════════════════════════════════════════════════════════════
   PLATE FRAME — the treatise border every diagram lives inside
   ═══════════════════════════════════════════════════════════════════════════ */
const Plate: React.FC<{
  numeral: string; title: string; latin: string; children: React.ReactNode;
  caption?: React.ReactNode;
}> = ({ numeral, title, latin, children, caption }) => (
  <motion.figure
    initial={{ opacity: 0, y: 34 }}
    whileInView={{ opacity: 1, y: 0 }}
    viewport={{ once: true, margin: "-80px" }}
    transition={{ duration: 1.05, ease: [0.16, 1, 0.3, 1] }}
    className="relative w-full"
  >
    <div className="relative p-[3px]" style={{
      background: `linear-gradient(150deg,${C.gold}55,${C.gold}11 40%,${C.gold}33 70%,${C.gold}08)`,
    }}>
      <div className="relative bg-[#0A0908] p-6 sm:p-10 lg:p-14" style={{
        boxShadow: `inset 0 0 120px rgba(0,0,0,0.9), 0 0 80px rgba(0,0,0,0.6)`,
      }}>
        {/* corner furniture */}
        <div className="absolute top-2 left-2"><CornerAcanthus rot={0} size={62} /></div>
        <div className="absolute top-2 right-2"><CornerAcanthus rot={90} size={62} /></div>
        <div className="absolute bottom-2 right-2"><CornerAcanthus rot={180} size={62} /></div>
        <div className="absolute bottom-2 left-2"><CornerAcanthus rot={270} size={62} /></div>

        <header className="text-center mb-8 relative z-10">
          <div className="font-mono text-[9px] tracking-[0.42em] uppercase mb-3"
            style={{ color: C.brass }}>
            Tabvla {numeral}
          </div>
          <h3 className="font-serif text-[clamp(1.5rem,3.4vw,2.6rem)] leading-[1.05] tracking-[0.02em]"
            style={{ color: C.parchment, fontWeight: 300 }}>
            {title}
          </h3>
          <div className="font-serif italic text-[13px] mt-2" style={{ color: C.gold }}>
            {latin}
          </div>
          <div className="mt-5 mx-auto w-40"><RuleDouble /></div>
        </header>

        <div className="relative z-10">{children}</div>

        {caption && (
          <figcaption className="relative z-10 mt-8 pt-6 border-t"
            style={{ borderColor: C.goldFaint }}>
            {caption}
          </figcaption>
        )}
      </div>
    </div>
  </motion.figure>
);

/* ═══════════════════════════════════════════════════════════════════════════
   ARMILLARY SPHERE — hero backdrop, scroll-driven
   ═══════════════════════════════════════════════════════════════════════════ */
const Armillary: React.FC<{ spin: number }> = ({ spin }) => {
  const rings = useMemo(() => [
    { rx: 250, ry: 250, rot: 0, w: 1.1, o: 0.55 },
    { rx: 250, ry: 96, rot: 0, w: 0.9, o: 0.42 },
    { rx: 250, ry: 96, rot: 60, w: 0.9, o: 0.34 },
    { rx: 250, ry: 96, rot: 120, w: 0.9, o: 0.34 },
    { rx: 200, ry: 200, rot: 0, w: 0.6, o: 0.28 },
    { rx: 200, ry: 66, rot: 30, w: 0.6, o: 0.24 },
    { rx: 200, ry: 66, rot: -30, w: 0.6, o: 0.24 },
    { rx: 300, ry: 300, rot: 0, w: 0.45, o: 0.16 },
    { rx: 150, ry: 150, rot: 0, w: 0.5, o: 0.22 },
  ], []);

  const ticks = Array.from({ length: 72 }, (_, i) => i);

  return (
    <svg viewBox="-360 -360 720 720" className="w-full h-full" aria-hidden
      style={{ transform: `rotate(${spin}deg)` }}>
      <defs>
        <radialGradient id="brassGlow" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor={C.brass} stopOpacity="0.34" />
          <stop offset="42%" stopColor={C.gold} stopOpacity="0.11" />
          <stop offset="100%" stopColor={C.gold} stopOpacity="0" />
        </radialGradient>
        <linearGradient id="ringBrass" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={C.brass} />
          <stop offset="50%" stopColor={C.gold} />
          <stop offset="100%" stopColor="#8A6B32" />
        </linearGradient>
      </defs>

      <circle cx="0" cy="0" r="340" fill="url(#brassGlow)" />

      {/* degree ring */}
      <circle cx="0" cy="0" r="322" fill="none" stroke={C.gold} strokeWidth="0.5" opacity="0.3" />
      <circle cx="0" cy="0" r="312" fill="none" stroke={C.gold} strokeWidth="0.5" opacity="0.2" />
      {ticks.map((i) => {
        const major = i % 6 === 0;
        const a = (i / 72) * Math.PI * 2;
        const r0 = major ? 302 : 308;
        return (
          <line key={i} x1={Math.cos(a) * r0} y1={Math.sin(a) * r0}
            x2={Math.cos(a) * 312} y2={Math.sin(a) * 312}
            stroke={C.gold} strokeWidth={major ? 0.9 : 0.45}
            opacity={major ? 0.6 : 0.3} />
        );
      })}

      {rings.map((r, i) => (
        <ellipse key={i} cx="0" cy="0" rx={r.rx} ry={r.ry}
          transform={`rotate(${r.rot + spin * (i % 3 === 0 ? 0.14 : -0.08)})`}
          fill="none" stroke="url(#ringBrass)" strokeWidth={r.w} opacity={r.o} />
      ))}

      {/* ecliptic band with zodiacal divisions */}
      <g transform={`rotate(${spin * 0.2})`}>
        <ellipse cx="0" cy="0" rx="252" ry="98" fill="none" stroke={C.gold}
          strokeWidth="13" opacity="0.045" />
        {Array.from({ length: 24 }, (_, i) => {
          const a = (i / 24) * Math.PI * 2;
          const px = Math.cos(a) * 252;
          const py = Math.sin(a) * 98;
          return <line key={i} x1={px * 0.945} y1={py * 0.945} x2={px * 1.055} y2={py * 1.055}
            stroke={C.gold} strokeWidth="0.5" opacity="0.34" />;
        })}
      </g>

      {/* earth at centre */}
      <circle cx="0" cy="0" r="26" fill="#0A0908" stroke={C.brass} strokeWidth="1.1" />
      <circle cx="0" cy="0" r="26" fill="none" stroke={C.gold} strokeWidth="0.4" opacity="0.5"
        strokeDasharray="1 3" />
      <circle cx="0" cy="0" r="4" fill={C.brass} opacity="0.85" />
      <circle cx="-8" cy="-8" r="9" fill={C.brass} opacity="0.09" />

      {/* axis */}
      <line x1="0" y1="-338" x2="0" y2="338" stroke={C.gold} strokeWidth="0.7" opacity="0.4" />
      <polygon points="0,-344 -4,-334 4,-334" fill={C.brass} opacity="0.7" />
      <polygon points="0,344 -4,334 4,334" fill={C.brass} opacity="0.7" />
    </svg>
  );
};

/* ═══════════════════════════════════════════════════════════════════════════
   PLATE I — THE ROCHE LIMIT
   ═══════════════════════════════════════════════════════════════════════════ */
const PlateRocheLimit: React.FC = () => {
  const [phase, setPhase] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setPhase((p) => (p + 1) % 100), 55);
    return () => clearInterval(id);
  }, []);

  const RHO_M = 5.51, RHO_m = 0.62;
  const Rp = 52;
  const limit = Rp * Math.cbrt((2 * RHO_M) / RHO_m);
  const t = phase / 100;
  const dist = 240 - t * 130;
  const breached = dist <= limit;
  const cx = 178, cy = 168;
  const sx = cx + dist, sy = cy;
  const stress = Math.pow(limit / Math.max(dist, 1), 3);

  const debris = useMemo(
    () => Array.from({ length: 96 }, (_, i) => {
      const a = (i / 96) * Math.PI * 2;
      const rr = limit + 8 + (i % 5) * 6;
      return { a, r: rr, i };
    }), []);

  return (
    <Plate numeral="I" title="The Roche Limit — Tidal Disintegration"
      latin="Vbi cohæsio gravitatis viribvs maris cvmbit"
      caption={
        <div className="grid md:grid-cols-[1fr_auto] gap-6 items-end">
          <p className="font-serif italic text-[15px] leading-relaxed" style={{ color: C.vellum }}>
            The precise radial boundary at which a body's internal gravitational cohesion is
            overwhelmed by the tidal pull of a greater mass. Disintegration is not probabilistic —
            it is a closed-form certainty.
          </p>
          <div className="font-mono text-[10px] leading-[1.9] text-right"
            style={{ color: breached ? C.crimsonLit : C.gold }}>
            <div>d = {dist.toFixed(1)} R</div>
            <div>limit = {limit.toFixed(2)} R</div>
            <div>σ = {stress.toFixed(3)}</div>
            <div className="tracking-[0.2em]">{breached ? "DISINTEGRATIO" : "COHÆSIO"}</div>
          </div>
        </div>
      }>

      <div className="w-full overflow-hidden" style={{
        background: `radial-gradient(ellipse 70% 60% at 22% 50%, rgba(197,160,89,0.09), transparent 70%), #080706`,
        border: `1px solid ${C.goldFaint}`,
      }}>
        <svg viewBox="0 0 720 336" className="w-full h-auto block">
          <defs>
            <radialGradient id="primaryBody" cx="34%" cy="32%">
              <stop offset="0%" stopColor="#FFE9B8" />
              <stop offset="26%" stopColor={C.brass} />
              <stop offset="62%" stopColor="#8A6220" />
              <stop offset="100%" stopColor="#2A1E0A" />
            </radialGradient>
            <radialGradient id="primaryHalo" cx="50%" cy="50%">
              <stop offset="0%" stopColor={C.brass} stopOpacity="0.30" />
              <stop offset="45%" stopColor={C.gold} stopOpacity="0.09" />
              <stop offset="100%" stopColor={C.gold} stopOpacity="0" />
            </radialGradient>
            <radialGradient id="satBody" cx="36%" cy="32%">
              <stop offset="0%" stopColor={C.vellum} />
              <stop offset="60%" stopColor="#6E6355" />
              <stop offset="100%" stopColor="#1A1613" />
            </radialGradient>
            <pattern id="hatchEngrave" width="5" height="5"
              patternTransform="rotate(45)" patternUnits="userSpaceOnUse">
              <line x1="0" y1="0" x2="0" y2="5" stroke={C.gold} strokeWidth="0.4" opacity="0.2" />
            </pattern>
          </defs>

          {/* engraved background hatching */}
          <rect x="0" y="0" width="720" height="336" fill="url(#hatchEngrave)" opacity="0.35" />

          <circle cx={cx} cy={cy} r="180" fill="url(#primaryHalo)" />

          {/* Roche limit circle */}
          <circle cx={cx} cy={cy} r={limit} fill="none"
            stroke={breached ? C.crimsonLit : C.gold} strokeWidth="0.9"
            strokeDasharray="5 6" opacity={breached ? 0.9 : 0.6} />

          {/* orbital path */}
          <ellipse cx={cx} cy={cy} rx={dist} ry={dist} fill="none"
            stroke={C.gold} strokeWidth="0.4" opacity="0.22" strokeDasharray="2 4" />

          {/* radial measurement */}
          <line x1={cx} y1={cy} x2={sx} y2={sy} stroke={C.brass} strokeWidth="0.6" opacity="0.7" />
          <line x1={cx} y1={cy - 5} x2={cx} y2={cy + 5} stroke={C.brass} strokeWidth="0.8" />
          <line x1={sx} y1={sy - 5} x2={sx} y2={sy + 5} stroke={C.brass} strokeWidth="0.8" />
          <text x={(cx + sx) / 2} y={cy - 9} textAnchor="middle" fontFamily={MONO}
            fontSize="8.5" fill={C.brass} letterSpacing="1.4">d</text>

          {/* primary */}
          <circle cx={cx} cy={cy} r={Rp} fill="url(#primaryBody)" />
          <circle cx={cx} cy={cy} r={Rp} fill="none" stroke={C.brass} strokeWidth="0.6" opacity="0.6" />
          <text x={cx} y={cy + Rp + 16} textAnchor="middle" fontFamily={SERIF}
            fontSize="11" fontStyle="italic" fill={C.gold}>Protocollvm</text>

          {/* secondary — elongates then shatters */}
          {!breached && (
            <g>
              <ellipse cx={sx} cy={sy} rx={13 + stress * 7} ry={Math.max(13 - stress * 5.5, 4.5)}
                fill="url(#satBody)" stroke={C.gold} strokeWidth="0.5" opacity="0.95" />
              <text x={sx} y={sy - 26} textAnchor="middle" fontFamily={SERIF}
                fontSize="10" fontStyle="italic" fill={C.vellum}>Invariæ</text>
            </g>
          )}

          {breached && debris.map((d) => {
            const spread = Math.min((limit - dist) * 0.05, 3.4);
            const ang = d.a + t * 0.7;
            const rr = limit * 0.55 + d.r * 0.42 + Math.sin(d.i * 2.1 + t * 6) * spread * 4;
            const px = cx + Math.cos(ang) * rr;
            const py = cy + Math.sin(ang) * rr * 0.42;
            return <circle key={d.i} cx={px} cy={py} r={0.5 + (d.i % 4) * 0.28}
              fill={C.crimsonLit} opacity={0.28 + (d.i % 5) * 0.13} />;
          })}

          {/* tidal vectors */}
          {Array.from({ length: 12 }, (_, i) => {
            const a = (i / 12) * Math.PI * 2;
            const l = 20 + stress * 22;
            const x0 = cx + Math.cos(a) * (Rp + 4);
            const y0 = cy + Math.sin(a) * (Rp + 4);
            return <line key={i} x1={x0} y1={y0} x2={x0 + Math.cos(a) * l} y2={y0 + Math.sin(a) * l}
              stroke={C.brass} strokeWidth="0.45" opacity={0.16 + stress * 0.16} />;
          })}

          {/* annotation leader lines */}
          <g fontFamily={MONO} fontSize="8" letterSpacing="1" fill={C.gold} opacity="0.75">
            <line x1={cx + limit * 0.71} y1={cy - limit * 0.71} x2={cx + limit * 0.71 + 44}
              y2={cy - limit * 0.71 - 30} stroke={C.gold} strokeWidth="0.4" opacity="0.5" />
            <text x={cx + limit * 0.71 + 48} y={cy - limit * 0.71 - 32}>LIMES ROCHE</text>
            <line x1={cx - Rp * 0.7} y1={cy + Rp * 0.7} x2={cx - Rp * 0.7 - 40}
              y2={cy + Rp * 0.7 + 34} stroke={C.gold} strokeWidth="0.4" opacity="0.5" />
            <text x={cx - Rp * 0.7 - 118} y={cy + Rp * 0.7 + 44}>MASSA PRIMARIA</text>
          </g>

          {/* equation cartouche */}
          <g transform="translate(470,120)">
            <rect x="0" y="0" width="214" height="96" fill="#0A0908" stroke={C.gold}
              strokeWidth="0.7" opacity="0.97" />
            <rect x="4" y="4" width="206" height="88" fill="none" stroke={C.gold}
              strokeWidth="0.35" opacity="0.4" />
            <text x="107" y="26" textAnchor="middle" fontFamily={MONO} fontSize="7.5"
              letterSpacing="2.4" fill={C.brass}>LEX DISINTEGRATIONIS</text>
            <line x1="24" y1="35" x2="190" y2="35" stroke={C.gold} strokeWidth="0.4" opacity="0.4" />
            <text x="107" y="60" textAnchor="middle" fontFamily={SERIF} fontSize="19"
              fill={C.parchment} fontStyle="italic">
              d = R · (2ρ<tspan baselineShift="sub" fontSize="11">M</tspan> / ρ
              <tspan baselineShift="sub" fontSize="11">m</tspan>)<tspan baselineShift="super" fontSize="11">⅓</tspan>
            </text>
            <text x="107" y="81" textAnchor="middle" fontFamily={MONO} fontSize="7.5"
              letterSpacing="1.2" fill={breached ? C.crimsonLit : C.gold}>
              {breached ? "σ > 1 · BOUNDARY BREACHED" : "σ ≤ 1 · COHESION HOLDS"}
            </text>
          </g>
        </svg>
      </div>
    </Plate>
  );
};

/* ═══════════════════════════════════════════════════════════════════════════
   PLATE II — FAST WALSH-HADAMARD BUTTERFLY NETWORK
   ═══════════════════════════════════════════════════════════════════════════ */
const PlateFWHT: React.FC = () => {
  const N = 8;
  const STAGES = 3;
  const top = 44, gap = 32, xIn = 78, xOut = 646;
  const stageX = [228, 372, 516];
  const wireY = (i: number) => top + i * gap;

  const butterflies = useMemo(() => {
    const out: { stage: number; a: number; b: number }[] = [];
    for (let s = 0; s < STAGES; s++) {
      const half = 1 << s;
      const block = half << 1;
      for (let base = 0; base < N; base += block) {
        for (let k = 0; k < half; k++) {
          out.push({ stage: s, a: base + k, b: base + k + half });
        }
      }
    }
    return out;
  }, []);

  const [hover, setHover] = useState<number | null>(null);

  return (
    <Plate numeral="II" title="The Discrete Fast Walsh–Hadamard Transform"
      latin="H_N · H_Nᵀ = N · I_N  —  rotatio vnitaria, error nvllvs"
      caption={
        <div className="grid md:grid-cols-3 gap-6 font-mono text-[10px] leading-[1.85]"
          style={{ color: C.ash }}>
          <div>
            <div className="tracking-[0.2em] mb-1.5" style={{ color: C.gold }}>COMPLEXITAS</div>
            O(N log N) butterflies, additions and subtractions only. No multiplications — therefore
            no floating-point rounding, therefore no drift.
          </div>
          <div>
            <div className="tracking-[0.2em] mb-1.5" style={{ color: C.gold }}>VNITARIETAS</div>
            Because H_N is orthogonal, the inverse is its transpose. Reconstruction is exact over
            the fixed-point integer field: W′ ≡ W, bit for bit.
          </div>
          <div>
            <div className="tracking-[0.2em] mb-1.5" style={{ color: C.gold }}>ENERGIA</div>
            Spectral energy concentrates into low-frequency heads; residual coefficients collapse
            toward a Laplace density of kurtosis κ ≈ 6 ≫ 3.
          </div>
        </div>
      }>

      <div className="w-full overflow-x-auto" style={{
        background: `radial-gradient(ellipse 60% 70% at 50% 40%, rgba(27,59,111,0.13), transparent 72%), #080706`,
        border: `1px solid ${C.goldFaint}`,
      }}>
        <svg viewBox="0 0 720 330" className="w-full h-auto block min-w-[680px]">
          <defs>
            <pattern id="engraveFine" width="4" height="4"
              patternTransform="rotate(-45)" patternUnits="userSpaceOnUse">
              <line x1="0" y1="0" x2="0" y2="4" stroke={C.lapisLit} strokeWidth="0.3" opacity="0.14" />
            </pattern>
          </defs>
          <rect width="720" height="330" fill="url(#engraveFine)" />

          {/* stage columns */}
          {stageX.map((x, i) => (
            <g key={i}>
              <line x1={x} y1={top - 20} x2={x} y2={wireY(N - 1) + 20}
                stroke={C.gold} strokeWidth="0.35" opacity="0.2" strokeDasharray="2 5" />
              <text x={x} y={top - 27} textAnchor="middle" fontFamily={MONO} fontSize="7.5"
                letterSpacing="2" fill={C.gold} opacity="0.6">STADIO {i + 1}</text>
            </g>
          ))}

          {/* wires */}
          {Array.from({ length: N }, (_, i) => (
            <g key={i} onMouseEnter={() => setHover(i)} onMouseLeave={() => setHover(null)}>
              <line x1={xIn} y1={wireY(i)} x2={xOut} y2={wireY(i)}
                stroke={hover === i ? C.brass : C.gold}
                strokeWidth={hover === i ? 1.1 : 0.5}
                opacity={hover === null || hover === i ? 0.72 : 0.2} />
              <text x={xIn - 12} y={wireY(i) + 3.5} textAnchor="end" fontFamily={SERIF}
                fontSize="13" fontStyle="italic" fill={C.vellum}
                opacity={hover === null || hover === i ? 1 : 0.32}>
                w<tspan baselineShift="sub" fontSize="9">{i}</tspan>
              </text>
              <text x={xOut + 12} y={wireY(i) + 3.5} fontFamily={SERIF} fontSize="13"
                fontStyle="italic" fill={C.brass}
                opacity={hover === null || hover === i ? 1 : 0.32}>
                V<tspan baselineShift="sub" fontSize="9">{i}</tspan>
              </text>
              <circle cx={xIn} cy={wireY(i)} r="1.9" fill={C.gold} opacity="0.7" />
              <circle cx={xOut} cy={wireY(i)} r="1.9" fill={C.brass} opacity="0.8" />
            </g>
          ))}

          {/* butterfly junctions */}
          {butterflies.map((b, idx) => {
            const x = stageX[b.stage];
            const ya = wireY(b.a), yb = wireY(b.b);
            const hot = hover === b.a || hover === b.b;
            return (
              <g key={idx} opacity={hot ? 1 : 0.78}>
                <line x1={x} y1={ya} x2={x} y2={yb}
                  stroke={hot ? C.brass : C.gold} strokeWidth={hot ? 1 : 0.65} />
                <circle cx={x} cy={ya} r="2.7" fill="#0A0908"
                  stroke={hot ? C.brass : C.gold} strokeWidth="0.8" />
                <circle cx={x} cy={yb} r="2.7" fill="#0A0908"
                  stroke={hot ? C.brass : C.gold} strokeWidth="0.8" />
                <text x={x + 5.5} y={ya - 4} fontFamily={MONO} fontSize="8.5"
                  fill={hot ? C.parchment : C.gold}>+</text>
                <text x={x + 5.5} y={yb + 10} fontFamily={MONO} fontSize="8.5"
                  fill={hot ? C.parchment : C.gold}>−</text>
              </g>
            );
          })}

          {/* header labels */}
          <text x={xIn - 12} y={top - 27} textAnchor="end" fontFamily={MONO} fontSize="7.5"
            letterSpacing="2" fill={C.ash}>PONDVS</text>
          <text x={xOut + 12} y={top - 27} fontFamily={MONO} fontSize="7.5"
            letterSpacing="2" fill={C.ash}>SPECTRVM</text>

          {/* bottom equation */}
          <g transform="translate(360,296)">
            <text textAnchor="middle" fontFamily={SERIF} fontSize="15" fontStyle="italic"
              fill={C.parchment}>
              V = W · H_N   ⟹   W = V · H_Nᵀ / N   ⟹   W′ ≡ W
            </text>
          </g>
        </svg>
      </div>
    </Plate>
  );
};

/* ═══════════════════════════════════════════════════════════════════════════
   PLATE III — E8 ROOT SYSTEM (240 roots, Coxeter plane)
   ═══════════════════════════════════════════════════════════════════════════ */
const PlateE8: React.FC = () => {
  const [reveal, setReveal] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setReveal((r) => (r >= 240 ? 240 : r + 3)), 26);
    return () => clearInterval(id);
  }, []);

  const scale = 118;
  const shown = E8_ROOTS.slice(0, reveal);

  return (
    <Plate numeral="III" title="The E₈ Root System — 240 Vectors in the Coxeter Plane"
      latin="Qvantizatio reticvli · lattice8⟨E8⟩ · error 0.0000000"
      caption={
        <div className="grid md:grid-cols-[1fr_auto] gap-6 items-end">
          <p className="font-serif italic text-[15px] leading-relaxed" style={{ color: C.vellum }}>
            The densest known sphere packing in eight dimensions. Every root is equidistant from
            every neighbour — a self-correcting geometry in which quantization error cannot
            accumulate. Roche lowers FP16 tensors onto this lattice and proves the reconstruction
            bound before a single weight is written to disk.
          </p>
          <div className="font-mono text-[10px] text-right leading-[1.9]" style={{ color: C.gold }}>
            <div>112 VECTOR ROOTS</div>
            <div>128 SPINOR ROOTS</div>
            <div style={{ color: C.brass }}>{reveal} / 240 PLOTTED</div>
          </div>
        </div>
      }>

      <div className="w-full overflow-hidden" style={{
        background: `radial-gradient(circle at 50% 50%, rgba(27,59,111,0.16), transparent 62%), #080706`,
        border: `1px solid ${C.goldFaint}`,
      }}>
        <svg viewBox="-260 -260 520 520" className="w-full h-auto block max-h-[560px]">
          <defs>
            <radialGradient id="e8core" cx="50%" cy="50%">
              <stop offset="0%" stopColor={C.brass} stopOpacity="0.22" />
              <stop offset="100%" stopColor={C.brass} stopOpacity="0" />
            </radialGradient>
          </defs>

          <circle cx="0" cy="0" r="240" fill="url(#e8core)" />

          {/* astronomical ring furniture */}
          {[60, 108, 156, 204].map((r) => (
            <circle key={r} cx="0" cy="0" r={r} fill="none" stroke={C.gold}
              strokeWidth="0.35" opacity="0.18" strokeDasharray="1.5 5" />
          ))}
          <circle cx="0" cy="0" r="232" fill="none" stroke={C.gold} strokeWidth="0.5" opacity="0.28" />
          {Array.from({ length: 60 }, (_, i) => {
            const a = (i / 60) * Math.PI * 2;
            const long = i % 5 === 0;
            return <line key={i} x1={Math.cos(a) * (long ? 222 : 227)} y1={Math.sin(a) * (long ? 222 : 227)}
              x2={Math.cos(a) * 232} y2={Math.sin(a) * 232}
              stroke={C.gold} strokeWidth={long ? 0.7 : 0.35} opacity={long ? 0.5 : 0.25} />;
          })}

          <line x1="-240" y1="0" x2="240" y2="0" stroke={C.gold} strokeWidth="0.35" opacity="0.2" />
          <line x1="0" y1="-240" x2="0" y2="240" stroke={C.gold} strokeWidth="0.35" opacity="0.2" />

          {shown.map((pt, i) => (
            <circle key={i} cx={pt.x * scale} cy={pt.y * scale}
              r={pt.kind === "spinor" ? 1.7 : 2.3}
              fill={pt.kind === "spinor" ? C.lapisLit : C.brass}
              opacity={pt.kind === "spinor" ? 0.72 : 0.92}>
              <animate attributeName="opacity"
                from="0" to={pt.kind === "spinor" ? 0.72 : 0.92} dur="0.6s" fill="freeze" />
            </circle>
          ))}

          <circle cx="0" cy="0" r="3" fill={C.brass} opacity="0.9" />
          <circle cx="0" cy="0" r="9" fill="none" stroke={C.gold} strokeWidth="0.5" opacity="0.5" />
        </svg>
      </div>
    </Plate>
  );
};

/* ═══════════════════════════════════════════════════════════════════════════
   ORNAMENTAL FRAME — fixed viewport border
   ═══════════════════════════════════════════════════════════════════════════ */
const OrnamentalFrame: React.FC = () => (
  <div className="fixed inset-0 pointer-events-none" style={{ zIndex: 60 }}>
    <div className="absolute inset-[10px] border" style={{ borderColor: C.goldDim }} />
    <div className="absolute inset-[15px] border" style={{ borderColor: C.goldFaint }} />
    <div className="absolute top-[3px] left-[3px]"><CornerAcanthus rot={0} size={70} /></div>
    <div className="absolute top-[3px] right-[3px]"><CornerAcanthus rot={90} size={70} /></div>
    <div className="absolute bottom-[3px] right-[3px]"><CornerAcanthus rot={180} size={70} /></div>
    <div className="absolute bottom-[3px] left-[3px]"><CornerAcanthus rot={270} size={70} /></div>
    {/* cardinal fleurons */}
    <div className="absolute top-[6px] left-1/2 -translate-x-1/2"><Fleuron size={15} /></div>
    <div className="absolute bottom-[6px] left-1/2 -translate-x-1/2"><Fleuron size={15} /></div>
  </div>
);

const ChiaroscuroVeil: React.FC = () => (
  <>
    <div className="fixed inset-0 pointer-events-none" style={{
      zIndex: 55,
      background: `radial-gradient(ellipse 130% 100% at 50% 40%, transparent 30%, rgba(0,0,0,0.55) 78%, rgba(0,0,0,0.92) 100%)`,
    }} />
    <div className="fixed inset-0 pointer-events-none opacity-[0.055] mix-blend-overlay"
      style={{
        zIndex: 56,
        backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='300'%3E%3Cfilter id='g'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4'/%3E%3C/filter%3E%3Crect width='300' height='300' filter='url(%23g)'/%3E%3C/svg%3E")`,
      }} />
  </>
);

/* ═══════════════════════════════════════════════════════════════════════════
   NUMERAL — animated counter in the old-style
   ═══════════════════════════════════════════════════════════════════════════ */
const Counter: React.FC<{ to: number; decimals?: number }> = ({ to, decimals = 0 }) => {
  const [val, setVal] = useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  const started = useRef(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting && !started.current) {
        started.current = true;
        const t0 = performance.now();
        const dur = 1900;
        const tick = (now: number) => {
          const k = Math.min((now - t0) / dur, 1);
          const eased = 1 - Math.pow(1 - k, 4);
          setVal(to * eased);
          if (k < 1) requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
      }
    }, { threshold: 0.4 });
    obs.observe(el);
    return () => obs.disconnect();
  }, [to]);

  return <span ref={ref}>{val.toLocaleString("en-US", {
    minimumFractionDigits: decimals, maximumFractionDigits: decimals })}</span>;
};

/* ═══════════════════════════════════════════════════════════════════════════
   INVARIANT CHAPTER
   ═══════════════════════════════════════════════════════════════════════════ */
type Invariant = {
  numeral: string; name: string; latin: string; body: string;
  code: string; metric: string; metricLabel: string; accent: string;
};

const INVARIANTS: Invariant[] = [
  {
    numeral: "I", name: "Zero-Allocation Execution",
    latin: "Nihil ex nihilo creatvr",
    body: "Zero bytes of dynamic memory are allocated on any hot execution path. Pre-allocated, 64-byte hardware cache-aligned slabs eliminate OS heap malloc/free jitter entirely — the interpreter never asks the kernel for anything mid-flight.",
    code: "const stack: [1024]u256 align(64) = undefined;",
    metric: "0", metricLabel: "BYTES HEAP", accent: C.gold,
  },
  {
    numeral: "II", name: "118K Executions per Second",
    latin: "Celeritas in silicio nvdo",
    body: "A single-threaded Zig 0.16.0 engine compiled ReleaseFast, with 256-bit AVX2 SIMD integer vectorization on the word arithmetic hot path. Seventy-two times the throughput of garbage-collected Haskell fuzzers running the same corpus.",
    code: "const sum = @Vector(4, u64) +% @Vector(4, u64);",
    metric: "72.2", metricLabel: "× FASTER", accent: C.brass,
  },
  {
    numeral: "III", name: "Automatic Exploit Synthesis",
    latin: "Ex vestigio, demonstratio",
    body: "Runnable Foundry .t.sol regression tests are generated directly from minimized execution traces. No manual boilerplate, no transcription error — the witness is the artifact, and the artifact compiles.",
    code: "roche synth --name ExploitPoC --bytecode 0x…",
    metric: "4", metricLabel: "OPCODE WITNESS", accent: C.crimsonLit,
  },
  {
    numeral: "IV", name: "McCarthy Storage Rollback",
    latin: "Redittvs in statvm priorem",
    body: "O(1) deterministic state checkpointing and recovery journals for EIP-1153 transient storage and recursive external subcall failure isolation. Revert cost is proportional to slots touched, never to chain length.",
    code: "select(store(S, k, v), k) == v;   // O(1) rollback",
    metric: "O(1)", metricLabel: "REVERT COST", accent: C.lapisLit,
  },
  {
    numeral: "V", name: "Cancun / Prague Compliance",
    latin: "Secvndvm canonem",
    body: "One hundred per cent verified against canonical Ethereum Foundation execution-spec-tests fixtures. MCOPY, TSTORE, TLOAD, transient frames, SELFDESTRUCT tombstoning, and every RJUMP immediate — all conformant.",
    code: "roche eest-validate   // → 100.0% CONFORMANCE",
    metric: "100", metricLabel: "% CONFORMANCE", accent: C.gold,
  },
  {
    numeral: "VI", name: "Native Socket RPC Streaming",
    latin: "Sine medio, sine mora",
    body: "Direct TCP socket connections to local Anvil instances and mainnet fork nodes, driven through native kernel handles. No third-party HTTP client, no JSON serialization tax on the critical path.",
    code: "roche fork http://localhost:8545 0x…V4Pool",
    metric: "0", metricLabel: "DEPENDENCIES", accent: C.brass,
  },
];

const InvariantChapter: React.FC<{ inv: Invariant; index: number }> = ({ inv, index }) => {
  const [open, setOpen] = useState(index < 2);
  const flip = index % 2 === 1;

  return (
    <motion.article
      initial={{ opacity: 0, y: 44 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.95, ease: [0.16, 1, 0.3, 1] }}
      className="relative border-t"
      style={{ borderColor: C.goldFaint }}
    >
      <button onClick={() => setOpen((o) => !o)} aria-expanded={open}
        className="w-full text-left py-9 group cursor-pointer"
        style={{ background: "transparent", border: "none", color: "inherit" }}>
        <div className={`grid gap-x-8 gap-y-5 items-start ${flip ? "md:grid-cols-[76px_1fr_190px]" : "md:grid-cols-[76px_190px_1fr]"}`}>

          <div className="relative">
            <div className="font-serif text-[52px] leading-none"
              style={{ color: inv.accent, opacity: 0.92, fontWeight: 300 }}>
              {inv.numeral}
            </div>
            <div className="absolute -bottom-1 left-0 w-8 h-px" style={{ background: inv.accent, opacity: 0.5 }} />
          </div>

          <div className={`${flip ? "md:order-3" : "md:order-2"}`}>
            <h4 className="font-serif text-[clamp(1.4rem,2.6vw,2.05rem)] leading-tight mb-1.5"
              style={{ color: C.parchment, fontWeight: 400 }}>
              {inv.name}
            </h4>
            <div className="font-serif italic text-[13px]" style={{ color: inv.accent, opacity: 0.85 }}>
              {inv.latin}
            </div>
          </div>

          <div className={`${flip ? "md:order-2 md:text-right" : "md:order-3"} flex md:block items-baseline gap-3`}>
            <div className="font-serif text-[40px] leading-none tabular-nums"
              style={{ color: inv.accent }}>
              {inv.metric.includes("O(") ? inv.metric :
                inv.metric.includes(".") ? <Counter to={parseFloat(inv.metric)} decimals={1} /> :
                  <Counter to={parseInt(inv.metric, 10)} />}
            </div>
            <div className="font-mono text-[9px] tracking-[0.26em] mt-1.5" style={{ color: C.ash }}>
              {inv.metricLabel}
            </div>
          </div>
        </div>
      </button>

      <AnimatePresence initial={false}>
        {open && (
          <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
            className="overflow-hidden">
            <div className="pb-10 grid md:grid-cols-[76px_1fr] gap-x-8">
              <div />
              <div>
                <p className="font-serif text-[17px] leading-[1.78] max-w-[64ch] mb-6"
                  style={{ color: C.vellum, fontWeight: 300 }}>
                  {inv.body}
                </p>
                <pre className="font-mono text-[12px] px-5 py-4 overflow-x-auto"
                  style={{
                    background: "#060505",
                    borderLeft: `2px solid ${inv.accent}`,
                    color: C.gold, letterSpacing: "0.02em",
                  }}>{inv.code}</pre>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.article>
  );
};

/* ═══════════════════════════════════════════════════════════════════════════
   ANOMALY FOLIO — the case files
   ═══════════════════════════════════════════════════════════════════════════ */
type Anomaly = {
  protocol: string; title: string; severity: string; body: string;
  breach: string; delta: string; witness: string[]; hash: string;
};

const ANOMALIES: Anomaly[] = [
  {
    protocol: "Uniswap V4", severity: "CRITICAL",
    title: "Transient Storage Gas Siphon",
    body: "Unbounded loop execution inside a dynamic fee hook exhausts the transaction gas budget before the EIP-1153 lock slot is cleared. The reentrancy guard is never reset — every subsequent swap enters an already-poisoned frame.",
    breach: "gasleft() == 0  ∧  tload(LOCK_SLOT) == 1",
    delta: "Lock slot permanently poisoned · unbounded value extraction",
    witness: ["SLOAD", "DUP2", "ADD", "SSTORE"],
    hash: "0x7f3a…c91d",
  },
  {
    protocol: "Aave V3", severity: "HIGH",
    title: "Isolation Mode Debt Ceiling Ray Overflow",
    body: "Same-block repay and re-borrow cycles desynchronize liquidity-index updates. Because the index advances only at block boundaries, the ceiling check reads a stale ray-scaled value and admits debt beyond the isolation limit.",
    breach: "totalDebt > debtCeiling   (ray-scaled lag)",
    delta: "Ceiling exceeded by fractional ray units per cycle",
    witness: ["CALL", "SLOAD", "MUL", "GT", "JUMPI"],
    hash: "0x2be8…44af",
  },
  {
    protocol: "Curve StableSwap-NG", severity: "HIGH",
    title: "Newton–Raphson Truncation Under Asymmetric Decimals",
    body: "Precision loss across asymmetric token decimal scaling (18 vs 6) biases each Newton–Raphson iteration downward. In low-liquidity pools the bias compounds per swap and permits continuous extraction against the virtual price.",
    breach: "Δ virtualPrice > 0.50% · maximum permitted drift",
    delta: "Continuous monotonic drain across iterations",
    witness: ["MLOAD", "DIV", "SUB", "SSTORE"],
    hash: "0x91cc…07e2",
  },
];

const AnomalyFolio: React.FC<{ a: Anomaly; i: number }> = ({ a, i }) => {
  const [open, setOpen] = useState(false);
  const sev = a.severity === "CRITICAL" ? C.crimsonLit : C.brass;

  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-50px" }}
      transition={{ duration: 0.85, delay: i * 0.08, ease: [0.16, 1, 0.3, 1] }}
      className="relative">
      <div className="absolute inset-0 -m-px" style={{
        background: `linear-gradient(150deg,${sev}44,transparent 45%,${C.gold}22)`,
        padding: 1,
      }}>
        <div className="w-full h-full" style={{ background: C.obsidian }} />
      </div>

      <div className="relative p-7 sm:p-9" style={{
        background: `linear-gradient(160deg, rgba(20,18,16,0.96), rgba(10,9,8,0.99))`,
      }}>
        <div className="flex items-start justify-between gap-6 mb-6">
          <div>
            <div className="font-mono text-[9px] tracking-[0.34em] uppercase mb-2.5"
              style={{ color: sev }}>
              {a.protocol} · {a.severity}
            </div>
            <h4 className="font-serif text-[clamp(1.35rem,2.4vw,1.95rem)] leading-[1.15]"
              style={{ color: C.parchment, fontWeight: 400 }}>
              {a.title}
            </h4>
          </div>
          <div className="shrink-0 mt-1"><Fleuron size={26} tone={sev} /></div>
        </div>

        <p className="font-serif text-[15.5px] leading-[1.75] mb-6"
          style={{ color: C.vellum, fontWeight: 300 }}>
          {a.body}
        </p>

        <div className="grid sm:grid-cols-2 gap-5 mb-6">
          <div>
            <div className="font-mono text-[8.5px] tracking-[0.28em] mb-2" style={{ color: C.ash }}>
              INVARIANT BREACH
            </div>
            <pre className="font-mono text-[11px] px-4 py-3 overflow-x-auto leading-relaxed"
              style={{ background: "#060505", borderLeft: `2px solid ${sev}`, color: sev }}>
              {a.breach}
            </pre>
          </div>
          <div>
            <div className="font-mono text-[8.5px] tracking-[0.28em] mb-2" style={{ color: C.ash }}>
              OBSERVED DELTA
            </div>
            <div className="font-serif italic text-[14.5px] leading-relaxed px-4 py-3"
              style={{ background: "#060505", borderLeft: `2px solid ${C.gold}`, color: C.gold }}>
              {a.delta}
            </div>
          </div>
        </div>

        <button onClick={() => setOpen((o) => !o)} aria-expanded={open}
          className="font-mono text-[9.5px] tracking-[0.28em] uppercase pb-1.5 border-b transition-colors cursor-pointer"
          style={{
            background: "none", border: "none", borderBottom: `1px solid ${C.goldDim}`,
            color: open ? C.brass : C.gold,
          }}>
          {open ? "Conceal Witness ▲" : "Reveal Minimized Witness ▼"}
        </button>

        <AnimatePresence initial={false}>
          {open && (
            <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }}
              exit={{ height: 0, opacity: 0 }} transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
              className="overflow-hidden">
              <div className="pt-6">
                <pre className="font-mono text-[11.5px] leading-[2.05] p-5 overflow-x-auto"
                  style={{ background: "#060505", border: `1px solid ${C.goldFaint}`, color: C.brass }}>
                  {a.witness.map((op, k) => `${String(k).padStart(3, "0")}   ${op}`).join("\n")}
                </pre>
                <div className="flex flex-wrap items-center justify-between gap-4 mt-4">
                  <span className="font-mono text-[9px] tracking-[0.2em]" style={{ color: C.ash }}>
                    TRACE {a.hash}
                  </span>
                  <span className="font-mono text-[9px] tracking-[0.2em] px-3 py-1.5 cursor-pointer transition-colors"
                    style={{ border: `1px solid ${C.goldDim}`, color: C.gold }}>
                    DOWNLOAD .T.SOL →
                  </span>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.div>
  );
};

/* ═══════════════════════════════════════════════════════════════════════════
   THE LEDGER — benchmark, engraved
   ═══════════════════════════════════════════════════════════════════════════ */
const LEDGER = [
  { name: "ROCHE v1.0", sub: "Pure Zig 0.16.0", thr: 118764, thrLabel: "118,764 / sec", mem: "0 MB", memLabel: "Fixed Slab", fp: "0.0%", kind: "Dynamic State + Invariant", ours: true },
  { name: "Echidna v2.2", sub: "Haskell / GC", thr: 1420, thrLabel: "1,420 / sec", mem: "540 MB", memLabel: "GC Heap", fp: "4.2%", kind: "Property Fuzzing", ours: false },
  { name: "Slither v0.10", sub: "Python / AST", thr: 0, thrLabel: "Static AST only", mem: "180 MB", memLabel: "Python Heap", fp: "28.5%", kind: "Static Detectors", ours: false },
];

const Ledger: React.FC = () => {
  const maxThr = 118764;
  return (
    <div className="w-full overflow-x-auto">
      <table className="w-full min-w-[760px] border-collapse">
        <thead>
          <tr>
            {["Instrumentum", "Throughput", "", "Memory Footprint", "False Positives", "Invariant Class"].map((h, i) => (
              <th key={i} colSpan={i === 1 ? 2 : 1}
                className="font-mono text-[8.5px] tracking-[0.26em] uppercase text-left pb-4 font-normal"
                style={{ color: C.brass, borderBottom: `1px solid ${C.goldDim}` }}>
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {LEDGER.map((row, i) => (
            <motion.tr key={row.name}
              initial={{ opacity: 0, x: -18 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.7, delay: i * 0.11 }}
              style={{ background: row.ours ? "rgba(197,160,89,0.045)" : "transparent" }}>
              <td className="py-6 pr-6 align-top" style={{ borderBottom: `1px solid ${C.goldFaint}` }}>
                <div className="font-serif text-[19px] leading-none"
                  style={{ color: row.ours ? C.brass : C.vellum, fontWeight: row.ours ? 500 : 400 }}>
                  {row.name}
                </div>
                <div className="font-mono text-[9px] tracking-[0.16em] mt-2" style={{ color: C.ash }}>
                  {row.sub}
                </div>
              </td>
              <td className="py-6 pr-3 align-top font-mono text-[12px] whitespace-nowrap"
                style={{ borderBottom: `1px solid ${C.goldFaint}`, color: row.ours ? C.brass : C.vellum }}>
                {row.thr > 0 ? <Counter to={row.thr} /> : "—"}
              </td>
              <td className="py-6 pr-6 align-top" style={{ borderBottom: `1px solid ${C.goldFaint}` }}>
                <div className="h-[3px] w-full min-w-[130px]" style={{ background: C.iron }}>
                  <motion.div initial={{ width: 0 }} whileInView={{ width: `${Math.max((row.thr / maxThr) * 100, 1.5)}%` }}
                    viewport={{ once: true }} transition={{ duration: 1.4, delay: 0.25 + i * 0.1, ease: [0.16, 1, 0.3, 1] }}
                    style={{ height: "100%", background: row.ours ? C.brass : C.ash, opacity: row.ours ? 1 : 0.5 }} />
                </div>
                <div className="font-mono text-[8.5px] tracking-[0.18em] mt-2" style={{ color: C.ash }}>
                  {row.thrLabel}
                </div>
              </td>
              <td className="py-6 pr-6 align-top font-mono text-[12px]"
                style={{ borderBottom: `1px solid ${C.goldFaint}`, color: row.ours ? C.gold : C.ash }}>
                {row.mem}
                <div className="text-[8.5px] tracking-[0.16em] mt-1.5" style={{ color: C.ash }}>{row.memLabel}</div>
              </td>
              <td className="py-6 pr-6 align-top font-mono text-[12px]"
                style={{
                  borderBottom: `1px solid ${C.goldFaint}`,
                  color: row.ours ? C.brass : row.fp === "28.5%" ? C.crimsonLit : C.ash,
                }}>
                {row.fp}
              </td>
              <td className="py-6 align-top font-serif italic text-[14px]"
                style={{ borderBottom: `1px solid ${C.goldFaint}`, color: row.ours ? C.vellum : C.ash }}>
                {row.kind}
              </td>
            </motion.tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

/* ═══════════════════════════════════════════════════════════════════════════
   TRACKS — engagement, no pricing
   ═══════════════════════════════════════════════════════════════════════════ */
const TRACKS = [
  {
    numeral: "I", head: "For Protocol Teams", accent: C.brass,
    lines: ["Three-month automated invariant CI/CD pilot", "Foundry .t.sol exploit synthesis, generated per finding", "Sub-minute regression checking on every pull request"],
    cta: "Request the Pilot",
  },
  {
    numeral: "II", head: "For Audit Firms", accent: C.gold,
    lines: ["Zero-overhead Rust FFI and C-ABI bindings", "Seventy-times faster trace minimization and triage", "White-label client reporting under your seal"],
    cta: "Open a Dialogue",
  },
  {
    numeral: "III", head: "For Grants & Builders", accent: C.lapisLit,
    lines: ["Ethereum Foundation ESP — Tier 1 proposal", "One hundred per cent open source, MIT / Apache-2.0", "Pure Zig 0.16.0 bare-silicon core, no runtime"],
    cta: "Read the Dossier",
  },
];

/* ═══════════════════════════════════════════════════════════════════════════
   APP
   ═══════════════════════════════════════════════════════════════════════════ */
export default function App() {
  const { scrollYProgress } = useScroll();
  const spin = useTransform(scrollYProgress, [0, 1], [0, 165]);
  const smoothSpin = useSpring(spin, { stiffness: 42, damping: 22, mass: 0.6 });
  const heroFade = useTransform(scrollYProgress, [0, 0.1], [1, 0]);

  const [navOpen, setNavOpen] = useState(false);

  useEffect(() => {
    const id = "roche-typography";
    if (document.getElementById(id)) return;
    const link = document.createElement("link");
    link.id = id;
    link.rel = "stylesheet";
    link.href =
      "https://cdn.jsdelivr.net/npm/@fontsource/cormorant-garamond@5.0.0/300.css," +
      "";
    // inject all faces via style element (fontsource CSS files)
    const st = document.createElement("style");
    st.textContent = `
      @import url('https://cdn.jsdelivr.net/npm/@fontsource/cormorant-garamond@5.0.0/300.css');
      @import url('https://cdn.jsdelivr.net/npm/@fontsource/cormorant-garamond@5.0.0/400.css');
      @import url('https://cdn.jsdelivr.net/npm/@fontsource/cormorant-garamond@5.0.0/500.css');
      @import url('https://cdn.jsdelivr.net/npm/@fontsource/cormorant-garamond@5.0.0/600.css');
      @import url('https://cdn.jsdelivr.net/npm/@fontsource/cormorant-garamond@5.0.0/300-italic.css');
      @import url('https://cdn.jsdelivr.net/npm/@fontsource/cormorant-garamond@5.0.0/400-italic.css');
      @import url('https://cdn.jsdelivr.net/npm/@fontsource/cormorant-sc@5.0.0/400.css');
      @import url('https://cdn.jsdelivr.net/npm/@fontsource/jetbrains-mono@5.0.0/400.css');
      @import url('https://cdn.jsdelivr.net/npm/@fontsource/jetbrains-mono@5.0.0/500.css');
      html { scroll-behavior: smooth; }
      body { background:#0A0908; margin:0; overflow-x:hidden; }
      ::selection { background:#C5A059; color:#0A0908; }
      ::-webkit-scrollbar{width:7px}
      ::-webkit-scrollbar-track{background:#0A0908}
      ::-webkit-scrollbar-thumb{background:#2A241C}
      ::-webkit-scrollbar-thumb:hover{background:#C5A059}
    `;
    document.head.appendChild(st);
    return () => { document.head.removeChild(st); link.remove(); };
  }, []);

  return (
    <div className="min-h-screen w-full relative" style={{ background: C.obsidian, color: C.parchment }}>
      <OrnamentalFrame />
      <ChiaroscuroVeil />

      {/* ── NAVIGATION ─────────────────────────────────────────── */}
      <nav className="fixed top-0 left-0 right-0 z-[70]" style={{
        background: "linear-gradient(180deg, rgba(10,9,8,0.96) 55%, rgba(10,9,8,0))",
        backdropFilter: "blur(2px)",
      }}>
        <div className="max-w-[1440px] mx-auto px-8 sm:px-14 py-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Fleuron size={17} tone={C.brass} />
            <span className="font-mono text-[10px] tracking-[0.4em] uppercase" style={{ color: C.parchment }}>
              Roche
            </span>
          </div>

          <div className="hidden lg:flex items-center gap-9 font-mono text-[9.5px] tracking-[0.24em] uppercase">
            {[["Tabvlæ", "#plates"], ["Invariantes", "#invariants"], ["Anomaliæ", "#anomalies"],
              ["Mensvra", "#ledger"], ["Architectvs", "#architect"]].map(([l, h]) => (
              <a key={h} href={h} className="transition-colors hover:text-[#D4AF37]"
                style={{ color: C.ash, textDecoration: "none" }}>{l}</a>
            ))}
          </div>

          <div className="flex items-center gap-4">
            <div className="hidden sm:flex items-center gap-2 font-mono text-[9px] tracking-[0.2em]"
              style={{ color: C.gold }}>
              <span className="w-1.5 h-1.5 rounded-full animate-pulse" style={{ background: C.brass }} />
              29/29 PASSING
            </div>
            <a href="https://github.com/creatorofaurad/Roche" target="_blank" rel="noreferrer"
              className="font-mono text-[9px] tracking-[0.24em] uppercase px-5 py-2.5 transition-all"
              style={{
                border: `1px solid ${C.goldDim}`, color: C.gold, textDecoration: "none",
              }}
              onMouseEnter={(e) => { e.currentTarget.style.background = C.gold; e.currentTarget.style.color = C.obsidian; }}
              onMouseLeave={(e) => { e.currentTarget.style.background = "transparent"; e.currentTarget.style.color = C.gold; }}>
              Codex
            </a>
          </div>
        </div>
      </nav>

      {/* ── FRONTISPIECE ───────────────────────────────────────── */}
      <header className="relative min-h-screen flex items-center justify-center overflow-hidden pt-24 pb-16">
        {/* chiaroscuro light source */}
        <div className="absolute inset-0 pointer-events-none" style={{
          background: `radial-gradient(ellipse 62% 52% at 50% 44%, rgba(197,160,89,0.17), rgba(27,59,111,0.06) 44%, transparent 70%)`,
        }} />

        <motion.div className="absolute inset-0 flex items-center justify-center pointer-events-none"
          style={{ opacity: heroFade }}>
          <div className="w-[min(118vh,1180px)] aspect-square opacity-[0.62]">
            <motion.div style={{ rotate: smoothSpin }} className="w-full h-full">
              <Armillary spin={0} />
            </motion.div>
          </div>
        </motion.div>

        <div className="relative z-10 max-w-[1180px] mx-auto px-8 text-center">
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 1.8, delay: 0.2 }}
            className="font-mono text-[9px] sm:text-[10px] tracking-[0.42em] uppercase mb-8"
            style={{ color: C.gold }}>
            Bare-Silicon EVM Kernel · Zig 0.16.0 · AVX2 256-bit SIMD
          </motion.div>

          <motion.h1 initial={{ opacity: 0, y: 26 }} animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 1.5, delay: 0.35, ease: [0.16, 1, 0.3, 1] }}
            className="font-serif leading-[0.84] tracking-[0.06em]"
            style={{
              fontSize: "clamp(4.2rem,17vw,13.5rem)", fontWeight: 300, color: C.parchment,
              textShadow: `0 0 90px rgba(197,160,89,0.30), 0 2px 0 rgba(0,0,0,0.9)`,
            }}>
            ROCHE
          </motion.h1>

          <motion.div initial={{ scaleX: 0 }} animate={{ scaleX: 1 }}
            transition={{ duration: 1.3, delay: 0.85, ease: [0.16, 1, 0.3, 1] }}
            className="mx-auto mt-7 max-w-[520px]"><RuleDouble label="De Limite Roche" /></motion.div>

          <motion.p initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 1.3, delay: 1.0 }}
            className="font-serif italic text-[clamp(1.05rem,2.3vw,1.55rem)] leading-snug mt-8 max-w-[26ch] mx-auto"
            style={{ color: C.vellum, fontWeight: 300 }}>
            The zero-allocation invariant engine for the Ethereum Virtual Machine.
          </motion.p>

          <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 1.4, delay: 1.25 }}
            className="font-serif text-[clamp(0.95rem,1.6vw,1.1rem)] leading-[1.75] mt-6 max-w-[54ch] mx-auto"
            style={{ color: C.ash, fontWeight: 300 }}>
            Stop fuzzing at a thousand executions per second inside a garbage-collected runtime.
            Roche executes state transitions on bare silicon, through direct Win32 and POSIX
            system calls, and proves the boundary before mainnet finds it for you.
          </motion.p>

          {/* the three numerals */}
          <motion.div initial={{ opacity: 0, y: 22 }} animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 1.2, delay: 1.5 }}
            className="mt-14 grid grid-cols-3 gap-px max-w-[720px] mx-auto"
            style={{ background: C.goldFaint }}>
            {[
              { v: 118764, s: "Executions / Second", d: 0 },
              { v: 0, s: "Bytes Dynamic Heap", d: 0 },
              { v: 29, s: "of 29 Suites Passing", d: 0 },
            ].map((m, i) => (
              <div key={i} className="px-3 py-7" style={{ background: "rgba(10,9,8,0.93)" }}>
                <div className="font-serif leading-none tabular-nums"
                  style={{ fontSize: "clamp(1.7rem,4.6vw,3rem)", color: i === 1 ? C.brass : C.parchment, fontWeight: 300 }}>
                  {m.v === 0 ? "0" : <Counter to={m.v} decimals={m.d} />}
                </div>
                <div className="font-mono text-[8px] sm:text-[9px] tracking-[0.24em] uppercase mt-3.5 leading-relaxed"
                  style={{ color: C.ash }}>
                  {m.s}
                </div>
              </div>
            ))}
          </motion.div>

          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 1, delay: 1.9 }}
            className="mt-12 flex flex-col sm:flex-row items-center justify-center gap-4">
            <a href="https://github.com/creatorofaurad/Roche" target="_blank" rel="noreferrer"
              className="font-mono text-[10px] tracking-[0.26em] uppercase px-9 py-4 transition-all"
              style={{ background: C.gold, color: C.obsidian, textDecoration: "none", fontWeight: 500 }}
              onMouseEnter={(e) => { e.currentTarget.style.background = C.brass; }}
              onMouseLeave={(e) => { e.currentTarget.style.background = C.gold; }}>
              Clone the Codex
            </a>
            <a href="#plates"
              className="font-mono text-[10px] tracking-[0.26em] uppercase px-9 py-4 transition-all"
              style={{ border: `1px solid ${C.goldDim}`, color: C.gold, textDecoration: "none" }}
              onMouseEnter={(e) => { e.currentTarget.style.borderColor = C.gold; e.currentTarget.style.color = C.parchment; }}
              onMouseLeave={(e) => { e.currentTarget.style.borderColor = C.goldDim; e.currentTarget.style.color = C.gold; }}>
              Examine the Plates
            </a>
          </motion.div>

          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 2.3, duration: 1 }}
            className="mt-14 font-mono text-[9px] tracking-[0.2em] leading-[2.1] max-w-[62ch] mx-auto"
            style={{ color: "#5C554A" }}>
            $ git clone https://github.com/creatorofaurad/Roche.git<br />
            $ cd Roche && zig build -Doptimize=ReleaseFast
          </motion.div>
        </div>
      </header>

      {/* ── THE METAPHOR ───────────────────────────────────────── */}
      <section className="relative py-28 sm:py-40 px-8">
        <div className="max-w-[1080px] mx-auto">
          <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}
            transition={{ duration: 1.6 }} className="mb-16">
            <RuleDouble label="Celestis Astrophysica" />
          </motion.div>

          <div className="grid lg:grid-cols-[1.15fr_1fr] gap-14 lg:gap-20 items-start">
            <motion.div initial={{ opacity: 0, x: -26 }} whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, margin: "-80px" }} transition={{ duration: 1.1, ease: [0.16, 1, 0.3, 1] }}>
              <div className="font-mono text-[9px] tracking-[0.36em] uppercase mb-6" style={{ color: C.brass }}>
                Capvt Primum
              </div>
              <h2 className="font-serif leading-[0.94] tracking-[-0.01em] mb-9"
                style={{ fontSize: "clamp(2.3rem,5.4vw,4.3rem)", fontWeight: 300, color: C.parchment }}>
                In orbital mechanics, the <span className="italic" style={{ color: C.brass }}>Roche Limit</span> is
                the exact radial boundary where a body's internal gravitational cohesion is
                overwhelmed by tidal force.
              </h2>
              <p className="font-serif text-[18px] leading-[1.85] mb-7" style={{ color: C.vellum, fontWeight: 300 }}>
                It is not a probability. It is not a heuristic. It is a closed-form expression —
                computable, exact, and indifferent to whether you choose to evaluate it.
              </p>
              <div className="pl-6 py-2" style={{ borderLeft: `2px solid ${C.lapis}` }}>
                <p className="font-serif italic text-[19px] leading-[1.7]" style={{ color: C.gold }}>
                  "We do not build software to follow trends. We sculpt bare silicon like marble —
                  in pursuit of timeless truth, formal beauty, and mathematical perfection."
                </p>
                <div className="font-mono text-[9px] tracking-[0.28em] uppercase mt-4" style={{ color: C.ash }}>
                  — Charles, Lead Systems Architect
                </div>
              </div>
            </motion.div>

            <motion.div initial={{ opacity: 0, x: 26 }} whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, margin: "-80px" }} transition={{ duration: 1.1, delay: 0.14, ease: [0.16, 1, 0.3, 1] }}
              className="relative">
              <div className="relative p-6 sm:p-8" style={{
                background: "linear-gradient(155deg, rgba(27,59,111,0.10), rgba(10,9,8,0.97) 62%)",
                border: `1px solid ${C.goldFaint}`,
              }}>
                <div className="font-mono text-[9px] tracking-[0.3em] uppercase mb-5" style={{ color: C.brass }}>
                  De Limitv Roche
                </div>
                <div className="font-serif italic text-[clamp(1.25rem,2.5vw,1.75rem)] leading-[1.5] mb-7"
                  style={{ color: C.parchment }}>
                  d = R · (2ρ<sub>M</sub> / ρ<sub>m</sub>)<sup>1/3</sup>
                </div>
                <div className="h-px w-full mb-7" style={{ background: C.goldFaint }} />
                <p className="font-serif text-[16px] leading-[1.8] mb-6" style={{ color: C.vellum, fontWeight: 300 }}>
                  Flash loans, dynamic hooks, and cross-chain composability exert brutal economic
                  tidal forces upon every pool they touch. When an invariant boundary is breached,
                  multi-million dollar liquidity cascades disintegrate in a single block.
                </p>
                <p className="font-serif text-[16px] leading-[1.8]" style={{ color: C.vellum, fontWeight: 300 }}>
                  Roche computes the exact invariant boundary <span style={{ color: C.brass, fontStyle: "italic" }}>
                    before mainnet deployment</span>. Not after the post-mortem. Before.
                </p>
                <div className="mt-8 flex items-center gap-3">
                  <div className="h-px flex-1" style={{ background: C.goldDim }} />
                  <Fleuron size={15} tone={C.gold} />
                  <div className="h-px flex-1" style={{ background: C.goldDim }} />
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* ── THE PLATES ─────────────────────────────────────────── */}
      <section id="plates" className="relative py-24 sm:py-32 px-6 sm:px-8">
        <div className="max-w-[1180px] mx-auto">
          <div className="text-center mb-20">
            <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}
              transition={{ duration: 1.4 }} className="mb-8">
              <RuleDouble label="Tabvlæ Æneæ" />
            </motion.div>
            <motion.h2 initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }} transition={{ duration: 1.1, ease: [0.16, 1, 0.3, 1] }}
              className="font-serif leading-[0.96]"
              style={{ fontSize: "clamp(2.1rem,5.2vw,4rem)", fontWeight: 300, color: C.parchment }}>
              Three Plates, Engraved<br />
              <span className="italic" style={{ color: C.brass }}>upon the Copper</span>
            </motion.h2>
            <motion.p initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}
              transition={{ duration: 1.2, delay: 0.2 }}
              className="font-serif text-[17px] leading-[1.8] mt-7 max-w-[58ch] mx-auto"
              style={{ color: C.ash, fontWeight: 300 }}>
              The mathematical instruments beneath the engine, drawn after the manner of the old
              treatises on natural philosophy. Every point plotted is computed, not decorated.
            </motion.p>
          </div>

          <div className="space-y-20 sm:space-y-28">
            <PlateRocheLimit />
            <PlateFWHT />
            <PlateE8 />
          </div>
        </div>
      </section>

      {/* ── INVARIANTS ─────────────────────────────────────────── */}
      <section id="invariants" className="relative py-24 sm:py-32 px-8">
        <div className="max-w-[1080px] mx-auto">
          <div className="mb-16">
            <RuleDouble label="Sex Invariantes" />
          </div>
          <div className="grid lg:grid-cols-[300px_1fr] gap-14">
            <div className="lg:sticky lg:top-32 self-start">
              <div className="font-mono text-[9px] tracking-[0.36em] uppercase mb-5" style={{ color: C.brass }}>
                Capvt Secvndvm
              </div>
              <h2 className="font-serif leading-[0.98] mb-7"
                style={{ fontSize: "clamp(2rem,4vw,3.1rem)", fontWeight: 300, color: C.parchment }}>
                The Six<br /><span className="italic" style={{ color: C.brass }}>Invariants</span>
              </h2>
              <p className="font-serif text-[15.5px] leading-[1.8] mb-8"
                style={{ color: C.ash, fontWeight: 300 }}>
                Not features. Invariants — properties that hold under every input, verified by
                test and by proof, enforced at compile time where the compiler can reach them.
              </p>
              <div className="font-mono text-[9px] tracking-[0.2em] leading-[2.2]" style={{ color: "#5C554A" }}>
                SELECT A CHAPTER TO EXPAND
              </div>
            </div>

            <div>
              {INVARIANTS.map((inv, i) => (
                <InvariantChapter key={inv.numeral} inv={inv} index={i} />
              ))}
              <div className="border-t" style={{ borderColor: C.goldFaint }} />
            </div>
          </div>
        </div>
      </section>

      {/* ── ANOMALIES ──────────────────────────────────────────── */}
      <section id="anomalies" className="relative py-24 sm:py-32 px-8">
        <div className="max-w-[1180px] mx-auto">
          <div className="mb-16"><RuleDouble label="Anomaliæ Reproductæ" tone={C.crimsonLit} /></div>

          <div className="grid lg:grid-cols-[1fr_320px] gap-14 mb-16 items-end">
            <div>
              <div className="font-mono text-[9px] tracking-[0.36em] uppercase mb-5" style={{ color: C.crimsonLit }}>
                Capvt Tertivm
              </div>
              <h2 className="font-serif leading-[0.98]"
                style={{ fontSize: "clamp(2rem,4.6vw,3.5rem)", fontWeight: 300, color: C.parchment }}>
                Reproduced Protocol<br /><span className="italic" style={{ color: C.crimsonLit }}>Anomalies</span>
              </h2>
            </div>
            <p className="font-serif text-[15.5px] leading-[1.8]" style={{ color: C.ash, fontWeight: 300 }}>
              Each of the following was reproduced from raw bytecode, minimized to its shortest
              witness, and emitted as a compilable Foundry regression test. No manual transcription
              intervened between detection and artifact.
            </p>
          </div>

          <div className="grid lg:grid-cols-3 gap-6">
            {ANOMALIES.map((a, i) => <AnomalyFolio key={a.protocol} a={a} i={i} />)}
          </div>
        </div>
      </section>

      {/* ── LEDGER ─────────────────────────────────────────────── */}
      <section id="ledger" className="relative py-24 sm:py-32 px-8">
        <div className="max-w-[1180px] mx-auto">
          <div className="mb-16"><RuleDouble label="Mensvra Empirica" /></div>
          <div className="text-center mb-16">
            <div className="font-mono text-[9px] tracking-[0.36em] uppercase mb-5" style={{ color: C.brass }}>
              Capvt Qvartvm
            </div>
            <h2 className="font-serif leading-[0.98]"
              style={{ fontSize: "clamp(2rem,4.6vw,3.5rem)", fontWeight: 300, color: C.parchment }}>
              The <span className="italic" style={{ color: C.brass }}>Empirical</span> Ledger
            </h2>
          </div>
          <Ledger />
          <div className="mt-9 font-mono text-[9px] tracking-[0.18em] leading-[2]" style={{ color: "#5C554A" }}>
            MEASURED SINGLE-THREADED · ZIG 0.16.0 RELEASEFAST · x86_64 AVX2 · IDENTICAL CORPUS ACROSS INSTRUMENTS
          </div>
        </div>
      </section>

      {/* ── TRACKS ─────────────────────────────────────────────── */}
      <section className="relative py-24 sm:py-32 px-8">
        <div className="max-w-[1180px] mx-auto">
          <div className="mb-16"><RuleDouble label="Tres Viæ" /></div>
          <div className="grid lg:grid-cols-3 gap-px" style={{ background: C.goldFaint }}>
            {TRACKS.map((t, i) => (
              <motion.div key={t.numeral}
                initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-60px" }}
                transition={{ duration: 0.9, delay: i * 0.12, ease: [0.16, 1, 0.3, 1] }}
                className="p-9 sm:p-11 flex flex-col" style={{ background: C.obsidian, minHeight: 380 }}>
                <div className="flex items-baseline justify-between mb-8">
                  <span className="font-serif text-[44px] leading-none" style={{ color: t.accent, fontWeight: 300 }}>
                    {t.numeral}
                  </span>
                  <Fleuron size={18} tone={t.accent} />
                </div>
                <h3 className="font-serif text-[26px] leading-tight mb-7"
                  style={{ color: C.parchment, fontWeight: 400 }}>
                  {t.head}
                </h3>
                <ul className="space-y-3.5 flex-1">
                  {t.lines.map((l) => (
                    <li key={l} className="font-serif text-[15px] leading-[1.65] flex gap-3"
                      style={{ color: C.vellum, fontWeight: 300 }}>
                      <span style={{ color: t.accent }}>◆</span><span>{l}</span>
                    </li>
                  ))}
                </ul>
                <button className="mt-9 font-mono text-[9.5px] tracking-[0.26em] uppercase py-3.5 transition-all cursor-pointer"
                  style={{ border: `1px solid ${t.accent}55`, background: "transparent", color: t.accent }}
                  onMouseEnter={(e) => { e.currentTarget.style.background = t.accent; e.currentTarget.style.color = C.obsidian; }}
                  onMouseLeave={(e) => { e.currentTarget.style.background = "transparent"; e.currentTarget.style.color = t.accent; }}>
                  {t.cta}
                </button>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ── THE ARCHITECT ──────────────────────────────────────── */}
      <section id="architect" className="relative py-28 sm:py-40 px-8 overflow-hidden">
        <div className="absolute inset-0 pointer-events-none" style={{
          background: `radial-gradient(ellipse 60% 55% at 50% 50%, rgba(27,59,111,0.15), transparent 70%)`,
        }} />
        <div className="relative max-w-[900px] mx-auto text-center">
          <div className="mb-10"><RuleDouble label="Architectvs" /></div>

          <motion.div initial={{ opacity: 0, scale: 0.94 }} whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }} transition={{ duration: 1.3, ease: [0.16, 1, 0.3, 1] }}
            className="mx-auto mb-11 w-[132px] h-[132px] relative">
            <div className="absolute inset-0 rounded-full" style={{
              background: `radial-gradient(circle at 38% 32%, ${C.brass}, ${C.gold} 40%, #3A2C12 78%, #0A0908)`,
              boxShadow: `0 0 66px rgba(197,160,89,0.34)`,
            }} />
            <div className="absolute inset-[5px] rounded-full flex items-center justify-center"
              style={{ background: C.obsidian, border: `1px solid ${C.goldDim}` }}>
              <span className="font-serif text-[42px] leading-none" style={{ color: C.brass, fontWeight: 300 }}>C</span>
            </div>
            <div className="absolute inset-[-13px] rounded-full border" style={{ borderColor: C.goldFaint }} />
          </motion.div>

          <motion.h2 initial={{ opacity: 0, y: 22 }} whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }} transition={{ duration: 1.1, delay: 0.1 }}
            className="font-serif leading-[1.02] mb-5"
            style={{ fontSize: "clamp(2.1rem,5.2vw,3.9rem)", fontWeight: 300, color: C.parchment }}>
            Charles
          </motion.h2>

          <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}
            transition={{ duration: 1, delay: 0.25 }}
            className="font-mono text-[10px] tracking-[0.32em] uppercase mb-10" style={{ color: C.brass }}>
            @coolkidsdontcode · Lead Systems Architect
          </motion.div>

          <motion.p initial={{ opacity: 0, y: 18 }} whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }} transition={{ duration: 1.1, delay: 0.35 }}
            className="font-serif italic text-[clamp(1.15rem,2.5vw,1.75rem)] leading-[1.62] max-w-[34ch] mx-auto mb-10"
            style={{ color: C.vellum, fontWeight: 300 }}>
            "We sculpt bare silicon like marble — in pursuit of timeless truth, formal beauty,
            and mathematical perfection."
          </motion.p>

          <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}
            transition={{ duration: 1.1, delay: 0.5 }}
            className="grid sm:grid-cols-3 gap-px max-w-[720px] mx-auto" style={{ background: C.goldFaint }}>
            {[["15", "Years of Age"], ["0", "Lines of Runtime"], ["∞", "Formal Rigour"]].map(([v, l]) => (
              <div key={l} className="py-7 px-4" style={{ background: C.obsidian }}>
                <div className="font-serif text-[34px] leading-none" style={{ color: C.brass, fontWeight: 300 }}>{v}</div>
                <div className="font-mono text-[8.5px] tracking-[0.26em] uppercase mt-3" style={{ color: C.ash }}>{l}</div>
              </div>
            ))}
          </motion.div>

          <motion.p initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}
            transition={{ duration: 1.2, delay: 0.62 }}
            className="font-serif text-[16px] leading-[1.85] mt-12 max-w-[58ch] mx-auto"
            style={{ color: C.ash, fontWeight: 300 }}>
            Built alongside an autonomous LLM multi-agent swarm — a cathedral raised by many hands,
            directed by one, and inspected line by line against the formal specification.
          </motion.p>
        </div>
      </section>

      {/* ── COLOPHON ───────────────────────────────────────────── */}
      <footer className="relative pt-20 pb-14 px-8" style={{ borderTop: `1px solid ${C.goldFaint}` }}>
        <div className="max-w-[1180px] mx-auto">
          <div className="mb-12"><RuleDouble label="Colophon" /></div>

          <div className="grid md:grid-cols-[1.4fr_1fr_1fr_1fr] gap-10 mb-14">
            <div>
              <div className="flex items-center gap-3 mb-5">
                <Fleuron size={18} tone={C.brass} />
                <span className="font-serif text-[26px] tracking-[0.12em]" style={{ color: C.parchment, fontWeight: 400 }}>
                  ROCHE
                </span>
              </div>
              <p className="font-serif text-[15px] leading-[1.8] max-w-[38ch]"
                style={{ color: C.ash, fontWeight: 300 }}>
                A high-throughput formal invariant verifier and state fuzzer for the Ethereum
                Virtual Machine. Written in Zig 0.16.0. Licensed MIT / Apache-2.0.
              </p>
            </div>

            {[
              { h: "Codex", l: [["Repository", "https://github.com/creatorofaurad/Roche"], ["Verification Audit", "https://github.com/creatorofaurad/Roche/blob/main/VERIFICATION_AUDIT.md"], ["Releases", "https://github.com/creatorofaurad/Roche/releases"]] },
              { h: "Doctrina", l: [["The Plates", "#plates"], ["Invariants", "#invariants"], ["Anomalies", "#anomalies"], ["The Ledger", "#ledger"]] },
              { h: "Architectvs", l: [["Charles", "#architect"], ["@coolkidsdontcode", "https://github.com/creatorofaurad"], ["Contact", "#architect"]] },
            ].map((col) => (
              <div key={col.h}>
                <div className="font-mono text-[9px] tracking-[0.3em] uppercase mb-5" style={{ color: C.brass }}>
                  {col.h}
                </div>
                <ul className="space-y-3">
                  {col.l.map(([label, href]) => (
                    <li key={label}>
                      <a href={href} target={href.startsWith("http") ? "_blank" : undefined}
                        rel={href.startsWith("http") ? "noreferrer" : undefined}
                        className="font-serif text-[15px] transition-colors"
                        style={{ color: C.ash, textDecoration: "none" }}
                        onMouseEnter={(e) => { e.currentTarget.style.color = C.gold; }}
                        onMouseLeave={(e) => { e.currentTarget.style.color = C.ash; }}>
                        {label}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>

          <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-5"
            style={{ borderTop: `1px solid ${C.goldFaint}` }}>
            <div className="flex items-center gap-2.5 font-mono text-[9px] tracking-[0.2em]" style={{ color: C.gold }}>
              <span className="w-1.5 h-1.5 rounded-full animate-pulse" style={{ background: C.brass }} />
              KERNEL ONLINE · 34/34 SUITES PASSING · 0 BYTES LEAKED
            </div>
            <div className="font-mono text-[9px] tracking-[0.2em] text-center sm:text-right" style={{ color: "#5C554A" }}>
              AUDITED ON BARE SILICON BY YELENA · XX·IX·MMXXVI<br />
              OPVS PERFECTVM EST · NON SEQVIMVR TRENDS
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}