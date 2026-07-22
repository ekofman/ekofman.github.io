/* =====================================================================
   Eric Kofman — site interactions
   1) scroll-reveal (spotlight up)   2) active nav highlight
   3) mobile menu                    4) rotating role words
   All motion respects prefers-reduced-motion.
   ===================================================================== */
(function () {
  "use strict";

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------- 1. Scroll reveal + act spotlights ---------- */
  const revealTargets = document.querySelectorAll(".reveal, .act");

  if ("IntersectionObserver" in window && !reduceMotion) {
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("in-view");
            // reveal children only once; acts keep their spotlight
            if (!entry.target.classList.contains("act")) {
              io.unobserve(entry.target);
            }
          } else if (entry.target.classList.contains("act")) {
            // let the spotlight fade back out when the act leaves
            entry.target.classList.remove("in-view");
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
    );
    revealTargets.forEach((el) => io.observe(el));
  } else {
    revealTargets.forEach((el) => el.classList.add("in-view"));
  }

  /* ---------- 2. Sticky marquee: scrolled state + active link ---------- */
  const marquee = document.getElementById("marquee");
  const navLinks = Array.from(document.querySelectorAll("[data-nav]"));
  const sections = navLinks
    .map((a) => document.getElementById(a.getAttribute("data-nav")))
    .filter(Boolean);

  const onScroll = () => {
    marquee.classList.toggle("is-scrolled", window.scrollY > 24);

    // active section = the last one whose top has passed the nav line
    const line = window.innerHeight * 0.35;
    let current = null;
    for (const sec of sections) {
      if (sec.getBoundingClientRect().top <= line) current = sec.id;
    }
    navLinks.forEach((a) =>
      a.classList.toggle("is-active", a.getAttribute("data-nav") === current)
    );
  };

  /* ---------- Parallax: titles drift up faster than their sections ---------- */
  const parallaxEls = Array.from(document.querySelectorAll("[data-parallax]"));
  const updateParallax = () => {
    if (reduceMotion) return;
    const half = window.innerHeight / 2;
    for (const el of parallaxEls) {
      const speed = parseFloat(el.dataset.parallax) || 0.12;
      const rect = el.getBoundingClientRect();
      // distance of the element's center from the viewport center:
      // below center -> pushed down (lags), above center -> pulled up (leads)
      const fromCenter = rect.top + rect.height / 2 - half;
      const offset = fromCenter * speed;
      el.style.transform = "translate3d(0," + offset.toFixed(1) + "px,0)";
    }
  };

  let ticking = false;
  const tick = () => {
    onScroll();
    updateParallax();
    ticking = false;
  };
  window.addEventListener(
    "scroll",
    () => {
      if (!ticking) {
        window.requestAnimationFrame(tick);
        ticking = true;
      }
    },
    { passive: true }
  );
  window.addEventListener("resize", tick, { passive: true });
  tick();

  /* ---------- 3. Mobile menu ---------- */
  const toggle = document.getElementById("navToggle");
  if (toggle) {
    toggle.addEventListener("click", () => {
      const open = marquee.classList.toggle("is-open");
      toggle.setAttribute("aria-expanded", String(open));
      toggle.setAttribute("aria-label", open ? "Close menu" : "Open menu");
    });
    // close after choosing a destination
    marquee.querySelectorAll(".marquee__nav a").forEach((a) =>
      a.addEventListener("click", () => {
        marquee.classList.remove("is-open");
        toggle.setAttribute("aria-expanded", "false");
      })
    );
  }

  /* ---------- 4. Rotating role words ---------- */
  const rotator = document.getElementById("rotator");
  if (rotator && !reduceMotion) {
    const roles = ["storyteller", "artist", "scientist", "songwriter"];
    let i = 0;
    const span = rotator.querySelector(".is-active");
    setInterval(() => {
      i = (i + 1) % roles.length;
      span.style.transition = "opacity .35s ease, transform .35s ease";
      span.style.opacity = "0";
      span.style.transform = "translateY(6px)";
      setTimeout(() => {
        span.textContent = roles[i];
        span.style.opacity = "1";
        span.style.transform = "none";
      }, 360);
    }, 2600);
  }

  /* ---------- 5. Art galleries (grouped) + shared lightbox ---------- */
  // manifest is an object like { cartoons: [...], paintings: [...] }.
  // (older flat-array manifests are treated as a single "cartoons" group.)
  let artwork = window.ARTWORK || {};
  if (Array.isArray(artwork)) artwork = { cartoons: artwork };

  // which subsection grid maps to which manifest group + its folder
  const galleries = [
    { gridId: "cartoonsGrid", group: "cartoons" },
    { gridId: "paintingsGrid", group: "paintings" },
  ];

  const anyItems = galleries.some((g) => {
    const el = document.getElementById(g.gridId);
    return el && Array.isArray(artwork[g.group]) && artwork[g.group].length;
  });

  if (anyItems) {
    // one shared lightbox; the active list is swapped in when a grid is opened
    const lb = document.createElement("div");
    lb.className = "lightbox";
    lb.innerHTML =
      '<button class="lightbox__close" aria-label="Close">&times;</button>' +
      '<button class="lightbox__nav lightbox__prev" aria-label="Previous">&lsaquo;</button>' +
      '<img class="lightbox__img" alt="">' +
      '<button class="lightbox__nav lightbox__next" aria-label="Next">&rsaquo;</button>' +
      '<div class="lightbox__caption"></div>';
    document.body.appendChild(lb);
    const lbImg = lb.querySelector(".lightbox__img");
    const lbCap = lb.querySelector(".lightbox__caption");
    let activeList = [];
    let idx = 0;

    const show = (i) => {
      if (!activeList.length) return;
      idx = (i + activeList.length) % activeList.length;
      lbImg.src = activeList[idx].full; // full-size loads only when opened
      lbImg.alt = activeList[idx].alt;
      lbCap.textContent = activeList[idx].alt;
    };
    const openList = (list, i) => {
      activeList = list;
      show(i);
      lb.classList.add("is-open");
      document.body.style.overflow = "hidden";
    };
    const close = () => {
      lb.classList.remove("is-open");
      document.body.style.overflow = "";
      lbImg.removeAttribute("src");
    };
    lb.querySelector(".lightbox__close").addEventListener("click", close);
    lb.querySelector(".lightbox__prev").addEventListener("click", (e) => { e.stopPropagation(); show(idx - 1); });
    lb.querySelector(".lightbox__next").addEventListener("click", (e) => { e.stopPropagation(); show(idx + 1); });
    lb.addEventListener("click", (e) => { if (e.target === lb) close(); });
    document.addEventListener("keydown", (e) => {
      if (!lb.classList.contains("is-open")) return;
      if (e.key === "Escape") close();
      else if (e.key === "ArrowLeft") show(idx - 1);
      else if (e.key === "ArrowRight") show(idx + 1);
    });

    // populate each gallery grid that has images
    galleries.forEach(({ gridId, group }) => {
      const grid = document.getElementById(gridId);
      const files = Array.isArray(artwork[group]) ? artwork[group] : [];
      if (!grid || !files.length) return;

      const base = "images/artwork/" + group + "/";
      const items = files.map((file) => {
        const safe = String(file).replace(/"/g, "");
        const enc = encodeURIComponent(safe);
        const alt = safe.replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ").trim();
        return { thumb: base + "thumbs/" + enc, full: base + enc, alt: alt };
      });

      grid.innerHTML = items
        .map(
          (it, i) =>
            '<figure class="frame" data-i="' + i + '" tabindex="0" role="button" aria-label="Open ' +
            it.alt + '"><img src="' + it.thumb + '" alt="' + it.alt +
            '" loading="lazy" decoding="async"></figure>'
        )
        .join("");

      // missing thumbnail -> fall back to the full image
      grid.querySelectorAll("img").forEach((img, i) => {
        img.addEventListener("error", function handler() {
          img.removeEventListener("error", handler);
          img.src = items[i].full;
        });
      });

      grid.querySelectorAll(".frame").forEach((fr) => {
        const openIt = () => openList(items, parseInt(fr.dataset.i, 10));
        fr.addEventListener("click", openIt);
        fr.addEventListener("keydown", (e) => {
          if (e.key === "Enter" || e.key === " ") { e.preventDefault(); openIt(); }
        });
      });
    });
  }
})();
