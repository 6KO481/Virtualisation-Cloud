# Utilisation de l'image Python
FROM python:3.9-slim

# Répertoire de travail
WORKDIR /app

# Copier les dépendances
COPY requirements.txt requirements.txt

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code dans le conteneur
COPY . .

# Commande de démarrage
CMD ["python", "app.py"]
