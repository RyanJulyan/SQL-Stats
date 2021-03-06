
IF ((SELECT compatibility_level  
FROM sys.databases WHERE name = '<SQL_DataBase_Name,dbname, database_name>') < 110)
BEGIN
	ALTER DATABASE <SQL_DataBase_Name,dbname, database_name>   
	SET COMPATIBILITY_LEVEL = 110; 
END

USE <SQL_DataBase_Name,dbname, database_name>
GO

SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS ( SELECT *
                  FROM sys.objects o
                       INNER JOIN sys.schemas s
                               ON s.schema_id = o.schema_id
                 WHERE o.type = 'P'
                       AND o.name = 'GeneralStats_Partitioned'
                       AND s.name = '<SQL_DataBase_Schema,schemaname, schema_name>'
              ) 
    BEGIN
        EXEC ('CREATE PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.GeneralStats_Partitioned AS BEGIN SET NOCOUNT ON; END');
    END;
GO
ALTER PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.GeneralStats_Partitioned(
--DECLARE
	 @ExternalIDField		NVARCHAR(128)
	,@ExternalCodeField		NVARCHAR(128)
	,@ValueField			NVARCHAR(128)
	,@IndependantValueField	NVARCHAR(128)
	,@PartionGroupField		NVARCHAR(128)
	,@TableName				NVARCHAR(128)
	,@TopX					NVARCHAR(128) = ''
	,@ErrorPercentage		FLOAT		  = 0.05
)
AS
BEGIN

	DECLARE @SQL NVARCHAR(MAX) = ''

	IF OBJECT_ID('TEMPDB..#Values') IS NOT NULL
		DROP TABLE #Values;

	CREATE TABLE #Values(
		 ID					BIGINT IDENTITY(1,1) PRIMARY KEY
		,ExternalID			BIGINT
		,ExternalCode		VARCHAR(8000)
		,Value				FLOAT
		,IndependantValue	FLOAT
		,PartionGroup		VARCHAR(900)
		);
		
		SET @SQL = '
			SELECT '+@TopX+' 
			 CONVERT(FLOAT,'+@ExternalIDField+')
			,CONVERT(VARCHAR(8000),'+@ExternalCodeField+')
			,CONVERT(FLOAT,'+@ValueField+')
			,CONVERT(FLOAT,'+@IndependantValueField+')
			,CONVERT(VARCHAR(900),'+@PartionGroupField+')
		FROM '+@TableName+';
		';

		INSERT INTO #Values
				(
				  ExternalID ,
				  ExternalCode ,
				  Value ,
				  IndependantValue ,
				  PartionGroup 
				)
		EXEC sp_ExecuteSQL @SQL

		CREATE NONCLUSTERED INDEX IX_#Values_PartionGroup ON #Values(PartionGroup);
		CREATE NONCLUSTERED INDEX IX_#Values_Value ON #Values(Value);
		CREATE NONCLUSTERED INDEX IX_#Values_IndependantValue ON #Values(IndependantValue);


	SELECT 
		 V.ID		
		,V.ExternalID
		,V.ExternalCode
		,V.Value
		,V.IndependantValue
		,V.PartionGroup
		,COUNT(V.Value) OVER (PARTITION BY V.PartionGroup) AS COUNT_Value
		,SUM(V.Value) OVER (PARTITION BY V.PartionGroup) AS SUM_Value
		,AVG(V.Value) OVER (PARTITION BY V.PartionGroup) AS AVG_Value
		,STDEV(V.Value) OVER (PARTITION BY V.PartionGroup) AS STDEV_Value
		,VAR(V.Value) OVER (PARTITION BY V.PartionGroup) AS VAR_Value
		,MIN(V.Value) OVER (PARTITION BY V.PartionGroup) AS MIN_Value
		,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) AS Median_Value_Cont
		,PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) AS Median_Value_Disc
		,MAX(V.Value) OVER (PARTITION BY V.PartionGroup) AS MAX_Value
		,V.Value - AVG(V.Value) OVER (PARTITION BY V.PartionGroup) / STDEV(V.Value) OVER (PARTITION BY V.PartionGroup) AS STANDARDIZED_Value

		,COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) AS COUNT_IndependantValue
		,SUM(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) AS SUM_IndependantValue
		,AVG(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) AS AVG_IndependantValue
		,STDEV(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) AS STDEV_IndependantValue
		,VAR(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) AS VAR_IndependantValue
		,MIN(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) AS MIN_IndependantValue
		,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY V.IndependantValue) 
			OVER (PARTITION BY V.PartionGroup) AS Median_IndependantValue_Cont
		,PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY V.IndependantValue) 
			OVER (PARTITION BY V.PartionGroup) AS Median_IndependantValue_Disc
		,MAX(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) AS MAX_IndependantValue
		,V.IndependantValue - AVG(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) / STDEV(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) AS STANDARDIZED_IndependantValue

		,((COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) * SUM(V.IndependantValue*V.Value) OVER (PARTITION BY V.PartionGroup) ) 
			- (SUM(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)*SUM(V.Value) OVER (PARTITION BY V.PartionGroup)) )
		/
		( (COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) * SUM(POWER(V.IndependantValue,2)) OVER (PARTITION BY V.PartionGroup)) 
			- (POWER(SUM(V.IndependantValue) OVER (PARTITION BY V.PartionGroup),2)) )
		AS Slope
		,(
			(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) * SUM(V.IndependantValue*V.Value) OVER (PARTITION BY V.PartionGroup))--((n*(SUM(X*Y)))
				- (SUM(V.IndependantValue)OVER (PARTITION BY V.PartionGroup)*SUM(V.Value)OVER (PARTITION BY V.PartionGroup))--((SUM(X)*SUM(Y))))
		)
		/
		(
			SQRT(
				(
					(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)  * (SUM(POWER(V.IndependantValue,2)) OVER (PARTITION BY V.PartionGroup) )) --(n*(SUM(POWER(X,2))))
						-(POWER(SUM(V.IndependantValue) OVER (PARTITION BY V.PartionGroup),2)) --(POWER(SUM(X),2))
				)
				*
				(
					(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)  * (SUM(POWER(V.Value,2)) OVER (PARTITION BY V.PartionGroup) )) --(n*(SUM(POWER(Y,2))))
						-(POWER(SUM(V.Value) OVER (PARTITION BY V.PartionGroup),2)) --(POWER(SUM(Y),2))
				)
			)
		)AS Pearson_R
		,POWER(
			(
			(
			(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) * SUM(V.IndependantValue*V.Value) OVER (PARTITION BY V.PartionGroup))--((n*(SUM(X*Y)))
					- (SUM(V.IndependantValue)OVER (PARTITION BY V.PartionGroup)*SUM(V.Value)OVER (PARTITION BY V.PartionGroup))--((SUM(X)*SUM(Y))))
			)
			/
			(
				SQRT(
					(
						(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)  * (SUM(POWER(V.IndependantValue,2)) OVER (PARTITION BY V.PartionGroup) )) --(n*(SUM(POWER(X,2))))
							-(POWER(SUM(V.IndependantValue) OVER (PARTITION BY V.PartionGroup),2)) --(POWER(SUM(X),2))
					)
					*
					(
						(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)  * (SUM(POWER(V.Value,2)) OVER (PARTITION BY V.PartionGroup) )) --(n*(SUM(POWER(Y,2))))
							-(POWER(SUM(V.Value) OVER (PARTITION BY V.PartionGroup),2)) --(POWER(SUM(Y),2))
					)
				)
			)
			)
		,2) AS Pearson_R_Sqrd
		,COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) - 2 AS DegOfFreedom
		,1-(@ErrorPercentage/2) AS ConfidenceLevel
		,(V.IndependantValue-AVG(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) ) / STDEV(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)  AS CriticalValue
		,(
			(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) * SUM(V.IndependantValue*V.Value) OVER (PARTITION BY V.PartionGroup))--((n*(SUM(X*Y)))
				- (SUM(V.IndependantValue)OVER (PARTITION BY V.PartionGroup)*SUM(V.Value)OVER (PARTITION BY V.PartionGroup))--((SUM(X)*SUM(Y))))
		)
		/
		(
			SQRT(
				(
					(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)  * (SUM(POWER(V.IndependantValue,2)) OVER (PARTITION BY V.PartionGroup) )) --(n*(SUM(POWER(X,2))))
						-(POWER(SUM(V.IndependantValue) OVER (PARTITION BY V.PartionGroup),2)) --(POWER(SUM(X),2))
				)
				*
				(
					(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)  * (SUM(POWER(V.Value,2)) OVER (PARTITION BY V.PartionGroup) )) --(n*(SUM(POWER(Y,2))))
						-(POWER(SUM(V.Value) OVER (PARTITION BY V.PartionGroup),2)) --(POWER(SUM(Y),2))
				)
			)
		)
		/
		SQRT(
		(1-(POWER(
			(
			(
			(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) * SUM(V.IndependantValue*V.Value) OVER (PARTITION BY V.PartionGroup))--((n*(SUM(X*Y)))
					- (SUM(V.IndependantValue)OVER (PARTITION BY V.PartionGroup)*SUM(V.Value)OVER (PARTITION BY V.PartionGroup))--((SUM(X)*SUM(Y))))
			)
			/
			(
				SQRT(
					(
						(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)  * (SUM(POWER(V.IndependantValue,2)) OVER (PARTITION BY V.PartionGroup) )) --(n*(SUM(POWER(X,2))))
							-(POWER(SUM(V.IndependantValue) OVER (PARTITION BY V.PartionGroup),2)) --(POWER(SUM(X),2))
					)
					*
					(
						(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup)  * (SUM(POWER(V.Value,2)) OVER (PARTITION BY V.PartionGroup) )) --(n*(SUM(POWER(Y,2))))
							-(POWER(SUM(V.Value) OVER (PARTITION BY V.PartionGroup),2)) --(POWER(SUM(Y),2))
					)
				)
			)
			)
		,2))/(COUNT(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) - 2)
		)
		) 
		AS t_value
		,CASE WHEN V.Value > STDEV(V.Value) OVER (PARTITION BY V.PartionGroup) 
			THEN 1
			ELSE
				0
		END AS Above_STDEV_Value
		,CASE WHEN V.IndependantValue > STDEV(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) 
			THEN 1
			ELSE
				0
		END AS Above_STDEV_IndependantValue
		,CASE WHEN V.Value > AVG(V.Value) OVER (PARTITION BY V.PartionGroup) 
			THEN 1
			ELSE
				0
		END AS Above_AVG_Value
		,CASE WHEN V.IndependantValue > AVG(V.IndependantValue) OVER (PARTITION BY V.PartionGroup) 
			THEN 1
			ELSE
				0
		END AS Above_AVG_IndependantValue
	FROM #Values V

END
GO