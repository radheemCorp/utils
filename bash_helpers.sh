
## CIP function
function cip() {
    _print_container_info() {
        local container_search
        local container_id
        local container_ports
        local container_ip
        local container_gateway
        local container_ipv6
        local container_ipv6_gateway
        local container_name
        local container_mac
        local container_network
        container_search="${1}"

        #container_ports=($(docker port "$container_search" | grep -o ":[0-9]\+" | cut -f2 -d:))
        container_name="$(docker container inspect --format "{{.Name}}" "$container_search" | sed 's/\///')"
        container_id="$(docker container inspect --format "{{.ID}}" "$container_search")"
        container_ip="$(docker container inspect --format "{{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}" "$container_search")"
        container_ports="$(docker container inspect "$container_search" |  jq '.[].NetworkSettings.Ports | keys[]')"
        container_ext_ports="$(docker container inspect "$container_search" | jq -r '.[].NetworkSettings.Ports | to_entries[] | select(.value != null) | .value[0].HostPort' | paste -sd ' ' -)"
        container_network=($(docker container inspect --format "{{range \$k, \$v := .NetworkSettings.Networks}}{{printf \"%s\\n\" \$k}}{{end}}" "$container_search"))
        container_working_dir=$(docker container inspect --format '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$container_search")
        container_depends_on_raw=$(docker container inspect --format '{{index .Config.Labels "com.docker.compose.depends_on"}}' "$container_search")
        container_depends_on=$(echo "$container_depends_on_raw" | tr ',' '\n' | cut -d: -f1 | paste -sd ' ' -)

        echo ''$container_name','$container_ip', '${container_ports[*]}','$container_ext_ports','${container_network[*]}','$container_working_dir','$container_depends_on'' >>~/tmp/docker-container.txt
    }

    touch ~/tmp/docker-container.txt
    echo '------------------------------------------------------'
    echo 'CONTAINER,IP,PORT,EXT_PORT,NETWORKS,WORKDIR,DEPENDS_ON' >>~/tmp/docker-container.txt

    local container_search
    container_search="$1"
    if [ -z "$container_search" ]; then
        # if $container_search is empty
        docker ps  --format "{{.ID}}" | while read -r container_search; do
            _print_container_info "$container_search"
        done
    else
        # only calls _print_container_info if $container_search exits
        docker container ls --format "{{.ID}} {{.Names}}" | grep -q "\b$container_search\b" && _print_container_info "$container_search"
    fi

    column -s "," --output-separator " ┊ " -t ~/tmp/docker-container.txt
    echo '------------------------------------------------------'

    rm -r ~/tmp/docker-container.txt
}

alias k='kubectl'
alias ka='kubectl get -A'
alias kctx='kubectx'
alias kns='kubens'
alias tl='tmux ls'
alias tns='tmux new-session -s'
alias ta='tmux attach -t'
alias ko='kubectl -n open5gs'
