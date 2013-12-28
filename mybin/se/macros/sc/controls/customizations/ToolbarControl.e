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
#require "UserControl.e"
#endregion

namespace sc.controls.customizations;

enum TBControlType {
   TBCT_PIC_BUTTON,
   TBCT_COMBO,
   TBCT_SEPARATOR,
   TBCT_USER_BUTTON,
}

class ToolbarControl : UserControl {
   // type of toolbar control (one of TBControlType)
   private int m_type = -1;
   // picture name (may be just filename or full path)
   private _str m_picture = '';

   /**
    * Sets the command for this ToolbarControl.  
    * 
    * @param command          command
    */
   public void setCommand(_str command)
   {
      // make sure all the dashes are turned to underscores
      if (command != null) {
         command = stranslate(command, '_', '-');
      }
      UserControl.setCommand(command);
   }

   /**
    * Returns the type of the Toolbar button represented by this ToolbarControl. 
    * One of the TBControlType enum. 
    * 
    * @return int 
    */
   public int getType()
   {
      return m_type;
   }

   /**
    * Sets the type of the Toolbar button represented by this ToolbarControl. 
    * One of the TBControlType enum. 
    *  
    * @param type 
    */
   public void setType(int type)
   {
      m_type = type;
   }

   /**
    * Returns the picture associated with this UserControl.  May be just a file 
    * name or a full path to the picture file. 
    * 
    * @param _str 
    */
   public _str getPicture()
   {
      return m_picture;
   }

   /**
    * Sets the picture associated with this UserControl.  May be just a file name 
    * or a full path to the picture file. 
    * 
    * @param picture 
    */
   public void setPicture(_str picture)
   {
      m_picture = picture;
   }
};

