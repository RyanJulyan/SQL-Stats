USE <SQL_DataBase_Name,dbname, database_name>
GO

IF EXISTS(SELECT 1 
		   FROM sys.tables T
           INNER JOIN sys.schemas S
				ON S.schema_id = T.schema_id 
			WHERE  T.name = 'ExampleData'
                AND s.name = '<SQL_DataBase_Schema,schemaname, schema_name>')
BEGIN
    DROP TABLE <SQL_DataBase_Schema,schemaname, schema_name>.[ExampleData];
END
GO

CREATE TABLE <SQL_DataBase_Schema,schemaname, schema_name>.[ExampleData] (
    [ExampleDataID] INTEGER NOT NULL IDENTITY(1, 1),
    [EP_ItemID] INTEGER NULL,
    [EP_ItemCode] VARCHAR(10) NULL,
    [Quantity] INTEGER NULL,
    [Grouping] INTEGER NULL,
    [QuantityDate] DATETIME,
    PRIMARY KEY ([ExampleDataID])
);
GO

INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1000,'56370',381,3,'12/19/16'),(1001,'7679',889,1,'02/09/16'),(1002,'38-015',320,2,'08/13/16'),(1003,'8624',552,1,'05/01/16'),(1004,'18815-690',356,1,'08/26/17'),(1005,'Z93 1CF',471,2,'02/20/16'),(1006,'71364',335,3,'05/03/16'),(1007,'49803',969,2,'01/02/17'),(1008,'4620',852,3,'01/24/17'),(1009,'58331',559,3,'10/15/17');
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1010,'3684',278,2,'09/27/17'),(1011,'4077',629,3,'12/19/16'),(1012,'21403',213,1,'01/25/17'),(1013,'3268 UA',66,2,'07/14/16'),(1014,'3240',673,3,'05/26/17'),(1015,'2370',161,3,'03/21/16'),(1016,'21407',233,1,'12/06/16'),(1017,'30018',385,1,'06/07/17'),(1018,'ZS22 3MF',968,2,'08/07/17'),(1019,'8892',153,1,'11/01/16');
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1020,'79069',455,3,'01/15/17'),(1021,'190134',468,1,'06/26/17'),(1022,'10804',142,1,'10/19/17'),(1023,'10517',160,2,'04/15/16'),(1024,'8250',330,2,'01/15/17'),(1025,'7225',562,2,'07/27/17'),(1026,'10306',876,2,'10/10/16'),(1027,'87978',118,2,'02/13/16'),(1028,'5041 LG',870,3,'07/04/17'),(1029,'1765',235,2,'09/15/17');
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1030,'75971',1000,2,'02/06/16'),(1031,'9298',813,2,'04/21/17'),(1032,'36790',763,2,'04/02/16'),(1033,'92536',532,1,'09/07/16'),(1034,'K0G 0V2',122,2,'09/15/16'),(1035,'M1E 2N9',365,3,'08/26/17'),(1036,'25124',284,3,'08/26/17'),(1037,'664099',448,1,'08/16/16'),(1038,'9774',308,3,'02/25/17'),(1039,'14-797',148,3,'12/21/16');
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1040,'75859',864,1,'02/06/16'),(1041,'2296 LI',402,1,'01/26/16'),(1042,'3013 JN',284,2,'09/30/16'),(1043,'4984',496,3,'01/14/16'),(1044,'M6 7FC',708,3,'06/23/16'),(1045,'67123',966,2,'09/02/16'),(1046,'1537',888,2,'07/25/16'),(1047,'32816',992,3,'07/19/16'),(1048,'16-329',246,2,'05/19/16'),(1049,'4786 DF',446,1,'12/01/16');
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1050,'9831',744,2,'01/30/17'),(1051,'83-711',989,3,'04/24/16'),(1052,'414019',204,3,'07/14/17'),(1053,'4823 GS',584,2,'09/18/17'),(1054,'83677',151,2,'10/28/16'),(1055,'B3R 8T2',688,2,'10/21/17'),(1056,'64-217',21,1,'06/10/16'),(1057,'9700',968,3,'12/14/17'),(1058,'12251',596,3,'09/11/16'),(1059,'64768',386,2,'03/09/16');
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1060,'251490',563,1,'04/05/16'),(1061,'7379',685,3,'05/03/16'),(1062,'27973',145,1,'05/02/16'),(1063,'71904',442,2,'10/19/17'),(1064,'09261',284,3,'08/04/17'),(1065,'90254',317,2,'06/13/16'),(1066,'3377',264,2,'03/18/16'),(1067,'J4F 2SE',499,2,'02/14/17'),(1068,'6328',381,3,'08/25/17'),(1069,'38594',713,1,'05/14/16');
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1070,'4807',719,2,'04/12/17'),(1071,'64754',766,1,'06/21/16'),(1072,'102257',89,2,'01/26/17'),(1073,'1583',673,2,'09/07/17'),(1074,'63056',148,3,'09/09/17'),(1075,'8896',252,1,'12/04/16'),(1076,'71016-189',350,3,'11/18/16'),(1077,'25907',238,2,'03/14/16'),(1078,'280372',704,1,'02/20/16'),(1079,'125786',879,2,'01/24/16');
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1080,'9978',204,2,'09/06/16'),(1081,'947717',686,3,'07/18/16'),(1082,'84298',530,1,'10/06/17'),(1083,'96-070',392,3,'11/23/16'),(1084,'44-648',853,3,'12/27/16'),(1085,'2953',609,1,'06/11/16'),(1086,'004816',163,2,'08/31/16'),(1087,'88314',484,3,'02/28/16'),(1088,'58854',689,2,'11/27/16'),(1089,'78837',953,1,'07/08/17');
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[QuantityDate]) VALUES(1090,'O00 4TL',566,3,'05/24/17'),(1091,'03933',900,1,'01/13/17'),(1092,'984595',286,3,'11/29/17'),(1093,'670460',38,2,'06/23/16'),(1094,'59500',375,1,'07/23/17'),(1095,'3060 TD',29,3,'08/09/17'),(1096,'F0 4SO',320,3,'01/17/16'),(1097,'60-667',779,3,'12/26/16'),(1098,'64903',946,2,'05/16/17'),(1099,'91845',191,2,'04/20/16');


EXEC <SQL_DataBase_Schema,schemaname, schema_name>.GeneralStats_Partitioned
	 @ExternalIDField = 'EP_ItemID'
	,@ExternalCodeField = 'EP_ItemCode'
	,@ValueField = 'Quantity'
	,@IndependantValueField = 'QuantityDate'
	,@PartionGroupField = 'Grouping'
	,@TableName = 'ExampleData'
	,@TopX = 'TOP 1000'
	,@ErrorPercentage = 0.05
GO