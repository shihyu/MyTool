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
#require "DialogTransformer.e"
#import "propertysheetform.e"
#endregion Imports

namespace se.options;

struct FormFunctions {
   int ExportSettings;
   int ImportSettings;
   int BuildExportSummary;
   int ImportSummary;
};

class DialogExporter : DialogTransformer {

   private FormFunctions m_functions;        // the callbacks used to export/import this dialog
   private typeless m_importFiles = "";      // any files that are used in the export/import
   private _str m_importArgs = "";           // any arguments to be sent to the import callback
   private int m_eventFlags = 0;             // events that must occur when this dialog is imported
   private PropertySheetItem m_summary[];    // summary of items set by this dialog

   DialogExporter(_str caption = "", _str panelHelp = "", _str systemHelp = "",
                     _str form = "", int index = 0, _str inheritsFromForm = "")
   {
      DialogTransformer(caption, panelHelp, systemHelp, form, index, inheritsFromForm);

      m_summary._makeempty();
   }

   /**
    * Sets the indices from the names table of our callback
    * functions.  Functions which are not found are set at 0.
    *
    */
   private void findFormFunctions()
   {
      m_functions.ExportSettings = findFormCallback("_export_settings");
      m_functions.ImportSettings = findFormCallback("_import_settings");
      m_functions.BuildExportSummary = findFormCallback("_build_export_summary");
      m_functions.ImportSummary = findFormCallback("_import_summary");
   }


   /**
    * Returns the type of panel for this object.
    * 
    * @return        the OPTIONS_PANEL_TYPE of this object
    */
   public int getPanelType()
   {
      if (isSummaryType()) {
         return OPT_DIALOG_SUMMARY_EXPORTER;
      } else return OPT_DIALOG_FORM_EXPORTER;
   }

   /**
    * Determines whether this dialog is imported by summary.
    * 
    * @return              true if this dialog is imported by summary, false if the 
    *                      argument/files method is used
    */
   private bool isSummaryType()
   {
      return (m_functions.BuildExportSummary > 0);
   }

   public void initializeSummary(int psWid, int helpHandle)
   {
      m_wid = psWid;
      m_wid._property_sheet_form_init_for_summary(m_summary, helpHandle);
   }

   /**
    * Builds the export summary used by this dialog to export/import its options.
    * 
    * @return              any errors returned by the callback, '' if no errors 
    *                      were found
    */
   public _str buildSummary()
   {
      result := "";
      if (m_functions.BuildExportSummary <= 0) {
         result = "No export summary callback found for form: ":+getFormName();
         return result;
      }
      
      if (m_langID != "") {
         result = callFunction(m_functions.BuildExportSummary, m_summary, m_langID);
      } else if (m_vcProviderID != "") {
         result = callFunction(m_functions.BuildExportSummary, m_summary, m_vcProviderID);
      } else {
         result = callFunction(m_functions.BuildExportSummary, m_summary);
      }
      
      return result;
   }

   /**
    * Imports the options for this dialog by sending the summary items to the 
    * FormFunctions.ImportSummary callback. 
    * 
    * @return              any errors returned by the FormFunctions.ImportSummary 
    *                      callback, '' if no errors were found.
    */
   private _str importSummary()
   {
      result := "";
      if (m_functions.ImportSummary <= 0) {
         result = "No import callback found for form:":+getFormName();
         return result;
      }

      if (m_langID != "") {
         result = callFunction(m_functions.ImportSummary, m_summary, m_langID);
      } else if (m_vcProviderID != "") {
         result = callFunction(m_functions.ImportSummary, m_summary, m_vcProviderID);
      } else {
         result = callFunction(m_functions.ImportSummary, m_summary);
      }
      
      return result;
   }

   /**
    * Imports a dialog's options.
    * 
    * @return              any errors returned by the import, '' if no errors were
    *                      found.
    */
   public _str import()
   {
      if (isSummaryBuilt()) {
         return importSummary();
      } else {
         return importSettings();
      }
   }

   private _str importSettings()
   {
      result := "";
      if (m_functions.ImportSettings <= 0) {
         result = "No import callback found for form: ":+getFormName();
         return result;
      }
      
      if (m_langID != "") {
         result = callFunction(m_functions.ImportSettings, m_importFiles, m_importArgs, m_langID);
      } else if (m_vcProviderID != "") {
         result = callFunction(m_functions.ImportSettings, m_importFiles, m_importArgs, m_vcProviderID);
      } else {
         result = callFunction(m_functions.ImportSettings, m_importFiles, m_importArgs);
      }
      
      return result;
   }

   public _str export(_str path)
   {
      if (isSummaryType()) {
         if (!isSummaryBuilt()) {
            buildSummary();
         }
         return "";
      } else {
         return exportSettings(path);
      }
   }

   private _str exportSettings(_str path)
   {
      result   := "";
      origPath := path;

      if (m_functions.ExportSettings <= 0) {
         result = "No export callback found for form: ":+getFormName();
         return result;
      }

      if (m_langID != "") {
         result = callFunction(m_functions.ExportSettings, path, m_importArgs, m_langID);
      } else if (m_vcProviderID != "") {
         result = callFunction(m_functions.ExportSettings, path, m_importArgs, m_vcProviderID);
      } else {
         result = callFunction(m_functions.ExportSettings, path, m_importArgs);
      }

      if (origPath != path) {
         m_importFiles = path;
      }

      return result;
   }

   public void setImportFilenames(_str path, _str files)
   {
      typeless fileArgument;

      _str filesArray[];
      split(files, ",", filesArray);

      if (filesArray._length() == 1) {
         m_importFiles = path :+ files;
      } else {
         foreach (auto filename in filesArray) {
            m_importFiles[m_importFiles._length()] = path :+ filename;
         }
      }

   }

   public _str getImportFilenamesAsString()
   {
      if (m_importFiles._typename() == "_str") {
         return m_importFiles;
      } else {
         files := "";
         foreach (auto filename in m_importFiles) {
            files = filename",";
         }

         files = substr(files, 1, length(files) - 1);
         return files;
      }

   }

   public void setImportArguments(_str args)
   {
      m_importArgs = args;
   }

   public _str getImportArguments()
   {
      return m_importArgs;
   }

   public int getNumSummaryItems()
   {
      return m_summary._length();
   }

   public bool isSummaryBuilt()
   {
      return m_summary._length() > 0;
   }

   public PropertySheetItem * getSummaryItem(int index)
   {
      return &(m_summary[index]);
   }

   public void addSummaryItem(PropertySheetItem dsi)
   {
      m_summary[m_summary._length()] = dsi;
      if (dsi.ChangeEvents != null) {
         m_eventFlags |= dsi.ChangeEvents;
      }
   }

   /**
    * Sets the event flags for this dialog.
    * 
    * @param f      flag to set
    */
   public void setChangeEventFlags(OptionsChangeEventFlags f)
   {
      m_eventFlags = f;
   }
   
   /**
    * Gets the event flag for this dialog.
    * 
    * @return      event flags
    */
   public int getChangeEventFlags()
   {
      return m_eventFlags;
   }
};
