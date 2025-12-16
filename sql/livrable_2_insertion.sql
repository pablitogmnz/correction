-- SCRIPT D'INSERTION (Livrable 2)
-- Jeu de données initial

-- 1. Utilisateurs (Mots de passe hashés : "password")
INSERT INTO UTILISATEUR (nom, prenom, email, mot_de_passe_hash, nom_connexion, role, statut_compte) VALUES
('Admin', 'Super', 'admin@snapfit.com', '$2y$10$8K1p/a0d3.0.0.0.0.0.0.0.0.0.0.0', 'admin', 'admin', 'actif'),
('Dupont', 'Jean', 'jean.dupont@email.com', '$2y$10$8K1p/a0d3.0.0.0.0.0.0.0.0.0.0.0', 'jeannot', 'user', 'actif'),
('Martin', 'Sophie', 'sophie.martin@email.com', '$2y$10$8K1p/a0d3.0.0.0.0.0.0.0.0.0.0.0', 'sophieM', 'user', 'actif');

-- 2. Domaines (Anti-Scam et Eco-Score)
INSERT INTO DOMAINE (url_racine, nom, statut, description) VALUES
('shein.com', 'Shein', 'scam', 'Fast fashion basse qualité, problèmes éthiques.'),
('temu.com', 'Temu', 'scam', 'Plateforme low-cost à risque.'),
('aliexpress.com', 'AliExpress', 'scam', 'Dropshipping massif, qualité aléatoire.'),
('patagonia.com', 'Patagonia', 'eco', 'Marque engagée pour l''environnement.'),
('vinted.fr', 'Vinted', 'eco', 'Seconde main, favorise l''économie circulaire.'),
('nike.com', 'Nike', 'neutre', 'Grande marque sportswear standard.');

-- 3. Articles (Exemples de scans sauvegardés)
INSERT INTO ARTICLE (url, image, categorie, marque, api_ref_id) VALUES
('https://www.nike.com/fr/t/pantalon-cargo', 'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/e6e7e5e3/cargo.jpg', 'Pantalon Cargo', 'Nike', 'nike_cargo_001'),
('https://www.patagonia.com/product/jacket', 'https://www.patagonia.com/images/jacket.jpg', 'Veste Pluie', 'Patagonia', 'pata_rain_002');

-- 4. Recherche (Historique simulé pour Jean)
INSERT INTO RECHERCHE (id_utilisateur, image_scan, api_id, date_recherche) VALUES
(2, 'scan_jean_001.jpg', 'search_abc123', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(2, 'scan_jean_002.jpg', 'search_def456', DATE_SUB(NOW(), INTERVAL 1 HOUR));

-- 5. Favoris
-- Jean aime le pantalon Nike (ID 1)
INSERT INTO FAVORI (id_utilisateur, id_article, date_ajout) VALUES
(2, 1, NOW());

-- Sophie aime la veste Patagonia (ID 2)
INSERT INTO FAVORI (id_utilisateur, id_article, date_ajout) VALUES
(3, 2, NOW());
