#!/usr/bin/env bash
set -e

LOG_FILE="logs/initialize-containerd.log"
echo "Initializing containerd and setting up Kubernetes..." | tee -a $LOG_FILE

# Vérification de la présence des outils nécessaires
if ! command -v containerd &> /dev/null; then
    echo "containerd n'est pas installé. Abandon." | tee -a $LOG_FILE
    exit 1
fi

if ! command -v kubeadm &> /dev/null; then
    echo "kubeadm n'est pas installé. Abandon." | tee -a $LOG_FILE
    exit 1
fi

# Vérification du fichier de configuration de containerd
CONTAINERD_CONFIG="/etc/containerd/config.toml"
if [[ ! -f "$CONTAINERD_CONFIG" ]]; then
    echo "Le fichier de configuration de containerd n'existe pas. Abandon." | tee -a $LOG_FILE
    exit 1
fi

# Activer le plugin "overlay" dans le fichier config.toml de containerd
echo "Modification du fichier de configuration de containerd " | tee -a $LOG_FILE
sudo sed -i 's|disabled_plugin = ["cri"]|enabled_plugin = ["cri"]|' $CONTAINERD_CONFIG

# Redémarrer le service containerd
echo "Redémarrage du service containerd..." | tee -a $LOG_FILE
if ! sudo systemctl restart containerd; then
    echo "Échec du redémarrage de containerd. Vérifiez les logs pour plus de détails." | tee -a $LOG_FILE
    exit 1
fi

# Exécution de la commande kubeadm init
echo "Exécution de kubeadm init pour initialiser le cluster Kubernetes..." | tee -a $LOG_FILE
if ! kubeadm init --apiserver-advertise-address=192.168.225.132 --pod-network-cidr=10.244.0.0/16 ; then
    echo "Échec de l'initialisation de Kubernetes avec kubeadm. Vérifiez les logs pour plus de détails." | tee -a $LOG_FILE
    exit 1
fi

echo "Processus d'initialisation terminé avec succès." | tee -a $LOG_FILE

