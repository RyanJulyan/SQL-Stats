
DROP PROCEDURE IF EXISTS CalculateLeadtime;

DELIMITER //
CREATE PROCEDURE CalculateLeadtime
(IN ScenarioID BIGINT)
BEGIN
    
    DECLARE CompanyID               BIGINT UNSIGNED DEFAULT 0;
    DECLARE json                    JSON;
    DECLARE Min_Date_Text           VARCHAR(250);
    DECLARE Max_Date_Text           VARCHAR(250);
    DECLARE Min_Date                DATETIME;
    DECLARE Max_Date                DATETIME;

    SELECT 
        company_id
    INTO CompanyID
    FROM `scenarios` S
    WHERE S.id = ScenarioID
    LIMIT 1;

    CREATE TEMPORARY TABLE IF NOT EXISTS `temp_JSON_Key_Value_Split`
    (
         `key`      VARCHAR(250) NOT NULL
        ,`value`    VARCHAR(250) NOT NULL
    );
    
    CREATE TEMPORARY TABLE IF NOT EXISTS `temp_scenario_set_order_transaction_types`
    AS
    (
        SELECT 
             SV.id
            ,SV.scenario_option_id
            ,COALESCE(SV.`key_value`,SO.`key_value`) as key_value
        FROM `scenario_options` SO
        LEFT JOIN  `scenario_values` SV
            ON SV.`scenario_option_id` = SO.`id`
            AND SV.`scenario_id` = ScenarioID
        WHERE SO.`option_name` = 'Set Orders Transaction Types'
        LIMIT 1
    );
        
    SELECT SV.`key_value`
    INTO json
    FROM temp_scenario_set_order_transaction_types SV
    ORDER BY 
            SV.id
    LIMIT 1;

    Truncate TABLE `temp_JSON_Key_Value_Split`;

    CALL JSON_Key_Value_Split(json);

    CREATE TEMPORARY TABLE IF NOT EXISTS `temp_scenario_orders_transaction_types`
    AS
    (
        SELECT  
             `key`
            ,`value`
        FROM `temp_JSON_Key_Value_Split`
    );
    
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_scenario_values
    AS
    (
        SELECT 
             SV.id
            ,SV.scenario_option_id
            ,COALESCE(SV.`key_value`,SO.`key_value`) as key_value
        FROM `scenario_options` SO
        LEFT JOIN  `scenario_values` SV
            ON SV.`scenario_option_id` = SO.`id`
            AND SV.`scenario_id` = ScenarioID
        WHERE SO.`option_name` = 'Calculate Leadtime Days'
    );
        
    SELECT SV.`key_value`
    INTO json
    FROM temp_scenario_values SV
    ORDER BY 
            SV.id
    LIMIT 1;

    TRUNCATE TABLE `temp_JSON_Key_Value_Split`;

    CALL JSON_Key_Value_Split(json);

    SELECT 
        `value`
    INTO Min_Date_Text
    FROM temp_JSON_Key_Value_Split
    WHERE `key` = 'StartDate'
    LIMIT 1;

    IF STRCMP(Min_Date_Text,"MIN") = 0 THEN 
        SELECT 
            MIN(`actual_completion_date`)
        INTO Min_Date
        FROM `transactions` T
        INNER JOIN `scenarios` S
            ON S.`transaction_source_id` = T.`transaction_source_id`
        INNER JOIN `transaction_types` TT
            ON TT.`id` = T.`transaction_type_id`
        WHERE S.`id` = ScenarioID
        AND TT.`code` IN (SELECT `value` 
                        FROM `temp_scenario_orders_transaction_types`
                        WHERE `key` NOT IN ('StartDate','EndDate')
                        );
    ELSE
        SELECT CONVERT(Min_Date_Text,DATE)
        INTO Min_Date;
    END IF;


    SELECT 
        `value`
    INTO Max_Date_Text
    FROM temp_JSON_Key_Value_Split
    WHERE `key` = 'EndDate'
    LIMIT 1;

    IF STRCMP(Max_Date_Text,"MAX") = 0 THEN

        SELECT 
            MAX(`actual_completion_date`)
        INTO Max_Date
        FROM `transactions` T
        INNER JOIN `transaction_types` TT
            ON TT.`id` = T.`transaction_type_id`
        INNER JOIN `scenarios` S
            ON S.`transaction_source_id` = T.`transaction_source_id`
        WHERE S.`id` = ScenarioID
        AND TT.`code` IN (SELECT `value` 
                        FROM `temp_scenario_orders_transaction_types`
                        WHERE `key` NOT IN ('StartDate','EndDate')
                        );

    ELSE

        SELECT CONVERT(Max_Date_Text,DATE)
        INTO Max_Date;

    END IF;

    
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_scenario_daysdiff
    AS
    (
    SELECT
         T.resource_id
        ,T.location_id
        ,DATEDIFF(T.actual_completion_date,IFNULL(T.initiated_date,T.actual_completion_date)) as days_diff
    FROM `transactions` T
    INNER JOIN `transaction_types` TT
        ON TT.`id` = T.`transaction_type_id`
    INNER JOIN `scenarios` S
        ON S.`transaction_source_id` = T.`transaction_source_id`
    WHERE S.`id` = ScenarioID
    AND TT.`code` IN (SELECT `value` 
                    FROM `temp_scenario_orders_transaction_types`
                    WHERE `key` NOT IN ('StartDate','EndDate')
                    )
    );

    CREATE TABLE IF NOT EXISTS `resource_location_leadtime`
    (
         `company_id`           BIGINT NOT NULL
        ,`scenario_id`          BIGINT NOT NULL
        ,`resource_id`          BIGINT NOT NULL
        ,`location_id`          BIGINT NOT NULL
        ,`leadtime_days`        DECIMAL(38, 19) NOT NULL
        ,`stddev_leadtime_days` DECIMAL(38, 19) NOT NULL
        ,`start_date`           DATETIME
        ,`end_date`             DATETIME
    );

    DELETE 
    FROM `resource_location_leadtime`
    WHERE `scenario_id` = ScenarioID;

    INSERT INTO `resource_location_leadtime`(
         `company_id`
        ,`scenario_id`
        ,`resource_id`
        ,`location_id`
        ,`leadtime_days`
        ,`stddev_leadtime_days`
        ,`start_date`
        ,`end_date`
    )
    SELECT 
         CompanyID AS `company_id`
        ,ScenarioID AS `scenario_id`
        ,O.resource_id
        ,O.location_id
        ,AVG(O.days_diff) AS leadtime_days
        ,STDDEV(O.days_diff) AS stddev_leadtime_days
        ,Min_Date AS `start_date`
        ,Max_Date AS `end_date`
    FROM temp_scenario_daysdiff AS O
    GROUP BY 
         O.resource_id
        ,O.location_id;

END //
DELIMITER ;