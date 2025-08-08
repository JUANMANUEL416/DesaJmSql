IF NOT EXISTS ( SELECT O.object_id, C.column_id, C.NAME FROM  SYS.OBJECTS O INNER    JOIN SYS.columns C ON O.object_id = C.object_id  
               WHERE O.NAME = 'KMCOM'  AND   C.NAME = 'MIVA')
BEGIN
   ALTER TABLE  KMCOM ADD MIVA BIT  
END
IF NOT EXISTS ( SELECT O.object_id, C.column_id, C.NAME FROM  SYS.OBJECTS O INNER    JOIN SYS.columns C ON O.object_id = C.object_id  
               WHERE O.NAME = 'KMCOM'  AND   C.NAME = 'CUENTAIVA')
BEGIN
   ALTER TABLE  KMCOM ADD CUENTAIVA VARCHAR(20)  
END
IF NOT EXISTS ( SELECT O.object_id, C.column_id, C.NAME FROM  SYS.OBJECTS O INNER    JOIN SYS.columns C ON O.object_id = C.object_id  
               WHERE O.NAME = 'KMCOMS'  AND   C.NAME = 'MIVA')
BEGIN
   ALTER TABLE  KMCOMS ADD MIVA BIT  
END
IF NOT EXISTS ( SELECT O.object_id, C.column_id, C.NAME FROM  SYS.OBJECTS O INNER    JOIN SYS.columns C ON O.object_id = C.object_id  
               WHERE O.NAME = 'KMCOMS'  AND   C.NAME = 'CUENTAIVA')
BEGIN
   ALTER TABLE  KMCOMS ADD CUENTAIVA VARCHAR(20)  
END