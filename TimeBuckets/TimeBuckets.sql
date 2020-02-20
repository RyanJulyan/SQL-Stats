
IF OBJECT_ID('tempdb..#DaysOfWeek') IS NOT NULL
		DROP TABLE #DaysOfWeek

	CREATE TABLE #DaysOfWeek (
		  DaysOfWeekID						INT IDENTITY (1,1)
		, Day								VARCHAR(50)
		, DayStartDate						DATETIME
		, DayEndDate						DATETIME
		, FiscalWeek						VARCHAR(50)
		, FiscalWeekStartDate				DATETIME
		, FiscalWeekEndDate					DATETIME
		, FiscalMonth						VARCHAR(50)
		, FiscalMonthStartDate				DATETIME
		, FiscalMonthEndDate				DATETIME
		, FiscalQuarter						VARCHAR(50)
		, FiscalQuarterStartDate			DATETIME
		, FiscalQuarterEndDate				DATETIME
		, FiscalYear						VARCHAR(50)
		, FiscalYearStartDate				DATETIME
		, FiscalYearEndDate					DATETIME
		, FiscalYearWeek					VARCHAR(50)
		, FiscalYearMonth					VARCHAR(50)
		, FiscalYearQuarter					VARCHAR(50)
		, FiscalYearMonthDays				INT
		, FiscalYearMonthWorkingDays		INT
		, FiscalYearQuarterDays				INT
		, FiscalYearQuarterWorkingDays		INT
		, GregorianMonth					VARCHAR(50)
		, GregorianMonthStartDate			DATETIME
		, GregorianMonthEndDate				DATETIME
		, GregorianQuarter					VARCHAR(50)
		, GregorianQuarterStartDate			DATETIME
		, GregorianQuarterEndDate			DATETIME
		, GregorianYear						VARCHAR(50)
		, GregorianYearStartDate			DATETIME
		, GregorianYearEndDate				DATETIME
		, GregorianYearWeek					VARCHAR(50)
		, GregorianYearMonth				VARCHAR(50)
		, GregorianYearQuarter				VARCHAR(50)
		, GregorianYearMonthDays			INT
		, GregorianYearMonthWorkingDays		INT
		, GregorianYearQuarterDays			INT
		, GregorianYearQuarterWorkingDays	INT
	)

	DECLARE @StarDate DATETIME = (SELECT DateAdd(yy, -2, CONVERT(DATE,GetDate()))) -- 2 Years History-- 
	SELECT @StarDate  = TRY_CONVERT(DATETIME,TRY_CONVERT(VARCHAR(50),DATEPART(YY, @StarDate))+'-01-01');

	DECLARE @EndDate DATETIME = (SELECT DateAdd(yy, +4,@StarDate)) -- 4 Years from @StarDate

	IF OBJECT_ID('tempdb..#StartDate')IS NOT NULL
	  BEGIN
	   DROP TABLE #StartDate
	  END

	SELECT @StarDate AS StartDate, @EndDate AS EndDate, @EndDate AS Endperiod
	INTO #StartDate

	;WITH DateRange AS
	(

	SELECT StartDate, ROW_NUMBER() OVER(ORDER BY @StarDate) RoWNumber,DATEADD(ms,-3, DATEADD(dd,1, StartDate)) AS EndDate, Endperiod
	FROM #StartDate

	UNION ALL

	SELECT DATEADD(dd,1,StartDate), RoWNumber + 1,  DATEADD(ms,-3, DATEADD(dd,2, StartDate)) AS EndDate,Endperiod
	FROM DateRange
	WHERE StartDate <= Endperiod
	)
	
	INSERT INTO #DaysOfWeek (
							  Day							
							, DayStartDate					
							, DayEndDate					
							, FiscalWeek					
							, FiscalWeekStartDate			
							, FiscalWeekEndDate				
							, FiscalMonth					
							, FiscalMonthStartDate			
							, FiscalMonthEndDate			
							, FiscalQuarter					
							, FiscalQuarterStartDate		
							, FiscalQuarterEndDate			
							, FiscalYear					
							, FiscalYearStartDate			
							, FiscalYearEndDate				
							, FiscalYearWeek				
							, FiscalYearMonth				
							, FiscalYearQuarter				
							, FiscalYearMonthDays			
							, FiscalYearMonthWorkingDays	
							, FiscalYearQuarterDays			
							, FiscalYearQuarterWorkingDays	
							, GregorianMonth				
							, GregorianMonthStartDate		
							, GregorianMonthEndDate			
							, GregorianQuarter				
							, GregorianQuarterStartDate		
							, GregorianQuarterEndDate		
							, GregorianYear					
							, GregorianYearStartDate		
							, GregorianYearEndDate			
							, GregorianYearWeek				
							, GregorianYearMonth			
							, GregorianYearQuarter			
							, GregorianYearMonthDays		
							, GregorianYearMonthWorkingDays	
							, GregorianYearQuarterDays		
							, GregorianYearQuarterWorkingDays
							)
	SELECT 

	 RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(DW, StartDate)),2) AS 'Day'
	,StartDate
	,EndDate
	,RIGHT('00'+TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END ),2) 	AS 'FiscalWeek'
	,MIN(StartDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END ),2)) AS 'FiscalWeekStartDate'
	,MAX(EndDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END ),2)) AS 'FiscalWeekEndDate'
	
	,RIGHT('00'+TRY_CONVERT(VARCHAR(50),TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END)),2) AS 'FiscalMonth'
	,MIN(StartDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END)),2)) AS 'FiscalMonthStartDate'
	,MAX(EndDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END)),2)) AS 'FiscalMonthEndDate'
	
	,RIGHT('00'+TRY_CONVERT(VARCHAR(50),
		CASE WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 3
			THEN 1
		WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 6
			THEN 2
		WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 9
			THEN 3
		ELSE 4
		END
	),2) AS 'Quarter'
	,MIN(StartDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),
																									CASE WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 3
																										THEN 1
																									WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 6
																										THEN 2
																									WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 9
																										THEN 3
																									ELSE 4
																									END
																								),2)) AS 'FiscalQuarterStartDate'
	,MAX(EndDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),
																									CASE WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 3
																										THEN 1
																									WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 6
																										THEN 2
																									WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 9
																										THEN 3
																									ELSE 4
																									END
																								),2)) AS 'FiscalQuarterEndDate'
	,TRY_CONVERT(VARCHAR(50),CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END ) AS 'FiscalYear'
	,MIN(StartDate) OVER (PARTITION BY CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END) AS 'FiscalYearStartDate'
	,MAX(EndDate) OVER (PARTITION BY CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END) AS 'FiscalYearEndDate'
	,TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END ),2)	AS 'FiscalYearWeek'
	,TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END)),2)	AS 'FiscalYearMonth'
	,TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),
																																																																			CASE WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 3
																																																																				THEN 1
																																																																			WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 6
																																																																				THEN 2
																																																																			WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 9
																																																																				THEN 3
																																																																			ELSE 4
																																																																			END
																																																																		),2)	AS 'FiscalYearQuarter'
	,COUNT(1) OVER (Partition BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END)),2))	AS FiscalYearMonthDays
	,SUM(CASE WHEN (DATEPART(DW, StartDate) IN (1,2,3,4,5)) THEN 1 ELSE 0 END) OVER (Partition BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END)),2))	AS FiscalYearMonthWorkingDays
	,COUNT(1) OVER (Partition BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),
																																																																			CASE WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 3
																																																																				THEN 1
																																																																			WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 6
																																																																				THEN 2
																																																																			WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 9
																																																																				THEN 3
																																																																			ELSE 4
																																																																			END
																																																																		),2))	AS FiscalYearQuarterDays
	,SUM(CASE WHEN (DATEPART(DW, StartDate) IN (1,2,3,4,5)) THEN 1 ELSE 0 END) OVER (Partition BY TRY_CONVERT(VARCHAR(50), CASE WHEN DATEPART(MM, StartDate) = 12 AND (CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END )= 1 THEN DATEPART(YY, StartDate) +1 ELSE DATEPART(YY, StartDate) END)+'_'+RIGHT('00'+TRY_CONVERT(VARCHAR(50),
																																																																			CASE WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 3
																																																																				THEN 1
																																																																			WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 6
																																																																				THEN 2
																																																																			WHEN TRY_CONVERT(INT,CASE WHEN ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2 ) / (53/11.959178)),0) + 1 = 13 THEN 1 ELSE ROUND(((CASE WHEN DATEPART(WEEK, StartDate) = 53 THEN 1 ELSE DATEPART(WEEK, StartDate) END -2) / (53/11.959178)),0) + 1 END) <= 9
																																																																				THEN 3
																																																																			ELSE 4
																																																																			END
																																																																		),2))	AS FiscalYearQuarterWorkingDays

	,RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(MM, StartDate)),2) AS 'Month'
	,MIN(StartDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(MM, StartDate)),2)))
	,MAX(EndDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(MM, StartDate)),2)))
	,RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(QUARTER, StartDate)),2) AS 'Quarter'
	,MIN(StartDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(QUARTER, StartDate)),2)))
	,MAX(EndDate) OVER (PARTITION BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(QUARTER, StartDate)),2)))
	,TRY_CONVERT(VARCHAR(50),DATEPART(YY, StartDate)) AS 'Year'
	,MIN(StartDate) OVER (PARTITION BY DATEPART(YY, StartDate))
	,MAX(EndDate) OVER (PARTITION BY DATEPART(YY, StartDate))
	,TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(WEEK, StartDate)),2))	AS 'GregorianYearWeek'
	,TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(MM, StartDate)),2))	AS 'GregorianYearMonth'
	,TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(QUARTER, StartDate)),2))	AS 'GregorianYearQuarter'
	,COUNT(1) OVER (Partition BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), DATEPART(MM, StartDate)))	AS GregorianYearMonthDays
	,SUM(CASE WHEN (DATEPART(DW, StartDate) IN (1,2,3,4,5)) THEN 1 ELSE 0 END) OVER (Partition BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), DATEPART(MM, StartDate)))	AS GregorianYearMonthWorkingDays
	,COUNT(1) OVER (Partition BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), DATEPART(QUARTER, StartDate)))	AS GregorianYearQuarterDays
	,SUM(CASE WHEN (DATEPART(DW, StartDate) IN (1,2,3,4,5)) THEN 1 ELSE 0 END) OVER (Partition BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), DATEPART(QUARTER, StartDate)))	AS GregorianYearQuarterWorkingDays
	FROM DateRange
	ORDER BY StartDate
	OPTION (MAXRECURSION 0)

	DROP TABLE IF EXISTS StandardCalendar;

	SELECT *
	INTO StandardCalendar
	FROM #DaysOfWeek