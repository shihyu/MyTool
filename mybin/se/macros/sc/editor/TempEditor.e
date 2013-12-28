////////////////////////////////////////////////////////////////////////////////////
// $Revision: 39117 $
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
#require "sc/lang/IControlID.e"
#import "stdprocs.e"

/**
 * The "sc.editor" namespace contains interfaces and 
 * classes that apply to the Slick-C editor control. 
 */
namespace sc.editor;

/**
 * This class is used to create a temporary editor which
 * is cleaned up automatically when the object is destructed.
 */
class TempEditor : sc.lang.IControlID {

   //
   // Public interface
   //

   public int open(_str file_name="", _str load_options="",
                   boolean doSelectEditMode=false, int more_buf_flags=0);
   public void close();
   int getStatus();

   //
   // Private data
   //

   private int m_editor_wid = 0;
   private int m_status = 0;

   /**
    * Constructor, creates temporary editor control.
    *
    * <p>
    *
    * You can defer creation by passing <code>null</code> for the 
    * filename. You can then call {@link open} to create the 
    * temporary editor. 
    * 
    * @param file_name     Name of file to open or create. Set to 
    *                      "" to create a new, empty editor. Set to
    *                      null to defer creation until later.
    * @param load_options  May be "" or only may contain the 
    *                      following:
    *                      <ul>
    *                      <li> +bi &lt;buf_id&gt;
    *                      <li> +d
    *                      <li> +b
    *                      </ul>
    * @param doSelectEditMode  
    *        When true, _SetEditorLanguage() is called to initialize
    *        the extension setup for the buffer. In addition,
    *        build_load_options() to generate all default load options
    *        which typically turns on undo.
    * @param more_buf_flags  Allows more buffer flags (typically 
    *                        VSBUFFLAG_THROW_AWAY_CHANGES) to be
    *                        added to buffers loaded from disk.
    * 
    * @see _create_temp_view() 
    * @see _open_temp_view() 
    */
   TempEditor(_str file_name="", _str load_options="",
              boolean doSelectEditMode=false, int more_buf_flags=0) {

      m_editor_wid = 0;
      m_status = 0;

      if( file_name != null ) {
         this.open(file_name,load_options,doSelectEditMode,more_buf_flags);
      }
   }

   /**
    * Destructor. Release resources. 
    *
    * @see _delete_temp_view();
    */
   ~TempEditor() {
      this.close();
   }


   /**
    * Create the temporary editor control.
    *
    * <p>
    *
    * Note: Calling this method <b>replaces</b> the existing editor
    * control (if any). 
    * 
    * @param file_name     Name of file to open or create. Set to 
    *                      "" to create a new, empty editor. Set to
    *                      null to defer creation until later.
    * @param load_options  May be "" or only may contain the 
    *                      following:
    *                      <ul>
    *                      <li> +bi &lt;buf_id&gt;
    *                      <li> +d
    *                      <li> +b
    *                      </ul>
    * @param doSelectEditMode  
    *        When true, _SetEditorLanguage() is called to initialize
    *        the extension setup for the buffer. In addition,
    *        build_load_options() to generate all default load options
    *        which typically turns on undo.
    * @param more_buf_flags  Allows more buffer flags (typically 
    *                        VSBUFFLAG_THROW_AWAY_CHANGES) to be
    *                        added to buffers loaded from disk.
    *
    * @param file_name 
    * @param load_options 
    * @param doSelectEditMode 
    * @param more_buf_flags 
    * 
    * @return int 
    */
   public int open(_str file_name="", _str load_options="",
                   boolean doSelectEditMode=false, int more_buf_flags=0) {

      int orig_wid = p_window_id;
      if( _iswindow_valid(m_editor_wid) ) {
         _delete_temp_view(m_editor_wid);
      }
      m_editor_wid = 0;
      if( file_name == "" ) {
         m_status = _create_temp_view(m_editor_wid, 
                                      load_options, 
                                      file_name, 
                                      doSelectEditMode, 
                                      more_buf_flags);
         // _create_temp_view returns the orig window id on success
         if( m_status > 0 ) {
            m_status = 0;
         }
      } else {
         m_status = _open_temp_view(file_name,
                                    m_editor_wid,
                                    orig_wid,
                                    load_options,
                                    auto buffer_already_exists,
                                    false,
                                    doSelectEditMode,
                                    more_buf_flags);
      }
      activate_window(orig_wid);
      return m_status;
   }

   /**
    * Close the temporary editor control.
    */
   public void close() {

      int orig_wid = p_window_id;
      int editor_wid = m_editor_wid;
      m_editor_wid = 0;
      if( 0 == m_status && _iswindow_valid(editor_wid) ) {
         _delete_temp_view(editor_wid);
      }
      m_status = 0;
      if( orig_wid != editor_wid && _iswindow_valid(orig_wid) ) {
         activate_window(orig_wid);
      }
   }

   /**
    * @return Status of the creating/opening the temporary editor.
    */
   int getStatus() {
      return m_status;
   }

   /**
    * @return Return the window ID of the temporary editor.
    */
   int getWindowID() {
      return m_editor_wid;
   }

}
