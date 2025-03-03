import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "player"
import "menu"

local gfx<const> = playdate.graphics
local dsp<const> = playdate.display

local centerX<const> = dsp.getWidth() / 2
local centerY<const> = dsp.getHeight() / 2
local playerSpriteHeight<const> = 50
playdate.display.setRefreshRate(50)
executeFrame = true --used to cycle frames to allow more time for serial processing

roundPause = 0 --out of place definition for Playlink multiplayer
gameOver = 0 --out of place definition for Playlink multiplayer
waitingForPlaylink = false

fieldBoundary = 30
maxGameSpeed = 6

p1 = nil
p2 = nil
ballSprite = nil

round = 0
gameReady = false
synth = nil

local maxRounds = 11
local vx = nil
local vy = nil

local function init()
  initSound()
  setMenuItems()
  math.randomseed(playdate.getSecondsSinceEpoch())
  dsp.setInverted(true)
  gfx.setImageDrawMode(playdate.graphics.kDrawModeNXOR)
  playdate.setMenuImage(gfx.image.new("images/pause-menu"))
end

function initSound()
  synth = playdate.sound.synth.new(playdate.sound.kWaveTriangle)
end

function setupGameAndStart(p1Dif, p2Dif)
  if p1Dif == 1 then
    p1 = Human(5, 15, "images/plong-player", 5, centerY)
  elseif p1Dif == 2 then
    p1 = Computer(1, 15, "images/plong-player", 5, centerY, 25, 1) -- EASY
  elseif p1Dif == 3 then
    p1 = Computer(1, 15, "images/plong-player", 5, centerY, 15, 2) -- MEDIUM
  elseif p1Dif == 4 then
    p1 = Computer(1, 35, "images/plong-player", 5, centerY, 10, 2) -- HARD
  end

  if p2Dif == 1 then
    p2 = Human(1, 15, "images/plong-player", 395, centerY, p1Dif == 1 and true or false)
  elseif p2Dif == 2 then
    p2 = Computer(1, 15, "images/plong-player", 395, centerY, 25, 1) -- EASY
  elseif p2Dif == 3 then
    p2 = Computer(1, 20, "images/plong-player", 395, centerY, 15, 2) -- MEDIUM
  elseif p2Dif == 4 then
    p2 = Computer(1, 35, "images/plong-player", 395, centerY, 10, 2) -- HARD
  elseif p2Dif == 5 then
    p2 = Playlink(1, 15, "images/plong-player", 395, centerY)
    
  end

  gameReady = true
  ballSprite = gfx.sprite.new(gfx.image.new("images/plong-ball"))
  ballSprite:setCollideRect(0, 0, ballSprite:getSize())
  ballSprite.x = centerX --added for Playlink
  ballSprite.y = centerY --added for Playlink
  ballSprite:add()
  resetBall()
end

function resetBall()
  vx = maxGameSpeed * (math.random(0, 1) == 0 and 1 or -1)
  vy = math.random(3, maxGameSpeed) * (math.random(0, 1) == 0 and 1 or -1)
  ballSprite:moveTo(centerX, centerY)
  
end

function moveBall() ballSprite:moveTo(ballSprite.x + vx, ballSprite.y + vy) end

function checkCollisions()
  -- print('ball x : ' .. ballSprite.x .. ' y : ' .. ballSprite.y .. ' vx : ' .. vx .. ' vy : ' .. vy)
  if ballSprite.y <= 5 then
    vy = math.abs(vy)
    synth:playNote("D5", .5, .1)
  elseif ballSprite.y >= 235 then
    vy = -math.abs(vy)
    synth:playNote("D5", .5, .1)
  end
  local collisions = ballSprite:overlappingSprites()
  if #collisions >= 1 then
    local collidingPlayer = collisions[1];
    local dif = collidingPlayer.y - ballSprite.y
    vx = -vx
    if (vx < 0 and ballSprite.x > 0 and ballSprite.x < (centerX / 2)) then
      return
    end
    if (vx > 0 and ballSprite.x < 0 and ballSprite.x > (centerX / 2)) then
      return
    end
    if dif > -4 and dif < 4 then
      if vy > 0 then
        vy = math.random(0, 1)
      else
        vy = -math.random(0, 1)
      end
      synth:playNote("D4", .5, .1)
    elseif dif > -18 and dif < 18 then
      if dif < 0 then
        vy = math.abs(vy + math.random(1, 3))
      else
        vy = -math.abs(vy - math.random(1, 3))
      end
      synth:playNote("D4", .5, .1)
    else
      if dif < 0 then
        vy = math.abs(vy + math.random(4, 6))
      else
        vy = -math.abs(vy - math.random(4, 6))
      end
      synth:playNote("D4", .5, .1)
    end
  end
end

function resetRound()
  resetBall()
  gfx.sprite.update()
  drawScore()
  gfx.drawText('*Round ' .. round .. '*', centerX - 30, centerY + 50)
  print("msg roundpause="..round)
  playdate.wait(1500)
end

function checkScore()
  if ballSprite.x <= 5 then
    p2.score = p2.score + 1
    round = round + 1
    if (checkEndGame() == true) then return true end
    resetRound()
  end
  if ballSprite.x >= 395 then
    p1.score = p1.score + 1
    round = round + 1
    if (checkEndGame() == true) then return true end
    resetRound()
  end
  return false
end

function checkEndGame()
  if (p1.score == maxRounds or p2.score == maxRounds) then
    gfx.sprite.update()
    drawScore()
    gameReady = false
    if p1.score == p2.score then
      gfx.drawText('*Draw!*', centerX - 30, centerY + 50)
      print("msg gameover=3") --tells other playdate a draw has occurred
    elseif p1.score > p2.score then
      gfx.drawText('*P1 wins!*', centerX - 30, centerY + 50)
      print("msg gameover=1") --tells other playdate p1 has won
    else
      gfx.drawText('*P2 wins!*', centerX - 30, centerY + 50)
      print("msg gameover=2") --tells other playdate p2 has won
    end
    playdate.wait(2500)
    cleanUp()
    gameMenu()
    return true;
  end
end

function drawScore()
  gfx.drawText(p1.score, centerX - (centerX / 2), 5)
  gfx.drawText(p2.score, centerX + (centerX / 2), 5)
end

function drawFieldSeparator()
  gfx.setLineWidth(4)

  for i = 2, dsp.getHeight(), 25 do gfx.drawLine(centerX, i, centerX, i + 10) end
end

function gameLoop()
  checkCollisions()
  p1:handleMovement(vx, vy, ballSprite)
  p2:handleMovement(vx, vy, ballSprite)
  moveBall()
  if (checkScore() == true) then return end
  playdate.timer.updateTimers()
  gfx.sprite.update()
  drawScore()

  -- if playdate.buttonIsPressed(playdate.kButtonB) then resetBall() end
  if (round == 0) then
    round = round + 1
    gfx.drawText('*Round ' .. round .. '*', centerX - 30, centerY + 50)
    print("msg roundpause="..round)
    playdate.wait(1500)
  end
  drawFieldSeparator()
end

playlink = false

function playdate.update()
  
  if ((playlink == false) or ((isHost == true) and (waitingForPlaylink == false))) then
    if (gameReady) then
      if executeFrame == true then
        gameLoop()
        executeFrame = false
      else
      --transmit gamestate
        if playlink == true then
          print("msg gamestate="..p1.sprite.y..","..p2.sprite.y..","
            ..ballSprite.x..","..ballSprite.y..","..p1.score..","..p2.score)
        end
        executeFrame = true
      end
      
      else
      gameMenu()
    end
    
    
  else
    --playlink connection loop
    if executeFrame == true then
      local p2Crank, _ = playdate.getCrankChange()
      print("msg "..p2Crank)
      executeFrame = false
    else
      if waitingForPlaylink == false then
        if gamestateTable ~= nil then
          p1.y = gamestateTable[1]
          p2.y = gamestateTable[2]
          ballSprite.x = gamestateTable[3]
          ballSprite.y = gamestateTable[4]
          p1.score = gamestateTable[5]
          p2.score = gamestateTable[6]
        end
        p1:handleMovement()
        p2:handleMovement()
        ballSprite:moveTo(ballSprite.x,ballSprite.y)
        gfx.sprite.update()
        gfx.drawText(p1.score, centerX - (centerX / 2), 5)
        gfx.drawText(p2.score, centerX + (centerX / 2), 5)
        if ((roundPause == 0) and (gameOver == 0)) then
          drawFieldSeparator()
        end
        --playlink draw playfield
      end
      executeFrame = true
      
    end
    
    if tonumber(roundPause) > 0 then
      gfx.pushContext()
        gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
        gfx.drawText('*Round ' .. roundPause .. '*', centerX - 30, centerY + 50)
      gfx.popContext()
    elseif tonumber(gameOver) > 0 then
      gfx.pushContext()
        gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
        local displayText = "error, gameover ="..gameOver
        if gameOver == "3" then
          displayText = "*Draw!*"
        elseif gameOver == "1" then
          displayText = "*P1 wins!*"
        elseif gameOver == "2" then
          displayText = "*P2 wins!*"
        end
        gfx.drawText(displayText, centerX - 30, centerY + 50)
        
      gfx.popContext()
    end
    
    if waitingForPlaylink == true then
      print ("code running")
      gfx.clear()
      gfx.pushContext()
        gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
        local displayText = "Waiting for Connection\n\nPlaylink for Chrome (PC/Mac only) available at:\ncoronavitae.github.io/Playlink-Cable/"
        gfx.drawText(displayText, centerX - 180, centerY -50)
        
      gfx.popContext()
    end
    
  
  end
  --playdate.drawFPS(0,0)
end


--needed for parsing serial input:
--mysplit makes it possible to split variable 
--values out of a single serial message
function mysplit(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

--string.starts makes it possible to check if 
--a message starts with a certain code
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

--second function 
function playdate.serialMessageReceived(message)
  
  
  if message == "host" then
    isHost = true
    playlink = true
    
  elseif message == "client" then
    isHost = false
    playlink = true
    waitingForPlaylink = true
    cleanUp()
    removeAssets()
    
    p1 = Dummy(1, 15, "images/plong-player", 5, centerY)
    p1.x, p1.y = 5, centerY
    p1.score = 0
    p2 = Dummy(1, 15, "images/plong-player", 395, centerY)
    p2.x, p2.y = 395, centerY
    p2.score = 0
    ballSprite = gfx.sprite.new(gfx.image.new("images/plong-ball"))
    ballSprite.x = 200
    ballSprite.y = 120
    ballSprite:add()
    ballSprite:moveTo(ballSprite.x,ballSprite.y)
  elseif message == "ping" then
    
  elseif isHost == true then
    local integer_message = tonumber(message)
    if integer_message then
      waitingForPlaylink = false
      playlinkInput = integer_message
    end
    
    
  elseif playlink == true then
    if string.starts(message,"gamestate=") then
      roundPause = 0
      gameOver = 0
      waitingForPlaylink = false
      local gamestate = string.sub(message, string.len("gamestate=")+1, string.len(message))
      --print(gamestate)
      gamestateTable = mysplit(gamestate,",")
      --print("gamestate is "..gamestateTable[1]..","..gamestateTable[2]..","..gamestateTable[3].."c"..gamestateTable[4])
    elseif string.starts(message,"roundpause=") then  
      roundPause = string.sub(message, string.len("roundpause=")+1, string.len(message))
    elseif string.starts(message,"gameover=") then
      gameOver = string.sub(message, string.len("gameover=")+1, string.len(message))
    end
    
  end
  
  --print("playlinInput now = ", playlinkInput)
  
  
end

init()
