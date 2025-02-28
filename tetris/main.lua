function love.load()
    blockSize = 30
    gridWidth = 10
    gridHeight = 20
    grid = {}
    
    colors = {
        {1, 0, 0},    -- czerwony
        {0, 1, 0},    -- zielony
        {0, 0, 1},    -- niebieski
        {1, 1, 0},    -- żółty
        {1, 0, 1},    -- magenta
        {0, 1, 1},    -- cyjan
        {1, 0.5, 0}   -- pomarańczowy
    }
    
    -- pusta siatki
    for y = 1, gridHeight do
        grid[y] = {}
        for x = 1, gridWidth do
            grid[y][x] = 0
        end
    end
    
    -- Definicje tetrisków
    tetrominoes = {
        -- I
        {
            {1,1,1,1}
        },
        -- L
        {
            {1,0},
            {1,0},
            {1,1}
        },
        -- Kwadrat
        {
            {1,1},
            {1,1}
        },
        -- T
        {
            {1,1,1},
            {0,1,0}
        }
    }
    
    -- Aktualny klocek
    currentPiece = {
        shape = nil,
        x = 4,
        y = 1,
        color = nil
    }
    
    spawnNewPiece()
    
    fallTimer = 0
    fallSpeed = 0.5  -- Czas między kolejnymi spadkami
    moveTimer = 0
    moveSpeed = 0.15  -- Czas między kolejnymi ruchami w bok
    
    -- System powiadomień
    notification = {
        text = "",
        timer = 0,
        duration = 2 
    }
    
    -- dźwięki
    sounds = {
        rotate = love.audio.newSource("sounds/rotate.wav", "static"),
        move = love.audio.newSource("sounds/move.wav", "static"),
        drop = love.audio.newSource("sounds/drop.wav", "static"),
        clear = love.audio.newSource("sounds/clear.wav", "static")
    }
    
    -- animacje
    animation = {
        lines = {},  -- linie do animacji
        timer = 0,
        duration = 0.3  -- czas trwania animacji w sekundach
    }
end

function love.update(dt)
    -- ruch w bok
    moveTimer = moveTimer + dt
    if moveTimer >= moveSpeed then
        if love.keyboard.isDown('left') then
            movePiece(-1, 0)
            moveTimer = 0
        elseif love.keyboard.isDown('right') then
            movePiece(1, 0)
            moveTimer = 0
        end
    end

    -- opadanie
    if love.keyboard.isDown('down') then
        fallSpeed = 0.05  -- Szybsze opadanie przy strzałce w dół
    else
        fallSpeed = 0.5   -- Normalna prędkość
    end

    -- opadanie
    fallTimer = fallTimer + dt
    if fallTimer >= fallSpeed then
        fallTimer = 0
        if not movePiece(0, 1) then
            lockPiece()
            spawnNewPiece()
        end
    end

    updateNotification(dt)
    updateAnimation(dt)
end

function love.draw()
    -- Rysowanie siatki
    for y = 1, gridHeight do
        for x = 1, gridWidth do
            love.graphics.rectangle('line', 
                (x-1) * blockSize, 
                (y-1) * blockSize, 
                blockSize, 
                blockSize)
            
            if grid[y][x] ~= 0 then
                -- czy linia jest animowana
                local isAnimated = false
                for _, animY in ipairs(animation.lines) do
                    if y == animY then
                        isAnimated = true
                        break
                    end
                end
                
                if isAnimated then
                    -- migotki
                    local alpha = math.abs(math.sin(animation.timer * 20))
                    love.graphics.setColor(1, 1, 1, alpha)
                else
                    love.graphics.setColor(grid[y][x][2])
                end
                
                love.graphics.rectangle('fill',
                    (x-1) * blockSize,
                    (y-1) * blockSize,
                    blockSize,
                    blockSize)
                love.graphics.setColor(1, 1, 1)
            end
        end
    end
    
    -- aktualny tetrisek
    drawCurrentPiece()

    drawNotification()
end

function love.keypressed(key)
        --obrót tetriska przez spację
    if key == 'space' then
        rotatePiece()
        --save game przez s 
    elseif key == 's' then
        saveGame()
        --load game przez l
    elseif key == 'l' then
        loadGame()
    end
end

function spawnNewPiece()
    currentPiece.shape = tetrominoes[love.math.random(#tetrominoes)]
    currentPiece.color = colors[love.math.random(#colors)]
    currentPiece.x = 4
    currentPiece.y = 1
end

function movePiece(dx, dy)
    local newX = currentPiece.x + dx
    local newY = currentPiece.y + dy
    
    if isValidMove(newX, newY) then
        currentPiece.x = newX
        currentPiece.y = newY
        if dx ~= 0 then
            sounds.move:play()
        end
        return true
    end
    return false
end

function isValidMove(testX, testY)
    -- czy kolizja
    for y = 1, #currentPiece.shape do
        for x = 1, #currentPiece.shape[1] do
            if currentPiece.shape[y][x] == 1 then
                local gridX = testX + x - 1
                local gridY = testY + y - 1
                
                if gridX < 1 or gridX > gridWidth or
                   gridY < 1 or gridY > gridHeight or
                   grid[gridY][gridX] ~= 0 then
                    return false
                end
            end
        end
    end
    return true
end

function drawCurrentPiece()
    love.graphics.setColor(currentPiece.color)
    for y = 1, #currentPiece.shape do
        for x = 1, #currentPiece.shape[1] do
            if currentPiece.shape[y][x] == 1 then
                love.graphics.rectangle('fill',
                    (currentPiece.x + x - 2) * blockSize,
                    (currentPiece.y + y - 2) * blockSize,
                    blockSize,
                    blockSize)
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function rotatePiece()
    local rotated = {}
    local h = #currentPiece.shape
    local w = #currentPiece.shape[1]
    
    for y = 1, w do
        rotated[y] = {}
        for x = 1, h do
            rotated[y][x] = currentPiece.shape[h - x + 1][y]
        end
    end
    
    local oldShape = currentPiece.shape
    currentPiece.shape = rotated
    
    if not isValidMove(currentPiece.x, currentPiece.y) then
        currentPiece.shape = oldShape
    end
    
    sounds.rotate:play()
end

function lockPiece()
    sounds.drop:play()
    for y = 1, #currentPiece.shape do
        for x = 1, #currentPiece.shape[1] do
            if currentPiece.shape[y][x] == 1 then
                local gridX = currentPiece.x + x - 1
                local gridY = currentPiece.y + y - 1
                grid[gridY][gridX] = {1, currentPiece.color}
            end
        end
    end
    checkLines()
end

function checkLines()
    animation.lines = {}  -- resetuj linie do animacji
    
    for y = gridHeight, 1, -1 do
        local complete = true
        for x = 1, gridWidth do
            if grid[y][x] == 0 then
                complete = false
                break
            end
        end
        
        if complete then
            table.insert(animation.lines, y)
        end
    end
    
    if #animation.lines > 0 then
        animation.timer = animation.duration
        sounds.clear:play()
    end
end

function removeLine(y)
    sounds.clear:play()
    for x = 1, gridWidth do
        grid[y][x] = 0
    end
end

function moveDownLines(startY)
    for y = startY, 2, -1 do
        for x = 1, gridWidth do
            grid[y][x] = grid[y-1][x]
        end
    end
    -- kasuj górny rząd
    for x = 1, gridWidth do
        grid[1][x] = 0
    end
end

function saveGame()
    local gameState = {
        grid = grid,
        currentPiece = {
            shape = currentPiece.shape,
            x = currentPiece.x,
            y = currentPiece.y,
            color = currentPiece.color
        },
        fallTimer = fallTimer,
        fallSpeed = fallSpeed
    }
    
    local serialized = "return " .. serializeTable(gameState)
    local success, message = love.filesystem.write("tetris_save.txt", serialized)
    if success then
        showNotification("Gra została zapisana!")
    else
        showNotification("Błąd zapisu gry!")
    end
end

function loadGame()
    if love.filesystem.getInfo("tetris_save.txt") then
        local content = love.filesystem.read("tetris_save.txt")
        local chunk, err = load(content, "tetris_save", "t", {})
        
        if chunk then
            local ok, gameState = pcall(chunk)
            if ok and gameState then
                if type(gameState) == "table" and gameState.grid and gameState.currentPiece then
                    grid = gameState.grid
                    currentPiece = gameState.currentPiece
                    fallTimer = gameState.fallTimer or 0
                    fallSpeed = gameState.fallSpeed or 0.5
                    showNotification("Gra została wczytana!")
                else
                    showNotification("Nieprawidłowy format zapisu!")
                end
            else
                showNotification("Błąd wczytywania gry!")
            end
        else
            showNotification("Błąd wczytywania pliku!")
        end
    else
        showNotification("Brak zapisanej gry!")
    end
end

function serializeTable(val)
    if type(val) == "table" then
        local str = "{"
        for k, v in pairs(val) do
            if type(k) == "number" then
                str = str .. serializeTable(v) .. ","
            elseif type(k) == "string" then
                str = str .. "['" .. k .. "']=" .. serializeTable(v) .. ","
            end
        end
        return str .. "}"
    elseif type(val) == "number" then
        return tostring(val)
    elseif type(val) == "string" then
        return "'" .. val .. "'"
    elseif type(val) == "boolean" then
        return tostring(val)
    else
        return "nil"
    end
end

function showNotification(text)
    notification.text = text
    notification.timer = notification.duration
end

function updateNotification(dt)
    if notification.timer > 0 then
        notification.timer = notification.timer - dt
    end
end

function drawNotification()
    if notification.timer > 0 then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle('fill', 10, 10, 200, 30)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(notification.text, 20, 20)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function updateAnimation(dt)
    if animation.timer > 0 then
        animation.timer = animation.timer - dt
        if animation.timer <= 0 then
            -- kasuj linie po zakończeniu animacji
            for _, y in ipairs(animation.lines) do
                removeLine(y)
                moveDownLines(y)
            end
            animation.lines = {}
        end
    end
end 