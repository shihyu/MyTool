////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49863 $
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
#import "coolfeatures.e"
#import "files.e"
#import "html.e"
#import "main.e"
#import "quickstart.e"
#import "recmacro.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "util.e"
#include "toolbar.sh"
#import "toolbar.e"
#require "sc/controls/customizations/MenuCustomizationHandler.e"
#require "sc/controls/customizations/ToolbarCustomizationHandler.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using namespace sc.controls.customizations;
using namespace se.lang.api.LanguageSettings;

/*
 * This is where post-installation tasks are defined.
 */

_str def_helpidx_filename;
_str def_apiidx_filename;

static void decomposeVersion(_str ver,
                             int& major, int& minor, int& rev, int& build)
{
   major=minor=rev=build=0;
   _str s_major, s_minor, s_rev, s_build;
   parse ver with s_major'.'s_minor'.'s_rev'.'s_build;
   if( isinteger(s_major) && (int)s_major>=0 ) {
      major=(int)s_major;
      if( isinteger(s_minor) && (int)s_minor>=0 ) {
         minor=(int)s_minor;
         if( isinteger(s_rev) && (int)s_rev>=0 ) {
            rev=(int)s_rev;
            if( isinteger(s_build) && (int)s_build>=0 ) {
               build=(int)s_build;
            }
         }
      }
   }
}

static void setTornadoConfigItem(_str root, _str propertyName, _str value, _str addto='', _str prefix='')
{
   if( addto != "" ) {
      //say(addto' ');
      //say('    'prefix:+propertyName);
      addToTornadoConfigItem(addto,prefix:+propertyName,'');
   }
   top();
   _str name = root:+propertyName;
   int status = search('^'_escape_re_chars(name'='),'@ri');
   if( status !=0 ) {
      bottom();
      insert_line(name'='value);
      return;
   }
   replace_line(name'='value);
}

static _str getTornadoConfigItem(_str name, _str value)
{
   top();
   //name = root:+propertyName;
   int status = search('^'_escape_re_chars(name'='),'@ri');
   if( status != 0 ) {
      return "";
   }
   get_line(auto line);
   parse line with '=' value;
   return value;
}

static void addToTornadoConfigItem(_str name, _str value, _str type)
{
   _str toolsList = getTornadoConfigItem(name,value);
   if( toolsList == "" ) {
      if( type != '' ) {
         toolsList = type','value',';
      } else {
         toolsList = value',';
      }
   } else {
      _str rest = "";
      if( type != '' ) {
         parse toolsList with type ',' rest;
      } else {
         rest = toolsList;
      }
      if( last_char(rest) != ',' ) {
         rest = rest:+',';
      }
      if( !pos(','value',',rest) ) {
         rest = rest:+value',';
      }
      if( type != '' ) {
         toolsList = type',':+rest;
      } else {
         toolsList = rest;
      }
   }
   if( type == '' ) {
      toolsList = substr(toolsList,1,length(toolsList)-1);
   }
   setTornadoConfigItem(name,'',toolsList);
}

static void setupTornado2(_str vsexe, _str vsgif)
{
}

static void setupTornado3(_str vsexe, _str vsgif)
{
#if __NT__
   _str latestVersionKey;
   int status = _ntRegFindLatestVersion(HKEY_LOCAL_MACHINE, "Software\\Wind River Systems", latestVersionKey);
   //status = 0;
   //lastestVersionKey = "Tornado 3.0";
   if( status != 0 ) {
      return;
   }
   _str major, minor;
   parse latestVersionKey with 'Tornado','i' major'.'minor;
   if( !isinteger(major) ) {
      // Messed up registry entry, so bail
      return;
   }
   if( (int)major <= 2 ) {
      setupTornado2(vsexe,vsgif);
      return;
   }
   latestVersionKey = stranslate(latestVersionKey,'',' ');
   _str filename = 'C:\.wind\'latestVersionKey'\userPrefs.registry';
   int temp_view_id, orig_view_id;
   status = _open_temp_view(filename,temp_view_id,orig_view_id);
   if( status != 0 ) {
      return;
   }
   _message_box("If you are currently running Tornado, please close it now so we can configure Tornado to use SlickEdit as the default editor","",MB_OK);
   _str root = "wrss.cmapps.look.LKEditor.";
   setTornadoConfigItem(root,'EditorName',strip(_dquote('S,'vsexe),'B','"'));
   setTornadoConfigItem(root,'EditorParameters','S,"$filename"');
   setTornadoConfigItem(root,'InternalEditor','B,false');
   _str prefix = 'CustomTools.SlickEdit.';
   _str addto = "wrss.launcher.LKLauncher.PropertyNames";
   root = "wrss.launcher.LKLauncher.CustomTools.SlickEdit.";
   setTornadoConfigItem(root,'arg','S,"$filename"',addto,prefix);
   setTornadoConfigItem(root,'close','B,false',addto,prefix);
   setTornadoConfigItem(root,'cmd',strip(_dquote('S,'vsexe),'B','"'),addto,prefix);
   setTornadoConfigItem(root,'dir','S,',addto,prefix);
   setTornadoConfigItem(root,'img',strip(_dquote('S,'vsgif),'B','"'),addto,prefix);
   setTornadoConfigItem(root,'menu','B,true',addto,prefix);
   setTornadoConfigItem(root,'output','B,false',addto,prefix);
   setTornadoConfigItem(root,'save','B,false',addto,prefix);
   setTornadoConfigItem(root,'title','S,SlickEdit',addto,prefix);
   setTornadoConfigItem(root,'toolbar','B,true',addto,prefix);
   //wrss.launcher.LKLauncher.CustomTools.toolsList=S,New_Tool,
   root = "wrss.launcher.LKLauncher.CustomTools.toolsList";
   addToTornadoConfigItem(root,"SlickEdit",'S');

   //wrss.launcher.LKLauncher.PropertyNames=
   addToTornadoConfigItem(addto,'CustomTools.toolsList','');

   //sort_buffer('i');
   _save_file();
   _delete_temp_view();
#endif
}

static void setupHelpIndex()
{
#if __NT__
   if( def_helpidx_filename == "" ) {
      def_helpidx_filename= _encode_vsenvvars(_ConfigPath():+"vslick.idx",true);
   }
   if( def_helpidx_filename == "" || !file_exists(_replace_envvars(def_helpidx_filename))) {
      def_helpidx_filename = "";
      _str list[];
      _str rootDir = get_env("VSROOT");
      list[0] = rootDir"vckwds.hlp";
      show("_help_build_index_form","",list,_ConfigPath():+"vslick.idx");
      _str rest;
      parse def_wh with . ';' rest;
      def_wh = "vslick.idx;"rest;
   }
#endif
}

static void runAutoTag()
{
   _str rootDir = get_env("VSROOT");
   _str macrosDir = rootDir"macros"FILESEP;

   //flush_keyboard();
   autotag();
// int status = shell("\""macrosDir'autotag'"\"");
// if( status != 0 && status != COMMAND_CANCELLED_RC ) {
//    //_message_box(nls("Failed to automatically create tag files."),"SlickEdit Installation");
// }
}

static void setupEmulation()
{
   // DJB 11-09-2007:  Do not prompt for emulation 
   // during upgrade or patch install
   // 
   if( !def_emulation_was_selected ) {
      show("-mdi -modal _emulation_form", true);
   }
}

static void maybeShowQuickStart()
{
   // add this so that quick start will not be shown to existing users
   if (!def_quick_start_was_shown && def_emulation_was_selected) def_quick_start_was_shown = true;

   if ( !def_quick_start_was_shown ) {
      quick_start();
      def_quick_start_was_shown = def_emulation_was_selected = true;
   }
}

static void fixupHtmlSetup()
{
   // This should enable syntax indent for HTML if it is not already
   _str info = name_info(find_index("def-language-html", MISC_TYPE));
   if( info != "" ) {
      _str text1, syntax_indt, rest;
      parse info with text1 'IN='syntax_indt',' +0 rest;
      if( syntax_indt != 2 ) {
         replace_def_data("def-language-html",text1:+'IN=2':+rest);
         _config_modify_flags(CFGMODIFY_DEFDATA);
      }
   }
}

static void fixupContextTaggingBindings()
{
   // We must have this for epsilon emulation.
   // Go ahead and do it for any configuration,
   // if several users complain, we can change this.
   int kt_index = find_index("default_keys",EVENTTAB_TYPE);
   set_eventtab_index(kt_index,event2index(name2event('A-.')),find_index('list_symbols',COMMAND_TYPE));
   set_eventtab_index(kt_index,event2index(name2event('A-,')),find_index('function_argument_help',COMMAND_TYPE));
}

static void fixupBackgroundTaggingIdle()
{
   // do not let background tagging kick in so quickly
   if( def_background_tagging_idle < 250 ) {
      def_background_tagging_idle = 250;
   }
}

/** 
 * This is used in order to set defaults that are different for
 * the plugin and the main editor.
 */
static void setupEclipseDefaults(){
   // turn off show pushed bookmarks, because this is the default behavior in eclipse
   def_show_bm_tags = 0;
   // turn off show top of file line
   _default_option('T',0);
   // disable vsdelta backup history...remove +DD and replace -O with +O
   def_save_options = '+O -Z -ZR -E -S';
   def_maxbackup='';
   _config_modify_flags(CFGMODIFY_DEFVAR);
   // change the se icon used in lists
   _pic_lbvs=load_picture(-1,'_lbvs_eclipse.ico');
   // disable change dir
   def_change_dir = 0;
   // disable change dir
   def_change_dir = 0;
}


static void fixupEclipseBindings()
{
   // Use this spot for setting Eclipse specific key bindings
   int index = find_index("default_keys",EVENTTAB_TYPE);
   set_eventtab_index(index,event2index(name2event('C-PGUP')),0);
   set_eventtab_index(index,event2index(name2event('C-PGDN')),0);
}

void fixupVimBindings()
{
   // Adding 12.0.2 Vim visual key bindings for users upgrading
   int vis_index = find_index("vi_visual_keys",EVENTTAB_TYPE);
   if (vis_index) {
      set_eventtab_index(vis_index,event2index(name2event('^')),find_index('vi_visual_begin_line',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('(')),find_index('vi_visual_prev_sentence',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event(')')),find_index('vi_visual_next_sentence',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('{')),find_index('vi_visual_prev_paragraph',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('}')),find_index('vi_visual_next_paragraph',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('[')),find_index('vi_open_bracket_cmd',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event(']')),find_index('vi_closed_bracket_cmd',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('%')),find_index('vi_find_matching_paren',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('<')),find_index('vi_visual_shift_left',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('>')),find_index('vi_visual_shift_right',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event(':')),find_index('vi_visual_ex_mode',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('*')),find_index('vi_quick_search',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('#')),find_index('vi_quick_reverse_search',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('=')),find_index('beautify_selection',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('b')),find_index('vi_visual_prev_word',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('B')),find_index('vi_visual_prev_word2',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('e')),find_index('vi_visual_end_word',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('E')),find_index('vi_visual_end_word2',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('g')),find_index('vi_maybe_text_motion',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('G')),find_index('vi_goto_line',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('i')),find_index('vi_visual_i_cmd',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('n')),find_index('ex_repeat_search',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('N')),find_index('ex_reverse_repeat_search',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('w')),find_index('vi_visual_next_word',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('W')),find_index('vi_visual_next_word2',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('HOME')),find_index('vi_visual_begin_line',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('C-R')),find_index('vi_visual_maybe_command',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('"')),find_index('vi_cb_name',COMMAND_TYPE));
      set_eventtab_index(vis_index,event2index(name2event('a')),find_index('vi_visual_a_cmd',COMMAND_TYPE));
   }

   // Adding 12.0.2 Vim command key bindings for users upgrading
   int com_index = find_index("vi_command_keys",EVENTTAB_TYPE);
   if (com_index) {
      set_eventtab_index(com_index,event2index(name2event('C-R')),find_index('redo',COMMAND_TYPE));
      set_eventtab_index(com_index,event2index(name2event('*')),find_index('vi_quick_search',COMMAND_TYPE));
      set_eventtab_index(com_index,event2index(name2event('#')),find_index('vi_quick_reverse_search',COMMAND_TYPE));
      set_eventtab_index(com_index,event2index(name2event('=')),find_index('vi_format',COMMAND_TYPE));
   }

   if (def_keys == 'vi-keys') {
      def_one_file='+w';
      _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
      _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_EVENLY);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

static void fixupUnixReSearch()
{
   // IF we have a 2.0 constant value for UNIXRE_SEARCH
   if( def_re_search == 0x80 ) {
      // Convert it to the new 3.0 value
      def_re_search = UNIXRE_SEARCH;
   }
}

static void migrateMenuAndToolbarCustomizations()
{
   MenuCustomizationHandler mch();
   mch.restoreChanges();

   ToolbarCustomizationHandler tch;
   tch.restoreChanges();
}

static void setupJaws()
{
#if __NT__
   _str key = "SOFTWARE\\Freedom Scientific\\JAWS";
   jawsTargetDir := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, key, '', "Target");

   if( jawsTargetDir != "" ) {
      int jawsOnOff = 0;
      _str msg = "Setting up SlickEdit for JAWS will improve screen reading and usability.\n\nDo you want to setup SlickEdit for use with JAWS?";
      int result = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
      if( result ==IDYES ) {
         _maybe_append_filesep(jawsTargetDir);
         _str jcf = jawsTargetDir:+"settings\\enu\\vs.jcf";
         if ( !file_exists(jcf) ) {
            int status = NTShellExecute("open",get_env("VSLICKBIN1"):+"jaws_setup.exe","-q","");
            if( status <= 32 ) {
               // Error
               msg = "Unable to save JAWS configuration file. Operating system reported status="status".";
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
               return;
            }
            jawsOnOff = 1;
         }
      }
      int status = _ini_config_value(_INI_FILE,"Environment","VSLICKJAWS",jawsOnOff);
      // Note: Do not bother showing them success message if they said "No"
      if( status == 0 && result == IDYES ) {
         msg = "JAWS setup successful. Please restart ":+_getProduct(false):+" to activate settings.";
         _message_box(msg,"",MB_OK|MB_ICONINFORMATION);
      }
   }
#endif
}


static void setupPersonalAnnotations()
{
   _str personalSCA = _ConfigPath()'personal.sca';
   if (file_match('-P +HRS 'personalSCA, 1) == '') {
      copy_file(get_env('VSROOT')'sysconfig'FILESEP'personal.sca', personalSCA);
   }
}

static void fixupJavaDefTagfiles()
{
   // setting it to '' will clear out the value
   LanguageSettings.setTagFileList('java', '');
}

/**
 * TBFLAG_DISMISS_LIKE_DIALOG was added in 13.0 in order to
 * dismiss a floating tool window as if it was a dialog. This 
 * flag takes the place of special .ESC() event handling. 
 */
static void fixupTBFlags13()
{
   _TOOLBAR* ptb;

   ptb = _tbFind("_tbfilelist_form");
   if( ptb && 0 == (ptb->tbflags & TBFLAG_DISMISS_LIKE_DIALOG) ) {
      ptb->tbflags |= TBFLAG_DISMISS_LIKE_DIALOG;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   ptb = _tbFind("_tbfind_form");
   if( ptb && 0 == (ptb->tbflags & TBFLAG_DISMISS_LIKE_DIALOG) ) {
      ptb->tbflags |= TBFLAG_DISMISS_LIKE_DIALOG;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   ptb = _tbFind("_tbfind_symbol_form");
   if( ptb && 0 == (ptb->tbflags & TBFLAG_DISMISS_LIKE_DIALOG) ) {
      ptb->tbflags |= TBFLAG_DISMISS_LIKE_DIALOG;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   ptb = _tbFind("_tbregex_form");
   if( ptb && 0 == (ptb->tbflags & TBFLAG_DISMISS_LIKE_DIALOG) ) {
      ptb->tbflags |= TBFLAG_DISMISS_LIKE_DIALOG;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   ptb = _tbFind("_tbclipboard_form");
   if( ptb && 0 == (ptb->tbflags & TBFLAG_DISMISS_LIKE_DIALOG) ) {
      ptb->tbflags |= TBFLAG_DISMISS_LIKE_DIALOG;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
}

/**
 * Run post-install pre tasks.
 * <p>
 * Pre tasks are run before all other tasks whenever any part of the
 * version changes.
 */
static void preTasks()
{
   _str binDir = editor_name('P');
   _str rootDir = get_env("VSROOT");
   _str bitmapsDir = rootDir"bitmaps"FILESEP;
   _str macrosDir = rootDir"macros"FILESEP;
   _str docsDir = rootDir"docs"FILESEP;

   setupPersonalAnnotations();
   fixupTBFlags13();

   // RGH - 5/15/2006
   // We show the readme in a modal html pane now, before the emulation, autotag, cool features, etc.
   _str serial=_getSerial();

   // 9:41:54 PM 12/28/2006 - DWH
   // Do not show the version dialog if this is a trial
   // 1.13.09 - version dialog is now shown as part of quick start - sg
// if ( !_trial()) {
//    vsversion('R', true);
// }
}

/**
 * Run post-install patch tasks.
 * <p>
 * A patch means that the revision number increased. <br>
 * Example: 10.0.1 -> 10.0.2
 */
static void patchTasks()
{
   _str binDir = editor_name('P');
   _str rootDir = get_env("VSROOT");
   _str bitmapsDir = rootDir"bitmaps"FILESEP;
   _str macrosDir = rootDir"macros"FILESEP;
   _str docsDir = rootDir"docs"FILESEP;

   //edit(maybe_quote_filename(binDir"readme.txt"));
}

/**
 * Run post-install upgrade tasks.
 * <p>
 * An upgrade means that the major or minor version number increased. <br>
 * Example: 10.0 -> 11.0
 */
static void upgradeTasks()
{
   _str binDir = editor_name('P');
   _str rootDir = get_env("VSROOT");
   _str bitmapsDir = rootDir"bitmaps"FILESEP;
   _str macrosDir = rootDir"macros"FILESEP;
   _str docsDir = rootDir"docs"FILESEP;

   setupTornado3(binDir'vs.exe',bitmapsDir'vs.gif');
   setupHelpIndex();

   fixupHtmlSetup();
   fixupContextTaggingBindings();
   fixupVimBindings();
   fixupUnixReSearch();
   fixupBackgroundTaggingIdle();

   // 12.17.08 - replace emulation prompt with quick start - sg
// setupEmulation();
   maybeShowQuickStart();

   if (isEclipsePlugin()) {
      fixupEclipseBindings();
      setupEclipseDefaults();
   }

   //edit(maybe_quote_filename(vsroot"readme.txt"));

   // We should not need to install the licesne file
   //if (!isEclipsePlugin() && !_trial() && _LicenseType()!=LICENSE_TYPE_BETA) {
   //   online_registration("-autorun");
   //}

   // 1.13.09 - this is now included in the quick-start - sg
// cool_features("startup");
}

/**
 * Run post-install post tasks.
 * <p>
 * Post tasks are run after all other tasks whenever any part of the
 * version changes.
 */
static void postTasks()
{
   fixupJavaDefTagfiles();

   // 1.13.09 - auto tag dialog is now part of quick start - sg
   // runAutoTag();
   if (!isEclipsePlugin()) {
      setupJaws();
   }

   // 3.3.09 - menu and toolbar customizations! - sg
   migrateMenuAndToolbarCustomizations();
#if __UNIX__ && !__MACOSX__
   _X11CreateDesktopShortcut();
#endif
}

// 1/24/2007 - rb
// Because _post_install_version is not saved in vusrdefs.e when the user's config
// is saved, ALL actions (pre, patch, upgrade, post) will get run each time the
// state file changes (regardless of version). It would be better to make the code
// in main.e smarter by only calling postinstall when the state file changes, and
// changing the name of the variable to def_post_install_version so it gets saved
// in vusrdefs.e (and setting CFGMODIFY_DEFVAR).
defmain()
{
   //say("postinstall can't be run yet");
   //return(0);
   preTasks();

   int cmajor, cminor, crev, cbuild;
   decomposeVersion(_version(),cmajor,cminor,crev,cbuild);
   int pmajor, pminor, prev, pbuild;
   decomposeVersion(_post_install_version,pmajor,pminor,prev,pbuild);
   boolean upgrade = cmajor>pmajor || (cmajor==pmajor && cminor>pminor);
   boolean patch = !upgrade &&
                   cmajor==pmajor && cminor==pminor &&
                   ( crev>prev || (crev==prev && cbuild>pbuild) );
   if( patch ) {
      patchTasks();
   } else if( upgrade ) {
      upgradeTasks();
   }

   if( upgrade || patch ) {
      postTasks();
   }
}
