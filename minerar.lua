-- ========================================
-- MINERADORA COM GEO SCANNER
-- ========================================

-- ===== CONFIGURACOES =====
local RAIO_SCAN = 8
local DISTANCIA_MAXIMA_ORIGEM = 25 -- nao persegue minerio alem disso (evita viagens longas ineficientes)
local FUEL_MINIMO_EMERGENCIA = 150
local FUEL_RESERVA_RETORNO = 100 -- fuel minimo que sempre reserva pra garantir volta

local mapaMinerios = {
    ["1"] = {nome = "Diamante", ids = {"minecraft:diamond_ore", "minecraft:deepslate_diamond_ore"}},
    ["2"] = {nome = "Ouro", ids = {"minecraft:gold_ore", "minecraft:deepslate_gold_ore"}},
    ["3"] = {nome = "Redstone", ids = {"minecraft:redstone_ore", "minecraft:deepslate_redstone_ore"}},
    ["4"] = {nome = "Lapis Lazuli", ids = {"minecraft:lapis_ore", "minecraft:deepslate_lapis_ore"}},
    ["5"] = {nome = "Carvao", ids = {"minecraft:coal_ore", "minecraft:deepslate_coal_ore"}},
}

local itensCombustivel = {
    "minecraft:coal",
    "minecraft:coal_ore",
    "minecraft:deepslate_coal_ore",
}

local dropsMinerio = {
    "minecraft:redstone",
    "minecraft:diamond",
    "minecraft:lapis_lazuli",
    "minecraft:raw_gold",
}

-- ===== ESTADO GLOBAL =====
local posX, posY, posZ, direcao = 0, 0, 0, 0
local idsProcurados = {}
local listaAlvos = {}
local visitados = {}

-- ===== MENU =====

local function menu()
    print("=== MINERADORA COM GEO SCANNER ===")
    print("Fuel atual: " .. turtle.getFuelLevel())
    print("")
    print("Quais minerios procurar? (recomendado: 1 ou 2 por vez)")
    print("1-Diamante  2-Ouro  3-Redstone  4-Lapis  5-Carvao")
    print("Digite os numeros separados por virgula (ex: 1,2):")
    local escolha = read()

    for numero in escolha:gmatch("%d") do
        if mapaMinerios[numero] then
            for _, id in ipairs(mapaMinerios[numero].ids) do
                table.insert(idsProcurados, id)
            end
        end
    end

    if #idsProcurados == 0 then
        print("Nenhum minerio valido selecionado. Encerrando.")
        return false
    end

    print("Quantos blocos descer antes de comecar? (0 se ja estiver na profundidade certa)")
    local profundidade = tonumber(read()) or 0

    if turtle.getFuelLevel() < 300 then
        print("AVISO: fuel baixo (" .. turtle.getFuelLevel() .. "). Recomendado 500+.")
        print("Continuar mesmo assim? (s/n)")
        if (read() or ""):lower() ~= "s" then
            print("Cancelado.")
            return false
        end
    end

    return true, profundidade
end

-- ===== PERIFERICO =====
local geoScanner = peripheral.wrap("right")

-- ===== FUNCOES DE ITEM =====

local function ehCombustivel(nome)
    for _, item in ipairs(itensCombustivel) do
        if nome == item then return true end
    end
    return false
end

local function ehItemParaGuardar(nome)
    for _, id in ipairs(idsProcurados) do
        if nome == id then return true end
    end
    for _, d in ipairs(dropsMinerio) do
        if nome == d then return true end
    end
    return false
end

-- reabastece devagar, so o minimo necessario, preservando o resto do carvao coletado
local function verificarFuel()
    if turtle.getFuelLevel() >= FUEL_MINIMO_EMERGENCIA then return end
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and ehCombustivel(item.name) then
            while turtle.getFuelLevel() < FUEL_MINIMO_EMERGENCIA and turtle.getItemCount(slot) > 0 do
                turtle.refuel(1)
            end
        end
        if turtle.getFuelLevel() >= FUEL_MINIMO_EMERGENCIA then break end
    end
    turtle.select(1)
end

local function descartarLixo()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and not (ehCombustivel(item.name) or ehItemParaGuardar(item.name)) then
            turtle.drop()
        end
    end
    turtle.select(1)
end

-- ===== MOVIMENTO =====

local function virarDireita()
    turtle.turnRight()
    direcao = (direcao + 1) % 4
end

local function virarEsquerda()
    turtle.turnLeft()
    direcao = (direcao - 1) % 4
end

-- gira pelo caminho mais curto (nunca mais de 2 giros)
local function orientarPara(dirAlvo)
    local diferenca = (dirAlvo - direcao) % 4
    if diferenca == 1 then virarDireita()
    elseif diferenca == 2 then virarDireita() virarDireita()
    elseif diferenca == 3 then virarEsquerda()
    end
end

local function avancar()
    verificarFuel()
    local t = 0
    while turtle.detect() and t < 15 do turtle.dig() sleep(0.2) t = t + 1 end
    t = 0
    while not turtle.forward() and t < 15 do
        if turtle.detect() then turtle.dig() end
        sleep(0.2)
        t = t + 1
    end
    if t >= 15 then return false end

    if direcao == 0 then posZ = posZ + 1
    elseif direcao == 1 then posX = posX + 1
    elseif direcao == 2 then posZ = posZ - 1
    elseif direcao == 3 then posX = posX - 1
    end
    descartarLixo()
    return true
end

local function subir()
    verificarFuel()
    local t = 0
    while turtle.detectUp() and t < 15 do turtle.digUp() sleep(0.2) t = t + 1 end
    t = 0
    while not turtle.up() and t < 15 do sleep(0.2) t = t + 1 end
    if t >= 15 then return false end
    posY = posY + 1
    return true
end

local function descer()
    verificarFuel()
    local t = 0
    while turtle.detectDown() and t < 15 do turtle.digDown() sleep(0.2) t = t + 1 end
    t = 0
    while not turtle.down() and t < 15 do sleep(0.2) t = t + 1 end
    if t >= 15 then return false end
    posY = posY - 1
    return true
end

-- move ate as coordenadas (Y primeiro, depois Z, depois X)
local function irPara(destX, destY, destZ)
    while posY < destY do if not subir() then return false end end
    while posY > destY do if not descer() then return false end end

    if posZ ~= destZ then
        orientarPara(posZ < destZ and 0 or 2)
        for i = 1, math.abs(destZ - posZ) do
            if not avancar() then return false end
        end
    end

    if posX ~= destX then
        orientarPara(posX < destX and 1 or 3)
        for i = 1, math.abs(destX - posX) do
            if not avancar() then return false end
        end
    end

    return true
end

-- ===== RETORNO SEGURO A ORIGEM =====

local function voltarParaOrigem()
    print("Retornando... posicao: X=" .. posX .. " Y=" .. posY .. " Z=" .. posZ)
    local ok = irPara(0, 0, 0)
    local tentativas = 0
    while not ok and tentativas < 3 do
        print("Obstaculo no caminho de volta, tentando novamente...")
        sleep(1)
        ok = irPara(0, 0, 0)
        tentativas = tentativas + 1
    end
    orientarPara(0)

    if posX == 0 and posY == 0 and posZ == 0 then
        print("Retorno confirmado com sucesso!")
    else
        print("ATENCAO: turtle presa fora da origem. Posicao: X=" .. posX .. " Y=" .. posY .. " Z=" .. posZ)
        print("Verifique manualmente - pode haver bloco indestrutivel no caminho.")
    end
end

local function descarregarNaOrigem()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and not ehCombustivel(item.name) then
            turtle.drop()
        end
    end
    turtle.select(1)
end

-- ===== ESCANEAMENTO =====

local function chaveDe(x, y, z) return x .. "," .. y .. "," .. z end

local function distanciaDaOrigem(x, y, z)
    return math.abs(x) + math.abs(y) + math.abs(z)
end

local function escanear()
    local ok, resultado = pcall(function() return geoScanner.scan(RAIO_SCAN) end)
    if not ok or not resultado then return 0 end

    local novos = 0
    for _, bloco in ipairs(resultado) do
        for _, id in ipairs(idsProcurados) do
            if bloco.name == id then
                local ax, ay, az = posX + bloco.x, posY + bloco.y, posZ + bloco.z
                local chave = chaveDe(ax, ay, az)

                -- ignora minerio longe demais da origem (evita viagem ineficiente)
                if not visitados[chave] and distanciaDaOrigem(ax, ay, az) <= DISTANCIA_MAXIMA_ORIGEM then
                    local existe = false
                    for _, a in ipairs(listaAlvos) do
                        if a.x == ax and a.y == ay and a.z == az then existe = true break end
                    end
                    if not existe then
                        table.insert(listaAlvos, {x = ax, y = ay, z = az})
                        novos = novos + 1
                    end
                end
            end
        end
    end
    return novos
end

local function pegarMaisProximo()
    if #listaAlvos == 0 then return nil end
    local idx, menorDist = nil, math.huge
    for i, a in ipairs(listaAlvos) do
        local d = math.abs(a.x - posX) + math.abs(a.y - posY) + math.abs(a.z - posZ)
        if d < menorDist then menorDist = d idx = i end
    end
    return table.remove(listaAlvos, idx)
end

-- calcula quanto de fuel custaria voltar da posicao atual pra origem
local function custoRetorno()
    return math.abs(posX) + math.abs(posY) + math.abs(posZ)
end

-- ===== PROGRAMA PRINCIPAL =====

local podeIniciar, profundidade = menu()
if not podeIniciar then return end

if not geoScanner then
    print("ERRO: Geo Scanner nao encontrado no lado direito da turtle.")
    return
end

if profundidade > 0 then
    print("Descendo " .. profundidade .. " blocos...")
    for i = 1, profundidade do
        if not descer() then
            print("Bloqueada na descida. Parando em Y=" .. posY)
            break
        end
    end
end

print("Iniciando escaneamento e mineracao...")
local semAchar = 0

while semAchar < 3 do
    -- seguranca: se o fuel mal da pra voltar, aborta AGORA
    if turtle.getFuelLevel() < custoRetorno() + FUEL_RESERVA_RETORNO then
        print("Fuel insuficiente para continuar com seguranca. Voltando...")
        break
    end

    if #listaAlvos == 0 then
        print("Escaneando (Y=" .. posY .. ")...")
        local novos = escanear()
        if novos == 0 then
            semAchar = semAchar + 1
            print("Nada encontrado. (" .. semAchar .. "/3)")
            sleep(1)
        else
            print(novos .. " minerio(s) encontrado(s)! Total na fila: " .. #listaAlvos)
            semAchar = 0
        end
    else
        local alvo = pegarMaisProximo()
        print("Indo ate X=" .. alvo.x .. " Y=" .. alvo.y .. " Z=" .. alvo.z .. " (fila: " .. #listaAlvos .. ")")
        local chegou = irPara(alvo.x, alvo.y, alvo.z)
        visitados[chaveDe(alvo.x, alvo.y, alvo.z)] = true
        if not chegou then
            print("Bloqueado, indo para o proximo...")
        end
    end
end

print("")
print("Busca encerrada. Retornando para a origem...")
voltarParaOrigem()
descarregarNaOrigem()

print("")
print("=== MISSAO CONCLUIDA ===")
print("Fuel restante: " .. turtle.getFuelLevel())