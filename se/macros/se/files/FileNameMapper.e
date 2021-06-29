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
#include "xml.sh"
#import "stdprocs.e"
#import "cfg.e"
#endregion

namespace se.files;

static const FILENAME_LIST_ELEMENT=       'Filenames';
static const FILENAME_ELEMENT=            'Filename';
static const FILE_ATTRIBUTE=              'File';
static const LANGUAGE_ATTRIBUTE=          'Language';
static const PATTERN_LIST_ELEMENT=        'Patterns';
static const PATTERN_ELEMENT=             'Pattern';
static const PATTERN_TYPE_ATTRIBUTE=      'Type';
static const ANT_PATTERN_ATTRIBUTE=       'AntPattern';
static const REGEX_ATTRIBUTE=             'Regex';
static const ALL_FILES_ATTRIBUTE=         'AppliesToAllFiles';

enum AdvancedFileTypeMapType {
   AFTMT_FILE,
   AFTMT_FILENAME_PATTERN,
   AFTMT_PATH_PATTERN,
   AFTMT_PATTERN,
};


/*
IMPORTANT: Since this struct is used to convert the old 
def_file_name_mapper variable, don't change it. Better
to make a new structure or just don't use this.
*/
struct FilePattern {
   int Type;
   _str AntPattern;
   _str Regex;
   bool AllFiles;
   _str Language;
};
/**
 * Maps filenames to languages.
 * 
 */
class FileNameMapper {
   // table mapping absolute file names to languages
   _str m_files:[];  // Sadly this is here only so vusrdefs.e will compile
   // array of FilePatterns in order of precedence
   FilePattern m_patterns[];  // Sadly this is here only so vusrdefs.e will compile

   FileNameMapper() {
   }
   static private void fetch_position_info(int (&hash_position):[],int &largest=0) {
      hash_position._makeempty();

      largest=0;
      handle:=_plugin_get_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_FILE_MAPPINGS,1);
      if (handle<0) return;
      hash_position._makeempty();
      typeless array[];
      _xmlcfg_find_simple_array(handle,"/profile/p",array);
      for (i:=0;i<array._length();++i) {
         int node=array[i];
         // langid;pattern
         combo:=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME);
         index:=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE);
         if (isinteger(index)) {
            if (index>largest) {
               largest=index;
            }
            hash_position:[combo]=index;
         }
      }
      _xmlcfg_close(handle);
   }
   static public void convertFromOldMapVariables(_str (&files):[],FilePattern (&patterns)[]) {
      /*if (files._length() || patterns._length())*/ {
         int handle=_xmlcfg_create('',VSENCODING_UTF8);
         int parent_node=_xmlcfg_set_path(handle,"/profile");
         _xmlcfg_set_attribute(handle,parent_node,VSXMLCFG_PROFILE_NAME,_plugin_append_profile_name(VSCFGPACKAGE_MISC,VSCFGPROFILE_FILE_MAPPINGS));
         _xmlcfg_set_attribute(handle,parent_node,VSXMLCFG_PROFILE_VERSION,VSCFGPROFILE_FILE_MAPPINGS_VERSION);
         _str filename, langid;
         /*
            Fetch existing position info.
         */
         int hash_position:[];
         last_position := 0;
         fetch_position_info(hash_position);
         foreach (filename => langid in files) {
            add_xml_item(handle,parent_node,filename,langid,last_position,hash_position);
         }
         FilePattern pattern;
         foreach (pattern in patterns) {
            add_xml_item(handle,parent_node,pattern.AntPattern,pattern.Language,last_position,hash_position);
         }
         _plugin_set_profile(handle);
         _xmlcfg_close(handle);
         updateMap();
      }
   }

   static private void updateMap() {
      _file_name_map_update_maps();
   }

   /**
    * Retrieves the info used to map files to languages.
    * 
    * @param fileMap                a hashtable mapping exact filenames to 
    *                               language ids
    * @param patterns               an array of FilePatterns in order of 
    *                               precedence
    */
   static public void getLists(FilePattern (&patterns)[])
   {
       patterns._makeempty();

       int handle=_plugin_get_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_FILE_MAPPINGS);
       if (handle>=0) {
          profile_node:=_xmlcfg_get_document_element(handle);
          _xmlcfg_sort_on_attribute(handle,profile_node,VSXMLCFG_PROPERTY_VALUE,'n');
          typeless array[];
          _xmlcfg_find_simple_array(handle,"/profile/p",array);
          for (i:=0;i<array._length();++i) {
             parse _xmlcfg_get_attribute(handle,array[i],VSXMLCFG_PROPERTY_NAME) with auto langid';'auto pattern;
             FilePattern info;
             if (_isWindows()) {
                pattern = stranslate(pattern, FILESEP, '/');
             }
             info.Type=AFTMT_PATTERN;
             info.AntPattern=pattern;
             info.Regex='';
             info.AllFiles=false;
             info.Language=langid;
             patterns[patterns._length()]=info;
          }
          _xmlcfg_close(handle);
       }


   }

   /**
    * Sets the info used to map files to languages.
    * 
    * @param fileMap                a hashtable mapping exact filenames to 
    *                               language ids
    * @param patterns               an array of FilePatterns in order of 
    *                               precedence
    */
   static public void setLists(FilePattern (&patterns)[])
   {
      convertFromOldMapVariables(null,patterns);
   }
   /**
    * Adds one file to language mapping to our table.  If the file is already 
    * mapped to another language, we overwrite the existing mapping. 
    * 
    * @param file                   absolute file name we want to map to a language
    * @param langId                 language id of language to map to
    */
   static public void addFileMap(_str file, _str langId)
   {
      // just checking
      if (file == '' || langId == '') return;
      addAntPattern(file,langId);

      updateMap();
   }

   static public void addPatternMap(FilePattern &pattern) {
      // safety!
      if (pattern.AntPattern == '' || pattern.Language == '') return;
      addAntPattern(pattern.AntPattern,pattern.Language);
   }
   /**
    * Add another ant pattern if it does not already exists.
    * 
    * @param pattern               Ant pattern to add.
    * @param langid                Map matches to this langid
    * @return 
    */
   static public void addAntPattern(_str pattern,_str langid) {
      int hash_position:[];
      int largest;
      if (_isWindows()) {
         pattern = stranslate(pattern, '/', FILESEP);
      }
      fetch_position_info(hash_position,largest);
      _plugin_set_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_FILE_MAPPINGS,VSCFGPROFILE_FILE_MAPPINGS_VERSION,langid';'pattern,largest+1);
      updateMap();
   }

   /**
    * Exports the file and pattern mappings to an XML file.
    * 
    * @param xmlFilename            name of xml file where data will go
    * 
    * @return int                   0 if export was successful, < 0 if there was 
    *                               an error
    */
   static public int exportMap(_str xmlFilename) {
      // create the file here
      xmlHandle := _xmlcfg_create(xmlFilename, VSENCODING_UTF8);
      if (xmlHandle < 0) {
         return xmlHandle;
      }

      // and now our patterns, please
      mapNode := _xmlcfg_add(xmlHandle, TREE_ROOT_INDEX, 'FileNameMap', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      listNode := _xmlcfg_add(xmlHandle, mapNode, PATTERN_LIST_ELEMENT, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);

      FilePattern patterns[];
      getLists(patterns);
      for (i:=0;i<patterns._length();++i) {
         node := _xmlcfg_add(xmlHandle, listNode, PATTERN_ELEMENT, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
         if (node < 0) break;
         //parse _xmlcfg_get_attribute(handle,array[i],VSXMLCFG_PROPERTY_NAME) with auto langid';'auto pattern;
         _xmlcfg_add_attribute(xmlHandle, node, ANT_PATTERN_ATTRIBUTE, patterns[i].AntPattern);
         _xmlcfg_add_attribute(xmlHandle, node, LANGUAGE_ATTRIBUTE, patterns[i].Language);
      }
      // we made it!  so save it
      _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);

      // tidy everything up now
      _xmlcfg_close(xmlHandle);

      return 0;
   }

   /**
    * Imports the file and pattern mappings from an XML file.
    * 
    * @param xmlFilename            name of xml file where data is kept
    * 
    * @return int                   0 if import was successful, < 0 if there was
    *                               an error
    */
   static public int importMap(_str xmlFilename) {
      // see if we can open it
      xmlHandle := _xmlcfg_open(xmlFilename, auto status);
      if (xmlHandle < 0) {
         return xmlHandle;
      }
      FilePattern patterns[];

      // now we look for our patterns
      listNode := _xmlcfg_find_simple(xmlHandle, '//'PATTERN_LIST_ELEMENT);
      if (listNode > 0) {

         // go through all the children - which should be patterns
         child := _xmlcfg_get_first_child(xmlHandle, listNode);
         while (child > 0) {
            type := _xmlcfg_get_attribute(xmlHandle, child, PATTERN_TYPE_ATTRIBUTE);
            antPattern := _xmlcfg_get_attribute(xmlHandle, child, ANT_PATTERN_ATTRIBUTE);
            regex := _xmlcfg_get_attribute(xmlHandle, child, REGEX_ATTRIBUTE);
            allFiles := (_xmlcfg_get_attribute(xmlHandle, child, ALL_FILES_ATTRIBUTE, 'False') == 'True');
            langid := _xmlcfg_get_attribute(xmlHandle, child, LANGUAGE_ATTRIBUTE);

            if (type!='' || regex!='') {
               if (endsWith(antPattern,'**')) {
                  antPattern:+=FILESEP:+"*.";
               }
               if (endsWith(antPattern,'*')) {
                  antPattern:+=".";
               }
            }
            FilePattern info;
            info.Type=AFTMT_PATTERN;
            info.AntPattern=antPattern;
            info.Regex='';
            info.AllFiles=false;
            info.Language=langid;
            patterns[patterns._length()]=info;

            // go to the next one
            child = _xmlcfg_get_next_sibling(xmlHandle, child);
         }
      }

      // tidy everything up
      _xmlcfg_close(xmlHandle);
      setLists(patterns);

      updateMap();

      return 0;
   }
   static private void add_xml_item(int handle,int parent_node,_str pattern,_str langid,int &last_position,int (&hash_position):[]) {
      // Normalize the file to use forward slashes
      if (_isWindows()) {
         pattern = stranslate(pattern, '/', FILESEP);
      }
      combo:=langid';'pattern;

      _plugin_next_position(combo,last_position,hash_position);
      node:=_xmlcfg_add(handle,parent_node,'p',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);

      _xmlcfg_set_attribute(handle,node,VSXMLCFG_PROPERTY_NAME,combo);
      _xmlcfg_set_attribute(handle,node,VSXMLCFG_PROPERTY_VALUE,last_position);
   }
}

