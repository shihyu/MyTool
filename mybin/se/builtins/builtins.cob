      *
      *  Copyright 1998-2002 by SlickEdit Inc.
      *  All rights reserved.
      * 
      *  This software is the confidential and proprietary information
      *  of SlickEdit Inc. You shall not disclose this information and 
      *  shall use it only with Visual SlickEdit.
      *  
      *  You may modify this file to add new built-ins
      *  for Visual SlickEdit's Context Tagging(TM).  Let us know about 
      *  new built-ins.  This way our installation/update will install
      *  the most up-to-date version and you won't need to maintain a
      *  backup.
      *

      /*****************************************************************
      ** COBOL INTRINSIC FUNCTIONS, SYNTAX HELP                       **
      ******************************************************************
       FUNCTION-ID.      *> stop comment lookup

      * The absolute value of 'numeric-argument-1'
       FUNCTION-ID. ABS USING numeric-argument-1
                        RETURNING numeric-result IS PROTOTYPE.

      * Arccosine in radians of 'numeric-argument-1'
       FUNCTION-ID. ACOS USING numeric-argument-1
                         RETURNING numeric-result IS PROTOTYPE.

      * Number of occurrences currently allocated for a dynamic table
       FUNCTION-ID. ALLOCATED-OCCURRENCES USING argument-1
                         RETURNING integer-result IS PROTOTYPE.

      * Ratio of annuity paid for 'numeric-argument-1' periods of
      * interest at the rate of 'numeric-argument-2' for an initial
      * investment of one dollar.  Interest is applied at the end of
      * the period, before the payment.
       FUNCTION-ID. ANNUITY USING numeric-argument-1 numeric-argument-2
                            RETURNING numeric-result IS PROTOTYPE.

      * Arcsine in radians of 'numeric-argument-1'
       FUNCTION-ID. ASIN USING numeric-argument-1
                         RETURNING numeric-result IS PROTOTYPE.

      * Arctangent in radians of 'numeric-argument-1'
       FUNCTION-ID. ATAN USING numeric-argument-1
                         RETURNING numeric-result IS PROTOTYPE.

      * Returns the boolean item of usage bit representing the binary
      * value equivalent of the absolute value of 'integer-argument-1',
      * where the rightmost boolean position is the low-order postion.
      * The boolean item is filled on the left, if necessary, with
      * boolean positions set to 0 or truncated on the left, if
      * necessary, to return a boolean item that contains the number of
      * boolean positions secified by 'integer-argument-2.
       FUNCTION-ID. BOOLEAN-OF USING integer-argument-1
                                     integer-argument-2
                               RETURNING boolean-result IS PROTOTYPE.

      * Character in position 'integer-argument-1' of the alphanumeric
      * program collating sequence.
       FUNCTION-ID. CHAR USING integer-argument-1
                         RETURNING alphanumeric-result IS PROTOTYPE.

      * Character in position 'integer-argument-1' of the national
      * program collating sequence.
       FUNCTION-ID. CHAR-NATIONAL USING integer-argument-1
                                  RETURNING national-result
                                  IS PROTOTYPE.

      * Cosine of 'numeric-argument-1', expressed in radians
       FUNCTION-ID. COS USING numeric-argument-1
                        RETURNING numeric-result IS PROTOTYPE.

      * Current date and time and local time difference from
      * Greenwich Mean Time (GMT) in a 21 character string
      * (YYYYMMDDHHmmsshh[+-0]ghgm.
       FUNCTION-ID. CURRENT-DATE RETURNING alphanumeric-result
                                 IS PROTOTYPE.

      * Standard date equivalent (YYYYMMDD) of integer date
       FUNCTION-ID. DATE-OF-INTEGER USING integer-argument-1
                                    OPTIONAL argument-2
                                    RETURNING date-result IS PROTOTYPE.

      * 'integer-argument-1' converted from YYMMDD to YYYYMMDD based on
      * the value of 'integer-argument-2', which allows adjustment to
      * the century range.  'integer-argument-2' defines the ending
      * year as a displacement from the current system year.  
       FUNCTION-ID. DATE-TO-YYYYMMDD USING integer-argument-1
                                     OPTIONAL integer-argument-2=50
                                     RETURNING date-result IS PROTOTYPE.

      * Date field equivalent of 'integer-argument-1'
       FUNCTION-ID. DATEVAL USING integer-argument-1
                            RETURNING date-result IS PROTOTYPE.
       
      * Standard date equivalent (YYYYMMDD) of integer date in the
      * Gregorian calendar.
       FUNCTION-ID. DAY-OF-INTEGER USING integer-argument-1
                                   RETURNING date-result IS PROTOTYPE.

      * 'integer-argument-1' converted from YYDDD to YYYYDDD based on
      * the value of 'integer-argument-2', which allows adjustment to
      * the century range.  'integer-argument-2' defines the ending
      * year as a displacement from the current system year.  
       FUNCTION-ID. DAY-TO-YYYYMMDD USING integer-argument-1
                                    OPTIONAL integer-argument-2=50
                                    RETURNING day-result IS PROTOTYPE.

      * Returns a character string containing the external media format
      * of the national characters in the argument 'national-argument-1'
       FUNCTION-ID. DISPLAY-OF USING national-argument-1
                                     alphanumeric-argument-2
                               RETURNING alphanumeric-result
                               IS PROTOTYPE.

      * The value of 'e', the natural base, 1.281718...
       FUNCTION-ID. E RETURNING numeric-result IS PROTOTYPE.

      * Information about the file exception that raised an exception
       FUNCTION-ID. EXCEPTION-FILE RETURNING alphanumeric-result
                                   IS PROTOTYPE.

      * Implementor-defined location of statement causing an exception
       FUNCTION-ID. EXCEPTION-LOCATION
                        RETURNING alphanumeric-result IS PROTOTYPE.

      * Name of statement causing an exception
       FUNCTION-ID. EXCEPTION-STATEMENT
                        RETURNING alphanumeric-result IS PROTOTYPE.

      * Exception-name identifying last exception
       FUNCTION-ID. EXCEPTION-STATUS
                        RETURNING alphanumeric-result IS PROTOTYPE.

      * 'e' raised to the power 'numeric-argument-1'
       FUNCTION-ID. EXP USING numeric-argument-1
                        RETURNING numeric-result IS PROTOTYPE.

      * 10 raised to the power 'numeric-argument-1'
       FUNCTION-ID. EXP10 USING numeric-argument-1
                          RETURNING numeric-result IS PROTOTYPE.

      * Factorial of 'integer-argument-1'
       FUNCTION-ID. FACTORIAL USING integer-argument-1
                              RETURNING integer-result IS PROTOTYPE.

      * Fraction part of 'numeric-argument-1'
       FUNCTION-ID. FRACTION-PART USING numeric-argument-1
                                  RETURNING numeric-result IS PROTOTYPE.

      * Greatest algebraic value that may be represented in 'argument-1'
       FUNCTION-ID. HIGHEST-ALGEBRAIC USING argument-1
                                      RETURNING numeric-result
                                      IS PROTOTYPE.

      * The greatest integer not greater than 'numeric-argument-1',
      * that is, the integer (fraction truncated) part of
      * 'numeric-argument-1'
       FUNCTION-ID. INTEGER USING numeric-argument-1
                            RETURNING integer-result IS PROTOTYPE.

      * Integer date equivalent of standard date (YYYYMMDD)
       FUNCTION-ID. INTEGER-OF-DATE USING date-argument-1
                                    RETURNING integer-result
                                    IS PROTOTYPE.

      * Integer date equivalent of Julian date (YYYYDDD)
       FUNCTION-ID. INTEGER-OF-DAY USING date-argument-1
                                   RETURNING integer-result
                                   IS PROTOTYPE.

      * Integer part of 'numeric-argument-1'
       FUNCTION-ID. INTEGER-PART USING numeric-argument-1
                                 RETURNING integer-result IS PROTOTYPE.

      * Length of 'argument-1' in number of character positions or
      * number of boolean positions.
       FUNCTION-ID. LENGTH USING argument-1
                           RETURNING integer-result IS PROTOTYPE.

      * Length of argument in number of alphanumeric character positions
       FUNCTION-ID. LENGTH-AN USING argument-1
                              RETURNING integer-result IS PROTOTYPE.

      * A character indicating the result of comparing 'argument-1'
      * to 'argument-2' using an ordering defined by a locale.
       FUNCTION-ID. LOCALE-COMPARE USING argument-1 arguent-2
                                   OPTIONAL mnemonic-name-1
                                   RETURNING alphanumeric-result
                                   IS PROTOTYPE.

      * A character string containing a date specified by 'argument-1'
      * in a format specified by a locale.
       FUNCTION-ID. LOCALE-DATE USING argument-1
                                OPTIONAL mnemonic-name-1
                                RETURNING alphanumeric-result
                                IS PROTOTYPE.

      * A character string containing a time specified by 'argument-1'
      * in a format specified by a locale.
       FUNCTION-ID. LOCALE-TIME USING argument-1
                                OPTIONAL mnemonic-name-1
                                RETURNING alphanumeric-result
                                IS PROTOTYPE.

      * Natural logarithm of 'numeric-argument-1'
       FUNCTION-ID. LOG USING numeric-argument-1
                        RETURNING numeric-result IS PROTOTYPE.

      * Base 10 logarithm of 'numeric-argument-1'
       FUNCTION-ID. LOG10 USING numeric-argument-1
                          RETURNING numeric-result IS PROTOTYPE.

      * All letters in the artument are set to lowercase
       FUNCTION-ID. LOWER-CASE USING argument-1
                               RETURNING alphanumeric-result
                               IS PROTOTYPE.

      * Lowest algebraic value that may be represented in the argument.
       FUNCTION-ID. LOWEST-ALGEBRAIC USING argument-1
                                     RETURNING numeric-result
                                     IS PROTOTYPE.

      * Value of maximum argument, as defined by numeric or collating
      * sequence.
       FUNCTION-ID. MAX USING argument-1 ...
                        RETURNING variant-result IS PROTOTYPE.

      * Arithmetic mean of arguments
       FUNCTION-ID. MEAN USING numeric-argument-1 ...
                         RETURNING numeric-result IS PROTOTYPE.

      * Median of arguments
       FUNCTION-ID. MEDIAN USING numeric-argument-1 ...
                           RETURNING numeric-result IS PROTOTYPE.

      * Median of arguments
       FUNCTION-ID. MIDRANGE USING numeric-argument-1 ...
                             RETURNING numeric-result IS PROTOTYPE.

      * Value of minimum argument, as defined by numeric or collating
      * sequence.
       FUNCTION-ID. MIN USING argument-1 ...
                        RETURNING variant-result IS PROTOTYPE.

      * Value of 'integer-argument-1' modulo 'integer-argument-2'
       FUNCTION-ID. MOD USING integer-argument-1 integer-argument-2
                        RETURNING integer-result IS PROTOTYPE.

      * Usage national representation of 'argument-1'
       FUNCTION-ID. NATIONAL-OF USING argument-1 OPTIONAL argument-2
                                RETURNING national-result IS PROTOTYPE.

      * Numeric value of simple numeric string
       FUNCTION-ID. NUMVAL USING argument-1
                           RETURNING numeric-result IS PROTOTYPE.

      * The decimal numeric value equivalent to the binary value of the
      * boolean item in 'argument-1'
       FUNCTION-ID. NUMVAL-B USING argument-1
                             RETURNING integer-result IS PROTOTYPE.

      * The numeric value of numeric string 'argument-1' with optional
      * commas and currency sign.
       FUNCTION-ID. NUMVAL-C USING argument-1
                             RETURNING numeric-result IS PROTOTYPE.

      * The numeric value of numeric string 'argument-1' representing a
      * floating point number.
       FUNCTION-ID. NUMVAL-F USING argument-1
                             RETURNING numeric-result IS PROTOTYPE.

      * Ordinal position of character 'argument-1' in collating
      * sequence.
       FUNCTION-ID. ORD USING argument-1
                        RETURNING integer-result IS PROTOTYPE.

      * Ordinal position of maximum argument
       FUNCTION-ID. ORD-MAX USING argument-1 ...
                            RETURNING integer-result IS PROTOTYPE.

      * Ordinal position of minimum argument
       FUNCTION-ID. ORD-MIN USING argument-1 ...
                            RETURNING integer-result IS PROTOTYPE.

      * The value of the constant PI (3.1459...), the ratio of the
      * circumference of a circle to its diameter
       FUNCTION-ID. PI RETURNING numeric-result IS PROTOTYPE.

      * Present value of a series of future period-end amounts
      * 'numeric-argument-2 ...' at a discount rate of
      * 'numeric-argument-1'
       FUNCTION-ID. PRESENT-VALUE USING numeric-argument-1
                                        numeric-argument-2 ...
                                  RETURNING numeric-result IS PROTOTYPE.

      * Generate a pseudo-random number from a rectangular distribution
      * between 0 and 1, 'argument-1', if specified, is used as a seed
      * value for the random number generator.
       FUNCTION-ID. RANDOM USING OPTIONAL argument-1
                           RETURNING numeric-result IS PROTOTYPE.

      * Value of maximum argument minus value of minimum argument.
       FUNCTION-ID. RANGE USING numeric-argument-1 ...
                          RETURNING numeric-result IS PROTOTYPE.

      * Remainder of 'numeric-argument-1' divided by
      * 'numeric-argument-2'
       FUNCTION-ID. REM USING numeric-argument-1 numeric-argument-2
                        RETURNING numeric-result IS PROTOTYPE.

      * Reverse order of the characters in 'argument-1'
       FUNCTION-ID. REVERSE USING argument-1
                            RETURNING alphanumeric-result IS PROTOTYPE.

      * The sign of 'numeric-argument-1'
       FUNCTION-ID. SIGN USING numeric-argument-1
                         RETURNING integer-result IS PROTOTYPE.

      * Sine of an angle or arc 'numeric-argument-1', expressed in
      * radians
       FUNCTION-ID. SIN USING numeric-argument-1
                        RETURNING numeric-result IS PROTOTYPE.
       
      * Square root of 'numeric-argument-1'
       FUNCTION-ID. SQRT USING numeric-argument-1
                         RETURNING numeric-result IS PROTOTYPE.

      * A character indicating the result of comparing 'argument-1' to
      * 'argument-2' using the ordering specified by ISO/EIC 14651 at
      * the comparison level set by 'argument-3'.
       FUNCTION-ID. STANDARD-COMPARE USING argument-1 argument-2
                                     OPTIONAL argument-3
                                     RETURNING alphanumeric-result
                                     IS PROTOTYPE.

      * Standard deviation of arguments.
       FUNCTION-ID. STANDARD-DEVIATION USING numeric-argument-1 ...
                         RETURNING numeric-result IS PROTOTYPE.

      * Sum of values of arguments
       FUNCTION-ID. SUM USING numeric-argument-1 ...
                        RETURNING numeric-result IS PROTOTYPE.

      * Tangent of an angle or arc 'numeric-argument-1', expressed in
      * radians
       FUNCTION-ID. TAN USING numeric-argument-1
                        RETURNING numeric-result IS PROTOTYPE.

      * Returns 0 if 'argument-1' is a valid standard date;
      * otherwise identifies the sub-field in error.
       FUNCTION-ID. TEST-DATE-YYYYMMDD USING argument-1
                         RETURNING integer-result IS PROTOTYPE.

      * Returns 0 if 'argument-1' is a valid standard Julian date;
      * otherwise identifies the sub-field in error.
       FUNCTION-ID. TEST-DATE-YYYYDDD USING argument-1
                         RETURNING integer-result IS PROTOTYPE.

      * Returns 0 if 'argument-1' conforms to the requirements of the
      * NUMVAL function; otherwise identifies the character in error.
       FUNCTION-ID. TEST-NUMVAL USING argument-1
                                RETURNING integer-result IS PROTOTYPE.

      * Returns 0 if 'argument-1' conforms to the requirements of the
      * NUMVAL-C function; otherwise identifies the character in error.
       FUNCTION-ID. TEST-NUMVAL-C USING argument-1
                                  OPTIONAL argument-2
                                  RETURNING integer-result IS PROTOTYPE.

      * Returns 0 if 'argument-1' conforms to the requirements of the
      * NUMVAL-F function; otherwise identifies the character in error.
       FUNCTION-ID. TEST-NUMVAL-F USING argument-1
                                  RETURNING integer-result IS PROTOTYPE.

      * Non-date equivalent of date field 'integer-argument-1'
       FUNCTION-ID. UNDATE USING integer-argument-1
                           RETURNING integer-result IS PROTOTYPE.
       
      * All letters in 'argument-1' are set to upper case.
       FUNCTION-ID. UPPER-CASE USING argument-1
                               RETURNING alphanumeric-result
                               IS PROTOTYPE.

      * Variance of arguments
       FUNCTION-ID. VARIANCE USING numeric-argument-1 ...
                             RETURNING numeric-result IS PROTOTYPE.

      * Date and time program was compiled
       FUNCTION-ID. WHEN-COMPILED RETURNING alphanumeric-result
                                  IS PROTOTYPE.

      * 'argument-1' converted from YY to YYYY based on the value of
      * 'argument-2', which allows adjustment to the
      * century range.  'integer-argument-2' defines the ending year as
      * a displacement from the current system year.  
       FUNCTION-ID. YEAR-TO-YYYY USING argument-1 OPTIONAL argument-2
                                 RETURNING integer-result IS PROTOTYPE.

      * If the DATEPROC compiler option is in effect, returns the
      * starting year (in the format YYYY) of the century window
      * specified by the YEARWINDOW compiler option; if NODATEPROC is
      * in efect, returns 0.
       FUNCTION-ID. YEARWINDOW RETURNING integer-result IS PROTOTYPE.

                                    
      /*****************************************************************
      ** COBOL IDENTIFICATION DIVISION, SYNTAX DIAGRAMS               **
      ******************************************************************
       FUNCTION-ID.      *> stop comment lookup

      * The Identification division provides the name of the source
      * program, and can also include other optional documentary
      * information, such as the program author, where the program is
      * installed, when it was written, and any applicable security
      * restrictions.
       PROCEDURE-ID. IDENTIFICATION IS
        "DIVISION.",
        "{PROGRAM-ID or FUNCTION-ID or CLASS-ID or","
        " INTERFACE-ID or METHOD-ID}. identifier-1 ...",
        "[AUTHOR. comment-entry-1... ]",
        "[INSTALLATION. comment-entry-2... ]",
        "[DATE-WRITTEN. comment-entry-3... ]",
        "[DATE-COMPILED. comment-entry-4... ]",
        "[SECURITY. comment-entry-5... ]"
       .

      * The PROGRAM-ID statement defines a main or nested COBOL program.
       PROCEDURE-ID. PROGRAM-ID IS
        ". {program-name-1 [AS literal-1]}... ",
        "[{IS {COMMON or INITIAL or RECURSIVE} PROGRAM or",
        " IS PROTOTYPE}]",
        "[options-paragraph]",
        "[environment-division]",
        "[data-division]",
        "[procedure-division]",
        "END PROGRAM program-name-1."
       .

      * The FUNCTION-ID statement defines a function or function
      * prototype.
       PROCEDURE-ID. FUNCTION-ID IS
        ". {function-name-1 [AS literal-1]}... [IS PROTOTYPE].",
        "[options-paragraph]",
        "[environment-division]",
        "[data-division]",
        "[procedure-division]",
        "END FUNCTION function-name-1."
       .

      * The CLASS-ID statement defines a COBOL class.
       PROCEDURE-ID. CLASS-ID IS
        ". {class-name-1 [AS literal-1]}",
        "[INHERITS FROM {class-name-2}...]",
        "[USING {parameter-name-1}...].",
        "[environment-division]",
        "[factory-division]",
        "[object-division]",
        "END CLASS class-name-1."
       .

      * The INTERFACE-ID statement defines a COBOL class interface.
       PROCEDURE-ID. INTERFACE-ID IS
        ". {interface-name-1 [AS literal-1]}",
        "[INHERITS FROM {interface-name-2}...]",
        "[USING {parameter-name-1}...].",
        "[environment-division]",
        "[PROCEDURE DIVISION.  {method-definition}...]",
        "END INTERFACE interface-name-1."
       .

      * The FACTORY statement defines the factory section of a class.
      * The factory section defines all the class specific data and
      * methods, such as "New" or "Finalize".
       PROCEDURE-ID. FACTORY IS
        ".",
        "[options-paragraph]",
        "[environment-division]",
        "[data-division]",
        "[PROCEDURE DIVISION.  {method-definition}...]",
        "END FACTORY."
       .

      * The OBJECT statement defines the object section of a class.
      * The object section defines all the instance specific data
      * and methods for the object.
       PROCEDURE-ID. OBJECT IS
        ".",
        "[options-paragraph]",
        "[environment-division]",
        "[data-division]",
        "[PROCEDURE DIVISION.  {method-definition}...]",
        "END OBJECT."
       .

      * The CLASS-OBJECT statement defines the object section of a
      * class. The object section defines all the object specific data
      * and methods (Microfocus specific version of FACTORY).
       PROCEDURE-ID. CLASS-OBJECT IS
        ".",
        "[options-paragraph]",
        "[environment-division]",
        "[data-division]",
        "[PROCEDURE DIVISION.  {method-definition}...]",
        "END CLASS-OBJECT."
       .

      * The METHOD-ID statement defines a class method, its local
      * and working storage, and procedure section.
       PROCEDURE-ID. METHOD-ID IS
        ". {method-name-1 [AS literal-1] or",
        "{GET or SET} PROPERTY property-name-1} [OVERRIDE].",
        "[options-paragraph]",
        "[environment-division]",
        "[data-division]",
        "[procedure-division]",
        "END METHOD method-name-1."
       .

      * The OPTIONS paragraph defines options used when executing
      * the given COBOL program, such as arithmetic, calling,
      * and localization conventions.
       PROCEDURE-ID. OPTIONS IS
        ".",
        "[ARITHMETHIC IS {NATIVE or STANDARD}]",
        "[CALL-CONVENTION IS {call-convention-name-1 or NESTED}]",
        "[LOCALIZE {LC_COLLATE or LC_CYTPE or LC_CURRENCY}]"
       .

      /*****************************************************************
      ** COBOL ENVIRONMENT DIVISION, SYNTAX DIAGRAMS                  **
      ******************************************************************

      * The ENVIRONMENT DIVISION specifies the aspects of the
      * particular program that depend on certain hardware.
       PROCEDURE-ID. ENVIRONMENT IS
        "DIVISION.",
        "[configuration-section]",
        "[input-ouput-section]"
       .

      * The CONFIGURE SECTION describes the source computer, symbol
      * characters, character sets, mnemonic names and sorting orders.
       PROCEDURE-ID. CONFIGURATION IS
        "SECTION.",
        "[source-computer-paragarph]",
        "[object-computer-paragraph]",
        "[special-names-paragraph]",
        "[repository-paragraph]"
       .

      * The SOURCE-COMPUTER paragraph defines the system where
      * the program is compiled.
       PROCEDURE-ID. SOURCE-COMPUTER IS
        ". [computer-name [WITH DEBUGGING MODE].]"
       .

      * The OBJECT-COMPUTER paragraph defines the hardware where
      * program is run.  It is not required to be the same as the
      * SOURCE-COMPUTER name.
       PROCEDURE-ID. OBJECT-COMPUTER IS
        ". [computer-name ",
        "[PROGRAM COLLATING SEQUENCE [FOR ALPHANUMERIC]",
        " IS alphabet-name-1 [FOR NATIONAL IS] alphabet-name-2].]"
       .

      * The SPECIAL-NAMES paragraph associates implementor names with
      * mnenmonic names and conditions, defines alphabets, symbolic
      * characters, creates class conditions, and specifies the default
      * decimal point and currency symbols.
       PROCEDURE-ID. SPECIAL-NAMES IS
        ".",
        "[switch-name-1",
        "[IS mnemonic-name-1][{ON or OFF}",
        " STATUS IS condition-name-1]...",
        "feature-name-1 IS mnemonic-name-2",
        "device-name-1 IS mnemonic-name-3",
        "report-attribute-name IS mnemmonic-name-4]...",
        "[ALPHABET {",
        " FOR ALPHANUMERIC alphabet-name-1 IS",
        "  {LOCALE or NATIVE or STANDARD-n or code-name-1 or",
        "   {literal-phrase}...}",
        " FOR NATIONAL alphabet-name-2 IS",
        "  {LOCALE or NATIVE or STANDARD-3 or UCS-2 or UCS-4 or",
        "   UTF-8 or UTF-16 or code-name-2 or {literal-phrase}...}}]",
        "[SYMBOLIC-CHARACTERS [FOR {ALPHANUMERIC or NATIONAL}]",
        " {symbolic-character-1}... {IS or ARE} {integer-1}...]",
        " [IN alphabet-name-3]",
        "[symbolic-characters-clause]...",
        "[LOCALE {locale-name-1 or literal-4} IS mnemonic-name-5]",
        "[CLASS class-name-1 [FOR {ALPHANUMERIC or NATIONAL}]",
        " IS {literal-5 [[THROUGH or THRU] literal-6]}...",
        " [IN alphabet-name-4]]...",
        "[CURRENCY SIGN IS {literal-7 or data-name-1}",
        " [WITH PICTURE SYMBOL literal-8]]...",
        "[DECIMAL-POINT IS COMMA]",
        "[CURSOR IS data-name-2]",
        "[CRT-STATUS IS data-name-3]"
       .

      * The REPOSITORY paragraph describes the modules and objects
      * composing the application or used by the current module.
       PROCEDURE-ID. REPOSITORY IS
        ".",
        "[CLASS class-name-1 [AS literal-1 or",
        " EXPANDS class-name-2",
        " USING {class-name-3 or interface-name-1}...]]",
        "[INTERFACE class-name-1 [AS literal-1 or",
        " EXPANDS class-name-2",
        " USING {class-name-3 or interface-name-1}...]]",
        "[FUNCTION function-prototype-name-1 [AS literal-3]]",
        "[FUNCTION {ALL or {intrinsic-func-name-1}...} INTRINSIC]",
        "[PROGRAM program-prototype-name-1 [AS literal-4]]",
        "[PROPERTY property-name-1 [AS literal-5]]"
       .

      * The INPUT-OUPUT section associates system file names and devices
      * with program file names, defines the physical location of files,
      * and defines characteristics of the devices where the files are
      * stored.
       PROCEDURE-ID. INPUT-OUTPUT IS
        "SECTION.",
        "[FILE-CONTROL. {file-control-entry}...]",
        "[I-O-CONTROL.  {i-o-control-entry}...]"
       .

      * The FILE-CONTROL section associates a program name with an
      * external file.  A file control entry or SELECT statement
      * defines and describes each file; file control entry or SELECT
      * statement appears for each file used by the program.
       PROCEDURE-ID. FILE-CONTROL IS
        ".",
        "[select-statement]..."
       .

      * The CLASS-CONTROL section associates a class with the external
      * names for other classes which it depends on.
       PROCEDURE-ID. CLASS-CONTROL IS
        ".",
        "{class-name-1 IS CLASS external-name-1}..."
       .

      * This form of the SELECT statement defines a sequential file,
      * ie, where records are written in serial order and read in the
      * same order as written.
       PROCEDURE-ID. SELECT IS
        "[OPTIONAL] file-name-1",
        "ASSIGN [TO {device-name-1 OR literal-1}...]",
        "[USING data-name-1]",
        "[ACCESS MODE IS SEQUENTIAL]",
        "[FILE STATUS is data-name-4]",
        "[LOCK MODE IS {MANUAL or AUTOMATIC}",
        "[WITH LOCK ON {RECORD or RECORDS}]]",
        "[ORGANIZATION IS] SEQUENTIAL",
        "[PADDING CHARACTER IS {data-name-8 or literal-2}]",
        "RECORD DELIMITER IS {STANDARD-1 or feature-name-1}",
        "[RESERVE integer-1 [ALTERNATE] [AREA or AREAS]]",
        "[SHARING WITH {ALL OTHER or NO OTHER or READ ONLY}]"
       .
      * This form of the SELECT statement defines a relative file
      * ie, one in which records are accessed by reference to their
      * relative position in the file.
       PROCEDURE-ID. SELECT IS
        "[OPTIONAL] file-name-1",
        "ASSIGN [TO {device-name-1 OR literal-1}...]",
        "[USING data-name-1]",
        "[ACCESS MODE IS {DYNAMIC or RANDOM or SEQUENTIAL}]",
        "[FILE STATUS is data-name-4]",
        "[LOCK MODE IS {MANUAL or AUTOMATIC}",
        "[WITH LOCK ON [MULTIPLE] {RECORD or RECORDS}]]",
        "[ORGANIZATION IS] RELATIVE",
        "[RESERVE integer-1 [ALTERNATE] [AREA or AREAS]]",
        "[SHARING WITH {ALL OTHER or NO OTHER or READ ONLY}]"
       .
      * This form of the SELECT statment defines an indexed file, which
      * allows for sequential file organization but also allows the
      * random access or processing of relative files.
       PROCEDURE-ID. SELECT IS
        "[OPTIONAL] file-name-1",
        "ASSIGN [TO {device-name-1 OR literal-1}...]",
        "[USING data-name-1]",
        "[ACCESS MODE IS {DYNAMIC or RANDOM or SEQUENTIAL}]",
        "[ALTERNATE RECORD KEY IS ",
        " {data-name-1 or record-key-name-1",
        "  SOURCE IS {data-name-3}...} [WITH DUPLICATES]]...",
        "[COLLATING SEQUENCE [FOR ALPHANUMERIC] IS alphabet-name-1",
        "   [FOR NATIONAL IS] alphabet-name-2]",
        "[FILE STATUS is data-name-4]",
        "[LOCK MODE IS {MANUAL or AUTOMATIC}",
        " [WITH LOCK ON [MULTIPLE] {RECORD or RECORDS}]]",
        "[ORGANIZATION IS] INDEXED",
        "RECORD KEY IS {data-name-5 or record-key-name-2",
        " SOURCE IS {data-name-3}...}",
        "[RESERVE integer-1 [ALTERNATE] [AREA or AREAS]]",
        "[SHARING WITH {ALL OTHER or NO OTHER or READ ONLY}]"
       .
      * This form of the SELECT statment defines a sort-merge file
      * which contains a collection of records to be sorted or merged.
       PROCEDURE-ID. SELECT IS
        "[OPTIONAL] file-name-1",
        "ASSIGN [TO {device-name-1 OR literal-1}...]",
        "[USING data-name-1]",
        "[[ORGANIZATION IS] SEQUENTIAL]"
       .
      * This form of the SELECT statement defines a report file,
      * which is a sequential output file, where records are written
      * by the Report Writer Control System.
       PROCEDURE-ID. SELECT IS
        "[OPTIONAL] file-name-1",
        "ASSIGN [TO {device-name-1 OR literal-1}...]",
        "[USING data-name-1]",
        "[ACCESS MODE IS SEQUENTIAL]",
        "[FILE STATUS is data-name-4]",
        "[[ORGANIZATION IS] SEQUENTIAL]",
        "[PADDING CHARACTER IS {data-name-8 or literal-2}]",
        "RECORD DELIMITER IS {STANDARD-1 or feature-name-1}",
        "[RESERVE integer-1 [ALTERNATE] [AREA or AREAS]]"
       .

      * The I-O-CONTROL section specifies how files are stored on a
      * device, specifically how they are stored on a tape device.
       PROCEDURE-ID. I-O-CONTROL IS
        ".",
        "[RERUN [ON {file-name-1 or implementor-name-1}] EVERY {",
        " [END OF] {REEL or UNIT} OF file-name-2 or",
        " integer-1 RECORDS or integer-2 CLOCK-UNITS or",
        " condition-name-1}]...",
        "[SAME [RECORD or SORT or SORT-MERGE] AREA",
        " FOR file-name-1 {file-name-2}...]...",
        "[MULTIPLE FILE TAPE CONTAINS {file-name-3",
        " [POSITION IS integer-1]}...]..."
       .

      /*****************************************************************
      ** COBOL DATA DIVISION, SYNTAX DIAGRAMS                         **
      ******************************************************************

      * The DATA DIVISION defines the data used by the program, the
      * heirarchical relationships of the data, and condition names.
       PROCEDURE-ID. DATA IS
        "DIVISION.",
        "[FILE SECTION. [file-description-entry]...]",
        "[WORKING-STORAGE SECTION. [data-description-entry]...]",
        "[LOCAL-STORAGE SECTION. [data-description-entry]...]",
        "[LINKAGE SECTION. [data-description-entry]...]",
        "[COMMUNICATION SECTION. [comm-description-entry]...]",
        "[REPORT SECTION. [report-description-entry]...]",
        "[SCREEN SECTION. [screen-description-entry]...]"
       .

      * The FILE SECTION describes the record structure of files.
      * Each file used by a program must have a file-control entry,
      * depending on its file type.
       PROCEDURE-ID. FILE IS
        "SECTION.",
        "[FD file-description-entry",
        "  [constant-entry or record-description-entry]...]...",
        "[SD sort-merge-description-entry",
        "  {constant-entry or record-description-entry}...]..."
       .

      * The WORKING-STORAGE SECTION defines data items that aren't
      * associated with any files.
       PROCEDURE-ID. WORKING-STORAGE IS
        "SECTION.",
        "[77 level-description-entry or",
        " 01 constant-entry or data-description-entry]..."
       .

      * The WORKING-STORAGE SECTION defines data items belonging to
      * current the function or method.
       PROCEDURE-ID. LOCAL-STORAGE IS
        "SECTION.",
        "[77 level-description-entry or",
        " 01 constant-entry or data-description-entry]..."
       .

      * The LINKAGE SECTION describes data made available from another
      * program or method when the program is called from another
      * program.
       PROCEDURE-ID. LINKAGE IS
        "SECTION.",
        "[77 level-description-entry or",
        " 01 constant-entry or data-description-entry]..."
       .

      * The COMMUNICATION SECTION defines data elements that are
      * used when communication with system devices.
       PROCEDURE-ID. COMMUNICATION IS
        "SECTION.",
        "[CD communication-description-entry",
        "  [constant-entry or record-description-entry]...]...",
       .

      * The REPORT SECTION defines a report and its associated data
      * items.
       PROCEDURE-ID. REPORT IS
        "SECTION.",
        "[RD report-description-entry",
        "  [constant-entry or report-group-description-entry]...]...",
       .

      * The SCREEN SECTION defines a screen layout and its associated
      * data items.
       PROCEDURE-ID. SCREEN IS
        "SECTION.",
        "[constant-entry or screen-description-entry]..."
       .

      * This form of the CD statement defines a communications
      * device opened for input.
       PROCEDURE-ID. CD IS
        "cd-name-1 FOR [INITIAL] INPUT",
        "[SYMBOLIC QUEUE IS data-name-1]",
        "[SYMBOLIC SUB-QUEUE-1 IS data-name-2]",
        "[SYMBOLIC SUB-QUEUE-2 IS data-name-3]",
        "[SYMBOLIC SUB-QUEUE-3 IS data-name-4]",
        "[MESSAGE DATE is data-name-5]",
        "[MESSAGE TIME is data-name-6]",
        "[SYMBOLIC SOURCE is data-name-7]",
        "[TEXT LENGTH IS data-name-8]",
        "[END KEY IS data-name-9]",
        "[STATUS KEY IS data-name-10]",
        "[MESSAGE COUNT IS data-name-11]"
       .
      * This form of the CD statement defines a communication
      * device opened for output.
       PROCEDURE-ID. CD IS
        "cd-name-1 FOR OUTPUT",
        "[DESTINATION COUNT IS data-name-1]",
        "[TEXT LENGTH IS data-name-2]",
        "[STATUS KEY IS data-name-3]",
        "[DESTINATION TABLE OCCURS integer-1 TIMES",
        "[INDEXED BY {index-name-1}...]]",
        "[ERROR KEY IS data-name-4]",
        "[SYMBOLIC DESTINATION IS data-name-5]"
       .
      * This form of the CD statement defines a communication
      * device opened for input and output.
       PROCEDURE-ID. CD IS
        "cd-name-1 FOR [INITIAL] I-O",
        "[MESSAGE DATE is data-name-1]",
        "[MESSAGE TIME is data-name-2]",
        "[SYMBOLIC TERMINAL is data-name-3]",
        "[TEXT LENGTH IS data-name-4]",
        "[END KEY IS data-name-5]",
        "[STATUS KEY IS data-name-16]"
       .

      * This form of the FD statement defines a logical
      * file device for a sequential file.
       PROCEDURE-ID. FD IS
        "file-name-1 [IS EXTERNAL [AS literal-1]] [IS GLOBAL]",
        "[FORMAT {CHARACTER or BIT or NUMERIC} DATA]",
        "[BLOCK CONTAINS [integer-1 TO] integer-2",
        " {RECORDS or CHARACTERS}]",
        "[LINAGE IS {data-name-2 or integer-8} LINES",
        " [WITH FOOTING AT {data-name-3 or integer-9}]",
        " [LINES AT TOP {data-name-4 or integer-10}]",
        " [LINES AT BOTTOM {data-name-4 or integer-10}]]",
        "[CODE-SET [FOR ALPHANUMERIC] IS alphabet-name-1",
        "   [FOR NATIONAL IS] alphabet-name-2]"
       .
      * This form of the FD statement defines a logical
      * file device for a relative or indexed file.
       PROCEDURE-ID. FD IS
        "file-name-1 [IS EXTERNAL [AS literal-1]] [IS GLOBAL]",
        "[BLOCK CONTAINS [integer-1 TO] integer-2",
        " {RECORDS or CHARACTERS}]",
        "[RECORD {CONTAINS integer-3 CHARACTERS or",
        " IS VARYING IN SIZE",
        " [[FROM integer-4][TO integer-5] CHARACTERS]",
        "  [DEPENDING ON data-name-1] or",
        " CONTAINS integer-6 to integer-7 CHARACTERS}]"
       .
      * This form of the FD statement defines a logical
      * file device for a report file.
       PROCEDURE-ID. FD IS
        "file-name-1 [IS EXTERNAL [AS literal-1]] [IS GLOBAL]",
        "[BLOCK CONTAINS [integer-1 TO] integer-2",
        " {RECORDS or CHARACTERS}]",
        "[RECORD {CONTAINS integer-3 CHARACTERS or",
        " IS VARYING IN SIZE",
        " [[FROM integer-4][TO integer-5] CHARACTERS]",
        "  [DEPENDING ON data-name-1] or",
        " CONTAINS integer-6 to integer-7 CHARACTERS}]",
        "[CODE-SET [FOR ALPHANUMERIC] IS alphabet-name-1",
        "  [FOR NATIONAL IS] alphabet-name-2]",
        "{REPORT IS or REPORTS ARE} {report-name-1}..."
       .

      * The SD statement defines a sort-merge file description.
       PROCEDURE-ID. SD IS
        "file-name-1",
        "[RECORD {CONTAINS integer-3 CHARACTERS or",
        " IS VARYING IN SIZE",
        " [[FROM integer-4][TO integer-5] CHARACTERS]",
        "  [DEPENDING ON data-name-1] or",
        " CONTAINS integer-6 to integer-7 CHARACTERS}]"
       .

      * The RD statement defines a report description.
       PROCEDURE-ID. RD IS
        "report-name-1 [IS GLOBAL]",
        "[ATTRIBUTE IS mnemonic-name-1]",
        "[CODE IS {literal-1 or identifer-1}]",
        "[{CONTROL IS or CONTROLS ARE} {{data-name-1}... or",
        " FINAL [data-name-1]...}]",
        "[PAGE [LIMIT IS or LIMITS ARE]",
        " [integer-1 [LINE or LINES] [integer-2 [COLS or COLUMNS]]]",
        " [HEADING IS integer-3] [FIRST {DETAIL or DE} IS integer-4]",
        " [LAST {CONTROL HEADING or CH} IS integer-5]",
        " [LAST {DETAIL or DE} IS integer-6] [FOOTING IS integer-7]]"
       .

      * A 01 level entry defines a data constant.
       PROCEDURE-ID. 01 IS
        "constant-name-1 CONSTANT [IS GLOBAL] AS literal-1"
       .
      * A data level-number entry defining a data item in the
      * working storage, linkage, or local storage section.
       PROCEDURE-ID. 99 IS
        "{data-name-1 or FILLER}",
        "[REDEFINES data-name-2] [IS TYPEDEF [STRONG]]",
        "[IS EXTERNAL [AS literal-1]] [IS GLOBAL]",
        "[{PICTURE or PIC} IS character-string",
        " [SIZE IS integer-1 LOCALE [IS mnemonic-name-1]]]",
        "[USAGE IS usage-clause]",
        "[[SIGN IS] {LEADING or TRAILING} [SEPARATE CHARACTER]]",
        "[OCCURS integer-2 TIMES [TO integer-2 TIMES",
        " DEPENDING ON data-name-1]",
        "    [EXTEND [BY integer-3] [UNTIL integer-4]]",
        "  [{ASCENDING or DESCENDING} KEY IS {data-name-2}...]...",
        "  [INDEXED BY {index-name-1}...]]",
        "[{SYNCHRONIZED or SYNC} [LEFT OR RIGHT]]",
        "[{JUSTIFIED or JUST} RIGHT]",
        "[BLANK WHEN ZERO]",
        "[VALUE IS literal-2 {",
        "  {VALUE or VALUES} [FROM({subsscript-1}...)]",
        "   [IS or ARE] {literal-1}...",
        "  REPEATED {integer-1 TIMES or TO END}]}",
        "[WITH POINTER [data-name-7]]",
        "[SAME AS data-name-5]",
        "[SELECT WHEN {condition-name-1 or OTHER}]",
        "[TYPE type-name-1]",
        "[{ALLOW [ONLY] literal-3 [OR literal-4]...",
        "  [WHEN condition-1]}...]",
        "[class-clause] [default-clause] [error-clause]",
        "[DESTINATION IS {indentifier-2}...]",
        "[{INVALID WHEN condition-name-2}...]",
        "  [PRESENT WHEN condition-3]",
        "[VARYING {data-name-6 [FROM expression-1]",
        " [BY expression-2]}...]"
       .
      * A data level-number entry defining a data item in a report.
       PROCEDURE-ID. 99 IS
        "[data-name-1]",
        "[TYPE IS {type-name-1 or {REPORT or PAGE or CONTROL}",
        " {HEADING or FOOTING} or DETAIL}]",
        "[NEXT GROUP IS {integer-1 or {PLUS or +} integer-2 or",
        " NEXT PAGE [WITH RESET]}]",
        "[{LINE or LINES} {NUMBER or NUMBERS} [IS or ARE]",
        " {[integer-1] ON NEXT PAGE or {PLUS or +} integer-2}]",
        "[{PICTURE or PIC} IS character-string",
        " [SIZE IS integer-1 LOCALE [IS mnemonic-name-1]]]",
        "[[USAGE IS] {DISPLAY or NATIONAL}]",
        "[[SIGN IS] {LEADING or TRAILING} [SEPARATE CHARACTER]]",
        "[{JUSTIFIED or JUST} RIGHT]",
        "[{COLUMN or COL or COLUMNS COLS} {NUMBER or NUMBERS}",
        "  {LEFT or CENTER or RIGHT} [IS or ARE]",
        "  {integer-1 or {PLUS or +} integer-2}...]",
        "[BLANK WHEN ZERO]",
        "[{SOURCE or SOURCES} [IS or ARE]",
        " {identifier-1 or expression-1}... [ROUNDED]]",
        "[{SUM OF {data-name-1 or identifer-1 or expression-1}...",
        "  [UPON {data-name-2}...] }...",
        "  [RESET ON {data-name-3 or FINAL}] [ROUNDED]]",
        "[{VALUE or VALUES} [IS or ARE] {literal-1}...]",
        "[{[NO] ERROR STATUS IS {literal-1 or identifier-1}}",
        "  [ON {FORMAT or CONTENT or RELATION}",
        "   FOR {identifier-3}...]]",
        "[{PRESENT or ABSENT} WHEN conditaion-1]",
        "[GROUP INDICATE]",
        "[OCCURS [integer-1 TO] integer-2 TIMES",
        " [DEPENDING ON identifier-1] [STEP integer-3]]",
        "[VARYING {data-name-1",
        " [FROM expression-1] [BY expression-2]}...]"
       .
      * A data level-number entry defining a data group
      * in a screen definition.
       PROCEDURE-ID. 99 IS
        "[screen-name-1 or FILLER] [IS GLOBAL]",
        "[LINE NUMBER IS [PLUS or MINUS] {identifer-1 or integer-1}]",
        "[{COLUMN or COL} NUMBER IS [PLUS or MINUS]",
        " {identifer-2 or integer-2}]",
        "[BLANK SCREEN] [BELL] [BLINK] [HIGHLIGHT or LOWLIGHT]",
        "[REVERSE-VIDEO] [UNDERLINE]",
        "[FOREGROUND-COLOR IS {identifier-3}]",
        "[BACKGROUND-COLOR IS {identifier-4}]",
        "[[SIGN IS] {LEADING or TRAILING} [SEPARATE CHARACTER]]",
        "[FULL] [AUTO] [SECURE] [REQUIRED]",
        "[OCCURS integer-5 TIMES]",
        "[[USAGE IS] {DISPLAY or NATIONAL}]"
       .
      * A data level-number entry defining a elementary data item
      * in a screen definition.
       PROCEDURE-ID. 99 IS
        "[screen-name-1 or FILLER] [IS GLOBAL]",
        "[LINE NUMBER IS [PLUS or MINUS] {identifer-1 or integer-1}]",
        "[{COLUMN or COL} NUMBER IS [PLUS or MINUS]",
        " {identifer-2 or integer-2}]",
        "[BLANK {LINE or SCREEN}]",
        "[ERASE {END OF LINE or EOL or END OF SCREEN or EOS}]",
        "[BELL] [BLINK] [HIGHLIGHT or LOWLIGHT]",
        "[REVERSE-VIDEO] [UNDERLINE]",
        "[FOREGROUND-COLOR IS {identifier-3}]",
        "[BACKGROUND-COLOR IS {identifier-4}]",
        "[{PICTURE or PIC} IS character-string",
        " [SIZE IS integer-1 LOCALE [IS mnemonic-name-1]]]",
        "[{FROM {identifer-5 or literal-1} or TO identifier-6} or",
        " USING identifier-7 or VALUE literal-2]",
        "[BLANK WHEN ZERO]",
        "[{JUSTIFIED or JUST} RIGHT]",
        "[[SIGN IS] {LEADING or TRAILING} [SEPARATE CHARACTER]]",
        "[FULL] [AUTO] [SECURE] [REQUIRED]",
        "[OCCURS integer-5 TIMES]",
        "[[USAGE IS] {DISPLAY or NATIONAL}]"
       .

      * A 66 level entry renames an existing set of data items.
       PROCEDURE-ID. 66 IS
        "data-name-1 RENAMES data-name-2",
        "[{THROUGH or THRU} data-name-3]"
       .

      * A 77 level number entry defines data items that don't fit
      * into the record heirarchy for the working storage, linkage,
      * or local storage section.
       PROCEDURE-ID. 77 IS
        "{data-name-1 or FILLER}",
        "[REDEFINES data-name-2] [IS TYPEDEF [STRONG]]",
        "[IS EXTERNAL [AS literal-1]] [IS GLOBAL]",
        "[{PICTURE or PIC} IS character-string",
        " [SIZE IS integer-1 LOCALE [IS mnemonic-name-1]]]",
        "[USAGE IS usage-clause]",
        "[[SIGN IS] {LEADING or TRAILING} [SEPARATE CHARACTER]]",
        "[OCCURS integer-2 TIMES",
        " [TO integer-2 TIMES DEPENDING ON data-name-1]",
        "    [EXTEND [BY integer-3] [UNTIL integer-4]]",
        "  [{ASCENDING or DESCENDING} KEY IS {data-name-2}...]...",
        "  [INDEXED BY {index-name-1}...]]",
        "[{SYNCHRONIZED or SYNC} [LEFT OR RIGHT]]",
        "[{JUSTIFIED or JUST} RIGHT]",
        "[BLANK WHEN ZERO]",
        "[VALUE IS literal-2 [",
        "  {VALUE or VALUES}",
        "   [FROM({subsscript-1}...)] [IS or ARE] {literal-1}...",
        "  REPEATED {integer-1 TIMES or TO END}]]",
        "[WITH POINTER [data-name-7]]",
        "[SAME AS data-name-5]",
        "[SELECT WHEN {condition-name-1 or OTHER}]",
        "[TYPE type-name-1]",
        "[{ALLOW [ONLY] literal-3 [OR literal-4]...",
        "  [WHEN condition-1]}...]",
        "[class-clause] [default-clause] [error-clause]",
        "[DESTINATION IS {indentifier-2}...]",
        "[{INVALID WHEN condition-name-2}...]",
        "  [PRESENT WHEN condition-3]",
        "[VARYING {data-name-6",
        " [FROM expression-1] [BY expression-2]}...]"
       .

      * An 88 level entry defines a condition name.
       PROCEDURE-ID. 88 IS
        "condition-name-2 {INVALID or VALID}",
        "{VALUE or VALUES} [IS or ARE]",
        "literal-1 [{THROUGH or THRU} literal-7]",
        "[WHEN {condition-4 or SET TO FALSE IS literal-8}]"
       .

      /*****************************************************************
      ** COBOL PROCEDURE DIVISION, SYNTAX DIAGRAMS                    **
      ******************************************************************
       FUNCTION-ID.      *> stop comment lookup

      * The PROCEDURE DIVISION defines all the methods, functions, or
      * procedures for the program, class, method, or function.
       PROCEDURE-ID. PROCEDURE IS
        "DIVISION",
        "[USING {[BY REFERENCE] {[OPTIONAL] data-name-1}... or",
        "  BY VALUE {data-name-1}...}...]",
        "[RETURNING data-name-2]",
        "[RAISING {exception-name-1 or class-name-1 or",
        " interface-name-1}...]",
        "[declaratives-section]",
        "{[section-name SECTION.]",
        " [paragraph-name. [sentence]...]...}..."
       .

      * The DECLARATIVES section defines a group of one or more special
      * purpose procedures.
       PROCEDURE-ID. DECLARATIVES IS
        ".",
        "{section-name SECTION.",
        "  use-statement.",
        "[paragraph-name. [sentence]...]...}...",
        "END DECLARATIVES"
       .

      /*****************************************************************
      ** COBOL STATEMENTS, SYNTAX DIAGRAMS                            **
      ******************************************************************
       FUNCTION-ID.      *> stop comment lookup

      * The ACCEPT statement stores data from a terminal, hardware
      * device, or date information into a user-defined data item.
       PROCEDURE-ID. ACCEPT IS
        "identifier-1 [FROM mnemonic-name-1]",
        "[END-ACCEPT]"
       .
      * This form of the ACCEPT statement isused to get the current
      * date or time.
       PROCEDURE-ID. ACCEPT IS
        "identifier-2 FROM {DATE or DAY or DAY-OF-WEEK or TIME}",
        "[END-ACCEPT]"
       .
      * This form of the ACCEPT statement is used to get the message
      * count from a communications device.
       PROCEDURE-ID. ACCEPT IS
        "cd-name-1 [MESSAGE] COUNT"
       .
      * This form of the ACCEPT statement used to pull data off of
      * a user session (screen).
       PROCEDURE-ID. ACCEPT IS
        "screen-name-1 [AT",
        "{LINE NUMBER {identifier-1 or integer-1} or",
        "{COLUMN or COL} NUMBER {identifier-2 or integer-2}}]",
        "[ON EXCEPTION imperative-statement-1]",
        "[NOT ON EXCEPTION imperative-statement-2]",
        "[END-ACCEPT]"
       .

      * The ADD statement sums one or more data items and
      * stores the result in another data item.
       PROCEDURE-ID. ADD IS
        "{identifier-1 or literal-1}...",
        " TO {identifer-2 [ROUNDED]}...",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-ADD]"
       .
      * This form of the ADD statement places the result in
      * 'identifier-3' leaving the other identifiers unchanged.
       PROCEDURE-ID. ADD IS
        "{identifier-1 or literal-1}...",
        " TO {identifer-2 or literal-2}",
        "GIVING {identifier-3 [ROUNDED]}...",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-ADD]"
       .
      * This form of the ADD statement adds all matching (like-named)
      * items in two groups.
       PROCEDURE-ID. ADD IS
        "{CORRESPONDING or CORR} identifier-1 TO identifer-2",
        "[ROUNDED] [ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-ADD]"
       .

      * The ALLOCATE statement is used to allocate space dynamically.
       PROCEDURE-ID. ALLOCATE IS
        "{arithmetic-expression-1 CHARACTERS or",
        " data-name-1 or type-name-1}",
        "[INITIALIZED] RETURNING pointer-name-1"
       .
       
      * The ALTER statement changes the destination of a GO TO
      * statement from one procedure name to another.
       PROCEDURE-ID. ALTER IS
        "{procedure-name-1 TO [PROCEED TO] procedure-name-2}..."
       .
                                          
      * The CALL statement transfers control from one program
      * to another.                                          
       PROCEDURE-ID. CALL IS
        "{identifier-1 or literal-1 or procedure-pointer-1}",
        "[USING {[BY REFERENCE or CONTENT] identifier-2}...]",
        "[RETURNING identifier-3]",
        "[ON OVERFLOW imperative-statement-1]",
        "[END-CALL]"
       .
      * This form of the CALL statement allows you to specify
      * an exception handler.
       PROCEDURE-ID. CALL IS
        "{identifier-1 or literal-1 or procedure-pointer-1}",
        "[USING {[BY REFERENCE or CONTENT] identifier-2}...]",
        "[RETURNING identifier-3]",
        "[ON EXCEPTION imperative-statement-2]",
        "[NOT ON EXCEPTION imperative-statement-3]",
        "[END-CALL]"
       .
      * This form of the CALL statement is used to call another
      * COBOL program using prototype.
       PROCEDURE-ID. CALL IS
        "[{identifier-1 or literal-1} AS] program-prototype-name-1",
        " [USING [BY REFERENCE] {identifier-2 or OMITTED}",
        "[BY CONTENT] {identifier-2 or literal-2}",
        "[BY VALUE] arithmentic-expression-1 ]",
        "[RETURNING identifier-3]",
        "[ON EXCEPTION imperative-statement-2]",
        "[NOT ON EXCEPTION imperative-statement-3]",
        "[END-CALL]"
       .

      * The CANCEL statement ensures that the next time a program is
      * called using the CALL command, it is returned to its initial
      * state.
       PROCEDURE-ID. CANCEL IS
        "{identifier-1 or literal-1 or program-pointer-1",
        " or program-prototype-name-1}..."
       .

      * MicroFocus COBOL specific version of CALL statement.
       PROCEDURE-ID. CHAIN IS
        "{identifier-1 or literal-1} [USING",
        "[BY REFERENCE] {identifier-2 or literal-2 or",
        " OMITTED or ADDRESS OF identifier-3}",
        "[BY CONTENT] {identifier-4 or literal-3",
        " or LENGTH OF identifier-5}",
        "[BY VALUE] {identifier-6 or literal-4",
        " or LENGTH OF identifier-7}",
        "[END-CHAIN]"
       .

      * The CLOSE statement finishes the processing of a file.
      * If the file is stored on a tape, the CLOSE command can also
      * rewind and lock the tape.
       PROCEDURE-ID. CLOSE IS
        "{file-name-1 [{REEL or UNIT}",
        " [FOR REMOVAL] or WITH {NO REWIND or LOCK}] }..."
       .

      * The COMMIT statement commits the current transaction.
       PROCEDURE-ID. COMMIT.

      * The COMPUTE statement stores the result of an arithmetic
      * expression into a data item.
       PROCEDURE-ID. COMPUTE IS
        "{identifier-1 [ROUNDED]}... = arithmetic-expression-1",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-COMPUTE]"
       .
      * This form of the COMPUTE statement is used to compute a
      * boolean expresssion.
       PROCEDURE-ID. COMPUTE IS
        "{identifier-1}... = boolean-expression-1",
        "[END-COMPUTE]"
       .

      * The CONTINUE statement does nothing.
       PROCEDURE-ID. CONTINUE.

      * The DELETE command removes a record from a file.
       PROCEDURE-ID. DELETE IS
        "file-name-1 RECORD",
        "[TIMEOUT {AFTER arithmetic-expression-2 SECONDS or RETRY",
        " {arithmentic-expression-2 or NO LIMIT} TIMES}]",
        "[INVALID KEY imperative-statement-1]",
        "[NOT INVALID KEY imperative-statement-2]",
        "[END-DELETE]"
       .

      * The DISABLE statement stops transfers of information
      * between input queues and destinations.
       PROCEDURE-ID. DISABLE IS
        "{INPUT [TERMINAL] or I-O TERMINAL or OUTPUT} cd-name-1",
        "[WITH KEY {identifier-1 or literal-1}]"
       .

      * The DISPLAY statement displays the contents of a data item
      * on a terminal or hardware device.
       PROCEDURE-ID. DISPLAY IS
        "{identifier-1 or literal-1}...",
        "[UPON mnemonic-name-1] [WITH NO ADVANCING]",
        "[END-DISPLAY]"
       .
      * This form of the DISPLAY statement is used to display output
      * on the screen device at a specified line and column.
       PROCEDURE-ID. DISPLAY IS
        "screen-name-1 [AT",
        "{LINE NUMBER {identifier-1 or integer-1} or",
        "{COLUMN or COL} NUMBER {identifier-2 or integer-2}}]",
        "[ON EXCEPTION imperative-statement-1]",
        "[NOT ON EXCEPTION imperative-statement-2]",
        "[END-DISPLAY]"
       .

      * The DIVIDE statement divides one data item into another
      * data item and stores the result or the quotient and remainder
      * into other data items.
       PROCEDURE-ID. DIVIDE IS
        "{identifier-1 or literal-1}...",
        "INTO {identifer-2 [ROUNDED]}...",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-DIVIDE]"
       .
      * This form of the DIVIDE statement places the result into
      * identifier-3 using the GIVING phrase, leaving identifier-1
      * and identifer-2 unchanged.
       PROCEDURE-ID. DIVIDE IS
        "{identifier-1 or literal-1}...",
        "INTO {identifer-2 or literal-2}",
        "GIVING {identifier-3 [ROUNDED]}...",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-DIVIDE]"
       .
      * This form of the DIVIDE statement places the result into
      * identifier-3 using the GIVING phrase, leaving identifier-1
      * and identifer-2 unchanged.
       PROCEDURE-ID. DIVIDE IS
        "{identifier-1 or literal-1}...",
        "BY {identifer-2 or literal-2}",
        "GIVING {identifier-3 [ROUNDED]}...",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-DIVIDE]"
       .
      * This form of the DIVIDE statement places the result into
      * identifer-3 and the remainder into identifier-4.
       PROCEDURE-ID. DIVIDE IS
        "{identifier-1 or literal-1}",
        "INTO {identifer-2 or literal-2}",
        "GIVING identifier-3 [ROUNDED]",
        "REMAINDER identifier-4",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-DIVIDE]"
       .
      * This form of the DIVIDE statement places the result into
      * identifer-3 and the remainder into identifier-4.
       PROCEDURE-ID. DIVIDE IS
        "{identifier-1 or literal-1}",
        "BY {identifer-2 or literal-2}",
        "GIVING identifier-3 [ROUNDED]",
        "REMAINDER identifier-4",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-DIVIDE]"
       .

      * The ENABLE statement starts transfers of information between
      * input queues and destinations.
       PROCEDURE-ID. ENABLE IS
        "{INPUT [TERMINAL] or I-O TERMINAL or OUTPUT} cd-name-1",
        "[WITH KEY {identifier-1 or literal-1}]"
       .

      * The ENTER statement embeds a routine or procedure written in
      * another programming language into your COBOL program.
       PROCEDURE-ID. ENTER IS
        "language-name-1 [routine-name-1]"
       .

      * The EXEC statement is used to embed SQL or CICS or other
      * code inside a COBOL application.
       PROCEDURE-ID. EXEC IS
        "text-name text-data",
        "END-EXEC."
       .

      * The EXHIBIT statement...
       PROCEDURE-ID. EXHIBIT IS
        "{NAMED or CHANGED NAMED or CHANGED}",
        "{identifier-1 or literal-1}..."
       .

      * The EXIT statment provides an ending point for a group of
      * procedures or a program.
       PROCEDURE-ID. EXIT IS
        "[PROGRAM or METHOD or FUNCTION]",
        "[RETURNING {identifier-1 or literal-1 or",
        " ADDRESS OF identifier-2}]",
        "[RAISING {EXCEPTION exception-name-1 or",
        " identifier-1 or LAST EXCEPTION}]"
       .
      * This form of the EXIT statement provides an early
      * break-point for a PERFORM loop.
       PROCEDURE-ID. EXIT IS
        "PERFORM [CYCLE]"
       .
      * This form of the EXIT statement provides an ending point for
      * a paragraph or section in the procedure division.
       PROCEDURE-ID. EXIT IS
        "{PARAGRAPH or SECTION}"
       .

      * The EVALUATE statement evaluates the result of an expression
      * and calls one of a set of statements depending on the result.
       PROCEDURE-ID. EVALUATE IS
        "selection-subject-1 [ALSO selection-subject-2]... {",
        "{WHEN selection-object-1 [ALSO selection-object-2]... }...",
        "imperative-statement-1 }...",
        "[WHEN OTHER imperative-statement-2]",
        "[END-EVALUATE]"
       .

      * The FREE statement releases memory dynamically allocated
      * using the ALLOCATE statement.
       PROCEDURE-ID. FREE IS
        "{pointer-name-1}..."
       .
       
      * The GENERATE statement produces a report defined using the
      * report writer definitions.
       PROCEDURE-ID. GENERATE IS
        "{data-name-1 or report-name-1}"
       .

      * The GO TO statement transfers control to a designated procedure.
       PROCEDURE-ID. GO IS
        "TO [procedure-name-1]"
       .
      * This form of the GO TO statement transfers control to one
      * of a list of procedures, depending on the value of identifer-1.
       PROCEDURE-ID. GO IS
        "TO {procedure-name-1}... DEPENDING ON identifier-1"
       .

      * The GOBACK statement returns control to the point where the
      * last GO TO occurred.
       PROCEDURE-ID. GOBACK
        "[RETURNING {identifier-1 or literal-1 or",
        " ADDRESS OF identifier-2}]"
       .

      * The IF statement controls the flow of execution based on a
      * condition.  The IF statement can execute one set of statement
      * if the condition is logically true, and another set of
      * statements if the condition is logically false.
       PROCEDURE-ID. IF IS
        "condition-1 THEN {{statement-1}... or NEXT SENTENCE}",
        "{ELSE {statement-2}... [END-IF] or",
        " ELSE NEXT SENTENCE or END-IF}"
       .

      * The INITIALIZE statement stores initial values in a data item.
       PROCEDURE-ID INITIALIZE IS
        "{identifier-1}... [WITH FILLER]",
        " [{ALL or class-names} TO VALUE]",
        "[THEN REPLACING {{ALPHABETIC or ALPHANUMERIC or",
        " ALPHANUMERIC-EDITED or BOOLEAN or NATIONAL or",
        " NATIONAL-EDITED or NUMERIC or NUMERIC-EDITED}",
        "DATA BY {identifier-2 or literal-1} }... ]",
        "[THEN TO DEFAULT]"
       .

      * The INITIATE statement begins the processing of a report.
       PROCEDURE-ID. INITIATE IS
        "{report-name-1}..."
       .

      * The INSPECT statement counts or replaces the occurrences
      * of a character or group of characters in a data item.
       PROCEDURE-ID. INSPECT IS
        "identifier-1 TALLYING {identifier-2 FOR { {CHARACTERS or ",
        "   {ALL or LEADING} {identifier-3 or literal-1}}",
        "   [{BEFORE or AFTER}",
        "    INITIAL {identifier-4 or literal-2}]... }... }..."
       .
      * This form of the INSPECT statement searches for a pattern and
      * replaces it by the value of the given identifier-5 or literal-3.
       PROCEDURE-ID. INSPECT IS
        "identifier-1 REPLACING { {CHARACTERS or",
        "   {ALL or LEADING or FIRST} {identifier-3 or literal-1}}",
        "   BY {identifier-5 or literal-3}",
        "   [{BEFORE or AFTER}",
        "    INITIAL {identifier-4 or literal-2}]... }..."
       .
      * This form of the INSPECT statement searches for a pattern
      * and replaces it with another pattern, and counts the number
      * of replacements made.
       PROCEDURE-ID. INSPECT IS
        "identifier-1 TALLYING {identifier-2 FOR { {CHARACTERS or ",
        "   {ALL or LEADING} {identifier-3 or literal-1}}",
        "   [{BEFORE or AFTER}",
        "    INITIAL {identifier-4 or literal-2}]... }... }...",
        "REPLACING { {CHARACTERS or",
        "   {ALL or LEADING or FIRST} {identifier-3 or literal-1}}",
        "   BY {identifier-5 or literal-3}",
        "   [{BEFORE or AFTER}",
        "    INITIAL {identifier-4 or literal-2}]... }..."
       .
      * This form of the INSPECT statement searches for a pattern and
      * replaces it by the value of the given identier-7 or literal-5
      * ALL is implied. 
       PROCEDURE-ID. INSPECT IS
        "identifier-1 CONVERTING {identifier-6 or literal-4}",
        "   TO {identifier-7 or literal-5} [{BEFORE or AFTER}",
        "   INITIAL {identifier-4 or literal-2}]..."
       .

      * The INVOKE statement transfers control to a method or a
      * class or interface.
       PROCEDURE-ID. INVOKE IS
        "identifier-1 {identifier-2 or literal-1} [USING",
        "[BY REFERENCE] {identifier-2 or OMITTED}",
        "[BY CONTENT] {identifier-2 or literal-2}",
        "[BY VALUE] arithmentic-expression-1 ]",
        "[RETURNING identifier-3]"
       .

      * The MERGE statement combines the contents of two or more files
      * using a specific set of keys.
       PROCEDURE-ID. MERGE IS
        "file-name-1 ",
        "{ON {ASCENDING or DESCENDING} KEY {data-name-1}...}...",
        "[COLLATING SEQUENCE [FOR ALPHANUMERIC] IS alphabet-name-1",
        "   [FOR NATIONAL IS] alphabet-name-2]",
        "USING file-name-2 {file-name-3}...",
        "{OUTPUT PROCEDURE IS procedure-name-1",
        " [{THROUGH or THRU} procedure-name-2]",
        "or GIVING {file-name-4}...}"
       .

      * The MOVE statement moves the contents of a data item or literal
      * into another data item.
       PROCEDURE-ID. MOVE IS
        "{identifier-1 or literal-3} TO {identifier-2}..."
       .
      * This form of the MOVE statement moves corresponding (like-named)
      * fields from one group to another.
       PROCEDURE-ID. MOVE IS
        "{CORRESPONDING or CORR} identifier-1 TO identifier-2"
       .

      * The MULTIPLY statment multiplies two data items together and
      * stores the result in one or more data items.
       PROCEDURE-ID. MULTIPLY IS
        "{identifier-1 or literal-1}...",
        " BY {identifer-2 [ROUNDED]}...",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-MULTIPLY]"
       .
      * This form of the MULTIPLE statement places the result of the
      * multiplication in identifier-3, leaving the input identifiers
      * unchanged.
       PROCEDURE-ID. MULTIPLY IS
        "{identifier-1 or literal-1}...",
        " BY {identifer-2 or literal-2}",
        "GIVING {identifier-3 [ROUNDED]}...",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-MULTIPLY]"
       .

      * The OPEN statement makes a file available for processing.
      * The first operation on any file must be an OPEN command.
       PROCEDURE-ID. OPEN IS
        "{ {INPUT or OUTPUT or I-O or EXTEND}",
        "[SHARING WITH {ALL OTHER or NO OTHER or READ ONLY}]",
        "[TIMEOUT {AFTER arithmetic-expression-1 SECONDS",
        "   or RETRY {arithmetic-expression-2 TIMES or NO LIMIT}}]",
        "{file-name-1 [{REVERSED or WITH NO REWIND}] }... }..."
       .

      * The PERFORM statement executes one or more paragraphs or
      * statements within the command.
       PROCEDURE-ID. PERFORM IS
        "[procedure-name-1 [{THROUGH or THRU} procedure-name-2]]",
        "[{identifier-name-1 or integer-1} TIMES]",
        "[imperative-statement-1 END-PERFORM]"
       .
      * This form of the PERFORM statement executes a set of procedures
      * until a condition is matched.
       PROCEDURE-ID. PERFORM IS
        "[procedure-name-1 [{THROUGH or THRU} procedure-name-2]]",
        "[WITH TEST {BEFORE or AFTER}] UNTIL condition-1",
        "[imperative-statement-1 END-PERFORM]"
       .
      * This form of the PERFORM statement executes a set of procedures
      * varying identifier-4 (the loop variable) and testing for
      * exit as specified, before or after, entering the loop.
       PROCEDURE-ID. PERFORM IS
        "[procedure-name-1 [{THROUGH or THRU} procedure-name-2]]",
        "[WITH TEST {BEFORE or AFTER}]",
        " VARYING {identifier-4 or literal-1}",
        "   FROM {identifier-3 or index-result-2 or literal-1}",
        "   BY {identifier-4 or literal-2} UNTIL condition-1",
        "[AFTER {identifier-5 or index-result-3}",
        "   FROM {identifier-6 or index-result-4 or literal-3}",
        "   BY {identifier-7 or literal-4} UNTIL condition-2]...",
        "[imperative-statement-1 END-PERFORM]"
       .

      * The PURGE statement removes a partial message from a
      * communications queue.
       PROCEDURE-ID. PURGE IS
        "cd-name-1"
       .

      * The READ statement reads a record from a file and stores
      * the result in a data item.  When reading sequentional files
      * the next record in the file is read.
       PROCEDURE-ID. READ IS
        "file-name-1 [NEXT or PREVIOUS] RECORD [INTO identifier-1]",
        "[ADVANCING ON LOCK or IGNORING LOCK or TIMEOUT",
        "   {AFTER arithmetic-expression-1 SECONDS or",
        "    RETRY {arithmetic-expression-2 or NO LIMIT} TIMES}]",
        "[WITH NO LOCK]",
        "[AT END imperative-statement-1]",
        "[NOT AT END imperative-statement-2]",
        "[END-READ]"
       .
      * The READ statement reads a record from a file and stores
      * the result in a data item.  When reading an indexed
      * or relative file, you specify a record to be read.
       PROCEDURE-ID. READ IS
        "file-name-1 RECORD [INTO identifier-1] [KEY IS data-name-1]",
        "[IGNORING LOCK or TIMEOUT",
        "   {AFTER arithmetic-expression-1 SECONDS or",
        "    RETRY {arithmetic-expression-2 or NO LIMIT} TIMES}]",
        "[WITH NO LOCK]",
        "[INVALID KEY imperative-statement-1]",
        "[NOT INVALID KEY imperative-statement-2]",
        "[END-READ]"
       .

      * The RECEIVE statement makes a message available to a program.
       PROCEDURE-ID. RECEIVE IS
        "cd-name-1 {MESSAGE or SEGMENT} INTO identifier-1",
        "[NO DATA imperative-statement-1]",
        "[WITH DATA imperative-statement-2]",
        "[END-RECEIVE]"
       .

      * The RELEASE statement delivers a record to the first step
      * of a sorting operation.
       PROCEDURE-ID. RELEASE IS
        "record-name-1 [FROM identifier-1]"
       .

      * The RETURN statement receives the sorted or merged record
      * from the last step of a sort or merge operation.
       PROCEDURE-ID. RETURN IS
        "file-name-1 RECORD [INTO identifier-1]",
        "AT END imperative-statement-1",
        "[NOT AT END imperative-statement-2]",
        "[END-RETURN]"
       .

      * The REWRITE statement replaces the contents of the current
      * record in a file.
       PROCEDURE-ID. REWRITE IS
        "{record-name-1 or FILE file-name-1}",
        "[FROM {identifier-1 or literal-1}]",
        "[TIMEOUT {AFTER arithmetic-expression-1 SECONDS or",
        " RETRY {arithmetic-expression-2 or NO LIMIT} TIMES}]",
        "[WITH NO LOCK]",
        "[INVALID KEY imperative-statement-1]",
        "[NOT INVALID KEY imperative-statement-2]",
        "[END-REWRITE]"
       .

      * The SEARCH statement scans a table for an element that
      * meets conditions that you specify.
       PROCEDURE-ID. SEARCH IS
        "identifier-1 [VARYING {identifier-2 or index-result-1}]",
        "[AT END imperative-statement-1]",
        "[WHEN condition-1",
        " {imperative-statement-2 or NEXT SENTENCE}}...]",
        "[END-SEARCH]"
       .
      * This form of the SEARCH statement scans a table for an element
      * that meets conditions specified, using a binary search, which
      * can be much faster, howver, the data must be sorted.
       PROCEDURE-ID. SEARCH IS
        "ALL identifier-1 [AT END imperative-statement-1]",
        "WHEN {data-name-1 {IS EQUAL TO or IS =}",
        "{identifier-3 or literal-1 or arithmetic-expression-1}",
        " or condition-1}",
        "[AND {data-name-1 {IS EQUAL TO or IS =}",
        "{identifier-3 or literal-1 or arithmetic-expression-1}",
        " or condition-1}]...",
        "{imperative-statement-2 or NEXT SENTENCE}}...",
        "[END-SEARCH]"
       .

      * The SEND statement sends a message to one or more output
      * communication devices.
       PROCEDURE-ID. SEND IS
        "cd-name-1 FROM identifier-1",
       .
      * This form of the SEND statement sends a message to one or more
      * output communication devices, and in addition, allows you to
      * specify indicators and line feeds to be sent.
       PROCEDURE-ID. SEND IS
        "cd-name-1 [FROM identifier-1]",
        "WITH {identifier-2 or ESI or EMI or EGI}",
        "[{BEFORE or AFTER} ADVANCING",
        "{{identifier-3 or integer-1}",
        " {LINE or LINES} or mnemonic-name-1 or PAGE}]",
        "[REPLACING LINE]"
       .

      * The SET statement stores or changes the value of a table index,
      * mnemonic name, or condition name.
       PROCEDURE-ID. SET IS
        "{index-result-1 or identifier-1}...",
        "TO {index-result-2 or identifier-2 or integer-1}"
       .
      * This form of the SET statement increments or decrements a
      * variable by a given value.
       PROCEDURE-ID. SET IS
        "{index-result-3}... {UP or DOWN}",
        " BY {identifier-3 or integer-2}"
       .
      * This form of the SET statement sets a condition variable
      * to ON or OFF.
       PROCEDURE-ID. SET IS
        "{ {mnemonic-name-1}... TO {ON or OFF} }..."
       .
      * This form of the SET statement sets a boolean variable to
      * TRUE or FALSE.
       PROCEDURE-ID. SET IS
        "{ {condition-name-1}... TO TRUE }..."
       .
      * This form of the SET statement places the value of
      * arithmentic-expression-1 to identifier-4.
       PROCEDURE-ID. SET IS
        "OCCURS FOR identifier-4 TO arithmetic-expression-1"
       .
      * This form of the SET statement sets the collating sequence
      * for a sort or merge operation.
       PROCEDURE-ID. SET IS
        "{SORT or MERGE or SORT-MERGE or PROGRAM}",
        "[COLLATING SEQUENCE",
        " [FOR ALPHANUMERIC] TO alphabet-name-1",
        " [FOR NATIONAL TO] alphabet-name-2]"
       .
      * This form of the SET statement sets an identifer to the
      * address of another identifier or NULL.
       PROCEDURE-ID. SET IS
        "{identifier-7 or ADDRESS OF data-name-1}",
        "TO {ADDRESS OF identifier-8 or identifier-9 or NULL}"
       .
      * This form of the SET statement sets an identifier to the
      * address of another COBOL program.
       PROCEDURE-ID. SET IS
        "identifier-10 TO",
        "{identifier-12 or NULL or ADDRESS OF PROGRAM",
        " {identifier-11 or literal-1 or program-prototype-name-1} }",
       .
      * This form of the SET statement increments or decrements
      * identifier-13 by arithmetic-expression-2.
       PROCEDURE-ID. SET IS
        "identifier-13 {UP or DOWN} BY arithmetic-expression-2"
       .
      * This form of the SET statement sets the LOCALE.
       PROCEDURE-ID. SET IS
        "LOCALE {LC_ALL or LC_COLLATE or LC_CTYPE or LC_MESSAGES",
        "or LC_MONETARY or LC_NUMERIC or LC_TIME}",
        "[INTO identifier-14]",
        " [FROM {DEFAULT or identifier-15 or mnemonic-name-2}]"
       .

      * The SORT command sorts a file in a specific order based
      * on a set of specified keys.
       PROCEDURE-ID. SORT IS
        "file-name-1",
        "{ON {ASCENDING or DESCENDING} KEY {data-name-1}... }...",
        "[WITH DUPLICATES IN ORDER] [COLLATING SEQUENCE",
        "[FOR ALPHANUMERIC] IS alphabet-name-1",
        " [FOR NATIONAL IS] alphabet-name-2]",
        "{INPUT PROCEDURE IS procedure-name-1",
        " [{THROUGH or THRU} procedure-name-2]",
        "or USING {file-name-2}...}",
        "{OUTPUT PROCEDURE IS procedure-name-3",
        " [{THROUGH or THRU} procedure-name-4]",
        "or GIVING {file-name-3}...}"
       .
      * The SORT command sorts a table in a specific order based
      * on a set of specified keys.
       PROCEDURE-ID. SORT IS
        "data-name-1",
        "{ON {ASCENDING or DESCENDING} KEY {data-name-1}... }...",
        "[WITH DUPLICATES IN ORDER] [COLLATING SEQUENCE",
        "[FOR ALPHANUMERIC] IS alphabet-name-1",
        " [FOR NATIONAL IS] alphabet-name-2]",
       .

      * The START statement sets the current record position of
      * a relative or indexed file before a record is read.
       PROCEDURE-ID. START IS
        "file-name-1 {FIRST or LAST or KEY relational-operator",
        "   {data-name-1 or record-key-name-1}",
        " [WITH LENGTH arithmetic-expression-1] }",
        "[INVALID KEY imperative-statement-1]",
        "[NOT INVALID KEY imperative-statement-2]",
        "[END-START]"
       .

      * The STOP statement terminates the execution of a program.
       PROCEDURE-ID. STOP IS
        "{RUN or literal-1} [WITH {ERROR or NORMAL}",
        " STATUS [identifier-1 or literal-1]]"
       .

      * The STRING statement concatenates two or more data items
      * storing the result in another data item.
       PROCEDURE-ID. STRING IS
        "{{identifier-1 or literal-1}...",
        "[DELIMITED BY {identifier-2 or literal-2 or SIZE}]}...",
        "INTO identifier-3 [WITH POINTER identifier-4]",
        "[ON OVERFLOW imperative-statement-1]",
        "[NOT ON OVERFLOW imperative-statement-2]",
        "[END-STRING]"
       .

      * The SUBTRACT statement subtracts the value of one of the sum
      * of multiple data items from one or more data items.
       PROCEDURE-ID. SUBTRACT IS
        "{identifier-1 or literal-1}...",
        "FROM {identifer-2 [ROUNDED]}...",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-SUBTRACT]"
       .
      * This form of the SUBTRACT statement places the result in
      * identifier-3 leaving the other input parameters unchanged.
       PROCEDURE-ID. SUBTRACT IS
        "{identifier-1 or literal-1}...",
        "FROM {identifer-2 or literal-2}",
        "GIVING {identifier-3 [ROUNDED]}...",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-SUBTRACT]"
       .
      * This form of the SUBTRACT statement subtracts values from
      * corresponding (like-named) fields in two groups.
       PROCEDURE-ID. SUBTRACT IS
        "{CORRESPONDING or CORR} identifier-1",
        "FROM identifer-2 [ROUNDED]",
        "[ON SIZE ERROR imperative-statement-1]",
        "[NOT ON SIZE ERROR imperative-statement-2]",
        "[END-SUBTRACT]"
       .

      * The SUPPRESS statement stops the display of a report.
       PROCEDURE-ID. SUPPRESS IS
        "PRINTING"
       .

      * The TERMINATE statement ends the processing of a
      * specified report.
       PROCEDURE-ID. TERMINATE IS
        "{report-name-1}..."
       .

      * The UNLOCK statement unlocks a record file.
       PROCEDURE-ID. UNLOCK IS
        "file-name-1 [RECORD or RECORDS]"
       .    
       
      * The UNSTRING statement seperates one long data item into
      * separate parts.
       PROCEDURE-ID. UNSTRING IS
        "identifier-1",
        "[DELIMITED BY [ALL] {identifier-2 or literal-2}",
        " [OR [ALL] {identifier-3 or literal-2}] ]...",
        "INTO identifier-4 [DELIMITER IN identifier-5]",
        "[COUNT IN identifier-6] }...",
        "[WITH POINTER identifier-7] [TALLYING IN identifier-8]",
        "[ON OVERFLOW imperative-statement-1]",
        "[NOT ON OVERFLOW imperative-statement-2]",
        "[END-UNSTRING]"
       .

      * The USE statement creates special handling routines that apply
      * to debugging, file exception handling, and reporting.
       PROCEDURE-ID. USE IS
        "[GLOBAL] AFTER STANDARD {EXCEPTION or ERROR} PROCEDURE ON",
        "{{file-name-1}... or INPUT or OUTPUT or I-O or EXTEND}"
       .
      * This form of the USE statement specifies what routine to
      * use before reporting.
       PROCEDURE-ID. USE IS
        "[GLOBAL] BEFORE REPORTING identifier-1"
       .
      * This form of the USE statement is used for debugging.
       PROCEDURE-ID. USE IS
        "FOR DEBUGGING ON {cd-name-1 or",
        "[ALL REFERENCES OF] identifier-1 or file-name-1 or",
        "procedure-name-1 or ALL PROCEDURES}"
       .
      * This form of the USE statement specifies what to do when
      * an exception occurs.
       PROCEDURE-ID. USE IS
        "AFTER EXCEPTION",
        " {exception-name-1 or class-name-1 or interface-name-1}"
       .

      * The VALIDATE statement invokes data validation, input
      * distribution, and error indication for a data item.
       PROCEDURE-ID. VALIDATE IS
        "{identifier-1} ..."
       .

      * The WRITE statement writes a record to a specific position in a
      * file or to position lines of text vertically on a page.
       PROCEDURE-ID. WRITE IS
        "{record-name-1 or FILE file-name-1}",
        "[FROM {identifier-1 or literal-1}]",
        "[{BEFORE or AFTER} ADVANCING",
        "{{identifier-3 or integer-1}",
        " {LINE or LINES} or mnemonic-name-1 or PAGE}]",
        "[TIMEOUT {AFTER arithmetic-expression-1 SECONDS or",
        " RETRY {arithmetic-expression-2 or NO LIMIT} TIMES}]",
        "[AT {END-OF-PAGE or EOP} imperative-statement-1]",
        "[NOT AT {END-OF-PAGE or EOP} imperative-statement-2]",
        "[END-WRITE]"
       .
      * This form of the WRITE statement is used to write records
      * to an indexed file, specifying the key to select which
      * record to rewrite.
       PROCEDURE-ID. WRITE IS
        "{record-name-1 or FILE file-name-1}",
        "[FROM {identifier-1 or literal-1}]",
        "[TIMEOUT {AFTER arithmetic-expression-1 SECONDS or",
        " RETRY {arithmetic-expression-2 or NO LIMIT} TIMES}]",
        "[WITH LOCK]",
        "[INVALID KEY imperative-statement-1]",
        "[NOT INVALID KEY imperative-statement-2]",
        "[END-WRITE]"
       .


      /*****************************************************************
      ** COBOL COMPILER PREPROCESSING FACILITY                        **
      ******************************************************************
       FUNCTION-ID.      *> stop comment lookup

      * Include the contents of the given file, making replacement
      * as specified.
       PROCEDURE-ID. COPY IS
        "{text-name or external-file-name-literal}",
        "[{OF or IN} {library-name or library-name-literal}]",
        "[SUPPRESS]",
        "[REPLACING {{==pseudo-text-1== or identifier-1 or",
        "             literal-1 or word-1}",
        " BY {==pseudo-text-2== or identifier-2",
        "     or literal-2 or word-2}}...]"
       .

      * Replace subsequent compiler input text as specified.
       PROCEDURE-ID. REPLACE IS
        "{==pseudo-text-1== BY ==pseudo-text-2}..."
       .
      * Cancel effect of previous replace statement.
       PROCEDURE-ID. REPLACE IS
        "OFF"
       .

      /*****************************************************************
      ** STANDARD COBOL CLASSES                                       **
      ******************************************************************

      * The interface BaseFactoryI specifies the factory interaface for
      * the built-in BASE class.
      * INTERFACE-ID. BaseFactoryI.
      * PROCEDURE DIVISION.
      * The New method is a factory method that provides a standard
      * mechanism for creating object instances of a class.
      * METHOD-ID. New.
      * DATA DIVISION.
      * LINKAGE SECTION.
      *       01 outObject usage object reference active-class.
      * PROCEDURE DIVISION RETURNING outObject.
      * END METHOD New.
      * END INTERFACE BaseFactoryI.

      * The interface BaseI specifies the object interface of the BASE
      * class.
      * INTERFACE-ID. BaseI.
      * PROCEDURE DIVISION.
      * The FactoryObject method is an object method that provides a
      * standard mechanism for acquiring access to the factory object
      * associated with the given object.
      * METHOD-ID. FactoryObject.
      * DATA DIVISION.
      * LINKAGE SECTION.
      *    01 outFactory usage object reference factory of active-class.
      * PROCEDURE DIVISION RETURNING outFactory.
      * END METHOD FactoryObject.
      * END INTERFACE BaseI.

      * The standard class BASE is the root of the class hierarchy and
      * provides standard object life-cycle functionality.
      * CLASS-ID. BASE INHERITS BaseFactoryI BaseI.
      * END CLASS BASE.
       
      * The NULL class is a predefined class.  There are no instances of
      * the NULL class.  The NULL object is the NULL factory object.
      * A reference to the NULL object is placed in every data item
      * declared with USAGE OBJECT REFERENCE when the storage for that
      * data item is allocated.
      * CLASS-ID. NULL.
      * END CLASS NULL.
