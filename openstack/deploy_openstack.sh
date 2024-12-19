#!/bin/bash

# ==========================================
# Script de déploiement OpenStack
# Ce script crée une infrastructure complète sur OpenStack :
# - Machines virtuelles (VM)
# - Volumes de stockage
# - Réseau privé
# - Registre Docker privé
# ==========================================

# Variables globales de configuration
VM_NAME="api-server"       # Nom de la VM
FLAVOR="m1.small"         # Spécifications (RAM, CPU, stockage)
IMAGE="ubuntu-22.04"      # Nom de l'image à utiliser
NETWORK_NAME="private-network"  # Nom du réseau privé
SUBNET_NAME="private-subnet"    # Nom du sous-réseau
SUBNET_RANGE="192.168.1.0/24"   # Plage d'adresses du sous-réseau
KEY_NAME="my-keypair"     # Nom de la clé SSH
VOLUME_NAME="db-volume"   # Nom du volume de stockage
VOLUME_SIZE=20             # Taille du volume (en Go)
DOCKER_REGISTRY_PORT=5000  # Port pour le registre Docker

# ==========================================
# 1. Création d'un réseau privé
# ==========================================
echo "=== Création du réseau privé ==="
openstack network create $NETWORK_NAME

openstack subnet create \
  --network $NETWORK_NAME \
  --subnet-range $SUBNET_RANGE \
  $SUBNET_NAME

# ==========================================
# 2. Création d'une machine virtuelle (VM)
# ==========================================
echo "=== Création de la VM : $VM_NAME ==="
openstack server create \
  --flavor $FLAVOR \
  --image $IMAGE \
  --network $NETWORK_NAME \
  --key-name $KEY_NAME \
  $VM_NAME

# ==========================================
# 3. Création et attachement d'un volume de stockage
# ==========================================
echo "=== Création et attachement d'un volume : $VOLUME_NAME ==="
openstack volume create --size $VOLUME_SIZE $VOLUME_NAME

VM_ID=$(openstack server show $VM_NAME -f value -c id)
VOLUME_ID=$(openstack volume show $VOLUME_NAME -f value -c id)

openstack server add volume $VM_ID $VOLUME_ID

# ==========================================
# 4. Déploiement d'un registre Docker privé
# ==========================================
echo "=== Déploiement du registre Docker privé ==="
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  registry:
    image: registry:2
    container_name: docker-registry
    ports:
      - "$DOCKER_REGISTRY_PORT:5000"
    volumes:
      - registry-data:/var/lib/registry
volumes:
  registry-data:
EOF

docker-compose up -d

echo "=== Registre Docker privé démarré sur le port $DOCKER_REGISTRY_PORT ==="

# ==========================================
# 5. Résumé des ressources créées
# ==========================================
echo "\n=== Résumé des ressources créées ==="
echo "- Machine virtuelle : $VM_NAME"
echo "- Réseau privé : $NETWORK_NAME ($SUBNET_RANGE)"
echo "- Volume de stockage : $VOLUME_NAME ($VOLUME_SIZE Go)"
echo "- Registre Docker : Accessible sur le port $DOCKER_REGISTRY_PORT"

# Fin du script
