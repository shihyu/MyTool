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
#import "se/lang/api/LanguageSettings.e"
#import "adaformat.e"
#import "adaptiveformatting.e"
#import "beautifier.e"
#import "codehelp.e"
#import "cutil.e"
#import "files.e"
#import "help.e"
#import "html.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "savecfg.e"
#import "cfg.e"
#import "seldisp.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagrefs.e"
#import "tags.e"
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

static const CFDEBUG_WINDOW=   0;
static const CFDEBUG_FILE=     0;

static const CFDEBUGFLAG_WINDOW= 0x1000;
static const CFDEBUGFLAG_FILE=   0x2000;

static const CFFLAG_REMEMBER_SEEKPOS= 0x8000;

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

static const CFCOMMENT_STATE_SPECIFIC= 0;
static const CFCOMMENT_STATE_ABSOLUTE= 1;
static const CFCOMMENT_STATE_RELATIVE= 2;

static const CFPADCONDITION_STATE_INSERT=   0;
static const CFPADCONDITION_STATE_REMOVE=   1;
static const CFPADCONDITION_STATE_NOCHANGE= 2;

//static int _mycheck_tabs(int :[]);
//static int _get_scheme(scheme_s (&):[],_str);
//static int _format(int :[],_str,_str,_str,_str,int,_str);

static bool gUserIniInitDone;

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
 */
_str _ext2modename2(_str ext,int &setup_index)
{
   lang := _Ext2LangId(ext);
   modename := _LangGetModeName(lang);
   if (modename=='C') {
      modename='C/C++';
   }
   return(modename);
}
int _OnUpdate_beautify(CMDUI cmdui,int target_wid,_str command)
{
   if ( !_haveBeautifiers() ) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return (MF_GRAYED | MF_REQUIRES_PRO);
   }

   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   idname:=target_wid._ConcurProcessName();
   if (idname!=null && translate(command,'-','_')!='beautifier-options') {
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
   lang := target_wid.p_LangId;
   if ( lang!="" && lang!="fundamental" && 
        (BeautifyCheckSupport(lang) && !new_beautifier_supported_language(target_wid.p_LangId)) ) 
      return(MF_GRAYED);

   return(MF_ENABLED);
}
int _OnUpdate_beautify_with_profile(CMDUI cmdui,int target_wid,_str command)
{
   return _OnUpdate_beautify(cmdui,target_wid,command);
}

/**
 * Beautifies the current buffer using the current 
 * options.
 * 
 * @see beautify_selection
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods 
 *  
 */
_command int beautify(bool quiet=false) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBeautifiers()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Beautify");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   _ExitScroll();
   msg := "";
   lang := p_LangId;

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
   index := find_index(lang'_beautify',COMMAND_TYPE);
   if ( !index ) {
      if ( !quiet ) {
         msg="Cannot find command: "lang"_beautify";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return 1;
   }

   // save bookmark, breakpoint, and annotation information
   _SaveMarkersInFile(auto markerSaves);

   status := 0;
   if ( _LanguageInheritsFrom('c',lang) ) {
      status=call_index(0,0,-1,quiet,index);
   } else if ( _LanguageInheritsFrom('html',lang) ) {
      status=call_index(0,0,"",-1,quiet,index);
   } else if ( _LanguageInheritsFrom('ada',lang) ) {
      status=call_index(0,0,-1,quiet,index);
   } else {
      // This just means that we do not know the position of the quiet option
      // for this beautifier function, so it will not be quiet.
      status=call_index(index);
   }

   // restore bookmarks, breakpoints, and annotation locations
   _RestoreMmrkersInFile(markerSaves);

   // Finally update adaptive formatting and we are done
   adaptive_format_reset_buffers();
   return status;
}

_OnUpdate_beautify_selection(CMDUI cmdui,int target_wid,_str command)
{
   return(_OnUpdate_beautify(cmdui,target_wid,command));
}
/**
 * Beautifies the current selection using the current options.  If there is 
 * no current selection the entire buffer is beautified.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods 
 *  
 */
_command int beautify_selection(...) name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBeautifiers()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Beautify");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   _ExitScroll();
   lang := p_LangId;
   msg := "";

   if (!select_active()) {
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
   index := find_index(lang'_beautify_selection',COMMAND_TYPE);
   if ( !index ) {
      msg="Cannot find command: "lang"_beautify_selection";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   currentLine := p_line;
   _begin_select("", true, false);
   startLine := p_line;
   _end_select("", true, false);
   endLine := p_line;
   p_line = currentLine;

   // save bookmark, breakpoint, and annotation information
   _SaveMarkersInFile(auto markerSaves, startLine, endLine);

   status := call_index(index);

   // restore bookmarks, breakpoints, and annotation locations
   _RestoreMmrkersInFile(markerSaves);

   // Finally update adaptive formatting and we are done
   p_line = currentLine;
   adaptive_format_reset_buffers();
   return status;
}

int _OnUpdate_ada_beautify(CMDUI cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_GRAYED;
   }
   if(target_wid._ConcurProcessName()!=null) { 
      return(MF_GRAYED);
   }

   lang := target_wid.p_LangId;
   return ( _LanguageInheritsFrom('ada',lang)?MF_ENABLED:MF_GRAYED );
}
int _OnUpdate_ada_format(CMDUI cmdui,int target_wid,_str command) {
   return _OnUpdate_ada_beautify(cmdui,target_wid,command);
}


int _OnUpdate_c_beautify(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !_haveBeautifiers() ) {
      return (MF_GRAYED | MF_REQUIRES_PRO);
   }

   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   if(target_wid._ConcurProcessName()!=null) { 
      return(MF_GRAYED);
   }

   lang := target_wid.p_LangId;
   return((lang=='c' || lang=='d' || lang=='java' || lang=='js' || lang=='cs' || lang=='e')?MF_ENABLED:MF_GRAYED);
}
int _OnUpdate_c_format(CMDUI cmdui,int target_wid,_str command) {
   return _OnUpdate_c_beautify(cmdui,target_wid,command);
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
_command int c_format,c_beautify,ada_format,ada_beautify(int in_wid=0, int start_indent=0, int ibeautifier=-1, bool quiet=false) name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBeautifiers()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Beautify");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (new_beautifier_supported_language(p_LangId)) {
      return beautify(quiet);
   }

   //struct scheme_s s:[];
   //s._makeempty();

   if ( p_Nofhidden ) {
      show_all();
   }

   old_modify := p_modify;   // Save in the case of doing the entire buffer so we can set it back when we "undo"
   old_left_edge := p_left_edge;
   old_cursor_y := p_cursor_y;
   save_pos(auto p);

   infilename := "";
   outfilename := "";
   editorctl_wid := p_window_id;
   if (!_isEditorCtl()) {
      editorctl_wid=0;
   }
   do_destroy_on_ibeautifier := false;

   // Do the current buffer
   status := 0;
   msg := "";
   lang := "";
   orig_lang := "";
   typeless sync_lang_options='';
   typeless linenum;
   if ( ibeautifier<0 ) {
      if ( !_isEditorCtl() ) {
         if ( !quiet ) {
            _message_box('No buffer!');
         }
         return(1);
      }
      lang=p_LangId;
      orig_lang=p_LangId;
      if ( BeautifyCheckSupport(lang) ) {
         if ( !quiet ) {
            _message_box('Beautifying not supported for ':+p_mode_name);
         }
         return(1);
      }

      // Sync with language options?
      sync_lang_options=true;

      // Get [[lang]-scheme-Default] section and put into s
      ibeautifier=_beautifier_create(p_LangId);
      profile_name:=_beautifier_get_buffer_profile(p_LangId,p_buf_name);
      if (profile_name=='') profile_name='Default';
      status=_beautifier_set_properties(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(p_LangId),profile_name);
      if (status != 0) {
         _beautifier_destroy(ibeautifier);
         return status;
      }
      do_destroy_on_ibeautifier=true;
      //_adjust_scheme(s:[CF_DEFAULT_SCHEME_NAME].options);
   } else {
      lang=p_LangId;
      BeautifyCheckSupport(lang);
      orig_lang=p_LangId;   // The correct DLL function will not get called unless we set this properly
   }

   /*if ( _mycheck_tabs(editorctl_wid,s:[CF_DEFAULT_SCHEME_NAME].options,quiet) ) {
      return(1);
   } */

   // Switch to temp view
   orig_view_id := p_window_id;
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
   start_linenum := p_line;
   //messageNwait('start_linenum='start_linenum);
   bottom();
   last_line_was_bare := (_line_length()==_line_length(true));
   utf8 := p_UTF8;
   int encoding=p_encoding;
   // Create a temporary view for beautifier output *with* p_undo_steps=0
   arg2 := "+td";   // DOS \r\n linebreak
   if ( length(p_newline)==1 ) {
      if ( substr(p_newline,1,1)=='\r' ) {
         arg2='+tm';   // Macintosh \r linebreak
      } else {
         arg2='+tu';   // UNIX \n linebreak
      }
   }
   output_view_id := 0;
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

   mou_hour_glass(true);
   status=_format(ibeautifier,
                  orig_lang,
                  encoding,
                  infilename,
                  0,   // Input view id
                  outfilename,
                  start_indent,
                  start_linenum);
   mou_hour_glass(false);
   if (do_destroy_on_ibeautifier) {
      _beautifier_destroy(ibeautifier);ibeautifier=-1;
   }

   // Cleanup temp files that were created
   delete_file(infilename);   // Delete the temp file
   if ( !_line_length(true) ) {
      // Get rid of the zero-length line at the bottom
      _delete_line();
   }
   if (lang=='ada') {
      msg=vsadaformat_iserror();
   } else {
      msg=vscf_iserror();
   }
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

static int _format(int  ibeautifier,
                   _str lang,
                   int  orig_encoding,
                   _str infilename,
                   _str in_wid,
                   _str outfilename,
                   int  start_indent,
                   int  start_linenum)
{
   if (lang=='ada') {
      return _format_ada(ibeautifier,lang,orig_encoding,infilename,in_wid,outfilename,start_indent,start_linenum);
   }
   typeless flags=_merge_flags(ibeautifier);

   debugfilename := "";
   vse_flags := 0;
   if ( CFDEBUG_WINDOW || CFDEBUG_FILE ) {
      if ( CFDEBUG_WINDOW ) {
         vse_flags|=CFDEBUGFLAG_WINDOW;
      }
      if ( CFDEBUG_FILE ) {
         vse_flags|=CFDEBUGFLAG_FILE;
      }
   }

   status := 0;
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

static int _find_begin_pp_context(int sl, int el, bool quiet=false)
{
   int old_mark = _duplicate_selection('');
   int mark = _alloc_selection();
   p_line=sl;
   _select_line(mark);
   p_line=el; _end_line();
   _select_line(mark);

   status := 0;
   while ( p_line>sl ) {

      _show_selection(mark);
      status=search('^[ \t]@\#[ \t]@(endif|else|elif)','@hXCSrm-');
      _show_selection(old_mark);
      if ( status!=0 ) {
         break;
      }

      // Found a #endif/#else/#elif, so match with the correct #if
      pp_line := p_line;
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
      nesting := 0;
      while ( status==0 ) {
         word := get_match_text(0);
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

static int _find_begin_context(_str mark, int& sl, int& el, bool quiet=false)
{
   int old_sl=sl;
   int old_el=el;

   _begin_select(mark);
   _begin_line();   // Goto to beginning of line so not fooled by start of comment

   /* If we are in the middle of a multi-line comment,
    * then skip to beginning of it
    */
   if ( _in_comment(true) ) {
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

static int _find_end_context(_str mark, int &sl, int &el, bool quiet=false)
{
   int old_sl=sl;
   int old_el=el;

   _end_select(mark);
   _end_line();   // Goto end of line so not fooled by start of comment

   /* If we are in the middle of a multi-line comment,
    * then skip to end of it
    */
   if ( _in_comment(true) ) {
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
                                bool &last_line_was_bare,
                                bool quiet=false)
{
   last_line_was_bare=false;
   save_pos(auto p);
   old_linenum := p_line;
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
         start_col := 0;
         end_col := 0;
         dummy := 0;
         _get_selinfo(start_col,end_col,dummy);
         if ( end_col==1 ) {
            // Throw out the last line of the selection
            _deselect(context_mark);
            _begin_select();
            startmark_linenum := p_line;
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
   sl := p_line;   // start line
   _end_select(context_mark);
   el := p_line;   // end line
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
   tl := p_line;   // Top line
   //soc_linenum=tl;
   soc_linenum=sl;
   int diff=old_linenum-tl;
   _select_line(mark);
   _begin_select(context_mark);
   _first_non_blank();
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
   last_line_was_bare= (_line_length()==_line_length(true));

   //messageNwait('orig_sl='orig_sl'  orig_el='orig_el'  tl='tl'  sl='sl'  el='el);

   // Create a temporary view to hold the code selection and move it there
   arg2 := "+td";   // DOS \r\n linebreak
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
   utf8 := 0;
   encoding := 0;
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
   p_line += diff+2;   // +2 to adjust for the CFORMAT-SUSPEND-WRITE and CFORMAT-RESUME-WRITE above
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
   last_line_was_empty := 0;
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
_command int c_format_selection,c_beautify_selection(int ibeautifier=-1, bool quiet=false) name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBeautifiers()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Beautify");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (new_beautifier_supported_language(p_LangId)) {
      if (select_active()) {
         return new_beautify_selection();
      } else {
         beautify_current_buffer();
         return 0;
      }
   }

   if ( !select_active() ) {
      return(c_format(0,0,ibeautifier,quiet));
   }

   if( p_Nofhidden ) {
      show_all();
   }

   save_pos(auto p);
   orig_view_id := p_window_id;
   old_left_edge := p_left_edge;
   old_cursor_y := p_cursor_y;

   _begin_select();
   tom_linenum := p_line;
   restore_pos(p);

   // Find the context
   temp_view_id := 0;
   typeless context_mark=0;
   soc_linenum := 0;
   last_line_was_bare := false;
   if ( _create_context_view(temp_view_id,context_mark,soc_linenum,last_line_was_bare,quiet) ) {
      _message_box('Failed to derive context for selection');
      return(1);
   }

   mark := 0;
   old_mark := 0;
   start_indent := 0;
   new_linenum := 0;
   error_linenum := 0;
   restore_pos(p);   // Do this before calling c_format() so don't end up somewhere funky
   int status=c_format(temp_view_id,start_indent,ibeautifier,quiet);
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
      new_linenum += soc_linenum-1;
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
         error_linenum += soc_linenum-1-2;
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

static int _mycheck_tabs(int editorctl_wid, int p:[], bool quiet=false)
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
      interval := 0;
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

static const CFFLAG_INDENT_CASE=              "ic";     /* indent-case                        */
static const CFFLAG_INDENT_FL=                "if";     /* indent-first-level                 */
static const CFFLAG_INDENT_WITH_TABS=         "it";     /* indent-with-tabs                   */
static const CFFLAG_NOSPACE_BEFORE_PAREN=     "nsp";    /* nospace-before-paren               */
static const CFFLAG_PAD_CONDITION=            "pc";     /* pad-condition                      */
static const CFFLAG_NOPAD_CONDITION=          "npc";    /* nopad-condition                    */
static const CFFLAG_EAT_BLANK_LINES=          "eb";     /* eat-blank-lines                    */
static const CFFLAG_INDENT_PP=                "ip";     /* indent-preprocessing               */
static const CFFLAG_INDENT_PP_INSIDE_BRACES=  "ipb";    /* indent-preprocessing-inside-braces */
static const CFFLAG_INDENT_IDEMPOTENT_BLOCK=  "ipi";    /* indent-idempotent-block            */
static const CFFLAG_CUDDLE_ELSE=              "ce";     /* cuddle-else                        */
static const CFFLAG_BESTYLE_ON_FUNCTIONS=     "bf";     /* bestyle-on-functions               */
static const CFFLAG_NOSPACE_BEFORE_BRACE=     "nsb";    /* nospace-before-brace               */
static const CFFLAG_EAT_PP_SPACE=             "eps";    /* eat-preprocessing-space            */
static const CFFLAG_INDENT_COMMENTS=          "isc";    /* indent-standalone-comments         */
static const CFFLAG_USE_RELATIVE_INDENT=      "icr";    /* indent-trailing-comments-relative  */
static const CFFLAG_ALIGN_ON_PARENS=          "ap";     /* align-on-parens                    */
static const CFFLAG_ALIGN_ON_EQUAL=           "ae";     /* align-on-equal                     */
static const CFFLAG_INDENT_COL1_COMMENTS=     "ic1";    /* indent-col1-comments               */
static const CFFLAG_PARENS_ON_RETURN=         "pr";     /* parens-on-return                   */
static const CFFLAG_BRACE_STYLE=              "bs";     /* brace-style                        */
static const CFFLAG_SYNTAX_INDENT=            "si";     /* syntax-indent                      */
static const CFFLAG_BRACE_INDENT=             "bi";     /* brace-indent                       */
static const CFFLAG_STATEMENT_COMMENT_COL=    "scc";    /* statement-comment-col              */
static const CFFLAG_DECL_COMMENT_COL=         "dcc";    /* decl-comment-col                   */
static const CFFLAG_TABSIZE=                  "ts";     /* tabsize                            */
static const CFFLAG_ORIG_TABSIZE=             "ots";    /* orig_tabsize                       */
static const CFFLAG_CONTINUATION_INDENT=      "ci";     /* continuation-indent                */
static const CFFLAG_INDENT_ACCESS_SPECIFIER=  "ias";    /* indent access specifier            */

static _str _merge_flags(int ibeautifier)
{
   result := "";
   _str value;
   bool apply;

   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_CASE);
   result :+= (value?('+'):('-')) :+ CFFLAG_INDENT_CASE:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_FIRST_LEVEL);
   result :+= (value?('+'):('-')) :+ CFFLAG_INDENT_FL:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS);
   result :+= (value?('+'):('-')) :+ CFFLAG_INDENT_WITH_TABS:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_SP_IF_BEFORE_LPAREN);
   result :+= (value?('-'):('+')) :+ CFFLAG_NOSPACE_BEFORE_PAREN:+' ';

   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_SPPAD_IF_PARENS,0,apply);
   _str pad=0;
   _str nopad=0;
   if (apply) {
      if (value==1) {
         pad=1;
      } else {
         nopad=1;
      }
   }
   result :+= (pad?('+'):('-')) :+ CFFLAG_PAD_CONDITION:+' ';
   result :+= (nopad?('+'):('-')) :+ CFFLAG_NOPAD_CONDITION:+' ';

   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_RM_BLANK_LINES);
   result :+= (value?('+'):('-')) :+ CFFLAG_EAT_BLANK_LINES:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_PP_INDENT);
   result :+= (value?('+'):('-')) :+ CFFLAG_INDENT_PP:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_PP_INDENT_IN_CODE_BLOCK);
   result :+= (value?('+'):('-')) :+ CFFLAG_INDENT_PP_INSIDE_BRACES:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_PP_INDENT_IN_HEADER_GUARD);
   result :+= (value?('+'):('-')) :+ CFFLAG_INDENT_IDEMPOTENT_BLOCK:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_NL_BEFORE_ELSE);
   result :+= (value?('-'):('+')) :+ CFFLAG_CUDDLE_ELSE:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_APPLY_BRACELOC_TO_FUNCTIONS);
   result :+= (value?('+'):('-')) :+ CFFLAG_BESTYLE_ON_FUNCTIONS:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_SP_BEFORE_LBRACE);
   result :+= (value?('-'):('+')) :+ CFFLAG_NOSPACE_BEFORE_BRACE:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_PP_RM_SPACES_AFTER_POUND);
   result :+= (value?('+'):('-')) :+ CFFLAG_EAT_PP_SPACE:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_COMMENTS);
   result :+= (value?('+'):('-')) :+ CFFLAG_INDENT_COMMENTS:+' ';

   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_TRAILING_COMMENT_STYLE);
   trailing_comment_col:=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_TRAILING_COMMENT_COL);
   _str use_relative_indent=0;
   if (value==TC_ORIG_REL_INDENT) {
      use_relative_indent=1;
      trailing_comment_col=0;
   } else if (value==TC_ORIG_ABS_COL) {
      use_relative_indent=0;
      trailing_comment_col=0;
   } else {
      use_relative_indent=0;
   }

   result :+= (use_relative_indent?('+'):('-')) :+ CFFLAG_USE_RELATIVE_INDENT:+' ';
   result :+= '-':+CFFLAG_STATEMENT_COMMENT_COL :+' ':+trailing_comment_col:+' ';

   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_LISTALIGN2_PARENS);
   result :+= (value?('-'):('+')) :+ CFFLAG_ALIGN_ON_PARENS:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_ALIGN_ON_ASSIGNMENT_OP);
   result :+= (value?('+'):('-')) :+ CFFLAG_ALIGN_ON_EQUAL:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_COL1_COMMENTS);
   result :+= (value?('+'):('-')) :+ CFFLAG_INDENT_COL1_COMMENTS:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_REQUIRE_PARENS_ON_RETURN);
   result :+= (value?('+'):('-')) :+ CFFLAG_PARENS_ON_RETURN:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_MEMBER_ACCESS);
   result :+= (value?('+'):('-')) :+ CFFLAG_INDENT_ACCESS_SPECIFIER:+' ';

   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_BRACELOC_IF,'',apply);
   if (!apply) {
      value=0;
   } else {
      if (value==0) {
         value=1;
      } else if (value==1) {
         value=2;
      } else if (value==2) {
         value=4;
      } else {
         value=1;
      }
   }
   result :+= '-':+CFFLAG_BRACE_STYLE :+' ':+value:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_SYNTAX_INDENT);
   result :+= '-':+CFFLAG_SYNTAX_INDENT :+' ':+value:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WIDTH_BRACES);
   if (!isinteger(value)) value=0;
   result :+= '-':+CFFLAG_BRACE_INDENT :+' ':+value:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_DECL_COMMENT_COL);
   if (!isinteger(value)) value=0;
   result :+= '-':+CFFLAG_DECL_COMMENT_COL :+' ':+value:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE);
   result :+= '-':+CFFLAG_TABSIZE :+' ':+value:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_ORIGINAL_TAB_SIZE);
   result :+= '-':+CFFLAG_ORIG_TABSIZE :+' ':+value:+' ';
   value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WIDTH_CONTINUATION);
   result :+= '-':+CFFLAG_CONTINUATION_INDENT :+' ':+value:+' ';
/*
-ic +if -it -nsp -pc -npc -eb +ip -ipb -ipi +ce -bf -nsb +eps +isc +icr +ap +ae -ic1 -pr -ias -bs 1 -si 3 -bi 0 -scc 0 -dcc 0 -ts 3 -ots 3 -ci 8
-ic +if -it -nsp -pc -npc -eb +ip -ipb -ipi +ce -bf -nsb +eps +isc +icr +ap -ae +ic1 -pr -ias -bs 1 -si 3 -bi 0 -dcc 0 -scc 0 -ts 3 -ots 3 -ci 3 
 
 
*/
   //say('result='result);

   return result;
#if 0
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
#endif
}

static const CFBESTYLE0_FLAG= 1;
static const CFBESTYLE1_FLAG= 2;
static const CFBESTYLE2_FLAG= 4;

static int _init_options(int (&p):[],int sync_lang_options,_str lang)
{
   msg := "";
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
   orig_filename := strip(backup_filename,'B','"');
   if (_isUnix()) {
      return(orig_filename:+'.~');
   }

   _str ext=_get_extension(orig_filename);
   filename := _strip_filename(orig_filename,'I');
   if (ext=='') {
      //File had No Extension
      return(filename:+'.__~');
   }
   if ( length(ext)==1 ) {
      //File had one character extension
      return(filename:+'.':+ext:+'_~');
   }
   return(filename:+'.':+substr(ext,1,2):+'~':+substr(ext,4));

}

// Converts .java, .js, .cs, and .e  languages to .c
static const DEFAULT_BEAUTIFIER_EXT=  "xhtml=xml phpscript=c ada=ada c=c java=c js=c cs=c e=c html=html cfml=html xml=html xsd=html vpj=xml docbook=xml ant=xml as=c android=xml";   /* Valid beautifier languages */
int BeautifyCheckSupport(_str &lang)
{
   lang=eq_name2value(lang,DEFAULT_BEAUTIFIER_EXT);
   if ( lang=='' ) {
      return(1);
   }

   return(0);
}

defeventtab _beautify_extension_form;
_ctl_ok.on_create()
{
   _str allLangIds[];
   _GetAllLangIds(allLangIds);
   foreach ( auto lang in allLangIds ) {
      if (_beautifier_is_supported(lang)) {
         _ctl_language._lbadd_item(_LangGetModeName(lang));
      }
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

static const PROFILE_SUBMENU = "BeautifyWithSubmenu";
static const PROFILE_BEAUTMENN = "BeautifyItem";


static const MSG_BEAUTIFY= 'Beautifies the buffer with the default profile for the language';
static const MSG_EDIT_PROFILE= 'Edits the settings for the current profile';
static const MSG_BEAUTIFIER_OPTIONS= 'Allows you to edit or change the default beautifier profile.';
static const MSG_BEAUTIFIER_PROFILE_OVERRIDES= 'Allows you to specify beautifier profiles used by specific source trees.';

void _init_menu_nbeautifier(int menu_handle, int no_child_windows)
{
   if (_haveBeautifiers()) {
      // Make the beautify while typing menu entry, if it doesn't already exist.
      rc := _menu_find(menu_handle, 'toggle-beautify-on-edit', auto ephand, auto eppos, 'M');
      if (rc != 0) {
         rc = _menu_find(menu_handle, 'indent-with-tabs-toggle', ephand, eppos, 'M');
         if (rc == 0) {
            fon := LanguageSettings.getBeautifierExpansions(p_LangId, 0) & BEAUT_EXPAND_ON_EDIT;
            _menu_insert(ephand, eppos, fon ? MF_CHECKED : MF_UNCHECKED, "Beautify While Typing", 'toggle-beautify-on-edit', 
                         '', '', 'Toggles beautify while typing feature on/off');
         }
      }
   } else {
      //int menu_handle=_mdi.p_menu_handle;
      // Find View menu so we can be more selective about selection
      // character.
      submenu_handle := -1;
      int i,Nofitems=_menu_info(menu_handle);
      for (i=0;i<Nofitems;++i) {
         _menu_get_state(menu_handle,i,auto flags,"P",auto caption,auto command);
         // IF the selection character is on the V or I
         nohotkey_caption := stranslate(caption,"","&");
         if (strieq(nohotkey_caption,'tools')) {
            if (isinteger(command)) {
               submenu_handle=(int)command;
            }
            break;
         }
      }
      if (submenu_handle>=0) {
         Nofitems=_menu_info(submenu_handle);
         for (i=0;i<Nofitems;++i) {
            _menu_get_state(submenu_handle,i,auto flags,"P",auto caption,auto command);
            // IF the selection character is on the V or I
            nohotkey_caption := stranslate(caption,"","&");
            if (strieq(nohotkey_caption,'Beautify')) {
               if (isinteger(command)) {
                  _menu_delete(submenu_handle,i);
               }
               return;
            }
         }
      }

      rc := _menu_find(menu_handle, 'toggle-beautify-on-edit', auto ephand, auto eppos, 'M');
      while (rc == 0) {
         _menu_delete(ephand, eppos);
         rc = _menu_find(menu_handle, 'toggle-beautify-on-edit', ephand, eppos, 'M');
      }

      if (markup_formatting_supported(p_LangId)) {
         if (rc != 0) {
            rc = _menu_find(menu_handle, 'indent-with-tabs-toggle', ephand, eppos, 'M');
            if (rc == 0) {
               fon := LanguageSettings.getBeautifierExpansions(p_LangId, 0) & BEAUT_EXPAND_ON_EDIT;
               _menu_insert(ephand, eppos, fon ? MF_CHECKED : MF_UNCHECKED, "XML/HTML Formatting", 'toggle-beautify-on-edit', '', '', 
                            'Enables formatting and wrapping for XML or HTML Documents as you type.');
            }
         }
      }
   }

   //_str outerlang = p_LangId;
   //_str lang      = p_window_id._GetEmbeddedLangId();
   lang := p_LangId;
   otherlang := lang;

   if (_LanguageInheritsFrom('html') || lang == 'xhtml') {
      otherlang = hformat_default_embedded();
   }

   if (lang == 'phpscript') {
      otherlang = 'html';
   }

   supports_profiles  := _plugin_has_profile(vsCfgPackage_for_LangBeautifierProfiles(lang),'Default');
   supports_profiles=supports_profiles && _ConcurProcessName()==null;
   both_standard := new_beautifier_supported_language(lang) && new_beautifier_supported_language(otherlang);
   html_mix := otherlang != lang;

   // Clear the slate.
   status := _menu_find(menu_handle, 'beautifier-edit-current-profile', auto ep_handle, auto ep_pos, 'M');
   if (status < 0) {
      status = _menu_find(menu_handle, 'beauty-edit', ep_handle, ep_pos, 'C');
   }
   if (status < 0) {
      // This could happen if the autosave timer is dead
      return;
   }
   num_ents := _menu_info(ep_handle);

   for (i := num_ents-1; i >=0; i--) {
      _menu_delete(ep_handle, i);
   }

   if (supports_profiles) {
      bool using_override;
      _str profileName=_beautifier_get_buffer_profile(lang,p_buf_name,using_override);
      _menu_insert(ep_handle, -1, 0, 
                   (using_override)?"Beautify ("profileName' - override)':"Beautify ("profileName')', 'beautify', '', '', 
                   MSG_BEAUTIFY);

      if (both_standard) {
         // Use that position and handle to add the submenu.
         bw_handle := _menu_insert(ep_handle, -1, MF_SUBMENU, "Beautify With", '', PROFILE_SUBMENU,
                                   '', "");

         _beautifier_list_profiles(lang,auto profiles);
         for (i = 0; i < profiles._length(); i++) {
            p := profiles[i];
            _menu_insert(bw_handle, -1, MF_ENABLED, p, 'beautify-with-profile 'p'', 
                         '', '', 'Beautifies current buffer with the "'p'" profile.');
         }
      }

      if (html_mix) {
         cursor_lang := p_window_id._GetEmbeddedLangId();
         clo := _LangGetModeName(cursor_lang);
         in_another_lang := cursor_lang != lang && cursor_lang != otherlang && new_beautifier_supported_language(cursor_lang);
         
         if (!in_another_lang) {
            cursor_lang = hformat_default_embedded();
            in_another_lang = cursor_lang != lang && cursor_lang != otherlang;
         }

         _menu_insert(ep_handle, -1, 0, '-');

         if (in_another_lang) {
            _menu_insert(ep_handle, -1, 0, 'Edit 'clo' Profile...', 'beautifier-edit-current-profile 'cursor_lang, '', '', 
                         'Edit the default profile for 'clo);
         }

         mno := _LangGetModeName(otherlang);
         _menu_insert(ep_handle, -1, 0, 'Edit 'mno' Profile...', 'beautifier-edit-current-profile 'otherlang, 'beauty-edit', '',
                      'Edit the default profile for 'mno);

         mni := _LangGetModeName(lang);
         _menu_insert(ep_handle, -1, 0, 'Edit 'mni' Profile...', 'beautifier-edit-current-profile 'lang, '', '',
                      'Edit the default profile for 'mni);

         _menu_insert(ep_handle, -1, 0, '-');

         if (in_another_lang) {
            _menu_insert(ep_handle, -1, 0, 'Options for 'clo'...', 'beautifier-options 'cursor_lang, '', '', 
                         MSG_BEAUTIFIER_OPTIONS);
         }

         _menu_insert(ep_handle, -1, 0, 'Options for 'mno'...', 'beautifier-options 'otherlang, '', '', 
                      MSG_BEAUTIFIER_OPTIONS);

         _menu_insert(ep_handle, -1, 0, 'Options for 'mni'...', 'beautifier-options 'lang, '', '', 
                      MSG_BEAUTIFIER_OPTIONS);

      } else {
         _menu_insert(ep_handle, -1, 0, "Edit Current Profile...", 'beautifier-edit-current-profile', '', '',
                      MSG_EDIT_PROFILE);
         _menu_insert(ep_handle, -1, 0, "Options...", 'beautifier-options', '', '', 
                      MSG_BEAUTIFIER_OPTIONS);
      }

   } else {
      // Standard type then.
      _menu_insert(ep_handle, 0, 0, "Beautify", 'beautify', '', '', MSG_BEAUTIFY);
      _menu_insert(ep_handle, 1, 0, "Edit Current Profile...", 'beautifier-edit-current-profile', '', '', 
                   MSG_EDIT_PROFILE);
      _menu_insert(ep_handle, 2, 0, "Options...", 'beautifier-options', '', '', 
                   MSG_BEAUTIFIER_OPTIONS);
   }
   _menu_insert(ep_handle, -1, 0, '-');
   _menu_insert(ep_handle, -1, 0, "Beautifier Profile Overrides...", 'beautifier-edit-seeditorconfig', '', '', 
                MSG_BEAUTIFIER_PROFILE_OVERRIDES);

}

_command void beautifier_options(_str lang='') name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBeautifiers()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Beautify");
      return;
   }

   if (lang == '' && _isEditorCtl()) {
      lang = p_LangId;
   }

   supports_profiles  := _plugin_has_profile(vsCfgPackage_for_LangBeautifierProfiles(lang),'Default');
   if (supports_profiles) {
      _new_beautifier_options(lang);
   } else {
      gui_beautify();
   }
}


_OnUpdate_beautifier_options(CMDUI cmdui,int target_wid,_str command)
{
   return _OnUpdate_beautify(cmdui,target_wid,command);
}
