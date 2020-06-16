--Space
SELECT  
 a.databasename
,ZEROIFNULL (a.PermSpace /  (1024*1024*1024))  (DECIMAL(18,1)) AS Asignado
,ZEROIFNULL (b.CurrentPerm / (1024*1024*1024)) (DECIMAL(18,1))  AS Utilizado
,ZEROIFNULL (Asignado -  Utilizado) AS Disponible
,CASE WHEN Asignado= 0 THEN 0 
      ELSE ZEROIFNULL ((Utilizado * 100) / Asignado) 
 END (DECIMAL(18,1))   AS Pct_Utilizado
,CASE WHEN Asignado= 0 THEN 0 
      ELSE ZEROIFNULL ((Disponible * 100) / Asignado) 
 END (DECIMAL(18,1)) AS Pct_Libre
,ZEROIFNULL ((c.CurrentPerm *(HASHAMP()+1)) / (1024*1024*1024)) (DECIMAL(18,1))  AS Utilizado_Real
,ZEROIFNULL (Asignado -  Utilizado_Real) AS Disponible_Real
,CASE WHEN Asignado= 0 THEN 0 
      ELSE ZEROIFNULL ((Utilizado_Real * 100) / Asignado) 
 END (DECIMAL(18,1))   AS Pct_Utilizado_Real,
        CASE 
            WHEN Asignado= 0 THEN 0 
            ELSE ZEROIFNULL ((Disponible_Real * 100) / Asignado) 
        END (DECIMAL(18,1)) AS Pct_Libre_Real
FROM    dbc.databases a  
LEFT OUTER JOIN( 
SELECT  databasename,
        SUM(CurrentPerm) CurrentPerm 
FROM    dbc.tablesize 
GROUP BY 1  ) b 
    ON a.databasename = b.databasename
LEFT OUTER JOIN( 
SELECT databasename, MAX(CurrentPerm) CurrentPerm
FROM( SELECT  databasename, vproc, sum(CurrentPerm) CurrentPerm 
FROM dbc.tablesize 
GROUP BY 1,2) TB group by 1 
) c
ON a.databasename = c.databasename
WHERE Asignado > 0
;


--Find updates 
SELECT logtbl.LogDate
    ,logtbl.QueryID
    ,logtbl.QueryText
    ,sqltbl.SqlTextInfo
	,logtbl.username
	,logtbl.logonsource
	,logtbl.clientid
	,logtbl.logondatetime
    ,logtbl.AMPCPUTime
	,logtbl.numofActiveAmps
FROM PDCRINFO.DBQLogTbl_Hst logtbl
INNER JOIN PDCRINFO.DBQLObjTbl_Hst objtbl
ON objtbl.logdate = logtbl.logdate
AND objtbl.queryid = logtbl.queryid
INNER JOIN PDCRINFO.DBQLSqlTbl_Hst sqltbl
ON logtbl.LogDate = sqltbl.LogDate
AND logtbl.QueryId = sqltbl.QueryId
where logtbl.logdate BETWEEN '2020-03-01' AND CURRENT_DATE
AND objtbl.ObjectTableName = 'PRODUCT'
AND objtbl.ObjectDatabaseName = 'E_DW_TABLES'
AND sqltbl.sqltextinfo like '%UPDATE%'
order by logtbl.logdate;

