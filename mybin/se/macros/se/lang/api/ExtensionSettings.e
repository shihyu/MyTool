////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45237 $
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
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

namespace se.lang.api;

#define ASSOCIATION_DEF_VAR_KEY                 'association'
#define DEFAULT_DTD_DEF_VAR_KEY                 'default-dtd'
#define ENCODING_DEF_VAR_KEY                    'encoding'
#define LANG_REFERS_TO_DEF_VAR_KEY              'lang-for-ext'
#define LANGUAGE_OPTIONS_KEY                    "LanguageOptions"

/**
 * This class is used to save and retrieve the extension-specific 
 * options.  These used to be accessed by changing def-vars directly.  Now 
 * all items can be accessed through static getter and setter methods in this 
 * class. 
 * 
 */
class ExtensionSettings {

   /**
    * Clear the language options cache
    */
   static void clearLanguageOptionsCache()
   {
      _SetDialogInfoHt(LANGUAGE_OPTIONS_KEY, null, _mdi);
   }

   /**
    * Creates file extension specific setup data which is used by the
    * File Extension Manager options dialog.  This procedure is typically used 
    * when associating a physical file extension with a specific language, or when
    * setting up encoding and application preferences for a physical file 
    * extension. 
    *  
    * @example 
    * <pre>
    *    ExtensionSettings.createExtension('ada', 'ada');
    *    ExtensionSettings.createExtension('ads', 'ada');
    * </pre>
    *  
    * @param extension        File extension to be configured.
    * @param langId           Language ID (see {@link p_LangId} 
    * @param encoding         (optional) default file encoding 
    * @param openApplication  (optional) path for external application used to 
    *                         open this type of file when double-clicked on in
    *                         project file browser.
    * @param useAssociation   (optional, Windows only) use Windows file 
    *                         association to select application for opening this
    *                         type of file when double-clicked on in the
    *                         project file browser.
    *
    * @return Returns the name index of the setup information created.
    * 
    * @see _CreateLanguage
    * @categories Miscellaneous_Functions
    */
   public static int createExtension(_str extension, _str langId, _str encoding = null, _str openApp = null, boolean useAssoc = false)
   {
      // new extension, so clear language/extension options cache
      clearLanguageOptionsCache();

      // no language, so refer it to fundamental
      if (langId == '') langId = 'fundamental';

      // make sure ref_language is valid
      if (!LanguageSettings.isLanguageDefined(langId)) return STRING_NOT_FOUND_RC;

      // check if the extension is already set up
      if (!isExtensionDefined(extension)) {
         // not already set, so create the extension
         insert_name('def-lang-for-ext-'extension, MISC_TYPE, langId);
      }

      // set the language
      setLangRefersTo(extension, langId);

      // did they want to specify a file encoding
      if (encoding != null) { 
         setEncoding(extension, encoding);
      }

      // or an open application?
      if (openApp != null) { 
         setOpenApplication(extension, openApp);

         // go ahead and set the association, too
         setUseFileAssociation(extension, useAssoc);
      } else if (useAssoc) {

         // go ahead and set the association, too
         setUseFileAssociation(extension, useAssoc);
      }

      index := find_index('def-lang-for-ext-'extension, MISC_TYPE);
      return index;
   }

   /**
    * Determines if an extension is defined in the application. 
    * 
    * @param langId              extension to look for
    * 
    * @return boolean            true if the given extension is mapped to a 
    *                            language.
    */
   public static boolean isExtensionDefined(_str extension)
   {
      index := find_index('def-lang-for-ext-'extension, MISC_TYPE);
      return (index > 0);
   }

   /**
    * Retrieves the name of the id-specific def-var for the given 
    * id and def-var key. 
    * 
    * @param id                  extension
    * @param defVarKey           def-var key
    * 
    * @return                    name of def-var in names table
    */
   private static _str getDefVarName(_str id, _str defVarKey)
   {
      // yup, it really is that simple
      return 'def-'defVarKey'-'id;
   }

   /**
    * Retrieves an extension-specific def-var.
    * 
    * @param extension           extension to retrieve def-var for 
    * @param defVarKey           key to the def-var
    * @param defaultValue        default value to be used in case the def-var is 
    *                            not present.  
    * 
    * @return                    extension-specific def-var value
    */
   private static typeless getExtensionDefVar(_str ext, _str defVarKey, _str defaultValue)
   {
      defVarName := getDefVarName(ext, defVarKey);
      if (defaultValue == null) defaultValue = getDefaultDefVarValue(defVarKey, ext);

      return getDefVar(defVarName, defaultValue);
   }

   /**
    * Sets the value of an extension-specific def-var.
    * 
    * @param langID              extension to retrieve def-var for
    * @param defVarKey           key to the def-var
    * @param value               new value 
    */
   private static int setExtensionDefVar(_str ext, _str defVarKey, typeless value)
   {
      // changed an extension option, so clear cache
      clearLanguageOptionsCache();

      defVarName := getDefVarName(ext, defVarKey);
      defaultValue := getDefaultDefVarValue(defVarKey, ext);

      return setDefVar(defVarName, value, defaultValue);
   }

   /**
    * Retrieves the default value for the given def-var.  If the def-var is not in 
    * the names table for a language, then this value is used.  Likewise, when 
    * setting a language-specific def-var to this value, we'll often just delete 
    * the name instead. 
    * 
    * @param defVarKey           def-var key
    * 
    * @return                    default value of def-var
    */
   private static typeless getDefaultDefVarValue(_str defVarKey, _str id)
   {
      typeless defaultValue;

      switch (defVarKey) {
      case ASSOCIATION_DEF_VAR_KEY:
         defaultValue = '0 ';
         break;
      case DEFAULT_DTD_DEF_VAR_KEY:
      case ENCODING_DEF_VAR_KEY:
      case LANG_REFERS_TO_DEF_VAR_KEY:
      default:
         defaultValue = '';
         break;
      }

      return defaultValue;
   }

   /**
    * Gets the language id for the language that this extension refers to.  This
    * value is available on the File Extension Manager. 
    *
    * @param ext                 extension to get value for
    * @param defaultValue        if the value is not available, then we just return
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    *
    * @return                    the language this extension refers to
    */
   public static _str getLangRefersTo(_str ext)
   {
      // there is no default value on this one - this sort of defines the extension, 
      // so if it's not there, the extension doesn't exist
      return getExtensionDefVar(ext, LANG_REFERS_TO_DEF_VAR_KEY, null);
   }

   /**
    * Sets the language that this extension refers
    * to.  This value is available on the File 
    * Extension Manager. 
    *
    * @param ext                 extension to get value for
    * @param value               new value
    */
   public static void setLangRefersTo(_str ext, _str langID)
   {
      setExtensionDefVar(ext, LANG_REFERS_TO_DEF_VAR_KEY, langID);
   }

   /**
    * Gets the encoding for this extension.  This value is available on the File
    * Extension Manager.
    *
    * @param ext                 extension to get value for
    * @param defaultValue        if the value is not available, then we just return
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    *
    * @return                    encoding info for this extension
    */
   public static _str getEncoding(_str ext, _str defaultValue = null)
   {
      return getExtensionDefVar(ext, ENCODING_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the encoding for this extension.  This value is 
    * available on the File Extension Manager. 
    *
    * @param ext                 extension to get value for
    * @param value               new value
    */
   public static void setEncoding(_str ext, _str value)
   {
      setExtensionDefVar(ext, ENCODING_DEF_VAR_KEY, value);
   }

   /**
    * Gets the file association for this extension.  This value is available on 
    * the File Extension Manager. 
    *
    * @param ext                 extension to get value for
    * @param defaultValue        if the value is not available, then we just return
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    *
    * @return                    whether to use file association for this 
    *                            extension
    */
   public static boolean getUseFileAssociation(_str ext, boolean defaultValue = 0)
   {
      associationInfo := getExtensionDefVar(ext, ASSOCIATION_DEF_VAR_KEY, null);
      parse associationInfo with auto useFA .;

      if (!isinteger(useFA)) {
         useFA = defaultValue;
      }

      return (useFA != 0);
   }

   /**
    * Sets the file association for this extension.  This value 
    * is available on the File Extension Manager. 
    *
    * @param ext                 extension to get value for
    * @param value               new value
    */
   public static void setUseFileAssociation(_str ext, boolean value)
   {
      associationInfo := getExtensionDefVar(ext, ASSOCIATION_DEF_VAR_KEY, null);
      parse associationInfo with auto useFA auto openApp;

      associationInfo = (int)value' 'openApp;

      setExtensionDefVar(ext, ASSOCIATION_DEF_VAR_KEY, associationInfo);
   }

   /**
    * Gets the open application info for this extension.  This value is available 
    * on the File Extension Manager. 
    *
    * @param ext                 extension to get value for
    * @param defaultValue        if the value is not available, then we just return
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    *
    * @return                    open application info for this extension 
    */
   public static _str getOpenApplication(_str ext, _str defaultValue = null)
   {
      associationInfo := getExtensionDefVar(ext, ASSOCIATION_DEF_VAR_KEY, null);
      parse associationInfo with . auto openApp;

      return openApp;
   }

   /**
    * Sets the open application info for this extension.  This 
    * value is available on the File Extension Manager. 
    *
    * @param ext                 extension to get value for
    * @param value               new value
    */
   public static void setOpenApplication(_str ext, _str value)
   {
      associationInfo := getExtensionDefVar(ext, ASSOCIATION_DEF_VAR_KEY, null);
      parse associationInfo with auto useFA auto openApp;

      associationInfo = useFA' 'value;

      setExtensionDefVar(ext, ASSOCIATION_DEF_VAR_KEY, associationInfo);
   }

   /**
    * Gets the default DTD file for this extension.  
    * 
    * @param langID              extension to get value for
    * @param defaultValue        if the value is not available, then we just return 
    *                            this value.  If this parameter is not specified,
    *                            then the default value for the overall def-var is
    *                            used.
    * 
    * @return                    default DTD file for this extension
    */
   public static _str getDefaultDTD(_str ext, _str defaultValue = null)
   {
      return getExtensionDefVar(ext, DEFAULT_DTD_DEF_VAR_KEY, defaultValue);
   }

   /**
    * Sets the default DTD file for this extension.  
    * 
    * @param langID              language to set value for
    * @param value               new value
    */
   public static void setDefaultDTD(_str ext, _str value)
   {
      setExtensionDefVar(ext, DEFAULT_DTD_DEF_VAR_KEY, value);
   }
};
