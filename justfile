npm_dir := "nginx-proxy-manager"

# List available recipes
default:
    @just --list

# Start Nginx Proxy Manager in the background
npm-up:
    docker compose --project-directory {{npm_dir}} up -d

# Stop and remove the Nginx Proxy Manager container (data is kept)
npm-down:
    docker compose --project-directory {{npm_dir}} down

# Follow Nginx Proxy Manager logs
npm-logs:
    docker compose --project-directory {{npm_dir}} logs -f --tail=100

pihole_dir := "pihole"

# Start Pi-hole in the background
pihole-up:
    docker compose --project-directory {{pihole_dir}} up -d

# Stop and remove the Pi-hole container (data is kept)
pihole-down:
    docker compose --project-directory {{pihole_dir}} down

# Follow Pi-hole logs
pihole-logs:
    docker compose --project-directory {{pihole_dir}} logs -f --tail=100

# Check that Pi-hole resolves normal names and blocks ad domains
pihole-test ip="192.168.68.106":
    @echo "Normal domain (expect a real IP):"
    @dig +short @{{ip}} example.com
    @echo "Ad domain (expect 0.0.0.0):"
    @dig +short @{{ip}} doubleclick.net
