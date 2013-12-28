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
#endregion Imports

/**
 * Represents one of the choices in a Select Property.
 */
class SelectChoice {
   private _str m_caption;             // caption of this choice
   private _str m_value;               // value used to set this choice
   private _str m_conditions:[];       // any conditions that will prevent this 
                                       // choice from being available
   private _str m_flagName;            // if this value is actually a flag, we save that, too
   private boolean m_choosable;        // if false, this choice will be seen, 
                                       // but not available for selection by the user
   private boolean m_default;          // whether this choice is the default for the Select

   /**
    * Constructor.
    */
   SelectChoice(_str caption = '', _str value = '', _str flagName = '')
   {
      m_caption = caption;
      m_value = value;
      m_flagName = flagName;

      // choices are almost always choosable - we'll set it to false if necessary
      m_choosable = true;
      m_default = false;
   }

   /**
    * Adds a condition to this choice.  Conditions are variable, value pairs. 
    * For this choice to be enabled the specificed variable must be equal to the 
    * specified value. 
    *  
    * @param variable      variable to check
    * @param reqValue      required value of variable for choice to be available
    */
   public void addCondition(_str variable, _str reqValue)
   {
      index := find_index(variable, VAR_TYPE);
      if (index > 0) {
         m_conditions:[index] = reqValue;
      }
   }

   /**
    * Sets whether this choice is "choosable."  Choices default to being 
    * choosable, so this is mostly used to set the value to false. 
    * 
    * @param value      whether choice is choosable
    */
   public void setChoosable(boolean value)
   {
      m_choosable = value;
   }

   /**
    * Gets the caption for this choice.
    *  
    * @return        caption
    */
   public _str getCaption()
   {
      return m_caption;
   }

   /**
    * Gets the value for this choice.
    *  
    * @return        value
    */
   public _str getValue()
   {
      return m_value;
   }

   /**
    * Gets the flag name for this choice.  May be blank if the value was not a 
    * flag. 
    *  
    * @return        flag name
    */
   public _str getFlagName()
   {
      return m_flagName;
   }

   /**
    * Sets whether this choice is the default choice for this Select.  If this 
    * choice is the default, it will be selected when the value does not match 
    * any other choice. 
    * 
    * @param value      whether this choice is default
    */
   public void setDefault(boolean value)
   {
      m_default = value;
   }

   /**
    * Determines if this choice is available.  If a choice is not available, the 
    * user cannot see it or select it.  Even if the program thinks this value is 
    * the current value of the Select, the user will see "Error" 
    *  
    * Availability is determined by the conditions of this choice. 
    *  
    * @return        whether this choice is currently available
    */
   public boolean isAvailable()
   {
      // otherwise, we check our conditions
      foreach (auto checkVar => auto checkValue in m_conditions) {
         if (_get_var(checkVar) != checkValue) return false;
      }

      return true;
   }

   /**
    * Determine if this choice is choosable.  When a choice is not choosable, it 
    * can be the current value (and therefore viewable as the selection in a 
    * drop-down), but the user cannot select it (it is not listed in the 
    * drop-down). 
    *  
    * Choosability is determined from the options.xml file. 
    *  
    * @return        whether this choice is choosable
    */
   public boolean isChoosable()
   {
      return m_choosable;
   }

   /**
    * Determines if this choice has any conditions determining its availability. 
    *  If not, then it is available all the time. 
    *  
    * @return        whether this choice has any conditions on its availability
    */
   public boolean isConditional()
   {
      return (!m_conditions._isempty());
   }

   /**
    * Determines whether this choice is the default choice for this Select.  If 
    * this choice is the default, it will be selected when the value does not 
    * match any other choice. 
    * 
    * @return     whether this choice is default
    */
   public boolean isDefault()
   {
      return m_default;
   }
};
