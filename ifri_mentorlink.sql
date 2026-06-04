#  IFRI_MentorLink — Base de données MySQL
#  Projet intégrateur PIL1 2025-2026
#  Université d'Abomey-Calavi / IFRI
#
#  Groupe 28 — PIL1_2526_28
#
#  Membres de l'équipe :
#  1. IDJINOU Ikpéé Orè Christobelle     (IA)    — 63854470
#  2. KOUDJENOUME Jean-Pierre             (IM)    — 69109922
#  3. DIALLO Sonnabella Hilary            (GL)    — 44989955
#  4. AKPANON Ange-Miguel Osbel           (SEIoT) — 65166502
#  5. APOVO Pascal Glory Delphin          (SI)    — 93628911
#  6. NIKOUE Amoni Lazare Gilles Christ   (SI)    — 54813363
#  7. ISSA CHABI OLATOUNDJI RILWANE       (GL)    — 59651432
#
#  Supervision    : M. Ratheil HOUNDJI
#  Encadrant 1    : M. Armand ACCROMBESSI
#  Encadrant 2    : Mme Maryse GAHOU
#
#  Date de création : 04 juin 2026
#  SGBD cible       : MySQL 8.0+  |  Moteur : InnoDB
#  Encodage         : utf8mb4_unicode_ci


SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS ifri_mentorlink;
CREATE DATABASE ifri_mentorlink
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE ifri_mentorlink;


# TABLE : filieres
# Référentiel des filières disponibles à l'IFRI
# (IA, IM, GL, SE_IoT, SI)

CREATE TABLE filieres (
    id_filiere  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code        VARCHAR(20)  NOT NULL UNIQUE COMMENT 'Ex: IA, IM, GL, SE_IoT, SI',
    libelle     VARCHAR(100) NOT NULL,
    description TEXT
) ENGINE=InnoDB;

INSERT INTO filieres (code, libelle) VALUES
    ('IA',     'Intelligence Artificielle'),
    ('IM',     'Ingénierie Multimédia'),
    ('GL',     'Génie Logiciel'),
    ('SE_IoT', 'Systèmes Embarqués & IoT'),
    ('SI',     'Systèmes d''Information');


# TABLE : matieres
# Catalogue des matières et compétences enseignées à l'IFRI
# Utilisée pour le matching mentor-mentoré

CREATE TABLE matieres (
    id_matiere  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom         VARCHAR(150) NOT NULL,
    categorie   VARCHAR(80)  COMMENT 'Ex: Algorithmique, Web, BD, Python',
    description TEXT
) ENGINE=InnoDB;


# TABLE : utilisateurs
# Comptes et profils de tous les utilisateurs de la plateforme
# Un utilisateur peut être mentor, mentoré ou les deux

CREATE TABLE utilisateurs (
    id_utilisateur   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom              VARCHAR(80)  NOT NULL,
    prenom           VARCHAR(80)  NOT NULL,
    email            VARCHAR(180) NOT NULL UNIQUE,
    telephone        VARCHAR(20)  NOT NULL UNIQUE,
    mot_de_passe     VARCHAR(255) NOT NULL COMMENT 'Hashé avec bcrypt',
    photo_profil     VARCHAR(300) DEFAULT NULL COMMENT 'Chemin ou URL de l\'image',
    bio              TEXT         DEFAULT NULL,
    id_filiere       INT UNSIGNED NOT NULL,
    niveau_etudes    ENUM('L1','L2','L3','M1','M2') NOT NULL DEFAULT 'L1',
    date_inscription DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    est_actif        TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT fk_util_filiere FOREIGN KEY (id_filiere)
        REFERENCES filieres(id_filiere) ON UPDATE CASCADE
) ENGINE=InnoDB;


# TABLE : competences_utilisateur
# Points forts d'un utilisateur — matières qu'il maîtrise
# Utilisée par l'algorithme de matching côté mentor

CREATE TABLE competences_utilisateur (
    id_competence   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur  INT UNSIGNED NOT NULL,
    id_matiere      INT UNSIGNED NOT NULL,
    niveau_maitrise TINYINT UNSIGNED NOT NULL DEFAULT 3
        COMMENT '1 = débutant, 2 = intermédiaire, 3 = avancé, 4 = confirmé, 5 = expert',
    UNIQUE KEY uq_comp_util_mat (id_utilisateur, id_matiere),
    CONSTRAINT fk_comp_util FOREIGN KEY (id_utilisateur)
        REFERENCES utilisateurs(id_utilisateur) ON DELETE CASCADE,
    CONSTRAINT fk_comp_mat  FOREIGN KEY (id_matiere)
        REFERENCES matieres(id_matiere) ON UPDATE CASCADE
) ENGINE=InnoDB;


# TABLE : lacunes_utilisateur
# Points faibles d'un utilisateur — matières où il a besoin d'aide
# Utilisée par l'algorithme de matching côté mentoré

CREATE TABLE lacunes_utilisateur (
    id_lacune       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur  INT UNSIGNED NOT NULL,
    id_matiere      INT UNSIGNED NOT NULL,
    priorite        TINYINT UNSIGNED NOT NULL DEFAULT 2
        COMMENT '1 = faible, 2 = moyenne, 3 = élevée',
    date_creation   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_resolution DATETIME DEFAULT NULL,
    UNIQUE KEY uq_lacune_util_mat (id_utilisateur, id_matiere),
    CONSTRAINT fk_lac_util FOREIGN KEY (id_utilisateur)
        REFERENCES utilisateurs(id_utilisateur) ON DELETE CASCADE,
    CONSTRAINT fk_lac_mat  FOREIGN KEY (id_matiere)
        REFERENCES matieres(id_matiere) ON UPDATE CASCADE
) ENGINE=InnoDB;


# TABLE : disponibilites
# Créneaux horaires habituels d'un utilisateur dans son profil
# Stockage structuré (pas de texte libre) pour permettre
# la comparaison algorithmique des créneaux

CREATE TABLE disponibilites (
    id_disponibilite INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur   INT UNSIGNED NOT NULL,
    jour_semaine     ENUM('Lundi','Mardi','Mercredi','Jeudi',
                          'Vendredi','Samedi','Dimanche') NOT NULL,
    heure_debut      TIME NOT NULL,
    heure_fin        TIME NOT NULL,
    CONSTRAINT fk_dispo_util FOREIGN KEY (id_utilisateur)
        REFERENCES utilisateurs(id_utilisateur) ON DELETE CASCADE,
    CONSTRAINT chk_horaire CHECK (heure_fin > heure_debut)
) ENGINE=InnoDB;


# TABLE : tokens_reinitialisation
# Tokens temporaires à usage unique pour la réinitialisation
# de mot de passe — envoyés par email, expiration courte

CREATE TABLE tokens_reinitialisation (
    id_token        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur  INT UNSIGNED NOT NULL,
    token           VARCHAR(255) NOT NULL UNIQUE,
    date_expiration DATETIME     NOT NULL,
    utilise         TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT fk_token_util FOREIGN KEY (id_utilisateur)
        REFERENCES utilisateurs(id_utilisateur) ON DELETE CASCADE
) ENGINE=InnoDB;


# TABLE : offres_mentorat
# Publications des utilisateurs : offres ("je peux aider")
# ou demandes ("j'ai besoin d'aide") de mentorat

CREATE TABLE offres_mentorat (
    id_offre          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_auteur         INT UNSIGNED NOT NULL,
    type_offre        ENUM('offre','demande') NOT NULL
        COMMENT 'offre = je peux aider | demande = j\'ai besoin d\'aide',
    format_session    ENUM('presentiel','en_ligne','les_deux') NOT NULL DEFAULT 'les_deux',
    description       TEXT,
    statut            ENUM('active','pourvue','annulee') NOT NULL DEFAULT 'active',
    date_creation     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_offre_auteur FOREIGN KEY (id_auteur)
        REFERENCES utilisateurs(id_utilisateur) ON DELETE CASCADE
) ENGINE=InnoDB;


# TABLE : offres_matieres
# Association N,N entre offres_mentorat et matieres
# Une offre peut cibler plusieurs matières

CREATE TABLE offres_matieres (
    id_offre_matiere INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_offre         INT UNSIGNED NOT NULL,
    id_matiere       INT UNSIGNED NOT NULL,
    UNIQUE KEY uq_offre_mat (id_offre, id_matiere),
    CONSTRAINT fk_ofmat_offre FOREIGN KEY (id_offre)
        REFERENCES offres_mentorat(id_offre) ON DELETE CASCADE,
    CONSTRAINT fk_ofmat_mat   FOREIGN KEY (id_matiere)
        REFERENCES matieres(id_matiere) ON UPDATE CASCADE
) ENGINE=InnoDB;


# TABLE : offres_disponibilites
# Créneaux horaires proposés spécifiquement pour une offre
# Stockage structuré identique à la table disponibilites

CREATE TABLE offres_disponibilites (
    id_offre_dispo INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_offre       INT UNSIGNED NOT NULL,
    jour_semaine   ENUM('Lundi','Mardi','Mercredi','Jeudi',
                        'Vendredi','Samedi','Dimanche') NOT NULL,
    heure_debut    TIME NOT NULL,
    heure_fin      TIME NOT NULL,
    CONSTRAINT fk_ofdispo_offre FOREIGN KEY (id_offre)
        REFERENCES offres_mentorat(id_offre) ON DELETE CASCADE,
    CONSTRAINT chk_ofdispo CHECK (heure_fin > heure_debut)
) ENGINE=InnoDB;


# TABLE : matchings
# Résultats de l'algorithme de mise en correspondance
# Scores décomposés : compétences, horaires, filière
# Statut suivi dans le temps : proposé → accepté → terminé

CREATE TABLE matchings (
    id_matching       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_mentor         INT UNSIGNED NOT NULL,
    id_mentore        INT UNSIGNED NOT NULL,
    score_total       DECIMAL(5,2) NOT NULL DEFAULT 0.00
        COMMENT 'Score de compatibilité global sur 100',
    score_competences DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    score_horaires    DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    score_filiere     DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    statut            ENUM('propose','accepte','refuse','termine')
                      NOT NULL DEFAULT 'propose',
    date_creation     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_matching_pair (id_mentor, id_mentore),
    CONSTRAINT fk_match_mentor  FOREIGN KEY (id_mentor)
        REFERENCES utilisateurs(id_utilisateur),
    CONSTRAINT fk_match_mentore FOREIGN KEY (id_mentore)
        REFERENCES utilisateurs(id_utilisateur),
    CONSTRAINT chk_match_diff   CHECK (id_mentor <> id_mentore)
) ENGINE=InnoDB;


# TABLE : reponses_offres
# Candidatures d'un utilisateur en réponse à une offre/demande
# Statut suivi : en attente → acceptée ou refusée

CREATE TABLE reponses_offres (
    id_reponse   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_offre     INT UNSIGNED NOT NULL,
    id_repondant INT UNSIGNED NOT NULL,
    message      TEXT,
    statut       ENUM('en_attente','acceptee','refusee')
                 NOT NULL DEFAULT 'en_attente',
    date_reponse DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_reponse_offre_util (id_offre, id_repondant),
    CONSTRAINT fk_rep_offre FOREIGN KEY (id_offre)
        REFERENCES offres_mentorat(id_offre) ON DELETE CASCADE,
    CONSTRAINT fk_rep_util  FOREIGN KEY (id_repondant)
        REFERENCES utilisateurs(id_utilisateur)
) ENGINE=InnoDB;


# TABLE : conversations
# Fils de messagerie privés entre exactement deux utilisateurs
# La paire (participant1, participant2) est unique

CREATE TABLE conversations (
    id_conversation INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_participant1 INT UNSIGNED NOT NULL,
    id_participant2 INT UNSIGNED NOT NULL,
    date_creation   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_conversation (id_participant1, id_participant2),
    CONSTRAINT fk_conv_p1   FOREIGN KEY (id_participant1)
        REFERENCES utilisateurs(id_utilisateur),
    CONSTRAINT fk_conv_p2   FOREIGN KEY (id_participant2)
        REFERENCES utilisateurs(id_utilisateur),
    CONSTRAINT chk_conv_diff CHECK (id_participant1 <> id_participant2)
) ENGINE=InnoDB;


# TABLE : messages
# Messages textuels échangés dans une conversation
# Suivi de l'état de lecture pour les notifications

CREATE TABLE messages (
    id_message      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_conversation INT UNSIGNED NOT NULL,
    id_expediteur   INT UNSIGNED NOT NULL,
    contenu         TEXT     NOT NULL,
    date_envoi      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    est_lu          TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_msg_conv  FOREIGN KEY (id_conversation)
        REFERENCES conversations(id_conversation) ON DELETE CASCADE,
    CONSTRAINT fk_msg_exped FOREIGN KEY (id_expediteur)
        REFERENCES utilisateurs(id_utilisateur)
) ENGINE=InnoDB;


# TABLE : notifications
# Alertes en temps réel générées automatiquement
# Types : nouveau message, matching, réponse offre, etc.

CREATE TABLE notifications (
    id_notification INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_destinataire INT UNSIGNED NOT NULL,
    type_notif      ENUM('nouveau_message','nouveau_matching',
                         'reponse_offre','offre_acceptee',
                         'offre_refusee') NOT NULL,
    contenu         VARCHAR(300) NOT NULL,
    lien            VARCHAR(300) DEFAULT NULL COMMENT 'URL de redirection',
    est_lue         TINYINT(1)   NOT NULL DEFAULT 0,
    date_creation   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_dest FOREIGN KEY (id_destinataire)
        REFERENCES utilisateurs(id_utilisateur) ON DELETE CASCADE
) ENGINE=InnoDB;


# INDEX — Optimisation des performances des requêtes fréquentes

CREATE INDEX idx_util_email     ON utilisateurs(email);
CREATE INDEX idx_util_telephone ON utilisateurs(telephone);
CREATE INDEX idx_offre_statut   ON offres_mentorat(statut);
CREATE INDEX idx_offre_type     ON offres_mentorat(type_offre);
CREATE INDEX idx_msg_conv       ON messages(id_conversation, date_envoi);
CREATE INDEX idx_notif_dest_lue ON notifications(id_destinataire, est_lue);
CREATE INDEX idx_matching_score ON matchings(score_total DESC);


# VUE : vue_matchings_details
# Matchings enrichis avec les informations complètes des deux
# utilisateurs (nom, photo, filière, niveau) — prête pour
# l'affichage frontend des résultats de matching

CREATE OR REPLACE VIEW vue_matchings_details AS
SELECT
    m.id_matching,
    m.score_total,
    m.score_competences,
    m.score_horaires,
    m.score_filiere,
    m.statut,
    m.date_creation,
    # Mentor
    u1.id_utilisateur AS id_mentor,
    u1.nom            AS mentor_nom,
    u1.prenom         AS mentor_prenom,
    u1.photo_profil   AS mentor_photo,
    f1.code           AS mentor_filiere,
    u1.niveau_etudes  AS mentor_niveau,
    # Mentoré
    u2.id_utilisateur AS id_mentore,
    u2.nom            AS mentore_nom,
    u2.prenom         AS mentore_prenom,
    u2.photo_profil   AS mentore_photo,
    f2.code           AS mentore_filiere,
    u2.niveau_etudes  AS mentore_niveau
FROM matchings m
JOIN utilisateurs u1 ON m.id_mentor  = u1.id_utilisateur
JOIN utilisateurs u2 ON m.id_mentore = u2.id_utilisateur
JOIN filieres     f1 ON u1.id_filiere = f1.id_filiere
JOIN filieres     f2 ON u2.id_filiere = f2.id_filiere;


# VUE : vue_profil_complet
# Profil utilisateur complet avec filière et comptage
# des compétences et lacunes enregistrées

CREATE OR REPLACE VIEW vue_profil_complet AS
SELECT
    u.id_utilisateur,
    u.nom,
    u.prenom,
    u.email,
    u.telephone,
    u.photo_profil,
    u.bio,
    f.code            AS filiere_code,
    f.libelle         AS filiere_libelle,
    u.niveau_etudes,
    u.date_inscription,
    u.est_actif,
    COUNT(DISTINCT cu.id_competence) AS nb_competences,
    COUNT(DISTINCT lu.id_lacune)     AS nb_lacunes
FROM utilisateurs u
JOIN filieres f ON u.id_filiere = f.id_filiere
LEFT JOIN competences_utilisateur cu ON u.id_utilisateur = cu.id_utilisateur
LEFT JOIN lacunes_utilisateur     lu ON u.id_utilisateur = lu.id_utilisateur
GROUP BY u.id_utilisateur;


SET FOREIGN_KEY_CHECKS = 1;


# Fin du script — ifri_mentorlink.sql
# Groupe 28 — PIL1_2526_28 — IFRI-UAC — 2025-2026
