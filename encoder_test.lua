-- test yr encoders
--
-- k2/k3: select encoder
-- turn selected encoder
-- to see data
--
-- turn quickly, watch graph:
-- craggy mountains may indicate
-- a faulty encoder

engine.name = "dummy"

local encoder = 1
local value = 0
local delta = 0
local deltadelta = 0

local frame_timer
local flash = 0
local flash_fade = 0.77
local info = 0
local info_fade = 0.66

local history = {}
local history_length = 128

function init()
  frame_timer = metro.init()
  frame_timer.time = 1 / 15
  frame_timer.event = frame
  frame_timer:start()
end

function frame()
  flash = flash * flash_fade
  info = info * info_fade
  redraw()
end

function enc(n, d)
  if n == encoder then
    deltadelta = delta - d
    delta = d
    value = value + delta
    value = value % 48
    table.insert(history, 1, value)
    if deltadelta ~= 0 then
      flash = 1
    end
    info = 30
  end
end

function key(n, z)
  if z == 1 then
    if n == 2 then
      encoder = (encoder - 2) % 3 + 1
    elseif n == 3 then
      encoder = encoder % 3 + 1
    end
  end
end

function set_info_level(multiplier)
  local level = math.floor(multiplier * math.min(1, info))
  if level > 0 then
    screen.level(level)
    return true
  else
    return false
  end
end

function redraw()
  screen.clear()

  -- history graph (background)
  screen.level(1)
  for x = 1, history_length do  
    local i = history_length - x + 1
    screen.move(x, 56)
    if history[i] ~= nil then
      screen.line_rel(0, history[i] / -1)
      screen.stroke()
    end
  end

  screen.aa(0)
  screen.font_face(1)
  screen.font_size(8)

  -- info labels
  if set_info_level(4) then
    screen.move(12, 25)
    screen.text_right('dd')
    screen.move(12, 35)
    screen.text_right('d')
    screen.move(12, 45)
    screen.text_right('=')
  end

  -- info values
  if set_info_level(15) then
    screen.move(16, 25)
    screen.text(deltadelta)
    screen.move(16, 35)
    screen.text(delta)
    screen.move(16, 45)
    screen.text(value)
  end

  -- << / >> direction indicator
  local flash_level = math.floor(flash * 9)
  if flash_level > 0 then
    screen.move(28, 45)
    screen.level(flash_level)
    screen.text(delta < 0 and '<<' or '>>')
  end

  -- encoder dots / orbit
  for e = 1, 3 do
    local ex = 20 + e * 30
    local ey = e == 1 and 23 or 34

    screen.stroke() -- clear path

    screen.line_width(1)
    screen.level(2)

    if e == encoder then
      local r = 15
      screen.circle(ex, ey, r)
      screen.aa(0)
      screen.stroke()

      local v = value * math.pi / 24
      screen.aa(1)
      screen.circle(ex + r * math.cos(v), ey + r * math.sin(v), 1.1 + 0.2 * flash_level)
      screen.level(15)
      screen.fill()

      screen.aa(1)
      screen.font_face(11)
      screen.font_size(16)

      screen.move(ex, ey + 6)
      screen.level(15)
      screen.text_center('E' .. encoder)
    else
      screen.aa(0)
      screen.circle(ex, ey, 1.7)
      screen.fill()
    end
  end

  -- +/- indicators
  screen.aa(0)
  screen.font_face(1)
  screen.font_size(8)
  screen.move(125, 64)
  screen.level(2)
  screen.text_right('-  +')

  screen.update()
end
