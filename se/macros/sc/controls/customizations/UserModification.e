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
 * Enum of Actions that a user can do to a Menu or Toolbar item.
 */
enum ModificationActions {
   MA_ADD,
   MA_REMOVE,
   MA_CHANGE,
   MA_DUPE,
};

/**
 * This class is used to keep track of modifications that users make to 
 * UserControls.   
 */
class UserModification {
   protected _str m_command = '';         // command of modified UserControl
   protected _str m_caption = '';         // caption of modified UserControl
   protected _str m_message = '';         // message of modified UserControl
   protected int m_action = -1;           // Modification action, one of the ModificationActions enum

   protected _str m_prev = '';            // identifier of previous UserControl
   protected _str m_next = '';            // identifier of next UserControl

   /**
    * Constructor.  Doesn't do much.
    */
   UserModification() { }

   /**
    * Retrieves the command.
    * 
    * @return        command
    */
   public _str getCommand()
   {
      return m_command;
   }

   /**
    * Sets the command.
    * 
    * @param command          new command value
    */
   public void setCommand(_str command)
   {
      m_command = command;
   }

   /**
    * Retrieves the message.
    * 
    * @return        message
    */
   public _str getMessage()
   {
      return m_message;
   }

   /**
    * Sets the message.
    * 
    * @param msg              new message value
    */
   public void setMessage(_str msg)
   {
      m_message = msg;
   }

   /**
    * Retrieves the caption.
    * 
    * @return        caption
    */
   public _str getCaption()
   {
      return m_caption;
   }

   /**
    * Sets the caption.
    * 
    * @param caption          new caption value
    */
   public void setCaption(_str caption)
   {
      m_caption = caption;
   }

   /**
    * Retrieves the action, which corresponds to one of the ModificationAction 
    * enum. 
    * 
    * @return        action
    */
   public int getAction()
   {
      return m_action;
   }

   /**
    * Sets the action.
    * 
    * @param action           new action value
    */
   public void setAction(int action)
   {
      m_action = action;
   }

   /**
    * Retrieves the next UserControl's identifier.  If this UserControl is the 
    * last in the list, LAST_ITEM_TEXT is returned. 
    * 
    * @return        next UserControl identifier
    */
   public _str getNext()
   {
      return m_next;
   }

   /**
    * Sets the the next UserControl's identifier.  If this UserControl is the 
    * last in the list, set this value to LAST_ITEM_TEXT. 
    * 
    * @param next             new next UserControl identifier
    */
   public void setNext(_str next)
   {
      m_next = next;
   }

   /**
    * Retrieves the previous UserControl's identifier.  If this UserControl is 
    * the first in the list, FIRST_ITEM_TEXT is returned. 
    * 
    * @return        previous UserControl identifier
    */
   public _str getPrev()
   {
      return m_prev;
   }

   /**
    * Sets the the previous UserControl's identifier.  If this UserControl is 
    * the first in the list, set this value to FIRST_ITEM_TEXT. 
    * 
    * @param prev             new previous UserControl identifier
    */
   public void setPrev(_str prev)
   {
      m_prev = prev;
   }
};

