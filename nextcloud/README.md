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

###### Parâmetros do rclone mount

Um exemplo de linha para montar o armazenamento que usamos em nossos testes:

rclone mount --daemon --allow-other --log-file /var/log/rclone/rclone.log --dir-perms 755 --file-perms 644 --uid 82 --gid 82 --use-server-modtime --transfers 16 --vfs-cache-mode full --vfs-fast-fingerprint --vfs-read-chunk-size 8M --vfs-read-chunk-size-limit off --vfs-read-ahead 256M --vfs-cache-max-age 168h --vfs-cache-max-size 15G nome-para-seu-compartilhamento:usp-gcp-0000073-31415.usp.br /mnt/gcs

Detalhando as opções:

  - `--daemon`: Roda o _Rclone_ em segundo plano e libera o terminal.
  - `--allow-other`: Permite acesso aos arquivos por outros usuários. Evita erros de permissão, mas para o caso do mount do `__groupfolders`, não resolve por si só pois o _Nextcloud_ verifica as permissões explicitamente.
  - `--log-file`: Opcional, mas pode ser útil para diagnosticar problemas.
  - `--dir-perms 755 --file-perms 644`: Definem as permissões dos arquivos no mount, dado que o backend do GCS não suporta permissões Unix completas. Os valores 755 para diretórios e 644 para arquivos são o que o _Nextcloud_ espera no diretório `/var/www/data/__groupfolders`.
  - `--uid 82 --gid 82`: Define o dono e o grupo dos arquivos no mount. 82 é o uid e gid do www-data no container do _Nextcloud_.
  - `--use-server-modtime`: Evita a criação de metadados adicionais para preservar a hora de modificação de um arquivo em backends que não o fazem nativamente (como o _GCS_). Aumenta o desempenho quando essa informação não é necessária. Em nossos testes não afeta o comportamento do _Nextcloud_, que provavelmente mantem os próprios metadados.
  - `--transfers`: Aumenta o número de transferências de arquivo em paralelo (o padrão é 4).
  - `--vfs-cache-mode full`: Sem essa flag a escrita é obrigatoriamente sequencial. Necessário para usar o GCS como sistema de arquivos normal sem arriscar problemas de compatibilidade.
  - `--vfs-fast-fingerprint`: Usa um mecanismo mais rápido para verificar se arquivos foram modificados em relação ao remoto. Recomendado na documentação do _Rclone_ para esse tipo de backend. Parte do mecanismo é o mesmo do `--use-server-modetime`.
  - `--vfs-read-chunk-size`: Tamanho de bloco inicial usado para operações de leitura do remoto.
  - `--vfs-read-chunk-size-limit`: Tamanho máximo de bloco usado para operações de leitura do remoto. O padrão é `off`, o que significa que o tamanho do bloco dobra a cada bloco, indefinidamente.
  - `--vfs-read-ahead 256M`: Tamanho do buffer de disco do VFS, além do buffer de memória.
  - `--vfs-cache-max-age 168h`: Tempo máximo em que um arquivo fica no cache desde a última leitura.
  - `--vfs-cache-max-size 15G`: Tamanho máximo de objetos no cache. A documentação ressalta que o tamanho pode ser excedido por arquivos abertos (que nunca saem do cache) e que o tamanho só é verificado a cada `--vfs-cache-poll-interval`, que por padrão é 1 minuto.
