"use client";

import React from "react";

export default function InDevelopmentPage() {
  return (
    <>
      {/* Full-bleed background video container */}
      <div className="bg">
        <video className="bg-video" autoPlay muted loop playsInline>
          <source
            src="https://d8j0ntlcm91z4.cloudfront.net/user_38xzZboKViGWJOttwIXH07lWA1P/hf_20260809_012548_ef22562c-c0ae-4816-ad9d-f8922af4e6a7.mp4"
            type="video/mp4"
          />
        </video>
      </div>

      {/* Single-viewport centered text */}
      <div className="page">
        <main className="hero">
          <h1 className="headline">
            Site is in development
          </h1>
        </main>
      </div>
    </>
  );
}
