
IF OBJECT_ID('tempdb..#DaysOfWeek') IS NOT NULL
		DROP TABLE #DaysOfWeek

	CREATE TABLE #DaysOfWeek (
		  DaysOfWeekID			INT IDENTITY (1,1)
		, Day					INT
		, DayStartDate			DATETIME
		, DayEndDate			DATETIME
		, Week					INT
		, WeekStartDate			DATETIME
		, WeekEndDate			DATETIME
		, Month					INT
		, MonthStartDate		DATETIME
		, MonthEndDate			DATETIME
		, Quarter				INT
		, QuarterStartDate		DATETIME
		, QuarterEndDate		DATETIME
		, Year					INT
		, YearStartDate			DATETIME
		, YearEndDate			DATETIME
		, YearWeek				VARCHAR(50)
		, YearMonth				VARCHAR(50)
		, YearQuarter			 VARCHAR(50)
		, YearMonthDays			INT
		, YearMonthWorkingDays	INT
		, YearQuarterDays		 INT
		, YearQuarterWorkingDays INT
	)

	DECLARE @StarDate DATETIME = (SELECT DateAdd(yy, -2, CONVERT(DATE,GetDate()))) -- 2 Years History-- 
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

	SELECT DATEADD(dd,1,StartDate), RoWNumber + 1,  DATEADD(ms,-3, DATEADD(dd,1, StartDate)) AS EndDate,Endperiod
	FROM DateRange
	WHERE StartDate <= Endperiod
	)
	
	INSERT INTO #DaysOfWeek (Day, DayStartDate, DayEndDate, Week, WeekStartDate, WeekEndDate, Month, MonthStartDate, MonthEndDate, Quarter, QuarterStartDate, QuarterEndDate, Year, YearStartDate, YearEndDate, YearWeek, YearMonth, YearQuarter, YearMonthDays, YearMonthWorkingDays, YearQuarterDays, YearQuarterWorkingDays)
	SELECT 
	 RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(DW, StartDate)),2) AS 'Day'
	,StartDate
	,EndDate
	,RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(WEEK, StartDate)),2)	AS 'Week'
	,MIN(StartDate) OVER (PARTITION BY DATEPART(WEEK, StartDate))
	,MAX(EndDate) OVER (PARTITION BY DATEPART(WEEK, StartDate))
	,RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(MM, StartDate)),2) AS 'Month'
	,MIN(StartDate) OVER (PARTITION BY DATEPART(MM, StartDate))
	,MAX(EndDate) OVER (PARTITION BY DATEPART(MM, StartDate))
	,RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(QUARTER, StartDate)),2) AS 'Quarter'
	,MIN(StartDate) OVER (PARTITION BY DATEPART(QUARTER, StartDate))
	,MAX(EndDate) OVER (PARTITION BY DATEPART(QUARTER, StartDate))
	,TRY_CONVERT(VARCHAR(50),DATEPART(YY, StartDate)) AS 'Year'
	,MIN(StartDate) OVER (PARTITION BY DATEPART(YY, StartDate))
	,MAX(EndDate) OVER (PARTITION BY DATEPART(YY, StartDate))
	,TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(WEEK, StartDate)),2))	AS 'YearWeek'
	,TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(MM, StartDate)),2))	AS 'YearMonth'
	,TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), RIGHT('00'+TRY_CONVERT(VARCHAR(50),DATEPART(QUARTER, StartDate)),2))	AS 'YearQuarter'
	,COUNT(1) OVER (Partition BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), DATEPART(MM, StartDate)))	AS YearMonthDays
	,SUM(CASE WHEN (DATEPART(DW, StartDate) IN (1,2,3,4,5)) THEN 1 ELSE 0 END) OVER (Partition BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), DATEPART(MM, StartDate)))	AS YearMonthWorkingDays
	,COUNT(1) OVER (Partition BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), DATEPART(QUARTER, StartDate)))	AS YearQuarterDays
	,SUM(CASE WHEN (DATEPART(DW, StartDate) IN (1,2,3,4,5)) THEN 1 ELSE 0 END) OVER (Partition BY TRY_CONVERT(VARCHAR(50), DATEPART(YY, StartDate))+'_'+TRY_CONVERT(VARCHAR(50), DATEPART(QUARTER, StartDate)))	AS YearQuarterWorkingDays
	FROM DateRange
	OPTION (MAXRECURSION 0)

	SELECT * 
	FROM #DaysOfWeek