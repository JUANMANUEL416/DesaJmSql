IF NOT EXISTS ( SELECT O.object_id, C.column_id, C.NAME FROM  SYS.OBJECTS O INNER    JOIN SYS.columns C ON O.object_id = C.object_id  
               WHERE O.NAME = 'MAGP'  AND   C.NAME = 'TIPO_ATEN')
BEGIN
   ALTER TABLE MAGP  ADD  TIPO_ATEN VARCHAR(20)
END