--Code will be deployed in ComputerCraft

--Load libraries
os.loadAPI("cryptoNET")

local class = require("middleclass")

local Controller = require("controller")

local HostController = class("HostController", Controller)

--region Constants
--The server address for the host controller
local HOST_CONTROLLER_SERVER = "BankNet.BankSys.Host"
local CLIENT_ACCESS_SERVER = "BankNet.BankSys.Client"

--The account data file path
local ACCOUNT_DATA_FILE = "accountData.dat"
--endregion

--region UI Functions

--Function to update the processor states on the monitors
local _updateProcessorStates = function(self, monitors, processors)
    for i = 1, #monitors do
        --Below the word "Database:", place the word "Processors:" on the left
        monitors[i].setCursorPos(1, 6)
        monitors[i].write("Processors:")

        --Calculate the length of the longest ID
        local longestId = 0
        for j = 1, #processors do
            if string.len(processors[j].id) > longestId then
                longestId = string.len(processors[j].id)
            end
        end

        --Below the word "Processors:", place a list of all the processors in the format of [-] [ID]: [Status]
        --The [-] will be a tick or cross or ! or ... depending on the status of the processor
        --The [ID] will be the ID of the processor
        --The [Status] will be the status of the processor

        for j = 1, #processors do
            --Move the cursor to the line below the word "Processors:"
            monitors[i].setCursorPos(1, 6 + j)

            --Before writing the status, clear the line to make sure the status is written correctly
            monitors[i].clearLine()

            --Place the tick or cross
            --Tick will be green, cross will be red, ! will be yellow, ... will be grey
            --Tick for ready, ! for error, ... for shutting down or processing, cross for disconnected
            if processors[j].status == self.processorStatus.ready then
                monitors[i].setTextColor(colors.green)
                monitors[i].write("[+]")
            elseif processors[j].status == self.processorStatus.error then
                monitors[i].setTextColor(colors.yellow)
                monitors[i].write("[!]")
            elseif processors[j].status == self.processorStatus.shuttingDown or processors[j].status == self.processorStatus.processing then
                monitors[i].setTextColor(colors.gray)
                monitors[i].write("[.]")
            elseif processors[j].status == self.processorStatus.disconnected then
                monitors[i].setTextColor(colors.red)
                monitors[i].write("[X]")
            else
                --If the status is not recognised, place a question mark
                monitors[i].setTextColor(colors.red)
                monitors[i].write("[?]")
            end

            --Place the ID
            monitors[i].setCursorPos(4, 6 + j)
            monitors[i].write(self.idToTitleCase(processors[j].id))

            --Place the status at the length of the longest ID + 5
            monitors[i].setCursorPos(longestId + 5, 6 + j)

            monitors[i].write(self.statusToString(processors[j].status))

            --print(j .. " " .. processors[j].id .. " " .. processors[j].status)
            --Print the position of the cursor
            --print(monitors[i].getCursorPos())
        end

        monitors[i].setCursorPos(1, 13)

        --Reset text colour to white
        monitors[i].setTextColor(colors.white)
    end
end

--Function to update the network status on the monitors
local _updateNetworkStatus = function(self, monitors, status)
    for i = 1, #monitors do
        --Move the cursor to the line below the word "Status"
        monitors[i].setCursorPos(1, 4)

        --Before writing the status, clear the line to make sure the status is written correctly
        monitors[i].clearLine()
        
        --Below the word "Network:", place the word "RedNet:" on the left
        monitors[i].write("Network:")

        --Place the word "Preparing..." next to the word "RedNet:", with a text colour of green for online, red for offline, yellow for preparing, grey for shutting down, and red for error
        monitors[i].setCursorPos(10, 4)
        
        --Set the text colour to green for online, red for offline, yellow for preparing, grey for shutting down, and red for error
        if status == self.networkStatus.online then
            monitors[i].setTextColor(colors.green)
        elseif status == self.networkStatus.offline then
            monitors[i].setTextColor(colors.red)
        elseif status == self.networkStatus.preparing then
            monitors[i].setTextColor(colors.yellow)
        elseif status == self.networkStatus.shuttingDown then
            monitors[i].setTextColor(colors.gray)
        elseif status == self.networkStatus.error then
            monitors[i].setTextColor(colors.red)
        else
            --If the status is not recognised, place a question mark
            monitors[i].setTextColor(colors.yellow)
        end

        monitors[i].write(self.networkStatusToString(status))

        --Change the text colour back to white
        monitors[i].setTextColor(colors.white)
    end
end

--Function to update the database status on the monitors
local _updateDatabaseStatus = function(self, monitors, status) 
   for i = 1, #monitors do
        --Below the word "Network:", place the word "Database:" on the left
        Monitors[i].setCursorPos(1, 5)
        Monitors[i].write("Database:")
    
        --Place the word "Preparing..." next to the word "Database:", with a text colour of green for online, red for offline, yellow for preparing, grey for shutting down, and red for error
        Monitors[i].setCursorPos(11, 5)
        
        --Set the text colour to green for online, red for offline, yellow for preparing, grey for shutting down, and red for error
        if status == self.networkStatus.online then
            monitors[i].setTextColor(colors.green)
        elseif status == self.networkStatus.offline then
            monitors[i].setTextColor(colors.red)
        elseif status == self.networkStatus.preparing then
            monitors[i].setTextColor(colors.yellow)
        elseif status == self.networkStatus.shuttingDown then
            monitors[i].setTextColor(colors.gray)
        elseif status == self.networkStatus.error then
            monitors[i].setTextColor(colors.red)
        else
            --If the status is not recognised, place a question mark
            monitors[i].setTextColor(colors.yellow)
        end

        monitors[i].write(self.networkStatusToString(status))
    
        --Change the text colour back to white
        monitors[i].setTextColor(colors.white)
   end
end
--endregion

--region Account Data Functions

--Load the account data from the file
local _loadAccountData = function(self, path)
    --Load the account data from the file (.dat)
    --If the file does not exist, return nil
    --If the file exists, return the account data parsed from the JSON file

    --Check that the file exists
    if (not fs.exists(path)) then
        return nil
    end

    --Open the file
    local file = fs.open(path, "r")

    --Read the file
    local fileContents = file.readAll()

    --Parse the file contents as JSON
    local accountData = textutils.unserializeJSON(fileContents)

    --Close the file
    file.close()

    --If the account data is nil, return nil
    if (accountData == nil) then
        return nil
    end

    print("Account data loaded")

    --Return the account data
    return accountData
end

--Save the account data to the file
local _saveAccountData = function(self, path, accountData)
    --Save the account data to the file (.dat)
    --If the file does not exist, create it
    --If the file exists, overwrite it

    --Open the file
    local file = fs.open(path, "w")

    --Write the account data to the file as JSON
    file.write(textutils.serializeJSON(accountData))

    --Close the file
    file.close()
end

--Modify the data of an account
local _modifyAccountData = function(self, username, data)
    --If the account data is nil, return false
    if (AccountData == nil) then
        return false
    end

    --The account data is in the following format:
    --[{
    --  username,
    --  intention,
    -- }]

    --Find the account with the given username
    local found = false
    for i = 1, #AccountData do
        if (AccountData[i].username == username) then
            --Set the data at the given index to the new data
            AccountData[i] = data
            found = true
            break
        end
    end

    --If the account does not exist, return false
    if (not found) then
        return false
    end

    --Save the account data to the file
    _saveAccountData(ACCOUNT_DATA_FILE, AccountData)

    --Return true
    return true
end

--Get the data of an account
local _getAccountData = function(self, accountData, username)
    --If the account data is nil, return nil
    if (accountData == nil) then
        return nil
    end

    --The account data is in the following format:
    --[{
    --  username,
    --  intention,
    -- }]

    --Find the account with the given username
    for i = 1, #accountData do
        if (accountData[i].username == username) then
            --Return the data at the given index
            return accountData[i]
        end
    end

    --If the account does not exist, return nil
    return nil
end

--Add an account to the account data
local _addAccountData = function(self, data)
    --If the account data is nil, create a new list
    if (AccountData == nil) then
        AccountData = {}
    end

    --The account data is in the following format:
    --[{
    --  username,
    --  intention,
    -- }]

    --Add the data to the account data
    AccountData[#AccountData + 1] = data

    --Save the account data to the file
    _saveAccountData(ACCOUNT_DATA_FILE, AccountData)

    --Return true
    return true
end

--endregion

--region Service Account Functions

--Function to create a service account
local _createServiceAccount = function(self, id, password, intention, server)
    --Create a new account with the ID and password
    --If the account already exists, return false
    --If the account is created successfully, return true

    if (cryptoNET.userExists(id, server)) then
        return false
    end

    cryptoNET.addUser(id, password, 1, server)

    --Create the account data
    local accountData = {
        username = id,
        intention = intention
    }

    --Add the account data to the account data file
    _addAccountData(accountData)

    return true
end

--endregion

--region Variables
--Try to get the attached monitors
local Monitors = {}

--The processors list will store the different processing units linked to the host controller
local Processors = {}

local AccountData = nil

local HostSocket = nil
local ClientSocket = nil
--endregion

--region Constructor

function HostController:initialize(monitors, processors)
    Controller.initialize(self, "host_controller.cfg")
    Monitors = monitors
    Processors = processors
    AccountData = _loadAccountData(self, ACCOUNT_DATA_FILE)
end

--endregion
--region Network Events
function HostController:onNetworkStartup()
    --Get the side of the wireless modem and make sure it is not the wired modem
    local modemSide
    local modems = { peripheral.find("modem", function(name, modem)
        return modem.isWireless() -- Check this modem is wireless.
    end) }
    
    for _, modem in pairs(modems) do
        --Get the side that the modem is on
        modemSide = peripheral.getName(modem)
      end

    --Prepare the network connections
    HostSocket = cryptoNET.host(HOST_CONTROLLER_SERVER, false, false, modemSide)
    --ClientSocket = cryptoNET.host(CLIENT_ACCESS_SERVER, false)

    print("Event loop started")

    _updateNetworkStatus(Monitors, self.networkStatus.online)
end

--endregion

--region Event Handlers

--Connection Opened Event Handler
function HostController:connectionOpenedBehaviour(socket, server)
    cryptoNET.send(socket, "Hello")
end

--Connection Closed Event Handler
function HostController:connectionClosedBehaviour(socket, server)
end

--Encrypted Message Received Event Handler
function HostController:encryptedMessageBehaviour(message, socket, server)
    --If the message is an object, then check the type property
    --If the type is intention, then verify the intention

    --Check that the message is an object
    if (type(message) ~= "table") then
        return
    end

    --Check that the message has a type property
    if (message.type == nil) then
        return
    end

    --Check that the message type is intention
    if (message.type == "intention") then
        --Get the account data for the socket username
        local accountData = _getAccountData(self, AccountData, socket.username)

        --If the account data is nil, then the account does not exist, so return
        if (accountData == nil) then
            return
        end

        --Check that the intention is the same as the account intention
        if (message.message ~= accountData.intention) then
            --If the intention is not the same, then send a message to the client to disconnect
            cryptoNET.send(socket, "disconnect")
        else
            --If the intention is the same, then send a message to the client to activate
            cryptoNET.send(socket, "activate")

            --Set the processor status to processing
            for i = 1, #Processors do
                if (Processors[i].id == accountData.intention) then
                    Processors[i].status = self.processorStatus.ready
                    break
                end
            end

            --Update the processor states
            _updateProcessorStates(self, Monitors, Processors)
        end

        --If the type is status, then update the status of the relevant processor
    elseif (message.type == "status") then
        --Get the socket username
        local username = socket.username

        --Get the account data for the socket username
        local accountData = _getAccountData(self, AccountData, username)

        --If the account data is nil, then the account does not exist, so return
        if (accountData == nil) then
            return
        end

        --Get the processor ID
        local processorId = accountData.intention

        --Convert the status to a number
        local status = self.processorStatusToNumber(message.message)

        --Update the status of the relevant processor
        for i = 1, #Processors do
            if (Processors[i].id == processorId) then
                Processors[i].status = status
                break
            end
        end

        --Update the processor states
        _updateProcessorStates(self, Monitors, Processors)
    end
end

--Plain Message Received Event Handler
function HostController:plainMessageBehaviour(message, socket, server)
end

--Login Event Handler
function HostController:loginBehaviour(username, socket, server)
    --Get the account data
    local accountData = _getAccountData(self, AccountData, username)

    --If the account data is nil, then the account does not exist, so return
    if (accountData == nil) then
        return
    end

    --Process the intention
    --Temporarily, just print the intention
    print(accountData.intention)

    --Send a request to the client to get the intention
    cryptoNET.send(socket, "get_intention")
end

--Login Failed Event Handler
function HostController:loginFailedBehaviour(username, socket, server)
end

--Logout Event Handler
function HostController:logoutBehaviour(username, socket, server)
end

--Key Up Event Handler
function HostController:keyUpBehaviour(key)
    --If the key is "t", then accept input from the terminal
    if (key == keys.t) then
        print("T key pressed, accepting input from terminal")
        self._freezeKeyInput = true

        --Print available commands
        print("Available commands:")
        print("createServiceAccount [username] [password] [intention]")
        print("cancel")

        local input = read()
        
        --Split the input into a list of words, separated by spaces
        local inputWords = {}
        for word in input:gmatch("([^%s]+)") do table.insert(inputWords, word) end

        --If the first word is "createServiceAccount", then call the createServiceAccount function
        if (inputWords[1] == "createServiceAccount") then
            --Check that the input is valid
            if (#inputWords ~= 4) then
                print("Invalid input")
                self._freezeKeyInput = false
                return
            end

            --Call the createServiceAccount function
            local success = _createServiceAccount(self, inputWords[2], inputWords[3], inputWords[4], HostSocket)

            --If the account was created successfully, print a success message
            if (success) then
                print("Account created successfully")
            else
                print("Account creation failed")
            end
        
        --If the first word is "cancel", then cancel the terminal input
        elseif (inputWords[1] == "cancel") then
            print("Terminal input cancelled")
        else
            print("Invalid input")
        end

        self._freezeKeyInput = false
    end
end

--Terminate Event Handler
function HostController:terminateBehaviour()
end
--endregion

--region Main Code
function HostController:startServer()
    
    --For each monitor, calculate the size of the screen and store it in a list, split into width and height
    local monitorSizes = {}
    for i = 1, #Monitors do
        monitorSizes[i] = { Monitors[i].getSize() }
    end

    --For each monitor, calculate the midpoint of both the width and height and store it in a list, split into x and y
    local monitorMidpoints = {}
    for i = 1, #Monitors do
        monitorMidpoints[i] = { math.floor(monitorSizes[i][1] / 2), math.floor(monitorSizes[i][2] / 2) }
    end

    --Set all Monitors to have grey background and white text
    for i = 1, #Monitors do
        Monitors[i].setTextColor(colors.white)
        Monitors[i].setBackgroundColor(colors.gray)

        --Clear the screen to make sure colours are applied
        Monitors[i].clear()
    end

    --Place the word "BankSys" in the top middle of the screens
    for i = 1, #Monitors do
        Monitors[i].setCursorPos(monitorMidpoints[i][1] - 2, 1)
        Monitors[i].write("BankSys")

        --Below the word "BankSys", place the word "Control" in the middle of the screen
        Monitors[i].setCursorPos(monitorMidpoints[i][1] - 2, 2)
        Monitors[i].write("Control")
    end

    --On the left, place the word "Status"
    for i = 1, #Monitors do
        Monitors[i].setCursorPos(1, 3)
        Monitors[i].write("Status")
    end

    _updateNetworkStatus(self, Monitors, self.networkStatus.preparing)

    _updateDatabaseStatus(self, Monitors, self.networkStatus.offline)

    _updateProcessorStates(self, Monitors, Processors)

    --local mainFrame = basalt.createFrame()
    --local button = mainFrame:addButton():setText("Test")

    --basalt.autoUpdate()

    cryptoNET.startEventLoop(onNetworkStartup, onNetworkEventRaised)

    --endregion
end

return HostController
