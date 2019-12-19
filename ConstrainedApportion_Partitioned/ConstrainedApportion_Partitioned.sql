
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
	,@OrderMultipleField	NVARCHAR(128)
	,@PartionGroupField		NVARCHAR(128)
	,@TableName				NVARCHAR(128)
	,@TopX					NVARCHAR(128) = ''
	,@bRoundUp				BIT = 0
	,@bRoundDown			BIT = 1
	,@bRoundClosest			BIT = 0
	,@bSaveToTable			BIT = 1
	,@bTruncateSaveTable	BIT = 1
)
AS
BEGIN
	
	DECLARE @SQL NVARCHAR(MAX) = ''

	IF(@bSaveToTable = 1)
	BEGIN
		IF NOT EXISTS ( SELECT *
						FROM sys.objects o
							INNER JOIN sys.schemas s
									ON s.schema_id = o.schema_id
						WHERE o.name = 'ConstrainedApportion_Partitioned_ROQ'
							AND s.name = '<SQL_DataBase_Schema,schemaname, schema_name>'
					) 
		BEGIN
			
			CREATE TABLE <SQL_DataBase_Schema,schemaname, schema_name>.ConstrainedApportion_Partitioned_ROQ(
				ID																						BIGINT PRIMARY KEY NOT NULL
				,ExternalID																				BIGINT NOT NULL
				,ExternalCode																			VARCHAR(8000) NOT NULL
				,Value																					DECIMAL(38, 19) NOT NULL
				,MinValue																				DECIMAL(38, 19) NOT NULL
				,MaxValue																				DECIMAL(38, 19) NOT NULL
				,TotalAvailable																			DECIMAL(38, 19) NOT NULL
				,OrderMultiple																			DECIMAL(38, 19) NOT NULL
				,PartionGroup																			VARCHAR(600) NOT NULL
				,TotalValue																				DECIMAL(38, 19) NOT NULL
				,PercentageContribution																	DECIMAL(38, 19) NOT NULL
				,SuggestedNewContribution																DECIMAL(38, 19) NOT NULL
				,ConstrainedSuggestedNewContribution													DECIMAL(38, 19)	NOT NULL
				--,AmountNeededTosubtractFromOrderMultipleForAddingToContribution							DECIMAL(38, 19)	NOT NULL
				,SuggestedNewContributionRoundedDownToOrderMultiple										DECIMAL(38, 19)	NOT NULL
				,SuggestedNewContributionRoundedUpToOrderMultiple										DECIMAL(38, 19)	NOT NULL
				,SuggestedNewContributionRoundedClosestToOrderMultiple									DECIMAL(38, 19)	NOT NULL
				,OrderMultiple_RunningTotal_ToAdd														DECIMAL(38, 19) NOT NULL
				,OrderMultiple_RunningTotal_ToSubtract													DECIMAL(38, 19) NOT NULL
				,ConstrainedSuggestedNewContribution_Over												DECIMAL(38, 19) NOT NULL
				,SuggestedNewContributionRoundedDownToOrderMultiple_Over								DECIMAL(38, 19) NOT NULL
				,SuggestedNewContributionRoundedUpToOrderMultiple_Over									DECIMAL(38, 19) NOT NULL
				,SuggestedNewContributionRoundedClosestToOrderMultiple_Over								DECIMAL(38, 19) NOT NULL
				,ConstrainedSuggestedNewContribution_OverConstrainedToOrderMultiple						DECIMAL(38, 19) DEFAULT 0
				,SuggestedNewContributionRoundedDownToOrderMultiple_OverConstrainedToOrderMultiple		DECIMAL(38, 19) DEFAULT 0
				,SuggestedNewContributionRoundedUpToOrderMultiple_OverConstrainedToOrderMultiple		DECIMAL(38, 19) DEFAULT 0
				,SuggestedNewContributionRoundedClosestToOrderMultiple_OverConstrainedToOrderMultiple	DECIMAL(38, 19) DEFAULT 0
				);
		END;
	END
			
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
		,OrderMultiple		DECIMAL(38, 19) NOT NULL
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
		,OrderMultiple												DECIMAL(38, 19) NOT NULL
		,PartionGroup												VARCHAR(600) NOT NULL
		,TotalValue													DECIMAL(38, 19) NOT NULL
		,PercentageContribution										DECIMAL(38, 19) NOT NULL
		,SuggestedNewContribution									DECIMAL(38, 19) NOT NULL
		,ConstrainedSuggestedNewContribution						DECIMAL(38, 19)	NOT NULL
		--,AmountNeededTosubtractFromOrderMultipleForAddingToContribution	DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedDownToOrderMultiple			DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedUpToOrderMultiple			DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedClosestToOrderMultiple		DECIMAL(38, 19)	NOT NULL
		);
			
	IF OBJECT_ID('TEMPDB..#OverNewContributionValues') IS NOT NULL
		DROP TABLE #OverNewContributionValues;

	CREATE TABLE #OverNewContributionValues(
		 ID																						BIGINT IDENTITY(1,1) PRIMARY KEY NOT NULL
		,ExternalID																				BIGINT NOT NULL
		,ExternalCode																			VARCHAR(8000) NOT NULL
		,Value																					DECIMAL(38, 19) NOT NULL
		,MinValue																				DECIMAL(38, 19) NOT NULL
		,MaxValue																				DECIMAL(38, 19) NOT NULL
		,TotalAvailable																			DECIMAL(38, 19) NOT NULL
		,OrderMultiple																			DECIMAL(38, 19) NOT NULL
		,PartionGroup																			VARCHAR(600) NOT NULL
		,TotalValue																				DECIMAL(38, 19) NOT NULL
		,PercentageContribution																	DECIMAL(38, 19) NOT NULL
		,SuggestedNewContribution																DECIMAL(38, 19) NOT NULL
		,ConstrainedSuggestedNewContribution													DECIMAL(38, 19)	NOT NULL
		--,AmountNeededTosubtractFromOrderMultipleForAddingToContribution							DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedDownToOrderMultiple										DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedUpToOrderMultiple										DECIMAL(38, 19)	NOT NULL
		,SuggestedNewContributionRoundedClosestToOrderMultiple									DECIMAL(38, 19)	NOT NULL
		,OrderMultiple_RunningTotal_ToAdd														DECIMAL(38, 19) NOT NULL
		,OrderMultiple_RunningTotal_ToSubtract													DECIMAL(38, 19) NOT NULL
		,ConstrainedSuggestedNewContribution_Over												DECIMAL(38, 19) NOT NULL
		,SuggestedNewContributionRoundedDownToOrderMultiple_Over								DECIMAL(38, 19) NOT NULL
		,SuggestedNewContributionRoundedUpToOrderMultiple_Over									DECIMAL(38, 19) NOT NULL
		,SuggestedNewContributionRoundedClosestToOrderMultiple_Over								DECIMAL(38, 19) NOT NULL
		,ConstrainedSuggestedNewContribution_OverConstrainedToOrderMultiple						DECIMAL(38, 19) DEFAULT 0
		,SuggestedNewContributionRoundedDownToOrderMultiple_OverConstrainedToOrderMultiple		DECIMAL(38, 19) DEFAULT 0
		,SuggestedNewContributionRoundedUpToOrderMultiple_OverConstrainedToOrderMultiple		DECIMAL(38, 19) DEFAULT 0
		,SuggestedNewContributionRoundedClosestToOrderMultiple_OverConstrainedToOrderMultiple	DECIMAL(38, 19) DEFAULT 0
		);

		
		SET @SQL = '
			SELECT '+@TopX+' 
			 TRY_CONVERT(DECIMAL(38, 19),'+@ExternalIDField+')
			,TRY_CONVERT(VARCHAR(8000),'+@ExternalCodeField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@ValueField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@MinValueField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@MaxValueField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@TotalAvailableField+')
			,TRY_CONVERT(DECIMAL(38, 19),'+@OrderMultipleField+')
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
				  OrderMultiple ,
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
											,OrderMultiple
											,PartionGroup
											,TotalValue
											,PercentageContribution
											,SuggestedNewContribution
											,ConstrainedSuggestedNewContribution
											,SuggestedNewContributionRoundedDownToOrderMultiple
											,SuggestedNewContributionRoundedUpToOrderMultiple
											,SuggestedNewContributionRoundedClosestToOrderMultiple
											)
		SELECT 
			 V.ExternalID
			,V.ExternalCode
			,V.Value
			,V.MinValue
			,V.MaxValue
			,V.TotalAvailable
			,V.OrderMultiple
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
					((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)+(-((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%V.OrderMultiple)
				ELSE 0
			 END AS SuggestedNewContributionRoundedDownToOrderMultiple
			,CASE WHEN @bRoundUp = 1
				THEN
					((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)+(V.OrderMultiple-((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%V.OrderMultiple) 
				ELSE 0
			 END AS SuggestedNewContributionRoundedUpToOrderMultiple
			,CASE WHEN @bRoundClosest = 1
				THEN
					CASE WHEN CONVERT(DECIMAL(38, 19),((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%CONVERT(DECIMAL(38, 19), V.OrderMultiple)) / V.OrderMultiple > 0.5
						THEN ((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)+(V.OrderMultiple-((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%V.OrderMultiple)
					 ELSE
						((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)+(-((V.Value/SUM(V.Value) OVER (PARTITION BY V.PartionGroup))*V.TotalAvailable)%V.OrderMultiple)
					END 
				ELSE 0
				END AS SuggestedNewContributionRoundedClosestToOrderMultiple
		FROM #Values V
		
		IF((SELECT SUM(CV.MinValue) FROM #NewContributionValues CV) IS NOT NULL)
		BEGIN

			CREATE NONCLUSTERED INDEX IX_#NewContributionValues_MinValue ON #NewContributionValues(MinValue);
			
			UPDATE CV
			SET 
				--MinValue
				ConstrainedSuggestedNewContribution = CASE WHEN (CV.ConstrainedSuggestedNewContribution < CV.MinValue)
														THEN CV.MinValue
														ELSE
															CV.ConstrainedSuggestedNewContribution
													 END
				,SuggestedNewContributionRoundedDownToOrderMultiple = CASE WHEN (CV.SuggestedNewContributionRoundedDownToOrderMultiple < (CV.MinValue+(CV.OrderMultiple-(CV.MinValue%CV.OrderMultiple))))
																	THEN CV.MinValue+(CV.OrderMultiple-(CV.MinValue%CV.OrderMultiple))
																	ELSE
																		CV.SuggestedNewContributionRoundedDownToOrderMultiple
																 END
				,SuggestedNewContributionRoundedUpToOrderMultiple = CASE WHEN (CV.SuggestedNewContributionRoundedUpToOrderMultiple < (CV.MinValue+(CV.OrderMultiple-(CV.MinValue%CV.OrderMultiple))))
																	THEN CV.MinValue+(CV.OrderMultiple-(CV.MinValue%CV.OrderMultiple))
																	ELSE
																		CV.SuggestedNewContributionRoundedUpToOrderMultiple
																 END
				,SuggestedNewContributionRoundedClosestToOrderMultiple = CASE WHEN (CV.SuggestedNewContributionRoundedClosestToOrderMultiple < (CV.MinValue+(CV.OrderMultiple-(CV.MinValue%CV.OrderMultiple))))
																		THEN CV.MinValue+(CV.OrderMultiple-(CV.MinValue%CV.OrderMultiple))
																		ELSE
																			CV.SuggestedNewContributionRoundedClosestToOrderMultiple
																	 END
			FROM #NewContributionValues CV

		END

		IF((SELECT SUM(CV.MAXVALUE) FROM #NewContributionValues CV) IS NOT NULL)
		BEGIN
			
			CREATE NONCLUSTERED INDEX IX_#NewContributionValues_MaxValue ON #NewContributionValues(MaxValue);

			UPDATE CV
			SET 
				--MaxValue
				ConstrainedSuggestedNewContribution = CASE WHEN (CV.ConstrainedSuggestedNewContribution > CV.MaxValue)
														THEN CV.MaxValue
														ELSE
															CV.ConstrainedSuggestedNewContribution
													 END
				,SuggestedNewContributionRoundedDownToOrderMultiple = CASE WHEN (CV.SuggestedNewContributionRoundedDownToOrderMultiple > CV.MaxValue)
																	THEN CV.MaxValue+(-(CV.MaxValue%CV.OrderMultiple))
																	ELSE
																		CV.SuggestedNewContributionRoundedDownToOrderMultiple
																 END
				,SuggestedNewContributionRoundedUpToOrderMultiple = CASE WHEN (CV.SuggestedNewContributionRoundedUpToOrderMultiple > CV.MaxValue)
																	THEN CV.MaxValue+(-(CV.MaxValue%CV.OrderMultiple))
																	ELSE
																		CV.SuggestedNewContributionRoundedUpToOrderMultiple
																 END
				,SuggestedNewContributionRoundedClosestToOrderMultiple = CASE WHEN (CV.SuggestedNewContributionRoundedClosestToOrderMultiple > CV.MaxValue)
																	THEN CV.MaxValue+(-(CV.MaxValue%CV.OrderMultiple))
																	ELSE
																		CV.SuggestedNewContributionRoundedUpToOrderMultiple
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
		          ,OrderMultiple
		          ,PartionGroup
		          ,TotalValue
		          ,PercentageContribution
		          ,SuggestedNewContribution
		          ,ConstrainedSuggestedNewContribution
		          --,AmountNeededTosubtractFromOrderMultipleForAddingToContribution
		          ,SuggestedNewContributionRoundedDownToOrderMultiple
		          ,SuggestedNewContributionRoundedUpToOrderMultiple
		          ,SuggestedNewContributionRoundedClosestToOrderMultiple
		          ,OrderMultiple_RunningTotal_ToAdd
		          ,OrderMultiple_RunningTotal_ToSubtract
		          ,ConstrainedSuggestedNewContribution_Over
		          ,SuggestedNewContributionRoundedDownToOrderMultiple_Over
		          ,SuggestedNewContributionRoundedUpToOrderMultiple_Over
		          ,SuggestedNewContributionRoundedClosestToOrderMultiple_Over
		        )
		SELECT 
			 ExternalID
			,ExternalCode
			,Value
			,MinValue
			,MaxValue
			,TotalAvailable
			,OrderMultiple
			,PartionGroup
			,TotalValue
			,PercentageContribution
			,SuggestedNewContribution
			,ConstrainedSuggestedNewContribution
			--,AmountNeededTosubtractFromOrderMultipleForAddingToContribution
			,SuggestedNewContributionRoundedDownToOrderMultiple
			,SuggestedNewContributionRoundedUpToOrderMultiple
			,SuggestedNewContributionRoundedClosestToOrderMultiple
			,SUM(NCV.OrderMultiple) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value DESC, ExternalID) OrderMultiple_RunningTotal_ToAdd
			,SUM(NCV.OrderMultiple) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value ASC, ExternalID) OrderMultiple_RunningTotal_ToSubtract
			,NCV.TotalAvailable - SUM(NCV.ConstrainedSuggestedNewContribution) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value DESC, ExternalID)  AS ConstrainedSuggestedNewContribution_Over
			,NCV.TotalAvailable - SUM(NCV.SuggestedNewContributionRoundedDownToOrderMultiple) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value DESC, ExternalID)  AS SuggestedNewContributionRoundedDownToOrderMultiple_Over
			,NCV.TotalAvailable - SUM(NCV.SuggestedNewContributionRoundedUpToOrderMultiple) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value DESC, ExternalID)  AS SuggestedNewContributionRoundedUpToOrderMultiple_Over
			,NCV.TotalAvailable - SUM(NCV.SuggestedNewContributionRoundedClosestToOrderMultiple) OVER (PARTITION BY NCV.PartionGroup ORDER BY NCV.PartionGroup, NCV.Value ASC, ExternalID)  AS SuggestedNewContributionRoundedClosestToOrderMultiple_Over
		FROM #NewContributionValues NCV

		-- Add OrderMultiple to ConstrainedSuggestedNewContribution
		UPDATE FP
			SET
			ConstrainedSuggestedNewContribution_OverConstrainedToOrderMultiple = CASE WHEN (ConstrainedSuggestedNewContribution+OrderMultiple <= FP.MaxValue)
																				THEN ConstrainedSuggestedNewContribution+OrderMultiple
																				ELSE
																					FP.ConstrainedSuggestedNewContribution
																			END
			
		FROM #OverNewContributionValues FP
		WHERE OrderMultiple_RunningTotal_ToAdd <= ConstrainedSuggestedNewContribution_Over
		OR ConstrainedSuggestedNewContribution_Over = 0

		-- Add OrderMultiple to SuggestedNewContributionRoundedDownToOrderMultiple
		UPDATE FP
			SET
			SuggestedNewContributionRoundedDownToOrderMultiple_OverConstrainedToOrderMultiple = CASE WHEN (SuggestedNewContributionRoundedDownToOrderMultiple+OrderMultiple <= FP.MaxValue AND (SuggestedNewContributionRoundedDownToOrderMultiple+OrderMultiple <= TotalAvailable))
																							THEN SuggestedNewContributionRoundedDownToOrderMultiple+OrderMultiple
																							ELSE
																								FP.SuggestedNewContributionRoundedDownToOrderMultiple
																						END
		FROM #OverNewContributionValues FP
		WHERE OrderMultiple_RunningTotal_ToAdd <= SuggestedNewContributionRoundedDownToOrderMultiple_Over
		OR SuggestedNewContributionRoundedDownToOrderMultiple_Over = 0

		-- Subtract OrderMultiple FROM SuggestedNewContributionRoundedUpToOrderMultiple
		UPDATE FP
			SET
			SuggestedNewContributionRoundedUpToOrderMultiple_OverConstrainedToOrderMultiple = CASE WHEN ((SuggestedNewContributionRoundedUpToOrderMultiple-OrderMultiple >= FP.MinValue AND SuggestedNewContributionRoundedDownToOrderMultiple > FP.MaxValue)OR (SuggestedNewContributionRoundedUpToOrderMultiple_Over > TotalAvailable))
																							THEN SuggestedNewContributionRoundedUpToOrderMultiple-OrderMultiple
																							ELSE
																								FP.SuggestedNewContributionRoundedUpToOrderMultiple
																						END
		FROM #OverNewContributionValues FP
		WHERE OrderMultiple_RunningTotal_ToSubtract < SuggestedNewContributionRoundedUpToOrderMultiple_Over
		OR SuggestedNewContributionRoundedUpToOrderMultiple_Over = 0

		
		IF(@bTruncateSaveTable = 1)
		BEGIN
			TRUNCATE TABLE <SQL_DataBase_Schema,schemaname, schema_name>.ConstrainedApportion_Partitioned_ROQ;
		END

		IF(@bSaveToTable = 1)
		BEGIN
			INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ConstrainedApportion_Partitioned_ROQ
		        (  
					 ID
					,ExternalID
					,ExternalCode
					,Value
					,MinValue
					,MaxValue
					,TotalAvailable
					,OrderMultiple
					,PartionGroup
					,TotalValue
					,PercentageContribution
					,SuggestedNewContribution
					,ConstrainedSuggestedNewContribution
					--AmountNeededTosubtractFromOrderMultipleForAddingToContribution
					,SuggestedNewContributionRoundedDownToOrderMultiple
					,SuggestedNewContributionRoundedUpToOrderMultiple
					,SuggestedNewContributionRoundedClosestToOrderMultiple
					,OrderMultiple_RunningTotal_ToAdd
					,OrderMultiple_RunningTotal_ToSubtract
					,ConstrainedSuggestedNewContribution_Over
					,SuggestedNewContributionRoundedDownToOrderMultiple_Over
					,SuggestedNewContributionRoundedUpToOrderMultiple_Over
					,SuggestedNewContributionRoundedClosestToOrderMultiple_Over
					,ConstrainedSuggestedNewContribution_OverConstrainedToOrderMultiple
					,SuggestedNewContributionRoundedDownToOrderMultiple_OverConstrainedToOrderMultiple
					,SuggestedNewContributionRoundedUpToOrderMultiple_OverConstrainedToOrderMultiple
					,SuggestedNewContributionRoundedClosestToOrderMultiple_OverConstrainedToOrderMultiple
		        )
			SELECT 
				 ONCV.ID
				,ONCV.ExternalID
				,ONCV.ExternalCode
				,ONCV.Value
				,ONCV.MinValue
				,ONCV.MaxValue
				,ONCV.TotalAvailable
				,ONCV.OrderMultiple
				,ONCV.PartionGroup
				,ONCV.TotalValue
				,ONCV.PercentageContribution
				,ONCV.SuggestedNewContribution
				,ONCV.ConstrainedSuggestedNewContribution
				--,ONCV.AmountNeededTosubtractFromOrderMultipleForAddingToContribution
				,ONCV.SuggestedNewContributionRoundedDownToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedUpToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedClosestToOrderMultiple
				,ONCV.OrderMultiple_RunningTotal_ToAdd
				,ONCV.OrderMultiple_RunningTotal_ToSubtract
				,ONCV.ConstrainedSuggestedNewContribution_Over
				,ONCV.SuggestedNewContributionRoundedDownToOrderMultiple_Over
				,ONCV.SuggestedNewContributionRoundedUpToOrderMultiple_Over
				,ONCV.SuggestedNewContributionRoundedClosestToOrderMultiple_Over
				,ONCV.ConstrainedSuggestedNewContribution_OverConstrainedToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedDownToOrderMultiple_OverConstrainedToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedUpToOrderMultiple_OverConstrainedToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedClosestToOrderMultiple_OverConstrainedToOrderMultiple
			FROM #OverNewContributionValues ONCV
		END
		ELSE
		BEGIN
			SELECT 
				 ONCV.ID
				,ONCV.ExternalID
				,ONCV.ExternalCode
				,ONCV.Value
				,ONCV.MinValue
				,ONCV.MaxValue
				,ONCV.TotalAvailable
				,ONCV.OrderMultiple
				,ONCV.PartionGroup
				,ONCV.TotalValue
				,ONCV.PercentageContribution
				,ONCV.SuggestedNewContribution
				,ONCV.ConstrainedSuggestedNewContribution
				--,ONCV.AmountNeededTosubtractFromOrderMultipleForAddingToContribution
				,ONCV.SuggestedNewContributionRoundedDownToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedUpToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedClosestToOrderMultiple
				,ONCV.OrderMultiple_RunningTotal_ToAdd
				,ONCV.OrderMultiple_RunningTotal_ToSubtract
				,ONCV.ConstrainedSuggestedNewContribution_Over
				,ONCV.SuggestedNewContributionRoundedDownToOrderMultiple_Over
				,ONCV.SuggestedNewContributionRoundedUpToOrderMultiple_Over
				,ONCV.SuggestedNewContributionRoundedClosestToOrderMultiple_Over
				,ONCV.ConstrainedSuggestedNewContribution_OverConstrainedToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedDownToOrderMultiple_OverConstrainedToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedUpToOrderMultiple_OverConstrainedToOrderMultiple
				,ONCV.SuggestedNewContributionRoundedClosestToOrderMultiple_OverConstrainedToOrderMultiple
			FROM #OverNewContributionValues ONCV
			--WHERE ONCV.PartionGroup = 1
			--ORDER BY ONCV.PartionGroup, ONCV.Value DESC
		END
END
GO