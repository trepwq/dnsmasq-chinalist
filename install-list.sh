#!/bin/bash
set -e

WORKDIR="$(mktemp -d)"
SERVERS=(114.114.114.114 114.114.115.115)

CONF_WITH_SERVERS=(accelerated-domains.china google.china apple.china)
CONF_SIMPLE=(bogus-nxdomain.china)

echo "Downloading latest configurations..."

git clone --depth=1 https://github.com/trepwq/dnsmasq-chinalist.git "$WORKDIR"


echo "Removing old configurations..."
for _conf in "${CONF_WITH_SERVERS[@]}" "${CONF_SIMPLE[@]}"; do
  rm -f /etc/dnsmasq.d/"$_conf"*.conf
done

echo "Installing new configurations..."
for _conf in "${CONF_SIMPLE[@]}"; do
  cp "$WORKDIR/$_conf.conf" "/etc/dnsmasq.d/$_conf.conf"
done

for _server in "${SERVERS[@]}"; do
  for _conf in "${CONF_WITH_SERVERS[@]}"; do
    cp "$WORKDIR/$_conf.conf" "/etc/dnsmasq.d/$_conf.$_server.conf"
  done

  sed -i "s|^\(server.*\)/[^/]*$|\1/$_server|" /etc/dnsmasq.d/*."$_server".conf
done

echo "Restarting dnsmasq service..."
if hash systemctl 2>/dev/null; then
  systemctl restart dnsmasq
elif hash service 2>/dev/null; then
  service dnsmasq restart
else
  echo "Now please restart dnsmasq since I don't know how to do it."
fi

echo "Cleaning up..."
rm -r "$WORKDIR"
