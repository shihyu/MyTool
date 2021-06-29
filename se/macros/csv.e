#pragma option(pedantic,on)
#pragma option(strict,on)
#region Imports
#include "slick.sh"
#include "csv.sh"
#import "stdprocs.e"
#import "treeview.e"
#endregion

void _csv_match_init(VSCSVMATCH &match) {
   match.m_col_index1=-1;
   match.m_col_index2=-1;
   match.m_search_string='';
   match.m_search_options='';
   match.m_matchop=VSCSVMATCHOP_CONTAINS;
   match.m_case_sensitive_non_regex_op=true;
   match.m_numeric_non_regex_op=false;
}
#if 0
 /* @param tree_parent_node  Specifies a tree item. Row data is inserted 
 * beneath this node. The root of the tree can't be deleted and 
 * always has an item index of 0. 
 */  
#endif

/**
 * clears tree and insert CSV rows with columns headings
 * 
 * @author cmaurer (1/2/20)
 * 
 * @param handle CSV handle returned from _csv_create() or 
 *               _csv_open()
 * @param matchlist Zero or more column expressions which much 
 *                  be true for row to be inserted.
 * @param col_names Space delimited list of column names to 
 *                  insert into tree. Column names with spaces
 *                  should be double quoted. If column names is
 *                  empty, all columns are inserted.
 * @param maxrows   Maximum number of rows to insert
 * @param set_user_info_to_row_handle When true, tree leaf user
 *                                    info is set to row
 *                                    handle.
 * 
 * @return int If successful, returns number of rows inserted. 
 *         Otherwise, a negative return code is returned.
 */
int _csv_find_insert_with_headings(int handle,VSCSVMATCH (&matchlist)[]=null,_str col_names='', int maxrows=1000, bool set_user_info_to_row_handle=true) {

   _TreeDelete(TREE_ROOT_INDEX,'C');
   int count=_TreeGetNumColButtons();
   int i;
   for (i=count-1;i>=0;--i) {
      _TreeDeleteColButton(i);
   }
   if (col_names=='') {
      for (col_index:=0;col_index<_csv_get_Nofcols(handle);++col_index) {
         if (length(col_names)) {
            strappend(col_names,' ');
         }
         strappend(col_names,_maybe_quote_filename(_csv_get_col_name(handle,col_index)));
      }
   }
   _str orig_col_names=col_names;
   for (i=0;;++i) {
      col_name:=parse_file(col_names,false);
      if (col_name=='') {
         break;
      }
      col_index:=_csv_get_col_index(handle,col_name);
      if (col_index<0) {
         return -1; //CMRC_CSV_COLUMN_NOT_FOUND;
      }

      _TreeSetColButtonInfo(i,1400,0,0,col_name);
   }
   result:=_csv_find_insert(handle,matchlist,col_names,maxrows,set_user_info_to_row_handle);
   _TreeAdjustColumnWidths(-1);

   return result;
}
