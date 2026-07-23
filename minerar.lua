print("Quantos blocos deseja minerar?")
local distancia = tonumber(read())

print("Iniciando mineracao de " .. distancia .. " blocos...")

for i = 1, distancia do
    -- minera o bloco na frente, se tiver algo
    if turtle.detect() then
        turtle.dig()
    end
    
    -- anda pra frente
    turtle.forward()
    
    -- minera acima e abaixo também (túnel 1x3)
    if turtle.detectUp() then
        turtle.digUp()
    end
    if turtle.detectDown() then
        turtle.digDown()
    end
end

print("Mineracao concluida!")