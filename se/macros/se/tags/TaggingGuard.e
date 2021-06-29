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
#include "tagsdb.sh"

namespace se.tags;

/**
 * This class is used to create a guard which is automatically released 
 * when the editor exits a function and which locks the set of tags in 
 * the current context from being modified by a background thread. 
 */
class TaggingGuard {
   private int m_lockContext = 0;
   private int m_lockMatches = 0;
   private _str m_lockedDatabases[];

   /**
    * Constructor locks the context to prevent other threads from modifying 
    * the contents of the context. 
    * 
    * @param doWrite 
    */
   TaggingGuard() {
   }

   /**
    * Lock the current context and locals for synchronized access. 
    * Note that the context is automatically locked for read access 
    * when this class is instantiated. 
    */
   void lockContext(bool doWrite=false) {
      tag_lock_context(doWrite);
      m_lockContext++;
   }

   /**
    * Lock the set of matches for writing
    * 
    * @param doWrite 
    */
   void lockMatches(bool doWrite=false) {
      tag_lock_matches(doWrite);
      m_lockMatches++;
   }

   /**
    * Lock the given database for reading or writing.
    */
   int lockDatabase(_str tagDatabase, int ms=0) {
      status := tag_lock_db(tagDatabase,ms);
      if (status < 0) return status;
      m_lockedDatabases[m_lockedDatabases._length()] = tagDatabase;
      return 0;
   }

   /**
    * Destructor unlocks the context to allow other threads to proceed.
    */
   ~TaggingGuard() {
      i := 0;
      for (i=0; i<m_lockContext; i++) {
         tag_unlock_context();
      }
      for (i=0; i<m_lockMatches; i++) {
         tag_unlock_matches();
      }
      tagDatabase := "";
      foreach (tagDatabase in m_lockedDatabases) {
         tag_unlock_db(tagDatabase);
      }
      m_lockedDatabases = null;
   }

};

