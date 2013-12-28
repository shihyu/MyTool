package Standard is
   pragma Pure(Standard);
   
   -- Boolean type is represented as enumerated type, False, True
   type Boolean is (False,True);
   
   -- Integer is elementary ordinal type
   type Integer is range;
   
   -- Natural numbers are non-negative integers
   subtype Natural is Integer range 0..IntegerLast;
   -- Positives are non-negative, non-zero integers
   subtype Positive is Integer range 1..Integer'Last;
   
   -- Floating point is elementary rational
   type Float is digits;
   
   -- Characters based on 8-bit character set
   type Character is 0..FF;
   
   -- Characters based on wide character set
   type Wide_Character is 0..FFFF;
   
   -- String of 8-bit (normal) characters
   type String is array (Positive range<>) of Character;
   pragma Pack(String);
   
   -- String of wide characters
   type Wide_String is Array(Positive range<>) of Wide_Character;
   pragma Pack(Wide_String);
   
   -- Time duration
   type Duration is delta range;
   
   -- Standard exception types
   Constraint_Error, Program_Error, Storage_Error, Tasking_Error: exception;

end Standard;

-- ISO 646 character set
package ASCII is
end ASCII;

-- NOT A REAL PACKAGE, used by SlickEdit only!   
package Predefined_Attributes is
   pragma Pure(Predefined_Attributes);
   
   -- Applies to an object or subprogram.
   -- Yields an access value designating the entity.
   Access: access T;
   
   -- Applies to an object, program unit or label.
   -- Denotes the address of the first storage element
   -- associated with the entity.  Of type System.Address.
   Address: System.Address;
   
   -- Applies to a floating point subtype S of a type T.
   -- Returns the machine number adjacent to 'x' in the direction 'towards'.
   function Adjacent(x,towards: T) return T;
   
   -- Applies to a fixed point subtype.
   -- Yields the number of decimal digits needed after the point
   -- to accommodate the subtype S, unless the delta of the subtype
   -- is greater than 0.1, in which case it yields the value one.
   -- (S'Aft is the smallest positive integer N for which
   -- (10**N)*S'Delta >= 1.
   Aft: Integer;
   
   -- Applies to a subtype or object.
   -- The Address of an object is an integer multiple of this attribute.
   Alignment: Integer;
   
   -- Appies to a subtype S and denotes an unconstrained subtype of its type.
   Base: subtype;
   
   -- Applies to a record subtype and denotes the bit ordering.
   Bit_Order: System.Bit_Order;
   
   -- Applies to a program unit and returns a String (Distributed)
   Body_Version: System.String;
   
   -- Applies to a task.  Yields true unless the task is completed,
   -- terminated, or abnormal.
   Callable: System.Boolean;
   
   -- Applies to an entry.  Yields the identity of the task calling the
   -- entry body or accept statement.
   Caller: Task_Identification.Task_ID;
   
   -- Applies to a floating point subtype S of a type T.
   -- Returns the algebraically smallest integral value not less than X.
   function Ceiling(X: T) return T;
   
   -- Applies to a tagged subtype.  Denotes its class wide type.
   Class: T;
   
   -- Applies to an array subtype or object.  Denotes the size in
   -- bits of components of this type.
   Component_Size: Integer;
   
   -- Applies toa floating point subtype S of a type T.
   -- Returns 'Fraction' but with its exponent replaced by 'Exponent'
   function Compose(Fraction: T; Exponent: Integer) return T;
   
   -- Applies to an object of a discrimated type.  Yields true if 'A'
   -- is a constant or is constrained.
   Constrained: Boolean;
   
   -- Applies to a floating point subtype S of a type T.
   -- Returns the magnitude of Value with the sign of Sign.
   function Copy_Sign(Value,Sign: T) return T;
   
   -- Applies to an entry.  Yields the number of tasks queued on the entry.
   Count: Integer;
   
   -- Applies to a formal indefinite subtype.  Yields true if the actual
   -- subtype is definite.
   Definite: Boolean;
   
   -- Appies to a fixed point subtype.  Yields the value of the delta
   -- of the subtype.
   Delta: Real:
   
   -- Applies to a floating point subtype.  Yields true if every
   -- denormalized number is a machine number.
   Denorm: Boolean;
   
   -- Applies to afloating point or decimal subtype.  Yields the requested
   -- number of decimal digits.
   Digits: Integer;
   
   -- Applies to a floating point subtype S of a type T and 
   -- returns the normalized exponent of X.
   function Exponent(X:T) return T; 
   
   -- Applies to a tagged subtype.  Yields an external representation
   -- of the tag.
   External_Tag: String;
   
   -- Applies to an array object, constrained subtype, or scalar subtype.
   -- Denotes the lower bound of the range.  Of the type bound.
   First: Integer;
   
   -- Applies to a componetn C of a composite, non-array object R.
   -- Yields the offset, measured in bits, from the start of the
   -- first of the storage elements occupied by C, of the first bit
   -- occupied by C.
   First_Bit: Integer;
   
   -- Applies to a floating point subtype S of a type T and returns
   -- the algebraically largest integral value not greater than X.
   function Floor(X:T) return T; 
   
   -- Applies to a fixed point subtype.  Yields the minimum number of
   -- characters needed before the decimal point for the decimal
   -- representation of any value of the subtype S, assuming that the
   -- representation does not include an exponent, but includes a one
   -- character prefix that is either a minus sign or a space.
   -- This minimum number does not include superfuous zeros or underlines;
   -- and is at least two.
   Fore: Integer;
   
   -- Applies toa floating point subtype S of a type T.
   -- Returns the number X with exponent replaced by zero.
   function Fraction(X: T) return T;
   
   -- Applies to an exception.  Yields the identity of the exception.
   Identity: Exceptions.Exception_ID;
   
   -- Applies to a task.  Yields the identiy of a task.
   Identity: Task_Identification.Task_ID;
   
   -- Applies to a scalar subtype. 
   -- The result is the image of the value of 'arg', that is, a sequence
   -- of characters representing the value in display form.  The image of
   -- an integer value is the coresponding decimal literal; without
   -- underlines, leading zeroes, exponent, or trailing spaces; but with
   -- a one character prefix that is either a minus sign or a space.
   -- The image if a real value is as for the corresponding Put with
   -- default format.  The image of an inumeration value is either the
   -- corresponding identifier in upper case or the corresponding
   -- character literal (including the two apostrophes); neither leading
   -- nor trailing spaces are included.  The image of a nongraphic
   -- character is the corresponding name in upper case, such as NUL.
   function Image(Arg: S'Base) return String;
   
   -- Applies to a subtype S of a type T (specific or class-wide).
   -- Reads and returns one value from the stream.
   function Input(Stream: access Ada.Streams.Root_Stream_Type'Class) return T;
   
   -- Applies to an array object, constrained subtype, or scalar subtype.
   -- Denotes the upper bound of the range.  Of the type bound.
   Last: Integer;
   
   -- Applies to a component C of a composite, non-array object R.
   -- Yields the offset, in bits, from the start of the first storage
   -- element occupied by C, of the last bit occupied by C.
   Last_Bit: Integer;
   
   -- Applies to a floating oint subtype S of a type T.
   -- Returns X but with all except the first D digits
   -- in the mantissa set to zero.
   function Leading_Part(X: T; D: integer): return T;
   
   -- Applies to an array object or constrained subtype.  Denotes the
   -- number of values of range (zero for a null range).
   Length: Integer;
   
   -- Applies to a floating point subtype S of a type T.  Returns X if
   -- it is a machine number and otherwise one adjacent to X.
   function Machine(X: T) return T; 
   
   -- Applies to a floating point subtype.  Yields the largest value
   -- of exponent in the canonical representation for which all numbers
   -- are machine numbers.
   Machine_Emax: Integer;
   
   -- Applies to a floating point subtype.  Yields the smallest value
   -- of exponent in the canonical representation for which all numbers
   -- are machine numbers.
   Machine_Emax: Integer;
   
   -- Applies to a floating point subtype.  Yields the largest value
   -- of digits in the mantissa in the canonical representation for
   -- which all numbers are machine numbers.
   Machine_Mantissa: Integer;
   
   -- Applies to a floating or fixed point subtype.  Yields true if 
   -- overflow and divide by zero raise Contraint_Error for every
   -- predefined operation return a value of the base type of S.
   Machine_Overflow: Boolean;
   
   -- Applies to a floating or fixed point type.  Yields the radix
   -- used by the machine representation of the base type of S.
   Machine_Radix: Integer;
   
   -- Applies to a floating or fixed point subtype.  Yields true if 
   -- rounding is performed on inexact results of every predefined
   -- arithmetic operation returning a value of the base type of S.
   Machine_Round: Boolean;
   
   -- Applies to a scalar type and returns the greater of the parameters.
   function Max(Left, Right: Base) return Base;
   
   -- Applies to any subtype.  Denotes the maximum value for
   -- Size_In_Storage_Elements that will be requested by Allocate
   -- for an access type designating the subtype S.
   Max_Size_In_Storage_Elements: Integer;
   
   -- Applies to a scalar type and returns the lesser of the parameters.
   function Min(Left, Right: Base) return Base;
   
   -- Applies to a floating point subtype S of a type T.
   -- Returns X if it is a model number and otherwise one adjacent to X.
   -- This attribute and Model_Emin, Model_Epsilon, Model_Mantissa, and
   -- Model_Small concern the floating point model.
   function Model(X: T) return T;
   
   -- Applies to a floating point subtype S of a type T.
   -- Model_Emin >= Machine_Emin
   Model_Emin: constant;
   
   -- Applies to a floating point subtype S of a type T.
   -- Denotes the measure of accuracy and is typically the difference
   -- between one and the next number above one.
   Model_Epsilon: constant;
   
   -- Applies to a floating point subtype S of a type T.
   -- 1+D.log(radix)10 <= Model_Mantissa <= Machine_Mantissa
   Model_Mantissa: constant;
   
   -- Applies to a floating point subtype S of a type T.
   -- Denotes the smallest positive number.
   Model_Small: constant;
   
   -- Applies to a modular subtype.  Yields its modulus.
   Modulus: Integer;
   
   -- Applies to a subtype S of a specific or class-wide type T.
   -- Writes the value of 'item' to the stream including bounds and
   -- descriminants, and external tags, as appropriate.
   procedure Output(Stream: access Ada.Streams.Root_Stream_Type'Class; Item: in T);

   -- Applies to a library level declaration (not pure).  Denotes the
   -- partition in which the entity was elaborated.
   Partition_ID: Integer;
   
   -- Applies to a discrete subtype and returns the position number of 'Arg'
   function Pos(Arg: Base) return Integer;
   
   -- Applies to a component C of a composite, non-array object R.
   -- Yields R.C'Address - R'Address.
   Position: Integer;
   
   -- Applies to a scalar subtype.  For a discrete subtype, returns the
   -- value whose position number is one less than that of 'Arg'.  For a
   -- fixed type, returns teh result of subtracting small from 'Arg';
   -- for a floating type returns the macine number below 'Arg'.  The
   -- exception Constraint_Error is raised if appropriate.
   function Pred(Arg: Base) return Base;
   
   -- Applies to an array object, constrained subtype, or sclar subtype.
   -- Is equivelent to First(N)..Last(N).
   Range: range;
   
   -- Applies to a subtype S of a specific or class-wide type T.
   -- Reads the value of 'Item' from the stream.  For tagged types,
   -- dispatches the Read attribute according to the tag of the item.
   procedure Read(Stream: access Ada.Streams.Root_Stream_Type'Class; Item: out T);
   
   -- Applies to a floating point subtype S of a type T and returns
   -- V=X-nY where 'n' is the integer nearest to X/Y.  (n is even if midway).
   function Remainder(X,Y: T) return T;
   
   -- Applies to a decimal fixed oint subtype and returns the value
   -- obtained by rounding X (away from zero if X is midway between
   -- the values of Base).
   function Round(X: real) return T;
   
   -- Applies to a floating point subtype S of a type T and returns the
   -- integral value obtained by rounding X (away from zero for
   -- exact halves).
   function Rounding(X: T) return T;
   
   -- Applies to a floating point subtype S of a type T.  Yields the
   -- lower bound of the safe range of T.
   Safe_First: Real;
   
   -- Applies to a floating point subtype S of a type T.  Yields the
   -- upper bound of the safe range of T.
   Safe_Last: Real;
   
   -- Applies to a decimal fixed point subtype.  Yields N such that
   -- S'Delta - 10.00**(-N).
   Scale: Integer;
   
   -- Applies to a flaoting point subtype S of a type T.
   -- Returns X but with its exponent increased by Adjustment.
   function Scaling(X: T; Adjustment: Integer) return T;
   
   -- Applies to a floating point subtype S of a type T.
   -- Returns true if the hardware representation of T supports
   -- signed zeros.
   Signed_Zeros: Boolean;
   
   -- Applies to any subtype or object.  For a definite subtype
   -- gives the size in bits of a packed record component of the
   -- subtype; for an indefinite subtype is implementation defined.
   Size: Integer;
   
   -- Applies to a fixed point subtype.  Denotes its small.
   Small: Real;
   
   -- Applies to an access subtype.  Denotes its storage pool.
   Storage_Pool: System.Storage_Pools.Root_Storage_Pool'Class;
   
   -- Applies to an access subtype or task.  Yields a measure
   -- of the number of storage elements reserved for its pool.
   Storage_Size: Integer;
   
   -- Applies to a scalar subtype.  For a discrete subtype, returns
   -- the value whose position number is one more than that of 'Arg'
   -- For a fixed type, returns the result of adding small to 'Arg'
   -- for a floating type returns the macine number above Arg.
   -- The exception Constraint_Error is raised if appropriate.
   function Succ(Arg: Base) return Base;
   
   -- Applies to a subtype S of a tagged type T or a class-wide type.
   -- Returns the tag of T.
   Tag: Ada.Tags.Tag;
   
   -- Applies to a task.  Yields true if the task is terminated.
   Terminated: Boolean;
   
   -- Applies to a floating point subtype S of type T.
   -- Returns the integral value obtained by truncation towards zero.
   function Truncation(X: T) return T;
   
   -- Applies toa floating point subtype S of a type T.
   -- Returns the integral value nearest to X choosing the even value
   -- if X is an exact half.
   function Unbiased_Rounding(X: T) return T;
   
   -- Applies to an aliased view of an object.  Af for X'Access
   -- but as if X were at the library level.
   Unchecked_Access: access T;
   
   -- Applies to a discrete subtype.  Returns the value of S
   -- with position number 'Arg'.
   function Val(Arg: Integer) return Base;
   
   -- Applies to a scalar object.  Yields true if X is normal
   -- and has a valid representation.
   Valid: Boolean;
   
   -- Applies to a scalar subtype.  Returns the value corresponding
   -- to the given image, ingoring any leading or trailing spaces.
   function Value(Arg: String) return Base;
   
   -- Applies to a program unit and returns a string.
   Version: String;
   
   -- Applies to a scalar subtype.
   -- The result is the image of the value of 'arg', that is, a sequence
   -- of characters representing the value in display form.  The image of
   -- an integer value is the coresponding decimal literal; without
   -- underlines, leading zeroes, exponent, or trailing spaces; but with
   -- a one character prefix that is either a minus sign or a space.
   -- The image if a real value is as for the corresponding Put with
   -- default format.  The image of an inumeration value is either the
   -- corresponding identifier in upper case or the corresponding
   -- character literal (including the two apostrophes); neither leading
   -- nor trailing spaces are included.  The image of a nongraphic
   -- character is the corresponding name in upper case, such as NUL.
   function Image(Arg: S'Base) return String;
   
   -- Applies to a scalar subtype.  Returns the value corresponding
   -- to the given image, ingoring any leading or trailing spaces.
   function Wide_Value(Arg: Wide_String) return Base;
   
   -- Applies to a scalar subtype.  Yields the length of a String
   -- returned by S'Image over all values of the subtype.
   Wide_Width: Integer;
   
   -- Applies to a scalar subtype.  Yields the length of a String
   -- returned by S'Image over all values of the subtype.
   Width: Integer;
   
   -- Applies to a subtype S' of a specific or class-wide type T.
   -- Writes the value of 'Item' to the stream.  For tagged types,
   -- dispatches the Write attribute according to the tag of the item.
   procedure Write(Stream: access Ada.Streams.Root_Stream_Type'Class; Item: in T);
   
end Predefined_Attributes;
