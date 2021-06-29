////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
#pragma option(metadata,"autocomplete.e")

#include "slick.sh"
#include "tagsdb.sh"


// prototypes for functions used to perform completions
void _autocomplete_process(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol);
void _autocomplete_space(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol);
void _autocomplete_expand_alias(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol);
void _autocomplete_prev(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol);
void _autocomplete_next(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol);


///////////////////////////////////////////////////////////////////////////////
_metadata enum_flags AutoCompleteFlags {
   AUTO_COMPLETE_ENABLE                = 0x00000001,   // enable auto complete
   AUTO_COMPLETE_NO_STRICT_CASE        = 0x00000002,   // should auto-complete matching be case-sensitive?
   AUTO_COMPLETE_SUBWORD_MATCHES       = 0x00000004,   // should auto-complete matching use subword pattern matching?
   AUTO_COMPLETE_SUBWORD_NO_GLOBALS    = 0x00000008,   // should auto-complete subword matching include globals?
   AUTO_COMPLETE_SHOW_BULB             = 0x00000010,   // show a light-bulb with the completion
   AUTO_COMPLETE_SHOW_LIST             = 0x00000020,   // show list of matches?
   AUTO_COMPLETE_SHOW_WORD             = 0x00000040,   // show what would be completed
   AUTO_COMPLETE_SHOW_DECL             = 0x00000080,   // show symbol declaration?
   AUTO_COMPLETE_SHOW_COMMENTS         = 0x00000100,   // show symbol comments?
   AUTO_COMPLETE_SHOW_ICONS            = 0x00000200,   // show symbol icons?
   AUTO_COMPLETE_SHOW_CATEGORIES       = 0x00000400,   // show categories or just show flat list?
   AUTO_COMPLETE_SYNTAX                = 0x00001000,   // show when syntax can be expanded
   AUTO_COMPLETE_ALIAS                 = 0x00002000,   // show when an alias can be completed
   AUTO_COMPLETE_SYMBOLS               = 0x00004000,   // show when a symbol can be completed
   AUTO_COMPLETE_KEYWORDS              = 0x00008000,   // show when keywords can be completed
   AUTO_COMPLETE_WORDS                 = 0x00010000,   // show when complete-list prefix matches
   AUTO_COMPLETE_EXTENSION_ARGS        = 0x00020000,   // extension specific argument completion
   AUTO_COMPLETE_LANGUAGE_ARGS         = 0x00020000,   // extension specific argument completion
   AUTO_COMPLETE_UNIQUE                = 0x00100000,   // automatically select unique item?
   AUTO_COMPLETE_TAB_NEXT              = 0x00200000,   // Tab key selects next item. Cycles through choices.
   AUTO_COMPLETE_ENTER_ALWAYS_INSERTS  = 0x00400000,   // Enter key always inserts current item, even if not selected
   AUTO_COMPLETE_TAB_INSERTS_PREFIX    = 0x00800000,   // use tab key to insert unique prefix match?
   AUTO_COMPLETE_ARGUMENTS             = 0x01000000,   // show for argument completion (text boxes)
   AUTO_COMPLETE_NO_INSERT_SELECTED    = 0x02000000,   // Insert the select item
   AUTO_COMPLETE_LOCALS                = 0x04000000,   // show when a local symbol can be completed
   AUTO_COMPLETE_MEMBERS               = 0x08000000,   // show when a class member can be completed
   AUTO_COMPLETE_CURRENT_FILE          = 0x10000000,   // show when a symbol in the current file can be completed
   AUTO_COMPLETE_SHOW_PROTOTYPES       = 0x20000000,   // show function argument prototypes in list

   AUTO_COMPLETE_DEFAULT               = ( AUTO_COMPLETE_ENABLE                |
                                         //AUTO_COMPLETE_CASE_SENSITIVE        |
                                           AUTO_COMPLETE_SUBWORD_MATCHES       |
                                           AUTO_COMPLETE_SUBWORD_NO_GLOBALS    |
                                           AUTO_COMPLETE_SHOW_BULB             |
                                           AUTO_COMPLETE_SHOW_LIST             |
                                           AUTO_COMPLETE_SHOW_WORD             |
                                           AUTO_COMPLETE_SHOW_DECL             |
                                           AUTO_COMPLETE_SHOW_COMMENTS         |
                                           AUTO_COMPLETE_SHOW_ICONS            |
                                           AUTO_COMPLETE_SHOW_CATEGORIES       |
                                           AUTO_COMPLETE_SYNTAX                |
                                           AUTO_COMPLETE_ALIAS                 |
                                           AUTO_COMPLETE_SYMBOLS               |
                                           AUTO_COMPLETE_KEYWORDS              |
                                           AUTO_COMPLETE_WORDS                 |
                                           AUTO_COMPLETE_EXTENSION_ARGS        |
                                           AUTO_COMPLETE_LANGUAGE_ARGS         |
                                         //AUTO_COMPLETE_UNIQUE                |
                                         //AUTO_COMPLETE_TAB_NEXT              |
                                           AUTO_COMPLETE_ENTER_ALWAYS_INSERTS  |
                                           AUTO_COMPLETE_TAB_INSERTS_PREFIX    |
                                           AUTO_COMPLETE_ARGUMENTS             |
                                           AUTO_COMPLETE_NO_INSERT_SELECTED    |
                                           AUTO_COMPLETE_LOCALS                |
                                           AUTO_COMPLETE_MEMBERS               |
                                           AUTO_COMPLETE_CURRENT_FILE          |
                                           AUTO_COMPLETE_SHOW_PROTOTYPES       )
};

enum AutoCompleteSubwordPattern {
   // subword matching specifies to only do prefix matching 
   // (aka, subword matching is turned OFF)
   AUTO_COMPLETE_SUBWORD_MATCH_NONE = 0,   
   // subword matching using stone-skipping with subword boundaries
   AUTO_COMPLETE_SUBWORD_MATCH_STSK_SUBWORD,
   // subword matching using subword acronyms
   AUTO_COMPLETE_SUBWORD_MATCH_STSK_ACRONYM,
   // subword matching using pure stone-skipping
   AUTO_COMPLETE_SUBWORD_MATCH_STSK_PURE,
   // subword matching using simple substring match
   AUTO_COMPLETE_SUBWORD_MATCH_SUBSTRING,
   // subword matching using simple subword prefix match
   AUTO_COMPLETE_SUBWORD_MATCH_SUBWORD,
   // character matching in any order
   AUTO_COMPLETE_SUBWORD_MATCH_CHAR_BITSET,
};


_metadata enum AutoCompletePoundIncludeOptions {
   // do not trigger auto-complete on #include
   AC_POUND_INCLUDE_NONE,
   // list quoted files after typing space
   AC_POUND_INCLUDE_QUOTED_ON_SPACE,
   // list files after typing " or <
   AC_POUND_INCLUDE_ON_QUOTELT,
};

enum AutoCompletePriorities {
   AUTO_COMPLETE_SYNTAX_PRIORITY=100,
   AUTO_COMPLETE_KEYWORD_PRIORITY=200,
   AUTO_COMPLETE_ALIAS_PRIORITY=300,
   AUTO_COMPLETE_FIRST_SYMBOL_PRIORITY=400,
   AUTO_COMPLETE_COMPATIBLE_PRIORITY=410,
   AUTO_COMPLETE_LOCALS_PRIORITY=420,
   AUTO_COMPLETE_MEMBERS_PRIORITY=430,
   AUTO_COMPLETE_CURRENT_FILE_PRIORITY=440,
   AUTO_COMPLETE_SYMBOL_PRIORITY=450,
   AUTO_COMPLETE_SUBWORD_PRIORITY=460,
   AUTO_COMPLETE_LAST_SYMBOL_PRIORITY=499,
   AUTO_COMPLETE_WORD_COMPLETION_PRIORITY=500,
   AUTO_COMPLETE_FILES_PRIORITY=600,
   AUTO_COMPLETE_ARGUMENT_PRIORITY=1000
};

/**
 * This struct represents an auto completion word.
 */
struct AUTO_COMPLETE_INFO {
   // priority of category
   int priorityLevel;
   // Word displayed in list
   _str displayWord;
   // Are function arguments shown for this word?
   bool displayArguments;
   // Text to insert. if this is null, the display word is inserted.
   _str insertWord;
   // comments describing completed word
   _str comments;
   // comment flags for this word
   VSCodeHelpCommentFlags comment_flags;
   // name of command to execute on space (for unique results)
   void (*pfnReplaceWord)(_str insertWord,_str prefix,int &removeStartCol,int &removeLen,bool onlyInsertWord,struct VS_TAG_BROWSE_INFO symbol);
   // tag information if this is a symbol
   struct VS_TAG_BROWSE_INFO symbol;
   // Indicates whether matching is case sensitive, default is true
   bool caseSensitive;
   // Index of bitmap to display in list
   int bitmapIndex;
};

/**
 * Control the default behavior of alias and other auto-completion options.
 * Bitset of AUTO_COMPLETE_*.  The default is for everything to be enabled
 * except partial symbol expansion and displaying the expansion bar.
 * <p>
 * The actual configurable options are stored per extension in
 * def_autocomplete_[ext].  This is used as a global default setting.
 *
 * @categories Configuration_Variables
 */
AutoCompleteFlags def_auto_complete_options = (AutoCompleteFlags)(-1 & ~(AUTO_COMPLETE_UNIQUE|AUTO_COMPLETE_TAB_NEXT));

