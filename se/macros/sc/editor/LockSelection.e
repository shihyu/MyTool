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
 * This class is used to simplify locking a selection 
 * temporarily. When LockSelection is constructed the current
 * active selection is locked (text position changes will not 
 * extend the selection). Upon destruction the active selection 
 * is unlocked. 
 *
 * <p>
 *
 * Note:<br>
 * The active window does not have to be an editor control to 
 * lock and unlock the active selection, but the active window 
 * must be an editor control to operate on selected text (e.g. 
 * {@link _select_line}, {@link _select_char}, {@link 
 * _select_block}, etc.). 
 */
class LockSelection {

   private int m_markid;

   /**
    * Constructor.
    *
    * @param markid  Selection to temporarily lock. Set to -1 to 
    *                manage the active selection. Defaults to -1.
    */
   LockSelection(int markid=-1) {
      m_markid = -1;
      if( markid < 0 ) {
         // Manage the active selection
         markid = _duplicate_selection('');
      }
      _str style = _select_type(markid,'S');
      if( style == 'C' ) {
         // Lock it
         m_markid = markid;
         //say('LockSelection : locking m_markid='m_markid);
         _select_type(m_markid,'S','E');
      }
   }

   /**
    * Destructor. Unlock selection.
    */
   ~LockSelection() {
      if( m_markid >= 0 && _select_type(m_markid) != '' ) {
         // Unlock it
         //say('  LockSelection : un-locking m_markid='m_markid);
         _select_type(m_markid,'S','C');
      }
   }
};
