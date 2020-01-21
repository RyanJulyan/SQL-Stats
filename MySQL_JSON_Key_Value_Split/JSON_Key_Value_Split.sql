DROP PROCEDURE IF EXISTS JSON_Key_Value_Split;

DELIMITER //
CREATE PROCEDURE JSON_Key_Value_Split
(IN `json` JSON)
BEGIN

    DECLARE `json_items` BIGINT UNSIGNED DEFAULT JSON_LENGTH(`json`);
    DECLARE `_index` BIGINT UNSIGNED DEFAULT 0;

    DROP TEMPORARY TABLE IF EXISTS `jsonTemporary`;

    CREATE TEMPORARY TABLE IF NOT EXISTS `jsonTemporary`
    (
         `key` VARCHAR(250) NOT NULL
        ,`value` VARCHAR(250) NOT NULL
    );

    WHILE `_index` < `json_items` DO
        INSERT INTO `jsonTemporary` (`key`,`value`)
        VALUES (
             REPLACE(JSON_EXTRACT(`json`, CONCAT('$[', `_index`, '].key')), '"', '')
            ,REPLACE(JSON_EXTRACT(`json`, CONCAT('$[', `_index`, '].value')), '"', '')
        );
        SET `_index` := `_index` + 1;
    END WHILE;

    
    
    INSERT INTO temp_JSON_Key_Value_Split(
                                            `key`
                                            ,`value` 
                                            )
        SELECT 
             `key`
            ,`value` 
        FROM `jsonTemporary`;
    
    DROP TEMPORARY TABLE IF EXISTS `jsonTemporary`;

END //
DELIMITER ;