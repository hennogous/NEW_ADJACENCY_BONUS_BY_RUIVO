-- author is Infixo, thank you!

--待做加成来源：
--输入贸易路线的6种产出数
--输出贸易路线的6种产出数

--自身、相邻、城市、玩家建筑总数
--自身、相邻、城市、玩家巨作总数
--城市贸易站数量
--宗教体系

-- ===========================================================================
--	获取指定城市的数据，返回包含该城市及其周边区域数据的表。
--	返回值：包含城市数据的 table
--				.City - 城市对象 (pCity)
--				.Name - 城市名称
--				.Districts - 区域表 (包含建筑)
--						.Buildings - 区域内的建筑列表
--				.Wonders - 奇观列表
--				.OutgoingRoutes - 输出贸易路线列表
--				.IncomingRoutes - 输入贸易路线列表
-- ===========================================================================
function GetCityData( pCity:table )

	local ownerID				:number = pCity:GetOwner();
	local pPlayer				:table	= Players[ownerID];
	local pCityDistricts		:table	= pCity:GetDistricts();
	-- 注意：玩家的 GetDistricts() 对象与上面的不同。
	local pMainDistrict			:table	= pPlayer:GetDistricts():FindID( pCity:GetDistrictID() );	
	local districtHitpoints		:number	= 0;
	local currentDistrictDamage :number = 0;
	local wallHitpoints			:number	= 0;
	local currentWallDamage		:number	= 0;
	local garrisonDefense		:number	= 0;

	-- 获取城市中心区域的防御和受损情况
	if pCity ~= nil and pMainDistrict ~= nil then
		districtHitpoints		= pMainDistrict:GetMaxDamage(DefenseTypes.DISTRICT_GARRISON);
		currentDistrictDamage	= pMainDistrict:GetDamage(DefenseTypes.DISTRICT_GARRISON);
		wallHitpoints			= pMainDistrict:GetMaxDamage(DefenseTypes.DISTRICT_OUTER);
		currentWallDamage		= pMainDistrict:GetDamage(DefenseTypes.DISTRICT_OUTER);
		garrisonDefense			= math.floor(pMainDistrict:GetDefenseStrength() + 0.5);
	end

	-- 初始化返回值数据表，部分字段将在后续逻辑中填充
	local data :table = {
		City					= pCity,
		SubjectType				= SubjectTypes.City,
		Name					= Locale.Lookup(pCity:GetName()),
		Yields 					= YieldTableNew(), -- 扩展产出表
		ContinentType			= 0,
		Districts				= {},		-- 每项格式: { Name, YieldType, YieldChange, Buildings={ Name,YieldType,YieldChange,isPillaged,isBuilt} }
		FoodSurplus				= 0,
		IsGovernorEstablished	= false,
		NumDistricts			= 0,
		NumSpecialtyDistricts	= 0,
		Population				= pCity:GetPopulation(),
		Wonders					= {},		-- 每项格式: { Name, YieldType, YieldChange }
		Plot 					= Map.GetPlot(pCity:GetX(), pCity:GetY()),
		NumResources            = 0,        -- 已改良的不同资源种类数量 (Johannesburg 效果相关)
		IsGarrisonUnit          = false,    -- 城市或军事驻地内是否有驻军
		
		--- 尚未在 RMA 中使用的字段
		AmenitiesNetAmount				= 0,
		AmenitiesNum					= 0,
		AmenitiesFromLuxuries			= 0,
		AmenitiesFromEntertainment		= 0,
		AmenitiesFromCivics				= 0,
		AmenitiesFromGreatPeople		= 0,
		AmenitiesFromCityStates			= 0,
		AmenitiesFromReligion			= 0,
		AmenitiesFromNationalParks  	= 0,
		AmenitiesFromStartingEra		= 0,
		AmenitiesFromImprovements		= 0,
		AmenitiesRequiredNum			= 0,
		AmenitiesFromGovernors			= 0,
		BeliefsOfDominantReligion		= {},
		Buildings						= {},		-- 每项格式: { Name, CitizenNum }
		BuildingsNum					= 0,
		CityWallTotalHP					= 0,
		CityWallHPPercent				= 0,
		CulturePerTurn					= 0,
		CurrentFoodPercent				= 0;		
		CurrentProdPercent				= 0,
		CurrentProductionName			= "",
		CurrentProductionDescription	= "",
		CurrentTurnsLeft				= 0,
		Damage							= 0,
		Defense							= garrisonDefense;
		DistrictsNum					= pCityDistricts:GetNumZonedDistrictsRequiringPopulation(),
		DistrictsPossibleNum			= pCityDistricts:GetNumAllowedDistrictsRequiringPopulation(),
		FaithPerTurn					= 0,
		FoodPercentNextTurn				= 0,
		FoodPerTurn						= 0,
		GoldPerTurn						= 0,
		GrowthPercent					= 100,
		Happiness						= 0,		
		HappinessGrowthModifier			= 0,		-- 倍率修正
		HappinessNonFoodYieldModifier	= 0,		-- 倍率修正
		Housing							= 0,
		HousingMultiplier				= 0,
		IsCapital						= pCity:IsCapital(),
		IsUnderSiege					= false,
		OccupationMultiplier            = 0,
		OwnerID							= ownerID,
		OtherGrowthModifiers			= 0,
		PantheonBelief					= -1,
		ProdPercentNextTurn				= 0,
		ProductionPerTurn				= 0;		
		ProductionQueue					= {},
		Religions						= {},		-- 每项格式: { Name, Followers }
		ReligionFollowers				= 0,
		SciencePerTurn					= 0,
		TradingPosts					= {},		-- 每项格式: { Player ID }
		TurnsUntilGrowth				= 0,
		TurnsUntilExpansion				= 0,
		UnitStats						= nil,
		--YieldFilters					= {},
	};

	-- 填充基本产出数据
	for yield,yid in pairs(YieldTypes) do data.Yields[ yield ] = pCity:GetYield( yid ); end
	
	local pCityGrowth					:table = pCity:GetGrowth();
	local pCityCulture					:table = pCity:GetCulture();
	local cityGold						:table = pCity:GetGold();		
	local pBuildQueue					:table = pCity:GetBuildQueue();
	local currentProduction				:string = "LOC_HUD_CITY_PRODUCTION_NOTHING_PRODUCED";
	local currentProductionDescription	:string = "";
	local currentProductionStats		:string = "";
	local pct							:number = 0;
	local pctNextTurn					:number = 0;
	local prodTurnsLeft					:number = -1;
	local productionInfo				:table = nil; -- 当前暂不处理生产项目详细信息

	-- 住房和宜居度也作为扩展产出处理
	data.Yields.HOUSING = pCityGrowth:GetHousing();
	data.Yields.AMENITY = pCityGrowth:GetAmenities();
	
	-- 获取总督和大陆等额外数据
	data.IsGovernorEstablished, data.NumGovernorPromotions = GetGovernorData(pCity)
	data.ContinentType = Map.GetPlot( pCity:GetX(), pCity:GetY() ):GetContinentType()
	data.GreatWorks = GetGreatWorksForCity(pCity)
	
	-- 如果当前有正在生产的项目，记录到队列中
	if productionInfo ~= nil then
		currentProduction				= productionInfo.Name;
		currentProductionDescription	= productionInfo.Description;
		if(productionInfo.StatString ~= nil) then
			currentProductionStats		= productionInfo.StatString;
		end
		pct								= productionInfo.PercentComplete;
		pctNextTurn						= productionInfo.PercentCompleteNextTurn;
		prodTurnsLeft					= productionInfo.Turns;
		productionInfo.Index			= 1;
		data.ProductionQueue[1]			= productionInfo;	-- 置于队首

		if currentProductionDescription == nil then
			currentProductionDescription = "";
		end
	end

	-- 记录当前生产项目的类型
	data.CurrentProductionType = "NONE";
	local iCurrentProductionHash:number = pCity:GetBuildQueue():GetCurrentProductionTypeHash();
	if iCurrentProductionHash ~= 0 then
		if     GameInfo.Buildings[iCurrentProductionHash] ~= nil then data.CurrentProductionType = "BUILDING";
		elseif GameInfo.Districts[iCurrentProductionHash] ~= nil then data.CurrentProductionType = "DISTRICT";
		elseif GameInfo.Units[iCurrentProductionHash]     ~= nil then data.CurrentProductionType = "UNIT";
		elseif GameInfo.Projects[iCurrentProductionHash]  ~= nil then data.CurrentProductionType = "PROJECT";
		end
	end

	-- 处理人口增长或饥饿状态
	local isGrowing	:boolean = pCityGrowth:GetTurnsUntilGrowth() ~= -1;
	local isStarving:boolean = pCityGrowth:GetTurnsUntilStarvation() ~= -1;

	local turnsUntilGrowth :number = 0;
	if isGrowing then
		turnsUntilGrowth = pCityGrowth:GetTurnsUntilGrowth();
	elseif isStarving then
		turnsUntilGrowth = -pCityGrowth:GetTurnsUntilStarvation();	-- 用负数表示饥饿倒计时
	end	
		
	local food             :number = pCityGrowth:GetFood();
	local growthThreshold  :number = pCityGrowth:GetGrowthThreshold();
	local foodSurplus      :number = pCityGrowth:GetFoodSurplus();
	local foodpct          :number = math.max( math.min( food / growthThreshold, 1.0 ), 0.0);
	local foodpctNextTurn  :number = 0;
	if turnsUntilGrowth > 0 then
		local foodGainNextTurn = foodSurplus * pCityGrowth:GetOverallGrowthModifier();
		foodpctNextTurn = (food + foodGainNextTurn) / growthThreshold;
		foodpctNextTurn = math.max( math.min( foodpctNextTurn, 1.0), 0.0 );
	end

	-- 处理宗教数据：包括游戏全局宗教、玩家宗教以及城市内的宗教信徒分布
	local pGameReligion		:table = Game.GetReligion();
	local pPlayerReligion	:table = pPlayer:GetReligion();
	local pAllReligions		:table = pGameReligion:GetReligions();
	local pReligions		:table = pCity:GetReligion():GetReligionsInCity();	
	local eDominantReligion	:number = pCity:GetReligion():GetMajorityReligion();
	local followersAll		:number = 0;
	for _, religionData in pairs(pReligions) do				

		-- 如果宗教 ID 小于 0，通常表示为万神殿
		local religionType	:string = (religionData.Religion > 0) and GameInfo.Religions[religionData.Religion].ReligionType or "RELIGION_PANTHEON";
		local thisReligion	:table = { ID=religionData.Religion, ReligionType=religionType, Followers=religionData.Followers };
		table.insert( data.Religions, thisReligion );		

		-- 如果是主流宗教，记录其信仰详情
		if religionData.Religion == eDominantReligion and eDominantReligion > -1 then
			data.Religions[DATA_DOMINANT_RELIGION] = thisReligion;
			for _,kFoundReligion in ipairs(pAllReligions) do
				if kFoundReligion.Religion == eDominantReligion then
					for _,belief in pairs(kFoundReligion.Beliefs) do
						table.insert( data.BeliefsOfDominantReligion, belief );
					end
					break;
				end
			end
		end

		if religionType ~= "RELIGION_PANTHEON" then
			followersAll = followersAll + religionData.Followers;
		end
	end

	-- 获取主流宗教的信徒数量
	data.MajorityReligionFollowers = 0;
	if eDominantReligion > 0 then 
		for _, religionData in pairs(pCity:GetReligion():GetReligionsInCity()) do
			if religionData.Religion == eDominantReligion then data.MajorityReligionFollowers = religionData.Followers; end
		end
	end
	
	-- 填充宜居度、住房、城墙、生命值等详细统计数据
	data.AmenitiesNetAmount				= pCityGrowth:GetAmenities() - pCityGrowth:GetAmenitiesNeeded();
	data.AmenitiesNum					= pCityGrowth:GetAmenities();
	data.AmenitiesFromLuxuries			= pCityGrowth:GetAmenitiesFromLuxuries();
	data.AmenitiesFromEntertainment		= pCityGrowth:GetAmenitiesFromEntertainment();
	data.AmenitiesFromCivics			= pCityGrowth:GetAmenitiesFromCivics();
	data.AmenitiesFromGreatPeople		= pCityGrowth:GetAmenitiesFromGreatPeople();
	data.AmenitiesFromCityStates		= pCityGrowth:GetAmenitiesFromCityStates();
	data.AmenitiesFromReligion			= pCityGrowth:GetAmenitiesFromReligion();
	data.AmenitiesFromNationalParks		= pCityGrowth:GetAmenitiesFromNationalParks();
	data.AmenitiesFromStartingEra		= pCityGrowth:GetAmenitiesFromStartingEra();
	data.AmenitiesFromImprovements		= pCityGrowth:GetAmenitiesFromImprovements();
	data.AmenitiesLostFromWarWeariness	= pCityGrowth:GetAmenitiesLostFromWarWeariness();
	data.AmenitiesLostFromBankruptcy	= pCityGrowth:GetAmenitiesLostFromBankruptcy();
	data.AmenitiesRequiredNum			= pCityGrowth:GetAmenitiesNeeded();
	--data.AmenitiesFromGovernors			= pCityGrowth:GetAmenitiesFromGovernors();
	data.AmenityAdvice					= pCity:GetAmenityAdvice();
	data.CityWallHPPercent				= (wallHitpoints-currentWallDamage) / wallHitpoints;
	data.CityWallCurrentHP				= wallHitpoints-currentWallDamage;
	data.CityWallTotalHP				= wallHitpoints;
	data.CurrentFoodPercent				= foodpct;
	data.CurrentProductionName			= Locale.Lookup( currentProduction );
	data.CurrentProdPercent				= pct;
	data.CurrentProductionDescription	= Locale.Lookup( currentProductionDescription );
	data.CurrentProductionIcon			= productionInfo and productionInfo.Icon;
	data.CurrentProductionStats			= productionInfo and productionInfo.StatString;
	data.CurrentTurnsLeft				= prodTurnsLeft;		
	data.FoodPercentNextTurn			= foodpctNextTurn;
	data.FoodSurplus					= foodSurplus; 
	data.Happiness						= pCityGrowth:GetHappiness();
	data.HappinessGrowthModifier		= pCityGrowth:GetHappinessGrowthModifier();
	data.HappinessNonFoodYieldModifier	= pCityGrowth:GetHappinessNonFoodYieldModifier();
	data.HitpointPercent				= ((districtHitpoints-currentDistrictDamage) / districtHitpoints);
	data.HitpointsCurrent				= districtHitpoints-currentDistrictDamage;
	data.HitpointsTotal					= districtHitpoints;
	data.Housing						= pCityGrowth:GetHousing(); 
	data.HousingFromWater				= pCityGrowth:GetHousingFromWater();
	data.HousingFromBuildings			= pCityGrowth:GetHousingFromBuildings();
	data.HousingFromImprovements		= pCityGrowth:GetHousingFromImprovements(); 
	data.HousingFromDistricts			= pCityGrowth:GetHousingFromDistricts();
	data.HousingFromCivics				= pCityGrowth:GetHousingFromCivics();
	data.HousingFromGreatPeople			= pCityGrowth:GetHousingFromGreatPeople();
	data.HousingFromStartingEra			= pCityGrowth:GetHousingFromStartingEra();
	data.HousingMultiplier				= pCityGrowth:GetHousingGrowthModifier();
	data.HousingAdvice					= pCity:GetHousingAdvice();
	data.OccupationMultiplier			= pCityGrowth:GetOccupationGrowthModifier();
	data.Occupied                       = pCity:IsOccupied();
	data.OtherGrowthModifiers			= pCityGrowth:GetOtherGrowthModifier();	-- 来自宗教和奇观的增长修正
	data.PantheonBelief					= pPlayerReligion:GetPantheon();	
	data.ProdPercentNextTurn			= pctNextTurn;
	data.ReligionFollowers				= followersAll;
	data.TurnsUntilExpansion			= pCityCulture:GetTurnsUntilExpansion();
	data.TurnsUntilGrowth				= turnsUntilGrowth;
	data.UnitStats						= nil;
	
	-- 确定建筑、区域和奇观
	local pCityBuildings	:table = pCity:GetBuildings();
	local kCityPlots		:table = Map.GetCityPlots():GetPurchasedPlots( pCity );
	if (kCityPlots ~= nil) then
		for _,plotID in pairs(kCityPlots) do
			local kPlot:table =  Map.GetPlotByIndex(plotID);
			local kBuildingTypes:table = pCityBuildings:GetBuildingsAtLocation(plotID);
			for _, type in ipairs(kBuildingTypes) do
				local building	= GameInfo.Buildings[type];
				table.insert( data.Buildings, { 
					Name		= GameInfo.Buildings[building.BuildingType].Name, 
					Citizens	= kPlot:GetWorkerCount(),
					isPillaged	= pCityBuildings:IsPillaged(type),
					Maintenance	= GameInfo.Buildings[building.BuildingType].Maintenance			-- 金币维护费
				});
			end
		end
	end	

	local pDistrict : table = pPlayer:GetDistricts():FindID( pCity:GetDistrictID() );
	if pDistrict ~= nil then
		data.IsUnderSiege = pDistrict:IsUnderSiege();
	else
		UI.DataError("由于无法获取城市对应的区域对象，部分数据将缺失: "..pCity:GetName());
	end
	
	-------------------------------------
	-- 处理城市单元格资源
	-- 遍历城市所有已购买的单元格，统计改良资源的种类
	local kResources: table = {};
	local cityPlots : table = Map.GetCityPlots():GetPurchasedPlots(pCity)
	for _, plotID in ipairs(cityPlots) do
		local plot: table = Map.GetPlotByIndex(plotID);
		local eResourceType: number = plot:GetResourceType();
		local eImprovementType: number = plot:GetImprovementType();

	    -- 统计改良后的不同资源类型 (Johannesburg 城邦效果相关)
		-- 注意：必须是实际的改良设施，区域下的战略资源不触发此效果
		if eResourceType ~= -1 and eImprovementType ~= -1 and not plot:IsImprovementPillaged() then
			-- 检查改良设施是否对该资源有效
			local tResults: table =
				DB.Query("SELECT * FROM Improvement_ValidResources WHERE ImprovementType = ? AND ResourceType = ?",
					GameInfo.Improvements[eImprovementType].ImprovementType,
					GameInfo.Resources[eResourceType].ResourceType);
			if tResults and #tResults > 0 then -- 找到有效的改良资源
				kResources[eResourceType] = true;
			end
		end
	end
	data.NumResources = table.count(kResources);	
	
	-------------------------------------
	-- 遍历城市区域
	for i, district in pCityDistricts:Members() do

		-- 辅助函数：获取区域产出
		local kTempDistrictYields :table = {};
		for yield in GameInfo.Yields() do
			kTempDistrictYields[yield.Index] = yield;
		end
		
		function GetDistrictYield( district:table, yieldType:string )
			for i,yield in ipairs( kTempDistrictYields ) do
				if yield.YieldType == yieldType then
					return district:GetYield(i);
				end
			end
			return 0;
		end

		-- 辅助函数：获取区域相邻加成
		function GetDistrictBonus( district:table, yieldType:string )
			for i,yield in ipairs( kTempDistrictYields ) do
				if yield.YieldType == yieldType then
					return district:GetAdjacencyYield(i);
				end
			end
			return 0;
		end


		local districtInfo	:table	= GameInfo.Districts[district:GetType()];
		local districtType	:string = districtInfo.DistrictType;	
		local locX			:number = district:GetX();
		local locY			:number = district:GetY();
		local kPlot			:table  = Map.GetPlot(locX,locY);
		local plotID		:number = kPlot:GetIndex();	
		local districtTable :table	= { 
			SubjectType		= SubjectTypes.District,
			Name			= data.Name..": "..Locale.Lookup(districtInfo.Name),
			Plot 			= kPlot,
			Yields   		= YieldTableNew(), -- 区域产出 (主要来自相邻加成)
			DistrictType 	= districtType,
			CityCenter		= districtInfo.CityCenter,
			OnePerCity		= districtInfo.OnePerCity,
			YieldBonus	= GetDistrictYieldText( district ),
			isPillaged  = pCityDistricts:IsPillaged(district:GetType()),
			isBuilt		= district:IsComplete(),
			Icon		= "ICON_"..districtType,
			Buildings	= {},
			Tourism		= 0,
			Maintenance = districtInfo.Maintenance,
		};
		
		-- 统计所有已建成的非奇观区域和特色区域
		if district:IsComplete() and not districtInfo.CityCenter and                             districtType ~= "DISTRICT_WONDER" then
			data.NumDistricts = data.NumDistricts + 1;
		end
		if district:IsComplete() and not districtInfo.CityCenter and districtInfo.OnePerCity and districtType ~= "DISTRICT_WONDER" then
			data.NumSpecialtyDistricts = data.NumSpecialtyDistricts + 1;
		end
		
		-- 获取区域的相邻加成产出 (作为标准产出处理)
		for yield,yid in pairs(YieldTypes) do
			districtTable.Yields[ yield ] = kPlot:GetAdjacencyYield(ownerID, pCity:GetID(), district:GetType(), yid)
		end
		
		-- 检查是否有驻军 (包括军事驻地内的单位)
		if not data.IsGarrisonUnit and tGarrisonDistricts[districtInfo.DistrictType] then
			for _,unit in ipairs(Units.GetUnitsInPlot(plotID)) do
				if unit:GetCombat() > 0 then data.IsGarrisonUnit = true; break; end
			end
		end

		---------------------------------------------------------------------
		-- 处理区域内的建筑
		local buildingTypes = pCityBuildings:GetBuildingsAtLocation(plotID);
		for _, buildingType in ipairs(buildingTypes) do 
			local building		:table = GameInfo.Buildings[buildingType];
			local sBuildingType:string = building.BuildingType;

			local extyields :table = YieldTableNew();
			
			-- 辅助函数：获取建筑的基础产出数据
			-- 注意：pCity:GetBuildingYield 返回的是处理后的产出，可能会导致某些政策加成计算两次，因此这里改用从数据库获取基础数据
			function GetBuildingBaseYield(sBuildingType:string, sYieldType:string)
				for row in GameInfo.Building_YieldChanges() do
					if row.BuildingType == sBuildingType and row.YieldType == sYieldType then return row.YieldChange; end
				end
				return 0;
			end
			
			for yield,_ in pairs(YieldTypes) do extyields[ yield ] = GetBuildingBaseYield(sBuildingType, "YIELD_"..yield); end
			
			-- 将建筑按奇观和普通建筑分类记录
			if building.IsWonder then
				table.insert( data.Wonders, {
					SubjectType			= SubjectTypes.Building,
					Name				= Locale.Lookup(building.Name), 
					Yields				= extyields,
					BuildingType		= sBuildingType,
					Icon				= "ICON_"..sBuildingType,
					isPillaged			= pCityBuildings:IsPillaged(building.BuildingType),
					isBuilt				= pCityBuildings:HasBuilding(building.Index),
				});
			else
				data.BuildingsNum = data.BuildingsNum + 1;
				table.insert( districtTable.Buildings, { 
					SubjectType			= SubjectTypes.Building,
					Name				= Locale.Lookup(building.Name),
					Yields				= extyields,
					BuildingType		= sBuildingType,
					Icon				= "ICON_"..sBuildingType,
					Citizens			= kPlot:GetWorkerCount(),
					isPillaged			= pCityBuildings:IsPillaged(buildingType);
					isBuilt				= pCityBuildings:HasBuilding(building.Index);
				});
			end
		end

		-- 将区域添加到列表 (奇观区域除外)
		if districtType ~= "DISTRICT_WONDER" then
			table.insert( data.Districts, districtTable );
		end
	end

	---------------------------------------------------------------
	-- 处理贸易站
	local pTrade:table = pCity:GetTrade();
	for iPlayer:number = 0, MapConfiguration.GetMaxMajorPlayers()-1,1 do
		if (pTrade:HasActiveTradingPost(iPlayer)) then
			table.insert( data.TradingPosts, iPlayer );
		end
	end

	---------------------------------------------------------------
	-- 处理输出贸易路线
	local pPlayerDiplomaticAI:table = pPlayer:GetDiplomaticAI()
	data.OutgoingRoutes = {}
	data.NumRoutesDomestic = 0
	data.NumRoutesInternational = 0
	for _,route in ipairs(pTrade:GetOutgoingRoutes()) do
		local routeData:table = {
			SubjectType = SubjectTypes.TradeRoute,
			Name        = "", 
			IsDomestic  = (route.OriginCityPlayer == route.DestinationCityPlayer), 
			Yields      = YieldTableNew(), 
			NumImprovedResourcesAtDestination = 0, 
			IsDestinationPlayerAlly = false, 
			IsDestinationSuzerained = false, -- 是否为该城邦的宗主国
			NumSpecialtyDistricts = 0, -- 目的地特色区域数量
		}
		-- 记录贸易路线产出
		for _,yield in ipairs(route.OriginYields) do
			YieldTableSetYield(routeData.Yields, GameInfo.Yields[yield.YieldIndex].YieldType, yield.Amount)
		end
	
		-- 统计国内/国际贸易路线
		if routeData.IsDomestic then data.NumRoutesDomestic      = data.NumRoutesDomestic + 1
		else                         data.NumRoutesInternational = data.NumRoutesInternational + 1 end

		-- 查找目的地城市信息
		local pDestPlayer:table = Players[ route.DestinationCityPlayer ] 
		local pDestCity:table = pDestPlayer:GetCities():FindID(route.DestinationCityID)
		routeData.Name = data.Name.." - "..Locale.Lookup(pDestCity:GetName())

		-- 统计目的地已改良的资源 (市场经济政策相关)
		local tResources:table = GetCityResourceData(pDestCity) 
		local function CountImprovedResources(sResourceClassToCount:string)
			local iNum:number = 0
			for eResourceType,amount in pairs(tResources) do
				if GameInfo.Resources[eResourceType].ResourceClassType == sResourceClassToCount then iNum = iNum + amount end
			end
			return iNum
		end
		routeData.NumImprovedResourcesStrategic = CountImprovedResources("RESOURCECLASS_STRATEGIC")
		routeData.NumImprovedResourcesLuxury    = CountImprovedResources("RESOURCECLASS_LUXURY")
		routeData.NumImprovedResourcesBonus     = CountImprovedResources("RESOURCECLASS_BONUS")
		
		-- 检查目的地玩家是否为盟友
		routeData.IsDestinationPlayerAlly = ( pPlayerDiplomaticAI:GetDiplomaticStateIndex(route.DestinationCityPlayer) == GameInfo.DiplomaticStates.DIPLO_STATE_ALLIED.Index );
		
		-- 检查目的地是否为我方宗主的城邦
		if pDestPlayer:IsMinor() then
			routeData.IsDestinationSuzerained = ( pDestPlayer:GetInfluence():GetSuzerain() == route.OriginCityPlayer );
		end
		
		-- 统计目的地已建成的特色区域数量 (伟人效果相关)
		for _,district in pDestCity:GetDistricts():Members() do
			local districtInfo:table = GameInfo.Districts[ district:GetType() ];
			if district:IsComplete() and not districtInfo.CityCenter and districtInfo.OnePerCity and districtInfo.DistrictType ~= "DISTRICT_WONDER" then
				routeData.NumSpecialtyDistricts = routeData.NumSpecialtyDistricts + 1;
			end
		end
		
		table.insert(data.OutgoingRoutes, routeData)
	end
	data.NumRoutes = table.count(data.OutgoingRoutes)
	
	---------------------------------------------------------------
	-- 处理输入贸易路线
	data.IncomingRoutes = {}
	for _,route in ipairs(pTrade:GetIncomingRoutes()) do
		local routeData:table = {
			SubjectType = SubjectTypes.TradeRoute,
			Name        = "", 
			IsDomestic  = (route.OriginCityPlayer == route.DestinationCityPlayer), 
			Yields      = YieldTableNew(), 
			IsOriginPlayerAlly = false, 
			IsOriginSuzerained = false, 
		}
		-- 记录产出
		for _,yield in ipairs(route.DestinationYields) do
			YieldTableSetYield(routeData.Yields, GameInfo.Yields[yield.YieldIndex].YieldType, yield.Amount)
		end

		-- 查找起始城市信息
		local pOriginPlayer:table = Players[ route.OriginCityPlayer ]
		local pOriginCity:table = pOriginPlayer:GetCities():FindID(route.OriginCityID)
		routeData.Name = Locale.Lookup(pOriginCity:GetName()).." - "..data.Name 
		
		-- 检查起始玩家是否为盟友
		routeData.IsOriginPlayerAlly = ( pOriginPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(route.DestinationCityPlayer) == GameInfo.DiplomaticStates.DIPLO_STATE_ALLIED.Index );

		-- 检查起始玩家是否为我方宗主的城邦
		if pOriginPlayer:IsMinor() then
			routeData.IsOriginSuzerained = ( pOriginPlayer:GetInfluence():GetSuzerain() == route.DestinationCityPlayer );
		end

		table.insert(data.IncomingRoutes, routeData)
	end
	
	-- 返回填充完毕的数据表
	return data
end

-- ===========================================================================
-- data 表成员详尽列表 (格式: data.XXX {类型} 城市的XXX)
-- ===========================================================================
-- data.City {table} 城市对象 (pCity)
-- data.SubjectType {number} 对象类型 (城市)
-- data.Name {string} 城市名称
-- data.Yields {table} 城市产出表 (包含食物、生产力、金币、科技、文化、信仰、住房、宜居度)
-- data.ContinentType {number} 城市所在大陆的类型 ID
-- data.Districts {table} 城市已建成的区域列表
-- data.FoodSurplus {number} 城市的剩余食物 (盈余)
-- data.IsGovernorEstablished {boolean} 城市是否有总督就任
-- data.NumDistricts {number} 城市已建成的非奇观区域总数
-- data.NumSpecialtyDistricts {number} 城市已建成的特色区域数量
-- data.Population {number} 城市的人口数量
-- data.Wonders {table} 城市内的奇观列表
-- data.Plot {table} 城市中心所在的单元格对象
-- data.NumResources {number} 城市范围内改良的不同资源种类数量
-- data.IsGarrisonUnit {boolean} 城市或其军事驻地内是否有驻军
-- data.AmenitiesNetAmount {number} 城市的宜居度净值 (当前总和 - 需求)
-- data.AmenitiesNum {number} 城市的宜居度总数
-- data.AmenitiesFromLuxuries {number} 城市来自奢侈品的宜居度
-- data.AmenitiesFromEntertainment {number} 城市来自娱乐设施的宜居度
-- data.AmenitiesFromCivics {number} 城市来自市政的宜居度
-- data.AmenitiesFromGreatPeople {number} 城市来自伟人的宜居度
-- data.AmenitiesFromCityStates {number} 城市来自城邦的宜居度
-- data.AmenitiesFromReligion {number} 城市来自宗教的宜居度
-- data.AmenitiesFromNationalParks {number} 城市来自国家公园的宜居度
-- data.AmenitiesFromStartingEra {number} 城市来自初始时代的宜居度
-- data.AmenitiesFromImprovements {number} 城市来自改良设施的宜居度
-- data.AmenitiesRequiredNum {number} 城市需求的宜居度数量
-- data.AmenitiesFromGovernors {number} 城市来自总督的宜居度
-- data.BeliefsOfDominantReligion {table} 城市主流宗教的信仰列表
-- data.Buildings {table} 城市内的建筑列表
-- data.BuildingsNum {number} 城市内非奇观建筑的数量
-- data.CityWallTotalHP {number} 城市的城墙总生命值
-- data.CityWallHPPercent {number} 城市的城墙生命值百分比
-- data.CulturePerTurn {number} 城市每回合的文化产出
-- data.CurrentFoodPercent {number} 城市当前食物进度的百分比
-- data.CurrentProdPercent {number} 城市当前生产进度的百分比
-- data.CurrentProductionName {string} 城市当前生产项目的名称
-- data.CurrentProductionDescription {string} 城市当前生产项目的描述
-- data.CurrentTurnsLeft {number} 城市当前生产项目剩余的回合数
-- data.Damage {number} 城市中心受到的伤害
-- data.Defense {number} 城市的防御力 (驻防强度)
-- data.DistrictsNum {number} 城市内需要人口的区域数量
-- data.DistrictsPossibleNum {number} 城市最大允许建设的区域数量
-- data.FaithPerTurn {number} 城市每回合的信仰产出
-- data.FoodPercentNextTurn {number} 城市下回合的食物进度百分比
-- data.FoodPerTurn {number} 城市每回合的食物总产出
-- data.GoldPerTurn {number} 城市每回合的金币产出
-- data.GrowthPercent {number} 城市的增长速率修正百分比
-- data.Happiness {number} 城市的幸福度等级 ID
-- data.HappinessGrowthModifier {number} 幸福度对城市增长的修正倍率
-- data.HappinessNonFoodYieldModifier {number} 幸福度对非食物产出的修正倍率
-- data.Housing {number} 城市的总住房数量
-- data.HousingMultiplier {number} 住房对城市增长的修正倍率
-- data.IsCapital {boolean} 该城市是否为玩家的首都
-- data.IsUnderSiege {boolean} 城市当前是否处于被围攻状态
-- data.OccupationMultiplier {number} 占领状态对城市增长的修正倍率
-- data.OwnerID {number} 城市所有者的玩家 ID
-- data.OtherGrowthModifiers {number} 城市的其他增长修正 (如来自宗教或奇观)
-- data.PantheonBelief {number} 玩家万神殿信仰的 ID
-- data.ProdPercentNextTurn {number} 城市下回合的生产进度百分比
-- data.ProductionPerTurn {number} 城市每回合的生产力产出
-- data.ProductionQueue {table} 城市的生产队列信息
-- data.Religions {table} 城市内的宗教分布列表
-- data.ReligionFollowers {number} 城市内的宗教信徒总数
-- data.SciencePerTurn {number} 城市每回合的科技产出
-- data.TradingPosts {table} 在该城市拥有贸易站的玩家 ID 列表
-- data.TurnsUntilGrowth {number} 距离人口增长的回合数 (负数表示处于饥饿状态)
-- data.TurnsUntilExpansion {number} 距离领土扩张的回合数
-- data.UnitStats {table} 正在生产的单位属性 (当前实现中为 nil)
-- data.NumGovernorPromotions {number} 城市就任总督的强化次数
-- data.GreatWorks {table} 城市内的杰作列表
-- data.CurrentProductionType {string} 当前生产类型 ("BUILDING", "DISTRICT", "UNIT", "PROJECT", "NONE")
-- data.MajorityReligionFollowers {number} 城市主流宗教的信徒数量
-- data.AmenityAdvice {string} 城市的宜居度建议文本
-- data.CityWallCurrentHP {number} 城市的城墙当前生命值
-- data.HitpointPercent {number} 城市中心地块的生命值百分比
-- data.HitpointsCurrent {number} 城市中心地块的当前生命值
-- data.HitpointsTotal {number} 城市中心地块的总生命值
-- data.HousingFromWater {number} 城市来自水源的住房数量
-- data.HousingFromBuildings {number} 城市来自建筑的住房数量
-- data.HousingFromImprovements {number} 城市来自改良设施的住房数量
-- data.HousingFromDistricts {number} 城市来自区域的住房数量
-- data.HousingFromCivics {number} 城市来自市政的住房数量
-- data.HousingFromGreatPeople {number} 城市来自伟人的住房数量
-- data.HousingFromStartingEra {number} 城市来自初始时代的住房数量
-- data.HousingAdvice {string} 城市的住房建议文本
-- data.Occupied {boolean} 城市是否正处于被占领状态
-- data.OutgoingRoutes {table} 城市发出的输出贸易路线列表
-- data.NumRoutesDomestic {number} 城市发出的国内贸易路线数量
-- data.NumRoutesInternational {number} 城市发出的国际贸易路线数量
-- data.NumRoutes {number} 城市发出的贸易路线总数
-- data.IncomingRoutes {table} 到达该城市的输入贸易路线列表
