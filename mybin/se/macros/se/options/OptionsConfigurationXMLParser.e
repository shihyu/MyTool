////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49147 $
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
#import "main.e"
#import "stdprocs.e"
#require "se/vc/VersionControlSettings.e"
#require "se/datetime/DateTime.e"
#endregion Imports

namespace se.options;

using se.vc.VersionControlSettings;
using namespace se.datetime;

#define LANGUAGE_ATTRIBUTE          'Language'
#define VC_PROVIDER_ATTRIBUTE       'VCProvider'

/**
 * Used with the Options History - the choices which the user 
 * can use to search for options that were changed. 
 */
enum_flags DateChangedWhenFlags {
   DC_TODAY,
   DC_YESTERDAY,
   DC_WITHIN_LAST_WEEK,
   DC_WITHIN_LAST_MONTH,
   DC_EVER,
};

/**
 * Used to define the way a particular setting was changed. 
 * This is used in the history to display additional info to the 
 * user. 
 */
enum OptionsChangeMethod {
   OCM_CONFIGURATION,
   OCM_IMPORT,
};

/**
 * Information about a protected setting.
 */
struct ProtectedSetting {
   _str Path;
   _str ProtectionCode;
};

class OptionsConfigurationXMLParser {
   
   // handle to the XML options configuration file in the user's config dir
   private int m_xmlConfigHandle = 0;
   // the name of the XML file user config
   private _str m_xmlConfigFile = 'optionsConfig.xml';
   
   /**
    * Constructor.  Doesn't initialize anything yet, as we don't have an XML DOM
    * to work with. 
    */
   OptionsConfigurationXMLParser()
   { }

   /**
    * Initializes the user's options configuration file.  This file
    * keeps up with their favorites and options history.  If the 
    * file does not yet exist for this user, it is created. 
    * 
    * @return boolean      success of opening XML file and creating 
    *                      DOM
    */
   public boolean init()
   {
      // get xml file from user's config directory
      file := _ConfigPath();
      _maybe_append_filesep(file);
      file :+= m_xmlConfigFile;

      // if file does not exist, then we create a new one
      int status;
      if (file_exists(file)) {
         m_xmlConfigHandle = _xmlcfg_open(file, status, 0, VSENCODING_UTF8);
         if (m_xmlConfigHandle > 0) {
            checkForOldTimeStyle();
         } else {
            // something is wrong with this file.  we need to cut our losses now
            delete_file(file);
         }
      }

      // return our success
      return (m_xmlConfigHandle > 0);
   }
   
   /**
    * Creates the user's configuration xml file for options.
    */
   private void createXMLConfigFile()
   {
      file := _ConfigPath();
      _maybe_append_filesep(file);
      file :+= m_xmlConfigFile;

      m_xmlConfigHandle = _xmlcfg_create(file, VSENCODING_UTF8);
      _xmlcfg_add(m_xmlConfigHandle, TREE_ROOT_INDEX, 'xml version="1.0" encoding="UTF-8"', 
                  VSXMLCFG_NODE_XML_DECLARATION, VSXMLCFG_ADD_AS_CHILD);
   }

   /**
    * Reads the favorites from the configuration xml.  Returns the favorite info 
    * hashed by the options caption path stored in the configuration file. 
    * 
    * @param faves         table of favorites
    */
   public void readFavorites(_str (&faves):[])
   {
      readOptionsConfigurationNodes('Favorites', faves);
   }
   
   /**
    * Reads the protections from the configuration xml.  Returns 
    * the protection info hashed by the options caption path stored 
    * in the configuration file. 
    * 
    * @param items          table of protections
    */
   public void readProtectedItems(ProtectedSetting (&items):[])
   {
      readOptionsConfigurationNodes('Protections', items);
   }
   
   /**
    * Callback to parse a Protected Setting from the options 
    * configuration file given the index of the node. 
    * 
    * @param index          index of node containing info
    * 
    * @return               ProtectedSetting defined by the given 
    *                       node
    */
   private ProtectedSetting parseProtectedSetting(int index)
   {
      ProtectedSetting ps;
      ps.Path = _xmlcfg_get_attribute(m_xmlConfigHandle, index, 'Path');
      ps.ProtectionCode = _xmlcfg_get_attribute(m_xmlConfigHandle, index, 'ProtectionCode');
      
      return ps;
   }
   
   /**
    * Retrieves a list of protections containing a given subpath.
    * 
    * @param subpath        subpath that we're looking for
    * @param paths          list of protected paths containing the 
    *                       subpath
    */
   public void getProtectedPathsContainingSubpath(_str subpath, _str (&paths)[])
   {
      // find the list in the config file
      index := _xmlcfg_find_simple(m_xmlConfigHandle, '//Protections');
      if (index < 0) {
         paths = null;
         return;
      }

      ss := "//@Path[contains(.,'"subpath"')]";
      _xmlcfg_find_simple_array(m_xmlConfigHandle, ss, paths, index, VSXMLCFG_FIND_VALUES);
   }

   /**
    * Determines if the user configuration file has been created.
    * 
    * @return true if file has been created, false otherwise
    */
   private boolean doesXMLConfigFileExist()
   {
      return (m_xmlConfigHandle > 0);
   }

   /**
    * Reads the configuration nodes under the given group title and 
    * loads them into the given table. 
    * 
    * @param groupTitle                 title of parent node which 
    *                                   contains the nodes we want
    * @param table                      hashtable containing data 
    *                                   we are reading
    * @param parseConfigCallback        optional callback to parse 
    *                                   the data, otherwise, only
    *                                   the Path attribute is read
    */
   private void readOptionsConfigurationNodes(_str groupTitle, typeless (&table):[])
   {
      // we got nothing
      if (!doesXMLConfigFileExist()) return;

      // find the list in the config file
      index := _xmlcfg_find_simple(m_xmlConfigHandle, '//'groupTitle);

      // go through each node in the list
      if (index > 0) {

         // grab each item
         index = _xmlcfg_get_first_child(m_xmlConfigHandle, index);
         i := 0;
         while (index > 0) {
            
            // each configuration item has a path to map it to the regular XML
            path := strip(_xmlcfg_get_attribute(m_xmlConfigHandle, index, 'Path'));

            if (path != '') {
               // if there is no parsing callback, we just save the path
               switch (groupTitle) {
               case 'Protections':
                  table:[path] = parseProtectedSetting(index);
                  break;
               default:
                  table:[path] = path;
                  break;
               }
            }
            index = _xmlcfg_get_next_sibling(m_xmlConfigHandle, index);
         }
      }
   }

   /**
    * Writes the special configuration nodes to the user's options configuration 
    * file. 
    * 
    * @param groupTitle                     XML element type that should be the 
    *                                       parent of these nodes
    * @param itemTitle                      XML element type that should be the 
    *                                       type of these nodes
    * @param table                          table of objects containing data to 
    *                                       be written
    * @param writeConfigCallback            optional callback that will contain 
    *                                       code to write the individual node,
    *                                       otherwise the object in table should
    *                                       be a string that will be written as
    *                                       the Path attribute
    */
   private void writeOptionsConfigurationNodes(_str groupTitle, _str itemTitle, typeless (&table):[])
   {
      weHaveItems := !table._isempty();

      if (!doesXMLConfigFileExist()) {
         if (!weHaveItems) return;

         // create the xml config file - we need it NOW
         createXMLConfigFile();
      }

      // find favorites list in the config file - create it if it's not there
      groupIndex := _xmlcfg_find_simple(m_xmlConfigHandle, '//'groupTitle);
      if (groupIndex < 0) {
         if (!weHaveItems) return;

         groupIndex = _xmlcfg_add(m_xmlConfigHandle, TREE_ROOT_INDEX, groupTitle, 
                             VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      } else {
         // delete any existing children
         _xmlcfg_delete(m_xmlConfigHandle, groupIndex, weHaveItems);
      }

      // go through our list and add them all
      typeless writeObject;
      foreach (writeObject in table) {

         // add our new favorite
         itemIndex := _xmlcfg_add(m_xmlConfigHandle, groupIndex, itemTitle, 
                             VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
         
         switch (itemTitle) {
         case 'Protection':
            writeProtectedSetting(itemIndex, writeObject);
            break;
         default:
            // just write the path
            _xmlcfg_add_attribute(m_xmlConfigHandle, itemIndex, 'Path', writeObject);
            break;
         }
      }
   }
   
   /**
    * Writes the list of favorites to XML.  Rather than keeping up
    * with additions and deletions of favorites as they occur, we
    * keep them in the favorites list and write them to XML at the end. 
    */
   public void writeFavorites(_str (&favorites):[])
   {
      writeOptionsConfigurationNodes('Favorites', 'Favorite', favorites);   
   }

   /**
    * Writes the list of protections to XML.  Rather than keeping 
    * up with additions and deletions of protections as they occur,
    * we keep them in the protections list and write them to XML at
    * the end. 
    */
   public void writeProtections(ProtectedSetting (&protections):[])
   {
      writeOptionsConfigurationNodes('Protections', 'Protection', protections);   
   }
   
   /** 
    * Callback to write the ProtectedSetting information to XML.
    * 
    * @param itemIndex          index where ProtectedSetting
    *                           information should be written to
    *                           XML
    * @param ps                 ProtectedSetting to be written
    */
   private void writeProtectedSetting(int itemIndex, ProtectedSetting ps)
   {
      _xmlcfg_add_attribute(m_xmlConfigHandle, itemIndex, 'Path', ps.Path);
      _xmlcfg_add_attribute(m_xmlConfigHandle, itemIndex, 'ProtectionCode', ps.ProtectionCode);
   }
   
   /**
    * Closes connections with XML files, doing any saving that
    * needs to be done.
    * 
    */
   public void close()
   {
      // save the close the Config DOM
      if (m_xmlConfigHandle > 0 && doesXMLConfigFileExist()) {
         _xmlcfg_save(m_xmlConfigHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
         _xmlcfg_close(m_xmlConfigHandle);
      }

      // reset
      m_xmlConfigHandle = 0;
   }

   /**
    * Builds a list of options that have been changed in the time
    * span defined by the input parameter.
    * 
    * @param changeFlags      a DateChangedWhenFlag signifying what
    *                         dates we are looking for
    * 
    * @return                 array of options matching the dates
    */
   public void buildOptionsHistory(int changeFlags, _str (&history)[])
   {
      if (!doesXMLConfigFileExist()) return;

      historyIndex := _xmlcfg_find_simple(m_xmlConfigHandle, '//History');

      if (historyIndex > 0) {

         // build an impressive regex and search for it
         regex := buildDateChangedRegex(changeFlags);
         searchStr := '//Option'XPATH_CONTAINS('DateChanged', regex, 'R');
         _xmlcfg_find_simple_array(m_xmlConfigHandle, searchStr, history, historyIndex);
   
         int i;
         for (i = 0; i < history._length(); i++) {
            index := (int)history[i];

            // now retrieve the path
            path := _xmlcfg_get_attribute(m_xmlConfigHandle, index, "Path");

            if (path == '') continue;

            // check for language or version control replacements
            origPath := path;
            fillInLanguageOrVersionControlName(path, LANGUAGE_ATTRIBUTE);
            if (origPath == path) {
               fillInLanguageOrVersionControlName(path, VC_PROVIDER_ATTRIBUTE);
            }

            // parse out the caption
            lastBrace := lastpos('>', path);
            caption := strip(substr(path, lastBrace + 1));
            path = strip(substr(path, 1, lastBrace - 1));

            // retrieve the time
            time := _xmlcfg_get_attribute(m_xmlConfigHandle, index, "DateChanged");

            // this should be an integer, but sometimes we run into old configurations with strings
            typeless method = _xmlcfg_get_attribute(m_xmlConfigHandle, index, "ChangeMethod", OCM_CONFIGURATION);
            if (isinteger(method)) {            
               method = configurationMethodToString((int)method);
            }
            
            // compile our list
            history[i] = caption\tpath\ttime\tmethod;
         }
      }

   }

   /**
    * Searches for a VCProvider or Langauge indicator string and then replaces that 
    * ID with the actual vc provider name or language mode name. 
    * 
    * @param path                path to check for language or version control 
    *                            provider
    * @param searchString        search string to look for that will indicate the 
    *                            presence of language of vc provider
    */
   private void fillInLanguageOrVersionControlName(_str &path, _str searchString)
   {
      attrPos := pos(searchString'=', path);
      if (attrPos) {
         // extract the language ID
         beforeSection := strip(substr(path, 1, attrPos - 1));
         afterSection := '';
         section := '';

         brackPos := pos('>', path, attrPos);
         if (!brackPos) {
            section = strip(substr(path, attrPos));
         } else {
            section = strip(substr(path, attrPos, brackPos - attrPos));
            afterSection = strip(substr(path, brackPos));
         }

         _str id;
         parse section with searchString'='id;
         switch (searchString) {
         case LANGUAGE_ATTRIBUTE:
            if (id == ALL_LANGUAGES_ID) {
               id = 'All Languages';
            } else {
               id = _LangId2Modename(id);
            }
            if (id != '') section = id;
            break;
         case VC_PROVIDER_ATTRIBUTE:
            id = VersionControlSettings.getProviderName(id);
            if (id != '') section = id;
            break;
         }

         path = beforeSection' 'section' 'afterSection;
      }
   }

   /**
    * Translates a member of the OptionsChangeMethod enum into a 
    * string that can be displayed in the Options History. 
    * 
    * @param method        member of OptionsChangeMethod enum
    * 
    * @return              string representation of method
    */
   private _str configurationMethodToString(int method)
   {
      text := '';
      
      switch (method) {
      case OCM_CONFIGURATION:
         text = 'User Configuration';
         break;
      case OCM_IMPORT:
         text = 'Option Import';
         break;
      }
      
      return text;
   }
   
   /**
    * Builds a regex to search the XML DOM for DateChanged values.
    * 
    * @param changeFlags   a set of flags defining the range of time
    *                      we want to search for as it relates to
    *                      now
    * 
    * @return              the search regex.
    */
   private _str buildDateChangedRegex(int changeFlags)
   {
      // this is easy - as long as it's 17 numbers
      if (changeFlags == DC_EVER) {
         return '';
      }

      // otherwise, we compile a range
      // TODAY -                 today, 0:0:0 - today, now
      // YESTERDAY               (today - 1), 0:0:0: - (today - 1), 23:59:999
      // WITHIN LAST WEEK        (today - 7), 0:0:0 - today, now
      // WITHIN LAST MONTH       (today - 30), 0:0:0 - today, now

      DateTime temp();
      DateTime startToday(temp.year(), temp.month(), temp.day(), 0, 0, 0, 0);
      DateTime endToday(temp.year(), temp.month(), temp.day(), 23, 59, 59, 999);

      beginDate := '';
      endDate := '';
      switch (changeFlags) {
      case DC_TODAY:
         // the last ten digits of this value is the hours, minutes, milliseconds.  Just zero those out
         beginDate = startToday.toTimeF();
         endDate = endToday.toTimeF();
         break;
      case DC_YESTERDAY:
         // get the number of today and then subtract 1 to find yesterday.  zero out the hours, min, ms.
         beginDate = startToday.add(-1, DT_DAY).toTimeF();
         endDate = endToday.add(-1, DT_DAY).toTimeF();
         break;
      case DC_WITHIN_LAST_WEEK:
         // get the number of today and then subtract 7 to find last week.  zero out the hours, min, ms.
         beginDate = startToday.add(-7, DT_DAY).toTimeF();
         endDate = endToday.toTimeF();
         break;
      case DC_WITHIN_LAST_MONTH:
         // get the number of today and then subtract 30 to find last month.  zero out the hours, min, ms.
         beginDate = startToday.add(-1, DT_MONTH).toTimeF();
         endDate = endToday.toTimeF();
         break;
      }


      // we have our ranges, now to make the regex
      return makeRegex(beginDate, endDate);
   }

   /**
    * Builds a regex that searches for numbers which fall between
    * two other numbers.
    * 
    * @param beginDate     the beginning number of our range
    * @param endDate       the end number of the range we want
    * 
    * @return              search regex
    */
   private _str makeRegex(_str beginDate, _str endDate)
   {
      if (beginDate == endDate) return beginDate;
   
      dateLength := length(beginDate);
   
      // now, to compile our crazy regex
      wholeRegex := '';
      // the bases are the 'stems' of the dates as we work our way through them
      base1 := '';
      base3 := '';
      part1 := '';
      part2 := '';
      part3 := '';
   
      int i, pivot = 0;
      regex := '';
      for (i = 1; i <= dateLength; i++) {
   
         // the nums we'll be dealing with during this round
         begCh := _charAt(beginDate, i);
         endCh := _charAt(endDate, i);
         begNum := (int)begCh;
         endNum := (int)endCh;
   
   
         // we want to find the first number where endNum > begNum
         if (!pivot) {
            if (begNum < endNum) {
               pivot = i;
   
               // unless we are dealing with the one's place, we don't want to use inclusive ranges
               if (dateLength - i >= 1) {
                  begNum++;
                  endNum--;
               }
   
               // now we work on the middle part
               regex = base1;
     
               regex :+= '['begNum'-'endNum']';
               
               // then add a bunch of [0-9]s, because we don't care about those yet
               if (dateLength != i) {
                  regex :+= '[0-9]:'dateLength - i'()';
               }
               
               part2 = regex;
            } 
   
            // add to our bases
            base1 :+= begCh;
            base3 :+= endCh;
            continue;
         }
   
         // unless we are dealing with the one's place, we don't want to use inclusive ranges
         if (dateLength - i >= 1) {
            begNum++;
            endNum--;
         }
   
         // first we calculate the numbers greater than our low end and the next highest part
         regex = base1;
         do {
            if (begNum > 9 || i == 1) break;
   
            // if we're at 9, we just put in the number, not a range
            if (begNum == 9) {
               regex :+= begNum;
            } else {
               regex :+= '['begNum'-9]';
            }
   
            // then add a bunch of [0-9]s, because we don't care about those yet
            if (i != dateLength) {
               regex :+= '[0-9]:'dateLength - i'()';
            }
   
            // add in this part to the total regex for this part
            if (part1 != '') {
               part1 :+= '|';
            }
            part1 :+= regex;
   
         } while (false);
   
         // finally, the numbers between our high end and the next lowest part
         regex = base3;
         do {
            if (endNum < 0 || i == 1) break;
   
            // if we're at 0, we just put in the number, not a range
            if (endNum == 0) {
               regex :+= endNum;
            } else {
               regex :+= '[0-'endNum']';
            }
   
            // then add a bunch of [0-9]s, because we don't care about those yet
            if (i != dateLength) {
               regex :+= '[0-9]:'dateLength - i'()';
            }
   
            // add in this part to the total regex for this part
            if (part3 != '') {
               part3 :+= '|';
            }
            part3 :+= regex;
   
         } while (false);
   
         // update all our bases (they are belong to us)
         base1 :+= begCh;
         base3 :+= endCh;
      }
   
      // now put it all together
      if (part1 != '') {
         part1 :+= '|';
      }
      if (part2 != '' ) {
         part2 :+= '|';
      }
      wholeRegex = part1 :+ part2 :+ part3;
      if (last_char(wholeRegex) == '|') {
         wholeRegex = substr(wholeRegex, 1, length(wholeRegex) - 1);
      }
   
      return wholeRegex;
   }

   /**
    * Sets an option as having its date changed on the given date.
    * Saves this information to the user's options configuration
    * file.
    * 
    * @param index  index of option that was changed
    * @param date   date option was changed
    */
   public void setDateChanged(_str (&paths)[], int changeMethod = OCM_CONFIGURATION)
   {
      history := getHistoryNode();
      date := _time('F');

      _str path;
      foreach (path in paths) {
         if (path != '') setDateChangedForSingleItem(history, path, date, changeMethod);
      }
   }

   /**
    * Looks for the options history section of the configuration XML.  If one does 
    * not exist, it is created. 
    * 
    * @return              index of history section
    */
   private int getHistoryNode()
   {
      // we definitely need to create the config file now if we don't have it
      if (!doesXMLConfigFileExist()) createXMLConfigFile();

      // find history list in the config file - create it if it's not there
      history := _xmlcfg_find_simple(m_xmlConfigHandle, '//History');
      if (history < 0) {
         history = _xmlcfg_add(m_xmlConfigHandle, TREE_ROOT_INDEX, 'History', 
                             VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      }

      return history;
   }

   /**
    * Sets the date changed for a single options history item.
    * 
    * @param historyIndex              index of history section of config xml
    * @param path                      path of history item that changed
    * @param date                      date of change
    * @param changeMethod              method used to change the option (one of OCM 
    *                                  enum)
    */
   private void setDateChangedForSingleItem(int historyIndex, _str path, _str date, int changeMethod)
   {
      // add our new history item
      // check if our item is already there
      if (m_xmlConfigHandle > 0) {
         index := _xmlcfg_find_simple(m_xmlConfigHandle, '//Option'XPATH_FILEEQ('Path', path), historyIndex);
         if (index < 0) {
            index = _xmlcfg_add(m_xmlConfigHandle, historyIndex, 'Option',
                                VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_add_attribute(m_xmlConfigHandle, index, 'Path', path);
            _xmlcfg_add_attribute(m_xmlConfigHandle, index, 'DateChanged', date);
            _xmlcfg_add_attribute(m_xmlConfigHandle, index, 'ChangeMethod', changeMethod);
         } else {
            // update the date and change method
            _xmlcfg_set_attribute(m_xmlConfigHandle, index, 'DateChanged', date);
            _xmlcfg_set_attribute(m_xmlConfigHandle, index, 'ChangeMethod', changeMethod);
         }
      }
   }
   
   /**
    * Adds an item to the options history saying that an Options Import was done on 
    * this date. 
    */
   public void setImportDate()
   {
      history := getHistoryNode();
      date := _time('F');

      setDateChangedForSingleItem(history, 'Options Import', date, OCM_IMPORT);
   }

   /**
    * Clears all the options protections that currently exist for 
    * this user. 
    */
   public void clearAllProtections()
   {
      wasOpen := (m_xmlConfigHandle > 0);
      if (!wasOpen) init();

      if (m_xmlConfigHandle > 0) {
    
          index := _xmlcfg_find_simple(m_xmlConfigHandle, '//Protections');
          if (index > 0) _xmlcfg_delete(m_xmlConfigHandle, index);
    
          _xmlcfg_save(m_xmlConfigHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);

          // close it back, please
          if (!wasOpen) close();
      }
   }

   /**
    * In v14, a bug dealing with the way the _time('B') was calculated was 
    * fixed.  However, the date format changed into the format used for 
    * _time('F'). This method checks for any dates saved in the config file that
    * are in the old format. It then updates them to the new format. 
    *  
    * Hopefully this function will only make changes one time. 
    */
   private void checkForOldTimeStyle()
   {
      // search the options history for dates with length = 16
      _str dates[];
      _xmlcfg_find_simple_array(m_xmlConfigHandle, "/History/Option/@DateChanged[contains(.,'^:d:16$', 'R')]", dates);

      int node;
      foreach (node in dates) {
         time := _xmlcfg_get_value(m_xmlConfigHandle, node);
         time = convertTime(time);
         _xmlcfg_set_value(m_xmlConfigHandle, node, time);
      }

      // make sure we save the new stuff
      _xmlcfg_save(m_xmlConfigHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
   }

   /**
    * Converts a binary time string (obtained by calling _time('b')) from the 
    * old style (pre v14) to the new style (v14 and beyond). 
    * 
    * @param time          old style time string (16 characters)
    * 
    * @return              new style time string (17 characters)
    */
   private _str convertTime(_str time)
   {
      // this value is the number of days
      temps := (int)substr(time, 1, length(time) - 10);
      day := temps % 32;

      // subtract out the days
      temps -= day;    

      // calculate the number of months (1-based, so check for 0 = 12)
      temps /= 32;
      month := temps % 12;
      if (month == 0) month = 12;

      // subtract the months - you get the years in days
      temps -= month;     
      year := (int)temps / 12;

      // last ten characters are the time - that didn't change in the new format, 
      // this value is the number of milliseconds
      temps = (int)substr(time, length(time) - 10 + 1);

      // divide by (60 * 60 * 1000) to get the hours
      // divide by (60 * 1000) to get the minutes
      // what's left is the milliseconds
      hours := temps / (60 * 60 * 1000);
      temps -= (hours * 60 * 60 * 1000);
      minutes := temps / (60 * 1000);
      temps -= (minutes * 60 * 1000);
      seconds := temps / 1000;
      milliseconds := temps % 1000;

      // build up the string again
      newTime := substr('', 1, 4 - length(year), '0') :+ year;
      newTime :+= substr('', 1, 2 - length(month), '0') :+ month;
      newTime :+= substr('', 1, 2 - length(day), '0') :+ day;
      newTime :+= substr('', 1, 2 - length(hours), '0') :+ hours;
      newTime :+= substr('', 1, 2 - length(minutes), '0') :+ minutes;
      newTime :+= substr('', 1, 2 - length(seconds), '0') :+ seconds;
      newTime :+= substr('', 1, 3 - length(milliseconds), '0') :+ milliseconds;

      return newTime;
   }
};

