////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#require "UserModification.e"
#endregion

namespace sc.controls.customizations;

class MenuModification : UserModification {
   private _str m_parentCaption = '';              // caption of parent menu/submenu
   private _str m_help = '';                       // help message of this menu item
   private _str m_categories = '';                 // categories of this menu item
   private boolean m_subMenu = false;              // whether this item is a submenu

   MenuModification() {  }

   /**
    * Returns the help message of this menu item.
    * 
    * @return           help message
    */
   public _str getHelp()
   {
      return m_help;
   }

   /**
    * Sets the help message of this menu item.
    * 
    * @param help       help message
    */
   public void setHelp(_str help)
   {
      m_help = help;
   }

   /**
    * Returns the parent caption of this menu item.
    *
    * @return           parent caption
    */
   public _str getParentCaption()
   {
      return m_parentCaption;
   }

   /**
    * Sets the parent caption of this menu item.
    *
    * @param parentCaption    parent caption
    */
   public void setParentCaption(_str parentCaption)
   {
      m_parentCaption = parentCaption;
   }

   public _str getCategories()
   {
      return m_categories;
   }

   public void setCategories(_str categories)
   {
      m_categories = categories;
   }

   public boolean getSubMenu()
   {
      return m_subMenu;
   }

   public void setSubMenu(boolean subMenu)
   {
      m_subMenu = subMenu;
   }
};

