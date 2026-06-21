--新增开局按钮：是否加载左侧侧滑栏
INSERT OR IGNORE INTO Parameters (ConfigurationGroup, ConfigurationId, DefaultValue, Description, Domain, GroupId, Hash, Name, ParameterId, SortIndex)
VALUES ('Game', 'RUIVO_DISABLE_MAB_POPUP', 0, 'LOC_RUIVO_DISABLE_MAB_POPUP_DESC', 'bool', 'AdvancedOptions', 0, 'LOC_RUIVO_DISABLE_MAB_POPUP_NAME', 'RUIVO_DISABLE_MAB_POPUP_ID', 999);
--============================================================================================================================
--全局参数，判断开没开马良相邻
    INSERT OR IGNORE INTO GlobalParameters (Name, Value) VALUES 
    ('RUIVO_MODULAR_ADJACENCY_BONUS_ABLED', '1');
--============================================================================================================================
