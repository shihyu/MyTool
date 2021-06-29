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
#import "cfg.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

namespace se.lang.api;

/**
 * This class is used to save and retrieve the extension-specific 
 * options.  These used to be accessed by changing def-vars directly.  Now 
 * all items can be accessed through static getter and setter methods in this 
 * class. 
 * 
 */
class ExtensionSettings {

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
    * @param ignoreSuffix     (optional) ignore this file extension suffix and 
    *                         try to map the file based on the inner file name
    *                         and/or extension.
    *
    * @see _CreateLanguage
    * @categories Miscellaneous_Functions
    */
   public static void createExtension(_str extension, _str langId, _str encoding="", _str openApp="", bool useAssociation = false, bool ignoreSuffix = false)
   {
       _CreateExtension(extension, langId, encoding, openApp, (int)useAssociation, (int)ignoreSuffix);
   }

   /**
    * Determines if an extension is defined in the application. 
    * 
    * @param langId              extension to look for
    * 
    * @return bool               true if the given extension is mapped to a 
    *                            language.
    */
   public static bool isExtensionDefined(_str extension)
   {
      value:=_plugin_get_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_FILE_EXTENSIONS,'langid-'extension);
      return value!='';
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
      lang := _Ext2LangId(ext);
      if (lang == '') {
         return null;
      }

      return lang;
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
      _ExtensionSetRefersTo(ext, langID);
   }

   /**
    * Checks if the given file extension is to be ignored, as is useful for .bak 
    * This value is available on the File Extension Manager. 
    *
    * @param ext                 extension to get value for
    *
    * @return                    'true' if the file extension should be ignored
    */
   public static bool getExtensionIgnoreSuffix(_str ext)
   {
      return _ExtensionGetIgnoreSuffix(ext);
   }

   /**
    * Sets the given file extension to be ignored, as is useful for .bak 
    * This value is available on the File Extension Manager. 
    *
    * @param ext                 extension to get value for
    * @param value               new value
    */
   public static void setExtensionIgnoreSuffix(_str ext, bool yesno)
   {
      _ExtensionSetIgnoreSuffix(ext, yesno);
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
      encoding := _ExtensionGetEncoding(ext);
      if (encoding == '') encoding = defaultValue;

      return encoding;
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
      _ExtensionSetEncoding(ext, value);
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
   public static bool getUseFileAssociation(_str ext)
   {
      _ExtensionGetFileAssociation(ext, auto useFA, auto openApp);

      return (useFA != 0);
   }

   /**
    * Sets the file association for this extension.  This value 
    * is available on the File Extension Manager. 
    *
    * @param ext                 extension to get value for
    * @param value               new value
    */
   public static void setUseFileAssociation(_str ext, bool value)
   {
      _ExtensionGetFileAssociation(ext, auto useFA, auto openApp);
      _ExtensionSetFileAssociation(ext, (int)value, openApp);
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
   public static _str getOpenApplication(_str ext, _str defaultValue = "")
   {
      _ExtensionGetFileAssociation(ext, auto useFA, auto openApp);
      if (openApp == '') openApp = defaultValue;

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
      _ExtensionGetFileAssociation(ext, auto useFA, auto openApp);
      _ExtensionSetFileAssociation(ext, useFA, value);
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
      dtd := _ExtensionGetDefaultDTD(ext);
      if (dtd == '') dtd = defaultValue;

      return dtd;
   }

   /**
    * Sets the default DTD file for this extension.  
    * 
    * @param langID              language to set value for
    * @param value               new value
    */
   public static void setDefaultDTD(_str ext, _str value)
   {
      _ExtensionSetDefaultDTD(ext, value);
   }
};
