IF NOT EXISTS ( SELECT O.object_id, C.column_id, C.NAME FROM  SYS.OBJECTS O INNER    JOIN SYS.columns C ON O.object_id = C.object_id  
               WHERE O.NAME = 'FTRD'  AND   C.NAME = 'TCOPAGO')
BEGIN
   ALTER TABLE FTRD   ADD  TCOPAGO VARCHAR(10)
END
IF NOT EXISTS ( SELECT O.object_id, C.column_id, C.NAME FROM  SYS.OBJECTS O INNER    JOIN SYS.columns C ON O.object_id = C.object_id  
               WHERE O.NAME = 'FTRDC'  AND   C.NAME = 'TCOPAGO')
BEGIN
   ALTER TABLE FTRDC   ADD  TCOPAGO VARCHAR(10)
END