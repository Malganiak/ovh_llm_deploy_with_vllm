# FROM : Spécifiez l'image de base pour notre image Docker . Nous choisissons l' image PyTorch car elle est livrée avec CUDA , CuDNN et torch , qui sont nécessaires à vLLM .
# WORKDIR /workspace : Nous définissons le répertoire de travail du conteneur Docker sur /workspace , qui est le dossier par défaut lorsque nous utilisons AI Deploy .
# RUN : Cela nous permet de mettre à niveau pip vers la dernière version pour nous assurer que nous avons accès aux dernières bibliothèques et dépendances. Nous allons installer la bibliothèque vLLM , et git , qui permettront de cloner le référentiel vLLM dans le répertoire /workspace .
# ENV HOME=/workspace : ceci définit la variable d'environnement HOME sur /workspace . C’est une condition nécessaire pour utiliser les produits OVHcloud AI.
# RUN chown -R 42420:42420 /workspace : Cela change le propriétaire du répertoire /workspace en utilisateur et groupe avec les ID 42420 ( utilisateur OVHcloud ). C’est également une condition nécessaire pour utiliser les produits OVHcloud AI.

#  Base image
FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

#  Set the working directory inside the container
WORKDIR /workspace

#  Install missing system packages (git) so we can clone the vLLM project repository
RUN apt-get update && apt-get install -y git
RUN git clone https://github.com/vllm-project/vllm/

#  Install the Python dependencies
RUN pip3 install --upgrade pip
RUN pip3 install vllm 

#  Give correct access rights to the OVHcloud user
ENV HOME=/workspace
RUN chown -R 42420:42420 /workspace