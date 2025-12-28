-- UI for LogFilterGroup

local FRAME_WIDTH = 500
local FRAME_HEIGHT = 400
local ROW_HEIGHT = 30  -- Single line per row (WoW 1.12 doesn't support word wrap on FontStrings)
local ROWS_VISIBLE = 10

-- Create a simple input dialog popup
function LogFilterGroup:ShowInputDialog(title, defaultText, callback)
    -- Create popup frame if it doesn't exist
    if not LogFilterGroupInputDialog then
        local dialog = CreateFrame("Frame", "LogFilterGroupInputDialog", UIParent)
        dialog:SetWidth(300)
        dialog:SetHeight(120)
        dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        dialog:SetFrameStrata("DIALOG")
        dialog:EnableMouse(true)
        dialog:Hide()

        -- Title
        local titleText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("TOP", dialog, "TOP", 0, -18)
        dialog.titleText = titleText

        -- Input box
        local input = CreateFrame("EditBox", nil, dialog)
        input:SetWidth(260)
        input:SetHeight(20)
        input:SetPoint("TOP", dialog, "TOP", 0, -45)
        input:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        input:SetBackdropColor(0, 0, 0, 0.8)
        input:SetFontObject(GameFontNormal)
        input:SetTextInsets(5, 5, 0, 0)
        input:SetAutoFocus(true)
        dialog.input = input

        -- OK button
        local okButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
        okButton:SetWidth(100)
        okButton:SetHeight(25)
        okButton:SetPoint("BOTTOM", dialog, "BOTTOM", -55, 15)
        okButton:SetText("OK")
        okButton:SetScript("OnClick", function()
            if dialog.callback then
                dialog.callback(dialog.input:GetText())
            end
            dialog:Hide()
        end)
        dialog.okButton = okButton

        -- Cancel button
        local cancelButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
        cancelButton:SetWidth(100)
        cancelButton:SetHeight(25)
        cancelButton:SetPoint("BOTTOM", dialog, "BOTTOM", 55, 15)
        cancelButton:SetText("Cancel")
        cancelButton:SetScript("OnClick", function()
            dialog:Hide()
        end)
        dialog.cancelButton = cancelButton

        -- Enter key submits
        input:SetScript("OnEnterPressed", function()
            okButton:Click()
        end)
        input:SetScript("OnEscapePressed", function()
            cancelButton:Click()
        end)
    end

    local dialog = LogFilterGroupInputDialog
    dialog.titleText:SetText(title)
    dialog.input:SetText(defaultText or "")
    dialog.callback = callback
    dialog:Show()
    dialog.input:SetFocus()
end

-- Show context menu for tab (right-click menu)
function LogFilterGroup:ShowTabContextMenu(tabButton)
    -- Create context menu if it doesn't exist
    if not LogFilterGroupTabContextMenu then
        local menu = CreateFrame("Frame", "LogFilterGroupTabContextMenu", UIParent)
        menu:SetWidth(120)
        menu:SetHeight(90)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetFrameLevel(100)
        menu:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        menu:SetBackdropColor(0, 0, 0, 0.9)
        menu:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        menu:EnableMouse(true)
        menu:Hide()

        -- Rename button
        local renameButton = CreateFrame("Button", nil, menu)
        renameButton:SetWidth(110)
        renameButton:SetHeight(20)
        renameButton:SetPoint("TOP", menu, "TOP", 0, -8)
        renameButton:EnableMouse(true)
        renameButton:RegisterForClicks("LeftButtonUp")

        local renameText = renameButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        renameText:SetPoint("CENTER", renameButton, "CENTER", 0, 0)
        renameText:SetText("Rename")
        renameButton.text = renameText

        renameButton:SetScript("OnClick", function()
            local tabId = menu.tabId
            local tab = LogFilterGroup:GetTab(tabId)
            if tab then
                LogFilterGroup:ShowInputDialog("Rename Tab", tab.name, function(newName)
                    if newName and newName ~= "" then
                        tab.name = newName
                        LogFilterGroup:SaveSettings()
                        LogFilterGroup:RefreshTabButtons()
                    end
                end)
            end
            menu:Hide()
        end)
        menu.renameButton = renameButton

        -- Delete button
        local deleteButton = CreateFrame("Button", nil, menu)
        deleteButton:SetWidth(110)
        deleteButton:SetHeight(20)
        deleteButton:SetPoint("TOP", renameButton, "BOTTOM", 0, -2)
        deleteButton:EnableMouse(true)
        deleteButton:RegisterForClicks("LeftButtonUp")

        local deleteText = deleteButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        deleteText:SetPoint("CENTER", deleteButton, "CENTER", 0, 0)
        deleteText:SetText("Delete")
        deleteButton.text = deleteText

        deleteButton:SetScript("OnClick", function()
            local tabId = menu.tabId
            if LogFilterGroup:DeleteTab(tabId) then
                LogFilterGroup:RefreshTabButtons()
                LogFilterGroup:UpdateDisplay()
            end
            menu:Hide()
        end)
        menu.deleteButton = deleteButton

        -- Mute/Unmute button
        local muteButton = CreateFrame("Button", nil, menu)
        muteButton:SetWidth(110)
        muteButton:SetHeight(20)
        muteButton:SetPoint("TOP", deleteButton, "BOTTOM", 0, -2)
        muteButton:EnableMouse(true)
        muteButton:RegisterForClicks("LeftButtonUp")

        local muteText = muteButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        muteText:SetPoint("CENTER", muteButton, "CENTER", 0, 0)
        muteText:SetText("Mute")
        muteButton.text = muteText

        muteButton:SetScript("OnClick", function()
            local tabId = menu.tabId
            local tab = LogFilterGroup:GetTab(tabId)
            if tab then
                tab.muted = not tab.muted
                LogFilterGroup:SaveSettings()

                -- Stop tab flashing when muted
                if tab.muted then
                    LogFilterGroup:StopFlashingTab(tabId)
                end
            end
            menu:Hide()
        end)
        menu.muteButton = muteButton

        -- Highlight on hover
        renameButton:SetScript("OnEnter", function()
            this:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
            })
            this:SetBackdropColor(0.3, 0.3, 0.3, 1)
            this.text:SetTextColor(1, 1, 0, 1)
        end)
        renameButton:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
            this.text:SetTextColor(1, 1, 1, 1)
        end)

        deleteButton:SetScript("OnEnter", function()
            this:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
            })
            this:SetBackdropColor(0.3, 0.3, 0.3, 1)
            this.text:SetTextColor(1, 1, 0, 1)
        end)
        deleteButton:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
            this.text:SetTextColor(1, 1, 1, 1)
        end)

        muteButton:SetScript("OnEnter", function()
            this:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
            })
            this:SetBackdropColor(0.3, 0.3, 0.3, 1)
            this.text:SetTextColor(1, 1, 0, 1)
        end)
        muteButton:SetScript("OnLeave", function()
            this:SetBackdrop(nil)
            this.text:SetTextColor(1, 1, 1, 1)
        end)

        -- Close menu after a short delay if mouse leaves
        menu.mouseLeaveTime = nil
        menu:SetScript("OnUpdate", function(elapsed)
            if not MouseIsOver(this) and not MouseIsOver(this.renameButton) and not MouseIsOver(this.deleteButton) and not MouseIsOver(this.muteButton) then
                if not this.mouseLeaveTime then
                    this.mouseLeaveTime = 0
                else
                    this.mouseLeaveTime = this.mouseLeaveTime + (arg1 or 0)
                    if this.mouseLeaveTime > 0.5 then  -- Close after 0.5 seconds outside
                        this:Hide()
                    end
                end
            else
                this.mouseLeaveTime = nil
            end
        end)
    end

    local menu = LogFilterGroupTabContextMenu
    menu.tabId = tabButton.tabId

    -- Update mute button text based on tab's muted state
    local tab = self:GetTab(tabButton.tabId)
    if tab then
        if tab.muted then
            menu.muteButton.text:SetText("Unmute")
        else
            menu.muteButton.text:SetText("Mute")
        end

        -- Show/hide rename and delete buttons based on whether this is a default tab
        if tab.isDefault then
            -- Default tabs: hide rename and delete, only show mute
            menu.renameButton:Hide()
            menu.deleteButton:Hide()
            menu.muteButton:ClearAllPoints()
            menu.muteButton:SetPoint("TOP", menu, "TOP", 0, -8)
            menu:SetHeight(35)  -- Smaller height for just one button
        else
            -- Custom tabs: show all buttons
            menu.renameButton:Show()
            menu.deleteButton:Show()
            menu.muteButton:ClearAllPoints()
            menu.muteButton:SetPoint("TOP", menu.deleteButton, "BOTTOM", 0, -2)
            menu:SetHeight(90)  -- Full height for all buttons
        end
    end

    -- Simple positioning - just put it near the mouse cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale

    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    menu:Show()
end

-- Helper function to escape pattern characters for literal search
local function EscapePattern(str)
    return string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

-- Helper function to truncate message if it's too long and add '...' if truncated
-- Returns: displayText, isTruncated
local function TruncateMessage(message, maxWidth)
    -- Calculate visual character count (excluding hidden item link codes)
    -- Item links are: |Hitem:12345:0:0:0|h[Display Name]|h
    -- Only [Display Name] is visible, but the whole thing counts in string length

    -- Count visible characters
    local visibleChars = 0
    local i = 1
    local msgLen = string.len(message)

    while i <= msgLen do
        local char = string.sub(message, i, i)

        if char == "|" then
            local nextChar = string.sub(message, i + 1, i + 1)
            if nextChar == "H" then
                -- Start of item link, skip to the [
                local bracketStart = string.find(message, "%[", i)
                if bracketStart then
                    i = bracketStart
                else
                    i = i + 2
                end
            elseif nextChar == "h" then
                -- End of item link display or closing tag, skip it
                i = i + 2
            elseif nextChar == "c" then
                -- Color code |cFFFFFFFF, skip 10 characters
                i = i + 10
            elseif nextChar == "r" then
                -- Color reset |r, skip it
                i = i + 2
            else
                visibleChars = visibleChars + 1
                i = i + 1
            end
        elseif char == "[" or char == "]" then
            -- Brackets in item links are visible
            visibleChars = visibleChars + 1
            i = i + 1
        else
            visibleChars = visibleChars + 1
            i = i + 1
        end
    end

    -- GameFontNormalSmall averages about 4.5 pixels per character
    local maxVisibleChars = math.floor(maxWidth / 4.5)

    -- Safety check: if width is too small, show at least "..."
    if maxVisibleChars < 3 then
        return "...", true
    end

    if visibleChars <= maxVisibleChars then
        return message, false
    end

    -- Need to truncate - find position that gives us maxVisibleChars visible characters
    local truncatePos = msgLen
    visibleChars = 0
    i = 1

    while i <= msgLen and visibleChars < (maxVisibleChars - 3) do
        local char = string.sub(message, i, i)

        if char == "|" then
            local nextChar = string.sub(message, i + 1, i + 1)
            if nextChar == "H" then
                -- Start of item link, skip to the [
                local bracketStart = string.find(message, "%[", i)
                if bracketStart then
                    i = bracketStart
                else
                    i = i + 2
                end
            elseif nextChar == "h" then
                i = i + 2
            elseif nextChar == "c" then
                i = i + 10
            elseif nextChar == "r" then
                i = i + 2
            else
                visibleChars = visibleChars + 1
                i = i + 1
            end
        elseif char == "[" or char == "]" then
            visibleChars = visibleChars + 1
            i = i + 1
        else
            visibleChars = visibleChars + 1
            i = i + 1
        end

        truncatePos = i - 1
    end

    -- Check if we're in the middle of an item link: |Hitem:...|h[name]|h
    -- Scan backwards to find if we're inside a link
    local checkPos = truncatePos
    local foundLinkStart = false
    while checkPos > 1 do
        local char = string.sub(message, checkPos, checkPos)

        -- If we hit the start of a link marker, we're inside a link
        if char == "|" then
            local nextChar = string.sub(message, checkPos + 1, checkPos + 1)
            if nextChar == "H" then
                -- We're inside a link, try to find the end of the link
                foundLinkStart = true
                local linkEnd = string.find(message, "|h", checkPos + 2)
                if linkEnd then
                    -- Find the second |h that closes the link
                    local secondEnd = string.find(message, "|h", linkEnd + 2)
                    if secondEnd and secondEnd <= maxChars then
                        -- The whole link fits, truncate after it
                        truncatePos = secondEnd + 1
                    else
                        -- Link doesn't fit, truncate before it
                        truncatePos = checkPos - 1
                    end
                else
                    -- Couldn't find end, truncate before link
                    truncatePos = checkPos - 1
                end
                break
            elseif nextChar == "h" then
                -- We found the end of a previous link, we're safe
                break
            end
        end

        -- Don't scan too far back
        if truncatePos - checkPos > 100 then
            break
        end

        checkPos = checkPos - 1
    end

    -- Ensure we don't truncate to negative or zero
    if truncatePos < 1 then
        truncatePos = 1
    end

    -- Truncate and add ellipsis
    local truncated = string.sub(message, 1, truncatePos) .. "..."
    return truncated, true
end

-- Helper function to evaluate a simple expression (no parentheses)
local function EvaluateSimpleExpression(message, expression)
    local lowerMessage = string.lower(message)
    local lowerExpr = string.lower(expression)

    -- Trim whitespace
    lowerExpr = string.gsub(lowerExpr, "^%s*(.-)%s*$", "%1")

    if lowerExpr == "" then
        return true
    end

    -- Check for OR operator (lower precedence)
    if string.find(lowerExpr, " or ") then
        -- Split by OR
        local orTerms = {}
        local currentTerm = ""
        local i = 1
        while i <= string.len(lowerExpr) do
            local char = string.sub(lowerExpr, i, i)
            -- Check if we're at " or "
            if string.sub(lowerExpr, i, i+3) == " or " then
                table.insert(orTerms, currentTerm)
                currentTerm = ""
                i = i + 4
            else
                currentTerm = currentTerm .. char
                i = i + 1
            end
        end
        table.insert(orTerms, currentTerm)

        -- At least one OR term must match
        for _, term in ipairs(orTerms) do
            if EvaluateSimpleExpression(message, term) then
                return true
            end
        end
        return false

    -- Check for AND operator (higher precedence)
    elseif string.find(lowerExpr, " and ") then
        -- Split by AND
        local andTerms = {}
        local currentTerm = ""
        local i = 1
        while i <= string.len(lowerExpr) do
            local char = string.sub(lowerExpr, i, i)
            -- Check if we're at " and "
            if string.sub(lowerExpr, i, i+4) == " and " then
                table.insert(andTerms, currentTerm)
                currentTerm = ""
                i = i + 5
            else
                currentTerm = currentTerm .. char
                i = i + 1
            end
        end
        table.insert(andTerms, currentTerm)

        -- All AND terms must match
        for _, term in ipairs(andTerms) do
            term = string.gsub(term, "^%s*(.-)%s*$", "%1")
            -- Escape the term for literal search
            local searchTerm = EscapePattern(term)
            if not string.find(lowerMessage, searchTerm) then
                return false
            end
        end
        return true

    else
        -- Simple search term - escape pattern characters for literal search
        local searchTerm = EscapePattern(lowerExpr)
        return string.find(lowerMessage, searchTerm) ~= nil
    end
end

-- Helper function to strip WoW item/enchant/spell/quest links from message text
-- This prevents internal link IDs from matching filter terms
local function StripLinks(message)
    if not message then
        return ""
    end

    -- Strip color codes: |cXXXXXXXX and |r
    local stripped = string.gsub(message, "|c%x%x%x%x%x%x%x%x", "")
    stripped = string.gsub(stripped, "|r", "")

    -- Strip link codes but keep the visible text: |Htype:id|h[text]|h -> text
    -- Pattern matches: |H<anything>|h[<text>]|h
    stripped = string.gsub(stripped, "|H.-|h%[(.-)%]|h", "%1")

    -- Strip any remaining pipe codes
    stripped = string.gsub(stripped, "|H.-|h", "")
    stripped = string.gsub(stripped, "|h", "")

    return stripped
end

-- Parse and evaluate filter expression with AND/OR logic and parentheses
function LogFilterGroup.MatchesFilter(message, filterText)
    if not filterText or filterText == "" then
        return true
    end

    -- Strip item/enchant/spell links before filtering
    message = StripLinks(message)

    local lowerFilter = filterText
    local placeholderCount = 0
    local placeholderResults = {}

    -- Process parentheses recursively (innermost first)
    while string.find(lowerFilter, "%(") do
        -- Find innermost parentheses
        local startPos, endPos = string.find(lowerFilter, "%b()")
        if not startPos then break end

        -- Extract expression inside parentheses (without the parentheses)
        local innerExpr = string.sub(lowerFilter, startPos + 1, endPos - 1)

        -- Evaluate the inner expression
        local result = EvaluateSimpleExpression(message, innerExpr)

        -- Create a unique placeholder
        placeholderCount = placeholderCount + 1
        local placeholder = "___PH" .. placeholderCount .. "___"
        placeholderResults[placeholder] = result

        -- Replace the parenthesized expression with the placeholder
        lowerFilter = string.sub(lowerFilter, 1, startPos - 1) .. placeholder .. string.sub(lowerFilter, endPos + 1)
    end

    -- Evaluate the final expression, treating placeholders as search terms
    -- We need a modified version of EvaluateSimpleExpression that handles placeholders
    local function EvaluateWithPlaceholders(expr)
        local lowerExpr = string.lower(expr)
        lowerExpr = string.gsub(lowerExpr, "^%s*(.-)%s*$", "%1")

        if lowerExpr == "" then
            return true
        end

        -- Check for OR operator
        if string.find(lowerExpr, " or ") then
            local orTerms = {}
            local currentTerm = ""
            local i = 1
            while i <= string.len(lowerExpr) do
                if string.sub(lowerExpr, i, i+3) == " or " then
                    table.insert(orTerms, currentTerm)
                    currentTerm = ""
                    i = i + 4
                else
                    currentTerm = currentTerm .. string.sub(lowerExpr, i, i)
                    i = i + 1
                end
            end
            table.insert(orTerms, currentTerm)

            for _, term in ipairs(orTerms) do
                if EvaluateWithPlaceholders(term) then
                    return true
                end
            end
            return false

        -- Check for AND operator
        elseif string.find(lowerExpr, " and ") then
            local andTerms = {}
            local currentTerm = ""
            local i = 1
            while i <= string.len(lowerExpr) do
                if string.sub(lowerExpr, i, i+4) == " and " then
                    table.insert(andTerms, currentTerm)
                    currentTerm = ""
                    i = i + 5
                else
                    currentTerm = currentTerm .. string.sub(lowerExpr, i, i)
                    i = i + 1
                end
            end
            table.insert(andTerms, currentTerm)

            for _, term in ipairs(andTerms) do
                if not EvaluateWithPlaceholders(term) then
                    return false
                end
            end
            return true

        else
            -- Check if this is a placeholder
            lowerExpr = string.gsub(lowerExpr, "^%s*(.-)%s*$", "%1")
            if placeholderResults[lowerExpr] ~= nil then
                return placeholderResults[lowerExpr]
            end
            -- Otherwise, it's a simple search term - escape pattern characters for literal search
            local searchTerm = EscapePattern(lowerExpr)
            return string.find(string.lower(message), searchTerm) ~= nil
        end
    end

    return EvaluateWithPlaceholders(lowerFilter)
end

-- Helper function to check if a message should be excluded based on exclude filter
-- Checks both message content and sender name
function LogFilterGroup.MatchesExclude(message, sender, excludeText)
    if not excludeText or excludeText == "" then
        return false  -- No exclude filter means don't exclude
    end

    -- Check if the exclude filter matches the message content
    if LogFilterGroup.MatchesFilter(message, excludeText) then
        return true
    end

    -- Check if the exclude filter matches the sender name
    if LogFilterGroup.MatchesFilter(sender, excludeText) then
        return true
    end

    return false
end


-- Create main frame
function LogFilterGroup:CreateFrame()
    if LogFilterGroupFrame then
        return
    end
    
    -- Main frame
    local frame = CreateFrame("Frame", "LogFilterGroupFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)

    -- Restore saved position and size, or default to center
    if self.mainFramePosition then
        frame:SetPoint(
            self.mainFramePosition.point,
            UIParent,
            self.mainFramePosition.point,
            self.mainFramePosition.xOfs,
            self.mainFramePosition.yOfs
        )
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    if self.mainFrameSize then
        frame:SetWidth(self.mainFrameSize.width)
        frame:SetHeight(self.mainFrameSize.height)
    end
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
    frame:SetResizable(true)
    frame:SetMinResize(300, 350)
    frame:SetMaxResize(1000, 800)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        LogFilterGroup:SaveMainFramePosition()
    end)
    frame:Hide()

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("LogFilterGroup")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Close Window")
        GameTooltip:Show()
    end)
    closeButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Minimize button
    local minimizeButton = CreateFrame("Button", nil, frame)
    minimizeButton:SetWidth(16)
    minimizeButton:SetHeight(16)
    minimizeButton:SetPoint("RIGHT", closeButton, "LEFT", -2, 2)
    minimizeButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    minimizeButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    minimizeButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    minimizeButton:SetScript("OnClick", function()
        LogFilterGroup:EnterTinyMode()
    end)
    minimizeButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Tiny Mode\n|cFFFFFFFFCompact view with just player names|r")
        GameTooltip:Show()
    end)
    minimizeButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.minimizeButton = minimizeButton

    -- Sound toggle button (global sound for all tabs)
    local soundButton = CreateFrame("Button", nil, frame)
    soundButton:SetWidth(16)
    soundButton:SetHeight(16)
    soundButton:SetPoint("RIGHT", minimizeButton, "LEFT", -2, 0)
    soundButton:SetNormalTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
    soundButton:SetPushedTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
    soundButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    soundButton:SetScript("OnClick", function()
        LogFilterGroup.soundEnabled = not LogFilterGroup.soundEnabled
        LogFilterGroup:SaveSettings()
        LogFilterGroup:UpdateSoundButton()
    end)
    soundButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Toggle Sound Notifications\n|cFFFFFFFFPlay sound when messages arrive|r")
        GameTooltip:Show()
    end)
    soundButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.soundButton = soundButton

    -- Lock button (global lock for all tabs)
    local lockButton = CreateFrame("Button", nil, frame)
    lockButton:SetWidth(16)
    lockButton:SetHeight(16)
    lockButton:SetPoint("RIGHT", soundButton, "LEFT", -2, 0)
    lockButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    lockButton:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
    lockButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    lockButton:SetScript("OnClick", function()
        LogFilterGroup.globalLocked = not LogFilterGroup.globalLocked
        LogFilterGroup:SaveSettings()
        LogFilterGroup:UpdateLockState()
    end)
    lockButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Toggle Filter Lock\n|cFFFFFFFFLock to hide filter inputs|r")
        GameTooltip:Show()
    end)
    lockButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.lockButton = lockButton

    -- Clear icon button (next to lock button)
    local clearIconButton = CreateFrame("Button", nil, frame)
    clearIconButton:SetWidth(16)
    clearIconButton:SetHeight(16)
    clearIconButton:SetPoint("RIGHT", lockButton, "LEFT", -2, 0)
    clearIconButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearIconButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
    clearIconButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearIconButton:GetHighlightTexture():SetAlpha(0.5)

    clearIconButton:SetScript("OnClick", function()
        -- Clear messages for the active tab
        local tab = LogFilterGroup:GetTab(LogFilterGroup.activeTabId)
        if tab then
            -- Clear this tab's message references
            tab.messageRefs = {}

            -- Also clean up orphaned messages from repository
            -- (messages that are only referenced by this tab)
            for messageId, msgData in pairs(LogFilterGroup.messageRepository) do
                -- Remove this tab from the message's tab list
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
            LogFilterGroup:UpdateDisplay()
        end
    end)
    clearIconButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Clear Messages\n|cFFFFFFFFRemove all messages from current tab|r")
        GameTooltip:Show()
    end)
    clearIconButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.clearIconButton = clearIconButton

    -- Tab buttons storage (will be created dynamically)
    frame.tabButtons = {}
    frame.currentTab = self.activeTabId

    -- Filter label
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -55)
    filterLabel:SetText("Filter:")
    frame.filterLabel = filterLabel

    -- Filter input box (shared by all tabs)
    local filterInput = CreateFrame("EditBox", "LogFilterGroupFilterInput", frame)
    filterInput:SetHeight(20)
    filterInput:SetPoint("LEFT", filterLabel, "RIGHT", 3, 0)
    filterInput:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    filterInput:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    filterInput:SetBackdropColor(0, 0, 0, 0.8)
    filterInput:SetFontObject(GameFontNormal)
    filterInput:SetTextInsets(5, 5, 0, 0)
    filterInput:SetAutoFocus(false)
    filterInput:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    filterInput:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    filterInput:SetScript("OnTextChanged", function()
        local tab = LogFilterGroup:GetTab(LogFilterGroup.activeTabId)
        if tab then
            tab.filterText = this:GetText()
            LogFilterGroup:SaveSettings()
            LogFilterGroup:UpdateDisplay()
        end
    end)
    frame.filterInput = filterInput

    -- Exclude label
    local excludeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    excludeLabel:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -7)
    excludeLabel:SetText("Exclude:")
    frame.excludeLabel = excludeLabel

    -- Exclude input box (shared by all tabs)
    local excludeInput = CreateFrame("EditBox", "LogFilterGroupExcludeInput", frame)
    excludeInput:SetHeight(20)
    excludeInput:SetPoint("LEFT", excludeLabel, "RIGHT", 3, 0)
    excludeInput:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    excludeInput:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    excludeInput:SetBackdropColor(0, 0, 0, 0.8)
    excludeInput:SetFontObject(GameFontNormal)
    excludeInput:SetTextInsets(5, 5, 0, 0)
    excludeInput:SetAutoFocus(false)
    excludeInput:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    excludeInput:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    excludeInput:SetScript("OnTextChanged", function()
        local tab = LogFilterGroup:GetTab(LogFilterGroup.activeTabId)
        if tab then
            tab.excludeText = this:GetText()
            LogFilterGroup:SaveSettings()
            LogFilterGroup:UpdateDisplay()
        end
    end)
    frame.excludeInput = excludeInput

    -- Auto-send whisper checkbox
    local autoSendCheckbox = CreateFrame("CheckButton", "LogFilterGroupAutoSendCheckbox", frame, "UICheckButtonTemplate")
    autoSendCheckbox:SetWidth(20)
    autoSendCheckbox:SetHeight(20)
    autoSendCheckbox:SetPoint("TOPLEFT", excludeLabel, "BOTTOMLEFT", 0, -7)
    autoSendCheckbox:SetScript("OnClick", function()
        local tab = LogFilterGroup:GetTab(LogFilterGroup.activeTabId)
        if tab then
            tab.autoSendWhisper = this:GetChecked()
            LogFilterGroup:SaveSettings()
        end
    end)
    frame.autoSendCheckbox = autoSendCheckbox

    local autoSendLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoSendLabel:SetPoint("LEFT", autoSendCheckbox, "RIGHT", 5, 0)
    autoSendLabel:SetText("Use Template")
    frame.autoSendLabel = autoSendLabel

    -- Whisper message input box (shared by all tabs)
    local whisperMsgInput = CreateFrame("EditBox", "LogFilterGroupWhisperMsgInput", frame)
    whisperMsgInput:SetHeight(20)
    whisperMsgInput:SetPoint("LEFT", autoSendLabel, "RIGHT", 5, 0)
    whisperMsgInput:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    whisperMsgInput:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    whisperMsgInput:SetBackdropColor(0, 0, 0, 0.8)
    whisperMsgInput:SetFontObject(GameFontNormalSmall)
    whisperMsgInput:SetTextInsets(5, 5, 0, 0)
    whisperMsgInput:SetAutoFocus(false)
    whisperMsgInput:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    whisperMsgInput:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    whisperMsgInput:SetScript("OnTextChanged", function()
        local tab = LogFilterGroup:GetTab(LogFilterGroup.activeTabId)
        if tab then
            tab.whisperTemplate = this:GetText()
            LogFilterGroup:SaveSettings()
        end
    end)
    frame.whisperMsgInput = whisperMsgInput

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "LogFilterGroupScrollFrame", frame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -115)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 25)
    scrollFrame:SetScript("OnVerticalScroll", function()
        FauxScrollFrame_OnVerticalScroll(ROW_HEIGHT, function() LogFilterGroup:UpdateDisplay() end)
    end)
    frame.scrollFrame = scrollFrame
    
    -- Create row frames
    frame.rows = {}
    for i = 1, ROWS_VISIBLE do
        local row = CreateFrame("Frame", nil, frame)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -(i-1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", scrollFrame, "RIGHT", -25, 0)

        -- Background
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        if math.mod(i, 2) == 0 then
            row.bg:SetTexture(0, 0, 0, 0.3)
        else
            row.bg:SetTexture(0, 0, 0, 0.1)
        end

        -- Sender name
        row.sender = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.sender:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -5)
        row.sender:SetJustifyH("LEFT")
        row.sender:SetWidth(80)

        -- Message text
        row.message = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.message:SetPoint("TOPLEFT", row, "TOPLEFT", 85, -5)
        row.message:SetPoint("RIGHT", row, "RIGHT", -157, 0)  -- Leave room for time (starts at -152) + 5px gap
        row.message:SetJustifyH("LEFT")

        -- Time ago
        row.time = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.time:SetPoint("TOPRIGHT", row, "TOPRIGHT", -152, -5)  -- Adjusted for three buttons
        row.time:SetJustifyH("RIGHT")
        row.time:SetWidth(50)  -- Fixed width for time display (max "59m ago" = ~45px)

        -- Clear button (rightmost)
        row.clearButton = CreateFrame("Button", nil, row)
        row.clearButton:SetWidth(40)
        row.clearButton:SetHeight(22)
        row.clearButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -5)
        row.clearButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        row.clearButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        row.clearButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        row.clearButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.clearButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.clearButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        row.clearButtonText = row.clearButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.clearButtonText:SetPoint("CENTER", row.clearButton, "CENTER", 0, 0)
        row.clearButtonText:SetText("Clear")

        -- Invite button (middle)
        row.inviteButton = CreateFrame("Button", nil, row)
        row.inviteButton:SetWidth(50)
        row.inviteButton:SetHeight(22)
        row.inviteButton:SetPoint("TOPRIGHT", row.clearButton, "TOPLEFT", -2, 0)
        row.inviteButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        row.inviteButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        row.inviteButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        row.inviteButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.inviteButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.inviteButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        row.inviteButtonText = row.inviteButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.inviteButtonText:SetPoint("CENTER", row.inviteButton, "CENTER", 0, 0)
        row.inviteButtonText:SetText("Invite")

        row.inviteButton:SetScript("OnClick", function()
            if this:GetParent().senderName then
                InviteByName(this:GetParent().senderName)
                -- Mark as invited and update button
                LogFilterGroup:MarkAsInvited(LogFilterGroup.activeTabId, this:GetParent().senderName)
                this:GetParent().inviteButtonText:SetText("|cff00ff00Invite|r")  -- Green text to indicate invited
            end
        end)

        -- Whisper button (leftmost)
        row.whisperButton = CreateFrame("Button", nil, row)
        row.whisperButton:SetWidth(50)
        row.whisperButton:SetHeight(22)
        row.whisperButton:SetPoint("TOPRIGHT", row.inviteButton, "TOPLEFT", -2, 0)
        row.whisperButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        row.whisperButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        row.whisperButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        row.whisperButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.whisperButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.whisperButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        row.whisperButtonText = row.whisperButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.whisperButtonText:SetPoint("CENTER", row.whisperButton, "CENTER", 0, 0)
        row.whisperButtonText:SetText("Whisper")

        -- Make row hoverable with tooltip
        row:EnableMouse(true)
        row:SetScript("OnEnter", function()
            this.bg:SetTexture(0.2, 0.2, 0.5, 0.5)
            -- Show tooltip when message is truncated or window is narrow
            local frameWidth = frame:GetWidth()
            if this.fullMessage and (this.isTruncated or frameWidth <= 350) then
                GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
                GameTooltip:SetText(this.senderName, 0, 1, 0, 1, true)
                GameTooltip:AddLine(this.fullMessage, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            if math.mod(i, 2) == 0 then
                this.bg:SetTexture(0, 0, 0, 0.3)
            else
                this.bg:SetTexture(0, 0, 0, 0.1)
            end
            GameTooltip:Hide()
        end)

        row:Hide()
        frame.rows[i] = row
    end

    -- Status text
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)
    statusText:SetText("Monitoring chat for messages...")
    frame.statusText = statusText

    -- Resize grip texture (visual indicator)
    local resizeGrip = frame:CreateTexture(nil, "ARTWORK")
    resizeGrip:SetWidth(16)
    resizeGrip:SetHeight(16)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    resizeGrip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame.resizeGrip = resizeGrip

    -- Resize grip button (invisible but functional)
    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetWidth(20)
    resizeButton:SetHeight(20)
    resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizeButton:EnableMouse(true)
    resizeButton:SetScript("OnEnter", function()
        resizeGrip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    resizeButton:SetScript("OnLeave", function()
        resizeGrip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)
    resizeButton:SetScript("OnMouseDown", function()
        resizeGrip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeButton:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        resizeGrip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        LogFilterGroup:UpdateDisplay()
    end)
    frame.resizeButton = resizeButton

    -- Handle resize to update display and maintain lock state
    frame:SetScript("OnSizeChanged", function()
        if frame:IsVisible() then
            -- Update lock state first to reposition scroll frame
            LogFilterGroup:UpdateLockState()
            -- Then refresh tabs and display
            LogFilterGroup:RefreshTabButtons()
            LogFilterGroup:UpdateDisplay()

            -- Save the new size
            LogFilterGroup:SaveMainFramePosition()
        end
    end)

    -- Update timer
    frame:SetScript("OnUpdate", function()
        if not this:IsVisible() then return end

        local now = GetTime()
        if now - LogFilterGroup.lastUpdate > 1 then
            LogFilterGroup.lastUpdate = now
            LogFilterGroup:UpdateDisplay()
        end
    end)

    -- Create initial tab buttons
    self:RefreshTabButtons()

    -- Show initial tab
    self:ShowTab(self.activeTabId)
end

-- Refresh tab buttons (create/recreate dynamic tabs)
function LogFilterGroup:RefreshTabButtons()
    local frame = LogFilterGroupFrame
    if not frame then
        return
    end

    -- Don't refresh tabs if window is minimized
    if frame.isMinimized then
        return
    end

    -- Clear existing tab buttons
    for _, button in ipairs(frame.tabButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    frame.tabButtons = {}

    -- Clear existing add button if it exists
    if frame.addTabButton then
        frame.addTabButton:Hide()
        frame.addTabButton:SetParent(nil)
        frame.addTabButton = nil
    end

    -- Create button for each tab with wrapping
    local TAB_WIDTH = 80
    local TAB_HEIGHT = 22
    local TAB_SPACING = 2
    local START_X = 10
    local START_Y = -28
    local frameWidth = frame:GetWidth()
    local maxTabsPerRow = math.floor((frameWidth - START_X - 40) / (TAB_WIDTH + TAB_SPACING))  -- 40 for + button

    local currentRow = 0
    local currentCol = 0

    for i, tab in ipairs(self.tabs) do
        local tabButton = CreateFrame("Button", "LogFilterGroupTab" .. tab.id, frame)
        tabButton:SetWidth(TAB_WIDTH)
        tabButton:SetHeight(TAB_HEIGHT)

        -- Calculate position with wrapping
        if i == 1 then
            tabButton:SetPoint("TOPLEFT", frame, "TOPLEFT", START_X, START_Y)
            currentRow = 0
            currentCol = 0
        else
            currentCol = currentCol + 1
            if currentCol >= maxTabsPerRow then
                -- Wrap to new row
                currentCol = 0
                currentRow = currentRow + 1
            end

            if currentCol == 0 then
                -- First tab in new row
                tabButton:SetPoint("TOPLEFT", frame, "TOPLEFT", START_X, START_Y - (currentRow * (TAB_HEIGHT + TAB_SPACING)))
            else
                -- Continue on same row
                tabButton:SetPoint("LEFT", frame.tabButtons[i-1], "RIGHT", TAB_SPACING, 0)
            end
        end

        tabButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = nil,
            tile = false,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })

        -- Add textures to make the button properly interactive
        tabButton:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        tabButton:GetNormalTexture():SetVertexColor(0, 0, 0, 0)
        tabButton:GetNormalTexture():SetAllPoints(tabButton)

        tabButton:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        tabButton:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.1)
        tabButton:GetHighlightTexture():SetAllPoints(tabButton)

        -- Make sure the entire button area is clickable
        tabButton:SetHitRectInsets(0, 0, 0, 0)

        local tabText = tabButton:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        tabText:SetPoint("CENTER", tabButton, "CENTER", 0, 0)
        tabText:SetText(tab.name)
        tabButton.text = tabText

        tabButton.tabId = tab.id
        tabButton.isDefault = tab.isDefault

        -- Store click handlers
        tabButton.leftClickHandler = function()
            LogFilterGroup:ShowTab(tabButton.tabId)
        end

        tabButton.rightClickHandler = function()
            -- Allow right-click menu for all tabs (default and custom)
            LogFilterGroup:ShowTabContextMenu(tabButton)
        end

        -- Left click to switch tabs, right click for menu
        tabButton:SetScript("OnClick", function()
            if arg1 == "LeftButton" then
                this.leftClickHandler()
            elseif arg1 == "RightButton" then
                this.rightClickHandler()
            end
        end)

        -- Also handle mouse down for better responsiveness
        tabButton:SetScript("OnMouseDown", function()
            if arg1 == "RightButton" then
                this.rightClickHandler()
            end
        end)

        -- Register for both left and right clicks, both up and down
        tabButton:RegisterForClicks("LeftButtonUp", "RightButtonUp", "RightButtonDown")

        table.insert(frame.tabButtons, tabButton)
    end

    -- Add "+" button to create new tab (only if we have at least one tab)
    if table.getn(frame.tabButtons) > 0 then
        local addTabButton = CreateFrame("Button", "LogFilterGroupAddTab", frame)
        addTabButton:SetWidth(30)
        addTabButton:SetHeight(22)
        addTabButton:SetPoint("LEFT", frame.tabButtons[table.getn(frame.tabButtons)], "RIGHT", 2, 0)
        addTabButton:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = nil,
            tile = false,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        addTabButton:SetBackdropColor(0.08, 0.08, 0.08, 1)

        local addText = addTabButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        addText:SetPoint("CENTER", addTabButton, "CENTER", 0, 0)
        addText:SetText("+")
        addText:SetTextColor(0.5, 0.5, 0.5, 1)

        addTabButton:SetScript("OnClick", function()
            LogFilterGroup:ShowInputDialog("Enter Tab Name", "Custom Tab", function(name)
                if name and name ~= "" then
                    local newTab = LogFilterGroup:AddTab(name)
                    LogFilterGroup:RefreshTabButtons()
                    LogFilterGroup:ShowTab(newTab.id)
                end
            end)
        end)

        frame.addTabButton = addTabButton
    end

    -- Calculate how many rows of tabs we have and adjust content position
    local numRows = currentRow + 1
    local TAB_ROW_HEIGHT = TAB_HEIGHT + TAB_SPACING
    local contentYOffset = -(28 + (numRows * TAB_ROW_HEIGHT) + 5)  -- 28 = initial offset, 5 = spacing

    -- Store contentYOffset for use in UpdateLockState
    frame.contentYOffset = contentYOffset

    -- Update positions of filter elements
    if frame.filterLabel then
        frame.filterLabel:ClearAllPoints()
        frame.filterLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, contentYOffset)
    end

    if frame.excludeLabel then
        frame.excludeLabel:ClearAllPoints()
        frame.excludeLabel:SetPoint("TOPLEFT", frame.filterLabel, "BOTTOMLEFT", 0, -7)
    end

    if frame.autoSendCheckbox then
        frame.autoSendCheckbox:ClearAllPoints()
        frame.autoSendCheckbox:SetPoint("TOPLEFT", frame.excludeLabel, "BOTTOMLEFT", 0, -7)
    end

    if frame.scrollFrame then
        frame.scrollFrame:ClearAllPoints()
        -- Position scroll frame based on lock state
        if self.globalLocked then
            -- When locked, position at contentYOffset (where filters would be)
            frame.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, contentYOffset)
        else
            -- When unlocked, position below autoSendCheckbox
            frame.scrollFrame:SetPoint("TOPLEFT", frame.autoSendCheckbox, "BOTTOMLEFT", 8, -10)
        end
        frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 25)
    end

    -- Update active tab appearance
    self:UpdateTabAppearance()
end

-- Update tab button appearances based on active tab
function LogFilterGroup:UpdateTabAppearance()
    local frame = LogFilterGroupFrame
    if not frame then return end

    for _, button in ipairs(frame.tabButtons) do
        if button.tabId == self.activeTabId then
            button:SetBackdropColor(0.15, 0.15, 0.15, 1)
            button.text:SetTextColor(1, 1, 1, 1)
        else
            button:SetBackdropColor(0.08, 0.08, 0.08, 1)
            button.text:SetTextColor(0.6, 0.6, 0.6, 1)
        end
    end
end

-- Update lock state (enable/disable inputs based on global locked state)
function LogFilterGroup:UpdateLockState()
    local frame = LogFilterGroupFrame
    if not frame then return end

    local locked = self.globalLocked or false

    -- Update lock button texture (use same icon, just change opacity/color when locked)
    if locked then
        frame.lockButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Disabled")
        frame.lockButton:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
    else
        frame.lockButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
        frame.lockButton:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
    end

    -- Hide/show filter inputs and labels
    if locked then
        -- Hide all filter-related elements
        frame.filterLabel:Hide()
        frame.filterInput:Hide()

        frame.excludeLabel:Hide()
        frame.excludeInput:Hide()

        if frame.excludeHelp then
            frame.excludeHelp:Hide()
        end

        frame.autoSendCheckbox:Hide()
        frame.autoSendLabel:Hide()
        frame.whisperMsgInput:Hide()

        -- Expand scroll frame to use the full space (use dynamic contentYOffset)
        frame.scrollFrame:ClearAllPoints()
        local yOffset = frame.contentYOffset or -55  -- Use stored offset or fallback to -55
        frame.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, yOffset)
        frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 25)
    else
        -- Show all filter-related elements
        frame.filterLabel:Show()
        frame.filterInput:Show()

        frame.excludeLabel:Show()
        frame.excludeInput:Show()

        if frame.excludeHelp then
            frame.excludeHelp:Show()
        end

        frame.autoSendCheckbox:Show()
        frame.autoSendLabel:Show()
        frame.whisperMsgInput:Show()

        -- Restore scroll frame to normal position (below the auto-send checkbox)
        frame.scrollFrame:ClearAllPoints()
        frame.scrollFrame:SetPoint("TOPLEFT", frame.autoSendCheckbox, "BOTTOMLEFT", 8, -10)
        frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 25)
    end
end

-- Show a specific tab
function LogFilterGroup:ShowTab(tabId)
    local frame = LogFilterGroupFrame
    if not frame then return end

    -- Verify tab exists, fallback to first tab if not
    if not self:GetTab(tabId) then
        tabId = self.tabs[1].id
    end

    self.activeTabId = tabId
    frame.currentTab = tabId

    -- Update tab button appearances
    self:UpdateTabAppearance()

    -- Update input fields with current tab's settings
    local tab = self:GetTab(tabId)
    if tab then
        frame.filterInput:SetText(tab.filterText)
        frame.excludeInput:SetText(tab.excludeText)
        frame.whisperMsgInput:SetText(tab.whisperTemplate)
        frame.autoSendCheckbox:SetChecked(tab.autoSendWhisper)
    end

    -- Update lock state
    self:UpdateLockState()

    -- Stop flashing this tab since it's now active
    self:StopFlashingTab(tabId)

    -- Update display
    self:UpdateDisplay()
end

-- Check if message passes filters and flash tab if it does
function LogFilterGroup:CheckAndFlashTab(tabId, sender, message)
    local tab = self:GetTab(tabId)
    if not tab then return end

    -- Check if message passes the include filter and exclude filter
    local filterText = tab.filterText
    local excludeText = tab.excludeText

    -- Apply same filter logic as UpdateDisplay
    if LogFilterGroup.MatchesFilter(message, filterText) and not LogFilterGroup.MatchesExclude(message, sender, excludeText) then
        -- Flash tab and play sound only if tab is not muted
        if not tab.muted then
            -- Flash the tab (only for inactive tabs)
            if tabId ~= self.activeTabId then
                self:FlashTab(tabId)
            end

            -- Play sound only if enabled globally AND either window is open
            local isWindowOpen = (LogFilterGroupFrame and LogFilterGroupFrame:IsVisible()) or
                               (LogFilterGroupTinyFrame and LogFilterGroupTinyFrame:IsVisible())
            if self.soundEnabled and isWindowOpen then
                PlaySound("AuctionWindowOpen")
            end
        end
    end
end

-- Update sound button appearance based on soundEnabled state
function LogFilterGroup:UpdateSoundButton()
    local frame = LogFilterGroupFrame
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

-- Flash a tab to draw attention to new messages
function LogFilterGroup:FlashTab(tabId)
    local frame = LogFilterGroupFrame
    if not frame or not frame.tabButtons then return end

    -- Find the tab button
    local tabButton = nil
    for _, button in ipairs(frame.tabButtons) do
        if button.tabId == tabId then
            tabButton = button
            break
        end
    end

    if not tabButton then return end

    -- Mark tab as flashing
    tabButton.isFlashing = true
    tabButton.flashElapsed = 0

    -- Create OnUpdate handler for flashing effect
    if not tabButton.flashScript then
        tabButton.flashScript = true
        tabButton:SetScript("OnUpdate", function()
            if not this.isFlashing then return end

            this.flashElapsed = this.flashElapsed + arg1

            -- Flash every 0.5 seconds
            local flashCycle = math.mod(this.flashElapsed, 1.0)
            if flashCycle < 0.5 then
                -- Bright yellow/gold
                this:SetBackdropColor(0.8, 0.6, 0.1, 1)
                this.text:SetTextColor(1, 1, 0.5, 1)
            else
                -- Normal inactive color
                this:SetBackdropColor(0.08, 0.08, 0.08, 1)
                this.text:SetTextColor(0.6, 0.6, 0.6, 1)
            end
        end)
    end
end

-- Stop flashing a tab
function LogFilterGroup:StopFlashingTab(tabId)
    local frame = LogFilterGroupFrame
    if not frame or not frame.tabButtons then return end

    -- Find the tab button
    for _, button in ipairs(frame.tabButtons) do
        if button.tabId == tabId then
            button.isFlashing = false
            button.flashElapsed = 0
            break
        end
    end

    -- Update tab appearance to restore proper colors
    self:UpdateTabAppearance()
end

-- Update the display
function LogFilterGroup:UpdateDisplay()
    local frame = LogFilterGroupFrame
    if not frame then
        if self.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG UpdateDisplay: frame is nil")
        end
        return
    end

    if not frame:IsVisible() then
        if self.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG UpdateDisplay: frame not visible")
        end
        return
    end

    -- Get current tab and its data
    local tab = self:GetTab(self.activeTabId)
    if not tab then
        if self.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG UpdateDisplay: tab is nil for activeTabId=" .. tostring(self.activeTabId))
        end
        return
    end

    local filterText = tab.filterText
    local excludeText = tab.excludeText

    if self.debugMode then
        local msgCount = 0
        if tab.messageRefs then
            for _ in pairs(tab.messageRefs) do
                msgCount = msgCount + 1
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG UpdateDisplay: Tab '" .. tab.name .. "' has " .. msgCount .. " message references")
    end

    -- Collect messages from central repository for this tab
    local messages = {}
    if tab.messageRefs then
        for messageId, metadata in pairs(tab.messageRefs) do
            local msgData = LogFilterGroup.messageRepository[messageId]
            if msgData then
                -- Apply include filter and exclude filter (exclude checks both message and sender name)
                if LogFilterGroup.MatchesFilter(msgData.message, filterText) and not LogFilterGroup.MatchesExclude(msgData.message, msgData.sender, excludeText) then
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

    if self.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG UpdateDisplay: " .. numMessages .. " messages after filtering")
    end

    -- Calculate how many rows can fit in the current scroll frame height
    local scrollHeight = frame.scrollFrame:GetHeight()
    local visibleRows = math.floor(scrollHeight / ROW_HEIGHT)
    if visibleRows > ROWS_VISIBLE then
        visibleRows = ROWS_VISIBLE
    end

    if self.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG UpdateDisplay: scrollHeight=" .. scrollHeight .. ", visibleRows=" .. visibleRows .. ", ROWS_VISIBLE=" .. ROWS_VISIBLE)
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG UpdateDisplay: scrollFrame visible=" .. tostring(frame.scrollFrame:IsVisible()) .. ", width=" .. frame.scrollFrame:GetWidth() .. ", height=" .. scrollHeight)
    end

    FauxScrollFrame_Update(frame.scrollFrame, numMessages, visibleRows, ROW_HEIGHT)

    for i = 1, ROWS_VISIBLE do
        local row = frame.rows[i]
        local index = i + offset

        if i <= visibleRows and index <= numMessages then
            local data = messages[index]
            row.sender:SetText("|cff00ff00" .. data.sender .. "|r")

            -- Calculate available width for message text
            -- Message FontString is positioned from x=85 to x=-157 from edges via SetPoint
            -- So the available width is: rowWidth - 85 (left margin) - 157 (right margin)
            local rowWidth = row:GetWidth()
            if rowWidth <= 0 then
                rowWidth = frame.scrollFrame:GetWidth() - 25
            end
            local messageWidth = rowWidth - 85 - 157

            -- Ensure minimum width to prevent overlap
            if messageWidth < 50 then
                messageWidth = 50
            end

            local displayText, isTruncated = TruncateMessage(data.message, messageWidth)
            row.message:SetText(displayText)
            row.time:SetText(self:GetTimeAgo(data.timestamp))

            -- Set whisper button text based on whispered state
            if data.whispered then
                row.whisperButtonText:SetText("|cff00ff00Whisper|r")  -- Green text to indicate whispered
            else
                row.whisperButtonText:SetText("Whisper")
            end

            -- Set invite button text based on invited state
            if data.invited then
                row.inviteButtonText:SetText("|cff00ff00Invite|r")  -- Green text to indicate invited
            else
                row.inviteButtonText:SetText("Invite")
            end

            -- Store sender data and full message on row for tooltip
            row.senderName = data.sender
            row.fullMessage = data.message
            row.isTruncated = isTruncated

            -- Configure whisper button behavior
            row.whisperButton:SetScript("OnClick", function()
                if this:GetParent().senderName then
                    local currentTab = LogFilterGroup:GetTab(LogFilterGroup.activeTabId)
                    if currentTab and currentTab.autoSendWhisper and currentTab.whisperTemplate ~= "" then
                        -- Auto-send the prepared message
                        SendChatMessage(currentTab.whisperTemplate, "WHISPER", nil, this:GetParent().senderName)
                    else
                        -- Just prepare the chat window
                        ChatFrameEditBox:SetText("/w " .. this:GetParent().senderName .. " ")
                        ChatFrameEditBox:Show()
                    end

                    -- Mark as whispered and update button
                    LogFilterGroup:MarkAsWhispered(LogFilterGroup.activeTabId, this:GetParent().senderName)
                    this:GetParent().whisperButtonText:SetText("|cff00ff00Whisper|r")  -- Green text to indicate whispered
                end
            end)

            -- Configure clear button behavior
            row.clearButton:SetScript("OnClick", function()
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
                        LogFilterGroup:UpdateDisplay()
                    end
                end
            end)

            row:Show()
        else
            row:Hide()
        end
    end

    -- Update status text
    if numMessages == 0 then
        frame.statusText:SetText("No messages yet. Keep monitoring chat...")
    else
        frame.statusText:SetText(numMessages .. " message(s) found")
    end
end

-- Note: MinimizeMainWindow and RestoreMainWindow are now defined in MinimizeHelper.lua
-- as unified functions that handle both main and separate windows

-- Toggle frame visibility
function LogFilterGroup:ToggleFrame()
    if not LogFilterGroupFrame then
        self:CreateFrame()
    end

    if LogFilterGroupFrame:IsVisible() then
        LogFilterGroupFrame:Hide()
    else
        LogFilterGroupFrame:Show()
        if not self.mainWindowMinimized then
            self:UpdateDisplay()
        end
    end
end
