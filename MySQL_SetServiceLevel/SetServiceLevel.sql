
DROP PROCEDURE IF EXISTS SetServiceLevel;

DELIMITER //
CREATE PROCEDURE SetServiceLevel
(IN ScenarioID BIGINT)
BEGIN
    
    DECLARE CompanyID        BIGINT UNSIGNED DEFAULT 0;
    DECLARE OptionName       VARCHAR(250);

    SELECT 
        company_id
    INTO CompanyID
    FROM `scenarios` S
    WHERE S.id = ScenarioID
    LIMIT 1;

    SELECT SO.`option_name`
    INTO OptionName
    FROM `scenario_options` SO
    INNER JOIN  `scenario_values` SV
        ON SV.`scenario_option_id` = SO.`id`
        AND SV.`scenario_id` = ScenarioID
    WHERE SO.`option_name` LIKE '%Set Service Level%'
    LIMIT 1;
    
    SELECT SV.*
    FROM `scenario_options` SO
    INNER JOIN  `scenario_values` SV
        ON SV.`scenario_option_id` = SO.`id`
        AND SV.`scenario_id` = ScenarioID
    WHERE SO.`option_name` = OptionName

END //
DELIMITER ;