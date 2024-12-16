import os
import io
import torch
import torchvision.transforms as transforms
from torchvision import models
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from PIL import Image
import requests

# Initialisation de l'application Flask
app = Flask(__name__)

# Configuration de la base de données
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'postgresql://user:password@db:5432/mydatabase')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Modèle de la base de données pour enregistrer les prédictions
class Prediction(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    image_name = db.Column(db.String(120), nullable=False)
    predicted_class = db.Column(db.String(120), nullable=False)
    confidence_score = db.Column(db.Float, nullable=False)

# Chargement du modèle ResNet pré-entraîné
model = models.resnet50(pretrained=True)
model.eval()

# Téléchargement des classes ImageNet
imagenet_classes_url = "https://raw.githubusercontent.com/pytorch/hub/master/imagenet_classes.txt"
imagenet_classes = requests.get(imagenet_classes_url).text.splitlines()

# Fonction pour prétraiter l'image
def preprocess_image(image_bytes):
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    return transform(image).unsqueeze(0)

# Route pour effectuer la prédiction
@app.route("/predict", methods=["POST"])
def predict():
    try:
        # Récupérer le fichier image envoyé
        if "file" not in request.files:
            return jsonify({"error": "Aucun fichier fourni."}), 400

        file = request.files["file"]
        if file.filename == "":
            return jsonify({"error": "Nom de fichier vide."}), 400

        # Prétraiter l'image
        image_bytes = file.read()
        input_tensor = preprocess_image(image_bytes)

        # Prédiction avec le modèle
        with torch.no_grad():
            outputs = model(input_tensor)
            probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
            confidence_score, predicted_idx = torch.max(probabilities, dim=0)

        # Obtenir la classe prédite
        predicted_class = imagenet_classes[predicted_idx.item()]

        # Enregistrer la prédiction dans la base
        prediction = Prediction(
            image_name=file.filename,
            predicted_class=predicted_class,
            confidence_score=confidence_score.item()
        )
        db.session.add(prediction)
        db.session.commit()

        response = {
            "confidence_score": confidence_score.item(),
            "predicted_class": predicted_class
        }
        return jsonify(response)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Initialisation automatique de la base
with app.app_context():
    db.create_all()


# Point d'entrée principal
if __name__ == "__main__":
    app.run(debug=True, use_reloader=False)
