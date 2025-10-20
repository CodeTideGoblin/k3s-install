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

# MetalLB (optional)

Apply address pool and L2 advertisement if using MetalLB:

```
kubectl apply -f metallb-addr-pool.yaml
kubectl apply -f metallb-advertise.yaml
```

# Cloudflare Tunnel

Install cloudflared on the host and create a Tunnel. Create the secret in the same namespace as the Deployment (cloudflared):

```
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install -y cloudflared
cloudflared tunnel login
cloudflared tunnel create my-tunnel
kubectl create namespace cloudflared || true
kubectl -n cloudflared create secret generic tunnel-credentials --from-file=credentials.json=$HOME/.cloudflared/<YOUR_TUNNEL_ID>.json
kubectl apply -f cloudflared.yaml
cloudflared tunnel route dns my-tunnel "*.sotools.cc"
```

# Apps: whoami and Uptime Kuma

```
kubectl create namespace apps || true
kubectl apply -f whoami.yaml
kubectl apply -f uptime.yaml
kubectl get deployment -A
kubectl get pods -A -o wide
kubectl get svc -A
kubectl describe ingress whoami-ingress -n apps
curl --header "Host: whoami.sotools.cc" <traefik_node_ip>
```

# Kustomize (apply everything)

You can apply the whole repo with kustomize:

```
kubectl apply -k .
```

# Notes

- The manifests set resource requests/limits and basic pod security contexts.
- Uptime Kuma persistent volume claim defaults to 5Gi and no StorageClass; set `storageClassName` as needed.
- In `cloudflared.yaml`, adjust domain, tunnel name, and image tag as needed.


