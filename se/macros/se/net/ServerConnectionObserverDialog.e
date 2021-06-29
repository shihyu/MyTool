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
#include "slick.sh"
#region Imports
#require "se/net/ServerConnectionObserver.e"
#import "stdprocs.e"
#endregion

namespace se.net;

/**
 * Convenience class.
 *
 * Generic observer class that observes an instance of 
 * ServerConnection and updates the user of the status of the 
 * pending connection via a stay-on-top dialog that is 
 * Cancel-able. 
 */
class ServerConnectionObserverDialog : ServerConnectionObserver {

   private int m_formwid;

   /**
    * Constructor.
    */
   ServerConnectionObserverDialog() {
      m_formwid = 0;
   }

   /**
    * Destructor.
    */
   ~ServerConnectionObserverDialog() {
   }

   /**
    * Create the dialog. Dialog is initially hidden. 
    * 
    * @return 0 on success, <0 on error. 
    */
   private int create() {

      status := 0;

      if( m_formwid > 0 ) {
         // Dialog already created
         return 0;
      }

      do {

         // Form
         m_formwid = _create_window(OI_FORM,_mdi,"Waiting for connection...",-1,-1,6000,2000,CW_PARENT|CW_HIDDEN,BDS_DIALOG_BOX);
         if( m_formwid < 0 ) {
            // Error
            status = m_formwid;
            break;
         }
         m_formwid.p_name = "_ServerConnectionObserverDialog_form";

         // Ensure that system Close also cancels form
         m_formwid.p_eventtab = defeventtab _ServerConnectionObserverDialog_etab;

         // Message line top-left
         x := 180;
         y := 180;
         int width = m_formwid.p_client_width*_twips_per_pixel_x() - 2*180;
         height := 195;
         int message_wid = _create_window(OI_LABEL,m_formwid,"",x,y,width,height,CW_CHILD);
         if( message_wid < 0 ) {
            // Error
            m_formwid._delete_window(0);
            m_formwid = 0;
            status = message_wid;
            break;
         }
         message_wid.p_name = "ctl_message";

         // Center a Cancel button in the form, below message line
         x = (m_formwid.p_client_width*_twips_per_pixel_x() - 1125) intdiv 2;
         y = (m_formwid.p_client_height*_twips_per_pixel_y() - 345 - message_wid.p_height - 180) intdiv 2;
         width = 1125;
         height = 345;
         int button_wid = _create_window(OI_COMMAND_BUTTON,m_formwid,"Cancel",x,y,width,height,CW_CHILD);
         if( button_wid < 0 ) {
            // Error
            m_formwid._delete_window(0);
            m_formwid = 0;
            status = button_wid;
            break;
         }
         button_wid.p_command = "ServerConnectionObserverDialog_cancel";

      } while( false );

      return status;
   }

   /**
    * Destroy this dialog.
    */
   private void destroy() {
      if( m_formwid > 0 ) {

         int form_wid = m_formwid;
         m_formwid = 0;
         if( _iswindow_valid(form_wid) &&
             form_wid.p_name == "_ServerConnectionObserverDialog_form" ) {

            // Dismiss this dialog
            // This must be the last thing we do, since we are 
            // commiting suicide. 
            form_wid._delete_window(0);
         }
      }
   }

   /**
    * Show the dialog. 
    *
    * @return 0 on success, <0 on error.
    */
   private int show() {

      int status = create();
      if( status != 0 ) {
         return status;
      }

      // Attach &this to the dialog so user Cancel and Close works
      m_formwid._SetDialogInfoHt("this_p",&this);

      // Center the dialog inside MDI frame
      m_formwid._center_window(_mdi);

      // Make dialog visible
      m_formwid.p_visible = true;

      // Success
      return 0;
   }

   private void hide() {
      if( m_formwid > 0 ) {
         m_formwid.p_visible = false;
      }
   }

   /**
    * Return true if this dialog is visible.
    * 
    * @return True if dialog is visible. 
    */
   private bool isVisible() {
      if( m_formwid > 0 ) {
         return m_formwid.p_visible;
      }
      return false;
   }

   protected void printMessage(_str msg) {
      if( isStarted() ) {
         msg_wid := m_formwid._find_control("ctl_message");
         if( msg_wid > 0 ) {
            msg_wid.p_caption = msg;
         }
      }
   }

   protected void printCriticalMessage(_str msg) {
      printMessage(msg);
   }

   public void onCancel() {
      // Inform any observer that the user cancelled
      notifyOnCancel();
      // Dismiss this dialog
      destroy();
   }

   public int start() {
      int status = show();
      return status;
   }

   public void stop() {
      destroy();
   }

   public bool isStarted() {
      return ( m_formwid > 0 && m_formwid.p_visible );
   }

};


namespace default;

//
// _ServerConnectionObserverDialog_etab
//

defeventtab _ServerConnectionObserverDialog_etab;
_command void ServerConnectionObserverDialog_cancel()
{
   int form_wid = _find_formobj("_ServerConnectionObserverDialog_form",'n');
   if( form_wid > 0 ) {
      se.net.ServerConnectionObserverDialog* scod = form_wid._GetDialogInfoHt("this_p");
      scod->onCancel();
   }
}
void _ServerConnectionObserverDialog_etab.on_close()
{
   ServerConnectionObserverDialog_cancel();
}
