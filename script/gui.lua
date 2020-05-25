local mod_gui = require("mod-gui")
local qrcode = require "lib.qrcode".qrcode
local gui = {prefix = "qrcode_"}
global.gui_position = {}

function math.round(x)
  return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

gui.init_player = function(player, reset)
  gui.create_button(player, reset)
end

function gui.create_button(player)
  reset = reset or false
  if not player.gui then
    return
  end
  local frame = mod_gui.get_button_flow(player)

  local flow = frame[gui.prefix .. "open_flow"]

  if not flow then
    frame.add(
      {
        type = "sprite-button",
        name = gui.prefix .. "open",
        sprite = "qrcode-icon",
        style = mod_gui.button_style,
        tooltip = {"gui-silo-script.button-tooltip"}
      }
    )
  end
end

local function chunkSurface(surface, size)
  for i = -size / 32, size / 32 do
    for j = -size / 32, size / 32 do
      surface.set_chunk_generated_status({i, j}, defines.chunk_generated_status.entities)
    end
  end
end

local function placeWhiteSpots(player, surface, size, pixel_size, fill)
  local tiles = {}
  for i = -size, size - 1 do
    for j = -size, size - 1 do
      if fill[1] then
        table.insert(tiles, {name = fill[1], position = {i, j}})
      end
      if fill[2] then
        surface.create_entity({name = fill[2], position = {x = i, y = j}, force = player.force})
      end
    end
  end
  surface.set_tiles(tiles)
end

local function placeBlackSpots(player, surface, qr, pixel_size, black, white)
  local floor = math.floor
  local size = #qr * pixel_size
  local adjust = 0 - (size / 2) - pixel_size
  local tiles = {}

  for x, row in pairs(qr) do
    for y, tile in pairs(row) do
      if tile > 0 then
        local base_x = floor(adjust + (x * pixel_size))
        local base_y = floor(adjust + (y * pixel_size))
        for i = 0, pixel_size - 1 do
          for j = 0, pixel_size - 1 do
            if white[2] then
              local e = surface.find_entities_filtered({name = white[2], position = {base_x + i + .5, base_y + j + .5}})
              for _, ent in pairs(e) do
                ent.destroy()
              end
            end
            if black[1] then
              table.insert(tiles, {name = black[1], position = {x = base_x + i, y = base_y + j}})
            end
            if black[2] then
              surface.create_entity(
                {name = black[2], position = {x = base_x + i, y = base_y + j}, force = player.force}
              )
            end
          end
        end
      end
    end
  end

  surface.set_tiles(tiles)
end

function gui.create_tile_from_qr(qr, player, pixel_size, white, black)
  local size = #qr * pixel_size + (8 * pixel_size)
  local surface =
    game.create_surface(
    "drawbp",
    {
      width = size,
      height = size
    }
  )
  surface.always_day = true

  chunkSurface(surface, size)
  placeWhiteSpots(player, surface, size, pixel_size, white)
  placeBlackSpots(player, surface, qr, pixel_size, black, white)

  local stack = player.cursor_stack
  local floor = math.floor
  stack.clear()
  stack.set_stack("blueprint")
  stack.create_blueprint {
    surface = surface,
    force = game.forces.player,
    area = {
      {-floor(size / 2) - 1, -floor(size / 2) - 1},
      {floor(size / 2) + (pixel_size - 1.1), floor(size / 2) - .1}
    },
    always_include_tiles = true,
    include_entities = true
  }
  game.delete_surface(surface)
end

function gui.create_fields(player, frame)
  -- Input
  frame.add {
    type = "label",
    name = gui.prefix .. "text_label",
    caption = {"", {"gui.qrcode-text"}, " :"},
    style = "bold_label"
  }

  frame.add(
    {
      type = "textfield",
      name = gui.prefix .. "text"
    }
  )
  -- Tiling size
  frame.add {
    type = "label",
    name = gui.prefix .. "size_label",
    caption = {"", {"gui.qrcode-size"}, " :"},
    style = "bold_label"
  }
  frame.add(
    {
      type = "drop-down",
      name = gui.prefix .. "size",
      items = {"1 tile", "2 tile", "3 tile"},
      selected_index = 1
    }
  )

  -- White tiles
  frame.add {
    type = "label",
    name = gui.prefix .. "white_label",
    caption = {"", {"gui.qrcode-white"}, " :"},
    style = "bold_label"
  }
  frame.add(
    {
      type = "choose-elem-button",
      elem_type = "tile",
      name = gui.prefix .. "white",
      style = mod_gui.button_style,
      tile = "stone-path"
    }
  )

  -- White entities
  frame.add {
    type = "label",
    name = gui.prefix .. "white_entities_label",
    caption = {"", {"gui.qrcode-white-entity"}, " :"},
    style = "bold_label"
  }
  frame.add(
    {
      type = "choose-elem-button",
      elem_type = "entity",
      name = gui.prefix .. "white-entity",
      style = mod_gui.button_style,
      entity = "stone-wall",
      force = player.force
    }
  )

  -- Black spots entities
  frame.add {
    type = "label",
    name = gui.prefix .. "black_label",
    caption = {"", {"gui.qrcode-black"}, " :"},
    style = "bold_label"
  }
  frame.add(
    {
      type = "choose-elem-button",
      elem_type = "tile",
      name = gui.prefix .. "black",
      style = mod_gui.button_style,
      tile = "hazard-concrete-left"
    }
  )
  -- Black spots entities
  frame.add {
    type = "label",
    name = gui.prefix .. "black_entities_label",
    caption = {"", {"gui.qrcode-black-entity"}, " :"},
    style = "bold_label"
  }
  frame.add(
    {
      type = "choose-elem-button",
      elem_type = "entity",
      name = gui.prefix .. "black-entity",
      style = mod_gui.button_style
    }
  )

  -- Button row
  frame.add {
    type = "label",
    name = gui.prefix .. "button_filler",
    caption = "",
    style = "bold_label"
  }
  frame.add(
    {
      type = "button",
      name = gui.prefix .. "submit",
      caption = {"gui.qrcode-create"},
      style = "confirm_button"
    }
  )
end

function gui.dragged(event)
  local player_id = event.player_index
  if player_id then
    local player = game.players[player_id]

    if player.gui.screen[gui.prefix .. "draggable_frame"] then
      local element = event.element

      if element.name == gui.prefix .. "draggable_frame" then
        global.gui_position[player_id] = element.location
      end
    end
  end
end

function gui.open_flow(event)
  local player = Player.get(event.player_index)

  global.gui_position[player.index] =
    global.gui_position[player.index] or {x = 300 * player.display_scale, y = 300 * player.display_scale}

  local center_gui = player.gui.screen
  if center_gui[gui.prefix .. "draggable_frame"] then
    center_gui[gui.prefix .. "draggable_frame"].destroy()
    return
  end

  local frame =
    center_gui.add(
    {type = "frame", name = gui.prefix .. "draggable_frame", direction = "vertical", style = "dialog_frame"}
  )
  frame.location = global.gui_position[event.player_index]
  frame.style.vertical_align = "center"
  frame.style.horizontal_align = "center"

  local flow = frame[gui.prefix .. "flow"]
  if flow == nil or not flow.valid then
    if flow then
      flow.destroy()
    end
    flow =
      frame.add {
      type = "flow",
      name = gui.prefix .. "flow",
      direction = "horizontal"
    }
    flow.style.horizontally_stretchable = true
    flow.style.vertical_align = "center"
  end

  local label = flow.add({type = "label", caption = {"gui.qrcode-head"}, style = "frame_title"})
  label.drag_target = frame

  local widget = flow.add({type = "empty-widget", name = gui.prefix .. "drag", style = "draggable_space_header"})
  widget.style.horizontally_stretchable = true
  widget.style.vertically_stretchable = true
  widget.style.minimal_width = 24
  widget.drag_target = frame

  -- recreate
  flow.add(
    {type = "sprite-button", sprite = "utility/close_white", style = "close_button", name = gui.prefix .. "close"}
  )

  local info_frame =
    frame.add {
    type = "flow",
    name = gui.prefix .. "frame",
    direction = "vertical"
  }
  info_frame.style.horizontally_stretchable = false

  local itable =
    info_frame.add {
    type = "table",
    column_count = 2,
    name = gui.prefix .. "table"
  }
  itable.style.column_alignments[1] = "right"

  gui.create_fields(player, itable)
end

function gui.button_click(event)
  local player = Player.get(event.player_index)
  local frame = player.gui.screen
  local flow = frame[gui.prefix .. "draggable_frame"]
  local iframe = flow[gui.prefix .. "frame"]
  local itable = iframe[gui.prefix .. "table"]

  local text = itable[gui.prefix .. "text"].text
  -- Check text
  local size = itable[gui.prefix .. "size"].selected_index
  local white = itable[gui.prefix .. "white"].elem_value or nil
  local white_entity = itable[gui.prefix .. "white-entity"].elem_value or nil
  local black = itable[gui.prefix .. "black"].elem_value
  local black_entity = itable[gui.prefix .. "black-entity"].elem_value

  local success, res = qrcode(text)
  -- local success, res = qrcode(stack.export_stack(), nil, 2)
  if success then
    gui.create_tile_from_qr(res, player, size, {white, white_entity}, {black, black_entity})
    -- player.teleport({0, 0}, surf)
    flow.destroy()
  end
end

function gui.close_flow(event)
  local player = Player.get(event.player_index)
  local frame = player.gui.screen
  local flow = frame[gui.prefix .. "draggable_frame"]
  if flow and flow.valid then
    flow.destroy()
  end
end

function gui.setup_events()
  Event.register(
    defines.events.on_player_created,
    function(event)
      local player = Player.get(event.player_index)
      gui.init_player(player)
    end
  )

  Gui.on_click(gui.prefix .. "open", gui.open_flow)
  Gui.on_click(gui.prefix .. "submit", gui.button_click)
  Gui.on_click(gui.prefix .. "close", gui.close_flow)
  Event.register(defines.events.on_gui_location_changed, gui.dragged)
  Event.register({defines.events.on_gui_closed, defines.events.on_gui_opened}, gui.close_flow)

  Event.on_init(
    function()
      for i, player in pairs(game.players) do
        gui.init_player(player)
      end
    end
  )
end

return gui
