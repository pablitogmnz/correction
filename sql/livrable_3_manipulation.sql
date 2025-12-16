-- SCRIPT DE MANIPULATION (Livrable 3)
-- Exemples de requêtes (CRUD, Jointures, Agrégats)

-- 1. LECTURE SIMPLE (SELECT)
-- Récupérer tous les produits de marque 'Nike'
SELECT * FROM ARTICLE WHERE marque = 'Nike';


-- 2. JOINTURE (INNER JOIN)
-- Lister les favoris de l'utilisateur 'Jean Dupont' (via son email ou ID)
SELECT U.nom, U.prenom, A.categorie, A.url, F.date_ajout
FROM UTILISATEUR U
JOIN FAVORI F ON U.id_utilisateur = F.id_utilisateur
JOIN ARTICLE A ON F.id_article = A.id_article
WHERE U.email = 'jean.dupont@email.com';


-- 3. AGREGATION (GROUP BY + COUNT)
-- Compter combien de fois chaque domaine 'scam' a été détecté ou listé
SELECT nom, COUNT(*) AS nombre_de_sites
FROM DOMAINE
WHERE statut = 'scam'
GROUP BY nom;

-- Compter le nombre de favoris par marque
SELECT marque, COUNT(id_article) as nb_favoris
FROM ARTICLE 
JOIN FAVORI ON ARTICLE.id_article = FAVORI.id_article
GROUP BY marque
ORDER BY nb_favoris DESC;


-- 4. MISE A JOUR (UPDATE)
-- Bloquer le compte de 'sophie.martin' après 3 tentatives échouées
UPDATE UTILISATEUR 
SET statut_compte = 'desactive', 
    tentatives_echouees = 3, 
    date_dernier_echec_connexion = NOW()
WHERE email = 'sophie.martin@email.com';


-- 5. SUPPRESSION (DELETE)
-- Supprimer l'historique de recherche vieux de plus de 30 jours
DELETE FROM RECHERCHE 
WHERE date_recherche < DATE_SUB(NOW(), INTERVAL 30 DAY);


-- 6. REQUETE COMPLEXE (Anti-Scam Check)
-- Vérifier si une URL donnée appartient à un domaine Scam
SELECT statut 
FROM DOMAINE 
WHERE 'https://fr.shein.com/robe-ete.html' LIKE CONCAT('%', url_racine, '%');
