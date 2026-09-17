-- AUTOGEAR_OPTIONS_V1. WoW 3.3.5a / Lua 5.1. Ordinary bots only.
MultiBot.Autogear = {}
local A = MultiBot.Autogear
local words = {
  title=MultiBot.L("autogear.title", "Autogear"),
  button_tip=MultiBot.L("autogear.button_tip", "Choose Autogear options and item level for this bot."),
  defaults=MultiBot.L("autogear.defaults", "Server values"),
  quality=MultiBot.L("autogear.quality", "Quality"),
  match=MultiBot.L("autogear.match", "Match my item level"),
  ilvl=MultiBot.L("autogear.ilvl", "Custom item level"),
  limits=MultiBot.L("autogear.limits", "Server limits: %s / item level %s"),
  unlimited=MultiBot.L("autogear.unlimited", "unlimited"),
  reset=MultiBot.L("autogear.reset", "Reset equipped gear"),
  prepare=MultiBot.L("autogear.prepare", "Review and confirm"),
  loading=MultiBot.L("autogear.loading", "Reading server limits..."),
  preparing=MultiBot.L("autogear.preparing", "Checking bot and options..."),
  running=MultiBot.L("autogear.running", "Applying Autogear..."),
  note=MultiBot.L("autogear.note", "Item level is a generation target. Existing stronger gear may remain without reset."),
  reset_note=MultiBot.L("autogear.reset_note", "Reset permanently deletes equipped combat gear before generating replacements. Shirt and tabard are kept."),
  confirm=MultiBot.L("autogear.confirm", "%s\nQuality: %s\nItem level target: %s\n%s"),
  normal=MultiBot.L("autogear.normal", "Upgrade existing gear."),
  invalid=MultiBot.L("autogear.invalid", "Enter a whole item level from 6 to 99999."),
  unavailable=MultiBot.L("autogear.unavailable", "Autogear options unavailable. Reconnect after updating the bridge."),
  failed=MultiBot.L("autogear.failed", "Autogear refused: %s"),
  ready=MultiBot.L("autogear.ready", "Choose options, then review the server's plan."),
  timeout=MultiBot.L("autogear.timeout", "No server reply. Reopen this panel to request fresh limits."),
  unknown=MultiBot.L("autogear.unknown", "No final reply: gear may already have changed. Check the bot's equipment before requesting another Autogear."),
  completed=MultiBot.L("autogear.completed", "Autogear finished: %d slots changed, %d empty combat slots."),
  busy=MultiBot.L("autogear.busy", "An Autogear request is already pending."),
  expired=MultiBot.L("autogear.expired", "Plan expired. Review a new plan."),
  accept_reset=MultiBot.L("autogear.accept_reset", "Reset gear"),
  accept=MultiBot.L("autogear.accept", "Apply"),
  cancel=MultiBot.L("autogear.cancel", "Cancel"),
}
local reasons = {
  NO_BOT=MultiBot.L("autogear.reason.NO_BOT", "Bot unavailable."),
  FORBIDDEN=MultiBot.L("autogear.reason.FORBIDDEN", "You cannot control this bot."),
  NOT_IN_WORLD=MultiBot.L("autogear.reason.NOT_IN_WORLD", "Bot is not in the world."),
  DEAD=MultiBot.L("autogear.reason.DEAD", "Bot is dead."),
  IN_COMBAT=MultiBot.L("autogear.reason.IN_COMBAT", "Bot is in combat."),
  LEVEL_TOO_LOW=MultiBot.L("autogear.reason.LEVEL_TOO_LOW", "Bot must be at least level 5."),
  DISABLED=MultiBot.L("autogear.reason.DISABLED", "Disabled by server configuration."),
  ALT_BOT_REFUSED=MultiBot.L("autogear.reason.ALT_BOT_REFUSED", "Autogear is disabled for altbots."),
  BAD_CONFIG=MultiBot.L("autogear.reason.BAD_CONFIG", "Server configuration is invalid."),
  NO_REFERENCE_GEAR=MultiBot.L("autogear.reason.NO_REFERENCE_GEAR", "No equipped items to calculate your item level."),
  BAD_ARGUMENT=MultiBot.L("autogear.reason.BAD_ARGUMENT", "Invalid option."),
  PLAN_EXPIRED=MultiBot.L("autogear.reason.PLAN_EXPIRED", "Plan expired."),
  TARGET_CHANGED=MultiBot.L("autogear.reason.TARGET_CHANGED", "Bot or equipped gear changed. Review a new plan."),
  PLAN_CHANGED=MultiBot.L("autogear.reason.PLAN_CHANGED", "Limits or reference gear changed. Review a new plan."),
  COOLDOWN=MultiBot.L("autogear.reason.COOLDOWN", "Wait 10 seconds before trying again."),
  RATE_LIMIT=MultiBot.L("autogear.reason.RATE_LIMIT", "Too many requests. Wait a few seconds."),
  BUSY=MultiBot.L("autogear.reason.BUSY", "Server busy."),
  EXECUTION_FAILED=MultiBot.L("autogear.reason.EXECUTION_FAILED", "Execution failed; gear may have changed. Check it before trying again."),
  BAD_RESPONSE=MultiBot.L("autogear.reason.BAD_RESPONSE", "Invalid server response."),
  SEND_FAILED=MultiBot.L("autogear.reason.SEND_FAILED", "Request could not be sent."),
}
local qualities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Artifact", "Heirloom" }
local popup = "MULTIBOT_AUTOGEAR_OPTIONS_CONFIRM"
local alertPopup = "MULTIBOT_AUTOGEAR_OPTIONS_ALERT"
local modes = { "DEFAULT", "QUALITY", "MATCH", "ILVL" }
local modeKeys = { "defaults", "quality", "match", "ilvl" }
local function now() return GetTime() end
local function generation() return MultiBot.bridge and MultiBot.bridge.connectionGeneration end
local function available()
  return MultiBot.bridge and MultiBot.bridge.connected == true and MultiBot.bridge.autogearOptionsCapable == true
    and MultiBot.Comm and type(MultiBot.Comm.Send) == "function"
end
local function qualityText(value) return _G["ITEM_QUALITY" .. value .. "_DESC"] or qualities[value] or "?" end
local function ilvlText(value) return value == 0 and words.unlimited or tostring(value) end
local function notify(message)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99MultiBot|r " .. message) end
end
local function showInitialAlert(message)
  local text = A.name and A.name ~= "" and (A.name .. "\n\n" .. message) or message
  StaticPopup_Hide(alertPopup)
  local dialog = StaticPopup_Show(alertPopup, text)
  if not dialog then notify(message) end
end
local function status(message)
  A.message = message
  if A.frame then A.frame.status:SetText(message) end
end
local function setEnabled(widget, enabled)
  if enabled then widget:Enable() else widget:Disable() end
end
local function refresh()
  if not A.frame then return end
  local free = not A.pending and not A.ready and A.qualityCap and available()
  setEnabled(A.frame.prepare, free)
  setEnabled(A.frame.reset, free)
  for i, button in ipairs(A.frame.modes) do
    setEnabled(button, free)
    button:SetAlpha(A.mode == modes[i] and 1 or 0.55)
  end
  for value, button in ipairs(A.frame.qualities) do
    setEnabled(button, free and A.mode == "QUALITY" and value <= (A.qualityCap or 0))
    button:SetAlpha(A.quality == value and 1 or 0.55)
  end
  -- EditBox has no Enable/Disable on the 3.3.5 client.
  A.frame.ilvl:EnableMouse(free and A.mode == "ILVL" and true or false)
  if not free or A.mode ~= "ILVL" then A.frame.ilvl:ClearFocus() end
  A.frame.ilvl:SetAlpha(free and A.mode == "ILVL" and 1 or 0.45)
end
local function failure(reason, uncertain)
  local initialInfo = A.initialInfo == true or (A.pending and A.pending.kind == "AUTOGEAR_INFO")
  A.pending, A.ready, A.initialInfo = nil, nil, nil
  StaticPopup_Hide(popup)
  if initialInfo and A.frame and A.frame:IsShown() then A.frame:Hide() end
  status(uncertain and words.unknown or string.format(words.failed, reasons[reason] or words.unavailable))
  refresh()
  if initialInfo and not uncertain then
    showInitialAlert(A.message)
  elseif uncertain or not A.frame or not A.frame:IsShown() then
    notify(A.message)
  end
end
local function encode(value)
  return (value:gsub("([^%w%-_%.])", function(char) return string.format("%%%02X", string.byte(char)) end))
end
local function split(value)
  local fields = {}
  for part in (value .. "~"):gmatch("(.-)~") do fields[#fields + 1] = part end
  return fields
end
local function integer(value, minimum, maximum)
  if type(value) ~= "string" or not value:match("^%d+$") or #value > 5 then return nil end
  local result = tonumber(value)
  if not result or result < minimum or result > maximum then return nil end
  return result
end
local function token()
  A.sequence = (A.sequence or 0) + 1
  return string.format("ago_%d_%d_%d", time(), math.floor(now() * 1000) % 100000000, A.sequence)
end
local function send(kind, requestToken, fields, context)
  if not available() then failure("UNAVAILABLE"); return false end
  local payload = kind .. "~" .. requestToken
  if fields and fields ~= "" then payload = payload .. "~" .. fields end
  if #payload + 4 > 255 then failure("BAD_ARGUMENT"); return false end
  context = context or {}
  context.kind, context.token, context.generation = kind, requestToken, generation()
  context.deadline = now() + (kind == "AUTOGEAR_APPLY" and 30 or 10)
  A.pending = context
  refresh()
  local ok, sent = pcall(MultiBot.Comm.Send, "RUN", payload)
  if not ok or not sent then failure("SEND_FAILED", kind == "AUTOGEAR_APPLY" and not ok); return false end
  return true
end
function A.Text(key) return words[key] or key end
function A.Tick()
  if A.pending and A.pending.generation ~= generation() then A.OnDisconnect(); return end
  if A.pending and now() >= A.pending.deadline then
    local uncertain = A.pending.kind == "AUTOGEAR_APPLY"
    local initialInfo = A.initialInfo == true or A.pending.kind == "AUTOGEAR_INFO"
    A.pending, A.initialInfo = nil, nil
    A.qualityCap = nil
    status(uncertain and words.unknown or words.timeout)
    refresh()
    if initialInfo and not uncertain then
      showInitialAlert(A.message)
    elseif uncertain or not A.frame or not A.frame:IsShown() then
      notify(A.message)
    end
  end
  if A.ready and now() >= A.ready.deadline then
    A.ready = nil
    StaticPopup_Hide(popup)
    status(words.expired)
    refresh()
  end
end
function A.OnDisconnect()
  local wasApplying = A.pending and A.pending.kind == "AUTOGEAR_APPLY"
  A.qualityCap = nil
  if A.pending then
    failure("UNAVAILABLE", wasApplying)
  else
    A.ready, A.initialInfo = nil, nil
    StaticPopup_Hide(popup)
    if A.frame then status(words.unavailable); refresh() end
  end
end
function A.Cancel(plan)
  if A.ready == plan then A.ready = nil; status(words.ready); refresh() end
end
function A.Apply(plan)
  if not plan or plan ~= A.ready or A.pending then return end
  if plan.generation ~= generation() or now() >= plan.deadline or not available() then
    A.ready = nil; status(words.expired); refresh(); return
  end
  A.ready = nil
  status(words.running)
  send("AUTOGEAR_APPLY", plan.token, nil, plan)
end
function A.Prepare()
  if A.pending or A.ready or not A.qualityCap then return end
  local value = 0
  if A.mode == "QUALITY" then value = A.quality end
  if A.mode == "ILVL" then
    value = integer(A.frame.ilvl:GetText(), 6, 99999)
    if not value then status(words.invalid); return end
  end
  local reset = A.frame.reset:GetChecked() and true or false
  local context = { name=A.name, mode=A.mode, value=value, reset=reset }
  status(words.preparing)
  send("AUTOGEAR_PLAN", token(), encode(A.name) .. "~" .. A.mode .. "~" .. value .. "~" .. (reset and "1" or "0"), context)
end
function A.HandleMessage(opcode, payload)
  -- Called ONLY after Comm's bridge-sender and addon-prefix authentication.
  if opcode ~= "AUTOGEAR_INFO" and opcode ~= "AUTOGEAR_READY" and opcode ~= "AUTOGEAR_RESULT" and opcode ~= "ERR" then return false end
  local fields = split(payload or "")
  local pending = A.pending
  if opcode == "ERR" then
    if not pending or #fields ~= 4 or fields[1] ~= "RUN" or fields[2] ~= pending.kind or fields[3] ~= pending.token then return false end
    if pending.generation ~= generation() then A.OnDisconnect(); return true end
    failure(fields[4]); return true
  end
  if not pending or fields[1] ~= pending.token then return true end
  if pending.generation ~= generation() then A.OnDisconnect(); return true end
  local expected = pending.kind == "AUTOGEAR_PLAN" and "AUTOGEAR_READY" or (pending.kind == "AUTOGEAR_APPLY" and "AUTOGEAR_RESULT" or "AUTOGEAR_INFO")
  if opcode ~= expected then return true end
  local isApply = pending.kind == "AUTOGEAR_APPLY"
  local expectedCount = opcode == "AUTOGEAR_READY" and 6 or 5
  if #fields ~= expectedCount or (fields[2] ~= "OK" and fields[2] ~= "ERR") then failure("BAD_RESPONSE", isApply); return true end
  if fields[2] == "ERR" then failure(fields[3]); return true end
  local first = integer(fields[4], isApply and 0 or 1, isApply and 17 or 7)
  local second = integer(fields[5], 0, isApply and 17 or 99999)
  if not first or not second or fields[3] ~= (isApply and "COMPLETED" or "READY") then failure("BAD_RESPONSE", isApply); return true end
  if opcode == "AUTOGEAR_READY" and fields[6] ~= (pending.reset and "1" or "0") then failure("BAD_RESPONSE"); return true end
  A.pending = nil
  if opcode == "AUTOGEAR_INFO" then
    A.initialInfo = nil
    StaticPopup_Hide(alertPopup)
    A.qualityCap, A.ilvlCap = first, second
    A.quality = math.min(3, first)
    A.frame.limits:SetText(string.format(words.limits, qualityText(first), ilvlText(second)))
    status(words.ready)
    A.frame:Show()
  elseif opcode == "AUTOGEAR_READY" then
    pending.deadline = now() + 20
    A.ready = pending
    local text = string.format(words.confirm, pending.name, qualityText(first), ilvlText(second), pending.reset and words.reset_note or words.normal)
    StaticPopupDialogs[popup].button1 = pending.reset and words.accept_reset or words.accept
    local dialog = StaticPopup_Show(popup, text, nil, pending)
    if not dialog then A.ready = nil; status(words.expired) end
  else
    A.frame.reset:SetChecked(false)
    status(string.format(words.completed, first, second))
    if not A.frame:IsShown() then notify(A.message) end
  end
  refresh()
  return true
end
StaticPopupDialogs[popup] = {
  text="%s", button1=words.accept, button2=words.cancel, timeout=20,
  whileDead=0, hideOnEscape=1, preferredIndex=3,
  OnAccept=function(self, data) A.Apply(data) end,
  OnCancel=function(self, data) A.Cancel(data) end,
}
StaticPopupDialogs[alertPopup] = {
  text="%s", button1=_G.OKAY or "OK", timeout=0,
  whileDead=1, hideOnEscape=1, preferredIndex=3,
}
local function getAceGUI()
  if MultiBot.GetAceGUI then
    local ace = MultiBot.GetAceGUI()
    if type(ace) == "table" and type(ace.Create) == "function" then return ace end
  end
  if type(LibStub) == "table" then
    local ok, ace = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
    if ok and type(ace) == "table" and type(ace.Create) == "function" then return ace end
  end
  return nil
end
local function addSimpleBackdrop(frame, bgAlpha)
  if not frame or not frame.SetBackdrop then return end
  frame:SetBackdrop({
    bgFile="Interface\\Buttons\\WHITE8x8",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
    tile=true, tileSize=16, edgeSize=14,
    insets={left=3,right=3,top=3,bottom=3},
  })
  if frame.SetBackdropColor then frame:SetBackdropColor(0.06, 0.06, 0.08, bgAlpha or 0.90) end
  if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95) end
end
local function label(parent, text, x, y, width, height)
  local font = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  font:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  font:SetWidth(width)
  if height then font:SetHeight(height); font:SetJustifyV("TOP") end
  font:SetJustifyH("LEFT"); font:SetText(text)
  return font
end
local function button(parent, text, x, y, width, click)
  local result = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  result:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  result:SetWidth(width); result:SetHeight(24); result:SetText(text); result:SetScript("OnClick", click)
  return result
end
local function createPanel()
  local aceGUI = getAceGUI()
  if not aceGUI then return false end
  local window = aceGUI:Create("Window")
  if not window or not window.frame or not window.content then return false end
  A.window = window
  window:SetTitle(words.title)
  window:SetLayout("Manual")
  window:SetWidth(520); window:SetHeight(500)
  if window.EnableResize then window:EnableResize(false) end
  window.frame:SetClampedToScreen(true)
  window.frame:ClearAllPoints(); window.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
  window.frame:SetFrameStrata(strataLevel or "DIALOG")
  window:SetCallback("OnClose", function(widget) widget:Hide() end)
  local frame = window.frame
  A.frame = frame
  frame.content = window.content
  frame.content:ClearAllPoints()
  frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
  frame.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
  local root = CreateFrame("Frame", nil, frame.content)
  root:SetAllPoints(frame.content); addSimpleBackdrop(root, 0.90)
  local limitsPanel = CreateFrame("Frame", nil, root)
  limitsPanel:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -8)
  limitsPanel:SetPoint("TOPRIGHT", root, "TOPRIGHT", -8, -8)
  limitsPanel:SetHeight(42); addSimpleBackdrop(limitsPanel, 0.55)
  frame.limits = label(limitsPanel, "", 10, -13, 448)
  local modesPanel = CreateFrame("Frame", nil, root)
  modesPanel:SetPoint("TOPLEFT", limitsPanel, "BOTTOMLEFT", 0, -6)
  modesPanel:SetPoint("TOPRIGHT", limitsPanel, "BOTTOMRIGHT", 0, -6)
  modesPanel:SetHeight(92); addSimpleBackdrop(modesPanel, 0.55)
  frame.modes, frame.qualities = {}, {}
  for i, mode in ipairs(modes) do
    local selectedMode = mode
    frame.modes[i] = button(modesPanel, words[modeKeys[i]], 8 + ((i-1)%2)*234, -14 - math.floor((i-1)/2)*32, 226, function()
      if A.pending or A.ready then return end
      A.mode = selectedMode; refresh()
    end)
  end
  local qualityPanel = CreateFrame("Frame", nil, root)
  qualityPanel:SetPoint("TOPLEFT", modesPanel, "BOTTOMLEFT", 0, -6)
  qualityPanel:SetPoint("TOPRIGHT", modesPanel, "BOTTOMRIGHT", 0, -6)
  qualityPanel:SetHeight(92); addSimpleBackdrop(qualityPanel, 0.55)
  for quality = 1, 7 do
    local selectedQuality = quality
    frame.qualities[quality] = button(qualityPanel, qualityText(quality), 8 + ((quality-1)%4)*116, -14 - math.floor((quality-1)/4)*32, 112, function()
      if A.pending or A.ready then return end
      A.quality = selectedQuality; refresh()
    end)
  end
  local settingsPanel = CreateFrame("Frame", nil, root)
  settingsPanel:SetPoint("TOPLEFT", qualityPanel, "BOTTOMLEFT", 0, -6)
  settingsPanel:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -8, 8)
  addSimpleBackdrop(settingsPanel, 0.55)
  label(settingsPanel, words.ilvl .. " (6-99999)", 12, -17, 220)
  frame.ilvl = CreateFrame("EditBox", nil, settingsPanel, "InputBoxTemplate")
  frame.ilvl:SetWidth(100); frame.ilvl:SetHeight(24); frame.ilvl:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 248, -11)
  frame.ilvl:SetAutoFocus(false); frame.ilvl:SetMaxLetters(5)
  frame.ilvl:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  frame.ilvl:SetScript("OnEnterPressed", function(self) self:ClearFocus(); A.Prepare() end)
  frame.reset = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
  frame.reset:SetWidth(26); frame.reset:SetHeight(26); frame.reset:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 8, -44)
  label(settingsPanel, words.reset, 38, -51, 420)
  label(settingsPanel, words.note, 12, -82, 448, 42)
  frame.status = label(settingsPanel, "", 12, -128, 448, 34)
  frame.prepare = button(settingsPanel, words.prepare, 122, -166, 224, A.Prepare)
  frame.prepare:ClearAllPoints(); frame.prepare:SetPoint("BOTTOM", settingsPanel, "BOTTOM", 0, 12)
  _G["MultiBotAutogearOptionsFrame"] = frame
  table.insert(UISpecialFrames, "MultiBotAutogearOptionsFrame")
  frame:HookScript("OnHide", function(self)
    self.ilvl:ClearFocus()
    A.ready = nil; StaticPopup_Hide(popup)
    if A.pending and A.pending.kind ~= "AUTOGEAR_APPLY" then A.pending = nil; A.qualityCap = nil end
  end)
  window:Hide()
  -- Independent timer keeps timeouts working when the panel is closed.
  A.timer = CreateFrame("Frame", nil, UIParent)
  A.timer:SetScript("OnUpdate", function() A.Tick() end)
  return true
end
function A.Open(name)
  A.Tick()
  if A.pending then
    if A.pending.kind ~= "AUTOGEAR_INFO" and A.frame then A.frame:Show() end
    notify(words.busy); return false
  end
  if type(name) ~= "string" or name == "" or #name > 64 or name:find("[%c~]") then return false end
  if not A.frame and not createPanel() then return false end
  if A.frame:IsShown() then A.frame:Hide() end
  A.ready = nil; A.initialInfo = true
  StaticPopup_Hide(popup); StaticPopup_Hide(alertPopup)
  A.name, A.mode, A.quality, A.qualityCap, A.ilvlCap = name, "DEFAULT", 3, nil, nil
  A.frame.reset:SetChecked(false); A.frame.ilvl:SetText("200")
  if A.window and A.window.SetTitle then A.window:SetTitle(words.title .. " - " .. name) end
  A.frame.limits:SetText("")
  status(words.loading)
  return send("AUTOGEAR_INFO", token(), encode(name), {name=name})
end
