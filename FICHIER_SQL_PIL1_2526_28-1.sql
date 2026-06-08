--  IFRI_MentorLink — Base de données finale
--  Projet intégrateur L1 IFRI - UAC 2025-2026
--  SGBD      : MySQL 8.0+
--  Encodage  : utf8mb4
SET FOREIGN_KEY_CHECKS = 0;

DROP DATABASE IF EXISTS ifri_mentorlink;
CREATE DATABASE ifri_mentorlink
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE ifri_mentorlink;

-- 1. FILIERES
--    Référentiel des filières disponibles à l'IFRI
--    (plus extensible qu'un simple ENUM)
CREATE TABLE filiere (
    id_filiere  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(20)  NOT NULL UNIQUE COMMENT 'Ex: IA, IM, GL, SE_IoT, SI',
    libelle     VARCHAR(100) NOT NULL,
    description TEXT
) ENGINE=InnoDB;

INSERT INTO filiere (code, libelle) VALUES
    ('IA',     'Intelligence Artificielle'),
    ('IM',     'Ingénierie Multimédia'),
    ('GL',     'Génie Logiciel'),
    ('SE_IoT', 'Systèmes Embarqués & IoT'),
    ('SI',     'Systèmes d''Information');

-- 2. MATIERES
--    Catalogue centralisé des matières et compétences
--    Évite les doublons et fautes de frappe
CREATE TABLE matiere (
    id_matiere  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom         VARCHAR(150) NOT NULL,
    categorie   VARCHAR(80)  COMMENT 'Ex: Algorithmique, Web, BD, Python',
    description TEXT
) ENGINE=InnoDB;

INSERT INTO matiere (nom, categorie) VALUES
('Développement Web',  'Web'),
('Python',             'Programmation'),
('Algorithmique',      'Algorithmique'),
('Bases de données',   'BD'),
('SQL',                'BD'),
('Machine Learning',   'IA'),
('Systèmes embarqués', 'SE'),
('C/C++',              'Programmation');

-- 3. UTILISATEURS
--    Comptes et profils de tous les utilisateurs
--    Un utilisateur peut être mentor, mentoré ou les deux
CREATE TABLE utilisateur (
    id               INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    nom              VARCHAR(100)    NOT NULL,
    prenom           VARCHAR(100)    NOT NULL,
    email            VARCHAR(150)    NOT NULL UNIQUE,
    telephone        VARCHAR(20)     NOT NULL UNIQUE,
    mot_de_passe     VARCHAR(255)    NOT NULL COMMENT 'Hashé avec bcrypt',
    photo_profil     VARCHAR(500)    DEFAULT NULL,
    id_filiere       INT UNSIGNED    NOT NULL,
    niveau           ENUM('L1','L2','L3','M1','M2') NOT NULL DEFAULT 'L1',
    bio              TEXT            DEFAULT NULL,
    est_actif        BOOLEAN         NOT NULL DEFAULT TRUE,
    date_inscription DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    derniere_connexion DATETIME      DEFAULT NULL,
    CONSTRAINT chk_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT fk_util_filiere FOREIGN KEY (id_filiere)
        REFERENCES filiere(id_filiere) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 4. COMPETENCES PAR UTILISATEUR
--    Points forts avec niveau de maîtrise (1 à 5)
CREATE TABLE competence_utilisateur (
    id_competence   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur  INT UNSIGNED NOT NULL,
    id_matiere      INT UNSIGNED NOT NULL,
    niveau_maitrise TINYINT UNSIGNED NOT NULL DEFAULT 3
        COMMENT '1=débutant, 2=intermédiaire, 3=avancé, 4=confirmé, 5=expert',
    UNIQUE KEY uq_comp_util_mat (id_utilisateur, id_matiere),
    CONSTRAINT fk_comp_util FOREIGN KEY (id_utilisateur)
        REFERENCES utilisateur(id) ON DELETE CASCADE,
    CONSTRAINT fk_comp_mat  FOREIGN KEY (id_matiere)
        REFERENCES matiere(id_matiere) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 5. LACUNES PAR UTILISATEUR
--    Points faibles avec niveau de priorité (1 à 3)
CREATE TABLE lacune_utilisateur (
    id_lacune       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur  INT UNSIGNED NOT NULL,
    id_matiere      INT UNSIGNED NOT NULL,
    priorite        TINYINT UNSIGNED NOT NULL DEFAULT 2
        COMMENT '1=faible, 2=moyenne, 3=élevée',
    date_creation   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_resolution DATETIME DEFAULT NULL COMMENT 'NULL = lacune non encore comblée',
    UNIQUE KEY uq_lacune_util_mat (id_utilisateur, id_matiere),
    CONSTRAINT fk_lac_util FOREIGN KEY (id_utilisateur)
        REFERENCES utilisateur(id) ON DELETE CASCADE,
    CONSTRAINT fk_lac_mat  FOREIGN KEY (id_matiere)
        REFERENCES matiere(id_matiere) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 6. DISPONIBILITES
--    Créneaux horaires structurés (pas de texte libre)
--    Permet la comparaison algorithmique des créneaux
CREATE TABLE disponibilite (
    id_disponibilite INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur   INT UNSIGNED NOT NULL,
    jour_semaine     ENUM('Lundi','Mardi','Mercredi','Jeudi',
                          'Vendredi','Samedi','Dimanche') NOT NULL,
    heure_debut      TIME NOT NULL,
    heure_fin        TIME NOT NULL,
    CONSTRAINT fk_dispo_util FOREIGN KEY (id_utilisateur)
        REFERENCES utilisateur(id) ON DELETE CASCADE,
    CONSTRAINT chk_horaire CHECK (heure_fin > heure_debut)
) ENGINE=InnoDB;

-- 7. TOKENS REINITIALISATION MOT DE PASSE
--    Tokens temporaires à usage unique
CREATE TABLE reset_password (
    id_token        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur  INT UNSIGNED NOT NULL,
    token           VARCHAR(255) NOT NULL UNIQUE,
    date_expiration DATETIME     NOT NULL,
    utilise         BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_token_util FOREIGN KEY (id_utilisateur)
        REFERENCES utilisateur(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 8. OFFRES ET DEMANDES DE MENTORAT
CREATE TABLE offre_mentorat (
    id                INT UNSIGNED   AUTO_INCREMENT PRIMARY KEY,
    id_auteur         INT UNSIGNED   NOT NULL,
    type_offre        ENUM('offre','demande') NOT NULL,
    format_session    ENUM('presentiel','en_ligne','les_deux') NOT NULL DEFAULT 'les_deux',
    description       TEXT           DEFAULT NULL,
    statut            ENUM('active','pourvue','annulee') NOT NULL DEFAULT 'active',
    date_creation     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_offre_auteur FOREIGN KEY (id_auteur)
        REFERENCES utilisateur(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 9. OFFRES_MATIERES
--    Association N,N entre offres et matières
--    Une offre peut cibler plusieurs matières
CREATE TABLE offre_matiere (
    id_offre_matiere INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_offre         INT UNSIGNED NOT NULL,
    id_matiere       INT UNSIGNED NOT NULL,
    UNIQUE KEY uq_offre_mat (id_offre, id_matiere),
    CONSTRAINT fk_ofmat_offre FOREIGN KEY (id_offre)
        REFERENCES offre_mentorat(id) ON DELETE CASCADE,
    CONSTRAINT fk_ofmat_mat   FOREIGN KEY (id_matiere)
        REFERENCES matiere(id_matiere) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 10. OFFRES_DISPONIBILITES
--     Créneaux horaires spécifiques à une offre
CREATE TABLE offre_disponibilite (
    id_offre_dispo INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_offre       INT UNSIGNED NOT NULL,
    jour_semaine   ENUM('Lundi','Mardi','Mercredi','Jeudi',
                        'Vendredi','Samedi','Dimanche') NOT NULL,
    heure_debut    TIME NOT NULL,
    heure_fin      TIME NOT NULL,
    CONSTRAINT fk_ofdispo_offre FOREIGN KEY (id_offre)
        REFERENCES offre_mentorat(id) ON DELETE CASCADE,
    CONSTRAINT chk_ofdispo CHECK (heure_fin > heure_debut)
) ENGINE=InnoDB;

-- 11. MATCHING MENTOR / MENTORE
--     Score décomposé : compétences + horaires + filière + niveau
CREATE TABLE match_mentorat (
    id                INT UNSIGNED     AUTO_INCREMENT PRIMARY KEY,
    id_mentor         INT UNSIGNED     NOT NULL,
    id_mentore        INT UNSIGNED     NOT NULL,
    score_total       DECIMAL(5,2)     NOT NULL DEFAULT 0.00 COMMENT 'Score global sur 100',
    score_competences DECIMAL(5,2)     NOT NULL DEFAULT 0.00,
    score_horaires    DECIMAL(5,2)     NOT NULL DEFAULT 0.00,
    score_filiere     DECIMAL(5,2)     NOT NULL DEFAULT 0.00,
    score_niveau      DECIMAL(5,2)     NOT NULL DEFAULT 0.00 COMMENT 'Proximité des niveaux d''études',
    matieres_communes TEXT             DEFAULT NULL,
    disponibilites_communes TEXT       DEFAULT NULL,
    statut            ENUM('propose','accepte','refuse','termine') NOT NULL DEFAULT 'propose',
    date_creation     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_match (id_mentor, id_mentore),
    CONSTRAINT chk_no_self_match CHECK (id_mentor <> id_mentore),	-- Empèche un utilisateur de se matche avec lui mème
    CONSTRAINT chk_score CHECK (score_total BETWEEN 0 AND 100),
    CONSTRAINT fk_match_mentor  FOREIGN KEY (id_mentor)
        REFERENCES utilisateur(id) ON DELETE CASCADE,
    CONSTRAINT fk_match_mentore FOREIGN KEY (id_mentore)
        REFERENCES utilisateur(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 12. REPONSES AUX OFFRES/DEMANDES
CREATE TABLE reponse_offre (
    id             INT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    id_offre       INT UNSIGNED  NOT NULL,
    id_repondant   INT UNSIGNED  NOT NULL,
    message        TEXT          DEFAULT NULL,
    statut         ENUM('en_attente','acceptee','refusee') NOT NULL DEFAULT 'en_attente',
    date_reponse   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_reponse (id_offre, id_repondant),
    CONSTRAINT fk_rep_offre FOREIGN KEY (id_offre)
        REFERENCES offre_mentorat(id) ON DELETE CASCADE,
    CONSTRAINT fk_rep_util  FOREIGN KEY (id_repondant)
        REFERENCES utilisateur(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 13. CONVERSATIONS
CREATE TABLE conversation (
    id              INT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    id_participant1 INT UNSIGNED  NOT NULL,
    id_participant2 INT UNSIGNED  NOT NULL,
    date_creation   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_dernier_msg DATETIME     DEFAULT NULL,
    UNIQUE KEY uq_conversation (id_participant1, id_participant2),
    CONSTRAINT chk_conv_diff CHECK (id_participant1 <> id_participant2),
    CONSTRAINT fk_conv_p1 FOREIGN KEY (id_participant1)
        REFERENCES utilisateur(id) ON DELETE CASCADE,
    CONSTRAINT fk_conv_p2 FOREIGN KEY (id_participant2)
        REFERENCES utilisateur(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 14. MESSAGES
CREATE TABLE message (
    id              INT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    id_conversation INT UNSIGNED  NOT NULL,
    id_expediteur   INT UNSIGNED  NOT NULL,
    contenu         TEXT          NOT NULL,
    est_lu          BOOLEAN       NOT NULL DEFAULT FALSE,
    date_envoi      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_msg_conv  FOREIGN KEY (id_conversation)
        REFERENCES conversation(id) ON DELETE CASCADE,
    CONSTRAINT fk_msg_exped FOREIGN KEY (id_expediteur)
        REFERENCES utilisateur(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 15. NOTIFICATIONS
CREATE TABLE notification (
    id              INT UNSIGNED  AUTO_INCREMENT PRIMARY KEY,
    id_destinataire INT UNSIGNED  NOT NULL,
    type_notif      ENUM('nouveau_message','nouveau_match',
                         'reponse_offre','offre_acceptee',
                         'offre_refusee') NOT NULL,
    contenu         VARCHAR(300)  NOT NULL,
    lien            VARCHAR(300)  DEFAULT NULL,
    est_lue         BOOLEAN       NOT NULL DEFAULT FALSE,
    date_creation   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_dest FOREIGN KEY (id_destinataire)
        REFERENCES utilisateur(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- INDEX
CREATE INDEX idx_utilisateur_email     ON utilisateur(email);
CREATE INDEX idx_utilisateur_telephone ON utilisateur(telephone);
CREATE INDEX idx_utilisateur_filiere   ON utilisateur(id_filiere);
CREATE INDEX idx_offre_statut          ON offre_mentorat(statut);
CREATE INDEX idx_offre_type            ON offre_mentorat(type_offre);
CREATE INDEX idx_match_score           ON match_mentorat(score_total DESC);
CREATE INDEX idx_match_statut          ON match_mentorat(statut);
CREATE INDEX idx_message_conv          ON message(id_conversation, date_envoi);
CREATE INDEX idx_message_lu            ON message(est_lu);
CREATE INDEX idx_notif_dest_lue        ON notification(id_destinataire, est_lue);
CREATE INDEX idx_offre_mat_matiere     ON offre_matiere(id_matiere);
CREATE INDEX idx_offre_dispo_jour      ON offre_disponibilite(jour_semaine, heure_debut);

-- VUES

-- Vue : matchings avec détails des deux utilisateurs
CREATE OR REPLACE VIEW vue_meilleurs_matchs AS
SELECT
    m.id               AS id_matching,
    m.score_total,
    m.score_competences,
    m.score_horaires,
    m.score_filiere,
    m.score_niveau,
    m.matieres_communes,
    m.disponibilites_communes,
    m.statut,
    m.date_creation,
    u1.id              AS id_mentor,
    u1.nom             AS mentor_nom,
    u1.prenom          AS mentor_prenom,
    u1.photo_profil    AS mentor_photo,
    f1.code            AS mentor_filiere,
    u1.niveau          AS mentor_niveau,
    u2.id              AS id_mentore,
    u2.nom             AS mentore_nom,
    u2.prenom          AS mentore_prenom,
    u2.photo_profil    AS mentore_photo,
    f2.code            AS mentore_filiere,
    u2.niveau          AS mentore_niveau
FROM match_mentorat m
JOIN utilisateur u1 ON m.id_mentor  = u1.id
JOIN utilisateur u2 ON m.id_mentore = u2.id
JOIN filiere    f1 ON u1.id_filiere = f1.id_filiere
JOIN filiere    f2 ON u2.id_filiere = f2.id_filiere
ORDER BY m.score_total DESC;

-- Vue : profil complet avec filière et nb compétences/lacunes
CREATE OR REPLACE VIEW vue_profil_complet AS
SELECT
    u.id,
    u.nom,
    u.prenom,
    u.email,
    u.telephone,
    u.photo_profil,
    u.bio,
    f.code             AS filiere_code,
    f.libelle          AS filiere_libelle,
    u.niveau,
    u.date_inscription,
    u.est_actif,
    COUNT(DISTINCT cu.id_competence) AS nb_competences,
    COUNT(DISTINCT lu.id_lacune)     AS nb_lacunes
FROM utilisateur u
JOIN filiere f ON u.id_filiere = f.id_filiere
LEFT JOIN competence_utilisateur cu ON u.id = cu.id_utilisateur
LEFT JOIN lacune_utilisateur     lu ON u.id = lu.id_utilisateur
GROUP BY u.id;

-- Vue : messages non lus par conversation
CREATE OR REPLACE VIEW vue_messages_non_lus AS
SELECT
    c.id_participant1,
    c.id_participant2,
    COUNT(m.id)   AS nb_non_lus,
    m.id_expediteur
FROM message m
JOIN conversation c ON c.id = m.id_conversation
WHERE m.est_lu = FALSE
GROUP BY c.id_participant1, c.id_participant2, m.id_expediteur;

-- DONNEES DE TEST

-- Utilisateurs
INSERT INTO utilisateur (nom, prenom, email, telephone, mot_de_passe, id_filiere, niveau, bio) VALUES
('Akpanon',  'Ange-Miguel', 'ange.akpanon@ifri.uac.bj',   '+22961000001', '$2b$12$hash1', 3, 'L1', 'Passionné de développement web.'),
('Gbaguidi', 'Marie',       'marie.gbaguidi@ifri.uac.bj',  '+22961000002', '$2b$12$hash2', 1, 'L1', 'Intéressée par le machine learning.'),
('Mensah',   'Koffi',       'koffi.mensah@ifri.uac.bj',    '+22961000003', '$2b$12$hash3', 2, 'L1', 'Fort en algorithmique et BDD.'),
('Diallo',   'Fatou',       'fatou.diallo@ifri.uac.bj',    '+22961000004', '$2b$12$hash4', 5, 'L1', 'Spécialisée en systèmes d info.'),
('Bello',    'Romaric',     'romaric.bello@ifri.uac.bj',   '+22961000005', '$2b$12$hash5', 4, 'L1', 'Passionné par les systèmes embarqués.');

-- Compétences (forces)
INSERT INTO competence_utilisateur (id_utilisateur, id_matiere, niveau_maitrise) VALUES
(1, 1, 4),  -- Ange-Miguel : Développement Web (confirmé)
(1, 2, 3),  -- Ange-Miguel : Python (avancé)
(2, 6, 4),  -- Marie : Machine Learning (confirmé)
(2, 2, 3),  -- Marie : Python (avancé)
(3, 3, 5),  -- Koffi : Algorithmique (expert)
(3, 4, 4),  -- Koffi : Bases de données (confirmé)
(4, 4, 4),  -- Fatou : Bases de données (confirmé)
(4, 5, 5),  -- Fatou : SQL (expert)
(5, 7, 4),  -- Romaric : Systèmes embarqués (confirmé)
(5, 8, 4);  -- Romaric : C/C++ (confirmé)

-- Lacunes
INSERT INTO lacune_utilisateur (id_utilisateur, id_matiere, priorite) VALUES
(1, 3, 2),  -- Ange-Miguel : Algorithmique (priorité moyenne)
(2, 1, 3),  -- Marie : Développement Web (priorité élevée)
(3, 6, 2),  -- Koffi : Machine Learning (priorité moyenne)
(4, 2, 3),  -- Fatou : Python (priorité élevée)
(5, 1, 3);  -- Romaric : Développement Web (priorité élevée)

-- Disponibilités
INSERT INTO disponibilite (id_utilisateur, jour_semaine, heure_debut, heure_fin) VALUES
(1, 'Lundi',    '14:00', '18:00'),
(1, 'Mercredi', '10:00', '12:00'),
(2, 'Mardi',    '15:00', '17:00'),
(2, 'Jeudi',    '14:00', '16:00'),
(3, 'Lundi',    '08:00', '12:00'),
(3, 'Vendredi', '14:00', '18:00'),
(4, 'Mercredi', '14:00', '18:00'),
(4, 'Samedi',   '09:00', '12:00'),
(5, 'Jeudi',    '10:00', '14:00'),
(5, 'Vendredi', '08:00', '12:00');

-- Offres et demandes
INSERT INTO offre_mentorat (id_auteur, type_offre, format_session, description) VALUES
(1, 'offre',   'les_deux',  'Je peux aider en Développement Web'),
(2, 'demande', 'en_ligne',  'Cherche aide en Développement Web'),
(3, 'offre',   'presentiel','Je peux aider en Algorithmique'),
(3, 'offre',   'les_deux',  'Je peux aider en Bases de données'),
(4, 'demande', 'en_ligne',  'Cherche aide en Python'),
(5, 'demande', 'les_deux',  'Cherche aide en Développement Web');

-- Association offres / matières
INSERT INTO offre_matiere (id_offre, id_matiere) VALUES
(1, 1), -- offre 1
(2, 1), -- demande 2
(3, 3), -- offre 3
(4, 4), -- offre 4
(5, 2), -- demande 5
(6, 1); -- demande 6

-- Disponibilités des offres
INSERT INTO offre_disponibilite (id_offre, jour_semaine, heure_debut, heure_fin) VALUES
(1, 'Lundi',    '14:00', '18:00'),
(2, 'Mardi',    '15:00', '17:00'),
(3, 'Lundi',    '08:00', '12:00'),
(4, 'Vendredi', '14:00', '18:00'),
(5, 'Mercredi', '14:00', '18:00'),
(6, 'Jeudi',    '10:00', '14:00');

-- Matchings
INSERT INTO match_mentorat (id_mentor, id_mentore, score_total, score_competences, score_horaires, score_filiere, score_niveau, matieres_communes, disponibilites_communes, statut) VALUES
(1, 5, 87.50, 40.00, 32.50, 10.00, 5.00, 'Développement Web', 'Lundi 14h-18h', 'propose'),
(1, 2, 92.00, 45.00, 35.00,  7.00, 5.00, 'Développement Web, Python', 'Mardi 15h-17h', 'accepte'),
(3, 4, 78.00, 38.00, 28.00,  7.00, 5.00, 'Bases de données, SQL', 'Mercredi 14h-16h', 'propose');

-- Conversation et messages
INSERT INTO conversation (id_participant1, id_participant2, date_dernier_msg) VALUES
(1, 2, NOW());

INSERT INTO message (id_conversation, id_expediteur, contenu, est_lu) VALUES
(1, 2, 'Bonjour ! J ai vu ton offre de mentorat en Développement Web.', TRUE),
(1, 1, 'Bonjour Marie ! Oui je peux t aider. Quand es-tu disponible ?', TRUE),
(1, 2, 'Je suis libre mardi de 15h à 17h, ca te convient ?', FALSE);

-- Notifications
INSERT INTO notification (id_destinataire, type_notif, contenu, est_lue) VALUES
(1, 'nouveau_match',   'Nouveau match avec Marie Gbaguidi — score : 92%', FALSE),
(2, 'offre_acceptee',  'Ange-Miguel a accepté ton match pour Développement Web !', FALSE),
(1, 'nouveau_message', 'Nouveau message de Marie Gbaguidi', FALSE);

SET FOREIGN_KEY_CHECKS = 1;

-- FIN DU SCRIPT
SELECT 'Base de données IFRI_MentorLink créée avec succès !' AS statut;
