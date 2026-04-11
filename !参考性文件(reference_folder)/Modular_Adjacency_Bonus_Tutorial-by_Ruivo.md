# RUIVO's Modular Adjacency Bonus Tutorial

## 1.1. Foreword

This tutorial introduces how to use the **Modular Adjacency Bonus (MAB)** system provided by this mod. This system allows you to add rich and dynamic adjacency bonuses to districts through simple SQL table insertion statements. It supports various dimensions including plot, district, city, player, and global game states. It also supports generalized bonuses such as Housing and Amenities, beyond the 6 basic yields. Furthermore, this mod is fully capable of reproducing all adjacency bonuses in Civilization VI.

In most cases, this mod will not conflict with any other mods, unless they intentionally use the same variable names or write incorrect code based on this mod. However, UI compatibility is still TBD, as the Civilization VI code framework dictates that mods modifying the UI will often conflict.

## 1.2. Acknowledgments

Special thanks to all modders exploring Lua, such as Hemmelfort, Maple Leaves, Uni, Pen, Ophidy, and the high-quality mods from many others, which allowed me to quickly accumulate experience to complete this tutorial. [1] This sentence is adapted from the acknowledgments in [SiQi's Tutorial](https://github.com/SiQi-1/Siqi-mod--/blob/main/Siqi%E7%9A%84%E6%96%87%E6%98%8E6mod%E6%95%99%E7%A8%8B.md).

I also want to thank the famous Civ VI modder Sukritact, who likely first implemented the idea of numerical correlation using binary methods in Civ VI (though I didn't know Suk had already done it when I finished this mod—reinventing the wheel, as they say).

In short, standing on the shoulders of giants, thanks to the support of many Civ VI modders and players, we will create a new future for Civilization VI!

Author: Ruivo

# 2. Prerequisite Knowledge

To use the Modular Adjacency Bonus System (MAB), you need to know how to create mods. Please refer to the following tutorials:

* Hemmelfort's [Github](https://github.com/Hemmelfort/Civ6ModdingNotes) and [Gitee](https://gitee.com/Hemmelfort/Civ6ModdingNotes), as well as Bilibili [videos](https://www.bilibili.com/video/BV1VW411U7tN/) and articles.
* Maple Leaves' [Civ VI Lua Tutorial](https://github.com/FYMapleLeaves/ml-civ6-lua-tutorial/blob/main/%E6%9E%AB%E5%8F%B6%E7%9A%84%E6%96%87%E6%98%8E6lua%E6%95%99%E7%A8%8B.md).
* SiQi's [Civ VI Mod Tutorial](https://github.com/SiQi-1/Siqi-mod--/blob/main/Siqi%E7%9A%84%E6%96%87%E6%98%8E6mod%E6%95%99%E7%A8%8B.md).

Knowledge of `.sql` is essential. All subsequent tutorials will use SQL structured statements. SQL is recommended because most Civ VI code consists of database "pre-made meals"; both SQL and XML essentially operate on the database.

Common Civ VI Directories:

* Log Location (after Great Builders pack): **C:\Users\User\AppData\Local\Firaxis Games\Sid Meier's Civilization VI\Logs**
* Non-Workshop Mod Location: **C:\Users\User\Documents\My Games\Sid Meier's Civilization VI\Mods**
* Civ VI Game Files (Steam): **\Steam\steamapps\common\Sid Meier's Civilization VI**
* Steam Workshop Mod Directory: **\Steam\steamapps\workshop\content\289070**
* Local Database Cache (Very Important!): **C:\Users\User\AppData\Local\Firaxis Games\Sid Meier's Civilization VI\Cache**

Additionally, the loading order of your `.sql` and `.xml` files that involve this mod's tables should not exceed **"1919810"**. Under normal circumstances, you don't need to specify a loading order.

Finally, if you want to check if this mod is enabled, check the **RUIVO_MODULAR_ADJACENCY_BONUS_ABLED** parameter in the **GlobalParameters** table; if it's **1**, the mod is active in both the front-end and game.

PS: Do not create SQL files in the Civ VI Development Tool; they will fail. It's best to use an editor like VS Code. You can also copy and clear this mod's SQL files for your own use.

# 3. Adjacency Bonus Implementation Tutorial

## 3.1. Basics

Standard Civ VI adjacency bonuses are quite limited, only covering "Districts," "Resources," "Improvements," and "Features." Even the Commercial Hub's "Adjacent to a River" feels unique. But with so many plot attributes available, why not use them? This mod enables extremely diverse methods.

### 3.1.1. Example: Commercial Hub gets Gold from each adjacent River segment

Let's try an idea: **Commercial Hub gets +1 Gold from each adjacent river segment**. Since a river can have multiple segments, why only give a bonus for being "adjacent to a river" once? Look at this code ↓:

```sql
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,               YieldType,   YieldChange,  AdjacencyType,  DistrictModifiers, ApplyForUniqueDistricts) VALUES
('RUIVO_DISTRICT_COMMERCIAL_HUB_YIELD_GOLD_FROM_RIVER_CROSSING', 
 'DISTRICT_COMMERCIAL_HUB', 'YIELD_GOLD', 1,           'FROM_RIVER_CROSSING',           1,                       1);
```

After adding this, it works! Now the Commercial Hub receives a bonus from every adjacent river segment. This bonus can go up to +5 since a plot can have up to 5 river edges! Unique districts also benefit!

![1775652413743](image/tutorial_images/1775652413743.png)

![1775652453359](image/tutorial_images/1775652453359.png)

![1775654973095](image/tutorial_images/1775654973095.png)

Now let's analyze the parameters. Unless customizing, all operations revolve around the **Ruivo_New_Adjacency** table.

#### 3.1.1.1. Parameter: ID (Unique Identifier)

ID is the unique identifier and **Primary Key** of the table. It's recommended to follow the naming convention "YourName_DistrictName_YieldName_AdjacencySource." If you're confident it won't conflict, any name works, even "abcd."

Note: These must be in English!

#### 3.1.1.2. Parameter: DistrictType

The district the adjacency bonus applies to. This must be a `DistrictType` defined in the `Districts` table. Standard, modded, custom, or unique districts all work!

#### 3.1.1.3. Parameter: YieldType

Without a `ProvideType`, the `YieldType` must be one of the 6 standard yields defined in the `Yields` table:

| YieldType        | Meaning    |
| ---------------- | ---------- |
| YIELD_FOOD       | Food       |
| YIELD_PRODUCTION | Production |
| YIELD_GOLD       | Gold       |
| YIELD_SCIENCE    | Science    |
| YIELD_CULTURE    | Culture    |
| YIELD_FAITH      | Faith      |

But `YieldType` is much more than this! More exciting content follows! See the `Ruivo_ProvideType_YieldType` table or the [ProvideType-YieldType Table Reference](./refer_table-参考表/Ruivo_ProvideType_YieldType.xlsx).

#### 3.1.1.4. Parameter: YieldChange (Bonus per Unit)

The **bonus value provided by each adjacent object**. For example, +1, +2, or +3 per river segment.

Decimals are supported! This is better than the original game. Note that values are rounded down (e.g., 0.9 = 0).

Also, each yield type is calculated independently; two different bonuses of +0.5 will not stack to +1. I haven't found a solution for this yet (as of 2026.4.8).

#### 3.1.1.5. Parameter: AdjacencyType

Defines the **source of the bonus**, i.e., what object/attribute the district gets its bonus from. This is the soul of this mod!

It's too long to screenshot; check the database or the [Adjacency Type Table Reference](./refer_table-参考表/Ruivo_AdjacencyType.xlsx) in `./refer_table-参考表/Ruivo_AdjacencyType.xlsx`. I extracted it with Python for easy updating.

* `AttributeType` is the source level: Plot, District, City, Player, Game.
* `HasCustomAdjacentObject` indicates if a custom object can be specified.
* `Environment` refers to whether the source function is in `GamePlay` or `UserInterface`. While I've implemented parameter passing via request events, multiplayer stability is not guaranteed.
* `CanDisplay` controls "visibility in the UI." Since religious adjacency sources haven't found a good display method yet, this parameter is currently reserved (as of 2026.4.8).
* `Tooltip` explains the adjacency source. Currently only in Chinese; use AI translation for now.

#### 3.1.1.6. Parameter: DistrictModifiers (Enable Bonus)

Controls **whether to enable this adjacency bonus**. Boolean, 0 or 1:

1: Enable bonus, binding it to the district's `DistrictModifiers`. **Required value**.

0: Disable bonus. Only used if you need to bind the bonus to a `TraitType`.

Since traits can now be formal sources, just fill in 1 unless you have stacking needs!

#### 3.1.1.7. Parameter: ApplyForUniqueDistricts

Controls **whether the bonus applies to unique districts**. Boolean, 0 or 1:

0: Only applies to the base district; unique districts do not inherit it.

1: Both base and corresponding unique districts benefit. **Recommended**.

Unique district mappings are defined in the `DistrictReplaces` table; the mod matches them automatically. If writing for a unique district directly, ignore this (defaults to 0).

### 3.1.2. Example: Theater Square gets Culture from City Amenities

Just for parameter demonstration:

```sql
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,        YieldType,        YieldChange,  AdjacencyType, DistrictModifiers, ApplyForUniqueDistricts,  Only) VALUES
('RUIVO_DISTRICT_THEATER_YIELD_CULTURE_FROM_CITY_SURPLUS_AMENITIES', 
 'DISTRICT_THEATER', 'YIELD_CULTURE',   1,           'FROM_CITY_SURPLUS_AMENITIES',  1,                       1, 'OnlyHuman');
```

![1775655597748](image/tutorial_images/1775655597748.png)

#### 3.1.2.1. Parameter: Only (Human/AI Target)

Controls **who the bonus applies to** (Human or AI players).

Supports three strings, default is 'Human&AI':

* `Human&AI`: Applies to both Human and AI (default).
* `OnlyHuman`: Only applies to Human players.
* `OnlyAI`: Only applies to AI players.

In most cases, leave this blank.

### 3.1.3. Example: Campus gets unconditional +1 Science

Just for parameter demonstration:

```sql
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,        YieldType,        YieldChange,  AdjacencyType, DistrictModifiers, ApplyForUniqueDistricts,  NewMethod) VALUES
('RUIVO_DISTRICT_CAMPUS_YIELD_SCIENCE_FROM_UNCONDITIONAL_BONUS', 
 'DISTRICT_CAMPUS',  'YIELD_SCIENCE',   1,           'FROM_UNCONDITIONAL_BONUS',     1,                       1,  1);
```

![1775656025569](image/tutorial_images/1775656025569.png)

#### 3.1.3.1. Parameter: NewMethod

Selects the **binding method for the district bonus**, either Old or New, to solve AI district placement bias.

Boolean, 0 or 1:

0 (Old Method): Bonus bound to `DistrictModifiers`. **Pro**: Bonus doesn't disappear with disasters/pillaging. **Con**: AI may value the district less or not build it at all.

1 (New Method): Bonus bound to `TraitModifiers` (`TRAIT_LEADER_MAJOR_CIV`). **Pro**: AI logic is normal. **Con**: Bonus disappears with disasters/pillaging and can cause performance lag.

This was created because a modder noted AI wouldn't build certain districts. Unfortunately, the new method is very laggy between turns and floods can break it. Stick to the old method unless necessary.

(Firaxis, what kind of code is this? I'll make you fly!)

## 3.2. Advanced

### 3.2.1. Example: Entertainment Complex gets Amenities from adjacent districts

Here, I'll reveal the charm of modular adjacency:

```sql
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,                       ProvideType,    YieldType,         YieldChange,     AdjacencyType,     DistrictModifiers,ApplyForUniqueDistricts) VALUES
('RUIVO_DISTRICT_ENTERTAINMENT_COMPLEX_YIELD_AMENITY_FROM_ADJACENT_DISTRICT', 
 'DISTRICT_ENTERTAINMENT_COMPLEX',  'SelfAmenity',  'YIELD_AMENITY',    0.5,            'FROM_ADJACENT_DISTRICT',           1,                      1);
```

![1775656754251](image/tutorial_images/1775656754251.png)

#### 3.2.1.1. Parameter: ProvideType

Defines the **delivery method of the bonus, corresponding to a unique `ModifierType`**. Determines the bonus type (base yield, percentage multiplier, Housing/Amenities, etc.). **Must be used with a compatible `YieldType`!**

Refer to the `Ruivo_ProvideType_YieldType` table or the [ProvideType-YieldType Table Reference](./refer_table-参考表/Ruivo_ProvideType_YieldType.xlsx).

This is the "exciting content"! The mod pre-sets many generalized bonuses, and `ProvideType` is customizable. We'll detail this in later chapters.

Currently supported fixed `ProvideTypes` and their bonuses:

```sql
-- Testing: Holy Site gets all yield types
INSERT INTO Ruivo_New_Adjacency 
(ID,
DistrictType,           ProvideType, YieldType, YieldChange, AdjacencyType,             DistrictModifiers,  NewMethod,  Only) SELECT
'RUIVO_TEST1_old_' || ProvideType || '_' || YieldType,
'DISTRICT_HOLY_SITE', ProvideType, YieldType, 10,         'FROM_UNCONDITIONAL_BONUS', 1,                  0,         'OnlyHuman'
FROM Ruivo_ProvideType_YieldType;
```

Includes: Air Slots, City Growth Speed, District Slots, Trade Capacity, Housing, Amenities, Loyalty, Influence, Diplomatic Favor, Tourism, Power, the 6 standard yields, Eurekas/Inspirations, Great Person Points, City Plot Appeal, and Strategic Resources.

![1775658689448](image/tutorial_images/1775658689448.png)

Additionally, this mod supports the **Property** system. Providing properties and using them as sources gives this mod incredible flexibility!

### 3.2.2. Example: Industrial Zone gets Great Engineer Points from City Production

Industrial Zone gets Great Engineer points based on the city's Production. Note that `YieldType` and `CustomAdjacentObject` depend on their `ProvideType` and `AdjacencyType`:

```sql
-- Industrial Zone gets Great Engineer points from city's "Production"
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,                 ProvideType,          YieldType,             YieldChange,     AdjacencyType,         CustomAdjacentObject,DistrictModifiers,ApplyForUniqueDistricts) VALUES
('RUIVO_DISTRICT_INDUSTRIAL_ZONE_GREAT_PERSON_CLASS_ENGINEER_FROM_CITY_CAO_YIELD', 
 'DISTRICT_INDUSTRIAL_ZONE',  'GreatPersonPoints',  'GREAT_PERSON_CLASS_ENGINEER',    1,    'FROM_CITY_CAO_YIELD', 'YIELD_PRODUCTION',                   1,                      1);
```

![1775874976118](image/tutorial_images/1775874976118.png)

#### 3.2.2.1. Parameter: CustomAdjacentObject

Specifies the **target for AdjacencyTypes that require a custom object**, such as specific resources, resource classes, terrains, etc.

Defaults to 'NONE'. In the `Ruivo_AdjacencyType` table ([Adjacency Type Table Reference](./refer_table-参考表/Ruivo_AdjacencyType.xlsx)), only sources where `HasCustomAdjacentObject` is 1 need this.

How to fill it depends on your "Civ VI common sense," for example:

* `FROM_RINGS_CAO_ROUTE`: Route types from the `Routes` table, e.g., 'ROUTE_RAILROAD'.
* `FROM_RINGS_CAO_UNIT`: Unit types from the `Units` table. Note: Traders and Spies are on a different level and cannot be objects.
* `FROM_RINGS_CAO_RESOURCE`: Resource types from the `Resources` table, e.g., 'RESOURCE_BANANAS'.
* `FROM_RINGS_CAO_RESOURCE_CLASS`: Resource classes like `RESOURCECLASS_BONUS`, `RESOURCECLASS_LUXURY`, `RESOURCECLASS_STRATEGIC`, `RESOURCECLASS_ARTIFACT`.
* `FROM_RINGS_TYPETAG_RESOURCE`: Resource tag groups from the `TypeTags` table. Tags must be of category `RESOURCE_CLASS` (extensible). Example: 'RESOURCE_COFFEE' belongs to 'CLASS_GODDESS_OF_FESTIVALS'. Define localized names in the `Ruivo_CAO` table with "LOC_" placeholders.
* `FROM_RINGS_CAO_IMPROVEMENT`: Improvement types, e.g., 'IMPROVEMENT_FARM'.
* `FROM_RINGS_CAO_DISTRICT`: District types, e.g., 'DISTRICT_CAMPUS'.
* `FROM_RINGS_CAO_FEATURE`: Feature types, e.g., 'FEATURE_FOREST'.
* `FROM_RINGS_CAO_TERRAIN`: Terrain types, e.g., 'TERRAIN_DESERT'.
* `FROM_RINGS_CAO_TERRAIN_SETS`: Custom terrain functions (Lua), e.g., 'IsMountain' for all mountain types.

For property-based sources, `CustomAdjacentObject` should be the property key name. For standard yields, use 'yield'.

### 3.2.3. Example: Preserve gets Housing from National Parks within 2 rings

```sql
-- Preserve gets Housing from National Parks within 2 rings
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,           ProvideType,   YieldType,      YieldChange,    AdjacencyType,              Rings,  DistrictModifiers, ApplyForUniqueDistricts) VALUES
('RUIVO_DISTRICT_PRESERVE_YIELD_HOUSING_FROM_RINGS_NATIONALPARK', 
 'DISTRICT_PRESERVE',   'SelfHousing', 'YIELD_HOUSING', 1,             'FROM_RINGS_NATIONALPARK',       2,                  1,                       1);
```

![1775878237062](image/tutorial_images/1775878237062.png)

#### 3.2.3.1. Parameter: Rings (Multi-ring Adjacency)

Defines the **number of rings for the adjacency bonus**. Only applies to `AdjacencyTypes` with the `RINGS` tag.

0: Only detects the **district's own plot**.

≥1: Detects plots/districts within the specified rings, **excluding the own plot**. Default is 1.

Non-RINGS types ignore this parameter.

### 3.2.4. Example: Harbor gets Gold from "Gold Resources" within 3 rings

```sql
-- Harbor gets Gold from gold-type resources within 3 rings
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,          ProvideType,   YieldType,       YieldChange,    AdjacencyType,            CustomAdjacentObject,  Rings,  DistrictModifiers, ApplyForUniqueDistricts) VALUES
('RUIVO_DISTRICT_HARBOR_YIELD_GOLD_FROM_RINGS_TYPETAG_RESOURCE', 
 'DISTRICT_HARBOR',    'SelfBonus',   'YIELD_GOLD',     1,             'FROM_RINGS_TYPETAG_RESOURCE',     'CLASS_GOLD',  3,                      1,                       1);
```

![1775879514177](image/tutorial_images/1775879514177.png)

### 3.2.5. Example: Theater gets Gold from Luxury Resources within 2 rings (Magnificence Catherine)

Method 1 (Note `DistrictModifiers` is 0):

```sql
-- Theater gets Gold from luxury resources within 2 rings (Magnificence Catherine)
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,          ProvideType,   YieldType,       YieldChange,    AdjacencyType,                   CustomAdjacentObject,  Rings,  DistrictModifiers, ApplyForUniqueDistricts,  TraitType) VALUES
('RUIVO_DISTRICT_THEATER_YIELD_GOLD_FROM_RINGS_CAO_RESOURCE_CLASS_1', 
 'DISTRICT_THEATER',   'SelfBonus',   'YIELD_GOLD',     1,             'FROM_RINGS_CAO_RESOURCE_CLASS', 'RESOURCECLASS_LUXURY',     2,                  0,                       1, 'TRAIT_LEADER_MAGNIFICENCES');
```

![1775880864130](image/tutorial_images/1775880864130.png)

#### 3.2.5.1. Parameter: TraitType

Binds the adjacency bonus to a **specific trait** (Civ or Leader). The bonus only works if the trait is active.

Default is NULL. Custom value: `TraitType` from the `Traits` table.

This has mostly been replaced by `ModifierOwner`, unless you need to stack traits with other sources. If used, `DistrictModifiers` must be 0.

### 3.2.6. Example: Theater gets Gold from Luxury Resources within 2 rings (Magnificence Catherine)

Method 2 (Note `DistrictModifiers` is 1):

```sql
-- Theater gets Gold from luxury resources within 2 rings (Magnificence Catherine)
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,          ProvideType,   YieldType,       YieldChange,    AdjacencyType,                   CustomAdjacentObject,  Rings,  DistrictModifiers, ApplyForUniqueDistricts, ModifierOwner, WhoIsTheOwner, CollectionType) VALUES
('RUIVO_DISTRICT_THEATER_YIELD_GOLD_FROM_RINGS_CAO_RESOURCE_CLASS_2', 
 'DISTRICT_THEATER',   'SelfBonus',   'YIELD_GOLD',     1,             'FROM_RINGS_CAO_RESOURCE_CLASS', 'RESOURCECLASS_LUXURY',     2,                  0,                       1, 'TraitModifiers', 'TRAIT_LEADER_MAGNIFICENCES', 'COLLECTION_PLAYER_DISTRICTS');
```

![1775881303326](image/tutorial_images/1775881303326.png)

#### 3.2.6.1. Parameter: ModifierOwner

Defines the **initiator of the modifier**, i.e., what object triggers the bonus (District, Tech, Building, Policy Card). Refer to the `Ruivo_ModifierOwner_CollectionType` table.

Note: Governor promotion series currently has bugs (as of 2026.4.11).

| ModifierOwner              | WhoIsTheOwner         | CollectionType              | Description                                                                                                   |
| -------------------------- | --------------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------- |
| DistrictModifiers          | NULL                  | COLLECTION_PLAYER_DISTRICTS | District is the initiator. No need for the other two parameters.                                              |
| TraitModifiers             | TraitType             | COLLECTION_PLAYER_DISTRICTS | Trait affects all of the player's districts. Find in `Traits` table.                                          |
| BuildingModifiers          | BuildingType          | COLLECTION_CITY_DISTRICTS   | Building affects districts in its city. Find in `Buildings` table.                                            |
| BuildingModifiers          | BuildingType          | COLLECTION_PLAYER_DISTRICTS | Building affects all player districts (e.g., Wonders). Find in `Buildings` table.                             |
| PolicyModifiers            | PolicyType            | COLLECTION_PLAYER_DISTRICTS | Policy card affects all player districts. Find in `Policies` table.                                           |
| TechnologyModifiers        | TechnologyType        | COLLECTION_PLAYER_DISTRICTS | Tech affects all player districts. Find in `Technologies` table.                                              |
| CivicModifiers             | CivicType             | COLLECTION_PLAYER_DISTRICTS | Civic affects all player districts. Find in `Civics` table.                                                    |
| GovernmentModifiers        | GovernmentType        | COLLECTION_PLAYER_DISTRICTS | Government affects all player districts. Find in `Governments` table.                                          |
| BeliefModifiers            | BeliefType            | COLLECTION_ALL_DISTRICTS    | Beliefs (Pantheon, Tenets) affect all districts as they have no owner. Find in `Beliefs` table.               |
| GovernorPromotionModifiers | GovernorPromotionType | COLLECTION_CITY_DISTRICTS   | Governor promotion affects city districts. Find in `GovernorPromotions` table.                                |
| GovernorPromotionModifiers | GovernorPromotionType | COLLECTION_PLAYER_DISTRICTS | Governor promotion affects all player districts. Find in `GovernorPromotions` table.                         |

#### 3.2.6.2. Parameter: WhoIsTheOwner

Defines the **specific object of the initiator**, e.g., which Tech/Building/Policy triggers the bonus. Strongly bound to `ModifierOwner`.

#### 3.2.6.3. Parameter: CollectionType

Defines the **scope of the modifier's target collection**, i.e., which districts are affected: City or Player. Core values:

| CollectionType              | Target             | Usage Scenario                                |
| --------------------------- | ------------------ | --------------------------------------------- |
| COLLECTION_PLAYER_DISTRICTS | All player's districts | Regular district bonuses (default).           |
| COLLECTION_CITY_DISTRICTS   | All districts in a city | City-wide bonuses from buildings/governors.   |
| COLLECTION_ALL_DISTRICTS    | All districts in game | Global bonuses from beliefs/pantheons.        |

## 3.3. Customization

From this section, we'll operate on tables beyond `Ruivo_New_Adjacency`.

### 3.3.1. Example: Modifying Tooltip Text - Campus gets +0.3 Great Scientist Points from each adjacent Mountain

Tooltip text for each ID can be replaced:

```sql
-- Campus gets +0.3 Great Scientist points from each mountain within 2 rings
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,          ProvideType,         YieldType,             YieldChange,     AdjacencyType,            CustomAdjacentObject,  Rings,  DistrictModifiers, ApplyForUniqueDistricts) VALUES
('RUIVO_DISTRICT_CAMPUS_GREAT_PERSON_CLASS_SCIENTIST_FROM_RINGS_CAO_TERRAIN_SETS', 
 'DISTRICT_CAMPUS',    'GreatPersonPoints', 'GREAT_PERSON_CLASS_SCIENTIST', 0.3,    'FROM_RINGS_CAO_TERRAIN_SETS',     'IsMountain',  2,                      1,                       1);

-- Replace Text
INSERT INTO Ruivo_New_Adjacency_Text (ID, Tooltip, AddPercentChar)
VALUES
('RUIVO_DISTRICT_CAMPUS_GREAT_PERSON_CLASS_SCIENTIST_FROM_RINGS_CAO_TERRAIN_SETS',      'LOC_RUIVO_TEST_TOOLTIP', 1);
```

Then provide the localization:

```xml
<GameData>
    <LocalizedText>
        <Row Tag="LOC_RUIVO_TEST_TOOLTIP" Language="en_US">
            <Text>This is Modular Adjacency! +{1_iBonus} {2_YieldIcon} from {3_AdjacentSubjectNum} adjacent {4_CAO}. Note: Parameter order cannot be changed.</Text>
        </Row>
    </LocalizedText>
</GameData>
```

![1775898293503](image/tutorial_images/1775898293503.png)

#### 3.3.1.1. Table: Ruivo_New_Adjacency_Text

Configures UI tooltip text for each bonus rule in the core table.

```sql
INSERT INTO Ruivo_New_Adjacency_Text (ID, Tooltip, AddPercentChar) VALUES
('CoreTable_ID', 'TextKey', 0/1);
```

+ ID: Matches `Ruivo_New_Adjacency.ID`.
+ Tooltip: Custom placeholder.
+ AddPercentChar: 0 = No, 1 = Yes (only modifies the tooltip display).

Placeholders (order is fixed):
+ {1_iBonus}: Bonus amount.
+ {2_YieldIcon}: Yield icon and name.
+ {3_AdjacentSubjectNum}: Number of adjacent objects.
+ {4_CAO}: Custom adjacent object.

### 3.3.2. Example: Custom Object - Entertainment Complex gets Amenities from custom tag resource group

Using resource tag groups:

```sql
-- Define resource class: RUIVO_TEST
INSERT INTO Tags 
(Tag,                  Vocabulary) VALUES  
('CLASS_RUIVO_TEST',   'RESOURCE_CLASS');

-- Define resource tags: Bananas, Jade, Iron
INSERT INTO TypeTags 
(Tag,                 Type) VALUES  
('CLASS_RUIVO_TEST', 'RESOURCE_BANANAS'),
('CLASS_RUIVO_TEST', 'RESOURCE_JADE'),
('CLASS_RUIVO_TEST', 'RESOURCE_IRON');

-- Entertainment Complex gets Amenities from custom tag resources
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,                        ProvideType,    YieldType,       YieldChange,    AdjacencyType,              CustomAdjacentObject,     Rings,  DistrictModifiers, ApplyForUniqueDistricts) VALUES
('RUIVO_DISTRICT_ENTERTAINMENT_COMPLEX_YIELD_AMENITY_FROM_RINGS_TYPETAG_RESOURCE', 
 'DISTRICT_ENTERTAINMENT_COMPLEX',   'SelfAmenity',  'YIELD_AMENITY',  1,             'FROM_RINGS_TYPETAG_RESOURCE', 'CLASS_RUIVO_TEST',     2,                      1,                       1);

-- Replace object placeholder text
INSERT INTO Ruivo_CAO 
(CustomAdjacentObject, Name) VALUES 
('CLASS_RUIVO_TEST', 'LOC_RUIVO_CLASS_TEST_RESOURCE');
```

Localization:

```xml
<GameData>
    <LocalizedText>
        <Row Tag="LOC_RUIVO_CLASS_TEST_RESOURCE" Language="en_US">
            <Text>Test Resources</Text>
        </Row>
    </LocalizedText>
</GameData>
```

![1775899577629](image/tutorial_images/1775899577629.png)

#### 3.3.2.1. Table: Ruivo_CAO (Custom Adjacent Object Text Table)

Example entries:

```sql
INSERT INTO Ruivo_CAO (CustomAdjacentObject, Name) VALUES
        -- Resource Classes
        ("RESOURCECLASS_BONUS",       "LOC_RUIVO_RESOURCECLASS_BONUS"),
        ("RESOURCECLASS_LUXURY",      "LOC_RUIVO_RESOURCECLASS_LUXURY"),
        ("RESOURCECLASS_STRATEGIC",   "LOC_RUIVO_RESOURCECLASS_STRATEGIC"),
        ("RESOURCECLASS_ARTIFACT",    "LOC_RUIVO_RESOURCECLASS_ARTIFACT"),

        -- Terrain Functions
        ("IsMountain",       "LOC_RUIVO_ISMOUNTAIN"),
        ("IsHills",          "LOC_RUIVO_ISHILLS"),
        ("IsFlatlands",      "LOC_RUIVO_ISFLATLANDS"),
        ("IsWater",          "LOC_RUIVO_ISWATER"),
        ("IsShallowWater",   "LOC_RUIVO_ISSHALLOWWATER"),
        ("IsLake",           "LOC_RUIVO_ISLAKE"),
        ("IsCanyon",         "LOC_RUIVO_ISCANYON"),
        ("IsCoastalLand",    "LOC_RUIVO_ISCOASTALLAND"),
        ("IsRiverCrossing",  "LOC_RUIVO_ISRIVERCROSSING"),
        ("IsOpenGround",     "LOC_RUIVO_ISOPENGROUND"),
        ("IsRoughGround",    "LOC_RUIVO_ISROUGHGROUND");
```

* CustomAdjacentObject: Custom object.
* Name: Text placeholder.

Actually, this table isn't strictly necessary as you can achieve the same via `Tooltip` replacement.

### 3.3.3. Example: Custom Yield Type - [Medical District](https://steamcommunity.com/sharedfiles/filedetails/?id=3483460357) Healing Aura

Example code from [Enhanced Medical District](https://steamcommunity.com/sharedfiles/filedetails/?id=3656529825). Note that this mod separates UI display from actual mechanics.

Note that while the `ProvideType` here isn't a property, it still uses properties as the Lua function trigger. Since plots have properties, you can use `FreeCompose` or one of the four property `ProvideTypes` (`SelfDistrictProperty`, `SelfCityProperty`, `SelfPlayerProperty`, `SelfGameProperty`).

```sql
-- Healing Aura yield name, icon, and text color
    INSERT INTO Ruivo_Yield_IconString (YieldType, Name, IconString, TextColor, AddPercentChar) VALUES
    ("HealRings", "LOC_RUIVO_HealRings", "[ICON_DAMAGED]", "[COLOR_GREEN]", 0);

-- Medical District releases Healing Aura
-- Base yield: +7 Healing Aura
-- Per Citizen yield: +10 Healing Aura
    INSERT INTO Ruivo_New_Adjacency 
    (ID, DistrictType, 
    ProvideType, YieldType, YieldChange, 
    AdjacencyType, CustomAdjacentObject, 
    DistrictModifiers, ApplyForUniqueDistricts, TraitType, 
    ModifierOwner, WhoIsTheOwner, CollectionType, 
    Only, 
    FreeCompose) 
    VALUES 
    ('R_DISTRICT_JD_HOSPITAL', 'DISTRICT_JD_HOSPITAL', 
    'ShowFreeComposeYield', 'HealRings', 10, 
    'FROM_SELF_WORKER', 'NONE', 
    1, 1, NULL, 
    'DistrictModifiers', NULL, 'COLLECTION_CITY_DISTRICTS', 
    'Human&AI', 
    1),

    ('R_DISTRICT_JD_HOSPITAL_BASIC', 'DISTRICT_JD_HOSPITAL', 
    'ShowFreeComposeYield', 'HealRings', 7, 
    'FROM_UNCONDITIONAL_BONUS', 'NONE', 
    1, 1, NULL, 
    'DistrictModifiers', NULL, 'COLLECTION_CITY_DISTRICTS', 
    'Human&AI', 
    1);
```

Localization:

```xml
<GameData>
    <LocalizedText>
        <Row Tag="LOC_RUIVO_HealRings" Language="en_US">
            <Text>Healing Aura Amount</Text>
        </Row>
    </LocalizedText>
</GameData>
```

![1775900810512](image/tutorial_images/1775900810512.png)

#### 3.3.3.1. Table: Ruivo_Yield_IconString (Custom Yield Display Table)

Configures UI display for custom `YieldTypes`.

```sql
INSERT INTO Ruivo_Yield_IconString (YieldType, Name, IconString, TextColor, AddPercentChar) VALUES
('CustomYieldType', 'NameKey', 'IconString', 'ColorValue', 0/1);
```

+ YieldType: Matches the custom type in the core table.
+ Name: Localization placeholder.
+ IconString: Game icon placeholder or custom icon.
+ TextColor: Standard color like `[COLOR_GREEN]` or custom RGB `[COLOR:255,255,255,255]`.
+ AddPercentChar: 0 = No, 1 = Yes.

### 3.3.4. Example: Custom Provide Type - [Light Industrial Zone](https://steamcommunity.com/sharedfiles/filedetails/?id=3489161598) Builder and Trader Production Acceleration

We have a new parameter `CustomArgumentValue` because a single `ArgumentName` might have multiple uses. We must distinguish `CustomArgumentValue` from `YieldType`.

```sql
-- Define ProvideType: Unit Production Acceleration -- YieldType will be filled automatically if ArgumentName is present
    INSERT INTO Ruivo_New_Adjacency_ProvideType (ProvideType, ModifierType, ArgumentName) VALUES
    ('SelfUnitProduction', 'MODIFIER_PLAYER_UNITS_ADJUST_UNIT_PRODUCTION', 'UnitType');

-- Define YieldTypes: Trader and Builder acceleration
    INSERT INTO Ruivo_Yield_IconString (YieldType, Name, IconString, TextColor, AddPercentChar) VALUES
    ('UNIT_BUILDER_ACCELERATION', 'LOC_RUIVO_UNIT_BUILDER_ACCELERATION', '[ICON_PRODUCTION]', '[COLOR:255,126,0,255]', 1),
    ('UNIT_TRADER_ACCELERATION',  'LOC_RUIVO_UNIT_TRADER_ACCELERATION',  '[ICON_PRODUCTION]', '[COLOR:255,252,0,255]', 1);

-- Light Industrial Zone +100% Trader and Builder acceleration
    INSERT INTO Ruivo_New_Adjacency 
    (ID, 
     DistrictType,                     ProvideType,          YieldType,                      CustomArgumentValue,   YieldChange, AdjacencyType,   DistrictModifiers,  ApplyForUniqueDistricts) VALUES
    ('RUIVO_DISTRICT_LIGHT_INDUSTRIAL_ZONE_UNIT_BUILDER_ACCELERATION_FROM_ADJACENT_DISTRICT',  
    'DISTRICT_LIGHT_INDUSTRIAL_ZONE', 'SelfUnitProduction', 'UNIT_BUILDER_ACCELERATION',    'UNIT_BUILDER',         100,        'FROM_ADJACENT_DISTRICT',         1,                        1),
    ('RUIVO_DISTRICT_LIGHT_INDUSTRIAL_ZONE_UNIT_TRADER_ACCELERATION_FROM_ADJACENT_DISTRICT',  
    'DISTRICT_LIGHT_INDUSTRIAL_ZONE', 'SelfUnitProduction', 'UNIT_TRADER_ACCELERATION',     'UNIT_TRADER',          100,        'FROM_ADJACENT_DISTRICT',         1,                        1);
```

Localization:

```xml
<GameData>
    <LocalizedText>
        <Row Tag="LOC_RUIVO_UNIT_BUILDER_ACCELERATION" Language="en_US">
            <Text>Builder Acceleration</Text>
        </Row>
        <Row Tag="LOC_RUIVO_UNIT_TRADER_ACCELERATION" Language="en_US">
            <Text>Trader Acceleration</Text>
        </Row>
    </LocalizedText>
</GameData>
```

![1775901497767](image/tutorial_images/1775901497767.png)

#### 3.3.4.1. Table: Ruivo_New_Adjacency_ProvideType

Defines a new `ProvideType` and its associated modifier effect.

```sql
INSERT INTO Ruivo_New_Adjacency_ProvideType (ProvideType, ModifierType, ArgumentName) VALUES
('CustomProvideType', 'AssociatedModifierType', 'ExtraArgumentName');
```

* ProvideType: Custom delivery type.
* ModifierType: The modifier effect. Since it's attached to districts, your `COLLECTION` scope should reflect district attributes.
* ArgumentName: Used when a special field is needed in `ModifierArguments`. Usually defaults to `Amount`. `CustomArgumentValue` is automatically inserted into this field.

#### 3.3.4.2. Parameter: CustomArgumentValue

This is a product of legacy code compatibility. To maintain UI compatibility when using custom modifiers (non-property) with arguments other than `Amount`, you need to specify the target here separately from `YieldType`.

Example: We define `UNIT_BUILDER_ACCELERATION` as a new yield, but in `Ruivo_New_Adjacency`, we still need to specify `UNIT_BUILDER` as the actual `UnitType`.

### 3.3.5. Example: FreeCompose Mode - Harbor providing Fishing Range

A complex example of `FreeCompose` mode:

```sql
-- Harbor: +1 Fishing Range per city district; +2 Gold on shallow and deep water within range.
    -- Custom yield icon and text for Fishing Range
    INSERT INTO Ruivo_Yield_IconString (YieldType, Name, IconString, TextColor) VALUES
    ("FishingRange", "LOC_RUIVO_FishingRange", "[ICON_DISTRICT_HARBOR]", "[COLOR:MarineDark]");

    -- Up to 10 rings
    CREATE TABLE Ruivo_RingList (Num INTEGER PRIMARY KEY);
    INSERT INTO Ruivo_RingList (Num) VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10);

    -- FreeCompose Mode
    INSERT INTO Ruivo_New_Adjacency
    (ID,                                                          DistrictType,      YieldType,    ProvideType,             YieldChange, AdjacencyType,            DistrictModifiers, FreeCompose)  VALUES 
    ('RUIVO_DISTRICT_HARBOR_YIELD_GOLD_FROM_CITY_DISTRICTS_NUM', 'DISTRICT_HARBOR', 'FishingRange', 'ShowFreeComposeYield',   1,          'FROM_CITY_DISTRICTS_NUM', 1,                 1);

    -- (Standard SQL follows for defining the actual mechanics using the property left by the mod)
    -- [Omitted for brevity, refer to Chinese tutorial for full SQL]
```

#### 3.3.5.1. Parameter: FreeCompose

Enables **FreeCompose Mode**, an advanced feature for non-standard bonuses. When enabled, only the Lua-side property data (and plot requirements) are kept. Boolean, 0 or 1:

+ 0: Regular Mode. Mod automatically generates modifiers and requirements.
+ 1: FreeCompose Mode. Mod **only calculates the bonus and stores it as a plot property**. You must manually write modifiers to read this property.

This was intended for new modifier needs, but with `ProvideType` customization and property systems, it's mostly used for niche scenarios now.

#### 3.3.5.2. Note: Lua-side statistical properties on the district's plot

If you want to use the statistical data left by a district on its plot in SQL or Lua, use these properties:

```lua
-- Total count
local TotalKey = ID .. '_TOTAL'
-- Actual total bonus (count * change)
local ActualAmountKey = ID .. '_ACTUAL_AMOUNT'

-- Example: Harbor adjacent to 3 river segments with +2 Gold each.
-- TotalKey = 3, ActualAmountKey = 6.
```

The key name is your adjacency rule's ID plus the suffix.

### 3.3.6. Example: FreeCompose Mode - Spaceport Project Acceleration by Latitude

Old implementation, now achievable via custom `ProvideType`:

```sql
-- Spaceport: Production bonus near equator, Science bonus near poles.
-- Space Race project acceleration based on equator proximity.
    -- Custom yield icon for Space Race Production
    INSERT INTO Ruivo_Yield_IconString (YieldType, Name, IconString, TextColor, AddPercentChar) VALUES
    ("SpaceRaceProduction", "LOC_RUIVO_SpaceRaceProduction", "[ICON_DISTRICT_SPACEPORT]", "[COLOR:Production]", 1);

    INSERT INTO Ruivo_New_Adjacency 
    (ID, 
     DistrictType,          ProvideType,            YieldType,              YieldChange,    AdjacencyType,      DistrictModifiers,  NewMethod,  ApplyForUniqueDistricts, FreeCompose) VALUES
  
    -- 1. Production from latitude
    ('RUIVO_DISTRICT_SPACEPORT_YIELD_PRODUCTION_FROM_LATITUDE', 
    'DISTRICT_SPACEPORT',   'SelfBonus',            'YIELD_PRODUCTION',     0.5,            'FROM_LATITUDE',    1,                  0,          1,                       0),

    -- 2. Science from poles
    ('RUIVO_DISTRICT_SPACEPORT_YIELD_SCIENCE_FROM_POLE', 
    'DISTRICT_SPACEPORT',   'SelfBonus',            'YIELD_SCIENCE',        0.5,            'FROM_POLE',        1,                  0,          1,                       0),
  
    -- 3. Space Race production (FreeCompose)
    ('RUIVO_DISTRICT_SPACEPORT_SPACE_RACE_PRODUCTION_FROM_LATITUDE', 
    'DISTRICT_SPACEPORT',   'ShowFreeComposeYield', 'SpaceRaceProduction',  1,              'FROM_LATITUDE',    1,                  0,          1,                       1);
```

### 3.3.7. Example: Property as Adjacency Source - Holy Site cascading bonus

`FROM PROPERTY` series don't have built-in tooltip translations; replacement is required:

```sql
-- Holy Site from mountains (FreeCompose to leave property)
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,          ProvideType,         YieldType,   YieldChange,   AdjacencyType,         CustomAdjacentObject,  Rings,  DistrictModifiers, ApplyForUniqueDistricts, FreeCompose) VALUES
('RUIVO_DISTRICT_HOLY_SITE_FROM_MOUNTAIN', 
 'DISTRICT_HOLY_SITE', 'ProvideNothing',    'YIELD_NONE', 1,            'FROM_RINGS_CAO_TERRAIN_SETS',  'IsMountain',  1,                      1,                       1,           1);

-- Holy Site gets bonus from mountains adjacent to OTHER Holy Sites within 2 rings
INSERT INTO Ruivo_New_Adjacency 
(ID, 
 DistrictType,          ProvideType,    YieldType,    YieldChange,   AdjacencyType,               CustomAdjacentObject,                           Rings,  DistrictModifiers, ApplyForUniqueDistricts) VALUES
('RUIVO_DISTRICT_HOLY_SITE_YIELD_FAITH_FROM_OTHER_DISTRICT_HOLY_SITE', 
 'DISTRICT_HOLY_SITE', 'SelfBonus',    'YIELD_FAITH', 1,            'FROM_RINGS_PLOT_PROPERTY',  'RUIVO_DISTRICT_HOLY_SITE_FROM_MOUNTAIN_TOTAL',  2,                      1,                       1);
```

![1775909832249](image/tutorial_images/1775909832249.png)

### 3.3.8. Example: Providing Property as Bonus - [Millennium Campus](https://steamcommunity.com/sharedfiles/filedetails/?id=3671918017)

[Refer to Chinese tutorial for full SQL implementation]

![1775910132109](image/tutorial_images/1775910132109.png)

# 4. Conclusion

That's all for now. Class dismissed!

Other parts are still under construction. Please bear with us as the mod and tutorial are not yet fully comprehensive!
