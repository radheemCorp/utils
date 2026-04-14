
# docker_net_table
# Prints a markdown table with Docker network details: Name, Driver, Scope, Internal, IPv4/IPv6 Subnets
docker_net() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker: command not found" >&2
    return 1
  fi

  # Header
  echo "| Name | Driver | Scope | Internal | IPv4 Subnets | IPv6 Subnets |"
  echo "|---|---|---|---|---|---|"

  # Iterate networks
  docker network ls --format '{{.Name}}' | sort | while IFS= read -r name; do
    # Fetch details: Driver|Scope|Internal|Subnet,Gateway ...
    info=$(docker network inspect --format '{{.Driver}}|{{.Scope}}|{{.Internal}}|{{range .IPAM.Config}}{{.Subnet}},{{.Gateway}} {{end}}' "$name" 2>/dev/null)
    
    if [ -z "$info" ]; then continue; fi

    IFS='|' read -r driver scope internal ipam_str <<< "$info"

    ipv4_list=""
    ipv6_list=""

    # Split ipam_str by space
    read -r -a ipam_arr <<< "$ipam_str"

    for entry in "${ipam_arr[@]}"; do
      subnet="${entry%%,*}"
      gateway="${entry##*,}"
      
      display="$subnet"
      if [ -n "$gateway" ] && [ "$gateway" != "<nil>" ] && [ "$gateway" != "" ]; then
         display="$display (gw: $gateway)"
      fi

      if [[ "$subnet" == *:* ]]; then
        [ -n "$ipv6_list" ] && ipv6_list="$ipv6_list<br>"
        ipv6_list="$ipv6_list$display"
      else
        [ -n "$ipv4_list" ] && ipv4_list="$ipv4_list<br>"
        ipv4_list="$ipv4_list$display"
      fi
    done

    [ -z "$ipv4_list" ] && ipv4_list="-"
    [ -z "$ipv6_list" ] && ipv6_list="-"

    echo "| $name | $driver | $scope | $internal | $ipv4_list | $ipv6_list |"
  done
}
