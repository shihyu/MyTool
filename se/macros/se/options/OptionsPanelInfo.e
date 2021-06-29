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

/**
 * The different types of 'options panels', meaning the 
 * different types of panel which can be in the right side of 
 * the options dialog, depending on which node in the tree on 
 * the left side is selected. 
 */
enum OPTIONS_PANEL_TYPE {
   OPT_UNKNOWN = -1,
   OPT_PROPERTY_SHEET = 0,
   OPT_DIALOG_EMBEDDER = 1,
   OPT_CATEGORY_HELP = 2,
   OPT_DIALOG_FORM_EXPORTER = 3,
   OPT_DIALOG_TAGGER = 4,
   OPT_DIALOG_SUMMARY_EXPORTER = 5,
};

/** 
 * Base class for classes holding information about panels that
 * will appear in the right hand side of the options tree
 * depending on the selected node.
 */
class OptionsPanelInfo {
   private _str m_caption;            // caption of node associated with this panelHelp
   private _str m_panelHelp;          // help information that will appear directly in the dialog
   private _str m_systemHelp;         // p_help tag for this panel in the Help System 
   private _str m_picture;            // picture for node associated with this panelHelp

   /**
    * Constructor.
    * 
    */
   OptionsPanelInfo(_str caption = '', _str panelHelp = '', _str systemHelp = '', _str picture = '')
   {
      m_caption = caption;
      m_panelHelp = panelHelp;
      m_systemHelp = systemHelp;
      m_picture = picture;
   }

   /**
    * Sets the panel help for this object.  Panel help is displayed
    * in the options dialog itself.
    * 
    * @param help   help information
    */
   public void setPanelHelp(_str help)
   {
      m_panelHelp = help;
   }

   /**
    * Sets the panel help for this object.  Panel help is displayed
    * in the options dialog itself.
    * 
    * @return   help information
    */
   public _str getPanelHelp()
   {
      return m_panelHelp;
   }

   /**
    * Sets the system help for this object.  System help is a 
    * p_help tag that is used to navigate to the corresponding 
    * section of the help documentation. 
    * 
    * @param   help information
    */
   public void setSystemHelp(_str help)
   {
      m_systemHelp = help;
      if (help == '') {
         m_systemHelp = m_caption;
      }
   }

   /**
    * Sets the system help for this object.  System help is a 
    * p_help tag that is used to navigate to the corresponding 
    * section of the help documentation. 
    * 
    * @return   help information
    */
   public _str getSystemHelp()
   {
      return m_systemHelp;
   }

   /**
    * Sets the caption for this object
    * 
    * @param value      new caption
    */
   public void setCaption(_str value)
   {
      m_caption = value;
   }

   /**
    * Gets the caption for this object
    * 
    * @return        caption
    */
   public _str getCaption()
   {
      return m_caption;
   }


   /**
    * Sets the caption icon/picture for this object
    * 
    * @param value      new icon for this panel
    */
   public void setPicture(_str value)
   {
      m_picture = value;
   }

   /**
    * Gets the caption icon/picture for this object
    * 
    * @return        icon for this panel
    */
   public _str getPicture()
   {
      return m_picture;
   }


   /**
    * Returns the type of panel for this object.
    * 
    * @return        the OPTIONS_PANEL_TYPE of this object
    */
   public int getPanelType()
   {
      return OPT_UNKNOWN;
   }
};
