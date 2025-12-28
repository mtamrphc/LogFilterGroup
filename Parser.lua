-- Message Parser for LogFilterGroup
-- All messages are now added to all tabs, and filters determine visibility

-- Parse a message and add it to all tabs (filters will determine visibility)
function LogFilterGroup:ParseMessage(sender, message)
    -- Skip messages from ourselves
    if sender == UnitName("player") then
        return
    end

    -- Debug output for all messages being parsed
    if LogFilterGroup.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("DEBUG ParseMessage: '" .. message .. "'")
    end

    -- Add ALL messages to ALL tabs (filters will determine visibility)
    for _, tab in ipairs(self.tabs) do
        self:AddMessage(tab.id, sender, message)
        if self.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("DEBUG: Added message to tab '" .. tab.name .. "'")
        end
    end
end

