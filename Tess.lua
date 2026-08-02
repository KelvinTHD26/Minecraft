-- ===== CONFIGURACOES =====
local NOME_IA = "Tess"
local TEMPO_PULSO = 1 -- segundos que o redstone fica ligado
local LADO_INTEGRATOR = "front" -- lado do Integrator conectado a Interface (ajustar conforme montagem)

-- ===== PERIFERICOS =====
local chatBox = peripheral.find("chatBox")
local integrator = peripheral.find("redstoneIntegrator")

if not chatBox then
    print("ERRO: Chat Box nao encontrado conectado a este computador.")
    return
end

if not integrator then
    print("ERRO: Redstone Integrator nao encontrado conectado a este computador.")
    return
end

print("=== " .. NOME_IA .. " ONLINE ===")
print("Aguardando comandos no chat...")
print("Use: " .. NOME_IA .. " limpar lixo")

-- ===== FUNCAO: LIMPAR LIXO DA CAMARA =====

local function limparLixo()
    print("Comando recebido! Limpando a camara...")
    chatBox.sendMessage(NOME_IA .. ": Limpando a camara de pressao...")

    integrator.setOutput(LADO_INTEGRATOR, true)
    sleep(TEMPO_PULSO)
    integrator.setOutput(LADO_INTEGRATOR, false)

    print("Limpeza concluida!")
    chatBox.sendMessage(NOME_IA .. ": Pronto! Camara limpa.")
end

-- ===== LOOP PRINCIPAL: OUVINDO O CHAT =====

while true do
    local event, username, message = os.pullEvent("chat")

    local mensagemLower = message:lower()
    local nomeLower = NOME_IA:lower()

    if mensagemLower:sub(1, #nomeLower) == nomeLower then
        local comando = mensagemLower:sub(#nomeLower + 1):gsub("^%s+", "")

        print("Comando de " .. username .. ": " .. comando)

        if comando == "limpar lixo" then
            limparLixo()
        else
            chatBox.sendMessage(NOME_IA .. ": Comando nao reconhecido. Tente: 'limpar lixo'")
        end
    end
end