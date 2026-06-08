--!strict
--> Bot simples de Discord em Luau usando Lune.

local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")

type GatewayPayload = {
	op: number,
	d: any?,
	s: number?,
	t: string?,
}

local DISCORD_API = "https://discord.com/api/v10"
local GATEWAY_URL = "wss://gateway.discord.gg/?v=10&encoding=json"
local DEFAULT_INTENTS = 33281 -- GUILDS + GUILD_MESSAGES + MESSAGE_CONTENT

local token = process.env.DISCORD_BOT_TOKEN
local commandPrefix = process.env.DISCORD_COMMAND_PREFIX or "!"
local intents = tonumber(process.env.DISCORD_INTENTS or "") or DEFAULT_INTENTS

if token == nil or token == "" then
	error("Defina DISCORD_BOT_TOKEN antes de iniciar o bot.")
end

local lastSequence: number? = nil
local heartbeatAcked = true
local running = true

local function encodeJson(value: any): string
	return serde.encode("json", value)
end

local function decodeJson(text: string): any
	return serde.decode("json", text)
end

local function sendPayload(socket: any, payload: GatewayPayload)
	socket:send(encodeJson(payload))
end

local function sendHeartbeat(socket: any)
	if not heartbeatAcked then
		warn("Heartbeat anterior não recebeu ACK; encerrando conexão para reconectar.")
		running = false
		socket:close()
		return
	end

	heartbeatAcked = false

	if lastSequence == nil then
		-- Luau não consegue manter campos nil em tabelas; enviamos null manualmente.
		socket:send('{"op":1,"d":null}')
	else
		sendPayload(socket, {
			op = 1,
			d = lastSequence,
		})
	end
end

local function startHeartbeatLoop(socket: any, intervalMs: number)
	task.spawn(function()
		local jitter = math.random()
		task.wait((intervalMs / 1000) * jitter)

		while running do
			sendHeartbeat(socket)
			task.wait(intervalMs / 1000)
		end
	end)
end

local function identify(socket: any)
	sendPayload(socket, {
		op = 2,
		d = {
			token = token,
			intents = intents,
			properties = {
				os = process.os,
				browser = "luau-lune-bot",
				device = "luau-lune-bot",
			},
		},
	})
end

local function createMessage(channelId: string, content: string)
	local response = net.request({
		url = `{DISCORD_API}/channels/{channelId}/messages`,
		method = "POST",
		headers = {
			["Authorization"] = `Bot {token}`,
			["Content-Type"] = "application/json",
		},
		body = encodeJson({
			content = content,
		}),
	})

	if not response.ok then
		warn(`Falha ao enviar mensagem ({response.statusCode} {response.statusMessage}): {response.body}`)
	end
end

local function startsWith(text: string, prefix: string): boolean
	return string.sub(text, 1, #prefix) == prefix
end

local function handleMessageCreate(message: any)
	local author = message.author
	if author ~= nil and author.bot then
		return
	end

	local content = message.content
	local channelId = message.channel_id
	if typeof(content) ~= "string" or typeof(channelId) ~= "string" then
		return
	end

	if content == commandPrefix .. "ping" then
		createMessage(channelId, "Pong! 🏓")
	elseif content == commandPrefix .. "help" then
		createMessage(channelId, `Comandos disponíveis: {commandPrefix}ping, {commandPrefix}help`)
	elseif startsWith(content, commandPrefix) then
		createMessage(channelId, `Não conheço esse comando. Use {commandPrefix}help.`)
	end
end

local function handleDispatch(eventName: string?, data: any)
	if eventName == "READY" then
		local user = data.user
		local username = if user ~= nil then user.username else "desconhecido"
		print(`Bot conectado como {username}. Prefixo: {commandPrefix}`)
	elseif eventName == "MESSAGE_CREATE" then
		handleMessageCreate(data)
	end
end

local function run()
	math.randomseed(os.time())
	print("Conectando ao Gateway do Discord...")

	local socket = net.socket(GATEWAY_URL)

	while running do
		local rawMessage = socket:next()
		if rawMessage == nil then
			break
		end

		local payload: GatewayPayload = decodeJson(rawMessage)
		if payload.s ~= nil then
			lastSequence = payload.s
		end

		if payload.op == 10 then
			local heartbeatInterval = payload.d.heartbeat_interval
			print(`Hello recebido. Heartbeat a cada {heartbeatInterval}ms.`)
			startHeartbeatLoop(socket, heartbeatInterval)
			identify(socket)
		elseif payload.op == 0 then
			handleDispatch(payload.t, payload.d)
		elseif payload.op == 1 then
			sendHeartbeat(socket)
		elseif payload.op == 7 then
			warn("Discord solicitou reconexão. Reinicie o processo para uma nova sessão simples.")
			running = false
			socket:close()
		elseif payload.op == 9 then
			warn("Sessão inválida. Confira token, intents e permissões do bot.")
			running = false
			socket:close()
		elseif payload.op == 11 then
			heartbeatAcked = true
		end
	end

	print("Conexão encerrada.")
end

run()
