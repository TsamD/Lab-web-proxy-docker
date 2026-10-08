# Labo admin sys — 2 serveurs Apache derrière un reverse proxy Nginx

## Ce que contient ce labo

```
          Votre navigateur / curl
                    │
            http://localhost:8080
                    │
          ┌─────────▼─────────┐
          │   proxy (Nginx)   │   ← seul conteneur accessible de l'extérieur
          └────┬─────────┬────┘
               │         │        réseau Docker « labo »
        ┌──────▼──┐   ┌──▼──────┐
        │  web1   │   │  web2   │
        │ Apache  │   │ Apache  │
        └─────────┘   └─────────┘
       www/site1      www/site2
```

Un **reverse proxy** reçoit toutes les requêtes et les transmet aux serveurs web placés derrière lui. Ici, Nginx envoie les requêtes **chacun son tour** à web1 puis à web2 : c'est de la **répartition de charge** (load balancing).

| Fichier | Rôle |
|---|---|
| `docker-compose.yml` | Décrit les 3 conteneurs et le réseau |
| `nginx/default.conf` | Configuration du proxy |
| `www/site1/`, `www/site2/` | Pages web servies par web1 et web2 |
| `reset.sh` | Remet tout le labo dans son état d'origine |

## Démarrage

```bash
git clone [<URL_DU_DEPOT>](https://github.com/TsamD/Lab-web-proxy-docker.git)
cd labo-web-proxy
docker compose up -d
docker compose ps
```

Les 3 conteneurs doivent être à l'état **running** (ou **Up**).

## En cas de problème : tout remettre à zéro

```bash
bash reset.sh
```

⚠️ Cette commande efface **toutes** vos modifications dans le dossier.

---

## Exercice 1 — Observer la répartition de charge

1. Ouvrez `http://localhost:8080` dans le navigateur et rafraîchissez plusieurs fois (F5). Que remarquez-vous ?
2. Faites la même chose en ligne de commande :

```bash
curl http://localhost:8080
curl http://localhost:8080
```

3. Affichez uniquement les en-têtes de la réponse :

```bash
curl -I http://localhost:8080
```

Repérez la ligne `X-Served-By`. Que contient-elle ?

**Question :** pourquoi ne peut-on pas ouvrir directement web1 ou web2 depuis le navigateur ? Indice : regardez la section `ports:` dans `docker-compose.yml`.

## Exercice 2 — Explorer un conteneur

```bash
docker compose exec web1 bash
```

Vous êtes maintenant **dans** le conteneur web1. Explorez :

```bash
hostname
cat /etc/os-release
ls /usr/local/apache2/
ls /usr/local/apache2/htdocs/
exit
```

**Questions :**
- Sur quelle distribution Linux est basé le conteneur Apache ?
- Faites la même chose dans le conteneur `proxy` (attention : il n'a pas `bash`, utilisez `sh`). Quelle distribution ?

## Exercice 3 — Lire les logs

```bash
docker compose logs proxy
docker compose logs web1
docker compose logs -f
```

`-f` = suivre les logs en direct. Rafraîchissez la page dans le navigateur et regardez les lignes apparaître. Quittez avec `Ctrl+C`.

**Question :** dans les logs de web1, quelle adresse IP apparaît comme client ? Est-ce l'IP de votre machine ? Pourquoi ?

## Exercice 4 — Modifier une page web

Modifiez la page servie par web2 **depuis la machine hôte** :

```bash
nano www/site2/index.html
```

Changez le titre `Serveur WEB 2` en ce que vous voulez.
Enregistrez avec `Ctrl+O` puis `Entrée`, quittez avec `Ctrl+X`.

Rafraîchissez le navigateur jusqu'à tomber sur web2.

**Question :** vous n'avez pas redémarré le conteneur. Pourquoi la modification est-elle visible immédiatement ? (mot-clé : *bind mount*)

## Exercice 5 — Panne d'un serveur

1. Arrêtez web1 :

```bash
docker compose stop web1
docker compose ps
```

2. Rafraîchissez plusieurs fois le navigateur. Le site fonctionne-t-il encore ? Qui répond ?
3. Redémarrez web1 :

```bash
docker compose start web1
```

**Question :** quel est l'intérêt d'avoir 2 serveurs web derrière un proxy ?

## Exercice 6 — Le réseau Docker

```bash
docker network ls
docker network inspect labo
```

Notez l'adresse IP de chaque conteneur.

**Question :** dans `nginx/default.conf`, le proxy contacte `web1` et `web2` par leur **nom**, pas par leur IP. Qui fait la traduction nom → IP ?

## Exercice 7 — Dépannage 🔧

1. Arrêtez web1 : `docker compose stop web1`
2. Redémarrez le proxy : `docker compose restart proxy`
3. Vérifiez l'état : `docker compose ps`
4. Que se passe-t-il ? Trouvez la cause dans les logs du proxy.
5. Remettez le labo en état de marche.

## Exercice 8 — Pondération

On veut que web1 reçoive **3 fois plus** de requêtes que web2 (par exemple parce que c'est une machine plus puissante).

- Cherchez dans la documentation Nginx l'option `weight` de la directive `upstream`.
- Modifiez `nginx/default.conf` (pensez à `Ctrl+X` pour quitter nano).
- Appliquez la modification **sans** arrêter le site.
- Vérifiez avec une dizaine de `curl -I`.

## Exercice 9 — Défi : un 3ᵉ serveur

Ajoutez un serveur **web3** (Apache) avec sa propre page `www/site3/index.html`, et faites-le intégrer à la répartition de charge.

Fichiers à modifier : à vous de trouver lesquels 😉

---

## Aide-mémoire

| Commande | Effet |
|---|---|
| `docker compose up -d` | Crée et démarre le labo |
| `docker compose ps` | État des conteneurs |
| `docker compose stop <service>` | Arrête un conteneur (sans le supprimer) |
| `docker compose start <service>` | Redémarre un conteneur arrêté |
| `docker compose restart <service>` | Arrête puis redémarre |
| `docker compose logs -f <service>` | Logs en direct |
| `docker compose exec <service> bash` | Ouvre un terminal dans le conteneur |
| `docker compose down` | Arrête **et supprime** les conteneurs |
| `bash reset.sh` | Remet tout à zéro |
