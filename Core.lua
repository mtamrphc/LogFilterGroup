-- LogFilterGroup Core
print("DEBUG: Core.lua is loading...")
LogFilterGroup = {}
LogFilterGroup.lfmMessages = {}  -- Looking for more (forming groups)
LogFilterGroup.lfgMessages = {}  -- Looking for group (players seeking groups)
LogFilterGroup.professionMessages = {}
LogFilterGroup.lastUpdate = 0
LogFilterGroup.mainWindowMinimized = false
LogFilterGroup.mainWindowMinimizedTab = nil  -- Track which tab was active when main window minimized
LogFilterGroup.poppedOutTabs = {}  -- Track which tabs are popped out (not persisted across sessions)
print("DEBUG: Core.lua basic initialization done")

-- Database defaults
local defaults = {
    lfmMessages = {},
    lfgMessages = {},
    professionMessages = {},
    autoSendWhisper = false,
    whisperMessageLFM = "inv",
    whisperMessageProfession = "How much?",
    filterTextLFM = "",
    filterTextProfession = "",
    excludeTextLFM = "",
    excludeTextProfession = ""
}

-- Initialize addon
function LogFilterGroup:Initialize()
    -- Initialize saved variables
    if not LogFilterGroupDB then
        LogFilterGroupDB = defaults
    end

    -- Clear all messages on load
    self.lfmMessages = {}
    self.lfgMessages = {}
    self.professionMessages = {}

    -- Load settings (but NOT messages - we want fresh start each load)
    self.autoSendWhisper = LogFilterGroupDB.autoSendWhisper or false
    self.whisperMessageLFM = LogFilterGroupDB.whisperMessageLFM or "inv"
    self.whisperMessageProfession = LogFilterGroupDB.whisperMessageProfession or "How much?"
    self.filterTextLFM = LogFilterGroupDB.filterTextLFM or ""
    self.filterTextProfession = LogFilterGroupDB.filterTextProfession or ""
    self.excludeTextLFM = LogFilterGroupDB.excludeTextLFM or ""
    self.excludeTextProfession = LogFilterGroupDB.excludeTextProfession or ""

    -- Save the cleared state
    self:SaveData()

    print("LogFilterGroup loaded! Type /lfg to open the interface.")
end

-- Clean messages older than 5 minutes
function LogFilterGroup:CleanOldMessages()
    local currentTime = time()
    local maxAge = 300 -- 5 minutes
    local cleaned = false

    -- Clean LFM messages
    for sender, data in pairs(self.lfmMessages) do
        if currentTime - data.timestamp > maxAge then
            self.lfmMessages[sender] = nil
            cleaned = true
        end
    end

    -- Clean LFG messages
    for sender, data in pairs(self.lfgMessages) do
        if currentTime - data.timestamp > maxAge then
            self.lfgMessages[sender] = nil
            cleaned = true
        end
    end

    -- Clean profession messages
    for sender, data in pairs(self.professionMessages) do
        if currentTime - data.timestamp > maxAge then
            self.professionMessages[sender] = nil
            cleaned = true
        end
    end

    if cleaned then
        self:SaveData()

        -- Update main window if visible
        if LogFilterGroupFrame and LogFilterGroupFrame:IsVisible() then
            self:UpdateDisplay()
        end

        -- Update separate windows if visible
        if LogFilterGroupLFMWindow and LogFilterGroupLFMWindow:IsVisible() then
            self:UpdateSeparateWindow("lfm")
        end
        if LogFilterGroupLFGWindow and LogFilterGroupLFGWindow:IsVisible() then
            self:UpdateSeparateWindow("lfg")
        end
        if LogFilterGroupProfessionWindow and LogFilterGroupProfessionWindow:IsVisible() then
            self:UpdateSeparateWindow("profession")
        end
    end
end

-- Add or update an LFM message (looking for more)
function LogFilterGroup:AddLFMMessage(sender, message)
    self.lfmMessages[sender] = {
        message = message,
        timestamp = time()
    }
    self:SaveData()

    -- Restore main window if minimized and this was the active tab
    if self.mainWindowMinimized and self.mainWindowMinimizedTab == "lfm" and LogFilterGroupFrame then
        self:RestoreMainWindow()
    end

    -- Don't auto-restore minimized separate windows
    -- if LogFilterGroupLFMWindow and LogFilterGroupLFMWindow.isMinimized then
    --     self:RestoreSeparateWindow("lfm")
    -- end

    if LogFilterGroupFrame and LogFilterGroupFrame:IsVisible() then
        self:UpdateDisplay()
    end

    -- Update separate window if open
    if LogFilterGroupLFMWindow and LogFilterGroupLFMWindow:IsVisible() then
        self:UpdateSeparateWindow("lfm")
    end
end

-- Add or update an LFG message (looking for group)
function LogFilterGroup:AddLFGMessage(sender, message)
    self.lfgMessages[sender] = {
        message = message,
        timestamp = time()
    }
    self:SaveData()

    -- Restore main window if minimized and this was the active tab
    if self.mainWindowMinimized and self.mainWindowMinimizedTab == "lfg" and LogFilterGroupFrame then
        self:RestoreMainWindow()
    end

    -- Don't auto-restore minimized separate windows
    -- if LogFilterGroupLFGWindow and LogFilterGroupLFGWindow.isMinimized then
    --     self:RestoreSeparateWindow("lfg")
    -- end

    if LogFilterGroupFrame and LogFilterGroupFrame:IsVisible() then
        self:UpdateDisplay()
    end

    -- Update separate window if open
    if LogFilterGroupLFGWindow and LogFilterGroupLFGWindow:IsVisible() then
        self:UpdateSeparateWindow("lfg")
    end
end

-- Add or update a profession message
function LogFilterGroup:AddProfessionMessage(sender, message)
    self.professionMessages[sender] = {
        message = message,
        timestamp = time()
    }
    self:SaveData()

    -- Restore main window if minimized and this was the active tab
    if self.mainWindowMinimized and self.mainWindowMinimizedTab == "profession" and LogFilterGroupFrame then
        self:RestoreMainWindow()
    end

    -- Don't auto-restore minimized separate windows
    -- if LogFilterGroupProfessionWindow and LogFilterGroupProfessionWindow.isMinimized then
    --     self:RestoreSeparateWindow("profession")
    -- end

    if LogFilterGroupFrame and LogFilterGroupFrame:IsVisible() then
        self:UpdateDisplay()
    end

    -- Update separate window if open
    if LogFilterGroupProfessionWindow and LogFilterGroupProfessionWindow:IsVisible() then
        self:UpdateSeparateWindow("profession")
    end
end

-- Save data to saved variables
function LogFilterGroup:SaveData()
    LogFilterGroupDB.lfmMessages = self.lfmMessages
    LogFilterGroupDB.lfgMessages = self.lfgMessages
    LogFilterGroupDB.professionMessages = self.professionMessages
end

-- Save settings to saved variables
function LogFilterGroup:SaveSettings()
    LogFilterGroupDB.autoSendWhisper = self.autoSendWhisper
    LogFilterGroupDB.whisperMessageLFM = self.whisperMessageLFM
    LogFilterGroupDB.whisperMessageProfession = self.whisperMessageProfession
    LogFilterGroupDB.filterTextLFM = self.filterTextLFM
    LogFilterGroupDB.filterTextProfession = self.filterTextProfession
    LogFilterGroupDB.excludeTextLFM = self.excludeTextLFM
    LogFilterGroupDB.excludeTextProfession = self.excludeTextProfession
end

-- Get time ago string
function LogFilterGroup:GetTimeAgo(timestamp)
    local diff = time() - timestamp
    
    if diff < 60 then
        return diff .. "s ago"
    elseif diff < 3600 then
        return math.floor(diff / 60) .. "m ago"
    else
        return math.floor(diff / 3600) .. "h ago"
    end
end

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")  -- All numbered channels (General, Trade, World, LocalDefense, etc.)
eventFrame:RegisterEvent("CHAT_MSG_YELL")
eventFrame:RegisterEvent("CHAT_MSG_SAY")
eventFrame:RegisterEvent("CHAT_MSG_GUILD")
eventFrame:RegisterEvent("CHAT_MSG_OFFICER")
eventFrame:RegisterEvent("CHAT_MSG_PARTY")
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "LogFilterGroup" then
        LogFilterGroup:Initialize()
        -- Start cleanup timer
        eventFrame:SetScript("OnUpdate", function()
            local currentTime = time()
            if not LogFilterGroup.lastCleanup then
                LogFilterGroup.lastCleanup = currentTime
            end
            -- Run cleanup every 30 seconds
            if currentTime - LogFilterGroup.lastCleanup >= 30 then
                LogFilterGroup:CleanOldMessages()
                LogFilterGroup.lastCleanup = currentTime
            end
        end)
    elseif event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_SAY" or event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER" or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID" then
        local message = arg1
        local sender = arg2

        -- Remove server name from sender
        if sender and string.find(sender, "-") then
            sender = string.gsub(sender, "%-.*", "")
        end

        if message and sender then
            -- Debug output to help diagnose issues
            if event == "CHAT_MSG_YELL" or event == "CHAT_MSG_SAY" then
                DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup [" .. event .. "]: Checking message from " .. sender .. ": " .. message)
            end
            LogFilterGroup:ParseMessage(sender, message)
        end
    elseif event == "PLAYER_LOGOUT" then
        LogFilterGroup:SaveData()
    end
end)

-- Slash command
SLASH_LOGFILTERGROUP1 = "/lfg"
SlashCmdList["LOGFILTERGROUP"] = function(msg)
    if msg == "clear" then
        LogFilterGroup.lfmMessages = {}
        LogFilterGroup.lfgMessages = {}
        LogFilterGroup.professionMessages = {}
        LogFilterGroup:SaveData()
        print("LogFilterGroup: All messages cleared.")
        if LogFilterGroupFrame and LogFilterGroupFrame:IsVisible() then
            LogFilterGroup:UpdateDisplay()
        end
    elseif msg == "test" then
        -- Add test messages
        LogFilterGroup:AddLFMMessage("TestPlayer1", "LFM BRD need tank and healer")
        LogFilterGroup:AddLFMMessage("TestPlayer2", "LF2M SM Cath")
        LogFilterGroup:AddLFGMessage("TestPlayer3", "LFG Stratholme")
        LogFilterGroup:AddLFGMessage("TestPlayer4", "LFG UBRS as DPS")
        LogFilterGroup:AddProfessionMessage("TestCrafter1", "Blacksmith LFW, your mats, tips appreciated")
        LogFilterGroup:AddProfessionMessage("TestCrafter2", "WTS enchanting services, PST")
        LogFilterGroup:AddProfessionMessage("TestCrafter3", "LF alchemist for transmute")
        print("LogFilterGroup: Test messages added. Open /lfg to view.")
    elseif string.sub(msg, 1, 5) == "debug" then
        -- Toggle debug mode
        if not LogFilterGroup.debugMode then
            LogFilterGroup.debugMode = true
            print("LogFilterGroup: Debug mode ON")
        else
            LogFilterGroup.debugMode = false
            print("LogFilterGroup: Debug mode OFF")
        end
    else
        LogFilterGroup:ToggleFrame()
    end
end
