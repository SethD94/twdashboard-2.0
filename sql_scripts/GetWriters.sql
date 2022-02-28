SELECT p.ID, p.firstname, p.lastname, p.fullname FROM kall.person p
INNER JOIN kall.personrole pr ON p.id = pr.owner
INNER JOIN scm.userpermissions up ON up.id= p.id AND (up.documentation=1 OR up.documentationmanager=1)
WHERE pr.enddate IS NULL AND pr.organisation = 2
ORDER BY p.firstname;