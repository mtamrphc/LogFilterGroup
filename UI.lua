-- UI for LogFilterGroup

local FRAME_WIDTH = 500
local FRAME_HEIGHT = 400
local ROW_HEIGHT = 30
local ROWS_VISIBLE = 10

-- Helper function to escape pattern characters for literal search
local function EscapePattern(str)
    return string.gsub(str, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
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
    frame:SetMinResize(450, 350)
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

    -- Clear icon button (next to close button)
    local clearIconButton = CreateFrame("Button", nil, frame)
    clearIconButton:SetWidth(16)
    clearIconButton:SetHeight(16)
    clearIconButton:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
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
        if parentFrame.currentTab == "lfm" then
            if not LogFilterGroupLFMWindow then
                LogFilterGroup:CreateSeparateWindow("lfm")
            end
            LogFilterGroupLFMWindow:Show()
        elseif parentFrame.currentTab == "lfg" then
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
    end)
    frame.separateButton = separateButton
    
    -- Filter label
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -60)
    filterLabel:SetText("Filter:")

    -- LFM/LFG Filter input box
    local filterInputLFM = CreateFrame("EditBox", "LogFilterGroupFilterInputLFM", frame)
    filterInputLFM:SetWidth(280)
    filterInputLFM:SetHeight(20)
    filterInputLFM:SetPoint("LEFT", filterLabel, "RIGHT", 5, 0)
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
    filterInputProfession:SetWidth(280)
    filterInputProfession:SetHeight(20)
    filterInputProfession:SetPoint("LEFT", filterLabel, "RIGHT", 5, 0)
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
    filterHelp:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -5)
    filterHelp:SetText("|cffaaaaaa(Use AND/OR with (): \"(DPS AND BRD) OR (TANK AND SFK)\")|r")

    -- Auto-send whisper checkbox
    local autoSendCheckbox = CreateFrame("CheckButton", "LogFilterGroupAutoSendCheckbox", frame, "UICheckButtonTemplate")
    autoSendCheckbox:SetWidth(20)
    autoSendCheckbox:SetHeight(20)
    autoSendCheckbox:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -25)
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
    whisperMsgInputLFM:SetWidth(180)
    whisperMsgInputLFM:SetHeight(20)
    whisperMsgInputLFM:SetPoint("LEFT", autoSendLabel, "RIGHT", 10, 0)
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
    whisperMsgInputProf:SetWidth(180)
    whisperMsgInputProf:SetHeight(20)
    whisperMsgInputProf:SetPoint("LEFT", autoSendLabel, "RIGHT", 10, 0)
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
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -155)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 35)
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
        row.sender:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -5)
        row.sender:SetJustifyH("LEFT")
        row.sender:SetWidth(100)

        -- Message text
        row.message = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.message:SetPoint("TOPLEFT", row, "TOPLEFT", 110, -5)
        row.message:SetPoint("RIGHT", row, "RIGHT", -150, 0)
        row.message:SetJustifyH("LEFT")

        -- Time ago
        row.time = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.time:SetPoint("TOPRIGHT", row, "TOPRIGHT", -75, -5)
        row.time:SetJustifyH("RIGHT")

        -- Action button (Whisper or Invite depending on tab)
        row.actionButton = CreateFrame("Button", nil, row)
        row.actionButton:SetWidth(60)
        row.actionButton:SetHeight(22)
        row.actionButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -5, -5)
        row.actionButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        row.actionButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        row.actionButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        row.actionButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.actionButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.actionButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        row.actionButtonText = row.actionButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.actionButtonText:SetPoint("CENTER", row.actionButton, "CENTER", 0, 0)

        -- Make row hoverable
        row:EnableMouse(true)
        row:SetScript("OnEnter", function()
            this.bg:SetTexture(0.2, 0.2, 0.5, 0.5)
        end)
        row:SetScript("OnLeave", function()
            if math.mod(i, 2) == 0 then
                this.bg:SetTexture(0, 0, 0, 0.3)
            else
                this.bg:SetTexture(0, 0, 0, 0.1)
            end
        end)

        row:Hide()
        frame.rows[i] = row
    end

    -- Status text
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
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

-- Show a specific tab
function LogFilterGroup:ShowTab(tab)
    local frame = LogFilterGroupFrame
    if not frame then return end

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
            row.message:SetText(data.message)
            row.time:SetText(self:GetTimeAgo(data.timestamp))

            -- Store sender data on row
            row.senderName = data.sender

            -- Configure action button based on current tab
            if frame.currentTab == "lfg" then
                -- Find Member tab: Invite button
                row.actionButtonText:SetText("Invite")
                row.actionButton:SetScript("OnClick", function()
                    if this:GetParent().senderName then
                        InviteByName(this:GetParent().senderName)
                    end
                end)
            else
                -- Find Group and Professions tabs: Whisper button
                row.actionButtonText:SetText("Whisper")
                row.actionButton:SetScript("OnClick", function()
                    if this:GetParent().senderName then
                        if LogFilterGroup.autoSendWhisper then
                            -- Determine which message to use based on current tab
                            local message = ""
                            if frame.currentTab == "lfm" then
                                message = LogFilterGroup.whisperMessageLFM
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
            end

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

-- Toggle frame visibility
function LogFilterGroup:ToggleFrame()
    if not LogFilterGroupFrame then
        self:CreateFrame()
    end
    
    if LogFilterGroupFrame:IsVisible() then
        LogFilterGroupFrame:Hide()
    else
        LogFilterGroupFrame:Show()
        self:UpdateDisplay()
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
    frame:SetMinResize(450, 350)
    frame:SetMaxResize(1000, 800)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()

    frame.windowType = windowType
    
    -- Title
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", frame, "TOP", 0, -10)
    titleText:SetText(title)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

    -- Clear icon button (next to close button)
    local clearIconButton = CreateFrame("Button", nil, frame)
    clearIconButton:SetWidth(16)
    clearIconButton:SetHeight(16)
    clearIconButton:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
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
    filterLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    filterLabel:SetText("Filter:")

    -- Filter input box
    local filterInput = CreateFrame("EditBox", frameName .. "FilterInput", frame)
    filterInput:SetWidth(280)
    filterInput:SetHeight(20)
    filterInput:SetPoint("LEFT", filterLabel, "RIGHT", 5, 0)
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
    filterHelp:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -5)
    filterHelp:SetText("|cffaaaaaa(Use AND/OR with (): \"(DPS AND BRD) OR (TANK AND SFK)\")|r")

    -- Auto-send whisper checkbox (only for LFM and Profession windows)
    if windowType ~= "lfg" then
        local autoSendCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        autoSendCheckbox:SetWidth(20)
        autoSendCheckbox:SetHeight(20)
        autoSendCheckbox:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -25)
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
        whisperMsgInput:SetWidth(180)
        whisperMsgInput:SetHeight(20)
        whisperMsgInput:SetPoint("LEFT", autoSendLabel, "RIGHT", 10, 0)
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
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -80)
    else
        scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -105)
    end
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 35)
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
        row.sender:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -5)
        row.sender:SetJustifyH("LEFT")
        row.sender:SetWidth(100)

        row.message = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.message:SetPoint("TOPLEFT", row, "TOPLEFT", 110, -5)
        row.message:SetPoint("RIGHT", row, "RIGHT", -150, 0)
        row.message:SetJustifyH("LEFT")

        row.time = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.time:SetPoint("TOPRIGHT", row, "TOPRIGHT", -75, -5)
        row.time:SetJustifyH("RIGHT")

        -- Action button (Whisper or Invite depending on window type)
        row.actionButton = CreateFrame("Button", nil, row)
        row.actionButton:SetWidth(60)
        row.actionButton:SetHeight(22)
        row.actionButton:SetPoint("TOPRIGHT", row, "TOPRIGHT", -5, -5)
        row.actionButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        row.actionButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        row.actionButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        row.actionButton:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.actionButton:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
        row.actionButton:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)

        row.actionButtonText = row.actionButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.actionButtonText:SetPoint("CENTER", row.actionButton, "CENTER", 0, 0)

        -- Store window type on row for later use
        row.windowType = windowType

        -- Make row hoverable
        row:EnableMouse(true)
        row:SetScript("OnEnter", function()
            this.bg:SetTexture(0.2, 0.2, 0.5, 0.5)
        end)
        row:SetScript("OnLeave", function()
            if math.mod(i, 2) == 0 then
                this.bg:SetTexture(0, 0, 0, 0.3)
            else
                this.bg:SetTexture(0, 0, 0, 0.1)
            end
        end)

        row:Hide()
        frame.rows[i] = row
    end
    
    -- Status text
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
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
            row.message:SetText(data.message)
            row.time:SetText(self:GetTimeAgo(data.timestamp))

            -- Store sender data on row
            row.senderName = data.sender

            -- Configure action button based on window type
            if windowType == "lfg" then
                -- Find Member window: Invite button
                row.actionButtonText:SetText("Invite")
                row.actionButton:SetScript("OnClick", function()
                    if this:GetParent().senderName then
                        InviteByName(this:GetParent().senderName)
                    end
                end)
            else
                -- Find Group and Professions windows: Whisper button
                row.actionButtonText:SetText("Whisper")
                row.actionButton:SetScript("OnClick", function()
                    if this:GetParent().senderName then
                        if LogFilterGroup.autoSendWhisper then
                            -- Determine which message to use based on window type
                            local message = ""
                            if windowType == "lfm" then
                                message = LogFilterGroup.whisperMessageLFM
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
            end

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
