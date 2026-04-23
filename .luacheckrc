-- Configuration Luacheck
std = "lua53"

exclude_files = {
   "**/MultiBotInit.lua"
}

globals = {
    "MultiBot", "GetLocale", "GetSpellInfo", "GetSpellLink", "MultiBotSave", "SendChatMessage", "CreateFrame", "UIParent",
    "MultiBotGlobalSave", "DEFAULT_CHAT_FRAME", "C_Timer_After", "IsInRaid", "GetNumRaidMembers", "IsInGroup", "GetNumPartyMembers",
    "GetNumGroupMembers", "GetNumSubgroupMembers", "lvl", "C_Timer", "UnitClass", "InspectUnit", "InspectFrame", "HideUIPanel",
    "tinsert", "strtrim", "wipe", "UnitName", "GetRealmName", "GameTooltip", "GameTooltip_Hide", "MultiBotDB", "SlashCmdList",
    "GetScreenWidth", "tParts", "tSpace", "strsub", "strlen", "GetNumTalents", "UnitLevel", "IsSpellKnown", "GetInventoryItemLink",
    "iName", "iLink", "iRare", "iMinLevel", "iType", "iSubType", "iStack", "GetItemInfo", "floor", "tIcon", "tBody", "GetMacroInfo",
    "CreateMacro", "PickupMacro", "UnitSex", "UnitRace", "substr", "StaticPopupDialogs", "ACCEPT", "CANCEL", "StaticPopup_Show",
    "MultiBotPVPFrame", "GetItemIcon", "OKAY", "_MB_getIcon", "_MB_applyDesat", "_MB_applyDesatToTexture", "_MB_setDesat", "unpack",
	"CheckInteractDistance", "Minimap", "GetScreenHeight", "GetCursorPosition", "InterfaceOptionsFrame_OpenToCategory", "TimerAfter",
	"UnitExists", "UnitIsPlayer", "GuildRoster", "ShowFriends", "GetNumGuildMembers", "GetGuildRosterInfo", "GetNumFriends", "GetFriendInfo",
	"UnitFactionGroup", "IsUnitOnQuest", "GetNumQuestLogEntries", "GetQuestLink", "YES", "NO", "GetQuestLogTitle", "GetNumQuestLeaderBoards",
	"GetNumQuestLogEntries", "SelectQuestLogEntry", "SetAbandonQuest", "QuestLogPushQuest", "UIErrorsFrame", "SendAll", "CancelTrade", "InitiateTrade",
	"GetNumMacroIcons", "gApply", "GetActiveTalentGroup", "GetTalentInfo", "GetUnspentTalentPoints", "GetTalentLink", "GetCursorInfo", "strsplit",
	"GetSpellTexture", "ClearCursor", "MBHunterPetPreview", "tru", "InterfaceOptionsFrame", "INTERFACEOPTIONS_ADDONCATEGORIES", "InterfaceOptionsFrame_AddCategory",
	"InterfaceOptions_AddCategory", "UIDropDownMenu_JustifyText", "UIDropDownMenu_SetSelectedValue", "UIDropDownMenu_SetButtonWidth", "UIDropDownMenu_SetWidth",
	"UIDropDownMenu_Initialize", "UIDropDownMenu_AddButton", "UIDropDownMenu_CreateInfo", "UIDropDownMenu_SetSelectedID", "SetRaidSubgroup", "GetRaidRosterInfo",
	"MouseIsOver", "UninviteUnit", "UnitInRaid", "UnitInGroup", "GetNumQuestChoices", "GetQuestItemLink", "GetQuestItemInfo", "SwapRaidSubgroup", "WorldMapButton",
	"UnitIsConnected", "event", "arg1", "arg2", "MultiBotSaved", "GetUnitName", "GetTime", "GetNumMacros", "ReloadUI", "GetQuestLogLeaderBoard", "AbandonQuest",
	"GetMacroIconInfo", "GetPlayerInfoByGUID", "UnitGUID", "ConvertToRaid", "HandleQuestsAllResponse", "UnitXPMax", "UnitXP", "UnitManaMax", "UnitMana",
	"GetCurrentMapContinent", "GetCurrentMapAreaID", "SLASH_MULTIBOT1", "SLASH_MULTIBOT2", "SLASH_MULTIBOT3", "SLASH_MULTIBOTOPTIONS1", "SLASH_MBFAKEGM1",
	"SLASH_MBCLASS1", "SLASH_MBCLASSTEST1", "UIDropDownMenu_SetText", "UIDropDownMenu_SetWidth", "UIDropDownMenu_Initialize", "UIDropDownMenu_CreateInfo",
    "UIDropDownMenu_AddButton", "UIDropDownMenu_SetSelectedValue", "time", "isFav", "ToggleDropDownMenu"
	
}

read_globals = {
   math = {
      fields = {
         atan2 = {}
      }
   }
}

-- Interdire les tabulations
no_tab_indent = true

-- Indentation à 4 espaces
indent_size = 4

-- Options de propreté du code
unused_args = false
unused_vars = false
redefined_vars = false
unused_values = false

-- Interdire les globals implicites
allow_defined_top = false

-- Considérer 'self' comme utilisé automatiquement
self = true

-- Limite de longueur de ligne
max_line_length = 500