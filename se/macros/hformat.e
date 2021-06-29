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
#include "markers.sh"
#include "tagsdb.sh"
#include "color.sh"
#import "se/lang/api/LanguageSettings.e"
#import "cfg.e"
#import "beautifier.e"
#import "cformat.e"
#import "cutil.e"
#import "files.e"
#import "help.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "mprompt.e"
#import "picture.e"
#import "saveload.e"
#import "seldisp.e"
#import "setupext.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#import "xml.e"
#endregion

using se.lang.api.LanguageSettings;

static const HF_DEFAULT_TAG_NAME= BEAUT_DEFAULT_TAG_NAME;

static const BROKENTAG_STYLE_INDENT=   (1);
static const BROKENTAG_STYLE_REL=      (2);
static const BROKENTAG_STYLE_PRESERVE= (3);

static const TCOMMENT_COLUMN=   (1);
static const TCOMMENT_RELATIVE= (2);
static const TCOMMENT_ABSOLUTE= (3);

static const HFMAX_MLCOMMENTS= (2);

static const QUOTESTYLE_NO= 0;
static const QUOTESTYLE_YES=  1;
//#define QUOTESTYLE_PRESERVE -1

static const DEF_INDENT= (2);

//#define HFORMAT_PREVIEW_PROFILE "Preview Window Profile"
static const NO_PARENT_TAG= "<None>";
static const NEWLINES_DISABLED= "As-Is";

static bool gTagParentUpdateInhibited = false;

// Contains the language to be edited when we're embedded in the options
// dialog.
static bool gOriginalSchemeModified;

static _str tagcase_map:[] = {
   //WORDCASE_PRESERVE => "Preserve",
   WORDCASE_CAPITALIZE => "Capitalize",
   WORDCASE_LOWER => "Lower",
   WORDCASE_UPPER => "Upper"
};

static _str hexcase_map:[] = {
   //WORDCASE_PRESERVE => "Preserve",
   WORDCASE_LOWER => "Lower",
   WORDCASE_UPPER => "Upper"
};


static _str quotestyle_map:[] = {
   //QUOTESTYLE_PRESERVE => "Preserve",
   QUOTESTYLE_YES       => "Yes",
   QUOTESTYLE_NO      => "No"
};

// Map from printable name to langid.
static _str supported_embedded_languages[] = {
   'cs',
   'java',
   "js",
   'pl',
   "phpscript",
   'py',
   'ruby',
   'vbs',
   'vb'
};

// Example file for options preview.
static _str gExample = '';
static _str gTagPreview = '';
static bool gInitialized = false;
static bool gDialogSaved = false;
static bool gCanBeautifyTarget = false;

static _str rlookup(_str (&ht):[], _str key)
{
   first := "";

   foreach (auto k => auto v in ht) {
      if (first == '') {
         first = k;
      }

      if (key == v) {
         return k;
      }
   }
   return first;
}


static int has_nls_within(typeless t) 
{
   return (int)(t != NEWLINES_DISABLED && (int)t > 0);
}
static bool tag_exists(int ibeautifier,_str tagName) {
   if (tagName==HF_DEFAULT_TAG_NAME) {
      return true;
   }
   return _beautifier_tag_exists(ibeautifier,tagName);
}
static _str get_tag_name() {
   _str tagName=ctltag_list._lbget_text();
   if (tagName==HF_DEFAULT_TAG_NAME) {
      return BEAUT_DEFAULT_TAG_NAME;
   }
   return tagName;
}

static _str get_tag_lb_within(int ibeautifier,_str tagname) {
   value:=_beautifier_get_tag_lb_within(ibeautifier,tagname,auto apply);
   if (!apply) {
      return NEWLINES_DISABLED;
   }
   return value;
}
static void set_tag_lb_within(int ibeautifier,_str tagname,_str lb_within) {
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_ISMIN_AFTER_START_TAG, 1);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_ISMIN_BEFORE_END_TAG, 1);

   apply := lb_within!=NEWLINES_DISABLED;
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_START_TAG, apply ? lb_within:"0", apply);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_END_TAG, apply ? lb_within:"0", apply);
   //exprop(xmldoc, tag, 'new_line_after_start_tag', lbw_disabled ? "0" : lb_within, lbw_disabled ? 0 : 1);
   //exprop(xmldoc, tag, 'new_line_after_start_tag_is_min', 1);
   //exprop(xmldoc, tag, 'new_line_before_end_tag', lbw_disabled ? "0" : lb_within, lbw_disabled ? 0 : 1);
   //exprop(xmldoc, tag, 'new_line_before_end_tag_is_min', 1);
}
static _str get_tag_standalone(int ibeautifier,_str tagname) {
   nlb := _beautifier_get_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG);
   nla := _beautifier_get_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG);
   lbw := get_tag_lb_within(ibeautifier,tagname);

   saVal := '0';

   if ((nlb != NEWLINES_DISABLED && nlb != '0') || (nla != NEWLINES_DISABLED && nla != '0') || (lbw != NEWLINES_DISABLED && lbw != '0')) {
      saVal = '1';
   }
   return saVal;
}
static _str get_tag_parent(int ibeautifier,_str tagname) {
   parent_tag:=_beautifier_get_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG);
   if (parent_tag=='') {
      parent_tag=NO_PARENT_TAG;
   }
   return parent_tag;
}
static _str get_tag_newlines(int ibeautifier,_str tagname, _str name) {
   bool apply;
   nl_before:=_beautifier_get_tag_property(ibeautifier,tagname,name,'',apply);
   if (!apply) {
      return NEWLINES_DISABLED;
   }
   if( !isinteger(nl_before) || nl_before<0 ) {
      return 0;
   }
   return nl_before;
}
static void _InitTag(int ibeautifier,_str tagname,_str lang)
{
   content_style := "Wrap";
   _str indent_tags= 0;
   _str preserve_child_tags=false;
   _str preserve_child_tags_indent=false;
   _str preserve_start_tag_indent=false;
   _str end_tag=true;
   _str end_tag_required=true;
   valid_child_tags := "";
   _str new_lines_before_start_tag=1;
   new_lines_before_start_tag_apply := true;
   _str new_lines_before_start_tag_is_min=1;
   _str new_lines_after_end_tag=1;
   new_lines_after_end_tag_apply := true;
   _str new_lines_after_end_tag_is_min=1;

   _str new_line_after_start_tag=0;
   new_line_after_start_tag_apply := true;
   _str new_line_after_start_tag_is_min=1;

   _str new_line_before_end_tag=0;
   new_line_before_end_tag_apply := true;
   _str new_line_before_end_tag_is_min=1;


   if( _LanguageInheritsFrom('xml',lang) ) {
      indent_tags=1;
      content_style='Preserve';
   }
   {
      int temp_ibeautifier=_beautifier_create('html');
      _beautifier_set_properties(temp_ibeautifier,vsCfgPackage_for_LangBeautifierProfiles('html'),BEAUTIFIER_DEFAULT_PROFILE);
      lc_tagname := lowcase(tagname);
      if (_beautifier_tag_exists(temp_ibeautifier,lc_tagname)) {
         content_style=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_CONTENT_STYLE,content_style);
         indent_tags=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_INDENT_TAGS,indent_tags);
         preserve_child_tags=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS,preserve_child_tags);
         preserve_child_tags_indent=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS_INDENT,preserve_child_tags_indent);
         preserve_start_tag_indent=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_PRESERVE_START_TAG_INDENT,preserve_start_tag_indent);
         end_tag=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_END_TAG,end_tag);
         end_tag_required=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_END_TAG_REQUIRED,end_tag_required);
         valid_child_tags=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_VALID_CHILD_TAGS,valid_child_tags);
         new_lines_before_start_tag=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG,new_lines_before_start_tag,new_lines_before_start_tag_apply);
         new_lines_before_start_tag_is_min=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_ISMIN_BEFORE_START_TAG,new_lines_before_start_tag_is_min);
         new_lines_after_end_tag=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG,new_lines_after_end_tag,new_lines_after_end_tag_apply);
         new_lines_after_end_tag_is_min=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_ISMIN_AFTER_END_TAG,new_lines_after_end_tag_is_min);

         new_line_after_start_tag=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_BL_AFTER_START_TAG,new_line_after_start_tag,new_line_after_start_tag_apply);
         new_line_after_start_tag_is_min=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_ISMIN_AFTER_START_TAG,new_line_after_start_tag_is_min);
         new_line_before_end_tag=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_END_TAG,new_line_before_end_tag,new_line_before_end_tag_apply);
         new_line_before_end_tag_is_min=_beautifier_get_tag_property(temp_ibeautifier,lc_tagname,VSCFGP_BEAUTIFIER_ISMIN_BEFORE_END_TAG,new_line_before_end_tag_is_min);
      } else {
         content_style=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_CONTENT_STYLE,content_style);
         indent_tags=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_INDENT_TAGS,indent_tags);
         preserve_child_tags=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS,preserve_child_tags);
         preserve_child_tags_indent=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS_INDENT,preserve_child_tags_indent);
         preserve_start_tag_indent=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_PRESERVE_START_TAG_INDENT,preserve_start_tag_indent);
         end_tag=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_END_TAG,end_tag);
         end_tag_required=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_END_TAG_REQUIRED,end_tag_required);
         valid_child_tags=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_VALID_CHILD_TAGS,valid_child_tags);
         new_lines_before_start_tag=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG,new_lines_before_start_tag,new_lines_before_start_tag_apply);
         new_lines_before_start_tag_is_min=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_ISMIN_BEFORE_START_TAG,new_lines_before_start_tag_is_min);
         new_lines_after_end_tag=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG,new_lines_after_end_tag,new_lines_after_end_tag_apply);
         new_lines_after_end_tag_is_min=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_ISMIN_AFTER_END_TAG,new_lines_after_end_tag_is_min);

         new_line_after_start_tag=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_BL_AFTER_START_TAG,new_line_after_start_tag,new_line_after_start_tag_apply);
         new_line_after_start_tag_is_min=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_ISMIN_AFTER_START_TAG,new_line_after_start_tag_is_min);
         new_line_before_end_tag=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_BL_BEFORE_END_TAG,new_line_before_end_tag,new_line_before_end_tag_apply);
         new_line_before_end_tag_is_min=_beautifier_get_tag_property(ibeautifier,BEAUT_DEFAULT_TAG_NAME,VSCFGP_BEAUTIFIER_ISMIN_BEFORE_END_TAG,new_line_before_end_tag_is_min);
      }
      _beautifier_destroy(temp_ibeautifier);
   }

   _beautifier_set_tag_property(ibeautifier,tagname,'','');  // add the tag
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_CONTENT_STYLE,content_style);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_INDENT_TAGS,indent_tags);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_END_TAG,end_tag);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_END_TAG_REQUIRED,end_tag_required);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG,new_lines_before_start_tag,new_lines_before_start_tag_apply);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_ISMIN_BEFORE_START_TAG,new_lines_before_start_tag_is_min);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG,new_lines_after_end_tag,new_lines_after_end_tag_apply);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_ISMIN_AFTER_END_TAG,new_lines_after_end_tag_is_min);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_PRESERVE_START_TAG_INDENT,preserve_start_tag_indent);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_VALID_CHILD_TAGS,valid_child_tags);

   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS,preserve_child_tags);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS_INDENT,preserve_child_tags_indent);


   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_START_TAG,new_line_after_start_tag,new_line_after_start_tag_apply);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_ISMIN_AFTER_START_TAG,new_line_after_start_tag_is_min);

   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_END_TAG,new_line_before_end_tag,new_line_before_end_tag_apply);
   _beautifier_set_tag_property(ibeautifier,tagname,VSCFGP_BEAUTIFIER_ISMIN_BEFORE_END_TAG,new_line_before_end_tag_is_min);



   return;
}


bool hformat_dialog_saved()
{
   return gDialogSaved;
}


static void hformatSaveScheme(int ibeautifier,_str lang, _str scheme) {
   isXml := _LanguageInheritsFrom('xml', lang);
   if (isXml) {
      if (_find_control('_ctl_auto_validate')) {
         LanguageSettings.setAutoValidateOnOpen(lang,_ctl_auto_validate.p_value != 0);
      } else {
         //LanguageSettings.setAutoValidateOnOpen(lang,false);
      }
   }
   
   if (_find_control('_ctl_symbol_trans')) {
      LanguageSettings.setAutoSymbolTranslation(lang, _ctl_symbol_trans.p_value != 0);
   }

   status:=_beautifier_save_profile(ibeautifier,vsCfgPackage_for_LangBeautifierProfiles(lang),scheme);


   if (status == 0) {
      _beautifier_cache_clear(lang);
      _beautifier_profile_changed(scheme,lang,ibeautifier);
   }
}

static const ONE_LINE_IF_ONE = "One Line If One Attr";
static const ALL_ONE_LINE    = "All On One Line";
static const ALL_WITH_WRAP   = "All On One Line, With Wrap";
static const ONE_PER_LINE    = "One Per Line";
static const PRESERVE_ALL    = "Preserve Layout";
static const PRESERVE_INDENT = "Preserve Layout, Reindent";

static _str attstyle_trans:[] = {
   ONE_LINE_IF_ONE => "OneLineIfOneAttr",
   ALL_ONE_LINE    => 'AllOnOneLine',
   ALL_WITH_WRAP   => 'AllOnOneLineWrapLongLine',
   ONE_PER_LINE    => 'OnePerLine',
   PRESERVE_ALL    => 'PreserveAll',
   PRESERVE_INDENT => 'PreserveLinesRelativeIndent'
};

static void init_attstyle_combobox(int ctl, _str initial_setting)
{
   first := true;

   ctl.p_cb_list_box._lbclear();
   foreach (auto k => auto v in attstyle_trans) {
      ctl.p_cb_list_box._lbadd_item(k);
      if (first || initial_setting == v) {
         ctl.p_cb_text_box.p_text = k;
      }
      first = false;
   }
}

static _str get_attstyle(int cbctrl)
{
   cbval := cbctrl.p_cb_text_box.p_text;

   foreach (auto k => auto v in attstyle_trans) {
      if (strieq(cbval,k)) {
         return v;
      }
   }
   return cbval;
}

static void populate_combobox_from_values(_str (&map):[], int ctl, _str initial_setting)
{
   first := true;

   foreach (auto k => auto v in map) {
      ctl.p_cb_list_box._lbadd_item_no_dupe(v);
      if (first || strieq(initial_setting,v)) {
         ctl.p_cb_text_box.p_text = v;
      }
      first = false;
   }
}
static void populate_combobox_from(_str (&map):[], int ctl, _str initial_setting,typeless apply)
{
   first := true;

   foreach (auto k => auto v in map) {
      ctl.p_cb_list_box._lbadd_item_no_dupe(v);
      if (first || initial_setting == k) {
         ctl.p_cb_text_box.p_text = v;
         if (apply!=null) {
            if (ctl.p_prev.p_object==OI_CHECK_BOX) {
               ctl.p_prev.p_value=apply;
            }
         }
      }
      first = false;
   }
}

static void populate_newlines_combobox(int wid, int maxnum, _str setting)
{
   wid.p_cb_list_box._lbclear();
   wid.p_cb_list_box._lbadd_item(NEWLINES_DISABLED);
   wid.p_cb_text_box.p_text = NEWLINES_DISABLED;

   for (i := 0; i <= maxnum; i++) {
      vtxt := (_str)i;

      if (setting == vtxt) {
         wid.p_cb_text_box.p_text;
      }
      wid.p_cb_list_box._lbadd_item(vtxt);
   }
}

static bool read_combobox_with(_str (&map):[], int ctl, int& val)
{
   foreach (auto k => auto v in map) {
      if (v == ctl.p_cb_text_box.p_text) {
         val = k;
         return true;
      }
   }

   return false;
}


int _OnUpdate_h_beautify(CMDUI cmdui,int target_wid,_str command)
{
   return _OnUpdate_beautify(cmdui,target_wid,command);
}


/** 
 * Beautifies selections or entire file.
 *  
 * @deprecated Use {@link beautify()}.
 */
_command int h_format,h_beautify,html_format,html_beautify,xml_format,xml_beautify() name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return beautify();
}

static int _FindBeginContext(int mark, int &sl, int &el, bool quiet=false)
{
   int old_sl=sl;
   int old_el=el;

   msg := "";
   _begin_select(mark);

   while( p_line>1 ) {
      _begin_line();   // Goto to beginning of line so not fooled by start of comment
      if( _in_comment(true) ) {
         // If we are in the middle of a multi-line comment,
         // then skip to beginning of it
         if( p_line==1 ) {
            // Should never get here
            // There is no way we will find the beginning of this comment
            if( !quiet ) {
               msg="Cannot find beginning of context:\n\n":+
                   "\tCannot find beginning of comment at line 1";
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return(1);
         }
         up();
         while( p_line && _clex_find(0,'G')==CFG_COMMENT ) {
            up();
         }
         if( _clex_find(0,'G')==CFG_COMMENT ) {
            // We are at the top of file
            if( !quiet ) {
               msg="Cannot find beginning of context:\n\n":+
                   "\tCannot find beginning of comment at line 1";
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return(1);
         }
         _end_line();
         // Check to see if we are ON the multiline comment
         if( _clex_find(0,'G')!=CFG_COMMENT ) {
            down();   // Move back onto the first line of the comment
         }
      } else if( p_EmbeddedLexerName!="" && p_line>1 ) {
         // If we are inside embedded script, then skip to beginning of it.
         // p_line>1 so we don't get into any weird situations where the
         // script starts on line 1 and we would have gotten into an infinite
         // loop while looking for the beginning of the script.
         while( p_EmbeddedLexerName!="" && p_EmbeddedLexerName!=p_lexer_name ) {
            up();
            if( _on_line0() ) {
               down();
               break;
            }
         }
         // It is safe to assume that we are on the <script ...> line now,
         // so no adjustment needed.
      } else {
         break;
      }
   }
   sl=p_line;
   if( sl!=old_sl ) {
      // Reset the selection
      _deselect(mark);
      p_line=sl;
      _select_line(mark);
      p_line=el;
      _select_line(mark);
   }

   _begin_select(mark);

   // Beginning of context is top-of-file
   top();

   return(0);
}

static int _FindEndContext(int mark ,int &sl, int &el, bool quiet=false)
{
   int old_sl=sl;
   int old_el=el;
   msg := "";

   _end_select(mark);
   _end_line();   // Goto end of line so not fooled by start of comment

   while( p_line<p_Noflines ) {
      if( _in_comment(true) ) {
         // If we are in the middle of a multi-line comment,
         // then skip to end of it
         if( down() ) {
            // Should never get here
            // There is no way that this multi-line comment has an end
            if( !quiet ) {
               msg="Cannot find end of context:\n\n":+
                   "\tCannot find end of comment at line ":+p_line;
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return(1);
         }
         _begin_line();
         while( _clex_find(0,'G')==CFG_COMMENT ) {
            if( down() ) break;   // Comment might extend to bottom of file
            _begin_line();
         }
         if( _clex_find(0,'G')==CFG_COMMENT ) {
            // We are at the bottom of file
            if( !quiet ) {
               msg="Cannot find end of context:\n\n":+
                   "\tCannot find end of comment at line ":+p_line;
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return(1);
         }
         up();   // Move back onto the last line of the comment
         // Will get infinite loop if we don't move outside the comment
         _end_line();
      } else if( p_EmbeddedLexerName!="" && p_line<p_Noflines ) {
         // If we are inside embedded script, then skip to beginning of it.
         // p_line>1 so we don't get into any weird situations where the
         // script starts on line 1 and we would have gotten into an infinite
         // loop while looking for the beginning of the script.
         while( p_EmbeddedLexerName!="" && p_EmbeddedLexerName!=p_lexer_name ) {
            if( down() ) break;
         }
         // It is safe to assume that we are on the <script ...> line now,
         // so no adjustment needed.
      } else {
         break;
      }
   }
   el=p_line;
   if( el!=old_el ) {
      // Reset the selection
      _deselect(mark);
      p_line=sl;
      _select_line(mark);
      p_line=el;
      _select_line(mark);
   }

   // End of context is bottom-of-file
   bottom();

   return(0);
}

static int _CreateContextView(_str mlc_startstr,_str mlc_endstr,
                              int &temp_view_id,
                              int &context_mark,
                              int &soc_linenum,   // StartOfContext line number
                              bool &last_line_was_bare,
                              bool quiet=false)
{
   last_line_was_bare=false;
   save_pos(auto p);
   old_linenum := p_line;
   typeless orig_mark=_duplicate_selection("");
   context_mark=_duplicate_selection();
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      _free_selection(context_mark);
      return(mark);
   }
   start_col := 0;
   end_col := 0;
   startmark_linenum := 0;
   typeless dummy;
   typeless stype=_select_type();
   if( stype!='LINE' ) {
      // Change the duplicated selection into a LINE selection
      if( stype=='CHAR' ) {
         _get_selinfo(start_col,end_col,dummy);
         if( end_col==1 ) {
            // Throw out the last line of the selection
            _deselect(context_mark);
            _begin_select();
            startmark_linenum=p_line;
            _select_line(context_mark);
            _end_select();
            // Check to be sure it's not a case of a character-selection of 1 char on the same line
            if( p_line!=startmark_linenum ) {
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
   if( _FindBeginContext(context_mark,sl,el,quiet) ) {
      if( !sl || !el ) {
         /* Probably in the middle of a comment that
          * extended to the bottom of file, so could
          * do nothing.
          */
         _free_selection(context_mark);
         _free_selection(mark);
         restore_pos(p);
         return(1);
      }
      top();
   }
   tl := p_line;   // Top line
   soc_linenum=sl;
   int diff=old_linenum-tl;
   _select_line(mark);
   _begin_select(context_mark);
   _first_non_blank();
   int start_indent=p_col-1;

   // Find the bottom context
   if( _FindEndContext(context_mark,sl,el,quiet) ) {
      if( !sl || !el ) {
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

   // Create a temporary view to hold the code selection and move it there
   arg2 := "+td";   // DOS \r\n linebreak
   if( length(p_newline)==1 ) {
      if( substr(p_newline,1,1)=='\r' ) {
         arg2="+tm";   // Macintosh \r linebreak
      } else {
         arg2="+tu";   // UNIX \n linebreak
      }
   }
   int orig_view_id=_create_temp_view(temp_view_id,arg2);
   if( orig_view_id=='' ) return(1);

   // Set the encoding of the temp view to the same thing as the original buffer
   typeless junk;
   typeless utf8=0;
   typeless encoding=0;
   _get_selinfo(junk,junk,junk,mark,junk,utf8,encoding);
   p_UTF8=utf8;
   p_encoding=encoding;

   _copy_to_cursor(mark);
   _free_selection(mark);       // Can free this because it was never shown
   top();up();
   insert_line(mlc_startstr:+' HFORMAT-SUSPEND-WRITE ':+mlc_endstr);
   down();
   p_line=sl-tl+1;   // +1 to compensate for the previously inserted line at the top
   insert_line(mlc_startstr:+' HFORMAT-RESUME-WRITE ':+mlc_endstr);
   p_line=el-tl+1+2;   // +2 to compensate for the 2 previously inserted lines
   insert_line(mlc_startstr:+' HFORMAT-SUSPEND-WRITE ':+mlc_endstr);
   top();
   // +2 to adjust for the HFORMAT-SUSPEND-WRITE and HFORMAT-RESUME-WRITE above
   p_line += diff+2;
   p_window_id=orig_view_id;

   return(0);
}

static void _DeleteContextSelection(int context_mark)
{
   /* If we were on the last line, then beautified text will get inserted too
    * early in the buffer
    */
   _end_select();
   last_line_was_empty := false;
   if( down() ) {
      last_line_was_empty=true;   // We are on the last line of the file
   } else {
      up();
   }

   _begin_select(context_mark);
   _begin_line();

   // Now delete the originally selected lines
   _delete_selection(context_mark);
   _free_selection(context_mark);   // Can free this because it was never shown
   if( !last_line_was_empty ) up();

   return;
}

int _OnUpdate_h_beautify_selection(CMDUI cmdui,int target_wid,_str command)
{
   return(_OnUpdate_h_beautify(cmdui,target_wid,command));
}

/**
 * Beautifies the current selection using the current options.  If there is 
 * no current selection the entire buffer is beautified.
 * 
 * @see beautify
 * @see beautify_selection
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods 
 *  
 */
_command int h_format_selection,h_beautify_selection,html_beautify_selection,xml_beautify_selection() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_PRO_EDITION)
{
   return beautify_selection();
}

static _str gLangId;
static _str gProfileName;
static int gibeautifier;

static const INDENTTAB=   (0);
static const TAGSTAB=     (1);
static const CASETAB=     (2);
static const COMMENTSTAB= (3);

defeventtab _html_beautify_form;


/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _html_beautify_form_initial_alignment()
{
   if (!_haveBeautifiers()) {
      // Save a bit of horizontal space when embedding
      // in the options dialog.  (since we don't have the right hand
      // row of buttons to line up with in this case)
      _ctl_preview.p_width = ctlsstab.p_width;  

#if 0
      // Stretch tag list down to cover area that used to have line breaks.
      ctltag_list.p_height = (ctl_tag_linebreaks_frame.p_y_extent) - ctltag_list.p_y;

      // squish.
      dy := ctlindenttags.p_height;

      // slide General box up to take freed space.  Make some room
      // so we can move the Parent Tag box below it.
      // the same place.
      gbot := ctl_general.p_y_extent;
      ctl_general.p_height -= (ctl_parent_frame.p_height + dy/2);

      // Move Parent box below General box.
      parRhs := ctl_parent_frame.p_x_extent;
      ctl_parent_frame.p_x = ctl_general.p_x;
      ctl_parent_frame.p_y = ctl_general.p_y_extent + dy/2;
      ctl_parent_frame.p_y_extent = gbot ;

      // Controls are all on the left, so try to spread things out to the right some.
      rightMove := ctl_parent_frame.p_width;
      ctl_tag_content_frame.p_width -= rightMove;
      ctl_tag_content_frame.p_x += rightMove;
      ctl_general.p_width -= rightMove;
      ctl_general.p_x += rightMove;
      ctl_parent_frame.p_width -= rightMove;
      ctl_parent_frame.p_x += rightMove;
      ctltag_list.p_width += rightMove;

      // And now widen the boxes to cover the empty space we just freed up.
      ctl_tag_content_frame.p_x_extent = parRhs ;
      ctl_general.p_x_extent = parRhs ;
      ctl_parent_frame.p_x_extent = parRhs ;

      // And lop a bit off the preview window.
      _ctl_preview.p_height -= _ctl_preview.p_height / 3;

      // Move Tag case up so it's not lonely at the bottom of the dialog.
      ctltagcase.p_y = ctlwordcase.p_y;
      ctllabel11.p_y  = ctllabel7.p_y;

#endif
      // Same for max line length.
      dyln := ctltabsize.p_y - ctlindent.p_y;
      ctlmax_line_length.p_y -= dyln;
      ctllabel1.p_y -= dyln;
   }

   padding := ctltag_list.p_x;
   tabWidth := ctlsstab.p_child.p_width;

   // indent tab
   ctlindent_with_tabs.p_x = tabWidth - (ctlindent_with_tabs.p_width + padding);

   // try putting the text box next to the label
   ctlindent.p_x = label1.p_x_extent + 60;
   rightMostPos := ctlindent_with_tabs.p_x - padding;

   // maybe that is messing with the indent with tabs checkbox?
   if( ctlindent.p_x > rightMostPos ) {
      ctlindent.p_x = rightMostPos;
   }
   ctltabsize.p_x = ctlorig_tabsize.p_x = ctlmax_line_length.p_x = ctl_glob_att_style.p_x = ctlindent.p_x;

   // tags tab
   ctladd_tag.resizeToolButton(ctlreset.p_height);
   ctlremove_tag.resizeToolButton(ctlreset.p_height);
   ctltag_list.p_width = ctl_tag_content_frame.p_x - padding - ctltag_list.p_x - ctladd_tag.p_width;
   alignControlsVertical(ctltag_list.p_x_extent, ctltag_list.p_y,
                         0,
                         ctladd_tag.p_window_id, 
                         ctlremove_tag.p_window_id);

   shift := 0;
   ctlnoflines_before.p_x += shift;
   ctlnoflines_after.p_x += shift;

   ctllabel2.p_x = ctlnoflines_before.p_x - (ctllabel2.p_width + 20);
   ctllabel3.p_x = ctlnoflines_before.p_x - (ctllabel3.p_width + 20);
}

static void _enable_children(int parent,bool enable)
{
   int firstwid,wid;

   if( !parent ) return;

   firstwid=parent.p_child;
   if( !firstwid ) return;
   wid=firstwid;
   for(;;) {
      if( wid.p_enabled!=enable ) wid.p_enabled=enable;
      wid=wid.p_next;
      if( wid==firstwid ) break;
   }

   return;
}

static void oncreateIndent(int ibeautifier)
{
   typeless indent_amount=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_SYNTAX_INDENT);
   if( !isinteger(indent_amount) || indent_amount<0 ) {
      indent_amount=DEF_INDENT;
   }
   typeless tabsize=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE);
   if( !isinteger(tabsize) || tabsize<0 ) {
      tabsize=indent_amount;
   }
   typeless orig_tabsize=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_ORIGINAL_TAB_SIZE);
   if( !isinteger(orig_tabsize) || orig_tabsize<0 ) {
      orig_tabsize=indent_amount;
   }
   typeless indent_with_tabs= (_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS)!=0);
   typeless max_line_length= (_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_MAX_LINE_LEN));
   if( !isinteger(max_line_length) || max_line_length<0 ) {
      max_line_length=0;
   }
   /*typeless brokentag_style=_beautifier_get_property(ibeautifier,"brokentag_style");
   if( !isinteger(brokentag_style) || brokentag_style<BROKENTAG_STYLE_INDENT || brokentag_style>BROKENTAG_STYLE_PRESERVE ) {
      brokentag_style=BROKENTAG_STYLE_REL;
   }
   typeless brokentag_indent=_beautifier_get_property(ibeautifier,"brokentag_indent");
   if( !isinteger(brokentag_indent) || brokentag_indent<0 ) {
      brokentag_indent=0;
   } */

   // Now set the controls
   ctlindent.p_text=indent_amount;

   ctltabsize.p_text=tabsize;

   ctlorig_tabsize.p_text=orig_tabsize;

   ctlindent_with_tabs.p_value=indent_with_tabs;

   ctlmax_line_length.p_text=max_line_length;

   _control ctl_glob_att_style;
   init_attstyle_combobox(ctl_glob_att_style, _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_TAG_ATTR_STYLE));

   if (!_haveBeautifiers()) {
      _oncreateIndentStandard();
   }
   return;
}

static void split_allowed_tags(_str (&taghash):[], _str allowedstr)
{
   for (;;) {
      _str tag, rest;
      parse allowedstr with tag ' ' rest;
      if (tag == '') 
         break;

      taghash:[tag] = 1;
      allowedstr = rest;
   }
}

static _str coalesce_allowed_tags(_str (&taghash):[])
{
   rv := "";

   foreach (auto k => auto v in taghash) {
      rv :+= k' ';
   }

   return rv;
}



int ctl_allowed_tags.on_change(int reason,int index)
{
   _str cap;
   _str taghash:[];
   //typeless tags:[];

   //tags=ctltag_list.p_user;
   switch (reason) {
   case CHANGE_CHECK_TOGGLED:
      cap = _TreeGetCaption(index, 0);
      tag := get_tag_name();

      //tags = ctltag_list.p_user;

      split_allowed_tags(taghash, _beautifier_get_tag_property(gibeautifier,tag,VSCFGP_BEAUTIFIER_VALID_CHILD_TAGS));
      if (_TreeGetCheckState(index)) {
         taghash:[cap] = 1;
      } else {
         taghash._deleteel(cap);
      }
      _beautifier_set_tag_property(gibeautifier,tag,VSCFGP_BEAUTIFIER_VALID_CHILD_TAGS,coalesce_allowed_tags(taghash));
      _ctl_label_numsel.p_caption = (taghash._length())" tags selected";
      //ctltag_list.p_user = tags;

      _ModifyScheme();
      maybe_update_preview();
      break;
   }
   return 0;
}

static void oncreateTags(int ibeautifier)
{
   // Fill the tag list

   ctltag_list._lbclear();
   ctl_allowed_tags._TreeDelete(TREE_ROOT_INDEX, "C");

   // List all tags
   _str tagNames[];
   _beautifier_list_tags(ibeautifier,tagNames);
   for(i:=0;i<tagNames._length(); ++i) {
      _str name=tagNames[i];
      if (name==BEAUT_DEFAULT_TAG_NAME) {
         name=HF_DEFAULT_TAG_NAME;
      }
      ctltag_list._lbadd_item(name);
      idx := ctl_allowed_tags._TreeAddListItem(name);
      ctl_allowed_tags._TreeSetCheckState(idx, 0);
   }
   ctltag_list._lbsort();
   ctltag_list._lbtop();

   ctl_allowed_tags._TreeSortCol(0);
   ctl_allowed_tags._TreeTop();


   // Put the default tag at the top
   line := "";
   typeless status=ctltag_list._lbsearch(HF_DEFAULT_TAG_NAME);
   if( !status && ctltag_list.p_line>1 ) {
      ctltag_list.get_line(line);
      ctltag_list._lbdelete_item();
      ctltag_list._lbtop();
      ctltag_list.up();
      ctltag_list._lbadd_item(HF_DEFAULT_TAG_NAME);
      ctltag_list.down();
   }

   //ctltag_list.p_user=s_p->tags;
   // Remember the last tag selected
   _str tagname=ctltag_list._retrieve_value("_html_beautify_form.lasttag");
   ctltag_list._lbsearch(tagname);
   ctltag_list._lbselect_line();

   ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE, "W");

   return;
}

static void oncreateAttribs(int ibeautifier)
{
   typeless tagcase=WORDCASE_LOWER;
   typeless tagcase_apply=false;
   typeless attribcase=WORDCASE_LOWER;
   typeless attribcase_apply=false;
   typeless wordvalcase=WORDCASE_LOWER;
   typeless wordvalcase_apply=false;
   typeless hexvalcase=WORDCASE_LOWER;
   typeless hexvalcase_apply=false;
   typeless quote_wordval= QUOTESTYLE_YES;
   typeless quote_wordval_apply= false;
   typeless quote_numval= QUOTESTYLE_YES;
   typeless quote_numval_apply= false;
   typeless value;
   typeless apply;

   value=_plugin_get_property(vsCfgPackage_for_LangBeautifierProfiles(gLangId),'Default',VSCFGP_BEAUTIFIER_WC_TAG_NAME,null,apply);
   if (value!=null) {
      tagcase=value;tagcase_apply=apply;
   }
   value=_plugin_get_property(vsCfgPackage_for_LangBeautifierProfiles(gLangId),'Default',VSCFGP_BEAUTIFIER_WC_ATTR_NAME,null,apply);
   if (value!=null) {
      attribcase=value;attribcase_apply=apply;
   }
   value=_plugin_get_property(vsCfgPackage_for_LangBeautifierProfiles(gLangId),'Default',VSCFGP_BEAUTIFIER_WC_ATTR_WORD_VALUE,null,apply);
   if (value!=null) {
      wordvalcase=value;wordvalcase_apply=apply;
   }
   value=_plugin_get_property(vsCfgPackage_for_LangBeautifierProfiles(gLangId),'Default',VSCFGP_BEAUTIFIER_WC_ATTR_HEX_VALUE,null,apply);
   if (value!=null) {
      hexvalcase=value;hexvalcase_apply=apply;
   }
   value=_plugin_get_property(vsCfgPackage_for_LangBeautifierProfiles(gLangId),'Default',VSCFGP_BEAUTIFIER_QUOTE_ATTR_WORD_VALUE,null,apply);
   if (value!=null) {
      quote_wordval=value;quote_wordval_apply=apply;
   }
   value=_plugin_get_property(vsCfgPackage_for_LangBeautifierProfiles(gLangId),'Default',VSCFGP_BEAUTIFIER_QUOTE_ATTR_NUMBER_VALUE,null,apply);
   if (value!=null) {
      quote_numval=value;quote_numval_apply=apply;
   }
   if(! _LanguageInheritsFrom('xml',gLangId) ) {
      value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_WORD_VALUE,null,apply);
      if (value!=null) {
         wordvalcase=value;wordvalcase_apply=apply;
      }
      value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_HEX_VALUE,null,apply);
      if (value!=null) {
         hexvalcase=value;hexvalcase_apply=apply;
      }
      value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_QUOTE_ATTR_WORD_VALUE,null,apply);
      if (value!=null) {
         quote_wordval=value;quote_wordval_apply=apply;
      }
      value=_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_QUOTE_ATTR_NUMBER_VALUE,null,apply);
      if (value!=null) {
         quote_numval=value;quote_numval_apply=apply;
      }

   }
   typeless quote_all_vals= (_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_QUOTE_ALL_VALUES)==1);
   

   if( _LanguageInheritsFrom('xml',gLangId) ) {
      // XML:
      // Not currently supported.
      ctlwordcase.p_enabled=false;ctlwordcase_apply.p_enabled=false;
      ctlhexcase.p_enabled=false;ctlhexcase_apply.p_enabled=false;
      ctl_quote_wordval.p_enabled=false;ctl_quote_wordval_apply.p_enabled=false;
      ctl_quote_numval.p_enabled=false;ctl_quote_numval_apply.p_enabled=false;
   }



   populate_combobox_from(tagcase_map, _control ctltagcase, tagcase,tagcase_apply);
   populate_combobox_from(tagcase_map, _control ctlattribcase, attribcase,attribcase_apply);
   populate_combobox_from(tagcase_map, _control ctlwordcase, wordvalcase,wordvalcase_apply);
   populate_combobox_from(hexcase_map, _control ctlhexcase, hexvalcase,hexvalcase_apply);
   populate_combobox_from(quotestyle_map, _control ctl_quote_wordval, quote_wordval,quote_wordval_apply);
   populate_combobox_from(quotestyle_map, _control ctl_quote_numval, quote_numval,quote_numval_apply);

   populate_combobox_from(quotestyle_map, _control ctl_quote_all_values, quote_all_vals,null);

   // Quote all values
   //ctl_quote_all_values.p_text= (quote_all_vals!=0)?quotestyle_map:[QUOTESTYLE_YES]:quotestyle_map:[QUOTESTYLE_NO];

   //ctl_quote_all_vals.call_event(ctl_quote_all_vals,LBUTTON_UP,'W');

   return;
}

static int maybeint(typeless val, int defval) 
{
   if (isinteger(val)) {
      return (int)val;
   }
   return defval;
}

static void oncreateComments(int ibeautifier)
{
   if (_haveBeautifiers()) {
      typeless indent_col1_comments= (_beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_COL1_COMMENTS)!=0);
      //typeless tcomment=s_p->style:["tcomment"]; indent_code_from_tag
      indent_from_tag := _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_INDENT_CODE_FROM_TAG,0);
      tag_indent_follows_code := _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_MOD_TAG_INDENT,1);
      closing_tag_own_line := _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_ML_CLOSING_TAG,1);
      multi_line_closing_block := _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_ML_CLOSING_BLOCK,1);
      default_embedded := _beautifier_get_property(ibeautifier,VSCFGP_BEAUTIFIER_DEFAULT_EMBEDDED_LANG,'phpscript');

      if (default_embedded=='') {
         default_embedded = "phpscript";
      }

      //if( !isinteger(tcomment) || tcomment<TCOMMENT_COLUMN || tcomment>TCOMMENT_ABSOLUTE ) {
      //   tcomment=TCOMMENT_RELATIVE;
      //}
      /*typeless tcomment_col=s_p->style:["tcomment_col"];
      if( !isinteger(tcomment_col) || tcomment_col<1 ) {
         tcomment_col=0;
         if( tcomment==TCOMMENT_COLUMN ) {
            // An invalid comment column invalidates this setting
            tcomment=TCOMMENT_RELATIVE;
         }
      } */

      // Now set the controls
      ctlindent_col1_comments.p_value=indent_col1_comments;
      ctl_emb_indent_from_tag.p_value=maybeint(indent_from_tag,0);
      ctl_emb_mod_tag_indent.p_value=maybeint(tag_indent_follows_code,1);
      ctl_emb_ml_closing_tag.p_value=maybeint(closing_tag_own_line,1);
      ctl_emb_closing_block.p_value=maybeint(multi_line_closing_block,1);

      first := false;
      ctl_emb_default_language.p_cb_text_box._lbclear();
      foreach (auto k in supported_embedded_languages) {
         ctl_emb_default_language.p_cb_list_box._lbadd_item(_LangGetModeName(k));
         if (first || k == default_embedded) {
            ctl_emb_default_language.p_cb_text_box.p_text=_LangGetModeName(k);
         }
      }
      ctl_emb_default_language._lbsort('A');

      ctl_emb_edit.p_enabled = new_beautifier_supported_language(default_embedded);
   }
   return;
}

void ctl_emb_edit.lbutton_up()
{
   auto langid = _Modename2LangId(ctl_emb_default_language.p_cb_text_box.p_text);
   prof := LanguageSettings.getBeautifierProfileName(langid);

   _beautifier_edit_profile(prof, langid);
}


void ctl_emb_indent_from_tag.lbutton_up()
{
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_INDENT_CODE_FROM_TAG,p_value);
   _ModifyScheme();
   maybe_update_preview();
}
void ctl_emb_mod_tag_indent.lbutton_up()
{
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_MOD_TAG_INDENT,p_value);
   _ModifyScheme();
   maybe_update_preview();
}
void ctl_emb_ml_closing_tag.lbutton_up()
{
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_ML_CLOSING_TAG,p_value);
   _ModifyScheme();
   maybe_update_preview();
}
void ctl_emb_closing_block.lbutton_up()
{
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_ML_CLOSING_BLOCK,p_value);
   _ModifyScheme();
   maybe_update_preview();
}

void ctl_emb_default_language.on_change()
{
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_DEFAULT_EMBEDDED_LANG,_Modename2LangId(p_text));
   ctl_emb_edit.p_enabled = new_beautifier_supported_language(_Modename2LangId(ctl_emb_default_language.p_cb_text_box.p_text));
   _ModifyScheme();
   maybe_update_preview();
}
void ctlindent_col1_comments.lbutton_up() {
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_INDENT_COL1_COMMENTS,p_value);
   _ModifyScheme();
   maybe_update_preview();
}

// Split out of the on_create function so 
// it can be called by both of our init paths.
// (gui-beautify and embedded in the options dialog)
static typeless initDialog(_str lang, _str caption,_str profileName)
{
   gDialogSaved = false;
   gInitialized = false;

   _html_beautify_form_initial_alignment();
   _SetDialogInfoHt(BEAUT_DISPLAY_TIMER, -1);

   // arg(1) is historically the extension used to find the beautifier
   // form (e.g. CFML uses the HTML form, so arg(1)='html'.
   // arg(2) is the canonical language ID of the file being beautified.


   int editorctl_wid=_form_parent();
   if ((editorctl_wid && !editorctl_wid._isEditorCtl()) ||
       (editorctl_wid._QReadOnly())) {
      editorctl_wid=0;
   }

   gCanBeautifyTarget = editorctl_wid != 0;

   if (!gCanBeautifyTarget) {
      ctlgo.p_caption = "OK";
   }

   msg := "";

   if (!_haveBeautifiers()) {
      caption = " ";
   }

   if( lang=="" ) {
      lang=_mdi.p_child.p_LangId;
   }
   if( lang=="" ) {
      // This can happen when the template for the form is being loaded.
      return("");
   }
   gLangId=lang;
   if (profileName=='') {
      profileName=LanguageSettings.getBeautifierProfileName(lang);
   }
   gProfileName=profileName;
   gibeautifier=_beautifier_create(lang);
   status:=_beautifier_set_properties(gibeautifier,vsCfgPackage_for_LangBeautifierProfiles(lang),profileName);

   if( caption!="" ) {
      p_active_form.p_caption=caption": "profileName;
   } else {
      p_active_form.p_caption="Beautifier "lang": "profileName;
   }


   //_InitStyle(scheme.style,lang);


   //htmScheme_t scheme;
   //htmScheme_t s:[];
   //scheme._makeempty();
   //_InitStyle(scheme.style,lang);
   // Guarantee that these atleast get set to the same value as "indent_amount"
   //scheme.style:["tab_size"]= -1;
   //scheme.style:["original_tab_size"]= -1;
   //_InitAllTags(scheme.tags,lang);
   //_InitComments(scheme.comments,lang);
   //sname := profileName;
   //s:[sname]=scheme;
   //himport_profile(s,lang,sname);
   //scheme=s:[sname];

   // Set the help by language
   if( _LanguageInheritsFrom('xml',gLangId) ) {
      ctlhelp.p_help="XML Beautifier dialog box";
   } else {
      ctlhelp.p_help="HTML Beautifier dialog box";
   }

   oncreateIndent(gibeautifier);
   oncreateTags(gibeautifier);
   oncreateAttribs(gibeautifier);
   oncreateComments(gibeautifier);
   //oncreateAdvanced(&scheme);

   // Remember the active tab
   ctlsstab._retrieve_value();
   //ctlsstab.p_ActiveTab=INDENTTAB;

   // Selection
   if( _mdi.p_child.select_active() ) {
      ctlselection_only.p_enabled=true;
      ctlselection_only.p_value=1;
   } else {
      ctlselection_only.p_enabled=false;
   }

   gInitialized = true;
   maybe_update_preview();
   return(0);
}


typeless ctlgo.on_create(_str notused_arg1="", _str lang="", 
                         _str notused_arg3="", _str caption="",_str profileName='')
{
   // Defer initialization for standard edition, which is 
   // embedded in the options dialog.
   if (_haveBeautifiers() && p_active_form.p_name=='_html_beautify_form') {
      return initDialog(lang, caption,profileName);
   }
   return 0;
}

void ctlgo.lbutton_up()
{
   // Save the user default and dialog settings
   typeless status=ctlsave.call_event(ctlsave,LBUTTON_UP);
   if( status ) {
      return;
   }

   if (gCanBeautifyTarget) {

      selection := (ctlselection_only.p_enabled && ctlselection_only.p_value!=0);

      int editorctl_wid=_form_parent();
      beautifier_schedule_deferred_update(-1, p_active_form);
      p_active_form._delete_window();
      p_window_id=editorctl_wid;

      // save bookmark, breakpoint, and annotation information
      editorctl_wid._SaveMarkersInFile(auto markerSaves);

      if (new_beautifier_supported_language(gLangId)) {
         beautify_with_profile(gProfileName);
      }

      // restore bookmarks, breakpoints, and annotation locations
      editorctl_wid._RestoreMmrkersInFile(markerSaves);
   } else {
      p_active_form._delete_window("");
   }
}

void ctlgo.on_destroy()
{
   // Remember the active tab
   ctlsstab._append_retrieve(ctlsstab,ctlsstab.p_ActiveTab);

   return;
}

int ctlsave.lbutton_up()
{
   if (have_invalid_fields()) return 1;
   hformatSaveScheme(gibeautifier,gLangId, gProfileName);

   // Configuration was saved, so change the "Cancel" caption to "Close"
   ctlcancel.p_caption='Cl&ose';
   gDialogSaved=true;

   return(0);
}

void ctlreset.lbutton_up()
{
   // Remember the current tab and the tag list position
   typeless p;
   tagname := "";
   typeless isline_selected=false;
   typeless old_tabinfo=ctlsstab.p_ActiveTab;
   line := ctltag_list.p_line;
   if( line ) {
      tagname=get_tag_name();
      isline_selected=ctltag_list._lbisline_selected();
      ctltag_list.save_pos(p);
   }

   status:=_beautifier_set_properties(gibeautifier,vsCfgPackage_for_LangBeautifierProfiles(gLangId),gProfileName);
   oncreateIndent(gibeautifier);
   oncreateTags(gibeautifier);
   oncreateAttribs(gibeautifier);
   oncreateComments(gibeautifier);

   // Restore the current tab and the tag list pos
   ctlsstab.p_ActiveTab = old_tabinfo;

   status2:=ctltag_list._lbsearch(tagname);
   if( !status2 ) {
      // The previously active tag still exists, so restore list position
      ctltag_list.restore_pos(p);
      if( isline_selected ) ctltag_list._lbselect_line();
      ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE,"W");
   }

   return;
}

static void _ModifyScheme()
{
   gOriginalSchemeModified=true;
}

void ctlindent.on_destroy()
{
   _beautifier_destroy(gibeautifier);
}
void ctlindent_with_tabs.lbutton_up()
{
   _ModifyScheme();
}
//void ctl_brokentag_style_indent.lbutton_up()
//{
//   // Text box is enabled when radio button is checked
//   ctl_brokentag_indent.p_enabled= (ctl_brokentag_style_indent.p_value!=0);
//
//   _ModifyScheme();
//
//   return;
//}
//void ctl_brokentag_indent.on_change()
//{
//   _ModifyScheme();
//
//   return;
//}

static bool is_embedded_code_tag(_str tagname)
{
   return tagname == '%' || tagname == '%!' || tagname == '%=' || tagname == '%@';
}

static void update_preview_text(_str tagname, int hasendtag, int has_nl_within)
{
   nl := _ctl_preview.p_newline;

   if ( tagname == HF_DEFAULT_TAG_NAME || tagname==BEAUT_DEFAULT_TAG_NAME) {
      tagname="DefaultTag";
   }

   //tagname = translate(tagname, "____", "()[]");

   if (_haveBeautifiers()) {
      if ( tagname == '!--' ) {
         // Comment configuration...
         gTagPreview = '<someParentTag>'nl'<!-- Column 1 comment -->'nl'<!-- this is a standalone'nl'comment -->'nl'</someParentTag>';
      } else if ( tagname == '?' || tagname == '?=') {
         gTagPreview = '<someParentTag>'nl'<'tagname' doSomething(a,b,c) ?>'nl'trailing content'nl'</someParentTag>';
      } else if (is_embedded_code_tag(tagname)) {
         gTagPreview = '<someParentTag>'nl'<'tagname' doSomething(a,b,c) %>'nl'trailing content'nl'</someParentTag>';
      } else {
         if (hasendtag > 0) {
            if (has_nl_within == 0) {
               gTagPreview = '<'tagname'>'nl'<'tagname :+ 
                  '>       content with leading whitespace 'nl'that spans'nl'several lines ' :+
                  '</'tagname'>'nl'...more content...'nl'</'tagname'>';
            } else {
               gTagPreview = '<'tagname'>'nl'<'tagname :+ 
                  '>       content with leading whitespace 'nl'that spans'nl'several lines ' :+
                  '<someChildTag X="Y"/>'nl'</'tagname'>'nl'...more content...'nl'</'tagname'>';
            }
         } else {
            gTagPreview = '<someParentTag>'nl'leading content <'tagname' A="1" B="x" C="#ffff00"/> and trailing content'nl'</someParentTag>';
         }
      }
      maybe_update_preview();
   } else {
      _str cfgtag = resolveTagname(tagname);

      if (tagname == "!--") {
         gTagPreview = "<!-- It's a comment -->"nl"<"ptag("atag")"/>";
      } else if ( tagname == '?' || tagname == '?=') {
         gTagPreview = '<'ptag(tagname)' doSomething(a,b,c) ?>'nl;
      } else if (is_embedded_code_tag(cfgtag)) {
         gTagPreview = '<'ptag(tagname)' doSomething(a,b,c) %>';
      } else {
         ind := ctlindenttags.p_value ? currentIndentString() : '';
         if (hasendtag > 0) {
            if (has_nl_within == 0) {
               gTagPreview = '<'ptag(tagname) :+ 
                  '>Some content.' :+ 
                  '</'ptag(tagname)'>'nl;
            } else {
               gTagPreview = '<'ptag(tagname) :+ 
                  '>'nl :+ ind'Some content'nl :+
                  '</'ptag(tagname)'>';
            }
         } else {
            gTagPreview = '<'ptag(tagname)' 'pattrib("A")'="1" 'pattrib("B")'="x"/>';
         }
      }
   }
}

static void populate_parent_tag_combo(int ibeautifier, int cb, _str parent, _str referrer = "")
{
   cb.p_cb_list_box._lbclear();
   cb.p_cb_list_box._lbadd_item(NO_PARENT_TAG);

   if (parent == '') {
      parent = NO_PARENT_TAG;
   }
   _str tagNames[];
   _beautifier_list_tags(ibeautifier,tagNames);
   for(i:=0;i<tagNames._length(); ++i) {
      _str name=tagNames[i];
      if (name==BEAUT_DEFAULT_TAG_NAME) {
         name=HF_DEFAULT_TAG_NAME;
      }
      if (name == referrer) {
         continue;
      }
      if (get_tag_parent(ibeautifier,name)!=NO_PARENT_TAG) {
         continue;
      }
      cb.p_cb_list_box._lbadd_item(name);
   }

   cb.p_cb_list_box._lbsort('A');
   cb.p_cb_text_box.p_text = parent;
}

static void change_tag_ctl_enabled(bool enabled)
{
   ctl_tag_linebreaks_frame.p_enabled = enabled;
   ctl_tag_content_frame.p_enabled = enabled;
   ctl_allowed_child_frame.p_enabled = enabled;
   ctl_general.p_enabled = enabled;
}
static void copy_tag_properties(int ibeautifier,_str from_tag,_str to_tag) {
   XmlCfgPropertyInfo array[];
   prefix := from_tag:+VSXMLCFG_PROPERTY_SEPARATOR;
   _beautifier_list_properties(ibeautifier,array,prefix);
   for (i:=0;i<array._length();++i) {
      name:=substr(array[i].name,length(prefix)+1);

      if (array[i].apply) {
         _beautifier_set_tag_property(ibeautifier,to_tag,name,array[i].value);
      } else {
         _beautifier_set_tag_property(ibeautifier,to_tag,name,array[i].value,false);
      }
   }
}
void ctl_parent_tag.on_change()
{
   if (gTagParentUpdateInhibited) {
      return;
   }

   tagname := get_tag_name();
   //tags := ctltag_list.p_user;

   if (tag_exists(gibeautifier,tagname)) {
      old_parent := get_tag_parent(gibeautifier,tagname);

      new_parent := ctl_parent_tag.p_cb_text_box.p_text;
      if (new_parent == NO_PARENT_TAG) {
         copy_tag_properties(gibeautifier,old_parent,tagname);
         //tags:[tagname] = tags:[from_tag];
         _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG,'');
      } else {
         // Just delete this tag and all properties. Just want parent_tag property
         _beautifier_delete_tag(gibeautifier,tagname);
         _beautifier_set_tag_property(gibeautifier,tagname,'','');  // Define this tag
         _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG,new_parent);
      }
      //ctltag_list.p_user = tags;
      ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE, "W");
   }
}

static bool _is_this_tag_referenced_as_parent(int ibeautifier,_str tagname) {
   if (tagname=='' || tagname==HF_DEFAULT_TAG_NAME) {
      return false;
   }
   //if( !_LanguageInheritsFrom('xml',gLangId) ) tagname=lowcase(tagname);
   XmlCfgPropertyInfo array[];
   _beautifier_list_properties(ibeautifier,array,'^[^'VSXMLCFG_PROPERTY_SEPARATOR']+'VSXMLCFG_PROPERTY_SEPARATOR:+VSCFGP_BEAUTIFIER_PARENT_TAG"$","r",tagname);
   return array._length()!=0;
}


void ctltag_list.on_change()
{
   typeless tags:[];
   typeless tag:[];
   tagname := "";
   orig_tagname := "";
   msg := "";
   typeless reformat_content=false;
   typeless literal_content=false;
   typeless endtag=false;
   typeless endtag_required=false;
   typeless preserve_body=false;
   typeless preserve_position=false;
   noflines_before := "0";
   noflines_after := "0";
   lb_within := "1";

   if( p_Nofselected ) {
      orig_tagname = tagname=get_tag_name();
      if( tagname!="" ) {
         int i;

         if( !tag_exists(gibeautifier,tagname) ) {
            // This should never happen
            msg='Invalid tag entry for "':+tagname:+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return;
         }

         rfc := _is_this_tag_referenced_as_parent(gibeautifier,tagname);
         ctlremove_tag.p_enabled = !rfc && tagname!=BEAUT_DEFAULT_TAG_NAME;
         ctl_parent_tag.p_enabled = !rfc && tagname!=BEAUT_DEFAULT_TAG_NAME;

         //ctlremove_tag.p_enabled=true;

         gTagParentUpdateInhibited = true;
         parent_tag:=get_tag_parent(gibeautifier,tagname);
         if (parent_tag!= NO_PARENT_TAG) {
            populate_parent_tag_combo(gibeautifier, _control ctl_parent_tag, parent_tag, tagname);
            tagname = parent_tag;
            change_tag_ctl_enabled(false);
         } else {
            populate_parent_tag_combo(gibeautifier, _control ctl_parent_tag, NO_PARENT_TAG, tagname);
            change_tag_ctl_enabled(true);
         }
         gTagParentUpdateInhibited=false;

         for (i = 1; i < ctl_allowed_tags._TreeGetNumChildren(TREE_ROOT_INDEX); i++) {
            ctl_allowed_tags._TreeSetCheckState(i, 0);
         }

         valid_child_tags:=_beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_VALID_CHILD_TAGS);
         if (valid_child_tags!='') {
            _str ac = valid_child_tags;
            _str tgs:[];

            split_allowed_tags(tgs, ac);

            foreach (auto k => auto v in tgs) {
               idx := ctl_allowed_tags._TreeSearch(TREE_ROOT_INDEX, k);

               if (idx != -1) {
                  ctl_allowed_tags._TreeSetCheckState(idx, 1);
               }
            }
            _ctl_label_numsel.p_caption = (tgs._length())" tags selected";

         } else {
            _ctl_label_numsel.p_caption = "0 tags selected";
         }

         // Content
         content_style:=_beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_CONTENT_STYLE);
         ctlwordwraptext.p_enabled=true;
         ctlpreservetext.p_enabled=true;
         if (strieq(content_style,'Preserve')) {
            ctlpreservetext.p_value=1;
            ctlpreservetags.p_enabled=true;
            preserve_child_tags:=_beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS);
            if (preserve_child_tags!='0') {
               ctlpreservetags.p_value=1;
            } else {
               ctlpreservetags.p_value=0;
            }
         } else {
            ctlwordwraptext.p_value=1;
            ctlpreservetags.p_enabled=false;
         }
         indent_tags:=_beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_INDENT_TAGS);
         ctlindenttags.p_value=indent_tags?1:0;

         endtag= _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_END_TAG)!=0;
         endtag_required= (endtag && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_END_TAG_REQUIRED)!=0);
         preserve_position= _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PRESERVE_START_TAG_INDENT)==1;

         //,"new_lines_before_start_tag"
         noflines_before=get_tag_newlines(gibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG);
         populate_newlines_combobox(ctlnoflines_before, 5, (_str)noflines_before);
         noflines_after=get_tag_newlines(gibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG);
         populate_newlines_combobox(ctlnoflines_after, 5, (_str)noflines_after);

         lb_within=get_tag_lb_within(gibeautifier,tagname);
         populate_newlines_combobox(_control ctl_lb_within, 1, (_str)lb_within);

         standalone := p_active_form._find_control('_ctl_standalone');
         standalone_val := false;
         if (standalone != 0) {
            standalone_val = get_tag_standalone(gibeautifier,tagname)!=0;
         }

         ctlendtag.p_enabled=true;

         ctlendtag_required.p_enabled=true;
         if (_LanguageInheritsFrom('html', gLangId)) {
            ctl_allowed_child_frame.p_enabled = (endtag_required == "0");
         } else {
            ctl_allowed_child_frame.p_enabled = false;
         }

         if (standalone != 0) {
            standalone.p_value = (int)standalone_val;
            standalone.p_enabled = true;
         }

         //ctlpreserve_body.p_enabled=true;
         ctlpreserve_position.p_enabled=true;
         ctlnoflines_before.p_enabled=true;
         ctlnoflines_after.p_enabled=true;

         ctlendtag.p_value=endtag;
         ctlendtag_required.p_value=endtag_required;
         ctlendtag_required.p_enabled= (ctlendtag.p_value!=0);
         ctlpreserve_position.p_value=preserve_position;

         // Linebreaks before open tag
         ctlnoflines_before.p_ReadOnly=false;
         ctlnoflines_before.p_text=noflines_before;
         ctlnoflines_before.p_ReadOnly=true;
         ctlnoflines_before.p_enabled= (ctlpreserve_position.p_value==0);
         // Linebreaks after close tag
         ctlnoflines_after.p_ReadOnly=false;
         ctlnoflines_after.p_text=noflines_after;
         ctlnoflines_after.p_ReadOnly=true;
         ctlnoflines_after.p_enabled= (ctlpreserve_position.p_value==0);

         ctl_lb_within.p_ReadOnly=false;
         ctl_lb_within.p_text=lb_within;
         ctl_lb_within.p_ReadOnly=true;
         ctl_lb_within.p_enabled= (ctlpreserve_position.p_value==0);

         update_preview_text(orig_tagname, endtag, has_nls_within(lb_within));
         maybe_update_preview();
      }
   } else {
      // No tag selected, so gray out options
      ctlwordwraptext.p_enabled=false;
      ctlpreservetext.p_enabled=false;
      ctlpreservetags.p_enabled=false;
      ctlindenttags.p_enabled=false;
      ctlendtag.p_enabled=false;
      ctlendtag_required.p_enabled=false;
      //ctlpreserve_body.p_enabled=false;
      ctlpreserve_position.p_enabled=false;
      ctlnoflines_before.p_enabled=false;
      ctlnoflines_after.p_enabled=false;
      ctlremove_tag.p_enabled=false;
      ctl_parent_tag.p_enabled = false;
      standalone := p_active_form._find_control('_ctl_standalone');
      if (standalone != 0) {
         standalone.p_enabled = false;
      }
   }

   return;
}
void ctltag_list.'!'-'~'()
{
   bool found_one;

   found_one=true;

   _str event=last_event();
   if( length(event)!=1 ) {
      return;
   }
   old_line := p_line;
   _lbdeselect_all();
   lastData := '';
   status := (int)_lbi_search(lastData, event, 'ir@');
   if( status ) {
      // String not found, so try it from the top
      save_pos(auto p);
      _lbtop();
      lastData='';
      status=(int)_lbi_search(lastData, event,'ir@');
      if( status ) {
         // String not found, so restore to previous line
         restore_pos(p);
         found_one=false;
      }
   } else {
      if( old_line==p_line && p_line!=p_Noflines ) {
         // On the same line, so find next occurrence
         status=(int)_lbi_search(lastData, event,'ir@');
         if( status ) {
            // String not found, so try it from the top
            _lbtop();
            status=(int)_lbi_search(lastData, event,'ir@');;
         }
         if( status ) {
            // String not found
            found_one=false;
         }
      }
   }
   _lbselect_line();

   if( found_one ) {
      ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE,"W");
   }

   return;
}


void ctlwordwraptext.lbutton_up()
{
   typeless tags:[];

   ctlpreservetags.p_enabled=false;
   _ModifyScheme();
   tagname := get_tag_name();
   if( tagname!=""  && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_CONTENT_STYLE,'Wrap');
   }
   _ModifyScheme();
   maybe_update_preview();
   return;
}
void ctlpreservetext.lbutton_up()
{
   typeless tags:[];

   ctlpreservetags.p_enabled=true;
   _ModifyScheme();
   tagname := get_tag_name();
   if( tagname!="" && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_CONTENT_STYLE,'Preserve');
   }
   _ModifyScheme();
   maybe_update_preview();
   return;
}
void ctlpreservetags.lbutton_up()
{
   typeless tags:[];

   ctlpreservetags.p_enabled=true;
   _ModifyScheme();
   tagname := get_tag_name();
   if( tagname!="" && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PRESERVE_CHILD_TAGS,p_value);
   }
   _ModifyScheme();
   maybe_update_preview();
   return;
}
void ctlindenttags.lbutton_up()
{
   typeless tags:[];

   _ModifyScheme();
   tagname := get_tag_name();
   if( tagname!="" && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_INDENT_TAGS,p_value);
   }
   _ModifyScheme();
   maybe_update_preview();

   return;
}

void ctlendtag.lbutton_up()
{
   typeless tags:[];

   ctlendtag_required.p_enabled= (p_value!=0);
   tagname := get_tag_name();
   if( tagname!="" && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      ///tags=ctltag_list.p_user;
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_END_TAG,p_value);
      //ctltag_list.p_user=tags;
   }

   _ModifyScheme();
   update_preview_text(tagname, p_value, has_nls_within(ctl_lb_within.p_text));
   return;
}
void ctlendtag_required.lbutton_up()
{
   typeless tags:[];

   _ModifyScheme();
   tagname := get_tag_name();
   if( tagname!="" && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_END_TAG_REQUIRED,p_value);
   }

   if (_LanguageInheritsFrom('html',gLangId)) {
      ctl_allowed_child_frame.p_enabled = (p_value == 0);
   }

   _ModifyScheme();
   maybe_update_preview();
   return;
}

void ctlpreserve_position.lbutton_up()
{
   typeless tags:[];

   ctlnoflines_before.p_enabled= (p_value==0);
   ctlnoflines_after.p_enabled= (p_value==0);
   ctl_lb_within.p_enabled= (p_value==0);
   _ModifyScheme();
   tagname := get_tag_name();
   if( tagname!="" && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PRESERVE_START_TAG_INDENT,p_value);
   }

   _ModifyScheme();
   maybe_update_preview();
   return;
}

void ctl_lb_within.on_change()
{
   tagname := get_tag_name();
   if( tagname!="" && p_visible && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      //tags := ctltag_list.p_user;
      set_tag_lb_within(gibeautifier,tagname,p_text);
      //ctltag_list.p_user = tags;
   }
   _ModifyScheme();
   maybe_update_preview();
}

void ctlnoflines_before.on_change()
{
   tagname := get_tag_name();
   if( tagname!="" && p_visible && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      value:=_beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG,0,auto apply);
      apply=p_text!=NEWLINES_DISABLED;
      if (isinteger(p_text)) {
         value=p_text;
      }
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG,value,apply);
   }
   _ModifyScheme();
   maybe_update_preview();
}

void ctlnoflines_after.on_change()
{
   tagname := get_tag_name();
   if( tagname!=""  && p_visible && _beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG)=='') {
      value:=_beautifier_get_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG,0,auto apply);
      apply=p_text!=NEWLINES_DISABLED;
      if (isinteger(p_text)) {
         value=p_text;
      }
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG,value,apply);
   }
   _ModifyScheme();
   maybe_update_preview();
}


static void add_tag_list(_str list[], _str tag_parent = "")
{
   int i;
   
   for( i=0;i<list._length();++i ) {
      tagname:=list[i];
      if( !_LanguageInheritsFrom('xml',gLangId) ) list[i]=tagname=lowcase(tagname);
      if( tag_exists(gibeautifier,tagname) ) {
         msg:='Tag "':+tagname:+'" already exists. Do you want to replace it?';
         status:=_message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
         if( status!=IDYES ) {
            list._deleteel(i);
            continue;
         }
      }
      if (tag_parent == "" || tag_parent == NO_PARENT_TAG) {
         _InitTag(gibeautifier,tagname,gLangId);
      } else {
         // Just delete this tag and all properties. Just want parent_tag property
         _beautifier_delete_tag(gibeautifier,tagname);
         _beautifier_set_tag_property(gibeautifier,tagname,'','');  // Define this tag
         _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_PARENT_TAG,tag_parent);
      }
   }

   line := "";
   for( i=0;i<list._length();++i ) {
      tagname:=list[i];
      status:=ctltag_list._lbsearch(tagname,'e');
      if( status ) {
         // It is not in the list, so put it there sorted
         ctltag_list._lbtop();
         line=ctltag_list._lbget_text();
         // Do not allow user to remove the default tag
         if( line:==HF_DEFAULT_TAG_NAME ) ctltag_list._lbdown();
         for(;;) {
            line=ctltag_list._lbget_text();
            if( tagname:<line ) {
               ctltag_list._lbup();
               ctltag_list._lbadd_item(tagname);
               idx := ctl_allowed_tags._TreeAddListItem(i);
               ctl_allowed_tags._TreeSetCheckState(idx, 0);
               ctl_allowed_tags._TreeSortCol(0);
               break;
            }
            if( ctltag_list._lbdown() ) {
               ctltag_list._lbadd_item(tagname);
               break;
            }
         }
      }
   }

   _ModifyScheme();

   // Select the first tag in the list
   tagname:="";
   if( list._length() ) tagname=list[0];
   ctltag_list._lbsearch(tagname,'e');
   ctltag_list._lbdeselect_all();
   ctltag_list._lbselect_line();
   ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE,"W");
}

static void break_tag_list(_str (&list)[], _str tags)
{
   _str tagname;

   // One or more tags in a space-delimited list
   while( tags!="" ) {
      parse tags with tagname tags;
      tagname=strip(tagname,'L','(');
      tagname=strip(tagname,'T',')');
      if( '('upcase(tagname)')':==HF_DEFAULT_TAG_NAME || '('lowcase(tagname)')':==BEAUT_DEFAULT_TAG_NAME) continue;
      list[list._length()]=tagname;
   }
}

void ctladd_tag.lbutton_up()
{
   typeless tags:[];

   //status=show("-modal _textbox_form","Add Tag",0,"","?Type in the name of the tag you want to add without <>","","","Tag");
   typeless status=show("-modal _html_beautify_add_tag_form", ctltag_list);
   if( status=="" ) {
      // User probably cancelled
      return;
   }
   typeless result=_param1;
   if (pos(VSXMLCFG_PROPERTY_SEPARATOR,result)) {
      _message_box(nls("The character '%s' is not allowed in tag names",VSXMLCFG_PROPERTY_SEPARATOR));
      return;
   }
   if (pos(VSXMLCFG_PROPERTY_ESCAPECHAR,result)) {
      _message_box(nls("The character '%s' is not allowed in tag names",VSXMLCFG_PROPERTY_ESCAPECHAR));
      return;
   }
   if( result=="" ) {
      return;
   }

   parent := _param2;
   _str list[];
   if( upcase(result)=='.DTD.' ) {
      // User wants us to get tags from current file's DTD
      wid := _mdi.p_child;
      if( !wid._isEditorCtl() || !wid._LanguageInheritsFrom('xml') || substr(wid.p_mode_name,1,3)!='XML' ) {
         msg := "No DTD specified or cannot get elements from DTD";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return;
      }
      tag_filename := wid._xml_GetConfigTagFile();
      if( tag_filename!=""  && _haveContextTagging()) {
         tag_close_db(tag_filename);
         status=tag_read_db(tag_filename);
         if( status >= 0 ) {
            status=tag_find_global(SE_TAG_TYPE_TAG,0,0);
            while( !status ) {
               tag_get_tag_browse_info(auto cm);
               list :+= cm.member_name;
               status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
            }
            tag_reset_find_in_class();
         }
         tag_close_db(tag_filename);
      }
      list._sort();
      add_tag_list(list);
   } else {
      break_tag_list(list, result);
      list._sort();
      add_tag_list(list, parent);
   }

   return;
}

static _str references_to(int ibeautifier, _str tagname, int& ct) {
   rv := "";

   // List all tags with a parent_tag property
   XmlCfgPropertyInfo array[];
   _beautifier_list_properties(ibeautifier,array,'^[^'VSXMLCFG_PROPERTY_SEPARATOR']+'VSXMLCFG_PROPERTY_SEPARATOR:+VSCFGP_BEAUTIFIER_PARENT_TAG"$","r",tagname);
   for (i:=0;i<array._length();++i) {
      parent_tag:=get_tag_parent(ibeautifier,tagname);
      if (parent_tag == tagname) {
         rv :+= array[i].value:+" ";
         ct += 1;
      }
   }

   return rv;
}

void ctlremove_tag.lbutton_up()
{
   typeless tags:[];
   tagname := "";

   if( !ctltag_list.p_Nofselected ) {
      return;
   }


   typeless status=ctltag_list._lbfind_selected(true);
   while( !status ) {
      tagname=get_tag_name();
      has_references := _is_this_tag_referenced_as_parent(gibeautifier,tagname);

      if (has_references) {
         ct := 0;
         refstr := references_to(gibeautifier, tagname, ct);
         _message_box("Can not delete <"tagname"> because it is referenced by "ct" tags: "refstr);
      } else {
         if( tagname!="" && tagname!=BEAUT_DEFAULT_TAG_NAME ) {
            _beautifier_delete_tag(gibeautifier,tagname);
            ctltag_list._lbdelete_item();
            ctltag_list._lbup();
         }
      }
      status=ctltag_list._lbfind_selected(false);
   }
   ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE,"W");

   _ModifyScheme();
   maybe_update_preview();

   return;
}

void ctltagcase.on_change()
{
   read_combobox_with(tagcase_map,ctltagcase,auto ivalue);
   bool apply;
   if (ctltagcase_apply.p_object==OI_CHECK_BOX) {
      apply=ctltagcase_apply.p_value?true:false;
   } else {
      _beautifier_get_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_TAG_NAME,'',apply);
   }
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_TAG_NAME,ivalue,apply);
   _ModifyScheme();
   maybe_update_preview();
}

void ctltagcase_apply.lbutton_up()
{
   read_combobox_with(tagcase_map,ctltagcase,auto ivalue);
   bool apply;
   if (ctltagcase_apply.p_object==OI_CHECK_BOX) {
      apply=ctltagcase_apply.p_value?true:false;
   } else {
      _beautifier_get_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_TAG_NAME,'',apply);
   }
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_TAG_NAME,ivalue,apply);
   _ModifyScheme();
   maybe_update_preview();
}

void ctlattribcase.on_change()
{
   read_combobox_with(tagcase_map,ctlattribcase,auto ivalue);
   bool apply;
   if (ctlattribcase_apply.p_object==OI_CHECK_BOX) {
      apply=ctlattribcase_apply.p_value?true:false;
   } else {
      _beautifier_get_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_NAME,'',apply);
   }
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_NAME,ivalue,apply);
   _ModifyScheme();
   maybe_update_preview();
}
void ctlattribcase_apply.lbutton_up()
{
   read_combobox_with(tagcase_map,ctlattribcase,auto ivalue);
   bool apply;
   if (ctlattribcase_apply.p_object==OI_CHECK_BOX) {
      apply=ctlattribcase_apply.p_value?true:false;
   } else {
      _beautifier_get_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_NAME,'',apply);
   }
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_NAME,ivalue,apply);
   _ModifyScheme();
   maybe_update_preview();
}

void ctlwordcase.on_change()
{
   read_combobox_with(tagcase_map,ctlwordcase,auto ivalue);
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_WORD_VALUE,ivalue,ctlwordcase_apply.p_value?true:false);
   _ModifyScheme();
   maybe_update_preview();
}
void ctlwordcase_apply.lbutton_up()
{
   read_combobox_with(tagcase_map,ctlwordcase,auto ivalue);
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_WORD_VALUE,ivalue,ctlwordcase_apply.p_value?true:false);
   _ModifyScheme();
   maybe_update_preview();
}

void ctlhexcase.on_change()
{
   read_combobox_with(tagcase_map,ctlhexcase,auto ivalue);
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_HEX_VALUE,ivalue,ctlhexcase_apply.p_value?true:false);
   _ModifyScheme();
   maybe_update_preview();
}
void ctlhexcase_apply.lbutton_up()
{
   read_combobox_with(tagcase_map,ctlhexcase,auto ivalue);
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_WC_ATTR_HEX_VALUE,ivalue,ctlhexcase_apply.p_value?true:false);
   _ModifyScheme();
   maybe_update_preview();
}

void ctl_quote_wordval.on_change()
{
   read_combobox_with(quotestyle_map,ctl_quote_wordval,auto ivalue);
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_QUOTE_ATTR_WORD_VALUE,ivalue,ctl_quote_wordval_apply.p_value?true:false);
   _ModifyScheme();
   maybe_update_preview();
}
void ctl_quote_wordval_apply.lbutton_up()
{
   read_combobox_with(quotestyle_map,ctl_quote_wordval,auto ivalue);
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_QUOTE_ATTR_WORD_VALUE,ivalue,ctl_quote_wordval_apply.p_value?true:false);
   _ModifyScheme();
   maybe_update_preview();
}

void ctl_quote_numval.on_change()
{
   read_combobox_with(quotestyle_map,ctl_quote_numval,auto ivalue);
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_QUOTE_ATTR_NUMBER_VALUE,ivalue,ctl_quote_numval_apply.p_value?true:false);
   _ModifyScheme();
   maybe_update_preview();
}
void ctl_quote_numval_apply.lbutton_up()
{
   read_combobox_with(quotestyle_map,ctl_quote_numval,auto ivalue);
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_QUOTE_ATTR_NUMBER_VALUE,ivalue,ctl_quote_numval_apply.p_value?true:false);
   _ModifyScheme();
   maybe_update_preview();
}

void ctl_quote_all_values.on_change()
{
   read_combobox_with(quotestyle_map,ctl_quote_all_values,auto ivalue);
   enable := (_LanguageInheritsFrom('html',gLangId) && !ivalue);
   ctl_quote_wordval.p_enabled=enable;
   ctl_quote_numval.p_enabled=enable;
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_QUOTE_ALL_VALUES,ivalue);
   _ModifyScheme();
   maybe_update_preview();
}

// Returns the tagname that has the actual
// configuration for a given tag, taking care
// of indirection, or redirecting to the 
// default tag when the tagname is unknown.
static _str resolveTagname(_str tagname)
{
   if (tag_exists(gibeautifier,tagname)) {
      parent_tag:=get_tag_parent(gibeautifier,tagname);
      if (parent_tag!= NO_PARENT_TAG) {
         return parent_tag;
      } else {
         return tagname;
      }
   }
   return HF_DEFAULT_TAG_NAME;
}

void standard_preview(int form)
{     
   beautifier_schedule_deferred_update(-1, form);
   oldw := p_window_id;
   p_window_id = find_any_enclosing_form(form);
   ind := currentIndentString();

   examp := '';

   if (ctlsstab.p_ActiveTab == TAGSTAB) {
      tagname := get_tag_name();
      _str cfgtag=resolveTagname(tagname);


      typeless endtag= _beautifier_get_tag_property(gibeautifier,cfgtag,VSCFGP_BEAUTIFIER_END_TAG)!=0;
      lb_within:=get_tag_lb_within(gibeautifier,cfgtag);
      update_preview_text(tagname, endtag, has_nls_within(lb_within));

      //update_preview_text(tagname, (int)(tags:[cfgtag]:[VSCFGP_BEAUTIFIER_END_TAG_REQUIRED] != '0'), (int)(get_tag_standalone(gibeautifier,cfgtag) != '0'));
      examp = gTagPreview;
   } else {
      examp = "<"ptag("container")">\n"ind"<"ptag("item")" "pattrib("id")"=\"543A\"/>\n</"ptag("container")">";
   }

   _ctl_preview.delete_all();
   _ctl_preview.p_ShowSpecialChars = SHOWSPECIALCHARS_TABS;
   _ctl_preview._insert_text(examp);
   _ctl_preview.refresh();
}

static void maybe_update_preview()
{
   if (!gInitialized) {
      return;
   }

   if (_haveBeautifiers()) {
      gExample = 'default';
      if (ctlsstab.p_ActiveTab == INDENTTAB) {
         gExample = "tags";
      } else if (ctlsstab.p_ActiveTab == TAGSTAB) {
         gExample = "";
      } else if( ctlsstab.p_ActiveTab == COMMENTSTAB ) {
         gExample='comment';
      }

      beautifier_schedule_deferred_update(150, p_active_form, 'hformat_update_preview');
   } else {
      standard_preview(p_active_form);
   }
}
void ctlindent.on_change() 
{
   if (isinteger(ctlindent.p_text) && ctlindent.p_text>=0) {
      _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_SYNTAX_INDENT,ctlindent.p_text);
      _ModifyScheme();
      maybe_update_preview();
   }
}

void ctltabsize.on_change()
{
   if (isinteger(ctltabsize.p_text) && ctltabsize.p_text>=0) {
      _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_TAB_SIZE,ctltabsize.p_text);
      _ModifyScheme();
      maybe_update_preview();
   }
}

void ctlorig_tabsize.on_change() {
   if (isinteger( ctlorig_tabsize.p_text) &&  ctlorig_tabsize.p_text>=0) {
      _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_ORIGINAL_TAB_SIZE,ctlorig_tabsize.p_text);
      _ModifyScheme();
      maybe_update_preview();
   }
}

void ctlmax_line_length.on_change() {
   if (isinteger( ctlmax_line_length.p_text) &&  ctlmax_line_length.p_text>=0) {
      _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_MAX_LINE_LEN,ctlmax_line_length.p_text);
      _ModifyScheme();
      maybe_update_preview();
   }
}

void ctl_glob_att_style.on_change() {
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_TAG_ATTR_STYLE,get_attstyle(ctl_glob_att_style));
   _ModifyScheme();
   maybe_update_preview();
}

void ctlindent_with_tabs.lbutton_up()
{
   _beautifier_set_property(gibeautifier,VSCFGP_BEAUTIFIER_INDENT_WITH_TABS,p_value);
   _ModifyScheme();
   maybe_update_preview();
}

// Bring up correct preview for the tab we switched to.
void ctlsstab.on_change(int reason)
{
   if (reason == CHANGE_TABACTIVATED) {
      maybe_update_preview();
   }
}
static _str currentIndentString()
{
   int si;

   if (isinteger(ctlindent.p_text)) {
      si = (int)ctlindent.p_text;
   } else {
      si = 4;
   }

   _ctl_preview.p_tabs = normalize_tabs(ctltabsize.p_text);
   _ctl_preview.p_SyntaxIndent = si;

   if (ctlindent_with_tabs.p_value) {
      return(_ctl_preview.expand_tabs(substr('',1,si,\t),1,si,'S'));
   }
   return(substr('',1,si));
}

static _str applyCase(_str setting, _str val)
{
   if (setting == "Capitalize") {
      return(upcase(substr(val,1,1)):+lowcase(substr(val,2)));  /* Capitalize */
   } else if (setting == "Lower") {
      return lowcase(val);
   } else if (setting == "Upper") {
      return upcase(val);
   } else {
      return val;
   }
}

static _str ptag(_str tag)
{
   return applyCase(ctltagcase.p_cb_text_box.p_text, tag);
}

static _str pattrib(_str attrib)
{
   return applyCase(ctlattribcase.p_cb_text_box.p_text, attrib);
}
static int have_invalid_fields()
{
   msg := "";
   typeless indent_amount=ctlindent.p_text;
   if( !isinteger(indent_amount) || indent_amount<0 ) {
      msg="Invalid indent amount";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctlindent;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return(1);
   }
   typeless tabsize=ctltabsize.p_text;
   if( !isinteger(tabsize) || tabsize<0 ) {
      msg="Invalid tab size";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctltabsize;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return(1);
   }
   typeless orig_tabsize=ctlorig_tabsize.p_text;
   if( ctlorig_tabsize.p_visible && (!isinteger(orig_tabsize) || orig_tabsize<0) ) {
      msg="Invalid original tab size";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctlorig_tabsize;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return(1);
   }
   typeless indent_with_tabs= (ctlindent_with_tabs.p_value!=0);
   typeless max_line_length= (ctlmax_line_length.p_text);
   if( !isinteger(max_line_length) || max_line_length<0 ) {
      msg="Invalid maximum line length";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctlmax_line_length;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return(1);
   }
   return(0);
}

void hformat_update_preview(int form)
{
   beautifier_schedule_deferred_update(-1, form);

   oldw := p_window_id;
   p_window_id = form;

   _nocheck _control _ctl_preview;

   _ctl_preview.delete_all();
   if (gExample == '') {
      _ctl_preview._insert_text(gTagPreview);
   }

   if (_haveBeautifiers()) {
      //curp := LanguageSettings.getBeautifierProfileName(gLangId);
      //LanguageSettings.setBeautifierProfileName(gLangId, HFORMAT_PREVIEW_PROFILE);
      beautifier_update_preview(_ctl_preview, gExample, gLangId,gibeautifier);
      _ctl_preview.refresh('W');
      //LanguageSettings.setBeautifierProfileName(gLangId, curp);
   }

   p_window_id = oldw;
}

// This expects the current object to be a list box
defeventtab _html_beautify_add_tag_form;
void ctl_ok.on_create(int tlistctl)
{
   if( !_LanguageInheritsFrom('xml',gLangId) || !_mdi.p_child._isEditorCtl() ) {
      ctl_from_dtd.p_enabled=false;
   }
   ctl_single_tag.p_value=1;

   populate_parent_tag_combo(gibeautifier, _control ctl_copytag, NO_PARENT_TAG);
}

void ctl_ok.lbutton_up()
{
   if( ctl_single_tag.p_value ) {
      _param1=ctl_tag.p_text;
      _param2=ctl_copytag.p_cb_text_box.p_text;
   } else {
      // From the current file's DTD
      _param1='.DTD.';
   }

   p_active_form._delete_window(0);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

void ctl_from_dtd.lbutton_up()
{
   ctl_tag.p_enabled= (ctl_from_dtd.p_value==0);
}

void ctl_help.lbutton_up()
{
   _str msg="Single tag:\n":+
       "\tType in the name of the tag you want to add without <>. You\n":+
       "specify multiple tags by separating each tag by a space.";
   if( _LanguageInheritsFrom('xml',gLangId) ) {
      msg=msg:+
          "\n\n":+
          "Add DTD elements from current file:\n":+
          "\tIf the current file has a parsable DTD, then select this\n":+
          "\toption to add all elements from the DTD.";

   }
}

_str hformat_edit_profile(int preview_wid, _str langid, _str profile)
{
   preview_wid.gui_beautify(langid,profile);
   return profile;
}

static int proSettings:[] = {
   VSCFGP_BEAUTIFIER_INDENT_COMMENTS => 1,
   VSCFGP_BEAUTIFIER_INDENT_COL1_COMMENTS => 1, 
   VSCFGP_BEAUTIFIER_DEFAULT_EMBEDDED_LANG => 1, 
   VSCFGP_BEAUTIFIER_ML_CLOSING_BLOCK => 1, 
   VSCFGP_BEAUTIFIER_ML_CLOSING_TAG => 1,
   VSCFGP_BEAUTIFIER_MOD_TAG_INDENT => 1,
   VSCFGP_BEAUTIFIER_INDENT_CODE_FROM_TAG => 1,
   'eo_insert_endtag' => 1,
   'reference_count' => 1, 
   VSCFGP_BEAUTIFIER_QUOTE_ATTR_NUMBER_VALUE => 1,
   VSCFGP_BEAUTIFIER_QUOTE_ATTR_WORD_VALUE => 1
};


// Copy-and-paste inheritance from the normal form, so we could
// get rid of the "Comments and Languages" tabs from the tab control.
defeventtab _html_standard_format;

//
// Options dialog integration for standard edition.
static _str getFormLangId()
{
   return _GetDialogInfoHt('sflangID');
}

void _html_standard_format_init_for_options(_str langId)
{
   _SetDialogInfoHt('sflangID', langId);
   //htmScheme_t scms:[];
   
   // Re-arrange the form slightly for standard.
   ctlgo.p_visible = false;
   ctlcancel.p_visible = false;
   ctlhelp.p_visible = false;
   ctlreset.p_visible = false;
   ctlsave.p_visible = false;
   ctlselection_only.p_visible = false;
   label7.p_visible = false;ctlorig_tabsize.p_visible = false;
   ctllabel5.p_visible=false;ctl_glob_att_style.p_visible = false;

#if 0
   ctl_tag_linebreaks_frame.p_visible = false;
   ctlreformat_content.p_visible = false;
   ctlpreserve_body.p_visible = false;
   ctlpreserve_position.p_visible = false;
   ctl_allowed_child_frame.p_visible = false;
   ctllabel5.p_visible = false;
#endif
   ctllabel12.p_y=ctllabel2.p_y;ctl_lb_within.p_y=ctlnoflines_before.p_y;
   ctllabel2.p_visible=ctlnoflines_before.p_visible=false;
   ctllabel3.p_visible=ctlnoflines_after.p_visible=false;

#if 1
   ctlwordcase_apply.p_visible=ctlwordcase.p_visible = false;
   ctlhexcase_apply.p_visible=ctlhexcase.p_visible = false;
   ctl_quote_wordval_apply.p_visible=ctl_quote_wordval.p_visible = false;
   ctl_quote_numval_apply.p_visible=ctl_quote_numval.p_visible = false;
   ctllabel14.p_visible=ctl_quote_all_values.p_visible = false;
#endif

   _ctl_auto_validate.p_visible = _LanguageInheritsFrom('xml', langId);

   initDialog(langId, " ",'');

   // Move up the Auto Validate and Auto Symbol Translation controls.
   dy := ctlindenttags.p_height;
   tabbot := ctlsstab.p_y_extent;

   _ctl_symbol_trans_edit.p_x = ctltabsize.p_x;
   _ctl_symbol_trans_edit.p_y = tabbot - dy*3;

   _ctl_symbol_trans.p_x = label8.p_x;
   _ctl_symbol_trans.p_y = _ctl_symbol_trans_edit.p_y;

   _ctl_auto_validate.p_x = label8.p_x;
   _ctl_auto_validate.p_y = _ctl_symbol_trans.p_y - dy;

   gOriginalSchemeModified=false;
}

bool _html_standard_format_apply()
{
   if (have_invalid_fields()) {
      return false;
   }
   //htmScheme_t scms:[];
   langId := getFormLangId();

   hformatSaveScheme(gibeautifier,langId, BEAUTIFIER_DEFAULT_PROFILE);

   gOriginalSchemeModified = false;
   //_beautifier_profile_changed(gProfileName,langId);

   return true;
}

bool _html_standard_format_is_modified()
{
   lang := getFormLangId();
   modified:=false;
   isXml := _LanguageInheritsFrom('xml', lang);
   if (isXml) {
      if ((_ctl_auto_validate.p_value != 0)!=LanguageSettings.getAutoValidateOnOpen(lang)) {
         modified=true;
      }
   }
   
   if ((_ctl_symbol_trans.p_value != 0)!=LanguageSettings.getAutoSymbolTranslation(lang)) {
      modified=true;
   }

   return gOriginalSchemeModified || modified;
}

_str _html_standard_format_export_settings(_str &file, _str &args, _str langID)
{
   return _language_settings_standard_export_settings(file, args, langID);
}

_str _html_standard_format_import_settings(_str &file, _str &args, _str langID)
{
   return _language_settings_standard_import_settings(file, args, langID);
}

static void _oncreateIndentStandard()
{
   validateOnOpen := false;
   autoSymbolTranslation := false;
   
   // These are grouped with the formatting dialog for standard.
   isXml := _LanguageInheritsFrom('xml', gLangId);
   validateOnOpen = isXml && LanguageSettings.getAutoValidateOnOpen(gLangId, false);
   autoSymbolTranslation = LanguageSettings.getAutoSymbolTranslation(gLangId, true);

   if (_ctl_auto_validate.p_visible) {
      if (!_haveXMLValidation()) {
         _ctl_auto_validate.p_visible=false;
      }
      _ctl_auto_validate.p_value = (int)validateOnOpen;
   }
   _ctl_symbol_trans.p_value= (int)autoSymbolTranslation;
}

#if 0
void _ctl_standalone.lbutton_up()
{
   typeless tags:[];
   tagname := get_tag_name();

   if( tagname!="" ) {
      apply := null;
      if (_ctl_standalone.p_value) {
         apply=true;
         set_tag_lb_within(gibeautifier,tagname,_ctl_standalone.p_value);
      } else {
         set_tag_lb_within(gibeautifier,tagname,NEWLINES_DISABLED);
      }
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_ISMIN_BEFORE_START_TAG, 1);
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_ISMIN_AFTER_END_TAG, 1);

      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_BEFORE_START_TAG,_ctl_standalone.p_value,apply);
      _beautifier_set_tag_property(gibeautifier,tagname,VSCFGP_BEAUTIFIER_BL_AFTER_END_TAG,_ctl_standalone.p_value,apply);
   }
   _ModifyScheme();
   maybe_update_preview();
   return;
}
#endif
