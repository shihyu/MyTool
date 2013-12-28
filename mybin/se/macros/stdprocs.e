////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50320 $
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
#include "vsevents.sh"
#include "tagsdb.sh"
#require "se/alias/AliasFile.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/datetime/DateTime.e"
#import "adaptiveformatting.e"
#import "cua.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "combobox.e"
#import "complete.e"
#import "contact_support.e"
#import "context.e"
#import "dlgman.e"
#import "files.e"
#import "get.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "recmacro.e"
#import "saveload.e"
#import "seek.e"
#import "slickc.e"
#import "smartp.e"
#import "stdcmds.e"
#import "tags.e"
#import "sc/lang/Range.e"
#endregion

using namespace se.lang.api;
using namespace se.datetime;
using namespace se.alias;

#define MAX_ATSLICK_LINE_LEN 1024
#define MAX_RETRIEVE_LINES 600
#define COMPLETION_ARGS  ('file='FILE_ARG             " "'buffer='BUFFER_ARG:+' ':+\
                     'command='COMMAND_ARG       " "'object='FORM_ARG:+' ':+\
                     'picture='PICTURE_ARG       " "'module='MODULE_ARG:+' ':+\
                     'pc='PC_ARG                 " ":+\
                     'pcb-type='PCB_TYPE_ARG     " ":+\
                     'var='VAR_ARG               " "'env='ENV_ARG:+' ':+\
                     'menu='MENU_ARG             " "'help='HELP_ARG:+' ':+\
                     'help-type='HELP_TYPE_ARG   " "'help-class='HELP_CLASS_ARG:+' ':+\
                     'color-field='COLOR_FIELD_ARG " "'tag='TAG_ARG)

_str def_wide_ext='';

int def_maxdialoghist=10;  // Default maximum dialog box retrieval
#define CTLSEPARATOR  "\0"

/**
 * If set to true, syntax expansion can still expand a keyword prefix,
 * even if there is a local variable with the same name as the prefix.
 * For example:
 * <pre>
 *    void foobar(int i) {
 *       i&lt;space&gt;
 *    }</pre>
 * will expand to:
 * <pre>
 *    void foobar(int i) {
 *       if (&lt;cursor&gt;) {
 *       }
 *    }</pre>
 *
 * @default false
 * @categories Configuration_Variables
 */
boolean def_expansion_overrides_locals=false;

//
//  Compare macro language identifiers case sensitive.
//
boolean name_eq(_str a,_str b)
{
   return a:==b;
}
_str name_case(_str a)
{
   return(a);
}
/** 
 * Compare two language mode names. 
 *  
 * @categories Miscellaneous_Functions
 * @deprecated Use {@link _ModenameEQ()} instead. 
 */
boolean _modename_eq(_str a,_str b)
{
   return (strieq(a,b));
}

boolean _files_case_sensitive()
{
#if __PCDOS__ || __MACOSX__
   return(false);
#else
   return(true);
#endif
}

/**
 * Compares file parts <i>file1</i> to <i>file2</i> in the case sensitivity
 * of the operating system file system. 
 *  
 * @categories File_Functions
 */
boolean file_eq(_str file1, _str file2)
{
#if __PCDOS__
   return (strieq(file1,file2));
#else
   if (_isMac()) {
      return (strieq(file1,file2));
   }
   return(file1:==file2);
#endif
}
/**
 * Returns file_attrs in operating system specific case.  For DOS and Windows NT,
 * attributes are displayed in upper case.  For UNIX, file_attrs is returned as
 * the result and is not changed.
 *
 * @param name   A string containing the attributes to convert.
 *
 * @return A string with the attributes converted to the proper case.
 * @categories File_Functions
 */
_str attr_case(_str name)
{
#if __PCDOS__
  return(upcase(name));
#else
  return(name);
#endif

}

/**
 * @return  Returns <i>env_name</i> in operating specific case. 
 * DOS environment variables are displayed in upper case. 
 * @categories String_Functions
 */
_str env_case(_str name)
{
#if __PCDOS__
   return(upcase(name));
#else
   return(name);
#endif
}

/**
 * Compares environment variable names <i>env1</i> to <i>env2</i> in the 
 * case sensitivity of the operating system. 
 * @categories File_Functions
 */
_str env_eq(_str env1,_str env2)
{
#if __PCDOS__
   return(strieq(env1,env2));
#else
   return(env1:==env2);
#endif
}

no_code_swapping   /* Just in case there is an I/O error reading */
                   /* the slick.sta file, this will ensure user */
                   /* safe exit and save of files.  These commonly */
                   /* used procedures will not cause module swapping. */

/**
 * Places <i>string</i> on the command line.  Cursor is placed at end
 * of <i>string</i>.
 *
 * @categories Command_Line_Functions
 */
void command_put(_str string)
{
   p_window_id=_cmdline;
   // Try to show as much text to the left of the cursor as possible
   _set_sel(1,1);_refresh_scroll();

   set_command(string,length(string)+1);
   _set_focus();
}
/**
 * Displays "Command cancelled" message.
 *
 *
 * @categories Miscellaneous_Functions
 */
void cancel()
{
  message(get_message(COMMAND_CANCELLED_RC));

}
/**
 * @return Returns <b>true</b> if isprint(<i>key</i>), <i>key</i> is bound
 * to the <b>normal_character</b> command, or <i>key</i> is not bound to a
 * command and asc(substr(<i>key</i>,1,1))>27.
 *
 * @categories Keyboard_Functions
 *
 */
boolean isnormal_char(_str key)
{
   int index=eventtab_index(_default_keys,
             (p_HasBuffer)?p_mode_eventtab: _edit_window().p_mode_eventtab,
                       event2index(key));
   _str akey=key2ascii(key);
   return((! index && length(akey)==1 && _asc(_maybe_e2a(akey))>27) ||
          (length(key)>=2 && length(key)<=3) ||  // 21-bit Unicode character above 127
          isprint(key) ||
         key==TAB  ||
         name_name(index)=='normal-character'
         );
}
boolean isspace(_str key)
{
   key=key2ascii(key);
   if ( length(key)>1 ) return(0);
   return(key:==" " || key:=="\t");
}
/**
 * @return Returns <b>true</b> if <i>char</i> is a numeric or alphabetic
 * character.
 *
 * @categories String_Functions
 *
 */
boolean isalnum(_str key)
{
   key=key2ascii(key);
   if ( length(key)>1 ) { return(0); }
   return((isalpha(key) || (key>='0' && key<='9')));

}
/**
 * @return Returns non-zero value if <i>char</i> is an alphabetic character.
 *
 * @categories String_Functions
 *
 */
boolean isalpha(_str key)
{
  if ( length(key)>1 ) { return(0); }
#if __EBCDIC__
  key=upcase(key)
  return((key>='A' && key<='I') || (key>='J' && key<='R') || (key>='S' && key<='Z'));
#else
  key=upcase(key);
  return(key>='A' && key<='Z');
#endif

}
/**
 * @return Returns non-zero value if <i>char</i> is an upper case string or character.
 *
 * @categories String_Functions
 */
boolean isupper(_str key)
{
   return (upcase(key) :== key && lowcase(key) :!= key);
}
/**
 * @return Returns non-zero value if <i>char</i> is an lower case string or character.
 *
 * @categories String_Functions
 */
boolean islower(_str key)
{
   return (lowcase(key) :== key && upcase(key) :!= key);
}
/**
 * @return Returns <b>true</b> if <i>key</i> is a single numeric character.
 *
 * @categories String_Functions
 *
 */
boolean isdigit(_str key)
{
  if ( length(key)>1 ) { return (false); }
  return(key>='0' && key<='9');

}
#if 0
_str isinteger(number)
{
  number=strip(number)
  ch=substr(number,1,1)
  if ( ch=='-' || ch=='+' ) {
     number=substr(number,2)
  }
  return(! verify(strip(number),'01234567989') && number!='')

}
#endif
/**
 * @return Returns <b>true</b> if <i>char</i> is length one and its ASCII
 * value is greater than 29.
 *
 * @categories String_Functions
 *
 */
boolean isprint(_str key)
{
   if ( length(key)>4 ) return(0);
   // event2index returns 0..128 for a Unicode 21-bit character or SBCS/DBCS character
   return(event2index(key)>=32);
#if 0
   if (_UTF8()) {
      if ( length(key)>4 ) return(0);
      return(event2index(key)>=32);
#if 0
      // IF this is NOT a 21-bit character
      i=_UTF8Asc(key);
      if (i>=0x200000 || i<0) return(0);
      return(event2index(key)>=30);
#endif
   }
   if ( length(key)>1 ) return(0);
   return(event2index(key)>=30)
#endif
}

/**
 * Returns the absolute value of number.  If number is negative, -number is returned.  Otherwise number is returned unmodified.
 *
 * @param x Integer or float.
 *
 * @return The absolute value of the number.
 *
 * @categories Miscellaneous_Functions
 */
typeless abs(typeless x)
{
   if( x>0 ) {
      return x;
   }
   return -x;
}

/**
 * Returns the sign (+1, 0, -1) of number.
 *
 * @param x              Integer or float.
 * @param zeroIsPositive (optional). Set to true if you want 0 to be considered a positive number (+1).
 *                       Defaults to false.
 *
 * @return +1 for positive signed value, -1 for negative signed value, 0 for zero value.
 *
 * @categories Miscellaneous_Functions
 */
int sign(typeless x, boolean zeroIsPositive=false)
{
   if( x == 0 || (double)x == 0.0 ) {
      return zeroIsPositive ? 1 : 0;
   }
   return ( x / abs(x) );
}

/**
 * Cancels the command currently executing.  If you write
 * macros which use the {@link get_event} procedure, be sure to
 * call the procedure {@link iscancel}, or {@link islist_cancel} to check
 * whether the user has selected to abort.
 *
 * @categories Miscellaneous_Functions
 */
_command void abort() name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      _cmdline.set_command('',1,1);
   }
   if ( command_state() && ! def_stay_on_cmdline ) command_toggle();

   // Whole-saled from cmdline_toggle() to handle hitting Ctrl+g to dismiss
   // a dialog.
   if (!p_mdi_child && !p_DockingArea && p_object==OI_EDITOR) {
      boolean emacs_abort=((def_keys=='gnuemacs-keys' || def_keys=='emacs-keys') && last_event():==C_G);
      if (last_event():==ESC || last_event():==A_F4 || emacs_abort ) {
         last_event(ESC);
         call_event(defeventtab _ainh_dlg_manager,last_event(),'e');
      }
   }

   cancel();
   _deselect();
}
/**
 * Indicates whether a key is considered a cancel key.
 *
 * @param key  A string key returned from {@link get_event}(), {@link test_event}(), or {@link last_event}().
 *
 * @return Returns <b>true</b> if key:==ESC or key is bound to the command {@link abort}.
 * @see islist_cancel
 * @see cancel_key_index
 *
 * @categories Keyboard_Functions
 *
 */
_str iscancel(_str key)
{

  int index=eventtab_index(_default_keys,
              (p_HasBuffer)?p_mode_eventtab: _edit_window().p_mode_eventtab,
                       event2index(key));
  return(key:==ESC || name_name(index)=='abort');

}
/**
 * @return Returns <b>true</b> if <i>key</i>:==ESC, <i>key</i> is bound to
 * the command <b>abort</b>, or <i>key</i> is bound to the command quit.
 *
 * @see iscancel
 * @see cancel_key_index
 *
 * @categories Keyboard_Functions
 *
 */
boolean islist_cancel(_str key)
{

  int index=eventtab_index(_default_keys,
              (p_HasBuffer)?p_mode_eventtab: _edit_window().p_mode_eventtab,
                   event2index(key));
  return(iscancel(key) || name_name(index)=='quit' || name_name(index)=='pquit');

}
void _maybe_reduce_retrieve()
{
   if (p_Noflines<=MAX_RETRIEVE_LINES) return;
   int diff=p_Noflines-MAX_RETRIEVE_LINES;
   if (diff<10) {
      diff=10;
   }
   top();
   int i;
   for (i=1; i<=diff ; ++i) {
      _delete_line();
   }
   bottom();
}
/**
 * Appends command at the end of the ".command" retrieve buffer
 * if command is different from the last line.   Specify a force_insert
 * that is not "", if you always want command appended.
 *
 * @categories Retrieve_Functions
 */
void append_retrieve_command(_str command, _str force_insert="")
{
  int view_id=0;
  get_window_id(view_id);
  activate_window(VSWID_RETRIEVE);
  bottom();
  if ( force_insert!='' ) {
     insert_line(command);
  } else {
     _str line="";
     get_line(line);
     if ( line=='' && p_line==1 ) {
       replace_line(command);
     } else {
       if ( line!=command ) {
         insert_line(command);
       }
     }
  }
  _maybe_reduce_retrieve();
  int col=0;
  int left_edge=0;
  _cmdline.get_command(command,col,left_edge);
  _cmdline.set_command('');
  execute();
  _cmdline.set_command(command,col,left_edge);
  activate_window(view_id);   /* activate top ring and empty file. */

}
/**
 * @return Returns <i>cmdline</i> without words that start with the characters '-',
 * '+', or '['.  The variable <i>Options</i> is set to stripped option words.
 *
 * @categories String_Functions
 *
 */
_str strip_options(_str name,_str &options,boolean StripLeadingOnly=false,boolean IgnoreQuotedStrings=false)
{
   _str ch='';
   _str result='';
   if (StripLeadingOnly) {
      options='';
      result=name;
      for (;;) {
         result=strip(result);
         ch=substr(result,1,1);
         if ( ch!='+' && ch!='-' && ch!='[' ) {
            return(result);
         }
         _str curOption='';
         parse result with curOption result;
         if (options=="") {
            options=curOption;
         } else {
            options=options:+' 'curOption;
         }
      }
   }
   options='';
   result='';
   for (;;) {
      if ( name=='' ) {
         return(strip(result));
      }
      // Skip leading spaces
      int k=pos('[~ ]',name,1,"r");

      if( IgnoreQuotedStrings && substr(name,k,1)=='"' ) {
         // Find the end of the string
         int j=pos('"',name,k+1,'e');
         while( j ) {
            if( j>2 && substr(name,j-1,1)=='\\' ) {
               // Escaped double-quote, so ignore
               j=pos('"',name,j+1,'e');
               continue;
            }
            result=result:+substr(name,1,j);
            name=substr(name,j+1);
            break;
         }
         // If j==0, then there was no ending quote.
         // Fall through and process as normal.
      }

      _str word='';
      int i=pos(' ',name,k);
      if (!i) {
         word=name;
         name="";
      } else {
         word=substr(name,1,i-1);
         name=substr(name,i);
      }
      //messageNwait("strip_options: word="word" name="name" len="length(spaces));
      //parse name with word name ;
      ch=substr(word,k,1);
      if ( ch!='+' && ch!='-' && ch!='[' ) {
         result=result:+word;
      } else {
         options=strip(options:+word);
      }
   }
}
/**
 * This procedure returns <b>true</b> if <i>filename</i> is a root directory
 * on a UNC network.
 *
 * @categories File_Functions
 *
 */
boolean isunc_root(_str name,...)
{
#if __UNIX__
   return(0);
#elif __PCDOS__
   _str prefix='', server='', share_name='', rest='';
   parse name with prefix '\\' server '\' share_name '\' rest ;
   //  Test for existance option?
   if (0 && arg(2)!='') {
      if (file_match('-p +d \\'server'\'share_name'\'ALLFILES_RE,1)=='') {
         return(0);
      }
   }
   // Used == instead of :== on prefix intentionally to
   // be more forgiving about spaces
   return(prefix=='' && share_name:!='' && rest:=='');
#else
   What about this os
#endif
}
/**
 * @return Returns non-zero string if filename is a drive or directory
 * specification.  If the '1' option is given, filename is returned in correct
 * format for appending '*.*' (UNIX: '*') or any file list specification.
 *
 * @categories File_Functions
 *
 */
_str isdirectory(_str name, _str appendFileSep="")
{
  name=translate(name,FILESEP,FILESEP2);
  /* remove any options that are present in name */
  _str options='';
  name=strip(strip_options(name,options,true),'B','"');
  if ( name=='' ) {
     return(options' ');
  }
  _str new_name='';
  _str temp=_strip_filename(name,'p');
  if (temp=='.' || temp=='..' ) {
     new_name=_strip_filename(absolute(name:+FILESEP:+ALLFILES_RE),'n');
  } else {
     new_name=absolute(name);
  }
  if (new_name!='') name=new_name;
  if ( appendFileSep=='1' ) {
    if ( last_char(name)!=FILESEP && ! isdrive(name) ) {
      return(strip(options " "name:+FILESEP));
    }
    return(strip(options " "name));
  }
  if ( isdrive(name) || name==FILESEP ||  /* d: or d:\ or \ or . or .. ? */
     (length(name)==3 &&
     substr(name,3,1):==FILESEP &&
     isdrive(substr(name,1,2))) || _strip_filename(name,'p')=='.' || _strip_filename(name,'p')=='..' ||
     isunc_root(name,1) ) {
    return(name);
  } else {
    name=strip(name);
    if ( last_char(name)==FILESEP && !_DataSetIsFile(name)) {
      name=substr(name,1,length(name)-1);
    }
    if ( iswildcard(name) && !file_exists(name) ) {
       return(0);
    }
    name=file_match('-p +h 'maybe_quote_filename(name),1);
    if ( name=='' || last_char(name):!=FILESEP ) {
      return(0);
    }
    return(strip(options " "maybe_quote_filename(name)));
  }
}

/**
 * Determine whether directory is empty.
 * <p>
 * If the directory passed in is garbage, then false is returned.
 * <p>
 * As with isdirectory(), prepending options to the directory name is valid.
 * <p>
 * IMPORTANT: <br>
 * It is NOT safe to call this function while in a find first/next loop
 * (e.g. file_match) since this function also calls file_match() and
 * calls to file_match() are not stackable.
 *
 * @param dir Directory to test for emptiness.
 * @param includeHidden (optional) Set to true if you want the existence of
 *                      hidden files/directories checked.
 *                      Defaults to false.
 * @param recurse       (optional). Set to true if you want to recurse
 *                      subdirectories. This means that you do not want to
 *                      count subdirectories in the emptiness check unless
 *                      those subdirectories have non-subdirectory contents.
 *                      Defaults to false.
 *
 * @return true if directory is empty.
 */
boolean isDirectoryEmpty(_str dir, boolean includeHidden=false, boolean recurse=false)
{
   dir=isdirectory(dir,1);
   if( last_char(dir) != FILESEP ) {
      // ???
      return false;
   }
   _str options;
   dir=strip(strip_options(dir,options,true),'B','"');
   _str hidden = includeHidden ? "+H" : "-H";
   _str tree = recurse ? "+T" : "-T";
   _str includedirs = recurse ? "-D" : "+D";
   _str result = file_match(maybe_quote_filename(dir:+ALLFILES_RE)' -X +S -P -V 'hidden' 'tree' 'includedirs,1);
   while( result!="" ) {
      if( last_char(result)==FILESEP && result!=".":+FILESEP && result!="..":+FILESEP ) {
         // Found a directory
         _str name = substr(result,1,length(result)-1);
         name=substr(name,lastpos(FILESEP,name)+1);
         if( name!="." && name!=".." ) {
            // Found a directory
            return false;
         }
      } else {
         // Found a file
         return false;
      }
      result = file_match(maybe_quote_filename(dir:+ALLFILES_RE)' -X +D +S -P -V 'hidden,0);
   }
   // If we got here, then the directory was empty
   return true;
}

/**
 * @return Returns <b>true</b> if <i>string</i> is of the format <i>d</i>:
 * where <i>d</i> is the drive.
 *
 * @categories File_Functions
 *
 */
boolean isdrive(_str name)
{
#if __UNIX__
   return(0);
#else
   name=strip(name);
   return(_Substr(name,2,1)==':' && length(name)==2);
#endif
}
// Count the number of qualifiers in the specified data set name.
//
//    //q0.q1.q2.q3.q4.q5      ==> 6
//    //q0.q1.q2.q3.q4.q5/mem  ==> 6
//    /datasets/ds.name/mem    ==> 2
//
// Retn: # of qualifiers
int _DataSetQualifierCount(_str dsname)
{
   _str qualifier = "";
   int count = 0;
   _str dsnameonly = _DataSetNameOnly(dsname);
   while (dsnameonly != "") {
      parse dsnameonly with qualifier'.'dsnameonly;
      if (qualifier == "") break;
      count++;
   }
   return(count);
}
// Extract the qualifier at the specified position from the specified data set name.
// Position 0 indicates the first qualifier.
// Position -1 indicates the last qualifier.
//
//    //q0.q1.q2.q3.q4.q5      ==> pos 0 is "q0", pos 5 is "q1", pos -1 is "q5"
//    //q0.q1.q2.q3.q4.q5/mem  ==> pos 0 is "q0", pos 5 is "q1", pos -1 is "q5"
//
// Retn: qualifier, "" for none
_str _DataSetQualifier(_str dsname, int qualifierPos)
{
   _str qualifier = "";
   _str lastQualifier = "";
   int count = 0;
   _str dsnameonly = _DataSetNameOnly(dsname);
   while (dsnameonly != "") {
      parse dsnameonly with qualifier'.'dsnameonly;
      if (qualifier == "") break;
      if (qualifierPos == count) return(qualifier);
      lastQualifier = qualifier;
      count++;
   }
   if (qualifierPos < 0) return(lastQualifier);
   return("");
}
// Extract the first "qcount" qualifiers from the specified data set name.
//
//    //q0.q1.q2.q3.q4.q5      ==> first 2 is "q0.q1", first 0 is ""
//    //q0.q1.q2.q3.q4.q5/mem  ==> first 10 is "q0.q1.q2.q3.q4.q5"
//
// Retn: qualifiers, "" for none
_str _DataSetFirstQualifiers(_str dsname, int qcount)
{
   if (qcount < 1) return(""); // special case
   _str result = "";
   _str qualifier = "";
   int count = 0;
   _str dsnameonly = _DataSetNameOnly(dsname);
   while (dsnameonly != "") {
      parse dsnameonly with qualifier'.'dsnameonly;
      if (qualifier == "") break;
      if (result != "") result = result :+ ".";
      result = result :+ qualifier;
      count++;
      if (qcount == count) return(result);
   }
   return(result);
}

/**
 * @return Returns <i>filename</i> with part stripped.  P=Path, D=Drive,
 * E=Extension, N=Name.
 *
 * @categories File_Functions, String_Functions
 * 
 * @deprecated Use _strip_filename()
 */
_str strip_filename(_str name,_str options)
{
   return _strip_filename(name,options);
}

//////////////////////////////////////////////////////////////////////////
_str strip_names(_str filename,int count)
{
   while (count-->0) {
      if (last_char(filename)==FILESEP) {
         filename=substr(filename,1,length(filename)-1);
      }
      filename=_strip_filename(filename,'N');
   }
   return(filename);
}


/**
 * @return  Returns date of <i>filename</i> in the form <i>dd</i>-<i>mm</i>-
 * <i>yy</i>.  <i>dd</i> will start with a space if it is less than 10.
 * <i>mm</i> will start with a 0 if it is less than 10.
 *
 * @see _file_date
 * @categories File_Functions
 */
_str file_date(_str filename)
{
  return(file_list_field(filename,DIR_DATE_COL,DIR_DATE_WIDTH));

}

/**
 * @return  Returns time of <i>filename</i> in the format of the Visual
 * SlickEdit file manager. '' is returned if <i>filename</i> is not found.
 * @categories File_Functions
 */
_str file_time(_str filename)
{
  return(file_list_field(filename,DIR_TIME_COL,DIR_TIME_WIDTH));

}


/**
 * @return  Returns the size, date, time or attributes/permissions for the
 * filename specified.  <i>col</i> is one of the constants DIR_SIZE_COL,
 * DIR_DATE_COL, DIR_TIME_COL, or DIR_ATTR_COL from "slick.sh".  <i>width</i> is
 * one of the constants DIR_DATE_WIDTH, DIR_TIME_WIDTH, DIR_ATTR_WIDTH, or
 * DIR_SIZE_WIDTH from "slick.sh".  If file is not found or error occurs, '' is
 * returned.
 *
 * @see file_time
 * @see file_date
 * @categories File_Functions
 */
_str file_list_field(_str filename,int col,int width)
{
  /* list read only, directory, hidden, and system files*/
  _str line=file_match('-p +VRHSD 'maybe_quote_filename(filename),1);
  return(strip(substr(line,col,width)));

}
/**
 * This function is identical to the <b>length</b> function, except that
 * the input string is converted to the same format as the buffers raw data
 * before the return result is computed.  See "<b>Unicode and
 * SBCS/DBCS Macro Programming</b>".
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 *
 */
int _rawLength(_str &text)
{
   if (p_HasBuffer) {
      if (p_UTF8) {
         return(length(text));
      }
      return(length(_UTF8ToMultiByte(text)));
   }
   _assert(false,"_rawLength was called when no buffer was active");
   if (p_UTF8) {
      return(length(text));
   }
   return(length(_UTF8ToMultiByte(text)));
}
/**
 * @return Returns part of the input <i>string</i> converted to the same format as
 * the buffers raw data.  See "Unicode and SBCS/DBCS Macro
 * Programming."
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, String_Functions
 *
 */
_str _rawText(_str &text)
{
   if (p_HasBuffer) {
      if (p_UTF8) {
         return(text);
      }
      return(_UTF8ToMultiByte(text));
   }
   _assert(false,"_rawText was called when no buffer was active");
   if (_UTF8()) {
      return(text);
   }
   return(_UTF8ToMultiByte(text));
}
/**
 * @return Returns part of the input <i>string</i> starting from <i>StartCol</i>
 * including the rest of the string or <i>Width</i> characters if specified.
 * The input string is converted to the same format as the buffers raw
 * data before the return result is computed.  See "Unicode and
 * SBCS/DBCS Macro Programming."  This function is identical to the
 * <b>substr</b> function except when a double byte or UTF-8 sequence
 * is bisected, the remaining bisected characters are replaced with zeros.
 * This function does not yet support the <i>pad</i> argument.
 *
 * @example
 * <pre>
 *         // This will always mismatch if the character at index 5 is part of a
 * DBCS
 *         // or UTF-8 sequence.
 *         if (_rawSubstr(string,5,1)=='+') {
 *              ...
 *         }
 * </pre>
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 *
 */
_str _rawSubstr(_str &string,int StartCol,int Width=-1)
{
   if (_UTF8()) {
      if (Width<0) {
         return(substr(_rawText(string),StartCol));
      }
      return(substr(_rawText(string),StartCol,Width));
   }
   return(_dbcsSubstr(_rawText(string),StartCol,Width));
}
_str _Substr(_str &string,int StartCol,int Width=-1)
{
   if (_UTF8()) {
      if (Width<0) {
         return(substr(string,StartCol));
      }
      return(substr(string,StartCol,Width));
   }
   return(_dbcsSubstr(string,StartCol,Width));
}

_str _CharLength(_str string, boolean beginComposite=false)
{
   int Nofchars = 0;
   int StartCol = 1;
   int len = length(string);
   if( _UTF8() ) {
      // UTF-8 case
      while( StartCol<=len ) {
         int charLen;
         _strBeginChar(string,StartCol,charLen,beginComposite);
         StartCol+=charLen;
         ++Nofchars;
      }
      return Nofchars;
   }

   // SBCS/DBCS case
   int charLen;
   _str ch;
   while( StartCol<=len ) {
      charLen=1;
      ch=substr(string,StartCol,1);
      if( _dbcsIsLeadByte(ch) && StartCol<len ) {
         charLen=2;
      }
      StartCol+=charLen;
      ++Nofchars;
   }
   return Nofchars;
}

/**
 * Return Nofchars characters from string, starting
 * at StartCol. This function automatically handles
 * SBCS/DBCS and Unicode characters.
 * <P>
 * A UTF-8 sequence counts as 1 character.
 * <P>
 * When beginComposite=true, then a multi-UTF-8 sequence representing
 * a composite character counts as 1 character.
 * <P>
 * A DBCS sequence counts as 1 character.
 * <P>
 * <B>Please note:</B><BR>
 * StartCol must not bisect a DBCS or UTF-8 sequence.
 *
 * @param string
 * @param StartCol
 * @param Nofchars
 * @param beginComposite
 * @return Nofchars characters.
 */
_str _SubstrChars(_str &string,int StartCol,int Nofchars=-1,boolean beginComposite=0)
{
   int charLen=0;
   _str ch='';
   _str result;

   result="";
   int i=0, len=length(string);
   if( _UTF8() ) {
      // UTF-8 case
      if( Nofchars<0 ) {
         return(substr(string,StartCol));
      }
      for( i=0;i<Nofchars;++i ) {
         if( StartCol>len ) break;
         _strBeginChar(string,StartCol,charLen,beginComposite);
         ch=substr(string,StartCol,charLen);
         result=result:+substr(string,StartCol,charLen);
         StartCol+=charLen;
      }
      return(result);
   }

   // SBCS/DBCS case
   if( Nofchars<0 ) {
      return(_dbcsSubstr(string,StartCol));
   }
   for( i=0;i<Nofchars;++i ) {
      if( StartCol>len ) break;
      charLen=1;
      ch=substr(string,StartCol,1);
      if( _dbcsIsLeadByte(ch) && StartCol<len ) {
         charLen=2;
      }
      result=result:+substr(string,StartCol,charLen);
      StartCol+=charLen;
   }
   return(result);
}

/**
 * @return  Returns part of the input <i>string</i> starting from <i>StartCol</i>
 * including the rest of the string or <i>Width</i> characters if specified.
 * This function is identical to the <b>substr</b> function except when double
 * byte characters are bisected, they are replaced with zeros.  This function
 * does not yet support the <i>pad</i> argument.
 *
 * @example
 * <pre>
 *         // This will always mismatch if index 5 is the first or second character of
 *         // a double byte character.
 *         if (_dbcsSubstr(string,5,1)=='+') {
 *              ...
 *         }
 * </pre>
 * @see _dbcs
 * @see _dbcsIsLeadByte
 * @see _dbcsStartOfDBCS
 * @categories String_Functions
 */
_str _dbcsSubstr(_str string,int StartCol,typeless Width="")
{
   if (Width=="" || Width== -1) {
      Width=length(string)-StartCol+1;
      if (Width<0) Width=0;
   }
   _str result=substr(string,StartCol,Width);
   if (!_dbcsStartOfDBCS(string,StartCol)) {
       result= _chr(0):+substr(result,2);
   }
   if(Width>=2 && !_dbcsStartOfDBCS(string,StartCol+Width-1)) {
      result=substr(result,1,length(result)-1):+_chr(0);
   }
   return(result);
}
boolean _IsLeadByteBuf(_str ch)
{
   if (p_UTF8) {
      return(0);
   }
   return(_dbcsIsLeadByte(ch));
}
boolean _dbcsIsLeadByteBuf(_str ch)
{
   if (p_UTF8) {
      return(0);
   }
   return(_dbcsIsLeadByte(ch));
}
/*
boolean _dbcsStartOfDBCSCol(int col)
{
   return(_StartOfDBCSCol(col));
}
*/
boolean _StartOfDBCSCol(int col)
{
   if (p_UTF8 || !_dbcs()) return(true);
   if (col<=1 || col>_text_colc()) {
      return(true);
   }
   int orig_col=p_col;
   p_col=col;

   int count;
   count=0;
   --p_col;if(_text_colc(p_col,'T')<0) left();
   ++count;
   // IF previous character is not a DBCS lead byte
   if (!_dbcsIsLeadByte(get_text_raw(1))) {
      p_col=orig_col;
      return(1);
   }
   // While we have a lead byte.
   for (;;) {
      if (col<=1) {
         p_col=orig_col;
         return((count&1)?false:true);
      }
      --p_col;if(_text_colc(p_col,'T')<0) left();
      ++count;
      if (!_dbcsIsLeadByte(get_text_raw(1))) {
         p_col=orig_col;
         return((count&1)?true:false);
      }
   }
}
boolean _StartOfDBCS(_str &string,int i)
{
   if (_UTF8()) return(true);
   return(_dbcsStartOfDBCS(string,i));
}


/**
 * @return  Returns <b>true</b> if the character at <i>Index</i> in string is
 * the start of a single or double byte character.
 *
 * @see _dbcs
 * @see _dbcsIsLeadByte
 * @see _dbcsSubstr
 *
 * @categories String_Functions
 */
boolean _dbcsStartOfDBCS(_str &string,int i)
{
   if (!_dbcs()) return(true);
   int count;
   count=0;
   if (i<=1 || i>length(string)) {
      return(true);
   }
   --i;++count;
   // IF previous character is not a DBCS lead byte
   if (!_dbcsIsLeadByte(substr(string,i,1))) {
      return(1);
   }
   // While we have a lead byte.
   for (;;) {
      if (i<=1) {
         return((count&1)?false:true);
      }
      --i;++count;
      if (!_dbcsIsLeadByte(substr(string,i,1))) {
         return((count&1)?true:false);
      }
   }
}
_str first_char(_str string)
{
   if ( string:=='' || length(string) <= 0) { return(''); }
   if (!_UTF8() && !_dbcsStartOfDBCS(string,length(string))) {
      return(_chr(0));
   }
   return(substr(string,1,1));

}
/**
 * @return Returns last character of <i>string</i>.  If string is null, the
 * space character is returned.
 *
 * @categories String_Functions
 *
 */
_str last_char(_str string)
{
   if ( string:=='' ) { return(''); }
   if (!_UTF8() && !_dbcsStartOfDBCS(string,length(string))) {
      return(_chr(0));
   }
   return(substr(string,length(string),1));

}
_str raw_last_char(_str &string)
{
   if ( string:=='' ) return('');
   if (!p_UTF8 && !_dbcsStartOfDBCS(string,length(string))) {
      return(_chr(0));
   }
   return(substr(string,length(string),1));

}


/**
 * @return  Returns <i>string</i> padded with trailing spaces to <i>width</i>
 * characters.  If length of <i>string</i> is greater or equal to <i>width</i>
 * characters, <i>string</i> is padded with one space.
 * @categories String_Functions
 */
_str field(_str string,int width)
{
  if ( length(string)>=width ) {
     return(string:+' ');
  }
  return(substr(string,1,width));
}
/**
 * @return The character to the left of the cursor. This is equivelent
 *         to "left(); get_text();" without moving the cursor.
 * @see get_text()
 */
_str get_text_left(int count=1)
{
   return get_text(count, _nrseek()-1);
}
/**
 * @return The character to the right of the cursor. This is equivelent
 *         to "right(); get_text();" without moving the cursor.
 * @see get_text()
 */
_str get_text_right(int count=1)
{
   return get_text(count, _nrseek()+1);
}
/**
 * @return Contents of n'th tagged expression of last search performed.
 * @param n tagged expression number, between 0 and 9.  If left to default
 *        (empty string), returns the entire string match.
 *
 * @see match_length
 * @see get_text
 * @see search
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str get_match_text(_str n='')
{
   return get_text(match_length(n),match_length('S'n));
}

/**
 * @return Contents of n'th tagged expression of last
 *         <code>pos</code> or <code>lastpos</code> performed.
 * @param n tagged expression number, between 0 and 9.
 *        If left to default (empty string), returns the entire string match.
 *
 * @see pos
 * @see lastpos
 * @see substr
 *
 * @categories String_Functions
 */
_str get_match_substr(_str s, _str n='')
{
   return substr(s,pos('S'n),pos(n));
}

/**
 * Pull prefix off of prefixexp until matching bracket, paren, or lt/gt.
 *
 * @param prefixexp (reference) prefix expression
 * @param parenexp  (reference) set to contents of paren expression
 * @param num_args  (reference) set to number of args in expression
 * @param start_close_seperator
 *                  seperator used for start and close of expression
 *
 * @return true on success, false if it fails to find paren match
 */
boolean match_generic(_str &prefixexp, _str &parenexp, int &num_args, _str start_close_seperator)
{
   //say("match_generic()");
   _str start_char = substr(start_close_seperator, 1, 1);
   _str close_char = substr(start_close_seperator, 2, 1);
   _str seperator  = substr(start_close_seperator, 3, 1);
   int nesting = 1;
   parenexp = '';
   num_args=1;
   prefixexp = strip(prefixexp,'L');
   int p;
   for (p=1;;p++) {
      _str ch = substr(prefixexp, p, 1);
      //say("match_generic: prefixexp="prefixexp" ch="ch);
      if (ch:==start_char) {
         //say("found start char");
         nesting++;
      } else if (ch:==close_char) {
         //say("found close char");
         nesting--;
         if (!nesting) {
            p--;
            break;
         }
      } else if (ch:==seperator) {
         //say("found seperator");
         if (nesting==1) {
            num_args++;
         }
      } else {
         int np = pos(":q|'\\*?'|:v|?", prefixexp, p, 'r');
         if (!np) {
            num_args=0;
            prefixexp = substr(prefixexp, p);
            return false;
         }
         p = np + pos('') - 1;
      }
   }
   if (p<=0) {
      num_args--;
   } else {
      parenexp = substr(prefixexp, 1, p);
   }
   prefixexp = substr(prefixexp, p+2);
   return true;
}
/**
 * Extract a parenthesized expression from the beginning of the
 * given prefix expression and find the number of arguments in
 * the expression.  Assumes regular paren chars and that arguments
 * are separated by commas.
 *
 * @param prefixexp      (reference) prefix expression
 * @param parenexp       (reference) set to contents of paren expression
 * @param num_args       (reference) set to number of args in expression
 *
 * @return true on success, false if it fails to find paren match
 *
 * @example
 * <PRE>
 *   INPUT:  prefixexp=(a,b,c,d).createNewObject()
 *   OUTPUT: prefixexp=.createNewObject()
 *           parenexp=a,b,c,d
 *           num_args=4
 * </PRE>
 */
boolean match_parens(_str &prefixexp, _str &parenexp, int &num_args)
{
   return match_generic(prefixexp, parenexp, num_args, '(),');
}
/**
 * Extract a template arguments expression from the beginning of the
 * given prefix expression and find the number of arguments in the
 * expression.  Assume C++ style "<" and ">" paren chars and that
 * arguments are separated by commas.
 *
 * @param prefixexp      (reference) prefix expression
 * @param template_args  (reference) set to contents of paren expression
 *
 * @return true on success, false if it fails to find paren match
 *
 * @example
 * <PRE>
 *   INPUT:  prefixexp=&lt;tm,int&gt;.createNewObject()
 *   OUTPUT: prefixexp=.createNewObject()
 *           template_args=[tm,int]
 * </PRE>
 */
boolean match_templates(_str &prefixexp, _str (&template_parms)[])
{
   _str parenexp = '';
   int num_args = 0;
   _str delimeters = _LanguageInheritsFrom('d')? "(),":"<>,";
   boolean result = match_generic(prefixexp, parenexp, num_args, delimeters);
   template_parms._makeempty();
   if (result) {
      int  arg_pos  = 0;
      _str argument = '';
      while (tag_get_next_argument(parenexp, arg_pos, argument) >= 0) {
         //say("cb_next_arg returns "argument);
         template_parms[template_parms._length()] = argument;
      }
   }
   return result;
}
/**
 * Extract a bracketted expression from the beginning of the
 * given prefix expression and find the number of arguments in
 * the expression.  Assumes regular bracket chars and that arguments
 * are separated by commas.
 *
 * @param prefixexp      (reference) prefix expression
 * @param parenexp       (reference) set to contents of paren expression
 * @param num_args       (reference) set to number of args in expression
 *
 * @return true on success, false if it fails to find paren match
 *
 * @example
 * <PRE>
 *   INPUT:  prefixexp=[32].str->length();
 *   OUTPUT: prefixexp=.str->length();
 *           parenexp=32
 *           num_args=1
 * </PRE>
 */
boolean match_brackets(_str &prefixexp, int &num_args)
{
   _str parenexp='';
   return match_generic(prefixexp, parenexp, num_args, '[],');
}

/**
 * @categories String_Functions
 * @param name   key to search for
 * @param string string to search within
 * @param preserveCase
 *               whether to preserve the case of the returned
 *               value (as it is in the string)
 *
 * @return Returns word in <i>namesNvalues</i> to right of the string
 *         expression (lowcase(<i>name</i>)'='). Now that Slick-C has arrays and hash
 *         tables, you don't need to use this function.
 */
typeless eq_name2value(_str name,_str string,boolean preserveCase = false)
{
  if ( name=='' ) return('');

  if (!preserveCase) {
     name=lowcase(name);
     string=lowcase(string);
  }

  _str search_name=' 'name:+'=';
  _str number='', rest='';
  parse string with (search_name),'i' number rest;
  if ( number=='' ) {   /* could be first one. */
     _str first_name='';
     parse string with first_name '=' number rest ;
     if ( first_name!=name ) {
        number='';
     }
  }

  return(number);

}
/**
 * @return  Returns word in <i>namesNvalues</i> to left of the string
 * expression ('='<i>value</i>).  Now that Slick-C has arrays and hash tables,
 * you don't need to use this function.
 * @categories String_Functions
 */
_str eq_value2name(_str nv,_str string)
{
  _str prefix_string='';
  parse string with prefix_string ('='nv),'i' . ;
  int i=lastpos(' ',prefix_string);
  if ( ! i ) { i=0; }
  return(substr(prefix_string,i+1,length(prefix_string)-i));
}
/**
 * Makes sure that the entire form can be seen on the display.
 *
 * @appliesTo Form
 *
 * @categories Form_Methods
 *
 */
void _show_entire_form()
{
   int x=0, y=0, form_width=0, form_height=0;
   _get_window(x,y,form_width,form_height,'O' /*get outer window rect if possible */);

   // no need to convert, since O option always returns pixels
// _lxy2dxy(p_xyscale_mode,x,y);
// _lxy2dxy(p_xyscale_mode,form_width,form_height);
   int screen_x=0, screen_y=0, screen_width=0, screen_height=0;
   _GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   int adjust=0;
   int orig_x=x;
   int orig_y=y;
   if (x<screen_x) {
      x=screen_x;
   } else if (x+form_width>screen_x+screen_width){
      adjust= x+form_width- (screen_x+screen_width);
      x-=adjust;
      // Move window left
      if (x<screen_x) {
         // Center to screen
         x=screen_x+((screen_width- form_width) intdiv 2);
      }
   }
   if (y<screen_y) {
      y=screen_y;
   } else if (y+form_height>screen_y+screen_height){
      adjust= y+form_height- (screen_y+screen_height);
      // Move window up
      y-=adjust;
      if (y<screen_y) {
         // Center to screen
         y=screen_y+((screen_height- form_height) intdiv 2);
      }
   }
   if (x<screen_x) x=screen_x;
   if (y<screen_y) y=screen_y;
   if (orig_x!=x || orig_y!=y) {
      _dxy2lxy(p_xyscale_mode,x,y);
      //_dxy2lxy(p_xyscale_mode,form_width,form_height);
      _move_window(x,y,p_width,p_height);
   }
}

/**
 * Centers the current window to the window specified.  If <i>centerto_wid</i>
 * is not specified, the <b>p_xyparent</b> is used.  If the current window is
 * not a form, the <i>centerto_wid</i> parameter is ignored.
 *
 * @appliesTo All_Window_Objects
 * @example
 * <pre>
 * // Normally the show primitive centers the window for you
 * // The -hidden option tells the show function not to make the form visible.
 * wid=show('-mdi -hidden -nocenter form1');
 * // Center the form to the MDI window
 * wid._center_window(_mdi);
 * // Make the form visible now.
 * wid.p_visible=1;
 * </pre>
 * @categories Check_Box_Methods, Combo_Box_Methods, Command_Button_Methods, Directory_List_Box_Methods, Drive_List_Methods, Editor_Control_Methods, File_List_Box_Methods, Form_Methods, Frame_Methods, Gauge_Methods, Hscroll_Bar_Methods, Image_Methods, Label_Methods, List_Box_Methods, Picture_Box_Methods, Radio_Button_Methods, Spin_Methods, Text_Box_Methods, Vscroll_Bar_Methods
 */
void _center_window(typeless parent="")
{
   //messageNwait('p_object='p_object' parent='p_parent' w='p_window_id);
   int parent_width=0;
   int parent_height=0;
   int screen_x=0, screen_y=0, screen_width=0, screen_height=0;
   int x=0, y=0, width=0, height=0;
   _get_window(x,y,width,height);
   if (p_object!=OI_FORM && p_object!=OI_MDI_FORM) {
      parent_width=p_parent.p_client_width;
      parent_height=p_parent.p_client_height;
      _dxy2lxy(p_xyscale_mode,parent_width,parent_height);
      x=(parent_width- p_width) intdiv 2;
      y=(parent_height- p_height) intdiv 2;
      _move_window(x,y,p_width,p_height);
      return;
   }
   if (p_object==OI_FORM) {
      if (parent!='') {
         if (parent && parent.p_object==OI_EDITOR && parent.p_IsTempEditor) {
            parent=_desktop;
         }
      } else {
         parent= p_xyparent;
      }
   } else /*if (p_object==OI_MDI_FORM)*/ {
      parent=0;
   }
   /*if (parent==_mdi && !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
      parent=_desktop;
   } */
   if (parent && parent!=_desktop && parent!=_app) {
      parent._get_window(x,y,parent_width,parent_height);
      boolean done=0;
      if (parent==_mdi && x==0 && y==0 && parent_width==0 && parent_height==0) {
         // Center to desktop
         /*
             By calling _get_window instead of checking for MDI_WINDOW
             support, we allow the capability to center a dialog
             to MDI without implementing full MDI_WINDOW support.
             Nobody does this yet.
         */
         _mdi._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
         parent_height=screen_height;parent_width=screen_width;
         _dxy2lxy(p_xyscale_mode,parent_width,parent_height);
         x=(parent_width- width) intdiv 2;
         y=(parent_height- height) intdiv 2;
      } else {
         // IF we have an editor control on a dialog box with
         //    out a center to parent, center to the editor control.
         if ((parent.p_object==OI_EDITOR || parent==_cmdline) && (!parent.p_parent || parent.p_mdi_child)) {
            if (1) {
               parent._GetOuterMostWindow(x,y,parent_width,parent_height);
               //say('x='x' y='y' w='parent_width' h='parent_height' n='parent.p_name' mc='parent.p_mdi_child);
               //_lxy2dxy(p_xyscale_mode,x,y);
               _lxy2dxy(p_xyscale_mode,width,height);
               //say('parent_height='parent_height' height='height);
               x=x+(parent_width- width) intdiv 2;
               y=y+(parent_height- height) intdiv 2;
               //say('b44444 xx='x' yy='y);
               _dxy2lxy(p_xyscale_mode,x,y);
               _dxy2lxy(p_xyscale_mode,width,height);
               //say('xx='x' yy='y);
               done=1;
            } else {
               // Need to calculate adjustment for desktop.
               int tx=0, ty=0;
               _map_xy(parent,0,tx,ty,parent.p_xyscale_mode);
               x+=tx;y+=ty;
            }
         }
         if (!done) {
            _lxy2lxy(parent.p_xyscale_mode,p_xyscale_mode,x,y);
            _lxy2lxy(parent.p_xyscale_mode,p_xyscale_mode,parent_width,parent_height);
            int parent_xyscale_mode=parent.p_xyscale_mode;
            x=x+(parent_width- width) intdiv 2;
            y=y+(parent_height- height) intdiv 2;
            _map_xy(parent.p_xyparent,p_xyparent,x,y,p_xyscale_mode);
         }
      }

   } else {
      _mdi._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
      parent_height=screen_height;parent_width=screen_width;
      _dxy2lxy(p_xyscale_mode,parent_width,parent_height);
      _dxy2lxy(p_xyscale_mode,screen_x,screen_y);
      x=screen_x+((parent_width- width) intdiv 2);
      y=screen_y+((parent_height- height) intdiv 2);

   }
   _move_window(x,y,p_width,p_height);
   _show_entire_form();
}
/**
 * @return Returns true if <i>filename</i> contains wild card characters.
 * For DOS and Windows NT, the wild card characters are '*' or '?'.  For UNIX,
 * the wild card characters are '*', '?', '[', ']', '^', '{', '}', '|', '\', or
 * '~'.
 *
 * @categories File_Functions
 *
 */
boolean iswildcard(_str filename)
{
  return(verify(filename,WILDCARD_CHARS,'M')!=0);
}
boolean iswildcard_for_any_platform(_str filename)
{
  return(verify(filename,'*?[]^\','M')!=0);
}


/**
 * Removes all key and mouse events from input queue.
 * @categories Keyboard_Functions
 */
void flush_keyboard()
{
   _FlushPendingKeys();
}

/**
 * Test if a keyboard or mouse event is available. 
 *
 * <p>
 *
 * This function does not check for MOUSE-MOVE events. If you 
 * want to check for mouse-move events, use {@link 
 * _IsEventPending}. 
 *
 * @param mouse  Set to false if you do not want to check for 
 *               mouse events. Defaults to true.
 * @param macro  Set to true if you want to check for events
 *               from recorded macro playback. Defaults to
 *               false.
 *
 * @return true if event is available.
 *
 * @see _IsEventPending
 * @see get_event
 * @see last_event
 * @see call_key
 * @see event2name
 * @see event2index
 * @see index2event
 * @see list_bindings
 * @see name2event
 * @see eventtab_index
 *
 * @categories Keyboard_Functions
 *
 */
boolean _IsKeyPending(boolean mouse=true, boolean macro=false)
{
   int flags = EVENTPENDING_KEY;
   flags |= mouse ? EVENTPENDING_MOUSE : 0;
   flags |= macro ? EVENTPENDING_MACRO : 0;
   return _IsEventPending(flags);
}

/**
 * Reads the number of lines specified in the variable
 * "<b>def_read_ahead_line</b>" after the cursor when the disk is read.
 *
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 *
 */
int read_ahead()
{
  if ( block_was_read() ) {
    typeless old_rc=rc;
    int cursor_y= p_cursor_y;
    int left_edge= p_left_edge;
    int col=p_col;
    typeless text_point=point();
    typeless line=point('L');
    down(def_read_ahead_lines);
    goto_point(text_point,line);
    set_scroll_pos(left_edge,cursor_y);
    p_col=col;
    rc=old_rc;
    block_was_read(0);
    return(1);
  } else {
    return(0);
  }


}
/**
 * Reads the number of lines specified in the variable
 * "<b>def_read_ahead_line</b>" before the cursor when the disk is
 * read.
 *
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 *
 */
int read_behind()
{
  if ( block_was_read() ) {
    typeless old_rc=rc;
    save_pos(auto p);
    up(def_read_ahead_lines);
    restore_pos(p);
    rc=old_rc;
    block_was_read(0);
    return(1);
  } else {
    return(0);
  }


}
/**
 * If <i>proc_index</i> is a valid index to a procedure that exists,
 * <i>proc_index</i> is called with no arguments.
 *
 * @see call_root_key
 *
 * @categories Miscellaneous_Functions
 *
 */
int try_calling(int index)
{
  if ( index_callable(index) ) {
     _macro('m',_macro());
     return(call_index(index));
  }
  return(0);

}
/**
 * @return Returns 'off' if <i>number</i>=="0".  Otherwise 'on' is returned.
 *
 * @categories String_Functions
 *
 */
_str number2onoff(_str number)
{
   _str result='';
   if ( number ) {
      result=nls('on');
   } else {
      result=nls('off');
   }
   return(result);

}
/**
 * Sets <i>name</i> to 1 or 0 corresponding to <i>value</i>='on' or
 * <i>value</i>='off'.
 *
 * @return Returns <b>false</b> if input value is valid.  Displays message if
 * <i>value</i> is not 'on' or 'off'.
 *
 * @categories String_Functions
 *
 */
boolean setonoff(boolean &number,_str string)
{
  _str on=nls('on');
  _str off=nls('off');
  if ( strieq(string,on) ) {
    number=true;
    return(false);
  } else if ( strieq(string,off) ) {
    number=false;
    return(false);
  }
  message(nls('Please specify %s or %s',upcase(on),upcase(off)));
  return(true);

}
/**
 * @return Returns 'N' if <i>number</i>=="0".  Otherwise 'Y' is returned.
 *
 * @categories String_Functions
 *
 */
_str number2yesno(_str number)
{
   _str result='';
   if ( number ) {
      result=nls('Y');
   } else {
      result=nls('N');
   }
   return(result);

}
void nls_yes_no(_str nls_chars,_str &yes,_str &no)
{
   nls_strip_chars(nls_chars,nls('~YES ~NO'));
   yes=substr(nls_chars,1,1);
   no=substr(nls_chars,2,1);

}
/**
 * Sets <i>name</i> to 1 or 0 corresponding to <i>value</i>='Y','Yes' or
 * <i>value</i>='N','No'.
 *
 * @return Returns <b>false</b> if input value is valid.  Displays message if
 * <i>value</i> is not 'Y', 'Yes','N', or 'No'.
 *
 * @categories String_Functions
 *
 */
boolean setyesno(boolean &number,_str string)
{
  string=upcase(string);
  _str nls_chars='';
  _str yes_msg='';
  _str no_msg='';
  parse nls_strip_chars(nls_chars,nls('~YES ~NO')) with yes_msg no_msg ;
  _str msg=nls('Please specify %s or %s',yes_msg,no_msg);
  if ( string==substr(nls_chars,1,1) || string==upcase(yes_msg) ) {
    number=true;
    return(0);
  } else if ( string==substr(nls_chars,2,1) || string==upcase(no_msg) ) {
    number=false;
    return(0);
  }
  message(msg);
  return(1);
}
/**
 * @return Returns the name of the command bound to key in the root event
 * table.
 *
 * @categories Keyboard_Functions
 *
 */
_str name_on_key(_str key)
{
   return(name_name(eventtab_index(_default_keys,_default_keys,event2index(key))));

}
/**
 * @return Returns the next command in the <i>retrieve_view_id</i> buffer.  If
 * end of buffer is reached the first command is returned.
 * <i>first_retrieve</i> is set to zero.
 *
 * @see pretrieve_prev
 * @see insert_retrieve
 *
 * @categories Retrieve_Functions
 *
 */
pretrieve_next(int retrieve_view_id,boolean &first_retrieve)
{
   if ( retrieve_view_id=='' ) {
      return('');
   }
   int view_id=0;
   get_window_id(view_id);
   activate_window(retrieve_view_id);
   down();
   if ( rc ) {
      top();
   }
   _str line='';
   get_line(line);
   activate_window(view_id);
   first_retrieve=false;
   return line;

}
/**
 * @return Returns the previous command in the <i>retrieve_view_id</i> buffer.
 * The last command is returned if <i>first_retrieve</i> is zero.  If top of
 * buffer is reached the last command is returned. <i>first_retrieve</i> is
 * set to zero.
 *
 * @see pretrieve_next
 * @see insert_retrieve
 *
 * @categories Retrieve_Functions
 *
 */
_str pretrieve_prev(int retrieve_view_id,boolean &first_retrieve)
{
   if ( retrieve_view_id=='' ) {
      return('');
   }
   int view_id=0;
   get_window_id(view_id);
   activate_window(retrieve_view_id);
   if ( ! first_retrieve ) {
      up();
      if ( rc ) {
         bottom();
      }
   } else {
      bottom();
   }
   _str line='';
   get_line(line);
   activate_window(view_id);
   first_retrieve=false;
   return line;

}
/**
 * Inserts <i>command</i> at end of retrieve buffer <i>retrieve_view_id</i>
 * if <i>command</i> is different from last line of buffer.<i>
 * first_retrieve</i> is set to 1.
 *
 * @see pretrieve_next
 * @see pretrieve_prev
 *
 * @categories Retrieve_Functions
 *
 */
void insert_retrieve(int retrieve_view_id,boolean &first_retrieve,_str line)
{
   if ( retrieve_view_id=='' ) {
      return;
   }
   int view_id=0;
   get_window_id(view_id);
   activate_window(retrieve_view_id);
   bottom();
   _str last_line='';
   get_line(last_line);
   if ( last_line!=line && line!='' ) {
      insert_line(line);
      _maybe_reduce_retrieve();
   }
   first_retrieve=true;
   activate_window(view_id);

}

/**
 * Counts the number of lines or sub-lines within the marked area identified
 * by <i>mark_id</i>.<i>  mark_id</i> is a handle to a selection returned by
 * one of the built-ins <b>_alloc_selection</b> or <b>_duplicate_selection</b>.
 * A <i>mark_id</i> of '' or no <i>mark_id</i> parameter identifies the active
 * selection.
 *
 * @return  If successful, returns number of lines or sub-lines within the
 * selection.  Otherwise, 0 is returned.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
int count_lines_in_selection(_str markid='',boolean count_nosave_lines=false)
{
   int orig_wid;
   get_window_id(orig_wid);
   int start_col=0, end_col=0, buf_id=0;
   int status=_get_selinfo(start_col,end_col,buf_id,markid);
   if (status) {
      return(0);
   }
   typeless orig_pos;
   save_pos(orig_pos);
   _str prev_select_type = '';
   if(_select_type(markid, 'S') == 'C') {
      prev_select_type = 'C';
      _select_type(markid, 'S', 'E');
   }
   activate_window(VSWID_HIDDEN);
   int orig_buf_id=p_buf_id;
   p_buf_id=buf_id;
   status=_begin_select(markid);
   if ( status ) return(0);
   int count=0;
   for (;;) {
      if (count_nosave_lines || !(_lineflags()&NOSAVE_LF)) {
         ++count;
      }
      status=down();
      if ( status || _end_select_compare(markid)>0 ) {
         break;
      }
   }
   p_buf_id=orig_buf_id;
   activate_window(orig_wid);
   restore_pos(orig_pos);
   if (prev_select_type != '') {
      _select_type(markid, 'S', prev_select_type);
   }
   return(count);
}

// Return the longest whole line in a selection
int longest_line_in_selection_raw(typeless markid="")
{
   if( markid=='' && !select_active() ) {
      _message_box('No selection active');
      return(0);
   }
   int end_col=0;
   typeless dummy=0;
   save_pos(auto p);
   boolean throw_out_last_line=0;
   if( _select_type()=='CHAR' ) {
      _get_selinfo(dummy,end_col,dummy);
      if( end_col==1 ) {
         // Throw out the last line of the character selection
         throw_out_last_line=1;
      }
   }
   typeless status=_begin_select(markid);
   if( status ) return(0);
   _str line='';
   get_line_raw(line);
   int len=length(expand_tabs(strip(line,'T')));
   for( ;; ) {
      if( down() ||
          _end_select_compare(markid)>0 ||
          (throw_out_last_line && !_end_select_compare(markid)) ) {
         break;
      }
      get_line_raw(line);
      line=expand_tabs(strip(line,'T'));
      if( length(line)>len ) {
         len=length(line);
      }
   }
   restore_pos(p);
   return(len);
}

// Using array for DBCS support.
  static _str gkeytab[]= {
     // Removed C_Backspace for so pressing C_BACKSPACE in
     // prefix area does the binding and does not insert character code 127
     PAD_SLASH,name2event('c-enter')/*,C_BACKSPACE*/,ENTER,TAB,BACKSPACE,ESC,
     PAD_PLUS,PAD_MINUS,PAD_STAR,S_END,S_DOWN,
     S_PGDN,S_LEFT,name2event('s-pad-5'),S_RIGHT,S_HOME,S_UP,
     S_PGUP,name2event('s-ins'),name2event('s-del'),
     name2event('pad-0'),
     name2event('pad-1'),
     name2event('pad-2'),
     name2event('pad-3'),
     name2event('pad-4'),
     name2event('pad-5'),
     name2event('pad-6'),
     name2event('pad-7'),
     name2event('pad-8'),
     name2event('pad-9'),
     name2event('pad-dot'),
     name2event('pad-equal'),
  };
#define ASCII_CHAR2 ('/' "\n" /*_chr(127)*/ "\r" "\t" _chr(8)_chr(27)'+-*1234567890.0123456789.=')

/**
 * @return Returns ASCII character corresponding to key.  This is useful for
 * converting keys like ENTER and TAB to the characters Ctrl+M and Ctrl+I.
 *
 * @categories Keyboard_Functions
 *
 */
_str key2ascii(_str key)
{
   if ( length(key)<2 ) {
      return(key);
   }
   int i;
   for (i=0;i<gkeytab._length();++i) {
      if (key:==gkeytab[i]) {
         break;
      }
   }
   if ( i<gkeytab._length()) {
      return(substr(ASCII_CHAR2,i+1,1));
   }
   int ki=event2index(key);
   int eventNoFlags=ki&~VSEVFLAG_ALL_SHIFT_FLAGS;
   if ( (ki&VSEVFLAG_ALL_SHIFT_FLAGS)==VSEVFLAG_CTRL &&
        eventNoFlags<128 && isalpha(_chr(eventNoFlags))
      ) {
      // Map Ctrl+A-Ctrl+Z to character codes 1..26
      return(_chr(_asc(upcase(_chr(eventNoFlags)))-_asc('A')+1));
   }
   return(key); /* May not be an ascii key.  */
}
/**
 * @return If indent with tabs is on, a string of tabs of length
 * <i>width</i> is returned.  Otherwise, a string of spaces of length
 * <i>width</i> is returned.
 *
 * @categories String_Functions
 *
 */
_str indent_string(int width)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_INDENT_WITH_TABS | AFF_TABS);
   if ( ! p_indent_with_tabs ) {
      return(substr('',1,width));
   }
   return(expand_tabs(substr('',1,width,\t),1,width,'S'));

}
/**
 * Updates the format line of the current buffer, if present, to the current
 * tab and word wrap options.  See section <b>Format Line</b> for more
 * information.
 *
 * @see read_format_line
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
update_format_line(...)
{
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      messageNwait(nls('Unable to allocate a mark.  Format line not updated.'));
      return(1);
   }
   int col=p_col;
   if ( ! _on_line0() ) {
      _select_char(mark);
   }
   top();
   _str line='';
   if (_line_length()>MAX_ATSLICK_LINE_LEN) {
      line='';
   } else {
      get_line(line);
   }
   _str before='';
   _str at_slick='';
   parse upcase(line) with before '\@SLICK( |$)','ri' +0 at_slick;
   if ( at_slick!='' && (arg(1)=='' || lastpos(',',line)<=length(before)) ) {   /* Format line present? */
      _str after='';
      int i=lastpos(',',line);
      if ( i>length(before) ) {
         after=substr(line,i+1);
      } else {
         after=substr(line,length(before)+7);
      }
      replace_line(substr(line,1,length(before))'@SLICK MA='p_margins', TABS='p_tabs', WWS='p_word_wrap_style', IWT='p_indent_with_tabs', ST='p_ShowSpecialChars', IN='p_indent_style', WC='p_word_chars','after);
   }
   if ( _select_type(mark)=='' ) {
      top();up();p_col=col;
   } else {
      _begin_select(mark);
   }
   _free_selection(mark);

/* Returns true and set tabs and margins if format line is present. */
}
/**
 * @return Returns non-zero value and sets tab and word wrap options if format
 * line is present.  See section Format Line for more information.
 *
 * @see update_format_line
 *
 * @appliesTo Edit_Window
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_str read_format_line()
{
   if ( p_buf_width ) {
      return(0);
   }
   typeless p=point();
   typeless line_num=point('l');
   int left_edge=p_left_edge;
   int cursor_y=p_cursor_y;
   int col=p_col;
   top();
   _str line='';
   if (_line_length()>MAX_ATSLICK_LINE_LEN) {
      line='';
   } else {
      get_line(line);
   }
   _str before='';
   _str at_slick='';
   typeless margins='';
   typeless tabs='';
   typeless word_wrap_style='';
   typeless indent_with_tabs='';
   typeless show_tabs='';
   typeless indent_style='';
   _str word_chars='';
   parse line with before '\@SLICK( |$)','ir' +0 at_slick 'MA='margins ',' 'TABS='tabs ',' 'WWS='word_wrap_style ',' 'IWT='indent_with_tabs ',' 'ST='show_tabs ',' 'IN='indent_style ',' 'WC='word_chars',';
   typeless status=(at_slick!='');
   if ( status ) {   /* Format line present? */
      if ( tabs!='' ) {
         p_tabs=tabs;
      }
      if ( margins!='' ) {
         p_margins=margins;
      }
      if ( word_wrap_style!='' ) {
         p_word_wrap_style=word_wrap_style;
         p_indent_with_tabs=indent_with_tabs;
         p_ShowSpecialChars=show_tabs;
      }
      if (indent_style!='') {
         p_indent_style=indent_style;
      } else {
         p_indent_style=INDENT_SMART;
      }
      if (word_chars!='') {
         p_word_chars=word_chars;
      }
   }
   goto_point(p,line_num);
   set_scroll_pos(left_edge,cursor_y);p_col=col;
   return(status);

}
/**
 * @return Saves the active selection in the variable <i>mark</i>.  Returns non-
 * zero value if a selection can not be allocated for saving the active
 * selection.
 *
 * @categories Selection_Functions
 *
 */
int save_selection(var mark)
{
   mark=_duplicate_selection('');
   typeless new_mark=_duplicate_selection();
   if ( new_mark<0 ) {
      message(get_message(TOO_MANY_SELECTIONS_RC));
      return(1);
   }
   _show_selection(new_mark);
   return(0);

}
/**
 * Restores the active mark (mark showing) to <i>mark</i>.
 * <i>mark</i> is freed.
 *
 * @see save_selection
 *
 * @categories Selection_Functions
 *
 */
void restore_selection(typeless mark)
{
   typeless cur_mark=_duplicate_selection('');
   _show_selection(mark);
   _free_selection(cur_mark);

}

/**
 * @return Returns completion information for <i>string</i>.  A string of
 * zero or more completion constants delimited with space characters is
 * returned.  If <i>string</i> starts with a '.' character, <i>string</i>
 * specifies a command.  Otherwise <i>string</i> should specify a completion
 * constant name without the "_ARG" suffix.  Completion constants have the
 * suffix "_ARG" and are listed in "slick.sh".
 *
 * @categories Completion_Functions
 *
 */
_str get_completion_info(_str command)
{
   _str completion_info='';
   command=translate(name_case(command),'-','_');
   if ( substr(command,1,1)=='.' ) {
      if ( command!='.' ) {
         int index=find_index(substr(command,2),COMMAND_TYPE);
         parse name_info(index) with completion_info ',' ;
      } else {
         completion_info='';
      }
   } else {
      completion_info=eq_name2value(stranslate(command,'','*'),COMPLETION_ARGS);
      if ( completion_info=='' ) {
         completion_info=eq_name2value(command,def_user_args);
      }
      if ( completion_info!='' && pos('*',command) ) {
         completion_info=completion_info'*';
      }
   }
   return(completion_info);

}
_str _check_tabs(_str tabs,int wid)
{
   _str old_tabs=wid.p_tabs;
   wid.p_tabs=tabs;
   typeless status=rc;
   wid.p_tabs=old_tabs;
   if (status) {
      _message_box('Invalid tab settings.');
   }
   return(status);

}

/**
 * Checkes the margin inputs.  Do not remove this method, as it is used as a 
 * callback by the gui_margins command. 
 * 
 * @return _str 
 */
_str _check_margins(_str junk)
{
   typeless left_ma=text1.p_text;
   typeless right_ma=text2.p_text;
   typeless newp_ma=text3.p_text;
   if (!isinteger(left_ma) || left_ma<1 || left_ma>MAX_LINE) {
      p_window_id=text1;_set_focus();
      _message_box('Invalid margin settings.');
      return(1);
   }
   if (!isinteger(right_ma) || right_ma<1 || right_ma>MAX_LINE) {
      p_window_id=text2;_set_focus();
      _message_box('Invalid margin settings.');
      return(1);
   }
   if (!isinteger(newp_ma) || newp_ma<1 || newp_ma>MAX_LINE) {
      p_window_id=text3;_set_focus();
      _message_box('Invalid margin settings.');
      return(1);
   }
   if (left_ma+2>right_ma) {
      p_window_id=text1;_set_focus();
      _message_box('Invalid margin settings.');
      return(1);
   }
   return(0);
}

_str _right_justify(_str string, int width)
{
   if ( length(string)>=width ) {
      return (' 'string);
   }
   return (substr('',1,width-length(string))string);
}
/**
 * Returns the canonical file extension for the given file.
 * <p>
 * If the file's actual extension extension matches an
 * <code>_[ext]_Filename2LangId()</code> callback, it will 
 * first try the callback to see if the file, based on it's 
 * path or name should be referred to an alternate extension.
 * <p> Otherwise, if the file's actual extension matches a 
 * <code>suffix_[ext]</code> callback, it will open the file
 * in a temporary view and call {@link _SetEditorLanguage} to
 * determine the file's actual language type. 
 *
 * @return Returns referred extension for buffer name, using
 *         {@link _Filename2LangId}.
 *
 * @param buf_name   file name and path to test
 *
 * @see get_extension
 * @see _Filename2LangId 
 * @see _Ext2LangId
 *
 * @categories Miscellaneous_Functions 
 * @deprecated Use {@link _Filename2LangId()} 
 */
_str _bufname2ext(_str buf_name)
{
   return _Filename2LangId(buf_name);
}
/**
 * Returns extension of buffer name without dot unless returnDot is true.
 *
 * @param buf_name  Filename to get extension from.
 * @param returnDot Specify true if you want '.' included in return value.
 * @return Returns extension of buffer name.
 *
 * @categories File_Functions 
 *  
 * @deprecated Use _get_extension() 
 */
_str get_extension(_str buf_name,boolean returnDot=false)
{
   return _get_extension(buf_name, returnDot);
}

/**
 * @return Returns <i>filename,</i> with quotes around it, if it contains a
 * space character.  Otherwise <i>filename</i> is returned.
 *
 * @categories File_Functions
 *
 */
_str maybe_quote_filename(_str filename)
{
   // '&' is a valid character in file name in both UNIX and Windows. And,
   // like embedded spaces, must also be quoted.
   filename=stranslate(filename,'','"');
   if ( pos(' ',filename) || pos('&',filename)) {
      filename='"'filename'"';
   }
   return(filename);

}

/**
 * @return Returns <i>filename,</i> with quotes removed.
 *
 * @categories File_Functions
 */
_str _unquote_filename(_str filename)
{
   if (first_char(filename)=='"') {
      if (last_char(filename)=='"') {
         return substr(filename, 2, length(filename)-2);
      } else {
         return substr(filename, 2);
      }
   }
   return filename;
}

/**
 * @returns Returns true when <i>Path</i> exists.
 *
 * @categories File_Functions
 *
 */
boolean path_exists(_str Path)
{
   _maybe_append_filesep(Path);
   _str WPath = strip(Path, "T", FILESEP);
   _str match=file_match('-p +hrsd ' :+ maybe_quote_filename(WPath),1);
   return(match!='');
}

/**
 * Returns the path from filename.  Just slightly
 * easier than calling strip_filename.
 *
 * @param filename Filename to return path from.
 *
 * @return Returns directory name that filename is in
 *
 * @categories File_Functions
 */
_str _file_path(_str filename)
{
   return(_strip_filename(filename,'N'));
}

/**
 * @return
 * Returns the path from a path.  Similar to _file_path(), but
 * handles the trailing slash and slightly easier than calling
 * strip_filename()
 *
 * @param Path   Must be a path.  If this is a filename, we will
 *               only return the path.
 *
 * @categories File_Functions
 */
_str _parent_path(_str Path)
{
   if (last_char(Path)==FILESEP) {
      Path=substr(Path,1,length(Path)-1);
   }
   Path=_strip_filename(Path,'N');
   return(Path);
}

_str _last_path(_str Path)
{
   _maybe_strip_filesep(Path);
   lastPath := _strip_filename(Path,'P');
   return lastPath;
}

/**
 * @return Parses first filename from string.
 *
 * @categories File_Functions, String_Functions
 *
 */
_str parse_file(_str &line,boolean returnQuotes=true, boolean support_single_quote=false)
{
   line=strip(line,'B');
   _str word="";
   _str ch=substr(line,1,1);
   if ( ch=='"' || (support_single_quote && ch=="'")) {
      int end_quote=pos(ch,line,2);
      if ( ! end_quote ) {
         end_quote=length(line);
      }
      word=substr(line,1,end_quote);
      line=strip(substr(line,end_quote+1),'B');
      if (returnQuotes) {
         return(word);
      }
      return(strip(word,'b',ch));
   }
   parse line with word line ;
   return(word);

}

/**
 * If the root (fundamental) event table has a command binding for <i>key</i>, the command is executed.
 * Otherwise, if <i>key</i> is length one, it is inserted into the buffer.  This function is typically
 * used for syntax expansion.
 *
 * @see  try_calling
 *
 *
 * @categories Keyboard_Functions
 */
void call_root_key(_str key)
{
   /* need this for when command_execute gets called later. */
   int index=eventtab_index(_default_keys,
                           _default_keys,event2index(key));
   if ( ! index && length(key):==1 ) {
      keyin(key);
   }
   try_calling(index);

}
_str nls_letter_prompt(_str msg)
{
   _str nls_chars='';
   msg=nls_strip_chars(nls_chars,msg);
   _str key=letter_prompt(msg,nls_chars);
   return(pos(key,nls_chars));

}
/**
 * <i>Remark</i> Displays <i>msg</i> given on message line and waits for
 * a character key contained in the <i>letters</i> argument, or the cancel key
 * to be pressed.  The letters defaults to 'YN' if not specified.
 *
 * @return Returns key pressed which caused return.  If it is one of the
 * letter keys, it is returned in upper case.
 *
 * @see get_string
 * @see prompt
 * @categories Keyboard_Functions
 *
 */
_str letter_prompt(_str msg, _str letters='')
{
   _str yes='', no='';
   letters=upcase(letters);
   if ( letters=='' ) {
      nls_yes_no(letters,yes,no);
   }
   refresh();
   message(msg);
   for (;;) {
      typeless k=get_event();
      if ( length(k)==1 ) {
         k=upcase(k);
      }
      if ( (length(k)==1 && pos(k,letters)) || iscancel(k) ) {
         clear_message();
         return(k);
      }
   }

}
_str _retrieve;

/**
 * <dl>
 * <dt>immed_return_value</dt><dd>Defaults to ''</dd>
 * <dt>msg</dt><dd>Defaults to the name of the last command
 * (_command) called</dd>
 * <dt>default_value</dt><dd>Defaults to ''</dd>
 * <dt>cursor_placement</dt><dd>Defaults to ''</dd>
 * </dl>
 *
 * <p>If the value of the macro variable "def_prompt" is not 0, this function
 * displays msg and prompts for a single argument to a command.
 * <i>default_value</i> may be specified as the user's default input
 * response.  The users response is returned.  If the user has selected to
 * abort, execution is stopped unless a menu is currently displayed on
 * screen.  If <i>immed_return_value</i> is given and not '', its value is
 * immediately returned.</p>
 *
 * <p>If the value of the macro variable "def_prompt" is 0, this function
 * places msg followed by <i>default_value</i> on the command line
 * and stops.  If <i>immed_return_value</i> is given and not '', its value
 * is immediately returned.</p>
 *
 * @see letter_prompt
 * @see get_string
 *
 * @categories Keyboard_Functions
 *
 */
_str prompt(_str arg1='', _str msg='', ...)
{
   _str cmd_name=name_name(last_index('','C'));
   if ( arg1!='' ) {
      return(arg1);
   }
   _str line='';
   if ( ! def_prompt && ! _in_help ) {
      line=cmd_name' 'arg(3);
      command_put(line);
      if ( arg(4)!='' ) {
         set_command(line' ',length(cmd_name)+2);
      }
      stop();
   }
   if ( msg=='' ) {
      msg=cmd_name;
      msg=upcase(substr(msg,1,1)):+substr(msg,2);
   }
   // Removed this because using alias_cd in Shell tab
   // changes focus to mdi window
   /*
   if ( ! def_stay_on_cmdline ) {
      cursor_data();
   } */
   _retrieve=arg()<3;
   _macro_delete_line();
   typeless status=get_string(line,msg': ','-.'cmd_name,arg(3));
   if ( status ) {
      if ( _in_help ) {
         line='';
      } else {
         stop();
      }
   }
   // defect #13320
   if (def_unix_expansion) {
      line = substr(_maybe_unix_expansion(cmd_name' 'line), length(cmd_name)+2);
   }
   _macro_call(translate(cmd_name,'_','-'),line);
   return(line);

}

/**
 * 
 * Presents a 'save changes to...?' message box, with 
 * platform-specific adjustments for the style. 
 * Windows and Unix platforms use Yes/No/Cancel buttons, with a 
 * question mark icon. 
 * Mac shows Save/Don't Save/Cancel buttons, with the default 
 * application icon. 
 * 
 * @param msg Prompt string for the message box 
 * @param title Title for the message box. Not displayed on Mac. 
 * @param cxlButton If true, show a cancel button. If false, 
 *                  only the 'Yes' and 'No' (or 'Save' and
 *                  'Don't Save') buttons are shown.
 * 
 * @return IDYES, IDNO, or IDCANCEL
 */
int prompt_for_save(_str msg, _str title='', boolean cxlButton = true)
{
    int result=IDCANCEL;
    int mbFlags = 0;
    if(_isMac() && def_mac_save_prompt_style) {
       if(cxlButton) {
           mbFlags = MB_SAVEDISCARDCANCEL;
       } else {
           mbFlags = MB_SAVEDISCARD;
       }
    } else {
       if(cxlButton) {
           mbFlags = MB_YESNOCANCEL|MB_ICONQUESTION;
       } else {
           mbFlags = MB_YESNO|MB_ICONQUESTION;
       }
    }
    result=_message_box(msg,title,mbFlags);
    if(result == IDSAVE) {
       result = IDYES;
    } else if(result == IDDISCARD) {
       result = IDNO;
    }
    return result;
}

/**
 * This function is present for backward compatibility.  New macros should
 * use the <b>min_abbrev2</b> function.  Performs list completion (like '?' key)
 * on partial argument <i>word</i> with valid sorted argument list
 * <i>word_list</i>.  The third word of the options argument must be the minimum
 * abbreviation length for list completion to take place.  This procedure is
 * typically used to allow syntax expansion to occur when space bar is pressed
 * after an incomplete keyword.  For example, typing "m&lt;Space&gt;" while in C mode
 * inserts a template for main(){}.
 *
 * @param word       current word under cursor
 * @param word_list  space delimited list of words handled by syntax expansion
 * @param options    syntax expansion options = name_info(p_index)
 *
 * @return Returns completed word if successful.  Otherwise '' is returned.
 *
 * @categories Miscellaneous_Functions
 *
 * @see min_abbrev2
 * @deprecated
 */
_str min_abbrev(_str word, _str word_list, typeless options)
{
   int i=pos(' 'word,word_list);
   if ( ! i || pos(' ',word) || word=='' ) {
      return '';
   }
   if ( substr(word_list,i+length(word)+1,1):==' ' ) { /* Exact match? */
      return word;
   }
   typeless min_len=0;
   parse options with . . min_len .;
   if ( length(word)<min_len ) {
      return '';
   }
   int j=pos(' 'word,word_list,i+1);
   if ( j ) {  /* Not unique match? */
      /* return '' */
      int temp_view_id=0;
      int orig_view_id=_create_temp_view(temp_view_id);
      if ( orig_view_id=='' ) return('');
      _delete_line();
      int width=0;
      _str line='';
      for (;;) {
         line=' 'substr(word_list,i+1,j -i-1);
         insert_line(line);
         if ( length(line)>width ) width=length(line);
         i=j;
         j=pos(' 'word,word_list,i+1);
         if ( ! j ) {
            line=' 'substr(word_list,i+1,pos(' ',word_list,i+1) -i-1);
            insert_line(line);
            if ( length(line)>width ) width=length(line);
            break;
         }
      }
      activate_window(orig_view_id);
      typeless result=show('_sellist_form -modal',
                  nls('Select a Keyword'),
                  SL_VIEWID|SL_SELECTCLINE,
                  temp_view_id,
                  '',                  // buttons
                  '',                  // help item name
                  ''                   // font
                 );
      activate_window(orig_view_id);
      return(strip(result));
   }
   return substr(word_list,i+1,pos(' ',word_list,i+1) -i-1);

}

/**
 * Is the given string in the given string array?
 *
 * @param string  string to search for
 * @param array   array to search (case sensitive)
 *
 * @return 1 if string is an element in array. 
 *  
 * @categories Miscellaneous_Functions
 */
boolean _inarray(_str string,_str (&array)[])
{
   int i;
   for (i=0;i<array._length();++i) {
      if (array[i]==string) return(true);
   }
   return false;
}

static void add_to_array(var array, typeless word)
{
   int i;
   for (i=0;i<array._length();++i) {
      if (array[i]==word) return;//No need to really replace
   }
   array[i]=word;
}
static _str LangCase(_str word,boolean LangCaseSensitive)
{
   if (LangCaseSensitive) {
      return(word);
   }
   return(lowcase(word));
}

/**
 * Determines whether we try to expand the text when the user hits the space 
 * bar.  
 * 
 * @param langId 
 * 
 * @return boolean 
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Miscellaneous_Functions
 */
boolean doExpandSpace(_str langId)
{
   return (LanguageSettings.getSyntaxExpansion(langId) || LanguageSettings.getExpandAliasOnSpace(langId));
}

/**
 * Performs list completion (like '?' key) on partial argument <i>word</i>
 * with valid argument list <i>word_list</i> and the extension specific aliases.
 * The third word of the options argument must be the minimum abbreviation
 * length for list completion to take place.  This procedure is typically used
 * to allow syntax expansion to occur when space bar is pressed after an
 * incomplete keyword.  For example, typing "m&lt;Space&gt;" while in C mode inserts a
 * template for main(){}.
 * @param word
 *                current word under cursor
 * @param word_list
 *                array or hash table of words handled by syntax expansion
 * @param options
 *                syntax expansion options = name_info(p_index)
 * @param aliasfilename
 *                (reference) set to name of alias file
 * @param findAliases
 *                Look for aliases and set aliasfilename
 * @param noPrompt
 *                Do not prompt.
 *                Return semicolon delimited list of matches
 *
 * @return Returns completed word if successful.  If the word is from the
 * extension specific alias file, <i>aliasfilename</i> is set to the full path
 * of the alias file.  Otherwise <i>aliasfilename</i> is set to "".   This
 * function returns "" if <i>word</i> is not a valid partial match, or if the
 * user hit ESCAPE, otherwise,
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Miscellaneous_Functions
 */
_str min_abbrev2(_str word, typeless &word_list, _str options,
                 _str &aliasfilename, boolean findAliases=true,
                 boolean noPrompt=false)
{
/* I thought about sorting the array and doing a binary search.  With 30
   keywords tops, I'll see if its fast enough first.
*/
   boolean LangCaseSensitive=p_EmbeddedCaseSensitive;
   _str LangCaseSensitiveStr=(LangCaseSensitive)?'':'i';
   _str cword=LangCase(word,LangCaseSensitive);
   int len=length(word);
   aliasfilename='';
   _str lang=p_LangId;
   _str setupext='';

   // Get the extension that this buffer's setup/options is based on
   int index=find_index('_'lang'_SetupExtension',PROC_TYPE);
   if( index && index_callable(index) ) {
      _str bufname=p_buf_name;
      _str bufext=_get_extension(bufname);
      setupext=call_index(bufext,index);
      if( !file_eq(bufext,setupext) ) {
         lang=setupext;
      }
   }

   // this might be called for two reasons : 1.) we want to do syntax expansion 
   // or 2.) we want to do automatic alias expansion.  those used to be controlled 
   // in a single option, but in v15 (se 2010), we split those out
   if (findAliases) findAliases = LanguageSettings.getExpandAliasOnSpace(lang);
   doSyntaxExpansion := LanguageSettings.getSyntaxExpansion(lang);

   // do we check for aliases?
   if (findAliases) {
      aliasfilename = LanguageSettings.getAliasFilename(lang);
      aliasfilename = usercfg_path_search(aliasfilename);
      if (aliasfilename!='') aliasfilename=absolute(aliasfilename);
   }
   
   // determine the minimum length of a word we need before we try to expand it
   min_len := LanguageSettings.getMinimumAbbreviation(p_LangId);
   if ( len<1 && !noPrompt ) {
      return('');
   }
   if (last_event():!=' ') {
      min_len=MAXINT;
   } else {
      if (len>=min_len) {
         min_len=MAXINT;
      } else {
         min_len=len;
      }
   }

   _str hitlist[];
   hitlist[0]=1;
   hitlist._deleteel(0,hitlist._length());
   if (doSyntaxExpansion) {
      int count=0;
      
      _str keyword;
      _str temp_list = (word_list._varformat()==VF_LSTR)? word_list:"";
      keyword._makeempty();
      
      int i;
      for (i=0; true; ++i) {
      
         if (word_list._varformat() == VF_HASHTAB) {
            // iterate through items in hash table
            word_list._nextel(keyword);
            if (keyword._isempty()) break;
      
         } else if (word_list._varformat() == VF_ARRAY) {
            // iterate over items in the array
            if (i >= word_list._length()) break;
            keyword = word_list[i];
      
         } else if (word_list._varformat() == VF_LSTR) {
            // parse out items in the space-delimited string
            parse temp_list with keyword temp_list;
            if (keyword=='') break;
      
         } else {
            // unrecognized variable format
            break;
         }
      
         _str caseword=LangCase(keyword,LangCaseSensitive);
         if (cword==caseword) {
            hitlist._deleteel(0,hitlist._length());
            hitlist[0]=word;
            break;
         }else if (cword==substr(caseword,1,len) && length(keyword)<=min_len) {
            hitlist[count++]=keyword;
         }
      }
   }

   int orig_view_id=p_window_id;
   _str alias_info='';
   _str alias_hitlist[];
   alias_hitlist[0]=1;alias_hitlist._deleteel(0,alias_hitlist._length());
   int alias_count=0;
   if (findAliases && aliasfilename!='') {
      AliasFile aliasFile;
      status := aliasFile.open(aliasfilename);
      if (!status) {
         _str list[];
         aliasFile.getNames(list, word);
         foreach (auto curword in list) {
            if (LangCase(curword,LangCaseSensitive)==cword) {
               hitlist._deleteel(0,hitlist._length());
               alias_hitlist._deleteel(0,alias_hitlist._length());
               hitlist[0]=word;
               alias_hitlist[0]=word;
               //alias_hitlist[0]=word;
               //alias_count=0;//Probably not necessary
               break;
            }
            if (length(curword)<=min_len) {
               add_to_array(hitlist,curword);
               alias_hitlist[alias_count++]=curword;
            }
         }
         aliasFile.close();
      }
   }
   hitlist._sort();

   // DJB (10-26-2005)
   // If there is a local variable matching the keyword prefix,
   // then do not do syntax expansion, as if (min_abbrev > length(word))
   // DJB (01-27-2010)
   // Only check for local variables if we actually have a matching 
   // word to expand.  Otherwise, we don't need to spend the time on it.
   if (hitlist._length() > 0) {
      if (!def_expansion_overrides_locals && _are_locals_supported()) {
         _UpdateContext(true);
         _UpdateLocals(true);
         // no need for synchronization here, since tag_find_local_iterator
         // is, for all purposes here, atomic.
         int local_id = tag_find_local_iterator(word, true, p_EmbeddedCaseSensitive, false, "");
         if (local_id > 0) {
            return('');
         }
      }
   }

   /*if ( len<min_len ) {
      if (hitlist._length()!=1) {
         return('');
      }
   } */
   switch (hitlist._length()) {
   case 1:
      if (!_inarray(hitlist[0],alias_hitlist)) aliasfilename='';
      return(hitlist[0]);
   case 0:
      return('');
   default:
      if (noPrompt) {
         return join(hitlist,';');
      }
      typeless result=show('_sellist_form -modal',
                  nls('Select a Keyword'),
                  SL_SELECTCLINE,
                  hitlist,
                  '',                  // buttons
                  '',                  // help item name
                  ''                   // font
                 );
      if (!_inarray(result,alias_hitlist)) aliasfilename='';
      if (result=='') return result;
      result=strip(result);
      return(result);
   }
}

/**
 * Obsolete wrapper function for finding syntax expansion options.
 *
 * @deprecated
 * @see min_abbrev2
 */
_str min_abbrev3(_str word, typeless &word_list,_str unused_options,_str &aliasfilename)
{
   return min_abbrev2(word, word_list, unused_options, aliasfilename);
}

void _on_got_focus()
{
   if (command_state()) {
      if (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX) {
         if (p_window_id==_cmdline ||
             // Ok for read-only text box to select text so users
             // can copy text to clipboard.
             !p_auto_select /*|| p_ReadOnly */|| p_style==PSCBO_NOEDIT ||
             !def_focus_select
             ) return;
         //p_MouseActivate=MA_NOACTIVATEANDEAT;
         _set_sel(1,length(p_text)+1);
      }
      ArgumentCompletionTerminate();
      return;
   }
   ArgumentCompletionTerminate();
   switch_buffer('','W');
   //call_list('_gotfocus_');
}
void _on_lost_focus()
{
   if (command_state()) {
      return;
   }
   call_list('_lostfocus_');
}

void set_switch_buffer_args(_str &old_buffer_name,_str &swold_pos,int &swold_buf_id)
{
   old_buffer_name='';
   swold_pos=null;
   swold_buf_id= -1;
   if (p_mdi_child && _isEditorCtl(false)) {
      old_buffer_name=(p_DocumentName!="")?p_DocumentName:p_buf_name;
      save_pos(swold_pos);
      swold_buf_id=p_buf_id;
   } else {
      if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW) &&
          !_no_child_windows()) {
         int wid=_mdi.p_child;
         old_buffer_name=(wid.p_DocumentName!="")?wid.p_DocumentName:wid.p_buf_name;
         wid.save_pos(swold_pos);
         swold_buf_id=wid.p_buf_id;
      }
   }
}
/**
 * This procedure is called just after SlickEdit switches to a new
 * buffer.  When not in EMACS emulation, this procedure does nothing.
 * Under EMACS emulation, this procedure keeps track of the last buffer
 * edited in the current window.
 *  
 * @param flag   flag = 'Q' if file is being closed
 *               flag = 'W' if focus is being indicated
 *  
 * @categories Buffer_Functions
 *
 */
void switch_buffer( _str old_buffer_name, _str option='',
                    _str swold_pos=null,  _str swold_buf_id=-1 )
{
   _tbSetRefreshBy(VSTBREFRESHBY_SWITCHBUF);
   if (_in_exit_list) return;
   // Call all functions which start with _switchbuf_
   call_list('_switchbuf_',old_buffer_name,option,swold_pos,swold_buf_id);
}
/**
 * Stores the active view id in <i>view_id</i> and activates the view
 * corresponding to the view id VSWID_HIDDEN (defined in
 * "slick.sh").  This allows macros to switch buffers without affecting the
 * original view's cursor position information.
 *
 * @categories Miscellaneous_Functions
 *
 */
void save_view(int &view_id)
{
   get_window_id(view_id);
   /* activate the hidden window with temporary view. */
   activate_window(VSWID_HIDDEN);

}

/**
 * Returns the language that should be used to lookup language specific
 * information for the mode <i>buf_mode_name</i> specified.  If no language 
 * data has a mode name of <i>buf_mode_name</i> the language associated with 
 * the <i>file_name</i> specified is returned. 
 * <p>
 * Many macros ignore the mode name property and use the extension on the 
 * buffer name to determine language specific options.  It is more correct to 
 * use this function to determine the language ID to used to lookup language 
 * specific information. 
 *
 * @return The language ID that should be used to lookup language specific
 * information for the mode <i>buf_mode_name</i> specified.  If no language 
 * data has a mode name of <i>buf_mode_name</i> the language associated with 
 * the <i>file_name</i> specified is returned. 
 *  
 * @param file_name        File name (and path) 
 * @param buf_mode_name    Expected mode name, see {@link p_mode_name} 
 *  
 * @categories Miscellaneous_Functions
 * @deprecated Use {@link _Filename2LangId()} or {@link _Modename2LangId()}
 */
_str _bufnameNmode2ext(_str file_name,_str buf_mode_name)
{
   lang := _Filename2LangId(file_name);
   index := find_index('def-language-'lang,MISC_TYPE);
   parse name_info(index) with auto junk'MN='auto modename',' ;
   //messageNwait('current extmodename='modename);
   if (modename != buf_mode_name) {
     // messageNwait('modes are not equal...searching');
      //wrong alias filename is being used, find which ext we need
      check_and_load_mode_support(buf_mode_name);
      new_lang := _Modename2LangId(buf_mode_name);
      if (new_lang!='') {
         lang = new_lang;
      }
   }
   return(lang);
}

/**
 * Find all the file name extensions associated with the given
 * language and create a file name wildcard expression for
 * those file types.
 * 
 * @param lang source language ID 
 * 
 * @return List of wildcards, separated by semicolons
 *         corresponding to the file name extensions
 *         associated with the given language mode.
 *
 * @categories Miscellaneous_Functions 
 * @deprecated Use {@link _GetWildcardsForLanguage()} 
 */
_str _ext2wildcards(_str lang)
{
   return _GetWildcardsForLanguage(lang);
}

/**
 * Find all the file name extensions associated with the given
 * language and create a file name wildcard expression for
 * those file types.
 * 
 * @param lang    Language ID (see {@link p_LangId}
 * 
 * @return List of wildcards, separated by semicolons
 *         corresponding to the file name extensions
 *         associated with the given language mode.
 *  
 * @see _Ext2LangId() 
 * @see p_LangId 
 *  
 * @categories Miscellaneous_Functions 
 */
_str _GetWildcardsForLanguage(_str lang)
{
   wildcards := '';
   index := find_index('def-lang-for-ext-'lang,MISC_TYPE);
   if (index > 0 && name_info(index) :== lang) {
      wildcards = '*.'lang;
   }

   index = name_match('def-lang-for-ext-',1,MISC_TYPE);
   while (index != 0) {
      name := substr(name_name(index),18);
      if (name != lang && name_info(index) :== lang) {
         _maybe_append(wildcards,';');
         wildcards = wildcards'*.'name;
      }
      index=name_match('def-lang-for-ext-',0,MISC_TYPE);
   }

   return wildcards;
}

/** 
 * Converts a file extension to the mode name 
 * corresponding to the language language referred to by 
 * the given file extension. 
 * 
 * @param ext           File extension. 
 * @param setup_index   Set to names table index for 
 *                      def-language-lang (canonical
 *                      extension)
 * 
 * @return The mode name for the language.
 *  
 * @see _Modename2LangId 
 * @see _Filename2LangId 
 * @see _Ext2LangId 
 *  
 * @categories Miscellaneous_Functions 
 * @deprecated Use {@link _LangId2Modename()}
 */
_str _ext2modename(_str ext,int &setup_index)
{
   setup_index=name_match('def-language-',1,MISC_TYPE);
   for( ;; ) {
      if( !setup_index ) break;

      _str e='';
      parse name_name(setup_index) with 'def-language-' e;
      if( file_eq(e,ext) ) {
         // Found a match
         _str ni=name_info(setup_index);
         if( substr(ni,1,1)=='@' ) {
            // Referred-to extension
            e=substr(ni,2);
            setup_index=find_index('def-language-'e,MISC_TYPE);
            if( !setup_index ) break;
            ni=name_info(setup_index);
         }
         typeless junk='', modename='';
         parse ni with junk'MN='modename',';
         return(modename);
      }
      setup_index=name_match('def-language-',0,MISC_TYPE);
   }
   return('');
}

/** 
 * @return 
 * Get the set of file extension wild cards for the given 
 * language mode. 
 * 
 * @param mode    language mode name
 * 
 * @deprecated Use {@link GetWildcardsForLanguage()} 
 */
_str _modename2wildcards(_str mode)
{
   return(_GetWildcardsForLanguage(_Modename2LangId(mode)));
}

/** 
 * Converts the unique display name for a language to it's 
 * language ID (canonical file extension).
 * 
 * @param mode_name     Display name for language type 
 * @param setup_index   (reference) set to the 'def-language-[lang]' 
 *                      name info entry for the language
 * @param doAutoLoadSupport   Automatically load language support 
 *                            if not already loaded. 
 * 
 * @return The language ID for the language 
 *         corresponding to 'mode_name'. 
 *  
 * @see _Filename2LangId 
 * @see _Ext2LangId 
 *  
 * @categories Miscellaneous_Functions 
 * @deprecated Use {@link _Modename2LangId()}. 
 */
_str _modename2ext(_str mode_name, 
                   int &setup_index,
                   boolean doAutoLoadSupport=true)
{
   if ( doAutoLoadSupport ) {
      check_and_load_mode_support(mode_name);
   }
   lang := _Modename2LangId(mode_name);
   setup_index = find_index("def-language-"lang,MISC_TYPE);
   return lang;
}

_str nls_strip_chars(_str &nls_chars,_str msg)
{
   nls_chars='';
   int i=1;
   for (;;) {
      i=pos('~',msg,i);
      if ( ! i ) {
         return(msg);
      }
      if ( substr(msg,i+1,1)=='~' ) {
         msg=substr(msg,1,i):+substr(msg,i+2);
         i=i+1;
      } else {
         nls_chars=nls_chars:+upcase(substr(msg,i+1,1));
         msg=substr(msg,1,i-1):+substr(msg,i+1);
      }
   }
}
_str nls_selection_chars(_str msg)
{
   _str nls_chars='';
   int i=1;
   for (;;) {
      i=pos('&',msg,i);
      if ( ! i ) {
         return(nls_chars);
      }
      nls_chars=nls_chars:+upcase(substr(msg,i+1,1));
      i=i+2;
   }
}
boolean _on_line0()
{
   if (p_object==OI_LIST_BOX) {
      return p_line==0;
   }
   typeless seekpos='', down_count='';
   parse point() with seekpos down_count ;
   if (down_count!='') {
      return(seekpos<0 && !down_count);
   }
   return(seekpos<0);
}
/**
 * @return Returns VSARG2_??? flags name information corresponding to name
 * table <i>index</i>.  If <i>index</i> is not an index to a valid name or name
 * has no VSARG2_??? information, '' is returned.
 *
 * @example
 * <pre>
 * _command mycommand()
 *       name_info(','VSARG2_REQUIRES_EDITORCTL |VSARG2_ICON)
 * {
 *    index= find_index("mycommand", COMMAND_TYPE);
 *    // Get the name information after the ','
 *    message('arg2 Name info for this command is 'name_info_arg2(index));
 * }
 * </pre>
 *
 * @see name_info
 *
 * @categories Names_Table_Functions
 *
 */
typeless name_info_arg2(int command_index)
{
   typeless flags='';
   parse name_info(command_index) with ',' flags ',' ;
   if ( flags=='' ) {
      flags=0;
   }
   return(flags);
}
/**
 * If macro recording and output is on (_macro()!=0), the first argument to
 * the last source line of the recorded macro is incremented.  The argument is
 * incremented only if the current command specified by <b>last_index</b> is the
 * same as the previous command indicated by <b>prev_index</b>.
 *
 * @see _macro
 * @see _macro_append
 * @see _macro_delete_line
 * @see _macro_replace_line
 * @see _macro_call
 * @see _macro_get_line
 *
 * @categories Macro_Programming_Functions
 *
 */
void _macro_repeat()
{
   if (_macro()) {
      _str this_cmd=name_name(last_index('','C'));
      _str prev_cmd=name_name(prev_index('','C'));
      if (prev_cmd==this_cmd) {
         _macro_delete_line();     // Delete code generated for this command
         _str line=_macro_get_line();
         _str param='';
         parse line with line '(' param ')';
         if (param=='') {
            param=2;
         } else {
            ++param;
         }
         _macro_replace_line(translate(this_cmd,'_','-')'('param');');
      }
   }
}

/**
 * <p>Replaces a picture or inserts a picture into the names table.
 * <i>filename</i> is the filename of a bitmap (<b>.bmp</b>) or pixmap
 * (<b>.xpm</b>) .    Currently only bitmaps and pixmap files are
 * supported.  After a picture is inserted into the names table, the path
 * information is removed (<b>name_name</b>(<b>p_picture</b>) has
 * no path).  Therefore, if you try to load two pictures from different
 * directories with the same name part into the names table, the second
 * copy will replace the first.</p>
 *
 * <p>Important: Pictures are deleted from the names table when you save
 * the configuration if the name of the picture does not start with an
 * underscore ('_') and no forms reference the picture
 * (<b>p_picture</b>).</p>
 *
 * <p>If <i>index</i> is less than 0, the existing picture will be replaced if it
 * already exists.  If it does not exist, the new picture is inserted.</p>
 *
 * <p>If <i>index</i> is 0, a new picture is inserted.</p>
 *
 * <p>If <i>index</i> is greater than 0, it is assumed to be a names table
 * index to an existing picture to be replaced.</p>
 *
 * @return Returns the names table index of the new picture if successful.  This
 * index can be used by the <b>p_picture</b> property.  On error, a
 * negative error code is returned.  Common error codes are
 * FILE_NOT_FOUND_RC are PATH_NOT_FOUND_RC.
 *
 * @example
 * <pre>
 * // Replace the existing picture.  Use -1 for index unless you know
 * what you are doing.
 * index=_update_picture(-1, '_drfixed.ico');
 * messageNwait('name_name(index)='name_name(index));
 *
 * // Try this code during a lbutton_up event of a command button.
 * // you need a form with a picture box called picture1 as well.
 * index=_update_picture(picture1.p_picture,'_drfixed.ico');
 * messageNwait('name_name(index)='name_name(index));
 * </pre>
 *
 * @categories Names_Table_Functions
 *
 */
int _update_picture(int index,_str filename)
{
   if (index<0) {
      /* Find existing picture. */
      index=find_index(filename,PICTURE_TYPE);
   }
   if (index) {
      index=replace_name(index,filename);
   } else {
      index=insert_name(filename,PICTURE_TYPE);
      if (!index) {
         index=rc;
      }
   }
   if (index<0) {
      if (index==FILE_NOT_FOUND_RC) {
         _message_box(nls('Picture %s1 not found',filename));
      } else {
         _message_box(nls('Unable to load picture %s1',filename)'. 'get_message(index));
      }
   } else {
      _config_modify_flags(CFGMODIFY_SYSRESOURCE|CFGMODIFY_RESOURCE);
   }
   return(index);
}

/**
 * Finds a picture in the names table.  If the picture is not already in the 
 * names table, it is added. 
 *  
 * <i>filename</i> is the filename of a bitmap (<b>.bmp</b>) or pixmap
 * (<b>.xpm</b>) .    Currently only bitmaps and pixmap files are
 * supported.  After a picture is inserted into the names table, the path
 * information is removed (<b>name_name</b>(<b>p_picture</b>) has
 * no path).  Therefore, if you try to load two pictures from different
 * directories with the same name part into the names table, the second
 * copy will replace the first.</p>
 *
 * <p>Important: Pictures are deleted from the names table when you save
 * the configuration if the name of the picture does not start with an
 * underscore ('_') and no forms reference the picture
 * (<b>p_picture</b>).</p>
 *
 * @return Returns the names table index of the picture if successful.  This
 * index can be used by the <b>p_picture</b> property.  On error, a
 * negative error code is returned.  Common error codes are
 * FILE_NOT_FOUND_RC are PATH_NOT_FOUND_RC.
 *
 * @categories Names_Table_Functions
 *
 */
int _find_or_add_picture(_str filename)
{
   index := find_index(filename, PICTURE_TYPE);
   if (!index) {
      index = _update_picture(-1, filename);
   }

   return index;
}

/**
 * @return Returns name type given converted to the corresponding object index.
 *
 * @see oi2type
 *
 * @categories Names_Table_Functions
 *
 */
int type2oi(int type)
{
   return((type&OBJECT_MASK)>>OBJECT_SHIFT);
}
/**
 * @return Returns object constant converted to an object type.  The return
 * value of this function is used as input into the <b>name_match</b>,
 * <b>find_index</b>, and other name table functions which accept a name type
 * argument.
 *
 * @example
 * <pre>
 * index=find_index('form1',oi2type(OI_FORM));
 * </pre>
 *
 * @categories Names_Table_Functions
 *
 */
int oi2type(int oi)
{
   return(OBJECT_TYPE|(oi<<OBJECT_SHIFT));
}

/**
 * @return  Returns <i>string</i> with regular expression special characters
 * prefixed with \.  Specify the 'U' option to escape UNIX regular expression
 * special characters.  Specify the 'B' option to escape Brief regular
 * expression special characters.  Specify the '&' option to escape a simple
 * Wildcard expression.
 *
 * @param filename      string to escape
 * @param regex_type    regular expression syntax type
 *
 * @example
 * <pre>
 * _escape_re_chars("abc") == "abc"
 * _escape_re_chars("*.c") =="\*.c"
 * _escape_re_chars("*.c",'U')   =="\*\.c"
 * _escape_re_chars("*.c",'B')   =="\*\.c"
 * _escape_re_chars("+++") =="\+\+\+"
 * </pre>
 * @categories Search_Functions, String_Functions
 */
_str _escape_re_chars(_str filename, _str regex_type="")
{
   _str re_chars='';
   if (upcase(regex_type)=='U' || upcase(regex_type)=='L') {
      re_chars='$?+*(){}^[]|.\';
   } else if (upcase(regex_type)=='B') {
      re_chars='*?@+{}[]|\<%>$';
   } else if (upcase(regex_type)=='&') {
      re_chars='*?#\';
   } else {
      re_chars='$?+#*@(){}~^[]|\:';
   }
   int i=1;
   for (;;) {
      i=verify(filename,re_chars,'m',i);
      if ( ! i ) {
         break;
      }
      filename=substr(filename,1,i-1):+'\':+substr(filename,i);
      i=i+2;
   }
   return(filename);
}
/**
 * @return Returns the first line/item of <i>string.</i>  The first line/item is
 * deleted from <i>string</i> so that this function may be called again to
 * get the next line.  By default, the line delimiters may be (13,10), (10),
 * or (13).  The optional <i>delimiter</i> argument is a single character
 * used as the item delimiter instead of the default delimiters.
 *
 * @example
 * <pre>
 * line='First,Second,Third';
 * for (;;){
 *    item=_parse_line(line, ',');
 *    if (item == '') break;      
 *    messageNwait('item='item);
 * }
 * line="First\nSecond\nThird";
 * for(;;){
 *    item=_parse_line(line);
 *    if (item == '') break;      
 *    messageNwait('item='item);
 * }
 * </pre>
 *
 * @categories String_Functions
 *
 */
_str _parse_line(_str &lines, _str parse_ch="")
{
   int i=0;
   if (parse_ch:!='') {
      i=pos(parse_ch,lines,1,'r');
   } else {
      // for DOS,UNIX, or MAC new line sequence
#if __EBCDIC__
      i=pos('\13\21|\21|\13',lines,1,'r')
#else
      i=pos('\13\10|\10|\13',lines,1,'r');
#endif
   }
   _str result="";
   if (i) {
      result=substr(lines,1,i-1);
      lines=substr(lines,i+pos(''));
   } else {
      result=lines;
      lines='';
   }
   return(result);
}
/**
 * Places the cursor at the end of the ".command" retrieve buffer.
 *
 * @categories Retrieve_Functions
 *
 */
void _reset_retrieve()
{
   int view_id=0;
   get_window_id(view_id);activate_window(VSWID_RETRIEVE);bottom();
   activate_window(view_id);_cmdline.set_command('');execute();
}

/*
    form_name can be just a form name or form_name.control
    The later is used for combo box list data.
*/
static void add_dialog_data(_str form_name,_str data,int maxNoflinesThatFollow)
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(_GetDialogHistoryViewId());
   top();
   int status=search("^"form_name'\:',"@re");
   if (status) {
      bottom();
      insert_line(form_name':1 0');
      insert_line(" "data);
      activate_window(orig_view_id);
      return;
   }
   _str line='';
   get_line(line);
   typeless NoflinesThatFollow="", NoflinesToCurRetrieve="";
   parse line with form_name':'NoflinesThatFollow NoflinesToCurRetrieve;
   if (!isinteger(NoflinesThatFollow)) {
      activate_window(orig_view_id);
      return;
   }
   save_pos(auto p);
   typeless prev_data="";
   int markid= -1;
   if (NoflinesThatFollow>0) {
      markid=_alloc_selection();
      down();
      _select_line(markid);
      down(NoflinesThatFollow-1);
      _select_line(markid);
      _begin_select(markid);
      status=search('^ '_escape_re_chars(data)'$','@re');
      //if (pos('ctlmffiles',form_name)) {
         //_message_box('status='status' ln='p_line' fn='form_name' deleted dup: 'translate(data,' ',"\0"));
      //}
      if (!status) {
         // We found previous retrieve data maching this one, delete
         // the old one here and insert the new one below.
         /*if (pos('ctlmffiles',form_name)) {
            _message_box('ln='p_line' fn='form_name' deleted dup: 'translate(data,' ',"\0"));
         } */
         //say('delete ln 'p_line' bn='p_buf_name);
         _delete_line();
         --NoflinesThatFollow;
      }
      restore_pos(p);
      _free_selection(markid);
      //down();get_line(prev_data);up();
   }
#if 0
   // IF the previous retrieve data matches this one, don't bother adding
   //    it again.
   if (substr(prev_data,2):==data || pos("\n",data)) {
      activate_window(orig_view_id);
      return;
   }
#endif
   insert_line(" "data);
   if (NoflinesThatFollow>=maxNoflinesThatFollow) {
      down(NoflinesThatFollow);
      _delete_line();
   } else {
      ++NoflinesThatFollow;
   }
   restore_pos(p);
   replace_line(form_name':'NoflinesThatFollow" "NoflinesToCurRetrieve);
   activate_window(orig_view_id);
}
/**
 * This command is typically called to add retrieve information for
 * a combo box control.  After adding combo box retrieve information,
 * the <b>_retrieve_list</b> method can be called to fill the combo box list.
 * Dialog box retrieval functions call this function to store retrieve
 * data of radio button, command button, check box, text box, and
 * combo box controls.
 *
 * @param ctl_wid  the window id (p_window_id) of the control.
 *                 The default <i>object_name</i> is form_name.ctl_name.
 * @param value    the text of a combo box or text box.  For a button control, value is 0 or 1.
 * @param ctl_name an override name for the combo box
 *
 * @example <pre>
 * defeventtab form1;
 * ok.lbutton_up()
 * {
 *     // When OK button is pressed, you will want to save combo box
 *     // retrieve information.
 *     _append_retrieve(_control combo1,combo1.p_text);
 * }
 * ok.on_create()
 * {
 *      // Fill in the combo box list
 *      combo1._retrieve_list();
 * }
 * </pre>
 *
 * @categories Retrieve_Functions
 */
void _append_retrieve(int ctl_wid,_str value,_str ctl_name='')
{
   if (ctl_name=='') {
      ctl_name=ctl_wid.p_active_form.p_name'.'ctl_wid.p_name;
   } else if(!pos('.',ctl_name) && ctl_wid.p_object!=OI_FORM){
      ctl_name=ctl_wid.p_active_form.p_name'.'ctl_name;
   }
   _str command="";
   _str dot_name=ctl_name;
   _str form_name="";
   parse ctl_name with form_name"."ctl_name;
   maxItems := 1;
   if (!ctl_wid) {
      command= CTLSEPARATOR:+"da ":+ctl_name:+":":+value;
      maxItems = def_maxcombohist;
   } else {
      switch (ctl_wid.p_object) {
      case OI_TEXT_BOX:
         command= CTLSEPARATOR:+'te 'ctl_name':'value;
         maxItems = def_maxcombohist;
         break;
      case OI_CHECK_BOX:
         command= CTLSEPARATOR:+'ch 'ctl_name':'value;
         break;
      case OI_RADIO_BUTTON:
         if (!value) {
            return;
         }
         command= CTLSEPARATOR:+'ra 'ctl_name':'value;
         break;
      case OI_HSCROLL_BAR:
         command= CTLSEPARATOR:+'hs 'ctl_name':'value;
         break;
      case OI_VSCROLL_BAR:
         command= CTLSEPARATOR:+'vs 'ctl_name':'value;
         break;
      case OI_COMBO_BOX:
         command= CTLSEPARATOR:+'cb 'ctl_name':'value;
         maxItems = def_maxcombohist;
         break;
      case OI_PICTURE_BOX:
         command= CTLSEPARATOR:+'pi 'ctl_name':'value;
         break;
      case OI_IMAGE:
         command= CTLSEPARATOR:+'im 'ctl_name':'value;
         break;
      case OI_GAUGE:
         command= CTLSEPARATOR:+'ga 'ctl_name':'value;
         break;
      case OI_SSTAB:
         command= CTLSEPARATOR:+"tb ":+ctl_name:+":":+value;
         break;
      default:
         return;
      }
   }
   add_dialog_data(dot_name,command, maxItems);
}
int _xsrg_dialogs(_str option='',_str info='')
{
   int window_file_id=0;
   get_window_id(window_file_id);  /* should be $window.slk */
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      return(mark);
   }
   typeless Noflines=0;
   dialogs_view_id := _GetDialogHistoryViewId();
   if ( (option=='R' || option=='N') ) {
      parse info with Noflines .;
      if (Noflines) {
         down();_select_line(mark);
         down(Noflines-1);
         _select_line(mark);
         activate_window(dialogs_view_id);
         _lbclear();
         _copy_to_cursor(mark);
         top();
      } else {
         activate_window(dialogs_view_id);
         _lbclear();
         top();
      }
   } else {
      activate_window(dialogs_view_id);
      Noflines=p_Noflines;
      if (Noflines) {
         int line_number=p_line;
         bottom();_end_line();
         activate_window(dialogs_view_id);
         top();
         _select_line(mark);
         bottom();_select_line(mark);
         activate_window(window_file_id);
         insert_line('DIALOGS: 'Noflines);
         _copy_to_cursor(mark);
         _end_select(mark);
         activate_window(dialogs_view_id);
         top();
      }
   }
   _free_selection(mark);
   activate_window(window_file_id);
   return(0);
}
static _str gtempdata;
static int _save_fr2(int wid,_str form_name)
{
   if (wid.p_name=='' || wid.p_object==OI_FORM) return(0);
   _str ctl_name=wid.p_name;
   switch (wid.p_object) {
   case OI_TEXT_BOX:
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'te 'ctl_name':'wid.p_text;
      break;
   case OI_CHECK_BOX:
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'ch 'ctl_name':'wid.p_value;
      break;
   case OI_RADIO_BUTTON:
      if (!wid.p_value) {
         return(0);
      }
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'ra 'ctl_name':'wid.p_value;
      break;
   case OI_HSCROLL_BAR:
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'hs 'ctl_name':'wid.p_value;
      break;
   case OI_VSCROLL_BAR:
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'vs 'ctl_name':'wid.p_value;
      break;
   case OI_COMBO_BOX:
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'cb 'ctl_name':'wid.p_text;
      break;
   case OI_PICTURE_BOX:
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'pi 'ctl_name':'wid.p_value;
      break;
   /*
   Buttons should not be restore because the lbutton_up even gets executed
   when the button was not pressed.
   case OI_IMAGE:
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'im 'ctl_name':'wid.p_value;
      break;
   */
   case OI_GAUGE:
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'ga 'ctl_name':'wid.p_value;
      break;
   case OI_SSTAB:
      gtempdata=gtempdata:+CTLSEPARATOR:+ 'tb 'ctl_name':'wid.p_ActiveTab;
      break;
   }
   return(0);
}
/**
 * Toggle a boolean variable in a saved form response
 *
 * @param formName Name of the form whose 1st response we want to modify
 * @param variable Name of the variable within that 1st response that we want to modify
 *
 * @return 1 if the boolean variable was toggled successfully; 0 otherwise. This might
 * happen if the form could not be found, the variable could not be found, or if the
 * variable is not either 0 or 1
 */
int _toggle_form_response_var(_str formName, _str variable)
{
   _str tuples:[];
   _str oldResponse = _get_form_response(formName, 1);
   if (oldResponse == "") {
      return 0;
   }
   _split_form_response_vars(oldResponse, tuples);
   if (!tuples._indexin(variable)) {
      return 0;
   }
   if (tuples:[variable] == 0) {
      tuples:[variable] = 1;
   }
   else if (tuples:[variable] :== 1) {
      tuples:[variable] = 0;
   }
   else {
      return 0;
   }
   _str newResponse = _replace_form_response_vars(oldResponse, tuples);
   _modify_form_response(formName, newResponse, 1);
   return 1;
}
/**
 * Split a saved form response into a hash of key-value pairs
 *
 * @param response The line representing the form response to parse
 * @param tuples The output hash that will contain the key-value pairs
 */
void _split_form_response_vars(_str response, _str (&tuples):[])
{
   tuples._makeempty();
   _str ctl_data;
   _str key, value;
   for (;;) {
      parse response with (CTLSEPARATOR) ctl_data (CTLSEPARATOR) +0 response;
      if (ctl_data=="") break;
      parse ctl_data with key':'value (CTLSEPARATOR) +0 ctl_data;
      if (key == "") {
         continue;
      }
      tuples:[key] = value;
   }
}
/**
 * Replace the keys in oldResponse with new values
 *
 * @param oldResponse The old response in which to perform search and replace
 * @param tuples A string hash where the keys are the names of parameters to
 * search for in oldResponse and the values are the new values of those parameters
 *
 * @return The new response with old values replaced by new values
 */
_str _replace_form_response_vars(_str oldResponse, _str (&tuples):[])
{
   _str oldTuples:[];
   _split_form_response_vars(oldResponse, oldTuples);
   typeless i;
   for (i._makeempty(); ; ) {
      tuples._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (oldTuples._indexin(i)) {
         oldTuples:[i] = tuples:[i];
      }
   }
   _str newResponse = CTLSEPARATOR :+ join_tuples(oldTuples, CTLSEPARATOR, ":", false);
   return newResponse;
}

/**
 * Retrieve the text string for the ith form response
 *
 * @param formName Name of the form
 * @param responseNum Index of the response to retrieve.
 *
 * @return The text string. If the form
 * is not found, or the index is too large or invalid, empty string ''
 * is returned
 */
_str _get_form_response(_str formName, int responseNum)
{
   // First we try to find the form in the .dialogs buffer
   int orig_view_id;
   get_window_id(orig_view_id);
   activate_window(_GetDialogHistoryViewId());
   top();
   int status = search("^"formName'\:',"@re");
   // If we didn't find the form, return an empty string
   if (status) {
      return '';
   }
   _str line;
   _str NoflinesThatFollow, NoflinesToCurRetrieve;
   get_line(line);
   parse line with formName':'NoflinesThatFollow NoflinesToCurRetrieve;
   if (!isinteger(NoflinesThatFollow) || !isinteger(NoflinesToCurRetrieve) ||
       responseNum <= 0 || responseNum > NoflinesThatFollow) {
      activate_window(orig_view_id);
      return '';
   }
   down(responseNum);
   get_line(line);
   activate_window(orig_view_id);
   return line;
}
/**
 * Add/replace a form response
 *
 * @param formName The name of the form
 * @param newResponse A one-line string representing the new response
 * @param responseNum The response # to replace. If this is 0, the last response
 * is replaced. If this is negative or greater than the # of responses currently
 * stored, newResponse is added as the last response. The default is 1, so that
 * the first response is replaced.
 */
void _modify_form_response(_str formName, _str newResponse, int responseNum=1)
{
   // First we try to find the form in the .dialogs buffer
   int orig_view_id;
   get_window_id(orig_view_id);
   activate_window(_GetDialogHistoryViewId());
   top();
   newResponse = " "newResponse;
   int status = search("^"formName'\:',"@re");
   // If we didn't find the form, then we should add it
   if (status) {
      bottom();
      insert_line(formName':1 0');
      insert_line(newResponse);
      activate_window(orig_view_id);
      return;
   }
   // If we found the form...
   get_line(auto line);
   _str NoflinesThatFollow, NoflinesToCurRetrieve;
   parse line with formName':'NoflinesThatFollow NoflinesToCurRetrieve;
   if (!isinteger(NoflinesThatFollow)) {
      activate_window(orig_view_id);
      return;
   }
   if (responseNum > (int) NoflinesThatFollow || responseNum < 0) {
      // Add the new response
      replace_line(formName':'(int) NoflinesThatFollow+1" "NoflinesToCurRetrieve);
      down((int) NoflinesThatFollow);
      insert_line(newResponse);
   }
   else if (responseNum == 0) {
      // Replace the last response
      down((int) NoflinesThatFollow - 1);
      replace_line(newResponse);
   }
   else {
      // Replace the requested responseNum
      down((int) responseNum);
      replace_line(newResponse);
   }
   activate_window(orig_view_id);
}
/**
 * Saves the response to check boxes, radio buttons, text boxes, and
 * combo boxes, for the active form.  Values are placed in the
 * ".command" buffer which is saved in the auto restore file
 * ("vrestore.slk" by default) when you exit the editor with auto restore
 * turned on.  Call the <b>_retrieve_prev_form</b> function during the
 * on_create event to initialize the form to the users previous response.
 * This function is used to perform dialog box retrieval.  The dialog
 * manager automatically calls the <b>_retrieve_prev_form</b> and
 * <b>_retrieve_next_form</b> function when you press F7 and F8
 * respectively.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * // Create a text box with an OK command button on the form for
 * this example
 * defeventtab form1;
 * ok.on_create()
 * {
 *    _retrieve_prev_form();
 * }
 * ok.lbutton_up()
 * {
 *    _save_form_response();
 *    p_active_form._delete_window(0);
 * }
 * </pre>
 *
 * @see _retrieve_next_form
 * @see _retrieve_prev_form
 *
 * @appliesTo Form
 *
 * @categories Form_Methods
 *
 */
void _save_form_response()
{
   int form_wid=p_active_form;
   _str form_name=form_wid.p_name;
   if (form_name=='') return;
   gtempdata="";
   typeless wid=_for_each_control(form_wid,
                         _save_fr2,'H',form_name);

   add_dialog_data(form_name,gtempdata,def_maxdialoghist);
}
static _str _set_retrieve_value(int form_wid, typeless wid, _str ctl_data)
{
   boolean done=0;
   typeless ctltype="", ctl_name="", value="";
   parse ctl_data with ctltype ctl_name':'value ;
   if (ctl_name=='') return(1);
   if (wid=='') {
      wid=form_wid._find_control(ctl_name);
   }
   switch (ctltype) {
   case 'te':
      if (wid) wid.p_text=value;
      break;
   case 'ch':
      if (wid) {
         wid.p_value=value;
         wid.call_event(wid,LBUTTON_UP);
      }
      break;
   case 'ra':
      if (wid) {
         wid.p_value=value;
         wid.call_event(wid,LBUTTON_UP);
      }
      break;
   case 'hs':
      if (wid) wid.p_value=value;
      break;
   case 'vs':
      if (wid) wid.p_value=value;
      break;
   case 'cb':
      if (wid) wid.p_text=value;
      break;
   case 'pi':
      if (wid) {
         wid.p_value=value;
         wid.call_event(wid,LBUTTON_UP);
      }
      break;
   case 'im':
      return(0);
      /*if (wid) {
         wid.p_value=value;
         wid.call_event(wid,LBUTTON_UP)
      } */
      break;
   case 'ga':
      if (wid) wid.p_value=value;
      break;
   case 'tb':
      if (wid) wid.p_ActiveTab=value;
      break;
   default:
      done=1;
   }
   return(done);
}
/**
 * Retrieves the previous response to check boxes, radio buttons, text
 * boxes, and combo boxes, for the active form.  This function is used to
 * perform dialog box retrieval and is called by the dialog manager when
 * you press F7.
 *
 * @example
 * <pre>
 * #include "slick.sh"
 * // Create a text box with an OK command button on the form for
 * this example
 * defeventtab form1;
 * ok.on_create()
 * {
 *    _retrieve_prev_form();
 * }
 * ok.lbutton_up()
 * {
 *    _save_form_response();
 *    p_active_form._delete_window(0);
 * }
 * </pre>
 *
 * @see _retrieve_next_form
 * @see _save_form_response
 *
 * @appliesTo Form
 *
 * @categories Form_Methods
 *
 */
int _retrieve_prev_form()
{
   return(_retrieve_next_form('-'));
}
/**
 * Retrieves the next response to check boxes, radio buttons, text boxes,
 * and combo boxes, for the active form.  This function is used to
 * perform dialog box retrieval and is called by the dialog manager when
 * you press F8.
 *
 * @see _retrieve_prev_form
 * @see _save_form_response
 *
 * @appliesTo Form
 *
 * @categories Form_Methods, Retrieve_Functions
 *
 */
int _retrieve_next_form(_str direction="", _str doSetSelect="")
{
   int form_wid=p_active_form;
   _str form_name=form_wid.p_name;
   if (form_name=='') return(1);
   int view_id=0;
   get_window_id(view_id);
   dialogs_view_id := _GetDialogHistoryViewId();
   activate_window(dialogs_view_id);
   top();
   typeless status=search("^"form_name'\:',"@re");
   if (status) {
      activate_window(view_id);
      return(status);
   }
   _str line="";
   get_line(line);
   typeless NoflinesThatFollow="", NoflinesToCurRetrieve="";
   parse line with form_name':'NoflinesThatFollow NoflinesToCurRetrieve;
   if (form_wid.p_user2=='') {
      NoflinesToCurRetrieve=0; // Start retrieving from first dialog
      form_wid.p_user2=1;
   }
   if (direction=='-') {
      if (NoflinesToCurRetrieve>=NoflinesThatFollow) {
         activate_window(view_id);
         return(1);
      }
      ++NoflinesToCurRetrieve;
   } else {
      if (NoflinesToCurRetrieve<=1 || NoflinesThatFollow<=0) {
         activate_window(view_id);
         return(1);
      }
      --NoflinesToCurRetrieve;
   }
   save_pos(auto p);
   down(NoflinesToCurRetrieve);
   _str data="";
   get_line(data);
   typeless done=0;
   for (;;) {
      _str ctl_data="";
      parse data with (CTLSEPARATOR) ctl_data (CTLSEPARATOR) +0 data;
      if (ctl_data=="") break;
      done=_set_retrieve_value(form_wid,'',ctl_data);
      activate_window(dialogs_view_id);
      if (done) break;
   }
   restore_pos(p);
   replace_line(form_name':'NoflinesThatFollow' 'NoflinesToCurRetrieve);
   activate_window(view_id);
   if (doSetSelect!='' && (p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX)) {
      _set_sel(1,length(p_text)+1);
   }
   return(rc);
}
_str def_retrieve_up=0;
/**
 * Inserts text box history into list box.  When no argument is given, the
 * history is retrieved based on the active form name and active control
 * name (<b>p_name</b>).  If the <i>cmdline</i> argument does not
 * contain a '.', the history is based on the active form name and
 * <i>cmdline</i> specifies an alternate control name.
 *
 * @param cmdline is a string in the format: <i>form_name</i>[<i>.ctl_name</i>]
 *
 * @example
 * <pre>
 * defeventtab form1;
 * ok.lbutton_up()
 * {
 *     // When OK button is pressed, you will want to save combo box
 * retrieve information.
 *     _append_retrieve(_control combo1,combo1.p_text);
 * }
 * ok.on_create()
 * {
 *      // Fill in the combo box list
 *      combo1._retrieve_list();
 * }
 * </pre>
 *
 * @see _append_retrieve
 *
 * @appliesTo Combo_Box, List_Box
 *
 * @categories Combo_Box_Methods, List_Box_Methods, Retrieve_Functions
 *
 */
void _retrieve_list(_str object_name='')/*,int noDuplicates=false)*/
{
   int form_wid=p_active_form;
   _str form_name=form_wid.p_name;
   _str ctl_name=p_name;
   if (object_name!='') {
      if(pos('.',object_name)){
         parse object_name with form_name '.' ctl_name ;
      } else {
         ctl_name=object_name;
      }
   }
   if (form_name=='' || ctl_name=='') {
      return;
   }
   int view_id=0;
   get_window_id(view_id);
   int output_wid=p_window_id;
   activate_window(_GetDialogHistoryViewId());
   top();
   typeless status=search("^"form_name"."ctl_name'\:',"@re");
   if (status) {
      status=search("^"form_name'\:',"@re");
   }
   if (status) {
      activate_window(view_id);
      return;
   }
   _str line="";
   get_line(line);
   typeless NoflinesThatFollow="", NoflinesToCurRetrieve="";
   parse line with form_name':'NoflinesThatFollow NoflinesToCurRetrieve;
   if (def_retrieve_up) {
      down(NoflinesThatFollow);
   } else {
      down();
   }
   _str last_value='';
   while(NoflinesThatFollow--){
      get_line(auto data);
      for (;;) {
         _str ctl_data="";
         parse data with (CTLSEPARATOR) ctl_data (CTLSEPARATOR) +0 data;
         if (ctl_data=="") break;
         typeless dctl_type="", dctl_name="", value="";
         parse ctl_data with dctl_type dctl_name':' value;
         if (dctl_name:==ctl_name) {
            if (value:!=last_value && value!="") {
               output_wid._lbadd_item_no_dupe(value, '', LBADD_BOTTOM);
               last_value=value;
            }
         }
      }
      //if (find_last_only) break;
      if (def_retrieve_up) {
         up();
      } else {
         down();
      }
   }
   activate_window(view_id);
   //if (find_last_only) return(value);
   if (output_wid.p_object==OI_COMBO_BOX) {
      // Try to find current text value in list
      status = output_wid._cbi_search('','$');
      if (!status) {
         output_wid._lbselect_line();
      } else {
         // Place cursor on line 0 so down arrow
         // key goes to first item.
         output_wid.p_line=0;
      }
   }
}

/**
 * Delete text box history into list box.  When no argument is 
 * given, the history is retrieved based on the active form name 
 * and active control 
 * name (<b>p_name</b>).  If the <i>cmdline</i> argument does not
 * contain a '.', the history is based on the active form name and
 * <i>cmdline</i> specifies an alternate control name.
 *
 * @param cmdline is a string in the format: <i>form_name</i>[<i>.ctl_name</i>]
 *
 * @see _append_retrieve
 *
 * @appliesTo Combo_Box, List_Box
 *
 * @categories Combo_Box_Methods, List_Box_Methods
 *
 */
void _delete_retrieve_list(_str object_name='')
{
   int form_wid=p_active_form;
   _str form_name=form_wid.p_name;
   _str ctl_name=p_name;
   if (object_name!='') {
      if(pos('.',object_name)){
         parse object_name with form_name '.' ctl_name ;
      } else {
         ctl_name=object_name;
      }
   }
   if (form_name=='' || ctl_name=='') {
      return;
   }
   int view_id=0;
   get_window_id(view_id);
   int output_wid=p_window_id;
   activate_window(_GetDialogHistoryViewId());
   top();
   typeless status=search("^"form_name"."ctl_name'\:',"@re");
   if (status) {
      status=search("^"form_name'\:',"@re");
   }
   if (status) {
      activate_window(view_id);
      return;
   }
   _str line="";
   get_line(line);
   typeless NoflinesThatFollow="", NoflinesToCurRetrieve="";
   parse line with form_name':'NoflinesThatFollow NoflinesToCurRetrieve;
   _delete_line();
   while(NoflinesThatFollow--){
      _delete_line();
   }
   activate_window(view_id);
}

/**
 * Sets text box <b>p_text</b> property to value saved by  the
 * <b>_append_retrieve</b> function.  When no argument is given, the
 * history is retrieved based on the active form name and active control
 * name (<b>p_name</b>).  If the <i>cmdline</i> argument does not
 * contain a '.', the history is based on the active form name and
 * <i>cmdline</i> specifies an alternate control name.
 *
 * @return Returns the value placed into the p_text property.
 *
 * @param cmdline is a string in the format: <i>form_name</i>[<i>.ctl_name</i>]
 *
 * @example
 * <pre>
 * defeventtab form1;
 * combo1.on_destroy()
 * {
 *     // When OK button is pressed, you will want to save combo box
 * retrieve information.
 *     _append_retrieve(_control combo1,combo1.p_text);
 * }
 * combo1.on_create()
 * {
 *      // Fill in the combo box list
 *      _retrieve_value();
 * }
 * </pre>
 *
 * @see _append_retrieve
 *
 * @categories Retrieve_Functions
 *
 */
typeless _retrieve_value(_str cmdline="")
{
   int form_wid=p_active_form;
   _str form_name=form_wid.p_name;
   _str ctl_name=p_name;
   if (cmdline!='') {
      if(pos('.',cmdline)){
         parse cmdline with form_name '.' ctl_name ;
      } else {
         ctl_name=cmdline;
      }
   }
   if (form_name=='' || ctl_name=='') return("");
   int view_id=0;
   get_window_id(view_id);
   int output_wid=p_window_id;
   activate_window(_GetDialogHistoryViewId());
   top();
   typeless status=search("^"form_name"."ctl_name'\:',"@re");
   if (status) {
      status=search("^"form_name'\:',"@re");
   }
   if (status) {
      activate_window(view_id);
      return("");
   }
   _str line="";
   get_line(line);
   typeless NoflinesThatFollow="", NoflinesToCurRetrieve="";
   parse line with form_name':'NoflinesThatFollow NoflinesToCurRetrieve;
   if (NoflinesThatFollow<=0) {
      activate_window(view_id);
      return("");
   }
   down();
   _str data="";
   get_line(data);
   _str result="";
   for (;;) {
      _str ctl_data="";
      parse data with (CTLSEPARATOR) ctl_data (CTLSEPARATOR) +0 data;
      if (ctl_data=="") break;
      typeless dctl_type="", dctl_name="", value="";
      parse ctl_data with dctl_type dctl_name':' value;
      if (dctl_name:==ctl_name) {
         result=value;
         _set_retrieve_value(form_wid,'',ctl_data);
         break;
      }
   }
   activate_window(view_id);
   //if (find_last_only) return(value);
   if (output_wid.p_object==OI_COMBO_BOX) {
      // Try to find current text value in list
      status=_cbi_search('','$');
      if (!status) {
         _lbselect_line();
      }
   }
   return(result);
}
void _DialogClearRetrieval(_str ObjectName)
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(_GetDialogHistoryViewId());
   top();
   int status=search('^'ObjectName'\:','r@');
   if (!status) {
      get_line(auto line);
      _str form_name="";
      typeless NoflinesThatFollow="", NoflinesToCurRetrieve="";
      parse line with form_name':'NoflinesThatFollow NoflinesToCurRetrieve;
      if (isinteger(NoflinesThatFollow) && NoflinesThatFollow>0) {
         _delete_line();
         while (NoflinesThatFollow--) {
            _delete_line();
         }
      }
   }
   activate_window(orig_view_id);
}


/**
 * @return  Returns the parent window id of the active form.  If the p_parent
 * property of the active form is 0, the active MDI edit window is returned
 * (_mdi.<b>p_child</b>).   Some dialog boxes such as the Replace and Spelling
 * dialog boxes determine what buffer they are operating on by calling this
 * function.  It is probably sufficient to use the expression
 * (<b>p_active_form.p_parent</b>).  We added this function just in case it is
 * needed for portability.
 *
 * @appliesTo  All_Window_Objects
 *
 * @categories Form_Functions
 */
int _form_parent()
{
  int wid=p_active_form.p_parent;
  if (!wid) {
     return(_mdi.p_child);
  }
  return(wid);
}

/**
 * Copies specified area of source buffer to the current buffer.
 * If <i>start_col</i> and <i>end_col</i> are not specified or '', the source lines are
 * inserted after the current line.  Otherwise the source text is inserted before the cursor position.
 *
 * @param src_buf_id
 * @param start_linenum
 *                   Source start line.  Defaults to first line of source buffer
 * @param end_linenum
 *                   Source end line.  Defaults to last line of source buffer
 * @param start_col  Source start column.
 * @param end_col    Source end column.
 *
 *
 * @return Returns 0 if successful.  Otherwise, message box error is displayed.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
int _buf_transfer(int src_buf_id,
                  int start_linenum=1,int end_linenum=-1,
                  int start_col=0,int end_col=0)
{
   int orig_view_id=0;
   if (src_buf_id<0) {
      get_window_id(orig_view_id);
      activate_window(src_buf_id);
      src_buf_id=p_buf_id;
      activate_window(orig_view_id);
   }
   typeless mark=_alloc_selection();
   if (mark<0) {
      _message_box('Unable to transfer data.  'get_message(TOO_MANY_SELECTIONS_RC));
      return(TOO_MANY_SELECTIONS_RC);
   }
   int orig_buf_id=p_buf_id;
   save_pos(auto p);
   p_buf_id=src_buf_id;
   p_line=start_linenum;_begin_line();
   // If there is no data to copy
   if (_on_line0()) {
      p_buf_id=orig_buf_id;
      return(0);
   }
   if (start_col<=0 && end_col<=0) {
      _select_line(mark);
      if (end_linenum<0) {
         bottom();
      } else {
         p_line=end_linenum;
      }
      _select_line(mark);
   } else {
      if (start_col>0) p_col=start_col;
      _select_char(mark);
      if (end_linenum<0) {
         bottom();
      } else {
         p_line=end_linenum;
      }
      if (end_col>0) p_col=end_col;
      _select_char(mark);
   }
   p_buf_id=orig_buf_id;
   restore_pos(p);
   _copy_to_cursor(mark);_end_select(mark);
   _free_selection(mark);
   return(0);
}
/**
 * Converts the <i>x</i> and <i>y</i> variables which are in the scale,
 * <i>in_scale_mode,</i> to the scale <i>out_scale_mode</i>.  The scale mode
 * parameters may be SM_PIXEL or SM_TWIP.
 *
 * @see _lx2dx
 * @see _lx2lx
 * @see _dx2lx
 * @see _lxy2lxy
 * @see _dxy2lxy
 * @see _lxy2dxy
 * @see _ly2dy
 * @see _ly2ly
 * @see _dy2ly
 * @see _map_xy
 *
 * @categories Miscellaneous_Functions
 *
 */
void _lxy2lxy(int in_scale,int out_scale,int &x,int &y)
{
   _lxy2dxy(in_scale,x,y);
   _dxy2lxy(out_scale,x,y);
}
/**
 * @return Returns the x coordinate which is the scale,
 * <i>in_scale_mode,</i> converted to scale, <i>out_scale_mode</i>.  The scale
 * mode parameters may be SM_PIXEL or SM_TWIP.
 *
 * @see _lx2dx
 * @see _dx2lx
 * @see _lxy2lxy
 * @see _dxy2lxy
 * @see _lxy2dxy
 * @see _ly2dy
 * @see _ly2ly
 * @see _dy2ly
 * @see _map_xy
 *
 * @categories Miscellaneous_Functions
 *
 */
int _lx2lx(int in_scale,int out_scale,int x)
{
   int y=0;
   _lxy2dxy(in_scale,x,y);
   _dxy2lxy(out_scale,x,y);
   return(x);
}
/**
 * @return Returns the <i>y</i> coordinate which is in the scale,
 * <i>in_scale_mode,</i> converted to scale, <i>out_scale_mode</i>.  The scale
 * mode parameters may be SM_PIXEL or SM_TWIP.
 *
 * @see _lx2dx
 * @see _lx2lx
 * @see _dx2lx
 * @see _lxy2lxy
 * @see _dxy2lxy
 * @see _lxy2dxy
 * @see _ly2dy
 * @see _dy2ly
 * @see _map_xy
 *
 * @categories Miscellaneous_Functions
 *
 */
int _ly2ly(int in_scale,int out_scale,int y)
{
   int x=0;
   _lxy2dxy(in_scale,x,y);
   _dxy2lxy(out_scale,x,y);
   return(y);
}


/**
 * @return  Returns the x position converted from pixels to the scale
 * mode specified.  <i>scale_mode</i> may be one of the constants SM_
 * TWIP or SM_PIXEL  defined in "slick.sh".
 *
 * @see  _lx2dx
 * @see _lx2lx
 * @see _lxy2lxy
 * @see _dxy2lxy
 * @see _lxy2dxy
 * @see _ly2dy
 * @see _ly2ly
 * @see _dy2ly
 * @see _map_xy
 * @categories Miscellaneous_Functions
 */
int _dx2lx(int scale,int x)
{
   int y=0;
   _dxy2lxy(scale,x,y);
   return(x);
}

/**
 * @return  Returns the y position converted from pixels to the scale mode
 * specified.  <i>scale_mode</i> may be one of the constants SM_TWIP or SM_PIXEL
 * defined in "slick.sh".
 *
 * @see _lx2dx
 * @see _lx2lx
 * @see _dx2lx
 * @see _lxy2lxy
 * @see _dxy2lxy
 * @see _lxy2dxy
 * @see _ly2dy
 * @see _ly2ly
 * @see _map_xy
 * @categories Miscellaneous_Functions
 */

int _dy2ly(int scale,int y)
{
   int x=0;
   _dxy2lxy(scale,x,y);
   return(y);
}
/**
 * @return Returns the x coordinate which is the scale, <i>scale_mode,</i>
 * converted to pixels.  <i>scale_mode</i> may be SM_PIXEL or SM_TWIP.
 *
 * @see _lx2lx
 * @see _dx2lx
 * @see _lxy2lxy
 * @see _dxy2lxy
 * @see _lxy2dxy
 * @see _ly2dy
 * @see _ly2ly
 * @see _dy2ly
 * @see _map_xy
 *
 * @categories Miscellaneous_Functions
 *
 */
int _lx2dx(int scale,int x)
{
   int y=0;
   _lxy2dxy(scale,x,y);
   return(x);
}
/**
 * @return Returns the <i>y</i> coordinate which is in the scale,
 * <i>scale_mode,</i> converted to pixels.  <i>scale_mode</i> may be SM_PIXEL or
 * SM_TWIP.
 *
 * @see _lx2dx
 * @see _lx2lx
 * @see _dx2lx
 * @see _lxy2lxy
 * @see _dxy2lxy
 * @see _lxy2dxy
 * @see _ly2ly
 * @see _dy2ly
 * @see _map_xy
 *
 * @categories Miscellaneous_Functions
 *
 */
int _ly2dy(int scale,int y)
{
   int x=0;
   _lxy2dxy(scale,x,y);
   return(y);
}
/**
 * Helps to ensure that buffer cursor positions are not lost.  Buffer
 * positions can be lost when you switch buffers when a hidden window
 * is active.  Before you switch buffers when the hidden window is
 * active, call this function.
 *
 *  Switching buffers while the hidden window is active can cause the following
 *  problems:
 *
 * <UL>
 * <LI>If a view other than the VSWID_HIDDEN is active, and the original buffer
 *     is not restored, a system macro may start modifying a buffer the user is
 *     editing.</LI>
 *
 * <LI>If the hidden window already has a buffer that the user is editing active, the old
 *     buffer position information may get destroyed.</LI>
 * </UL>
 *
 *
 * @categories Miscellaneous_Functions
 *
 */
void _safe_hidden_window()
{
   if (p_window_flags & HIDE_WINDOW_OVERLAP) {
      activate_window(VSWID_HIDDEN);
      // The +m option preserves the old buffer position information for the current buffer
      load_files('+m +bi 'RETRIEVE_BUF_ID);
   }
}
/*
    This function only supports CHAR or LINE type selections.
*/
_str _QSelection(typeless MustBeOneLine="", typeless MaximumNumberOfBytes="")
{
   MustBeOneLine = MustBeOneLine!="" && MustBeOneLine;
   if (MaximumNumberOfBytes=='') {
      MaximumNumberOfBytes=256000;
   }
   if(!select_active() ) return("");
   if (_select_type()=='BLOCK') {
      return("");
   }
   int start_col=0, end_col=0, buf_id=0;
   _get_selinfo(start_col,end_col,buf_id);
   save_pos(auto p);
   boolean mark_locked=0;
   if (_select_type('','S')=='C') {
      mark_locked=1;
      _select_type('','S','E');
   }
   _begin_select();
   if (_select_type()=='LINE') {
      _begin_line();
   }
   typeless start_offset=_nrseek();
   _end_select();
   if (_select_type()=='CHAR' && _select_type('','I')) {
      if (get_text()=="\r") {
         _end_line();p_col+=2;
      } else {
         right();
      }
   }
   if (_select_type()=='LINE') {
      _end_line();p_col+=2;
   }
   typeless end_offset=_nrseek();
   //_begin_select();
   //messageNwait('start='start_offset' end='end_offset);
   _str text=get_text(end_offset-start_offset,start_offset);
   restore_pos(p);
   if (mark_locked) {
      _select_type('','S','C');
   }
   return(text);
}

/**
 * @return Returns non-zero value if there are no non-hidden MDI edit
 * windows available.
 *
 * @categories Window_Functions
 *
 */
int _no_child_windows()
{
   return(_mdi.p_child.p_window_flags &HIDE_WINDOW_OVERLAP);
}
boolean _isEditorCtl(boolean allowHiddenWindow=true)
{
   return(p_HasBuffer &&
          (p_object==OI_EDITOR ||
            (p_object==OI_FORM && (allowHiddenWindow || !(p_window_flags &HIDE_WINDOW_OVERLAP)))
          )
         );
}
void _ExitScroll()
{
   if(p_scroll_left_edge>=0) p_scroll_left_edge=-1;
}
/**
 * @return Returns <b>true</b> if the encoding will be loaded as UTF-8.
 *
 * <p>This function does not support any AUTO encoding such as
 * "VSENCODING_AUTOUNICODE" which requires reading a files contents to determine
 * if SlickEdit will load the file as UTF-8.</p>
 *
 * @categories Keyboard_Functions
 *
 */
boolean _IsCodePageLoadedAsUTF8(int encoding)
{
   return(encoding!=VSCP_ACTIVE_CODEPAGE && encoding!=VSCP_EBCDIC_SBCS);
}

/**
 * Used in EMACS emulation.  If the cursor is on or before the first non blank character
 * of the current line and the proper C statement indent column is after the current column,
 * then the current statement is reindented and the cursor is placed on the first non blank
 * character.  Otherwise the root key table binding for the TAB key is invoked.  This command
 * should only be bound to a mode key table.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void c_tab,gnu_ctab,smarttab() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_LINEHEX|VSARG2_ONLY_BIND_MODALLY)
{
   if (command_state()) {
      call_root_key(TAB);
      return;
   }
   // Handle Assembler embedded in C
   typeless orig_values='';
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(TAB, "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }
   if (def_modal_tab && select_active() && _within_char_selection()) {
#if 0
      _undo('S');
      _str oldarg=_argument;
      _argument=1;
      _save_pos2(p);
      begin_select();
      int line_top=p_line;
      end_select();
      int line_bottom=p_line;
      end_line_sp=_QROffset();
      deselect();
      for (p_line=line_top;p_line<=line_bottom;down()) {
         begin_line();
         smarttab();
      }
      _restore_pos2(p);
      _argument=oldarg;
      return;
   }else if (select_active()) {
#endif
      indent_selection();
      return;
   }
   if (_on_line0() || !_IsSmartTabEnabled() || def_keys == 'ispf-keys') {
      call_root_key(TAB);
   } else if (_argument=='') {
      _undo('S');
   }
}
int _get_smarttab(_str lang,int &smartpaste_index)
{
   smartpaste_index = _FindLanguageCallbackIndex('%s_smartpaste',lang);
   if (!smartpaste_index) {
      return(0);
   }
   int smarttab_index=find_index('def_smarttab_'lang,MISC_TYPE);
   int SmartTab;
   if (def_smarttab<0) {
      // Override the extension specific setting with the
      // the default extension specific setting
      SmartTab= def_smarttab;
   } else {
      if (smarttab_index) {
         SmartTab=(int)name_info(smarttab_index);
      } else {
         // Use the default extension specific setting
         // for this emulation.  This gives a real convenient way
         // to change the setting for a lot of extensions and
         // still support extension specific settings.
         SmartTab=def_smarttab;
      }
   }
   return(SmartTab);
}
/**
 * @return 
 * Return 'true' if smart tab is enabled for the current language. 
 * Return 'false' if it is disabled or does not apply for the 
 * text currently under the cursor. 
 * 
 * @param SmartTab  VSSMARTTAB_* options, to check for any option. 
 * 
 * @deprecated Use {@link _IsSmartTabEnabled()}.
 */
boolean ext_smarttab(int SmartTab= -1)
{
   return !_IsSmartTabEnabled(SmartTab); 
}
/**
 * @return 
 * Return 'true' if smart tab is enabled for the current language.
 * 
 * @param SmartTab  VSSMARTTAB_* options, to check for any option. 
 *  
 * @since 13.0 
 */
boolean _IsSmartTabEnabled(int SmartTab= -1)
{
   int smartpaste_index=0;
   if (SmartTab<0) {
      SmartTab=_get_smarttab(p_LangId,smartpaste_index);
      if (SmartTab<0) SmartTab= -SmartTab;
   } else {
      _get_smarttab(p_LangId,smartpaste_index);
      if (!smartpaste_index) return(true);
   }
   // check if smart tab or re-indent line is turned on
   if (p_indent_style!=INDENT_SMART || SmartTab == VSSMARTTAB_INDENT) {
      return(false);
   }
   // check if we are in a comment
   if (_smart_in_comment(false)) {
      // return 'true' for always re-indent, we don't want to insert 
      // a tab for a line we don't know how to indent.
      return(SmartTab == VSSMARTTAB_ALWAYS_REINDENT);
   }
   int syntax_indent=p_SyntaxIndent;
   _str line="";
   get_line(line);

   // if VSSMARTTAB_REINDENT_IF_BEFORE or VSSMARTTAB_MAYBE_REINDENT then smarttab
   // only applies if cursor is in preceding whitespace so check for that
   if ((SmartTab == VSSMARTTAB_MAYBE_REINDENT || SmartTab == VSSMARTTAB_MAYBE_REINDENT_STRICT) &&
       expand_tabs(line,1,p_col-1)!='' || syntax_indent<=0 || _on_line0()) {
      //say('f1');
      return(false);
   }
   save_pos(auto p);
   typeless orig_markid=_duplicate_selection('');
   typeless markid=_alloc_selection();_select_line(markid);
   _show_selection(markid);
   typeless enter_col=call_index(true, // char type clipboard so we try harder
                        2,    // first col not 1 so we try harder
                        1,    // Noflines==1
                        true, // allow the enter_col = 1
                        smartpaste_index
                        );
   _show_selection(orig_markid);_free_selection(markid);
   restore_pos(p);

   // if there is no indent column, insert normal tab
   if (!enter_col) {
      // return 'true' for always re-indent, even though we haven't
      // done anything to the line, we don't want to insert a tab
      // for a line we don't know how to indent.
      return(SmartTab == VSSMARTTAB_ALWAYS_REINDENT);
   }

   // handle VSSMARTTAB_REINDENT_ALWAYS (6.0 gnu-ctab functionality)
   if(SmartTab == VSSMARTTAB_ALWAYS_REINDENT) {
      // remember the offset of the cursor within the text
      // NOTE: this is currently done the easy way by just calculating
      //       the difference in the columns
      int origCol = p_col;
      first_non_blank();
      int colOffset = origCol - p_col;
      if(colOffset < 0) {
         // if the cursor preceded the line, leave the cursor at the
         // beginning of the text
         colOffset = 0;
      }

      replace_line(reindent_line(strip(line,'L'),enter_col-1, true));

      // correct the cursor offset within the text
      first_non_blank();
      p_col = p_col + colOffset;

      //say('f2');
      return true;
   }

   _str tline=expand_tabs(line);

   // if VSSMARTTAB_MAYBE_REINDENT then smarttab only reindents if the cursor
   // is before the proper indentation level.  if the cursor is after that
   // point, a normal tab is inserted so check for that
   if (SmartTab == VSSMARTTAB_MAYBE_REINDENT &&
       enter_col<=p_col && (_rawSubstr(tline,p_col,1)!='' || line=='')) {
      //say('f4');
      return(false);
   }

   // fall thru handles VSSMARTTAB_REINDENT_IF_BEFORE and reindent case
   // for VSSMARTTAB_MAYBE_REINDENT
   replace_line(reindent_line(strip(line,'L'),enter_col-1));
   p_col=enter_col;
   //say('got here');
   return(true);
}

/**
 * Case-sensitive comparison of strings 's1' and 's2'.
 *
 * @param s1   first string
 * @param s2   second string
 *
 * @return 0 if the are equal, <0 if s1<s2, >0 if s1>s2
 */
int StringCompare(_str s1, _str s2)
{
   if (s1 < s2) {
      return(-1);
   }
   if (s1 > s2) {
      return(1);
   }
   return(0);
}
/**
 * Looks for the given <B>item</B> in a sorted array <B>a</B>.
 *
 * @param pArray     Slick-C&reg; array to search.
 *                   Must be sorted in non-decreasing order
 * @param item       item to search for
 * @param pfnCompare Item comparison function
 *
 * @return If found, the index of the item is returned.
 *         If not found, return STRING_NOT_FOUND_RC;
 */
int ArraySearch(typeless (&a)[],typeless item,typeless *pfnCompare)
{
   int lo=0, hi=a._length()-1;
   int mid,status;

   for (;;) {
      if (hi<0 || lo>hi) {
         break;
      }
      mid=((hi-lo)intdiv 2)+lo;
      status=(*pfnCompare)(item,a[mid]);
      if (!status) {
         return(mid);
      }
      if (status<0) {
         hi=mid-1;
      } else {
         lo=mid+1;
      }
   }

   // didn't find the item
   return(STRING_NOT_FOUND_RC);
}

/**
 * Returns false if the specified dll is not available
 *
 * @param filename dll to check
 *
 * @return true if the dll is missing
 */
boolean DllIsMissing(_str filename)
{
#if __UNIX__
   return(false);
#else
   _str dllName=_strip_filename(filename,'P');
   if ( pos(' 'dllName' ',' 'gMissingDllList' ',1,_fpos_case) ) {
      return(true);
   }
   return(false);
#endif
}

/**
 * Write a string to the SlickEdit debug window,
 * indented by the specified number of tabs.
 *
 * @param level      indentation level
 * @param string     string to display
 *
 * @categories Debugger_Functions
 */
void isay(int level, _str string)
{
   _str indent = '';
   int i;
   for (i=0; i<level; ++i) {
      strappend(indent,':   ');
   }
   say(indent:+string);
}
/**
 * Opens <i>filename</i> specified and creates a window and buffer to hold it.
 * The VSBUFFLAG_HIDDEN flag is added to the p_buf_flags
 * property of the buffer so that the buffer will not be display in a user
 * buffer list.  <i>temp_wid</i> is set to the id of the new window created.
 * <i>orig_wid</i> is set to the previously active window id.  If
 * <i>load_options</i> are specified, these options are used to load the file.
 * <p>
 * WARNING: If you specify the +b option, you can not specify other options.
 *
 * @param filename Name of file to open
 * @param temp_wid
 *                 Window id of file that is opened
 * @param orig_wid
 *                 Original window id
 * @param load_options
 *                 may be "" or only may contain the following
 *                 <UL>
 *                 <LI> +bi &lt;buf_id&gt;
 *                 <LI> +d
 *                 <LI> +b
 *                 </UL>
 * @param buffer_already_exists
 *                 Get set to true if the file was already open
 * @param doClear
 * @param doSelectEditorLanguage
 *                 When true, _SetEditorLanguage() is called to initialize the
 *                 language setup for the buffer. In addition,
 *                 build_load_options() to generate all default load options
 *                 which typically turns on undo.
 * @param more_buf_flags
 *                 Allows more buffer flags (typically VSBUFFLAG_THROW_AWAY_CHANGES) to be added to buffers loaded from disk.
 * @param doCreateIfNotFound
 *                 When true, a file (not buffer) is specified, and the file is not found, a new files
 *                 is created.
 * @param doCallSelectEditModeLater
 *                 When true, only build_load_options is called. _SetEditorLanguage
 *                 is not called and should be invoked by the caller if necessary.
 *                 This has no effect unless doSelectEditorLanguage is true.
 *
 * @return Returns 0 if successful.
 *
 * @see load_files
 * @categories File_Functions, Miscellaneous_Functions
 */
int _open_temp_view(_str filename,int &temp_wid,int &orig_wid,
                    _str load_options="",boolean &buffer_already_exists=true,
                    boolean doClear=false,
                    boolean doSelectEditorLanguage=false, int more_buf_flags=0,
                    boolean doCreateIfNotFound=false,
                    boolean doCallSelectEditModeLater=false)
{
   //say('f='filename' l='load_options' dos='doSelectEditorLanguage);
   filename=strip(filename,'B','"');
   typeless buf_id="";
   parse load_options with '+bi 'buf_id;
   get_window_id(orig_wid);
   if (filename=='' && buf_id=='') {
      return(FILE_NOT_FOUND_RC);
   }
   buffer_already_exists=1;
   typeless status=0;
   if (buf_id!='') {
      status=_BufLoad(filename,load_options);
   } else if (pos(' +b ',' 'load_options' ')) {
      status=_BufLoad(filename,load_options);
   } else if (pos(' +t',' 'load_options' ')) {
      if (filename!='') {
         if (doSelectEditorLanguage) {
            load_options=build_load_options(filename)' 'load_options;
         } else {
            load_options=_load_option_encoding(filename)' 'load_options;
         }
      }

      if (filename=='') {
         load_options='+q +futf8 'load_options;
      } else {
         load_options='+q 'load_options;
      }

      status=_BufLoad(null,load_options);
      if ( status<0 ) {
         _message_box('Unable to create temporary buffer');
         return(0);
      }
      temp_wid=_CreateTempEditor2(status);
      _delete_line();
      p_buf_name=filename;
      p_buf_flags=p_buf_flags|VSBUFFLAG_HIDDEN|more_buf_flags;
      if (doSelectEditorLanguage && !doCallSelectEditModeLater) {
         p_buf_flags|=VSBUFFLAG_PROMPT_REPLACE;
         _SetEditorLanguage('',false,false,true);
      }
      return(0);
   } else {
      buffer_already_exists=
         (!pos(' +d ',' 'lowcase(load_options)' ') &&
          buf_match(absolute(filename),1,'hx')!=''
         );
      _str options='';
      if (!buffer_already_exists) {
         if (doSelectEditorLanguage) {
            options=build_load_options(filename);
         } else {
            options=_load_option_encoding(filename);
         }
      }
      status=_BufLoad(filename,options' 'load_options,doCreateIfNotFound);
      //status=load_files(options' +q 'load_options' 'maybe_quote_filename(filename));
   }
   if (status<0) {
      return(status);
   }
   temp_wid=_CreateTempEditor2(status);
   if (doClear) {
      _lbclear();
   }
   //get_window_id(temp_wid);
   if (!buffer_already_exists) {
      p_buf_flags=p_buf_flags | VSBUFFLAG_HIDDEN|more_buf_flags;
      if (doSelectEditorLanguage && !doCallSelectEditModeLater) {
         _SetEditorLanguage('',false,false,true);
      }
   }
   return(0);
}

/**
 * Creates a temporary window, and buffer.  This function is used to create lists or
 * process files you any editing feature without the buffer being displayed.
 *
 * @param temp_wid
 *                 Window id of file that is opened
 * @param load_options
 *                 may be "" or only may contain the following
 *                 <UL>
 *                 <LI> +bi &lt;buf_id&gt;
 *                 <LI> +d
 *                 <LI> +b
 *                 </UL>
 * @param buf_name Specified buffer name for temp window/buffer.
 * @param doSelectEditorLanguage 
 *                 When true, _SetEditorLanguage() is called to initialize the
 *                 language setup for the buffer.  In addition,
 *                 build_load_options() to generate all default load options
 *                 which typically turns on undo.
 * @param more_buf_flags
 *                 Allows more buffer flags (typically VSBUFFLAG_THROW_AWAY_CHANGES) to be added to buffers loaded from disk.
 *
 * @return If successful, <i>temp_wid</i> is set to the window created,
 *         the new window is active, and the original window id is returned.  On error,
 *         0 is returned and message box is displayed.
 * @example
 * <pre>
 * #include "slick.sh"
 * defmain()
 * {
 *     orig_wid=_create_temp_view(temp_wid);
 *     if (orig_wid=='') return(1);
 *     // The buffer and window allocated by _create_temp_view are active
 *     _lbadd_item('a');
 *     _lbadd_item('b');
 *     _lbadd_item('c');
 *     //  The original window must be activated before showing the _sellist_form
 *     activate_window(orig_wid);
 *     result=show('_sellist_form -mdi -modal',
 *                 "Sample Selection List",
 *                 SL_VIEWID|SL_SELECTCLINE, // Indicate the next argument is a window id
 *                 temp_wid,
 *                 "OK",
 *                 "",  // Help item
 *                 '',  // Use default font
 *                 ""      // Call back function
 *                );
 *       if (result) {
 *            message("Item selected is "result);
 *       } else {
 *            message("Selection list cancelled");
 *       }
 * }
 * </pre>
 *
 * @see _sellist_form
 * @see _delete_temp_view 
 *  
 * @categories Miscellaneous_Functions
 */
int _create_temp_view(int &temp_wid, 
                      _str load_options='',
                      _str buf_name='',
                      boolean doSelectEditorLanguage=false,
                      int more_buf_flags=0)
{
   int orig_wid=0;
   get_window_id(orig_wid);

   if (load_options=='') {
      load_options='+t';
   }
   if (buf_name!='') {
      if (doSelectEditorLanguage) {
         load_options=build_load_options(buf_name)' 'load_options;
      } else {
         load_options=_load_option_encoding(buf_name)' 'load_options;
      }
   }

   if (buf_name=='') {
      load_options='+q +futf8 'load_options;
   } else {
      load_options='+q 'load_options;
   }
   // Now create a buffer in the hidden window
   typeless status=_BufLoad(null,load_options);
   if ( status<0 ) {
      _message_box('Unable to create temporary buffer');
      return(0);
   }
   temp_wid=_CreateTempEditor2(status);
   _delete_line();
   p_buf_name=buf_name;
   p_buf_flags=p_buf_flags|VSBUFFLAG_HIDDEN|more_buf_flags;
   if (doSelectEditorLanguage) {
      p_buf_flags|=VSBUFFLAG_PROMPT_REPLACE;
      _SetEditorLanguage();
   }
   return(orig_wid);
}

/**
 * Deletes temp window and buffer corresponding to <i>temp_wid</i>.
 *
 * @param temp_wid
 *               should have been returned by the <b>_create_temp_view</b> function.
 *               If <i>temp_wid</i> is not given,
 *               current window and buffer are deleted.
 * @param dodelete_buffer
 *               If false, the buffer attached to
 *               the window is not deleted.
 * @categories Selection_Functions
 */
void _delete_temp_view(_str temp_wid='',boolean dodelete_buffer=true)
{
   if (temp_wid=='') {
      //say('_delete_temp_view: h1 filename='p_buf_name);
      // VSBUFFLAG_HIDDEN means that there must NOT be an MDI child displaying
      // this buffer.
      // IF call wants delete AND no mdi child with buffer AND
      //    no dialog viewing this buffer
      if (dodelete_buffer && (p_buf_flags & VSBUFFLAG_HIDDEN) &&
          _SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)
          ) {
         //messageNwait('deleting buffer');
         _delete_buffer();
      }
      // delete window does not delete buffers in windows created by _CreateTempEditor2
      _delete_window();
      return;
   }
   int orig_wid=0;
   get_window_id(orig_wid);
   activate_window((int)temp_wid);
   //say('_delete_temp_view: h2 filename='p_buf_name);
   // VSBUFFLAG_HIDDEN means that there must NOT be an MDI child displaying
   // this buffer.
   // IF call wants delete AND no mdi child with buffer AND
   //    no dialog viewing this buffer
   if (dodelete_buffer && (p_buf_flags & VSBUFFLAG_HIDDEN) &&
       _SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)
       ) {
      //_message_box('delete buffer');
      _delete_buffer();
   }
   // delete window does not delete buffers in windows created by _CreateTempEditor2
   _delete_window();
   if (orig_wid!=temp_wid) activate_window(orig_wid);
}


/**
 * Activates the temp window and buffer name specified.
 *
 * @appliesTo Edit_Window
 * @categories Buffer_Functions
 * @param buf_name  Name of buffer to search for.
 *
 * @return Returns 0 if successful.  Otherwise, a non-zero value is
 *         returned.
 */
int find_view(_str buf_name)
{
   int i;
   for (i=1;i<=_last_window_id();++i) {
      if (_iswindow_valid(i) && i.p_object==OI_EDITOR && i.p_IsTempEditor &&
          file_eq(i.p_buf_name,buf_name)
         ) {
         p_window_id=i;
         return(0);
      }
   }
   return(1);
}
/**
 * Activates the temp window/buffer for buffer name specified.  If the
 * buffer does not exists, a temp window/buffer is created.
 *
 * @param temp_wid
 * @param load_options
 *                 Load options supported by {@link _create_temp_view()}.
 * @param buf_name Name of buffer to search for.
 * @param doSelectEditorLanguage
 *                 When true, _SetEditorLanguage() is called to initialize the
 *                 language setup for the buffer.  In addition,
 *                 build_load_options() to generate all default load options
 *                 which typically turns on undo.
 * @param more_buf_flags
 *                 Allows more buffer flags (typically VSBUFFLAG_THROW_AWAY_CHANGES) to be added to buffers loaded from disk.
 * @param doClear  Indicates whether the contents of the buffer should always be cleared.
 *
 * @return Returns previously active window
 * 
 * @appliesTo Edit_Window
 * @categories Buffer_Functions
 */
int _find_or_create_temp_view(int &temp_wid,
                              _str load_options='',
                              _str buf_name='',
                              boolean doSelectEditorLanguage=false,
                              int more_buf_flags=0,
                              boolean doClear=false
                              )
{
   int orig_wid=0;
   get_window_id(orig_wid);
   typeless status=find_view(buf_name);
   if (status) {
      _create_temp_view(temp_wid,load_options,buf_name,doSelectEditorLanguage,more_buf_flags);
   } else {
      temp_wid=p_window_id;
      if (doClear) {
         _lbclear();
      }
   }
   return(orig_wid);
}
/**
 * Activates the temp window/buffer for buffer name specified.  If the
 * buffer does not exists, a temp window/buffer is created.
 *
 * @param buf_name Name of buffer to search for.
 * @param temp_wid
 *                 Window id of file that is opened
 * @param orig_wid
 *                 Original window id
 * @param load_options
 *                 Load options supported by {@link _open_temp_view()}.
 * @param buffer_already_exists
 *                 Set to true if the buffer already existed.
 * @param doClear  Indicates whether the contents of the buffer should always be cleared.
 * @param doSelectEditorLanguage 
 *                 When true, _SetEditorLanguage() is called to initialize the
 *                 language setup for the buffer.  In addition,
 *                 build_load_options() to generate all default load options
 *                 which typically turns on undo.
 * @param more_buf_flags
 *                 Allows more buffer flags (typically VSBUFFLAG_THROW_AWAY_CHANGES) to be added to buffers loaded from disk.
 * @param doCreateIfNotFound
 *                 When true, a file (not buffer) is specified, and the file is not found, a new files
 *                 is created.
 *
 * @return Returns 0 if successful.  Otherwise, a non-zero value is
 *         returned.
 * 
 * @appliesTo Edit_Window
 * @categories Buffer_Functions
 */
int _find_or_open_temp_view(_str buf_name,
                            int &temp_wid,
                            int &orig_wid,
                            _str load_options='',
                            boolean &buffer_already_exists=false,
                            boolean doClear=false,
                            boolean doSelectEditorLanguage=false,
                            int more_buf_flags=0,
                            boolean doCreateIfNotFound=false)
{
   get_window_id(orig_wid);
   buffer_already_exists=true;
   typeless status=find_view(buf_name);
   if (status) {
      int orig_wid2;
      boolean buffer_already_exists2;
      status=_open_temp_view(buf_name,temp_wid,orig_wid2,load_options,
                             buffer_already_exists2,doClear,
                             doSelectEditorLanguage,more_buf_flags,doCreateIfNotFound);
   } else {
      if (doClear) {
         _lbclear();
      }
      get_window_id(temp_wid);
   }
   return(status);
}

/**
 * Copy the number of lines specified starting from the
 * current line into the view specified.
 *
 * @param temp_view_id
 * @param Noflines
 * @param preserverCurrentData
 */
void _copy_into_view(_str view_buf_name,int &temp_view_id,int Noflines,boolean preserverCurrentData=true)
{
   int orig_view_id;
   get_window_id(orig_view_id);
   int src_buf_id=p_buf_id;
   int src_start_line=p_line;
   if (temp_view_id) {
      activate_window(temp_view_id);
      if (!preserverCurrentData) {
         _lbclear();
      }
   } else {
      _create_temp_view(temp_view_id);
      p_buf_name=view_buf_name;
   }
   if (Noflines) {
      // Copy the data from the buffer into the temp view
      _buf_transfer(src_buf_id,src_start_line,src_start_line+Noflines-1);
   }
   activate_window(orig_view_id);
}

/**
 * Copy the number of lines specified into the temp view
 * specified.
 *
 * @param temp_view_id
 * @param Noflines_copied      (output). Number of lines copied.
 * @param start_linenum
 * @param end_linenum
 */
void _copy_from_view(int temp_view_id,int &NoflinesCopied,int start_linenum=1,int end_linenum=-1)
{
   int orig_view_id;
   get_window_id(orig_view_id);
   activate_window(temp_view_id);
   int src_buf_id=p_buf_id;
   if (end_linenum<0) {
      end_linenum=p_Noflines;
   }
   if (start_linenum>end_linenum) {
      NoflinesCopied=0;
      return;
   }
   NoflinesCopied=end_linenum-start_linenum+1;
   activate_window(orig_view_id);
   _buf_transfer(src_buf_id,start_linenum,end_linenum);
}

/**
 * Deletes the temp window and buffer for the buffer name specified.
 *
 * @appliesTo Edit_Window
 * @categories Buffer_Functions
 * @param buf_name  Name of buffer to search for.
 *
 * @return Returns 0 if successful.  Otherwise, a non-zero value is
 *         returned.
 */
void _find_and_delete_temp_view(_str buf_name)
{
   //say('_find_and_delete_temp_view: 'buf_name);
   int orig_wid=p_window_id;
   boolean doRestore=false;
   if( !find_view(buf_name) ) {
      /*say('_find_and_delete_temp_view: h1 name='p_buf_name);
      if ((p_buf_flags & VSBUFFLAG_HIDDEN) &&
          _SafeToDeleteBuffer(p_buf_id,p_window_id,p_buf_flags)
          ) {
         say('delete it');
      }
      */

      if (p_window_id!=orig_wid) doRestore=true;
      _delete_temp_view();
   }
   if (doRestore) p_window_id=orig_wid;
}

/**
 * Kill process and all process children.
 *
 * @param pid          Process id of process to kill.
 * @param exit_code    Exit code of process.
 * @param process_list (optional). Initial process list created by _list_processes.
 *                     If null, then the initial process list will be generated.
 *
 * @return 0 on success.
 *
 * @see _list_processes
 * @see _IsProcessRunning
 */
int _kill_process_tree(int pid,int &exit_code,PROCESS_INFO (&process_list)[]=null)
{
   if (process_list==null) {
      _list_processes(process_list);
   }
   int len=process_list._length();
   int i;
   for (i=0;i<len;++i) {
      if (pid==process_list[i].parent_pid) {
         _kill_process_tree(process_list[i].pid,exit_code,process_list);
      }
   }
   if (_IsProcessRunning(pid)) {
      _kill_process(pid,exit_code);
   }
   return(0);
}

/**
 * Substitues DOS style embedded environment variables
 * in the format %ENVVAR% with corresponding value.
 *
 * @param string Input string.
 * @return Return string with %ENVVAR% specifications replaced
 *         with values.
 * @see _replace_envvars2()
 */
_str _replace_envvars(_str string)
{
   _str result='';
   _str before='';
   _str name='';
   _str v='';
   for (;;) {
      parse string with before '%' name '%' +0 string;
      if ( string:=='' ) {
         /* if there is no ending percent, loose text. */
         return(result:+before);
      }
      string=substr(string,2);
      if ( name:=='' ) {
         v='%';
      } else {
         name=env_case(name);
         v=get_env(name);
         if ( rc ) { /* Environment variable name does not exist. */
            /* Check for special name. */
            if ( name=='CWD' ) {
               v=getcwd();
            } else if ( name=='CURDRIVE' ) {
#if ! __UNIX__
               v=substr(getcwd(),1,2);
#else
               v="";
#endif
            } else if (name=="VSLICKCONFIG" && v=='') {
               // as of SlickEdit 2008, there is no more VSLICKCONFIG
               // so fake it out if a template encodes it
               v = _ConfigPath();
            }
         }
      }
      result=result:+before:+v;
   }
}

/**
 * Reconstruct path(s) by replacing occurrences of root directory stored in EnvVarName
 * with environment-encoded %EnvVarName%. This allows files and directories that are
 * relative to a root directory to move around when that root directory
 * moves (e.g. on product reinstalls, etc.).
 *
 * @param paths       Path(s) to convert. Paths are separated by PATHSEP.
 * @param isFilename  Set to true to indicate that path(s) are filenames,
 *                    not directories.
 * @param EnvVarName  Name of environment variable that stores root directory.
 * @param allowDotDot (optional). Set to false to disallow path(s) to be
 *                    reconstructed relative to parent (../).
 *                    Defaults to true.
 *
 * @return Path(s) reconstructed as relative to root directory.
 *
 * @example
 * Assuming VSROOT=c:\SlickEdit\
 * _encode_env_root("c:\SlickEdit\macros\main.e",true,"VSROOT") => "%VSROOT%macros\main.e"
 */
_str _encode_env_root(_str paths, boolean isFilename, _str EnvVarName, boolean allowDotDot=true)
{
   _str root = get_env(EnvVarName);
   if( root=="" ) {
      // Nothing to encode
      return paths;
   }
   _str result = "";
   _str path = "";
   for( ;; ) {
      parse paths with path (PATHSEP) paths;
      if( path=="" ) {
         break;
      }
      if( !isFilename && last_char(path)!=FILESEP ) {
         path=path:+FILESEP;
      }
      _str prefix = '%'EnvVarName'%';
      _str prefixpath = root;
      for( ;; ) {
         if( length(prefixpath) <= 3 ) {
            if( result!="" ) {
               result=result:+PATHSEP;
            }
            result=result:+path;
            break;
         }
         if( file_eq(prefixpath,substr(path,1,length(prefixpath))) ) {
            if( result!="" ) {
               result=result:+PATHSEP;
            }
            result=result:+prefix:+substr(path,length(prefixpath)+1);
            break;
         }
         if( !allowDotDot ) {
            if( result!="" ) {
               result=result:+PATHSEP;
            }
            result=result:+path;
            break;
         }
         if( last_char(prefixpath)==FILESEP ) {
            prefixpath=substr(prefixpath,1,length(prefixpath)-1);
         }
         prefixpath=_strip_filename(prefixpath,'n');
         prefix=prefix'..'FILESEP;
      }
   }
   return result;
}

/**
 * Reconstruct path(s) by replacing occurrences of root product directory with
 * environment-encoded %VSROOT%. This allows files and directories that are
 * relative to the product directory to move around when the product directory
 * moves (e.g. reinstall).
 *
 * @param paths        Path(s) to convert. Paths are separated by PATHSEP.
 * @param isFilename   Set to true to indicate that path(s) are filenames,
 *                     not directories.
 * @param allowDotDot  Set to false to disallow path(s) to be reconstructed relative to parent (../).
 *                     Defaults to true.
 *
 * @return Path(s) reconstructed as relative to root product directory.
 */
_str _encode_vsroot(_str paths, boolean isFilename, boolean allowDotDot=true)
{
   return ( _encode_env_root(paths,isFilename,"VSROOT",allowDotDot) );
}
_str _encode_vsenvvars(_str paths, boolean isFilename, boolean allowDotDot=true)
{
   _str result=_encode_env_root(paths,isFilename,"SLICKEDITCONFIGVERSION",allowDotDot);
   return ( _encode_env_root(result,isFilename,"VSROOT",allowDotDot) );
}

/**
 * Reconstruct path(s) by replacing occurrences of root configuration directory with
 * environment-encoded %SLICKEDITCONFIGVERSION%. This allows files and directories that are
 * relative to the configuration directory to move around when the configuration directory
 * moves (e.g. patch, upgrade).
 *
 * @param paths        Path(s) to convert. Paths are separated by PATHSEP.
 * @param isFilename   Set to true to indicate that path(s) are filenames,
 *                     not directories.
 * @param allowDotDot  Set to false to disallow path(s) to be reconstructed relative to parent (../).
 *                     Defaults to true.
 *
 * @return Path(s) reconstructed as relative to root configuration directory.
 */
_str _encode_vslickconfig(_str paths, boolean isFilename, boolean allowDotDot=true)
{
   return ( _encode_env_root(paths,isFilename,"SLICKEDITCONFIGVERSION",allowDotDot) );
}

typedef struct {
   typeless infoArray[];
   typeless infoHashTable:[];
} _GetSetDialogInfo_t;

static _GetSetDialogInfo_t *_getDialogInfoTablePtr(boolean usePUser2)
{
   _GetSetDialogInfo_t *pinfo = (usePUser2)? (&p_user2) : (&p_user);
   if (pinfo == null) return null;
   if ((*pinfo) instanceof _GetSetDialogInfo_t) return pinfo;
   return null;
}

/**
 * Retrieve indexed data from a dialog. Use this instead of using multiple p_user
 * variables for several controls.
 * <p>
 * Use _SetDialogInfo to store data to a dialog by index.
 * <p>
 * This function differs from _GetDialogInfoHt because it retrieves data from an
 * array that is indexed by integer, rather than a hash table key.
 * Use _SetDialogInfoHt, _GetDialogInfoHt to store/retrieve data to/from a
 * dialog by hash table key.
 *
 * @param index     A unique int that represents a given item.  There should be
 *                  a constant for this.
 * @param wid       (optional). If specified, use this control's p_user instead
 *                  of p_active_form. 0 specifies the active form.
 *                  Defaults to 0.
 * @param usePUser2 If true, get the data from the p_user2 property
 *
 * @return Data found with index.
 * @see _SetDialogInfo
 * @see _SetDialogInfoHt
 * @see _GetDialogInfoHt 
 *  
 * @categories Form_Functions 
 */
typeless _GetDialogInfo(int index, int wid=0,boolean usePUser2=false)
{
   if( 0==wid ) {
      // Store for the active form
      wid=p_active_form;
   }
   _GetSetDialogInfo_t *pinfo = wid._getDialogInfoTablePtr(usePUser2);
   if (pinfo==null) return null;
   return ( pinfo->infoArray[index] );
}

/**
 * Retrieve a pointer to indexed data from a dialog. Use this instead 
 * of using multiple p_user variables for several controls.
 * <p>
 * Use _SetDialogInfo to store data to a dialog by index.
 * <p>
 * This function differs from _GetDialogInfoHt because it retrieves data from an
 * array that is indexed by integer, rather than a hash table key.
 * Use _SetDialogInfoHt, _GetDialogInfoHt to store/retrieve data to/from a
 * dialog by hash table key.
 *
 * @param index     A unique int that represents a given item.  There should be
 *                  a constant for this.
 * @param wid       (optional). If specified, use this control's p_user instead
 *                  of p_active_form. 0 specifies the active form.
 *                  Defaults to 0.
 * @param usePUser2 If true, get the data from the p_user2 property
 *
 * @return Data found with index.
 * @see _SetDialogInfo
 * @see _SetDialogInfoHt
 * @see _GetDialogInfoHt 
 *  
 * @categories Form_Functions 
 */
typeless *_GetDialogInfoPtr(int index, int wid=0,boolean usePUser2=false)
{
   if( 0==wid ) {
      // Store for the active form
      wid=p_active_form;
   }
   _GetSetDialogInfo_t *pinfo = wid._getDialogInfoTablePtr(usePUser2);
   if (pinfo==null) return null;
   return ( &pinfo->infoArray[index] );
}

/**
 * Store indexed data to a dialog.  Use this instead of using multiple p_user
 * variables for several controls.
 * <p>
 * Use _GetDialogInfo to retrieve data from a dialog by hash table key.
 * <p>
 * This function differs from _SetDialogInfoHt because it stores data in an
 * array that is indexed by integer, rather than a hash table key.
 * Use _SetDialogInfoHt, _GetDialogInfoHt to store/retrieve data to/from a
 * dialog by hash table key.
 *
 * @param index     A unique int that represents a given item.  There should be
 *                  a constant for this.
 * @param value
 * @param wid       (optional). If specified, use this control's p_user instead
 *                  of p_active_form. 0 specifies the active form.
 *                  Defaults to 0.
 * @param usePUser2 If true, store the data on the p_user2
 *                  property
 *
 * @see _GetDialogInfo
 * @see _SetDialogInfoHt
 * @see _GetDialogInfoHt 
 *  
 * @categories Form_Functions 
 */
void _SetDialogInfo(int index, typeless value, int wid=0,boolean usePUser2=false)
{
   if ( 0==wid ) {
      wid=p_active_form;
   }
   _GetSetDialogInfo_t *pinfo = wid._getDialogInfoTablePtr(usePUser2);
   if (pinfo!=null) {
      pinfo->infoArray[index]=value;
      return;
   }
   _GetSetDialogInfo_t info;
   info.infoArray[index]=value;
   if ( usePUser2 ) {
      wid.p_user2=info;
   }else{
      wid.p_user=info;
   }
}

/**
 * Retrieve data from a dialog indexed by key. Use this instead of using multiple p_user
 * variables for several controls.
 * <p>
 * Use _SetDialogInfoHt to store data to a dialog by hash table key.
 * <p>
 * This function differs from _GetDialogInfo because it retrieves data from a
 * hash table that is indexed by string key, rather than an array.
 * Use _SetDialogInfo, _GetDialogInfo to store/retrieve data to/from a
 * dialog by integer index.
 *
 * @param key       A unique hash table key that represents a given item.
 * @param wid       (optional). If specified, use this control's p_user instead
 *                  of p_active_form. 0 specifies the active form.
 *                  Defaults to 0.
 * @param usePUser2 If true, get the items from the p_user2 property
 *
 * @return Data found with hash table key.
 * @see _SetDialogInfoHt
 * @see _SetDialogInfo
 * @see _GetDialogInfo 
 *  
 * @categories Form_Functions 
 */
typeless _GetDialogInfoHt(_str key, int wid=0,boolean usePUser2=false)
{
   if( 0==wid ) {
      // Store for the active form
      wid=p_active_form;
   }
   _GetSetDialogInfo_t *pinfo = wid._getDialogInfoTablePtr(usePUser2);
   if (pinfo==null) return null;
   if (!pinfo->infoHashTable._indexin(key)) return null;
   return ( pinfo->infoHashTable:[key] );
}

/**
 * Retrieve a pointer to the data from a dialog indexed by key. 
 * Use this instead of using multiple p_user variables for several controls.
 * <p>
 * Use _SetDialogInfoHt to store data to a dialog by hash table key.
 * <p>
 * This function differs from _GetDialogInfo because it retrieves data from a
 * hash table that is indexed by string key, rather than an array.
 * Use _SetDialogInfo, _GetDialogInfo to store/retrieve data to/from a
 * dialog by integer index.
 *
 * @param key       A unique hash table key that represents a given item.
 * @param wid       (optional). If specified, use this control's p_user instead
 *                  of p_active_form. 0 specifies the active form.
 *                  Defaults to 0.
 * @param usePUser2 If true, get the items from the p_user2 property
 *
 * @return Data found with hash table key.
 * @see _SetDialogInfoHt
 * @see _SetDialogInfo
 * @see _GetDialogInfo 
 *  
 * @categories Form_Functions 
 */
typeless *_GetDialogInfoHtPtr(_str key, int wid=0,boolean usePUser2=false)
{
   if( 0==wid ) {
      // Store for the active form
      wid=p_active_form;
   }
   _GetSetDialogInfo_t *pinfo = wid._getDialogInfoTablePtr(usePUser2);
   if (pinfo==null) return null;
   if (!pinfo->infoHashTable._indexin(key)) return null;
   return ( &pinfo->infoHashTable:[key] );
}

/**
 * Store data to a dialog indexed by key.  Use this instead of using multiple p_user
 * variables for several controls.
 * <p>
 * Use _GetDialogInfoHt to retrieve data from a dialog by hash table key.
 * <p>
 * This function differs from _SetDialogInfo because it stores data in a
 * hash table that is indexed by string key, rather than an array.
 * Use _SetDialogInfo, _GetDialogInfo to store/retrieve data to/from a
 * dialog by integer index.
 * <p>
 * IMPORTANT: <br>
 * The old value stored by hash table key is returned. null is returned if
 * there is no old value stored. You should initialize your key/value pairs
 * (e.g. in an on_create event) if you want to safely take advantage of the
 * return value.
 *
 * @param key       A unique hash table key that represents a given item.
 * @param value
 * @param wid       (optional). If specified, use this control's p_user instead
 *                  of p_active_form. 0 specifies the active form.
 *                  Defaults to 0.
 * @param usePUser2 If true, store the data on the p_user2
 *                  property
 *
 * @return Old value stored by key. null is returned if there is no old value stored
 *         for that key.
 * @see _GetDialogInfoHt
 * @see _SetDialogInfo
 * @see _GetDialogInfo 
 *  
 * @categories Form_Functions 
 */
typeless _SetDialogInfoHt(_str key, typeless value, int wid=0,boolean usePUser2=false)
{
   if ( 0==wid ) {
      wid=p_active_form;
   }

   _GetSetDialogInfo_t *pinfo = wid._getDialogInfoTablePtr(usePUser2);
   if (pinfo != null) {
      typeless oldValue = null;
      if (pinfo->infoHashTable._indexin(key)) {
         oldValue = pinfo->infoHashTable:[key];
      }
      pinfo->infoHashTable:[key]=value;
      return oldValue;
   }

   _GetSetDialogInfo_t info;
   info.infoHashTable:[key]=value;
   if ( usePUser2 ) {
      wid.p_user2=info;
   }else{
      wid.p_user=info;
   }
   return null;
}

/**
 * Retrieve a the per-file (per-buffer) data from a indexed by key. 
 * <p>
 * Use {@link _SetBufferInfoHt()} to store data by hash table key.
 *
 * @param key       A unique hash table key that represents a given item.
 *
 * @return Data found with hash table key.
 * @see _SetBufferInfoHt
 * @see _GetBufferInfoHtPtr
 * @see _SetDialogInfoHt 
 *  
 * @categories Buffer_Functions 
 */
typeless *_GetBufferInfoHt(_str key)
{
   if (p_buf_user==null) return null;
   if (p_buf_user._varformat() != VF_HASHTAB) return null;
   typeless (*pinfo):[] = &p_buf_user;
   if (!pinfo->_indexin(key)) return null;
   return ( pinfo->:[key] );
}


/**
 * Retrieve a pointer to the per-file (per-buffer) data from a indexed by key. 
 * <p>
 * Use {@link _SetBufferInfoHt()} to store data by hash table key.
 *
 * @param key       A unique hash table key that represents a given item.
 *
 * @return Data found with hash table key.
 * @see _SetBufferInfoHt
 * @see _GetBufferInfoHt
 * @see _SetDialogInfoHt 
 *  
 * @categories Buffer_Functions 
 */
typeless *_GetBufferInfoHtPtr(_str key)
{
   if (p_buf_user==null) return null;
   if (p_buf_user._varformat() != VF_HASHTAB) return null;
   typeless (*pinfo):[] = &p_buf_user;
   if (!pinfo->_indexin(key)) return null;
   return ( &pinfo->:[key] );
}

/**
 * Store data to the current buffer indexed by the given key. 
 * <p>
 * Use {@link _GetBufferInfoHt()} or {@link _GetBufferInfoHtPtr()} to 
 * retrieve data from a dialog by hash table key.
 * <p>
 * This function differs from {@link _SetDialogInfoHt()} because it stores 
 * data in a hash table per open file (buffer) rather than per-dialog. 
 * <p>
 * IMPORTANT: <br>
 * The old value stored by hash table key is returned. null is returned if
 * there is no old value stored. You should initialize your key/value pairs
 * if you want to safely take advantage of the return value.
 *
 * @param key     A unique hash table key that represents a given item.
 * @param value   value to store in hash table
 *
 * @return Old value stored by key. 
 *         null is returned if there is no old value stored for that key.
 *  
 * @see _GetBufferInfoHt
 * @see _GetBufferInfoHtPtr
 * @see _GetDialogInfoHt
 * @see _SetDialogInfoHt 
 *  
 * @categories Buffer_Functions 
 */
typeless _SetBufferInfoHt(_str key, typeless value)
{
   if (p_buf_user != null && p_buf_user._varformat() == VF_HASHTAB) {
      typeless (*pinfo):[] = &p_buf_user;
      typeless oldValue = null;
      if (pinfo->_indexin(key)) {
         oldValue = pinfo->:[key];
      }
      pinfo->:[key]=value;
      return oldValue;
   }

   typeless info:[];
   info:[key] = value;
   p_buf_user = info;
   return null;
}

/**
 * Is this product the Visual Studio Plugin?
 */
boolean isVisualStudioPlugin()
{
   return (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_VISUALSTUDIO_PLUGIN);
}

/**
 * @return
 * Return the maximum value among the given pair or list of
 * values.  Uses the relational operator ">" to find the
 * largest item.
 *
 * @param num1
 * @param num2
 *
 * @categories Miscellaneous_Functions
 */
typeless max(typeless num1, typeless num2, ...)
{
   typeless max_num=num1;
   int i;
   for (i=2; i<=arg() ; ++i) {
      if ( arg(i)>max_num ) {
         max_num=arg(i);
      }
   }
   return(max_num);
}

/**
 * @return
 * Return the minimum value among the given pair or list of
 * values.  Uses the relational operator ">" to find the
 * largest item.
 *
 * @param num1
 * @param num2
 *
 * @categories Miscellaneous_Functions
 */
typeless min(typeless num1, typeless num2, ...)
{
   typeless min_num=num1;
   int i;
   for (i=2; i<=arg() ; ++i) {
      if ( arg(i)<min_num ) {
         min_num=arg(i);
      }
   }
   return(min_num);
}

/**
 * @return
 * Return a sc.lang.Range object for iterating over the given
 * range of integers by the specified step amount.
 *
 * @param start_val  start value (inclusive)
 * @param end_val    end_value (inclusive)
 * @param step_by    step amount, if step is default of 1 and
 *                   the (start_value > end_value),
 *                   automatically change step to -1;
 *
 * @categories Miscellaneous_Functions
 */
typeless range(int start_val, int end_val, int step_by=1)
{
   // auto-correct the step amount
   if (step_by==1 && start_val > end_val) step_by=-1;
   // create the class instance and return it
   class sc.lang.Range rng(start_val, end_val, step_by);
   return rng;
}

/**
 * @return
 * Return the name(s) corresponding to the given value for
 * the specified enumerated type.
 *
 * @param enum_name  enumerated type name
 * @param value      value to find
 * @param flags      true if enum_name is enum_flags
 *
 * @categories Miscellaneous_Functions
 */
_str _enum_name(_str enum_name, int value, boolean flags=false)
{
   _enum_names(enum_name,auto a);
   all_flags := '';
   foreach (auto item in a) {
      index := find_index(item,ENUM_TYPE);
      if (index) {
         typeless value_of_name = name_info(index);
         if (value_of_name==value) {
            // single enumerator matches perfectly
            return item;
         }
         if (flags && isinteger(value_of_name) && ((value_of_name & value) == value_of_name)) {
            if (length(all_flags) > 0) {
               all_flags :+= '|';
            }
            all_flags :+= item;
         }
      }
   }
   // return the collection of flags
   return all_flags;
}

/**
 * @return
 * Return the value of the given enumerator in an enumerated type.
 * Note the enumerator name needs to be qualified with namespace and
 * class names as necessary.
 *
 * @param enum_name  enumerator name
 *
 * @categories Miscellaneous_Functions
 */
typeless _enum_value(_str enum_name)
{
   index := find_index(enum_name,ENUM_TYPE);
   if (index <= 0) return '';
   return name_info(index);
}

/**
 * Get all the enumerator constants for an enumerated type.
 * Note the enumerator name needs to be qualified with namespace and
 * class names as necessary.  The enumerator constants will
 * returned qualified with the same namespace and class as
 * the enumerator.
 *
 * @param enum_name  enumerator_name
 * @param a          (output) array of enumerator names
 *
 * @categories Miscellaneous_Functions
 */
void _enum_names(_str enum_name, _str (&a)[])
{
   index := find_index(enum_name,ENUM_TYPE);
   if (index <= 0) {
      a._makeempty();
      return;
   }
   split(name_info(index),',',a);
   i := lastpos('.',enum_name);
   if (i > 0) {
      prefix := substr(enum_name,1,i);
      foreach (i => auto v in a) {
         a[i] = prefix:+v;
      }
   }
}

/**
 * @return
 * Return the value of the given constant declaration.
 * Note the constant name needs to be qualified with namespace and
 * class names as necessary.
 *
 * @param const_name    constant name
 * @param status        0 if we found the const in the names
 *                      table, non-zero if it was not found
 *
 * @categories Miscellaneous_Functions
 */
typeless _const_value(_str const_name, int &status = 0)
{
   // set the status to A-OK
   status = 0;

   // find the index of this const in the names table
   index := find_index(const_name,CONST_TYPE|ENUM_TYPE);

   // we didn't find it, set the status and return a blank
   if (index <= 0) {
      status = INVALID_NAME_INDEX_RC;
      return '';
   }

   // return the value
   return name_info(index);
}

/** 
 * Rounds a value to the specified number of decimal places.
 * 
 * @param value               value to be rounded
 * @param decimalPlaces       number of decimal places
 * 
 * @return double             rounded value
 */
double round(double value, int decimalPlaces = 2)
{
   if (decimalPlaces < 0) {
      decimalPlaces = 0;
   }

   //Factor to scale for rounding test
   int factor = pow(10, decimalPlaces);

   //Make double and int version of start value times factor
   double valueXfactor = value * factor;
   int valueXfactorInt = (int)valueXfactor;

   //Check if we need to round up.
   if (valueXfactor - valueXfactorInt >= 0.5) {
      valueXfactorInt++;
   }

   //Scale back down and return
   return ((double)valueXfactorInt / (double)factor);
}

/**
 * Rounds a number down to the nearest whole number.
 * 
 * @param number     value to be rounded down
 * 
 * @return           rounded number
 */
int floor(double number)
{
   // find the decimal, please
   decPos := pos(',', number);
   if (decPos) number = (double)substr(number, 1, decPos - 1);

   return (int)number;
}

/**
 * Rounds a number up to the nearest whole number.
 * 
 * @param number     value to be rounded up
 * 
 * @return int       rounded number
 */
int ceiling(double number)
{
   intNum := (int)number;
   if (number > intNum) {
      return ++intNum;
   }

   return intNum;
}

/**
 * Pads a string with extra characters to get it up to a specified length. 
 * Can pad on either the right or the left.
 * 
 * @param text    the string to be padded
 * @param totalLength
 *                the desired total length
 * @param padChar the padding character to use
 * @param options behavior options
 * 
 * <pre>
 * L - pad on the left side of the string
 * R (default) - pad on the right side of the string
 * </pre>
 * 
 * @return the padded string 
 *  
 * @categories String_Functions
 */
_str _pad(_str text, int totalLength, _str padChar, _str options = 'R')
{
   switch (upcase(options)) {
   case 'L':
      return substr('', 1, totalLength - length(text) , padChar) :+ text;
      break;
   default:
      return substr(text, 1, totalLength, padChar);
   }
}

_str _charAt(_str text, int i)
{
   if (i <= 0 || i > length(text)) return '';
   return substr(text,i,1);
}
/**
 * Returns true if name ends with possibleSuffix
 *
 * @param name name to check
 * @param possibleSuffix suffix to check name for
 *
 * @return boolean true if <B>name</B> ends with <B>possibleSuffix</B> 
 *  
 * @categories String_Functions
 */
boolean endsWith(_str name,_str possibleSuffix,boolean strict=false,_str searchOptions='')
{
   int i=lastpos(possibleSuffix,name,'',searchOptions);
   int len=lastpos('');
   if (strict) {
      return(i>1 && i+len>length(name));
   }
   return(i>=1&& i+len>length(name));
}

/**
 * Takes a value from _time('B') and converts it to _time('F') format.
 * 
 * @param timeB 
 * 
 * @return 
 */
_str _timeBToTimeF(_str timeB)
{
   DateTime dt = DateTime.fromTimeB(timeB);

   return dt.toTimeF();
}

/** 
 * Returns true if the range [s1,e1) overlaps [s2, e2)
 */
boolean _ranges_overlap(long s1, long e1, long s2, long e2) {
   long l1 = e1 - s1;
   long l2 = e2 - s2;
   long sm = min(s1, s2);
   long se = max(e1, e2);
   long sl = se - sm;

   return sl < (l1 + l2);
}
