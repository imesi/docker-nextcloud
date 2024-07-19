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
