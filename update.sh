#!/bin/bash -ex

# Default values
type=A
name=@
ttl=600

while [[ $# -gt 1 ]] ; do
  case $1 in
    -k|--key)
      key=$2
      shift
      ;;
    -s|--secret)
      secret=$2
      shift
      ;;
    -d|--domain)
      domain=$2
      shift
      ;;
    -t|--type)
      type=$2
      shift
      ;;
    -n|--name)
      name=$2
      shift
      ;;
    -l|--ttl)
      ttl=$2
      shift
      ;;
    *)
    ;;
  esac
  shift
done

[ -n "$key" ] || { echo 'Missing key' ; exit 1 ; }
[ -n "$secret" ] || { echo 'Missing secret' ; exit 1 ; }
[ -n "$domain" ] || { echo 'Missing domain' ; exit 1 ; }

cached_ip=/tmp/current_ip
chech_url=http://api.ipify.org
SuccessExec=''
FailedExec=''


echo -n "Checking current 'Public IP' from '${chech_url}'..."
public_ip=$(curl -kLs ${chech_url})
if [ $? -eq 0 ] && [[ "${public_ip}" =~ [0-9]{1,3}\.[0-9]{1,3} ]];then
  echo "Public IP : ${public_ip}!"
else
  echo "Fail! ${public_ip}"
  exit 1
fi

if [ "$(cat ${cached_ip} 2>/dev/null)" != "${public_ip}" ] ; then
  echo -n "Checking '${Domain}' IP records from 'GoDaddy'..."
  check=$(curl -kLsH"Authorization: sso-key ${key}:${secret}" \
               -H"Content-type: application/json" \
               https://api.godaddy.com/v1/domains/${domain}/records/${type}/${name} \
               2>/dev/null | sed -r 's/.+data":"(.+)","t.+/\1/g' 2>/dev/null)
  if [ $? -eq 0 ] && [ "${check}" = "${public_ip}" ] ; then
    echo -n ${check} > ${cached_ip}
    echo -e "unchanged!\nCurrent 'Public IP' matches 'GoDaddy' records. No update required!"
  else
    echo -en "changed!\nUpdating '${domain}'..."
    update=$(curl -kLsXPUT -H"Authorization: sso-key ${key}:${secret}" \
                  -H"Content-type: application/json" \
                  https://api.godaddy.com/v1/domains/${domain}/records/${type}/${name} \
                  -d "{\"data\":\"${public_ip}\",\"ttl\":${ttl}}" 2>/dev/null)
    if [ $? -eq 0 ] && [ "${update}" = "{}" ];then
      echo -n ${public_ip} > ${cached_ip}
      echo "Success!"
    else
      echo "Fail! ${update}"
      exit 1
    fi  
  fi
else
  echo "Current 'Public IP' matches 'Cached IP' recorded. No update required!"
fi
exit $?
