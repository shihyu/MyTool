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
#require "se/net/IServerConnection.e"
#require "se/net/ServerConnectionObserver.e"
#import "main.e"
#import "stdprocs.e"
#endregion

namespace se.net;

/**
 * A server connection observer that takes an existing instance
 * of a form and updates the form with connection status. 
 *
 * <p>
 *
 * Status provided to the form through its '!' form event 
 * handler: 
 * <pre> defeventtab _name_of_form; ... void 
 * _name_of_form.'!'(IServerConnection* server=null, SERVER_CONNECTION_STATUS status=SCS_NONE) 
 * {
 *     // Your code here
 * }
 * </pre>
 *
 * <p>
 *
 * The form can provide cancel-ability by checking for an
 * embedded instance of the observer instance:
 * <pre>
 * ...
 * void ctl_cancel.lbutton_up()
 * {
 *    ServerConnectionObserverFormInstance* pobserver = _GetDialogInfoHt("ServerConnectionObserverFormInstance");
 *    if( pobserver ) {
 *       pobserver->onCancel();
 *    }
 *    p_active_form._delete_window("");
 * }
 * </pre>
 */
class ServerConnectionObserverFormInstance : ServerConnectionObserver {

   private int m_formwid;

   /**
    * Constructor.
    *
    * @param formwid  Instance of form to keep updated with 
    *                 connection status.
    */
   ServerConnectionObserverFormInstance(int formwid=0) {

      if( formwid > 0 && _iswindow_valid(formwid) && formwid.p_object == OI_FORM ) {
         int index = eventtab_index(formwid.p_eventtab,formwid.p_eventtab,event2index('!'));
         if( index > 0 ) {
            // All good
            m_formwid = formwid;
            _SetDialogInfoHt("ServerConnectionObserverFormInstance",&this,m_formwid);
         } else {
            _assert(false,nls("No '!' event handler for form '%s'",formwid.p_name));
            m_formwid = 0;
         }
      } else {
         // Invalid formwid
         _assert(false,"Invalid form instance.");
         m_formwid = 0;
      }
   }

   /**
    * Destructor.
    */
   ~ServerConnectionObserverFormInstance() {
      if( m_formwid > 0 && _iswindow_valid(m_formwid) ) {
         _SetDialogInfoHt("ServerConnectionObserverFormInstance",null,m_formwid);
      }
      m_formwid = 0;
   }

   public int start() {
      return 0;
   }

   public void stop() {
      return;
   }

   public bool isStarted() {
      return ( m_formwid > 0 );
   }

   private void onStatusListen(IServerConnection* server) {
      // Server watch timer might have gotten off a shot right after the form
      // was cancelled, so must check for valid form.
      if( m_formwid > 0 && _iswindow_valid(m_formwid) ) {
         m_formwid.call_event(server,SCS_LISTEN,m_formwid,'!','w');
      }
   }

   private void onStatusPending(IServerConnection* server) {
      // Server watch timer might have gotten off a shot right after the form
      // was cancelled, so must check for valid form.
      if( m_formwid > 0 && _iswindow_valid(m_formwid) ) {
         m_formwid.call_event(server,SCS_PENDING,m_formwid,'!','w');
      }
   }

   private void onStatusError(IServerConnection* server) {
      // Server watch timer might have gotten off a shot right after the form
      // was cancelled, so must check for valid form.
      if( m_formwid > 0 && _iswindow_valid(m_formwid) ) {
         m_formwid.call_event(server,SCS_ERROR,m_formwid,'!','w');
      }
   }

   public void onCancel() {
      // Inform any observer that the user cancelled
      notifyOnCancel();
   }

};
