include("RUIVO_STAT_MODULE_GP.lua");
-------------------------------------------------------------------------------
--先加载
Base_GetDistrictToolTip = ToolTipHelper.GetDistrictToolTip;

--组合之前的+模块化相邻加成
ToolTipHelper.GetDistrictToolTip = function(districtType)
  local district = GameInfo.Districts[districtType]
  districtType = district.DistrictType

  local tooltipText = Base_GetDistrictToolTip(districtType)
  local MABText = GetDistrictModularAdjacencyBonusText(districtType)
  if MABText ~= "" then
    tooltipText = tooltipText .. "[NEWLINE][NEWLINE]" 
    tooltipText = tooltipText .. Locale.Lookup("LOC_RUIVO_MODULAR_ADJACENCY_BONUS")
    tooltipText = tooltipText .. "[NEWLINE]"
    tooltipText = tooltipText .. MABText
  end

  return tooltipText
end

--覆盖
g_ToolTipGenerators.KIND_DISTRICT = ToolTipHelper.GetDistrictToolTip;
-------------------------------------------------------------------------------