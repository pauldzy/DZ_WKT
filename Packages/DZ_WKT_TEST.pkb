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
      RETURN '{'
      || ' "GITRELEASE":"'    || C_GITRELEASE    || '"'
      || ',"GITCOMMIT":"'     || C_GITCOMMIT     || '"'
      || ',"GITCOMMITDATE":"' || C_GITCOMMITDATE || '"'
      || ',"GITCOMMITAUTH":"' || C_GITCOMMITAUTH || '"'
      || '}';
      
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

