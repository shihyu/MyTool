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

/**
 * The "sc.lang" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language.
 */
namespace sc.lang;

/**
 * Guard a value reference. Current value is saved, and restored 
 * when the guard falls out of scope. 
 */
class ScopedValueGuard {
   private typeless* m_val_ref;
   private typeless m_val;

   ScopedValueGuard(typeless& val_ref=null) {
      m_val_ref = &val_ref;
      m_val = val_ref;
   }
   ~ScopedValueGuard() { *m_val_ref = m_val; }
};
