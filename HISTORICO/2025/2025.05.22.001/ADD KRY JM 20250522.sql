IF NOT EXISTS ( SELECT O.object_id, C.column_id, C.NAME FROM  SYS.OBJECTS O INNER JOIN SYS.columns C ON O.object_id = C.object_id  WHERE O.NAME = 'FTRD'  AND   C.NAME = 'CODCUMXML')
BEGIN
   ALTER TABLE FTRD  ADD CODCUMXML VARCHAR(20) 
END