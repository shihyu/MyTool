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
#include 'plugin.sh'
#include 'xml.sh'
#import 'mprompt.e'
#import 'main.e'
#import 'stdprocs.e'
#import 'stdcmds.e'
#import 'slickc.e'
#import 'help.e'
#endregion

const VSXMLCFG_FILESEP=  '.';
const VSXMLCFG_PROPERTY_SEPARATOR=   ',';
const VSXMLCFG_PROPERTY_ESCAPECHAR=   '`';
const VSXMLCFG_OPTIONS=  "options";
const VSXMLCFG_DELETE=  "d";
const VSXMLCFG_ATTRS=   "attrs";
const VSXMLCFG_PROPERTY=  "p";
const VSXMLCFG_PROPERTY_NAME= "n";
const VSXMLCFG_PROPERTY_VALUE= "v";
// Apply attribute only supported inside profile.
const VSXMLCFG_PROPERTY_APPLY= "apply";
const VSXMLCFG_PROPERTY_CONFIGS= "configs";

const VSXMLCFG_PROFILE= "profile";
const VSXMLCFG_PROFILE_NAME= "n";
const VSXMLCFG_PROFILE_VERSION= "version";
const VSXMLCFG_PROFILE_CASESENSITIVEPROPERTYNAMES= "case_sensitive_property_names";
const VSXMLCFG_PROFILE_CONFIGS= "configs";

/* 
   Naming convents for packages, profiles and properties
   Packages: no underscores and start with VSCFGPACKAGE_
        #define VSCFGPACKAGE_APPLICATION "application"
 
   Profile names: no underscores and start with VSCFGPROFILE_
        #define VSCFGPROFILE_ENVIRONMENT "application.environment"
      
   Properties: start with VSCFGP_, followed by 
        profile name (or category like "BEAUTIFIER"), followed by propert name which may
        include underscores
        VSCFGP_BEAUTIFIER_TAB_SIZE CMINIT_TO_CFG("tab_size");
 */


const VSCFGPACKAGE_MISC= "misc";
const VSCFGPROFILE_FILE_MAPPINGS= "file_mappings";
const VSCFGPROFILE_FILE_MAPPINGS_VERSION= 1;
const VSCFGPROFILE_FILE_EXTENSIONS= "file_extensions";
const VSCFGPROFILE_FILE_EXTENSIONS_VERSION= 1;

const VSCFGPACKAGE_NOTIFICATION_PROFILES= 'notification_profiles';
const VSCFGPROFILE_DIFF_VERSION=     1;
const VSCFGPACKAGE_DIFF= 'diff';
_str vsCfgPackage_for_NotificationGroup(_str NotificationGroup) {
   return (VSCFGPACKAGE_NOTIFICATION_PROFILES:+VSXMLCFG_FILESEP:+NotificationGroup);
}


const VSCFGPACKAGE_APPLICATION= 'application';
const VSCFGPACKAGE_LANGUAGE= 'language';
const VSCFGPROFILE_LANGUAGE_VERSION= '1';
const VSCFGPROFILE_ALL_LANGUAGES= '*ALL_LANGUAGES*';
const VSCFGP_FILEPROJECT_DEFAULT_PROFILE= 'fileproject_default_profile';
_str vsCfgPackage_for_Lang(_str LangId) {
   return (VSCFGPACKAGE_LANGUAGE:+VSXMLCFG_FILESEP:+LangId);
}

_str vsCfgPackage_for_LangFileProjectProfiles(_str LangId) {
   return (vsCfgPackage_for_Lang(LangId):+VSXMLCFG_FILESEP:+'fileproject_profiles');
}
const VSCFGPROFILE_FILEPROJECTS= 'fileprojects';
const VSCFGPROFILE_FILEPROJECTS_VERSION= '1';

_str vsCfgPackage_for_LangBeautifierProfiles(_str LangId) {
   return (vsCfgPackage_for_Lang(LangId):+VSXMLCFG_FILESEP:+'beautifier_profiles');
}
//For now, use this for all beautifiers.
const VSCFGPROFILE_BEAUTIFIER_VERSION= '1';

const VSCFGPROFILE_RTE_PROFILES='rte_profiles';
const VSCFGPROFILE_RTE_VERSION='1';

_str vsCfgPackage_for_RTE(_str LangId)
{
   return vsCfgPackage_for_Lang(LangId):+VSXMLCFG_FILESEP:+
      VSCFGPROFILE_RTE_PROFILES;
}

_str vsCfgPackage_for_LangInteractiveProfiles(_str LangId) {
   return (vsCfgPackage_for_Lang(LangId):+VSXMLCFG_FILESEP:+'interactive_profiles');
}
const VSCFGPROFILE_INTERACTIVE_PROFILES= 'interactive_profiles';
const VSCFGPROFILE_INTERACTIVE_VERSION= '1';


const VSCFGPROFILE_SYMBOLTRANS_ALIASES=  'symboltrans_aliases';
const VSCFGPROFILE_DOC_ALIASES=  'doc_aliases';
const VSCFGPROFILE_ALIASES_VERSION=  1;
const VSCFGPROFILE_ALIASES=  'aliases';

// For now, just use this version for all 3 profiles.
const VSCFGPROFILE_XMLOUTLINEVIEW_VERSION=     1;
const VSCFGPACKAGE_XMLOUTLINEVIEW=  'xmloutlineview';
const VSCFGPACKAGE_XMLOUTLINEVIEW_PROFILES=  'xmloutlineview.profiles';
const VSCFGPROFILE_XMLOUTLINEVIEW_FILEMAP=  'filemap';
const VSCFGPROFILE_XMLOUTLINEVIEW_EXTENSIONMAP=  'extensionmap';

const VSCFGPROFILE_FTP_VERSION=     1;
const VSCFGPACKAGE_FTP=  'ftp';
const VSCFGPACKAGE_FTP_PROFILES=  'ftp.profiles';
const VSCFGPROFILE_FTP_OPTIONS=  'options';

const VSCFGPROFILE_EVENTTAB_VERSION=     1;
const VSCFGPACKAGE_EVENTTAB_PROFILES=  'eventtab_profiles';
const VSCFGPROFILE_EMULATION_PREFIX= "emulation-";
const VSCFGOPTIONS_ATTR_EMULATION= "emulation";

const VSCFGPROFILE_COLORCODING_VERSION=     2;
const VSCFGPACKAGE_COLORCODING_PROFILES=  'colorcoding_profiles';

const VSCFGPROFILE_SYMBOLCOLORING_VERSION=     1;
const VSCFGPACKAGE_SYMBOLCOLORING_PROFILES= 'symbolcoloring_profiles';

const VSCFGPROFILE_COLOR_VERSION= 5;
const VSCFGPACKAGE_COLOR_PROFILES= 'color_profiles';

const VSCFGPROFILE_ERRORPARSING_VERSION=     1;
const VSCFGPROFILE_ERRORPARSING=         'errorparsing';

const VSCFGPROFILE_FONTS_VERSION=     1;
const VSCFGPROFILE_FONTS=        'fonts';

const VSCFGPROFILE_EXPLORER_FAVORITES_VERSION=     1;
const VSCFGPROFILE_EXPLORER_FAVORITES=        'explorer_favorites';

const VSCFGPROFILE_DATE_TIME_FILTERS_VERSION=     1;
const VSCFGPROFILE_DATE_TIME_FILTERS=        'date_time_filters';

const VSCFGPROFILE_OPTIONS_VERSION=     1;
const VSCFGPROFILE_OPTIONS=        'options';

const VSCFGPROFILE_SEARCHES_VERSION=     1;
const VSCFGPROFILE_SEARCHES=        'searches';

const VSCFGPROFILE_URL_MAPPINGS_VERSION=   1;
const VSCFGPROFILE_URL_MAPPINGS=  "url_mappings";

const VSCFGPROFILE_TAG_FILE_LIST_VERSION=   1;
const VSCFGPROFILE_TAG_FILE_LIST=  "tag_file_list";
const VSCFGPROFILE_TAG_FILE_LIST_ALL=  "tag_file_list_all";

const VSCFGPROFILE_COLOR_CODING_SAMPLES_VERSION=   1;
const VSCFGPROFILE_COLOR_CODING_SAMPLES=  "color_coding_samples";

const VSCFGPROFILE_ENVIRONMENT_VERSION=  1;
const VSCFGPROFILE_ENVIRONMENT=   "environment";

const VSCFGPROFILE_VERSIONCONTROL_VERSION=  1;
const VSCFGPACKAGE_VERSIONCONTROL_PROFILES=   "versioncontrol_profiles";

const VSCFGPROFILE_DEF_VARS_VERSION=  1;
const VSCFGPROFILE_DEF_VARS=   "def_vars";

const VSCFGPACKAGE_PRINTING_PROFILES= "printing_profiles";
const VSCFGPROFILE_PRINTING_VERSION=  1;
const VSCFGP_PRINTING_PORTRAIT= 'portrait';
const VSCFGP_PRINTING_NUMBER_LINES_EVERY= 'number_lines_every';
const VSCFGP_PRINTING_PRINT_COLOR= 'print_color';
const VSCFGP_PRINTING_PRINT_BG_COLOR= 'print_bg_color';
const VSCFGP_PRINTING_NUMBER_OF_COPIES= 'number_of_copies';
const VSCFGP_PRINTING_PRINT_HEX= 'print_hex';
const VSCFGP_PRINTING_LEFT_MARGIN= 'left_margin';
const VSCFGP_PRINTING_BEFORE_FOOTER= 'before_footer';
const VSCFGP_PRINTING_RIGHT_FOOTER= 'right_footer';
const VSCFGP_PRINTING_LEFT_FOOTER= 'left_footer';
const VSCFGP_PRINTING_AFTER_HEADER= 'after_header';
const VSCFGP_PRINTING_RIGHT_HEADER= 'right_header';
const VSCFGP_PRINTING_SELECTION_ONLY= 'selection_only';
const VSCFGP_PRINTING_RIGHT_MARGIN= 'right_margin';
const VSCFGP_PRINTING_BOTTOM_MARGIN= 'bottom_margin';
const VSCFGP_PRINTING_CENTER_FOOTER= 'center_footer';
const VSCFGP_PRINTING_LEFT_HEADER= 'left_header';
const VSCFGP_PRINTING_TWO_UP= 'two_up';
const VSCFGP_PRINTING_VISIBLE_LINES_ONLY= 'visible_lines_only';
const VSCFGP_PRINTING_LANDSCAPE= 'landscape';
const VSCFGP_PRINTING_TOP_MARGIN= 'top_margin';
const VSCFGP_PRINTING_CENTER_HEADER= 'center_header';
const VSCFGP_PRINTING_SPACE_BETWEEN= 'space_between';
const VSCFGP_PRINTING_PRINT_COLOR_CODING= 'print_color_coding';
const VSCFGP_PRINTING_FONT_TEXT= 'font_text';

const VSCFGPROFILE_APPTHEME_VERSION = 1;
const VSCFGPACKAGE_APPTHEME_PROFILES = 'apptheme_profiles';


int _xmlcfg_export_profiles(int dest_handle,_str package,_str (&optionAttrs):[]=null,bool write_file_if_no_profiles_added=false) {
   _str profileNames[];
   _plugin_list_profiles(package,profileNames);
   if (!write_file_if_no_profiles_added && !profileNames._length()) {
      return 0;
   }
   NofProfiles := 0;
   options_node:=_xmlcfg_set_path(dest_handle,"/options");
   foreach (auto attrName=>auto attrValue in optionAttrs) {
      _xmlcfg_set_attribute(dest_handle,options_node,attrName,attrValue);
   }
   for (i:=0;i<profileNames._length();++i) {
      // If this profile has user modifications
      handle:=_plugin_get_user_profile(package,profileNames[i],false);
      if (handle>=0) {
         ++NofProfiles;
         _xmlcfg_copy(dest_handle,options_node,handle,0,VSXMLCFG_COPY_CHILDREN);
      }
   }
   return NofProfiles;
}
int _xmlcfg_export_profile(int dest_handle,_str package,_str profileName) {
   handle:=_plugin_get_user_profile(package,profileName,false);
   if (handle<0) {
      return 0;
   }
   options_node:=_xmlcfg_set_path(dest_handle,"/options");
   _xmlcfg_copy(dest_handle,options_node,handle,0,VSXMLCFG_COPY_CHILDREN);
   return 1;
}
void _xmlcfg_export_property(int dest_handle,_str package,_str profile,_str profileVersion,_str name,_str value,bool merge=true) {
   eprofileName:=_plugin_append_profile_name(package,profile);
   int node;
   if (merge) {
      node =_xmlcfg_find_simple(dest_handle,"/options/profile[strieq(@n,'"eprofileName"')][@merge='1']");
   } else {
      node =_xmlcfg_find_simple(dest_handle,"/options/profile[strieq(@n,'"eprofileName"')][not(@merge)]");
   }
   if (node<0) {
      options_node:=_xmlcfg_set_path(dest_handle,"/options");
      node=_xmlcfg_add(dest_handle,options_node,VSXMLCFG_PROFILE,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(dest_handle,node,VSXMLCFG_PROFILE_NAME,eprofileName);
      _xmlcfg_set_attribute(dest_handle,node,VSXMLCFG_PROFILE_VERSION,profileVersion);
      // This attributes is for export/import only
      _xmlcfg_set_attribute(dest_handle,node,'merge',1);
   }
   _xmlcfg_set_property(dest_handle,node,name,value);
}
void _xmlcfg_import_from_file(_str filename) {
   handle:=_xmlcfg_open(filename,auto status);
   if (handle>=0) {
      _str default_profile=null;
      typeless array[];
       _xmlcfg_find_simple_array(handle,"/options/":+VSXMLCFG_PROFILE,array);
       for (i:=0;i<array._length();++i) {
          eprofile:=_xmlcfg_get_attribute(handle,array[i],VSXMLCFG_PROFILE_NAME);
          profileName:=_plugin_get_profile_name(eprofile);
          epackage:=_plugin_get_profile_package(eprofile);
          merge:=_xmlcfg_get_attribute(handle,array[i],'merge');
          //say('package='epackage' pn='profileName' merge='merge);
          if (merge=='' || merge=='0') {
             profile_handle:=_xmlcfg_create('',VSENCODING_UTF8);
             _xmlcfg_copy(profile_handle,0,handle,array[i],VSXMLCFG_COPY_AS_CHILD);
             _plugin_set_user_profile(profile_handle);
             _xmlcfg_close(profile_handle);
          } else {
             profileVersion:=_xmlcfg_get_attribute(handle,array[i],VSXMLCFG_PROFILE_VERSION);
             typeless prop_array[];
             _xmlcfg_find_simple_array(handle,VSXMLCFG_PROPERTY, prop_array, array[i]);
             for (j:=0;j<prop_array._length();++j) {
                propertyName:=_xmlcfg_get_attribute(handle,prop_array[j],VSXMLCFG_PROPERTY_NAME);
                propertyValue:=_xmlcfg_get_attribute(handle,prop_array[j],VSXMLCFG_PROPERTY_VALUE);
                propertyApply:=_xmlcfg_get_attribute(handle,prop_array[j],VSXMLCFG_PROPERTY_APPLY,null);
                //say('n='propertyName' v='propertyValue);
                _plugin_set_property(epackage,profileName,profileVersion,propertyName,propertyValue,propertyApply);
             }
          }
       }
   }
}
// Ensures the profile name does not shadow a system profile name by prompting
// the user for a new name if ncessary.
int _plugin_prompt_save_profile(_str package,_str &profile_name) {   
   conflictRename := false;
   while (conflictRename ||_plugin_has_builtin_profile(package,profile_name)) {
      int status;

      if (conflictRename) {
         conflictRename = false;
         status = textBoxDialog("Save Profile As", 0, 0, "", "", "", 
                               "Pick a different profile name to save this as:"profile_name);
      } else {
         status = textBoxDialog("Save Profile As", 0, 0, "", "", "", 
                               "Pick a new profile name to save this as:My "profile_name);
      }

      if (status == COMMAND_CANCELLED_RC) {
         if (_message_box("Discard your changes?", "Cancel Edit", MB_YESNO) == IDYES) {
            return status;
         }
      } else {
         profile_name = _param1;
         if (profile_name=='') {
            _message_box("Can not overwrite system profiles.", "Invalid Profile Name");
            continue;
         }
         if (_plugin_has_builtin_profile(package,profile_name)) {
            _message_box("Can not overwrite system profiles.", "Invalid Profile Name");
            continue;
         }
      }

      int handle=_plugin_get_profile(package,profile_name);
      if (handle>=0) {
         _xmlcfg_close(handle);
         status = _message_box("A profile named '"profile_name"' already exists.  Overwrite it?", "Confirm Overwrite", MB_YESNO);
         if (status == IDYES) {
            break;
         }
         conflictRename = true;
      }
   }
   return 0;
}
int _plugin_prompt_add_profile(_str package,_str &profileName,_str copyFrom='') {
   needToPrompt := true;
   for (;;) {
      int status;
      if (copyFrom!='') {
         status = textBoxDialog("Copy Profile: "copyFrom, 0, 0, "", "", "", "Enter a new profile name:");
      } else {
         status = textBoxDialog("New Profile", 0, 0, "", "", "", "Enter a new profile name:");
      }

      if (status == COMMAND_CANCELLED_RC) {
         return status;
      }
      profileName = _param1; 

      if (_plugin_has_builtin_profile(package,profileName)) {
         _message_box("Can not overwrite system profiles.", "Invalid Profile Name");
         continue;
      }

      int handle=_plugin_get_profile(package,profileName);
      if (handle>=0) {
         _xmlcfg_close(handle);
         status = _message_box("A profile named '"profileName"' already exists.  Overwrite it?", "Confirm Overwrite", MB_YESNO);
         if (status == IDYES) {
            return 0;
         }
         continue;
      }
      return 0;
   }
}
int _plugin_copy_profile(_str escapedProfilePackage,_str fromProfile,_str toProfile) {
   handle:=_plugin_get_profile(escapedProfilePackage,fromProfile);
   if (handle<0) {
      return handle;
   }
   profileNode:=_xmlcfg_set_path(handle,"/profile");
   _xmlcfg_set_attribute(handle,profileNode,VSXMLCFG_PROFILE_NAME,_plugin_append_profile_name(escapedProfilePackage,toProfile));
   _plugin_set_profile(handle);
   _xmlcfg_close(handle);
   return 0;
}

_str _plugin_export_profile(_str &file, _str escapedPackage,_str profileName,_str langID='') {
   error := '';

   justFile := "";
   // Any characters are allowed (< > / etc.) but they have to be encoded
   justFile=_plugin_encode_filename(_plugin_append_profile_name(escapedPackage,profileName)):+VSCFGFILEEXT_CFGXML;
   // Get the user's diff profile if there is one
   handle:=_plugin_get_user_profile(escapedPackage,profileName);
   if (handle>=0) {
      // rip out just the file name
      filename:=file :+ justFile;
      status:=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL,filename);
      if (status) {
         if (langID != '') {
            error = nls("Error exporting profile for '%s1' to '%s2'",_LangGetModeName(langID),filename);
         } else {
            error = nls("Error exporting profile to '%s1'",filename);
         }
      }
      file = justFile;
   }
   return error;
}
int _plugin_export_profile_to_file(_str filename, _str escapedPackage,_str profileName,bool exportUserDiffProfile=true) {
   justFile := "";
   int handle;
   if (exportUserDiffProfile) {
      handle=_plugin_get_user_profile(escapedPackage,profileName);
   } else {
      handle=_plugin_get_profile(escapedPackage,profileName);
   }
   status:=handle;
   if (handle>=0) {
      // rip out just the file name
      status=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL,filename);
      if (status) {
         _message_box(nls("Error exporting profile to '%s1'",filename));
      }
   }
   return status;
}

_str _plugin_import_profile(_str file, _str escapedPackage, _str profileName, _str langID='') {
   error := '';

   if (file != '') {
      handle:=_xmlcfg_open(file,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
      if (handle<0) {
         if (langID != '') {
            error = nls("Error importing profile for '%s1' from '%s2'",_LangGetModeName(langID),file);
         } else {
            error = nls("Error importing profile from '%s1'",file);
         }
      } else {
         _plugin_set_user_profile(handle);
         _xmlcfg_close(handle);
      }
   } else {
      // This only deletes user level profiles
      _plugin_delete_profile(escapedPackage,profileName);
   }
   return error;
}


_str _plugin_export_profiles(_str &file, _str escapedPackage,_str (&optionAttrs):[]=null,bool write_file_if_no_profiles_added=false) {
   error := '';

   handle:=_xmlcfg_create('',VSENCODING_UTF8);
   NofProfiles:=_xmlcfg_export_profiles(handle,escapedPackage,optionAttrs,write_file_if_no_profiles_added);

   if (NofProfiles || write_file_if_no_profiles_added) {
      // Any characters are allowed (< > / etc.) but they have to be encoded
      _str filename=file;
      if (_strip_filename(file,'p')=='') {
         justFile:=_plugin_encode_filename(escapedPackage):+VSCFGFILEEXT_CFGXML;
         filename=file :+ justFile;
         file = justFile;
      }
      status:=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_UNIX_EOL,filename);
      if (status) {
         error = nls("Error exporting profiles to '%s1'",filename);
      }
   }
   return error;
}

/**
 * 
 * @param file      .cfg.xml file with options node.
 * @param escapedPackage
 *                  The escaped profile package. Specifies
 *                  the package this profile (profileName)
 *                  is contained in.
 * @param allow_deleting_profiles
 *                  When 2, only allow built-in profiles to be cleared. Don't
 *                  allow a complete delete of an existing profile.
 *                  <p>When 1, Delete profiles that aren't listed.
 *                  <p>When 0, Don't delete or clear any profiles.
 * @param callback
 * @param user_info
 * @param optionAttrs
 * 
 * @return 
 */
_str _plugin_import_profiles(_str file, _str escapedPackage,int allow_deleting_profiles=2,void (*callback)(_str epackage,_str profileName,bool doDelete,typeless user_info)=null,typeless user_info=null,_str (&optionAttrs):[]=null) {
   error := '';
   optionAttrs._makeempty();

   handle := -1;
   if (file != '') {
      handle=_xmlcfg_open(file,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
      if (handle<0) {
         error = nls("Error importing profile from '%s1'",file);
         return error;
      }
   }
   options_node:=_xmlcfg_get_first_child(handle,0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   if (options_node>=0) {
      attr_node:=_xmlcfg_get_first_child(handle, options_node,VSXMLCFG_NODE_ATTRIBUTE);
      while (attr_node>0) {
         optionAttrs:[_xmlcfg_get_name(handle,attr_node)]=_xmlcfg_get_value(handle,attr_node);
         attr_node=_xmlcfg_get_next_attribute(handle, attr_node);
      }
   }
   typeless profile_node_array[];
   int profile_name_2_node:[];
   _xmlcfg_find_simple_array(handle,"/options/":+VSXMLCFG_PROFILE,profile_node_array);
   for (j:=0;j<profile_node_array._length();++j) {
      int node=profile_node_array[j];
      _str profileName=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROFILE_NAME);
      if (profileName!='' && _plugin_get_profile_package(profileName)==escapedPackage) {
         // Profiles names are case insensitive.
         // Event table names are case sensitive but this does not support that. No big deal.
         profileName=substr(profileName,length(escapedPackage)+2);
         if (profileName!='') {
            profile_name_2_node:[lowcase(profileName)]=node;
         }
      }
   }
   _str profileNames[];
   _plugin_list_profiles(escapedPackage,profileNames);
   // Replace or delete existing profiles
   for (i:=0;i<profileNames._length();++i) {
      _str profileName=profileNames[i];
      int *pnode=profile_name_2_node._indexin(lowcase(profileName));
      if (pnode) {
         int node=*pnode;
         profile_handle:=_xmlcfg_create('',VSENCODING_UTF8);
         profile_node:=_xmlcfg_copy(profile_handle,0,handle,node,VSXMLCFG_COPY_AS_CHILD);
         _plugin_set_user_profile(profile_handle);
         if (callback!=null) {
            (*callback)(escapedPackage,profileName,false,user_info);
         }
         _xmlcfg_close(profile_handle);
         profile_name_2_node._deleteel(lowcase(profileName));
      } else {
         flags:=_plugin_has_profile_ex(escapedPackage,profileName);
         // IF there is a user profile to delete AND
         //    there is a built-in profile or we can allow profiles to be deleted.
         if ((flags&0x2) && (allow_deleting_profiles==1 || ((flags&1) || allow_deleting_profiles==2))) {
            // This only deletes user level profiles
            _plugin_delete_profile(escapedPackage,profileName);
            if (callback!=null) {
               (*callback)(escapedPackage,profileName,true,user_info);
            }
         }
      }
   }
   // Now add remaining new profiles
   foreach(auto profileName=>auto node in profile_name_2_node) {
      profile_handle:=_xmlcfg_create('',VSENCODING_UTF8);
      profile_node:=_xmlcfg_copy(profile_handle,0,handle,node,VSXMLCFG_COPY_AS_CHILD);
      _plugin_set_user_profile(profile_handle);
      if (callback!=null) {
         (*callback)(escapedPackage,profileName,false,user_info);
      }
      _xmlcfg_close(profile_handle);
   }

   if (handle>=0) {
      _xmlcfg_close(handle);
   }
   return error;
}
_str _plugin_escape_property(_str word) {
   // translate , --> `,
   // translate ` --> ``
   _str result;
   result=stranslate(word,"\0",VSXMLCFG_PROPERTY_ESCAPECHAR);
   result=stranslate(result,VSXMLCFG_PROPERTY_ESCAPECHAR',',',');
   result=stranslate(result,VSXMLCFG_PROPERTY_ESCAPECHAR:+VSXMLCFG_PROPERTY_ESCAPECHAR,"\0");
   return result;
}
_str _plugin_unescape_property(_str word) {
   return stranslate(word,'#0','`{?}','r');
}
void _plugin_next_position(_str key,int &last_position,int (&hash_position):[]) {
   int *pindex;
   int position;
   pindex=hash_position._indexin(key);
   // IF we don't have a position
   if (last_position<=0) {
      if (pindex) {
         last_position=*pindex;
      } else {
         last_position=1;
      }
   } else {
      if (pindex) {
         if (*pindex>last_position) {
            last_position= *pindex;
         } else {
            last_position++;
         }
      } else {
         last_position++;
      }
   }
}
int _xmlcfg_create_profile(int &profile_node,_str package,_str profileName,_str profileVersion,bool create_inside_options_node=false) {
   int handle=_xmlcfg_create('',VSENCODING_UTF8);
   if (create_inside_options_node) {
      profile_node=_xmlcfg_set_path(handle,"/options/profile");
   } else {
      profile_node=_xmlcfg_set_path(handle,"/profile");
   }
   _xmlcfg_set_attribute(handle,profile_node,VSXMLCFG_PROFILE_NAME,_plugin_append_profile_name(package,profileName));
   _xmlcfg_set_attribute(handle,profile_node,VSXMLCFG_PROFILE_VERSION,profileVersion);
   return handle;
}
int _xmlcfg_find_profile(int handle,_str epath) {
   int node=_xmlcfg_get_document_element(handle);
   if (node<0) return -1;
   node=_xmlcfg_get_first_child_element(handle,node);
   while (node>=0) {
      if (strieq(_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROFILE_NAME),epath)) {
         return node;
      }
      node=_xmlcfg_get_next_sibling_element(handle,node);
   }
   return -1;
}
int _xmlcfg_add_property(int handle,int profile_node,_str name,_str value=null,bool apply=null) {
   property_node:=_xmlcfg_add(handle,profile_node,VSXMLCFG_PROPERTY, VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME,name);
   if (value!=null) {
      _xmlcfg_set_attribute(handle,property_node,VSXMLCFG_PROPERTY_VALUE,value);
   }
   if (apply!=null) {
      _xmlcfg_set_attribute(handle,property_node,VSXMLCFG_PROPERTY_APPLY,apply);
   }
   return property_node;
}

bool _plugin_is_modified_builtin_profile(_str package,_str profileName) {
   flags:=_plugin_has_profile_ex(package,profileName);
   return (flags&0x1) && (flags&0x2);
}
bool _plugin_has_user_profile(_str package,_str profileName) {
   return  (_plugin_has_profile_ex(package,profileName)&0x2)?true:false;
}
int _xmlcfg_get_first_child_element(int handle,int node=0) {
   return _xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
}
int _xmlcfg_get_document_element(int handle) {
   return _xmlcfg_get_first_child(handle,0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
}
int _xmlcfg_get_next_sibling_element(int handle,int node=0) {
   return _xmlcfg_get_next_sibling(handle,node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
}
#if 0
_str _xmlcfg_get_profile_name(int handle,int node) {
   element:=_xmlcfg_get_name(handle,node);
   if (element==VSXMLCFG_PROFILE_NAME) {
      return _xmlcfg_get_attribute(handle,node,VSXMLCFG_PROFILE_NAME);
   }
   name :=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROFILE_NAME);
   if (length(name)) {
       return _plugin_append_profile_name(element, name);
   }
   return element;
}
#endif

_command void apply_profile_style(_str cmdline='')  name_info(FILE_ARG' 'WORD_ARG' 'WORD_ARG' 'WORD_ARG',') {
   profile_style:=VSPROFILE_STYLE_UNKNOWN;
   property_style:=VSPROPERTY_STYLE_UNKNOWN;
   filename:=parse_file(cmdline);
   parse cmdline with auto s1 auto s2 auto requiredPropertyNamePrefix;
   s1=lowcase(s1);
   if (s1=='n') {
      profile_style=VSPROFILE_STYLE_NORMALIZED;
   } else if (s1=='p') {
      profile_style=VSPROFILE_STYLE_PACKAGE_ELEMENT;
   } else if (s1=='f' || s1=='e') {
      profile_style=VSPROFILE_STYLE_FULL_QUALIFIED_PROFILE_ELEMENT;
   }
   s2=lowcase(s2);
   if (s2=='n') {
      property_style=VSPROPERTY_STYLE_NORMALIZED;
   } else if (s2=='e') {
      property_style=VSPROPERTY_STYLE_ELEMENT;
   }
   if (filename=='') {
      if (!_isEditorCtl(false)) {
         return;
      }
      filename=p_buf_name;
      if (p_modify) {
         status:=save();
         if (status) return;
      }
   }
   handle:=_xmlcfg_open(filename,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
   if (handle<0) {
      return;
   }
   _xmlcfg_apply_profile_style(handle,_xmlcfg_get_document_element(handle),profile_style,property_style,requiredPropertyNamePrefix);
   _xmlcfg_save(handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
   _xmlcfg_close(handle);
}
_str _plugin_update_word_list(_str orig_styles,_str new_styles) {
   bool found_style:[];
   for (;;) {
      parse new_styles with auto style new_styles;
      if (style=='') break;
      found_style:[style]=true;
      if (!pos(' 'style' ',' 'orig_styles' ')) {
         // Add this style
         if (orig_styles!='') {
            strappend(orig_styles,' 'style);
         } else {
            orig_styles=style;
         }
      }
   }
   temp:=orig_styles;
   for (;;) {
      parse temp with auto style temp;
      if (style=='') break;
      // If this style was removed.
      if (!found_style._indexin(style)) {
         orig_styles=stranslate(orig_styles,'','^'style'($|[ \t])','r');
         orig_styles=stranslate(orig_styles,'','(^|[ \t])'style'$','r');
         orig_styles=stranslate(orig_styles,' ','([ \t])'style'([ \t])','r');
      }
   }
   return orig_styles;
}
void _xmlcfg_delete_property(int handle,int profile_node,_str name) {
   node:=_xmlcfg_find_property(handle,profile_node,name);
   if (node<0) return;
   _xmlcfg_delete(handle,node);
}
struct VSPLUGIN_OTHER_FILE {
   _str m_filename;
   long m_time;
};
long def_plugin_other_files:[];
extern void _plugin_get_other_files(VSPLUGIN_OTHER_FILE (&other_files)[]);
struct PLUGIN_FILE_INFO {
   _str m_filename;
   int m_i;
};
struct PLUGIN_PATH_INFO {
   _str m_plugin_xml_filename;
   PLUGIN_FILE_INFO m_files:[];
};
static void list_plugin_files(_str (&ordered_files)[],_str path,int plugin_xml_handle,int plugin_xml_parent_node) {
   node:=_xmlcfg_get_first_child(plugin_xml_handle,plugin_xml_parent_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   while (node>=0) {
      name:=_xmlcfg_get_attribute(plugin_xml_handle,node,'n');
      if (_xmlcfg_get_name(plugin_xml_handle,node)=='dir') {
         new_path:=path:+name:+FILESEP;
         list_plugin_files(ordered_files,new_path,plugin_xml_handle,node);
      } else {
         ordered_files[ordered_files._length()]= path:+name;
      }
      node=_xmlcfg_get_next_sibling(plugin_xml_handle,node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   }
}
static void process_plugin_file(_str filename,int i,VSPLUGIN_OTHER_FILE (&other_files)[], bool (&file_not_used_anymore):[],int (&plugin_file_not_used_anymore):[],bool &stopped_on_error) {
   ext := get_extension(filename,true);
   //say(filename);
   if (_file_eq(ext,_macro_ext)) {
      _str temp;
      temp=_plugin_relative_path(filename);
      if (temp!=null) {
         key:=temp;
         _maybe_append(temp, 'x');
         index:=find_index(temp,MODULE_TYPE);
         key=_file_case(key);
         //say('key='key);
         file_not_used_anymore._deleteel(key);
         plugin_file_not_used_anymore._deleteel(key'x');
         doLoad := false;
         if (!index) {
            doLoad=true;
         } else {
            long *pl=def_plugin_other_files._indexin(key);
            if (!pl || *pl!=other_files[i].m_time) {
               /*if (pl) {
                  say(filename);
                  say('old='(*pl));
                  say('new='other_files[i].m_time);
               } */
               doLoad=true;
            }
         }
         if (doLoad) {
            //say('load 'filename);
            //say('new='other_files[i].m_time);
            chdir(_strip_filename(filename,'N'),1);
            //say('load 'filename);
            status:=load(filename);
            if (status) {
               result:=_message_box(nls("Failed to load '%s1'\n\nContinue to load other plugin macros?",filename),'',MB_YESNO);
               if (result==IDNO) {
                  stopped_on_error=true;
                  return;
               }
            }
            def_plugin_other_files:[key]=other_files[i].m_time;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
      }
   }
}
void _plugin_load_all() {
   VSPLUGIN_OTHER_FILE other_files[];
   // List plugin files that are no .cfg.xml files
   _plugin_get_other_files(other_files);
   len := other_files._length();
   int i;
   bool file_not_used_anymore:[];
   foreach (auto k => auto v in def_plugin_other_files) {
      file_not_used_anymore:[k]=true;
   }
   int plugin_file_not_used_anymore:[];
   index:=name_match('',1,MODULE_TYPE|PICTURE_TYPE);
   while (index) {
      name := name_name(index);
      // If this is a plugin relative name
      if (pos('/',name) && _isRelative(name)) {
         plugin_file_not_used_anymore:[_file_case(name)]=index;
      }

      index=name_match('',0,MODULE_TYPE|PICTURE_TYPE);
   }
   PLUGIN_PATH_INFO plugin_xml_files:[];
   stopped_on_error := false;
   for (i=0;i<len;++i) {
      _str filename=other_files[i].m_filename;
      ext := get_extension(filename,true);
      _str name=_plugin_relative_path(filename);
      parse name with auto plugin_root_name ('/');
      plugin_root_name=_file_case(plugin_root_name);
      PLUGIN_PATH_INFO *pinfo=plugin_xml_files._indexin(plugin_root_name);
      if (!pinfo) {
         pinfo=&plugin_xml_files:[plugin_root_name];
         pinfo->m_plugin_xml_filename='';
         pinfo->m_files._makeempty();
      }
      if (_file_eq(ext,'.png') || 
          _file_eq(ext,'.bmp') || 
          _file_eq(ext,'.xpm') || 
          _file_eq(ext,'.ico') || 
          _file_eq(ext,'.jpg') ||
          _file_eq(ext,'.svg') || 
          _file_eq(ext,'.svgz') || 
          _file_eq('plugin.xml',_strip_filename(filename,'P'))
          ) {
         if (_file_eq('plugin.xml',_strip_filename(filename,'P'))) {
            pinfo->m_plugin_xml_filename=filename;
         }
         if (name!=null) {
            key:=_file_case(name);
            //say('key='key);
            file_not_used_anymore._deleteel(key);
            plugin_file_not_used_anymore._deleteel(key);
         }
      } else if (_file_eq(ext,_macro_ext)) {
         PLUGIN_FILE_INFO *pfile= &pinfo->m_files:[_file_case(filename)];
         pfile->m_filename=filename;
         pfile->m_i=i;
      }
   }


   _str orig_cwd=getcwd();
   PLUGIN_PATH_INFO info;
   foreach (auto plugin_root_name=>info in plugin_xml_files) {
      if (info.m_plugin_xml_filename!='') {

         plugin_xml_handle:=_xmlcfg_open(info.m_plugin_xml_filename,auto status);
         int plugin_xml_parent_node=-1;
         if (plugin_xml_handle>=0) {
            plugin_xml_parent_node=_xmlcfg_find_simple(plugin_xml_handle,"/options/plugin/files");
         }
         _str ordered_files[];
         if (plugin_xml_handle>=0 && plugin_xml_parent_node>=0) {
            list_plugin_files(ordered_files,_strip_filename(info.m_plugin_xml_filename,'n'),plugin_xml_handle,plugin_xml_parent_node);
         }
         if (plugin_xml_handle>=0) {
            _xmlcfg_close(plugin_xml_handle);
         }
         for (j:=0;j<ordered_files._length();++j) {
            filename:=ordered_files[j];
            PLUGIN_FILE_INFO *pfile= info.m_files._indexin(_file_case(filename));
            if (pfile) {
               i=pfile->m_i;
               info.m_files._deleteel(_file_case(filename));
               process_plugin_file(filename,i,other_files,file_not_used_anymore,plugin_file_not_used_anymore,stopped_on_error);
               if (stopped_on_error) break;
            }
         }

         PLUGIN_FILE_INFO fileinfo;
         foreach (auto junk=>fileinfo in info.m_files) {
            _str filename=fileinfo.m_filename;
            i=fileinfo.m_i;
            process_plugin_file(filename,i,other_files,file_not_used_anymore,plugin_file_not_used_anymore,stopped_on_error);
            if (stopped_on_error) break;
         }
      }
   }
   //say('len='def_plugin_other_files._length());
   chdir(orig_cwd,1);
   if (!stopped_on_error) {
      foreach (k => auto v2 in file_not_used_anymore) {
         def_plugin_other_files._deleteel(k);
      }
      bool unloaded_macro=false;
      foreach (k => index in plugin_file_not_used_anymore) {
         if (name_type(index)&MODULE_TYPE) {
            //say('unload k='k);
            //trace();
            //int status=_load(_maybe_quote_filename(k),'u');
            //say('status='status);
            unload(k,false,false);
            unloaded_macro=true;
         } else {
            //say('remove pic 'name_name(index));
            // Remove this picture
            delete_name(index);
         }
      }
      if (unloaded_macro) {
         _e_MaybeBuildTagFile(auto tfindex,true,true,true);
      }
   }
}

// Reloads the user.cfg.xml from disk, clearing out any caches
// that would interfere with reloaded settings.
void plugin_reload_user_config() {
   // Reload the user.cfg.xml, user, and system plugin .cfg.xml files
   // This does not update plugin macros
   _plugin_reload_option_levels(1);

   filename_no_quotes:=_ConfigPath():+VSCFGFILE_USER;
   _config_file_dates:[_file_case(filename_no_quotes)]=_file_date(filename_no_quotes,'B');
}

_command void plugin_update() name_info(',') {
   plugin_reload_user_config();
   _plugin_load_all();
}
int _plugin_uninstall(_str pluginName,bool display_error=true,bool updatePlugins=true) {
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG);
      return VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG;
   }
   //say('uninstall 'pluginName);
   _str path;
   path=_strip_filename(pluginName,'N');
   if (path=='') {
      i:=pos('.ver.',pluginName,1,_fpos_case);
      if (i>0) {
         pluginName=substr(pluginName,1,i-1);
      }
      path=VSCFGPLUGIN_DIR:+pluginName;
   }
   //say('h2 path 'path);
   _maybe_append_filesep(path);
   path=absolute(path:+FILESEP,null,true);
   //say('h3 path 'path);
   if (path=='' || _isPluginFileSpec(path)) {
      // Bad argument? Plugin not registered?
      return 0;
   }
   path=substr(path,1,length(path)-1);
   path2:=_strip_filename(path,'N');
   if (path2!='') path2=substr(path2,1,length(path2)-1);
   int status;
   if (_file_eq(get_extension(path2),'zip')) {
      //say('h4 path2 'path2);
      status=delete_file(path2);
   } else {
      //say('h5 path 'path);
      status=_DelTree(path,true);
   }
   if (status && display_error) {
      _message_box(nls('Unable to remove plugin %s1',path));
   }
   if (updatePlugins) {
      plugin_update();
   }
   return status;
}
static bool _plugin_install_error_check(_str path) {
  _maybe_append_filesep(path);
  if (file_exists(path:+'plugin.xml')) {
     return false;
  }
  path=file_match('+t '_maybe_quote_filename(path:+"*.e"),1);
  if (path=='') {
     path=file_match('+t '_maybe_quote_filename(path:+"*.cfg.xml"),1);
     if (path=='') {
        return true;
     }
  }
  return false;
}
int _plugin_install(_str filename, bool check_if_looks_like_plugin=true) {
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG);
      return VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG;
   }
   filename=absolute(filename);
   _maybe_strip_filesep(filename);
   pluginName := _strip_filename(filename,'P');
   ext := get_extension(pluginName);
   is_zip := false;
   if (_file_eq(ext,'zip') || _file_eq(ext,'jar')) {
      pluginName=substr(pluginName,1,length(pluginName)-4);
      is_zip=true;
   }
   i:=pos('.ver.',pluginName,1,_fpos_case);
   if (i>0) {
       if (is_zip) {
          if (!file_exists(filename:+FILESEP:+pluginName)) {
             // Assume this has an unversioned interior directory
             pluginName=substr(pluginName,1,i-1);
          }
       } else {
          pluginName=substr(pluginName,1,i-1);
       }
   }
   status := 0;
   if (is_zip) {
      if (!file_exists(filename:+FILESEP:+pluginName)) {
         if (!file_exists(filename)) {
            _message_box(nls("File '%s1' not found",filename));
            return 1;
         }
         _message_box(nls("Plugin zip file '%s1' has incorrect plugin structure. Missing interior directory",filename));
         return 1;
      }
      unzip := 2; // Auto
      handle:=_xmlcfg_open(filename:+FILESEP:+pluginName:+FILESEP:+'plugin.xml',auto status2);
      if (handle>=0) {
         node:=_xmlcfg_find_simple(handle,'/options/plugin/p');
         if (node>=0) {
            value:=_xmlcfg_get_attribute(handle,node,'unzip');
            if (isinteger(value)) {
               unzip=(int)value;
            }
         }
         _xmlcfg_close(handle);
      }
      // Auto?
      if (unzip==2) {
         if (file_match('+t '_maybe_quote_filename(filename:+FILESEP:+pluginName:+FILESEP:+'*.e'),1)!='') {
            unzip=1;
         } else {
            unzip=0;
         }
      }
      if (check_if_looks_like_plugin) {
         if (_plugin_install_error_check(filename:+FILESEP:+pluginName:+FILESEP)) {
            _message_box(nls("Plugin zip file '%s1' has incorrect plugin struction. plugin.xml is missing",filename));
            return 1;
         }
      }
      _str destination;
      _plugin_uninstall(pluginName,false,false);
      if (unzip) {
         destination=_plugin_get_user_plugins_path();
         _make_path(destination,false);
         status=copyFileTree(filename:+FILESEP,destination);
      } else {
         destination=_plugin_get_user_plugins_path():+_strip_filename(filename,'P');
         _make_path(destination,true);
         status=copy_file(filename,destination);
      }
      if (status) {
         _message_box(nls("Failed to install plugin zip file '%s1' to '%s2'",filename,destination)". "get_message(status));
      }
   } else {
      if (!isdirectory(filename)) {
         _message_box(nls("Plugin file '%s1' is not recognized as a directory or zip file",filename));
         return 1;
      }
      if (check_if_looks_like_plugin) {
         if (_plugin_install_error_check(filename:+FILESEP)) {
            _message_box(nls("Plugin zip file '%s1' has incorrect plugin struction. plugin.xml is missing",filename));
            return 1;
         }
      }
      _str destination;
      destination=_plugin_get_user_plugins_path():+pluginName:+FILESEP;
      _plugin_uninstall(pluginName,false,false);
      _make_path(destination,false);
      status=copyFileTree(filename:+FILESEP,destination);
      if (status) {
         _message_box(nls("Failed to install plugin from '%s1' to '%s2'",filename,destination)". "get_message(status));
      }
   }
   plugin_update();
   return status;
}
