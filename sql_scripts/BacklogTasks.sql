SELECT revisioninfo.SCM, revisioninfo.KALL, 
CASE
WHEN GROUP_CONCAT(DISTINCT t.assignee) IS NOT NULL
THEN GROUP_CONCAT(DISTINCT t.assignee SEPARATOR ', ')
WHEN revisioninfo.Team IS NOT NULL
THEN 
(SELECT techWriterId FROM nzteam.techwriterassignment 
WHERE teamId=(SELECT id FROM nzteam.teams WHERE name=revisioninfo.Team))
ELSE
NULL
END AS writer_id,

CASE 
WHEN GROUP_CONCAT(DISTINCT kp.firstname SEPARATOR ', ') IS NOT NULL
THEN GROUP_CONCAT(DISTINCT kp.firstname SEPARATOR ', ')

WHEN revisioninfo.Team IS NOT NULL 
THEN 
(SELECT kall.person.firstname FROM nzteam.techwriterassignment 
INNER JOIN kall.person ON techWriterId = kall.person.id
WHERE teamId=(SELECT id FROM nzteam.teams WHERE name=revisioninfo.Team))
ELSE
NULL
END

 AS 'Writer',
revisioninfo.Team,
revisioninfo.Title, 
revisioninfo.Type,
revisioninfo.CRN_Status, 
revisioninfo.TW_Status, 
revisioninfo.Dev_Status, 
revisioninfo.QA_Status,
CONVERT(revisioninfo.completeddate,date) AS 'SC Closed', 
revisioninfo.Requestor,
revisioninfo.Revision


FROM (

SELECT sc.id, sc.completeddate, sc.businessid AS 'SCM',
GROUP_CONCAT(DISTINCT i.businessid ORDER BY i.businessid ASC SEPARATOR ', ') AS 'KALL',

GROUP_CONCAT(DISTINCT 
CASE 

WHEN pi.id IN (SELECT pi_id FROM nzteam.teamProjectIterations)

THEN (SELECT name FROM nzteam.teams WHERE id IN (SELECT team_id FROM nzteam.teamProjectIterations WHERE pi_id = pi.id ))


WHEN te.name IS NOT NULL AND te.isActive=1 
THEN te.name

WHEN sc.createdby IN (SELECT kallPersonID FROM nzteam.teamPersonMemberships)
THEN (SELECT name FROM nzteam.teams INNER JOIN nzteam.teamPersonMemberships ON teams.id=teamPersonMemberships.teamId WHERE sc.createdby=teamPersonMemberships.kallPersonId )

ELSE NULL

END
ORDER BY 1 SEPARATOR ', '
)
AS 'Team',

IFNULL(GROUP_CONCAT(DISTINCT 
IF(t.documentationtasktype IN 
('CUSTOMER_RELEASE_NOTICE'),
UPPER(t.status)
, NULL) SEPARATOR ', ') ,

CASE sc.includeincustomerreleasenotice
WHEN 'YES' THEN 'REQUIRED (NO CRN TASK)'
WHEN 'NO' THEN 'NOT REQUIRED'
ELSE 'UNSET'
END
)
AS 'CRN_Status',

IFNULL(GROUP_CONCAT(DISTINCT 
IF(t.documentationtasktype = 'TECHNICAL_WRITING',
UPPER(t.status)
, NULL) ORDER BY 
t.status <> 'Unassigned',
t.status  <> 'Assigned',
t.status <> 'In Progress',
t.status <> 'Awaiting Feedback',
t.status<> 'Completed'
SEPARATOR ',<br />' ) ,

CASE sc.technicalWritingRequired
WHEN 'YES' THEN 'REQUIRED (NO TW TASK)'
WHEN 'NO' THEN 'NOT REQUIRED'
ELSE 'UNSET'

END


)
AS 'TW_Status',
sc.Title AS 'Title', sc.type AS 'Type',

da.developmentstatus AS 'Dev_Status',
da.qastatus AS 'QA_Status',



GROUP_CONCAT(DISTINCT CONCAT(rg.name, '_', r.major, IF(ISNULL(r.minor), '', CONCAT('_', r.minor)), IF(ISNULL(r.patch), '', CONCAT('_', r.patch)) ) SEPARATOR '<br />') AS 'Revision' ,

GROUP_CONCAT(DISTINCT org.name SEPARATOR ', ') AS 'Requestor',

CASE (GROUP_CONCAT(r.releasedate) IS NOT NULL) 
WHEN 1 THEN 'YES'
ELSE 'NO'
END
AS 'Released'

FROM scm.softwarechange sc



INNER JOIN scm.targetedrevisions tr
ON tr.softwarechangeid = sc.id


INNER JOIN scm.revision r
ON
r.id = tr.revisionid

INNER JOIN scm.revisiongroup rg
ON rg.id = r.revisiongroupid

INNER JOIN scm.softwarechangederivedattributes da
ON da.id = sc.id

LEFT JOIN kall.softwarechangelink sl
ON sl.softwarechangeid = sc.businessid

LEFT JOIN kall.issue i 
ON i.id = sl.issueid

LEFT JOIN kall.organisation org
ON org.id = i.reportedat

LEFT JOIN scm.task t
ON t.softwarechangeid = sc.id 
AND t.status NOT IN ('CANCELLED','MOVED')
#AND (t.documentationtasktype IS NULL OR t.documentationtasktype NOT IN ('CUSTOMER_RELEASE_NOTICE', 'TECHNICAL_WRITING'))

LEFT JOIN nzteam.teamPersonMemberships m
ON m.kallPersonId=t.assignee

LEFT JOIN nzteam.teams te
ON te.id=m.teamId

LEFT JOIN scm.projectiteration pi
ON pi.id=sc.iteration



WHERE sc.id IN(SELECT DISTINCT softwarechangeid from scm.targetedrevisions tr
WHERE tr.revisionid IN (
SELECT revision FROM scm.dashboardentry 
WHERE 
(archived>'2019-11-07')

))



-- AND da.developmentstatus  IN ('COMPLETED', 'PENDING_COMMIT')


AND (
sc.includeincustomerreleasenotice = 'UNSET'

OR 
(
sc.includeincustomerreleasenotice = 'YES' AND NOT EXISTS (SELECT softwarechangeid FROM scm.task ta WHERE ta.softwarechangeid = tr.softwarechangeid AND documentationtasktype IN('CUSTOMER_RELEASE_NOTICE')
AND status IN ('completed'))
)

OR 
(
sc.technicalWritingRequired = 'YES' AND 
(
NOT EXISTS (SELECT softwarechangeid FROM scm.task ta WHERE ta.softwarechangeid = tr.softwarechangeid AND documentationtasktype IN('TECHNICAL_WRITING') AND status IN ('completed'))
OR
EXISTS (SELECT softwarechangeid FROM scm.task ta WHERE ta.softwarechangeid = tr.softwarechangeid AND documentationtasktype IN('TECHNICAL_WRITING') AND status NOT IN ('cancelled', 'completed'))
)
)
)

AND rg.name <>'Droid'

GROUP BY sc.id

) AS revisioninfo


LEFT JOIN scm.task t ON
t.softwarechangeid=revisioninfo.id
AND t.status NOT IN ('COMPLETED', 'CANCELLED', 'MOVED') AND t.documentationtasktype IN ('CUSTOMER_RELEASE_NOTICE','TECHNICAL_WRITING')

LEFT JOIN kall.person kp ON kp.id=t.assignee

WHERE revisioninfo.Released = 'Yes'

GROUP BY SCM

ORDER BY Writer,

CASE CRN_Status
WHEN  'COMPLETED' THEN 0
WHEN  'AWAITING FEEDBACK' THEN 1
WHEN  'IN PROGRESS' THEN 2
WHEN  'ASSIGNED' THEN 3
WHEN  'UNASSIGNED' THEN 4
WHEN  'UNSET' THEN 5
ELSE 6
END,


CASE TW_Status
WHEN  'COMPLETED' THEN 0
WHEN  'AWAITING FEEDBACK' THEN 1
WHEN  'IN PROGRESS' THEN 2
WHEN  'ASSIGNED' THEN 3
WHEN  'UNASSIGNED' THEN 4
WHEN  'REQUIRED (NO TW TASK)' THEN 5
WHEN  'UNSET' THEN 6
ELSE 7
END,

CASE Dev_Status
WHEN  'COMPLETED' THEN 0
WHEN  'PENDING_COMMIT' THEN 1
WHEN  'AWAITING_REWORK' THEN 2
WHEN  'AWAITING_QA' THEN 3
WHEN 'IN_PROGRESS' THEN 4
WHEN  'PENDING' THEN 5
END
,

CASE QA_Status
WHEN  'COMPLETED' THEN 0
WHEN  'AWAITING_REWORK' THEN 1
WHEN  'IN_PROGRESS' THEN 2
WHEN  'PENDING' THEN 3
WHEN  'AWAITING_DEV' THEN 4
END

,


team,
t.documentationtasktype
