# Documentation Technique - Base de Données SnapFit (V3)

Ce document explique le fonctionnement et la structure de la base de données relationnelle conçue pour l'application **SnapFit**.

## 1. Vue d'ensemble
L'architecture de la base de données repose sur une séparation claire entre les **Utilisateurs**, les **Contenus** (Articles) et les **Interactions** (Recherches, Favoris). Elle intègre également un module de sécurité via la gestion des **Domaines** (Anti-Scam).

## 2. Description des Entités (Tables)

### A. UTILISATEUR (`UTILISATEUR`)
Cette table centrale stocke les informations des inscrits.
- **Rôle** : Sécurisation de l'accès et profil.
- **Particularités** :
    - `mot_de_passe_hash` : Stockage sécurisé (jamais en clair).
    - `statut_compte` / `tentatives_echouees` : Mécanisme de sécurité pour bloquer les attaques par force brute.
    - `token_reinitialisation` : Permet la récupération de mot de passe hors connexion.

### B. ARTICLE (`ARTICLE`)
Représente un produit identifié sur le web (vêtement, accessoire).
- **Rôle** : Source de vérité unique pour un objet.
- **Logique** : Contrairement à une approche naïve où chaque favori copierait les infos, ici un article est stocké **une seule fois** (identifié par son URL).
- **Attributs clés** : Image, Titre, Marque (récupérés via Google Lens/SerpAPI).

### C. RECHERCHE (`RECHERCHE`)
Historique des scans effectués par les utilisateurs.
- **Rôle** : Traçabilité et fonctionnalité "Mon Historique".
- **Lien** : Relié à `UTILISATEUR` (1 utilisateur -> N recherches).
- **Contenu** : Stocke l'image scannée (`image_scan`) et la date.

### D. DOMAINE (`DOMAINE`)
Table de référence pour le filtrage Anti-Scam et Eco-Score.
- **Rôle** :Sécurité et Éthique.
- **Fonctionnement** : Chaque résultat de recherche est comparé à cette liste.
    - Si statut = `scam` (ex: Shein, Temu) -> Le résultat est masqué ou alerté.
    - Si statut = `eco` (ex: Patagonia, Vinted) -> Le résultat est mis en avant.

---

## 3. Les Relations Clés

### La Relation "Favori" (Table `FAVORI`)
C'est une relation **Plusieurs-à-Plusieurs** entre `UTILISATEUR` et `ARTICLE`.
- **Pourquoi une table dédiée ?**
  Un utilisateur peut aimer plusieurs articles, et un article peut être aimé par plusieurs utilisateurs.
- **Structure** : Elle ne contient que les ID (`id_utilisateur`, `id_article`) et la date d'ajout. C'est un lien léger et performant.
- **Avantage** : Si on met à jour l'image d'un article dans la table `ARTICLE`, tous les utilisateurs qui l'ont en favori voient la mise à jour instantanément.

### La Relation "Effectuer" (Table `RECHERCHE`)
C'est une relation **Un-à-Plusieurs**.
- Un utilisateur peut avoir plusieurs recherches.
- Une recherche appartient à un seul utilisateur.
- **Cycle de vie** : Si un utilisateur supprime son compte (`ON DELETE CASCADE`), son historique est automatiquement effacé pour respecter la confidentialité (RGPD).

## 4. Schéma Relationnel Simplifié

```text
[UTILISATEUR] 1 ---- 0..N [RECHERCHE]
      1
      |
    0..N
  [FAVORI] (Table de liaison)
    0..N
      |
      1
  [ARTICLE]
```
