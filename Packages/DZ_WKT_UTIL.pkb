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
         ary_output2 MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY();
         int_index   PLS_INTEGER := 1;
         str_check   VARCHAR2(4000 Char);
         
      BEGIN

         --------------------------------------------------------------------------
         -- Step 10
         -- Exit if input is empty
         --------------------------------------------------------------------------
         IF p_input IS NULL
         OR p_input.COUNT = 0
         THEN
            RETURN ary_output2;
            
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
               ary_output2.EXTEND(1);
               ary_output2(int_index) := str_check;
               int_index := int_index + 1;
               
            END IF;

         END LOOP;

         --------------------------------------------------------------------------
         -- Step 10
         -- Return the results
         --------------------------------------------------------------------------
         RETURN ary_output2;

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
         RAISE_APPLICATION_ERROR(
             -20001
            ,'Unable to determine dimensionality from gtype'
         );
         
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
         
         FOR i2 IN 1 .. n_points
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
         ,'TM9'
         ,'NLS_NUMERIC_CHARACTERS = ''.,'''
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
         prune_number_varchar2(
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

