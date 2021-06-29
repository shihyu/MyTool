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
#include "cbrowser.sh"
#import "cjava.e"
#import "compile.e"
#import "debug.e"
#import "extern.e"
#import "gnucopts.e"
#import "help.e"
#import "ini.e"
#import "makefile.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "optionsxml.e"
#import "os2cmds.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbfind.e"
#import "toolbar.e"
#import "wkspace.e"
#import "tbcmds.e"
#endregion
//#include "xcode.sh"   coming soon to an editor near you

// comments in this file use the following convention:
//    (Xcode name)/(SlickEdit name)
//
// with the most common uses as follows:
//    project/workspace
//    target/project
//    configuration/target

/**
 * holds the whole project file
 */
static typeless xcode_idHash;
/**
 * pointer to xcode_idHash:['objects']
 */
static typeless *xcode_objects=0;
/**
 * the name of the file that is loaded in xcode_idHash and xcode_objects
 */
static _str xcode_project_file='';
/**
 * the base directory for files with relative paths
 */
static _str xcode_project_path='';

static _str objVersion = 39;
/**
 * similar to _nextel but will return the indices in alphabetical order
 *
 * @param idHash the hash table to travers
 * @param index the last index or '' to get the first index
 * @param returnHidden if true, this function will return indicies that start with #
 *
 * @return the next index or '' if there are no more indices
 */
static _str nextSortedEl(typeless & idHash,_str index,bool returnHidden)
{
   next_index := "";
   _str test_index;
   _str comp_index;
   next_has_quotes := false;
   comp_has_quotes := false;

   index=strip(index,'B','"');

   for (test_index._makeempty();;) {
      idHash._nextel(test_index);
      if (test_index._isempty()) break;
      if ((!returnHidden)&&(_first_char(test_index):=='#')) continue;

      comp_index=strip(test_index,'B','"');
      comp_has_quotes=(comp_index:!=test_index);

      if (comp_index > index) {
         if ((next_index=='') || (next_index > comp_index)) {
            next_index=comp_index;
            next_has_quotes=comp_has_quotes;
         }
      }
   }

   if (next_has_quotes) {
      return '"'next_index'"';
   }
   return next_index;
}

/**
 * Gets the name of the project/workspace from the filename.
 *
 * //NEEDED - see if it is possible to change the name of the
 * rootObject::mainGroup to be anything other than the project
 * name.  Also check what happens if the file is renamed.  I may
 * need to update this function base on the results
 *
 * @return the project/workspace name
 */
static _str xcode_get_project_name()
{
   output := _strip_filename(xcode_project_file,'N');
   _maybe_strip_filesep(output);
   return _strip_filename(output,'PE');
}

/**
 * Determine the target CPU architecture from the buildSettings<br>
 * <br>
 * The ARCHS options is usually set in the target buildSettings, but
 * probably could be in any buildSettings object.  This function will
 * work with any of them
 *
 * @param buildSettings the buildSettings object to examine
 * @return the architecture - only ppc and i386 are supported by gcc3.3
 */
static _str xcode_get_architecture(typeless * buildSettings)
{
   typeless * ARCHS=buildSettings->_indexin('ARCHS');
   if (!ARCHS || ARCHS->_varformat()!=VF_LSTR) {
      return 'ppc';
   }

   return (*ARCHS);
}

static _str xcode_get_output_dir(_str target_name)
{
   typeless build_settings;
   xcode_get_build_settings(target_name,_strip_filename(xcode_project_file,'N'):+target_name:+PRJ_FILE_EXT,build_settings);
   
   typeless * symRoot = build_settings._indexin('SYMROOT');
   if (!symRoot || symRoot->_varformat()!=VF_LSTR) {
      // xcode_get_build_settings should generate a default SYMROOT if there isn't one
      // so something has gone wrong
      return '';
   }

   output_dir := strip(*symRoot,'B','"');
   if (output_dir:!='') {
      _maybe_append_filesep(output_dir);
   }

   return output_dir;
}

/**
 * Determines a filename for an object id.
 *
 * @param id the object id to translate
 *
 * @return an absolute filename of '' if the object id is not recognized
 */
static _str idHashTranslateAbsoluteFile(_str id,_str target_name,_str & file_id=null)
{
   if (!xcode_objects) {
      return '';
   }

   // is the object id defined at all
   typeless * object_block=xcode_objects->_indexin(id);
   if (object_block && object_block->_varformat()==VF_HASHTAB) {
      // does it have a path?
      typeless * path=object_block->_indexin('path');
      if (path && path->_varformat()==VF_LSTR) {
         path_string := strip(*path,'B','"');

         path_type := "";
         typeless * sourceTree=object_block->_indexin('sourceTree');
         if (sourceTree && sourceTree->_varformat()==VF_LSTR) {
            path_type=(*sourceTree);
         } else {
            path_type='"<absolute>"';
         }

         switch (path_type) {
         case '"<absolute>"':
            path_string=strip(path_string,'B','"');
            break;
         case 'BUILT_PRODUCTS_DIR':
            path_string=xcode_get_output_dir(target_name):+strip(path_string,'B','"');
//            break; The result should be relative to the project directory
         case '"<group>"':
         default:
            typeless * parent_id=object_block->_indexin('#parent');
            if (_first_char(path_string):==FILESEP || !parent_id || parent_id->_varformat()!=VF_LSTR || (*parent_id):=='') {
               path_string=strip(absolute(path_string,xcode_project_path),'B','"');
            } else {
               _str parent_path=idHashTranslateAbsoluteFile(*parent_id,target_name,file_id);
               _maybe_append_filesep(parent_path);
               while (substr(path_string,1,3):==('..':+FILESEP)) {
                  path_string=substr(path_string,4);
                  parent_path=substr(parent_path,1,length(parent_path)-1);
                  parent_path=_strip_filename(parent_path,'N');
               }
               path_string=parent_path:+path_string;
            }
            break;
         }

         return path_string;
      }

      // it's not a file, is it a file reference?
      typeless * fileRef=object_block->_indexin('fileRef');
      if (fileRef && fileRef->_varformat()==VF_LSTR) {
         if (file_id!=null) {
            file_id=*fileRef;
         }
         return idHashTranslateAbsoluteFile(*fileRef,target_name,file_id);
      }

      // It's a group (possibly mainGroup)
      return xcode_project_path;
   }

   return '';
}

/**
 * get the display name for an object from the object id.
 *
 * @param id the id to translate
 *
 * @return '' if id could not be found
 */
static _str idHashTranslate(_str id)
{
   if (!xcode_objects) {
      return '';
   }

   typeless * object_block=xcode_objects->_indexin(id);
   if (object_block && object_block->_varformat()==VF_HASHTAB) {
      typeless * name=object_block->_indexin('name');
      if (name && name->_varformat()==VF_LSTR) {
         return (*name);
      }
      typeless * fileRef=object_block->_indexin('fileRef');
      if (fileRef && fileRef->_varformat()==VF_LSTR) {
         return idHashTranslate(*fileRef);
      }
   }

   return '';
}

/**
 * DEBUGGING ONLY: get the display name for an object from the object id<br>
 * <br>
 * NOTE1: an asterix(*) will be prepended if the object id is defined, but no
 * name could be determined<br>
 * <br>
 * NOTE2: information about the name will be appended (e.g. (ref) )
 *
 * @param id the id of the object
 * @param suffix text that will be appeneded to the name
 *
 * @return the display name for the object
 */
static _str idHashTranslateDebug(_str id,_str suffix='')
{
   if (!xcode_objects) {
      return id;
   }

   typeless * object_block=xcode_objects->_indexin(id);
   if (object_block && object_block->_varformat()==VF_HASHTAB) {
      typeless * name=object_block->_indexin('name');
      if (name && name->_varformat()==VF_LSTR) {
         return (*name):+suffix'(name)('id')';
      }
      typeless * path=object_block->_indexin('path');
      if (path && path->_varformat()==VF_LSTR) {
         return (*path):+suffix'(path)('id')';
      }
      typeless * fileRef=object_block->_indexin('fileRef');
      if (fileRef && fileRef->_varformat()==VF_LSTR) {
         return idHashTranslateDebug(*fileRef,'(ref)');
      }

      // mark that the id is recognized, but no name could be determined
      return '*'id:+suffix;
   }

   return id:+suffix;
}

/**
 * Reads text from the project file until <b>terminating_char</b> is found
 *
 * @return all text from the current line until the terminating_char
 */
static _str xcode_get_text(_str terminating_char)
{
   // this function does not handle the first line the same way as
   // subsequent lines to match how Xcode handles whitespace
   _str line;
   get_line(auto output);
   output=xcode_strip42(output);
   
   foundEnd := (_last_char(output):==terminating_char);
   if (foundEnd) {
      return substr(output,1,length(output)-1);
   }

   while (!foundEnd) {
      down();
      get_line(line);
      line=xcode_strip42(line);
      foundEnd=(_last_char(line):==terminating_char);
      if (foundEnd) {
         line=substr(line,1,length(line)-1);
      }
      strappend(output,"\n");
      strappend(output, line);
   }

   return output;
}

/**
 * Parses an array from an xcode file and inserts it into the array
 *
 * @param idHash either xcode_idHash, or some part of it
 */
static void xcode_parse_array(typeless &idArray)
{
   _str line;

   while (!down()) {
      get_line(line);
      line=xcode_strip42(line);
      
      // end of array?
      if (_first_char(line):==')') {
         return;
      }

      // comment? something probably went wrong
      if (substr(line,1,2):=='//') {
         continue;
      }

      // determine the index for the object/arrary/value
      index := idArray._length();
      // element is sub-object?
      if (line:=='{') {
         xcode_parse_object(idArray[index]);
         // force the element to be a hashtable in case the object is empty
         if (idArray[index]._isempty()) {
            idArray[index]:['']='';
            idArray[index]._deleteel('');
         }
      } else if (line:=='(') {
         xcode_parse_array(idArray[index]);
         // force the element to be an array in case the object is empty
         if (idArray[index]._isempty()) {
            idArray[index]='';
            idArray._deleteel(0);
         }
      } else {
         idArray[index]=strip(xcode_get_text(','));
      }
   }
}

/**
 * Determines if xcode_idHash includes a mark for a readable version
 *
 * @return true on error
 */
static bool xcode_check_archive_version()
{
   ret_value := false;
   version := 100;

   typeless * archiveVersion=xcode_idHash._indexin('archiveVersion');
   if (!archiveVersion || archiveVersion->_varformat()!=VF_LSTR) {
      ret_value=true;
   } else {
      _str version_str=(*archiveVersion);
      ret_value=version_str:!='1';
      if (isnumber(version_str)) {
         version=(int)version_str;
      }
   }


   if (ret_value) {
      if (version<1) {
         // This isn't likely, but if we ever support another version, the code is here
         _message_box("The version of this file is not supported.\n\nOpening this project in Xcode may update the file to a supported version.");
      } else {
         _message_box('The version of this file is not supported.');
      }
   }

   return ret_value;
}

/**
 * Determines if xcode_idHash includes a mark for a readable version
 *
 * @return true on error
 */
static bool xcode_check_object_version()
{
   ret_value := false;
   version := 100;

   typeless * objectVersion=xcode_idHash._indexin('objectVersion');
   if (!objectVersion || objectVersion->_varformat()!=VF_LSTR) {
      ret_value=true;
   } else {
      _str version_str=(*objectVersion);
      //objectVersion is 39 for Xcode 2.0
      //objectVersion is 42 for Xcode 2.1
      //objectVersion is 44 for Xcode 3.0
      //objectVersion is 45 for Xcode 3.1
      //objectVersion is 46 for Xcode 4.1
      objVersion = version_str;
      ret_value = (version_str:!='39' &&
                   version_str:!='42' &&
                   version_str:!='44' &&
                   version_str:!='45' &&
                   version_str:!='46');
      if (isnumber(version_str)) {
         version=(int)version_str;
      }
   }


   if (ret_value) {
      if (version<39) {
         _message_box("The version of this file is not supported.\n\nOpening this project in Xcode may update the file to a supported version.");
      } else {
         _message_box('The version of this file is not supported.');
      }
   }

   return ret_value;
}

/**
 * remove c-style comments -- does not handle comments that span multiple lines
 * 
 * @param lineIn a line to remove c-style comments from
 * 
 * @return the line with comments removed
 */
static _str xcode_strip42 (_str lineIn)
{
   commentOpenPos := 0;
   commentClosePos := 0;
   tempLine1 := "";
   _str tempLine2 = lineIn;
   do {
      commentOpenPos = pos("/*", lineIn);
      tempLine1 :+= substr(lineIn, 1, commentOpenPos - 1);
      commentClosePos = pos("*/", lineIn);
      lineIn = substr(lineIn, commentClosePos + 2);
   } while (commentOpenPos);
   return strip(tempLine1);
}
/**
 * Parses an array from an xcode file, that has been crammed onto a single line,
 * and inserts it into the array. This will not handle any objects or arrays
 * that are nested in the array.
 * 
 * @param idArray some part of it of xcode_idHash
 * @param arrayLine te line the array is on.
 */
static void xcode_parse_one_line_array(typeless &idArray, _str arrayLine)
{
   remainder := "";
   id := "";
   value := "";
   index := 0;
   parse arrayLine with id "= (" remainder ")" .;
   id = strip(id);
   remainder = strip(remainder);
   if (idArray:[id]._isempty()) {
      idArray:[id][0]='';
      idArray:[id]._deleteel(0);
   }
   while (length(remainder)) {
      parse remainder with value "," remainder;
      index = idArray:[id]._length();
      idArray:[id][index] = strip(value);
   }
}
/**
 * Parses an object from an xcode file, that has been crammed onto a single
 * line, and inserts it into the hash.
 * 
 * @param idHash either xcode_idHash, or some part of it
 * @param objectLine the line the object is on.
 */
static void xcode_parse_one_line_object(typeless &idHash, _str objectLine)
{
   remainder := "";
   attribute := "";
   value := "";
   id := "";
   parse objectLine with id "= {" remainder;
   id = strip(id);
   // force the element to be a hashtable in case the object is empty
   if (idHash:[id]._isempty()) {
      idHash:[id]:['']='';
      idHash:[id]._deleteel('');
   }
   remainder = strip(substr(remainder, 1, length(remainder)-2)); //cut off "};"
   while (length(remainder)) {
      parse remainder with attribute "=" value ";" remainder;
      attribute = strip(attribute);
      value = strip(value);
      if (_first_char(value):=="{") {
         xcode_parse_one_line_object(idHash:[id], attribute" = "value";};");
      } else if (_first_char(value):=="(") {
         xcode_parse_one_line_array(idHash:[id], attribute" = "value);
      } else if (attribute:!="};") {
         idHash:[id]:[attribute] = value;
      }
   }
}
/**
 * Parses one object from an xcode file and inserts it into the hash
 *
 * @param idHash either xcode_idHash, or some part of it
 *
 * @return true if the version number is not correct or if another error occured
 */
static bool xcode_parse_object(typeless &idHash)
{
   _str line;
   _str id;

   // xcode_maybe_open_project could be reworked to check
   // version numbers before calling this function, but
   // it does not complicate things too much to have the
   // checks here.  If this functions grows significantly,
   // the checks should be moved out.
   needs_archive_validation := (&idHash==&xcode_idHash);
   needs_object_validation := false;

   while (!down()) {
      get_line(line);
      line=xcode_strip42(line);
      
      // end of object?
      if (_first_char(line):=='}') {
         return false;
      }

      // comment?
      if (substr(line,1,2):=='//') {
         continue;
      }

      // blank line?
      if (length(line) == 0) {
         continue;
      }

      // attribute is sub-object?
      if (_last_char(line):=='{') {
         if (needs_archive_validation) {
            if (xcode_check_archive_version()) {
               return true;
            }
            needs_archive_validation=false;
            needs_object_validation=true;
         }

         parse line with id '=' .;
         id=strip(id);
         if (needs_object_validation && id=='objects') {
            if (xcode_check_object_version()) {
               return true;
            }
            needs_object_validation=false;
         }
         xcode_parse_object(idHash:[id]);
         // force the element to be a hashtable in case the object is empty
         if (idHash:[id]._isempty()) {
            idHash:[id]:['']='';
            idHash:[id]._deleteel('');
         }
      } else if (_last_char(line):=='(') {
         parse line with id '=' .;
         id=strip(id);
         xcode_parse_array(idHash:[id]);
         // force the element to be an array in case the object is empty
         if (idHash:[id]._isempty()) {
            idHash:[id][0]='';
            idHash:[id]._deleteel(0);
         }
      } else if (substr(line, length(line)-1, 2):=="};") { // objectVersion > 42 mashed-together line?
         xcode_parse_one_line_object(idHash, line);
      } else {
         // just a simple attribute...
         line=xcode_get_text(';');
         parse line with id '=' line;
         id=strip(id);
         idHash:[id]=strip(line);
      }
   }

   return false;
}

/**
 * DEBUG ONLY:  insert either some section of xcode_idHash into the current
 * buffer with translated ids
 *
 * @param idArray the array to display
 * @param indent the current level of indentation
 */
static void translate_array(typeless & idArray, _str indent='')
{
   if (idArray._varformat()!=VF_ARRAY) {
      insert_line(indent'!! object is not an array ('idArray._varformat()')');
      return;
   }

   int index;
   for (index=0;index<idArray._length();++index) {
      // is this a sub-object?
      if (idArray[index]._varformat()==VF_HASHTAB) {
         // log the index
         insert_line(indent'('index')');
         // and recurse
         translate_hash(idArray[index],indent'   ');
      } else if (idArray[index]._varformat()==VF_ARRAY) {
         // log the index
         insert_line(indent'('index')');
         // and recurse
         translate_array(idArray[index],indent'   ');
      } else {
         // value
         insert_line(indent'('index') 'idHashTranslateDebug(idArray[index]));
      }
   }
}

/**
 * DEBUG ONLY:  insert either xcode_idHash or some section of it into the current
 * buffer with translated ids
 *
 * @param idHash the hash table to display
 * @param indent the current level of indentation
 */
static void translate_hash(typeless & idHash, _str indent='')
{
   if (idHash._varformat()!=VF_HASHTAB) {
      insert_line(indent'!! object is not a hash table ('idHash._varformat()')');
      return;
   }

   index := "";
   for (;;) {
      index=nextSortedEl(idHash,index,true);

      if (index:=='') break;

      // is this a sub-object?
      if (idHash:[index]._varformat()==VF_HASHTAB) {
         // log the name
         insert_line(indent:+idHashTranslateDebug(index)' =');
         // and recurse
         translate_hash(idHash:[index],indent'   ');
      } else if (idHash:[index]._varformat()==VF_ARRAY) {
         // log the name
         insert_line(indent:+idHashTranslateDebug(index)' =');
         // and recurse
         translate_array(idHash:[index],indent'   ');
      } else {
         // attribute
         insert_line(indent:+index' = 'idHashTranslateDebug(idHash:[index]));
      }
   }
}

/**
 * DEBUG ONLY: displays the entire hash table with translated ids in a
 * _showbuf window
 */
static void showHash(typeless & idHash)
{
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);

   if (!orig_view_id) {
      message('error creating temp view');
      return;
   }

   translate_hash(idHash);

   _showbuf(temp_view_id,true);

   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
}

/**
 * used by {@link xcode_recreate_object} to insert the comments inside of
 * the main object list
 *
 * @param index the object id of the object that is about to be added to the file
 * @param previous_index the object id of the last object added to the file
 */
static void xcode_handle_labels(_str index, _str previous_index)
{
   // this function might be more complicated if I knew why the comments
   // were put there and if they mean anything
   //
   // maybe they are just used to speed up searching the file???
   index=substr(index,1,2);
   previous_index=substr(previous_index,1,2);

   if (previous_index:=='  ' || index:=='  ' || index:==previous_index) {
      return;
   }

   insert_line('//'previous_index'0');
   insert_line('//'previous_index'1');
   insert_line('//'previous_index'2');
   insert_line('//'previous_index'3');
   insert_line('//'previous_index'4');

   insert_line('//'index'0');
   insert_line('//'index'1');
   insert_line('//'index'2');
   insert_line('//'index'3');
   insert_line('//'index'4');
}

/**
 * this function generates a section of the xcode project.pbxproj file
 *
 * @param idHash xcode_idHash or the section of it to generate
 * @param indent the current level of indention
 */
static void xcode_recreate_array(typeless & idArray,_str indent)
{
   if (idArray._varformat()!=VF_ARRAY) {
      return;
   }

   int index;

   for (index=0;index<idArray._length();++index) {
      // is sub-object?
      if (idArray[index]._varformat()==VF_HASHTAB) {
         insert_line(indent'{');
         xcode_recreate_object(idArray[index],indent"\t");
         insert_line(indent'},');
      } else if (idArray[index]._varformat()==VF_ARRAY) {
         // is an array
         insert_line(indent'(');
         xcode_recreate_array(idArray[index],indent"\t");
         insert_line(indent'),');
      } else {
         // simple value
         if (idArray[index]:!='') { // band-aid, somehow empty array items are being added
            insert_line(indent:+idArray[index]',');
         }
      }
   }
}

/**
 * this function generates a section of the xcode project.pbxproj file
 *
 * @param idHash xcode_idHash or the section of it to generate
 * @param indent the current level of indention
 */
static void xcode_recreate_object(typeless & idHash,_str indent="\t")
{
   if (idHash._varformat()!=VF_HASHTAB) {
      insert_line(indent'something bad happened('idHash._varformat()')');
      return;
   }

   // when generating the main objects list, comments separating the object
   // ids must be inserted
   isObjects := (xcode_objects==&idHash);

   index := "";
   _str previous_index;

   for (;;) {
      previous_index=index;
      index=nextSortedEl(idHash,index,false);

      if ((isObjects) && (objVersion:=='39')) {
         xcode_handle_labels(index,previous_index);
      }

      if (index:=='') break;

      // is sub-object?
      if (idHash:[index]._varformat()==VF_HASHTAB) {
         // put name
         insert_line(indent:+index' = {');
         // and recurse
         xcode_recreate_object(idHash:[index],indent"\t");
         insert_line(indent'};');
      } else if (idHash:[index]._varformat()==VF_ARRAY) {
         // is an array
         insert_line(indent:+index' = (');
         // and recurse
         xcode_recreate_array(idHash:[index],indent"\t");
         insert_line(indent');');
      } else {
         // simple attribute
         insert_line(indent:+index' = 'idHash:[index]';');
      }
   }
}

/**
 * writes xcode_idHash into the specified file
 *
 * @param filename the filename to use
 */
static void xcode_recreate_file(_str filename)
{
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);

   if (!orig_view_id) {
      return;
   }

   // insert the format identifier
   insert_line('// !$*UTF8*$!');
   insert_line('{');
   xcode_recreate_object(xcode_idHash);
   insert_line('}');

   p_buf_name=filename;
   // Xcode seems to use UNIX line endings
   _save_file('+FU');

   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
}

/**
 * creates a new object id based on an existing id
 *
 * @param id the existing id
 * @return the new id
 */
static _str make_new_id(_str id)
{
   _str result;
   eval_exp(result,'0x'id'+0x01',16);
   // removed the leading 0x
   result=substr(result,3);

   // add any leading zeros if needed
   id_length := length(id);
   result_length := length(result);

   if (id_length > result_length) {
      result=substr('',1,id_length-result_length,'0'):+result;
   }
   return result;
}

/**
 * generate a new object id
 *
 * @return an object id
 */
static _str xcode_find_available_id()
{
   if (!xcode_objects) {
      return '';
   }

   _str id;
   id._makeempty();
   xcode_objects->_nextel(id);
   if (id._isempty()) {
      // this really shouldn't ever happen
      return '080E96DDFE201D6D7F000001';   // chosen randomly from a test project
   }

   do {
      id=make_new_id(id);
   } while (xcode_objects->_indexin(id));

   return id;
}

/**
 * Determine if a file with the specified extension would be part
 * of the SourcesBuildPhase or the HeadersBuildPhase
 *
 * @param ext the extension to check
 * @return true for HeadersBuildPhase
 */
static bool xcode_is_header_ext(_str ext)
{
   return (ext:=='pch' || _first_char(ext):=='h');
}

/**
 * Save the current project/workspace into the pbxproj file
 */
static void xcode_save_project()
{
   xcode_recreate_file(xcode_project_file);
}

/**
 * Searches xcode_idHash for the rootObject
 *
 * @return a pointer to the rootObject in xcode_idHash or zero if it
 * is not found
 */
static typeless * xcode_find_root_object()
{
   typeless * root_object_id=xcode_idHash._indexin('rootObject');
   if (!root_object_id || root_object_id->_varformat()!=VF_LSTR) {
      return (null);
   }

   typeless * root_object=xcode_objects->_indexin(*root_object_id);
   if (!root_object || root_object->_varformat()!=VF_HASHTAB) {
      return (null);
   }

   return root_object;
}

/**
 * Searches xcode_idHash for the specified target
 *
 * @param target_name the name of the target to look for
 * @param root_object a pointer to the rootObject
 *
 * @return a pointer to the target object or zero if it could
 * not be found
 */
static typeless * xcode_find_target(_str target_name,typeless * root_object)
{
   if (!root_object) {
      return (null);
   }

   typeless * targets=root_object->_indexin('targets');
   if (!targets || targets->_varformat()!=VF_ARRAY) {
      return (null);
   }

   int target_index;
   for (target_index=0;target_index<targets->_length();++target_index) {
      if (target_name:==idHashTranslate((*targets)[target_index])) {
         break;
      }
   }

   if (target_index>=targets->_length()) {
      return(null);
   }

   typeless * target=xcode_objects->_indexin((*targets)[target_index]);
   if (!target || target->_varformat()!=VF_HASHTAB) {
      return (null);
   }

   return target;
}

/**
 * Searches xcode_idHash for the mainGroup
 *
 * @return a pointer to the mainGroup or zero if it could not be found
 */
static typeless * xcode_find_main_group(_str &id=null)
{
   typeless * root_object=xcode_find_root_object();
   if (!root_object) {
      return (null);
   }
   typeless * mainGroup_id=root_object->_indexin('mainGroup');
   if (!mainGroup_id || mainGroup_id->_varformat()!=VF_LSTR) {
      return (null);
   }
   typeless * mainGroup=xcode_objects->_indexin(*mainGroup_id);
   if (!mainGroup || mainGroup->_varformat()!=VF_HASHTAB) {
      return (null);
   }

   if (id!=null) {
      id=*mainGroup_id;
   }

   return mainGroup;
}

/**
 * Searchs the specified target for the build phase that holds files
 * with the specified extension
 *
 * @param target a pointer to the target object inside of xcode_idHash
 * @param ext the extension of the file
 *
 * @return a pointer to the buildPhase inside of xcode_idHash or
 * zero if it could not be found
 */
static typeless * xcode_find_build_phase(typeless * target,_str ext)
{
   typeless * buildPhases=target->_indexin('buildPhases');
   if (!buildPhases || buildPhases->_varformat()!=VF_ARRAY) {
      return (null);
   }

   typeless * source_phase;
   int phaseIndex;

   for (phaseIndex=0;phaseIndex<buildPhases->_length();++phaseIndex) {
      source_phase=xcode_objects->_indexin((*buildPhases)[phaseIndex]);
      if (!source_phase || source_phase->_varformat()!=VF_HASHTAB) {
         continue;
      }

      typeless * isa=source_phase->_indexin('isa');
      if (!isa || isa->_varformat()!=VF_LSTR) {
         continue;
      }

      if (xcode_is_header_ext(ext)) {
         if ((*isa):=='PBXHeadersBuildPhase') {
            return source_phase;
         }
      } else if ((*isa):=='PBXSourcesBuildPhase') {
         return source_phase;
      }
   }

   return (null);
}

static typeless * xcode_find_containing_folder(_str id,typeless * folder,int & index)
{
   if (!folder || folder->_varformat()!=VF_HASHTAB) {
      return null;
   }

   typeless * children = folder->_indexin('children');
   if (!children || children->_varformat()!=VF_ARRAY) {
      return null;
   }

   typeless * recurse_result;
   int child_index;
   for (child_index=0;child_index<children->_length();++child_index) {
      if (id:==(*children)[child_index]) {
         index=child_index;
         return folder;
      }
      recurse_result=xcode_find_containing_folder(id,xcode_objects->_indexin((*children)[child_index]),index);
      if (recurse_result) {
         return recurse_result;
      }
   }

   return null;
}

static typeless * xcode_find_style(_str style_name)
{
   typeless * root_object=xcode_find_root_object();
   if (!root_object) {
      return (null);
   }

   typeless * styles=root_object->_indexin('buildStyles');
   if (!styles || styles->_varformat()!=VF_ARRAY) {
      return (null);
   }

   int style_index;
   for (style_index=0;style_index<styles->_length();++style_index) {
      if (style_name:==idHashTranslate((*styles)[style_index])) {
         break;
      }
   }

   if (style_index>=styles->_length()) {
      return(null);
   }

   typeless * style=xcode_objects->_indexin((*styles)[style_index]);
   if (!style || style->_varformat()!=VF_HASHTAB) {
      return (null);
   }

   return style;
}

static typeless * xcode_find_file_in_phase(_str file_name,_str target_name,typeless * phase)
{
   typeless * files=phase->_indexin('files');
   if (!files || files->_varformat()!=VF_ARRAY) {
      return (null);
   }

   int file_index;
   _str file_ref_id;
   _str file_id;

   for (file_index=0;file_index<files->_length();++file_index) {
      file_ref_id=(*files)[file_index];
      if (_file_eq(file_name,idHashTranslateAbsoluteFile(file_ref_id,target_name,file_id))) {
         break;
      }
   }

   if (file_index>=files->_length()) {
      return (null);
   }

   typeless * file=xcode_objects->_indexin(file_id);
   if (!file || file->_varformat()!=VF_HASHTAB) {
      return (null);
   }

   return file;
}

static typeless * xcode_find_file(_str file_name,_str target_name,typeless * target)
{
   typeless * phase=xcode_find_build_phase(target,_get_extension(file_name));

   typeless * file=null;

   if (phase) {
      file=xcode_find_file_in_phase(file_name,target_name,phase);
      if (!file) {
         phase=null;
      }
   }

   if (!phase) {
      // could not find file in sources or headers phase, or phase does not exist,
      // try the other one

      if (xcode_is_header_ext(_get_extension(file_name))) {
         phase=xcode_find_build_phase(target,'m');
      } else {
         phase=xcode_find_build_phase(target,'h');
      }

      if (phase) {
         file=xcode_find_file_in_phase(file_name,target_name,phase);
      }
   }

   return file;
}

/**
 * Adds a file to the Xcode project
 *
 * @param filename the file to add
 * @param projFile the name of the Xcode project (used to create relative file names)
 *
 * @return zero on success
 */
static int xcode_add_file(_str filename,_str target_name)
{
   // Xcode does not seem to look for duplicate files.  So if the
   // user adds the same file to multiple targets within a project
   // the full set of nodes in the project file is created.
   //
   // Since this is the behavior of Xcode, this function will do
   // the same.  If this function looked for duplicate files and
   // did not create new file nodes, Xcode might break if it opened
   // the project.
   if (!xcode_objects) {
      return (1);
   }

   filename=relative(filename,xcode_project_path);

   // add the file object
   _str file_id=xcode_find_available_id();

   (*xcode_objects):[file_id]:['fileEncoding']='30';
   // have to create the first element before this works
   typeless * file_object=xcode_objects->_indexin(file_id);
   
   (*file_object):['isa']='PBXFileReference';
   (*file_object):['lastKnownFileType']='sourcecode.c.';

   ext := lowcase(_get_extension(filename));
   if (ext:=='mm') {
      (*file_object):['lastKnownFileType']='sourcecode.c.objcpp';
   } else if (ext:=='m') {
      (*file_object):['lastKnownFileType']='sourcecode.c.objc';
   } else if (ext:=='java') {
      (*file_object):['lastKnownFileType']='sourcecode.java';
   } else {
      (*file_object):['lastKnownFileType']='sourcecode.c.'ext;
   }

   (*file_object):['path']=filename;
   (*file_object):['refType']='4'; //NEEDED what is this and does it ever change
   (*file_object):['sourceTree']='"<group>"';  // ditto

   // add the file reference object
   _str file_ref_id=xcode_find_available_id();

   (*xcode_objects):[file_ref_id]:['fileRef']=file_id;
   // have to create the first element before this works
   typeless * file_ref_object=xcode_objects->_indexin(file_ref_id);

   (*file_ref_object):['isa']='PBXBuildFile';
   (*file_ref_object):['settings']:['ATTRIBUTES'][0]='';

   // add the file to the sources tree
   typeless * mainGroup=xcode_find_main_group();
   if (!mainGroup) {
      return (1);
   }
   typeless * children=mainGroup->_indexin('children');
   if (!children || children->_varformat()!=VF_ARRAY) {
      return (1);
   }
   (*children)[children->_length()]=file_id;

   // add the fileRef to the BuildPhase
   typeless * target=xcode_find_target(target_name,xcode_find_root_object());
   if (!target) {
      return (1);
   }

   typeless * source_phase=xcode_find_build_phase(target,ext);
   if (!source_phase) {
      return (1);
   }

   typeless * files=source_phase->_indexin('files');
   if (!files || files->_varformat()!=VF_ARRAY) {
      return (1);
   }

   (*files)[files->_length()]=file_ref_id;
   return 0;
}

/**
 * Removes the specified file from the specified target in the
 * active project.
 *
 * @param filename the absolute name of the file to remove
 * @param target_name the target to remove the file from
 *
 * @return zero if succesful
 */
static int xcode_remove_file(_str filename, _str target_name)
{
   // Xcode does not seem to look for duplicate files when adding
   // a file to a target.  So if the user adds the same file to
   // multiple targets within a project the full set of nodes in
   // the project file is created.
   //
   // Therefore when removing the file, it is safe to start at
   // the target and remove everything that appears to be tied
   // to the file.  Any other projects that use the file will have
   // their own set of node which should not be affected in any
   // way by this function.

   ext := lowcase(_get_extension(filename));

   // find the target
   typeless * target=xcode_find_target(target_name,xcode_find_root_object());
   if (!target) {
      return (1);
   }

   // find the build phase
   typeless * build_phase=xcode_find_build_phase(target,ext);
   if (!build_phase) {
      return (1);
   }

   // find the file reference and file objects
   typeless * files=build_phase->_indexin('files');
   if (!files || files->_varformat()!=VF_ARRAY) {
      return (1);
   }

   int file_index;
   _str file_ref_id;

   for (file_index=0;file_index<files->_length();++file_index) {
      file_ref_id=(*files)[file_index];
      if (_file_eq(filename,idHashTranslateAbsoluteFile(file_ref_id,target_name))) {
         break;
      }
   }

   if (file_index>=files->_length()) {
      return (1);
   }

   typeless * file_ref=xcode_objects->_indexin(file_ref_id);
   // don't need to check the return value here because idHashTranslateAbsoluteFile already has

   if (!file_ref->_indexin('fileRef')) {
      // the build phase points directly to the file object?
      return (1);
   }

   _str file_id = (*file_ref):['fileRef'];

   // find the file in project source tree
   int folder_index;
   typeless * project_folder=xcode_find_containing_folder(file_id,xcode_find_main_group(),folder_index);
   if (!project_folder) {
      return (1);
   }

   typeless * folder_files=project_folder->_indexin('children');
   if (!folder_files || folder_files->_varformat()!=VF_ARRAY) {
      // how did xcode_find_containing_folder succeed?
      return (1);
   }

   // above here, nothing has been changed, just data collection
   // after here nothing should fail

   // delete the file object
   xcode_objects->_deleteel(file_id);

   // delete the file reference object
   xcode_objects->_deleteel(file_ref_id);

   // remove the file reference from the build phase
   files->_deleteel(file_index);

   // remove it from the project source tree
   folder_files->_deleteel(folder_index);

   return 0;
}

static void xcode_set_parents_recurse(typeless * group,_str group_id)
{
   typeless * children=group->_indexin('children');
   if (!children || children->_varformat()!=VF_ARRAY) {
      return;
   }

   int index;
   _str id;
   typeless * child;

   for (index=0;index<children->_length();++index) {
      id=children->_el(index);
      child=xcode_objects->_indexin(id);
      if (child && child->_varformat()==VF_HASHTAB) {
         (*child):['#parent']=group_id;
         xcode_set_parents_recurse(child,id);
      }
   }
}

/**
 * Reads the project file heirarchy and add hidden parent links to all file
 * and group nodes
 */
static bool xcode_set_parents()
{
   _str main_group_id;
   typeless * main_group=xcode_find_main_group(main_group_id);
   if (!main_group) {
      return true;
   }

   (*main_group):['#parent']='';

   xcode_set_parents_recurse(main_group,main_group_id);

   return false;
}

/**
 * Opens an Xcode project file if it is not already open and sets
 * the following global variables:
 * <ol>
 *    <li>xcode_idHash</li>
 *    <li>xcode_objects</li>
 *    <li>xcode_project_file</li>
 *    <li>xcode_project_path</li>
 * </ol>
 *
 * @param filename the name of the file to open.  This should be the
 * project.pbxproj and not the .xcode directory
 *
 * @return zero on success
 */
static int xcode_maybe_open_project(_str filename)
{
   if (_file_eq(filename,xcode_project_file)) {
      return 0;
   }

   xcode_close_project();

   xcode_project_file=filename;

   // first get rid of the actual project file name
   xcode_project_path=_strip_filename(xcode_project_file,'N');

   // now get rid of the '.xcode' file/directory name
   _maybe_strip_filesep(xcode_project_path);
   xcode_project_path=_strip_filename(xcode_project_path,'N');

   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);

   if (status) {
      xcode_project_file='';
      return 1;
   }

   top();
   up();

   _str ss_search_string;
   int ss_flags;
   _str ss_word_re;
   _str ss_reservedMore;
   int ss_flags2;

   save_search(ss_search_string, ss_flags, ss_word_re, ss_reservedMore, ss_flags2);

   search('{','@h');

   if (!xcode_parse_object(xcode_idHash)) {
      xcode_objects=xcode_idHash._indexin('objects');
   } else {
      return 1;
   }

   restore_search(ss_search_string, ss_flags, ss_word_re, ss_reservedMore, ss_flags2);

   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   if (!xcode_objects) {
      xcode_close_project();
      return 1;
   }

   if (xcode_set_parents()) {
      xcode_close_project();
      return 1;
   }

   return 0;
}

static void xcode_close_project()
{
   _XcodeProjectClosed();
   xcode_idHash._makeempty();
   xcode_objects=null;
   xcode_project_file='';
   xcode_project_path='';
}

/**
 * callback from workspace_close
 */
void _wkspace_close_xcode()
{
   xcode_close_project();
}

static void _xcode_check_subprojects(_str rootDir, _str (&project_bundle_dir)[], _str (&ProjectNames)[],_str (&VendorProjectNames)[])
{
   i := 0;
   for (i = 0; i < project_bundle_dir._length(); ++i) {
      _str XcodeProjBundleDir = project_bundle_dir[i];
      projectfile := absolute("project.pbxproj", XcodeProjBundleDir);
      _str projectName;
      if(!_GetXcodeProjectName(projectfile, projectName)){
         _str vpjName;
         _str vpjFullName;
         if (projectName:!='') {
            vpjName = _strip_filename(XcodeProjBundleDir, "N"):+VSEProjectFilename(projectName);
            ProjectNames[ProjectNames._length()] = relative(vpjName, rootDir);
            VendorProjectNames[VendorProjectNames._length()] = XcodeProjBundleDir;
            
            _str nestedProjects[];
            _GetXcodeProjectGetSubProjects(projectfile, nestedProjects);
            _xcode_check_subprojects(rootDir, nestedProjects, ProjectNames, VendorProjectNames);
         }
      }
   }
}

/**
 * Retrieves SlickEdit .vpj project names from an Xcode project 
 * bundle (.xcode or .xcodeproj extension) 
 * @param XcodeProjBundleDir Full path to the project.xcode 
 *                                or project.xcodeproj bundle
 *                                directory
 * @param ProjectNames Output to receive .vpj names
 * @param VendorProjectNames Output to receive Xcode project 
 *                           paths
 * 
 * @return int Zero (0) on success.
 */
int _xcode_project_get_vpj_names(_str XcodeProjBundleDir, _str (&ProjectNames)[],_str (&VendorProjectNames)[])
{
   rootDir := _strip_filename(XcodeProjBundleDir, "N");
   _str project_bundle_dir[];
   project_bundle_dir[0] = XcodeProjBundleDir;
   _xcode_check_subprojects(rootDir, project_bundle_dir, ProjectNames, VendorProjectNames);
   return 0;
}

/**
 * Retrieves SlickEdit .vpj project names from an Xcode 
 * workspace bundle (.xcworkspace extension) 
 * @param XcodeWorkspaceBundleDir Full path to the 
 *                                workspace.xcworkspace bundle
 *                                directory
 * @param ProjectNames Output to receive .vpj names
 * @param VendorProjectNames Output to receive Xcode project 
 *                           paths
 * 
 * @return int Zero (0) on success.
 */
int _xcode_workspace_get_vpj_names(_str XcodeWorkspaceBundleDir, _str (&ProjectNames)[],_str (&VendorProjectNames)[])
{
   // Create the full path to the contents.xcworkspacedata file. It's just XML...
   workspaceData := absolute("contents.xcworkspacedata", XcodeWorkspaceBundleDir);
   stat := 0;
   int wkHandle = _xmlcfg_open(workspaceData, stat);
   if(stat != 0) {
      return 1;
   }

   // The parent directory of the .xcworkspace bundle
   workspaceRootDir := _strip_filename(XcodeWorkspaceBundleDir, "N");

   // Get the Workspace/FileRef/@location values
   typeless projLocations[]; projLocations._makeempty();
   _xmlcfg_find_simple_array(wkHandle, "/Workspace/FileRef", projLocations);

   // Walk the list of file ref nodes, and get the location attributes
   int i;
   for (i=0;i<projLocations._length();++i) {
      _str loc = _xmlcfg_get_attribute(wkHandle,projLocations[i],"location");
      // Strip off "group:" prefix from the location value. This gives a path relative
      // to the workspace bundle directory.
      absoluteLoc := "";
      if(pos("group:", loc) == 1)
      {
         // Make the absolute path to the .xcodeproj directory
         relativeLoc := substr(loc, 7);
         absoluteLoc = absolute(relativeLoc, workspaceRootDir);
      } else if(pos("container:", loc) == 1) {
          relativeLoc := substr(loc, 11);
         absoluteLoc = absolute(relativeLoc, workspaceRootDir);
      }
      // TODO: What other prefixes besides "container:" and "group:" are possible?
      
      if(absoluteLoc != '') {
         _str project_bundle_dir[];
         project_bundle_dir[0] = absoluteLoc;
         _xcode_check_subprojects(workspaceRootDir, project_bundle_dir, ProjectNames, VendorProjectNames);
      }
   }
   _xmlcfg_close(wkHandle);
   return 0;
}

int _xcode_get_configs(_str VendorWorkspaceFilename, ProjectConfig (&configList)[])
{
   // Using new projsupp library method to return list of Configs, which are really formatted
   // "Config|Target", like Development|MyApplication or Deployment|HelperUtilLib or Debug|iPhoneApp
   // At some point, we may also introduce the SDK variant, so we'd have something
   // that looks like Debug|iPhoneApp|iphoneos3.0.3 (or maybe Debug|iphoneos3.0.3|iPhoneApp
   
   // First, get all the config strings (Config|Target)
   _str configStrings[];
   projectfile := absolute("project.pbxproj", VendorWorkspaceFilename);
 
   _GetXcodeProjectConfigurations(projectfile, configStrings);
  
   // Iterate, and create output ProjectConfig objects for each
   numConfigs := configStrings._length();
   if(numConfigs > 0) {
      int index;
      for (index=0; index < numConfigs; ++index) {
         configIndex := configList._length();
         configList[configIndex].config=configStrings[index];
         // Not using the obj directory. Yet.
         configList[configIndex].objdir= '';
      }
      return 0;
   }
   return -1;
}

int _xcode_update_files(int _srcfile_list_view_id,_str VendorWorkspaceFilename)
{
   _message_box("Modifying Xcode project files is disabled, and no changes will be written.\nUse Xcode to add/remove project files. ");
   return 1;
}

static _str xcode_make_object_file_name(_str buf_name,_str target_name,typeless & buildSettings)
{
   output := "";

   if (buildSettings._indexin('OBJROOT')) {
      output=buildSettings:['OBJROOT']:+FILESEP;
   }

   strappend(output,xcode_get_project_name());
   strappend(output,'.build');
   strappend(output,FILESEP);
   strappend(output,target_name);
   strappend(output,'.build');
   strappend(output,FILESEP);
   strappend(output,'Objects-');
   strappend(output,buildSettings:['BUILD_VARIANTS']);
   strappend(output,FILESEP);
   strappend(output,buildSettings:['ARCHS']);
   if (buf_name:!='') {
      strappend(output,FILESEP);
      strappend(output,_strip_filename(buf_name,'PE'));
      strappend(output,'.o');
   }

   return output;
}

static void xcode_group_build_settings(typeless & all_buildSettings,typeless * buildSettings)
{
   _str build_option_name;
   _str build_option_value;

   for (build_option_name._makeempty();;) {
      buildSettings->_nextel(build_option_name);
      if (build_option_name._isempty()) break;

      build_option_value=(*buildSettings):[build_option_name];
      all_buildSettings:[build_option_name]=build_option_value;
   }
}

static void xcode_process_build_settings(typeless & buildSettings,_str &compile_command)
{
   _str build_option_name;
   _str build_option_value;
   bool build_option_bool;
   for (build_option_name._makeempty();;) {
      buildSettings._nextel(build_option_name);
      if (build_option_name._isempty()) break;
      build_option_value=buildSettings:[build_option_name];
      build_option_bool=(upcase(build_option_value):=='YES');
      switch (build_option_name) {
      case 'ARCHS':
         strappend(compile_command,' -arch 'build_option_value);
         break;
      case 'COPY_PHASE_STRIP':
         //NEEDED
         break;
      case 'FRAMEWORK_SEARCH_PATHS':
         _str path;
         build_option_value=strip(build_option_value,'B','"');
         while (build_option_value!='') {
            parse build_option_value with path (PARSE_PATHSEP_RE),'r' build_option_value;
            strappend(compile_command,' ':+_maybe_quote_filename('-F':+path));
         }
         break;
      case 'GCC_ALTIVEC_EXTENSIONS':
         if (build_option_bool) {
            strappend(compile_command,' -faltivec');
         }
         break;
      case 'GCC_CHAR_IS_UNSIGNED_CHAR':
         if (build_option_bool) {
            strappend(compile_command,' -funsigned-char');
         }
         break;
      case 'GCC_CW_ASM_SYNTAX':
         if (build_option_bool) {
            strappend(compile_command,' -fasm-blocks');
         }
         break;
      case 'GCC_C_LANGUAGE_STANDARD':
         strappend(compile_command,' -std='build_option_value);
         break;
      case 'GCC_DYNAMIC_NO_PIC':
         //NEEDED
         break;
      case 'GCC_ENABLE_CPP_EXCEPTIONS':
         if (build_option_bool) {
            strappend(compile_command,' -fexceptions');
         } else {
            strappend(compile_command,' -fno-exceptions');
         }
         break;
      case 'GCC_ENABLE_CPP_RTTI':
         if (!build_option_bool) {
            strappend(compile_command,' -fno-rtti');
         }
         break;
      case 'GCC_ENABLE_FIX_AND_CONTINUE':
         if (build_option_bool) {
            strappend(compile_command,' -ffix-and-continue');
         }
         break;
      case 'GCC_ENABLE_OBJC_EXCEPTIONS':
         if (build_option_bool) {
            strappend(compile_command,' -fobjc-exceptions');
         }
         break;
      case 'GCC_ENABLE_PASCAL_STRINGS':
         if (build_option_bool) {
            strappend(compile_command,' -fpascal-strings');
         }
         break;
      case 'GCC_ENABLE_TRIGRAPHS':
         if (build_option_bool) {
            strappend(compile_command,' -trigraphs');
         } else {
            strappend(compile_command,'  -Wno-trigraphs');
         }
         break;
      case 'GCC_GENERATE_DEBUGGING_SYMBOLS':
         if (build_option_bool) {
            strappend(compile_command,' -g');
         }
         break;
      case 'GCC_MODEL_CPU':
         strappend(compile_command,' -mcpu='build_option_value);
         break;
      case 'GCC_MODEL_PPC64':
         if (build_option_bool) {
            strappend(compile_command,' -mpowerpc64');
         }
         break;
      case 'GCC_MODEL_TUNING':
         strappend(compile_command,' -mtune='build_option_value);
         break;
      case 'GCC_NO_COMMON_BLOCKS':
         if (build_option_bool) {
            strappend(compile_command,' -fno-common');
         }
         break;
      case 'GCC_NO_NIL_RECEIVERS':
         if (build_option_bool) {
            strappend(compile_command,' -fno-nil-receivers');
         }
         break;
      case 'GCC_OPTIMIZATION_LEVEL':
         strappend(compile_command,' -O':+build_option_value);
         break;
      case 'GCC_PREFIX_HEADER':
         strappend(compile_command,' -include 'absolute(build_option_value,xcode_project_path));
         break;
      case 'GCC_PREPROCESSOR_DEFINITIONS':
         build_option_value=strip(build_option_value,'B','"');
         while (build_option_value:!='') {
            strappend(compile_command,' -D'parse_next_option(build_option_value));
         }
         break;
      case 'GCC_REUSE_STRINGS':
         if (!build_option_bool) {
            strappend(compile_command,' -fwritable-strings');
         }
         break;
      case 'GCC_SHORT_ENUMS':
         if (build_option_bool) {
            strappend(compile_command,' -fshort-enums');
         }
         break;
      case 'GCC_SKIP_UNUSED_SOURCE':
         //NEEDED I have no idea what option this is supposed to be
         break;
      case 'GCC_TREAT_WARNINGS_AS_ERRORS':
         if (build_option_bool) {
            strappend(compile_command,' -Werror');
         }
         break;
      case 'GCC_WARN_ABOUT_MISSING_PROTOTYPES':
         if (build_option_bool) {
            strappend(compile_command,' -Wmissing-prototypes');
         }
         break;
      case 'GCC_WARN_ALLOW_INCOMPLETE_PROTOCOL':
         if (build_option_bool) {
            strappend(compile_command,' -Wprotocol');
         } else {
            strappend(compile_command,' -Wno-protocol');
         }
         break;
      case 'GCC_WARN_CHECK_SWITCH_STATEMENTS':
         if (build_option_bool) {
            strappend(compile_command,' -Wswitch');
         }
         break;
      case 'GCC_WARN_EFFECTIVE_CPLUSPLUS_VIOLATIONS':
         if (build_option_bool) {
            strappend(compile_command,' -Weffc++');
         }
         break;
      case 'GCC_WARN_FOUR_CHARACTER_CONSTANTS':
         if (!build_option_bool) {
            strappend(compile_command,' -Wno-multichar');
         }
         break;
      case 'GCC_WARN_HIDDEN_VIRTUAL_FUNCTIONS':
         if (build_option_bool) {
            strappend(compile_command,' -Woverloaded-virtual');
         }
         break;
      case 'GCC_WARN_INHIBIT_ALL_WARNINGS':
         if (build_option_bool) {
            strappend(compile_command,' -w');
         }
         break;
      case 'GCC_WARN_INITIALIZER_NOT_FULLY_BRACKETED':
         if (build_option_bool) {
            strappend(compile_command,' -Wmissing-braces');
         }
         break;
      case 'GCC_WARN_MISSING_PARENTHESES':
         if (build_option_bool) {
            strappend(compile_command,' -Wparentheses');
         }
         break;
      case 'GCC_WARN_NON_VIRTUAL_DESTRUCTOR':
         if (build_option_bool) {
            strappend(compile_command,' -Wnon-virtual-dtor');
         }
         break;
      case 'GCC_WARN_PEDANTIC':
         if (build_option_bool) {
            strappend(compile_command,' -pedantic');
         }
         break;
      case 'GCC_WARN_SHADOW':
         if (build_option_bool) {
            strappend(compile_command,' -Wshadow');
         }
         break;
      case 'GCC_WARN_SIGN_COMPARE':
         if (build_option_bool) {
            strappend(compile_command,' -Wsign-compare');
         }
         break;
      case 'GCC_WARN_TYPECHECK_CALLS_TO_PRINTF':
         if (build_option_bool) {
            strappend(compile_command,' -Wformat');
         }
         break;
      case 'GCC_WARN_UNINITIALIZED_AUTOS':
         if (build_option_bool) {
            strappend(compile_command,' -Wuninitialized');
         }
         break;
      case 'GCC_WARN_UNKNOWN_PRAGMAS':
         if (build_option_bool) {
            strappend(compile_command,' -Wunknown-pragmas');
         } else {
            strappend(compile_command,' -Wno-unknown-pragmas');
         }
         break;
      case 'GCC_WARN_UNUSED_FUNCTION':
         if (build_option_bool) {
            strappend(compile_command,' -Wunused-function');
         }
         break;
      case 'GCC_WARN_UNUSED_LABEL':
         if (build_option_bool) {
            strappend(compile_command,' -Wunused-label');
         }
         break;
      case 'GCC_WARN_UNUSED_PARAMETER':
         if (build_option_bool) {
            strappend(compile_command,' -Wunused-parameter');
         }
         break;
      case 'GCC_WARN_UNUSED_VALUE':
         if (build_option_bool) {
            strappend(compile_command,' -Wunused-value');
         }
         break;
      case 'GCC_WARN_UNUSED_VARIABLE':
         if (build_option_bool) {
            strappend(compile_command,' -Wunused-variable');
         }
         break;
      case 'GENERATE_PROFILING_CODE':
         if (build_option_bool) {
            strappend(compile_command,' -pg');
         }
         break;
      case 'HEADER_SEARCH_PATHS':
         build_option_value=strip(build_option_value,'B','"');
         while (build_option_value!='') {
            parse build_option_value with path (PARSE_PATHSEP_RE),'r' build_option_value;
            strappend(compile_command,' ':+_maybe_quote_filename('-I':+path));
         }
         break;
      case 'LIBRARY_SEARCH_PATHS':
         build_option_value=strip(build_option_value,'B','"');
         while (build_option_value!='') {
            parse build_option_value with path (PARSE_PATHSEP_RE),'r' build_option_value;
            strappend(compile_command,' ':+_maybe_quote_filename('-L':+path));
         }
         break;
      case 'MACOSX_DEPLOYMENT_TARGET':
         if ('env':== substr(compile_command,1,3)) {
            compile_command=substr(compile_command,5);
         }
         compile_command='env MACOSX_DEPLOYMENT_TARGET='build_option_value' 'compile_command;
         break;
      case 'OPTIMIZATION_CFLAGS':
         build_option_value=strip(build_option_value,'B','"');
         if (build_option_value:!='') {
            strappend(compile_command,' 'build_option_value);
         }
         break;
      case 'OTHER_CFLAGS':
         build_option_value=strip(build_option_value,'B','"');
         if (build_option_value:!='') {
            strappend(compile_command,' 'build_option_value);
         }
         break;
      case 'SECTORDER_FLAGS':
         build_option_value=strip(build_option_value,'B','"');
         if (build_option_value:!='') {
            strappend(compile_command,' -sectorder ':+build_option_value);
         }
         break;
      case 'SYMROOT':
         build_option_value=strip(build_option_value,'B','"');
         while (build_option_value!='') {
            parse build_option_value with path (PARSE_PATHSEP_RE),'r' build_option_value;
            strappend(compile_command,' -F':+path:+' -I':+path:+FILESEP:+'include');
         }
         break;
      case 'WARNING_CFLAGS':
         build_option_value=strip(build_option_value,'B','"');
         if (build_option_value:!='') {
            strappend(compile_command,' 'build_option_value);
         }
         break;
      case 'ZERO_LINK':
         if (build_option_bool) {
            strappend(compile_command,' -fzero-link');
         }
         break;
      default:
         break;
      }
   }
}

static bool xcode_get_build_settings(_str target_name,_str vpj_filename,typeless & all_buildSettings,_str style_name='')
{
   typeless * root_object=xcode_find_root_object();
   if (!root_object) {
      return true;
   }

   typeless * root_buildSettings=root_object->_indexin('buildSettings');
   if (!root_buildSettings || root_buildSettings->_varformat()!=VF_HASHTAB) {
      return true;
   }

   typeless * target=xcode_find_target(target_name,root_object);
   if (!target) {
      return true;
   }

   typeless * target_buildSettings=target->_indexin('buildSettings');
   if (!target_buildSettings || target_buildSettings->_varformat()!=VF_HASHTAB) {
      return true;
   }

   if (style_name:=='') {
      style_name=GetCurrentConfigName(VSEProjectFilename(vpj_filename));
   }

   typeless * style_buildSettings=null;
   typeless * style=xcode_find_style(style_name);
   if (style) {
      style_buildSettings=style->_indexin('buildSettings');
      if (!style_buildSettings || style_buildSettings->_varformat()!=VF_HASHTAB) {
         return true;
      }
   }

   //first set some defaults
   all_buildSettings._makeempty();
   all_buildSettings:['ARCHS']='ppc';
   all_buildSettings:['GCC_ENABLE_PASCAL_STRINGS']='YES';
   all_buildSettings:['GCC_CW_ASM_SYNTAX']='YES';
   all_buildSettings:['GCC_ENABLE_CPP_RTTI']='YES';
   all_buildSettings:['GCC_REUSE_STRINGS']='YES';
   all_buildSettings:['BUILD_VARIANTS']='normal';

   xcode_group_build_settings(all_buildSettings,root_buildSettings);
   xcode_group_build_settings(all_buildSettings,target_buildSettings);
   if (style_buildSettings) {
      xcode_group_build_settings(all_buildSettings,style_buildSettings);
   }

   symRoot := "";
   if (all_buildSettings._indexin('SYMROOT')) {
      symRoot=strip(all_buildSettings:['SYMROOT'],'B','"');
   } else {
      all_buildSettings:['SYMROOT']='build';
   }

   headerSearchPaths := "";
   if (all_buildSettings._indexin('HEADER_SEARCH_PATHS')) {
      headerSearchPaths=strip(all_buildSettings:['HEADER_SEARCH_PATHS'],'B','"');
   }
   if (headerSearchPaths:=='') {
      if (all_buildSettings._indexin('OBJROOT')) {
         headerSearchPaths=all_buildSettings:['OBJROOT']:+FILESEP;
      }

      strappend(headerSearchPaths,xcode_get_project_name());
      strappend(headerSearchPaths,'.build');
      strappend(headerSearchPaths,FILESEP);
      strappend(headerSearchPaths,target_name);
      strappend(headerSearchPaths,'.build');
      strappend(headerSearchPaths,FILESEP);
      strappend(headerSearchPaths,'DerivedSources');

      all_buildSettings:['HEADER_SEARCH_PATHS']=headerSearchPaths;
   }

   return false;
}

_str _xcode_make_compile_command(_str buf_name, _str vpj_filename=_project_name)
{
   _str VendorWorkspaceFilename;
   int status=_GetAssociatedProjectInfo(vpj_filename,VendorWorkspaceFilename);
   if (status) {
      return '';
   }

   projectfile := absolute("project.pbxproj",VendorWorkspaceFilename);
   target_name := _strip_filename(vpj_filename, "PE");

   if (xcode_maybe_open_project(projectfile)) {
      return '';
   }

   typeless * target=xcode_find_target(target_name,xcode_find_root_object());
   if (!target) {
      return '';
   }

   typeless * file=xcode_find_file(buf_name,target_name,target);
   if (!file) {
      return '';
   }

   typeless * file_type=file->_indexin('explicitFileType');
   if (!file_type || file_type->_varformat()!=VF_LSTR) {
      file_type=file->_indexin('lastKnownFileType');
      if (!file_type || file_type->_varformat()!=VF_LSTR) {
         return '';
      }
   }

   _str language;
   _str ext;
   parse (*file_type) with 'sourcecode.'language'.'ext;

   compile_command := "/usr/bin/gcc-3.3 -pipe -fmessage-length=0 -x ";

   if (ext:=='objc') {
      strappend(compile_command,'objective-c');
   } else if (ext:=='objcpp') {
      strappend(compile_command,'objective-c++');
   } else if (language:=='cpp') {
      strappend(compile_command,'c++');
   } else {
      strappend(compile_command,'c');
   }

   typeless all_buildSettings;
   if (xcode_get_build_settings(target_name,vpj_filename,all_buildSettings)) {
      return '';
   }
   
   xcode_process_build_settings(all_buildSettings,compile_command);

   strappend(compile_command,' -c 'buf_name);

   strappend(compile_command,' -o 'xcode_make_object_file_name(buf_name,target_name,all_buildSettings));

   //expand any environment variables that may be in the command
   while (pos('$(',compile_command)) {
      _str leading;
      _str var_name;
      _str trailing;
      parse compile_command with leading'$('var_name')'trailing;
      // It seems that the dollar sign is always escaped, but it may not be
      // a requirement so this will deal with it either way.
      _maybe_strip(leading, '\');
      compile_command=leading:+get_env(var_name):+trailing;
   }
   return compile_command;
}

_str _xcode_get_output_file(_str vpj_file, _str xcodeBundleDirName, _str config, _str & output_dir, _str sdkName='')
{
   // Project support method for this. Get it straight from
   // the information the parser picks up. And we can pass the .app 
   // directory name to the debugger. We don't have to go down any further 
   // into the bundle. The gdb debugger is smart enough to find it.

   // Get absolute path to the .xcodeproj bundle directory
   vpjDir := _strip_filename(vpj_file,'N');
   xcodeBundleAbsoluteDir := absolute(xcodeBundleDirName, vpjDir);

   // Get absolute path to the project.pbxproj file
   projectfile := absolute("project.pbxproj",xcodeBundleAbsoluteDir);
   _str outputPath;
   _GetXcodeProjectOutputFilename(projectfile, config, sdkName, outputPath);
   if (outputPath._length()) {
      // Make sure .app/ trailing sep is removed
      outputPath = strip(outputPath, 'T', FILESEP);
      _ProjectSet_OutputFile(_ProjectHandle(vpj_file),relative(outputPath,vpjDir),config);
      output_dir = _strip_filename(outputPath, 'NE');
   }
   return outputPath;
}

_str _xcode_get_include_dirs(_str vpj_filename=_project_name)
{
   // TODO: Get the header directories of the linked frameworks.

   _str VendorWorkspaceFilename;
   int status=_GetAssociatedProjectInfo(vpj_filename,VendorWorkspaceFilename);
   if (status) {
      return '';
   }
   projectfile := absolute("project.pbxproj",VendorWorkspaceFilename);
   target_name := _strip_filename(vpj_filename, "PE");

   if (xcode_maybe_open_project(projectfile)) {
      return '';
   }

   typeless * target=xcode_find_target(target_name,xcode_find_root_object());
   if (!target || target->_varformat()!=VF_HASHTAB) {
      return '';
   }

   typeless * buildSettings=target->_indexin('buildSettings');
   if (!buildSettings || buildSettings->_varformat()!=VF_HASHTAB) {
      return '';
   }

   typeless * HEADER_SEARCH_PATHS=buildSettings->_indexin('HEADER_SEARCH_PATHS');
   if (!HEADER_SEARCH_PATHS || HEADER_SEARCH_PATHS->_varformat()!=VF_LSTR) {
      return '';
   }

   return (*HEADER_SEARCH_PATHS);
}

static const XCMENU_BUILDWORKSPACE_SCHEME_CATEGORY= 'build xcworkspace scheme';
static const XCMENU_BUILDWORKSPACE_SCHEME_CAPTION= 'Build Scheme...';
static const XCMENU_BUILDWORKSPACE_SCHEME_COMMAND= 'xcode-build-scheme';

_command void xcode_build_scheme(_str SchemeName='', _str WorkspaceFile=_workspace_filename) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_PRO_EDITION)
{
   if (SchemeName=='') {
      return;
   }
   if (_IsWorkspaceAssociated(_workspace_filename, auto associateWkspace)) {
      isXcodeWorkspace := _IsXcodeWorkspaceFilename(associateWkspace);
      isXcodeProject := _IsXcodeProjectFilename(associateWkspace);
      if (isXcodeWorkspace || isXcodeProject) {
         commandLine := "xcodebuild";
         if (isXcodeWorkspace) {
            commandLine :+= ' -workspace ':+ _maybe_quote_filename(WorkspaceFile);
         } else {
            commandLine :+= ' -project ':+ _maybe_quote_filename(WorkspaceFile);
         }
      
         // add scheme name
         commandLine :+= ' -scheme ' :+ _maybe_quote_filename(SchemeName);

         // set configuration name
         // commandLine :+= ' -configuration ' :+ ConfigurationName;

         // set build dir
         build_dir := 'build/';
         //commandLine :+= ' BUILD_DIR=' :+ _maybe_quote_filename(build_dir);

         concur_command(commandLine);
         //say("Building scheme "SchemeName" for workspace "associatedWkspace);
      }
   }
}

void initMenuXcodeWorkspaceSchemes(int menu_handle)
{
    if (!_isMac()) {
       return;
    }
    schemesMenu := -1;
    schemesPos := -1;
    associateWkspace := "";
    static _str lastXcWorkspace;
    int statusSchemesMenu = _menu_find(menu_handle, XCMENU_BUILDWORKSPACE_SCHEME_CATEGORY, schemesMenu, schemesPos, "C");
    if (_IsWorkspaceAssociated(_workspace_filename, associateWkspace) &&
        (_IsXcodeWorkspaceFilename(associateWkspace) || _IsXcodeProjectFilename(associateWkspace))) {
        if ( (statusSchemesMenu == 0) && (associateWkspace != lastXcWorkspace)) {
            // Schemes menu is from a different workspace. Delete and re-add
            _menu_delete(schemesMenu,schemesPos);
            statusSchemesMenu = -1;
        }
        if (statusSchemesMenu != 0) {
            lastXcWorkspace = associateWkspace;
            // Create the "Build Scheme" menu
            // Find a place for it to go on the Build menu
            int build_menu_handle, itempos;
            int status = _menu_find(menu_handle, "start-process", build_menu_handle, itempos, "M");
            if (status) {
                status = _menu_find(menu_handle, "project-tool-wizard", build_menu_handle, itempos, "M");
                if (status) {
                   status = _menu_find(menu_handle, "projecttbAddNewBuildTool", build_menu_handle, itempos, "M");
                }
            }
            if (status < 0) {
               return;
            }

            status = _menu_insert(build_menu_handle,
                                  itempos+1,
                                  MF_SUBMENU,       // flags
                                  XCMENU_BUILDWORKSPACE_SCHEME_CAPTION,  // tool name
                                  "",   // command
                                  XCMENU_BUILDWORKSPACE_SCHEME_CATEGORY,    // category
                                  "",  // help command
                                  "Builds a workspace scheme"       // help message
                                 );

            status = _menu_find(build_menu_handle, XCMENU_BUILDWORKSPACE_SCHEME_CATEGORY, schemesMenu, schemesPos, "C");

            int tdmf_flags;
            int schemes_submenu_handle;
            _str tdcaption, tdcommand, tdcategories, tdhelp_command, tdhelp_message;
            _menu_get_state(schemesMenu, schemesPos, tdmf_flags, "P", tdcaption, schemes_submenu_handle,
                            tdcategories, tdhelp_command, tdhelp_message);

            // Insert the individual scheme names
            _str allSchemes[];
            _GetXcodeWorkspaceSchemes(associateWkspace, allSchemes);

            if (allSchemes._length() == 0) {
                _menu_delete(schemesMenu,schemesPos);
            } else {
                for (i := 0; i < allSchemes._length(); ++i) {
                    status = _menu_insert(schemes_submenu_handle, i,
                                          0,  // flags
                                          allSchemes[i], // tool name
                                          'xcode_build_scheme '_maybe_quote_filename(allSchemes[i]),
                                          "scheme", // category
                                          "",  // help command
                                          ""   // help message
                                         );
                }
            }

        }

    } else {
        if (statusSchemesMenu == 0 && schemesMenu != -1 && schemesPos != -1) {
            lastXcWorkspace = '';
            // Remove the "Build Scheme" menu
            _menu_delete(schemesMenu,schemesPos);
        }
    }
}   

static const SET_TARGET_DESTINATION= 'Set Target Destination';
static XcodeSDKInfo s_macFrameworks[];

_str GetCurrentTargetSDK(_str ProjectName=_project_name)
{
   if (ProjectName=='') {
      return('');
   }
   if (_file_eq(ProjectName, _project_name) && gActiveTargetDestination!='') {
      return(gActiveTargetDestination);
   }
   TargetName := "";
   _ini_get_value(VSEWorkspaceStateFilename(), "TargetSDK", _RelativeToWorkspace(ProjectName), TargetName,'',_fpos_case);
   return(TargetName);
}

_command void xcode_set_target_sdk(_str TargetName='', _str ProjectFilename=_project_name) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_PRO_EDITION)
{
   if (TargetName == "") return;
   // look for project specified on command line?
   _str cmd_line = TargetName;
   cmd_arg := "";
   for (;;) {
      cmd_arg = parse_file(cmd_line, false);
      if (cmd_arg == '') break;

      if (cmd_arg == '-p') {
         ProjectFilename = parse_file(cmd_line, false);
      } else {
         TargetName = cmd_arg;
         break;
      }
   }
   ProjectFilename = strip(ProjectFilename, 'B', '"');

   int orig_view_id;
   get_window_id(orig_view_id);

   _str old_targetName = GetCurrentTargetSDK(ProjectFilename);
   int status = _ini_set_value(VSEWorkspaceStateFilename(), "TargetSDK", _RelativeToWorkspace(ProjectFilename), TargetName ,_fpos_case);
   activate_window(orig_view_id);
}

void initMenuTargetDestinations(int menu_handle, _str ProjectFilename)
{
   if (!_isMac()) return;

   _str targetDestinations[];
   _str sdkTargetName[];
   count := 0;

   handle := _ProjectHandle(ProjectFilename);
   associatedProject := _ProjectGet_AssociatedFile(handle);
   if (associatedProject) {
      if (_IsXcodeProjectFilename(associatedProject)) {
         activeConfig := GetCurrentConfigName(ProjectFilename);
         projectfile := absolute("project.pbxproj", absolute(associatedProject, _strip_filename(ProjectFilename, 'N')));
         _GetXcodeProjectSDKRoot(projectfile, activeConfig, auto sdkRoot);
         if (sdkRoot == "iphoneos") {
            if (s_macFrameworks._length() == 0) {
               getXcodeSDKs(s_macFrameworks);
            }

            for (i := 1; i < s_macFrameworks._length(); ++i) {
               if (pos("iphone", s_macFrameworks[i].canonicalName, 1) == 1) {
                  if (pos("iphoneos", s_macFrameworks[i].canonicalName, 1) == 1) {
                     targetDestinations[count] = "iOS Device";
                     sdkTargetName[count++] = s_macFrameworks[i].canonicalName;
                     continue;
                  }

                  parse s_macFrameworks[i].canonicalName with "iphonesimulator" auto sdkVersion;
                  // parse sdkVersion with auto majorNumber "." minorNumber;
                  targetDestinations[count] = "iPhone Simulator "sdkVersion;   
                  sdkTargetName[count++] = s_macFrameworks[i].canonicalName"-1";
                  targetDestinations[count] = "iPad Simulator "sdkVersion;
                  sdkTargetName[count++] = s_macFrameworks[i].canonicalName"-2";

               }
            }
         }
      }
   }

   no_targets := (_workspace_filename == "" || _project_name == "" || (targetDestinations._length() == 0));
   int tdmenu, tdpos;
   int status = _menu_find(menu_handle, "set target destination", tdmenu, tdpos, "C");
   if (status && !no_targets) {
      int build_menu_handle, itempos;
      status = _menu_find(menu_handle, "set active configuration", build_menu_handle, itempos, "C");
      if (status) {
         status = _menu_find(menu_handle, "start-process", build_menu_handle, itempos, "M");
         if (status) {
            status = _menu_find(menu_handle, "projecttbSetCurProject", build_menu_handle, itempos, "M");
         }
      }
      if (status) return;

      status = _menu_insert(build_menu_handle,
                            itempos + 1,
                            MF_SUBMENU,       // flags
                            SET_TARGET_DESTINATION,  // tool name
                            "",   // command
                            "set target destination",    // category
                            "",  // help command
                            "Sets the target destination"       // help message
                            );
      if (status < 0) return;
      status = _menu_find(build_menu_handle, "set target destination", tdmenu, tdpos, "C");
   }

   if (status) return;

   typeless tdsubmenu_handle;
   int tdmf_flags;
   _str tdcaption, tdcommand, tdcategories, tdhelp_command, tdhelp_message;
   _menu_get_state(tdmenu, tdpos, tdmf_flags, "P", tdcaption, tdsubmenu_handle,
                   tdcategories, tdhelp_command, tdhelp_message);
   if (!no_targets) {
      _menu_set_state(tdmenu, tdpos, (tdmf_flags & ~MF_GRAYED)|MF_ENABLED, "P", tdcaption, tdsubmenu_handle,
                      tdcategories, tdhelp_command, tdhelp_message);
   }

   for (;;) {
      status = _menu_get_state(tdsubmenu_handle, 0, tdmf_flags, "P", tdcaption, tdcommand,
                               tdcategories, tdhelp_command, tdhelp_message);
      if (status) {
         break;
      }
      _menu_delete(tdsubmenu_handle, 0);
   }

   if (no_targets) {
      _menu_delete(tdmenu, tdpos);
      return;
   }

   _str currentTarget = GetCurrentTargetSDK(ProjectFilename);
   for (i := 0; i < targetDestinations._length(); ++i) {
      flags := 0;
      if ((currentTarget == "" && i == 0) || strieq(sdkTargetName[i], currentTarget)) {
         flags |= MF_CHECKED;
      }
      status = _menu_insert(tdsubmenu_handle, i,
                            flags,  // flags
                            targetDestinations[i], // tool name
                            'xcode_set_target_sdk -p '_maybe_quote_filename(ProjectFilename)' '_maybe_quote_filename(sdkTargetName[i]),
                            "file", // category
                            "",  // help command
                            ""   // help message
                            );
   }

}
 
void xcode_project_add_simulator_targets(_str ProjectFilename, int projectHandle)
{
   _str configStrings[];
   projectfile := absolute("project.pbxproj", ProjectFilename);
   _GetXcodeProjectConfigurations(projectfile, configStrings);
  
   numConfigs := configStrings._length();
   if (numConfigs > 0) {
      int index;
      for (index = 0; index < numConfigs; ++index) {
         config := configStrings[index];
         _GetXcodeProjectSDKRoot(projectfile, config, auto sdkRoot);
         if (sdkRoot == "iphoneos") {
            configNode := _ProjectGet_ConfigNode(projectHandle, config);
            if (configNode < 0) {
               continue;
            }
            launchNode := _ProjectAddTool(projectHandle, "Launch Simulator", config);
            if (launchNode >= 0) {
               _ProjectSet_TargetCmdLine(projectHandle, launchNode, "xcode_project_launch_sim", "Slick-C");
               _ProjectSet_TargetCaptureOutputWith(projectHandle, launchNode, "ProcessBuffer");
               _ProjectSet_TargetSaveOption(projectHandle, launchNode, "SaveNone");
            }

            debugNode := _ProjectAddTool(projectHandle, "Debug Simulator", config);
            if (debugNode >= 0) {
               _ProjectSet_TargetCmdLine(projectHandle, debugNode, "xcode_project_debug_sim", "Slick-C");
               _ProjectSet_TargetCaptureOutputWith(projectHandle, debugNode, "ProcessBuffer");
               _ProjectSet_TargetSaveOption(projectHandle, debugNode, "SaveNone");
            }

            // LB: this may need to revisited
            exeNode := _ProjectGet_TargetNode(projectHandle, 'Execute', config);
            if (exeNode >= 0) {
               _xmlcfg_delete(projectHandle, exeNode);
            }

            // disable debug callback for iOS (to be fixed at a later date)
            dbgNode := _ProjectGet_TargetNode(projectHandle, 'Debug', config);
            if (dbgNode >= 0) {
               _ProjectSet_TargetCmdLine(projectHandle, dbgNode, "");
               _ProjectSet_DebugCallbackName(projectHandle, "", config);
            }
         }
      }
   }
}

int _OnUpdate_xcode_project_launch_sim(CMDUI &cmdui, int target_wid, _str command)
{
   if (!_haveBuild()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (_project_name == "") {
      return(MF_GRAYED);
   }
   associatedProject := _ProjectGet_AssociatedFile(_ProjectHandle(_project_name));
   if (associatedProject == "" || !_IsXcodeProjectFilename(associatedProject)) {
      return(MF_GRAYED);
   }
   currentTarget := GetCurrentTargetSDK(_project_name);
   if (currentTarget == "") {
      return(MF_GRAYED);
   }
   parse currentTarget with auto targetSDK "-" .;
   if (targetSDK == "iphoneos") {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

static _str xcode_ios_simulator_command(_str outputFile = "", _str debug = "")
{
   if (outputFile == "") {
      associatedProject := _ProjectGet_AssociatedFile(_ProjectHandle(_project_name));
      if (associatedProject == "" || !_IsXcodeProjectFilename(associatedProject)) {
         // not xcode project
         _message_box("Xcode Project:  Not an Xcode project.");
         return("");
      }
    
      currentConfig := GetCurrentConfigName(_project_name);
      outputFile = _xcode_get_output_file(_project_name, associatedProject, currentConfig, auto absOutputDir, "iphonesimulator");
   }

   if (outputFile == "") {
      // no output file
      _message_box("Xcode Project:  Cannot resolve output file from Xcode project.");
      return("");
   }

   currentTarget := GetCurrentTargetSDK(_project_name);
   if (currentTarget == "") {
      _message_box("Xcode Project:  No target SDK or Device");
      return("");
   }

   parse currentTarget with auto targetSDK "-" auto targetDevice;
   if (targetSDK == "iphoneos") {
      // not available for device
      _message_box("Xcode Project:  Simulator not available. Current target is iOS Device.");
      return("");
   }
   se_simlaunch := get_env("VSLICKBIN1"):+"se_simlaunch";
   if (file_exists(se_simlaunch)) {
      attrs:=file_list_field(se_simlaunch,DIR_ATTR_COL,DIR_ATTR_WIDTH);
      if (attrs=='') {
         _message_box(nls("Unable to get permiision for '%s'",se_simlaunch));
         return('');
      }
      if(!pos('x',attrs,'','i')) {
          _message_box(nls("In order to execute:\n\n\n%s1\n\n\nit must be given executing permssions. At a terminal execute the command:\n\n\nsudo chmod a+x %s1\n\n\nand try this operation again. \n\n\nThis extra step is due to a code signing limitation.",se_simlaunch));
          return("");
      }
   }

   cmd := _maybe_quote_filename(se_simlaunch);
   cmd :+= " ":+_maybe_quote_filename(outputFile);
   if (debug == "debug") {
      cmd :+= " -debugwait";
   }
   if (targetSDK != "") {
      cmd :+= " -sdk ":+targetSDK;
   }
   if (targetDevice != "") {
      if (targetDevice == "2") {
         cmd :+= " -device ipad";
      }
   }
   return cmd;
}

_command void xcode_project_launch_sim(_str outputFile = "", _str debug = "") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return;
   }
   cmd := xcode_ios_simulator_command();
   if (cmd != '') {
      status := concur_command(cmd);
   }
}

int _OnUpdate_xcode_project_debug_sim(CMDUI &cmdui, int target_wid, _str command)
{
   return _OnUpdate_xcode_project_launch_sim(cmdui, target_wid, command);
}
 
_command void xcode_project_debug_sim() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   associatedProject := _ProjectGet_AssociatedFile(_ProjectHandle(_project_name));
   if (associatedProject == "" || !_IsXcodeProjectFilename(associatedProject)) {
      // not xcode project
      _message_box("Xcode Project:  Not an Xcode project.");
      return;
   }
  
   currentConfig := GetCurrentConfigName(_project_name);
   outputFile := _xcode_get_output_file(_project_name, associatedProject, currentConfig, auto absOutputDir, "iphonesimulator");
   if (outputFile == "") {
      // no output file
      _message_box("Xcode Project:  Cannot resolve output file from Xcode project.");
      return;
   }

   cmd := xcode_ios_simulator_command(outputFile, "debug");
   if (cmd == "") {
      return;
   }
   status := concur_command(cmd);

   // _xcode_project_debug_sim_callback will recieve the ok to attach debugger
}
 
int _xcode_project_debug_sim_callback(_str output_file = '', int pid = -1) 
{
   if (output_file != '' && pid > 0) {
      // debug attach to process
      session_name := "Simulator: " :+ output_file;
      attach_info := "pid="pid",app="output_file",session="session_name;
      debug_attach("gdb", attach_info, session_name);
   }
   return 0;
}
 
//-----------------------------------------------------------------
//-----------------------------------------------------------------
//------------ below here handles the Xcode emulation -------------
//-----------------------------------------------------------------
//-----------------------------------------------------------------

_command void macos_font_config()
{
   config('_font_config_form', 'D');
}

_command void macos_show_colors()
{
   color();
}

_str strMacOSFind='';
_command void macos_select_find_string()
{
   str := "";
   if (p_window_id._isEditorCtl(false) && p_window_id.select_active2()) {
      mark_locked := 0;
      if (_select_type('','S')=='C') {
         mark_locked=1;
         _select_type('','S','E');
      }
      p_window_id.filter_init();
      p_window_id.filter_get_string(str);
      p_window_id.filter_restore_pos();
      if (mark_locked) {
         _select_type('','S','C');
      }
   }
   strMacOSFind=str;
}

_command void macos_project_add_files()
{
   project_edit(PROJECTPROPERTIES_TABINDEX_FILES);
}

_command xcode_activate_project_toolbar() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return activate_project_files();
}

_command xcode_activate_output_toolbar() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return activate_output();
}

_command macos_activate_build_output_toolbar() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return activate_build();
}

_command void xcode_activate_tag_properties_toolbar() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   activate_tag_properties_toolbar();
}

_command macos_find_in_files()
{
   find_in_files();
}

