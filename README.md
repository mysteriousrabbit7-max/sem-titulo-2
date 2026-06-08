# Bot de Discord em Luau

Este projeto é um bot simples de Discord escrito em **Luau** e executado com o runtime **Lune**. Ele conecta no Gateway do Discord por WebSocket, mantém heartbeats e responde a comandos de texto.

## Recursos

- Conexão WebSocket com o Gateway v10 do Discord.
- Identificação do bot com token via variável de ambiente.
- Heartbeat automático com ACK.
- Comandos básicos:
  - `!ping` responde `Pong! 🏓`
  - `!help` lista os comandos disponíveis
- Prefixo e intents configuráveis por variáveis de ambiente.
- Deploy pronto para Render usando Docker e `render.yaml`.

## Pré-requisitos

1. Instale o [Lune](https://lune-org.github.io/docs/getting-started/1-installation/) para rodar localmente.
2. Crie uma aplicação/bot no [Discord Developer Portal](https://discord.com/developers/applications).
3. Copie o token do bot.
4. Ative **Message Content Intent** na aba **Bot** do Developer Portal se quiser que comandos com prefixo funcionem em servidores.
5. Convide o bot para um servidor com permissão para ler e enviar mensagens.

## Configuração local

Defina o token do bot antes de executar:

```bash
export DISCORD_BOT_TOKEN="seu-token-aqui"
```

Opcionalmente, altere o prefixo dos comandos:

```bash
export DISCORD_COMMAND_PREFIX="!"
```

Opcionalmente, altere as intents enviadas no `IDENTIFY`:

```bash
export DISCORD_INTENTS="33281"
```

O valor padrão `33281` habilita `GUILDS`, `GUILD_MESSAGES` e `MESSAGE_CONTENT`.

## Executando localmente

```bash
lune run bot.luau
```

Depois que o bot aparecer online, envie `!ping` em um canal onde ele tenha acesso.

## Deploy no Render

Para um bot do Discord, use **Background Worker** no Render, não Web Service. O bot mantém uma conexão WebSocket aberta com o Gateway do Discord e não precisa receber tráfego HTTP.

> Observação importante: Background Worker no Render não tem plano Free. O `render.yaml` usa `plan: starter`, que é a menor opção paga para esse tipo de serviço.

### Opção 1: Blueprint com `render.yaml` (recomendado)

1. Faça push deste repositório para GitHub/GitLab/Bitbucket.
2. No Render, clique em **New** e escolha **Blueprint**.
3. Selecione o repositório deste bot.
4. O Render vai ler o arquivo `render.yaml` e criar um serviço `worker` usando Docker.
5. Quando o Render pedir as variáveis, preencha:
   - `DISCORD_BOT_TOKEN`: token real do bot.
   - `DISCORD_COMMAND_PREFIX`: opcional, padrão `!`.
   - `DISCORD_INTENTS`: opcional, padrão `33281`.
6. Clique para criar/deployar o Blueprint.
7. Abra os logs do serviço e procure uma mensagem parecida com `Bot conectado como ...`.

### Opção 2: Criar manualmente

1. No Render, clique em **New** e escolha **Background Worker**.
2. Conecte o repositório.
3. Em **Language**, escolha **Docker**.
4. Deixe o Dockerfile Path como `./Dockerfile`.
5. Não precisa definir Start Command/Docker Command: o `Dockerfile` já tem `CMD ["lune", "run", "bot.luau"]`.
6. Em **Environment**, adicione:
   - `DISCORD_BOT_TOKEN` = token real do bot.
   - `DISCORD_COMMAND_PREFIX` = `!`.
   - `DISCORD_INTENTS` = `33281`.
7. Faça deploy e acompanhe os logs.

## Tem opção melhor que Render?

Depende do que você quer:

- **Mais simples gerenciado:** Render Background Worker é uma boa opção, mas é pago para worker.
- **Mais barato/grátis:** um VPS gratuito/barato, um servidor caseiro, Oracle Cloud Always Free ou outra VM geralmente funciona melhor para bot 24/7, porque o processo pode ficar ligado sem precisar fingir ser um app web.
- **Mais robusto no futuro:** se o bot crescer muito, considere reescrever para Node.js/TypeScript com `discord.js` ou Python com `discord.py`, porque essas bibliotecas têm mais recursos prontos para Discord, incluindo slash commands, reconexão e rate limits.

Se a prioridade for manter **Luau**, a melhor arquitetura continua sendo um processo 24/7 em Docker, seja no Render Worker ou em uma VM.


## Deploy em VM/VPS pelo celular

Sim, dá para fazer tudo pelo celular. Você só precisa de:

- uma conta em um provedor de VM/VPS;
- um app de SSH no celular, como Termius, JuiceSSH ou Blink Shell;
- o link do repositório no GitHub/GitLab/Bitbucket;
- o token do bot do Discord.

### Qual VPS escolher?

Para este bot, qualquer VM Linux pequena já serve. Minha recomendação prática:

1. **Oracle Cloud Always Free** se você quer tentar grátis. A Oracle oferece recursos Always Free para Compute, incluindo Ampere A1, mas pode faltar capacidade na região escolhida e a criação da conta pode ser mais chata.
2. **DigitalOcean Droplet pequeno** se você quer o caminho mais simples. É pago, mas costuma ser fácil de criar e manter.
3. **Hetzner Cloud pequeno** se estiver disponível para você e quiser preço baixo. Também é pago.

Se você for iniciante e puder pagar pouco, eu escolheria uma VPS paga simples. Se a prioridade for grátis, tente Oracle Cloud, mas tenha paciência com disponibilidade.

### Passo a passo pelo celular

1. Crie a VM/VPS no provedor escolhido.
   - Sistema: **Ubuntu 24.04 LTS** ou **Debian 12**.
   - Tamanho: 1 vCPU e 512 MB/1 GB RAM já deve bastar para este bot.
   - Adicione uma chave SSH se o provedor pedir. Alguns apps de SSH conseguem gerar a chave no próprio celular.
2. Copie o IP público da VM.
3. Abra seu app de SSH no celular e conecte:

```bash
ssh root@IP_DA_SUA_VPS
```

4. Atualize o servidor e instale Git + Docker:

```bash
apt update && apt upgrade -y
apt install -y git ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

> Se você escolheu Debian em vez de Ubuntu, troque `linux/ubuntu` por `linux/debian` no comando da chave/repositório do Docker.

5. Baixe o projeto:

```bash
git clone LINK_DO_SEU_REPOSITORIO discord-luau-bot
cd discord-luau-bot
```

6. Crie o arquivo `.env` com seu token:

```bash
cp .env.example .env
nano .env
```

No `nano`, coloque o token real em `DISCORD_BOT_TOKEN`, salve com `CTRL+O`, `Enter` e saia com `CTRL+X`.

7. Suba o bot em segundo plano:

```bash
docker compose up -d --build
```

8. Veja os logs:

```bash
docker compose logs -f bot
```

Quando aparecer `Bot conectado como ...`, teste `!ping` no Discord.

### Comandos úteis na VPS

```bash
# Ver se o container está rodando
docker compose ps

# Reiniciar o bot
docker compose restart bot

# Parar o bot
docker compose down

# Atualizar depois de um novo commit
git pull
docker compose up -d --build
```

### Dicas importantes

- Não compartilhe seu `DISCORD_BOT_TOKEN` em print, vídeo ou mensagem.
- Ative **Message Content Intent** no Developer Portal, senão comandos como `!ping` podem não chegar ao bot.
- Use apenas **uma instância** deste bot rodando com o mesmo token. Rodar em dois lugares ao mesmo tempo pode causar comportamento estranho.
- Se a VM reiniciar, o `restart: unless-stopped` do `docker-compose.yml` faz o bot voltar automaticamente.

## Docker local

Se você tiver Docker instalado, também pode testar o mesmo ambiente usado no Render:

```bash
docker build -t luau-discord-bot .
docker run --rm -e DISCORD_BOT_TOKEN="seu-token-aqui" luau-discord-bot
```

## Segurança

Nunca coloque o token do bot diretamente no código. Use variável de ambiente ou um gerenciador de segredos. O arquivo `.gitignore` já ignora arquivos `.env` para evitar commits acidentais de credenciais.

## Observações

Este é um bot inicial para aprendizado. Para produção, adicione reconexão/resume completo, tratamento de rate limits mais avançado, logs estruturados e suporte a slash commands.
