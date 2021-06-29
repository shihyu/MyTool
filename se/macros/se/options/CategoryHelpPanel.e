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
#require "OptionsPanelInfo.e"
#endregion Imports

namespace se.options;

/** 
 * Represents a category in the options dialog.  When a category
 * is selected, the right panel shows information about the
 * category.  This class holds that information.
 */
class CategoryHelpPanel : OptionsPanelInfo {

   /**
    * Constructor.  Calls on OptionsPanelInfo base class.
    * 
    */
   CategoryHelpPanel(_str caption = '', _str panelHelp = '', _str systemHelp = '')
   {
      OptionsPanelInfo(caption, panelHelp, systemHelp);
   }

   /**
    * Returns the type of panel for this object.
    * 
    * @return        the OPTIONS_PANEL_TYPE of this object
    */
   public int getPanelType()
   {
      return OPT_CATEGORY_HELP;
   }
};
