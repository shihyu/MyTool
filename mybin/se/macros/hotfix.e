////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47140 $
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
#import "saveload.e"
#import "sellist.e"
#import "seltree.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbview.e"
#import "toast.e"
#import "vc.e"
#import "window.e"
#require "se/datetime/DateTime.e"

using se.datetime.DateTime;

//////////////////////////////////////////////////////////////////////
// Begin Update Manager Hotfix loading code
//////////////////////////////////////////////////////////////////////

#define HOTFIX_HOTFIX_MANIFEST_XML "hotfix.xml"
#define ZIP_EXE_NAME "zip"

enum_flags HotfixInfoFlags {
   HIF_FILENAME,
   HIF_SERIES,
   HIF_REVISION,
   HIF_FIX_DATE,
   HIF_DESCRIPTION,
   HIF_FIXES,
};

struct HotfixInfo {
   _str ZipFile;
   int ManifestHandle;
   boolean Restart;
   _str Files[];
   _str SystemFiles[];
};

static _str hotfixGetZipFile(_str zipfile="")
{
   // already specified on command line?
   if (zipfile!="" && file_exists(zipfile)) {
      return zipfile;
   }

   // prompte user for zip file
   _str format_list='Zip Files(*.zip),All Files('ALLFILES_RE')';
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
   _str manifest_path = zipfile;
   _maybe_append_filesep(manifest_path);
   manifest_path = manifest_path:+HOTFIX_HOTFIX_MANIFEST_XML;

   // make sure the manifest exists
   if (!file_exists(manifest_path)) {
      return FILE_NOT_FOUND_RC;
   }

   // now open it as an xml config file
   int status=0;
   int handle = _xmlcfg_open(manifest_path,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (status < 0) return status;
   return handle;
}

static _str hotfixGetVersion(int handle, _str *compatibleVersions=null)
{
   // find the hotfix element
   int node = _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the compatible versions for this hot fix
   if (compatibleVersions != null) {
      *compatibleVersions = _xmlcfg_get_attribute(handle, node, "CompatibleVersions");
   }

   // look up the version attribute and compare to the editor version
   _str fix_version = _xmlcfg_get_attribute(handle, node, "Version");
   return fix_version;
}

static _str hotfixGetSeries(int handle)
{
   // find the hotfix element
   int node = _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the version attribute and compare to the editor version
   _str series = _xmlcfg_get_attribute(handle, node, "Series");

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
   int node = _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the version attribute and compare to the editor version
   _str rev = _xmlcfg_get_attribute(handle, node, "Revision", 1);
   return rev;
}

static _str hotfixGetRequirements(int handle, _str &requiredNames)
{
   // find the hotfix element
   int node = _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the version attribute and compare to the editor version
   _str rev = _xmlcfg_get_attribute(handle, node, "Requires", "");
   requiredNames = _xmlcfg_get_attribute(handle, node, "RequiresDisplay", "");
   return rev;
}

static _str hotfixGetDate(int handle)
{
   // find the hotfix element
   int node = _xmlcfg_find_simple(handle, "/HotFix");
   if (node < 0) {
      _message_box("Invalid hot fix manifest file");
      return node;
   }

   // look up the version attribute and compare to the editor version
   _str fixDate = _xmlcfg_get_attribute(handle, node, "Date");
   return fixDate;
}

static boolean hotfixGetRestart(int &handle)
{
   // find the hotfix element
   int node = _xmlcfg_find_simple(handle, "/HotFix");
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
   int node = _xmlcfg_find_simple(handle, "/HotFix/Description");
   if (node < 0) {
      return 0;
   }

   // the text is PCDATA
   _str description = "";
   int text_node = _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_PCDATA);
   if (text_node > 0) {
      description = _xmlcfg_get_value(handle, text_node);
   }
   description=stranslate(description, " ", "[\t\n\r]",'r');

   // replace the hot fix revision number in description
   if (pos("&revision;", description)) {
      _str revNumber = hotfixGetRevision(handle);
      if (revNumber == '') revNumber=1;
      description=stranslate(description, revNumber, "&revision;");
   }
   // replace the hot fix version number in description
   if (pos("&version;", description)) {
      _str verNumber = hotfixGetVersion(handle);
      if (verNumber == '') verNumber="<unknown>";
      description=stranslate(description, verNumber, "&version;");
   }

   // that's all folks
   return description;
}

static _str hotfixGetFixDescriptions(int handle)
{
   // the text is PCDATA
   description := "";

   // now get the individual defect descriptions
   typeless defects[];
   status := _xmlcfg_find_simple_array(handle, "/HotFix/Defect", defects);
   if (defects._length() > 0) {
      description :+= "<ul>";
      foreach (auto node in defects) {
         modules := _xmlcfg_get_attribute(handle, node, "Modules");
         ids     := _xmlcfg_get_attribute(handle, node, "Ids");
         if (modules=='') modules="general fix";
         description :+= "<li><font color=\"darkred\">":+modules:+"</font> -- ";
         text_node := _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_PCDATA);
         if (text_node > 0) {
            _str defect_info = _xmlcfg_get_value(handle, text_node);
            description :+= stranslate(defect_info, " ", "[\t\n\r]",'r'); 
         }
         description :+= "</li>";
      }
      description :+= "</ul>";
   }

   // that's all folks
   return description;
}

static int hotfixGetFiles(int handle, 
                          _str (&files)[], 
                          _str (&system_files)[], 
                          _str (&readonly_files)[])
{
   // Find the Contents group
   int node = _xmlcfg_find_simple(handle, "/HotFix/Contents");
   if (node < 0) {
      _message_box("Hot fix has no contents!");
      return STRING_NOT_FOUND_RC;
   }

   // files are relative to the installation or config directory
   _str root_dir=get_env('VSROOT');
   _maybe_append_filesep(root_dir);
   _str config_dir=_ConfigPath();

   // go through each tag under "Contents"
   int status=0;
   int child = _xmlcfg_get_first_child(handle, node);
   while (child >= 0) {

      _str dest = "";
      _str name = "";
      _str arch = "";
      _str item = _xmlcfg_get_name(handle, child);
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
         files[files._length()] = dest;
         system_files[system_files._length()] = dest;
         if (!_FileIsWritable(root_dir:+dest)) {
            readonly_files[readonly_files._length()] = dest;
            status = ACCESS_DENIED_RC;
         }
         break;
      case "Config":   
         // file to be copied to configuration directory
         name=_xmlcfg_get_attribute(handle, child, "Name");
         dest=_xmlcfg_get_attribute(handle, child, "Path");
         dest = stranslate(dest, FILESEP, FILESEP2);
         if (dest=="") dest=name;
         files[files._length()] = dest;
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
         files[files._length()] = "win" :+ FILESEP :+ name;
         system_files[system_files._length()] = "win" :+ FILESEP :+ name;
         // check listvtg.exe, because the actual DLL 
         // will be RO because it is in use
         if (!_FileIsWritable(root_dir:+"win":+FILESEP:+"listvtg.exe")) {
            readonly_files[readonly_files._length()] = "win" :+ FILESEP :+ name;
            status = ACCESS_DENIED_RC;
         }
         break;
      case "Module": 
         // Slick-C module to load (on a per-user basis)
         name=_xmlcfg_get_attribute(handle, child, "Name");
         name = stranslate(name, FILESEP, FILESEP2);
         files[files._length()] = "macros" :+ FILESEP :+ name;
         break;
      case "ZipFile": 
         // Nested hotfix to apply
         name=_xmlcfg_get_attribute(handle, child, "Name");
         files[files._length()] = "hotfixes" :+ FILESEP :+ name;
         break;
      case "Sysconfig": 
         // system config file to be copied to the hotfixes dir
         name=_xmlcfg_get_attribute(handle, child, "Name");
         name = stranslate(name, FILESEP, FILESEP2);
         files[files._length()] = "sysconfig" :+ FILESEP :+ name;
         break;
      }

      // next please
      child = _xmlcfg_get_next_sibling(handle, child);
   }

   // that's all folks
   return status;
}

static int hotfixCheckVersion(_str fix_version, _str compatibleVersions)
{
   // look up the version attribute and compare to the editor version
   _str editor_version = _version();
   if (fix_version != editor_version && !pos(' 'editor_version' ', ' 'compatibleVersions' ')) {
      _message_box("Invalid version:  the selected hot fix is for SlickEdit "fix_version".  You are currently running "editor_version".");
      return COMMAND_CANCELLED_RC;
   }

   // success
   return 0;
}

static int hotfixCheckRequirements(_str fix_requires, _str requires_display_names, _str (&fix_list)[] = null, boolean quiet = false)
{
   // get the list of installed fixes
   int status = hotfixFindAll("", fix_list, HIF_SERIES | HIF_REVISION);
   
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
         if (file_eq(_strip_filename(fix, 'P'), fix_series)) {
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
   int status = show('-new -modal _hotfix_autofind_prompt_form', list, reason);

   return status;
}

_str hotfixGetDisplayMsg(HotfixInfo &info, _str description, _str fixes, int reason) 
{
   // create an HTML bullet list of files
   _str file_list="<ul>";
   int i,n = info.Files._length();
   for (i=0; i<n; ++i) {
      file_list = file_list:+"<li>":+info.Files[i];
   }
   file_list=file_list:+"</ul>";

   // prepend warning if this fix modifies system files
   _str systemFilesWarning="";
   if (info.SystemFiles._length() > 0) {

      // create an HTML bullet list of system files
      _str system_list="<ul>";
      for (i=0; i<info.SystemFiles._length(); ++i) {
         system_list = system_list:+"<li>":+info.SystemFiles[i];
      }
      system_list=system_list:+"</ul>";

      // put together the larg warning in HTML
      systemFilesWarning = "<b>WARNING</b>:<br> " :+
                           "This hot fix modifies files under your SlickEdit installation directory. ":+
                           "You must have write access to these files for the fix to install successfully. ";
      systemFilesWarning = systemFilesWarning :+ system_list;

      // add warning about multi-user installations
      if( _getSerial()!="" && !_trial() && _FlexlmNofusers()>1 ) {
         systemFilesWarning = systemFilesWarning :+ "<p><b>WE DO NOT RECOMMEND APPLYING THIS FIX FOR A MULTI-USER INSTALLATION.</b>";
      }
   }

   // add message about restart being required
   restartWarning := '';
   if (info.Restart) {
      restartWarning = "<p><b><font color=brown>This hot fix will require you to close and restart SlickEdit.</font></b>";
   }

   // add list of fixes if there were any
   if (fixes != '') {
      fixes = "<p><b>Fixes:</b><br>" :+ fixes;
   }

   filename := _strip_filename(info.ZipFile, 'P');

   msg := '';
   if (reason == HPFP_AUTO_PROMPT) {
      msg = '<p>Your system administrator has installed a new update that needs to be applied.<br><br>';
   }

   // put together HTML message
   msg :+= "<p><b>Name: </b>" :+ filename :+
         "<br>" :+
         systemFilesWarning :+
         "<p><b>Inventory:</b><br>" :+
         "This fix includes the following files:" :+
         file_list :+ 
         "<p><b>Description:</b><br>" :+
         description :+ fixes :+ restartWarning;

   if (reason == HPFP_MANUAL_PROMPT) {
      msg :+= "<p><b>Continue and apply fix?</b>";
   }

   return msg;                             
}

_str hotfixGetHotfixesDirectory()
{
   return _ConfigPath() :+ "hotfixes" :+ FILESEP;
}

static int hotfixCheckIfApplied(_str zipfile, boolean quiet)
{
   // get path to hotfixes under config directory
   path := hotfixGetHotfixesDirectory();

   // check if this fix has already been applied
   _str name = _strip_filename(zipfile, 'p');
   path = path :+ FILESEP :+ name;
   if (file_exists(path)) {

      // get revision of new zipfile
      _str revision1 = "";
      int handle = hotfixOpenManifest(zipfile);
      if (handle >= 0) {
         revision1 = hotfixGetRevision(handle);
         _xmlcfg_close(handle);
      }

      // get revision of saved zipfile
      _str revision2 = "";
      handle = hotfixOpenManifest(path);
      if (handle >= 0) {
         revision2 = hotfixGetRevision(handle);
         _xmlcfg_close(handle);
      }

      // if not a newer version, warn them
      if (revision1 <= revision2) {
         if (quiet) return IDNO;
         int status = _message_box("Hotfix \"" :+ name :+ "\" has already been applied.  Continue anyway?", "SlickEdit", MB_YESNO|MB_ICONQUESTION);
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
   save_config();
   safe_exit();
}

static void hotfixCheckRestart(boolean doRestart)
{
   if (doRestart) {
      int status = _message_box("This fix requires you to close and restart SlickEdit.  Close SlickEdit now?", "SlickEdit", MB_YESNO|MB_ICONQUESTION);
      if (status == IDYES) {
         _post_call(hotfixDoRestart);
      }
   }
}

static int hotfixCopyFile(_str zipfile, _str name, _str dest, _str backupExt="")
{
   // make sure the dest file doesn't already exist
   _str line="";
   int status=0;
   if (file_exists(dest)) {
      if (backupExt=="") {
         backupExt = stranslate(_version(), '_', ' ');
      }
      if (!file_exists(dest'.'backupExt)) {
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
   _str src = zipfile :+ FILESEP :+ name;
   status = copy_file(src, dest);
   if (status < 0) {
      line = "*** Could not copy to file: " :+ dest :+ " -- " :+ get_message(status);
      hotfixLogAction(line);
   }

#if __UNIX__
   // check that we have access to the new file
   int temp_wid=0, orig_wid=0;
   status = _open_temp_view(dest, temp_wid, orig_wid);
   if (status < 0) {
      _chmod("u+rw,g+rw,o+r " maybe_quote_filename(dest));
   } else {
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
   }
#endif

   // that's all folks
   return status;
}

static int hotfixRestoreBackup(_str dest, _str backupExt="", boolean failIfNoBackup=true)
{
   if (backupExt=="") {
      backupExt = stranslate(_version(), '_', ' ');
   }

   _str line="";
   int status=0;
   _str backupFile = dest"."backupExt;
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

static int hotfixApplyFile(int handle, int node, _str zipfile, boolean doRestore, boolean quiet)
{
   // check the architecture of the DLL
   _str arch=_xmlcfg_get_attribute(handle, node, "Arch");
   if (arch != null && arch != "" && machine():+machine_bits() != arch) {
      return VSUPDATE_INCORRECT_ARCHITECTURE_RC;
   }

   // get the name and destination path
   _str name=_xmlcfg_get_attribute(handle, node, "Name");
   _str dest=_xmlcfg_get_attribute(handle, node, "Path");
   dest = stranslate(dest, FILESEP, FILESEP2);
   if (dest=="") dest=name;

   // files go to installation directory
   _str root_dir=get_env('VSROOT');
   _maybe_append_filesep(root_dir);
   dest = root_dir :+ dest;

   // tell them about it and copy the file
   if (doRestore) {
      _str line = "Restoring file: " :+ dest;
      hotfixLogAction(line);
      int status = hotfixRestoreBackup(dest);
      if (status) {
         return status;
      }
   } else {
      _str line = "Replacing file: " :+ dest;
      hotfixLogAction(line);
      int status = hotfixCopyFile(zipfile,name,dest);
      if (status) {
         return status;
      }
   }

   // that's all folks
   return 0;
}
static int hotfixApplyConfig(int handle, int node, _str zipfile, boolean doRestore, boolean quiet)
{
   // get the name and destination path
   _str name=_xmlcfg_get_attribute(handle, node, "Name");
   _str dest=_xmlcfg_get_attribute(handle, node, "Path");
   dest = stranslate(dest, FILESEP, FILESEP2);
   if (dest=="") dest=name;

   // files go to installation directory
   _str config_dir=_ConfigPath();
   dest = config_dir :+ dest;

   // tell them about it and copy the file
   if (doRestore) {
      _str line = "Restoring file: " :+ dest;
      hotfixLogAction(line);
      int status = hotfixRestoreBackup(dest);
      if (status) {
         return status;
      }

   } else {
      _str line = "Replacing file: " :+ dest;
      hotfixLogAction(line);
      int status = hotfixCopyFile(zipfile,name,dest);
      if (status) {
         return status;
      }
   }

   // that's all folks
   return 0;
}

static int hotfixApplySysconfig(int handle, int node, _str zipfile, boolean doRestore, boolean quiet)
{
   // get the source path
   _str name=_xmlcfg_get_attribute(handle, node, "Name");

   // just get the file name here
   name = _strip_filename(name, 'P');

   // files go to the hotfix directory
   dest := hotfixGetHotfixesDirectory() :+ name;

   // tell them about it and copy the file
   if (doRestore) {
      _str line = "Restoring file: " :+ dest;
      hotfixLogAction(line);
      int status = hotfixRestoreBackup(dest, '', false);
      if (status) {
         return status;
      }
   } else {
      _str line = "Replacing file: " :+ dest;
      hotfixLogAction(line);
      int status = hotfixCopyFile(zipfile,name,dest);
      if (status) {
         return status;
      }
   }

   // that's all folks
   return 0;
}
static _str hotfixGetModuleRevision(_str path)
{
   // open the source file in a temp view
   _str revision="";
   int temp_wid=0, orig_wid=0;
   int status = _open_temp_view(path, temp_wid, orig_wid);
   if (status) {
      return status;
   }
   // look for the revision header
   top();
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   status = search("$Revision:",'@eh');
   restore_search(s1,s2,s3,s4,s5);
   if (!status && p_line < 4) {
      _str line="";
      get_line(line);
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
   int temp_wid=0, orig_wid=0;
   int status = _open_temp_view(path, temp_wid, orig_wid);
   if (status) {
      return status;
   }

   // go to the bottom of the file and check offset
   bottom();_end_line();
   int size = (int)_QROffset();
   
   // finished, clean up
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);
   return size;
}
static boolean hotfixCheckForDefmain(_str path)
{
   // the defmain check does not apply to main.e
   if (_strip_filename(path, "P") == "main.e") {
      return false;
   }

   // open the source file in a temp view
   _str revision="";
   int temp_wid=0, orig_wid=0;
   int status = _open_temp_view(path, temp_wid, orig_wid, '+d');
   if (status) {
      return false;
   }

   // look for the defmain function
   _SetEditorLanguage('e');
   //DJB 01-03-2007 -- push/pop context is obsolete
   //tag_push_context();
   _UpdateContext(true);
   boolean hasDefmain = (tag_find_context_iterator("defmain",true,true) > 0);

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
static int hotfixMakeNload(_str module, boolean doLoad=true)
{
   message(nls('Loading:')' 'module);
   if ( pos(' ',module) ) module='"'module'"';
   status := _make(module);
   if (status) {
      line := "Error compiling module: ":+module:+".  "get_message(status);
      _message_box(line);
      hotfixLogAction(line);
      return status;
   }
   if (!doLoad) return(0);
   // Load needed a global variable since, defload and definit are executed
   // after the _load opcode completes.  We could change this if defload
   // and definit executed immediately.
   _loadrc= 0;
   _load(module,'r');
   status = _loadrc;
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
static int hotfixApplyModule(int handle, int node, _str zipfile, boolean doRestore, boolean quiet)
{
   // get name of module to apply
   int status=0;
   _str name=_xmlcfg_get_attribute(handle, node, "Name");
   typeless doLoad=_xmlcfg_get_attribute(handle, node, "Load", 1);
   typeless doRun =_xmlcfg_get_attribute(handle, node, "Run",  0);

   // standardize the path separators
   name = stranslate(name, FILESEP, FILESEP2);
   _str namePath = _strip_filename(name, "N");
   _str nameFile = _strip_filename(name, "P");

   // will copy file into configuration directory / hotfixes
   _str dest=hotfixGetHotfixesDirectory();
   chdir(dest,1);
   dest = dest :+ nameFile;

   // handle restore 
   _str line="";
   if (doRestore) {
      // remove file and .ex from hotfixes directory
      if (file_exists(dest))       delete_file(dest);
      if (file_exists(dest'x'))    delete_file(dest'x');
      if (file_exists(dest".bak")) {
         _file_move(dest, dest".bak");
      }

      // will copy file into configuration directory / hotfixes
      dest=get_env('VSROOT');
      _maybe_append_filesep(dest);
      dest = dest :+ "macros" :+ FILESEP :+ name;
      new_dest := file_match("-T ":+maybe_quote_filename(dest), 1);
      if (new_dest != "") dest = new_dest;

      // log the action
      line = "Restoring module: " :+ dest;
      hotfixLogAction(line);
   }

   // execute batch macro?
   if (doRun) {
      line = "Run batch program: " :+ dest;
      hotfixLogAction(line);
      if (doRestore) {
         line = "*** Can not undo effects of batch macro: " :+ dest;
         hotfixLogAction(line);
         return 0;
      } else {
         return execute(maybe_quote_filename(dest));
      }
   } 

   // check if the module has a defmain and thus can't be loaded
   if (doLoad && file_exists(dest) && hotfixCheckForDefmain(dest)) {
      line = "Can not load module containing defmain(): " :+ dest;
      hotfixLogAction(line);
      doLoad=false;
   }

   // load module?
   if (doLoad) {
      if (doRestore && !file_exists(dest)) {
         line = "Module not found: " :+ dest;
         hotfixLogAction(line);

      } else {
         line = "Loading module: " :+ dest;
         hotfixLogAction(line);
   
         if (doRestore) {
            //unload(name'x');
         } else {
            if (file_exists(dest:+'x')) {
               delete_file(dest:+'x');
            }
         }

         // for macros in namespace directories, they might import
         // other modules in their namespace using a relative path
         // work around this by prepending the namespace directory
         // to the macros path search.
         searchPath := get_env("VSLICKINCLUDE");
         if (namePath != '') {
            namespaceDir := get_env('VSROOT') :+ "macros" :+ FILESEP :+ namePath;
            set_env("VSLICKINCLUDE", namespaceDir :+ PATHSEP :+ searchPath);
         }

         // compile and load the module
         status = hotfixMakeNload(dest);
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

static int hotfixCopyModule(int handle, int node, _str zipfile, boolean quiet)
{
   // get name of module to apply
   int status=0;
   _str name=_xmlcfg_get_attribute(handle, node, "Name");

   // standardize the path separators
   name = stranslate(name, FILESEP, FILESEP2);
   _str namePath = _strip_filename(name, "N");
   _str nameFile = _strip_filename(name, "P");

   // will copy file into configuration directory / hotfixes
   _str dest=hotfixGetHotfixesDirectory() :+ nameFile;

   // check that the revision numbers are same or increasing
   // prompt if replacement module is older revision
   if (file_exists(dest)) {
      _str new_rev = hotfixGetModuleRevision(zipfile:+FILESEP:+nameFile);
      _str old_rev = hotfixGetModuleRevision(dest);
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
   _str line = "Copying module to: " :+ dest;
   hotfixLogAction(line);
   status = hotfixCopyFile(zipfile,nameFile,dest,"bak");
   if (status) {
      return status;
   }

   // that's all folks
   return 0;
}

// SlickEdit DLL interdependencies
static _str hotfixDLLDependencies:[] = {
   "tagsdb.dll" => "vsdebug.dll;cparse.dll",
   "vsscc.dll" => "vsvcs.dll",
};

static int hotfixApplyDLL(int handle, int node, _str zipfile, boolean doRestore, boolean quiet)
{
   // check the architecture of the DLL
   _str arch=_xmlcfg_get_attribute(handle, node, "Arch");
   if (arch != null && arch != "" && machine():+machine_bits() != arch) {
      return VSUPDATE_INCORRECT_ARCHITECTURE_RC;
   }

   // get the name of the DLL
   _str name=_xmlcfg_get_attribute(handle, node, "Name");

   // compute destination file name
   _str root_dir=get_env('VSROOT');
   _maybe_append_filesep(root_dir);
   _str dest = root_dir :+ "win" :+ FILESEP :+ name;

   // look up dependencies on other DLL's
   _str dependencies = "";
   if (hotfixDLLDependencies._indexin(name)) {
      dependencies = hotfixDLLDependencies:[name];
   }

   // unload all the DLL's that depend on us
   int status = 0;
   _str line = "";
   _str temp = dependencies;
   while (temp != "") {
      _str dep_dll;
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
      status = hotfixCopyFile(zipfile,name,dest);
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
      _str dep_dll;
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

static int hotfixApplyCommand(int handle, int node, _str zipfile, boolean doRestore, boolean quiet)
{
   // get the command and run it
   _str cmd=_xmlcfg_get_attribute(handle, node, "Exec");
   _str line = "Run command: " :+ cmd;
   hotfixLogAction(line);
   if (doRestore) {
      line = "*** Can not undo effects of command: " :+ cmd;
      hotfixLogAction(line);
      return 0;
   }
   return execute(cmd);
}

static int hotfixApplyZipFile(int handle, int node, _str zipfile, 
                              boolean &restart, boolean doRestore, boolean quiet)
{
   // get the name and destination path
   _str name=_xmlcfg_get_attribute(handle, node, "Name");

   // create path to copy zip file to
   _str inner_zipfile = zipfile :+ FILESEP :+ name;

   // get path to hotfixes under config directory
   _str dest = hotfixGetHotfixesDirectory() :+ name;

   // copy the zip file into the hotfixes directory
   int status = copy_file(inner_zipfile, dest);
   if (status < 0) {
      return status;
   }

   // show that we are recursively expanding hot fixes
   hotfixLogAction("--------------------------------------------------");

   // tell them about it and copy the file
   if (doRestore) {
      _str line = "Unloading fixes from zip file: " :+ name;
      hotfixLogAction(line);
      hotfixUnload(dest, restart, true);
   } else {
      _str line = "Applying fixes from zip file: " :+ name;
      hotfixLogAction(line);
      hotfixLoad(dest, restart, true);
   }

   // show that we are done with recursion
   hotfixLogAction("--------------------------------------------------");

   // that's all folks
   return 0;
}

static int hotfixCopyZipFile(_str zipfile, int manifest_handle)
{
   // get path to hotfixes under config directory
   _str hotfixDir=hotfixGetHotfixesDirectory();

   // make directory if it doesn't exist already
   int status=0;
   if (!isdirectory(hotfixDir)) {
      status = make_path(hotfixDir);
      if (status) {
         _message_box("Could not make directory: " :+ hotfixDir);
         return status;
      }
   }

   // check and see if they are using a hotfix in the hotfix directory
   _str name = _strip_filename(zipfile, 'p');
   dest := hotfixDir :+ name;
   if (file_eq(dest, zipfile)) {
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

static int hotfixCopyModules(int handle, _str zipfile, boolean quiet)
{
   int node = _xmlcfg_find_simple(handle, "/HotFix/Contents");
   if (node < 0) {
      if (!quiet) {
         _message_box("Hot fix has no contents!");
      }
      return STRING_NOT_FOUND_RC;
   }

   int child = _xmlcfg_get_first_child(handle, node);
   if (child < 0) {
      if (!quiet) {
         _message_box("Hot fix has no contents!");
      }
      return STRING_NOT_FOUND_RC;
   }

   int status,result = 0;
   while (child >= 0) {

      _str item = _xmlcfg_get_name(handle, child);
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
                       boolean &restart, boolean doRestore, boolean quiet)
{
   int node = _xmlcfg_find_simple(handle, "/HotFix/Contents");
   if (node < 0) {
      if (!quiet) {
         _message_box("Hot fix has no contents!");
      }
      return STRING_NOT_FOUND_RC;
   }

   int child = _xmlcfg_get_first_child(handle, node);
   if (child < 0) {
      if (!quiet) {
         _message_box("Hot fix has no contents!");
      }
      return STRING_NOT_FOUND_RC;
   }

   _str origDir=getcwd();
   int status,result = 0;
   while (child >= 0) {

      _str item = _xmlcfg_get_name(handle, child);
      switch (item) {
      case "File":   
         status = hotfixApplyFile(handle, child, zipfile, doRestore, quiet);    
         if (status < 0) result=status;
         break;
      case "Config":   
         status = hotfixApplyConfig(handle, child, zipfile, doRestore, quiet);
         if (status < 0) result=status;
         break;
      case "Module": 
         status = hotfixApplyModule(handle, child, zipfile, doRestore, quiet);
         if (status < 0) result=status;
         break;
      case "DLL":    
         status = hotfixApplyDLL(handle, child, zipfile, doRestore, quiet);     
         if (status < 0) result=status;
         break;
      case "Sysconfig":   
         status = hotfixApplySysconfig(handle, child, zipfile, doRestore, quiet);
         if (status < 0) result=status;
         break;
      case "Command":
         status = hotfixApplyCommand(handle, child, zipfile, doRestore, quiet); 
         if (status < 0) result=status;
         break;
      case "ZipFile":
         status = hotfixApplyZipFile(handle, child, zipfile, restart, doRestore, true);
         if (status < 0) result=status;
         break;
      }

      // If they cancelled out of something, the quit now
      if (status == COMMAND_CANCELLED_RC) {
         hotfixLogAction("Cancelled.");
         break;
      }

      child = _xmlcfg_get_next_sibling(handle, child);
   }

   hotfixLogAction("Done.");
   dsay("==================================================");
   clear_message();
   chdir(origDir,1);
   return result;
}

static int hotfixSaveFiles()
{
   if (_no_child_windows()) return 0;
   _project_disable_auto_build(true);
   int status = _mdi.p_child.list_modified("Files must be saved before applying hotfix",true);
   _project_disable_auto_build(false);
   return status;
}

static int hotfixShowInfo(HotfixInfo &info, int reason)
{
   status := hotfixCheckDescription(info, reason);

   return status;
}

static int hotfixCanLoad(_str zipfile, _str (&files)[], _str (&system_files)[], _str (&fix_list)[] = null, boolean quiet = false)
{
   // make sure they haven't already applied this hot fix
   int status = hotfixCheckIfApplied(zipfile, quiet);
   if (status) {
      return status;
   }

   // make sure that the zip file has a manifest
   int manifest_handle = hotfixOpenManifest(zipfile);
   if (manifest_handle < 0) {
      if (!quiet) {
         _message_box("Invalid hot fix.  Could not open manifest: " :+ get_message(manifest_handle));
      }
      return manifest_handle;
   }

   // check the version number
   compatibleVersions := "";
   fix_version := hotfixGetVersion(manifest_handle, &compatibleVersions);
   status = hotfixCheckVersion(fix_version, compatibleVersions);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      return status;
   }

   // check the hotfix requirements
   _str fix_requires = hotfixGetRequirements(manifest_handle, auto fix_requires_names);
   status = hotfixCheckRequirements(fix_requires, fix_requires_names, fix_list);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      return status;
   }

   // check if the hot fix affects system files
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
      return status;
   }

   return manifest_handle;
}

static int hotfixPrepareToLoad(_str &zipfile, boolean &restart, boolean quiet = false)
{
   // find the zip file to load
   zipfile = hotfixGetZipFile(zipfile);
   if (zipfile == "") {
      return COMMAND_CANCELLED_RC;
   }

   // make sure they haven't already applied this hot fix
   int status = hotfixCheckIfApplied(zipfile, quiet);
   if (status) {
      return status;
   }

   // make sure that the zip file has a manifest
   int manifest_handle = hotfixOpenManifest(zipfile);
   if (manifest_handle < 0) {
      if (!quiet) {
         _message_box("Invalid hot fix.  Could not open manifest: " :+ get_message(manifest_handle));
      }
      return manifest_handle;
   }

   // check the version number
   compatibleVersions := "";
   fix_version := hotfixGetVersion(manifest_handle, &compatibleVersions);
   status = hotfixCheckVersion(fix_version, compatibleVersions);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      return status;
   }

   // check the hotfix requirements
   _str fix_requires = hotfixGetRequirements(manifest_handle, auto fix_requires_names);
   status = hotfixCheckRequirements(fix_requires, fix_requires_names);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
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
      return status;
   }

   // show the description of the hot fix to confirm before applying
   HotfixInfo info;
   info.ZipFile = zipfile;
   info.ManifestHandle = manifest_handle;
   info.Files = files;
   info.SystemFiles = system_files;
   info.Restart = hotfixGetRestart(manifest_handle);
   status = hotfixCheckDescription(info, HPFP_MANUAL_PROMPT);
   if (status != IDOK) {
      _xmlcfg_close(manifest_handle);
      return COMMAND_CANCELLED_RC;
   }

   // make them save files before applying the hot fix
   if (!quiet) {
      status = hotfixSaveFiles();
      if (status < 0) {
         _xmlcfg_close(manifest_handle);
         return status;
      }
   }

   return manifest_handle;
}

static int hotfixLoad(_str zipfile, boolean &restart, boolean quiet=false)
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

static int hotfixLoadByManifest(_str zipfile, int manifest_handle, boolean &restart, boolean quiet = false, boolean closeManifest = true)
{
   // copy the zip file to the user's configuration directory
   int status = hotfixCopyZipFile(zipfile, manifest_handle);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      return status;
   }

   // initialize results output
   _SccDisplayOutput("Applying hot fix: "zipfile, !quiet);
   dsay("==================================================");

   // modules need to be copied first to destination directory before being loaded
   // hotfixApplyModule still handles the unload operations for deleting files
   status = hotfixCopyModules(manifest_handle, zipfile, quiet);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      return status;
   }

   dsay("==================================================");
   dsay("Applying hot fix: "zipfile);

   // apply each rule in the hot fix
   int orig_timers=_use_timers;
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
   }

   // that's all folks!
   return status;
}

static int hotfixUnload(_str zipfile, boolean &restart, boolean quiet=false)
{
   // get name of hot fix to unload
   if (zipfile == "") {
      zipfile = hotfixChooser("Select hot fix to unload");
   } else if (!quiet) {
      int status = _message_box("Unload hotfix?  ":+zipfile, "SlickEdit", MB_YESNOCANCEL|MB_ICONQUESTION);
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
   int manifest_handle = hotfixOpenManifest(zipfile);
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
   int orig_timers=_use_timers;
   _use_timers=0;
   int status = hotfixApply(manifest_handle, zipfile, restart, true, quiet);
   _use_timers=orig_timers;

   // check if fix requires a restart
   if (!status) {
      restart = restart || hotfixGetRestart(manifest_handle);
   }

   // finally, close the manifest
   if (manifest_handle) {
      _xmlcfg_close(manifest_handle);
   }

   // finally, move the zip file out of the way
   _str unloaded_zipfile = zipfile :+ ".unloaded";
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
 * @param path      directory to scan for fixes
 * @param fix_list  (reference) list of fixes, each line has the format:
 *                  <pre>
 *                  file [tab] series [tab] revision [tab] date [tab] description [tab] fixes
 *                  </pre>
 * @param infoFlags what info to include in each line
 * 
 * @return <0 on failure, number of fixes >0 on success
 */
static int hotfixFindAll(_str path, _str (&fix_list)[], int infoFlags)
{
   // find the hotfixes directory
   if (path=="") {
      path = hotfixGetHotfixesDirectory();
   }

   // and wildcards to find all the zip files
   _maybe_append_filesep(path);
   path = path :+ "*.zip";
   path = maybe_quote_filename(path);

   // look for zip files
   _str file = file_match(path, 1);
   if (file == "") {
      return FILE_NOT_FOUND_RC;
   }
   while (file != "") {
      // get hot fix description
      // add to caption list
      fix_list[fix_list._length()] = hotfixGetInfoStr(file, infoFlags);

      // next please
      file = file_match(path, 0);
   }

   // success
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
      
   _str fixDate="";
   _str revision="";
   _str description="";
   _str fixes="";
   int manifest_handle = hotfixOpenManifest(zipfile);
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
         info :+= "\t" :+ hotfixGetFixDescriptions(manifest_handle);
      }

      // all done with this one
      _xmlcfg_close(manifest_handle);
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
   _str result = "";
   _str file,revision,date,description,fixes;
   int i, n = fix_list._length();
   for (i=0; i<n; ++i) {

      parse fix_list[i] with file "\t" revision "\t" date "\t" description "\t" fixes "\t";
      int size = hotfixGetFileSize(file);
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
   int status = hotfixFindAll(path, fix_list, (HIF_FILENAME | HIF_REVISION | HIF_FIX_DATE));
   if (status < 0) {
      return "";
   }

   // display the list of hot fixes
   _str choice = select_tree(fix_list, 
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
   int status = hotfixFindAll(path, fix_list, (HIF_FILENAME | HIF_REVISION | HIF_FIX_DATE | HIF_DESCRIPTION | HIF_FIXES));
   if (status < 0) {
      _message_box("No hot fixes found");
      return status;
   }

   // generate the HTML string
   _str msg = hotfixGenerateHTML(fix_list);
   
   // now show them the list of fixes
   return textBoxDialog(caption,       // Form caption
                        0,             // Flags
                        8000,             // Use default textbox width
                        "", // Help item
                        "OK,Cancel:_cancel\t-html ":+msg
                        );
   return status;
}

/**
 * Load a hot fix.
 */
_command void load_hotfix(_str zipfile="", boolean quiet=false) name_info(FILE_ARG','VSARG2_NCW|VSARG2_READ_ONLY)
{
   zipfile = strip(zipfile, 'B', '"');
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
_command void unload_hotfix(_str zipfile="", boolean quiet=false) name_info(FILE_ARG','VSARG2_NCW|VSARG2_READ_ONLY)
{
   zipfile = strip(zipfile, 'B', '"');
   status := hotfixUnload(zipfile, auto doRestart=false, quiet);
   if (status != COMMAND_CANCELLED_RC) {
      hotfixCheckRestart(doRestart);
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
   _str config_dir = _ConfigPath();
   _str root_dir   = get_env("VSROOT");
   _maybe_append_filesep(root_dir);
   _str macros_dir = root_dir :+ "macros" :+ FILESEP;
   _str win_dir    = root_dir :+ "win" :+ FILESEP;
   _str win64_dir  = root_dir :+ "win64" :+ FILESEP;
   _str sysconfig_dir = root_dir :+ "sysconfig" :+ FILESEP;

   // parse out create options
   _str revisionNumber = '';
   boolean doRestart = false;
   files = strip(files);
   while (first_char(files) == '-') {
      opt := parse_file(files);
      if (opt == "-restart") {
         doRestart=true;
      }
      if (opt == "-revision") {
         revisionNumber = parse_file(files);
      }
   }

   // prompt user for fix file
   _str format_list='Macro Files(*.e;*.sh),All Files('ALLFILES_RE')';
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
   int status = textBoxDialog("Describe Hot Fix", 
                                 0, 0, "", "", "", 
                              "Name",
                              "Description");
      if (status < 0) {
         return;
      }
   _str hotfix_name = _param1;
   _str description = _param2;
      if (!pos("^[a-zA-z0-9_]*$", hotfix_name, 1, 'ri')) {
         _message_box("Invalid name:  "hotfix_name".  Hotfix names must contain only letters, numbers or underscores.");
      return;
   }

   // iterate through list of files
   _str fixes="";
   _str item="";
   foreach (item in files) {
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
   format_list='Macro Files(*.zip),All Files('ALLFILES_RE')';
   _str zipfile = hotfix_name :+ ".zip";
   zipfile = _OpenDialog('-new -mdi -modal',
                         'Save hot fix to',
                         '',     // Initial wildcards
                         format_list,  // file types
                         OFN_SAVEAS,
                         ".zip",  // Default extensions
                         zipfile, // Initial filename
                         '',      // Initial directory
                         '',      // Reserved
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

   // open temporary view for creating the manifest file
   int temp_wid=0, orig_wid=0;
   orig_wid = _create_temp_view(temp_wid);
   if (!orig_wid) return;

   // put together optional hot fix attributes
   _str hotfixAttrs = '';
   if (revisionNumber != '') {
      hotfixAttrs = " Revision=\""revisionNumber"\"";
   }
   if (doRestart) {
      hotfixAttrs = hotfixAttrs" Restart=\"1\"";
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
   _str orig_files = files;
   _str file = "", dest = "";
   _str fileArray[];
   item = parse_file(files, false);
   while (item != "") {
      fileArray[fileArray._length()] = item;
      // get just the file name
      file = _strip_filename(item, 'p');

      // from macros directory?
      if (pos(macros_dir, item, 1, 'i')==1) {
         _str noLoadAttribute="";
         if (hotfixCheckForDefmain(item)) {
            noLoadAttribute=' Load="0"';
         }
         relative_path := relative(item, macros_dir, false);
         relative_path = stranslate(relative_path, "/", FILESEP);
         insert_line("<Module Name=\""relative_path"\""noLoadAttribute"/>");
      } else if (lowcase(_get_extension(file))=="dll" && pos(win_dir, item, 1, 'i')==1) {
         // dll
         insert_line("<DLL Name=\""file"\" Arch=\""machine():+machine_bits()"\"/>");
      } else if (lowcase(_get_extension(file))=="dll" && pos(win64_dir, item, 1, 'i')==1) {
         // win 64 dll
         insert_line("<DLL Name=\""file"\" Arch=\""machine():+"64\"/>");
      } else if (pos(config_dir, item, 1, 'i')==1) {
         // configuration item
         dest = relative(item, config_dir);
         insert_line("<Config Name=\""file"\" Path=\""dest"\"/>");
      } else if (pos(root_dir, item, 1, 'i')==1) {
         dest = relative(item, root_dir);
         if (pos(win_dir, item, 1, 'i')==1) {
            insert_line("<File Name=\""file"\" Path=\""dest"\" Arch=\""machine():+machine_bits()"\"/>");
         } else if (pos(win64_dir, item, 1, 'i')==1) {
            insert_line("<File Name=\""file"\" Path=\""dest"\" Arch=\""machine()"64\"/>");
         } else if (pos(sysconfig_dir, item, 1, 'i')==1) {
            relative_path := relative(item, sysconfig_dir, false);
            relative_path = stranslate(relative_path, "/", FILESEP);
            insert_line("<Sysconfig Name=\""relative_path"\" />");
         } else {
            insert_line("<File Name=\""file"\" Path=\""dest"\"/>");
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
   _str zip_dir = _strip_filename(zipfile, 'n');
   _maybe_append_filesep(zip_dir);
   _str manifest = maybe_quote_filename(zip_dir:+HOTFIX_HOTFIX_MANIFEST_XML);
   status = save_as(manifest);
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);

   manifest=strip(manifest, 'b', "\"");
   fileArray[fileArray._length()] = manifest;

   // create the zip file
   zipfile = strip(zipfile, 'B', '"');
   int fileStatus[];
   status=_CreateZipFile(zipfile, fileArray, fileStatus);
   if ( status ) {
      _str msg=nls("Error creating zip file\n\n%s",get_message(status));
      _message_box(msg);
   }

   // clean up
   manifest=strip(manifest, 'b', "\"");
   delete_file(manifest);
}

_str aboutHotfixesList()
{
   _str fix_list[];
   int status = hotfixFindAll("", fix_list, HIF_FILENAME | HIF_REVISION);
   if (status < 0) {
      return "";
   }
   
   _str hotfix_list = "<b>Hotfixes: </b>\n";
   for (i := 0; i < fix_list._length(); ++i) {
     parse fix_list[i] with auto file "\t" auto revision;
     hotfix_list :+= file"&nbsp;(Revision:&nbsp;"revision")\n";
   }
   return hotfix_list;
}

_str getHotfixesList()
{
   _str fix_list[];
   int status = hotfixFindAll("", fix_list, HIF_FILENAME | HIF_REVISION);
   if (status < 0) {
      return "";
   }
   
   _str hotfix_list = "";
   for (i := 0; i < fix_list._length(); ++i) {
     parse fix_list[i] with auto file "\t" auto revision;
     hotfix_list :+= _strip_filename(file,'P'):+" (Revision: "revision") ";
   }
   return hotfix_list;
}

//////////////////////////////////////////////////////////////////////
// End Update Manager Hotfix loading code
//////////////////////////////////////////////////////////////////////



boolean gAutoHotfixesFound = false;
_str gLastSearchTime = 0;
int gLastSearchFinished = 0;
_str gConfigFileDate = 0;

#define HOTFIX_AUTO_SEARCH_PERIOD         4
#define HOTFIX_AUTO_SEARCH_INTERVAL       se.datetime.DT_HOUR

static boolean doAutoHotfixWork()
{
   if (gbgm_search_state ||
       _tbDebugQMode() ||
       _default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS) == SW_HIDE) {
      return false;
   }

   return true;
}

_command void hotfix_auto_apply(boolean quiet = false) name_info(',')
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

void hotfixAutoFindCallback()
{
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
            _ActivateAlert(ALERT_GRP_UPDATE_ALERTS, ALERT_HOTFIX_AUTO_FOUND, 'Your system administrator has configured a hot fix to be loaded. To apply it now, click <a href="<<cmd hotfix_auto_apply">here</a>.', 'Update Available');
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

static boolean hotfixTimeToAutoSearch()
{
   // if this is 0, then we go ahead and do this thing
   if (!gLastSearchTime) return true;
      
   DateTime now();
   DateTime then = DateTime.fromTimeB(gLastSearchTime);
   DateTime theNextTime = then.add(HOTFIX_AUTO_SEARCH_PERIOD, HOTFIX_AUTO_SEARCH_INTERVAL);

   return (now.compare(theNextTime) > 0);
}

static boolean hotfixesToApply()
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

static void hotfixApplyAutoFoundHotfixes(boolean automatic)
{
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
         result = show('-modal _hotfix_autofind_prompt_form', fixes);
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
         }
      }
   
      if (progressWid) {
         cancel_form_progress(progressWid, 1, 1);
         close_cancel_form(progressWid);
      }
   
      // clear our the applied list
      _xmlcfg_delete(configHandle, applyListNode, true);

      // save our xml file
      _xmlcfg_save(configHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
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
         fixes[fixes._length()] = info;
         fix_list[fix_list._length()] = hotfixGetInfoStr(info.ZipFile, HIF_SERIES | HIF_REVISION);
      }

      child = _xmlcfg_get_next_sibling(configHandle, child);
   }
}

int hotfixGetAutoFixInfo(HotfixInfo &info, _str (&fix_list)[])
{
   // make sure they haven't already applied this hot fix
   int status = hotfixCheckIfApplied(info.ZipFile, true);
   if (status) {
      return status;
   }

   // make sure that the zip file has a manifest
   int manifest_handle = hotfixOpenManifest(info.ZipFile);
   if (manifest_handle < 0) {
      return manifest_handle;
   }

   // check the version number
   compatibleVersions := "";
   fix_version := hotfixGetVersion(manifest_handle, &compatibleVersions);
   status = hotfixCheckVersion(fix_version, compatibleVersions);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      return status;
   }

   // check the hotfix requirements
   _str fix_requires = hotfixGetRequirements(manifest_handle, auto fix_requires_names);
   status = hotfixCheckRequirements(fix_requires, fix_requires_names, fix_list, true);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      return status;
   }

   // check if the hot fix affects system files
   _str readonly_files[];
   status = hotfixGetFiles(manifest_handle, info.Files, info.SystemFiles, readonly_files);
   if (status < 0) {
      _xmlcfg_close(manifest_handle);
      return status;
   }

   info.ManifestHandle = manifest_handle;
   info.Restart = hotfixGetRestart(manifest_handle);

   return 0;
}

static void hotfixMarkFileAsHandled(int configHandle, int handledListNode, _str zipFile, int manifestHandle)
{
   // create a node under our list of handled nodes
   int node = _xmlcfg_add(configHandle, handledListNode, "Hotfix", 
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

#define FIX_LIST           _ctl_apply.p_user

void _ctl_apply.on_create(HotfixInfo (&fixes)[], int purpose = 0)
{
   // how many hotfixes do we have?
   if (fixes._length() == 1) {
      showPromptForOneHotfix(fixes[0], purpose);
   } else {
      showPromptForMultipleHotfixes(fixes);
   }

   FIX_LIST = fixes;
}

static void moveControls()
{
   padding := _ctl_text.p_y;

   // figure out where the divider should go
   dividerY := 0;
   if (_ctl_info.p_visible) {
      dividerY = _ctl_info.p_y + _ctl_info.p_height + padding;
   } else {
      dividerY = _ctl_show_info.p_y + _ctl_show_info.p_height + padding;
   }

   // resize the form based on the size of the html control
   diff := _ctl_divider.p_y - dividerY;
   _ctl_divider.p_y = dividerY;

   p_active_form.p_height -= diff;
   _ctl_apply.p_y -= diff;
   _ctl_ask_later.p_y = _ctl_apply.p_y;
}

static void showPromptForOneHotfix(HotfixInfo fix, int purpose)
{
   padding := _ctl_text.p_y;

   // some things are not visible in this mode
   _ctl_text.p_visible = _ctl_list.p_visible = _ctl_show_info.p_visible = false;
   _ctl_info.p_height += (_ctl_info.p_y - _ctl_text.p_y);
   _ctl_info.p_y = _ctl_text.p_y;

   description := hotfixGetDescription(fix.ManifestHandle);
   fixes := hotfixGetFixDescriptions(fix.ManifestHandle);
   _ctl_info._minihtml_UseDialogFont();
   _ctl_info.p_backcolor = 0x80000022;
   _ctl_info.p_text = hotfixGetDisplayMsg(fix, description, fixes, purpose);

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

      _ctl_apply.p_caption = 'Yes';
      _ctl_ask_later.p_caption = 'No';
      break;
   }

   moveControls();
}

static void showPromptForMultipleHotfixes(HotfixInfo (&fixes)[])
{
   _ctl_text.p_caption = 'Your system administrator has installed new updates that need to be applied.';

   // some things are not visible in this mode
   _ctl_info.p_visible = false;
   _ctl_show_info.p_y = _ctl_info.p_y;
   moveControls();

   // set up our tree
   width := _ctl_list.p_width / 2;
   _ctl_list._TreeSetColButtonInfo(0, width, TREE_BUTTON_PUSHBUTTON, -1, "File");
   _ctl_list._TreeSetColButtonInfo(1, width, TREE_BUTTON_PUSHBUTTON, -1, "Path");

   // populate our list
   for (i := 0; i < fixes._length(); i++) {
      file := fixes[i].ZipFile;
      text := _strip_filename(file, 'P') :+ \t :+ _strip_filename(file, 'N');
      _ctl_list._TreeAddItem(TREE_ROOT_INDEX, text, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, i);
   }

   _ctl_apply.p_caption = '&Apply all hot fixes';
}

void _ctl_show_info.lbutton_up()
{
   // get the selected tree item
   index := _ctl_list._TreeCurIndex();
   index = _ctl_list._TreeGetUserInfo(index);

   // now we have the index in our list of fixes
   info := ((HotfixInfo)FIX_LIST[index]);

   // show the info about it
   hotfixShowInfo(info, HPFP_INFO);
}

void _ctl_apply.lbutton_up()
{
   p_active_form._delete_window(IDOK);
}

void _ctl_ask_later.lbutton_up()
{
   p_active_form._delete_window(IDCANCEL);

}
