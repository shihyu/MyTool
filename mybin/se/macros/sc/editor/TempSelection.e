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
#endregion

/**
 * The "sc.editor" namespace contains interfaces and 
 * classes that apply to the Slick-C editor control. 
 */
namespace sc.editor;

/**
 * This class is used to simplify using a temporary selection. When the 
 * TempSelection is constructed the current active selection is saved and a 
 * temporary selection is made active. Upon destruction the original active
 * selection is restored.
 *
 * <p>
 *
 * There are 2 ways to use TempSelection:<br>
 *
 * <li>Managed. Temporary selection creation and lifetime managed 
 * automatically. This is the default. When the TempSelection object is 
 * constructed, the temporary selection is allocated and made active. Upon 
 * destruction (e.g. falling out of scope) the temporary selection is 
 * automatically freed. 
 *
 * <li>Unmanaged. Use this method when the temporary selection must persist 
 * beyond the lifetime of the TempSelection. When the TempSelection object 
 * is constructed, the temporary selection passed in is made active. Upon 
 * destruction (e.g. falling out of scope) the temporary selection is NOT 
 * freed. 
 *
 * <p>
 *
 * Note:<br>
 * The active window does not have to be an editor control to save 
 * and restore the active selection, but the active window must be an
 * editor control to operate on selected text (e.g. {@link 
 * _select_line}, {@link _select_char}, {@link _select_block}, etc.).
 * 
 * @example
 * <pre>
 * void magicWordSelection() 
 * { 
 *    // Temporarily select the current word
 *    TempSelection sentry();
 *    select_whole_word();
 *    refresh();
 *    // Count to 3
 *    delay(300);
 *    
 *    // TempSelection sentry falls out of scope and automatically
 *    // restores original active selection. Temporary selection
 *    // is automatically destroyed.
 * } 
 * </pre>
 */
class TempSelection {

   // Used to restore the original selection on destruct
   private int m_orig_markid;
   // Temporary selection
   private int m_markid;

   /**
    * Constructor.
    *
    * @param markid  Selection to temporarily make
    *                active. Set to -1 to have this class
    *                manage the creation and lifetime of
    *                the temporary selection. See class
    *                description for more details on
    *                managed versus unmanaged temporary
    *                selections. Defaults to -1.
    */
   TempSelection(int markid=-1) {
      m_orig_markid = _duplicate_selection('');
      m_markid = -1;
      if( markid < 0 ) {
         // This instance will manage the lifetime of the temporary
         // selection.
         markid = _alloc_selection();
         m_markid = markid;
      }
      //say('TempSelection: markid='markid);
      _show_selection(markid);
   }

   /**
    * Destructor. Restore original active selection.
    */
   ~TempSelection() {
      _show_selection((_str)m_orig_markid);
      if( m_markid >= 0 ) {
         _free_selection(m_markid);
      }
   }
};
