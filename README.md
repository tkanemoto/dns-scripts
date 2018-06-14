# dns-scripts
A collection of scripts that updates the DNS record on services such as GoDaddy and CloudFlare.

## GoDaddy
Usage:

```bash
./update-godaddy.sh [-k|--key key] [-s|--secret secret] [-d|--domain domain] [-n|--name name] [-l|--ttl TTL]
```

## CloudFlare
Usage:

```bash
./update-clareflare.sh [-k|--key auth-key] [-e|--email auth-email] [-z|--zone zone-name] [-r|--record record-name] [-t|--type record-type]
```
