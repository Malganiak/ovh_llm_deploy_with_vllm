# LLM Deployment on OVHcloud

## Introduction
This guide offers a detailed walkthrough for deploying the LLaMA 3 large language model (LLM) on OVHcloud using vLLM to ensure efficient inference and serving.

**Official Documentation:** [OVHcloud Blog](https://blog.ovhcloud.com/how-to-serve-llms-with-vllm-and-ovhcloud-ai-deploy/)  
**Supported Models:** [vLLM Documentation](https://docs.vllm.ai/en/latest/models/supported_models.html)

## Prerequisites
Before you proceed, make sure you have the following:

- An OVHcloud account.
- A Public Cloud project.
- A user associated with the AI Products for the Public Cloud project.
- OVHcloud AI CLI installed on your local computer.
- Docker installed on your local computer or access to a Debian Docker Instance on the Public Cloud.

### For Windows Users who need Linux environment
If you need a Linux environment:

#### WSL2 Setup
From PowerShell or CMD:

1. Install WSL:
    ```sh
    wsl --install
    ```
2. List available Linux distributions:
    ```sh
    wsl --list --online
    ```
3. Install a specific distribution:
    ```sh
    wsl --install -d <Distribution Name>
    ```
4. Change to WSL2 version:
    ```sh
    wsl --set-version <distro name> 2
    ```
5. Enable necessary features and restart:
    ```sh
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    ```

### OVHcloud AI CLI Setup in WSL
From your WSL environment:

1. Update package manager:
    ```sh
    sudo apt update
    ```
2. Install Curl:
    ```sh
    sudo apt install curl
    ```
3. Install Unzip:
    ```sh
    sudo apt install unzip
    ```
4. Install OVHcloud AI CLI:
    ```sh
    sudo curl -sSL https://cli.gra.ai.cloud.ovh.net/install.sh | bash
    ```
5. Login to OVHcloud:
    ```sh
    ovhai login
    ```

For more details, refer to the [OVHcloud AI CLI documentation](https://docs.ovh.com/gb/en/ai/ai-cli-usage/).

## Building the Docker Image
1. Create a directory for the Dockerfile:
    ```sh
    mkdir my_vllm_image
    cd my_vllm_image
    nano Dockerfile
    ```
2. Write the Dockerfile:
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
3. Build the Docker image:
    ```sh
    docker build . -t vllm_image:latest
    ```

## Pushing the Image to the Shared Registry
1. List Shared Registries:
    ```sh
    ovhai registry list
    ```
2. Login to Shared Registry:
    ```sh
    docker login -u <user> -p <password> <shared-registry-address>
    ```
3. Tag and push the image:
    ```sh
    docker tag vllm_image:latest <shared-registry-address>/vllm_image:latest
    docker push <shared-registry-address>/vllm_image:latest
    ```

## Deploying the vLLM Inference Server
1. Create an Access Token:
    ```sh
    ovhai token create vllm --role operator --label-selector name=vllm
    ```
2. Deploy the Application:
    ```sh
    ovhai app run <shared-registry-address>/vllm_image:latest \
      --name vllm_app \
      --flavor h100-1-gpu \
      --gpu 1 \
      --env HF_TOKEN="<YOUR_HUGGING_FACE_TOKEN>" \
      --label name=vllm \
      --default-http-port 8080 \
      -- python -m vllm.entrypoints.api_server --host 0.0.0.0 --port 8080 --model <model> --dtype half
    ```
3. Monitor the Logs:
    ```sh
    ovhai app logs -f <APP_ID>
    ```

## Interacting with the Deployed Model
### Using cURL
```sh
curl --request POST \
  --url https://<APP_ID>.app.gra.ai.cloud.ovh.net/generate \
  --header 'Authorization: Bearer <AI_TOKEN_generated_with_CLI>' \
  --header 'Content-Type: application/json' \
  --data '{
        "prompt": "<YOUR_PROMPT>",
        "max_tokens": 50,
        "n": 1,
        "stream": false
}'
