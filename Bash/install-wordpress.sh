#!/bin/bash
# Wordpressin asennus. **VAATII** että on webserveri ja mysql ym vaadittavat asennettuna :D
# Toki, varmaan jossai kohi lisään ne tähä, ny ei ollu tarvetta
# Helpotan vaan omaa elämääni tällä
# curl -o- https://raw.githubusercontent.com/Onsqa/Scripts/main/install-wordpress.sh.sh | bash
if [[ $EUID -ne 0 ]]; then
    echo "Tämä skripti vaatii root oikeudet"
    exit 1
fi

WP_URL="https://wordpress.org/latest.tar.gz"
read -ep "Asennuspolku johon asennetaan wordpress: " WP_DIR
read -p "Tietokannan nimi: " DB_NAME
read -p "Käyttäjätunnus: " DB_USER
read -sp "Salasana: " DB_PASSWORD
echo
read -p "Tietokannan host (default on localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}

# Tarkistetaan onko asennuskansiota, jos ei ole niin luodaan
if [ ! -d "$WP_DIR" ]; then
    mkdir -p $WP_DIR
    echo "Wordpress kansiota ei ollut, luotiin kansio"
fi

# Luodaan tietokanta
sudo mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"

# Tarkistetaan onko käyttäjä jo olemassa
USER_EXISTS=$(sudo mysql -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER' AND host = '$DB_HOST');")

if [ "$USER_EXISTS" -eq 0 ]; then
    # Luodaan käyttäjä ja annetaan oikeudet
    sudo mysql -e "CREATE USER '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASSWORD';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'$DB_HOST';"
    sudo mysql -e "FLUSH PRIVILEGES;"
else
    echo "Käyttäjä $DB_USER on jo olemassa, ohitetaan käyttäjän luonti."
fi

# Ladataan wordpress
TMP_FILE=$(mktemp)
wget $WP_URL -O "$TMP_FILE"

# Puretaan wordpress 
tar -xzf "$TMP_FILE" -C /tmp
rm "$TMP_FILE"

# Siirretään tiedostot asennuskansioon
mv /tmp/wordpress/* "$WP_DIR"


# Päivitetään tiedostojen käyttöoikeudet
chown -R www-data:www-data "$WP_DIR"
find "$WP_DIR" -type d -exec chmod 755 {} \;
find "$WP_DIR" -type f -exec chmod 644 {} \;

# Config tiedoston luonti
cp "$WP_DIR/wp-config-sample.php" "$WP_DIR/wp-config.php"

sed -i "s/database_name_here/$DB_NAME/" "$WP_DIR/wp-config.php"
sed -i "s/username_here/$DB_USER/" "$WP_DIR/wp-config.php"
sed -i "s/password_here/$DB_PASSWORD/" "$WP_DIR/wp-config.php"

echo "WordPress asennus on valmis. Siirry selaimella palvelimen IP-osoitteesee."
