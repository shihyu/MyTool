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
#endregion

namespace sc.controls.customizations;

/**
 * Holds information for a control for use with the CustomizationHandler.  Can 
 * be inherited from to add additional information relevant to your specific 
 * control type.
 */
class UserControl {
   // caption of this control
   protected _str m_caption = '';
   // command launched by this control
   protected _str m_command = '';
   // information displayed to the user about this control
   protected _str m_message = '';

   /**
    * Returns the string used to identify this control.  May be overwritten.
    * 
    * @return _str            identifying string
    */
   public _str getIdentifier()
   {
      return m_command;
   }

   /**
    * Returns the command associated with this UserControl
    * 
    * @return _str 
    */
   public _str getCommand()
   {
      return m_command;
   }

   /**
    * Sets the command associated with this UserControl.
    * 
    * @param command 
    */
   public void setCommand(_str command)
   {
      m_command = command;
   }

   /**
    * Returns the message associated with this UserControl
    * 
    * @return _str 
    */
   public _str getMessage()
   {
      return m_message;
   }

   /**
    * Sets the message associated with this UserControl.
    * 
    * @param msg 
    */
   public void setMessage(_str msg)
   {
      m_message = msg;
   }

   /**
    * Returns the caption associated with this UserControl
    * 
    * @return _str 
    */
   public _str getCaption()
   {
      return m_caption;
   }

   /**
    * Sets the caption associated with this UserControl.
    * 
    * @param caption 
    */
   public void setCaption(_str caption)
   {
      m_caption = caption;
   }
};

