#!/bin/bash

while [[ $# -gt 1 ]] ; do
  case $1 in
    -k|--key)
      auth_key=$2
      shift
      ;;
    -e|--email)
      auth_email=$2
      shift
      ;;
    -z|--zone)
      zone_name=$2
      shift
      ;;
    -r|--record)
      record_name=$2
      shift
      ;;
    -t|--type)
      record_type=$2
      shift
      ;;
    -p|--proxied)
      proxied=$2
      shift
      ;;
    *)
    ;;
  esac
  shift
done

[ -n "$auth_key" ] || { echo 'Missing auth key' ; exit 1 ; }
[ -n "$auth_email" ] || { echo 'Missing auth email' ; exit 1 ; }
[ -n "$zone_name" ] || { echo 'Missing zone name' ; exit 1 ; }
[ -n "$record_name" ] || { echo 'Missing record name' ; exit 1 ; }
[ -n "$record_type" ] || record_type=A
[ -n "$proxied" ] || proxied="true"

# LOGGER
log() {
    if [ -n "$1" ]; then
        echo -e "[$(date)] - $1"
    fi
}

ip=$(curl -s https://ipv4.icanhazip.com)
ip_file="ip.txt"
id_file="cloudflare.ids"

# SCRIPT START
log "Check Initiated"

if [ -z "$ip" ]; then
    echo -e "Updated IP is empty"
    exit 1
fi

if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ "$ip" == "$old_ip" ]; then
        log "IP has not changed."
        echo "IP has not changed."
        exit 0
    fi
fi

if [ -f $id_file ] && [ $(wc -l $id_file | cut -d " " -f 1) == 2 ]; then
    zone_identifier=$(head -1 $id_file)
    record_identifier=$(tail -1 $id_file)
else
    zone_identifier=$(\
      curl \
        -s \
        -X GET \
        "https://api.cloudflare.com/client/v4/zones?name=$zone_name" \
        -H "X-Auth-Email: $auth_email" \
        -H "X-Auth-Key: $auth_key" \
        -H "Content-Type: application/json" | \
      grep -Po '(?<="id":")[^"]*' | head -1 )
    record_identifier=$(\
      curl \
        -s \
        -X GET \
        "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name&type=$record_type" \
        -H "X-Auth-Email: $auth_email" \
        -H "X-Auth-Key: $auth_key" \
        -H "Content-Type: application/json" | \
      grep -Po '(?<="id":")[^"]*')
    echo "$zone_identifier" > $id_file
    echo "$record_identifier" >> $id_file
fi

curr_ip=$(\
  curl \
    -s \
    -X GET \
    "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
    -H "X-Auth-Email: $auth_email" \
    -H "X-Auth-Key: $auth_key" \
    -H "Content-Type: application/json" | \
  grep -Po '(?<="content":")[^"]*')

log "Current IP : $curr_ip"
log "New IP     : $ip"

update=$(\
  curl \
    -s \
    -X PUT \
    "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
    -H "X-Auth-Email: $auth_email" \
    -H "X-Auth-Key: $auth_key" \
    -H "Content-Type: application/json" \
    --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\",\"proxied\":$proxied}")

if [[ $update == *"\"success\":false"* ]]; then
    message="Update failed:\n$update"
    log "$message"
    echo -e "$message"
    exit 1 
else
    message="Updated IP to : $ip"
    echo "$ip" > $ip_file
    log "$message"
    echo -e "$message"
fi
