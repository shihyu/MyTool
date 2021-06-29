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
#pragma option(pedantic, on)
#region Imports
#include "slick.sh"
#require "se/util/IPathMapper.e"
#require "sc/lang/IComparable.e"
#import "stdprocs.e"
#endregion

namespace se.util;

using sc.collections.Map;
using sc.collections.IMapIterator;

class PathMapperIterator : IPathMapperIterator {

   // Instance of PathMapper class that this
   // iterator belongs to.
   private IPathMapper* m_path_mapper;

   // Current mapped key
   private _str m_key = null;
   // Current mapped path
   private _str m_path = null;
   // Path to match for mapFirst/mapNext
   private _str m_path_to_match = null;
   // Searching default keys?
   private bool m_use_default_keys = false;

   public typeless key() {
      return m_path_mapper->getByPath(m_path,m_use_default_keys);
   }

};

static const PMI_FIELD_PATH_MAPPER = 0;
static const PMI_FIELD_KEY = 1;
static const PMI_FIELD_PATH = 2;
static const PMI_FIELD_PATH_TO_MATCH = 3;
static const PMI_FIELD_USE_DEFAULT_KEYS = 4;

/**
 * Map file and directory patterns to keys. Given a path, you
 * can lookup the key that pattern-matches the path. Simple
 * wildcard characters may be used for the pattern (*, ?). 
 * Key lookups are based on the strongest pattern-match for a 
 * given path. Keys can be simple types (e.g. _str, int) or 
 * objects. If using an object for a key then it must implement 
 * the IComparable interface. 
 *
 * @example Map file patterns to pretty language captions
 * <pre> 
 * PathMapper pm;
 * pm.addDefault("Other","*.*");
 * pm.add("C/C++","*.cpp");
 * pm.add("Java","*.java");
 * pm.add("HTML","*.htm*");
 * pm.add("Specific File","/path/to/specific/file.ext");
 * <br>
 * // Returns "Specific File"
 * caption = pm.map('/path/to/specific/file.ext');
 * _assert(caption == "Specific File");
 * // Returns "C/C++"
 * _str caption = pm.map('c:\project\myfile.cpp');
 * // Returns "Java"
 * _str caption = pm.map("/project/src/Foo.java");
 * // Returns "HTML"
 * _str caption = pm.map("/var/www/html/index.html");
 * // Returns "Other"
 * _str caption = pm.map("/app/docs/readme.txt");
 * </pre> 
 *
 * @example Map project-template patterns to categories
 * <pre> 
 * PathMapper pm;
 * pm.addDefault("Other Project","/templates/project/\*");
 * pm.add("C++ Project","/templates/project/C++/\*");
 * pm.add("GNU C++ Project","/templates/project/C++/GNU C++/\*");
 * pm.add("Java Project","/templates/project/Java/\*");
 * pm.add("Java Swing Project","/templates/project/Java/\*Swing*");
 * pm.add("Java Swing Project","/templates/project/Java/\*JFC*"); 
 * <br>
 * // Returns "GNU C++ Project"
 * _str category = pm.map('/templates/project/C++/GNU C++/A "Hello World" application');
 * // Returns "C++ Project"
 * _str category = pm.map("/templates/project/C++/Console application");
 * // Returns:
 * //   - C++ Project
 * //   - GNU C++ Project
 * _str category[] = pm.mapAll('/templates/project/C++/GNU C++/A "Hello World" application'); 
 * // Returns "Java Swing Project"
 * _str category = pm.map('/templates/project/Java/A JFC application');
 * // Returns:
 * //   - Java Project
 * //   - Java Swing Project
 * _str category[] = pm.mapAll('/templates/project/Java/A Swing/JFC application'); 
 * // Returns "Other Project"
 * _str category = pm.map('/templates/project/HTML/Web Project');
 * </pre> 
 */
class PathMapper : IPathMapper {

   //
   // Private interfaces
   //

   private static bool match(_str wildcard, _str path, _str search_opts, int& strength);
   private IPathMapperIterator make_iter(_str key, _str path, _str path_to_match, bool use_default_keys);

   //
   // Private data
   //

   // path-pattern => key
   private Map m_keys;
   // default-path-pattern => key
   private Map m_default_keys;
   // Search comparison options.
   // ''  = exact match
   // 'i' = case-(i)nsensitive match
   private _str m_search_options='';

   /**
    * Constructor.
    *
    * @param caseSensitive Case-sensitivity used when finding a 
    *                      path mapping. Set to 0 (false) for
    *                      case-insensitive comparison. Set to 1
    *                      (true) for case-sensitive comparison.
    *                      Set to -1 for operating system default
    *                      filesystem case-sensitivity. Defaults to
    *                      -1.
    */
   PathMapper(int caseSensitive=-1) {

      // Guarantee items are inserted in FIFO order.
      // This allows you to impose a priority order on mappings and use
      // mapFirst/mapNext to iterate over matches in priority (FIFO)
      // order.
      m_keys.setCompareFunction(sc.collections.compare_map_item_fifo);
      m_default_keys.setCompareFunction(sc.collections.compare_map_item_fifo);

      setCaseSensitive(caseSensitive);
   }

   ~PathMapper() {
   }

   /**
    * Set case-sensitivity when finding a path mapping.
    * 
    * @param caseSensitive Case-sensitivity used when finding a 
    *                      path mapping. Set to 0 (false) for
    *                      case-insensitive comparison. Set to 1
    *                      (true) for case-sensitive comparison.
    *                      Set to -1 for operating system default
    *                      filesystem case-sensitivity. 
    */
   public void setCaseSensitive(int caseSensitive) {

      m_search_options = '';
      if( caseSensitive < 0 ) {
         // Use operating system default
         m_search_options :+= _fpos_case;
      } else if( caseSensitive == 0 ) {
         m_search_options :+= 'i';
      }
   }

   /**
    * Add a mapping with key and path.
    * 
    * @param key   Key of mapping.
    * @param path  Path of mapping.
    */
   public void add(typeless key, _str path) {
      m_keys.set(path,key);
   }

   /**
    * Add a default mapping with key and path. Default mappings are 
    * used when normal lookup fails to find a key. 
    * 
    * @param key   Key of default mapping.
    * @param path  Path of default mapping.
    */
   public void addDefault(typeless key, _str path) {
      m_default_keys.set(path,key);
   }

   /**
    * Remove all mappings by key. 
    * 
    * @param key  Key of mapping to remove.
    */
   public void removeByKey(typeless key) {

      typeless k, v;

      // Remove all mappings for path=>key
      for( k=m_keys.front(); k != null; ) {
         v = m_keys.get(k);
         if( v instanceof sc.lang.IComparable ) {
            // Use IComparable interface ==
            if( v == key ) {
               k = m_keys.delete(k);
               continue;
            }
         } else if( v :== key ) {
            k = m_keys.delete(k);
            continue;
         }
         k = m_keys.next(k);
      }

      // Remove all mappings for default=>key
      for( k=m_default_keys.front(); k != null; ) {
         v = m_default_keys.get(k);
         if( v instanceof sc.lang.IComparable ) {
            // Use IComparable interface ==
            if( v == key ) {
               k = m_default_keys.delete(k);
               continue;
            }
         } else if( v :== key ) {
            k = m_default_keys.delete(k);
            continue;
         }
         k = m_default_keys.next(k);
      }
   }

   /**
    * Remove mapping that exactly matches specified path. No 
    * pattern matching is used. If you want to remove mappings that
    * match a pattern, then use {@link removeByPathSpec}. By 
    * default, default-path mappings are not removed. 
    * 
    * @param path                Path of mapping to remove.
    * @param removeDefaultPaths  Set to true if you want to also 
    *                            remove default path mappings when
    *                            finding matching paths. Defaults
    *                            to false.
    */
   public void removeByPath(_str path, bool removeDefaultPaths=false) {

      m_keys.delete(path);

      // Defaults
      if( removeDefaultPaths ) {
         m_default_keys.delete(path);
      }
   }

   /**
    * Remove all mappings that pattern-match path. By default, 
    * default-path mappings are not removed. 
    * 
    * @param path                Path of mapping to remove.
    * @param removeDefaultPaths  Set to true if you want to also 
    *                            remove default path mappings when
    *                            finding matching paths. Defaults
    *                            to false.
    */
   public void removeByPathSpec(_str path_spec, bool removeDefaultPaths=false) {

      _str wildcard;
      typeless key;
      for( wildcard=m_keys.front(); wildcard != null; ) {
         int not_used;
         if( match(path_spec,wildcard,m_search_options,not_used) ) {
            // Found one
            wildcard = m_keys.delete(wildcard);
         } else {
            wildcard = m_keys.next(wildcard);
         }
      }

      // Defaults
      if( removeDefaultPaths ) {
         for( wildcard=m_default_keys.front(); wildcard != null; ) {
            int not_used;
            if( match(path_spec,wildcard,m_search_options,not_used) ) {
               // Found one
               wildcard = m_default_keys.delete(wildcard);
            } else {
               wildcard = m_default_keys.next(wildcard);
            }
         }
      }
   }

   /**
    * Get key for mapping that exactly matches specified path. No 
    * pattern matching is used. 
    * 
    * @param path             Path of mapping to get.
    * @param useDefaultPaths  Set to true if you want to search 
    *                         default path mappings when finding
    *                         matching paths. Defaults to false.
    *
    * @return Key of mapping that exactly matches path. null if no 
    *         match found.
    */
   public typeless getByPath(_str path, bool useDefaultPaths=false) {
      if( useDefaultPaths ) {
         return m_default_keys.get(path);
      } else {
         return m_keys.get(path);
      }
   }

   /**
    * Clear all stored path mappings. 
    */
   public void clear() {
      m_keys.clear();
      m_default_keys.clear();
   }

   /**
    * Attempt to pattern-match pattern to path specified. If match 
    * is successful, strength is set to the number of non-wildcard 
    * characters matched in the path. 
    * 
    * @param pattern 
    * @param path 
    * @param search_opts  'i'=case-insensitive lookup on path.
    * @param strength 
    * 
    * @return true if pattern-matches path.
    */
   private static bool match(_str pattern, _str path, _str search_opts, int& strength) {

      // Quick test to see if pattern matches all of path
      if( pos(pattern,path,1,search_opts'&') <= 0 || length(path) != pos('') ) {
         // No match
         return false;
      }

      // Split pattern into array of wildcard and non-wildcard chunks
      _str pat = pattern;
      _str pat_array[];
      while( pat != '' ) {
         _str search_for;
         if( verify(pat,'*?') == 1 ) {
            // Non-wildcard part
            parse pat with search_for'[\*\?]','er' +0 pat;
            pat_array[pat_array._length()] = search_for;
         } else {
            // Wildcard part
            parse pat with search_for'[~\*\?]','er' +0 pat;
            pat_array[pat_array._length()] = search_for;
         }
      }

      // Determine strength of match (how much of path was matched by
      // non-wildcard parts of pattern).
      strength = 0;
      start := 1;
      int i, n=pat_array._length();
      for( i=0; i < n; ++i ) {
         _str search_for = pat_array[i];
         if( verify(search_for,'*?') > 0 ) {
            // Non-wildcard part
            strength += length(search_for);
         } else if( _last_char(search_for) == '*' && (i+1) < n ) {
            // Trailing '*' wildcard part that is not the last part.
            // '*' could match the rest of the path, but we have more parts of
            // the pattern to match, so we have to append the end with the
            // next part of the pattern (which is a non-wildcard).
            search_for :+= pat_array[++i];
            // Do not forget to count the appended non-wildcard part
            strength += length(pat_array[i]);
         }

         // Set up for the next part of match
         pos(search_for,path,start,search_opts'&');
         // Sanity please
         if( pos('S') != start ) {
            return false;
         }
         start = start + pos('');
      }

      // Match found
      return true;
   }

   private IPathMapperIterator make_iter(_str key, _str path, _str path_to_match, bool use_default_keys) {

      PathMapperIterator pmi;

      // m_path_mapper
      pmi._setfield(PMI_FIELD_PATH_MAPPER,&this);
      // m_key
      pmi._setfield(PMI_FIELD_KEY,key);
      // m_path
      pmi._setfield(PMI_FIELD_PATH,path);
      // m_path_to_match
      pmi._setfield(PMI_FIELD_PATH_TO_MATCH,path_to_match);
      // m_default_keys
      pmi._setfield(PMI_FIELD_USE_DEFAULT_KEYS,use_default_keys);

      return pmi;
   }

   /**
    * Find the first mapping that pattern-matches the path 
    * specified. 
    * 
    * @param path  Path to match on.
    * 
    * @return Iterator pointing to match. null if there is no 
    *         match. Use <code>key</code> method of iterator to
    *         retrieve the key of the match.
    */
   public IPathMapperIterator mapFirst(_str path) {

      _str pattern;
      typeless key;

      for( pattern=m_keys.front(); pattern != null; pattern=m_keys.next(pattern) ) {
         int not_used;
         if( match(pattern,path,m_search_options,not_used) ) {
            // Found first match
            key = m_keys.get(pattern);
            return make_iter(key,pattern,path,false);
         }
      }

      // No matches yet, so try defaults
      for( pattern=m_default_keys.front(); pattern != null; pattern=m_default_keys.next(pattern) ) {
         int not_used;
         if( match(pattern,path,m_search_options,not_used) ) {
            // Found first match
            key = m_default_keys.get(pattern);
            return make_iter(key,pattern,path,true);
         }
      }

      // No match
      return null;
   }

   /**
    * Find the next mapping, relative to the current mapping given 
    * by where-iterator, that maps to the same path started by 
    * {@link mapFirst}. 
    * 
    * @param where  Iterator pointing to current mapping.
    * @param fail_fast  Set to true if you want to stop/fail if the
    *                   next mapping in-order does not match.
    *                   Defaults to false.
    * 
    * @return Iterator pointing to match. null if there is no 
    *         match. Use <code>key</code> method of iterator to
    *         retrieve the key of the match.
    */
   public IPathMapperIterator mapNext(IPathMapperIterator where, bool fail_fast=false) {

      if( where == null || !(where instanceof se.util.PathMapperIterator) ) {
         // Invalid iterator
         return null;
      }

      use_default_keys := where._getfield(PMI_FIELD_USE_DEFAULT_KEYS);
      Map* pkeys;
      if( use_default_keys ) {
         pkeys = &m_default_keys;
      } else {
         pkeys = &m_keys;
      }

      typeless key;
      _str pattern = where._getfield(PMI_FIELD_PATH);
      _str path = where._getfield(PMI_FIELD_PATH_TO_MATCH);
      for( pattern=pkeys->next(pattern); pattern != null; pattern=pkeys->next(pattern) ) {
         int not_used;
         if( match(pattern,path,m_search_options,not_used) ) {
            // Found next match
            key = pkeys->get(pattern);
            return make_iter(key,pattern,path,use_default_keys);
         } else if( fail_fast ) {
            // Fail on first non-match
            return null;
         }
      }

      // No match
      return null;
   }

   /**
    * Find and return the key with <b>strongest</b> pattern-match 
    * against path passed in. A strongest-match is one where the 
    * most non-wildcard characters in the pattern match the path. 
    * 
    * @param path  Path to match on.
    * 
    * @return Strongest key that pattern-matches path, or null if 
    *         not found.
    *
    * @example
    * If we have the following mappings:
    * <ul>
    * <li>'*.??ml' ::: "Markup Language File"</li>
    * <li>'*.html' ::: "HTML File"</li>
    * </ul>
    *
    * Then we get the following results when a path is mapped:
    * <ul>
    * <li>'index.html' =maps=to=> "HTML File" because 5 
    * non-wildcard characters from '*.html' match the path, 
    * while only 3 non-wildcard characters from '*.??ml' 
    * match.</li> 
    * <li>'data.xml' =maps=to=> "Markup Language File" because 
    * '*.??ml' is the only pattern that matches the path.</li> 
    * </ul>
    */
   public typeless map(_str path) {

      // Quick lookup first.
      // We will fall through to pattern-matching if:
      // 1) pattern and path are not an exact, case-sensitive match, or
      // 2) pattern is a wildcard and path is not
      if( m_keys.exists(path) ) {
         // Found it in one
         return m_keys:[path];
      }

      // Have to find strongest pattern match
      strongest := -1;
      strongest_key := null;
      _str pattern;
      typeless key;
      foreach( pattern=>key in m_keys ) {
         int strength;
         if( match(pattern,path,m_search_options,strength) ) {
            if( strength > strongest ) {
               strongest = strength;
               strongest_key = key;
            }
         }
      }

      // If no match in wildcards, then try defaults
      if( strongest_key == null ) {
         foreach( pattern=>key in m_default_keys ) {
            int strength;
            if( match(pattern,path,m_search_options,strength) ) {
               if( strength > strongest ) {
                  strongest = strength;
                  strongest_key = key;
               }
            }
         }
      }

      return strongest_key;
   }

   /**
    * Find and return all keys with path pattern-matching path 
    * passed in. 
    * 
    * @param path  Path to match on.
    * 
    * @return Array of all keys that pattern-match path.
    */
   public TYPELESSARRAY mapAll(_str path) {

      typeless result[];

      _str pattern;
      typeless key;
      foreach( pattern=>key in m_keys ) {
         int not_used;
         if( match(pattern,path,m_search_options,not_used) ) {
            // Found one
            result[result._length()] = key;
         }
      }

      // If no matches yet, then try defaults.
      // Note we only include the strongest default match since
      // returning all default matches is generally not useful.
      if( result._length() == 0 ) {
         strongest := -1;
         foreach( pattern=>key in m_default_keys ) {
            int strength;
            if( match(pattern,path,m_search_options,strength) ) {
               if( strength > strongest ) {
                  result[0] = key;
               }
            }
         }
      }

      return result;
   }

   /**
    * Get all non-default mappings indexed by path (path=>key).
    * 
    * @return Map of non-default mappings.
    */
   Map getMappings() {
      return m_keys;
   }

   /**
    * Get all default mappings indexed by path (path=>key).
    * 
    * @return Map of non-default mappings.
    */
   Map getDefaultMappings() {
      return m_default_keys;
   }

};
