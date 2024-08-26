# Nextcloud

Docker compose completo para rodar Nextcloud com:

  - proxy de entrada;
  - geração automática de certificado;
  - usuários via Active Directory (testado com Samba);
  - backup com BorgBackup;
  - Collabora Office integrado.

### Como usar?

Assumindo uma máquina Debian com IP externo:

  - apt install docker.io docker-compose git;
  - git clone [https://github.com/imesi/docker](https://github.com/imesi.docker);
  - ajustar o arquivo .env no diretório docker/nextcloud;
  - obter o certificado CA do Samba;
  - liberar portas 80 e 443 no firewall para a máquina Debian;
  - adicionar no DNS um nome para o serviço do Nextcloud e outro para o serviço do Collabora.

Depois dos passos acima, ir para o diretório do Nextcloud e rodar:

    docker-compose up

### Como obter o certificado CA no Samba?

Numa instalação debian, ele está em /var/lib/samba/private/tls/ca.pem.

### Rotinas de administração

A configuração extra pode ser realizada tanto por meio da interface administrativa quanto do utilitário occ. Para rodar o occ:

    docker-compose exec --user www-data app php occ

##### Usuários

Para listar usuários:

    php occ user:list

Para limpar a configuração de um usuário:

    php occ ldap:reset-user "E8A6F578-1B02-48D2-8BFF-8413F94AB15A"

onde o código é o ID obtido no passo anterior.

##### Skel

Para definir um diretório específico com o conteúdo inicial:

    php occ config:system:set skeletondirectory --value="" --type=string

##### Configurações de brute-force

O nextcloud por padrão limita a quantidade de acessos que um mesmo ip pode realizar. Para liberar um IP em particular, é preciso primeiro habilitar o App _Brute-force settings_, seja pela interface Web ou via ``occ``:

    php occ app:enable bruteforcesettings

Após isso, será possível configurar a _Whitelist_ na página _Administration Settings_, _Seção Security_, item _Brute-force IP whitelist_. Também é possível adicionar uma entrada via `occ`, por exemplo:

    php occ config:app:set bruteForce whitelist_1 --value=143.107.44.127/0

##### Trabalhando com Google Cloud Storage via Rclone

É possível montar o *Google Cloud Storage* (*GCS*) através do *Rclone* no host, e então fazer um bind mount para repassar o diretório (ou um subdiretório) do *GCS* para dentro do container do nextcloud. Isso permite duas abordagens para tratar as pastas de grupo:

  - Fazer um bind mount em um lugar arbitrário (como `/mnt/gcs`) e usar o mecanismo de _External Storage_ do _Nextcloud_ para compartilhar diretórios dentro desse mount com os usuários.
  - Usar o Plug-in de _Group Folders_ e fazer bind mount do diretório `/var/www/data/__groupfolders` para um diretório dentro do mount do GCS.

A vantagem da abordagem do _External Storage_ é que o mecanismo já é pensado para o conceito de um armazenamento que pode ser modificado externamente. Já a abordagem do _Group Folders_ é mais integrada com o _Nextcloud_, dado que o diretório é tratado como parte do armazenamento interno do _Nextcloud_, o que permite por exemplo definir cotas de espaço em disco por pasta de grupo (por mais que a mensagem de erro por ultrapassar a cota na interface web não seja clara). 

Os detalhes do procedimento para montar o GCS via Rclone estão em uma [página dedicada](rclone.md).

##### Borg Backup

O compose inclui um container do _Borg Backup_ que roda periodicamente conforme o arquivo `./backup/crontab.txt` e joga os arquivos em um bind mount que aponta para `/mnt/backukp/borg`. O diretório precisa existir e ter um repositório inicializado para que os backups funcionem. Para inicializar um repositório sem criptografia:

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

Outras opções podem ser definidas no `.backup/config.yaml`. Para uso de criptografia é possível definir a passphrase usando a variável `BORG_PASSPHRASE`.
