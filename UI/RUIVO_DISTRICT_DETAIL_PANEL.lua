-- ===========================================================================
-- 区域详情左弹窗 (RUIVO MAB)
-- 进入区域规划模式时从左侧滑入，显示非单元格系相邻加成
-- 上半部：区域图标 + 描述滚动区
-- 下半部：iconString（左）+ tooltip（右），各带滚动区
-- ===========================================================================
include("RUIVO_STAT_MODULE_GP.lua");

-- ===========================================================================
-- 滑入弹窗：显示 UI → 提升层级 → 刷新内容 → 播放动画
-- ===========================================================================
function Open()
    if ContextPtr:IsHidden() then
        ContextPtr:SetHide(false);
        ContextPtr:ChangeParent(ContextPtr:LookUpControl("/InGame/Choosers"));
        RefreshContent();
        Controls.SlideOnShow:SetToBeginning();
        Controls.SlideOnShow:Play();
        UI.PlaySound("Tech_Tray_Slide_Open");
    else
        RefreshContent();
    end
end

-- ===========================================================================
-- 滑出弹窗：反向播放动画
-- ===========================================================================
function Close()
    if not ContextPtr:IsHidden() and not Controls.SlideOnShow:IsReversing() then
        Controls.SlideOnShow:SetToEnd();
        Controls.SlideOnShow:Reverse();
        UI.PlaySound("Tech_Tray_Slide_Closed");
    end
end

-- ===========================================================================
-- 动画结束回调：逆向结束时隐藏
-- ===========================================================================
function OnAnimEnd()
    if Controls.SlideOnShow:IsReversing() then
        ContextPtr:SetHide(true);
    end
end

-- ===========================================================================
-- 调用核心函数计算弹窗数据（plot=nil → 仅 City/Player/Game 系）
-- ===========================================================================
function ComputePopupData(eDistrict, pkCity, Yield_Table)
    local iconString = "";
    local tooltipText = "";
    iconString, tooltipText = Ruivo_ExtraAdjacentYieldBonusString(
        eDistrict, pkCity, nil,
        iconString, tooltipText, Yield_Table, true
    );
    return iconString, tooltipText;
end

-- ===========================================================================
-- 构建区域的固有加成表（非单元格依赖：住房/宜居/空军槽位/伟人点数）
-- 参考 AdjacencyBonusSupport.lua#L222-342
-- ===========================================================================
function BuildInherentYieldTable(eDistrict)
    local Yield_Table = {};

    local districtRow = GameInfo.Districts[eDistrict];
    if not districtRow then return Yield_Table; end

    -- 区域固有基础住房
    if districtRow.Housing and districtRow.Housing > 0 then
        Yield_Table["YIELD_HOUSING"] = (Yield_Table["YIELD_HOUSING"] or 0) + districtRow.Housing;
    end

    -- 区域固有宜居度
    if districtRow.Entertainment and districtRow.Entertainment > 0 then
        Yield_Table["YIELD_AMENITY"] = (Yield_Table["YIELD_AMENITY"] or 0) + districtRow.Entertainment;
    end

    -- 区域固有空军槽位
    if districtRow.AirSlots and districtRow.AirSlots > 0 then
        Yield_Table["YIELD_AIR_SLOTS"] = (Yield_Table["YIELD_AIR_SLOTS"] or 0) + districtRow.AirSlots;
    end

    -- 区域固有伟人点数
    for row in GameInfo.District_GreatPersonPoints() do
        if row.DistrictType == districtRow.DistrictType then
            Yield_Table[row.GreatPersonClassType] = row.PointsPerTurn;
        end
    end

    return Yield_Table;
end

-- ===========================================================================
-- 从建筑类型解析对应的区域类型（用于相邻加成计算）
-- 与 DistrictPlotIconManager_MAB.lua 中逻辑一致
-- ===========================================================================
function ResolveDistrictForBuilding(buildingType, building)
    -- 1. 查建筑-区域映射表
    for row in GameInfo.Ruivo_Building_District_Mapping() do
        if row.BuildingType == buildingType then
            return row.DistrictType;
        end
    end
    -- 2. 奇观 → DISTRICT_WONDER
    if building.IsWonder then
        return "DISTRICT_WONDER";
    end
    return nil;
end

-- ===========================================================================
-- 刷新弹窗内容：图标 + 描述 + 固有加成 + 模块化加成
-- 支持区域放置 (DISTRICT_PLACEMENT) 和建筑/奇观放置 (BUILDING_PLACEMENT)
-- ===========================================================================
function RefreshContent()
    local pkCity = UI.GetHeadSelectedCity();
    if not pkCity then return; end

    local currentMode = UI.GetInterfaceMode();
    local eDistrict;
    local iconType;      -- "ICON_".. 图标的类型名
    local displayName;   -- 头部显示名称
    local description;   -- 描述文本

    if currentMode == InterfaceModeTypes.BUILDING_PLACEMENT then
        -- 建筑/奇观模式
        local buildingHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_BUILDING_TYPE);
        local building = GameInfo.Buildings[buildingHash];
        if not building then return; end

        local districtType = ResolveDistrictForBuilding(building.BuildingType, building);
        if not districtType then return; end

        local districtRow = GameInfo.Districts[districtType];
        if not districtRow then return; end
        eDistrict = districtRow.Index;

        -- 上半部：建筑图标
        iconType = building.BuildingType;
        -- 上半部：建筑描述
        description = building.Description;
        -- 头部：建筑名称
        displayName = building.Name;

    else
        -- 区域模式（默认）
        local districtHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
        local district = GameInfo.Districts[districtHash];
        if not district then return; end

        eDistrict = district.Index;
        local districtRow = GameInfo.Districts[eDistrict];
        if not districtRow then return; end

        iconType = districtRow.DistrictType;
        description = districtRow.Description;
        displayName = districtRow.Name;
    end

    -- 上半部：图标 (SetIcon, 同百科 AddPortrait)
    if iconType then
        Controls.DistrictIcon:SetIcon("ICON_" .. iconType);
        Controls.DistrictIcon:SetHide(false);
    else
        Controls.DistrictIcon:SetHide(true);
    end

    -- 上半部：描述
    if description then
        Controls.DistrictDescText:SetText(Locale.Lookup(description));
    else
        Controls.DistrictDescText:SetText("");
    end

    -- 构建固有加成表 + 调用模块化加成计算
    local Yield_Table = BuildInherentYieldTable(eDistrict);
    local iconString, tooltipText = ComputePopupData(eDistrict, pkCity, Yield_Table);

    -- 下半部：显示
    if iconString ~= "" then
        Controls.BottomTitle:SetText(Locale.Lookup("LOC_RUIVO_POPUP_BONUS_TITLE"));
        Controls.IconStringText:SetText(iconString);
        Controls.TooltipText:SetText(tooltipText ~= "" and tooltipText or "");
    else
        Controls.BottomTitle:SetText(Locale.Lookup("LOC_RUIVO_POPUP_NO_GLOBAL_BONUS"));
        Controls.IconStringText:SetText("");
        Controls.TooltipText:SetText("");
    end

    -- 更新头部
    if displayName then
        Controls.HeaderText:SetText(Locale.ToUpper(Locale.Lookup(displayName)));
    end
end

-- ===========================================================================
-- 监听界面模式切换：进入区域/建筑/奇观放置模式时打开弹窗
-- ===========================================================================
function OnInterfaceModeChanged(oldMode, newMode)
    if newMode == InterfaceModeTypes.DISTRICT_PLACEMENT
        or newMode == InterfaceModeTypes.BUILDING_PLACEMENT then
        Open();
    else
        Close();
    end
end

-- ===========================================================================
-- 初始化：注册关闭按钮、动画回调、模式切换事件
-- ===========================================================================
function Initialize()
    ContextPtr:SetHide(true);
    Controls.CloseButton:RegisterCallback(Mouse.eLClick, Close);
    Controls.SlideOnShow:RegisterEndCallback(OnAnimEnd);
    Events.InterfaceModeChanged.Add(OnInterfaceModeChanged);
end
Initialize();
