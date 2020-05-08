DECLARE  @ItemsToSplit		VARCHAR(8000) = 'Test1,Test2'
		,@Delimiter			VARCHAR(8000) = ','

IF OBJECT_ID('TEMPDB..#ItemsTableSplit') IS NOT NULL
	DROP TABLE #ItemsTableSplit;

CREATE TABLE #ItemsTableSplit(
								 ID					INT
								,Item				NVARCHAR(MAX)
							);

;WITH Split(stpos,endpos)
AS(
    SELECT 0 AS stpos, CHARINDEX(@Delimiter,@ItemsToSplit) AS endpos
    UNION ALL
    SELECT endpos+1, CHARINDEX(@Delimiter,@ItemsToSplit,endpos+1)
        FROM Split
        WHERE endpos > 0
)
INSERT INTO #ItemsTableSplit(
							 ID 
							,Item
							)
SELECT 
	'ID' = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
    'Item' = SUBSTRING(@ItemsToSplit,stpos,COALESCE(NULLIF(endpos,0),LEN(@ItemsToSplit)+1)-stpos)
FROM SPLIT

SELECT * FROM #ItemsTableSplit