#ifndef CSV_SH
#define CSV_SH

#pragma option(metadata,"main.e")

extern _str _csv_get_filename(int handle);
extern int_csv_get_modify(int handle);
extern void _csv_set_modify(int handle,bool modify);

extern int _csv_open(_str filename,int encoding=VSENCODING_AUTOUNICODEUTF8);
extern int _csv_create(_str filename="");
extern int _csv_close(int handle);
extern int _csv_save(int handle, _str filename=null,_str NLChars=null);
extern long _csv_row_first(int handle);
extern long _csv_row_next(long hrow,bool removeCurrent);
extern void _csv_row_remove(long hrow);
extern _str _csv_row_get_col(long hrow,int col_index);
extern void _csv_row_set_col(long hrow,int col_index,_str value);

extern int _csv_get_Nofcols(int handle);
extern _str _csv_get_col_name(int handle,int col_index);
extern void _csv_set_col_name(int handle,int col_index,_str col_name);
extern int _csv_get_col_index(int handle,_str col_name);
extern long _csv_append_row(int handle);
struct VSCSV_NEW_COL {
   _str m_col_name;
   _str m_default_value;
};
extern void _csv_append_cols(int handle,VSCSV_NEW_COL (&newcols)[]);

enum VSCSVMATCHOP {
    VSCSVMATCHOP_EQUAL,
    VSCSVMATCHOP_NOTEQUAL,
    VSCSVMATCHOP_CONTAINS,
    VSCSVMATCHOP_LTE,
    VSCSVMATCHOP_LT,
    VSCSVMATCHOP_GTE,
    VSCSVMATCHOP_GT,
};

struct VSCSVMATCH {
    int m_col_index1;  // Must be valid
    int m_col_index2;  // May be invalid <0
    _str m_search_string;   // Used when m_col_index2<0
    _str m_search_options;  // Used when m_col_index2<0
    VSCSVMATCHOP m_matchop;
    bool m_case_sensitive_non_regex_op;
    bool m_numeric_non_regex_op;
}
extern int _csv_find_insert(int handle,VSCSVMATCH (&matchlist)[]=null,_str col_names='', int maxrows=1000, bool set_user_info_to_row_handle=true);
//extern int _csv_find_array(int handle,VSCSVMATCH (&matchlist)[],long (&hrow_array)[]);

#endif
