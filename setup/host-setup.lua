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
--The URL for the cryptoAPI (DO NOT CHANGE)
local _cryptoApiPaste = "https://raw.githubusercontent.com/SiliconSloth/CryptoNet/master/cryptoNet.lua" 
local cryptoApiFileName = "cryptoNET"

--The URL for the middleclass API (DO NOT CHANGE)
local _middleclassPaste = "https://raw.githubusercontent.com/kikito/middleclass/master/middleclass.lua"
local middleClassFileName = "middleclass"

--The URLs for controller class files (DO NOT CHANGE)
local controllerCorePaste = "https://raw.githubusercontent.com/007spy9/cc-banking/host-controller-v1/controller/controller.lua"
local controllerCoreName = "controller"

--The URL for the current controller implementation
local currentControllerPaste = "https://raw.githubusercontent.com/007spy9/cc-banking/host-controller-v1/controller/host_controller/host_controller.lua"
local currentControllerMainPaste = "https://raw.githubusercontent.com/007spy9/cc-banking/host-controller-v1/controller/host_controller/host_controller_main.lua"

local currentControllerFileName = "host_controller"
local currentControllerMainFileName = "host_controller_main"

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

--Write the word "Host Controller" in the middle of the screen
print("Host Controller")

--Set the cursor position to the middle of the screen, below the word "Host Controller"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 2)

--Write the word "Setup" in the middle of the screen
print("Setup")

sleep(2)

--Start by deleting existing files

--Delete the server certificate
fs.delete("BankNet.BankSys.Host.crt")
fs.delete("BankNet.BankSys.Host_private.key")

sleep(1)

--Clear the screen
term.clear()

--Set the cursor position to the middle of the screen
term.setCursorPos(math.floor(x / 2) - 5, math.floor(y / 2))

--Write the word "BankSys" in the middle of the screen
print("BankSys")

--Set the cursor position to the middle of the screen, below the word "BankSys"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 1)

--Write the word "Host Controller" in the middle of the screen
print("Host Controller")

--Set the cursor position to the middle of the screen, below the word "Host Controller"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 2)

--Write the word "Installing..." in the middle of the screen
print("Installing...")

--Delete the cryptoAPI
fs.delete(cryptoApiFileName)

--Delete the middleclass API
fs.delete(middleClassFileName)

--Delete the controller core
fs.delete(controllerCoreName)

--Delete the current controller implementation
fs.delete(currentControllerFileName)

--Delete the current controller main implementation
fs.delete(currentControllerMainFileName)

--Download the cryptoAPI into the root directory in the background
wget(_cryptoApiPaste, cryptoApiFileName)

--Download the middleclass API into the root directory in the background
wget(_middleclassPaste, middleClassFileName)

--Download the controller core into the root directory in the background
wget(controllerCorePaste, controllerCoreName)

--Download the current controller implementation into the root directory in the background
wget(currentControllerPaste, currentControllerFileName)

--Download the current controller main implementation into the root directory in the background
wget(currentControllerMainPaste, currentControllerMainFileName)

--Clear the screen
term.clear()

--Set the cursor position to the middle of the screen
term.setCursorPos(math.floor(x / 2) - 5, math.floor(y / 2))

--Write the word "BankSys" in the middle of the screen
print("BankSys")

--Set the cursor position to the middle of the screen, below the word "BankSys"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 1)

--Write the word "Host Controller" in the middle of the screen
print("Host Controller")

--Set the cursor position to the middle of the screen, below the word "Host Controller"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 2)

--Write the word "Configuring..." in the middle of the screen
print("Configuring...")

--TODO: Add code to configure the hostController

--Create a startup file to run the hostController on startup
local startupFile = fs.open("startup", "w")
startupFile.writeLine("shell.run(\"" .. currentControllerMainFileName .. "\")")
startupFile.close()

--Clear the screen
term.clear()

--Set the cursor position to the middle of the screen
term.setCursorPos(math.floor(x / 2) - 5, math.floor(y / 2))

--Write the word "BankSys" in the middle of the screen
print("BankSys")

--Set the cursor position to the middle of the screen, below the word "BankSys"
term.setCursorPos(math.floor(x / 2) - 7, math.floor(y / 2) + 1)

--Write the word "Host Controller" in the middle of the screen
print("Host Controller")

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