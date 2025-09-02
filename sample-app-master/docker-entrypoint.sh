#!/bin/bash
set -e

# Attendre que la base de données soit prête
echo "Waiting for database to be ready..."
while ! php -r "
try {
    \$pdo = new PDO('mysql:host=' . getenv('DB_HOST') . ';port=' . getenv('DB_PORT'), getenv('DB_USERNAME'), getenv('DB_PASSWORD'));
    echo 'Database connection successful' . PHP_EOL;
    exit(0);
} catch (PDOException \$e) {
    exit(1);
}
"; do
    echo "Database not ready, waiting 5 seconds..."
    sleep 5
done

echo "Database is ready!"

# Exécuter les migrations
echo "Running database migrations..."
php artisan migrate --force

# Optionnel: Exécuter les seeders seulement si la variable d'environnement est définie
if [ "$RUN_SEEDERS" = "true" ]; then
    echo "Running database seeders..."
    php artisan db:seed --force
fi

# Démarrer Apache
echo "Starting Apache server..."
exec apache2-foreground
