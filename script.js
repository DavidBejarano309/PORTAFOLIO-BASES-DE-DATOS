// ===========================================================
// David Felipe Bejarano Montes — E-Portafolio Bases de Datos 2
// ===========================================================

document.addEventListener('DOMContentLoaded', () => {
  // Año dinámico en el footer
  const yearEl = document.getElementById('year');
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  // Menú móvil
  const navToggle = document.getElementById('navToggle');
  const navLinks = document.getElementById('navLinks');
  if (navToggle && navLinks) {
    navToggle.addEventListener('click', () => {
      const isOpen = navLinks.classList.toggle('is-open');
      navToggle.setAttribute('aria-expanded', String(isOpen));
    });
    navLinks.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        navLinks.classList.remove('is-open');
        navToggle.setAttribute('aria-expanded', 'false');
      });
    });
  }

  // Efecto de escritura en la terminal del hero
  const query = "SELECT * FROM estudiantes WHERE nombre = 'David Felipe Bejarano Montes';";
  const typedEl = document.getElementById('typedQuery');
  const cursorEl = document.getElementById('cursor');
  const resultEl = document.getElementById('terminalResult');
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  if (typedEl) {
    if (prefersReducedMotion) {
      typedEl.textContent = query;
      if (resultEl) resultEl.hidden = false;
    } else {
      let i = 0;
      const typeSpeed = 28;
      const typeNext = () => {
        if (i < query.length) {
          typedEl.textContent += query.charAt(i);
          i++;
          setTimeout(typeNext, typeSpeed);
        } else {
          setTimeout(() => {
            if (resultEl) resultEl.hidden = false;
            if (cursorEl) cursorEl.style.opacity = '0.4';
          }, 300);
        }
      };
      setTimeout(typeNext, 500);
    }
  }

  // Reveal de secciones al hacer scroll
  const revealTargets = document.querySelectorAll(
    '.section__title, .cards, .card, .about__grid, .presentacion__photo, .presentacion__copy, .skills, .quote'
  );
  revealTargets.forEach(el => el.classList.add('reveal'));

  if ('IntersectionObserver' in window && !prefersReducedMotion) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15 });

    revealTargets.forEach(el => observer.observe(el));
  } else {
    revealTargets.forEach(el => el.classList.add('is-visible'));
  }

  // Resaltar el enlace activo del menú según la sección visible
  const sections = document.querySelectorAll('main section[id]');
  const navAnchors = document.querySelectorAll('.nav__links a');

  if ('IntersectionObserver' in window && sections.length) {
    const navObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        const id = entry.target.getAttribute('id');
        const link = document.querySelector(`.nav__links a[href="#${id}"]`);
        if (!link) return;
        if (entry.isIntersecting) {
          navAnchors.forEach(a => a.style.color = '');
          link.style.color = 'var(--cyan)';
        }
      });
    }, { rootMargin: '-40% 0px -50% 0px' });

    sections.forEach(section => navObserver.observe(section));
  }
});
