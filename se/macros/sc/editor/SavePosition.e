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

/**
 * The "sc.editor" namespace contains interfaces and 
 * classes that apply to the Slick-C editor control. 
 */
namespace sc.editor;

/**
 * This class is used to simplify saving and restoring the 
 * cursor position in an editor control.  The cursor 
 * position is saved at the time the class is constructed 
 * and restored when this object is destructed. The 
 * current object is expected to be an editor control. 
 *
 * <p>
 *
 * Do not use this class if you plan to modify the 
 * contents of the editor window before calling restore. 
 * 
 * @example
 * <pre>
 * int findMagicString(_str magic)
 * {
 *    SavePosition sentry;
 *    top();
 *    loop {
 *       get_line(line);
 *       if (line == magic) { 
 *          return p_line;
 *       }
 *       if (down()) break;
 *    }
 *    return STRING_NOT_FOUND_RC;
 *
 *    // SavePosition sentry falls out of scope and restores previous
 *    // position in editor window.
 *  
 * }
 * </pre>
 */
class SavePosition {

   // Prototypes
   public void save(int wid=0, typeless p=null);
   public void restore();

   // For saving window ID and position
   private int m_wid = 0;
   private typeless m_p = null;

   /**
    * Constructor, saves cursor position.
    *
    * @param wid  Editor window ID to save position for.
    *             Specify 0 for the active window.
    *             Defaults to 0.
    * @param p    Position to save. Use save_pos to 
    *             create a position. Specify null to
    *             save current position in editor
    *             window. Defaults to null.
    */
   SavePosition(int wid=0, typeless p=null) {
      this.save(wid,p);
   }

   /**
    * Destructor, restores cursor position.
    */
   ~SavePosition() {
      this.restore();
   }

   /**
    * Reset the saved cursor position. 
    *
    * @param wid  Editor window ID to save position for.
    *             Specify 0 for the active window.
    *             Defaults to 0.
    * @param p    Position to save. Specify null to save
    *             current position in editor window.
    *             Defaults to null.
    */
   public void save(int wid=0, typeless p=null) {
      m_wid = wid;
      if( m_wid == 0 ) {
         m_wid = p_window_id;
      }
      m_p = p;
      if( m_p == null ) {
         m_wid.save_pos(m_p);
      }
   }

   /**
    * Restore the saved cursor position.
    */
   public void restore() {
      if( _iswindow_valid(m_wid) ) {
         m_wid.restore_pos(m_p);
      }
   }
}

