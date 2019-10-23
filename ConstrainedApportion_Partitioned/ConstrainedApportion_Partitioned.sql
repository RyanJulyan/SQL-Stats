
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
                       AND o.name = 'ConstrainedApportion_Partitioned'
                       AND s.name = '<SQL_DataBase_Schema,schemaname, schema_name>'
              ) 
    BEGIN
        EXEC ('CREATE PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.ConstrainedApportion_Partitioned AS BEGIN SET NOCOUNT ON; END');
    END;
GO
ALTER PROCEDURE <SQL_DataBase_Schema,schemaname, schema_name>.ConstrainedApportion_Partitioned(
--DECLARE
	 @ExternalIDField		NVARCHAR(128)
	,@ExternalCodeField		NVARCHAR(128)
	,@ValueField			NVARCHAR(128)
	,@MinValueField			NVARCHAR(128)
	,@MaxValueField			NVARCHAR(128)
	,@TotalAvailableField	NVARCHAR(128)
	,@RoundingField			NVARCHAR(128)
	,@PartionGroupField		NVARCHAR(128)
	,@TableName				NVARCHAR(128)
	,@TopX					NVARCHAR(128) = ''
	,@bRoundUp				BIT = 0
	,@bRoundDown			BIT = 0
	,@bRoundClosest			BIT = 0
)
AS
BEGIN
	
	DECLARE @SQL NVARCHAR(MAX) = ''
			
	IF OBJECT_ID('TEMPDB..#Values') IS NOT NULL
		DROP TABLE #Values;

	CREATE TABLE #Values(
		 ID					BIGINT IDENTITY(1,1) PRIMARY KEY NOT NULL
		,ExternalID			BIGINT NOT NULL
		,ExternalCode		VARCHAR(8000) NOT NULL
		,Value				DECIMAL(38, 19) NOT NULL
		,MinValue			DECIMAL(38, 19) NOT NULL
		,MaxValue			DECIMAL(38, 19) NOT NULL
		,TotalAvailable		DECIMAL(38, 19) NOT NULL
		,Rounding			DECIMAL(38, 19) NOT NULL
		,PartionGroup		VARCHAR(600) NOT NULL
		);
			
	IF OBJECT_ID('TEMPDB..#NewContributionValues') IS NOT NULL
		DROP TABLE #NewContributionValues;

	CREATE TABLE #NewContributionValues(
		 ID															BIGINT IDENTITY(1,1) PRIMARY KEY NOT NULL
		,ExternalID													BIGINT NOT NULL
		,ExternalCode												VARCHAR(8000) NOT NULL
		,Value														DECIMAL(38, 19) NOT NULL
		,MinValue													DECIMAL(38, 19) NOT NULL
		,MaxValue													DECIMAL(38, 19) NOT NULL
		,TotalAvailable												DECIMAL(38, 19) NOT NULL
		,Rounding													DECIMAL(38, 19) NOT NULL
		,PartionGroup												VARCHAR(600) NOT NULL
		,TotalValue													DECIMAL(38, 19) NOT NULL
		,PercentageContribution										DECIMAL(38, 19) NOT NULL
		,SuggestedNewContribution									DECIMAL(38, 19) NOT NULL
		,ConstrainedSuggestedNewContribution						DECIMAL(38, 19)	NOT NULL
		--,AmountNeededTosubtractFromRoundingForAddingToContribution	DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedDownToRounding				DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedUpToRounding				DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedClosestToRounding			DECIMAL(38, 19)	NOT NULL
		);
			
	IF OBJECT_ID('TEMPDB..#OverNewContributionValues') IS NOT NULL
		DROP TABLE #OverNewContributionValues;

	CREATE TABLE #OverNewContributionValues(
		 ID																			BIGINT IDENTITY(1,1) PRIMARY KEY NOT NULL
		,ExternalID																	BIGINT NOT NULL
		,ExternalCode																VARCHAR(8000) NOT NULL
		,Value																		DECIMAL(38, 19) NOT NULL
		,MinValue																	DECIMAL(38, 19) NOT NULL
		,MaxValue																	DECIMAL(38, 19) NOT NULL
		,TotalAvailable																DECIMAL(38, 19) NOT NULL
		,Rounding																	DECIMAL(38, 19) NOT NULL
		,PartionGroup																VARCHAR(600) NOT NULL
		,TotalValue																	DECIMAL(38, 19) NOT NULL
		,PercentageContribution														DECIMAL(38, 19) NOT NULL
		,SuggestedNewContribution													DECIMAL(38, 19) NOT NULL
		,ConstrainedSuggestedNewContribution										DECIMAL(38, 19)	NOT NULL
		--,AmountNeededTosubtractFromRoundingForAddingToContribution					DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedDownToRounding								DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedUpToRounding								DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedClosestToRounding							DECIMAL(38, 19)	NOT NULL
		,Rounding_RunningTotal_ToAdd												DECIMAL(38, 19) NOT NULL
		,Rounding_RunningTotal_ToSubtract											DECIMAL(38, 19) NOT NULL
		,ConstrainedSuggestedNewContribution_Over									DECIMAL(38, 19) NOT NULL
		,SuggestedNewContributionRoundedDownToRounding_Over							DECIMAL(38, 19) NOT NULL
		,SuggestedNewContributionRoundedUpToRounding_Over							DECIMAL(38, 19) NOT NULL
		,SuggestedNewContributionRoundedClosestToRounding_Over						DECIMAL(38, 19) NOT NULL
		,ConstrainedSuggestedNewContribution_OverConstrainedToRounding				DECIMAL(38, 19) DEFAULT 0
		,SuggestedNewContributionRoundedDownToRounding_OverConstrainedToRounding	DECIMAL(38, 19) DEFAULT 0
		,SuggestedNewContributionRoundedUpToRounding_OverConstrainedToRounding		DECIMAL(38, 19) DEFAULT 0
		,SuggestedNewContributionRoundedClosestToRounding_OverConstrainedToRounding DECIMAL(38, 19) DEFAULT 0
		);

		
		SET @SQL = '
			SELECT '+@TopX+' 
			 TRY_CONVERT(DECIMAL(38, 19),'+@ExternalIDField+')
			,TRY_CONVERT(VARCHAR(8000),'+@ExternalCodeField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@ValueField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@MinValueField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@MaxValueField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@TotalAvailableField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@RoundingField+')
			,TRY_CONVERT(VARCHAR(900),'+@PartionGroupField+')
		FROM '+@TableName+';
		';

		INSERT INTO #Values
				(
				  ExternalID ,
				  ExternalCode ,
				  Value ,
				  MinValue ,
				  MaxValue ,
				  TotalAvailable ,
				  Rounding ,
				  PartionGroup 
				)
		EXEC sp_ExecuteSQL @SQL
		

		CREATE NONCLUSTERED INDEX IX_#Values_PartionGroup ON #Values(PartionGroup);
		CREATE NONCLUSTERED INDEX IX_#Values_Value ON #Values(Value);
		
		INSERT INTO #NewContributionValues(
											 ExternalID
											,ExternalCode
											,Value
											,MinValue
											,MaxValue
											,TotalAvailable
											,Rounding
											,PartionGroup
											,TotalValue
											,PercentageContribution
											,SuggestedNewContribution
											,ConstrainedSuggestedNewContribution
											,SuggestedNewContributionRoundedDownToRounding
											,SuggestedNewContributionRoundedUpToRounding
											,SuggestedNewContributionRoundedClosestToRounding
											)
		SELECT 
			 V.ExternalID
			,V.ExternalCode
			,V.Value
			,V.MinValue
			,V.MaxValue
			,V.TotalAvailable
			,V.Rounding
			,V.PartionGroup
			,SUM(V.Value) OVER (PARTITION BY V.PartionGroup) AS TotalValue
			,(V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup)) AS PercentageContribution
			,(V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable AS SuggestedNewContribution
			,
			CASE WHEN (V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable <= V.Value
				THEN (V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable
			ELSE
				V.Value
			END AS ConstrainedSuggestedNewContribution
			,CASE WHEN @bRoundDown = 1
				THEN 
					((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)+(-((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%V.Rounding)
				ELSE 0
			 END AS SuggestedNewContributionRoundedDownToRounding
			,CASE WHEN @bRoundUp = 1
				THEN
					((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)+(V.Rounding-((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%V.Rounding) 
				ELSE 0
			 END AS SuggestedNewContributionRoundedUpToRounding
			,CASE WHEN @bRoundClosest = 1
				THEN
					CASE WHEN CONVERT(DECIMAL(38, 19),((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%CONVERT(DECIMAL(38, 19), V.Rounding)) / V.Rounding > 0.5
						THEN ((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)+(V.Rounding-((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%V.Rounding)
					 ELSE
						((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)+(-((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%V.Rounding)
					END 
				ELSE 0
				END AS SuggestedNewContributionRoundedClosestToRounding
		FROM #Values V

		CREATE NONCLUSTERED INDEX IX_#NewContributionValues_MinValue ON #NewContributionValues(MinValue);
		CREATE NONCLUSTERED INDEX IX_#NewContributionValues_MaxValue ON #NewContributionValues(MaxValue);
		
		IF((SELECT SUM(CV.MinValue) FROM #NewContributionValues CV) IS NOT NULL)
		BEGIN
			
			UPDATE CV
			SET 
				--MinValue
				ConstrainedSuggestedNewContribution = CASE WHEN (CV.ConstrainedSuggestedNewContribution < CV.MinValue)
														THEN CV.MinValue
														ELSE
															CV.ConstrainedSuggestedNewContribution
													 END
				,SuggestedNewContributionRoundedDownToRounding = CASE WHEN (CV.SuggestedNewContributionRoundedDownToRounding < (CV.MinValue+(CV.Rounding-(CV.MinValue%CV.Rounding))))
																	THEN CV.MinValue+(CV.Rounding-(CV.MinValue%CV.Rounding))
																	ELSE
																		CV.SuggestedNewContributionRoundedDownToRounding
																 END
				,SuggestedNewContributionRoundedUpToRounding = CASE WHEN (CV.SuggestedNewContributionRoundedUpToRounding < (CV.MinValue+(CV.Rounding-(CV.MinValue%CV.Rounding))))
																	THEN CV.MinValue+(CV.Rounding-(CV.MinValue%CV.Rounding))
																	ELSE
																		CV.SuggestedNewContributionRoundedUpToRounding
																 END
				,SuggestedNewContributionRoundedClosestToRounding = CASE WHEN (CV.SuggestedNewContributionRoundedClosestToRounding < (CV.MinValue+(CV.Rounding-(CV.MinValue%CV.Rounding))))
																		THEN CV.MinValue+(CV.Rounding-(CV.MinValue%CV.Rounding))
																		ELSE
																			CV.SuggestedNewContributionRoundedClosestToRounding
																	 END
			FROM #NewContributionValues CV

		END

		IF((SELECT SUM(CV.MAXVALUE) FROM #NewContributionValues CV) IS NOT NULL)
		BEGIN

			UPDATE CV
			SET 
				--MaxValue
				ConstrainedSuggestedNewContribution = CASE WHEN (CV.ConstrainedSuggestedNewContribution > CV.MaxValue)
														THEN CV.MaxValue
														ELSE
															CV.ConstrainedSuggestedNewContribution
													 END
				,SuggestedNewContributionRoundedDownToRounding = CASE WHEN (CV.SuggestedNewContributionRoundedDownToRounding > CV.MaxValue)
																	THEN CV.MaxValue+(-(CV.MaxValue%CV.Rounding))
																	ELSE
																		CV.SuggestedNewContributionRoundedDownToRounding
																 END
				,SuggestedNewContributionRoundedUpToRounding = CASE WHEN (CV.SuggestedNewContributionRoundedUpToRounding > CV.MaxValue)
																	THEN CV.MaxValue+(-(CV.MaxValue%CV.Rounding))
																	ELSE
																		CV.SuggestedNewContributionRoundedUpToRounding
																 END
				,SuggestedNewContributionRoundedClosestToRounding = CASE WHEN (CV.SuggestedNewContributionRoundedClosestToRounding > CV.MaxValue)
																	THEN CV.MaxValue+(-(CV.MaxValue%CV.Rounding))
																	ELSE
																		CV.SuggestedNewContributionRoundedUpToRounding
																 END
			FROM #NewContributionValues CV
		
		END

		INSERT INTO #OverNewContributionValues
		        (  ExternalID
		          ,ExternalCode
		          ,Value
		          ,MinValue
		          ,MaxValue
		          ,TotalAvailable
		          ,Rounding
		          ,PartionGroup
		          ,TotalValue
		          ,PercentageContribution
		          ,SuggestedNewContribution
		          ,ConstrainedSuggestedNewContribution
		          --,AmountNeededTosubtractFromRoundingForAddingToContribution
		          ,SuggestedNewContributionRoundedDownToRounding
		          ,SuggestedNewContributionRoundedUpToRounding
		          ,SuggestedNewContributionRoundedClosestToRounding
		          ,Rounding_RunningTotal_ToAdd
		          ,Rounding_RunningTotal_ToSubtract
		          ,ConstrainedSuggestedNewContribution_Over
		          ,SuggestedNewContributionRoundedDownToRounding_Over
		          ,SuggestedNewContributionRoundedUpToRounding_Over
		          ,SuggestedNewContributionRoundedClosestToRounding_Over
		        )
		SELECT 
			 ExternalID
			,ExternalCode
			,Value
			,MinValue
			,MaxValue
			,TotalAvailable
			,Rounding
			,PartionGroup
			,TotalValue
			,PercentageContribution
			,SuggestedNewContribution
			,ConstrainedSuggestedNewContribution
			--,AmountNeededTosubtractFromRoundingForAddingToContribution
			,SuggestedNewContributionRoundedDownToRounding
			,SuggestedNewContributionRoundedUpToRounding
			,SuggestedNewContributionRoundedClosestToRounding
			,SUM(NCV.Rounding) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value DESC) Rounding_RunningTotal_ToAdd
			,SUM(NCV.Rounding) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value ASC) Rounding_RunningTotal_ToSubtract
			,NCV.TotalAvailable - SUM(NCV.ConstrainedSuggestedNewContribution) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value DESC)  AS ConstrainedSuggestedNewContribution_Over
			,NCV.TotalAvailable - SUM(NCV.SuggestedNewContributionRoundedDownToRounding) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value DESC)  AS SuggestedNewContributionRoundedDownToRounding_Over
			,NCV.TotalAvailable - SUM(NCV.SuggestedNewContributionRoundedUpToRounding) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value DESC)  AS SuggestedNewContributionRoundedUpToRounding_Over
			,NCV.TotalAvailable - SUM(NCV.SuggestedNewContributionRoundedClosestToRounding) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value ASC)  AS SuggestedNewContributionRoundedClosestToRounding_Over
		FROM #NewContributionValues NCV

		-- Add Rounding to ConstrainedSuggestedNewContribution
		UPDATE FP
			SET
			ConstrainedSuggestedNewContribution_OverConstrainedToRounding = ConstrainedSuggestedNewContribution+Rounding
		FROM #OverNewContributionValues FP
		WHERE Rounding_RunningTotal_ToAdd <= ConstrainedSuggestedNewContribution_Over

		-- Add Rounding to SuggestedNewContributionRoundedDownToRounding
		UPDATE FP
			SET
			SuggestedNewContributionRoundedDownToRounding_OverConstrainedToRounding = SuggestedNewContributionRoundedDownToRounding+Rounding
		FROM #OverNewContributionValues FP
		WHERE Rounding_RunningTotal_ToAdd <= SuggestedNewContributionRoundedDownToRounding_Over

		-- Subtract Rounding FROM SuggestedNewContributionRoundedUpToRounding
		UPDATE FP
			SET
			SuggestedNewContributionRoundedUpToRounding_OverConstrainedToRounding = SuggestedNewContributionRoundedUpToRounding-Rounding
		FROM #OverNewContributionValues FP
		WHERE Rounding_RunningTotal_ToSubtract < SuggestedNewContributionRoundedUpToRounding_Over

		SELECT 
			 ONCV.ID
			,ONCV.ExternalID
			,ONCV.ExternalCode
			,ONCV.Value
			,ONCV.MinValue
			,ONCV.MaxValue
			,ONCV.TotalAvailable
			,ONCV.Rounding
			,ONCV.PartionGroup
			,ONCV.TotalValue
			,ONCV.PercentageContribution
			,ONCV.SuggestedNewContribution
			,ONCV.ConstrainedSuggestedNewContribution
			--,ONCV.AmountNeededTosubtractFromRoundingForAddingToContribution
			,ONCV.SuggestedNewContributionRoundedDownToRounding
			,ONCV.SuggestedNewContributionRoundedUpToRounding
			,ONCV.SuggestedNewContributionRoundedClosestToRounding
			,ONCV.Rounding_RunningTotal_ToAdd
			,ONCV.Rounding_RunningTotal_ToSubtract
			,ONCV.ConstrainedSuggestedNewContribution_Over
			,ONCV.SuggestedNewContributionRoundedDownToRounding_Over
			,ONCV.SuggestedNewContributionRoundedUpToRounding_Over
			,ONCV.SuggestedNewContributionRoundedClosestToRounding_Over
			,ONCV.ConstrainedSuggestedNewContribution_OverConstrainedToRounding
			,ONCV.SuggestedNewContributionRoundedDownToRounding_OverConstrainedToRounding
			,ONCV.SuggestedNewContributionRoundedUpToRounding_OverConstrainedToRounding
			,ONCV.SuggestedNewContributionRoundedClosestToRounding_OverConstrainedToRounding
		FROM #OverNewContributionValues ONCV
		--WHERE ONCV.PartionGroup = 1
		--ORDER BY ONCV.PartionGroup, ONCV.Value DESC

END
GO