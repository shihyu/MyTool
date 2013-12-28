////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#ifndef SLICK24_SH
#define SLICK24_SH


/*
$VerboseHistory: slick24.sh$
*/
 const
   NUMKEYS=129+260+19+9*4+4+1,
   SLICK_MENU_FILE = 'slick.mnu',
   SLICK_HELP_FILE = 'slick.doc',
   COMPILE_ERROR_FILE='$errors.tmp',
#if __PCDOS__
   USERDEFS_FILE='userdefs',
   STATE_FILENAME='slick.sta',
   _MULTI_USER=1,
#else
   USERDEFS_FILE='unixdefs',
   STATE_FILENAME='slick.stu',
   _MULTI_USER=1,
#endif
   MAX_LINE=2046;

 const
   PAUSE_COMMAND =4,
   QUIET_COMMAND =8;

 const
    HIDE_BUFFER       =1,
    THROW_AWAY_CHANGES=2,
    KEEP_ON_QUIT      =4,
    REVERT_ON_THROW_AWAY  =16,
    PROMPT_REPLACE_BFLAG  =32;

 const
   NULL_CORNER_MASK= 0xFF,
   TL_MASK       =0x300,
   TL_LEFT_MASK  =0x100,
   TL_ABOVE_MASK =0x200,
   TL_SHIFT      =2**8,
   TR_MASK       =0xc00,
   TR_RIGHT_MASK =0x400,
   TR_ABOVE_MASK =0x800,
   TR_SHIFT      =2**10,
   BR_MASK       =0x3000,
   BR_RIGHT_MASK =0x1000,
   BR_BELOW_MASK =0x2000,
   BR_SHIFT      =2**12,
   BL_MASK       =0xc000,
   BL_LEFT_MASK  =0x4000,
   BL_BELOW_MASK =0x8000,
   BL_SHIFT      =2**14;

 const
   DIR_SIZE_COL     =4,
   DIR_SIZE_WIDTH   =8,
   DIR_DATE_COL     =14,
   DIR_DATE_WIDTH   =8,
   DIR_TIME_COL     =24,
   DIR_TIME_WIDTH   =6,
   DIR_ATTR_COL     =31,
#if __PCDOS__
   DIR_ATTR_WIDTH   =5,
   DIR_FILE_COL     =38;
#elif __UNIX__
   DIR_ATTR_WIDTH   =10,
   DIR_FILE_COL     =43;
#endif

 const
   PROC_TYPE    = 0x1,
   VAR_TYPE     = 0x4,
   KEYTAB_TYPE  = 0x8,
   COMMAND_TYPE = 0x10,
   GVAR_TYPE    = 0x20,
   GPROC_TYPE   = 0x40,
   MODULE_TYPE  = 0x80,
   MACRO_TYPE   = 0x100,
   BUFFER_TYPE  = 0x200,
   INFO_TYPE    = 0x400,
   BUILT_IN_TYPE= 0X800,
   MENU_TYPE    = 0X1000,
   MISC_TYPE    = 0X2000;

 const
   HELP_TYPES = 'proc='PROC_TYPE         'macro='MACRO_TYPE       ||' '||
                'bufvar='BUFFER_TYPE     'built-in='BUILT_IN_TYPE ||' '||
                'command='COMMAND_TYPE   'misc='MISC_TYPE         ||' '||
                'any=-1',

   HELP_CLASSES= 'window=1 search=2 cursor=4 mark=8 misc=16 name=32'||' '||
                 'string=64 display=128 keyboard=256 buffer=512'    ||' '||
                 'file=1024 menu=2048 help=4096 cmdline=8192' ||' '||
                 'language=16384 mouse=32768 any=-1',

   PCB_TYPES='built-in='BUILT_IN_TYPE||' '||
             'command='COMMAND_TYPE||' '||
             'proc='PROC_TYPE;

 const
   BUF_NAME_COLOR_FIELD        =         0,
   BOX_COLOR_FIELD             =         1,
   MESSAGE_COLOR_FIELD         =         2,
   FKEYTEXT_COLOR_FIELD        =         3,
   WINDOW_COLOR_FIELD          =         4,
   COMMAND_COLOR_FIELD         =         5,
   MARK_COLOR_FIELD            =         6,
   SUBTITLE_COLOR_FIELD        =         7,
   CURSOR_COLOR_FIELD          =         8,
   ACTIVE_BOX_COLOR_FIELD      =         9,
   CURRENT_LINE_COLOR_FIELD    =         10,
   MARKED_CLINE_COLOR_FIELD    =         11,

   COLOR_FIELDS= 'buf-name=0 window-border=1 message=2 fkeytext=3 window-text=4'||' '||
                 'command=5 mark=6 subtitle=7 cursor=8 awindow-border=9'||' '||
                 'popup-window-border=-1 popup-window-text=-1'||' '||
                 'popup-buf-name=-1 popup-subtitle=-1'||' '||
                 'popup-mark=-1 popup-selection-char=-1'||' '||
                 'erase-command=5',
   COLOR_FIELDS2= 'sizemove-border=9 current-line=10 marked-current-line=11';

  const
    RETRIEVE_VIEW_ID  = 7,
    RETRIEVE_BUF_ID   = 0,
    VSWID_HIDDEN    = 8,
    VSWID_HIDDEN  = 0;


 const
   TERMINATE_MATCH   =1,
   FILE_CASE_MATCH   =2,
   NO_SORT_MATCH     =4,
   REMOVE_DUPS_MATCH =8,
   AUTO_DIR_MATCH    =16,

   MORE_ARG      ='*',

   WORD_ARG      ='W',

   FILE_ARG      ='F:'(FILE_CASE_MATCH|AUTO_DIR_MATCH),
   BUFFER_ARG    ='B:'FILE_CASE_MATCH,
   CMDNMACRO_ARG ='CK',
   COMMAND_ARG   ='C',
   MACRO_ARG     ='K',
   MODULE_ARG    ='M',
   PC_ARG        ='PC',

   PCB_ARG       ='PCB:'REMOVE_DUPS_MATCH,
   PCB_TYPE      = COMMAND_TYPE|PROC_TYPE|BUILT_IN_TYPE,
   PCB_TYPE_ARG  ='PCBT',
   PROC_ARG      ='P',
   VAR_ARG       ='V',
   ENV_ARG       ='E',
   MENU_ARG      ='MNU',
   HELP_ARG      ='H:'REMOVE_DUPS_MATCH,


   HELP_TYPE     = COMMAND_TYPE|PROC_TYPE|MACRO_TYPE|BUILT_IN_TYPE|MISC_TYPE,
   HELP_TYPE_ARG ='HT',
   HELP_CLASS_ARG='HC',
   COLOR_FIELD_ARG='CF',
   TAG_ARG='TAG:'(REMOVE_DUPS_MATCH|NO_SORT_MATCH|TERMINATE_MATCH),

   MARK_ARG2=    1,

   MODIFY_ARG2=  2,


   DELETE_ARG2=  4,


   HELP_ARG2=    8,

   HELPSALL_ARG2=    16;




 const
#if __PCDOS__
   FILESEP = '\',
   FILESEP2= '/',
   PATHSEP=';',
#else
   FILESEP = '/',
   FILESEP2= '\',
   PATHSEP=':',
#endif
   ARGSEP='-';

 typeless
   root_keys
   ,mode_keys
   ,default_keys
   ,help_file_spec
   ,menu_file_spec
   ,def_load_options='-L'
   ,def_save_options='-O'
   ,def_read_ahead_lines= 500
   ,def_kill_buffers= 2
   ,def_tab_ext=''

   ,def_preload_ext=''

   ,def_auto_restore=0
   ,def_mark_style='E'
   ,def_word_chars='A-Za-z0-9_$'

   ,def_line_insert='A'
   ,buffer_view_id

   ,def_exit_process
   ,def_user_args
   ,error_file
   ,arg_complete


   ,def_keys
   ,def_prompt
#if __PCDOS__
   ,_fpos_case='I'

#else
   ,_fpos_case=''
#endif
   ,_macro_ext
   ,_tag_pass
   ,_config_modify
   ,def_unix_expansion;

 const
    LANGUAGE_MODES='c pascal slick',
    INITIAL_LANGUAGE_MARGINS='1 254';

 const
    MENU_OVERLAP=2,
    LIST_OVERLAP=4,
    WORD_OVERLAP=8,
    DISPLAY_COLOR_OVERLAP=16,
    HIDE_WINDOW_OVERLAP= 32,
    NO_BORDERS_OVERLAP = 64,
    HSCROLL_BAR_OVERLAP =128,
    VSCROLL_BAR_OVERLAP =256;

 const
    STRIP_SPACES_WWS =1,
    WORD_WRAP_WWS    =2,
    JUSTIFY_WWS      =4;

  const
    IGNORECASE_SEARCH= 1,
    MARK_SEARCH      = 2,
    POSITIONONLASTCHAR_SEARCH      = 4,
    REVERSE_SEARCH   = 8,
    RE_SEARCH        = 16,
    WORD_SEARCH      = 32,
    REV1_SEARCH      = 64,
    UNIXRE_SEARCH    = 128,
    NO_MESSAGE_SEARCH= 256,
    GO_SEARCH        = 512,
    INCREMENTAL_SEARCH=1024;
const
        NSPECIAL_KEYS = 19,
        BACKSPACE_SK =3,
        C_2_K=          256-127,
        C_PRTSC_K=      (C_2_K+1),
        C_CTRL_K =      (C_2_K+2),
        A_ALT_K  =      (C_2_K+3),
        KEYTAB_MAXASCII= 129,
        KEYTAB_MAXEXT =     260,

        ALT_KEYS_OFFSET= (C_2_K+4),
        SPECIAL_KEYS_OFFSET=   (ALT_KEYS_OFFSET+128),
        A_SPECIAL_KEYS_OFFSET= (SPECIAL_KEYS_OFFSET+NSPECIAL_KEYS),
        C_SPECIAL_KEYS_OFFSET= (A_SPECIAL_KEYS_OFFSET+NSPECIAL_KEYS),
        S_SPECIAL_KEYS_OFFSET= (C_SPECIAL_KEYS_OFFSET+NSPECIAL_KEYS),
        A_C_SPECIAL_KEYS_OFFSET= (S_SPECIAL_KEYS_OFFSET+NSPECIAL_KEYS),
        NFKEYS =12,
        FKEYS_OFFSET =   (A_C_SPECIAL_KEYS_OFFSET+BACKSPACE_SK+1),
        S_FKEYS_OFFSET=  (FKEYS_OFFSET+NFKEYS),
        A_FKEYS_OFFSET=  (S_FKEYS_OFFSET+NFKEYS),
        C_FKEYS_OFFSET=  (A_FKEYS_OFFSET+NFKEYS),
        S_C_SPECIAL_KEYS_OFFSET= (C_FKEYS_OFFSET+NFKEYS),
        NMEVENTS2=13,
        NMEVENTS=9,
        MEVENTS_OFFSET=(S_C_SPECIAL_KEYS_OFFSET+NSPECIAL_KEYS),
        S_MEVENTS_OFFSET=(MEVENTS_OFFSET+NMEVENTS2),
        A_MEVENTS_OFFSET=(S_MEVENTS_OFFSET+NMEVENTS),
        C_MEVENTS_OFFSET=(A_MEVENTS_OFFSET+NMEVENTS);

  const
     MLCOMMENTINDEX_LF  =0x08,
     MLCOMMENTLEVEL_LF  =0x07,
     MODIFY_LF          =0x10,
     INSERTED_LINE_LF   =0x20,
     VIMARK_LF          =0x100,
     USER1_LF           =0x200;

// rc.sh  2.4 version

const
   FILE_NOT_FOUND_RC = -2,
   PATH_NOT_FOUND_RC = -3,
   TOO_MANY_OPEN_FILES_RC = -4,
   ACCESS_DENIED_RC = -5,
   MEMORY_CONTROL_BLOCKS_RC = -7,
   INSUFFICIENT_MEMORY_RC = -8,
   INVALID_DRIVE_RC = -15,
   NO_MORE_FILES_RC = -18,
   DISK_IS_WRITE_PROTECTED_RC = -19,
   UNKNOWN_UNIT_RC = -20,
   DRIVE_NOT_READY_RC = -21,
   BAD_DEVICE_COMMAND_RC = -22,
   DATA_ERROR_RC = -23,
   BAD_REQUEST_STRUCTURE_LENGTH_RC = -24,
   SEEK_ERROR_RC = -25,
   UNKNOWN_MEDIA_TYPE_RC = -26,
   SECTOR_NOT_FOUND_RC = -27,
   PRINTER_OUT_OF_PAPER_RC = -28,
   WRITE_FAULT_RC = -29,
   READ_FAULT_RC = -30,
   GENERAL_FAILURE_RC = -31,
   ERROR_OPENING_FILE_RC = -32,
   ERROR_READING_FILE_RC = -33,
   ERROR_WRITING_FILE_RC = -34,
   ERROR_CLOSING_FILE_RC = -35,
   INSUFFICIENT_DISK_SPACE_RC = -36,
   PROGRAM_CAN_NOT_BE_RUN_IN_OS2_RC = -37,
   ERROR_CREATING_DIRECTORY_RC = -38,
   SESSION_PARENT_EXISTS_RC = -39,
   UNABLE_TO_OPEN_KDF_RC = -500,

   UNABLE_TO_READ_KDF_RC = -502,

   INCORECT_KDF_VERSION_RC = -504,

   ERROR_OPENING_KEYBOARD_RC = -506,

   UNABLE_TO_OPEN_TTY_DEV_RC = -508,
   SLICK_EDITOR_VERSION_RC = -2000,
   SPILL_FILE_TOO_LARGE_RC = -2001,
   ON_RC = -2002,
   OFF_RC = -2003,
   EXPECTING_IGNORE_OR_EXACT_RC = -2004,
   ERROR_IN_MARGIN_SETTINGS_RC = -2005,
   ERROR_IN_TAB_SETTINGS_RC = -2006,
   UNKNOWN_COMMAND_RC = -2007,
   MISSING_FILENAME_RC = -2008,
   TOO_MANY_FILES_RC = -2009,
   TOO_MANY_MARKS_RC = -2010,
   LINES_TRUNCATED_RC = -2011,
   TEXT_ALREADY_MARKED_RC = -2012,
   TEXT_NOT_MARKED_RC = -2013,
   INVALID_MARK_TYPE_RC = -2014,
   SOURCE_DEST_CONFLICT_RC = -2015,
   NEW_FILE_RC = -2016,
   LINE_MARK_REQUIRED_RC = -2017,
   BLOCK_MARK_REQUIRED_RC = -2018,
   TOO_MANY_GROUPS_RC = -2019,
   MACRO_FILE_NOT_FOUND_RC = -2020,

   HIT_ANY_KEY_RC = -2023,
   BOTTOM_OF_FILE_RC = -2024,
   TOP_OF_FILE_RC = -2025,
   INVALID_POINT_RC = -2026,
   TYPE_ANY_KEY_RC = -2027,
   TOO_MANY_WINDOWS_RC = -2028,
   NOT_ENOUGH_MEMORY_RC = -2029,
   PRESS_ANY_KEY_TO_CONTINUE_RC = -2030,
   SPILL_FILE_IO_ERROR_RC = -2031,
   TYPE_NEW_DRIVE_LETTER_RC = -2032,
   NOTHING_TO_UNDO_RC = -2033,
   NOTHING_TO_REDO_RC = -2034,
   LINE_OR_BLOCK_MARK_REQUIRED_RC = -2035,
   INVALID_MARK_RC = -2036,
   SEARCHING_AND_REPLACING_RC = -2037,
   COMMAND_CANCELLED_RC = -2038,
   ERROR_CREATING_SEMAPHORE_RC = -2039,
   ERROR_CREATING_THREAD_RC = -2040,
   ERROR_CREATING_QUEUE_RC = -2041,
   PROCESS_ALREADY_RUNNING_RC = -2042,
   CANT_FIND_INIT_PROGRAM_RC = -2043,
   CMDLINE_TOO_LONG_RC = -2044,
   SERIAL_NUMBER_RC = -2045,
   INVALID_REGULAR_EXPRESSION_RC = -2500,
   INCORRECT_VERSION_RC = -3000,
   NO_MAIN_ENTRY_POINT_RC = -3001,
   INTERPRETER_OUT_OF_MEMORY_RC = -3002,
   PROCEDURE_NOT_FOUND_RC = -3003,

   MODULE_ALREADY_LOADED_RC = -3006,
   CANT_REMOVE_MODULE_RC = -3007,
   NUMERIC_OVERFLOW_RC = -3008,
   INVALID_NUMBER_ARGUMENT_RC = -3009,
   RECURSION_TOO_DEEP_RC = -3010,
   INVALID_NUMBER_OF_PARAMETERS_RC = -3011,
   OUT_OF_STRING_SPACE_RC = -3012,
   EXPRESSION_STACK_OVERFLOW_RC = -3013,
   ILLEGAL_OPCODE_RC = -3014,
   INVALID_ARGUMENT_RC = -3015,
   LOOP_STACK_OVERFLOW_RC = -3016,
   DIVIDE_BY_ZERO_RC = -3017,
   INVALID_CALL_BY_REFERENCE_RC = -3018,
   PROCEDURE_NEEDS_MORE_ARGS_RC = -3019,
   BREAK_KEY_PRESSED_RC = -3020,
   CANT_WRITE_STATE_DURING_REL_RC = -3021,
   STRING_NOT_FOUND_RC = -3022,
   KBD_MACRO_TOO_LONG_RC = -3023,
   COMMAND_NOT_FOUND_RC = -3024,

   FUNCTION_NOT_SUPPORTED_IN_DOS_RC = -3027,
   FUNCTION_NOT_SUPPORTED_IN_OS2_RC = -3028,
   INVALID_NAME_INDEX_RC = -3029,
   INVALID_OPTION_RC = -3030,

   SPELL_FILE_NOT_FOUND_RC	= -3501,
   SPELL_ERROR_OPENING_MAIN_DICT_FILE_RC	= -3504,
   SPELL_ERROR_OPENING_USER_DICT_FILE_RC	= -3507,
   SPELL_NOT_ENOUGH_MEMORY_RC	= -3510,
   SPELL_ERROR_READING_MAIN_INDEX_RC	= -3511,
   SPELL_ERROR_OPENING_COMMON_DICT_RC	= -3514,
   SPELL_COMMON_DICT_TOO_LARGE_RC	= -3517,
   SPELL_ERROR_READING_COMMON_DICT_RC	= -3518,
   SPELL_USER_DICT_TOO_LARGE_RC	= -3521,
   SPELL_ERROR_READING_USER_DICT_RC	= -3524,
   SPELL_ERROR_UPDATING_USER_DICT_FILE_RC	= -3527,
   SPELL_ACCESS_DENIED_RC	= -3530,
   SPELL_OUT_OF_DISK_SPACE_RC	= -3533,
   SPELL_ERROR_READING_MAIN_DICT_RC	= -3536,
   SPELL_WORD_NOT_FOUND_RC	=-3537,
   SPELL_CAPITALIZATION_RC	=-3538,
   SPELL_WORD_TOO_SMALL_RC	=-3539,
   SPELL_WORD_TOO_LARGE_RC	=-3540,
   SPELL_WORD_INVALID_RC	=-3541,
   SPELL_REPLACE_WORD_RC	=-3542,
   SPELL_HISTORY_TOO_LARGE_RC	=-3543,
   SPELL_USER_DICT_NOT_LOADED_RC	=-3544,
   SPELL_NO_MORE_WORDS_RC	=-3545,
   SPELL_REPEATED_WORD_RC	=-3546;


#endif
