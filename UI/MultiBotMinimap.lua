if not MultiBot then return end

-- ============================================================
--  MultiBotMinimap.lua  |  Minimap button via LibDBIcon-1.0
-- ============================================================

do
  local dbicon = LibStub("LibDBIcon-1.0", true)

  local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("MultiBot", {
    type = "launcher",
    text = "MultiBot",
    icon = "Interface\\AddOns\\MultiBot\\Icons\\browse.blp",

    OnClick = function(self, mouseButton)
      if mouseButton == "RightButton" then
        if MultiBot.ToggleOptionsPanel then
          MultiBot.ToggleOptionsPanel()
        elseif InterfaceOptionsFrame_OpenToCategory and MultiBot.BuildOptionsPanel then
          MultiBot.BuildOptionsPanel()
          InterfaceOptionsFrame_OpenToCategory("MultiBot")
          InterfaceOptionsFrame_OpenToCategory("MultiBot")
        end
        return
      end

      if SlashCmdList and SlashCmdList["MULTIBOT"] then
        SlashCmdList["MULTIBOT"]()
      elseif MultiBot.ToggleMainUIVisibility then
        MultiBot.ToggleMainUIVisibility()
      end
    end,

    OnTooltipShow = function(tooltip)
      if not tooltip or not tooltip.AddLine then return end
      tooltip:AddLine(MultiBot.L and MultiBot.L("info.butttitle") or "MultiBot", 1, 1, 1)
      tooltip:AddLine(MultiBot.L and MultiBot.L("info.buttontoggle") or "Left-click: Toggle MultiBot", 0.9, 0.9, 0.9)
      tooltip:AddLine(MultiBot.L and MultiBot.L("info.buttonoptions") or "Right-click: Options", 0.9, 0.9, 0.9)
    end,
  })

  local _minimapFrame = CreateFrame("Frame")
  _minimapFrame:RegisterEvent("PLAYER_LOGIN")
  _minimapFrame:SetScript("OnEvent", function()
    -- luacheck: globals MultiBotMinimapIconDB
    -- Initialise the saved variable for the icon position/visibility.
    MultiBotMinimapIconDB = MultiBotMinimapIconDB or {}
    if MultiBotMinimapIconDB.hide == nil then
      MultiBotMinimapIconDB.hide = false
    end

    -- Honour any existing hide setting coming from the old minimap config.
    local minimapConfig = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or nil
    if minimapConfig and minimapConfig.hide ~= nil then
      MultiBotMinimapIconDB.hide = minimapConfig.hide
    end

    if dbicon then
      dbicon:Register("MultiBot", miniButton, MultiBotMinimapIconDB)
    end
  end)

  -- Public helpers so the rest of the addon can show/hide/refresh the icon
  -- the same way it did before, without breaking existing call-sites.

  function MultiBot.Minimap_Create()
    -- With LibDBIcon the icon is registered on PLAYER_LOGIN; nothing to do here.
    -- Kept for backwards-compatibility with any code that calls this function.
    MultiBot.Minimap_Refresh()
  end

  function MultiBot.Minimap_Refresh()
    if not dbicon then return end

    local minimapConfig = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or nil
    local shouldHide = minimapConfig and minimapConfig.hide

    if shouldHide then
      dbicon:Hide("MultiBot")
    else
      dbicon:Show("MultiBot")
    end
  end
end
