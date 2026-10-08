#!/bin/bash
# Remet le labo dans son état d'origine (fichiers + conteneurs)
echo "ATTENTION : toutes vos modifications dans ce dossier seront perdues."
read -p "Continuer ? (o/n) " rep
[ "$rep" != "o" ] && echo "Annulé." && exit 0

docker compose down --remove-orphans
git checkout -- .
git clean -fd
docker compose up -d
docker compose ps
echo "Labo réinitialisé. Testez : curl http://localhost:8080"
