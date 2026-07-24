-- ===== CONFIGURACOES =====
local LARGURA = 15
local COMPRIMENTO = 15
local profundidade = 0

local itensParaGuardar = {
    "minecraft:redstone",
    "minecraft:lapis_lazuli",
    "minecraft:raw_gold",
    "minecraft:gold_ore",
    "minecraft:deepslate_gold_ore",
    "minecraft:diamond",
    "minecraft:coal",
    "minecraft:coal_ore",
    "minecraft:deepslate_coal_ore",
}

local itensCombustivel = {
    "minecraft:coal",
    "minecraft:coal_ore",
    "minecraft:deepslate_coal_ore",
}

-- posicao relativa ao ponto de partida (0,0,0) e direcao (0=frente original,1=direita,2=tras,3=esquerda)
local posX, posY, posZ, direcao = 0, 0, 0, 0

print("Quantas camadas de profundidade escavar? (cada camada = 2 blocos de altura)")
profundidade = tonumber(read())

-- ===== FUNCOES BASICAS =====

local function ehCombustivel(nome)
    for _, item in ipairs(itensCombustivel) do
        if nome == item then return true end
    end
    return false
end

local function verificarFuel(minimo)
    if turtle.getFuelLevel() < minimo then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then turtle.refuel() end
        end
        turtle.select(1)
        if turtle.getFuelLevel() < minimo then
            print("AVISO: fuel baixo (" .. turtle.getFuelLevel() .. ")")
        end
    end
end

local function descartarLixo()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            local guardar = false
            for _, nome in ipairs(itensParaGuardar) do
                if item.name == nome then guardar = true break end
            end
            if not guardar then turtle.drop() end
        end
    end
    turtle.select(1)
end

local function inventarioCheio()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then return false end
    end
    return true
end

-- ===== MOVIMENTO COM RASTREAMENTO DE POSICAO =====

local function virarDireita()
    turtle.turnRight()
    direcao = (direcao + 1) % 4
end

local function virarEsquerda()
    turtle.turnLeft()
    direcao = (direcao - 1) % 4
end

local function orientarPara(dirAlvo)
    while direcao ~= dirAlvo do virarDireita() end
end

local function avancar()
    while turtle.detect() do turtle.dig() sleep(0.3) end
    while not turtle.forward() do
        if turtle.detect() then turtle.dig() end
        sleep(0.3)
    end
    if direcao == 0 then posZ = posZ + 1
    elseif direcao == 1 then posX = posX + 1
    elseif direcao == 2 then posZ = posZ - 1
    elseif direcao == 3 then posX = posX - 1
    end
    if turtle.detectUp() then turtle.digUp() end
    descartarLixo()
end

local function subir()
    while turtle.detectUp() do turtle.digUp() end
    while not turtle.up() do sleep(0.3) end
    posY = posY + 1
end

local function descer()
    while turtle.detectDown() do turtle.digDown() end
    while not turtle.down() do sleep(0.3) end
    posY = posY - 1
end

-- vai da posicao atual ate as coordenadas (destX, destY, destZ)
local function irPara(destX, destY, destZ)
    while posY < destY do subir() end
    while posY > destY do descer() end

    if posZ < destZ then
        orientarPara(0)
        for i = 1, destZ - posZ do avancar() end
    elseif posZ > destZ then
        orientarPara(2)
        for i = 1, posZ - destZ do avancar() end
    end

    if posX < destX then
        orientarPara(1)
        for i = 1, destX - posX do avancar() end
    elseif posX > destX then
        orientarPara(3)
        for i = 1, posX - destX do avancar() end
    end
end

-- ===== DESCARREGAR NO BAU DE ORIGEM =====

local function irDescarregarERetornar()
    local sx, sy, sz, sdir = posX, posY, posZ, direcao
    irPara(0, 0, 0)
    orientarPara(0)
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and not ehCombustivel(item.name) then
            turtle.drop()
        end
    end
    turtle.select(1)
    irPara(sx, sy, sz)
    orientarPara(sdir)
end

-- ===== ESCAVACAO DE UMA CAMADA (15x15, em zigue-zague) =====

local function escavarCamada()
    local indoDireita = true
    for linha = 1, COMPRIMENTO do
        for coluna = 1, LARGURA - 1 do
            avancar()
            verificarFuel(300)
            if inventarioCheio() then
                print("Inventario cheio, indo descarregar...")
                irDescarregarERetornar()
                print("Retomando escavacao...")
            end
        end
        if linha < COMPRIMENTO then
            if indoDireita then
                virarDireita(); avancar(); virarDireita()
            else
                virarEsquerda(); avancar(); virarEsquerda()
            end
            indoDireita = not indoDireita
        end
    end
end

-- ===== LOOP PRINCIPAL =====

print("Iniciando escavacao da chunk (15x15), " .. profundidade .. " camadas de profundidade...")
print("Fuel atual: " .. turtle.getFuelLevel())

for camada = 1, profundidade do
    print("Camada " .. camada .. " de " .. profundidade)
    escavarCamada()
    if camada < profundidade then
        descer()
        descer()
    end
end

print("Escavacao concluida! Retornando a origem...")
irPara(0, 0, 0)
orientarPara(0)

for slot = 1, 16 do
    turtle.select(slot)
    turtle.drop()
end
turtle.select(1)

print("Turtle de volta! Escavacao da chunk finalizada.")