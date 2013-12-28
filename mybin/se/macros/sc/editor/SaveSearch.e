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
#require "sc/editor/SearchParameters.e"
#endregion

/**
 * The "sc.editor" namespace contains interfaces and 
 * classes that apply to the Slick-C editor control. 
 */
namespace sc.editor;

/**
 * This class is used to simplify saving and restoring 
 * current search parameters used by the repeat_search, 
 * _select_match, and match_length built-ins, in an editor
 * control. Use this class as a sentry to perform search 
 * operations within the context of a specific set of saved 
 * search parameters. Original search parameters are restored 
 * upon destruction (e.g. falling out of scope). 
 *
 * @example
 * <pre>
 * ...
 * search('foo');
 * {
 *    SaveSearch sentry;
 *    search('bar');
 * }
 * // repeat-search will search again for 'foo' NOT 'bar'
 * // because SaveSearch sentry fell out of scope and restored 
 * // previous search parameters.
 * repeat_search();
 * ...
 * </pre>
 *
 * @see SearchParameters
 */
class SaveSearch {

   // Original search parameters to restore when destructed
   private SearchParameters m_orig_search;

   /**
    * Constructor. Initialize search environment.
    * 
    * @param init_data  If not null then these search parameters are restored 
    *                   and ready-to-use by one of the search builtins
    *                   (repeat_search, etc.). Defaults to null.
    */
   SaveSearch(SearchParameters& init_search=null) {
      // Note: m_orig_search ctor took care of saving orig search parameters
      if( init_search != null ) {
         init_search.restore();
      }
   }

   /**
    * Destructor. Restores original search parameters.
    */
   ~SaveSearch() {
      m_orig_search.restore();
   }
};
