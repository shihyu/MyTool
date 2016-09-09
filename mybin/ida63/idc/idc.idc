/*
 *      This file contains IDA built-in function declarations
 *      and internal bit definitions.
 *      Each byte of the program has 32-bit flags
 *      (low 8 bits keep the byte value).
 *      These 32 bits are used in GetFlags/SetFlags functions.
 *      You may freely examine these bits using GetFlags()
 *      but I strongly discourage using SetFlags() function.
 *
 *      This file is subject to change without any notice.
 *      Future versions of IDA may use other definitions.
 */

#ifndef _IDC_IDC
#define _IDC_IDC

// ----------------------------------------------------------------------------
#define BADADDR         -1                 // Not allowed address value
#define BADSEL          -1                 // Not allowed selector value/number

#ifdef __EA64__
#define MAXADDR         0xFF00000000000000 // Max allowed address in IDA
#else
#define MAXADDR         0xFF000000
#endif

//
//      Flag bit definitions (for GetFlags())
//

#define MS_VAL  0x000000FFL             // Mask for byte value
#define FF_IVL  0x00000100L             // Byte has value ?


// Do flags contain byte value? (i.e. has the byte a value?)
// if not, the byte is uninitialized.

#define hasValue(F)     ((F & FF_IVL) != 0)     // any defined value?


// Get byte value from flags
// Get value of byte provided that the byte is initialized.
// This macro works ok only for 8-bit byte machines.

#define byteValue(F)    (F & MS_VAL)    // quick replacement for Byte()


// Is the byte initialized?

#define isLoaded(ea)    hasValue(GetFlags(ea))  // any defined value?

#define MS_CLS  0x00000600L             // Mask for typing
#define FF_CODE 0x00000600L             // Code ?
#define FF_DATA 0x00000400L             // Data ?
#define FF_TAIL 0x00000200L             // Tail ?
#define FF_UNK  0x00000000L             // Unknown ?


#define isCode(F)       ((F & MS_CLS) == FF_CODE) // is code byte?
#define isData(F)       ((F & MS_CLS) == FF_DATA) // is data byte?
#define isTail(F)       ((F & MS_CLS) == FF_TAIL) // is tail byte?
#define isUnknown(F)    ((F & MS_CLS) == FF_UNK)  // is unexplored byte?
#define isHead(F)       ((F & FF_DATA) != 0)      // is start of code/data?

//
//      Common bits
//

#define MS_COMM 0x000FF800L             // Mask of common bits
#define FF_COMM 0x00000800L             // Has comment?
#define FF_REF  0x00001000L             // has references?
#define FF_LINE 0x00002000L             // Has next or prev cmt lines ?
#define FF_NAME 0x00004000L             // Has user-defined name ?
#define FF_LABL 0x00008000L             // Has dummy name?
#define FF_FLOW 0x00010000L             // Exec flow from prev instruction?
#define FF_SIGN 0x00020000L             // Inverted sign of operands
#define FF_BNOT 0x00040000L             // Bitwise negation of operands
#define FF_VAR  0x00080000L             // Is byte variable ?
#define FF_ANYNAME      (FF_LABL|FF_NAME)

#define isFlow(F)       ((F & FF_FLOW) != 0)
#define isVar(F)        ((F & FF_VAR ) != 0)
#define isExtra(F)      ((F & FF_LINE) != 0)
#define isRef(F)        ((F & FF_REF)  != 0)
#define hasName(F)      ((F & FF_NAME) != 0)
#define hasUserName(F)  ((F & FF_ANYNAME) == FF_NAME)

#define MS_0TYPE 0x00F00000L            // Mask for 1st arg typing
#define FF_0VOID 0x00000000L            // Void (unknown)?
#define FF_0NUMH 0x00100000L            // Hexadecimal number?
#define FF_0NUMD 0x00200000L            // Decimal number?
#define FF_0CHAR 0x00300000L            // Char ('x')?
#define FF_0SEG  0x00400000L            // Segment?
#define FF_0OFF  0x00500000L            // Offset?
#define FF_0NUMB 0x00600000L            // Binary number?
#define FF_0NUMO 0x00700000L            // Octal number?
#define FF_0ENUM 0x00800000L            // Enumeration?
#define FF_0FOP  0x00900000L            // Forced operand?
#define FF_0STRO 0x00A00000L            // Struct offset?
#define FF_0STK  0x00B00000L            // Stack variable?
#define FF_0FLT  0x00C00000L            // Floating point number?
#define FF_0CUST 0x00D00000L            // Custom format type?

#define MS_1TYPE 0x0F000000L            // Mask for 2nd arg typing
#define FF_1VOID 0x00000000L            // Void (unknown)?
#define FF_1NUMH 0x01000000L            // Hexadecimal number?
#define FF_1NUMD 0x02000000L            // Decimal number?
#define FF_1CHAR 0x03000000L            // Char ('x')?
#define FF_1SEG  0x04000000L            // Segment?
#define FF_1OFF  0x05000000L            // Offset?
#define FF_1NUMB 0x06000000L            // Binary number?
#define FF_1NUMO 0x07000000L            // Octal number?
#define FF_1ENUM 0x08000000L            // Enumeration?
#define FF_1FOP  0x09000000L            // Forced operand?
#define FF_1STRO 0x0A000000L            // Struct offset?
#define FF_1STK  0x0B000000L            // Stack variable?
#define FF_1FLT  0x0C000000L            // Floating point number?
#define FF_1CUST 0x0D000000L            // Custom format type?

// The following macros answer questions like
//   'is the 1st (or 2nd) operand of instruction or data of the given type'?
// Please note that data items use only the 1st operand type (is...0)

#define isDefArg0(F)    ((F & MS_0TYPE) != FF_0VOID)
#define isDefArg1(F)    ((F & MS_1TYPE) != FF_1VOID)
#define isDec0(F)       ((F & MS_0TYPE) == FF_0NUMD)
#define isDec1(F)       ((F & MS_1TYPE) == FF_1NUMD)
#define isHex0(F)       ((F & MS_0TYPE) == FF_0NUMH)
#define isHex1(F)       ((F & MS_1TYPE) == FF_1NUMH)
#define isOct0(F)       ((F & MS_0TYPE) == FF_0NUMO)
#define isOct1(F)       ((F & MS_1TYPE) == FF_1NUMO)
#define isBin0(F)       ((F & MS_0TYPE) == FF_0NUMB)
#define isBin1(F)       ((F & MS_1TYPE) == FF_1NUMB)
#define isOff0(F)       ((F & MS_0TYPE) == FF_0OFF)
#define isOff1(F)       ((F & MS_1TYPE) == FF_1OFF)
#define isChar0(F)      ((F & MS_0TYPE) == FF_0CHAR)
#define isChar1(F)      ((F & MS_1TYPE) == FF_1CHAR)
#define isSeg0(F)       ((F & MS_0TYPE) == FF_0SEG)
#define isSeg1(F)       ((F & MS_1TYPE) == FF_1SEG)
#define isEnum0(F)      ((F & MS_0TYPE) == FF_0ENUM)
#define isEnum1(F)      ((F & MS_1TYPE) == FF_1ENUM)
#define isFop0(F)       ((F & MS_0TYPE) == FF_0FOP)
#define isFop1(F)       ((F & MS_1TYPE) == FF_1FOP)
#define isStroff0(F)    ((F & MS_0TYPE) == FF_0STRO)
#define isStroff1(F)    ((F & MS_1TYPE) == FF_1STRO)
#define isStkvar0(F)    ((F & MS_0TYPE) == FF_0STK)
#define isStkvar1(F)    ((F & MS_1TYPE) == FF_1STK)
#define isFloat0(F)     ((F & MS_0TYPE) == FF_0FLT)
#define isFloat1(F)     ((F & MS_1TYPE) == FF_1FLT)
#define isCustFmt0(F)   ((F & MS_0TYPE) == FF_0CUST)
#define isCustFmt1(F)   ((F & MS_1TYPE) == FF_1CUST)

//
//      Bits for DATA bytes
//

#define DT_TYPE 0xF0000000L             // Mask for DATA typing

#define FF_BYTE 0x00000000L             // byte
#define FF_WORD 0x10000000L             // word
#define FF_DWRD 0x20000000L             // dword
#define FF_QWRD 0x30000000L             // qword
#define FF_TBYT 0x40000000L             // tbyte
#define FF_ASCI 0x50000000L             // ASCII ?
#define FF_STRU 0x60000000L             // Struct ?
#define FF_OWRD 0x70000000L             // octaword (16 bytes)
#define FF_FLOAT 0x80000000L            // float
#define FF_DOUBLE 0x90000000L           // double
#define FF_PACKREAL 0xA0000000L         // packed decimal real
#define FF_ALIGN    0xB0000000L         // alignment directive
#define FF_3BYTE    0xC0000000L         // 3-byte data
#define FF_CUSTOM   0xD0000000L         // custom data type

#define isByte(F)     (isData(F) && (F & DT_TYPE) == FF_BYTE)
#define isWord(F)     (isData(F) && (F & DT_TYPE) == FF_WORD)
#define isDwrd(F)     (isData(F) && (F & DT_TYPE) == FF_DWRD)
#define isQwrd(F)     (isData(F) && (F & DT_TYPE) == FF_QWRD)
#define isOwrd(F)     (isData(F) && (F & DT_TYPE) == FF_OWRD)
#define isTbyt(F)     (isData(F) && (F & DT_TYPE) == FF_TBYT)
#define isFloat(F)    (isData(F) && (F & DT_TYPE) == FF_FLOAT)
#define isDouble(F)   (isData(F) && (F & DT_TYPE) == FF_DOUBLE)
#define isPackReal(F) (isData(F) && (F & DT_TYPE) == FF_PACKREAL)
#define isASCII(F)    (isData(F) && (F & DT_TYPE) == FF_ASCI)
#define isStruct(F)   (isData(F) && (F & DT_TYPE) == FF_STRU)
#define isAlign(F)    (isData(F) && (F & DT_TYPE) == FF_ALIGN)
#define is3byte(F)    (isData(F) && (F & DT_TYPE) == FF_3BYTE)
#define isCustom(F)   (isData(F) && (F & DT_TYPE) == FF_CUSTOM)

//
//      Bits for CODE bytes
//

#define MS_CODE 0xF0000000L
#define FF_FUNC 0x10000000L             // function start?
#define FF_IMMD 0x40000000L             // Has Immediate value ?
#define FF_JUMP 0x80000000L             // Has jump table

//
//      Loader flags
//

#define NEF_SEGS   0x0001               // Create segments
#define NEF_RSCS   0x0002               // Load resources
#define NEF_NAME   0x0004               // Rename entries
#define NEF_MAN    0x0008               // Manual load
#define NEF_FILL   0x0010               // Fill segment gaps
#define NEF_IMPS   0x0020               // Create imports section
#define NEF_TIGHT  0x0040               // Don't align segments (OMF)
#define NEF_FIRST  0x0080               // This is the first file loaded
#define NEF_CODE   0x0100               // for load_binary_file:
#define NEF_RELOAD 0x0200               // reload the file at the same place:
#define NEF_FLAT   0x0400               // Autocreated FLAT group (PE)

#undef _notdefinedsymbol
#ifdef _notdefinedsymbol // There aren't declarations in IDC, so comment them

//         List of built-in functions
//         --------------------------
//
// The following conventions are used in this list:
//   'ea' is a linear address
//   'success' is 0 if a function failed, 1 otherwise
//   'void' means that function returns no meaningful value (always 0)
//   'string' means that function returns a string on success or an empty string on failure (unless specified otherwise)
//
//  All function parameter conversions are made automatically.
//
// ----------------------------------------------------------------------------
//                       M I S C E L L A N E O U S
// ----------------------------------------------------------------------------

// Check the variable type
// Returns true if the variable type is the expected one
// Thread-safe functions.

success IsString(var);
success IsLong(var);
success IsFloat(var);
success IsObject(var);


// Return value of expression: ((seg<<4) + off)

long    MK_FP           (long seg, long off);


// Return a formatted string.
//      format - printf-style format string.
//               %a - means address expression.
//               floating point values are output only in one format
//                regardless of the character specified (f, e, g, E, G)
//               %p is not supported.
// Thread-safe function.

string  sprintf(string format, ...);


// Return substring of a string
//      str - input string
//      x1  - starting index (0..n)
//      x2  - ending index. If x2 == -1, then return substring
//            from x1 to the end of string.
// Thread-safe function.

string  substr(string str, long x1, long x2);


// Search a substring in a string
//      str    - input string
//      substr - substring to search
// returns: 0..n - index in the 'str' where the substring starts
//          -1   - if the substring is not found
// Thread-safe function.

long    strstr(string str, string substr);       // find a substring, -1 - not found


// Return length of a string in bytes
//      str - input string
// Returns: length (0..n)
// Thread-safe function.

long    strlen(string str);                     // calculate length


// Return string filled with the specified character
//      chr - character to fill with
//      len - number of characters
// Returns: filled string
// Thread-safe function.

string  strfill(long chr, long len);


// Remove trailing zero bytes from a string
//      str - input string
// Returns: trimmed string
// Thread-safe function.

string  trim(string str);


// Convert ascii string to a binary number.
// (this function is the same as hexadecimal 'strtoul' from C library)

long    xtol            (string str);           // ascii hex -> number
                                                // (use long() for atol)


// Convert address value to a string

string  atoa            (long ea);              // returns address in
                                                // the form 'seg000:1234'
                                                // (the same as in line prefixes)


// Convert a number to a string.
//      n - number
//      radix - number base (2, 8, 10, 16)
// Thread-safe function.

string  ltoa            (long n, long radix);    // convert to ascii string


// Convert ascii string to a number
//      str - a decimal representation of a number
// returns: a binary number
// Thread-safe function.

long    atol            (string str);           // convert ascii decimal to long


// Get code of an ascii character
//      str - string with one character
// returns: a binary number, character code
// Thread-safe function.

long    ord             (string str);


// ***********************************************
// ** rotate a value to the left (or right)
//    arguments:
//         x      - value to rotate
//         count  - number of times to rotate. negative counter means
//                  rotate to the right
//         nbits  - number of bits to rotate
//         offset - offset of the first bit to rotate
// returns: the value with the specified field rotated
//          all other bits are not modified
// Thread-safe function.

long rotate_left(long value, long count, long nbits, long offset);

#endif
#define rotate_dword(x, count) rotate_left(x, count, 32, 0)
#define rotate_word(x, count) rotate_left(x, count, 16, 0)
#define rotate_byte(x, count) rotate_left(x, count, 8, 0)

// Add hotkey for IDC function
//      hotkey  - hotkey name ('a', "Alt-A", etc)
//      idcfunc - IDC function name
// returns:
#define IDCHK_OK        0       // ok
#define IDCHK_ARG       -1      // bad argument(s)
#define IDCHK_KEY       -2      // bad hotkey name
#define IDCHK_MAX       -3      // too many IDC hotkeys
#ifdef _notdefinedsymbol

long AddHotkey(string hotkey, string idcfunc);


// Delete IDC function hotkey

success DelHotkey(string hotkey);


// Move cursor to the specifed linear address
//      ea - linear address

success Jump            (long ea);              // move cursor to ea
                                                // screen is refreshed at
                                                // the end of IDC execution

// Wait for the end of autoanalysis
// This function will suspend execution of IDC program
// till the autoanalysis queue is empty.

void    Wait            ();                     // Process all entries in the
                                                // autoanalysis queue

// Compile an IDC script.
// The input should not contain functions that are
// currently executing - otherwise the behaviour of the replaced
// functions is undefined.
//      input  - if isfile != 0, then this is the name of file to compile
//               otherwise it hold the text to compile
// returns: 0 - ok, otherwise it returns an error message.
// Thread-safe function.

string CompileEx(string input, long isfile);


// Compile and execute IDC statement(s)
//      input  - IDC statement(s)
// returns: 1 - ok, otherwise throws an exception
// Thread-safe function.

long ExecIDC(string input);


// Evaluate an expression, in the current scripting language.
//      expr - an expression
// returns: the expression value.
// If there are problems, the returned value will be "IDC_FAILURE: xxx"
// where xxx is the error description
// Thread-safe function.

string or long Eval     (string expr);

#endif
// Macro to check for evaluation failures:
#define EVAL_FAILURE(code) (IsString(code) && substr(code, 0, 13) == "IDC_FAILURE: ")
#ifdef _notdefinedsymbol


// Save current database to the specified idb file
//      idbname - name of the idb file. if empty, the current idb
//                file will be used.
//      flags   - DBFL_BAK or 0

success SaveBase        (string idbname, long flags);

#endif
#define DBFL_BAK        0x04            // create backup file
#ifdef _notdefinedsymbol


// Stop execution of IDC program, close the database and exit to OS
//      code - code to exit with.

void    Exit            (long code);            // Exit to OS


// Execute an OS command.
// IDA will wait for the started program to finish.
// In order to start the command in parallel, use OS methods.
// For example, you may start another program in parallel using "start" command.
//      command - command line to execute
// returns: error code from OS
// Thread-safe function.

long    Exec            (string command);       // Execute OS command


// Sleep the specified number of milliseconds
// This function suspends IDA for the specified amount of time
// Thread-safe function.

void    Sleep(long milliseconds);


// Load and run a plugin
// The plugin name is a short plugin name without an extension
// returns: 0 if could not load the plugin, 1 if ok

success RunPlugin(string name, long arg);


// Load (plan to apply) a FLIRT signature file
//      name - signature name without path and extension
// returns: 0 if could not load the signature file, !=0 otherwise

success ApplySig(string name);


// ----------------------------------------------------------------------------
//  O B J E C T S
// ----------------------------------------------------------------------------
// NB: Thread-safe functions should not be called on the same variable
//     concurrently.

// Does an object attribute exist?
//      self  - object
//      attr  - attribute name
// Thread-safe function.

success hasattr(object self, string attr);


// Get object attribute
//      self  - object
//      attr  - attribute name
// This function gets the attribute value without calling __getattr__()
// Thread-safe function.

any     getattr(object self, string attr);


// Set object attribute
//      self  - object
//      attr  - attribute name
//      value - value
// This function sets the attribute value without calling __setattr__()
// Returns false: self is not an object
// Thread-safe function.

success setattr(object self, string attr, any value);


// Del object attribute
//      self  - object
//      attr  - attribute name
// Thread-safe function.

success delattr(object self, string attr);


// Get the first object attribute
//      self  - object
// If there are no attributes, returns 0
// Thread-safe function.

string  firstattr(object self);


// Get the last object attribute
//      self  - object
// If there are no attributes, returns 0
// Thread-safe function.

string  lastattr(object self);


// Get the next object attribute
//      self  - object
//      attr  - current attribute name
// If there are no more attributes, returns 0
// Thread-safe function.

string  nextattr(object self, string attr);


// Get the previois object attribute
//      self  - object
//      attr  - current attribute name
// If there are no more attributes, returns 0
// Thread-safe function.

string  prevattr(object self, string attr);


// Convert the object into a C structure and store it into the idb or a buffer
//  typeinfo - description of the C structure. Can be specified
//             as a declaration string or result of GetTinfo() or
//             similar functions
//  dest     - address (ea) to store the C structure
//             OR a reference to a destination string
//  flags    - combination of PIO_.. bits

void object.store(typeinfo, dest, flags);

#endif
#define PIO_NOATTR_FAIL 0x0004  // missing attributes are not ok
#define PIO_IGNORE_PTRS 0x0008  // do not follow pointers
#ifdef _notdefinedsymbol


// Retrieve a C structure from the idb or a buffer and convert it into an object
//  typeinfo - description of the C structure. Can be specified
//             as a declaration string or result of GetTinfo() or
//             similar functions
//  src      - address (ea) to retrieve the C structure from
//             OR a string buffer previously packed with the store method
//  flags    - combination of PIO_.. bits

void object.retrieve(typeinfo, src, flags);


// Print typeinfo in a human readable form
//   flags - optional parameter, combination of PRTYPE_... bits
// The typeinfo object must be "type" and "fields" attributes
// If the "name" attribute is present, it will be used in the output too
// If failed, returns 0

string typeinfo.print(flags);

// ----------------------------------------------------------------------------
//  L O A D E R  I N P U T  C L A S S
// ----------------------------------------------------------------------------

// Open an input file for reading
//      filename - name of the file to open
//      is_remote- !=0 means to open a file on the remote computer
//                 (possible only during remote debugging)
// Returns loader_input_t object or 0

loader_input_t open_loader_input(string filename, long is_remote);


class loader_input_t
{
// Read from the input file
//      buf - reference to the variable that will hold the read bytes
//            in form of a string
//      size - number of bytes to read
// Returns: number of read bytes

long loader_input_t.read(vref buf, long size);


// Get size of the input file

long loader_input_t.size();


// Seek in the input file
//      pos - position to seek to
//      whence - where from?
// Returns: the new file position

long loader_input_t.seek(long pos, long whence);

#endif
#define SEEK_SET   0 // from the file start
#define SEEK_CUR   1 // from the current position
#define SEEK_END   2 // from the file end
#ifdef _notdefinedsymbol


// Get the current file position

long loader_input_t.tell();


// Read one line of text from the input file
//      maxsize - maximal size of the line
// Returns: one line of text or 0
// If the input file contains zeroes, the line will be truncated at them

string loader_input_t.gets(long maxsize);


// Read a zero terminated string from the input file
//      pos     - file position to read from
//      maxsize - maximal size of the string
// Returns: a string or 0

string loader_input_t.getz(long pos, long maxsize);


// Read one byte from the input file
// Returns -1 if no more bytes

long loader_input_t.getc();


// Read a multibyte value from the input file
//      result - reference to the variable that will hold the result
//      size   - size of the value. Usually is: 1, 2, 4, 8
//      mf     - should the value be swapped?
// Returns: 0:ok, -1:failure

long loader_input_t.readbytes(vref result, long size, long mf);


// Close the input file

void loader_input_t.close();

};

#endif

// Definitions for loaders that are implemented in IDC

// The bit that can be used in the 'options' attribute of the object
// that is returned by loader.accept_file()
#define ACCEPT_FIRST    0x8000            // Put the loader at the top of the list
                                          // on the 'load file' dialog

// Flags for the loader.load_file() function
#define NEF_SEGS        0x0001            // Create segments
#define NEF_RSCS        0x0002            // Load resources
#define NEF_NAME        0x0004            // Rename entries
#define NEF_MAN         0x0008            // Manual load
#define NEF_FILL        0x0010            // Fill segment gaps
#define NEF_IMPS        0x0020            // Create import segment
#define NEF_FIRST       0x0080            // This is the first file loaded
                                          // into the database.
#define NEF_CODE        0x0100            // for load_binary_file:
                                          //   load as a code segment
#define NEF_RELOAD      0x0200            // reload the file at the same place:
                                          //   don't create segments
                                          //   don't create fixup info
                                          //   don't import segments
                                          //   etc
                                          // load only the bytes into the base.
                                          // a loader should have LDRF_RELOAD
                                          // bit set
#define NEF_FLAT        0x0400            // Autocreate FLAT group (PE)
#define NEF_MINI        0x0800            // Create mini database (do not copy
                                          // segment bytes from the input file;
                                          // use only the file header metadata)
#define NEF_LOPT        0x1000            // Display additional loader options dialog
#define NEF_LALL        0x2000            // Load all segments without questions
#ifdef _notdefinedsymbol

// ----------------------------------------------------------------------------
// C H A N G E   P R O G R A M   R E P R E S E N T A T I O N
// ----------------------------------------------------------------------------

// Delete all segments, instructions, comments, i.e. everything
// except values of bytes.

void    DeleteAll       ();                     // delete ALL information
                                                // about the program

// Create an instruction at the specified address
//      ea - linear address
// returns: 0 - can't create an instruction (no such opcode, the instruction would
//              overlap with existing items, etc)
//          otherwise returns length of the instruction in bytes

long    MakeCode        (long ea);              // convert to instruction
                                                // returns number of bytes
                                                // occupied by the instruction


// Perform full analysis of the area
//      sEA - starting linear address
//      eEA - ending linear address (excluded)
// returns: 1-ok, 0-Ctrl-Break was pressed.

long    AnalyzeArea     (long sEA, long eEA);   // analyze area and try to
                                                // convert to code all bytes
                                                // Returns 1-ok,0-CtrlBreak pressed

// Rename an address
//      ea - linear address
//      name - new name of address. If name == "", then delete old name
//      flags - combination of SN_... constants
// returns: 1-ok, 0-failure

success MakeNameEx      (long ea, string name, long flags);

#endif
#define SN_CHECK        0x01    // Fail if the name contains invalid characters
                                // If this bit is clear, all invalid chars
                                // (those !is_ident_char()) will be replaced
                                // by SubstChar (usually '_')
                                // List of valid characters is defined in ida.cfg
#define SN_NOCHECK      0x00    // Replace invalid chars with SubstChar
#define SN_PUBLIC       0x02    // if set, make name public
#define SN_NON_PUBLIC   0x04    // if set, make name non-public
#define SN_WEAK         0x08    // if set, make name weak
#define SN_NON_WEAK     0x10    // if set, make name non-weak
#define SN_AUTO         0x20    // if set, make name autogenerated
#define SN_NON_AUTO     0x40    // if set, make name non-autogenerated
#define SN_NOLIST       0x80    // if set, exclude name from the list
                                // if not set, then include the name into
                                // the list (however, if other bits are set,
                                // the name might be immediately excluded
                                // from the list)
#define SN_NOWARN       0x100   // don't display a warning if failed
#define SN_LOCAL        0x200   // create local name. a function should exist.
                                // local names can't be public or weak.
                                // also they are not included into the list of names
                                // they can't have dummy prefixes
#ifdef _notdefinedsymbol


// Set an indented regular comment of an item
//      ea      - linear address
//      comment - comment string

success MakeComm        (long ea, string comment); // give a comment


// Set an indented repeatable comment of an item
//      ea      - linear address
//      comment - comment string

success MakeRptCmt      (long ea, string comment); // give a repeatable comment


// Create an array.
//      ea      - linear address
//      nitems  - size of array in items
// This function will create an array of the items with the same type as the
// type of the item at 'ea'. If the byte at 'ea' is undefined, then this
// function will create an array of bytes.

success MakeArray       (long ea, long nitems);  // convert to an array


// Create a string.
// This function creates a string (the string type is determined by the value
// of GetLongPrm(INF_STRTYPE))
//      ea - linear address
//      endea - ending address of the string (excluded)
//              if endea == BADADDR, then length of string will be calculated
//              by the kernel
// returns: 1-ok, 0-failure
// note: the type of an existing string is returned by GetStringType()

success MakeStr         (long ea, long endea);


// Create a data item at the specified address
//      ea - linear address
//      flags - FF_BYTE..FF_PACKREAL
//      size - size of item in bytes
//      tid - for FF_STRU the structure id
// returns: 1-ok, 0-failure

success MakeData        (long ea, long flags, long size, long tid);


// Create a structure data item at the specified address
//      ea      - linear address
//      size    - structure size in bytes. -1 means that the size
//                will be calculated automatically
//      strname - name of a structure type
// returns: 1-ok, 0-failure

success MakeStructEx    (long ea, long size, string strname);


// Convert the current item to an alignment directive
//      ea      - linear address
//      count   - number of bytes to convert
//      align   - 0 or 1..32
//                if it is 0, the correct alignment will be calculated
//                by the kernel
// returns: 1-ok, 0-failure

success MakeAlign       (long ea, long count, long align);


// Create a local variable
//      start,end - range of addresses for the local variable.
//                  For the stack variables the end address is ignored.
//                  If there is no function at 'start' then this function.
//                  will fail.
//      location  - the variable location in the "[bp+xx]" form where xx is
//                  a number. The location can also be specified as a register name.
//      name      - name of the local variable
// returns: 1-ok, 0-failure

success MakeLocal(long start, long end, string location, string name);


// Convert the current item to an explored item
//      ea     - linear address
//      size   - size of the range to undefine (for MakeUnknown)
//      flags  - combination of DOUNK_... constants

void    MakeUnkn        (long ea, long flags);
void    MakeUnknown     (long ea, long size, long flags);

#endif
#define DOUNK_SIMPLE    0x0000  // simply undefine the specified item
#define DOUNK_EXPAND    0x0001  // propogate undefined items, for example
                                // if removing an instruction removes all
                                // references to the next instruction, then
                                // plan to convert to unexplored the next
                                // instruction too.
#define DOUNK_DELNAMES  0x0002  // delete any names at the specified
                                // address(es)
#ifdef _notdefinedsymbol


// Set array representation format
//      ea      - linear address
//      flags   - combination of AP_... constants or 0
//      litems  - number of items per line. 0 means auto
//      align   - element alignment:
//                  -1: do not align
//                  0:  automatic alignment
//                  other values: element width
// Returns: 1-ok, 0-failure

success SetArrayFormat(long ea, long flags, long litems, long align);

#endif
#define AP_ALLOWDUPS    0x00000001L     // use 'dup' construct
#define AP_SIGNED       0x00000002L     // treats numbers as signed
#define AP_INDEX        0x00000004L     // display array element indexes as comments
#define AP_ARRAY        0x00000008L     // reserved (this flag is not stored in database)
#define AP_IDXBASEMASK  0x000000F0L     // mask for number base of the indexes
#define   AP_IDXDEC     0x00000000L     // display indexes in decimal
#define   AP_IDXHEX     0x00000010L     // display indexes in hex
#define   AP_IDXOCT     0x00000020L     // display indexes in octal
#define   AP_IDXBIN     0x00000030L     // display indexes in binary
#ifdef _notdefinedsymbol


// Convert an operand of the item (instruction or data) to a binary number
//      ea - linear address
//       n  - number of operand
//              0 - the first operand
//              1 - the second, third and all other operands
//              -1 - all operands
// Note: the data items use only the type of the first operand
// Returns: 1-ok, 0-failure

success OpBinary        (long ea, int n);       // make operand binary
                                                // n=0 - first operand
                                                // n=1 - second, third etc. operands
                                                // n=-1 - all operands

// Convert an operand of the item (instruction or data) to an octal number
// (see explanation to Opbinary functions)

success OpOctal         (long ea, int n);

// Convert operand to decimal, hex, char (see OpBinary() for explanations)

success OpDecimal       (long ea, int n);
success OpHex           (long ea, int n);
success OpChr           (long ea, int n);


// Convert operand to an offset
// (for the explanations of 'ea' and 'n' please see OpBinary())
//      base - base of the offset as a linear address
//             If base == BADADDR then the current operand becomes non-offset
// Example:
//  seg000:2000 dw      1234h
// and there is a segment at paragraph 0x1000 and there is a data item
// within the segment at 0x1234:
//  seg000:1234 MyString        db 'Hello, world!',0
// Then you need to specify a linear address of the segment base to
// create a proper offset:
//      OpOff(MK_FP("seg000",0x2000),0,0x10000);
// and you will have:
//  seg000:2000 dw      offset MyString
// Motorola 680x0 processor have a concept of "outer offsets".
// If you want to create an outer offset, you need to combine number
// of the operand with the following bit:
#endif
#define OPND_OUTER      0x80                    // outer offset base
#ifdef _notdefinedsymbol
// Please note that the outer offsets are meaningful only for
// Motorola 680x0.

success OpOff           (long ea, int n, long base);


// Convert operand to a complex offset expression
// This is a more powerful version of OpOff() function.
// It allows to explicitly specify the reference type (off8,off16, etc)
// and the expression target with a possible target delta.
// The complex expressions are represented by IDA in the following form:
//
//         target + tdelta - base
//
// If the target is not present, then it will be calculated using
//         target = operand_value - tdelta + base
// The target must be present for LOW.. and HIGH.. reference types
//      ea      - linear address of the instruction/data
//      n       - number of operand to convert (the same as in OpOff)
//      reftype - one of REF_... constants
//      target  - an explicitly specified expression target. if you don't
//                want to specify it, use -1. Please note that LOW... and
//                HIGH... reference type requre the target.
//      base    - the offset base (a linear address)
//      tdelta  - a displacement from the target which will be displayed
//                in the expression.


success OpOffEx(long ea, int n, long reftype, long target, long base, long tdelta);

#endif
#define REF_OFF8    0 // 8bit full offset
#define REF_OFF16   1 // 16bit full offset
#define REF_OFF32   2 // 32bit full offset
#define REF_LOW8    3 // low 8bits of 16bit offset
#define REF_LOW16   4 // low 16bits of 32bit offset
#define REF_HIGH8   5 // high 8bits of 16bit offset
#define REF_HIGH16  6 // high 16bits of 32bit offset
#define REF_VHIGH   7 // high ph.high_fixup_bits of 32bit offset (processor dependent)
#define REF_VLOW    8 // low  (32-ph.high_fixup_bits) of 32bit offset (processor dependent)
#define REF_OFF64   9 // 64bit full offset
#define REFINFO_RVA     0x10 // based reference (rva)
#define REFINFO_PASTEND 0x20 // reference past an item
                             // it may point to an nonexistitng address
                             // do not destroy alignment dirs
#define REFINFO_NOBASE  0x80 // offset base is a number
                             // implies that base have be any value
                             // nb: base xrefs are created only if base
                             // points to the middle of a segment
#ifdef _notdefinedsymbol

// Convert operand to a segment expression
// (for the explanations of 'ea' and 'n' please see OpBinary())

success OpSeg           (long ea, int n);

// Convert operand to a number (with default number base, radix)
// (for the explanations of 'ea' and 'n' please see OpBinary())

success OpNumber        (long ea, int n);

// Convert operand to a floating-point number
// (for the explanations of 'ea' and 'n' please see OpBinary())

success OpFloat         (long ea, int n);

// Specify operand represenation manually.
// (for the explanations of 'ea' and 'n' please see OpBinary())
//      str - a string represenation of the operand
// IDA will not check the specified operand, it will simply display
// it instead of the orginal representation of the operand.

success OpAlt           (long ea, long n, string str);// manually enter n-th operand


// Change sign of the operand.
// (for the explanations of 'ea' and 'n' please see OpBinary())

success OpSign          (long ea, int n);        // change operand sign


// Toggle the bitwise not operator for the operand
// (for the explanations of 'ea' and 'n' please see OpBinary())

success OpNot           (long ea, int n);


// Convert operand to a symbolic constant
// (for the explanations of 'ea' and 'n' please see OpBinary())
//      enumid - id of enumeration type
//      serial - serial number of the constant in the enumeration
//               The serial numbers are used if there are more than
//               one symbolic constant with the same value in the
//               enumeration. In this case the first defined constant
//               get the serial number 0, then second 1, etc.
//               There could be 256 symbolic constants with the same
//               value in the enumeration.

success OpEnumEx(long ea, int n, long enumid, long serial);


// Convert operand to an offset in a structure
// (for the explanations of 'ea' and 'n' please see OpBinary())
//      strid - id of a structure type
//      delta - struct offset delta. usually 0. denotes the difference
//              between the structure base and the pointer into the structure.

success OpStroffEx      (long ea, int n, long strid, long delta);


// Convert operand to a stack variable
// (for the explanations of 'ea' and 'n' please see OpBinary())

success OpStkvar        (long ea, int n);


// Convert operand to a high offset
// High offset is the upper 16bits of an offset.
// This type is used by TMS320C6 processors (and probably by other
// RISC processors too)
// (for the explanations of 'ea' and 'n' please see OpBinary())
//      target - the full value (all 32bits) of the offset

success OpHigh          (long ea, int n, long target);


// Get id of a custom data type
//      name - name of the custom data type
// Returns: id or -1

long    GetCustomDataType(string name);


// Get id of a custom data format
//      name - name of the custom data format
// Returns: id or -1

long    GetCustomDataFormat(string name);


// Mark the location as "variable"
// Note: All that IDA does is to mark the location as "variable". Nothing else,
// no additional analysis is performed.
// This function may disappear in the future.

void    MakeVar         (long ea);


// Specify an additional line to display before the generated ones.
//      ea   - linear address
//      n    - number of anterior additioal line (0..MAX_ITEM_LINES)
//      line - the line to display
// IDA displays additional lines from number 0 up to the first unexisting
// additional line. So, if you specify additional line #150 and there is no
// additional line #149, your line will not be displayed.
// MAX_ITEM_LINES is defined in IDA.CFG

void    ExtLinA         (long ea, long n, string line);


// Specify an additional line to display after the generated ones.
//      ea   - linear address
//      n    - number of posterior additioal line (0..MAX_ITEM_LINES)
//      line - the line to display
// IDA displays additional lines from number 0 up to the first unexisting
// additional line. So, if you specify additional line #150 and there is no
// additional line #149, your line will not be displayed.
// MAX_ITEM_LINES is defined in IDA.CFG

void    ExtLinB         (long ea, long n, string line);


// Delete an additional anterior line
//      ea   - linear address
//      n    - number of anterior additioal line (0..500)

void    DelExtLnA       (long ea, long n);


// Delete an additional posterior line
//      ea   - linear address
//      n    - number of posterior additioal line (0..500)

void    DelExtLnB       (long ea, long n);


// Specify instruction represenation manually.
//      ea   - linear address
//      insn - a string represenation of the operand
// IDA will not check the specified instruction, it will simply display
// it instead of the orginal representation.

void    SetManualInsn   (long ea, string insn);


// Get manual representation of instruction
//      ea   - linear address
// This function returns value set by SetManualInsn earlier.

string  GetManualInsn   (long ea);


// Change a byte in the debugged process memory only
//      ea    - linear address
//      value - new value of the byte
// Returns: 1 if successful, 0 if not
// Thread-safe function (may be called only from the main thread and debthread)

success PatchDbgByte(long ea, long value);


// Change value of a program byte
// If debugger was active then the debugged process memory will be patched too
//      ea    - linear address
//      value - new value of the byte
// Returns: 1 if successful, 0 if not

success PatchByte       (long ea, long value);   // change a byte


// Change value of a program word (2 bytes)
//      ea    - linear address
//      value - new value of the word
// Returns: 1 if successful, 0 if not

success PatchWord       (long ea, long value);   // change a word (2 bytes)


// Change value of a double word
//      ea    - linear address
//      value - new value of the double word
// Returns: 1 if successful, 0 if not

success PatchDword      (long ea, long value);   // change a dword (4 bytes)


// Set new value of flags
// This function should not used be used directly if possible.
// It changes properties of a program byte and if misused, may lead to
// very-very strange results.

void    SetFlags        (long ea, long flags);   // change internal flags for ea


// Set value of a segment register.
//      ea - linear address
//      reg - name of a register, like "cs", "ds", "es", etc.
//      value - new value of the segment register.
//      tag   - one of SR_... constants
// IDA keeps tracks of all the points where segment registers change their
// values. This function allows you to specify the correct value of a segment
// register if IDA is not able to find the corrent value.
// See also SetReg() compatibility macro.

success SetRegEx(long ea, string reg, long value, long tag);
#endif
#define SR_inherit      1               // the value is inherited from the previous area
#define SR_user         2               // the value is specified by the user
#define SR_auto         3               // the value is determined by IDA
#define SR_autostart    4               // used as SR_auto for segment starting address
#ifdef _notdefinedsymbol

// Plan to perform an action in the future.
// This function will put your request to a special autoanalysis queue.
// Later IDA will retrieve the request from the queue and process
// it. There are several autoanalysis queue types. IDA will process all
// queries from the first queue and then switch to the second queue, etc.

// plan/unplan range of addresses
void    AutoMark2       (long start, long end, long queuetype);
void    AutoUnmark      (long start, long end, long queuetype);

#endif

// plan to analyze an address
#define AutoMark(ea, qtype)      AutoMark2(ea, ea+1, qtype)

#define AU_UNK  10      // make unknown
#define AU_CODE 20      // convert to instruction
#define AU_PROC 30      // make function
#define AU_USED 40      // reanalyze
#define AU_LIBF 60      // apply a flirt signature (the current signature!)
#define AU_FINAL 200    // coagulate unexplored items

#ifdef _notdefinedsymbol

// ----------------------------------------------------------------------------
//             P R O D U C E   O U T P U T   F I L E S
// ----------------------------------------------------------------------------


// Generate an output file
//      type  - type of output file. One of OFILE_... symbols. See below.
//      fp    - the output file handle
//      ea1   - start address. For some file types this argument is ignored
//      ea2   - end address. For some file types this argument is ignored
//      flags - bit combination of GENFLG_...
// returns: number of the generated lines.
//          -1 if an error occured
//          OFILE_EXE: 0-can't generate exe file, 1-ok

int GenerateFile(long type, long file_handle, long ea1, long ea2, long flags);
#endif

// output file types:

#define OFILE_MAP  0
#define OFILE_EXE  1
#define OFILE_IDC  2
#define OFILE_LST  3
#define OFILE_ASM  4
#define OFILE_DIF  5

// output control flags:

#define GENFLG_MAPSEGS 0x0001          // map: generate map of segments
#define GENFLG_MAPNAME 0x0002          // map: include dummy names
#define GENFLG_MAPDMNG 0x0004          // map: demangle names
#define GENFLG_MAPLOC  0x0008          // map: include local names
#define GENFLG_IDCTYPE 0x0008          // idc: gen only information about types
#define GENFLG_ASMTYPE 0x0010          // asm&lst: gen information about types too
#define GENFLG_GENHTML 0x0020          // asm&lst: generate html (gui version only)
#define GENFLG_ASMINC  0x0040          // asm&lst: gen information only about types

#ifdef _notdefinedsymbol

// Generate a flow chart GDL file
//      outfile - output file name. GDL extension will be used
//      title   - graph title
//      ea1     - beginning of the area to flow chart
//      ea2     - end of the area to flow chart. if ea2 == BADADDR
//                then ea1 is treated as an address within a function.
//                That function will be flow charted.
//      flags   - combination of CHART_... constants


success GenFuncGdl(string outfile, string title, long ea1, long ea2, long flags);

#endif
#define CHART_PRINT_NAMES 0x1000 // print labels for each block?
#define CHART_GEN_GDL     0x4000 // generate .gdl file (file extension is forced to .gdl)
#define CHART_WINGRAPH    0x8000 // call wingraph32 to display the graph
#define CHART_NOLIBFUNCS  0x0400 // don't include library functions in the graph
#ifdef _notdefinedsymbol


// Generate a function call graph GDL file
//      outfile - output file name. GDL extension will be used
//      title   - graph title
//      ea1     - beginning of the area to flow chart
//      ea2     - end of the area to flow chart. if ea2 == BADADDR
//                then ea1 is treated as an address within a function.
//                That function will be flow charted.
//      flags   - combination of CHART_GEN_GDL, CHART_WINGRAPH, CHART_NOLIBFUNCS

success GenCallGdl(string outfile, string title, long flags);


// ----------------------------------------------------------------------------
//               C O M M O N   I N F O R M A T I O N
// ----------------------------------------------------------------------------

// Get IDA directory
// This function returns the directory where IDA.EXE resides

string    GetIdaDirectory ();


// Get input file name
// This function returns name of the file being disassembled

string    GetInputFile    ();             // only the file name
string    GetInputFilePath();             // full path


// Set input file name
// This function updates the file name that is stored in the database
// It is used by the debugger and other parts of IDA
// Use it when the database is moved to another location or when you
// use remote debugging.

void      SetInputFilePath(string path);


// Get IDB full path
// This function returns full path of the current IDB database

string    GetIdbPath();


// Get MD5 hash of the input file.
// This function returns the MD5 hash string of the input file (32 chars)

string    GetInputMD5();


// Get internal flags
//      ea - linear address
// returns: 32-bit value of internal flags. See start of IDC.IDC file
// for explanations.

long    GetFlags        (long ea);              // get internal flags for ea


// Get one byte (8-bit) of the program at 'ea' from the database
// even if the debugger is active.
//      ea - linear address
// returns: byte value. If the byte has no value then 0xFF is returned.
// If the current byte size is different from 8 bits, then the returned value
// may have more 1's.
// To check if a byte has a value, use this expr: hasValue(GetFlags(ea))

long    IdbByte         (long ea);              // get a byte at ea


// Return the specified number of bytes of the program
//       ea - linear address
//       size - size of buffer in normal 8-bit bytes
//       use_dbg - use debugger memory or just the database
// returns: 0-failure
//          or a string containing the read bytes

string  GetManyBytes(long ea, long size, long use_dbg);

// Get value of program byte
//      ea - linear address
// returns: value of byte. If byte has no value then returns 0xFF
// If the current byte size is different from 8 bits, then the returned value
// might have more 1's.
// To check if a byte has a value, use functions hasValue(GetFlags(ea))

long    Byte            (long ea);              // get a byte at ea


// Get value of program byte using the debugger memory
//      ea - linear address
// returns: value of byte. Throws an exception on failure.
// Thread-safe function (may be called only from the main thread and debthread)

long    DbgByte            (long ea);


// Get original value of program byte
//      ea - linear address
// returns: the original value of byte before any patch applied to it

long    GetOriginalByte(long ea);


// Get value of program word (2 bytes)
//      ea - linear address
// returns: the value of the word. If word has no value then returns 0xFFFF
// If the current byte size is different from 8 bits, then the returned value
// might have more 1's.

long    Word            (long ea);              // get a word (2 bytes) at ea


// Get value of program word (2 bytes) using the debugger memory
//      ea - linear address
// returns: the value of the word. Throws an exception on failure.
// Thread-safe function (may be called only from the main thread and debthread)

long    DbgWord            (long ea);


// Get value of program double word (4 bytes)
//      ea - linear address
// returns: the value of the double word. Throws an exception on failure.

long    Dword           (long ea);              // get a double-word (4 bytes) at ea


// Get value of program double word (4 bytes) using the debugger memory
//      ea - linear address
// returns: the value of the quadro word. Throws an exception on failure.
// Thread-safe function (may be called only from the main thread and debthread)

long    DbgDword           (long ea);

// Get value of program quadro word (8 bytes)
//      ea - linear address
// returns: the value of the quadro word. If failed, throws an exception
// Note: this function is available only in the 64-bit version of IDA Pro

long    Qword           (long ea);


// Get value of program quadro word (8 bytes) using the debugger memory
//      ea - linear address
// returns: the value of the quadro word. If failed, throws an exception
// Note: this function is available only in the 64-bit version of IDA Pro
// Thread-safe function (may be called only from the main thread and debthread)

long    DbgQword           (long ea);


// Read from debugger memory
//      ea - linear address
//      size - size of data to read
// returns: data as a string. If failed, If failed, throws an exception
// Thread-safe function (may be called only from the main thread and debthread)

string  DbgRead            (long ea, long size);


// Write to debugger memory
//      ea - linear address
//      data - string to write
// returns: number of written bytes (-1 - network/debugger error)
// Thread-safe function (may be called only from the main thread and debthread)

long    DbgWrite           (long ea, string data);


// Get value of a floating point number (4/8 bytes)
//      ea - linear address
// Returns: a floating point number at the specified address.
// If the bytes at the specified address can not be represented as a floating
// point number, then return -1.

#endif
#define GetFloat(ea)     GetFpNum(ea, 4)
#define GetDouble(ea)    GetFpNum(ea, 8)
#ifdef _notdefinedsymbol

// Get linear address of a name
//      from - the referring address.
//             Allows to retrieve local label addresses in functions.
//             If a local name is not found, then address of a global name is returned.
//      name - name of program byte
// returns: address of the name
//          BADADDR - no such name
// Dummy names (like byte_xxxx where xxxx are hex digits) are parsed by this
// function to obtain the address. The database is not consulted for them.

long    LocByName       (string name);              // BADADDR - no such name
long    LocByNameEx     (long from, string name);   // BADADDR - no such name


// Get segment by segment base
//      base - segment base paragraph or selector
// returns: linear address of the start of the segment
//          BADADDR - no such segment

long    SegByBase       (long base);            // BADADDR - no such segment


// Get linear address of cursor

long    ScreenEA        ();                     // the current screen ea


// Invokes an IDA UI action by name
//      name    - Name of the command
//      flags   - Reserved. Must be zero.
// returns: 1-ok, 0-failed

long ProcessUiAction(string name, long flags);


// Get the disassembly line at the cursor

string  GetCurrentLine  ();


// Get start address of the selected area
// returns BADADDR - the user has not selected an area

long    SelStart        ();                     // the selected area start ea
                                                // BADADDR - no selected area


// Get end address of the selected area
// returns BADADDR - the user has not selected an area

long    SelEnd          ();                     // the selected area end ea
                                                // BADADDR - no selected area


// Get value of segment register at the specified address
//      ea - linear address
//      reg - name of segment register
// returns: the value of the segment register. The segment registers in
// 32bit program usually contain selectors, so to get paragraph pointed by
// the segment register you need to call AskSelector() function.

long    GetReg          (long ea, string reg);     // get segment register value


// Get next addresss in the program
//      ea - linear address
// returns: BADADDR - the specified address in the last used address

long    NextAddr        (long ea);              // returns next defined address
                                                // BADADDR if no such address exists


// Get previous addresss in the program
//      ea - linear address
// returns: BADADDR - the specified address in the first address

long    PrevAddr        (long ea);              // returns prev defined address
                                                // BADADDR if no such address exists


// Get next defined item (instruction or data) in the program
//      ea    - linear address to start search from
//      maxea - the search will stop at the address
//              maxea is not included in the search range
// returns: BADADDR - no (more) defined items

long    NextHead        (long ea, long maxea);  // returns next defined item address
                                                // BADADDR if no such address exists


// Get previous defined item (instruction or data) in the program
//      ea    - linear address to start search from
//      minea - the search will stop at the address
//              minea is included in the search range
// returns: BADADDR - no (more) defined items

long    PrevHead        (long ea, long minea);  // returns prev defined item address
                                                // BADADDR if no such address exists


// Get next not-tail address in the program
// This function searches for the next displayable address in the program.
// The tail bytes of instructions and data are not displayable.
//      ea - linear address
// returns: BADADDR - no (more) not-tail addresses

long    NextNotTail     (long ea);              // returns next not tail address
                                                // BADADDR if no such address exists


// Get previous not-tail address in the program
// This function searches for the previous displayable address in the program.
// The tail bytes of instructions and data are not displayable.
//      ea - linear address
// returns: BADADDR - no (more) not-tail addresses

long    PrevNotTail     (long ea);              // returns prev not tail address
                                                // BADADDR if no such address exists


// Get starting address of the item
//      ea - linear address
// returns: the starting address of the item
//          if the current address is unexplored, returns 'ea'

long    ItemHead         (long ea);


// Get address of the end of the item (instruction or data)
//      ea - linear address
// returns: address past end of the item at 'ea'

long    ItemEnd         (long ea);              // returns address past end of
                                                // the item


// Get size of instruction or data item in bytes
//      ea - linear address
// returns: 1..n

long    ItemSize        (long ea);              // returns item size, min answer=1


// Get visible name of program byte
// This function returns name of byte as it is displayed on the screen.
// If a name contains illegal characters, IDA replaces them by the substitution
// character during displaying. See IDA.CFG for the definition of the
// substitution character.
//      from - the referring address. may be BADADDR.
//             Allows to retrieve local label addresses in functions.
//             If a local name is not found, then a global name is returned.
//      ea   - linear address
// returns: 0 - byte has no name

string  NameEx          (long from, long ea);   // get visible name of the byte


// Get true name of program byte
// This function returns name of byte as is without any replacements.
//      from - the referring address. may be BADADDR.
//             Allows to retrieve local label addresses in functions.
//             If a local name is not found, then a global name is returned.
//      ea   - linear address
// returns: 0 - byte has no name

string  GetTrueNameEx   (long from, long ea);   // get true name of the byte


// Demangle a name
//      name - name to demangle
//      disable_mask - a mask that tells how to demangle the name
//                     it is a good idea to get this mask using
//                     GetLongPrm(INF_SHORT_DN) or GetLongPrm(INF_LONG_DN)
// Returns: a demangled name
// If the input name cannot be demangled, returns 0

string  Demangle        (string name, long disable_mask);


// Get disassembly line
//      ea - linear address of instruction
// returns: 0 - no instruction at the specified location
// note: this function may not return exactly the same mnemonics
// as you see on the screen.

string  GetDisasm       (long ea);              // get disassembly line


// Get instruction mnemonics
//      ea - linear address of instruction
// returns: 0 - no instruction at the specified location
// note: this function may not return exactly the same mnemonics
// as you see on the screen.

string  GetMnem         (long ea);              // get instruction name


// Get operand of an instruction
//      ea - linear address of instruction
//      n  - number of operand:
//              0 - the first operand
//              1 - the second operand
// returns: the current text representation of operand

string  GetOpnd         (long ea, long n);       // get instruction operand
                                                // n=0 - first operand


// Get type of instruction operand
//      ea - linear address of instruction
//      n  - number of operand:
//              0 - the first operand
//              1 - the second operand
// returns:
//      -1      bad operand number passed
#endif
#define o_void        0  // No Operand                           ----------
#define o_reg         1  // General Register (al,ax,es,ds...)    reg
#define o_mem         2  // Direct Memory Reference  (DATA)      addr
#define o_phrase      3  // Memory Ref [Base Reg + Index Reg]    phrase
#define o_displ       4  // Memory Reg [Base Reg + Index Reg + Displacement] phrase+addr
#define o_imm         5  // Immediate Value                      value
#define o_far         6  // Immediate Far Address  (CODE)        addr
#define o_near        7  // Immediate Near Address (CODE)        addr
#define o_idpspec0    8  // IDP specific type
#define o_idpspec1    9  // IDP specific type
#define o_idpspec2   10  // IDP specific type
#define o_idpspec3   11  // IDP specific type
#define o_idpspec4   12  // IDP specific type
#define o_idpspec5   13  // IDP specific type

// x86
#define o_trreg         o_idpspec0      // trace register
#define o_dbreg         o_idpspec1      // debug register
#define o_crreg         o_idpspec2      // control register
#define o_fpreg         o_idpspec3      // floating point register
#define o_mmxreg        o_idpspec4      // mmx register
#define o_xmmreg        o_idpspec5      // xmm register

// arm
#define o_reglist       o_idpspec1      // Register list (for LDM/STM)
#define o_creglist      o_idpspec2      // Coprocessor register list (for CDP)
#define o_creg          o_idpspec3      // Coprocessor register (for LDC/STC)
#define o_fpreg         o_idpspec4      // Floating point register
#define o_fpreglist     o_idpspec5      // Floating point register list
#define o_text          (o_idpspec5+1)  // Arbitrary text stored in the operand

// ppc
#define o_spr           o_idpspec0      // Special purpose register
#define o_twofpr        o_idpspec1      // Two FPRs
#define o_shmbme        o_idpspec2      // SH & MB & ME
#define o_crf           o_idpspec3      // crfield      x.reg
#define o_crb           o_idpspec4      // crbit        x.reg
#define o_dcr           o_idpspec5      // Device control register

#ifdef _notdefinedsymbol

long    GetOpType       (long ea, long n);       // get operand type


// Get number used in the operand
// This function returns an immediate number used in the operand
//      ea - linear address of instruction
//      n  - the operand number
// The return values are:
//      operand is an immediate value  => immediate value
//      operand has a displacement     => displacement
//      operand is a direct memory ref => memory address
//      operand is a register          => register number
//      operand is a register phrase   => phrase number
//      otherwise                      => -1

long    GetOperandValue (long ea, long n);       // get instruction operand value

// Decode an instruction
// Decode an instruction and returns an insn_t object (check ua.hpp)
//      ea - linear address of the instruction to decode
// The return values are:
//      0 => if the function fails
//    or:
//      insn_t object:
//        cs, ip, ea, itype, size, auxpref, insnpref, segpref, flags
//        n: number of operands
//        is_canonical: Boolean. True if its a canonical instruction.
//        feature, mnem: canonical feature and mnemonic string (if is_canonical is True)
//        Op0..Op5: instances of op_t (check ua.hpp)
//                  n, type, offb, offo, flags, dtyp, reg, value, addr, specval,
//                  specflag1, specflag2, specflag3, specflag4

object  DecodeInstruction(long ea);             // decodes an instruction

// Get anterior line
//      ea - linear address
//      num - number of anterior line (0..MAX_ITEM_LINES)
//            MAX_ITEM_LINES is defined in IDA.CFG

string  LineA           (long ea, long num);     // get additional line before generated ones


// Get posterior line
//      ea - linear address
//      num - number of posterior line (0..MAX_ITEM_LINES)

string  LineB           (long ea, long num);     // get additional line after generated ones


// Get indented comment
//      ea - linear address
//      repeatable: 0-regular, !=0-repeatable comment

string  CommentEx       (long ea, long repeatable);


// Get manually entered operand string
//      ea - linear address
//      n  - number of operand:
//              0 - the first operand
//              1 - the second operand

string  AltOp           (long ea, long n);       // get manually entered operand

// Get string contents
//      ea   - linear address
//      len  - string length. -1 means to calculate the max string length
//      type - the string type (one of ASCSTR_... constants)
// Returns: string contents or empty string

string GetString(long ea, long len, long type);


// Get string type
//      ea - linear address
// Returns one of ASCSTR_... constants

long GetStringType(long ea);

//
//      The following functions search for the specified byte
//          ea - address to start from
//          flag is combination of the following bits:
#endif
#define SEARCH_UP       0x00            // search backward
#define SEARCH_DOWN     0x01            // search forward
#define SEARCH_NEXT     0x02            // start the search at the next/prev item
                                        // useful only for FindText() and FindBinary()
                                        // for other Find.. functions it is implicitly set
#define SEARCH_CASE     0x04            // search case-sensitive
                                        // (only for bin&txt search)
#define SEARCH_REGEX    0x08            // enable regular expressions (only for txt)
#define SEARCH_NOBRK    0x10            // don't test ctrl-break
#define SEARCH_NOSHOW   0x20            // don't display the search progress
#ifdef _notdefinedsymbol

//      returns BADADDR - not found
//
long    FindVoid        (long ea, long flag);
long    FindCode        (long ea, long flag);
long    FindData        (long ea, long flag);
long    FindUnexplored  (long ea, long flag);
long    FindExplored    (long ea, long flag);
long    FindImmediate   (long ea, long flag, long value);
long    FindText        (long ea, long flag, long y, long x, string str);
                // y - number of text line at ea to start from (0..MAX_ITEM_LINES)
                // x - x coordinate in this line
long    FindBinary      (long ea, long flag, string str);
                // str - a string as a user enters it for Search Text in Core
                //      example:  "41 42" - find 2 bytes 41h,42h
                // The default radix depends on the current IDP module
                // (radix for ibm pc is 16)

// ----------------------------------------------------------------------------
//     G L O B A L   S E T T I N G S
// ----------------------------------------------------------------------------

// Parse one or more ida.cfg config directives
//      line - directives to process, for example: PACK_DATABASE=2
// If the directives are erroneous, a fatal error will be generated.
// The changes will be effective only for the current session.

void    ChangeConfig(string directive);


// The following functions allow you to set/get common parameters.
// Please note that not all parameters can be set directly.

long    GetLongPrm (long offset);
long    GetShortPrm(long offset);
long    GetCharPrm (long offset);
success SetLongPrm (long offset, long value);
success SetShortPrm(long offset, long value);
success SetCharPrm (long offset, long value);

#endif
// 'offset' may be one of the following:

#define INF_VERSION     3               // short;   Version of database
#define INF_PROCNAME    5               // char[8]; Name of current processor
#define INF_LFLAGS      13              // char;    IDP-dependent flags
#define         LFLG_PC_FPP     0x01    //              decode floating point processor
                                        //              instructions?
#define         LFLG_PC_FLAT    0x02    //              Flat model?
#define         LFLG_64BIT      0x04    //              64-bit program?
#define         LFLG_64BIT      0x04    //              64-bit program?
#define         LFLG_DBG_NOPATH 0x08    //              do not store input full path
#define         LFLG_SNAPSHOT   0x10    //              is memory snapshot?
#define         LFLG_IS_DLL     0x20    //              is dynamic library?
#define INF_DEMNAMES    14              // char;    display demangled names as:
#define         DEMNAM_CMNT  0          //              comments
#define         DEMNAM_NAME  1          //              regular names
#define         DEMNAM_NONE  2          //              don't display
#define         DEMNAM_GCC3  4          //          assume gcc3 names (valid for gnu compiler)
#define INF_FILETYPE    15              // short;   type of input file (see ida.hpp)
#define         FT_EXE_OLD      0       //              MS DOS EXE File (obsolete)
#define         FT_COM_OLD      1       //              MS DOS COM File (obsolete)
#define         FT_BIN          2       //              Binary File
#define         FT_DRV          3       //              MS DOS Driver
#define         FT_WIN          4       //              New Executable (NE)
#define         FT_HEX          5       //              Intel Hex Object File
#define         FT_MEX          6       //              MOS Technology Hex Object File
#define         FT_LX           7       //              Linear Executable (LX)
#define         FT_LE           8       //              Linear Executable (LE)
#define         FT_NLM          9       //              Netware Loadable Module (NLM)
#define         FT_COFF         10      //              Common Object File Format (COFF)
#define         FT_PE           11      //              Portable Executable (PE)
#define         FT_OMF          12      //              Object Module Format
#define         FT_SREC         13      //              R-records
#define         FT_ZIP          14      //              ZIP file (this file is never loaded to IDA database)
#define         FT_OMFLIB       15      //              Library of OMF Modules
#define         FT_AR           16      //              ar library
#define         FT_LOADER       17      //              file is loaded using LOADER DLL
#define         FT_ELF          18      //              Executable and Linkable Format (ELF)
#define         FT_W32RUN       19      //              Watcom DOS32 Extender (W32RUN)
#define         FT_AOUT         20      //              Linux a.out (AOUT)
#define         FT_PRC          21      //              PalmPilot program file
#define         FT_EXE          22      //              MS DOS EXE File
#define         FT_COM          23      //              MS DOS COM File
#define         FT_AIXAR        24      //              AIX ar library
#define         FT_MACHO        25      //              Mac OS X Mach-O file
#define INF_FCORESIZ    17
#define INF_CORESTART   21
#define INF_OSTYPE      25              // short;   FLIRT: OS type the program is for
#define         OSTYPE_MSDOS 0x0001
#define         OSTYPE_WIN   0x0002
#define         OSTYPE_OS2   0x0004
#define         OSTYPE_NETW  0x0008
#define INF_APPTYPE     27              // short;   FLIRT: Application type
#define         APPT_CONSOLE 0x0001     //              console
#define         APPT_GRAPHIC 0x0002     //              graphics
#define         APPT_PROGRAM 0x0004     //              EXE
#define         APPT_LIBRARY 0x0008     //              DLL
#define         APPT_DRIVER  0x0010     //              DRIVER
#define         APPT_1THREAD 0x0020     //              Singlethread
#define         APPT_MTHREAD 0x0040     //              Multithread
#define         APPT_16BIT   0x0080     //              16 bit application
#define         APPT_32BIT   0x0100     //              32 bit application
#define INF_START_SP    29              // int32;   SP register value at the start of
                                        //          program execution
#define INF_AF          33              // short;   Analysis flags:
#define         AF_FIXUP        0x0001  //              Create offsets and segments using fixup info
#define         AF_MARKCODE     0x0002  //              Mark typical code sequences as code
#define         AF_UNK          0x0004  //              Delete instructions with no xrefs
#define         AF_CODE         0x0008  //              Trace execution flow
#define         AF_PROC         0x0010  //              Create functions if call is present
#define         AF_USED         0x0020  //              Analyze and create all xrefs
#define         AF_FLIRT        0x0040  //              Use flirt signatures
#define         AF_PROCPTR      0x0080  //              Create function if data xref data->code32 exists
#define         AF_JFUNC        0x0100  //              Rename jump functions as j_...
#define         AF_NULLSUB      0x0200  //              Rename empty functions as nullsub_...
#define         AF_LVAR         0x0400  //              Create stack variables
#define         AF_TRACE        0x0800  //              Trace stack pointer
#define         AF_ASCII        0x1000  //              Create ascii string if data xref exists
#define         AF_IMMOFF       0x2000  //              Convert 32bit instruction operand to offset
#define         AF_DREFOFF      0x4000  //              Create offset if data xref to seg32 exists
#define         AF_FINAL        0x8000  //              Final pass of analysis
#define INF_START_IP    35              // int32;    IP register value at the start of
                                        //          program execution
#define INF_BEGIN_EA    39              // int32;   Linear address of program entry point
#define INF_MIN_EA      43              // int32;   The lowest address used
                                        //          in the program
#define INF_MAX_EA      47              // int32;   The highest address used
                                        //          in the program - 1
#define INF_OMIN_EA     51
#define INF_OMAX_EA     55
#define INF_LOW_OFF     59              // int32;   low limit of voids
#define INF_HIGH_OFF    63              // int32;   high limit of voids
#define INF_MAXREF      67              // int32;   max xref depth
#define INF_ASCII_BREAK 71              // char;    ASCII line break symbol
#define INF_WIDE_HIGH_BYTE_FIRST 72
#define INF_INDENT      73              // char;    Indention for instructions
#define INF_COMMENT     74              // char;    Indention for comments
#define INF_XREFNUM     75              // char;    Number of references to generate
                                        //          0 - xrefs won't be generated at all
#define INF_ENTAB       76              // char;    Use '\t' chars in the output file?
#define INF_SPECSEGS    77
#define INF_VOIDS       78              // char;    Display void marks?
#define INF_SHOWAUTO    80              // char;    Display autoanalysis indicator?
#define INF_AUTO        81              // char;    Autoanalysis is enabled?
#define INF_BORDER      82              // char;    Generate borders?
#define INF_NULL        83              // char;    Generate empty lines?
#define INF_GENFLAGS    84              // char;    General flags:
#define         INFFL_LZERO     0x01    //              Generate leading zeroes in numbers
#define         INFFL_ALLASM    0x02    //              May use constructs not supported by
                                        //              the target assembler
#define         INFFL_LOADIDC   0x04    //              Loading an idc file that contains database info
#define INF_SHOWPREF    85              // char;    Show line prefixes?
#define INF_PREFSEG     86              // char;    line prefixes with segment name?
#define INF_ASMTYPE     87              // char;    target assembler number (0..n)
#define INF_BASEADDR    88              // int32;   base paragraph of the program
#define INF_XREFS       92              // char;    xrefs representation:
#define         SW_SEGXRF       0x01    //              show segments in xrefs?
#define         SW_XRFMRK       0x02    //              show xref type marks?
#define         SW_XRFFNC       0x04    //              show function offsets?
#define         SW_XRFVAL       0x08    //              show xref values? (otherwise-"...")
#define INF_BINPREF     93              // short;   # of instruction bytes to show
                                        //          in line prefix
#define INF_CMTFLAG     95              // char;    comments:
#define         SW_RPTCMT       0x01    //              show repeatable comments?
#define         SW_ALLCMT       0x02    //              comment all lines?
#define         SW_NOCMT        0x04    //              no comments at all
#define         SW_LINNUM       0x08    //              show source line numbers

#define INF_NAMETYPE    96              // char;    dummy names represenation type
#define         NM_REL_OFF      0
#define         NM_PTR_OFF      1
#define         NM_NAM_OFF      2
#define         NM_REL_EA       3
#define         NM_PTR_EA       4
#define         NM_NAM_EA       5
#define         NM_EA           6
#define         NM_EA4          7
#define         NM_EA8          8
#define         NM_SHORT        9
#define         NM_SERIAL       10
#define INF_SHOWBADS    97              // char;    show bad instructions?
                                        //          an instruction is bad if it appears
                                        //          in the ash.badworks array

#define INF_PREFFLAG    98              // char;    line prefix type:
#define         PREF_SEGADR     0x01    //              show segment addresses?
#define         PREF_FNCOFF     0x02    //              show function offsets?
#define         PREF_STACK      0x04    //              show stack pointer?

#define INF_PACKBASE    99              // char;    pack database?

#define INF_ASCIIFLAGS  100             // uchar;   ascii flags
#define         ASCF_GEN        0x01    //              generate ASCII names?
#define         ASCF_AUTO       0x02    //              ASCII names have 'autogenerated' bit?
#define         ASCF_SERIAL     0x04    //              generate serial names?
#define         ASCF_COMMENT    0x10    //              generate auto comment for ascii references?
#define         ASCF_SAVECASE   0x20    //              preserve case of ascii strings for identifiers

#define INF_LISTNAMES   101             // uchar;   What names should be included in the list?
#define         LN_NORMAL       0x01    //              normal names
#define         LN_PUBLIC       0x02    //              public names
#define         LN_AUTO         0x04    //              autogenerated names
#define         LN_WEAK         0x08    //              weak names

#define INF_ASCIIPREF   102             // char[16];ASCII names prefix
#define INF_ASCIISERNUM 118             // uint32;  serial number
#define INF_ASCIIZEROES 122             // char;    leading zeroes
#define INF_TRIBYTE_ORDER 125           // char;    order of bytes in 3-byte items
#define         TRIBYTE_123 0           //              regular most significant byte first (big endian) - default
#define         TRIBYTE_132 1
#define         TRIBYTE_213 2
#define         TRIBYTE_231 3
#define         TRIBYTE_312 4
#define         TRIBYTE_321 5           //              regular least significant byte first (little endian)
#define INF_MF          126             // uchar;   Byte order: 1==MSB first
#define INF_ORG         127             // char;    Generate 'org' directives?
#define INF_ASSUME      128             // char;    Generate 'assume' directives?
#define INF_CHECKARG    129             // char;    Check manual operands?
#define INF_START_SS    130             // int32;   value of SS at the start
#define INF_START_CS    134             // int32;   value of CS at the start
#define INF_MAIN        138             // int32;   address of main()
#define INF_SHORT_DN    142             // int32;   short form of demangled names
#define INF_LONG_DN     146             // int32;   long form of demangled names
                                        //          see demangle.h for definitions
#define INF_DATATYPES   150             // int32;   data types allowed in data carousel
#define INF_STRTYPE     154             // int32;   current ascii string type
                                        //          is considered as several bytes:
                                        //      low byte:
#define         ASCSTR_TERMCHR  0       //              Character-terminated ASCII string
#define         ASCSTR_C        0       //              C-string, zero terminated
#define         ASCSTR_PASCAL   1       //              Pascal-style ASCII string (length byte)
#define         ASCSTR_LEN2     2       //              Pascal-style, length is 2 bytes
#define         ASCSTR_UNICODE  3       //              Unicode string
#define         ASCSTR_LEN4     4       //              Delphi string, length is 4 bytes
#define         ASCSTR_ULEN2    5       //              Pascal-style Unicode, length is 2 bytes
#define         ASCSTR_ULEN4    6       //              Pascal-style Unicode, length is 4 bytes
#define         ASCSTR_LAST     6       //              Last string type
                                        //      2nd byte - termination chracters for ASCSTR_TERMCHR:
#define         STRTERM1(strtype)       ((strtype>>8)&0xFF)
                                        //      3d byte:
#define         STRTERM2(strtype)       ((strtype>>16)&0xFF)
                                        //              The termination characters are kept in
                                        //              the 2nd and 3d bytes of string type
                                        //              if the second termination character is
                                        //              '\0', then it is ignored.
#define INF_AF2         158             // ushort;  Analysis flags 2
#define AF2_JUMPTBL     0x0001          //              Locate and create jump tables
#define AF2_DODATA      0x0002          //              Coagulate data segs at the final pass
#define AF2_HFLIRT      0x0004          //              Automatically hide library functions
#define AF2_STKARG      0x0008          //              Propagate stack argument information
#define AF2_REGARG      0x0010          //              Propagate register argument information
#define AF2_CHKUNI      0x0020          //              Check for unicode strings
#define AF2_SIGCMT      0x0040          //              Append a signature name comment for recognized anonymous library functions
#define AF2_SIGMLT      0x0080          //              Allow recognition of several copies of the same function
#define AF2_FTAIL       0x0100          //              Create function tails
#define AF2_DATOFF      0x0200          //              Automatically convert data to offsets
#define AF2_ANORET      0x0400          //              Perform 'no-return' analysis
#define AF2_VERSP       0x0800          //              Perform full stack pointer analysis
#define AF2_DOCODE      0x1000          //              Coagulate code segs at the final pass
#define AF2_TRFUNC      0x2000          //              Truncate functions upon code deletion
#define AF2_PURDAT      0x4000          //              Control flow to data segment is ignored
#define INF_NAMELEN     160             // ushort;  max name length (without zero byte)
#define INF_MARGIN      162             // ushort;  max length of data lines
#define INF_LENXREF     164             // ushort;  max length of line with xrefs
#define INF_LPREFIX     166             // char[16];prefix of local names
                                        //          if a new name has this prefix,
                                        //          it will be automatically converted to a local name
#define INF_LPREFIXLEN  182             // uchar;   length of the lprefix
#define INF_COMPILER    183             // uchar;   compiler
#define      COMP_MASK        0x0F      //              mask to apply to get the pure compiler id
#define         COMP_UNK      0x00      // Unknown
#define         COMP_MS       0x01      // Visual C++
#define         COMP_BC       0x02      // Borland C++
#define         COMP_WATCOM   0x03      // Watcom C++
#define         COMP_GNU      0x06      // GNU C++
#define         COMP_VISAGE   0x07      // Visual Age C++
#define         COMP_BP       0x08      // Delphi
#define INF_MODEL       184             // uchar;  memory model & calling convention
#define INF_SIZEOF_INT  185             // uchar;  sizeof(int)
#define INF_SIZEOF_BOOL 186             // uchar;  sizeof(bool)
#define INF_SIZEOF_ENUM 187             // uchar;  sizeof(enum)
#define INF_SIZEOF_ALGN 188             // uchar;  default alignment
#define INF_SIZEOF_SHORT 189
#define INF_SIZEOF_LONG  190
#define INF_SIZEOF_LLONG 191
#define INF_CHANGE_COUNTER 192          // uint32; database change counter; keeps track of byte and segment modifications
#define INF_SIZEOF_LDBL  196            // uchar;  sizeof(long double)
#define INF_APPCALL_OPTIONS 197         // uint32; appcall options

#ifdef __EA64__                 // redefine the offsets for 64-bit version
#define INF_CORESTART             25
#define INF_OSTYPE                33
#define INF_APPTYPE               35
#define INF_START_SP              37
#define INF_AF                    45
#define INF_START_IP              47
#define INF_BEGIN_EA              55
#define INF_MIN_EA                63
#define INF_MAX_EA                71
#define INF_OMIN_EA               79
#define INF_OMAX_EA               87
#define INF_LOW_OFF               95
#define INF_HIGH_OFF             103
#define INF_MAXREF               111
#define INF_ASCII_BREAK          119
#define INF_WIDE_HIGH_BYTE_FIRST 120
#define INF_INDENT               121
#define INF_COMMENT              122
#define INF_XREFNUM              123
#define INF_ENTAB                124
#define INF_SPECSEGS             125
#define INF_VOIDS                126
#define INF_SHOWAUTO             128
#define INF_AUTO                 129
#define INF_BORDER               130
#define INF_NULL                 131
#define INF_GENFLAGS             132
#define INF_SHOWPREF             133
#define INF_PREFSEG              134
#define INF_ASMTYPE              135
#define INF_BASEADDR             136
#define INF_XREFS                144
#define INF_BINPREF              145
#define INF_CMTFLAG              147
#define INF_NAMETYPE             148
#define INF_SHOWBADS             149
#define INF_PREFFLAG             150
#define INF_PACKBASE             151
#define INF_ASCIIFLAGS           152
#define INF_LISTNAMES            153
#define INF_ASCIIPREF            154
#define INF_ASCIISERNUM          170
#define INF_ASCIIZEROES          178
#define INF_MF                   182
#define INF_ORG                  183
#define INF_ASSUME               184
#define INF_CHECKARG             185
#define INF_START_SS             186
#define INF_START_CS             194
#define INF_MAIN                 202
#define INF_SHORT_DN             210
#define INF_LONG_DN              218
#define INF_DATATYPES            226
#define INF_STRTYPE              234
#define INF_AF2                  242
#define INF_NAMELEN              244
#define INF_MARGIN               246
#define INF_LENXREF              248
#define INF_LPREFIX              250
#define INF_LPREFIXLEN           266
#define INF_COMPILER             267
#define INF_MODEL                268
#define INF_SIZEOF_INT           269
#define INF_SIZEOF_BOOL          270
#define INF_SIZEOF_ENUM          271
#define INF_SIZEOF_ALGN          272
#define INF_SIZEOF_SHORT         273
#define INF_SIZEOF_LONG          274
#define INF_SIZEOF_LLONG         275
#define INF_CHANGE_COUNTER       276
#define INF_SIZEOF_LDBL          280
#define INF_APPCALL_OPTIONS      281
#endif

//--------------------------------------------------------------------------

// Set target processor
//      processor - name of processor in short form.
//                  run 'ida ?' to get list of allowed processor types
//      level     - the power of request:
//        SETPROC_COMPAT - search for the processor type in the current module
//        SETPROC_ALL    - search for the processor type in all modules
//                         only if there were not calls with SETPROC_USER
//        SETPROC_USER   - search for the processor type in all modules
//                         and prohibit level SETPROC_USER
//        SETPROC_FATAL  - can be combined with previous bits.
//                         means that if the processor type can't be
//                         set, IDA should display an error message and exit.

#define SETPROC_COMPAT 0
#define SETPROC_ALL    1
#define SETPROC_USER   2
#define SETPROC_FATAL  0x80

#define SetPrcsr(processor) SetProcessorType(processor, SETPROC_COMPAT)
#ifdef _notdefinedsymbol
success SetProcessorType (string processor, long level); // set processor type


// Set target assembler
//      asmidx - index of the target assembler in the array of assemblers
//               for the current processor.
// Returns: 1 - success, 0 - failure.

long    SetTargetAssembler(long asmidx);


// Enable/disable batch mode of operation
//      batch:  0 - ida will display dialog boxes and wait for the user input
//              1 - ida will not display dialog boxes, warnings, etc.
// returns: old balue of batch flag

long    Batch           (long batch);           // enable/disable batch mode
                                                // returns old value

// ----------------------------------------------------------------------------
//        I N T E R A C T I O N   W I T H   T H E   U S E R
// ----------------------------------------------------------------------------

// Ask the user to enter a string
//      defval - the default string value. This value
//               will appear in the dialog box.
//      prompt - the prompt to display in the dialog box
// Returns: the entered string.

string  AskStr          (string defval, string prompt); // ask a string


// Ask the user to choose a file
//      forsave- 0: "Open" dialog box, 1: "Save" dialog box
//      mask   - the input file mask as "*.*" or the default file name.
//      prompt - the prompt to display in the dialog box
// Returns: the selected file.

string  AskFile         (bool forsave, string mask, string prompt);   // ask a file name

// Ask the user to enter an address
//      defval - the default address value. This value
//               will appear in the dialog box.
//      prompt - the prompt to display in the dialog box
// Returns: the entered address or BADADDR.

long    AskAddr         (long defval, string prompt); // BADADDR - no or bad input

// Ask the user to enter a number
//      defval - the default value. This value
//               will appear in the dialog box.
//      prompt - the prompt to display in the dialog box
// Returns: the entered number or -1.

long    AskLong         (long defval, string prompt); // -1 - no or bad input

// Ask the user to enter a segment value
//      defval - the default value. This value
//               will appear in the dialog box.
//      prompt - the prompt to display in the dialog box
// Returns: the entered segment selector or BADSEL.

long    AskSeg          (long defval, string prompt); // BADSEL - no or bad input
                                                     // returns the segment selector


// Ask the user to enter an identifier
//      defval - the default identifier. This value
//               will appear in the dialog box.
//      prompt - the prompt to display in the dialog box
// Returns: the entered identifier.

string  AskIdent        (string defval, string prompt);


// Ask the user a question and let him answer Yes/No/Cancel
//      defval - the default answer. This answer will be selected if the user
//               presses Enter. -1:cancel, 0-no, 1-ok
//      prompt - the prompt to display in the dialog box
// Returns: -1:cancel, 0-no, 1-ok

long    AskYN           (long defval, string prompt);


// Display a message in the message window
//      format - printf() style format string
//      ...    - additional parameters if any
// This function can be used to debug IDC scripts
// Thread-safe function.

void    Message         (string format, ...);


// Print variables in the message window
// This function print text representation of all its arguments to the output window.
// This function can be used to debug IDC scripts

void    print           (...);


// Display a message in a message box
//      format - printf() style format string
//      ...    - additional parameters if any
// This function can be used to debug IDC scripts
// The user will be able to hide messages if they appear twice in a row on the screen

void    Warning         (string format, ...);      // show a warning a dialog box


// Display a fatal message in a message box and quit IDA
//      format - printf() style format string
//      ...    - additional parameters if any

void    Fatal           (string format, ...);      // exit IDA immediately


// Change IDA indicator.
// Returns the previous status.
long    SetStatus       (long status);

#endif
#define IDA_STATUS_READY    0 // READY     IDA is idle
#define IDA_STATUS_THINKING 1 // THINKING  Analyzing but the user may press keys
#define IDA_STATUS_WAITING  2 // WAITING   Waiting for the user input
#define IDA_STATUS_WORK     3 // BUSY      IDA is busy
#ifdef _notdefinedsymbol


// Refresh all disassembly views

void    Refresh         (void);


// Refresh all list views (names, functions, etc)

void    RefreshLists    (void);


// ----------------------------------------------------------------------------
//                        S E G M E N T A T I O N
// ----------------------------------------------------------------------------
//
// ***********************************************
// ** get a selector value
//         arguments:      sel - the selector number
//         returns:        selector value if found
//                         otherwise the input value (sel)
//         note:           selector values are always in paragraphs

long    AskSelector     (long sel);     // returns paragraph

// ***********************************************
// ** find a selector which has the specifed value
//         arguments:      val - value to search for
//         returns:        the selector number if found
//                         otherwise the input value (val & 0xFFFF)
//         note:           selector values are always in paragraphs

long    FindSelector    (long val);

// ***********************************************
// ** set a selector value
//         arguments:      sel - the selector number
//                         val - value of selector
//         returns:        nothing
//         note:           ida supports up to 4096 selectors.
//                         if 'sel' == 'val' then the
//                         selector is destroyed because
//                         it has no significance

void    SetSelector     (long sel, long value);

// ***********************************************
// ** delete a selector
//         arguments:      sel - the selector number to delete
//         returns:        nothing
//         note:           if the selector is found, it will
//                         be deleted

void    DelSelector     (long sel);

// ***********************************************
// ** SEGMENT FUNCTIONS

// Get first segment
// returns: linear address of the start of the first segment
// BADADDR - no segments are defined

long    FirstSeg        ();                     // returns start of the first
                                                // segment, BADADDR - no segments


// Get next segment
//      ea - linear address
// returns: start of the next segment
//          BADADDR - no next segment

long    NextSeg         (long ea);              // returns start of the next
                                                // segment, BADADDR - no more segs


// Get start address of a segment
//      ea - any address in the segment
// returns: start of segment
//          BADADDR - the specified address doesn't belong to any segment
// note: this function is a macro, see its definition at the end of idc.idc

long    SegStart        (long ea);              // returns start of the segment
                                                // BADADDR if bad address passed


// Get end address of a segment
//      ea - any address in the segment
// returns: end of segment (an address past end of the segment)
//          BADADDR - the specified address doesn't belong to any segment
// note: this function is a macro, see its definition at the end of idc.idc

long    SegEnd          (long ea);              // return end of the segment
                                                // this address doesn't belong
                                                // to the segment
                                                // BADADDR if bad address passed

// Get name of a segment
//      ea - any address in the segment
// returns: 0 - no segment at the specified address

string  SegName         (long ea);


// Create a new segment
//      startea  - linear address of the start of the segment
//      endea    - linear address of the end of the segment
//                 this address will not belong to the segment
//                 'endea' should be higher than 'startea'
//      base     - base paragraph or selector of the segment.
//                 a paragraph is 16byte memory chunk.
//                 If a selector value is specified, the selector should be
//                 already defined.
//      use32    - 0: 16bit segment, 1: 32bit segment, 2: 64bit segment
//      align    - segment alignment. see below for alignment values
//      comb     - segment combination. see below for combination values.
// returns: 0-failed, 1-ok

success AddSeg(long startea, long endea, long base, long use32, long align, long comb);


// Delete a segment
//   ea      - any address in the segment
//   flags   - combination of SEGMOD_... flags

success DelSeg(long ea, long flags);

#endif
#define SEGMOD_KILL   0x0001 // disable addresses if segment gets
                             // shrinked or deleted
#define SEGMOD_KEEP   0x0002 // keep information (code & data, etc)
#define SEGMOD_SILENT 0x0004 // be silent
#ifdef _notdefinedsymbol


// Change segment boundaries
//   ea      - any address in the segment
//   startea - new start address of the segment
//   endea   - new end address of the segment
//   flags   - combination of SEGMOD_... flags

success SetSegBounds(long ea, long startea, long endea, long flags);


// Change name of the segment
//   ea      - any address in the segment
//   name    - new name of the segment

success RenameSeg(long ea, string name);


// Change class of the segment
//   ea      - any address in the segment
//   class   - new class of the segment

success SetSegClass(long ea, string klass);


// Change alignment of the segment
//   ea      - any address in the segment
//   align   - new alignment of the segment, one of sa... constants

#endif
#define SegAlign(ea, alignment) SetSegmentAttr(ea, SEGATTR_ALIGN, alignment)
        #define saAbs      0    // Absolute segment.
        #define saRelByte  1    // Relocatable, byte aligned.
        #define saRelWord  2    // Relocatable, word (2-byte, 16-bit) aligned.
        #define saRelPara  3    // Relocatable, paragraph (16-byte) aligned.
        #define saRelPage  4    // Relocatable, aligned on 256-byte boundary (a "page"
                                // in the original Intel specification).
        #define saRelDble  5    // Relocatable, aligned on a double word (4-byte)
                                // boundary. This value is used by the PharLap OMF for
                                // the same alignment.
        #define saRel4K    6    // This value is used by the PharLap OMF for page (4K)
                                // alignment. It is not supported by LINK.
        #define saGroup    7    // Segment group
        #define saRel32Bytes 8  // 32 bytes
        #define saRel64Bytes 9  // 64 bytes
        #define saRelQword 10   // 8 bytes
#ifdef _notdefinedsymbol


// Change combination of the segment
//   ea      - any address in the segment
//   comb    - new combination of the segment, one of sc... constants

#endif
#define SegComb(ea, comb) SetSegmentAttr(ea, SEGATTR_COMB, comb)
        #define scPriv     0    // Private. Do not combine with any other program
                                // segment.
        #define scPub      2    // Public. Combine by appending at an offset that meets
                                // the alignment requirement.
        #define scPub2     4    // As defined by Microsoft, same as C=2 (public).
        #define scStack    5    // Stack. Combine as for C=2. This combine type forces
                                // byte alignment.
        #define scCommon   6    // Common. Combine by overlay using maximum size.
        #define scPub3     7    // As defined by Microsoft, same as C=2 (public).
#ifdef _notdefinedsymbol


// Change segment addressing
//   ea      - any address in the segment
//   bitness - 0: 16bit, 1: 32bit, 2: 64bit

success SetSegAddressing(long ea, long bitness);


// Get segment by name
//      segname - name of segment
// returns: segment selector or BADADDR

long    SegByName       (string segname);


// Set default segment register value for a segment
//   ea      - any address in the segment
//             if no segment is present at the specified address
//             then all segments will be affected
//   reg     - name of segment register
//   value   - default value of the segment register. -1-undefined.

success SetSegDefReg(long ea, string reg, long value);

// ***********************************************
// ** set segment type
//         arguments:      segea - any address within segment
//                         type  - new segment type:
//         returns:        !=0 - ok
// note: this function is a macro, see its definition at the end of idc.idc
#endif
#define SEG_NORM        0
#define SEG_XTRN        1       // * segment with 'extern' definitions
                                //   no instructions are allowed
#define SEG_CODE        2       // pure code segment
#define SEG_DATA        3       // pure data segment
#define SEG_IMP         4       // implementation segment
#define SEG_GRP         6       // * group of segments
                                //   no instructions are allowed
#define SEG_NULL        7       // zero-length segment
#define SEG_UNDF        8       // undefined segment type
#define SEG_BSS         9       // uninitialized segment
#define SEG_ABSSYM     10       // * segment with definitions of absolute symbols
                                //   no instructions are allowed
#define SEG_COMM       11       // * segment with communal definitions
                                //   no instructions are allowed
#define SEG_IMEM       12       // internal processor memory & sfr (8051)
#ifdef _notdefinedsymbol

success SetSegmentType  (long segea, long type);


// ***********************************************
// ** get segment attribute
//         arguments:      segea - any address within segment
//                         attr  - one of SEGATTR_... constants

long    GetSegmentAttr  (long segea, long attr);

// ***********************************************
// ** set segment attribute
//         arguments:      segea - any address within segment
//                         attr  - one of SEGATTR_... constants
// Please note that not all segment attributes are modifiable.
// Also some of them should be modified using special functions
// like SetSegAddressing, etc.

long    SetSegmentAttr  (long segea, long attr, long value);

#endif
#ifndef __EA64__
#define SEGATTR_START    0      // starting address
#define SEGATTR_END      4      // ending address
#define SEGATTR_ORGBASE 16
#define SEGATTR_ALIGN   20      // alignment
#define SEGATTR_COMB    21      // combination
#define SEGATTR_PERM    22      // permissions
#define SEGATTR_BITNESS 23      // bitness (0: 16, 1: 32, 2: 64 bit segment)
                                // Note: modifying the attrbite directly does
                                // not lead to the reanalysis of the segment.
                                // Using SetSegAddressing() is more correct.
#define SEGATTR_FLAGS   24      // segment flags
#define SEGATTR_SEL     26      // segment selector
#define SEGATTR_ES      30      // default ES value
#define SEGATTR_CS      34      // default CS value
#define SEGATTR_SS      38      // default SS value
#define SEGATTR_DS      42      // default DS value
#define SEGATTR_FS      46      // default FS value
#define SEGATTR_GS      50      // default GS value
#define SEGATTR_TYPE    94      // segment type
#define SEGATTR_COLOR   95      // segment color
#else
#define SEGATTR_START    0
#define SEGATTR_END      8
#define SEGATTR_ORGBASE 32
#define SEGATTR_ALIGN   40
#define SEGATTR_COMB    41
#define SEGATTR_PERM    42
#define SEGATTR_BITNESS 43
#define SEGATTR_FLAGS   44
#define SEGATTR_SEL     46
#define SEGATTR_ES      54
#define SEGATTR_CS      62
#define SEGATTR_SS      70
#define SEGATTR_DS      78
#define SEGATTR_FS      86
#define SEGATTR_GS      94
#define SEGATTR_TYPE    182
#define SEGATTR_COLOR   183
#endif

// Valid segment flags
#define SFL_COMORG   0x01       // IDP dependent field (IBM PC: if set, ORG directive is not commented out)
#define SFL_OBOK     0x02       // orgbase is present? (IDP dependent field)
#define SFL_HIDDEN   0x04 	// is the segment hidden?
#define SFL_DEBUG    0x08       // is the segment created for the debugger?
#define SFL_LOADER   0x10       // is the segment created by the loader?
#define SFL_HIDETYPE 0x20       // hide segment type (do not print it in the listing)

#ifdef _notdefinedsymbol


// Move a segment to a new address
// This function moves all information to the new address
// It fixes up address sensitive information in the kernel
// The total effect is equal to reloading the segment to the target address
//      ea    - any address within the segment to move
//      to    - new segment start address
//      flags - combination MFS_... constants
// returns: MOVE_SEGM_... error code

#endif
#define MSF_SILENT    0x0001    // don't display a "please wait" box on the screen
#define MSF_NOFIX     0x0002    // don't call the loader to fix relocations
#define MSF_LDKEEP    0x0004    // keep the loader in the memory (optimization)
#define MSF_FIXONCE   0x0008    // valid for RebaseProgram(): call loader only once
#ifdef _notdefinedsymbol

long MoveSegm(long ea, long to, long flags);


#endif
#define MOVE_SEGM_OK      0     // all ok
#define MOVE_SEGM_PARAM  -1     // The specified segment does not exist
#define MOVE_SEGM_ROOM   -2     // Not enough free room at the target address
#define MOVE_SEGM_IDP    -3     // IDP module forbids moving the segment
#define MOVE_SEGM_CHUNK  -4     // Too many chunks are defined, can't move
#define MOVE_SEGM_LOADER -5     // The segment has been moved but the loader complained
#define MOVE_SEGM_ODD    -6     // Can't move segments by an odd number of bytes
#ifdef _notdefinedsymbol


// Rebase the whole program by 'delta' bytes
//      delta - number of bytes to move the program
//      flags - combination of MFS_... constants
//              it is recommended to use MSF_FIXONCE so that the loader takes
//              care of global variables it stored in the database
// returns: error code MOVE_SEGM_...

long RebaseProgram(long delta, long flags);


// Set storage type
//      startEA - starting address
//      endEA   - ending address
//      stt     - new storage type, one of STT_VA and STT_MM
// returns: 0 - ok, otherwise internal error code

long SetStorageType(long startEA, long endEA, long stt);

#endif
#define STT_VA 0  // regular storage: virtual arrays, an explicit flag for each byte
#define STT_MM 1  // memory map: sparse storage. useful for huge objects
#ifdef _notdefinedsymbol

// ----------------------------------------------------------------------------
//                    C R O S S   R E F E R E N C E S
// ----------------------------------------------------------------------------

//      See sample file xrefs.idc to learn to use these functions.

//      Flow types (combine with XREF_USER!):
#endif
#define fl_CF   16              // Call Far
#define fl_CN   17              // Call Near
#define fl_JF   18              // Jump Far
#define fl_JN   19              // Jump Near
#define fl_F    21              // Ordinary flow

#define XREF_USER 32            // All user-specified xref types
                                // must be combined with this bit

#ifdef _notdefinedsymbol
                                        // Mark exec flow 'from' 'to'
void    AddCodeXref(long From, long To, long flowtype);
long    DelCodeXref(long From, long To, int undef);// Unmark exec flow 'from' 'to'
                                        // undef - make 'To' undefined if no
                                        //        more references to it
                                        // returns 1 - planned to be
                                        // made undefined

// The following functions include the ordinary flows:
// (the ordinary flow references are returned first)
long    Rfirst  (long From);            // Get first code xref from 'From'
long    Rnext   (long From, long current);// Get next code xref from
long    RfirstB (long To);              // Get first code xref to 'To'
long    RnextB  (long To, long current); // Get next code xref to 'To'

// The following functions don't take into account the ordinary flows:
long    Rfirst0 (long From);
long    Rnext0  (long From, long current);
long    RfirstB0(long To);
long    RnextB0 (long To, long current);

//      Data reference types (combine with XREF_USER!):
#endif
#define dr_O    1                       // Offset
#define dr_W    2                       // Write
#define dr_R    3                       // Read
#define dr_T    4                       // Text (names in manual operands)
#define dr_I    5                       // Informational
#ifdef _notdefinedsymbol

void    add_dref(long From, long To, long drefType);      // Create Data Ref
void    del_dref(long From, long To);    // Unmark Data Ref

long    Dfirst  (long From);            // Get first data xref from 'From'
long    Dnext   (long From, long current);
long    DfirstB (long To);              // Get first data xref to 'To'
long    DnextB  (long To, long current);

long    XrefType(void);                 // returns type of the last xref
                                        // obtained by [RD]first/next[B0]
                                        // functions. Return values
                                        // are fl_... or dr_...
// ----------------------------------------------------------------------------
//                            F I L E   I / O
// ----------------------------------------------------------------------------

// ***********************************************
// ** open a file
//         arguments: similiar to C fopen()
//         returns:        0 -error
//                         otherwise a file handle
// Thread-safe function.

long    fopen           (string file, string mode);

// ***********************************************
// ** close a file
//         arguments:      file handle
//         returns:        nothing
// Thread-safe function.

void    fclose          (long handle);

// ***********************************************
// ** get file length
//         arguments:      file handle
//         returns:        -1 - error
//                         otherwise file length in bytes
// Thread-safe function.

long    filelength      (long handle);

// ***********************************************
// ** set cursor position in the file
//         arguments:      handle  - file handle
//                         offset  - offset from origin
//                         origin  - 0 = from the start of file
//                                   1 = from the current cursor position
//                                   2 = from the end of file
//         returns:        0 - ok
//                         otherwise error
// Thread-safe function.

long    fseek           (long handle, long offset, long origin);

// ***********************************************
// ** get cursor position in the file
//         arguments:      file handle
//         returns:        -1 - error
//                         otherwise current cursor position
// Thread-safe function.

long    ftell           (long handle);

// ***********************************************
// ** load file into IDA database
//         arguments:      handle  - file handle or loader_input_t object
//                         pos     - position in the file
//                         ea      - linear address to load
//                         size    - number of bytes to load
//         returns:        0 - error
//                         1 - ok

success loadfile        (long handle, long pos, long ea, long size);

// ***********************************************
// ** save from IDA database to file
//         arguments:      handle  - file handle
//                         pos     - position in the file
//                         ea      - linear address to save from
//                         size    - number of bytes to save
//         returns:        0 - error
//                         1 - ok

success savefile        (long handle, long pos, long ea, long size);

// ***********************************************
// ** read one byte from file
//         arguments:      handle  - file handle
//         returns:        -1 - error
//                         otherwise a byte read.
// Thread-safe function.

long    fgetc           (long handle);

// ***********************************************
// ** write one byte to file
//         arguments:      handle  - file handle
//                         byte    - byte to write
//         returns:        0 - ok
//                         -1 - error
// Thread-safe function.

long    fputc           (long byte, long handle);

// ***********************************************
// ** fprintf
//         arguments:      handle  - file handle
//                         format  - format string
//         returns:        0 - ok
//                         -1 - error
// Thread-safe function.

long    fprintf         (long handle, string format, ...);

// ***********************************************
// ** read 2 bytes from file
//         arguments:      handle  - file hanlde
//                         mostfirst 0 - least significant byte is first (intel)
//                                   1 - most  significant byte is first
//         returns:        -1 - error
//                         otherwise: a 16-bit value
// Thread-safe function.

long    readshort       (long handle, long mostfirst);

// ***********************************************
// ** read 4 bytes from file
//         arguments:      handle  - file hanlde
//                         mostfirst 0 - least significant byte is first (intel)
//                                   1 - most  significant byte is first
//         returns:        a 32-bit value
// Thread-safe function.

long    readlong        (long handle, long mostfirst);

// ***********************************************
// ** write 2 bytes to file
//         arguments:      handle  - file hanlde
//                         word    - a 16-bit value to write
//                         mostfirst 0 - least significant byte is first (intel)
//                                   1 - most  significant byte is first
//         returns:        0 - ok
// Thread-safe function.

long    writeshort      (long handle, long word, long mostfirst);

// ***********************************************
// ** write 4 bytes to file
//         arguments:      handle  - file hanlde
//                         dword   - a 32-bit value to write
//                         mostfirst 0 - least significant byte is first (intel)
//                                   1 - most  significant byte is first
//         returns:        0 - ok
// Thread-safe function.

long    writelong       (long handle, long dword, long mostfirst);

// ***********************************************
// ** read a string from file
//         arguments:      handle  - file hanlde
//         returns:        a string
//                         check for EOF like this: !IsString(retvalue)
// Thread-safe function.

string    readstr         (long handle);

// ***********************************************
// ** write a string to file
//         arguments:      handle  - file hanlde
//                         str     - string to write
//         returns:        0 - ok
// Thread-safe function.

long    writestr        (long handle, string str);

// ***********************************************
// ** rename a file
//         arguments:      oldname - existing file name
//                         newname - new file name
//         returns:        error code from the system
// Thread-safe function.

long    rename(string oldname, string newname);

// ***********************************************
// ** delete a file
//         arguments:      filename - existing file/dir name
//         returns:        error code from the system
// Thread-safe function.

long    unlink(string filename);

// ***********************************************
// ** create a directory
//         arguments:      dirname - directory name
//                         mode    - file permissions (for unix)
//         returns:        error code from the system
// Thread-safe function.

long    mkdir(string dirname, long mode);

// ----------------------------------------------------------------------------
//                           F U N C T I O N S
// ----------------------------------------------------------------------------

// ***********************************************
// ** create a function
//         arguments:      start,end - function bounds
//                         If the function end address is BADADDR, then
//                         IDA will try to determine the function bounds
//                         automatically. IDA will define all necessary
//                         instructions to determine the function bounds.
//         returns:        !=0 - ok
//         note:           an instruction should be present at the start address

success MakeFunction(long start, long end);

// ***********************************************
// ** delete a function
//         arguments:      ea - any address belonging to the function
//         returns:        !=0 - ok

success DelFunction(long ea);

// ***********************************************
// ** change function end address
//         arguments:      ea - any address belonging to the function
//                         end - new function end address
//         returns:        !=0 - ok

success SetFunctionEnd(long ea, long end);

// ***********************************************
// ** find next function
//         arguments:      ea - any address belonging to the function
//         returns:        -1 - no more functions
//                         otherwise returns the next function start address

long NextFunction(long ea);

// ***********************************************
// ** find previous function
//         arguments:      ea - any address belonging to the function
//         returns:        -1 - no more functions
//                         otherwise returns the previous function start address

long PrevFunction(long ea);

// ***********************************************
// ** get a function attribute
//         arguments:      ea - any address belonging to the function
//                         attr - one of FUNCATTR_... constants
//         returns:        -1 - error
//                         otherwise returns the attribute value

long GetFunctionAttr(long ea, long attr);

#endif
#ifndef __EA64__
#define FUNCATTR_START    0     // function start address
#define FUNCATTR_END      4     // function end address
#define FUNCATTR_FLAGS    8     // function flags
#define FUNCATTR_FRAME   10     // function frame id
#define FUNCATTR_FRSIZE  14     // size of local variables
#define FUNCATTR_FRREGS  18     // size of saved registers area
#define FUNCATTR_ARGSIZE 20     // number of bytes purged from the stack
#define FUNCATTR_FPD     24     // frame pointer delta
#define FUNCATTR_COLOR   28     // function color code
#define FUNCATTR_OWNER   10     // chunk owner (valid only for tail chunks)
#define FUNCATTR_REFQTY  14     // number of chunk parents (valid only for tail chunks)
#else
#define FUNCATTR_START    0
#define FUNCATTR_END      8
#define FUNCATTR_FLAGS   16
#define FUNCATTR_FRAME   18
#define FUNCATTR_FRSIZE  26
#define FUNCATTR_FRREGS  34
#define FUNCATTR_ARGSIZE 36
#define FUNCATTR_FPD     44
#define FUNCATTR_COLOR   52
#define FUNCATTR_OWNER   18
#define FUNCATTR_REFQTY  26
#endif
#ifdef _notdefinedsymbol

// ***********************************************
// ** set a function attribute
//         arguments:      ea - any address belonging to the function
//                         attr - one of FUNCATTR_... constants
//                         value - new value of the attribute
//         returns:        1-ok, 0-failed

success SetFunctionAttr(long ea, long attr, long value);


// ***********************************************
// ** retrieve function flags
//         arguments:      ea - any address belonging to the function
//         returns:        -1 - function doesn't exist
//                         otherwise returns the flags:
#endif
#define FUNC_NORET         0x00000001L     // function doesn't return
#define FUNC_FAR           0x00000002L     // far function
#define FUNC_LIB           0x00000004L     // library function
#define FUNC_STATIC        0x00000008L     // static function
#define FUNC_FRAME         0x00000010L     // function uses frame pointer (BP)
#define FUNC_USERFAR       0x00000020L     // user has specified far-ness
                                           // of the function
#define FUNC_HIDDEN        0x00000040L     // a hidden function
#define FUNC_THUNK         0x00000080L     // thunk (jump) function
#define FUNC_BOTTOMBP      0x00000100L     // BP points to the bottom of the stack frame
#define FUNC_NORET_PENDING 0x00000200L     // Function 'non-return' analysis
                                           // must be performed. This flag is
                                           // verified upon func_does_return()
#define FUNC_SP_READY      0x00000400L     // SP-analysis has been performed
                                           // If this flag is on, the stack
                                           // change points should not be not
                                           // modified anymore. Currently this
                                           // analysis is performed only for PC
#define FUNC_PURGED_OK     0x00004000L     // 'argsize' field has been validated.
                                           // If this bit is clear and 'argsize'
                                           // is 0, then we do not known the real
                                           // number of bytes removed from
                                           // the stack. This bit is handled
                                           // by the processor module.
#define FUNC_TAIL          0x00008000L     // This is a function tail.
                                           // Other bits must be clear
                                           // (except FUNC_HIDDEN)
#ifdef _notdefinedsymbol

// note: this function is a macro, see its definition at the end of idc.idc
long GetFunctionFlags(long ea);

// ***********************************************
// ** change function flags
//         arguments:      ea - any address belonging to the function
//                         flags - see GetFunctionFlags() for explanations
//         returns:        !=0 - ok
// note: this function is a macro, see its definition at the end of idc.idc

success SetFunctionFlags(long ea, long flags);

// ***********************************************
// ** retrieve function name
//         arguments:      ea - any address belonging to the function
//         returns:        0 - function doesn't exist
//                         otherwise returns function name

string GetFunctionName(long ea);

// ***********************************************
// ** retrieve function comment
//         arguments:      ea - any address belonging to the function
//                         repeatable - 1: get repeatable comment
//                                      0: get regular comment
//         returns:        function comment string

string GetFunctionCmt(long ea, long repeatable);

// ***********************************************
// ** set function comment
//         arguments:      ea - any address belonging to the function
//                         cmt - a function comment line
//                         repeatable - 1: get repeatable comment
//                                      0: get regular comment

void SetFunctionCmt(long ea, string cmt, long repeatable);

// ***********************************************
// ** ask the user to select a function
//         arguments:      title - title of the dialog box
//         returns:        -1 - user refused to select a function
//                         otherwise returns the selected function start address

long ChooseFunction(string title);

// ***********************************************
// ** convert address to 'funcname+offset' string
//         arguments:      ea - address to convert
//         returns:        if the address belongs to a function then
//                           return a string formed as 'name+offset'
//                           where 'name' is a function name
//                           'offset' is offset within the function
//                         else
//                           return 0

string GetFuncOffset(long ea);

// ***********************************************
// ** Determine a new function boundaries
// **
//         arguments:      ea  - starting address of a new function
//         returns:        if a function already exists, then return
//                         its end address.
//                         if a function end cannot be determined,
//                         the return BADADDR
//                         otherwise return the end address of the new function

long FindFuncEnd(long ea);

// ***********************************************
// ** Get ID of function frame structure
// **
//         arguments:      ea - any address belonging to the function
//         returns:        ID of function frame or -1
//                         In order to access stack variables you need to use
//                         structure member manipulation functions with the
//                         obtained ID.
// note: this function is a macro, see its definition at the end of idc.idc

long GetFrame(long ea);

// ***********************************************
// ** Get size of local variables in function frame
// **
//         arguments:      ea - any address belonging to the function
//         returns:        Size of local variables in bytes.
//                         If the function doesn't have a frame, return 0
//                         If the function does't exist, return -1
// note: this function is a macro, see its definition at the end of idc.idc

long GetFrameLvarSize(long ea);

// ***********************************************
// ** Get size of saved registers in function frame
// **
//         arguments:      ea - any address belonging to the function
//         returns:        Size of saved registers in bytes.
//                         If the function doesn't have a frame, return 0
//                         This value is used as offset for BP
//                         (if FUNC_FRAME is set)
//                         If the function does't exist, return -1
// note: this function is a macro, see its definition at the end of idc.idc

long GetFrameRegsSize(long ea);

// ***********************************************
// ** Get size of arguments in function frame which are purged upon return
// **
//         arguments:      ea - any address belonging to the function
//         returns:        Size of function arguments in bytes.
//                         If the function doesn't have a frame, return 0
//                         If the function does't exist, return -1
// note: this function is a macro, see its definition at the end of idc.idc

long GetFrameArgsSize(long ea);

// ***********************************************
// ** Get full size of function frame
// **
//         arguments:      ea - any address belonging to the function
//         returns:        Size of function frame in bytes.
//                         This function takes into account size of local
//                         variables + size of saved registers + size of
//                         return address + size of function arguments
//                         If the function doesn't have a frame, return size of
//                         function return address in the stack.
//                         If the function does't exist, return 0

long GetFrameSize(long ea);

// ***********************************************
// ** Make function frame
// **
//         arguments:      ea      - any address belonging to the function
//                         lvsize  - size of function local variables
//                         frregs  - size of saved registers
//                         argsize - size of function arguments
//         returns:        ID of function frame or -1
//                         If the function did not have a frame, the frame
//                         will be created. Otherwise the frame will be
//                         modified

long MakeFrame(long ea, long lvsize, long frregs, long argsize);

// ***********************************************
// ** Get current delta for the stack pointer
// **
//         arguments:      ea      - end address of the instruction
//                                   i.e.the last address of the instruction+1
//         returns:        The difference between the original SP upon
//                         entering the function and SP for
//                         the specified address

long GetSpd(long ea);

// ***********************************************
// ** Get modification of SP made by the instruction
// **
//         arguments:      ea      - end address of the instruction
//                                   i.e.the last address of the instruction+1
//         returns:        Get modification of SP made at the specified location
//                         If the specified location doesn't contain a SP
//                         change point, return 0
//                         Otherwise return delta of SP modification

long GetSpDiff(long ea);

// ***********************************************
// ** Setup modification of SP made by the instruction
// **
//         arguments:      ea      - end address of the instruction
//                                   i.e.the last address of the instruction+1
//                         delta   - the difference made by the current
//                                   instruction.
//         returns:        1-ok, 0-failed

success SetSpDiff(long ea, long delta);


// Add automatical SP register change point
//      func_ea  - function start
//      ea       - linear address where SP changes
//                 usually this is the end of the instruction which
//                 modifies the stack pointer (cmd.ea+cmd.size)
//      delta    - difference between old and new values of SP
// returns: 1-ok, 0-failed

success AddAutoStkPnt2(func_ea, ea, sval_t delta);


// Add user-defined SP register change point
//      ea    - linear address where SP changes
//      delta - difference between old and new values of SP
// returns: 1-ok, 0-failed

success AddUserStkPnt(ea, sval_t delta);


// Delete SP register change point
//      func_ea - function start
//      ea      - linear address
// returns: 1-ok, 0-failed

success DelStkPnt(func_ea, ea_t ea);


// Return the address with the minimal spd (stack pointer delta)
// If there are no SP change points, then return BADADDR.
//      func_ea - function start
// returns: BADDADDR - no such function

long GetMinSpd(func_ea);


// Recalculate SP delta for an instruction that stops execution.
//
//      cur_ea  - linear address of the current instruction
// returns: 1 - new stkpnt is added, 0 - nothing is changed

success RecalcSpd(cur_ea);


// Below are the function chunk (or function tail) related functions

// ***********************************************
// ** Get a function chunk attribute
// **
//         arguments:      ea     - any address in the chunk
//                         attr   - one of: FUNCATTR_START, FUNCATTR_END
//                                  FUNCATTR_OWNER, FUNCATTR_REFQTY
//         returns:        desired attribute or -1

long GetFchunkAttr(long ea, long attr);

// ***********************************************
// ** Set a function chunk attribute
// **
//         arguments:      ea     - any address in the chunk
//                         attr   - nothing defined yet
//                         value  - desired bg color (RGB)
//         returns:        0 if failed, 1 if success

success SetFchunkAttr(long ea, long attr, long value);

// ***********************************************
// ** Get a function chunk referer
// **
//         arguments:      ea     - any address in the chunk
//                         idx    - referer index (0..GetFchunkAttr(FUNCATTR_REFQTY))
//         returns:        referer address or BADADDR

long GetFchunkReferer(long ea, long idx);

// ***********************************************
// ** Get next function chunk
// **
//         arguments:      ea     - any address
//         returns:        the starting address of the next
//                         function chunk or BADADDR
// This function enumerates all chunks of all functions in the database

long NextFchunk(long ea);

// ***********************************************
// ** Get previous function chunk
// **
//         arguments:      ea     - any address
//         returns:        the starting address of the previous
//                         function chunk or BADADDR
// This function enumerates all chunks of all functions in the database

long PrevFchunk(long ea);

// ***********************************************
// ** Append a function chunk to the function
// **
//         arguments:      funcea   - any address in the function
//                         ea1, ea2 - boundaries of a function tail
//                                    to add. If a chunk exists at the
//                                    specified addresses, it must have exactly
//                                    the specified boundaries
//         returns:        0 if failed, 1 if success

success AppendFchunk(long funcea, long ea1, long ea2);

// ***********************************************
// ** Remove a function chunk from the function
// **
//         arguments:      funcea - any address in the function
//                         ea1    - any address in the function chunk
//                                  to remove
//         returns:        0 if failed, 1 if success

success RemoveFchunk(long funcea, long tailea);

// ***********************************************
// ** Change the function chunk owner
// **
//         arguments:      tailea - any address in the function chunk
//                         funcea - the starting address of the new owner
//         returns:        0 if failed, 1 if success
// The new owner must already have the chunk appended before the call

success SetFchunkOwner(long tailea, long funcea);

// ***********************************************
// ** Get the first function chunk of the specified function
// **
//         arguments:      funcea - any address in the function
//         returns:        the function entry point or BADADDR
// This function returns the first (main) chunk of the specified function

long FirstFuncFchunk(long funcea);

// ***********************************************
// ** Get the next function chunk of the specified function
// **
//         arguments:      funcea - any address in the function
//                         tailea - any address in the current chunk
//         returns:        the starting address of the next
//                         function chunk or BADADDR
// This function returns the next chunk of the specified function

long NextFuncFchunk(long funcea, long tailea);

// ----------------------------------------------------------------------------
//                        E N T R Y   P O I N T S
// ----------------------------------------------------------------------------

// ***********************************************
// ** retrieve number of entry points
//         arguments:      none
//         returns:        number of entry points

long GetEntryPointQty(void);

// ***********************************************
// ** add entry point
//         arguments:      ordinal  - entry point number
//                                    if entry point doesn't have an ordinal
//                                    number, 'ordinal' should be equal to 'ea'
//                         ea       - address of the entry point
//                         name     - name of the entry point. If null string,
//                                    the entry point won't be renamed.
//                         makecode - if 1 then this entry point is a start
//                                    of a function. Otherwise it denotes data
//                                    bytes.
//         returns:        0 - entry point with the specifed ordinal already
//                                 exists
//                         1 - ok

success AddEntryPoint(long ordinal, long ea, string name, long makecode);

// ***********************************************
// ** retrieve entry point ordinal number
//         arguments:      index - 0..GetEntryPointQty()-1
//         returns:        0 if entry point doesn't exist
//                         otherwise entry point ordinal

long GetEntryOrdinal(long index);

// ***********************************************
// ** retrieve entry point address
//         arguments:      ordinal - entry point number
//                                   it is returned by GetEntryPointOrdinal()
//         returns:        -1 if entry point doesn't exist
//                         otherwise entry point address.
//                         If entry point address is equal to its ordinal
//                         number, then the entry point has no ordinal.

long GetEntryPoint(long ordinal);

// ***********************************************
// ** retrieve entry point name
//         arguments:      ordinal - entry point number
//                                   it is returned by GetEntryPointOrdinal()
//         returns:        -entry point name or ""

string GetEntryName(long ordinal);

// ***********************************************
// ** rename entry point
//         arguments:      ordinal - entry point number
//                         name    - new name
//         returns:        !=0 - ok

success RenameEntryPoint(long ordinal, string name);


// ----------------------------------------------------------------------------
//                              F I X U P S
// ----------------------------------------------------------------------------

// ***********************************************
// ** find next address with fixup information
//         arguments:      ea - current address
//         returns:        -1 - no more fixups
//                         otherwise returns the next address with
//                                                 fixup information

long GetNextFixupEA(long ea);

// ***********************************************
// ** find previous address with fixup information
//         arguments:      ea - current address
//         returns:        -1 - no more fixups
//                         otherwise returns the previous address with
//                                                 fixup information

long GetPrevFixupEA(long ea);

// ***********************************************
// ** get fixup target type
//         arguments:      ea - address to get information about
//         returns:        -1 - no fixup at the specified address
//                         otherwise returns fixup target type:
#endif
#define FIXUP_MASK      0xF
#define FIXUP_BYTE      FIXUP_OFF8 // 8-bit offset.
#define FIXUP_OFF8      0       // 8-bit offset.
#define FIXUP_OFF16     1       // 16-bit offset.
#define FIXUP_SEG16     2       // 16-bit base--logical segment base (selector).
#define FIXUP_PTR32     3       // 32-bit long pointer (16-bit base:16-bit
                                // offset).
#define FIXUP_OFF32     4       // 32-bit offset.
#define FIXUP_PTR48     5       // 48-bit pointer (16-bit base:32-bit offset).
#define FIXUP_HI8       6       // high  8 bits of 16bit offset
#define FIXUP_HI16      7       // high 16 bits of 32bit offset
#define FIXUP_LOW8      8       // low   8 bits of 16bit offset
#define FIXUP_LOW16     9       // low  16 bits of 32bit offset
#define FIXUP_REL       0x10    // fixup is relative to the linear address
                                // specified in the 3d parameter to set_fixup()
#define FIXUP_SELFREL   0x0     // self-relative?
                                //   - disallows the kernel to convert operands
                                //      in the first pass
                                //   - this fixup is used during output
                                // This type of fixups is not used anymore.
                                // Anyway you can use it for commenting purposes
                                // in the loader modules
#define FIXUP_EXTDEF    0x20    // target is a location (otherwise - segment)
#define FIXUP_UNUSED    0x40    // fixup is ignored by IDA
                                //   - disallows the kernel to convert operands
                                //   - this fixup is not used during output
#define FIXUP_CREATED   0x80    // fixup was not present in the input file
#ifdef _notdefinedsymbol

long GetFixupTgtType(long ea);

// ***********************************************
// ** get fixup target selector
//         arguments:      ea - address to get information about
//         returns:        -1 - no fixup at the specified address
//                         otherwise returns fixup target selector

long GetFixupTgtSel(long ea);

// ***********************************************
// ** get fixup target offset
//         arguments:      ea - address to get information about
//         returns:        -1 - no fixup at the specified address
//                         otherwise returns fixup target offset

long GetFixupTgtOff(long ea);

// ***********************************************
// ** get fixup target displacement
//         arguments:      ea - address to get information about
//         returns:        -1 - no fixup at the specified address
//                         otherwise returns fixup target displacement

long GetFixupTgtDispl(long ea);

// ***********************************************
// ** set fixup information
//         arguments:      ea        - address to set fixup information about
//                         type      - fixup type. see GetFixupTgtType()
//                                     for possible fixup types.
//                         targetsel - target selector
//                         targetoff - target offset
//                         displ     - displacement
//         returns:        none

void SetFixup(long ea, long type, long targetsel, long targetoff, long displ);

// ***********************************************
// ** delete fixup information
//         arguments:      ea - address to delete fixup information about
//         returns:        none

void DelFixup(long ea);

// ----------------------------------------------------------------------------
//                    M A R K E D   P O S I T I O N S
// ----------------------------------------------------------------------------

// ***********************************************
// ** mark position
//         arguments:      ea      - address to mark
//                         lnnum   - number of generated line for the 'ea'
//                         x       - x coordinate of cursor
//                         y       - y coordinate of cursor
//                         slot    - slot number: 1..1023
//                                   if the specifed value is not within the
//                                   range, IDA will ask the user to select slot.
//                         comment - description of the mark.
//                                   Should be not empty.
//         returns:        none

void MarkPosition(long ea, long lnnum, long x, long y, long slot, string comment);

// ***********************************************
// ** get marked position
//         arguments:      slot    - slot number: 1..1023
//                                   if the specifed value is <= 0
//                                   range, IDA will ask the user to select slot.
//         returns:        -1 - the slot doesn't contain a marked address
//                         otherwise returns the marked address

long GetMarkedPos(long slot);

// ***********************************************
// ** get marked position comment
//         arguments:      slot    - slot number: 1..1023
//         returns:        0 if the slot doesn't contain
//                                         a marked address
//                         otherwise returns the marked address comment

string GetMarkComment(long slot);

// ----------------------------------------------------------------------------
//                          S T R U C T U R E S
// ----------------------------------------------------------------------------

// ***********************************************
// Begin type updating. Use this function if you
// plan to call AddEnumConst or similar type modification functions
// many times or from inside a loop
//
//         arguments:      utp (one of UTP_... consts)
//         returns:        none

success BeginTypeUpdating(long utp);


// ***********************************************
// End type updating. Refreshes the type system
// at the end of type modification operations
//
//         arguments:      utp (one of UTP_... consts)
//         returns:        none

success EndTypeUpdating(long utp);


// ***********************************************
// ** get number of defined structure types
//         arguments:      none
//         returns:        number of structure types

long GetStrucQty(void);

// ***********************************************
// ** get index of first structure type
//         arguments:      none
//         returns:        -1 if no structure type is defined
//                         index of first structure type.
//                         Each structure type has an index and ID.
//                         INDEX determines position of structure definition
//                          in the list of structure definitions. Index 1
//                          is listed first, after index 2 and so on.
//                          The index of a structure type can be changed any
//                          time, leading to movement of the structure definition
//                          in the list of structure definitions.
//                         ID uniquely denotes a structure type. A structure
//                          gets a unique ID at the creation time and this ID
//                          can't be changed. Even when the structure type gets
//                          deleted, its ID won't be resued in the future.

long GetFirstStrucIdx(void);

// ***********************************************
// ** get index of last structure type
//         arguments:      none
//         returns:        -1 if no structure type is defined
//                         index of last structure type.
//                         See GetFirstStrucIdx() for the explanation of
//                         structure indices and IDs.

long GetLastStrucIdx(void);

// ***********************************************
// ** get index of next structure type
//         arguments:      current structure index
//         returns:        -1 if no (more) structure type is defined
//                         index of the next structure type.
//                         See GetFirstStrucIdx() for the explanation of
//                         structure indices and IDs.

long GetNextStrucIdx(long index);

// ***********************************************
// ** get index of previous structure type
//         arguments:      current structure index
//         returns:        -1 if no (more) structure type is defined
//                         index of the presiouvs structure type.
//                         See GetFirstStrucIdx() for the explanation of
//                         structure indices and IDs.

long GetPrevStrucIdx(long index);

// ***********************************************
// ** get structure index by structure ID
//         arguments:      structure ID
//         returns:        -1 if bad structure ID is passed
//                         otherwise returns structure index.
//                         See GetFirstStrucIdx() for the explanation of
//                         structure indices and IDs.

long GetStrucIdx(long id);

// ***********************************************
// ** get structure ID by structure index
//         arguments:      structure index
//         returns:        -1 if bad structure index is passed
//                         otherwise returns structure ID.
//                         See GetFirstStrucIdx() for the explanation of
//                         structure indices and IDs.

long GetStrucId(long index);

// ***********************************************
// ** get structure ID by structure name
//         arguments:      structure type name
//         returns:        -1 if bad structure type name is passed
//                         otherwise returns structure ID.

long GetStrucIdByName(string name);


// ***********************************************
// ** get structure type name
//         arguments:      structure type ID
//         returns:        -1 if bad structure type ID is passed
//                         otherwise returns structure type name.

string GetStrucName(long id);

// ***********************************************
// ** get structure type comment
//         arguments:      id         - structure type ID
//                         repeatable - 1: get repeatable comment
//                                      0: get regular comment
//         returns:        0 if bad structure type ID is passed
//                         otherwise returns comment.

string GetStrucComment(long id, long repeatable);

// ***********************************************
// ** get size of a structure
//         arguments:      id         - structure type ID
//         returns:        0 if bad structure type ID is passed
//                         otherwise returns size of structure in bytes.

long GetStrucSize(long id);

// ***********************************************
// ** get number of members of a structure
//         arguments:      id         - structure type ID
//         returns:        -1 if bad structure type ID is passed
//                         otherwise returns number of members.

long GetMemberQty(long id);

// ***********************************************
// ** get member id
//         arguments:      id         - structure type ID
//                         member_offset - member offset. The offset can be
//                                         any offset in the member. For example,
//                                         is a member is 4 bytes long and starts
//                                         at offset 2, then 2,3,4,5 denote
//                                         the same structure member.
//         returns:        -1 if bad structure type ID is passed or there is
//                         no member at the specified offset.
//                         otherwise returns the member id.

long GetMemberId(long id, long member_offset);

// ***********************************************
// ** get previous offset in a structure
//         arguments:      id     - structure type ID
//                         offset - current offset
//         returns:        -1 if bad structure type ID is passed
//                            or no (more) offsets in the structure
//                         otherwise returns previous offset in a structure.
//                         NOTE: IDA allows 'holes' between members of a
//                               structure. It treats these 'holes'
//                               as unnamed arrays of bytes.
//                         This function returns a member offset or a hole offset.
//                         It will return size of the structure if input
//                         'offset' is bigger than the structure size.
//                         NOTE: Union members are, in IDA's internals, located
//                         at subsequent byte offsets: member 0 -> offset 0x0,
//                         member 1 -> offset 0x1, etc...

long GetStrucPrevOff(long id, long offset);

// ***********************************************
// ** get next offset in a structure
//         arguments:      id     - structure type ID
//                         offset - current offset
//         returns:        -1 if bad structure type ID is passed
//                            or no (more) offsets in the structure
//                         otherwise returns next offset in a structure.
//                         NOTE: IDA allows 'holes' between members of a
//                               structure. It treats these 'holes'
//                               as unnamed arrays of bytes.
//                         This function returns a member offset or a hole offset.
//                         It will return size of the structure if input
//                         'offset' belongs to the last member of the structure.
//                         NOTE: Union members are, in IDA's internals, located
//                         at subsequent byte offsets: member 0 -> offset 0x0,
//                         member 1 -> offset 0x1, etc...

long GetStrucNextOff(long id, long offset);

// ***********************************************
// ** get offset of the first member of a structure
//         arguments:      id            - structure type ID
//         returns:        -1 if bad structure type ID is passed
//                            or structure has no members
//                         otherwise returns offset of the first member.
//                         NOTE: IDA allows 'holes' between members of a
//                               structure. It treats these 'holes'
//                               as unnamed arrays of bytes.
//                         NOTE: Union members are, in IDA's internals, located
//                         at subsequent byte offsets: member 0 -> offset 0x0,
//                         member 1 -> offset 0x1, etc...

long GetFirstMember(long id);

// ***********************************************
// ** get offset of the last member of a structure
//         arguments:      id            - structure type ID
//         returns:        -1 if bad structure type ID is passed
//                            or structure has no members
//                         otherwise returns offset of the last member.
//                         NOTE: IDA allows 'holes' between members of a
//                               structure. It treats these 'holes'
//                               as unnamed arrays of bytes.
//                         NOTE: Union members are, in IDA's internals, located
//                         at subsequent byte offsets: member 0 -> offset 0x0,
//                         member 1 -> offset 0x1, etc...

long GetLastMember(long id);

// ***********************************************
// ** get offset of a member of a structure by the member name
//         arguments:      id            - structure type ID
//                         member_name   - name of structure member
//         returns:        -1 if bad structure type ID is passed
//                            or no such member in the structure
//                         otherwise returns offset of the specified member.
//                         NOTE: Union members are, in IDA's internals, located
//                         at subsequent byte offsets: member 0 -> offset 0x0,
//                         member 1 -> offset 0x1, etc...

long GetMemberOffset(long id, string member_name);

// ***********************************************
// ** get name of a member of a structure
//         arguments:      id            - structure type ID
//                         member_offset - member offset. The offset can be
//                                         any offset in the member. For example,
//                                         is a member is 4 bytes long and starts
//                                         at offset 2, then 2,3,4,5 denote
//                                         the same structure member.
//         returns:        0 if bad structure type ID is passed
//                            or no such member in the structure
//                         otherwise returns name of the specified member.

string GetMemberName(long id, long member_offset);

// ***********************************************
// ** get comment of a member
//         arguments:      id            - structure type ID
//                         member_offset - member offset. The offset can be
//                                         any offset in the member. For example,
//                                         is a member is 4 bytes long and starts
//                                         at offset 2, then 2,3,4,5 denote
//                                         the same structure member.
//                         repeatable - 1: get repeatable comment
//                                      0: get regular comment
//         returns:        0 if bad structure type ID is passed
//                            or no such member in the structure
//                         otherwise returns comment of the specified member.

string GetMemberComment(long id, long member_offset, long repeatable);

// ***********************************************
// ** get size of a member
//         arguments:      id            - structure type ID
//                         member_offset - member offset. The offset can be
//                                         any offset in the member. For example,
//                                         is a member is 4 bytes long and starts
//                                         at offset 2, then 2,3,4,5 denote
//                                         the same structure member.
//         returns:        -1 if bad structure type ID is passed
//                            or no such member in the structure
//                         otherwise returns size of the specified
//                                           member in bytes.

long GetMemberSize(long id, long member_offset);

// ***********************************************
// ** get type of a member
//         arguments:      id            - structure type ID
//                         member_offset - member offset. The offset can be
//                                         any offset in the member. For example,
//                                         is a member is 4 bytes long and starts
//                                         at offset 2, then 2,3,4,5 denote
//                                         the same structure member.
//         returns:        -1 if bad structure type ID is passed
//                            or no such member in the structure
//                         otherwise returns type of the member, see bit
//                         definitions above. If the member type is a structure
//                         then function GetMemberStrid() should be used to
//                         get the structure type id.

long GetMemberFlag(long id, long member_offset);

// ***********************************************
// ** get structure id of a member
//         arguments:      id            - structure type ID
//                         member_offset - member offset. The offset can be
//                                         any offset in the member. For example,
//                                         is a member is 4 bytes long and starts
//                                         at offset 2, then 2,3,4,5 denote
//                                         the same structure member.
//         returns:        -1 if bad structure type ID is passed
//                            or no such member in the structure
//                         otherwise returns structure id of the member.
//                         If the current member is not a structure, returns -1.

long GetMemberStrId(long id, long member_offset);

// ***********************************************
// ** is a structure a union?
//      arguments:      id            - structure type ID
//         returns:        1: yes, this is a union id
//                         0: no
//
//                         Unions are a special kind of structures

long IsUnion(long id);

// ***********************************************
// ** define a new structure type
//         arguments:      index         - index of new structure type
//                         If another structure has the specified index,
//                         then index of that structure and all other
//                         structures will be increentedfreeing the specifed
//                         index. If index is == -1, then the biggest index
//                         number will be used.
//                         See GetFirstStrucIdx() for the explanation of
//                         structure indices and IDs.
//
//                         name - name of the new structure type.
//
//                         is_union - 0: structure
//                                    1: union
//
//         returns:        -1 if can't define structure type because of
//                         bad structure name: the name is ill-formed or is
//                         already used in the program.
//                         otherwise returns ID of the new structure type

long AddStrucEx(long index, string name, long is_union);

// ***********************************************
// ** delete a structure type
//         arguments:      id            - structure type ID
//         returns:        0 if bad structure type ID is passed
//                         1 otherwise the structure type is deleted. All data
//                         and other structure types referencing to the
//                         deleted structure type will be displayed as array
//                         of bytes.

success DelStruc(long id);

// ***********************************************
// ** change structure index
//         arguments:      id      - structure type ID
//                         index   - new index of the structure
//                         See GetFirstStrucIdx() for the explanation of
//                         structure indices and IDs.
//         returns:        !=0 - ok

long SetStrucIdx(long id, long index);

// ***********************************************
// ** change structure name
//         arguments:      id      - structure type ID
//                         name    - new name of the structure
//         returns:        !=0 - ok

long SetStrucName(long id, string name);

// ***********************************************
// ** change structure comment
//         arguments:      id      - structure type ID
//                         comment - new comment of the structure
//                         repeatable - 1: change repeatable comment
//                                      0: change regular comment
//         returns:        !=0 - ok

long SetStrucComment(long id, string comment, long repeatable);

// ***********************************************
// Add structure member.
//
// This function can be used in two forms.
// First form:
// long AddStrucMember(long id, string name, long offset, long flag,
//                     long typeid, long nbytes);
// Second form:
// long AddStrucMember(long id, string name, long offset, long flag,
//                     long typeid, long nbytes,
//                     long target, long tdelta, long reftype);
//
// arguments:
//   id      - structure type ID
//   name    - name of the new member
//   offset  - offset of the new member
//             -1 means to add at the end of the structure
//   flag    - type of the new member. Should be one of
//             FF_BYTE..FF_PACKREAL (see above)
//             combined with FF_DATA
//   typeid  - if isStruc(flag) then typeid specifies
//             the structure id for the member
//             if isOff0(flag) then typeid specifies
//             the offset base.
//             if isASCII(flag) then typeid specifies
//             the string type (ASCSTR_...).
//             if isStroff(flag) then typeid specifies
//             the structure id
//             if isCustom(flags) then typeid specifies
//             the dtid and fid: dtid|(fid<<16)
//             if isEnum(flag) then typeid specifies
//             the enum id
//             Otherwise typeid should be -1
//   nbytes  - number of bytes in the new member
// the remaining arguments are allowed only if isOff0(flag) and you want
// to specify a complex offset expression
//   target  - target address of the offset expr. You may specify it as
//             -1, ida will calculate it itself
//   tdelta  - offset target delta. usually 0
//   reftype - see REF_... definitions
// returns: 0 - ok, otherwise error code:
#endif

// Constants used with BeginTypeUpdating() and EndTypeUpdating()
#define UTP_ENUM      0
#define UTP_STRUCT    1

#define STRUC_ERROR_MEMBER_NAME    (-1) // already has member with this name (bad name)
#define STRUC_ERROR_MEMBER_OFFSET  (-2) // already has member at this offset
#define STRUC_ERROR_MEMBER_SIZE    (-3) // bad number of bytes or bad sizeof(type)
#define STRUC_ERROR_MEMBER_TINFO   (-4) // bad typeid parameter
#define STRUC_ERROR_MEMBER_STRUCT  (-5) // bad struct id (the 1st argument)
#define STRUC_ERROR_MEMBER_UNIVAR  (-6) // unions can't have variable sized members
#define STRUC_ERROR_MEMBER_VARLAST (-7) // variable sized member should be the last member in the structure
#ifdef _notdefinedsymbol
long AddStrucMember(long id, string name, long offset, long flag, long typeid, long nbytes,
                    long target, long tdelta, long reftype);

// ***********************************************
// ** delete structure member
//         arguments:      id            - structure type ID
//                         member_offset - offset of the member
//         returns:        !=0 - ok.
//                         NOTE: IDA allows 'holes' between members of a
//                               structure. It treats these 'holes'
//                               as unnamed arrays of bytes.

long DelStrucMember(long id, long member_offset);

// ***********************************************
// ** change structure member name
//         arguments:      id            - structure type ID
//                         member_offset - offset of the member
//                         name          - new name of the member
//         returns:        !=0 - ok.

long SetMemberName(long id, long member_offset, string name);

// ***********************************************
// Change structure member type.
//
// This function can be used in two forms.
// First form:
// long SetMemberType(long id, long member_offset, long flag, long typeid, long nitems);
//
// Second form:
// long SetMemberType(long id, long member_offset, long flag, long typeid, long nitems,
//                     long target, long tdelta, long reftype);
//
// arguments:
//   id            - structure type ID
//   member_offset - offset of the member
//   flag    - new type of the member. Should be one of
//             FF_BYTE..FF_PACKREAL (see above)
//             combined with FF_DATA
//   typeid  - if isStruc(flag) then typeid specifies
//             the structure id for the member
//             if isOff0(flag) then typeid specifies
//             the offset base.
//             if isASCII(flag) then typeid specifies
//             the string type (ASCSTR_...).
//             if isStroff(flag) then typeid specifies
//             the structure id
//             if isEnum(flag) then typeid specifies
//             the enum id
//             if isCustom(flags) then typeid specifies
//             the dtid and fid: dtid|(fid<<16)
//             Otherwise typeid should be -1
//   nitems  - number of items in the member
// the remaining arguments are allowed only if isOff0(flag) and you want
// to specify a complex offset expression:
//   target  - target address of the offset expr. You may specify it as
//             -1, ida will calculate it itself
//   tdelta  - offset target delta. usually 0
//   reftype - see REF_... definitions
// returns:        !=0 - ok.
long SetMemberType(long id, long member_offset, long flag, long typeid, long nitems,
                    long target, long tdelta, long reftype);

// ***********************************************
// ** change structure member comment
//         arguments:      id      - structure type ID
//                         member_offset - offset of the member
//                         comment - new comment of the structure member
//                         repeatable - 1: change repeatable comment
//                                      0: change regular comment
//         returns:        !=0 - ok

long SetMemberComment(long id, long member_offset, string comment, long repeatable);

// ----------------------------------------------------------------------------
//                          E N U M S
// ----------------------------------------------------------------------------

// ***********************************************
// ** get number of enum types
//         arguments:      none
//         returns:        number of enumerations

long GetEnumQty(void);

// ***********************************************
// ** get ID of the specified enum by its serial number
//         arguments:      idx - number of enum (0..GetEnumQty()-1)
//         returns:        ID of enum or -1 if error

long GetnEnum(long idx);


// ***********************************************
// ** get serial number of enum by its ID
//         arguments:      enum_id - ID of enum
//         returns:        (0..GetEnumQty()-1) or -1 if error

long GetEnumIdx(long enum_id);

// ***********************************************
// ** get enum ID by the name of enum
//         arguments:      name - name of enum
//         returns:        ID of enum or -1 if no such enum exists

long GetEnum(string name);

// ***********************************************
// ** get name of enum
//         arguments:      enum_id - ID of enum
//         returns:        name of enum or empty string

string GetEnumName(long enum_id);

// ***********************************************
// ** get comment of enum
//         arguments:      enum_id - ID of enum
//                         repeatable - 0:get regular comment
//                                      1:get repeatable comment
//         returns:        comment of enum

string GetEnumCmt(long enum_id, long repeatable);

// ***********************************************
// ** get size of enum
//         arguments:      enum_id - ID of enum
//         returns:        number of constants in the enum
//                         Returns 0 if enum_id is bad.

long GetEnumSize(long enum_id);

// ***********************************************
// ** get width of enum elements
//         arguments:      enum_id - ID of enum
//         returns:        log2(size of enum elements in bytes)+1
//                         possible returned values are 1..7
//                         1-1byte,2-2bytes,3-4bytes,4-8bytes,etc
//                         Returns 0 if enum_id is bad or the width is unknown.

long GetEnumWidth(long enum_id);

// ***********************************************
// ** get flag of enum
//         arguments:      enum_id - ID of enum
//         returns:        flags of enum. These flags determine representation
//                         of numeric constants (binary,octal,decimal,hex)
//                         in the enum definition. See start of this file for
//                         more information about flags.
//                         Returns 0 if enum_id is bad.

long GetEnumFlag(long enum_id);


// ***********************************************
// ** get member of enum - a symbolic constant ID
//         arguments:      name - name of symbolic constant
//         returns:        ID of constant or -1

long GetConstByName(string name);

// ***********************************************
// ** get value of symbolic constant
//         arguments:      const_id - id of symbolic constant
//         returns:        value of constant or 0

long GetConstValue(long const_id);

// ***********************************************
// ** get bit mask of symbolic constant
//         arguments:      const_id - id of symbolic constant
//         returns:        bitmask of constant or 0
//                         ordinary enums have bitmask = -1

long GetConstBmask(long const_id);

// ***********************************************
// ** get id of enum by id of constant
//         arguments:      const_id - id of symbolic constant
//         returns:        id of enum the constant belongs to.
//                         -1 if const_id is bad.

long GetConstEnum(long const_id);

// ***********************************************
// ** get id of constant
//         arguments:      enum_id - id of enum
//                         value   - value of constant
//                         serial  - serial number of the constant in the
//                                   enumeration. See OpEnumEx() for
//                                   for details.
//                         bmask   - bitmask of the constant
//                                   ordinary enums accept only -1 as a bitmask
//         returns:        id of constant or -1 if error

long GetConstEx(long enum_id, long value, long serial, long bmask);


// ***********************************************
// ** get first bitmask in the enum (bitfield)
//         arguments:      enum_id - id of enum (bitfield)
//         returns:        the smallest bitmask of constant or -1
//                         no bitmasks are defined yet
//                         All bitmasks are sorted by their values
//                         as unsigned longs.

long GetFirstBmask(long enum_id);

// ***********************************************
// ** get last bitmask in the enum (bitfield)
//         arguments:      enum_id - id of enum
//         returns:        the biggest bitmask or -1 no bitmasks are defined yet
//                         All bitmasks are sorted by their values
//                         as unsigned longs.

long GetLastBmask(long enum_id);

// ***********************************************
// ** get next bitmask in the enum (bitfield)
//         arguments:      enum_id - id of enum
//                         bmask   - value of the current bitmask
//         returns:        value of a bitmask with value higher than the specified
//                         value. -1 if no such bitmasks exist.
//                         All bitmasks are sorted by their values
//                         as unsigned longs.

long GetNextBmask(long enum_id, long value);

// ***********************************************
// ** get prev bitmask in the enum (bitfield)
//         arguments:      enum_id - id of enum
//                         value   - value of the current bitmask
//         returns:        value of a bitmask with value lower than the specified
//                         value. -1 no such bitmasks exist.
//                         All bitmasks are sorted by their values
//                         as unsigned longs.

long GetPrevBmask(long enum_id, long value);

// ***********************************************
// ** get bitmask name (only for bitfields)
//         arguments:      enum_id - id of enum
//                         bmask   - bitmask of the constant
//         returns:        name of bitmask if it exists. otherwise returns 0.

long GetBmaskName(long enum_id, long bmask);

// ***********************************************
// ** get bitmask comment (only for bitfields)
//         arguments:      enum_id - id of enum
//                         bmask   - bitmask of the constant
//                         repeatable - type of comment, 0-regular, 1-repeatable
//         returns:        comment attached to bitmask if it exists.
//                         otherwise returns 0.

long GetBmaskCmt(long enum_id, long bmask, long repeatable);

// ***********************************************
// ** set bitmask name (only for bitfields)
//         arguments:      enum_id - id of enum
//                         bmask   - bitmask of the constant
//                         name    - name of bitmask
//         returns:        1-ok, 0-failed

success SetBmaskName(long enum_id, long bmask, string name);

// ***********************************************
// ** set bitmask comment (only for bitfields)
//         arguments:      enum_id - id of enum
//                         bmask   - bitmask of the constant
//                         cmt     - comment
//                         repeatable - type of comment, 0-regular, 1-repeatable
//         returns:        1-ok, 0-failed

long SetBmaskCmt(long enum_id, long bmask, string cmt, long repeatable);

// ***********************************************
// ** get first constant in the enum
//         arguments:      enum_id - id of enum
//                         bmask   - bitmask of the constant
//                                   ordinary enums accept only -1 as a bitmask
//         returns:        value of constant or -1 no constants are defined
//                         All constants are sorted by their values
//                         as unsigned longs.

long GetFirstConst(long enum_id, long bmask);

// ***********************************************
// ** get last constant in the enum
//         arguments:      enum_id - id of enum
//                         bmask   - bitmask of the constant
//                                   ordinary enums accept only -1 as a bitmask
//         returns:        value of constant or -1 no constants are defined
//                         All constants are sorted by their values
//                         as unsigned longs.

long GetLastConst(long enum_id, long bmask);

// ***********************************************
// ** get next constant in the enum
//         arguments:      enum_id - id of enum
//                         bmask   - bitmask of the constant
//                                   ordinary enums accept only -1 as a bitmask
//                         value   - value of the current constant
//         returns:        value of a constant with value higher than the specified
//                         value. -1 no such constants exist.
//                         All constants are sorted by their values
//                         as unsigned longs.

long GetNextConst(long enum_id, long value, long bmask);

// ***********************************************
// ** get prev constant in the enum
//         arguments:      enum_id - id of enum
//                         bmask   - bitmask of the constant
//                                   ordinary enums accept only -1 as a bitmask
//                         value   - value of the current constant
//         returns:        value of a constant with value lower than the specified
//                         value. -1 no such constants exist.
//                         All constants are sorted by their values
//                         as unsigned longs.

long GetPrevConst(long enum_id, long value, long bmask);

// ***********************************************
// ** get name of a constant
//         arguments:      const_id - id of const
//         returns:        name of constant

string GetConstName(long const_id);

// ***********************************************
// ** get comment of a constant
//         arguments:      const_id - id of const
//                         repeatable - 0:get regular comment
//                                      1:get repeatable comment
//         returns:        comment string

string GetConstCmt(long const_id, long repeatable);

// ***********************************************
// ** add a new enum type
//         arguments:      idx - serial number of the new enum.
//                               If another enum with the same serial number
//                               exists, then all enums with serial
//                               numbers >= the specified idx get their
//                               serial numbers incremented (in other words,
//                               the new enum is put in the middle of the list
//                               of enums).
//                               If idx >= GetEnumQty() or idx == -1
//                               then the new enum is created at the end of
//                               the list of enums.
//                         name - name of the enum.
//                         flag - flags for representation of numeric constants
//                                in the definition of enum.
//         returns:        id of new enum or -1.

long AddEnum(long idx, string name, long flag);

// ***********************************************
// ** delete enum type
//         arguments:      enum_id - id of enum

void DelEnum(long enum_id);

// ***********************************************
// ** give another serial number to a enum
//         arguments:      enum_id - id of enum
//                         idx     - new serial number.
//                               If another enum with the same serial number
//                               exists, then all enums with serial
//                               numbers >= the specified idx get their
//                               serial numbers incremented (in other words,
//                               the new enum is put in the middle of the list
//                               of enums).
//                               If idx >= GetEnumQty() then the enum is
//                               moved to the end of the list of enums.
//         returns:        comment string

success SetEnumIdx(long enum_id, long idx);

// ***********************************************
// ** rename enum
//         arguments:      enum_id - id of enum
//                         name    - new name of enum
//         returns:        1-ok, 0-failed

success SetEnumName(long enum_id, string name);

// ***********************************************
// ** set comment of enum
//         arguments:      enum_id - id of enum
//                         cmt     - new comment for the enum
//                         repeatable - 0:set regular comment
//                                      1:set repeatable comment
//         returns:        1-ok, 0-failed

success SetEnumCmt(long enum_id, string cmt, long repeatable);

// ***********************************************
// ** set flag of enum
//         arguments:      enum_id - id of enum
//                         flag - flags for representation of numeric constants
//                                in the definition of enum.
//         returns:        1-ok, 0-failed

success SetEnumFlag(long enum_id, long flag);

// ***********************************************
// ** set bitfield property of enum
//         arguments:      enum_id - id of enum
//                         flag - 1: convert to bitfield
//                                0: convert to ordinary enum
//         returns:        1-ok, 0-failed

success SetEnumBf(long enum_id, long flag);

// ***********************************************
// ** set width of enum elements
//         arguments:      enum_id - id of enum
//                         width - element width in bytes
//                                 allowed values: 0-unknown
//                                 or 1..7: (log2 of the element size)+1
//         returns:        1-ok, 0-failed

success SetEnumWidth(long enum_id, long width);

// ***********************************************
// ** is enum a bitfield?
//         arguments:      enum_id - id of enum
//         returns:        1-yes, 0-no, ordinary enum

success IsBitfield(long enum_id);

// ***********************************************
// ** add a member of enum - a symbolic constant
//         arguments:      enum_id - id of enum
//                         name    - name of symbolic constant. Must be unique
//                                   in the program.
//                         value   - value of symbolic constant.
//                         bmask   - bitmask of the constant
//                                   ordinary enums accept only -1 as a bitmask
//                                   all bits set in value should be set in bmask too
//         returns:        0-ok, otherwise error code:
#endif
#define CONST_ERROR_NAME  1     // already have member with this name (bad name)
#define CONST_ERROR_VALUE 2     // already have member with this value
#define CONST_ERROR_ENUM  3     // bad enum id
#define CONST_ERROR_MASK  4     // bad bmask
#define CONST_ERROR_ILLV  5     // bad bmask and value combination (~bmask & value != 0)
#ifdef _notdefinedsymbol

long AddConstEx(long enum_id, string name, long value, long bmask);

// ***********************************************
// ** delete a member of enum - a symbolic constant
//         arguments:      enum_id - id of enum
//                         value   - value of symbolic constant.
//                         serial  - serial number of the constant in the
//                                   enumeration. See OpEnumEx() for
//                                   for details.
//                         bmask   - bitmask of the constant
//                                   ordinary enums accept only -1 as a bitmask
//         returns:        1-ok, 0-failed

success DelConstEx(long enum_id, long value, long serial, long bmask);

// ***********************************************
// ** rename a member of enum - a symbolic constant
//         arguments:      const_id - id of const
//                         name     - new name of constant
//         returns:        1-ok, 0-failed

success SetConstName(long const_id, string name);

// ***********************************************
// ** set a comment of a symbolic constant
//         arguments:      const_id - id of const
//                         cmt     - new comment for the constant
//                         repeatable - 0:set regular comment
//                                      1:set repeatable comment
//         returns:        1-ok, 0-failed

success SetConstCmt(long const_id, string cmt, long repeatable);

// ----------------------------------------------------------------------------
//                          A R R A Y S  I N  I D C
// ----------------------------------------------------------------------------

// The following functions allow you to manipulate arrays in IDC.
// They have nothing to do with arrays in the disassembled program.
// The IDC arrays are persistent and are kept in the database.
// They remain until you explicitly delete them using DeleteArray().
//
// The arrays are virtual. IDA allocates space for and keeps only the specified
// elements of an array. The array index is 32-bit long. Actually, each array
// may keep a set of strings and a set of long(32bit or 64bit) values.

// ***********************************************
// ** create array
//         arguments:      name - name of array. There are no restrictions
//                                on the name (its length should be less than
//                                120 characters, though)
//         returns:        -1 - can't create array (it already exists)
//                         otherwise returns id of the array

long CreateArray(string name);


// ***********************************************
// ** get array id by its name
//         arguments:      name - name of existing array.
//         returns:        -1 - no such array
//                         otherwise returns id of the array

long GetArrayId(string name);


// ***********************************************
// ** rename array
//         arguments:      id      - array id returned by CreateArray() or
//                                   GetArrayId()
//                         newname - new name of array. There are no
//                                   restrictions on the name (its length should
//                                   be less than 120 characters, though)
//         returns:        1-ok, 0-failed

success RenameArray(long id, string newname);


// ***********************************************
// ** delete array
//    This function deletes all elements of the array.
//         arguments:      id      - array id

void DeleteArray(long id);


// ***********************************************
// ** set long value of array element.
//         arguments:      id      - array id
//                         idx     - index of an element
//                         value   - 32bit or 64bit value to store in the array
//         returns:        1-ok, 0-failed

success SetArrayLong(long id, long idx, long value);


// ***********************************************
// ** set string value of array element
//         arguments:      id      - array id
//                         idx     - index of an element
//                         str     - string to store in array element
//         returns:        1-ok, 0-failed

success SetArrayString(long id, long idx, string str);


// ***********************************************
// ** get value of array element
//         arguments:      tag     - tag of array, specifies one of two
//                                   array types:
#endif
#define AR_LONG 'A'     // array of longs
#define AR_STR  'S'     // array of strings
#ifdef _notdefinedsymbol
//                         id      - array id
//                         idx     - index of an element
//         returns:        value of the specified array element.
//                         note that this function may return char or long
//                         result. Unexistent array elements give zero as
//                         a result.

string or long GetArrayElement(long tag, long id, long idx);


// ***********************************************
// ** delete an array element
//         arguments:      tag     - tag of array (AR_LONG or AR_STR)
//                         id      - array id
//                         idx     - index of an element
//         returns:        1-ok, 0-failed

success DelArrayElement(long tag, long id, long idx);


// ***********************************************
// ** get index of the first existing array element
//         arguments:      tag     - tag of array (AR_LONG or AR_STR)
//                         id      - array id
//         returns:        -1 - array is empty
//                         otherwise returns index of the first array element

long GetFirstIndex(long tag, long id);


// ***********************************************
// ** get index of the last existing array element
//         arguments:      tag     - tag of array (AR_LONG or AR_STR)
//                         id      - array id
//         returns:        -1 - array is empty
//                         otherwise returns index of the last array element

long GetLastIndex(long tag, long id);


// ***********************************************
// ** get index of the next existing array element
//         arguments:      tag     - tag of array (AR_LONG or AR_STR)
//                         id      - array id
//                         idx     - index of the current element
//         returns:        -1 - no more array elements
//                         otherwise returns index of the next array element

long GetNextIndex(long tag, long id, long idx);


// ***********************************************
// ** get index of the previous existing array element
//         arguments:      tag     - tag of array (AR_LONG or AR_STR)
//                         id      - array id
//                         idx     - index of the current element
//         returns:        -1 - no more array elements
//                         otherwise returns index of the previous array element

long GetPrevIndex(long tag, long id, long idx);


// ***********************************************
// ** associative arrays (the same as hashes in Perl)
// ** to create a hash, use CreateArray() function
// ** you can use the following function with hashes:
// **      GetArrayId(), RenameArray(), DeleteArray()
// ** The following additional functions are defined:

success SetHashLong(long id, string idx, long value);
success SetHashString(long id, string idx, string value);
long    GetHashLong(long id, string idx);
string  GetHashString(long id, string idx);
success DelHashElement(long id, string idx);
string  GetFirstHashKey(long id);
string  GetNextHashKey(long id, string idx);
string  GetLastHashKey(long id);
string  GetPrevHashKey(long id, string idx);

// ----------------------------------------------------------------------------
//                 S O U R C E   F I L E / L I N E   N U M B E R S
// ----------------------------------------------------------------------------
//
//   IDA can keep information about source files used to create the program.
//   Each source file is represented by a range of addresses.
//   A source file may contains several address ranges.

// ***********************************************
// ** Mark a range of address as belonging to a source file
//    An address range may belong only to one source file.
//    A source file may be represented by several address ranges.
//         ea1     - linear address of start of the address range
//         ea2     - linear address of end of the address range
//         filename- name of source file.
//    returns: 1-ok, 0-failed.

success AddSourceFile(long ea1, ulong ea2, string filename);


// ***********************************************
// ** Get name of source file occupying the given address
//         ea - linear address
//    returns: NULL - source file information is not found
//             otherwise returns pointer to file name

string GetSourceFile(long ea);


// ***********************************************
// ** Delete information about the source file
//         ea - linear address belonging to the source file
//    returns: NULL - source file information is not found
//             otherwise returns pointer to file name

success DelSourceFile(long ea);


// ***********************************************
// ** set source line number
//         arguments:      ea      - linear address
//                         lnnum   - number of line in the source file
//         returns:        nothing

void SetLineNumber(long ea, long lnnum);


// ***********************************************
// ** get source line number
//         arguments:      ea      - linear address
//         returns:        number of line in the source file or -1

long GetLineNumber(long ea);


// ***********************************************
// ** delete information about source line number
//         arguments:      ea      - linear address
//         returns:        nothing

void DelLineNumber(long ea);


// ----------------------------------------------------------------------------
//                 T Y P E  L I B R A R I E S
// ----------------------------------------------------------------------------

// ***********************************************
// ** Load a type library
//         name - name of type library.
//    returns: 1-ok, 0-failed.

success LoadTil(string name);


// ***********************************************
// ** Copy information from type library to database
//    Copy structure, union, or enum definition from the type library
//    to the IDA database.
//         idx       - the position of the new type in the list of
//                     types (structures or enums)
//                     -1 means at the end of the list
//         type_name - name of type to copy
//    returns: BADNODE-failed, otherwise the type id
//                 (structure id or enum id)

long Til2Idb(long idx, string type_name);


// ***********************************************
// ** Get type of function/variable
//         ea - the address of the object
//    returns: type string, 0 - failed

string GetType(long ea);


// ***********************************************
// ** Get type information of function/variable as 'typeinfo' object
//         ea - the address of the object
//    returns: typeinfo object, 0 - failed
// The typeinfo object has 2 attributes: type and fields

typeinfo GetTinfo(long ea);


// ***********************************************
// ** Guess type of function/variable
//         ea - the address of the object.
//              can be the structure member id too
//    returns: type string, 0 - failed

string GuessType(long ea);


// ***********************************************
// ** Set type of function/variable
//         ea   - the address of the object
//         type - the type string in C declaration form.
//                must contain the closing ';'
//                if specified as an empty string, then the type
//                assciated with 'ea' will be deleted
//    returns: 1-ok, 0-failed.

success SetType(long ea, string type);


// ***********************************************
// ** Parse many type declarations
//         input -  file name or C declarations (depending on the flags)
//         flags -  combination of PT_... constants or 0
//    returns: number of errors

long ParseTypes(string input, long flags);

// ***********************************************
// ** Parse one type declaration
//         input -  a C declaration
//         flags -  combination of PT_... constants or 0
//                  PT_FILE should not be specified in flags (it is ignored)
//    returns: typeinfo object or num 0

typeinfo ParseType(string input, long flags);

#endif
#define PT_FILE   0x0001  // input if a file name (otherwise contains type declarations)
#define PT_SILENT 0x0002  // silent mode
#define PT_PAKDEF 0x0000  // default pack value
#define PT_PAK1   0x0010  // #pragma pack(1)
#define PT_PAK2   0x0020  // #pragma pack(2)
#define PT_PAK4   0x0030  // #pragma pack(4)
#define PT_PAK8   0x0040  // #pragma pack(8)
#define PT_PAK16  0x0050  // #pragma pack(16)
#ifdef _notdefinedsymbol

// ***********************************************
// Calculate the size of a type
//      type - type to calculate the size of
//             can be specified as a typeinfo object (e.g. the result of GetTinfo())
//             or a string with C declaration (e.g. "int")
// Returns: size of the type or -1 if error

long sizeof(typeinfo type);


// ***********************************************
// ** Get number of local types + 1
//    returns: value >= 1. 1 means that there are no local types.

long GetMaxLocalType(void);


// ***********************************************
// ** Parse one type declaration and store it in the specified slot
//         ordinal -  slot number (1...NumberOfLocalTypes)
//                    -1 means allocate new slot or reuse the slot
//                    of the existing named type
//         input -  C declaration. Empty input empties the slot
//         flags -  combination of PT_... constants or 0
//    returns: slot number or 0 if error

success SetLocalType(long ordinal, string input, long flags);


// ***********************************************
// ** Retrieve a local type declaration
//         ordinal -  slot number (1...NumberOfLocalTypes)
//    returns: local type as a C declaration or ""

string GetLocalType(long ordinal, long flags);
#endif
#define PRTYPE_1LINE  0x0000 // print to one line
#define PRTYPE_MULTI  0x0001 // print to many lines
#define PRTYPE_TYPE   0x0002 // print type declaration (not variable declaration)
#define PRTYPE_PRAGMA 0x0004 // print pragmas for alignment
#ifdef _notdefinedsymbol


// ***********************************************
// ** Retrieve a local type name
//         ordinal -  slot number (1...NumberOfLocalTypes)
//    returns: local type name or ""

string GetLocalTypeName(long ordinal);


// Format value(s) as a C/C++ data initializers
//      outvec - reference to the output object
//               after the call will contain array of strings
//      value  - value to format
//      type   - type of the data to format
//      options- optional object, which may have the following attributes:
//                      'ptvf' - combination of PTV_... constants:
#endif
#define PTV_DEREF  0x0001  // take value to print from the database.
                           // its address is specifed by value.num (default)
#define PTV_QUEST  0x0002  // print '?' for uninited data
#define PTV_EMPTY  0x0004  // return empty string for uninited data (default)
#define PTV_CSTR   0x0008  // print constant strings inline (default)
#define PTV_EXPAND 0x0010  // print only top level on separate lines
                           // max_length applies to separate lines
                           // margin is ignored
#define PTV_LZHEX  0x0020  // print hex numbers with leading zeroes
#define PTV_STPFLT 0x0040  // fail on bad floating point numbers
                           // (if not set, just print ?flt for them)
#define PTV_SPACE  0x0080  // add spaces after commas and around braces (default)
#define PTV_DEBUG  0x0100  // format output for debugger
#ifdef _notdefinedsymbol
//                      'flags'      number representation (e.g. hexflag(), decflags(), etc)
//                      'max_length' max length of the formatted text (0 means no limit)
//                      'arrbase'    for arrays: the first element of array to print
//                      'arrnelems'  for arrays: number of elements to print
//                      'margin'     length of one line (0 means to print everything on one line)
//                      'indent'     how many spaces to use to indent nested structures/arrays
//      info   - object to store additional information about the generated lines
//               after the call will contain array of objects, each of which has:
//                      'ea' - address of the line
//                      'type' - typeinfo of the line (may include label for the line as 'name')
//               may be specified as 0 if this info is not required
// Returns: error code

long FormatCData(object &outvec, anyvalue value, typeinfo type, object options, object &info);


// ----------------------------------------------------------------------------
//                           H I D D E N  A R E A S
// ----------------------------------------------------------------------------

// Hidden areas - address ranges which can be replaced by their descriptions

// ***********************************************
// ** hide an area
//    arguments:
//         start,end   - area boundaries
//         description - description to display if the area is collapsed
//         header      - header lines to display if the area is expanded
//         footer      - footer lines to display if the area is expanded
//         visible     - the area state
//         color       - RGB color code (-1 means default color)
//    returns:        !=0 - ok

success HideArea(long start, long end, string description, string header, string footer, long color);


// ***********************************************
// ** set hidden area state
//    arguments:
//         ea      - any address belonging to the hidden area
//         visible - new state of the area
//    returns: !=0 - ok

success SetHiddenArea(long ea, long visible);


// ***********************************************
// ** delete a hidden area
//    arguments:      ea - any address belonging to the hidden area
//    returns:        !=0 - ok

success DelHiddenArea(long ea);


// ----------------------------------------------------------------------------
//                           D E B U G G E R  I N T E R F A C E
// ----------------------------------------------------------------------------

// ***********************************************
// ** Load the debugger
//    arguments:
//         dbgname - debugger module name
//                   Examples: win32, linux, mac.
//         use_remote - 0/1: use remote debugger or not
// This function is needed only when running idc scripts from the command line.
// In other cases IDA loads the debugger module automatically.

success LoadDebugger(string dbgname, long use_remote);


// ***********************************************
// ** Launch the debugger
//    arguments:
//         path - path to the executable file.
//         args - command line arguments
//         sdir - initial directory for the process
// for all args: if empty, the default value from the database will be used
//    returns: -1-failed, 0-cancelled by the user, 1-ok
// See the important note to the StepInto() function

long StartDebugger(string path, string args, string sdir);


// ***********************************************
// ** Stop the debugger
// Kills the currently debugger process and returns to the disassembly mode
//    arguments: none
//    returns: success

success StopDebugger(void);


// ***********************************************
// ** Suspend the running process
// Tries to suspend the process. If successful, the PROCESS_SUSPEND
// debug event will arrive (see GetDebuggerEvent)
//    arguments: none
//    returns: success
// To resume a suspended process use the GetDebuggerEvent function.
// See the important note to the StepInto() function

success PauseProcess(void);


// ***********************************************
// Take a snapshot of running processes and return their number.

long GetProcessQty(void);

// ***********************************************
// Get information about a running process
//      idx - number of process, is in range 0..GetProcessQty()-1
// returns: 0 if failure

long GetProcessPid(long idx);
string GetProcessName(long idx);


// ***********************************************
// Attach the debugger to a running process
//     pid - PID of the process to attach to. If NO_PROCESS, a dialog box
//           will interactively ask the user for the process to attach to.
//     event_id - reserved, must be -1
// returns:
//         -2 - impossible to find a compatible process
//         -1 - impossible to attach to the given process (process died, privilege
//              needed, not supported by the debugger plugin, ...)
//          0 - the user cancelled the attaching to the process
//          1 - the debugger properly attached to the process
// See the important note to the StepInto() function

long AttachProcess(long pid, long event_id);


// ***********************************************
// Detach the debugger from the debugged process.

success DetachProcess(void);


// ***********************************************
// Get number of threads.

long GetThreadQty(void);


// ***********************************************
// Get the ID of a thread
//     idx - number of thread, is in range 0..GetThreadQty()-1
// returns: -1 if failure

long GetThreadId(long idx);


// ***********************************************
// Get current thread ID
// returns: -1 if failure

long GetCurrentThreadId(void);


// ***********************************************
// Select the given thread as the current debugged thread.
//     tid - ID of the thread to select
// The process must be suspended to select a new thread.
// returns: success

success SelectThread(long tid);


// ***********************************************
// Suspend thread
// Suspending a thread may deadlock the whole application if the suspended
// was owning some synchronization objects.
//     tid - thread id
// Return: -1:network error, 0-failed, 1-ok

long SuspendThread(long tid);


// ***********************************************
// Resume thread
//     tid - thread id
// Return: -1:network error, 0-failed, 1-ok

long ResumeThread(long tid);


// ***********************************************
// Enumerate process modules
// These function return the module base address

long GetFirstModule(void);
long GetNextModule(long base);


// ***********************************************
// Get process module name
//      base - the base address of the module
// returns: required info

string GetModuleName(long base);


// ***********************************************
// Get process module size
//      base - the base address of the module
// returns: required info or -1

long GetModuleSize(long base);


// ***********************************************
// Execute one instruction in the current thread.
// Other threads are kept suspended.
//
// NOTE
//   You must call GetDebuggerEvent() after this call
//   in order to find out what happened. Normally you will
//   get the STEP event but other events are possible (for example,
//   an exception might occur or the process might exit).
//   This remark applies to all execution control functions.
//   The event codes depend on the issued command.
// returns: success

success StepInto(void);


// ***********************************************
// Execute one instruction in the current thread,
// but without entering into functions
// Others threads keep suspended.
// See the important note to the StepInto() function

success StepOver(void);


// ***********************************************
// Execute the process until the given address is reached.
// If no process is active, a new process is started.
// See the important note to the StepInto() function

success RunTo(long ea);


// ***********************************************
// Execute instructions in the current thread until
// a function return instruction is reached.
// Other threads are kept suspended.
// See the important note to the StepInto() function

success StepUntilRet(void);


// ***********************************************
// Wait for the next event
// This function (optionally) resumes the process
// execution and wait for a debugger event until timeout
//      wfne - combination of WFNE_... constants
//      timeout - number of seconds to wait, -1-infinity
// returns: debugger event codes, see below

long GetDebuggerEvent(long wfne, long timeout);

#endif
// convenience function
#define ResumeProcess() GetDebuggerEvent(WFNE_CONT|WFNE_NOWAIT, 0)
// wfne flag is combination of the following:
#define WFNE_ANY    0x0001 // return the first event (even if it doesn't suspend the process)
                           // if the process is still running, the database
                           // does not reflect the memory state. you might want
                           // to call RefreshDebuggerMemory() in this case
#define WFNE_SUSP   0x0002 // wait until the process gets suspended
#define WFNE_SILENT 0x0004 // 1: be slient, 0:display modal boxes if necessary
#define WFNE_CONT   0x0008 // continue from the suspended state
#define WFNE_NOWAIT 0x0010 // do not wait for any event, immediately return DEC_TIMEOUT
                           // (to be used with WFNE_CONT)
#define WFNE_USEC   0x0020 // timeout is specified in microseconds
                           // (minimum non-zero timeout is 40000us)

// debugger event codes
#define NOTASK         -2         // process does not exist
#define DBG_ERROR      -1         // error (e.g. network problems)
#define DBG_TIMEOUT     0         // timeout
#define PROCESS_START  0x00000001 // New process started
#define PROCESS_EXIT   0x00000002 // Process stopped
#define THREAD_START   0x00000004 // New thread started
#define THREAD_EXIT    0x00000008 // Thread stopped
#define BREAKPOINT     0x00000010 // Breakpoint reached
#define STEP           0x00000020 // One instruction executed
#define EXCEPTION      0x00000040 // Exception
#define LIBRARY_LOAD   0x00000080 // New library loaded
#define LIBRARY_UNLOAD 0x00000100 // Library unloaded
#define INFORMATION    0x00000200 // User-defined information
#define SYSCALL        0x00000400 // Syscall (not used yet)
#define WINMESSAGE     0x00000800 // Window message (not used yet)
#define PROCESS_ATTACH 0x00001000 // Attached to running process
#define PROCESS_DETACH 0x00002000 // Detached from process
#define PROCESS_SUSPEND 0x00004000 // Process has been suspended
#ifdef _notdefinedsymbol


// ***********************************************
// Refresh debugger memory
// Upon this call IDA will forget all cached information
// about the debugged process. This includes the segmentation
// information and memory contents (register cache is managed
// automatically). Also, this function refreshes exported name
// from loaded DLLs.
// You must call this function before using the segmentation
// information, memory contents, or names of a non-suspended process.
// This is an expensive call.

void RefreshDebuggerMemory(void);


// ***********************************************
// Take memory snapshot of the debugged process
//      only_loader_segs: 0-copy all segments to idb
//                        1-copy only SFL_LOADER segments

success TakeMemorySnapshot(long only_loader_segs);


// ***********************************************
// Get debugged process state
// returns: one of the DSTATE_... constants (see below)

long GetProcessState(void);

#endif
#define DSTATE_SUSP             -1 // process is suspended
#define DSTATE_NOTASK            0 // no process is currently debugged
#define DSTATE_RUN               1 // process is running
#ifdef _notdefinedsymbol


// ***********************************************
// Get various information about the current debug event
// These function are valid only when the current event exists
// (the process is in the suspended state)

// For all events:
long GetEventId(void);
long GetEventPid(void);
long GetEventTid(void);
long GetEventEa(void);
long IsEventHandled(void);

// For PROCESS_START, PROCESS_ATTACH, LIBRARY_LOAD events:
string GetEventModuleName(void);
long GetEventModuleBase(void);
long GetEventModuleSize(void);

// For PROCESS_EXIT, THREAD_EXIT events
long GetEventExitCode(void);

// For LIBRARY_UNLOAD (unloaded library name)
// For INFORMATION (message to display)
string GetEventInfo(void);

// For BREAKPOINT event
long GetEventBptHardwareEa(void);

// For EXCEPTION event
long GetEventExceptionCode(void);
long GetEventExceptionEa(void);
long CanExceptionContinue(void);
string GetEventExceptionInfo(void);


// ***********************************************
// Get/set debugger options
//      opt - combination of DOPT_... constants
// returns: old options

long SetDebuggerOptions(long opt);
#endif
#define DOPT_SEGM_MSGS    0x00000001 // print messages on debugger segments modifications
#define DOPT_START_BPT    0x00000002 // break on process start
#define DOPT_THREAD_MSGS  0x00000004 // print messages on thread start/exit
#define DOPT_THREAD_BPT   0x00000008 // break on thread start/exit
#define DOPT_BPT_MSGS     0x00000010 // print message on breakpoint
#define DOPT_LIB_MSGS     0x00000040 // print message on library load/unlad
#define DOPT_LIB_BPT      0x00000080 // break on library load/unlad
#define DOPT_INFO_MSGS    0x00000100 // print message on debugging information
#define DOPT_INFO_BPT     0x00000200 // break on debugging information
#define DOPT_REAL_MEMORY  0x00000400 // don't hide breakpoint instructions
#define DOPT_REDO_STACK   0x00000800 // reconstruct the stack
#define DOPT_ENTRY_BPT    0x00001000 // break on program entry point
#define DOPT_EXCDLG       0x00006000 // exception dialogs:
#  define EXCDLG_NEVER    0x00000000 // never display exception dialogs
#  define EXCDLG_UNKNOWN  0x00002000 // display for unknown exceptions
#  define EXCDLG_ALWAYS   0x00006000 // always display
#define DOPT_LOAD_DINFO   0x00008000 // automatically load debug files (pdb)
#ifdef _notdefinedsymbol


// ***********************************************
// Return the debugger event condition
//
// returns: event condition

string GetDebuggerEventCondition();


// ***********************************************
// Set a new debugger event condition

string SetDebuggerEventCondition(string condition);


// ***********************************************
// Set remote debugging options
//      hostname - remote host name or address
//                 if empty, revert to local debugger
//      password - password for the debugger server
//      portnum  - port number to connect (-1: don't change)
// returns: nothing

void SetRemoteDebugger(string hostname, string password, long portnum);


// ***********************************************
// Get number of defined exception codes

long GetExceptionQty(void);


// ***********************************************
// Get exception code
//      idx - number of exception in the vector (0..GetExceptionQty()-1)
// returns: exception code (0 - error)

long GetExceptionCode(long idx);


// ***********************************************
// Get exception information
//      code - exception code

string GetExceptionName(long code); // returns "" on error
long GetExceptionFlags(long code);  // returns -1 on error


// ***********************************************
// Add exception handling information
//      code - exception code
//      name - exception name
//      desc - exception description
//      flags - exception flags (combination of EXC_...)
// returns: failure description or ""

string DefineException(long code, string name, string desc, long flags);
#endif
#define EXC_BREAK  0x0001 // break on the exception
#define EXC_HANDLE 0x0002 // should be handled by the debugger?
#define EXC_MSG    0x0004 // instead of warn, log the exception to the output window
#define EXC_SILENT 0x0008 // do not warn or log to the output window
#ifdef _notdefinedsymbol


// ***********************************************
// Set exception flags
//      code - exception code
//      flags - exception flags (combination of EXC_...)

success SetExceptionFlags(long code, long flags);


// ***********************************************
// Delete exception handling information
//      code - exception code

success ForgetException(long code);


// ***********************************************
// ** get register value
//    arguments:
//         name - the register name
//    the debugger should be running. otherwise the function fails
//    the register name should be valid.
//    It is not necessary to use this function to get register values
//    because a register name in the script will do too.
//    returns: register value (integer or floating point)
// Thread-safe function (may be called only from the main thread and debthread)

number GetRegValue(string name);


// ***********************************************
// ** set register value
//    arguments:
//         name - the register name
//         value - new register value
//    the debugger should be running
//    It is not necessary to use this function to set register values.
//    A register name in the left side of an assignment will do too.
// Thread-safe function (may be called only from the main thread and debthread)

success SetRegValue(number value, string name);


// Get number of breakpoints.
// Returns: number of breakpoints

long GetBptQty();


// Get breakpoint address
//      n - number of breakpoint, is in range 0..GetBptQty()-1
// returns: addresss of the breakpoint or BADADDR

long GetBptEA(long n);


// Get the characteristics of a breakpoint
//      address - any address in the breakpoint range
//      bptattr - the desired attribute code, one of BPTATTR_... constants
// Returns: the desired attribute value or -1

long GetBptAttr(long ea, number bptattr);

#endif

#define BPTATTR_EA     1  // starting address of the breakpoint
#define BPTATTR_SIZE   2  // size of the breakpoint (undefined for software breakpoint)
#define BPTATTR_TYPE   3  // type of the breakpoint
                          // Breakpoint types:
#define  BPT_WRITE   1    // Hardware: Write access
#define  BPT_READ    2    // Hardware: Read access
#define  BPT_RDWR    3    // Hardware: Read/write access
#define  BPT_SOFT    4    // Software breakpoint
#define  BPT_EXEC    8    // Hardware: Execute instruction

#define BPTATTR_COUNT  4  // number of times the breakpoint is hit before stopping

#define BPTATTR_FLAGS  5  // Breakpoint attributes:
#define BPT_BRK     0x01    // the debugger stops on this breakpoint
#define BPT_TRACE   0x02    // the debugger adds trace information when
                            // this breakpoint is reached
#define BPT_UPDMEM  0x04    // refresh the memory layout and contents before evaluating bpt condition
#define BPT_ENABLED 0x08    // enabled?
#define BPT_LOWCND  0x10    // condition is calculated at low level (on the server side)

#define BPTATTR_COND   6  // Breakpoint condition
                          // NOTE: the return value is a string in this case

// Breakpoint location type:
#define BPLT_ABS     0    // Absolute address. Attributes:
                          // - locinfo: absolute address

#define BPLT_REL     1    // Module relative address. Attributes:
                          // - locpath: the module path
                          // - locinfo: offset from the module base address

#define BPLT_SYM     2    // Symbolic name. The name will be resolved on DLL load/unload
                          // events and on naming an address. Attributes:
                          // - locpath: symbol name
                          // - locinfo: offset from the symbol base address

// Breakpoint properties:
#define BKPT_BADBPT   0x01 // failed to write the bpt to the process memory (at least one location)
#define BKPT_LISTBPT  0x02 // include in bpt list (user-defined bpt)
#define BKPT_TRACE    0x04 // trace bpt; should not be deleted when the process gets suspended
#define BKPT_ACTIVE   0x08 // active?
#define BKPT_PARTIAL  0x10 // partially active? (some locations were not written yet)
#define BKPT_CNDREADY 0x20 // condition has been compiled


#ifdef _notdefinedsymbol

// ***********************************************
class Breakpoint
{
  // Breakpoint type. One of BPT_... constants
  attribute type;

  // Breakpoint size (for hardware breakpoint)
  attribute size;

  // Breakpoint condition
  attribute condition;

  // Breakpoint flags. Refer to BPTATTR_FLAGS
  attribute flags;

  // Breakpoint properties. Refer to BKPT_... constants
  attribute props;

  // Breakpoint pass count
  attribute pass_count;

  // Attribute location type. Refer to BPLT_... constants.
  // Readonly attribute.
  attribute loctype;

  // Breakpoint path (depending on the loctype)
  // Readonly attribute.
  attribute locpath;

  // Breakpoint address info (depending on the loctype)
  // Readonly attribute.
  attribute locinfo;

  // Set absolute breakpoint
  success set_abs_bpt(address);

  // Set symbolic breakpoint
  success set_sym_bpt(symbol_name, offset);

  // Set relative breakpoint
  success set_rel_bpt(path, offset);
};

// Set modifiable characteristics of a breakpoint
//      address - any address in the breakpoint range
//      bptattr - the attribute code, one of BPTATTR_... constants.
//                BPTATTR_CND is not allowed, see SetBptCnd()
//      value   - the attibute value
// Returns: success

success SetBptAttr(long ea, number bptattr, long value);


// Set breakpoint condition
//      address  - any address in the breakpoint range
//      cnd      - breakpoint condition
//      is_lowcnd- 0:regular condition, 1:low level condition
// Returns: success

success SetBptCndEx(long ea, string cnd, long is_lowcnd);


// Add a new breakpoint
//     ea   - any address in the process memory space:
//     size - size of the breakpoint (irrelevant for software breakpoints):
//     type - type of the breakpoint (one of BPT_... constants)
// Only one breakpoint can exist at a given address.
// Returns: success

success AddBptEx(long ea, long size, long bpttype);

#endif
#define AddBpt(ea) AddBptEx(ea, 0, BPT_SOFT) // Shorthand for software breakpoints
#define SetBptCnd(ea, cnd) SetBptCndEx(ea, cnd, 0) // Compatibility macro
#ifdef _notdefinedsymbol


// Delete breakpoint
//     ea   - any address in the process memory space:
// Returns: success

success DelBpt(long ea);


// Enable/disable breakpoint
//     ea   - any address in the process memory space
// Disabled breakpoints are not written to the process memory
// To check the state of a breakpoint, use CheckBpt()
// Returns: success

success EnableBpt(long ea, long enable);


// Check a breakpoint
//     ea   - any address in the process memory space
// Returns: one of BPTCK_... constants

long CheckBpt(long ea);

#endif
#define BPTCK_NONE -1  // breakpoint does not exist
#define BPTCK_NO    0  // breakpoint is disabled
#define BPTCK_YES   1  // breakpoint is enabled
#define BPTCK_ACT   2  // breakpoint is active (written to the process)
#ifdef _notdefinedsymbol


// Enable step tracing
//      trace_level - what kind of trace to modify
//      enable      - 0: turn off, 1: turn on
// Returns: success

success EnableTracing(long trace_level, long enable);

#endif
#define TRACE_STEP 0x0  // lowest level trace. trace buffers are not maintained
#define TRACE_INSN 0x1  // instruction level trace
#define TRACE_FUNC 0x2  // function level trace (calls & rets)
#ifdef _notdefinedsymbol

// Call application function
//      ea - address to call
//      type - type of the function to call. can be specified as:
//              - declaration string. example: "int func(void);"
//              - typeinfo object. example: GetTinfo(ea)
//              - zero: the type will be retrieved from the idb
//      ... - arguments of the function to call
// Returns: the result of the function call
// If the call fails because of an access violation or other exception,
// a runtime error will be generated (it can be caught with try/catch)
// In fact there is rarely any need to call this function explicitly.
// IDC tries to resolve any unknown function name using the application labels
// and in the case of success, will call the function. For example:
//      _printf("hello\n")
// will call the application function _printf provided that there is
// no IDC function with the same name.

anyvalue Appcall(ea, type, ...);


// Set/get appcall options

#endif
#define SetAppcallOptions(x) SetLongPrm(INF_APPCALL_OPTIONS, x)
#define GetAppcallOptions()  GetLongPrm(INF_APPCALL_OPTIONS)

#define APPCALL_MANUAL 0x0001   // Only set up the appcall, do not run it.
                                // you should call CleanupAppcall() when finished
#define APPCALL_DEBEV  0x0002   // Return debug event information
                                // If this bit is set, exceptions during appcall
                                // will generate idc exceptions with full
                                // information about the exception
#define SET_APPCALL_TIMEOUT(x) ((x<<16)|0x0004) // Appcall with timeout
#ifdef _notdefinedsymbol


// Cleanup the current appcall
// This function can be used to terminate the current appcall that was
// started with APPCALL_MANUAL

success CleanupAppcall();

// ----------------------------------------------------------------------------
//                           C O L O R S
// ----------------------------------------------------------------------------

// ***********************************************
// ** get item color
//    arguments:
//         ea - address of the item
//         what - type of the item (one of COLWHAT... constants)
//    returns: color code in RGB (hex 0xBBGGRR)

long GetColor(long ea, long what);

#endif
// color item codes:
#define CIC_ITEM 1          // one instruction or data
#define CIC_FUNC 2          // function
#define CIC_SEGM 3          // segment

#define DEFCOLOR 0xFFFFFFFF     // Default color
#ifdef _notdefinedsymbol

// ***********************************************
// ** set item color
//    arguments:
//         ea - address of the item
//         what - type of the item (one of COLWHAT... constants)
//         color - new color code in RGB (hex 0xBBGGRR)
//    returns: 1-ok, 0-failure

success SetColor(long ea, long what, long color);


// ----------------------------------------------------------------------------
//                               X M L
// ----------------------------------------------------------------------------

// ***********************************************
// ** set or update one or more XML values.
//      arguments: path  - XPath expression of elements
//                         where to create value(s)
//                 name  - name of the element/attribute
//                         (use @XXX for an attribute) to create.
//                         If 'name' is empty, the elements or
//                         attributes returned by XPath are directly
//                         updated to contain the new 'value'.
//                 value - value of the element/attribute
//      returns:   1-ok, 0-failed

success SetXML(string path, string name, string value);

// ***********************************************
// ** get one XML value.
//      arguments: path - XPath expression to an element
//                        or attribute whose value is
//                        requested
//      returns:   the value, 0 if failed

string or long GetXML(string path);



// ----------------------------------------------------------------------------
//                     T I M E   A N D   D A T E
// ----------------------------------------------------------------------------

// ***********************************************
// ** get the current timestamp, in nanoseconds.
//    Retrieves the high-resolution current timestamp, in nanoseconds.
//      returns:   the timestamp, a 64-bit number.
//
//

long GetNsecStamp();


// ----------------------------------------------------------------------------
//                       A R M   S P E C I F I C
// ----------------------------------------------------------------------------

//    Some ARM compilers in Thumb mode use BL (branch-and-link)
//    instead of B (branch) for long jumps, since BL has more range.
//    By default, IDA tries to determine if BL is a jump or a call.
//    You can override IDA's decision using commands in Edit/Other menu
//    (Force BL call/Force BL jump) or the following two functions.

//    Force BL instruction to be a jump
//      arguments: ea - address of the BL instruction
//      returns:   1-ok, 0-failed

success ArmForceBLJump(long ea);

//    Force BL instruction to be a call
//      arguments: ea - address of the BL instruction
//      returns:   1-ok, 0-failed

success ArmForceBLCall(long ea);


// ----------------------------------------------------------------------------
#endif // _notdefinedsymbol
//--------------------------------------------------------------------------
// Compatibility macros:

#define Compile(file)           CompileEx(file, 1)
#define OpOffset(ea, base)      OpOff(ea,-1,base)
#define OpNum(ea)               OpNumber(ea,-1)
#define OpChar(ea)              OpChr(ea,-1)
#define OpSegment(ea)           OpSeg(ea,-1)
#define OpDec(ea)               OpDecimal(ea,-1)
#define OpAlt1(ea,str)          OpAlt(ea,0,str)
#define OpAlt2(ea,str)          OpAlt(ea,1,str)
#define StringStp(x)            SetCharPrm(INF_ASCII_BREAK,x)
#define LowVoids(x)             SetLongPrm(INF_LOW_OFF,x)
#define HighVoids(x)            SetLongPrm(INF_HIGH_OFF,x)
#define TailDepth(x)            SetLongPrm(INF_MAXREF,x)
#define Analysis(x)             SetCharPrm(INF_AUTO,x)
#define Tabs(x)                 SetCharPrm(INF_ENTAB,x)
#define Comments(x)             SetCharPrm(INF_CMTFLAG,((x) ? (SW_ALLCMT|GetCharPrm(INF_CMTFLAG)) : (~SW_ALLCMT&GetCharPrm(INF_CMTFLAG))))
#define Voids(x)                SetCharPrm(INF_VOIDS,x)
#define XrefShow(x)             SetCharPrm(INF_XREFNUM,x)
#define Indent(x)               SetCharPrm(INF_INDENT,x)
#define CmtIndent(x)            SetCharPrm(INF_COMMENT,x)
#define AutoShow(x)             SetCharPrm(INF_SHOWAUTO,x)
#define MinEA()                 GetLongPrm(INF_MIN_EA)
#define MaxEA()                 GetLongPrm(INF_MAX_EA)
#define BeginEA()               GetLongPrm(INF_BEGIN_EA)
#define set_start_cs(x)         SetLongPrm(INF_START_CS,x)
#define set_start_ip(x)         SetLongPrm(INF_START_IP,x)
#define WriteMap(file) \
        GenerateFile(OFILE_MAP, fopen(file,"w"), 0, BADADDR, \
        GENFLG_MAPSEGS|GENFLG_MAPNAME)
#define WriteTxt(file,ea1,ea2) \
        GenerateFile(OFILE_ASM,fopen(file,"w"), ea1, ea2, 0)
#define WriteExe(file) \
        GenerateFile(OFILE_EXE,fopen(file,"wb"), 0, BADADDR, 0)
#define AddConst(enum_id,name,value) AddConstEx(enum_id,name,value,-1)
#define AddStruc(index,name)         AddStrucEx(index,name,0)
#define AddUnion(index,name)         AddStrucEx(index,name,1)
#define OpStroff(ea,n,strid)         OpStroffEx(ea,n,strid,0)
#define OpEnum(ea,n,enumid)          OpEnumEx(ea,n,enumid,0)
#define DelConst(id,v,mask)          DelConstEx(id,v,0,mask)
#define GetConst(id,v,mask)          GetConstEx(id,v,0,mask)
#define AnalyseArea(sEA, eEA)        AnalyzeArea(sEA,eEA)

#define MakeStruct(ea,name)          MakeStructEx(ea, -1, name)
#define Name(ea)                     NameEx(BADADDR, ea)
#define GetTrueName(ea)              GetTrueNameEx(BADADDR, ea)
#define MakeName(ea,name)            MakeNameEx(ea,name,SN_CHECK)

#define GetFrame(ea)                GetFunctionAttr(ea, FUNCATTR_FRAME)
#define GetFrameLvarSize(ea)        GetFunctionAttr(ea, FUNCATTR_FRSIZE)
#define GetFrameRegsSize(ea)        GetFunctionAttr(ea, FUNCATTR_FRREGS)
#define GetFrameArgsSize(ea)        GetFunctionAttr(ea, FUNCATTR_ARGSIZE)
#define GetFunctionFlags(ea)        GetFunctionAttr(ea, FUNCATTR_FLAGS)
#define SetFunctionFlags(ea, flags) SetFunctionAttr(ea, FUNCATTR_FLAGS, flags)

#define SegStart(ea)                GetSegmentAttr(ea, SEGATTR_START)
#define SegEnd(ea)                  GetSegmentAttr(ea, SEGATTR_END)
#define SetSegmentType(ea, type)    SetSegmentAttr(ea, SEGATTR_TYPE, type)
#define SegCreate(a1, a2, base, use32, align, comb) AddSeg(a1, a2, base, use32, align, comb)
#define SegDelete(ea, flags)        DelSeg(ea, flags)
#define SegBounds(ea, startea, endea, flags) SetSegBounds(ea, startea, endea, flags)
#define SegRename(ea, name)         RenameSeg(ea, name)
#define SegClass(ea, class)         SetSegClass(ea, class)
#define SegAddrng(ea, bitness)      SetSegAddressing(ea, bitness)
#define SegDefReg(ea, reg, value)   SetSegDefReg(ea, reg, value)

#define Comment(ea)                 CommentEx(ea, 0)
#define RptCmt(ea)                  CommentEx(ea, 1)

#define MakeByte(ea)                MakeData(ea, FF_BYTE, 1, BADADDR)
#define MakeWord(ea)                MakeData(ea, FF_WORD, 2, BADADDR)
#define MakeDword(ea)               MakeData(ea, FF_DWRD, 4, BADADDR)
#define MakeQword(ea)               MakeData(ea, FF_QWRD, 8, BADADDR)
#define MakeOword(ea)               MakeData(ea, FF_OWRD, 16, BADADDR)
#define MakeFloat(ea)               MakeData(ea, FF_FLOAT, 4, BADADDR)
#define MakeDouble(ea)              MakeData(ea, FF_DOUBLE, 8, BADADDR)
#define MakePackReal(ea)            MakeData(ea, FF_PACKREAL, 10, BADADDR)
#define MakeTbyte(ea)               MakeData(ea, FF_TBYT, 10, BADADDR)
#define MakeCustomData(ea,size,dtid,fid) MakeData(ea, FF_CUSTOM, size, dtid|((fid)<<16))

#define SetReg(ea,reg,value)        SetRegEx(ea,reg,value,SR_user)

// erroneous name of INF_AF:
#define INF_START_AF    33

// Convenience macros:
#define here                    ScreenEA()
#define isEnabled(ea)           (PrevAddr(ea+1)==ea)

// obsolete segdel macros:
#define SEGDEL_PERM   0x0001 // permanently, i.e. disable addresses
#define SEGDEL_KEEP   0x0002 // keep information (code & data, etc)
#define SEGDEL_SILENT 0x0004 // be silent

#define form sprintf
// ----------------------------------------------------------------------------
//               P R O C E S S O R  M O D U L E   C O N S T A N T S
// ----------------------------------------------------------------------------
// asm_t.flag
#define AS_OFFST      0x00000001L       // offsets are 'offset xxx' ?
#define AS_COLON      0x00000002L       // create colons after data names ?
#define AS_UDATA      0x00000004L       // can use '?' in data directives

#define AS_2CHRE      0x00000008L       // double char constants are: "xy
#define AS_NCHRE      0x00000010L       // char constants are: 'x
#define AS_N2CHR      0x00000020L       // can't have 2 byte char consts

//----------------------------------------------------------------------
// asm_t.flag2
                                        // ASCII directives:
#define AS_1TEXT      0x00000040L       //   1 text per line, no bytes
#define AS_NHIAS      0x00000080L       //   no characters with high bit
#define AS_NCMAS      0x00000100L       //   no commas in ascii directives

#define AS_HEXFM      0x00000E00L       // format of hex numbers:
#define ASH_HEXF0     0x00000000L       //   34h
#define ASH_HEXF1     0x00000200L       //   h'34
#define ASH_HEXF2     0x00000400L       //   34
#define ASH_HEXF3     0x00000600L       //   0x34
#define ASH_HEXF4     0x00000800L       //   $34
#define ASH_HEXF5     0x00000A00L       //   <^R   > (radix)
#define AS_DECFM      0x00003000L       // format of dec numbers:
#define ASD_DECF0     0x00000000L       //   34
#define ASD_DECF1     0x00001000L       //   #34
#define ASD_DECF2     0x00002000L       //   34.
#define ASD_DECF3     0x00003000L       //   .34
#define AS_OCTFM      0x0001C000L       // format of octal numbers:
#define ASO_OCTF0     0x00000000L       //   123o
#define ASO_OCTF1     0x00004000L       //   0123
#define ASO_OCTF2     0x00008000L       //   123
#define ASO_OCTF3     0x0000C000L       //   @123
#define ASO_OCTF4     0x00010000L       //   o'123
#define ASO_OCTF5     0x00014000L       //   123q
#define ASO_OCTF6     0x00018000L       //   ~123
#define AS_BINFM      0x000E0000L       // format of binary numbers:
#define ASB_BINF0     0x00000000L       //   010101b
#define ASB_BINF1     0x00020000L       //   ^B010101
#define ASB_BINF2     0x00040000L       //   %010101
#define ASB_BINF3     0x00060000L       //   0b1010101
#define ASB_BINF4     0x00080000L       //   b'1010101
#define ASB_BINF5     0x000A0000L       //   b'1010101'

#define AS_UNEQU      0x00100000L       // replace undefined data items
                                        // with EQU (for ANTA's A80)
#define AS_ONEDUP     0x00200000L       // One array definition per line
#define AS_NOXRF      0x00400000L       // Disable xrefs during the output file generation
#define AS_XTRNTYPE   0x00800000L       // Assembler understands type of extrn
                                        // symbols as ":type" suffix
#define AS_RELSUP     0x01000000L       // Checkarg: 'and','or','xor' operations
                                        // with addresses are possible
#define AS_LALIGN     0x02000000L       // Labels at "align" keyword
                                        // are supported.
#define AS_NOCODECLN  0x04000000L       // don't create colons after code names
#define AS_NOTAB      0x08000000L       // Disable tabulation symbols during the output file generation
#define AS_NOSPACE    0x10000000L       // No spaces in expressions
#define AS_ALIGN2     0x20000000L       // .align directive expects an exponent rather than a power of 2
                                        // (.align 5 means to align at 32byte boundary)
#define AS_ASCIIC     0x40000000L       // ascii directive accepts C-like
                                        // escape sequences (\n,\x01 and similar)
#define AS_ASCIIZ     0x80000000L       // ascii directive inserts implicit
                                        // zero byte at the end

#define AS2_BRACE     0x00000001        // Use braces for all expressions
#define AS2_STRINV    0x00000002        // For processors with bytes bigger than 8 bits:
                                        //  invert the meaning of inf.wide_high_byte_first
                                        //  for text strings
#define AS2_BYTE1CHAR 0x00000004        // One symbol per processor byte
                                        // Meaningful only for wide byte processors
#define AS2_IDEALDSCR 0x00000008        // Description of struc/union is in
                                        // the 'reverse' form (keyword before name)
                                        // the same as in borland tasm ideal
#define AS2_TERSESTR  0x00000010        // 'terse' structure initialization form
                                        // NAME<fld,fld,...> is supported
#define AS2_COLONSUF  0x00000020        // addresses may have ":xx" suffix
                                        // this suffix must be ignored when extracting
                                        // the address under the cursor

//----------------------------------------------------------------------
// processor_t.version
#define IDP_INTERFACE_VERSION 76

//----------------------------------------------------------------------
// processor_t.flags
#define PR_SEGS       0x000001  // has segment registers?
#define PR_USE32      0x000002  // supports 32-bit addressing?
#define PR_DEFSEG32   0x000004  // segments are 32-bit by default
#define PR_RNAMESOK   0x000008  // allow to user register names for
                                // location names
#define PR_DB2CSEG    0x0010  // .byte directive in code segments
                              // should define even number of bytes
                              // (used by AVR processor)
#define PR_ADJSEGS    0x000020  // IDA may adjust segments moving
                                // their starting/ending addresses.
#define PR_DEFNUM     0x0000C0  // default number representation:
#define PRN_HEX       0x000000  //      hex
#define PRN_OCT       0x000040  //      octal
#define PRN_DEC       0x000080  //      decimal
#define PRN_BIN       0x0000C0  //      binary
#define PR_WORD_INS   0x000100  // instruction codes are grouped
                                // 2bytes in binrary line prefix
#define PR_NOCHANGE   0x000200  // The user can't change segments
                                // and code/data attributes
                                // (display only)
#define PR_ASSEMBLE   0x000400  // Module has a built-in assembler
                                // and understands IDP_ASSEMBLE
#define PR_ALIGN      0x000800  // All data items should be aligned
                                // properly
#define PR_TYPEINFO   0x001000  // the processor module supports
                                // type information callbacks
                                // ALL OF THEM SHOULD BE IMPLEMENTED!
                                // (the ones >= decorate_name)
#define PR_USE64      0x002000  // supports 64-bit addressing?
#define PR_SGROTHER   0x004000  // the segment registers don't contain
                                // the segment selectors, something else
#define PR_STACK_UP   0x008000  // the stack grows up
#define PR_BINMEM     0x010000  // the processor module provides correct
                                // segmentation for binary files
                                // (i.e. it creates additional segments)
                                // The kernel will not ask the user
                                // to specify the RAM/ROM sizes
#define PR_SEGTRANS   0x020000  // the processor module supports
                                // the segment translation feature
                                // (it means it calculates the code
                                // addresses using the codeSeg() function)
#define PR_CHK_XREF   0x040000  // don't allow near xrefs between segments
                                // with different bases
#define PR_NO_SEGMOVE 0x080000  // the processor module doesn't support move_segm()
                                // (i.e. the user can't move segments)
#define PR_FULL_HIFXP 0x100000  // REF_VHIGH operand value contains full operand
                                // not only the high bits. Meaningful if ph.high_fixup_bits
#define PR_USE_ARG_TYPES 0x200000 // use ph.use_arg_types callback
#define PR_SCALE_STKVARS 0x400000 // use ph.get_stkvar_scale callback
#define PR_DELAYED    0x800000 // has delayed jumps and calls
#define PR_ALIGN_INSN 0x1000000 // allow ida to create alignment instructions
                                // arbirtrarily. Since these instructions
                                // might lead to other wrong instructions
                                // and spoil the listing, IDA does not create
                                // them by default anymore
#define PR_PURGING    0x2000000 // there are calling conventions which may
                                // purge bytes from the stack
#define PR_CNDINSNS   0x4000000 // has conditional instructions
#define PR_USE_TBYTE  0x8000000 // BTMT_SPECFLT means _TBYTE type
#define PR_DEFSEG64  0x10000000 // segments are 64-bit by default

//----------------------------------------------------------------------
// insn_t.flags
#define INSN_MACRO  0x01        // macro instruction
#define INSN_MODMAC 0x02        // macros: may modify the database
                                // to make room for the macro insn


//----------------------------------------------------------------------
// processor_t.set_idp_options
#define IDPOPT_STR 1                    // string constant (char *)
#define IDPOPT_NUM 2                    // number (uval_t *)
#define IDPOPT_BIT 3                    // bit, yes/no (int *)
#define IDPOPT_FLT 4                    // float (double *)
#define IDPOPT_I64 5                    // 64bit number (int64 *)
// returns:
#define IDPOPT_OK       0               // ok
#define IDPOPT_BADKEY   1               // illegal keyword
#define IDPOPT_BADTYPE  2               // illegal type of value
#define IDPOPT_BADVALUE 3               // illegal value (bad range, for example)

//----------------------------------------------------------------------
// processor_t.is_sp_based return code
#define OP_FP_BASED  0x00000000 // operand is FP based
#define OP_SP_BASED  0x00000001 // operand is SP based
#define OP_SP_ADD    0x00000000 // operand value is added to the pointer
#define OP_SP_SUB    0x00000002 // operand value is substracted from the pointer

//----------------------------------------------------------------------
//
//      Floating point -> IEEE conversion function
// error codes returned by the processor_t.realcvt function (load/store):
#define REAL_ERROR_FORMAT  -1 // not supported format for current .idp
#define REAL_ERROR_RANGE   -2 // number too big (small) for store (mem NOT modifyed)
#define REAL_ERROR_BADDATA -3 // illegal real data for load (IEEE data not filled)

//-----------------------------------------------------------------------
// instruc_t.feature
#define CF_STOP 0x00001  // Instruction doesn't pass execution to the
                         // next instruction
#define CF_CALL 0x00002  // CALL instruction (should make a procedure here)
#define CF_CHG1 0x00004  // The instruction modifies the first operand
#define CF_CHG2 0x00008  // The instruction modifies the second operand
#define CF_CHG3 0x00010  // The instruction modifies the third operand
#define CF_CHG4 0x00020  // The instruction modifies 4 operand
#define CF_CHG5 0x00040  // The instruction modifies 5 operand
#define CF_CHG6 0x00080  // The instruction modifies 6 operand
#define CF_USE1 0x00100  // The instruction uses value of the first operand
#define CF_USE2 0x00200  // The instruction uses value of the second operand
#define CF_USE3 0x00400  // The instruction uses value of the third operand
#define CF_USE4 0x00800  // The instruction uses value of the 4 operand
#define CF_USE5 0x01000  // The instruction uses value of the 5 operand
#define CF_USE6 0x02000  // The instruction uses value of the 6 operand
#define CF_JUMP 0x04000  // The instruction passes execution using indirect
                         // jump or call (thus needs additional analysis)
#define CF_SHFT 0x08000  // Bit-shift instruction (shl,shr...)
#define CF_HLL  0x10000  // Instruction may be present in a high level
                         // language function.

//-----------------------------------------------------------------------
// op_t.dtyp
#define dt_byte         0       // 8 bit
#define dt_word         1       // 16 bit
#define dt_dword        2       // 32 bit
#define dt_float        3       // 4 byte
#define dt_double       4       // 8 byte
#define dt_tbyte        5       // variable size (ph.tbyte_size)
#define dt_packreal     6       // packed real format for mc68040
// ...to here the order should not be changed, see mc68000
#define dt_qword        7       // 64 bit
#define dt_byte16       8       // 128 bit
#define dt_code         9       // ptr to code (not used?)
#define dt_void         10      // none
#define dt_fword        11      // 48 bit
#define dt_bitfild      12      // bit field (mc680x0)
#define dt_string       13      // pointer to asciiz string
#define dt_unicode      14      // pointer to unicode string
#define dt_3byte        15      // 3-byte data
#define dt_ldbl         16      // long double (which may be different from tbyte)

//-----------------------------------------------------------------------
// op_t.flags
#define OF_NO_BASE_DISP 0x80    // o_displ: base displacement doesn't exist
                                // meaningful only for o_displ type
                                // if set, base displacement (x.addr)
                                // doesn't exist.
#define OF_OUTER_DISP   0x40    // o_displ: outer displacement exists
                                // meaningful only for o_displ type
                                // if set, outer displacement (x.value) exists.
#define PACK_FORM_DEF   0x20    // !o_reg + dt_packreal: packed factor defined
#define OF_NUMBER       0x10    // can be output as number only
                                // if set, the operand can be converted to a
                                // number only
#define OF_SHOW         0x08    // should the operand be displayed?
                                // if clear, the operand is hidden and should
                                // not be displayed

// ----------------------------------------------------------------------------
//               P L U G I N S  C O N S T A N T S
// ----------------------------------------------------------------------------

#define PLUGIN_MOD  0x0001      // Plugin changes the database.
                                // IDA won't call the plugin if
                                // the processor prohibited any changes
                                // by setting PR_NOCHANGES in processor_t.
#define PLUGIN_DRAW 0x0002      // IDA should redraw everything after calling
                                // the plugin
#define PLUGIN_SEG  0x0004      // Plugin may be applied only if the
                                // current address belongs to a segment
#define PLUGIN_UNL  0x0008      // Unload the plugin immediately after
                                // calling 'run'.
                                // This flag may be set anytime.
                                // The kernel checks it after each call to 'run'
                                // The main purpose of this flag is to ease
                                // the debugging of new plugins.
#define PLUGIN_HIDE 0x0010      // Plugin should not appear in the Edit, Plugins menu
                                // This flag is checked at the start
#define PLUGIN_DBG  0x0020      // A debugger plugin. init() should put
                                // the address of debugger_t to dbg
                                // See idd.hpp for details
#define PLUGIN_PROC 0x0040      // Load plugin when a processor module is loaded and keep it
                                // until the processor module is unloaded
#define PLUGIN_FIX  0x0080      // Load plugin when IDA starts and keep it in the
                                // memory until IDA stops

#define PLUGIN_SKIP  0          // Plugin doesn't want to be loaded
#define PLUGIN_OK    1          // Plugin agrees to work with the current database
                                // It will be loaded as soon as the user presses the hotkey

#define PLUGIN_KEEP  2          // Plugin agrees to work with the current database
                                // and wants to stay in the memory

#endif // _IDC_IDC
