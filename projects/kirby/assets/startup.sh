#!/bin/bash

## Install Apache, PHP, and other dependencies
add-apt-repository ppa:ondrej/php -y

apt update
apt install apache2 php8.3 php8.3-mbstring php8.3-curl libapache2-mod-php8.3 zip unzip -y

systemctl enable apache2
systemctl start apache2

cat <<EOF > "/etc/apache2/sites-available/kirby.conf"
<VirtualHost *:443>
        ServerName kirby.george.black
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/cloudflare.crt
        SSLCertificateKeyFile /etc/ssl/private/cloudflare.key
        <Directory /var/www/html/>
                Options FollowSymlinks
                AllowOverride All
                Require all granted
        </Directory>
</VirtualHost>
EOF

# Install certs
gcloud storage cp gs://kirby.george.black/certs/cert.pem /etc/ssl/certs/cloudflare.crt
gcloud storage cp gs://kirby.george.black/certs/key.pem /etc/ssl/private/cloudflare.key
chown www-data:www-data /etc/ssl/certs/cloudflare.crt /etc/ssl/private/cloudflare.key

rm /var/www/html/index.html # Remove default index.html
a2enmod rewrite             # Enable mod_rewrite
a2enmod ssl                 # Enable mod_ssl
a2dissite 000-default.conf  # Disable default site
sudo a2ensite kirby.conf    # Enable Kirby site
systemctl reload apache2

# Restore site data from backup
RESTORE=$(gsutil ls "gs://kirby.george.black/backups/*.zip" | sort | tail -n 1)
gcloud storage cp $RESTORE /tmp/restore.zip
unzip /tmp/restore.zip -d /tmp/restore
cp -r /tmp/restore/var/www/html/* /var/www/html
rm -rf /tmp/restore /tmp/restore.zip
chown -R www-data:www-data /var/www/html

# Set up the cron job to backup to GCS
cat <<EOF > "/usr/local/bin/backup.sh"
TIMESTAMP=\$(date +"%Y-%m-%d-%H%M")
zip -r /tmp/$TIMESTAMP.zip /var/www/html
/snap/bin/gcloud storage cp /tmp/$TIMESTAMP.zip gs://kirby.george.black/backups/$TIMESTAMP.zip
rm /tmp/$TIMESTAMP.zip
EOF
chmod +x /usr/local/bin/backup.sh

CRON="0 * * * * /usr/local/bin/backup.sh"
(crontab -l | grep -F "$CRON") || (crontab -l; echo "$CRON") | crontab -
