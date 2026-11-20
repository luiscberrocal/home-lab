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
