////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47669 $
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
#import "stdprocs.e"
#endregion

namespace default;

/**
 * Holds the information required for a Version Control 
 * Provider. 
 */
struct VersionControlProvider {
   _str Name;                       // name of the provider - used to display the provider to the user
   _str VCSProject;                 // the VCSProject value associated with this provider
   _str ArchiveFileSpec;            // archive_filespec value associated with this provider
   int Styles;                      // contains style setting flags for this provider
   _str Commands[];                 // the list of commands used by this provider
   boolean System;                  // whether this provider was read from the installed system file
};

VersionControlProvider def_vc_providers:[] = null;

namespace se.vc;

enum VCCommands {
   VCGET,        
   VCCHECKOUT,   
   VCCHECKIN,    
   VCUNLOCK,     
   VCADD,        
   VCLOCK,       
   VCREMOVE,     
   VCHISTORY,    
   VCDIFF,       
   VCPROPERTIES, 
   VCMANAGER,    
};

#define NUM_VC_COMMANDS        VCMANAGER + 1

enum_flags VCStyleFlags {
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

struct CommandInfo {
   int Index;
   _str DisplayName;
};

static _str g_defaultCommands[] = { '', '', '', '', '', '', '', '', '', '', '' };

// table of commands
static CommandInfo g_commandInfo:[] = {
   'checkout_read_only' => { VCGET,          'Get' },
   'checkout'           => { VCCHECKOUT,     'Checkout' },
   'checkin'            => { VCCHECKIN,      'Checkin' },
   'checkin_discard'    => { VCUNLOCK,       'Unlock' },
   'checkin_new'        => { VCADD,          'Add' },
   'lock'               => { VCLOCK,         'Lock' },
   'remove'             => { VCREMOVE,       'Remove' },
   'history'            => { VCHISTORY,      'History' },
   'difference'         => { VCDIFF,         'Difference' },
   'properties'         => { VCPROPERTIES,   'Properties' },
   'manager'            => { VCMANAGER,      'Manager' },
};

class VersionControlSettings {
   
   // these are indexed by provider ID
   private static _str s_systemINIFile = '';
   private static _str s_userINIFile = '';
   
   VersionControlSettings()
   {  }
   
   public static boolean isValidProviderName(_str provName)
   {
      maybeLoadProviders();
      return (getProviderID(provName) != '');
   }

   /**
    * Gets the list of commands that SlickEdit supports for version control 
    * systems.  This does not retrieve any commands used to perform any actions for 
    * a specific version control provider. 
    * 
    * @param commands 
    */
   public static void getCommandList(_str (&commands)[])
   {
      CommandInfo cInfo;
      foreach (cInfo in g_commandInfo) {
         commands[cInfo.Index] = cInfo.DisplayName;
      }
   }

   /**
    * Determines whether the given vc provider is one defined by 
    * the system, as opposed to being user-defined. 
    * 
    * @return           true if the provider was defined by the 
    *                   system, false if it was defined by the
    *                   user.
    */
   public static boolean isSystemProvider(_str provID)
   {
      if (!isValidProviderID(provID)) return false;     

      return def_vc_providers:[provID].System;
   }

   /**
    * Retrieves a list of all the command line version control 
    * providers.  The list is a hashtable keyed off the display 
    * name of the provider.  The values in the hashtable are the 
    * VersionControlProvider.System values of the providers.  Any 
    * providers not available for this operating system are 
    * filtered out. 
    * 
    * @param list             hashtable to be filled 
    */
   public static void getCommandLineProviderList(boolean (&list):[])
   {
      maybeLoadProviders();
      VersionControlProvider vcp;
      foreach (auto provID => vcp in def_vc_providers) {
         if (pos('os/2', provID, 1, 'I') == 0) list:[vcp.Name] = vcp.System;
      }

   }

   /**
    * Retrieves a list of all the command line version control 
    * providers.  The list is a hashtable keyed off the id 
    * of the provider.  The values in the hashtable are the 
    * VersionControlProvider.Name values of the providers.  Any 
    * providers not available for this operating system are 
    * filtered out. 
    * 
    * @param list             hashtable to be filled 
    */
   public static void getCommandLineProviderIDList(_str (&list):[])
   {
      maybeLoadProviders();

      VersionControlProvider vcp;
      foreach (auto provID => vcp in def_vc_providers) {
         if (pos('os/2', provID, 1, 'I') == 0) list:[provID] = vcp.Name;
      }

   }

   /**
    * Gets the list of user-defined version control providers, 
    * i.e., providers whose System variable is false. 
    * 
    * @param list          list to be populated with the provider 
    *                      IDs of user-defined providers
    */
   public static void getProviderList(_str (&list)[])
   {
      maybeLoadProviders();

      VersionControlProvider vcp;
      foreach (auto providerID => vcp in def_vc_providers) {
         list[list._length()] = providerID;
      }
   }

   /**
    * Reads an INI file containing version control system 
    * information.  Creates VersionControlProvider structs 
    * containing the information read from the file. 
    * 
    * @param filename            file to read
    * @param system              whether this is the system file or 
    *                            a user config file
    * 
    * @return                    true if file was read 
    *                            successfully
    */
   private static boolean readINI(_str filename, boolean system)
   {
      // so...get all the names first
      _str providersList[];
      _ini_get_sections_list(filename, providersList);
      
      _str providerID;
      foreach (providerID in providersList) {
         
         VersionControlProvider vcp;
         vcp.VCSProject = '';
         vcp.ArchiveFileSpec = '';
         vcp.Commands = g_defaultCommands;
         
         // see if this provider already exists
         overWriting := false;
         if (def_vc_providers._indexin(providerID)) {
            vcp = def_vc_providers:[providerID];
            overWriting = true;
         }
         
         // now load the info from the ini file into this provider
         _str data[];
         _ini_get_section_array(filename, providerID, data);
         
         // data is in form of "key=value" for each line
         _str line;
         _str styles, vcsProject;
         name := providerID;
         foreach (line in data) {
            _str key, value;
            parse line with key'='value;
            value = strip(value);
            if (key == 'vcsproject') {
               vcp.VCSProject = value;
            } else if (key == 'styles') {
               styles = value;
            } else if (key == 'name') {
               name = value;
            } else if (key == 'archive_filespec') {
               vcp.ArchiveFileSpec = value;
            } else {
               // it's got to be a command then
               commandIndex := parseINICommand(key);
               if (commandIndex >= 0) {
                  vcp.Commands[commandIndex] = value;
               }
            }
         }

         vcp.Styles = parseINIStyles(styles, vcp.VCSProject, isRCS(providerID));
         vcp.Name = name;

         // we don't want to overwrite the system value
         if (!overWriting) {
            vcp.System = system;
         } 

         def_vc_providers:[providerID] = vcp;
      }
      
      return true;
   }
   
   /**
    * Parses the INI styles value to create a single integer 
    * containing styles flags. 
    * 
    * @param styles              the styles INI value
    * @param vcsProject          the VCSProject INI value
    * @param isRCS               whether this provider is an RCS 
    *                            version control system
    * 
    * @return                    the newly created styles value 
    *                            containing all the styles flags as
    *                            according to the INI value
    */
   private static int parseINIStyles(_str styles, _str vcsProject, boolean isRCS)
   {
      styleFlags := 0;
         
      if (pos(',error_redir,',','styles',')) {
         styleFlags |= VCS_ERROR_STDERR_STDOUT;
      } else if (pos(',error_stdout,',','styles',')) {
         styleFlags |= VCS_ERROR_STDOUT;
      } else if (pos(',error_file,',','styles',')) {
         styleFlags |= VCS_ERROR_FILE;
      } else if (pos(',internal_cmd_lookup,',','styles',')) {
         styleFlags |= VCS_ERROR_INTERNAL_LOOKUP;
      }
      
      if (pos(',delta_error,',','styles',')) styleFlags |= VCS_DELTA_ERROR;
      if (pos(',comment_file,',','styles',')) styleFlags |= VCS_WRITE_COMMENT_TO_FILE;
      if (pos(',unix_comment_file,',','styles',')) styleFlags |= VCS_UNIX_COMMENT_FILE;
      if (pos(',dosrc,',','styles',')) styleFlags |= VCS_DOSRC_FOR_ERROR;
      if (pos(',pvcs_wildcards,',','styles',')) styleFlags |= VCS_PVCS_WILDCARDS;
      if (pos(',vcp_required,',','styles',')) styleFlags |= VCS_PROJECT_REQUIRED;
      if (pos(',always_show_output,',','styles',')) styleFlags |= VCS_ALWAYS_SHOW_OUTPUT;
      if (pos(',cdtofile,',','styles',')) styleFlags |= VCS_CD_TO_FILE;
      
      if (pos(',sstree,',','styles',')) {
         styleFlags |= VCS_PROJ_SS_TREE;
      } else if (pos(',ssonedir,',','styles',')) {
         styleFlags |= VCS_PROJ_SS_ONE_DIR;
      } else if (pos(',sslocate,',','styles',')) {
         styleFlags |= VCS_PROJ_SS_LOCATE_FILE;
      } else if (strip(vcsProject)=='dir') {
         styleFlags |= VCS_PROJ_CD_TO_DIR;
      } else if (strip(vcsProject)=='always_show_output') {
         styleFlags |= VCS_ALWAYS_SHOW_OUTPUT;
      } else if (isRCS) {
         styleFlags |= VCS_PROJ_DIR_CONTAINS_ARCHIVES;
      } 
      
      return styleFlags;
   }

   /**
    * Determines the index of the command specified by the string 
    * taken from the INI file. 
    * 
    * @param commandKey          string to parse
    * 
    * @return                    index of where to place this 
    *                            command in the
    *                            VersionControlProvider.Commands
    *                            table.
    */
   private static int parseINICommand(_str commandKey)
   {
      index := -1;

      if (g_commandInfo._indexin(commandKey)) {
         index = g_commandInfo:[commandKey].Index;
      }

      return index;
   }
   
   /**
    * Determines if the given provider is an RCS version control 
    * system. 
    * 
    * @param providerID          ID of the system to check
    * 
    * @return                    true if the provider is an RCS, 
    *                            false otherwise
    */
   private static boolean isRCS(_str providerID)
   {
      return (pos(' RCS ',' 'providerID' ') != 0);
   }

   /**
    * Adds a new version control provider to the collection.  Can 
    * optionally copy the settings from an existing provider. 
    * 
    * @param name                name of the new provider
    * @param srcProviderID       provider id of the existing 
    *                            provider from which to copy
    *                            settings
    * 
    * @return                    true if provider was added 
    *                            successfully, false otherwise
    */
   public static boolean addProvider(_str name, _str srcProviderID = '')
   {
      // this is not a valid ID
      if (srcProviderID != '' && !isValidProviderID(srcProviderID)) return false;
      
      VersionControlProvider vcp;

      if (srcProviderID != '') {
         vcp = def_vc_providers:[srcProviderID];
         vcp.System = false;
      } else vcp = buildDefaultProvider();

      vcp.Name = name;
      def_vc_providers:[name] = vcp;
      
      return true;
   }
   
   /**
    * Creates a VersionControlProvider with the default settings.
    * 
    * @return              new default VersionControlProvider 
    */
   private static VersionControlProvider buildDefaultProvider()
   {
      VersionControlProvider vcp;
      vcp.Styles = VCS_ERROR_STDERR_STDOUT | VCS_DOSRC_FOR_ERROR | VCS_WRITE_COMMENT_TO_FILE;
      vcp.Commands = g_defaultCommands;
      vcp.System = false;
      vcp.ArchiveFileSpec = '';
      vcp.Name = '';
      vcp.VCSProject = '';

      return vcp;
   }

   /**
    * Removes the VersionControlProvider with the given provider ID 
    * from the collection. 
    * 
    * @param providerID          provider id of provider to remove
    * 
    * @return                    true if VCP was deleted 
    *                            successfully, false otherwise.
    *                            Possible reasons for failure -
    *                            provider does not exist or is
    *                            system provider
    */
   public static boolean deleteProvider(_str providerID)
   {
      // this is not a valid ID
      if (!isValidProviderID(providerID)) return false;     

      // we don't allow deletion of system providers
      if (isSystemProvider(providerID)) return false;
      
      def_vc_providers._deleteel(providerID);
   
      return true;
   }
   
   /**
    * Renames the VersionControlProvider with the given provider 
    * ID. 
    * 
    * @param providerID          provider id of provider to rename
    * @param newName             new name of provider
    * 
    * @return                    true if VCP was renamed 
    *                            successfully, false otherwise.
    *                            Possible reasons for failure -
    *                            provider does not exist or is a
    *                            system provider
    */
   public static boolean renameProvider(_str providerID, _str newName)
   {
      // is this a valid provider ID
      if (!isValidProviderID(providerID)) return false;     
      
      // first make sure that no other provider has this name
      if (getProviderID(newName) != '') return false;
      
      def_vc_providers:[providerID].Name = newName;
      
      return true;
   }
   
   /**
    * Returns the provider name associated with the given provider ID.
    * 
    * @param providerID          ID of provider whose name to fetch
    * 
    * @return                    name of associated provider, empty string if no 
    *                            provider with that ID exists.
    */
   public static _str getProviderName(_str providerID)
   {
      // is this a valid provider ID
      if (!isValidProviderID(providerID)) return '';     
    
      return def_vc_providers:[providerID].Name;  
   }
   
   /**
    * Returns the provider ID associated with the provider with the given name.
    * 
    * @param providerName        name of provider with the given ID
    * 
    * @return                    ID of associated provider, empty string if no 
    *                            provider with that name exists
    */
   public static _str getProviderID(_str providerName)
   {
      _str id;
      VersionControlProvider vcp;
      foreach (id => vcp in def_vc_providers) {
         if (vcp.Name == providerName) return id;
      }
      
      return '';
   }
   
   /**
    * Loads the Version Control Provider information from INI 
    * files.  Previous to SlickEdit 2008, we saved all version 
    * control provider information in INI files. 
    * 
    * @return           true if we successfully loaded the 
    *                   information, false otherwise
    */
   private static boolean maybeLoadProviders()
   {
      // check for the system providers
      status := true;
      if (s_systemINIFile == '') {
         def_vc_providers._makeempty();
         s_systemINIFile = get_env('VSROOT') :+ VCSYSTEM_FILE;
         status = readINI(s_systemINIFile, true);
      }

      // now check for this one
      if (s_userINIFile == '') {
         s_userINIFile = usercfg_path_search(VSCFGFILE_USER_VCS);
         status = readINI(s_userINIFile, false) && status;
      }

      return status;
   }

   /**
    * Determines if the given provider ID currently is associated with any of 
    * the providers stored. 
    * 
    * @param providerID          provider ID to check
    * 
    * @return                    true if the given ID is associated with a 
    *                            provider, false otherwise
    */
   public static boolean isValidProviderID(_str providerID)
   {
      if (def_vc_providers._indexin(providerID)) return true;

      // make sure this stuff is even loaded...
      maybeLoadProviders();
      return def_vc_providers._indexin(providerID);
   }
   
   /**
    * Retrieves the index in VCCommands enum that corresponds to the given 
    * command name. 
    * 
    * @param commandName         Command name to search for.  Note that this is 
    *                            the same as the ini names, not the pretty
    *                            command names seen in the GUI.
    * 
    * @return                    corresponding index in VCCommands enum, -1 if 
    *                            no match was found.
    */
   private static int getCommandIDByCommandName(_str commandName)
   {
      _str cName;
      CommandInfo cInfo;
      foreach (cName => cInfo in g_commandInfo) {
         if (cName == commandName) {
            return cInfo.Index;
         }
      }

      return -1;
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
   public static _str getCommandByName(_str provider, _str commandName)
   {
      command := '';

      if (isValidProviderID(provider)) {
         commandID := getCommandIDByCommandName(commandName);
         if (commandID > 0) {
            command = def_vc_providers:[provider].Commands[commandID];
            if (command == null) command = '';
         }
      }

      return command;
   }

   public static _str getCommand(_str provider, int commandID)
   {
      if (isValidProviderID(provider)) {
         if (def_vc_providers:[provider].Commands[commandID] != null) {
            return def_vc_providers:[provider].Commands[commandID];
         }
      }

      return '';
   }

   private static void setCommand(_str provider, int commandID, _str commandValue)
   {
      if (isValidProviderID(provider) && def_vc_providers:[provider].Commands[commandID] != commandValue) {
         def_vc_providers:[provider].Commands[commandID] = commandValue;
      }
   }

   private static int getStyleChoice(_str provider, int choices)
   {
      if (isValidProviderID(provider)) {
         return (def_vc_providers:[provider].Styles & choices);
      }

      return 0;
   }

   private static void setStyleChoice(_str provider, int choices, int selectedChoice)
   {
      if (isValidProviderID(provider) && getStyleChoice(provider, choices) != selectedChoice) {
         // first get rid of all the possible values that might be there
         def_vc_providers:[provider].Styles &= ~choices;

         // now add back the one we want
         def_vc_providers:[provider].Styles |= selectedChoice;
      }
   }

   public static int getStyleFlags(_str provider)
   {
      if (isValidProviderID(provider)) {
         return def_vc_providers:[provider].Styles;
      }

      return 0;
   }

   private static boolean getStyle(_str provider, int style)
   {
      if (isValidProviderID(provider)) {
         return (def_vc_providers:[provider].Styles & style) != 0;
      }

      return false;
   }

   private static void setStyle(_str provider, int style, boolean value)
   {
      if (isValidProviderID(provider) && getStyle(provider, style) != value) {

         if (value) def_vc_providers:[provider].Styles |= style;
         else def_vc_providers:[provider].Styles &= ~style;
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
   public static _str getVCSProject(_str provider)
   {
      if (isValidProviderID(provider)) {
         return def_vc_providers:[provider].VCSProject;
      }

      return '';
   }

   public static void setVCSProject(_str provider, _str vcsProject)
   {
      if (isValidProviderID(provider) && def_vc_providers:[provider].VCSProject != vcsProject) {
         def_vc_providers:[provider].VCSProject = vcsProject;
      }
   }

   public static _str getArchiveFileSpec(_str provider)
   {
      if (isValidProviderID(provider)) {
         return def_vc_providers:[provider].ArchiveFileSpec;
      }

      return '';
   }

   public static void setArchiveFileSpec(_str provider, _str archiveFileSpec)
   {
      if (isValidProviderID(provider) && def_vc_providers:[provider].ArchiveFileSpec != archiveFileSpec) {
         def_vc_providers:[provider].ArchiveFileSpec = archiveFileSpec;
      }
   }

   public static void getCommandArray(_str provID, _str (&array)[])
   {
      if (isValidProviderID(provID)) {
         array = def_vc_providers:[provID].Commands;
      }
   }

   public static void getCommandTable(_str provID, _str (&table):[])
   {
      if (isValidProviderID(provID)) {
         CommandInfo cInfo;
         foreach (cInfo in g_commandInfo) {
            table:[cInfo.DisplayName] = def_vc_providers:[provID].Commands[cInfo.Index];
         }
      }
   }

   public static void setCommandTable(_str provID, _str (&table):[])
   {
      if (isValidProviderID(provID)) {
         CommandInfo cInfo;
         foreach (cInfo in g_commandInfo) {
            def_vc_providers:[provID].Commands[cInfo.Index] = table:[cInfo.DisplayName];
         }
      }
   }

   public static int getErrorCaptureStyleFromFlags(int styleFlags)
   {
      return (styleFlags & (VCS_ERROR_STDERR_STDOUT | VCS_ERROR_STDOUT | 
                            VCS_ERROR_FILE | VCS_ERROR_INTERNAL_LOOKUP));
   }

   public static int getErrorCaptureStyle(_str provider)
   {
      return getStyleChoice(provider, VCS_ERROR_STDERR_STDOUT | VCS_ERROR_STDOUT | 
                      VCS_ERROR_FILE | VCS_ERROR_INTERNAL_LOOKUP);
   }
   
   public static void setErrorCaptureStyle(_str provider, int style)
   {
      setStyleChoice(provider, VCS_ERROR_STDERR_STDOUT | VCS_ERROR_STDOUT | 
                      VCS_ERROR_FILE | VCS_ERROR_INTERNAL_LOOKUP, style);
   }

   public static int getVCSProjectStyleFromFlags(int styleFlags)
   {
      return (styleFlags & (VCS_PROJ_SS_TREE | VCS_PROJ_SS_ONE_DIR | VCS_PROJ_SS_LOCATE_FILE | 
                            VCS_PROJ_CD_TO_DIR | VCS_PROJ_DIR_CONTAINS_ARCHIVES));
   }

   public static int getVCSProjectStyle(_str provider)
   {
      return getStyleChoice(provider, VCS_PROJ_SS_TREE | VCS_PROJ_SS_ONE_DIR | 
                      VCS_PROJ_SS_LOCATE_FILE | VCS_PROJ_CD_TO_DIR | VCS_PROJ_DIR_CONTAINS_ARCHIVES);
   }
   
   public static void setVCSProjectStyle(_str provider, int style)
   {
      setStyleChoice(provider, VCS_PROJ_SS_TREE | VCS_PROJ_SS_ONE_DIR | 
                      VCS_PROJ_SS_LOCATE_FILE | VCS_PROJ_CD_TO_DIR | VCS_PROJ_DIR_CONTAINS_ARCHIVES, style);
   }

   public static boolean getDeltaError(_str provider)
   {
      return getStyle(provider, VCS_DELTA_ERROR);
   }

   public static void setDeltaError(_str provider, boolean value)
   {
      setStyle(provider, VCS_DELTA_ERROR, value);
   }

   public static boolean getWriteCommentToFile(_str provider)
   {
      return getStyle(provider, VCS_WRITE_COMMENT_TO_FILE);
   }

   public static void setWriteCommentToFile(_str provider, boolean value)
   {
      setStyle(provider, VCS_WRITE_COMMENT_TO_FILE, value);
   }

   public static boolean getUNIXCommentFile(_str provider)
   {
      return getStyle(provider, VCS_UNIX_COMMENT_FILE);
   }

   public static void setUNIXCommentFile(_str provider, boolean value)
   {
      setStyle(provider, VCS_UNIX_COMMENT_FILE, value);
   }

   public static boolean getRunDOSRCForError(_str provider)
   {
      return getStyle(provider, VCS_DOSRC_FOR_ERROR);
   }

   public static void setRunDOSRCForError(_str provider, boolean value)
   {
      setStyle(provider, VCS_DOSRC_FOR_ERROR, value);
   }

   public static boolean getUsePVCSWildcards(_str provider)
   {
      return getStyle(provider, VCS_PVCS_WILDCARDS);
   }

   public static void setUsePVCSWildcards(_str provider, boolean value)
   {
      setStyle(provider, VCS_PVCS_WILDCARDS, value);
   }

   public static boolean getVCSProjectRequired(_str provider)
   {
      return getStyle(provider, VCS_PROJECT_REQUIRED);
   }

   public static void setVCSProjectRequired(_str provider, boolean value)
   {
      setStyle(provider, VCS_PROJECT_REQUIRED, value);
   }

   public static boolean getAlwaysShowOutput(_str provider)
   {
      return getStyle(provider, VCS_ALWAYS_SHOW_OUTPUT);
   }

   public static void setAlwaysShowOutput(_str provider, boolean value)
   {
      setStyle(provider, VCS_ALWAYS_SHOW_OUTPUT, value);
   }

   public static boolean getCDToFileDir(_str provider)
   {
      return getStyle(provider, VCS_CD_TO_FILE);
   }

   public static void setCDToFileDir(_str provider, boolean value)
   {
      setStyle(provider, VCS_CD_TO_FILE, value);
   }

   #endregion Get/Set For Individual Provider Options
};
