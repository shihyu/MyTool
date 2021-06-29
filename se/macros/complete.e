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
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "tagsdb.sh"
#include "autocomplete.sh"
#import "autocomplete.e"
#import "codehelp.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "recmacro.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#import "wkspace.e"
#import "files.e"
#endregion

const SE_ORIG_MENU_SUFFIX=            '_se_orig';

bool def_filematch_case_insensitive=true;

/**
 * The maximum number of items that should be displayed
 * by argument completion.  If there are more items than this
 * the user will be prompted if they want to get all items
 * or not.
 * 
 * @default 2000 items
 * 
 * @categories Configuration_Variables
 */
int def_max_completion_items=5000;
// true- prefix match
// false- contains match
bool def_command_completion_style=true;

enum {
   /**
    * If the user says "Yes" to continue searching for matches even after 
    * being prompted about hitting the maximum number of completion items, 
    * check again when the search hits the max times this factor, and prompt 
    * one last time, warning that this is the last change to stop searching. 
    */
   MAX_COMPLETION_ITEMS_REPROMPT_FACTOR=10
};


///////////////////////////////////////////////////////////////////////////////
// AUTO ARGUMENT COMPLETION LIST OPTIONS
///////////////////////////////////////////////////////////////////////////////

/**
 * Control the default behavior of text box argument and
 * command line auto completion.
 * This value is a bitset of the flags defined by VSARGUMENT_COMPLETION_*.
 * The default is for everything to be enabled, including the use of
 * TAB and S_TAB to cycle up and down through the list.
 * <ul>
 * <li><b>VSARGUMENT_COMPLETION_ENABLE</b>
 * <li><b>VSARGUMENT_COMPLETION_NO_TAB_NEXT</b>
 * <li><b>SARGUMENT_COMPLETION_COMMANDLINE</b>
 * <li><b>VSARGUMENT_COMPLETION_UNC_PATHS</b>
 * </ul>
 * 
 * @default VSARGUMENT_COMPLETION_ALL_OPTIONS
 * @categories Configuration_Variables
 */
enum_flags VSArgumentCompletionFlags {
   VSARGUMENT_COMPLETION_DISABLE       = 0x0000,
   VSARGUMENT_COMPLETION_ENABLE        = 0x0001,
   VSARGUMENT_COMPLETION_NO_TAB_NEXT   = 0x0002,
   VSARGUMENT_COMPLETION_COMMANDLINE   = 0x0004,
   VSARGUMENT_COMPLETION_UNC_PATHS     = 0x0008,
   VSARGUMENT_COMPLETION_ALL_OPTIONS   = 0xffff
};

static bool gcompletion_list_already_deleted=false;

int def_argument_completion_options = VSARGUMENT_COMPLETION_ALL_OPTIONS;
/**
 * Control the maximum number of arguments to be displayed in the
 * list created by argument completion.  The default is 100 items,
 * which gives very good response time, without overloading the user
 * with more results than he would want to cycle through.
 * 
 * @default 500
 * @categories Configuration_Variables
 */
int def_argument_completion_maximum = 500;


/**
 * File position case argument, used with the {@link pos}
 * function, 'i' on Windows, '' on Unix
 * 
 * @see pos
 * @see sort
 * @see remove_duplicates
 * @see _lbsort
 */
_str _fpos_case;

// forward declaration
static _str clist_fall_through(int reason, _str &result, _str key);

/**
 * Key in the last character typed.
 * 
 * @see keyin
 * @see last_event
 */
static void keyin_char()
{
   _str keyin_char = key2ascii(last_event());
   if ( length(keyin_char) != 1 ) {
      keyin_char='';
   }
   keyin(keyin_char);
}

/**
 * <p>For the command line, the partially typed command currently on the 
 * command line is filled in ("completed") as much as possible.</p>
 * 
 * <p>For an edit window or editor control, a space character is inserted at 
 * the cursor.</p>
 * 
 * @param completion_info
 * <p>The <i>completion_info</i> must be specified for this function to work 
 * properly for a text box other than the command line.  For a text box, the 
 * partially typed argument is completed according to the <i>completion_info</i> 
 * string.   <i>completion_info</i> is a space-delimited string of completion 
 * constants.  The completion constants are defined in "slick.sh' and have the 
 * suffix "_ARG".</p>
 * 
 * @see complete
 * 
 * @appliesTo Edit_Window, Editor_Control, Command_Line
 * 
 * @categories Completion_Functions
 */
_command void maybe_complete(_str completion_info=null) name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      if ( completion_info!=null && completion_info!=COMMANDLINE_ARG) {
         complete(completion_info);
      } else {
         complete();
      }
   } else {
      keyin_char();
   }
}

static _str get_arg_completion_info_description(_str completion_info)
{
   switch (completion_info) {
   case WORD_ARG:                      return nls("Word");
   case FILE_ARG:                      
   case FILE_MAYBE_LIST_BINARIES_ARG:  
   case FILENOAUTODIR_ARG:
   case FILENOQUOTES_ARG:              
   case FILENEW_ARG:
   case FILENEW_NOQUOTES_ARG:
   case MULTI_FILE_ARG:
   case SEMICOLON_FILES_ARG:           return nls("File");
   case PROJECT_FILE_ARG:              return nls("Project File");
   case WORKSPACE_FILE_ARG:            return nls("Workspace File");
   case DIR_ARG:                       
   case DIRNOQUOTES_ARG:
   case DIRNEW_ARG:
   case DIRNEW_NOQUOTES_ARG:           return nls("Directory");
   case BUFFER_ARG:      
   case EMACS_BUFFER_ARG:              return nls("Buffer Name");
   case COMMAND_ARG:                   
   case COMMANDLINE_ARG:               return nls("Command");
   case PICTURE_ARG:                   return nls("Bitmap Name");
   case FORM_ARG:                      return nls("Form Name");
   case OBJECT_ARG:                    return nls("Form or Menu Name");
   case OPTIONS_SEARCH_ARG:            return nls("Options Category");
   case MODULE_ARG:                    return nls("Slick-C Module");
   case DLLMODULE_ARG:                 return nls("DLL Module");
   case PCB_TYPE_ARG:
   case PC_ARG:                        return nls("Slick-C Comamnd or Procedure");
   case SLICKC_FILE_ARG:               return nls("Slick-C File");
   case MACROTAG_ARG:                  return nls("Slick-C Symbol");
   case MACRO_ARG:                     return nls("User Macro Name");
   case VAR_ARG:                       return nls("Slick-C Variable");
   case ENV_ARG:                       return nls("Environment Variable");
   case MENU_ARG:                      return nls("Menu");
   case MODENAME_ARG:                  return nls("Language Mode");
   case BOOKMARK_ARG:                  return nls("Bookmark");
   case HELP_ARG:
   case HELP_TYPE_ARG:
   case HELP_CLASS_ARG:                return nls("Help Item");
   case COLOR_FIELD_ARG:               return nls("Color Setting");
   case CLASSNAME_ARG:                 return nls("Class Name");
   case CTAGS_ARG:                     
   case TAG_ARG:                       return nls("Symbol");
   default:
      if (_last_char(completion_info) == '*') {
         return get_arg_completion_info_description(strip(completion_info, 'T', '*'));
      }
      return "";
   }
}

// information about the last list_matches operation done
static int  glast_list_matches_column=1;
static _str glast_list_matches_word='';
static _str glast_list_matches_prefix='';
static _str glast_list_matches_suffix='';

/**
 * <p>For the command line, if the cursor is on the command line, a selection 
 * list of possible completions to the partially typed command currently on the 
 * command line is displayed.</p>
 * 
 * <p>For an edit window or editor control, a '?' character is inserted at 
 * the cursor.</p>
 * 
 * <p>The <i>completion_info</i> must be specified for this function to work 
 * properly for a text box other than the command line.  For a text box, a 
 * selection list of possible completions to the partially typed argument is 
 * displayed.  <i>completion_info</i> is a spaced-delimited string of completion 
 * constants.  The completion constants are defined in "slick.sh' and have the 
 * suffix "_ARG".</p>
 * 
 * @param completion_info
 *                Completion info
 * @param notused
 * @param auto_select
 *                Auto selection if one match
 * @param args_to_command
 *                True if listing matches on the arguments to a command
 *                where the command name itself is not included.
 * 
 * @return Returns 0 if there are no matches, 1 if last arg.
 * 
 * @appliesTo Edit_Window, Editor_Control, Text_Box
 * 
 * @categories Completion_Functions
 * 
 */
_command bool maybe_list_matches( _str completion_info='',
                                  _str notused='',
                                  bool auto_select=false,
                                  bool args_to_command=false,
                                  bool doEditorCtl=false,
                                  _str first_arg_completion_info=null,
                                  bool doAddToAutoCompletion=false,
                                  typeless &words=null,
                                  bool doAddToArgumentCompletion=false,
                                  bool &case_sensitive_matching=false,
                                  int editorctl_start_col=0
                                   ) name_info(','VSARG2_MULTI_CURSOR|VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (completion_info==COMMANDLINE_ARG) {
      completion_info='';
      args_to_command=false;
   }
   glast_list_matches_column=1;
   glast_list_matches_word='';
   glast_list_matches_prefix='';
   glast_list_matches_suffix='';

   if ( command_state() || doEditorCtl) {

      return_val := false;
      line := "";
      col := 1;
      if (doEditorCtl) {
         if (editorctl_start_col>0) {
            line=_expand_tabsc(editorctl_start_col);
            col=p_col-editorctl_start_col+1;
            if (col<1) col=1;
         } else {
            line=_expand_tabsc();
            col=p_col;
         }
      } else {
         get_command(line,col);
      }
      /*
       Would like plugin:\\? to list plugins.

      if (_isWindows() && last_event():=='?' && col>=3 && substr(line,col-2,1):=='\' && substr(line,col-1,1):=='\') {
         keyin('?');
         return false;
      } */

     /* Could be search command like /.... */
     /* If first char of command line is not an alpha AND not just args of command. */
     if ( line!='' && ! isalpha(substr(line,1,1)) && ! args_to_command ) {
        if (!doAddToAutoCompletion) keyin_char();
        return false;
     }

     int start_word_col;
     _str word;
     _str temp_line=line;

     name_prefix := "";
     typeless match_flags='';
     parse completion_info with name_prefix ':' match_flags;
     match_flags=strip(match_flags,'T','*');

     // IF we are selecting files
     // For compatibility with bash throw in '='.  This is so that 
     //     ./configure --prefix=/gtk<Tab>  
     // works just like the bash shell.  Not sure we = was added.  We 
     // may have to add back slash support so a\=b works for a file
     // or directory named "a=b".
     _str alternate_temp_line=translate(temp_line,"   ","=>|<");
     if (isinteger(match_flags) && (match_flags & FILE_CASE_MATCH) && !(match_flags&EMACS_BUF_MATCH)) {
        // Translate redirection characters to space
        temp_line=alternate_temp_line;
     }

     // IF the current and previous characters are space
     if (col>1 && substr(temp_line,col-1,2,'*'):=='  ') {
        // Split the line so we insert a word here instead of replacing
        // the next word.
        temp_line=substr(temp_line,1,col);
     }

     /* if the current character is a space and the previous character is not. */
     /* Try to expand the current argument on the command line. */
     int arg_number= _get_arg_number(temp_line,col,word,start_word_col,args_to_command,completion_info);
     if( isinteger(match_flags) && match_flags&EMACS_BUF_MATCH ) {
        // Override normal word matching if we are matching on a buffer line
        // of the form:
        //
        // name<path>
        //
        // since the path could have spaces in it, which would cause
        // arg_number > 1. This would cause us to list matches on the
        // last space-delimited word. Not what we want in this case.
        arg_number=1;
        word=temp_line;
        start_word_col=1;
     }

     fall_through_file_completion := false;
     //say('arg_number='arg_number' col='col' word=<'word'> start_word_col='start_word_col' args_to_command='args_to_command);
     if (arg_number==1 && first_arg_completion_info!=null) {
        completion_info=first_arg_completion_info;
     }

     status := 0;
     match_fun_prefix := "";
     if ( arg_number<=1 && ! args_to_command ) {
        match_fun_prefix=COMMAND_ARG;
        completion_info=COMMAND_ARG;
     } else {
        if ( args_to_command ) {
           status=_find_match_fun(temp_line,arg_number,match_fun_prefix,true,completion_info,false,completion_info);
        } else {
           status=_find_match_fun(temp_line,arg_number,match_fun_prefix,true,null,false,completion_info);
           if (status && status!=2) {
              arg_number= _get_arg_number(alternate_temp_line,col,word,start_word_col,args_to_command,completion_info);
              status=_find_match_fun(alternate_temp_line,arg_number,match_fun_prefix,true,"f:"(FILE_CASE_MATCH)"*");
              completion_info = MULTI_FILE_ARG;
              fall_through_file_completion=true;
              auto_select=true;
           }
        }
        if ( status ) {
           if (!doAddToAutoCompletion) keyin_char();
           return false;
        }
     }

     multi_select := 0;
     typeless last_arg2=0;
     int match_fun_index=match_prefix2index(match_fun_prefix,match_flags,multi_select, last_arg2);

     glast_list_matches_word=word;
     glast_list_matches_prefix=substr(line,1,start_word_col-1);
     glast_list_matches_suffix=substr(line,start_word_col+length(word));
     glast_list_matches_column=start_word_col;

     if (doAddToAutoCompletion) {
        list_matches(strip(word),match_fun_prefix,'',0,'',(auto_select)?auto_select:false,doAddToAutoCompletion,words,doAddToArgumentCompletion,case_sensitive_matching);
        return(false);
     }

     // disable automatic argument completion until we are done here
     orig_ListCompletions := true;
     if (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX) {
        ArgumentCompletionTerminate();
        orig_ListCompletions = p_ListCompletions;
        p_ListCompletions=false;
     }

     //messageNwait('word='word' new_match_name='new_match_name);
     /*
       In Open tool window, type "*\?" and get infinite loop unless check for repeats.
       There might be a better way to fix this but this will break the infinite loop.
       Maybe the "filenew_match" function needs to support matching wildcards in paths.
     */
     repeat := "";
     for (;;) {

        title := get_arg_completion_info_description(completion_info);
        if (title != "") {
           title = nls("Select a %s", title);
        }

        //old_word=strip(word);
        last_event(ESC);
        _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,1);
        _str result=list_matches(strip(word),match_fun_prefix,title,0,'',(auto_select)?auto_select:false);
        _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,0);
        if ( result=='' ) {
           /* No matches found OR ESC pressed OR match function not found. */
           if (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX) {
              p_ListCompletions=orig_ListCompletions;
           }
           return false;
        }

        keep_listing := ((match_flags & AUTO_DIR_MATCH) && _last_char(result):==FILESEP);
        if (keep_listing) {
           if (repeat!='') {
              if (repeat:==result) {
                 /* No matches found OR ESC pressed OR match function not found. */
                 if (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX) {
                    p_ListCompletions=orig_ListCompletions;
                 }
                 return false;
              }
           }
           repeat=result;
        } else {
           repeat='';
        }
        // When we complete on a data set, unless a data set's type
        // is known, the PDS entries presented by list_matches() do not
        // have the trailing FILESEP to indicate that it is a "directory"
        // and not a file.
        //
        // As a result, if a resulting selection is a data set, we
        // need to stat() the data set to ensure its type. Calling
        // file_match("-p") does this trick efficiently.
        if (!keep_listing && _DataSetIsFile(result)) {
           dsmatched := file_match("-p "result, 1);
           keep_listing=((match_flags & AUTO_DIR_MATCH) && _last_char(dsmatched):==FILESEP);
        }

        if ( result!='' ) {
           //last_arg=_arg_complete && last_event():==ENTER && ! keep_listing
           last_arg := _arg_complete && ! keep_listing;
           if ( keep_listing ) {
              /* Translate  path/../ to / and Translate path/./ to path */
              len := length(result);
              if ( len>4 && _Substr(result,length(result)-3)==FILESEP'..'FILESEP ) {
                 if ( _Substr(result,length(result)-4,1)!='.' ) {
                    result=_strip_filename(substr(result,1,length(result)-4),'n');
                 }
              } else if ( len>3 && _Substr(result,length(result)-2)==FILESEP'.'FILESEP ) {
                 result=substr(result,1,length(result)-2);
                 if (result:==line) {
                    keep_listing=false;
                 }
              }
           }

           replace_word(line,word,start_word_col,result);
           if (doEditorCtl) {
              if (_arg_complete) {
                 result :+= ' ';
              }
              replace_line(line);
              p_col=start_word_col+_rawLength(result);
           } else {
              set_command(line,start_word_col+length(result)+_arg_complete);
           }

           if ( last_arg && ! args_to_command && p_window_id==_cmdline &&
                !fall_through_file_completion) {
              command_execute()  /* Execute the command on the command line. */;
           }

           if ( ! keep_listing ) {
              if (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX) {
                 p_ListCompletions=orig_ListCompletions;
              }
              return(last_arg);
           }
           return_val=last_arg;
        }

        /* matching files? */
        if ( !auto_select && keep_listing ) {
           /* Check if there is at least one match. */
           _str match_name = call_index(result,1,match_fun_index);
           if ( match_flags & TERMINATE_MATCH ) {
              call_index('',2,match_fun_index);
           }
           if ( match_name=='' ) {
              break;
           }
           word=result;
           continue;
        }

        if (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX) {
           p_ListCompletions=orig_ListCompletions;
        }
        return return_val;
     }
     /* messageNwait('arg_number='arg_number' col='col' word=<'word'> start_word_col' start_word_col) */

   } else {
      keyin_char();
   }

   return false;
}

/**
 * Completes the current command argument being entered on the command
 * line according to the command's completion info or <i>completion_info</i>
 * specified.  <i>completion_info</i> must be zero or more completion
 * constants delimited with space characters.  For example,
 * <b>complete</b>(FILE_ARG' 'FILE_ARG) would specify that the command
 * takes two file name arguments.  Completion constants have the suffix
 * "_ARG" and are listed in "slick.sh".
 *
 * @categories Completion_Functions
 */
void complete(_str completion_info=null)
{
   line := "";
   col := 1;
   get_command(line,col);

   status := 0;
   fun_name_prefix := "";
   command_case := true;

   /* if the current character is a space and the previous character is not. */
   if ( col>1 && _Substr(line,col,1):==' ' && _Substr(line,col-1):!=' ' &&
       (isalpha(substr(line,1,1)) || completion_info!=null)
      ) {

      one_argument_text_box := false;
      /* Try to expand this word on the command line. */
      word := "";
      start_word_col := 1;
      int arg_number= _get_arg_number(line,col,word,start_word_col,completion_info!=null,completion_info);

      // IF doing completion on command argument of a command line
      if ( arg_number<=1 && completion_info==null ) {

         index := 0;
         if (def_keys=='ispf-keys') {
            index=name_match('ispf-'strip(word),COMMAND_TYPE|IGNORECASE_TYPE);
         }

         if (!index) {
            index=name_match(strip(word),1,COMMAND_TYPE);
            if (!index) {
               index=name_match(strip(word),1,COMMAND_TYPE|IGNORECASE_TYPE);
            }
         }

         if ( ! index ) {
           keyin_char();
           /*_str k=get_event();
           if (command_state() && vsIsMouseEvent(event2index(k))) {
              // Can't invoke mouse event on text box
              return;
           }
           call_key(k);*/
           return;
         }

         fun_name_prefix=COMMAND_ARG;
         command_case=true;

      } else {

         if ( completion_info!=null ) {
            status=_find_match_fun(line,arg_number,fun_name_prefix,false,completion_info,one_argument_text_box);
         } else {
            status=_find_match_fun(line,arg_number,fun_name_prefix,false,completion_info,one_argument_text_box);
         }
         if ( status || word=='' ) {
           keyin_char();
           return;
         }
         command_case=false;
      }

      expand_word(line,word,start_word_col,fun_name_prefix,command_case,one_argument_text_box);
      return;
  }

  keyin_char();
}

/**
 * Get the argument number for the current command.
 * 
 * @param line             command line being completed
 * @param col              column within line
 * @param word             (output) set to current argument
 * @param start_word_col   (output) column that argument starts on
 * @param args_to_command  true if completion info was passed in
 * @param completion_info  completion information
 * 
 * @return the argument number
 */
int _get_arg_number( _str line, int col,
                     _str &word,int &start_word_col,
                     bool args_to_command,
                     _str completion_info
                     // Valid only if args_to_command is 'false'
   )
{
   one_arg := 999999;
   // Check for special one argument support only flag
   command := "";
   rest := "";
   if (!args_to_command) {
      parse line with command rest ;
      index := find_index(command,COMMAND_TYPE);
      completion_info='';
      if (index) {
         parse name_info(index) with completion_info ',' ;
      }
   }

   name_prefix := "";
   typeless match_flags='';
   parse completion_info with name_prefix ':' match_flags;
   match_flags=strip(match_flags,'T','*');
   if (isinteger(match_flags) && (match_flags & ONE_ARG_MATCH)) {
      one_arg=(args_to_command?1:2);
   }

   ch := "";
   end_of_word_col := 0;
   arg_number := 0;
   word='';
   _str orig_line=line;

   for (;;) {

      if ( line:=='' ) {
        start_word_col=col;
        arg_number++;
        word='';
        return(arg_number);
      }

      if ( substr(line,1,1):=='"' ) {
         parse line with '"' word '"' +0 ch ' ' line ;
         word='"'word:+ch;
      } else if ( arg_number  || args_to_command) {
         parse line with word ' ' line ;
      } else {
        int i=verify(line,' /','M')   /* allow /. "c/x/y" will be accepted. */;
        if ( i>1 ) {  /* i=1 means "/usr/xxxx/...." i=0 means not found. */
          word=substr(line,1,i-1);
          if ( substr(line,i,1):==' ' ) {  /* Just find a space? */
             line=substr(line,i+1);
          } else {
            line=substr(line,i);
          }
        } else {
          word=line;
          line='';
        }
      }

      end_of_word_col += length(word)+1;
      strip_word := strip(word);
      ch=substr(strip_word,1,1);
      /* don't count options or blanks. */
      if (_isWindows()) {
         if ( ch:=='-' || ch:=='+' || ch:=='[' || ch=='/' || strip_word:=='' ) { continue; }
      } else {
         /* UNIX case */
         if ( ch:=='-' || ch:=='+' || ch:=='[' || strip_word:=='' ) { continue; }
      }

      arg_number++;
      if (arg_number>=one_arg) {
         start_word_col= end_of_word_col-length(word);
         word=substr(orig_line,start_word_col);
         return(arg_number);
      } else if ( end_of_word_col>=col) {
         start_word_col= end_of_word_col-length(word);
         return(arg_number);
      }
   }
}

/**
 * Replace the <code>word</code>, starting at <code>start_word_col</code>
 * with <code>new_word</code>.
 * 
 * @param line             (reference) line to make repacement in
 * @param word             word to replace
 * @param start_word_col   start position to replace at
 * @param new_word         new word to insert
 */
static void replace_word(_str &line,
                         _str word, int start_word_col,
                         _str new_word)
{
  /* Will have to support */
  /* messageNwait('line=<'line'> word=<'word'> word_col=<'start_word_col'> new_word=<'new_word'>') */
  line= substr(line,1,start_word_col-1):+
        new_word:+
        substr(line,start_word_col+length(word));
}
/**
 * Match a file name or directory name.
 * 
 * @param name                entry name to search for
 * @param find_first          'true' to find first, 'false' to find next
 * @param quote_option        quote results?
 * @param file_match_options  options to pass on to {@link file_match}
 * @param semicolon_separator use semicolon as a separator?
 * 
 * @return '' if not more matches, otherwise returns the file name
 */
static _str file_or_dir_match(_str name, bool find_first,
                              bool quote_option,
                              _str file_match_options,
                              bool semicolon_separator=false)
{
   // if this is going to take too long, we won't bother
   if (find_first==1 && _findFirstTimeOut(name,def_fileio_timeout,def_fileio_continue_to_timeout)) {
      return('');
   }
   if (_fpos_case=='' && def_filematch_case_insensitive) {
      file_match_options:+=' +9 ';
   }

   // get rid of any quotes hanging around
   name=strip(name,'B','"');

   prefix := "";

   // are we using semicolons to separate our filenames?
   if (semicolon_separator) {
      i := 1;
      for (;;) {
         int j=pos_file_sepchar(i,name);
         if (!j) {
            prefix=substr(name,1,i-1);
            name=strip(substr(name,i));
            break;
         }
         i=j+1;
      }
      name=strip(strip(name),'B','"');
      name=file_match(file_match_options'"'name,(int)find_first);
   } else if ( substr(name,1,1)=='@') {
      name='@':+file_match(file_match_options'"'substr(name,2),find_first? 1:0);
      if ( name=='@' ) {
         return('');
      }
   } else {
      // just do a regular match
      name=file_match(file_match_options'"'name,find_first? 1:0);
   }

   // determine if the last char is a filesep (that means its a directory!)
   last_char_is_filesep := (_last_char(name):==FILESEP);
   if ( name:!='' ) {
      _arg_complete=(_arg_complete && ! last_char_is_filesep);
   }

   // do we want to quote the results?
    if (semicolon_separator) {
      _arg_complete=false;
      if (quote_option) {
         // maybe quote our filename
         name=_maybe_quote_filename(name);
         // if it's a directory, leave the last quote off the end
         if ( last_char_is_filesep ) {
            name=strip(name,'T','"');
         }
      }
      if (name=='') {
         return('');
      }
      name=prefix:+name;
    } else if (quote_option) {
      // maybe quote our filename
      name=_maybe_quote_filename(name);
      // if it's a directory, leave the last quote off the end
      if ( last_char_is_filesep ) {
         name=strip(name,'T','"');
      }
   }
   return _escape_unix_expansion(name);
}

_str plg_match(_str name, bool find_first) {
   // if this is going to take too long, we won't bother
   if (find_first==1 && _findFirstTimeOut(name,def_fileio_timeout,def_fileio_continue_to_timeout)) {
      return('');
   }
   file_match_options:='';
   if (_fpos_case=='' && def_filematch_case_insensitive) {
      file_match_options:+=' +9 ';
   }

   // get rid of any quotes hanging around
   name=strip(name,'B','"');

   prefix := "";

   for (;;) {
      // just do a regular match
      file=file_match(file_match_options'"'VSCFGPLUGIN_DIR:+name,find_first? 1:0);
      if (file=='') {
         return '';
      }
      if (FILESEP=='\') {
         file=translate(file,'\','/');
      }
      parse file with (FILESEP:+FILESEP) auto plugin_name (FILESEP);
      if (plugin_name!='com_slickedit.base') {
         // maybe quote our filename
         plugin_name=_maybe_quote_filename(plugin_name);
         return plugin_name;
      }
      find_first=false;
   }
}
/**
 * Search for an open buffer with the given file name.
 * 
 * @param name 
 * @param find_first 
 * @param return_path 
 * 
 * @return _str 
 *  
 * @deprecated use buf_match with 'N' option instead
 */
_str _buf_match_no_path(_str name,bool find_first,bool return_path=false)
{
   name=_strip_filename(name,'p');
   _str match=buf_match('',find_first? 1:0);
   for (;;) {
      if ( rc ) {
         return('');
      }
      if ( match!='' ) {
         temp := _strip_filename(match,'P');
         if ( _file_eq(substr(temp,1,length(name)),name) ) {
            if (return_path) {
               return(match);
            }
            return(temp);
         }
      }
      match=buf_match('',0);
   }
}
_str def_binary_ext='.vtg .sx .ex .vsb .obj .exe .lib .dll .pdb .qfy .bmp .jpg .gif .ico .zip .gz .tgz .xz .txz .bz2 .tbz2 .winmd .o .a .so .sl .svgz';

static int ga_match_count;
enum AMatch{
   AMATCH_FILES,
   AMATCH_BUFFERS,
   AMATCH_WORKSPACE,
   AMATCH_RELFILES
};
static AMatch gamatch;


static _str a_match_files(_str name, bool find_first) {
   // do we make exclusions for binary files?
   if (def_keys!='brief-keys' && def_list_binary_files) {
      // the real work is done in f_match
      temp := f_match(name,find_first);

      // we found something!
      if (temp!="") {
         ++ga_match_count;
         return(temp);
      }
   } else {
      case_insensitive_option:='';
      if (_fpos_case=='I' || def_filematch_case_insensitive) {
         case_insensitive_option='9';
      }
      // let f_match do the work
      temp := f_match(name,find_first);
      for (;;) {
         // we didn't find anything, give up on this part
         if ( temp=="" ) break;

         // filter out the binary files
         if ( ! pos('.'_get_extension(temp)' ',def_binary_ext' ',1,case_insensitive_option) ) {
            ++ga_match_count;
            return temp;
         }

         // file was binary, so try again
         temp=f_match(name,false);
      }
   }
   return "";
}

_str a_match(_str name, bool find_first)
{
   // determine if calling find first on this path will take too long
   if (find_first==1 && _findFirstTimeOut(name,def_fileio_timeout,def_fileio_continue_to_timeout)) {
      // takes too long, don't bother
      return('');
   }

   // make sure all our fileseps are pointing the same way
   name=translate(name,FILESEP,FILESEP2);

   // we may be starting a brand new search - if so, initialize our variables
   if (find_first) {
      ga_match_count=0;
      gamatch=AMATCH_FILES;
   }

   _str temp;
   if (gamatch==AMATCH_FILES) {
      temp = a_match_files(name,find_first);
      if (temp!="") {
         return(temp);
      }
   }

   // If there are any wildcard characters in the name (not path), 
   // we don't want to bother with it.
   if (iswildcard(_strip_filename(name,'p')) 
       || substr(name,1,2)=='**'  // Takes too long to search this, so don't bother
       ) {
   //if (iswildcard(name)) {
      return('');
   }

   // we already tried files, buffers are next
   if (gamatch==AMATCH_FILES) {
      find_first=true;
      gamatch=AMATCH_BUFFERS;
   }

   // get just the plain filename
   name_no_path := _strip_filename(name,'p');

   _str orig_name=name;
   // we do this to escape the slash character for wildcard searching
   if (FILESEP=='\') {
      name=stranslate(name,'\\','\');
   }
   case_insensitive_option:='';
   if (_fpos_case=='I' || def_filematch_case_insensitive) {
      case_insensitive_option='9';
   }

   // are we looking for a buffer?
   if ((gamatch==AMATCH_BUFFERS) && (def_edit_flags&EDITFLAG_BUFFERS) && 
       ga_match_count+1<def_max_completion_items) {

      temp = buf_match(name_no_path, (int)find_first, 'N':+case_insensitive_option);
      for (;;) {
         if (temp!='') {
            if (!endsWith(temp,name'*',false,case_insensitive_option'&')) {
               temp = buf_match(name_no_path, 0, 'N');
               continue;
            }
            ++ga_match_count;
            return(temp);
         }
         break;
      }
   }

   // we tried buffers, on to workspace files
   if (gamatch==AMATCH_BUFFERS) {
      find_first=true;
      gamatch=AMATCH_WORKSPACE;
   }

   // are we looking for workspace files?
   if ((gamatch==AMATCH_WORKSPACE) && 
       (def_edit_flags&EDITFLAG_WORKSPACEFILES) && 
       ga_match_count+1<def_max_completion_items) {

      temp=wkspace_file_match(name_no_path,find_first);
      for (;;) {
         if (temp!='') {
            if (!endsWith(temp,name'*',false,case_insensitive_option'&')) {
               temp=wkspace_file_match(name_no_path,false);
               continue;
            }
            ++ga_match_count;
            return(temp);
         }
         break;
      }
   }

   // we tried workspace files, on to files in the directory containing
   // the current file (relative files)
   if (gamatch==AMATCH_WORKSPACE) {
      find_first=true;
      gamatch=AMATCH_RELFILES;
   }

   // are we looking for workspace files?
   if ((gamatch==AMATCH_RELFILES) && !_no_child_windows() &&
       (def_edit_flags & EDITFLAG_SAME_DIR_FILES) && 
       (ga_match_count+1<def_max_completion_items)) {
      name=orig_name;

      editor_wid := _mdi.p_child;
      reldir := _strip_filename(_mdi.p_child.p_buf_name,'N');
      path_no_name := _strip_filename(name,'N');
      isabsolutedir := (path_no_name != "" && _file_eq(path_no_name, absolute(path_no_name)) && isdirectory(path_no_name)) || (_isWindows() && substr(path_no_name,1,2)=='\\');
      if (reldir != "" && reldir != getcwd() && !isabsolutedir) {
         _maybe_append_filesep(reldir);
         reldir_slash_name := reldir:+name;
         temp = a_match_files(reldir_slash_name, find_first);
         if (temp!="") {
            return(temp);
         }
      }
   }

   return '';
}
/**
 * @return  Returns next file name which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.  Returns '' when
 * no more matches are found.
 * 
 * @param name          file name to search for
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @categories Completion_Functions, File_Functions
 */
_str f_match(_str name,bool find_first)
{
   return file_or_dir_match(name,find_first,true,'');
}
/**
 * @return  Returns next file name which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.  Returns '' when
 * no more matches are found.
 * <p>
 * "fnq" means "file no quote".  
 * This function does not quote the files returned.
 * 
 * @param name          file name to search for
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @see f_match
 * 
 * @categories Completion_Functions, File_Functions
 */
_str fnq_match(_str name,bool find_first)
{
   return file_or_dir_match(name,find_first,false,'');
}
/**
 * @return  Returns next file name which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.  Returns '' when
 * no more matches are found.
 * 
 * @param name          file name to search for
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @see f_match
 * 
 * @categories Completion_Functions, File_Functions
 */
_str semicolonfiles_match(_str name,bool find_first)
{
   // Unix needs quotes around filenames which contain semicolons.
   return file_or_dir_match(name,find_first,_isUnix(),'',true);
}
/**
 * @return  Returns next directory name which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.  Returns '' when
 * no more matches are found.
 * 
 * @param name          directory name to search for
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @see f_match
 * 
 * @categories Completion_Functions, File_Functions
 */
_str dir_match(_str name,bool find_first)
{
   return file_or_dir_match(name,find_first,true,'+X ');
}
/**
 * @return  Returns next directory name which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.  Returns '' when
 * no more matches are found.
 * <p>
 * "dirnq" means "directory no quote".  
 * This function does not quote the items returned.
 * 
 * @param name          directory name to search for
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @see dir_match
 * @see fnq_match
 * 
 * @categories Completion_Functions, File_Functions
 */
_str dirnq_match(_str name,bool find_first)
{
   return file_or_dir_match(name,find_first,false,'+X ');
}

/**
 * Match only the word specified by <code>name</code>.
 * 
 * @param name          name to match
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @return <code>name</code> if <code>find_first</code> is true, '' otherwise.
 * 
 * @categories Completion_Functions
 */
_str w_match(_str name,bool find_first)
{
   if ( find_first ) {
      return(name);
   }
   return('');
}

/** 
 * @return Returns <i>buf_name</i> in a form which makes the root name more 
 * identifiable by placing the path at the end in angle braces.  For example, a 
 * <i>buf_name</i> of "c:\autoexec.bat" is translated to "autoexec.bat&lt;c:\&gt;"
 * 
 * @param name   buffer name
 * 
 * @categories Buffer_Functions
 */
_str make_buf_match(_str name)
{
   firstch := substr(name,1,1);
   if ( isdrive(substr(name,1,2)) || firstch==FILESEP || firstch==FILESEP2 ) {
      name=_strip_filename(name,'P')'<'_strip_filename(name,'N')'>';
   }
   return(name);
}

/**
 * @return Returns next buffer name which is a prefix match of name.
 * <code>find_first</code> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 *
 * @param name          buffer name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @see f_match
 * @see dir_match
 * 
 * @categories Buffer_Functions, Completion_Functions
 */
_str b_match(_str name,bool find_first)
{
   name=make_buf_match(name);
   _str match=buf_match('',find_first? 1:0);
   for (;;) {
      if ( rc ) {
         break;
      }
      if ( match!='' ) {
         match=make_buf_match(match);
         if ( _file_eq(substr(match,1,length(name)),name) ) {
            break;
         }
      }
      match=buf_match('',0);
   }
   return(match);
}

/**
 * @return Returns next file name in the current project which is a
 *         prefix match of name.  Returns '' when no more matches
 *         are found.
 *
 * @param name          file name prefix to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @see f_match
 * @see dir_match 
 * @see wkspace_file_match 
 * 
 * @categories Buffer_Functions, Completion_Functions
 */
_str project_file_match(_str name,bool find_first)
{
   // no project file, so instead do a file match in
   // the current working directory as the next-best thing
   if (_workspace_filename=='' || _project_name=='') {
      return f_match(name, find_first);
   }

   // list of file name matches found
   static _str matches[];
   static int k;

   // find all the matches on find first, then pass them
   // out on subsequent find-next operations 
   if (find_first) {
      // re-initialize match list and traversal index
      matches._makeempty();
      k=0;

      // get it's file list as a Slick-C array (this is cached for speed)
      _str fileList[];
      status := _getProjectFiles(_workspace_filename, _project_name, fileList, 0);
      if (status) {
         return '';
      }
   
      // look for file name matches within the list
      KeyPendingCount := 0;
      foreach (auto filename in fileList) {
         ++KeyPendingCount;
         if( (KeyPendingCount%100)==0 && _IsKeyPending() ) {
            return '';
         }
         filename = _strip_filename(filename, 'P');
         if (_file_eq(substr(filename,1,length(name)), name))  {
            matches[matches._length()] = filename;
         }
      }
   }

   // more matches to hand out?
   if (k < matches._length()) {
      return matches[k++];
   }

   // that's all folks
   return '';
}
static int gKeyPendingCount=0;
/**
 * @return Returns next file name in the current workspace which is
 *         a prefix match of name.  Returns '' when no more matches
 *         are found.
 *
 * @param name          file name prefix to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @see f_match
 * @see dir_match 
 * @see wkspace_file_match 
 * 
 * @categories Buffer_Functions, Completion_Functions
 */
_str wkspace_file_match(_str name,bool find_first)
{
   // no workspace file, so instead do a file match in
   // the current working directory as the next-best thing
   if (_workspace_filename=='') {
      return f_match(name, find_first);
   }

   // list of file name matches found
   static _str matches[];
   static int k;

   // find all the matches on find first, then pass them
   // out on subsequent find-next operations 
   if (find_first) {
      // re-initialize match list and traversal index
      matches._makeempty();
      k=0;

      // retrieve the names of the projects in the current workspace
      ++gKeyPendingCount;
      if( (gKeyPendingCount%100)==0 && _IsKeyPending() ) {
         return '';
      }

      status := _getProjectFilesInWorkspace(_workspace_filename, auto ProjectNames);
      if (status) return '';
      // for each project
      workspacePath := _strip_filename(_workspace_filename,'N');
      if (def_filematch_case_insensitive) {
         foreach (auto p in ProjectNames) {
            // search for matching file names
            _projectMatchFile(_workspace_filename, p, name, matches,true,def_filematch_case_insensitive);
            // also check if the project anme matches the prefix
            if (strieq(name, substr(_strip_filename(p,"P"),1,length(name)))) {
               matches[matches._length()] = absolute(p,_strip_filename(_workspace_filename, 'N'));
            }
         }
         // finally, check if the current workspace name matches the prefix
         if (strieq(name, substr(_strip_filename(_workspace_filename,"P"),1,length(name)))) {
            matches[matches._length()] = _workspace_filename;
         }
      } else { 
         foreach (auto p in ProjectNames) {
            // search for matching file names
            _projectMatchFile(_workspace_filename, p, name, matches,true,false);
            // also check if the project anme matches the prefix
            if (_file_eq(name, substr(_strip_filename(p,"P"),1,length(name)))) {
               matches[matches._length()] = absolute(p,_strip_filename(_workspace_filename, 'N'));
            }
         }
         // finally, check if the current workspace name matches the prefix
         if (_file_eq(name, substr(_strip_filename(_workspace_filename,"P"),1,length(name)))) {
            matches[matches._length()] = _workspace_filename;
         }
      }
   }

   // more matches to hand out?
   if (k < matches._length()) {
      return matches[k++];
   }

   // that's all folks
   return '';
}

/**
 * @return Returns next project file name in the current workspace which is
 *         a prefix match of name.  Returns '' when no more matches
 *         are found.
 *
 * @param name          project file name prefix to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @see f_match
 * @see dir_match 
 * @see wkspace_file_match 
 * 
 * @categories Buffer_Functions, Completion_Functions
 */
_str project_filename_match(_str name,bool find_first)
{
   // no workspace file, so instead do a file match in
   // the current working directory as the next-best thing
   if (_workspace_filename=='') {
      return "";
   }

   // list of file name matches found
   static _str matches[];
   static int k;

   // find all the matches on find first, then pass them
   // out on subsequent find-next operations 
   if (find_first) {
      // re-initialize match list and traversal index
      matches._makeempty();
      k=0;

      status := _getProjectFilesInWorkspace(_workspace_filename, auto ProjectNames);
      if (status) return '';

      // for each project
      workspacePath := _strip_filename(_workspace_filename,'N');
      foreach (auto p in ProjectNames) {
         // check if the project anme matches the prefix
         if (_file_eq(name, substr(_strip_filename(p,"P"),1,length(name)))) {
            matches :+= absolute(p,_strip_filename(_workspace_filename, 'N'));
         }
      }
   }

   // more matches to hand out?
   if (k < matches._length()) {
      return matches[k++];
   }

   // that's all folks
   return '';
}

/**
 * @return Returns next or first command name which is a
 * prefix match of <i>name</i>.  
 * <i>find_first</i> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 *
 * @param name          command name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */
_str c_match(_str name,int find_first)
{
   static int pass;
   if (find_first==1) {
      pass=0;
   }

   result := "";
   if (pass) {
      result=name_name(cname_match('ispf-'name,find_first!=0,COMMAND_TYPE,def_command_completion_style));
      if (result:=='') {
         return(result);
      }
      return(substr(result,6));
   }
   result=name_name(cname_match(name,find_first!=0,COMMAND_TYPE,def_command_completion_style));
   if (result:!='') {
      return(result);
   }
   if (pass!=0 || def_keys!='ispf-keys') {
      return('');
   }
   pass=1;
   return(c_match(name,3));
}
/*
   This is here just in case some code calls this function. When COMMANDLINE_ARG
   is used, the command line functions for completion for space, ?, and Tab are 
   supposed to be called as if you cursor is on the command line. This allows
   for better space key handling so that external programs can be called.
*/
_str cl_match(_str name,int find_first)
{      
   return(c_match(name,find_first));
}

/**
 * @see help
 */
_str c_help(_str line)
{
   return(help(line));
}

/**
 * @return Returns next Slick-C&reg; object name which is a prefix match of name.
 * <code>find_first</code> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 *
 * @param name          object name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @see c_match
 * 
 * @categories Completion_Functions
 */
_str _object_match(_str name,bool find_first)
{
   int index=name_match(name,(int)find_first,OBJECT_TYPE);
   if (!index) {
      return('');
   }
   return(translate(name_name(index),'_','-'));
}

/**
 * @return  Returns the name of the form matching the prefix <i>name_prefix</i>.
 * If a match is not found, '' is returned.
 * Specify <i>find_first</i> == 1, to start from the first form and 
 * 0 to find the next match.
 * This function scans the names table for forms and not instances of
 * forms already displayed.
 * 
 * @param name          form name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Form_Functions
 */
_str _form_match(_str name,bool find_first)
{
   index := 0;
   for (;;) {
      index=name_match(name,(int)find_first,OBJECT_TYPE);
      if (!index) {
         return('');
      }
      if (type2oi(name_type(index))==OI_FORM) {
         break;
      }
      find_first=false;
   }
   return(translate(name_name(index),'_','-'));
}

/** 
 * @return Returns next menu name in names table which is a prefix match of 
 * <i>name</i>.  <i>find_first</i> must be non-zero to initialize matching.  
 * Returns '' when no more matches are found.
 * 
 * @param name          menu name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 * 
 * @categories Completion_Functions, Menu_Functions
 */
_str _menu_match(_str name,bool find_first)
{
   index := 0;
   for (;;) {
      index=name_match(name,(int)find_first,OBJECT_TYPE);
      if (!index) {
         return('');
      }
      if (type2oi(name_type(index))==OI_MENU) {
         // we do not want to return any hidden original menus
         objectName := translate(name_name(index),'_','-');
         if (!endsWith(objectName, SE_ORIG_MENU_SUFFIX)) break;
      }
      find_first=false;
   }
   return(translate(name_name(index),'_','-'));
}

/**
 * @return Returns next already loaded picture name which is a prefix match of 
 * <i>name</i>.  <i>find_first</i> must be non-zero to initialize 
 * matching.  Returns '' when no more matches are found.
 * 
 * @param name          picture name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */ 
_str _pic_match(_str name, bool find_first)
{
   return(name_name(name_match(name,(int)find_first,PICTURE_TYPE)));
}

/**
 * @return Returns next mode name which is a prefix match of 
 * <i>name</i>.  <i>find_first</i> must be non-zero to initialize 
 * matching.  Returns '' when no more matches are found.
 * 
 * @param name          mode name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */
_str mode_match(_str name,bool find_first)
{
   static _str results[];
   static int index;
   if (find_first) {
      _str langid_array[];
      _GetAllLangIds(langid_array);
      for (i:=0;i<langid_array._length();++i) {
         modename:=_LangGetModeName(langid_array[i]);
         if (modename!='') {
            results[results._length()]=modename;
         }
      }
      index=-1;
   }
   for (;;) {
      ++index;
      if (index>=results._length()) {
         return '';
      }
      modename:=results[index];
      if (_ModenameEQ(substr(modename,1,length(name)),name)) {
         return(modename);
      }
   }
   return('');
}

/** 
 * @return Returns the name of the user recorded macro matching the prefix 
 * <i>name_prefix</i>.  If a match is not found, '' is returned.  If 
 * <i>find_first</i> is non-zero, matching starts from the first user recorded 
 * macro.  Otherwise matching starts after the previous match.
 * 
 * @param name          macro name to match
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @categories Completion_Functions, Macro_Programming_Functions
 */
_str k_match(_str name, bool find_first)
{
   int index=cname_match(name,find_first,COMMAND_TYPE);
   for (;;) {
      if (!index) return('');
      typeless flags='';
      parse name_info(index) with ',' flags;
      if (flags!='' && (flags &VSARG2_MACRO)) {
         return(name_name(index));
      }
      index=cname_match(name,false,COMMAND_TYPE);
   }
}

static int cignorecase_type;
/**
 * Generic function for matching Slick-C&reg; command names.
 * <p>
 * @return Returns the command name matching the prefix 
 * <i>name_prefix</i>.  If a match is not found, '' is returned.  If 
 * <i>find_first</i> is non-zero, matching starts from the first command.
 * Otherwise matching starts after the previous match.
 * <p>
 * If it does not find a match on it's first attempt, it will
 * look for case-insensitive matches.
 * 
 * @param name          command name to match
 * @param find_first    'true' to find first, 'false' to find next
 */
int cname_match(_str name, bool find_first, int kind,bool doPrefixMatch=true)
{
   if (find_first) cignorecase_type=0;
   int index=cname_match2(name,find_first,kind|cignorecase_type,doPrefixMatch);
   if (!index) {
      cignorecase_type=IGNORECASE_TYPE;
      index=cname_match2(name,find_first,kind|cignorecase_type,doPrefixMatch);
   }
   return(index);
}
/**
 * Generic function for matching Slick-C&reg; command names.
 * <p>
 * @return Returns the command name matching the prefix 
 * <i>name_prefix</i>.  If a match is not found, '' is returned.  If 
 * <i>find_first</i> is non-zero, matching starts from the first command.
 * Otherwise matching starts after the previous match.
 * 
 * @param name          command name to match
 * @param find_first    'true' to find first, 'false' to find next
 */
static int cname_match2(_str name, bool find_first, int kind,bool doPrefixMatch)
{
   if (doPrefixMatch) {
      int index=name_match(name,(int)find_first,kind);
      for (;;) {
         // no more matches
         if (!index) {
            return index;
         }
         // do not check index_callable() for non-commands
         if (!(name_type(index) & COMMAND_TYPE)) {
            return index;
         }
         // check if this command is allowed in this version
         if (!_isProEdition()) {
            typeless flags=0;
            parse name_info(index) with ',' flags;
            if (flags!='' && (flags & VSARG2_REQUIRES_PRO_EDITION)) {
               index=name_match(name,0,kind);
               continue;
            }
         }
         if (!_isProEdition() && !_isStandardEdition()) {
            typeless flags=0;
            parse name_info(index) with ',' flags;
            if (flags!='' && (flags & VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)) {
               index=name_match(name,0,kind);
               continue;
            }
         }
         // verify that command is callable
         if ( index_callable(index) ) {
            return(index);
         }
         // next please
         index=name_match(name,0,kind);
      }
   }
   int index=name_match('',(int)find_first,kind);
   _str ignore_case=(kind&IGNORECASE_TYPE)?'I':'E';
   for (;;) {
      // no more matches
      if (!index) {
         return index;
      }
      // do not check index_callable() for non-commands
      if (!(name_type(index) & COMMAND_TYPE)) {
         //say('??kind='dec2hex(kind)' n='name_name(index));
         return index;
      }
      if (!pos(name,name_name(index),1,ignore_case)) {
         index=name_match('',0,kind);
         continue;
      }
      // check if this command is allowed in this version
      if (!_haveProMacros()) {
         typeless flags=0;
         parse name_info(index) with ',' flags;
         if (flags!='' && (flags & VSARG2_REQUIRES_PRO_EDITION)) {
            index=name_match('',0,kind);
            continue;
         }
         if (!_isProEdition() && !_isStandardEdition()) {
            flags=0;
            parse name_info(index) with ',' flags;
            if (flags!='' && (flags & VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)) {
               index=name_match(name,0,kind);
               continue;
            }
         }
      }
      // verify that command is callable
      if ( index_callable(index) ) {
         //say('kind='kind' n='name_name(index));
         return(index);
      }
      // next please
      index=name_match('',0,kind);
   }

}

/** 
 * @return Returns next Slick-C&reg; module name which is a prefix match of 
 * <i>name</i>.  <i>find_first</i> must be non-zero to initialize matching.  
 * Returns '' when no more matches are found.  Only loaded macro modules are 
 * listed.
 * 
 * @param name          module name to match
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @categories Completion_Functions
 * 
 */
_str m_match(_str name, bool find_first)
{
   return(name_name(name_match(name,(int)find_first,MODULE_TYPE)));
}

/**
 * @return  Returns next DLL module name in the names table which is a
 * prefix match of <i>name</i>.  <i>find_first</i> must be non-zero to
 * initialize matching.  Returns "" when no more matches are found.
 * 
 * @param name          DLL name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */
_str _dll_match(_str name, bool find_first)
{
   return(name_name(name_match(name,(int)find_first,DLLMODULE_TYPE)));
}

/**
 * @return Returns next global Slick-C&reg; variable name which is a prefix match
 * of <i>name</i>.  <i>find_first</i> must be non-zero to initialize 
 * matching.  Returns '' when no more matches are found.
 * 
 * @param name          variable name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */ 
_str v_match(_str name, bool find_first)
{
   return(translate(name_name(name_match(name,(int)find_first,VAR_TYPE|BUFFER_TYPE)),'_','-'));
}

/**
 * @return Returns next procedure or command name which is a prefix match of 
 * <i>name</i>.  <i>find_first</i> must be non-zero to initialize 
 * matching.  Returns '' when no more matches are found.
 * 
 * @param name          name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */ 
_str pc_match(_str name, bool find_first)
{
   return(name_name(cname_match(name,find_first,PROC_TYPE|COMMAND_TYPE)));
}

/**
 * @see help
 */
_str pc_help(_str line)
{
   return(help(line));
}

/** 
 * @return Returns next Slick-C&reg; tag name which is a prefix match of 
 * <i>name</i>.  <i>find_first</i> must be non-zero to initialize matching.  
 * Returns "" when no more matches are found.  This function excludes 
 * import and include statements.
 * 
 * @param name          tag name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */
_str mt_match(_str name,bool find_first)
{
   // use the names table to complete proc names or variable names
   if (!_haveContextTagging()) {
      static bool match_procs;
      if (find_first) match_procs=true;
      if (match_procs) {
         proc_name := pc_match(name,find_first);
         if (proc_name != "") return proc_name;
      }
      match_procs=false;
      return v_match(name,find_first);
   }
   // use Slick-C tag database
   if (find_first && find_first!=2) {
      orig_id := p_window_id;
      status := _e_MaybeBuildTagFile(auto tfindex,true);
      p_window_id = orig_id;
      if (status) {
         messageNwait("Error building Slick-C"VSREGISTEREDTM" tag file");
         return("");
      }
   }
   loop {
      tag_name := tag_match(name,(int)find_first,"e");
      if (tag_name == "") return "";
      tag_decompose_tag_browse_info(tag_name, auto cm);
      if (cm.type_name == "include" || cm.type_name == "import") {
         find_first=false;
         continue;
      }
      return tag_name;
   }
}

/**
 * @see help
 */
_str mt_help(_str line)
{
   return(help(line));
}

/**
 * @return Returns next procedure, command name, or builtin which is a
 * prefix match of  <i>name</i>.  <i>find_first</i> must be non-zero to
 * initialize matching.  Returns '' when no more matches are found.
 * 
 * @param name          name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */ 
_str pcbt_match(_str name, bool find_first)
{
   return(name_eq_match(name,find_first,PCB_TYPES));
}

/**
 * @see help
 */
_str h_help(_str line)
{
   return(help(line));
}

/**
 * @return Returns help item or help topic which is a
 * prefix match of  <i>name</i>.  <i>find_first</i> must be non-zero to
 * initialize matching.  Returns '' when no more matches are found.
 * 
 * @param name          help item to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */ 
_str hNt_match(_str name, bool find_first)
{
   int index=cname_match(name,find_first,HELP_TYPE);
   if ( index ) {
     return(field(name_name(index),16) " "eq_value2name(name_type(index)& ~INFO_TYPE,HELP_TYPES));
   }
   return('');
}

/**
 * @see help
 */
_str hNt_help(_str line)
{
   return(help(line));
}

/**
 * @return Returns help type which is a prefix match of  <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 * 
 * @param name          name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */ 
_str ht_match(_str name,bool find_first)
{
   return(name_eq_match(name,find_first,HELP_TYPES));
}

/**
 * @return Returns help class which is a prefix match of  <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 * 
 * @param name          name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */ 
_str hc_match(_str name,bool find_first)
{
   return(name_eq_match(name,find_first,HELP_CLASSES));

}

/**
 * @return Returns the next item matching the given string.
 * Generic function for matching several different name types.
 * <i>find_first</i> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 * 
 * @param prefix_name   name to match
 * @param find_first    'true' to find first, 'false' to find next
 * @param string        
 */
_str name_eq_match(_str prefix_name, bool find_first, _str string)
{
   static _str eq_string;
   if ( find_first ) {
     eq_string=lowcase(string);
   }
   name := "";
   prefix_name=lowcase(prefix_name);
   for (;;) {
     if ( eq_string=='' ) { return(''); }
     parse eq_string with name '=' . eq_string;
     if ( substr(name,1,length(prefix_name))==prefix_name ) {
       return(lowcase(strip(name)));
     }
   }

}

/**
 * @return  Returns next environment variable name which is a prefix
 * match of <i>name</i>.  <i>find_first</i> must be non-zero to initialize
 * matching.  Returns '' when no more matches are found.
 * 
 * @param prefix_name   name to match
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @categories Completion_Functions
 */
_str e_match(_str name,bool find_first)
{
   return(env_match(env_case(name),(int)find_first));
}

static void list_cmdline_history_matches(_str history_prefix, _str prefix, _str (&words)[])
{
   // open a tempview of the command history buffer
   orig_view_id := 0;
   get_window_id(orig_view_id);
   activate_window(VSWID_RETRIEVE);

   // start from the beginning
   bool duplicates:[];
   save_pos(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   top();
   _begin_line();
   for (;;) {
      if (search("^":+_escape_re_chars(history_prefix:+prefix),'@re>') < 0) {
         break;
      }
      get_line(auto line);
      if (duplicates._indexin(line)) {
         continue;
      }
      line = substr(line,glast_list_matches_column);
      words[words._length()]=substr(line, length(history_prefix)+1);
      duplicates:[line]=true;
   }

   // clean up
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   p_window_id=orig_view_id;
   return;
}

/**
 * @return
 * Decompose an argument completion string into it's parts.
 * Return the names table index of the completion function
 * corresponding to the given name prefix.
 * 
 * @param name_prefix      name prefix to find
 * @param match_flags      (output) set to completion flags (*_MATCH)
 * @param multi_select     (output) multiple arguments?
 * @param last_arg2        (outout) last argument?
 */
static int match_prefix2index(_str name_prefix,
                              int &match_flags,
                              int &multi_select, 
                              bool &last_arg2)
{
   last_arg2=false;
   multi_select=0;
   match_flags=0;
   if ( pos('*',name_prefix) ) {
      multi_select=1;
      name_prefix=stranslate(name_prefix,'','*');
   }
   if ( pos('!',name_prefix) ) {
      name_prefix=stranslate(name_prefix,'','!');
      last_arg2=true;
   }
   typeless tmp_match_flags = '';
   parse name_prefix with name_prefix ':' tmp_match_flags;
   if (tmp_match_flags != "" && isinteger(tmp_match_flags)) {
      match_flags = (int)tmp_match_flags;
   }

   index := find_index(name_prefix'-match',PROC_TYPE|COMMAND_TYPE);
   if ( ! index_callable(index) ) {
     _message_box(nls("Match function '%s' not found",name_prefix));
     return(0);
   }
   return(index);

}

/**
 * Move all lines in starting with ' _' to the bottom.
 * <p>
 * The current object needs to be an editor control or list box.
 */
void _UnderScoresToBottom()
{
   //place the under scores at the bottom.
   top();
   typeless mark=_alloc_selection();
   if (mark>=0) {
      status := search('^ _','r@');
      if (!status) {
         _select_line(mark);
         status=search('^ ~_','ri@');
         if (status) {
            bottom();
         } else {
            up();
         }
         _select_line(mark);
         bottom();
         _move_to_cursor(mark);
      }
      _free_selection(mark);
   }
}

/**
 * Prompt if they should continue looking for matches or stop now.
 * 
 * @param prefix     item being matched
 * @param count      number of items found so far
 * 
 * @return IDYES, IDNO, or IDCANCEL
 */
static int prompt_continue_matching(_str prefix, int count)
{
   last_chance := (count >= def_max_completion_items*MAX_COMPLETION_ITEMS_REPROMPT_FACTOR)? " (last chance to stop long search)" : "";
   return _message_box(nls('Found %s1 items with prefix "%s2"' :+ last_chance :+ '.  Continue searching?', count, prefix), '', MB_YESNO|MB_ICONQUESTION);
}

/**
 * List matches
 * 
 * @param title            title of popup-window
 * @param flags            selection list flags SL_*
 * @param buttons          buttons to add to list
 * @param help_item        help item
 * @param font             font to use for list
 * @param callback_name    selection list callback name
 * @param retrieve_name    dialog retrieval name
 * @param completion       completion argument
 * @param min_list_width   minimum list width
 * @param fast_complete    use fast completion algorithm
 * @param initial_value    initial value for selection list
 * 
 * @return Return the value of the selected item.
 * 
 * @see list_matches
 */
_str _list_matches2(_str title,
                    int flags,
                    _str buttons,
                    _str help_item,
                    _str font,
                    typeless callback_name,
                    typeless retrieve_name,
                    _str completion,
                    int min_list_width=0,
                    typeless fast_complete='',
                    _str initial_value=''
                    )
{
   int was_recording=_macro();
   _macro_delete_line();
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id=='') return(1);
   if ( title=='' ) {
     title=nls('Open Form');
   }
   name_prefix := "";
   typeless match_flags='';
   if (fast_complete!='') {
      _insert_name_list(fast_complete);
   } else {
      parse completion with name_prefix ':' match_flags ;
      //match_fun_index=match_prefix2index(completion,match_flags,multi_select, last_arg2)
      match_fun_index := find_index(name_prefix'_match',PROC_TYPE);
      _str match_name=call_index('',1,match_fun_index);
      num_matches := 0;
      for (;;) {
         if (match_name=='') {
            break;
         }
         if (++num_matches==def_max_completion_items || num_matches==def_max_completion_items*MAX_COMPLETION_ITEMS_REPROMPT_FACTOR) {
            int status=prompt_continue_matching('',num_matches);
            if (status==IDNO) {
               break;
            }
         }
         _lbadd_item(match_name);
         match_name=call_index('',0,match_fun_index);
      }
      if (match_flags==''){
         match_flags=0;
      }
      if ( match_flags & TERMINATE_MATCH ) {
         call_index('',2,match_fun_index);
      }
      top();
   }
   activate_window(orig_view_id);
   typeless result=show('_sellist_form -hidden -reinit',
            title,
            flags,
            temp_view_id,
            buttons,
            help_item, // help item name
            '',              // font
            callback_name,   // Call back function
            '',              // Item separator for list_data
            retrieve_name,   // Retrieve form name
            completion,      // Combo box. Completion property value.
            min_list_width,  // minimum list width
            initial_value
           );
   if (result<0) return(result);
   p_window_id=result;
   if (flags&SL_MATCHCASE) {
      p_window_id=_control _sellist;
      _lbsort('e');
      _UnderScoresToBottom();
      p_window_id=result;
   } else {
      _sellist._lbsort('i');
   }
   _sellist._lbtop();
   _sellistcombo._set_sel(1,length(_sellistcombo.p_text)+1);
   if (flags & SL_SELECTPREFIXMATCH) {
      _sellistcombo.call_event(CHANGE_SELECTED,_sellistcombo,ON_CHANGE,'');
   }
   // Add this so the dialog does not flicker when it comes up
   p_active_form.p_ShowModal=true;
   p_active_form.p_visible=true;
   result=_modal_wait(result);
   if (result=='') {
      activate_window(orig_view_id);
      return('');
   }
   activate_window(orig_view_id);
   _macro('m',was_recording);
   _macro_call(retrieve_name,result);
   return(result);
}

   static int help_proc_index;

/** 
 * Creates a pop-up selection list of items that are a prefix match of name.  
 * Returns line selected or '' to indicate that nothing was selected.  
 * <i>match_fun_name </i>is a prefix name or index of a completion function.   
 * "_match" is appended to <i>match_fun_name</i> to determine the complete 
 * function name.  The following are completion functions tag_match, b_match, 
 * c_match, _pic_match, _form_match, mt_match, e_match, f_match, _menu_match, 
 * m_match, pcb_match, pc_match, and v_match.  New completion functions may be 
 * defined (see comment in module "complete.e" for more information).  The 
 * selection list window title is set to <i>title</i> if given.    The 
 * <i>help_fun_name</i> argument is the name of a help procedure.
 * 
 * @param name
 *          Prefix string to match
 * @param match_fun_index
 *          One ????_ARG constants defined in slick.sh
 *          OR index of find first/next function
 * @param title
 *          Title of popup-window
 * @param multi_select
 *          If Not '', allow multiple selections
 *          This argument is here for backward compatibility
 * @param help_proc
 *          Name of help function to call
 * @param auto_select_if_one_match
 *          Auto select if 1 match
 * 
 * @return If <i>allow_multi_select</i> is not '', multiple lines in the 
 * selection list may be selected with the space- bar key.   <b>list_matches</b> 
 * returns each selected line separated with a space or if there are too many, a 
 * list file specification is returned.  A list file specification starts with 
 * the character '@'.  If <i>allow_multi_selection</i> is not given or '', line 
 * selected is returned.  '' is returned to indicate user pressed cancel key, 
 * list is null, or error.  On error message is displayed and user is prompted 
 * to press a key.
 * 
 * @example
 * <pre>
 *        file_name=list_matches('','f');
 *        if (file_name=='' ) {
 *             return(1)  // Cancel key pressed or list null.
 *        }
 *        message('file_name='file_name);
 * </pre>
 * 
 * @categories Completion_Functions
 */
_str list_matches(_str name,
                  typeless match_fun_index,
                  _str title='',
                  int multi_select=0,
                  _str help_proc='',
                  bool auto_select_if_one_match=false,
                  bool doAddToAutoCompletion=false,
                  typeless &words=null,
                  bool doAddToArgumentCompletion=false,
                  bool &case_sensitive_matching=false)
{
   cmdline_active := (_cmdline==p_window_id);
   last_arg2 := false;
   match_flags := 0;
   if ( ! isinteger(match_fun_index) ) {
      match_fun_index=match_prefix2index(match_fun_index,match_flags,multi_select,last_arg2);
      if ( ! match_fun_index ) {
         return('');
      }
   }

   // is argument completion disabled for UNC Paths?
   if ((doAddToArgumentCompletion || doAddToAutoCompletion) && 
       !(def_argument_completion_options & VSARGUMENT_COMPLETION_UNC_PATHS) &&
       substr(name,1,2)==FILESEP:+FILESEP) {
      return('');
   }

   if (match_flags & FILE_CASE_MATCH) {
      name=_unix_expansion(name);
      if (_fpos_case=='') {
         // When removing duplicates, must do it case sensitive.
         case_sensitive_matching=true;
      }
   }

   if (doAddToArgumentCompletion && name=='') {
      return('');
   }
   if (doAddToArgumentCompletion && gautocomplete_ContinueToFail) {
      if (gautocomplete_MatchFunIndex==match_fun_index) {
         typeless end_time=(typeless)_time('b');
         if (end_time>gautocomplete_StartTime) {
            if (end_time-gautocomplete_StartTime<gautocomplete_ContinueToFail) {
               return '';
            }
         }
      }
   }
   gautocomplete_ContinueToFail=0;

   if ( ! multi_select ) {
      multi_select=0;
   } else {
      multi_select=SL_ALLOWMULTISELECT|SL_SELECTALL;
   }

   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if ( orig_view_id=='') {
      return('');
   }

   // multi_select not support yet for dialog boxes because
   // of interpreter string length limit.
   if (multi_select && orig_view_id!=_cmdline) {
      multi_select=0;
   }

   if ( name=='' ) message(nls('Building selection list...'));
   gautocomplete_StartTime=_time('b');
   _str match_name=call_index(name,1,match_fun_index);
   if ( match_name=='' ) {
      if ( match_flags & TERMINATE_MATCH ) {
         call_index('',2,match_fun_index);
      }
      _delete_temp_view(temp_view_id);
      if ( name=='' ) clear_message();
      activate_window(orig_view_id);
      return'';
   }

   if ( title=="" ) {
      title=nls("Select a Command Parameter");
   }

   _str buttons=nls('&Select'); //  ,&Print')  Can't print just yet.
   help_proc_index=0;
   if ( help_proc=='' ) {  /* help function given? */
      help_proc_index=find_index(help_proc,PROC_TYPE);
   } else {
      int i=pos('-',name_name(match_fun_index));
      if ( i ) {
         help_proc=substr(name_name(match_fun_index),1,i)'help';
         help_proc_index=find_index(help_proc,PROC_TYPE);
      }
   }

   if ( help_proc_index ) {
      if ( !index_callable(help_proc_index) ) {
         help_proc_index=0;
      }
   }
   bool abs_hashtab:[];
   bool remove_dups_rel_abs=(match_flags & REMOVE_DUPS_REL_ABS_MATCH)?true:false;

   num_matches := 0;
   width := 0;
   KeyPendingCount := 0;
   for (;;) {
     if ( match_name=='' ) { break; }
     if (doAddToAutoCompletion && ((typeless)_time('b')-gautocomplete_StartTime)>=def_fileio_timeout && (match_flags & DISKIO_TIMEOUT_MATCH)) {
        gautocomplete_ContinueToFail=def_fileio_continue_to_timeout;
        gautocomplete_MatchFunIndex=match_fun_index;
        break;
     }
     if (doAddToAutoCompletion) {
        // test for a keypress
        ++KeyPendingCount;
        if( (KeyPendingCount%100)==0 && _IsKeyPending() ) {
           break;
        }
        // check for argument completion limit
        if (++num_matches >= def_argument_completion_maximum) {
           break;
        }
     } else if (++num_matches==def_max_completion_items || num_matches==def_max_completion_items*MAX_COMPLETION_ITEMS_REPROMPT_FACTOR) {
        int status=prompt_continue_matching(name,num_matches);
        if (status==IDNO) {
           break;
        }
     }
     if (remove_dups_rel_abs) {
        name2:=strip(match_name,'B','"');
        if (_isRelative(name2)) {
           name2=absolute(name2);
        }
        key:=_file_case(name2);
        if (abs_hashtab._indexin(key)) {
           match_name=call_index(name2,0,match_fun_index);
           continue;
        }
        abs_hashtab:[key]=true;
     }
     insert_line(' 'match_name);
     if ( length(match_name)>width ) { width=length(match_name); }
     match_name=call_index(name,0,match_fun_index);
   }

   if ( match_flags & TERMINATE_MATCH ) {
      call_index('',2,match_fun_index);
   }

   top(); /* get rid of the blank line */
   if ( ! (match_flags & NO_SORT_MATCH) &&
        !((SMALLSORT_MATCH & match_flags) && p_Noflines>500)) {
      case_sense := 'i';
      if (match_flags & FILE_CASE_MATCH) {
         case_sense=_fpos_case;
      }
      sort_buffer(case_sense);
   }

   if ( match_flags & REMOVE_DUPS_MATCH ) {
      _remove_duplicates();
   }
   clear_message();

   result := "";
   get_line(result);
   if (doAddToAutoCompletion) {
      /*if (p_Noflines==1 && name==result) {
         _delete_temp_view(temp_view_id);
      } else {*/
         activate_window(temp_view_id);
         top();up();
         _str initialPrefix=name;
         if (substr(initialPrefix,1,1)=='"') {
            initialPrefix=substr(initialPrefix,2);
         }
         initialPrefix=_strip_filename(initialPrefix,'n');
         while(!down()) {
            get_line(auto line);line=strip(line,'L');
            isDirectory := _last_char(line)==FILESEP;
            if (isDirectory) {
               line=substr(line,1,length(line)-1);
            }
            _str prefix;
            if (substr(line,1,1)=='"') {
               prefix='"'initialPrefix;
            } else {
               prefix=initialPrefix;
            }
            displayText := substr(line,length(prefix)+1);
            if (displayText=='.' || displayText=='..') {
               continue;
            }
            if (doAddToArgumentCompletion) {
               words[words._length()] = line;
            } else {
               AutoCompleteAddResult(words, 
                                     AUTO_COMPLETE_FILES_PRIORITY,
                                     displayText,
                                     _autocomplete_process,
                                     ((isDirectory)?'Directory ':'File '):+line,
                                     null,
                                     (_fpos_case=='I')? false:true,
                                     (isDirectory)? _pic_fldclos:_pic_file);
            }
         }
         _delete_temp_view(temp_view_id);
      //}
   } else if ( p_Noflines==1 && (auto_select_if_one_match ||
       ((match_flags&AUTO_DIR_MATCH) && _last_char(result):==FILESEP))  ) {
      _delete_temp_view(temp_view_id);
   } else {
      activate_window(orig_view_id);
      orig_wid := p_window_id;
      typeless wid=show('_sellist_form -new -reinit',
                  title,
                  SL_VIEWID|SL_SELECTCLINE|SL_HELPCALLBACK|SL_SIZABLE|multi_select,
                  temp_view_id,
                  buttons,
                  (help_proc_index)?'1':'',  // help item
                  '',                   // font
                  clist_fall_through  // Call back function
                 );
      if (cmdline_active) {
         _cmdline.p_visible=true;
      }
      result=_modal_wait(wid);
      // We will assume that the form is edited if '' is returned.
      // We want the edited form to be the active window so
      // we will not change the active window.
      if (result!='' && _iswindow_valid(orig_wid)) {
         p_window_id=orig_wid;
      }
   }

   activate_window(orig_view_id);
   _set_focus();
   _arg_complete=1;

   if ( (!multi_select || substr(result,1,1)!='@') &&
      ! (match_flags & TERMINATE_MATCH) ) {
      /* Can't handle completion function that require third call. */
      /* This means that I must assume that all arguments to these */
      /* completion functions require no more typing. */
      /* Not @$list.slk case */
      _str line=result;
      for (;;) {
         _str word=parse_file(line);
         if ( word=='' ) {
            break;
         }
         match_name=call_index(word,1,match_fun_index);
#if 0
         if ( match_name!=word ) {
            _arg_complete=0;
         }
#endif
      }
   }
   _arg_complete=_arg_complete && last_arg2;
   return strip(result,'L');   /* remove leading space */
}

/**
 * Default callback for completion list
 * 
 * @param reason     Selection list reason SL_*
 * @param result     selected item
 * @param key        key
 * 
 * @return empty string
 */
static _str clist_fall_through(int reason, _str &result, _str key)
{
   if (reason==SL_ONUSERBUTTON) {
      switch (key) {
      case 3:
         _str text=_sellist._lbget_text();
         if (text=='') {
            return('');
         }
         call_index(text,help_proc_index);
      }
   }
   return('');
}

/**
 * Removes duplicate lines from the current buffer.
 *  
 * <p>No need to sort the buffer before calling this function. 
 *  
 * <p>If there is a selection active, this function will only 
 * remove duplicates within the selected lines.
 * 
 * @param ignore_case      'i' for case insensitive
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void remove_duplicates(_str ignore_case='') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   start_line := 0;
   last_line := -1;
   if (select_active2()) {
      if (_select_type()=='CHAR') {
         _select_type("","L","LINE");
      }
      _begin_select();
      start_line=p_line;
      _end_select();
      last_line=p_line;
   }
   _remove_duplicates(ignore_case,start_line,last_line,false);
}

/**
 * Removes duplicate adjacent lines from the current buffer.
 * Usually the buffer is sorted before calling this function.
 * <p>
 * If there is a selection active, this function will only
 * remove duplicates within the selected lines.
 * 
 * @param ignore_case      'i' for case insensitive
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void remove_adjacent_duplicates(_str ignore_case='') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   start_line := 0;
   last_line := -1;
   if (select_active2()) {
      if (_select_type()=='CHAR') {
         _select_type("","L","LINE");
      }
      _begin_select();
      start_line=p_line;
      _end_select();
      last_line=p_line;
   }
   _remove_duplicates(ignore_case,start_line,last_line);
}
/**
 * Removes duplicate adjacent lines from the current buffer.
 * Usually the buffer is sorted before calling this function.
 * 
 * @param ignore_case      'i' for case insensitive
 * @param start_line       starting line (inclusive)
 * @param last_line        last line (inclusive)
 * @param sorted           Indicates whether buffer is 
 *                         sorted.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
void _remove_duplicates(_str ignore_case='',int start_line=0,int last_line=-1,bool sorted=true)
{
   // if this is a list box, then use the more effecient builtin method
   listbox_object := (p_object == OI_LIST_BOX);
   if (listbox_object) {
      _lbremove_duplicates(ignore_case, start_line, last_line-start_line);
      return;
   }

   // convert case argument to bool
   ignore_case=upcase(ignore_case)=='I';

   // compute the start line
   if (start_line>0) {
      p_line=start_line;
   } else {
      top();
      start_line=1;
   }

   // compute the last line
   if (last_line<0) {
      last_line=p_Noflines;
   }

   // go through the lines
   int count=last_line-start_line;
   previous_line := line := "";
   get_line(previous_line);
   if (sorted) {
      if (ignore_case) {
         // case insensitive
         for (;count-->0;) {
            down();
            get_line(line);
            if (strieq(line,previous_line)) {
               up();_delete_line();
            }
            previous_line=line;
         }
      } else {
         // case sensitive
         for (;count-->0;) {
            down();
            get_line(line);
            if ( line:==previous_line ) {
               up();_delete_line();
            }
            previous_line=line;
         }
      }
   } else {
      bool hash:[];
      if (ignore_case) {
         hash:[lowcase(previous_line)]=true;
         down();
         // case insensitive
         for (;count-->0;) {
            get_line(line);
            line=lowcase(line);
            typeless *pvalue=&hash:[lowcase(line)];
            if (pvalue->_varformat()!=VF_EMPTY) {
               _delete_line();
            } else {
               *pvalue=1;
               down();
            }
         }
      } else {
         hash:[previous_line]=true;
         down();
         // case sensitive
         for (;count-->0;) {
            get_line(line);
            typeless *pvalue=&hash:[line];
            if (pvalue->_varformat()!=VF_EMPTY) {
               _delete_line();
            } else {
               *pvalue=1;
               down();
            }
         }
      }
   }
}

/**
 * Expand the word at the given column according to the specified
 * completion rules.
 * 
 * @param line             original line
 * @param word             original word
 * @param start_word_col   column that 'word' starts on
 * @param fun_name_prefix  completion function prefix
 * @param command_case     command case option?
 */
static void expand_word(_str line,
                        _str word,
                        int start_word_col,
                        _str fun_name_prefix,
                        bool command_case,
                        bool one_argument_text_box)
{
   match_flags := 0;
   multi_select := 0;
   last_arg2 := false;
   int match_fun_index=match_prefix2index(fun_name_prefix,match_flags,multi_select, last_arg2);
   if ( ! match_fun_index ) {
      return;
   }
   int is_file_match_fun=(match_flags & FILE_CASE_MATCH);
   if ((match_flags & APPEND_SPACE_MATCH) || (is_file_match_fun && iswildcard(word))) {
      keyin(' ');
      return;
   }
   strip_word := strip(word);
   if ( command_case ) {
      strip_word=name_case(strip_word);
   }

   old_wid := p_window_id;
   p_window_id=_edit_window();
   _arg_complete=1;

   if (match_flags & FILE_CASE_MATCH) {
      strip_word=_unix_expansion(strip_word);
   }
   dquote_ch := "";
   if (substr(strip_word,1,1)=='"') {
      dquote_ch='"';
      strip_word=substr(strip_word,2);
   }
   int lenp1=length(strip_word)+1;

   name := "";
   shortest_name := "";
   number_found := 0;
   exact_match := false;
   add_dquote := false;
   if ( command_case && (find_index(strip_word,COMMAND_TYPE) ||
       find_index(strip_word,COMMAND_TYPE|IGNORECASE_TYPE))) {
      name=strip_word;

   } else {
      name=call_index(strip_word,1,match_fun_index);
      ch := substr(name,1,1);
      if (ch=='"') {
         name=substr(name,2);
         add_dquote=true;
      }
      shortest_name=name;
      number_found=0;
      exact_match=false;
      if (name!='' && is_file_match_fun && iswildcard(strip_word)) {
         name=strip_word;
      }
   }


   allow_quick_break := false;
   switch (name_name(match_fun_index)) {
   case 'tag-match':
      allow_quick_break=true;
      break;
   }

   do_upcase := (match_flags & FILE_CASE_MATCH) && _fpos_case=='I';
   /* 
       Handle following case:
         "Program<Space>"
       Where have two files:
         "Program Files"
         "ProgramGroup"
       When type space, need to get a space for the above
       case.
   */ 
   NofSpaceMatches := 0;
   _str space_match;
   quote_strip_word_space := strip_word' ';
   if ( do_upcase ) {
      quote_strip_word_space=upcase(quote_strip_word_space);
   }

   // In the case of certain types of file matching, we might
   // want to just complete the longest file name, in case if
   // there are multiple file names from different directories
   // which match the word searched for
   shortest_filename := "";
   if (match_flags & FILE_CASE_MATCH) {
      shortest_filename = _strip_filename(shortest_name, 'P');
   }

   for (;;) {
      first_ch := substr(name,1,1);
      if (first_ch=='"') {
         name=substr(name,2);
         add_dquote=true;
      }

      if (do_upcase) {
         if ( strieq(name,strip_word) ) {
            shortest_name=name;
            exact_match=true;
            // Need to keep keep for NofSpaceMatches
            //break;
         }
      } else if ( name:==strip_word ) {
         shortest_name=name;
         exact_match=true;
         // Need to keep keep for NofSpaceMatches
         //break;
      }

      if ( name=='' ) break;
      number_found++;

      _str filename=name;
      if (match_flags & FILE_CASE_MATCH) {
         filename = _strip_filename(name, 'P');
      }

      _str temp=name;
      if ( length(name)<length(shortest_name) ) {
        name=shortest_name;
        shortest_name=temp;
        shortest_filename=filename;
      }

      _str tname=shortest_name;
      _str tfilename=shortest_filename;
      if ( do_upcase ) {
         tname=upcase(tname);
         tfilename=upcase(tfilename);
         name=upcase(name);
         filename=upcase(filename);
      }
      if (strieq(quote_strip_word_space,substr(name,1,length(quote_strip_word_space)))) {
         if ((match_flags & EXACT_CASE_MATCH) && !quote_strip_word_space:==substr(name,1,length(quote_strip_word_space))) {
         } else {
            space_match=temp;
            ++NofSpaceMatches;
         }
      }

      int i;
      for (i=lenp1; i<=length(shortest_name) ; ++i) {
         if ( substr(tname,i,1):!=substr(name,i,1) ) {
            shortest_name=substr(shortest_name,1,i-1);
            if (shortest_name:!="" && !_StartOfDBCS(shortest_name,length(shortest_name))) {
                shortest_name=substr(shortest_name,1,length(shortest_name)-1);
            }
            break;
         }
      }

      // Find the alternate completion, which is just the name of the file.
      if (match_flags & FILE_CASE_MATCH) {
         for (i=lenp1; i<=length(shortest_filename) ; ++i) {
            if ( substr(tfilename,i,1):!=substr(filename,i,1) ) {
               shortest_filename=substr(shortest_filename,1,i-1);
               if (shortest_filename:!="" && !_StartOfDBCS(shortest_filename,length(shortest_filename))) {
                   shortest_filename=substr(shortest_filename,1,length(shortest_filename)-1);
               }
               break;
            }
         }
      }

      if (allow_quick_break && length(shortest_name)==length(strip_word)) {
         break;
      }

      name=call_index(strip_word,0,match_fun_index);
   }

   // If the completion that was found for the file does not contain
   // the search word, then try to use the shortest filename which matched.
   rejected_shortest_name := false;
   if (!exact_match && (match_flags & FILE_CASE_MATCH) &&
       length(shortest_filename) >= length(strip_word) &&
       !pos(strip_word,shortest_name,  1, _fpos_case) && 
        pos(strip_word,shortest_filename,1, _fpos_case)) {
      shortest_name = shortest_filename;
      rejected_shortest_name = true;
   }
   _str tname=shortest_name;
   name=strip_word;
   if ( do_upcase ) {
      tname=upcase(tname);
      name=upcase(name);
   }

   if (((match_flags & EXACT_CASE_MATCH) && name==tname) ||
       (!(match_flags & EXACT_CASE_MATCH) && strieq(name,tname))
        && NofSpaceMatches) {
      if (NofSpaceMatches==1) {
         shortest_name=space_match;
         number_found=1;
      } else if(_last_char(shortest_name):!=' '){
         shortest_name :+= ' ';
      }
   }
   // Put dquote back on if original word had one or one of the matches had one
   if (dquote_ch:!='' || add_dquote) {
      strip_word='"':+strip_word;
      shortest_name='"':+shortest_name;
      if (NofSpaceMatches) {
         space_match='"':+space_match;
      }
   }

   if ( match_flags & TERMINATE_MATCH ) {
      call_index('',2,match_fun_index);
   }

   p_window_id=old_wid;
   /* messageNwait('sh=<'shortest_name'> fun_name='name_name(match_fun_index)' exact_match='exact_match) */
   /* directory files are deceptive.  Don't count them */
   exact_match= (number_found==1 &&
                   _arg_complete) || exact_match;
   found_match_with_space := false;
   //say('h3 strip_word='strip_word);
   //say('shortest_name='shortest_name'> exact_match='exact_match);
   if ( ! exact_match && length(strip_word)>=length(shortest_name) ) {
      if ( command_case ) {
        if ( last_event():==' ' ) {
           _beep();
           message(nls('Command expanded as much as possible.  Hit space again to force insert.'));
           _str k=get_event();
           if ( k:==' ' ) {
              keyin_char();
              clear_message();
           } else {
              call_key(k);
           }
        }
        return;
      } else {
         if ( shortest_name=='' ) {
            // IF we are doing file match and user input starts this double quote
            if (is_file_match_fun && substr(strip_word,1,1)=='"') {
               shortest_name=strip_word' ';
               exact_match=true;
               //keyin_char();
            } else {
               _beep();
               message(nls('Match not found'));
               return;
            }
         } else {
            word_expanded_as_much_as_possible := true;
            // IF we are doing file match and user input starts this double quote
            if (is_file_match_fun && substr(strip_word,1,1)=='"' &&
                length(shortest_name)<=length(strip_word)) {
               //say('strip_word='strip_word);
               word_expanded_as_much_as_possible=false;
               found_match_with_space=true;
            } else if (is_file_match_fun && iswildcard(strip_word)) {
               word_expanded_as_much_as_possible=false;
            }
            if (word_expanded_as_much_as_possible && !(match_flags & MAYBE_APPEND_SPACE_MATCH)) {
               _beep();
               message(nls('Word expanded as much as possible'));
               if (rejected_shortest_name) {
                  ArgumentCompletionUpdateTextBox();
               }
               return;
            }
            shortest_name=strip_word;
            exact_match=true;
         }
      }
   }

   int col=start_word_col+length(shortest_name);

   replace_word(line,word,start_word_col,shortest_name);
   set_command(line,col);
   //say('one_argument_text_box='one_argument_text_box);
   if ( exact_match==1 && (!one_argument_text_box || found_match_with_space) && _last_char(line) != ' ') {
      keyin(' ');
   }
   if (rejected_shortest_name) {
      ArgumentCompletionUpdateTextBox();
   }
}

/**
 * 
 * @param line       line to complete arguments in
 * @param arg_number argument number
 * @param match_fun_name
 *                   set to match function to use
 * @param keep_star  keep multi-select argument?
 * @param info       other information
 * @param one_argument_text_box
 *                   When doing completion in
 *                   dialog, want to know if need to
 *                   append space after the
 *                   argument. When on the command
 *                   line, a spaced is added after
 *                   an exact completion match. We
 *                   may want to tweak this later to
 *                   not add a space after the last
 *                   command line argument if there
 *                   are problems.
 * 
 * @return 0, 1, or 2
 */
int _find_match_fun(_str line,
                    int arg_number,
                    _str &match_fun_name,
                    bool keep_star=false,
                    _str info=null,
                    bool &one_argument_text_box=false,
                    _str &completion_info=null)
{
   one_argument_text_box=true;
   index := 1;
   get_number := 0;
   adjust := 0;
   if ( info!=null) {
      get_number=0;
   } else {
      command := "";
      parse line with command ('[ \t/]'),'r';
      command=strip(command);
      if (def_keys=='ispf-keys') {
         index=find_index('ispf-'command,COMMAND_TYPE|IGNORECASE_TYPE);
         if (!index) {
            index=find_index(command,COMMAND_TYPE);
         }
      } else {
         index=find_index(command,COMMAND_TYPE);
      }
      if (!index) {
         index=find_index(command,COMMAND_TYPE|IGNORECASE_TYPE);
      }
      parse name_info(index) with info ',' ;
      get_number=1;
      adjust=1;
   }

   if ( info=="" ) {
      /* This command does not indicate its argument types. */
      completion_info = "";
      return((index)?2:1);
   }

   multiples := false;
   type := "";
   for (;;) {
     if ( info=="" ) { break; }
     parse info with type info ;
     completion_info = type;
     get_number++;
     if ( pos('*',type) ) { /* Multiples or more */
        multiples=true;
        if ( type=='*' ) {  /* More? */
           return(2);
        }
        arg_number=-1;
        if ( !keep_star) {
           type=stranslate(type,'','*');
        }
        break;
     }
     if ( get_number>=arg_number ) {
        break;
     }
   }

   if ( get_number<arg_number ) {
      /* This command does not indicate this argument type. */
      completion_info = "";
      return(2);
   }
   one_argument_text_box= (info=='') && get_number==1+adjust && !multiples;

   if ( info=='' ) {
      type :+= '!';
   }

   if ( !keep_star ) {
      type=stranslate(type,'','!');
   }

   match_fun_name=type;
   return(0);
}

/**
 * This macro expands $envvar and ~ like a UNIX shell.
 * tilde followed by a user name is not yet supported.
 * <ul>
 * <li>Use \~ to escape tilde
 * <li>Use \$ to escape $ expansion
 * <li>Use \\ to escape \
 * <li>\ not followed by $, ~, or \ represents a backslash
 * </ul>
 * <p>
 * NOTE:  The algorithm used here is sligly different that a UNIX shell.
 *        No special processing is done when tilde or $ is found in a
 *        single or double quoted string.
 * 
 * @param cmdline    command line to expand
 * 
 * @return Expanded command line
 */
_str _unix_expansion(_str cmdline /*,do_expansion */)
{
   if (arg()<=1) {
      if ( ! def_unix_expansion ) {
         return(cmdline);
      }
   } else {
      if (!arg(2)) {
         return(cmdline);
      }
   }

   int i=1, j=0, k=0;
   env_wordchars := "a-zA-Z_0-9";
   username_wordchars := "a-zA-Z_0-9";
   result := "";
   ch := "";
   string := "";
   name := "";
   username := "";
   for (;;) {

      j=pos('[$~\\]',cmdline,i,'r');
      if ( ! j ) {
         j=length(cmdline)+1;
         result :+= substr(cmdline,i,j-i);
         return(result);
      }

      //messageNwait("_unix_expansion: cmdline="cmdline" j="j " x="pos('S'));
      result :+= substr(cmdline,i,j-i);
      ch=substr(cmdline,pos('S'),pos(''));
      string=ch;
      //messageNwait("_unix_expansion: ch="ch);
      if ( ch=='$' ) {
         k=pos('[~'env_wordchars']',cmdline,j+1,'r');
         if ( ! k ) {
            k=length(cmdline)+1;
         }
         name=substr(cmdline,j+1,k-j-1);
         if ( length(name) ) {
            string=get_env(name);
         }
         j=k-1;

      } else if ( ch=='~' && (j == 1 || substr(cmdline,j-1,1)==' ')) {
         //This type of Unix '~' expansion to home directory should only
         //happen when the '~' is at the start of the path, not in the middle
         //so added the extra test for (j == 1) (DOB 05-11-2007)
         k=pos('[~'username_wordchars']',cmdline,j+1,'r');
         if ( ! k ) {
            k=length(cmdline)+1;
         }
         username=substr(cmdline,j+1,k-j-1);
         //messageNwait("_unix_expansion: username="username);
         if ( length(username) ) {
            PASSWD passwd;
            int status=_getpwnam(username,passwd);
            //messageNwait("_unix_expansion: status="status" passwd.pw_dir="passwd.pw_dir);
            if (status) {
               string="~"username;
            } else {
               string=passwd.pw_dir;
            }
         } else {
            string=get_env('HOME');
         }
         j=k-1;

      } else if ( ch=='\' ) {
         next_ch := substr(cmdline,j+1,1);
         if ( next_ch:=='~' || next_ch:=='$' || next_ch:=='\' ) {
            string=next_ch;
            j++;
         }
      }

      result :+= string;
      i=j+1;
   }
}

/**
 * @return 
 * Escape the characters in <code>cmdline</code> to prevent
 * them from being expanded by the shell.
 * 
 * @param cmdline       line to escape
 */
_str _escape_unix_expansion(_str cmdline)
{
   if (arg()<=1) {
      if ( ! def_unix_expansion ) {
         return(cmdline);
      }
   } else {
      if (!arg(2)) {
         return(cmdline);
      }
   }

   i := 1;
   j := 0;
   result := "";
   string := "";
   ch := "";
   for (;;) {
      j=pos('[$~\\]',cmdline,i,'r');
      if ( ! j ) {
         j=length(cmdline)+1;
         result :+= substr(cmdline,i,j-i);
         return(result);
      }
      result :+= substr(cmdline,i,j-i);
      ch=substr(cmdline,pos('S'),pos(''));
      string='\'ch;
      result :+= string;
      i=j+1;
   }
}

/**
 * @return
 * Expand Unix environment variables and ~ sequences in the
 * given command line, if required by the completion information.
 * 
 * @param cmdline          command line
 * @param completion_info  (optional) completion information
 */
_str _maybe_unix_expansion(_str cmdline  /*,completion_info*/)
{
   second_arg_present := arg()>1;
   completion_info := "";
   if ( isalpha(substr(cmdline,1,1)) && ! second_arg_present ) {
      command := "";
      parse cmdline with command . ;
      index := find_index(command,COMMAND_TYPE);
      if (!index) {
         index=find_index(command,COMMAND_TYPE|IGNORECASE_TYPE);
      }
      if ( index ) {
         parse name_info(index) with completion_info ',' ;
      }
   }

   typeless match_flags;
   parse completion_info with ':' match_flags '[!*]','r' ;
   if ( isinteger(match_flags) && (match_flags &FILE_CASE_MATCH) ) {
      return(_unix_expansion(cmdline));
   }
   /*
      Get a little fancy here to support xcom command with
        completion_info=f:18 w*
   */
   //say(completion_info);
   _str line=cmdline;
   _str result=parse_file(line);
   did_some_expansion := false;
   for (;;) {
      _str word=parse_file(line);
      if (word=='') {
         break;
      }
      info:=parse_file(completion_info);
      parse info with ':' match_flags '[!*]','r';
      if ( isinteger(match_flags) && (match_flags &FILE_CASE_MATCH) ) {
         word=_unix_expansion(word);
         did_some_expansion=true;
      }
      result :+= ' 'word;
   }
   if (did_some_expansion) {
      return result;
   }
   return(cmdline);
}

static _str doPathSearchQuote(_str filename,bool return_quotes)
{
   if (return_quotes) {
      if (substr(filename,1,1)=='"') {
         return(strip(filename,'T','"'));
      }
      return(strip(_maybe_quote_filename(filename),'T','"'));
   }
   return filename;
}
/**
 * @return  Returns path search match which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 * 
 * @param name          name to match
 * @param find_first    'true' to find first, 'false' to find next
 */
_str path_search_match(_str name, int find_first,bool return_quotes=true)
{
   // When in first state, list directories and executables
   static bool gpathFirstState;
   static _str gpaths;
   static _str gpath;

   filename := "";
   permissions := "";
   isdirectory := 0;
   if (find_first) {
      gpathFirstState=true;
      if (_isUnix()) {
         gpaths=strip(get_env('PATH'));
      } else {
         gpaths=strip(PATHSEP:+get_env('PATH'));
      }
      gpath=_strip_filename(name,'N');
      filename=file_match('+v 'name,1);
   } else if (gpathFirstState) {
      filename=file_match('+v 'name,0);
   } else {
      filename=file_match('+v -d 'gpath:+name,0);
   }

   for (;;) {
      if (filename=='') {
         if (gpathFirstState) {
            // Don't path search if there is a path separator
            if (pos(FILESEP,name)) return('');
         }
         gpathFirstState=false;
         if (gpaths=='') return('');
         parse gpaths with gpath (PARSE_PATHSEP_RE),'r' gpaths;
         _maybe_append_filesep(gpath);
         filename=file_match('+v -d 'gpath:+name,1);
         continue;
      }

      //say(filename);
      permissions=substr(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
      filename=substr(filename,DIR_FILE_COL);
      if (_isUnix()) {
         isdirectory=pos('d',permissions);
      } else {
         isdirectory=pos('D',permissions);
      }

      if (isdirectory) filename :+= FILESEP;
      if (_isUnix()) {
         if (!isdirectory && pos('x',permissions) && filename!='.' && filename!='..') {
            _arg_complete=(_arg_complete && !isdirectory);
            if (gpathFirstState) {
               return(doPathSearchQuote(gpath:+filename,return_quotes));
            }
            return(doPathSearchQuote(filename,return_quotes));
         }
      } else {
         _str ext=_get_extension(filename);
         if (ext!='' && pos(' 'ext' ',' com exe pif bat cmd lnk ',1,_fpos_case) && filename!='.' &&
             filename!='..') {
            _arg_complete=(_arg_complete && !isdirectory);
            //say('dbg: filename='filename);
            if (gpathFirstState) {
               return(doPathSearchQuote(gpath:+filename,return_quotes));
            }
            return(doPathSearchQuote(filename,return_quotes));
         }
      }

      if (gpathFirstState && isdirectory) {
         _arg_complete=(_arg_complete && !isdirectory);
         //say('h2: filename='gpath:+filename);
         return(doPathSearchQuote(gpath:+filename,return_quotes));
      }

      if (gpathFirstState) {
         filename=file_match('+v 'name,0);
      } else {
         filename=file_match('+v -d 'gpath:+name,0);
      }
   }
}
/**
 * @return  Returns path search match which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 * 
 * @param name          name to match
 * @param find_first    'true' to find first, 'false' to find next
 */
_str path_searchnq_match(_str name, int find_first)
{
   return path_search_match(name,find_first,false);
}


///////////////////////////////////////////////////////////////////////////////
// EVENT TABLE FOR ARGUMENT COMPLETION
///////////////////////////////////////////////////////////////////////////////
defeventtab argument_completion_key_overrides;
def ESC=    ArgumentCompletionDoKey;   // cancel argument completion
def C_G=    ArgumentCompletionDoKey;   // maybe cancel
def ENTER=  ArgumentCompletionDoKey;   // auto complete on ENTER
def TAB=    ArgumentCompletionDoKey;   // next auto completion choice
def S_TAB=  ArgumentCompletionDoKey;   // prev auto completion choice
def UP=     ArgumentCompletionDoKey;   // next auto completion
def DOWN=   ArgumentCompletionDoKey;   // prev auto completion
def HOME=   ArgumentCompletionDoKey;   // next auto completion
def END=    ArgumentCompletionDoKey;   // prev auto completion
def PGDN=   ArgumentCompletionDoKey;   // page down auto completions
def PGUP=   ArgumentCompletionDoKey;   // page up auto completions
def C_I=    ArgumentCompletionDoKey;   // next auto completion
def C_K=    ArgumentCompletionDoKey;   // prev auto completion
def ' '=    ArgumentCompletionDoKey;   // take selected item and go for more

///////////////////////////////////////////////////////////////////////////////
// AUTO ARGUMENT COMPLETION FORM
///////////////////////////////////////////////////////////////////////////////
defeventtab _argument_completion_form;

ctltree.on_create(_str (&words)[], int text_wid)
{
   gcompletion_list_already_deleted=false;
   // size the tree
   p_active_form.p_MouseActivate=MA_NOACTIVATE;
   int y=ctltree.p_height;
   _str h=_retrieve_value("_argument_completion_list_form.p_height");
   if (isinteger(h)) y=(int)h;
   ctltree.p_user=0;

   // add the completion words to the tree
   ctltree.ArgumentCompletionUpdateList(words, text_wid);
   ctltree._TreeTop();
   ctltree._TreeSetCurIndex(TREE_ROOT_INDEX);
   ctltree.p_user=text_wid;
   //ctltree.p_ShowRoot=true;
   ctltree._TreeSetCaption(TREE_ROOT_INDEX,glast_list_matches_word);
   text_wid._AddEventtab(defeventtab argument_completion_key_overrides);
}

ctltree.on_destroy()
{
   gcompletion_list_already_deleted=true;
   // get the text box and remove the argument completion event table
   int text_wid = p_user;
   if (_iswindow_valid(text_wid)) {
      text_wid._RemoveEventtab(defeventtab argument_completion_key_overrides);
   }
   p_user=0;
}

/**
 * Update the tree control containing the list of completions
 * <p>
 * Each item in the tree uses it's tree index to refer back
 * to the index of that item in the list of words.
 * 
 * @param words      list of argument complete items
 * @param text_wid   corresponding text box (for setting width)
 */
static void ArgumentCompletionUpdateList(_str (&words)[], int text_wid,bool case_sensitive_matching=false)
{
   // set up the tree for updating
   _TreeBeginUpdate(TREE_ROOT_INDEX, '', 'T');

   // update all the words
   int i,n = words._length();
   for (i=0; i<n; ++i) {
      // add the word to the list
      _TreeAddItem(TREE_ROOT_INDEX, words[i], TREE_ADD_AS_CHILD,-1,-1,-1);
   }

   // that's all folks
   _TreeEndUpdate(TREE_ROOT_INDEX);
   if (case_sensitive_matching) {
      _TreeSortCaption(TREE_ROOT_INDEX, 'i');
      _TreeSortCaption(TREE_ROOT_INDEX, 'u');
   } else {
      _TreeSortCaption(TREE_ROOT_INDEX, 'iu');
   }

   // get the width of the corresponding text box
   initial_width := 0;
   if (text_wid && _iswindow_valid(text_wid)) {
      initial_width=text_wid.p_width;
   }

   // update the size of the list form
   _update_list_width(initial_width);
   _update_list_height(0,true,true);
   p_active_form._adjust_above_below(text_wid);
   _TreeTop();
   _TreeSetCurIndex(TREE_ROOT_INDEX);
   _TreeRefresh();
}

static void _adjust_above_below(int text_wid)
{
   // get the screen position of the text box
   wx := wy := 0;
   _map_xy(text_wid,0,wx,wy,SM_TWIP);

   screen_x := screen_y := screen_width := screen_height := 0;
   text_wid._GetVisibleScreen(screen_x, screen_y, screen_width, screen_height);
   screen_y      = _dy2ly(SM_TWIP, screen_y);
   screen_height = _dy2ly(SM_TWIP, screen_height);
   if (p_y < wy || wy+p_height+text_wid.p_height >= screen_y+screen_height) {
      wy -= p_height;
   } else {
      wy += text_wid.p_height;
   }
   _move_window(wx,wy,p_width,p_height);
}

void ctltree.lbutton_double_click()
{
   ArgumentCompletionTextBoxInsert();
   ArgumentCompletionTerminate();
}

void ctltree.ENTER()
{
   ArgumentCompletionTextBoxInsert();
   ArgumentCompletionTerminate();
}

void ctltree.on_change(int reason, int index)
{
   if (reason == CHANGE_SELECTED) {
      isRoot := (index == TREE_ROOT_INDEX);
      p_NeverColorCurrent  = isRoot;
      p_AlwaysColorCurrent = !isRoot;
      ArgumentCompletionUpdateSelected(index);
   }
}

void ctltree.ESC()
{
   ArgumentCompletionTerminate();
}

void ctltree.on_lost_focus()
{
   focus_wid := _get_focus();
   text_wid := ArgumentCompletionTextBoxWid();
   /*
      Hopefully a fix to a Slick-C stack that seems to occur when
      double clicking the the tree. I was not able to reproduce this
      but based on the stack, this should fix it.
   */
   if (!_iswindow_valid(text_wid)) {
      return;
   }
   if (focus_wid != text_wid && focus_wid != text_wid.p_active_form) {
      ArgumentCompletionTerminate();
      if (focus_wid && _iswindow_valid(focus_wid) && focus_wid!=_get_focus()) {
         focus_wid._set_focus();
      }
   }
}

/**
 * Update the selected item in the tree and corresponding text box
 */
static void ArgumentCompletionUpdateSelected(int index)
{
   int text_wid = p_user;
   if (_iswindow_valid(text_wid)) {
      ArgumentCompletionTextBoxInsert();
   }
}

/**
 * Return the WID of the tree control on the argument complete form
 */
static int ArgumentCompletionTreeWid()
{
   int form_wid = _find_formobj('_argument_completion_form','n');
   if (!form_wid) return 0;
   return form_wid.ctltree;
}

static int ArgumentCompletionTextBoxWid()
{
   tree_wid := ArgumentCompletionTreeWid();
   if (!tree_wid) return 0;
   int text_wid = tree_wid.p_user;
   if (!_iswindow_valid(text_wid)) return 0;
   return text_wid;
}


/**
 * Callback for handling keypresses during auto complete mode.
 * This function passes through to the default key mappings
 * for handling one key press.
 * <p>
 * NOTE: If 'key' is bound to a macro that closes the current
 * window and leaves focus in another window, especially one
 * that is not an editor control, and the window ID found in
 * <code>gAutoCompleteResults.editor</code> is recycled, we may
 * add the event tab back to the wrong window.
 * 
 * @param key           key press
 * @param doTerminate   force auto complete to terminate
 */
void ArgumentCompletionDoKey()
{
   if (!command_state()) {
      _macro_delete_line();
   }
   _macro('m',_macro('s'));
   _str key=last_event(null,true);

   if (ArgumentCompletionKey(key)) {
      return;
   }

   last_index(prev_index('','C'),'C');
   _RemoveEventtab(defeventtab argument_completion_key_overrides);

   text_wid := p_window_id;
   last_event(key);
   call_key(key);
   tree_wid := ArgumentCompletionTreeWid();
   if (_iswindow_valid(text_wid) && _iswindow_valid(tree_wid)) {
      text_wid._AddEventtab(defeventtab argument_completion_key_overrides);
   }
}
bool maybeListDirectoryEntries() {
   //return(false);
   _str line;
   int col;
   get_command(line,col);
   // Only works if last argument is a directory
   if (col<=length(line)) {
      return(false);
   }
   _str command=parse_file(line);
   if (line=='') {
      return(false);
   }
   index := find_index(command,COMMAND_TYPE);
   if (!index) return(false);
   _str completion_info=name_info(index);
   typeless match_flags;
   _str name_prefix;
   // For now, this only handles simple completion with only the first
   // argument defined.
   parse completion_info with name_prefix ':' match_flags',';
   match_flags=strip(match_flags,'T','*');
   if (name_prefix!='f' || !(isinteger(match_flags) && (match_flags & APPEND_SPACE_MATCH))) {
      if((name_prefix!='f' && name_prefix!='a') || !isinteger(match_flags) ||!(match_flags && AUTO_DIR_MATCH) ) {
         return(false);
      }
   }
   /* 
       NOTE:  This can not support "e c:\temp\" because the command line is replaced with what
       was already there.  No on change event occurs in this case so no new list is presented.
   */
   tempArg := "";
   hasQuote := true;
   line=strip(p_text,'T','"');
   _maybe_strip_filesep(line);
   i := lastpos('"',line);
   // Try not to be fooled by: e "abc" file2
   if (!i || substr(line,i+1,1,'?')==' ') {
      i=lastpos(' ',line);
      if (i) {

         hasQuote=false;
         tempArg=substr(line,i+1);
      }
   } else {
      tempArg=substr(line,i+1);
   }
   if (tempArg!='' && isdirectory(tempArg)) {
      _maybe_append_filesep(line);
      //say('len='length(line)+1'*********************************');
//         set_command('',length(line)+1);
      //_str junk;
      //get_command(junk,col);
      //say('col='col);
      //say('line='line);
      set_command(line,length(line)+1);
      //command_put(line);
      //keyin(FILESEP);
      /*if (hasQuote) {
         //dir('"'tempArg);
         command_put('e "'tempArg);
      } else {
         //dir(tempArg);
         command_put(tempArg);
      } */
      //ArgumentCompletionUpdateTextBox();
      return(true);
   }
   //say('completion_info='completion_info);
   return(false);
}

/**
 * Process keyboard event occuring while argument completion
 * is active.  Maps UP/DOWN to scrolling up/down the list, etc.
 */
bool ArgumentCompletionKey(_str key)
{
   //say("ArgumentCompletionKey: last="event2name(last_event()));
   // get the auto complete tree
   // if it is gone, then auto complete is gone
   status := 0;
   tree_wid := ArgumentCompletionTreeWid();
   if (tree_wid <= 0) {
      return false;
   }

   // make sure this is a valid key
   if (key==null) {
      return false;
   }

   // handle other key presses
   switch (key) {
   case name2event(' '):
      if (tree_wid._TreeCurIndex()!=TREE_ROOT_INDEX) {
         ArgumentCompletionTextBoxInsert();
      }
      ArgumentCompletionTerminate();
      return false;

   case ENTER:
      if (tree_wid._TreeCurIndex()==TREE_ROOT_INDEX) {
         ArgumentCompletionTerminate();
         return false;
      }
      if (ArgumentCompletionTextBoxInsert()) {
         ArgumentCompletionTerminate();
         if (p_window_id==_cmdline) {
            return(maybeListDirectoryEntries());
         }
         return true;
      }
      ArgumentCompletionTerminate();
      return false;

   case C_G:
      if (!iscancel(key)) {
         return false;
      }
      ArgumentCompletionTerminate();
      return true;
   case ESC:
      ArgumentCompletionTerminate();
      return true;
   
   case S_TAB:
   case UP:
   case C_I:
      if (key==S_TAB && p_window_id!=_cmdline &&
          (def_argument_completion_options & VSARGUMENT_COMPLETION_NO_TAB_NEXT)) {
         ArgumentCompletionTerminate();
         return false;
      }
      if (tree_wid._TreeCurIndex() == TREE_ROOT_INDEX) {
         tree_wid._TreeBottom();
         if (_iswindow_valid(tree_wid) && tree_wid.p_object==OI_TREE_VIEW) {
            tree_wid.ArgumentCompletionUpdateSelected(tree_wid._TreeCurIndex());
         }
      } else {
         status = tree_wid._TreeUp();
         if (status < 0) {
            tree_wid._TreeSetCurIndex(TREE_ROOT_INDEX);
         }
      }
      return true;

   case TAB:
   case DOWN:
   case C_K:
      if (key==TAB && p_window_id!=_cmdline &&
          (def_argument_completion_options & VSARGUMENT_COMPLETION_NO_TAB_NEXT)) {
         ArgumentCompletionTerminate();
         return false;
      }
      if (tree_wid._TreeCurIndex() == TREE_ROOT_INDEX) {
         tree_wid._TreeTop();
         if (_iswindow_valid(tree_wid) && tree_wid.p_object==OI_TREE_VIEW) {
            tree_wid.ArgumentCompletionUpdateSelected(tree_wid._TreeCurIndex());
         }
      } else {
         status = tree_wid._TreeDown();
         if (status < 0) {
            tree_wid._TreeSetCurIndex(TREE_ROOT_INDEX);
         }
      }
      return true;

   case HOME:
      if (tree_wid._TreeCurIndex()==TREE_ROOT_INDEX ||
          tree_wid._TreeGetPrevSiblingIndex(tree_wid._TreeCurIndex())<=0) {
         return false;
      }
      tree_wid._TreeTop();
      return true;
   case END:
      if (tree_wid._TreeCurIndex()==TREE_ROOT_INDEX ||
         tree_wid._TreeGetNextSiblingIndex(tree_wid._TreeCurIndex())<=0) {
         return false;
      }
      tree_wid._TreeBottom();
      return true;

   case PGUP:
      tree_wid._TreePageUp();
      return true;
   case PGDN:
      tree_wid._TreePageDown();
      return true;

   default:
      return false;
   }
}

/**
 * Replace the selected text in the text box
 */
_str ArgumentCompletionGetNewValue()
{
   tree_wid := ArgumentCompletionTreeWid();
   if (tree_wid <= 0) {
      return null;
   }

   index := tree_wid._TreeCurIndex();
   if (index < 0) {
      return null;
   }

   caption := tree_wid._TreeGetCaption(index);
   return glast_list_matches_prefix:+caption:+glast_list_matches_suffix;
}

/**
 * Replace the selected text in the text box
 */
bool ArgumentCompletionTextBoxInsert()
{
   tree_wid := ArgumentCompletionTreeWid();
   if (tree_wid <= 0) {
      return false;
   }

   index := tree_wid._TreeCurIndex();
   if (index < 0) {
      return false;
   }

   _str new_value = ArgumentCompletionGetNewValue();
   if (new_value == null) {
      return false;
   }

   text_wid := ArgumentCompletionTextBoxWid();
   if (text_wid <= 0) {
      return false;
   }

   caption := tree_wid._TreeGetCaption(index);
   prefix := substr(new_value,1,glast_list_matches_column-1);
   prefix :+= caption;
   glast_list_matches_word=prefix;
   text_wid.p_text = prefix;
   text_wid._end_line();
   text_wid.p_text=new_value;
   return true;
}
void _deleteArgumentCompletionForm(int formWID)
{
   if (gcompletion_list_already_deleted) {
      return;
   }
   origFocusWID := _get_focus();
   start_pos := 0;
   end_pos := 0;
   if ((origFocusWID) && (origFocusWID.p_object) && (origFocusWID.p_object==OI_TEXT_BOX || origFocusWID.p_object==OI_COMBO_BOX)) {
      origFocusWID._get_sel(start_pos,end_pos);
   }
   if (_iswindow_valid(formWID)) {
      formWID._delete_window();
   }
   if ( _iswindow_valid(origFocusWID) ) {
      origFocusWID._set_focus();
      if ( origFocusWID.p_object==OI_TEXT_BOX || origFocusWID.p_object==OI_COMBO_BOX ) {
         origFocusWID._set_sel(start_pos,end_pos);
      }
   }
}

/**
 * Break out of argument completion dialog
 */
void ArgumentCompletionTerminate(bool checkForTreeFocus=false)
{
   // check if the tree control has just gotton focus
   // this is used only when being called fron on_lost_focus()
   focus_wid := _get_focus();
   tree_wid := ArgumentCompletionTreeWid();
   if (tree_wid && _iswindow_valid(tree_wid) && checkForTreeFocus &&
       (focus_wid == tree_wid || focus_wid==tree_wid.p_active_form)) {
      return;
   }

   // turn off auto-select so that the text-wid does
   // not auto-select when the tree loses focus
   orig_auto_select := false;
   text_wid := ArgumentCompletionTextBoxWid();
   int text_box_wid = text_wid;
   if (text_wid && _iswindow_valid(text_wid)) {
      orig_auto_select = text_box_wid.p_auto_select;
      text_box_wid.p_auto_select = false;
      text_wid._RemoveEventtab(defeventtab argument_completion_key_overrides);
   }

   // kill the list
   if (tree_wid != 0) {
      // 4/3/2012
      // Cannot delete the tree here because we could be called from an on_change
      //tree_wid.p_active_form._delete_window();
      tree_wid.p_user=0;
      tree_wid.p_active_form.p_visible = false;
      tree_wid.p_active_form.p_name = "";
      _post_call(_deleteArgumentCompletionForm,tree_wid.p_active_form);
   }

   // initialize globals for next time in
   glast_list_matches_column=1;
   glast_list_matches_word='';
   glast_list_matches_prefix='';
   glast_list_matches_suffix='';

   // restore focus in case if we accidently changed focus
   // when we deleted the window
   // force the set_focus(), even if it already has focus
   // so that a bogus _on_got_focus() event doesn't come
   // along later and screw everything up
   if (tree_wid!=0 && focus_wid && _iswindow_valid(focus_wid)) {
      focus_wid._set_focus();
   }

   // restore auto-select property and focus back to text wid
   if (orig_auto_select && text_box_wid && _iswindow_valid(text_box_wid)) {
      text_box_wid.p_auto_select = orig_auto_select;
   }
}

/**
 * Update the completion suggestions for a text box or combo box.
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see autocomplete
 * 
 * @appliesTo  Text_Box, Combo_Box
 * @categories Completion_Functions, Combo_Box_Methods, Text_Box_Methods
 */
bool ArgumentCompletionUpdateTextBox(_str completion_info='', _str history_prefix="")
{
//   say('ArgumentCompletionUpdateTextBox disabled until tree finished');
//   return(false);

   // is this feature turned off?
   if (!(def_argument_completion_options & VSARGUMENT_COMPLETION_ENABLE)) {
      return false;
   }

   // If the text box having focus or being updated changes
   // then kill the argument completion list
   text_wid := ArgumentCompletionTextBoxWid();
   if (text_wid != 0 && text_wid != p_window_id && text_wid == _get_focus()) {
      ArgumentCompletionTerminate();
   }

   // If the current window does not have focus, then
   // do not attempt to do arguent completion
   text_wid = p_window_id;
   if (_get_focus() != text_wid) {
      return false;
   }
   if (text_wid.p_object != OI_TEXT_BOX && text_wid.p_object!=OI_COMBO_BOX) {
      return false;
   }

   // is this feature turned off for this text box control?
   if (!text_wid.p_ListCompletions) {
      return false;
   }

   if (text_wid.p_text == '') {
      ArgumentCompletionTerminate();
      return false;
   }

   // command line auto completion enabled?
   if (text_wid==_cmdline && !(def_argument_completion_options & VSARGUMENT_COMPLETION_COMMANDLINE)) {
      return false;
   }

   // If we already have a tree control and it's current
   // item is not the root item
   //int tree_wid = ArgumentCompletionTreeWid();
   //if (tree_wid && tree_wid._TreeCurIndex()!=TREE_ROOT_INDEX) {
   //}
   _str new_value = ArgumentCompletionGetNewValue();
   if (new_value != null && new_value == text_wid.p_text) {
      return false;
   }

   // attempt to find multiple matches?
   _str words[];
   words._makeempty();

   // get the completion information
   bool isCommandLine = (p_window_id == _cmdline ||
                            (isEclipsePlugin() && p_active_form.p_caption :== "SlickEdit Command"));
   args_to_command := (!isCommandLine || completion_info != '' || history_prefix != '');
   if (completion_info=='') {
      completion_info=p_completion;
   }

   // look for syntax expansion opportunities
   orig_word := p_text;
   bool case_sensitive_matching=false;
   maybe_list_matches(completion_info, '', true, args_to_command,
                      false, null, true, words, true,case_sensitive_matching);
   if (words._length()==0) {
      glast_list_matches_word=p_text;
      glast_list_matches_prefix='';
      glast_list_matches_suffix='';
      glast_list_matches_column=1;
   }
   if (p_window_id==_cmdline) {
      list_cmdline_history_matches(history_prefix,p_text,words);
   }

   // did we get any results?
   if (words._length() == 0) {
      ArgumentCompletionTerminate();
      return false;
   }

   // remove duplicate matches, technically, we should sort first,
   // but we really only care if there is just one unique match
   _aremove_duplicates(words,false);

   // only one result from command line
   if (p_window_id==_cmdline && words._length()==1 && glast_list_matches_word==words[0]) {
      ArgumentCompletionTerminate();
      return false;
   }

   // only one result that is an exact match of the text box's contents
   if (words._length()==1 && words[0]==p_text) {
      ArgumentCompletionTerminate();
      return false;
   }

   // Now set up the auto complete GUI with our results
   int tree_wid = ArgumentCompletionShowList(words, orig_word,case_sensitive_matching);
   if (tree_wid) {
      tree_wid._TreeSetCaption(TREE_ROOT_INDEX,glast_list_matches_word);
   }

   // clean up and return
   return true;
}


/**
 * Display the list of auto-completion results
 * 
 * @return 1 on success
 */
static int ArgumentCompletionShowList(_str (&words)[], _str prefix,bool case_sensitive_matching=false)
{
   tree_wid := ArgumentCompletionTreeWid();
   if (!tree_wid) {

      // get the screen position of the text box
      wx := wy := 0;
      _map_xy(p_window_id,0,wx,wy,SM_TWIP);

      // now show the window
      orig_wid := p_window_id;
      int orig_start=p_sel_start;
      int orig_length=p_sel_length;
      wy += p_height;

      int form_wid = show('-hidden -nocenter _argument_completion_form', words, p_window_id);
      if (form_wid > 0) {
         form_wid._move_window(wx,wy,form_wid.p_width,form_wid.p_height);
         form_wid._adjust_above_below(orig_wid);
         form_wid._ShowWindow(SW_SHOWNOACTIVATE);
      }

      // make sure focus goes back to the text box control
      p_window_id = orig_wid;
      _set_focus();
      p_sel_start=orig_start;
      p_sel_length=orig_length;

   } else {
      int text_wid = tree_wid.p_user;
      tree_wid.p_user=0;
      tree_wid.ArgumentCompletionUpdateList(words,text_wid,case_sensitive_matching);
      tree_wid.p_user=text_wid;
   }

   return tree_wid;
}

void _lostfocus_ArgumentCompletionList()
{
   ArgumentCompletionTerminate();
}

void _actapp_ArgumentCompletionList(_str gettingFocus="")
{
   if (!gettingFocus) {
      ArgumentCompletionTerminate();
   }
}

