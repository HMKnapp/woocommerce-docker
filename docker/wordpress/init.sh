#!/bin/bash

set -e

if [[ -z ${WORDPRESS_URL} ]]; then
  echo "WORDPRESS_URL not specified."
  if [[ -n ${NGROK_TOKEN} ]]; then 
    echo "Launching ngrok to get temporary URL"
    WORDPRESS_URL=$(ngrok.sh ${NGROK_TOKEN})
  else
    echo "No NGROK_TOKEN specified. Using localhost as URL"
  fi
fi

echo "Waiting for DB host ${WORDPRESS_DB_HOST}"

while ! mysqladmin ping -h"${WORDPRESS_DB_HOST}" --silent; do
  sleep 1
done

echo "Creating Database"

wp config create \
  --dbhost=${WORDPRESS_DB_HOST} \
  --dbname=${WORDPRESS_DB_NAME} \
  --dbuser=${WORDPRESS_DB_USER} \
  --dbpass=${WORDPRESS_DB_PASS} \
  --locale=${WORDPRESS_LOCALE}

echo "Installing Wordpress"

wp core install \
  --url=${WORDPRESS_URL} \
  --title=${WORDPRESS_TITLE} \
  --admin_user=${WORDPRESS_ADMIN_USER} \
  --admin_password=${WORDPRESS_ADMIN_PASS} \
  --admin_email=${WORDPRESS_ADMIN_EMAIL} \
  --skip-email

echo "Installing WooCommerce"
wp plugin install woocommerce --activate

echo "Install Sample Data"
wp plugin install wordpress-importer --activate
wp import wp-content/plugins/woocommerce/sample-data/sample_products.xml --authors=create

if [[ -n ${PLUGIN_URL} ]]; then
  STR_PLUGIN=$(get_plugin.sh ${PLUGIN_URL} ${PLUGIN_VERSION})
  PLUGIN_NAME=$(echo ${STR_PLUGIN} | cut -d'^' -f1)
  PATH_TO_ZIP=$(echo ${STR_PLUGIN} | cut -d'^' -f2)
  wp plugin install ${PATH_TO_ZIP} --activate
fi

echo
echo '####################################'
echo
echo "URL: https://${WORDPRESS_URL}"
echo "Panel: https://${WORDPRESS_URL}/wp-admin/"
echo "User: ${WORDPRESS_ADMIN_USER}"
echo "Password: ${WORDPRESS_ADMIN_PASS}"
echo
echo '####################################'
echo

apache2-foreground "$@"
