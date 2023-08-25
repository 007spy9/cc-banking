--Code will be deployed in ComputerCraft

--Load the cryptoNet API
os.loadAPI("cryptoNET")

local class = require("middleclass")

local TransitController = require("transit_controller")

local CONFIG_FILE = "transit_controller.cfg"

local controller = TransitController:new(CONFIG_FILE)

controller:startServer()