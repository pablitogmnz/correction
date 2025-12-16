-- SCRIPT DE CREATION (Livrable 1)
-- Projet SnapFit - Base de données relationnelle

-- 1. Nettoyage préalable
DROP TABLE IF EXISTS FAVORI;
DROP TABLE IF EXISTS RECHERCHE;
DROP TABLE IF EXISTS ARTICLE;
DROP TABLE IF EXISTS DOMAINE;
DROP TABLE IF EXISTS UTILISATEUR;

-- 2. Création des tables

CREATE TABLE UTILISATEUR (
    id_utilisateur INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(50),
    prenom VARCHAR(50),
    email VARCHAR(100) UNIQUE NOT NULL,
    mot_de_passe_hash VARCHAR(255) NOT NULL,
    nom_connexion VARCHAR(50) UNIQUE NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    statut_compte ENUM('actif', 'desactive') DEFAULT 'actif',
    tentatives_echouees INT DEFAULT 0 NOT NULL,
    date_dernier_echec_connexion DATETIME DEFAULT NULL,
    token_reinitialisation VARCHAR(255) DEFAULT NULL,
    expiration_token DATETIME DEFAULT NULL,
    date_inscription DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE DOMAINE (
    id_domaine INT AUTO_INCREMENT PRIMARY KEY,
    url_racine VARCHAR(255) UNIQUE NOT NULL,
    nom VARCHAR(100),
    statut ENUM('eco', 'scam', 'neutre') DEFAULT 'neutre',
    description TEXT
) ENGINE=InnoDB;

CREATE TABLE ARTICLE (
    id_article INT AUTO_INCREMENT PRIMARY KEY,
    url VARCHAR(500) NOT NULL,
    image VARCHAR(500),
    categorie VARCHAR(100),
    marque VARCHAR(100),
    api_ref_id VARCHAR(100) UNIQUE,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE RECHERCHE (
    id_recherche INT AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur INT NOT NULL,
    image_scan VARCHAR(255) NOT NULL,
    api_id VARCHAR(100),
    date_recherche DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rech_user FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id_utilisateur) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE FAVORI (
    id_utilisateur INT NOT NULL,
    id_article INT NOT NULL,
    date_ajout DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_utilisateur, id_article),
    CONSTRAINT fk_fav_user FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id_utilisateur) ON DELETE CASCADE,
    CONSTRAINT fk_fav_article FOREIGN KEY (id_article) REFERENCES ARTICLE(id_article) ON DELETE CASCADE
) ENGINE=InnoDB;
