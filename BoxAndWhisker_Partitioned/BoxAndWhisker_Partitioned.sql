ALTER DATABASE <SQL_DataBase_Name,dbname, database_name>   
SET COMPATIBILITY_LEVEL = 110; 
GO

SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS ( SELECT *
                  FROM sys.objects o
                       INNER JOIN sys.schemas s
                               ON s.schema_id = o.schema_id
                 WHERE o.type = 'P'
                       AND o.name = 'BoxAndWhisker_Partitioned'
                       AND s.name = '<SQL_DataBase_Schema,schemaname, schema_name>'
              ) 
    BEGIN
        EXEC ('CREATE PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.BoxAndWhisker_Partitioned AS BEGIN SET NOCOUNT ON; END');
    END;
GO
ALTER PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.BoxAndWhisker_Partitioned(
--DECLARE
	 @ExternalIDField	NVARCHAR(MAX)
	,@ExternalCodeField	NVARCHAR(MAX)
	,@ValueField		NVARCHAR(MAX)
	,@PartionGroupField	NVARCHAR(MAX)
	,@TableName			NVARCHAR(MAX)
	,@TopX				NVARCHAR(MAX) = ''
)
AS
BEGIN

	DECLARE @SQL NVARCHAR(MAX) = ''

	IF OBJECT_ID('TEMPDB..#Values') IS NOT NULL
		DROP TABLE #Values;

	CREATE TABLE #Values(
		 ID					BIGINT IDENTITY(1,1) PRIMARY KEY
		,ExternalID			BIGINT
		,ExternalCode		NVARCHAR(MAX)
		,Value				FLOAT
		,PartionGroup		NVARCHAR(MAX)
		);
		
		SET @SQL = '
			SELECT '+@TopX+' 
			 CONVERT(FLOAT,'+@ExternalIDField+')
			,CONVERT(NVARCHAR(MAX),'+@ExternalCodeField+')
			,CONVERT(FLOAT,'+@ValueField+')
			,CONVERT(NVARCHAR(MAX),'+@PartionGroupField+')
		FROM '+@TableName+';
		';

		INSERT INTO #Values
				(
				  ExternalID ,
				  ExternalCode ,
				  Value ,
				  PartionGroup 
				)

		EXEC sp_ExecuteSQL @SQL

	SELECT 
		 V.ID		
		,V.ExternalID
		,V.ExternalCode
		,V.Value
		,V.PartionGroup
		,AVG(V.Value) OVER (PARTITION BY V.PartionGroup)  AS AVG_Value
		,STDEV(V.Value) OVER (PARTITION BY V.PartionGroup)  AS STDEV_Value
		,MIN(V.Value) OVER (PARTITION BY V.PartionGroup)  AS MIN_Value
		,PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) AS Q1_Cont
		,PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) AS Median_Cont
		,PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) AS Q3_Cont
		,(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) ) - (PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY V.Value) 
														OVER (PARTITION BY V.PartionGroup)) 
		 AS IQR_Cont
		,((PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) ) - (PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY V.Value) 
														OVER (PARTITION BY V.PartionGroup))) / (0.5*PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY V.Value) 
																										OVER (PARTITION BY V.PartionGroup))
		AS QCoeffDisp_Cont
		,PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) AS Q1_Disc
		,PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) AS Median_Disc
		,PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) AS Q3_Disc
		,(PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) ) - (PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY V.Value) 
														OVER (PARTITION BY V.PartionGroup)) 
		 AS IQR_Disc
		,((PERCENTILE_DISC(0.75) WITHIN GROUP (ORDER BY V.Value) 
			OVER (PARTITION BY V.PartionGroup) ) - (PERCENTILE_DISC(0.25) WITHIN GROUP (ORDER BY V.Value) 
														OVER (PARTITION BY V.PartionGroup))) / (0.5*PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY V.Value) 
																										OVER (PARTITION BY V.PartionGroup))
		AS QCoeffDisp_Disc
		,MAX(V.Value) OVER (PARTITION BY V.PartionGroup) AS MAX_Value
	FROM #Values V


END
GO