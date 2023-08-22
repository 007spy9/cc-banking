--Code will be deployed in ComputerCraft

--Load the cryptoNet API
os.loadAPI("cryptoNET")

--region Constants
--The config file path
local CONFIG_FILE = "transit_controller.cfg"
--endregion

--region Variables
local serverSocket
local config
local connectionEstablished = false
local activated = false
--endregion

--region Methods
local onConnectionOpened
local onConnectionClosed
local onEncryptedMessageReceived
local onPlainMessageReceived
local onLogin
local onLoginFailed
local onLogout
local onKeyUp
local onTerminate

--region Message Methods

--Report the status of the system
function reportStatus(status)
    local message = {
        type = "status",
        message = status
    }

    cryptoNET.send(serverSocket, message)
end

--endregion

--region Network Events
function onNetworkStartup()
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
    config = readConfigurationFile(CONFIG_FILE)

    --Prepare the network connections
    serverSocket = cryptoNET.connect(config.server, false, false, modemSide)

    --Send a login message to the host controller
    cryptoNET.login(serverSocket, config.systemUsername, config.systemPassword)
end

function onNetworkEventRaised(event)
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

        onConnectionOpened(socket, server)
    elseif (eventType == "connection_closed") then
        local socket = event[2]
        local server = event[3]

        onConnectionClosed(socket, server)
    elseif (eventType == "encrypted_message") then
        local message = event[2]
        local socket = event[3]
        local server = event[4]

        onEncryptedMessageReceived(message, socket, server)
    elseif (eventType == "plain_message") then
        local message = event[2]
        local socket = event[3]
        local server = event[4]

        onPlainMessageReceived(message, socket, server)
    elseif (eventType == "login") then
        local username = event[2]
        local socket = event[3]
        local server = event[4]

        onLogin(username, socket, server)
    elseif (eventType == "login_failed") then
        local username = event[2]
        local socket = event[3]
        local server = event[4]

        onLoginFailed(username, socket, server)
    elseif (eventType == "logout") then
        local username = event[2]
        local socket = event[3]
        local server = event[4]

        onLogout(username, socket, server)
    --Add a check for a key press event, and if the key is "q", then shut down the network
    elseif (eventType == "key_up") then
        local key = event[2]
        
        onKeyUp(key)
    elseif (eventType == "terminate") then
        onTerminate()
    end
end

--Connection Opened Event Handler
function onConnectionOpened(socket, server)
    print("Connection opened" .. socket.target)

    cryptoNET.send(socket, "Hello")
end

--Connection Closed Event Handler
function onConnectionClosed(socket, server)
    print("Connection closed" .. socket.target)
end

--Encrypted Message Received Event Handler
function onEncryptedMessageReceived(message, socket, server)
    --print("Encrypted message received" .. message .. socket.target)

    if (connectionEstablished) then
        --The server is successfully connected, so we can process instructions

        --If the message is a request for intention, then send an intention message along with the intention
        if (message == "get_intention") then
            local message = {
                type = "intention",
                message = config.intention
            }

            cryptoNET.send(socket, message)

        --If the message is "disconnect", then disconnect from the server
        elseif (message == "disconnect") then
            print ("Disconnecting from server")

            reportStatus("disconnected")

            cryptoNET.logout(socket)

            cryptoNET.close(socket)

            connectionEstablished = false
            activated = false

            --If the message is "activate", then activate the system
        elseif (message == "activate") then
            print("Activating system")
            activated = true

            --Send a message to the host controller to report system status
            reportStatus("ready")
        end
    end

end

--Plain Message Received Event Handler
function onPlainMessageReceived(message, socket, server)
    --print("Plain message received" .. message .. socket.target)
end

--Login Event Handler
function onLogin(username, socket, server)
    print("Successfully logged in to Host as " .. config.systemUsername)
    connectionEstablished = true
end

--Login Failed Event Handler
function onLoginFailed(username, socket, server)
    print("Failed to log in to Host as " .. config.systemUsername)
    connectionEstablished = false
end

--Logout Event Handler
function onLogout(username, socket, server)
    print("Logged out of Host.")
    connectionEstablished = false
end

--Key Up Event Handler
function onKeyUp(key)
    if (key == keys.q) then
        reportStatus("shutting down")
        print("Q key pressed, shutting down server")
        reportStatus("disconnected")
        cryptoNET.closeAll()

        os.shutdown()
    end
end

--Terminate Event Handler
function onTerminate()
    print("Terminate event raised, shutting down server")
    cryptoNET.closeAll()

    os.shutdown()
end

--endregion

--region Configuration Reading
function readConfigurationFile(file)
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


--region Main Code
cryptoNET.startEventLoop(onNetworkStartup, onNetworkEventRaised)
--endregion