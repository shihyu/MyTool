
package Standard is
   
   -- time
   TYPE time IS RANGE ... -- rechnerabh舅gig
   
   -- time units
   UNITS fs;
       ps = 1000 fs;
       ns = 1000 ps;
       us = 1000 ns;
       ms = 1000 us;
       sec = 1000 ms;
       min = 60 sec;
       hr = 60 min;
   END UNITS;
   
   -- Boolean type is represented as enumerated type, False, True
   type boolean is (false,true);
   
   -- bit type, zero on one for value
   type bit is ('0', '1');

   -- raw vector of bits
   type bit_vector IS ARRAY (natural RANGE <>) OF bit;

   -- Integer is elementary ordinal type
   type integer is range;
   
   -- Real is floating point values
   type real is range;
   
   -- Natural numbers are non-negative integers
   subtype natural is integer range 0..integer'HIGH;
   -- Positives are non-negative, non-zero integers
   subtype positive is integer range 1..integer'HIGH;
   
   -- severity level
   TYPE severity_level IS (note, warning, error, failure);

   -- Characters based on 8-bit character set
   type character is 0..FF;
   
   -- String of 8-bit (normal) characters
   type string is array (positive range<>) of character;
   
end Standard;

-- NOT A REAL PACKAGE, used by SlickEdit only!   
package Predefined_Attributes is

    -- base tupe of T
    BASE: integer;
    -- Left bound of T
    LEFT: integer; 
    -- Right bound of T
    RIGHT: integer; 
    -- Lower bound of T
    LOW: integer; 
    -- Upper bound of T
    HIGH: integer; 
    
    -- is the range type an ascending sequence?
    -- RANGE N1 TO N2, not RANGE N2 DOWNTO N1
    ASCENDING: boolean;
    
    -- is the dimension N of array type T ascending?
    function ASCENDING(N: integer): boolean;
    
    -- convert integer value X in enumerated type T to symbol name
    function IMAGE(X: integer) return string;
    
    -- convert symbol name in enumerated type to integer value
    function VALUE(X: string) return integer;
    
    -- Applies to a discrete subtype and returns the position number of 'Arg'
    function POS(N: integer) return integer;
    
    -- Applies to a discrete subtype.  Returns the value of S
    -- with position number 'Arg'.
    function VAL(N: integer) return integer;
   
    -- Value in T which is one position left from X
    function LEFTOF(X: integer) return integer;
    -- Value in T which is one position right from X
    function RIGHTOF(X: integer) return integer;
    -- Value in T which is one position lower than X
    -- For an ascending range, T'leftof(X) = T'pred(X), and T'rightof(X) = T'succ(X).
    -- For a descending range, T'leftof(X) = T'succ(X), and T'rightof(X) = T'pred(X).
    -- Thirdly, for any array type or object A, and N an integer between 1 and
    -- the number of dimensions of A, the following attributes can be used:
    function PRED(X: integer) return integer;
    -- Value in T which is one position higher than X
    -- For an ascending range, T'leftof(X) = T'pred(X), and T'rightof(X) = T'succ(X).
    -- For a descending range, T'leftof(X) = T'succ(X), and T'rightof(X) = T'pred(X).
    -- Thirdly, for any array type or object A, and N an integer between 1 and
    -- the number of dimensions of A, the following attributes can be used:
    function SUCC(X: integer) return integer;
    
    -- Left bound of index range of dim地 N of A
    function LEFT(N: integer) return integer;
    -- Right bound of index range of dim地 N of A
    function RIGHT(N: integer) return integer;
    
    -- Lower bound of index range of dim地 N of A
    function LOW(N: integer) return integer;
    -- Upper bound of index range of dim地 N of A
    function HIGH(N: integer) return integer;
    
    -- Index range of dim地 N of A
    function RANGE(N: integer) return integer;
    -- Reverse of index range of dim地 N of A
    function REVERSE_RANGE(N: integer) return integer;
    
    -- Length of index range of dim地 N of A
    function LENGTH(N: integer) return integer;
    
    -- signal table
    STABLE: boolean;
    -- delayed signal?
    DELAYED: boolean;
    -- quiet?
    QUIET; boolean;
    
    -- signal table
    function STABLE(N: integer) return boolean;
    -- delayed signal?
    function DELAYED(N: integer) return boolean;
    -- quiet?
    function QUIET(N: integer) return boolean;
    
    -- apply to signals
    TRANSACTION: bit;
    EVENT:       boolean;
    ACTIVE:      boolean;
    LAST_EVENT:  integer;
    LAST_ACTIVE: boolean;
    LAST_VALUE:  integer;
    DRIVING: boolean;
    DRIVING_VALUE: integer;
    
    -- block types
    BEHAVIOR: boolean;
    STRUCTURE: boolean;
    
    -- object names
    SIMPLE_NAME, PATH_NAME, INSTANCE_NAME: string;
    
end Predefined_Attributes;

package textio is

    TYPE line IS ACCESS string;
    TYPE text IS FILE OF string;
    TYPE side IS (right, left);
    SUBTYPE width IS natural;
    FILE input : text IS IN "STD_INPUT";
    FILE output : text IS OUT "STD_OUTPUT";
    
    PROCEDURE readline (f : IN text; l : OUT line);
    PROCEDURE writeline (f : OUT text; l : IN line);
    FUNCTION endfile (f : IN text) RETURN boolean;
    
    PROCEDURE read (l : INOUT line; value : OUT bit);
    PROCEDURE read (l : INOUT line; value : OUT bit; good : OUT boolean);
    
    FUNCTION endline (l : IN line) RETURN boolean;
    
    PROCEDURE write (l : INOUT line; value : IN bit;
                     justified : IN side:=right; field : IN width:=0);
    PROCEDURE write (l : INOUT line; value : IN real;
                     justified : IN side:=right; field : IN width:=0;
                     digits : IN natural := 0);
    PROCEDURE write (l : INOUT line; value : IN time;
                     justified : IN side:=right; field : IN width:=0;
                     unit : IN time := ns);
                     
end textio.

package std_logic_1164 is
    TYPE std_ulogic IS ( 'U', -- Uninitialized
                         'X', -- Forcing Unknown
                         '0', -- Forcing 0
                         '1', -- Forcing 1
                         'Z', -- High Impedance
                         'W', -- Weak Unknown
                         'L', -- Weak 0
                         'H', -- Weak 1
                         '-' ); -- Don't care
        
    TYPE std_ulogic_vector IS ARRAY
        ( natural RANGE <> ) OF std_ulogic;
    FUNCTION resolved ( s : std_ulogic_vector )
    RETURN std_ulogic;
    SUBTYPE std_logic IS resolved std_ulogic;
    TYPE std_logic_vector IS ARRAY
        ( natural RANGE <> ) OF std_logic;
    SUBTYPE X01 IS resolved std_ulogic RANGE 'X' TO '1';
    SUBTYPE X01Z IS resolved std_ulogic RANGE 'X' TO 'Z';
    SUBTYPE UX01 IS resolved std_ulogic RANGE 'U' TO '1';
    SUBTYPE UX01Z IS resolved std_ulogic RANGE 'U' TO 'Z';                       
    
    FUNCTION "NAND" ( l : std_ulogic; r : std_ulogic )
        RETURN UX01;
    FUNCTION "NAND" ( l, r : std_logic_vector )
        RETURN std_logic_vector;
    FUNCTION "NAND" ( l, r : std_ulogic_vector )
        RETURN std_ulogic_vector;
        
    FUNCTION xnor ( l : std_ulogic; r : std_ulogic )
        RETURN UX01;
    FUNCTION xnor ( l, r : std_logic_vector )
        RETURN std_logic_vector;
    FUNCTION xnor ( l, r : std_ulogic_vector )
        RETURN std_ulogic_vector;
        
    FUNCTION rising_edge (SIGNAL s : std_ulogic)
        RETURN boolean;
    FUNCTION falling_edge (SIGNAL s : std_ulogic)
        RETURN boolean;
    FUNCTION Is_X ( s : std_ulogic_vector ) RETURN boolean;
    FUNCTION Is_X ( s : std_logic_vector ) RETURN boolean;
    FUNCTION Is_X ( s : std_ulogic ) RETURN boolean;
    
    TYPE stdlogic_1d IS ARRAY (std_ulogic) OF std_ulogic;
    TYPE stdlogic_table IS ARRAY(std_ulogic, std_ulogic) OF std_ulogic;
    
end std_logic_1164;
