<?php

use Symfony\Component\Yaml\Yaml;

// 1. Chemin vers le fichier config.yaml
$configFile = __DIR__ . '/../config.yaml';
$localConfigFile = __DIR__ . '/../config_local.yaml';

// 2. Vérification de sécurité (Priorité au fichier local)
if (file_exists($localConfigFile)) {
    $configFile = $localConfigFile;
} elseif (!file_exists($configFile)) {
    die("<h1>Erreur de configuration</h1><p>Le fichier <code>config.yaml</code> est introuvable. Veuillez le créer à la racine du projet en copiant <code>config.example.yaml</code>.</p>");
}

// 3. Lecture du fichier YAML
try {
    $config = Yaml::parseFile($configFile);
} catch (Exception $e) {
    die("<h1>Erreur YAML</h1><p>Impossible de lire le fichier de configuration : " . $e->getMessage() . "</p>");
}

// 4. Définition des constantes
define('DB_HOST', $config['bdd']['host'] ?? 'localhost');
define('DB_NAME', $config['bdd']['nom'] ?? 'aecheverria_pro');
define('DB_USER', $config['bdd']['user'] ?? 'aecheverria_pro');
define('DB_PASS', $config['bdd']['password'] ?? 'aecheverria_pro');
define('', '');

?>
