-- UI for LogFilterGroup

local FRAME_WIDTH = 500
local FRAME_HEIGHT = 400
local ROW_HEIGHT = 30  -- Single line per row (WoW 1.12 doesn't support word wrap on FontStrings)
local ROWS_VISIBLE = 40

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
        dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetFrameLevel(200)
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

-- Show Yes/No confirmation dialog
function LogFilterGroup:ShowConfirmDialog(title, message, yesCallback)
    -- Create popup frame if it doesn't exist
    if not LogFilterGroupConfirmDialog then
        local dialog = CreateFrame("Frame", "LogFilterGroupConfirmDialog", UIParent)
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
        dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetFrameLevel(200)
        dialog:EnableMouse(true)
        dialog:Hide()

        -- Title
        local titleText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetPoint("TOP", dialog, "TOP", 0, -18)
        dialog.titleText = titleText

        -- Message text
        local messageText = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        messageText:SetPoint("TOP", dialog, "TOP", 0, -45)
        messageText:SetWidth(260)
        dialog.messageText = messageText

        -- Yes button
        local yesButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
        yesButton:SetWidth(100)
        yesButton:SetHeight(25)
        yesButton:SetPoint("BOTTOM", dialog, "BOTTOM", -55, 15)
        yesButton:SetText("Yes")
        yesButton:SetScript("OnClick", function()
            if dialog.yesCallback then
                dialog.yesCallback()
            end
            dialog:Hide()
        end)
        dialog.yesButton = yesButton

        -- No button
        local noButton = CreateFrame("Button", nil, dialog, "GameMenuButtonTemplate")
        noButton:SetWidth(100)
        noButton:SetHeight(25)
        noButton:SetPoint("BOTTOM", dialog, "BOTTOM", 55, 15)
        noButton:SetText("No")
        noButton:SetScript("OnClick", function()
            dialog:Hide()
        end)
        dialog.noButton = noButton
    end

    local dialog = LogFilterGroupConfirmDialog
    dialog.titleText:SetText(title)
    dialog.messageText:SetText(message)
    dialog.yesCallback = yesCallback
    dialog:Show()
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
            local wasActiveTab = (LogFilterGroup.activeTabId == tabId)

            if LogFilterGroup:DeleteTab(tabId) then
                LogFilterGroup:RefreshTabButtons()

                -- If we deleted the active tab, ShowTab will properly load the new active tab's settings
                if wasActiveTab then
                    LogFilterGroup:ShowTab(LogFilterGroup.activeTabId)
                else
                    -- Otherwise just update the display
                    LogFilterGroup:UpdateDisplay()
                end
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

-- Helper function to process quoted phrases in filter text
-- Extracts quoted strings and replaces them with placeholders
-- Returns: modified filter text, quote mappings table
local function ProcessQuotes(filterText)
    local quoteMappings = {}
    local quoteCounter = 1
    local result = ""
    local i = 1
    local inQuote = false
    local currentContent = ""

    while i <= string.len(filterText) do
        local char = string.sub(filterText, i, i)

        if char == '"' then
            -- Check if escaped
            local prevChar = i > 1 and string.sub(filterText, i-1, i-1) or ""
            if prevChar == "\\" then
                -- Escaped quote, add to content
                if inQuote then
                    -- Remove the backslash and add the quote
                    currentContent = string.sub(currentContent, 1, -2) .. '"'
                else
                    -- Remove the backslash from result and add the quote
                    result = string.sub(result, 1, -2) .. '"'
                end
            else
                -- Toggle quote state
                if inQuote then
                    -- End quote - create placeholder
                    local placeholder = "___QUOTE" .. quoteCounter .. "___"
                    quoteMappings[placeholder] = currentContent
                    result = result .. placeholder
                    quoteCounter = quoteCounter + 1
                    currentContent = ""
                    inQuote = false
                else
                    -- Start quote
                    inQuote = true
                end
            end
        else
            if inQuote then
                currentContent = currentContent .. char
            else
                result = result .. char
            end
        end

        i = i + 1
    end

    -- Handle unclosed quote (fail open - treat as literal)
    if inQuote then
        result = result .. '"' .. currentContent
    end

    return result, quoteMappings
end

-- Helper function to process match type prefixes and resolve quote placeholders
-- Returns: {matchType = "exact|prefix|suffix|contains", searchTerm = "..."}
local function ProcessMatchTypes(term, quoteMappings)
    -- Handle nil term
    if not term then
        return {matchType = "contains", searchTerm = ""}
    end

    -- Ensure quoteMappings is a table
    if not quoteMappings then
        quoteMappings = {}
    end

    -- Trim whitespace
    term = string.gsub(term, "^%s*(.-)%s*$", "%1")

    -- Use string.find to check for match type prefixes (don't lowercase the whole term yet)
    local colonPos = string.find(term, ":")
    if colonPos then
        local prefix = string.sub(term, 1, colonPos - 1)
        prefix = string.gsub(prefix, "^%s*(.-)%s*$", "%1")  -- Trim prefix
        local lowerPrefix = string.lower(prefix)  -- Lowercase only the prefix for comparison

        -- Check if it's a valid match type
        if lowerPrefix == "exact" or lowerPrefix == "prefix" or lowerPrefix == "suffix" or lowerPrefix == "contains" then
            local searchTerm = string.sub(term, colonPos + 1)
            searchTerm = string.gsub(searchTerm, "^%s*(.-)%s*$", "%1")  -- Trim

            -- Resolve quote placeholder if present (placeholders are case-sensitive)
            if quoteMappings[searchTerm] then
                searchTerm = quoteMappings[searchTerm]
            end

            return {matchType = lowerPrefix, searchTerm = searchTerm}
        end
    end

    -- No valid prefix, default to contains
    local searchTerm = term

    -- Resolve quote placeholder if present
    if quoteMappings[searchTerm] then
        searchTerm = quoteMappings[searchTerm]
    end

    return {matchType = "contains", searchTerm = searchTerm}
end

-- Helper function to perform the actual matching based on match type
-- Returns: boolean indicating if message matches the search term
local function PerformMatch(message, matchType, searchTerm)
    local lowerMessage = string.lower(message)
    local lowerTerm = string.lower(searchTerm)

    -- Empty term matches nothing
    if lowerTerm == "" then
        return false
    end

    if matchType == "exact" then
        -- Exact match: for single words, match whole word; for phrases, match the phrase
        local escapedTerm = EscapePattern(lowerTerm)

        -- Check if term contains spaces (multi-word phrase)
        if string.find(lowerTerm, " ") then
            -- Multi-word phrase: just check if the phrase appears in the message
            if string.find(lowerMessage, escapedTerm) then
                return true
            end
        else
            -- Single word: match as whole word with space boundaries
            local paddedMessage = " " .. lowerMessage .. " "
            local paddedTerm = " " .. lowerTerm .. " "

            if string.find(paddedMessage, paddedTerm, 1, true) then
                return true
            end
        end

        return false

    elseif matchType == "prefix" then
        local escapedTerm = EscapePattern(lowerTerm)
        return string.find(lowerMessage, "^" .. escapedTerm) ~= nil

    elseif matchType == "suffix" then
        local escapedTerm = EscapePattern(lowerTerm)
        return string.find(lowerMessage, escapedTerm .. "$") ~= nil

    else  -- "contains" or any other value (default)
        local escapedTerm = EscapePattern(lowerTerm)
        return string.find(lowerMessage, escapedTerm) ~= nil
    end
end

-- Helper function to truncate message if it's too long and add '...' if truncated
-- Returns: displayText, isTruncated
function LogFilterGroup.TruncateMessage(message, maxWidth)
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
                    if secondEnd and secondEnd <= msgLen then
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
local function EvaluateSimpleExpression(message, expression, quoteMappings, placeholderResults)
    local lowerMessage = string.lower(message)

    -- Trim whitespace from original expression first
    expression = string.gsub(expression, "^%s*(.-)%s*$", "%1")

    -- Check if this is a placeholder reference BEFORE lowercasing
    if placeholderResults and placeholderResults[expression] ~= nil then
        return placeholderResults[expression]
    end

    -- Now convert to lowercase for operator checking
    local lowerExpr = string.lower(expression)

    if lowerExpr == "" then
        return true
    end

    -- Check for OR operator (lower precedence)
    if string.find(lowerExpr, " or ") then
        -- Split by OR using ORIGINAL expression to preserve case
        local orTerms = {}
        local currentTerm = ""
        local i = 1
        while i <= string.len(expression) do
            local char = string.sub(expression, i, i)
            local lowerChar = string.lower(char)
            -- Check if we're at " or " (case-insensitive)
            if string.lower(string.sub(expression, i, i+3)) == " or " then
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
            if EvaluateSimpleExpression(message, term, quoteMappings, placeholderResults) then
                return true
            end
        end
        return false

    -- Check for AND operator (higher precedence)
    elseif string.find(lowerExpr, " and ") then
        -- Split by AND using ORIGINAL expression to preserve case
        local andTerms = {}
        local currentTerm = ""
        local i = 1
        while i <= string.len(expression) do
            local char = string.sub(expression, i, i)
            -- Check if we're at " and " (case-insensitive)
            if string.lower(string.sub(expression, i, i+4)) == " and " then
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

            -- Check if AND term is a placeholder (BEFORE lowercasing!)
            local termResult
            if placeholderResults and placeholderResults[term] ~= nil then
                termResult = placeholderResults[term]
            else
                -- Use new match type processing
                local matchData = ProcessMatchTypes(term, quoteMappings)
                termResult = PerformMatch(message, matchData.matchType, matchData.searchTerm)
            end

            if not termResult then
                return false
            end
        end
        return true

    else
        -- Simple search term - use new match type processing
        local matchData = ProcessMatchTypes(lowerExpr, quoteMappings)
        return PerformMatch(message, matchData.matchType, matchData.searchTerm)
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

    -- Strip newlines from filter text (allows multi-line formatting in config)
    filterText = string.gsub(filterText, "\n", " ")
    filterText = string.gsub(filterText, "\r", "")

    -- Strip item/enchant/spell links before filtering
    message = StripLinks(message)

    -- Process quotes first to extract quoted phrases
    local quoteMappings = {}
    local processedFilter
    processedFilter, quoteMappings = ProcessQuotes(filterText)

    local placeholderCount = 0
    local placeholderResults = {}

    -- Process parentheses recursively (innermost first)
    while string.find(processedFilter, "%(") do
        -- Find innermost parentheses by looking for a closing paren without nested parens
        local startPos = nil
        local endPos = nil

        -- Scan through the string to find innermost parentheses
        local i = 1
        while i <= string.len(processedFilter) do
            if string.sub(processedFilter, i, i) == "(" then
                -- Found an opening paren, this could be our innermost
                startPos = i
            elseif string.sub(processedFilter, i, i) == ")" then
                -- Found a closing paren - this closes the most recent opening paren (which is innermost)
                if startPos then
                    endPos = i
                    break
                end
            end
            i = i + 1
        end

        if not startPos or not endPos then break end

        -- Extract expression inside parentheses (without the parentheses)
        local innerExpr = string.sub(processedFilter, startPos + 1, endPos - 1)

        -- Debug output
        if LogFilterGroup.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG MatchesFilter: Evaluating inner expression: '" .. innerExpr .. "'")
        end

        -- Evaluate the inner expression with quote mappings and placeholder results
        local result = EvaluateSimpleExpression(message, innerExpr, quoteMappings, placeholderResults)

        -- Debug output
        if LogFilterGroup.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG MatchesFilter: Inner expression result: " .. tostring(result))
        end

        -- Create a unique placeholder
        placeholderCount = placeholderCount + 1
        local placeholder = "___PH" .. placeholderCount .. "___"
        placeholderResults[placeholder] = result

        -- Replace the parenthesized expression with the placeholder
        processedFilter = string.sub(processedFilter, 1, startPos - 1) .. placeholder .. string.sub(processedFilter, endPos + 1)

        -- Debug output
        if LogFilterGroup.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG MatchesFilter: Filter after substitution: '" .. processedFilter .. "'")
        end
    end

    -- Evaluate the final expression, treating placeholders as search terms
    -- We need a modified version of EvaluateSimpleExpression that handles placeholders
    local function EvaluateWithPlaceholders(expr)
        -- Trim whitespace but preserve case for placeholders
        expr = string.gsub(expr, "^%s*(.-)%s*$", "%1")

        if expr == "" then
            return true
        end

        -- Use lowercase only for checking operators, not for the whole expression
        local lowerExpr = string.lower(expr)

        -- Check for OR operator
        if string.find(lowerExpr, " or ") then
            local orTerms = {}
            local currentTerm = ""
            local i = 1
            while i <= string.len(expr) do
                local lowerSubstr = string.lower(string.sub(expr, i, i+3))
                if lowerSubstr == " or " then
                    table.insert(orTerms, currentTerm)
                    currentTerm = ""
                    i = i + 4
                else
                    currentTerm = currentTerm .. string.sub(expr, i, i)
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
            while i <= string.len(expr) do
                local lowerSubstr = string.lower(string.sub(expr, i, i+4))
                if lowerSubstr == " and " then
                    table.insert(andTerms, currentTerm)
                    currentTerm = ""
                    i = i + 5
                else
                    currentTerm = currentTerm .. string.sub(expr, i, i)
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
            -- Check if this is a parentheses placeholder (case-sensitive)
            if placeholderResults[expr] ~= nil then
                return placeholderResults[expr]
            end
            -- Otherwise, use new match type processing (preserving case for quote placeholders)
            local matchData = ProcessMatchTypes(expr, quoteMappings)
            return PerformMatch(message, matchData.matchType, matchData.searchTerm)
        end
    end

    -- Debug output
    if LogFilterGroup.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG MatchesFilter: Final filter to evaluate: '" .. processedFilter .. "'")
    end

    local finalResult = EvaluateWithPlaceholders(processedFilter)

    -- Debug output
    if LogFilterGroup.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG MatchesFilter: Final result: " .. tostring(finalResult))
    end

    return finalResult
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
    closeButton:SetScript("OnClick", function()
        frame:Hide()
        LogFilterGroupDB.windowVisible = false
        LogFilterGroup:SaveData()
    end)
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

    -- Configure Tab button (wrench icon, next to sound button)
    local configureButton = CreateFrame("Button", nil, frame)
    configureButton:SetWidth(16)
    configureButton:SetHeight(16)
    configureButton:SetPoint("RIGHT", soundButton, "LEFT", -2, 0)
    configureButton:SetNormalTexture("Interface\\Icons\\INV_Misc_Wrench_01")
    configureButton:SetPushedTexture("Interface\\Icons\\INV_Misc_Wrench_01")
    configureButton:SetHighlightTexture("Interface\\Icons\\INV_Misc_Wrench_01")
    configureButton:GetHighlightTexture():SetAlpha(0.5)
    configureButton:SetScript("OnClick", function()
        LogFilterGroup:ShowConfigureWindow()
    end)
    configureButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Configure Tab\n|cFFFFFFFFEdit tab settings, filters, and whisper template|r")
        GameTooltip:Show()
    end)
    configureButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame.configureButton = configureButton

    -- Clear icon button (next to configure button)
    local clearIconButton = CreateFrame("Button", nil, frame)
    clearIconButton:SetWidth(16)
    clearIconButton:SetHeight(16)
    clearIconButton:SetPoint("RIGHT", configureButton, "LEFT", -2, 0)
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

    -- Help button (next to clear button)
    local helpButton = CreateFrame("Button", nil, frame)
    helpButton:SetWidth(20)
    helpButton:SetHeight(20)
    helpButton:SetPoint("RIGHT", clearIconButton, "LEFT", -3, 0)

    -- Create backdrop for clean button appearance
    helpButton:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    helpButton:SetBackdropColor(0.8, 0.1, 0.1, 1)  -- Red background
    helpButton:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)  -- Dark border

    -- Add a larger "?" text
    local helpText = helpButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    helpText:SetPoint("CENTER", helpButton, "CENTER", 0, 1)
    helpText:SetText("|cFFFFFFFF?|r")
    helpButton.helpText = helpText

    helpButton:SetScript("OnClick", function()
        LogFilterGroup:ShowHelpWindow()
    end)
    helpButton:SetScript("OnEnter", function()
        helpButton:SetBackdropColor(1, 0.2, 0.2, 1)  -- Brighter red on hover
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Help\n|cFFFFFFFFClick for addon help and filter syntax|r")
        GameTooltip:Show()
    end)
    helpButton:SetScript("OnLeave", function()
        helpButton:SetBackdropColor(0.8, 0.1, 0.1, 1)  -- Normal red
        GameTooltip:Hide()
    end)
    frame.helpButton = helpButton

    -- Tab buttons storage (will be created dynamically)
    frame.tabButtons = {}
    frame.currentTab = self.activeTabId

    -- Scroll frame (moved up since Configure button is removed)
    local scrollFrame = CreateFrame("ScrollFrame", "LogFilterGroupScrollFrame", frame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -55)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 22)
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
    -- Completely disable OnSizeChanged processing during resize for maximum performance
    local isResizing = false

    frame:SetScript("OnSizeChanged", function()
        -- Do nothing during resize - we'll update when mouse is released
    end)

    -- Override the resize button to handle updates manually
    resizeButton:SetScript("OnMouseDown", function()
        resizeGrip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        frame:StartSizing("BOTTOMRIGHT")
        isResizing = true
    end)

    resizeButton:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        resizeGrip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        isResizing = false

        -- Now update everything after resize completes
        LogFilterGroup:UpdateDisplay()
        LogFilterGroup:SaveMainFramePosition()
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

    -- Ensure we have at least one tab
    if not self.tabs or table.getn(self.tabs) == 0 then
        self:AddTab("New Tab")
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

        -- Left click to switch tabs
        tabButton:SetScript("OnClick", function()
            LogFilterGroup:ShowTab(tabButton.tabId)
        end)

        -- Register for left click only
        tabButton:RegisterForClicks("LeftButtonUp")

        table.insert(frame.tabButtons, tabButton)
    end

    -- Add Tab button moved to Configure Tab window

    -- Calculate how many rows of tabs we have and adjust content position
    local numRows = currentRow + 1
    local TAB_ROW_HEIGHT = TAB_HEIGHT + TAB_SPACING
    local contentYOffset = -(28 + (numRows * TAB_ROW_HEIGHT) + 5)  -- 28 = initial offset, 5 = spacing

    -- Reposition scrollFrame to start below all tab rows
    if frame.scrollFrame then
        frame.scrollFrame:ClearAllPoints()
        frame.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, contentYOffset)
        frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 22)
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

-- Lock state feature removed - all configuration is now in Configure Tab window

-- Show a specific tab
function LogFilterGroup:ShowTab(tabId)
    local frame = LogFilterGroupFrame
    if not frame then return end

    -- Ensure we have at least one tab
    if not self.tabs or table.getn(self.tabs) == 0 then
        -- Create a default tab if none exist
        self:AddTab("New Tab")
    end

    -- Verify tab exists, fallback to first tab if not
    if not self:GetTab(tabId) then
        if self.tabs[1] then
            tabId = self.tabs[1].id
        else
            return  -- No tabs available, can't continue
        end
    end

    self.activeTabId = tabId
    frame.currentTab = tabId

    -- Sync config window to show this tab
    for i, tab in ipairs(self.tabs) do
        if tab.id == tabId then
            self.configTabIndex = i
            -- Update config window if it's open
            if LogFilterGroupConfigFrame and LogFilterGroupConfigFrame:IsVisible() then
                self:UpdateConfigureWindow()
            end
            break
        end
    end

    -- Update tab button appearances
    self:UpdateTabAppearance()

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
    -- Flash in main UI
    local frame = LogFilterGroupFrame
    if frame and frame.tabButtons then
        -- Find the tab button
        local tabButton = nil
        for _, button in ipairs(frame.tabButtons) do
            if button.tabId == tabId then
                tabButton = button
                break
            end
        end

        if tabButton then
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
    end

    -- Flash in Tiny UI
    local tinyFrame = LogFilterGroupTinyFrame
    if tinyFrame and tinyFrame.tabButtons then
        -- Find the tab button
        local tabButton = nil
        for _, button in ipairs(tinyFrame.tabButtons) do
            if button.tabId == tabId then
                tabButton = button
                break
            end
        end

        if tabButton then
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
                        this:SetBackdropColor(0.1, 0.1, 0.1, 0.7)
                        this.text:SetTextColor(0.7, 0.7, 0.7, 1)
                    end
                end)
            end
        end
    end
end

-- Stop flashing a tab
function LogFilterGroup:StopFlashingTab(tabId)
    -- Stop flashing in main UI
    local frame = LogFilterGroupFrame
    if frame and frame.tabButtons then
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

    -- Stop flashing in Tiny UI
    local tinyFrame = LogFilterGroupTinyFrame
    if tinyFrame and tinyFrame.tabButtons then
        -- Find the tab button
        for _, button in ipairs(tinyFrame.tabButtons) do
            if button.tabId == tabId then
                button.isFlashing = false
                button.flashElapsed = 0
                break
            end
        end

        -- Update Tiny tab appearance to restore proper colors
        self:UpdateTinyTabButtons()
    end
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
    local visibleRows = math.ceil(scrollHeight / ROW_HEIGHT)
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

            local displayText, isTruncated = LogFilterGroup.TruncateMessage(data.message, messageWidth)
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

        -- Restore Tiny mode state if user was in Tiny mode
        if self.inTinyMode then
            self:EnterTinyMode()
            return
        end
    end

    -- Check if user is in Tiny mode
    if self.inTinyMode then
        -- Toggle Tiny frame instead
        if LogFilterGroupTinyFrame and LogFilterGroupTinyFrame:IsVisible() then
            LogFilterGroupTinyFrame:Hide()
            LogFilterGroupDB.windowVisible = false
            self:SaveData()
        else
            if not LogFilterGroupTinyFrame then
                self:EnterTinyMode()
            else
                LogFilterGroupTinyFrame:Show()
                self:UpdateTinyDisplay()
            end
            LogFilterGroupDB.windowVisible = true
            self:SaveData()
        end
    else
        -- Toggle main frame
        if LogFilterGroupFrame:IsVisible() then
            LogFilterGroupFrame:Hide()
            LogFilterGroupDB.windowVisible = false
            self:SaveData()
        else
            LogFilterGroupFrame:Show()
            if not self.mainWindowMinimized then
                self:UpdateDisplay()
            end
            LogFilterGroupDB.windowVisible = true
            self:SaveData()
        end
    end
end

-- Show main frame (used on login)
function LogFilterGroup:ShowFrame()
    if not LogFilterGroupFrame then
        self:CreateFrame()
    end
    LogFilterGroupFrame:Show()
    if not self.mainWindowMinimized then
        self:UpdateDisplay()
    end
    LogFilterGroupDB.windowVisible = true
    self:SaveData()
end

-- Show tiny frame (used on login)
function LogFilterGroup:ShowTinyFrame()
    if not LogFilterGroupTinyFrame then
        self:CreateTinyModeFrame()
    end
    self:UpdateTinyTabButtons()
    LogFilterGroupTinyFrame:Show()
    self:UpdateTinyDisplay()
    self:UpdateTinySoundButton()
    LogFilterGroupDB.windowVisible = true
    self:SaveData()
end

-- Show help window
function LogFilterGroup:ShowHelpWindow()
    -- Create help frame if it doesn't exist
    if not LogFilterGroupHelpFrame then
        local helpFrame = CreateFrame("Frame", "LogFilterGroupHelpFrame", UIParent)
        helpFrame:SetWidth(500)
        helpFrame:SetHeight(550)
        helpFrame:SetPoint("CENTER", UIParent, "CENTER")
        helpFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        helpFrame:SetBackdropColor(0, 0, 0, 1)
        helpFrame:EnableMouse(true)
        helpFrame:SetMovable(true)
        helpFrame:RegisterForDrag("LeftButton")
        helpFrame:SetScript("OnDragStart", function() this:StartMoving() end)
        helpFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
        helpFrame:SetFrameStrata("DIALOG")

        -- Title
        local title = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", helpFrame, "TOP", 0, -20)
        title:SetText("LogFilterGroup - Help")

        -- Close button
        local closeBtn = CreateFrame("Button", nil, helpFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", helpFrame, "TOPRIGHT", -5, -5)

        -- Scroll frame for content
        local scrollFrame = CreateFrame("ScrollFrame", "LogFilterGroupHelpScrollFrame", helpFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 20, -50)
        scrollFrame:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -30, 20)

        -- Content frame
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetWidth(440)
        content:SetHeight(1200)
        scrollFrame:SetScrollChild(content)

        -- Help text
        local helpText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        helpText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
        helpText:SetWidth(440)
        helpText:SetJustifyH("LEFT")
        helpText:SetJustifyV("TOP")
        helpText:SetText(
            "|cFFFFD700Overview|r\n" ..
            "LogFilterGroup filters LFG/LFM messages from chat channels. Messages are organized into tabs with customizable filters.\n\n" ..

            "|cFFFFD700Tab Management|r\n" ..
            "|cFFFFFFFF• Default Tabs:|r Find Group, Find Member, Professions\n" ..
            "|cFFFFFFFF• Custom Tabs:|r Use Configure Tab menu to create/rename/delete/mute\n" ..
            "|cFFFFFFFF• Muted Tabs:|r No sound/flash notifications for new messages\n\n" ..

            "|cFFFFD700Filter Field|r\n" ..
            "Show only messages matching your filter. Supports AND/OR logic and quotes.\n\n" ..

            "|cFFFFD700Exclude Field|r\n" ..
            "Hide messages matching this filter (checked against both message and sender).\n\n" ..

            "|cFFFFD700Filter Syntax|r\n" ..
            "|cFFFFFFFF• Basic:|r |cFF00FF00tank|r - contains \"tank\"\n" ..
            "|cFFFFFFFF• Quotes:|r |cFF00FF00\"dark iron helm\"|r - exact phrase\n" ..
            "|cFFFFFFFF• AND:|r |cFF00FF00tank AND healer|r - must have both\n" ..
            "|cFFFFFFFF• OR:|r |cFF00FF00tank OR healer|r - either one\n" ..
            "|cFFFFFFFF• Parentheses:|r |cFF00FF00(tank OR heal) AND lfm|r\n" ..
            "|cFFFFFFFF• Exact word:|r |cFF00FF00exact:tank|r - whole word only\n" ..
            "|cFFFFFFFF• Starts with:|r |cFF00FF00prefix:lf|r - message starts with\n" ..
            "|cFFFFFFFF• Ends with:|r |cFF00FF00suffix:pst|r - message ends with\n" ..
            "|cFFFFFFFF• Contains:|r |cFF00FF00contains:tank|r - same as basic\n\n" ..

            "|cFFFFD700Match Type Examples|r\n" ..
            "|cFFFFFFFF• |cFF00FF00exact:\"lf tank\"|r - phrase anywhere in message\n" ..
            "|cFFFFFFFF• |cFF00FF00prefix:\"looking for\"|r - starts with phrase\n" ..
            "|cFFFFFFFF• |cFF00FF00suffix:\"pst me\"|r - ends with phrase\n" ..
            "|cFFFFFFFF• |cFF00FF00(exact:tank OR exact:heal) AND prefix:lf|r\n\n" ..

            "|cFFFFD700Whisper Template|r\n" ..
            "Set a template message (e.g., \"inv\"). Click a message to auto-whisper the sender.\n\n" ..

            "|cFFFFD700Action Buttons|r\n" ..
            "|cFFFFFFFF• Whisper:|r Send template to sender (or blank if no template)\n" ..
            "|cFFFFFFFF• Invite:|r Invite sender to group\n" ..
            "|cFFFFFFFF• Clear:|r Remove all messages from current tab\n\n" ..

            "|cFFFFD700Title Bar Buttons|r\n" ..
            "|cFFFFFFFF• Help (?):|r Show this help window\n" ..
            "|cFFFFFFFF• Clear (X):|r Remove all messages from current tab\n" ..
            "|cFFFFFFFF• Lock:|r Prevent editing filters\n" ..
            "|cFFFFFFFF• Sound:|r Toggle notification sounds\n" ..
            "|cFFFFFFFF• Minimize (-):|r Minimize to title bar\n" ..
            "|cFFFFFFFF• Close:|r Hide addon window\n\n" ..

            "|cFFFFD700Tips|r\n" ..
            "|cFFFFFFFF• Right-click tabs for more options\n" ..
            "|cFFFFFFFF• Use quotes for multi-word phrases\n" ..
            "|cFFFFFFFF• Combine match types with AND/OR for powerful filters\n" ..
            "|cFFFFFFFF• Messages auto-clear after 5 minutes|r"
        )

        helpFrame:Hide()
    end

    -- Toggle visibility
    if LogFilterGroupHelpFrame:IsVisible() then
        LogFilterGroupHelpFrame:Hide()
    else
        LogFilterGroupHelpFrame:Show()
    end
end

-- Show configuration window for current tab
function LogFilterGroup:ShowConfigureWindow()
    -- Initialize config tab index to match the active tab
    if not self.configTabIndex then
        for i, tab in ipairs(self.tabs) do
            if tab.id == self.activeTabId then
                self.configTabIndex = i
                break
            end
        end
        if not self.configTabIndex then
            self.configTabIndex = 1
        end
    end

    local tab = self.tabs[self.configTabIndex]
    if not tab then
        return
    end

    -- Create config frame if it doesn't exist
    if not LogFilterGroupConfigFrame then
        LogFilterGroupConfigFrame = CreateFrame("Frame", "LogFilterGroupConfigFrame", UIParent)
        local configFrame = LogFilterGroupConfigFrame
        configFrame:SetWidth(500)
        configFrame:SetHeight(550)
        configFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        configFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        configFrame:SetMovable(true)
        configFrame:EnableMouse(true)
        configFrame:RegisterForDrag("LeftButton")
        configFrame:SetScript("OnDragStart", function() this:StartMoving() end)
        configFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
        configFrame:SetFrameStrata("DIALOG")

        -- Title
        local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", configFrame, "TOP", 0, -15)
        title:SetText("Configure Tabs")
        configFrame.title = title

        -- Tab navigation row
        -- Previous Tab button
        local prevTabButton = CreateFrame("Button", nil, configFrame)
        prevTabButton:SetWidth(30)
        prevTabButton:SetHeight(22)
        prevTabButton:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, -40)
        prevTabButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        prevTabButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
        prevTabButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        prevTabButton:SetScript("OnClick", function()
            LogFilterGroup:ShowPreviousConfigTab()
        end)
        configFrame.prevTabButton = prevTabButton

        -- Current tab display
        local currentTabDisplay = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        currentTabDisplay:SetPoint("LEFT", prevTabButton, "RIGHT", 10, 0)
        currentTabDisplay:SetWidth(200)
        currentTabDisplay:SetJustifyH("CENTER")
        configFrame.currentTabDisplay = currentTabDisplay

        -- Next Tab button
        local nextTabButton = CreateFrame("Button", nil, configFrame)
        nextTabButton:SetWidth(30)
        nextTabButton:SetHeight(22)
        nextTabButton:SetPoint("LEFT", currentTabDisplay, "RIGHT", 10, 0)
        nextTabButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        nextTabButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
        nextTabButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        nextTabButton:SetScript("OnClick", function()
            LogFilterGroup:ShowNextConfigTab()
        end)
        configFrame.nextTabButton = nextTabButton

        -- Add New Tab button
        local addNewTabButton = CreateFrame("Button", nil, configFrame)
        addNewTabButton:SetWidth(80)
        addNewTabButton:SetHeight(22)
        addNewTabButton:SetPoint("LEFT", nextTabButton, "RIGHT", 15, 0)
        addNewTabButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        addNewTabButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        addNewTabButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        addNewTabButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        addNewTabButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        addNewTabButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        local addNewTabText = addNewTabButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        addNewTabText:SetPoint("CENTER", addNewTabButton, "CENTER", 0, 0)
        addNewTabText:SetText("Add New Tab")

        addNewTabButton:SetScript("OnClick", function()
            LogFilterGroup:ShowInputDialog("Enter Tab Name", "New Tab", function(name)
                if name and name ~= "" then
                    local newTab = LogFilterGroup:AddTab(name)
                    -- Switch to the newly created tab
                    LogFilterGroup.activeTabId = newTab.id
                    -- Update config window to show new tab
                    LogFilterGroup.configTabIndex = table.getn(LogFilterGroup.tabs)
                    LogFilterGroup:UpdateConfigureWindow()
                    -- Refresh UI based on current mode
                    if LogFilterGroup.inTinyMode then
                        -- In Tiny Mode, update the tiny display and tab buttons
                        LogFilterGroup:UpdateTinyTabButtons()
                        LogFilterGroup:UpdateTinyDisplay()
                    else
                        -- In Main UI mode, refresh the display
                        if LogFilterGroupFrame then
                            LogFilterGroup:RefreshTabButtons()
                            LogFilterGroup:UpdateDisplay()
                        end
                    end
                end
            end)
        end)
        configFrame.addNewTabButton = addNewTabButton

        -- Tab Name label and input (moved down to accommodate navigation)
        local tabNameLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabNameLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, -75)
        tabNameLabel:SetText("Tab Name:")

        local tabNameInput = CreateFrame("EditBox", nil, configFrame)
        tabNameInput:SetWidth(200)
        tabNameInput:SetHeight(20)
        tabNameInput:SetPoint("LEFT", tabNameLabel, "RIGHT", 10, 0)
        tabNameInput:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        tabNameInput:SetBackdropColor(0, 0, 0, 0.8)
        tabNameInput:SetFontObject(GameFontNormal)
        tabNameInput:SetTextInsets(5, 5, 0, 0)
        tabNameInput:EnableMouse(true)
        tabNameInput:SetAutoFocus(false)
        tabNameInput:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        tabNameInput:SetScript("OnEnterPressed", function() this:ClearFocus() end)

        configFrame.tabNameInput = tabNameInput

        -- Filter label
        local filterLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        filterLabel:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 20, -110)
        filterLabel:SetText("Filter (messages matching this will be shown):")

        -- Filter input - large multi-line box
        local filterInput = CreateFrame("EditBox", nil, configFrame)
        filterInput:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -5)
        filterInput:SetWidth(460)
        filterInput:SetHeight(100)
        filterInput:SetMultiLine(true)
        filterInput:SetMaxLetters(0)
        filterInput:SetFontObject(GameFontNormal)
        filterInput:SetTextInsets(8, 8, 8, 8)
        filterInput:SetAutoFocus(false)
        filterInput:EnableMouse(true)
        filterInput:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        filterInput:SetBackdropColor(0, 0, 0, 0.8)
        filterInput:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        filterInput:SetScript("OnEnterPressed", function()
            -- Allow Enter to add newlines in multi-line edit box
            local text = this:GetText()
            local cursorPos = this:GetCursorPosition()
            local newText = string.sub(text, 1, cursorPos) .. "\n" .. string.sub(text, cursorPos + 1)
            this:SetText(newText)
            this:SetCursorPosition(cursorPos + 1)
        end)
        filterInput:SetScript("OnTextChanged", function()
            -- Temporarily update the config tab's filter for preview (without saving)
            local currentTab = LogFilterGroup.tabs[LogFilterGroup.configTabIndex]
            if currentTab then
                currentTab.filterText = this:GetText()
                -- Only update display if this is the active tab in main UI
                if currentTab.id == LogFilterGroup.activeTabId then
                    LogFilterGroup:UpdateDisplay()
                end
            end
        end)

        configFrame.filterInput = filterInput

        -- Exclude label
        local excludeLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        excludeLabel:SetPoint("TOPLEFT", filterInput, "BOTTOMLEFT", 0, -10)
        excludeLabel:SetText("Exclude (messages matching this will be hidden):")

        -- Exclude input - large multi-line box
        local excludeInput = CreateFrame("EditBox", nil, configFrame)
        excludeInput:SetPoint("TOPLEFT", excludeLabel, "BOTTOMLEFT", 0, -5)
        excludeInput:SetWidth(460)
        excludeInput:SetHeight(100)
        excludeInput:SetMultiLine(true)
        excludeInput:SetMaxLetters(0)
        excludeInput:SetFontObject(GameFontNormal)
        excludeInput:SetTextInsets(8, 8, 8, 8)
        excludeInput:SetAutoFocus(false)
        excludeInput:EnableMouse(true)
        excludeInput:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        excludeInput:SetBackdropColor(0, 0, 0, 0.8)
        excludeInput:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        excludeInput:SetScript("OnEnterPressed", function()
            -- Allow Enter to add newlines in multi-line edit box
            local text = this:GetText()
            local cursorPos = this:GetCursorPosition()
            local newText = string.sub(text, 1, cursorPos) .. "\n" .. string.sub(text, cursorPos + 1)
            this:SetText(newText)
            this:SetCursorPosition(cursorPos + 1)
        end)
        excludeInput:SetScript("OnTextChanged", function()
            -- Temporarily update the config tab's exclude filter for preview (without saving)
            local currentTab = LogFilterGroup.tabs[LogFilterGroup.configTabIndex]
            if currentTab then
                currentTab.excludeText = this:GetText()
                -- Only update display if this is the active tab in main UI
                if currentTab.id == LogFilterGroup.activeTabId then
                    LogFilterGroup:UpdateDisplay()
                end
            end
        end)

        configFrame.excludeInput = excludeInput

        -- Whisper Template label and input
        local whisperLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        whisperLabel:SetPoint("TOPLEFT", excludeInput, "BOTTOMLEFT", 0, -10)
        whisperLabel:SetText("Whisper Template:")

        local whisperInput = CreateFrame("EditBox", nil, configFrame)
        whisperInput:SetWidth(200)
        whisperInput:SetHeight(20)
        whisperInput:SetPoint("LEFT", whisperLabel, "RIGHT", 10, 0)
        whisperInput:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        whisperInput:SetBackdropColor(0, 0, 0, 0.8)
        whisperInput:SetFontObject(GameFontNormal)
        whisperInput:SetTextInsets(5, 5, 0, 0)
        whisperInput:EnableMouse(true)
        whisperInput:SetAutoFocus(false)
        whisperInput:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        whisperInput:SetScript("OnEnterPressed", function() this:ClearFocus() end)

        configFrame.whisperInput = whisperInput

        -- Use Template checkbox
        local useTemplateCheckbox = CreateFrame("CheckButton", nil, configFrame, "UICheckButtonTemplate")
        useTemplateCheckbox:SetWidth(20)
        useTemplateCheckbox:SetHeight(20)
        useTemplateCheckbox:SetPoint("LEFT", whisperInput, "RIGHT", 10, 0)

        configFrame.useTemplateCheckbox = useTemplateCheckbox

        local useTemplateLabel = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        useTemplateLabel:SetPoint("LEFT", useTemplateCheckbox, "RIGHT", 5, 0)
        useTemplateLabel:SetText("Use Template")

        -- Action buttons row (Mute, Delete, Rename)
        local muteButton = CreateFrame("Button", nil, configFrame)
        muteButton:SetWidth(80)
        muteButton:SetHeight(22)
        muteButton:SetPoint("TOPLEFT", whisperLabel, "BOTTOMLEFT", 0, -15)
        muteButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        muteButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        muteButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        muteButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        muteButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        muteButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        local muteButtonText = muteButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        muteButtonText:SetPoint("CENTER", muteButton, "CENTER", 0, 0)
        muteButtonText:SetText("Mute Tab")

        muteButton.text = muteButtonText

        muteButton:SetScript("OnClick", function()
            local currentTab = LogFilterGroup.tabs[LogFilterGroup.configTabIndex]
            if currentTab then
                currentTab.muted = not currentTab.muted
                muteButtonText:SetText(currentTab.muted and "Unmute Tab" or "Mute Tab")
                LogFilterGroup:SaveSettings()
                LogFilterGroup:UpdateTabAppearance()
            end
        end)

        configFrame.muteButton = muteButton

        local deleteButton = CreateFrame("Button", nil, configFrame)
        deleteButton:SetWidth(80)
        deleteButton:SetHeight(22)
        deleteButton:SetPoint("LEFT", muteButton, "RIGHT", 10, 0)
        deleteButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        deleteButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        deleteButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        deleteButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        deleteButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        deleteButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        local deleteButtonText = deleteButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        deleteButtonText:SetPoint("CENTER", deleteButton, "CENTER", 0, 0)
        deleteButtonText:SetText("Delete Tab")

        deleteButton:SetScript("OnClick", function()
            local currentTab = LogFilterGroup.tabs[LogFilterGroup.configTabIndex]
            if currentTab then
                LogFilterGroup:ShowConfirmDialog(
                    "Delete Tab?",
                    "Are you sure you want to delete '" .. currentTab.name .. "'?",
                    function()
                        if LogFilterGroup:DeleteTab(currentTab.id) then
                            -- Adjust config index if needed
                            if LogFilterGroup.configTabIndex > table.getn(LogFilterGroup.tabs) then
                                LogFilterGroup.configTabIndex = table.getn(LogFilterGroup.tabs)
                            end
                            -- If we have tabs left, update to show the new current tab
                            if table.getn(LogFilterGroup.tabs) > 0 then
                                LogFilterGroup:UpdateConfigureWindow()
                            else
                                configFrame:Hide()
                            end
                            -- Refresh UI based on current mode
                            if LogFilterGroup.inTinyMode then
                                -- In Tiny Mode, just update the tiny display and tab buttons
                                LogFilterGroup:UpdateTinyTabButtons()
                                LogFilterGroup:UpdateTinyDisplay()
                            else
                                -- In Main UI mode, recreate the main frame to rebuild tabs
                                if LogFilterGroupFrame then
                                    LogFilterGroupFrame:Hide()
                                    LogFilterGroupFrame = nil
                                end
                                LogFilterGroup:ShowFrame()
                            end
                        end
                    end
                )
            end
        end)

        configFrame.deleteButton = deleteButton

        -- Cancel button
        local cancelButton = CreateFrame("Button", nil, configFrame)
        cancelButton:SetWidth(100)
        cancelButton:SetHeight(22)
        cancelButton:SetPoint("BOTTOM", configFrame, "BOTTOM", 55, 20)
        cancelButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        cancelButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        cancelButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        cancelButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        cancelButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        cancelButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        local cancelButtonText = cancelButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        cancelButtonText:SetPoint("CENTER", cancelButton, "CENTER", 0, 0)
        cancelButtonText:SetText("Cancel")

        cancelButton:SetScript("OnClick", function()
            -- Restore original values for current config tab
            local currentTab = LogFilterGroup.tabs[LogFilterGroup.configTabIndex]
            if currentTab and configFrame.originalTabName then
                currentTab.name = configFrame.originalTabName
                currentTab.filterText = configFrame.originalFilterText
                currentTab.excludeText = configFrame.originalExcludeText
                currentTab.whisperTemplate = configFrame.originalWhisperTemplate
                currentTab.autoSendWhisper = configFrame.originalAutoSendWhisper
                currentTab.muted = configFrame.originalMuted
                LogFilterGroup:SaveSettings()
                LogFilterGroup:UpdateTabAppearance()
                LogFilterGroup:UpdateDisplay()
            end
            configFrame:Hide()
        end)

        configFrame.cancelButton = cancelButton

        -- Save button
        local saveButton = CreateFrame("Button", nil, configFrame)
        saveButton:SetWidth(100)
        saveButton:SetHeight(22)
        saveButton:SetPoint("BOTTOM", configFrame, "BOTTOM", -55, 20)
        saveButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        saveButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        saveButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        saveButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        saveButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        saveButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        local saveButtonText = saveButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        saveButtonText:SetPoint("CENTER", saveButton, "CENTER", 0, 0)
        saveButtonText:SetText("Save")

        saveButton:SetScript("OnClick", function()
            -- Save current config tab
            local currentTab = LogFilterGroup.tabs[LogFilterGroup.configTabIndex]
            if currentTab then
                currentTab.name = configFrame.tabNameInput:GetText()
                currentTab.filterText = configFrame.filterInput:GetText()
                currentTab.excludeText = configFrame.excludeInput:GetText()
                currentTab.whisperTemplate = configFrame.whisperInput:GetText()
                currentTab.autoSendWhisper = configFrame.useTemplateCheckbox:GetChecked()
                LogFilterGroup:SaveSettings()
                -- Refresh UI based on current mode
                if LogFilterGroup.inTinyMode then
                    -- In Tiny Mode, just update the tiny display and tab buttons
                    LogFilterGroup:UpdateTinyTabButtons()
                    LogFilterGroup:UpdateTinyDisplay()
                else
                    -- In Main UI mode, refresh the main frame
                    if LogFilterGroupFrame then
                        LogFilterGroupFrame:Hide()
                        LogFilterGroupFrame = nil
                    end
                    LogFilterGroup:ShowFrame()
                end
                print("LogFilterGroup: Tab configuration saved!")
            end
            configFrame:Hide()
        end)

        configFrame.saveButton = saveButton

        configFrame:Hide()
    end

    -- Call update function to load current tab data
    self:UpdateConfigureWindow()

    -- Show the window
    LogFilterGroupConfigFrame:Show()
end

-- Update configure window with current tab data
function LogFilterGroup:UpdateConfigureWindow()
    if not LogFilterGroupConfigFrame then return end

    local tab = self.tabs[self.configTabIndex]
    if not tab then return end

    -- Update tab display
    LogFilterGroupConfigFrame.currentTabDisplay:SetText(string.format("Tab %d of %d: %s", self.configTabIndex, table.getn(self.tabs), tab.name))

    -- Store original values for Cancel button
    LogFilterGroupConfigFrame.originalTabName = tab.name
    LogFilterGroupConfigFrame.originalFilterText = tab.filterText or ""
    LogFilterGroupConfigFrame.originalExcludeText = tab.excludeText or ""
    LogFilterGroupConfigFrame.originalWhisperTemplate = tab.whisperTemplate or ""
    LogFilterGroupConfigFrame.originalAutoSendWhisper = tab.autoSendWhisper or false
    LogFilterGroupConfigFrame.originalMuted = tab.muted or false

    -- Load current values
    LogFilterGroupConfigFrame.tabNameInput:SetText(tab.name)
    LogFilterGroupConfigFrame.filterInput:SetText(tab.filterText or "")
    LogFilterGroupConfigFrame.excludeInput:SetText(tab.excludeText or "")
    LogFilterGroupConfigFrame.whisperInput:SetText(tab.whisperTemplate or "")
    LogFilterGroupConfigFrame.useTemplateCheckbox:SetChecked(tab.autoSendWhisper or false)

    -- Update mute button text
    LogFilterGroupConfigFrame.muteButton.text:SetText(tab.muted and "Unmute Tab" or "Mute Tab")

    -- Enable/disable prev/next buttons
    LogFilterGroupConfigFrame.prevTabButton:SetAlpha(self.configTabIndex > 1 and 1 or 0.3)
    LogFilterGroupConfigFrame.nextTabButton:SetAlpha(self.configTabIndex < table.getn(self.tabs) and 1 or 0.3)
end

-- Navigate to previous tab in configure window
function LogFilterGroup:ShowPreviousConfigTab()
    if self.configTabIndex > 1 then
        self.configTabIndex = self.configTabIndex - 1
        -- Switch main UI to this tab
        local tab = self.tabs[self.configTabIndex]
        if tab then
            self:ShowTab(tab.id)
        end
        self:UpdateConfigureWindow()
    end
end

-- Navigate to next tab in configure window
function LogFilterGroup:ShowNextConfigTab()
    if self.configTabIndex < table.getn(self.tabs) then
        self.configTabIndex = self.configTabIndex + 1
        -- Switch main UI to this tab
        local tab = self.tabs[self.configTabIndex]
        if tab then
            self:ShowTab(tab.id)
        end
        self:UpdateConfigureWindow()
    end
end
