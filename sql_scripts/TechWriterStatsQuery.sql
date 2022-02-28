
SELECT 

MAKEDATE(YEAR(curdate()),(WEEK(st.completeddate)*7)+0) AS 'Week Beginning',
SUM(CASE kp.fullname WHEN 'Dennis Thorpe' THEN 1 ELSE 0 END) AS 'Dennis',
SUM(CASE kp.fullname WHEN 'Guy Halpe' THEN 1 ELSE 0 END) AS 'Guy',
SUM(CASE kp.fullname WHEN 'Janet Stevenson' THEN 1 ELSE 0 END) AS 'Janet',
SUM(CASE kp.fullname WHEN 'Paul Erith'  THEN 1 ELSE 0 END) AS 'Paul',
SUM(CASE kp.fullname WHEN 'Seth Delpachitra' THEN 1 ELSE 0 END) AS 'Seth',
SUM(CASE kp.fullname 
WHEN 'Paul Erith' THEN 1 
WHEN 'Guy Halpe' THEN 1 
WHEN 'Sam Norton' THEN 1
WHEN 'Seth Delpachitra' THEN 1
WHEN 'Dennis Thorpe' THEN 1
WHEN 'Janet Stevenson' THEN 1
ELSE 0 END) AS `Total`

FROM scm.task st

INNER JOIN kall.person kp
ON kp.id = st.completedby


WHERE st.documentationtasktype IN ( 'CUSTOMER_RELEASE_NOTICE', 'TECHNICAL_WRITING', 'GENERAL')
AND st.status='Completed'
AND st.completeddate IS NOT NULL 
AND st.completeddate >= MAKEDATE(YEAR(curdate()), 7) -- Set to 7 so that the first partial week is not included (there were no tech writers here that week anyway in 2018)


GROUP BY MAKEDATE(YEAR(curdate()),(WEEK(st.completeddate)*7)+0)
ORDER BY st.completeddate DESC;
