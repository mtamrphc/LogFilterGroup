-- LogFilterGroup Core
LogFilterGroup = {}
LogFilterGroup.tabs = {}  -- Dynamic tab system
LogFilterGroup.activeTabId = "lfm"  -- Currently active tab
LogFilterGroup.nextTabId = 1  -- Counter for generating unique custom tab IDs
LogFilterGroup.lastUpdate = 0
LogFilterGroup.mainWindowMinimized = false
LogFilterGroup.mainWindowMinimizedTab = nil  -- Track which tab was active when main window minimized
LogFilterGroup.debugMode = false  -- Debug mode off by default
LogFilterGroup.globalLocked = false  -- Global lock state for all filter inputs
LogFilterGroup.soundEnabled = true  -- Global sound notification toggle
LogFilterGroup.messageRepository = {}  -- Centralized message storage (eliminates duplication)
LogFilterGroup.nextMessageId = 1  -- Auto-incrementing ID for messages

-- Database defaults
local defaults = {
    globalLocked = false,
    soundEnabled = true,
    messageRepository = {},
    nextMessageId = 1,
    tabs = {
        {
            id = "lfm",
            name = "Find Group",
            messageRefs = {},  -- Changed from messages to messageRefs
            filterText = "",
            excludeText = "",
            whisperTemplate = "inv",
            autoSendWhisper = false,
            isDefault = true,
            locked = false,
            muted = false
        },
        {
            id = "lfg",
            name = "Find Member",
            messageRefs = {},  -- Changed from messages to messageRefs
            filterText = "",
            excludeText = "",
            whisperTemplate = "",
            autoSendWhisper = false,
            isDefault = true,
            locked = false,
            muted = false
        },
        {
            id = "profession",
            name = "Professions",
            messageRefs = {},  -- Changed from messages to messageRefs
            filterText = "",
            excludeText = "",
            whisperTemplate = "How much?",
            autoSendWhisper = false,
            isDefault = true,
            locked = false,
            muted = false
        }
    },
    activeTabId = "lfm",
    nextTabId = 1,

    -- Window position data
    mainFramePosition = nil,  -- Will store {point, xOfs, yOfs}
    mainFrameSize = nil,      -- Will store {width, height}
    tinyFramePosition = nil,  -- Will store {point, xOfs, yOfs}
    tinyFrameSize = nil        -- Will store {width, height}
}

-- Find tab by ID
function LogFilterGroup:GetTab(tabId)
    for _, tab in ipairs(self.tabs) do
        if tab.id == tabId then
            return tab
        end
    end
    return nil
end

-- Add new custom tab
function LogFilterGroup:AddTab(name)
    local newTab = {
        id = "custom_" .. self.nextTabId,
        name = name or ("Tab " .. self.nextTabId),
        messageRefs = {},  -- Changed from messages to messageRefs
        filterText = "",
        excludeText = "",
        whisperTemplate = "",
        autoSendWhisper = false,
        isDefault = false,
        locked = false,
        muted = false
    }
    table.insert(self.tabs, newTab)
    self.nextTabId = self.nextTabId + 1
    self:SaveSettings()
    return newTab
end

-- Delete custom tab (can't delete default tabs)
function LogFilterGroup:DeleteTab(tabId)
    local tab = self:GetTab(tabId)
    if not tab or tab.isDefault then
        return false
    end

    for i, t in ipairs(self.tabs) do
        if t.id == tabId then
            table.remove(self.tabs, i)
            -- If deleting active tab, switch to first tab
            if self.activeTabId == tabId then
                self.activeTabId = self.tabs[1].id
            end
            self:SaveSettings()
            return true
        end
    end
    return false
end

-- Initialize addon
function LogFilterGroup:Initialize()
    -- Initialize saved variables
    if not LogFilterGroupDB then
        LogFilterGroupDB = {}
    end

    -- Deep copy defaults for any missing fields
    for key, value in pairs(defaults) do
        if LogFilterGroupDB[key] == nil then
            if key == "tabs" then
                -- Deep copy tabs
                LogFilterGroupDB[key] = {}
                for i, tab in ipairs(value) do
                    LogFilterGroupDB[key][i] = {}
                    for k, v in pairs(tab) do
                        LogFilterGroupDB[key][i][k] = v
                    end
                end
            else
                LogFilterGroupDB[key] = value
            end
        end
    end

    -- Migrate old data structure if needed
    if LogFilterGroupDB.filterTextLFM then
        -- Old structure detected, migrate
        -- Ensure we have the default tab structure first
        if not LogFilterGroupDB.tabs or table.getn(LogFilterGroupDB.tabs) == 0 then
            LogFilterGroupDB.tabs = {}
            for i, tab in ipairs(defaults.tabs) do
                LogFilterGroupDB.tabs[i] = {}
                for k, v in pairs(tab) do
                    LogFilterGroupDB.tabs[i][k] = v
                end
            end
        end

        if not LogFilterGroupDB.tabs[1] then LogFilterGroupDB.tabs[1] = {} end
        if not LogFilterGroupDB.tabs[2] then LogFilterGroupDB.tabs[2] = {} end
        if not LogFilterGroupDB.tabs[3] then LogFilterGroupDB.tabs[3] = {} end

        LogFilterGroupDB.tabs[1].filterText = LogFilterGroupDB.filterTextLFM
        LogFilterGroupDB.tabs[2].filterText = LogFilterGroupDB.filterTextLFM
        LogFilterGroupDB.tabs[1].excludeText = LogFilterGroupDB.excludeTextLFM or ""
        LogFilterGroupDB.tabs[2].excludeText = LogFilterGroupDB.excludeTextLFM or ""
        LogFilterGroupDB.tabs[3].filterText = LogFilterGroupDB.filterTextProfession or ""
        LogFilterGroupDB.tabs[3].excludeText = LogFilterGroupDB.excludeTextProfession or ""
        LogFilterGroupDB.tabs[1].whisperTemplate = LogFilterGroupDB.whisperMessageLFM or "inv"
        LogFilterGroupDB.tabs[3].whisperTemplate = LogFilterGroupDB.whisperMessageProfession or "How much?"

        -- Clean up old fields
        LogFilterGroupDB.filterTextLFM = nil
        LogFilterGroupDB.filterTextProfession = nil
        LogFilterGroupDB.excludeTextLFM = nil
        LogFilterGroupDB.excludeTextProfession = nil
        LogFilterGroupDB.whisperMessageLFM = nil
        LogFilterGroupDB.whisperMessageProfession = nil
        LogFilterGroupDB.autoSendWhisper = nil
        LogFilterGroupDB.lfmMessages = nil
        LogFilterGroupDB.lfgMessages = nil
        LogFilterGroupDB.professionMessages = nil

        print("LogFilterGroup: Migrated settings from old version")
    end

    -- Load tabs (ensure at least default tabs exist)
    if not LogFilterGroupDB.tabs or table.getn(LogFilterGroupDB.tabs) == 0 then
        LogFilterGroupDB.tabs = {}
        for i, tab in ipairs(defaults.tabs) do
            LogFilterGroupDB.tabs[i] = {}
            for k, v in pairs(tab) do
                LogFilterGroupDB.tabs[i][k] = v
            end
        end
    end

    -- Load settings
    self.tabs = LogFilterGroupDB.tabs
    self.activeTabId = LogFilterGroupDB.activeTabId or "lfm"
    self.nextTabId = LogFilterGroupDB.nextTabId or 1
    self.globalLocked = LogFilterGroupDB.globalLocked or false
    self.soundEnabled = LogFilterGroupDB.soundEnabled
    if self.soundEnabled == nil then
        self.soundEnabled = true
    end
    self.messageRepository = LogFilterGroupDB.messageRepository or {}
    self.nextMessageId = LogFilterGroupDB.nextMessageId or 1

    -- Load window positions
    self.mainFramePosition = LogFilterGroupDB.mainFramePosition
    self.mainFrameSize = LogFilterGroupDB.mainFrameSize
    self.tinyFramePosition = LogFilterGroupDB.tinyFramePosition
    self.tinyFrameSize = LogFilterGroupDB.tinyFrameSize

    -- Migrate old message structure to new one (if needed)
    local migrated = false
    for _, tab in ipairs(self.tabs) do
        if tab.messages and not tab.messageRefs then
            -- Old structure detected, convert to new format
            if not migrated then
                print("LogFilterGroup: Migrating message storage to new format...")
                migrated = true
            end

            tab.messageRefs = {}

            for sender, data in pairs(tab.messages) do
                -- Create unique message ID
                local messageId = "msg_" .. self.nextMessageId
                self.nextMessageId = self.nextMessageId + 1

                -- Store message in central repository
                self.messageRepository[messageId] = {
                    sender = sender,
                    message = data.message,
                    timestamp = data.timestamp,
                    tabs = {[tab.id] = true}
                }

                -- Store per-tab metadata
                tab.messageRefs[messageId] = {
                    whispered = data.whispered or false,
                    invited = data.invited or false
                }
            end

            -- Remove old structure
            tab.messages = nil
        end
    end

    if migrated then
        LogFilterGroupDB.messageRepository = self.messageRepository
        LogFilterGroupDB.nextMessageId = self.nextMessageId
        print("LogFilterGroup: Migration complete!")
    end

    -- Clear old messages on load (start fresh each session)
    self.messageRepository = {}
    for _, tab in ipairs(self.tabs) do
        tab.messageRefs = {}
    end

    -- Save the cleared state
    self:SaveData()

    print("LogFilterGroup loaded! Type /lfg to open the interface.")
end

-- Clean messages older than 5 minutes
function LogFilterGroup:CleanOldMessages()
    local currentTime = time()
    local maxAge = 300  -- 5 minutes (300 seconds)
    local cleaned = false

    -- Clean central repository (single pass, no duplication)
    for messageId, msgData in pairs(self.messageRepository) do
        if currentTime - msgData.timestamp > maxAge then
            -- Remove from all tabs' reference lists
            for tabId, _ in pairs(msgData.tabs) do
                local tab = self:GetTab(tabId)
                if tab and tab.messageRefs then
                    tab.messageRefs[messageId] = nil
                end
            end

            -- Delete from central repository
            self.messageRepository[messageId] = nil
            cleaned = true
        end
    end

    if cleaned then
        self:SaveData()

        -- Update main window if visible
        if LogFilterGroupFrame and LogFilterGroupFrame:IsVisible() then
            self:UpdateDisplay()
        end
    end
end

-- Add or update a message in a specific tab
function LogFilterGroup:AddMessage(tabId, sender, message)
    local tab = self:GetTab(tabId)
    if not tab then
        return
    end

    -- Generate unique message ID (or find existing message from this sender)
    local messageId = nil

    -- Check if we already have a recent message from this sender with same content
    for id, msgData in pairs(self.messageRepository) do
        if msgData.sender == sender and msgData.message == message then
            messageId = id
            break
        end
    end

    -- Create new message in central repository if not found
    if not messageId then
        messageId = "msg_" .. self.nextMessageId
        self.nextMessageId = self.nextMessageId + 1

        self.messageRepository[messageId] = {
            sender = sender,
            message = message,
            timestamp = time(),
            tabs = {}  -- Track which tabs this message belongs to
        }
    end

    -- Add this tab to the message's tab list
    self.messageRepository[messageId].tabs[tabId] = true

    -- Store per-tab metadata (whispered/invited state) separately
    if not tab.messageRefs then
        tab.messageRefs = {}
    end

    if not tab.messageRefs[messageId] then
        tab.messageRefs[messageId] = {
            whispered = false,
            invited = false
        }
    end

    self:SaveData()

    -- Restore main window if minimized and this is the active tab
    if self.mainWindowMinimized and self.activeTabId == tabId and LogFilterGroupFrame then
        self:RestoreMainWindow()
    end

    -- Check if message passes filters and flash tab if needed
    if LogFilterGroupFrame then
        self:CheckAndFlashTab(tabId, sender, message)
    end

    -- Update display if frame exists
    if LogFilterGroupFrame and LogFilterGroupFrame:IsVisible() then
        self:UpdateDisplay()
    end

    -- Also update Tiny Mode if it's visible
    if LogFilterGroupTinyFrame and LogFilterGroupTinyFrame:IsVisible() then
        self:UpdateTinyDisplay()
    end
end

-- Save data to saved variables
function LogFilterGroup:SaveData()
    LogFilterGroupDB.tabs = self.tabs
    LogFilterGroupDB.messageRepository = self.messageRepository
    LogFilterGroupDB.nextMessageId = self.nextMessageId
end

-- Save settings to saved variables
function LogFilterGroup:SaveSettings()
    LogFilterGroupDB.tabs = self.tabs
    LogFilterGroupDB.activeTabId = self.activeTabId
    LogFilterGroupDB.nextTabId = self.nextTabId
    LogFilterGroupDB.globalLocked = self.globalLocked
    LogFilterGroupDB.soundEnabled = self.soundEnabled
    LogFilterGroupDB.messageRepository = self.messageRepository
    LogFilterGroupDB.nextMessageId = self.nextMessageId

    -- Save window positions
    LogFilterGroupDB.mainFramePosition = self.mainFramePosition
    LogFilterGroupDB.mainFrameSize = self.mainFrameSize
    LogFilterGroupDB.tinyFramePosition = self.tinyFramePosition
    LogFilterGroupDB.tinyFrameSize = self.tinyFrameSize
end

-- Save main frame position and size
function LogFilterGroup:SaveMainFramePosition()
    local frame = LogFilterGroupFrame
    if not frame then return end

    -- Get position
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    self.mainFramePosition = {
        point = point,
        xOfs = xOfs,
        yOfs = yOfs
    }

    -- Get size
    self.mainFrameSize = {
        width = frame:GetWidth(),
        height = frame:GetHeight()
    }

    self:SaveSettings()
end

-- Save tiny frame position and size
function LogFilterGroup:SaveTinyFramePosition()
    local frame = LogFilterGroupTinyFrame
    if not frame then return end

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    self.tinyFramePosition = {
        point = point,
        xOfs = xOfs,
        yOfs = yOfs
    }

    -- Save size
    self.tinyFrameSize = {
        width = frame:GetWidth(),
        height = frame:GetHeight()
    }

    self:SaveSettings()
end

-- Mark a message as whispered
function LogFilterGroup:MarkAsWhispered(tabId, sender)
    local tab = self:GetTab(tabId)
    if not tab or not tab.messageRefs then return end

    -- Find message from this sender in this tab
    for messageId, metadata in pairs(tab.messageRefs) do
        local msgData = self.messageRepository[messageId]
        if msgData and msgData.sender == sender then
            metadata.whispered = true
            self:SaveData()
            return
        end
    end
end

-- Mark a message as invited
function LogFilterGroup:MarkAsInvited(tabId, sender)
    local tab = self:GetTab(tabId)
    if not tab or not tab.messageRefs then return end

    -- Find message from this sender in this tab
    for messageId, metadata in pairs(tab.messageRefs) do
        local msgData = self.messageRepository[messageId]
        if msgData and msgData.sender == sender then
            metadata.invited = true
            self:SaveData()

            -- Track pending invite with timestamp
            if not self.pendingInvites then
                self.pendingInvites = {}
            end
            self.pendingInvites[sender] = time()
            return
        end
    end
end

-- Unmark a message as invited (when invite fails or is declined)
function LogFilterGroup:UnmarkAsInvited(tabId, sender)
    local tab = self:GetTab(tabId)
    if not tab or not tab.messageRefs then return end

    -- Find message from this sender in this tab
    for messageId, metadata in pairs(tab.messageRefs) do
        local msgData = self.messageRepository[messageId]
        if msgData and msgData.sender == sender then
            metadata.invited = false
            self:SaveData()

            -- Clear pending invite
            if self.pendingInvites then
                self.pendingInvites[sender] = nil
            end

            -- Update display if visible
            if LogFilterGroupFrame and LogFilterGroupFrame:IsVisible() then
                self:UpdateDisplay()
            end
            return
        end
    end
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
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")  -- System messages (invite declined, already in group, etc.)
eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")  -- Party member joins/leaves
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
    elseif event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_SAY" then
        local message = arg1
        local sender = arg2

        -- Remove server name from sender
        if sender and string.find(sender, "-") then
            sender = string.gsub(sender, "%-.*", "")
        end

        if message and sender then
            -- Skip addon communication messages using heuristic detection
            -- Addon messages typically: start with Identifier:data or Identifier.data,
            -- have very few spaces, and high density of numbers/delimiters
            local msgLen = string.len(message)
            local _, spaceCount = string.gsub(message, " ", " ")

            -- Check 1: Starts with identifier followed by colon/dot and data with no spaces
            -- Pattern like "ATW:1043:v" or "AddonData.456" - these are almost always addon messages
            if string.find(message, "^[A-Za-z_]+[:%.]%S") and spaceCount == 0 then
                return  -- Skip addon message (no human types "Word:stuff" with zero spaces)
            end

            if msgLen > 10 then
                -- Check 2: Starts with identifier:data pattern with very few spaces
                if string.find(message, "^[A-Za-z_]+[:%.]%S") then
                    -- If very few spaces relative to length, likely addon data
                    if spaceCount < 2 or (spaceCount < msgLen / 15) then
                        return  -- Skip likely addon message
                    end
                end

                -- Check 3: High density of numbers and delimiters (serialized data pattern)
                local _, numCount = string.gsub(message, "[0-9]", "0")
                local _, delimCount = string.gsub(message, "[:%.,%-]", ":")
                -- If more than 50% of message is numbers/delimiters with few spaces, likely addon data
                if (numCount + delimCount) > (msgLen * 0.5) and spaceCount < 3 then
                    return  -- Skip likely addon data
                end
            end

            -- Debug output to help diagnose issues
            if LogFilterGroup.debugMode and (event == "CHAT_MSG_YELL" or event == "CHAT_MSG_SAY") then
                DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup [" .. event .. "]: Checking message from " .. sender .. ": " .. message)
            end
            LogFilterGroup:ParseMessage(sender, message)
        end
    elseif event == "CHAT_MSG_SYSTEM" then
        -- Check for invite-related system messages
        local message = arg1
        if message and LogFilterGroup.pendingInvites then
            -- Parse player name from various system messages
            -- "Player is already in a group."
            -- "Player declines your group invitation."
            -- "No player named 'Player' is currently playing."
            -- "Player is ignoring you."

            local playerName = nil
            local _, _, name

            -- Pattern: "PlayerName is already in a group."
            _, _, name = string.find(message, "^(.+) is already in a group%.$")
            if name then
                playerName = name
            end

            if not playerName then
                -- Pattern: "PlayerName declines your group invitation."
                _, _, name = string.find(message, "^(.+) declines your group invitation%.$")
                if name then
                    playerName = name
                end
            end

            if not playerName then
                -- Pattern: "No player named 'PlayerName' is currently playing."
                _, _, name = string.find(message, "^No player named '(.+)' is currently playing%.$")
                if name then
                    playerName = name
                end
            end

            if not playerName then
                -- Pattern: "PlayerName is ignoring you."
                _, _, name = string.find(message, "^(.+) is ignoring you%.$")
                if name then
                    playerName = name
                end
            end

            if playerName and LogFilterGroup.pendingInvites[playerName] then
                -- Invite failed or was declined, unmark as invited
                LogFilterGroup:UnmarkAsInvited(LogFilterGroup.activeTabId, playerName)

                if LogFilterGroup.debugMode then
                    DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup: Invite to " .. playerName .. " failed/declined")
                end
            end
        end
    elseif event == "PARTY_MEMBERS_CHANGED" then
        -- Someone joined or left the party
        -- Clear old pending invites (they either joined or we know the result by now)
        if LogFilterGroup.pendingInvites then
            local currentTime = time()
            for sender, inviteTime in pairs(LogFilterGroup.pendingInvites) do
                -- Clear invites older than 60 seconds
                if currentTime - inviteTime > 60 then
                    LogFilterGroup.pendingInvites[sender] = nil
                end
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        LogFilterGroup:SaveData()
    end
end)

-- Slash command
SLASH_LOGFILTERGROUP1 = "/lfg"
SlashCmdList["LOGFILTERGROUP"] = function(msg)
    if msg == "clear" then
        LogFilterGroup.messageRepository = {}
        for _, tab in ipairs(LogFilterGroup.tabs) do
            tab.messageRefs = {}
        end
        LogFilterGroup:SaveData()
        print("LogFilterGroup: All messages cleared.")
        if LogFilterGroupFrame and LogFilterGroupFrame:IsVisible() then
            LogFilterGroup:UpdateDisplay()
        end
    elseif msg == "test" then
        -- Add test messages
        LogFilterGroup:AddMessage("lfm", "TestPlayer1", "LFM BRD need tank and healer")
        LogFilterGroup:AddMessage("lfm", "TestPlayer2", "LF2M SM Cath")
        LogFilterGroup:AddMessage("lfg", "TestPlayer3", "LFG Stratholme")
        LogFilterGroup:AddMessage("lfg", "TestPlayer4", "LFG UBRS as DPS")
        LogFilterGroup:AddMessage("profession", "TestCrafter1", "Blacksmith LFW, your mats, tips appreciated")
        LogFilterGroup:AddMessage("profession", "TestCrafter2", "WTS enchanting services, PST")
        LogFilterGroup:AddMessage("profession", "TestCrafter3", "LF alchemist for transmute")
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
