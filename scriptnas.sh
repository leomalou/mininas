#!/bin/bash

echo "=== MiniNAS TSSR - Installation complète ==="

if [ "$EUID" -ne 0 ]; then
  echo "Lance ce script en root."
  exit 1
fi

PASSWORD="tech"
BASE="/partage"

########## 1. Installation ##########

apt update -y
apt install -y samba

########## 2. Groupes ##########

groupadd employes 2>/dev/null || true

########## 3. Utilisateurs ##########

USERS="dupuis boulier jeanne lagaffe lebrac"

for u in $USERS; do
    if ! id "$u" >/dev/null 2>&1; then
        useradd -m "$u"
    fi
    usermod -aG employes "$u"

    # Mot de passe Samba
    (echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a -s "$u"
done

########## 4. Arborescence ##########

mkdir -p $BASE/public
mkdir -p $BASE/commun
mkdir -p $BASE/direction
mkdir -p $BASE/compta
mkdir -p $BASE/communication

echo "Fichier Public" > $BASE/public/readme.txt
echo "Fichier Commun" > $BASE/commun/readme.txt
echo "Direction" > $BASE/direction/readme.txt
echo "Compta" > $BASE/compta/readme.txt
echo "Communication" > $BASE/communication/readme.txt

########## 5. Droits Linux ##########

# public → lecture seule pour tous
chown -R root:employes $BASE/public
chmod -R 755 $BASE/public

# commun → RW pour tous les employés
chown -R root:employes $BASE/commun
chmod -R 775 $BASE/commun

# direction (Dupuis)
chown -R dupuis:dupuis $BASE/direction
chmod -R 770 $BASE/direction

# compta (Boulier)
chown -R boulier:boulier $BASE/compta
chmod -R 770 $BASE/compta

# communication (Jeanne)
chown -R jeanne:jeanne $BASE/communication
chmod -R 770 $BASE/communication

########## 6. smb.conf ##########

mv /etc/samba/smb.conf /etc/samba/smb.conf.bak

echo "[global]" > /etc/samba/smb.conf
echo "   workgroup = Contoso" >> /etc/samba/smb.conf
echo "   netbios name = NAS" >> /etc/samba/smb.conf
echo "   server string = MiniNAS TSSR" >> /etc/samba/smb.conf
echo "   security = user" >> /etc/samba/smb.conf
echo "   passdb backend = tdbsam" >> /etc/samba/smb.conf
echo "   encrypt passwords = yes" >> /etc/samba/smb.conf
echo "   interfaces = lo ens33" >> /etc/samba/smb.conf
echo "   obey pam restrictions = yes" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

# Homes
echo "[homes]" >> /etc/samba/smb.conf
echo "   path = /home/%S" >> /etc/samba/smb.conf
echo "   browseable = no" >> /etc/samba/smb.conf
echo "   valid users = %S" >> /etc/samba/smb.conf
echo "   create mask = 600" >> /etc/samba/smb.conf
echo "   directory mask = 700" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

# Public
echo "[public]" >> /etc/samba/smb.conf
echo "   path = /partage/public" >> /etc/samba/smb.conf
echo "   read only = yes" >> /etc/samba/smb.conf
echo "   valid users = @employes" >> /etc/samba/smb.conf
echo "   create mask = 644" >> /etc/samba/smb.conf
echo "   directory mask = 755" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

# Commun
echo "[commun]" >> /etc/samba/smb.conf
echo "   path = /partage/commun" >> /etc/samba/smb.conf
echo "   read only = no" >> /etc/samba/smb.conf
echo "   valid users = @employes" >> /etc/samba/smb.conf
echo "   force group = employes" >> /etc/samba/smb.conf
echo "   create mask = 664" >> /etc/samba/smb.conf
echo "   directory mask = 775" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

# Direction
echo "[direction]" >> /etc/samba/smb.conf
echo "   path = /partage/direction" >> /etc/samba/smb.conf
echo "   read only = no" >> /etc/samba/smb.conf
echo "   valid users = dupuis" >> /etc/samba/smb.conf
echo "   create mask = 660" >> /etc/samba/smb.conf
echo "   directory mask = 770" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

# Compta
echo "[compta]" >> /etc/samba/smb.conf
echo "   path = /partage/compta" >> /etc/samba/smb.conf
echo "   read only = no" >> /etc/samba/smb.conf
echo "   valid users = boulier" >> /etc/samba/smb.conf
echo "   create mask = 660" >> /etc/samba/smb.conf
echo "   directory mask = 770" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

# Communication
echo "[communication]" >> /etc/samba/smb.conf
echo "   path = /partage/communication" >> /etc/samba/smb.conf
echo "   read only = no" >> /etc/samba/smb.conf
echo "   valid users = jeanne" >> /etc/samba/smb.conf
echo "   create mask = 660" >> /etc/samba/smb.conf
echo "   directory mask = 770" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

########## 7. Redémarrage ##########

systemctl restart smbd nmbd

echo "=== INSTALLATION TERMINEE ==="
echo "\\\\NAS pour accéder au serveur"
echo "Mot de passe de tous les comptes : tech"
