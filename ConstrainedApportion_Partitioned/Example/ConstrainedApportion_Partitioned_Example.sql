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
    [Rounding] INTEGER NULL,
    [TotalAvailable] INTEGER NULL,
    [Min] INTEGER NULL,
    [Max] INTEGER NULL,
    PRIMARY KEY ([ExampleDataID])
);
GO

INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1000,'279761',2716,3,1,1000,2,600),(1001,'1873',3654,3,2,1000,2,600),(1002,'P4Z 3K8',4402,1,5,1000,2,600),(1003,'1690',422,1,4,1000,2,600),(1004,'H7J 9J8',2421,3,6,1000,2,600),(1005,'28683',3225,1,7,1000,2,600),(1006,'85940',2758,3,3,1000,2,600),(1007,'V9M 8L2',2734,1,7,1000,2,600),(1008,'51115-302',1554,3,8,1000,2,600),(1009,'S27 1PN',902,3,2,1000,2,600);
INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1010,'26615-785',1014,2,9,1000,2,600),(1011,'55437',1332,3,9,1000,2,600),(1012,'72361-275',489,3,9,1000,2,600),(1013,'9815 OA',961,1,1,1000,2,600),(1014,'9120',4029,1,2,1000,2,600),(1015,'09706',2024,1,9,1000,2,600),(1016,'60150',1663,1,6,1000,2,600),(1017,'Y8 2LA',1942,3,9,1000,2,600),(1018,'327728',2801,1,4,1000,2,600),(1019,'79015',4108,2,7,1000,2,600);
INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1020,'221422',2842,2,3,1000,2,600),(1021,'93407',2460,1,10,1000,2,600),(1022,'56575-971',2095,1,2,1000,2,600),(1023,'83036-024',3278,1,7,1000,2,600),(1024,'62225',4476,3,6,1000,2,600),(1025,'11646',4025,1,3,1000,2,600),(1026,'53855',4851,2,6,1000,2,600),(1027,'32815',4010,3,3,1000,2,600),(1028,'941002',687,1,3,1000,2,600),(1029,'35232',607,2,10,1000,2,600);
INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1030,'54667',1141,3,5,1000,2,600),(1031,'68385',4591,3,1,1000,2,600),(1032,'68919',4843,2,6,1000,2,600),(1033,'2070',2950,2,8,1000,2,600),(1034,'6711 LF',1339,1,7,1000,2,600),(1035,'20925',4388,2,3,1000,2,600),(1036,'6709',4182,2,5,1000,2,600),(1037,'21769-482',84,3,3,1000,2,600),(1038,'0826 XH',2850,2,1,1000,2,600),(1039,'798204',3720,2,2,1000,2,600);
INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1040,'5843 CG',2987,3,7,1000,2,600),(1041,'22368',4839,1,8,1000,2,600),(1042,'E8Y 1S9',1267,1,6,1000,2,600),(1043,'653387',3013,2,9,1000,2,600),(1044,'93274',3379,1,7,1000,2,600),(1045,'2248',4639,2,9,1000,2,600),(1046,'II70 6TQ',4573,3,1,1000,2,600),(1047,'52425',2621,3,8,1000,2,600),(1048,'616828',4709,3,1,1000,2,600),(1049,'X4N 1L1',1480,1,2,1000,2,600);
INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1050,'310847',1918,3,1,1000,2,600),(1051,'22003',3567,3,3,1000,2,600),(1052,'76799',3054,2,4,1000,2,600),(1053,'J0S 4Y5',4992,2,8,1000,2,600),(1054,'69-842',4280,3,7,1000,2,600),(1055,'52032',4237,3,3,1000,2,600),(1056,'70318',1779,2,6,1000,2,600),(1057,'9726',3702,3,6,1000,2,600),(1058,'06-142',777,1,4,1000,2,600),(1059,'96990',3912,3,4,1000,2,600);
INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1060,'6627',1037,1,1,1000,2,600),(1061,'6203',4372,1,6,1000,2,600),(1062,'9146',952,3,4,1000,2,600),(1063,'71899',545,2,4,1000,2,600),(1064,'2428',3672,1,5,1000,2,600),(1065,'95533',796,2,8,1000,2,600),(1066,'81190-229',4604,1,8,1000,2,600),(1067,'28660',2562,1,7,1000,2,600),(1068,'9392',1787,1,1,1000,2,600),(1069,'2167',3342,3,9,1000,2,600);
INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1070,'E4P 9X3',2388,1,3,1000,2,600),(1071,'97907',4982,1,9,1000,2,600),(1072,'6868',3188,1,7,1000,2,600),(1073,'95626',1324,2,1,1000,2,600),(1074,'N7C 1C1',4638,3,5,1000,2,600),(1075,'71680',2437,3,1,1000,2,600),(1076,'37405',3841,1,3,1000,2,600),(1077,'9994',1877,2,8,1000,2,600),(1078,'94-544',2792,1,3,1000,2,600),(1079,'28194',707,3,6,1000,2,600);
INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1080,'07412',2014,3,10,1000,2,600),(1081,'30418',2811,3,10,1000,2,600),(1082,'60643',1820,1,4,1000,2,600),(1083,'38937',3998,1,10,1000,2,600),(1084,'3419',997,3,6,1000,2,600),(1085,'5922',625,2,9,1000,2,600),(1086,'951247',2830,2,4,1000,2,600),(1087,'33967',2838,1,2,1000,2,600),(1088,'1128',3690,2,5,1000,2,600),(1089,'4964',2995,3,7,1000,2,600);
INSERT INTO  <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping],[Rounding],[TotalAvailable],[Min],[Max]) VALUES(1090,'D28 7UU',4819,2,8,1000,2,600),(1091,'39359-886',4124,1,10,1000,2,600),(1092,'56549',774,2,4,1000,2,600),(1093,'36696',1691,1,5,1000,2,600),(1094,'10219',4488,3,1,1000,2,600),(1095,'5595',4403,1,3,1000,2,600),(1096,'33796',3071,1,5,1000,2,600),(1097,'634860',810,1,7,1000,2,600),(1098,'7185',4763,3,4,1000,2,600),(1099,'567175',870,1,1,1000,2,600);



EXEC <SQL_DataBase_Schema,schemaname, schema_name>.ConstrainedApportion_Partitioned
 @ExternalIDField = 'EP_ItemID'
,@ExternalCodeField = 'EP_ItemCode'
,@ValueField = 'Quantity'
,@PartionGroupField = 'Grouping'
,@MinValueField = 'Min'
,@MaxValueField = 'Max'
,@TotalAvailableField = 'TotalAvailable'
,@RoundingField = 'Rounding'
,@TableName = 'ExampleData'
,@TopX = 'TOP 1000'
GO;