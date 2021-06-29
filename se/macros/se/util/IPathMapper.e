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
#require "sc/lang/IIterable.e"
#require "sc/collections/Map.e"
#endregion

namespace se.util;

using sc.collections.Map;

typedef typeless TYPELESSARRAY[];

/**
 * Iterator used to point to a mapped item.
 */
interface IPathMapperIterator {

   /**
    * Retrieve current key pointed to by this iterator.
    * 
    * @return Current key pointed to by iterator.
    */
   typeless key();

};


/**
 * Interface for mapping file and directory patterns to keys.
 */
interface IPathMapper {

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
   void setCaseSensitive(int caseSensitive);

   /**
    * Add a mapping with key and path.
    * 
    * @param key   Key of mapping.
    * @param path  Path of mapping.
    */
   void add(typeless key, _str path);

   /**
    * Add a default mapping with key and path. Default mappings are 
    * used when normal lookup fails to find a key. 
    * 
    * @param key   Key of default mapping.
    * @param path  Path of default mapping.
    */
   void addDefault(typeless key, _str path);

   /**
    * Remove all mappings by key. 
    * 
    * @param key  Key of mapping to remove.
    */
   void removeByKey(typeless key);

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
   void removeByPath(_str path, bool removeDefaultPaths=false);

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
   void removeByPathSpec(_str path_spec, bool removeDefaultPaths=false);

   /**
    * Get key for mapping that exactly matches specified path. No 
    * pattern matching is used. 
    * 
    * @param path             Path of mapping to remove.
    * @param useDefaultPaths  Set to true if you want to search 
    *                         default path mappings when finding
    *                         matching paths. Defaults to false.
    *
    * @return Key of mapping that exactly matches path. null if no 
    *         match found.
    */
   typeless getByPath(_str path, bool useDefaultPaths=false);

   /**
    * Clear all stored path mappings. 
    */
   void clear();

   /**
    * Find the first mapping that pattern-matches the path 
    * specified. 
    * 
    * @param path  Path to match on.
    * 
    * @return Iterator pointing to match. Use <code>key</code> 
    *         method of iterator to retrieve the key of the match.
    */
   IPathMapperIterator mapFirst(_str path);

   /**
    * Find the next mapping, relative to the current mapping given 
    * by where-iterator, that maps to the same path started by 
    * {@link mapFirst}. 
    * 
    * @param iter  Iterator pointing to current mapping.
    * @param fail_fast  Set to true if you want to stop/fail if the
    *                   next mapping in-order does not match.
    *                   Defaults to false.
    * 
    * @return Iterator pointing to match. Use <code>key</code> 
    *         method of iterator to retrieve the key of the match.
    */
   IPathMapperIterator mapNext(IPathMapperIterator where, bool fail_fast=false);

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
   typeless map(_str path);

   /**
    * Find and return all keys with path pattern-matching path 
    * passed in. 
    * 
    * @param path  Path to match on.
    * 
    * @return Array of all keys that pattern-match path.
    */
   TYPELESSARRAY mapAll(_str path);

   /**
    * Get all non-default mappings indexed by path (path=>key).
    * 
    * @return Map of non-default mappings.
    */
   Map getMappings();

   /**
    * Get all default mappings indexed by path (path=>key).
    * 
    * @return Map of non-default mappings.
    */
   Map getDefaultMappings();

};
