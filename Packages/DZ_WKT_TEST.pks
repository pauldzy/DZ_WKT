CREATE OR REPLACE PACKAGE dz_wkt_test
AUTHID CURRENT_USER
AS

   C_TFS_CHANGESET CONSTANT NUMBER := 0.0;
   C_JENKINS_JOBNM CONSTANT VARCHAR2(255) := 'NULL';
   C_JENKINS_BUILD CONSTANT NUMBER := 0.0;
   C_JENKINS_BLDID CONSTANT VARCHAR2(255) := 'NULL';
   
   C_PREREQUISITES CONSTANT MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY(
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER;
   

END dz_wkt_test;
/

GRANT EXECUTE ON dz_wkt_test TO public;
