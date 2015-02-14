# DZ_WKT
PL/SQL code for the conversion of OGC WKT to and from Oracle Spatial MDSYS.SDO_GEOMETRY

This library is provided for testing and feedback.  It may be installed and executed from any schema.  The deployment script creates three packages:
1. DZ\_WKT\_MAIN
2. DZ\_WKT\_TEST
3. DZ\_WKT\_UTIL
The test package is not needed for normal usage but always a good idea to inspect and keep around.

Some simple usage:

SELECT dz\_wkt\_main.sdo2wkt(MDSYS.SDO\_GEOMETRY(2001,8265,SDO\_POINT\_TYPE(-100,200,NULL),NULL,NULL)) FROM dual;

SELECT dz\_wkt\_main.wkt2sdo('POINT(-100 200)') FROM dual;



