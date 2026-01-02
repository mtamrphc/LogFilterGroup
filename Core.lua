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
LogFilterGroup.syntaxPreviewEnabled = true  -- Show syntax preview pane in config window
LogFilterGroup.autoCloseParentheses = true  -- Auto-close parentheses in filter inputs

-- Utility function to strip titles and PVP ranks from player names
-- WoW 1.12 formats: "Private PlayerName", "Corporal PlayerName", "PlayerName the Explorer", etc.
local function StripPlayerTitle(fullName)
    if not fullName then
        return fullName
    end

    -- PVP ranks appear as prefixes: "Private Name", "Corporal Name", "Sergeant Name", etc.
    local pvpRanks = {
        "Private ", "Corporal ", "Sergeant ", "Master Sergeant ", "Sergeant Major ",
        "Knight ", "Knight%-Lieutenant ", "Knight%-Captain ", "Knight%-Champion ",
        "Lieutenant Commander ", "Commander ", "Marshal ", "Field Marshal ", "Grand Marshal ",
        "Scout ", "Grunt ", "Sergeant ", "Senior Sergeant ", "First Sergeant ",
        "Stone Guard ", "Blood Guard ", "Legionnaire ", "Centurion ", "Champion ",
        "Lieutenant General ", "General ", "Warlord ", "High Warlord "
    }

    local name = fullName

    -- Strip PVP rank prefix
    for _, rank in ipairs(pvpRanks) do
        if string.find(name, "^" .. rank) then
            name = string.gsub(name, "^" .. rank, "")
            break
        end
    end

    -- Strip title suffix (e.g., "the Explorer", "of Orgrimmar")
    -- Titles usually start with " the " or " of "
    name = string.gsub(name, " the .+$", "")
    name = string.gsub(name, " of .+$", "")

    return name
end

-- Database defaults
local defaults = {
    globalLocked = false,
    soundEnabled = true,
    inTinyMode = false,
    windowVisible = true,  -- Auto-open window on login
    syntaxPreviewEnabled = true,  -- Show syntax preview pane
    autoCloseParentheses = true,  -- Auto-close parentheses
    messageRepository = {},
    nextMessageId = 1,
    tabs = {
        {
            id = "lfm",
            name = "Find Group",
            messageRefs = {},  -- Changed from messages to messageRefs
            filterText = "lfm OR lf1m OR lf2m OR lf3m OR lf4m OR lf5m OR looking for more OR need more OR recruiting OR (lf tank) OR (lf heal) OR (lf dps) OR (lf rogue) OR (lf warrior) OR (lf mage) OR (lf priest) OR (lf warlock) OR (lf hunter) OR (lf druid) OR (lf paladin) OR (lf shaman)",
            excludeText = "",
            whisperTemplate = "inv",
            autoSendWhisper = false,
            isDefault = false,  -- Changed to false so it behaves like a custom tab
            locked = false,
            muted = false,
            showInTinyMode = true  -- Show in Tiny UI by default
        },
        {
            id = "lfg",
            name = "Find Member",
            messageRefs = {},  -- Changed from messages to messageRefs
            filterText = "lfg OR lf1g OR lf2g OR lf3g OR looking for group OR looking for raid OR seeking group",
            excludeText = "",
            whisperTemplate = "",
            autoSendWhisper = false,
            isDefault = false,  -- Changed to false so it behaves like a custom tab
            locked = false,
            muted = false,
            showInTinyMode = true  -- Show in Tiny UI by default
        },
        {
            id = "profession",
            name = "Professions",
            messageRefs = {},  -- Changed from messages to messageRefs
            filterText = "lfw OR lf work OR looking for work OR lfwork OR blacksmith OR tailor OR alchemist OR enchanter OR engineer OR leatherworker OR jewelcrafter OR inscription OR wts OR wtb OR wtt OR transmute OR enchanting OR recipe OR pattern OR formula OR craft OR crafting",
            excludeText = "",
            whisperTemplate = "How much?",
            autoSendWhisper = false,
            isDefault = false,  -- Changed to false so it behaves like a custom tab
            locked = false,
            muted = false,
            showInTinyMode = true  -- Show in Tiny UI by default
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
        muted = false,
        showInTinyMode = true  -- Show in Tiny UI by default
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

    -- Prevent deletion of the last tab
    if table.getn(self.tabs) <= 1 then
        print("LogFilterGroup: Cannot delete the last remaining tab!")
        return false
    end

    for i, t in ipairs(self.tabs) do
        if t.id == tabId then
            table.remove(self.tabs, i)
            -- If deleting active tab, switch to first tab
            if self.activeTabId == tabId then
                if self.tabs[1] then
                    self.activeTabId = self.tabs[1].id
                else
                    -- Fallback: create a default tab if somehow we have none
                    self:AddTab("New Tab")
                    self.activeTabId = self.tabs[1].id
                end
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

    -- Initialize shared character data storage
    if not LogFilterGroupShared then
        LogFilterGroupShared = { characters = {} }
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

    -- Migrate default tabs to pre-configured filter-based tabs
    if LogFilterGroupDB.tabs and table.getn(LogFilterGroupDB.tabs) >= 3 then
        local needsMigration = false

        -- Check if any of the first 3 tabs still have isDefault = true
        for i = 1, 3 do
            if LogFilterGroupDB.tabs[i] and LogFilterGroupDB.tabs[i].isDefault == true then
                needsMigration = true
                break
            end
        end

        if needsMigration then
            -- Migrate the three default tabs to pre-configured custom tabs with filters
            local filterConfigs = {
                {
                    id = "lfm",
                    filterText = "lfm OR lf1m OR lf2m OR lf3m OR lf4m OR lf5m OR looking for more OR need more OR recruiting OR (lf tank) OR (lf heal) OR (lf dps) OR (lf rogue) OR (lf warrior) OR (lf mage) OR (lf priest) OR (lf warlock) OR (lf hunter) OR (lf druid) OR (lf paladin) OR (lf shaman)"
                },
                {
                    id = "lfg",
                    filterText = "lfg OR lf1g OR lf2g OR lf3g OR looking for group OR looking for raid OR seeking group"
                },
                {
                    id = "profession",
                    filterText = "lfw OR lf work OR looking for work OR lfwork OR blacksmith OR tailor OR alchemist OR enchanter OR engineer OR leatherworker OR jewelcrafter OR inscription OR wts OR wtb OR wtt OR transmute OR enchanting OR recipe OR pattern OR formula OR craft OR crafting"
                }
            }

            for i = 1, 3 do
                if LogFilterGroupDB.tabs[i] and LogFilterGroupDB.tabs[i].id == filterConfigs[i].id then
                    -- Only update if filterText is empty (user hasn't customized it yet)
                    if not LogFilterGroupDB.tabs[i].filterText or LogFilterGroupDB.tabs[i].filterText == "" then
                        LogFilterGroupDB.tabs[i].filterText = filterConfigs[i].filterText
                    end
                    -- Change isDefault to false so it behaves like a custom tab
                    LogFilterGroupDB.tabs[i].isDefault = false
                end
            end

            print("LogFilterGroup: Migrated default tabs to pre-configured filter-based tabs")
        end
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
    self.inTinyMode = LogFilterGroupDB.inTinyMode or false
    self.syntaxPreviewEnabled = LogFilterGroupDB.syntaxPreviewEnabled
    if self.syntaxPreviewEnabled == nil then
        self.syntaxPreviewEnabled = true
    end
    self.autoCloseParentheses = LogFilterGroupDB.autoCloseParentheses
    if self.autoCloseParentheses == nil then
        self.autoCloseParentheses = true
    end
    self.messageRepository = LogFilterGroupDB.messageRepository or {}
    self.nextMessageId = LogFilterGroupDB.nextMessageId or 1

    -- Ensure all tabs have showInTinyMode field (migration for existing data)
    for _, tab in ipairs(self.tabs) do
        if tab.showInTinyMode == nil then
            tab.showInTinyMode = true  -- Default to showing in Tiny UI
        end
    end

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

    -- Auto-open window if it was visible when last logged out
    local windowVisible = LogFilterGroupDB.windowVisible
    if windowVisible == nil then
        windowVisible = true  -- Default to open on first run
    end

    if windowVisible then
        -- Delay showing the frame until after login is fully complete
        -- This ensures all UI elements are properly initialized
        local loginFrame = CreateFrame("Frame")
        loginFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        loginFrame:SetScript("OnEvent", function()
            if LogFilterGroup.inTinyMode then
                LogFilterGroup:ShowTinyFrame()
            else
                LogFilterGroup:ShowFrame()
            end
            loginFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
        end)
    end

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
    else
        -- Update timestamp for existing message (duplicate message sent again)
        self.messageRepository[messageId].timestamp = time()
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
    -- Call this if either frame exists (main or tiny)
    if LogFilterGroupFrame or LogFilterGroupTinyFrame then
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
    -- Don't save if we're in clone preview mode
    if self.pendingClone then
        return
    end

    LogFilterGroupDB.tabs = self.tabs
    LogFilterGroupDB.messageRepository = self.messageRepository
    LogFilterGroupDB.nextMessageId = self.nextMessageId
end

-- Save settings to saved variables
function LogFilterGroup:SaveSettings()
    -- Don't save if we're in clone preview mode
    if self.pendingClone then
        return
    end

    LogFilterGroupDB.tabs = self.tabs
    LogFilterGroupDB.activeTabId = self.activeTabId
    LogFilterGroupDB.nextTabId = self.nextTabId
    LogFilterGroupDB.globalLocked = self.globalLocked
    LogFilterGroupDB.soundEnabled = self.soundEnabled
    LogFilterGroupDB.inTinyMode = self.inTinyMode
    LogFilterGroupDB.syntaxPreviewEnabled = self.syntaxPreviewEnabled
    LogFilterGroupDB.autoCloseParentheses = self.autoCloseParentheses
    LogFilterGroupDB.messageRepository = self.messageRepository
    LogFilterGroupDB.nextMessageId = self.nextMessageId

    -- Save window visibility state based on current frame visibility
    if LogFilterGroupTinyFrame and LogFilterGroupTinyFrame:IsShown() then
        LogFilterGroupDB.windowVisible = true
    elseif LogFilterGroupFrame and LogFilterGroupFrame:IsShown() then
        LogFilterGroupDB.windowVisible = true
    else
        LogFilterGroupDB.windowVisible = false
    end

    -- Save window positions
    LogFilterGroupDB.mainFramePosition = self.mainFramePosition
    LogFilterGroupDB.mainFrameSize = self.mainFrameSize
    LogFilterGroupDB.tinyFramePosition = self.tinyFramePosition
    LogFilterGroupDB.tinyFrameSize = self.tinyFrameSize

    -- Auto-export to shared storage for cross-character cloning
    local characterKey = UnitName("player") .. "-" .. GetRealmName()

    if not LogFilterGroupShared then
        LogFilterGroupShared = { characters = {} }
    end

    -- Deep copy tabs (excluding messageRefs since we don't want to clone messages)
    local tabsCopy = {}
    for i, tab in ipairs(self.tabs) do
        tabsCopy[i] = {
            id = tab.id,
            name = tab.name,
            filterText = tab.filterText,
            excludeText = tab.excludeText,
            whisperTemplate = tab.whisperTemplate,
            autoSendWhisper = tab.autoSendWhisper,
            isDefault = tab.isDefault,
            locked = tab.locked,
            muted = tab.muted,
            showInTinyMode = tab.showInTinyMode
            -- Intentionally exclude messageRefs - we don't clone messages
        }
    end

    LogFilterGroupShared.characters[characterKey] = {
        lastUpdated = time(),
        tabs = tabsCopy,
        settings = {
            globalLocked = self.globalLocked,
            soundEnabled = self.soundEnabled,
            syntaxPreviewEnabled = self.syntaxPreviewEnabled,
            autoCloseParentheses = self.autoCloseParentheses
        }
    }
end

-- Get list of available characters to clone settings from
function LogFilterGroup:GetAvailableCharacters()
    if not LogFilterGroupShared or not LogFilterGroupShared.characters then
        return {}
    end

    local currentChar = UnitName("player") .. "-" .. GetRealmName()
    local available = {}

    for charKey, charData in pairs(LogFilterGroupShared.characters) do
        -- Skip current character
        if charKey ~= currentChar then
            -- Check if character has non-default tabs
            if charData.tabs and table.getn(charData.tabs) > 0 then
                table.insert(available, {
                    key = charKey,
                    lastUpdated = charData.lastUpdated or 0
                })
            end
        end
    end

    return available
end

-- Clone settings from another character
function LogFilterGroup:CloneFromCharacter(characterKey)
    local charData = LogFilterGroupShared.characters[characterKey]
    if not charData then
        print("LogFilterGroup: Character data not found")
        return
    end

    -- First, backup current tabs and settings (in case user cancels)
    if not self.preCloneBackup then
        -- Deep copy current tabs
        local backupTabs = {}
        for i, tab in ipairs(self.tabs) do
            backupTabs[i] = {}
            for k, v in pairs(tab) do
                if type(v) == "table" then
                    backupTabs[i][k] = {}
                    for k2, v2 in pairs(v) do
                        backupTabs[i][k][k2] = v2
                    end
                else
                    backupTabs[i][k] = v
                end
            end
        end

        self.preCloneBackup = {
            tabs = backupTabs,
            settings = {
                globalLocked = self.globalLocked,
                soundEnabled = self.soundEnabled,
                syntaxPreviewEnabled = self.syntaxPreviewEnabled,
                autoCloseParentheses = self.autoCloseParentheses
            }
        }
    end

    -- Deep copy tabs to pending clone data (don't apply yet)
    local clonedTabs = {}
    for i, tab in ipairs(charData.tabs) do
        clonedTabs[i] = {}
        for k, v in pairs(tab) do
            if type(v) == "table" then
                clonedTabs[i][k] = {}
                for k2, v2 in pairs(v) do
                    clonedTabs[i][k][k2] = v2
                end
            else
                clonedTabs[i][k] = v
            end
        end
        -- Initialize empty messageRefs for display
        clonedTabs[i].messageRefs = {}
    end

    -- Store cloned data in pending state
    self.pendingClone = {
        tabs = clonedTabs,
        settings = {
            globalLocked = charData.settings.globalLocked or false,
            soundEnabled = charData.settings.soundEnabled,
            syntaxPreviewEnabled = charData.settings.syntaxPreviewEnabled,
            autoCloseParentheses = charData.settings.autoCloseParentheses
        },
        sourceCharacter = characterKey
    }

    -- Apply pending clone settings to config window for preview
    if LogFilterGroupConfigFrame then
        -- Temporarily override tabs for config window display
        self.configPreviewTabs = clonedTabs
        self.configTabIndex = 1  -- Reset to first tab
        self:UpdateConfigureWindow()
    end

    print("LogFilterGroup: Cloned settings from " .. characterKey .. " - Click Save to keep changes")
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
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  -- For auto-export after player data is available
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")  -- All numbered channels (General, Trade, World, LocalDefense, etc.)
eventFrame:RegisterEvent("CHAT_MSG_YELL")
eventFrame:RegisterEvent("CHAT_MSG_SAY")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")  -- Incoming whispers
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
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Auto-export settings when player data is available
        -- This ensures UnitName and GetRealmName return valid values
        if not LogFilterGroup.hasExportedOnLogin then
            LogFilterGroup:SaveSettings()
            LogFilterGroup.hasExportedOnLogin = true

            -- Debug output
            local charKey = UnitName("player") .. "-" .. GetRealmName()
            print("LogFilterGroup: Exported settings for " .. charKey)
        end
    elseif event == "CHAT_MSG_CHANNEL" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_SAY" or event == "CHAT_MSG_WHISPER" then
        local message = arg1
        local sender = arg2

        -- Remove server name from sender
        if sender and string.find(sender, "-") then
            sender = string.gsub(sender, "%-.*", "")
        end

        -- Strip titles and PVP ranks from sender name
        sender = StripPlayerTitle(sender)

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
            if LogFilterGroup.debugMode and (event == "CHAT_MSG_YELL" or event == "CHAT_MSG_SAY" or event == "CHAT_MSG_WHISPER") then
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
        LogFilterGroup:SaveSettings()  -- Ensure shared export is saved
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
    elseif msg == "status" then
        -- Show current status
        print("LogFilterGroup Status:")
        print("  In Tiny Mode: " .. tostring(LogFilterGroup.inTinyMode))
        print("  Sound Enabled: " .. tostring(LogFilterGroup.soundEnabled))
        print("  Active Tab: " .. tostring(LogFilterGroup.activeTabId))
        local tab = LogFilterGroup:GetTab(LogFilterGroup.activeTabId)
        if tab then
            print("  Tab Name: " .. tostring(tab.name))
            print("  Tab Muted: " .. tostring(tab.muted))
            print("  Tab showInTinyMode: " .. tostring(tab.showInTinyMode))
        end
    elseif msg == "resetui" then
        -- Force recreate UI frames
        if LogFilterGroupConfigFrame then
            LogFilterGroupConfigFrame:Hide()
            LogFilterGroupConfigFrame = nil
        end
        print("LogFilterGroup: UI frames reset. Config window will be recreated on next open.")
    else
        LogFilterGroup:ToggleFrame()
    end
end
