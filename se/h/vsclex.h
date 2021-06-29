#pragma once

#define VSCLEXFLAG_OTHER        0x1
/* #define    VSCLEXFLAG_ERROR     =  0x2 */
#define VSCLEXFLAG_KEYWORD      0x4
#define VSCLEXFLAG_NUMBER       0x8
#define VSCLEXFLAG_STRING       0x10
#define VSCLEXFLAG_COMMENT      0x20
#define VSCLEXFLAG_PPKEYWORD    0x40
#define VSCLEXFLAG_LINENUM      0x80
#define VSCLEXFLAG_SYMBOL1      0x100
#define VSCLEXFLAG_PUNCTUATION  0x100
#define VSCLEXFLAG_SYMBOL2      0x200
#define VSCLEXFLAG_LIB_SYMBOL   0x200
#define VSCLEXFLAG_SYMBOL3      0x400
#define VSCLEXFLAG_OPERATOR     0x400
#define VSCLEXFLAG_SYMBOL4      0x800
#define VSCLEXFLAG_USER_DEFINED 0x800
#define VSCLEXFLAG_FUNCTION     0x1000
#define VSCLEXFLAG_NOSAVE       0x2000
#define VSCLEXFLAG_ATTRIBUTE    0x4000
#define VSCLEXFLAG_TAG          0x8000
#define VSCLEXFLAG_UNKNOWN_TAG  0x10000
#define VSCLEXFLAG_XHTMLELEMENTINXSL 0x20000
// WARNING: Don't add more flags unless
// you fix search flags.
#define VSCLEXFLAG_ALLFLAGS     0x3ffff



   #define VSLF_OTHERBITMAPS (VSLF_CURLINEBITMAP)

   #define VSLF_VISIBLE       0x0   //Line should be visible
   // Don't want to undo line flags in VSLF_UNDOMASK. Maybe should call this VSLF_NOUNDOMASK
   #define VSLF_UNDOMASK     (VSLF_LEXER_STATE_INFO|VSLF_OTHERBITMAPS|VSLF_CPPFLAGSMASK|VSLF_LANGFLAGMASK|VSLF_SPELL_CHECK|VSLF_VIMARK)
   // Indicate line flags which may be copied
   #define VSLF_COPYMASK     (VSLF_EOL_MISSING|VSLF_ALLINSERTED_LINE|VSLF_HIDDEN|VSLF_MINUSBITMAP|VSLF_PLUSBITMAP|VSLF_LEVEL)
   #define VSLF_NOTALLOWEDMASK   (VSLF_LEXER_STATE_INFO|VSLF_CPPFLAGSMASK|VSLF_LANGFLAGMASK)
   #define VSLF_COUNTMASK    (VSLF_NOSAVE|VSLF_HIDDEN|VSLF_PLUSBITMAP|VSLF_MINUSBITMAP|VSLF_OTHERBITMAPS|VSLF_EOL_MISSING)
   // USERMASK_LF are the flags that the user can modify
   #define VSLF_USERMASK    (VSLF_LEVEL|VSLF_VIMARK|VSLF_ALLINSERTED_LINE|VSLF_ALLMODIFY|VSLF_HIDDEN|VSLF_NOSAVE|VSLF_PLUSBITMAP|VSLF_MINUSBITMAP|VSLF_OTHERBITMAPS)

   #define VSLFC_VSSELDISPSHIFT      11


   //VSLF_CURLINEBITMAP is used to implement cursor position
   //for search output.  We could used debug mode for this
   //but then we have to ship breakpt.dll
   #define VSLF_CURLINEBITMAP  0x00008000
   #define VSLF_MODIFY         0x00010000
   #define VSLF_INSERTED_LINE  0x00020000
   #define VSLF_HIDDEN         0x00040000
   #define VSLF_MINUSBITMAP    0x00080000
   #define VSLF_PLUSBITMAP     0x00100000
   #define VSLF_NEXTLEVEL      0x00200000
   #define VSLF_LEVEL          0X07E00000   // 6-bits
   #define VSLF_NOSAVE         0x08000000   //Display this line in no save color
   #define VSLF_VIMARK         0x10000000   //Used by VImacro to mark lines
   #define VSLF_READONLY       0x20000000
   #define VSLF_EOL_MISSING    0x40000000
   #define VSLF_SPELL_CHECK    0x80000000
   #define VSLF_ALLMODIFY   (VSLF_MODIFY|VSLF_SPELL_CHECK)
   #define VSLF_ALLINSERTED_LINE (VSLF_INSERTED_LINE|VSLF_SPELL_CHECK)
   #define VSLF_INITIAL     (VSLF_VISIBLE|VSLF_SPELL_CHECK)

   #define vsLevelIndex(bl_flags)  (((bl_flags) & VSLF_LEVEL)>>21)
   #define vsIndex2Level(level)   ((level)<<21)

                                 
   #define VSLF_NEST_LEVEL_SHIFT  4
   #define VSLF_LINEFLAGSMASK  0x7FFFFFFF
   #define VSLF_CPPFLAGSMASK   0x00003fff00000000LL
   #define VSLF_LANGFLAGMASK   0x003fc00000000000LL //lang specific

   #define VSLF_ALL_LEXER_STATE_INFO  (VSLF_LEXER_STATE_INFO|VSLF_CPPFLAGSMASK|VSLF_LANGFLAGMASK)
   /*
       Syntax Color Coding encoding
    
            [embedded-indexp1 5 bits] [mlindex 6 bits][nest-level 3 bits]
    
       next-level 1..7         must be non-zero in order for mlindex to be valid
       mlindex    0..63        Used for multi-line state which is not inside an embedded
                               language. (comment, string, multi-line line comment, etc.)
       embedded-indexp1 1..31
                               embedded language index. Embedded language and for
                               embedded string color

   */
   // Note that LF stands for Line flag.  The H is just to assist with
   // completion purposes.

   // Mask multi-line comments, strings, and embedded languages
   #define VSLF_LEXER_STATE_INFO 0x7fff

   // Encode embedded language lexer state
   #define vsLFHEmbeddedLanguageInfo(EmbeddedLanguageIndex)  (((EmbeddedLanguageIndex)+1)<<10)
   // Returns index of embedded language.  -1 indicates no embedded language.
   #define vsLFHEmbeddedLanguageIndex(comment_info)  ((((cmint)(comment_info) &VSLF_EMBEDDED_LANGUAGE_MASK)>>10)-1)

   // Mask multi-line comments, strings
   #define VSLF_COMMENT_INFO_MASK 0x3ff
                                         
   #define VSLF_EMBEDDED_LANGUAGE_MASK 0x7C00
   // This can only occur when CICS is embedded in OS/390 assembler
   //#define VSLF_CICS_IS_LINECONT_PARAM      0x18

   // Encode multi-line comment.
   #define vsLFHCommentInfo(nest_level,comment_index) ((nest_level)|((comment_index)<<VSLF_NEST_LEVEL_SHIFT))
   // Returns index of multi-line comment we are currently in.  Don't
   // use this macro unless vsLFHInComment returns non-zero value.
   #define vsLFHCommentIndex(LexerStateInfo) ((cmint)(((LexerStateInfo) &VSLF_COMMENT_INFO_MASK)>>VSLF_NEST_LEVEL_SHIFT))
   // Returns nesting level of multi-line comment we are currently in.
   // Don't use this macro unless vsLFHInComment returns non-zero value.
   #define vsLFHNestLevel(LexerStateInfo) ((cmint)((LexerStateInfo) &((1<<VSLF_NEST_LEVEL_SHIFT)-1)))


   #define vsCppFlagsStackI(depth,active,bits)  ((bl_flags_t)((((bl_flags_t)depth) << 43) | (((bl_flags_t)active) << 40) | (((bl_flags_t)bits) << 32)))
   #define vsCppFlagsDepth(flags)   ((flags >> 43) & 0x7)
   #define vsCppFlagsActive(flags)  ((flags >> 40) & 0x7)
   #define vsCppFlagsOnFlags(flags)   ((flags >> 32) & 0xff)

   #define vsLangLFFlags(flags)      ((flags >> 46) & 0xff)
   #define vsLangLFFlagsSet(flags)   ((bl_flags_t)(((bl_flags_t)flags) & 0xff) << 46)

