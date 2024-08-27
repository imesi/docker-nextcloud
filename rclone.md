# Trabalhando com o GCS via Rclone

## Instalação

No debian, instalamos os pacotes `rclone` e `fuse3`. O fuse é necessário para a função `mount` mas não conta como dependência pois o rclone possui outros modos de operação.

```
apt install rclone fuse3
```

## Configuração

Para configurar, execute:

```
rclone config
```

E escolha a opção `n) New remote`. As configurações que fogem do padrão são:

```
name> nome-para-seu-compartilhamento
Storage> google cloud storage
bucket_policy_only> true
```

Caso esteja em uma máquina remota, lembre-se de responder `No` na pergunta `Use web browser to automatically authenticate rclone with remote?` no final da configuração. O caminho padrão onde a configuração resultante fica salva é `$HOME/.config/rclone/rclone.conf`.

## Montando

Assumindo o endereço do GCS:

https://console.cloud.google.com/storage/browser/usp-gcp-0000073-31415.usp.br

A informação relevante é:

```
usp-gcp-0000073-31415.usp.br
```

Um exemplo de linha para montar o armazenamento que usamos em nossos testes:

```
rclone mount --daemon --allow-other --log-file /var/log/rclone/rclone.log --dir-perms 755 --file-perms 644 --uid 82 --gid 82 --use-server-modtime --transfers 16 --vfs-cache-mode full --vfs-fast-fingerprint --vfs-read-chunk-size 8M --vfs-read-chunk-size-limit off --vfs-read-ahead 256M --vfs-cache-max-age 168h --vfs-cache-max-size 15G nome-para-seu-compartilhamento:usp-gcp-0000073-31415.usp.br /mnt/gcs
```

Detalhando as opções:

  - `--daemon`: Roda o _Rclone_ em segundo plano e libera o terminal.
  - `--allow-other`: Permite acesso aos arquivos por outros usuários. Evita erros de permissão, mas para o caso do mount do `__groupfolders`, não resolve por si só pois o _Nextcloud_ verifica as permissões explicitamente.
  - `--log-file`: Opcional, mas pode ser útil para diagnosticar problemas. É importante que o diretório de destino exista para não dar erro no mount.
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


## Montando automaticamente

É possível fazer o mount via fstab. Primeiro é necessário fazer um symlink do rclone em `/sbin/` com prefixo `mount.`:

```
ln -s /usr/bin/rclone /sbin/mount.rclone
```

Colocando parâmetros similares ao mount acima (excetuando o logfile):

```
    nome-para-seu-compartilhamento:usp-gcp-0000073-31415.usp.br /mnt/gcs rclone allow_other,uid=82,gid=82,dir-perms=755,file-perms=644,use-server-modtime,transfers=16,vfs-cache-mode=full,vfs-fast-fingerprint,vfs-read-chunk-size=8M,vfs-read-chunk-size-limit=off,vfs-read-ahead=256M,vfs-cache-max-age=168h,vfs-cache-max-size=15G,config=/root/.config/rclone/rclone.conf 0 0
```

Nessa linha, a pricipal diferença do exemplo manual é a necessidade de especificar o caminho da configuração do rclone com o parâmetro config. Uma vez especificado o mount point, basta recarregar o fstab, criar o destino do mount e montar:

```
systemctl daemon-reload
mkdir /mnt/gcs
mount /mnt/gcs
```
