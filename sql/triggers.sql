-- Triggers de Sécurité SnapFit (PL/SQL)
-- À importer pour valider la compétence "Programmation Base de Données"

DELIMITER //

-- 1. Trigger Anti-Scam : Protection Ultime
-- Empêche l'ajout dans la table ARTICLE d'un lien provenant d'un domaine SCAM.
-- Même si le code PHP échoue, la BDD refuse la donnée.

DROP TRIGGER IF EXISTS before_article_insert //

CREATE TRIGGER before_article_insert
BEFORE INSERT ON ARTICLE
FOR EACH ROW
BEGIN
    DECLARE scam_count INT;
    
    -- On vérifie si l'URL contient un domaine marqué 'scam'
    SELECT COUNT(*) INTO scam_count 
    FROM DOMAINE 
    WHERE statut = 'scam' 
    AND NEW.url LIKE CONCAT('%', url_racine, '%');
    
    IF scam_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'SECURITE BDD : Tentative d''insertion d''un article SCAM bloquée.';
    END IF;
END //

-- 2. Trigger Maintenance : Nettoyage Historique
-- Supprime les anciennes recherches d'un utilisateur s'il en a plus de 20
-- (Garde la table légère)

DROP TRIGGER IF EXISTS after_recherche_insert //

CREATE TRIGGER after_recherche_insert
AFTER INSERT ON RECHERCHE
FOR EACH ROW
BEGIN
    DECLARE count_rech INT;
    DECLARE id_to_delete INT;

    SELECT COUNT(*) INTO count_rech FROM RECHERCHE WHERE id_utilisateur = NEW.id_utilisateur;

    IF count_rech > 20 THEN
        SELECT id_recherche INTO id_to_delete 
        FROM RECHERCHE 
        WHERE id_utilisateur = NEW.id_utilisateur 
        ORDER BY date_recherche ASC 
        LIMIT 1;

        DELETE FROM RECHERCHE WHERE id_recherche = id_to_delete;
    END IF;
END //

DELIMITER ;
