
DROP PROCEDURE IF EXISTS SetServiceLevel;

DELIMITER //
CREATE PROCEDURE SetServiceLevel
(IN ScenarioID BIGINT)
BEGIN
    
    DECLARE CompanyID               BIGINT UNSIGNED DEFAULT 0;
    DECLARE json                    JSON;
    DECLARE COUNT_Scenario_Values   BIGINT UNSIGNED DEFAULT 0;
    DECLARE OptionName              VARCHAR(250);
    DECLARE `_counter`              BIGINT UNSIGNED DEFAULT 0;
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

    SELECT SO.`option_name`
    INTO OptionName
    FROM `scenario_options` SO
    INNER JOIN  `scenario_values` SV
        ON SV.`scenario_option_id` = SO.`id`
        AND SV.`scenario_id` = ScenarioID
    WHERE SO.`option_name` LIKE '%Set Service Level%'
    LIMIT 1;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_scenario_values
    AS
    (
        SELECT 
             SV.id
            ,SV.scenario_option_id
            ,SV.key_value
        FROM `scenario_options` SO
        INNER JOIN  `scenario_values` SV
            ON SV.`scenario_option_id` = SO.`id`
            AND SV.`scenario_id` = ScenarioID
        WHERE SO.`option_name` = OptionName
    );

    SELECT
        COUNT(1) AS COUNT_Scenario_Values
    INTO COUNT_Scenario_Values
    FROM temp_scenario_values;



    IF INSTR(OptionName, 'Set Service Level By Pareto') = 1 THEN

        CALL ParetoClassification(ScenarioID);

        CREATE TABLE IF NOT EXISTS `resource_pareto_service_levels`
        (
            `company_id`           BIGINT NOT NULL
            ,`scenario_id`          BIGINT NOT NULL
            ,`resource_id`          BIGINT NOT NULL
            ,`key`                  VARCHAR(250)
            ,`service_level_prec`   FLOAT NOT NULL
            ,`start_date`           DATE NOT NULL
            ,`end_date`             DATE NOT NULL
        );


        DELETE 
        FROM `resource_pareto_service_levels`
        WHERE `scenario_id` = ScenarioID;

    END IF;
    

    WHILE `_counter` < COUNT_Scenario_Values DO
        
        SELECT SV.`key_value`
        INTO json
        FROM temp_scenario_values SV
        ORDER BY 
             SV.id
        LIMIT 1;

        SET `_counter` := `_counter` + 1;

        CREATE TEMPORARY TABLE IF NOT EXISTS `temp_JSON_Key_Value_Split`
        (
             `key`      VARCHAR(250) NOT NULL
            ,`value`    VARCHAR(250) NOT NULL
        );

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
            WHERE S.`id` = ScenarioID;
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
            INNER JOIN `scenarios` S
                ON S.`transaction_source_id` = T.`transaction_source_id`
            WHERE S.`id` = ScenarioID;

        ELSE

            SELECT CONVERT(Max_Date_Text,DATE)
            INTO Max_Date;

        END IF;

        IF INSTR(OptionName, 'Set Service Level By Pareto') = 1 THEN

            INSERT INTO `resource_pareto_service_levels`(
                 `company_id`
                ,`scenario_id`
                ,`resource_id`
                ,`key`
                ,`service_level_prec`
                ,`start_date`
                ,`end_date`
            )
            SELECT 
                 CompanyID AS `company_id`
                ,ScenarioID AS `scenario_id`
                ,PC.`resource_id`
                ,KV.`key`
                ,KV.`value` AS `service_level_prec`
                ,Min_Date AS `start_date`
                ,Max_Date AS `end_date`
            FROM temp_JSON_Key_Value_Split KV
            INNER JOIN `resource_pareto_classifications` PC
                ON PC.`key` = KV.`key`
            WHERE KV.`key` NOT IN ('StartDate','EndDate');

        END IF;

        DELETE
        FROM `temp_scenario_values`
        ORDER BY 
             id
        LIMIT 1;

    END WHILE;

END //
DELIMITER ;