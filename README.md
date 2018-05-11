
# K1Plaza ♥ Docker
A forma ideal de utilizar o K1Plaza é através de imagens pré-configuradas do Docker.

A imagem https://hub.docker.com/r/cafe01/k1plaza/ contém sempre a última versão do K1Plaza instalada em um linux Debian 9-slim com todas as dependências necessárias tambem já instaladas. Essa imagem é gerada a partir do arquivo [Dockerfile](./Dockerfile) desse repositorio.

Se você ainda não possui o Docker instalado, aqui estão os tutoriais pra cada sistema:
- [Linux Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository)
- [Mac](https://docs.docker.com/docker-for-mac/install/#install-and-run-docker-for-mac)
- [Mac Antigo](https://docs.docker.com/toolbox/toolbox_install_mac/)
- [Windows 10 Pro ou Enterprise](https://docs.docker.com/docker-for-windows/install/)
- [Windows 10 Home ou anterior](https://docs.docker.com/toolbox/toolbox_install_windows/)

# Instalando o K1Plaza

## 1. Criar o arquivo docker-compose.yml
Em uma nova pasta chamada `k1plaza` no seu computador, crie o arquivo `docker-compose.yml` com o seguinte conteúdo:

```yaml
# Arquivo docker-compose.yml - K1Plaza CMS
# Esse arquivo descreve os container necessários para o funcionamento do K1Plaza.
# O primeiro, chamado 'k1plaza', utiliza a imagem mais atual do K1Plaza (cafe01/k1plaza:latest).
# O segundo, chamado 'k1plaza_mysql', utiliza a imagem oficial do MySQL na versão 5.7 (mysql:5.7).

version: "3"
services:
  app:
    image: cafe01/k1plaza:latest
    container_name: k1plaza
    depends_on:
      - db
    networks:
      - k1plaza
    ports:
      - "3000:3000"
    volumes:
      - "./projetos:/projects"
      - "uploads:/k1plaza/file_storage"
  db:
    image: mysql:5.7
    container_name: k1plaza_mysql
    networks:
      - k1plaza
    ports:
      - "3306:3306"
    volumes:
      - "db-data:/var/lib/mysql"
    environment:
      MYSQL_ROOT_PASSWORD: P@ssw0rd
      MYSQL_DATABASE: k1plaza_development
      MYSQL_USER: k1plaza
      MYSQL_PASSWORD: P@ssw0rd
networks:
  k1plaza:
volumes:
  db-data:
  uploads:
```

## 2. Iniciar o K1Plaza
Usando o prompt de comando, acesse a pasta aonde se encontra o arquivo `docker-compose.yml` e execute o comando `docker-compose up`.

Ex:
```
[~]$ cd ~/workspace/k1plaza
[~/workspace/k1plaza]$ ls docker-compose.yml
docker-compose.yml
[~/workspace/k1plaza]$ docker-compose up
Starting k1plaza_mysql ... done
Recreating k1plaza     ... done
Attaching to k1plaza_mysql, k1plaza
...
```
O comando `docker-compose up` executa as seguintes tarefas:
1. Se não existir localmente, faz download da imagem cafe01/k1plaza:latest;
2. Se não existir localmente, faz download da imagem mysql:5.7;
3. Se nao exitir, cria um container chamado k1plaza com a imagem do cafe01/k1plaza:latest.
4. Se nao exitir, cria um container chamado k1plaza_mysql com a imagem do mysql:5.7.
5. Inicia o container k1plaza_mysql
6. Inicia o container k1plaza
7. Cria uma rede privada entre os dois containers e o host (sua maquina).

Tudo isso acontece em segundos, com exceção dos passos 1 e 2 :)

Quando o K1Plaza estiver pronto você verá as seguintes linhas:
```
k1plaza | Server available at http://127.0.0.1:3000
k1plaza | [info] K1Plaza started in development mode.
```

Mantenha o prompt de comando aberto enquanto trabalha.
Para desligar os containers basta apertar `CTRL+C`. Qualquer conteúdo de testes que você adicionar estará salvo para o próximo `docker-compose up`

## 3. Abrir Developer Panel

Acessar o Developer Panel:
- Docker: http://localhost:3000/.dev
- Docker Toolbox: http://192.168.99.100:3000/.dev
