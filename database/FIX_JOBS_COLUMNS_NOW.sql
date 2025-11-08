SELECT
    t.name AS Table_Name,
    c.name AS Column_Name
FROM
    sys.tables AS t
INNER JOIN
    sys.columns AS c ON t.object_id = c.object_id
ORDER BY
    Table_Name, Column_Name;