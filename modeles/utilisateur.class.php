<?php
/**
 * @file    utilisateur.class.php
 * @author  Paul (Team SnapFit)
 * @brief   Définit la classe Utilisateur (Modèle + Logique Métier).
 *          Intègre l'authentification sécurisée (Atelier Auth) et les propriétés SnapFit.
 * @version 1.0
 * @date    15/12/2025
 */

require_once 'bd.class.php';

// Constantes de sécurité (Adaptées de l'atelier)
const MAX_CONNEXIONS_ECHOUEES = 3;
const DELAI_ATTENTE_CONNEXION = 60 * 5; // 5 minutes

class Utilisateur {
    // Propriétés SnapFit existantes
    private ?int $id_utilisateur = null;
    private ?string $nom = null;
    private ?string $prenom = null;
    private ?string $email; // Obligatoire
    private ?string $mot_de_passe_hash; // Obligatoire
    private string $role = 'user';
    private ?string $nom_connexion = null;
    private ?string $date_inscription = null;
    private ?string $sexe = null;
    private ?string $pays = null;

    // Propriétés de Sécurité (Atelier Auth)
    private int $tentativesEchouees = 0;
    private ?string $dateDernierEchecConnexion = null;
    private string $statutCompte = 'actif';
    
    // Constructeur adapté : On garde compatible avec l'ancien code qui injectait tout, 
    // OU le nouveau qui n'utilise que email/pass.
    // Pour "moins modifier possible", on supporte les deux via des paramètres optionnels.
    public function __construct(
        string $email, 
        string $passwordHashOrClear,
        ?string $nom = null,
        ?string $prenom = null,
        ?string $nom_connexion = null
    ) {
        $this->email = $email;
        $this->mot_de_passe_hash = $passwordHashOrClear; // Sera haché si inscription
        $this->nom = $nom;
        $this->prenom = $prenom;
        $this->nom_connexion = $nom_connexion;
    }

    // --- LOGIQUE METIER (ADAPTÉE DE L'ATELIER) ---

    public function emailExiste(): bool {
        $pdo = Bd::getInstance()->getConnexion();
        $req = $pdo->prepare('SELECT COUNT(*) FROM UTILISATEUR WHERE email = :email');
        $req->execute(['email' => $this->email]);
        return $req->fetchColumn() > 0;
    }

    public function estRobuste(string $password): bool {
        // Regex de l'atelier
        $regex = '/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/';
        return preg_match($regex, $password) === 1;
    }

    /**
     * @brief Inscription sécurisée
     */
    public function inscription(string $passwordClair): void {
        if (!$this->estRobuste($passwordClair)) {
            throw new Exception("mdp_faible");
        }
        if ($this->emailExiste()) {
            throw new Exception("compte_existant");
        }

        $pdo = Bd::getInstance()->getConnexion();
        $this->mot_de_passe_hash = password_hash($passwordClair, PASSWORD_BCRYPT);
        
        // On génère un nom de connexion unique si pas fourni
        if (!$this->nom_connexion) {
            $this->nom_connexion = explode('@', $this->email)[0] . uniqid();
        }

        $sql = "INSERT INTO UTILISATEUR (email, mot_de_passe_hash, role, nom_connexion, nom, prenom, sexe, pays, date_inscription) 
                VALUES (:email, :mdp, :role, :login, :nom, :prenom, 'N-A', 'France', NOW())";
        
        $req = $pdo->prepare($sql);
        $req->execute([
            'email' => $this->email,
            'mdp' => $this->mot_de_passe_hash,
            'role' => $this->role,
            'login' => $this->nom_connexion,
            'nom'  => $this->nom ?? 'Anonyme',
            'prenom' => $this->prenom ?? 'User'
        ]);
        
        $this->id_utilisateur = $pdo->lastInsertId();
    }

    /**
     * @brief Authentification sécurisée (Brute force protection)
     */
    public function authentification(string $passwordClair): bool {
        $pdo = Bd::getInstance()->getConnexion();
        
        // Récupération des infos sécurité
        $req = $pdo->prepare(
            'SELECT id_utilisateur, mot_de_passe_hash, tentatives_echouees, date_dernier_echec_connexion, statut_compte, role, nom, prenom, nom_connexion 
             FROM UTILISATEUR WHERE email = :email'
        );
        $req->execute(['email' => $this->email]);
        $user = $req->fetch(PDO::FETCH_ASSOC);

        if (!$user) return false;

        // Hydratation interne
        $this->id_utilisateur = $user['id_utilisateur'];
        $this->mot_de_passe_hash = $user['mot_de_passe_hash']; // Hash stocké
        $this->tentativesEchouees = $user['tentatives_echouees'];
        $this->dateDernierEchecConnexion = $user['date_dernier_echec_connexion'];
        $this->statutCompte = $user['statut_compte'];
        $this->role = $user['role'];
        // Champs extra Snapfit
        $this->nom = $user['nom'];
        $this->prenom = $user['prenom'];
        $this->nom_connexion = $user['nom_connexion'];

        // Vérif Compte Désactivé
        if ($this->statutCompte === 'desactive') {
            if (!$this->delaiAttenteEstEcoule()) {
                throw new Exception("compte_desactive");
            }
            $this->reactiverCompte();
        }

        // Vérif Password
        if (password_verify($passwordClair, $this->mot_de_passe_hash)) {
            if ($this->tentativesEchouees > 0) {
                $this->reinitialiserTentativesConnexions();
            }
            return true;
        } else {
            $this->gererEchecConnexion();
            return false;
        }
    }

    // --- MÉTHODES PRIVÉES SÉCURITÉ (COPIÉ-COLLÉ ADAPTÉ) ---

    private function reinitialiserTentativesConnexions(): void {
        $this->tentativesEchouees = 0;
        $this->dateDernierEchecConnexion = null;
        $pdo = Bd::getInstance()->getConnexion();
        $req = $pdo->prepare('UPDATE UTILISATEUR SET tentatives_echouees = 0, date_dernier_echec_connexion = NULL WHERE id_utilisateur = :id');
        $req->execute(['id' => $this->id_utilisateur]);
    }

    private function gererEchecConnexion(): void {
        $this->tentativesEchouees++;
        $pdo = Bd::getInstance()->getConnexion();
        
        if ($this->tentativesEchouees >= MAX_CONNEXIONS_ECHOUEES) {
            $req = $pdo->prepare(
                'UPDATE UTILISATEUR SET tentatives_echouees = :t, date_dernier_echec_connexion = NOW(), statut_compte = "desactive" WHERE id_utilisateur = :id'
            );
            $this->statutCompte = 'desactive';
        } else {
            $req = $pdo->prepare(
                'UPDATE UTILISATEUR SET tentatives_echouees = :t, date_dernier_echec_connexion = NOW() WHERE id_utilisateur = :id'
            );
        }
        $req->execute(['t' => $this->tentativesEchouees, 'id' => $this->id_utilisateur]);
    }

    private function reactiverCompte(): void {
        $this->tentativesEchouees = 0;
        $this->dateDernierEchecConnexion = null;
        $this->statutCompte = 'actif';
        $pdo = Bd::getInstance()->getConnexion();
        $pdo->prepare('UPDATE UTILISATEUR SET tentatives_echouees = 0, date_dernier_echec_connexion = NULL, statut_compte = "actif" WHERE id_utilisateur = :id')->execute(['id' => $this->id_utilisateur]);
    }

    private function delaiAttenteEstEcoule(): bool {
        return $this->tempsRestantAvantReactivationCompte() === 0;
    }

    public function tempsRestantAvantReactivationCompte(): int {
        if (!$this->dateDernierEchecConnexion) return 0;
        $dernierEchec = strtotime($this->dateDernierEchecConnexion);
        return max(0, DELAI_ATTENTE_CONNEXION - (time() - $dernierEchec));
    }

    // --- GETTERS (POUR SNAPFIT) ---
    public function getId(): ?int { return $this->id_utilisateur; }
    public function getNom(): ?string { return $this->nom; }
    public function getPrenom(): ?string { return $this->prenom; }
    public function getRole(): string { return $this->role; }
    public function getEmail(): string { return $this->email; }
    public function getNomConnexion(): ?string { return $this->nom_connexion; }
}