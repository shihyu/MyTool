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
 * Keeps track of dependencies within the options tree.
 * Dependencies are defined as one property only being enabled
 * when another property has a specific value.
 * 
 */
class DependencyTree {
   private int m_dependencies:[][];

   DependencyTree()
   {
      m_dependencies._makeempty();
   }

   /** 
    * Clears all dependencies from the tree.
    * 
    */
   void clearTree()
   {
      m_dependencies._makeempty();
   }

   /**
    * Adds a dependency to the tree.
    * 
    * @param caption Caption of property being depended on
    * @param value   Value that property being depended on
    *                needs to be for dependent to be enabled
    * @param pa      Property Address of dependent property
    */
   void addDependency(_str caption, _str value, int index)
   {
      // if this property is already depended on, we just add this to the list
      if (!m_dependencies._indexin(caption)) {
         int array[];
         array[0] = index;
         m_dependencies:[caption] = array;
      } else {             
         // otherwise create a new entry
         len := (m_dependencies:[caption])._length();
         m_dependencies:[caption][len] = index;
      }
   }

   /** 
    * Returns whether the property with this caption has any other 
    * properties depending on it. 
    * 
    * @param caption       Property to test
    * 
    * @return bool         True if property has other properties 
    *                      depending on it, false otherwise.
    */
   bool isDependedOn(_str caption)
   {
      return (m_dependencies._indexin(caption));
   }

   /** 
    * Returns the dependencies associated with the property that 
    * has the given caption. 
    * 
    * @param caption       Caption of property that is depended on
    * @param dl            list of dependencies
    */
   void getDependencies(_str caption, int (&dl)[])
   {
      dl = m_dependencies:[caption];
   }
};
