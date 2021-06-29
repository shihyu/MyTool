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
#include "slick.sh"
#include "xml.sh"
#include "scc.sh"
#import "context.e"
#import "fileman.e"
#import "files.e"
#import "guiopen.e"
#import "main.e"
#import "mprompt.e"
#import "project.e"
#import "projutil.e"
#import "saveload.e"
#import "sellist.e"
#import "seltree.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "taggui.e"
#import "tbview.e"
#import "toast.e"
#import "vc.e"
#import "window.e"
#require "se/datetime/DateTime.e"

using se.datetime.DateTime;

//////////////////////////////////////////////////////////////////////
// Begin Update Manager Hotfix loading code
//////////////////////////////////////////////////////////////////////

static const HOTFIX_HOTFIX_MANIFEST_XML= "hotfix.xml";

enum_flags HotfixInfoFlags {
   HIF_FILENAME,
   HIF_SERIES,
   HIF_REVISION,
   HIF_FIX_DATE,
   HIF_DESCRIPTION,
   HIF_FIXES,
   HIF_VERSIONS,
};

struct HotfixInfo {
   _str ZipFile;
   int ManifestHandle;
   bool Restart;
   _str Files[];
   _str SystemFiles[];
   _str LoadedRevision;
};

static _str hotfixGetZipFile(_str zipfile="")
{
   // already specified on command line?
   if (zipfile!="" && file_exists(zipfile)) {
      return zipfile;
   }

   // prompte user for zip file
   format_list := 'Zip Files(*.zip),All Files('ALLFILES_RE')';
   zipfile = _OpenDialog('-new -mdi -modal',
                         'Apply Hot Fix',
                         '',     // Initial wildcards
                         format_list,  // file types
                         OFN_FILEMUSTEXIST,
                         ".zip",  // Default extensions
                         '',      // Initial filename
                         '',      // Initial directory
                         'hotfixGetZipFile',      // Reserved
                         "Standard Open dialog box"
                         );
   zipfile=strip(zipfile,'B','"');

   return zipfile;
}

static int hotfixOpenManifest(_str zipfile)
{
   // put together path to manifest path
   manifest_path := zipfile;
   _maybe_append_filesep(manifest_path);
   manifest_path :+= HOTFIX_HOTFIX_MANIFEST_XML;

   // make sure the manifest exists
   if (!file_exists(manifest_path)) {
      return FILE_NOT_FOUND_RC;
   }

   // now open it as an xml config file
   status := 0;
   handle := _xmlcfg_open(manifest_path,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (status < 0) return status;
   return handle;
}

static _str hotfixGetVersion(int handle, _str *compatibleVersions=null)
{
   // find the hotfix element
   node := _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the compatible versions for this hot fix
   if (compatibleVersions != null) {
      *compatibleVersions = _xmlcfg_get_attribute(handle, node, "CompatibleVersions");
   }

   // look up the version attribute and compare to the editor version
   fix_version := _xmlcfg_get_attribute(handle, node, "Version");
   return fix_version;
}

static _str hotfixGetSeries(int handle)
{
   // find the hotfix element
   node := _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the version attribute and compare to the editor version
   series := _xmlcfg_get_attribute(handle, node, "Series");

   // if the series attribute is blank, then use the file name of the zip
   if (series == '') {
      file := _xmlcfg_get_filename(handle);
      // get the path only - we want the zip file, really
      file = _strip_filename(file, 'N');
      // remove the file separator
      file = substr(file, 1, length(file) - 1);
      // finally, remove the extension
      file = _strip_filename(file, 'E');
      // and get rid of the path
      series = _strip_filename(file, 'P');
   }

   return series;
}

static _str hotfixGetRevision(int handle)
{
   // find the hotfix element
   node := _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the version attribute and compare to the editor version
   rev := _xmlcfg_get_attribute(handle, node, "Revision", 1);
   return rev;
}

static _str hotfixGetRequirements(int handle, _str &requiredNames)
{
   // find the hotfix element
   node := _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the version attribute and compare to the editor version
   rev := _xmlcfg_get_attribute(handle, node, "Requires", "");
   requiredNames = _xmlcfg_get_attribute(handle, node, "RequiresDisplay", "");
   return rev;
}

static _str hotfixGetDate(int handle)
{
   // find the hotfix element
   node := _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the version attribute and compare to the editor version
   fixDate := _xmlcfg_get_attribute(handle, node, "Date");
   return fixDate;
}

static bool hotfixGetRestart(int &handle)
{
   // find the hotfix element
   node := _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      return false;
   }

   // look up the version attribute and compare to the editor version
   typeless doRestart = _xmlcfg_get_attribute(handle, node, "Restart", 0);
   return (doRestart != 0)? true:false;
}

static _str hotfixGetDescription(int handle)
{
   // find the description element
   node := _xmlcfg_find_simple(handle, "/HotFix/Description");
   if (node < 0) {
      return 0;
   }

   // the text is PCDATA
   description := "";
   text_node := _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_PCDATA);
   if (text_node > 0) {
      description = _xmlcfg_get_value(handle, text_node);
   }
   description = stranslate(description, " ", "[\t\n\r]",'r');

   // replace the hot fix revision number in description
   if (pos("&revision;", description)) {
      revNumber := hotfixGetRevision(handle);
      if (revNumber == '') revNumber=1;
      description=stranslate(description, revNumber, "&revision;");
   }
   // replace the hot fix version number in description
   if (pos("&version;", description)) {
      verNumber := hotfixGetVersion(handle);
      if (verNumber == '') verNumber="<unknown>";
      description=stranslate(description, verNumber, "&version;");
   }

   // that's all folks
   return description;
}

static _str hotfixGetFixDescriptions(int handle, bool &have_revs, _str loaded_rev="")
{
   // the text is PCDATA
   description := "";

   // now get the individual defect descriptions
   typeless defects[];
   status := _xmlcfg_find_simple_array(handle, "/HotFix/Defect", defects);
   if (defects._length() > 0) {

      // check if any defect IDs specify a cumulative revision #
      have_revs = false;
      current_rev := "";
      foreach (auto node in defects) {
         rev := _xmlcfg_get_attribute(handle, node, "Revision");
         if (rev != "") {
            if (current_rev == "") {
               current_rev = rev;
            } else if (current_rev != rev) {
               have_revs = true;
            }
         }
      }

      // for multiple hotfix revisions, we'll add the start <ul> later
      current_rev = "";
      if (!have_revs) {
         description :+= "<ul>";
      }

      // iterate through defects
      foreach (node in defects) {
         modules := _xmlcfg_get_attribute(handle, node, "Modules");
         ids     := _xmlcfg_get_attribute(handle, node, "Ids");
         rev     := _xmlcfg_get_attribute(handle, node, "Revision");

         // maybe we can use the hotfix revision as first rev
         if (have_revs && rev == "" && current_rev == "") {
            rev = hotfixGetRevision(handle);
         }

         // hark, is this a new cumulative revision forsooth?
         if (have_revs && rev != "" && rev != current_rev) {
            if (current_rev != "") {
               description :+= "</ul>";
            }
            description :+= "<p><b>Changes in Revision #":+rev;
            if (rev == loaded_rev) {
               description :+= " <font color=\"steelblue\">(currently loaded)</font>";
            }
            if (isnumber(loaded_rev) && isnumber(rev) && ((double)rev > (double)loaded_rev)) {
               description :+= " <font color=\"orange\"> (new)</font>";
            }
            description :+= "</b>";
            description :+= "<br>";
            description :+= "<ul>";
            current_rev = rev;
         }

         // highlight module names in green
         if (modules=='') modules="general fix";
         highlightColor := "green";
         description :+= "<li><font color=\"":+highlightColor:+"\">":+modules:+"</font> -- ";
         text_node := _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_PCDATA);
         if (text_node > 0) {
            defect_info := _xmlcfg_get_value(handle, text_node);
            description :+= stranslate(defect_info, " ", "[\t\n\r]",'r'); 
         }
         description :+= "</li>";
      }

      // close the last (set) of defects
      description :+= "</ul>";
   }

   // that's all folks
   return description;
}

static int hotfixGetFiles(int handle, 
                          _str (&files)[], 
                          _str (&system_files)[], 
                          _str (&readonly_files)[]=null,
                          _str (&absolute_files)[]=null,
                          bool &doRestart=false)
{
   // Find the Contents group
   node := _xmlcfg_find_simple(handle, "/HotFix/Contents");
   if (node < 0) {
      _message_box("Hot fix has no contents!");
      return STRING_NOT_FOUND_RC;
   }

   // files are relative to the installation or config directory
   config_dir := _ConfigPath();
   _maybe_append_filesep(config_dir);
   root_dir   := _getSlickEditInstallPath();
   _maybe_append_filesep(root_dir);
   macros_dir := root_dir :+ "macros" :+ FILESEP;
   win_dir    := root_dir :+ "win" :+ FILESEP;
   win64_dir  := root_dir :+ "win64" :+ FILESEP;
   sysconfig_dir := root_dir :+ "plugins" :+ FILESEP :+ "com_slickedit.base" :+ FILESEP "sysconfig" :+ FILESEP;
   base_plugins_dir := root_dir :+ "plugins" :+ FILESEP;
   _str ex_files[];

   // go through each tag under "Contents"
   status := 0;
   child  := _xmlcfg_get_first_child(handle, node);
   while (child >= 0) {

      dest := "";
      name := "";
      arch := "";
      item := _xmlcfg_get_name(handle, child);
      switch (item) {
      case "File":
         // check file architecture if it was specified
         arch=_xmlcfg_get_attribute(handle, child, "Arch");
         if (arch != null && arch != "" && machine():+machine_bits() != arch ) {
            status = VSUPDATE_INCORRECT_ARCHITECTURE_RC;
            break;
         }
         // file to be copied to installation directory
         name=_xmlcfg_get_attribute(handle, child, "Name");
         dest=_xmlcfg_get_attribute(handle, child, "Path");
         dest = stranslate(dest, FILESEP, FILESEP2);
         if (dest=="") dest=name;
         files :+= dest;
         system_files :+= dest;
         absolute_files :+= dest;
         if (!_FileIsWritable(root_dir:+dest)) {
            readonly_files :+= dest;
            status = ACCESS_DENIED_RC;
         }
         break;
      case "Config":   
         // file to be copied to configuration directory
         name=_xmlcfg_get_attribute(handle, child, "Name");
         dest=_xmlcfg_get_attribute(handle, child, "Path");
         dest = stranslate(dest, FILESEP, FILESEP2);
         if (dest=="") dest=name;
         files :+= dest;
         absolute_files :+= config_dir:+dest;
         if (file_exists(config_dir:+dest) && !_FileIsWritable(config_dir:+dest)) {
            status = ACCESS_DENIED_RC;
         }
         break;
      case "DLL":
         // Windows DLL to replace
         arch=_xmlcfg_get_attribute(handle, child, "Arch");
         if (arch == null || arch == "") {
            // no architecture, assume windows only
            if (machine()!='WINDOWS') {
               status = VSUPDATE_DLL_ONLY_FOR_WINDOWS_RC;
               break;
            }
         } else if ( machine():+machine_bits() != arch ) {
            status = VSUPDATE_INCORRECT_ARCHITECTURE_RC;
            break;
         }
         name=_xmlcfg_get_attribute(handle, child, "Name");
         files :+= "win" :+ FILESEP :+ name;
         system_files :+= win_dir :+ name;
         if (arch == 64 && file_exists(win64_dir)) {
            absolute_files :+= win64_dir :+ name;
         } else {
            absolute_files :+= win_dir :+ name;
         }
         // check listvtg.exe, because the actual DLL 
         // will be RO because it is in use
         if (!_FileIsWritable(win_dir:+"listvtg.exe")) {
            readonly_files :+= "win" :+ FILESEP :+ name;
            status = ACCESS_DENIED_RC;
         }
         doRestart=true;
         break;
      case "Module": 
         // Slick-C module to load (on a per-user basis)
         name=_xmlcfg_get_attribute(handle, child, "Name");
         name = stranslate(name, FILESEP, FILESEP2);
         files :+= "macros" :+ FILESEP :+ name;
         absolute_files :+= macros_dir :+ name;

         // make sure all the .ex files are up-to-date
         slickc_file := macros_dir :+ name;
         if (file_exists(slickc_file) && !pos(".zip":+FILESEP,slickc_file,1,'i') && _get_extension(name)=="e") {
            _make(_maybe_quote_filename(slickc_file));
         }

         // add the exfile to the list
         doLoad := _xmlcfg_get_attribute(handle, child, "Load", 1);
         doRun  := _xmlcfg_get_attribute(handle, child, "Run", 0);
         if ((doLoad || doRun) && get_extension(name)=="e" && file_exists(slickc_file:+"x")) {
            ex_files :+= macros_dir :+ name :+ "x";
         }
         break;
      case "ZipFile": 
         // Nested hotfix to apply
         name=_xmlcfg_get_attribute(handle, child, "Name");
         files :+= "hotfixes" :+ FILESEP :+ name;
         absolute_files :+= config_dir:+"hotfixes":+FILESEP:+dest;
         break;
      case "Sysconfig": 
         // system config file to be copied to the hotfixes dir
         name=_xmlcfg_get_attribute(handle, child, "Name");
         name = stranslate(name, FILESEP, FILESEP2);
         files :+= "sysconfig" :+ FILESEP :+ name;
         absolute_files :+= sysconfig_dir:+name;
         doRestart=true;
         break;
      case "Plugin":
         name=_xmlcfg_get_attribute(handle, child, "Name");
         name = stranslate(name, FILESEP, FILESEP2);
         files :+= "plugins" :+ FILESEP :+ name;
         if (_get_extension(name) != "zip" || file_exists(base_plugins_dir:+name)) {
            absolute_files :+= base_plugins_dir:+name;
         } else {
            absolute_files :+= base_plugins_dir:+substr(name,1,length(name)-4);
         }
         doRestart=true;
         break;
      case "Statefile":
         name=_xmlcfg_get_attribute(handle, child, "Name");
         name = stranslate(name, FILESEP, FILESEP2);
         files :+= name;
         absolute_files :+= root_dir:+name;
         doRestart=true;
         break;
      }

      // next please
      child = _xmlcfg_get_next_sibling(handle, child);
   }

  // append ex files to the absolute files list
  foreach (auto ex in ex_files) {
     absolute_files :+= ex;
  }

   // that's all folks
   return status;
}

static int hotfixCheckVersion(_str fix_version, _str compatibleVersions, bool quiet=false)
{
   // look up the version attribute and compare to the editor version
   editor_version := _version();

   // no version specified, or matches editor version
   if (fix_version == "" || fix_version == editor_version) {
      return 0;
   }
   // match any version
   if (compatibleVersions == "all") {
      return 0;
   }
   // editor version is one of the specific compatible versions
   // try this for specific editor version, and substrings up to the major version
   orig_editor_version := editor_version;
   while (editor_version != "") {
      if (pos(' 'editor_version' ', ' 'compatibleVersions' ')) {
         return 0;
      }
      // try trimming off the last digit of the version
      last_dot := lastpos('.', editor_version);
      if (last_dot <= 0) break;
      editor_version = substr(editor_version, 1, last_dot - 1);
   }

   // the version does not match
   if (!quiet) {
      _message_box("Invalid hot fix version:\n------------------\nThe selected hot fix is for SlickEdit "fix_version".\nYou are currently running "orig_editor_version".");
   }
   return COMMAND_CANCELLED_RC;
}

static int hotfixCheckRequirements(_str fix_requires, _str requires_display_names, _str (&fix_list)[] = null, bool quiet = false)
{
   // get the list of installed fixes
   status := hotfixFindAll("", fix_list, HIF_SERIES | HIF_REVISION, true);
   
   _str requiredArray[];
   _str requiredNamesArray[];
   split(fix_requires, ' ', requiredArray);
   split(requires_display_names, ',', requiredNamesArray);
   
   // make sure that each required hot fix is loaded
   not_found_list := "";
   for (i := 0; i < requiredArray._length(); i++) {
      fix_series := requiredArray[i];
      parse fix_series with fix_series "(" auto fix_rev ")";
      // remove a ".zip" if there is one
      if (pos(".zip", fix_series) == (length(fix_series) - 4)) {
         fix_series = substr(fix_series, 1, length(fix_series) - 4);
      }
      found_it := false;
      your_rev := "";
      // iterate through the list of loaded fixes
      foreach (auto fix in fix_list) {
         // parse out the loaded fix path and revision number loaded
         parse fix with fix "\t" auto rev;
         // check the filename against the required name
         if (_file_eq(_strip_filename(fix, 'P'), fix_series)) {
            found_it = true;
            // also check the revision number
            if (fix_rev != '' && fix_rev > rev) {
               your_rev = ".  You have Revision "rev".";
               found_it = false;
            }
            break;
         }
      }
      // did not find this requirement, so append it to the list
      if (!found_it) {
         fix_name := fix_series;
         if (requiredNamesArray[i] != null && requiredNamesArray[i] != '') {
            fix_name = requiredNamesArray[i];
         }
         not_found_list :+= "\t"fix_name;
         if (fix_rev != "") {
            not_found_list :+= " (Revision "fix_rev:+your_rev")";
         }
         not_found_list :+= "\n";
      }
   }

   // if there was a fix that did not get loaded
   if (not_found_list != "") {
      if (!quiet) _message_box("You are required to load the following fixes before loading this hot fix:\n\n":+not_found_list"\nInstallation cancelled.");
      return COMMAND_CANCELLED_RC;
   }

   // success
   return 0;
}



static int hotfixCheckDescription(HotfixInfo &info, int reason) 
{
   HotfixInfo list[];
   list[0] = info;
   status := show('-new -modal -xy -wh _hotfix_autofind_prompt_form', list, reason);
   return status;
}

static _str hotfixGetDisplayMsg(HotfixInfo &info, _str description, _str fixes, bool have_revs, int reason) 
{
   // create an HTML bullet list of files
   file_list := "<ul>";
   for (i:=0; i<info.Files._length(); ++i) {
      file_list :+= "<li>":+info.Files[i];
   }
   file_list :+= "</ul>";

   // prepend warning if this fix modifies system files
   systemFilesWarning := "";
   if (info.SystemFiles._length() > 0) {

      // create an HTML bullet list of system files
      system_list := "<ul>";
      for (i=0; i<info.SystemFiles._length(); ++i) {
         system_list :+= "<li>":+info.SystemFiles[i];
      }
      system_list :+= "</ul>";

      // put together the larg warning in HTML
      systemFilesWarning = "<b>WARNING</b>:<br> " :+
                           "This hot fix modifies files under your SlickEdit installation directory. ":+
                           "You must have write access to these files for the fix to install successfully. ";
      systemFilesWarning :+= system_list;

      // add warning about multi-user installations
      if( _getSerial()!="" && !_trial() && _FlexlmNofusers()>1 ) {
         systemFilesWarning :+= "<p><b>WE DO NOT RECOMMEND APPLYING THIS FIX FOR A MULTI-USER INSTALLATION.</b>";
      }
   }

   // add message about restart being required
   restartWarning := '';
   if (info.Restart) {
      highlightColor := "darkviolet";
      if (strieq(_GetAppThemeForOS(),'Dark')) {
         highlightColor = "violet";
      }
      restartWarning = "<p><b><font color=\"":+highlightColor:+\"">This hot fix will require you to close and restart SlickEdit.</font></b>";
   }

   // add list of fixes if there were any
   if (fixes != '' && !have_revs) {
      fixes = "<p><b><u>Fixes:</u></b><br>" :+ fixes;
   }

   filename := _strip_filename(info.ZipFile, 'P');

   msg := '';
   if (reason == HPFP_AUTO_PROMPT) {
      msg = '<p>Your system administrator has installed a new update that needs to be applied.<br><br>';
   }

   // put together HTML message
   msg :+= "<p><b><u>Name:</u></b> " :+ filename :+
         "<br>" :+
         "<p><b><u>Description:</u></b><br>" :+
         description :+ fixes :+ 
         systemFilesWarning :+
         "<p><b><u>Inventory:</u></b><br>" :+
         "This fix includes the following files:" :+
         file_list :+ 
         restartWarning;

   //if (reason == HPFP_MANUAL_PROMPT) {
   //   msg :+= "<p><b>Continue and apply fix?</b>";
   //}

   return msg;                             
}

_str hotfixGetHotfixesDirectory()
{
   return _ConfigPath() :+ "hotfixes" :+ FILESEP;
}

static void find_latest_hotfix_revision(_str &latest_revision) {
   _str path=hotfixGetHotfixesDirectory();
   latest_revision='';
   strappend(path,'hotfix_*_*_cumulative.zip');
   path=_maybe_quote_filename(path);
   filename := file_match('-d 'path,1);
   while (filename!='') {
      i:=pos('hotfix_[a-z]#{#0[0-9]#}_{#1[0-9]#}_cumulative.zip',filename,1,'r');
      if (i>0) {
         revision:=substr(filename,pos('S1'),pos('1'));
         if (revision>latest_revision) {
            latest_revision=revision;
         }
      }
      filename=file_match('-d 'path,0);
   }
}
static int hotfixCheckIfApplied(_str zipfile, bool quiet)
{
   // get path to hotfixes under config directory
   path := hotfixGetHotfixesDirectory();

   // check if this fix has already been applied
   name := _strip_filename(zipfile, 'p');
   path :+= FILESEP :+ name;
   latest_revision := "";
   find_latest_hotfix_revision(latest_revision);
   // get revision of new zipfile
   revision1 := "";
   handle := hotfixOpenManifest(zipfile);
   if (handle >= 0) {
      revision1 = hotfixGetRevision(handle);
      _xmlcfg_close(handle);
      _ZipClose(zipfile);
   }
   if (latest_revision!="") {
      if (revision1!="") {
         // if not a newer version, warn them
         if (revision1 < latest_revision) {
            if (quiet) return IDNO;
            status:=_message_box("A newer hot fix has already been applied.  Continue anyway?", "SlickEdit", MB_YESNO|MB_ICONQUESTION);
            if (status != IDYES) {
               return COMMAND_CANCELLED_RC;
            }
         } else {
            // if not a newer version, warn them
            if (revision1 <= latest_revision) {
               if (quiet) return IDNO;
               status := _message_box("Hotfix \"" :+ name :+ "\" has already been applied.  Continue anyway?", "SlickEdit", MB_YESNO|MB_ICONQUESTION);
               if (status != IDYES) {
                  return COMMAND_CANCELLED_RC;
               }
            }
         }
      }
   } else if (file_exists(path)) {
      // get revision of saved zipfile
      revision2 := "";
      handle = hotfixOpenManifest(path);
      if (handle >= 0) {
         revision2 = hotfixGetRevision(handle);
         _xmlcfg_close(handle);
         _ZipClose(path);
      }

      // if not a newer version, warn them
      if (revision1 <= revision2) {
         if (quiet) return IDNO;
         status := _message_box("Hotfix \"" :+ name :+ "\" has already been applied.  Continue anyway?", "SlickEdit", MB_YESNO|MB_ICONQUESTION);
         if (status != IDYES) {
            return COMMAND_CANCELLED_RC;
         }
      }
   }

   // that's all
   return 0;
}

void hotfixDoRestart()
{
   save_config(0);
   safe_exit();
}

static void hotfixCheckRestart(bool doRestart)
{
   if (doRestart) {
      status := _message_box("This fix requires you to close and restart SlickEdit.  Close SlickEdit now?", "SlickEdit", MB_YESNO|MB_ICONQUESTION);
      if (status == IDYES) {
         _post_call(hotfixDoRestart);
      }
   }
}

static int hotfixCopyFile(_str zipfile, _str name, _str dest, _str backupExt="", bool doBackup=true, bool makeDestDir=false)
{
   // we may need to create the destination directory if it does not already exist
   if (makeDestDir) {
      destDir := _strip_filename(dest,'N');
      if (!isdirectory(destDir)) {
         mkdir(destDir);
      }
   }

   // make sure the dest file doesn't already exist
   line := "";
   status := 0;
   if (file_exists(dest)) {
      if (backupExt=="") {
         backupExt = stranslate(_version(), '_', ' ');
      }
      if (doBackup && !file_exists(dest'.'backupExt)) {
         line = "Making backup copy: " :+ dest'.'backupExt;
         hotfixLogAction(line);
         status = _file_move(dest'.'backupExt, dest);
         if (status < 0) {
            line = "*** Could not rename file: " :+ dest :+ " -- " :+ get_message(status);
            hotfixLogAction(line);
         }
      } else {
         status = delete_file(dest);
         if (status < 0) {
            line = "*** Could not delete file: " :+ dest :+ " -- " :+ get_message(status);
            hotfixLogAction(line);
         }
      }
   }

   // copy the new file in
   src := zipfile :+ FILESEP :+ name;
   status = copy_file(src, dest);
   if (status < 0) {
      line = "*** Could not copy to file: " :+ dest :+ " -- " :+ get_message(status);
      hotfixLogAction(line);
   }

   if (_isUnix()) {
      // check that we have access to the new file
      temp_wid := orig_wid := 0;
      status = _open_temp_view(dest, temp_wid, orig_wid);
      if (status < 0) {
         _chmod("u+rw,g+rw,o+r " _maybe_quote_filename(dest));
      } else {
         _delete_temp_view(temp_wid);
         activate_window(orig_wid);
      }
   }

   // that's all folks
   return status;
}

static int hotfixRestoreBackup(_str dest, _str backupExt="", bool failIfNoBackup=true)
{
   if (backupExt=="") {
      backupExt = stranslate(_version(), '_', ' ');
   }

   line := "";
   status := 0;
   backupFile := dest"."backupExt;
   backupExists := file_exists(backupFile);
   if (backupExists || !failIfNoBackup) {
      if (file_exists(dest)) {
         status = delete_file(dest);
         if (status < 0) {
            line = "*** Could not delete file: " :+ dest :+ " -- " :+ get_message(status);
            hotfixLogAction(line);
         }
      }
      if (backupExists) {
         status = _file_move(dest, backupFile);
         if (status < 0) {
            line = "*** Could not restore file: " :+ dest :+ " -- " :+ get_message(status);
            hotfixLogAction(line);
         }
      } else {
         line = "*** No backup file, did not restore file: " :+ dest;
         hotfixLogAction(line);
      }
   } else {
      line = "*** Backup file missing, could not restore file: " :+ dest;
      hotfixLogAction(line);
   }

   return status;
}

static int hotfixApplyFile(int handle, int node, _str zipfile, bool doRestore, _str (&filesToDelete)[], bool quiet)
{
   // check the architecture of the DLL
   arch := _xmlcfg_get_attribute(handle, node, "Arch");
   if (arch != null && arch != "" && machine():+machine_bits() != arch) {
      return VSUPDATE_INCORRECT_ARCHITECTURE_RC;
   }

   // get the name and destination path
   name := _xmlcfg_get_attribute(handle, node, "Name");
   dest := _xmlcfg_get_attribute(handle, node, "Path");
   dest = stranslate(dest, FILESEP, FILESEP2);
   if (dest=="") dest=name;

   // files go to installation directory
   root_dir := _getSlickEditInstallPath();
   _maybe_append_filesep(root_dir);
   dest = root_dir :+ dest;

   // tell them about it and copy the file
   if (doRestore) {
      line := "Restoring file: " :+ dest;
      hotfixLogAction(line);
      status := hotfixRestoreBackup(dest);
      if (status) {
         return status;
      }
   } else {
      line := "Replacing file: " :+ dest;
      hotfixLogAction(line);
      status := hotfixCopyFile(zipfile,name,dest,makeDestDir:true);
      if (status) {
         return status;
      }
   }

   // that's all folks
   return 0;
}
static int hotfixApplyConfig(int handle, int node, _str zipfile, bool doRestore, _str (&filesToDelete)[], bool quiet)
{
   // get the name and destination path
   name := _xmlcfg_get_attribute(handle, node, "Name");
   dest := _xmlcfg_get_attribute(handle, node, "Path");
   dest = stranslate(dest, FILESEP, FILESEP2);
   if (dest=="") dest=name;

   // files go to installation directory
   config_dir := _ConfigPath();
   dest = config_dir :+ dest;

   // tell them about it and copy the file
   if (doRestore) {
      line := "Restoring file: " :+ dest;
      hotfixLogAction(line);
      status := hotfixRestoreBackup(dest);
      if (status) {
         return status;
      }

   } else {
      line := "Replacing file: " :+ dest;
      hotfixLogAction(line);
      status := hotfixCopyFile(zipfile,name,dest,makeDestDir:true);
      if (status) {
         return status;
      }
   }

   // that's all folks
   return 0;
}

static int hotfixApplySysconfig(int handle, int node, _str zipfile, bool doRestore, _str (&filesToDelete)[], bool quiet)
{
   // get the source path
   name := _xmlcfg_get_attribute(handle, node, "Name");
   dest := _xmlcfg_get_attribute(handle, node, "Path");

   // just get the file name here
   name = _strip_filename(name, 'P');

   // files go to the hotfix directory
   if (dest == null || dest == "") dest = name;
   dest = hotfixGetHotfixesDirectory() :+ dest;

   // tell them about it and copy the file
   if (doRestore) {
      line := "Restoring file: " :+ dest;
      hotfixLogAction(line);
      status := hotfixRestoreBackup(dest, '', false);
      if (status) {
         return status;
      }
   } else {
      line := "Replacing file: " :+ dest;
      hotfixLogAction(line);
      status := hotfixCopyFile(zipfile, name, dest, makeDestDir:true);
      if (status) {
         return status;
      }
   }

   // that's all folks
   return 0;
}

static _str getPluginVersionedName(_str installDir, _str name, _str revisionNumber)
{
   verName := name;

   // does this plugin already have a version?
   if (!pos('.ver.', name)) {
      // no, so add one
      justName := _strip_filename(name, 'P');
      if (_get_extension(name) == "zip") {
         justName = _strip_filename(name, 'E');
         verName = justName :+ '.ver.' :+ _version() :+ '.' :+ revisionNumber :+ ".zip";
      } else {
         verName = justName :+ '.ver.' :+ _version() :+ '.' :+ revisionNumber;
      }
   }

   return verName;
}

static int hotfixApplyPlugin(int handle, int node, _str zipfile, bool doRestore, _str (&filesToDelete)[], bool quiet)
{
   // get the name
   name := _xmlcfg_get_attribute(handle, node, "Name");
   revisionNumber := hotfixGetRevision(handle);
   if (revisionNumber == "") revisionNumber=1;

   // files go to the local plugins directory
   dest := _ConfigPath() :+ "plugins" :+ FILESEP :+ _strip_filename(name,'N');
   line := "";
   status := 0;

   // tell them about it and copy the file
   if (doRestore) {
      line = "Removing plugin: " :+ name;
      hotfixLogAction(line);

      dest :+= getPluginVersionedName(dest, name, revisionNumber);
      filesToDelete :+= dest;

   } else {

      // make plugins directory if it doesn't exist already
      if (!isdirectory(dest)) {
         status = make_path(dest);
         if (status) {
            _message_box("Could not make directory: " :+ dest);
            return status;
         }
      }

      // maybe generate a versioned name
      dest :+= getPluginVersionedName(dest, name, revisionNumber);

      line = "Installing plugin: "dest;
      hotfixLogAction(line);
      name = _strip_filename(name, 'P');
      status = hotfixCopyFile(zipfile, name, dest, "bak", false);
      if (status) {
         return status;
      }
   }

   return 0;
}

static int hotfixApplyStatefile(int handle, int node, _str zipfile, bool doRestore, _str (&filesToDelete)[], bool quiet)
{
   // get the name
   name := _xmlcfg_get_attribute(handle, node, "Name");
   if (name == "") name = STATE_FILENAME;
   destName := hotfixGetVersionedName(handle, name);

   // files go to the local plugins directory
   config_dir := _ConfigPath();
   _maybe_append_filesep(config_dir);
   dest := config_dir :+ destName;
   line := "";
   status := 0;

   // tell them about it and copy the file
   if (doRestore) {
      line = "Removing Slick-C state file: " :+ destName;
      hotfixLogAction(line);
      filesToDelete :+= dest;
      
   } else {
      line = "Installing Slick-C state file: " :+ destName;
      hotfixLogAction(line);
      status = hotfixCopyFile(zipfile, name, dest, "bak", false);
      if (status) {
         return status;
      }
   }

   return 0;
}

static _str hotfixGetVersionedName(int handle, _str name)
{
   version  := hotfixGetVersion(handle);
   revision := hotfixGetRevision(handle);
   destExt  := _get_extension(name, true);
   destName := _strip_filename(name, 'E');
   destName :+= ".ver";
   if (version  != "") destName :+= "." version;
   if (revision != "") destName :+= "." revision;
   destName :+= destExt;
   return destName;
}

static _str hotfixGetModuleRevision(_str path)
{
   // open the source file in a temp view
   revision := "";
   temp_wid := orig_wid := 0;
   status := _open_temp_view(path, temp_wid, orig_wid);
   if (status) {
      return status;
   }
   // look for the revision header
   top();
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   status = search("$Revision:",'@eh');
   restore_search(s1,s2,s3,s4,s5);
   if (!status && p_line < 4) {
      get_line(auto line);
      parse line with "$Revision:" revision;
      revision = strip(revision,'T','$');
      revision = strip(revision);
   }
   // finished, clean up
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);
   return revision;
}
static int hotfixGetFileSize(_str path)
{
   // open the file in a temp view
   temp_wid := orig_wid := 0;
   status := _open_temp_view(path, temp_wid, orig_wid);
   if (status) {
      return status;
   }

   // go to the bottom of the file and check offset
   bottom();_end_line();
   size := (int)_QROffset();
   
   // finished, clean up
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);
   return size;
}
static bool hotfixCheckForDefmain(_str path)
{
   // the defmain check does not apply to main.e
   if (_strip_filename(path, "P") == "main.e") {
      return false;
   }

   // open the source file in a temp view
   revision := "";
   temp_wid := orig_wid := 0;
   status := _open_temp_view(path, temp_wid, orig_wid, '+d');
   if (status) {
      return false;
   }

   // look for the defmain function
   _SetEditorLanguage('e');
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_push_context();
   _UpdateContext(true);
   hasDefmain := (tag_find_context_iterator("defmain",true,true) > 0);

   // finished, clean up
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);
   return hasDefmain;
}
static int hotfixCompareRevisions(_str rev1, _str rev2)
{
   typeless part1 = "";
   typeless part2 = "";
   while (rev1 != "" && rev2 != "") {
      parse rev1 with part1 "." rev1;
      parse rev2 with part2 "." rev2;
      if (part1 != part2) {
         return ((int)part1 < (int)part2)? -1:1;
      }
   }
   if (rev2 != "") {
      return -1;
   }
   if (rev1 != "") {
      return 1;
   }
   return 0;
}

/**
 * Compiles (if necessary) and loads the Slick-C&reg; <i>module_name</i> given.
 *  
 * @param module     Slick-C&reg; module to build and load 
 * @param doLoad     (default true) load module into interpreter?
 *  
 * @return Returns 0 if successful.
 */
static int hotfixMakeNload(_str module, bool doLoad=true)
{
   message(nls('Loading:')' 'module);
   if (!_haveProMacros() && file_exists(module:+"x")) {
      module :+= "x";
   }
   if ( pos(' ',module) ) module='"'module'"';
   if (_haveProMacros()) {
      status := _make(module);
      if (status < 0) {
         line := "Error compiling module: ":+module:+".  "get_message(status);
         _message_box(line);
         hotfixLogAction(line);
         return status;
      }
   }
   if (!doLoad) return(0);
   // Load needed a global variable since, defload and definit are executed
   // after the _load opcode completes.  We could change this if defload
   // and definit executed immediately.
   _loadrc= 0;
   _load(module,'r');_config_modify_flags(CFGMODIFY_LOADMACRO);
   status := _loadrc;
   if ( status ) {
      if ( substr(status,1,1)!='-' ) {
         status=1;
      }
      line := "Error loading module: ":+module:+".  "get_message(status);
      _message_box(line);
      hotfixLogAction(line);
   }
   return(status);
}
static int hotfixApplyModule(int handle, int node, _str zipfile, bool doRestore, _str (&filesToDelete)[], bool quiet)
{
   // get name of module to apply
   status := 0;
   name := _xmlcfg_get_attribute(handle, node, "Name");
   typeless doLoad=_xmlcfg_get_attribute(handle, node, "Load", 1);
   typeless doRun =_xmlcfg_get_attribute(handle, node, "Run",  0);

   // standardize the path separators
   name = stranslate(name, FILESEP, FILESEP2);
   namePath := _strip_filename(name, "N");
   nameFile := _strip_filename(name, "P");

   // will copy file into configuration directory / hotfixes
   dest := hotfixGetHotfixesDirectory();
   chdir(dest,1);
   dest :+= nameFile;

   // copy from the zip file
   src := zipfile :+ FILESEP :+ nameFile;

   // handle restore 
   line := "";
   if (doRestore) {
      // remove file and .ex from hotfixes directory
      if (file_exists(dest))       delete_file(dest);
      if (file_exists(dest'x'))    delete_file(dest'x');
      if (file_exists(dest".bak")) {
         _file_move(dest, dest".bak");
      }
      if (file_exists(dest"x.bak")) {
         _file_move(dest"x", dest"x.bak");
      }

      // will copy file into configuration directory / hotfixes
      src = _getSlickEditInstallPath();
      _maybe_append_filesep(src);
      src :+= "macros" :+ FILESEP :+ name;
      new_src := file_match("-T ":+_maybe_quote_filename(src), 1);
      if (new_src != "") src = new_src;

      // log the action
      line = "Restoring module: " :+ src;
      hotfixLogAction(line);
   }

   // execute batch macro?
   if (doRun) {
      line = "Run batch program: " :+ src;
      hotfixLogAction(line);
      if (doRestore) {
         line = "*** Can not undo effects of batch macro: " :+ src;
         hotfixLogAction(line);
         return 0;
      } else {
         if (!_haveProMacros() || file_exists(src:+"x")) {
            src :+= "x";
         } else if (pos(".zip":+FILESEP, src, 1, 'i')) {
            hotfixCopyModule(handle, node, zipfile, quiet);
            src = hotfixGetHotfixesDirectory() :+ nameFile;
         }
         return shell(_maybe_quote_filename(src));
      }
   } 

   // check if the module has a defmain and thus can't be loaded
   if (doLoad && file_exists(src) && hotfixCheckForDefmain(src)) {
      line = "Can not load module containing defmain(): " :+ src;
      hotfixLogAction(line);
      doLoad=false;
   }

   // load module?
   if (doLoad) {
      if (doRestore && !file_exists(src)) {
         line = "Module not found: " :+ src;
         hotfixLogAction(line);

      } else {
         line = "Loading module: " :+ src;
         hotfixLogAction(line);
   
         if (doRestore) {
            //unload(name'x');
         } else {
            if (_haveProMacros() && file_exists(dest:+'x')) {
               delete_file(dest:+'x');
            }
            if (_haveProMacros() && !file_exists(src:+"x") && pos(".zip":+FILESEP, src, 1, 'i')) {
               hotfixCopyModule(handle, node, zipfile, quiet);
               src = hotfixGetHotfixesDirectory() :+ nameFile;
            }
         }

         // for macros in namespace directories, they might import
         // other modules in their namespace using a relative path
         // work around this by prepending the namespace directory
         // to the macros path search.
         searchPath := get_env("VSLICKINCLUDE");
         if (namePath != '') {
            namespaceDir := _getSlickEditInstallPath() :+ "macros" :+ FILESEP :+ namePath;
            set_env("VSLICKINCLUDE", namespaceDir :+ PATHSEP :+ searchPath);
         }

         // compile and load the module
         status = hotfixMakeNload(src);
         if (!status) {
            _config_modify_flags(CFGMODIFY_LOADMACRO);
         }

         // restore the VSLICKINCLUDE path
         set_env("VSLICKINCLUDE", searchPath);
         return status;
      }
   }

   // that's all folks
   return 0;
}

static int hotfixCopyModule(int handle, int node, _str zipfile, bool quiet)
{
   // get name of module to apply
   status := 0;
   name := _xmlcfg_get_attribute(handle, node, "Name");

   // standardize the path separators
   name = stranslate(name, FILESEP, FILESEP2);
   namePath := _strip_filename(name, "N");
   nameFile := _strip_filename(name, "P");

   // will copy file into configuration directory / hotfixes
   dest := hotfixGetHotfixesDirectory() :+ nameFile;

   // check that the revision numbers are same or increasing
   // prompt if replacement module is older revision
   if (file_exists(dest)) {
      new_rev := hotfixGetModuleRevision(zipfile:+FILESEP:+nameFile);
      old_rev := hotfixGetModuleRevision(dest);
      if (hotfixCompareRevisions(new_rev, old_rev) < 0) {
         // if in quiet mode, never overwrite newer versions
         if (quiet) return 0;
         status = _message_box("Module \"" :+ nameFile :+ "\" has already been patched with a more recent revision.  Continue anyway?", "SlickEdit", MB_YESNO|MB_ICONQUESTION);
         if (status != IDYES) {
            return COMMAND_CANCELLED_RC;
         }
      }
   }

   // copy the file
   line := "Copying module to: " :+ dest;
   hotfixLogAction(line);
   status = hotfixCopyFile(zipfile, nameFile, dest, "bak");
   if (status) {
      return status;
   }

   // copy the .ex file if it exists
   bytecode := zipfile :+ FILESEP :+ nameFile :+ "x";
   if (file_exists(bytecode)) {
      dest :+= "x";
      nameFile :+= "x";
      line = "Copying bytecode to: " :+ dest;
      hotfixLogAction(line);
      status = hotfixCopyFile(zipfile,nameFile,dest,"bak", false);
      if (status) {
         return status;
      }
   }

   // that's all folks
   return 0;
}

// SlickEdit DLL interdependencies
static _str hotfixDLLDependencies:[] = {
   "tagsdb.dll" => "vsdebug.dll;cparse.dll",
   "vsscc.dll" => "vsvcs.dll",
};

static int hotfixApplyDLL(int handle, int node, _str zipfile, bool doRestore, _str (&filesToDelete)[], bool quiet)
{
   // check the architecture of the DLL
   arch := _xmlcfg_get_attribute(handle, node, "Arch");
   if (arch != null && arch != "" && machine():+machine_bits() != arch) {
      return VSUPDATE_INCORRECT_ARCHITECTURE_RC;
   }

   // get the name of the DLL
   name := _xmlcfg_get_attribute(handle, node, "Name");

   // compute destination file name
   root_dir := _getSlickEditInstallPath();
   _maybe_append_filesep(root_dir);
   dest := root_dir :+ "win" :+ FILESEP :+ name;

   // look up dependencies on other DLL's
   dependencies := "";
   if (hotfixDLLDependencies._indexin(name)) {
      dependencies = hotfixDLLDependencies:[name];
   }

   // unload all the DLL's that depend on us
   status := 0;
   line := "";
   temp := dependencies;
   while (temp != "") {
      dep_dll := "";
      parse temp with dep_dll ";" temp ;
      if (dep_dll != "") {
         line = "Unloading dependent DLL: " :+ dep_dll;
         hotfixLogAction(line);
         status = dunload(dep_dll);
         if (status) {
            line = "Failed to unload DLL: " :+ dep_dll;
            hotfixLogAction(line);
         }
      }
   }

   // now unload the target DLL
   line = "Unloading DLL: " :+ name;
   hotfixLogAction(line);
   dunload(name);
   if (status) {
      line = "Failed to unload DLL: " :+ name;
      hotfixLogAction(line);
   }

   // now copy in the new DLL,
   // even if the copy fails, we need to reload the DLL
   if (doRestore) {
      line = "Restoring DLL to: " :+ dest;
      hotfixLogAction(line);
      status = hotfixRestoreBackup(dest);
   } else {
      line = "Copied DLL to: " :+ dest;
      hotfixLogAction(line);
      status = hotfixCopyFile(zipfile, name, dest);
   }

   // now reload the target DLL
   line = "Loading DLL: " :+ dest;
   hotfixLogAction(line);
   status = dload(dest);
   if (status) {
      line = "Failed to load DLL: " :+ dest;
      hotfixLogAction(line);
   }

   // finally, reload the dependent DLL's
   temp = dependencies;
   while (temp != "") {
      dep_dll := "";
      parse temp with dep_dll ";" temp ;
      if (dep_dll != "") {
         line = "Reloading dependent DLL: " :+ dep_dll;
         hotfixLogAction(line);
         dest = root_dir :+ "win" :+ FILESEP :+ dep_dll;
         status = dload(dest);
         if (status) {
            line = "Failed to load DLL: " :+ dest;
            hotfixLogAction(line);
         }
      }
   }

   // that's all folks
   return status;
}

static int hotfixApplyCommand(int handle, int node, _str zipfile, bool doRestore, _str (&filesToDelete)[], bool quiet)
{
   // get the command and run it
   cmd  := _xmlcfg_get_attribute(handle, node, "Exec");
   line := "Run command: " :+ cmd;
   hotfixLogAction(line);
   if (doRestore) {
      line = "*** Can not undo effects of command: " :+ cmd;
      hotfixLogAction(line);
      return 0;
   }
   return execute(cmd);
}

static int hotfixApplyZipFile(int handle, int node, _str zipfile, bool &restart, 
                              bool doRestore, _str (&filesToDelete)[], bool quiet)
{
   // get the name and destination path
   name := _xmlcfg_get_attribute(handle, node, "Name");

   // create path to copy zip file to
   inner_zipfile := zipfile :+ FILESEP :+ name;

   // get path to hotfixes under config directory
   dest := hotfixGetHotfixesDirectory() :+ name;

   // copy the zip file into the hotfixes directory
   status := copy_file(inner_zipfile, dest);
   if (status < 0) {
      return status;
   }

   // show that we are recursively expanding hot fixes
   hotfixLogAction("--------------------------------------------------");

   // tell them about it and copy the file
   if (doRestore) {
      line := "Unloading fixes from zip file: " :+ name;
      hotfixLogAction(line);
      hotfixUnload(dest, restart, true);
   } else {
      line := "Applying fixes from zip file: " :+ name;
      hotfixLogAction(line);
      hotfixLoad(dest, restart, true);
   }

   // show that we are done with recursion
   hotfixLogAction("--------------------------------------------------");

   // that's all folks
   return 0;
}

static int hotfixCopyZipFile(_str zipfile)
{
   // get path to hotfixes under config directory
   hotfixDir := hotfixGetHotfixesDirectory();

   // make directory if it doesn't exist already
   status := 0;
   if (!isdirectory(hotfixDir)) {
      status = make_path(hotfixDir);
      if (status) {
         _message_box("Could not make directory: " :+ hotfixDir);
         return status;
      }
   }

   // check and see if they are using a hotfix in the hotfix directory
   name := _strip_filename(zipfile, 'p');
   dest := hotfixDir :+ name;
   if (_file_eq(dest, zipfile)) {
      return 0;
   }

   // copy the zip file to the hotfix directory
   status = copy_file(zipfile, dest);
   if (status < 0) {
      _message_box("Could not copy \"" :+ zipfile :+ "\" to configuration directory");
   } 

   // that's all
   return status;
}

static int hotfixCopyModules(int handle, _str zipfile, bool quiet)
{
   node := _xmlcfg_find_simple(handle, "/HotFix/Contents");
   if (node < 0) {
      if (!quiet) {
         _message_box("Hot fix has no contents!");
      }
      return STRING_NOT_FOUND_RC;
   }

   child := _xmlcfg_get_first_child(handle, node);
   if (child < 0) {
      if (!quiet) {
         _message_box("Hot fix has no contents!");
      }
      return STRING_NOT_FOUND_RC;
   }

   status := result := 0;
   while (child >= 0) {

      item := _xmlcfg_get_name(handle, child);
      if (item :== "Module") {
         status = hotfixCopyModule(handle, child, zipfile, quiet);
         if (status < 0) result=status;
      }

      // If they cancelled out of something, the quit now
      if (status == COMMAND_CANCELLED_RC) {
         hotfixLogAction("Cancelled.");
         break;
      }

      child = _xmlcfg_get_next_sibling(handle, child);
   }

   hotfixLogAction("Modules copied.");
   dsay("==================================================");
   clear_message();
   return result;
}

static void hotfixLogAction(_str msg)
{
   dsay(msg);
   _SccDisplayOutput(msg);
}

static int hotfixApply(int handle, _str zipfile, 
                       bool &restart, bool doRestore, bool quiet)
{
   node := _xmlcfg_find_simple(handle, "/HotFix/Contents");
   if (node < 0) {
      if (!quiet) {
         _message_box("Hot fix has no contents!");
      }
      return STRING_NOT_FOUND_RC;
   }

   child := _xmlcfg_get_first_child(handle, node);
   if (child < 0) {
      if (!quiet) {
         _message_box("Hot fix has no contents!");
      }
      return STRING_NOT_FOUND_RC;
   }

   _str filesToDelete[];
   origDir := getcwd();
   status := result := 0;
   while (child >= 0) {

      item := _xmlcfg_get_name(handle, child);
      switch (item) {
      case "File":   
         status = hotfixApplyFile(handle, child, zipfile, doRestore, filesToDelete, quiet);    
         if (status < 0) result=status;
         break;
      case "Config":   
         status = hotfixApplyConfig(handle, child, zipfile, doRestore, filesToDelete, quiet);
         if (status < 0) result=status;
         break;
      case "Module": 
         status = hotfixApplyModule(handle, child, zipfile, doRestore, filesToDelete, quiet);
         if (status < 0) result=status;
         break;
      case "DLL":    
         status = hotfixApplyDLL(handle, child, zipfile, doRestore, filesToDelete, quiet);     
         if (status < 0) result=status;
         break;
      case "Sysconfig":   
         status = hotfixApplySysconfig(handle, child, zipfile, doRestore, filesToDelete, quiet);
         if (status < 0) result=status;
         break;
      case "Command":
         status = hotfixApplyCommand(handle, child, zipfile, doRestore, filesToDelete, quiet); 
         if (status < 0) result=status;
         break;
      case "ZipFile":
         status = hotfixApplyZipFile(handle, child, zipfile, restart, doRestore, filesToDelete, true);
         if (status < 0) result=status;
         break;
      case "Plugin":
         status = hotfixApplyPlugin(handle, child, zipfile, doRestore, filesToDelete, quiet);
         if (status < 0) result=status;
         else restart = true;
         break;
      case "Statefile":
         status = hotfixApplyStatefile(handle, child, zipfile, doRestore, filesToDelete, quiet);
         if (status < 0) result=status;
         else restart = true;
         break;
      }

      // If they cancelled out of something, the quit now
      if (status == COMMAND_CANCELLED_RC) {
         hotfixLogAction("Cancelled.");
         break;
      }

      child = _xmlcfg_get_next_sibling(handle, child);
   }

   // create xml file to indicate there are files to delete
   if (doRestore && filesToDelete._length() > 0) {
      hotfixRevision := hotfixGetRevision(handle);
      hotfixScheduleFilesForDelete(filesToDelete, hotfixRevision);
   }

   hotfixLogAction("Done.");
   dsay("==================================================");
   clear_message();
   chdir(origDir,1);
   return result;
}

static void hotfixScheduleFilesForDelete(_str (&filesToDelete)[], _str hotfixRevision)
{
   // nothing but nothing equals nothing to do for me
   if (filesToDelete._length() <= 0) return;

   // open temporary view for creating the deletion list file
   temp_wid := orig_wid := 0;
   orig_wid = _create_temp_view(temp_wid);
   if (!orig_wid) return;
   config_dir := _ConfigPath();
   _maybe_append_filesep(config_dir);

   // insert header for manifest
   insert_line("<actions>");
   foreach (auto f in filesToDelete) {
      insert_line("\t<delete_file name=\"":+relative(f,config_dir):+"\"/>");
      hotfixLogAction("Unloaded configuration file: ":+f);
   }
   insert_line("</actions>");

   // save manifest and cleanup
   manifest := _maybe_quote_filename(config_dir:+"shutdown.xml");
   status := save_as(manifest);
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);
   if (status < 0) {
      line := "*** Could not create file: " :+ manifest :+ " -- " :+ get_message(status);
      hotfixLogAction(line);
   } else {
      hotfixLogAction("Unloaded configuration files scheduled for deletion.");
   }
}

static int hotfixSaveFiles()
{
   if (_no_child_windows()) return 0;
   _project_disable_auto_build(true);
   status := _mdi.p_child.list_modified("Files must be saved before applying hotfix",true);
   _project_disable_auto_build(false);
   return status;
}

static int hotfixShowInfo(HotfixInfo &info, int reason)
{
   status := hotfixCheckDescription(info, reason);

   return status;
}

bool hotfixCanLoad(_str zipfile, 
                      _str (&files)[], 
                      _str (&system_files)[], 
                      _str (&fix_list)[]=null, 
                      bool quiet=false, 
                      bool checkIfApplied=true, 
                      bool checkFiles=true)
{
   // make sure they haven't already applied this hot fix
   if (checkIfApplied) {
      status := hotfixCheckIfApplied(zipfile, quiet);
      if (status) {
         return false;
      }
   }

   // make sure that the zip file has a manifest
   manifest_handle := hotfixOpenManifest(zipfile);
   if (manifest_handle < 0) {
      if (!quiet) {
         _message_box("Invalid hot fix.  Could not open manifest: " :+ get_message(manifest_handle));
      }
      return false;
   }

   // check the version number
   compatibleVersions := "";
   fix_version := hotfixGetVersion(manifest_handle, &compatibleVersions);
   status := hotfixCheckVersion(fix_version, compatibleVersions, quiet);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(zipfile);
      return false;
   }

   // check the hotfix requirements
   fix_requires := hotfixGetRequirements(manifest_handle, auto fix_requires_names);
   status = hotfixCheckRequirements(fix_requires, fix_requires_names, fix_list);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(zipfile);
      return false;
   }

   // check if the hot fix affects system files
   if (checkFiles) {
      _str readonly_files[];
      status = hotfixGetFiles(manifest_handle, files, system_files, readonly_files);
      if (status < 0) {
         if (!quiet) {
            if (status == ACCESS_DENIED_RC) {
               status = _message_box("This hot fix modifies files under your SlickEdit installation directory.\n\n":+
                                     "You do not have write access to all these files.  Installation terminated.\n\n":+
                                     join(readonly_files,"\n"));
            }
            if (status == VSUPDATE_DLL_ONLY_FOR_WINDOWS_RC) {
               status = _message_box("This hot fix includes DLL's which are for Windows platforms only.\n\n":+
                                     "Installation terminated.");
            }
            // silently skip files that are for other architecutres
            if (status == VSUPDATE_INCORRECT_ARCHITECTURE_RC) {
               status = _message_box("This hot fix includes files which are for another platform or architecture.\n\n":+
                                     "Installation terminated.");
            }
         }
         _xmlcfg_close(manifest_handle);
         _ZipClose(zipfile);
         return false;
      }
   }

   // all good
   _xmlcfg_close(manifest_handle);
   _ZipClose(zipfile);
   return true;
}

static int hotfixPrepareToLoad(_str &zipfile, bool &restart, bool quiet=false)
{
   // find the zip file to load
   orig_zipfile := zipfile;
   manifest_handle := 0;
   for (;;) {
      zipfile = orig_zipfile;
      zipfile = hotfixGetZipFile(zipfile);
      if (zipfile == "") {
         return COMMAND_CANCELLED_RC;
      }

      // make sure that the zip file has a manifest
      manifest_handle = hotfixOpenManifest(zipfile);
      if (manifest_handle < 0) {
         if (!quiet) {
            _message_box("Invalid hot fix.  Could not open manifest: " :+ get_message(manifest_handle));
         }
         if (!quiet && orig_zipfile=="") continue;
         return manifest_handle;
      }

      // check the version number
      compatibleVersions := "";
      fix_version := hotfixGetVersion(manifest_handle, &compatibleVersions);
      status := hotfixCheckVersion(fix_version, compatibleVersions, quiet);
      if (status < 0) {
         _xmlcfg_close(manifest_handle);
         _ZipClose(zipfile);
         if (!quiet && orig_zipfile=="") continue;
         return status;
      }

      // make sure they haven't already applied this hot fix
      status = hotfixCheckIfApplied(zipfile, quiet);
      if (status) {
         if (!quiet && orig_zipfile=="") continue;
         return status;
      }

      // we've got a good one!
      break;
   }

   // check the hotfix requirements
   _str fix_list[];
   fix_requires := hotfixGetRequirements(manifest_handle, auto fix_requires_names);
   status := hotfixCheckRequirements(fix_requires, fix_requires_names, fix_list);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(zipfile);
      return status;
   }

   // check if the hot fix affects system files
   _str files[];
   _str system_files[];
   _str readonly_files[];
   status = hotfixGetFiles(manifest_handle, files, system_files, readonly_files);
   if (status < 0) {
      if (!quiet) {
         if (status == ACCESS_DENIED_RC) {
            _message_box("This hot fix modifies files under your SlickEdit installation directory.\n\n":+
                         "You do not have write access to all these files.  Installation terminated.\n\n":+
                         join(readonly_files,"\n"));
         }
         if (status == VSUPDATE_DLL_ONLY_FOR_WINDOWS_RC) {
            _message_box("This hot fix includes DLL's which are for Windows platforms only.\n\n":+
                         "Installation terminated.");
         }
         // silently skip files that are for other architecutres
         if (status == VSUPDATE_INCORRECT_ARCHITECTURE_RC) {
            _message_box("This hot fix includes files which are for another platform or architecture.\n\n":+
                         "Installation terminated.");
         }
      }
      _xmlcfg_close(manifest_handle);
      _ZipClose(zipfile);
      return status;
   }

   // match this hotfix against already loaded ones
   current_rev := "";
   foreach (auto loaded_fix in fix_list) {
     parse loaded_fix with auto file "\t" auto revision;
     if (_file_eq(file, _strip_filename(zipfile,'pe'))) {
        current_rev = revision;
     }
   }

   // show the description of the hot fix to confirm before applying
   HotfixInfo info;
   info.ZipFile = zipfile;
   info.ManifestHandle = manifest_handle;
   info.Files = files;
   info.SystemFiles = system_files;
   info.Restart = hotfixGetRestart(manifest_handle);
   info.LoadedRevision = current_rev;
   status = hotfixCheckDescription(info, HPFP_MANUAL_PROMPT);
   if (status != IDOK) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(zipfile);
      return COMMAND_CANCELLED_RC;
   }

   // make them save files before applying the hot fix
   if (!quiet) {
      status = hotfixSaveFiles();
      if (status < 0) {
         _xmlcfg_close(manifest_handle);
         _ZipClose(zipfile);
         return status;
      }
   }

   return manifest_handle;
}

static int hotfixLoad(_str zipfile, bool &restart, bool quiet=false)
{
   manifest_handle := hotfixPrepareToLoad(zipfile, restart, quiet);
   if (manifest_handle < 0) {
      return manifest_handle;
   }

   result := hotfixLoadByManifest(zipfile, manifest_handle, restart, quiet);
   if (!result) {
      // we were successful, so let's restart our hotfix thread
      gLastSearchTime = 0;
   }

   return result;
}

static int hotfixLoadByManifest(_str zipfile, int manifest_handle, bool &restart, bool quiet = false, bool closeManifest = true)
{
   // copy the zip file to the user's configuration directory
   newZipFile := "";
   status := hotfixCopyZipFile(zipfile);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(zipfile);
      return status;
   }

   // initialize results output
   _SccDisplayOutput("Applying hot fix: "zipfile, !quiet);
   dsay("==================================================");

   // modules need to be copied first to destination directory before being loaded
   // hotfixApplyModule still handles the unload operations for deleting files
// status = hotfixCopyModules(manifest_handle, zipfile, quiet);
// if (status < 0) {
//    _xmlcfg_close(manifest_handle);
//    return status;
// }

   dsay("==================================================");
   dsay("Applying hot fix: "zipfile);

   // apply each rule in the hot fix
   orig_timers:=_use_timers;
   _use_timers=0;
   status = hotfixApply(manifest_handle, zipfile, restart, false, quiet);
   _use_timers=orig_timers;

   // check if this hotfix requires a restart
   if (!status) {
      restart = restart || hotfixGetRestart(manifest_handle);
   }

   // finally, close the manifest
   if (manifest_handle && closeManifest) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(zipfile);
   }

   // that's all folks!
   return status;
}

static int hotfixUnload(_str zipfile, bool &restart, bool quiet=false)
{
   // get name of hot fix to unload
   if (zipfile == "") {
      zipfile = hotfixChooser("Select hot fix to unload");
      if (zipfile == "") {
         _message_box("No hot fixes loaded.");
      }
   } else if (!quiet) {
      status := _message_box("Unload hotfix?  ":+zipfile, "SlickEdit", MB_YESNOCANCEL|MB_ICONQUESTION);
      if (status != IDYES) {
         return COMMAND_CANCELLED_RC;
      }
   }
   if (zipfile=="" || zipfile==COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }
   if (!file_exists(zipfile)) {
      if (!quiet) {
         _message_box("File not found: "zipfile);
      }
      return FILE_NOT_FOUND_RC;
   }

   // make sure that the zip file has a manifest
   manifest_handle := hotfixOpenManifest(zipfile);
   if (manifest_handle < 0) {
      if (!quiet) {
         _message_box("Invalid hot fix.  Could not open manifest: " :+ get_message(manifest_handle));
      }
      return manifest_handle;
   }

   // initialize results output
   _SccDisplayOutput("Removing hot fix: "zipfile, !quiet);
   dsay("==================================================");
   dsay("Removing hot fix: "zipfile);

   // apply the hot fix
   orig_timers:=_use_timers;
   _use_timers=0;
   status := hotfixApply(manifest_handle, zipfile, restart, true, quiet);
   _use_timers=orig_timers;

   // check if fix requires a restart
   if (!status) {
      restart = restart || hotfixGetRestart(manifest_handle);
   }

   // finally, close the manifest
   if (manifest_handle) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(zipfile);
   }

   // finally, move the zip file out of the way
   unloaded_zipfile := zipfile :+ ".unloaded";
   if (file_exists(unloaded_zipfile)) {
      delete_file(unloaded_zipfile);
   }
   _file_move(unloaded_zipfile, zipfile);
   if (file_exists(zipfile)) {
      delete_file(zipfile);
   }

   // that's all folks
   return 0;
}

/**
 * Find all hotfixes in the given path, and extract the vital
 * information and load that into the "fix_list" array.
 * 
 * @param path             directory to scan for fixes
 * @param fix_list         (reference) list of fixes, each line has the format:
 *                         <pre>
 *                            file [tab] series [tab] revision [tab] date [tab] description [tab] fixes
 *                         </pre>
 * @param infoFlags        what info to include in each line 
 * @param findAllHotfixes  If 'false' only find hot fixes that can be loaded by this version 
 * @param checkIfApplied   If 'true' only find hot fixes that have been loaded by this version 
 * 
 * @return <0 on failure, number of fixes >0 on success
 */
static int hotfixFindAll(_str path, _str (&fix_list)[], int infoFlags, bool findAllHotfixes=false, bool checkIfApplied=false)
{
   // find the hotfixes directory
   if (path=="") {
      path = hotfixGetHotfixesDirectory();
   }

   // and wildcards to find all the zip files
   _maybe_append_filesep(path);
   path :+= "*.zip";
   path = _maybe_quote_filename(path);

   // look for zip files
   _str all_files[];
   file := file_match(path, 1);
   if (file == "") {
      return FILE_NOT_FOUND_RC;
   }
   while (file != "") {
      // next please
      all_files :+= file;
      file = file_match(path, 0);
   }

   foreach (file in all_files) {
      // check if the hot fix can be loaded by this version of SlickEdit
      if (findAllHotfixes || hotfixCanLoad(file, null, null, null, true, false, false)) {
         // check if it was already loaded
         if (!checkIfApplied || hotfixCheckIfApplied(file, true)) {
            fix_list :+= hotfixGetInfoStr(file, infoFlags);
         }
      }
   }

   // success
   fix_list._sort('F');
   return fix_list._length();
}

/**
 * Returns information about the given hotfix file.  Information includes the 
 * filename, revision, fixdate, description, and list of fixes.  Specify 
 * includeDescriptions = false to exclude the description and fixes. 
 * 
 * @param zipfile 
 * @param includeDescriptions 
 * 
 * @return _str 
 */
static _str hotfixGetInfoStr(_str zipfile, int infoFlags)
{
   // no flags?
   if (infoFlags == 0) return '';
   
   info := '';
   if (infoFlags & HIF_FILENAME) {
      info = zipfile;
   }
      
   fixDate  := "";
   revision := "";
   description := "";
   fixes := "";
   manifest_handle := hotfixOpenManifest(zipfile);
   if (manifest_handle > 0) {

      // do we want the series?
      if (infoFlags & HIF_SERIES) {
         info :+= "\t" :+ hotfixGetSeries(manifest_handle);
      }

      // how about the revision?
      if (infoFlags & HIF_REVISION) {
         info :+= "\t" :+ hotfixGetRevision(manifest_handle);
      }

      // do we want the fix date?
      if (infoFlags & HIF_FIX_DATE) {
         info :+= "\t" :+ hotfixGetDate(manifest_handle);
      }

      // description of hotfix?
      if (infoFlags & HIF_DESCRIPTION) {
         info :+= "\t" :+ hotfixGetDescription(manifest_handle);
      }

      // list of fixes?
      if (infoFlags & HIF_FIXES) {
         info :+= "\t" :+ hotfixGetFixDescriptions(manifest_handle, auto have_revs);
      }

      // versions of editor this fix applies to
      if (infoFlags & HIF_VERSIONS) {
         compatible := "";
         info :+= "\t" :+ hotfixGetVersion(manifest_handle, &compatible);
         if (compatible != "") info :+= " " :+ compatible;
      }

      // all done with this one
      _xmlcfg_close(manifest_handle);
      _ZipClose(zipfile);
   }

   return strip(info);
}

/**
 * Generate HTML text describing all the hot fixes in the given list.
 * 
 * @param fix_list   list of hot fix descriptions
 * @param skip_i     hot fix index to skip (for cumulative fix)
 */
static _str hotfixGenerateHTML(_str (&fix_list)[])
{
   // now generate HTML for all the other fixes
   result := "";
   n := fix_list._length();
   for (i:=0; i<n; ++i) {

      _str file,revision,date,description,fixes;
      parse fix_list[i] with file "\t" revision "\t" date "\t" description "\t" fixes "\t";
      size := hotfixGetFileSize(file);
      file = _strip_filename(file,'p');

      strappend(result,"<p>");
      strappend(result,"<b>File name:</b> ");
      strappend(result,"<font color=green>"file"</font><br>");
      strappend(result,"<b>File size:</b> "(size intdiv 1024)" KB<br>");
      strappend(result,"<b>Date</b>: "date"<br>");
      strappend(result,"<b>Revision</b>: "revision"<br>");
      strappend(result,"<b>Description</b>:");
      strappend(result,description);
      strappend(result,"<b>Fixes</b>:");
      strappend(result,fixes);
      strappend(result,"</p>");
   }

   return result;
}

static _str hotfixChooser(_str caption="", _str path="")
{
   // get the list of fixes in the specified directory
   _str fix_list[];
   status := hotfixFindAll(path, fix_list, (HIF_FILENAME | HIF_REVISION | HIF_FIX_DATE));
   if (status <= 0) {
      return "";
   }

   // display the list of hot fixes
   choice := select_tree(fix_list, 
                         null, null, null, null, null, null, 
                         caption,
                         SL_COLWIDTH,
                         "Fix,Revision,Date",
                         (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_IS_FILENAME|TREE_BUTTON_SORT_FILENAME)","(TREE_BUTTON_PUSHBUTTON)","(TREE_BUTTON_PUSHBUTTON)","(TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_WRAP)
                        );
   parse choice with choice "\t" . ;
   return choice;
}

static _str hotfixList(_str caption="", _str path="")
{
   // get the list of fixes in the specified directory
   _str fix_list[];
   status := hotfixFindAll(path, fix_list, (HIF_FILENAME | HIF_REVISION | HIF_FIX_DATE | HIF_DESCRIPTION | HIF_FIXES));
   if (status <= 0) {
      _message_box("No hot fixes found");
      return status;
   }

   // generate the HTML string
   msg := hotfixGenerateHTML(fix_list);
   
   // now show them the list of fixes
   return textBoxDialog(caption,       // Form caption
                        0,             // Flags
                        8000,             // Use default textbox width
                        "", // Help item
                        "OK\t-html ":+msg
                        );
}

/**
 * Load a hot fix.
 */
_command void load_hotfix(_str zipfile="", bool quiet=false) name_info(FILE_ARG','VSARG2_NCW|VSARG2_READ_ONLY)
{
   // Can't load hot fix into a non-primary instance since it can't write a local state file.
   if (!_default_option(VSOPTION_LOCALSTA)) {
      _message_box('Please exit all instances of SlickEdit, restart SlickEdit, and retry loading a hot fix.');
      return;
   }
   zipfile = strip(zipfile, 'B', '"');
   if (zipfile != "") zipfile = absolute(zipfile);
   status := hotfixLoad(zipfile, auto doRestart=false, quiet);
   if (status != COMMAND_CANCELLED_RC) {
      hotfixCheckRestart(doRestart);
   }
}

/**
 * List currently installed hot fixes.
 */
_command void list_hotfixes(_str path="") name_info(DIR_ARG','VSARG2_NCW|VSARG2_READ_ONLY)
{
   path = strip(path, 'B', '"');
   hotfixList("Loaded hot fixes",path);
}

/**
 * Unload the specified hot fix.  If given no arguments, will list the
 * currently installed hot fixes and allow you to select one to unload.
 */
_command void unload_hotfix(_str zipfile="", bool quiet=false) name_info(FILE_ARG','VSARG2_NCW|VSARG2_READ_ONLY)
{
   zipfile = strip(zipfile, 'B', '"');
   if (zipfile != "") zipfile = absolute(zipfile);
   status := hotfixUnload(zipfile, auto doRestart=false, quiet);
   if (status != COMMAND_CANCELLED_RC) {
      hotfixCheckRestart(doRestart);
   }
}
_command void delete_old_hotfix_files() name_info(','VSARG2_NCW|VSARG2_READ_ONLY)
{
   _str latest_revision;
   find_latest_hotfix_revision(latest_revision);
   if (latest_revision=='') {
      return;
   }
   _str ver=_version();
   _str path=hotfixGetHotfixesDirectory();
   strappend(path,'hotfix_*_*_cumulative.zip');
   path=_maybe_quote_filename(path);
   filename := file_match('-d 'path,1);
   _str hotfix_files[];
   while (filename!='') {
      hotfix_files[hotfix_files._length()]=filename;
      filename=file_match('-d 'path,0);
   }
   foreach (auto j=>filename in hotfix_files) {
      i:=pos('hotfix_[a-z]#{#0[0-9]#}_{#1[0-9]#}_cumulative.zip',filename,1,'r');
      if (i>0) {
         revision:=substr(filename,pos('S1'),pos('1'));
         if (revision<latest_revision) {
            delete_file(filename);
            filename=_ConfigPath():+'vslick.ver.':+ver:+'.':+revision:+'.sta';
            delete_file(filename);
            filename=_ConfigPath():+'plugins':+FILESEP:+'com_slickedit.base.ver.':+ver:+'.':+revision:+'.zip';
            delete_file(filename);
         }
      }
   }
}

/**
 * Create a new hot fix ZIP file.  This will prompt you for a set of
 * files, or you can specify the file set on the command line.  It will
 * then generate the manifest file and zip everything up into the
 * zipfile that you specify.
 */
_command void create_hotfix(_str files="") name_info(MULTI_FILE_ARG','VSARG2_NCW|VSARG2_READ_ONLY)
{
   // get significant directories
   config_dir := _ConfigPath();
   _maybe_append_filesep(config_dir);
   root_dir   := _getSlickEditInstallPath();
   _maybe_append_filesep(root_dir);
   macros_dir := root_dir :+ "macros" :+ FILESEP;
   win_dir    := root_dir :+ "win" :+ FILESEP;
   win64_dir  := root_dir :+ "win64" :+ FILESEP;
   sysconfig_dir := root_dir :+ "plugins" :+ FILESEP :+ "com_slickedit.base" :+ FILESEP "sysconfig" :+ FILESEP;
   base_plugins_dir := root_dir :+ "plugins" :+ FILESEP :+ "com_slickedit.base";

   // parse out create options
   revisionNumber := '';
   doRestart := false;
   files = strip(files);
   while (_first_char(files) == '-') {
      opt := parse_file(files);
      if (opt == "-restart") {
         doRestart=true;
      }
      if (opt == "-revision") {
         revisionNumber = parse_file(files);
      }
   }

   // prompt user for fix file
   format_list := 'Macro Files(*.e;*.sh),All Files('ALLFILES_RE')';
   if (files == "") {
      files = _OpenDialog('-new -mdi -modal',
                            'Select file(s) to add to hot fix',
                            '',          // Initial wildcards
                            format_list, // file types
                            OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,
                            ".e",       // Default extensions
                            '',         // Initial filename
                            macros_dir, // Initial directory
                            '',         // Reserved
                            "Standard Open dialog box"
                            );
      if (files == "") {
         return;
      }
   }

   // prompt for description of hot fix
   status := textBoxDialog("Describe Hot Fix", 
                                 0, 0, "", "", "", 
                              "Name",
                              "Description");
   if (status < 0) {
      return;
   }
   hotfix_name := _param1;
   description := _param2;
   if (!pos("^[a-zA-z0-9_]*$", hotfix_name, 1, 'ri')) {
      _message_box("Invalid name:  "hotfix_name".  Hotfix names must contain only letters, numbers or underscores.");
      return;
   }

   // iterate through list of files
   fixes := "";
   item  := "";
   foreach (item in files) {
      item = _maybe_unquote_filename(item);
      item = _strip_filename(item, 'p');
      status = textBoxDialog("Describe Defect for '":+item"'", 
                             0, 0, "", "", "", 
                             "Defect#(s)",
                             "Description");
      if (status < 0) {
         return;
      }
      // skip this one if they don't given us any comments
      if (_param1 == '' && _param2 == '') continue;
      // add the fix descriptions
      fixes :+= "<Defect Ids=\"" :+ _param1 :+ "\" Modules=\"" :+ item :+ "\">\n";
      fixes :+= _param2 :+ "\n";
      fixes :+= "</Defect>\n";
   }

   // prompt for the path to save the hot fix
   format_list='Hotfix Files(*.zip),All Files('ALLFILES_RE')';
   zipfile := hotfix_name :+ ".zip";
   zipfile = _OpenDialog('-new -mdi -modal',
                         'Save hot fix to',
                         '',     // Initial wildcards
                         format_list,  // file types
                         OFN_SAVEAS,
                         ".zip",  // Default extensions
                         zipfile, // Initial filename
                         '',      // Initial directory
                         'hotfixCreateZipFile',      // Retrieve name
                         "Standard Open dialog box"
                         );

   // nothing good
   if (zipfile == '') return;

   // we may need to parse out an encoding value
   parse zipfile with auto temp1 auto temp2;
   if (temp2 != '') {
      if (isEncoding(temp1)) {
      zipfile = temp2;
      }
   }
   zip_dir := _strip_filename(zipfile, 'n');
   _maybe_append_filesep(zip_dir);

   // open temporary view for creating the manifest file
   _SccDisplayOutput("Creating hot fix: " :+ zipfile, true);
   temp_wid := orig_wid := 0;
   orig_wid = _create_temp_view(temp_wid);
   if (!orig_wid) return;

   // put together optional hot fix attributes
   hotfixAttrs := '';
   if (revisionNumber != '') {
      hotfixAttrs = " Revision=\""revisionNumber"\"";
   }
   if (doRestart) {
      hotfixAttrs :+= " Restart=\"1\"";
   }

   // insert header for manifest
   insert_line("<!DOCTYPE HotFix SYSTEM \"http://www.slickedit.com/dtd/vse/upcheck/1.0/hotfix.dtd\">");
   insert_line("<HotFix Date=\""_date('u')"\" Version=\""_version()"\""hotfixAttrs">");
   insert_line("<Description>");
   description = stranslate(description, "&amp;", "&");
   description = stranslate(description, "&gt;", ">");
   description = stranslate(description, "&lt;", "<");
   insert_line(description);
   insert_line("</Description>");
   insert_line(fixes);
   insert_line("<Contents>");

   // iterate through list of files
   orig_files := files;
   file := "";
   dest := "";
   _str fileArray[];
   item = parse_file(files, false);
   while (item != "") {
      item = _maybe_unquote_filename(item);
      fileArray :+= item;
      // get just the file name
      file = _strip_filename(item, 'p');

      // from macros directory?
      if (pos(macros_dir, item, 1, 'i')==1) {
         noLoadAttribute := "";
         if (hotfixCheckForDefmain(item)) {
            noLoadAttribute=' Load="0"';
         }
         relative_path := relative(item, macros_dir, false);
         relative_path = stranslate(relative_path, "/", FILESEP);
         insert_line("<Module Name=\""relative_path"\""noLoadAttribute"/>");
         if (_haveProMacros()) {
            _make(_maybe_quote_filename(item));
         }

         hotfixLogAction("Adding macro: ":+file);
         if (file_exists(item:+"x")) {
            fileArray :+= file:+"x";
            hotfixLogAction("Adding macro: ":+file:+"x");
         }
      } else if (lowcase(_get_extension(file))=="dll" && pos(win_dir, item, 1, 'i')==1) {
         // dll
         insert_line("<DLL Name=\""file"\" Arch=\""machine():+machine_bits()"\"/>");
         hotfixLogAction("Adding DLL: ":+file);
      } else if (lowcase(_get_extension(file))=="dll" && pos(win64_dir, item, 1, 'i')==1) {
         // win 64 dll
         insert_line("<DLL Name=\""file"\" Arch=\""machine():+"64\"/>");
         hotfixLogAction("Adding DLL: ":+file);
      } else if (lowcase(file)==STATE_FILENAME) {
         // state file
         insert_line("<Statefile Name=\""STATE_FILENAME"\"/>");
         hotfixLogAction("Adding Statefile: ":+file);
      } else if (pos(config_dir, item, 1, 'i')==1) {
         // configuration item
         dest = relative(item, config_dir);
         insert_line("<Config Name=\""file"\" Path=\""dest"\"/>");
         hotfixLogAction("Adding configuration file: ":+file);
         if (lowcase(_get_extension(file))=="e") {
            noLoadAttribute := "";
            if (hotfixCheckForDefmain(item)) {
               noLoadAttribute=' Load="0"';
            }
            _make(_maybe_quote_filename(item));
            if (file_exists(item:+"x")) {
               fileArray :+= item:+"x";
            }
         }
      } else if (pos(root_dir, item, 1, 'i')==1) {
         dest = relative(item, root_dir);
         if (pos(win_dir, item, 1, 'i')==1) {
            insert_line("<File Name=\""file"\" Path=\""dest"\" Arch=\""machine():+machine_bits()"\"/>");
            hotfixLogAction("Adding executable: ":+file);
         } else if (pos(win64_dir, item, 1, 'i')==1) {
            insert_line("<File Name=\""file"\" Path=\""dest"\" Arch=\""machine()"64\"/>");
            hotfixLogAction("Adding executable: ":+file);
         } else if (pos(sysconfig_dir, item, 1, 'i')==1) {
            relative_path := relative(item, sysconfig_dir, false);
            relative_path = stranslate(relative_path, "/", FILESEP);
            insert_line("<Sysconfig Name=\""relative_path"\" />");
            hotfixLogAction("Adding sysconfig: ":+file);
         } else if (pos(base_plugins_dir, item, 1, 'i')==1) {
            // base plugin, need to zip it up
            zipFile := zip_dir :+ 'com_slickedit.base.zip';
            _str zipArray[];
            zipArray[0]=base_plugins_dir;
            int statusArray[];
            _ZipCreate(zipFile, zipArray, statusArray);
            insert_line("<Plugin Name=\"com_slickedit.base.zip\" />");
            fileArray[fileArray._length() - 1] = zipFile;
            _ZipClose(zipFile);
            hotfixLogAction("Adding plugin com_slickedit.base.zip");
         } else {
            insert_line("<File Name=\""file"\" Path=\""dest"\"/>");
            hotfixLogAction("Adding other file: ":+file);
         }
      }

      // next please
      item = parse_file(files, false);
   }

   // insert final lines of hot fix
   files = orig_files;
   insert_line("</Contents>");
   insert_line("</HotFix>");

   // save manifest and cleanup
   manifest := _maybe_quote_filename(zip_dir:+HOTFIX_HOTFIX_MANIFEST_XML);
   status = save_as(manifest);
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);

   manifest=strip(manifest, 'b', "\"");
   fileArray :+= manifest;

   // create the zip file
   zipfile = strip(zipfile, 'B', '"');
   int fileStatus[];
   status=_ZipCreate(zipfile, fileArray, fileStatus);
   if ( status ) {
      msg:=nls("Error creating zip file\n\n%s",get_message(status));
      _message_box(msg);
   }

   // clean up
   hotfixLogAction("Created hot fix file: ":+zipfile);
   manifest=strip(manifest, 'b', "\"");
   delete_file(manifest);
   _ZipClose(zipfile);
}

/**
 * Create a new hot fix ZIP file based on the hotfix manifest 
 * file specified on the command line.  It will zip up all the 
 * required files listed in the manifest and also save the 
 * manifest to the hot fix ZIP file. 
 */
_command int create_hotfix_from_manifest(_str args="") name_info(FILE_ARG','VSARG2_NCW|VSARG2_READ_ONLY)
{
   // get significant directories
   config_dir := _ConfigPath();
   root_dir   := _getSlickEditInstallPath();
   _maybe_append_filesep(root_dir);
   macros_dir := root_dir :+ "macros" :+ FILESEP;
   win_dir    := root_dir :+ "win" :+ FILESEP;
   win64_dir  := root_dir :+ "win64" :+ FILESEP;
   base_plugins_dir := root_dir :+ "plugins" :+ FILESEP;
   sysconfig_dir := base_plugins_dir :+ "com_slickedit.base" :+ FILESEP "sysconfig" :+ FILESEP;
   tmp_dir := _temp_path();
   _maybe_append_filesep(tmp_dir);

   // parse out create options
   manifest_path := root_dir :+ "util" :+ FILESEP :+ HOTFIX_HOTFIX_MANIFEST_XML;
   revisionNumber := "1";
   hotfix_name := "cumulative";
   hotfix_dir := "";
   doRestart := false;
   haveManifestOpt := false;
   haveRevisionOpt  := false;
   haveHotfixOpt    := false;
   args = strip(args);
   while (_first_char(args) == '-') {
      opt := parse_file(args);
      if (opt == "-restart") {
         doRestart=true;
      }
      if (opt == "-revision") {
         revisionNumber = parse_file(args);
         haveRevisionOpt = true;
      }
      if (opt == "-manifest") {
         manifest_path = parse_file(args);
         haveManifestOpt = true;
      }
      if (opt == "-name") {
         hotfix_name = parse_file(args);
      }
      if (opt == "-hotfix") {
         haveHotfixOpt = true;
         hotfix_name = parse_file(args);
      }
      if (opt == "-dest") {
         hotfix_dir = parse_file(args);
         _maybe_append_filesep(hotfix_dir);
      }
   }
   opt := parse_file(args);
   if (opt != "" && file_exists(opt) && !haveManifestOpt) {
      manifest_path = opt;
      opt = parse_file(args);
   }
   if (opt != "" && isnumber(opt) && !haveRevisionOpt) {
      revisionNumber = opt;
   }

   // construct the hotfix name
   if (!haveHotfixOpt) {
      slick_version := _version();
      parse slick_version with auto major "." auto minor "." auto dot "." auto build;
      slick_version = major:+minor:+dot;
      hotfix_name = "hotfix_se" :+ slick_version  :+ "_" :+ revisionNumber :+ "_" :+ hotfix_name;
   }

   // make sure the manifest exists
   if (!file_exists(manifest_path)) {
      _message_box("File not found:  "manifest_path);
      return FILE_NOT_FOUND_RC;
   }

   // now open it as an xml config file
   status := 0;
   handle := _xmlcfg_open(manifest_path,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (status < 0) {
      _message_box("Could not open manifest:  "manifest_path"  \n\n"get_message(status));
      return status;
   }

   // get the list of files to collect
   _str files[];
   _str system_files[];
   _str readonly_files[];
   _str absolute_files[];
   status = hotfixGetFiles(handle, files, system_files, readonly_files, absolute_files, doRestart);
   if (status < 0) {
      _message_box("Could not get file list:  "get_message(status));
      _xmlcfg_close(handle);
      return status;
   }

   // open temporary view for editing the manifest file
   _SccDisplayOutput("Creating hot fix from manifest: "manifest_path, true);
   temp_wid := orig_wid := 0;
   orig_wid = _create_temp_view(temp_wid);
   if (!orig_wid) return FILE_NOT_FOUND_RC;

   hotfix_node := _xmlcfg_find_simple(handle, "/HotFix");
   if (pos("@", _xmlcfg_get_attribute(handle, hotfix_node, "Version"))) {
      _xmlcfg_set_attribute(handle, hotfix_node, "Version", _version());
   }
   _xmlcfg_set_attribute(handle, hotfix_node, "Date", _date('u'));
   _xmlcfg_set_attribute(handle, hotfix_node, "Revision", revisionNumber);
   if (doRestart) {
      _xmlcfg_set_attribute(handle, hotfix_node, "Restart", "1");
   }

  status =  _xmlcfg_save_to_buffer(temp_wid, handle, 2, VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR|VSXMLCFG_SAVE_PRESERVE_PCDATA);
  if (status < 0) {
     _message_box("Could not save manifest:  "get_message(status));
     return status;
  }

  // ok, we are done with the file listing now
  _xmlcfg_close(handle);

  // zip up plugins
  _str tmpFilesToDelete[];
  for (i:=0; i<absolute_files._length(); i++) {
     abs_file := absolute_files[i];
     rel_file := files[i];
     if (pos(sysconfig_dir, abs_file, 1, 'i')==1) {
        // do not confuse sysconfig with plugins
     } else if (pos(base_plugins_dir, abs_file, 1, 'i')==1) {
        // base plugin, need to zip it up
        if (_get_extension(rel_file) == "zip" || !file_exists(abs_file)) {
           pluginZipFile := tmp_dir :+ _strip_filename(rel_file,'p');
           if (_get_extension(rel_file) != "zip") pluginZipFile :+= ".zip";
           if (isdirectory(abs_file)) _maybe_append_filesep(abs_file);
           _str zipArray[];
           zipArray[0]=abs_file;
           int statusArray[];
           _ZipCreate(pluginZipFile, zipArray, statusArray);
           absolute_files[i] = pluginZipFile;
           tmpFilesToDelete :+= pluginZipFile;
           _ZipClose(pluginZipFile);
           hotfixLogAction("Adding plugin zip file: " :+ pluginZipFile);
           continue;
        }
     }
     // log the file add operation
     hotfixLogAction("Adding file: " :+ abs_file);
  }

  // prompt for the path to save the hot fix
  format_list := 'Hotfix Files(*.zip),All Files('ALLFILES_RE')';
  zipfile := hotfix_dir :+ hotfix_name :+ ".zip";
  if (hotfix_dir == "") {
     zipfile = _OpenDialog('-new -mdi -modal',
                           'Save hot fix to',
                           '',     // Initial wildcards
                           format_list,  // file types
                           OFN_SAVEAS,
                           ".zip",  // Default extensions
                           zipfile, // Initial filename
                           '',      // Initial directory
                           'hotfixCreateZipFile',      // Retrieve name
                           "Standard Open dialog box"
                           );
  }

  // nothing good
  if (zipfile == '') return COMMAND_CANCELLED_RC;

  // we may need to parse out an encoding value
  parse zipfile with auto temp1 auto temp2;
  if (temp2 != '') {
     if (isEncoding(temp1)) {
        zipfile = temp2;
     }
  }

   // save manifest and cleanup
   manifest := _maybe_quote_filename(tmp_dir:+HOTFIX_HOTFIX_MANIFEST_XML);
   status = save_as(manifest);
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);

   manifest=strip(manifest, 'b', "\"");
   fileArray := absolute_files;
   fileArray :+= manifest;
   tmpFilesToDelete :+= manifest;

   // create the zip file
   zipfile = strip(zipfile, 'B', '"');
   int fileStatus[];
   status=_ZipCreate(zipfile, fileArray, fileStatus);
   hotfixLogAction("Created hot fix: " :+ zipfile);
   if ( status ) {
      msg:=nls("Error creating zip file\n\n%s",get_message(status));
      _message_box(msg);
   }

   // clean up temporary files
   _ZipClose(zipfile);
   foreach (auto tmpFile in tmpFilesToDelete) {
      delete_file(tmpFile);
   }

   return 0;
}

_str aboutHotfixesList()
{
   _str fix_list[];
   status := hotfixFindAll("", fix_list, HIF_FILENAME | HIF_REVISION, findAllHotfixes:false, checkIfApplied:true);
   if (status <= 0) {
      return "";
   }
   
   hotfix_list := "<b>Hotfixes: </b>\n";
   for (i := 0; i < fix_list._length(); ++i) {
     parse fix_list[i] with auto file "\t" auto revision;
     hotfix_list :+= file"&nbsp;(Revision:&nbsp;"revision")\n";
   }

   updateMessage := hotfixGetFixAvailableMessage();
   if (updateMessage != "") {
      hotfix_list :+= "\n<b>Update Available:</b>\n" :+ updateMessage :+ "\n";
   }
   return hotfix_list;
}

_str getHotfixesList()
{
   _str fix_list[];
   status := hotfixFindAll("", fix_list, HIF_FILENAME | HIF_REVISION, true, true);
   if (status <= 0) {
      return "";
   }
   
   hotfix_list := "";
   for (i := 0; i < fix_list._length(); ++i) {
     parse fix_list[i] with auto file "\t" auto revision;
     hotfix_list :+= _strip_filename(file,'P'):+" (Revision: "revision") ";
   }
   return hotfix_list;
}

//////////////////////////////////////////////////////////////////////
// End Update Manager Hotfix loading code
//////////////////////////////////////////////////////////////////////



bool gAutoHotfixesFound = false;
_str gLastSearchTime = 0;
int gLastSearchFinished = 0;
_str gConfigFileDate = 0;

static const HOTFIX_AUTO_SEARCH_PERIOD=         5;
static const HOTFIX_AUTO_SEARCH_INTERVAL=       se.datetime.DT_MINUTE;

static bool doAutoHotfixWork()
{
   if (gbgm_search_state ||
       _tbDebugQMode() ||
       _default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS) == SW_HIDE) {
      return false;
   }

   return true;
}

_command void hotfix_auto_apply(bool quiet = false) name_info(',')
{
   if (!doAutoHotfixWork()) return;

   // are there any hotfixes waiting to be applied?
   if (hotfixesToApply()) {
      hotfixApplyAutoFoundHotfixes(false);
   } else {
      if (!quiet) {
         _message_box("There are no available hot fixes at this time.");
      }
   }
}

int _OnUpdate_hotfix_auto_apply()
{
   if (hotfixesToApply()) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

void hotfixAutoApplyOnExit()
{
   // we do this if we are not set to prompt
   if (!def_hotfix_auto_prompt && hotfixesToApply()) {
      hotfixApplyAutoFoundHotfixes(true);
   }
}

void _hotfix_startup()
{
   // reset this to 0, so we'll search again
   gLastSearchTime = "0";
   gAutoHotfixesFound = false;
   gLastSearchFinished = 0;
   gConfigFileDate = "0";
}

void hotfixAutoFindCallback(bool AlwaysUpdate=false)
{
   if (!AlwaysUpdate && _idle_time_elapsed() < 1000) {
      return;
   }
   if (!doAutoHotfixWork()) return;

   // is it time to look for hotfixes again?
   if (hotfixTimeToAutoSearch()) {
      if (def_auto_hotfixes_path != '') {
//       say(_time('f')' - got a path - starting up');
         gLastSearchFinished = 0;
         gLastSearchTime = _time('B');
         _hotfix_auto_search(def_auto_hotfixes_path, _ConfigPath());
      }
   } else {
      // no, let's check if the last thread finished - we only do 
      // this if we did not previously find something.  Once we 
      // have found something for the session, we don't care if 
      // stuff gets found again
      if (!gLastSearchFinished) {

         // is the thread finished running
         if (_hotfix_auto_search_finished()) {

            gLastSearchFinished = 1;

            // we may need to turn an alert on or off
            hotfixHandleAutoAlert();
         }
      } else {
         // see if it's time to turn off the alert
         hotfixHandleAutoAlert();
      }
   }
}

static void hotfixHandleAutoAlert()
{
   // we only mess with alerts if we are supposed to prompt this user
   if (!def_hotfix_auto_prompt) return;

   // see if the config file was updated
   curDate := _file_date(hotfixGetAutoConfigFile(), 'B');
   if (curDate != gConfigFileDate) {
      // this file was changed
      if (hotfixesToApply()) {
         if (!gAutoHotfixesFound) {
            _ActivateAlert(ALERT_GRP_UPDATE_ALERTS, ALERT_HOTFIX_AUTO_FOUND, hotfixGetFixAvailableMessage(false), 'Update Available');
            gAutoHotfixesFound = true;
         }
      } else {
         if (gAutoHotfixesFound) {
//          _ClearLastAlert(ALERT_GRP_UPDATE_ALERTS, ALERT_HOTFIX_AUTO_FOUND);
            _UnregisterAlert(ALERT_GRP_UPDATE_ALERTS);
            gAutoHotfixesFound = false;
         }
      }

      gConfigFileDate = curDate;
   }
}

_str hotfixGetFixAvailableMessage(bool call_autohotfix_time=true) 
{
   // Avoid infinite recursion
   if (call_autohotfix_time) {
      hotfixAutoFindCallback(true);
   }
   if (hotfixesToApply()) {
      return "Your system administrator has configured a hot fix to be loaded. To apply it now, click <a href=\"<<cmd hotfix_auto_apply\">here</a>.";
   }
   return "";
}

static bool hotfixTimeToAutoSearch()
{
   // if this is 0, then we go ahead and do this thing
   if (!gLastSearchTime) return true;
      
   DateTime now();
   DateTime then = DateTime.fromTimeB(gLastSearchTime);
   DateTime theNextTime = then.add(HOTFIX_AUTO_SEARCH_PERIOD, HOTFIX_AUTO_SEARCH_INTERVAL);

   return (now.compare(theNextTime) > 0);
}

static bool hotfixesToApply()
{
   stuffToApply := false;
   configHandle := 0;
   do {
      configHandle = hotfixOpenAutoConfigFile();
      if (configHandle < 0) break;

      // find our list of hotfixes to apply
      applyListNode := _xmlcfg_find_simple(configHandle, "/HotfixesToApply");
      if (applyListNode < 0) break;

      child := _xmlcfg_get_first_child(configHandle, applyListNode);
      if (child < 0) break;

      stuffToApply = true;

   } while (false);

   if (configHandle > 0) {
      _xmlcfg_close(configHandle);
   }
   return stuffToApply;
}

static void hotfixApplyAutoFoundHotfixes(bool automatic)
{
   // open the hotfix config file
   configHandle := hotfixOpenAutoConfigFile();
   if (configHandle < 0) {
      return;
   }

   // find our list of hotfixes to apply
   applyListNode := _xmlcfg_find_simple(configHandle, "/HotfixesToApply");
   if (applyListNode < 0) {
      // we don't have a list, call it quits
      _xmlcfg_close(configHandle);
      return;
   }

   // get the files we want
   HotfixInfo fixes[];
   hotfixGetFilesToApply(configHandle, applyListNode, fixes);

   result := IDOK;
   if (!automatic) {
      if (fixes._length() == 1) {
         // show the prompt for just this file
         HotfixInfo fix = fixes[0];

         result = hotfixShowInfo(fix, HPFP_AUTO_PROMPT);
      } else if (fixes._length() > 1) {
         // show the multi-file prompt
         result = show('-modal  -xy -wh _hotfix_autofind_prompt_form', fixes);
      }
   } 

   // just apply these all in order
   appliedSomething := false;
   needRestart := false;

   if (result == IDOK) {
   
      handledListNode := _xmlcfg_find_simple(configHandle, "HandledHotFixes");
      if (handledListNode < 0) {
         // create it then
         handledListNode = _xmlcfg_add(configHandle, 0, "HandledHotFixes",  
                     VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         
      }
   
      // progress form showing how far we have to go
      progressWid := 0;
      if (result == IDOK) {
         progressWid = _mdi.show_cancel_form("Applying updates installed by your system administrator", 'Applying 'fixes[0].ZipFile'...', false, true);
         progressWid.refresh();
      }
   
      for (i := 0; i < fixes._length(); i++) {
   
         if (fixes[i] != null) {

            // update the progress bar
            if (progressWid && !cancel_form_cancelled()) {
               if (cancel_form_progress(progressWid, i, fixes._length())) {
                  cancel_form_set_labels(progressWid, 'Applying 'fixes[i].ZipFile'...');
               }
            }

            // load up our file
            status := hotfixLoadByManifest(fixes[i].ZipFile, fixes[i].ManifestHandle, fixes[i].Restart, true, false);
            if (!status) {
               appliedSomething = true;
               needRestart = needRestart || fixes[i].Restart;

               // we handled this bad boy
               hotfixMarkFileAsHandled(configHandle, handledListNode, fixes[i].ZipFile, fixes[i].ManifestHandle);
            }
   
            // close up the manifest, we are done with it
            _xmlcfg_close(fixes[i].ManifestHandle);
            _ZipClose(fixes[i].ZipFile);
         }
      }
   
      if (progressWid) {
         cancel_form_progress(progressWid, 1, 1);
         close_cancel_form(progressWid);
      }
   
      // clear our the applied list
      _xmlcfg_delete(configHandle, applyListNode, true);

      // save our xml file
      _xmlcfg_save(configHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);

   } else {

      // clean up zip files and configurations we opened earlier
      for (i := 0; i < fixes._length(); i++) {
         if (fixes[i] != null) {
            _xmlcfg_close(fixes[i].ManifestHandle);
            _ZipClose(fixes[i].ZipFile);
         }
      }
   }

   _xmlcfg_close(configHandle);

   if (!automatic) {
      // need a restart?
      if (needRestart) {
         hotfixCheckRestart(needRestart);
      } else {
         // prompt user to save configuration
         if (appliedSomething) {
            gui_save_config();
         }
      }
   }
}

static _str hotfixGetAutoConfigFile()
{
   return hotfixGetHotfixesDirectory() :+ "autoHotfix.xml";
}

static int hotfixOpenAutoConfigFile()
{
   // open the file where we put these things
   configFile := hotfixGetAutoConfigFile();
   return _xmlcfg_open(configFile, auto status);
}

static void hotfixGetFilesToApply(int configHandle, int applyListNode, HotfixInfo (&fixes)[])
{
   _str fix_list[];

   // go through all the children in the apply list
   child := _xmlcfg_get_first_child(configHandle, applyListNode);
   while (child > 0) {
      // get the file name
      HotfixInfo info;
      info.ZipFile = _xmlcfg_get_attribute(configHandle, child, "Name");

      // make sure we can load this thing up
      if (!hotfixGetAutoFixInfo(info, fix_list)) {
         fixes :+= info;
         fix_list :+= hotfixGetInfoStr(info.ZipFile, HIF_SERIES | HIF_REVISION);
      }

      child = _xmlcfg_get_next_sibling(configHandle, child);
   }
}

int hotfixGetAutoFixInfo(HotfixInfo &info, _str (&fix_list)[])
{
   // make sure they haven't already applied this hot fix
   status := hotfixCheckIfApplied(info.ZipFile, true);
   if (status) {
      return status;
   }

   // make sure that the zip file has a manifest
   manifest_handle := hotfixOpenManifest(info.ZipFile);
   if (manifest_handle < 0) {
      return manifest_handle;
   }

   // check the version number
   compatibleVersions := "";
   fix_version := hotfixGetVersion(manifest_handle, &compatibleVersions);
   status = hotfixCheckVersion(fix_version, compatibleVersions, true);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(info.ZipFile);
      return status;
   }

   // check the hotfix requirements
   fix_requires := hotfixGetRequirements(manifest_handle, auto fix_requires_names);
   status = hotfixCheckRequirements(fix_requires, fix_requires_names, fix_list, true);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(info.ZipFile);
      return status;
   }

   // check if the hot fix affects system files
   status = hotfixGetFiles(manifest_handle, info.Files, info.SystemFiles);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      _ZipClose(info.ZipFile);
      return status;
   }

   // match this hotfix against already loaded ones
   info.LoadedRevision = "";
   foreach (auto loaded_fix in fix_list) {
      parse loaded_fix with auto file "\t" auto revision;
      if (_file_eq(file, _strip_filename(info.ZipFile,'pe'))) {
         info.LoadedRevision = revision;
      }
   }

   info.ManifestHandle = manifest_handle;
   info.Restart = hotfixGetRestart(manifest_handle);

   return 0;
}

static void hotfixMarkFileAsHandled(int configHandle, int handledListNode, _str zipFile, int manifestHandle)
{
   // create a node under our list of handled nodes
   node := _xmlcfg_add(configHandle, handledListNode, "Hotfix", 
                       VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

   // file name
   _xmlcfg_add_attribute(configHandle, node, "Name", zipFile);

   // fix date
   _xmlcfg_add_attribute(configHandle, node, "FileDate", _file_date(zipFile, 'B'));

   // series
   _xmlcfg_add_attribute(configHandle, node, "Series", hotfixGetSeries(manifestHandle));

   // revision
   _xmlcfg_add_attribute(configHandle, node, "Revision", hotfixGetRevision(manifestHandle));
}

enum HotfixPromptFormPurpose {
   HPFP_INFO,
   HPFP_AUTO_PROMPT,
   HPFP_MANUAL_PROMPT,
}

defeventtab _hotfix_autofind_prompt_form;

static HotfixInfo FIX_LIST(...)[] {
   if (arg()) _ctl_apply.p_user=arg(1);
   return _ctl_apply.p_user;
}

void _ctl_apply.on_create(HotfixInfo (&fixes)[], int purpose = 0)
{
   // how many hotfixes do we have?
   FIX_LIST(fixes);
   if (fixes._length() == 1) {
      showPromptForOneHotfix(fixes[0], purpose);
   } else {
      showPromptForMultipleHotfixes(fixes);
   }
}

void _hotfix_autofind_prompt_form.on_resize()
{
   client_width  := _dx2lx(SM_TWIP,p_client_width);
   client_height := _dy2ly(SM_TWIP,p_client_height);

   xbuffer := _ctl_text.p_x;
   ybuffer := _ctl_text.p_y;

   // adjust all widths and horizontal positioning
   _ctl_text.p_width = client_width - 2*xbuffer;
   _ctl_list.p_width = client_width - 2*xbuffer;
   _ctl_info.p_width = client_width - 2*xbuffer;
   _ctl_divider.p_width = client_width - 2*xbuffer;

   _ctl_ask_later.p_x = client_width - _ctl_ask_later.p_width - xbuffer;
   _ctl_apply.p_x     = _ctl_ask_later.p_x - _ctl_apply.p_width - 2*xbuffer;

   // all vertical positioning
   if (!_ctl_text.p_visible) {
      _ctl_info.p_y = 0;
   }

   _ctl_ask_later.p_y = client_height - _ctl_ask_later.p_height - ybuffer;
   _ctl_apply.p_y = _ctl_ask_later.p_y;

   _ctl_divider.p_y = _ctl_ask_later.p_y - ybuffer - _ctl_divider.p_height;
   _ctl_info.p_height = _ctl_divider.p_y - _ctl_info.p_y;
}

void _ctl_list.on_change(int reason, int index=0)
{
   if (reason == CHANGE_SELECTED) {

      // get the selected tree item
      index = _ctl_list._TreeCurIndex();
      index = _ctl_list._TreeGetUserInfo(index);

      // now we have the index in our list of fixes
      fix := ((HotfixInfo)FIX_LIST()[index]);

      have_revs   := false;
      description := hotfixGetDescription(fix.ManifestHandle);
      fixes := hotfixGetFixDescriptions(fix.ManifestHandle, have_revs, fix.LoadedRevision);
      _ctl_info._minihtml_UseDialogFont();
      _ctl_info.p_backcolor = 0x80000022;
      _ctl_info.p_text = hotfixGetDisplayMsg(fix, description, fixes, have_revs, HPFP_INFO);
   }
}

static void showPromptForOneHotfix(HotfixInfo fix, int purpose)
{
   padding := _ctl_text.p_y;

   // some things are not visible in this mode
   _ctl_text.p_visible = _ctl_list.p_visible = false;
   _ctl_info.p_height += (_ctl_info.p_y - _ctl_text.p_y);
   _ctl_info.p_y = _ctl_text.p_y;

   have_revs   := false;
   description := hotfixGetDescription(fix.ManifestHandle);
   fixes := hotfixGetFixDescriptions(fix.ManifestHandle, have_revs, fix.LoadedRevision);
   _ctl_info._minihtml_UseDialogFont();
   _ctl_info.p_backcolor = 0x80000022;
   _ctl_info.p_text = hotfixGetDisplayMsg(fix, description, fixes, have_revs, purpose);

   // resize the html control
   origHeight := _ctl_info.p_height;
   origWidth := _ctl_info.p_width;

   _ctl_info.p_height *= 10;
   _ctl_info._minihtml_ShrinkToFit(_ctl_info.p_width);
   if (_ctl_info.p_height > origHeight) {
      _ctl_info.p_height = origHeight;
      _ctl_info.p_width = origWidth;
   }

   switch (purpose) {
   case HPFP_INFO:
      _ctl_text.p_visible = false;

      _ctl_apply.p_caption = 'OK';
      _ctl_apply.p_x = _ctl_ask_later.p_x;

      _ctl_ask_later.p_visible = false;
      break;
   case HPFP_MANUAL_PROMPT:
      _ctl_text.p_visible = false;

      _ctl_apply.p_caption = "&Apply hot fix";
      _ctl_ask_later.p_caption = "Cancel";
      _ctl_ask_later.p_cancel = true;
      break;
   }
}

static void showPromptForMultipleHotfixes(HotfixInfo (&fixes)[])
{
   _ctl_text.p_caption = 'Your system administrator has installed new updates that need to be applied.';

   // set up our tree
   width := _ctl_list.p_width intdiv 2;
   _ctl_list._TreeSetColButtonInfo(0, width, TREE_BUTTON_PUSHBUTTON, -1, "File");
   _ctl_list._TreeSetColButtonInfo(1, width, TREE_BUTTON_PUSHBUTTON, -1, "Path");

   // populate our list
   for (i := 0; i < fixes._length(); i++) {
      file := fixes[i].ZipFile;
      text := _strip_filename(file, 'P') :+ \t :+ _strip_filename(file, 'N');
      _ctl_list._TreeAddItem(TREE_ROOT_INDEX, text, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, i);
   }

   _ctl_apply.p_caption = "&Apply all hot fixes";
}

void _ctl_apply.lbutton_up()
{
   p_active_form._delete_window(IDOK);
}

void _ctl_ask_later.lbutton_up()
{
   p_active_form._delete_window(IDCANCEL);

}
