# Modelo de migração do Google Drive

O problema que se deseja resolver é como portar uma infraestrutura que outrora estava em shared drives para usar algum mecanismo de storage arbitrário.

A ideia é usar este deployment de nextcloud como intermediário entre algum storage de objeto (e.g. S3, GCS, MinIO) e os usuários.

Montaremos um bucket utilizando o [Rclone](rclone.md). O objetivo é fazer uso do VFS, conferindo propriedades de um sistema de arquivos tradicional a um mount oriundo de um storage de objetos. Há um caveat: **não é possível** escalar, pois o VFS liga um sistema de arquivos local ao storage de objetos.

Utilizaremos as pastas de grupo (groupfolders) para entregar o análogo dos drives de grupo da google. Somente as pastas de grupo serão armazenadas no storage de objetos.

O storage de objetos é montado no **host** do docker e o subdiretório utilizado para os groupfolders é montado via bind mount na criação do container. Em particular, ele deve ficar no diretório `$NEXTCLOUD_DATA_DIR/__groupfolders`. A montagem é o único procedimento que liga o Nextcloud ao storage de objeto e, portanto, é transparente para o Nextcloud.

### Criando uma pasta de grupo

Estamos criando pastas de grupo a partir do usuário admin. Basta acessar o painel de administração e clicar no menu Pastas grupo. É **necessário** atribuir um grupo a um groupfolder. Também é possível atribuir uma quota.

```bash
# se precisar de grupo
docker-compose exec -u 82 app php occ group:add nome_do_grupo
docker-compose exec -u 82 app php occ group:adduser nome_do_grupo id_do_membro

# cria groupfolder
docker-compose exec -u 82 app php occ groupfolders:create nome_do_grupo

# adiciona um grupo a um groupfolder
docker-compose exec -u 82 app php occ groupfolders:group id_do_groupfolder nome_do_grupo <write|share|delete>

# adiciona quota a um groupfolder
docker-compose exec -u 82 app php occ groupfolders:quota id_do_groupfolder quota
```

### Trazendo os dados do drive de grupo

Também utilizamos o Rclone para trazer os dados dos drives de grupo para um storage local. A ideia é configurar o Rclone para acessar o drive, mas **sem montar**, e fazer a cópia via `rclone copy`.

```bash
# i é um acesso pré-configurado a um drive
rclone dedupe --dedupe-mode rename $i-drive:
rclone copy --create-empty-src-dirs --drive-acknowledge-abuse $i-drive: /backup/drive/$i
rclone check --one-way --missing-on-dst /root/ARQUIVOS-NAO-COPIADOS-$i $i-drive: /backup/drive/$i
```
Há um porém: os arquivos do Google Docs, sem formato, serão exportados em formato de Office. Os formulários não serão salvos.

### Migrando dados locais para o Nextcloud

O Nextcloud não reconhece automaticamente qualquer conteúdo que seja colocado por fora dele. Daí é necessário um procedimento de scan para levar o novo conteúdo para registrar o conteúdo copiado por fora no Nextcloud, criando os metadadados necessários.

Para copiar "manualmente" algum arquivo para o Nextcloud, basta:
  - copiá-lo para o diretório correto referente ao groupfolder;
  - rodar `docker-compose exec -u 82 app php occ groupfolders:scan --all`.

É possível fornecer direto o ID de um groupfolder, que é um número inteiro. Basta trocar o `--all` pelo ID.

IMPORTANTE: é **necessário** criar o groupfolder **antes** de copiar os arquivos.
