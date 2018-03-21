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
                       AND o.name = 'KMeansCluster_Partitioned'
                       AND s.name = '<SQL_DataBase_Schema,schemaname, schema_name>'
              ) 
    BEGIN
        EXEC ('CREATE PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.KMeansCluster_Partitioned AS BEGIN SET NOCOUNT ON; END');
    END;
GO
ALTER PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.KMeansCluster_Partitioned(
	--DECLARE 
	 @ExternalIDField		NVARCHAR(MAX) = ''
	,@ExternalCodeField		NVARCHAR(MAX) = ''
	,@ValueField			NVARCHAR(MAX) = ''
	,@IndependantValueField	NVARCHAR(MAX) = ''
	,@PartionGroupField		NVARCHAR(MAX) = ''
	,@TableName				NVARCHAR(MAX) = ''
	,@TopX					NVARCHAR(MAX) = ''
	,@GroupingSplit			VARCHAR(8000) = 'A,B,C'
	,@Delimiter				VARCHAR(8000) = ','
)
AS
BEGIN

	DECLARE  @SQL			NVARCHAR(MAX) = ''
			,@NTILE			NVARCHAR(MAX) = '3'
			,@LoopCounter	INT = 1
			,@LoopMax		INT

	IF OBJECT_ID('TEMPDB..#Centoids') IS NOT NULL
		DROP TABLE #Centoids;

	CREATE TABLE #Centoids(
		 CentoidID		INT NOT NULL
		,CentoidName	NVARCHAR(MAX)  NOT NULL
	)

	;WITH Centoids(stpos,endpos)
    AS(
        SELECT 0 AS stpos, CHARINDEX(@Delimiter,@GroupingSplit) AS endpos
        UNION ALL
        SELECT endpos+1, CHARINDEX(@Delimiter,@GroupingSplit,endpos+1)
        FROM Centoids
        WHERE endpos > 0
    )
	INSERT INTO #Centoids(CentoidID 
								,CentoidName
								)
    SELECT 'CentoidID' = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
        'CentoidName' = TRY_CONVERT(NVARCHAR(MAX),SUBSTRING(@GroupingSplit,stpos,COALESCE(NULLIF(endpos,0),LEN(@GroupingSplit)+1)-stpos))
    FROM Centoids

	SET @NTILE = CONVERT(NVARCHAR(MAX),(SELECT MAX(CentoidID) FROM #Centoids))

	IF OBJECT_ID('TEMPDB..#Values') IS NOT NULL
		DROP TABLE #Values;

	CREATE TABLE #Values(
		 ID							BIGINT IDENTITY(1,1) PRIMARY KEY
		,ExternalID					BIGINT
		,ExternalCode				NVARCHAR(MAX)
		,Value						FLOAT
		,IndependantValue			FLOAT
		,PartionGroup				NVARCHAR(MAX)
		,CentoidID					INT
		,Itteration					INT
		);
		
		SET @SQL = '
			SELECT '+@TopX+' 
			 CONVERT(FLOAT,'+@ExternalIDField+')
			,CONVERT(NVARCHAR(MAX),'+@ExternalCodeField+')
			,CONVERT(FLOAT,'+@ValueField+')
			,CONVERT(FLOAT,'+@IndependantValueField+')
			,CONVERT(NVARCHAR(MAX),'+@PartionGroupField+')
			,NTILE('+@NTILE+') OVER (PARTITION BY '+@PartionGroupField+' ORDER BY '+@ValueField+', '+@IndependantValueField+')
			,'+CONVERT(NVARCHAR(MAX),@LoopCounter)+'
		FROM '+@TableName+';
		';

		INSERT INTO #Values
				(
				  ExternalID ,
				  ExternalCode ,
				  Value ,
				  IndependantValue ,
				  PartionGroup ,
				  CentoidID ,
				  Itteration
				)
		EXEC sp_ExecuteSQL @SQL;
		
		IF OBJECT_ID('TEMPDB..#CentoidsPartionGroup') IS NOT NULL
			DROP TABLE #CentoidsPartionGroup;

		SELECT 
			 V.CentoidID
			,V.PartionGroup
			,C.CentoidName
			,CONVERT(FLOAT,0.0) AS CentoidValueX
			,CONVERT(FLOAT,0.0) AS CentoidValueY
		INTO #CentoidsPartionGroup
		FROM #Values V
		INNER JOIN #Centoids C
			ON C.CentoidID = V.CentoidID
		GROUP BY
			 V.CentoidID
			,V.PartionGroup
			,C.CentoidName

			

	IF OBJECT_ID('TEMPDB..#ValuesCentoidsPartionGroup_Assign') IS NOT NULL
		DROP TABLE #ValuesCentoidsPartionGroup_Assign;

	CREATE TABLE #ValuesCentoidsPartionGroup_Assign(
		 ID							BIGINT
		,ExternalID					BIGINT
		,ExternalCode				NVARCHAR(MAX)
		,Value						FLOAT
		,IndependantValue			FLOAT
		,PartionGroup				NVARCHAR(MAX)
		,OLD_CentoidID				INT
		,CentoidID					INT
		,MIN_DistanceRow			BIT
		);

	SET @LoopMax = (SELECT MAX(Count_PartionGroup)
					FROM (
							SELECT COUNT(1) Count_PartionGroup
							FROM #Values
							GROUP BY PartionGroup
						) M)

	WHILE @LoopCounter <= @LoopMax
	BEGIN

		UPDATE C
			SET
				 C.CentoidValueX = U.AVG_Value
				,C.CentoidValueY = U.AVG_IndependantValue
		FROM #CentoidsPartionGroup C
		INNER JOIN (
					SELECT 
						 V.CentoidID
						,V.PartionGroup
						,AVG(V.Value) AS AVG_Value
						,AVG(V.IndependantValue) AS AVG_IndependantValue
					FROM #Values V
					INNER JOIN #CentoidsPartionGroup CP
						ON CP.CentoidID = V.CentoidID
						AND CP.PartionGroup = V.PartionGroup
					GROUP BY
						 V.CentoidID 
						,V.PartionGroup
						) U
			ON U.CentoidID = C.CentoidID
			AND U.PartionGroup = C.PartionGroup

		TRUNCATE TABLE #ValuesCentoidsPartionGroup_Assign

		INSERT INTO #ValuesCentoidsPartionGroup_Assign
		        ( ID ,
				  ExternalID ,
		          ExternalCode ,
		          Value ,
		          IndependantValue ,
		          PartionGroup ,
		          CentoidID ,
				  OLD_CentoidID ,
		          MIN_DistanceRow
		        )
		SELECT  
			 ID
			,V.ExternalID
			,V.ExternalCode
			,V.Value
			,V.IndependantValue
			,V.PartionGroup
			,V.CentoidID AS OLD_CentoidID
			,CP.CentoidID
			,CASE WHEN MIN(POWER((V.Value - CP.CentoidValueX),2) + POWER((V.IndependantValue - CP.CentoidValueY),2)) OVER (PARTITION BY V.PartionGroup, V.ExternalID) = POWER((V.Value - CP.CentoidValueX),2) + POWER((V.IndependantValue - CP.CentoidValueY),2)
				THEN 1
				ELSE
					0
			 END AS MIN_DistanceRow
			--,POWER((V.Value - CP.CentoidValueX),2) AS ValueDistanceFromCentoidValueX
			--,MIN(POWER((V.Value - CP.CentoidValueX),2)) OVER (PARTITION BY V.PartionGroup, V.ExternalID) AS Min_ValueDistanceFromCentoidValueX
			--,POWER((V.IndependantValue - CP.CentoidValueY),2) AS IndependantValueDistanceFromCentoidValueY
			--,MIN(POWER((V.IndependantValue - CP.CentoidValueY),2)) OVER (PARTITION BY V.PartionGroup, V.ExternalID) AS Min_IndependantValueDistanceFromCentoidValueY
			--,CASE WHEN MIN(POWER((V.Value - CP.CentoidValueX),2)) OVER (PARTITION BY V.PartionGroup, V.ExternalID) = POWER((V.Value - CP.CentoidValueX),2)
			--	THEN 1
			--	ELSE
			--		0
			-- END AS Min_ValueDistanceFromCentoidValueX_Row
			--,CASE WHEN MIN(POWER((V.IndependantValue - CP.CentoidValueY),2)) OVER (PARTITION BY V.PartionGroup, V.ExternalID) = POWER((V.IndependantValue - CP.CentoidValueY),2)
			--	THEN 1
			--	ELSE
			--		0
			-- END AS Min_IndependantValueDistanceFromCentoidValueY_Row
			--,POWER((V.Value - CP.CentoidValueX),2) + POWER((V.IndependantValue - CP.CentoidValueY),2) AS ValueDistanceFromCentoidValueX_IndependantValueDistanceFromCentoidValueY
			--,MIN(POWER((V.Value - CP.CentoidValueX),2) + POWER((V.IndependantValue - CP.CentoidValueY),2)) OVER (PARTITION BY V.PartionGroup, V.ExternalID) AS MIN_ValueDistanceFromCentoidValueX_IndependantValueDistanceFromCentoidValueY
			--,CASE WHEN MIN(POWER((V.Value - CP.CentoidValueX),2) + POWER((V.IndependantValue - CP.CentoidValueY),2)) OVER (PARTITION BY V.PartionGroup, V.ExternalID) = POWER((V.Value - CP.CentoidValueX),2) + POWER((V.IndependantValue - CP.CentoidValueY),2)
			--	THEN 1
			--	ELSE
			--		0
			-- END AS MIN_ValueDistanceFromCentoidValueX_IndependantValueDistanceFromCentoidValueY_Row
			--,*
		FROM #Values V
		INNER JOIN #CentoidsPartionGroup CP
			ON CP.PartionGroup = V.PartionGroup

		SET @LoopCounter = @LoopCounter + 1

		UPDATE V
			SET
				V.CentoidID = VP.CentoidID 
				,V.Itteration = @LoopCounter
		FROM #Values V
		INNER JOIN #ValuesCentoidsPartionGroup_Assign VP
			ON VP.ID = V.ID
		WHERE VP.MIN_DistanceRow = 1
	
	END

		SELECT 
				V.ID
               ,V.ExternalID
               ,V.ExternalCode
               ,V.Value
               ,V.IndependantValue
               ,V.PartionGroup
               ,V.CentoidID 
			   ,V.Itteration
			   ,C.CentoidName
		FROM #Values V
		INNER JOIN #Centoids C
			ON C.CentoidID = V.CentoidID

END