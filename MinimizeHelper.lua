-- Helper functions for minimize/restore windows (both main and separate)
print("DEBUG: MinimizeHelper.lua is loading...")

-- Unified minimize function that works for both main window and separate windows
function LogFilterGroup:MinimizeWindow(windowType)
    DEFAULT_CHAT_FRAME:AddMessage("DEBUG: MinimizeWindow called with windowType = " .. tostring(windowType))

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
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: frame is nil, returning")
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

    -- Hide filter help text
    if frame.filterHelp then
        frame.filterHelp:Hide()
    end

    -- Hide filter inputs (main window has two, separate windows have one)
    if frame.filterInput then
        frame.filterInput:Hide()
    end
    if frame.filterInputLFM then
        frame.filterInputLFM:Hide()
    end
    if frame.filterInputProfession then
        frame.filterInputProfession:Hide()
    end

    -- Hide auto-send checkbox and related elements
    if frame.autoSendCheckbox then
        frame.autoSendCheckbox:Hide()
        frame.autoSendLabel:Hide()
    end

    -- Hide whisper message inputs
    if frame.whisperMsgInput then
        frame.whisperMsgInput:Hide()
    end
    if frame.whisperMsgInputLFM then
        frame.whisperMsgInputLFM:Hide()
    end
    if frame.whisperMsgInputProf then
        frame.whisperMsgInputProf:Hide()
    end

    -- Hide tabs (main window only)
    if frame.lfmTab then
        frame.lfmTab:Hide()
    end
    if frame.lfgTab then
        frame.lfgTab:Hide()
    end
    if frame.professionTab then
        frame.professionTab:Hide()
    end

    -- Hide separate button (main window only)
    if frame.separateButton then
        frame.separateButton:Hide()
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

    -- Show all content
    frame.scrollFrame:Show()

    -- Explicitly show the scroll bar
    local scrollBar = getglobal(frame.scrollFrame:GetName() .. "ScrollBar")
    if scrollBar then
        scrollBar:Show()
    end

    frame.statusText:Show()
    frame.resizeGrip:Show()
    frame.resizeButton:Show()
    frame.clearIconButton:Show()

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

    -- Show separate button (main window only)
    if frame.separateButton then
        frame.separateButton:Show()
    end

    -- For main window, show appropriate filter inputs based on current tab
    if windowType == "main" then
        if frame.currentTab == "profession" then
            frame.filterInputProfession:Show()
            frame.autoSendCheckbox:Show()
            frame.autoSendLabel:Show()
            frame.whisperMsgInputProf:Show()
        elseif frame.currentTab == "lfg" then
            frame.filterInputLFM:Show()
        else
            frame.filterInputLFM:Show()
            frame.autoSendCheckbox:Show()
            frame.autoSendLabel:Show()
            frame.whisperMsgInputLFM:Show()
        end
    else
        -- For separate windows, always show their auto-send elements
        if frame.autoSendCheckbox then
            frame.autoSendCheckbox:Show()
            frame.autoSendLabel:Show()
            frame.whisperMsgInput:Show()
        end
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

    -- Update the window display
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

-- Backward compatibility wrappers - these now call the unified functions
function LogFilterGroup:MinimizeSeparateWindow(windowType)
    self:MinimizeWindow(windowType)
end

function LogFilterGroup:RestoreSeparateWindow(windowType)
    self:RestoreWindow(windowType)
end

function LogFilterGroup:MinimizeMainWindow()
    self:MinimizeWindow("main")
end

function LogFilterGroup:RestoreMainWindow()
    self:RestoreWindow("main")
end

print("DEBUG: MinimizeHelper.lua loaded successfully. MinimizeWindow = " .. tostring(LogFilterGroup.MinimizeWindow))
