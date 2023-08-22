--Lua script to obtain the relevant pastebin code for the hostController

--This will install and configure the hostController
--#region Functions
local function wget(option, url, ziel)
    if type(url) ~= "string" and type(ziel) ~= "string" then
          return
    elseif type(option) == "string" and option ~= "-f" and type(url) == "string" then
          ziel = url
          url = option
    end
    if http.checkURL(url) then
          if fs.exists(ziel) and option ~= "-f" then
            printError("<Error> Target exists already")
            return
          else
            term.write("Downloading ... ")
            local timer = os.startTimer(60)
            http.request(url)
            while true do
                  local event, id, data = os.pullEvent()
                  if event == "http_success" then
                    print("success")
                    local f = io.open(ziel, "w")
                    f:write(data.readAll())
                    f:close()
                    data:close()
                    print("Saved as " .. ziel)
                    return true
                  elseif event == "timer" and timer == id then
                    printError("<Error> Timeout")
                    return
                  elseif event == "http_failure" then
                    printError("<Error> Download")
                    os.cancelAlarm(timer)
                    return
                  end
            end
          end
    else
          printError("<Error> URL")
          return
    end
  end
--#endregion

--#region Variables
--The pastebin code for the cryptoAPI
local cryptoApiPaste = "https://raw.githubusercontent.com/SiliconSloth/CryptoNet/master/cryptoNet.lua" 

 --The pastebin code for the controller
local controllerPaste = "fqiGtNA1"

local cryptoApiFileName = "cryptoNET"
local controllerFileName = "transit_controller"
local controllerConfigFileName = "transit_controller.cfg"
local systemName = "Transit Controller"
local serverHost = "BankNet.BankSys.Host"
local intention = "transit"
--#endregion

--#region Processing
--Set the background colour to blue
term.setBackgroundColor(colors.blue)

--Clear the screen
term.clear()

--Set the text colour to white
term.setTextColor(colors.white)

--Set the cursor position to the middle of the screen
local x,y = term.getSize()

term.setCursorPos(math.floor(x / 2) - 5, math.floor(y / 2))

--Write the word "BankSys" in the middle of the screen
print("BankSys")

--Set the cursor position to the middle of the screen, below the word "BankSys"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 1)

--Write the name of the system in the middle of the screen
print(systemName)

--Set the cursor position to the middle of the screen, below the word "Host Controller"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 2)

--Write the word "Setup" in the middle of the screen
print("Setup")

sleep(2)

--Start by deleting existing files
--Delete the cryptoAPI
fs.delete(cryptoApiFileName)

--Delete the controller
fs.delete(controllerFileName)

sleep(1)

--Clear the screen
term.clear()

--Set the cursor position to the middle of the screen
term.setCursorPos(math.floor(x / 2) - 5, math.floor(y / 2))

--Write the word "BankSys" in the middle of the screen
print("BankSys")

--Set the cursor position to the middle of the screen, below the word "BankSys"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 1)

--Write the name of the system in the middle of the screen
print(systemName)

--Set the cursor position to the middle of the screen, below the word "Host Controller"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 2)

--Write the word "Installing..." in the middle of the screen
print("Installing...")

--Download the cryptoAPI into the root directory in the background
wget(cryptoApiPaste, cryptoApiFileName)

--Download the hostController into the root directory in the background
shell.run("pastebin", "get", controllerPaste, controllerFileName)

--Clear the screen
term.clear()

--Set the cursor position to the middle of the screen
term.setCursorPos(math.floor(x / 2) - 5, math.floor(y / 2))

--Write the word "BankSys" in the middle of the screen
print("BankSys")

--Set the cursor position to the middle of the screen, below the word "BankSys"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 1)

--Write the word "Host Controller" in the middle of the screen
print(systemName)

--Set the cursor position to the middle of the screen, below the word "Host Controller"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 2)

--Write the word "Configuring..." in the middle of the screen
print("Configuring...")

--Request username and password for the system
print("Please enter the username for the system:")
local systemUsername = read()
print("Please enter the password for the system:")
local systemPassword = read("*")

--Create a configuration file
local configFile = fs.open(controllerConfigFileName, "w")

--Serialise the configuration into JSON
local config = {
    server = serverHost,
    systemName = systemName,
    systemUsername = systemUsername,
    systemPassword = systemPassword,
    intention = intention
}

local configText = textutils.serializeJSON(config)

--Write the configuration to the file
configFile.write(configText)

--Close the file
configFile.close()

--TODO: Add code to configure the controller

--Create a startup file to run the hostController on startup
local startupFile = fs.open("startup", "w")
startupFile.writeLine("shell.run(\"" .. controllerFileName .. "\")")
startupFile.close()

--Clear the screen
term.clear()

--Set the cursor position to the middle of the screen
term.setCursorPos(math.floor(x / 2) - 5, math.floor(y / 2))

--Write the word "BankSys" in the middle of the screen
print("BankSys")

--Set the cursor position to the middle of the screen, below the word "BankSys"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 1)

--Write the name of the system in the middle of the screen
print(systemName)

--Set the cursor position to the middle of the screen, below the word "Host Controller"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 2)

--Write the word "Complete!" in the middle of the screen
print("Complete!")

--Set the cursor position to the middle of the screen, below the word "Complete!"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 3)

--Write the word "Rebooting..." in the middle of the screen
print("Rebooting...")

sleep(2)

--Reboot the computer
os.reboot()
--#endregion