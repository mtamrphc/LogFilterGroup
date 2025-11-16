-- Message Parser for LogFilterGroup

-- LFM patterns (looking for more - groups seeking members)
local lfmPatterns = {
    "lfm",
    "lf%d+m",  -- matches lf1m, lf2m, lf3m, etc.
    "looking for more",
    "need more",
    "recruiting"
}

-- Group role keywords (used with "LF " to identify LFM messages)
local groupRoleKeywords = {
    "tank", "tanks",
    "heal", "healer", "healers", "heals",
    "dps", "dd", "damage", "dps'er", "dpser",
    "rogue", "warrior", "mage", "priest", "warlock", "hunter", "druid", "paladin", "shaman",
    "all", "more", "members", "people", "players"
}

-- LFG patterns (looking for group - players seeking to join)
local lfgPatterns = {
    "lfg",
    "lf%d*g",  -- matches lfg, lf1g, lf2g, etc.
    "looking for group",
    "looking for raid",
    "seeking group"
}

-- Profession keywords (case-insensitive patterns)
local professionKeywords = {
    -- Looking for professions/work
    "lfw", "lf work", "looking for work", "lfwork",
    "lf bs", "lf blacksmith", "need blacksmith",
    "lf tailor", "need tailor",
    "lf alchemist", "lf alch", "need alchemist", "need alch",
    "lf enchanter", "lf ench", "need enchanter", "need ench",
    "lf engineer", "lf eng", "need engineer", "need eng",
    "lf leatherworker", "lf lw", "need leatherworker", "need lw",
    "lf jc", "lf jewelcrafter", "need jewelcrafter", "need jc",
    "lf inscription", "lf scribe", "need scribe",
    "lf herbalist", "lf herb", "need herbalist",
    "lf miner", "lf mining", "need miner",
    "lf skinner", "lf skinning", "need skinner",

    -- Offering professions
    "blacksmith", "bs lf", "bs lfwork",
    "tailor", "tailoring",
    "alchemist", "alchemy", "alch lf", "transmute",
    "enchanter", "enchanting", "ench lf",
    "engineer", "engineering", "eng lf",
    "leatherworker", "leatherworking", "lw lf",
    "jewelcrafter", "jewelcrafting", "jc lf",
    "inscription", "scribe",

    -- Common profession patterns
    "wts", "wtb", "wtt",
    "pst", "whisper me",
    "tips appreciated", "free", "your mats",
    "craft", "crafting", "make",
    "enchant", "enchanting",
    "pattern", "recipe", "formula"
}

-- Parse a message and categorize it
function LogFilterGroup:ParseMessage(sender, message)
    local lowerMessage = string.lower(message)

    -- Skip messages from ourselves
    if sender == UnitName("player") then
        return
    end

    local isLFM = false
    local isLFG = false
    local isProfession = false

    -- Check for LFM patterns first (groups looking for members)
    for _, pattern in ipairs(lfmPatterns) do
        if string.find(lowerMessage, pattern) then
            isLFM = true
            if self.debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup: LFM pattern '" .. pattern .. "' found in: " .. message)
            end
            break
        end
    end

    -- Check for "LF " pattern combined with group role keywords
    if not isLFM then
        if string.find(lowerMessage, "^lf ") or string.find(lowerMessage, " lf ") then
            -- Check if message also contains any group role keyword
            for _, roleKeyword in ipairs(groupRoleKeywords) do
                if string.find(lowerMessage, roleKeyword) then
                    isLFM = true
                    if self.debugMode then
                        DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup: LF + role keyword '" .. roleKeyword .. "' found in: " .. message)
                    end
                    break
                end
            end
        end
    end

    -- Check for LFG patterns (players looking for groups)
    if not isLFM then
        for _, pattern in ipairs(lfgPatterns) do
            if string.find(lowerMessage, pattern) then
                isLFG = true
                if self.debugMode then
                    DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup: LFG pattern '" .. pattern .. "' found in: " .. message)
                end
                break
            end
        end
    end

    -- Check for profession keywords only if not LFM/LFG
    if not isLFM and not isLFG then
        for _, keyword in ipairs(professionKeywords) do
            if string.find(lowerMessage, keyword) then
                isProfession = true
                if self.debugMode then
                    DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup: Profession keyword '" .. keyword .. "' found in: " .. message)
                end
                break
            end
        end
    end

    -- Add to appropriate category (LFM takes priority, then LFG, then profession)
    if isLFM then
        self:AddLFMMessage(sender, message)
        if self.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup: Added LFM message from " .. sender)
        end
    elseif isLFG then
        self:AddLFGMessage(sender, message)
        if self.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup: Added LFG message from " .. sender)
        end
    elseif isProfession then
        self:AddProfessionMessage(sender, message)
        if self.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("LogFilterGroup: Added profession message from " .. sender)
        end
    end
end

