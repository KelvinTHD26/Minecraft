-- ===== CONFIGURACOES =====
local distanciaTotal = 0
local passosAndados = 0

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

print("Quantos blocos deseja minerar?")
distanciaTotal = tonumber(read())

-- ===== FUNCOES =====

local function verificarFuel()
    if turtle.getFuelLevel() < (distanciaTotal * 2 + 10) then
        print("Fuel baixo, tentando reabastecer...")
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then
                turtle.refuel()
                print("Reabastecido! Fuel atual: " .. turtle.getFuelLevel())
                turtle.select(1)
                return true
            end
        end
        print("SEM COMBUSTIVEL SUFICIENTE! Abortando.")
        turtle.select(1)
        return false
    end
    return true
end

local function descartarLixo()
    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item then
            local guardar = false
            for _, nome in ipairs(itensParaGuardar) do
                if item.name == nome then
                    guardar = true
                    break
                end
            end
            if not guardar then
                turtle.drop()
            end
        end
    end
    turtle.select(1)
end

local function inventarioCheio()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end

local function ehCombustivel(nome)
    for _, item in ipairs(itensCombustivel) do
        if nome == item then
            return true
        end
    end
    return false
end

local function voltarParaBase()
    print("Voltando para descarregar...")
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, passosAndados do
        turtle.forward()
    end

    for slot = 1, 16 do
        turtle.select(slot)
        local item = turtle.getItemDetail()
        if item and not ehCombustivel(item.name) then
            turtle.drop()
        end
    end
    turtle.select(1)

    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, passosAndados do
        turtle.forward()
    end
    print("Retomando mineracao...")
end

local function avancarSeguro()
    local tentativas = 0
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
        end
        tentativas = tentativas + 1
        if tentativas > 5 then
            print("Bloqueado! Nao consigo avancar.")
            return false
        end
        sleep(0.3)
    end
    passosAndados = passosAndados + 1
    return true
end

-- ===== LOOP PRINCIPAL =====

print("Iniciando mineracao de " .. distanciaTotal .. " blocos...")

for i = 1, distanciaTotal do
    if not verificarFuel() then break end

    if turtle.detect() then turtle.dig() end
    if turtle.detectUp() then turtle.digUp() end
    if turtle.detectDown() then turtle.digDown() end

    if not avancarSeguro() then break end

    descartarLixo()

    if inventarioCheio() then
        voltarParaBase()
    end
end

print("Mineracao concluida! Total de blocos andados: " .. passosAndados)