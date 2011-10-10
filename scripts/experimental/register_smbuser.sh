#!/bin/bash
for u in $*; do
	useradd -M -d /var/hyperspace-$u -c "samba account" -s /bin/false -g samba -G users,vdr $u
	smbpasswd -a $u
done
