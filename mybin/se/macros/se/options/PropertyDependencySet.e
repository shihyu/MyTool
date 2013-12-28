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
#require "Condition.e"
#require "IPropertyDependency.e"
#endregion Imports

namespace se.options;

/**
 * This class keeps up with the dependencies that a property has
 * on values throughout the application.  If these dependencies
 * return false, then this property is disabled. 
 *  
 * A PropertyDependencySet can contain invidual conditions or 
 * additional dependency sets. 
 * 
 */
class PropertyDependencySet : IPropertyDependency 
{
   // if true, then all dependencies must be true for the set to 
   // be true, otherwise any one of them can be true for the set 
   // to return true
   boolean m_all;
   // the set of our dependencies
   IPropertyDependency m_dependencies[];

   /**
    * Constructor.  
    * 
    */
   PropertyDependencySet(boolean all = true)
   {
      m_all = all;
      m_dependencies._makeempty();
   }

   /**
    * Evaluates the dependency set to true or false.
    * 
    * @param options       current caption, value set of other
    *                      options that this dependency set may reference
    * 
    * @return 
    */
   public boolean evaluate(_str options:[])
   {
      boolean enabled = m_all;
      IPropertyDependency * ipd;
      int i;

      for (i = 0; i < m_dependencies._length(); i++) {
         ipd = &(m_dependencies[i]);

         // evaluate this thing, be it condition or another set
         depEnabled := ipd -> evaluate(options);

         // because of the ALL versus ANY, we may know the value before we completely finish going through the list
         // HOWEVER, we don't want to return yet, because we want to make sure we save the current value
         if (m_all) {
            // AND in the value and continue
            enabled = (enabled && depEnabled);
         } else {
            // OR in the value and continue
            enabled = (enabled || depEnabled);
         }
      }

      return enabled;
   }

   /**
    * Re-evaluate this set based on the change of an option.
    * 
    * @param caption       caption of changed option
    * @param value         new option value
    * 
    * @return 
    */
   public boolean reevaluate(_str caption, _str value)
   {
      _str options:[];
      options:[caption] = value;
      return evaluate(options);
   }

   /**
    * Get all the conditions within this dependency set that look
    * up another option in the tree.
    * 
    * @param ot     hashtable of caption, value pairs
    */
   public void getOptionTypes(_str (&ot):[])
   {
      IPropertyDependency ipd;
      foreach (ipd in m_dependencies) {
         switch (ipd._typename()) {
         case "se.options.PropertyDependencySet":
            ((PropertyDependencySet)ipd).getOptionTypes(ot);
            break;
         case "se.options.Condition":
            Condition c = (Condition)ipd;
            if (c.getType() == DT_OPTION) {
               ot:[c.getInfo()] = c.getValue();
            }
         }
      }
   }

   /**
    * Adds a dependency to this set.
    * 
    * @param ipd    new dependency to be added
    */
   public void addDependency(IPropertyDependency ipd)
   {
      m_dependencies[m_dependencies._length()] = ipd;
   }

   public void setLanguage(_str langID)
   {
      IPropertyDependency * ipd;
      for (i := 0; i < m_dependencies._length(); i++) {
         ipd = &(m_dependencies[i]);
         ipd -> setLanguage(langID);
      }
   }

};

