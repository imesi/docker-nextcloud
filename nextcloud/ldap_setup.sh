#! /bin/bash

source ldap.env
OCC='docker-compose exec --user www-data app php occ'

$OCC app:enable user_ldap
$OCC ldap:create-empty-config
$OCC ldap:set-config s01 hasMemberOfFilterSupport 1
$OCC ldap:set-config s01 ldapAgentName $LDAP_USER
$OCC ldap:set-config s01 ldapAgentPassword $LDAP_PASSWORD
$OCC ldap:set-config s01 ldapBase $BASE_DN
$OCC ldap:set-config s01 ldapConfigurationActive 1
$OCC ldap:set-config s01 ldapExperiencedAdmin 1
$OCC ldap:set-config s01 ldapHost $LDAP_HOST
# limita para pessoas do $LOGIN_GROUP 
$OCC ldap:set-config s01 ldapLoginFilter "(&(&(objectclass=person)(memberof=$LOGIN_GROUP_DN))(uid=%uid))"
$OCC ldap:set-config s01 ldapPort 636
$OCC ldap:set-config s01 ldapUserFilter "(&(objectclass=person)(memberof=$LOGIN_GROUP_DN))"
$OCC ldap:set-config s01 ldapUserFilterGroups $LOGIN_GROUP
$OCC ldap:set-config s01 ldapUserFilterObjectclass person
