--这个文件定义了以下表，在-1加载，很早加载：
-- Ruivo_ProvideType_YieldType 用于定义提供类型和产出类型，也就是支持什么样的加成和产出
-- Ruivo_AdjacencyType 用于定义相邻加成类型 from 哪些相邻对象

-- Ruivo_Terrain_Function 用于定义地形函数类型，是给 FROM_RINGS_CAO_TERRAIN_SETS 的 CustomAdjacentObject

-- Ruivo_New_Adjacency_Text 自定义tootip表，方便大伙直接改原文，包含了四个格式化参数
-- Ruivo_CAO 自定义相邻对象的名称表，通常用于诸如FROM_RINGS_TYPETAG_RESOURCE这样的自定义相邻对象，当然完全可以用于 from property 系列的相邻来源
-- Ruivo_Yield_IconString 产出图标、名称、颜色表，用于在tooltip中显示产出图标及其名称，以及区域下标的字体颜色
-- Ruivo_New_Adjacency_ProvideType 自定义提供类型表，用于定义相邻加成的提供类型，也就是支持什么样的加成和产出
-- 因为通常的格式是：+1 [图标][某个产出] 来自相邻范围内的 n 个 [某个对象] (某个特质/某个建筑/某个政策卡...) (来自n环内)
-- 通过上述三个表，你可以做到修改图标、相邻对象，或是整句话


--============================================================================================================================
--全局参数，判断开没开马良相邻
    INSERT OR IGNORE INTO GlobalParameters (Name, Value) VALUES 
    ('RUIVO_MODULAR_ADJACENCY_BONUS_ABLED', '1');
--============================================================================================================================


--============================================================================================================================
--提供类型-产出类型-表
--这个表只是单纯给大伙看的，虽然也确实能用于select遍历，但实际上lua代码没有用到这个
    CREATE TABLE Ruivo_ProvideType_YieldType (
        ProvideType TEXT NOT NULL, 
        YieldType TEXT NOT NULL,
        Tooltip TEXT DEFAULT NULL,
        PRIMARY KEY (ProvideType, YieldType)
    );

    --基本加成组
    --SelfBonus 和 SelfMultiplier 的常规产出类型
    --一个是给区域自身基础产出，一个是给区域产出系数（百分比）
    INSERT INTO Ruivo_ProvideType_YieldType (ProvideType, YieldType, Tooltip) VALUES
        ('SelfBonus', 'YIELD_FOOD',         '区域给自己加6大产出'),
        ('SelfBonus', 'YIELD_PRODUCTION',   '区域给自己加6大产出'),
        ('SelfBonus', 'YIELD_GOLD',         '区域给自己加6大产出'),
        ('SelfBonus', 'YIELD_SCIENCE',      '区域给自己加6大产出'),
        ('SelfBonus', 'YIELD_CULTURE',      '区域给自己加6大产出'),
        ('SelfBonus', 'YIELD_FAITH',        '区域给自己加6大产出'),
        
        ('SelfMultiplier', 'YIELD_FOOD',        '区域给自己加产出6大产出系数（百分比）'),
        ('SelfMultiplier', 'YIELD_PRODUCTION',  '区域给自己加产出6大产出系数（百分比）'),
        ('SelfMultiplier', 'YIELD_GOLD',        '区域给自己加产出6大产出系数（百分比）'),
        ('SelfMultiplier', 'YIELD_SCIENCE',     '区域给自己加产出6大产出系数（百分比）'),
        ('SelfMultiplier', 'YIELD_CULTURE',     '区域给自己加产出6大产出系数（百分比）'),
        ('SelfMultiplier', 'YIELD_FAITH',       '区域给自己加产出6大产出系数（百分比）');

    --广义加成组
    INSERT INTO Ruivo_ProvideType_YieldType (ProvideType, YieldType, Tooltip) VALUES
        ("SelfAirSlots",          "YIELD_AIR_SLOTS",            "为区域所在城市提供空军槽位"),
        ("SelfHousing",           "YIELD_HOUSING",              "为区域所在城市提供住房"),
        ("SelfAmenity",           "YIELD_AMENITY",              "为区域所在城市提供宜居度"),
        ("SelfExtraDistrictSlot", "YIELD_DISTRICT_SLOT",        "为区域所在城市提供额外的区域位"),
        ("SelfLoyalty",           "YIELD_LOYALTY",              "为区域所在城市提供忠诚度"),
        ("SelfPower",             "YIELD_POWER",                "为区域所在城市提供清洁电力"),
        ("SelfPowerModifier",     "YIELD_POWER",                "为区域所在城市提供清洁电力系数（百分比）"),
        ("SelfCityGrowth",        "YIELD_CITY_GROWTH",          "为区域所在城市提供城市发展速度/余粮系数（百分比）"),

        ("SelfTourism",           "YIELD_TOURISM",              "为玩家提供旅游业绩"),
        ("SelfInfluence",         "YIELD_INFLUENCE",            "为玩家提供影响力"),
        ("SelfFavor",             "YIELD_FAVOR",                "为玩家提供外交支持点数"),
        ("SelfTradeRoute",        "YIELD_TRADE_ROUTE",          "为玩家提供贸易路线容量"),
        ("SelfCivicBoost",        "YIELD_CIVIC_BOOST",          "为玩家提供鼓舞提升（百分比）"),
        ("SelfTechnologyBoost",   "YIELD_TECHNOLOGY_BOOST",     "为玩家提供尤里卡提升（百分比）");

    --伟人点数系列，一个是伟人点数，一个是伟人点数系数，但是都是给玩家的
    --填伟人类型即可，比如大预言家点数： GREAT_PERSON_CLASS_PROPHET 
    INSERT INTO Ruivo_ProvideType_YieldType (ProvideType, YieldType, Tooltip)
    SELECT 'GreatPersonPoints', GreatPersonClassType, '为玩家提供伟人点数' FROM GreatPersonClasses
    UNION ALL
    SELECT 'GreatPersonMultiplier', GreatPersonClassType, '为玩家提供伟人点数系数（百分比）' FROM GreatPersonClasses;

    --战略资源每回合产出，可以填例如铁： RESOURCE_IRON
    INSERT INTO Ruivo_ProvideType_YieldType (ProvideType, YieldType, Tooltip)
    SELECT 'SelfExtractResource', ResourceType, '为玩家提供战略资源每回合产出' FROM Resources WHERE ResourceClassType = 'RESOURCECLASS_STRATEGIC';

    --Property系列--只是告诉你有这个ProvideType，你想填啥就填啥，这里是keyName
    INSERT INTO Ruivo_ProvideType_YieldType (ProvideType, YieldType, Tooltip) VALUES
        ('SelfDistrictProperty',    'Ruivo_MAB_Test_Key_Name_For_District', '为区域设置自定义属性值 (Property)'),
        ('SelfCityProperty',        'Ruivo_MAB_Test_Key_Name_For_City',     '为城市设置自定义属性值 (Property)'),
        ('SelfPlayerProperty',      'Ruivo_MAB_Test_Key_Name_For_Player',   '为玩家设置自定义属性值 (Property)'),
        ('SelfGameProperty',        'Ruivo_MAB_Test_Key_Name_For_Game',     '为游戏设置自定义属性值 (Property)');

    --城市单元格魅力，这个是通过填写Ruivo_New_Adjacency_ProvideType表实现的，但是我们仍然在此列出
    INSERT INTO Ruivo_ProvideType_YieldType (ProvideType, YieldType, Tooltip) VALUES
        ('SelfCityAppeal', 'YIELD_CITY_APPEAL', '为城市单元格提供魅力加成');
--============================================================================================================================


--============================================================================================================================
--相邻类型表--层级为：单元格、区域、城市、玩家、全局
--有些相邻本就可以互相实现，写都写了，喜欢哪个用哪个呗
    CREATE TABLE Ruivo_AdjacencyType (
        --相邻类型
        AdjacencyType TEXT PRIMARY KEY NOT NULL,
        --属性来源类型
        AttributeType TEXT NOT NULL,
        --是否存在指定相邻对象
        HasCustomAdjacentObject BOOLEAN NOT NULL CHECK (HasCustomAdjacentObject IN (0, 1)),
        --游戏环境
        Environment TEXT NOT NULL CHECK (Environment IN ("GamePlay", "UserInterface")),
        --能否显示，注意，这个参数被废弃了，不要使用这个参数
        CanDisplay BOOLEAN NOT NULL CHECK (CanDisplay IN (0, 1)),
        --不在进行规划时显示此加成（这个是针对单元格plot级别的，其他的本身就没打算显示在规划阶段）
        DoNotDisplayWhenPlacement BOOLEAN NOT NULL CHECK (DoNotDisplayWhenPlacement IN (0, 1)) DEFAULT 0, 
        --注意，这并不是相邻显示文本，只是介绍而已，不要去使用这个参数
        Tooltip TEXT NOT NULL,
        --放置时显示的边缘图标（Overlay.artdef 条目名称；NULL 表示无图标）
        ArtdefOverlayEntry TEXT DEFAULT NULL
    );
    INSERT INTO Ruivo_AdjacencyType 
    (AdjacencyType, AttributeType, HasCustomAdjacentObject, Environment, CanDisplay, Tooltip) VALUES

    --property体系！！！
    ('FROM_PLOT_PROPERTY',                  'Plot', 1, 'GamePlay', 1, '单元格property（通常来自lua）'),
    ('FROM_PLOT_PROPERTY_HASHED',           'Plot', 1, 'GamePlay', 1, '哈希化的单元格property（通常来自modifier）'),
    ('FROM_RINGS_PLOT_PROPERTY',            'Plot', 1, 'GamePlay', 1, '环数内的单元格property（通常来自lua）'),
    ('FROM_RINGS_PLOT_PROPERTY_HASHED',     'Plot', 1, 'GamePlay', 1, '哈希化的环数内的单元格property（通常来自modifier）'),
    --我操你妈了个逼的Firaxis，District:GetProperty()仅限GamePlayScript
    --('FROM_DISTRICT_PROPERTY',             'District', 1, 'GamePlay', 0, '区域property（通常来自lua）'),
    --('FROM_DISTRICT_PROPERTY_HASHED',      'District', 1, 'GamePlay', 0, '哈希化的区域property（通常来自modifier）'),
    --('FROM_RINGS_DISTRICT_PROPERTY',       'District', 1, 'GamePlay', 0, '环数内的区域property（通常来自lua）'),
    --('FROM_RINGS_DISTRICT_PROPERTY_HASHED','District', 1, 'GamePlay', 0, '哈希化的环数内的区域property（通常来自modifier）'),
    ('FROM_CITY_PROPERTY',                  'City', 1, 'GamePlay', 1, '城市property（通常来自lua）'),
    ('FROM_CITY_PROPERTY_HASHED',           'City', 1, 'GamePlay', 1, '哈希化的城市property（通常来自modifier）'),
    ('FROM_PLAYER_PROPERTY',              'Player', 1, 'GamePlay', 1, '玩家property（通常来自lua）'),
    ('FROM_PLAYER_PROPERTY_HASHED',       'Player', 1, 'GamePlay', 1, '哈希化的玩家property（通常来自modifier）'),
    ('FROM_GAME_PROPERTY',                  'Game', 1, 'GamePlay', 1, '游戏property（通常来自lua）'),
    ('FROM_GAME_PROPERTY_HASHED',           'Game', 1, 'GamePlay', 1, '哈希化的游戏property（通常来自modifier）'),

    --全局属性--GP环境
    ('FROM_UNCONDITIONAL_BONUS',            'Game', 0, 'GamePlay', 1, '无条件加成'),
    ('FROM_STORM_HAPPEND',                  'Game', 0, 'GamePlay', 1, '本局风暴发生次数'),
    ('FROM_STANDARDIZE_TURNS',              'Game', 0, 'GamePlay', 1, '标准化回合数（当前回合/速度系数）'),
    --全局属性--GP环境--有自定义相邻对象
    ('FROM_HIGHEST_HUMAN_YIELD',            'Game', 1, 'GamePlay', 1, '指定产出类型的最高人类玩家产出值，可填6种基本产出'),
    --全局属性--UI环境
    ('FROM_UI_SEA_LEVEL',                   'Game', 0, 'UserInterface', 1, '本局游戏的气候变化点数'),
    --UI环境--有自定义相邻对象
    --暂无

    --单元格属性--GP环境--本格属性
    ('FROM_LAND_WATER_PAIR',                'Plot', 0, 'GamePlay', 1, '相邻每对水陆地势（最高3对）'),
    ('FROM_RIVER_CROSSING',                 'Plot', 0, 'GamePlay', 1, '相邻河流每个面'),
    ('FROM_SELF_ROUTE',                     'Plot', 0, 'GamePlay', 1, '本格道路等级'),
    ('FROM_SELF_WORKER',                    'Plot', 0, 'GamePlay', 1, '本区域内在岗公民'),
    ('FROM_CLIFF',                          'Plot', 0, 'GamePlay', 1, '单元格有无悬崖'),
    ('FROM_LATITUDE',                       'Plot', 0, 'GamePlay', 1, '从宇航标准线到赤道距离的百分比'),
    ('FROM_POLE',                           'Plot', 0, 'GamePlay', 1, '从宇航标准线到极地距离的百分比'),
    ('FROM_SELF_WATER_LEVEL',               'Plot', 0, 'GamePlay', 1, '本格淡水等级（无水0，咸水1，淡水3）'),
    --单元格属性--GP环境--相邻格属性
    ('FROM_ADJACENT_ROUTE',                 'Plot', 0, 'GamePlay', 1, '相邻每个等级的道路'),
    ('FROM_ADJACENT_WORKER',                'Plot', 0, 'GamePlay', 1, '相邻在岗公民'),
    ('FROM_ADJACENT_UNIT',                  'Plot', 0, 'GamePlay', 1, '相邻单位'),
    ('FROM_ADJACENT_DISTRICT',              'Plot', 0, 'GamePlay', 1, '相邻区域'),
    ('FROM_ADJACENT_DISTRICT_AND_WONDER',   'Plot', 0, 'GamePlay', 1, '相邻区域和人造奇观（即使未建成）'),
    ('FROM_ADJACENT_LAKE',                  'Plot', 0, 'GamePlay', 1, '相邻淡水湖数量'),
    ('FROM_ADJACENT_WATER_LEVEL',           'Plot', 0, 'GamePlay', 1, '相邻淡水等级（无水0，咸水1，淡水3）'),
    ('FROM_ADJACENT_RESOURCE',              'Plot', 0, 'GamePlay', 1, '相邻资源数量（即使不可见）'),
    ('FROM_ADJACENT_WONDERS',               'Plot', 0, 'GamePlay', 1, '相邻已完工的人造奇观数量'),
    --单元格属性--GP环境--允许多环
    ('FROM_RINGS_ROUTE',                    'Plot', 0, 'GamePlay', 1, '环数内的道路等级总和'),
    ('FROM_RINGS_WORKER',                   'Plot', 0, 'GamePlay', 1, '环数内的在岗公民总和'),
    ('FROM_RINGS_UNIT',                     'Plot', 0, 'GamePlay', 1, '环数内的单位数量'),
    ('FROM_RINGS_DISTRICT_AND_WONDER',      'Plot', 0, 'GamePlay', 1, '环数内的区域和奇观数量'),
    ('FROM_RINGS_DISTRICT',                 'Plot', 0, 'GamePlay', 1, '环数内的区域数量（不含奇观）'),
    ('FROM_RINGS_LAKE',                     'Plot', 0, 'GamePlay', 1, '环数内的淡水湖数量'),
    ('FROM_RINGS_WATER_LEVEL',              'Plot', 0, 'GamePlay', 1, '环数内的淡水等级总和（无水0，咸水1，淡水3）'),
    ('FROM_RINGS_RESOURCE',                 'Plot', 0, 'GamePlay', 1, '环数内的资源数量'),
    ('FROM_RINGS_WONDERS',                  'Plot', 0, 'GamePlay', 1, '环数内的奇观数量（已建成）'),
    ('FROM_RINGS_NATIONALPARK',             'Plot', 0, 'GamePlay', 1, '环数内的国家公园'),
    --单元格属性--GP环境--允许多环--有自定义相邻对象
    ('FROM_RINGS_CAO_ROUTE',                'Plot', 1, 'GamePlay', 1, '环数内的指定道路类型'),
    ('FROM_RINGS_CAO_UNIT',                 'Plot', 1, 'GamePlay', 1, '环数内的指定单位类型'),
    ('FROM_RINGS_CAO_RESOURCE_CLASS',       'Plot', 1, 'GamePlay', 1, '环数内的指定资源类对应的资源'),
    ('FROM_RINGS_TYPETAG_RESOURCE',         'Plot', 1, 'GamePlay', 1, '环数内的指定tag对应的资源'),
    ('FROM_RINGS_CAO_RESOURCE',             'Plot', 1, 'GamePlay', 1, '环数内的指定资源'),
    ('FROM_RINGS_CAO_IMPROVEMENT',          'Plot', 1, 'GamePlay', 1, '环数内的指定改良'),
    ('FROM_RINGS_CAO_DISTRICT',             'Plot', 1, 'GamePlay', 1, '环数内的指定区域'),
    ('FROM_RINGS_TYPETAG_DISTRICT',         'Plot', 1, 'GamePlay', 1, '环数内的指定tag对应的区域'),
    ('FROM_RINGS_CAO_FEATURE',              'Plot', 1, 'GamePlay', 1, '环数内的指定地貌'),
    ('FROM_RINGS_CAO_TERRAIN_SETS',         'Plot', 1, 'GamePlay', 1, '环数内的指定函数地形（注：这个的CAO是地形判断函数）'),
    ('FROM_RINGS_CAO_TERRAIN',              'Plot', 1, 'GamePlay', 1, '环数内的指定地形（这个可以正常填地形）'),
    --单元格属性--UI环境--本格属性
    ('FROM_UI_SELF_UNIT_LEVELS',            'Plot', 0, 'UserInterface', 1, '本格的单位等级总和'),
    ('FROM_UI_SELF_APPEAL',                 'Plot', 0, 'UserInterface', 1, '本单元格的魅力'),
    --单元格属性--UI环境--相邻格属性
    ('FROM_UI_ADJACENT_UNIT_LEVELS',        'Plot', 0, 'UserInterface', 1, '相邻的单位等级总和'),
    ('FROM_UI_ADJACENT_APPEAL',             'Plot', 0, 'UserInterface', 1, '相邻单元格的魅力'),
    ('FROM_UI_ADJACENT_YIELD_FOOD',         'Plot', 0, 'UserInterface', 1, '相邻单元格的食物'),
    ('FROM_UI_ADJACENT_YIELD_PRODUCTION',   'Plot', 0, 'UserInterface', 1, '相邻单元格的生产力'),
    ('FROM_UI_ADJACENT_YIELD_GOLD',         'Plot', 0, 'UserInterface', 1, '相邻单元格的金币'),
    ('FROM_UI_ADJACENT_YIELD_SCIENCE',      'Plot', 0, 'UserInterface', 1, '相邻单元格的科技'),
    ('FROM_UI_ADJACENT_YIELD_CULTURE',      'Plot', 0, 'UserInterface', 1, '相邻单元格的文化'),
    ('FROM_UI_ADJACENT_YIELD_FAITH',        'Plot', 0, 'UserInterface', 1, '相邻单元格的信仰'),
    --单元格属性--UI环境--允许多环
    ('FROM_UI_RINGS_UNIT_LEVELS',           'Plot', 0, 'UserInterface', 1, '环数内的单位等级总和'),
    ('FROM_UI_RINGS_APPEAL',                'Plot', 0, 'UserInterface', 1, '环数内的魅力'),
    --单元格属性--UI环境--允许多环--有自定义相邻对象
    ('FROM_UI_RINGS_CAO_YIELD',             'Plot', 1, 'UserInterface', 1, '环数内的指定产出'),

    --区域属性--GP环境
    ('FROM_SELF_YIELD_FOOD',                'District', 0, 'GamePlay', 1, '区域自身粮食'),
    ('FROM_SELF_YIELD_PRODUCTION',          'District', 0, 'GamePlay', 1, '区域自身生产力'),
    ('FROM_SELF_YIELD_GOLD',                'District', 0, 'GamePlay', 1, '区域自身金币'),
    ('FROM_SELF_YIELD_SCIENCE',             'District', 0, 'GamePlay', 1, '区域自身科技'),
    ('FROM_SELF_YIELD_CULTURE',             'District', 0, 'GamePlay', 1, '区域自身文化'),
    ('FROM_SELF_YIELD_FAITH',               'District', 0, 'GamePlay', 1, '区域自身信仰'),
    ('FROM_SELF_DISTRICT_MAX_HP',           'District', 0, 'GamePlay', 1, '区域血量上限'),
    ('FROM_SELF_DISTRICT_DAMAGE',           'District', 0, 'GamePlay', 1, '区域受到的伤害'),
    ('FROM_SELF_DISTRICT_REMAIN_HP',        'District', 0, 'GamePlay', 1, '区域剩余血量'),
    ('FROM_SELF_WALL_MAX_HP',               'District', 0, 'GamePlay', 1, '城墙血量上限'),
    ('FROM_SELF_WALL_DAMAGE',               'District', 0, 'GamePlay', 1, '城墙受到的伤害'),
    ('FROM_SELF_WALL_REMAIN_HP',            'District', 0, 'GamePlay', 1, '城墙剩余血量'),
    ('FROM_SELF_DISTRICT_DAMAGE_PERCENT',   'District', 0, 'GamePlay', 1, '区域受损百分比'),
    ('FROM_SELF_DISTRICT_REMAIN_HP_PERCENT','District', 0, 'GamePlay', 1, '区域剩余生命百分比'),
    ('FROM_SELF_WALL_DAMAGE_PERCENT',       'District', 0, 'GamePlay', 1, '城墙受损百分比'),
    ('FROM_SELF_WALL_REMAIN_HP_PERCENT',    'District', 0, 'GamePlay', 1, '城墙剩余生命百分比'),
    ('FROM_SELF_DEFENSE_STRENGTH',          'District', 0, 'GamePlay', 1, '区域驻军防御力'),
    --区域属性--GP环境--允许多环
    ('FROM_RINGS_DISTRICT_MAX_HP',          'District', 0, 'GamePlay', 1, '环数内区域血量上限'),
    ('FROM_RINGS_DISTRICT_DAMAGE',          'District', 0, 'GamePlay', 1, '环数内区域受到的伤害'),
    ('FROM_RINGS_DISTRICT_REMAIN_HP',       'District', 0, 'GamePlay', 1, '环数内区域剩余血量'),
    ('FROM_RINGS_WALL_MAX_HP',              'District', 0, 'GamePlay', 1, '环数内区域城墙血量上限'),
    ('FROM_RINGS_WALL_DAMAGE',              'District', 0, 'GamePlay', 1, '环数内区域城墙受到的伤害'),
    ('FROM_RINGS_WALL_REMAIN_HP',           'District', 0, 'GamePlay', 1, '环数内区域城墙剩余血量'),
    ('FROM_RINGS_DEFENSE_STRENGTH',         'District', 0, 'GamePlay', 1, '环数内区域驻军防御力'),
    --区域属性--GP环境--允许多环--有自定义相邻对象
    ('FROM_RINGS_DISTRICTS_CAO_YIELD',      'District', 1, 'GamePlay', 1, '环数内区域的指定产出'),
    --区域属性--UI环境
    ('FROM_UI_SELF_AIR_SLOTS',              'District', 0, 'UserInterface', 1, '区域空军槽位'),
    ('FROM_UI_SELF_AIR_UNITS',              'District', 0, 'UserInterface', 1, '区域空军单位数量'),
    ('FROM_UI_SELF_SURPLUS_AIR_SLOTS',      'District', 0, 'UserInterface', 1, '区域剩余空军槽位'),
    --区域属性--UI环境--允许多环
    ('FROM_UI_RINGS_AIR_SLOTS',             'District', 0, 'UserInterface', 1, '环数内区域空军槽位'),
    ('FROM_UI_RINGS_AIR_UNITS',             'District', 0, 'UserInterface', 1, '环数内区域空军单位数量'),
    ('FROM_UI_RINGS_SURPLUS_AIR_SLOTS',     'District', 0, 'UserInterface', 1, '环数内区域剩余空军槽位'),
    --区域属性--UI环境--允许多环--有自定义相邻对象
    --暂无

    --城市属性--GP环境
    ('FROM_CITY_POPULATION',                'City', 0, 'GamePlay', 1, '城市人口总数'),
    ('FROM_CITY_TOTAL_HOUSING',             'City', 0, 'GamePlay', 1, '城市住房总数'),
    ('FROM_CITY_SURPLUS_HOUSING',           'City', 0, 'GamePlay', 1, '城市剩余住房数'),
    ('FROM_CITY_DISTRICTS_NUM',             'City', 0, 'GamePlay', 1, '城市区域总数（不包括市中心和奇观）'),
    ('FROM_CITY_SURPLUS_FOOD',              'City', 0, 'GamePlay', 1, '城市余粮数量'),
    ('FROM_CITY_SURPLUS_AMENITIES',         'City', 0, 'GamePlay', 1, '城市溢出宜居度'),
    ('FROM_CITY_SURPLUS_AMENITIES_OVER_HIGHEST_LEVEL_HAPPINESS','City', 0, 'GamePlay', 1, '城市超过顶级幸福度部分的宜居度'),
    ('FROM_CITY_DEFENSE_STRENGTH',          'City', 0, 'GamePlay', 1, '城市防御力'),
    --城市属性--GP环境--自定义相邻对象
    ('FROM_CITY_CAO_YIELD',                 'City', 1, 'GamePlay', 1, '城市对应产出，可填6种基本产出'),
    --城市属性--UI环境
    ('FROM_UI_CITY_DISTRICT_SLOT',          'City', 0, 'UserInterface', 1, '城市区域位'),
    ('FROM_UI_CITY_SURPLUS_DISTRICT_SLOT',  'City', 0, 'UserInterface', 1, '城市剩余区域位'),
    ('FROM_UI_CITY_FREE_POWER',             'City', 0, 'UserInterface', 1, '城市清洁电力'),
    ('FROM_UI_CITY_TEMPORARY_POWER',        'City', 0, 'UserInterface', 1, '城市临时电力'),
    ('FROM_UI_CITY_REQUIRED_POWER',         'City', 0, 'UserInterface', 1, '城市需求电力'),
    ('FROM_UI_CITY_CURRENT_POWER',          'City', 0, 'UserInterface', 1, '城市总电力'),
    ('FROM_UI_CITY_SURPLUS_POWER',          'City', 0, 'UserInterface', 1, '城市溢出电力'),
    ('FROM_UI_CITY_POWER_RATIO',            'City', 0, 'UserInterface', 1, '城市供电率'),
    ('FROM_UI_CITY_LOYALTY_PERTURN',        'City', 0, 'UserInterface', 1, '城市忠诚度'),
    ('FROM_UI_CITY_LOYALTY_PERCENT',        'City', 0, 'UserInterface', 1, '城市忠诚率'),
    ('FROM_UI_CITY_INCOMING_ROUTES',        'City', 0, 'UserInterface', 1, '城市输入贸易路线数量'),
    ('FROM_UI_CITY_OUTGOING_ROUTES',        'City', 0, 'UserInterface', 1, '城市输出贸易路线数量'),
    --城市属性--UI环境--有自定义相邻对象
    --暂无
    
    --玩家属性--GP环境
    ('FROM_PLAYER_TECHS_NUM',               'Player', 0, 'GamePlay', 1, '玩家科技种类（不包括循环科技）'),
    ('FROM_PLAYER_CIVICS_NUM',              'Player', 0, 'GamePlay', 1, '玩家市政种类（不包括循环市政）'),
    ('FROM_OUTGOING_ROUTES',                'Player', 0, 'GamePlay', 1, '玩家经营的商路数量'),
    ('FROM_SLOT_MILITARY',                  'Player', 0, 'GamePlay', 1, '玩家军事卡数量'),
    ('FROM_SLOT_ECONOMIC',                  'Player', 0, 'GamePlay', 1, '玩家经济卡数量'),
    ('FROM_SLOT_DIPLOMATIC',                'Player', 0, 'GamePlay', 1, '玩家外交卡数量'),
    ('FROM_SLOT_GREAT_PERSON',              'Player', 0, 'GamePlay', 1, '玩家伟人卡数量'),
    ('FROM_SLOT_WILDCARD',                  'Player', 0, 'GamePlay', 1, '玩家通配卡数量'),
    ('FROM_PLAYER_TOTAL_UNITS',             'Player', 0, 'GamePlay', 1, '玩家总单位数量'),
    ('FROM_PLAYER_RESOURCES_TYPES',         'Player', 0, 'GamePlay', 1, '玩家持有资源类型总数'),
    --玩家属性--GP环境--自定义相邻对象
    ('FROM_CAO_IMPROVEMENT_RESOURCE_TYPES', 'Player', 1, 'GamePlay', 1, '玩家持有资源类型总数（对应改良的）'),
    ('FROM_PLAYER_CAO_YIELD',               'Player', 1, 'GamePlay', 1, '玩家指定某种总产出'),
    --玩家属性--UI环境
    ('FROM_UI_MILITARY_STRENGTH',           'Player', 0, 'UserInterface', 1, '玩家总军事战力'),
    --玩家属性--UI环境--有自定义相邻对象
    --暂无
    
    --不可显示的属性
    --宗教属性
    ('FROM_RELIGION_FAITH_YIELD',               'Religion', 0, 'GamePlay', 0, '总信仰产出'),
    ('FROM_RELIGION_BELIEFS_COUNT',             'Religion', 0, 'GamePlay', 0, '信条数量'),
    ('FROM_RELIGION_TOTAL_FOLLOWERS',           'Religion', 0, 'GamePlay', 0, '总信徒数量'),
    ('FROM_RELIGION_FOREIGN_FOLLOWERS',         'Religion', 0, 'GamePlay', 0, '国外信徒数量'),
    ('FROM_RELIGION_DOMESTIC_FOLLOWERS',        'Religion', 0, 'GamePlay', 0, '国内信徒数量'),
    ('FROM_RELIGION_TOTAL_CITIES_FOLLOWING',    'Religion', 0, 'GamePlay', 0, '总信仰城市数量'),
    ('FROM_RELIGION_CITIES_WITH_WONDER',        'Religion', 0, 'GamePlay', 0, '总信仰城市数量（拥有人造奇观）'),
    ('FROM_RELIGION_FOREIGN_CITIES',            'Religion', 0, 'GamePlay', 0, '国外信仰城市数量'),
    ('FROM_RELIGION_DOMESTIC_CITIES',           'Religion', 0, 'GamePlay', 0, '国内信仰城市数量'),
    ('FROM_RELIGION_CITY_PLAYER_FOLLOWERS',     'Religion', 0, 'GamePlay', 0, '本城的信仰玩家宗教信徒数量（即使不是本城主流宗教）')
    ;

--对在岗公民系的单元格级别相邻加成不在规划阶段显示，因为这个太过经常变动了，只在建成后显示就行了
UPDATE Ruivo_AdjacencyType SET DoNotDisplayWhenPlacement = 1 WHERE AdjacencyType = 'FROM_SELF_WORKER';
UPDATE Ruivo_AdjacencyType SET DoNotDisplayWhenPlacement = 1 WHERE AdjacencyType = 'FROM_ADJACENT_WORKER';
UPDATE Ruivo_AdjacencyType SET DoNotDisplayWhenPlacement = 1 WHERE AdjacencyType = 'FROM_RINGS_WORKER';

-- Tile-edge overlay icons for non-CAO adjacency types (parallel to Ruivo_CAO.ArtdefOverlayEntry)
    UPDATE Ruivo_AdjacencyType SET ArtdefOverlayEntry = 'Terrain_River'              WHERE AdjacencyType = 'FROM_RIVER_CROSSING';
    UPDATE Ruivo_AdjacencyType SET ArtdefOverlayEntry = 'Terrain_Generic_Resource'   WHERE AdjacencyType IN ('FROM_ADJACENT_RESOURCE', 'FROM_RINGS_RESOURCE');
    UPDATE Ruivo_AdjacencyType SET ArtdefOverlayEntry = 'Terrain_Coast'              WHERE AdjacencyType IN ('FROM_ADJACENT_LAKE', 'FROM_RINGS_LAKE');
    UPDATE Ruivo_AdjacencyType SET ArtdefOverlayEntry = 'Generic_Wonder'             WHERE AdjacencyType IN ('FROM_ADJACENT_WONDERS', 'FROM_RINGS_WONDERS');
    UPDATE Ruivo_AdjacencyType SET ArtdefOverlayEntry = 'Districts_Generic_District' WHERE AdjacencyType IN ('FROM_ADJACENT_DISTRICT', 'FROM_RINGS_DISTRICT', 'FROM_ADJACENT_DISTRICT_AND_WONDER', 'FROM_RINGS_DISTRICT_AND_WONDER');
--============================================================================================================================


--============================================================================================================================
--发起者类型表
    CREATE TABLE Ruivo_ModifierOwner_CollectionType (
        ModifierOwner TEXT, 
        WhoIsTheOwner TEXT,
        CollectionType TEXT,
        Tooltip TEXT,
        PRIMARY KEY (ModifierOwner, CollectionType)
    );
    INSERT INTO Ruivo_ModifierOwner_CollectionType 
        ( ModifierOwner,                 WhoIsTheOwner,          CollectionType,                 Tooltip) VALUES
        ('DistrictModifiers',           'NULL',                 'COLLECTION_PLAYER_DISTRICTS',  '区域作为发起者，这个不需要填后面两个参数，直接用默认值即可'),
        ('TraitModifiers',              'TraitType',            'COLLECTION_PLAYER_DISTRICTS',  '玩家特质作用于玩家全部区域，请去 Traits 表里找'),
        ('BuildingModifiers',           'BuildingType',         'COLLECTION_CITY_DISTRICTS',    '建筑作用于所属城市的区域，请去 Buildings 表里找'),
        ('BuildingModifiers',           'BuildingType',         'COLLECTION_PLAYER_DISTRICTS',  '建筑作用于玩家全部区域，通常可能会用在奇观上，建筑参数同样请去 Buildings 表里找'),
        ('PolicyModifiers',             'PolicyType',           'COLLECTION_PLAYER_DISTRICTS',  '政策卡作用于玩家全部区域，请去 Policies 表里找'),
        ('TechnologyModifiers',         'TechnologyType',       'COLLECTION_PLAYER_DISTRICTS',  '科技作用于玩家全部区域，请去 Technologies 表里找'),
        ('CivicModifiers',              'CivicType',            'COLLECTION_PLAYER_DISTRICTS',  '市政作用于玩家全部区域，请去 Civics 表里找'),
        ('GovernmentModifiers',         'GovernmentType',       'COLLECTION_PLAYER_DISTRICTS',  '政体作用于玩家全部区域，请去 Governments 表里找'),
        ('BeliefModifiers',             'BeliefType',           'COLLECTION_ALL_DISTRICTS',     '信仰（万神殿、信条）是作用于全部区域的，因为信仰是没有所有者对象的，只会因为req而产生效果，请去 Beliefs 表里找'),
        ('GovernorPromotionModifiers',  'GovernorPromotionType','COLLECTION_CITY_DISTRICTS',    '总督升级作用于所属城市区域，请去 GovernorPromotions 表里找'),
        ('GovernorPromotionModifiers',  'GovernorPromotionType','COLLECTION_PLAYER_DISTRICTS',  '总督升级作用于玩家所有区域，请去 GovernorPromotions 表里找');
--============================================================================================================================


--============================================================================================================================
--自定义tooltip表
    CREATE TABLE Ruivo_New_Adjacency_Text(
        ID TEXT PRIMARY KEY NOT NULL, 
        Tooltip TEXT NOT NULL,
        AddPercentChar BOOLEAN NOT NULL CHECK (AddPercentChar IN (0, 1)) DEFAULT 0  --是否在数字后加百分比符号
    );
--============================================================================================================================


--============================================================================================================================
--自定义相邻对象的文本（CustomAdjacentObject）
    CREATE TABLE Ruivo_CAO (
        CustomAdjacentObject TEXT PRIMARY KEY NOT NULL,
        Name TEXT NOT NULL,
        ArtdefOverlayEntry TEXT DEFAULT NULL  -- overlay artdef entry name for tile-edge icon during district placement
    );
--文本表 + 默认 tile-edge 图标 (ArtdefOverlayEntry)
--  NULL = 没有合适的基础游戏图标，或该 CAO 类型在放置时不产生边缘图标
    INSERT INTO Ruivo_CAO (CustomAdjacentObject, Name, ArtdefOverlayEntry) VALUES
        --资源class (FROM_RINGS_CAO_RESOURCE_CLASS)
        ("RESOURCECLASS_BONUS",       "LOC_RUIVO_RESOURCECLASS_BONUS",       "Terrain_Generic_Resource"),
        ("RESOURCECLASS_LUXURY",      "LOC_RUIVO_RESOURCECLASS_LUXURY",      "Terrain_Generic_Resource"),
        ("RESOURCECLASS_STRATEGIC",   "LOC_RUIVO_RESOURCECLASS_STRATEGIC",   "Terrain_Generic_Resource"),
        ("RESOURCECLASS_ARTIFACT",    "LOC_RUIVO_RESOURCECLASS_ARTIFACT",    "Terrain_Generic_Resource"),

        --资源tag (FROM_RINGS_TYPETAG_RESOURCE)
        ("CLASS_FOOD",                "LOC_RUIVO_CLASS_FOOD",                "Terrain_Generic_Resource"),
        ("CLASS_CULTURE",             "LOC_RUIVO_CLASS_CULTURE",             "Terrain_Generic_Resource"),
        ("CLASS_GOLD",                "LOC_RUIVO_CLASS_GOLD",                "Terrain_Generic_Resource"),
        ("CLASS_PRODUCTION",          "LOC_RUIVO_CLASS_PRODUCTION",          "Terrain_Generic_Resource"),
        ("CLASS_SCIENCE",             "LOC_RUIVO_CLASS_SCIENCE",             "Terrain_Generic_Resource"),
        ("CLASS_ORAL_TRADITION",      "LOC_RUIVO_CLASS_ORAL_TRADITION",      "Terrain_Generic_Resource"),
        ("CLASS_GODDESS_OF_FESTIVALS","LOC_RUIVO_CLASS_GODDESS_OF_FESTIVALS","Terrain_Generic_Resource"),
        ("CLASS_SEA",                 "LOC_RUIVO_CLASS_SEA",                 "Terrain_Generic_Resource"),

        --地形函数 (FROM_RINGS_CAO_TERRAIN_SETS)
        --  IsCanyon has no suitable base-game overlay icon
        ("IsMountain",       "LOC_RUIVO_ISMOUNTAIN",       "Terrain_Mountain"),
        ("IsHills",          "LOC_RUIVO_ISHILLS",          "Terrain_Plains_Hills"),
        ("IsFlatlands",      "LOC_RUIVO_ISFLATLANDS",      "Terrain_Plains"),
        ("IsWater",          "LOC_RUIVO_ISWATER",          "Terrain_Sea"),
        ("IsShallowWater",   "LOC_RUIVO_ISSHALLOWWATER",   "Terrain_Coast"),
        ("IsLake",           "LOC_RUIVO_ISLAKE",           "Terrain_Coast"),
        ("IsCanyon",         "LOC_RUIVO_ISCANYON",         NULL),
        ("IsCoastalLand",    "LOC_RUIVO_ISCOASTALLAND",    "Terrain_Coast"),
        ("IsRiverCrossing",  "LOC_RUIVO_ISRIVERCROSSING",  "Terrain_River"),
        ("IsOpenGround",     "LOC_RUIVO_ISOPENGROUND",     "Terrain_Grass"),
        ("IsRoughGround",    "LOC_RUIVO_ISROUGHGROUND",    "Terrain_Plains_Hills");
--============================================================================================================================


--============================================================================================================================
--自定义提供类型ProvideType表--后续可能需要在ModifierArguments表加点特别字段，毕竟是自由的Modifier
    CREATE TABLE Ruivo_New_Adjacency_ProvideType(
        ProvideType TEXT PRIMARY KEY NOT NULL, 
        ModifierType TEXT NOT NULL,
        ArgumentName TEXT NOT NULL DEFAULT 'NONE' --用于在需要向ModifierArguments表里加特别字段时使用，填写字段时自动把YieldType也填上
    );
--示例定义提供类型：城市魅力
    INSERT INTO Ruivo_New_Adjacency_ProvideType (ProvideType, ModifierType) VALUES
    ('SelfCityAppeal', 'MODIFIER_SINGLE_CITY_ADJUST_CITY_APPEAL');
--============================================================================================================================


--============================================================================================================================
--自定义产出类型的图标和名称和字体颜色
    CREATE TABLE Ruivo_Yield_IconString (
        YieldType   TEXT PRIMARY KEY NOT NULL,
        Name        TEXT NOT NULL,
        IconString  TEXT NOT NULL,
        TextColor   TEXT NOT NULL,
        AddPercentChar BOOLEAN NOT NULL CHECK (AddPercentChar IN (0, 1)) DEFAULT 0  --是否在数字后加百分比符号
    );
--示例定义产出类型：城市单元格魅力
    INSERT INTO Ruivo_Yield_IconString (YieldType, Name, IconString, TextColor, AddPercentChar) VALUES
    ('YIELD_CITY_APPEAL', 'LOC_RUIVO_CITY_APPEAL', '[ICON_TERRAIN]', '[COLOR:2,255,141,255]', 0);
--============================================================================================================================


--============================================================================================================================
--二进制折叠矩阵表（1-512 → 1023）
    CREATE TABLE Ruivo_BinaryList (
        Num INTEGER PRIMARY KEY
    );
    INSERT INTO Ruivo_BinaryList (Num)
    VALUES (1), (2), (4), (8), (16), (32), (64), (128), (256), (512); --上限1023
--============================================================================================================================


--============================================================================================================================
--建筑-区域对应表 用于在建造奇观/需要放置的建筑时，查找对应的区域类型来计算相邻加成
    CREATE TABLE Ruivo_Building_District_Mapping (
        BuildingType TEXT PRIMARY KEY NOT NULL,
        DistrictType TEXT NOT NULL
    );
--============================================================================================================================

