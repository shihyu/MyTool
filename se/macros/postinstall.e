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
#include "toolbar.sh"
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
   name :=  root:+propertyName;
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
      rest := "";
      if( type != '' ) {
         parse toolsList with type ',' rest;
      } else {
         rest = toolsList;
      }
      _maybe_append(rest, ',');
      if( !pos(','value',',rest) ) {
         rest :+= value',';
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
   if (_isWindows()) {
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
      filename :=  'C:\.wind\'latestVersionKey'\userPrefs.registry';
      int temp_view_id, orig_view_id;
      status = _open_temp_view(filename,temp_view_id,orig_view_id);
      if( status != 0 ) {
         return;
      }
      _message_box("If you are currently running Tornado, please close it now so we can configure Tornado to use SlickEdit as the default editor","",MB_OK);
      root := "wrss.cmapps.look.LKEditor.";
      setTornadoConfigItem(root,'EditorName',strip(_dquote('S,'vsexe),'B','"'));
      setTornadoConfigItem(root,'EditorParameters','S,"$filename"');
      setTornadoConfigItem(root,'InternalEditor','B,false');
      prefix := "CustomTools.SlickEdit.";
      addto := "wrss.launcher.LKLauncher.PropertyNames";
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
   }
}

static void runAutoTag()
{
   _str rootDir = _getSlickEditInstallPath();
   macrosDir :=  rootDir"macros"FILESEP;

   //flush_keyboard();
   autotag();
// int status = shell("\""macrosDir'autotag'"\"");
// if( status != 0 && status != COMMAND_CANCELLED_RC ) {
//    //_message_box(nls("Failed to automatically create tag files."),"SlickEdit Installation");
// }
}

static void maybeShowQuickStart()
{
   cant_write_config_files := _default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   if ( _allow_quick_start_wizard && !cant_write_config_files) {
      quick_start();
   }
}

static void fixupHtmlSetup()
{
   // This should enable syntax indent for HTML if it is not already
   LanguageSettings.setIndentStyle('html', 2);
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
   def_show_bm_tags = false;
   // turn off show top of file line
   _default_option('T',0);
   // disable vsdelta backup history...remove +DD and replace -O with +O
   def_save_options = '+O -Z -ZR -E -S';
   def_maxbackup_ksize=0;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   // change the se icon used in lists
   _pic_lbvs=load_picture(-1,'_f_vs_plugin.svg');
   // disable change dir
   def_change_dir = 0;
   // disable change dir
   def_change_dir = 0;
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
   if (_isWindows()) {
      key := "SOFTWARE\\Freedom Scientific\\JAWS";
      jawsTargetDir := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, key, '', "Target");

      if( jawsTargetDir != "" ) {
         jawsOnOff := 0;
         msg := "Setting up SlickEdit for JAWS will improve screen reading and usability.\n\nDo you want to setup SlickEdit for use with JAWS?";
         int result = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
         if( result ==IDYES ) {
            _maybe_append_filesep(jawsTargetDir);
            jcf :=  jawsTargetDir:+"settings\\enu\\vs.jcf";
            if ( !file_exists(jcf) ) {
               int status = _ShellExecute(get_env("VSLICKBIN1"):+"jaws_setup.exe",null,"-q");
               if( status <= 32 ) {
                  // Error
                  msg = "Unable to save JAWS configuration file. Operating system reported status="status".";
                  _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
                  return;
               }
               jawsOnOff = 1;
            }
         }
         int status = _ConfigEnvVar("VSLICKJAWS",jawsOnOff);
         // Note: Do not bother showing them success message if they said "No"
         if( status == 0 && result == IDYES ) {
            msg = "JAWS setup successful. Please restart ":+_getProduct(false):+" to activate settings.";
            _message_box(msg,"",MB_OK|MB_ICONINFORMATION);
         }
      }
   }
}


static void setupPersonalAnnotations()
{
   _str personalSCA = _ConfigPath()'personal.sca';
   if (file_match('-P +HRS 'personalSCA, 1) == '') {
      copy_file(_getSysconfigMaybeFixPath("personal.sca"), personalSCA);
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
   binDir := editor_name('P');
   _str rootDir = _getSlickEditInstallPath();
   bitmapsDir :=  rootDir:+VSE_BITMAPS_DIR:+FILESEP;
   macrosDir :=  rootDir"macros"FILESEP;
   docsDir :=  rootDir"docs"FILESEP;

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
   binDir := editor_name('P');
   _str rootDir = _getSlickEditInstallPath();
   bitmapsDir :=  rootDir:+VSE_BITMAPS_DIR:+FILESEP;
   macrosDir :=  rootDir"macros"FILESEP;
   docsDir :=  rootDir"docs"FILESEP;

   //edit(_maybe_quote_filename(binDir"readme.txt"));
}

/**
 * Run post-install upgrade tasks.
 * <p>
 * An upgrade means that the major or minor version number increased. <br>
 * Example: 10.0 -> 11.0
 */
static void upgradeTasks()
{
   binDir := editor_name('P');
   _str rootDir = _getSlickEditInstallPath();
   bitmapsDir :=  rootDir:+VSE_BITMAPS_DIR:+FILESEP;
   macrosDir :=  rootDir"macros"FILESEP;
   docsDir :=  rootDir"docs"FILESEP;

   setupTornado3(binDir'vs.exe',bitmapsDir'vs.gif');

   fixupHtmlSetup();
   fixupBackgroundTaggingIdle();

   update_keys();

   // 12.17.08 - replace emulation prompt with quick start - sg
// setupEmulation();
   maybeShowQuickStart();

   if (isEclipsePlugin()) {
      setupEclipseDefaults();
   }
   if (def_keys=='vi-keys') {
      def_block_mode_fill_only_if_line_long_enough=true;
   }

   //edit(_maybe_quote_filename(vsroot"readme.txt"));

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
   if (_isUnix() && !_isMac()) {
      _X11CreateDesktopShortcut();
   }
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
   upgrade := cmajor>pmajor || (cmajor==pmajor && cminor>pminor);
   bool patch = !upgrade &&
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
