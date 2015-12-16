
--*************************--
PROMPT sqlplus_header.sql;

WHENEVER SQLERROR EXIT -99;
WHENEVER OSERROR  EXIT -98;
SET DEFINE OFF;



--*************************--
PROMPT DZ_WKT_UTIL.pks;

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


--*************************--
PROMPT DZ_WKT_UTIL.pkb;

CREATE OR REPLACE PACKAGE BODY dz_wkt_util
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN VARCHAR2
      ,p_regex            IN VARCHAR2
      ,p_match            IN VARCHAR2 DEFAULT NULL
      ,p_end              IN NUMBER   DEFAULT 0
      ,p_trim             IN VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC 
   AS
      int_delim      PLS_INTEGER;
      int_position   PLS_INTEGER := 1;
      int_counter    PLS_INTEGER := 1;
      ary_output     MDSYS.SDO_STRING2_ARRAY;
      num_end        NUMBER      := p_end;
      str_trim       VARCHAR2(5 Char) := UPPER(p_trim);
      
      FUNCTION trim_varray(
         p_input            IN MDSYS.SDO_STRING2_ARRAY
      ) RETURN MDSYS.SDO_STRING2_ARRAY
      AS
         ary_output MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY();
         int_index  PLS_INTEGER := 1;
         str_check  VARCHAR2(4000 Char);
         
      BEGIN

         --------------------------------------------------------------------------
         -- Step 10
         -- Exit if input is empty
         --------------------------------------------------------------------------
         IF p_input IS NULL
         OR p_input.COUNT = 0
         THEN
            RETURN ary_output;
         END IF;

         --------------------------------------------------------------------------
         -- Step 20
         -- Trim the strings removing anything utterly trimmed away
         --------------------------------------------------------------------------
         FOR i IN 1 .. p_input.COUNT
         LOOP
            str_check := TRIM(p_input(i));
            IF str_check IS NULL
            OR str_check = ''
            THEN
               NULL;
            ELSE
               ary_output.EXTEND(1);
               ary_output(int_index) := str_check;
               int_index := int_index + 1;
            END IF;

         END LOOP;

         --------------------------------------------------------------------------
         -- Step 10
         -- Return the results
         --------------------------------------------------------------------------
         RETURN ary_output;

      END trim_varray;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Create the output array and check parameters
      --------------------------------------------------------------------------
      ary_output := MDSYS.SDO_STRING2_ARRAY();

      IF str_trim IS NULL
      THEN
         str_trim := 'FALSE';
         
      ELSIF str_trim NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'Boolean Error!');
         
      END IF;

      IF num_end IS NULL
      THEN
         num_end := 0;
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Exit early if input is empty
      --------------------------------------------------------------------------
      IF p_str IS NULL
      OR p_str = ''
      THEN
         RETURN ary_output;
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Account for weird instance of pure character breaking
      --------------------------------------------------------------------------
      IF p_regex IS NULL
      OR p_regex = ''
      THEN
         FOR i IN 1 .. LENGTH(p_str)
         LOOP
            ary_output.EXTEND(1);
            ary_output(i) := SUBSTR(p_str,i,1);
         END LOOP;
         
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Break string using the usual REGEXP functions
      --------------------------------------------------------------------------
      LOOP
         EXIT WHEN int_position = 0;
         int_delim  := REGEXP_INSTR(p_str,p_regex,int_position,1,0,p_match);
         
         IF  int_delim = 0
         THEN
            -- no more matches found
            ary_output.EXTEND(1);
            ary_output(int_counter) := SUBSTR(p_str,int_position);
            int_position  := 0;
            
         ELSE
            IF int_counter = num_end
            THEN
               -- take the rest as is
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position);
               int_position  := 0;
               
            ELSE
               --dbms_output.put_line(ary_output.COUNT);
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position,int_delim-int_position);
               int_counter := int_counter + 1;
               int_position := REGEXP_INSTR(p_str,p_regex,int_position,1,1,p_match);
               
            END IF;
            
         END IF;
         
      END LOOP;

      --------------------------------------------------------------------------
      -- Step 50
      -- Trim results if so desired
      --------------------------------------------------------------------------
      IF str_trim = 'TRUE'
      THEN
         RETURN trim_varray(
            p_input => ary_output
         );
      END IF;

      --------------------------------------------------------------------------
      -- Step 60
      -- Cough out the results
      --------------------------------------------------------------------------
      RETURN ary_output;
      
   END gz_split;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN VARCHAR2
      ,p_null_replacement IN NUMBER DEFAULT NULL
   ) RETURN NUMBER
   AS
   BEGIN
      RETURN TO_NUMBER(
         REPLACE(
            REPLACE(
               p_input,
               CHR(10),
               ''
            ),
            CHR(13),
            ''
         ) 
      );
      
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         RETURN p_null_replacement;
         
   END safe_to_number;

   ----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION true_point(
      p_input      IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
   BEGIN

      IF p_input.SDO_POINT IS NOT NULL
      THEN
         RETURN p_input;
         
      END IF;

      IF p_input.get_gtype() = 1
      THEN
         IF p_input.get_dims() = 2
         THEN
            RETURN MDSYS.SDO_GEOMETRY(
                p_input.SDO_GTYPE
               ,p_input.SDO_SRID
               ,MDSYS.SDO_POINT_TYPE(
                   p_input.SDO_ORDINATES(1)
                  ,p_input.SDO_ORDINATES(2)
                  ,NULL
                )
               ,NULL
               ,NULL
            );
            
         ELSIF p_input.get_dims() = 3
         THEN
            RETURN MDSYS.SDO_GEOMETRY(
                p_input.SDO_GTYPE
               ,p_input.SDO_SRID
               ,MDSYS.SDO_POINT_TYPE(
                    p_input.SDO_ORDINATES(1)
                   ,p_input.SDO_ORDINATES(2)
                   ,p_input.SDO_ORDINATES(3)
                )
               ,NULL
               ,NULL
            );
            
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'function true_point can only work on 2 and 3 dimensional points - dims=' || p_input.get_dims() || ' '
            );
            
         END IF;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'function true_point can only work on point geometries'
         );
         
      END IF;
      
   END true_point;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2d(
      p_input   IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   -- Taken from Albert Godfrind's Yellow Book
   AS
      geom_2d       MDSYS.SDO_GEOMETRY;
      dim_count     PLS_INTEGER;
      gtype         PLS_INTEGER;
      n_points      PLS_INTEGER;
      n_ordinates   PLS_INTEGER;
      i             PLS_INTEGER;
      j             PLS_INTEGER;
      k             PLS_INTEGER;
      offset        PLS_INTEGER;
      
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN NULL;
      END IF;

      IF LENGTH (p_input.SDO_GTYPE) = 4
      THEN
         dim_count := p_input.get_dims();
         gtype     := p_input.get_gtype();
      ELSE
         RAISE_APPLICATION_ERROR(-20001, 'Unable to determine dimensionality from gtype');
      END IF;

      IF dim_count = 2
      THEN
         RETURN p_input;
      END IF;

      geom_2d := MDSYS.SDO_GEOMETRY(
          2000 + gtype
         ,p_input.sdo_srid
         ,p_input.sdo_point
         ,SDO_ELEM_INFO_ARRAY()
         ,SDO_ORDINATE_ARRAY()
      );

      IF geom_2d.sdo_point IS NOT NULL
      THEN
         geom_2d.sdo_point.z   := NULL;
         geom_2d.sdo_elem_info := NULL;
         geom_2d.SDO_ORDINATES := NULL;
         
      ELSE
         n_points    := p_input.SDO_ORDINATES.COUNT / dim_count;
         n_ordinates := n_points * 2;
         geom_2d.SDO_ORDINATES.EXTEND(n_ordinates);
         j := p_input.SDO_ORDINATES.FIRST;
         k := 1;
         
         FOR i IN 1 .. n_points
         LOOP
            geom_2d.SDO_ORDINATES(k) := p_input.SDO_ORDINATES(j);
            geom_2d.SDO_ORDINATES(k + 1) := p_input.SDO_ORDINATES(j + 1);
            j := j + dim_count;
            k := k + 2;
         
         END LOOP;

         geom_2d.sdo_elem_info := p_input.sdo_elem_info;

         i := geom_2d.SDO_ELEM_INFO.FIRST;
         WHILE i < geom_2d.SDO_ELEM_INFO.LAST
         LOOP
            offset := geom_2d.SDO_ELEM_INFO(i);
            geom_2d.SDO_ELEM_INFO(i) := (offset - 1) / dim_count * 2 + 1;
            i := i + 3;
            
         END LOOP;

      END IF;

      IF geom_2d.SDO_GTYPE = 2001
      THEN
         RETURN true_point(geom_2d);
         
      ELSE
         RETURN geom_2d;
         
      END IF;

   END downsize_2d;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE verify_ordinate_rotation(
       p_rotation    IN            VARCHAR2
      ,p_input       IN OUT NOCOPY MDSYS.SDO_GEOMETRY
      ,p_lower_bound IN            PLS_INTEGER DEFAULT 1
      ,p_upper_bound IN            PLS_INTEGER DEFAULT NULL
   )
   AS
      str_rotation  VARCHAR2(3 Char);
      int_lb        PLS_INTEGER := p_lower_bound;
      int_ub        PLS_INTEGER := p_upper_bound;
      
   BEGIN

      IF p_rotation NOT IN ('CW','CCW')
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'rotation values are CW or CCW'
         );
         
      END IF;

      IF p_upper_bound IS NULL
      THEN
         int_ub  := p_input.SDO_ORDINATES.COUNT;
      END IF;

      str_rotation := test_ordinate_rotation(
          p_input       => p_input
         ,p_lower_bound => int_lb
         ,p_upper_bound => int_ub
      );
 
      IF p_rotation = str_rotation
      THEN
         RETURN;
         
      ELSE
         reverse_ordinate_rotation(
             p_input       => p_input
            ,p_lower_bound => p_lower_bound
            ,p_upper_bound => p_upper_bound
         );
         
         RETURN;
         
      END IF;

   END verify_ordinate_rotation;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE test_ordinate_rotation(
      p_input       IN  MDSYS.SDO_GEOMETRY,
      p_lower_bound IN  NUMBER DEFAULT 1,
      p_upper_bound IN  NUMBER DEFAULT NULL,
      p_results     OUT VARCHAR2,
      p_area        OUT NUMBER
   )
   AS
      int_dims      PLS_INTEGER;
      int_lb        PLS_INTEGER := p_lower_bound;
      int_ub        PLS_INTEGER := p_upper_bound;
      num_x         NUMBER;
      num_y         NUMBER;
      num_lastx     NUMBER;
      num_lasty     NUMBER;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF int_ub IS NULL
      THEN
         int_ub  := p_input.SDO_ORDINATES.COUNT;
      END IF;

      IF int_lb IS NULL
      THEN
         int_lb  := 1;
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Get the number of dimensions in the geometry
      --------------------------------------------------------------------------
      int_dims := p_input.get_dims();

      --------------------------------------------------------------------------
      -- Step 30
      -- Loop through the ordinates create the area value
      --------------------------------------------------------------------------
      p_area  := 0;
      num_lastx := 0;
      num_lasty := 0;
      WHILE int_lb <= int_ub
      LOOP
         num_x := p_input.SDO_ORDINATES(int_lb);
         num_y := p_input.SDO_ORDINATES(int_lb + 1);
         p_area := p_area + ( (num_lasty * num_x ) - ( num_lastx * num_y) );
         num_lastx := num_x;
         num_lasty := num_y;
         int_lb := int_lb + int_dims;
         
      END LOOP;

      --------------------------------------------------------------------------
      -- Step 40
      -- If area is positive, then its clockwise
      --------------------------------------------------------------------------
      IF p_area > 0
      THEN
         p_results := 'CW';
         
      ELSE
         p_results := 'CCW';
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 50
      -- Preserve the area value if required by the caller
      --------------------------------------------------------------------------
      p_area := ABS(p_area);

   END test_ordinate_rotation;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION test_ordinate_rotation(
       p_input       IN  MDSYS.SDO_GEOMETRY
      ,p_lower_bound IN  NUMBER DEFAULT 1
      ,p_upper_bound IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2
   AS
      str_results   VARCHAR2(3 Char);
      num_area      NUMBER;

   BEGIN

      test_ordinate_rotation(
          p_input       => p_input
         ,p_lower_bound => p_lower_bound
         ,p_upper_bound => p_upper_bound
         ,p_results     => str_results
         ,p_area        => num_area
      );

      RETURN str_results;

   END test_ordinate_rotation;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE test_ordinate_rotation(
       p_input       IN  MDSYS.SDO_ORDINATE_ARRAY
      ,p_lower_bound IN  NUMBER DEFAULT 1
      ,p_upper_bound IN  NUMBER DEFAULT NULL
      ,p_num_dims    IN  NUMBER DEFAULT 2
      ,p_results     OUT VARCHAR2
      ,p_area        OUT NUMBER
   )
   AS
      int_dims      PLS_INTEGER := p_num_dims;
      int_lb        PLS_INTEGER := p_lower_bound;
      int_ub        PLS_INTEGER := p_upper_bound;
      num_x         NUMBER;
      num_y         NUMBER;
      num_lastx     NUMBER;
      num_lasty     NUMBER;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF int_dims IS NULL
      THEN
        int_dims := 2;
        
      END IF;
      
      IF int_ub IS NULL
      THEN
         int_ub  := p_input.COUNT;
      
      END IF;

      IF int_lb IS NULL
      THEN
         int_lb  := 1;
      
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Loop through the ordinates create the area value
      --------------------------------------------------------------------------
      p_area  := 0;
      num_lastx := 0;
      num_lasty := 0;
      
      WHILE int_lb <= int_ub
      LOOP
         num_x := p_input(int_lb);
         num_y := p_input(int_lb + 1);
         p_area := p_area + ( (num_lasty * num_x ) - ( num_lastx * num_y) );
         num_lastx := num_x;
         num_lasty := num_y;
         int_lb := int_lb + int_dims;
         
      END LOOP;

      --------------------------------------------------------------------------
      -- Step 40
      -- If area is positive, then its clockwise
      --------------------------------------------------------------------------
      IF p_area > 0
      THEN
         p_results := 'CW';
         
      ELSE
         p_results := 'CCW';
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 50
      -- Preserve the area value if required by the caller
      --------------------------------------------------------------------------
      p_area := ABS(p_area);

   END test_ordinate_rotation;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION test_ordinate_rotation(
       p_input       IN MDSYS.SDO_ORDINATE_ARRAY
      ,p_lower_bound IN NUMBER DEFAULT 1
      ,p_upper_bound IN NUMBER DEFAULT NULL
      ,p_num_dims    IN NUMBER DEFAULT 2
   ) RETURN VARCHAR2
   AS
      str_results   VARCHAR2(3 Char);
      num_area      NUMBER;

   BEGIN

      test_ordinate_rotation(
          p_input       => p_input
         ,p_lower_bound => p_lower_bound
         ,p_upper_bound => p_upper_bound
         ,p_num_dims    => p_num_dims
         ,p_results     => str_results
         ,p_area        => num_area
      );

      RETURN str_results;

   END test_ordinate_rotation;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE reverse_ordinate_rotation(
       p_input       IN OUT NOCOPY MDSYS.SDO_GEOMETRY
      ,p_lower_bound IN            PLS_INTEGER DEFAULT 1
      ,p_upper_bound IN            PLS_INTEGER DEFAULT NULL
   ) 
   AS
      int_n         PLS_INTEGER;
      int_m         PLS_INTEGER;
      int_li        PLS_INTEGER;
      int_ui        PLS_INTEGER;
      num_tempx     NUMBER;
      num_tempy     NUMBER;
      num_tempz     NUMBER;
      num_tempm     NUMBER;
      int_lb        PLS_INTEGER := p_lower_bound;
      int_ub        PLS_INTEGER := p_upper_bound;
      int_dims      PLS_INTEGER;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF int_lb IS NULL
      THEN
         int_lb := 1;
      END IF;
      
      IF int_ub IS NULL
      THEN
         int_ub  := p_input.SDO_ORDINATES.COUNT;
      END IF;
      
      int_dims := p_input.get_dims();

      int_n := int_ub - int_lb + 1;

      -- Exit if only a single ordinate
      IF int_n <= int_dims
      THEN
         RETURN;
      END IF;

      -- Calculate the start n1, the end n2, and the middle m
      int_m  := int_lb + (int_n / 2);
      int_li := int_lb;
      int_ui := int_ub;
      WHILE int_li < int_m
      LOOP

         IF int_dims = 2
         THEN
            num_tempx := p_input.SDO_ORDINATES(int_li);
            num_tempy := p_input.SDO_ORDINATES(int_li + 1);

            p_input.SDO_ORDINATES(int_li)     := p_input.SDO_ORDINATES(int_ui - 1);
            p_input.SDO_ORDINATES(int_li + 1) := p_input.SDO_ORDINATES(int_ui);

            p_input.SDO_ORDINATES(int_ui - 1) := num_tempx;
            p_input.SDO_ORDINATES(int_ui)     := num_tempy;

         ELSIF int_dims = 3
         THEN
            num_tempx := p_input.SDO_ORDINATES(int_li);
            num_tempy := p_input.SDO_ORDINATES(int_li + 1);
            num_tempz := p_input.SDO_ORDINATES(int_li + 2);

            p_input.SDO_ORDINATES(int_li)     := p_input.SDO_ORDINATES(int_ui - 2);
            p_input.SDO_ORDINATES(int_li + 1) := p_input.SDO_ORDINATES(int_ui - 1);
            p_input.SDO_ORDINATES(int_li + 2) := p_input.SDO_ORDINATES(int_ui);

            p_input.SDO_ORDINATES(int_ui - 2) := num_tempx;
            p_input.SDO_ORDINATES(int_ui - 1) := num_tempy;
            p_input.SDO_ORDINATES(int_ui)     := num_tempz;
            
         ELSIF int_dims = 4
         THEN
            num_tempx := p_input.SDO_ORDINATES(int_li);
            num_tempy := p_input.SDO_ORDINATES(int_li + 1);
            num_tempz := p_input.SDO_ORDINATES(int_li + 2);
            num_tempm := p_input.SDO_ORDINATES(int_li + 3);

            p_input.SDO_ORDINATES(int_li)     := p_input.SDO_ORDINATES(int_ui - 3);
            p_input.SDO_ORDINATES(int_li + 1) := p_input.SDO_ORDINATES(int_ui - 2);
            p_input.SDO_ORDINATES(int_li + 2) := p_input.SDO_ORDINATES(int_ui - 1);
            p_input.SDO_ORDINATES(int_li + 3) := p_input.SDO_ORDINATES(int_ui);

            p_input.SDO_ORDINATES(int_ui - 3) := num_tempx;
            p_input.SDO_ORDINATES(int_ui - 2) := num_tempy;
            p_input.SDO_ORDINATES(int_ui - 1) := num_tempz;
            p_input.SDO_ORDINATES(int_ui)     := num_tempm;
            
         END IF;

         int_li := int_li + int_dims;
         int_ui := int_ui - int_dims;

      END LOOP;

   END reverse_ordinate_rotation;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE reverse_ordinate_rotation(
       p_input       IN OUT NOCOPY MDSYS.SDO_ORDINATE_ARRAY
      ,p_lower_bound IN            PLS_INTEGER DEFAULT 1
      ,p_upper_bound IN            PLS_INTEGER DEFAULT NULL
      ,p_num_dims    IN            PLS_INTEGER DEFAULT 2
   ) 
   AS
      int_n         PLS_INTEGER;
      int_m         PLS_INTEGER;
      int_li        PLS_INTEGER;
      int_ui        PLS_INTEGER;
      num_tempx     NUMBER;
      num_tempy     NUMBER;
      num_tempz     NUMBER;
      num_tempm     NUMBER;
      int_lb        PLS_INTEGER := p_lower_bound;
      int_ub        PLS_INTEGER := p_upper_bound;
      int_dims      PLS_INTEGER := p_num_dims;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF int_lb IS NULL
      THEN
         int_lb := 1;
         
      END IF;
      
      IF int_ub IS NULL
      THEN
         int_ub  := p_input.COUNT;
      
      END IF;
      
      IF int_dims IS NULL
      THEN
         int_dims := 2;
      
      END IF;

      int_n := int_ub - int_lb + 1;

      -- Exit if only a single ordinate
      IF int_n <= int_dims
      THEN
         RETURN;
         
      END IF;

      -- Calculate the start n1, the end n2, and the middle m
      int_m  := int_lb + (int_n / 2);
      int_li := int_lb;
      int_ui := int_ub;
      
      WHILE int_li < int_m
      LOOP
         IF int_dims = 2
         THEN
            num_tempx := p_input(int_li);
            num_tempy := p_input(int_li + 1);

            p_input(int_li)     := p_input(int_ui - 1);
            p_input(int_li + 1) := p_input(int_ui);

            p_input(int_ui - 1) := num_tempx;
            p_input(int_ui)     := num_tempy;

         ELSIF int_dims = 3
         THEN
            num_tempx := p_input(int_li);
            num_tempy := p_input(int_li + 1);
            num_tempz := p_input(int_li + 2);

            p_input(int_li)     := p_input(int_ui - 2);
            p_input(int_li + 1) := p_input(int_ui - 1);
            p_input(int_li + 2) := p_input(int_ui);

            p_input(int_ui - 2) := num_tempx;
            p_input(int_ui - 1) := num_tempy;
            p_input(int_ui)     := num_tempz;
            
         ELSIF int_dims = 4
         THEN
            num_tempx := p_input(int_li);
            num_tempy := p_input(int_li + 1);
            num_tempz := p_input(int_li + 2);
            num_tempm := p_input(int_li + 3);

            p_input(int_li)     := p_input(int_ui - 3);
            p_input(int_li + 1) := p_input(int_ui - 2);
            p_input(int_li + 2) := p_input(int_ui - 1);
            p_input(int_li + 3) := p_input(int_ui);

            p_input(int_ui - 3) := num_tempx;
            p_input(int_ui - 2) := num_tempy;
            p_input(int_ui - 1) := num_tempz;
            p_input(int_ui)     := num_tempm;
            
         END IF;

         int_li := int_li + int_dims;
         int_ui := int_ui - int_dims;

      END LOOP;

   END reverse_ordinate_rotation;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION reverse_ordinate_rotation(
       p_input       IN  MDSYS.SDO_ORDINATE_ARRAY
      ,p_lower_bound IN  NUMBER DEFAULT 1
      ,p_upper_bound IN  NUMBER DEFAULT NULL
      ,p_num_dims    IN  NUMBER DEFAULT 2
   ) RETURN MDSYS.SDO_ORDINATE_ARRAY
   AS
      sdo_ord_output MDSYS.SDO_ORDINATE_ARRAY;
      
   BEGIN
   
      sdo_ord_output := p_input;
      
      reverse_ordinate_rotation(
          sdo_ord_output
         ,p_lower_bound
         ,p_upper_bound
         ,p_num_dims
      );
      
      RETURN sdo_ord_output;
      
   END reverse_ordinate_rotation;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE sdo_append(
       p_target             IN OUT MDSYS.SDO_ELEM_INFO_ARRAY
      ,p_input              IN     NUMBER
      ,p_input_2            IN     NUMBER DEFAULT NULL
      ,p_input_3            IN     NUMBER DEFAULT NULL
   )
   AS
      int_index PLS_INTEGER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN;
      END IF;

      IF p_target IS NULL
      THEN
         p_target := MDSYS.SDO_ELEM_INFO_ARRAY();
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add first value
      --------------------------------------------------------------------------
      int_index := p_target.COUNT;
      p_target.EXTEND();
      p_target(int_index + 1) := p_input;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add extra values
      --------------------------------------------------------------------------
      IF p_input_2 IS NOT NULL
      THEN
         p_target.EXTEND();
         p_target(int_index + 2) := p_input_2;
      
         IF p_input_3 IS NOT NULL
         THEN
            p_target.EXTEND();
            p_target(int_index + 3) := p_input_3;
         
         END IF;
      
      END IF;

   END sdo_append;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE sdo_append(
       p_target             IN OUT MDSYS.SDO_ELEM_INFO_ARRAY
      ,p_input              IN     MDSYS.SDO_ELEM_INFO_ARRAY
   )
   AS
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN;
         
      END IF;

      FOR i IN 1 .. p_input.COUNT
      LOOP
         sdo_append(p_target,p_input(i));
         
      END LOOP;

   END sdo_append;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE sdo_append(
       p_target             IN OUT MDSYS.SDO_ORDINATE_ARRAY
      ,p_input              IN     NUMBER
   )
   AS
      int_index PLS_INTEGER;
      
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN;
         
      END IF;

      IF p_target IS NULL
      THEN
         p_target := MDSYS.SDO_ORDINATE_ARRAY();
         
      END IF;

      int_index := p_target.COUNT;
      
      p_target.EXTEND();
      
      p_target(int_index + 1) := p_input;

   END sdo_append;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE sdo_append(
       p_target             IN OUT MDSYS.SDO_ORDINATE_ARRAY
      ,p_input              IN     MDSYS.SDO_ORDINATE_ARRAY
   )
   AS
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN;
         
      END IF;

      FOR i IN 1 .. p_input.COUNT
      LOOP
         sdo_append(p_target,p_input(i));
         
      END LOOP;

   END sdo_append;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN NUMBER
   AS
      
   BEGIN
      
      IF p_trunc IS NULL
      THEN
         RETURN p_input;
      END IF;
      
      IF p_input IS NULL
      THEN
         RETURN NULL;
      END IF;
      
      RETURN TRUNC(p_input,p_trunc);
      
   END prune_number;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_varchar2(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2
   AS
   BEGIN
      RETURN TO_CHAR(
         prune_number(
             p_input => p_input
            ,p_trunc => p_trunc
         )
      );
      
   END prune_number_varchar2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_clob(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
      RETURN TO_CLOB(
         prune_number(
             p_input => p_input
            ,p_trunc => p_trunc
         )
      );
      
   END prune_number_clob;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION smart_transform(
       p_input     IN  MDSYS.SDO_GEOMETRY
      ,p_srid      IN  NUMBER
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output     MDSYS.SDO_GEOMETRY;
      
      -- preferred SRIDs
      num_wgs84_pref NUMBER := 4326;
      num_nad83_pref NUMBER := 8265;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN p_input;
         
      END IF;

      IF p_srid IS NULL
      THEN
         RAISE_APPLICATION_ERROR(-20001,'function requires srid in parameter 2');
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Check if SRID values match
      --------------------------------------------------------------------------
      IF p_srid = p_input.SDO_SRID
      THEN
         RETURN p_input;
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Check for equivalents and adjust geometry SRID if required
      --------------------------------------------------------------------------
      IF  p_srid IN (4269,8265)
      AND p_input.SDO_SRID IN (4269,8265)
      THEN
         sdo_output := p_input;
         sdo_output.SDO_SRID := num_nad83_pref;
         RETURN sdo_output;
         
      ELSIF p_srid IN (4326,8307)
      AND   p_input.SDO_SRID IN (4326,8307)
      THEN
         sdo_output := p_input;
         sdo_output.SDO_SRID := num_wgs84_pref;
         RETURN sdo_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Run the transformation then
      --------------------------------------------------------------------------
      IF p_srid = 3785
      THEN
         sdo_output := MDSYS.SDO_CS.TRANSFORM(
             geom     => p_input
            ,use_case => 'USE_SPHERICAL'
            ,to_srid  => p_srid
         );
         
      ELSE
         sdo_output := MDSYS.SDO_CS.TRANSFORM(
             geom     => p_input
            ,to_srid  => p_srid
         );
      
      END IF;
      
      RETURN sdo_output;

   END smart_transform;
   
END dz_wkt_util;
/


--*************************--
PROMPT DZ_WKT_MAIN.pks;

CREATE OR REPLACE PACKAGE dz_wkt_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_WKT
     
   - Build ID: 3
   - TFS Change Set: 8194
   
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


--*************************--
PROMPT DZ_WKT_MAIN.pkb;

CREATE OR REPLACE PACKAGE BODY dz_wkt_main
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_lrs_append(
       p_geometry_1     IN  MDSYS.SDO_GEOMETRY
      ,p_geometry_2     IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      num_dim_1  NUMBER;
      num_dim_2  NUMBER;
      num_lrs_1  NUMBER;
      num_lrs_2  NUMBER;
      sdo_output MDSYS.SDO_GEOMETRY;
      
   BEGIN
   
      IF p_geometry_1 IS NULL
      THEN
         RETURN p_geometry_2;
         
      ELSIF p_geometry_2 IS NULL
      THEN
         RETURN p_geometry_1;
         
      END IF;
      
      num_dim_1  := p_geometry_1.get_dims();
      num_dim_2  := p_geometry_2.get_dims();
      num_lrs_1  := p_geometry_1.get_lrs_dim();
      num_lrs_2  := p_geometry_2.get_lrs_dim();
      
      IF num_dim_1 != num_dim_2
      OR num_lrs_1 != num_lrs_2
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'both inputs must be valid LRS with same dimensionality'
         );
         
      END IF; 
      
      sdo_output := MDSYS.SDO_UTIL.APPEND(
          p_geometry_1
         ,p_geometry_2
      );
      
      sdo_output.SDO_GTYPE := TO_NUMBER(
         TO_CHAR(num_dim_1) || TO_CHAR(num_lrs_1) || '0' || TO_CHAR(sdo_output.get_gtype())
      );
      
      RETURN sdo_output;
      
   END safe_lrs_append;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_tokens
   RETURN tbl_token
   AS
      ary_output tbl_token;
      
   BEGIN

      ary_output(1).t_name   := 'LEFT_PAREN';
      ary_output(1).t_pad    := 0;
      ary_output(1).t_regex  := ' *\(';
      ary_output(1).t_class  := NULL;

      ary_output(2).t_name   := 'RIGHT_PAREN';
      ary_output(2).t_pad    := 0;
      ary_output(2).t_regex  := ' *\)';
      ary_output(2).t_class  := NULL;

      ary_output(3).t_name   := 'VERTEX';
      ary_output(3).t_pad    := 1;
      ary_output(3).t_regex  := '[[:digit:]|\.|-|E-]+( |,|\))';
      ary_output(3).t_class  := NULL;

      ary_output(4).t_name   := 'VERTEX_SEP';
      ary_output(4).t_pad    := 1;
      ary_output(4).t_regex  := ' [[:digit:]|\.|-|E-]{1}';
      ary_output(4).t_class  := NULL;

      ary_output(5).t_name   := 'ORDINATE_SEP';
      ary_output(5).t_pad    := 1;
      ary_output(5).t_regex  := ' *, *[[:digit:]|\.|-|E-]{1}';
      ary_output(5).t_class  := NULL;

      ary_output(6).t_name   := 'LEV2_SEP';
      ary_output(6).t_pad    := 2;
      ary_output(6).t_regex  := ' *,\(\( *[[:digit:]|\.|-|E-]{1}';
      ary_output(6).t_class  := NULL;

      ary_output(7).t_name   := 'LEV1_SEP';
      ary_output(7).t_pad    := 1;
      ary_output(7).t_regex  := ' *,\( *[[:digit:]|\.|-|E-]{1}';
      ary_output(7).t_class  := NULL;

      -- 2D Classes --
      ary_output(8).t_name   := 'POINT';
      ary_output(8).t_pad    := 1;
      ary_output(8).t_regex  := ' *,*POINT *\(';
      ary_output(8).t_class  := 'POINT';

      ary_output(9).t_name   := 'LINESTRING';
      ary_output(9).t_pad    := 1;
      ary_output(9).t_regex  := ' *,*LINESTRING *\(';
      ary_output(9).t_class  := 'LINESTRING';

      ary_output(10).t_name  := 'POLYGON';
      ary_output(10).t_pad   := 1;
      ary_output(10).t_regex := ' *,*POLYGON *\(';
      ary_output(10).t_class := 'POLYGON';

      ary_output(11).t_name  := 'MULTIPOINT';
      ary_output(11).t_pad   := 1;
      ary_output(11).t_regex := ' *MULTIPOINT *\(';
      ary_output(11).t_class := 'POINT';

      ary_output(12).t_name   := 'MULTILINESTRING';
      ary_output(12).t_pad    := 1;
      ary_output(12).t_regex  := ' *,*MULTILINESTRING *\(';
      ary_output(12).t_class  := 'LINESTRING';

      ary_output(13).t_name  := 'MULTIPOLYGON';
      ary_output(13).t_pad   := 1;
      ary_output(13).t_regex := ' *MULTIPOLYGON *\(';
      ary_output(13).t_class := 'POLYGON';

      ary_output(14).t_name  := 'GEOMETRYCOLLECTION';
      ary_output(14).t_pad   := 1;
      ary_output(14).t_regex := ' *GEOMETRYCOLLECTION *\(';
      ary_output(14).t_class := 'MULTI';
      
      -- 2DM Classes --      
      ary_output(15).t_name   := 'POINT M';
      ary_output(15).t_pad    := 1;
      ary_output(15).t_regex  := ' *,*POINT *M *\(';
      ary_output(15).t_class  := 'POINT';

      ary_output(16).t_name   := 'LINESTRING M';
      ary_output(16).t_pad    := 1;
      ary_output(16).t_regex  := ' *,*LINESTRING *M *\(';
      ary_output(16).t_class  := 'LINESTRING';
      
      ary_output(17).t_name  := 'POLYGON M';
      ary_output(17).t_pad   := 1;
      ary_output(17).t_regex := ' *,*POLYGON *M *\(';
      ary_output(17).t_class := 'POLYGON';
      
      ary_output(18).t_name   := 'MULTIPOINT M';
      ary_output(18).t_pad    := 1;
      ary_output(18).t_regex  := ' *,*MULTIPOINT *M *\(';
      ary_output(18).t_class  := 'POINT';
      
      ary_output(19).t_name   := 'MULTILINESTRING M';
      ary_output(19).t_pad    := 1;
      ary_output(19).t_regex  := ' *,*MULTILINESTRING *M *\(';
      ary_output(19).t_class  := 'LINESTRING';
      
      ary_output(20).t_name  := 'MULTIPOLYGON M';
      ary_output(20).t_pad   := 1;
      ary_output(20).t_regex := ' *MULTIPOLYGON *M *\(';
      ary_output(20).t_class := 'POLYGON';

      ary_output(21).t_name  := 'GEOMETRYCOLLECTION M';
      ary_output(21).t_pad   := 1;
      ary_output(21).t_regex := ' *GEOMETRYCOLLECTION *M *\(';
      ary_output(21).t_class := 'MULTI';
      
      -- 3D Classes --      
      ary_output(22).t_name   := 'POINT Z';
      ary_output(22).t_pad    := 1;
      ary_output(22).t_regex  := ' *,*POINT *Z *\(';
      ary_output(22).t_class  := 'POINT';

      ary_output(23).t_name   := 'LINESTRING Z';
      ary_output(23).t_pad    := 1;
      ary_output(23).t_regex  := ' *,*LINESTRING *Z *\(';
      ary_output(23).t_class  := 'LINESTRING';
      
      ary_output(24).t_name  := 'POLYGON Z';
      ary_output(24).t_pad   := 1;
      ary_output(24).t_regex := ' *,*POLYGON *Z *\(';
      ary_output(24).t_class := 'POLYGON';
      
      ary_output(25).t_name   := 'MULTIPOINT Z';
      ary_output(25).t_pad    := 1;
      ary_output(25).t_regex  := ' *,*MULTIPOINT *Z *\(';
      ary_output(25).t_class  := 'POINT';
      
      ary_output(26).t_name   := 'MULTILINESTRING Z';
      ary_output(26).t_pad    := 1;
      ary_output(26).t_regex  := ' *,*MULTILINESTRING *Z *\(';
      ary_output(26).t_class  := 'LINESTRING';
      
      ary_output(27).t_name  := 'MULTIPOLYGON Z';
      ary_output(27).t_pad   := 1;
      ary_output(27).t_regex := ' *MULTIPOLYGON *Z *\(';
      ary_output(27).t_class := 'POLYGON';

      ary_output(28).t_name  := 'GEOMETRYCOLLECTION Z';
      ary_output(28).t_pad   := 1;
      ary_output(28).t_regex := ' *GEOMETRYCOLLECTION *Z *\(';
      ary_output(28).t_class := 'MULTI';
      
      -- 3DM Classes --      
      ary_output(29).t_name   := 'POINT ZM';
      ary_output(29).t_pad    := 1;
      ary_output(29).t_regex  := ' *,*POINT *Z *M *\(';
      ary_output(29).t_class  := 'POINT';

      ary_output(30).t_name   := 'LINESTRING Z';
      ary_output(30).t_pad    := 1;
      ary_output(30).t_regex  := ' *,*LINESTRING *Z *M *\(';
      ary_output(30).t_class  := 'LINESTRING';
      
      ary_output(31).t_name  := 'POLYGON ZM';
      ary_output(31).t_pad   := 1;
      ary_output(31).t_regex := ' *,*POLYGON *Z *M *\(';
      ary_output(31).t_class := 'POLYGON';
      
      ary_output(32).t_name   := 'MULTIPOINT ZM';
      ary_output(32).t_pad    := 1;
      ary_output(32).t_regex  := ' *,*MULTIPOINT *Z *M *\(';
      ary_output(32).t_class  := 'POINT';
      
      ary_output(33).t_name   := 'MULTILINESTRING ZM';
      ary_output(33).t_pad    := 1;
      ary_output(33).t_regex  := ' *,*MULTILINESTRING *Z *M *\(';
      ary_output(33).t_class  := 'LINESTRING';
      
      ary_output(34).t_name  := 'MULTIPOLYGON ZM';
      ary_output(34).t_pad   := 1;
      ary_output(34).t_regex := ' *MULTIPOLYGON *Z *M *\(';
      ary_output(34).t_class := 'POLYGON';

      ary_output(35).t_name  := 'GEOMETRYCOLLECTION ZM';
      ary_output(35).t_pad   := 1;
      ary_output(35).t_regex := ' *GEOMETRYCOLLECTION *Z *M *\(';
      ary_output(35).t_class := 'MULTI';
      
      ary_output(36).t_name  := 'SRID';
      ary_output(36).t_pad   := 0;
      ary_output(36).t_regex := ' *SRID *\= *[[:digit:]][[:digit:]]* *\; *';
      ary_output(36).t_class := 'SRID';
      
      ary_output(37).t_name  := 'EMPTY';
      ary_output(37).t_pad   := 0;
      ary_output(37).t_regex := '(POINT|LINESTRING|POLYGON|MULTIPOINT|MULTILINESTRING|MULTIPOLYGON|GEOMETRYCOLLECTION) *Z*M* *EMPTY';
      ary_output(37).t_class := 'EMPTY';
      
      RETURN ary_output;

   END get_tokens;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE create_elem_info(
       p_type           IN  VARCHAR2
      ,p_output         OUT MDSYS.SDO_ELEM_INFO_ARRAY
      ,p_return_code    OUT NUMBER
      ,p_status_message OUT VARCHAR2
   )
   AS
   BEGIN
      
      p_output := MDSYS.SDO_ELEM_INFO_ARRAY();
      p_output.EXTEND(3);
      
      IF p_type IN ('POINT','POINT M','POINT Z','POINT ZM')
      THEN
         p_output(1) := 1;
         p_output(2) := 1;
         p_output(3) := 1;
         
      ELSIF p_type IN ('LINESTRING','LINESTRING M','LINESTRING Z','LINESTRING ZM')
      THEN
         p_output(1) := 1;
         p_output(2) := 2;
         p_output(3) := 1;
         
      ELSIF p_type IN ('POLYGON','POLYGON M','POLYGON Z','POLYGON ZM')
      THEN
         p_output(1) := 1;
         p_output(2) := 1003;
         p_output(3) := 1;
         
      ELSE
         p_return_code := -15;
         p_status_message := 'invalid wkt: no code for ' || p_type;
         RETURN;
         
      END IF;

      p_return_code := 0;

   END create_elem_info;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION create_elem_info(
      p_type      IN VARCHAR2
   ) RETURN MDSYS.SDO_ELEM_INFO_ARRAY
   AS
      elem_output        MDSYS.SDO_ELEM_INFO_ARRAY;
      num_return_code    NUMBER;
      str_status_message VARCHAR2(255 Char);
      
   BEGIN
      
      create_elem_info(
          p_type           => p_type
         ,p_output         => elem_output
         ,p_return_code    => num_return_code
         ,p_status_message => str_status_message
      );
      
      IF num_return_code <> 0
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,str_status_message
         );
         
      END IF;

      RETURN elem_output;

   END create_elem_info;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION add_polygon_void(
       p_offset    IN NUMBER
      ,p_elem_info IN MDSYS.SDO_ELEM_INFO_ARRAY
   ) RETURN MDSYS.SDO_ELEM_INFO_ARRAY
   AS
      elem_output MDSYS.SDO_ELEM_INFO_ARRAY := MDSYS.SDO_ELEM_INFO_ARRAY();
      num_index   PLS_INTEGER;
      
   BEGIN

      num_index   := p_elem_info.COUNT + 1;
      elem_output := p_elem_info;
      elem_output.EXTEND(3);
      elem_output(num_index)     := p_offset + 1;
      elem_output(num_index + 1) := 2003;
      elem_output(num_index + 2) := 1;

      RETURN elem_output;

   END add_polygon_void;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION append_ordinates(
       p_input_1   IN MDSYS.SDO_ORDINATE_ARRAY
      ,p_input_2   IN MDSYS.SDO_ORDINATE_ARRAY
   ) RETURN MDSYS.SDO_ORDINATE_ARRAY
   AS
      sdo_output MDSYS.SDO_ORDINATE_ARRAY;
      num_index  PLS_INTEGER;
      
   BEGIN

      sdo_output := p_input_1;
      num_index  := p_input_1.COUNT + 1;

      sdo_output.EXTEND(p_input_2.COUNT);

      FOR i IN 1 .. p_input_2.COUNT
      LOOP
         sdo_output(num_index) := p_input_2(i);
         num_index := num_index + 1;
         
      END LOOP;

      RETURN sdo_output;

   END append_ordinates;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION tighten_wkt(
      p_input IN CLOB
   ) RETURN CLOB
   AS
      clb_output CLOB := UPPER(p_input);
      
   BEGIN

      clb_output := REGEXP_REPLACE(
          clb_output
         ,' *\) *\)|\) *\)|','))'
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,' *\( *\(|\( *\(','(('
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,' *, *\(|, *\(',',('
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,' *\) *,|\) *,','),'
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,' *\( *|\( *| *\(','('
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,' *\) *|\) *| *\)',')'
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,', *([[:alpha:]]{1})',',\1'
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,'([[:alpha:]]{1}) *\(','\1('
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,'\( +([[:digit:]|\.|-]{1})','(\1'
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,'([[:digit:]|\.|-]{1}) +\)','\1)'
      );
      clb_output := REGEXP_REPLACE(
          clb_output
         ,'( ){2,}',' '
      );
      
      --dbms_output.put_line(TO_CHAR(SUBSTR(clb_output,1,2000)));
      RETURN clb_output;

   END;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE wkt_diagnostic(
       p_input          IN  CLOB
      ,p_input_code     IN  NUMBER DEFAULT NULL
      ,p_input_message  IN  VARCHAR2 DEFAULT NULL
      ,p_return_code    OUT NUMBER
      ,p_status_message OUT VARCHAR2
   )
   AS
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters and pass through values
      --------------------------------------------------------------------------
      p_return_code    := p_input_code;
      p_status_message := p_input_message;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Search for input using commas rather than periods
      --------------------------------------------------------------------------
      IF p_input_code = -11
      THEN
         IF REGEXP_INSTR(
             p_input
            ,'\( *[[:digit:]]* *, *[[:digit:]]* +[[:digit:]]* *, *[[:digit:]]*\)'
         ) > 0
         THEN
            p_status_message := p_status_message ||
            ', check that your numeric input uses periods and not commas as decimal separator.';
         
         END IF;
      
      END IF;
      
      
      
   END wkt_diagnostic;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE wkt2sdo(
       p_input            IN  CLOB
      ,p_srid             IN  NUMBER   DEFAULT NULL
      ,p_num_dims         IN  NUMBER   DEFAULT NULL
      ,p_axes_latlong     IN  VARCHAR2 DEFAULT NULL
      ,p_output           OUT MDSYS.SDO_GEOMETRY
      ,p_return_code      OUT NUMBER
      ,p_status_message   OUT VARCHAR
   )
   AS
      str_axes_latlong VARCHAR2(4000 Char) := UPPER(p_axes_latlong);
      num_dims         NUMBER := p_num_dims;
      num_srid         NUMBER := p_srid;
      ary_output       tbl_token;
      ary_words        tbl_parsed;
      ary_geowords     tbl_parsed;
      ary_partswords   tbl_parsed;
      clb_input        CLOB;
      str_current      VARCHAR2(32000 Char);
      int_pos          PLS_INTEGER;
      int_index        PLS_INTEGER;
      int_start        PLS_INTEGER;
      int_length       PLS_INTEGER;
      int_stop         PLS_INTEGER;
      int_end          PLS_INTEGER;
      int_inner        PLS_INTEGER;
      boo_check        BOOLEAN;
      num_vertex       NUMBER;
      int_dims         PLS_INTEGER;
      int_dimchk       PLS_INTEGER;
      str_type         VARCHAR2(32 Char);
      str_multi        VARCHAR2(32 Char);
      int_dcounter     SIMPLE_INTEGER := 1;

   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF num_dims IS NULL
      THEN
          num_dims := 2;
          
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Parse the WKT into tokens
      --------------------------------------------------------------------------
      clb_input   := tighten_wkt(p_input);
      ary_output  := get_tokens();
      str_current := '';
      int_pos     := 1;
      int_index   := 1;
      int_start   := 1;
      int_length  := 0;

      --------------------------------------------------------------------------
      -- Step 30
      -- Loop through the WKT
      --------------------------------------------------------------------------
      WHILE int_pos <= LENGTH(clb_input)
      LOOP
         int_inner   := 1;
         boo_check   := FALSE;
         str_current := str_current || SUBSTR(clb_input,int_pos,1);

         WHILE int_inner <= ary_output.COUNT
         LOOP
            IF REGEXP_INSTR(str_current,ary_output(int_inner).t_regex,1,1,0) = 1
            THEN
               int_end    := REGEXP_INSTR(str_current,ary_output(int_inner).t_regex,1,1,1);
               int_length := (int_end - 1) - ary_output(int_inner).t_pad;
               int_stop   := int_start + int_length - 1;

               ary_words(int_index).token       := ary_output(int_inner).t_name;
               ary_words(int_index).t_class     := ary_output(int_inner).t_class;
               ary_words(int_index).start_pos   := int_start;
               ary_words(int_index).length_item := int_length;
               int_index := int_index + 1;

               str_current := '';
               int_pos   := int_stop;
               int_start := int_stop + 1;
               --dbms_output.put_line(int_start || ' ' || int_end || ' ' || int_length);
               int_inner := ary_output.COUNT;
               boo_check := TRUE;

            END IF;
            
            int_inner := int_inner + 1;
            
         END LOOP;

         int_pos := int_pos + 1;

      END LOOP;

      IF boo_check = FALSE
      THEN
        p_return_code    := -10;
        p_status_message := 'invalid wkt: unable to parse ' || str_current;
        RETURN;
        
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Collapse ( + ordinates + ) sets into single ORDINATE token
      --------------------------------------------------------------------------
      int_dimchk := NULL;
      int_dims   := 0;
      int_index  := 1;
      boo_check  := FALSE;
      str_multi  := ary_words(1).token;
      
      FOR i IN 1 .. ary_words.COUNT
      LOOP
         --dbms_output.put_line(ary_words(i).token);
         IF  ary_words(i).token = 'SRID'
         AND i = 1
         THEN
            IF num_srid IS NULL
            THEN
               num_srid := TO_NUMBER(REGEXP_SUBSTR(
                   SUBSTR(clb_input,ary_words(i).start_pos,ary_words(i).length_item)
                  ,'([[:digit:]]+)'
               ));
               
               IF num_srid = 0
               THEN
                  num_srid := NULL;
                  
               END IF;
               
            END IF;
         
         ELSIF  ary_words(i).token = 'EMPTY'
         AND i IN (2,3)
         THEN
            p_return_code := 0;
            p_output      := NULL;
            RETURN;
            
         ELSIF ary_words(i).token = 'VERTEX'
         THEN
            IF boo_check = FALSE
            THEN
               int_dcounter := 1;
               int_pos  := 1;
               ary_geowords(int_index).token := 'ORDINATES';
               ary_geowords(int_index).shape := MDSYS.SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL);
               ary_geowords(int_index).shape.SDO_ORDINATES := MDSYS.SDO_ORDINATE_ARRAY();
               boo_check := TRUE;
               
            END IF;
            
            BEGIN
               num_vertex := TO_NUMBER(
                  SUBSTR(
                      clb_input
                     ,ary_words(i).start_pos
                     ,ary_words(i).length_item
                  )
               );
               
            EXCEPTION
               WHEN VALUE_ERROR
               THEN
                  p_return_code    := -14;
                  p_status_message := 'invalid wkt: unable to parse ' || SUBSTR(
                      clb_input
                     ,ary_words(i).start_pos
                     ,ary_words(i).length_item
                  ) || ' as numeric ordinate';
                  RETURN;
                  
               WHEN OTHERS
               THEN
                  RAISE;
                  
            END;
            
            ary_geowords(int_index).shape.SDO_ORDINATES.EXTEND(1);
            
            IF str_axes_latlong = 'TRUE'
            AND int_dcounter = 2
            THEN
               ary_geowords(int_index).shape.SDO_ORDINATES(int_pos) := ary_geowords(int_index).shape.SDO_ORDINATES(int_pos - 1);
               ary_geowords(int_index).shape.SDO_ORDINATES(int_pos - 1) := num_vertex;
               
            ELSE
               ary_geowords(int_index).shape.SDO_ORDINATES(int_pos) := num_vertex;
               
            END IF;
            
            int_pos := int_pos + 1;
            int_dcounter := int_dcounter + 1;
            int_dims := int_dims + 1;
            
            IF int_dcounter > num_dims
            THEN
               int_dcounter := 1;
               
            END IF;

         ELSIF ary_words(i).token = 'VERTEX_SEP'
         THEN
            NULL;

         ELSIF ary_words(i).token = 'ORDINATE_SEP'
         THEN
            IF boo_check = TRUE
            THEN
               IF int_dimchk IS NULL
               THEN
                  int_dimchk := int_dims;
                  
               ELSE
                  IF int_dimchk != int_dims
                  THEN
                     p_return_code    := -11;
                     p_status_message := 'invalid wkt: vertex counts are not consistant';
                     
                     wkt_diagnostic(
                         p_input          => p_input
                        ,p_input_code     => p_return_code
                        ,p_input_message  => p_status_message
                        ,p_return_code    => p_return_code
                        ,p_status_message => p_status_message
                     );
                     
                     RETURN;
                     
                  END IF;
                  
                  IF int_dimchk > 4
                  THEN
                     p_return_code    := -12;
                     p_status_message := 'invalid wkt: more than four dimensions found';
                     RETURN;
                     
                  END IF;
                  
               END IF;
               
               int_dims := 0;
               
            END IF;

            IF str_multi IN ('MULTIPOINT','MULTIPOINT Z','MULTIPOINT M','MULTIPOINT ZM')
            THEN
               -- Need to insert a part break here
               IF int_dimchk IS NULL
               THEN
                  int_dimchk := int_dims;
                  
               END IF;
               
               int_dims := 0;
               boo_check := FALSE;
               ary_geowords(int_index).num_dims := int_dimchk;
               int_index := int_index + 1;

            END IF;

         ELSIF ary_words(i).token = 'RIGHT_PAREN'
         THEN

            IF boo_check = TRUE
            THEN
               IF int_dimchk IS NULL
               THEN
                  int_dimchk := int_dims;
                  
               ELSE
                  IF int_dimchk != int_dims
                  THEN
                     p_return_code    := -11;
                     p_status_message := 'invalid wkt: vertex counts are not consistant';
                     
                     wkt_diagnostic(
                         p_input          => p_input
                        ,p_input_code     => p_return_code
                        ,p_input_message  => p_status_message
                        ,p_return_code    => p_return_code
                        ,p_status_message => p_status_message
                     );
                     
                     RETURN;
                     
                  END IF;
                  
                  IF int_dimchk > 4
                  THEN
                     p_return_code    := -12;
                     p_status_message := 'invalid wkt: more than four dimensions found';
                     RETURN;
                     
                  END IF;
                  
               END IF;

               int_dims := 0;
               boo_check := FALSE;
               ary_geowords(int_index).num_dims := int_dimchk;
               int_index := int_index + 1;

            END IF;

            ary_geowords(int_index) := ary_words(i);
            int_index := int_index + 1;

         ELSE
            ary_geowords(int_index) := ary_words(i);
            int_index := int_index + 1;
            
         END IF;

      END LOOP;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Add check for garbled wkt that appears less than 2 dimensions
      --------------------------------------------------------------------------
      IF int_dimchk < 2
      THEN
         p_return_code    := -18;
         p_status_message := 'invalid wkt: unable to parse ' || SUBSTR(p_input,1,220);
         RETURN;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 60
      -- Deal with inner polygon rings and multicollections
      -- Inner rings collapse into outer object and multis are separated out
      --------------------------------------------------------------------------
      int_index := 1;
      boo_check := FALSE;
      str_multi := ary_geowords(1).token;
      FOR i IN 1 .. ary_geowords.COUNT
      LOOP
         IF ary_geowords(i).t_class IS NOT NULL
         THEN
            str_type := ary_geowords(i).token;
            
         END IF;

         -- Start looking for ordinate groups to collaspe
         IF  ary_geowords(i).token = 'ORDINATES'
         AND boo_check = FALSE
         THEN
            IF str_multi = 'MULTIPOINT'
            THEN
               ary_partswords(int_index).token := 'POINT';
               int_index := int_index + 1;
               
            ELSIF str_multi = 'MULTILINESTRING'
            THEN
               ary_partswords(int_index).token := 'LINESTRING';
               int_index := int_index + 1;
            
            ELSIF str_multi = 'MULTIPOLYGON'
            THEN
               ary_partswords(int_index).token := 'POLYGON';
               int_index := int_index + 1;
               
            ELSIF str_multi = 'MULTIPOINT M'
            THEN
               ary_partswords(int_index).token := 'POINT M';
               int_index := int_index + 1;
               
            ELSIF str_multi = 'MULTILINESTRING M'
            THEN
               ary_partswords(int_index).token := 'LINESTRING M';
               int_index := int_index + 1;
                  
            ELSIF str_multi = 'MULTIPOLYGON M'
            THEN
               ary_partswords(int_index).token := 'POLYGON M';
               int_index := int_index + 1;
               
            ELSIF str_multi = 'MULTIPOINT Z'
            THEN
               ary_partswords(int_index).token := 'POINT Z';
               int_index := int_index + 1;
               
            ELSIF str_multi = 'MULTILINESTRING Z'
            THEN
               ary_partswords(int_index).token := 'LINESTRING Z';
               int_index := int_index + 1;
                  
            ELSIF str_multi = 'MULTIPOLYGON Z'
            THEN
               ary_partswords(int_index).token := 'POLYGON Z';
               int_index := int_index + 1;
               
            ELSIF str_multi = 'MULTIPOINT ZM'
            THEN
               ary_partswords(int_index).token := 'POINT ZM';
               int_index := int_index + 1;
               
            ELSIF str_multi = 'MULTILINESTRING ZM'
            THEN
               ary_partswords(int_index).token := 'LINESTRING ZM';
               int_index := int_index + 1;
                  
            ELSIF str_multi = 'MULTIPOLYGON ZM'
            THEN
               ary_partswords(int_index).token := 'POLYGON ZM';
               int_index := int_index + 1;
               
            END IF;

            -- This is an ordinate starting the geometry
            -- Build the sdo_elem_info and move on
            ary_partswords(int_index) := ary_geowords(i);
            ary_partswords(int_index).shape.SDO_SRID  := num_srid;

            IF str_type IN ('POINT','MULTIPOINT')
            THEN
               create_elem_info(
                   p_type           => 'POINT'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := TO_NUMBER(TO_CHAR(ary_partswords(int_index).num_dims) || '001');
             
            ELSIF str_type IN ('POINT Z','MULTIPOINT Z')
            THEN
               create_elem_info(
                   p_type           => 'POINT Z'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3001;
              
            ELSIF str_type IN ('POINT M','MULTIPOINT M')
            THEN
               create_elem_info(
                   p_type           => 'POINT M'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3301;
               
            ELSIF str_type IN ('POINT ZM','MULTIPOINT ZM')
            THEN
               create_elem_info(
                   p_type           => 'POINT ZM'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 4401;
            
            ELSIF str_type IN ('LINESTRING','MULTILINESTRING')
            THEN
               create_elem_info(
                   p_type           => 'LINESTRING'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := TO_NUMBER(TO_CHAR(ary_partswords(int_index).num_dims) || '002');
            
            ELSIF str_type IN ('LINESTRING Z','MULTILINESTRING Z')
            THEN
               create_elem_info(
                   p_type           => 'LINESTRING'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3002;
            
            ELSIF str_type IN ('LINESTRING M','MULTILINESTRING M')
            THEN
               create_elem_info(
                   p_type           => 'LINESTRING M'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3302;
            
            ELSIF str_type IN ('LINESTRING ZM','MULTILINESTRING ZM')
            THEN
               create_elem_info(
                   p_type           => 'LINESTRING ZM'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 4402;
               
            ELSIF str_type IN ('POLYGON','MULTIPOLYGON')
            THEN
               create_elem_info(
                   p_type           => 'POLYGON'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := TO_NUMBER(TO_CHAR(ary_partswords(int_index).num_dims) || '003');
               
               dz_wkt_util.verify_ordinate_rotation(
                   p_rotation => 'CCW'
                  ,p_input    => ary_partswords(int_index).shape
               );
            
            ELSIF str_type IN ('POLYGON Z','MULTIPOLYGON Z')
            THEN
               create_elem_info(
                   p_type           => 'POLYGON'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3003;
               
               dz_wkt_util.verify_ordinate_rotation(
                   p_rotation => 'CCW'
                  ,p_input    => ary_partswords(int_index).shape
               );
                  
            ELSIF str_type IN ('POLYGON M','MULTIPOLYGON M')
            THEN
               create_elem_info(
                   p_type           => 'POLYGON'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3303;
               
               dz_wkt_util.verify_ordinate_rotation(
                   p_rotation => 'CCW'
                  ,p_input    => ary_partswords(int_index).shape
               );
               
            ELSIF str_type IN ('POLYGON ZM','MULTIPOLYGON ZM')
            THEN
               create_elem_info(
                   p_type           => 'POLYGON'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 4403;
               
               dz_wkt_util.verify_ordinate_rotation(
                   p_rotation => 'CCW'
                  ,p_input    => ary_partswords(int_index).shape
               );
            
            ELSIF str_type IS NULL
            THEN
               p_return_code    := -13;
               p_status_message := 'invalid wkt: geometry type token required (e.g. POINT, POLYGON, etc)';
               RETURN;
               
            ELSE
               p_return_code    := -13;
               p_status_message := 'invalid wkt: unknown token type ' || str_type;
               RETURN;
               
            END IF;

            int_index := int_index + 1;

         ELSIF  ary_geowords(i).token = 'ORDINATES'
         AND boo_check = TRUE
         THEN

            IF str_type IN (
                'POLYGON','MULTIPOLYGON'
               ,'POLYGON Z','MULTIPOLYGON Z'
               ,'POLYGON M','MULTIPOLYGON M'
               ,'POLYGON ZM','MULTIPOLYGON ZM'
            )
            THEN
               -- make sure rotation is correct
               dz_wkt_util.verify_ordinate_rotation(
                   p_rotation => 'CW'
                  ,p_input    => ary_geowords(i).shape
               );

               -- We got some holes
               ary_partswords(int_index - 2).shape.SDO_ELEM_INFO := add_polygon_void(
                   ary_partswords(int_index - 2).shape.SDO_ORDINATES.COUNT
                  ,ary_partswords(int_index - 2).shape.SDO_ELEM_INFO 
               );

               ary_partswords(int_index - 2).shape.SDO_ORDINATES := append_ordinates(
                   ary_partswords(int_index - 2).shape.SDO_ORDINATES
                  ,ary_geowords(i).shape.SDO_ORDINATES
               );

               --back up and roll over separator and ordinates
               int_index := int_index - 1;
            
            ELSIF str_type IN ('MULTILINESTRING')
            THEN
               ary_partswords(int_index) := ary_geowords(i);
               ary_partswords(int_index).shape.SDO_SRID  := num_srid;
               
               create_elem_info(
                   p_type           => 'LINESTRING'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 2002;
            
            ELSIF str_type IN ('MULTILINESTRING M')
            THEN
               ary_partswords(int_index) := ary_geowords(i);
               ary_partswords(int_index).shape.SDO_SRID  := num_srid;
               
               create_elem_info(
                   p_type           => 'LINESTRING M'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3302;
            
            ELSIF str_type IN ('MULTILINESTRING Z')
            THEN
               ary_partswords(int_index) := ary_geowords(i);
               ary_partswords(int_index).shape.SDO_SRID  := num_srid;
               
               create_elem_info(
                   p_type           => 'LINESTRING Z'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3002;
              
            ELSIF str_type IN ('MULTILINESTRING ZM')
            THEN
               ary_partswords(int_index) := ary_geowords(i);
               ary_partswords(int_index).shape.SDO_SRID  := num_srid;
               
               create_elem_info(
                   p_type           => 'LINESTRING ZM'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 4402;
                
            ELSIF str_type IN ('MULTIPOINT')
            THEN
               ary_partswords(int_index) := ary_geowords(i);
               ary_partswords(int_index).shape.SDO_SRID  := num_srid;
               
               create_elem_info(
                   p_type           => 'POINT'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 2001;
            
            ELSIF str_type IN ('MULTIPOINT M')
            THEN
               ary_partswords(int_index) := ary_geowords(i);
               ary_partswords(int_index).shape.SDO_SRID  := num_srid;
               
               create_elem_info(
                   p_type           => 'POINT M'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3301;
              
            ELSIF str_type IN ('MULTIPOINT Z')
            THEN
               ary_partswords(int_index) := ary_geowords(i);
               ary_partswords(int_index).shape.SDO_SRID  := num_srid;
               
               create_elem_info(
                   p_type           => 'POINT Z'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 3001;
              
            ELSIF str_type IN ('MULTIPOINT ZM')
            THEN
               ary_partswords(int_index) := ary_geowords(i);
               ary_partswords(int_index).shape.SDO_SRID  := num_srid;
               
               create_elem_info(
                   p_type           => 'POINT ZM'
                  ,p_output         => ary_partswords(int_index).shape.SDO_ELEM_INFO
                  ,p_return_code    => p_return_code
                  ,p_status_message => p_status_message
               );
               IF p_return_code <> 0
               THEN
                  RETURN;
               
               END IF;
               
               ary_partswords(int_index).shape.SDO_GTYPE := 4401;
                 
            ELSE
               p_return_code    := -13;
               p_status_message := 'invalid wkt: unknown token type (' || str_type || ')';
               RETURN;
               
            END IF;

         ELSIF ary_geowords(i).token = 'LEV1_SEP'
         THEN
            boo_check := TRUE;

            -- Check that parent ordinate exists
            IF ary_partswords(int_index - 1).token != 'ORDINATES'
            THEN
               p_return_code    := -14;
               p_status_message := 'invalid wkt: no parent ORDINATES token found for child';
               RETURN;
               
            END IF;

            ary_partswords(int_index) := ary_geowords(i);
            int_index := int_index + 1;

         ELSIF ary_geowords(i).token = 'LEV2_SEP'
         THEN
            -- Nothing special for lev2_sep as they must be multipolygons
            ary_partswords(int_index) := ary_geowords(i);
            int_index := int_index + 1;

         ELSIF ary_geowords(i).token = 'LEFT_PAREN'
         THEN
            boo_check := FALSE;
            
         ELSIF ary_geowords(i).token = 'RIGHT_PAREN'
         THEN
            -- New object and remove this parenthesis token clutter
            boo_check := FALSE;
            
         ELSE
            ary_partswords(int_index) := ary_geowords(i);
            int_index := int_index + 1;
            
         END IF;

      END LOOP;

      --------------------------------------------------------------------------
      -- Step 70
      -- Final spin through to check the grammer
      --------------------------------------------------------------------------
      int_index := 1;
      p_output  := NULL;
      str_type  := NULL;
      str_multi := ary_words(1).token;
      
      WHILE int_index <= ary_partswords.COUNT
      LOOP
         IF ary_partswords(int_index).t_class IS NOT NULL
         THEN
            str_type  := ary_partswords(int_index).token;
            boo_check := TRUE;
            
         END IF;

         IF ary_partswords(int_index).token = 'ORDINATES'
         THEN
            IF str_type IN ('POINT','POINT Z')
            AND ary_partswords(int_index).num_dims < 4
            THEN
               ary_partswords(int_index).shape := dz_wkt_util.true_point(
                  p_input => ary_partswords(int_index).shape
               );
               
            END IF;

            IF p_output IS NULL
            THEN
               p_output := ary_partswords(int_index).shape;
               
            ELSE
               p_output := safe_lrs_append(
                   p_geometry_1 => p_output
                  ,p_geometry_2 => ary_partswords(int_index).shape
               );
               
            END IF;

         END IF;

         int_index := int_index + 1;

      END LOOP;
      
      p_return_code    := 0;
      p_status_message := NULL;
      RETURN;
   
   END wkt2sdo;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION wkt2sdo(
       p_input            IN  CLOB
      ,p_srid             IN  NUMBER   DEFAULT NULL
      ,p_num_dims         IN  NUMBER   DEFAULT NULL
      ,p_axes_latlong     IN  VARCHAR2 DEFAULT NULL
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output         MDSYS.SDO_GEOMETRY;
      num_return_code    NUMBER;
      str_status_message VARCHAR2(255 Char);

   BEGIN
   
      wkt2sdo(
          p_input           => p_input
         ,p_srid            => p_srid
         ,p_num_dims        => p_num_dims
         ,p_axes_latlong    => p_axes_latlong
         ,p_output          => sdo_output
         ,p_return_code     => num_return_code
         ,p_status_message  => str_status_message
      );
      
      IF num_return_code <> 0
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,str_status_message
         );
         
      END IF;

      RETURN sdo_output;

   END wkt2sdo;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION point2wkt(
       p_input            IN  MDSYS.SDO_POINT_TYPE
      ,p_head             IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_paren            IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_dims             IN  NUMBER   DEFAULT 2
      ,p_lrs_dim          IN  NUMBER   DEFAULT 0
   ) RETURN VARCHAR2
   AS
      str_output VARCHAR2(4000 Char) := '';
      
   BEGIN

      IF p_head IS NULL
      OR p_head = 'TRUE'
      THEN
         str_output := 'POINT ';
         
         IF  p_input.z IS NOT NULL
         AND p_2d_flag = 'FALSE'
         AND p_dims > 2
         AND p_lrs_dim = 0
         THEN
            str_output := str_output || 'Z';
            
         ELSIF p_input.z IS NOT NULL
         AND p_2d_flag = 'FALSE'
         AND p_lrs_dim <> 0
         THEN
            str_output := str_output || 'M';
            
         END IF;
         
      ELSIF p_head = 'FALSE'
      THEN
         NULL;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_head parameter must be TRUE or FALSE'
         );
         
      END IF;

      str_output := str_output || '( ' || dz_wkt_util.prune_number_varchar2(
         p_input => p_input.x,
         p_trunc => p_prune_number
      ) || ' ' || dz_wkt_util.prune_number_varchar2(
         p_input => p_input.y,
         p_trunc => p_prune_number
      );

      IF  p_input.z IS NOT NULL
      AND p_2d_flag = 'FALSE'
      THEN
         str_output := str_output || ' ' || dz_wkt_util.prune_number_varchar2(
            p_input => p_input.z,
            p_trunc => p_prune_number
         );
      END IF;

      str_output := str_output || ')';
      
      RETURN str_output;

   END point2wkt;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION point2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_head             IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_paren            IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN VARCHAR2
   AS
      int_dims   PLS_INTEGER;
      int_gtyp   PLS_INTEGER;
      int_lrs    PLS_INTEGER;
      str_output VARCHAR2(4000 Char) := '';
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();

      IF int_gtyp <> 1
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be point'
         );
         
      END IF;

      IF p_input.SDO_POINT IS NOT NULL
      THEN
         RETURN point2wkt(
             p_input        => p_input.SDO_POINT
            ,p_head         => 'TRUE'
            ,p_paren        => 'TRUE'
            ,p_prune_number => p_prune_number
            ,p_2d_flag      => p_2d_flag
            ,p_dims         => int_dims
            ,p_lrs_dim      => int_lrs
         );
         
      END IF;

      IF p_head = 'TRUE'
      THEN
         str_output := 'POINT';
         
         IF  int_dims = 3
         AND p_2d_flag = 'FALSE'
         AND int_lrs = 0
         THEN
            str_output := str_output || ' Z';
            
         ELSIF  int_dims = 3
         AND p_2d_flag = 'FALSE'
         AND int_lrs <> 0
         THEN
            str_output := str_output || ' M';
            
         ELSIF  int_dims = 4
         AND p_2d_flag = 'FALSE'
         AND int_lrs <> 0
         THEN
            str_output := str_output || ' ZM';
            
         ELSIF  int_dims = 4
         AND p_2d_flag = 'FALSE'
         AND int_lrs = 0
         THEN
            str_output := str_output || ' Z';
            
         END IF;

      ELSIF p_head = 'FALSE'
      THEN
         NULL;

      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_head parameter must be TRUE or FALSE'
         );
         
      END IF;

      IF p_paren = 'TRUE'
      THEN
         str_output := str_output || '(';
         
      ELSIF p_paren = 'FALSE'
      THEN
         NULL;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_paren parameter must be TRUE or FALSE'
         );
         
      END IF;

      str_output := str_output || dz_wkt_util.prune_number_varchar2(
          p_input => p_input.SDO_ORDINATES(1)
         ,p_trunc => p_prune_number
      ) || ' ' || dz_wkt_util.prune_number_varchar2(
          p_input => p_input.SDO_ORDINATES(2)
         ,p_trunc => p_prune_number
      );

      IF  int_dims  = 3
      AND p_2d_flag = 'FALSE'
      AND p_input.SDO_ORDINATES.EXISTS(3)
      THEN
         str_output := str_output || ' ' || dz_wkt_util.prune_number_varchar2(
             p_input => p_input.SDO_ORDINATES(3)
            ,p_trunc => p_prune_number
         );
      
      END IF;
      
      IF int_dims = 4
      AND p_2d_flag = 'FALSE'
      AND int_lrs = 3
      AND p_input.SDO_ORDINATES.EXISTS(3)
      AND p_input.SDO_ORDINATES.EXISTS(4)
      THEN
         IF p_input.SDO_ORDINATES.EXISTS(4)
         THEN
            str_output := str_output || ' ' || dz_wkt_util.prune_number_varchar2(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            );
            
         END IF;
         
         IF p_input.SDO_ORDINATES.EXISTS(3)
         THEN
            str_output := str_output || ' ' || dz_wkt_util.prune_number_varchar2(
                p_input => p_input.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            );
            
         END IF;
            
      ELSIF int_dims = 4
      AND p_2d_flag = 'FALSE'
      AND int_lrs = 4
      THEN
         IF p_input.SDO_ORDINATES.EXISTS(3)
         THEN
            str_output := str_output || ' ' || dz_wkt_util.prune_number_varchar2(
                p_input => p_input.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            ) ;
            
         END IF;  
         
         IF p_input.SDO_ORDINATES.EXISTS(4)
         THEN
            str_output := str_output || ' ' || dz_wkt_util.prune_number_varchar2(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            );
            
         END IF;
         
      ELSIF int_dims = 4
      AND p_2d_flag = 'FALSE'
      AND int_lrs = 0
      THEN
         IF p_input.SDO_ORDINATES.EXISTS(3)
         THEN
            str_output := str_output || ' ' || dz_wkt_util.prune_number_varchar2(
                p_input => p_input.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            ) ;
            
         END IF;  
         
         IF p_input.SDO_ORDINATES.EXISTS(4)
         THEN
            str_output := str_output || ' ' || dz_wkt_util.prune_number_varchar2(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            );
            
         END IF;
         
      END IF;

      IF p_paren = 'TRUE'
      THEN
         str_output := str_output || ')';
         
      END IF;

      RETURN str_output;

   END point2wkt;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION ords2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_start            IN  NUMBER   DEFAULT 1
      ,p_stop             IN  NUMBER   DEFAULT NULL
      ,p_inter            IN  NUMBER   DEFAULT 1
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      clb_output  CLOB;
      int_start   PLS_INTEGER;
      int_stop    PLS_INTEGER;
      int_counter PLS_INTEGER;
      int_dims    PLS_INTEGER;
      
   BEGIN
   
      int_dims := p_input.get_dims();

      int_start := p_start;
      
      IF p_stop IS NULL
      THEN
         int_stop := p_input.SDO_ORDINATES.COUNT;
         
      ELSE
         int_stop := p_stop;
         
      END IF;

      clb_output  := '(';
      
      IF p_inter = 1
      THEN
         int_counter := int_start;
         WHILE int_counter <= int_stop
         LOOP
            clb_output  := clb_output || TO_CLOB(
               dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(int_counter),
                  p_trunc => p_prune_number
               )
            );
            int_counter := int_counter + 1;

            clb_output  := clb_output || ' ' || TO_CLOB(
               dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(int_counter),
                  p_trunc => p_prune_number
               )
            );
            int_counter := int_counter + 1;

            IF int_dims > 2
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_output  := clb_output || ' ';
                  clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                     p_input => p_input.SDO_ORDINATES(int_counter),
                     p_trunc => p_prune_number
                  );
               END IF;
               
               int_counter := int_counter + 1;
               
            END IF;

            IF int_dims > 3
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_output  := clb_output || ' ';
                  clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                      p_input => p_input.SDO_ORDINATES(int_counter)
                     ,p_trunc => p_prune_number
                  );
               END IF;
               
               int_counter := int_counter + 1;
               
            END IF;

            IF int_counter < int_stop
            THEN
               clb_output := clb_output || ',';
            END IF;

         END LOOP;

      ELSIF p_inter = 3
      THEN
         IF int_dims != (p_stop - p_start + 1)/2
         THEN
            RAISE_APPLICATION_ERROR(
                -20001
               ,'extract etype 3 from geometry'
            );
            
         END IF;

         IF int_dims = 2
         THEN
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(3),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(3),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(4),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(4),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );

         ELSIF int_dims = 3
         THEN
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(4),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(4),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(5),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(6),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(5),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(6),
                  p_trunc => p_prune_number
               );
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
            END IF;

         ELSIF int_dims = 4
         THEN
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(4),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(5),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(4),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(5),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(6),
               p_trunc => p_prune_number
            );
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(7),
                  p_trunc => p_prune_number
               );
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(8),
                  p_trunc => p_prune_number
               );
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(6),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(7),
                  p_trunc => p_prune_number);
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(8),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(4),
                  p_trunc => p_prune_number
               );
               
            END IF;

         END IF;

      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'no code for interpretation ' || p_inter
         );
         
      END IF;

      RETURN clb_output || ')';

   END ords2wkt;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION strungords2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_start            IN  NUMBER   DEFAULT 1
      ,p_stop             IN  NUMBER   DEFAULT NULL
      ,p_inter            IN  NUMBER   DEFAULT 1
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      clb_output  CLOB;
      int_start   PLS_INTEGER;
      int_stop    PLS_INTEGER;
      int_counter PLS_INTEGER;
      int_dims    PLS_INTEGER;
      
   BEGIN
   
      int_dims := p_input.get_dims();

      int_start := p_start;
      
      IF p_stop IS NULL
      THEN
         int_stop := p_input.SDO_ORDINATES.COUNT;
         
      ELSE
         int_stop := p_stop + (int_dims - 1);
         
      END IF;

      clb_output  := '(';
      
      IF p_inter IN (1,2)
      THEN
         int_counter := int_start;
         WHILE int_counter <= int_stop
         LOOP
            clb_output  := clb_output || TO_CLOB(
               dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(int_counter),
                  p_trunc => p_prune_number
               )
            );
            
            int_counter := int_counter + 1;

            clb_output  := clb_output || ' ' || TO_CLOB(
               dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(int_counter),
                  p_trunc => p_prune_number
               )
            );
            
            int_counter := int_counter + 1;

            IF int_dims > 2
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_output  := clb_output || ' ';
                  clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                     p_input => p_input.SDO_ORDINATES(int_counter),
                     p_trunc => p_prune_number
                  );
                  
               END IF;
               
               int_counter := int_counter + 1;
               
            END IF;

            IF int_dims > 3
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_output  := clb_output || ' ';
                  clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                      p_input => p_input.SDO_ORDINATES(int_counter)
                     ,p_trunc => p_prune_number
                  );
                  
               END IF;
               
               int_counter := int_counter + 1;
               
            END IF;

            IF int_counter <= int_stop
            THEN
               clb_output := clb_output || ',';
               
            END IF;

         END LOOP;

      ELSIF p_inter = 3
      THEN
         IF int_dims != (p_stop - p_start + 1)/2
         THEN
            RAISE_APPLICATION_ERROR(
                -20001
               ,'extract etype 3 from geometry'
            );
            
         END IF;

         IF int_dims = 2
         THEN
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(3),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(3),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(4),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(4),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );

         ELSIF int_dims = 3
         THEN
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(4),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(4),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(5),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(6),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(5),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(6),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
               
            END IF;

         ELSIF int_dims = 4
         THEN
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(4),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(5),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(4),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(5),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(6),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(7),
                  p_trunc => p_prune_number
               );
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(8),
                  p_trunc => p_prune_number
               );
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(6),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(7),
                  p_trunc => p_prune_number);
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(8),
                  p_trunc => p_prune_number
               );
               
            END IF;
            clb_output  := clb_output || ',';

            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(1),
               p_trunc => p_prune_number
            );
            clb_output  := clb_output || ' ';
            clb_output  := clb_output || dz_wkt_util.prune_number_clob(
               p_input => p_input.SDO_ORDINATES(2),
               p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(3),
                  p_trunc => p_prune_number
               );
               clb_output  := clb_output || ' ';
               clb_output  := clb_output || dz_wkt_util.prune_number_clob(
                  p_input => p_input.SDO_ORDINATES(4),
                  p_trunc => p_prune_number
               );
               
            END IF;

         END IF;

      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'no code for interpretation ' || p_inter
         );
         
      END IF;

      RETURN clb_output || ')';

   END strungords2wkt;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION line2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_head             IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      int_dims    PLS_INTEGER;
      int_gtyp    PLS_INTEGER;
      int_lrs     PLS_INTEGER;
      clb_output  CLOB := '';
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();

      IF int_gtyp != 2
      THEN
         RAISE_APPLICATION_ERROR(-20001,'input sdo must be line');
         
      END IF;

      IF p_head = 'TRUE'
      THEN
         clb_output := 'LINESTRING';
         IF  int_dims = 3
         AND int_lrs = 3
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' M';
            
         ELSIF  int_dims = 3
         AND int_lrs = 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' Z';
            
         ELSIF  int_dims = 4
         AND int_lrs > 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' ZM';
            
         ELSIF  int_dims = 4
         AND int_lrs = 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' Z';
            
         END IF;
         
      ELSIF p_head = 'FALSE'
      THEN
         NULL;
      
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_head parameter must be TRUE or FALSE!'
         );
         
      END IF;

      clb_output := clb_output || ords2wkt(
          p_input        => p_input
         ,p_start        => 1
         ,p_stop         => NULL
         ,p_inter        => 1
         ,p_prune_number => p_prune_number
         ,p_2d_flag      => p_2d_flag
      );

      RETURN clb_output;

   END line2wkt;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION circularstring2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_head             IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      int_dims    PLS_INTEGER;
      int_gtyp    PLS_INTEGER;
      int_lrs     PLS_INTEGER;
      clb_output  CLOB := '';
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();

      IF int_gtyp != 2
      THEN
         RAISE_APPLICATION_ERROR(-20001,'input sdo must be line');
         
      END IF;

      IF p_head = 'TRUE'
      THEN
         clb_output := 'CIRCULARSTRING';
         IF  int_dims = 3
         AND int_lrs = 3
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' M';
            
         ELSIF int_dims = 3
         AND int_lrs = 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' Z';
            
         ELSIF int_dims = 4
         AND int_lrs > 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' ZM';
            
         ELSIF int_dims = 4
         AND int_lrs = 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' Z';
            
         END IF;
         
      ELSIF p_head = 'FALSE'
      THEN
         NULL;
      
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_head parameter must be TRUE or FALSE'
         );
         
      END IF;

      clb_output := clb_output || ords2wkt(
          p_input        => p_input
         ,p_start        => 1
         ,p_stop         => NULL
         ,p_inter        => 1
         ,p_prune_number => p_prune_number
         ,p_2d_flag      => p_2d_flag
      );

      RETURN clb_output;

   END circularstring2wkt;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION compoundcurve2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_head             IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      int_dims    PLS_INTEGER;
      int_gtyp    PLS_INTEGER;
      int_lrs     PLS_INTEGER;
      clb_output  CLOB := '';
      
      int_parts   PLS_INTEGER;
      int_offset  PLS_INTEGER;
      int_trip1   NUMBER;
      int_trip2   NUMBER;
      int_trip3   NUMBER;
      int_start   PLS_INTEGER;
      int_stop    PLS_INTEGER;
      
      str_notation VARCHAR2(3 Char) := '';
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();

      IF int_gtyp != 2
      THEN
         RAISE_APPLICATION_ERROR(-20001,'input sdo must be line');
         
      END IF;

      IF p_head = 'TRUE'
      THEN
         clb_output := 'COMPOUNDCURVE';
         IF  int_dims = 3
         AND int_lrs = 3
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' M';
            str_notation := ' M';
            
         ELSIF int_dims = 3
         AND int_lrs = 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' Z';
            str_notation := ' Z';
            
         ELSIF int_dims = 4
         AND int_lrs > 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' ZM';
            str_notation := ' ZM';
            
         ELSIF int_dims = 4
         AND int_lrs = 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || ' Z';
            str_notation := ' Z';
            
         END IF;
         
      ELSIF p_head = 'FALSE'
      THEN
         NULL;
      
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_head parameter must be TRUE or FALSE'
         );
         
      END IF;
      
      int_parts  := p_input.SDO_ELEM_INFO(3);
      int_offset := 4;
      
      clb_output := clb_output || '(';

      FOR i IN 1 .. int_parts
      LOOP
      
         WHILE int_offset <= p_input.SDO_ELEM_INFO.COUNT
         LOOP
            int_trip1 := p_input.SDO_ELEM_INFO(int_offset);
            int_offset := int_offset + 1;
            int_trip2 := p_input.SDO_ELEM_INFO(int_offset);
            int_offset := int_offset + 1;
            int_trip3 := p_input.SDO_ELEM_INFO(int_offset);
            int_offset := int_offset + 1;
            
            int_start := int_trip1;
            
            IF int_offset > p_input.SDO_ELEM_INFO.COUNT
            THEN
               int_stop := NULL;
            
            ELSE
               int_stop := p_input.SDO_ELEM_INFO(int_offset);
               
            END IF;
         
            IF int_trip3  = 1
            THEN
               NULL;
                
            ELSIF int_trip3 = 2
            THEN
               clb_output := clb_output || 'CIRCULARSTRING' || str_notation;
            
            ELSE
               RAISE_APPLICATION_ERROR(-20001,'unknown etype');
               
            END IF;
            
            clb_output := clb_output || strungords2wkt(
                p_input        => p_input
               ,p_start        => int_start
               ,p_stop         => int_stop
               ,p_inter        => int_trip3
               ,p_prune_number => p_prune_number
               ,p_2d_flag      => p_2d_flag
            );
            
            IF int_offset < p_input.SDO_ELEM_INFO.COUNT
            THEN 
               clb_output := clb_output || ','; 
            
            END IF;
                        
         END LOOP;
      
      END LOOP;
      
      clb_output := clb_output || ')';

      RETURN clb_output;

   END compoundcurve2wkt;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION polygon2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_head             IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      int_dims    PLS_INTEGER;
      int_gtyp    PLS_INTEGER;
      int_lrs     PLS_INTEGER;
      int_counter PLS_INTEGER;
      clb_output  CLOB := '';
      int_offset  PLS_INTEGER;
      int_etype   PLS_INTEGER;
      int_inter   PLS_INTEGER;
      int_start   PLS_INTEGER;
      int_stop    PLS_INTEGER;
      
   BEGIN

      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();

      IF int_gtyp <> 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be polygon'
         );
         
      END IF;

      IF p_head = 'TRUE'
      THEN
         clb_output := 'POLYGON';
         
         IF  int_dims = 3
         AND p_2d_flag = 'FALSE'
         and int_lrs  = 0
         THEN
            clb_output := clb_output || ' Z';
         
         ELSIF  int_dims = 3
         AND p_2d_flag = 'FALSE'
         and int_lrs  = 3
         THEN
            clb_output := clb_output || ' M';
            
         ELSIF  int_dims = 4
         AND p_2d_flag = 'FALSE'
         and int_lrs  = 0
         THEN
            clb_output := clb_output || ' Z';
         
         ELSIF  int_dims = 4
         AND p_2d_flag = 'FALSE'
         and int_lrs IN (3,4)
         THEN
            clb_output := clb_output || ' ZM';
               
         END IF;
         
      END IF;

      clb_output  := clb_output || '(';
      int_counter := 1;
      WHILE int_counter <= p_input.SDO_ELEM_INFO.COUNT
      LOOP
         int_offset  := p_input.SDO_ELEM_INFO(int_counter);
         int_counter := int_counter + 1;
         int_etype   := p_input.SDO_ELEM_INFO(int_counter);
         int_counter := int_counter + 1;
         int_inter   := p_input.SDO_ELEM_INFO(int_counter);
         int_counter := int_counter + 1;

         int_start   := int_offset;
         IF int_counter > p_input.SDO_ELEM_INFO.COUNT
         THEN
            int_stop := NULL;
            
         ELSE
            int_stop := p_input.SDO_ELEM_INFO(int_counter) - 1;
            
         END IF;
         
         --dbms_output.put_line(int_start || ' ' || int_stop || ' ' || int_inter);
         IF int_etype IN (1003,2003)
         THEN
            clb_output := clb_output || ords2wkt(
                p_input        => p_input
               ,p_start        => int_start
               ,p_stop         => int_stop
               ,p_inter        => int_inter
               ,p_prune_number => p_prune_number
               ,p_2d_flag      => p_2d_flag
            );
            
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'no support for etype ' || int_etype
            );
            
         END IF;

         IF int_counter < p_input.SDO_ELEM_INFO.COUNT
         THEN
            clb_output := clb_output || ',';
            
         END IF;

      END LOOP;

      clb_output  := clb_output || ')';

      RETURN clb_output;

   END polygon2wkt;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION curvepolygon2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_head             IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      int_dims     PLS_INTEGER;
      int_gtyp     PLS_INTEGER;
      int_lrs      PLS_INTEGER;
      int_counter  PLS_INTEGER;
      clb_output   CLOB := '';
      int_offset   PLS_INTEGER;
      int_etype    PLS_INTEGER;
      int_inter    PLS_INTEGER;
      int_start    PLS_INTEGER;
      int_stop     PLS_INTEGER;
      str_notation VARCHAR2(3 Char);
      
   BEGIN

      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();

      IF int_gtyp <> 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be polygon'
         );
         
      END IF;

      IF p_head = 'TRUE'
      THEN
         clb_output := 'CURVEPOLYGON';
         
         IF  int_dims = 3
         AND p_2d_flag = 'FALSE'
         and int_lrs  = 0
         THEN
            clb_output := clb_output || ' Z';
            str_notation := ' Z';
         
         ELSIF  int_dims = 3
         AND p_2d_flag = 'FALSE'
         and int_lrs  = 3
         THEN
            clb_output := clb_output || ' M';
            str_notation := ' M';
            
         ELSIF  int_dims = 4
         AND p_2d_flag = 'FALSE'
         and int_lrs  = 0
         THEN
            clb_output := clb_output || ' Z';
            str_notation := ' Z';
         
         ELSIF  int_dims = 4
         AND p_2d_flag = 'FALSE'
         and int_lrs IN (3,4)
         THEN
            clb_output := clb_output || ' ZM';
            str_notation := ' ZM';
               
         END IF;
         
      END IF;

      RAISE_APPLICATION_ERROR(
          -20001
         ,'Unimplemented'
      );

      RETURN clb_output;

   END curvepolygon2wkt;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION simplesdo2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_head             IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_paren            IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      int_gtype   PLS_INTEGER;
      
   BEGIN
   
      int_gtype := p_input.get_gtype();

      IF int_gtype  = 1
      THEN
         RETURN point2wkt(
             p_input        => p_input
            ,p_head         => p_head
            ,p_paren        => p_paren
            ,p_prune_number => p_prune_number
            ,p_2d_flag      => p_2d_flag
         );
         
      ELSIF int_gtype = 2
      AND p_input.SDO_ELEM_INFO(1) = 1
      AND p_input.SDO_ELEM_INFO(2) = 2
      AND p_input.SDO_ELEM_INFO(3) = 1
      THEN
         RETURN line2wkt(
             p_input        => p_input
            ,p_head         => p_head
            ,p_prune_number => p_prune_number
            ,p_2d_flag      => p_2d_flag
         );
      
      ELSIF int_gtype = 2
      AND p_input.SDO_ELEM_INFO(1) = 1
      AND p_input.SDO_ELEM_INFO(2) = 2
      AND p_input.SDO_ELEM_INFO(3) = 2
      THEN
         RETURN circularstring2wkt(
             p_input        => p_input
            ,p_head         => p_head
            ,p_prune_number => p_prune_number
            ,p_2d_flag      => p_2d_flag
         );
      
      ELSIF int_gtype = 2
      AND p_input.SDO_ELEM_INFO(1) = 1
      AND p_input.SDO_ELEM_INFO(2) = 4
      THEN
         RETURN compoundcurve2wkt(
             p_input        => p_input
            ,p_head         => p_head
            ,p_prune_number => p_prune_number
            ,p_2d_flag      => p_2d_flag
         );
              
      ELSIF int_gtype = 3
      AND p_input.SDO_ELEM_INFO(2) = 1003
      THEN
         RETURN polygon2wkt(
             p_input         => p_input
            ,p_head          => p_head
            ,p_prune_number  => p_prune_number
            ,p_2d_flag       => p_2d_flag
         );
      
      ELSIF int_gtype = 3
      AND p_input.SDO_ELEM_INFO(2) = 1005
      THEN
         RETURN curvepolygon2wkt(
             p_input         => p_input
            ,p_head          => p_head
            ,p_prune_number  => p_prune_number
            ,p_2d_flag       => p_2d_flag
         );
           
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unable to process gtype ' || int_gtype || ' elem ' ||
             p_input.SDO_ELEM_INFO(1) || ',' ||
             p_input.SDO_ELEM_INFO(2) || ',' ||
             p_input.SDO_ELEM_INFO(3)
         );
         
      END IF;

   END simplesdo2wkt;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2wkt(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_add_ewkt_srid    IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
      str_2d_flag   VARCHAR2(4000 Char) := UPPER(p_2d_flag);
      str_ewkt_flag VARCHAR2(4000 Char) := UPPER(p_add_ewkt_srid);
      sdo_input     MDSYS.SDO_GEOMETRY := p_input;
      int_gtype     PLS_INTEGER;
      int_dims      PLS_INTEGER;
      int_lrs       PLS_INTEGER;
      int_stop      PLS_INTEGER;
      int_counter   PLS_INTEGER;
      clb_output    CLOB;
      str_type      VARCHAR2(4000 Char);
      
      --------------------------------------------------------------------------
      --------------------------------------------------------------------------
      FUNCTION recursive_unload(
          p_input        IN  MDSYS.SDO_GEOMETRY
         ,p_2d_flag      IN  VARCHAR2
         ,p_prune_number IN  NUMBER
         ,p_sanity_check IN  BOOLEAN
      ) RETURN CLOB DETERMINISTIC
      AS
         clb_output    CLOB;
         sdo_input     MDSYS.SDO_GEOMETRY := p_input;
         int_elemcount PLS_INTEGER;
         
      BEGIN
      
         int_elemcount := MDSYS.SDO_UTIL.GETNUMELEM(sdo_input);
      
         IF sdo_input.get_gtype() IN (1,2,3)
         THEN
            clb_output := simplesdo2wkt(
                p_input        => sdo_input
               ,p_head         => 'TRUE'
               ,p_paren        => 'TRUE'
               ,p_prune_number => p_prune_number
               ,p_2d_flag      => p_2d_flag
            );
            
         ELSIF sdo_input.GET_GTYPE() = 4
         AND int_elemcount = 1
         AND sdo_input.SDO_ELEM_INFO.COUNT = 3
         AND sdo_input.SDO_ELEM_INFO(1) = 1
         AND sdo_input.SDO_ELEM_INFO(1) = 1
         AND sdo_input.SDO_ELEM_INFO(1) = 1
         THEN
            sdo_input.sdo_gtype := TO_CHAR(sdo_input.GET_DIMS()) || TO_CHAR(sdo_input.GET_LRS_DIM()) || '01';
            clb_output := simplesdo2wkt(
                p_input        => sdo_input
               ,p_head         => 'TRUE'
               ,p_paren        => 'TRUE'
               ,p_prune_number => p_prune_number
               ,p_2d_flag      => p_2d_flag
            );
         
         ELSE
            
            IF sdo_input.get_gtype() = 4
            AND int_elemcount = 1 
            AND p_sanity_check = TRUE
            THEN
               RAISE_APPLICATION_ERROR(
                   -20001
                  ,'collection extract gtype bug'
               );
               
            END IF;
            
            FOR i IN 1 .. int_elemcount
            LOOP
               clb_output := clb_output || recursive_unload(
                   p_input        => MDSYS.SDO_UTIL.EXTRACT(sdo_input,i)
                  ,p_2d_flag      => p_2d_flag
                  ,p_prune_number => p_prune_number
                  ,p_sanity_check => TRUE
               );
               
               IF i < MDSYS.SDO_UTIL.GETNUMELEM(sdo_input)
               THEN
                  clb_output := clb_output || ',';
                  
               END IF;
                  
            END LOOP;
               
         END IF;
         
         RETURN clb_output;
      
      END recursive_unload;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Bail if input geometry is null
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'FALSE';
         
      ELSIF str_2d_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'boolean error'
         );
         
      END IF;
      
      IF str_ewkt_flag IS NULL
      THEN
         str_ewkt_flag := 'FALSE';
      
      ELSIF str_ewkt_flag NOT IN ('TRUE','FALSE')
      THEN
         IF dz_wkt_util.safe_to_number(str_ewkt_flag) IS NULL
         THEN
            RAISE_APPLICATION_ERROR(
                -20001
               ,'p_ewkt_flag may be TRUE, FALSE or numeric SRID'
            );
            
         END IF;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Run CS transform if required and add EWKT SRID if requested
      --------------------------------------------------------------------------
      IF p_output_srid IS NOT NULL
      THEN
         sdo_input := dz_wkt_util.smart_transform(
             p_input => sdo_input
            ,p_srid  => p_output_srid
         );
         
      END IF;
      
      IF str_ewkt_flag = 'TRUE'
      THEN
         IF sdo_input.SDO_SRID IS NOT NULL
         THEN
            clb_output := 'SRID=' || TO_CHAR(sdo_input.SDO_SRID) || ';';
         
         ELSE
            clb_output := 'SRID=0;';
            
         END IF;
         
      ELSIF str_ewkt_flag = 'FALSE'
      THEN
         clb_output := '';
      
      ELSE
         clb_output := 'SRID=' || str_ewkt_flag || ';';
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Convert into WKT
      --------------------------------------------------------------------------
      int_gtype := sdo_input.get_gtype();
      int_dims  := sdo_input.get_dims();
      int_lrs   := sdo_input.get_lrs_dim();

      IF int_gtype IN (1,2,3)
      THEN
         RETURN clb_output || simplesdo2wkt(
             p_input        => sdo_input
            ,p_head         => 'TRUE'
            ,p_paren        => 'TRUE'
            ,p_prune_number => p_prune_number
            ,p_2d_flag      => p_2d_flag
         );

      ELSIF int_gtype = 4
      THEN
         str_type := 'GEOMETRYCOLLECTION';
         
         IF int_dims = 3
         AND int_lrs = 3
         THEN
            str_type := str_type || ' M';
         
         ELSIF int_dims = 3
         AND int_lrs = 0
         THEN
            str_type := str_type || ' Z';
            
         END IF;
         
         IF  int_dims = 4
         AND int_lrs <> 0
         THEN
            str_type := str_type || ' M';
         
         END IF;         
         
         RETURN clb_output || str_type || '(' ||
            recursive_unload(
                p_input        => sdo_input
               ,p_2d_flag      => p_2d_flag
               ,p_prune_number => p_prune_number
               ,p_sanity_check => FALSE
            ) || ')';

      ELSIF int_gtype = 5
      AND MDSYS.SDO_UTIL.GETNUMELEM(sdo_input) = 1
      THEN
         IF int_dims > 2
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || 'MULTIPOINT Z(';
            
         ELSE
            clb_output := clb_output || 'MULTIPOINT(';
            
         END IF;

         int_stop := sdo_input.SDO_ORDINATES.COUNT;
         int_counter := 1;
         WHILE int_counter <= int_stop
         LOOP
            clb_output  := clb_output || '(' ||
               dz_wkt_util.prune_number_clob(
                  p_input => sdo_input.SDO_ORDINATES(int_counter),
                  p_trunc => p_prune_number
               );
            int_counter := int_counter + 1;

            clb_output  := clb_output || ' ';
            clb_output  := clb_output || 
            dz_wkt_util.prune_number_clob(
               p_input => sdo_input.SDO_ORDINATES(int_counter),
               p_trunc => p_prune_number
            );
            int_counter := int_counter + 1;

            IF int_dims > 2
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_output  := clb_output || ' ';
                  clb_output  := clb_output || 
                  dz_wkt_util.prune_number_clob(
                     p_input => sdo_input.SDO_ORDINATES(int_counter),
                     p_trunc => p_prune_number
                  );
                  
               END IF;
               
               int_counter := int_counter + 1;
               
            END IF;

            IF int_dims > 3
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_output  := clb_output || ' ';
                  clb_output  := clb_output || 
                  dz_wkt_util.prune_number_clob(
                     p_input => sdo_input.SDO_ORDINATES(int_counter),
                     p_trunc => p_prune_number
                  );
                  
               END IF;
               
               int_counter := int_counter + 1;
               
            END IF;
            
            clb_output  := clb_output || ')';

            IF int_counter < int_stop
            THEN
               clb_output := clb_output || ',';
               
            END IF;

         END LOOP;

         RETURN clb_output || ')';

      ELSIF int_gtype = 5
      AND MDSYS.SDO_UTIL.GETNUMELEM(sdo_input) > 1
      THEN
         IF int_dims > 2
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || 'MULTIPOINT Z(';
            
         ELSE
            clb_output := clb_output || 'MULTIPOINT(';
            
         END IF;

         FOR i IN 1 .. MDSYS.SDO_UTIL.GETNUMELEM(sdo_input)
         LOOP
            clb_output := clb_output || simplesdo2wkt(
                p_input        => MDSYS.SDO_UTIL.EXTRACT(sdo_input,i)
               ,p_head         => 'FALSE'
               ,p_paren        => 'TRUE'
               ,p_prune_number => p_prune_number
               ,p_2d_flag      => p_2d_flag
            );

            IF i < MDSYS.SDO_UTIL.GETNUMELEM(sdo_input)
            THEN
               clb_output := clb_output || ',';
               
            END IF;

         END LOOP;

         RETURN clb_output || ')';

      ELSIF int_gtype = 6
      THEN
         IF int_dims > 2
         AND int_lrs = 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || 'MULTILINESTRING Z(';
            
         ELSIF int_dims > 2
         AND int_lrs > 0
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || 'MULTILINESTRING ZM(';
            
         ELSE
            clb_output := clb_output || 'MULTILINESTRING(';
            
         END IF;

         FOR i IN 1 .. MDSYS.SDO_UTIL.GETNUMELEM(sdo_input)
         LOOP
            clb_output := clb_output || simplesdo2wkt(
                p_input        => MDSYS.SDO_UTIL.EXTRACT(sdo_input,i)
               ,p_head         => 'FALSE'
               ,p_paren        => 'TRUE'
               ,p_prune_number => p_prune_number
               ,p_2d_flag      => p_2d_flag
            );

            IF i < MDSYS.SDO_UTIL.GETNUMELEM(sdo_input)
            THEN
               clb_output := clb_output || ',';
               
            END IF;

         END LOOP;

         RETURN clb_output || ')';

      ELSIF int_gtype = 7
      THEN
         IF int_dims > 2
         AND p_2d_flag = 'FALSE'
         THEN
            clb_output := clb_output || 'MULTIPOLYGON Z(';
            
         ELSE
            clb_output := clb_output || 'MULTIPOLYGON(';
            
         END IF;

         FOR i IN 1 .. MDSYS.SDO_UTIL.GETNUMELEM(sdo_input)
         LOOP
            clb_output := clb_output || simplesdo2wkt(
                p_input        => MDSYS.SDO_UTIL.EXTRACT(sdo_input,i)
               ,p_head         => 'FALSE'
               ,p_paren        => 'TRUE'
               ,p_prune_number => p_prune_number
               ,p_2d_flag      => p_2d_flag
            );

            IF i < MDSYS.SDO_UTIL.GETNUMELEM(sdo_input)
            THEN
               clb_output := clb_output || ',';
               
            END IF;

         END LOOP;

         RETURN clb_output || ')';

      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unknown gtype of ' || int_gtype
         );
         
      END IF;

   END sdo2wkt;

END dz_wkt_main;
/


--*************************--
PROMPT DZ_WKT_TEST.pks;

CREATE OR REPLACE PACKAGE dz_wkt_test
AUTHID CURRENT_USER
AS

   C_TFS_CHANGESET CONSTANT NUMBER := 8194;
   C_JENKINS_JOBNM CONSTANT VARCHAR2(255 Char) := 'NULL';
   C_JENKINS_BUILD CONSTANT NUMBER := 3;
   C_JENKINS_BLDID CONSTANT VARCHAR2(255 Char) := 'NULL';
   
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


--*************************--
PROMPT DZ_WKT_TEST.pkb;

CREATE OR REPLACE PACKAGE BODY dz_wkt_test
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION test_against_oracle (
       p_input     IN  MDSYS.SDO_GEOMETRY
      ,p_mode      IN  VARCHAR2 DEFAULT 'TEST'
      ,p_tolerance IN  NUMBER   DEFAULT 0.05
   ) RETURN CLOB
   AS
      sdo_conversion MDSYS.SDO_GEOMETRY;
      clb_conversion CLOB;
      int_srid       PLS_INTEGER;
      num_tolerance  NUMBER := p_tolerance;
      
   BEGIN
   
      IF num_tolerance IS NULL
      THEN
         num_tolerance := 0.05;
      END IF;
   
      int_srid       := p_input.SDO_SRID;
      clb_conversion := p_input.get_WKT();
      sdo_conversion := dz_wkt_main.wkt2sdo(clb_conversion,int_srid);

      IF p_mode = 'TEST'
      THEN
         RETURN MDSYS.SDO_GEOM.RELATE(
             p_input
            ,'DETERMINE'
            ,sdo_conversion
            ,num_tolerance
         );
      
      ELSIF p_mode IN ('WKT')
      THEN
         RETURN p_input.get_WKT();
      
      ELSIF p_mode IN ('SDO_1','1')
      THEN
         RETURN MDSYS.SDO_UTIL.TO_CLOB(p_input);
      
      ELSIF p_mode IN ('SDO_2','2')
      THEN
         RETURN MDSYS.SDO_UTIL.TO_CLOB(sdo_conversion);
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unknown mode'
         );
         
      END IF;

   END test_against_oracle;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION test_against_self(
       p_input     IN  MDSYS.SDO_GEOMETRY
      ,p_mode      IN  VARCHAR2 DEFAULT 'TEST'
      ,p_tolerance IN  NUMBER   DEFAULT 0.05
   ) RETURN CLOB
   AS
      sdo_conversion MDSYS.SDO_GEOMETRY;
      clb_conversion CLOB;
      int_srid       PLS_INTEGER;
      num_tolerance  NUMBER := p_tolerance;
      
   BEGIN
   
      IF num_tolerance IS NULL
      THEN
         num_tolerance := 0.05;
      END IF;
   
      int_srid       := p_input.SDO_SRID;
      clb_conversion := dz_wkt_main.sdo2wkt(p_input,'FALSE');
      sdo_conversion := dz_wkt_main.wkt2sdo(clb_conversion,int_srid);

      IF p_mode = 'TEST'
      THEN
         RETURN MDSYS.SDO_GEOM.RELATE(
             p_input
            ,'DETERMINE'
            ,sdo_conversion
            ,num_tolerance
         );
         
      ELSIF p_mode IN ('WKT')
      THEN
         RETURN clb_conversion;
      
      ELSIF p_mode IN ('SDO_1','1')
      THEN
         RETURN MDSYS.SDO_UTIL.TO_CLOB(p_input);
      
      ELSIF p_mode IN ('SDO_2','2')
      THEN
         RETURN MDSYS.SDO_UTIL.TO_CLOB(sdo_conversion);
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unknown mode'
         );
         
      END IF;

   END test_against_self;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER
   AS
      num_check NUMBER;
      
   BEGIN
      
      FOR i IN 1 .. C_PREREQUISITES.COUNT
      LOOP
         SELECT 
         COUNT(*)
         INTO num_check
         FROM 
         user_objects a
         WHERE 
             a.object_name = C_PREREQUISITES(i) || '_TEST'
         AND a.object_type = 'PACKAGE';
         
         IF num_check <> 1
         THEN
            RETURN 1;
         
         END IF;
      
      END LOOP;
      
      RETURN 0;
   
   END prerequisites;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2
   AS
   BEGIN
      RETURN '{"TFS":' || C_TFS_CHANGESET || ','
      || '"JOBN":"' || C_JENKINS_JOBNM || '",'   
      || '"BUILD":' || C_JENKINS_BUILD || ','
      || '"BUILDID":"' || C_JENKINS_BLDID || '"}';
      
   END version;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER
   AS
      num_test     NUMBER;
      num_results  NUMBER := 0;
      clb_results  CLOB;
      sdo_results  MDSYS.SDO_GEOMETRY;
      
      --------------------------------------------------------------------------
      --------------------------------------------------------------------------
      FUNCTION sdocheck(
          p_sdo_input    IN  MDSYS.SDO_GEOMETRY
         ,p_clb_expected IN  CLOB
         ,p_check_oracle IN  BOOLEAN DEFAULT FALSE
         ,p_tolerance    IN  NUMBER DEFAULT 0.05
         ,p_sdo_override IN  MDSYS.SDO_GEOMETRY DEFAULT NULL
      ) RETURN NUMBER
      AS
         num_srid   NUMBER;
         sdo_final  MDSYS.SDO_GEOMETRY;
         sdo_oracle MDSYS.SDO_GEOMETRY;
         clb_test   CLOB;
         wkt_oracle CLOB;
         str_check  VARCHAR2(255 Char);
         
         FUNCTION validator(
             p_input     IN  MDSYS.SDO_GEOMETRY
            ,p_tolerance IN  NUMBER
         ) RETURN VARCHAR2
         AS
            str_results VARCHAR2(4000 Char);
            num_lrs_dim NUMBER;
            
         BEGIN
            
            num_lrs_dim := p_input.get_lrs_dim();
            
            str_results := MDSYS.SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT(
                p_input
               ,p_tolerance
            );
            
            IF num_lrs_dim = 0
            THEN
               RETURN str_results;
               
            END IF;
            
            str_results := MDSYS.SDO_LRS.VALIDATE_LRS_GEOMETRY(
                p_input
            );
            
            IF str_results = '13331'
            AND p_input.get_gtype() IN (4,5,6,7)
            THEN
               str_results := MDSYS.SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT(
                   dz_wkt_util.downsize_2d(p_input)
                  ,p_tolerance
               );
            
            END IF;

            RETURN str_results;
 
         END validator;
         
      BEGIN
         
         num_srid := p_sdo_input.SDO_SRID;
         
         clb_test := dz_wkt_main.sdo2wkt(
             p_input => p_sdo_input
         );
         
         sdo_final := dz_wkt_main.wkt2sdo(
             p_input => clb_test
            ,p_srid  => num_srid
         );
         
         str_check := validator(
             sdo_final
            ,p_tolerance
         );
         IF str_check <> 'TRUE'
         THEN
            dbms_output.put_line(str_check);
            RETURN -2;
            
         END IF;
         
         IF p_check_oracle = TRUE
         THEN
            wkt_oracle := MDSYS.SDO_UTIL.TO_WKTGEOMETRY(p_sdo_input);
            sdo_oracle := dz_wkt_main.wkt2sdo(
                p_input => wkt_oracle
               ,p_srid  => num_srid
            );
            
            IF MDSYS.SDO_GEOM.RELATE(
                sdo_final
               ,'DETERMINE'
               ,sdo_oracle
               ,p_tolerance
            ) NOT IN ('EQUAL')
            THEN
               RETURN -1;
               
            END IF;
         
         END IF;
         
         IF p_sdo_override IS NULL
         THEN
            IF MDSYS.SDO_UTIL.TO_CLOB(sdo_final) <> MDSYS.SDO_UTIL.TO_CLOB(p_sdo_input)
            THEN
               RETURN -4;
                  
            END IF;
            
         ELSE
            IF MDSYS.SDO_UTIL.TO_CLOB(sdo_final) <> MDSYS.SDO_UTIL.TO_CLOB(p_sdo_override)
            THEN
               RETURN -5;
                  
            END IF;
         
         END IF;
         
         RETURN 0;
         
      END sdocheck;
      
      --------------------------------------------------------------------------
      --------------------------------------------------------------------------
      FUNCTION wktcheck(
          p_wkt_clob     IN  CLOB
         ,p_sdo_expected IN  MDSYS.SDO_GEOMETRY DEFAULT NULL
         ,p_check_oracle IN  BOOLEAN DEFAULT FALSE
         ,p_tolerance    IN  NUMBER DEFAULT 0.05
         ,p_wkt_override IN  CLOB DEFAULT NULL
         ,p_srid_force   IN  NUMBER DEFAULT NULL
      ) RETURN NUMBER
      AS
         num_srid   NUMBER;
         sdo_test   MDSYS.SDO_GEOMETRY;
         sdo_oracle MDSYS.SDO_GEOMETRY;
         sdo_final  MDSYS.SDO_GEOMETRY;
         clb_test   CLOB;
         str_check  VARCHAR2(255 Char);
         
         FUNCTION validator(
             p_input     IN  MDSYS.SDO_GEOMETRY
            ,p_tolerance IN  NUMBER
         ) RETURN VARCHAR2
         AS
            str_results VARCHAR2(4000 Char);
            num_lrs_dim NUMBER;
            
         BEGIN
            
            num_lrs_dim := p_input.get_lrs_dim();
            
            str_results := MDSYS.SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT(
                p_input
               ,p_tolerance
            );
            
            IF num_lrs_dim = 0
            THEN
               RETURN str_results;
               
            END IF;
            
            str_results := MDSYS.SDO_LRS.VALIDATE_LRS_GEOMETRY(
                p_input
            );
            
            IF str_results = '13331'
            AND p_input.get_gtype() IN (4,5,6,7)
            THEN
               str_results := MDSYS.SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT(
                   dz_wkt_util.downsize_2d(p_input)
                  ,p_tolerance
               );
            
            END IF;
            
            RETURN str_results;
 
         END validator;
         
      BEGIN
      
         IF p_sdo_expected IS NOT NULL
         THEN
            num_srid := p_sdo_expected.SDO_SRID;
         
         ELSE
            IF p_srid_force IS NOT NULL
            THEN
               num_srid := p_srid_force;
            
            ELSE
               num_srid := NULL;
               
            END IF;
                           
         END IF;
      
         sdo_test := dz_wkt_main.wkt2sdo(
             p_input => p_wkt_clob
            ,p_srid  => num_srid
         );
         
         str_check := validator(
             sdo_test
            ,p_tolerance
         );
         
         IF str_check <> 'TRUE'
         THEN
            dbms_output.put_line(str_check);
            RETURN -2;
            
         END IF;
         
         IF p_sdo_expected IS NOT NULL
         THEN
            IF MDSYS.SDO_UTIL.TO_CLOB(p_sdo_expected) <> MDSYS.SDO_UTIL.TO_CLOB(sdo_test)
            THEN
               dbms_output.put_line(SUBSTR(MDSYS.SDO_UTIL.TO_CLOB(p_sdo_expected),1,4000));
               dbms_output.put_line(SUBSTR(MDSYS.SDO_UTIL.TO_CLOB(sdo_test),1,4000));
               RETURN -1;
               
            END IF;
         
         END IF;
         
         IF p_check_oracle = TRUE
         THEN
            sdo_oracle := MDSYS.SDO_UTIL.FROM_WKTGEOMETRY(p_wkt_clob);
            sdo_oracle.SDO_SRID := num_srid;
            
            str_check := MDSYS.SDO_GEOM.RELATE(
                p_sdo_expected
               ,'DETERMINE'
               ,sdo_test
               ,p_tolerance
            );
            IF str_check NOT IN ('EQUAL')
            THEN
               dbms_output.put_line(str_check);
               RETURN -3;
               
            END IF;
         
         END IF;
         
         clb_test := dz_wkt_main.sdo2wkt(
            p_input => sdo_test
         );
         
         sdo_final := dz_wkt_main.wkt2sdo(
             p_input => clb_test
            ,p_srid  => num_srid
         );
         
         IF p_wkt_override IS NULL
         THEN
            IF MDSYS.SDO_UTIL.TO_CLOB(sdo_final) <> MDSYS.SDO_UTIL.TO_CLOB(sdo_test)
            THEN
               dbms_output.put_line(SUBSTR(MDSYS.SDO_UTIL.TO_CLOB(sdo_final),1,4000));
               dbms_output.put_line(SUBSTR(MDSYS.SDO_UTIL.TO_CLOB(sdo_test),1,4000));
               RETURN -4;
                  
            END IF;
         
         ELSE
            IF MDSYS.SDO_UTIL.TO_CLOB(sdo_final) <> MDSYS.SDO_UTIL.TO_CLOB(dz_wkt_main.wkt2sdo(p_wkt_override,num_srid))
            THEN
               dbms_output.put_line(SUBSTR(MDSYS.SDO_UTIL.TO_CLOB(sdo_final),1,4000));
               dbms_output.put_line(SUBSTR(MDSYS.SDO_UTIL.TO_CLOB(dz_wkt_main.wkt2sdo(p_wkt_override,num_srid)),1,4000));
               RETURN -5;
                  
            END IF;
            
         END IF;
         
         RETURN 0;
      
      END wktcheck;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check 2D Point against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'POINT(-87.845556 42.582222)'
         ,p_sdo_expected => MDSYS.SDO_GEOMETRY(
              2001
             ,8265
             ,MDSYS.SDO_POINT_TYPE(-87.845556,42.582222,NULL)
             ,NULL
             ,NULL
          )
         ,p_check_oracle => TRUE
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Point against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Check 2D Line against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'LINESTRING(-69.3595752695824 46.8212947275705, -69.3675442694518 46.8303115941057, -69.3766786692845 46.840151527372)'
         ,p_check_oracle => TRUE
         ,p_srid_force   => 8265
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Line against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Check 2D Polygon against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'POLYGON ((-77.2903337908711 41.9901156015547, -77.2898433240096 41.9903066678044, -77.2906707236743 41.9905902014476, -77.2903337908711 41.9901156015547))'
         ,p_check_oracle => TRUE
         ,p_srid_force   => 8265
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Polygon against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Check 2D Polygon with hole against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'POLYGON((-69.2352824697095 46.6621271945153, -69.2350178693785 46.6626301943289, -69.2349856026028 46.6630875274683, -69.2353518029427 46.663589993984, -69.2354856697272 46.6641613278839, -69.2357848696753 46.6643667941931, -69.2362164696137 46.664366327445, -69.236847003186 46.6641599941893, -69.2374438031883 46.6637707271383, -69.2376754694467 46.6634275944089, -69.237541269913 46.6627877276724, -69.2372414692177 46.6623079942195, -69.2368756699755 46.6620111945619, -69.2363110027499 46.6618517942258, -69.2360122695499 46.6618521944242, -69.2352824697095 46.6621271945153), (-69.2364458030307 46.6628803272662, -69.2367118692567 46.6631085940872, -69.2365794692664 46.6632915944325, -69.2361148696049 46.6633835276286, -69.2359154692228 46.6632923273799, -69.2359150699239 46.6631093944839, -69.2364458030307 46.6628803272662))'
         ,p_check_oracle => TRUE
         ,p_srid_force   => 8265
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Polygon with hole against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Check 2D Multipoint against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'MULTIPOINT ((-72.0625739321406 44.4558197974466), (-72.2365621315365 42.9447322001319))'
         ,p_check_oracle => TRUE
         ,p_srid_force   => 8265
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Multipoint against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Check 2D Multipoint against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'MULTIPOINT ((-72.0625739321406 44.4558197974466), (-72.2365621315365 42.9447322001319))'
         ,p_check_oracle => TRUE
         ,p_srid_force   => 8265
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Multipoint against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 60
      -- Check 2D MultiLine against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'MULTILINESTRING ((-78.3466269890437 38.83615220656, -78.3475923887771 38.8354434067887), (-71.1501673996052 43.0729051996162, -71.150759800124 43.0725619994377, -71.1507907997549 43.0723791330914))'
         ,p_check_oracle => TRUE
         ,p_srid_force   => 8265
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D MultiLine against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Check 2D MultiPolygon against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'MULTIPOLYGON (((-87.0000061752442 38.7082849396991, -87.0000061752442 38.7095630067283, -87.0007041085071 38.7095636731259, -87.0012883090076 38.709724606806, -87.0015215751599 38.7099536731244, -87.0022805750878 38.7102750062874, -87.0024263749766 38.7104582728319, -87.0023967755901 38.7106642067886, -87.0026301757414 38.7108246728213, -87.0032729086172 38.7108254066681, -87.0036231756684 38.7110088728621, -87.0036221090724 38.7116726732561, -87.0044399084744 38.7118566061983, -87.0047893751289 38.7124064067312, -87.005256908379 38.7124068069295, -87.0062807757366 38.7115608731367, -87.006397708287 38.7115610736855, -87.0065151084848 38.7112178069571, -87.0063401085085 38.7110344729634, -87.0060783752162 38.7102788733722, -87.0054359750895 38.7101408733035, -87.004706375798 38.709613673633, -87.0035383749953 38.7093378065954, -87.0030133085168 38.7089022730224, -87.0025461089152 38.708695806667, -87.0024879758388 38.7085354728347, -87.001932908876 38.7085120733744, -87.0015533751875 38.7083972065667, -87.0008825088201 38.7077556068367, -87.0005905753941 38.7076638067402, -87.0004733757451 38.7078696066979, -87.0006771090607 38.7083276736841, -87.0002681090853 38.708327206936, -87.0000061752442 38.7082354068394, -87.0000061752442 38.7082849396991)), ((-87.0000061752442 38.7095630067283, -86.9995977751166 38.7080756063051, -86.9994811087655 38.7080986064664, -86.9994523754261 38.7084420062944, -86.9996279752502 38.7086478062521, -86.9997459752959 38.7093114735466, -87.0000061752442 38.7095630067283)))'
         ,p_check_oracle => TRUE
         ,p_srid_force   => 8265
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D MultiPolygon against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 80
      -- Check 2D MultiPolygon with holes against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'MULTIPOLYGON (((-80.0953250048658 32.7159313945079, -80.0955357835113 32.716074696591, -80.0955404736155 32.7160682491954, -80.0955840579904 32.7160051986746, -80.0953636819491 32.715931672633, -80.0953250048658 32.7159313945079)), ((-80.0949602730955 32.7155296137794, -80.0950711798662 32.7155755163836, -80.0952989861158 32.7158004122166, -80.0955196256988 32.7158764215914, -80.0956176574695 32.7159425252372, -80.0956211637195 32.7159487372164, -80.0956283923654 32.7159377179453, -80.0956696095527 32.7158713991956, -80.0957089725736 32.7158044179457, -80.0957161340318 32.7157915017999, -80.0954029173656 32.7155463382587, -80.0951683809076 32.7153935559671, -80.0946093033044 32.7152181356549, -80.094219015805 32.7151679606551, -80.0934254819521 32.7151622278425, -80.0925142934118 32.7149211096138, -80.0920982663291 32.7147128872182, -80.0920610850792 32.7146968325306, -80.0918246986212 32.7145958971142, -80.0917145934131 32.714471070552, -80.0916375116423 32.7143780549271, -80.0915386533092 32.7142623288855, -80.0909921178934 32.7140351169069, -80.090777663727 32.7138103090947, -80.0905563668524 32.7137342882613, -80.0903740918527 32.7136901189906, -80.090042886124 32.7136674215948, -80.0896002840413 32.7138446158654, -80.0893860496667 32.7138611007612, -80.0881956486268 32.713667536699, -80.087486701753 32.7136736559698, -80.0872508887325 32.7136510882615, -80.0872458069617 32.713667621074, -80.087225815295 32.7137394929488, -80.0872078277951 32.7138116768029, '
            || '-80.0871918507117 32.7138841393028, -80.0871778918576 32.7139568486776, -80.0871659590451 32.7140297700317, -80.0871642981076 32.7140420330526, -80.088748573626 32.7141180601358, -80.0896916371662 32.7143707122187, -80.0901860121654 32.7144148908646, -80.0906541491439 32.7144160309688, -80.0911161970598 32.714491541906, -80.0912132793513 32.7145193059685, -80.091239564247 32.7145578330517, -80.0912719189346 32.714589638781, -80.0913108496636 32.7146305116976, -80.0918772975795 32.7151307320091, -80.0919734632043 32.7151832945091, -80.0921372803916 32.7152724283632, -80.0924627236203 32.7153379262798, -80.0938283408057 32.7154199627379, -80.0943486111172 32.7154101898212, -80.0945179418462 32.7154159231547, -80.0949602730955 32.7155296137794), (-80.0904781262274 32.7138870658654, -80.0906603356021 32.7140033960735, -80.0907125809146 32.7140466215942, -80.0906347251855 32.71409566899, -80.0897631090411 32.7139653169069, -80.0897434934161 32.7139268382611, -80.0898802590409 32.7138556684696, -80.0900949507072 32.7137940835738, -80.0904781262274 32.7138870658654)))'
         ,p_check_oracle => TRUE
         ,p_srid_force   => 8265
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D MultiPolygon with holes against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 90
      -- Check 2D MultiPolygon against Oracle
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'GEOMETRYCOLLECTION (POINT(4 6),LINESTRING(4 6,7 10),POLYGON ((35 10, 45 45, 15 40, 10 20, 35 10),(20 30, 35 35, 30 20, 20 30)))'
         ,p_check_oracle => TRUE
         ,p_srid_force   => 8265
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Collection against Oracle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 100
      -- Check 2DM Point
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'POINT M(-87.845556 42.582222 100)'
         ,p_sdo_expected => MDSYS.SDO_GEOMETRY(
              3301
             ,8265
             ,NULL
             ,SDO_ELEM_INFO_ARRAY(
                  1
                 ,1
                 ,1
              )
             ,SDO_ORDINATE_ARRAY(
                  -87.845556
                 ,42.582222
                 ,100
              )
          )
         ,p_check_oracle => FALSE
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2DM Point: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 110
      -- Check 3D Point
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'POINT Z(-87.845556 42.582222 12.765)'
         ,p_sdo_expected => MDSYS.SDO_GEOMETRY(
              3001
             ,4327
             ,MDSYS.SDO_POINT_TYPE(
                  -87.845556
                 ,42.582222
                 ,12.765
              )
             ,NULL
             ,NULL
          )
         ,p_check_oracle => FALSE
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 3D Point: ' || num_test);

      --------------------------------------------------------------------------
      -- Step 120
      -- Check 3DM Point
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'POINT ZM(-87.845556 42.582222 12.765 100)'
         ,p_sdo_expected => MDSYS.SDO_GEOMETRY(
              4401
             ,4327
             ,NULL
             ,SDO_ELEM_INFO_ARRAY(
                  1
                 ,1
                 ,1
              )
             ,SDO_ORDINATE_ARRAY(
                  -87.845556
                 ,42.582222
                 ,12.765
                 ,100
              )
          )
         ,p_check_oracle => FALSE
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check 3DM Point: ' || num_test);
       
      --------------------------------------------------------------------------
      -- Step 130
      -- Check Geometry Collection M
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'GEOMETRYCOLLECTIONM(POINTM(2 3 9), LINESTRINGM(2 3 4, 3 4 5))'
         ,p_sdo_expected => MDSYS.SDO_GEOMETRY(
              3304
             ,8265
             ,NULL
             ,SDO_ELEM_INFO_ARRAY(
                  1
                 ,1
                 ,1
                 ,4
                 ,2
                 ,1
              )
             ,SDO_ORDINATE_ARRAY(
                  2
                 ,3
                 ,9
                 ,2
                 ,3
                 ,4
                 ,3
                 ,4
                 ,5
              )
          )
         ,p_check_oracle => FALSE
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check Geometry Collection M: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 140
      -- Check Point MZ possibilities
      --------------------------------------------------------------------------
      num_test := sdocheck(
          p_sdo_input    =>  MDSYS.SDO_GEOMETRY(
              4301
             ,4327
             ,NULL
             ,SDO_ELEM_INFO_ARRAY(
                  1
                 ,1
                 ,1
              )
             ,SDO_ORDINATE_ARRAY(
                  -87
                 ,42
                 ,-100
                 ,12
              )
          )
         ,p_clb_expected => 'POINT ZM(-87 42 12 -100)'
         ,p_check_oracle => FALSE
         ,p_sdo_override => MDSYS.SDO_GEOMETRY(
              4401
             ,4327
             ,NULL
             ,SDO_ELEM_INFO_ARRAY(
                  1
                 ,1
                 ,1
              )
             ,SDO_ORDINATE_ARRAY(
                  -87
                 ,42
                 ,12
                 ,-100
              )
          )
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check Point MZ possibility: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 150
      -- Check EWKT raw point implied 3D
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'POINT(120 130 -10)'
         ,p_sdo_expected => MDSYS.SDO_GEOMETRY(
              3001
             ,4327
             ,SDO_POINT_TYPE(
                  120
                 ,130
                 ,-10
              )
             ,NULL
             ,NULL
          )
         ,p_check_oracle => FALSE
         ,p_wkt_override => 'POINT Z(120 130 -10)'
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check implied 3D Point: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 160
      -- Check EWKT raw point implied 4D
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'POINT(120 130 88 -10)'
         ,p_sdo_expected =>  MDSYS.SDO_GEOMETRY(
              4001
             ,4327
             ,NULL
             ,SDO_ELEM_INFO_ARRAY(
                  1
                 ,1
                 ,1
              )
             ,SDO_ORDINATE_ARRAY(
                  120
                 ,130
                 ,88
                 ,-10
              )
          )
         ,p_check_oracle => FALSE
         ,p_wkt_override => 'POINT Z(120 130 88 -10)'
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check implied 4D Point: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 170
      -- Check EWKT raw line implied 3D
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'LINESTRING(-71.160281 42.258729 -1,-71.260837 42.259113 -2,-71.361144 42.25932 -3)'
         ,p_sdo_expected => MDSYS.SDO_GEOMETRY(
              3002
             ,4327
             ,NULL
             ,SDO_ELEM_INFO_ARRAY(
                  1
                 ,2
                 ,1
              )
             ,SDO_ORDINATE_ARRAY(
                  -71.160281
                 ,42.258729
                 ,-1
                 ,-71.260837
                 ,42.259113
                 ,-2
                 ,-71.361144
                 ,42.25932
                 ,-3
              )
          )
         ,p_check_oracle => FALSE
         ,p_wkt_override => 'LINESTRING Z(-71.160281 42.258729 -1,-71.260837 42.259113 -2,-71.361144 42.25932 -3)'
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check implied 3D Line: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 180
      -- Check EWKT raw line implied 4D
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'LINESTRING(-71.160281 42.258729 -1 11,-71.260837 42.259113 -2 22,-71.361144 42.25932 -3 33)'
         ,p_sdo_expected =>  MDSYS.SDO_GEOMETRY(
              4002
             ,4327
             ,NULL
             ,SDO_ELEM_INFO_ARRAY(
                  1
                 ,2
                 ,1
              )
             ,SDO_ORDINATE_ARRAY(
                  -71.160281
                 ,42.258729
                 ,-1
                 ,11
                 ,-71.260837
                 ,42.259113
                 ,-2
                 ,22
                 ,-71.361144
                 ,42.25932
                 ,-3
                 ,33
              )
          )
         ,p_check_oracle => FALSE
         ,p_wkt_override => 'LINESTRING Z(-71.160281 42.258729 -1 11,-71.260837 42.259113 -2 22,-71.361144 42.25932 -3 33)'
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check implied 4D Line: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 190
      -- Check SRID
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => ' SRID = 4269 ; LINESTRING ( -71.160281 42.258729 , -71.260837 42.259113 , -71.361144 42.25932 )'
         ,p_sdo_expected =>  MDSYS.SDO_GEOMETRY(
              2002
             ,4269
             ,NULL
             ,SDO_ELEM_INFO_ARRAY(
                  1
                 ,2
                 ,1
              )
             ,SDO_ORDINATE_ARRAY(
                  -71.160281
                 ,42.258729
                 ,-71.260837
                 ,42.259113
                 ,-71.361144
                 ,42.25932
              )
          )
         ,p_check_oracle => FALSE
         ,p_wkt_override => 'LINESTRING(-71.160281 42.258729 ,-71.260837 42.259113 ,-71.361144 42.25932 )'
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check SRID: ' || num_test);

      --------------------------------------------------------------------------
      -- Step 200
      -- Check SRID override
      --------------------------------------------------------------------------
      sdo_results := dz_wkt_main.wkt2sdo(
          p_input => 'SRID=4269;LINESTRING(-71.160281 42.258729,-71.260837 42.259113,-71.361144 42.25932)'
         ,p_srid  => 8265    
      );
      IF sdo_results.SDO_SRID = 8265
      THEN
         num_test := 0;
         
      ELSE
         num_test := -1;
         
      END IF;   
      num_results := num_results + num_test;
      dbms_output.put_line('Check SRID Override: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 210
      -- Check Axes override
      --------------------------------------------------------------------------
      sdo_results := dz_wkt_main.wkt2sdo(
          p_input => 'LINESTRING ZM(-71.160281 42.258729 10 -1,-71.260837 42.259113 20 -2,-71.361144 42.25932 30 -3)'
         ,p_srid  => 8265
         ,p_axes_latlong => 'TRUE'    
      );
      IF sdo_results.SDO_ORDINATES(1) = 42.258729
      THEN
         num_test := 0;
         
      ELSE
         num_test := -1;
         
      END IF;   
      num_results := num_results + num_test;
      dbms_output.put_line('Check Axes Override: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 220
      -- Check EWKT SRID addition
      --------------------------------------------------------------------------
      clb_results := dz_wkt_main.sdo2wkt(
          dz_wkt_main.wkt2sdo(
              p_input => 'SRID=4327;MULTIPOINTM(0 0 0,1 2 1)'    
          )
         ,p_add_ewkt_srid => 'TRUE'
      );
      
      IF SUBSTR(clb_results,1,10) = 'SRID=4327;'
      THEN
         num_test := 0;
         
      ELSE
         num_test := -1;
         
      END IF;   
      num_results := num_results + num_test;
      dbms_output.put_line('Check EWKT SRID addition: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 230
      -- Check Empty option
      --------------------------------------------------------------------------
      sdo_results := dz_wkt_main.wkt2sdo(
          p_input => 'POLYGON ZM EMPTY'   
      );
      
      IF sdo_results IS NULL
      THEN
         num_test := 0;
         
      ELSE
         num_test := -1;
         
      END IF;   
      num_results := num_results + num_test;
      dbms_output.put_line('Check EMPTY option: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 240
      -- Check Scientific Notation Test
      --------------------------------------------------------------------------
      num_test := wktcheck(
          p_wkt_clob     => 'POINT(-67.000207185806265013 -1.06637853128938E-05)'
         ,p_sdo_expected => MDSYS.SDO_GEOMETRY(
              2001
             ,8265
             ,SDO_POINT_TYPE(
                  -67.000207185806265013
                 ,-0.0000106637853128938
                 ,NULL
              )
             ,NULL
             ,NULL
          )
         ,p_check_oracle => FALSE
      );
      num_results := num_results + num_test;
      dbms_output.put_line('Check Scientific Notation: ' || num_test);
      
      
      RETURN num_results;
      
   END inmemory_test;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END scratch_test;

END dz_wkt_test;
/


--*************************--
PROMPT sqlplus_footer.sql;


SHOW ERROR;

DECLARE
   l_num_errors PLS_INTEGER;

BEGIN

   SELECT
   COUNT(*)
   INTO l_num_errors
   FROM
   user_errors a
   WHERE
   a.name LIKE 'DZ_WKT%';

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'COMPILE ERROR');

   END IF;

   l_num_errors := DZ_WKT_TEST.inmemory_test();

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'INMEMORY TEST ERROR');

   END IF;

END;
/

EXIT;

