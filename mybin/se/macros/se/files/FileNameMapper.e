////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#endregion

namespace se.files;

#define FILENAME_LIST_ELEMENT       'Filenames'
#define FILENAME_ELEMENT            'Filename'
#define FILE_ATTRIBUTE              'File'
#define LANGUAGE_ATTRIBUTE          'Language'
#define PATTERN_LIST_ELEMENT        'Patterns'
#define PATTERN_ELEMENT             'Pattern'
#define PATTERN_TYPE_ATTRIBUTE      'Type'
#define ANT_PATTERN_ATTRIBUTE       'AntPattern'
#define REGEX_ATTRIBUTE             'Regex'
#define ALL_FILES_ATTRIBUTE         'AppliesToAllFiles'

enum AdvancedFileTypeMapType {
   AFTMT_FILE,
   AFTMT_FILENAME_PATTERN,
   AFTMT_PATH_PATTERN,
   AFTMT_PATTERN,
};

struct FilePattern {
   int Type;
   _str AntPattern;
   _str Regex;
   boolean AllFiles;
   _str Language;
};

/**
 * Maps filenames to languages.
 * 
 */
class FileNameMapper {
   // table mapping absolute file names to languages
   _str m_files:[];
   // array of FilePatterns in order of precedence
   FilePattern m_patterns[];

   FileNameMapper()
   {
      m_files._makeempty();
      m_patterns._makeempty();
   }

   public void init(boolean forceRebuildRegex)
   {
      updateMap(forceRebuildRegex);
   }

   private void updateMap(boolean forceRebuildRegex = false)
   {
      // make a simplified list of the patterns - the C++ code doesn't 
      // need all the data
      FILELANGMAP_FILEPATTERN simpleList[];
      buildSimpleMap(simpleList, forceRebuildRegex);

      _file_name_map_update_maps(m_files, simpleList);
   }

   public void getSimpleMaps(_str (&pathMap):[], FILELANGMAP_FILEPATTERN (&patternMap)[])
   {
      // make a simplified list of the patterns - the C++ code doesn't 
      // need all the data
      buildSimpleMap(patternMap, false);
      pathMap = m_files;
   }

   private void buildSimpleMap(FILELANGMAP_FILEPATTERN (&simpleList)[], boolean forceRebuildRegex)
   {
      // make a simplified list of the patterns - the C++ code doesn't 
      // need all the data
      for (i := 0; i < m_patterns._length(); i++) {
         // make sure we have a regex for this pattern - if we have not attempted to
         // match this pattern with anything yet, we might not have built the regex
         if (forceRebuildRegex || m_patterns[i].Regex == '' || m_patterns[i].Regex == null) {
            m_patterns[i].Regex = antToRegex(m_patterns[i].AntPattern);
         }

         FILELANGMAP_FILEPATTERN simple;
         simple.m_regex = m_patterns[i].Regex;
         simple.m_langId = m_patterns[i].Language;

         simpleList[i] = simple;
      }
   }

   /**
    * Attempts to map a file to a language.
    * 
    * @param file                   absolute filename of file
    * 
    * @return _str                  lang id of associated language, '' if none 
    *                               was found
    */
   public _str mapFilenameToLanguage(_str file)
   {
      return _file_name_map_file_to_language(file);
   }

   /**
    * Converts an Ant pattern to a SlickEdit regular expression.
    * 
    * @param antPattern             Ant pattern (uses ?, *, and **)
    * 
    * @return _str                  SlickEdit regular expression which matches 
    *                               the Ant pattern
    */
   private _str antToRegex(_str antPattern)
   {
      startAt := 1;
      regex := '';
      regexFilesep := _escape_re_chars(FILESEP, 'R');
   
      // special case - see if we have FILESEP** at the end
      endsWithAnyDir := false;
      if (substr(antPattern, length(antPattern) - 2) == FILESEP'**') {
         // mark this and strip off the special stuff - we'll add handling for 
         // it at the very end
         endsWithAnyDir = true;
         antPattern = substr(antPattern, 1, length(antPattern) - 3);
      }
   
      starPos := pos('*', antPattern, startAt);
      if (!starPos) {
         // no stars, so just escape everything else
         regex =  _escape_re_chars(antPattern);
      } else {
      
         while (starPos) {
            // get what comes before this star
            before := '';
            if (starPos != 1) {
               before = substr(antPattern, startAt, starPos - startAt);
               before = _escape_re_chars(before, 'R');
            }

            middle := '';
      
            // get the next character after this one
            nextChar := substr(antPattern, starPos + 1, 1, '');
            if (nextChar == '*') {
               // we have a double star
               nextNextChar := substr(antPattern, starPos + 2, 1, '');
               if (nextNextChar == FILESEP) {
                  // we have a directory match, let's go with it
                  //middle = '(?@'regexFilesep')@';
                  middle = '?@'regexFilesep;
                  startAt = starPos + 3;
               } else {
                  // we have no idea what this is, just move along
                  middle = _escape_re_chars('**', 'R');
                  startAt = starPos + 2;  
               }
            } else {
               // just one star - this is a filename wildcard - means any 
               // character except for a file separator
               middle = '[~'regexFilesep']@';
               startAt = starPos + 1;
            }
      
            regex :+= before :+ middle;
            starPos = pos('*', antPattern, startAt);
         }
   
         // add whatever is left
         remainder := substr(antPattern, startAt);
         regex :+= _escape_re_chars(remainder, 'R');
      }
   
      // add a special something for FILESEP** - we can have any 
      // number of directories at the end of this
      if (endsWithAnyDir) {
         regex = regex :+ '('regexFilesep'?@)@';
      }
   
      // add the start and end line symbols
      regex = '^'regex'$';
   
      return regex;
   }

   /**
    * Retrieves the info used to map files to languages.
    * 
    * @param fileMap                a hashtable mapping exact filenames to 
    *                               language ids
    * @param patterns               an array of FilePatterns in order of 
    *                               precedence
    */
   public void getLists(_str (&fileMap):[], FilePattern (&patterns)[])
   {
      fileMap = m_files;
      patterns = m_patterns;
   }

   /**
    * Sets the info used to map files to languages.
    * 
    * @param fileMap                a hashtable mapping exact filenames to 
    *                               language ids
    * @param patterns               an array of FilePatterns in order of 
    *                               precedence
    */
   public void setLists(_str (&fileMap):[], FilePattern (&patterns)[])
   {
      m_files = fileMap;
      m_patterns = patterns;

      updateMap();
   }

   /**
    * Adds one file to language mapping to our table.  If the file is already 
    * mapped to another language, we overwrite the existing mapping. 
    * 
    * @param file                   absolute file name we want to map to a language
    * @param langId                 language id of language to map to
    */
   public void addFileMap(_str file, _str langId)
   {
      // just checking
      if (file == '' || langId == '') return;

      m_files:[file] = langId;

      updateMap();
   }

   /**
    * Inserts one pattern to our list at the specified position.  If the pattern 
    * matches exactly to a pattern that is already in the list, the existing 
    * pattern is deleted and the new pattern is added in the given position. 
    * 
    * @param pattern                FilePattern to be added to our list
    * @param position               position in the list to insert the new pattern, 
    *                               -1 to add it to the end of the list.  If an
    *                               invalid position is sent in, the item will be
    *                               added to the end of the list.
    * @return 
    */
   public void addPatternMap(FilePattern &pattern, int position = -1)
   {
      // safety!
      if (pattern.AntPattern == '' || pattern.Language == '') return;

      // does this pattern already exist?  if so, delete the older one
      checkForExistingPattern(pattern, true);

      // check for some invalid values
      if (position < 0 || position > m_patterns._length()) {
         position = -1;
      }

      if (position > 0) {
         // put it where the user told us to
         m_patterns._insertel(pattern, position);
      } else {
         // just shove it at the end, no biggie.
         m_patterns[m_patterns._length()] = pattern;
      }

      updateMap();
   }

   /**
    * Checks the list of patterns to see if a pattern matching the 
    * given pattern's AntPattern already exists.  Can optionally 
    * delete the existing pattern. 
    * 
    * @param pattern                   pattern to look for
    * @param deleteExisting            true to delete the existing 
    *                                  pattern, false otherwise
    * 
    * @return boolean                  true if pattern was found
    */
   private boolean checkForExistingPattern(FilePattern &pattern, boolean deleteExisting)
   {
      // go through our list and make sure this doesn't already match something else
      for (i := 0; i < m_patterns._length(); i++) {
         // compare the ant pattern values - that's what counts
         if (m_patterns[i].AntPattern == pattern.AntPattern) {
            // we have a match!  maybe delete the old one
            if (deleteExisting) {
               m_patterns._deleteel(i);
            }
            break;
         }
      }

      return (i < m_patterns._length());
   }

   /**
    * Exports the file and pattern mappings to an XML file.
    * 
    * @param xmlFilename            name of xml file where data will go
    * 
    * @return int                   0 if export was successful, < 0 if there was 
    *                               an error
    */
   public int exportMap(_str xmlFilename)
   {
      // create the file here
      xmlHandle := _xmlcfg_create(xmlFilename, VSENCODING_UTF8);
      if (xmlHandle < 0) {
         return xmlHandle;
      }

      do {
   
         mapNode := _xmlcfg_add(xmlHandle, TREE_ROOT_INDEX, 'FileNameMap', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
         if (mapNode < 0) break;
   
         // first add the list of directly mapped files      
         if (m_files._length()) {
            listNode := _xmlcfg_add(xmlHandle, mapNode, FILENAME_LIST_ELEMENT, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
            if (listNode < 0) break;

            _str filename, langId;
            foreach (filename => langId in m_files) {
               node := _xmlcfg_add(xmlHandle, listNode, FILENAME_ELEMENT, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
               if (node < 0) break;

               _xmlcfg_add_attribute(xmlHandle, node, FILE_ATTRIBUTE, filename);
               _xmlcfg_add_attribute(xmlHandle, node, LANGUAGE_ATTRIBUTE, langId);
            }
         }
   
         // and now our patterns, please
         if (m_patterns._length()) {
            listNode := _xmlcfg_add(xmlHandle, mapNode, PATTERN_LIST_ELEMENT, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
            if (listNode < 0) break;

            FilePattern pattern;
            foreach (pattern in m_patterns) {
               node := _xmlcfg_add(xmlHandle, listNode, PATTERN_ELEMENT, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
               if (node < 0) break;

               _xmlcfg_add_attribute(xmlHandle, node, PATTERN_TYPE_ATTRIBUTE, pattern.Type);
               _xmlcfg_add_attribute(xmlHandle, node, ANT_PATTERN_ATTRIBUTE, pattern.AntPattern);
               _xmlcfg_add_attribute(xmlHandle, node, LANGUAGE_ATTRIBUTE, pattern.Language);
               _xmlcfg_add_attribute(xmlHandle, node, ALL_FILES_ATTRIBUTE, pattern.AllFiles);
   
               if (pattern.Regex != '') {
                  _xmlcfg_add_attribute(xmlHandle, node, REGEX_ATTRIBUTE, pattern.Regex);
               }
            }
         }

         // we made it!  so save it
         _xmlcfg_save(xmlHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);

      } while (false);

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
   public int importMap(_str xmlFilename)
   {
      // see if we can open it
      xmlHandle := _xmlcfg_open(xmlFilename, auto status);
      if (xmlHandle < 0) {
         return xmlHandle;
      }

      // search for our list of files
      listNode := _xmlcfg_find_simple(xmlHandle, '//'FILENAME_LIST_ELEMENT);
      if (listNode > 0) {

         // go through all the children - which should be file to language mappings
         child := _xmlcfg_get_first_child(xmlHandle, listNode);
         while (child > 0) {
            file := _xmlcfg_get_attribute(xmlHandle, child, FILE_ATTRIBUTE);
            language := _xmlcfg_get_attribute(xmlHandle, child, LANGUAGE_ATTRIBUTE);

            // we found something worth saving
            if (file != '' && language != '') {
               // we might need to switch some fileseps, if this is on a different system
               file = stranslate(file, FILESEP, FILESEP2);

               m_files:[file] = language;
            }

            // go to the next one then
            child = _xmlcfg_get_next_sibling(xmlHandle, child);
         }
      }

      // now we look for our patterns
      listNode = _xmlcfg_find_simple(xmlHandle, '//'PATTERN_LIST_ELEMENT);
      if (listNode > 0) {

         // go through all the children - which should be patterns
         child := _xmlcfg_get_first_child(xmlHandle, listNode);
         while (child > 0) {
            type := _xmlcfg_get_attribute(xmlHandle, child, PATTERN_TYPE_ATTRIBUTE);
            antPattern := _xmlcfg_get_attribute(xmlHandle, child, ANT_PATTERN_ATTRIBUTE);
            regex := _xmlcfg_get_attribute(xmlHandle, child, REGEX_ATTRIBUTE);
            allFiles := (_xmlcfg_get_attribute(xmlHandle, child, ALL_FILES_ATTRIBUTE, 'False') == 'True');
            language := _xmlcfg_get_attribute(xmlHandle, child, LANGUAGE_ATTRIBUTE);

            // make sure we have something worth saving
            if (type != '' && antPattern != '' && language != '') {
               FilePattern pattern;
               pattern.Type = (int)type;

               // maybe switch some fileseps?
               pattern.AntPattern = stranslate(antPattern, FILESEP, FILESEP2);
               if (pattern.AntPattern == antPattern) {
                  // only use this regex if the fileseps were the same - 
                  // otherwise we will rebuild it on our own
                  pattern.Regex = regex;
               }
               pattern.Language = language;
               pattern.AllFiles = allFiles;

               // go through our existing patterns to see if this one already exists
               if (!checkForExistingPattern(pattern, false)) {
                  m_patterns[m_patterns._length()] = pattern;
               }
            }

            // go to the next one
            child = _xmlcfg_get_next_sibling(xmlHandle, child);
         }
      }

      // tidy everything up
      _xmlcfg_close(xmlHandle);

      updateMap();

      return 0;
   }
}
