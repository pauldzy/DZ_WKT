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
      
      sdo_output := SDO_UTIL.APPEND(
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
                p_input        => SDO_UTIL.EXTRACT(sdo_input,i)
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
                p_input        => SDO_UTIL.EXTRACT(sdo_input,i)
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
