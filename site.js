const siteHeader = document.querySelector(".site-header");
const heroProfileImage = document.querySelector(".hero-media .image-shell img");

const updateHeaderState = () => {
  if (!siteHeader) {
    return;
  }

  siteHeader.classList.toggle("is-scrolled", window.scrollY > 24);
};

updateHeaderState();
window.addEventListener("scroll", updateHeaderState, { passive: true });

if (heroProfileImage) {
  const heroImageShell = heroProfileImage.closest(".image-shell");

  const markHeroImageLoaded = () => {
    heroImageShell?.classList.remove("is-image-failed");
  };

  const markHeroImageFailed = () => {
    heroImageShell?.classList.add("is-image-failed");
  };

  heroProfileImage.addEventListener("load", markHeroImageLoaded, { once: true });

  if (!heroProfileImage.complete) {
    heroProfileImage.addEventListener("error", markHeroImageFailed, { once: true });
  } else if (heroProfileImage.naturalWidth === 0) {
    markHeroImageFailed();
  } else {
    markHeroImageLoaded();
  }
}

const revealTargets = Array.from(
  document.querySelectorAll(
    ".hero-copy > *, .hero-media, .profile-copy > *, .experience-intro > *, .experience-logo-card, .experience-entry, .highlight-card, .image-grid .image-shell, .event-grid > *, .marquee, .kpi-card, .kpi-main-image, .contact-box > *, .source-image"
  )
);

revealTargets.forEach((element, index) => {
  element.setAttribute("data-reveal", "");
  element.style.setProperty("--reveal-order", String(index % 6));
});

const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

if (!reduceMotion && "IntersectionObserver" in window) {
  const revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) {
          return;
        }

        entry.target.classList.add("is-visible");
        revealObserver.unobserve(entry.target);
      });
    },
    {
      threshold: 0.16,
      rootMargin: "0px 0px -8% 0px"
    }
  );

  revealTargets.forEach((element) => revealObserver.observe(element));
} else {
  revealTargets.forEach((element) => element.classList.add("is-visible"));
}

const parallaxTargets = Array.from(
  document.querySelectorAll(".hero-media .image-shell, .image-grid .image-shell, .source-image")
);

let rafId = 0;

const updateParallax = () => {
  rafId = 0;

  parallaxTargets.forEach((element) => {
    const rect = element.getBoundingClientRect();
    const viewportCenter = window.innerHeight * 0.5;
    const elementCenter = rect.top + rect.height * 0.5;
    const distance = (elementCenter - viewportCenter) / window.innerHeight;
    const shift = Math.max(-14, Math.min(14, distance * -22));
    element.style.setProperty("--parallax-shift", shift.toFixed(2));
  });
};

const requestParallax = () => {
  if (reduceMotion || rafId) {
    return;
  }

  rafId = window.requestAnimationFrame(updateParallax);
};

updateParallax();
window.addEventListener("scroll", requestParallax, { passive: true });
window.addEventListener("resize", requestParallax);

const zoomableImages = Array.from(
  document.querySelectorAll(".image-shell img")
);

if (zoomableImages.length > 0) {
  const lightbox = document.createElement("div");
  lightbox.className = "lightbox";
  lightbox.innerHTML = `
    <div class="lightbox__panel">
      <button class="lightbox__close" type="button" aria-label="Close image view">&times;</button>
      <img class="lightbox__image" alt="" />
    </div>
  `;

  const lightboxImage = lightbox.querySelector(".lightbox__image");
  const closeButton = lightbox.querySelector(".lightbox__close");

  const openLightbox = (image) => {
    if (!lightboxImage) {
      return;
    }

    lightboxImage.src = image.currentSrc || image.src;
    lightboxImage.alt = image.alt || "";
    lightbox.classList.add("is-open");
    document.body.style.overflow = "hidden";
  };

  const closeLightbox = () => {
    lightbox.classList.remove("is-open");
    document.body.style.overflow = "";
    window.setTimeout(() => {
      if (!lightbox.classList.contains("is-open") && lightboxImage) {
        lightboxImage.src = "";
      }
    }, 180);
  };

  zoomableImages.forEach((image) => {
    image.classList.add("zoomable-image");
    image.addEventListener("click", () => openLightbox(image));
    image.addEventListener("dblclick", () => openLightbox(image));
  });

  closeButton?.addEventListener("click", closeLightbox);
  lightbox.addEventListener("click", (event) => {
    if (event.target === lightbox) {
      closeLightbox();
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && lightbox.classList.contains("is-open")) {
      closeLightbox();
    }
  });

  document.body.appendChild(lightbox);
}
