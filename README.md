# Personal Health Coach (PHC)

Application Streamlit d'analyse de données de santé Apple Health, propulsée par LangChain et OpenAI.

## Prérequis

- Docker 20.10+
- Une clé API OpenAI

---

## Construction de l'image

```bash
docker build -t phc .
```

Le build utilise un **multi-stage** :
- `builder` — résout et compile les dépendances Python en wheels
- `runtime` — image finale allégée, sans outils de build, utilisateur non-root

---

## Variables d'environnement

Copier `.sample_env` en `.env` et renseigner les valeurs :

```bash
cp .sample_env .env
```

| Variable | Description | Exemple |
|---|---|---|
| `NAME` | Prénom affiché dans l'assistant | `Runner` |
| `GENDER` | Genre (`male` / `female`) | `male` |
| `AGE` | Âge en années | `30` |
| `WEIGHT` | Poids en kg | `75` |
| `HEIGHT` | Taille en cm | `175` |
| `PACE` | Objectif d'allure en min/km | `6.30` |
| `STRIDE_LENGTH` | Objectif de longueur de foulée en m | `1.00` |
| `HEART_RATE` | Objectif de fréquence cardiaque max | `160` |
| `GROUND_CONTACT_TIME` | Objectif de temps de contact sol en ms | `250` |
| `HEALTH_RECORD_FILE` | Chemin vers le CSV des records | `data/records_data.csv` |
| `HEALTH_WORKOUT_FILE` | Chemin vers le CSV des workouts | `data/workouts_data.csv` |
| `OPENAI_API_KEY` | **Obligatoire** — clé API OpenAI | `sk-...` |
| `SERPAPI_API_KEY` | Optionnel — pour la recherche web | `...` |

> Les secrets ne doivent jamais être intégrés dans l'image. Ils sont injectés au `docker run` via `--env-file`.

---

## Port exposé

| Port | Protocole | Usage |
|---|---|---|
| `8501` | TCP | Interface web Streamlit |

---

## Lancer le conteneur

```bash
docker run -p 8501:8501 --env-file .env phc
```

L'application est accessible sur [http://localhost:8501](http://localhost:8501).

---

## Commandes utiles

**Lancer en arrière-plan**
```bash
docker run -d -p 8501:8501 --env-file .env --name phc-app phc
```

**Voir les logs en temps réel**
```bash
docker logs -f phc-app
```

**Arrêter le conteneur**
```bash
docker stop phc-app
```

**Supprimer le conteneur**
```bash
docker rm phc-app
```

**Reconstruire sans cache**
```bash
docker build --no-cache -t phc .
```

**Inspecter l'image (taille, layers)**
```bash
docker image inspect phc
docker history phc
```

**Ouvrir un shell de débogage (image builder uniquement)**
```bash
docker run --rm -it --entrypoint /bin/bash python:3.11-slim
```

> Le conteneur de production ne permet pas d'ouvrir un shell (`/sbin/nologin`).

---

## Données

Le dépôt inclut des données d'exemple dans `data/` :

| Fichier | Contenu |
|---|---|
| `records_data.csv` | Métriques de santé (fréquence cardiaque, foulée…) |
| `workouts_data.csv` | Historique des séances |

Pour utiliser vos propres données Apple Health : exporter depuis l'app Santé (icône utilisateur → Exporter), copier `export.xml` dans `data/`, puis exécuter `data/process_data.ipynb`.

---

## CI/CD

Le dépôt utilise **GitHub Actions** pour construire et publier automatiquement l'image Docker sur Docker Hub.

### Déclencheurs

| Événement | Action |
|---|---|
| Push sur `main` | Build + push de l'image vers Docker Hub |
| Pull Request vers `main` | Build uniquement (pas de push) |

### Secrets requis

Configurer dans **Settings → Secrets and variables → Actions** :

| Secret | Description |
|---|---|
| `DOCKER_HUB_USERNAME` | Nom d'utilisateur Docker Hub |
| `DOCKER_HUB_TOKEN` | Token d'accès Docker Hub (Account Settings → Security) |

### Images publiées

```
<DOCKER_HUB_USERNAME>/mon-application:latest
<DOCKER_HUB_USERNAME>/mon-application:<git-sha>
```

---

## Demo

![demo](./data/demo.gif)
