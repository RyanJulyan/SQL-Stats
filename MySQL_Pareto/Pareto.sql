DROP PROCEDURE IF EXISTS ParetoClassification;

DELIMITER //
CREATE PROCEDURE ParetoClassification
(IN scenarioID BIGINT)
BEGIN

    DECLARE json                JSON;
    DECLARE Min_Date_Text       VARCHAR(250);
    DECLARE Max_Date_Text       VARCHAR(250);
    DECLARE Min_Date            DATETIME;
    DECLARE Max_Date            DATETIME;
    DECLARE Sum_Prec            FLOAT;
    DECLARE Count_Perc          INT;
    DECLARE Row_Number          INT DEFAULT 0;
    DECLARE Count_Row_Number    INT DEFAULT 0;
    DECLARE `_counter`          BIGINT UNSIGNED DEFAULT 0;
    DECLARE UpperRange          FLOAT DEFAULT 0;

    SELECT
        COALESCE(SV.`key_value`,SO.`key_value`) as key_value
    INTO json
    FROM `scenario_options` SO
    LEFT JOIN  `scenario_values` SV
        ON SV.`scenario_option_id` = SO.`id`
        AND SV.`scenario_id` = scenarioID
    WHERE SO.`option_name` = 'Set Service Level By Pareto'
    LIMIT 1;


    CREATE TEMPORARY TABLE IF NOT EXISTS `temp_JSON_Key_Value_Split`
    (
         `key` VARCHAR(250) NOT NULL
        ,`value` VARCHAR(250) NOT NULL
    );

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
        WHERE S.id = scenarioID;
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
        WHERE S.id = scenarioID;

    ELSE

        SELECT CONVERT(Max_Date_Text,DATE)
        INTO Max_Date;

    END IF;

    SELECT 
        SUM(`value`)
    INTO Sum_Prec 
    FROM temp_JSON_Key_Value_Split
    WHERE `key` NOT IN ('StartDate','EndDate');

    
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_Perc
    AS
    (
        SELECT 
            `key`
            ,`value` AS OriginalPrec
            ,`value` / Sum_Prec AS ApportionedPrec
        FROM temp_JSON_Key_Value_Split
        WHERE `key` NOT IN ('StartDate','EndDate')
        ORDER BY `value` / Sum_Prec
    );

    CREATE TEMPORARY TABLE IF NOT EXISTS `temp_Perc_Split`
    (
         `key` VARCHAR(250) NOT NULL
        ,`OriginalPrec` FLOAT NOT NULL
        ,`ApportionedPrec` FLOAT NOT NULL
        ,`LowerRange` FLOAT NULL
        ,`UpperRange` FLOAT NULL
    );

    SELECT 
        COUNT(1) AS Count_Perc
    INTO Count_Perc
    FROM temp_Perc;

    WHILE `_counter` < Count_Perc DO
        
        IF `_counter` = 0 THEN

            INSERT INTO `temp_Perc_Split` (`key`,`OriginalPrec`,`ApportionedPrec`,`LowerRange`,`UpperRange`)
            SELECT 
                 `key`
                ,`OriginalPrec`
                ,`ApportionedPrec`
                ,0 as `LowerRange`
                ,`ApportionedPrec` AS `UpperRange`
            FROM temp_Perc
            LIMIT 1;

        ELSE

            INSERT INTO `temp_Perc_Split` (`key`,`OriginalPrec`,`ApportionedPrec`,`LowerRange`,`UpperRange`)
            SELECT 
                 `key`
                ,`OriginalPrec`
                ,`ApportionedPrec`
                ,UpperRange as `LowerRange`
                ,UpperRange + `ApportionedPrec` AS `UpperRange`
            FROM temp_Perc
            LIMIT 1;

        END IF;

        SELECT UpperRange + `ApportionedPrec`
        INTO UpperRange
        FROM temp_Perc
        LIMIT 1;
        
        DELETE
        FROM temp_Perc
        LIMIT 1;

        SET `_counter` := `_counter` + 1;
    END WHILE;
    
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_resource_actual_quantity
    AS
    (
    SELECT
         T.`resource_id`
        ,SUM(actual_quantity) AS actual_quantity
    FROM `transactions` T
    INNER JOIN `scenarios` S
        ON S.`transaction_source_id` = T.`transaction_source_id`
    WHERE S.`id` = scenarioID
    AND T.`actual_completion_date` >= Min_Date
    AND T.`actual_completion_date` <= Max_Date
    GROUP BY
        T.`resource_id`
    );

    SELECT COUNT(1)
    INTO Count_Row_Number
    FROM temp_resource_actual_quantity;
    

    
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_resource_actual_quantity_rank
    AS
    (
    SELECT 
         @rownum := @rownum + 1 AS rank
        ,resource_id
        ,actual_quantity
        ,Count_Row_Number
        ,@rownum / Count_Row_Number AS prec
    FROM temp_resource_actual_quantity, 
       (SELECT @rownum := 0) r
    ORDER BY 
         actual_quantity
        ,resource_id
    );


    CREATE TABLE IF NOT EXISTS `resource_ParetoClassification`
    (
         `rank` VARCHAR(250) NOT NULL
        ,`value` VARCHAR(250) NOT NULL
    );

    SELECT *
    FROM temp_resource_actual_quantity_rank RR
    INNER JOIN temp_Perc_Split PS
        ON RR.prec BETWEEN PS.`LowerRange` AND PS.`UpperRange`;

END //
DELIMITER ;