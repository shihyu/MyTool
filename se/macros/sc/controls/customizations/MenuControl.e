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
#require "UserControl.e"
#endregion

namespace sc.controls.customizations;

class MenuControl : UserControl {
   // help topic brought up when user asks for help on this menu item
   private _str m_help = '';
   // categories value associated with this menu item
   private _str m_categories = '';
   // caption of parent menu
   private _str m_parentCaption = '';
   // true if this menu item is a submenu
   private bool m_subMenu = false;

   /**
    * Returns the string used to identify this control.
    * 
    * @return _str            identifying string
    */
   public _str getIdentifier()
   {
      // take the & out when we are comparing this as an identifier
      caption := '';
      if (m_caption != null) {
         caption = stranslate(m_caption, '', '&');
      }

      // put the parent caption at the beginning
      if (m_parentCaption != '') {
         caption = m_parentCaption'>'caption;
      }

      return caption;
   }

   /**
    * Returns the help topic associated with this MenuControl.
    *  
    * @return _str 
    */
   public _str getHelp()
   {
      return m_help;
   }

   /**
    * Sets the help topic associated with this MenuControl.
    * 
    * @param help 
    */
   public void setHelp(_str help)
   {
      m_help = help;
   }

   /**
    * Gets the parent caption of the menu item represented by this MenuControl. 
    *  
    * @return _str 
    */
   public _str getParentCaption()
   {
      return m_parentCaption;
   }

   /**
    * Sets the parent caption of the menu item represented by this MenuControl. 
    * 
    * @param parentCaption 
    */
   public void setParentCaption(_str parentCaption)
   {
      m_parentCaption = parentCaption;
   }

   /**
    * Returns the categories value associated with this MenuControl.
    * 
    * @return _str 
    */
   public _str getCategories()
   {
      return m_categories;
   }

   /**
    * Sets the categories value associated with this MenuControl.
    * 
    * @param categories 
    */
   public void setCategories(_str categories)
   {
      m_categories = categories;
   }

   /**
    * Returns whether the menu item represented by this MenuControl is a submenu.
    * 
    * @return bool
    */
   public bool getSubMenu()
   {
      return m_subMenu;
   }

   /**
    * Sets whether the menu item represented by this MenuControl is a submenu.
    * 
    * @param submenu
    */
   public void setSubMenu(bool subMenu)
   {
      m_subMenu = subMenu;
   }
};

