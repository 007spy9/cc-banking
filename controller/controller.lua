--Code will be deployed in ComputerCraft

--Load the cryptoNet API
os.loadAPI("cryptoNET")

local class = require("middleclass")

--region Configuration Reading
local _readConfigurationFile = function(self, file)
    --Read the configuration file
      local configFile = fs.open(file, "r")
      
      --The configuration file is a JSON file, so we can use the JSON API to decode it
  
      --The config is in the following format:
      --{
      --  server,
      --  systemName,
      --  systemUsername,
      --  systemPassword,
      --  intention
      --}
      local rawText = configFile.readAll()
      local config = textutils.unserializeJSON(rawText)
  
      print("Raw config: " .. rawText)
  
      configFile.close()
  
      --Check that the config is valid
      if (config == nil) then
          error("Invalid configuration file")
      end
  
      --Check that the server is valid
      if (config.server == nil) then
          error("Invalid server")
      end
  
      --Check that the system name is valid
      if (config.systemName == nil) then
          error("Invalid system name")
      end
  
      --Check that the system username is valid
      if (config.systemUsername == nil) then
          error("Invalid system username")
      end
  
      --Check that the system password is valid
      if (config.systemPassword == nil) then
          error("Invalid system password")
      end
  
      --Check that the intention is valid
      if (config.intention == nil) then
          error("Invalid intention")
      end
  
      return config
  end
  --endregion

--This is our base controller class that all other controllers will inherit from
Controller = class("Controller")

--region Constants
--The config file path
Controller.static.CONFIG_FILE = "controller.cfg"
--endregion

--region Constructor
function Controller:initialize(configFileName)
    self.CONFIG_FILE = configFileName
    self._serverSocket = nil
    self._config = nil
    self._connectionEstablished = false
    self._activated = false
end
--endregion

--region Message Methods

--Report the status of the system
function Controller:reportStatus(status)
    local message = {
        type = "status",
        message = status
    }

    cryptoNET.send(self._serverSocket, message)
end

--endregion

--region Network Events
function Controller:onNetworkStartup()
    --Get the side of the wireless modem and make sure it is not the wired modem
    local modemSide
    local modems = { peripheral.find("modem", function(name, modem)
        return modem.isWireless() -- Check this modem is wireless.
    end) }
    
    for _, modem in pairs(modems) do
        --Get the side that the modem is on
        modemSide = peripheral.getName(modem)
      end

    --Read the configuration file
    self._config = _readConfigurationFile(self, self.CONFIG_FILE)

    --Prepare the network connections
    self._serverSocket = cryptoNET.connect(self._config.server, false, false, modemSide)

    --Send a login message to the host controller
    cryptoNET.login(self._serverSocket, self._config.systemUsername, self._config.systemPassword)
end

function Controller:onNetworkEventRaised(event)
    --Different events have different parameters:
    -- connection_opened
    -- -> socket, server
    -- connection_closed
    -- -> socket, server
    -- encrypted_message
    -- -> message, socket, server
    -- plain_message
    -- -> message, socket, server
    -- login
    -- -> username, socket, server
    -- login_failed
    -- -> username, socket, server
    -- logout
    -- -> username, socket, server
    -- key_up
    -- -> key
    local eventType = event[1]    

    if (eventType == "connection_opened") then
        local socket = event[2]
        local server = event[3]

        self.onConnectionOpened(socket, server)
    elseif (eventType == "connection_closed") then
        local socket = event[2]
        local server = event[3]

        self.onConnectionClosed(socket, server)
    elseif (eventType == "encrypted_message") then
        local message = event[2]
        local socket = event[3]
        local server = event[4]

        self.onEncryptedMessageReceived(message, socket, server)
    elseif (eventType == "plain_message") then
        local message = event[2]
        local socket = event[3]
        local server = event[4]

        self.onPlainMessageReceived(message, socket, server)
    elseif (eventType == "login") then
        local username = event[2]
        local socket = event[3]
        local server = event[4]

        self.onLogin(username, socket, server)
    elseif (eventType == "login_failed") then
        local username = event[2]
        local socket = event[3]
        local server = event[4]

        self.onLoginFailed(username, socket, server)
    elseif (eventType == "logout") then
        local username = event[2]
        local socket = event[3]
        local server = event[4]

        self.onLogout(username, socket, server)
    elseif (eventType == "key_up") then
        local key = event[2]
        
        self.onKeyUp(key)
    elseif (eventType == "terminate") then
        self.onTerminate()
    end
end

--Connection Opened Event Handler
function Controller:onConnectionOpened(socket, server)
    print("Connection opened" .. socket.target)

    self.connectionOpenedBehaviour(socket, server)
end

--Connection Closed Event Handler
function Controller:onConnectionClosed(socket, server)
    print("Connection closed" .. socket.target)

    self.connectionClosedBehaviour(socket, server)
end

--Encrypted Message Received Event Handler
function Controller:onEncryptedMessageReceived(message, socket, server)
    --Base behaviour to ensure that the connection is established correctly
    if (connectionEstablished) then
        --The server is successfully connected, so we can process instructions

        --If the message is a request for intention, then send an intention message along with the intention
        if (message == "get_intention") then
            local message = {
                type = "intention",
                message = self._config.intention
            }

            cryptoNET.send(socket, message)

        --If the message is "disconnect", then disconnect from the server
        elseif (message == "disconnect") then
            print ("Disconnecting from server")

            reportStatus("disconnected")

            cryptoNET.logout(socket)

            cryptoNET.close(socket)

            self._connectionEstablished = false
            self._activated = false

            --If the message is "activate", then activate the system
        elseif (message == "activate") then
            print("Activating system")
            self._activated = true

            --Send a message to the host controller to report system status
            reportStatus("ready")
        end

        --Call the derived class behaviour for encrypted messages if the system is activated
        if (self._activated) then
            self.encryptedMessageBehaviour(message, socket, server)
        end
    end

end

--Plain Message Received Event Handler
function Controller:onPlainMessageReceived(message, socket, server)
    
    --Call the derived class behaviour for plain messages if the system is activated
    if (self._activated) then
        self.plainMessageBehaviour(message, socket, server)
    end
end

--Login Event Handler
function Controller:onLogin(username, socket, server)
    print("Successfully logged in to Host as " .. self._config.systemUsername)
    self._connectionEstablished = true

    self.loginBehaviour(username, socket, server)
end

--Login Failed Event Handler
function Controller:onLoginFailed(username, socket, server)
    print("Failed to log in to Host as " .. self._config.systemUsername)
    self._connectionEstablished = false

    self.loginFailedBehaviour(username, socket, server)
end

--Logout Event Handler
function Controller:onLogout(username, socket, server)
    print("Logged out of Host.")
    self._connectionEstablished = false

    self.logoutBehaviour(username, socket, server)
end

--Key Up Event Handler
function Controller:onKeyUp(key)
    if (key == keys.q) then
        reportStatus("shutting down")
        print("Q key pressed, shutting down server")
        reportStatus("disconnected")
        cryptoNET.closeAll()

        os.shutdown()
    end

    self.keyUpBehaviour(key)
end

--Terminate Event Handler
function Controller:onTerminate()
    print("Terminate event raised, shutting down server")
    cryptoNET.closeAll()

    self.terminateBehaviour()
end

--endregion

--region Virtual Methods

function Controller:connectionOpenedBehaviour(socket, server)

end

function Controller:connectionClosedBehaviour(socket, server)
    
end

function Controller:encryptedMessageBehaviour(message, socket, server)
    
end

function Controller:plainMessageBehaviour(message, socket, server)
    
end

function Controller:loginBehaviour(username, socket, server)
    
end

function Controller:loginFailedBehaviour(username, socket, server)
    
end

function Controller:logoutBehaviour(username, socket, server)
    
end

function Controller:keyUpBehaviour(key)
    
end 

function Controller:terminateBehaviour()
    
end

--endregion

--region Entry Point
function Controller:startServer()
    cryptoNET.startEventLoop(self.onNetworkStartup, self.onNetworkEventRaised)
end

--endregion

return Controller