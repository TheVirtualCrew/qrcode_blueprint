local qrcode = require "lib.qrcode"

Event = require("__stdlib__/stdlib/event/event")
Player = require("__stdlib__/stdlib/event/player").register_events()
Gui = require("__stdlib__/stdlib/event/gui")

local gui = require "script.gui"

gui.setup_events()