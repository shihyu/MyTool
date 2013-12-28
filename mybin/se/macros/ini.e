////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50062 $
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
#import "files.e"
#import "listbox.e"
#import "main.e"
#import "put.e"
#import "savecfg.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

/*

    _BufEdit should only be used when opening buffers on dialog
    boxes.

    load_options may be "" or only may contain the following
      +bi buf_id
      +d
      +b

*/
int _BufEdit(_str filename,_str load_options="",boolean IgnoreNotFound=true,_str load_options2="",boolean quiet=false)
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   if (filename=='') {
      return(FILE_NOT_FOUND_RC);
   }
   typeless buf_id=0;
   parse load_options with '+bi 'buf_id;

   boolean buffer_already_exists=(lowcase(load_options)!='+d' &&
                                  buf_match(absolute(filename),1,'hx')!='') || buf_id!='';
   int status=0;
   int BLResultFlags=0;
   if (buf_id!='') {
      status=_BufLoad(filename,load_options' 'load_options2);
   } else if (load_options=='+b') {
      status=_BufLoad(filename,load_options' 'load_options2);
   } else {
      /*parse def_max_loadall with on size;
      TempNoLoad="";
      if (on && isinteger(size) && size > 0 &&
          _filesize(filename) > size * 1024) {
         TempNoLoad='-L ';
      }
      */
      load_options=build_load_options(filename)" "/*TempNoLoad:+*/load_options:+' 'load_options2;
      mou_hour_glass(1);
      status=_BufLoad(filename,load_options,IgnoreNotFound,BLResultFlags);
      mou_hour_glass(0);
   }
   if (status<0) {
      return(status);
   }
   int temp_view_id=0;
   int orig_view_id2=0;
   buf_id=status;
   _open_temp_view('',temp_view_id,orig_view_id2,'+bi 'buf_id);
   p_buf_flags=p_buf_flags | VSBUFFLAG_DELETE_BUFFER_ON_CLOSE;
   if (!buffer_already_exists) {
      p_buf_flags=p_buf_flags | VSBUFFLAG_HIDDEN;
   }
   if ( p_readonly_mode && (BLResultFlags&VSBLRESULTFLAG_READONLY)) {
      _str command='read-only-mode';
      if (!quiet) {
         if ( BLResultFlags&VSBLRESULTFLAG_READONLYACCESS) {
            message(nls('Warning:  You have read only access to this file'));
         } else {
            message(nls('Warning:  Another process has read access'));
         }
      }
      _SetEditorLanguage();
      call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
      call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
      _restore_filepos(p_buf_name);
      if ( index_callable(find_index(command,COMMAND_TYPE)) ) {
         //execute(command,"");
         read_only_mode();
      }
   } else if (p_LangId=='') {
      if (BLResultFlags&VSBLRESULTFLAG_NEW) {
         _SetEditorLanguage();
         call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
         call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
         _restore_filepos(p_buf_name);
      }
   }
   _SaveCursorInfo();
   _delete_temp_view(temp_view_id,false);
   activate_window(orig_view_id);
   return(buf_id);
}
/*
    temp_option
    +t
    +tu
    +tm
    +td

    load_options
      +70

*/
int _BufCreate(_str temp_option,_str load_options,int reserved)
{
   int orig_view_id=0;
   get_window_id(orig_view_id);

   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   int status=load_files(' +q 'def_load_options' 'load_options' 'temp_option);
   if (status) {
      _safe_hidden_window();
      activate_window(orig_view_id);
      return(status);
   }
   int buf_id=p_buf_id;
   p_buf_flags=p_buf_flags | VSBUFFLAG_DELETE_BUFFER_ON_CLOSE;
   p_buf_flags=p_buf_flags | VSBUFFLAG_HIDDEN;
   _SetEditorLanguage();
   call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
   call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
   _safe_hidden_window();
   activate_window(orig_view_id);
   return(buf_id);
}

/** 
 * Creates view and buffer containing section.  The start of a 
 * section is identified by a section name in square brackets.  All lines until 
 * the next section or end of file are copied not including the start section 
 * line.
 * 
 * @return Returns 0 if successful.
 * 
 * @categories File_Functions, Miscellaneous_Functions
 * 
 */
int _ini_get_section(_str filename,_str section_name,int &temp_view_id)
{
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename,ini_view_id,view_id);
   if (status){
      return(status);
   }
   status=_ini_get_section2(section_name,temp_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(status);
}

/** 
 * Gets all lines from a section and stores them in the array
 * <i>data</i>. The start of a section is identified by a
 * section name in square brackets. All lines until the next
 * section or end of file are copied <b>not</b> including the 
 * start section line. 
 * 
 * <p>
 *
 * This will not parse values, but get whole lines.  It is well
 * suited to grabbing lists of files (no '=value' to worry 
 * about). 
 * 
 * @param filename      ini file to get section from.
 * @param section_name  Section to load into <i>data</i>.
 * @param data          Array that will receive data from 
 *                      section specified in the ini file.
 * 
 * @return Returns 0 if successful.
 * 
 * @categories File_Functions, Miscellaneous_Functions
 */
int _ini_get_section_array(_str filename, _str section_name, _str (&data)[])
{
   int temp_wid;
   int orig_wid = p_window_id;
   int status = _ini_get_section(filename,section_name,temp_wid);
   if( status != 0 ) {
      // Error
      return status;
   }
   p_window_id = temp_wid;
   top();up();
   while( !down() ) {
      _str curline = "";
      get_line(curline);
      data[data._length()] = curline;
   }
   _delete_temp_view(temp_wid);
   p_window_id = orig_wid;
   return status;
}

void _ini_get_section3(int &temp_view_id)
{
   int ini_view_id=0;
   get_window_id(ini_view_id);
   boolean utf8=p_UTF8;
   _create_temp_view(temp_view_id);
   p_UTF8=utf8;
   activate_window(ini_view_id);
   down();
   _str line="";
   get_line(line);
   if (substr(line,1,1)=='[') {
      return;// Nothing was in the section
   }
   typeless mark_id=_alloc_selection();
   _select_line(mark_id);
   if (_ini_find_section('')) {
      bottom();
   }else{
      up();
   }
   _select_line(mark_id);
   activate_window(temp_view_id);
   _copy_to_cursor(mark_id);
   p_line=1;
   _free_selection(mark_id);
   int Nofchanges=0;
   search('^[ \t]@\n','@rih','',Nofchanges);
   // above replace does not delete the last line.
   // so do that specially here.
   bottom();
   get_line(line);
   if (line=='') {
      _delete_line();
   }
   p_line=1;
}
static int _ini_get_section2(_str section_name,int &temp_view_id)
{
   int status=_ini_find_section(section_name);
   if (status) {
      return(status);
   }
   _ini_get_section3(temp_view_id);
   return(0);
}

/** 
 * For each <i>field_name</i>=<i>value</i> line in buffer 
 * corresponding in <i>temp_view_id</i>, the <i>field_name</i> value is replaced 
 * or inserted into <i>section</i>.  In addition, the <i>temp_view_id</i> is 
 * deleted.  Unlike the <b>_ini_put_section</b> function, fields which are not 
 * defined are NOT deleted.  This allows more than one user to replace multiple 
 * field values in one call without deleting field names defined by someone 
 * else.  This function is slower than the <b>_ini_put_section</b> function 
 * which replaces the entire section with the buffer corresponding to 
 * <i>temp_view_id</i>.
 * 
 * @return 0 if successful
 * 
 * <pre>
 *      ".ini" File Syntax:
 *          [<i>section1</i>]
 *          <i>field_name1</i>=<i>value1</i>
 *          <i>field_name2=value2</i>
 *          ...
 *          [<i>section2</i>]
 *          <i>field_name1=value1</i>
 *          field_name2=<i>value2</i>
 *          ...
 * </pre>
 * 
 * @categories File_Functions, Miscellaneous_Functions
 * 
 */
int _ini_replace_section(_str filename,_str section_name,int temp_view_id)
{
   /* Just adds the section if it doesn't already exist */
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename, ini_view_id, view_id);
   if (status==FILE_NOT_FOUND_RC) {
      view_id=_create_temp_view(ini_view_id);
      p_buf_name=absolute(filename);
      p_UTF8=_load_option_UTF8(p_buf_name);
      status=0;
   }
   if (status) {
      return(status);
   }
   activate_window(ini_view_id);
   _ini_replace_section2(section_name, temp_view_id);
   _delete_temp_view(ini_view_id);
   _delete_temp_view(temp_view_id);
   if (view_id!=temp_view_id) {
      activate_window(view_id);
   }
   return(0);
}

/** 
 * Replaces all <i>field_name</i>=<i>value</i> lines in the section 
 * specified with the buffer text contained in <i>temp_view_id</i>.
 * 
 * @return zero if successful
 * 
 * <pre>
 *      ".ini" File Syntax:
 *          [<i>section1</i>]
 *          <i>field_name1</i>=<i>value1</i>
 *          <i>field_name2=value2</i>
 *          ...
 *          [<i>section2</i>]
 *          <i>field_name1=value1</i>
 *          field_name2=<i>value2</i>
 *          ...
 * </pre>
 * 
 * @see _ini_replace_section
 * 
 * @categories File_Functions, Miscellaneous_Functions
 * 
 */
int _ini_put_section(_str filename,_str section_name,int temp_view_id)
{
   /* Just adds the section if it doesn't already exist */
   /* Had to write this to put in filenames(logic for adding in var=val form messed up
      searching for filenames */
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename, ini_view_id, view_id);
   if (status==FILE_NOT_FOUND_RC) {
      view_id=_create_temp_view(ini_view_id);
      p_buf_name=absolute(filename);
      p_UTF8=_load_option_UTF8(p_buf_name);
      status=0;
   }
   if (status) {
      return(status);
   }
   activate_window(ini_view_id);
   status=_ini_put_section2(section_name, temp_view_id);
   _delete_temp_view(ini_view_id);
   _delete_temp_view(temp_view_id);
   if (view_id!=temp_view_id) {
      activate_window(view_id);
   }
   return(status);
}

int _ini_put_section2(_str section_name,int temp_view_id)
{
   int ini_view_id=0;
   get_window_id(ini_view_id);
   top();
   int status=_ini_find_section(section_name);
   if (status) {
      bottom();
      insert_line('['section_name']');
   } else {
      // Delete contents of section
      // Cursor should be placed on header.
      _ini_delete_section3(0);
   }
   activate_window(temp_view_id);
   typeless mark_id=_alloc_selection();
   top();
   _select_line(mark_id);
   bottom();
   status=_select_line(mark_id);
   if (status) {
      clear_message();
      activate_window(ini_view_id);
      return(_save_config_file());//Nothing in temp_view_id;
   }
   activate_window(ini_view_id);
   _copy_to_cursor(mark_id);
   _free_selection(mark_id);
   return(_save_config_file());
}

static int _ini_replace_section2(_str section_name,int temp_view_id)
{
   int ini_view_id=0;
   get_window_id(ini_view_id);
   int status=_ini_find_section(section_name);
   if (status) {
      insert_line('['section_name']');
      activate_window(temp_view_id);
      typeless mark_id=_alloc_selection();
      top();
      _select_line(mark_id);
      bottom();
      _select_line(mark_id);
      activate_window(ini_view_id);
      _copy_to_cursor(mark_id);
      _free_selection(mark_id);
      return(_save_config_file());
   }
   save_search(auto a,auto b,auto c,auto d);
   _end_line();
   // We are sitting on the section name at end of line
   save_pos(auto p);
   activate_window(temp_view_id);
   _str line="";
   get_line(line);
   top();up();
   for (;;) {
      activate_window(temp_view_id);
      if (down()) {
         break;
      }
      get_line(line);
      typeless value="";
      _str var_name="";
      _str equalsign="";
      parse line with var_name '=' +0 equalsign;
      if (equalsign!='') {
         parse equalsign with '=' value;
      }else{
         value='';
      }
      activate_window(ini_view_id);
      restore_pos(p);
      if (equalsign=='') {
         // Searching for a filename
         status=search('^('_escape_re_chars(var_name)'$|\[)','rh@'((_fpos_case=='')?'e':'i'));
         if (status) {
            bottom();
            insert_line(var_name);
            continue;
         }else{
            get_line(line);
            if (substr(line,1,1)=='[') {
               up();
               insert_line(var_name);
            } else {
               replace_line(var_name);
            }
            continue;
         }
      }
      // We are sitting on the section name at end of line
      status=search('^('var_name'=|\[)','rih@');
      if (status) {
         insert_line(var_name'='value);
         continue;
      }
      get_line(line);
      if (substr(line,1,1)=='[') {
         up();
         insert_line(var_name '=' value);
         continue;
      }
      //parse line with old_name '=' old_val;
      replace_line(var_name '=' value);
   }
   activate_window(ini_view_id);
   restore_search(a,b,c,d);
   return(_save_config_file());
}

/**
 * Sets values of a table full of fields and values (field name = key, value = 
 * value). 
 * 
 * @param filename 
 * @param section_name 
 * @param fieldValueTable 
 * @param case_option 
 * 
 * @return                 0 if successful 
 *  
 * @categories File_Functions, Miscellaneous_Functions
 */
int _ini_set_hashtable_values(_str filename, _str section_name, _str (&fieldValueTable):[], _str case_option = null)
{
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename,ini_view_id, view_id);
   if (status) {
      // check if the file exists, maybe we should just make a nice new one
      if (status==FILE_NOT_FOUND_RC && filename!="") {
         view_id=_create_temp_view(ini_view_id);
         p_buf_name=absolute(filename);
         p_UTF8=_load_option_UTF8(p_buf_name);
         status=0;
      } else {
         return(status);
      }
   }

   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(ini_view_id);

   _str field_name, new_value;
   foreach (field_name => new_value in fieldValueTable) {
      status=_ini_set_value2(section_name,field_name,new_value,case_option);
   }

   activate_window(orig_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(status);
}

/** 
 * Gets all name=value pairs from a section and stores them in 
 * the hash table <i>fieldValueTable</i> as name=&gt;value. The 
 * start of a section is identified by a section name in square 
 * brackets. All name=value pairs until the next section or end 
 * of file are copied. 
 * 
 * <p>
 *
 * If there is no value (i.e. no '=value' part) for a particular
 * item in the section, then only the hash table key will be set
 * and the hash table value will be null. 
 * 
 * @param filename         ini file to get section from.
 * @param section_name     Section to load into <i>data</i>.
 * @param fieldValueTable  Hash table that will receive data 
 *                         from section specified in the ini
 *                         file.
 * 
 * @return Returns 0 if successful.
 * 
 * @categories File_Functions, Miscellaneous_Functions
 */
int _ini_get_hashtable_values(_str filename, _str section_name, _str (&fieldValueTable):[])
{
   int temp_wid;
   int orig_wid = p_window_id;
   int status = _ini_get_section(filename,section_name,temp_wid);
   if( status != 0 ) {
      return status;
   }

   _str fieldName;
   _str value;
   p_window_id = temp_wid;
   top();up();
   while( !down() ) {
      _str curline = "";
      get_line(curline);
      parse curline with fieldName '=' value;
      fieldValueTable:[fieldName] = value;
   }

   _delete_temp_view(temp_wid);
   p_window_id = orig_wid;
   return status;
}

/** 
 * Sets value of <i>field_name</i> defined within <i>section</i> of 
 * <i>filename</i> to <i>value</i> specified.
 * 
 * @return 0 if successful
 * 
 * <pre>
 *      ".ini" File Syntax:
 *          [<i>section1</i>]
 *          <i>field_name1</i>=<i>value1</i>
 *          <i>field_name2=value2</i>
 *          ...
 *          [<i>section2</i>]
 *          <i>field_name1=value1</i>
 *          field_name2=<i>value2</i>
 *          ...
 * </pre>
 * 
 * @categories File_Functions, Miscellaneous_Functions
 * 
 */
int _ini_set_value(_str filename,_str section_name,_str field_name,_str new_value, _str case_option=null)
{
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename,ini_view_id, view_id);
   if (status) {
      if (status==FILE_NOT_FOUND_RC && filename!="") {
         view_id=_create_temp_view(ini_view_id);
         p_buf_name=absolute(filename);
         p_UTF8=_load_option_UTF8(p_buf_name);
         status=0;
      } else {
         return(status);
      }
   }
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(ini_view_id);
   status=_ini_set_value2(section_name,field_name,new_value,case_option);
   activate_window(orig_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(status);
}

static int _ini_set_value2(_str section_name,_str field_name,_str new_value,_str case_option)
{
   // see if we even have this section - if not, create it!
   int status=_ini_find_section(section_name);
   if (status) {
      // IF trying to delete this field
      if (new_value._isempty()) {
         return(0);
      }
      insert_line('['section_name']');
      insert_line(field_name'='new_value);
      /* a little useless cleanup */
      down();
      _str line="";
      get_line(line);
      if (line=='') {
         _delete_line();
      }
      status=_save_config_file();
      //messageNwait('h4 status='status' 'p_buf_name);
      return(status);
   }

   _end_line();
   save_search(auto a,auto b,auto c,auto d);
   status=search('^('_escape_re_chars(field_name)'=|\[)', 'rh@'(case_option==null?'i':case_option));
   restore_search(a,b,c,d);
   if (status) {
      // IF trying to delete this field
      if (new_value._isempty()) {
         return(0);
      }
      bottom();
      for (;;) {
         if (_line_length()) break;
         up();
      }
      insert_line(field_name'='new_value);
      status=_save_config_file();
      //messageNwait('h3 status='status' 'p_buf_name);
      return(status);
   }
   _str line="";
   get_line(line);
   if (substr(line,1,1)=='[') {
      // IF trying to delete this field
      if (new_value._isempty()) {
         return(0);
      }
      up();
      insert_line(field_name'='new_value);
      status=_save_config_file();
      //messageNwait('status='status' 'p_buf_name);
      return(status);
   }
   _str old_fname="";
   _str old_value="";
   parse line with old_fname '=' old_value;
   // IF trying to delete this field
   if (new_value._isempty()) {
      _delete_line();
   } else {
      replace_line(field_name'='new_value);
   }
   status=_save_config_file();
   //messageNwait('h2 status='status' 'p_buf_name);
   return(status);
}

/** 
 * Places value for <i>field_name</i> defined within section of file 
 * specified in <i>result</i> variable.  The start of a section is identified by 
 * a section name in square brackets.  All lines until the next section or end 
 * of file are part of the section.  If <i>section</i> or <i>field_name</i> do 
 * not exist, <i>default_value</i> is placed in <i>result</i>. 
 * 
 * @param default_value has no effect on ini file.  It only affects return
 * value when section name or field name does not exist.
 * 
 * <pre>
 *    ".ini" File Syntax:
 *          [<i>section1</i>]
 *          <i>field_name1</i>=<i>value1</i>
 *          <i>field_name2=value2</i>
 *          ...
 *          [<i>section2</i>]
 *          <i>field_name1=value1</i>
 *          field_name2=<i>value2</i>
 *          ...
 * </pre>
 * 
 * @return Returns 0 if successful.
 * 
 * @categories File_Functions, Miscellaneous_Functions
 * 
 */
int _ini_get_value(_str filename, _str section_name, _str field_name,
                   _str &result, _str default_value='', _str case_option=null)
{
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename,ini_view_id,view_id);
   if (status) {
      activate_window(view_id);
      result=default_value;
      return(status);
   }
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(ini_view_id);
   // If section_name or field_name not found, 'default_value' is returned
   // actual value in file not changed.
   status=_ini_get_value2(section_name,field_name,result,default_value,true,case_option);

   activate_window(orig_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(status);
}

/*
    default_value has no effect on ini file.  It only affects return
    value when section name or field name does not exist.
*/
int _ini_get_all_values(_str filename, _str section_name, _str field_name,
                        _str (&result)[], _str (&default_value)[]=null)
{
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename,ini_view_id,view_id);
   if (status) {
      activate_window(view_id);
      result=default_value;
      return(status);
   }
   if (result._varformat()!=VF_ARRAY) {
      result._makeempty();
   }
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(ini_view_id);
   boolean found=false;
   boolean ff=true;
   for (ff=1;;ff=0) {
      // If section_name or field_name not found, 'default_value' is returned
      // actual value in file not changed.
      _str tempresult="";
      _str tempdefault="";
      if (default_value!=null) tempdefault=default_value[result._length()];
      status=_ini_get_value2(section_name,field_name,tempresult,tempdefault,ff);
      if (status) {
         break;
      }
      result[result._length()]=tempresult;
      found=true;
   }

   activate_window(orig_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(found?0:status);
}

static int _ini_find_value(_str section_name,_str field_name)
{
   // If section_name or field_name not found, arg(5) is returned
   // actual value in file not changed.
   if (_ini_find_section(section_name)) {
      return(STRING_NOT_FOUND_RC);  // String not found in section
   }
   _end_line();
   save_search(auto a,auto b,auto c,auto d);
   int status=search('^('_escape_re_chars(field_name)'=|\[)', 'rih@');
   restore_search(a,b,c,d);
   if (status) {
      return(STRING_NOT_FOUND_RC);
   }
   _str line="";
   get_line(line);
   if (substr(line,1,1)=='[') {
      return(STRING_NOT_FOUND_RC);
   }
   return(0);
}
int _ini_delete_value(_str filename,_str section_name,_str field_name)
{
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename,ini_view_id,view_id);
   if (status) {
      activate_window(view_id);
      return(status);
   }
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(ini_view_id);

   status=_ini_find_value(section_name,field_name);
   if (!status) {
      _delete_line();
      status=_save_config_file();
   }

   activate_window(orig_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(status);
}

/** 
 * Deletes section specified from <i>filename</i>.  The start of a 
 * section is identified by a section name in square brackets.  All lines until 
 * the next section or end of file are deleted.
 * 
 * @return Returns 0 if successful.
 * 
 * @categories File_Functions, Miscellaneous_Functions
 * 
 */
int _ini_delete_section(_str filename,_str section_name)
{
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename,ini_view_id,view_id);
   if (status) return(status);
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(ini_view_id);
   status=_ini_delete_section2(section_name);

   activate_window(orig_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(status);
}

/*
   Call this function with cursor sitting on
   section header line [...]
*/
void _ini_delete_section3(boolean DeleteHeader)
{
   typeless status=0;
   typeless mark_id=_alloc_selection();
   if (DeleteHeader) {
      _select_line(mark_id);
      status=down();
      if (!status) {
         status=_ini_find_section('');
      }
   } else {
      status=down();
      if (status) {
         _free_selection(mark_id);
         return;
      }
      _select_line(mark_id);
      int linenum=p_line;
      status=_ini_find_section('');
      // Nothing to delete
      if (!status) {
         if (linenum==p_line) {
            up();
            _free_selection(mark_id);
            return;
         }
      }
   }
   if (status) {
      bottom();
   }else{
      up();
   }
   _select_line(mark_id);
   if (!DeleteHeader) {
      // Place cursor on header line
      _begin_select(mark_id);up();
   }
   _delete_selection(mark_id);
   _free_selection(mark_id);
}
/**
 * Deletes section specified from current buffer.  The start of a
 * section is identified by a section name in square brackets.  All lines until
 * the next section or end of file are deleted.
 *
 * @return Returns 0 if successful.
 *
 * @categories Miscellaneous_Functions
 *
 */
int _ini_delete_section2(_str section_name)
{
   int status=_ini_find_section(section_name);
   if (status) {
      return(status);
   }
   _ini_delete_section3(1);
   return(_save_config_file());
}

static int _ini_get_value2(_str section_name, _str  field_name, _str &result,
                           _str DefaultValue='', boolean DoFindSection=true,
                           _str case_option=null)
{
   if (DoFindSection) {
      if (_ini_find_section(section_name)) {
         result=DefaultValue;
         return(1);  // String not found in section
      }
   }
   _end_line();
   save_search(auto a,auto b,auto c,auto d);
   int status=search('^('_escape_re_chars(field_name)'=|\[)', 'rh@'(case_option==null?'i':case_option));
   restore_search(a,b,c,d);
   if (status) {
      result=DefaultValue;
      return(STRING_NOT_FOUND_RC);
   }
   _str line="";
   get_line(line);
   if (substr(line,1,1)=='[') {
      result=DefaultValue;
      return(STRING_NOT_FOUND_RC);
   }
   parse line with section_name'='result;
   return(0);
}

/**
 * After a call to _ini_find_section, this function is called to
 * parse each <i>field_name</i>=<i>value</i> line in the section.
 *
 * @return A non-zero value is returned when the end of the section is reached.
 *
 * <pre>
 *    ".ini" File Syntax:
 *          [<i>section1</i>]
 *          <i>field_name1</i>=<i>value1</i>
 *          <i>field_name2=value2</i>
 *          ...
 *          [<i>section2</i>]
 *          <i>field_name1=value1</i>
 *          field_name2=<i>value2</i>
 *          ...
 * </pre>
 *
 * @categories File_Functions, Miscellaneous_Functions
 *
 */
int _ini_parse_line(int ini_view, _str &field_name, _str &info, int first=0)
{
/*  ini_view is a view of an ini file. */
/*  the name of the field in the current line is returned in field name */
/*  the value of the field at the current line is returned in info */

   int view_id=0;
   get_window_id(view_id);
   activate_window(ini_view);
   if (first==1) {
      top();up();
   }
   if (down()) {
      if (p_window_id==view_id) view_id=0;
      _delete_temp_view();
      if(view_id) activate_window(view_id);
      return(1);
   }
   _str line="";
   get_line(line);
   parse line with field_name '=' info;
   activate_window(view_id);
   return(0);
}

/**
 * Place cursor on start of section specified in current buffer.
 * Search for section starts from the beginning of the buffer.  The start of a
 * section is identified by a section name in square brackets.
 *
 * @return Returns 0 if successful.
 *
 * @categories Miscellaneous_Functions
 *
 */
int _ini_find_section(_str section_name)
{
   // Note: we don't start searching from top here so that
   // we can use this function to find the start of the
   // next section (section_name=="").
   /* Searches for [section_name] at the begining of a line in the current buffer */
   /* If no search string is specifed, just finds the next section */
   section_name=_escape_re_chars(section_name);
   if (section_name!='') {
      top();up();
   }
   _str search_string="";
   if (section_name=='') {
      search_string='^\[';
   }else{
      search_string='^\['section_name'\]?@$';
   }
   save_search(auto a,auto b,auto c,auto d);
   int status=search(search_string,'rih@');
   restore_search(a,b,c,d);
   return(status);
}

/**
 * @return Returns 0 if successful.
 *
 * Creates a buffer and view in list box format of all section names
 * in square brackets in <i>filename</i>.
 *
 * <pre>
 *      ".ini" File Syntax:
 *          [<i>section1</i>]
 *          <i>field_name1</i>=<i>value1</i>
 *          <i>field_name2=value2</i>
 *          ...
 *          [<i>section2</i>]
 *          <i>field_name1=value1</i>
 *          field_name2=<i>value2</i>
 *          ...
 * </pre>
 *
 * @categories File_Functions, Miscellaneous_Functions
 *
 */
int _ini_list_sections(_str filename)
{
   /* Operates on a listbox */
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename,ini_view_id,view_id);
   if (status) return(status);
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(ini_view_id);
   _ini_list_sections2(view_id);
   activate_window(orig_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(0);
}

/**
 * 11:35am 6/1/2000
 * Dan added this function so that we can get a list of ini sections
 * in an array
 *
 * @param filename Name of the ini file.
 *
 * @param List     Array to return section names in
 *
 * @return returns 0 if successful.  Otherwise probably
 *         FILE_NOT_FOUND_RC, or STRING_NOT_FOUND_RC.
 *
 * @categories File_Functions, Miscellaneous_Functions
 *
 */
int _ini_get_sections_list(_str filename,_str (&List)[],_str Prefix='')
{
   int ini_view_id=0;
   int view_id=0;
   int status=_open_temp_view(filename,ini_view_id,view_id);
   if (status) return(status);
   int orig_view_id=0;
   get_window_id(orig_view_id);
   activate_window(ini_view_id);
   _ini_list_sections2(0,Prefix,List);
   activate_window(orig_view_id);
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(0);
}

static void _ini_list_sections2(int lb_view_id,_str Prefix='',_str (&List)[]=null)
{
   List._makeempty();
   top();
   int status=0;
   int ini_view=0;
   get_window_id(ini_view);
   save_search(auto a,auto b,auto c,auto d);
   while (!status) {
      status=search('^\[','rh@');
      if (!status) {
         _str line="";
         get_line(line);
         _str name="";
         parse line with '[' name ']';
         if (name != '') {
            //11:35am 6/1/2000
            //Putting in a couple of changes here so I can return an array
            //with all the section names
            if (Prefix=='' ||
                strieq(substr(name,1,length(Prefix)),Prefix)) {
               if (lb_view_id) {
                  activate_window(lb_view_id);
                  _lbadd_item(name);
                  activate_window(ini_view);
               }else {
                  List[List._length()]=name;
               }
            }
         }
         if (down()) break;
      }
   }
   restore_search(a,b,c,d);
}
boolean _isfile_loaded(_str filename)
{
   return(buf_match(absolute(filename),1,'hx')!='' );
}
int _ini_append_section(_str filename,_str section_name, _str new_string,_str ignorecase /* 'I' or '' */)
{
   int orig_view_id = p_window_id;                                    //Switch to list buffer
   int listviewid = 0;
   int status =_ini_get_section(filename,section_name,listviewid);
   if (status) {
      if (status!=STRING_NOT_FOUND_RC) {
         return(status);
      }
      orig_view_id = p_window_id;                                      //Switch to list buffer
      _create_temp_view(listviewid);
      p_UTF8=_load_option_UTF8(filename);
      p_window_id = orig_view_id;                                      //Switch views
   }
   p_window_id = listviewid;                                           //Place temp View into focus
   if(!(search('^'_escape_re_chars(new_string)'$','rh@'ignorecase))){
      return(0);
   }

   bottom();                                                         //Move to the bottom of the buffer
   insert_line(new_string);                                          //Insert new material
   p_window_id = orig_view_id;                                         //Switch views
   status = _ini_put_section(filename,section_name,listviewid); //Insert new list into file
   return (status);
}

int _ini_duplicate_section(_str filename,_str orig_section_name,_str new_section_name)
{
   int temp_view_id=0;
   int status=_ini_get_section(filename,orig_section_name,temp_view_id);
   if (status) {
      return(status);
   }
   status=_ini_put_section(filename,new_section_name,temp_view_id);
   return(status);
}

/**
 * This is simply a wrapper for _ini_get_value() that supports
 * expanding the 'copy_from' value in the prjpacks file
 *
 * @categories File_Functions, Miscellaneous_Functions
 *
 */
int _ini_get_value_expand_copy_from(_str filename, _str section_name, _str field_name,
                                    _str& result, _str default_value="")
{
   _str current_section = section_name;

   // first try just passing the call and check for failure
   int status = _ini_get_value(filename, current_section, field_name, result, default_value);

   while(status == STRING_NOT_FOUND_RC) {
      // if string not found, check for copy-from
      _str copy_from_section = "";
      status = _ini_get_value(filename, current_section, "copy_from", copy_from_section);
      if(status) return status;

      // remember which section currently in
      current_section = copy_from_section;

      // try to get the value from the copy-from section
      status = _ini_get_value(filename, current_section, field_name, result, default_value);
   }

   return status;
}

boolean _ini_is_valid(_str filename)
{
   int orig_view_id;
   int temp_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if (!status) {
      top();
      status=search('[\[<]','rh@');
      _str ch=get_text();
      if (!status && ch=='[') {
         /*
            This happens when...
               * Open 8.0 project in 7.0
               * Open trashed project in 8.0

            This will indicate that this project is trashed.  Resulting user
            error message could be better.
         */
         if (!search('^<!DOCTYPE ','reh@')) {
            status=1;
         }
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      // IF this file has not been converted yet.
      if (status || ch!='[') {
         return(false);
      }
      return(true);
   }
   return(false);
}

/**
 * Combines a pair of ini files by appending the contents of file2 to file1.  If 
 * any section names are used in both file1 and file2, then the contents of the 
 * sections in file2 will be used. 
 * 
 * @param file1         
 * @param file2 
 * 
 * @return              0 if success, error code otherwise
 */
int _ini_combine_files(_str file1, _str file2)
{
   // get all the sections from the second view
   _str sections[];
   _ini_get_sections_list(file2, sections);

   origWid := 0;
   iniView := 0;
   status := _open_temp_view(file1, iniView, origWid);
   if (status) return status;

   // now we delete each of these sections in the first file
   foreach (auto sectionName in sections) {
      // if we find it, delete it
      if (!_ini_find_section(sectionName)) {
         _ini_delete_section3(true);
      }
   }

   // now that we've deleted all the duplicated sections, just append the
   // second file to the first file
   bottom();
   status = get(file2, 'B');

   // now close her up
   status = save();

   _delete_temp_view(iniView);
   activate_window(origWid);

   return status;
}
