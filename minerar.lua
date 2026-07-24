-- ===== CONFIGURACOES =====
local RAIO_SCAN = 8
local FUEL_MINIMO_EMERGENCIA = 100
local FUEL_ABORTAR_BUSCA = 50

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

-- ===== MENU DE ESCOLHA =====

print("=== MINERADORA INTELIGENTE ===")
print("Fuel atual: " .. turtle.getFuelLevel())
print("")
print("Quais minerios voce quer procurar? (recomendado: 1 ou 2 por vez)")
print("1 - Diamante")
print("2 - Ouro")
print("3 - Redstone")
print("4 - Lapis Lazuli")
print("5 - Carvao")
print("Digite os numeros separados por virgula (ex: 1,2):")
local escolha = read()

local idsProcurados = {}
for numero in escolha:gmatch("%d") do
    if mapaMinerios[numero] then
        for _, id in ipairs(mapaMinerios[numero].ids) do
            table.insert(idsProcurados, id)
        end
    end
end

if #idsProcurados == 0 then
    print("Nenhum minerio valido selecionado. Encerrando.")
    return
end

print("Quantos blocos deseja descer antes de comecar a escanear?")
print("(digite 0 se ja estiver na profundidade certa)")
local profundidadeDescer = tonumber(read()) or 0

if turtle.getFuelLevel() < 200 then
    print("AVISO: fuel inicial baixo (" .. turtle.getFuelLevel() .. "). Recomendado ter pelo menos 500+.")
    print("Deseja continuar mesmo assim? (s/n)")
    local resp = read()
    if resp ~= "s" and resp ~= "S" then
        print("Cancelado.")
        return
    end
end

-- ===== POSICAO E DIRECAO (0,0,0 = onde ela comecou, na superficie) =====
local posX, posY, posZ, direcao = 0, 0, 0, 0

-- ===== PERIFERICO =====
local geoScanner = peripheral.wrap("right")
if not geoScanner then
    print("ERRO: Geo Scanner nao encontrado no lado direito.")
    return
end

-- ===== FUNCOES BASICAS =====

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
        if item then
            local guardar = ehCombustivel(item.name) or ehItemParaGuardar(item.name)
            if not guardar then turtle.drop() end
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

local function orientarPara(dirAlvo)
    local diferenca = (dirAlvo - direcao) % 4
    if diferenca == 0 then return
    elseif diferenca == 1 then virarDireita()
    elseif diferenca == 2 then virarDireita() virarDireita()
    elseif diferenca == 3 then virarEsquerda()
    end
end

local function avancar()
    verificarFuel()
    local tentativas = 0
    while turtle.detect() and tentativas < 20 do
        turtle.dig()
        sleep(0.3)
        tentativas = tentativas + 1
    end
    tentativas = 0
    while not turtle.forward() and tentativas < 20 do
        if turtle.detect() then turtle.dig() end
        sleep(0.3)
        tentativas = tentativas + 1
    end
    if tentativas >= 20 then return false end
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
    local tentativas = 0
    while turtle.detectUp() and tentativas < 20 do
        turtle.digUp()
        sleep(0.3)
        tentativas = tentativas + 1
    end
    tentativas = 0
    while not turtle.up() and tentativas < 20 do
        sleep(0.3)
        tentativas = tentativas + 1
    end
    if tentativas >= 20 then return false end
    posY = posY + 1
    return true
end

local function descer()
    verificarFuel()
    local tentativas = 0
    while turtle.detectDown() and tentativas < 20 do
        turtle.digDown()
        sleep(0.3)
        tentativas = tentativas + 1
    end
    tentativas = 0
    while not turtle.down() and tentativas < 20 do
        sleep(0.3)
        tentativas = tentativas + 1
    end
    if tentativas >= 20 then return false end
    posY = posY - 1
    return true
end

local function irPara(destX, destY, destZ)
    while posY < destY do if not subir() then return false end end
    while posY > destY do if not descer() then return false end end

    if posZ < destZ then
        orientarPara(0)
        for i = 1, destZ - posZ do if not avancar() then return false end end
    elseif posZ > destZ then
        orientarPara(2)
        for i = 1, posZ - destZ do if not avancar() then return false end end
    end

    if posX < destX then
        orientarPara(1)
        for i = 1, destX - posX do if not avancar() then return false end end
    elseif posX > destX then
        orientarPara(3)
        for i = 1, posX - destX do if not avancar() then return false end end
    end

    return true
end

-- ===== RETORNO A ORIGEM (superficie) =====

local function voltarParaOrigem()
    print("Voltando para a superficie... posicao atual: X=" .. posX .. " Y=" .. posY .. " Z=" .. posZ)
    local sucesso = irPara(0, 0, 0)
    if not sucesso then
        print("AVISO: obstaculo impediu retorno total. Tentando novamente...")
        sleep(1)
        sucesso = irPara(0, 0, 0)
    end
    orientarPara(0)
    if posX == 0 and posY == 0 and posZ == 0 then
        print("Chegou na superficie com sucesso!")
    else
        print("ATENCAO: retorno incompleto. Posicao final: X=" .. posX .. " Y=" .. posY .. " Z=" .. posZ)
    end
    return sucesso
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

-- ===== ESCANEAMENTO E FILA DE ALVOS =====

local listaAlvos = {}
local visitados = {}

local function chaveDe(x, y, z)
    return x .. "," .. y .. "," .. z
end

local function escanearEAdicionar()
    local ok, resultado = pcall(function() return geoScanner.scan(RAIO_SCAN) end)
    if not ok or not resultado then return 0 end

    local novos = 0
    for _, bloco in ipairs(resultado) do
        for _, id in ipairs(idsProcurados) do
            if bloco.name == id then
                local ax = posX + bloco.x
                local ay = posY + bloco.y
                local az = posZ + bloco.z
                local chave = chaveDe(ax, ay, az)

                if not visitados[chave] then
                    local jaNaLista = false
                    for _, alvo in ipairs(listaAlvos) do
                        if alvo.x == ax and alvo.y == ay and alvo.z == az then
                            jaNaLista = true
                            break
                        end
                    end
                    if not jaNaLista then
                        table.insert(listaAlvos, {x = ax, y = ay, z = az})
                        novos = novos + 1
                    end
                end
            end
        end
    end
    return novos
end

local function pegarAlvoMaisProximo()
    if #listaAlvos == 0 then return nil end
    local indiceMaisProximo = nil
    local menorDistancia = math.huge
    for i, alvo in ipairs(listaAlvos) do
        local dist = math.abs(alvo.x - posX) + math.abs(alvo.y - posY) + math.abs(alvo.z - posZ)
        if dist < menorDistancia then
            menorDistancia = dist
            indiceMaisProximo = i
        end
    end
    return table.remove(listaAlvos, indiceMaisProximo)
end

-- ===== DESCIDA INICIAL =====

if profundidadeDescer > 0 then
    print("Descendo " .. profundidadeDescer .. " blocos antes de comecar...")
    for i = 1, profundidadeDescer do
        if not descer() then
            print("Bloqueada durante a descida! Parando na profundidade atual (Y=" .. posY .. ")")
            break
        end
    end
    print("Chegou na profundidade Y=" .. posY .. ". Iniciando escaneamento...")
end

-- ===== LOOP PRINCIPAL =====

print("Iniciando busca por minerios...")

local semAcharNada = 0

while semAcharNada < 3 do
    if turtle.getFuelLevel() < FUEL_ABORTAR_BUSCA then
        print("Fuel critico! Abortando busca e voltando...")
        break
    end

    if #listaAlvos == 0 then
        print("Escaneando area...")
        local novos = escanearEAdicionar()
        if novos == 0 then
            semAcharNada = semAcharNada + 1
            print("Nada novo encontrado. (" .. semAcharNada .. "/3)")
            sleep(1)
        else
            print(novos .. " minerio(s) novo(s) encontrado(s)! Fila: " .. #listaAlvos)
            semAcharNada = 0
        end
    else
        local alvo = pegarAlvoMaisProximo()
        local chave = chaveDe(alvo.x, alvo.y, alvo.z)
        print("Indo ate X=" .. alvo.x .. " Y=" .. alvo.y .. " Z=" .. alvo.z .. " (fila: " .. #listaAlvos .. ")")
        local chegou = irPara(alvo.x, alvo.y, alvo.z)
        visitados[chave] = true
        if not chegou then
            print("Bloqueado, pulando para o proximo alvo...")
        else
            escanearEAdicionar()
        end
    end
end

print("Busca finalizada. Retornando para a superficie...")
voltarParaOrigem()
descarregarNaOrigem()

print("Turtle de volta na superficie! Missao concluida.")
print("Fuel restante: " .. turtle.getFuelLevel())