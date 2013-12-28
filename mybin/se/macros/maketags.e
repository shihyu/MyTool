////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49793 $
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
#import "backtag.e"
#import "context.e"
#import "files.e"
#import "listproc.e"
#import "main.e"
#import "slickc.e"
#import "stdcmds.e"
#require "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "toast.e"
#import "se/util/MousePointerGuard.e"
#endregion

defmain()
{
   if ( arg(1)=='' ) {  /* help? */
      _message_box(nls("Arguments: maketags [options] file1 file2 ...\n":+
                       "    -L list\tspecifies list file.\n":+
                       "    -R     \tupdate tag file (checks dates)\n":+
                       "    -D     \tdelete tags\n":+
                       "    -C     \tallow cancellation\n":+
                       "    -O file\tname of output tag file\n":+
                       "    -X     \tbuild symbol cross-reference\n":+
                       "    -N str \tdescription of tag file\n":+
                       "    -U file\trebuild tag file\n":+
                       "    -P     \treport time required to tag\n":+
                       "    -B     \tuse background thread if possible\n":+
                       "    -T     \tfind files recursively in subdirectories\n":+
                       "    -Q     \tquiet\n":+
                       "    -E     \texclude files under directory name"
                  ));
      command_put('make-tags ');
      return(1);
   }

   /* -U option added for rebuilding tag files
      -U <filename> rebuilds specific filename
      also added -Q option for quiet rebuilds */

   /* look for -R and -D option. */
   boolean useThread = false;
   _str wildcardOptions = "";
   _str exclude = '';
   _str update_option='';
   _str list=arg(1);
   _str params='';
   _str output_name=SLICK_TAGS_DB;
   _str output_description='';
   int output_flags=0;
   boolean cancel_option = false;
   boolean quiet = false;
   boolean profile = false;
   int start_time=(int)_time('b');
   int status=0;
   for (;;) {
      _str option=parse_file(list);
      if (option=='') break;
      _str uoption=upcase(option);
      if ( uoption=='-R' || uoption=='+R') {
         update_option='-R';
      } else if ( uoption=='-D' || uoption=='+D') {
         update_option='-D';
      } else if ( uoption=='-C' || uoption=='+C') {
         cancel_option= 1;
      } else if ( uoption=='-O' || uoption=='+O') {
         output_name=parse_file(list);
      } else if ( uoption=='-X' || uoption=='+X') {
         output_flags=VS_DBFLAG_occurrences;
      } else if ( uoption=='-N' || uoption=='+N') {
         output_description=strip(parse_file(list),'B','"');
      } else if ( uoption=='-U' || uoption=='+U') {
         output_name=parse_file(list);
         update_option='-U';
      } else if ( uoption=='-Q' || uoption=='+Q') {
         quiet = true;
      } else if ( uoption=='-P') {
         profile = true;
      } else if ( uoption=='-B') {
         useThread = true;
      } else if (uoption=='-T' || uoption=='+T') {
         params :+= ' 'uoption;
         _maybe_append(wildcardOptions, ' ');
         wildcardOptions :+= "-T";
      } else if (uoption=='-E') {
         exclude = strip(parse_file(list));
         _maybe_append(wildcardOptions, ' ');
         wildcardOptions :+= "-X ";
         wildcardOptions :+= maybe_quote_filename(exclude); 
      } else {
         params :+= ' 'maybe_quote_filename(option);
         _maybe_append(wildcardOptions, ' ');
         wildcardOptions :+= maybe_quote_filename(option);
      }
   }

   if (useThread) {
      return make_tags_threaded(output_name, update_option, output_description, output_flags, wildcardOptions);
   }

   if (update_option == '-U') {
      se.util.MousePointerGuard hour_glass;
      status=RetagFilesInTagFile(absolute(output_name), 
                                 true, false, false, false, 
                                 useThread, quiet, true);
      if (profile) {
         _message_box("Time spent tagging = "(int)_time('b')-start_time" ms");
      }
      return status;
   }

   se.util.MousePointerGuard hour_glass;
   int orig_def_autotag_flags;
   orig_def_autotag_flags=def_autotag_flags2;
   def_autotag_flags2=0;
   // make_tags2 calls load_files which needs an editor control
   status= _mdi.p_child.make_tags2(params,cancel_option,update_option,output_name,output_description,output_flags,quiet,useThread,exclude);
   def_autotag_flags2=orig_def_autotag_flags;
   if (profile) {
      _message_box("Time spent tagging = "(int)_time('b')-start_time" ms");
   }
   return(status);
}

static int make_tags_threaded(_str output_name, _str update_option, 
                              _str dbDescription, int dbFlags,
                              _str wildcardOptions)
{
   rebuildFlags := 0;
   if (dbFlags & VS_DBFLAG_occurrences) {
      rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
   }
   if (update_option == '-R') {
      rebuildFlags |= VS_TAG_REBUILD_CHECK_DATES;
   } else {
      rebuildFlags |= VS_TAG_REBUILD_FROM_SCRATCH;
   }

   // need to do somethign with
   // _str output_description='';

   tag_database := absolute(output_name);
   directoryPath := _strip_filename(tag_database, 'N');

   boolean tag_file_already_exists=false;
   int status=0;
   if ( update_option=='-R' || update_option=='-D') {
      tag_file_already_exists=1;
      //_message_box('make_tags2: loading file 'tag_database);
      status=tag_open_db(tag_database);
      if ( status==FILE_NOT_FOUND_RC ) {
         message(nls('This option requires that "%s" exists',tag_database));
         return(status);
      } else if (status < 0) {
         message(nls("Error reading tag file '%s'",tag_database)". "get_message(status));
         return(status);
      }
   } else {
      status=tag_read_db(tag_database);
      if (status >= 0) {
         tag_file_already_exists=1;
      }
      //tag_close_db(tag_database);
      status=tag_create_db(tag_database);
      if ( status < 0 ) {
         message('Could not create "'tag_database'"');
         return(status);
      }
   }
   if (dbDescription!='') {
      tag_set_db_comment(dbDescription);
   }
   if (dbFlags!=0) {
      tag_set_db_flags(dbFlags);
   }

   tag_close_db(tag_database, true);

   if (update_option == '-D') {

      status = tag_remove_files_from_tag_file_in_wildcards(tag_database,
                                                           0,
                                                           directoryPath,
                                                           wildcardOptions);
      if (def_tagging_logging) {
         loggingMessage := nls("Removing files from tag file '%s1' using wildcard specs '%s2'", tag_database, wildcardOptions);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }

   } else if (update_option == '-U') {

      status = tag_build_tag_file(tag_database, rebuildFlags);
      if (def_tagging_logging) {
         loggingMessage := nls("Starting background tag file update for '%s1'", tag_database);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }

   } else if (update_option == '-L') {

      status = tag_build_tag_file_from_list_file(tag_database, rebuildFlags, wildcardOptions);
      if (def_tagging_logging) {
         loggingMessage := nls("Building tag file '%s1' using list file '%s2'", tag_database, wildcardOptions);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }

   } else {

      status = tag_build_tag_file_from_wildcards(tag_database,
                                                 rebuildFlags, 
                                                 directoryPath,
                                                 wildcardOptions);
      if (def_tagging_logging) {
         loggingMessage := nls("Building tag file '%s1' from wildcard specs '%s2'", tag_database, wildcardOptions);
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }

   }

   if (status == 0) {
      alertId := _GetBuildingTagFileAlertGroupId(tag_database);
      _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, alertId, "Updating: "tag_database, '', 1);
      call_list("_LoadBackgroundTaggingSettings");
   } else if (status < 0) {
      msg := get_message(status, tag_database);
      _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_TAGGING_ERROR, msg, "Tag file build", 1);
   }

   return status;
}

static int make_tags2(_str params,boolean cancel_option,
                       _str option2,_str tag_dbname,
                       _str tag_dbdescription, int tag_dbflags,
                       boolean quiet=false, boolean useThread=false,
                       _str exclude='')
{
   tag_dbname=absolute(strip(tag_dbname,'B','"'));
   // ask if they want to blow away old style tags files
   if (file_eq(_strip_filename(tag_dbname, "P"),SLICK_TAGS_DB)) {
      _str old_filename=_strip_filename(tag_dbname, "N") :+ SLICK_TAGS_FILE;
      if (file_match('-p 'maybe_quote_filename(old_filename),1) != '' &&
          file_match('-p 'maybe_quote_filename(tag_dbname),1) == ''
          ) {
         int btn=IDYES;
         if (!quiet) {
            btn = _message_box(nls("Delete old style tag file: %s?%s?", old_filename), '', MB_YESNOCANCEL|MB_ICONQUESTION,IDNO);
         }
         if (btn!=IDYES && btn!=IDNO) {
            tag_close_db(tag_dbname,1);
            return(1);
         }
         if (btn==IDYES) {
            rc=delete_file(old_filename);
            if ( rc ) {
               message('Could not delete "'old_filename'"');
               return(1);
            }
         }
         rc=0;
      }
   }
   boolean tag_file_already_exists=false;
   int status=0;
   if ( option2=='-R' || option2=='-D') {
      tag_file_already_exists=1;
      //_message_box('make_tags2: loading file 'tag_dbname);
      status=tag_open_db(tag_dbname);
      if ( status==FILE_NOT_FOUND_RC ) {
         message(nls('This option requires that "%s" exists',tag_dbname));
         return(status);
      } else if (status < 0) {
         message(nls("Error reading tag file '%s'",tag_dbname)". "get_message(status));
         return(status);
      }
   } else {
      status=tag_read_db(tag_dbname);
      if (status >= 0) {
         tag_file_already_exists=1;
      }
      //tag_close_db(tag_dbname);
      status=tag_create_db(tag_dbname);
      if ( status < 0 ) {
         message('Could not create "'tag_dbname'"');
         return(status);
      }
   }
   if (tag_dbdescription!='') {
      tag_set_db_comment(tag_dbdescription);
   }
   if (tag_dbflags!=0) {
      tag_set_db_flags(tag_dbflags);
   }
   _str list_view_id='';
   _str list_stack='';
   _str path_prefix='';

   int file_view_id=0;
   int orig_view_id=_create_temp_view(file_view_id);
   int orig_use_timers=_use_timers;
   int orig_def_actapp=def_actapp;
   def_actapp=0;
   _use_timers=0;
   int buildform_wid=0;
   if (cancel_option) {
      buildform_wid=show_cancel_form(_GetBuildingTagFileMessage(useThread),null,true,true);
   }
   status=make_tags3(params,option2,cancel_option,list_view_id,path_prefix, tag_dbname,quiet,buildform_wid,file_view_id);
   if (status!=COMMAND_CANCELLED_RC) {
      status=make_tags4(option2=='-D',cancel_option,file_view_id,tag_dbname,quiet,buildform_wid,useThread,exclude);
   }

   _use_timers=orig_use_timers;
   def_actapp=orig_def_actapp;
   if (cancel_option && !cancel_form_cancelled()) {
      close_cancel_form(buildform_wid);
   }

   _delete_temp_view(file_view_id);
   activate_window(orig_view_id);

   if ( status ) {
      tag_close_db(tag_dbname);
      return(status);
   }
   tag_close_db(tag_dbname,1);
   if (useThread) {
      message(nls("Tag file '%s' will finish building in the background.", tag_dbname));
   } else {
      message(nls('Finished. Tag file is %s.', tag_dbname));
   }
   if (pos(PATHSEP:+tag_dbname:+PATHSEP,PATHSEP:+tags_filename():+PATHSEP,1,_fpos_case)) {
      if (tag_file_already_exists) {
         _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tag_dbname);
      } else {
         _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,tag_dbname,'A');
      }
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   } else {
      // really close the database here, it is not in the tag file path
      tag_close_db(tag_dbname);
   }
   return(status);
}
static int make_tags3(_str params,_str option2,
                      boolean cancel_option,typeless list_view_id,
                      _str path_prefix, _str tag_db_name,
                      boolean quiet=false,
                      int buildform_wid=0, int file_view_id=0)
{
   int status=0;
   _str tree_option='';
   for (;;) {
      if (cancel_option) {
         if (cancel_form_cancelled(0)) {
            tag_close_db(tag_db_name);
            delete_file(tag_db_name);
            message(nls("Command Canceled"));
            status = COMMAND_CANCELLED_RC;
            break;
         }
         cancel_form_set_labels(buildform_wid,null,"Searching for files...");
      }
      if ( list_view_id!='' && params=='' ) {
         activate_window(list_view_id);
         status=down();
         if ( status ) {
            list_view_id='';
            return(0);
         }
         get_line(params);
         if ( params=='' ) {
            continue;
         }
         params=strip(params);
         _str ch1=substr(params,1,1);
         if (ch1!="-" && ch1!="+") {
            params=maybe_quote_filename(params);
         }
      }
      _str filename=parse_file(params);
      filename=strip(filename,"B",'"');
      if ( substr(filename,1,1)=='@' ) {
         params=maybe_quote_filename(substr(filename,2))" "params;
         filename='-L';
      }
      _str option=upcase(filename);
      _str list_switches='+d ';
      if (option=='+B') {
         list_switches='+b ';
         option='-L';
      }
      if ( option=='-L' || option=='+L') {  /* specify list? */
         filename=parse_file(params);
         filename=translate(filename,FILESEP,FILESEP2);
         if ( _strip_filename(filename,'D'):==filename && /* Not absolute spec? */
             substr(filename,1,1):!=FILESEP ) {
            filename=path_prefix:+filename;
         }
         filename=strip(filename,"B",'"');
         //_message_box('make_tags3: loading ' filename);
         int new_list_view_id;
         int orig_view_id;
         // 2/8/2007 - rb
         // Add +ro switch to cause _open_temp_view to only attempt to open
         // file with read permissions. We did this for 2 reasons:
         // 1. Microsoft Windows Vista does not like applications that attempt
         // to open files under Program Files/ with write permissions. When the
         // product first starts, it attempts to tag runtimes which are more than
         // likely under Program Files/.
         // 2. When tagging large numbers of files, this will be faster since
         // we are only performing 1 open instead of 2 (once to determine
         // writeability, once to re-open with minimal permissions).
         int status2=_open_temp_view(filename,new_list_view_id,orig_view_id,list_switches' +ro');
         if (status2 ) {
            _str msg;
            if ( status2==FILE_NOT_FOUND_RC ) {
               msg=nls("File '%s' not found",filename)'.';
            } else {
               msg=get_message(status2);
            }
            message(nls("Error reading list '%s'",filename)". "msg);
            status=1;
            break;
         }
         _str new_path_prefix='';
         if ( path_prefix!='' ) {
            new_path_prefix=substr(path_prefix,1,length(path_prefix)-1);
         }
         new_path_prefix=_strip_filename(filename,'N');

         top();up();
         status=make_tags3(params,option2,cancel_option,new_list_view_id,new_path_prefix, tag_db_name, false, buildform_wid, file_view_id);
         _delete_temp_view(new_list_view_id);
         activate_window(orig_view_id);
         if ( status ) {
            return(status);
         }
         params='';
         continue;
      } else if (option=='-T' || option=='+T'){
         tree_option='+T';
         continue;
      }
      if ( filename=='' ) {
         break;
      }
      filename=translate(filename,FILESEP,FILESEP2);
      if ( _strip_filename(filename,'D'):==filename && /* Not absolute spec? */
          substr(filename,1,1):!=FILESEP ) {
         filename=path_prefix:+filename;
      }
      int temp_view_id=0,orig_view_id=0;
      _str match="";
      if ( (iswildcard(filename) && !file_exists(filename)) || tree_option!='') {
         orig_view_id=_create_temp_view(temp_view_id);
         insert_file_list('-dv +p 'tree_option' 'maybe_quote_filename(filename));
         top();
         if (p_line > 0) {
            get_line(match);match=strip(match);
         }
         //match=file_match('-pd 'tree_option' 'maybe_quote_filename(filename),1);
      } else {
         match=filename;
      }
      for (;;) {
         if (cancel_option) {
            if (cancel_form_cancelled(0)) {
               tag_close_db(tag_db_name);
               delete_file(tag_db_name);
               message(nls("Command Canceled"));
               status = COMMAND_CANCELLED_RC;
               break;
            }
         }
         if ( match=='' ) {
            break;
         }

         int before_file_view_id=0;
         get_window_id(before_file_view_id);
         activate_window(file_view_id);
         insert_line(match);
         activate_window(before_file_view_id);

         if (temp_view_id) {
            activate_window(temp_view_id);
            if (down()) {
               match="";
            } else {
               get_line(match);match=strip(match);
            }
         }  else {
            match="";
         }
         //_message_box('filename='filename', match='match);
      }
      if (temp_view_id) {
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
      }
      if ( status ) {
         break;
      }
   }
   if (status) {
      if (list_view_id!='') {
         activate_window(list_view_id);
         list_view_id='';
      }
   }

   return(status);
}
static int make_tags4(boolean delete_option,boolean cancel_option,
                      int list_view_id,_str tag_db_name,
                      boolean quiet=false,int buildform_wid=0,
                      boolean useThread=false,_str exclude='')
{
   int status=0;
   _str filename='';
   int not_tagged_count = 0;
   _str not_tagged_list = '';
   boolean not_tagged_more = false;
   int max_label2_width=1000;
   if (cancel_option && !cancel_form_cancelled(0)) {
      max_label2_width=cancel_form_max_label2_width(buildform_wid);
   }

   activate_window(list_view_id);
   top();up();

   for (;;) {

      activate_window(list_view_id);
      if (down()) {
         status=0;
         break;
      }

      get_line(filename);
      if ( filename=='' ) {
         continue;
      }
      filename=strip(filename);
      filename=translate(filename,FILESEP,FILESEP2);

      if (exclude != '' && (pos(FILESEP:+exclude:+FILESEP, filename, 1) != 0)) {
         continue;
      }

      if (cancel_option) {
         boolean wasCancelled = cancel_form_cancelled();
         if (!wasCancelled) {
            if (cancel_form_progress(buildform_wid,p_line-1,p_Noflines)) {
               _str sfilename=buildform_wid._ShrinkFilename(filename,max_label2_width);
               cancel_form_set_labels(buildform_wid,null,sfilename);
            }
         }
         if (wasCancelled) {
            tag_close_db(tag_db_name);
            delete_file(tag_db_name);
            message(nls("Command Canceled"));
            status = COMMAND_CANCELLED_RC;
            break;
         }
      }

      // delete old tags before adding new ones
      if (delete_option) {
         if (!cancel_option) {
            message(nls("Deleting tags for '%s'..."filename));
         }
         status = tag_remove_from_file(absolute(filename));
         if (status) {
            if (status!=BT_RECORD_NOT_FOUND_RC) {
               message(nls("Error deleting tags in '%s'",filename));
               status=1;
               break;
            } else {
               status=0;
            }
         }

      } else {

         if (!cancel_option) {
            message(nls("Searching '%s'...",filename));
         }

         int add_status = add_tags(filename,quiet,useThread);
         if (add_status && add_status!=COMMAND_CANCELLED_RC) {
            not_tagged_count++;
            if (not_tagged_list == '') {
               not_tagged_list = maybe_quote_filename(filename);
            } else if (length(not_tagged_list) < 1000) {
               strappend(not_tagged_list, ', 'maybe_quote_filename(filename));
            } else {
               not_tagged_more = true;
            }
         }

         if (add_status==COMMAND_CANCELLED_RC) {
            tag_close_db(tag_db_name);
            delete_file(tag_db_name);
            message(nls("Command Canceled"));
            status = COMMAND_CANCELLED_RC;
            break;
         }
      }
   }

   // report if any files not found or tagged
   if (not_tagged_count > 0) {
      if (not_tagged_more) {
         strappend(not_tagged_list, ', ...');
      }
      _str tmp = "file was";
      if (not_tagged_count > 1) tmp = "files were";
      if (!quiet) {
         _message_box(nls("%s %s not tagged:\n\n%s",
                          not_tagged_count,tmp,not_tagged_list));
      }
   }

   // return result
   return(status);
}
static int add_tags(_str filename, boolean quiet, boolean useThread=false)
{
   abs_filename := absolute(filename);
   _str lang=_Filename2LangId(abs_filename);
   if (!_is_background_tagging_supported(lang)) {
      useThread=false;
   }

   index := _FindLanguageCallbackIndex('vs%s_list_tags',lang);
   if (index <= 0) {
      useThread=false;
   }

   if (!useThread) {
      tag_set_date(abs_filename);
   }

   setup_index:=0;
   check_and_load_support(lang,setup_index,abs_filename);
   tag_set_language(abs_filename,lang);

   ltf_flags := (tag_get_db_flags()&VS_DBFLAG_occurrences)? VSLTF_LIST_OCCURRENCES:0;
   status := 0;
   result := 0;
   do_embedded := false;
   insert_file_started := false;
   if ( index ) {

      if (!useThread) {
         insert_file_started = true;
         status = tag_insert_file_start(abs_filename);
         if (status == BT_RECORD_NOT_FOUND_RC) {
            status = 0;
         } else if (status) {
            message(nls("Error searching for tags in '%s'",filename));
            status=1;
         }
      }

      if (!useThread && (ltf_flags & VSLTF_LIST_OCCURRENCES)) {
         result = tag_occurrences_start(abs_filename);
      }
      if (useThread) {
         ltf_flags |= VSLTF_ASYNCHRONOUS;
      }
      tag_lock_context();
      tag_clear_embedded();

      status=call_index(0,abs_filename,lang,ltf_flags,index);
      if (status) {
         if (status != COMMAND_CANCELLED_RC) {
            if (status==FILE_NOT_FOUND_RC) {
               message(nls("File '%s' not found",filename));
            } else {
               message(nls("Error reading '%s'",filename)". "get_message(status));
            }
         }
      }

      if (!useThread && (ltf_flags & VSLTF_LIST_OCCURRENCES) && !result) {
         result=tag_occurrences_end(abs_filename);
      }

      if (!status) status=result;
      do_embedded=0;
      if (!useThread) {
         do_embedded=(tag_get_num_of_embedded() > 0);
      }
      tag_unlock_context();

      // drops through and call embedded proc search
      if ( useThread || status || !do_embedded ) {

         if (!useThread) {
            status = tag_insert_file_end();
            if (status == BT_RECORD_NOT_FOUND_RC) {
               status = 0;
            } else if (status) {
               message(nls("Error deleting stale tags in '%s'",filename));
               status=1;
            }
         }

         return(status);
      }
      // drops through and call embedded proc search
   }

   index = _FindLanguageCallbackIndex('%s-proc-search',lang);
   /* Search for Pascal functions */
   if ( !do_embedded && !index) {
      if (lang == 'fundamental' || lang=='mak' || lang=='xml') {
         return(0);
      }

      // see if there is a load-tags function
      fext := lowcase(_get_extension(filename));
      index = find_index('vs'fext'-load-tags',PROC_TYPE);
      if (index) {

         status = tag_insert_file_start(abs_filename);
         if (status == BT_RECORD_NOT_FOUND_RC) {
            status = 0;
         } else if (status) {
            message(nls("Error searching for tags in '%s'",filename));
            status=1;
         }

         tag_set_date(abs_filename);
         tag_set_language(abs_filename,lang);
         if (ltf_flags & VSLTF_LIST_OCCURRENCES) {
            result = tag_occurrences_start(abs_filename);
         }
         cancelStatus := 0;
         status=call_index(abs_filename,ltf_flags&VSLTF_LIST_OCCURRENCES,index);
         if (status) {
            if (status != COMMAND_CANCELLED_RC) {
               message(nls("Error "status" reading '%s'",filename));
            } else {
               cancelStatus = status;
            }
         }
         if (ltf_flags & VSLTF_LIST_OCCURRENCES) {
            result=tag_occurrences_end(abs_filename);
         }

         status = tag_insert_file_end();
         if (status == BT_RECORD_NOT_FOUND_RC) {
            status = 0;
         } else if (status) {
            message(nls("Error deleting stale tags in '%s'",filename));
            status=1;
         }
         
         if (cancelStatus < 0) {
            return cancelStatus;
         }
         return status;
      }

      // don't complain about this
      if (quiet) {
         return(0);
      }

      message(nls("No tagging support function for extension '%s'",lang));
      return(1);
   }

   //_message_box('add_tags: editing file ' filename);
   _str tag_filename=tag_current_db();
   int view_id,junk_view_id;
   // 2/8/2007 - rb
   // Add +ro switch to cause _open_temp_view to only attempt to open
   // file with read permissions. We did this for 2 reasons:
   // 1. Microsoft Windows Vista does not like applications that attempt
   // to open files under Program Files/ with write permissions. When the
   // product first starts, it attempts to tag runtimes which are more than
   // likely under Program Files/.
   // 2. When tagging large numbers of files, this will be faster since
   // we are only performing 1 open instead of 2 (once to determine
   // writeability, once to re-open with minimal permissions).
   openStatus := _open_temp_view(abs_filename,view_id,junk_view_id,'+d +ro');
   if ( openStatus ) {
      _str msg;
      if ( openStatus==FILE_NOT_FOUND_RC ) {
         msg=nls("File '%s' not found",filename)".";
      } else {
         msg=get_message(openStatus);
      }
      message(nls('Error reading file "%s"',filename)'. 'msg);

      if (insert_file_started) {
         status = tag_insert_file_end();
         if (status == BT_RECORD_NOT_FOUND_RC) {
            status = 0;
         } else if (status) {
            message(nls("Error deleting stale tags in '%s'",filename));
            status=1;
         }
      }

      return(openStatus);
   }
   _SetEditorLanguage(lang);
   tag_open_db(tag_filename);

   if (!insert_file_started) {
      status = tag_insert_file_start(abs_filename);
      if (status == BT_RECORD_NOT_FOUND_RC) {
         status = 0;
      } else if (status) {
         message(nls("Error searching for tags in '%s'",filename));
         status=1;
      }
   }

   get_window_id(view_id);
   _str proc_name='';
   searchStatus := 0;
   _tag_pass=1;
   if (do_embedded) {
      searchStatus = _EmbeddedProcSearch(0,proc_name,1,lang,index);
   } else {
      searchStatus = call_index(proc_name,1,lang,index);
   }
   for (;;) {
      if ( searchStatus ) {
         break;
      }
      // this basically accomplishes doing a tag_insert_extension()
      // for the extension associated with the embedded context
      tag_set_embedded_language();
      // now insert the tag
      int tag_flags;
      _str signature = '';
      _str return_type = '';
      _str tag_name = '';
      _str class_name = '';
      _str type_name = '';
      tag_tree_decompose_tag(proc_name, tag_name, class_name, type_name, tag_flags, signature, return_type);
      if (tag_name :!= "") {
         _str s = '';
         if (return_type != '' || signature != '') {
            s = return_type :+ VS_TAGSEPARATOR_args :+ signature;
         }
         status = tag_insert_tag(tag_name, type_name, abs_filename,
                                 p_line, class_name, tag_flags, s);
      }

      proc_name="";
      if (do_embedded) {
         searchStatus =_EmbeddedProcSearch(0,proc_name,0,lang,index);
      } else {
         searchStatus = call_index(proc_name,0,lang,index);
      }
   }
   _delete_temp_view();

   status = tag_insert_file_end();
   if (status == BT_RECORD_NOT_FOUND_RC) {
      status = 0;
   } else if (status) {
      message(nls("Error deleting stale tags in '%s'",filename));
      status=1;
   }

   return(0);

}
