[Youtube video](https://youtu.be/drmZjI6JWs8?si=GI5dSdZwLpFFYcKd)

# k3s-install

As root:

```vi /etc/fstab```

Comment out the SWAP entry.
After saving the file, disable SWAP by running:

```swapoff -a```

Check the memory:

```free -m```

Install k3s:

```curl -sfL https://get.k3s.io | sh -    ```

# Preserve source IP

```
kubectl edit svc traefik -n kube-system
externalTrafficPolicy: Local
```

# CloudflareD

```
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
apt update && apt install cloudflared
cloudflared tunnel login
cloudflared tunnel create my-tunnel
kubectl create secret generic tunnel-credentials --from-file=credentials.json=.cloudflared/5623acb0-bf87-437a-9678-859b80abd1fb.json
kubectl apply -f cloudflared.yaml
cloudflared tunnel route dns my-tunnel "*.linuxcloudhacks.ovh"
```

# Whoami pod

```
kubectl apply -f whoami.yaml
kubectl get deployment
kubectl get pods -o wide
kubectl get svc
kubectl describe ingress whoami-ingress
curl --header "Host: whoami.linuxcloudhacks.ovh" 192.168.10.230
```

# Uptime kuma pod

```
kubectl apply -f uptime.yaml
```


