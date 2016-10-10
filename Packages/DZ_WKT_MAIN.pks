CREATE OR REPLACE PACKAGE dz_wkt_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_WKT
     
   - Build ID: DZBUILDIDDZ
   - Change Set: DZCHANGESETDZ
   
   Utility for the exchange of geometries between Oracle Spatial and OGC
   Well Known Text 1.2.1 / PostGIS Extended WKT formats.
   
   */
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------

   TYPE rec_token IS RECORD (
       t_name   VARCHAR2(32 Char)
      ,t_pad    PLS_INTEGER
      ,t_regex  VARCHAR2(255 Char)
      ,t_class  VARCHAR2(16 Char)
   );

   TYPE tbl_token IS TABLE OF rec_token
   INDEX BY PLS_INTEGER;

   TYPE rec_parsed IS RECORD (
       token       VARCHAR2(32 Char)
      ,start_pos   PLS_INTEGER
      ,length_item PLS_INTEGER
      ,num_dims    PLS_INTEGER
      ,t_class     VARCHAR2(16 Char)
      ,shape       MDSYS.SDO_GEOMETRY
   );

   TYPE tbl_parsed IS TABLE OF rec_parsed
   INDEX BY PLS_INTEGER;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_wkt_main.wkt2sdo

   Function for conversion of OGC Well Known Text Simple Features 1.21 and 
   Extended WKT into Oracle Spatial SDO_GEOMETRY.  Currently only straight-line 
   geometries are supported.

   Parameters:

      p_input - WKT geometry as CLOB
      p_srid - Optional SRID value to apply to resulting SDO_GEOMETRY.
      p_num_dims - Optional number of expected dimensions value
      p_axes_latlong - Option to interpret WKT long and lat as lat and long

   Returns:

      MDSYS.SDO_GEOMETRY spatial type
      
   Notes:
   
   -  Pure WKT has no concept of coordinate system so utilize the *p_srid* parameter
      to define the SRID of the output SDO_GEOMETRY object.  If *p_srid* is undefined
      or left NULL then the resulting SDO_GEOMETRY will have a NULL SRID.  If the input is 
      EWKT with a SRID prefix then that SRID will be used unless overridden by 
      using *p_srid*.  For example, *SRID=4269;POINT(1 2)* will use 4269 in the 
      output SDO unless overridden.  EWKT SRIDs with value 0 are converted to NULL 
      SRID unless overridden.
   
   -  DZ_WKT supports EWKT where additional dimensions are implied (e.g. WKT without 
      a Z or M notation).  For example *POINT(1 2 3)* is converted equivalent to 
      *POINT Z(1 2 3)*.  However this involves pretesting the count of ordinates 
      to verify the dimensions and consistency.  You may increase performance by 
      setting *p_num_dims* to the number of dimensions you know to be in your 
      input geometry.     
   
   -  In some cases WKT with reverse X and Y has been observed in the wild.  This is
      most troublesome to correct.  Use this flag to allow the input of such broken
      WKT geometries.  Note in an ideal world this should never happen.
   
   -  *POINT EMPTY* and similar empty geometries simply return NULL.

   */
   PROCEDURE wkt2sdo(
       p_input            IN  CLOB
      ,p_srid             IN  NUMBER   DEFAULT NULL
      ,p_num_dims         IN  NUMBER   DEFAULT NULL
      ,p_axes_latlong     IN  VARCHAR2 DEFAULT NULL
      ,p_output           OUT MDSYS.SDO_GEOMETRY
      ,p_return_code      OUT NUMBER
      ,p_status_message   OUT VARCHAR
   );
   
   FUNCTION wkt2sdo(
       p_input            IN  CLOB
      ,p_srid             IN  NUMBER   DEFAULT NULL
      ,p_num_dims         IN  NUMBER   DEFAULT NULL
      ,p_axes_latlong     IN  VARCHAR2 DEFAULT NULL
   ) RETURN MDSYS.SDO_GEOMETRY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_wkt_main.sdo2wkt

   Function for conversion of Oracle Spatial SDO_GEOMETRY into OGC Well Known 
   Text Simple Features 1.21 or Extended WKT.  Currently only straight-line 
   geometries are supported.

   Parameters:

      p_input - MDSYS.SDO_GEOMETRY object to convert into WKT or EWKT.
      p_2d_flag - Optional TRUE/FALSE flag to remove Z and M dimensions.
      p_output_srid - Optional SRID to transform geometry before conversion.
      p_prune_number - Optional length to truncate precision of ordinates.
      p_add_ewkt_srid - Option to add EWKT SRID as prefix to output.

   Returns:

      CLOB text in WKT or EWKT format
   
   Notes:
   
    - Ordinate precision pruning also affects any Z or M ordinates.
      
    - *p_add_ewkt_srid* takes values of TRUE, FALSE or a numeric SRID.  TRUE
      will output the final SRID of the geometry (after any transformations
      requested by *p_output_srid*).  Entering a numeric SRID will overrule
      the actual SRID.   
      
   */
   FUNCTION sdo2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_add_ewkt_srid    IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB;

END dz_wkt_main;
/

GRANT EXECUTE ON dz_wkt_main TO public;

