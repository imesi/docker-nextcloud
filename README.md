# Nextcloud

Docker compose completo para rodar Nextcloud com:

  - proxy de entrada;
  - geração automática de certificado;
  - usuários via Active Directory (testado com Samba);
  - backup com BorgBackup;
  - Collabora Office integrado.

### Como usar?

Assumindo uma máquina Debian com IP externo:

  - `apt install docker.io docker-compose git`;
  - git clone [https://github.com/imesi/docker-nextcloud](https://github.com/imesi.docker);
  - ajustar o arquivo .env;
  - obter o certificado CA do Samba;
  - liberar portas 80 e 443 no firewall para a máquina Debian;
  - adicionar no DNS um nome para o serviço do Nextcloud e outro para o serviço do Collabora.

Depois dos passos acima, ir para o diretório do Nextcloud e rodar:

    docker-compose up -d

### Como obter o certificado CA no Samba?

Numa instalação debian, ele está em /var/lib/samba/private/tls/ca.pem.

OBS: o DNS do Samba deve ser acessível pela máquina onde roda o Nextcloud. Em particular, o nome contido no CN do certificado deve ser acessível via rede.

Podemos obter o CN com o comando:

    openssl x509 -noout -text -in ca.pem

### Rotinas de administração

A configuração extra pode ser realizada tanto por meio da interface administrativa quanto do utilitário occ. Para rodar o occ:

    docker-compose exec --user www-data app php occ

##### Usuários

Para listar usuários:

    php occ user:list

Para limpar a configuração de um usuário:

    php occ ldap:reset-user "E8A6F578-1B02-48D2-8BFF-8413F94AB15A"

onde o código é o ID obtido no passo anterior.

Há, ainda, algumas configurações portencialmente relevantes com os seguintes atributos autoexplicáveis:

```
"s01ldap_group_filter": "(objectclass=group)",
"s01ldap_group_member_assoc_attribute": "member",
"s01ldap_quota_attr": "",
"s01ldap_quota_def": "10 MB",
```

##### Skel

Para definir um diretório específico com o conteúdo inicial:

    php occ config:system:set skeletondirectory --value="" --type=string

##### Configurações de brute-force

O nextcloud por padrão limita a quantidade de acessos que um mesmo ip pode realizar. Para liberar um IP em particular, é preciso primeiro habilitar o App _Brute-force settings_, seja pela interface Web ou via ``occ``:

    php occ app:enable bruteforcesettings

Após isso, será possível configurar a _Whitelist_ na página _Administration Settings_, _Seção Security_, item _Brute-force IP whitelist_. Também é possível adicionar uma entrada via `occ`, por exemplo:

    php occ config:app:set bruteForce whitelist_1 --value=143.107.44.127/0

##### Trabalhando com Google Cloud Storage via Rclone

É possível montar o *Google Cloud Storage* (*GCS*) via *Rclone* no host e fazer um bind mount para repassar um diretório do *GCS* para dentro do container do Nextcloud. Isso permite duas abordagens para tratar as pastas de grupo:

  - external storage: fazer um bind mount do GCS num lugar arbitrário (como `/mnt/gcs`) e compartilhar diretórios dentro desse mount com os usuários;
  - group folders (pasta de grupo): fazer bind mount do GCS no diretório `/var/www/data/__groupfolders`.

A vantagem da abordagem do _External Storage_ é que o mecanismo já é pensado para o conceito de um armazenamento que pode ser modificado externamente. Já a abordagem do _Group Folders_ é mais integrada com o _Nextcloud_, dado que o diretório é tratado como parte do armazenamento interno do _Nextcloud_, o que permite por exemplo definir quotas de armazenamento por pasta de grupo.

OBS: a mensagem de erro por ultrapassar a quota na interface web diz "erro desconhecido".

Os detalhes do procedimento para montar o GCS via Rclone estão em uma [página dedicada](rclone.md).

##### Backup
As instruções para operar o mecanismo de backup encontram-se na [página sobre backup](borg.md).
