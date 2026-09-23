/**
 * Main JavaScript Controller
 * - EaseOutCubic count-up numbers with exact staggered delay
 * - IntersectionObserver (threshold: 0.25)
 * - Mobile drawer state management (Escape, backdrop click, resize, aria-expanded)
 */

document.addEventListener("DOMContentLoaded", () => {
  initCountUp();
  initMobileMenu();
});

/**
 * 1. Count-up Stats Animation
 * Easing: easeOutCubic
 * Duration: 1500 + i * 80 ms
 * Start Offset: 480 + i * 90 ms
 */
function initCountUp() {
  const statElements = document.querySelectorAll(".stat-val");
  if (!statElements.length) return;

  const easeOutCubic = (t) => 1 - Math.pow(1 - t, 3);

  const startAnimation = () => {
    statElements.forEach((el, index) => {
      const target = parseFloat(el.getAttribute("data-target")) || 0;
      const decimals = parseInt(el.getAttribute("data-decimals"), 10) || 0;
      const suffix = el.getAttribute("data-suffix") || "";
      const duration = 1500 + index * 80;
      const delay = 480 + index * 90;

      setTimeout(() => {
        let startTime = null;

        const step = (timestamp) => {
          if (!startTime) startTime = timestamp;
          const elapsed = timestamp - startTime;
          const progress = Math.min(elapsed / duration, 1);
          const currentVal = easeOutCubic(progress) * target;

          el.textContent = `${currentVal.toFixed(decimals)}${suffix}`;

          if (progress < 1) {
            requestAnimationFrame(step);
          } else {
            el.textContent = `${target.toFixed(decimals)}${suffix}`;
          }
        };

        requestAnimationFrame(step);
      }, delay);
    });
  };

  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      (entries, obs) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            startAnimation();
            obs.disconnect();
          }
        });
      },
      { threshold: 0.25 }
    );

    const footer = document.querySelector(".stats-footer");
    if (footer) {
      observer.observe(footer);
    } else {
      startAnimation();
    }
  } else {
    startAnimation();
  }
}

/**
 * 2. Mobile Menu Controller
 * Toggles aria-expanded, body.menu-open, .burger-btn.open, and [hidden] overlay
 */
function initMobileMenu() {
  const burgerBtn = document.querySelector(".burger-btn");
  const overlay = document.querySelector(".mobile-overlay");
  const mobileLinks = document.querySelectorAll(".mobile-link, .mobile-signin");

  if (!burgerBtn || !overlay) return;

  const openMenu = () => {
    burgerBtn.classList.add("open");
    burgerBtn.setAttribute("aria-expanded", "true");
    overlay.removeAttribute("hidden");
    document.body.classList.add("menu-open");
  };

  const closeMenu = () => {
    burgerBtn.classList.remove("open");
    burgerBtn.setAttribute("aria-expanded", "false");
    overlay.setAttribute("hidden", "");
    document.body.classList.remove("menu-open");
  };

  burgerBtn.addEventListener("click", () => {
    const isOpen = burgerBtn.classList.contains("open");
    if (isOpen) {
      closeMenu();
    } else {
      openMenu();
    }
  });

  // Close on backdrop click (click outside .mobile-sheet)
  overlay.addEventListener("click", (e) => {
    if (e.target === overlay) {
      closeMenu();
    }
  });

  // Close on Escape key
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && !overlay.hasAttribute("hidden")) {
      closeMenu();
    }
  });

  // Close when clicking any menu link
  mobileLinks.forEach((link) => {
    link.addEventListener("click", () => {
      closeMenu();
    });
  });

  // Auto-close on resize > 720px
  window.addEventListener("resize", () => {
    if (window.innerWidth > 720 && !overlay.hasAttribute("hidden")) {
      closeMenu();
    }
  });
}
