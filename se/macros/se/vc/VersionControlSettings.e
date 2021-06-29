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
#include "svc.sh"
#import "ini.e"
#import "main.e"
#import "cfg.e"
#import "stdprocs.e"
#endregion

namespace default;

struct VersionControlProvider {
   _str Name;                       // name of the provider - used to display the provider to the user
   _str VCSProject;                 // the VCSProject value associated with this provider
   _str ArchiveFileSpec;            // archive_filespec value associated with this provider
   int Styles;                      // contains style setting flags for this provider
   _str Commands[];                // the list of commands used by this provider
   bool System;
};

struct VersionControlProfile {
   _str m_vcsproject;                 // the VCSProject value associated with this provider
   _str m_archive_filespec;           // archive_filespec value associated with this provider
   int m_styles;                      // contains style setting flags for this provider
   _str m_commands:[];                // the list of commands used by this provider
};

// table of commands
_str _vc_commands:[] = {
   'get'=>'',
   'checkout'=>'',
   'checkin'=>'',
   'unlock'=>'',
   'add'=>'',
   'lock'=>'',
   'remove'=>'',
   'history'=>'',
   'difference'=>'',
   'properties'=>'',
   'manager'=>'',
};

namespace se.vc;

_metadata enum_flags VCStyleFlags {
   VCS_ERROR_STDERR_STDOUT,
   VCS_ERROR_STDOUT,
   VCS_ERROR_FILE,
   VCS_ERROR_INTERNAL_LOOKUP,
   VCS_DELTA_ERROR,
   VCS_WRITE_COMMENT_TO_FILE,
   VCS_UNIX_COMMENT_FILE,
   VCS_DOSRC_FOR_ERROR,
   VCS_PVCS_WILDCARDS,
   VCS_PROJECT_REQUIRED,
   VCS_ALWAYS_SHOW_OUTPUT,
   VCS_CD_TO_FILE,
   VCS_PROJ_CD_TO_DIR,
   VCS_PROJ_DIR_CONTAINS_ARCHIVES,
   VCS_PROJ_SS_TREE,
   VCS_PROJ_SS_ONE_DIR,
   VCS_PROJ_SS_LOCATE_FILE
};

class VersionControlSettings {
   
   // these are indexed by provider ID
   VersionControlSettings() {  
   }
   
   public static bool isValidProviderName(_str profileName) {
      return _plugin_has_profile(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName);
   }

   /**
    * Determines whether the given vc profile is built-in as
    * opposed to being user-defined. 
    * 
    * @return           true if the provider was defined by the 
    *                   system, false if it was defined by the
    *                   user.
    */
   public static bool isSystemProvider(_str profileName)
   {
      return _plugin_has_builtin_profile(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName);
   }


   /**
    * Retrieves a list of all the version control profiles.
    * 
    * @param list             hashtable to be filled 
    */
   public static void getCommandLineProviderList(bool (&list):[]) {
      _plugin_list_profiles(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,auto profileNames);
      for (i:=0;i<profileNames._length();++i) {
         profileName:=profileNames[i];
         list:[profileName] = _plugin_has_builtin_profile(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName);
      }
   }
   /**
    * Gets the list of user-defined version control providers, 
    * i.e., providers whose System variable is false. 
    * 
    * @param list          list to be populated with the provider 
    *                      IDs of user-defined providers
    */
   public static void getProviderList(_str (&list)[]) {
      _plugin_list_profiles(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,list);
   }

   public static void saveProfile(_str profileName,VersionControlProfile &vcp) {
      handle:=_xmlcfg_create_profile(auto profile_node,VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName,VSCFGPROFILE_VERSIONCONTROL_VERSION);
      _xmlcfg_add_property(handle,profile_node,'vcsproject',vcp.m_vcsproject);
      _xmlcfg_add_property(handle,profile_node,'archive_filespec',vcp.m_archive_filespec);
      _xmlcfg_add_property(handle,profile_node,'style_flags',"0x":+_dec2hex(vcp.m_styles));
      foreach (auto key=>auto value in _vc_commands) {
         if (vcp.m_commands._indexin(key)) {
            _xmlcfg_add_property(handle,profile_node,key,vcp.m_commands:[key]);
         }
      }
      _plugin_set_profile(handle);
      _xmlcfg_close(handle);
   }

   /**
    * Adds a new version control provider to the collection.  Can 
    * optionally copy the settings from an existing provider. 
    * 
    * @param profileName         profile name of the new provider 
    * @param srcProfileNam       provider id of the existing 
    *                            provider from which to copy
    *                            settings
    * 
    * @return                    true if provider was added 
    *                            successfully, false otherwise
    */
   public static bool addProvider(_str profileName, _str srcProfileName = '') {
      if (srcProfileName!='') {
         if (!isValidProviderID(srcProfileName)) {
            return false;
         }
         status:=_plugin_copy_profile(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,srcProfileName,profileName);
         return status==0;
      }
      
      VersionControlProfile vcp;

      vcp = buildDefaultProvider();

      saveProfile(profileName,vcp);

      return true;
   }
   
   /**
    * Creates a VersionControlProfile with the default settings.
    * 
    * @return              new default VersionControlProfile 
    */
   private static VersionControlProfile buildDefaultProvider() {
      VersionControlProfile vcp;
      vcp.m_styles = VCS_ERROR_STDERR_STDOUT | VCS_DOSRC_FOR_ERROR | VCS_WRITE_COMMENT_TO_FILE;
      vcp.m_commands = null;
      vcp.m_archive_filespec = '';
      vcp.m_vcsproject = '';

      return vcp;
   }

   /**
    * Removes the VersionControlProfile with the given provider ID 
    * from the collection. 
    * 
    * @param profileName         profile name of version control 
    *                            system to remove
    * 
    * @return                    true if profile was deleted 
    *                            successfully, false otherwise.
    *                            Possible reasons for failure -
    *                            provider does not exist or is
    *                            system provider
    */
   public static bool deleteProvider(_str profileName)
   {
      // this is not a valid ID
      if (!isValidProviderID(profileName)) return false;     

      // we don't allow deletion of system providers
      if (isSystemProvider(profileName)) return false;
   
      _plugin_delete_profile(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName);
      return true;
   }
   
   /**
    * Renames the VersionControlProfile with the given provider 
    * ID. 
    * 
    * @param profileName         Profile name to rename
    * @param newProfileName      new name of profile
    * 
    * @return                    true if profile was renamed 
    *                            successfully, false otherwise.
    *                            Possible reasons for failure -
    *                            profile does not exist or is a
    *                            built-in profile
    */
   public static bool renameProvider(_str profileName, _str newProfileName) {
      if (isSystemProvider(profileName)) {
         return false;
      }
      handle:=_plugin_get_profile(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName);
      if (handle<0) return false;
      profile_node:=_xmlcfg_get_first_child_element(handle);
      _xmlcfg_set_attribute(handle,profile_node,VSXMLCFG_PROFILE_NAME,_plugin_append_profile_name(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,newProfileName));
      _plugin_set_profile(handle);
      _xmlcfg_close(handle);
      _plugin_delete_profile(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName);
      return true;
   }
   
   /**
    * Returns the profile name if it is valie
    * 
    * @param profileName         profile name of version control 
    *                            system.
    * 
    * @return                    name of profile, empty string if 
    *                            no profile does not exist.
    */
   public static _str getProviderName(_str profileName) {
      if (isValidProviderName(profileName)) {
         return profileName;
      }
      return '';
   }
   
   /**
    * Returns the profile name if it is valie
    * 
    * @param profileName         profile name of version control 
    *                            system.
    * 
    * @return                    name of profile, empty string if 
    *                            no profile does not exist.
    */
   public static _str getProviderID(_str profileName) {
         return getProviderName(profileName);
   }
   
   /**
    * Determines if the given version control profile exists
    * 
    * @param profileName         profile name to check
    * 
    * @return                    true if the given ID is associated with a 
    *                            provider, false otherwise
    */
   public static bool isValidProviderID(_str profileName)
   {
      return _plugin_has_profile(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName);
   }

   /**
    * Retrieves the command that corresponds to the given command name. 
    * 
    * @param commandName         Command name to search for.  Note that this is 
    *                            the same as the ini names (e.g. VCS_REMOVE),
    *                            not the pretty command names seen in the GUI.
    * 
    * @return                    corresponding index in VCCommands enum, -1 if 
    *                            no match was found.
    */
   public static _str getCommandByName(_str provider, _str commandName) {
      command := '';

      if (isValidProviderID(provider)) {
         command=_plugin_get_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,provider,lowcase(commandName));
      }

      return command;
   }

   public static _str getCommand(_str provider, _str commandName) {
      return getCommandByName(provider,commandName);
   }

   private static void setCommand(_str provider, _str commandName, _str commandValue) {
      _plugin_set_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,provider,VSCFGPROFILE_VERSIONCONTROL_VERSION,lowcase(commandName),commandValue);
   }

   private static int getStyleChoice(_str provider, int choices) {
      if (isValidProviderID(provider)) {
         typeless style_flags;
         style_flags=_hex2dec(_plugin_get_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,provider,'style_flags'));
         if (!isinteger(style_flags)) {
            return 0;
         }
         return (style_flags & choices);
      }

      return 0;
   }

   private static void setStyleChoice(_str provider, int choices, int selectedChoice) {
      if (isValidProviderID(provider) && getStyleChoice(provider, choices) != selectedChoice) {
         typeless style_flags;
         style_flags=_hex2dec(_plugin_get_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,provider,'style_flags'));
         if (!isinteger(style_flags)) {
            style_flags=0;
         }

         // first get rid of all the possible values that might be there
         style_flags &= ~choices;

         // now add back the one we want
         style_flags |= selectedChoice;

         _plugin_set_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,provider,VSCFGPROFILE_VERSIONCONTROL_VERSION,'style_flags',"0x":+_dec2hex(style_flags));
      }
   }

   public static int getStyleFlags(_str provider) {
      typeless style_flags;
      style_flags=_hex2dec(_plugin_get_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,provider,'style_flags'));
      if (!isinteger(style_flags)) {
         return 0;
      }
      return style_flags;
   }

   private static bool getStyle(_str provider, int style) {
      if (isValidProviderID(provider)) {
         return (getStyleFlags(provider) & style) != 0;
      }

      return false;
   }

   private static void setStyle(_str provider, int style, bool value) {
      if (!isValidProviderID(provider)) return;
      if (isValidProviderID(provider) && getStyle(provider, style) != value) {
         style_flags:=getStyleFlags(provider);
         if (value) {
            _plugin_set_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,provider,VSCFGPROFILE_VERSIONCONTROL_VERSION,'style_flags',"0x":+_dec2hex(style_flags|style));
         } else {
            _plugin_set_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,provider,VSCFGPROFILE_VERSIONCONTROL_VERSION,'style_flags',"0x":+_dec2hex(style_flags&~style));
         }
      }
   }

   #region Get/Set For Individual Provider Options

   /**
    * Gets the version control provider setting, VCS Project.
    * 
    * @param provider         the provider ID of the version control provider 
    *                         whose setting we want
    * 
    * @return                 current setting value, empty string if the 
    *                         provider ID does not match any current provider
    */
   public static _str getVCSProject(_str profileName) {
      if (isValidProviderID(profileName)) {
         VCSProject:=_plugin_get_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName,'vcsproject');
         return VCSProject;
      }

      return '';
   }

   public static void setVCSProject(_str profileName, _str vcsProject) {
      if (isValidProviderID(profileName) && getVCSProject(profileName) != vcsProject) {
         _plugin_set_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName,VSCFGPROFILE_VERSIONCONTROL_VERSION,'vcsproject',vcsProject);
      }
   }

   public static _str getArchiveFileSpec(_str profileName) {
      if (isValidProviderID(profileName)) {
         return _plugin_get_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName,'archive_filespec');
      }

      return '';
   }

   public static void setArchiveFileSpec(_str profileName, _str archiveFileSpec) {
      if (isValidProviderID(profileName) && getArchiveFileSpec(profileName)!= archiveFileSpec) {
         _plugin_set_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName,VSCFGPROFILE_VERSIONCONTROL_VERSION,'archive_filespec',archiveFileSpec);
      }
   }
#if 0
   public static _str vcCommandToProperty(_str vccommand) {
      property_name:=substr(vccommand,3);
      if (property_name=='diff') property_name='difference';
      return property_name;
   }
#endif

   public static void getCommandTable(_str profileName, _str (&table):[]) {
      table._makeempty();
      if (isValidProviderID(profileName)) {
         table=_vc_commands;
         handle:=_plugin_get_profile(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName);
         if (handle<0) return;
         profile_node:=_xmlcfg_get_first_child_element(handle);
         property_node:=_xmlcfg_get_first_child_element(handle,profile_node);
         while (property_node>=0) {
            property_name:=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME);
            if (!pos(' 'property_name' ',' style_flags vcsproject archive_filespec ',1,'i')) {
               table:[property_name]=_xmlcfg_get_attribute(handle,property_node,VSXMLCFG_PROPERTY_VALUE);
            }
            property_node=_xmlcfg_get_next_sibling_element(handle,property_node);
         }
         _xmlcfg_close(handle);
      }
   }

   public static void setCommandTable(_str profileName, _str (&table):[]) {
      if (isValidProviderID(profileName)) {
         foreach (auto key=>auto value in table) {
            _plugin_set_property(VSCFGPACKAGE_VERSIONCONTROL_PROFILES,profileName,VSCFGPROFILE_VERSIONCONTROL_VERSION,lowcase(key),value);
         }
      }
   }

   public static int getErrorCaptureStyleFromFlags(int styleFlags) {
      return (styleFlags & (VCS_ERROR_STDERR_STDOUT | VCS_ERROR_STDOUT | 
                            VCS_ERROR_FILE | VCS_ERROR_INTERNAL_LOOKUP));
   }

   public static int getErrorCaptureStyle(_str profile) {
      return getStyleChoice(profile, VCS_ERROR_STDERR_STDOUT | VCS_ERROR_STDOUT | 
                      VCS_ERROR_FILE | VCS_ERROR_INTERNAL_LOOKUP);
   }
   
   public static void setErrorCaptureStyle(_str profile, int style) {
      setStyleChoice(profile, VCS_ERROR_STDERR_STDOUT | VCS_ERROR_STDOUT | 
                      VCS_ERROR_FILE | VCS_ERROR_INTERNAL_LOOKUP, style);
   }

   public static int getVCSProjectStyleFromFlags(int styleFlags) {
      return (styleFlags & (VCS_PROJ_SS_TREE | VCS_PROJ_SS_ONE_DIR | VCS_PROJ_SS_LOCATE_FILE | 
                            VCS_PROJ_CD_TO_DIR | VCS_PROJ_DIR_CONTAINS_ARCHIVES));
   }

   public static int getVCSProjectStyle(_str profile) {
      return getStyleChoice(profile, VCS_PROJ_SS_TREE | VCS_PROJ_SS_ONE_DIR | 
                      VCS_PROJ_SS_LOCATE_FILE | VCS_PROJ_CD_TO_DIR | VCS_PROJ_DIR_CONTAINS_ARCHIVES);
   }
   
   public static void setVCSProjectStyle(_str profile, int style) {
      setStyleChoice(profile, VCS_PROJ_SS_TREE | VCS_PROJ_SS_ONE_DIR | 
                      VCS_PROJ_SS_LOCATE_FILE | VCS_PROJ_CD_TO_DIR | VCS_PROJ_DIR_CONTAINS_ARCHIVES, style);
   }

   public static bool getDeltaError(_str profile) {
      return getStyle(profile, VCS_DELTA_ERROR);
   }

   public static void setDeltaError(_str profile, bool value) {
      setStyle(profile, VCS_DELTA_ERROR, value);
   }

   public static bool getWriteCommentToFile(_str profile) {
      return getStyle(profile, VCS_WRITE_COMMENT_TO_FILE);
   }

   public static void setWriteCommentToFile(_str profile, bool value) {
      setStyle(profile, VCS_WRITE_COMMENT_TO_FILE, value);
   }

   public static bool getUNIXCommentFile(_str profile) {
      return getStyle(profile, VCS_UNIX_COMMENT_FILE);
   }

   public static void setUNIXCommentFile(_str profileName, bool value) {
      setStyle(profileName, VCS_UNIX_COMMENT_FILE, value);
   }

   public static bool getRunDOSRCForError(_str profileName) {
      return getStyle(profileName, VCS_DOSRC_FOR_ERROR);
   }

   public static void setRunDOSRCForError(_str profileName, bool value) {
      setStyle(profileName, VCS_DOSRC_FOR_ERROR, value);
   }

   public static bool getUsePVCSWildcards(_str profileName) {
      return getStyle(profileName, VCS_PVCS_WILDCARDS);
   }

   public static void setUsePVCSWildcards(_str profileName, bool value) {
      setStyle(profileName, VCS_PVCS_WILDCARDS, value);
   }

   public static bool getVCSProjectRequired(_str profileName) {
      return getStyle(profileName, VCS_PROJECT_REQUIRED);
   }

   public static void setVCSProjectRequired(_str profileName, bool value) {
      setStyle(profileName, VCS_PROJECT_REQUIRED, value);
   }

   public static bool getAlwaysShowOutput(_str profileName) {
      return getStyle(profileName, VCS_ALWAYS_SHOW_OUTPUT);
   }

   public static void setAlwaysShowOutput(_str profileName, bool value) {
      setStyle(profileName, VCS_ALWAYS_SHOW_OUTPUT, value);
   }

   public static bool getCDToFileDir(_str profileName) {
      return getStyle(profileName, VCS_CD_TO_FILE);
   }

   public static void setCDToFileDir(_str profileName, bool value) {
      setStyle(profileName, VCS_CD_TO_FILE, value);
   }

   #endregion Get/Set For Individual Provider Options
};
