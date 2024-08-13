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

