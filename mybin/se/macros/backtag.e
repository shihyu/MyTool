////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50249 $
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
#include "tagsdb.sh"
#include "color.sh"
#import "se/tags/TaggingGuard.e"
#import "se/datetime/DateTime.e"
#import "context.e"
#import "listproc.e"
#import "main.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "toast.e"
#endregion

using namespace se.datetime;

#if __OS390__ || __TESTS390__
int def_max_retag_including = 0;
int def_max_retag_includes  = 0;
#else
int def_max_retag_including = 16;
int def_max_retag_includes  = 32;
#endif

static int gBackgroundTaggingRunning=0;
static _str gNextAvailableTagTime = 0;

static void SetDateForBuffer(boolean forceInvalidDate=false)
{
   if (p_modify || forceInvalidDate) {
      tag_set_date(p_buf_name,'1111':+substr(p_file_date,5));
   }else{
      tag_set_date(p_buf_name,p_file_date);
   }
   tag_set_language(p_buf_name,p_LangId);
   //say('got here find='tag_find_language(dummy,p_LangId));
}

/**
 * Store the language identifier for this embedded
 * code block in the current tag database.
 * 
 * @deprecated 
 *    Use {@link tag_set_embedded_language()}.
 */
void SetEmbeddedExtension()
{
   tag_set_embedded_language();
}
/**
 * Store the language identifier for this embedded
 * code block in the current tag database. 
 *  
 * @see _EmbeddedStart() 
 * @see _EmbeddedEnd() 
 * @see tag_set_language 
 *  
 * @categories Tagging_Functions
 * @since 13.0
 */
void tag_set_embedded_language()
{
   typeless orig_values;
   int embedded=_EmbeddedStart(orig_values);
   if (embedded==1) {
      tag_set_language(p_buf_name,p_LangId);
      _EmbeddedEnd(orig_values);
      tag_set_language(p_buf_name,p_LangId);
   }
}

int RetagFile(_str filename, boolean useThread=false, int bufferId=0,_str langId=null)
{
   if (useThread && RetagCurrentFileAsync(filename, langId) == 0) {
      return 0;
   }
   boolean inmem=false;
   int temp_view_id=0;
   int orig_view_id=0;
   int status = FILE_NOT_FOUND_RC;
   if (bufferId > 0) {
      status = _open_temp_view("+bi "bufferId,temp_view_id,orig_view_id,"",inmem,false,true);
   }
   if (status < 0) {
      status = _open_temp_view(filename,temp_view_id,orig_view_id,"",inmem,false,true);
   }
   if (status) {
      return(status);
   }
   status=RetagCurrentFile(useThread,!inmem);
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(status);
}
int RetagCurrentFileAsync(_str buf_name, _str langId=null)
{
   //say("RetagCurrentFileAsync: trying file="buf_name);
   // make sure this file is not open in the editor
   // even as a hidden buffer
   if (buf_match(buf_name,1,'EBH') != "") {
      return FILE_NOT_FOUND_RC;
   }

   // check the language ID for this file.
   // If we can't determine the language ID
   // without opening the file, then bail out
   if (langId==null || length(langId) == 0) {
      langId = _Filename2LangId(buf_name);
      if (langId == "") {
         return FILE_NOT_FOUND_RC;
      }
   }

   // verify that this language has a list-tags callback
   index := _FindLanguageCallbackIndex('vs%s_list_tags',langId);
   if (!index) {
      return STRING_NOT_FOUND_RC;
   }

   // verify that this language supports background tagging
   if (!_is_background_tagging_supported(langId)) {
      return STRING_NOT_FOUND_RC;
   }

   // check if this file is included by another buffer.
   // if so, then the outer file really should be retagged, not this one
   if (def_max_retag_including > 0 && !_DataSetIsFile(buf_name)) {
      _str source_file_name='';
      int status=tag_find_included_by(buf_name,source_file_name);
      if (!status && source_file_name!='') {
         _str parents[]; parents._makeempty();
         while (!status && source_file_name!='' &&
                parents._length() < def_max_retag_including) {
            // if it is a buffer, add to list of files to be retagged
            if (buf_match(source_file_name,1,'EB')!='') {
               tag_reset_find_file();
               return FILE_NOT_FOUND_RC;
            }
            status=tag_next_included_by(buf_name,source_file_name);
         }
      }
      tag_reset_find_file();
   }

   // get the date on disk for this file
   //say("RetagCurrentFileAsync: tagging buffer="buf_name);
   ltf_flags := (tag_get_db_flags()&VS_DBFLAG_occurrences)? VSLTF_LIST_OCCURRENCES:0;
   fileDate := _file_date(buf_name,'B'); 

   // check if there is already a job running for this buffer
   // cancel the job if the buffer is already out of date
   int status = tag_get_async_tagging_job(buf_name, 
                                          ltf_flags, 
                                          0,
                                          fileDate,
                                          0, null, 1, 0, 0);
   if (!status) {
      return(0);
   }

   // if the file is not already represented in the tag database, add it now
   if (tag_get_date(buf_name, auto modify_date) < 0) {
      tag_set_date(buf_name,fileDate);
      tag_set_language(buf_name,langId);
   }

   // call the list tags callback for asynchronous tagging
   ltf_flags |= VSLTF_ASYNCHRONOUS;
   status = call_index(0,buf_name,langId,ltf_flags,index);
   return status;
}
int RetagCurrentFile(boolean useThread=false, boolean useFileOnDisk=false)
{
   int i=0;
   typeless already_loaded=0;
   int temp_view_id=0;
   int orig_view_id=0;
   //say("RetagCurrentFile: buffer="p_buf_name);
   if (def_max_retag_including > 0 && !_DataSetIsFile(p_buf_name)) {
      _str source_file_name='';
      int status=tag_find_included_by(p_buf_name,source_file_name);
      if (!status && source_file_name!='') {
         _str parents[]; parents._makeempty();
         while (!status && source_file_name!='' &&
                parents._length() < def_max_retag_including) {
            // if it is a buffer, add to list of files to be retagged
            if (buf_match(source_file_name,1,'EB')!='') {
               parents[parents._length()] = source_file_name;
            }
            status=tag_next_included_by(p_buf_name,source_file_name);
         }
         tag_reset_find_file();
         for (i=0; i<parents._length(); ++i) {
            already_loaded=false;
            status=_open_temp_view(parents[i],temp_view_id,orig_view_id,'',already_loaded,false,true);
            if (!status) {
               RetagCurrentFile(useThread, useFileOnDisk);
               _delete_temp_view(temp_view_id);
               activate_window(orig_view_id);
            }
         }
         return(0);
      }
   }

   // can we use the context information for retagging this one?
   tag_reset_find_file();
   int status=0;
   int result=0;
   /*
   if (tag_check_cached_context(VSLTF_SET_TAG_CONTEXT) && 
       !(tag_get_db_flags() & VS_DBFLAG_occurrences) &&
       (p_ModifyFlags&MODIFYFLAG_CONTEXT_UPDATED) == MODIFYFLAG_CONTEXT_UPDATED) {
      status = tag_transfer_context(p_buf_name);
      if (!status) {
         return status;
      }
   }
   */

   // Ok, just use list-tags or proc-search to do the work
   save_pos(auto p);
   p_line=0;

   // check if we are really able to use a background thread to tag this
   _str lang=p_LangId;
   if (useThread && !_is_background_tagging_supported(lang)) {
      useThread = false;
   }

   //9:29am 7/15/1997:Can't do this because it screws up bg tagging
   typeless p1,p2,p3,p4;
   index := _FindLanguageCallbackIndex('vs%s_list_tags',lang);
   if (index) {

      ltf_flags := (tag_get_db_flags()&VS_DBFLAG_occurrences)? VSLTF_LIST_OCCURRENCES:0;
      if (useThread) {

         // check if there is already a job running for this buffer
         // cancel the job if the buffer is already out of date
         int bufferId = (useFileOnDisk? 0:p_buf_id);
         status = tag_get_async_tagging_job(p_buf_name, 
                                            ltf_flags, 
                                            bufferId, 
                                            p_file_date, 
                                            p_LastModified,
                                            null, 1, 0, 0);
         if (!status) {
            restore_pos(p);
            return(0);
         }

         // if the file is not already represented in the tag database, add it now
         if (tag_get_date(p_buf_name, auto modify_date) < 0) {
            SetDateForBuffer(true);
         }

         ltf_flags |= VSLTF_ASYNCHRONOUS;
         bufferName := (useFileOnDisk? p_buf_name:"");
         status = call_index(0,bufferName,lang,ltf_flags,index);

      } else {

         status=tag_insert_file_start(p_buf_name);

         // is this the project tag file or Slick-C tag file?
         if (ltf_flags & VSLTF_LIST_OCCURRENCES) {
            status = tag_occurrences_start(p_buf_name);
         }

         // prepare for update for current buffer
         tag_lock_context(true);
         tag_clear_embedded();
         SetDateForBuffer();
         save_search(p1,p2,p3,p4);
         status=call_index(0,'',lang,ltf_flags,index);

         // if there was embedded code, do proc-search for embedded tags
         if (!status && tag_get_num_of_embedded()) {

            // bump up the max string size parameter to match the buffer size
            _str orig_max = _default_option(VSOPTION_WARNING_STRING_LENGTH);
            if (p_RBufSize*3+1024 > orig_max) {
               _default_option(VSOPTION_WARNING_STRING_LENGTH, p_RBufSize*3+1024);
            }

            boolean gdo_search=false;
            _str ext_embedded_buffer_data:[];
            int ext_embedded_buffer_data_length:[];

            CollateEmbeddedSections(ext_embedded_buffer_data, ext_embedded_buffer_data_length, gdo_search);

            for (lang._makeempty();;) {
               ext_embedded_buffer_data._nextel(lang);
               if (lang._isempty()) {
                  break;
               }

               int ltf_flags2 = VSLTF_READ_FROM_STRING;

               // look up the list-tags function and call it on the fake buffer
               tag_set_language(p_buf_name,lang);
               LTindex := _FindLanguageCallbackIndex('vs%s-list-tags',lang);
               fake_buffer := ext_embedded_buffer_data:[lang];

               status = call_index(0, '', fake_buffer,
                                   ltf_flags2,
                                   0,0,0,length(fake_buffer),
                                   LTindex);
            }

            // restore the max string size parameter
            _default_option(VSOPTION_WARNING_STRING_LENGTH, orig_max);
         }

         tag_unlock_context();
         restore_search(p1,p2,p3,p4);
         //say('called index status='status);
         restore_pos(p);
         if (status) {
            message(nls("Error reading '%s'",p_buf_name)". "get_message(status));
            return(status);
         }
         status=tag_insert_file_end();
         // complete updating current buffer
         if (ltf_flags & VSLTF_LIST_OCCURRENCES) {
            result = tag_occurrences_end(p_buf_name);
            if (result < 0) {
               return(result);
            }
         }
      }

      restore_pos(p);
      return(status);
   }

   status=tag_insert_file_start(p_buf_name);

   index = _FindLanguageCallbackIndex('%s-proc-search',lang);
   if ( !index ) {

      // see if there is a load-tags function
      fext := lowcase(_get_extension(p_buf_name));
      index = find_index('vs'fext'-load-tags',PROC_TYPE);
      if (index_callable(index)) {
         int ltf_flags = (tag_get_db_flags()&VS_DBFLAG_occurrences)? VSLTF_LIST_OCCURRENCES:0;
         if (ltf_flags & VSLTF_LIST_OCCURRENCES) {
            status = tag_occurrences_start(p_buf_name);
         }
         SetDateForBuffer();
         status=call_index(p_buf_name,ltf_flags,index);
         restore_pos(p);
         if (status) {
            message(nls("Error reading '%s'",p_buf_name)". "get_message(status));
            restore_pos(p);//Shouldn't hurt anything
            return(status);
         }
         status=tag_insert_file_end();
         // complete updating current buffer
         if (ltf_flags & VSLTF_LIST_OCCURRENCES) {
            result = tag_occurrences_end(p_buf_name);
            if (result < 0) {
               restore_pos(p);//Shouldn't hurt anything
               return(result);
            }
         }
         return status;
      }
      restore_pos(p);//Shouldn't hurt anything
      status=tag_insert_file_end();
      return(1);
   }

   //_SetEditorLanguage();
   _str proc_name='';
   SetDateForBuffer();
   save_search(p1,p2,p3,p4);
   status=call_index(proc_name,1,lang,index);
   for (;;) {
      if ( status ) {
         break;
      }
      // first deal with keeping track of extensions of embedded contexts
      tag_set_embedded_language();
      // now insert the current tag
      _str tag_name='';
      _str class_name='';
      _str type_name='';
      int tag_flags=0;
      _str signature='';
      _str return_type='';
      tag_tree_decompose_tag(proc_name, tag_name, class_name, type_name, tag_flags, signature, return_type);
      if (tag_name :!= "") {
         _str s = '';
         if (signature != '' || return_type != '') {
            s = return_type :+ VS_TAGSEPARATOR_args :+ signature;
         }
         status = tag_insert_tag(tag_name, type_name, p_buf_name, p_line, class_name, tag_flags, s);
      }
      proc_name="";
      status=call_index(proc_name,0,lang,index);
   }
   restore_search(p1,p2,p3,p4);
   restore_pos(p);
   status=tag_insert_file_end();
   if (!status) {
      status = _retagOccurrences();
   }

   return(status);
}

/**
 * Takes an array of filenames, and adds them to a
 * tag file.  By default, it adds them to the
 * workspace tag file.
 *
 * @param Filenames An array of filenames
 *
 * @param TagFilename
 *                  Name of tag file to add files to.  If this parameter
 *                  is null(default), it uses the workspace_tag_filename
 *
 * @return returns 0 if succesful.
 */
int AddFilesToTagFile(_str Filenames[],_str TagFilename=null,boolean useThread=false)
{
   mou_hour_glass(1);
   if (TagFilename==null) {
      TagFilename = _GetWorkspaceTagsFilename();
   }
   int status=_OpenOrCreateTagFile(TagFilename);
   //status = tag_open_db(TagFilename);
   if (status < 0) {
      mou_hour_glass(0);
      return(status);
   }
   int i;
   int temp_view_id=0;
   int orig_view_id=0;
   for (i=0;i<Filenames._length();++i) {
      if (useThread && RetagCurrentFileAsync(Filenames[i]) == 0) {
         continue;
      }
      boolean already_loaded=false;
      status=_open_temp_view(Filenames[i],temp_view_id,orig_view_id,'',already_loaded,false,true);
      if (status) {
         p_window_id=orig_view_id;
         continue;
      }
      //We don't care about the status, just do next on anyway
      status=RetagCurrentFile(useThread, !already_loaded);
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
   }
   tag_read_db(TagFilename);
   mou_hour_glass(0);
   return(0);
}

void TagFileOnSave(...)
{
   // has buffer been modified?
   taggingThreaded := false;
   boolean modifyTagged=(p_ModifyFlags & MODIFYFLAG_TAGGED)? true:false;
   boolean doRefresh=false;
   _str filename=p_buf_name;

   // for each tag file
   _str date='';
   typeless tag_files=tags_filenamea();
   int i=0;
   _str tag_filename = next_tag_filea(tag_files, i, false, true);
   while (tag_filename != '') {
      //The file may not have been in this database anyway...
      int status=tag_get_date(filename,date);
      if (!status) {
         // check if we should let background tagging do the work
         useThread := _is_background_tagging_enabled(AUTOTAG_BUFFERS_NO_THREADS);
         if (useThread && !_is_background_tagging_supported()) {
            useThread = false;
         }
         // open the tag file read-write for update
         if (!useThread) {
            status=tag_open_db(tag_filename);
         }
         if (status >= 0) {
            if (!useThread && modifyTagged) {
               // source file not modified, just update date
               tag_set_date(filename,p_file_date);
            } else {
               // source file changed, retag and set date
               status=RetagCurrentFile(useThread);
               if (!status && useThread) {
                  taggingThreaded = true;
               }
               if (!status && !useThread) {
                  p_ModifyFlags|=MODIFYFLAG_TAGGED;
                  _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tag_filename);
                  doRefresh = true;
               }
            }
            // commit the changes
            tag_close_db(tag_filename,1);
         }
      }
      // next please
      tag_filename = next_tag_filea(tag_files,i,false,true);
   }

   // mark this buffer as having a thread started to update the tagging
   if (taggingThreaded) {
      p_ModifyFlags |= MODIFYFLAG_BGRETAG_THREADED;
   }

   // notify those interested that some tag files were modified
   if (doRefresh) {
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
}

// Check if a copy book or include file pulled in by this
// program was modified and we need to retag the buffer
boolean IncludeFileChanged(_str file_name)
{
   // don't want to spend any time checking include files?
   if (!def_max_retag_includes || _DataSetIsFile(file_name)) {
      return false;
   }

   //say("IncludeFileChanged("file_name")");
   boolean include_modified=false;

   // get the list of files included by us
   _str include_file_name;
   _str includes[]; includes._makeempty();
   int status=tag_find_include_file(file_name,include_file_name);
   while (!status && include_file_name!='' &&
          includes._length() < def_max_retag_includes) {
      //say("IncludeFileChanged: include="include_file_name);
      includes[includes._length()] = include_file_name;
      status=tag_next_include_file(file_name,include_file_name);
   }
   tag_reset_find_file();

   // for each include file, get its date and compare to database
   typeless include_buf_id=0;
   int i;
   for (i=0; i<includes._length(); ++i) {
      _str fdate="";
      _str tagged_date="";
      status = tag_get_date(includes[i],tagged_date,file_name);
      if (!status) {
         parse buf_match(includes[i],1,'vhx') with include_buf_id .;
         if (include_buf_id!="") {
            fdate=_BufDate(include_buf_id);
         } else {
            fdate=_file_date(includes[i],'b');
         }
      }
      //say("IFC: include="includes[i]" fdate="fdate" tdate="tagged_date);
      if (tagged_date!="" && fdate!="" && fdate!=tagged_date) {
         include_modified=true;
         break;
      }
   }

   // That's all folks!
   return include_modified;
}

//This function will change as the database API changes
//Returns false if dates match
void _BGReTag2(boolean curBufferOnly=false)
{
   //say('BGTag2: 'p_buf_name);
   int status=0;
   int orig_view_id=0;
   int temp_view_id=0;
   get_window_id(orig_view_id);
   boolean Retagged=false;
   
   if (!curBufferOnly) {
      status=_open_temp_view('',temp_view_id,orig_view_id,'+bi '_mdi.p_child.p_buf_id);
      if (status) {
         return;
      }
   }

   // check if we have already started a thread to tag this buffer
   taggingThreaded := (p_ModifyFlags & MODIFYFLAG_BGRETAG_THREADED) != 0;
   if (taggingThreaded) {
      if(!curBufferOnly) {
         _delete_temp_view(temp_view_id,0 /* Don't delete buffer*/);
      }
      activate_window(orig_view_id);
      return;
   }

   boolean did_hour_glass=false;
   int i=0, first_buf_id=p_buf_id;
   typeless tag_files=tags_filenamea();
   auto_updated_tagfiles := FILESEP:+_file_case(auto_updated_tags_filename()):+FILESEP;
   _str tag_filename = next_tag_filea(tag_files, i, false, true);
   while (tag_filename != '') {
      // do not do background tagging of auto-updated tag files
      if (pos(FILESEP:+_file_case(tag_filename):+FILESEP, auto_updated_tagfiles)) {
         tag_filename = next_tag_filea(tag_files, i, false, true);
         continue;
      }
      // check if this file is in the tag file (and date matches)
      boolean ModifiedTagFile=false;
      for (;;) {
         if (!curBufferOnly && (p_buf_flags&VSBUFFLAG_HIDDEN)) {
            _next_buffer('NHR');
            if (p_buf_id==first_buf_id) break;
            continue;
         }

         _str date='';
         status=tag_get_date(p_buf_name,date);
         if (status) {
            if (curBufferOnly) break;
            //File does not exist in this database
            _next_buffer('NHR');
            if (p_buf_id==first_buf_id) break;
            continue;
         }

         // get the language Id, but don't let a failure stop tagging
         _str langId='';
         status=tag_get_language(p_buf_name,langId);
         if (status) langId=p_LangId;

         // Retag the file if necessary
         if (
             //!(p_buf_flags&VSBUFFLAG_HIDDEN) && already did this above

             //!(p_ModifyFlags&MODIFYFLAG_TAGGED) &&
             //  (p_modify || date!=p_file_date || IncludeFileChanged(p_buf_name))

             (!(p_ModifyFlags&MODIFYFLAG_TAGGED) && 
               (p_modify || date!=p_file_date || langId!=p_LangId)) ||
               IncludeFileChanged(p_buf_name)
             ) {
            //Tag File
            //messageNwait(nls('tagging 'p_buf_name));

            useThread := _is_background_tagging_enabled(AUTOTAG_BUFFERS_NO_THREADS);
            if (useThread && !_is_background_tagging_supported()) {
               useThread = false;
            }

            status = 0;
            if (!useThread) {
               status=tag_open_db(tag_filename);
            }
            if (status >= 0) {
               if (!did_hour_glass && !useThread) {
                  did_hour_glass=true;
                  mou_hour_glass(1);
               }

               RetagCurrentFile(useThread);
               if (!useThread) {
                  ModifiedTagFile=true;
                  Retagged=true;
                  tag_close_db(tag_filename,1);
               } else {
                  taggingThreaded=true;
               }
            }
            // We could add the buffer twice but this won't hurt.
         }

         if (curBufferOnly) break;
         _next_buffer('NHR');
         if (p_buf_id==first_buf_id) break;
      }

      // May be this is paranoia
      if (ModifiedTagFile) {
         activate_window(orig_view_id);
         _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tag_filename);
         if (curBufferOnly) {
            activate_window(orig_view_id);
         } else {
            activate_window(temp_view_id);
         }
      }
      tag_filename = next_tag_filea(tag_files, i, false, true);
   }
   if (did_hour_glass) {
      mou_hour_glass(0);  // so the pointer doesn't throb
      did_hour_glass=false;
   }

   // mark this buffer as having a thread started to update the tagging
   if (taggingThreaded) {
      p_ModifyFlags |= MODIFYFLAG_BGRETAG_THREADED;
   }

   if (Retagged) {
      if (curBufferOnly) {
         p_ModifyFlags|=MODIFYFLAG_TAGGED;
      } else {
         for (;;) {
            _next_buffer('NHR');
            if (
                !(p_buf_flags&VSBUFFLAG_HIDDEN) &&
                !(p_ModifyFlags&MODIFYFLAG_TAGGED)
                //&&  (p_modify)  Removed to ovoid MouCursor blinking when tagging fails
                ) {
               p_ModifyFlags|=MODIFYFLAG_TAGGED;

            }
            if (p_buf_id==first_buf_id) break;
            // The +m option preserves the old buffer position information for the current buffer
         }
      }

   }
   if(!curBufferOnly) {
      _delete_temp_view(temp_view_id,0 /* Don't delete buffer*/);
   }
   activate_window(orig_view_id);
   if (Retagged) {
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
}

//This does buffers...
int _BGReTag()
{
   if (def_autotag_flags2&AUTOTAG_BUFFERS) {
      if (_idle_time_elapsed()>=def_buffer_retag && !gBackgroundTaggingRunning && p_buf_size<=def_update_context_max_file_size) {
         // check if the tag database is busy and we can't get a lock.
         dbName := _GetWorkspaceTagsFilename();
         if (tag_trylock_db(dbName)) {
            gBackgroundTaggingRunning=1;
            _BGReTag2();
            gBackgroundTaggingRunning=0;
            tag_unlock_db(dbName);
         }
      }
   }
   return(0);
}

//12:20pm 9/3/1997
//Scenario:we have tagged a modified buffer and
// it is quit without saving.  The tags are now wrong.
void _cbquit_maybe_retag()
{
   //say(p_ModifyFlags&MODIFYFLAG_TAGGED);
   if (p_buf_name!='' &&
       (def_autotag_flags2&AUTOTAG_BUFFERS) &&
       //(p_ModifyFlags&MODIFYFLAG_TAGGED) &&  (clark) don't want this, just check modify
       p_modify) {
      boolean doRefresh=false;
      typeless tag_files=tags_filenamea();
      int i=0;
      _str tag_filename=next_tag_filea(tag_files, i, false, true);
      while (tag_filename != '') {
         int first=p_buf_id;
         _str dd='';
         int status=tag_get_date(p_buf_name, dd);
         if (!status && tag_open_db(tag_filename) >= 0) {
            _str lang = p_LangId;
            int temp_view_id=0;
            int orig_view_id=0;
            status=_open_temp_view(p_buf_name,temp_view_id,orig_view_id,'+d');
            if (!status) {
               _SetEditorLanguage(lang);
               useThread := _is_background_tagging_enabled(AUTOTAG_BUFFERS_NO_THREADS);
               if (useThread && !_is_background_tagging_supported()) {
                  useThread = false;
               }
               RetagCurrentFile(useThread,true);
               _delete_temp_view(temp_view_id);
               activate_window(orig_view_id);
               if (!useThread) {
                  _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tag_filename);
                  doRefresh=true;
               }
            }
            tag_close_db(tag_filename,1);
         }
         // next please
         tag_filename=next_tag_filea(tag_files, i, false, true);
      }
      if (doRefresh) {
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      }
   }
}

static _str gTagFileTable[];
static int  gCurTagfileIndex=0;
static boolean gfsay_delete_done = false;

definit()
{
   if (upcase(arg(1))!='L') {
      gfsay_delete_done=false;
      gTagFileTable._makeempty();
      gBackgroundTaggingRunning=0;
      gNextAvailableTagTime=0;
   }
}
static void GetTagFileTable(_str (&tag_file_table)[])
{
   if (def_autotag_flags2&AUTOTAG_FILES_PROJECT_ONLY) {
      tag_file_table[0] = project_tags_filename();
      return;
   }
   all_tag_files := tags_filenamea();
   tag_file_table._makeempty();
   boolean tagFileFound:[];
   foreach (auto tag_filename in all_tag_files) {
      if ( tag_filename == "" || tagFileFound._indexin(_file_case(tag_filename)) ) {
         continue;
      }
      tag_file_table[tag_file_table._length()] = tag_filename;
      tagFileFound:[_file_case(tag_filename)] = true;
   }
}

/**
 * Write a string to a log file.
 *
 * @param text       string to display
 * @param filename   full path to the log file.
 *
 * @categories Miscellaneous_Functions
 * @deprecated
 */
_command int fsay(_str text='',_str filename='')
{
   if (filename=='') {
#if __UNIX__
      filename='/tmp/junk.slk';
#else
      filename='c:\junk';
#endif
   }
   if (!gfsay_delete_done) {
      delete_file(filename);
      gfsay_delete_done=true;
   }
   int orig_view_id=0;
   get_window_id(orig_view_id);

   // Preserve the active view in the HIDDEN WINDOW
   p_window_id=VSWID_HIDDEN;
   int orig_hidden_window_view_id=0;
   get_window_id(orig_hidden_window_view_id);

   int temp_view_id=0;
   int junk_view_id=0;
   int status=_open_temp_view(filename,temp_view_id,junk_view_id,'+futf8');
   if (status) {
      if (status!=FILE_NOT_FOUND_RC) {
         return(status);
      }
      _create_temp_view(temp_view_id);
      p_buf_name=filename;
   }
   bottom();
   insert_line(text);
   status=_save_file('+o');

   // Restore the active view in the HIDDEN WINDOW
   activate_window(orig_hidden_window_view_id);

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(status);
}

//This does files on disk
//arg(1)!=''
int _BGReTagFiles()
{
   // if background tagging of other files is disabled, return immedately
   if ( !(def_autotag_flags2&AUTOTAG_FILES) ) {
      //say("_BGRetagFiles: option is off");
      return 0;
   }

   // check that at least 10 seconds have elapsed
   idletime := _idle_time_elapsed();
   if (idletime < 10000) {
      //say("_BGRetagFiles: waiting for ten seconds of inactivity");
      return 0;
   }

   // if we are already tagging something, return immediately
   if ( gBackgroundTaggingRunning ) {
      //say("_BGRetagFiles: recursion guard");
      return 0;
   }

   // if there are already background tagging jobs in process, then
   // return immedately so as not to interfere
   if (tag_get_num_async_tagging_jobs() > 0) {
      //say("_BGRetagFiles: other tagging jobs in process");
      return 0;
   }

   // not yet time to restart tagging, so return immediately
   if (gNextAvailableTagTime > _time('F')) {
      //say("_BGRetagFiles: next run will be at "gNextAvailableTagTime);
      return 0;
   }

   // if we already have a tag file rebuild job running, return immedately
   _str tagDatabasesBeingRebuilt[];
   status := tag_get_async_tag_file_builds(tagDatabasesBeingRebuilt);
   if (status < 0) {
      //say("_BGRetagFiles: error checking on tag file build");
      return status;
   }
   if (tagDatabasesBeingRebuilt._length() > 0) {
      //say("_BGRetagFiles: there is already a rebuild running");
      return 0;
   }

   // get the restart time options
   typeless ActivateInterval = 0;
   typeless MaxFileCheck     = 0; // obsolete
   typeless MaxFileRetag     = 0; // obsolete
   typeless PauseInterval    = 0;
   parse def_bgtag_options with ActivateInterval MaxFileCheck MaxFileRetag PauseInterval;
   if (!isinteger(PauseInterval)) PauseInterval=600;
   if (ActivateInterval < 0 || ActivateInterval=='') {
      //say("_BGRetagFiles: activate interval is 0");
      return(0);
   }

   // have we waited long enough?
   if ((idletime intdiv 1000) < ActivateInterval) {
      //say("_BGRetagFiles: not enough idle time passed");
      return(0);
   }

   // get tag file table again if we don't already have it.
   if ( gTagFileTable._isempty() ) {
      GetTagFileTable(gTagFileTable);
      gCurTagfileIndex=0;
   }

   // check if we are done with scheduling and rebuilding all tag files
   if ( gCurTagfileIndex >= gTagFileTable._length() ) {
      GetTagFileTable(gTagFileTable);
      gCurTagfileIndex=0;
      // set up the next time to run the tagging jobs
      d := DateTime.fromTimeF(_time("F"));
      d = d.add((long)PauseInterval, DT_SECOND);
      gNextAvailableTagTime = d.toTimeF();
      //say("_BGRetagFiles: finished with all tag files, restart at "gNextAvailableTagTime);
      return 0;
   }

   // ok, we are now ready to start background tagging.
   gBackgroundTaggingRunning=1;

   // get the next tag file to be rebuilt
   tag_filename := gTagFileTable[gCurTagfileIndex++];

   // just skip the tag file if hasn't been built already.
   if (tag_filename == "" || !file_exists(tag_filename)) {
      //say("_BGRetagFiles: file does not exist: "tag_filename);
      gBackgroundTaggingRunning=0;
      return 0;
   }

   // start a background tagging job to rebuild this tag file
   status = tag_build_tag_file(tag_filename, VS_TAG_REBUILD_CHECK_DATES|VS_TAG_REBUILD_REMOVE_MISSING_FILES);
   if (status == 0) {
      //say("_BGRetagFiles: REBUILDING: "tag_filename);
      alertId := _GetBuildingTagFileAlertGroupId(tag_filename);
      _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, "Updating: "tag_filename, '', 1);
      if (def_tagging_logging) {
         loggingMessage := nls("Starting background tag file update for '%s1'", tag_filename);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }
   } else if (status < 0) {
      //say("_BGRetagFiles: tag file rebuild failed: "get_message(status)" tag file="tag_filename);
      msg := get_message(status, tag_filename);
      _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_TAGGING_ERROR, msg, 'Tagging', 1);
      gBackgroundTaggingRunning=0;
      if (def_tagging_logging) {
         loggingMessage := nls("Error starting background tag file update for '%s1': %s2", tag_filename, msg);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }
      return status;
   }

   // set up the time to run the next tag file build
   d := DateTime.fromTimeF(_time("F"));
   d = d.add((long)ActivateInterval, DT_SECOND);
   gNextAvailableTagTime = d.toTimeF();
   gBackgroundTaggingRunning = 0;
   //say("_BGRetagFiles: restart at "gNextAvailableTagTime);
   return 0;
}

void _TagFileAddRemove_refresh_table()
{
   GetTagFileTable(gTagFileTable);
}
boolean def_embedded_tagging=true;

void CollateEmbeddedSections(_str (&embedded_buffer_data_by_language):[],  
                             int  (&embedded_buffer_data_length):[], 
                             boolean &gdo_search)
{
   int status=0;
   gdo_search=false;
   embedded_buffer_data_by_language = null;
   embedded_buffer_data_length = null; // length in characters, not bytes as length() returns
   int i,n=tag_get_num_of_embedded();
   if (!def_embedded_tagging) return;
#if 0
   struct Range {
      int m_start_seekpos;
      int m_end_seekpos;
   };
   Range  langIdHash:[][];
#endif
   for (i=0; i<n; ++i) {
      int start_seekpos=0;
      int end_seekpos=0;
      tag_get_embedded(i,start_seekpos,end_seekpos);
      _GoToROffset(start_seekpos);

      // Are we in an embedded context?
      if (p_EmbeddedLexerName=='') {
         status=_clex_find(0,'E');
         if (status < 0) {
            gdo_search = true;
            break;
         }
         start_seekpos = (int)_QROffset();
         if( start_seekpos>end_seekpos ) {
            // This can happen when you have nothing between the <script>...</script>
            // Example:
            //   <script type="text/javascript" language="javascript" src="included_file.js"></script>
            continue;
         }
      }

      // check the embedded mode and see if it has a list-tags function
      typeless orig_values;
      status=_EmbeddedStart(orig_values);
      if (status == 1 && _FindLanguageCallbackIndex('vs%s-list-tags',p_LangId)) {
#if 0
         int len=langIdHash:[p_extension]._length();
         langIdHash:[p_extension][len].m_start_seekpos=start_seekpos;
         langIdHash:[p_extension][len].m_end_seekpos=end_seekpos;
#endif

         // put together the fake buffer data for this item
         _str cur_buffer = '';
         int cur_length = 0;
         if (embedded_buffer_data_by_language._indexin(p_LangId)) {
            cur_buffer = embedded_buffer_data_by_language:[p_LangId];
            cur_length = embedded_buffer_data_length:[p_LangId];
         }

         if (start_seekpos-cur_length<0) {
            cur_length=0;
         }
         // get the text before and the embedded block
         _str white_before = get_text(start_seekpos-cur_length,cur_length);
         _str this_block = get_text(end_seekpos-start_seekpos,start_seekpos);

         // get the text for this embedded section, white out if of the form <% = expr %>
         if (pos('<%[ \t\n\r]*$', white_before, 1, 'r') && pos('^[ \t\n\r]*=', this_block, 1, 'r')) {
            this_block=translate(this_block, "", "\n\r ", " ", 1,true);
         }

         // white out all the text between here and the start of the embedded context
         white_before=translate(white_before, "", "\n\r ", " ", 1,true);

         // append the fake white space and embedded section to the buffer
         cur_buffer = cur_buffer:+white_before:+this_block;
         embedded_buffer_data_by_language:[p_LangId] = cur_buffer;

         // the length would be this:
         //       cur_length+length(white_before)+length(this_block)
         //
         // but using characters(seek positions) instead of bytes, it looks like this:
         //       cur_length+(start_seekpos-cur_length)+(end_seekpos-start_seekpos)
         //
         // which simplifies to:
         embedded_buffer_data_length:[p_LangId] = end_seekpos;

      } else {
         // we also have to do a proc-search
         gdo_search = true;
      }
      if (status==1) {
         _EmbeddedEnd(orig_values);
      }
   }
#if 0
   _str langId=null;
   for (langId._makeempty();;) {
      langIdHash._nextel(langId);
      if (langId._isempty()) break;
      say("index="langId);
   }
#endif
}
