////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48480 $
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
#import "adaptiveformatting.e"
#import "annotations.e"
#import "beautifier.e"
#import "bookmark.e"
#import "cutil.e"
#import "debug.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "savecfg.e"
#import "seldisp.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

vsc_format(int,_str,int,_str,int,int,_str,int);
vsd_format(int,_str,int,_str,int,int,_str,int);
vsjava_format(int,_str,int,_str,int,int,_str,int);
vsjavascript_format(int,_str,int,_str,int,int,_str,int);
vscsharp_format(int,_str,int,_str,int,int,_str,int);
vsslickc_format(int,_str,int,_str,int,int,_str,int);

struct scheme_s {
   int options:[];
};

#define CFDEBUG_WINDOW   0
#define CFDEBUG_FILE     0

#define CFDEBUGFLAG_WINDOW 0x1000
#define CFDEBUGFLAG_FILE   0x2000

#define CFFLAG_REMEMBER_SEEKPOS 0x8000

#define CF_NONE_SCHEME_NAME    "(None)"

// Used by c_beautify()
static int _options:[];

// Used by form
static int  _form_options:[];
static int  _orig_form_options:[];   // Save this for the Reset button
static _str _form_lang;
static _str _orig_lang;
static scheme_s _schemes:[];         // Read-only schemes
static scheme_s _user_schemes:[];    // User schemes
static _str _cur_scheme;             // Last scheme used
static _str _orig_scheme;            // Save this for the Reset button

static int _suspend_modify;
#define CHANGING_SCHEMES _ctl_scheme_save.p_user

#define CFCOMMENT_STATE_SPECIFIC 0
#define CFCOMMENT_STATE_ABSOLUTE 1
#define CFCOMMENT_STATE_RELATIVE 2

#define CFPADCONDITION_STATE_INSERT   0
#define CFPADCONDITION_STATE_REMOVE   1
#define CFPADCONDITION_STATE_NOCHANGE 2

//static int _mycheck_tabs(int :[]);
//static int _get_scheme(scheme_s (&):[],_str);
//static int _format(int :[],_str,_str,_str,_str,int,_str);

static boolean gUserIniInitDone;

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
_str _ext2modename2(_str ext,int &setup_index)
{
   lang := _Ext2LangId(ext);
   setup_index = find_index("def-language-"lang,MISC_TYPE);
   _str modename=_LangId2Modename(lang);
   if (modename=='C') {
      modename='C/C++';
   }
   return(modename);
}
/**
 * Runs the language specific dialog box which is used to set beautifier
 * options and beautify code.  When we have beautifiers for other languages,
 * this command will pick the beautifier dialog box based on the current buffers
 * extension or prompt the user to pick a beautifier.
 *
 * @see c_beautify
 * @see c_beautify_selection
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command gui_beautify() name_info(','VSARG2_EDITORCTL)
{
   _str lang='';
   _str orig_lang='';
   _str caption='';
   int index=0;
   int dummy=0;
   
   if (new_beautifier_supported_language(p_LangId)) {
      return beautifier_edit_current_profile();
   }
      
   if ( !_isEditorCtl() ) {
      lang=show('-modal _beautify_extension_form');
      if ( lang=='' ) {
         // User cancelled
         return('');
      }

      orig_lang=lang;
      if (lang == 'docbook') {
         lang = 'xml';
      }
      index=find_index("_"lang"_beautify_form",oi2type(OI_FORM));
      if ( !index ) {
         if ( BeautifyCheckSupport(lang) ) {
            _message_box("Can't find form: ":+"_"lang"_beautify_form");
            return('');
         }
         // Double check the new language
         index=find_index("_"lang"_beautify_form",oi2type(OI_FORM));
         if ( !index ) {
            _message_box("Can't find form: ":+"_"lang"_beautify_form");
            return('');
         }
      }
      caption=_LangId2Modename(orig_lang);
      if ( caption!="" ) caption=caption" Beautifier";
      show("-modal "index,lang,orig_lang,"",caption);
      return('');
   }
   _ExitScroll();
   lang=p_LangId;
   orig_lang=lang;
   if (lang == 'docbook') {
      lang = 'xml';
   }
   index=find_index("_"lang"_beautify_form",oi2type(OI_FORM));
   int lastModified=p_LastModified;
   if ( !index ) {
      if ( BeautifyCheckSupport(lang) ) {
         lang=show('-modal _beautify_extension_form');
         if ( lang=='' ) {
            // User cancelled
            return('');
         }

         if (new_beautifier_supported_language(lang)) {
            origLang := p_LangId;
            p_LangId = lang;
            beautifier_edit_current_profile();
            p_LangId := origLang;
            return '';
         }

         // User has specified that they want this buffer treated as if it
         // had this language
         orig_lang=lang;
      }

      // Double check the new language
      if ( BeautifyCheckSupport(lang) ) {
         _message_box("Can't find form: ":+"_"lang"_beautify_form","Error",MB_OK|MB_ICONEXCLAMATION);
         return('');
      }
      index=find_index("_"lang"_beautify_form",oi2type(OI_FORM));
      if ( !index ) {
         _message_box("Can't find form: ":+"_"lang"_beautify_form");
         return('');
      }

      caption=_LangId2Modename(orig_lang);
      if ( caption!="" ) caption=caption" Beautifier";
      show("-modal "index,lang,orig_lang,"",caption);
      if ( lastModified!=p_LastModified ) adaptive_format_reset_buffers();
      return('');
   }
   // Need to pass in orig_lang because this could be an editor control
   caption=_LangId2Modename(orig_lang);
   if ( caption!="" ) caption=caption" Beautifier";
   show("-modal "index,lang,orig_lang,"",caption);
   if ( lastModified!=p_LastModified ) adaptive_format_reset_buffers();
}

_OnUpdate_beautify(CMDUI cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   // DJB (05-04-2006) -- Since the beautify command will prompt
   //                  -- for what language specific beautifier
   //                  -- to use if beautify is not supported, we
   //                  -- can allow this to be enabled for fundamental
   //                  -- mode.  This allows people to edit large XML
   //                  -- file in fundamental mode and still beautify
   //                  -- if the want to, but still prevents confusion
   //                  -- for users editing Basic and thinking they
   //                  -- might be able to beautify because the menu
   //                  -- option is enabled.
   //
   _str lang=target_wid.p_LangId;
   if ( lang!="" && lang!="fundamental" && 
        (BeautifyCheckSupport(lang) && !new_beautifier_supported_language(target_wid.p_LangId)) ) 
      return(MF_GRAYED);

   return(MF_ENABLED);
}

_OnUpdate_gui_beautify(CMDUI cmdui,int target_wid,_str command)
{
   return _OnUpdate_beautify(cmdui,target_wid,command);
}
_command int beautify(boolean quiet=false) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _ExitScroll();
   _str msg='';
   _str lang=p_LangId;

   if (new_beautifier_supported_language(lang)) {
      beautify_current_buffer();
      return 0;
   }

   if ( BeautifyCheckSupport(lang) ) {
      if ( !quiet ) {
         msg="Beautifying not supported for ":+p_mode_name;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return 1;
   }
   int index=find_index(lang'_beautify',COMMAND_TYPE);
   if ( !index ) {
      if ( !quiet ) {
         msg="Cannot find command: "lang"_beautify";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return 1;
   }

   // save bookmark, breakpoint, and annotation information
   _SaveBookmarksInFile(auto bmSaves);
   _SaveBreakpointsInFile(auto bpSaves);
   _SaveAnnotationsInFile(auto annoSaves);

   int status = 0;
   if ( _LanguageInheritsFrom('c',lang) ) {
      status=call_index(0,0,0,quiet,index);
   } else if ( _LanguageInheritsFrom('html',lang) ) {
      status=call_index(0,0,"",0,quiet,index);
   } else if ( _LanguageInheritsFrom('ada',lang) ) {
      status=call_index(0,0,"",0,quiet,index);
   } else {
      // This just means that we do not know the position of the quiet option
      // for this beautifier function, so it will not be quiet.
      status=call_index(index);
   }

   // restore bookmarks, breakpoints, and annotation locations
   _RestoreBookmarksInFile(bmSaves);
   _RestoreBreakpointsInFile(bpSaves);
   _RestoreAnnotationsInFile(annoSaves);

   // Finally update adaptive formatting and we are done
   adaptive_format_reset_buffers();
   return status;
}

_OnUpdate_beautify_selection(CMDUI cmdui,int target_wid,_str command)
{
   return(_OnUpdate_beautify(cmdui,target_wid,command));
}
_command int beautify_selection(...) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _ExitScroll();
   _str lang=p_LangId;
   _str msg='';

   int seltest = _get_selinfo(auto sc, auto ec, auto bi);

   if (seltest != 0) {
      return beautify();
   }

   if (new_beautifier_supported_language(lang)) {
      new_beautify_selection();
      return 0;
   }

   if (lang == 'fundamental') {
      return gui_beautify();
   }

   if ( BeautifyCheckSupport(lang) ) {
      msg="Beautifying not supported for ":+p_mode_name;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   int index=find_index(lang'_beautify_selection',COMMAND_TYPE);
   if ( !index ) {
      msg="Cannot find command: "lang"_beautify_selection";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   int currentLine = p_line;
   _begin_select("", true, false);
   int startLine = p_line;
   _end_select("", true, false);
   int endLine = p_line;
   p_line = currentLine;

   // save bookmark, breakpoint, and annotation information
   _SaveBookmarksInFile(auto bmSaves, startLine, endLine);
   _SaveBreakpointsInFile(auto bpSaves, startLine, endLine);
   _SaveAnnotationsInFile(auto annoSaves);

   int status = call_index(index);

   // restore bookmarks, breakpoints, and annotation locations
   _RestoreBookmarksInFile(bmSaves);
   _RestoreBreakpointsInFile(bpSaves);
   _RestoreAnnotationsInFile(annoSaves);

   // Finally update adaptive formatting and we are done
   p_line = currentLine;
   adaptive_format_reset_buffers();
   return status;
}

int _OnUpdate_c_beautify(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   _str lang=target_wid.p_LangId;
   return((lang=='c' || lang=='d' || lang=='java' || lang=='js' || lang=='cs' || lang=='e')?MF_ENABLED:MF_GRAYED);
}

/**
 * Beautifies the current buffer using the current options.  Use the
 * C/C++/Java/JavaScript/C# Beautifier dialog box set beautifier options used by this command.
 *
 * @param in_wid Input window id to format. If 0, then current window is formatted.
 *               Defaults to 0.
 * @param start_indent Starting indent for formatted lines.
 *                     Defaults to 0.
 * @param use_form_options Set to true to use globally stored options filled in on form by
 * @param quiet  (optional). Set to true if you do not want to see status messages or be
 *               prompted for options (e.g. tab mismatch). More serious errors (e.g. failed to save
 *               default options, etc.) will still be displayed loudly.
 *               Defaults to false.
 *
 * @return  a status value.  Return value=2 means there was an error beautifying and calling function should
 * get the error message with vscf_iserror().
 *
 * @see gui_beautify
 * @see c_beautify_selection
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */

_command int c_format,c_beautify(int in_wid=0, int start_indent=0, boolean use_form_options=false, boolean quiet=false) name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (new_beautifier_supported_language(p_LangId)) {
      beautify(quiet);
   }

   struct scheme_s s:[];
   s._makeempty();

   if ( p_Nofhidden ) {
      show_all();
   }

   boolean old_modify=p_modify;   // Save in the case of doing the entire buffer so we can set it back when we "undo"
   int old_left_edge=p_left_edge;
   int old_cursor_y=p_cursor_y;
   save_pos(auto p);

   _str infilename='';
   _str outfilename='';
   int editorctl_wid=p_window_id;
   if (!_isEditorCtl()) {
      editorctl_wid=0;
   }

   // Do the current buffer
   int status=0;
   _str msg='';
   _str lang='';
   _str orig_lang='';
   typeless sync_lang_options='';
   typeless linenum;
   int writedefaultoptions=0;
   if ( !use_form_options ) {
      if ( !_isEditorCtl() ) {
         if ( !quiet ) {
            _message_box('No buffer!');
         }
         return(1);
      }
      lang=p_LangId;
      orig_lang=lang;
      if ( BeautifyCheckSupport(lang) ) {
         if ( !quiet ) {
            _message_box('Beautifying not supported for ':+p_mode_name);
         }
         return(1);
      }

      // Sync with language options?
      status=_ini_get_value(FormatUserIniFilename(),'common','sync_ext_options',sync_lang_options,'1');
      if ( status ) sync_lang_options=true;

      // Get [[lang]-scheme-Default] section and put into s
      writedefaultoptions=_get_user_scheme(s,'Default',orig_lang);
      status=_init_options(s:[CF_DEFAULT_SCHEME_NAME].options,sync_lang_options,orig_lang);
      if ( status ) {
         _message_box('Error setting options');
         return(1);
      }
      if ( writedefaultoptions ) {
         /* If we are here, then (for some reason) there were no default options
          * in the user scheme file, so write the default options
          */
         MaybeCreateFormatUserIniFile();
         status=_write_scheme(s:[CF_DEFAULT_SCHEME_NAME].options,sync_lang_options,orig_lang:+'-scheme-':+CF_DEFAULT_SCHEME_NAME);
         if ( status ) {
            _message_box('Failed to write default options to ':+FormatUserIniFilename());
            return(1);
         }
      }
      _adjust_scheme(s:[CF_DEFAULT_SCHEME_NAME].options);
   } else {
      lang=_form_lang;
      orig_lang=_orig_lang;   // The correct DLL function will not get called unless we set this properly
      s:[CF_DEFAULT_SCHEME_NAME].options=_options;
   }

   if ( _mycheck_tabs(editorctl_wid,s:[CF_DEFAULT_SCHEME_NAME].options,quiet) ) {
      return(1);
   }

   // Switch to temp view
   int orig_view_id=p_window_id;
   if ( in_wid ) {
      p_window_id=in_wid;
   }

   // Make a temp file to use as the input source file
   infilename=mktemp();
   if ( infilename=='' ) {
      _message_box('Error creating temp file');
      return(1);
   }
   status=_save_config_file(infilename);   // This is the source file
   if ( status ) {
      _message_box('Error creating temp file "':+infilename'".  ':+get_message(status));
      return(1);
   }
   int start_linenum=p_line;
   //messageNwait('start_linenum='start_linenum);
   bottom();
   boolean last_line_was_bare=(_line_length()==_line_length(1));
   boolean utf8=p_UTF8;
   int encoding=p_encoding;
   // Create a temporary view for beautifier output *with* p_undo_steps=0
   _str arg2='+td';   // DOS \r\n linebreak
   if ( length(p_newline)==1 ) {
      if ( substr(p_newline,1,1)=='\r' ) {
         arg2='+tm';   // Macintosh \r linebreak
      } else {
         arg2='+tu';   // UNIX \n linebreak
      }
   }
   int output_view_id=0;
   status=_create_temp_view(output_view_id,arg2);

   // Set the encoding of the temp view to the same thing as the original buffer
   p_UTF8=utf8;
   p_encoding=encoding;

   if ( status=='' ) {
      _message_box('Error creating temp view');
      return(1);
   }
   _delete_line();

   if ( start_indent<0 ) {
      start_indent=0;
   }

   mou_hour_glass(1);
   status=_format(s:[CF_DEFAULT_SCHEME_NAME].options,
                  orig_lang,
                  encoding,
                  infilename,
                  0,   // Input view id
                  outfilename,
                  start_indent,
                  start_linenum);
   mou_hour_glass(0);

   // Cleanup temp files that were created
   delete_file(infilename);   // Delete the temp file
   if ( !_line_length(true) ) {
      // Get rid of the zero-length line at the bottom
      _delete_line();
   }

   msg=vscf_iserror();
   if ( msg!='' ) {
      _delete_temp_view(output_view_id);
      if ( in_wid ) {
         p_window_id=in_wid;   // Do this instead of orig_view_id so we can set the error line number correctly
      } else {
         p_window_id=orig_view_id;
      }

      // Show the message and position at the error
      if ( isinteger(msg) ) {
         // Got one of the *_RC constants in rc.sh
         msg=get_message((int)msg);
      } else {
         parse msg with linenum ':' .;
         if ( isinteger(linenum) ) {   // Just in case
            p_line=linenum;
         }
      }
      if ( in_wid ) {
         /* Don't show the error yet.  Let c_beautify_selection() do that, otherwise
          * the linenumber it displays will be completely wrong
          */
         p_window_id=in_wid;
         return(2);
      } else {
         if ( !quiet ) {
            _message_box(msg);
         }
      }
      return(2);
   } else {
      // Everything is good, so clear the temp view and put the beautiful stuff in
      int mark=_alloc_selection();
      if ( mark<0 ) {
         _message_box(get_message(mark));
         _delete_temp_view(output_view_id);
         p_window_id=orig_view_id;
         return(1);
      }
      if ( in_wid ) {
         p_window_id=in_wid;
      } else {
         p_window_id=orig_view_id;
      }
      _lbclear();   // _lbclear() does a _delete_selection(), so don't have to worry about a lot of undo steps
      p_window_id=output_view_id;
      top();
      _select_line(mark);
      bottom();
      _select_line(mark);
      if ( in_wid ) {
         p_window_id=in_wid;
      } else {
         p_window_id=orig_view_id;
      }
      _copy_to_cursor(mark);
      _free_selection(mark);
      bottom();
      if ( last_line_was_bare ) {
         // The last line of the file had no newline at the end, so fix it
         _end_line();
         _delete_text(-2);
      }
      int adjusted_linenum=vscf_adjusted_linenum();
      //messageNwait('adjusted_linenum='adjusted_linenum);
      p_line= (adjusted_linenum)?(adjusted_linenum):(1);   // Don't allow line 0
      _begin_line();
      set_scroll_pos(old_left_edge,old_cursor_y);
      _delete_temp_view(output_view_id);
   }

   // Switch back to original view
   if ( in_wid ) {
      //p_window_id=orig_view_id;
   }

   return(0);
}

static int _format(int  p:[],
                   _str lang,
                   int  orig_encoding,
                   _str infilename,
                   _str in_wid,
                   _str outfilename,
                   int  start_indent,
                   int  start_linenum)
{
   typeless flags=_merge_flags(p);

   _str debugfilename="";
   int vse_flags=0;
   if ( CFDEBUG_WINDOW || CFDEBUG_FILE ) {
      if ( CFDEBUG_WINDOW ) {
         vse_flags|=CFDEBUGFLAG_WINDOW;
      }
      if ( CFDEBUG_FILE ) {
         vse_flags|=CFDEBUGFLAG_FILE;
      }
   }

   int status=0;
   if ( lang=="java" ) {
      status=vsjava_format(orig_encoding,
                           infilename,
                           (int)in_wid,
                           outfilename,
                           start_indent,
                           start_linenum,
                           flags,
                           vse_flags
                          );
   } else if ( lang=="js" ) {
      status=vsjavascript_format(orig_encoding,
                                 infilename,
                                 (int)in_wid,
                                 outfilename,
                                 start_indent,
                                 start_linenum,
                                 flags,
                                 vse_flags
                                );
   } else if ( lang=="e" ) {
      status=vsslickc_format(orig_encoding,
                             infilename,
                             (int)in_wid,
                             outfilename,
                             start_indent,
                             start_linenum,
                             flags,
                             vse_flags
                            );
   } else if ( lang=="cs" ) {
      status=vscsharp_format(orig_encoding,
                             infilename,
                             (int)in_wid,
                             outfilename,
                             start_indent,
                             start_linenum,
                             flags,
                             vse_flags
                            );
   } else if ( lang=="d" ) {
      status=vsd_format(orig_encoding,
                        infilename,
                        (int)in_wid,
                        outfilename,
                        start_indent,
                        start_linenum,
                        flags,
                        vse_flags
                       );
   } else if ( lang=="phpscript" ) {
      status=vsc_format(orig_encoding,
                        infilename,
                        (int)in_wid,
                        outfilename,
                        start_indent,
                        start_linenum,
                        flags,
                        vse_flags
                       );
   } else {
      status=vsc_format(orig_encoding,
                        infilename,
                        (int)in_wid,
                        outfilename,
                        start_indent,
                        start_linenum,
                        flags,
                        vse_flags
                       );
   }

   return(0);
}

static int _find_begin_pp_context(int sl, int el, boolean quiet=false)
{
   int old_mark = _duplicate_selection('');
   int mark = _alloc_selection();
   p_line=sl;
   _select_line(mark);
   p_line=el; _end_line();
   _select_line(mark);

   int status = 0;
   while ( p_line>sl ) {

      _show_selection(mark);
      status=search('^[ \t]@\#[ \t]@(endif|else|elif)','@hXCSrm-');
      _show_selection(old_mark);
      if ( status!=0 ) {
         break;
      }

      // Found a #endif/#else/#elif, so match with the correct #if
      int pp_line = p_line;
      if ( pp_line<2 ) {
         // We cannot possibly find the matching #if
         if ( !quiet ) {
            _message_box("Cannot find beginning of context:\r\r":+
                         "  Cannot find matching #if at line ":+pp_line);
         }
         _free_selection(mark);
         return(1);
      }
      up();
      _end_line();
      _show_selection(mark);
      status=search('^[ \t]@\#[ \t]@{#0(endif|ifdef|ifndef|if)}','@hXCSr-');
      int nesting = 0;
      while ( status==0 ) {
         _str word = get_match_text(0);
         if ( word!='endif' /*&& !nesting*/ ) {
            if ( nesting==0 ) break;   // Found it
            --nesting;
         } else {
            ++nesting;
         }
         status=repeat_search();
      }
      _show_selection(old_mark);
      if ( status ) {
         // We never found the matching #if, so bail
         if ( !quiet ) {
            _message_box("Cannot find beginning of context:\r\r":+
                         "  Cannot find matching #if at line ":+pp_line);
         }
         _free_selection(mark);
         return(1);
      }

      // If we got here, then that means we found the matching #if/#ifdef/#ifndef
   }
   if ( p_line<sl ) {
      // The #if/#ifdef/#ifndef is outside the selection,
      // so move up to it.  Don't extend the selection since
      // this is only context and we don't want to actually
      // beautify it.
   } else {
      _begin_select(mark);
   }
   _show_selection(old_mark);
   _free_selection(mark);

   return(0);
}

static int _find_begin_context(_str mark, int& sl, int& el, boolean quiet=false)
{
   int old_sl=sl;
   int old_el=el;

   _begin_select(mark);
   _begin_line();   // Goto to beginning of line so not fooled by start of comment

   /* If we are in the middle of a multi-line comment,
    * then skip to beginning of it
    */
   if ( _in_comment(1) ) {
      if ( p_line==1 ) {   // SHOULD NEVER GET HERE
         // There is no way we will find the beginning of this comment
         if ( !quiet ) {
            _message_box("Cannot find beginning of context:\r\r":+
                         "  Cannot find beginning of comment at line 1");
         }
         sl=0;
         el=0;
         return(1);
      }
      up();
      while ( p_line && _clex_find(0,'G')==CFG_COMMENT ) {
         up();
      }
      if ( _clex_find(0,'G')==CFG_COMMENT ) {
         // We are at the top of file
         if ( !quiet ) {
            _message_box("Cannot find beginning of context:\r\r":+
                         "  Cannot find beginning of comment at line 1");
         }
         sl=0;
         el=0;
         return(1);
      }
      _end_line();
      // Check to see if we are ON the multiline comment
      if ( _clex_find(0,'G')!=CFG_COMMENT ) {
         down();   // Move back onto the first line of the comment
      }
   } else {
#if 0
      /* If we are in the middle of multi-line preprocessing,
       * then skip to beginning of it
       */

      // Get the whole thing started with some fake values
      prev_lastch='\';
      while ( prev_lastch=='\' ) {
         if ( !up() ) {
            if ( p_line ) {
               get_line(prev_line);
               if ( prev_line=='' ) {
                  // Blank line, we're done
                  prev_lastch='';
                  continue;
               }
               prev_line=strip(prev_line,'B');
               prev_lastch=substr(prev_line,length(prev_line),1);
               continue;
            } else {
               // At top of file, so start at line 1
               sl=1;

               // Reset the selection
               _deselect(mark);
               p_line=sl;
               _select_line(mark);
               p_line=el;
               _select_line(mark);

               p_line=sl;

               return(0);
            }
         } else {
            // At top of file, so start at line 1
            sl=1;

            // Reset the selection
            _deselect(mark);
            p_line=sl;
            _select_line(mark);
            p_line=el;
            _select_line(mark);

            p_line=sl;

            return(0);
         }
      }
      down();   // Move down by 1 to correct for the last call to up()
#endif
   }
   sl=p_line;
   if ( sl!=old_sl ) {
      // Reset the selection
      _deselect(mark);
      p_line=sl;
      _select_line(mark);
      p_line=el;
      _select_line(mark);
   }

   int status=_find_begin_pp_context(p_line,el,quiet);
   if ( status!=0 ) {
      // Message already taken care of in _find_begin_pp_context()
      return(status);
   }
   // At this point, p_line is at the beginning of the preprocessing context (if any)

   //_begin_select(mark);
   // Determine if we can even call prev_proc()
   status = ( _istagging_supported() ) ? 0 : 1;
   while ( !status ) {
      status=prev_proc(1);
      if ( p_line>sl ) {
         // We are still inside the selection, need to go further up
         continue;
      }
      // If we got here, then we are outside the selection
      if ( _first_non_blank_col(1)>1 && !status ) {
         // Keep trying to find a context that starts in column 1, so we
         // have the best chance of getting the indent right in the selection.
         continue;
      }
      break;
   }
   if ( status ) {
      top();
   } else {
      // We could have ended up inside of a preprocessed function definition
      // header, so adjust up to beginning of preprocessing. Example:
      //
      //   #ifdef _MSCVER
      //
      //   extern WIN32_TYPE foo() { ... }   <-- Cursor ends up here, NOT on the #ifdef above
      //
      //   #else
      //
      //   extern UNIX_TYPE foo() { ... }
      //
      //   #endif
      //
      // Note:
      // This will not handle more complicated preprocessing cases (e.g. conditional
      // preprocessing that straddles the end of one function and the beginning of
      // the next function.
      status=_find_begin_pp_context(p_line,el,quiet);
      if ( status!=0 ) {
         // Message already taken care of in _find_begin_pp_context()
         return(status);
      }
      // At this point, p_line is at the beginning of the preprocessing context (if any)
   }

   return(0);
}

static int _find_end_context(_str mark, int &sl, int &el, boolean quiet=false)
{
   int old_sl=sl;
   int old_el=el;

   _end_select(mark);
   _end_line();   // Goto end of line so not fooled by start of comment

   /* If we are in the middle of a multi-line comment,
    * then skip to end of it
    */
   if ( _in_comment(1) ) {
      if ( down() ) {   // SHOULD NEVER GET HERE
         // There is no way that this multi-line comment has an end
         if ( !quiet ) {
            _message_box("Cannot find end of context:\r\r":+
                         "  Cannot find end of comment at line ":+p_line);
         }
         sl=0;
         el=0;
         return(1);
      }
      _begin_line();
      while ( _clex_find(0,'G')==CFG_COMMENT ) {
         if ( down() ) break;   // Comment might extend to bottom of file
         _begin_line();
      }
      if ( _clex_find(0,'G')==CFG_COMMENT ) {
         // We are at the bottom of file
         if ( !quiet ) {
            _message_box("Cannot find end of context:\r\r":+
                         "  Cannot find end of comment at line ":+p_line);
         }
         sl=0;
         el=0;
         return(1);
      }
      up();   // Move back onto the last line of the comment
   } else {
#if 0
      /* If we are in the middle of multi-line preprocessing,
       * then skip to end of it
       */

      lastch='';
      get_line(line);
      if ( line!='' ) {
         line=strip(line,'B');
         //firstch=substr(line,1,1);
         lastch=substr(line,length(line),1);
      }
      while ( lastch=='\' ) {
         if ( !down() ) {
            get_line(line);
            if ( line=='' ) {
               // Blank line, we're done
               lastch='';
               continue;
            }
            line=strip(line,'B');
            //firstch=substr(line,1,1);
            lastch=substr(line,length(line),1);
         } else {
            // At bottom of file
            el=p_line;

            // Reset the selection
            _deselect(mark);
            p_line=sl;
            _select_line(mark);
            p_line=el;
            _select_line(mark);

            return(0);
         }
      }
#endif
   }
   el=p_line;
   if ( el!=old_el ) {
      // Reset the selection
      _deselect(mark);
      p_line=sl;
      _select_line(mark);
      p_line=el;
      _select_line(mark);
   }

#if 0   // Don't care about dangling #elif/#else/#endif
   old_mark=_duplicate_selection('');
   _end_select(mark);
   _end_line();
   _show_selection(mark);
   status=search('^[ \t]@\#[ \t]@(endif|else|elif)','@rhm-');
   _show_selection(old_mark);
   if ( !status ) {
      // Found a #endif/#else/#elif, so match with the correct #if
      pp_line=p_line;
      if ( pp_line<2 ) {
         // We cannot possibly find the matching #if
         sl=0;
         el=0;
         return(1);
      }
      up();
      _end_line();
      _show_selection(mark);
      status=search('^[ \t]@\#[ \t]@{#0(endif|if|ifdef|ifndef)}','@rh-');
      nesting=0;
      while ( !status ) {
         word=get_match_text(0);
         if ( word!='endif' && !nesting ) {
            if ( !nesting ) {
               // Found it
               break;
            }
            --nesting;
         }
         ++nesting;
         status=repeat_search();
      }
      _show_selection(old_mark);
      if ( status ) {
         // We never found the matching #if, so bail
#if 1
         sl=0;
         el=0;
         if ( !quiet ) {
            _message_box("Cannot find beginning of context:\r\r":+
                         "  Cannot find matching #if at line ":+pp_line);
         }
         return(1);
#else
         // We never found the matching #if, so don't beautify
         el=pp_line-1;
         if ( el!=old_el ) {
            // Reset the selection
            _deselect(mark);
            p_line=sl;
            _select_line(mark);
            p_line=el;
            _select_line(mark);
         }
#endif
      }

      // If we got here, then that means we found the matching #if/#ifdef/#ifndef
      if ( p_line<sl ) {
         // The #if/#ifdef/#ifndef is outside the selection, so include it in the selection
         sl=p_line;

         // Reset the selection
         _deselect(mark);
         p_line=sl;
         _select_line(mark);
         p_line=el;
         _select_line(mark);
      }
   }
#endif

   //_end_select(mark);
#if 0
   // Determine if we can even call next_proc()
   status = (_istagging_supported())?0:1;
   while ( !status ) {
      status=next_proc(1);
      if ( p_line<el ) {
         // We are still inside the selection, need to go further down
         continue;
      }
      break;
   }
   if ( status ) bottom();
#endif

   return(0);
}

static int _create_context_view(int &temp_view_id,
                                int &context_mark,
                                int &soc_linenum,   // StartOfContext line number
                                boolean &last_line_was_bare,
                                boolean quiet=false)
{
   last_line_was_bare=0;
   save_pos(auto p);
   int old_linenum=p_line;
   int orig_mark=_duplicate_selection('');
   context_mark=_duplicate_selection();
   int mark=_alloc_selection();
   if ( mark<0 ) {
      _free_selection(context_mark);
      return(mark);
   }
   typeless stype=_select_type();
   if ( stype!='LINE' ) {
      // Change the duplicated selection into a LINE selection
      if ( stype=='CHAR' ) {
         int start_col=0;
         int end_col=0;
         int dummy=0;
         _get_selinfo(start_col,end_col,dummy);
         if ( end_col==1 ) {
            // Throw out the last line of the selection
            _deselect(context_mark);
            _begin_select();
            int startmark_linenum=p_line;
            _select_line(context_mark);
            _end_select();
            // Check to be sure it's not a case of a character-selection of 1 char on the same line
            if ( p_line!=startmark_linenum ) {
               up();
            }
            _select_line(context_mark);
         } else {
            _select_type(context_mark,'T','LINE');
         }
      } else {
         _select_type(context_mark,'T','LINE');
      }
   }

   // Define the line boundaries of the selection
   _begin_select(context_mark);
   int sl=p_line;   // start line
   _end_select(context_mark);
   int el=p_line;   // end line
   int orig_sl=sl;
   int orig_el=el;

   // Find the top context
   if ( _find_begin_context(context_mark,sl,el,quiet) ) {
      if ( !sl || !el ) {
         /* Probably in the middle of a comment/preprocessing that
          * extended to the bottom of file, so could do nothing
          */
         _free_selection(context_mark);
         _free_selection(mark);
         restore_pos(p);
         return(1);
      }
      top();
   }
   int tl=p_line;   // Top line
   //soc_linenum=tl;
   soc_linenum=sl;
   int diff=old_linenum-tl;
   _select_line(mark);
   _begin_select(context_mark);
   first_non_blank();
   int start_indent=p_col-1;

   // Find the bottom context
   if ( _find_end_context(context_mark,sl,el,quiet) ) {
      if ( !sl || !el ) {
         _free_selection(context_mark);
         _free_selection(mark);
         restore_pos(p);
         return(1);
      }
      bottom();
   }
   _select_line(mark);
   _end_select(context_mark);

   // Check to see if last line was bare of newline
   last_line_was_bare= (_line_length()==_line_length(1));

   //messageNwait('orig_sl='orig_sl'  orig_el='orig_el'  tl='tl'  sl='sl'  el='el);

   // Create a temporary view to hold the code selection and move it there
   _str arg2='+td';   // DOS \r\n linebreak
   if ( length(p_newline)==1 ) {
      if ( substr(p_newline,1,1)=='\r' ) {
         arg2='+tm';   // Macintosh \r linebreak
      } else {
         arg2='+tu';   // UNIX \n linebreak
      }
   }
   int orig_view_id=_create_temp_view(temp_view_id,arg2);
   if ( orig_view_id=='' ) return(1);

   // Set the encoding of the temp view to the same thing as the original buffer
   typeless junk;
   int utf8=0;
   int encoding=0;
   _get_selinfo(junk,junk,junk,mark,junk,utf8,encoding);
   p_UTF8 = (utf8 != 0);
   p_encoding=encoding;

   _copy_to_cursor(mark);
   _free_selection(mark);       // Can free this because it was never shown
   top();up();
   insert_line('/* CFORMAT-SUSPEND-WRITE */');
   down();
   p_line=sl-tl+1;   // +1 to compensate for the previously inserted line at the top
   insert_line('/* CFORMAT-RESUME-WRITE */');
   p_line=el-tl+1+2;   // +2 to compensate for the 2 previously inserted lines
   insert_line('/* CFORMAT-SUSPEND-WRITE */');
   top();
   p_line=p_line+diff+2;   // +2 to adjust for the CFORMAT-SUSPEND-WRITE and CFORMAT-RESUME-WRITE above
   //messageNwait('p_line='p_line'  diff='diff);
#if 0   // DEBUG
   _save_file('+o temp.out');
#endif
   p_window_id=orig_view_id;

   return(0);
}

static void _delete_context_selection(int context_mark)
{
   /* If we were on the last line, then beautified text will get inserted too
    * early in the buffer
    */
   _end_select();
   int last_line_was_empty=0;
   if ( down() ) {
      last_line_was_empty=1;   // We are on the last line of the file
   } else {
      up();
   }

   _begin_select(context_mark);
   _begin_line();

   // Now delete the originally selected lines
   _delete_selection(context_mark);
   _free_selection(context_mark);   // Can free this because it was never shown
   if ( !last_line_was_empty ) up();

#if 0
   /* If we were on the last line, then beautified text will get inserted too
    * early in the buffer
    */
   if ( do_empty ) {
      // Stick an EMPTY (yes, truly empty) line at the end of the buffer
      insert_line('');
      _delete_text(-2);   // Delete to end of buffer (this will get the newline)
   }
#endif

   return;
}

int _OnUpdate_c_beautify_selection(CMDUI cmdui,int target_wid,_str command)
{
   return(_OnUpdate_c_beautify(cmdui,target_wid,command));
}


/**
 * Beautifies the current selection using the current options.  If there is no
 * current selection the entire buffer is beautified.  Use the C/C++/Java/JavaScript/C# Beautifier
 * dialog box set beautifier options used by this command.
 *
 * @see gui_beautify
 * @see c_beautify
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods
 */
_command int c_format_selection,c_beautify_selection(boolean use_form_options=false, boolean quiet=false) name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (new_beautifier_supported_language(p_LangId)) {
      if (select_active()) {
         return new_beautify_selection();
      } else {
         beautify_current_buffer();
         return 0;
      }
   }

   if ( !select_active() ) {
      return(c_format(0,0,use_form_options,quiet));
   }

   save_pos(auto p);
   int orig_view_id=p_window_id;
   int old_left_edge=p_left_edge;
   int old_cursor_y=p_cursor_y;

   _begin_select();
   int tom_linenum=p_line;
   restore_pos(p);

   // Find the context
   int temp_view_id=0;
   typeless context_mark=0;
   int soc_linenum=0;
   boolean last_line_was_bare=0;
   if ( _create_context_view(temp_view_id,context_mark,soc_linenum,last_line_was_bare,quiet) ) {
      _message_box('Failed to derive context for selection');
      return(1);
   }

   int mark=0;
   int old_mark=0;
   int start_indent=0;
   int new_linenum=0;
   int error_linenum=0;
   restore_pos(p);   // Do this before calling c_format() so don't end up somewhere funky
   int status=c_format(temp_view_id,start_indent,use_form_options,quiet);
   if ( !status ) {
      p_window_id=orig_view_id;
      old_mark=_duplicate_selection('');
      mark=_alloc_selection();
      if ( mark<0 ) {
         _delete_temp_view(temp_view_id);
         _message_box(get_message(mark));
         return(mark);
      }

      /* Delete the selection and position cursor so we are sure
       * we start inserting beautified text at the correct place
       */
      _delete_context_selection(context_mark);

      // Get the beautified text from the temp view
      p_window_id=temp_view_id;
      new_linenum=p_line;
      top();
      _select_line(mark);
      bottom();
      _select_line(mark);
      p_window_id=orig_view_id;
      _copy_to_cursor(mark);
      _end_select(mark);
      _free_selection(mark);
#if 1
      // Check to see if we need to strip off the last newline
      if ( last_line_was_bare ) {
         _end_line();
         _delete_text(-2);
      }
#endif
      /* -2 to correct for the
       * CFORMAT-SUSPEND-WRITE and CFORMAT-RESUME-WRITE directives
       * in the temp view.
       */
      //messageNwait('new_linenum='new_linenum'  soc_linenum='soc_linenum);
      //new_linenum=new_linenum+soc_linenum-1-2;
      //new_linenum=new_linenum+tom_linenum-1-2;
      //new_linenum=new_linenum+tom_linenum-1;
      new_linenum=new_linenum+soc_linenum-1;
      p_line=new_linenum;
      set_scroll_pos(old_left_edge,old_cursor_y);
      /* HERE - Need to account for extended selection because started/ended
       * in the middle of a comment/preprocessing.  Need to do an adjustment.
       */
   } else {
      if ( status==2 ) {
         /* There was an error, so transform the error line number
          * from the temp view into the correct line number
          */
         error_linenum=p_line;
         p_window_id=orig_view_id;
         _deselect();
         /* -2 to correct for the
          * CFORMAT-SUSPEND-WRITE and CFORMAT-RESUME-WRITE directives
          * in the temp view.
          */
         error_linenum=error_linenum+soc_linenum-1-2;
         //messageNwait('soc_linenum='soc_linenum'  error_linenum='error_linenum);
         if ( error_linenum>0 ) {
            p_line=error_linenum;
         }
         set_scroll_pos(old_left_edge,old_cursor_y);
         _str msg=vscf_iserror();
         if ( isinteger(msg) ) {
            // Got one of the *_RC constants in rc.sh
            msg=get_message((int)msg);
         } else {
            parse msg with . ':' msg;
            msg=error_linenum:+':':+msg;
         }
         if ( !quiet ) {
            _message_box(msg);
         }
      }
   }

   // Cleanup
   _delete_temp_view(temp_view_id);

   return(status);
}

static int _mycheck_tabs(int editorctl_wid, int p:[], boolean quiet=false)
{
   // Check to see if the current buffer's tab settings differ from the (syntax_indent && indent_with_tabs)
   if ( p:["indent_with_tabs"] && editorctl_wid ) {
      typeless t1=0;
      typeless t2=0;
      if ( editorctl_wid.p_tabs!='' ) {
         parse editorctl_wid.p_tabs with t1 t2 .;
      }
      // It is possible for p_tabs to have a non-interval setting:
      // p_tabs = '2';  // One tabstop at column 2
      // p_tabs = '';   // No tabstops defined
      int interval = 0;
      if ( isinteger(t1) && isinteger(t2) ) {
         interval = t2 - t1;
      }
      if ( interval!=p:["tabsize"] ) {
         int status = IDOK;
         if ( !quiet ) {
            status=_message_box("Your current buffer's tab settings do not match your chosen tab size.\r\r":+
                                "OK will change your current buffer's tab settings to match those you have chosen",
                                "",
                                MB_OKCANCEL);
         }
         if ( status==IDOK ) {
            editorctl_wid.p_tabs='+':+p:["tabsize"];
         } else {
            return(1);
         }
      }
   }

   return(0);
}

#define CFFLAG_INDENT_CASE              "ic"     /* indent-case                        */
#define CFFLAG_INDENT_FL                "if"     /* indent-first-level                 */
#define CFFLAG_INDENT_WITH_TABS         "it"     /* indent-with-tabs                   */
#define CFFLAG_NOSPACE_BEFORE_PAREN     "nsp"    /* nospace-before-paren               */
#define CFFLAG_PAD_CONDITION            "pc"     /* pad-condition                      */
#define CFFLAG_NOPAD_CONDITION          "npc"    /* nopad-condition                    */
#define CFFLAG_EAT_BLANK_LINES          "eb"     /* eat-blank-lines                    */
#define CFFLAG_INDENT_PP                "ip"     /* indent-preprocessing               */
#define CFFLAG_INDENT_PP_INSIDE_BRACES  "ipb"    /* indent-preprocessing-inside-braces */
#define CFFLAG_INDENT_IDEMPOTENT_BLOCK  "ipi"    /* indent-idempotent-block            */
#define CFFLAG_CUDDLE_ELSE              "ce"     /* cuddle-else                        */
#define CFFLAG_BESTYLE_ON_FUNCTIONS     "bf"     /* bestyle-on-functions               */
#define CFFLAG_NOSPACE_BEFORE_BRACE     "nsb"    /* nospace-before-brace               */
#define CFFLAG_EAT_PP_SPACE             "eps"    /* eat-preprocessing-space            */
#define CFFLAG_INDENT_COMMENTS          "isc"    /* indent-standalone-comments         */
#define CFFLAG_USE_RELATIVE_INDENT      "icr"    /* indent-trailing-comments-relative  */
#define CFFLAG_ALIGN_ON_PARENS          "ap"     /* align-on-parens                    */
#define CFFLAG_ALIGN_ON_EQUAL           "ae"     /* align-on-equal                     */
#define CFFLAG_INDENT_COL1_COMMENTS     "ic1"    /* indent-col1-comments               */
#define CFFLAG_PARENS_ON_RETURN         "pr"     /* parens-on-return                   */
#define CFFLAG_BRACE_STYLE              "bs"     /* brace-style                        */
#define CFFLAG_SYNTAX_INDENT            "si"     /* syntax-indent                      */
#define CFFLAG_BRACE_INDENT             "bi"     /* brace-indent                       */
#define CFFLAG_STATEMENT_COMMENT_COL    "scc"    /* statement-comment-col              */
#define CFFLAG_DECL_COMMENT_COL         "dcc"    /* decl-comment-col                   */
#define CFFLAG_TABSIZE                  "ts"     /* tabsize                            */
#define CFFLAG_ORIG_TABSIZE             "ots"    /* orig_tabsize                       */
#define CFFLAG_CONTINUATION_INDENT      "ci"     /* continuation-indent                */
#define CFFLAG_INDENT_ACCESS_SPECIFIER  "ias"    /* indent access specifier            */

static _str _merge_flags(int p:[])
{
   return(((p:["indent_case"])                   ?('+'):('-')) :+ CFFLAG_INDENT_CASE                :+' ':+
          ((p:["indent_fl"])                     ?('+'):('-')) :+ CFFLAG_INDENT_FL                  :+' ':+
          ((p:["indent_with_tabs"])              ?('+'):('-')) :+ CFFLAG_INDENT_WITH_TABS           :+' ':+
          ((p:["nospace_before_paren"])          ?('+'):('-')) :+ CFFLAG_NOSPACE_BEFORE_PAREN       :+' ':+
          ((p:["pad_condition"])                 ?('+'):('-')) :+ CFFLAG_PAD_CONDITION              :+' ':+
          ((p:["nopad_condition"])               ?('+'):('-')) :+ CFFLAG_NOPAD_CONDITION            :+' ':+
          ((p:["eat_blank_lines"])               ?('+'):('-')) :+ CFFLAG_EAT_BLANK_LINES            :+' ':+
          ((p:["indent_pp"])                     ?('+'):('-')) :+ CFFLAG_INDENT_PP                  :+' ':+
          ((p:["indent_pp_inside_braces"])       ?('+'):('-')) :+ CFFLAG_INDENT_PP_INSIDE_BRACES    :+' ':+
          ((p:["indent_idempotent_block"])       ?('+'):('-')) :+ CFFLAG_INDENT_IDEMPOTENT_BLOCK    :+' ':+
          ((p:["cuddle_else"])                   ?('+'):('-')) :+ CFFLAG_CUDDLE_ELSE                :+' ':+
          ((p:["bestyle_on_functions"])          ?('+'):('-')) :+ CFFLAG_BESTYLE_ON_FUNCTIONS       :+' ':+
          ((p:["nospace_before_brace"])          ?('+'):('-')) :+ CFFLAG_NOSPACE_BEFORE_BRACE       :+' ':+
          ((p:["eat_pp_space"])                  ?('+'):('-')) :+ CFFLAG_EAT_PP_SPACE               :+' ':+
          ((p:["indent_comments"])               ?('+'):('-')) :+ CFFLAG_INDENT_COMMENTS            :+' ':+
          ((p:["use_relative_indent"])           ?('+'):('-')) :+ CFFLAG_USE_RELATIVE_INDENT        :+' ':+
          ((p:["align_on_parens"])               ?('+'):('-')) :+ CFFLAG_ALIGN_ON_PARENS            :+' ':+
          ((p:["align_on_equal"])                ?('+'):('-')) :+ CFFLAG_ALIGN_ON_EQUAL             :+' ':+
          ((p:["indent_col1_comments"])          ?('+'):('-')) :+ CFFLAG_INDENT_COL1_COMMENTS       :+' ':+
          ((p:["parens_on_return"])              ?('+'):('-')) :+ CFFLAG_PARENS_ON_RETURN           :+' ':+
          ((p:["indent_access_specifier"])       ?('+'):('-')) :+ CFFLAG_INDENT_ACCESS_SPECIFIER    :+' ':+
          '-':+CFFLAG_BRACE_STYLE           :+' ':+p:["be_style"]              :+' ':+
          '-':+CFFLAG_SYNTAX_INDENT         :+' ':+p:["syntax_indent"]         :+' ':+
          '-':+CFFLAG_BRACE_INDENT          :+' ':+p:["brace_indent"]          :+' ':+
          '-':+CFFLAG_STATEMENT_COMMENT_COL :+' ':+p:["statement_comment_col"] :+' ':+
          '-':+CFFLAG_DECL_COMMENT_COL      :+' ':+p:["decl_comment_col"]      :+' ':+
          '-':+CFFLAG_TABSIZE               :+' ':+p:["tabsize"]               :+' ':+
          '-':+CFFLAG_ORIG_TABSIZE          :+' ':+p:["orig_tabsize"]          :+' ':+
          '-':+CFFLAG_CONTINUATION_INDENT   :+' ':+p:["continuation_indent"]
         );
}

#define CFBESTYLE0_FLAG 1
#define CFBESTYLE1_FLAG 2
#define CFBESTYLE2_FLAG 4

static int _init_options(int (&p):[],int sync_lang_options,_str lang)
{
   _str msg='';
   syntax_indent := LanguageSettings.getSyntaxIndent(lang);
   if ( sync_lang_options || !isinteger(p:["syntax_indent"]) || p:["syntax_indent"]<0 ) {
      if ( !isinteger(syntax_indent) || syntax_indent<0 ) {
         _message_box('Invalid syntax indent value');
         return(1);
      }
      p:["syntax_indent"]=syntax_indent;   // Set to default value
   }

   int be_style=LanguageSettings.getBeginEndStyle(lang);
   if ( sync_lang_options || !isinteger(p:["be_style"]) ||
        p:["be_style"]<0 || p:["be_style"]>4 ) {
      if ( !isinteger(be_style) || be_style<0 || be_style>2 ) {
         _message_box('Invalid Begin/End style');
         return(1);
      }
      /* The 3 styles are indexed 0x1,0x2,0x4 (not 0,1,2) in cformat.dll
       * because 0 means no brace style
       */
      switch ( be_style ) {
      case 0:
         be_style=CFBESTYLE0_FLAG;   // The first begin/end style (Kernigan&Richie)
         break;
      case 1:
         be_style=CFBESTYLE1_FLAG;
         break;
      case 2:
         be_style=CFBESTYLE2_FLAG;
         break;
      default:
         be_style=0;   // SHOULD NEVER GET HERE
      }
      p:["be_style"]=be_style;
   }

   indent_fl := LanguageSettings.getIndentFirstLevel(lang);
   if ( sync_lang_options || !isinteger(p:["indent_fl"]) ) p:["indent_fl"]=indent_fl;
   indent_case := (int)LanguageSettings.getIndentCaseFromSwitch(lang);
   if ( sync_lang_options || !isinteger(p:["indent_case"]) ) p:["indent_case"]= indent_case;
   nospace_before_paren := (int)LanguageSettings.getNoSpaceBeforeParen(lang);
   if ( sync_lang_options || !isinteger(p:["nospace_before_paren"]) ) p:["nospace_before_paren"]= nospace_before_paren;

   if ( !isinteger(p:["eat_blank_lines"]) ) {
      p:["eat_blank_lines"]=0;
   }

#if 1
   // For now, there will be no separate brace_indent amount
   if ( p:["be_style"]==CFBESTYLE2_FLAG ) {
      p:["brace_indent"]=p:["syntax_indent"];
   } else {
      p:["brace_indent"]=0;
   }
#else
   if ( !isinteger(p:["brace_indent"]) ) {
      p:["brace_indent"]=0;
   }
#endif

   if ( !isinteger(p:["indent_pp"]) ) {
      p:["indent_pp"]=1;   // Default to ON
   }

   if ( !isinteger(p:["indent_pp_inside_braces"]) ) {
      p:["indent_pp_inside_braces"]=0;   // Default to OFF
   }

   if ( !isinteger(p:["indent_idempotent_block"]) ) {
      p:["indent_idempotent_block"]=0;   // Default to OFF
   }

   if ( !isinteger(p:["statement_comment_col"]) ) {
      p:["statement_comment_col"]=0;
   }

   if ( !isinteger(p:["decl_comment_col"]) ) {
      p:["decl_comment_col"]=0;
   }

   if ( !isinteger(p:["cuddle_else"]) ) {
      p:["cuddle_else"]=(int)(p:["be_style"]==CFBESTYLE0_FLAG);
   }

   if ( !isinteger(p:["bestyle_on_functions"]) ) {
      p:["bestyle_on_functions"]=0;
   }

   if ( !isinteger(p:["indent_comments"]) ) {
      p:["indent_comments"]=1;   // Default to ON
   }

   if ( !isinteger(p:["use_relative_indent"]) ) {
      p:["use_relative_indent"]=1;   // Default to ON
   }

   if ( !isinteger(p:["align_on_parens"]) ) {
      p:["align_on_parens"]=1;   // Default to ON
   }

   if ( !isinteger(p:["align_on_equal"]) ) {
      p:["align_on_equal"]=1;   // Default to ON
   }

   if ( !isinteger(p:["indent_col1_comments"]) ) {
      p:["indent_col1_comments"]=0;   // Default to OFF
   }

   if ( !isinteger(p:["parens_on_return"]) ) {
      p:["parens_on_return"]=0;   // Default to OFF
   }

   /* NOTE:  Padding condition actually has 3 states:  INSERT_PADDING, REMOVE_PADDING,
    *        and LEAVE_PADDING_ALONE.  It is easier to make 2 separate options
    *        (pad_condition and nopad_condition), and, if neither of these are ON,
    *        then use the default case (leave padding alone).
    */
   if ( !isinteger(p:["pad_condition"]) ) {
      p:["pad_condition"]=0;   // Default to OFF
   }

   if ( !isinteger(p:["nopad_condition"]) ) {
      p:["nopad_condition"]=0;   // Default to OFF
   }

   p:["nospace_before_brace"]=0;   // HERE - don't support this option yet

   if ( !isinteger(p:["indent_access_specifier"]) ) {
      p:["indent_access_specifier"]=0;
   }

   if ( sync_lang_options || !isinteger(p:["indent_with_tabs"]) ) {
      p:["indent_with_tabs"]=(int)LanguageSettings.getIndentWithTabs(lang);
   }

   if ( !isinteger(p:["continuation_indent"]) || p:["continuation_indent"]<0 ) {
      p:["continuation_indent"]=0;
   }

   if ( !isinteger(p:["eat_pp_space"]) ) {
      p:["eat_pp_space"]=1;   // Default to ON
   }

   if ( !isinteger(p:["tabsize"]) || p:["tabsize"]<0 ) {
      p:["tabsize"]=p:["syntax_indent"];
   }

   if ( !isinteger(p:["orig_tabsize"]) || p:["orig_tabsize"]<0 ) {
      p:["orig_tabsize"]=p:["syntax_indent"];
   }

   return(0);
}

// This function derives a backup filename from an input filename
static _str _make_backup(_str backup_filename)
{
   _str orig_filename=strip(backup_filename,'B','"');
#if __UNIX__
   return(orig_filename:+'.~');
#else
   _str ext=_get_extension(orig_filename);
   _str filename=_strip_filename(orig_filename,'I');
   if (ext=='') {
      //File had No Extension
      return(filename:+'.__~');
   }
   if ( length(ext)==1 ) {
      //File had one character extension
      return(filename:+'.':+ext:+'_~');
   }
   return(filename:+'.':+substr(ext,1,2):+'~':+substr(ext,4));
#endif
}

defeventtab _c_beautify_form;
_ctl_go.on_create(_str lang='', _str orig_lang='', _str arg3='', _str caption='')
{
   if ( caption!="" ) {
      p_active_form.p_caption=caption;
   }

   _orig_lang=orig_lang;
   scheme_s s:[];

   s._makeempty();

   _suspend_modify=0;
   CHANGING_SCHEMES=1;
   int editorctl_wid=_form_parent();
   if ((editorctl_wid && !editorctl_wid._isEditorCtl()) ||
       (editorctl_wid._QReadOnly())) {
      editorctl_wid=0;
   }

   if ( lang!='') {
      // Specific language passed to form
      if ( !editorctl_wid || arg3!="" ) {
         _ctl_go.p_enabled=false;
      }
   } else {
      if ( !editorctl_wid) {
         // No extension passed to form
         _message_box('No Buffer');
         p_active_form._delete_window();
         return('');
      }
      _orig_lang=lang=_mdi.p_child.p_LangId;

   }
   // The language here may not match the buffer's language.
   _form_lang=lang;

   int status=_get_user_scheme(s,'Default',_orig_lang);

   _suspend_modify=1;
   status=_init_form(s:['Default'].options);
   _suspend_modify=0;
   if ( status ) {
      _ctl_go.p_enabled=0;
      return('');
   }

   _form_options=s:['Default'].options;
   _orig_form_options=_form_options;   // Save this for the Reset button

   // Remember the active tab
   _ctl_sstab._retrieve_value();
   //_ctl_sstab.p_ActiveTab=0;
}

_c_beautify_form.on_load()
{
   // Set focus to "Beautify" button
   _ctl_go._set_focus();
}

_ctl_go.on_destroy()
{
   // Remember the active tab
   _ctl_sstab._append_retrieve(_ctl_sstab,_ctl_sstab.p_ActiveTab);
}

_ctl_go.lbutton_up()
{
   // Save the user default and dialog settings
   typeless status=call_event(_control _ctl_save,LBUTTON_UP);
   if ( status ) {
      return('');
   }

   // Check to see if the current buffer's tab settings matches the tab size chosen
   if ( _mycheck_tabs(_form_parent(),_form_options,false) ) {
      return('');
   }

   boolean do_selection=0;
   if ( _ctl_selection_only.p_enabled && _ctl_selection_only.p_value ) {
      do_selection=1;
   }
   int editorctl_wid=_form_parent();
   int wid=p_window_id;
   p_active_form._delete_window();

   // save bookmark, breakpoint, and annotation information
   editorctl_wid._SaveBookmarksInFile(auto bmSaves);
   editorctl_wid._SaveBreakpointsInFile(auto bpSaves);
   editorctl_wid._SaveAnnotationsInFile(auto annoSaves);

   p_window_id=editorctl_wid;
   if ( do_selection ) {
      c_beautify_selection(1);
   } else {
      c_beautify(0,0,true);   // arg(3) says use static array _options:[]
   }

   // restore bookmarks, breakpoints, and annotation locations
   editorctl_wid._RestoreBookmarksInFile(bmSaves);
   editorctl_wid._RestoreBreakpointsInFile(bpSaves);
   editorctl_wid._RestoreAnnotationsInFile(annoSaves);

#if 0
   p_window_id=wid;
   p_active_form._delete_window();
#endif
}

int _ctl_save.lbutton_up()
{
   MaybeCreateFormatUserIniFile();

   typeless sync_lang_options=_ctl_sync_ext_options.p_value;

   // Save the user dialog settings to [<_orig_lang>-scheme-Default] section of user schemes
   if ( _get_form_scheme(_form_options) || _write_scheme(_form_options,sync_lang_options,_orig_lang:+'-scheme-Default') ) {
      return(1);
   }

   _options=_form_options;
   _adjust_scheme(_options);
#if 0
   /* Some quick cleanup so that meaningless dialog options don't get stuck in
    * the default section of user ini file
    */
   _options._deleteel("disable_bestyle");
   _options._deleteel("statement_comment_state");
   _options._deleteel("pad_condition_state");

   //messageNwait('_form_lang='_form_lang'  _orig_lang='_orig_lang);
   if ( _write_scheme(_options,_orig_lang:+'-scheme-':+CF_DEFAULT_SCHEME_NAME) ) {
      _message_box('Failed to write default options to ':+FormatUserIniFilename());
      return(1);
   }
#endif

   // Save the last scheme name used
   _str scheme_name=_ctl_schemes_list.p_text;
   _ini_set_value(FormatUserIniFilename(),_orig_lang:+'-scheme-Default','last_scheme',scheme_name);

   /* Now write common options.  We do this after the call to _write_scheme()
    * because _write_scheme() gaurantees that the file will exist.
    */
   _ini_set_value(FormatUserIniFilename(),'common','sync_ext_options',sync_lang_options);

   // Configuration was saved, so change the "Cancel" caption to "Close"
   _ctl_cancel.p_caption='Cl&ose';

   return(0);
}

// arg(1)!='' means do a rename instead of a save
int _ctl_scheme_save.lbutton_up(_str doRename='')
{
   _str old_name=_ctl_schemes_list.p_text;
   if ( old_name==CF_NONE_SCHEME_NAME ) {
      old_name='';
   } else if ( pos('(Modified)',old_name,1,'I') ) {
      parse old_name with old_name '(Modified)' ;
   }

   boolean do_rename= (doRename!='');

   if ( do_rename && !_user_schemes._indexin(old_name) ) {
      _message_box(nls("Can't find user scheme '%s'.  System schemes cannot be renamed",old_name));
      return(1);
   }

   // Prompt user for name of scheme
   int count=0;
   _str system_schemes=' 'CF_DEFAULT_SCHEME_NAME' ';
   typeless i;
   for ( i._makeempty();; ) {
      _schemes._nextel(i);
      if ( i._isempty() ) break;
      system_schemes=system_schemes:+' "'i'" ';
   }
   count=0;
   _str user_schemes='';
   for ( i._makeempty();; ) {
      _user_schemes._nextel(i);
      if ( i._isempty() ) break;
      if ( i==CF_DEFAULT_SCHEME_NAME ) continue;
      user_schemes=user_schemes:+' "'i'" ';
   }
   _str name=show('-modal _beautify_save_scheme_form',old_name,do_rename,system_schemes,user_schemes);
   if ( name=='' ) {
      // User cancelled
      return(0);
   }

   MaybeCreateFormatUserIniFile();

   typeless status=0;
   if ( do_rename ) {
      // Delete the existing scheme
      _user_schemes._deleteel(old_name);
      _ini_delete_section(FormatUserIniFilename(),_orig_lang:+'-scheme-':+old_name);

      _ctl_schemes_list._lbfind_and_delete_item(old_name, 'I');
      _ctl_schemes_list._lbtop();
   }

   // Save the user dialog settings to [<_form_lang>-scheme-<scheme name>] section of user schemes
   if ( _get_form_scheme(_form_options) || _write_scheme(_form_options,0,_orig_lang:+'-scheme-'name) ) {
      _message_box('Failed to write scheme to ':+FormatUserIniFilename());
      return(1);
   }
   _suspend_modify=1;
   _ctl_schemes_list._lbadd_item_no_dupe(name, '', LBADD_SORT, true);
   _ctl_schemes_list.p_user='';   // Set this so _ctl_schemes_list.on_change doesn't try to save old scheme
   _suspend_modify=0;
   _user_schemes:[name].options=_form_options;

   return(0);
}

_ctl_scheme_rename.lbutton_up()
{
   call_event(1,_control _ctl_scheme_save,LBUTTON_UP,'W');
}

_ctl_scheme_delete.lbutton_up()
{
   _str old_name=_ctl_schemes_list.p_text;
   if ( old_name==CF_NONE_SCHEME_NAME ) {
      _message_box('Cannot remove empty scheme');
      return('');
   } else if ( !_user_schemes._indexin(old_name) ) {
      _message_box(nls("Can't find user scheme '%s'.  System schemes cannot be removed",old_name));
      return('');
   }

   MaybeCreateFormatUserIniFile();

   // Delete the existing scheme
   _user_schemes._deleteel(old_name);
   _ini_delete_section(FormatUserIniFilename(),_orig_lang:+'-scheme-':+old_name);
   _suspend_modify=1;
   _ctl_schemes_list._lbfind_and_delete_item(old_name, 'I');
   _ctl_schemes_list._lbtop();
   _ctl_schemes_list.p_text=CF_NONE_SCHEME_NAME;
   _ctl_schemes_list.p_user='';   // Set this so _ctl_schemes_list.on_change doesn't try to save old scheme
   _suspend_modify=0;
}

// p_user holds the previous scheme in case of error
_ctl_schemes_list.on_change(int reason)
{
   if ( reason==CHANGE_OTHER || !CHANGING_SCHEMES ) {
      /* Probably stuck a '(Modified)' on the end of the scheme name
       * OR
       * We are temporarily suspending ON_CHANGE for the scheme list
       */
      return('');
   }
   _str name=p_text;
   _str old_name=p_user;
   // IF name has not changed OR no scheme chosen
   if ( name==old_name || name==CF_NONE_SCHEME_NAME ) {
      return('');
   }
   int status=0;
   if ( !_schemes._indexin(name) && !_user_schemes._indexin(name) ) {
      _message_box('Empty scheme!');
      p_text=old_name;
      return('');
   } else {
      if ( pos('(Modified)',old_name,1,'I') ) {
         status=_message_box("You have a modified scheme.\r":+
                             "Do you wish to save it?",
                             "",MB_YESNOCANCEL|MB_ICONQUESTION);
         if ( status==IDCANCEL ) {
            p_text=old_name;
            return('');
         } else if ( status==IDYES ) {
            p_text=old_name;   // Put the old name in so we know which scheme to save
            status=call_event(_control _ctl_scheme_save,LBUTTON_UP);
            if ( status ) {
               // There was a problem, so do not put the new name back in its place
               return('');
            }
            _ctl_schemes_list.p_text=name;   // Put it back
         }

      }
      _suspend_modify=1;
      CHANGING_SCHEMES=0;
      if ( _schemes._indexin(name) ) {
         _init_form(_schemes:[name].options,0);   // Second argument overrides sync_lang_options
         _form_options=_schemes:[name].options;
      } else {
         _init_form(_user_schemes:[name].options,0);   // Second argument overrides sync_lang_options
         _form_options=_user_schemes:[name].options;
      }
      CHANGING_SCHEMES=1;
      _suspend_modify=0;
   }

   p_user=name;
}

_ctl_reset.lbutton_up()
{
   _ctl_schemes_list.p_text=_orig_scheme;
   _ctl_schemes_list.p_user='';   // Set this so _ctl_schemes_list.on_change doesn't try to save old scheme
   _suspend_modify=1;
   CHANGING_SCHEMES=0;
   _init_form(_orig_form_options,0);   // Second argument overrides sync_lang_options
   _form_options=_orig_form_options;
   CHANGING_SCHEMES=1;
   _suspend_modify=0;
}

static int _init_form(int (&p):[], ...)
{
   // Sync with language options?
   typeless sync_lang_options='';
   int status=_ini_get_value(FormatUserIniFilename(),'common','sync_ext_options',sync_lang_options,'1');
   if ( status ) sync_lang_options=true;
   if ( sync_lang_options ) {
      _ctl_sync_ext_options.p_value=sync_lang_options;
   }

   if ( arg(2)!="" ) {
      // Override sync_lang_options with value passed in
      sync_lang_options= (arg(2)!=0);
   }
   if ( _init_options(p,sync_lang_options,_orig_lang) ) {
      return(1);
   }

   /* Some form specific options that must be initialized eventhough
    * they are not on the main dialog
    */
   if ( !isinteger(p:["disable_bestyle"]) ) p:["disable_bestyle"]=0;
   if ( !isinteger(p:["statement_comment_state"]) ) p:["statement_comment_state"]=CFCOMMENT_STATE_RELATIVE;
   if ( !isinteger(p:["pad_condition_state"]) ) p:["pad_condition_state"]=CFPADCONDITION_STATE_NOCHANGE;

   onCreateBEStyle(p);
   onCreateIndenting(p);
   onCreateComments(p);
   onCreateAdvanced(p);
   if ( CHANGING_SCHEMES ) onCreateSchemes();

   // Selection
   if ( _mdi.p_child.select_active() ) {
      _ctl_selection_only.p_enabled=1;
      _ctl_selection_only.p_value=1;
   } else {
      _ctl_selection_only.p_enabled=0;
   }

   return(0);
}

// Begin/End Style
_ctl_disable_bestyle.lbutton_up(...)
{
   boolean enabled= !(_ctl_disable_bestyle.p_value);
   _ctl_bestyle0.p_enabled=enabled;
   _ctl_bestyle1.p_enabled=enabled;
   _ctl_bestyle2.p_enabled=enabled;

   _modify_scheme();
}

// We only use this event to notify _schemes_list of a modification to current scheme
_ctl_bestyle0.lbutton_up()
{
   _modify_scheme();
}

static int onCreateBEStyle(int (&p):[])
{
   // Begin/end style
   _suspend_modify=1;

   if ( !isinteger(p:["disable_bestyle"]) ) {
      p:["disable_bestyle"]=0;
   }
   _ctl_disable_bestyle.p_value=p:["disable_bestyle"];
   call_event(_control _ctl_disable_bestyle,LBUTTON_UP);
   _ctl_bestyle0.p_value=0;
   _ctl_bestyle1.p_value=0;
   _ctl_bestyle2.p_value=0;
   switch ( p:["be_style"] ) {
   case CFBESTYLE0_FLAG:
      _ctl_bestyle0.p_value=1;
      break;
   case CFBESTYLE1_FLAG:
      _ctl_bestyle1.p_value=1;
      break;
   case CFBESTYLE2_FLAG:
      _ctl_bestyle2.p_value=1;
      break;
   }
   _ctl_nospace_before_paren.p_value=p:["nospace_before_paren"];
   _ctl_cuddle_else.p_value=p:["cuddle_else"];
   _ctl_bestyle_on_functions.p_value=p:["bestyle_on_functions"];

   _suspend_modify=0;

   return(0);
}

static int _get_bestyle_tab_scheme(int (&p):[])
{
   // Begin/end style
   p:["disable_bestyle"]=_ctl_disable_bestyle.p_value;
   p:["be_style"]= -1;   // Undefined
   if ( _ctl_bestyle0.p_value ) {
      p:["be_style"]=CFBESTYLE0_FLAG;
   } else if ( _ctl_bestyle1.p_value ) {
      p:["be_style"]=CFBESTYLE1_FLAG;
   } else if ( _ctl_bestyle2.p_value ) {
      p:["be_style"]=CFBESTYLE2_FLAG;
   }
   p:["nospace_before_paren"]=_ctl_nospace_before_paren.p_value;
   p:["cuddle_else"]=_ctl_cuddle_else.p_value;
   p:["bestyle_on_functions"]=_ctl_bestyle_on_functions.p_value;

   return(0);
}


// Indenting

// We only use this event to notify _schemes_list of a modification to current scheme
_ctl_indent_with_tabs.lbutton_up()
{
   _modify_scheme();
}

// We only use this event to notify _schemes_list of a modification to current scheme
_ctl_syntax_indent.on_change()
{
   _modify_scheme();
}

_ctl_indent_access_specifier.on_change()
{
   _modify_scheme();
}

static int onCreateIndenting(int (&p):[])
{
   // Indenting
   _suspend_modify=1;

   _ctl_indent_with_tabs.p_value=p:["indent_with_tabs"];
   _ctl_indent_fl.p_value=p:["indent_fl"];
   _ctl_indent_case.p_value=p:["indent_case"];
   _ctl_syntax_indent.p_text=p:["syntax_indent"];
   _ctl_continuation_indent.p_text=p:["continuation_indent"];
   _ctl_align_on_parens.p_value=p:["align_on_parens"];
   _ctl_align_on_equal.p_value=p:["align_on_equal"];
#if 0
   p:["tabsize"]=p:["syntax_indent"];
#else
   if ( !isinteger(p:["tabsize"]) ) {
      p:["tabsize"]=p:["syntax_indent"];
   }
#endif
   int tabsize=p:["tabsize"];
   _ctl_tabsize.p_text=tabsize;
#if 1
   p:["orig_tabsize"]=p:["syntax_indent"];
#else
   if ( !isinteger(p:["orig_tabsize"]) ) {
      p:["orig_tabsize"]=p:["syntax_indent"];
   }
#endif
   int orig_tabsize=p:["orig_tabsize"];
   _ctl_orig_tabsize.p_text=orig_tabsize;

   _ctl_indent_access_specifier.p_visible = (_orig_lang == 'c');
   _ctl_indent_access_specifier.p_value=p:["indent_access_specifier"];

   _suspend_modify=0;

   return(0);
}

static int _get_indenting_tab_scheme(int (&p):[])
{
   // Indenting
   typeless indent_with_tabs=_ctl_indent_with_tabs.p_value;
   typeless indent_fl=_ctl_indent_fl.p_value;
   typeless indent_case=_ctl_indent_case.p_value;

   typeless syntax_indent=_ctl_syntax_indent.p_text;
   if ( !isinteger(syntax_indent) || syntax_indent<0 ) {
      _message_box('Invalid value for Syntax Indent');
      p_window_id=_ctl_syntax_indent;
      _set_sel(1,length(p_text)+1);_set_focus();
      return(1);
   }

   typeless continuation_indent=_ctl_continuation_indent.p_text;
   if ( !isinteger(continuation_indent) || continuation_indent<0 ) {
      _message_box('Invalid value for Continuation Indent');
      p_window_id=_ctl_continuation_indent;
      _set_sel(1,length(p_text)+1);_set_focus();
      return(1);
   }

   typeless result=0;
   typeless tabsize=_ctl_tabsize.p_text;
   if ( !isinteger(tabsize) || tabsize<0 ) {
      _message_box('Invalid value for Tab Size');
      p_window_id=_ctl_tabsize;
      _set_sel(1,length(p_text)+1);_set_focus();
      return(1);
   } else if ( syntax_indent!=tabsize ) {
      result=_message_box("You have selected tab stops which differ from the Syntax indent amount.\n\nAre you sure this is what you want?",
                          'Danger Will Robinson! Danger...  Danger',
                          MB_YESNOCANCEL|MB_ICONQUESTION);
      if ( result==IDCANCEL || result==IDNO ) {
         p_window_id=_ctl_tabsize;
         _set_sel(1,length(p_text)+1);_set_focus();
         return(1);
      }
   }

   typeless orig_tabsize=_ctl_orig_tabsize.p_text;
   if ( !isinteger(orig_tabsize) || orig_tabsize<0 ) {
      _message_box('Invalid value for Original Tab Size');
      p_window_id=_ctl_orig_tabsize;
      _set_sel(1,length(p_text)+1);_set_focus();
      return(1);
   }

   typeless align_on_parens=_ctl_align_on_parens.p_value;
   typeless align_on_equal=_ctl_align_on_equal.p_value;
   typeless indent_access_specifier=_ctl_indent_access_specifier.p_value;

   // Now set the options
   p:["indent_with_tabs"]=indent_with_tabs;
   p:["indent_fl"]=indent_fl;
   p:["indent_case"]=indent_case;
   p:["syntax_indent"]=(int)syntax_indent;
   p:["continuation_indent"]=(int)continuation_indent;
   p:["tabsize"]=(int)tabsize;
   p:["orig_tabsize"]=(int)orig_tabsize;
   p:["align_on_parens"]=align_on_parens;
   p:["align_on_equal"]=align_on_equal;
   p:["indent_access_specifier"]=indent_access_specifier;
   return(0);
}


// Comments
_ctl_abs_comment_col.lbutton_up()
{
   call_event(_control _ctl_statement_comment_col_enable,LBUTTON_UP);
}

_ctl_rel_comment_col.lbutton_up()
{
   call_event(_control _ctl_statement_comment_col_enable,LBUTTON_UP);
}

_ctl_statement_comment_col.on_change()
{
   _modify_scheme();
}

_ctl_statement_comment_col_enable.lbutton_up()
{
   // text box is enabled when check-box is checked
   _ctl_statement_comment_col.p_enabled= (_ctl_statement_comment_col_enable.p_value!=0);

   _modify_scheme();
}

_ctl_indent_comments.lbutton_up()
{
   _ctl_indent_col1_comments.p_enabled=(_ctl_indent_comments.p_value!=0);

   _modify_scheme();
}


static int onCreateComments(int (&p):[])
{
   // Comments
   _suspend_modify=1;

   _ctl_indent_comments.p_value=p:["indent_comments"];
   _ctl_indent_col1_comments.p_value=p:["indent_col1_comments"];
   int col=p:["statement_comment_col"];
   _ctl_statement_comment_col.p_text=col;
   _ctl_statement_comment_col_enable.p_value=0;
   _ctl_abs_comment_col.p_value=0;
   _ctl_rel_comment_col.p_value=0;
   if ( !isinteger(p:["statement_comment_state"]) ) {
      p:["statement_comment_state"]=CFCOMMENT_STATE_RELATIVE;
   }
   switch ( p:["statement_comment_state"] ) {
   case CFCOMMENT_STATE_SPECIFIC:
      _ctl_statement_comment_col_enable.p_value=1;
      break;
   case CFCOMMENT_STATE_ABSOLUTE:
      _ctl_abs_comment_col.p_value=1;
      break;
   case CFCOMMENT_STATE_RELATIVE:
      _ctl_rel_comment_col.p_value=1;
      break;
   }
   call_event(_control _ctl_indent_comments,LBUTTON_UP);
   call_event(_control _ctl_statement_comment_col_enable,LBUTTON_UP);

   _suspend_modify=0;

   return(0);
}

static int _get_comments_tab_scheme(int (&p):[])
{
   // Comments
   typeless indent_comments=_ctl_indent_comments.p_value;
   typeless indent_col1_comments=_ctl_indent_col1_comments.p_value;
   typeless statement_comment_col=_ctl_statement_comment_col.p_text;
   if ( !isinteger(statement_comment_col) || statement_comment_col<0 ) {
      _message_box('Invalid value for Comment Column');
      p_window_id=_ctl_statement_comment_col;
      _set_sel(1,length(p_text)+1);_set_focus();
      return(1);
   }

   // Now set the options
   p:["indent_comments"]=indent_comments;
   p:["indent_col1_comments"]=indent_col1_comments;
   p:["statement_comment_col"]=(int)statement_comment_col;
   p:["statement_comment_state"]=-1;   // Undefined
   if ( _ctl_statement_comment_col_enable.p_value ) {
      p:["statement_comment_state"]=CFCOMMENT_STATE_SPECIFIC;
   } else if ( _ctl_abs_comment_col.p_value ) {
      p:["statement_comment_state"]=CFCOMMENT_STATE_ABSOLUTE;
   } else if ( _ctl_rel_comment_col.p_value ) {
      p:["statement_comment_state"]=CFCOMMENT_STATE_RELATIVE;
   }
   p:["use_relative_indent"]=_ctl_rel_comment_col.p_value;

   return(0);
}


// Preprocessing, and Advanced
_ctl_indent_pp.lbutton_up()
{
   _ctl_indent_pp_inside_braces.p_enabled= (p_value!=0);
   _ctl_indent_idempotent_block.p_enabled= (p_value!=0);

   _modify_scheme();
}

_ctl_indent_pp_inside_braces.lbutton_up()
{
   _modify_scheme();
}

_ctl_indent_idempotent_block.lbutton_up()
{
   _modify_scheme();
}

_ctl_eat_pp_space.lbutton_up()
{
   _modify_scheme();
}

_ctl_parens_on_return.lbutton_up()
{
   _modify_scheme();
}

_ctl_insert_padding.lbutton_up()
{
   _modify_scheme();
}

_ctl_remove_padding.lbutton_up()
{
   call_event(_control _ctl_insert_padding,LBUTTON_UP);
}

_ctl_leave_padding_alone.lbutton_up()
{
   call_event(_control _ctl_insert_padding,LBUTTON_UP);
}

static int onCreateAdvanced(int (&p):[])
{
   _suspend_modify=1;

   // Preprocessing
   _ctl_indent_pp.p_value=p:["indent_pp"];
   _ctl_indent_pp_inside_braces.p_value=p:["indent_pp_inside_braces"];
   _ctl_indent_idempotent_block.p_value=p:["indent_idempotent_block"];
   _ctl_eat_pp_space.p_value=p:["eat_pp_space"];
   _ctl_frame_pp.p_enabled= (_orig_lang!="js");
   _ctl_indent_pp.p_enabled= (_orig_lang!="js");
   _ctl_indent_pp_inside_braces.p_enabled= (p:["indent_pp"]!=0 && _orig_lang!="js");
   _ctl_indent_idempotent_block.p_enabled= (p:["indent_pp"]!=0 && _orig_lang!="js");
   _ctl_eat_pp_space.p_enabled= (_orig_lang!="js");

   // Parens on return
   _ctl_parens_on_return.p_value=p:["parens_on_return"];

   // Pad condition
   _ctl_insert_padding.p_value=0;
   _ctl_remove_padding.p_value=0;
   _ctl_leave_padding_alone.p_value=0;
   if ( !isinteger(p:["pad_condition_state"]) ) {
      p:["pad_condition_state"]=CFPADCONDITION_STATE_NOCHANGE;
   }
   //messageNwait('pad_condition_state='p:["pad_condition_state"]);
   switch ( p:["pad_condition_state"] ) {
   case CFPADCONDITION_STATE_INSERT:
      _ctl_insert_padding.p_value=1;
      break;
   case CFPADCONDITION_STATE_REMOVE:
      _ctl_remove_padding.p_value=1;
      break;
   case CFPADCONDITION_STATE_NOCHANGE:
      _ctl_leave_padding_alone.p_value=1;
      break;
   }
   call_event(_control _ctl_insert_padding,LBUTTON_UP);

   _suspend_modify=0;

   return(0);
}

static int _get_advanced_tab_scheme(int (&p):[])
{
   // Preprocessing
   p:["indent_pp"]=_ctl_indent_pp.p_value;
   p:["indent_pp_inside_braces"]=_ctl_indent_pp_inside_braces.p_value;
   p:["indent_idempotent_block"]=_ctl_indent_idempotent_block.p_value;
   p:["eat_pp_space"]=_ctl_eat_pp_space.p_value;

   // Parens on return
   p:["parens_on_return"]=_ctl_parens_on_return.p_value;

   // Pad condition
   if ( _ctl_insert_padding.p_value ) {
      p:["pad_condition_state"]=CFPADCONDITION_STATE_INSERT;
   } else if ( _ctl_remove_padding.p_value ) {
      p:["pad_condition_state"]=CFPADCONDITION_STATE_REMOVE;
   } else if ( _ctl_leave_padding_alone.p_value ) {
      p:["pad_condition_state"]=CFPADCONDITION_STATE_NOCHANGE;
   }
   p:["pad_condition"]=_ctl_insert_padding.p_value;
   p:["nopad_condition"]=_ctl_remove_padding.p_value;

   return(0);
}


// Schemes
static int onCreateSchemes()
{
   // Schemes
   _ctl_schemes_list.p_user='';
   _schemes._makeempty();
   _user_schemes._makeempty();

   // Get the last scheme used
   if ( !_ini_get_value(FormatUserIniFilename(),_orig_lang:+'-scheme-Default','last_scheme',_cur_scheme) ) {
#if 0   // Can't do this because _schemes and _user_schemes are not filled in yet
      // Check if scheme name is valid
      if ( !_schemes._indexin(_cur_scheme) && !_user_schemes._indexin(_cur_scheme) ) {
         // Scheme does not exist
         _cur_scheme=CF_NONE_SCHEME_NAME;
      }
#endif
   } else {
      _cur_scheme=CF_NONE_SCHEME_NAME;
   }
   _orig_scheme=_cur_scheme;   // Save this for the Reset button

   typeless i;
   if ( !_get_scheme(_schemes,'',_orig_lang) ) {
      for ( i._makeempty();; ) {
         _schemes._nextel(i);
         if ( i._isempty() ) break;
         _ctl_schemes_list._lbadd_item(i);
      }
   }
   if ( !_get_user_scheme(_user_schemes,'',_orig_lang) ) {
      for ( i._makeempty();; ) {
         _user_schemes._nextel(i);
         if ( i._isempty() ) break;
         // We don't want to blast the default scheme because it is already set
         if ( i!=CF_DEFAULT_SCHEME_NAME ) {
            _ctl_schemes_list._lbadd_item(i);
         }
      }
   }
   _ctl_schemes_list._lbsort();
   _ctl_schemes_list.p_text=_cur_scheme;

   return(0);
}

/**
 * <P>
 * This function is common to all beautifiers/formatters.
 * </P>
 *
 * @return The absolute path of the system config file.
 */
_str FormatSystemIniFilename()
{
   _str vsroot=get_env('VSROOT');
   if ( last_char(vsroot)!=FILESEP ) vsroot=vsroot:+FILESEP;
   _str filename=vsroot:+FORMAT_INI_FILENAME;

   return(filename);
}

/**
 * <P>
 * This function is common to all beautifiers/formatters.
 * </P>
 *
 * @return The absolute path of the user config file.
 */
_str FormatUserIniFilename()
{
   if ( _format_user_ini_filename!=null ) {
      // We are reading from the newest user config file
      return(_format_user_ini_filename);
   }

   _str filenopath=VSCFGFILE_USER_BEAUTIFIER;

   _format_user_ini_filename=usercfg_path_search(filenopath);

   return(_format_user_ini_filename);
}

/**
 * <P>
 * This function is common to all beautifiers/formatters.
 * </P>
 *
 * @return The absolute path of the admin config file.
 */
_str FormatAdminIniFilename()
{
   _str vsroot=get_env('VSROOT');
   if ( last_char(vsroot)!=FILESEP ) vsroot=vsroot:+FILESEP;
   _str filename=vsroot:+"format-admin.ini";

   return(filename);
}

/**
 * <P>
 * This function is common to all beautifiers/formatters.
 * </P>
 *
 * <P>
 * Create the local user config ini file if necessary.
 * </P>
 *
 * @return The absolute path of the local user config file.
 */
_str MaybeCreateFormatUserIniFile()
{
   int status=0;
   _str filenopath=VSCFGFILE_USER_BEAUTIFIER;

   usercfg_init_write(filenopath);

   _str filename=_ConfigPath():+filenopath;
   if ( file_match("-p "maybe_quote_filename(filename),1)=="" ) {
      // Doesn't exist so create it
      int temp_view_id=0;
      int orig_view_id=_create_temp_view(temp_view_id);
      p_buf_name=filename;
      insert_line(';');
      insert_line('; C/C++/Java/JavaScript/Slick-C Beautifier note:');
      insert_line(';');
      insert_line('; Options not currently implemented:');
      insert_line(';');
      insert_line('; decl_comment_col');
      insert_line('; nospace_before_brace');
      insert_line(';');
      insert_line(';');
      insert_line(';');
      insert_line('; Explanation of statement_comment_state:');
      insert_line(';   3-state radio button group for statement comment column');
      insert_line(';   Can be one of 3 values:');
      insert_line(';     0=column');
      insert_line(';     1=absolute');
      insert_line(';     2=relative');
      insert_line('');
      status=_save_config_file();
      if ( status ) {
         _message_box('Failed to save user config file "':+filename:+'". ':+get_message(status),"",MB_OK|MB_ICONEXCLAMATION);
         filename='';
      }
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
   }

   if ( status ) {
      return('');
   }
   _format_user_ini_filename=filename;

   return(filename);
}

static int _write_scheme(int p:[],int sync_lang_options,_str section_name)
{
   int status=0;

   if ( sync_lang_options ) {
      parse section_name with auto lang '-' .;
      // Syntax indent
      LanguageSettings.setSyntaxIndent(lang, p:["syntax_indent"]);
      updateList := SYNTAX_INDENT_UPDATE_KEY'='p:["syntax_indent"]',';

      // Begin/end style
      be_style := 0;
      switch ( p:["be_style"] ) {
      case CFBESTYLE1_FLAG:
         be_style = BES_BEGIN_END_STYLE_2;
         break;
      case CFBESTYLE2_FLAG:
         be_style = BES_BEGIN_END_STYLE_3;
         break;
      }
      LanguageSettings.setBeginEndStyle(lang, be_style);
      updateList :+= BEGIN_END_STYLE_UPDATE_KEY'='be_style',';
      
      LanguageSettings.setNoSpaceBeforeParen(lang, p:["nospace_before_paren"] != 0);
      updateList :+= NO_SPACE_BEFORE_PAREN_UPDATE_KEY'='(p:["nospace_before_paren"] != 0)',';

      // Indent first level
      LanguageSettings.setIndentFirstLevel(lang, p:["indent_fl"]);

      // Indent case from switch
      LanguageSettings.setIndentCaseFromSwitch(lang, p:["indent_case"] != 0);
      updateList :+= INDENT_CASE_FROM_SWITCH_UPDATE_KEY'='p:["indent_case"]',';

      _config_modify_flags(CFGMODIFY_DEFDATA);

      LanguageSettings.setIndentWithTabs(lang, p:["indent_with_tabs"]!=0);
      updateList :+= INDENT_WITH_TABS_UPDATE_KEY'='p:["indent_with_tabs"]',';

      _update_buffers(lang,updateList);
   }

   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if ( orig_view_id=='' ) {
      _message_box('Error creating temp view');
      return(1);
   }

   // Write the values
   _delete_line();
   typeless i;
   for ( i._makeempty();; ) {
      p._nextel(i);
      if ( i._isempty() ) break;
      //messageNwait('inserting p:['i']='p:[i]);
      insert_line(i:+'=':+p:[i]);
   }

   p_window_id=orig_view_id;

   // Do not need to use _delete_temp_view() because _ini_put_section() will get rid of it for us
   // Don't need to worry if the file does not exist, _ini_put_section() will create it
   status=_ini_put_section(FormatUserIniFilename(),section_name,temp_view_id);
   if ( status ) {
      _message_box(nls("Unable to update file %s.",FormatUserIniFilename())"  "get_message(status),"Error",MB_OK|MB_ICONEXCLAMATION);
      return(status);
   }

   return(0);
}

static int _get_form_scheme(int (&p):[])
{
   _get_bestyle_tab_scheme(_form_options);
   if (_get_indenting_tab_scheme(_form_options)) {
      return(1);
   }
   if (_get_comments_tab_scheme(_form_options)) {
      return(1);
   }
   _get_advanced_tab_scheme(_form_options);

   // Others not supported now, but have to be filled in
   p:["eat_blank_lines"]=0;
   p:["nospace_before_brace"]=0;
   p:["decl_comment_col"]=0;

   return(0);
}

/* Adust the values according to dialog settings so that they can be
 * passed to _format()
 */
static int _adjust_scheme(int (&p):[])
{
   // Begin/end style
   p:["brace_indent"]=0;
   if ( p:["disable_bestyle"] ) {
      p:["be_style"]=0;
   } else if ( p:["be_style"]==CFBESTYLE2_FLAG ) {
      p:["brace_indent"]=p:["syntax_indent"];
   }

   // Indenting
   int indent=p:["syntax_indent"];
   if ( !isinteger(indent) || indent<0 ) {
      p:["syntax_indent"]=3;   // Need to change this
   }
   indent=p:["continuation_indent"];
   if ( !isinteger(indent) || indent<0 ) {
      p:["continuation_indent"]=0;
   }

   // Comments
   if ( p:["statement_comment_state"]==CFCOMMENT_STATE_SPECIFIC ) {
      int col=p:["statement_comment_col"];
      if ( !isinteger(col) || col<0 ) {
         p:["statement_comment_col"]=0;
      }
   } else {
      p:["statement_comment_col"]=0;
   }

   return(0);
}

static boolean _user_scheme_exists(_str name,_str lang)
{
   boolean exists;
   int temp_view_id=0;
   int orig_view_id=0;
   if ( FormatSystemIniFilename()=='' || _open_temp_view(FormatSystemIniFilename(),temp_view_id,orig_view_id) ) {
      return(false);
   }

   _str ss=lang:+'-scheme-':+name;
   exists= (_ini_find_section(ss)==0);

   // Delete the temp view
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return(exists);
}

static int _get_scheme(scheme_s (&p):[],_str name,_str lang)
{
   int temp_view_id=0;
   int orig_view_id=0;
   if ( FormatSystemIniFilename()=='' || _open_temp_view(FormatSystemIniFilename(),temp_view_id,orig_view_id) ) {
      return(1);
   }

   _str prefix=lang:+'-scheme-';
   _get_scheme2(p,prefix,name);

   // Delete the temp view
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return(0);
}

static int _get_user_scheme(scheme_s (&p):[],_str name,_str lang)
{
   int temp_view_id=0;
   int orig_view_id=0;
   if ( FormatUserIniFilename()=='' || _open_temp_view(FormatUserIniFilename(),temp_view_id,orig_view_id) ) {
      return(1);
   }

   _str prefix=lang:+'-scheme-';
   int status=_get_scheme2(p,prefix,name);

   // Delete the temp view
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return(status);
}

static int _get_scheme2(scheme_s (&p):[],_str prefix,_str name)
{
   _str ss='';
   if ( name!='' ) {
      ss=prefix:+name;
   }

   top();
   boolean found_one=0;
   do {
      if ( _ini_find_section(ss) ) {
         break;
      }
      _str line='';
      get_line(line);
      _str section_name='';
      parse line with '[' section_name ']';
      _str scheme_name='';
      parse section_name with (prefix) scheme_name;
      if ( scheme_name=='' ) {
         // Not a valid scheme
         if ( down() ) break;   // Bottom of file, so done!
         continue;
      }
      found_one=1;
      down();   // Move off the section line
      int sl=p_line;
      // Now find the next section so we can bracket this section
      if ( _ini_find_section('') ) {
         bottom();
      } else {
         up();   // Move off the the next section name
      }
      int el=p_line;

      // Get the values
      p_line=sl;
      while ( p_line<=el ) {
         get_line(line);
         line=strip(line,'L');
         if ( line=='' || substr(line,1,1)==';' ) {
            // Blank line OR comment line
            if ( down() ) break;  // Done!
            continue;
         }
         parse line with line ';' .;   // Get rid of a trailing comment (not sure if we need this)
         _str varname='';
         typeless val='';
         parse line with varname '=' val;
         if ( val=='' || !isinteger(val) ) {
            if ( down() ) break;   // Done!
            continue;   // Not a valid value
         }
         varname=lowcase(varname);
         p:[scheme_name].options:[varname]=val;
         if ( down() ) break;   // Done!
      }
   } while ( name=='' );

   if ( !found_one ) {
      return(1);
   }
   return(0);
}

static void _modify_scheme()
{
   if ( _suspend_modify ) return;   // Modification temporarily suspended
   _str name=_ctl_schemes_list.p_text;
   if ( !pos('(Modified)',name,1,'I') && name!=CF_NONE_SCHEME_NAME ) {
      name=strip(name,'B'):+' (Modified)';
      _ctl_schemes_list.p_text=name;
      _ctl_schemes_list.p_user=name;
   }
}

static _str system_schemes;   // List of system schemes that are read-only
static _str user_schemes;     // List of user schemes that we must prompt to overwrite
defeventtab _beautify_save_scheme_form;
// arg(1) is initial value of scheme name to save
// arg(2)!='' means to do a rename instead of a save
// arg(3)!='' is a list of system schemes (read-only)
// arg(4)!='' is a list of user schemes   (prompt for overwrite)
_ctl_save.on_create(_str schemeName='', _str doRename='', ...)
{
   _ctl_schemes.p_text=schemeName;
   if ( isinteger(doRename) && doRename ) {
      p_active_form.p_caption='Rename Scheme';
   }
   system_schemes='';
   user_schemes='';
   if ( arg()>2 ) {
      system_schemes=arg(3);
   }
   if ( arg()>3 ) {
      user_schemes=arg(4);
   }
   _str list=user_schemes;
   while ( list!='' ) {
      _str name=parse_file(list,false);
      //parse list with name list;
      _ctl_schemes._lbadd_item(name);
   }
   _ctl_schemes._lbsort();
}

_ctl_save.on_destroy()
{
}

void _ctl_schemes.on_change(int reason)
{
   _str name=_ctl_schemes.p_text;
   if ( name!='' ) {
      _ctl_save.p_enabled=1;
   } else {
      _ctl_save.p_enabled=0;
   }
}

_ctl_save.lbutton_up()
{
   _str name=strip(_ctl_schemes.p_text,'B');
   if ( pos(' "'name'" ',system_schemes,1,'I') ) {
      _message_box('System schemes cannot be removed.');
      return('');
   }
   if ( pos(' "'name'" ',user_schemes,1,'I') ) {
      int status=_message_box('Overwrite existing scheme "'name'"?','',MB_YESNO|MB_ICONQUESTION);
      if ( status==IDNO ) {
         return('');
      }
   } else if ( pos('(Modified)',name,1,'I') ) {
      // Invalid name, try again
      _message_box('Invalid name');
      return('');
   }
   p_active_form._delete_window(name);
}

// Converts .java, .js, .cs, and .e  languages to .c
#define DEFAULT_BEAUTIFIER_EXT  "phpscript=c ada=ada c=c java=c js=c cs=c e=c html=html cfml=html xml=html xsd=html vpj=xml docbook=xml ant=xml as=c d=c android=xml"   /* Valid beautifier languages */
int BeautifyCheckSupport(_str &lang)
{
   lang=eq_name2value(lang,DEFAULT_BEAUTIFIER_EXT);
   if ( lang=='' ) {
      return(1);
   }

   return(0);
}

#define DEFAULT_BEAUTIFIER_LANGUAGES  "ada c java js cs e html cfml xml xsd ant d m"   /* Valid beautifier languages */
defeventtab _beautify_extension_form;
_ctl_ok.on_create()
{
   foreach ( auto lang in DEFAULT_BEAUTIFIER_LANGUAGES ) {
      _ctl_language._lbadd_item(_LangId2Modename(lang));
   }

   _ctl_language._lbsort();
   _ctl_language._lbtop();
   _ctl_language._lbselect_line();
}

_ctl_ok.on_destroy()
{
}

_ctl_ok.lbutton_up()
{
   name := _ctl_language._lbget_seltext();
   lang := _Modename2LangId(name);
   p_active_form._delete_window(lang);
}

_ctl_language.lbutton_double_click()
{
   call_event(_control _ctl_ok,LBUTTON_UP);
}

const PROFILE_SUBMENU = "BeautifyWithSubmenu";
const PROFILE_BEAUTMENN = "BeautifyItem";

void _init_menu_nbeautifier(int menu_handle, int no_child_windows)
{
   _str lang = p_LangId;
   boolean handled_by_new  = new_beautifier_supported_language(lang);
   boolean handled_by_orig = handled_by_new || BeautifyCheckSupport(lang);
    
   // find neighbor of Beautify With, to get it's position and also the tool menu handle
   status := _menu_find(menu_handle, 'beautifier-edit-current-profile', auto beaut_handle, auto beaut_pos, 'M');

   if (status < 0) {
      return;
   }

   // Kill beautify-with submenu if it already exists.
   status = _menu_find(beaut_handle, PROFILE_SUBMENU, auto xh, auto exist_pos);

   if (status >= 0) {
      status = _menu_delete(beaut_handle, exist_pos);
      if (status < 0) {
         return;
      }
   }

   // Kill Beautify item if it already exists.
   status = _menu_find(beaut_handle, PROFILE_BEAUTMENN, xh, exist_pos);
   if (status >= 0) {
      status = _menu_delete(beaut_handle, exist_pos);
      if (status < 0) {
         return;
      }
   }

   if (handled_by_new) {
      // Use that position and handle to add the submenu.
      bw_handle := _menu_insert(beaut_handle, 0, MF_SUBMENU, "Beautify With", '', PROFILE_SUBMENU,
                                '', "Beautifies the buffer with the profile associated with this language.");

      if (bw_handle < 0) {
         return;
      }

      int i;
      profiles := beautifier_profiles_for(lang);
      for (i = 0; i < profiles._length(); i++) {
         p := profiles[i];
         _menu_insert(bw_handle, -1, MF_ENABLED, p, 'beautify-with-profile 'p'', 
                      '', '', 'Beautifies current buffer with the "'p'" profile.');
      }
   }

   // Create Beautify entry with profile name in the text.
   _str caption = 'Beautify';

   prof := LanguageSettings.getBeautifierProfileName(lang);
   if (handled_by_new) {
      caption = caption' ('prof')';
   }
   bi_handle := _menu_insert(beaut_handle, 0, MF_ENABLED, caption, "beautify", PROFILE_BEAUTMENN, '',
                             'Beautifies the buffer with the profile associated with this language.');
   if (bi_handle < 0) {
      return;
   }
}


_command void beautifier_options() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if (new_beautifier_supported_language(p_LangId)) {
      new_beautifier_options();
   } else {
      gui_beautify();
   }
}


_OnUpdate_beautifier_options(CMDUI cmdui,int target_wid,_str command)
{
   return _OnUpdate_beautify(cmdui,target_wid,command);
}
