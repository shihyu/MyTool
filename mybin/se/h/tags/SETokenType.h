////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SE_TOKEN_TYPE_H
#define SE_TOKEN_TYPE_H

// File:        SETokenType
// Description: Declaration for the SETokenType enumeration

namespace slickedit {

/**
 * This enumerated type defines the core values for identifying token 
 * types.  User defined token types should extend this and re-use as 
 * many of these tokens as possible.  Note that the single character 
 * lower-ASCII operators are given token values corresponding to their 
 * actual ASCII value.
 */
enum SETokenType {

   SETOKEN_NULL                = 0,    // Null Character
   SETOKEN_ASCII_SOH           = 1,    // Start of Header
   SETOKEN_ASCII_STX           = 2,    // Start of Text
   SETOKEN_ASCII_ETX           = 3,    // End of Text
   SETOKEN_ASCII_EOT           = 4,    // End of Transmission
   SETOKEN_ASCII_ENQ           = 5,    // Enquiry
   SETOKEN_ASCII_ACK           = 6,    // Acknowledgement
   SETOKEN_BELL                = '\a', // Bell
   SETOKEN_BACKSPACE           = '\b', // Backspace
   SETOKEN_TAB                 = '\t', // Horizontal Tab
   SETOKEN_LINE_FEED           = '\n', // Line feed
   SETOKEN_VERTICAL_TAB        = '\v', // Vertical tab
   SETOKEN_FORM_FEED           = '\f', // Form feed
   SETOKEN_CARRIAGE_RETURN     = '\r', // Carriage return
   SETOKEN_ASCII_SO            = 14,   // Shift Out
   SETOKEN_ASCII_SI            = 15,   // Shift In
   SETOKEN_ASCII_DLE           = 16,   // Data Link Escape
   SETOKEN_ASCII_DC1           = 17,   // Device Control 1
   SETOKEN_ASCII_DC2           = 18,   // Device Control 2
   SETOKEN_ASCII_DC3           = 19,   // Device Control 3
   SETOKEN_ASCII_DC4           = 20,   // Device Control 4
   SETOKEN_ASCII_NAK           = 21,   // Negative Acknowledgement
   SETOKEN_ASCII_SYN           = 22,   // Synchronous Idle
   SETOKEN_ASCII_ETB           = 23,   // End of Transmission Block
   SETOKEN_ASCII_CAN           = 24,   // Cancel
   SETOKEN_ASCII_EOM           = 25,   // End of Medium
   SETOKEN_ASCII_SUB           = 26,   // Substitute
   SETOKEN_ASCII_ESC           = 27,   // Escape
   SETOKEN_ASCII_FS            = 28,   // File Separator
   SETOKEN_ASCII_GS            = 29,   // Group Separator
   SETOKEN_ASCII_RS            = 30,   // Record Separator
   SETOKEN_ASCII_US            = 31,   // Unit Separator
   SETOKEN_SPACE               = ' ',  // Space character
   SETOKEN_NOT                 = '!',  // Exclamation mark
   SETOKEN_DQUOTE              = '\"', // Double quote
   SETOKEN_POUND               = '#',  // Pound sign
   SETOKEN_DOLLAR              = '$',  // Dollar sign
   SETOKEN_PERCENT             = '%',  // Percent sign
   SETOKEN_AMPERSAND           = '&',  // Ampersand
   SETOKEN_SINGLE_QUOTE        = '\'', // Single quote
   SETOKEN_LEFT_PAREN          = '(',  // Open paren
   SETOKEN_RIGHT_PAREN         = ')',  // Close paren
   SETOKEN_ASTERISK            = '*',  // Asterisk
   SETOKEN_STAR                = '*',  // Asterisk is also knows as star
   SETOKEN_PLUS                = '+',  // Plus sign
   SETOKEN_COMMA               = ',',  // Comma
   SETOKEN_MINUS               = '-',  // Minus sign
   SETOKEN_DOT                 = '.',  // Period
   SETOKEN_DIVIDE              = '/',  // Forward slash
   SETOKEN_COLON               = ':',  // Colon
   SETOKEN_SEMICOLON           = ';',  // Semicolon
   SETOKEN_LT                  = '<',  // Less than
   SETOKEN_ASSIGN              = '=',  // Equals
   SETOKEN_GT                  = '>',  // Greater than
   SETOKEN_QUESTION            = '?',  // Question mark
   SETOKEN_ATSIGN              = '@',  // At sign
   SETOKEN_LEFT_BRACKET        = '[',  // Open bracket
   SETOKEN_BACKSLASH           = '\\', // Backslash
   SETOKEN_RIGHT_BRACKET       = ']',  // Close bracket
   SETOKEN_CAROT               = '^',  // Carot
   SETOKEN_UNDERSCORE          = '_',  // Underscore
   SETOKEN_BACKQUOTE           = '`',  // Backwards single quote
   SETOKEN_LEFT_BRACE          = '{',  // Open brace
   SETOKEN_OR                  = '|',  // Vertical bar
   SETOKEN_RIGHT_BRACE         = '}',  // Close brace
   SETOKEN_TILDE               = '~',  // Tilde
   SETOKEN_ASCII_DEL           = 127,  // Delete

   // Identifier types
   SETOKEN_IDENTIFIER          = 'A',  // User-defined identifier
   SETOKEN_BUILTIN             = 'a',  // Builtin identifier or type name
   
   // Constants
   SETOKEN_NUMBER              = '0',  // Integer Number
   SETOKEN_FLOAT,                      // Floating point number
   SETOKEN_STRING,                     // String constant
   SETOKEN_CHARACTER,                  // Character constant
   SETOKEN_REGEX,                      // Regular expression

   // Whitespace
   SETOKEN_WHITESPACE      = SETOKEN_SPACE,     // Whitespace charactors
   SETOKEN_NEWLINE         = SETOKEN_LINE_FEED, // Line separator
   SETOKEN_LINE_COMMENT    = SETOKEN_ASCII_SOH, // Line Comment
   SETOKEN_BLOCK_COMMENT   = SETOKEN_ASCII_STX, // Block Comment
   SETOKEN_EOF             = SETOKEN_ASCII_EOT, // End of File
   SETOKEN_EOS             = SETOKEN_ASCII_ETX, // End of string buffer

   // operators
   SETOKEN_GARBAGE_CHAR = 128,         // Unexpected character
   SETOKEN_EQGT,                       // =>
   SETOKEN_LTLT,                       // <<
   SETOKEN_GTGT,                       // >>
   SETOKEN_GTGTGT,                     // >>>
   SETOKEN_LTLTLT,                     // <<<
   SETOKEN_LTE,                        // <=
   SETOKEN_GTE,                        // >=
   SETOKEN_GTQUESTION,                 // >?
   SETOKEN_LTQUESTION,                 // <?
   SETOKEN_EQEQ,                       // ==
   SETOKEN_NOTEQ,                      // !=
   SETOKEN_PLUSEQ,                     // +=
   SETOKEN_MINUSEQ,                    // -=
   SETOKEN_STAREQ,                     // *=
   SETOKEN_DIVEQ,                      // /=
   SETOKEN_PERCENTEQ,                  // %=
   SETOKEN_CARETEQ,                    // ^=
   SETOKEN_ANDEQ,                      // &=
   SETOKEN_OREQ,                       // |=
   SETOKEN_LTLTEQ,                     // <<=
   SETOKEN_GTGTEQ,                     // >>=
   SETOKEN_GTGTGTEQ,                   // >>>=
   SETOKEN_ANDAND,                     // &&
   SETOKEN_OROR,                       // ||
   SETOKEN_PLUSPLUS,                   // ++
   SETOKEN_MINUSMINUS,                 // --
   SETOKEN_DASHGTSTAR,                 // ->*
   SETOKEN_DASHGT,                     // ->
   SETOKEN_DOTSTAR,                    // .*
   SETOKEN_DOTEQ,                      // .=
   SETOKEN_COLONPLUS,                  // :+
   SETOKEN_STARSTAR,                   // **
   SETOKEN_DOTDOT,                     // ..
   SETOKEN_EQTILDE,                    // =~
   SETOKEN_NOTTILDE,                   // !~
   SETOKEN_ELLIPSE,                    // ...
   SETOKEN_EQEQEQ,                     // ===
   SETOKEN_NOTEQEQ,                    // !==
   SETOKEN_COLONEQ,                    // :=
   SETOKEN_COLONLT,                    // :<
   SETOKEN_COLONGT,                    // :>
   SETOKEN_COLONLTE,                   // :<=
   SETOKEN_COLONGTE,                   // :>=
   SETOKEN_COLONEQEQ,                  // :==
   SETOKEN_COLONNOTEQ,                 // :!=
   SETOKEN_LTGT,                       // <>
   SETOKEN_LTGTEQ,                     // <>=
   SETOKEN_NOTLTGT,                    // !<>
   SETOKEN_NOTLTGTEQ,                  // !<>=
   SETOKEN_NOTLT,                      // !<
   SETOKEN_NOTLTEQ,                    // !<=
   SETOKEN_NOTGT,                      // !>
   SETOKEN_NOTGTEQ,                    // !>=
   SETOKEN_TILDEEQ,                    // ~=
   SETOKEN_TILDETILDE,                 // ~~
   SETOKEN_NOTPAREN,                   // !(
   SETOKEN_COLONCOLON,                 // ::

   // Use defined tokens start at 256
   SETOKEN_FIRST_USER = 256,

   // And are allowed no more than 2^16 token types
   SETOKEN_LAST_USER = 65535

};

}

#endif // SE_TOKEN_TYPE_H
