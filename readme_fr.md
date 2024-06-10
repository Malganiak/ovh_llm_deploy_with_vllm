# Déploiement de LLM sur OVHcloud

## Introduction
Ce guide fournit des instructions étape par étape pour déployer le modèle de langage LLaMA 3 ou tout autre sur OVHcloud en utilisant vLLM pour une inférence et un service efficaces.

- [Documentation officielle](https://blog.ovhcloud.com/how-to-serve-llms-with-vllm-and-ovhcloud-ai-deploy/)
- [Modèles supportés](https://docs.vllm.ai/en/latest/models/supported_models.html)

## Prérequis
Avant de commencer, assurez-vous d'avoir :

- Un compte OVHcloud.
- Un projet Public Cloud.
- Un utilisateur associé aux Produits AI pour le projet Public Cloud.
- OVHcloud AI CLI installé sur votre ordinateur.
- Docker installé sur votre ordinateur ou accès à une instance Debian Docker sur le Public Cloud.

### Pour les utilisateurs Windows n'ayant pas de linux a disposition : Configuration de WSL2
Depuis PowerShell ou CMD :

1. Installez WSL :
    ```sh
    wsl --install
    ```
2. Listez les distributions Linux disponibles :
    ```sh
    wsl --list --online
    ```
3. Installez une distribution spécifique :
    ```sh
    wsl --install -d <Nom_de_la_Distribution>
    ```
4. Changez pour la version WSL2 :
    ```sh
    wsl --set-version <Nom_de_la_Distribution> 2
    ```
5. Activez les fonctionnalités nécessaires et redémarrez :
    ```sh
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    ```
    Redémarrez votre système.

### Configuration de l'OVHcloud AI CLI dans WSL
Depuis votre environnement WSL :

1. Mettez à jour le gestionnaire de paquets :
    ```sh
    sudo apt update
    ```
2. Installez Curl :
    ```sh
    sudo apt install curl
    ```
3. Installez Unzip :
    ```sh
    sudo apt install unzip
    ```
4. Installez OVHcloud AI CLI :
    ```sh
    sudo curl -sSL https://cli.gra.ai.cloud.ovh.net/install.sh | bash
    ```
5. Connectez-vous à OVHcloud :
    ```sh
    ovhai login
    ```

Pour plus de détails, consultez la [documentation de l'OVHcloud AI CLI](https://docs.ovhcloud.com/).

## Construction de l'Image Docker
1. Créez un répertoire pour le Dockerfile :
    ```sh
    mkdir my_vllm_image
    cd my_vllm_image
    nano Dockerfile
    ```
2. Écrivez le Dockerfile :
    ```Dockerfile
    FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime
    WORKDIR /workspace
    RUN apt-get update && apt-get install -y git
    RUN git clone https://github.com/vllm-project/vllm/
    RUN pip3 install --upgrade pip
    RUN pip3 install vllm
    ENV HOME=/workspace
    RUN chown -R 42420:42420 /workspace
    ```
3. Construisez l'image Docker :
    ```sh
    docker build . -t vllm_image:latest
    ```

## Pousser l'Image vers le Registre Partagé
1. Listez les registres partagés :
    ```sh
    ovhai registry list
    ```
2. Connectez-vous au registre partagé :
    ```sh
    docker login -u <utilisateur> -p <mot_de_passe> <adresse_du_registre_partagé>
    ```
3. Taggez et poussez l'image :
    ```sh
    docker tag vllm_image:latest <adresse_du_registre_partagé>/vllm_image:latest
    docker push <adresse_du_registre_partagé>/vllm_image:latest
    ```

## Déploiement du Serveur d'Inférence vLLM
1. Créez un jeton d'accès :
    ```sh
    ovhai token create vllm --role operator --label-selector name=vllm
    ```
2. Déployez l'application :
    ```sh
    ovhai app run <adresse_du_registre_partagé>/vllm_image:latest \
      --name vllm_app \
      --flavor h100-1-gpu \
      --gpu 1 \
      --env HF_TOKEN="<VOTRE_HUGGING_FACE_TOKEN>" \
      --label name=vllm \
      --default-http-port 8080 \
      -- python -m vllm.entrypoints.api_server --host 0.0.0.0 --port 8080 --model <modèle> --dtype half
    ```
3. Surveillez les journaux :
    ```sh
    ovhai app logs -f <ID_DE_L_APPLICATION>
    ```

## Interaction avec le Modèle Déployé
### Utilisation de cURL
```sh
curl --request POST \
  --url https://<ID_DE_L_APPLICATION>.app.gra.ai.cloud.ovh.net/generate \
  --header 'Authorization: Bearer <AI_TOKEN_généré_avec_CLI>' \
  --header 'Content-Type: application/json' \
  --data '{
        "prompt": "<VOTRE_PROMPT>",
        "max_tokens": 50,
        "n": 1,
        "stream": false
}'
