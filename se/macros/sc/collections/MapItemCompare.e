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
#endregion Imports

/*
 * Utility functions used by Map and MultiMap classes for the
 * purpose of maintaining map items in sorted order.
 */

namespace sc.collections;


// Comparison function used to maintain map items in sorted order.
// (key1,value1) represents item1. (key2,value2) represents item2.
//
// A custom comparison function MUST handle the case of null values.
//
// Return:
//   < 0  if item1 < item2
//   == 0 if item1 == item2
//   > 0  if item1 > item2
typedef int (*MapItemCompareFunction)(_str key1, _str key2, typeless& value1, typeless& value2);

/**
 * Case-sensitive, ascending-order comparison of first item 
 * (key1,value1) with second item (key2,value2). 
 * 
 * @param key1 
 * @param key2 
 * @param value1 
 * @param value2 
 * 
 * @return 
 * <pre>
 * < 0  if item1 < item2 
 * == 0 if item1 == item2 
 * > 0  if item1 > item2 
 * </pre>
 */
int compare_map_item_a(_str key1, _str key2, typeless& value1, typeless& value2) {
   return strcmp(key1,key2);
}

/**
 * Case-insensitive, ascending-order comparison of first item 
 * (key1,value1) with second item (key2,value2). 
 * 
 * @param key1 
 * @param key2 
 * @param value1 
 * @param value2 
 * 
 * @return 
 * <pre>
 * < 0  if item1 < item2 
 * == 0 if item1 == item2 
 * > 0  if item1 > item2 
 * </pre>
 */
int compare_map_item_ia(_str key1, _str key2, typeless& value1, typeless& value2) {
   return stricmp(key1,key2);
}

/**
 * Case-sensitive, descending-order comparison of first item 
 * (key1,value1) with second item (key2,value2). 
 * 
 * @param key1 
 * @param key2 
 * @param value1 
 * @param value2 
 * 
 * @return 
 * <pre>
 * < 0  if item2 < item1 
 * == 0 if item2 == item1 
 * > 0  if item2 > item1 
 * </pre>
 */
int compare_map_item_d(_str key1, _str key2, typeless& value1, typeless& value2) {
   return strcmp(key2,key1);
}

/**
 * Case-insensitive, descending-order comparison of first item 
 * (key1,value1) with second item (key2,value2). 
 * 
 * @param key1 
 * @param key2 
 * @param value1 
 * @param value2 
 * 
 * @return 
 * <pre>
 * < 0  if item2 < item1 
 * == 0 if item2 == item1 
 * > 0  if item2 > item1 
 * </pre>
 */
int compare_map_item_id(_str key1, _str key2, typeless& value1, typeless& value2) {
   return stricmp(key2,key1);
}

/**
 * Comparison of first item (key1,value1) with second item 
 * (key2,value2) always returns > 0. This guarantees that the 
 * last item inserted will be inserted at the end (FIFO). 
 * 
 * @param key1 
 * @param key2 
 * @param value1 
 * @param value2 
 * 
 * @return > 0
 */
int compare_map_item_fifo(_str key1, _str key2, typeless& value1, typeless& value2) {
   return 1;
}

/**
 * Comparison of first item (key1,value1) with second item 
 * (key2,value2) always returns < 0. This guarantees that the 
 * last item inserted will be inserted at the front (LIFO). 
 * 
 * @param key1 
 * @param key2 
 * @param value1 
 * @param value2 
 * 
 * @return < 0
 */
int compare_map_item_lifo(_str key1, _str key2, typeless& value1, typeless& value2) {
   return -1;
}
