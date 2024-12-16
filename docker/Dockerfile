# Utilisation de l'image officielle de Python
FROM python:3.9

# Définition du répertoire de travail
WORKDIR /app

# Copie des fichiers de l'application dans le conteneur
COPY . /app

# Installation des dépendances via requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Exposition du port Flask
EXPOSE 5000

# Commande pour démarrer l'application Flask
CMD ["python", "app.py"]
