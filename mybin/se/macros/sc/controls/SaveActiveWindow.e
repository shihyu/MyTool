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
#require "sc/lang/IControlID.e"
#endregion

/**
 * The "sc.controls" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language's
 * form editor system and editor control.  It also contains
 * class wrappers for composite controls.
 */
namespace sc.controls;
using sc.lang.IControlID;

/**
 * Class used to simplify saving and restoring the active 
 * window. Used to perform window operations within context 
 * of a specific window. Original window is restored upon 
 * destruction (e.g. falling out of scope). 
 */
class SaveActiveWindow {

   // Prototypes
   public void restore();

   // Used to restore original active window on destruction
   private int m_orig_wid = 0;

   /**
    * Constructor.
    * 
    * @param wid  Window ID to make active. This can also be 
    *             an instance of a class derived from
    *             IControlID. Set to 0 to leave active window
    *             alone. Call-by-reference to avoid any
    *             auto-destruct behavior. Defaults to 0.
    */
   SaveActiveWindow(typeless& wid=0) {
      m_orig_wid = p_window_id;
      int awid = 0;
      if( wid instanceof IControlID ) {
         awid = ((IControlID)wid).getWindowID();
      } else if( isinteger(wid) ) {
         awid = (int)wid;
      }
      if( _iswindow_valid(awid) ) {
         activate_window(awid);
      }
   }

   ~SaveActiveWindow() {
      this.restore();
   }

   /**
    * Restore original active window. You only need to use this 
    * method if you want to restore the active window without 
    * waiting for for this instance to die. 
    */
   public void restore() {
      if( _iswindow_valid(m_orig_wid) ) {
         activate_window(m_orig_wid);
      }
   }

};
