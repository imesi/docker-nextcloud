#! /bin/sh

OCC="/var/www/html/occ"

$OCC app:install richdocuments
$OCC config:app:set richdocuments wopi_url --value=https://$COLLABORA_DOMAIN
