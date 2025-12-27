-- Helper functions for minimize/restore windows (both main and separate)

-- Unified minimize function that works for both main window and separate windows
function LogFilterGroup:MinimizeWindow(windowType)
    if self.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: MinimizeWindow called with windowType = " .. tostring(windowType))
    end

    local frame
    if windowType == "main" then
        frame = LogFilterGroupFrame
    elseif windowType == "lfm" then
        frame = LogFilterGroupLFMWindow
    elseif windowType == "lfg" then
        frame = LogFilterGroupLFGWindow
    else
        frame = LogFilterGroupProfessionWindow
    end

    if not frame then
        if self.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: frame is nil, returning")
        end
        return
    end

    -- Store current height
    frame.savedHeight = frame:GetHeight()
    frame.isMinimized = true

    -- For main window, track which tab was active
    if windowType == "main" then
        LogFilterGroup.mainWindowMinimizedTab = frame.currentTab
        LogFilterGroup.mainWindowMinimized = true
    end

    -- Hide all content except title bar
    frame:SetHeight(30)

    -- Immediately hide all message rows before hiding scrollFrame
    if frame.rows then
        for i = 1, table.getn(frame.rows) do
            if frame.rows[i] then
                frame.rows[i]:Hide()
            end
        end
    end

    frame.scrollFrame:Hide()

    -- Explicitly hide the scroll bar (child of scrollFrame)
    local scrollBar = getglobal(frame.scrollFrame:GetName() .. "ScrollBar")
    if scrollBar then
        scrollBar:Hide()
    end

    frame.statusText:Hide()
    frame.resizeGrip:Hide()
    frame.resizeButton:Hide()
    frame.clearIconButton:Hide()

    -- Hide filter label
    if frame.filterLabel then
        frame.filterLabel:Hide()
    end

    -- Hide filter input
    if frame.filterInput then
        frame.filterInput:Hide()
    end

    -- Hide exclude input
    if frame.excludeInput then
        frame.excludeInput:Hide()
    end

    -- Hide exclude label
    if frame.excludeLabel then
        frame.excludeLabel:Hide()
    end

    -- Hide auto-send checkbox and related elements
    if frame.autoSendCheckbox then
        frame.autoSendCheckbox:Hide()
    end
    if frame.autoSendLabel then
        frame.autoSendLabel:Hide()
    end

    -- Hide whisper message input
    if frame.whisperMsgInput then
        frame.whisperMsgInput:Hide()
    end

    -- Hide dynamic tab buttons by moving them off-screen AND hiding
    if frame.tabButtons then
        if self.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Hiding " .. table.getn(frame.tabButtons) .. " tab buttons")
        end
        for i, button in ipairs(frame.tabButtons) do
            if button then
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
                button:Hide()
                if self.debugMode then
                    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Tab " .. i .. " moved and hidden")
                end
            end
        end
    end

    -- Also try to hide by global names
    for _, tab in ipairs(LogFilterGroup.tabs) do
        local globalButton = getglobal("LogFilterGroupTab" .. tab.id)
        if globalButton then
            globalButton:ClearAllPoints()
            globalButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
            globalButton:Hide()
        end
    end

    -- Hide add tab button
    if frame.addTabButton then
        frame.addTabButton:ClearAllPoints()
        frame.addTabButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
        frame.addTabButton:Hide()
    end

    -- Also hide by global name
    local globalAddButton = getglobal("LogFilterGroupAddTab")
    if globalAddButton then
        globalAddButton:ClearAllPoints()
        globalAddButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
        globalAddButton:Hide()
    end

    -- Change minimize button to restore button
    frame.minimizeButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    frame.minimizeButton:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-Down")
    frame.minimizeButton:SetScript("OnClick", function()
        local parentFrame = this:GetParent()
        local wType = windowType
        if parentFrame and parentFrame.windowType then
            wType = parentFrame.windowType
        end
        LogFilterGroup:RestoreWindow(wType)
    end)
end

-- Unified restore function that works for both main window and separate windows
function LogFilterGroup:RestoreWindow(windowType)
    local frame
    if windowType == "main" then
        frame = LogFilterGroupFrame
    elseif windowType == "lfm" then
        frame = LogFilterGroupLFMWindow
    elseif windowType == "lfg" then
        frame = LogFilterGroupLFGWindow
    else
        frame = LogFilterGroupProfessionWindow
    end

    if not frame then return end

    -- Restore height
    if frame.savedHeight then
        frame:SetHeight(frame.savedHeight)
    else
        frame:SetHeight(400)
    end

    frame.isMinimized = false

    -- For main window, clear minimized state
    if windowType == "main" then
        LogFilterGroup.mainWindowMinimized = false
        LogFilterGroup.mainWindowMinimizedTab = nil
    end

    -- Show all content first (must be visible before we can show rows)
    frame.scrollFrame:Show()

    -- Explicitly show the scroll bar
    local scrollBar = getglobal(frame.scrollFrame:GetName() .. "ScrollBar")
    if scrollBar then
        scrollBar:Show()
    end

    -- Immediately show all visible rows to prevent delay
    if frame.rows then
        for i = 1, table.getn(frame.rows) do
            if frame.rows[i] then
                frame.rows[i]:Show()
            end
        end
    end

    frame.statusText:Show()
    frame.resizeGrip:Show()
    frame.resizeButton:Show()
    frame.clearIconButton:Show()

    -- Update lock state FIRST to show/hide filter inputs and reposition scroll frame
    if windowType == "main" and LogFilterGroup.UpdateLockState then
        LogFilterGroup:UpdateLockState()
    else
        -- For non-main windows, just show all inputs
        -- Show filter label
        if frame.filterLabel then
            frame.filterLabel:Show()
        end

        -- Show filter help text
        if frame.filterHelp then
            frame.filterHelp:Show()
        end

        -- Show filter inputs (main window has two, separate windows have one)
        if frame.filterInput then
            frame.filterInput:Show()
        end

        -- Show exclude label
        if frame.excludeLabel then
            frame.excludeLabel:Show()
        end

        -- Show exclude inputs (main window has two, separate windows have one)
        if frame.excludeInput then
            frame.excludeInput:Show()
        end

        -- Show auto-send checkbox and related elements
        if frame.autoSendCheckbox then
            frame.autoSendCheckbox:Show()
        end
        if frame.autoSendLabel then
            frame.autoSendLabel:Show()
        end

        -- Show whisper message input
        if frame.whisperMsgInput then
            frame.whisperMsgInput:Show()
        end
    end

    -- Show dynamic tab buttons - need to restore their positions via RefreshTabButtons
    LogFilterGroup:RefreshTabButtons()

    if frame.tabButtons then
        for _, button in ipairs(frame.tabButtons) do
            button:Show()
        end
    end

    -- Show add tab button
    if frame.addTabButton then
        frame.addTabButton:Show()
    end

    -- Change restore button back to minimize button
    frame.minimizeButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    frame.minimizeButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    frame.minimizeButton:SetScript("OnClick", function()
        local parentFrame = this:GetParent()
        local wType = windowType
        if parentFrame and parentFrame.windowType then
            wType = parentFrame.windowType
        end
        LogFilterGroup:MinimizeWindow(wType)
    end)

    -- Now update the display with proper data AFTER lock state has been applied
    if windowType == "main" then
        if LogFilterGroup.UpdateDisplay then
            LogFilterGroup:UpdateDisplay()
        end
    else
        if LogFilterGroup.UpdateSeparateWindow then
            LogFilterGroup:UpdateSeparateWindow(windowType)
        end
    end
end

-- Main window minimize/restore functions
function LogFilterGroup:MinimizeMainWindow()
    self:MinimizeWindow("main")
end

function LogFilterGroup:RestoreMainWindow()
    self:RestoreWindow("main")
end
