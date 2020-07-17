
--Separate characters from the first number:
SEL Entrada,Salida
FROM
(
SELECT 
'Adsd56BC04x56' (VARCHAR(100)) AS Entrada
,INDEX(Entrada,REGEXP_SUBSTR(Entrada, '[0-9]', 1, 1, 'i')) AS Pos1Num
,SUBSTR(Entrada,1,Pos1Num-1)||'|'||SUBSTR(Entrada,Pos1Num) AS Salida
) X

/*
Entrada	Salida
Adsd56BC04x56	Adsd|56BC04x56
*/
