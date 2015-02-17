CREATE OR REPLACE PACKAGE dz_wkt_util
AUTHID CURRENT_USER
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN VARCHAR2
      ,p_regex            IN VARCHAR2
      ,p_match            IN VARCHAR2 DEFAULT NULL
      ,p_end              IN NUMBER   DEFAULT 0
      ,p_trim             IN VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN VARCHAR2
      ,p_null_replacement IN NUMBER DEFAULT NULL
   ) RETURN NUMBER;
   
   ----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION true_point(
      p_input      IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2d(
      p_input   IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE verify_ordinate_rotation(
       p_rotation    IN            VARCHAR2
      ,p_input       IN OUT NOCOPY MDSYS.SDO_GEOMETRY
      ,p_lower_bound IN            PLS_INTEGER DEFAULT 1
      ,p_upper_bound IN            PLS_INTEGER DEFAULT NULL
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE test_ordinate_rotation(
       p_input       IN  MDSYS.SDO_GEOMETRY
      ,p_lower_bound IN  NUMBER DEFAULT 1
      ,p_upper_bound IN  NUMBER DEFAULT NULL
      ,p_results     OUT VARCHAR2
      ,p_area        OUT NUMBER
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION test_ordinate_rotation(
       p_input       IN  MDSYS.SDO_GEOMETRY
      ,p_lower_bound IN  NUMBER DEFAULT 1
      ,p_upper_bound IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION test_ordinate_rotation(
       p_input       IN MDSYS.SDO_ORDINATE_ARRAY
      ,p_lower_bound IN NUMBER DEFAULT 1
      ,p_upper_bound IN NUMBER DEFAULT NULL
      ,p_num_dims    IN NUMBER DEFAULT 2
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE reverse_ordinate_rotation(
       p_input       IN OUT NOCOPY MDSYS.SDO_GEOMETRY
      ,p_lower_bound IN            PLS_INTEGER DEFAULT 1
      ,p_upper_bound IN            PLS_INTEGER DEFAULT NULL
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE reverse_ordinate_rotation(
       p_input       IN OUT NOCOPY MDSYS.SDO_ORDINATE_ARRAY
      ,p_lower_bound IN            PLS_INTEGER DEFAULT 1
      ,p_upper_bound IN            PLS_INTEGER DEFAULT NULL
      ,p_num_dims    IN            PLS_INTEGER DEFAULT 2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION reverse_ordinate_rotation(
       p_input       IN  MDSYS.SDO_ORDINATE_ARRAY
      ,p_lower_bound IN  NUMBER DEFAULT 1
      ,p_upper_bound IN  NUMBER DEFAULT NULL
      ,p_num_dims    IN  NUMBER DEFAULT 2
   ) RETURN MDSYS.SDO_ORDINATE_ARRAY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE sdo_append(
       p_target             IN OUT MDSYS.SDO_ELEM_INFO_ARRAY
      ,p_input              IN     NUMBER
      ,p_input_2            IN     NUMBER DEFAULT NULL
      ,p_input_3            IN     NUMBER DEFAULT NULL
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE sdo_append(
       p_target             IN OUT MDSYS.SDO_ELEM_INFO_ARRAY
      ,p_input              IN     MDSYS.SDO_ELEM_INFO_ARRAY
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE sdo_append(
       p_target             IN OUT MDSYS.SDO_ORDINATE_ARRAY
      ,p_input              IN     NUMBER
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE sdo_append(
       p_target             IN OUT MDSYS.SDO_ORDINATE_ARRAY
      ,p_input              IN     MDSYS.SDO_ORDINATE_ARRAY
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_varchar2(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_clob(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION smart_transform(
      p_input     IN  MDSYS.SDO_GEOMETRY,
      p_srid      IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY;

END dz_wkt_util;
/

GRANT EXECUTE ON dz_wkt_util TO public;

