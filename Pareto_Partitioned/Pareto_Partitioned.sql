
IF ((SELECT compatibility_level  
FROM sys.databases WHERE name = '<SQL_DataBase_Name,dbname, database_name>') < 110)
BEGIN
	ALTER DATABASE <SQL_DataBase_Name,dbname, database_name>   
	SET COMPATIBILITY_LEVEL = 110; 
END
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS ( SELECT *
                  FROM sys.objects o
                       INNER JOIN sys.schemas s
                               ON s.schema_id = o.schema_id
                 WHERE o.type = 'P'
                       AND o.name = 'Pareto_Partitioned'
                       AND s.name = '<SQL_DataBase_Schema,schemaname, schema_name>'
              ) 
    BEGIN
        EXEC ('CREATE PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.Pareto_Partitioned AS BEGIN SET NOCOUNT ON; END');
    END;
GO
ALTER PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.Pareto_Partitioned(
--DECLARE
	 @ExternalIDField	NVARCHAR(MAX)
	,@ExternalCodeField	NVARCHAR(MAX)
	,@ValueField		NVARCHAR(MAX)
	,@PartionGroupField	NVARCHAR(MAX)
	,@TableName			NVARCHAR(MAX)
	,@TopX				NVARCHAR(MAX) = ''
	,@PercentageSplit	VARCHAR(8000) = ''
	,@Delimiter			VARCHAR(8000) = ','
)
AS
BEGIN

	--DECLARE @PercentageSplit VARCHAR(8000) = '0.8,0.15,0.05',@Delimiter VARCHAR(8000) = ','
	
	DECLARE @SQL NVARCHAR(MAX) = ''
			,@NTILE INT = 3

	IF OBJECT_ID('TEMPDB..#PercentageSplit') IS NOT NULL
		DROP TABLE #PercentageSplit;

	CREATE TABLE #PercentageSplit(
									 ID					INT
									,Percentage			FLOAT
									,ProvidedPercentage FLOAT
									,LowerRange			FLOAT
									,UpperRange			FLOAT
								);

	;WITH Split(stpos,endpos)
    AS(
        SELECT 0 AS stpos, CHARINDEX(@Delimiter,@PercentageSplit) AS endpos
        UNION ALL
        SELECT endpos+1, CHARINDEX(@Delimiter,@PercentageSplit,endpos+1)
            FROM Split
            WHERE endpos > 0
    )
	INSERT INTO #PercentageSplit(ID 
								,Percentage
								)
    SELECT 'ID' = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
        'Percentage' = TRY_CONVERT(FLOAT,SUBSTRING(@PercentageSplit,stpos,COALESCE(NULLIF(endpos,0),LEN(@PercentageSplit)+1)-stpos))
    FROM SPLIT

	UPDATE PS
		SET PS.ProvidedPercentage = PS.Percentage
			,PS.Percentage = U.NewPercentage
	FROM #PercentageSplit PS
	INNER JOIN (
				SELECT 
						 ID
						,Percentage/SUM(Percentage) OVER (ORDER BY (SELECT 1)) AS NewPercentage
				FROM #PercentageSplit) AS U
	ON U.ID = PS.ID
    
	UPDATE PS
	SET PS.UpperRange = U.UpperRange
	--SELECT * 
	FROM #PercentageSplit PS
	INNER JOIN (SELECT 
					ID
				   ,SUM(Percentage) OVER (ORDER BY ID) AS UpperRange  
				FROM #PercentageSplit
				) AS U
	ON U.ID = PS.ID
	
    
	UPDATE PS
	SET PS.LowerRange = U.LowerRange
	--SELECT * 
	FROM #PercentageSplit PS
	INNER JOIN (	SELECT 
						ID
					   ,LAG(UpperRange, 1,0) OVER (ORDER BY ID) AS LowerRange
					FROM #PercentageSplit) AS U
	ON U.ID = PS.ID

	SET @NTILE = (SELECT MAX(ID) FROM #PercentageSplit)

	IF OBJECT_ID('TEMPDB..#Values') IS NOT NULL
		DROP TABLE #Values;

	CREATE TABLE #Values(
		 ID					BIGINT IDENTITY(1,1) PRIMARY KEY
		,ExternalID			BIGINT
		,ExternalCode		VARCHAR(8000)
		,Value				FLOAT
		,PartionGroup		VARCHAR(900)
		);
		
		SET @SQL = '
			SELECT '+@TopX+' 
			 CONVERT(FLOAT,'+@ExternalIDField+')
			,CONVERT(VARCHAR(8000),'+@ExternalCodeField+')
			,CONVERT(FLOAT,'+@ValueField+')
			,CONVERT(VARCHAR(900),'+@PartionGroupField+')
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

		CREATE NONCLUSTERED INDEX IX_#Values_PartionGroup ON #Values(PartionGroup);
		CREATE NONCLUSTERED INDEX IX_#Values_Value ON #Values(Value);
		
		
	--DECLARE @NTILE INT = 3

	IF OBJECT_ID('TEMPDB..#ValuesPercentageSplit') IS NOT NULL
		DROP TABLE #ValuesPercentageSplit;
	
	CREATE TABLE #ValuesPercentageSplit(
		 ID								BIGINT
		,ExternalID						BIGINT
		,ExternalCode					NVARCHAR(MAX)
		,Value							FLOAT
		,PartionGroup					NVARCHAR(MAX)
		,N_TILE							INT
		,RowNumber						INT
		,TotalCount						INT
		,PercentageOfValueByPartition	FLOAT
		);

	INSERT INTO #ValuesPercentageSplit(
										 ID
										,ExternalID
										,ExternalCode
										,Value
										,PartionGroup
										,N_TILE
										,RowNumber
										,TotalCount
										,PercentageOfValueByPartition
										)
	SELECT 
		 V.ID		
		,V.ExternalID
		,V.ExternalCode
		,V.Value
		,V.PartionGroup
		,NTILE(@NTILE) OVER (PARTITION BY V.PartionGroup ORDER BY V.Value) AS N_TILE
		,ROW_NUMBER() OVER (PARTITION BY V.PartionGroup ORDER BY V.Value) AS RowNumber
		,COUNT(1) OVER (PARTITION BY V.PartionGroup) AS TotalCount
		,TRY_CONVERT(FLOAT,ROW_NUMBER() OVER (PARTITION BY V.PartionGroup ORDER BY V.Value)) /TRY_CONVERT(FLOAT,COUNT(1) OVER (PARTITION BY V.PartionGroup)) AS PercentageOfValueByPartition
	FROM #Values V

	SELECT 
		 VPS.ID
		,VPS.ExternalID
		,VPS.ExternalCode
		,VPS.Value
		,VPS.PartionGroup
		,VPS.N_TILE
		,VPS.RowNumber
		,VPS.TotalCount
		,VPS.PercentageOfValueByPartition
		,PS.ID AS ParetoRank
		,PS.Percentage
		,PS.ProvidedPercentage
		,PS.LowerRange
		,PS.UpperRange
	FROM #ValuesPercentageSplit VPS
	INNER JOIN #PercentageSplit PS
		ON VPS.PercentageOfValueByPartition BETWEEN PS.LowerRange AND PS.UpperRange


END
GO