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
#include 'slick.sh'
#endregion

/**
 * The "sc.lang" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language.
 */
namespace sc.lang;

/**
 * This class is used to encapsulate a timer.  Inherit from this 
 * class and override the <B>run</B> method to perform your 
 * timer task.  Timer is automatically stopped when item is 
 * destructed. 
 *  
 * Inherits from Timer 
 */
class Timer {
   // Use -1 instead of -2.  There the keystate timer uses -1
   private int m_timerHandle   = -2;
   private int m_timerInterval = 1000;
   private int m_numCallbacks  = -1;

   // When the state file is saved, we cannot let it be written with m_timerHandle
   // >= -1, because it a global instance variable could be written that way, and 
   // then the timer killed when it was never started.  This variable will 
   // temporarily hold the value of the actual timer handle.
   private int m_hiddenTimerHandleValue = -2;

   /** 
    * @param interval Amount of time in milliseconds between timer 
    *                 callbacks
    *  @param numCallbacks Number of times to run callback. <=0
    *                      will run until <B>kill</B> is called or
    *                      the object is destructed
    */
   Timer(int interval = 1000,int numCallbacks=-1) {
      m_timerInterval = interval;
      m_numCallbacks  = numCallbacks;
   }

   /**
    * If an instantiation is a global variable, the
    * _before_write_state_ callback should be caught and call this
    * function to be sure that the timer handle is not saved. 
    *  
    * recoverFromWriteState should be called after the state file 
    * is written. 
    *  
    * @see recoverFromWriteState 
    */
   void prepareForWriteState() {
      m_hiddenTimerHandleValue = m_timerHandle;
      m_timerHandle = -2;
   }

   /**
    * If an instantiation is a global variable, the
    * _after_write_state_ callback should be caught and call this
    * function to restore the timer handle. 
    *  
    * prepareForWriteState should be called before the state file 
    * is written. 
    *  
    * @see prepareForWriteState 
    */
   void recoverFromWriteState() {
      m_timerHandle = m_hiddenTimerHandleValue;
   }

   /** 
    * Stop the timer if it is running.  Re-initialize 
    * m_timerHandle to -1 
    *  
    * @return 0 if successful (return value from _kill_timer)
    */
   int kill() {
      status := 0;
      if ( m_timerHandle==null ) m_timerHandle=-2;
      if ( m_timerHandle>-1 ) {
         if ( _timer_is_valid(m_timerHandle) ) {
            status =_kill_timer(m_timerHandle);
         }
      }
      m_timerHandle = -2;
      return status;
   }

   boolean isRunning() {
      return m_timerHandle>-1;
   }

   ~Timer() {
      kill();
   }

   /** 
    * Here to be overridden.  Must return 0 for timer to continue. 
    * Timer will be killed if run() returns non-zero. 
    */
   int run() {
      return 0;
   }

   /**
    * @return value from <B>run</B>, -1 if <B>pThis</B> is null
    */
   static int timerProc(Timer* pThis) {
      status := 0;
      if ( pThis != null ) {
         status= pThis->run();
      }
      if ( pThis->m_numCallbacks==1 ) pThis->kill();
      if ( status ) pThis->kill();
      if ( pThis->m_numCallbacks>1 ) --pThis->m_numCallbacks;
      return status;
   }

   /** 
    * @return <0 if error (return value from _set_timer)
    */
   int start() {
      m_timerHandle = _set_timer(m_timerInterval,timerProc,&this);
      return (int)(m_timerHandle>=0);
   }
};
