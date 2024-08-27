# Borg Backup
O compose inclui um container do _Borg Backup_ que roda periodicamente conforme o arquivo `./backup/crontab.txt` e salva os arquivos em um bind mount que aponta para `$BORG_PATH`. O diretório precisa existir e ter um repositório inicializado para que os backups funcionem. Para inicializar um repositório sem criptografia:

```
docker-compose exec backup borgmatic rcreate -e none
/mnt/borg-repository is not a valid repository. Check repo config.
```

Essa mensagem de saída é normal quando o destino é um diretório vazio ainda não incializado. Para rodar um backup de teste manualmente:

```
docker-compose exec backup borgmatic
```

Listando os backups:

```
docker-compose exec backup borgmatic list
```

Também é possível montar o backup do borg:

```
docker-compose exec restore /bin/bash
mkdir /mnt/borg
borgmatic mount --archive latest --mount-point /mnt/borg
```

OBS: o container **não** é o **backup**, é o **restore**, pois há configurações menos restritivas de container que são necessárias para a montagem de sistemas de arquivo com o FUSE.

Assumindo que o backup foi montado em `/mnt/borg`, os arquivos mais relevantes ficam localizados em:
  - `/mnt/borg/root/.borgmatic/mariadb_databases`;
  - `/mnt/borg/mnt/nextcloud_groupfolders`.

Outras opções podem ser definidas no `backup/config.yaml`. Para uso de criptografia é possível definir a passphrase usando a variável `BORG_PASSPHRASE`.
