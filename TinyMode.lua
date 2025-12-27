-- Tiny Mode UI for LogFilterGroup
-- Compact view showing only player names with W/I/X buttons

local TINY_ROW_HEIGHT = 20
local TINY_ROWS_VISIBLE = 10

-- NOTE: MatchesFilter and MatchesExclude are defined in UI.lua as LogFilterGroup.MatchesFilter and LogFilterGroup.MatchesExclude
-- We use the same filter logic as the Main UI to ensure consistent behavior

-- Create or get tiny mode frame
function LogFilterGroup:CreateTinyModeFrame()
    if LogFilterGroupTinyFrame then
        return LogFilterGroupTinyFrame
    end

    local frame = CreateFrame("Frame", "LogFilterGroupTinyFrame", UIParent)
    frame:SetWidth(200)
    frame:SetHeight(30 + (TINY_ROW_HEIGHT * TINY_ROWS_VISIBLE))
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:SetFrameStrata("MEDIUM")
    frame:Hide()

    -- Title bar with tab name (moved to the left)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    title:SetText("Loading...")
    title:SetJustifyH("LEFT")
    frame.title = title

    -- Close button (make it smaller to match other buttons)
    local closeButton = CreateFrame("Button", nil, frame)
    closeButton:SetWidth(12)
    closeButton:SetHeight(12)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    closeButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Close Window")
        GameTooltip:Show()
    end)
    closeButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.closeButton = closeButton

    -- Expand button (to restore full window)
    local expandButton = CreateFrame("Button", nil, frame)
    expandButton:SetWidth(12)
    expandButton:SetHeight(12)
    expandButton:SetPoint("RIGHT", closeButton, "LEFT", -2, 0)
    expandButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    expandButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
    expandButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    expandButton:SetScript("OnClick", function()
        LogFilterGroup:ExitTinyMode()
    end)
    expandButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Expand to Full View")
        GameTooltip:Show()
    end)
    expandButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.expandButton = expandButton

    -- Sound toggle button
    local soundButton = CreateFrame("Button", nil, frame)
    soundButton:SetWidth(12)
    soundButton:SetHeight(12)
    soundButton:SetPoint("RIGHT", expandButton, "LEFT", -2, 0)
    soundButton:SetNormalTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
    soundButton:SetPushedTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
    soundButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    soundButton:SetScript("OnClick", function()
        LogFilterGroup.soundEnabled = not LogFilterGroup.soundEnabled
        LogFilterGroup:SaveSettings()
        LogFilterGroup:UpdateTinySoundButton()
    end)
    soundButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Toggle Sound Notifications")
        GameTooltip:Show()
    end)
    soundButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.soundButton = soundButton

    -- Clear messages button
    local clearButton = CreateFrame("Button", nil, frame)
    clearButton:SetWidth(12)
    clearButton:SetHeight(12)
    clearButton:SetPoint("RIGHT", soundButton, "LEFT", -2, 0)
    clearButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
    clearButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearButton:GetHighlightTexture():SetAlpha(0.5)
    clearButton:SetScript("OnClick", function()
        -- Clear messages for the active tab
        local tab = LogFilterGroup:GetTab(LogFilterGroup.activeTabId)
        if tab then
            -- Clear this tab's message references
            tab.messageRefs = {}

            -- Also clean up orphaned messages from repository
            for messageId, msgData in pairs(LogFilterGroup.messageRepository) do
                if msgData.tabs and msgData.tabs[tab.id] then
                    msgData.tabs[tab.id] = nil

                    -- If no other tabs reference this message, delete it from repository
                    local hasOtherTabs = false
                    for _ in pairs(msgData.tabs) do
                        hasOtherTabs = true
                        break
                    end
                    if not hasOtherTabs then
                        LogFilterGroup.messageRepository[messageId] = nil
                    end
                end
            end

            LogFilterGroup:SaveData()
            LogFilterGroup:UpdateTinyDisplay()
        end
    end)
    clearButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Clear All Messages")
        GameTooltip:Show()
    end)
    clearButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.clearButton = clearButton

    -- Scroll frame for messages
    local scrollFrame = CreateFrame("ScrollFrame", "LogFilterGroupTinyScrollFrame", frame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -25)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 8)
    scrollFrame:SetScript("OnVerticalScroll", function()
        FauxScrollFrame_OnVerticalScroll(TINY_ROW_HEIGHT, function() LogFilterGroup:UpdateTinyDisplay() end)
    end)
    frame.scrollFrame = scrollFrame

    -- Timer to update glow fade effect
    frame.glowUpdateElapsed = 0
    frame:SetScript("OnUpdate", function()
        frame.glowUpdateElapsed = frame.glowUpdateElapsed + arg1
        if frame.glowUpdateElapsed >= 0.5 then  -- Update every 0.5 seconds
            frame.glowUpdateElapsed = 0
            LogFilterGroup:UpdateTinyDisplay()
        end
    end)

    -- Create message rows
    frame.rows = {}
    for i = 1, TINY_ROWS_VISIBLE do
        local row = CreateFrame("Frame", nil, frame)
        row:SetWidth(scrollFrame:GetWidth() - 5)
        row:SetHeight(TINY_ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -(i-1) * TINY_ROW_HEIGHT)

        -- Background texture for glow effect
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bg:SetAllPoints(row)
        bg:SetVertexColor(1, 1, 0, 0)  -- Yellow, initially transparent
        row.glowBg = bg

        -- Player name (clickable for tooltip)
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("LEFT", row, "LEFT", 2, 0)
        nameText:SetWidth(70)
        nameText:SetJustifyH("LEFT")
        nameText:SetTextColor(0, 1, 0, 1)  -- Green
        row.nameText = nameText

        -- Message timer (to the right of name)
        local timerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        timerText:SetPoint("LEFT", nameText, "RIGHT", 2, 0)
        timerText:SetWidth(20)
        timerText:SetJustifyH("LEFT")
        timerText:SetTextColor(0.7, 0.7, 0.7, 1)  -- Gray
        row.timerText = timerText

        -- Make row show tooltip on hover
        row:EnableMouse(true)
        row:SetScript("OnEnter", function()
            if this.fullMessage then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(this.senderName, 0, 1, 0)
                GameTooltip:AddLine(this.fullMessage, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Whisper button (W)
        local whisperBtn = CreateFrame("Button", nil, row)
        whisperBtn:SetWidth(15)
        whisperBtn:SetHeight(15)
        whisperBtn:SetPoint("LEFT", timerText, "RIGHT", 3, 0)
        whisperBtn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        whisperBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        whisperBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local whisperText = whisperBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        whisperText:SetPoint("CENTER", whisperBtn, "CENTER")
        whisperText:SetText("W")
        whisperBtn:SetScript("OnClick", function()
            if this:GetParent().senderName then
                LogFilterGroup:SendWhisper(this:GetParent().senderName)
                LogFilterGroup:MarkAsWhispered(LogFilterGroup.activeTabId, this:GetParent().senderName)
                whisperText:SetTextColor(0, 1, 0, 1)  -- Green when whispered
                LogFilterGroup:UpdateTinyDisplay()
            end
        end)
        whisperBtn.text = whisperText
        row.whisperBtn = whisperBtn

        -- Invite button (I)
        local inviteBtn = CreateFrame("Button", nil, row)
        inviteBtn:SetWidth(15)
        inviteBtn:SetHeight(15)
        inviteBtn:SetPoint("LEFT", whisperBtn, "RIGHT", 3, 0)
        inviteBtn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        inviteBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        inviteBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local inviteText = inviteBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        inviteText:SetPoint("CENTER", inviteBtn, "CENTER")
        inviteText:SetText("I")
        inviteBtn:SetScript("OnClick", function()
            if this:GetParent().senderName then
                InviteByName(this:GetParent().senderName)
                LogFilterGroup:MarkAsInvited(LogFilterGroup.activeTabId, this:GetParent().senderName)
                inviteText:SetTextColor(0, 1, 0, 1)  -- Green when invited
                LogFilterGroup:UpdateTinyDisplay()
            end
        end)
        inviteBtn.text = inviteText
        row.inviteBtn = inviteBtn

        -- Clear button (X)
        local clearBtn = CreateFrame("Button", nil, row)
        clearBtn:SetWidth(15)
        clearBtn:SetHeight(15)
        clearBtn:SetPoint("LEFT", inviteBtn, "RIGHT", 3, 0)
        clearBtn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        clearBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        clearBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local clearText = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        clearText:SetPoint("CENTER", clearBtn, "CENTER")
        clearText:SetText("X")
        clearText:SetTextColor(1, 0.5, 0.5, 1)  -- Light red
        clearBtn:SetScript("OnClick", function()
            local senderName = this:GetParent().senderName
            if senderName then
                local currentTab = LogFilterGroup:GetTab(LogFilterGroup.activeTabId)
                if currentTab and currentTab.messageRefs then
                    -- Find and remove the message from this sender
                    for messageId, metadata in pairs(currentTab.messageRefs) do
                        local msgData = LogFilterGroup.messageRepository[messageId]
                        if msgData and msgData.sender == senderName then
                            -- Remove from this tab's references
                            currentTab.messageRefs[messageId] = nil

                            -- Remove this tab from the message's tab list
                            if msgData.tabs then
                                msgData.tabs[currentTab.id] = nil

                                -- If no other tabs reference this message, delete from repository
                                local hasOtherTabs = false
                                for _ in pairs(msgData.tabs) do
                                    hasOtherTabs = true
                                    break
                                end
                                if not hasOtherTabs then
                                    LogFilterGroup.messageRepository[messageId] = nil
                                end
                            end

                            break
                        end
                    end

                    LogFilterGroup:SaveData()
                    LogFilterGroup:UpdateTinyDisplay()
                end
            end
        end)
        clearBtn.text = clearText
        row.clearBtn = clearBtn

        row:Hide()
        table.insert(frame.rows, row)
    end

    return frame
end

-- Update tiny mode display
function LogFilterGroup:UpdateTinyDisplay()
    local frame = LogFilterGroupTinyFrame
    if not frame or not frame:IsVisible() then
        return
    end

    -- Get current tab
    local tab = self:GetTab(self.activeTabId)
    if not tab then
        return
    end

    -- Update title with tab name
    frame.title:SetText(tab.name)

    -- Collect and filter messages (same logic as main display)
    local filterText = tab.filterText
    local excludeText = tab.excludeText
    local messages = {}

    if tab.messageRefs then
        for messageId, metadata in pairs(tab.messageRefs) do
            local msgData = self.messageRepository[messageId]
            if msgData then
                -- Apply filters (using helper functions from UI.lua)
                if LogFilterGroup.MatchesFilter(msgData.message, filterText) and
                   not LogFilterGroup.MatchesExclude(msgData.message, msgData.sender, excludeText) then
                    table.insert(messages, {
                        sender = msgData.sender,
                        message = msgData.message,
                        timestamp = msgData.timestamp,
                        whispered = metadata.whispered or false,
                        invited = metadata.invited or false
                    })
                end
            end
        end
    end

    -- Sort by timestamp (newest first)
    table.sort(messages, function(a, b)
        return a.timestamp > b.timestamp
    end)

    local numMessages = table.getn(messages)
    local offset = FauxScrollFrame_GetOffset(frame.scrollFrame)

    FauxScrollFrame_Update(frame.scrollFrame, numMessages, TINY_ROWS_VISIBLE, TINY_ROW_HEIGHT)

    local currentTime = time()
    for i = 1, TINY_ROWS_VISIBLE do
        local row = frame.rows[i]
        local index = i + offset

        if index <= numMessages then
            local data = messages[index]
            row.senderName = data.sender
            row.fullMessage = data.message

            -- Set player name
            row.nameText:SetText(data.sender)

            -- Calculate and display elapsed time
            local elapsed = currentTime - data.timestamp
            local timeStr
            if elapsed < 60 then
                timeStr = string.format("%ds", elapsed)
            else
                local minutes = math.floor(elapsed / 60)
                timeStr = string.format("%dm", minutes)
            end
            row.timerText:SetText(timeStr)

            -- Update button colors based on state
            if data.whispered then
                row.whisperBtn.text:SetTextColor(0, 1, 0, 1)  -- Green
            else
                row.whisperBtn.text:SetTextColor(1, 1, 1, 1)  -- White
            end

            if data.invited then
                row.inviteBtn.text:SetTextColor(0, 1, 0, 1)  -- Green
            else
                row.inviteBtn.text:SetTextColor(1, 1, 1, 1)  -- White
            end

            -- Show yellow glow for messages less than 10 seconds old
            local messageAge = currentTime - data.timestamp
            if messageAge < 10 then
                -- Fade the glow from 0.3 alpha at 0 seconds to 0 alpha at 10 seconds
                local glowAlpha = 0.3 * (1 - (messageAge / 10))
                row.glowBg:SetVertexColor(1, 1, 0, glowAlpha)
            else
                row.glowBg:SetVertexColor(1, 1, 0, 0)  -- No glow
            end

            row:Show()
        else
            row.glowBg:SetVertexColor(1, 1, 0, 0)  -- Clear glow
            row:Hide()
        end
    end
end

-- Enter tiny mode
function LogFilterGroup:EnterTinyMode()
    -- Hide main window
    if LogFilterGroupFrame then
        LogFilterGroupFrame:Hide()
    end

    -- Show tiny mode
    local tinyFrame = self:CreateTinyModeFrame()
    tinyFrame:Show()
    self:UpdateTinyDisplay()
    self:UpdateTinySoundButton()

    -- Set flag
    self.inTinyMode = true
end

-- Exit tiny mode
function LogFilterGroup:ExitTinyMode()
    -- Hide tiny mode
    if LogFilterGroupTinyFrame then
        LogFilterGroupTinyFrame:Hide()
    end

    -- Show main window
    if LogFilterGroupFrame then
        LogFilterGroupFrame:Show()
        self:UpdateDisplay()
    end

    -- Clear flag
    self.inTinyMode = false
end

-- Helper function to send whisper from tiny mode
function LogFilterGroup:SendWhisper(playerName)
    local tab = self:GetTab(self.activeTabId)
    if tab then
        if tab.autoSendWhisper and tab.whisperTemplate and tab.whisperTemplate ~= "" then
            -- Auto-send the prepared message
            SendChatMessage(tab.whisperTemplate, "WHISPER", nil, playerName)
        else
            -- Just prepare the chat window
            ChatFrameEditBox:SetText("/w " .. playerName .. " ")
            ChatFrameEditBox:Show()
        end
    end
end

-- Update sound button appearance in tiny mode
function LogFilterGroup:UpdateTinySoundButton()
    local frame = LogFilterGroupTinyFrame
    if not frame then return end

    if self.soundEnabled then
        -- Sound is ON - show icon in full color
        frame.soundButton:SetNormalTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
        frame.soundButton:SetPushedTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
        frame.soundButton:GetNormalTexture():SetVertexColor(1, 1, 1, 1)
    else
        -- Sound is OFF - show icon greyed out
        frame.soundButton:SetNormalTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
        frame.soundButton:SetPushedTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
        frame.soundButton:GetNormalTexture():SetVertexColor(0.4, 0.4, 0.4, 1)
    end
end
