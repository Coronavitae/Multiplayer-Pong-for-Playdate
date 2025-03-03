local gfx<const> = playdate.graphics
local dsp<const> = playdate.display
local centerX<const> = dsp.getWidth() / 2
local centerY<const> = dsp.getHeight() / 2

local p1Cl, p1Cr, p2Cl, p2Cr = nil
local p1label, p2label = nil
local selectorRadius = 8
local levelLabels = {'Human', 'AI - Easy', 'AI - Medium', 'AI - Hard'}

local p1Selection, p2Selection = 1, 3
local cursorOptions = {'player1', 'player2', 'start', 'playlink'}
local cursorSelected = 3

local pangLogo = nil
local dateLogo = nil

local function loadSprites()
  local chevronLeftImg = gfx.image.new("images/cleft")
  local chevronLeftImgSelected = gfx.image.new("images/cleft"):setInverted(1)

  p1Cl = gfx.sprite.new(chevronLeftImg)
  p1Cr = gfx.sprite.new(chevronLeftImg)
  p1Cr:setImageFlip(1)
  p2Cl = gfx.sprite.new(chevronLeftImg)
  p2Cr = gfx.sprite.new(chevronLeftImg)
  p2Cr:setImageFlip(1)

  pangLogo = gfx.sprite.new(gfx.image.new("images/panglogo"))
  dateLogo = gfx.sprite.new(gfx.image.new("images/datelogo"))
  pangLogo:moveTo(centerX, centerY - 60);
  dateLogo:moveTo(centerX + 99, centerY - 42);

  p1label = gfx.sprite.new()
  p1text = gfx.image.new(100, 20)
  gfx.pushContext(p1text)
  gfx.drawText('player 1', 0, 0)
  gfx.popContext()
  p1label:setImage(p1text)
  p1label:moveTo(centerX - 55, centerY + 20)

  p2label = gfx.sprite.new()
  p2text = gfx.image.new(100, 20)
  gfx.pushContext(p2text)
  gfx.drawText('player 2', 0, 0)
  gfx.popContext()
  p2label:setImage(p2text)
  p2label:moveTo(centerX - 55, centerY + 50)
  drawStaticAssets()
end

function drawStaticAssets()
  pangLogo:add()
  dateLogo:add()
  p1label:add()
  p2label:add()
end

function drawP1DifficultySelector(text, x, y)
  p1Cl:moveTo(x - 55, y + 10)
  p1Cl:addSprite()
  p1Cr:moveTo(x + 55, y + 10)
  p1Cr:addSprite()
  gfx.drawTextAligned(text, x, y, kTextAlignment.center)
end

function drawP2DifficultySelector(text, x, y)
  p2Cl:moveTo(x - 55, y + 10)
  p2Cl:addSprite()
  p2Cr:moveTo(x + 55, y + 10)
  p2Cr:addSprite()
  gfx.drawTextAligned(text, x, y, kTextAlignment.center)
end

function drawOptions()
  if (cursorOptions[cursorSelected] == 'player1') then
    gfx.fillRect(centerX + 5, centerY + 8, 90, 22)
  end
  drawP1DifficultySelector(levelLabels[p1Selection], centerX + 50, centerY + 10)
  if (cursorOptions[cursorSelected] == 'player2') then
    gfx.fillRect(centerX + 5, centerY + 38, 90, 22)
  end
  drawP2DifficultySelector(levelLabels[p2Selection], centerX + 50, centerY + 40)

  if (cursorOptions[cursorSelected] == 'start') then
    gfx.fillRect(centerX - 52, centerY + 63, 104, 22)
  end
  
  if (cursorOptions[cursorSelected] == 'playlink') then
    gfx.fillRect(centerX - 67, centerY + 88, 134, 22)
  end
  
  gfx.drawTextAligned('*START GAME*', centerX, centerY + 65,
                      kTextAlignment.center)
                      
  gfx.drawTextAligned('*START PLAYLINK*', centerX, centerY + 90,
                      kTextAlignment.center)
  
end

function cursorPrev()
  if cursorSelected == 1 then
    cursorSelected = 4
  else
    cursorSelected = cursorSelected - 1
  end
end

function cursorNext()
  if cursorSelected == 4 then
    cursorSelected = 1
  else
    cursorSelected = cursorSelected + 1
  end
end

function selectPlayerDifficultyPrev(pSelection)
  if pSelection == 1 then
    return 4
  else
    return pSelection - 1
  end
end

function selectPlayerDifficultyNext(pSelection)
  if pSelection == 4 then
    return 1
  else
    return pSelection + 1
  end
end

function removeAssets()
  p1Cl:remove()
  p1Cr:remove()
  p2Cl:remove()
  p2Cr:remove()
  p1label:remove()
  p2label:remove()
  pangLogo:remove()
  dateLogo:remove()
end

function handleInput()
  if playdate.buttonJustPressed(playdate.kButtonUp) then
    cursorPrev()
  elseif playdate.buttonJustPressed(playdate.kButtonDown) then
    cursorNext()
  elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
    if cursorSelected == 1 then
      p1Selection = selectPlayerDifficultyPrev(p1Selection)
      playdate.graphics.fillCircleAtPoint(195, 140, selectorRadius)
    elseif cursorSelected == 2 then
      p2Selection = selectPlayerDifficultyPrev(p2Selection)
      playdate.graphics.fillCircleAtPoint(195, 170, selectorRadius)
    end
  elseif playdate.buttonJustPressed(playdate.kButtonRight) then
    if cursorSelected == 1 then
      p1Selection = selectPlayerDifficultyNext(p1Selection)
      playdate.graphics.fillCircleAtPoint(305, 140, selectorRadius)
    elseif cursorSelected == 2 then
      p2Selection = selectPlayerDifficultyNext(p2Selection)
      playdate.graphics.fillCircleAtPoint(305, 170, selectorRadius)
    end
  elseif playdate.buttonJustPressed(playdate.kButtonA) or
      playdate.buttonJustPressed(playdate.kButtonA) then
    if cursorSelected == 3 then
      removeAssets()
      setupGameAndStart(p1Selection, p2Selection)
    elseif cursorSelected == 4 then
      playlinkInput = 0
      removeAssets()
      setupGameAndStart(1, 5)
      print("Playlink Game Started")
      playlink = true
      waitingForPlaylink = true
    end
    
  end
end

function cleanUp()
  humanPlayers = 0
  if (p1 and p2) then
    p1.score = 0
    p2.score = 0
    ballSprite:remove()
    p1:remove()
    p2:remove()
  end
  round = 0
  gameReady = false
  gfx.clear()
  drawStaticAssets()
end

function setMenuItems()
  local menu = playdate.getSystemMenu()
  menu:addMenuItem("Main menu", function()
    cleanUp()
  end)
end

function gameMenu()
  playdate.timer.updateTimers()
  gfx.sprite.update()
  drawOptions()
  handleInput()
end

loadSprites()
