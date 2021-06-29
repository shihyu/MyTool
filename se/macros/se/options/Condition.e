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
#require "IPropertyDependency.e"
#endregion Imports

namespace se.options;

/**
 * Types of conditions 
 * DT_APIFLAG - refers to a condition relying upon the result of 
 * _default_option(VSOPTION_APIFLAGS) & value. 
 *  
 * DT_FUNCTION - checks the return value of a function call against the target 
 * value 
 *  
 * DT_VARIABLE - checks the value of a variable against the target value 
 *  
 * DT_OPTION - checks the current value of another option against the target 
 * value 
 *  
 * DT_LANG_CALLBACK - sees if a callback exists for the given language, returns 
 * true if so 
 *  
 * DT_LANG_INHERITANCE - sees if the current language inherits from the given 
 * parent language 
 */
enum ConditionType {
   DT_APIFLAG,
   DT_FUNCTION,
   DT_VARIABLE,
   DT_OPTION,
   DT_LANG_CALLBACK,
   DT_LANG_INHERITANCE,
   // default value
   DT_NONE=0,
};

enum ComparisonType {
   CT_STRING,
   CT_FLAG,
   // default value
   CT_NONE=0,
};

/**
 * The condition class keeps track of checking a dependency that
 * an option has to fulfill to be enabled.
 * 
 */
class Condition : IPropertyDependency
{
   private ConditionType m_type;            // type of the dependency
   private _str m_info;                     // info about the dependency, varies by type
   private typeless m_value;                // target value for this dependency
   private bool m_equals;                // whether this is a condition or not condition
   private _str m_savedValue;               // used for DT_OPTION - saves the last known value 
                                            // of the depended upon option
   private _str m_language;                 // used with DT_FUNCTION - language that applies to the property
   private ComparisonType m_compare;

   /**
    * Constructor.  Doesn't do much.
    * 
    */
   Condition(ConditionType type = DT_NONE)
   {
      m_type = type;
      m_info = "";
      m_value = "";
      m_equals = true;
      m_savedValue = null;
      m_language = "";
      m_compare = CT_NONE;
   }
   
   /**
    * Determines whether the condition is currently true or false.
    * In case the condition is of type DT_OPTION, a hashtable of
    * options and their current values are sent in.
    * 
    * @param options    hashtable of current options
    * 
    * @return           whether the condition evaluated to true or false
    */
   public bool evaluate(_str options:[]) 
   {
      bool enabled;

      switch (m_type) {
      case DT_APIFLAG:
         enabled = (_default_option(VSOPTION_APIFLAGS) & (int)m_value);
         break;
      case DT_FUNCTION:
         returnVal := getFunctionValue();
         
         if (m_compare == CT_FLAG) enabled = checkFlagType(returnVal);
         else enabled = checkStringType(returnVal);
         break;
      case DT_VARIABLE:
         returnVal = getVariableValue();
         
         if (m_compare == CT_FLAG) enabled = checkFlagType(returnVal);
         else enabled = checkStringType(returnVal);
         break;
      case DT_OPTION:
         if (options._indexin(m_info)) {
            enabled = (options:[m_info] == m_value);

            // save the current value
            m_savedValue = options:[m_info];
         } else if (m_savedValue != null) {
            // revert to the value we saved
            enabled = (m_savedValue == m_value);
         } else {
            // you know, we just don't know sometimes...
            enabled = false;
         }
         break;
      case DT_LANG_CALLBACK:
         enabled = doesCallbackExist();
         break;
      case DT_LANG_INHERITANCE:
         enabled = doesLanguageInheritFromParent();
         break;
      }

      // some conditions are "Not" conditions, meaning the value has to 
      // NOT equal the target value for the condition to be true.  In 
      // that case, we reverse whatever we found before.
      if (!m_equals) enabled = !enabled;

      return enabled;
   }
   
   /**
    * Checks to see if the flag value is ORed into the given value.
    * 
    * @param returnVal        value in which to check for flag
    * 
    * @return                 true if flag is ORed into value, false otherwise
    */
   private bool checkFlagType(typeless returnVal)
   {
      // this better be an int...
      return ((returnVal & (int)m_value) != 0);
   }
   
   private bool checkStringType(typeless returnVal)
   {
      if (m_value == '') return returnVal;
      else return strieq((_str)returnVal, m_value);
   }
   
   private typeless getFunctionValue()
   {
      // call the function, maybe with a language
      typeless returnVal;
      if (m_language != '') {
         returnVal = call_index(m_language, (int)m_info);
      } else {
         returnVal = call_index((int)m_info);
      }
      
      return returnVal;
   }
   
   private typeless getVariableValue()
   {
      return _get_var((int)m_info);
   }

   private bool doesCallbackExist()
   {
      // make sure we even have a language
      if (m_language != '') {
         return (_FindLanguageCallbackIndex(m_info, m_language) != 0);
      }

      return false;
   }

   private bool doesLanguageInheritFromParent()
   {
      // make sure we even have a language
      if (m_language != '') {
         return _LanguageInheritsFrom(m_info, m_language);
      }

      return false;
   }
   
   public ConditionType getType()
   {
      return m_type;
   }
   
   public void setType(ConditionType type)
   {
      m_type = type;
   }
   
   public _str getInfo()
   {
      return m_info;
   }
   
   public void setInfo(_str info)
   {
      m_info = info;
   }
   
   public typeless getValue()
   {
      return m_value;
   }
   
   public void setValue(typeless value)
   {
      m_value = value;
   }
   
   public void setEquals(bool value)
   {
      m_equals = value;
   }
   
   public void setLanguage(_str langID)
   {
      m_language = langID;
   }
   
   public void setComparisonType(ComparisonType compare)
   {
      m_compare = compare;
   }
};
