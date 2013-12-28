////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50048 $
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

#define SE_ORIG_MENU_SUFFIX            '_se_orig'

//
// This module is a general purpose engine for providing completion.
// To avoid update problems, do not  modify this file if possible.  Place
// your additional completion support procedures in another file.
// See below for information on conventions.
//
// To add completion support for another argument type you need to define
// a constant, run initialization code, and define a procedure (DEFPROC)
// with the name equal to constant_value||'_match'.  You may also define a
// help procedure with name equal to constant_value||'_help'.  See c_help
// procedure for a source code help example.
// The sample code below shows the format:
//
//   include "slick.sh"
//   const
//      US_STATE_ARG='US'   /* Underscores must be dashes */
//
//   defload
//      if eq_name2value('us-state',def_user_args)='' then  /* Not exist? */
//         def_user_args=def_user_args' us-state='US_STATE_ARG
//      endif
//
//   defproc us_match(name_prefix,find_first)
//
//            This function must perform three tasks depending on the
//            value of find_first.
//
//            find_first       Task
//                0            Search for next prefix match of name_prefix.
//                             Return match found. Return '' if not found.
//                1            Search for first prefix match of name_prefix.
//                             Return match found. Return '' if not found.
//                2            Terminate match.  Only match functions
//                             with the TERMINATE_MATCH flag will be called.
//
//  Flags may be attached to the completion procedures:
//
//       TERMINATE_MATCH   =1
//       FILE_CASE_MATCH   =2
//       NO_SORT_MATCH     =4
//       REMOVE_DUPS_MATCH =8
//       AUTO_DIR_MATCH    =16
//
//

#if __OS390__ || __TESTS390__
int def_max_completion_items=500;
#else
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
int def_max_completion_items=2000;
#endif


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
_command void maybe_complete(...) name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      if ( arg() ) {
         complete(arg(1));
      } else {
         complete();
      }
   } else {
      keyin_char();
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
_command boolean maybe_list_matches( _str completion_info='',
                                     _str notused='',
                                     boolean auto_select=false,
                                     boolean args_to_command=false,
                                     boolean doEditorCtl=false,
                                     _str first_arg_completion_info=null,
                                     boolean doAddToAutoCompletion=false,
                                     typeless &words=null,
                                     boolean doAddToArgumentCompletion=false
                                   ) name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   glast_list_matches_column=1;
   glast_list_matches_word='';
   glast_list_matches_prefix='';
   glast_list_matches_suffix='';

   if ( command_state() || doEditorCtl) {

      boolean return_val=false;
      _str line='';
      int col=1;
      if (doEditorCtl) {
         line=_expand_tabsc();
         col=p_col;
      } else {
         get_command(line,col);
      }

     /* Could be search command like /.... */
     /* If first char of command line is not an alpha AND not just args of command. */
     if ( line!='' && ! isalpha(substr(line,1,1)) && ! args_to_command ) {
        if (!doAddToAutoCompletion) keyin_char();
        return false;
     }

     int start_word_col;
     _str word;
     _str temp_line=line;

     _str name_prefix='';
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

     boolean fall_through_file_completion=false;
     //say('arg_number='arg_number' col='col' word=<'word'> start_word_col='start_word_col);
     if (arg_number==2 && args_to_command && first_arg_completion_info!=null) {
        completion_info=first_arg_completion_info;
     }

     int status=0;
     _str match_fun_prefix='';
     if ( arg_number<=1 && ! args_to_command ) {
        match_fun_prefix=COMMAND_ARG;
     } else {
        if ( args_to_command ) {
           status=_find_match_fun(temp_line,arg_number,match_fun_prefix,true,completion_info);
        } else {
           status=_find_match_fun(temp_line,arg_number,match_fun_prefix,true);
           if (status && status!=2) {
              arg_number= _get_arg_number(alternate_temp_line,col,word,start_word_col,args_to_command,completion_info);
              status=_find_match_fun(alternate_temp_line,arg_number,match_fun_prefix,true,"f:"(FILE_CASE_MATCH)"*");
              fall_through_file_completion=true;
              auto_select=true;
           }
        }
        if ( status ) {
           if (!doAddToAutoCompletion) keyin_char();
           return false;
        }
     }

     int multi_select=0;
     typeless last_arg2=0;
     int match_fun_index=match_prefix2index(match_fun_prefix,match_flags,multi_select, last_arg2);

     glast_list_matches_word=word;
     glast_list_matches_prefix=substr(line,1,start_word_col-1);
     glast_list_matches_suffix=substr(line,start_word_col+length(word));
     glast_list_matches_column=start_word_col;

     if (doAddToAutoCompletion) {
        list_matches(strip(word),match_fun_prefix,'',0,'',(auto_select)?auto_select:false,doAddToAutoCompletion,words,doAddToArgumentCompletion);
        return(false);
     }

     // disable automatic argument completion until we are done here
     boolean orig_ListCompletions=true;
     if (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX) {
        ArgumentCompletionTerminate();
        orig_ListCompletions = p_ListCompletions;
        p_ListCompletions=false;
     }

     //messageNwait('word='word' new_match_name='new_match_name);
     for (;;) {
        //old_word=strip(word);
        last_event(ESC);
        _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,1);
        _str result=list_matches(strip(word),match_fun_prefix,'',0,'',(auto_select)?auto_select:false);
        _default_option(VSOPTION_STAY_IN_GET_STRING_COUNT,0);
        if ( result=='' ) {
           /* No matches found OR ESC pressed OR match function not found. */
           if (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX) {
              p_ListCompletions=orig_ListCompletions;
           }
           return false;
        }

        boolean keep_listing=((match_flags & AUTO_DIR_MATCH) && last_char(result):==FILESEP);
        // When we complete on a data set, unless a data set's type
        // is known, the PDS entries presented by list_matches() do not
        // have the trailing FILESEP to indicate that it is a "directory"
        // and not a file.
        //
        // As a result, if a resulting selection is a data set, we
        // need to stat() the data set to ensure its type. Calling
        // file_match("-p") does this trick efficiently.
        if (!keep_listing && _DataSetIsFile(result)) {
           _str dsmatched = file_match("-p "result, 1);
           keep_listing=((match_flags & AUTO_DIR_MATCH) && last_char(dsmatched):==FILESEP);
        }

        if ( result!='' ) {
           //last_arg=_arg_complete && last_event():==ENTER && ! keep_listing
           boolean last_arg=_arg_complete && ! keep_listing;
           if ( keep_listing ) {
              /* Translate  path/../ to / and Translate path/./ to path */
              int len=length(result);
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
                 result=result:+' ';
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
void complete(...)
{
   _str line='';
   int col=1;
   get_command(line,col);

   int status=0;
   _str fun_name_prefix='';
   boolean command_case=true;

   /* if the current character is a space and the previous character is not. */
   if ( col>1 && _Substr(line,col,1):==' ' && _Substr(line,col-1):!=' ' &&
       (isalpha(substr(line,1,1)) || arg())
      ) {

      /* Try to expand this word on the command line. */
      _str word='';
      int start_word_col=1;
      int arg_number= _get_arg_number(line,col,word,start_word_col,arg(),arg(1));
      if ( arg_number<=1 && ! arg() ) {

         int index=0;
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
           _str k=get_event();
           call_key(k);
           return;
         }

         fun_name_prefix=COMMAND_ARG;
         command_case=true;

      } else {

         if ( arg() ) {
            status=_find_match_fun(line,arg_number,fun_name_prefix,false,arg(1));
         } else {
            status=_find_match_fun(line,arg_number,fun_name_prefix);
         }
         if ( status || word=='' ) {
           keyin_char();
           return;
         }
         command_case=0;
      }

      expand_word(line,word,start_word_col,fun_name_prefix,command_case);
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
                     boolean args_to_command,
                     _str completion_info
                     // Valid only if args_to_command is 'false'
   )
{
   int one_arg=999999;
   // Check for special one argument support only flag
   _str command='';
   _str rest='';
   if (!args_to_command) {
      parse line with command rest ;
      int index=find_index(command,COMMAND_TYPE);
      completion_info='';
      if (index) {
         parse name_info(index) with completion_info ',' ;
      }
   }

   _str name_prefix='';
   typeless match_flags='';
   parse completion_info with name_prefix ':' match_flags;
   match_flags=strip(match_flags,'T','*');
   if (isinteger(match_flags) && (match_flags & ONE_ARG_MATCH)) {
      one_arg=(args_to_command?1:2);
   }

   _str ch='';
   int end_of_word_col=0;
   int arg_number=0;
   word='';
   _str orig_line=line;

   for (;;) {

      if ( line:=='' ) {
        start_word_col=col;
        arg_number=arg_number+1;
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

      end_of_word_col=end_of_word_col+ length(word)+1;
      _str strip_word=strip(word);
      ch=substr(strip_word,1,1);
      /* don't count options or blanks. */
 #if __PCDOS__
      if ( ch:=='-' || ch:=='+' || ch:=='[' || ch=='/' || strip_word:=='' ) { continue; }
 #else
      /* UNIX case */
      if ( ch:=='-' || ch:=='+' || ch:=='[' || strip_word:=='' ) { continue; }
 #endif

      arg_number=arg_number+1;
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
static _str file_or_dir_match(_str name, boolean find_first,
                              boolean quote_option,
                              _str file_match_options,
                              boolean semicolon_separator=false)
{
   // if this is going to take too long, we won't bother
   if (find_first==1 && _findFirstTimeOut(name,def_fileio_timeout,def_fileio_continue_to_timeout)) {
      return('');
   }

   // get rid of any quotes hanging around
   name=strip(name,'B','"');

   _str prefix='';

   // are we using semicolons to separate our filenames?
   if (semicolon_separator) {
      int i=lastpos(';',name);
      if (i) {
         prefix=substr(name,1,i);
         name=substr(name,i+1);
      }
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
   boolean last_char_is_filesep=(last_char(name):==FILESEP);
   if ( name:!='' ) {
      _arg_complete=(_arg_complete && ! last_char_is_filesep);
   }

   // do we want to quote the results?
   if (quote_option) {
      // maybe quote our filename
      name=maybe_quote_filename(name);
      // if it's a directory, leave the last quote off the end
      if ( last_char_is_filesep ) {
         name=strip(name,'T','"');
      }
   } else if (semicolon_separator) {
      _arg_complete=false;
      if (name=='') {
         return('');
      }
      name=prefix:+name;
   }

   return _escape_unix_expansion(name);
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
_str _buf_match_no_path(_str name,boolean find_first,boolean return_path=false)
{
   name=_strip_filename(name,'p');
   _str match=buf_match('',find_first? 1:0);
   for (;;) {
      if ( rc ) {
         return('');
      }
      if ( match!='' ) {
         _str temp=_strip_filename(match,'P');
         if ( file_eq(substr(temp,1,length(name)),name) ) {
            if (return_path) {
               return(match);
            }
            return(temp);
         }
      }
      match=buf_match('',0);
   }
}
_str def_binary_ext='.vtg .sx .ex .vsb .obj .exe .lib .dll .pdb .qfy .bmp .jpg .gif .ico .zip .gz .winmd .o .a .so .sl ';

static int ga_match_count;
enum AMatch{
   AMATCH_FILES,
   AMATCH_BUFFERS,
   AMATCH_WORKSPACE
};
static AMatch gamatch;

_str a_match(_str name, boolean find_first)
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

      // do we make exclusions for binary files?
      if (def_keys!='brief-keys' && def_list_binary_files) {
         // the real work is done in f_match
         temp=f_match(name,find_first);

         // we found something!
         if (temp!='') {
            ++ga_match_count;
            return(temp);
         }
      } else {
         // let f_match do the work
         temp=f_match(name,find_first);
         for (;;) {
            // we didn't find anything, give up on this part
            if ( temp=='' ) break;

            // filter out the binary files
            if ( ! pos('.'_get_extension(temp)' ',def_binary_ext' ',1,_fpos_case) ) {
               ++ga_match_count;
               return temp;
            }

            // file was binary, so try again
            temp=f_match(name,false);
         }
      }
   }

   // if there are any wildcard characters in the filename, we don't want to bother with it
   if (iswildcard(_strip_filename(name,'p'))) {
      return('');
   }

   // we already tried files, buffers are next
   if (gamatch==AMATCH_FILES) {
      find_first=1;
      gamatch=AMATCH_BUFFERS;
   }

   // get just the plain filename
   _str name_no_path=_strip_filename(name,'p');

   // we do this to escape the slash character for wildcard searching
#if FILESEP=='\'
   name=stranslate(name,'\\','\');
#endif

   // are we looking for a buffer?
   if ((gamatch==AMATCH_BUFFERS) && (def_edit_flags&EDITFLAG_BUFFERS) && 
       ga_match_count+1<def_max_completion_items) {

      temp = buf_match(name_no_path, (int)find_first, 'N');
      for (;;) {
         if (temp!='') {
            if (!endsWith(temp,name'*',false,_fpos_case'&')) {
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
      find_first=1;
      gamatch=AMATCH_WORKSPACE;
   }

   // are we looking for workspace files?
   if ((gamatch==AMATCH_WORKSPACE) && (def_edit_flags&EDITFLAG_WORKSPACEFILES) && 
       ga_match_count+1<def_max_completion_items) {

      temp=wkspace_file_match(name_no_path,find_first);
      for (;;) {
         if (temp!='') {
            if (!endsWith(temp,name'*',false,_fpos_case'&')) {
               temp=wkspace_file_match(name_no_path,false);
               continue;
            }
            ++ga_match_count;
            return(temp);
         }
         break;
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
_str f_match(_str name,boolean find_first)
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
_str fnq_match(_str name,boolean find_first)
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
_str semicolonfiles_match(_str name,boolean find_first)
{
   return file_or_dir_match(name,find_first,false,'',true);
}
/**
 * @return  Returns next file name which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.  Returns '' when
 * no more matches are found.
 * <p>
 * If there are absolute no matches to <code>name</code>,
 * and <code>find_first</code> is true, it will return <code>name</code>.
 * <p>
 * This function behaves like {@link f_match}, but allows the user to
 * type a non-existent file name.  This is useful in order to get completion
 * for directory names, but still be able to specify a new file.
 * 
 * @param name          file name to search for
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @see f_match
 * 
 * @categories Completion_Functions, File_Functions
 */
_str filenew_match(_str name,boolean find_first)
{
   _str f=file_or_dir_match(name,find_first,true,'');
   if (find_first && f=='') return(name);
   return(f);
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
_str dir_match(_str name,boolean find_first)
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
_str dirnq_match(_str name,boolean find_first)
{
   return file_or_dir_match(name,find_first,false,'+X ');
}
/**
 * @return  Returns next directory name which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.  Returns '' when
 * no more matches are found.
 * <p>
 * If there are absolute no matches to <code>name</code>,
 * and <code>find_first</code> is true, it will return <code>name</code>.
 * <p>
 * This function behaves like {@link dir_match}, but allows the user to
 * type a non-existent directory name.  This is useful in order to get
 * completion for directory names, but still be able to specify a new path.
 * 
 * @param name          directory path to search for
 * @param find_first    'true' to find first, 'false' to find next
 * 
 * @see f_match
 * 
 * @categories Completion_Functions, File_Functions
 */
_str dirnew_match(_str name,boolean find_first)
{
   _str f=file_or_dir_match(name,find_first,false,'+X ');
   if (find_first && f=='') return(name);
   return(f);
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
_str w_match(_str name,boolean find_first)
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
   _str firstch=substr(name,1,1);
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
_str b_match(_str name,boolean find_first)
{
   name=make_buf_match(name);
   _str match=buf_match('',find_first? 1:0);
   for (;;) {
      if ( rc ) {
         break;
      }
      if ( match!='' ) {
         match=make_buf_match(match);
         if ( file_eq(substr(match,1,length(name)),name) ) {
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
_str project_file_match(_str name,boolean find_first)
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
      int KeyPendingCount=0;
      foreach (auto filename in fileList) {
         ++KeyPendingCount;
         if( (KeyPendingCount%100)==0 && _IsKeyPending() ) {
            return '';
         }
         filename = _strip_filename(filename, 'P');
         if (file_eq(substr(filename,1,length(name)), name))  {
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

   if (_project_name=='') {
      return f_match(name, find_first);
   }

   static int j;
   if (find_first) {
      j=0;
   }

   _str fileList[];
   status := _getProjectFiles(_workspace_filename, _project_name, fileList, 0);
   if (status) {
      return '';
   }

   while (j < fileList._length()) {
      if (file_eq(substr(_strip_filename(fileList[j], 'p'),1,length(name)), name))  {
         return fileList[j];
      }
      j++;
   }

   return '';
}
static int gKeyPendingCount;
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
_str wkspace_file_match(_str name,boolean find_first)
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
      foreach (auto p in ProjectNames) {
         // search for matching file names
         _projectMatchFile(_workspace_filename, p, name, matches,true);
         // also check if the project anme matches the prefix
         if (file_eq(name, substr(_strip_filename(p,"P"),1,length(name)))) {
            matches[matches._length()] = absolute(p,_strip_filename(_workspace_filename, 'N'));
         }
      }
      // finally, check if the current workspace name matches the prefix
      if (file_eq(name, substr(_strip_filename(_workspace_filename,"P"),1,length(name)))) {
         matches[matches._length()] = _workspace_filename;
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

   _str result='';
   if (pass) {
      result=name_name(cname_match('ispf-'name,find_first!=0,COMMAND_TYPE));
      if (result:=='') {
         return(result);
      }
      return(substr(result,6));
   }
   result=name_name(cname_match(name,find_first!=0,COMMAND_TYPE));
   if (result:!='') {
      return(result);
   }
   if (pass!=0 || def_keys!='ispf-keys') {
      return('');
   }
   pass=1;
   return(c_match(name,3));
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
_str _object_match(_str name,boolean find_first)
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
_str _form_match(_str name,boolean find_first)
{
   int index=0;
   for (;;) {
      index=name_match(name,(int)find_first,OBJECT_TYPE);
      if (!index) {
         return('');
      }
      if (type2oi(name_type(index))==OI_FORM) {
         break;
      }
      find_first=0;
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
_str _menu_match(_str name,boolean find_first)
{
   int index=0;
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
      find_first=0;
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
_str _pic_match(_str name, boolean find_first)
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
_str mode_match(_str name,boolean find_first)
{
   _str modename='';
   int index=1;
   static typeless i;
   if (find_first) {
      i._makeempty();
   }
   for (;;) {
      index=name_match('def-language-',(int)find_first,MISC_TYPE);
      find_first=0;
      if (index <= 0) break;
      _str ni=name_info(index);
      if (ni!='' && substr(ni,1,1)!='@') {
         parse ni with . 'MN='modename',';
         if (_ModenameEQ(substr(modename,1,length(name)),name)) {
            return(modename);
         }
      }
   }
   for (;;) {
      gAutoLoadExtHashtab._nextel(i);
      if (i._isempty()) {
         break;
      }
      modename=gAutoLoadExtHashtab:[i].modeName;
      index=find_index('def-language-'i,MISC_TYPE);
      if (index<=0 && _ModenameEQ(substr(modename,1,length(name)),name)) {
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
_str k_match(_str name, boolean find_first)
{
   int index=cname_match(name,find_first,COMMAND_TYPE);
   for (;;) {
      if (!index) return('');
      typeless flags='';
      parse name_info(index) with ',' flags;
      if (flags!='' && (flags &VSARG2_MACRO)) {
         return(name_name(index));
      }
      index=cname_match(name,0,COMMAND_TYPE);
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
int cname_match(_str name, boolean find_first, int kind)
{
   if (find_first) cignorecase_type=0;
   int index=cname_match2(name,find_first,kind|cignorecase_type);
   if (!index) {
      cignorecase_type=IGNORECASE_TYPE;
      index=cname_match2(name,find_first,kind|cignorecase_type);
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
static int cname_match2(_str name, boolean find_first, int kind)
{
   int index=name_match(name,(int)find_first,kind);
   for (;;) {
      if ( ! index || (! (name_type(index)&COMMAND_TYPE)) ||
         index_callable(index) ) {
         return(index);
      }
      index=name_match(name,0,kind);
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
_str m_match(_str name, boolean find_first)
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
_str _dll_match(_str name, boolean find_first)
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
_str v_match(_str name, boolean find_first)
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
_str pc_match(_str name, boolean find_first)
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
 * Returns '' when no more matches are found.
 * 
 * @param name          tag name to match
 * @param find_first    'true' to find first, 'false' to find next
 *
 * @categories Completion_Functions
 */
_str mt_match(_str name,boolean find_first)
{
   if (find_first) {
      if (find_first==2) {
         return(tag_match(name,(int)find_first,"e"));
      }
      int tfindex=0;
      int orig_id = p_window_id;
      int status=_e_MaybeBuildTagFile(tfindex,true);
      p_window_id = orig_id;
      if (status) {
         messageNwait("Error building Slick-C"VSREGISTEREDTM" tag file");
         return("");
      }

   }
   return(tag_match(name,(int)find_first,"e"));
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
_str pcbt_match(_str name, boolean find_first)
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
_str hNt_match(_str name, boolean find_first)
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
_str ht_match(_str name,boolean find_first)
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
_str hc_match(_str name,boolean find_first)
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
_str name_eq_match(_str prefix_name, boolean find_first, _str string)
{
   static _str eq_string;
   if ( find_first ) {
     eq_string=lowcase(string);
   }
   _str name='';
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
_str e_match(_str name,boolean find_first)
{
   return(env_match(env_case(name),(int)find_first));
}

static void list_cmdline_history_matches(_str history_prefix, _str prefix, _str (&words)[])
{
   // open a tempview of the command history buffer
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(VSWID_RETRIEVE);

   // start from the beginning
   boolean duplicates:[];
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
                              boolean &last_arg2)
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
   match_flags = (tmp_match_flags=='')? 0: tmp_match_flags;

   int index= find_index(name_prefix'-match',PROC_TYPE|COMMAND_TYPE);
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
      int status=search('^ _','r@');
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
   return _message_box(nls('Found %s1 items with prefix "%s2".  Continue searching?', count, prefix), '', MB_YESNO|MB_ICONQUESTION);
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
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id=='') return(1);
   if ( title=='' ) {
     title=nls('Open Form');
   }
   _str name_prefix='';
   typeless match_flags='';
   if (fast_complete!='') {
      _insert_name_list(fast_complete);
   } else {
      parse completion with name_prefix ':' match_flags ;
      //match_fun_index=match_prefix2index(completion,match_flags,multi_select, last_arg2)
      int match_fun_index=find_index(name_prefix'_match',PROC_TYPE);
      _str match_name=call_index('',1,match_fun_index);
      int num_matches=0;
      for (;;) {
         if (match_name=='') {
            break;
         }
         if (++num_matches==def_max_completion_items) {
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
      _sellist._lbsort();
   }
   _sellist._lbtop();
   _sellistcombo._set_sel(1,length(_sellistcombo.p_text)+1);
   if (flags & SL_SELECTPREFIXMATCH) {
      _sellistcombo.call_event(CHANGE_SELECTED,_sellistcombo,ON_CHANGE,'');
   }
   // Add this so the dialog does not flicker when it comes up
   p_active_form.p_ShowModal=1;
   p_active_form.p_visible=1;
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
                  boolean auto_select_if_one_match=false,
                  boolean doAddToAutoCompletion=false,
                  typeless &words=null,
                  boolean doAddToArgumentCompletion=false)
{
   boolean cmdline_active = (_cmdline==p_window_id);
   boolean last_arg2=0;
   int match_flags=0;
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
   }

   if (doAddToArgumentCompletion && name=='') {
      return('');
   }

   if ( ! multi_select ) {
      multi_select=0;
   } else {
      multi_select=SL_ALLOWMULTISELECT|SL_SELECTALL;
   }

   int temp_view_id=0;
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

   if ( title=='' ) {
     title=nls('Select a Command Parameter');
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

   int num_matches=0;
   int width=0;
   int KeyPendingCount=0;
   for (;;) {
     if ( match_name=='' ) { break; }
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
     } else if (++num_matches==def_max_completion_items) {
        int status=prompt_continue_matching(name,num_matches);
        if (status==IDNO) {
           break;
        }
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
      _str case_sense='i';
      if (match_flags & FILE_CASE_MATCH) {
         case_sense=_fpos_case;
      }
      sort_buffer(case_sense);
   }

   if ( match_flags & REMOVE_DUPS_MATCH ) {
      _remove_duplicates();
   }
   clear_message();

   _str result='';
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
            boolean isDirectory=last_char(line)==FILESEP;
            if (isDirectory) {
               line=substr(line,1,length(line)-1);
            }
            _str prefix;
            if (substr(line,1,1)=='"') {
               prefix='"'initialPrefix;
            } else {
               prefix=initialPrefix;
            }
            _str displayText=substr(line,length(prefix)+1);
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
                                     (isDirectory)? _pic_fldclos12:_pic_file12);
            }
         }
         _delete_temp_view(temp_view_id);
      //}
   } else if ( p_Noflines==1 && (auto_select_if_one_match ||
       ((match_flags&AUTO_DIR_MATCH) && last_char(result):==FILESEP))  ) {
      _delete_temp_view(temp_view_id);
   } else {
      activate_window(orig_view_id);
      int orig_wid=p_window_id;
      typeless wid=show('_sellist_form -new -reinit',
                  title,
                  SL_VIEWID|SL_SELECTCLINE|SL_HELPCALLBACK|multi_select,
                  temp_view_id,
                  buttons,
                  (help_proc_index)?'1':'',  // help item
                  '',                   // font
                  clist_fall_through  // Call back function
                 );
      if (cmdline_active) {
         _cmdline.p_visible=1;
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
 * Removes duplicate adjacent lines from the current buffer.
 * Usually the buffer is sorted before calling this function.
 * <p>
 * If there is a selection active, this function will only
 * remove duplicates within the selected lines.
 * 
 * @param ignore_case      'i' for case sensitive
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void remove_duplicates(_str ignore_case='') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   int start_line=0;
   int last_line=MAXINT;
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
 * @param ignore_case      'i' for case sensitive
 * @param start_line       starting line (inclusive)
 * @param last_line        last line (inclusive)
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
void _remove_duplicates(_str ignore_case='',int start_line=0,int last_line=MAXINT)
{
   // if this is a list box, then use the more effecient builtin method
   boolean listbox_object = (p_object == OI_LIST_BOX);
   if (listbox_object) {
      _lbremove_duplicates(ignore_case, start_line, last_line-start_line);
      return;
   }

   // convert case argument to boolean
   ignore_case=upcase(ignore_case)=='I';

   // compute the start line
   if (start_line>0) {
      p_line=start_line;
   } else {
      top();
      start_line=1;
   }

   // compute the last line
   if (last_line==MAXINT) {
      last_line=p_Noflines;
   }

   // go through the lines
   int count=last_line-start_line;
   _str previous_line='', line='';
   get_line(previous_line);

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
                        boolean command_case)
{
   int match_flags=0;
   int multi_select=0;
   boolean last_arg2=false;
   int match_fun_index=match_prefix2index(fun_name_prefix,match_flags,multi_select, last_arg2);
   if ( ! match_fun_index ) {
      return;
   }

   _str strip_word=strip(word);
   if ( command_case ) {
      strip_word=name_case(strip_word);
   }

   int old_wid=p_window_id;
   p_window_id=_edit_window();
   _arg_complete=1;

   if (match_flags & FILE_CASE_MATCH) {
      strip_word=_unix_expansion(strip_word);
   }

   _str name='';
   _str shortest_name='';
   int number_found=0;
   boolean exact_match=0;
   if ( command_case && (find_index(strip_word,COMMAND_TYPE) ||
       find_index(strip_word,COMMAND_TYPE|IGNORECASE_TYPE))) {
      name=strip_word;

   } else {
      name=call_index(strip_word,1,match_fun_index);
      shortest_name=name;
      number_found=0;
      exact_match=0;
      if (name!='' && (match_flags & FILE_CASE_MATCH) && iswildcard(strip_word)) {
         name=strip_word;
      }
   }

   int lenp1=length(strip_word)+1;
   _str dquote_ch='';
   if (substr(strip_word,1,1)=='"') {
      dquote_ch='"';
   }

   if (name!='' && substr(name,1,1)!='"') {
      name=dquote_ch:+name;
   }

   if (shortest_name!='' && substr(shortest_name,1,1)!='"') {
      shortest_name=dquote_ch:+shortest_name;
   }

   boolean allow_quick_break=false;
   switch (name_name(match_fun_index)) {
   case 'tag-match':
      allow_quick_break=true;
      break;
   }

   boolean do_upcase=(match_flags & FILE_CASE_MATCH) && _fpos_case=='I';
   /* 
       Handle following case:
         "Program<Space>"
       Where have two files:
         "Program Files"
         "ProgramGroup"
       When type space, need to get a space for the above
       case.
   */ 
   int NofSpaceMatches=0;
   _str space_match;
   _str quote_strip_word_space=strip_word' ';
   if ( do_upcase ) {
      quote_strip_word_space=upcase(quote_strip_word_space);
   }
   if (substr(quote_strip_word_space,1,1)!='"') {
      quote_strip_word_space='"'quote_strip_word_space;
   }
   for (;;) {

      if (do_upcase) {
         if ( strieq(name,strip_word) ) {
            shortest_name=name;
            exact_match=1;
            break;
         }
      } else if ( name:==strip_word ) {
         shortest_name=name;
         exact_match=1;
         break;
      }

      if ( name=='' ) break;
      number_found=number_found+1;

      _str ch1=substr(shortest_name,1,1);
      _str ch2=substr(name,1,1);
      if ( ch1=='"' && ch2:!='"' ) {
         name='"'name;
      } else if ( ch2=='"' && ch1:!='"' ) {
         shortest_name='"'shortest_name;
      }

      _str temp=name;
      if ( length(name)<length(shortest_name) ) {
        name=shortest_name;
        shortest_name=temp;
      }

      _str tname=shortest_name;
      if ( do_upcase ) {
         tname=upcase(tname);
         name=upcase(name);
      }
      if (quote_strip_word_space:==substr(name,1,length(quote_strip_word_space))) {
         space_match=temp;
         ++NofSpaceMatches;
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

      if (allow_quick_break && length(shortest_name)==length(strip_word)) {
         break;
      }

      name=call_index(strip_word,0,match_fun_index);
      if (name!='' && substr(name,1,1)!='"') {
         name=dquote_ch:+name;
      }
   }
   if (substr(shortest_name,1,1)=='"' && substr(strip_word,1,1)!='"') {
      strip_word='"'strip_word;
   }
   _str tname=shortest_name;
   name=strip_word;
   if ( do_upcase ) {
      tname=upcase(tname);
      name=upcase(name);
   }

   //say('NofSpaceMatches='NofSpaceMatches);
   if (name==tname && NofSpaceMatches) {
      if (NofSpaceMatches==1) {
         shortest_name=space_match;
         number_found=1;
      } else {
         shortest_name=shortest_name:+' ';
      }
      /*
         Try not to change case when no new characters inserted. This
         allows user to create new files with different case. This logic
         does not work if ~ unix expansion is used on a case insensitive
         file system (mac!)

         Example 
            type "c:\program<space>" --> "c:\program " NOT "c:\Program "
      */
      if((match_flags & FILE_CASE_MATCH) && !_files_case_sensitive()) {
         _str cmpword=word;
         if (substr(shortest_name,1,1)=='"' && substr(cmpword,1,1)!='"') {
            cmpword='"'cmpword;
         } else if (substr(shortest_name,1,1)!='"' && substr(cmpword,1,1)=='"') {
            cmpword=substr(cmpword,2);
         }
         if (file_eq(cmpword,strip(shortest_name))) {
            shortest_name=substr(cmpword,1,length(cmpword)):+substr(shortest_name,length(cmpword)+1);
         }
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
   /*
      There are still some problems with doing file completion
      in dialogs which do recursive file matching. The following
      case still will confuse a user:

         *  User presses space for recursive file match in
            make tags dialog, no wildcard, and a longer
            match occurs in the current directory.
            User must press right arrow to avoid completion.

      Possible solutions

         *  Turn off completion when doing recursive file
            matching.
            This is not great because user may want to complete
            a directory name.
         *  Change completion key to shift+space.
            Could require semicolon file separator.

            This works but most users will never known
            shift+space does completion.
         *  Do a recursive file match.  This works but the
            performance could be very slow.

      None of these solutions are any better than what we
      have.

   */
   if (name_name(match_fun_index)=='f-match' && iswildcard(strip_word)) {
      if ( shortest_name=='' ) {
         //message(nls('Match not found'));
      }
      exact_match=1;
      shortest_name='"'strip(strip_word,'B','"')'"';
   } else if (substr(strip_word,1,1)=='"' && substr(shortest_name,1,1)!='"') {
      shortest_name='"'shortest_name;
   }

   //say('h3 strip_word='strip_word);
   //say('shortest_name='shortest_name);
   if ( ! exact_match && length(strip_word)>=length(shortest_name) ) {
      if ( command_case ) {
#if 0
        if ( find_index(strip_word,VAR_TYPE|GVAR_TYPE) ) {
           keyin_char()
           return ''
        }
#endif
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
            if (name_name(match_fun_index)=='f-match' && substr(strip_word,1,1)=='"') {
               shortest_name=strip_word' ';
               exact_match=1;
               //keyin_char();
            } else {
               _beep();
               message(nls('Match not found'));
               return;
            }
         } else {
            boolean word_expanded_as_much_as_possible=true;
            // IF we are doing file match and user input starts this double quote
            if (name_name(match_fun_index)=='f-match' && substr(strip_word,1,1)=='"' &&
                length(shortest_name)<=length(strip_word)) {
               //say('strip_word='strip_word);
               word_expanded_as_much_as_possible=0;
            // IF there is NOT a file with this name + a space
            } else if (name_name(match_fun_index)=='f-match' && !iswildcard(strip_word) &&
                file_match(maybe_quote_filename(strip(strip_word,'B','"')' '),1):!=""
                ) {
               word_expanded_as_much_as_possible=0;
            } else if (name_name(match_fun_index)=='f-match' && iswildcard(strip_word)) {
               word_expanded_as_much_as_possible=0;
            } else if (match_flags & ONE_ARG_MATCH) {
               p_window_id=_edit_window();
               name=call_index(strip_word' ',1,match_fun_index);
               if ( match_flags & TERMINATE_MATCH ) {
                  call_index('',2,match_fun_index);
               }
               word_expanded_as_much_as_possible=(name=='');
               p_window_id=old_wid;
            }
            if (word_expanded_as_much_as_possible) {
               _beep();
               message(nls('Word expanded as much as possible'));
               return;
            }
            shortest_name=strip_word;
            exact_match=1;
         }
      }
   }

   int col=start_word_col+length(shortest_name);
   if ( exact_match==1 ) {
      col=col+1;
   }

   replace_word(line,word,start_word_col,shortest_name);
   set_command(line,col);
}

/**
 * @return 0, 1, or 2
 * 
 * @param line             line to complete arguments in
 * @param arg_number       argument number
 * @param match_fun_name   set to match function to use
 * @param keep_star        keep multi-select argument?
 * @param info             other information
 */
int _find_match_fun(_str line,
                    int arg_number,
                    _str &match_fun_name,
                    boolean keep_star=false,
                    _str info=null)
{
   int index=1;
   int get_number=0;
   if ( info!=null) {
      get_number=0;
   } else {
      _str command='';
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
   }

   if ( info=='' ) {
      /* This command does not indicate its argument types. */
      return((index)?2:1);
   }

   _str type='';
   for (;;) {
     if ( info=='' ) { break; }
     parse info with type info ;
     get_number=get_number+1;
     if ( pos('*',type) ) { /* Multiples or more */
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
      return(2);
   }

   if ( info=='' ) {
      type=type:+'!';
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
   _str env_wordchars='a-zA-Z_0-9';
   _str username_wordchars='a-zA-Z_0-9';
   _str result='';
   _str ch='';
   _str string='';
   _str name='';
   _str username='';
   for (;;) {

      j=pos('[$~\\]',cmdline,i,'r');
      if ( ! j ) {
         j=length(cmdline)+1;
         result=result :+ substr(cmdline,i,j-i);
         return(result);
      }

      //messageNwait("_unix_expansion: cmdline="cmdline" j="j " x="pos('S'));
      result=result :+ substr(cmdline,i,j-i);
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
         _str next_ch=substr(cmdline,j+1,1);
         if ( next_ch:=='~' || next_ch:=='$' || next_ch:=='\' ) {
            string=next_ch;
            j=j+1;
         }
      }

      result=result:+string;
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

   int i=1;
   int j=0;
   _str result='';
   _str string='';
   _str ch='';
   for (;;) {
      j=pos('[$~\\]',cmdline,i,'r');
      if ( ! j ) {
         j=length(cmdline)+1;
         result=result :+ substr(cmdline,i,j-i);
         return(result);
      }
      result=result :+ substr(cmdline,i,j-i);
      ch=substr(cmdline,pos('S'),pos(''));
      string='\'ch;
      result=result:+string;
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
   boolean second_arg_present=arg()>1;
   _str completion_info='';
   if ( isalpha(substr(cmdline,1,1)) && ! second_arg_present ) {
      _str command='';
      parse cmdline with command . ;
      int index=find_index(command,COMMAND_TYPE);
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

   return(cmdline);
}
static _str doPathSearchQuote(_str filename)
{
   if (substr(filename,1,1)=='"') {
      return(strip(filename,'T','"'));
   }
   return(strip(maybe_quote_filename(filename),'T','"'));
}
/**
 * @return  Returns path search match which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 * 
 * @param name          name to match
 * @param find_first    'true' to find first, 'false' to find next
 */
_str path_search_match(_str name, int find_first)
{
   // When in first state, list directories and executables
   static boolean gpathFirstState;
   static _str gpaths;
   static _str gpath;

   _str filename='';
   _str permissions='';
   int isdirectory=0;
   if (find_first) {
      gpathFirstState=true;
#if __UNIX__
      gpaths=strip(get_env('PATH'));
#else
      gpaths=strip(PATHSEP:+get_env('PATH'));
#endif
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
         parse gpaths with gpath (PATHSEP) gpaths;
         _maybe_append_filesep(gpath);
         filename=file_match('+v -d 'gpath:+name,1);
         continue;
      }

      //say(filename);
      permissions=substr(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
      filename=substr(filename,DIR_FILE_COL);
#if __UNIX__
      isdirectory=pos('d',permissions);
#else
      isdirectory=pos('D',permissions);
#endif

      if (isdirectory) filename=filename:+FILESEP;
#if __UNIX__
      if (!isdirectory && pos('x',permissions) && filename!='.' && filename!='..') {
         _arg_complete=(_arg_complete && !isdirectory);
         if (gpathFirstState) {
            return(doPathSearchQuote(gpath:+filename));
         }
         return(doPathSearchQuote(filename));
      }
#else
      _str ext=_get_extension(filename);
      if (ext!='' && pos(' 'ext' ',' com exe pif bat cmd lnk ',1,_fpos_case) && filename!='.' &&
          filename!='..') {
         _arg_complete=(_arg_complete && !isdirectory);
         //say('dbg: filename='filename);
         if (gpathFirstState) {
            return(doPathSearchQuote(gpath:+filename));
         }
         return(doPathSearchQuote(filename));
      }
#endif

      if (gpathFirstState && isdirectory) {
         _arg_complete=(_arg_complete && !isdirectory);
         //say('h2: filename='gpath:+filename);
         return(doPathSearchQuote(gpath:+filename));
      }

      if (gpathFirstState) {
         filename=file_match('+v 'name,0);
      } else {
         filename=file_match('+v -d 'gpath:+name,0);
      }
   }
}


///////////////////////////////////////////////////////////////////////////////
// EVENT TABLE FOR ARGUMENT COMPLETION
///////////////////////////////////////////////////////////////////////////////
defeventtab argument_completion_keys;
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
   text_wid._AddEventtab(defeventtab argument_completion_keys);
}

ctltree.on_destroy()
{
   // get the text box and remove the argument completion event table
   int text_wid = p_user;
   if (_iswindow_valid(text_wid)) {
      text_wid._RemoveEventtab(defeventtab argument_completion_keys);
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
static void ArgumentCompletionUpdateList(_str (&words)[], int text_wid)
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
   _TreeSortCaption(TREE_ROOT_INDEX, 'iu');

   // get the width of the corresponding text box
   int initial_width=0;
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
   int wx=0, wy=0;
   _map_xy(text_wid,0,wx,wy,SM_TWIP);

   int screen_x=0, screen_y=0, screen_width=0, screen_height=0;
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
      boolean isRoot = (index == TREE_ROOT_INDEX);
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
   int focus_wid = _get_focus();
   int text_wid = ArgumentCompletionTextBoxWid();
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
   int tree_wid = ArgumentCompletionTreeWid();
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
   _macro_delete_line();
   _macro('m',_macro('s'));
   _str key=last_event(null,true);

   if (ArgumentCompletionKey(key)) {
      return;
   }

   last_index(prev_index('','C'),'C');
   _RemoveEventtab(defeventtab argument_completion_keys);

   int text_wid = p_window_id;
   last_event(key);
   call_key(key);
   int tree_wid=ArgumentCompletionTreeWid();
   if (_iswindow_valid(text_wid) && _iswindow_valid(tree_wid)) {
      text_wid._AddEventtab(defeventtab argument_completion_keys);
   }
}
boolean maybeListDirectoryEntries() {
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
   int index=find_index(command,COMMAND_TYPE);
   if (!index) return(false);
   _str completion_info=name_info(index);
   typeless match_flags;
   _str name_prefix;
   // For now, this only handles simple completion with only the first
   // argument defined.
   parse completion_info with name_prefix ':' match_flags',';
   match_flags=strip(match_flags,'T','*');
   if (name_prefix!='filenew') {
      if((name_prefix!='f' && name_prefix!='a') || !isinteger(match_flags) ||!(match_flags && AUTO_DIR_MATCH) ) {
         return(false);
      }
   }
   /* 
       NOTE:  This can not support "e c:\temp\" because the command line is replaced with what
       was already there.  No on change event occurs in this case so no new list is presented.
   */
   _str tempArg='';
   boolean hasQuote=true;
   line=strip(p_text,'T','"');
   _maybe_strip_filesep(line);
   int i=lastpos('"',line);
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
boolean ArgumentCompletionKey(_str key)
{
   //say("ArgumentCompletionKey: last="event2name(last_event()));
   // get the auto complete tree
   // if it is gone, then auto complete is gone
   int status = 0;
   int tree_wid = ArgumentCompletionTreeWid();
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
   int tree_wid = ArgumentCompletionTreeWid();
   if (tree_wid <= 0) {
      return null;
   }

   int index = tree_wid._TreeCurIndex();
   if (index < 0) {
      return null;
   }

   _str caption = tree_wid._TreeGetCaption(index);
   return glast_list_matches_prefix:+caption:+glast_list_matches_suffix;
}

/**
 * Replace the selected text in the text box
 */
boolean ArgumentCompletionTextBoxInsert()
{
   int tree_wid = ArgumentCompletionTreeWid();
   if (tree_wid <= 0) {
      return false;
   }

   int index = tree_wid._TreeCurIndex();
   if (index < 0) {
      return false;
   }

   _str new_value = ArgumentCompletionGetNewValue();
   if (new_value == null) {
      return false;
   }

   int text_wid = ArgumentCompletionTextBoxWid();
   if (text_wid <= 0) {
      return false;
   }

   _str caption = tree_wid._TreeGetCaption(index);
   _str prefix = substr(new_value,1,glast_list_matches_column-1);
   prefix = prefix :+ caption;
   glast_list_matches_word=prefix;
   text_wid.p_text = prefix;
   text_wid._end_line();
   text_wid.p_text=new_value;
   return true;
}
void _deleteArgumentCompletionForm(int formWID)
{
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
void ArgumentCompletionTerminate(boolean checkForTreeFocus=false)
{
   // check if the tree control has just gotton focus
   // this is used only when being called fron on_lost_focus()
   int focus_wid = _get_focus();
   int tree_wid = ArgumentCompletionTreeWid();
   if (tree_wid && _iswindow_valid(tree_wid) && checkForTreeFocus &&
       (focus_wid == tree_wid || focus_wid==tree_wid.p_active_form)) {
      return;
   }

   // turn off auto-select so that the text-wid does
   // not auto-select when the tree loses focus
   boolean orig_auto_select = false;
   int text_wid = ArgumentCompletionTextBoxWid();
   int text_box_wid = text_wid;
   if (text_wid && _iswindow_valid(text_wid)) {
      orig_auto_select = text_box_wid.p_auto_select;
      text_box_wid.p_auto_select = false;
      text_wid._RemoveEventtab(defeventtab argument_completion_keys);
   }

   // kill the list
   if (tree_wid != 0) {
      // 4/3/2012
      // Cannot delete the tree here because we could be called from an on_change
      //tree_wid.p_active_form._delete_window();
      tree_wid.p_user=0;
      tree_wid.p_active_form.p_visible = 0;
      tree_wid.p_active_form.p_name = "";
      _post_call(_deleteArgumentCompletionForm,tree_wid.p_active_form);
   }

   // initalize globals for next time in
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
boolean ArgumentCompletionUpdateTextBox(_str completion_info='', _str history_prefix="")
{
//   say('ArgumentCompletionUpdateTextBox disabled until tree finished');
//   return(false);

   // is this feature turned off?
   if (!(def_argument_completion_options & VSARGUMENT_COMPLETION_ENABLE)) {
      return false;
   }

   // If the text box having focus or being updated changes
   // then kill the argument completion list
   int text_wid = ArgumentCompletionTextBoxWid();
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
   boolean isCommandLine = (p_window_id == _cmdline ||
                            (isEclipsePlugin() && p_active_form.p_caption :== "SlickEdit Command"));
   boolean args_to_command = (!isCommandLine || completion_info != '' || history_prefix != '');
   if (completion_info=='') {
      completion_info=p_completion;
   }

   // look for syntax expansion opportunities
   _str orig_word = p_text;
   maybe_list_matches(completion_info, '', true, args_to_command,
                      false, null, true, words, true);
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
   int tree_wid = ArgumentCompletionShowList(words, orig_word);
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
static int ArgumentCompletionShowList(_str (&words)[], _str prefix)
{
   int tree_wid = ArgumentCompletionTreeWid();
   if (!tree_wid) {

      // get the screen position of the text box
      int wx=0, wy=0;
      _map_xy(p_window_id,0,wx,wy,SM_TWIP);

      // now show the window
      int orig_wid = p_window_id;
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
      tree_wid.ArgumentCompletionUpdateList(words,text_wid);
      tree_wid.p_user=text_wid;
   }

   return tree_wid;
}

