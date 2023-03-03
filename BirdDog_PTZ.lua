NamedControl.SetValue("activePreset", 00000)
local json             = require('json')
local irisMode         = NamedControl.GetValue("irisMode")
local focusMode        = NamedControl.GetPosition("focusMode")
local screenSaver      = NamedControl.GetPosition("screenSaver")
local screenSaverState = nil
local camSpeed         = NamedControl.GetValue("camSpeed")
local camSpeedValue    = nil
local irisModeValue    = irisMode
local focusModeValue   = focusMode
local isMoving         = false
local Connected        = false
local gotData          = false
local activeButton     = nil
local activePreset     = 0000
local dataTimer        = 0
local rebootTimer      = 0
local initiateTimer    = 0

NamedControl.SetPosition("Connected", 0)
NamedControl.SetText("hostName", "")

local Commands = {
    [1] = "01 00 00 0a 00 00 00 03 81 01 06 01 2a 2a 03 03 FF", -- panTiltStop
    [2] = "01 00 00 0a 00 00 00 03 81 01 04 07 00 FF", -- zoomStop
    [3] = "01 00 00 0a 00 00 00 03 81 01 04 08 00 FF", -- focusStop
    [4] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. camSpeed .. " 07 03 01 FF", -- Up
    [5] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. camSpeed .. " 07 03 02 FF", -- Down
    [6] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. camSpeed .. " 07 01 03 FF", -- Left
    [7] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. camSpeed .. " 07 02 03 FF", -- Right
    [8] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. camSpeed .. " 07 01 01 FF", -- upLeft
    [9] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. camSpeed .. " 07 02 01 FF", -- upRight
    [10] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. camSpeed .. " 07 01 02 FF", -- downleft
    [11] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. camSpeed .. " 07 02 02 FF", -- downRight
    [12] = "01 00 00 0a 00 00 00 03 81 01 04 07 02 FF", -- zoomIn
    [13] = "01 00 00 0a 00 00 00 03 81 01 04 07 03 FF", -- zoomOut
    [14] = "01 00 00 0a 00 00 00 03 81 01 04 08 02 FF", -- focusNear
    [15] = "01 00 00 0a 00 00 00 03 81 01 04 08 03 FF", -- focusFar
}

local Presets = {
    [1] = "01 00 00 0a 00 00 00 03 81 01 04 3F 02 00 FF",
    [2] = "01 00 00 0a 00 00 00 03 81 01 04 3F 02 01 FF",
    [3] = "01 00 00 0a 00 00 00 03 81 01 04 3F 02 02 FF",
    [4] = "01 00 00 0a 00 00 00 03 81 01 04 3F 02 03 FF",
    [5] = "01 00 00 0a 00 00 00 03 81 01 04 3F 02 04 FF",
    [6] = "01 00 00 0a 00 00 00 03 81 01 04 3F 02 05 FF",
    [7] = "01 00 00 0a 00 00 00 03 81 01 04 3F 02 06 FF",
    [8] = "01 00 00 0a 00 00 00 03 81 01 04 3F 02 07 FF",
    [9] = "01 00 00 0a 00 00 00 03 81 01 04 3F 02 08 FF"
}

local updatePresets = {
    [1] = "01 00 00 0a 00 00 00 03 81 01 04 3F 01 00 FF",
    [2] = "01 00 00 0a 00 00 00 03 81 01 04 3F 01 01 FF",
    [3] = "01 00 00 0a 00 00 00 03 81 01 04 3F 01 02 FF",
    [4] = "01 00 00 0a 00 00 00 03 81 01 04 3F 01 03 FF",
    [5] = "01 00 00 0a 00 00 00 03 81 01 04 3F 01 04 FF",
    [6] = "01 00 00 0a 00 00 00 03 81 01 04 3F 01 05 FF",
    [7] = "01 00 00 0a 00 00 00 03 81 01 04 3F 01 06 FF",
    [8] = "01 00 00 0a 00 00 00 03 81 01 04 3F 01 07 FF",
    [9] = "01 00 00 0a 00 00 00 03 81 01 04 3F 01 08 FF"

}

local Iris = {
    [1] = "01 00 00 0a 00 00 00 03 81 01 04 0B 00 FF", -- irisReset
    [2] = "01 00 00 0a 00 00 00 03 81 01 04 0B 02 FF", -- irisUp
    [3] = "01 00 00 0a 00 00 00 03 81 01 04 0B 03 FF" -- irisDown
}

local irisModes = {
    [1] = "01 00 00 0a 00 00 00 03 81 01 04 39 00 FF",
    [2] = "01 00 00 0a 00 00 00 03 81 01 04 39 03 FF",
    [3] = "01 00 00 0a 00 00 00 03 81 01 04 39 0A FF",
    [4] = "01 00 00 0a 00 00 00 03 81 01 04 39 0B FF"
}

local focusModes = {
    [1] = "01 00 00 0a 00 00 00 03 81 01 04 38 02 FF",
    [2] = "01 00 00 0a 00 00 00 03 81 01 04 38 03 FF"
}

local oneButtons = {
    updatePreset = "",
    autoWB = "01 00 00 0a 00 00 00 03 81 01 04 35 03 FF",
    autoAF = "01 00 00 0a 00 00 00 03 81 01 04 18 01 FF",
    Home = "01 00 00 0a 00 00 00 03 81 01 06 04 FF"
}

local numberOfControls = #Commands
local numberOfPresets  = #Presets
local numberOfIris     = #Iris

--- Convert hex <-> string
function string.fromhex(str)
    return (str:gsub('..', function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

function FormatCamSpeed(Value)

    if Value < 10 then
        Value = "0" .. Value
    end
    if Value == 10 then
        Value = "10"
    else Value = string.gsub(Value, ".0", "")
    end

    Commands[4] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. Value .. " 07 03 01 FF"
    Commands[5] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. Value .. " 07 03 02 FF"
    Commands[6] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. Value .. " 07 01 03 FF"
    Commands[7] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. Value .. " 07 02 03 FF"
    Commands[8] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. Value .. " 07 01 01 FF"
    Commands[9] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. Value .. " 07 02 01 FF"
    Commands[10] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. Value .. " 07 01 02 FF"
    Commands[11] = "01 00 00 0a 00 00 00 03 81 01 06 01 " .. Value .. " 07 02 02 FF"
end

function IsError(err)

    print(err)
    NamedControl.SetPosition("Connected", 0)
    NamedControl.SetText("Error", err)
    Connected = false

end

function HandleData(socket, packet)

    -- Info about receiving socket and packet
    --print("Socket ID: " .. socket.ID)
    --receivedIP, receivedPort = socket:GetSockName()
    --print("Socket IP: " .. receivedIP)
    --print("Socket Port: " .. receivedPort)
    --print("Packet IP: " .. packet.Address)
    --print("Packet Port: " .. packet.Port)
    --Do stuff with the received packet
    --print("Packet Data: \r" .. packet.Data)
    if packet.Data ~= nil then
        gotData = true
    end
end

function Initiate()

    function HostName_RequestResponse(Table, ReturnCode, Data, Error, Headers)

        print(Data)
        print(Table)
        print(ReturnCode)
        print(Error)
        print(Headers)
        if ReturnCode == 200 then
            NamedControl.SetText("hostName", Data)
            Connected = true
            gotData = true
            Rebooting = false
            NamedControl.SetPosition("Connected", 1)
        else
            IsError(Error)
        end
    end

    function HostName_Request()

        HttpClient.Upload({
            Url = NamedControl.GetText("IP") .. ":8080/hostname",
            Headers = { ["Accept"] = "text" },
            Data = "",
            Method = "GET",
            EventHandler = HostName_RequestResponse
        })
    end

    HostName_Request()
end

function SetScreenSaverResponse(Table, ReturnCode, Data, Error, Headers)

    -- print(Data)
    -- print(Table)
    -- print(ReturnCode)
    --print(Error)
    -- print(Headers)
    if ReturnCode == 200 then
        gotData = true
    else
        IsError(Error)
    end
end

function SetScreenSaver(State)

    if State == 1 then
        State = "Off"
    elseif State == 0 then
        State = "On"
    end

    local encodedJson = json.encode({ StreamToNetwork = State })

    HttpClient.Upload({
        Url = NamedControl.GetText("IP") .. ":8080/encodesetup?",
        Headers = { ["Content-Type"] = "application/json" },
        Data = encodedJson,
        Method = "POST",
        EventHandler = SetScreenSaverResponse
    })
end

function RebootResponse(Table, ReturnCode, Data, Error, Headers)

    -- print(Data)
    -- print(Table)
    -- print(ReturnCode)
    -- print(Error)
    -- print(Headers)
    if ReturnCode == 200 then
        gotData = true
    else
        IsError(Error)
    end
end

function Reboot(State)

    HttpClient.Upload({
        Url = NamedControl.GetText("IP") .. ":8080/" .. State,
        Headers = { ["Accept"] = "text" },
        Data = "",
        Method = "GET",
        EventHandler = RebootResponse
    })
    Rebooting = true
end

---------------------------------------------------------------------------------------------------

function Moving(Button, Off)

    if Off == "nil" then
        isMoving = false
        activeButton = nil
    end
    if Off == nil then
        isMoving = true
    end

    local removedSpaces = Commands[Button]:gsub('%s+', '')
    MyUdp:Send(NamedControl.GetText("IP"), 52381, string.fromhex(removedSpaces))
end

function SetPreset(Preset)

    for i = 1, 9 do
        if Preset == i then
            Controls.Outputs[i].Value = i
        else Controls.Outputs[i].Value = 0
        end
    end
    local removedSpaces = Presets[Preset]:gsub('%s+', '')
    MyUdp:Send(NamedControl.GetText("IP"), 52381, string.fromhex(removedSpaces))
end

function ChangeIris(Value)

    Value = Value + 1
    local removedSpaces = irisModes[Value]:gsub('%s+', '')
    MyUdp:Send(NamedControl.GetText("IP"), 52381, string.fromhex(removedSpaces))
end

function TimerClick()

    if not Connected and NamedControl.GetPosition("Connect") == 1 then
        Initiate()
        NamedControl.SetPosition("Connect", 0)
    end

    if Rebooting then
        rebootTimer = rebootTimer + 1
        if rebootTimer == 20 then
            rebootTimer = 0
            Initiate()
        end
    end

    if gotData then
        dataTimer = dataTimer + 1
        NamedControl.SetPosition("DataLed", 1)
        NamedControl.SetText("Error", "")

        if dataTimer == 8 then
            gotData = false
            dataTimer = 0
            NamedControl.SetPosition("DataLed", 0)
        end
    end

    if Connected and not Rebooting then
        irisMode    = NamedControl.GetValue("irisMode")
        focusMode   = NamedControl.GetValue("focusMode")
        screenSaver = NamedControl.GetPosition("screenSaver")
        camSpeed    = NamedControl.GetValue("camSpeed")

        if camSpeedValue ~= camSpeed then
            FormatCamSpeed(camSpeed)
            camSpeedValue = camSpeed
        end

        for i = 1, numberOfControls do
            if NamedControl.GetPosition("Button" .. i) == 1 and isMoving == false then
                Moving(i, nil)
                activeButton = i
            end
        end

        if activeButton ~= nil and NamedControl.GetPosition("Button" .. (activeButton)) == 0 and isMoving then
            if activeButton > 3 and activeButton < 12 then
                Moving(1, "nil")
            end
            if activeButton == 12 or activeButton == 13 then
                Moving(2, "nil")
            end
            if activeButton == 14 or 15 then
                Moving(3, "nil")
            end
        end

        for i = 1, numberOfPresets do
            if NamedControl.GetPosition("Preset" .. i) == 1 then
                SetPreset(i)
                activePreset = i
                NamedControl.SetValue("activePreset", activePreset)
                NamedControl.SetPosition("Preset" .. i, 0)
            end
        end

        for i = 1, numberOfIris do
            if NamedControl.GetPosition("Iris" .. i) == 1 then
                local removedSpaces = Iris[i]:gsub('%s+', '')
                MyUdp:Send(NamedControl.GetText("IP"), 52381, string.fromhex(removedSpaces))
                NamedControl.SetPosition("Iris" .. i, 0)
            end
        end

        if irisModeValue ~= irisMode then
            irisModeValue = irisMode
            ChangeIris(irisMode)
        end

        if focusModeValue ~= focusMode then
            focusModeValue = focusMode
            local removedSpaces = focusModes[focusMode + 1]:gsub('%s+', '')
            MyUdp:Send(NamedControl.GetText("IP"), 52381, string.fromhex(removedSpaces))
        end

        if screenSaverState ~= screenSaver then
            SetScreenSaver(screenSaver)
            screenSaverState = screenSaver
        end

        if NamedControl.GetPosition("Reboot") == 1 then
            Reboot("Reboot")
            NamedControl.SetPosition("Reboot", 0)
        end
        if NamedControl.GetPosition("Restart") == 1 then
            Reboot("Restart")
            NamedControl.SetPosition("Restart", 0)
        end

        for k, v in pairs(oneButtons) do
            if NamedControl.GetPosition(k) == 1 then
                local removedSpaces = nil
                if k == "updatePreset" then
                    removedSpaces = updatePresets[activePreset]:gsub('%s+', '')
                elseif k ~= "updatePreset" then
                    removedSpaces = v:gsub('%s+', '')
                end
                MyUdp:Send(NamedControl.GetText("IP"), 52381, string.fromhex(removedSpaces))
                NamedControl.SetPosition(k, 0)
            end
        end
    end
end

MyUdp = UdpSocket.New()
MyUdp:Open(Device.LocalUnit.ControlIP, 0)
MyUdp.Data = HandleData

MyTimer = Timer.New()
MyTimer.EventHandler = TimerClick
MyTimer:Start(.25)
