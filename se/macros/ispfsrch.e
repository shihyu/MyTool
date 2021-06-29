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
#import "docsearch.e"
#import "ispflc.e"
#import "main.e"
#import "math.e"
#import "mfsearch.e"
#import "search.e"
#import "searchcb.e"
#import "seek.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#endregion

static int convertSearchString(_str &searchString,_str &options,_str string,_str stringType,bool doReplaceString=false)
{
   //say("convertSearchString("searchString","options","string","stringType")");
   pictureString := "";
   hexstring := "";

   switch (stringType) {
   case 'T':
      if (!doReplaceString) options :+= 'I';
      searchString=string;
      return(0);
   case 'C':
      if (!doReplaceString) options :+= 'E';
      searchString=string;
      return(0);
   case 'P':
      if (doReplaceString) {
         clear_message();
         _message_box('Replace string can not be a pattern');
         return(1);
      }
      options :+= 'RE';
      // DJB 07-14-2011 -- The quote wass already removed
      pictureString=string;//substr(string,1,length(string)-1);
      searchString=ispf_convert_re(pictureString);
      return(0);
   case 'X':
      if (!doReplaceString) {
         // !! Hex bytes above 127 won't work if in _UTF8() mode.
         // The only way to fix this is to do a regular expression
         // search.
         options :+= 'E';
      }
      hexstring=string;
      if ((length(hexstring)&1) || !length(hexstring)) {
         clear_message();
         _message_box('Invalid hexadecimal character string');
         return(1);
      }
      string='';
      for (;;) {
         typeless more=hex2dec('0x'substr(hexstring,1,2));
         if (more=='') {
            clear_message();
            _message_box('Invalid hexadecimal character string');
            return(1);
         }
         string :+= _chr(more);
         hexstring=substr(hexstring,3);
         if (hexstring=='') {
            break;
         }
      }
      searchString=string;
      return(0);
   case '*':
      if (doReplaceString) {
         searchString=old_replace_string;
         return(0);
      }
      searchString=old_search_string;
      int flags=old_search_flags&(RE_SEARCH|IGNORECASE_SEARCH);
      if (!doReplaceString) options :+= make_search_options(flags);
      return(0);
   }
   return(1);
}

   struct STACK {
      bool isString; // if isString==false, this is integer or .label
      _str string;
      _str stringType;
   };
static int ispf_parse_find(
   _str &searchString,_str &replaceString,
   VSSEARCH_BOUNDS &vssearch_bounds,
   _str cmdline,
   bool doChangeCommand,
   bool doExclude=false)
{
   searchString='';
   replaceString='';
   if (doExclude) {
      vssearch_bounds.searchOptions='XV,';
   } else {
      vssearch_bounds.searchOptions='HXV,';
   }
   if (_default_option('s') & VSSEARCHFLAG_WRAP) {
      vssearch_bounds.searchOptions=vssearch_bounds.searchOptions:+'P';
   }

   vssearch_bounds.startLabel='';
   vssearch_bounds.endLabel='';
   vssearch_bounds.startCol=-1;
   vssearch_bounds.endCol=-1;
   vssearch_bounds.startCmd='';

   STACK stack[];
   itop := 0;
   startCmd := "";
   wordCmd := "";
   i := 0;
   ch := "";
   word := "";
   orig_word := "";

   for (;;) {
      if (cmdline=='') break;
      cmdline=strip(cmdline);
      ch=substr(cmdline,1,1);
      string := "";
      stringType := 'T';  // Type of string 'T', 'C', 'P', 'X', or '*'
      if (ch=='"' || ch=="'") {
         stringType='T';
         i=pos(ch,cmdline,2);
         if (!i) {
            clear_message();
            _message_box('Quoted string not terminated');
            return(1);
         }
         string=substr(cmdline,2,i-2);
         cmdline=substr(cmdline,i+1);
         if (substr(cmdline,1,1):!=' ') {
            stringType=upcase(substr(cmdline,1,1));
            if (!pos(stringType,'TCPX')) {
               clear_message();
               _message_box("Invalid string type");
               return(1);
            }
            cmdline=substr(cmdline,2);
         }
      } else if (pos(ch,'TCPX',1,'i') &&
                 (substr(cmdline,2,1)=='"' || substr(cmdline,2,1)=="'")) {
         stringType=upcase(ch);
         ch=substr(cmdline,2,1);
         i=pos(ch,cmdline,3);
         if (!i) {
            clear_message();
            _message_box('Quoted string not terminated');
            return(1);
         }
         string=substr(cmdline,3,i-3);
         cmdline=substr(cmdline,i+1);
      } else {
         parse cmdline with word cmdline;
         orig_word=word;
         word=upcase(word);
         switch (word) {
         case '*':
            string='*';stringType='*';
            break;
         case 'QUIET':
            // If the range start command is already set
            if (cmdline=='' && !stack._length()) {
               string=orig_word;
            } else {
               vssearch_bounds.searchOptions=vssearch_bounds.searchOptions:+'@';
            }
            break;
         /*case 'SELECTION':
            SPF edit actual uses selection
            as the search string. Let user use clipboard.
            Searching within the selection might be valuable
            though.  User can use find dialog to search within
            a selection.

            // If the range start command is already set
            if (cmdline=='' && !stack._length()) {
               string=orig_word;
            } else {
               vssearch_bounds.searchOptions=vssearch_bounds.searchOptions:+'m';
            }
            break;
         */
         case 'FIRST':
         case 'LAST':
         case 'PREV':
         case 'NEXT':
         case 'ALL':
            // If the range start command is already set
            if (cmdline=='' && !stack._length() && !doExclude) {
               string=orig_word;
            } else {
               if (startCmd=='LAST' && word=='ALL') {
                  startCmd='ALLLAST';
               } else if (startCmd=='ALL' && word=='LAST') {
                  startCmd='ALLLAST';
               }
               startCmd=word;
            }
            break;
         case 'CHARS':
         case 'WORD':
         case 'PREFIX':
         case 'SUFFIX':
            if (cmdline=='' && !stack._length()) {
               string=orig_word;
            } else {
               wordCmd=word;
            }
            break;
         case 'X':
         case 'EX':
            // If the range start command is already set
            if (cmdline=='' && !stack._length()) {
               string=orig_word;
            } else {
               vssearch_bounds.searchOptions=vssearch_bounds.searchOptions:+'CH';
            }
            break;
         case 'NX':
            // If the range start command is already set
            if (cmdline=='' && !stack._length()) {
               string=orig_word;
            } else {
               vssearch_bounds.searchOptions=vssearch_bounds.searchOptions:+'XH';
            }
            break;
         default:
            if (substr(word,1,1)=='.') {
               if (_LCFindLabel(word,false)>=0) {
                  if (vssearch_bounds.startLabel=='') {
                     vssearch_bounds.startLabel=word;
                  } else if(vssearch_bounds.endLabel=='') {
                     vssearch_bounds.endLabel=word;
                  } else {
                     clear_message();
                     _message_box("Too many labels specified");
                     return(1);
                  }
               } else {
                  itop=stack._length();
                  stack[itop].isString=false;
                  stack[itop].string=word;
                  stack[itop].stringType='T';
                  break;
               }
            } else if (isinteger(word)) {
               itop=stack._length();
               stack[itop].isString=false;
               stack[itop].string=word;
               stack[itop].stringType='T';
            } else {
               string=orig_word;
            }

         }
      }
      if (string:!='') {
         itop=stack._length();
         stack[itop].isString=true;
         stack[itop].string=string;
         stack[itop].stringType=stringType;
      }
   }
   doExcludeAll := false;
   // Set the search string
   for (i=0;;++i) {
      if (i>=stack._length()) {
         // Use number for string
         i=0;
         if (i>=stack._length()) {
            if (doExclude) {
               doExcludeAll=true;
            } else {
               clear_message();
               _message_box('Put string in quotes');
               return(1);
            }
         }
         break;
      }
      if (stack[i].isString) {
         break;
      }
   }
   if (doExcludeAll) {
      vssearch_bounds.orig_searchString='';
      searchString='';
   } else {
      if(convertSearchString(searchString,
                             vssearch_bounds.searchOptions,
                             stack[i].string,
                             stack[i].stringType)) {
         return(1);
      }
      if (stack[i].stringType=='*') {
         //vssearch_bounds.orig_searchString=stack[i].string;
         if (old_search_bounds!=null && old_search_bounds.orig_searchString!=null) {
            vssearch_bounds.orig_searchString=old_search_bounds.orig_searchString;
         } else {
            // This can happen when editor first comes up
            vssearch_bounds.orig_searchString=stack[i].string;
         }
      } else {
         vssearch_bounds.orig_searchString=stack[i].string;
      }
      stack._deleteel(i);
   }
   if (doChangeCommand) {
      // Set the replace string
      for (;;++i) {
         if (i>=stack._length()) {
            // Use number for string
            i=0;
            if (i>=stack._length()) {
               clear_message();
               _message_box('Put replace string in quotes');
               return(1);
            }
            break;
         }
         if (stack[i].isString) {
            break;
         }
      }
      typeless junk="";
      if(convertSearchString(replaceString,
                             junk,
                             stack[i].string,
                             stack[i].stringType,true)) {
         return(1);
      }
      stack._deleteel(i);
   }
   for (i=0;i<stack._length();++i) {
      if (stack[i].isString) {
         clear_message();
         _message_box("Too many string arguments specified");
         return(1);
      }
      if (substr(stack[i].string,1,1)=='.') {
         if (vssearch_bounds.startLabel=='') {
            vssearch_bounds.startLabel=stack[i].string;
         } else if(vssearch_bounds.endLabel=='') {
            vssearch_bounds.endLabel=stack[i].string;
         } else {
            clear_message();
            _message_box("Too many label arguments specified");
            return(1);
         }
      } else {
         if (vssearch_bounds.startCol<0) {
            vssearch_bounds.startCol=(int)stack[i].string;
         } else if (vssearch_bounds.endCol<0) {
            vssearch_bounds.endCol=(int)stack[i].string;
         } else {
            clear_message();
            _message_box("Too many column arguments specified");
            return(1);
         }
      }
   }
   if (doExcludeAll && (startCmd!='ALL' && vssearch_bounds.startLabel=='') ) {
      clear_message();
      _message_box('Put string in quotes');
      return(1);
   }
   vssearch_bounds.startCmd=startCmd;
   if (wordCmd!='') {
      switch (wordCmd) {
      case 'WORD':
         vssearch_bounds.searchOptions=vssearch_bounds.searchOptions:+'w';
         break;
      case 'PREFIX':
         vssearch_bounds.searchOptions=vssearch_bounds.searchOptions:+'w:ps';
         break;
      case 'SUFFIX':
         vssearch_bounds.searchOptions=vssearch_bounds.searchOptions:+'w:ss';
         break;
      case 'CHARS':
         // default
         break;
      }
   }
   if (vssearch_bounds.startCol>0) {
      if (vssearch_bounds.endCol<=0) {
         if (pos('r',vssearch_bounds.searchOptions,1,'I') <= 0) {
            vssearch_bounds.endCol=vssearch_bounds.startCol+length(searchString)-1;
         }
      } else if (vssearch_bounds.startCol>vssearch_bounds.endCol){
         typeless temp=vssearch_bounds.endCol;
         vssearch_bounds.endCol=vssearch_bounds.startCol;
         vssearch_bounds.startCol=temp;
      }
   }
   if (vssearch_bounds.startLabel!='' &&
       vssearch_bounds.endLabel=='') {
      vssearch_bounds.endLabel=vssearch_bounds.startLabel;
   }
   if (vssearch_bounds.startCol>0 &&
       vssearch_bounds.endCol<=0=='') {
      vssearch_bounds.endCol=vssearch_bounds.startCol;
   }
#if 0
   say('');
   say('');
   say('searchString='searchString);
   say('replaceString='replaceString);
   say('vssearch_bounds.searchOptions='vssearch_bounds.searchOptions);
   say('startLabel='vssearch_bounds.startLabel);
   say('endLabel='vssearch_bounds.endLabel);
   say('startCol='vssearch_bounds.startCol);
   say('endCol='vssearch_bounds.endCol);
   say('startCmd='vssearch_bounds.startCmd);
#endif

   return(0);
}
static void _HideMore(int Noflines,long startpoint)
{
   typeless p;
   _save_pos2(p);
   _nrseek(startpoint);
   int count=Noflines;
   while (count-- > 0) {
      _lineflags(HIDDEN_LF,HIDDEN_LF);
      down();
   }
   NoflinesAfter := ispf_is_excluded_line();
   if (NoflinesAfter) {
      int old_ModifyFlags=p_ModifyFlags;
      _delete_line();
      p_ModifyFlags=old_ModifyFlags;
   }
   _nrseek(startpoint);
   NoflinesBefore := 0;
   for (;;) {
      int status=up();
      if (_nrseek()<0) {
         break;
      }
      if (!(_lineflags() & HIDDEN_LF)) {
         break;
      }
      ++NoflinesBefore;
   }

   if (ispf_is_excluded_line()) {
      ispf_insert_exclude(NoflinesBefore+Noflines+NoflinesAfter,true);
   } else {
      ispf_insert_exclude(NoflinesBefore+Noflines+NoflinesAfter);
   }
   _restore_pos2(p);
}
static int doExclude(_str searchString,VSSEARCH_BOUNDS vssearch_bounds)
{
   typeless new_search_options=vssearch_bounds.searchOptions;

   doAll := false;
   typeless markid="";
   typeless orig_markid="";
   if(_InitSearchBounds(vssearch_bounds,
                        markid,
                        orig_markid,
                        doAll
                        )) {
      return(1);
   }
   if (markid!='') {
      new_search_options :+= 'm';
   }
   searchBackward := false;
   if (vssearch_bounds.startCmd=='PREV' ||
       vssearch_bounds.startCmd=='ALLLAST' ||
       vssearch_bounds.startCmd=='LAST'
       ) {
      searchBackward=true;
      new_search_options :+= '-';
   }
   typeless junk="";
   typeless fail_pos="";
   _initSearchBounds2(vssearch_bounds,doAll,markid,fail_pos);

   old_search_bounds=vssearch_bounds;
   old_search_bounds.result_doAll=doAll;
   if (markid!='' && _select_type(markid)!='LINE') {
      _get_selinfo(old_search_bounds.result_startCol,
                   old_search_bounds.result_endCol,
                   junk,
                   markid);
   } else {
      old_search_bounds.result_startCol= -1;
      old_search_bounds.result_endCol= -1;
   }
   old_search_string=searchString;


   //_macro('m',recording_macro);
   //_macro_delete_line();
   //_macro_call('find',old_search_string,new_search_options);
   mou_hour_glass(true);
   _mffindNoMore(1);
   _mfrefNoMore(1);
   typeless status=0;
   //say('new_search_options='new_search_options);
   //say('old_search_string='old_search_string);
   //messageNwait('got here');
   if (old_search_string=='') {
      if (markid=='') {
         orig_markid=_duplicate_selection('');
         markid='';
         markid=_alloc_selection();
         save_pos(auto p);
         top();_select_line(markid);
         bottom();_select_line(markid);
         _show_selection(markid);
         restore_pos(p);
      }
      _begin_select(markid);
      count := 0;
      for (;;) {
         int flags=_lineflags();
         if (flags & NOSAVE_LF) {
            status=_delete_line();
            if (status) {
               break;
            }
         } else {
            _lineflags(HIDDEN_LF,HIDDEN_LF);
            ++count;
            if(down()) break;
         }
         if (_end_select_compare(markid)>0) {
            for (;;) {
               if (!(flags &HIDDEN_LF)) {
                  break;
               }
               ++count;
               if(down()) break;
               flags=_lineflags();
            }
            break;
         }
      }
      if (count) {
         _begin_select(markid);
         up();
         ispf_insert_exclude(count);
      }
      status=0;

   } else {
      status=search(old_search_string,'xv,@'new_search_options);
      if (!status) {
         //_MaybeUnhideLine(selection_markid);
         if (doAll) {
            typeless first_pos;
            save_pos(first_pos);
            for (;;) {
               typeless startpoint=point();
               typeless lastpoint=point();
               Noflines := 1;
               for (;;) {
                  status=repeat_search();
                  if (status) break;
                  //messageNwait('p_line='p_line' s='status);
                  // Check if this is the line above or below that last hit
                  if (startpoint!=point()) {
                     if (searchBackward) {
                        down();
                     } else {
                        up();
                     }
                     done := lastpoint!=point();
                     if (searchBackward) {
                        up();
                     } else {
                        down();
                     }
                     if (done) {
                        break;
                     }
                     ++Noflines;
                     lastpoint=point();
                  }
               }
               //messageNwait('Noflines='Noflines' 'startpoint);
               if (searchBackward) {
                  _HideMore(Noflines,lastpoint);
               } else {
                  _HideMore(Noflines,startpoint);
               }
               //messageNwait('h2');
               if (status) {
                  break;
               }
            }

            restore_pos(first_pos);
            status=0;
         } else {
            _HideMore(1,(long)point());
         }
      }
   }
   //search_flags_str=old_search_flags;//Dan Added here
   if (old_search_string:=='') status=STRING_NOT_FOUND_RC;
   if (markid!='') {
      _show_selection(orig_markid);
      _free_selection(markid);
   }
   typeless new_flags;
   save_search(junk,new_flags,junk);
   mou_hour_glass(false);
   old_search_string=old_search_string;
   save_search(junk,old_search_flags,old_word_re,old_search_reserved,old_search_flags2);
   save_last_search(old_search_string, new_search_options);
   if (!status) p_LCHasCursor=false;
   if (fail_pos!=null && status) {
      restore_pos(fail_pos);
   }
   return(status);
}
static int doFind(_str searchString,VSSEARCH_BOUNDS vssearch_bounds)
{
   int status=find(searchString,vssearch_bounds.searchOptions,vssearch_bounds);
   if (status>0) {
      return(status);
   }
   msg := "";
   if (!status) {
      if (old_search_bounds!=null && old_search_bounds.result_doAll) {
         msg=nls("Found %s1 occurrences of '%s2'",_Nofchanges,old_search_bounds.orig_searchString);
         if (old_search_bounds.startLabel!='') {
            msg :+= "\nRange: "old_search_bounds.startLabel:+' 'old_search_bounds.endLabel;
         } else {
            msg :+= "\nRange: ALL";
         }
         if (old_search_bounds.result_startCol>0) {
            msg :+= "\nColumns: "old_search_bounds.result_startCol' 'old_search_bounds.result_endCol;
         }
      }
      p_LCHasCursor=false;
   } else {
      msg=nls("'%s1' not found",old_search_bounds.orig_searchString);
      if (old_search_bounds!=null && old_search_bounds.result_doAll) {
         if (old_search_bounds.startLabel!='') {
            msg :+= "\nRange: "old_search_bounds.startLabel:+' 'old_search_bounds.endLabel;
         } else {
            msg :+= "\nRange: ALL";
         }
      }
      if (old_search_bounds.result_startCol>0) {
         msg :+= "\nColumns: "old_search_bounds.result_startCol' 'old_search_bounds.result_endCol;
      }
   }
   clear_message();
   if (msg!='') {
      refresh();
      clear_message();
      _message_box(msg,'',MB_OK|MB_ICONINFORMATION);
   }
   return(status);
}
/**
 * Repeat the last find operation requested by the last find command issued.
 * 
 * 
 * <p>Syntax:<pre>
 *    RFIND
 * </pre>
 * 
 * @return Returns 0 if the search string is found.  Common return codes 
 * are STRING_NOT_FOUND_RC and  INVALID_OPTION_RC.  On error, a message 
 * is displayed.
 * 
 * @see ispf_find
 * 
 * @categories ISPF_Primary_Commands
 */
_command int ispf_rfind() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   /*if (old_search_bounds!=null && old_search_bounds.result_doAll) {
      return(doFind(old_search_string,old_search_bounds));
   } */
   return(find_next());
}
/**
 * This command finds occurrences of the given search string or ISPF regular expression in
 * the current buffer.  If an occurrence is found in an excluded line, the line will be
 * unexcluded.  Find takes the following common searching arguments (also used in the
 * change, exclude, and locate commands):
 * 
 * <p>Syntax:<pre>
 *    <i>string</i> [ <i>range</i> ] [NEXT | ALL | FIRST | LAST | PREV | CHARS | SUFFIX | WORD | X | NX | QUIET] [<i>col1</i> [<i>col2</i> ]]
 * </pre>
 * 
 * <dl compact style="margin-left:20pt">
 * <dt><i>string</i><dd style="margin-left:60pt">The string or regular expression to search for.
 * <dt><i>line</i><dd style="margin-left:60pt">range  Two numbers or labels, specifying the starting and ending lines to search within, inclusive.
 * <dt>NEXT<dd style="margin-left:60pt">Find the next occurrence starting from the cursor.
 * <dt>ALL<dd style="margin-left:60pt">Find all matches in the specified range.
 * <dt>FIRST<dd style="margin-left:60pt">Find only the first occurrence in the specified range.
 * <dt>LAST<dd style="margin-left:60pt">Find only the last occurrence in the specified range.
 * <dt>PREV<dd style="margin-left:60pt">Find the previous occurrence starting from the cursor.
 * <dt>CHARS<dd style="margin-left:60pt">(default) Locate match anywhere.
 * <dt>PREFIX<dd style="margin-left:60pt">Only find matches at the beginning of a word.
 * <dt>SUFFIX<dd style="margin-left:60pt">Only find matches at the end of a word.
 * <dt>WORD<dd style="margin-left:60pt">Only find matches for the entire word.
 * <dt>X<dd style="margin-left:60pt">Look for matches only in excluded lines.
 * <dt>NX<dd style="margin-left:60pt">Do not report matches in excluded lines.
 * <dt><i>col1</i><dd style="margin-left:60pt"> Starting column boundary to search within.
 * <dt><i>col2</i><dd style="margin-left:60pt"> Ending column boundary to search within.
 * <dt>QUIET<dd style="margin-left:60pt"> Do not display messages.
 * </dl>
 * 
 * The ISPF find command supports ISPF regular expressions (known as picture strings).  The 
 * following table shows the specific picture string characters supported, as well as how 
 * they may be expressed as <a href="help:SlickEdit regular expressions">SlickEdit Regular Expressions</a>
 * 
 * <blockquote><pre>
 * =  <b>?</b>          any character.
 * ^  <b>[^ \t]</b>     non-blank character.
 * .  <b>[0-9]</b>      non-ASCII character (0x20..0x7E)
 * #  <b>[0-9]</b>      any single decimal digit.
 * -  <b>[^0-9]</b>     non-numeric character.
 * @  <b>[a-zA-Z]</b>   alphabetic character (case-insensitive).
 * &lt;  <b>[a-z]</b>      lowercase alphabetic character.
 * &gt;  <b>[A-Z]</b>      uppercase alphabetic character.
 * $  <b>[~ \ta-zA-Z0-9]</b>  punctuation (not alphabetic, digit, or blank).
 * </pre></blockquote>
 * 
 * @return Returns 0 if the search string specified is found.  Common return codes are 
 *         STRING_NOT_FOUND_RC, INVALID_OPTION_RC and INVALID_REGULAR_EXPRESSION_RC.  
 *         On error, a message is displayed.
 * 
 * @see ispf_change
 * @see ispf_locate
 * @see ispf_exclude
 * @see ispf_hilite
 * @see ispf_flip
 * 
 * @categories ISPF_Primary_Commands
 */
_command int ispf_find,ispf_f(_str arglist="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (arglist=="") {
      return(gui_find());
   }
   VSSEARCH_BOUNDS vssearch_bounds;
   searchString := "";
   replaceString := "";
   if(ispf_parse_find(
         searchString,replaceString,
         vssearch_bounds,arglist,false) ) {
      return(1);
   }
   return(doFind(searchString,vssearch_bounds));
}

/**
 * This command hides (excludes) lines that match the given search string or ISPF 
 * regular expression. It accepts the same search options as find, locate, and change.  
 * See {@link ispf_find} for more details about the search arguments.
 * 
 * <p>Syntax:<pre>
 *    EXCLUDE <i>string</i> [ <i>range</i> ] [NEXT | ALL | FIRST | LAST | PREV | CHARS | SUFFIX | WORD | X | NX] [<i>col1</i> [<i>col2</i> ]]
 * </pre>
 * 
 * @return  Returns 0 if the search string specified is found.  Common return codes are 
 *   STRING_NOT_FOUND_RC, INVALID_OPTION_RC and INVALID_REGULAR_EXPRESSION_RC.  On error, 
 *   a message is displayed.
 * 
 * @see ispf_find
 * @see ispf_flip
 * @see help:ISPF Line Command Exclude
 * 
 * @categories ISPF_Primary_Commands
 *        
 */
_command int ispf_exclude,ispf_ex,ispf_x(_str arglist="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (_isdiffed(p_buf_id)) {
      return(1);
   }
   if (arglist=="") {
      return(1);
   }
   VSSEARCH_BOUNDS vssearch_bounds;
   searchString := "";
   replaceString := "";
   if(ispf_parse_find(
         searchString,replaceString,
         vssearch_bounds,arglist,false,true) ) {
      return(1);
   }
   int status=doExclude(searchString,vssearch_bounds);

   msg := "";
   if (!status) {
      p_LCHasCursor=false;
   } else {
      msg=nls("'%s1' not found",old_search_bounds.orig_searchString);
      if (old_search_bounds!=null && old_search_bounds.result_doAll) {
         if (old_search_bounds.startLabel!='') {
            msg :+= "\nRange: "old_search_bounds.startLabel:+' 'old_search_bounds.endLabel;
         } else {
            msg :+= "\nRange: ALL";
         }
      }
      if (old_search_bounds.result_startCol>0) {
         msg :+= "\nColumns: "old_search_bounds.result_startCol' 'old_search_bounds.result_endCol;
      }
   }
   clear_message();
   if (msg!='') {
      refresh();
      clear_message();
      _message_box(msg,'',MB_OK|MB_ICONINFORMATION);
   }
   return(status);
}

/**
 * Repeats the change requested by the most recent change command.
 * 
 * 
 * <p>Syntax:<pre>
 *    RCHANGE
 * </pre>
 * 
 * @return Returns 0 if successful.
 * 
 * @see ispf_change
 * 
 * @categories ISPF_Primary_Commands
 */
_command int ispf_rchange(_str cmdline='',bool supportDoAll=false) name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (old_search_bounds==null) {
      // Nothing to repeat
      return(0);
   }

   typeless markid="";
   typeless orig_markid="";
   doAll := false;
   typeless new_search_options=old_search_bounds.searchOptions;
   if(_InitSearchBounds(old_search_bounds,
                        markid,
                        orig_markid,
                        doAll
                        )) {
      return(1);
   }
   if (markid!='') {
      new_search_options :+= 'm';
   }
   if (old_search_bounds.startCmd=='PREV' ||
       old_search_bounds.startCmd=='ALLLAST' ||
       old_search_bounds.startCmd=='LAST'
       ) {
      new_search_options :+= '-';
   }
   save_pos(auto p);
   typeless fail_pos="";
   _initSearchBounds2(old_search_bounds,doAll,markid,fail_pos);
   if(!supportDoAll) restore_pos(p);

   typeless flags=0;
   typeless junk="";
   old_search_bounds.result_doAll=doAll;
   if (!supportDoAll) doAll=false;
   if (markid!='' && _select_type(markid)!='LINE') {
      _get_selinfo(old_search_bounds.result_startCol,
                   old_search_bounds.result_endCol,
                   junk,
                   markid);
   } else {
      old_search_bounds.result_startCol= -1;
      old_search_bounds.result_endCol= -1;
   }

   mou_hour_glass(true);
   _mffindNoMore(1);
   _mfrefNoMore(1);
   first_pos := null;
   Nofchanges := 0;
   _Nofchanges=0;
   //old_search_string=searchString;
   //old_replace_string=replaceString;
   int old_TruncateLength=p_TruncateLength;
   int bnds_start_col,bnds_end_col;
   _LCGetBounds(bnds_start_col,bnds_end_col);
   if (bnds_start_col>0) {
      p_TruncateLength=old_search_bounds.result_endCol;
   }
   _SearchInitSkipped(0);
   status := search(old_search_string,'@'new_search_options);
   if (!status) {
      flags=_LCQFlags();
      _MaybeUnhideLine();
      search_replace(old_replace_string);
      ++_Nofchanges;
      if (!_SearchQNofSkipped()) {
         p_col+=_rawLength(old_replace_string);
      }
      _save_pos2(first_pos);
      if (doAll) {
         if (p_Nofhidden) {
            for (;;) {
               status=repeat_search();
               if (status) break;
               _MaybeUnhideLine();
               search_replace(old_replace_string);
               ++_Nofchanges;
            }
         } else {
            if (_SearchQNofSkipped()) {
               status=repeat_search();
               if (!status) {
                  search(old_search_string,'@'new_search_options,old_replace_string,Nofchanges);
               }
            } else {
               search(old_search_string,'@'new_search_options,old_replace_string,Nofchanges);
            }
            _Nofchanges+=Nofchanges;
         }
      } else {
         _LCSetFlags(flags,VSLCFLAG_ERROR|VSLCFLAG_CHANGE);
      }
      status=0;
   }
   _Nofchanges-= _SearchQNofSkipped();
   if (bnds_start_col>0) {
      p_TruncateLength=old_TruncateLength;
   }
   if (markid!='') {
      _show_selection(orig_markid);
      _free_selection(markid);
   }

   mou_hour_glass(false);
   save_search(junk,old_search_flags,old_word_re,old_search_reserved,old_search_flags2);
   if (first_pos!=null) {
      _restore_pos2(first_pos);
   } else {
      _free_selection(first_pos);
   }
   if (!status) p_LCHasCursor=false;
   if (fail_pos!=null && status) {
      restore_pos(fail_pos);
   }

   msg := "";
   if (!status) {
      if (old_search_bounds!=null && doAll) {
         msg=nls("Changed %s1 occurrences of '%s2' to '%s3'",_Nofchanges,old_search_bounds.orig_searchString,old_replace_string);
         if (old_search_bounds.startLabel!='') {
            msg :+= "\nRange: "old_search_bounds.startLabel:+' 'old_search_bounds.endLabel;
         } else {
            msg :+= "\nRange: ALL";
         }
         if (old_search_bounds.result_startCol>0) {
            msg :+= "\nColumns: "old_search_bounds.result_startCol' 'old_search_bounds.result_endCol;
         }
      }
      p_LCHasCursor=false;
   } else {
      msg=nls("'%s1' not found",old_search_bounds.orig_searchString);
      if (old_search_bounds!=null && doAll) {
         if (old_search_bounds.startLabel!='') {
            msg :+= "\nRange: "old_search_bounds.startLabel:+' 'old_search_bounds.endLabel;
         } else {
            msg :+= "\nRange: ALL";
         }
      }
      if (old_search_bounds.result_startCol>0) {
         msg :+= "\nColumns: "old_search_bounds.result_startCol' 'old_search_bounds.result_endCol;
      }
   }
   if (_SearchQNofSkipped()) {
      if (msg!="") {
         msg :+= "\n";
      }
      msg :+= "Errors: "_SearchQNofSkipped();
   }
   clear_message();
   if (msg!='') {
      refresh();
      clear_message();
      _message_box(msg,'',MB_OK|MB_ICONINFORMATION);
   }
   return(status);
}
/**
 * The change command is used to replace one string with 
 * another.  It accepts the same search options as find, 
 * locate, and exclude.  See {@link ispf_find} for more details 
 * about the search arguments.
 * <p><pre>
 *    CHANGE <i>string1</i> <i>string2</i>
 *           [FIRST| LAST | NEXT | PREV ]
 *           [WORD| PREFIX | SUFFIX ]
 *           [X| EX| NX ]
 *           [ ALL ]
 *           [<i>StartCol</i>-<i>EndCol</i>]
 *           [<i>StartLabel</i>-<i>EndLabel</i>]
 * </pre>
 * 
 * @return Returns 0 if successful.
 * @see ispf_find
 * @see ispf_exclude
 * @see ispf_locate
 * 
 * @categories ISPF_Primary_Commands
 */
_command int ispf_change,ispf_chg,ispf_c(_str arglist="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (arglist=="") {
      return(gui_replace());
   }
   VSSEARCH_BOUNDS vssearch_bounds;
   searchString := "";
   replaceString := "";
   if(ispf_parse_find(
         searchString,replaceString,
         vssearch_bounds,arglist,true) ) {
      return(1);
   }
   old_search_string=searchString;
   old_replace_string=replaceString;
   old_search_bounds=vssearch_bounds;
   return(ispf_rchange('',true));
}

static int find_next_excluded()
{
   save_pos(auto p);
   _end_line();
   status := search('not displayed','@icv');
   if (status) {
      restore_pos(p);
      return(status);
   }
   return(0);
}
static int find_prev_excluded()
{
   save_pos(auto p);
   up();_end_line();
   status := search('not displayed','-@icv');
   if (status) {
      restore_pos(p);
      return(status);
   }
   return(0);
}
/**
 * The locate command is used to find lines with specific attributes in the prefix
 * line.  It can be used to find a line with a specific label, line number,
 * command, changed line, error line, or no-save lines.
 * 
 * <p>Syntax:<pre>
 *    LOCATE <i>line_number</i>
 *    LOCATE <i>label</i>
 *    LOCATE [NEXT | PREV | FIRST | LAST ]
 *           [LABEL COMMAND CMD ERROR CHANGE CHG C SPECIAL S EXCLUDED X]
 *           [range]
 * </pre>
 * 
 * Arguments:
 * <dl compact style="margin-left:20pt">
 * <dt><i>line_number</i><dd style="margin-left:80pt">Line number to go directly to.
 * <dt><i>label</i><dd style="margin-left:80pt">ISPF label to go directly to.
 * <dt><i>range</i><dd style="margin-left:80pt">Two numbers or labels, specifying the starting and ending lines to search within, inclusive.
 * <dt>NEXT<dd style="margin-left:80pt">Find the next occurrence starting from the cursor.
 * <dt>ALL<dd style="margin-left:80pt">Find all matches in the specified range.
 * <dt>FIRST<dd style="margin-left:80pt">Find only the first occurrence in the specified range.
 * <dt>LAST<dd style="margin-left:80pt">Find only the last occurrence in the specified range.
 * <dt>PREV<dd style="margin-left:80pt">Find the previous occurrence starting from the cursor.
 * <dt>CHANGE<dd style="margin-left:80pt">Search for lines with a change flag (==CHG>).
 * <dt>COMMAND<dd style="margin-left:80pt">Search for lines containing an edit line command.
 * <dt>ERROR<dd style="margin-left:80pt">Search for lines with an error flag (==ERR>).
 * <dt>EXCLUDED<dd style="margin-left:80pt">Search only for excluded lines.
 * <dt>LABEL<dd style="margin-left:80pt">Search for lines with a label.
 * <dt>SPECIAL<dd style="margin-left:80pt">Search for lines with special non-data lines, (e.g. =COLS>)
 * <dt>QUIET<dd style="margin-left:80pt">Do not display messages.
 * </dl>
 * 
 * @see ispf_do_lc
 * @see ispf_reset
 * @see help:ISPF Line Commands
 * 
 * @categories ISPF_Primary_Commands
 * 
 */
_command void ispf_locate,ispf_loc,ispf_l(_str cmdline="") name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (cmdline=='') {
      return;
   }

   if (isinteger(cmdline)) {
      goto_line(cmdline);
      line_to_top();
      return;
   }
   cmdline=strip(upcase(cmdline));
   // If we are searching for a label
   if (substr(cmdline,1,1)=='.') {
      int linenum=_LCFindLabel(cmdline,true,true);
      if (linenum>=0) {
         p_line=linenum;
         line_to_top();
         return;
      }
      return;
   }
   startcmd := "NEXT";
   searchfor := "";
   word := "";
   for (;;) {
      parse cmdline with word cmdline;
      if (word=='') {
         break;
      }
      word=upcase(word);
      switch (word) {
      case 'NEXT':
      case 'PREV':
      case 'FIRST':
      case 'LAST':
         startcmd=word;
         break;
      default:
         if (searchfor!='') {
            clear_message();
            _message_box('Bad command argument');
            return;
         }
         switch (word) {
         case 'L':
         case 'LAB':
         case 'LABEL':
            searchfor='LABEL';
            break;
         case 'CMD':
         case 'COMMAND':
            searchfor='COMMAND';
            break;
         case 'C':
         case 'CHG':
         case 'CHANGE':
            searchfor='CHANGE';
            break;
         case 'S':
         case 'SP':
         case 'SPEC':
         case 'SPECIAL':
            searchfor='SPECIAL';
            break;
         case 'X':
         case 'EX':
         case 'EXCLUDED':
            searchfor='EXCLUDED';
            break;
         case 'E':
         case 'ERR':
         case 'ERROR':
            searchfor='ERROR';
            break;
         default:
            clear_message();
            _message_box('Bad command argument');
            return;
         }
      }
   }
   if (searchfor=='' ) searchfor='SPECIAL';

   typeless p="";
   typeless status=0;
   if (searchfor=='EXCLUDED') {
      if (startcmd=='NEXT') {
         status=find_next_excluded();
         if (status) {
            clear_message();
            _message_box('No more excluded lines');
         }
         return;
      }
      if (startcmd=='PREV') {
         status=find_prev_excluded();
         if (status) {
            clear_message();
            _message_box('No more excluded lines');
         }
         return;
      }
      save_pos(p);
      if (startcmd=='FIRST') {
         top();
         status=find_next_excluded();
      } else {
         bottom();
         status=find_prev_excluded();
      }
      if (status) {
         restore_pos(p);
         clear_message();
         _message_box('Excluded lines not found');
      }
      return;
   }
   i := 0;
   ln := 0;
   direction := 1;
   switch (startcmd) {
   case 'NEXT':
      for (i=0;i<_LCQNofLineCommands();++i) {
         ln=_LCQLineNumberAtIndex(i);
         if (ln==p_line) {
            ++i;
            break;
         } else if (ln>p_line) {
            break;
         }
      }
      break;
   case 'PREV':
      direction=-1;
      for (i=_LCQNofLineCommands()-1;i>=0;--i) {
         ln=_LCQLineNumberAtIndex(i);
         if (ln==p_line) {
            --i;
            break;
         } else if (ln<p_line) {
            break;
         }
      }
      break;
   case 'FIRST':
      i=0;
      break;
   case 'LAST':
      i=_LCQNofLineCommands()-1;
      direction=-1;
      break;
   }
   typeless flags=0;
   for (;i>=0 && i<_LCQNofLineCommands();i+=direction) {
      data := upcase(strip(_LCQDataAtIndex(i)));
      if (searchfor=='LABEL') {
         if (substr(data,1,1)=='.') {
            p_line=_LCQLineNumberAtIndex(i);
            line_to_top();
            return;
         }
      } else if (searchfor=='SPECIAL') {
         flags=_LCQFlagsAtIndex(i);
         if (flags & (VSLCFLAG_TABS|VSLCFLAG_COLS|VSLCFLAG_BOUNDS|VSLCFLAG_MASK)) {
            p_line=_LCQLineNumberAtIndex(i);
            line_to_top();
            return;
         }
      } else if (searchfor=='COMMAND') {
         ch := substr(data,1,1);
         if (ch!='.') {
            p_line=_LCQLineNumberAtIndex(i);
            line_to_top();
            return;
         }
      } else if (searchfor=='CHANGE') {
         flags=_LCQFlagsAtIndex(i);
         if (flags & VSLCFLAG_CHANGE) {
            p_line=_LCQLineNumberAtIndex(i);
            line_to_top();
            return;
         }
      } else if (searchfor=='ERROR') {
         flags=_LCQFlagsAtIndex(i);
         if (flags & VSLCFLAG_ERROR) {
            p_line=_LCQLineNumberAtIndex(i);
            line_to_top();
            return;
         }
      }
   }
   if (searchfor=='LABEL') {
      clear_message();
      _message_box("Label not found");
   } else if (searchfor=='SPECIAL') {
      clear_message();
      _message_box("Special not found");
   } else if (searchfor=='COMMAND') {
      clear_message();
      _message_box("Pending command not found");
   } else if (searchfor=='CHANGE') {
      clear_message();
      _message_box("Change not found");
   } else if (searchfor=='ERROR') {
      clear_message();
      _message_box("Error not found");
   }
}
