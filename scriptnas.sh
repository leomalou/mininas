#!/bin/bash

echo "=== MiniNAS Samba - Installation complète ==="

# Vérification root
if [ "$EUID" -ne 0 ]; then
  echo "Lance ce script en root."
  exit 1
fi

##############################
# 1. Installation Samba
##############################

apt update
apt install -y samba

##############################
# 2. Arborescence
##############################

mkdir -p /partage/direction
mkdir -p /partage/compta
mkdir -p /partage/communication
mkdir -p /partage/commun
mkdir -p /partage/public

echo "Direction" > /partage/direction/readme.txt
echo "Compta" > /partage/compta/readme.txt
echo "Communication" > /partage/communication/readme.txt
echo "Commun" > /partage/commun/readme.txt
echo "Public" > /partage/public/readme.txt

##############################
# 3. Groupes par service
##############################

groupadd direction
groupadd compta
groupadd communication
groupadd salaries
groupadd commun
##############################
# 4. Utilisateurs
##############################

adduser --disabled-password --gecos "" dupuis
adduser --disabled-password --gecos "" boulier
adduser --disabled-password --gecos "" jeanne
adduser --disabled-password --gecos "" lagaffe
adduser --disabled-password --gecos "" lebrac

# Assignation groupes
usermod -aG direction commun dupuis
usermod -aG compta commun boulier
usermod -aG communication commun jeanne
usermod -aG salaries commun lagaffe
usermod -aG salaries commun lebrac

##############################
# 5. Droits Linux
##############################

chown -R dupuis:direction /partage/direction
chmod -R 770 /partage/direction

chown -R boulier:compta /partage/compta
chmod -R 770 /partage/compta

chown -R jeanne:communication /partage/communication
chmod -R 770 /partage/communication

chown -R root:salaries /partage/commun
chmod -R 770 /partage/commun

chown -R root:root /partage/public
chmod -R 755 /partage/public

##############################
# 6. smb.conf
##############################

mv /etc/samba/smb.conf /etc/samba/smb.conf.backup

cat <<EOF > /etc/samba/smb.conf
[global]
   workgroup = WORKGROUP
   netbios name = NAS
   comment = Serveur de fichier MiniNAS
   interfaces = ens33
   encrypt passwords = true
   security = user
   passdb backend = tdbsam
   obey pam restrictions = yes

[public]
   path = /partage/public
   browseable = yes
   read only = yes
   guest ok = yes

[commun]
   path = /partage/commun
   valid users = @salaries
   read only = no

[direction]
   path = /partage/direction
   valid users = @direction
   read only = no

[compta]
   path = /partage/compta
   valid users = @compta
   read only = no

[communication]
   path = /partage/communication
   valid users = @communication
   read only = no
EOF

##############################
# 7. Comptes Samba auto-MDP
##############################

for u in dupuis boulier jeanne lagaffe lebrac; do
    printf "tech\ntech\n" | smbpasswd -a $u
done

##############################
# 8. Redémarrage Samba
##############################

systemctl restart smbd
systemctl enable smbd

echo "=== Installation terminée ==="
echo "Accès Windows : \\\\NAS"
echo "Mot de passe par défaut : tech"
