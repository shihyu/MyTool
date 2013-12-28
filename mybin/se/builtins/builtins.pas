unit System;

interface

   // returns an absolute value
   function abs(X: number): number;
   // abort program execution
   procedure Abort;
   // returns the address of X
   function addr(X): pointer;
   // Append prepares an existing file for adding text to the end
   procedure Append(var F: text);
   // calculates the arctangent of the given number
   procedure ArcTan(X: extended):extended;
   // tests whether a boolean expression is successful
   procedure Assert(expr: Boolean ;const msg:string='');
   // tests for a nil (unassigned) pointer or procedure variable
   function Assigned(var P): Boolean;
   // associates the name of an external file with a file variable
   procedure AssignFile(var F; filename: string);
   // reads one or more records from an open file into a variable
   procedure BlockRead(var F: file; var Buf; Count: integer; var AmtTransferred: Integer=0);
   // writes one or more records froma variable to an open file
   procedure BlockWrite(var F: file; var Buf; Count: integer; var AmtTransferred: Integer=0);
   // changes the current directory
   procedure ChDir(S: string);
   // returns the character for a specified ASCII value
   function Chr(X: byte): Char;
   // terminates the association between file variable and an external file
   procedure Close(var F);
   // terminates the association between file variable and an external disk file
   procedure CloseFile(var F);
   // Concatenates two or more strings into one
   function Concat(s1, s2, ...: string): string;
   // returns a substring of a string
   function Copy(s: string; index,count: integer): string;
   // calculates the cosine of an angle
   function Cos(X: extended): extended;
   // decrements a variable by 1 or N
   procedure Dec(var X; n: integer=1);
   // removes a substring from a string
   procedure Delete(var S: string; Index,count: integer);
   // releases memory allocated for a dynamic variable
   procedure Dispose(var P: pointer);
   // tests whether the file position is at the end of file
   function Eof(var f: text=input): boolean;
   // tests whether the file position is at the end of line
   function Eoln(var f: text=input): boolean;
   // deletes an external file
   procedure Erase(var f);
   // removes an element from a set
   procedure exclude(var s: set of T; i:T);
   // exits from the current procedure
   procedure Exit;
   // returns the exponential of X
   function Exp(x: real): real;
   // returns the current file position
   function FilePos(var F): longint;
   // returns the size of a file in bytes or the number of records in a record file
   function FileSize(var f): integer;
   // fills contiguous bytes with a specified value
   procedure fillchar(var x; cout: integer; value: byte);
   // unitializes a dynamically allocated variable
   procedure Finalize(var V; Count: integer=1);
   // empties the buffer of a text file for opened for output
   procedure Flush(var f: text);
   // multiplies the value by a specified power of 10
   function fpower10(val: extended; pow: integer): extended;
   // returns the fractional part of a real number
   function frac(x: extended): extended;
   // disposes of a dynamic variable of a given size
   procedure FreeMem(var P: pointer; size:Integer=default);
   // returns the current directory for a specified drive
   procedure GetDir(d: byte; var s: string);
   procedure GetDir(var s: string);
   // creates a dynamic variable and pointer to the address of the block
   procedure GetMem(var P: pointer; size: integer);
   // initiates abnormal termination of a program
   procedure Halt(Exitcode: integer=0);
   // returns the High-order byte of X as an unsigned value.
   function Hi(X): Byte;
   // returns the highest value in the range of an argument
   function High(X: T): T;
   // increments a variable by 1 or N
   procedure Inc(var X; n: integer=1);
   // adds an element to a set
   procedure Include(var s: set of T; i:T);
   // initializes a dynamically allocated variable
   procedure Initialize(var V; count : integer=1);
   // inserts a substring into a string beginning at a specified point
   procedure Insert(Source: string; var s: string; Index: integer);
   // returns the integer part of a real number
   function Int(X: extended): extended;
   // returns the status of the last I/O operation performed
   function IOResult: integer;
   // returns the number of characters used in a string
   function Length(s: string): integer;
   // returns the natural log of a real expression
   function Ln(X: real): real;
   // returns the low order Byte of argument X
   function Lo(X): Byte;
   // returns the lowest value in the range of an argument
   function Low(X:T): T;
   // creates a new subdirectory
   procedure MkDir(s: string);
   // copies bytes fro a source to a destination.
   procedure Move(const Source; var Dest; Count: integer);
   // creates a new dynamic variable and sets P to point to it
   procedure New(var P: pointer);
   // returns True if argument is an odd number
   function Odd(X: longint): boolean;
   // returns the ordinal value of an ordinal-type expression
   function ord(X): integer;
   // returns the value of Pi (3.1459...)
   function Pi: extended;
   // returns the index value of the first character in a substring
   function Pos(substr: string; s: string): integer;
   // returns the predecessor of the argument
   function pred(i: T): T;
   // converts a specified address to a pointer
   function Ptr(address: integer): pointer;
   // generates random numbers within a specified range
   function Random(Range: integer=1): real;
   // initializes the random number generator with a random value
   procedure Randomize;
   // reads data from a file
   procedure Read(var f: text; var v1, v2, etc);
   procedure Read(var v1, v2, etc);
   // read a line of data from a file
   procedure ReadLn(var f: text; var v1, v2, etc);
   procedure ReadLn(var v1, v2, etc);
   // Reallocates a dynamic variable
   procedure ReallocMem(var P: pointer; size: integer);
   // changes the name of an external file
   procedure Rename(var f; newname: string);
   // changes a file name identified by oldname
   function RenameFile(const OldName,NewName: string): boolean;
   // opens an existing file
   procedure Reset(var f: File; RecSize: word=0);
   // creates a new file and opens it
   procedure Rewrite(var f: File; RecSize: word=0);
   // deletes an empty subdirectory
   procedure RmDir(S: string);
   // returns the value of X rounded to the nearest whole number
   function Round(X: extended): longint;
   // stops the execution and generates a run-time error
   procedure RunError(Errorcode: byte=0);
   // moves the current position of a file to a specified component
   procedure Seek(var F; N: longint);
   // returns the end-of-file status of a file
   function SeekEof(var f: text=input): boolean;
   // returns the end-of-line status of a file
   function SeekEoln(var f: text=input): boolean;
   // sets the dynamic length of a string variable
   procedure setLength(var s: string; newLength: integer);
   // sets the contents and length of the given string
   procedure setString(var s: string; buffer: PChar; len: integer);
   // assigns an I/O buffer to a text file
   procedure SetTextBuf(var f: Text; var Buf; size: integer);
   // returns the sine of the angle in radians
   function Sin(X: extended): extended;
   // returns the number of bytes occupied by X
   function SizeOf(X): integer;
   // returns a sub-section of an array
   function Slice(var a: array; count: integer);
   // returns the square of a number
   function Sqr(X: extended): Extended;
   // returns the square root of a number
   function Sqrt(X: extended): Extended;
   // formats a string and returns it to a variable
   procedure Str(X; width, decimals: integer; var s);
   // returns a string with the specified number of characters
   function StringOfChar(Ch: char; Count: integer): string;
   // return the successor of the argument
   function Succ(X: T): T;
   // exchanged the high order byte with the low order byte of an integer or word
   function Swap(X): word;
   // truncates a real number to an integer
   function Trunc(X: extended): Longint;
   // deletes all the records after the current file position
   procedure Truncate(var F);
   // returns a pointer toa compiler-generated run-time type information for a type
   function TypeInfo(TypeIdent): pointer;
   // converts a character to uppercase
   function UpCase(Ch: Char): char;
   // returns a string in uppercase
   function UpperCase(const S: string): string;
   // converts a string to a numeric representation
   procedure Val(S; var V; var Code: integer);
   // resizes a variant array
   procedure VarArrayRedim(var a: variant; highbound: integer);
   // converts a varient to a specified type storing the result in a variable
   procedure VarCast(var Dest: Variant; const Source: variant; varType: integer);
   // clears the given variant
   procedure VarClear(var V: Variant);
   // copies a variant
   procedure VarCopy(var Dest: variant; const Source: variant);
   // writes to a text file
   procedure Write(var F: text; p1, p2, etc);
   procedure Write(p1, p2, etc);
   // writes data and an end-of-line marker to a text file
   procedure WriteLn(var F: text; p1, p2, etc);
   procedure WriteLn(p1, p2, etc);

begin
end.
