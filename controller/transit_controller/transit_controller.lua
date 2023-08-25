--Code will be deployed in ComputerCraft

--Load the cryptoNet API
os.loadAPI("cryptoNET")

local class = require("middleclass")

local Controller = require("controller")

local TransitController = class("TransitController", Controller)

--region Constructor

function TransitController:initialize(configFileName)
    Controller.initialize(self, configFileName)
end

--Connection Opened Event Handler
function TransitController:connectionOpenedBehaviour(socket, server)
    cryptoNET.send(socket, "Hello")
end

--Connection Closed Event Handler
function TransitController:connectionClosedBehaviour(socket, server)

end

--Encrypted Message Received Event Handler
function TransitController:encryptedMessageBehaviour(message, socket, server)
    if (connectionEstablished) then
        
    end
end

--Plain Message Received Event Handler
function TransitController:plainMessageBehaviour(message, socket, server)

end

--Login Event Handler
function TransitController:loginBehaviour(username, socket, server)

end

--Login Failed Event Handler
function TransitController:loginFailedBehaviour(username, socket, server)
end

--Logout Event Handler
function TransitController:logoutBehaviour(username, socket, server)
end

--Key Up Event Handler
function TransitController:keyUpBehaviour(key)
   if (key == keys.q) then
        os.shutdown()
   end
end

--Terminate Event Handler
function TransitController:terminateBehaviour()
end

--endregion

return TransitController