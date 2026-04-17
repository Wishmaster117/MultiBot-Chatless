if not MultiBot then return end

-- Minimap config is resolved through MultiBot.GetMinimapConfig().

do
  local BTN_NAME = "MultiBot_MinimapButton"
  local RADIUS = 80 -- rayon d’ancrage au bord de la minimap

  local function deg2rad(degrees)
    return degrees * math.pi / 180
  end

  local function updatePosition(button, angle)
    local minimapConfig = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or nil
    local resolvedAngle = angle or (minimapConfig and minimapConfig.angle) or 220

    if not Minimap or not Minimap:GetCenter() then
      return
    end

    local minimapX, minimapY = Minimap:GetCenter()
    local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
    if not minimapX or not minimapY or not screenWidth or not screenHeight then
      return
    end

    local radius = RADIUS * (Minimap:GetEffectiveScale() / UIParent:GetEffectiveScale())
    local xOffset = math.cos(deg2rad(resolvedAngle)) * radius
    local yOffset = math.sin(deg2rad(resolvedAngle)) * radius

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", xOffset, yOffset)
  end

  local function saveAngleFromCursor(button)
    local minimapX, minimapY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()

    cursorX, cursorY = cursorX / scale, cursorY / scale

    local deltaX, deltaY = cursorX - minimapX, cursorY - minimapY
    local angle = math.deg(math.atan2(deltaY, deltaX))
    if angle < 0 then
      angle = angle + 360
    end

    if MultiBot.SetMinimapConfig then
      MultiBot.SetMinimapConfig("angle", angle)
    end

    updatePosition(button, angle)
  end

  function MultiBot.Minimap_Create()
    if _G[BTN_NAME] then
      MultiBot.Minimap_Refresh()
      return _G[BTN_NAME]
    end

    local minimapConfig = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or nil
    if minimapConfig and minimapConfig.hide then
      return nil
    end

    local button = CreateFrame("Button", BTN_NAME, Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("AnyUp")

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetSize(56, 56)
    overlay:SetPoint("TOPLEFT")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\browse.blp")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    button.icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(button)

    button:SetScript("OnDragStart", function(self)
      -- M11 ownership: keep this OnUpdate local.
      -- Reason: angle update must follow cursor every frame while dragging.
      self:SetScript("OnUpdate", saveAngleFromCursor)
    end)

    button:SetScript("OnDragStop", function(self)
      self:SetScript("OnUpdate", nil)
      saveAngleFromCursor(self)
    end)

    button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      GameTooltip:ClearLines()
      GameTooltip:AddLine(MultiBot.L("info.butttitle"), 1, 1, 1)
      GameTooltip:AddLine(MultiBot.L("info.buttontoggle"), 0.9, 0.9, 0.9)
      GameTooltip:AddLine(MultiBot.L("info.buttonoptions"), 0.9, 0.9, 0.9)
      GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(_, mouseButton)
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
    end)

    updatePosition(button)
    button:Show()

    MultiBot.MinimapButton = button
    return button
  end

  function MultiBot.Minimap_Refresh()
    local minimapConfig = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or nil
    local button = _G[BTN_NAME] or MultiBot.MinimapButton

    if minimapConfig and minimapConfig.hide then
      if button then
        button:Hide()
      end
      return
    end

    if not button then
      button = MultiBot.Minimap_Create()
    end

    if button then
      updatePosition(button)
      button:Show()
    end
  end
end