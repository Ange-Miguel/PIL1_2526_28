/* ═══════════════════════════════════════════════════════════════
   IFRI_MentorLink — app.js  (utilitaires partagés)
   ═══════════════════════════════════════════════════════════════ */

/* ── FAUX STORE SESSION (localStorage) ─────────────────────────── */
const ML = {
  // Retourne l'utilisateur connecté (objet) ou null
  currentUser() {
    try { return JSON.parse(localStorage.getItem('ml_user')); } catch { return null; }
  },
  // Connecte un utilisateur
  login(user) {
    localStorage.setItem('ml_user', JSON.stringify(user));
  },
  // Déconnecte
  logout() {
    localStorage.removeItem('ml_user');
    window.location.href = 'connexion.html';
  },
  // Sauvegarde les données d'un module
  save(key, data) {
    localStorage.setItem(key, JSON.stringify(data));
  },
  load(key, fallback = null) {
    try { return JSON.parse(localStorage.getItem(key)) ?? fallback; } catch { return fallback; }
  },
  // Génère un id unique
  uid() { return '_' + Math.random().toString(36).substr(2, 9); },
  // Formate une date relative
  timeAgo(ts) {
    const diff = Date.now() - ts;
    if (diff < 60000) return 'À l\'instant';
    if (diff < 3600000) return Math.floor(diff/60000) + ' min';
    if (diff < 86400000) return Math.floor(diff/3600000) + 'h';
    return new Date(ts).toLocaleDateString('fr-FR');
  },
  // Initiales
  initials(name) {
    return name ? name.split(' ').map(p => p[0]).join('').toUpperCase().slice(0, 2) : '?';
  }
};

/* ── SEED DONNÉES DÉMO ──────────────────────────────────────────── */
function seedDemoData() {
  if (ML.load('ml_seeded')) return;

  const users = [
    { id: 'u1', nom: 'AKPANON', prenom: 'Ange-Miguel', email: 'ange@ifri.bj', tel: '62000001', filiere: 'SE&IoT', niveau: 'L1', password: '1234', role: 'both', competences: ['Python', 'Algorithmes', 'HTML/CSS'], lacunes: ['Mathématiques', 'Probabilités'], bio: 'Passionné des objets connectés et du dev web.', disponibilites: ['Lundi 14h-18h', 'Mercredi 10h-12h'], photo: null },
    { id: 'u2', nom: 'SOSSOU', prenom: 'Merveilles', email: 'merveilles@ifri.bj', tel: '62000002', filiere: 'GL', niveau: 'L1', password: '1234', role: 'mentor', competences: ['Java', 'UML', 'Bases de données', 'Mathématiques'], lacunes: ['Réseaux'], bio: 'J\'aime partager mes connaissances en génie logiciel.', disponibilites: ['Mardi 15h-17h', 'Jeudi 10h-13h'], photo: null },
    { id: 'u3', nom: 'KPATINVOH', prenom: 'Charis', email: 'charis@ifri.bj', tel: '62000003', filiere: 'IA', niveau: 'L1', password: '1234', role: 'mentoré', competences: ['Python'], lacunes: ['Algèbre linéaire', 'Statistiques', 'Machine Learning'], bio: 'Curieuse et motivée à apprendre l\'IA.', disponibilites: ['Lundi 8h-12h', 'Vendredi 14h-16h'], photo: null },
    { id: 'u4', nom: 'GBESSEMEHLAN', prenom: 'Sènami', email: 'senami@ifri.bj', tel: '62000004', filiere: 'IM', niveau: 'L1', password: '1234', role: 'both', competences: ['Réseaux', 'Linux', 'Cybersécurité'], lacunes: ['Python', 'Développement web'], bio: 'Spécialiste en infrastructure réseau.', disponibilites: ['Mercredi 14h-18h', 'Samedi 9h-12h'], photo: null },
    { id: 'u5', nom: 'N\'DA', prenom: 'Prielle', email: 'prielle@ifri.bj', tel: '62000005', filiere: 'SI', niveau: 'L1', password: '1234', role: 'mentor', competences: ['SQL', 'Bases de données', 'Merise', 'Statistiques'], lacunes: ['Développement mobile'], bio: 'Expérimentée en gestion et analyse de données.', disponibilites: ['Lundi 10h-12h', 'Mercredi 16h-18h'], photo: null }
  ];

  const offres = [
    { id: 'o1', userId: 'u2', type: 'offre', matieres: ['Java', 'UML'], disponibilites: ['Mardi 15h-17h'], format: 'presentiel', description: 'Je propose des séances d\'initiation à Java et à la modélisation UML.', date: Date.now() - 86400000 },
    { id: 'o2', userId: 'u5', type: 'offre', matieres: ['SQL', 'Merise'], disponibilites: ['Lundi 10h-12h'], format: 'online', description: 'Aide pour la conception de bases de données avec Merise et SQL.', date: Date.now() - 172800000 },
    { id: 'o3', userId: 'u4', type: 'offre', matieres: ['Réseaux', 'Linux'], disponibilites: ['Samedi 9h-12h'], format: 'hybrid', description: 'Formation à l\'administration réseaux Linux.', date: Date.now() - 3600000 },
    { id: 'd1', userId: 'u3', type: 'demande', matieres: ['Algèbre linéaire', 'Statistiques'], disponibilites: ['Lundi 8h-12h'], format: 'online', description: 'Besoin d\'aide pour comprendre les bases de l\'algèbre linéaire.', date: Date.now() - 7200000 },
    { id: 'd2', userId: 'u1', type: 'demande', matieres: ['Mathématiques', 'Probabilités'], disponibilites: ['Mercredi 10h-12h'], format: 'presentiel', description: 'Je cherche quelqu\'un pour m\'aider avec les probabilités.', date: Date.now() - 3600000 * 5 }
  ];

  const messages = [
    { id: 'm1', convId: 'conv_u1_u2', senderId: 'u2', receiverId: 'u1', text: 'Bonjour Ange ! Je peux t\'aider avec les maths.', ts: Date.now() - 3600000 },
    { id: 'm2', convId: 'conv_u1_u2', senderId: 'u1', receiverId: 'u2', text: 'Super ! Merci Merveilles, quand es-tu disponible ?', ts: Date.now() - 3000000 },
    { id: 'm3', convId: 'conv_u1_u2', senderId: 'u2', receiverId: 'u1', text: 'Mardi à 15h ça te convient ?', ts: Date.now() - 1800000 }
  ];

  ML.save('ml_users', users);
  ML.save('ml_offres', offres);
  ML.save('ml_messages', messages);
  ML.save('ml_seeded', true);
}

/* ── PROTECTION DES PAGES ───────────────────────────────────────── */
function requireAuth() {
  if (!ML.currentUser()) {
    window.location.href = 'connexion.html';
  }
}
function requireGuest() {
  if (ML.currentUser()) {
    window.location.href = 'accueil.html';
  }
}

/* ── NAVBAR DYNAMIQUE ───────────────────────────────────────────── */
function renderNavbar(activePage = '') {
  const user = ML.currentUser();
  const navEl = document.getElementById('navbar');
  if (!navEl) return;

  const pages = [
    { href: 'accueil.html',   label: 'Accueil'     },
    { href: 'matching.html',  label: 'Matching'    },
    { href: 'offres.html',    label: 'Offres & Demandes' },
    { href: 'messagerie.html',label: 'Messagerie'  },
    { href: 'profil.html',    label: 'Mon Profil'  },
  ];

  const links = pages.map(p =>
    `<a href="${p.href}" class="${activePage === p.href ? 'active' : ''}">${p.label}</a>`
  ).join('');

  const authSection = user
    ? `<div class="flex items-center gap-8">
         <span style="color:var(--g5);font-size:12px;font-weight:600">${user.prenom}</span>
         <a href="profil.html" class="avatar avatar-sm">${ML.initials(user.prenom + ' ' + user.nom)}</a>
         <button class="btn btn-ghost btn-sm" onclick="ML.logout()">Déconnexion</button>
       </div>`
    : `<div class="flex gap-8">
         <a href="connexion.html" class="btn btn-ghost btn-sm">Connexion</a>
         <a href="inscription.html" class="btn btn-primary btn-sm">S'inscrire</a>
       </div>`;

  navEl.innerHTML = `
    <nav class="navbar">
      <div class="container">
        <a href="accueil.html" class="nav-brand">
          <div class="nav-logo"><img src="../assets/images/logo.jpg" alt="Logo"></div>
          <span class="nav-brand-name">IFRI_<span>MentorLink</span></span>
        </a>
        <div class="nav-links">${links}</div>
        <div class="nav-actions">${authSection}</div>
      </div>
    </nav>`;
}

/* ── FOOTER ─────────────────────────────────────────────────────── */
function renderFooter() {
  const el = document.getElementById('footer');
  if (!el) return;
  el.innerHTML = `
    <footer class="site-footer">
      <div class="footer-logo">IFRI_<span>MentorLink</span></div>
      <p>Université d'Abomey-Calavi · Institut de Formation et de Recherche en Informatique</p>
      <p style="margin-top:6px">© 2026 Groupe 28 — Projet Intégrateur L1</p>
    </footer>`;
}

/* ── MODALES ─────────────────────────────────────────────────────── */
function openModal(id) {
  const m = document.getElementById(id);
  if (m) m.classList.add('open');
}
function closeModal(id) {
  const m = document.getElementById(id);
  if (m) m.classList.remove('open');
}
// Fermeture en cliquant en dehors
document.addEventListener('click', e => {
  if (e.target.classList.contains('modal-overlay')) {
    e.target.classList.remove('open');
  }
});

/* ── TABS ────────────────────────────────────────────────────────── */
function initTabs(container) {
  const btns = container.querySelectorAll('.tab-btn');
  const panes = container.querySelectorAll('.tab-pane');
  btns.forEach(btn => {
    btn.addEventListener('click', () => {
      btns.forEach(b => b.classList.remove('active'));
      panes.forEach(p => p.classList.remove('active'));
      btn.classList.add('active');
      const target = container.querySelector('#' + btn.dataset.tab);
      if (target) target.classList.add('active');
    });
  });
}

/* ── TAG INPUT ───────────────────────────────────────────────────── */
function initTagInput(container, onChange) {
  const tagsDisplay = container.querySelector('.tags-container');
  const hiddenInput = container.querySelector('input[type=hidden]');
  let tags = [];

  function render() {
    tagsDisplay.innerHTML = '';
    tags.forEach((t, i) => {
      const span = document.createElement('span');
      span.className = 'tag-item';
      span.innerHTML = `${t} <span class="tag-remove" data-i="${i}">×</span>`;
      tagsDisplay.appendChild(span);
    });
    const inp = document.createElement('input');
    inp.className = 'tags-input';
    inp.placeholder = 'Ajouter...';
    inp.addEventListener('keydown', e => {
      if ((e.key === 'Enter' || e.key === ',') && inp.value.trim()) {
        e.preventDefault();
        const val = inp.value.trim().replace(',', '');
        if (val && !tags.includes(val)) { tags.push(val); render(); if(onChange) onChange(tags); }
        else inp.value = '';
      }
      if (e.key === 'Backspace' && !inp.value && tags.length) {
        tags.pop(); render(); if(onChange) onChange(tags);
      }
    });
    tagsDisplay.appendChild(inp);
    tagsDisplay.addEventListener('click', e2 => {
      if (e2.target.classList.contains('tag-remove')) {
        tags.splice(+e2.target.dataset.i, 1); render(); if(onChange) onChange(tags);
      } else inp.focus();
    });
    if (hiddenInput) hiddenInput.value = JSON.stringify(tags);
  }
  render();
  return { getTags: () => tags, setTags: (t) => { tags = t; render(); } };
}

/* ── TOAST NOTIFICATION ──────────────────────────────────────────── */
function showToast(msg, type = 'success') {
  const colors = { success: 'var(--g2)', danger: 'var(--danger)', info: 'var(--info)' };
  const toast = document.createElement('div');
  toast.style.cssText = `
    position:fixed;bottom:24px;right:24px;z-index:9999;
    background:${colors[type]};color:#fff;
    padding:12px 20px;border-radius:10px;
    font-family:var(--font);font-size:13px;font-weight:600;
    box-shadow:0 4px 20px rgba(0,0,0,.2);
    animation:fadeInUp .3s ease;
    max-width:320px;
  `;
  toast.textContent = msg;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 3500);
}

/* ── INIT GLOBAL ─────────────────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', () => {
  seedDemoData();
  renderFooter();
});
