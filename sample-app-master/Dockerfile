# Utilisez une image Docker officielle pour PHP 8.2 avec Apache
FROM php:8.2.8-apache

# Installez les dépendances système et SSH
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    p7zip-full \
    openssh-server \
    dialog \
    && rm -rf /var/lib/apt/lists/*

# Installez les extensions PHP nécessaires
RUN docker-php-ext-install pdo_mysql

# Installez Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copiez les fichiers de l'application dans le conteneur
COPY . /var/www/html/

# Installez les dépendances de l'application
RUN composer install --no-dev --optimize-autoloader

# Configuration des permissions
RUN chown -R www-data:www-data /var/www/html/vendor /var/www/html/storage /var/www/html/bootstrap /var/www/html/public /var/www/html/app /var/www/html/config /var/www/html/routes /var/www/html/resources
RUN chmod -R 755 /var/www/html/vendor /var/www/html/storage /var/www/html/bootstrap /var/www/html/public /var/www/html/app /var/www/html/config /var/www/html/routes /var/www/html/resources

# Configuration d'Apache pour pointer vers le répertoire public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Activez le module Apache Rewrite
RUN a2enmod rewrite

# Configuration SSH pour Azure App Service
COPY sshd_config /etc/ssh/
RUN mkdir -p /var/run/sshd \
    && echo "root:Docker!" | chpasswd \
    && chmod +x /var/www/html/init.sh

# Exposez les ports
EXPOSE 80 2222

# Script de démarrage
CMD ["/var/www/html/init.sh"]