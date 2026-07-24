-- ===== CONFIGURACOES =====
local RAIO_SCAN = 8

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

-- ===== MENU DE ESCOLHA =====

print("Quais minerios voce quer procurar?")
print("1 - Diamante")
print("2 - Ouro")
print("3 - Redstone")
print("4 - Lapis Lazuli")
print("5 - Carvao")
print("Digite os numeros separados por virgula (ex: 1,2,4) ou 'todos':")
local escolha = read()

local idsProcurados = {}
if escolha == "todos" then
    for _, item in pairs(mapaMinerios) do
        for _, id in ipairs(item.ids) do table.insert(idsProcurados, id) end
    end
else
    for numero in escolha:gmatch("%d") do
        if mapaMinerios[numero] then
            for _, id in ipairs(mapaMinerios[numero].ids) do
                table.insert(idsProcurados, id)
            end
        end
    end
end

if #idsProcurados == 0 then
    print("Nenhum minerio valido selecionado. Encerrando.")
    return
end

-- ===== POSICAO E DIRECAO =====
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

local function verificarFuel()
    if turtle.getFuelLevel() < 200 then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then turtle.refuel() end
        end
        turtle.select(1)
    end
end

local function descartarLixo()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            local guardar = ehCombustivel(item.name)
            for _, id in ipairs(idsProcurados) do
                if item.name == id then guardar = true end
            end
            local drops = {"minecraft:redstone","minecraft:diamond","minecraft:lapis_lazuli","minecraft:raw_gold"}
            for _, d in ipairs(drops) do
                if item.name == d then guardar = true end
            end
            if not guardar then turtle.drop() end
        end
    end
    turtle.select(1)
end

-- ===== MOVIMENTO COM RASTREAMENTO DE POSICAO =====
-- IMPORTANTE: essas funcoes so atualizam posX/posY/posZ/direcao QUANDO
-- o movimento realmente da certo. Isso garante que a posicao salva
-- sempre reflita a posicao real da turtle, essencial pro retorno funcionar.

local function virarDireita()
    turtle.turnRight()
    direcao = (direcao + 1) % 4
end

local function virarEsquerda()
    turtle.turnLeft()
    direcao = (direcao - 1) % 4
end

local function orientarPara(dirAlvo)
    local tentativas = 0
    while direcao ~= dirAlvo and tentativas < 4 do
        virarDireita()
        tentativas = tentativas + 1
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
    if tentativas >= 20 then
        return false -- nao conseguiu avancar, evita loop infinito
    end
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

-- vai da posicao atual ate as coordenadas absolutas (relativas a origem 0,0,0)
-- retorna true se conseguiu chegar, false se travou em algum ponto
local function irPara(destX, destY, destZ)
    while posY < destY do
        if not subir() then return false end
    end
    while posY > destY do
        if not descer() then return false end
    end

    if posZ < destZ then
        orientarPara(0)
        for i = 1, destZ - posZ do
            if not avancar() then return false end
        end
    elseif posZ > destZ then
        orientarPara(2)
        for i = 1, posZ - destZ do
            if not avancar() then return false end
        end
    end

    if posX < destX then
        orientarPara(1)
        for i = 1, destX - posX do
            if not avancar() then return false end
        end
    elseif posX > destX then
        orientarPara(3)
        for i = 1, posX - destX do
            if not avancar() then return false end
        end
    end

    return true
end

-- ===== RETORNO A ORIGEM (funcao critica, chamada varias vezes) =====

local function voltarParaOrigem()
    print("Voltando para a origem... posicao atual: X=" .. posX .. " Y=" .. posY .. " Z=" .. posZ)
    local sucesso = irPara(0, 0, 0)
    if not sucesso then
        print("AVISO: obstaculo impediu retorno total. Tentando novamente...")
        sleep(1)
        sucesso = irPara(0, 0, 0)
    end
    orientarPara(0)
    if posX == 0 and posY == 0 and posZ == 0 then
        print("Chegou na origem com sucesso!")
    else
        print("ATENCAO: nao foi possivel confirmar retorno exato. Posicao: X=" .. posX .. " Y=" .. posY .. " Z=" .. posZ)
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

-- ===== ESCANEAMENTO =====

local function encontrarMinerioMaisProximo()
    local ok, resultado = pcall(function() return geoScanner.scan(RAIO_SCAN) end)
    if not ok or not resultado then return nil end

    local maisProximo = nil
    local menorDistancia = math.huge

    for _, bloco in ipairs(resultado) do
        for _, id in ipairs(idsProcurados) do
            if bloco.name == id then
                local dist = math.abs(bloco.x) + math.abs(bloco.y) + math.abs(bloco.z)
                if dist < menorDistancia then
                    menorDistancia = dist
                    maisProximo = bloco
                end
            end
        end
    end

    return maisProximo
end

-- ===== LOOP PRINCIPAL =====

print("Iniciando busca por minerios...")
print("Fuel atual: " .. turtle.getFuelLevel())

local semAchar = 0
local rodando = true

while rodando and semAchar < 3 do
    -- checagem de seguranca: se fuel ficar muito baixo, aborta e volta
    if turtle.getFuelLevel() < 50 then
        print("Fuel critico! Abortando busca e voltando...")
        break
    end

    local alvo = encontrarMinerioMaisProximo()

    if alvo then
        semAchar = 0
        print("Minerio encontrado! Indo ate ele...")
        local chegou = irPara(posX + alvo.x, posY + alvo.y, posZ + alvo.z)
        if not chegou then
            print("Nao conseguiu chegar no minerio, tentando outro...")
        end
    else
        semAchar = semAchar + 1
        print("Nada por perto, tentando de novo... (" .. semAchar .. "/3)")
        sleep(1)
    end
end

print("Busca finalizada. Retornando para a origem...")
voltarParaOrigem()
descarregarNaOrigem()

print("Turtle de volta na origem! Missao concluida.")