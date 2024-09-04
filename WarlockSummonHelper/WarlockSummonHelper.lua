local addonName, addon = ...
addon.tradePartners = {}
addon.inviteRequests = {}

-- Main frame
local frame = CreateFrame("Frame", "WarlockSummonFrame", UIParent, "BackdropTemplate")
frame:SetSize(400, 400) -- Adjusted size for better spacing
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    addon.SavePosition()
end)

frame:SetBackdrop({
    bgFile = "Interface\\FrameGeneral\\UI-Background-Rock",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true, tileSize = 128, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
frame:SetBackdropColor(0.2, 0, 0.2, 0.8)
frame:SetBackdropBorderColor(0.5, 0, 0.5, 1)

local headerTexture = frame:CreateTexture(nil, "ARTWORK")
headerTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
headerTexture:SetPoint("TOP", 0, 12)
headerTexture:SetSize(350, 64)  -- Increased width to accommodate text

local title = frame:CreateFontString(nil, "OVERLAY")
title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")  -- Slightly reduced font size
title:SetPoint("TOP", headerTexture, "TOP", 0, -14)
title:SetText("Warlock Summon Helper")
title:SetTextColor(0.6, 0.2, 0.6) -- Purple text color
title:SetShadowOffset(2, -2)
title:SetShadowColor(0.5, 0, 0, 1)

-- Scroll frame for party members and invite requests
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 70)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(320, 320)  -- Adjusted size to fit the new frame dimensions
scrollFrame:SetScrollChild(content)

-- Debug text
local debugText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
debugText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
debugText:SetText("Initializing...")
debugText:SetTextColor(0.6, 0.2, 0.6) -- Purple text color

-- Function to get player's current location
local function GetPlayerLocation()
    local zoneText = GetZoneText()
    local subZoneText = GetSubZoneText()
    if subZoneText and subZoneText ~= "" and subZoneText ~= zoneText then
        return string.upper(subZoneText .. ", " .. zoneText)
    else
        return string.upper(zoneText)
    end
end

-- Function to send whisper message
local function SendSummonWhisper(playerName)
    local location = GetPlayerLocation()
    local message = string.format("Summoning %s to %s. I am NOT a bot, please make sure to pay so I can continue this service! Thank you!", playerName, location)
    SendChatMessage(message, "WHISPER", nil, playerName)
end

-- Function to send thank you whisper
local function SendThankYouWhisper(playerName)
    local message = "Thank you for using my summoning service! Remember to whisper me again for another summon if needed."
    SendChatMessage(message, "WHISPER", nil, playerName)
end

-- Function to update party member list
local function UpdatePartyList()
    -- Clear existing buttons
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
    end

    local offset = 0
    local memberCount = 0

    for i = 1, 4 do
        local unit = "party"..i
        if UnitExists(unit) then
            local name = UnitName(unit)

            -- Create a button for the member's name
            local nameButton = CreateFrame("Button", nil, content, "SecureActionButtonTemplate,UIPanelButtonTemplate")
            nameButton:SetSize(160, 22)  -- Increased width for better visibility
            nameButton:SetPoint("TOPLEFT", 0, -offset)
            nameButton:SetText(name)
            nameButton:SetNormalFontObject("GameFontHighlightSmall")
            nameButton:SetHighlightFontObject("GameFontHighlightSmall")
            nameButton:SetAttribute("type", "macro")
            nameButton:SetAttribute("macrotext", "/target "..name.."\n/cast Ritual of Summoning")
            nameButton:SetScript("PreClick", function()
                debugText:SetText("Summoning: " .. name)
                SendSummonWhisper(name)
            end)
            nameButton:Show()

            -- Create a button for trading
            local tradeButton = CreateFrame("Button", nil, content, "SecureActionButtonTemplate,UIPanelButtonTemplate")
            tradeButton:SetSize(60, 22)
            tradeButton:SetPoint("TOPLEFT", 170, -offset)
            tradeButton:SetText("Trade")
            tradeButton:SetNormalFontObject("GameFontHighlightSmall")
            tradeButton:SetHighlightFontObject("GameFontHighlightSmall")
            tradeButton:SetAttribute("type", "macro")
            tradeButton:SetAttribute("macrotext", "/target "..name.."\n/trade")
            tradeButton:SetScript("PreClick", function()
                debugText:SetText("Trading with: " .. name)
            end)
            tradeButton:Show()

            -- Create a green check mark texture if trade was successful
            local checkMark = content:CreateTexture(nil, "OVERLAY")
            checkMark:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
            checkMark:SetSize(16, 16)
            checkMark:SetPoint("TOPLEFT", 240, -offset + 3)
            checkMark:Hide()

            if addon.tradePartners[name] then
                checkMark:Show()
            end

            -- Create a button for uninviting
            local uninviteButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            uninviteButton:SetSize(60, 22)
            uninviteButton:SetPoint("TOPLEFT", 260, -offset)
            uninviteButton:SetText("Uninvite")
            uninviteButton:SetNormalFontObject("GameFontHighlightSmall")
            uninviteButton:SetHighlightFontObject("GameFontHighlightSmall")
            uninviteButton:SetScript("OnClick", function()
                UninviteUnit(name)
                debugText:SetText("Uninvited: " .. name)
                addon.tradePartners[name] = nil -- Clear trade status on uninvite
                UpdatePartyList()
            end)
            uninviteButton:Show()

            offset = offset + 30  -- Increased offset for better spacing
            memberCount = memberCount + 1
        end
    end

    -- Add invite request buttons
    for name, _ in pairs(addon.inviteRequests) do
        local inviteButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        inviteButton:SetSize(200, 22)
        inviteButton:SetPoint("TOPLEFT", 0, -offset)
        inviteButton:SetText("Invite " .. name)
        inviteButton:SetNormalFontObject("GameFontHighlightSmall")
        inviteButton:SetHighlightFontObject("GameFontHighlightSmall")
        inviteButton:SetScript("OnClick", function()
            InviteUnit(name)
            addon.inviteRequests[name] = nil
            UpdatePartyList()
        end)
        inviteButton:Show()

        local declineButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        declineButton:SetSize(60, 22)
        declineButton:SetPoint("TOPLEFT", 210, -offset)
        declineButton:SetText("Decline")
        declineButton:SetNormalFontObject("GameFontHighlightSmall")
        declineButton:SetHighlightFontObject("GameFontHighlightSmall")
        declineButton:SetScript("OnClick", function()
            addon.inviteRequests[name] = nil
            UpdatePartyList()
        end)
        declineButton:Show()

        offset = offset + 30
    end

    content:SetHeight(offset)
    debugText:SetText(memberCount .. " members found")
end

-- Track the trade events
local function OnTradeShow()
    addon.tradePartner = UnitName("NPC")
    addon.thankYouWhisperSent = false
end

local function OnTradeAcceptUpdate(playerAccepted, targetAccepted)
    if playerAccepted and targetAccepted and not addon.thankYouWhisperSent then
        local copperReceived = GetTargetTradeMoney()
        if copperReceived >= 50000 then -- 5g in copper
            SendThankYouWhisper(addon.tradePartner)
            addon.tradePartners[addon.tradePartner] = true
            addon.thankYouWhisperSent = true
            UpdatePartyList()
        end
    end
end

-- Clear the trade partners on player leaving group
local function OnGroupRosterUpdate()
    for i = 1, 4 do
        local unit = "party"..i
        if not UnitExists(unit) then
            local name = UnitName(unit)
            if name and addon.tradePartners[name] then
                addon.tradePartners[name] = nil
            end
        end
    end
    UpdatePartyList()
end

-- Handle whisper messages
local function OnChatMsgWhisper(msg, author)
    if msg:lower() == "inv" then
        addon.inviteRequests[author] = true
        UpdatePartyList()
    end
end

-- Register events
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("TRADE_SHOW")
frame:RegisterEvent("TRADE_ACCEPT_UPDATE")
frame:RegisterEvent("CHAT_MSG_WHISPER")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "TRADE_SHOW" then
        OnTradeShow()
    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...
        OnTradeAcceptUpdate(playerAccepted, targetAccepted)
    elseif event == "GROUP_ROSTER_UPDATE" then
        OnGroupRosterUpdate()
    elseif event == "CHAT_MSG_WHISPER" then
        local msg, author = ...
        OnChatMsgWhisper(msg, author)
    else
        UpdatePartyList()
    end
end)

-- Slash command to show/hide the frame
SLASH_WARLOCKSUMMON1 = "/wsummon"
SlashCmdList["WARLOCKSUMMON"] = function(msg)
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        UpdatePartyList()
    end
end

-- Initialize
UpdatePartyList()
