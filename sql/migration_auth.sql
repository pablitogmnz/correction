-- Mise à jour de la table UTILISATEUR pour supporter l'authentification sécurisée
-- Ajout des champs pour la gestion des tentatives et du verrouillage

ALTER TABLE UTILISATEUR
ADD COLUMN tentatives_echouees INT DEFAULT 0 NOT NULL,
ADD COLUMN date_dernier_echec_connexion DATETIME DEFAULT NULL,
ADD COLUMN statut_compte ENUM('actif', 'desactive') DEFAULT 'actif',
ADD COLUMN token_reinitialisation VARCHAR(255) DEFAULT NULL,
ADD COLUMN expiration_token DATETIME DEFAULT NULL;
