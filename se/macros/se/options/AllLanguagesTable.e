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
#endregion Imports

namespace se.options;

struct LangValue {
   _str Value;
   int Version;
};

/**
 * Keeps track of the value for one specific control on a language-specific 
 * options form. 
 */
class ControlValues {
   private int m_version = 0;
   private LangValue m_allLangsValue;                   // the all languages value for this control
   private LangValue m_langsValues:[];                  // table of other values, hashed by language id

   ControlValues()
   {
      m_langsValues._makeempty();
   }

   /**
    * Adds a value to our list.
    * 
    * @param langID              language id which has this value, can be 
    *                            ALL_LANGUAGES_ID
    * @param value               current value (or string representation 
    *                            thereof)
    */
   public void addLanguageValue(_str langID, _str value)
   {
      // see if this is a new value, it might be old
      oldValue := getLanguageValue(langID);
      if (oldValue == null || oldValue != value) {
   
         m_version++;
   
         // create a new LangValue with this info
         LangValue lv;
         lv.Value = value;
         lv.Version = m_version;
   
         if (langID == ALL_LANGUAGES_ID) {
            // if it is the ALL_LANGS value, then we set that.  We also erase 
            // all the existing values for individual languages, because the 
            // ALL_LANGS value will override those
            m_allLangsValue = lv;
            m_langsValues._makeempty();
         } else {
            // just save the value for this language
            m_langsValues:[langID] = lv;
         }
      }
   }

   public _str getLanguageValue(_str langID)
   {
      value := null;
      if (langID == ALL_LANGUAGES_ID) {
         value = m_allLangsValue.Value;
      } else {
         // just get the value for this language
         if (m_langsValues._indexin(langID)) {
            value =  m_langsValues:[langID].Value;
         }
      }

      return value;
   }

   public bool hasChanged(_str langID)
   {
      alVersion := getAllLangsVersion();

      if (langID == ALL_LANGUAGES_ID) {
         return (alVersion < m_version);
      } else {
         langVersion := getLangVersion(langID);
         return (langVersion < alVersion);
      }
   }

   private int getLangVersion(_str langID)
   {
      if (m_langsValues._indexin(langID)) {
         return m_langsValues:[langID].Version;
      }

      return 0;
   }

   private int getAllLangsVersion()
   {
      if (m_allLangsValue != null && m_allLangsValue.Version != null) {
         return m_allLangsValue.Version;
      }

      return 0;
   }

   public bool isEmpty()
   {
      return ((m_allLangsValue == null || 
               (m_allLangsValue.Value == null && m_allLangsValue.Version == null)) && 
              m_langsValues._isempty());
   }

   public void removeLanguageValue(_str langID)
   {
      if (langID == ALL_LANGUAGES_ID) {
         m_allLangsValue = null;
      } else {
         m_langsValues._deleteel(langID);

         if (m_langsValues._length() == 0) {
            m_langsValues._makeempty();
         }
      }
   }

   public bool doesAllLanguagesOverrideLanguageValue(_str langId)
   {
      return (getLangVersion(langId) < getAllLangsVersion());
   }

   public bool doesAnyLanguageValueOverrideAllLanguages()
   {
      return (m_version > getAllLangsVersion());
   }

// public bool getAllLanguagesValue(_str &value)
// {
//    // we want all our values to match, starting with the all langs value
//    value = (m_allLangsValue != null) ? m_allLangsValue.Value : null;
//    LangValue lv;
//    foreach (lv in m_langsValues) {
//       if (value == null) {
//          value = lv.Value;
//       } else if (lv.Value != value) {
//          value = null;
//          break;
//       }
//    }
// }
};

class AllLanguagesTable {
   
   private ControlValues m_table:[];

   AllLanguagesTable()
   {
      m_table._makeempty();
   }

   private _str createKey(_str form, _str control)
   {
      return form'.'control;
   }

   private _str getFormNameFromKey(_str key)
   {
      return substr(key, 1, pos('.', key) - 1);
   }

   private _str getControlNameFromKey(_str key)
   {
      return substr(key, pos('.', key) + 1);
   }

   /**
    * Saves a language option that has been set.
    * 
    * @param langID                 language id
    * @param form                   form name where option lives
    * @param control                name of control that was set
    * @param value                  value of control
    */
   public void setLanguageValue(_str form, _str control, _str langId, _str value)
   {
      key := createKey(form, control);
      if (m_table._indexin(key)) {
         m_table:[key].addLanguageValue(langId, value);
      } else {
         ControlValues cv;
         cv.addLanguageValue(langId, value);

         m_table:[key] = cv;
      }
   }

   /**
    * Retrieves a language option that has been set.
    * 
    * @param form                   form name where option lives
    * @param control                name of control that was set
    * @param langID                 language id
    */
   public _str getLanguageValue(_str form, _str control, _str langId)
   {
      _str value = null;

      key := createKey(form, control);
      if (m_table._indexin(key)) {
         value = m_table:[key].getLanguageValue(langId);
      } 

      return value;
   }

   /**
    * Removes a language value from our table.
    * 
    * @param form                   form name where option lives
    * @param control                name of control (value)
    * @param langId                 language id
    */
   public void removeLanguageValue(_str form, _str control,  _str langId)
   {
      key := createKey(form, control);
      if (m_table._indexin(key)) {
         m_table:[key].removeLanguageValue(langId);

         // if it's empty now, clear it out
         if (m_table:[key].isEmpty()) m_table._deleteel(key);
         if (m_table._length() == 0) m_table._makeempty();
      } 
   }

   /**
    * Determines whether the given language value has been overridden by an All 
    * Languages value. 
    * 
    * @param form                   form name where option lives
    * @param control                name of control to check
    * @param langId                 language id
    * 
    * @return                       true if the value is overridden by All 
    *                               Langauges, false otherwise
    */
   public bool doesAllLanguagesOverride(_str form, _str control, _str langId)
   {
      key := createKey(form, control);
      if (m_table._indexin(key)) {
         return m_table:[key].doesAllLanguagesOverrideLanguageValue(langId);
      }

      return false;
   }

   public bool doesAnyLanguageOverrideAllLanguages(_str form, _str control)
   {
      key := createKey(form, control);
      if (m_table._indexin(key)) {
         return m_table:[key].doesAnyLanguageValueOverrideAllLanguages();
      } 

      return false;
   }

   /**
    * Gets all the overriding All Language values for a form. 
    * 
    * @param form                      name of form
    * @param langID                    lang id that we are looking to override
    * @param values                    hash table of control names to overriding 
    *                                  values
    */
   public void getOverridingAllLanguageValuesForForm(_str form, _str langID, _str (&values):[])
   {
      _str key;
      ControlValues cv;
      foreach (key => cv in m_table) {
         // is this control on this form?
         if (getFormNameFromKey(key) == form) {
            // see if there is a value for this lang id - then we don't use the all langs value
            if (cv.getLanguageValue(langID) == null) {
               // get the all langs value
               value := cv.getLanguageValue(ALL_LANGUAGES_ID);
               if (value != null) {
                  // save it
                  control := getControlNameFromKey(key);
                  values:[control] = value;
               }
            }
         }
      }
   }

   /**
    * Determines if any All Language settings have been modified for this form.
    * 
    * @param form             name of form to check
    * 
    * @return                 true if a value has been modified, false otherwise
    */
   public bool isAllLanguagesModified(_str form)
   {
      _str key;
      ControlValues cv;
      foreach (key => cv in m_table) {
         // is this control on this form?
         if (getFormNameFromKey(key) == form) {

            // get the all langs value
            value := cv.getLanguageValue(ALL_LANGUAGES_ID);
            if (value != null) {
               return true;
            }
         }
      }

      return false;
   }

   public bool isLangFormModified(_str form, _str langID)
   {
      _str key;
      ControlValues cv;
      // go through each of our controls
      foreach (key => cv in m_table) {
         // is this control on this form?
         if (getFormNameFromKey(key) == form) {

            // get the all langs value
            value := cv.getLanguageValue(langID);
            if (value != null) {
               return true;
            }
         }
      }

      return false;
   }

   public bool hasAllLanguagesBeenSetForControl(_str form, _str control)
   {
      value := getLanguageValue(form, control, ALL_LANGUAGES_ID);

      return (value != null);
   }

   public void removeFormListings(_str form, _str langID)
   {
      _str key;
      foreach (key => . in m_table) {
         // is this control on this form?
         if (getFormNameFromKey(key) == form) {

            m_table:[key].removeLanguageValue(langID);
            if (m_table:[key].isEmpty()) {
               m_table._deleteel(key);
            }
         }
      }

      if (m_table._length() == 0) {
         m_table._makeempty();
      }
   }
};
