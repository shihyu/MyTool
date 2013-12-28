////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50246 $
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
#include 'slick.sh'
#import "files.e"
#import "main.e"
#import "math.e"
#import "recmacro.e"
#import "slickc.e"
#import "stdprocs.e"
#import "se/color/ColorScheme.e"
#endregion

defmain()
{
  if ( arg(1)!='' ) {
    if ( upcase(strip(arg(1)))!='INSERT' ) {
      message(nls('Expecting INSERT option'));
      return(1);
    }
    message(nls('Inserting default definitions...'));
  } else {
    rc=edit('+b lconfig'_macro_ext);
    _str temp_name='';
    if ( rc ) {
     temp_name='lconfig'_macro_ext;
    } else {
     clear_message();
     temp_name='lconfig..';
    }
    typeless status=edit('+t 'maybe_quote_filename(temp_name));
    if ( status ) { return(status); }
    message(nls('building configuration file ...'));
  }
  insert_line('//MARKER.  Editor searches for this line!');
  insert_line('#pragma option(redeclvars,on)');
  insert_line("#include 'slick.sh'");
  insert_line("#include 'toolbar.sh'");
  insert_line("#include 'cvs.sh'");
  insert_line("#include 'git.sh'");
  insert_line("#include 'mercurial.sh'");
  insert_line("#include 'perforce.sh'");
  insert_line("#include 'subversion.sh'");
  insert_line("#include 'debug.sh'");
  insert_line("#import 'notifications.e'");
  insert_line("#import 'se/vc/VersionControlSettings.e'");
  insert_line("#import 'se/color/SymbolColorRuleBase.e'");
  insert_line("#import 'se/files/FileNameMapper.e'");
  insert_def_vars();
  insert_line('');
  insert_line('defmain()');
  insert_line('{');
  insert_line('  _config_modify_flags(CFGMODIFY_OPTION|CFGMODIFY_KEYS);');

  insert_defaults();
  // Is there a button bar?
  insert_def_data();
  /* insert_completion_info() */
  /* insert_line  '  p_count_cursor_motion='p_count_cursor_motion */
  insert_proc_call('_scroll_style',_scroll_style());
  insert_proc_call('_cursor_shape',_cursor_shape());
  insert_proc_call('_spill_file_path',_spill_file_path());
  insert_proc_call('_cache_size',_cache_size());
  insert_proc_call('get_event','D'get_event('D'));
  /* insert_proc_call('get_event','S'get_event('s')) */
  insert_proc_call('_grid_width',_grid_width());
  insert_proc_call('_grid_height',_grid_height());

  insert_proc_call2('_default_option','VSOPTION_FORCE_WRAP_LINE_LEN',_default_option(VSOPTION_FORCE_WRAP_LINE_LEN));
  insert_proc_call2('_default_option','VSOPTION_LINE_NUMBERS_LEN',_default_option(VSOPTION_LINE_NUMBERS_LEN));
  insert_proc_call2('_default_option','VSOPTION_LCREADWRITE',_default_option(VSOPTION_LCREADWRITE));
  insert_proc_call2('_default_option','VSOPTION_LCREADONLY',_default_option(VSOPTION_LCREADONLY));
  insert_proc_call('_LCUpdateOptions');

  insert_proc_call2('_default_option','VSOPTION_NEXTWINDOWSTYLE',_default_option(VSOPTION_NEXTWINDOWSTYLE));

  insert_proc_call2('_default_option','VSOPTION_IPVERSION_SUPPORTED',_default_option(VSOPTION_IPVERSION_SUPPORTED));
  insert_proc_call2('_default_option','VSOPTION_NO_BEEP',_default_option(VSOPTION_NO_BEEP));

  insert_proc_call2('_default_option','VSOPTION_NEW_WINDOW_WIDTH',_default_option(VSOPTION_NEW_WINDOW_WIDTH));
  insert_proc_call2('_default_option','VSOPTION_NEW_WINDOW_HEIGHT',_default_option(VSOPTION_NEW_WINDOW_HEIGHT));
  insert_proc_call2('_default_option','VSOPTION_PLACE_CARET_ON_FOCUS_CLICK',_default_option(VSOPTION_PLACE_CARET_ON_FOCUS_CLICK));
  insert_proc_call2('_default_option','VSOPTION_APPLICATION_CAPTION_FLAGS',_default_option(VSOPTION_APPLICATION_CAPTION_FLAGS));
  insert_proc_call2('_default_option','VSOPTION_MAC_ALT_KEY_BEHAVIOR',_default_option(VSOPTION_MAC_ALT_KEY_BEHAVIOR));
  insert_proc_call2('_default_option','VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS',_default_option(VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS));
  insert_proc_call2('_default_option','VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY',_default_option(VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY));
  insert_proc_call2('_default_option','VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE',_default_option(VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE));
  // Need to set the current clear_key_numlock_state to the initial state
  insert_proc_call2('_default_option','VSOPTION_CLEAR_KEY_NUMLOCK_STATE',_default_option(VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE));
  // Mac: Allow resizing from any edge or corner of editor control window frame
  insert_proc_call2('_default_option','VSOPTION_MAC_RESIZE_BORDERS',_default_option(VSOPTION_MAC_RESIZE_BORDERS));
  insert_proc_call2('_default_option','VSOPTION_CURSOR_BLINK_RATE',_default_option(VSOPTION_CURSOR_BLINK_RATE));
  insert_proc_call2('_default_option','VSOPTION_MDI_ALLOW_CORNER_TOOLBAR',_default_option(VSOPTION_MDI_ALLOW_CORNER_TOOLBAR));
  insert_proc_call2('_default_option','VSOPTION_MAC_HIGH_DPI_SUPPORT',_default_option(VSOPTION_MAC_HIGH_DPI_SUPPORT));
  insert_proc_call2('_default_option','VSOPTION_MAC_SHOW_FULL_MDI_CHILD_PATH',_default_option(VSOPTION_MAC_SHOW_FULL_MDI_CHILD_PATH));
  insert_proc_call2('_default_option','VSOPTION_TAB_TITLE',_default_option(VSOPTION_TAB_TITLE));
  insert_proc_call2('_default_option','VSOPTION_SPLIT_WINDOW',_default_option(VSOPTION_SPLIT_WINDOW));
  // v18 MDI rewrite: Want MAXIMIZE_FIRST_MDICHILD option off by default. Since we used old-style 'F' option before,
  // we simply made 'F' a noop and go forward using VSOPTION_MAXIMIZE_FIRST_MDICHILD constant.
  insert_proc_call2('_default_option', 'VSOPTION_AUTO_ZOOM_SETTING', _default_option(VSOPTION_AUTO_ZOOM_SETTING));
  insert_proc_call2('_default_option', 'VSOPTION_ZOOM_WHEN_ONE_WINDOW', _default_option(VSOPTION_ZOOM_WHEN_ONE_WINDOW));
  insert_proc_call2('_default_option', 'VSOPTION_TAB_MODIFIED_COLOR', _default_option(VSOPTION_TAB_MODIFIED_COLOR));

  insert_proc_call('_default_option','N',_default_option('N'));
  insert_proc_call('_default_option','D',_default_option('D'));
  insert_proc_call('_default_option','T',_default_option('T'));
  insert_proc_call('_default_option','H',_default_option('H'));
  insert_proc_call('_default_option','V',_default_option('V'));
  insert_proc_call('_default_option','S',_default_option('S'));
  insert_proc_call('_default_option','P',_default_option('P'));
  insert_proc_call('_default_option','A',_default_option('A'));
  insert_proc_call('_default_option','C',_default_option('C'));
  insert_proc_call2('_default_option','VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB',_default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB));
  insert_proc_call2('_default_option','VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8',_default_option(VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8));
  insert_proc_call('_default_option','O',_default_option('O'));
  insert_proc_call('_default_option','L',_default_option('L'));
  insert_proc_call('_default_option','R',_default_option('R'));
  insert_proc_call('_default_option','Y',_default_option('Y'));
  insert_proc_call('_default_option','U',_default_option('U'));

  insert_proc_call('_spell_option','M',_spell_option('M'));
  insert_proc_call('_spell_option','C',_spell_option('C'));
  insert_proc_call('_spell_option','1',_spell_option('1'));
  insert_proc_call('_spell_option','2',_spell_option('2'));
  insert_proc_call('_spell_option','R',_spell_option('R'));
  insert_proc_call('_spell_option','U',_spell_option('U'));

  insert_proc_call('_cua_textbox',def_cua_textbox);
  insert_font_field('CFG_CMDLINE',CFG_CMDLINE);
  insert_font_field('CFG_SBCS_DBCS_SOURCE_WINDOW',CFG_SBCS_DBCS_SOURCE_WINDOW);
  insert_font_field('CFG_HEX_SOURCE_WINDOW',CFG_HEX_SOURCE_WINDOW);
  insert_font_field('CFG_UNICODE_SOURCE_WINDOW',CFG_UNICODE_SOURCE_WINDOW);
  insert_font_field('CFG_MESSAGE',CFG_MESSAGE);
  insert_font_field('CFG_STATUS',CFG_STATUS);
  insert_font_field('CFG_MENU',CFG_MENU);
  insert_font_field('CFG_DIALOG',CFG_DIALOG);
  insert_font_field('CFG_MDICHILDICON',CFG_MDICHILDICON);
  insert_font_field('CFG_MDICHILDTITLE',CFG_MDICHILDTITLE);
  insert_font_field('CFG_FUNCTION_HELP',CFG_FUNCTION_HELP);
  insert_font_field('CFG_FUNCTION_HELP_FIXED',CFG_FUNCTION_HELP_FIXED);
  insert_font_field('CFG_FILE_MANAGER_WINDOW',CFG_FILE_MANAGER_WINDOW);
  insert_font_field('CFG_DIFF_EDITOR_WINDOW',CFG_DIFF_EDITOR_WINDOW);
  insert_font_field('CFG_MINIHTML_PROPORTIONAL',CFG_MINIHTML_PROPORTIONAL);
  insert_font_field('CFG_MINIHTML_FIXED',CFG_MINIHTML_FIXED);
  insert_font_field('CFG_DOCUMENT_TABS',CFG_DOCUMENT_TABS);

  insert_proc_call2('_default_option','VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS',_default_option(VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS));
  insert_proc_call2('_default_option','VSOPTION_NO_ANTIALIAS',_default_option(VSOPTION_NO_ANTIALIAS));

  /* insert_proc_call('get_event','A'get_event('A')) */
  insert_proc_call('_insert_state',_insert_state(),'d');

  // delegate to the color scheme class to generate color settings code
  se.color.ColorScheme scm;
  scm.loadCurrentColorScheme();
  scm.insertMacroCode(false);

  insert_proc_call('_update_sysmenu_bindings');
  insert_proc_call('menu_mdi_bind_all');
  insert_line('  rc=0;');
  insert_line('}');
  //insert_replace_def_data_proc();
  clear_message();
  if ( arg(1)=='' ) top();
  return(0);

}
static void insert_font_field(_str field_name,int field_number)
{
   fontValue := _default_font(field_number);
   if (field_number == CFG_DIALOG) {
      // this might be different if we have already changed 
      // the value but haven't restarted yet.
      fontValue = get_env('VSLICKDIALOGFONT');
   } 

   insert_line('  _default_font('field_name','_quote(fontValue)');');
}
static void insert_def_vars()
{
  int index=name_match('def-',1,VAR_TYPE);
  for (;;) {
     if ( ! index ) { break; }
     typeless v = _get_var(index);
     defvarType := v._typename();
     defvarType=stranslate(defvarType,'_','-');
     if ( defvarType==''   || defvarType=='null' ||
          defvarType=='[]' || defvarType==':[]' ) {
        defvarType='typeless';
     }
     if (v._varformat()==VF_OBJECT && v._fieldname(0)=='') {
        defvarType='typeless';
     }
     insert_line('  'defvarType' 'translate(name_name(index),'_','-')';');
     index=name_match('def-',0,VAR_TYPE);
  }
}
static void insert_defaults()
{
  insert_line('  typeless p1,p2,p3,p4;');
  int index=name_match('def-',1,VAR_TYPE);
  for (;;) {
     if ( ! index ) break;
     _insert_var_source(_get_var(index),translate(name_name(index),"_","-"),'  ',1);
     //insert_line "  "translate(name_name(index),"_","-")" = "_quote(_get_var(index))
     index=name_match('def-',0,VAR_TYPE);
  }
}
static void insert_def_data()
{
  int index=name_match('def-',1,MISC_TYPE);
  for (;;) {
     if ( ! index ) { break; }
#if 0
     if (pos(' 'name_name(index)' ',' def-language-cob def-language-ada def-language-prg def-language-mod def-language-for ')) {
        parse name_name(index) with 'def-language-'ext;
        insert_line('  check_and_load_support("'ext'",junk);');
     }
#endif
     insert_line('  replace_def_data("'name_name(index)'",'_quote(name_info(index))');');
     index=name_match('def-',0,MISC_TYPE);
  }

}
/*  May be future use of this routine.
defproc global insert_completion_info()
  index=name_match('',1,COMMAND_TYPE)
  loop
     if not index then leave endif
     if name_info(index)<>'' then
        insert_line '  replace_def_data("'name_name(index)'","'name_info(index)'")'
     endif
     index=name_match('',0,COMMAND_TYPE)
  endloop
*/

#if 0
static void insert_replace_def_data_proc()
{
    insert_line('');
    insert_line('static void replace_def_data(name,info)');
    insert_line('{');
    insert_line('   index=find_index(name,MISC_TYPE);');
    insert_line('   if (index) {');
    insert_line('      set_name_info(index,info);');
    insert_line('   } else {');
    insert_line('      insert_name(name,MISC_TYPE,info);');
    insert_line('   }');
    insert_line('}');

}
#endif

static void insert_proc_call(_str proc_name, ...)
{
   _str string="  "proc_name'(';
   int i;
   for (i=2; i<=arg() ; ++i) {
      if ( i:==2 ) {
         if (isinteger(arg(i))) {
            string=string:+arg(i);
         } else {
            string=string:+_quote(arg(i));
         }
      } else {
         _str new_string=string','_quote(arg(i));
         if ( length(new_string)>79 ) {
            insert_line(string',');
            string=substr('',1,length(proc_name)+1):+_quote(arg(i));
         } else {
            string=new_string;
         }
      }
   }
   insert_line(string');');
}
static void insert_proc_call2(_str proc_name, ...)
{
   _str string="  "proc_name'(';
   int i;
   for (i=2; i<=arg() ; ++i) {
      if ( i:==2 ) {
         string=string:+arg(i);
      } else {
         _str new_string=string','_quote(arg(i));
         if ( length(new_string)>79 ) {
            insert_line(string',');
            string=substr('',1,length(proc_name)+1):+_quote(arg(i));
         } else {
            string=new_string;
         }
      }
   }
   insert_line(string');');
}
