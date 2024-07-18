#! /bin/bash

OCC='docker-compose exec --user www-data app php occ'

$OCC app:install richdocuments
$OCC config:app:set richdocuments wopi_url --value=https://office.ime.usp.br
