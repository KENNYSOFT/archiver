SELECT s.`no`, s.description, s.`type`, l.revision, l.archived_at, LEFT(l.content, 256)
FROM (SELECT a.*
	FROM archiver.archive a
		INNER JOIN (SELECT source_no, MAX(revision) AS revision FROM archiver.archive GROUP BY source_no) a2 ON a.source_no = a2.source_no AND a.revision = a2.revision
	WHERE a.content IS NOT NULL) l
	RIGHT OUTER JOIN archiver.source s ON l.source_no = s.`no`
ORDER BY s.`no` ASC;
