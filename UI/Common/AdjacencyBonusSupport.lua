-- ===========================================================================
--	功能：查找区域（District）因相邻地块属性而获得的产出加成
--	用途：UI 显示支持，用于在放置区域模式下计算和显示预期的相邻加成
--	说明：此文件主要被区域放置透镜（AdjacencyBonusLens）和生产面板调用
-- ===========================================================================
include( "Civ6Common" );		-- 引入 Civ6Common 库，主要用于 GetYieldString() 获取产出文本
include( "MapEnums" );			-- 引入地图枚举，用于处理方向、地块类型等


-- ===========================================================================
--	常量定义
-- ===========================================================================
-- 定义产出类型的索引范围，用于遍历检查各种产出（从食物到信仰）
local START_INDEX	:number = GameInfo.Yields["YIELD_FOOD"].Index;
local END_INDEX		:number = GameInfo.Yields["YIELD_FAITH"].Index;


-- 缓存表：存储哪些区域类型本身具有相邻加成规则
-- 作用：快速判断一个区域是否需要计算相邻加成，避免对无加成的区域进行无用计算
local m_DistrictsWithAdjacencyBonuses	:table = {};
for row in GameInfo.District_Adjacencies() do
	local districtIndex = GameInfo.Districts[row.DistrictType].Index;
	if (districtIndex ~= nil) then
		m_DistrictsWithAdjacencyBonuses[districtIndex] = true;
	end
end

-- CAO → artdef overlay entry name, populated from Ruivo_CAO.ArtdefOverlayEntry on LoadGameViewStateDone.
-- Allows mods to show tile-edge icons for their Ruivo adjacency types by setting ArtdefOverlayEntry in SQL.
local m_CAO_Icons :table = {};

-- ===========================================================================
--	功能：获取用于显示在地块之间的小图标 ArtDef 字符串名称
--	参数：
--		targetDistrictType: 目标区域类型
--		plot: 相邻的地块对象
--		pkCity: 所属城市
--		direction: 相邻方向
--	返回：图标的 ArtDef 字符串名称（例如 "Terrain_Forest"），如果无加成则返回空字符串
-- ===========================================================================
function GetAdjacentIconArtdefName( targetDistrictType:string, plot:table, pkCity:table, direction:number )

	local eDistrict = GameInfo.Districts[targetDistrictType].Index;
	local eType = -1;
	local iSubType = -1;
	
	-- 调用 C++ 层的 GetAdjacencyBonusType 获取具体的相邻加成类型和子类型
	eType, iSubType = plot:GetAdjacencyBonusType(Game.GetLocalPlayer(), pkCity:GetID(), eDistrict, direction);

	-- 根据加成类型返回对应的图标资源名
	if eType == AdjacencyBonusTypes.NO_ADJACENCY then
		-- Check Ruivo adjacency rules that target ring 1 ONLY (MinRings == MaxRings == 1).
		-- Broader ring ranges (e.g. 1–3) represent "nearby" bonuses rather than a single-tile
		-- relationship, so they intentionally produce no edge icon.
		if Ruivo_Adjacency_Cache and Ruivo_Adjacency_Cache.byDistrict then
			local cachedEntries = Ruivo_Adjacency_Cache.byDistrict[targetDistrictType] or {}
			for _, row in ipairs(cachedEntries) do
				local minR = row.MinRings or 1
				local maxR = row.MaxRings or row.Rings or 1
				if minR == 1 and maxR == 1 then
					-- Respect MustOwn: only show icon when the plot is owned by the city's player.
					if row.MustOwn ~= 1 or plot:GetOwner() == pkCity:GetOwner() then
						local cao = row.CustomAdjacentObject
						local iconArtdef = cao and m_CAO_Icons[cao]
						if iconArtdef and PlotMatchesRuivoCAO(plot, row.AdjacencyType, cao) then
							return iconArtdef
						end
					end
				end
			end
		end
		return "";
	elseif eType == AdjacencyBonusTypes.ADJACENCY_DISTRICT then
		return "Districts_Generic_District"; -- 通用区域图标
	elseif eType == AdjacencyBonusTypes.ADJACENCY_FEATURE then
		-- 根据地貌类型返回对应图标
		if iSubType == g_FEATURE_JUNGLE then
			return "Terrain_Jungle"; -- 雨林
		elseif iSubType == g_FEATURE_FOREST then
			return "Terrain_Forest"; -- 森林
		elseif iSubType == g_FEATURE_GEOTHERMAL_FISSURE then
			return "Terrain_Generic_Resource"; -- 地热裂缝（通常用通用资源图标）
		elseif iSubType == g_FEATURE_REEF then
			return "Terrain_Reef"; -- 礁石
		end
	elseif eType == AdjacencyBonusTypes.ADJACENCY_IMPROVEMENT then
		-- 根据改良设施返回图标
		if iSubType == 1 then
			return "Improvements_Farm"; -- 农场
		elseif iSubType == 2 then
			return "Improvement_Mine"; -- 矿山
		elseif iSubType == 3 then
			return "Improvement_Quarry"; -- 采石场
		end
	elseif eType == AdjacencyBonusTypes.ADJACENCY_NATURAL_WONDER then
		return "Wonders_Natural_Wonder"; -- 自然奇观
	elseif eType == AdjacencyBonusTypes.ADJACENCY_RESOURCE then
		return "Terrain_Generic_Resource"; -- 通用资源
	elseif eType == AdjacencyBonusTypes.ADJACENCY_RESOURCE_CLASS then
		return "Terrain_Generic_Resource_Class"; -- 资源类别
	elseif eType == AdjacencyBonusTypes.ADJACENCY_RIVER then
		return "Terrain_River"; -- 河流
	elseif eType == AdjacencyBonusTypes.ADJACENCY_SEA_RESOURCE then
		return "Terrain_Sea"; -- 海洋资源
	elseif eType == AdjacencyBonusTypes.ADJACENCY_TERRAIN then
		-- 根据地形类型返回图标
		if iSubType == g_TERRAIN_TYPE_TUNDRA or iSubType == g_TERRAIN_TYPE_TUNDRA_HILLS then
			return "Terrain_Tundra"; -- 冻土
		elseif iSubType == g_TERRAIN_TYPE_DESERT or iSubType == g_TERRAIN_TYPE_DESERT_HILLS then
			return "Terrain_Desert"; -- 沙漠
		elseif iSubType == g_TERRAIN_TYPE_COAST then -- TODO or TERRAIN_TYPE_OCEAN?
			return "Terrain_Coast"; -- 海岸
		else -- TODO specify mountain and have an error asset if no match?
			return "Terrain_Mountain"; -- 山脉（默认）
		end
	elseif eType == AdjacencyBonusTypes.ADJACENCY_WONDER then
		return "Generic_Wonder"; -- 人造奇观
	end
	
	-- 默认返回通用资源图标
	return "Terrain_Generic_Resource";
end

-- ===========================================================================
--	功能：获取并添加相邻地块的加成信息表
--	参数：
--		kPlot: 中心目标地块
--		districtType: 区域类型字符串
--		pSelectedCity: 选中的城市对象
--		tCurrentBonuses: 当前已有的加成表（用于更新）
--	返回：包含相邻地块加成信息的表
-- ===========================================================================
function AddAdjacentPlotBonuses( kPlot:table, districtType:string, pSelectedCity:table, tCurrentBonuses:table )
	local adjacentPlotBonuses:table = {};
	local x		:number = kPlot:GetX();
	local y		:number = kPlot:GetY();

	-- 遍历六个方向
	for _,direction in pairs(DirectionTypes) do			
		if direction ~= DirectionTypes.NO_DIRECTION and direction ~= DirectionTypes.NUM_DIRECTION_TYPES then
			local adjacentPlot	:table= Map.GetAdjacentPlot( x, y, direction);
			if adjacentPlot ~= nil then
				-- 获取该方向上相邻地块对应的加成图标名称
				local artdefIconName:string = GetAdjacentIconArtdefName( districtType, adjacentPlot, pSelectedCity, direction );
			
				if artdefIconName ~= nil and artdefIconName ~= "" then
		
					-- 获取或创建相邻地块的视图信息
					local districtViewInfo:table = GetViewPlotInfo( adjacentPlot, tCurrentBonuses );
					
					-- 计算反向方向（用于在相邻地块边缘正确绘制图标）
					local oppositeDirection :number = -1;
					if direction == DirectionTypes.DIRECTION_NORTHEAST	then oppositeDirection = DirectionTypes.DIRECTION_SOUTHWEST; end
					if direction == DirectionTypes.DIRECTION_EAST		then oppositeDirection = DirectionTypes.DIRECTION_WEST; end
					if direction == DirectionTypes.DIRECTION_SOUTHEAST	then oppositeDirection = DirectionTypes.DIRECTION_NORTHWEST; end
					if direction == DirectionTypes.DIRECTION_SOUTHWEST	then oppositeDirection = DirectionTypes.DIRECTION_NORTHEAST; end
					if direction == DirectionTypes.DIRECTION_WEST		then oppositeDirection = DirectionTypes.DIRECTION_EAST; end
					if direction == DirectionTypes.DIRECTION_NORTHWEST	then oppositeDirection = DirectionTypes.DIRECTION_SOUTHEAST; end

					-- 插入相邻加成信息到列表中
					table.insert( districtViewInfo.adjacent, {
						direction	= oppositeDirection,
						iconArtdef	= artdefIconName,
						inBonus		= false,
						outBonus	= true					
						}
					);				

					adjacentPlotBonuses[adjacentPlot:GetIndex()] = districtViewInfo;
				end
			end		
		end
	end

	return adjacentPlotBonuses;
end

-- ===========================================================================
--	功能：获取地块的视图信息表，如果不存在则初始化一个
--	参数：
--		kPlot: 游戏核心地块对象
--		kExistingTable: 现有的信息表，用于检查是否已存在
--	返回：新的或已存在的地块信息表 (plotInfo)
-- ===========================================================================
function GetViewPlotInfo( kPlot:table, kExistingTable:table )
	local plotId	:number = kPlot:GetIndex();
	local plotInfo	:table = kExistingTable[plotId];
	
	-- 如果表中没有该地块信息，则创建一个新的结构
	if plotInfo == nil then 
		plotInfo = {
			index	= plotId, 
			x		= kPlot:GetX(), 
			y		= kPlot:GetY(),
			adjacent= {},				-- 相邻边缘加成列表
			selectable = false,			-- 鼠标悬停时是否改变状态
			purchasable = false			-- 是否可购买
		}; 
	end
	--print( "   plot: " .. plotInfo.x .. "," .. plotInfo.y..": " .. tostring(plotInfo.iconArtdef) );
	return plotInfo;
end

-- ===========================================================================
--	功能：判断地块如果是可购买的，是否应该显示放置选项
--	返回：true 或 false
-- ===========================================================================
function IsShownIfPlotPurchaseable(eDistrict:number, pkCity:table, plot:table)
	return true;
end

-- ===========================================================================
--	核心功能：获取地块上区域的相邻加成文本字符串
--	参数：
--		eDistrict: 区域类型的 Index (number)
--		pkCity: 城市对象
--		plot: 目标地块对象
--	返回：
--		1. iconString: 图标字符串（可能包含住房等图标）
--		2. tooltipText: 详细的提示框文本（包含各产出加成明细）
--		3. requiredText: 如果不可用，返回解释文本；否则返回 nil
-- ===========================================================================

-- 引入 RUIVO 的统计模块，用于计算自定义相邻加成
include("RUIVO_STAT_MODULE_GP.lua");
local times = 0
-- 函数在此，获得加成的字符
function GetAdjacentYieldBonusString( eDistrict:number, pkCity:table, plot:table )
	times = times + 1

	local tooltipText	:string  = "";
	local totalBonuses	:string  = "";
	local requiredText	:string  = "";
	local isFirstEntry	:boolean = true;	
	local iconString	:string  = "";
	
	-- 检查地块是否有对应的区域，无对应区域时不显示固有加成
	local districtType = plot:GetDistrictType()
	local hasDistrict = false
	if districtType == eDistrict then
		hasDistrict = true
	end

	-- 初始化产出统计表，用于汇总所有来源的产出
	local Yield_Table	:table 	 = {
		YIELD_AIR_SLOTS = 0,  -- 空军槽位
		YIELD_HOUSING = 0,    -- 住房
		YIELD_FOOD = 0,       -- 食物
		YIELD_PRODUCTION = 0, -- 生产力
		YIELD_GOLD = 0,       -- 金币
		YIELD_SCIENCE = 0,    -- 科技值
		YIELD_CULTURE = 0,    -- 文化值
		YIELD_FAITH = 0,      -- 信仰值
		YIELD_AMENITY = 0     -- 宜居度
	}
	
    -- 有区域或者在建时，插入固有所有伟人点数作为产出类型（适配伟人点数加成）
	if hasDistrict then
        for row in GameInfo.District_GreatPersonPoints() do
			if row.DistrictType == GameInfo.Districts[eDistrict].DistrictType then
				Yield_Table[row.GreatPersonClassType] = row.PointsPerTurn
			end
        end
	end


		-- 1. 遍历并计算原版相邻加成规则
		-- 检查每一个邻居是否符合相邻规则
		for iBonusYield = START_INDEX, END_INDEX do
			-- 调用 C++ 层获取原版相邻产出值
			local iBonus:number = plot:GetAdjacencyYield(Game.GetLocalPlayer(), pkCity:GetID(), eDistrict, iBonusYield); 
			if (iBonus > 0) then
				-- 获取对应的提示文本
				local yieldTooltip, yieldRequireText = plot:GetAdjacencyBonusTooltip(Game.GetLocalPlayer(), pkCity:GetID(), eDistrict, iBonusYield);
				
				-- 拼接提示文本
				if tooltipText == "" then
					tooltipText = tooltipText..yieldTooltip;
				else
					tooltipText = tooltipText .. "[NEWLINE]" .. yieldTooltip;
				end

				-- 只需要一个 requiredText，如果有就替换
				requiredText = yieldRequireText;

				-- 获取产出字符串（例如 "+1 [ICON_Food]"）
				local yieldString:string = GetYieldString( GameInfo.Yields[iBonusYield].YieldType, iBonus );
				
				-- 将产出值存入统计表
				Yield_Table[GameInfo.Yields[iBonusYield].YieldType] = 
				Yield_Table[GameInfo.Yields[iBonusYield].YieldType] + iBonus
				--print(GameInfo.Yields[iBonusYield].YieldType, Yield_Table[GameInfo.Yields[iBonusYield].YieldType])
			end
		end
			
		-- 如果 requiredText 为空字符串，将其置为 nil
		if requiredText ~= nil and string.len(requiredText) < 1 then
			requiredText = nil;
		end

	-- 2. 计算区域提供的住房效果 (包括每回合固定住房和基于魅力的住房)
	local iAppeal = plot:GetAppeal(); -- 获取地块魅力
	-- 获取区域固有基础住房
	local iBaseHousing = 0
	if hasDistrict then
		iBaseHousing = GameInfo.Districts[eDistrict].Housing; 
	end

	-- 默认为姆班扎的情况（无魅力变化）
	local iTotalHousing:number = iBaseHousing;

	-- 遍历 AppealHousingChanges 表（例如社区根据魅力提供不同住房）
	for row in GameInfo.AppealHousingChanges() do
		if (row.DistrictType == GameInfo.Districts[eDistrict].DistrictType) then
			local iMinimumValue = row.MinimumValue;
			local iAppealChange = row.AppealChange;
			local szDescription = row.Description;
			-- 如果满足最小魅力要求
			if (iAppeal >= iMinimumValue) then
				iTotalHousing = iBaseHousing + iAppealChange;
				-- 添加提示文本
				tooltipText = tooltipText..Locale.Lookup("LOC_DISTRICT_ZONE_NEIGHBORHOOD_TOOLTIP", GameInfo.Districts[eDistrict].Housing + iAppealChange, szDescription);
				break;
			end
		end
	end

	-- 如果有住房加成，添加到统计表和图标字符串
	if iTotalHousing ~= 0 then
		if iconString ~= "" then iconString = iconString.."[NEWLINE]" end
		--iconString = iconString.."[ICON_Housing]+" .. tostring(iTotalHousing);
		-- 存入住房数
		Yield_Table["YIELD_HOUSING"] = Yield_Table["YIELD_HOUSING"] + iTotalHousing
		--print("当前收集表中的住房为：", Yield_Table["YIELD_HOUSING"])
	end


	--获取区域固有空军槽位
	local iBaseAirSlots = 0
	if hasDistrict then
		iBaseAirSlots = GameInfo.Districts[eDistrict].AirSlots; 
	end
	-- 存入空军槽位数
	Yield_Table["YIELD_AIR_SLOTS"] = Yield_Table["YIELD_AIR_SLOTS"] + iBaseAirSlots

	-- 3. 获取区域提供的固有宜居度
	if hasDistrict then
		Yield_Table["YIELD_AMENITY"] = Yield_Table["YIELD_AMENITY"] + GameInfo.Districts[eDistrict].Entertainment
	end

	--==================================================================================
	-- 4. 模块化相邻加成部分 (RUIVO MOD 核心挂钩点)
	-- 调用模组自定义函数，计算并追加额外的相邻加成文本和图标
	--==================================================================================
		if eDistrict then 
			iconString, tooltipText = Ruivo_ExtraAdjacentYieldBonusString(eDistrict, pkCity, plot, iconString, tooltipText, Yield_Table, hasDistrict)
		end
	--==================================================================================

	return iconString, tooltipText, requiredText;
end



-- ===========================================================================
--	功能：获取城市拥有的（或可以拥有的）所有地块索引
--	参数：pCity - 目标城市对象
--	返回：地块索引表
-- ===========================================================================
function GetCityRelatedPlotIndexes( pCity:table )
	
	--print("GetCityRelatedPlotIndexes() isn't updated with the latest purchaed plot if one was just purchased and this is being called on Event.CityMadePurchase !");
	-- 获取城市已购买的地块
	local plots:table = Map.GetCityPlots():GetPurchasedPlots( pCity );

	-- 获取未拥有但可购买的地块（这些也是放置区域的潜在好位置！）
	local tParameters :table = {};
	tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
	local tResults = CityManager.GetCommandTargets( pCity, CityCommandTypes.PURCHASE, tParameters );
	if (tResults[CityCommandResults.PLOTS] ~= nil and table.count(tResults[CityCommandResults.PLOTS]) ~= 0) then
		for _,plotId in pairs(tResults[CityCommandResults.PLOTS]) do
			table.insert(plots, plotId);
		end
	end

	return plots;
end

-- ===========================================================================
--	功能：同上，但专门针对区域放置，即使缓存未更新也能工作
--	参数：
--		pCity: 目标城市
--		districtHash: 区域类型的 Hash 值
--	返回：符合条件的地块索引列表
-- ===========================================================================
function GetCityRelatedPlotIndexesDistrictsAlternative( pCity:table, districtHash:number )

	local district		:table = GameInfo.Districts[districtHash];
	local plots			:table = {};
	local tParameters	:table = {};

	tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtHash;


	-- 1. 获取所有可用的建造地块（Available to place plots）
	local tResults :table = CityManager.GetOperationTargets( pCity, CityOperationTypes.BUILD, tParameters );
	if (tResults[CityOperationResults.PLOTS] ~= nil and table.count(tResults[CityOperationResults.PLOTS]) ~= 0) then			
		local kPlots:table = tResults[CityOperationResults.PLOTS];			
		for i, plotId in ipairs(kPlots) do
			table.insert(plots, plotId);
		end	
	end	

	--[[
	-- antonjs: 从 UI 显示中移除被阻塞的地块。现在区域放置可以自动移除地貌、资源和改良设施，
	-- 只要玩家拥有相应科技，就没有必要显示红色阻塞块，那会让人困惑。
	-- （保留这段被注释的代码以作参考）
	if (tResults[CityOperationResults.BLOCKED_PLOTS] ~= nil and table.count(tResults[CityOperationResults.BLOCKED_PLOTS]) ~= 0) then			
		for _, plotId in ipairs(tResults[CityOperationResults.BLOCKED_PLOTS]) do
			table.insert(plots, plotId);		
		end
	end
	--]]

	-- 2. 获取未拥有但如果购买后可以获得加成的地块
	tParameters = {};
	tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
	local tResults = CityManager.GetCommandTargets( pCity, CityCommandTypes.PURCHASE, tParameters );
	if (tResults[CityCommandResults.PLOTS] ~= nil and table.count(tResults[CityCommandResults.PLOTS]) ~= 0) then
		for _,plotId in pairs(tResults[CityCommandResults.PLOTS]) do
			
			local kPlot	:table = Map.GetPlotByIndex(plotId);	
			-- 检查该地块是否允许放置该区域
			if kPlot:CanHaveDistrict(district.Index, pCity:GetOwner(), pCity:GetID()) then
				local isValid :boolean = IsShownIfPlotPurchaseable(district.Index, pCity, kPlot);
				if isValid then
					table.insert(plots, plotId);
				end
			end
			
		end
	end
	return plots;
end

-- ===========================================================================
--	功能：同上，但专门针对奇观放置
--	参数：
--		pCity: 目标城市
--		buildingHash: 奇观（建筑）类型的 Hash 值
-- ===========================================================================
-- ===========================================================================
--	功能：判断相邻地块是否匹配 Ruivo 相邻规则中的 CustomAdjacentObject
--	说明：仅处理单地块可判断的 CAO 类型；属性类、游戏级、河流等类型不对应
--	      单一地块，故意不处理，直接返回 false。
-- ===========================================================================
function PlotMatchesRuivoCAO( adjacentPlot:table, adjacencyType:string, cao:string )
	if adjacencyType == "FROM_RINGS_TYPETAG_RESOURCE" then
		local eResource = adjacentPlot:GetResourceType()
		if eResource >= 0 then
			local resType = ResourceTypeMap[eResource]
			-- TypeTagsMap structure: [tag][resourceType] = true
			return TypeTagsMap[cao] ~= nil and TypeTagsMap[cao][resType] == true
		end
	elseif adjacencyType == "FROM_RINGS_CAO_RESOURCE" then
		local eResource = adjacentPlot:GetResourceType()
		return eResource >= 0 and ResourceTypeMap[eResource] == cao
	elseif adjacencyType == "FROM_RINGS_CAO_IMPROVEMENT" then
		local eImprv = adjacentPlot:GetImprovementType()
		return eImprv >= 0 and ImprovementTypeMap[eImprv] == cao
	elseif adjacencyType == "FROM_RINGS_CAO_FEATURE" then
		local eFeat = adjacentPlot:GetFeatureType()
		return eFeat >= 0 and FeatureTypeMap[eFeat] == cao
	elseif adjacencyType == "FROM_RINGS_CAO_DISTRICT" then
		local eDist = adjacentPlot:GetDistrictType()
		return eDist >= 0 and DistrictTypeMap[eDist] == cao
	elseif adjacencyType == "FROM_RINGS_CAO_TERRAIN" then
		local eTerrain = adjacentPlot:GetTerrainType()
		if eTerrain >= 0 then
			local terrainRow = GameInfo.Terrains[eTerrain]
			return terrainRow ~= nil and terrainRow.TerrainType == cao
		end
	elseif adjacencyType == "FROM_RINGS_CAO_RESOURCE_CLASS" then
		local eResource = adjacentPlot:GetResourceType()
		if eResource >= 0 then
			local resType = ResourceTypeMap[eResource]
			local resRow = GameInfo.Resources[resType]
			return resRow ~= nil and resRow.ResourceClassType == cao
		end
	elseif adjacencyType == "FROM_RINGS_CAO_TERRAIN_SETS" then
		if     cao == "IsMountain"      then return adjacentPlot:IsMountain()
		elseif cao == "IsHills"         then return adjacentPlot:IsHills()
		elseif cao == "IsFlatlands"     then return adjacentPlot:IsFlatlands()
		elseif cao == "IsWater"         then return adjacentPlot:IsWater()
		elseif cao == "IsShallowWater"  then return adjacentPlot:IsShallowWater()
		elseif cao == "IsLake"          then return adjacentPlot:IsLake()
		elseif cao == "IsCanyon"        then return adjacentPlot:IsCanyon()
		elseif cao == "IsCoastalLand"   then return adjacentPlot:IsCoastalLand()
		elseif cao == "IsRiverCrossing" then return adjacentPlot:IsRiverCrossing()
		elseif cao == "IsOpenGround"    then return adjacentPlot:IsOpenGround()
		elseif cao == "IsRoughGround"   then return adjacentPlot:IsRoughGround()
		end
	end
	-- All other types (property-based, game-level, wonder, etc.) do not correspond to a
	-- single adjacent tile and will never produce an edge icon.
	return false
end

-- ===========================================================================
--	功能：从 Ruivo_CAO.ArtdefOverlayEntry 建立 CAO → 图标 artdef 名称的查找表
--	时机：在 LoadGameViewStateDone 时调用，与 STAT_Initialize 同时触发
-- ===========================================================================
function BuildCAOIconLookup()
	m_CAO_Icons = {}
	for row in GameInfo.Ruivo_CAO() do
		if row.ArtdefOverlayEntry and row.ArtdefOverlayEntry ~= "" then
			m_CAO_Icons[row.CustomAdjacentObject] = row.ArtdefOverlayEntry
		end
	end
end
Events.LoadGameViewStateDone.Add(BuildCAOIconLookup);

-- ===========================================================================
function GetCityRelatedPlotIndexesWondersAlternative( pCity:table, buildingHash:number )

	local building		:table = GameInfo.Buildings[buildingHash];
	local plots			:table = {};
	local tParameters	:table = {};

	tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = buildingHash;


	-- 1. 获取所有可用的建造地块
	local tResults :table = CityManager.GetOperationTargets( pCity, CityOperationTypes.BUILD, tParameters );
	if (tResults[CityOperationResults.PLOTS] ~= nil and table.count(tResults[CityOperationResults.PLOTS]) ~= 0) then			
		local kPlots:table = tResults[CityOperationResults.PLOTS];			
		for i, plotId in ipairs(kPlots) do
			table.insert(plots, plotId);
		end	
	end	

	-- 2. 获取未拥有但如果是我们的就能建造奇观的地块（潜在购买项）
	tParameters = {};
	tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
	local tResults = CityManager.GetCommandTargets( pCity, CityCommandTypes.PURCHASE, tParameters );
	if (tResults[CityCommandResults.PLOTS] ~= nil and table.count(tResults[CityCommandResults.PLOTS]) ~= 0) then
		for _,plotId in pairs(tResults[CityCommandResults.PLOTS]) do
			
			local kPlot	:table = Map.GetPlotByIndex(plotId);	
			-- 检查地块是否能建造奇观
			if kPlot:CanHaveWonder(building.Index, pCity:GetOwner(), pCity:GetID()) then
				table.insert(plots, plotId);
			end
			
		end
	end
	return plots;
end

-- ===========================================================================
-- RUIVO MAB: 覆写 Realize2dArtForCityDistricts，在建筑/奇观放置时显示相邻加成
-- 原理：本文件在 DistrictPlotIconManager.lua 头部被 include，此时目标函数尚未定义。
--       利用 GetAdjacentYieldBonusString 首次调用时（所有函数已定义完毕）完成覆写。
-- 兼容：不依赖 ReplaceUIScript，与 KublaiKhan_Vietnam 等 mod 无冲突。
-- ===========================================================================
local MAB_PADDING_X = 18;
local MAB_PADDING_Y = 16;
local MAB_OverrideApplied = false;

-- 根据建筑类型解析对应的区域 Index
local function MAB_GetDistrictIndexForBuilding(buildingType, building)
	for row in GameInfo.Ruivo_Building_District_Mapping() do
		if row.BuildingType == buildingType then
			local districtRow = GameInfo.Districts[row.DistrictType];
			if districtRow then return districtRow.Index; end
		end
	end
	if building.IsWonder then
		local wonderRow = GameInfo.Districts["DISTRICT_WONDER"];
		if wonderRow then return wonderRow.Index; end
	end
	return nil;
end

-- 延迟覆写：Events.LoadScreenClose 触发时所有 UI 已初始化完毕，Realize2dArtForCityDistricts 已定义
function MAB_TryApplyOverride()
	if MAB_OverrideApplied then return end
	if not Realize2dArtForCityDistricts then return end
	MAB_OverrideApplied = true;

	local MAB_BASE = Realize2dArtForCityDistricts;

	Realize2dArtForCityDistricts = function(pCity)
		local buildingHash = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_BUILDING_TYPE);
		local building = GameInfo.Buildings[buildingHash];

		if building ~= nil then
			local eAdjDistrict = MAB_GetDistrictIndexForBuilding(building.BuildingType, building);
			local bIsWonder = building.IsWonder;

			local plots = GetCityRelatedPlotIndexesWondersAlternative(pCity, buildingHash);
			for i, plotID in pairs(plots) do
				local kPlot = Map.GetPlotByIndex(plotID);
				if kPlot == nil then
					UI.DataError("[MAB] Bad plot index #" .. tostring(plotID));
				else
					local bValidPlot = bIsWonder and kPlot:CanHaveWonder(building.Index, pCity:GetOwner(), pCity:GetID())
						or not bIsWonder;
					if bValidPlot then
						local instance = GetInstanceAt(plotID);
						if eAdjDistrict then
							local yieldBonus, yieldTooltip = GetAdjacentYieldBonusString(eAdjDistrict, pCity, kPlot);
							instance.PlotBonus:SetHide(yieldBonus == "");
							instance.BonusText:SetText(yieldBonus);
							instance.BonusText:SetToolTipString(yieldTooltip);
						else
							instance.PlotBonus:SetHide(true);
							instance.BonusText:SetText("");
						end
						instance.PrereqIcon:SetHide(true);
						local x, y = instance.BonusText:GetSizeVal();
						instance.PlotBonus:SetSizeVal(x + MAB_PADDING_X, y + MAB_PADDING_Y);
						RealizeIconStack(instance);
					end
				end
			end
		else
			MAB_BASE(pCity);
		end
	end;
end

-- 游戏加载完毕后覆写（此时所有 UI 函数已就绪）
Events.LoadScreenClose.Add(MAB_TryApplyOverride);
