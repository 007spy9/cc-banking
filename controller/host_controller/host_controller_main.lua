--Code will be deployed in ComputerCraft

--Load the cryptoNet API
os.loadAPI("cryptoNET")

local class = require("middleclass")

local HostController = require("host_controller")

--Try to get the attached monitors
local Monitors = { peripheral.find("monitor") }

--The processors list will store the different processing units linked to the host controller
local Processors = {
    --Add a dummy processor to the list
    { id = "accounts", status = HostController.processorStatus.disconnected },
    { id = "transit",  status = HostController.processorStatus.disconnected },
    { id = "gambling", status = HostController.processorStatus.disconnected },
    { id = "market",   status = HostController.processorStatus.disconnected },
    { id = "loans",    status = HostController.processorStatus.disconnected },
    { id = "admin",    status = HostController.processorStatus.disconnected }
}

local controller = HostController:new(Monitors, Processors)

controller:startServer()