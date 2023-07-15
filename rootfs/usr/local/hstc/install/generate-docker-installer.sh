#!/bin/bash

set -e

# Make the necessary changes to generate the Hestia Docker installer

hestia_dir="$1"

check_result() {
    local file_path="$1"
    local content="$2"
    local invert_match="$3"
    local check_content

    check_content="$(grep -E "$content" "$file_path" || true)"
    if [[ -z "$check_content" && "${invert_match,,}" != "invert" ]] || [[ -n "$check_content" && "${invert_match,,}" == "invert" ]]; then
        echo "Replacement failure: $content in $file_path"
        exit 1
    fi
}

if [[ ! -d "$hestia_dir" || ! -f "$hestia_dir/install/hst-install-debian.sh" ]]; then
    echo "Hestia repository directory is invalid"
    exit 1
fi

cp -af "$hestia_dir/install/hst-install-debian.sh" "$hestia_dir/install/hst-install-debian-docker.sh"

### PHP
if [ -n "$MULTIPHP_VERSIONS" ]; then
    sed -Ei "s|^(multiphp_v=).*|\1\(${MULTIPHP_VERSIONS}\)|" "$hestia_dir/install/hst-install-debian-docker.sh"
    check_result "$hestia_dir/install/hst-install-debian-docker.sh" "^multiphp_v=\(${MULTIPHP_VERSIONS}\)"
fi

# Prevent PHP installation errors
sed -Ei "s|(check_result \\\$\? \"php-fpm start failed\")|#\1|" "$hestia_dir/install/hst-install-debian-docker.sh"
check_result "$hestia_dir/install/hst-install-debian-docker.sh" "#check_result \\\$\? \"php-fpm start failed\""

### MariaDB
# Change MariaDB Version
if [ -n "$MARIADB_CLIENT_VERSION" ]; then
    sed -Ei "s|^(mariadb_v=\").*(\")$|\1${MARIADB_CLIENT_VERSION}\2|" "$hestia_dir/install/hst-install-debian-docker.sh"
    check_result "$hestia_dir/install/hst-install-debian-docker.sh" "^mariadb_v=\"${MARIADB_CLIENT_VERSION}\""
fi

# Remove MariaDB Server from the installer
sed -Ei "s|\- MariaDB Database Server|\- MariaDB Database Client|g" "$hestia_dir/install/hst-install-debian-docker.sh"
check_result "$hestia_dir/install/hst-install-debian-docker.sh" "\- MariaDB Database Client"
sed -Ei "s|(mariadb-common) mariadb-server|\1|g" "$hestia_dir/install/hst-install-debian-docker.sh"
check_result "$hestia_dir/install/hst-install-debian-docker.sh" "mariadb-common mariadb-server" invert
sed -Ezi "s|(.*Configure MariaDB[\ #\n\-]*if )(\[ \"\\\$mysql\" = 'yes' \])|\1\[ -z 'mysql-disabled' \]|g" "$hestia_dir/install/hst-install-debian-docker.sh"
check_result "$hestia_dir/install/hst-install-debian-docker.sh" "if \[ -z 'mysql-disabled' \] || \[ -n 'mysql' \]"
sed -Ei "s|(.*/v-add-database-host mysql .*)|#\1\necho \"---\"|" "$hestia_dir/install/hst-install-debian-docker.sh"
check_result "$hestia_dir/install/hst-install-debian-docker.sh" "#.*/v-add-database-host mysql .*"

# Disable PHPMyAdmin database configuration
sed -Ei "s|(.*/phpmyadmin/pma.sh.*)|#\1|g" "$hestia_dir/install/hst-install-debian-docker.sh"
check_result "$hestia_dir/install/hst-install-debian-docker.sh" "#.*/phpmyadmin/pma.sh.*"

### Hestia
# Remove Hestia source from the apt list to prevent an upgrade after installation
sed -Ei "/\[ \* \] Hestia Control Panel/,/^gpg.*hestia-keyring.gpg/ s/(.*)/#\1/" "$hestia_dir/install/hst-install-debian-docker.sh"
check_result "$hestia_dir/install/hst-install-debian-docker.sh" "#gpg.*hestia-keyring.gpg"

# Remove the server's default domain creation
sed -Ei "s|(\\\$HESTIA/bin/v-add-web-domain admin \\\$servername)|\#\1|" "$hestia_dir/install/hst-install-debian-docker.sh"
sed -Ei "s|(check_result \\\$\? \"can't create \\\$servername domain\")|#\1|" "$hestia_dir/install/hst-install-debian-docker.sh"
check_result "$hestia_dir/install/hst-install-debian-docker.sh" "#check_result \\\$\? \"can't create \\\$servername domain\""

# Disable Roundcube database configuration
sed -Ei "s|(if \[) .*\"\\\$DB_SYSTEM\".* (\]; then)|\1 -z 'db-config-disabled' \2|" "$hestia_dir/bin/v-add-sys-roundcube"
check_result "$hestia_dir/bin/v-add-sys-roundcube" "'db-config-disabled'"

# Avoid errors caused by "reload-or-restart" when trying to restart services
sed -Ei "s%systemctl reload\-or\-restart .*%service \"\\\$service\" reload > /dev/null 2>\&1 || service \"\\\$service\" restart > /dev/null 2>\&1%g" "$hestia_dir/bin/v-restart-service"
check_result "$hestia_dir/bin/v-restart-service" "reload-or-restart" invert

# # Create necessary directories and files
# mkdir -p /etc/logrotate.d || true
# cp -a "$hestia_dir/install/deb/logrotate/httpd-prerotate/"* /etc/logrotate.d/ || true
# cp -a "$hestia_dir/install/deb/sudo/admin" /etc/sudoers.d/ || true
# cp -a "$hestia_dir/install/deb/logrotate/hestia" /etc/logrotate.d/ || true
# mkdir -p /usr/local/hestia/log
# mkdir -p /usr/local/hestia/data
# cp -a "$hestia_dir/install/deb/ssl/dhparam.pem" /usr/local/hestia/data/ || true

# # Modify the Hestia installation script to force installation
# sed -i 's/^test_install$//' "$hestia_dir/install/hst-install-debian-docker.sh"

# ### Hestia
# # Remove Hestia installation check
# sed -Ei "s|if \[ -f \"HESTIA_CHECK\" \]; then|if \[ -z 'hestia-check-disabled' \]; then|" "$hestia_dir/install/hst-install-debian-docker.sh"
# check_result "$hestia_dir/install/hst-install-debian-docker.sh" "if \[ -z 'hestia-check-disabled' \]"


# # Modify the Hestia installation script to fix SSL certificate creation
# sed -i 's/ssl_certificate}\/${data_dir}/ssl_certificate}\//' "$hestia_dir/install/hst-install-debian-docker.sh"

# echo "Docker installer generated successfully."
