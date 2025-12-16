-- Structure complète V2 SnapFit
-- Basée sur le schéma relationnel fourni
-- Inclut : UTILISATEUR, FAVORI, RECHERCHE, AJOUTER, SITE_ECO, SITE_SCAM
-- + Trigger de sécurité "Anti-Scam"

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Table UTILISATEUR
DROP TABLE IF EXISTS UTILISATEUR;
CREATE TABLE UTILISATEUR (
    id_utilisateur INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(50),
    prenom VARCHAR(50),
    mot_de_passe_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user', -- 'user' ou 'admin'
    date_inscription DATETIME DEFAULT CURRENT_TIMESTAMP,
    email VARCHAR(100) UNIQUE NOT NULL,
    nom_connexion VARCHAR(50) UNIQUE NOT NULL,
    sexe VARCHAR(20),
    pays VARCHAR(50)
) ENGINE=InnoDB;

-- 2. Table SITE_SCAM (Pour détecter les arnaques)
DROP TABLE IF EXISTS SITE_SCAM;
CREATE TABLE SITE_SCAM (
    id_site_scam INT AUTO_INCREMENT PRIMARY KEY,
    url_site_scam VARCHAR(255) NOT NULL,
    nom VARCHAR(100)
) ENGINE=InnoDB;

-- 3. Table SITE_ECO (Pour mettre en avant l'éco-responsabilité)
DROP TABLE IF EXISTS SITE_ECO;
CREATE TABLE SITE_ECO (
    id_site_eco INT AUTO_INCREMENT PRIMARY KEY,
    url_site_eco VARCHAR(255) NOT NULL,
    nom VARCHAR(100)
) ENGINE=InnoDB;

-- 4. Table FAVORI (L'article en lui-même)
DROP TABLE IF EXISTS FAVORI;
CREATE TABLE FAVORI (
    id_favori INT AUTO_INCREMENT PRIMARY KEY,
    url VARCHAR(500) NOT NULL,
    image VARCHAR(500),
    categorie VARCHAR(100),
    marque VARCHAR(100),
    api_ref_id VARCHAR(100), -- ID unique venant de l'API SerpApi
    date_fav DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 5. Table AJOUTER (Liaison User <-> Favori)
DROP TABLE IF EXISTS AJOUTER;
CREATE TABLE AJOUTER (
    id_utilisateur INT,
    id_favori INT,
    PRIMARY KEY (id_utilisateur, id_favori),
    CONSTRAINT fk_ajouter_user FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id_utilisateur) ON DELETE CASCADE,
    CONSTRAINT fk_ajouter_fav FOREIGN KEY (id_favori) REFERENCES FAVORI(id_favori) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. Table RECHERCHE (Historique des scans)
DROP TABLE IF EXISTS RECHERCHE;
CREATE TABLE RECHERCHE (
    id_recherche INT AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur INT,
    image VARCHAR(255) NOT NULL, -- Chemin de l'image scannée
    date_recherche DATETIME DEFAULT CURRENT_TIMESTAMP,
    api_id VARCHAR(100), -- ID de recherche API
    CONSTRAINT fk_recherche_user FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id_utilisateur) ON DELETE CASCADE
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================
-- TRIGGERS PL/SQL
-- =============================================

DELIMITER //

-- Trigger 1 : Prévention Anti-Scam
-- Avant d'ajouter un favori, on vérifie si son URL est dans la liste noire (SITE_SCAM).
-- Si oui, on bloque l'insertion avec une erreur.

CREATE TRIGGER before_favori_insert
BEFORE INSERT ON FAVORI
FOR EACH ROW
BEGIN
    DECLARE scam_count INT;
    
    -- On compte si le domaine de l'URL existe dans SITE_SCAM
    -- Note : C'est une vérification simplifiée avec LIKE
    SELECT COUNT(*) INTO scam_count 
    FROM SITE_SCAM 
    WHERE NEW.url LIKE CONCAT('%', url_site_scam, '%');
    
    IF scam_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Sécurité SnapFit : Impossible d''ajouter ce favori car le site est identifié comme une arnaque (Scam).';
    END IF;
END //

-- Trigger 2 : Archivage automatique (Optionnel)
-- A chaque nouvelle recherche, si l'user a plus de 10 recherches, on supprime la plus vieille.
-- (Pour garder l'historique propre).

CREATE TRIGGER after_recherche_insert
AFTER INSERT ON RECHERCHE
FOR EACH ROW
BEGIN
    DECLARE user_recherche_count INT;
    DECLARE oldest_id INT;
    
    SELECT COUNT(*) INTO user_recherche_count FROM RECHERCHE WHERE id_utilisateur = NEW.id_utilisateur;
    
    IF user_recherche_count > 10 THEN
        SELECT id_recherche INTO oldest_id 
        FROM RECHERCHE 
        WHERE id_utilisateur = NEW.id_utilisateur 
        ORDER BY date_recherche ASC LIMIT 1;
        
        DELETE FROM RECHERCHE WHERE id_recherche = oldest_id;
    END IF;
END //

DELIMITER ;

-- Données de test initiales

INSERT INTO SITE_SCAM (url_site_scam, nom) VALUES 
('arnaque-mode.com', 'Faux Site Mode'),
('fast-fashion-scam.net', 'Scam Fashion');

INSERT INTO SITE_ECO (url_site_eco, nom) VALUES 
('patagonia.com', 'Patagonia'),
('veja-store.com', 'Veja');

-- Création d'un User Admin par défaut (mdp: 'admin')
INSERT INTO UTILISATEUR (nom, prenom, mot_de_passe_hash, role, email, nom_connexion, sexe, pays) VALUES
('Admin', 'Super', '$2y$10$8K1p/a0d3.0.0.0.0.0.0.0.0.0.0.0', 'admin', 'admin@snapfit.com', 'admin', 'H', 'France');
