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

/**
 * The "sc.editor" namespace contains interfaces and 
 * classes that apply to the Slick-C editor control. 
 */
namespace sc.editor;

/**
 * Encapsulate set of last search parameters. Last search
 * parameters are used by repeat_search, _select_match, and 
 * match_length built-ins in an editor control. 
 *
 * <p>
 *
 * Used by SaveSearch class to create a "search context" 
 * that makes saving and restoring search parameters 
 * easier. 
 *
 * @example
 * <pre>
 * ...
 * search('foo');
 * SearchParameters foo_search; 
 * search('bar');
 * foo_search.restore();
 * // repeat-search will search again for 'foo' NOT 'bar'
 * ...
 * </pre>
 *
 * @see SaveSearch
 */
class SearchParameters {

   // Prototypes
   public void reset();
   public void save();
   public void restore();

   // Search parameters used by repeat_search, _select_match, and
   // match_length built-ins.
   private _str m_search_string = "";
   private _str m_word_re = "";
   private int m_flags = 0;
   private _str m_reserved = "";
   private int m_flags2 = 0;

   /**
    * Constructor. 
    *
    * @param saveCurrent  Set to false if you do not want current search
    *                     parameters initially saved. Defaults to true.
    */
   SearchParameters(boolean saveCurrent=true) {
      if( saveCurrent ) {
         // Start with current search parameters
         this.save();
      } else {
         // Start with search parameters that are guaranteed to fail until
         // save is called.
         this.reset();
      }
   }

   ~SearchParameters() {
   }

   /**
    * Reset search parameters. Calling restore after a reset will cause
    * repeat_search to fail.
    */
   public void reset() {
      m_search_string = "";
      m_word_re = "";
      m_flags = 0;
      m_reserved = null;
      m_flags2 = 0;
   }

   /**
    * Save current search parameters.
    */
   public void save() {
      save_search(m_search_string,m_flags,m_word_re,m_reserved,m_flags2);
   }

   /**
    * Restore saved current search parameters.
    */
   public void restore() {
      restore_search(m_search_string,m_flags,m_word_re,m_reserved,m_flags2);
   }

};
