////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47987 $
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
#include "color.sh"
#import "complete.e"
#import "diff.e"
#import "files.e"
#import "guiopen.e"
#import "ini.e"
#import "last.e"
#import "listbox.e"
#import "main.e"
#import "optionsxml.e"
#import "recmacro.e"
#import "savecfg.e"
#import "seltree.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

#define COMMENT_MULTILINE  1
#define COMMENT_SINGLELINE 2
#define MAX_MLCOMMENTS 4

#define CCTAB_COMMENTS   4

#define NO_LEXER     '(None)'

#define KEYWORDS     '_ctlkeywords'
#define CSKEYWORDS   '_ctlcs_keywords'
#define PREPROCESSOR '_ctlpp_keywords'
#define SYMBOL1      '_ctlsymbol1'
#define SYMBOL2      '_ctlsymbol2'
#define SYMBOL3      '_ctlsymbol3'
#define SYMBOL4      '_ctlsymbol4'

struct CLEXDEF {
   boolean  case_sensitive;
   _str filename;//File where the lexer came from
   _str idchars;
   _str styles;
   _str keywords[];
   _str cskeywords[];
   _str ppkeywords[];
   _str symbol1[];
   _str symbol2[];
   _str symbol3[];
   _str symbol4[];
   COMMENT_TYPE comments[];
   _str comment_keywords;
   _str comment_attributes:[];//3:02pm 1/6/1998 For xml/html embedded languages
   _str comment_values:[];    //12:14pm 8/14/2001 for xml/html languages
};

/**
 * Adds a new blank lexer with the given name to the user's 
 * color coding file. 
 * 
 * @param lexer      name for lexer
 */
void addNewBlankLexer(_str lexer) 
{
   // get our user vlx file
   file := _ConfigPath():+USER_LEXER_FILENAME;

   // create a temp view where we'll stash our info
   lexer_view_id := 0;
   orig_view_id := _create_temp_view(lexer_view_id);
   p_window_id = lexer_view_id;

   // now put in our info - there's not much to it
   insert_line('idchars=a-zA-Z_$ 0-9');
   insert_line('case-sensitive=n');

   // insert a section into the ini file
   _ini_put_section(file, lexer, lexer_view_id);

   p_window_id = orig_view_id;
}

/**
 * Copies a lexer.
 *  
 * @param srcLexer      name of source lexer
 * @param destLexer     name of destination lexer.
 * 
 * @return              whether lexer copy was successful
 */
boolean copyLexer(_str srcLexer, _str destLexer)
{
   // find the source lexer
   orig_view_id := p_window_id;
   src_view_id := 0;
   if (_FindLexerFile(srcLexer, true, orig_view_id, src_view_id)) {
      // get our user vlx file
      file := _ConfigPath():+USER_LEXER_FILENAME;

      // insert the section into the ini file under the new name
      return (_ini_put_section(file, destLexer, src_view_id) == 0);
   }

   // hey, that was fun
   return true;
}

defeventtab _cc_form;
/*

   BE CAREFUL, THIS LIST MAYBE INCOMPLETE!!! BEFORE YOU USE A CONTROL'S P_USER
   PROPERTY, SEARCH THIS FILE TO BE SURE THAT IT HAS NOT ALREADY BEEN USED.

* p_active_form.p_user   says don't update list
* _ctlok.p_user          clex files list
* _ctlnew_name.p_user    HASTAB list of all lexers to save 3:27pm 4/2/1996
* _ctlkeywords.p_user    name of the last type chosen
* _ctllexer_list.p_user  name of the last lexer chosen
  _ctlcancel.p_user      name of file that the current lexer is in
* _ctlcolors.p_user      if 1, means that _ctlexer_list.on_change is running
                         (no logic to the choice of this one, I'm just running
                         out)

  Be sure to get new complete.e (I added a case insensitive option to
  _remove_duplicates).

  Also, get a new color.e, I think that I just modified the on_create event to
  take an argument.
*/

#define LL_ONCHANGE_RUNNING    _ctlcolors.p_user
#define DONT_UPDATE_LIST       p_active_form.p_user
#define MODIFIED_LEXER_HASHTAB _ctlnew_name.p_user
#define LAST_TYPE              _ctlkeywords.p_user
#define LAST_LEXER_NAME        _ctllexer_list.p_user
#define CUR_LEXER_FILE         _ctlcancel.p_user
#define DELETE_LEXER_LIST      _ctldelete_lexer.p_user
#define CUR_COMMENT_ARRAY      _ctlnew_lc.p_user
#define OLD_COMMENT_ARRAY      _ctlnew_ml.p_user
#define CUR_COMMENT_INDEX      _ctlaftercol_rb.p_user
#define CUR_COMMENT_ISNEW      _ctlcheckfirst.p_user
#define CUR_TAG_NAME           _ctlattr_list.p_user
#define IGNORE_TAG_LIST_ON_CHANGE      _ctltag_list.p_user
#define CUR_ATTR_NAME          _ctlnew_attr.p_user
#define CUR_ATTR_VALUES        _ctlnew_value.p_user
#define ERROR_ON_LEXER_NAME_CHANGE   _ctlnew_tag.p_user

static int refresh_lexer_list = 0;

static CLEXDEF new_keyword_table:[];

_str unsaved_lexer_language_table:[];

#region Options Dialog Helper Functions

void set_refresh_lexer_list()
{
   refresh_lexer_list = 1;
}

void maybe_refresh_lexer_list()
{
   // we don't even need to do this
   if (!refresh_lexer_list) return;

   // get all the user lexers
   _str lexers[];
   _ini_get_sections_list(_ConfigPath():+USER_LEXER_FILENAME, lexers);   

   for (i := 0; i < lexers._length(); i++) {
      lexer := lexers[i];
      // see if this lexer is in our list box
      if (_ctllexer_list._lbfind_item(lexer) < 0) {
         // no?  maybe it has been deleted!
         if (!pos(' 'lexer',', ' 'DELETE_LEXER_LIST',')) {
            // we best add it then
            _ctllexer_list._lbadd_item(lexer);
         }
      }
   }

   // i feel refreshed
   refresh_lexer_list = 0;
}

void clear_unsaved_lexer_info_for_langId(_str langId)
{
   if (unsaved_lexer_language_table._indexin(langId'CaseSensitive')) {
      unsaved_lexer_language_table._deleteel(langId'CaseSensitive');
   } 
   if (unsaved_lexer_language_table._indexin(langId'Lexer')) {
      unsaved_lexer_language_table._deleteel(langId'Lexer');
   } 
}

_str get_unsaved_lexer_case_sensitivity_for_langId(_str langId)
{
   if (unsaved_lexer_language_table._indexin(langId'CaseSensitive')) {
      // now look up the value in the new_keyword_table
      return unsaved_lexer_language_table:[langId'CaseSensitive'];
   } 

   return '';
}

_str get_unsaved_lexer_name_for_langId(_str langId)
{
   if (unsaved_lexer_language_table._indexin(langId'Lexer')) {
      // now look up the value in the new_keyword_table
      return unsaved_lexer_language_table:[langId'Lexer'];
   } 

   return '';
}

void _cc_form_init_for_options(_str langId)
{
   _ctlok.p_visible = false;
   _ctlcancel.p_visible = false;
   _ctlhelp.p_visible = false;

   _ctlimport.p_x = _ctlok.p_x;
   _ctlcolors.p_x = _ctlcancel.p_x;

   // set the proper lexer to display
   lexer_name := LanguageSettings.getLexerName(langId);

   _ctllexer_list._lbfind_and_select_item(lexer_name, '', true);

   // save the current lang id
   unsaved_lexer_language_table:['currentLangId'] = langId;
}

boolean _cc_form_validate()
{
   // save the settings from this version of the lexer options - we do this
   // in validate so that we have the chance to cancel the switch to another
   // options node if necessary

   curLangId := unsaved_lexer_language_table:['currentLangId'];
   if (curLangId != null) {
      unsaved_lexer_language_table:[curLangId'Lexer'] = _ctllexer_list.p_text;
      unsaved_lexer_language_table:[curLangId'CaseSensitive'] = _ctlcase_sensitive.p_value;
   }

   if (save_last_settings()) return false;

   // everything checked out fine
   return true;
}

void _cc_form_restore_state(_str langId)
{
   // we might have to refresh the list, if something has been added
   maybe_refresh_lexer_list();

   // see if we've already looked at this language and saved this info
   if (unsaved_lexer_language_table._indexin(langId'Lexer')) {
      lexer_name := unsaved_lexer_language_table:[langId'Lexer'];
      if (lexer_name != _ctllexer_list._lbget_text()) {
         _ctllexer_list._lbfind_and_select_item(lexer_name, '', true);
      }
   } else {
      // we haven't looked at this one yet.  look at it now!
      lexer_name := LanguageSettings.getLexerName(langId);
      unsaved_lexer_language_table:[langId] = lexer_name;

      _ctllexer_list._lbfind_and_select_item(lexer_name, '', true);
   }

   unsaved_lexer_language_table:['currentLangId'] = langId;
}

boolean _cc_form_is_modified()
{
   // see if current lexer for this language was modified
   langId := unsaved_lexer_language_table:['currentLangId'];
   lexer := LanguageSettings.getLexerName(langId);

   if (stricmp(lexer, _ctllexer_list.p_text) && !(lexer == '' && _ctllexer_list.p_text == NO_LEXER)) {
      return true;
   }

   if (DELETE_LEXER_LIST != '') {
      return true;
   }

   return (MODIFIED_LEXER_HASHTAB._varformat() == VF_HASHTAB && MODIFIED_LEXER_HASHTAB._indexin(_ctllexer_list.p_text)); 
}

boolean _cc_form_apply()
{
   if (!DONT_UPDATE_LIST) {
      if(save_last_settings()) {
         return false;
      }
   }

   mou_hour_glass(1);
   int orig_view_id=p_window_id;
   int lexer_view_id=0;
   int status=0;
   _str filename='';
   _str cur='';
   typeless ptr;
   typeless temp;
   typeless hashindex;
   for (hashindex._makeempty();;) {
      if (lexer_view_id!=0) {
         _delete_temp_view(lexer_view_id);
         lexer_view_id=0;
      }
      ptr=&new_keyword_table._nextel(hashindex);
      if (hashindex._isempty()) {
         break;
      }
      _str lexername=hashindex;
      temp=MODIFIED_LEXER_HASHTAB;
      if (temp._varformat()!=VF_HASHTAB || !temp._indexin(lexername)) {
         continue;
      }
      filename=_ConfigPath():+USER_LEXER_FILENAME;
      if (filename!='') {
         status=_ini_get_section(filename,lexername,lexer_view_id);
         if (status) {
            //Section does not currently exist in this file
            orig_view_id=_create_temp_view(lexer_view_id);
            if (orig_view_id) status=0;
            p_window_id=orig_view_id;
         }
      }else{
         orig_view_id=_create_temp_view(lexer_view_id);
         //Have to keep filename for new user file to be used later 11:10am 4/4/1996
         filename=_ConfigPath():+USER_LEXER_FILENAME;
         if (orig_view_id) status=0;
         p_window_id=orig_view_id;
         //parse CLEX_FILE_LIST with filename ';' .
         //I don't think that this applies anymore 11:41am 4/3/1996
      }
      message(nls("Working on color lexer file '%s'",filename));
      if (!status) {
         p_window_id=lexer_view_id;

         top();up();
         while (!search('^mlckeywords','r@i')) {
            _delete_line();up();
         }

         top();up();
         status=search('^( |\t)@idchars','ir@');
         if (!status) _delete_line();
         top();
         insert_line('idchars='new_keyword_table:[lexername].idchars);
         top();up();
         status=search('^( |\t)@case-sensitive','ir@');
         if (!status) _delete_line();
         top();
         _str ch;
         if (new_keyword_table:[lexername].case_sensitive) {
            ch='y';
         }else{
            ch='n';
         }
         insert_line('case-sensitive='ch);
         ReplaceKeywordList("keywords",new_keyword_table:[lexername].keywords);
         ReplaceKeywordList("cskeywords",new_keyword_table:[lexername].cskeywords);
         ReplaceKeywordList("ppkeywords",new_keyword_table:[lexername].ppkeywords);
         ReplaceKeywordList("punctuation",new_keyword_table:[lexername].symbol1);
         ReplaceKeywordList("libkeywords",new_keyword_table:[lexername].symbol2);
         ReplaceKeywordList("operators",new_keyword_table:[lexername].symbol3);
         ReplaceKeywordList("userkeywords",new_keyword_table:[lexername].symbol4);
         ReplaceStylesLine(new_keyword_table:[lexername].styles);

         p_line=0;
         while (!search('^( |\t)@mlcomment( |\t)@=','r@')) {
            _delete_line();up();
         }
         p_line=0;
         while (!search('^( |\t)@linecomment( |\t)@=','r@')) {
            _delete_line();up();
         }
         p_line=0;
         while (!search('^( |\t)@mlckeywords( |\t)@=','r@')) {
            _delete_line();up();
         }
         p_line=0;
         while (!search('^( |\t)@keywordattrs( |\t)@=','r@')) {
            _delete_line();up();
         }
         p_line=0;
         while (!search('^( |\t)@attrvalues( |\t)@=','r@')) {
            _delete_line();up();
         }
         bottom();//Don't want to put anything in front of id-chars and case-sensitive
         typeless comments=new_keyword_table:[lexername].comments;
         _str line='';
         _str delim='';
         _str sep='';
         int i;
         for (i=0;i<comments._length();++i) {
            COMMENT_TYPE temp_comment;
            temp_comment=comments[i];
            switch (temp_comment.type) {
            case COMMENT_MULTILINE:
               line='mlcomment='temp_comment.delim1;
               if (!temp_comment.startcol) {
                  line=line' 'temp_comment.delim2;
                  if (temp_comment.nesting) {
                     line=line' nesting';
                  }
                  if (temp_comment.isDocumentation) {
                     line=line' documentation';
                  }
                  if (temp_comment.idchars!='') {
                     line=line' followedby 'temp_comment.idchars;
                  }
                  if (temp_comment.colorname!='') {
                     line=line' 'temp_comment.colorname;
                  }
               }else{
                  line=line' 'temp_comment.startcol;
                  if (temp_comment.cf_or_l!='') {
                     line=line' 'temp_comment.cf_or_l;
                  }
                  line=line' 'temp_comment.delim2;
                  if (temp_comment.lastchar) {
                     line=line' lastchar';
                  }
               }
               insert_line(line);
               break;
            case COMMENT_SINGLELINE:
               delim=temp_comment.delim1;
               if (CCNeedQuotes(delim)) {
                  delim=_dquote(delim);
               }
               line='linecomment='delim;
               if (temp_comment.startcol) {
                  line=line' 'temp_comment.startcol;
                  if (temp_comment.repeat) {
                     //Will put in redundant info if we aren't careful
                     if (temp_comment.cf_or_l!='+') {
                        line=line'+';
                     }
                  }else if (temp_comment.endcol) {
                     line=line'-'temp_comment.endcol;
                  }
               }
               if (temp_comment.precededbyblank) {
                  line=line' precededbyblank';
               }
               if (temp_comment.isDocumentation) {
                  line=line' documentation';
               }
               if (temp_comment.backslashContinuation) {
                  line=line' continuation';
               }
               if (temp_comment.cf_or_l!='') {
                  if (temp_comment.cf_or_l=='+') {
                     sep='';
                  }else{
                     sep=' ';
                  }
                  line=line:+sep:+temp_comment.cf_or_l;
               }
               insert_line(line);
               break;
            }
         }
         // XML/HTML tags
         _str comment_keywords=new_keyword_table:[lexername].comment_keywords;
         if (comment_keywords!='') {
            bottom();
            _str keyword_list=comment_keywords;
            line='';
            for (;;) {
               if (line=='') {
                  line='mlckeywords=';
               }
               parse keyword_list with cur keyword_list;
               if (cur=='') {
                  break;
               }
               line=line' 'cur;
               if (length(line)>70) {
                  insert_line(line);
                  line='';
               }
            }
            if (line!='') insert_line(line);
         }
         // attributes for XML/HTML tags
         typeless hi;
         _str comment_attrs:[];
         comment_attrs=new_keyword_table:[lexername].comment_attributes;
         if (comment_attrs._varformat()==VF_HASHTAB) {
            bottom();
            for (hi._makeempty();;) {
               comment_attrs._nextel(hi);
               if (hi._isempty()) break;
               if (comment_attrs:[hi]!='') {
                  insert_line('keywordattrs='hi' 'comment_attrs:[hi]);
               }
            }
         }
         // values for XML/HTML attributes
         comment_attrs=new_keyword_table:[lexername].comment_values;
         if (comment_attrs._varformat()==VF_HASHTAB) {
            bottom();
            for (hi._makeempty();;) {
               comment_attrs._nextel(hi);
               if (hi._isempty()) break;
               if (comment_attrs:[hi]!='') {
                  insert_line('attrvalues='hi' 'comment_attrs:[hi]);
               }
            }
         }
         //break;
      }
      p_window_id=orig_view_id;
      message(nls("Writing color lexer file '%s'",filename));
      status=_ini_put_section(filename,lexername,lexer_view_id);
      if (status) {
         _message_box(nls("Could not write to color lexer file %s.\n\n%s",filename,get_message(status)));
      }
      p_window_id=orig_view_id;//Paranoia
      lexer_view_id=0;

      call_list('_lexer_updated_', lexername);
   }
   if (lexer_view_id!=0) {
      _delete_temp_view(lexer_view_id);
      lexer_view_id=0;
   }
   p_window_id=orig_view_id;//Paranoia
   delete_lexers(DELETE_LEXER_LIST);
   _str filenamelist=LEXER_FILE_LIST;
   for (;;) {
      parse filenamelist with cur (PATHSEP) filenamelist;
      if (cur=='') break;
      message(nls("Reloading color lexer file '%s'",cur));
      if (file_exists(cur)) {
         //9:12am 3/7/2000
         //Only reload if the file exists.
         //Switched to calling _clex_load so that if there are problems,
         //we don't get two error messages.
         status=_clex_load(cur);
         if (status) {
            _message_box(nls("Could not load file '%s'\n\n%s",cur,get_message(status)));
         }
      }
   }
   clear_message();

   // first things first - set each lexer to their langID
   _str key, lexerName;
   foreach (key => lexerName in unsaved_lexer_language_table) {

      // determine if this is a lexer key by checking for the word 'Lexer'
      lexPos := pos('Lexer', key);
      if (lexPos) {
         langId := substr(key, 1, lexPos - 1);
         if (langId != '' && langId != '0') {
            // set the new lexer for the language
            if (lexerName != null) {
               LanguageSettings.setLexerName(langId, lexerName);

               // update the open buffers in this language
               _update_buffers(langId, LEXER_NAME_UPDATE_KEY'='lexerName);
            }
         }
      }
   }

   // clear out the hash table
   curId := unsaved_lexer_language_table:['currentLangId'];
   unsaved_lexer_language_table._makeempty();
   unsaved_lexer_language_table:['currentLangId'] = curId;

   MODIFIED_LEXER_HASHTAB=0;

   mou_hour_glass(0);

   return true;
}

void _cc_form_cancel()
{
   // clear out the hash table
   unsaved_lexer_language_table._makeempty();

   if (LAST_LEXER_NAME!=null && LAST_LEXER_NAME!='' && LAST_LEXER_NAME!=NO_LEXER) {
      _str orig_styles=new_keyword_table:[LAST_LEXER_NAME].styles;
      new_keyword_table:[LAST_LEXER_NAME].styles=get_styles();
      if (!cc_styles_eq(new_keyword_table:[LAST_LEXER_NAME].styles,orig_styles)) {
         AddLexerToModList();
      }
      cc_update_line_comment(true);
      cc_update_ml_comment(true);
      if (cc_comments_changed()) {
         new_keyword_table:[LAST_LEXER_NAME].comments=CUR_COMMENT_ARRAY;
         AddLexerToModList();
      }
      cc_update_tags(false);
   }
}

_str _cc_form_export_settings(_str &file, _str &args, _str langID)
{
   error := '';
   
   // just set the args to be the lexer name for this langauge
   args = LanguageSettings.getLexerName(langID);
   if (args == null) {
      // if it doesn't exist, we just ignore it
      args = '';
      return '';;
   }
         
   targetFile := file :+ USER_LEXER_FILENAME;
   alreadyThere := file_exists(targetFile);
   
   // see if this file already exists - that means we've already 
   // exported a lexer (and this one with it) - so do nothing!
   if (!alreadyThere) {
      // the system lexer file is our base
      sysLexer := get_env('VSROOT') :+ SYSTEM_LEXER_FILENAME;
      userLexer := _ConfigPath() :+ USER_LEXER_FILENAME;
      if (copy_file(sysLexer, targetFile)) error = 'Error copying system lexer file, 'sysLexer'.';
      else if (file_exists(userLexer) && _ini_combine_files(targetFile, userLexer)) {
         error = 'Error copying user lexer file, 'userLexer'.';
      }
   }

   // make sure our lexer exists in that file
   tempView := 0;
   status := _ini_get_section(targetFile, args, tempView);
   if (status) {
      // special case!  check for the oem lexer file

      filename := get_env('VSROOT'):+OEM_LEXER_FILENAME;
      status = _ini_get_section(filename, args, tempView);
      if (!status) {
         // we don't need the original file in this case, 
         // so delete it if we created it just now
         if (!alreadyThere) delete_file(targetFile);
      } else {
         // okay, we couldn't find it - bummer
         args = NO_LEXER;
         // delete the file if we created it just now
         if (!alreadyThere) delete_file(targetFile);
      }
   } else file = USER_LEXER_FILENAME;
   
   return error;
}

_str _cc_form_import_settings(_str &file, _str &args, _str langID)
{
   error := '';
   
   if (args == NO_LEXER) {
      // in that case, we don't care about the file, just set the lexer to null
      LanguageSettings.setLexerName(langID, args);

      return error;
   }

   if (file != '') {
      do {
         // get the lexer for this language - the name should be the args
         tempView := 0;
         status := _ini_get_section(file, args, tempView);
         if (status) {
            error = 'Error retrieving lexer information for '_LangId2Modename(langID)'.';
            break;
         }
         
         userLexerFile := _ConfigPath() :+ USER_LEXER_FILENAME;
         status = _ini_put_section(userLexerFile, args, tempView);
         if (status) {
            error = 'Error importing lexer information for '_LangId2Modename(langID)'.';
            break;
         }
         
         // now set the lexer name for the language
         LanguageSettings.setLexerName(langID, args);
         
      } while (false);
   } else {
      // this could be a special case - an OEM lexer
      filename := get_env('VSROOT'):+OEM_LEXER_FILENAME;
      status := _ini_get_section(filename, args, auto tempView);
      if (status) {
         error = 'Error retrieving lexer information for '_LangId2Modename(langID)'.';
      } else {
      // set the lexer name, it's an OEM lexer filename
         LanguageSettings.setLexerName(langID, args);
      }
   }
   
   return error;
}

#endregion Options Dialog Helper Functions

_str _FindLexerFile(_str lexername,boolean leaveTempViewOpen=false,int &orig_wid=0,int &temp_view_id=0)
{
   _str filename='';
   orig_wid=p_window_id;
   temp_view_id=0;

   do {
      // user.vlx
      filename=usercfg_path_search(USER_LEXER_FILENAME);
      int status=_ini_get_section(filename,lexername,temp_view_id);
      if (!status) break;

      // vslick.vlx
      filename=get_env('VSROOT'):+SYSTEM_LEXER_FILENAME;
      status=_ini_get_section(filename,lexername,temp_view_id);
      if (!status) break;

      // oem.vlx
      filename=get_env('VSROOT'):+OEM_LEXER_FILENAME;
      status=_ini_get_section(filename,lexername,temp_view_id);
      if (!status) break;

      // no match
      return '';

   } while (false);

   // cleanup
   if (!leaveTempViewOpen) {
      p_window_id=orig_wid;
      _delete_temp_view(temp_view_id);
   }
   return(filename);
}

_str clex_parse_word(var line)
{
   line=strip(line,'B');
   _str word="";
   _str ch=substr(line,1,1);
   if (ch=='"') {
      int end_quote=pos(ch,line,2);
      for (;;) {
         if (!end_quote) {
            end_quote=length(line);
            break;
         } else if (substr(line, end_quote-1, 1) == '\') {
            end_quote = pos(ch, line, end_quote+1);
         } else {
            break;
         }
      }
      
      word=substr(line,1,end_quote);
      line=strip(substr(line,end_quote+1),'B');
      return(word);
   }
   parse line with word line ;
   return(word);
}
_ctlok.on_create(_str lexer_name='', int initial_tab=-1)
{
   IGNORE_TAG_LIST_ON_CHANGE = 0;

   // we don't need to refresh, we are starting anew!
   refresh_lexer_list = 0;

   // restore the initial tab
   if (initial_tab>=0) {
      _ctlsstab.p_ActiveTab=initial_tab;
   } else {
      _ctlsstab._retrieve_value();
   }

   // clear out the table of unsaved lexers
   unsaved_lexer_language_table._makeempty();

   // adjust the size of the tab control and form
   // (because it is extra-wide to make editing comments easier)
   _ctlsstab.p_width=_ctldelete_lexer.p_x+_ctldelete_lexer.p_width;
   int border_width=p_active_form.p_width-_dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   p_active_form.p_width=_ctlsstab.p_x+_ctlsstab.p_width+_ctlsstab.p_x+border_width;
   _ctl_ml_frame.p_x=_ctl_lc_frame.p_x;
   _ctl_ml_frame.p_y=_ctl_lc_frame.p_y;
   _ctl_lc_frame.p_visible=_ctl_lc_frame.p_enabled=false;
   _ctl_ml_frame.p_visible=_ctl_ml_frame.p_enabled=false;
   CUR_COMMENT_INDEX=-1;
   CUR_COMMENT_ISNEW=0;

   // if we are coming from an mdi window, set the lexer to the current one
   int wid=_form_parent();
   if (lexer_name=="" && wid.p_HasBuffer && !(wid.p_window_flags & HIDE_WINDOW_OVERLAP)) {
      lexer_name=wid.p_lexer_name;
   }

   //new_keyword_table=_notinit;
   //This cannot be here because the function is re-entrant

   // add the lexers to the combo box
   _ctllexer_list._lbclear();
   _str filenamelist=LEXER_FILE_LIST;
   for (;;) {
      parse filenamelist with auto filename (PATHSEP) filenamelist;
      if (filename=='') break;
      _ctllexer_list._ini_list_sections(filename);
   }

   // add any additional lexers from the keyword table - no need to search,
   // as we will remove duplicates later
   typeless status=0;
   if (new_keyword_table._varformat()!=VF_EMPTY) {
      typeless i;
      for (i._makeempty();;) {
         typeless ptr=&new_keyword_table._nextel(i);
         if (i._isempty()) break;
         _ctllexer_list._lbadd_item(i);
      }
   }

   _ctlkeywords.p_value=1;

   _ctllexer_list._lbadd_item(NO_LEXER);
   _ctllexer_list._lbsort('i');
   _ctllexer_list._lbremove_duplicates();
   _ctllexer_list._lbtop();

   LAST_TYPE=KEYWORDS;
   MODIFIED_LEXER_HASHTAB=0;

   // select the lexer specified
   if (lexer_name!='' && lexer_name!='fundamental') {
      if (_ctllexer_list._lbfind_item(lexer_name) < 0) {
         // it's not in there, so add it
         AddNewLexer(lexer_name);
      }
   }

   _ctllexer_list._lbselect_line();
   DONT_UPDATE_LIST=0;
}

_ctlok.on_destroy()
{
   _ctlsstab._append_retrieve(_ctlsstab, _ctlsstab.p_ActiveTab);
   new_keyword_table._makeempty();
   //show('-mdi _var_editor_form','',&new_keyword_table);
}

static void cc_prepare_tags_tab()
{
   int orig_active=_ctlsstab.p_ActiveTab;
   _ctlsstab.p_ActiveTab=5; /* Tags */
   _ctlsstab.p_ActiveEnabled=((ctlhtml.p_value || ctlxml.p_value)? true:false);
   ctllinedocs.p_enabled = !_ctlsstab.p_ActiveEnabled;
   ctlblockdocs.p_enabled = !_ctlsstab.p_ActiveEnabled;
   _ctlsstab.p_ActiveTab=orig_active;
   if (!ctlhtml.p_value && !ctlxml.p_value && orig_active==5) {
      _ctlsstab.p_ActiveTab=0;
   }
}

static void AddLexerToModList()
{
   if (LAST_LEXER_NAME == NO_LEXER) return;

   int fid=p_active_form;
   if (p_active_form.p_name!='_cc_form') {
      //return;
      fid=_find_formobj('_cc_form','N');
      if (!fid) return;
   }
   _str temp:[];
   if (fid.MODIFIED_LEXER_HASHTAB._varformat()==VF_HASHTAB) {
      temp=fid.MODIFIED_LEXER_HASHTAB;
   }
   temp:[fid.LAST_LEXER_NAME]=1;
   fid.MODIFIED_LEXER_HASHTAB=temp;
   _nocheck _control _ctlcancel;
   fid.CUR_LEXER_FILE=USER_LEXER_FILENAME;//If the lexer is modified we now want it
                                     //written to the user file
}

_ctlcase_sensitive.lbutton_up()
{
   AddLexerToModList();
   //say('mod0');
}

void _ctlcancel.lbutton_up()
{
   _cc_form_cancel();

   if (MODIFIED_LEXER_HASHTAB._varformat()==VF_HASHTAB) {//Has been changed to list
      _str temp=MODIFIED_LEXER_HASHTAB;
      int result=_message_box(nls("Changes have been made.\n\nExit Anyway?"),
                          '',
                          MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result!=IDYES) return;
   }
   p_active_form._delete_window('');
}

static int active_keyword_rb()
{
   if (_ctlkeywords.p_value)    return(_ctlkeywords);
   if (_ctlcs_keywords.p_value) return(_ctlcs_keywords);
   if (_ctlpp_keywords.p_value) return(_ctlpp_keywords);
   if (_ctlsymbol1.p_value)     return(_ctlsymbol1);
   if (_ctlsymbol2.p_value)     return(_ctlsymbol2);
   if (_ctlsymbol3.p_value)     return(_ctlsymbol3);
   if (_ctlsymbol4.p_value)     return(_ctlsymbol4);
   return(-1);
}


_ctlfollow_idchars.on_change()
{
   if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
      AddLexerToModList();//say('mod5');
   }
}

_ctlstart_idchars.on_change()
{
   if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
      AddLexerToModList();//say('mod6');
   }
}

void disable_enable_tabs(int tabControl, boolean enable)
{
   int i;
   for (i = 0; i < tabControl.p_NofTabs; i++) {
      tabControl._setEnabled(i, (int)enable);
   }
}

void _ctllexer_list.on_change(int reason)
{
   if (ERROR_ON_LEXER_NAME_CHANGE==1) {
      return;
   }
   LL_ONCHANGE_RUNNING=1;

   // validate any changes that were made
   errorTab := validate_lexer();
   if (errorTab >= 0) {
      // failed validation, switch back to the last lexer
      ERROR_ON_LEXER_NAME_CHANGE=1;
      _ctllexer_list.p_text=LAST_LEXER_NAME;
      ERROR_ON_LEXER_NAME_CHANGE='';

      // switch to the tab that errored
      _ctlsstab.p_ActiveTab = errorTab;
      LL_ONCHANGE_RUNNING=0;
      return;
   }

   if (!DONT_UPDATE_LIST) {
      // Save the last settings
      if(save_last_settings() ) {
         ERROR_ON_LEXER_NAME_CHANGE=1;
         _ctllexer_list.p_text=LAST_LEXER_NAME;
         ERROR_ON_LEXER_NAME_CHANGE='';
         LL_ONCHANGE_RUNNING=0;
         return;
      }
   }
   LAST_LEXER_NAME=_ctllexer_list.p_text;

   //Reset all the values
   _ctlcase_sensitive.p_value=0;
   _ctlstart_idchars.p_text='';
   _ctlfollow_idchars.p_text='';

   if (_ctllexer_list.p_text == NO_LEXER) {
      // disable all controls
      _ctldelete_lexer.p_enabled = false;
      disable_enable_tabs(_ctlsstab.p_window_id, false);

      return;
   } else if (!_ctldelete_lexer.p_enabled) {
      _ctldelete_lexer.p_enabled = true;
      disable_enable_tabs(_ctlsstab.p_window_id, true);
   }

   //We need to check and see if the lexer is loaded.  Any field should be ok
   if (new_keyword_table:[_ctllexer_list.p_text].case_sensitive._varformat()==VF_EMPTY) {
      int orig_view_id=p_window_id;
      int lexer_view_id=0;
      _str filename=_FindLexerFile(_ctllexer_list.p_text);
      CUR_LEXER_FILE=filename;
      int status=_ini_get_section(filename,
                              _ctllexer_list.p_text,
                              lexer_view_id);
      if (!status) {
         LoadLexer(lexer_view_id,new_keyword_table:[_ctllexer_list.p_text]);
         _delete_temp_view(lexer_view_id);
         p_window_id=orig_view_id;
      }else{
         if (status!=STRING_NOT_FOUND_RC) {
            _message_box(nls("Could not open lexer file '%s'\n\n%s",
                         filename,get_message(status)));
         }
      }
   } else {
      CUR_LEXER_FILE=_FindLexerFile(_ctllexer_list.p_text);
   }
   if (new_keyword_table:[_ctllexer_list.p_text].case_sensitive._varformat()!=VF_EMPTY) {
      _ctlcase_sensitive.p_value=(int)new_keyword_table:[_ctllexer_list.p_text].case_sensitive;
      _str idchars=new_keyword_table:[_ctllexer_list.p_text].idchars;
      _str start,follow;
      parse idchars with start follow;
      _ctlstart_idchars.p_text=start;
      _ctlfollow_idchars.p_text=follow;
   }
   cc_prepare_styles(_ctllexer_list.p_text);
   cc_prepare_comments(_ctllexer_list.p_text,true);
   cc_prepare_tags(_ctllexer_list.p_text);
   cc_prepare_tags_tab();
   _ctlkeywords.cc_prepare_kwdlist(LAST_TYPE);
   //_ctlkeywords.call_event(_ctlkeywords,LBUTTON_UP);
   _ctlcomment_list.call_event(CHANGE_SELECTED,_ctlcomment_list,on_change,'W');
   _ctldelete_lexer.p_enabled=!file_eq(_strip_filename(CUR_LEXER_FILE,'P'),SYSTEM_LEXER_FILENAME);
   LL_ONCHANGE_RUNNING=0;
}

static void AddNewLexer(_str LexerName, _str copyFromLexer = '')
{
   int wid=p_window_id;
   p_window_id=_ctllexer_list;
   save_pos(auto p);
   _lbtop();_lbup();
   //p_window_id=wid;
   if (!_lbfind_and_select_item(LexerName)) {
      _message_box(nls("A lexer definition named '%s' already exists.",LexerName));
      p_window_id=wid;
      return;
   }
   restore_pos(p);
   if (copyFromLexer == '') {
      new_keyword_table:[LexerName].styles='';
      new_keyword_table:[LexerName].comments._makeempty();
      new_keyword_table:[LexerName].idchars='a-zA-Z 0-9_';
      new_keyword_table:[LexerName].case_sensitive=0;
      new_keyword_table:[LexerName].comment_keywords='';
   } else {
      // do not load it, just copy the settings and the _ctllexer_list
      // on_change event will handle it
      copyLexer(copyFromLexer, LexerName);
   }
   wid=p_window_id;
   p_window_id=_ctllexer_list;
   _lbadd_item(LexerName);
   _lbsort('i');
   _lbfind_and_select_item(LexerName);
   AddLexerToModList();
   p_window_id=wid;
}

_ctlnew.lbutton_up()
{
   result := show('-modal _create_new_lexer_form');

   if (result != '') {
      AddNewLexer(_param1, _param2);
   }
}

/**
 * Callback to ensure that the lexer name is acceptable as according to our very 
 * high standards. 
 * 
 * @param name    the lexer name to be verified
 * 
 * @return        0 for successful validation, error otherwise
 */
boolean verifyLexerName(_str name)
{
   // we don't allow no blank lexer names 'round here
   if (name == '') {
      _message_box("Please enter a lexer name.");
      return 1;
   }

   // everything's alright
   return 0;
}

_ctlkw_list.DEL()
{
   if (_ctldelete_name.p_enabled) {
      _ctldelete_name.call_event(_ctldelete_name,LBUTTON_UP,'W');
   }
}
_ctldelete_name.lbutton_up()
{
   AddLexerToModList();
   mou_hour_glass(1);
   boolean ff=true;
   p_window_id=_control _ctlkw_list;
   while (!_lbfind_selected(ff)) {
      _lbdelete_item();
      _lbup();
      ff=false;
   }
   _lbdown();
   _lbselect_line();
   mou_hour_glass(0);
}
void _ctlget.lbutton_up()
{
   typeless result=_OpenDialog('-modal ',
               'Get File',
               '*.*',
               'All Files (*.*)',
               OFN_FILEMUSTEXIST,  //OFN_FILEMUSTEXIST can create new file.
               '',
               '',
               '');
   if (result=='') return;
   _str filename=result;
   int list1wid=_ctlkw_list;
   mou_hour_glass(1);
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(result,temp_view_id,orig_view_id,'+d');
   if (status) {
      _message_box(nls("Could not open %s\n\n%s",filename,get_message(status)));
      mou_hour_glass(0);
      return;
   }
   _str line='';
   _str cur='';
   p_window_id=temp_view_id;
   top();up();
   while (!down()) {
      get_line(line);
      for (;;) {
         cur = clex_parse_word(line);
         if (cur=='') break;
         list1wid._lbadd_item(cur);
      }
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   int wid=p_window_id;p_window_id=_ctlkw_list;
#if 1   /* HERE - 11/6/1996 - by Rodney */
   _lbdeselect_all();
   AddLexerToModList();
   //say('mod8');
#endif
   _lbsort();
   _lbtop();
   _lbremove_duplicates();
   _lbtop();
   _lbselect_line();
   p_window_id=wid;
   mou_hour_glass(0);
   _ctldelete_name.p_enabled=_ctlkw_list.p_Noflines!=0;
}

static void make_keyword_list(_str (&list)[])
{
   int list_size = p_Noflines;
   list._makeempty();
   if (list_size == 0) {
      return;
   }
   list[list_size-1] = "";
   mou_hour_glass(1);
   int count = 0;
   _lbtop();_lbup();
   while (!_lbdown()) {
      _str text=_lbget_text();
      if (pos(' ',text) && !(substr(text, 1, 1)=='"' && substr(text, length(text), 1)=='"')) {
         text=_dquote(text);
      }
      list[count] = text; count++;
   }
   mou_hour_glass(0);
}

static void add_to_str(_str &str,_str newinfo,_str spacer=' ')
{
   if (str=='') {
      str=newinfo;
   }else{
      str=str:+spacer:+newinfo;
   }
}


//static _str * GetPointerToCurrentList(_str LexerName='')
static STRARRAYPTR GetKeywordList(_str LexerName='')
{
   if (LexerName=='') {
      LexerName=_ctllexer_list.p_text;
   }
   STRARRAYPTR arr = null;
   if (_ctlkeywords.p_value) {
       arr = &new_keyword_table:[LexerName].keywords;
    }else if (_ctlcs_keywords.p_value) {
       arr = &new_keyword_table:[LexerName].cskeywords;
    }else if (_ctlpp_keywords.p_value) {
       arr = &new_keyword_table:[LexerName].ppkeywords;
    }else if (_ctlsymbol1.p_value) {
       arr = &new_keyword_table:[LexerName].symbol1;
    }else if (_ctlsymbol2.p_value) {
       arr = &new_keyword_table:[LexerName].symbol2;
    }else if (_ctlsymbol3.p_value) {
       arr = &new_keyword_table:[LexerName].symbol3;
    }else if (_ctlsymbol4.p_value) {
       arr = &new_keyword_table:[LexerName].symbol4;
    }else{
       _message_box(nls("GetKeywordList:Should never get here. Call SlickEdit"));
       return(null);
   }
   return (arr);
}

//static _str * GetPointerToLastList(_str LexerName='')
static STRARRAYPTR GetLastTypeKeywordList(_str LexerName='')
{
   if (LexerName=='') {
      LexerName=LAST_LEXER_NAME;
   }
   STRARRAYPTR arr = null;
   if (lowcase(LAST_TYPE)==KEYWORDS) {
       arr = &new_keyword_table:[LexerName].keywords;
   } else if (LAST_TYPE==CSKEYWORDS) {
       arr = &new_keyword_table:[LexerName].cskeywords;
   } else if (LAST_TYPE==PREPROCESSOR) {
      arr = &new_keyword_table:[LexerName].ppkeywords;
   } else if (LAST_TYPE==SYMBOL1) {
      arr = &new_keyword_table:[LexerName].symbol1;
   } else if (LAST_TYPE==SYMBOL2) {
      arr = &new_keyword_table:[LexerName].symbol2;
   } else if (LAST_TYPE==SYMBOL3) {
      arr = &new_keyword_table:[LexerName].symbol3;
   } else if (LAST_TYPE==SYMBOL4) {
      arr = &new_keyword_table:[LexerName].symbol4;
   } else {
      _message_box(nls("Should never get here. Call SlickEdit"));
      _UpdateSlickCStack();
      return (null);
   }
   return (arr);
}

static _str ItemTable[]={"keywords","cskeywords","ppkeywords","symbol1","symbol2","symbol3","symbol4",
                         "punctuation","libkeywords","operators","userkeywords"};

static void LoadComments(COMMENT_TYPE (&comments)[])
{
   COMMENT_TYPE temp;
   top();up();
   int count=0;
   _str line='';

   comments._makeempty();
   while (!search('^( |\t)@(linecomment|mlcomment)','@ri>')) {
      get_line(line);
      temp=_process_comment(line);
      comments[count]=temp;
      ++count;
   }
}

static void LoadMLCKeywords(CLEXDEF &Lexer)
{
   _str line='';
   _str cur='';
   _str keyword='';
   _str attrs='';
   top();up();
   Lexer.comment_keywords='';
   Lexer.comment_attributes._makeempty();
   Lexer.comment_values._makeempty();

   while (!search('^( |\t)@(mlckeywords|keywordattrs|attrvalues)','@ri>')) {
      get_line(line);
      line=strip(line);
      if (lowcase(substr(line,1,11))=='mlckeywords') {
         parse line with '=' line;
         for (;;) {
            parse line with cur line;
            if (cur=='') break;
            if (Lexer.comment_keywords=='') {
               Lexer.comment_keywords=cur;
            }else{
               Lexer.comment_keywords=Lexer.comment_keywords' 'cur;
            }
         }
      } else if (lowcase(substr(line,1,12))=='keywordattrs') {
         parse line with '=' keyword attrs;
         Lexer.comment_attributes:[strip(keyword)]=strip(attrs);
      } else if (lowcase(substr(line,1,10))=='attrvalues') {
         parse line with '=' keyword attrs;
         Lexer.comment_values:[strip(keyword)]=strip(attrs);
      }
   }
}
static void LoadIDChars(CLEXDEF &Lexer)
{
   _str line='';
   _str val='';
   top();up();
   int status=search('^( |\t)@idchars','@ri');
   if (!status) {
      get_line(line);
      parse line with '=' val;
      Lexer.idchars=val;
   }
   top();up();
   status=search('^( |\t)@case-sensitive','@ri');
   if (!status) {
      get_line(line);
      parse line with '=' val;
      Lexer.case_sensitive=(lowcase(val)=='y');
   }
}
static void LoadLexer(int lexer_view_id,CLEXDEF &Lexer,_str toinsert='',int wid=0)
{
   _str line='';
   _str cur='';
   int orig_view_id=p_window_id;
   p_window_id=lexer_view_id;
   int i;
   for (i=0;i<ItemTable._length();++i) {
      _str word=ItemTable[i];
      top();up();

      STRARRAYPTR arr;
      switch (word) {
      case 'keywords':
         arr = &Lexer.keywords; break;
      case 'cskeywords':
         arr = &Lexer.cskeywords; break;
      case 'ppkeywords':
         arr = &Lexer.ppkeywords; break;
      case 'punctuation':
      case 'symbol1':
         arr = &Lexer.symbol1; break;
      case 'libkeywords':
      case 'symbol2':
         arr = &Lexer.symbol2; break;
      case 'operators':
      case 'symbol3':
         arr = &Lexer.symbol3; break;
      case 'userkeywords':
      case 'symbol4':
         arr = &Lexer.symbol4; break;
      }
      (*arr)._makeempty();
      _str str='';
      while (!search('^'word' @=','@ri>')) {
         get_line(line);
         _end_line();
         parse line with (word) '=' line;
         _str CopyOfLine=line;
         for (;;) {
            //cur=strip(parse_file(CopyOfLine),'B','"');
            cur=clex_parse_word(CopyOfLine);
            cur=strip(cur,"B"," \t");
            cur=strip(cur,"B","\r");
            cur=strip(cur,"B","\n");
            //say(CopyOfLine);say('cur='cur);
            if (cur=='') break;
            (*arr)[(*arr)._length()] = cur;
         }
         if (word==toinsert) {
            _lbadd_item_list(*arr);
         }
      }
   }
   if (toinsert!='') {
      p_window_id=orig_view_id;
      return;
   }
   LoadComments(Lexer.comments);
   LoadMLCKeywords(Lexer);
   LoadIDChars(Lexer);
   top();up();
   int status=search('^styles @=','ri@');
   if (status) {
      Lexer.styles='';
   }else{
      get_line(line);
      parse line with '=' Lexer.styles;
   }
   p_window_id=orig_view_id;
}

static void cc_prepare_kwdlist(...)
{
   //orig_name=p_name;
   int orig_view_id=p_window_id;
   _str word=stranslate(p_caption,'','&');
   word=lowcase(stranslate(word,'',' '));
   _ctlkw_list._lbclear();
   STRARRAYPTR keyword_list = GetKeywordList();
   if (new_keyword_table:[_ctllexer_list.p_text]._varformat()==VF_EMPTY) {
      //The information for this lexer is not in memory
      _str filename=_FindLexerFile(_ctllexer_list.p_text);
      int lexer_view_id=0;
      int status=_ini_get_section(filename,_ctllexer_list.p_text,lexer_view_id);
      if (!status) {
         LoadLexer(lexer_view_id,new_keyword_table:[_ctllexer_list.p_text],word,_ctlkw_list);
         _delete_temp_view(lexer_view_id);
         p_window_id = _ctlkw_list;
         _lbsort();
         _lbremove_duplicates();
         _lbtop();
         _lbselect_line();
      }
   } else if (keyword_list != null) {
      _ctlkw_list._lbadd_item_list(*keyword_list);
      _ctlkw_list._lbsort();
      _ctlkw_list._lbtop();
      _ctlkw_list._lbselect_line();
   }
   //LAST_TYPE=orig_name;
   LAST_LEXER_NAME = _ctllexer_list.p_text;
   _ctldelete_name.p_enabled = _ctlkw_list.p_Noflines!=0;
}
//This is the event handler for all the radio buttons.  Loads the information
//If it is not in memory
_ctlkeywords.lbutton_up()
{
   if (!DONT_UPDATE_LIST) {
      new_keyword_table:[LAST_LEXER_NAME].idchars=_ctlstart_idchars.p_text' '_ctlfollow_idchars.p_text;
      new_keyword_table:[LAST_LEXER_NAME].case_sensitive=_ctlcase_sensitive.p_value!=0;
      new_keyword_table:[LAST_LEXER_NAME].filename=CUR_LEXER_FILE;

      STRARRAYPTR keyword_list = GetLastTypeKeywordList();
      if (keyword_list != null) {
         _ctlkw_list.make_keyword_list(*keyword_list);
      }
   }
   _str orig_name=p_name;
   cc_prepare_kwdlist();
   LAST_TYPE=orig_name;
}

static void ReplaceKeywordList(_str ListType,_str (&List)[])
{
   //First Delete all existing lines that start with ListType
   top();up();
   while (!search('^'_escape_re_chars(ListType),'wr@')) {
      _delete_line();up();
   }

   // Next delete all existing lines that start with
   // the alternate ListType
   _str AltListType=null;
   switch (ListType) {
   case "punctuation":  AltListType="symbol1"; break;
   case "libkeywords":  AltListType="symbol2"; break;
   case "operators":    AltListType="symbol3"; break;
   case "userkeywords": AltListType="symbol4"; break;
   }
   if (AltListType!=null) {
      top();up();
      while (!search('^'_escape_re_chars(AltListType),'wr@')) {
         _delete_line();up();
      }
   }
   if (List._varformat()==VF_EMPTY) {
      return;
   }
   int i;
   _str line = ListType'=';
   _str cur = '';
   bottom();//Nothing can be in front of the lines that are for idchars, etc.
   for (i = 0; i < List._length(); ++i) {
      cur = List[i];
      line = line' 'cur;
      if (length(line) > 70) {
         insert_line(line);
         line = ListType'=';
      }
   }
   if (line != ListType'=') {
      insert_line(line);
   }
}

static void ReplaceStylesLine(_str Styles)
{
   top();up();
   int status=search('^styles( |\t)@=','ri@');
   if (!status) {
      _delete_line();
   }

   //5:10pm 7/12/1999
   //Have to be sure that the styles come before the keywords....
   //All the keywords are inserted first, so this is cool.
   top();up();
   status=search('^keywords( |\t)@=','ri@');
   if (status) {
      top();
      int status1=search('^idchars( |\t)@=','ri@');
      int line1=p_line;
      int status2=search('^case-sensitive( |\t)@=','ri@');
      int line2=p_line;
      if (!status1 && !status2) {
         p_line=max(line1,line2);
      }
   }else{
      up();
   }
   if (Styles._varformat()!=VF_EMPTY) {
      insert_line('styles='Styles);
   }
}
static boolean save_last_settings()
{
   if (LAST_LEXER_NAME == NO_LEXER) return false;

   // save all the good stuff in the new keyword table
   new_keyword_table:[LAST_LEXER_NAME].idchars=_ctlstart_idchars.p_text' '_ctlfollow_idchars.p_text;
   new_keyword_table:[LAST_LEXER_NAME].case_sensitive=_ctlcase_sensitive.p_value!=0;
   new_keyword_table:[LAST_LEXER_NAME].filename=CUR_LEXER_FILE;

   // save styles, comments, numbers, language specific
   _str orig_styles=new_keyword_table:[LAST_LEXER_NAME].styles;
   new_keyword_table:[LAST_LEXER_NAME].styles=get_styles();

   // if the styles are not equal, add this one to the mod list
   if (!cc_styles_eq(new_keyword_table:[LAST_LEXER_NAME].styles,orig_styles)) {
      AddLexerToModList();
   }

   // update the comments
   if (cc_update_line_comment() || cc_update_ml_comment()) {
      // they must have failed some validation
      _ctlsstab.p_ActiveTab=CCTAB_COMMENTS;
      return(true);
   }

   // check whether the comments changed
   if (cc_comments_changed()) {
      new_keyword_table:[LAST_LEXER_NAME].comments=CUR_COMMENT_ARRAY;
      AddLexerToModList();
   }

   // finally, update the tags, keywords
   cc_update_tags(false);
   STRARRAYPTR keyword_list = GetLastTypeKeywordList();
   if (keyword_list != null) {
      _ctlkw_list.make_keyword_list(*keyword_list);
   }

   return(false);
}
int _ctlok.lbutton_up()
{
   if (_cc_form_apply()) {
      p_active_form._delete_window(0);
      return(0);
   }

   return (1);
}

_ctlnew_name.lbutton_up()
{
   _str first_word='';
   _str firstExisting='';
   _str name=show('-modal _textbox_form',
             'Enter New Keywords',
             0, //Flags
             '',//Width
             '',//Help item
             '',//Buttons and captions
             '',//retrieve name
             'New Keywords:' //prompt
             );
   if (name!='') {
      int wid=p_window_id;p_window_id=_control _ctlkw_list;
      _lbdeselect_all();
      AddLexerToModList();
      //say('mod11');

      boolean GetFirst=false;
      if (_ctlpp_keywords.p_value) {
         firstExisting=_lbget_text();
         if (firstExisting=='') {
            GetFirst=true;
         }
      }
      name=_param1;
      _str CopyOfName=name;
      first_word=clex_parse_word(CopyOfName);
      if (GetFirst) {
         firstExisting=first_word;
      }
      boolean GaveErrorMessage=false;
      for (;;) {
         _str word=clex_parse_word(name);
         if (word=='') break;
         if (_ctlpp_keywords.p_value) {
            if (substr(word,1,1)!=substr(firstExisting,1,1)) {
               if (!GaveErrorMessage) {
                  _message_box(nls('All PreProcessor Keywords must begin with the same character'));
               }
               GaveErrorMessage=true;
               continue;
            }
         }
         _str ch=_ctlcase_sensitive.p_value?'e':'';
         if (!_lbsearch(word,ch)) {
            _message_box(nls("%s already exists in the list",word));
         }else{
            _lbadd_item(word);
         }
      }
      _lbsort();
      _lbtop();
      _lbsearch(first_word);
      _lbselect_line();
      p_window_id=wid;
      _ctldelete_name.p_enabled=_ctlkw_list.p_Noflines!=0;
   }
}

//Deletes the section and the header too
static int myini_delete_section(_str filename,_str section_name)
{
   int status=0;
   int ini_view_id=0;
   int view_id=0;
   filename=_ConfigPath():+USER_LEXER_FILENAME;
   if (!pos('\+b( |\t)',filename,1,'ir')) {
      status=_open_temp_view(filename,ini_view_id,view_id,'+d');
   }else{
      status=_open_temp_view(filename,ini_view_id,view_id);
   }
   if (status) return(status);
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(ini_view_id);
   top();up();
   status=_ini_delete_section2(section_name);
   if (!status) {
      top();up();
      status=search('^\['section_name'\]','@ri');
      if (!status) {
         _delete_line();
      }
      _save_config_file();
   }
   activate_window(orig_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(status);
}

static void delete_lexers(_str list)
{
   for (;;) {
      _str cur='';
      parse list with cur ',' list;
      if (cur=='') break;
      _str filename=_FindLexerFile(cur);
      if (filename!='') myini_delete_section(filename,cur);
   }
}

void _ctldelete_lexer.lbutton_up()
{
   _str lexername=_ctllexer_list.p_text;
   if (lexername!='') {
      int result=_message_box(nls("Are you sure that you wish to delete the lexer '%s'",lexername),'',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result!=IDYES) return;
      _ctllexer_list._lbdelete_item();
      _ctllexer_list.p_text=_ctllexer_list._lbget_text();
      if (DELETE_LEXER_LIST=='') {
         DELETE_LEXER_LIST=lexername;
      } else {
         DELETE_LEXER_LIST=DELETE_LEXER_LIST', 'lexername;
      }
      new_keyword_table._deleteel(lexername);
   }
}
_ctlcolors.lbutton_up()
{
   _str word=stranslate(active_keyword_rb().p_caption,'','&');
   word=lowcase(stranslate(word,'',' '));
   switch (word) {
   case 'keywords':
   case 'cskeywords':
      word='keyword';break;
   case 'ppkeywords':
      word='preprocess';break;
   }

   config('_color_form', 'D', word);
}

void _ctlimport.lbutton_up()
{
   typeless result=_OpenDialog('-modal',
               'Select VLX File',
               '*.vlx',
               'VLX Files (*.vlx)',
               OFN_FILEMUSTEXIST,  //OFN_FILEMUSTEXIST can create new file.
               '',
               '',
               '');

   if (result=='') return;
   _str filename = result;
   _str lexers[];
   int status = _ini_get_sections_list(filename, lexers);
   if (status) return;
   result = select_tree(lexers, 
                        null, null, null, null, null, null,
                        "Select lexer definitions to import",
                        SL_COLWIDTH|SL_ALLOWMULTISELECT,
                        "Lexer Name",
                        TREE_BUTTON_SORT
                       );
   if (result == COMMAND_CANCELLED_RC || result == '') {
      return;
   }
   save_last_settings();
   _str last_lexer_name = '';
   while (result != '') {
      int loadlexer = IDYES;
      _str lexername = '';
      parse result with lexername "\n" result;
      if (new_keyword_table._indexin(lexername)) {
         loadlexer = _message_box(nls("Replace existing lexer definition '%s'?", lexername),
                                  "Replace",
                                  MB_YESNOCANCEL|MB_ICONQUESTION);
         if (loadlexer == IDCANCEL) break;
      }
      if (loadlexer == IDYES) {
         int lexer_view_id;
         status = _ini_get_section(filename,
                                   lexername,
                                   lexer_view_id);
         if (!status) {
            int orig_wid = p_window_id;
            LoadLexer(lexer_view_id, new_keyword_table:[lexername]);
            _delete_temp_view(lexer_view_id);
            _ctllexer_list._lbadd_item_no_dupe(lexername, '', LBADD_SORT);
            p_window_id = orig_wid;

            _str temp:[];
            if (MODIFIED_LEXER_HASHTAB._varformat() == VF_HASHTAB) {
               temp = MODIFIED_LEXER_HASHTAB;
            }
            temp:[lexername] = 1;
            MODIFIED_LEXER_HASHTAB = temp;
            last_lexer_name = lexername;
         }
      }
   }
   if (last_lexer_name != '') {
      LAST_LEXER_NAME = NO_LEXER;
      _ctllexer_list.p_text = last_lexer_name;
   }
}

//defeventtab _cc_styles_form;
//#define STYLES_LEXER_NAME _ctlhex_intelasm.p_user
#define OTHER_STYLES_TABLE _ctlhex_c.p_user

static void ShutOffControls(_str ControlList)
{
   for (;;) {
      typeless wid;
      parse ControlList with wid ControlList;
      if (wid=='') break;
      if (p_window_id!=wid) wid.p_value=0;
   }
}

_ctldqbsml.lbutton_up()
{
   if (p_value) {
      _str sqlist=(_control _ctlsqmultiline)' '(_control _ctlsqbsml)' '(_control _ctlsqterminate);
      _str dqlist=(_control _ctldqmultiline)' '(_control _ctldqbsml)' '(_control _ctldqterminate);
      if (pos('_ctldq',p_name)==1) {
         ShutOffControls(dqlist);
      }else if (pos('_ctlsq',p_name)==1) {
         ShutOffControls(sqlist);
      }
   }
}

void ctlperl.lbutton_up()
{
   cc_prepare_tags_tab();
   if (ctlperl.p_value || ctlother.p_value) {
      ctlhere_document.p_enabled=1;
   }else{
      ctlhere_document.p_enabled=0;
   }
}

static void cc_prepare_styles(_str lexername)
{
   _ctlhex_intelasm.p_value=0;
   _ctlhex_c.p_value=0;
   _ctlhex_basic.p_value=0;
   _ctlhex_motorolaasm.p_value=0;
   ctlnohex.p_value=0;
   ctlzqhex.p_value=0;
   ctlrexxhex.p_value=0;
   _ctlbquote.p_value=0;
   _ctldqatsign.p_value=0;
   _ctldqd.p_value=0;
   _ctldqbs.p_value=0;
   _ctldqchar.p_value=0;
   _ctldqbsml.p_value=0;
   _ctldqmultiline.p_value=0;
   _ctldqterminate.p_value=0;
   _ctlsqd.p_value=0;
   _ctlsqbs.p_value=0;
   _ctlsqchar.p_value=0;
   _ctlsqbsml.p_value=0;
   _ctlsqmultiline.p_value=0;
   _ctlsqterminate.p_value=0;
   _ctloct_intelasm_o.p_value=0;
   _ctloct_intelasm_q.p_value=0;
   _ctloct_intelasm_b.p_value=0;
   _ctloct_basic.p_value=0;
   _ctlbinb.p_value=0;
   _ctlzerooct.p_value=0;
   _ctllinenums.p_value=0;
   _ctlpound_base.p_value=0;
   _ctlint_underscores.p_value=0;
   _ctlno_numbers.p_value=0;
   ctlidparenfunction.p_value=0;
   ctlidstartnum.p_value=0;
   ctlpackageimport.p_value=0;
   ctlppanywhere.p_value=0;
   ctlhtml.p_value=0;
   ctlxml.p_value=0;
   ctlbs_escape_chars.p_value=0;
   ctlhere_document.p_value=0;
   ctlperl.p_value=0;
   ctlpython.p_value=0;
   ctltcl.p_value=0;
   ctlruby.p_value=0;
   ctldlang.p_value=0;
   ctllua.p_value=0;
   ctlcobol.p_value=0;
   ctlos390asm.p_value=0;
   ctljcl.p_value=0;
   ctlprogress.p_value=0;
   ctlcics.p_value=0;
   ctlmodel204.p_value=0;
   ctlefloat.p_value=0;
   ctldfloat.p_value=0;
   ctlnoexponent.p_value=0;
   ctlverilog.p_value=0;
   ctlother.p_value=0;
   ctljavadoc.p_value=0;
   ctlxmldoc.p_value=0;
   ctldoxygen.p_value=0;
   ctleof.p_value=0;
   ctlcpp.p_value=0;
   ctltriplequote.p_value=0;

   int orig_view_id=p_window_id;
   //p_active_form.p_caption='Styles for 'lexername;
   _str OtherStyleTable[];
   if (new_keyword_table:[lexername].styles._varformat()!=VF_EMPTY) {
      _str line=new_keyword_table:[lexername].styles;
      for (;;) {
         _str cur='';
         parse line with cur line;
         if (cur=='') break;
         cur=lowcase(cur);
         if (cur=='hexh') {
            _ctlhex_intelasm.p_value=1;
         }else if (cur=='xhex') {
            _ctlhex_c.p_value=1;
         }else if (cur=='amphhex') {
            _ctlhex_basic.p_value=1;
         }else if (cur=='dollarhex') {
            _ctlhex_motorolaasm.p_value=1;
         }else if (cur=='nohex') {
            ctlnohex.p_value=1;
         }else if (cur=='zqhex') {
            ctlzqhex.p_value=1;
         }else if (cur=='rexxhex') {
            ctlrexxhex.p_value=1;
         }else if (cur=='bquote') {
            _ctlbquote.p_value=1;
         }else if (cur=='dqdoubles') {
            _ctldqd.p_value=1;
         }else if (cur=='dqatsign') {
            _ctldqatsign.p_value=1;
         }else if (cur=='dqbackslash') {
            _ctldqbs.p_value=1;
         }else if (cur=='dqlen1') {
            _ctldqchar.p_value=1;
         }else if (cur=='dqbackslashml') {
            _ctldqbsml.p_value=1;
         }else if (cur=='dqmultiline') {
            _ctldqmultiline.p_value=1;
         }else if (cur=='dqterminate') {
            _ctldqterminate.p_value=1;
         }else if (cur=='sqdoubles') {
            _ctlsqd.p_value=1;
         }else if (cur=='sqbackslash') {
            _ctlsqbs.p_value=1;
         }else if (cur=='sqlen1') {
            _ctlsqchar.p_value=1;
         }else if (cur=='sqbackslashml') {
            _ctlsqbsml.p_value=1;
         }else if (cur=='sqmultiline') {
            _ctlsqmultiline.p_value=1;
         }else if (cur=='sqterminate') {
            _ctlsqterminate.p_value=1;
         }else if (cur=='octo') {
            _ctloct_intelasm_o.p_value=1;
         }else if (cur=='octq') {
            _ctloct_intelasm_q.p_value=1;
         }else if (cur=='octb') {
            _ctloct_intelasm_b.p_value=1;
         }else if (cur=='ampooct') {
            _ctloct_basic.p_value=1;
         }else if (cur=='zerooct') {
            _ctlzerooct.p_value=1;
         }else if (cur=='binb') {
            _ctlbinb.p_value=1;
         }else if (cur=='linenum') {
            _ctllinenums.p_value=1;
         }else if (cur=='poundbase') {
            _ctlpound_base.p_value=1;
         }else if (cur=='underlineint') {
            _ctlint_underscores.p_value=1;
         }else if (cur=='nonumbers') {
            _ctlno_numbers.p_value=1;
         }else if (cur=='idparenfunction') {
            //2:06pm 6/5/1997
            //Adding support for the new keywords that Clark added
            //packageimport idparenfunction
            ctlidparenfunction.p_value=1;
         }else if (cur=='idstartnum') {
            ctlidstartnum.p_value=1;
         }else if (cur=='packageimport') {
            ctlpackageimport.p_value=1;
         }else if (cur=='ppkeywordsanywhere') {
            ctlppanywhere.p_value=1;
         }else if (cur=='html') {
            ctlhtml.p_value=1;
         }else if (cur=='xml') {
            ctlxml.p_value=1;
         }else if (cur=='backslashescapechars') {
            ctlbs_escape_chars.p_value=1;
         }else if (cur=='eof') {
            ctleof.p_value=1;
         }else if (cur=='cpp') {
            ctlcpp.p_value=1;
         }else if (cur=='heredocument') {
            ctlhere_document.p_value=1;
         }else if (cur=='perl') {
            ctlperl.p_value=1;
         }else if (cur=='python') {
            ctlpython.p_value=1;
         }else if (cur=='tcl') {
            ctltcl.p_value=1;
         }else if (cur=='ruby') {
            ctlruby.p_value=1;
         }else if (cur=='lua') {
            ctllua.p_value=1;
         }else if (cur=='dlang') {
            ctldlang.p_value=1;
         }else if (cur=='cobol') {
            ctlcobol.p_value=1;
         }else if (cur=='os390asm') {
            ctlos390asm.p_value=1;
         }else if (cur=='jcl') {
            ctljcl.p_value=1;
         }else if (cur=='dqtilde' || cur=='sqtilde' || cur=='dqtildeml' || cur=='sqtildeml') {
            ctlprogress.p_value=1;
         }else if (cur=='cics') {
            ctlcics.p_value=1;
         }else if (cur=='model204') {
            ctlmodel204.p_value=1;
         }/*else{
            ctlother.p_value=1;
         }*/else if (cur=='noexponent') {
            ctlnoexponent.p_value=1;
         }else if (cur=='efloat') {
            ctlefloat.p_value=1;
         }else if (cur=='dfloat') {
            ctldfloat.p_value=1;
         }else if (cur=='verilog') {
            ctlverilog.p_value=1;
         }else if (cur=='javadoc') {
            ctljavadoc.p_value=1;
         }else if (cur=='xmldoc') {
            ctlxmldoc.p_value=1;
         }else if (cur=='doxygen') {
            ctldoxygen.p_value=1;
         }else if (cur=='tqmultiline') {
            ctltriplequote.p_value=1;
         }else{
            OtherStyleTable[OtherStyleTable._length()]=cur;
         }
      }
      if (!ctlperl.p_value &&
          !ctlpython.p_value &&
          !ctltcl.p_value &&
          !ctlruby.p_value &&
          !ctllua.p_value &&
          !ctldlang.p_value &&
          !ctlhtml.p_value &&
          !ctlxml.p_value &&
          !ctlcics.p_value &&
          !ctlmodel204.p_value &&
          !ctlos390asm.p_value &&
          !ctlcobol.p_value &&
          !ctljcl.p_value &&
          !ctlprogress.p_value &&
          !ctlverilog.p_value) {
         ctlother.p_value=1;
      }
   }else{
      //Taking out this message because there is no styles information if the user
      //is starting a new lexer
      _message_box(nls("No styles information loaded."));
   }
   //p_window_id=orig_view_id;
   _ctldqbsml.call_event(_ctldqbsml,LBUTTON_UP);
   _ctldqmultiline.call_event(_ctldqmultiline,LBUTTON_UP);
   _ctlsqbsml.call_event(_ctlsqbsml,LBUTTON_UP);
   _ctlsqmultiline.call_event(_ctlsqmultiline,LBUTTON_UP);
   OTHER_STYLES_TABLE=OtherStyleTable;
}

_ctldqd.lbutton_up()
{
   _str dqnames=' _ctldqd _ctldqbs _ctldqchar ';
   _str sqnames=' _ctlsqd _ctlsqbs _ctlsqchar ';
   if (pos(' 'p_name' ',dqnames)) {
      if (p_name=='_ctldqd') {
         _ctldqbs.p_value=_ctldqchar.p_value=0;
      }else if (p_name=='_ctldqbs') {
         _ctldqd.p_value=_ctldqchar.p_value=0;
      }else if (p_name=='_ctldqchar') {
         _ctldqd.p_value=_ctldqbs.p_value=0;
      }
   }else if (pos(' 'p_name' ',sqnames)) {
      if (p_name=='_ctlsqd') {
         _ctlsqbs.p_value=_ctlsqchar.p_value=0;
      }else if (p_name=='_ctlsqbs') {
         _ctlsqd.p_value=_ctlsqchar.p_value=0;
      }else if (p_name=='_ctlsqchar') {
         _ctlsqd.p_value=_ctlsqbs.p_value=0;
      }
   }
}
static boolean cc_styles_eq(_str style1, _str style2)
{
   _str style_name='';
   _str sa1[]; sa1._makeempty();
   while (style1!='') {
      parse style1 with style_name style1;
      sa1[sa1._length()]=style_name;
   }
   _str sa2[]; sa2._makeempty();
   while (style2!='') {
      parse style2 with style_name style2;
      sa2[sa2._length()]=style_name;
   }
   if (sa1._length()!=sa2._length()) {
      return(0);
   }
   sa1._sort();
   sa2._sort();
   int i,n=sa1._length();
   for (i=0; i<n; ++i) {
      if (!strieq(sa1[i],sa2[i])) {
         return(0);
      }
   }
   return(1);
}
static _str get_styles()
{
   _str str='';
   if (_ctllinenums.p_value && _ctllinenums.p_enabled) {
      add_to_str(str,'linenum');
   }
   if (_ctlpound_base.p_value && _ctlpound_base.p_enabled) {
      add_to_str(str,'poundbase');
   }
   if (_ctlint_underscores.p_value && _ctlint_underscores.p_enabled) {
      add_to_str(str,'underlineint');
   }
   if (_ctlhex_c.p_value && _ctlhex_c.p_enabled) {
      add_to_str(str,'xhex');
   }
   if (_ctlhex_intelasm.p_value && _ctlhex_intelasm.p_enabled) {
      add_to_str(str,'hexh');
   }
   if (ctlnohex.p_value && ctlnohex.p_enabled) {
      add_to_str(str,'nohex');
   }
   if (ctlzqhex.p_value && ctlzqhex.p_enabled) {
      add_to_str(str,'zqhex');
   }
   if (ctlrexxhex.p_value && ctlzqhex.p_enabled) {
      add_to_str(str,'rexxhex');
   }
   if (ctlnoexponent.p_value && ctlnoexponent.p_enabled) {
      add_to_str(str,'noexponent');
   }
   if (ctldfloat.p_value && ctldfloat.p_enabled) {
      add_to_str(str,'dfloat');
   }
   if (ctlefloat.p_value && ctlefloat.p_enabled) {
      add_to_str(str,'efloat');
   }
   if (_ctlhex_motorolaasm.p_value && _ctlhex_motorolaasm.p_enabled) {
      add_to_str(str,'dollarhex');
   }
   if (_ctlhex_basic.p_value && _ctlhex_basic.p_enabled) {
      add_to_str(str,'amphhex');
   }
   if (_ctloct_intelasm_o.p_value && _ctloct_intelasm_o.p_enabled) {
      add_to_str(str,'octo');
   }
   if (_ctloct_intelasm_q.p_value && _ctloct_intelasm_q.p_enabled) {
      add_to_str(str,'octq');
   }
   if (_ctloct_intelasm_b.p_value && _ctloct_intelasm_b.p_enabled) {
      add_to_str(str,'octb');
   }
   if (_ctloct_basic.p_value && _ctloct_basic.p_enabled) {
      add_to_str(str,'ampooct');
   }
   if (_ctlzerooct.p_value && _ctlzerooct.p_enabled) {
      add_to_str(str,'zerooct');
   }
   if (_ctlbinb.p_value && _ctlbinb.p_enabled) {
      add_to_str(str,'binb');
   }
   if (_ctlbquote.p_value && _ctlbquote.p_enabled) {
      add_to_str(str,'bquote');
   }
   if (_ctldqatsign.p_value && _ctldqatsign.p_enabled) {
      add_to_str(str,'dqatsign');
   }
   if (_ctldqd.p_value && _ctldqd.p_enabled) {
      add_to_str(str,'dqdoubles');
   }
   if (_ctldqbs.p_value && _ctldqbs.p_enabled) {
      add_to_str(str,'dqbackslash');
   }
   if (_ctldqchar.p_value && _ctldqchar.p_enabled) {
      add_to_str(str,'dqlen1');
   }
   if (_ctlno_numbers.p_value && _ctlno_numbers.p_enabled) {
      add_to_str(str,'nonumbers');
   }
   if (_ctldqbsml.p_value && _ctldqbsml.p_enabled) {
      add_to_str(str,'dqbackslashml');
   }
   if (_ctldqmultiline.p_value && _ctldqmultiline.p_enabled) {
      add_to_str(str,'dqmultiline');
   }
   if (_ctldqterminate.p_value && _ctldqterminate.p_enabled) {
      add_to_str(str,'dqterminate');
   }
   if (_ctlsqd.p_value && _ctlsqd.p_enabled) {
      add_to_str(str,'sqdoubles');
   }
   if (_ctlsqbs.p_value && _ctlsqbs.p_enabled) {
      add_to_str(str,'sqbackslash');
   }
   if (_ctlsqchar.p_value && _ctlsqchar.p_enabled) {
      add_to_str(str,'sqlen1');
   }
   if (_ctlsqbsml.p_value && _ctlsqbsml.p_enabled) {
      add_to_str(str,'sqbackslashml');
   }
   if (_ctlsqmultiline.p_value && _ctlsqmultiline.p_enabled) {
      add_to_str(str,'sqmultiline');
   }
   if (_ctlsqterminate.p_value && _ctlsqterminate.p_enabled) {
      add_to_str(str,'sqterminate');
   }
   if (ctlidparenfunction.p_value && ctlidparenfunction.p_enabled) {
      add_to_str(str,'idparenfunction');
   }
   if (ctlidstartnum.p_value && ctlidstartnum.p_enabled) {
      add_to_str(str,'idstartnum');
   }
   if (ctlpackageimport.p_value && ctlpackageimport.p_enabled) {
      add_to_str(str,'packageimport');
   }
   if (ctlppanywhere.p_value && ctlppanywhere.p_enabled) {
      add_to_str(str,'ppkeywordsanywhere');
   }
   if (ctlhtml.p_value && ctlhtml.p_enabled) {
      add_to_str(str,'html');
   }
   if (ctlxml.p_value && ctlxml.p_enabled) {
      add_to_str(str,'xml');
   }
   if (ctlbs_escape_chars.p_value) {
      add_to_str(str,'backslashescapechars');
   }
   if (ctleof.p_value) {
      add_to_str(str,'eof');
   }
   if (ctlcpp.p_value) {
      add_to_str(str,'cpp');
   }
   if (ctlhere_document.p_value && ctlhere_document.p_enabled) {
      add_to_str(str,'heredocument');
   }
   if (ctlperl.p_value) {
      add_to_str(str,'perl');
   }else if (ctlpython.p_value) {
      add_to_str(str,'python');
   }else if (ctltcl.p_value) {
      add_to_str(str,'tcl');
   }else if (ctlruby.p_value) {
      add_to_str(str,'ruby');
   }else if (ctllua.p_value) {
      add_to_str(str,'lua');
   }else if (ctldlang.p_value) {
      add_to_str(str,'dlang');
   }else if (ctlcobol.p_value) {
      add_to_str(str,'cobol');
   }else if (ctlos390asm.p_value && ctlos390asm.p_enabled) {
      add_to_str(str,'os390asm');
   }else if (ctljcl.p_value && ctljcl.p_enabled) {
      add_to_str(str,'jcl');
   }else if (ctlprogress.p_value && ctlprogress.p_enabled) {
      add_to_str(str,'dqtilde');
      add_to_str(str,'sqtilde');
      add_to_str(str,'dqtildeml');
      add_to_str(str,'sqtildeml');
   }else if (ctlcics.p_value && ctlcics.p_enabled) {
      add_to_str(str,'cics');
   }else if (ctlmodel204.p_value && ctlmodel204.p_enabled) {
      add_to_str(str,'model204');
   }else if (ctlverilog.p_value) {
      add_to_str(str,'verilog');
   }else if (ctlother.p_value) {
   }
   if (ctljavadoc.p_value) {
      add_to_str(str,'javadoc');
   }
   if (ctlxmldoc.p_value) {
      add_to_str(str,'xmldoc');
   }
   if (ctldoxygen.p_value) {
      add_to_str(str,'doxygen');
   }
   if (ctltriplequote.p_value) {
      add_to_str(str,'tqmultiline');
   }
   _str OtherStyles[];
   OtherStyles=OTHER_STYLES_TABLE;
   int i;
   for (i=0;i<OtherStyles._length();++i) {
      add_to_str(str,OtherStyles[i]);
   }
   return(str);
}

static int ArrayComp(var one,var two)
{
   if (one._length()!=two._length()) {
      return(0);
   }
   int i;
   for (i=0;i<one._length();++i) {
      if (one[i]!=two[i]) {
         return(0);
      }
   }
   return(1);
}

static boolean ArrayCompare(typeless one,typeless two)
{
   boolean notequal=(one._length()!=two._length());
   if (notequal) {
      //say('ellen='one._length()' el2len='two._length());
      return(notequal);
   }
   int i;
   for (i=0;i<one._length();++i) {
      if (one[i]!=two[i]) {
         //say('value i='i' vf1='one[i]._varformat()' vf2='two[i]._varformat());
         //say('value i='i' vf1='one[i]' vf2='two[i]);
         return(true);
      }
   }
   return(false);
}

static boolean cc_comments_changed()
{
   typeless temp1=OLD_COMMENT_ARRAY;
   typeless temp2=CUR_COMMENT_ARRAY;
   boolean notequal=(temp1._length()!=temp2._length());
   int extent=min(temp1._length(),temp2._length());
   if (!notequal) {
      int i;
      for (i=0;i<extent;++i) {
         notequal=ArrayCompare(temp1[i],temp2[i]);
         if (notequal) {
            //say('i='i);
            break;
         }
      }
   } else {
      //say('t1len='temp1._length()' t2len='temp2._length());
   }
   return(notequal);
}

static _str GetCommentType(COMMENT_TYPE comment)
{
   if (comment.type==COMMENT_MULTILINE) {
      return('MultiLine');
   }
   if (comment.type==COMMENT_SINGLELINE) {
      return('LineComment');
   }
   return('');
}

static void cc_prepare_comments(_str lexername, boolean clear_all=false)
{
   int linenum=-1;
   COMMENT_TYPE temparray[],temp;
   temparray._makeempty();

   // do we need to clear everything out first?
   if (clear_all) {
      OLD_COMMENT_ARRAY=null;
      CUR_COMMENT_ARRAY=null;
      CUR_COMMENT_INDEX=-1;
      CUR_COMMENT_ISNEW=0;
   }

   // we got no lexer
   if (lexername=='') {
      linenum=_ctlkw_list.p_line;
      _ctlkw_list._lbclear();
   }

   // grab the stuff from the new keyword table if available
   if (new_keyword_table:[lexername].comments._varformat()!=VF_EMPTY) {
      temparray=new_keyword_table:[lexername].comments;
   }

   if (CUR_COMMENT_ARRAY._varformat()==VF_ARRAY) {
      temparray=CUR_COMMENT_ARRAY;
   }else{
      temparray=new_keyword_table:[lexername].comments;
      CUR_COMMENT_ARRAY=new_keyword_table:[lexername].comments;
   }

   haveDocumentationComment := false;
   _ctlcomment_list._lbclear();
   int i;
   for (i=0;i<temparray._length();++i) {
      if (temparray[i].startcol&&temparray[i].delim1==''&&temparray[i].delim2=='') {
         _ctlcomment_list._lbadd_item(GetCommentType(temparray[i])"\t"temparray[i].startcol"+\t");
      }else{
         _ctlcomment_list._lbadd_item(GetCommentType(temparray[i])"\t":+temparray[i].delim1:+"\t"temparray[i].delim2);
      }
      if (temparray[i].isDocumentation) {
         haveDocumentationComment = true;
      }
   }
   if (!haveDocumentationComment) {
      ctljavadoc.p_enabled=false;
      ctlxmldoc.p_enabled=false;
      ctldoxygen.p_enabled=false;
   }
   int wid=p_window_id;p_window_id=_ctlcomment_list;
   _col_width(0,1200);
   _col_width(1,500);
   _col_width(2,500);
   _lbtop();
   if (CUR_COMMENT_INDEX>=0) {
      p_line=CUR_COMMENT_INDEX+1;
   } else if (linenum>=0) {
      p_line=linenum;
   } else {
   }
   _lbselect_line();
   p_window_id=wid;
   if (OLD_COMMENT_ARRAY._varformat()!=VF_ARRAY) {
      OLD_COMMENT_ARRAY=temparray;
      //say('set old********************');
      //say('vf='temparray[0].cf_or_l._varformat());
   }
   _ctlnew_ml.p_enabled=(number_ml_comments() < MAX_MLCOMMENTS);
}


static void FindEndOfComment(_str buffer,int &start)
{
   int i=start;
   for (;i<=length(buffer);++i) {
      _str ch=substr(buffer,i,1);
      if (ch=='\') {
         ++i;
         continue;
      }
      if (ch=='"') {
         start=i;
         return;
      }
   }
}

static _str CCProcessEscapeChars(_str string)
{
   _str result='';
   int i=1;
   for (;;) {
      int j=pos('\',string,i);
      if (!j) {
         j=length(string)+1;
         result=result:+substr(string,i,j-i);
         return(result);
      }
      result=result:+substr(string,i,j-i);
      ++j;
      result=result:+substr(string,j,1);
      i=j+1;
   }
}

static boolean CCNeedQuotes(_str string)
{
   return(pos(' ',string) || substr(string,1,1)=='"' || pos('\', string));
}
static _str CCEscapeChars(_str string)
{
   _str temp=string;
   temp=stranslate(temp,'\\','\');
   temp=stranslate(temp,'\"','"');
   return('"'temp'"');
}

static _str MaybeStrip2Quotes(_str string)
{
   if (substr(string,1,1)!='"') return(string);
   string=substr(string,2);
   if (length(string)==1) {
      if (string=='"') return('');
      return(string);
   }
   string=substr(string,1,length(string)-1);
   return(string);
}

/**
 * This function parse a word the same way clex.c does for a MLCOMMENT
 * definition.
 *
 * @param string
 *
 * @return
 */
static _str cc_parse_word(_str &string)
{
   _str word='';
   parse string with word string;
   return(word);
   //return(parse_file(string,false));
}
COMMENT_TYPE _process_comment(_str commentline)
{
   COMMENT_TYPE comment;
   init_comment(comment);

   _str field='';
   _str info='';
   parse commentline with field '=' info;
   field=lowcase(strip(field));
   info=strip(info);
   _str buffer=info;
   _str line='';
   typeless tok='';
   int start=1;
   switch (field) {
   case 'mlcomment':
      line="MultiLine\t";
      comment.type=COMMENT_MULTILINE;
      comment.delim1=cc_parse_word(buffer);
      tok=cc_parse_word(buffer);
      if (isdigit(substr(tok,1,1))) {
            //start_symbol start_col [checfirst|leading] endsymbol [lastchar]
         // Not supported yet
         if (last_char(tok)=='+') {
            //comment.endcol=-1;   not supported yet
            comment.startcol=(int)substr(tok,1,length(tok)-1);
         } else {
            comment.startcol=tok;//col3=tok;
         }
         if (start>=0) {//has to be
            tok=cc_parse_word(buffer);
            switch (lowcase(tok)) {
            case 'checkfirst':
            case 'leading':
               //col4=tok;
               comment.cf_or_l=tok;
               break;
            case 'documentation':
               comment.isDocumentation=true;
               break;
            default:
               //delim2=tok;
               comment.delim2=tok;
               break;
            }
         }
         if (start>=0) {
            tok=cc_parse_word(buffer);
            //if (delim2=='') delim2=tok;
            if (comment.delim2=='') comment.delim2=tok;
         }
         if (start>=0) {
            tok=cc_parse_word(buffer);
            //col5=tok;
            if (lowcase(tok)=='lastchar') {
               comment.lastchar=1;
            }
            if (lowcase(tok)=='documentation') {
               comment.isDocumentation=true;
            }
         }
         //comment.nesting=0;comment.startcol=0;comment.colorname='';comment.idchars='';
      }else{//start_symbol end_symbol [nesting] [followed_by idchars] [colorname]
         comment.delim2=tok;//delim2=tok;
         for (;;) {
            tok=cc_parse_word(buffer);
            if (tok=='') {
               break;
            }
            if (strieq(tok,'NESTING')) {
               comment.nesting=1;
            } else if (pos(' 'tok' ',' KEYWORDCOLOR NUMBERCOLOR STRINGCOLOR COMMENTCOLOR PPKEYWORDCOLOR LINENUMCOLOR SYMBOL1COLOR SYMBOL2COLOR SYMBOL3COLOR SYMBOL4COLOR PUNCTUATIONCOLOR LIBKEYWORDCOLOR OPERATORCOLOR USERKEYWORDCOLOR ',1,'I')) {
               comment.colorname=tok;
            } else if (strieq(tok,'FOLLOWEDBY')) {
               comment.idchars=cc_parse_word(buffer);//get idchars
            } else if (strieq(tok,'DOCUMENTATION')) {
               comment.isDocumentation=true;
            }
         }
      }
      return(comment);
   case 'linecomment':
      comment.type=COMMENT_SINGLELINE;
      line="LineComment\t";
      //say(buffer);
      tok=next_token(buffer,start,start,field);
      if (isdigit(substr(tok,1,1))) {
         // Define the ignore start column

         //say('case1');
         comment.startcol=tok;//scol=tok;
         tok=next_token(buffer,start,start,field);
         switch (tok) {
         case '+':
            comment.repeat=1;//range='+'
            break;
         }
         // Note that histically the JCL and ASM390 lexers had something like
         // "72+ checkfirst" as their line comment.
         // "clex.c" ignores this so we ignore it here too.

         // checkfirst/leading not supported here in C code "clex.c"
         //if (start>=0) {
         //   comment.cf_or_l=next_token(buffer,start,start,field);
         //}
         //line=line"\t"delim"\t"scol"\t"range"\t"ecol"\t"cf_or_l;
         tok=next_token(buffer,start,start,field);
         if (lowcase(tok)=='precededbyblank') {
            comment.precededbyblank=true;
            tok=next_token(buffer,start,start,field);
         }
         if (lowcase(tok)=='documentation') {
            comment.isDocumentation=true;
         }
         if (lowcase(tok)=='continuation') {
            comment.backslashContinuation=true;
         }
      }else{
         //say('case2');
         //say(buffer);
         comment.delim1=tok;
         comment.delim1=MaybeStrip2Quotes(comment.delim1);
         comment.delim1=CCProcessEscapeChars(comment.delim1);
         //say('h1 tok='tok' start='start);
         if (start>=0) {
            tok=next_token(buffer,start,start,field);
            //say('h2 tok='tok);
            if (isinteger(tok)) {
               comment.startcol=tok;//scol=tok;
               if (start>=0) {
                  //oldstart=start;
                  tok=next_token(buffer,start,start,field);
                  switch (tok) {
                  case '+':
                     comment.repeat=1;//range='+'
                     tok=next_token(buffer,start,start,field);
                     break;
                  case '-':
                     //range='-';
                     tok=next_token(buffer,start,start,field);
                     comment.endcol=tok;
                     tok=next_token(buffer,start,start,field);
                     break;
                  }
               }
            }
            if (lowcase(tok)=='precededbyblank') {
               comment.precededbyblank=true;
               tok=next_token(buffer,start,start,field);
            } else if (lowcase(tok)=='checkfirst' ||
                      lowcase(tok)=='leading') {
               comment.cf_or_l=tok;
               tok=next_token(buffer,start,start,field);
            }
            if (lowcase(tok)=='documentation') {
               comment.isDocumentation=true;
            }
            if (lowcase(tok)=='continuation') {
               comment.backslashContinuation=true;
            }
         }
      }
      return(comment);
   default:
      _message_box('Internal error processing color coding entry.  Call SlickEdit');
      stop();
      return(comment);
   }
}

static _str next_token(_str &buffer,int start,int &next,_str type)
{
   if (start<=0) {
      return('');
   }
   _str temp='';
   if (buffer=='') {
      next=-1;
      return("");
   }
   if (start>length(buffer)) {
      next=-1;
      return('');
   }
   _str ch='';
   int i=0;
   int p=0;
   buffer=strip(substr(buffer,start));
   if (start==1) {
      //return everything up to first space, unless it starts with a nubmer
      if (isinteger(substr(buffer,1,1))) {
         for (i=1;i<=length(buffer);++i) {
            ch=substr(buffer,i,1);
            if (isinteger(ch)) {
               temp=temp:+ch;
               if ( (type=='linecomment' && (temp=='+'||temp=='-'))
                    ||temp=='='||temp=='>'||temp=='<!') {
                  next=i+1;
                  return(temp);
               }
            }else{
               break;
            }
         }
         //next=pos('~[ |\t]',buffer,i,'r');
         next=i;
         return(temp);
      }else{
         if (substr(buffer,start,1)=='"') {
            i=start+1;
            FindEndOfComment(buffer,i);
            temp=substr(buffer,start,start+i-1);
            //start=i;
            next=i;
            return(temp);
         }else{
            p=pos(' |\t|$',buffer,start,'r');
            if (p>1) {
               temp=substr(buffer,1,p-1);
            }
            if ( (pos('$',buffer,p,'r')<pos(' |\t',buffer,p,'r')) ||
                 !pos(' |\t',buffer,p,'r')) {
               next=-1;
            }else{
               next=pos('~[ \t$]',buffer,p+1,'r');
            }
            //next=p+1;
            return(temp);
         }
      }
   }
   boolean startint=isinteger(substr(buffer,1,1));
   if (!startint) {
      for (i=1;i<=length(buffer);++i) {
         ch=substr(buffer,i,1);
         p=pos(' |\t',ch,1,'r');
         if (!p) {
            temp=temp:+ch;
            if ( (type=='linecomment' && (temp=='+'||temp=='-') )
                 /*
                   Took out the following b/c Perl uses '=' as a delimiter
                   and anything else was the comment color.
                  */
                 /*||temp=='='*/
                 ||temp=='>'||temp=='<!') {
               next=i+1;
               return(temp);
            }
         }else{
            next=i;
            return(temp);
         }
      }
   }else{
      for (i=1;i<=length(buffer);++i) {
         ch=substr(buffer,i,1);
         if (isinteger(ch)) {
            temp=temp:+ch;
         }else{break;}
      }
      if (i>length(buffer)) {
         next=-1;
      }else{
         next=i;
      }
      return(temp);
   }
   if (i>length(buffer)) {
      next=-1;//culprit
   }else{
      next=i+1;
   }
   return(temp);
}


void _ctlcomment_list.on_change(int reason)
{
   //say('_ctlcomment_list.on_change');
   if (!p_Noflines) {
      _ctl_lc_frame.p_visible=_ctl_lc_frame.p_enabled=false;
      _ctl_ml_frame.p_visible=_ctl_ml_frame.p_enabled=false;
      CUR_COMMENT_INDEX=-1;
      CUR_COMMENT_ISNEW=0;
      return;
   }
   if (reason==CHANGE_SELECTED) {
      if (cc_update_line_comment() || cc_update_ml_comment()) {
         // If there was an error when we tried to switch comments, the
         // current window became that textbox, so we have to switch it
         // back
         p_window_id=_ctlcomment_list;
         _lbdeselect_line();
         p_line=CUR_COMMENT_INDEX+1;
         _lbselect_line();
         return;
      }
      typeless orig_LL_ONCHANGE_RUNNING=LL_ONCHANGE_RUNNING;
      LL_ONCHANGE_RUNNING=1;
      _str line=_ctlcomment_list._lbget_text();
      if (line=='') return;
      _str type='';
      COMMENT_TYPE temp[];
      parse line with type .;
      switch (type) {
      case 'LineComment':
         temp=CUR_COMMENT_ARRAY;
         cc_prepare_line_comment(temp[_ctlcomment_list.p_line-1],
                                 LAST_LEXER_NAME,
                                 _ctlcomment_list.p_line-1);
         break;
      case 'MultiLine':
         temp=CUR_COMMENT_ARRAY;
         cc_prepare_ml_comment(temp[_ctlcomment_list.p_line-1],
                               LAST_LEXER_NAME,
                               _ctlcomment_list.p_line-1);
         break;
      }
      cc_prepare_comments(_ctllexer_list.p_text);
      //if (cc_comments_changed()) {
      //   say('x1 ??already difffert??');
      //}
      CUR_COMMENT_ISNEW=0;
      _ctlstartcol_ml.call_event(CHANGE_OTHER,_ctlstartcol_ml,ON_CHANGE,'w');
      LL_ONCHANGE_RUNNING=orig_LL_ONCHANGE_RUNNING;
      //say('h2');
   }
}

static int number_ml_comments()
{
   int wid=p_window_id;p_window_id=_control _ctlcomment_list;
   int count=0;
   save_pos(auto p);
   top();up();
   while (!down()) {
      _str line='';
      get_line(line);
      _str type='';
      parse substr(line,2) with type "\t" .;
      if (type=='MultiLine') ++count;
   }
   restore_pos(p);
   p_window_id=wid;
   return(count);
}

void _ctlnew_lc.lbutton_up()
{
   if (cc_update_line_comment() || cc_update_ml_comment()) {
      return;
   }
   typeless temp2;
   COMMENT_TYPE temp;
   init_comment(temp);
   temp.type=COMMENT_SINGLELINE;
   //result=show('-modal _cc_comment_l_form',
   //            &temp,
   //            LAST_LEXER_NAME,
   //            _ctlcomment_list.p_Noflines-1);
   //if (!result) {
      temp2=CUR_COMMENT_ARRAY;//Get the comment array
      temp2[_ctlcomment_list.p_Noflines]=temp;//Insert this element
      CUR_COMMENT_ARRAY=temp2;//Replace the array
      //_ctlok.call_event(_ctlok,ON_CREATE);//Refresh the list
   //}
   cc_prepare_line_comment(temp,
                           _ctllexer_list.p_text,
                           _ctlcomment_list.p_Noflines);
   cc_prepare_comments(_ctllexer_list.p_text);
   CUR_COMMENT_ISNEW=1;
}
void _ctlnew_ml.lbutton_up()
{
   if (cc_update_line_comment() || cc_update_ml_comment()) {
      return;
   }
   typeless temp2;
   COMMENT_TYPE temp;
   init_comment(temp);
   temp.type=COMMENT_MULTILINE;
   //result=show('-modal _cc_comment_ml_form',
   //            &temp,
   //            LAST_LEXER_NAME,
   //            _ctlcomment_list.p_Noflines-1);
   //if (!result) {
      temp2=CUR_COMMENT_ARRAY;//Get the comment array
      temp2[_ctlcomment_list.p_Noflines]=temp;//Insert this element
      CUR_COMMENT_ARRAY=temp2;//Replace the array
      //_ctlok.call_event(_ctlok,ON_CREATE);//Refresh the list
   //}
   cc_prepare_ml_comment(temp,
                         _ctllexer_list.p_text,
                         _ctlcomment_list.p_Noflines);
   cc_prepare_comments(_ctllexer_list.p_text);
   CUR_COMMENT_ISNEW=1;
}

_ctlcomment_list.DEL()
{
   if (_ctldelete_comment.p_enabled) {
      _ctldelete_comment.call_event(_ctldelete_comment,LBUTTON_UP,'W');
   }
}
_ctldelete_comment.lbutton_up()
{
   COMMENT_TYPE temp[];
   temp=CUR_COMMENT_ARRAY;
   temp._deleteel(_ctlcomment_list.p_line-1,1);
   CUR_COMMENT_ARRAY=temp;
   _ctlcomment_list._lbdelete_item();
   _ctlcomment_list._lbselect_line();
   _ctl_lc_frame.p_visible=_ctl_lc_frame.p_enabled=false;
   _ctl_ml_frame.p_visible=_ctl_ml_frame.p_enabled=false;
   CUR_COMMENT_INDEX=-1;
   CUR_COMMENT_ISNEW=0;
   _ctlcomment_list.call_event(CHANGE_SELECTED,_ctlcomment_list,on_change,'W');
}

//defeventtab _cc_comment_l_form;
_ctldelim_text.on_change()
{
   boolean val=(length(_ctldelim_text.p_text)==1 && isinteger(_ctlstartcol.p_text));
   //_ctlcheckfirst.p_enabled=val;
   if (_ctldelim_text.p_text!='') {
      ctlpreceded.p_enabled=true;
      ctllinedocs.p_enabled=true;
      ctllinecontinuation.p_enabled=true;
   }else{
      ctlpreceded.p_enabled=false;
      ctllinedocs.p_enabled=false;
      ctllinecontinuation.p_enabled=false;
   }
   if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
      if (!cc_update_line_comment(true,true)) {
         cc_prepare_comments(_ctllexer_list.p_text);
      }
   }
}

void ctlblockdocs.lbutton_up()
{
   if (p_value) {
      ctljavadoc.p_enabled=true;
      ctlxmldoc.p_enabled=true;
      ctldoxygen.p_enabled=true;
   } else if (ctljavadoc.p_enabled) {
      COMMENT_TYPE temparray[] = CUR_COMMENT_ARRAY;
      haveDocumentationComment := false;
      for (i:=0;i<temparray._length();++i) {
         if (temparray[i].isDocumentation) {
            haveDocumentationComment = true;
         }
      }
      if (!haveDocumentationComment) {
         ctljavadoc.p_enabled=false;
         ctlxmldoc.p_enabled=false;
         ctldoxygen.p_enabled=false;
      }
   }
}

void _cc_comment_l_form.on_load()
{
   if (_ctldelim.p_value) {
      _ctldelim_text._set_focus();
      _ctldelim_text._set_sel(1,length(_ctldelim_text.p_text)+1);
   }
}

static void cc_prepare_line_comment(COMMENT_TYPE comment, _str lexername,int commentnum)
{
   _ctl_lc_frame.p_visible=_ctl_lc_frame.p_enabled=true;
   _ctl_ml_frame.p_visible=_ctl_ml_frame.p_enabled=false;
   //if (arg(1)._varformat()!=VF_PTR) {//Hit Shift-Space Bar
   //   p_active_form._delete_window(0);
   //   _mdi.show('-modal _cc_form');
   //   return;
   //}
   _ctlmessage_label.p_visible=0;
   //COMMENT_TYPE *comment;
   CUR_COMMENT_INDEX=commentnum;
   //p_active_form.p_caption=lexername" Line Comment "commentnum;

   // initialize common fields with defaults
   _ctlendcol.p_enabled=0;
   _ctlstartcol.p_text='';
   _ctlendcol.p_text='';
   ctlpreceded.p_value=comment.precededbyblank? 1:0;
   ctllinedocs.p_value=comment.isDocumentation? 1:0;
   ctllinecontinuation.p_value=comment.backslashContinuation? 1:0;
   _ctldelim_text.p_text=comment.delim1;
   _ctlcheckfirst.p_value=0;
   _ctlleading.p_value=0;
   _ctlrest.p_value=0;

   if (comment.startcol && comment.delim1=='') {
      _ctlaftercol.p_text=comment.startcol;
      _ctlaftercol_rb.p_value=1;

   }else{

      //Order is important here
      _ctlrest.p_value=comment.repeat;
      if (comment.startcol) {
         _ctlstartcol.p_text=comment.startcol;
         if (comment.endcol) {
            _ctlendcol.p_text=comment.endcol;
         }
      }
      _ctldelim.p_value=1;
      _ctlaftercol.p_text='';
      _ctlcheckfirst.p_value=0;
      _ctlleading.p_value=0;
      switch (lowcase(comment.cf_or_l)) {
      case 'checkfirst':
         _ctlcheckfirst.p_value=1;
         break;
      case 'leading':
         _ctlleading.p_value=1;
         break;
      }
   }
   _ctlstartcol.call_event(CHANGE_OTHER,_ctlstartcol,ON_CHANGE,"W");
   //set_preceded_limitations();
}

static void cc_prepare_delim_options(boolean enable)
{
   _ctldelim_text.p_enabled=enable;
   _ctlleading.p_enabled=enable;
   _ctlcheckfirst.p_enabled=enable;
   _ctlendcol.p_enabled=enable;
   ctlpreceded.p_enabled=enable;
   ctllinedocs.p_enabled=enable;
   ctllinecontinuation.p_enabled=enable;
   _ctlstartcol.p_enabled=enable;
   _ctlendcol.p_enabled=enable;
   _ctlrest.p_enabled=enable;
}

void _ctlaftercol_rb.lbutton_up()
{
   switch (p_name) {
   case '_ctldelim':
      //_delim_options_frame.disable_all_controls(1);
      cc_prepare_delim_options(true);
      _ctlstartcol.call_event(CHANGE_OTHER,_ctlstartcol,ON_CHANGE,"W");
      _ctlaftercol.p_enabled=0;
      p_window_id=_ctldelim_text;
      if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
         _ctldelim_text._set_focus();
         _ctldelim_text._set_sel(1,length(_ctldelim_text.p_text)+1);

         _ctlaftercol.p_text='';
         if (!cc_update_line_comment(true,true)) {
            cc_prepare_comments(_ctllexer_list.p_text);
         }

      }
      break;
   case '_ctlaftercol_rb':
      //_delim_options_frame.disable_all_controls();
      cc_prepare_delim_options(false);
      _ctlaftercol.p_enabled=1;
      _ctlstartcol.p_text='';
      _ctlendcol.p_text='';
      if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
         _ctlaftercol._set_focus();
         _ctldelim_text.p_text='';
         if (!cc_update_line_comment(true,true)) {
            cc_prepare_comments(_ctllexer_list.p_text);
         }
      }
      break;
   }
}
void _ctlaftercol.on_change()
{
   if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
      if (!cc_update_line_comment(true)) {
         cc_prepare_comments(LAST_LEXER_NAME);
      }
   }
}

static void update_message_label()
{
   if (_ctlstartcol.p_text=='') {
      _ctlmessage_label.p_visible=0;
   }else{
      _ctlmessage_label.p_visible=1;
      if (!isinteger(_ctlstartcol.p_text) ||
         (_ctlendcol.p_text!='' && !isinteger(_ctlendcol.p_text))) {
         _ctlmessage_label.p_caption="Value must be a positive integer";
         _ctlmessage_label.p_forecolor=0x0000FF;//Red
      }else if (isinteger(_ctlstartcol.p_text) && isinteger(_ctlendcol.p_text) &&
                _ctlendcol.p_text<=_ctlstartcol.p_text) {
         _ctlmessage_label.p_caption="Startcol must occur after endcol";
         _ctlmessage_label.p_forecolor=0x0000FF;//Red
      }else if (isinteger(_ctlstartcol.p_text) && _ctlstartcol.p_text <1) {
         _ctlmessage_label.p_caption="Value must be a positive integer";
         _ctlmessage_label.p_forecolor=0x0000FF;//Red
      }else{
         _ctlmessage_label.p_visible=1;
         _ctlmessage_label.p_forecolor=0x000000;//Black
         if (_ctlendcol.p_text=='') {
            if (_ctlrest.p_enabled && _ctlrest.p_value) {
               _ctlmessage_label.p_caption="Delimiter functions anywhere after column "_ctlstartcol.p_text;
            }else{
               _ctlmessage_label.p_caption="Delimiter functions only when in column "_ctlstartcol.p_text;
            }
         }else{
            if (_ctlrest.p_enabled && _ctlrest.p_value) {
               _ctlmessage_label.p_caption="Delimiter functions anywhere after column "_ctlstartcol.p_text;
            }else{
               _ctlmessage_label.p_caption="Delimiter functions between columns "_ctlstartcol.p_text" and "_ctlendcol.p_text;
            }
         }
      }
   }
}

_ctlrest.lbutton_up()
{
#if 0
   if (p_name=='_ctlcheckfirst') {
      _ctlrest.p_value=0;
   }else if (p_name=='_ctlrest') {
      _ctlcheckfirst.p_value=0;
   }
#endif
   _ctlstartcol.call_event(CHANGE_OTHER,_ctlstartcol,ON_CHANGE,"W");
}

_ctlstartcol.on_change()
{
   if (_ctlendcol.p_enabled && _ctlendcol.p_text!='') {
      _ctlrest.p_enabled=false;
   }else{
      _ctlrest.p_enabled=(_ctldelim.p_value || _ctlstartcol.p_text!='')? true:false;
   }
   if (p_window_id!=_ctlendcol) {
      //If it just changed, I don't think that we would need to disable it
      _ctlendcol.p_enabled=(_ctlstartcol.p_text!='' && (!_ctlrest.p_value&&_ctlrest.p_enabled));
   }
   //val=(length(_ctldelim_text.p_text)==1 && isinteger(_ctlstartcol.p_text))
   //_ctlcheckfirst.p_enabled=val;
   update_message_label();
}

/**
 * Initializes a COMMENT_TYPE to all the default values.
 * 
 * @param COMMENT_TYPE& comment 
 */
static void init_comment(COMMENT_TYPE &comment)
{
   comment.type=0;
   comment.delim1='';
   comment.cf_or_l='';
   comment.startcol=0;

   comment.delim2='';
   comment.colorname='';
   comment.lastchar=0;
   comment.nesting=0;
   comment.idchars='';

   comment.endcol=0;
   comment.repeat=0;
   comment.precededbyblank=false;
   comment.isDocumentation=false;
   comment.backslashContinuation=false;
}

_ctlcheckfirst.lbutton_up()
{
   //if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
      if (p_name=='_ctlcheckfirst') {
         _ctlleading.p_value=0;
         ctlpreceded.p_value=0;
      }else if (p_name=='_ctlleading') {
         _ctlcheckfirst.p_value=0;
         ctlpreceded.p_value=0;
      } else if (p_name=='ctlpreceded') {
         _ctlcheckfirst.p_value=0;
         _ctlleading.p_value=0;
      }
   //}
}
_ctlcheckfirst_ml.lbutton_up()
{
   //if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
      if (p_name=='_ctlcheckfirst_ml') {
         _ctlleading_ml.p_value=0;
      }else if (p_name=='_ctlleading_ml') {
         _ctlcheckfirst_ml.p_value=0;
      }
   //}
}

/**
 * Goes through and validates changes made to the lexer.  If
 * anything needs to be fixed, we return the tab number with the
 * problem.  Otherwise, we return -1.
 *
 * @return int          tab number that failed validation
 */
int validate_lexer()
{
   if (validate_line_comment()) return CCTAB_COMMENTS;

   if (validate_ml_comment()) return CCTAB_COMMENTS;

   return -1;
}

boolean validate_line_comment(boolean quiet = false, boolean allow_blank_delim = false)
{
   // make sure a line comment is selected in the list
   if (!_ctl_lc_frame.p_enabled || CUR_COMMENT_INDEX<0) return 0;

   if (_ctlaftercol_rb.p_value) {
      // set the start column
      if (!isinteger(strip(_ctlaftercol.p_text)) || _ctlaftercol.p_text<=0) {
         // this ain't valid
         if (!quiet) {
            _ctlaftercol._text_box_error("Column numbers must be a positive integer value.");
         }
         return 1;
      }
   }else{
      if (_ctldelim_text.p_text=='' && !allow_blank_delim) {
         // we don't allow blank delimiters here
         if (!quiet) {
            //_StackDump();
            _message_box(nls("You must specify a delimiter."));
            return 1;
         }
      }

      // setup start and end column
      if (_ctlstartcol.p_enabled && _ctlstartcol.p_text!='') {
         if (!isinteger(_ctlstartcol.p_text) || _ctlstartcol.p_text<=0) {

            if (!quiet) {
               _ctlstartcol._text_box_error("Column numbers must be a positive integer value.");
            }
            return 1;

         }
         if (_ctlendcol.p_text!='' && (!isinteger(_ctlendcol.p_text) || _ctlendcol.p_text<=0)) {
            if (!quiet) {
               _ctlendcol._text_box_error("Column numbers must be a positive integer value.");
            }
            return 1;
         }
      }
   }

   // everything validated okay!
   return 0;

}

static int cc_update_line_comment(boolean quiet=false,boolean allow_blank_delim=false)
{
   if (!_ctl_lc_frame.p_enabled || CUR_COMMENT_INDEX<0) {
      return(0);
   }

   // make sure all the required info is in there
   if (validate_line_comment(quiet, allow_blank_delim)) return 1;

   // create a new single line comment type
   COMMENT_TYPE temp;
   init_comment(temp);
   temp.type=COMMENT_SINGLELINE;

   // only if preceded by blank
   if (ctlpreceded.p_enabled && ctlpreceded.p_value) {
      temp.precededbyblank=true;
   }

   // Is this a structured documentation comment?
   if (ctllinedocs.p_enabled && ctllinedocs.p_value) {
      temp.isDocumentation=true;
   }

   // Can this line comment be continued to the next line with backslash
   if (ctllinecontinuation.p_enabled && ctllinecontinuation.p_value) {
      temp.backslashContinuation=true;
   }

   // setup after column versus using delimted text
   if (_ctlaftercol_rb.p_value) {
      // set the start column
      temp.startcol=(int)_ctlaftercol.p_text;
      temp.repeat=1;
   }else{
      temp.delim1=_ctldelim_text.p_text;

      if (_ctlleading.p_value) {       // only if first non-blank character in line
         temp.cf_or_l='leading';
      }
      if (_ctlcheckfirst.p_value && _ctlcheckfirst.p_enabled) {      // check columns first
         temp.cf_or_l='checkfirst';
      }
      if (_ctlrest.p_enabled && _ctlrest.p_value) {                  // end column is end of line
         temp.repeat=1;
      }

      // setup start and end column
      if (_ctlstartcol.p_enabled && _ctlstartcol.p_text!='') {
         // all these should be fine - we checked them in the validation step
         temp.startcol=(int)_ctlstartcol.p_text;
         if (_ctlendcol.p_text!='') {
            temp.endcol=(int)_ctlendcol.p_text;
         }
      }
   }

   COMMENT_TYPE temp2[];
   temp2=CUR_COMMENT_ARRAY;//Get the comment array
   temp2[CUR_COMMENT_INDEX]=temp;//Insert this element
   CUR_COMMENT_ARRAY=temp2;//Replace the array

   //p_active_form._delete_window(0);//This was a 1, don't know why Dan 4:49pm 4/8/1996
   return(0);
}

//defeventtab _cc_comment_ml_form;
void _ctltag_list.on_change(int reason)
{
   if (IGNORE_TAG_LIST_ON_CHANGE) return;

   if (reason==CHANGE_SELECTED) {
      cc_update_tags();
      cc_prepare_attrs(_ctltag_list._lbget_seltext());
      CUR_TAG_NAME=_ctltag_list._lbget_seltext();
   }
}
void _ctlattr_list.on_change(int reason)
{
   if (IGNORE_TAG_LIST_ON_CHANGE) return;

   if (reason==CHANGE_SELECTED) {
      cc_update_tags();
      cc_prepare_values(
         _ctltag_list._lbget_seltext(),
         _ctlattr_list._lbget_seltext());
      CUR_ATTR_NAME=_ctlattr_list._lbget_seltext();
   }
}
_ctlnew_tag.lbutton_up()
{
   _str first_word='';
   _str word='';
   _str name=show('-modal _textbox_form',
             'Enter New Keywords',
             0, //Flags
             '',//Width
             '',//Help item
             '',//Buttons and captions
             '',//retrieve
             'New Keywords:' //prompt
             );
   if (name!='') {
      //cc_update_tag();
      AddLexerToModList();
      //say('mod15');
      name=_param1;
      int wid=p_window_id;p_window_id=_control _ctltag_list;
      parse name with first_word .;
      for (;;) {
         parse name with word name;
         if (word=='') break;
         _lbadd_item(word);
      }
      _lbsort();
      _lbtop();
      _lbsearch(first_word);
      _lbselect_line();
      p_window_id=wid;
      _ctltag_list.call_event(CHANGE_SELECTED,_ctltag_list,ON_CHANGE,'W');
      //cc_prepare_attrs(_ctltag_list._lbget_seltext());
      //CUR_TAG_NAME=_ctltag_list._lbget_seltext();
      _ctlnew_attr.p_enabled=_ctltag_list.p_Noflines!=0;
#if 0
      _ctldelete_attr.p_enabled=_ctlattr_list.p_Noflines!=0;
      _ctldelete_tag.p_enabled=_ctltag_list.p_Noflines!=0;
      _ctlnew_value.p_enabled=_ctlattr_list.p_Noflines!=0;
      _ctldelete_value.p_enabled=_ctlvalue_list.p_Noflines!=0;
#endif
   }
}
_ctltag_list.DEL()
{
   if (_ctldelete_tag.p_enabled) {
      _ctldelete_tag.call_event(_ctldelete_tag,LBUTTON_UP,'W');
   }
}
_ctldelete_tag.lbutton_up()
{
   mou_hour_glass(1);
   if (_ctltag_list.p_Nofselected==1) {
      _ctltag_list._lbdelete_item();
      _ctltag_list._lbselect_line();
   } else {
      boolean ff=true;
      p_window_id=_control _ctltag_list;
      while (!_lbfind_selected(ff)) {
         _lbdelete_item();
         _lbup();
         ff=false;
      }
      _lbselect_line();
   }
   AddLexerToModList();
   //say('mod16');
   _ctlnew_attr.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctldelete_attr.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctlnew_value.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctldelete_value.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctldelete_tag.p_enabled=_ctltag_list.p_Noflines!=0;
   cc_prepare_attrs(_ctltag_list._lbget_seltext());
   CUR_TAG_NAME=_ctltag_list._lbget_seltext();
   mou_hour_glass(0);
}

_ctlnew_attr.lbutton_up()
{
   _str word='';
   _str first_word='';
   _str keyword=CUR_TAG_NAME;
   _str name=show('-modal _textbox_form',
             'Enter New Attributes for 'keyword,
             0, //Flags
             '',//Width
             '',//Help item
             '',//Buttons and captions
             '',//retrieve
             'New Attributes:' //prompt
             );
   if (name!='') {
      cc_update_tags();
      AddLexerToModList();
      //say('mod17');
      name=_param1;
      int wid=p_window_id;p_window_id=_control _ctlattr_list;
      parse name with first_word .;
      for (;;) {
         parse name with word name;
         if (word=='') break;
         _lbadd_item(word);
      }
      _lbsort();
      _lbtop();
      _lbsearch(first_word);
      _lbselect_line();
      p_window_id=wid;
      _ctlnew_value.p_enabled=_ctlattr_list.p_Noflines!=0;
      _ctldelete_value.p_enabled=_ctlattr_list.p_Noflines!=0;
      _ctldelete_attr.p_enabled=_ctlattr_list.p_Noflines!=0;
      CUR_ATTR_NAME=_ctlattr_list._lbget_seltext();
      CUR_ATTR_VALUES='';
      cc_prepare_values(
         _ctltag_list._lbget_seltext(),
         _ctlattr_list._lbget_seltext());
   }
}
_ctlattr_list.DEL()
{
   if (_ctldelete_attr.p_enabled) {
      _ctldelete_attr.call_event(_ctldelete_attr,LBUTTON_UP,'W');
   }
}
_ctldelete_attr.lbutton_up()
{
   if (CUR_ATTR_VALUES=='') {
      CUR_ATTR_VALUES=CUR_ATTR_NAME'('CUR_TAG_NAME')';
   }
   if (ctlalltags.p_value && pos('(',CUR_ATTR_VALUES)) {
      CUR_ATTR_VALUES=CUR_ATTR_NAME;
   } else if (!ctlalltags.p_value && !pos('(',CUR_ATTR_VALUES)) {
      CUR_ATTR_VALUES=CUR_ATTR_NAME'('CUR_TAG_NAME')';
   }
   new_keyword_table:[_ctllexer_list.p_text].comment_values._deleteel(CUR_ATTR_VALUES);
   mou_hour_glass(1);
   if (_ctlattr_list.p_Nofselected==1) {
      _ctlattr_list._lbdelete_item();
      _ctlattr_list._lbselect_line();
   } else {
      boolean ff=true;
      p_window_id=_control _ctlattr_list;
      while (!_lbfind_selected(ff)) {
         _lbdelete_item();
         _lbup();
         ff=false;
      }
      _lbselect_line();
   }
   AddLexerToModList();
   //say('mod18');
   mou_hour_glass(0);

   if (_ctlattr_list.p_Noflines) {
      cc_prepare_values(
         _ctltag_list._lbget_seltext(),
         _ctlattr_list._lbget_seltext());
   } else {
      _ctlvalue_list._lbclear();

   }
   CUR_ATTR_NAME=_ctlattr_list._lbget_seltext();

   _ctlnew_value.p_enabled=_ctlattr_list.p_Noflines!=0;
   _ctldelete_value.p_enabled=_ctlattr_list.p_Noflines!=0;
   _ctldelete_attr.p_enabled=_ctlattr_list.p_Noflines!=0;

}
_ctlnew_value.lbutton_up()
{
   _str first_word='';
   _str word='';
   _str keyword=CUR_ATTR_NAME;
   _str name=show('-modal _textbox_form',
             'Enter New Values for 'keyword,
             0, //Flags
             '',//Width
             '',//Help item
             '',//Buttons and captions
             '',//retrieve
             'New attribute values:' //prompt
             );
   if (name!='') {
      AddLexerToModList();
      //say('mod19');
      name=_param1;
      int wid=p_window_id;p_window_id=_control _ctlvalue_list;
      parse name with first_word .;
      for (;;) {
         parse name with word name;
         if (word=='') break;
         _lbadd_item(word);
      }
      _lbsort();
      _lbtop();
      _lbsearch(first_word);
      _lbselect_line();
      p_window_id=wid;
   }
   _ctldelete_value.p_enabled=_ctlvalue_list.p_Noflines!=0;
}
_ctlvalue_list.DEL()
{
   if (_ctldelete_value.p_enabled) {
      _ctldelete_value.call_event(_ctldelete_value,LBUTTON_UP,'W');
   }
}
_ctldelete_value.lbutton_up()
{
   mou_hour_glass(1);
   boolean ff=true;
   p_window_id=_control _ctlvalue_list;
   while (!_lbfind_selected(ff)) {
      _lbdelete_item();
      _lbup();
      ff=false;
   }
   _lbselect_line();
   AddLexerToModList();
   //say('mod20');
   _ctldelete_value.p_enabled=_ctlvalue_list.p_Noflines!=0;
   mou_hour_glass(0);
}


static void cc_prepare_ml_comment(COMMENT_TYPE comment,_str lexername,int commentnum)
{
   _ctl_lc_frame.p_visible=_ctl_lc_frame.p_enabled=false;
   _ctl_ml_frame.p_visible=_ctl_ml_frame.p_enabled=true;

   CUR_COMMENT_INDEX=commentnum;
   //p_active_form.p_caption=lexername' Multi-Line Comment 'commentnum;
   //_ctladvanced._dmless();
   int wid=p_window_id;
   p_window_id=_control _ctlcolor_name;
   if (!p_Noflines) {
      _lbadd_item('KeywordColor');
      _lbadd_item('NumberColor');
      _lbadd_item('StringColor');
      _lbadd_item('CommentColor');
      _lbadd_item('PPKeywordColor');
      _lbadd_item('LineNumColor');
      _lbadd_item('PunctuationColor');
      _lbadd_item('LibKeywordColor');
      _lbadd_item('OperatorColor');
      _lbadd_item('UserKeywordColor');
      _lbtop();
   }
   p_window_id=_ctlcolor_name;
   p_text=_lbget_text();
   p_window_id=wid;

   //Setup dialog box
   _ctldelim1.p_text=comment.delim1;
   _ctldelim2.p_text=comment.delim2;
   if (comment.startcol) {
      _ctlstartcol_ml.p_text=comment.startcol;
   }
   //_ctlidchars.p_text=comment.idchars;

   _str color=comment.colorname;
   if (color=='') color='CommentColor';
   _ctlcolor_name._lbfind_and_select_item(color,'i');

   _ctlnesting.p_value=comment.nesting;
   _ctlcheckfirst_ml.p_value=(int)(comment.cf_or_l=='checkfirst');
   _ctlleading_ml.p_value=(int)(comment.cf_or_l=='leading');
   _ctllastchar.p_value=comment.lastchar;
   ctlblockdocs.p_value=comment.isDocumentation? 1:0;
   _ctlstartcol_ml.call_event(CHANGE_OTHER,_ctlstartcol,ON_CHANGE,"W");
}
static void cc_prepare_tags(_str lexername)
{
   CUR_TAG_NAME='';CUR_ATTR_NAME='';CUR_ATTR_VALUES='';
   _ctltag_list._lbclear();
   _ctlattr_list._lbclear();
   _ctlvalue_list._lbclear();
   if (!ctlhtml.p_value && !ctlxml.p_value) {
      return;
   }
   // activate the tags tab so it can be refreshed
   int orig_active=_ctlsstab.p_ActiveTab;
   _ctlsstab.p_ActiveTab=5; /* Tags */
   _ctlsstab.p_ActiveEnabled=true;
   _ctlsstab.p_ActiveTab=orig_active;

   _str cur='';
   _str keywords=new_keyword_table:[lexername].comment_keywords;
   if (keywords!=null && keywords!='') {
      for (;;) {
         parse keywords with cur keywords;
         if (cur=='') break;
         _ctltag_list._lbadd_item(strip(cur));
      }
      _ctltag_list._lbtop();
      _ctltag_list._lbselect_line();
   }
   _ctltag_list._lbsort();
   _ctldelete_tag.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctlnew_attr.p_enabled=_ctltag_list.p_Noflines!=0;
   _ctldelete_attr.p_enabled=false;
   _ctlnew_value.p_enabled=false;
   _ctldelete_value.p_enabled=false;
   if (_ctltag_list.p_Noflines>0) {
      cc_prepare_attrs(_ctltag_list._lbget_seltext());
   }
   CUR_TAG_NAME=_ctltag_list._lbget_text();
   CUR_ATTR_VALUES='';
}
static void cc_prepare_attrs(_str tagname)
{
   _str attributes:[];
   attributes=new_keyword_table:[_ctllexer_list.p_text].comment_attributes;

   _ctlattr_list._lbclear();
   _str keywords='';
   if (attributes._indexin(tagname)) {
      keywords=attributes:[tagname];
   } else if (attributes._indexin(upcase(tagname))) {
      keywords=attributes:[upcase(tagname)];
   }

   if (keywords!=null && keywords!='') {
      for (;;) {
         _str cur='';
         parse keywords with cur keywords;
         if (cur=='') break;
         _ctlattr_list._lbadd_item(strip(cur));
      }
      _ctlattr_list._lbtop();
      _ctlattr_list._lbselect_line();
   }
   _ctlattr_list._lbsort();
   _ctlvalue_list._lbclear();
   _ctldelete_attr.p_enabled=_ctlattr_list.p_Noflines!=0;
   _ctlnew_value.p_enabled=_ctlattr_list.p_Noflines!=0;
   _ctldelete_value.p_enabled=false;
   if (_ctlattr_list.p_Noflines>0) {
      cc_prepare_values(tagname,_ctlattr_list._lbget_seltext());
   }
   CUR_ATTR_NAME=_ctlattr_list._lbget_text();
   CUR_ATTR_VALUES='';
}
static void cc_prepare_values(_str tagname, _str attrname)
{
   _str attrvalues:[];
   attrvalues=new_keyword_table:[_ctllexer_list.p_text].comment_values;

   _ctlvalue_list._lbclear();
   _str keywords='';
   //say('**********************************************************');
   // IF we have attributes for this specific tag
   if (attrvalues._indexin(attrname'('tagname')')) {
      keywords=attrvalues:[attrname'('tagname')'];
      CUR_ATTR_VALUES=attrname'('tagname')';
      ctlalltags.p_value=0;
   } else if (attrvalues._indexin(upcase(attrname'('tagname')'))) {
      keywords=attrvalues:[upcase(attrname'('tagname')')];
      CUR_ATTR_VALUES=upcase(attrname'('tagname')');
      ctlalltags.p_value=0;
   } else if (attrvalues._indexin(attrname)) {
      keywords=attrvalues:[attrname];
      CUR_ATTR_VALUES=attrname;
      ctlalltags.p_value=1;
   } else if (attrvalues._indexin(upcase(attrname))) {
      keywords=attrvalues:[upcase(attrname)];
      CUR_ATTR_VALUES=upcase(attrname);
      ctlalltags.p_value=1;
   } else {
      CUR_ATTR_VALUES='';
      ctlalltags.p_value=0;
   }
   if (keywords!=null && keywords!='') {
      for (;;) {
         _str cur='';
         parse keywords with cur keywords;
         if (cur=='') break;
         _ctlvalue_list._lbadd_item(strip(cur));
      }
      _ctlvalue_list._lbtop();
      _ctlvalue_list._lbselect_line();
   }
   _ctlvalue_list._lbsort();
   _ctldelete_value.p_enabled=_ctlvalue_list.p_Noflines!=0;
}

boolean validate_ml_comment(boolean quiet=false)
{
   // make sure we are looking at an ml comment
   if (!_ctl_ml_frame.p_enabled || CUR_COMMENT_INDEX<0) return(0);

   //Do a whole bunch of error checking
   if (_ctldelim1.p_text=='') {
      if (!quiet) {
         _ctldelim1._text_box_error("You must specifiy two comment delimiters for a multi-line comment.");
      }
      return(1);
   }
   if (_ctldelim2.p_text=='') {
      if (!quiet) {
         _ctldelim2._text_box_error("You must specifiy two comment delimiters for a multi-line comment.");
      }
      return(1);
   }

   _nocheck _control _ctlstart_idchars,_ctlfollow_idchars;
   //int pwid=p_active_form.p_parent.p_active_form;
   _str start_idchars=_ctlstart_idchars.p_text;
   _str folow_idchars=_ctlfollow_idchars.p_text;

   if (pos('['start_idchars']['start_idchars:+folow_idchars']@',_ctldelim1.p_text,1,'r')==1 &&
       strip(_ctldelim1.p_text)!='$') {
      if (!quiet) {
         _ctldelim1._text_box_error("Currently, a comment delimiter may not be a valid identifer.");
      }
      return(1);
   }
   if (pos('['start_idchars']['start_idchars:+folow_idchars']@',_ctldelim2.p_text,1,'r')==1 &&
       (_ctldelim2.p_text)!='$') {
      if (!quiet) {
         _ctldelim2._text_box_error("Currently, a comment delimiter may not be a valid identifer.");
      }
      return(1);
   }
   if (_ctlstartcol_ml.p_text!='' && !isinteger(_ctlstartcol_ml.p_text)) {
      if (!quiet) {
         _ctlstartcol_ml._text_box_error("Start Column must be an intger.");
      }
      return(1);
   }

   // everything is fine, just fine
   return 0;
}

static int cc_update_ml_comment(boolean quiet=false)
{
   if (!_ctl_ml_frame.p_enabled || CUR_COMMENT_INDEX<0) {
      return(0);
   }

   // do some validation on these fields
   if (validate_ml_comment(quiet)) return 1;

   COMMENT_TYPE temp;
   init_comment(temp);
   temp.type=COMMENT_MULTILINE;

// _nocheck _control _ctlstart_idchars,_ctlfollow_idchars;
   //int pwid=p_active_form.p_parent.p_active_form;
// _str start_idchars=_ctlstart_idchars.p_text;
// _str folow_idchars=_ctlfollow_idchars.p_text;

   //Finish error checking

   temp.delim1=_ctldelim1.p_text;
   temp.delim2=_ctldelim2.p_text;
   temp.startcol=(_ctlstartcol_ml.p_text=='')?0:(int)_ctlstartcol_ml.p_text;
   if (_ctlcolor_name.p_text!='CommentColor') {
      temp.colorname=_ctlcolor_name.p_text;
   }else{
      temp.colorname='';
   }
   //temp.idchars=_ctlidchars.p_text;
   if (_ctlcheckfirst_ml.p_enabled && _ctlcheckfirst_ml.p_value) {
      temp.cf_or_l='checkfirst';
   }else if (_ctlleading_ml.p_enabled && _ctlleading_ml.p_value) {
      temp.cf_or_l='leading';
   }
   temp.lastchar=(int)(_ctllastchar.p_enabled && _ctllastchar.p_value);
   temp.nesting=(int)(_ctlnesting.p_enabled && _ctlnesting.p_value);
   temp.isDocumentation=(ctlblockdocs.p_enabled && ctlblockdocs.p_value);

   COMMENT_TYPE temp2[];
   temp2=CUR_COMMENT_ARRAY;//Get the comment array
   temp2[CUR_COMMENT_INDEX]=temp;//Insert this element
   CUR_COMMENT_ARRAY=temp2;//Replace the array

   return(0);
}

static void cc_update_tags(boolean useCurrent = true)
{
   // ignore any tag list change events - causes recursion problems because
   // we are iterating through the list boxes
   IGNORE_TAG_LIST_ON_CHANGE = 1;

   // whether we are updating the current lexer or saving 
   // the last lexer before showing a new one
   lexer := _ctllexer_list.p_text;
   if (!useCurrent) {
      lexer = LAST_LEXER_NAME;
   }

   // first update the list of tags
   int wid=p_window_id;
   p_window_id=_ctltag_list;
   save_pos(auto p);
   _lbtop();
   _lbup();
   _str keyword='';
   _str keyword_list='';
   while (!_lbdown()) {
      keyword=_lbget_text();
      if (keyword_list=='') {
         keyword_list=keyword;
      }else{
         keyword_list=keyword_list' 'keyword;
      }
   }
   restore_pos(p);
   _lbselect_line();

   p_window_id=wid;
   _str orig_tags='';
   if (new_keyword_table:[lexer].comment_keywords!=null) {
      orig_tags=new_keyword_table:[lexer].comment_keywords;
   }
   if (keyword_list != orig_tags) {
      new_keyword_table:[lexer].comment_keywords=keyword_list;
   }

   // update the list of attributes for selected tag
   if (CUR_TAG_NAME!=null && CUR_TAG_NAME!='') {
      wid=p_window_id;
      p_window_id=_ctlattr_list;
      save_pos(p);
      _lbtop();_lbup();
      keyword_list='';
      while (!_lbdown()) {
         keyword=_lbget_text();
         if (keyword_list=='') {
            keyword_list=keyword;
         }else{
            keyword_list=keyword_list' 'keyword;
         }
      }
      restore_pos(p);_lbselect_line();
      p_window_id=wid;
      _str orig_attrs='';
      if (new_keyword_table:[lexer].comment_attributes._indexin(CUR_TAG_NAME)) {
         orig_attrs=new_keyword_table:[lexer].comment_attributes:[CUR_TAG_NAME];
      }
      //say('na='keyword_list);say('oa='orig_attrs);
      if (keyword_list != orig_attrs) {
         new_keyword_table:[lexer].comment_attributes:[CUR_TAG_NAME]=keyword_list;
      }
   }

   // update the list of values for the attributes
   if (CUR_ATTR_NAME!=null && CUR_ATTR_NAME!='') {
      if (CUR_ATTR_VALUES=='') {
         CUR_ATTR_VALUES=CUR_ATTR_NAME'('CUR_TAG_NAME')';
      }
      if (ctlalltags.p_value && pos('(',CUR_ATTR_VALUES)) {
         CUR_ATTR_VALUES=CUR_ATTR_NAME;
      } else if (!ctlalltags.p_value && !pos('(',CUR_ATTR_VALUES)) {
         CUR_ATTR_VALUES=CUR_ATTR_NAME'('CUR_TAG_NAME')';
      }
      wid=p_window_id;
      p_window_id=_ctlvalue_list;
      save_pos(p);
      _lbtop();_lbup();
      keyword_list='';
      while (!_lbdown()) {
         keyword=_lbget_text();
         if (keyword_list=='') {
            keyword_list=keyword;
         }else{
            keyword_list=keyword_list' 'keyword;
         }
      }
      restore_pos(p);_lbselect_line();
      p_window_id=wid;
      _str orig_vals='';
      if (new_keyword_table:[lexer].comment_values._indexin(CUR_ATTR_VALUES)) {
         orig_vals=new_keyword_table:[lexer].comment_values:[CUR_ATTR_VALUES];
      }
      if (keyword_list != orig_vals) {
         new_keyword_table:[lexer].comment_values:[CUR_ATTR_VALUES]=keyword_list;

         _str attrvalues:[];
         attrvalues=new_keyword_table:[lexer].comment_values;
      }
      if (ctlalltags.p_value) {
         new_keyword_table:[lexer].comment_values._deleteel(CUR_ATTR_NAME'('CUR_TAG_NAME')');
      }
   }

   IGNORE_TAG_LIST_ON_CHANGE = 0;
}


_ctldelim1.on_change()
{

   if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
      if (!cc_update_ml_comment(true)) {
         cc_prepare_comments(_ctllexer_list.p_text);
      }
   }
}

_ctldelim2.on_change()
{
   if (p_active_form.p_visible && !LL_ONCHANGE_RUNNING) {
      if (!cc_update_ml_comment(true)) {
         cc_prepare_comments(_ctllexer_list.p_text);
      }
   }
}


_ctlstartcol_ml.on_change()
{
   if (isinteger(_ctlstartcol_ml.p_text)||_ctlstartcol_ml.p_text!='') {
      _ctlcheckfirst_ml.p_enabled=1;
      _ctlleading_ml.p_enabled=1;
      _ctllastchar.p_enabled=1;
      _ctlnesting.p_enabled=0;
      ctlblockdocs.p_enabled=0;
      //_ctlidchars.p_enabled=0;
      _ctlcolor_name.p_enabled=0;
      _ctlcolor_label.p_enabled=0;
      //_ctlidchars_label.p_enabled=0;
   }else{
      _ctlcheckfirst_ml.p_enabled=0;
      _ctlleading_ml.p_enabled=0;
      _ctllastchar.p_enabled=0;
      _ctlnesting.p_enabled=1;
      ctlblockdocs.p_enabled=1;
      //_ctlidchars.p_enabled=1;
      _ctlcolor_name.p_enabled=1;
      _ctlcolor_label.p_enabled=1;
      //_ctlidchars_label.p_enabled=1;
   }
}

_str vlx_proc_search(_str &proc_name,boolean find_first)
{
   return ini_proc_search(proc_name,find_first);
}

_str ini_proc_search(_str &proc_name,boolean find_first)
{
   if ( proc_name:=='' ) {
      proc_name='[^\]]#';
   } else {
      _str rest='';
      proc_name=_escape_re_chars(proc_name);
      proc_name=stranslate(proc_name,'?','\[');
      proc_name=stranslate(proc_name,'?','\]');
      parse proc_name with proc_name '(' rest;
   }
   int status=0;
   _str search_key='^[\[]'proc_name'[\]]';
   if ( find_first ) {
      status=search(search_key,'@riXc');
   } else {
      status=repeat_search();
   }
   if (!status) {
      _str line='';
      get_line(line);
      parse line with '[' proc_name ']';
      proc_name=stranslate(proc_name,'[','(');
      proc_name=stranslate(proc_name,']',')');
      proc_name=proc_name'(label)';
   }
   return(status);
}

_str rc_proc_search(_str &proc_name,boolean find_first)
{
   return '';
}

/**
 * Update destination lexer file with contents 
 * in source file.  By default, the dest_lexer_filename refers 
 * to the user.vlx in the user configuration directory. 
 * 
 * @param filename
 * @param dest_lexer_filename
 */
void import_lexer_file(_str filename, _str dest_lexer_filename = '')
{
   int orig_view_id = p_window_id;
   _str lexernames[];
   int status = _ini_get_sections_list(filename, lexernames);
   if (status) return;

   if (dest_lexer_filename == '') {
      dest_lexer_filename = _ConfigPath():+USER_LEXER_FILENAME;
   }
   int i, len = lexernames._length();
   for (i = 0; i < len; ++i) {
      int lexer_view_id;
      status = _ini_get_section(filename, lexernames[i], lexer_view_id);
      if (status) break;
      status = _ini_put_section(dest_lexer_filename, lexernames[i], lexer_view_id);
      if (status) break;
   }
   p_window_id = orig_view_id;
   if (file_exists(dest_lexer_filename)) {
      status = _clex_load(dest_lexer_filename);
      if (status) {
         _message_box(nls("Could not load file '%s'\n\n%s", dest_lexer_filename, get_message(status)));
      }
   }
}

defeventtab _create_new_lexer_form;

void ctlok.on_create()
{
   // add the lexers to the combo box
   ctllexer_list._lbclear();
   filenamelist := LEXER_FILE_LIST;
   for (;;) {
      parse filenamelist with auto filename (PATHSEP) filenamelist;
      if (filename=='') break;
      ctllexer_list._ini_list_sections(filename);
   }
   ctllexer_list._lbsort();
   ctllexer_list._lbtop();
   ctllexer_list._lbselect_line();

   ctlcopy_cb.call_event(ctlcopy_cb, LBUTTON_UP);
}

void ctlcopy_cb.lbutton_up()
{
   ctllexer_list.p_enabled = (ctlcopy_cb.p_value != 0);
}

void ctlok.lbutton_up()
{
   if (verifyLexerName(ctllexer_name.p_text)) return;

   _param1 = ctllexer_name.p_text;

   if (ctlcopy_cb.p_value) {
      _param2 = ctllexer_list.p_text;
   } else {
      _param2 = '';
   }


   p_active_form._delete_window(IDOK);
}
