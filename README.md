# Home Lab

Home lab configuration

Source: https://www.youtube.com/watch?v=U9tIwCmWctc

## Reverse proxy: Nginx Proxy Manager

Goal: reach LAN services at `https://<service>.home.example.com` with valid
Let's Encrypt certificates, **without opening any ports on the router**.

How it works:

1. A **wildcard certificate** (`*.home.example.com`) is issued with a
   **DNS-01 challenge**. Let's Encrypt checks a TXT record at your DNS
   provider instead of connecting to your network, so no port forwarding is
   needed.
2. **Local DNS** (router, Pi-hole, AdGuard Home…) resolves
   `*.home.example.com` to the LAN IP of the Docker host running NPM.
3. NPM receives the request on 443 and forwards it to the right
   container or IP:port.

### Prerequisites

- A domain you own, with DNS hosted at a provider NPM supports for DNS
  challenges (Cloudflare is the most common; DuckDNS also works for free).
- A Docker host with a static LAN IP (referred to below as `192.168.1.10`).
- Ports 80, 443 and 81 free on that host.

### 1. Start NPM

```bash
cd nginx-proxy-manager
cp .env.example .env        # adjust TZ if needed
docker compose up -d
```

Open `http://192.168.1.10:81`, sign in and create the admin account when
prompted (older versions use `admin@example.com` / `changeme`).

### 2. Create a DNS API token

Cloudflare: *My Profile → API Tokens → Create Token → "Edit zone DNS"*
template, limited to your zone. Copy the token.

### 3. Request the wildcard certificate

In NPM: *SSL Certificates → Add SSL Certificate → Let's Encrypt*

- Domain names: `*.home.example.com` and `home.example.com`
- Enable **Use a DNS Challenge**, provider **Cloudflare**
- Credentials file content:
  ```
  dns_cloudflare_api_token = <your-token>
  ```
- Agree to the ToS and save. Renewals happen automatically.

### 4. Point local DNS at NPM

Add a wildcard record on your local DNS server:

| Record                | Type | Value          |
|-----------------------|------|----------------|
| `*.home.example.com`  | A    | `192.168.1.10` |

Pi-hole (v6) only does exact names through the UI. For a wildcard, set
`misc.dnsmasq_lines` to `address=/home.example.com/192.168.1.10`. You can
also add one Local DNS record per service.

Do **not** create these A records at the public DNS provider. The names
only need to resolve inside your LAN.

### 5. Add proxy hosts

*Hosts → Proxy Hosts → Add Proxy Host*:

- Domain: `npm.home.example.com` → forward to `192.168.1.10`, port `81`
  (now you can reach the admin UI over HTTPS)
- Domain: `<service>.home.example.com` → the service's IP/container and port
- SSL tab: pick the wildcard certificate, enable **Force SSL** and
  **HTTP/2**.
- Enable **Websockets Support** for apps that need it (Home Assistant,
  Portainer, etc.).

If a service runs in Docker on the same host, you can put it on the same
Docker network as NPM and forward to its container name instead of an IP.

### Notes

- `nginx-proxy-manager/data` and `nginx-proxy-manager/letsencrypt` hold the
  database and private keys. They are git-ignored, so back them up
  separately.
- Keep port 81 reachable only from the LAN.
