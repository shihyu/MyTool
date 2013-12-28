////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46645 $
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
#import "math.e"
#import "recmacro.e"
#import "stdprocs.e"
#require "Property.e"
#require "se/vc/VersionControlSettings.e"
#endregion Imports

using se.vc.VersionControlSettings;

namespace se.options;

struct PropertySetting {
   _str Value;
   int CheckState;
};

#define RETRIEVE_ERROR        'Error retrieving value'

/** 
 * This class handles getting and setting properties from the
 * options dialog.  Also handles the translation of values to 
 * and from strings. 
 * 
 */
class PropertyGetterSetter
{
   PropertyGetterSetter()
   { }

   #region Translation From Display Methods

   /** 
    * Converts an integer value from its display value to its 
    * actual value. 
    * 
    * @param value      the value as a string
    * @param newValue   the value as an integer
    * 
    * @return boolean   success of conversion
    */
   private static boolean displayToInt(_str value, int &newValue, ResolutionInfo resInfo)
   {
      if (isinteger(value)) {
         if (resInfo != null) {
            // resInfo.Divide specifies how you get from value to 
            // display, so we do the opposite here
            if (resInfo.Divide) {
               newValue = (int)value * resInfo.Value;
            } else {
               newValue = (int)value / resInfo.Value;
            }
         } else {
            newValue = (int)value;
         }
         return true;
      }

      return false;
   }

   /**
    * Converts a long value from its display value to its actual
    * value.
    *
    * @param value      the value as a string
    * @param newValue   the value as an integer
    *
    * @return boolean   success of conversion
    */
   private static boolean displayToLong(_str value, long &newValue, ResolutionInfo resInfo)
   {
      if (isnumber(value)) {
         if (resInfo != null) {
            // resInfo.Divide specifies how you get from value to
            // display, so we do the opposite here
            if (resInfo.Divide) {
               newValue = (long)value * resInfo.Value;
            } else {
               newValue = (long)value / resInfo.Value;
            }
         } else {
            newValue = (long)value;
         }
         return true;
      }

      return false;
   }

   /** 
    * Converts a float value from its display value to its actual
    * value. 
    * 
    * @param value      the value as a string
    * @param newValue   the value as a float
    * 
    * @return boolean   success of conversion
    */
   private static boolean displayToFloat(_str value, double &newValue, ResolutionInfo resInfo)
   {
      if (isnumber(value)) {
         if (resInfo != null) {
            // resInfo.Divide specifies how you get from value to 
            // display, so we do the opposite here
            if (resInfo.Divide) {
               newValue = (double)value * resInfo.Value;
            } else {
               newValue = (double)value / (double)resInfo.Value;
            }
         } else {
            newValue = (double)value;
         }
         return true;
      }

      return false;
   }

   /** 
    * Converts a boolean to a flag (either a constant, enum, or 
    * enum flag).  If the boolean is true, the flag value is 
    * returned, else 0. 
    * 
    * @param value      the value as a boolean
    * @param newValue   the value as an integer (which corresponds 
    *                   to a flag)
    * @param flag       the value of the flag
    * 
    * @return boolean   success of conversion   
    */
   private static boolean displayToFlag(_str value, int &newValue, int flag, boolean backwards)
   {
      boolean trueFalse = strieq(value, 'true');
      if (backwards) trueFalse = !trueFalse;

      if (trueFalse) {
         newValue = flag;
         return true;
      } else {
         newValue = 0;
         return true;
      }
    
      return false;
   }

   private static boolean translateFlagValue(SettingInfo &info, int &value)
   {
      curValue := (int)getSetting(info, false);
      
      // handle |= case for flags
      if (info.ValueType == FLAG || info.ValueType == BACKWARDS_FLAG) {
         // means we're setting this to true, so we OR in the value
         if (value == info.Flags[0].Value) {
            curValue |= info.Flags[0].Value;
         } else {
            curValue &= ~info.Flags[0].Value;
         }
         value = curValue;
      } else if (info.ValueType == SELECT_AS_FLAG) {
         temp := curValue;

         // we have to get rid of all the other values that are in there
         FlagInformation fi;
         foreach (fi in info.Flags) {
            if ((curValue & fi.Value) == fi.Value) temp = temp & ~fi.Value;
         }

         // then add ours in
         temp = temp | (int)value;

         // check to see if this is the same as it was before
         value = temp;
      }

      return true;
   }
   
   /** 
    * Converts a string to a boolean.  String must either be "true" 
    * or "false".  Case-insensitive. 
    * 
    * @param value      string to be converted
    * @param newValue   converted boolean
    * 
    * @return boolean   success of conversion
    */
   private static boolean displayToBool(_str value, typeless &newValue, BooleanInfo &binfo)
   {
      if (strieq(value, "true")) {
         newValue = binfo.TrueValue;
         return true;
      } else if (strieq(value, "false")){
         newValue = binfo.FalseValue;
         return true;
      }

      // couldn't figure it out
      return false;
   }

   /** 
    * Translates a value from its "display" value to its actual 
    * value.  An options value may be set as a boolean, an int, or 
    * a flag, but is always displayed as a string. 
    * 
    * @param info       struct containing info about this 
    *                   particular setting, including conversion
    *                   info
    * @param value      the value to be converted, which will be 
    *                   the converted value at the return of the
    *                   function.
    * 
    * @return boolean   success of conversion
    */
   private static boolean translateDisplayToValue(SettingInfo &info, typeless &value)
   {
      typeless newValue = 0;
      boolean status = false;

      if (info.ValueType == BOOL) {
         status = displayToBool(value, newValue, info.BoolInfo);
      } else if (info.ValueType == INT) {
         status = displayToInt(value, newValue, info.ResInfo);
      } else if (info.ValueType == LONG) {
         status = displayToLong(value, newValue, info.ResInfo);
      } else if (info.ValueType == FLOAT) {
         status = displayToFloat(value, newValue, info.ResInfo);
         if (info.SettingType == DEFAULT_OPTION) {
            newValue = (int)newValue;
         }
      } else if (info.ValueType == FLAG || info.ValueType == BACKWARDS_FLAG) {
         status = displayToFlag(value, newValue, info.Flags[0].Value, info.ValueType == BACKWARDS_FLAG);
         status = translateFlagValue(info, newValue);
      } else if (info.ValueType == SELECT_AS_FLAG) {
         newValue = value;
         status = translateFlagValue(info, newValue);
      } else {
         newValue = value;
         status = true;
      }

      value = newValue;
      return status;
   }
   #endregion Translation From Display Methods

   #region Translation To Display Methods

   /**
    * Converts an integer to a string representation of a boolean.
    * 1 -> 'True', 0 -> 'False'
    *
    * @param value   integer to be converted
    *
    * @return _str   boolean string
    */
   private static _str boolToDisplay(typeless value, BooleanInfo &binfo)
   {
      if (isinteger(value)) {

         // try a straight comparison
         if (value == binfo.FalseValue) {
            return "False";
         } else if (value == binfo.TrueValue) {
            return "True";
         }

         // no go?  try converting to bool and then back to int
         intValue := (int)(value != 0);
         if (intValue == binfo.FalseValue) {
            return "False";
         } else if (intValue == binfo.TrueValue) {
            return "True";
         }

      } else {
         if (strieq(value, binfo.FalseValue)) {
            return "False";
         } else if (strieq(value, binfo.TrueValue)) {
            return "True";
         }

         // last ditch effort
         if (value) {
            return "True";
         } else {
            return "False";
         }
      }

      // confused!
      return '';
   }

   /** 
    * Converts a flag boolean to a true/false display value. 
    * Determines if the flag is ORed into the value, returns "True" 
    * or "False". 
    * 
    * @param value      value to check
    * @param flag       flag to look for in value
    * 
    * @return _str      boolean string
    */
   private static _str flagToDisplay(int value, int flag, boolean backwards)
   {
      boolean trueFalse = ((value & flag) == flag);

      if (backwards) trueFalse = !trueFalse;

      if (trueFalse) return "True";
      else return "False";
   }

   /** 
    * Converts an integer value to an integer display value.  If the value needs
    * to be multipled or divided for display purposes, this happens 
    * here.
    * 
    * @param value      value to check 
    * @param resInfo    resolution info for this property 
    * 
    * @return _str      boolean string
    */
   private static _str intToDisplay(int value, ResolutionInfo &resInfo)
   {
      if (resInfo != null && isinteger(value)) {
         // resInfo.Divide specifies how we scale to go from 
         // the value to the display value
         if (resInfo.Divide) {
            value = value / resInfo.Value;
         } else{
            value = value * resInfo.Value;
         }
      }

      return (_str)value;
   }

   /**
    * Converts an integer value to an integer display value.  If the value needs
    * to be multipled or divided for display purposes, this happens
    * here.
    *
    * @param value      value to check
    * @param resInfo    resolution info for this property
    *
    * @return _str      boolean string
    */
   private static _str longToDisplay(long value, ResolutionInfo &resInfo)
   {
      if (resInfo != null && isnumber(value)) {
         // resInfo.Divide specifies how we scale to go from
         // the value to the display value
         if (resInfo.Divide) {
            value = value / resInfo.Value;
         } else{
            value = value * resInfo.Value;
         }
      }

      return (_str)value;
   }

   private static _str floatToDisplay(double value, ResolutionInfo &resInfo)
   {
      // the value to the display value
      if (resInfo != null && isnumber(value)) {
         if (resInfo.Divide) {
            value = value / (double)resInfo.Value;
         } else{
            value = value * resInfo.Value;
         }
      }

      // also do a bit o' rounding
      value = round(value);

      return (_str)value;
   }

   /** 
    * Translates a value from its actual value to its "display" 
    * value. An options value may be set as a boolean, an int, or a
    * flag, but is always displayed as a string. 
    * 
    * @param info       struct containing info about this 
    *                   particular setting, including conversion
    *                   info
    * @param value      the value to be converted, which will be 
    *                   the converted value at the return of the
    *                   function.
    * 
    * @return boolean   success of conversion
    */
   private static boolean translateValueToDisplay(SettingInfo &info, typeless &value)
   {
      boolean status;

      if (info.ValueType == BOOL) {
         value = boolToDisplay(value, info.BoolInfo);
      } else if (info.ValueType == FLAG || info.ValueType == BACKWARDS_FLAG) {
         value = flagToDisplay(value, info.Flags[0].Value, info.ValueType == BACKWARDS_FLAG);
      } else if (info.ValueType == INT) {
         value = intToDisplay(value, info.ResInfo);
      } else if (info.ValueType == LONG) {
         value = longToDisplay(value, info.ResInfo);
      } else if (info.ValueType == FLOAT) {
         value = floatToDisplay(value, info.ResInfo);
      } else {
         value = (_str)value;
      }

      return (value != '');
   }

   #region Translation To Display Methods

   #region Get Setting Methods

   /** 
    * Gets a value using the _spell_option method.  Options 
    * are retrieved by a string (e.g. 'C' for the common list).
    * 
    * @param info    struct containing info used to retrieve 
    *                default option
    * 
    * @return _str   default option value or error.
    */
   private static _str getSpellOption(SetOptionInfo &soi)
   {
      return _spell_option(soi.Value);
   }

   /** 
    * Gets a value using the _default_option method.  Some options 
    * are retrieved by a string (e.g. 'S' for search options), 
    * others by const values (VSOPTION_SHOWTOOLTIPS for show tool 
    * tips option). 
    * 
    * @param info    struct containing info used to retrieve 
    *                default option
    * 
    * @return _str   default option value or error.
    */
   private static _str getDefaultOption(SetOptionInfo &soi)
   {
      return _default_option(soi.Value);
   }

   /** 
    * Gets the value of a default color parameter using 
    * _default_color.  Fetches only the foreground property.
    * 
    * @param color   the index to be sent to _default_color
    * 
    * @return _str   the foreground color in a hex string or error 
    *                string
    */
   private static _str getDefaultColor(SetDefaultColorInfo &scoi)
   {
      _str fg, bg, ff;

      if (scoi.Value) {
         parse _default_color(scoi.Value) with fg bg ff;
            return dec2hex((int)fg);
      }

      return RETRIEVE_ERROR;
   }

   /** 
    * Gets the value of a variable.
    * 
    * @param index   the index of the variable in the names table
    * 
    * @return _str   the value or error string
    */
   private static _str getVariableProperty(SetVariableInfo &svi)
   {
      if (svi.Index > 0) {
         return (_str)_get_var(svi.Index);
      } 

      return RETRIEVE_ERROR;
   }

   /** 
    * Gets the value returned by calling a function.  Does not 
    * currently handle any arguments, but could be expanded to do 
    * so. 
    * 
    * @param index   index of the desired function in the names 
    *                table
    * 
    * @return _str   return value of function or error string
    */
   private static PropertySetting getFunctionProperty(SettingInfo &info)
   {
      SetFunctionInfo sfi = info.SettingTypeInfo;

      PropertySetting ps;
      ps.Value = RETRIEVE_ERROR;
      ps.CheckState = 0;

      if (index_callable(sfi.Index)) {
         typeless extraArg = '';
         if (info.FunctionKey) {
            extraArg = info.FunctionKey;
         } else if (info.Language != '') {
            extraArg = info.Language;
         } else if (info.VCProvider != '' ) {
            extraArg = info.VCProvider;
         }

         if (extraArg != '') {
            if (info.GetCheckState) {
               ps.Value = call_index(extraArg, null, ps.CheckState, sfi.Index);
            } else {
               ps.Value = call_index(extraArg, sfi.Index);
            }
         } else {
            if (info.GetCheckState) {
               ps.Value = call_index(null, ps.CheckState, sfi.Index);
            } else {
               ps.Value = call_index(sfi.Index);
            }
         }

      }

      return ps;
   }

   /** 
    * Gets the value returned by calling a function in the 
    * se.lang.api.LanguageSettings class. Does not currently handle any 
    * arguments, but could be expanded to do so. 
    *  
    * @param info    SettingInfo object 
    * @return _str   return value of function or error string
    */
   private static PropertySetting getLanguageSetting(SettingInfo &info)
   {
      PropertySetting ps;
      ps.Value = RETRIEVE_ERROR;
      ps.CheckState = 0;

      SetLanguageSettingInfo slsi = info.SettingTypeInfo;
      if (index_callable(slsi.GetIndex)) {
         if (info.GetCheckState) {
            ps.Value = call_index(info.Language, null, ps.CheckState, slsi.GetIndex);
         } else {
            ps.Value = call_index(info.Language, slsi.GetIndex);
         }
      }

      return ps;
   }
   
   /** 
    * Gets the value returned by calling a function in the 
    * se.vc.VersionControlSettings class. Does not currently 
    * handle any arguments, but could be expanded to do so. 
    *  
    * @param info    SettingInfo object 
    * @return _str   return value of function or error string
    */
   private static PropertySetting getVersionControlSetting(SettingInfo &info)
   {
      PropertySetting ps;
      ps.Value = RETRIEVE_ERROR;
      ps.CheckState = 0;

      SetVersionControlSettingInfo svcsi = info.SettingTypeInfo;
      if (index_callable(svcsi.GetIndex)) {
         if (info.GetCheckState) {
            ps.Value = call_index(info.VCProvider, null, ps.CheckState, svcsi.GetIndex);
         } else {
            ps.Value = call_index(info.VCProvider, svcsi.GetIndex);
         }
      }

      return ps;
   }

   public static void getCheckedSetting(SettingInfo &info, _str &value, int &checkState, boolean translateToDisplay = true)
   {
      // check states really only work with certain kinds of settings
      PropertySetting ps;
      ps.Value = RETRIEVE_ERROR;
      ps.CheckState = 0;
      if (info.SettingType == FUNCTION) {
         ps = getFunctionProperty(info);
      } else if (info.SettingType == LANGUAGE_SETTING) {
         ps = getLanguageSetting(info);
      } else if (info.SettingType == VERSION_CONTROL_SETTING) {
         ps = getVersionControlSetting(info);
      }

      if (ps.Value != RETRIEVE_ERROR && translateToDisplay) {
         translateValueToDisplay(info, ps.Value);
      }

      value = ps.Value;
      checkState = ps.CheckState;
   }

   /** 
    * Gets the value of a setting as specified by the parameters in 
    * the SettingInfo struct.  After retrieval, converts the 
    * setting into a string for display purposes. 
    * 
    * @param info    SettingInfo struct containing info about 
    *                setting to be retrieved
    *       
    * @return _str   a string version of the value or an error 
    *                string.
    */
   public static _str getSetting(SettingInfo &info, boolean translateToDisplay = true)
   {
      PropertySetting ps;
      if (info.SettingType == VARIABLE) {
         ps.Value= getVariableProperty(info.SettingTypeInfo);
      } else if (info.SettingType == FUNCTION) {
         ps = getFunctionProperty(info);
      } else if (info.SettingType == DEFAULT_OPTION) {
         ps.Value = getDefaultOption(info.SettingTypeInfo);
      } else if (info.SettingType == DEFAULT_COLOR) {
         ps.Value = getDefaultColor(info.SettingTypeInfo);
      } else if (info.SettingType == SPELL_OPTION) {
         ps.Value = getSpellOption(info.SettingTypeInfo);
      } else if (info.SettingType == LANGUAGE_SETTING) {
         ps = getLanguageSetting(info);
      } else if (info.SettingType == VERSION_CONTROL_SETTING) {
         ps = getVersionControlSetting(info);
      } 

      if (ps.Value != RETRIEVE_ERROR && translateToDisplay) {
         translateValueToDisplay(info, ps.Value);
      } 

      return ps.Value;
   }

   #endregion Get Setting Methods

   #region Set Setting Methods

   /** 
    * Sets a spell option using the information provided in 
    * SettingInfo struct to the value specified.  Also makes a 
    * macro call in case we're currently recording. 
    * 
    * @param info       information about spell option to be set
    * @param value      new value of spell option
    * 
    * @return boolean   success of calling _spell_option - does 
    *                   not verify that value was changed.
    */
   private static boolean setSpellOption(SetOptionInfo &soi, _str value)
   {
      _spell_option(soi.Value, value);
      _macro_call("_spell_option("soi.Name", "value");");

      return true;
   }

   /** 
    * Sets a default option using the information provided in 
    * SettingInfo struct to the value specified.  Also makes a 
    * macro call in case we're currently recording. 
    * 
    * @param info       information about default option to be set
    * @param value      new value of default option
    * 
    * @return boolean   success of calling _default_option - does 
    *                   not verify that value was changed.
    */
   private static boolean setDefaultOption(SetOptionInfo soi, _str value)
   {
      _default_option(soi.Value, value);
      _macro_call("_default_option("soi.Name", "value");");

      return true;
   }

   /** 
    * Sets the value of a default color parameter using 
    * _default_color.  Sets both the foreground and background 
    * colors to the same value. 
    * 
    * @param info    SettingInfo struct - uses Name and Value to 
    *                set the value and create a recorded macro
    *                command
    * @param value   the new color that will be set
    * 
    * @return boolean   success of calling _default_color - does 
    *                   not verify that color was set correctly.
    */
   private static boolean setDefaultColor(SetDefaultColorInfo &scoi, _str value)
   {
      typeless fg, bg, ff;

      if (scoi.Value) {
         parse _default_color(scoi.Value) with fg bg ff;
   
         fg = bg = hex2dec(value);
   
         _default_color(scoi.Value, fg, bg, ff);
         _macro_call("_default_color("scoi.Name", ":+
                     fg:+", ":+
                     bg:+", ":+
                     dec2hex(ff):+");");
         return true;
      }
      return false;
   }

   /** 
    * Sets a variable value using its index in the names table. 
    * Also makes associated macro call in case we are recording a 
    * macro. 
    * 
    * @param info       contains info about variable to be set and 
    *                   how to set it
    * @param value      new value (variable may be set equal to new 
    *                   value or have it ORed in)
    * 
    * @return boolean   whether set was successful - does not 
    *                   verify the new value of variable
    */
   private static boolean setVariableProperty(SettingInfo &info, _str value)
   {
      SetVariableInfo svi = info.SettingTypeInfo;
      if (svi.Index > 0) {
         _set_var(svi.Index, value);
   
         if (info.ValueType == INT) _macro_append(svi.Name"="dec2hex((long)value)";");
         else _macro_append(svi.Name"="value";");

         return true;
      }

      return false;
   }
   
   /**
    * Calls a function which sets a value.  Function should be
    * multi-purpose such that can use the same function to get and
    * set value.
    * 
    * @param info       contains info on how to call the my function 
    * @param value      value to be set
    * 
    * @return boolean   success of function call - does not verify 
    *                   that value was actually set
    *         
    * See {@link _getFunctionProperty}.
    */
   private static boolean setFunctionProperty(SettingInfo &info, _str value, int checkState = null)
   {
      SetFunctionInfo sfi = info.SettingTypeInfo;
      if (sfi.Index > 0) {
         typeless extraArg = '';
         if (info.FunctionKey) {
            extraArg = info.FunctionKey;
         } else if (info.Language != '') {
            extraArg = info.Language;
         } else if (info.VCProvider != '') {
            extraArg = info.VCProvider;
         }

         if (extraArg != '') {
            if (info.GetCheckState) {
               call_index(extraArg, value, checkState, sfi.Index);
               _macro_append(sfi.Name'('extraArg','value','checkState')');
            } else {
               call_index(extraArg, value, sfi.Index);
               _macro_append(sfi.Name'('extraArg','value')');
            }
         } else {
            if (info.GetCheckState) {
               call_index(value, checkState, sfi.Index);
               _macro_append(sfi.Name'('value','checkState')');
            } else {
               call_index(value, sfi.Index);
               _macro_append(sfi.Name'('value')');
            }
         }

         return true;
      }

      return false;
   }

   /**
    * Calls a function in the se.lang.api.LanguageSettings API which sets a 
    * value. 
    * 
    * @param info       contains info on how to call the function 
    * @param value      value to be set
    * 
    * @return boolean   success of function call - does not verify 
    *                   that value was actually set
    *         
    * See {@link _getLanguageSetting}.
    */
   private static boolean setLanguageSetting(SettingInfo &info, _str value, int checkState = null)
   {
      SetLanguageSettingInfo slsi = info.SettingTypeInfo;
      if (index_callable(slsi.SetIndex)) {
         if (info.GetCheckState) {
            call_index(info.Language, value, checkState, slsi.CreateNewLang, slsi.SetIndex);
            _macro_append('se.lang.api.LanguageSettings.set'slsi.Setting'('info.Language','value','checkState','slsi.CreateNewLang')');
         } else {
            call_index(info.Language, value, slsi.CreateNewLang, slsi.SetIndex);
            _macro_append('se.lang.api.LanguageSettings.set'slsi.Setting'('info.Language','value','slsi.CreateNewLang')');
         }
         return true;
      }
      return false;
   }

   /**
    * Calls a function in the se.vc.VersionControlSettings API
    * which sets a value. 
    * 
    * @param info       contains info on how to call the function 
    * @param value      value to be set
    * 
    * @return boolean   success of function call - does not verify 
    *                   that value was actually set
    *         
    * See {@link _getVersionControlSetting}.
    */
   private static boolean setVersionControlSetting(SettingInfo &info, _str value, int checkState = null)
   {
      SetVersionControlSettingInfo svcsi = info.SettingTypeInfo;
      if (index_callable(svcsi.SetIndex)) {
         // make sure this version control provider exists
         if (!VersionControlSettings.isValidProviderID(info.VCProvider)) {
            VersionControlSettings.addProvider(info.VCProvider);
         }

         if (info.GetCheckState) {
            call_index(info.VCProvider, value, checkState, svcsi.SetIndex);
            _macro_append('se.vc.VersionControlSettings.set'svcsi.Setting'('info.VCProvider','value','checkState')');
         } else {
            call_index(info.VCProvider, value, svcsi.SetIndex);
            _macro_append('se.vc.VersionControlSettings.set'svcsi.Setting'('info.VCProvider','value')');
         }

         return true;
      }
      return false;
   }

   public static boolean setCheckedSetting(SettingInfo &info, _str value, int checkState)
   {
      if (translateDisplayToValue(info, value)) {
         if (info.SettingType == FUNCTION) {
            return setFunctionProperty(info, value, checkState);
         } else if (info.SettingType == LANGUAGE_SETTING) {
            return setLanguageSetting(info, value);
         } else if (info.SettingType == VERSION_CONTROL_SETTING) {
            return setVersionControlSetting(info, value);
         }
      }

      return false;
   }

   /** 
    * Sets an option value.
    * 
    * @param info       info on how to set the value
    * @param value      value to be set
    * 
    * @return boolean   success of set operation - does not verify 
    *                   that value was actually changed.
    */
   public static boolean setSetting(SettingInfo &info, _str value)
   {
      if (translateDisplayToValue(info, value)) {
         if (info.SettingType == VARIABLE) {
            return setVariableProperty(info, value);
         } else if (info.SettingType == FUNCTION) {
            return setFunctionProperty(info, value);
         } else if (info.SettingType == DEFAULT_OPTION) {
            return setDefaultOption(info.SettingTypeInfo, value);
         } else if (info.SettingType == DEFAULT_COLOR) {
            return setDefaultColor(info.SettingTypeInfo, value);
         } else if (info.SettingType == SPELL_OPTION) {
            return setSpellOption(info.SettingTypeInfo, value);
         } else if (info.SettingType == LANGUAGE_SETTING) {
            return setLanguageSetting(info, value);
         } else if (info.SettingType == VERSION_CONTROL_SETTING) {
            return setVersionControlSetting(info, value);
         } 
      } 

      return false;
   }
};
