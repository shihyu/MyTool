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
 * Information about a separator in a menu or toolbar
 */
class Separator {
   _str m_prev = '';            // identifier of item before this separator
   _str m_next = '';            // identifier of item after this separator  

   Separator() { }

   void setPrevItem(_str prev)
   {
      m_prev = prev;
   }

   _str getPrevItem()
   {
      return m_prev;
   }

   void setNextItem(_str next)
   {
      m_next = next;
   }

   _str getNextItem()
   {
      return m_next;
   }
};

