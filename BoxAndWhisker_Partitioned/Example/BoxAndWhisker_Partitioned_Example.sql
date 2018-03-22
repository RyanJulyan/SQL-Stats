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
    [EP_ItemCode] VARCHAR(255) NULL,
    [Quantity] INTEGER NULL,
    [Grouping] INTEGER NULL,
    PRIMARY KEY ([ExampleDataID])
);
GO

INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1000,'8681',656,3),(1001,'3332',148,2),(1002,'7361',231,3),(1003,'1769',649,2),(1004,'3951',493,2),(1005,'3207',772,3),(1006,'3149',317,2),(1007,'7034',387,1),(1008,'1573',489,1),(1009,'5513',340,2);
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1010,'4877',54,3),(1011,'9170',197,1),(1012,'5982',463,1),(1013,'9335',964,3),(1014,'5945',481,3),(1015,'4072',388,3),(1016,'8506',13,1),(1017,'4323',673,3),(1018,'3973',311,2),(1019,'3543',117,3);
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1020,'1418',201,3),(1021,'5709',86,2),(1022,'3057',677,3),(1023,'7082',618,1),(1024,'6301',21,3),(1025,'9936',702,3),(1026,'3760',469,2),(1027,'7922',204,1),(1028,'6944',734,1),(1029,'9656',896,3);
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1030,'1695',38,1),(1031,'3028',498,2),(1032,'2720',152,3),(1033,'7851',211,3),(1034,'1859',155,1),(1035,'7156',455,1),(1036,'3831',477,2),(1037,'3183',596,3),(1038,'5230',54,2),(1039,'5210',348,3);
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1040,'4813',568,1),(1041,'2276',450,1),(1042,'3239',177,1),(1043,'3510',19,3),(1044,'6967',538,2),(1045,'9061',424,2),(1046,'1721',811,2),(1047,'4528',820,1),(1048,'5136',412,2),(1049,'5495',16,1);
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1050,'5049',850,3),(1051,'9314',380,2),(1052,'9264',990,3),(1053,'2106',317,3),(1054,'9402',888,2),(1055,'7619',639,1),(1056,'5597',976,3),(1057,'4718',559,3),(1058,'7634',182,2),(1059,'5859',887,2);
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1060,'5283',469,3),(1061,'6701',56,1),(1062,'6124',99,3),(1063,'6836',445,1),(1064,'8604',295,1),(1065,'8249',423,1),(1066,'8849',303,2),(1067,'1755',400,2),(1068,'7645',506,1),(1069,'6423',978,2);
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1070,'8900',973,2),(1071,'6094',955,2),(1072,'2426',103,1),(1073,'4999',543,1),(1074,'6176',951,2),(1075,'8457',563,2),(1076,'1651',472,2),(1077,'3569',930,2),(1078,'5787',625,2),(1079,'9031',568,3);
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1080,'5611',750,2),(1081,'4011',916,1),(1082,'1436',927,3),(1083,'3332',923,1),(1084,'9854',140,1),(1085,'5547',750,3),(1086,'4507',806,3),(1087,'3514',280,2),(1088,'6093',800,3),(1089,'1215',515,3);
INSERT INTO <SQL_DataBase_Schema,schemaname, schema_name>.ExampleData([EP_ItemID],[EP_ItemCode],[Quantity],[Grouping]) VALUES(1090,'6608',679,2),(1091,'6917',385,2),(1092,'9931',48,2),(1093,'7295',546,1),(1094,'5349',878,1),(1095,'5974',586,3),(1096,'7213',67,2),(1097,'5446',760,1),(1098,'9730',242,3),(1099,'5458',864,1);


EXEC <SQL_DataBase_Schema,schemaname, schema_name>.BoxAndWhisker_Partitioned
 @ExternalIDField = 'EP_ItemID'
,@ExternalCodeField = 'EP_ItemCode'
,@ValueField = 'Quantity'
,@PartionGroupField = 'Grouping'
,@TableName = 'ExampleData'
,@TopX = 'TOP 1000'
GO