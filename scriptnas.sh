#!/bin/bash

echo "=== TP Samba - TSSR : MiniNAS complet avec dossiers perso ==="

# Vérification root
if [ "$EUID" -ne 0 ]; then
  echo "Lance ce script en root."
  exit 1
fi

### ======================
### VARIABLES
### ======================
BASE_DIR="/partage"
PASSWORD="tech"

# Utilisateurs et dossiers perso
declare -A USERS=( ["dupuis"]="direction" ["boulier"]="compta" ["jeanne"]="communication" ["lagaffe"]="lagaffe" ["lebrac"]="lebrac" )

# Groupe commun pour le dossier commun
GROUP_COMMUN="commun"

### ======================
### 1. Installation Samba
### ======================
apt update -y
apt install -y samba

### ======================
### 2. Création des groupes
### ======================
groupadd -f $GROUP_COMMUN

### ======================
### 3. Création des dossiers
### ======================
mkdir -p $BASE_DIR/public
mkdir -p $BASE_DIR/commun

for u in "${!USERS[@]}"; do
  mkdir -p "$BASE_DIR/${USERS[$u]}"   # dossiers métiers ou perso pour salariés
  mkdir -p "$BASE_DIR/$u"             # dossier perso individuel
done

# Fichiers témoins
echo "Public" > $BASE_DIR/public/readme.txt
echo "Commun" > $BASE_DIR/commun/readme.txt

for u in "${!USERS[@]}"; do
  echo "${USERS[$u]}" > "$BASE_DIR/${USERS[$u]}/readme.txt"
  echo "$u perso" > "$BASE_DIR/$u/readme.txt"
done

### ======================
### 4. Création utilisateurs Linux + Samba
### ======================
for u in "${!USERS[@]}"; do
  if ! id "$u" >/dev/null 2>&1; then
    useradd -m "$u"
  fi
  # Mot de passe Samba
  (echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -s -a "$u"
done

### ======================
### 5. Droits Linux
### ======================
# Public = lecture pour tous
chown -R root:root $BASE_DIR/public
chmod -R 755 $BASE_DIR/public

# Commun = RW pour tout le monde (groupe commun)
chown -R root:$GROUP_COMMUN $BASE_DIR/commun
chmod -R 770 $BASE_DIR/commun

# Dossiers métiers / perso par utilisateur
for u in "${!USERS[@]}"; do
  # dossier métier ou perso pour métier
  chown -R $u:$u $BASE_DIR/${USERS[$u]}
  chmod -R 700 $BASE_DIR/${USERS[$u]}
  
  # dossier perso individuel
  chown -R $u:$u $BASE_DIR/$u
  chmod -R 700 $BASE_DIR/$u
done

### ======================
### 6. Création smb.conf via echo
### ======================
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Global
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

# Dossiers métiers / perso
for u in "${!USERS[@]}"; do
  # dossier métier
  echo "[${USERS[$u]}]" >> /etc/samba/smb.conf
  echo "   path = $BASE_DIR/${USERS[$u]}" >> /etc/samba/smb.conf
  echo "   valid users = $u" >> /etc/samba/smb.conf
  echo "   writeable = yes" >> /etc/samba/smb.conf
  echo "" >> /etc/samba/smb.conf

  # dossier perso individuel
  echo "[$u]" >> /etc/samba/smb.conf
  echo "   path = $BASE_DIR/$u" >> /etc/samba/smb.conf
  echo "   valid users = $u" >> /etc/samba/smb.conf
  echo "   writeable = yes" >> /etc/samba/smb.conf
  echo "" >> /etc/samba/smb.conf
done

### ======================
### 7. Redémarrage Samba
### ======================
systemctl restart smbd
systemctl restart nmbd

echo "=== MiniNAS TSSR terminé ==="
echo "Accès Windows : \\\\NAS"
echo "Mot de passe pour tous les utilisateurs : $PASSWORD"
