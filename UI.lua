-- UI for LogFilterGroup

local FRAME_WIDTH = 500
local FRAME_HEIGHT = 400
local ROW_HEIGHT = 30  -- Single line per row (WoW 1.12 doesn't support word wrap on FontStrings)
local ROWS_VISIBLE = 10

-- Helper function to escape pattern characters for literal search
local function EscapePattern(str)
    return string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

-- Helper function to truncate message if it's too long and add '...' if truncated
-- Returns: displayText, isTruncated
local function TruncateMessage(message, maxWidth)
    -- Approximate character count based on width
    -- GameFontNormalSmall is roughly 6-7 pixels per character
    local maxChars = math.floor(maxWidth / 7)

    if string.len(message) <= maxChars then
        return message, false
    end

    -- Truncate and add ellipsis
    local truncated = string.sub(message, 1, maxChars - 3) .. "..."
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

-- Parse and evaluate filter expression with AND/OR logic and parentheses
local function MatchesFilter(message, filterText)
    if not filterText or filterText == "" then
        return true
    end

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


-- Create main frame
function LogFilterGroup:CreateFrame()
    if LogFilterGroupFrame then
        return
    end
    
    -- Main frame
    local frame = CreateFrame("Frame", "LogFilterGroupFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
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
    frame:SetResizable(true)
    frame:SetMinResize(300, 350)
    frame:SetMaxResize(1000, 800)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("LogFilterGroup")

    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    -- Minimize button
    local minimizeButton = CreateFrame("Button", nil, frame)
    minimizeButton:SetWidth(16)
    minimizeButton:SetHeight(16)
    minimizeButton:SetPoint("RIGHT", closeButton, "LEFT", -2, 0)
    minimizeButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    minimizeButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    minimizeButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    minimizeButton:SetScript("OnClick", function()
        LogFilterGroup:MinimizeMainWindow()
    end)
    frame.minimizeButton = minimizeButton

    -- Clear icon button (next to minimize button)
    local clearIconButton = CreateFrame("Button", nil, frame)
    clearIconButton:SetWidth(16)
    clearIconButton:SetHeight(16)
    clearIconButton:SetPoint("RIGHT", minimizeButton, "LEFT", -2, 0)
    clearIconButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearIconButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
    clearIconButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearIconButton:GetHighlightTexture():SetAlpha(0.5)

    clearIconButton:SetScript("OnClick", function()
        local parentFrame = this:GetParent()
        if parentFrame.currentTab == "lfm" then
            LogFilterGroup.lfmMessages = {}
        elseif parentFrame.currentTab == "lfg" then
            LogFilterGroup.lfgMessages = {}
        else
            LogFilterGroup.professionMessages = {}
        end
        LogFilterGroup:SaveData()
        LogFilterGroup:UpdateDisplay()
    end)
    frame.clearIconButton = clearIconButton

    -- Tab buttons (simple text-based design)
    local lfmTab = CreateFrame("Button", "LogFilterGroupLFMTab", frame)
    lfmTab:SetWidth(80)
    lfmTab:SetHeight(22)
    lfmTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -28)
    lfmTab:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = nil,
        tile = false,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    lfmTab:SetBackdropColor(0.15, 0.15, 0.15, 1)

    local lfmTabText = lfmTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lfmTabText:SetPoint("CENTER", lfmTab, "CENTER", 0, 0)
    lfmTabText:SetText("Find Group")

    lfmTab:SetScript("OnClick", function()
        LogFilterGroup:ShowTab("lfm")
    end)
    frame.lfmTab = lfmTab
    frame.lfmTabText = lfmTabText

    local lfgTab = CreateFrame("Button", "LogFilterGroupLFGTab", frame)
    lfgTab:SetWidth(80)
    lfgTab:SetHeight(22)
    lfgTab:SetPoint("LEFT", lfmTab, "RIGHT", 2, 0)
    lfgTab:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = nil,
        tile = false,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    lfgTab:SetBackdropColor(0.08, 0.08, 0.08, 1)

    local lfgTabText = lfgTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lfgTabText:SetPoint("CENTER", lfgTab, "CENTER", 0, 0)
    lfgTabText:SetText("Find Member")

    lfgTab:SetScript("OnClick", function()
        LogFilterGroup:ShowTab("lfg")
    end)
    frame.lfgTab = lfgTab
    frame.lfgTabText = lfgTabText

    local professionTab = CreateFrame("Button", "LogFilterGroupProfessionTab", frame)
    professionTab:SetWidth(80)
    professionTab:SetHeight(22)
    professionTab:SetPoint("LEFT", lfgTab, "RIGHT", 2, 0)
    professionTab:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = nil,
        tile = false,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    professionTab:SetBackdropColor(0.08, 0.08, 0.08, 1)

    local professionTabText = professionTab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    professionTabText:SetPoint("CENTER", professionTab, "CENTER", 0, 0)
    professionTabText:SetText("Professions")

    professionTab:SetScript("OnClick", function()
        LogFilterGroup:ShowTab("profession")
    end)
    frame.professionTab = professionTab
    frame.professionTabText = professionTabText

    -- Separate window icon button (appears next to active tab)
    local separateButton = CreateFrame("Button", nil, frame)
    separateButton:SetWidth(16)
    separateButton:SetHeight(16)
    separateButton:SetPoint("LEFT", lfmTab, "RIGHT", 4, 0)
    separateButton:SetFrameLevel(frame:GetFrameLevel() + 2)
    separateButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    separateButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    separateButton:SetHighlightTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    separateButton:GetHighlightTexture():SetAlpha(0.5)

    separateButton:SetScript("OnClick", function()
        local parentFrame = this:GetParent()
        local tab = parentFrame.currentTab

        -- Check if we can pop out (need at least 2 tabs visible)
        if LogFilterGroup:CountVisibleTabs() <= 1 then
            DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup: Cannot pop out the last remaining tab.")
            return
        end

        -- Mark tab as popped out
        LogFilterGroup.poppedOutTabs[tab] = true

        -- Create and show the separate window
        if tab == "lfm" then
            if not LogFilterGroupLFMWindow then
                LogFilterGroup:CreateSeparateWindow("lfm")
            end
            LogFilterGroupLFMWindow:Show()
        elseif tab == "lfg" then
            if not LogFilterGroupLFGWindow then
                LogFilterGroup:CreateSeparateWindow("lfg")
            end
            LogFilterGroupLFGWindow:Show()
        else
            if not LogFilterGroupProfessionWindow then
                LogFilterGroup:CreateSeparateWindow("profession")
            end
            LogFilterGroupProfessionWindow:Show()
        end

        -- Switch to first available tab and update display
        LogFilterGroup:ShowTab(tab)
        LogFilterGroup:UpdateTabVisibility()
    end)
    frame.separateButton = separateButton
    
    -- Filter label
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -55)
    filterLabel:SetText("Filter:")
    frame.filterLabel = filterLabel

    -- LFM/LFG Filter input box
    local filterInputLFM = CreateFrame("EditBox", "LogFilterGroupFilterInputLFM", frame)
    filterInputLFM:SetHeight(20)
    filterInputLFM:SetPoint("LEFT", filterLabel, "RIGHT", 3, 0)
    filterInputLFM:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    filterInputLFM:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    filterInputLFM:SetBackdropColor(0, 0, 0, 0.8)
    filterInputLFM:SetFontObject(GameFontNormal)
    filterInputLFM:SetTextInsets(5, 5, 0, 0)
    filterInputLFM:SetAutoFocus(false)
    filterInputLFM:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    filterInputLFM:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    filterInputLFM:SetScript("OnTextChanged", function()
        LogFilterGroup.filterTextLFM = this:GetText()
        LogFilterGroup:SaveSettings()
        LogFilterGroup:UpdateDisplay()
    end)
    frame.filterInputLFM = filterInputLFM

    -- Profession Filter input box
    local filterInputProfession = CreateFrame("EditBox", "LogFilterGroupFilterInputProfession", frame)
    filterInputProfession:SetHeight(20)
    filterInputProfession:SetPoint("LEFT", filterLabel, "RIGHT", 3, 0)
    filterInputProfession:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    filterInputProfession:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    filterInputProfession:SetBackdropColor(0, 0, 0, 0.8)
    filterInputProfession:SetFontObject(GameFontNormal)
    filterInputProfession:SetTextInsets(5, 5, 0, 0)
    filterInputProfession:SetAutoFocus(false)
    filterInputProfession:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    filterInputProfession:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    filterInputProfession:SetScript("OnTextChanged", function()
        LogFilterGroup.filterTextProfession = this:GetText()
        LogFilterGroup:SaveSettings()
        LogFilterGroup:UpdateDisplay()
    end)
    frame.filterInputProfession = filterInputProfession

    -- Filter help text
    local filterHelp = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterHelp:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -2)
    filterHelp:SetText("|cffaaaaaa(You can use 1 and/or statement)|r")
    frame.filterHelp = filterHelp

    -- Auto-send whisper checkbox
    local autoSendCheckbox = CreateFrame("CheckButton", "LogFilterGroupAutoSendCheckbox", frame, "UICheckButtonTemplate")
    autoSendCheckbox:SetWidth(20)
    autoSendCheckbox:SetHeight(20)
    autoSendCheckbox:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -18)
    autoSendCheckbox:SetScript("OnClick", function()
        LogFilterGroup.autoSendWhisper = this:GetChecked()
        LogFilterGroup:SaveSettings()
    end)
    frame.autoSendCheckbox = autoSendCheckbox

    local autoSendLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoSendLabel:SetPoint("LEFT", autoSendCheckbox, "RIGHT", 5, 0)
    autoSendLabel:SetText("Use Template")
    frame.autoSendLabel = autoSendLabel

    -- LFM Whisper message input box
    local whisperMsgInputLFM = CreateFrame("EditBox", "LogFilterGroupWhisperMsgInputLFM", frame)
    whisperMsgInputLFM:SetHeight(20)
    whisperMsgInputLFM:SetPoint("LEFT", autoSendLabel, "RIGHT", 5, 0)
    whisperMsgInputLFM:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    whisperMsgInputLFM:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    whisperMsgInputLFM:SetBackdropColor(0, 0, 0, 0.8)
    whisperMsgInputLFM:SetFontObject(GameFontNormalSmall)
    whisperMsgInputLFM:SetTextInsets(5, 5, 0, 0)
    whisperMsgInputLFM:SetAutoFocus(false)
    whisperMsgInputLFM:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    whisperMsgInputLFM:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    whisperMsgInputLFM:SetScript("OnTextChanged", function()
        LogFilterGroup.whisperMessageLFM = this:GetText()
        LogFilterGroup:SaveSettings()
    end)
    frame.whisperMsgInputLFM = whisperMsgInputLFM

    -- Profession Whisper message input box
    local whisperMsgInputProf = CreateFrame("EditBox", "LogFilterGroupWhisperMsgInputProf", frame)
    whisperMsgInputProf:SetHeight(20)
    whisperMsgInputProf:SetPoint("LEFT", autoSendLabel, "RIGHT", 5, 0)
    whisperMsgInputProf:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    whisperMsgInputProf:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    whisperMsgInputProf:SetBackdropColor(0, 0, 0, 0.8)
    whisperMsgInputProf:SetFontObject(GameFontNormalSmall)
    whisperMsgInputProf:SetTextInsets(5, 5, 0, 0)
    whisperMsgInputProf:SetAutoFocus(false)
    whisperMsgInputProf:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    whisperMsgInputProf:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    whisperMsgInputProf:SetScript("OnTextChanged", function()
        LogFilterGroup.whisperMessageProfession = this:GetText()
        LogFilterGroup:SaveSettings()
    end)
    frame.whisperMsgInputProf = whisperMsgInputProf

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
        row.message:SetPoint("RIGHT", row, "RIGHT", -215, 0)  -- Adjusted for three buttons
        row.message:SetJustifyH("LEFT")

        -- Time ago
        row.time = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.time:SetPoint("TOPRIGHT", row, "TOPRIGHT", -152, -5)  -- Adjusted for three buttons
        row.time:SetJustifyH("RIGHT")

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

    -- Handle resize to update display
    frame:SetScript("OnSizeChanged", function()
        if frame:IsVisible() then
            LogFilterGroup:UpdateDisplay()
        end
    end)

    -- Set default tab
    frame.currentTab = "lfm"

    -- Load saved settings into UI
    frame.autoSendCheckbox:SetChecked(LogFilterGroup.autoSendWhisper)
    frame.whisperMsgInputLFM:SetText(LogFilterGroup.whisperMessageLFM)
    frame.whisperMsgInputProf:SetText(LogFilterGroup.whisperMessageProfession)
    frame.filterInputLFM:SetText(LogFilterGroup.filterTextLFM)
    frame.filterInputProfession:SetText(LogFilterGroup.filterTextProfession)

    LogFilterGroup:ShowTab("lfm")

    -- Update timer
    frame:SetScript("OnUpdate", function()
        if not this:IsVisible() then return end
        
        local now = GetTime()
        if now - LogFilterGroup.lastUpdate > 1 then
            LogFilterGroup.lastUpdate = now
            LogFilterGroup:UpdateDisplay()
        end
    end)
end

-- Helper function to count visible (non-popped-out) tabs
function LogFilterGroup:CountVisibleTabs()
    local count = 0
    if not self.poppedOutTabs.lfm then count = count + 1 end
    if not self.poppedOutTabs.lfg then count = count + 1 end
    if not self.poppedOutTabs.profession then count = count + 1 end
    return count
end

-- Helper function to update tab visibility based on pop-out state
function LogFilterGroup:UpdateTabVisibility()
    local frame = LogFilterGroupFrame
    if not frame then return end

    -- Show/hide tabs based on pop-out state
    if self.poppedOutTabs.lfm then
        frame.lfmTab:Hide()
    else
        frame.lfmTab:Show()
    end

    if self.poppedOutTabs.lfg then
        frame.lfgTab:Hide()
    else
        frame.lfgTab:Show()
    end

    if self.poppedOutTabs.profession then
        frame.professionTab:Hide()
    else
        frame.professionTab:Show()
    end

    -- Reposition visible tabs
    local lastTab = nil
    if not self.poppedOutTabs.lfm then
        frame.lfmTab:ClearAllPoints()
        frame.lfmTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -28)
        lastTab = frame.lfmTab
    end

    if not self.poppedOutTabs.lfg then
        frame.lfgTab:ClearAllPoints()
        if lastTab then
            frame.lfgTab:SetPoint("LEFT", lastTab, "RIGHT", 2, 0)
        else
            frame.lfgTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -28)
        end
        lastTab = frame.lfgTab
    end

    if not self.poppedOutTabs.profession then
        frame.professionTab:ClearAllPoints()
        if lastTab then
            frame.professionTab:SetPoint("LEFT", lastTab, "RIGHT", 2, 0)
        else
            frame.professionTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -28)
        end
        lastTab = frame.professionTab
    end
end

-- Show a specific tab
function LogFilterGroup:ShowTab(tab)
    local frame = LogFilterGroupFrame
    if not frame then return end

    -- If this tab is popped out, switch to first available non-popped-out tab
    if self.poppedOutTabs[tab] then
        if not self.poppedOutTabs.lfm then
            tab = "lfm"
        elseif not self.poppedOutTabs.lfg then
            tab = "lfg"
        elseif not self.poppedOutTabs.profession then
            tab = "profession"
        else
            -- All tabs are popped out, shouldn't happen but just in case
            return
        end
    end

    frame.currentTab = tab

    -- Update tab appearances
    if tab == "lfm" then
        frame.lfmTab:SetBackdropColor(0.15, 0.15, 0.15, 1)
        frame.lfgTab:SetBackdropColor(0.08, 0.08, 0.08, 1)
        frame.professionTab:SetBackdropColor(0.08, 0.08, 0.08, 1)
        frame.lfmTabText:SetTextColor(1, 1, 1, 1)
        frame.lfgTabText:SetTextColor(0.6, 0.6, 0.6, 1)
        frame.professionTabText:SetTextColor(0.6, 0.6, 0.6, 1)
        -- Move separate button next to LFM tab
        frame.separateButton:ClearAllPoints()
        frame.separateButton:SetPoint("LEFT", frame.lfmTab, "RIGHT", 2, 0)
        -- Show LFM filter and auto-send controls
        frame.filterInputLFM:Show()
        frame.filterInputProfession:Hide()
        frame.autoSendCheckbox:Show()
        frame.autoSendLabel:Show()
        frame.whisperMsgInputLFM:Show()
        frame.whisperMsgInputProf:Hide()
    elseif tab == "lfg" then
        frame.lfmTab:SetBackdropColor(0.08, 0.08, 0.08, 1)
        frame.lfgTab:SetBackdropColor(0.15, 0.15, 0.15, 1)
        frame.professionTab:SetBackdropColor(0.08, 0.08, 0.08, 1)
        frame.lfmTabText:SetTextColor(0.6, 0.6, 0.6, 1)
        frame.lfgTabText:SetTextColor(1, 1, 1, 1)
        frame.professionTabText:SetTextColor(0.6, 0.6, 0.6, 1)
        -- Move separate button next to LFG tab
        frame.separateButton:ClearAllPoints()
        frame.separateButton:SetPoint("LEFT", frame.lfgTab, "RIGHT", 2, 0)
        -- Show LFG filter, hide auto-send controls
        frame.filterInputLFM:Show()
        frame.filterInputProfession:Hide()
        frame.autoSendCheckbox:Hide()
        frame.autoSendLabel:Hide()
        frame.whisperMsgInputLFM:Hide()
        frame.whisperMsgInputProf:Hide()
    else
        frame.lfmTab:SetBackdropColor(0.08, 0.08, 0.08, 1)
        frame.lfgTab:SetBackdropColor(0.08, 0.08, 0.08, 1)
        frame.professionTab:SetBackdropColor(0.15, 0.15, 0.15, 1)
        frame.lfmTabText:SetTextColor(0.6, 0.6, 0.6, 1)
        frame.lfgTabText:SetTextColor(0.6, 0.6, 0.6, 1)
        frame.professionTabText:SetTextColor(1, 1, 1, 1)
        -- Move separate button next to Profession tab
        frame.separateButton:ClearAllPoints()
        frame.separateButton:SetPoint("LEFT", frame.professionTab, "RIGHT", 2, 0)
        -- Show Profession filter and auto-send controls
        frame.filterInputLFM:Hide()
        frame.filterInputProfession:Show()
        frame.autoSendCheckbox:Show()
        frame.autoSendLabel:Show()
        frame.whisperMsgInputLFM:Hide()
        frame.whisperMsgInputProf:Show()
    end

    self:UpdateDisplay()
end

-- Update the display
function LogFilterGroup:UpdateDisplay()
    local frame = LogFilterGroupFrame
    if not frame then
        return
    end

    if not frame:IsVisible() then
        return
    end

    -- Update tab visibility based on pop-out state
    self:UpdateTabVisibility()
    
    -- Get filter text based on current tab
    local filterText = ""
    if frame.currentTab == "profession" then
        if frame.filterInputProfession then
            filterText = frame.filterInputProfession:GetText()
        end
    else
        if frame.filterInputLFM then
            filterText = frame.filterInputLFM:GetText()
        end
    end

    local messages = {}
    local sourceData
    if frame.currentTab == "lfm" then
        sourceData = self.lfmMessages
    elseif frame.currentTab == "lfg" then
        sourceData = self.lfgMessages
    else
        sourceData = self.professionMessages
    end

    for sender, data in pairs(sourceData) do
        -- Apply filter
        if MatchesFilter(data.message, filterText) then
            table.insert(messages, {
                sender = sender,
                message = data.message,
                timestamp = data.timestamp
            })
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(messages, function(a, b)
        return a.timestamp > b.timestamp
    end)

    local numMessages = table.getn(messages)
    local offset = FauxScrollFrame_GetOffset(frame.scrollFrame)

    -- Calculate how many rows can fit in the current scroll frame height
    local scrollHeight = frame.scrollFrame:GetHeight()
    local visibleRows = math.floor(scrollHeight / ROW_HEIGHT)
    if visibleRows > ROWS_VISIBLE then
        visibleRows = ROWS_VISIBLE
    end

    FauxScrollFrame_Update(frame.scrollFrame, numMessages, visibleRows, ROW_HEIGHT)

    for i = 1, ROWS_VISIBLE do
        local row = frame.rows[i]
        local index = i + offset

        if i <= visibleRows and index <= numMessages then
            local data = messages[index]
            row.sender:SetText("|cff00ff00" .. data.sender .. "|r")

            -- Calculate available width for message text (window width - sender - time - buttons - margins)
            local messageWidth = frame:GetWidth() - 85 - 215
            local displayText, isTruncated = TruncateMessage(data.message, messageWidth)
            row.message:SetText(displayText)
            row.time:SetText(self:GetTimeAgo(data.timestamp))

            -- Store sender data and full message on row for tooltip
            row.senderName = data.sender
            row.fullMessage = data.message
            row.isTruncated = isTruncated

            -- Configure whisper button behavior
            row.whisperButton:SetScript("OnClick", function()
                if this:GetParent().senderName then
                    if LogFilterGroup.autoSendWhisper then
                        -- Determine which message to use based on current tab
                        local message = ""
                        if frame.currentTab == "lfm" then
                            message = LogFilterGroup.whisperMessageLFM
                        elseif frame.currentTab == "lfg" then
                            -- For LFG tab, just prepare whisper (no auto-send)
                            ChatFrameEditBox:SetText("/w " .. this:GetParent().senderName .. " ")
                            ChatFrameEditBox:Show()
                            return
                        else
                            message = LogFilterGroup.whisperMessageProfession
                        end

                        if message ~= "" then
                            -- Auto-send the prepared message
                            SendChatMessage(message, "WHISPER", nil, this:GetParent().senderName)
                        else
                            -- Just prepare the chat window if message is empty
                            ChatFrameEditBox:SetText("/w " .. this:GetParent().senderName .. " ")
                            ChatFrameEditBox:Show()
                        end
                    else
                        -- Just prepare the chat window
                        ChatFrameEditBox:SetText("/w " .. this:GetParent().senderName .. " ")
                        ChatFrameEditBox:Show()
                    end
                end
            end)

            -- Configure clear button behavior
            row.clearButton:SetScript("OnClick", function()
                local senderName = this:GetParent().senderName
                if senderName then
                    -- Determine which data table to clear from based on current tab
                    local dataTable
                    if frame.currentTab == "lfm" then
                        dataTable = LogFilterGroup.lfmMessages
                    elseif frame.currentTab == "lfg" then
                        dataTable = LogFilterGroup.lfgMessages
                    else
                        dataTable = LogFilterGroup.professionMessages
                    end

                    -- Remove the entry
                    if dataTable[senderName] then
                        dataTable[senderName] = nil
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

-- Create separate windows for all three tabs
function LogFilterGroup:CreateSeparateWindows()
    -- Create LFM window
    if not LogFilterGroupLFMWindow then
        self:CreateSeparateWindow("lfm")
    end

    -- Create LFG window
    if not LogFilterGroupLFGWindow then
        self:CreateSeparateWindow("lfg")
    end

    -- Create profession window
    if not LogFilterGroupProfessionWindow then
        self:CreateSeparateWindow("profession")
    end

    LogFilterGroupLFMWindow:Show()
    LogFilterGroupLFGWindow:Show()
    LogFilterGroupProfessionWindow:Show()

    if LogFilterGroupFrame then
        LogFilterGroupFrame:Hide()
    end
end

-- Create a separate window for a specific type
function LogFilterGroup:CreateSeparateWindow(windowType)
    local frameName, title
    if windowType == "lfm" then
        frameName = "LogFilterGroupLFMWindow"
        title = "Find Group (LFM)"
    elseif windowType == "lfg" then
        frameName = "LogFilterGroupLFGWindow"
        title = "Find Member (LFG)"
    else
        frameName = "LogFilterGroupProfessionWindow"
        title = "Professions"
    end
    
    local frame = CreateFrame("Frame", frameName, UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", windowType == "lfm" and -260 or (windowType == "lfg" and 0 or 260), 0)
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
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()

    -- Title
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", frame, "TOP", 0, -10)
    titleText:SetText(title)

    -- Store window type on frame for later reference
    frame.windowType = windowType

    -- Close button - dock the tab back into main window
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        -- Dock the tab back into main window
        LogFilterGroup.poppedOutTabs[windowType] = nil

        -- Hide this separate window
        frame:Hide()

        -- Update main window tab visibility
        if LogFilterGroupFrame then
            LogFilterGroup:UpdateTabVisibility()
            -- Switch to the tab we just docked back
            LogFilterGroup:ShowTab(windowType)
        end
    end)

    -- Minimize button
    local minimizeButton = CreateFrame("Button", nil, frame)
    minimizeButton:SetWidth(16)
    minimizeButton:SetHeight(16)
    minimizeButton:SetPoint("RIGHT", closeButton, "LEFT", -2, 0)
    minimizeButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    minimizeButton:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-Down")
    minimizeButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    minimizeButton:SetScript("OnClick", function()
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Minimize button clicked")
        local parentFrame = this:GetParent()
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: parentFrame = " .. tostring(parentFrame))
        if parentFrame then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: parentFrame.windowType = " .. tostring(parentFrame.windowType))
        end
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: LogFilterGroup = " .. tostring(LogFilterGroup))
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG: LogFilterGroup.MinimizeSeparateWindow = " .. tostring(LogFilterGroup.MinimizeSeparateWindow))
        if parentFrame and parentFrame.windowType then
            LogFilterGroup:MinimizeSeparateWindow(parentFrame.windowType)
        end
    end)
    frame.minimizeButton = minimizeButton

    -- Clear icon button (next to minimize button)
    local clearIconButton = CreateFrame("Button", nil, frame)
    clearIconButton:SetWidth(16)
    clearIconButton:SetHeight(16)
    clearIconButton:SetPoint("RIGHT", minimizeButton, "LEFT", -2, 0)
    clearIconButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearIconButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
    clearIconButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    clearIconButton:GetHighlightTexture():SetAlpha(0.5)

    clearIconButton:SetScript("OnClick", function()
        if windowType == "lfm" then
            LogFilterGroup.lfmMessages = {}
        elseif windowType == "lfg" then
            LogFilterGroup.lfgMessages = {}
        else
            LogFilterGroup.professionMessages = {}
        end
        LogFilterGroup:SaveData()
        LogFilterGroup:UpdateSeparateWindow(windowType)
    end)
    frame.clearIconButton = clearIconButton

    -- Filter label
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -35)
    filterLabel:SetText("Filter:")
    frame.filterLabel = filterLabel

    -- Filter input box
    local filterInput = CreateFrame("EditBox", frameName .. "FilterInput", frame)
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
    filterInput:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        LogFilterGroup:UpdateSeparateWindow(windowType)
    end)
    filterInput:SetScript("OnTextChanged", function()
        LogFilterGroup:UpdateSeparateWindow(windowType)
    end)
    frame.filterInput = filterInput

    -- Filter help text
    local filterHelp = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterHelp:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -2)
    filterHelp:SetText("|cffaaaaaa(You can use 1 and/or statement)|r")
    frame.filterHelp = filterHelp

    -- Auto-send whisper checkbox (only for LFM and Profession windows)
    if windowType ~= "lfg" then
        local autoSendCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        autoSendCheckbox:SetWidth(20)
        autoSendCheckbox:SetHeight(20)
        autoSendCheckbox:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -18)
        autoSendCheckbox:SetScript("OnClick", function()
            LogFilterGroup.autoSendWhisper = this:GetChecked()
            LogFilterGroup:SaveSettings()
        end)
        autoSendCheckbox:SetChecked(LogFilterGroup.autoSendWhisper)
        frame.autoSendCheckbox = autoSendCheckbox

        local autoSendLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        autoSendLabel:SetPoint("LEFT", autoSendCheckbox, "RIGHT", 5, 0)
        autoSendLabel:SetText("Use Template")
        frame.autoSendLabel = autoSendLabel

        -- Whisper message input box
        local whisperMsgInput = CreateFrame("EditBox", nil, frame)
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
            if windowType == "lfm" then
                LogFilterGroup.whisperMessageLFM = this:GetText()
            else
                LogFilterGroup.whisperMessageProfession = this:GetText()
            end
            LogFilterGroup:SaveSettings()
        end)

        if windowType == "lfm" then
            whisperMsgInput:SetText(LogFilterGroup.whisperMessageLFM)
        else
            whisperMsgInput:SetText(LogFilterGroup.whisperMessageProfession)
        end

        frame.whisperMsgInput = whisperMsgInput
    end
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", frameName .. "ScrollFrame", frame, "FauxScrollFrameTemplate")
    if windowType == "lfg" then
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -75)
    else
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -95)
    end
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 25)
    scrollFrame:SetScript("OnVerticalScroll", function()
        FauxScrollFrame_OnVerticalScroll(ROW_HEIGHT, function() LogFilterGroup:UpdateSeparateWindow(windowType) end)
    end)
    frame.scrollFrame = scrollFrame
    
    -- Create rows
    frame.rows = {}
    for i = 1, ROWS_VISIBLE do
        local row = CreateFrame("Frame", nil, frame)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -(i-1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", scrollFrame, "RIGHT", -25, 0)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        if math.mod(i, 2) == 0 then
            row.bg:SetTexture(0, 0, 0, 0.3)
        else
            row.bg:SetTexture(0, 0, 0, 0.1)
        end

        row.sender = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.sender:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -5)
        row.sender:SetJustifyH("LEFT")
        row.sender:SetWidth(80)

        row.message = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.message:SetPoint("TOPLEFT", row, "TOPLEFT", 85, -5)
        row.message:SetPoint("RIGHT", row, "RIGHT", -215, 0)  -- Adjusted for three buttons
        row.message:SetJustifyH("LEFT")

        row.time = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.time:SetPoint("TOPRIGHT", row, "TOPRIGHT", -152, -5)  -- Adjusted for three buttons
        row.time:SetJustifyH("RIGHT")

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

        -- Store window type on row for later use
        row.windowType = windowType

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
        LogFilterGroup:UpdateSeparateWindow(windowType)
    end)
    frame.resizeButton = resizeButton

    -- Handle resize to update display
    frame:SetScript("OnSizeChanged", function()
        if frame:IsVisible() then
            LogFilterGroup:UpdateSeparateWindow(windowType)
        end
    end)

    -- Update timer
    frame:SetScript("OnUpdate", function()
        if not this:IsVisible() then return end

        local now = GetTime()
        if now - (frame.lastUpdate or 0) > 1 then
            frame.lastUpdate = now
            LogFilterGroup:UpdateSeparateWindow(windowType)
        end
    end)
end

-- Update separate window display
function LogFilterGroup:UpdateSeparateWindow(windowType)
    local frameName
    if windowType == "lfm" then
        frameName = "LogFilterGroupLFMWindow"
    elseif windowType == "lfg" then
        frameName = "LogFilterGroupLFGWindow"
    else
        frameName = "LogFilterGroupProfessionWindow"
    end

    local frame = getglobal(frameName)
    if not frame or not frame:IsVisible() then return end

    -- Get filter text
    local filterText = ""
    if frame.filterInput then
        filterText = frame.filterInput:GetText()
    end

    local messages = {}
    local sourceData
    if windowType == "lfm" then
        sourceData = self.lfmMessages
    elseif windowType == "lfg" then
        sourceData = self.lfgMessages
    else
        sourceData = self.professionMessages
    end

    for sender, data in pairs(sourceData) do
        -- Apply filter
        if MatchesFilter(data.message, filterText) then
            table.insert(messages, {
                sender = sender,
                message = data.message,
                timestamp = data.timestamp
            })
        end
    end

    table.sort(messages, function(a, b)
        return a.timestamp > b.timestamp
    end)

    local numMessages = table.getn(messages)
    local offset = FauxScrollFrame_GetOffset(frame.scrollFrame)

    -- Calculate how many rows can fit in the current scroll frame height
    local scrollHeight = frame.scrollFrame:GetHeight()
    local visibleRows = math.floor(scrollHeight / ROW_HEIGHT)
    if visibleRows > ROWS_VISIBLE then
        visibleRows = ROWS_VISIBLE
    end

    FauxScrollFrame_Update(frame.scrollFrame, numMessages, visibleRows, ROW_HEIGHT)

    for i = 1, ROWS_VISIBLE do
        local row = frame.rows[i]
        local index = i + offset

        if i <= visibleRows and index <= numMessages then
            local data = messages[index]
            row.sender:SetText("|cff00ff00" .. data.sender .. "|r")

            -- Calculate available width for message text (window width - sender - time - buttons - margins)
            local messageWidth = frame:GetWidth() - 85 - 215
            local displayText, isTruncated = TruncateMessage(data.message, messageWidth)
            row.message:SetText(displayText)
            row.time:SetText(self:GetTimeAgo(data.timestamp))

            -- Store sender data and full message on row for tooltip
            row.senderName = data.sender
            row.fullMessage = data.message
            row.isTruncated = isTruncated

            -- Configure whisper button behavior
            row.whisperButton:SetScript("OnClick", function()
                if this:GetParent().senderName then
                    if LogFilterGroup.autoSendWhisper then
                        -- Determine which message to use based on window type
                        local message = ""
                        if windowType == "lfm" then
                            message = LogFilterGroup.whisperMessageLFM
                        elseif windowType == "lfg" then
                            -- For LFG window, just prepare whisper (no auto-send)
                            ChatFrameEditBox:SetText("/w " .. this:GetParent().senderName .. " ")
                            ChatFrameEditBox:Show()
                            return
                        else
                            message = LogFilterGroup.whisperMessageProfession
                        end

                        if message ~= "" then
                            -- Auto-send the prepared message
                            SendChatMessage(message, "WHISPER", nil, this:GetParent().senderName)
                        else
                            -- Just prepare the chat window if message is empty
                            ChatFrameEditBox:SetText("/w " .. this:GetParent().senderName .. " ")
                            ChatFrameEditBox:Show()
                        end
                    else
                        -- Just prepare the chat window
                        ChatFrameEditBox:SetText("/w " .. this:GetParent().senderName .. " ")
                        ChatFrameEditBox:Show()
                    end
                end
            end)

            -- Configure clear button behavior
            row.clearButton:SetScript("OnClick", function()
                local senderName = this:GetParent().senderName
                if senderName then
                    -- Determine which data table to clear from based on window type
                    local dataTable
                    if windowType == "lfm" then
                        dataTable = LogFilterGroup.lfmMessages
                    elseif windowType == "lfg" then
                        dataTable = LogFilterGroup.lfgMessages
                    else
                        dataTable = LogFilterGroup.professionMessages
                    end

                    -- Remove the entry
                    if dataTable[senderName] then
                        dataTable[senderName] = nil
                        LogFilterGroup:UpdateSeparateWindow(windowType)
                    end
                end
            end)

            row:Show()
        else
            row:Hide()
        end
    end

    if numMessages == 0 then
        frame.statusText:SetText("No messages yet. Keep monitoring chat...")
    else
        frame.statusText:SetText(numMessages .. " message(s) found")
    end
end
