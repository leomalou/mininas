# mininas

wget https://raw.githubusercontent.com/leomalou/mininas/main/scriptnas.sh
```
#Parametre global
[global]
   workgroup = Contoso
   netbios name = NAS
   server string = MiniNAS TSSR
   security = user
   passdb backend = tdbsam
   encrypt passwords = yes
   interfaces = ens33
   obey pam restrictions = yes

#Parametre des fichier perso

[homes]
   path = /home/%S
   browseable = no
   valid users = %S
   create mask = 600
   directory mask = 700

#Parametre du partage public

[public]
   path = /partage/public
   read only = yes
   valid users = @employes
   create mask = 644
   directory mask = 755

#Parametre du partage commun

[commun]
   path = /partage/commun
   read only = no
   valid users = @employes
   create mask = 664
   directory mask = 775

#Parametre du partage direction

[direction]
   path = /partage/direction
   read only = no
   valid users = dupuis
   create mask = 660
   directory mask = 770

#Parametre du partage compta

[compta]
   path = /partage/compta
   read only = no
   valid users = boulier
   create mask = 660
   directory mask = 770

#Parametre du partage comunication

[communication]
   path = /partage/communication
   read only = no
   valid users = jeanne
   create mask = 660
   directory mask = 770
```
#Script de backup
```
#!/bin/bash

mkdir -p /backup
mkdir -p "/backup/"
cp -a /home "/backup/"

echo "=== Terminé ==="
```
   
