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
#require "PropertyDependencySet.e"
#require "IPropertyTreeMember.e"
#endregion Imports

namespace se.options;

enum PropertyType {
   BOOLEAN_PROPERTY,
   COLOR_PROPERTY,
   DIRECTORY_PATH_PROPERTY,
   FILE_PATH_PROPERTY,
   NUMERIC_PROPERTY,
   SELECT_PROPERTY,
   TEXT_PROPERTY,
};

/**
 * Keeps track of the way an option is set
 */
enum SettingType {
   VARIABLE,                  // set by variable, e.g. def_one_file
   FUNCTION,                  // set by function, e.g. keymsg_delay(value)
   DEFAULT_OPTION,            // set using _default_option
   DEFAULT_COLOR,             // set using _default_color
   SPELL_OPTION,              // set using _spell_option
   LANGUAGE_SETTING,          // set using the se.lang.api.LanguageSettings class
   VERSION_CONTROL_SETTING,   // set using the VersionControlSettings class
};

/**
 * Defines the form a value takes when it is set (bool, int, 
 * string, etc). 
 */
enum ValueType {
   BOOL,                // boolean
   INT,                 // integer
   FLOAT,               // floating point number
   STRING,              // string
   FLAG,                // const, enum, or enum_flag
   BACKWARDS_FLAG,      // const, enum, or enum_flag, but backwards (so setting value means &~FLAG)
   SELECT_AS_FLAG,      // const, enum, or enum_flag in a Select property
   LONG,                // long integers
};

/**
 * Only used by NumericProperty.  Occasionally, the value we
 * display is different by a certain factor than the value we
 * save.  This controls those differences.
 */
struct ResolutionInfo {
   int Value;
   bool Divide;
};

struct BooleanInfo {
   typeless TrueValue;
   typeless FalseValue;
};

/**
 * Information used to set a value by Function.
 */
struct SetFunctionInfo {
   _str Name;        // name of function
   int Index;        // index in names table
};

/**
 * Information used to set a value by Variable.
 */
struct SetVariableInfo {
   _str Name;        // name of variable
   int Index;        // index in names table
};

/**
 * Information used to set a value by calling _default_option.
 */
struct SetOptionInfo {
   _str Name;        // name of arg sent to _default_option or _spell_option
   _str Value;       // value of arg sent to _default_option or _spell_option
};

/**
 * Information used to set a value by calling _default_color.
 */
struct SetDefaultColorInfo {
   _str Name;        // name of arg sent to _default_color
   int Value;        // value of arg sent to _default_color
};

/**
 * Information used to set a value by calling a function in the LangaugeSettings 
 * api. 
 */
struct SetLanguageSettingInfo {
   _str Setting;                 // name of getter/setter in LanguageSettings API
   int GetIndex;                 // index of getter function
   int SetIndex;                 // index of setter function
   bool CreateNewLang;        // whether to create a new language if settings 
                                 // for this language do not exist
};

/**
 * Information used to set a value by calling a function in the LangaugeSettings 
 * api. 
 */
struct SetVersionControlSettingInfo {
   _str Setting;
   int GetIndex;
   int SetIndex;
};

/** 
 * Keeps track of the address of a property by holding the index
 * of its containing Property Sheet in the XML DOM, as well as
 * the index of the property within the property sheet.
 * 
 */
struct PropertyAddress {
   int PSXMLIndex;
   int PropertyIndexInSheet;        // 0-based
};

struct FlagInformation {
   _str Name;
   int Value;
};

struct SettingInfo {
   SettingType SettingType;
   ValueType ValueType;
   typeless SettingTypeInfo;
   ResolutionInfo ResInfo;
   _str Language;
   _str VCProvider;
   _str FunctionKey;
   bool GetCheckState;

   FlagInformation Flags[];
   BooleanInfo BoolInfo;
};

/** 
 * This class is a data object to keep up with Properties on the
 * option dialog.  This class is not meant to be used directly,
 * but to act as a parent for more clearly defined Properties
 * (BooleanProperty, NumericProperty, etc).
 * 
 */ 
class Property : IPropertyTreeMember {
   protected _str m_caption;                    // caption of this property
   private int m_xmlIndex;                      // index in XML DOM
   protected _str m_value;                      // current value
   private _str m_origValue;                    // original value (or last applied value)

   protected SettingInfo m_settingInfo;           // setting info - used to get/set this property
   private int m_eventFlags;                    // events that are triggered by this property being set
   public PropertyDependencySet m_dependencies; // list of dependencies that this property depends on to be enabled

   private _str m_help = '';                    // help information about this property
   private int m_clickEvent;                    // special event to be launched when this property is clicked
   private PropertyAddress m_address;           // address of this property

   private _str m_key = '';                     // used only when a PropertySheet is used as a prompt rather 
                                                // than a getter/setter, this key is associated with this property

   private int m_checkState;                    // used when m_settingInfo.GetCheckState is true, which means that
                                                // this property also has a checkbox in addition to its value
   private int m_origCheckState;                // original value of checkbox, so we can see if it was modified

   /**
    * Constructor.  
    */
   Property(_str caption = '', int index = 0)
   {
      m_caption = caption;
      m_xmlIndex = index;

      m_value = m_origValue = null;
      m_eventFlags = 0;
      m_clickEvent = 0;
      m_address = null;

      m_checkState = m_origCheckState = 0;
   }

   /** 
    * Updates the current value.  If the new value
    * is equal to the old value, does nothing. 
    * 
    * @param newValue      new value to be set
    * 
    * @return _str         current value (which may be newly 
    *                      updated)
    */
   public _str updateValue(_str newValue)
   {
      m_value = newValue;
      return m_value;
   }

   /**
    * Updates the current check state.
    *
    * @param newCheckState
    */
   public void updateCheckState(int newCheckState)
   {
      m_checkState = newCheckState;
   }

   #region Boolean is-Something Functions

   /**  
    * Returns whether the current property has been modified.
    * 
    * @return bool         true if modified, false otherwise
    */
   public bool isModified()
   {
      // if the value is different
      // if we have a checkbox and the checkbox has changed
      return (m_value == null && m_origValue != null) || 
         (m_origValue == null && m_value != null) ||
         (m_value :!= m_origValue) || 
         (isCheckable() && m_checkState :!= m_origCheckState);
   }

   /**
    * Returns whether this property has a special click event.
    * 
    * @return true if this property has a special click event, false otherwise.
    */
   public bool hasClickEvent()
   {
      return (m_clickEvent > 0);
   }

   #endregion Boolean is-Something Functions

   #region Properties

   /** 
    * Sets the initial value.  This function differs from 
    * updateValue because it sets the original value as well.
    * 
    * @param newValue      new value
    */
   public void setValue(_str newValue)
   {
      m_value = newValue;
      m_origValue = m_value;
   }

   /** 
    * Returns the current display value of the property.  The 
    * display value may be different from the actual value, 
    * depending on the Property type. 
    * 
    * @return _str      current value
    */
   public _str getDisplayValue()
   {
      if (m_value != null) {
         return m_value;
      } else {
         return null;
      }
   }

   /**
    * Returns the current actual value of the property, which may 
    * differ from how we want to display it to the user. 
    * 
    * @return           current actual value
    */
   public _str getActualValue()
   {
      return m_value;
   }

   /** 
    * Marks the property as having been applied by saving the 
    * current value as the original value. 
    */
   public void setApplied()
   {
      m_origValue = m_value;
   }

   /**
    * Sets the event flags for this property.
    * 
    * @param f      flag to set
    */
   public void setChangeEventFlags(OptionsChangeEventFlags f)
   {
      m_eventFlags = f;
   } 

   /**
    * Gets the event flag for this property.
    * 
    * @return      event flags
    */
   public int getChangeEventFlags()
   {
      return m_eventFlags;
   }

   /**
    * Sets the help for this property.
    * 
    * @param help   help
    */
   public void setHelp(_str help)
   {
      m_help = help;
   }

   /**
    * Gets the help for this property.
    * 
    * @return _str   help
    */
   public _str getHelp()
   {
      return m_help;
   }

   /**
    * Gets the caption for this property.
    * 
    * @return _str   caption
    */
   public _str getCaption()
   {
      return m_caption;
   }

   public void setCaption(_str caption)
   {
      m_caption = caption;
   }

   /**
    * Gets the index in the XML DOM for this property.
    * 
    * @return int   index
    */
   public int getIndex()
   {
      return m_xmlIndex;
   }

   /**
    * Gets the click event index (from names table) for this 
    * property. 
    * 
    * @return _str   event index
    */
   public int getClickEvent()
   {
      return m_clickEvent;
   }

   /**
    * Sets the click event index (from names table) for this 
    * property. 
    * 
    * @param int    event index
    */
   public void setClickEvent(int value)
   {
      m_clickEvent = value;
   }

   /**
    * Returns the address for this property.  Address refers to its
    * position within the PropertySheet, and that PropertySheet's
    * position in the XML DOM.
    * 
    * @return PropertyAddress
    */
   public PropertyAddress getAddress()
   {
      return m_address;
   }

   /**
    * Sets the address for this property.  Address refers to its
    * position within the PropertySheet, and that PropertySheet's
    * position in the XML DOM.
    * 
    * @param xmlIndex index of PropertySheet in XML DOM
    * @param psIndex  index within property sheet of this property
    */
   public void setAddress(int xmlIndex, int psIndex)
   {
      PropertyAddress pa;
      pa.PSXMLIndex = xmlIndex;
      pa.PropertyIndexInSheet = psIndex;

      m_address = pa;
   }

   public void setSettingInfo(SettingInfo &info)
   {
      m_settingInfo = info;
   }

   public SettingInfo getSettingInfo()
   {
      return m_settingInfo;
   }

   public _str getFunctionKey()
   {
      return m_settingInfo.FunctionKey;
   }

   public void setFunctionKey(_str fkey)
   {
      m_settingInfo.FunctionKey = fkey;
   }

   public _str getLanguage()
   {
      return m_settingInfo.Language;
   }

   public void setLanguage(_str langID)
   {
      m_settingInfo.Language = langID;
      m_dependencies.setLanguage(langID);
   }

   public void setVCProvider(_str providerID)
   {
      m_settingInfo.VCProvider = providerID;
   }

   public void setIndex(int index)
   {
      m_xmlIndex = index;
   }

   /**
    * Returns the current property type (one of the PropertyType enum).  Should 
    * be overwritten by child classes. 
    * 
    * @return           property type of this object
    */
   public int getPropertyType()
   {
      return -1;
   }

   public _str getKey()
   {
      return m_key;
   }

   public void setKey(_str key)
   {
      m_key = key;
   }

   /**
    * Returns whether or not this property should have a checkbox
    * in addition to its regular value.
    *
    * @return bool
    */
   public bool isCheckable()
   {
      return m_settingInfo.GetCheckState;
   }

   /**
    * Sets whether or not this property should have a checkbox in
    * addition to its regular value
    *
    * @param checkable
    */
   public void setCheckable(bool checkable)
   {
      m_settingInfo.GetCheckState = checkable;
   }

   /**
    * Returns the current state of the checkbox associated with
    * this property.
    *
    * @return int
    */
   public int getCheckState()
   {
      return m_checkState;
   }

   /**
    * Sets the current state of the checkbox associated with this
    * property.
    *
    * @param checkState
    */
   public void setCheckState(int checkState)
   {
      m_checkState = m_origCheckState = checkState;
   }

   #endregion Properties
};
         
