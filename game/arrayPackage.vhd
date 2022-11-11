library IEEE;
use IEEE.STD_LOGIC_1164.all;

package arrayPackage is -- Package defining array types
type 	array8x6      is array ( 7 downto 0) of std_logic_vector(  5 downto 0);
type 	array5x8      is array ( 4 downto 0) of std_logic_vector(  7 downto 0);
type 	array6x8      is array ( 5 downto 0) of std_logic_vector(  7 downto 0);
type 	array8x8      is array ( 7 downto 0) of std_logic_vector(  7 downto 0);
type 	array7x9      is array ( 6 downto 0) of std_logic_vector(  8 downto 0);
type 	array8x9      is array ( 7 downto 0) of std_logic_vector(  8 downto 0);
type 	array8x10     is array ( 7 downto 0) of std_logic_vector(  9 downto 0);
type 	array8x16     is array ( 7 downto 0) of std_logic_vector( 15 downto 0);

type 	array3x24     is array ( 2 downto 0) of std_logic_vector( 23 downto 0);

type 	array2x32     is array ( 1 downto 0) of std_logic_vector( 31 downto 0);
type 	array3x32     is array ( 2 downto 0) of std_logic_vector( 31 downto 0);
type 	array4x32     is array ( 3 downto 0) of std_logic_vector( 31 downto 0);
type 	array5x32     is array ( 4 downto 0) of std_logic_vector( 31 downto 0);
type 	array6x32     is array ( 5 downto 0) of std_logic_vector( 31 downto 0);
type 	array8x32     is array ( 7 downto 0) of std_logic_vector( 31 downto 0);
type 	array16x32    is array (15 downto 0) of std_logic_vector( 31 downto 0);
type    array32x8     is array (31 downto 0) of std_logic_vector(  7 downto 0); 
type 	array32x32    is array (31 downto 0) of std_logic_vector( 31 downto 0);

type 	array3x48     is array ( 2 downto 0) of std_logic_vector( 47 downto 0);

type 	array3x64     is array ( 2 downto 0) of std_logic_vector( 63 downto 0);

type    array32x96    is array (31 downto 0) of std_logic_vector( 95 downto 0); 

type 	array3x200    is array ( 2 downto 0) of std_logic_vector(199 downto 0);
type 	array8x256    is array (31 downto 0) of std_logic_vector(255 downto 0);
type 	array32x256   is array (31 downto 0) of std_logic_vector(255 downto 0);
type 	array3x272    is array ( 2 downto 0) of std_logic_vector(271 downto 0);


component DSPProc is 
    Port (  clk  	      : in STD_LOGIC;
            rst           : in STD_LOGIC;
		
            host_memWr    : in  STD_LOGIC;
            host_memAdd   : in  STD_LOGIC_VECTOR(10 downto 0);
            host_datToMem : in  STD_LOGIC_VECTOR(255 downto 0);
            
            datToHost     : out STD_LOGIC_VECTOR(31 downto 0)
          );
end component;

component DSP_top is 
    Port (  clk  	         : in  STD_LOGIC;
            rst              : in  STD_LOGIC;
			
            BRAM_dOut        : in std_logic_vector(255 downto 0);
			reg32x32_dOut	 : in std_logic_vector(31 downto 0);
            reg4x32_CSRA     : in array4x32;
            reg4x32_CSRB     : in array4x32;
			
	        DSP_memWr        : out std_logic; 
	        DSP_memAdd       : out std_logic_vector(7 downto 0); 
		    DSP_datToMem     : out std_logic_vector(31 downto 0);
            DSP_functBus     : out std_logic_vector(95 downto 0)
            );
end component;

 component memory_top is 
    Port (  clk  	      : in  STD_LOGIC;
            rst           : in  STD_LOGIC;
			            			  
	        host_memWr    : in  std_logic;
	        host_memAdd   : in  std_logic_vector(10 downto 0);
		    host_datToMem : in  std_logic_vector(255 downto 0);
			
	        DSP_memWr     : in  std_logic;
	        DSP_memAdd    : in  std_logic_vector(7 downto 0);
		    DSP_datToMem  : in  std_logic_vector(31 downto 0);
		    
		    DSP_functBus  : in  std_logic_vector(95 downto 0);
						  
 	 	    datToHost     : out std_logic_vector(31 downto 0);
						  
			BRAM_dOut     : out std_logic_vector(255 downto 0);
			reg32x32_dOut : out std_logic_vector(31 downto 0);
			reg4x32_CSRA  : out array4x32;
			reg4x32_CSRB  : out array4x32
		 );
end component;

 component decodeMemWr is
    Port ( memWr            : in  std_logic;
	       memAdd	        : in  std_logic_vector(10 downto 0);
           BRAM_we          : out std_logic;
		   reg32x32_we      : out std_logic;
           reg4x32_CSRA_we  : out std_logic;

           host_memWr       : in  std_logic;
           host_memAdd      : in  std_logic_vector(10 downto 0);
           reg4x32_CSRB_we  : out std_logic
          );
end component;

 component selDatToHost is
    Port ( memAdd       	   : in  std_logic_vector( 10 downto 0);
		   reg4x32_CSRA_dOut   : in  std_logic_vector( 31 downto 0);
		   XX_intBRAM32x256_dOut  : in  std_logic_vector(255 downto 0);
		   XX_intReg32x32_dOut : in  std_logic_vector( 31 downto 0);
		   reg4x32_CSRB_dOut   : in  std_logic_vector( 31 downto 0);
		   datToHost           : out std_logic_vector( 31 downto 0)		   
 		 );
end component;

 component reg4x32_CSRA_c is
     Port ( clk       : in std_logic;   
           rst       : in std_logic;
           clr00     : in std_logic;
           ld0       : in std_logic;   
		   
           we        : in std_logic;  
	       add       : in std_logic_vector(1 downto 0);
	       dIn       : in std_logic_vector(31 downto 0);	  

           reg       : out array4x32;
           dOut      : out std_logic_vector(31 downto 0)
           );
end component;

 component BRAM32x256 is
    Port ( clk  : in std_logic;   
           we   : in std_logic;    				       
	       add  : in std_logic_vector(4 downto 0);	  
	       dIn  : in std_logic_vector(255 downto 0);	  
           dOut : out std_logic_vector(255 downto 0)
 		 );
end component;

 component reg32x32 is
    Port ( clk  : in std_logic;   
           rst  : in std_logic;
           ld0  : in std_logic;     
			    
           we   : in std_logic;    				       
	       add  : in std_logic_vector(4 downto 0);	  
	       dIn  : in std_logic_vector(31 downto 0);	  
			    
           reg    : out array32x32;
           dOut : out std_logic_vector(31 downto 0)
 		 );
end component;

 component reg4x32_CSRB_c is
    Port ( clk       : in std_logic;   
           rst       : in std_logic;
           ld0       : in std_logic;   		   
           
           we        : in std_logic;  
	       add       : in std_logic_vector(1 downto 0);
	       dIn3DT1   : in std_logic_vector(95 downto 0);	  
	       dIn       : in std_logic_vector(31 downto 0);	  
	       
           reg       : out array4x32;
           dOut      : out std_logic_vector(31 downto 0)
 		 );
 end component;

 component decodeCmd is 
    Port (clk  	           : in  STD_LOGIC;
          rst              : in  STD_LOGIC;		  
          reg4x32_CSRA_0  : in  std_logic_vector(31 downto 0);
          go               : out std_logic_vector(31 downto 0)
          );	
end component;

 component generateCE is 
    Port (clk  	           : in  STD_LOGIC;
          rst              : in  STD_LOGIC;		  
          enSingleStep     : in  std_logic;
          step             : in  std_logic;
		  ce               : out std_logic
          );	
end component;

component selDSPOutSigs is
    Port ( sel  : in std_logic_vector(4 downto 0); 
		   datToMem : in array32x32;
           add : in array32x8;
           wr : in std_logic_vector(31 downto 0);
           functBus : in array32x96;
	
           DSP_datToMem : out std_logic_vector(31 downto 0);              
           DSP_memAdd   : out std_logic_vector(7 downto 0);                      
           DSP_memWr    : out std_logic;
           DSP_functBus : out std_logic_vector(95 downto 0)
		  );
end component;

component maxMinPixelWord0 is
    Port ( clk 		     : in STD_LOGIC;   
           rst 		     : in STD_LOGIC; 
           ce            : in  std_logic;                		 
           go            : in  std_logic;                		 
		   active        : out std_logic;

		   reg4x32_CSRA  : in array4x32; 
		   reg4x32_CSRB  : in array4x32;	
           BRAM_dOut     : in std_logic_vector(255 downto 0);	
           reg32x32_dOut : in STD_LOGIC_VECTOR(31 downto 0); 
					 
		   wr            : out std_logic;
		   add           : out std_logic_vector(  7 downto 0);					 
		   datToMem	     : out std_logic_vector( 31 downto 0);
		   
		   functBus      : out std_logic_vector( 95 downto 0)
           );
end component;

component maxMinPixel is
    Port ( clk 		     : in STD_LOGIC;   
           rst 		     : in STD_LOGIC; 
           ce            : in  std_logic;                		 
           go            : in  std_logic;                		 
		   active        : out std_logic;

		   reg4x32_CSRA : in array4x32; 
		   reg4x32_CSRB : in array4x32;	
           BRAM_dOut     : in std_logic_vector(255 downto 0);	
           reg32x32_dOut : in STD_LOGIC_VECTOR(31 downto 0); 
					 
		   wr            : out std_logic;
		   add           : out std_logic_vector(  7 downto 0);					 
		   datToMem	     : out std_logic_vector( 31 downto 0);
		   
		   functBus      : out std_logic_vector( 95 downto 0)
           );
end component;

component gameAndReg32x32 is
    Port ( clk 		     : in STD_LOGIC;   
           rst 		     : in STD_LOGIC; 
           ce            : in  std_logic;                		 
           go            : in  std_logic;                		 
		   active        : out std_logic;

		   reg4x32_CSRA  : in array4x32; 
		   reg4x32_CSRB  : in array4x32;	
					 
		   wr            : out std_logic;
		   add           : out std_logic_vector(  7 downto 0);					 
		   datToMem	     : out std_logic_vector( 31 downto 0);

		   functBus      : out std_logic_vector(95 downto 0)
           );
end component;

component game is
    Port ( clk 		     : in STD_LOGIC;   
           rst 		     : in STD_LOGIC; 
           ce            : in  std_logic;                		 
           go            : in  std_logic;                		 
		   active        : out std_logic;

		   reg4x32_CSRA  : in array4x32; 
		   reg4x32_CSRB  : in array4x32;	
           BRAM_dOut     : in std_logic_vector(255 downto 0);	
           reg32x32_dOut : in std_logic_vector(31 downto 0);
					 
		   wr            : out std_logic;
		   add           : out std_logic_vector(  7 downto 0);					 
		   datToMem	     : out std_logic_vector( 31 downto 0);

		   functBus      : out std_logic_vector(95 downto 0)
           );
end component;

--component histogram is
--    Port ( clk 		 : in STD_LOGIC;   
--           rst 		 : in STD_LOGIC;  
--   		   continue  : in  std_logic;
		   
--		   WDTimeout : in std_logic;
--           go        : in  std_logic;                		 
--		   active    : out std_logic;

--		   CSR       : in  array4x32;
--           sourceMem : in  std_logic_vector(255 downto 0); 
					 
--		   memWr     : out std_logic;
--		   memAdd    : out std_logic_vector(  7 downto 0);					 
--		   datToMem	 : out std_logic_vector( 31 downto 0)
--           );
--end component;

--component threshold is
--    Port ( clk 		 : in STD_LOGIC;   
--           rst 		 : in STD_LOGIC;
--  		   continue  : in  std_logic;

--		   WDTimeout : in std_logic;		   
--           go        : in  std_logic;
--		   active    : out std_logic;

--		   CSR       : in  array4x32;
--           sourceMem : in  std_logic_vector(255 downto 0); 
					 
--		   memWr     : out std_logic;
--		   memAdd    : out std_logic_vector(  7 downto 0);					 
--		   datToMem	 : out std_logic_vector( 31 downto 0)
--           );
--end component;

--component sobel is
--    Port ( clk 		 : in STD_LOGIC;   
--           rst 		 : in STD_LOGIC;   
--  		   continue  : in  std_logic;

--		   WDTimeout : in std_logic;		   
--           go        : in  std_logic;
--		   active    : out std_logic;

--		   CSR       : in  array4x32;
--           sourceMem : in  std_logic_vector(255 downto 0); 
					 
--		   memWr     : out std_logic;
--		   memAdd    : out std_logic_vector(  7 downto 0);					 
--		   datToMem	 : out std_logic_vector( 31 downto 0)
--           );
--end component;

--component dataProc1 is
--    Port ( clk 		 : in STD_LOGIC;   
--           rst 		 : in STD_LOGIC; 
--  		   continue  : in  std_logic;
		   
--		   WDTimeout : in std_logic;
--           go        : in  std_logic;                		 
--		   active    : out std_logic;

--		   CSR       : in  array4x32;
--           sourceMem : in  std_logic_vector(255 downto 0); 
					 
--		   memWr     : out std_logic;
--		   memAdd    : out std_logic_vector(  7 downto 0);					 
--		   datToMem	 : out std_logic_vector( 31 downto 0)
--           );
--end component;

--component DSPStub is
--    Port ( clk 		 : in STD_LOGIC;   
--           rst 		 : in STD_LOGIC;   
--  		   continue  : in  std_logic;

--		   WDTimeout : in std_logic;		   
--           go        : in  std_logic;
--		   active    : out std_logic;

--		   CSR       : in  array4x32;
--           sourceMem : in  std_logic_vector(255 downto 0); 
					 
--		   memWr     : out std_logic;
--		   memAdd    : out std_logic_vector(  7 downto 0);					 
--		   datToMem	 : out std_logic_vector( 31 downto 0)
--           );
--end component;

component DSP_selMemMaster is
    Port ( DSP_activeIndex   : in std_logic_vector(5 downto 0); 
           -- 5:0 is viewSourceMemInResultMem, userFunct, sobel, threshold, histogram, maxPixel
           DSP_memWr         : in std_logic_vector(5 downto 0); 
           DSP_memAdd        : in array6x8;                     
           DSP_datToMem      : in array6x32;                     

		   memWr             : out std_logic;
	       memAdd            : out std_logic_vector(7 downto 0);
		   datToMem          : out std_logic_vector(31 downto 0)
           );
end component;

 component selDSPOrHostCtrl is
    Port ( DSPMaster     : in  std_logic;
    
	       host_memWr    : in  std_logic;
	       host_memAdd   : in  std_logic_vector(10 downto 0);
		   host_datToMem : in  std_logic_vector(255 downto 0);
	       
	       DSP_memWr     : in  std_logic;
	       DSP_memAdd    : in  std_logic_vector(7 downto 0);
		   DSP_datToMem  : in  std_logic_vector(31 downto 0);

	       memWr         : out std_logic;
	       memAdd        : out std_logic_vector(10 downto 0);
		   datToMem      : out std_logic_vector(255 downto 0)
           );
end component;

--component CB5CLE is
--    Port ( clk 	   : in STD_LOGIC;   
--           rst 	   : in STD_LOGIC;   
--           loadDat : in std_logic_vector(4 downto 0);
--           load	   : in STD_LOGIC;                
--           ce 	   : in STD_LOGIC;                
--           count   : out std_logic_vector(4 downto 0);
--           TC      : out STD_LOGIC;
--           ceo     : out STD_LOGIC                    
--           );
--end component;

--component CB3CLE is
--    Port ( clk 	   : in STD_LOGIC;   
--           rst 	   : in STD_LOGIC;   
--           loadDat : in std_logic_vector(2 downto 0);
--           load	   : in STD_LOGIC;                
--           ce 	   : in STD_LOGIC;                
--           count   : out std_logic_vector(2 downto 0);
--           TC      : out STD_LOGIC;
--           ceo     : out STD_LOGIC                    
--           );
--end component;

--component CB32CLE is
--    Port ( clk 	   : in STD_LOGIC;   
--           rst 	   : in STD_LOGIC;   
--           loadDat : in std_logic_vector(31 downto 0);
--           load	   : in STD_LOGIC;                
--           ce 	   : in STD_LOGIC;                
--           count   : out std_logic_vector(31 downto 0);
--           TC      : out STD_LOGIC;
--           ceo     : out STD_LOGIC                    
--           );
--end component;

 component singleShot is
Port (clk   : in  std_logic;
      rst   : in  std_logic;
      sw    : in  std_logic; 	
      aShot	: out std_logic  
	  ); 
end component;

--component WDogTimer is 
--    Port (  clk  	        : in STD_LOGIC;
--            rst             : in STD_LOGIC;
--			CSR             : in array4x32; 
--			DSP_activeIndex : in std_logic_vector(5 downto 0);
--			WDTimeout       : out std_logic  
--			);
--end component;


--component memCtrlr is 
--    Port (  memWr        : in std_logic; 
--			memAdd       : in std_logic_vector(7 downto 0); 
--			datToMem     : in std_logic_vector(31 downto 0);

--            userCSRWr    : in std_logic;
--            userCSRAdd   : in std_logic_vector( 1 downto 0);
--            userCSRDatIn : in std_logic_vector(31 downto 0);
			
--			CSRWr        : out std_logic; 
--			CSRAdd       : out std_logic_vector(1 downto 0); 
--			CSRDatIn     : out std_logic_vector(31 downto 0);

--			resultMemWr  : out std_logic
--		  );
--end component;

--component setBitIDOfVec is
--    Port ( clk : in STD_LOGIC;   
--           rst : in STD_LOGIC;   
--           ld0 : in STD_LOGIC;   
--           ce  : in STD_LOGIC;   
--           bitID : in  std_logic_vector( 4 downto 0); 
--		   vec : out std_logic_vector(31 downto 0)
--           );
--end component;

component maxPixel_top is 
    Port (  clk  	      : in  STD_LOGIC;
            rst           : in  STD_LOGIC;
	        WDTimeout     : in std_logic;
			ld0_resultMem : in std_logic;			
			
            go            : in  std_logic;                		 
		    active        : out std_logic;

            userCSRWr     : in std_logic;
            userCSRAdd    : in std_logic_vector( 1 downto 0);
            userCSRDatIn  : in std_logic_vector(31 downto 0)
			);
end component;

--component histogram_top is 
--    Port (  clk  	      : in STD_LOGIC;
--            rst           : in STD_LOGIC;
--	        WDTimeout     : in std_logic; 
--			ld0_resultMem : in std_logic;
			
--            go            : in  std_logic;                		 
--		    active        : out std_logic;

--            userCSRWr     : in std_logic;
--            userCSRAdd    : in std_logic_vector( 1 downto 0);
--            userCSRDatIn  : in std_logic_vector(31 downto 0)
--		  );
--end component;

--component FD8CL0E is
-- Port ( clk : in STD_LOGIC;
--        rst : in STD_LOGIC;           
--        ld0 : in STD_LOGIC;           
--        ce	: in STD_LOGIC;  
--        D	: in STD_LOGIC_VECTOR(7 downto 0);  
--        Q   : out STD_LOGIC_VECTOR(7 downto 0)
--      );
--end component;

--component FD5CL0E is
-- Port ( clk : in STD_LOGIC;
--        rst : in STD_LOGIC;           
--        ld0 : in STD_LOGIC;           
--        ce	: in STD_LOGIC;  
--        D	: in STD_LOGIC_VECTOR(4 downto 0);  
--        Q   : out STD_LOGIC_VECTOR(4 downto 0)
--      );
--end component;
--component FD3CL0E is
-- Port ( clk : in STD_LOGIC;
--        rst : in STD_LOGIC;           
--        ld0 : in STD_LOGIC;           
--        ce	: in STD_LOGIC;  
--        D	: in STD_LOGIC_VECTOR(2 downto 0);  
--        Q   : out STD_LOGIC_VECTOR(2 downto 0)
--      );
--end component;

-- component DSPProc_threshold is 
    -- Port (  clk  	  : in  STD_LOGIC;
            -- rst       : in  STD_LOGIC;
			
            -- host_memWr    : in  STD_LOGIC;
            -- host_memAdd   : in  STD_LOGIC_VECTOR(7 downto 0);
            -- host_datToMem : in  STD_LOGIC_VECTOR(255 downto 0);
            -- hostSelSource32Word : in  STD_LOGIC_VECTOR(2 downto 0);
            
            -- datToHost     : out STD_LOGIC_VECTOR(31 downto 0)
          -- );
-- end component;

-- component selHostMemDatapath is 
    -- Port (  clk  	  : in  STD_LOGIC;
            -- rst       : in  STD_LOGIC;
			
			-- selLdBlk  : in std_logic;
			
			-- blkXLow   : in std_logic_vector(7 downto 0);  
			-- blkXHigh  : in std_logic_vector(7 downto 0);
			-- blkYLow   : in std_logic_vector(4 downto 0); 
			-- blkYHigh  : in std_logic_vector(4 downto 0); 
			
            -- host_memWr    : in  STD_LOGIC;
            -- host_memAdd   : in  STD_LOGIC_VECTOR(7 downto 0);
            -- host_datToMem : in  STD_LOGIC_VECTOR(255 downto 0);
            
            -- memWr    : out  STD_LOGIC;
            -- memAdd   : out  STD_LOGIC_VECTOR(7 downto 0);
            -- datToMem : out  STD_LOGIC_VECTOR(255 downto 0)
		   -- );
-- end component;

-- component DSP_top_threshold is 
    -- Port (  clk  	         : in  STD_LOGIC;
            -- rst              : in  STD_LOGIC;
			
            -- CSR              : in array4x32;
            -- sourceMem        : in std_logic_vector(255 downto 0); 
			
	        -- memWr            : out std_logic; 
	        -- memAdd           : out std_logic_vector(7 downto 0); 
		    -- datToMem         : out std_logic_vector(31 downto 0);
		    -- WDTimeoutOut     : out std_logic
		   -- );
-- end component;

-- component fifo3x272_ld0Word_ldSourceMem is
-- Port ( clk 		                       : in STD_LOGIC;                       
       -- rst 		                       : in STD_LOGIC;                       
       -- ld0	                           : in STD_LOGIC;                       
       -- ld_buffReg3x272_FromSourceMem   : in STD_LOGIC;  
       -- XX_buffReg3x272_FromSourceMem   : in STD_LOGIC_vector(271 downto 0);  
       -- ld_buffReg3x272_Reg0_0          : in STD_LOGIC;  
       -- XX_buffReg3x272                 : out array3x272  					 
     -- );			
-- end component;

-- component SReg3x272_ldFromFifo_shiftLeft8 is
-- Port (clk 		                    : in STD_LOGIC;   
	  -- rst 		                    : in STD_LOGIC;   
	  -- ld0     	                    : in STD_LOGIC;      
	  -- ld_SReg3x272_FromBuffReg3x272 : in STD_LOGIC;  
	  -- XX_buffReg3x272               : in array3x272; 
	  -- enShft8 	                    : in STD_LOGIC;   
	  -- XX_SReg3X272                  : out array3x272
     -- );
-- end component;

-- component userFunct is
   -- Port ( clk 		 : in  std_logic;   
           -- rst 		 : in  std_logic;   
  		   -- continue  : in  std_logic;

		   -- WDTimeout : in std_logic;		   
           -- go        : in  std_logic;
		   -- active    : out std_logic;
		   
		   -- CSR       : in  array4x32;
           -- sourceMem : in  std_logic_vector(255 downto 0); 
					 		   
		   -- -- user controls
		   -- user_clrActive   : in std_logic;		   
   		   -- user_memWr      : in std_logic;
		   -- user_MemAdd     : in std_logic_vector(  7 downto 0);					 
		   -- user_DatToMem   : in std_logic_vector( 31 downto 0);
		   
 		   -- memWr           : out std_logic;
		   -- memAdd          : out std_logic_vector(  7 downto 0);					 
		   -- datToMem	       : out std_logic_vector( 31 downto 0)
           -- );
-- end component;

-- component viewSourceMemInResultMem is
    -- Port ( clk 		 : in STD_LOGIC;   
           -- rst 		 : in STD_LOGIC;   
  		   -- continue  : in  std_logic;

		   -- WDTimeout : in std_logic;		   
           -- go        : in  std_logic;
		   -- active    : out std_logic;

		   -- CSR       : in  array4x32; 
           -- sourceMem : in  std_logic_vector(255 downto 0); 

		   -- -- user controls
		   -- user_clrActive  : in std_logic;		   
		   -- user_32BitCol   : in std_logic_vector(  2 downto 0);					 
					 
		   -- memWr     : out std_logic;
		   -- memAdd    : out std_logic_vector(  7 downto 0);					 
		   -- datToMem	 : out std_logic_vector( 31 downto 0)
           -- );
-- end component;

-- component CB0To7CLEInteger is
    -- Port ( clk 		: in STD_LOGIC;   
           -- rst 		: in STD_LOGIC;   
           -- loadDat	: in integer range 0 to 7; 
           -- load		: in STD_LOGIC;                
           -- ce 		: in STD_LOGIC;                
           -- count	: out integer range 0 to 7;
           -- TC       : out STD_LOGIC;
           -- ceo      : out STD_LOGIC                    
           -- );
-- end component;

-- component CB0To31CLEInteger is
    -- Port ( clk 		: in STD_LOGIC;   
           -- rst 		: in STD_LOGIC;   
           -- loadDat	: in integer range 0 to 31; 
           -- load		: in STD_LOGIC;                
           -- ce 		: in STD_LOGIC;                
           -- count	: out integer range 0 to 31;
           -- TC       : out STD_LOGIC;
           -- ceo      : out STD_LOGIC                    
           -- );
-- end component;

-- component DSP_functionTimer is 
    -- Port (  clk  	   : in STD_LOGIC;
            -- rst        : in STD_LOGIC;
			-- CSR3       : in std_logic_vector(31 downto 0);
			-- DSP_activeIndex : in std_logic_vector(5 downto 0);
			-- WDTimeout  : out std_logic
			-- );
-- end component;

-- component threshold_top is 
    -- Port (  clk  	         : in  STD_LOGIC;
            -- rst              : in  STD_LOGIC;
	        -- WDTimeout        : in std_logic;
			-- ld0_resultMem	 : in std_logic;		
			
            -- go               : in  std_logic;                		 
		    -- active           : out std_logic;

            -- userCSRWr        : in std_logic;
            -- userCSRAdd       : in std_logic_vector( 1 downto 0);
            -- userCSRDatIn     : in std_logic_vector(31 downto 0)
		  -- );
-- end component;

end 	arrayPackage;

package body arrayPackage is

end arrayPackage;
