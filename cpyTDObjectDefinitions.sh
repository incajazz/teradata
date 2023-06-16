##############################################################################################
#Purpose: copy Teradata objects' definition (tables and views) from a source_DB to a target_DB
#Execution: sh cpyTDObjectDefinitions.sh Source_DB "'TableKind'" Target_DB
#Examples:
# copying views: sh cpyTDObjectDefinitions.sh P_DIM_V "'V'" T_DIM_V
# copying tables: sh cpyTDObjectDefinitions.sh P_REL "'T','O'" T_REL
# Author: @incajazz
##############################################################################################
vDBSrc=$1
vObjKind=$2
vDBTgt=$3
PRM_FECHA_EJEC=`date +"%Y%m%d"`
PRM_ARCH_LOG=/home/SE31870A/cpyTDObjectsDefinitions_${PRM_FECHA_EJEC}.LOG
PRM_PATH_WRK=/home/SE31870A/
V_ListObjects=List_Objects_${vDBSrc}.SQL
V_DefObjects=DDL_Objects_${vDBTgt}.SQL
>${PRM_ARCH_LOG}
>${V_ListObjects}
>${V_DefObjects}

fGetDDLSource()
{
echo "get objects from ${vDBSrc}"
# -----------------------------------------------------------------------------------------#
#                  Obtiene DDLs                #
# -----------------------------------------------------------------------------------------#
 bteq <<EOF_1> ${PRM_ARCH_LOG} 2>&1
.SET ERROROUT STDOUT;
.LOGON tdprod/p_loader, ypfp_loader;
.SET ECHOREQ ON     
.SET TITLEDASHES OFF
.SET SEPARATOR '|'
.SET FORMAT OFF
.SET NULL ''
.SET WIDTH 4000

SELECT '-------------- Iniciamos Ejecucion del Script ---------------';
SELECT CURRENT_TIMESTAMP(6);

.OS rm ${PRM_PATH_WRK}${V_ListObjects}
.EXPORT REPORT File = ${PRM_PATH_WRK}${V_ListObjects}


/* Obtenemos definicion de Tablas */
.EXPORT REPORT File = '${PRM_PATH_WRK}${V_ListObjects}'
LOCKING ROW FOR ACCESS
SELECT       	
     (
          (
               CASE TableKind
                    WHEN 'T' THEN 'SHOW TABLE'
                    WHEN 'O' THEN 'SHOW TABLE'
                    WHEN 'V' THEN 'SHOW VIEW'
               ELSE '--'
               END
          )
          ||' '
          ||TRIM(T.DatabaseName)
          ||'."'
          ||TRIM(T.TABLENAME)
          ||'";'
     ) (TITLE '')
FROM DBC.TablesV T
WHERE UPPER(DatabaseName)=UPPER('${vDBSrc}')
     AND	T.TableKind IN (${vObjKind}) 
ORDER BY 	1;

.EXPORT RESET
.OS IF EXISTS ${PRM_PATH_WRK}${V_DefObjects} (rm ${PRM_PATH_WRK}${V_DefObjects})
.EXPORT REPORT File = ${PRM_PATH_WRK}${V_DefObjects}
.RUN File = '${PRM_PATH_WRK}${V_ListObjects}'
.EXPORT RESET

SELECT '-------------- Fin de Ejecucion del Script ---------------';
SELECT CURRENT_TIMESTAMP(6);

.LOGOFF
.QUIT
EOF_1
}

fTranslateEnv(){
#replace envs
echo "Replace"
sed -i "s/${vDBSrc}/${vDBTgt}/g" "${PRM_PATH_WRK}${V_DefObjects}"
sed -i "s/P_REL/T_REL/g" "${PRM_PATH_WRK}${V_DefObjects}"
sed -i "s/P_DIM/T_DIM/g" "${PRM_PATH_WRK}${V_DefObjects}"
}

fSetDDLTarget()
{
echo "create objects in ${vDBTgt}"
 bteq <<EOF_1> ${PRM_ARCH_LOG} 2>&1
.SET ERROROUT STDOUT;
.LOGON tddesa/t_loader, Ypf2023;
.SET ECHOREQ ON     
.SET TITLEDASHES OFF
.SET SEPARATOR '|'
.SET FORMAT OFF
.SET NULL ''
.SET WIDTH 4000

.EXPORT RESET
.RUN File = '${PRM_PATH_WRK}${V_DefObjects}'
.EXPORT RESET

SELECT '-------------- Fin de Ejecucion del Script ---------------';
SELECT CURRENT_TIMESTAMP(6);

.LOGOFF
.QUIT
EOF_1
}

##############################################################################
fGetDDLSource
fTranslateEnv
fSetDDLTarget