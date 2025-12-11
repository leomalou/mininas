#!/bin/bash

echo "=== MiniNAS TSSR : Correctif droits ==="

if [ "$EUID" -ne 0 ]; then
  echo "Lance le script en root."
  exit 1
fi

BASE_DIR="/partage"
PASSWORD="tech"

# Utilisateurs et dossiers métiers
USERS=("dupuis" "boulier" "jeanne" "lagaffe" "lebrac")
DIRECTIONS=("direction" "compta" "communication" "lagaffe" "lebrac")

GROUP_COMMUN="commun"

# 1. Création des dossiers
mkdir -p $BASE_DIR/public
mkdir -p $BASE_DIR/commun

for i in ${!USERS[@]}; do
    mkdir -p "$BASE_DIR/${DIRECTIONS[$i]}"  # dossier métier
    mkdir -p "$BASE_DIR/${USERS[$i]}"       # dossier perso
done

# Fichiers témoins
echo "Public" > $BASE_DIR/public/readme.txt
echo "Commun" > $BASE_DIR/commun/readme.txt
for i in ${!USERS[@]}; do
    echo "${DIRECTIONS[$i]}" > "$BASE_DIR/${DIRECTIONS[$i]}/readme.txt"
    echo "${USERS[$i]} perso" > "$BASE_DIR/${USERS[$i]}/readme.txt"
done

# 2. Création groupe commun
groupadd -f $GROUP_COMMUN

# 3. Création utilisateurs Linux + Samba
for i in ${!USERS[@]}; do
    u=${USERS[$i]}
    if ! id "$u" >/dev/null 2>&1; then
        useradd -m "$u"
    fi
    (echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -s -a "$u"
done

# 4. Droits Linux
chown -R root:root $BASE_DIR/public
chmod -R 755 $BASE_DIR/public

chown -R root:$GROUP_COMMUN $BASE_DIR/commun
chmod -R 770 $BASE_DIR/commun

for i in ${!USERS[@]}; do
    u=${USERS[$i]}
    # dossier métier
    chown -R $u:$u $BASE_DIR/${DIRECTIONS[$i]}
    chmod -R 700 $BASE_DIR/${DIRECTIONS[$i]}
    # dossier perso
    chown -R $u:$u $BASE_DIR/$u
    chmod -R 700 $BASE_DIR/$u
done

# 5. smb.conf via echo
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak

echo "[global]" > /etc/samba/smb.conf
echo "   workgroup = Contoso" >> /etc/samba/smb.conf
echo "   netbios name = NAS" >> /etc/samba/smb.conf
echo "   comment = MiniNAS TSSR" >> /etc/samba/smb.conf
echo "   interfaces = ens33" >> /etc/samba/smb.conf
echo "   encrypt passwords = true" >> /etc/samba/smb.conf
echo "   security = user" >> /etc/samba/smb.conf
echo "   passdb backend = tdbsam" >> /etc/samba/smb.conf
echo "   obey pam restrictions = yes" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

# Public
echo "[public]" >> /etc/samba/smb.conf
echo "   path = $BASE_DIR/public" >> /etc/samba/smb.conf
echo "   browseable = yes" >> /etc/samba/smb.conf
echo "   read only = yes" >> /etc/samba/smb.conf
echo "   guest ok = yes" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

# Commun
echo "[commun]" >> /etc/samba/smb.conf
echo "   path = $BASE_DIR/commun" >> /etc/samba/smb.conf
echo "   browseable = yes" >> /etc/samba/smb.conf
echo "   valid users = @${GROUP_COMMUN}" >> /etc/samba/smb.conf
echo "   writeable = yes" >> /etc/samba/smb.conf
echo "" >> /etc/samba/smb.conf

# Dossiers métiers + perso
for i in ${!USERS[@]}; do
    u=${USERS[$i]}
    # dossier métier
    echo "[${DIRECTIONS[$i]}]" >> /etc/samba/smb.conf
    echo "   path = $BASE_DIR/${DIRECTIONS[$i]}" >> /etc/samba/smb.conf
    echo "   valid users = $u" >> /etc/samba/smb.conf
    echo "   writeable = yes" >> /etc/samba/smb.conf
    echo "" >> /etc/samba/smb.conf
    # dossier perso
    echo "[$u]" >> /etc/samba/smb.conf
    echo "   path = $BASE_DIR/$u" >> /etc/samba/smb.conf
    echo "   valid users = $u" >> /etc/samba/smb.conf
    echo "   writeable = yes" >> /etc/samba/smb.conf
    echo "" >> /etc/samba/smb.conf
done

# 6. Redémarrage Samba
systemctl restart smbd
systemctl restart nmbd

echo "=== MiniNAS TSSR terminé ==="
echo "Accès Windows : \\\\NAS"
echo "Mot de passe pour tous : $PASSWORD"
