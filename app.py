import requests
import json

# change for your host
APP_URL = "https://yout_real_url.app.your_zone.ai.cloud.ovh.net"
TOKEN = "your_token"

url = f"{APP_URL}/generate"

headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {TOKEN}"
}
data = {
    "prompt": "Qu'est ce qu'est Llama3?",
    "max_tokens": 100,
    "temperature": 0
}

response = requests.post(url, headers=headers, data=json.dumps(data))

print(response.json())
