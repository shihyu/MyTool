////////////////////////////////////////////////////////////////////////////////////
// Copyright 2013 SlickEdit Inc. 
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
#include 'slick.sh'
#include 'svc.sh'
#import 'diff.e'
#import 'dir.e'
#import 'files.e'
#import 'fileman.e'
#import 'guiopen.e'
#import "help.e"
#import 'historydiff.e'
#import 'listbox.e'
#import 'main.e'
#import 'mprompt.e'
#import 'picture.e'
#import 'projconv.e'
#import 'sellist2.e'
#import 'stdcmds.e'
#import 'stdprocs.e'
#import 'treeview.e'
#import 'svcrepobrowser.e'
#import 'svcupdate.e'
#import 'varedit.e'
#import 'wkspace.e'
#import 'xml.e'
#require 'se/datetime/DateTime.e'
#require 'se/datetime/DateTimeInterval.e'
#endregion Imports

using se.datetime.DateTime;
using se.datetime.DateTimeInterval;


struct FILE_INFO {
   se.datetime.DateTime date;
   _str filename;
};

const DELTA_ELEMENT_MOST_RECENT     = "M";
const DELTA_ELEMENT_NODE            = "D";
const DELTA_ATTR_DATE               = "D";
const DELTA_ATTR_TIME               = "T";
const DELTA_ELEMENT_MOST_RECENT_OLD = "MostRecent";
const DELTA_ELEMENT_NODE_OLD        = "Delta";
const DELTA_ATTR_DATE_OLD           = "Date";
const DELTA_ATTR_TIME_OLD           = "Time";

static _str getDateForIndex(int xmlhandle,int index,_str ext)
{
   dateAttrName := DELTA_ATTR_DATE_OLD;
   timeAttrName := DELTA_ATTR_TIME_OLD;
   if ( _file_eq(ext,DELTA_ARCHIVE_EXT) ) {
      dateAttrName = DELTA_ATTR_DATE;
      timeAttrName = DELTA_ATTR_TIME;
   }
   if (index<0) {
      return "";
   }
   date := _xmlcfg_get_attribute(xmlhandle,index,dateAttrName);
   date :+= " " _xmlcfg_get_attribute(xmlhandle,index,timeAttrName);
   return date;
}

static void addToDateTable(_str date,STRHASHTAB &dateTable,_str filename)
{
   if ( !dateTable._indexin(date) ) {
      dateTable:[date] = _maybe_quote_filename(filename);
   } else {
      dateTable:[date] :+= ' '_maybe_quote_filename(filename);
   }
}

static _str getSourceFilenameFromDeltaFilename(_str basePath,_str deltaFilename)
{
   deltaFilename = substr(deltaFilename,length(basePath)+1);
   STRHASHTAB driveLetters;
   if (_isWindows()) {
      if (pos(FILESEP,deltaFilename)==2) {
         // Figure out if we have something that should have a drive letter
         dl := substr(deltaFilename,1,1);
         if (driveLetters:[dl]!=null) {
            if (file_match('+p 'dl,1)!="") {
               driveLetters:[dl] = "";
               deltaFilename = substr(deltaFilename,1,1)':'substr(deltaFilename,2);
            }
         } else {
            deltaFilename = substr(deltaFilename,1,1)':'substr(deltaFilename,2);
         }
      } else if ( pos(FILESEP,deltaFilename)==4 && 
           _file_eq(substr(deltaFilename,1,3),"ftp") ) {
         deltaFilename = _ConfigPath():+deltaFilename;
      } else {
         deltaFilename = '\\'deltaFilename;
      }
   } else {
      if ( pos(FILESEP,deltaFilename)==4 && 
           _file_eq(substr(deltaFilename,1,3),"ftp") ) {
         deltaFilename = _ConfigPath():+deltaFilename;
      } else {
         // For UNIX this will be the root directory
         deltaFilename = '/' :+ deltaFilename;
      }
   }
   deltaFilename = _strip_filename(deltaFilename,'E');
   return deltaFilename;
}

static void getNewArchiveHT(FILE_INFO (&newArchiveHT):[],_str path)
{
   origWID := _create_temp_view(auto tempWID);
   insert_file_list("+t +v +p "_maybe_quote_filename(path:+"*"DELTA_ARCHIVE_EXT));
   top();up();
   STRHASHTAB driveLetters;
   while (!down()) {
      get_line(auto line);
      FILE_INFO temp;
      temp.filename = substr(line,DIR_FILE_COL);
      if (_isWindows()) {
         if (pos(FILESEP,temp.filename)==2) {
            // Figure out if we have something that should have a drive letter
            dl := substr(temp.filename,1,1);
            if (driveLetters:[dl]!=null) {
               if (file_match('+p 'dl,1)!="") {
                  driveLetters:[dl] = "";
                  temp.filename = substr(temp.filename,1,1)':'substr(temp.filename,2);
               }
            } else {
               temp.filename = substr(temp.filename,1,1)':'substr(temp.filename,2);
            }
         }
      }
      date := substr(line,DIR_DATE_COL,DIR_DATE_WIDTH);
      parse date with auto month '-' auto day '-' auto year;
      time := substr(line,DIR_TIME_COL,DIR_TIME_WIDTH);
      parse time with auto hh ":" auto mm;
      if (_last_char(mm)=='p') {
         int tempMM = (int)substr(mm,1,2);
         tempMM += 12;
         mm= tempMM;
      }else{
         mm = substr(mm,1,2);
      }
      hhint := (int)strip(hh);
      mmint := (int)strip(mm);
      yearint := (int)strip(year);
      monthint := (int)strip(month);
      dayint := (int)strip(day);
      
      se.datetime.DateTime tempDate(yearint,monthint,dayint,hhint,mmint);

      temp.date = tempDate;
      dtstr := temp.date.toString();
      newArchiveHT:[_file_case(temp.filename)] = temp;
   }
   p_window_id = origWID;
   _delete_temp_view(tempWID);
}

const DELTA_ARCHIVE_EXT_PRE22 = ".vsdelta";
static void getFileList(_str path,FILE_INFO (&fileList)[])
{
   FILE_INFO newArchiveHT:[];
   // First get all the new new archive extension, and put that in a hashtable
   // indexed by the whole path.
   getNewArchiveHT(newArchiveHT,path);
   origWID := _create_temp_view(auto tempWID);
   // Now list all the files with the old archive extension and list those like
   // we always have.
   insert_file_list("+t +v +p "_maybe_quote_filename(path:+"*"DELTA_ARCHIVE_EXT_PRE22));
   top();up();
   STRHASHTAB driveLetters;
   while (!down()) {
      get_line(auto line);
      FILE_INFO temp;
      curFilename := substr(line,DIR_FILE_COL);
      newArchiveExtFilename := _file_case((_strip_filename(curFilename,'E'):+DELTA_ARCHIVE_EXT));
      // Build the same filename with the new extension. See if we have this
      // with a new archive extension already
      temp = newArchiveHT:[newArchiveExtFilename];
      if ( temp==null ) {
         // Add the information as we always have.  Anything we use will be 
         // upgraded as soon as we touch it.
         temp.filename = curFilename;
         if (_isWindows()) {
            if (pos(FILESEP,temp.filename)==2) {
               // Figure out if we have something that should have a drive letter
               dl := substr(temp.filename,1,1);
               if (driveLetters:[dl]!=null) {
                  if (file_match('+p 'dl,1)!="") {
                     driveLetters:[dl] = "";
                     temp.filename = substr(temp.filename,1,1)':'substr(temp.filename,2);
                  }
               } else {
                  temp.filename = substr(temp.filename,1,1)':'substr(temp.filename,2);
               }
            }
         }
         date := substr(line,DIR_DATE_COL,DIR_DATE_WIDTH);
         parse date with auto month '-' auto day '-' auto year;
         time := substr(line,DIR_TIME_COL,DIR_TIME_WIDTH);
         parse time with auto hh ":" auto mm;
         if (_last_char(mm)=='p') {
            int tempMM = (int)substr(mm,1,2);
            tempMM += 12;
            mm= tempMM;
         }else{
            mm = substr(mm,1,2);
         }
         hhint := (int)strip(hh);
         mmint := (int)strip(mm);
         yearint := (int)strip(year);
         monthint := (int)strip(month);
         dayint := (int)strip(day);

         se.datetime.DateTime tempDate(yearint,monthint,dayint,hhint,mmint);

         temp.date = tempDate;
         dtstr := temp.date.toString();
         // Remove ".vsdelta"
         // temp.filename = _strip_filename(temp.filename,'E');
      } else {
         // Delete this item from the hashtable, we'll add it below
         newArchiveHT._deleteel(newArchiveExtFilename);
      }

      // Whether it came from the hashtable or we got the information from an
      // old archive, add it.
      ARRAY_APPEND(fileList,temp);
   }
   // Whatever is left in the hashtable, add that to the array.  We have to
   // do check for null because of the way it was assigned above.
   foreach ( auto filename => auto curTemp in newArchiveHT) {
      if (curTemp!=null) {
         ARRAY_APPEND(fileList,curTemp);
      }
   }
   p_window_id = origWID;
   _delete_temp_view(tempWID);
}

int _repairBHFile(_str filename)
{
   status := _open_temp_view(filename,auto tempWID,auto origWID);
   if ( status ) return status;

   _SetEditorLanguage();

   haveMostRecent := true;
   do {
      p_line = 3;  // Put cursor on MostRecent line
      if ( status ) {
         break;
      }
      status = _xml_find_matching_word(false,0x7fffffff);
      if ( status ) {
         haveMostRecent = false;
         break;
      }
   } while (false);
   if ( status ) {
      if ( !haveMostRecent ) {
         p_window_id = origWID;
         _delete_temp_view(tempWID);
         result := _message_box(nls("SlickEdit cannot find the most recent version of the file and will not be able to repair this archive.\n\nWould you like to remove it?"),"",MB_YESNO);
         if ( result == IDYES ) {
            _removeArchive(filename);
         }
         return -1;
      }
   }
   // Move down and postion on what should be first <Delta> entry
   markid := _alloc_selection();

   // For some reason, blank lines get inserted after the most recent version.
   // Skip over them.
   nextLine := "";
   for (;;) {
      down();
      get_line(nextLine);
      if ( nextLine!="" ) break;
   }
   _select_line(markid);
   for (;;) {
      get_line(auto beginline);
      if ( substr(beginline,1,7)!="<Delta " ) break;
      status = _xml_find_matching_word(false,0x7fffffff);
      if ( status ) break;
      down();
   }
   if ( status ) {
      // If we had a status, delete everything to the bottom
      bottom(); // This will take us to the </DeltaFile> entry
      up();     // this should be the last </Delta> entry
      _select_line(markid);
      _delete_selection(markid);
      status = saveArchive(p_window_id,filename);
   }
   _free_selection(markid);
   p_window_id = origWID;
   _delete_temp_view(tempWID);
   return status;
}

static int saveArchive(int archiveWID,_str filename)
{
   origWID := p_window_id;
   p_window_id = archiveWID;
   int status;
   if (_isUnix()) {
      status = _chmod('u+w '_maybe_quote_filename(filename));
   } else {
      status = _chmod('-r '_maybe_quote_filename(filename));
   }
   if ( status ) return status;
   status = _save_file('+o 'filename);
   if ( status ) return status;
   if (_isUnix()) {
      status = _chmod('u-w '_maybe_quote_filename(filename));
   } else {
      status = _chmod('+r '_maybe_quote_filename(filename));
   }
   p_window_id = origWID;
   return status;
}

int _removeArchive(_str filename)
{
   int status;
   if (_isUnix()) {
      status = _chmod('u+w '_maybe_quote_filename(filename));
   } else {
      status = _chmod('-r '_maybe_quote_filename(filename));
   }
   if ( status ) return status;
   status = delete_file(filename);
   if ( status ) return status;
   if (_isUnix()) {
      status = _chmod('u-w '_maybe_quote_filename(filename));
   } else {
      status = _chmod('+r '_maybe_quote_filename(filename));
   }
   return status;
}

static int addItemToTable(int xmlhandle,_str basePath,_str filename,STRHASHTAB &dateTable)
{
   ext := _get_extension(filename,true);
   mr := DELTA_ELEMENT_MOST_RECENT_OLD;
   dn := DELTA_ELEMENT_NODE_OLD;
   if ( _file_eq(ext,DELTA_ARCHIVE_EXT) ) {
      mr = DELTA_ELEMENT_MOST_RECENT;
      dn = DELTA_ELEMENT_NODE;
   }
   index := _xmlcfg_find_simple(xmlhandle,"//"mr);
   if (index<0) return index;
   date := getDateForIndex(xmlhandle,index,ext);
   sourceFilename := getSourceFilenameFromDeltaFilename(basePath,filename);
   addToDateTable(date,dateTable,sourceFilename);
   _xmlcfg_find_simple_array(xmlhandle,"//"dn,auto arrayIndex);
   indexArrayLen := arrayIndex._length();
   for ( j:=0;j<indexArrayLen;++j ) {
      date = getDateForIndex(xmlhandle,(int)arrayIndex[j],ext);
      addToDateTable(date,dateTable,sourceFilename);
   }
   return 0;
}

_command void rebuild_backup_history_log() name_info(',')
{
   if (!_haveBackupHistory()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Backup History");
      return;
   }
   basePath := _getBackupHistoryPath();
   origMaxArraySize:=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,MAXINT);
   mou_hour_glass(true);
   _maybe_append_filesep(basePath);
   FILE_INFO fileList[];
   getFileList(basePath,fileList);

   len := fileList._length();
   STRHASHTAB dateTable;
   for (i:=0;i<len;++i) {
      filename := fileList[i].filename;
      xmlhandle := _xmlcfg_open(filename,auto status);
      if ( status ) {
         result := _message_box(nls("Could not open '%s', it may be damaged.\n\nWould you like to try to repair it now?",filename),"",MB_YESNO);
         if ( result==IDYES ) {
            status = _repairBHFile(filename);
            if ( !status ) {
               xmlhandle = _xmlcfg_open(filename,status);
            }
         }
      }
      if ( xmlhandle>=0 ) {
         status = addItemToTable(xmlhandle,basePath,filename,dateTable);
         if (status) break;
         _xmlcfg_close(xmlhandle);
      }
   }
   STRARRAY dateArray;
   foreach (auto key => auto value in dateTable) {
      ARRAY_APPEND(dateArray,key);
   }
   dateArray._sort();
   saveLogFilename := basePath:+SAVELOG_FILE;
   xmlhandle := _xmlcfg_create(saveLogFilename,VSENCODING_UTF8);
   _xmlcfg_delete(xmlhandle,TREE_ROOT_INDEX,true);

   saveLogIndex := _xmlcfg_add(xmlhandle,TREE_ROOT_INDEX,"SaveLog",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);

   foreach (auto curDate in dateArray) {
      curIndex := _xmlcfg_add(xmlhandle,saveLogIndex,"f",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      fileListStr := dateTable:[curDate];
      for (;;) {
         curFile := parse_file(fileListStr);
         if ( curFile=="" ) break;
         // Be sure not to add double quoted files to log
         curFile = strip(curFile,'B','"');
         _xmlcfg_add_attribute(xmlhandle,curIndex,"n",curFile);
         _xmlcfg_add_attribute(xmlhandle,curIndex,"d",curDate);
      }
   }

   _xmlcfg_save(xmlhandle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
   _xmlcfg_close(xmlhandle);
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,origMaxArraySize);
   mou_hour_glass(false);
}

defeventtab _backup_history_browser_form;
void ctlsearch_clear.lbutton_up()
{
   p_prev.p_text = "";
}

void _grabbar_horz.lbutton_down()
{
   // figure out orientation
   min := 0;
   max := 0;

   getGrabbarMinMax(min, max);

   _ul2_image_sizebar_handler(min, max);
}

#if 1
static void getGrabbarMinMax(int &min, int &max)
{
//   typeless (*pposTable):[] = getPointerToPositionTable();

   // use what is saved in the table if we don't know any better
//   if (orientation == '') orientation = (*pposTable):["lastOrientation"];

   min = max = 0;
   min = 2 * ctltree1.p_y;
   max = ctlclose.p_y - min;
}
#endif

static void resizeDialog()
{
   clientHeight := _dy2ly(SM_TWIP,p_active_form.p_client_height);
   clientWidth := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   ybuffer := ctlfilespecs.p_prev.p_y;
   xbuffer := ctlscope.p_prev.p_x;
   ctlscope.p_width = (clientWidth - ctlscope.p_prev.p_x_extent) - 2*ybuffer;

   ctltree1.p_x = ctltree2.p_x = ybuffer;
   ctltree1.p_width = ctltree2.p_width = clientWidth - 2*ybuffer;

   // Some controls on dialog are not currently visible, because they might not
   // be used by first pass
   treeHeight := treeHeight1 := 0;
   if ( ctlscope.p_visible ) {
      ctltree1.p_y = ctlscope.p_y_extent+ybuffer;
   } else {
      ctltree1.p_y = ctlfilespecs.p_y_extent+ybuffer;
   }
   treeHeight1 = _grabbar_horz.p_y - ctltree1.p_y - ybuffer;
   ctltree1.p_height = treeHeight1;

   _grabbar_horz.p_y = ctltree1.p_y_extent+ybuffer;
   restOfDialog := clientHeight - _grabbar_horz.p_y_extent;
   ctlfilesSavedSince.p_y = _grabbar_horz.p_y_extent+ybuffer;
   ctltree2.p_y = ctlfilesSavedSince.p_y_extent+ybuffer;
   treeHeight2 := ((restOfDialog - ctlview.p_height)- ctlfilesSavedSince.p_height) - (4 * ybuffer);
   ctltree2.p_height = treeHeight2;

   ctlview.p_y = ctlrestore.p_y = ctlrebuildSaveLog.p_y = ctlrebuildSaveLog.p_next.p_y = ctldiff.p_y = ctlclose.p_y = ctltree2.p_y_extent+ybuffer;
   _grabbar_horz.p_width = clientWidth;

   ctlfilespecs.p_x = ctlfilespecs.p_prev.p_x_extent + xbuffer;
   sizeBrowseButtonToTextBox(ctlfilespecs.p_window_id, ctlsearch_clear.p_window_id, ctlfilespecs_help.p_window_id, clientWidth);

}

_backup_history_browser_form.on_resize()
{
   resizeDialog();
}

extern void _loadThisWeeksFileDates(int);
extern void _loadOlderFileDates(int,int);
extern void _GetFileTableFromBHBrowser(STRHASHTAB &fileTable);

_str _getBackupHistoryPath()
{
   deltaArchivePath := get_env("VSLICKBACKUP");
   if (deltaArchivePath=="") {
      deltaArchivePath = get_env(_SLICKEDITCONFIG);
      _maybe_append_filesep(deltaArchivePath);
      deltaArchivePath :+= DELTA_DIR_NAME;
   }
   _maybe_append_filesep(deltaArchivePath);
   return deltaArchivePath;
}

static _str getSaveLogFilename()
{
   basePath := _getBackupHistoryPath();
   saveLogFilename := basePath:+SAVELOG_FILE;
   return saveLogFilename;
}

static void loadThisWeeksDatesIntoTree()
{
   saveLogFilename := getSaveLogFilename();
   xmlhandle := _xmlcfg_open(saveLogFilename,auto status);
   needRebuild := false;
   if (status==PATH_NOT_FOUND_RC) {
      _message_box(nls("Path '%s' does not exist.  It will be created when a file is backed up.",_getBackupHistoryPath()));
      p_active_form._delete_window();
      return;
   }
   if ( xmlhandle<0 ) {
      basePath := _getBackupHistoryPath();
      if ( file_match('+p +t 'basePath:+ALLFILES_RE,1)!="" ) {
         needRebuild = true;
      }
   } else {
      nodeIndex := _xmlcfg_find_child_with_name(xmlhandle,TREE_ROOT_INDEX,"SaveLog");
      if ( nodeIndex >- 1 ) {
         rebuild := _xmlcfg_get_attribute(xmlhandle,nodeIndex,"Rebuild");
         if ( rebuild == 1 ) {
            needRebuild = true;
         }
      }
   }
   if ( needRebuild ) {
      result := _message_box(nls("Your %s file needs to be rebuilt.\n\nRebuild now?",SAVELOG_FILE),"",MB_YESNO);
      if (result==IDYES) {
         if ( xmlhandle>0 ) _xmlcfg_close(xmlhandle);
         rebuild_backup_history_log();
         xmlhandle = _xmlcfg_open(saveLogFilename,status);
         if ( xmlhandle<0 ) {
            return;
         }
      } else {
         return;
      }
   }
   int fileDateTable:[]:[];

   origWID := p_window_id;
   p_window_id = ctltree1;
   _TreeBeginUpdate(TREE_ROOT_INDEX);

   mou_hour_glass(true);
   _loadThisWeeksFileDates(xmlhandle);
   _TreeEndUpdate(TREE_ROOT_INDEX);
   olderIndex := _TreeAddItem(TREE_ROOT_INDEX,"Older",TREE_ADD_AS_CHILD,0,0,0,TREENODE_BOLD);
   _SetDialogInfoHt("olderIndex",olderIndex);
   _TreeTop();

   mou_hour_glass(false);

   p_window_id = origWID;
   _xmlcfg_close(xmlhandle);
}

void ctlclose.on_create()
{
   origWID := p_window_id;
   p_window_id = ctltree1;
   _TreeSetColButtonInfo(0,ctltree1.p_width intdiv 2,TREE_BUTTON_IS_DATETIME,-1,"Date");
   _TreeSetColButtonInfo(1,ctltree1.p_width intdiv 2,-1,-1,"Filename");
   p_window_id = origWID;
   ctldiff.p_enabled = ctlrestore.p_enabled = ctlview.p_enabled = false;
   loadThisWeeksDatesIntoTree();
}

static int gChangeSelectedTimer = -1;
static int gFilespecTimer = -1;

void ctlclose.on_destroy()
{
   if ( gChangeSelectedTimer>-1 ) {
      _kill_timer(gChangeSelectedTimer);
      gChangeSelectedTimer = -1;
   }
   if ( gFilespecTimer>-1 ) {
      _kill_timer(gFilespecTimer);
      gFilespecTimer = -1;
   }
}

void ctltree1.on_change(int reason,int index)
{
   inOnChange := _GetDialogInfoHt("inOnChange");
   if (inOnChange) {
      return;
   }
   _SetDialogInfoHt("inOnChange",1);
   switch (reason) {
   case CHANGE_EXPANDED:
      if (_TreeGetDepth(index)==1 && _TreeGetCaption(index)=="Older") {
         olderIndex := _GetDialogInfoHt("olderIndex");
         if (olderIndex>0) {
            saveLogFilename := getSaveLogFilename();
            xmlhandle := _xmlcfg_open(saveLogFilename,auto status);
            if ( xmlhandle<0 ) {
               return;
            }
            mou_hour_glass(true);
            _loadOlderFileDates(xmlhandle,olderIndex);
            _TreeSortCaption(olderIndex,'D');
            mou_hour_glass(false);
            _xmlcfg_close(xmlhandle);
            filterTree(ctlfilespecs.p_text);
         }
      }
      break;
   case CHANGE_LEAF_ENTER:
      {
         diffFromTopTree(index);
      }
   case CHANGE_SELECTED:
      {
         if ( gChangeSelectedTimer>=0 )_kill_timer(gChangeSelectedTimer);
         gChangeSelectedTimer = _set_timer(50,treeChangeSelectedCallback,p_active_form' 'index);
      }
   }
   _SetDialogInfoHt("inOnChange",0);
}

static void filespecTimerCallback(_str info)
{
   if (gFilespecTimer>-1) {
      _kill_timer(gFilespecTimer);
      gFilespecTimer = -1;
   }

   parse info with auto fid auto text;
   if ( fid.ctlfilespecs.p_text != text ) {
      return;
   }
   fid.ctltree1.filterTree(fid.ctlfilespecs.p_text);
}

static void filterTreeRecursive(_str filter,INTARRAY &hiddenIndexList,
                                INTARRAY &showIndexList,int index)
{
   if ( filter=="" ) filter = "*";
   origMaxArraySize := maxArraySize := _default_option(VSOPTION_WARNING_ARRAY_SIZE);
   i:=0;
   for (;;) {
      if (index<0) break;
      childIndex := _TreeGetFirstChildIndex(index);
      if ( childIndex>=0 ) {
         filterTreeRecursive(filter,hiddenIndexList,showIndexList,childIndex);
      }
      cap := _TreeGetCaption(index);
      parse cap with auto date "\t" auto filename;
//      filename = _strip_filename(filename,'P');
      if (_TreeGetDepth(index)==2) {
         // Not actually matching excludes here, but this function has better
         // fuzzy logic for matches (ex: path\ == path\*)
         match := _FileRegexMatchExcludePath(filter,filename);
         ++i;
         if (i >= maxArraySize) {
            _default_option(VSOPTION_WARNING_ARRAY_SIZE,maxArraySize*2);
            maxArraySize = _default_option(VSOPTION_WARNING_ARRAY_SIZE);
         }
         if ( !match ) {
            ARRAY_APPEND(hiddenIndexList,index);
         } else {
            ARRAY_APPEND(showIndexList,index);
         }
      }
      index = _TreeGetNextSiblingIndex(index);
   }
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,origMaxArraySize);
}

static void filterTree(_str filter)
{
   INTARRAY hiddenIndexList;
   INTARRAY showIndexList;
   filterTreeRecursive(filter,hiddenIndexList,showIndexList,TREE_ROOT_INDEX);
   len := hiddenIndexList._length();
   for (i:=0;i<len;++i) {
      _TreeGetInfo(hiddenIndexList[i],auto state, auto bm1, auto bm2, auto nodeFlags);
      _TreeSetInfo(hiddenIndexList[i], state, bm1, bm2, nodeFlags|TREENODE_HIDDEN);
   }
   len = showIndexList._length();
   for (i=0;i<len;++i) {
      _TreeGetInfo(showIndexList[i],auto state, auto bm1, auto bm2, auto nodeFlags);
      _TreeSetInfo(showIndexList[i], state, bm1, bm2, nodeFlags&~TREENODE_HIDDEN);
   }
   call_event(CHANGE_SELECTED,_TreeCurIndex(),p_window_id,ON_CHANGE,'W');
}

void ctlfilespecs.on_change()
{
   inOnChangeFilespecs := _GetDialogInfoHt("inOnChangeFilespecs");
   if (inOnChangeFilespecs) {
      return;
   }
   _SetDialogInfoHt("inOnChangeFilespecs",1);
   if (gFilespecTimer>-1) {
      _kill_timer(gFilespecTimer);
      gFilespecTimer = -1;
   }
   gFilespecTimer = _set_timer(100,filespecTimerCallback,p_active_form' 'p_text);
   _SetDialogInfoHt("inOnChangeFilespecs",0);
}

static bool noItemsSelected()
{
   index := _TreeGetNextCheckedIndex(1,auto info);
   return index<0;
}

void ctltree2.on_change(int reason,int index)
{
   inOnChange := _GetDialogInfoHt("inOnChange");
   if (inOnChange) {
      return;
   }
   _SetDialogInfoHt("inOnChange",1);
   switch (reason) {
   case CHANGE_SELECTED:
      if ( noItemsSelected() ) {
         diff := false;
         restore := false;
         view := false;
         _TreeGetInfo(index,auto state, auto bm1, auto bm2);
         if ( bm1 == _pic_file || bm1 == _pic_cvs_filem ) {
            diff = true;
            view = true;
            restore = true;
         } else {
         }
         if ( diff ) ctldiff.p_enabled = true;
         if ( restore ) ctlrestore.p_enabled = true;
         if ( view ) ctlview.p_enabled = true;
      }
      break;
   case CHANGE_LEAF_ENTER:
      diffOneFile(index);
      break;
   case CHANGE_EXPANDED:
      break;
   case CHANGE_CHECK_TOGGLED:
      {
         getCheckedIndexList(auto indexList);
         len := indexList._length();
         diff := false;
         restore := false;
         view := false;
         for (i:=0;i<len;++i) {
            _TreeGetInfo(indexList[i],auto state, auto bm1, auto bm2);
            if ( bm1 == _pic_file || bm1 == _pic_cvs_filem ) {
               diff = true;
               view = true;
               restore = true;
            } else {
            }
            if ( diff && restore && view ) break; // Nothing else we can accomplish
         }
         if ( diff ) ctldiff.p_enabled = true;
         if ( restore ) ctlrestore.p_enabled = true;
         if ( view ) ctlview.p_enabled = true;
      }
      break;
   }
   _SetDialogInfoHt("inOnChange",0);
}

static void treeChangeSelectedCallback(int info)
{
   if ( gChangeSelectedTimer>=0 ) _kill_timer(gChangeSelectedTimer);
   gChangeSelectedTimer = -1;

   parse info with auto fid auto index;
   if (fid.ctltree1._TreeCurIndex()!=index) {
      return;
   }

   tree1CurIndex := fid.ctltree1._TreeCurIndex();
   tree1ChildIndex := fid.ctltree1._TreeGetFirstChildIndex(tree1CurIndex);
   if ( fid.ctltree1._TreeGetDepth(tree1CurIndex)==1 ) {
      indexAbove := fid.ctltree1._TreeGetPrevIndex(tree1CurIndex);
      if ( indexAbove <0 || fid.ctltree1._TreeGetDepth(indexAbove)==1 ) {
         fid.ctltree2._TreeDelete(TREE_ROOT_INDEX,'C');
         return;
      }
   }

   STRHASHTAB fileTable;
   int pathTable:[];
   fid.ctltree1.getFileTable(fileTable);
   origWID := p_window_id;
   p_window_id = fid.ctltree2;
   mou_hour_glass(true);
   _TreeDelete(TREE_ROOT_INDEX,'C');
   buildPathTable(fileTable,pathTable);
   foreach (auto casedFilename => auto filename in fileTable) {
      pathIndex := _SVCGetPathIndex(_file_path(filename),'',pathTable);
      bmIndex := _pic_file;
      curIndex := _TreeAddItem(pathIndex,_strip_filename(filename,'P'),TREE_ADD_AS_CHILD,bmIndex,bmIndex,-1);
      _TreeSetCheckable(curIndex,1,0);
   }

   // Now sort everything
   firstChild := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (firstChild >= 0) {
      _TreeSortCaption(firstChild,'FT');
   }

   p_window_id = ctltree1;
   treeIndex := _TreeCurIndex();
   if (_TreeGetDepth(treeIndex)<2) {
      treeIndex = _TreeGetPrevIndex(treeIndex);
   }
   if ( treeIndex>0 ) {
      _TreeGetDateTimeStr(treeIndex,0,auto date);
      ctlfilesSavedSince.p_caption = "Files saved since "date':';
   } else {
      ctlfilesSavedSince.p_caption = "";
   }
   ctldiff.p_enabled = false;
   ctlrestore.p_enabled = false;
   ctlview.p_enabled = false;
   mou_hour_glass(false);
   p_window_id = origWID;
}

static void buildPathTable(STRHASHTAB &fileTable, 
                           int (&pathTable):[], 
                           int ExistFolderIndex=_pic_fldopen,
                           int NoExistFolderIndex=_pic_cvs_fld_m,
                           _str OurFilesep=FILESEP,
                           int state=1,
                           int checkable=1)
{
   // temporaries
   subpath := path := "";
   cased_path := "";
   cased_subpath := "";

   // Hash table and list of paths we want to keep
   // The hash table maps paths to their parent path in the heirarchy.
   _str filePathsTable:[];
   _str sortedPaths[];
   // All paths and sub-paths we have seen so far
   bool allPathsTable:[];

   // Go through each file in the file table
   foreach (auto filename => auto value in fileTable) {
      // Check if we already have seen this path
      path = _strip_filename(filename, 'N');
      cased_path = _file_case(path);
      if (filePathsTable._indexin(cased_path)) {
         continue;
      }
      // Add the path to all the tables
      filePathsTable:[cased_path] = "";
      allPathsTable:[cased_path] = true;
      sortedPaths[sortedPaths._length()] = path;
      // Then traverse over interior paths and see if we find
      // a common interior path with another path we already saw
      subpath = path;
      while (subpath != "") {
         // Remove the trailing file separator and
         // check that we didn't hit a top level path
         subpath = strip(subpath,'T',OurFilesep);
         if (!pos(OurFilesep,strip(subpath,'L',OurFilesep))) break;
         // Get the interior path and see if we have seen it before
         // and then add it to the table.
         subpath = _strip_filename(subpath, 'N');
         cased_subpath = _file_case(subpath);
         if (filePathsTable._indexin(cased_subpath)) {
            filePathsTable:[cased_path] = subpath;
            break;
         }
         if (allPathsTable._indexin(cased_subpath)) {
            filePathsTable:[cased_subpath] = "";
            sortedPaths[sortedPaths._length()] = subpath;
            break;
         }
         allPathsTable:[cased_subpath] = true;
      }
   }

   // Second pass through the paths in order to patch up any
   // paths that may share an interior path with another
   foreach (path in sortedPaths) {
      subpath = path;
      while (subpath != "") {
         // Remove the trailing file separator and
         // check that we didn't hit a top level path
         subpath = strip(subpath,'T',OurFilesep);
         if (!pos(OurFilesep,strip(subpath,'L',OurFilesep))) break;
         // Get the interior path and see if we have seen it before
         // and then modify the table
         subpath = _strip_filename(subpath, 'N');
         if (filePathsTable._indexin(_file_case(subpath))) {
            filePathsTable:[_file_case(path)] = subpath;
            break;
         }
      }
   }

   // Sort the list of paths, this way interior paths get inserted
   // before their child nodes.  Also insures things are sorted
   // when building a flattened tree.
   sortedPaths._sort('F');

   // Insert the required paths into the tree
   foreach (path in sortedPaths) {
      // Find the interior node that this path should be inserted under
      cased_path = _file_case(path);
      subpath = filePathsTable:[cased_path];
      cased_subpath = _file_case(subpath);
      treeIndex := TREE_ROOT_INDEX;
      if (subpath != "" && pathTable._indexin(cased_subpath)) {
         treeIndex = pathTable:[cased_subpath];
      }
      // Determine which bitmap index to use
      bmindex := ExistFolderIndex;
#if 0 //10:12am 9/27/2016
      // This code was here to change the bitmap if the local directory
      // for the file no longer exists.  The problem is that it can cause
      // hange for network paths that no longer exist.
      if (!isdirectory(path,"",true,true)) {
         bmindex=NoExistFolderIndex;
      }
#endif
      // Then add the item to the tree
      treeIndex = _TreeAddItem(treeIndex, 
                               path, 
                               TREE_ADD_AS_CHILD, 
                               bmindex,
                               bmindex,
                               state);
      _TreeSetCheckable(treeIndex, checkable, checkable);
      // And, finally, update the path table
      pathTable:[cased_path] = treeIndex;
   }
}



static void getFileTable(STRHASHTAB &fileTable)
{
   curTreeIndex := index := _TreeCurIndex();
   cache := _GetDialogInfoHt("cache:"index);
   if ( cache != null ) {
      fileTable = cache;
      return;
   }
   _GetFileTableFromBHBrowser(fileTable);
   _SetDialogInfoHt("cache:"index,fileTable);
}

static void getCheckedIndexList(INTARRAY &indexList)
{
   int info;
   for (ff:=1;;ff=0) {
      index := _TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      _TreeGetInfo(index,auto state, auto bm1);
      if ( bm1 != _pic_fldopen && bm1 != _pic_cvs_fld_m ) {
         ARRAY_APPEND(indexList,index);
      }
   }
   if ( indexList._length() == 0 ) {
      index := _TreeCurIndex();
      if ( index>= 0 ) {
         ARRAY_APPEND(indexList,index);
      }
   }
}

static void diffSelectedFiles()
{
   origWID := p_window_id;
   p_window_id = ctltree1;
   index := _TreeCurIndex();
   while ( _TreeGetDepth(index)==1 ) {
      index = _TreeGetPrevIndex(index);
   }
   cap := _TreeGetCaption(index);
   parse cap with "\t" auto filename;
   datestr := _TreeGetUserInfo(index);
   p_window_id = origWID;

   origWID = p_window_id;
   p_window_id = ctltree2;
   getCheckedIndexList(auto indexList);
   len := indexList._length();
   STRHASHTAB versionList;
   STRARRAY oldVersionList;
   for (i:=0;i<len;++i) {
      curIndex := indexList[i];
      cap = _TreeGetCaption(curIndex);
      _TreeGetInfo(curIndex,auto state, auto bm1, auto bm2);
      if ( bm1 != _pic_file ) {
         continue;
      }
      filename = _TreeGetCaption(_TreeGetParentIndex(curIndex)):+_TreeGetCaption(curIndex);
      version := getVersionOfFile(filename,datestr,auto oldestVersion);
      if ( version < 0 ) {
         version = oldestVersion;
         ARRAY_APPEND(oldVersionList,filename);
      }
      versionList:[filename] = version;
   }
   if ( oldVersionList._length() ) {
      oldVersionStr := "";
      foreach (auto curFile in oldVersionList) {
         oldVersionStr :+= curFile"\n";
      }
      result := _message_box(nls("The following files do not have enough versions for the selected date.\n\n%s\n\nWould you like to view the oldest versions of the files?",oldVersionStr),"",MB_YESNO);
      if (result==IDNO) {
         foreach (curFile in oldVersionList) {
            versionList._deleteel(curFile);
         }
      }
   }
   foreach (auto curFilename => auto curVersion in versionList) {
      _HistoryDiffBackupHistoryFile(curFilename, curVersion);
   }
   p_window_id = origWID;
}

static void diffFromTopTree(int fileIndex)
{
   origWID := p_window_id;
   p_window_id = ctltree1;
   index := _TreeCurIndex();
   while ( _TreeGetDepth(index)==1 ) {
      index = _TreeGetPrevIndex(index);
   }
   cap := _TreeGetCaption(index);
   parse cap with "\t" auto filename;
   datestr := _TreeGetUserInfo(index);
   p_window_id = origWID;

   version := getVersionOfFile(filename,datestr,auto oldestVersion);
   // Don't have to check version, we know we have this exact version
   _HistoryDiffBackupHistoryFile(filename, version);
   p_window_id = origWID;
}

static void diffOneFile(int fileIndex)
{
   origWID := p_window_id;
   p_window_id = ctltree1;
   index := _TreeCurIndex();
   if (index<=0) return;
   while ( _TreeGetDepth(index)==1 ) {
      index = _TreeGetPrevIndex(index);
   }
   cap := _TreeGetCaption(index);
   parse cap with "\t" auto filename;
   datestr := _TreeGetUserInfo(index);
   p_window_id = origWID;

   origWID = p_window_id;
   p_window_id = ctltree2;
   getCheckedIndexList(auto indexList);
   len := indexList._length();
   cap = _TreeGetCaption(fileIndex);
   _TreeGetInfo(fileIndex,auto state, auto bm1, auto bm2);
   if ( bm1 != _pic_file ) {
      return;
   }
   filename = _TreeGetCaption(_TreeGetParentIndex(fileIndex)):+_TreeGetCaption(fileIndex);
   version := getVersionOfFile(filename,datestr,auto oldestVersion);
   if ( version < 0 ) {
      result := _message_box(nls("A version of '%s' that old does not exist.  You may want to increase the number of backups kept (Tools>Options>File Options>Backup)\n\nWould you like to view the oldest version?",filename),"",MB_YESNO);
      if ( result==IDYES ) {
         _HistoryDiffBackupHistoryFile(filename, oldestVersion);
         return;
      } else{
         p_window_id = origWID;
         return;
      }
   }
   _HistoryDiffBackupHistoryFile(filename, version);
   p_window_id = origWID;
}

void ctldiff.lbutton_up()
{
   diffSelectedFiles();
}

void ctlrebuildSaveLog.lbutton_up()
{
   rebuild_backup_history_log();

   origWID := p_window_id;
   p_window_id = ctltree1;
   _TreeDelete(TREE_ROOT_INDEX,'C');
   loadThisWeeksDatesIntoTree();
   p_window_id = origWID;
}

static void restoreOneFile(int index)
{
   origWID := p_window_id;
   p_window_id = ctltree2;
   _TreeGetInfo(index, auto state, auto bm1);
#if 0 //10:14am 9/27/2016
   // We didn't used to allow restoring files that exist, but now are going to
   if ( bm1!=_pic_cvs_filem ) {
      p_window_id = origWID;
      return;
   }
#endif
   filename := _TreeGetCaption(_TreeGetParentIndex(index)):+_TreeGetCaption(index);
   p_window_id = origWID;
   destFilename := filename;
   path := _file_path(filename);
   justName := _strip_filename(filename,'P');
   status := make_path(path);
   while ( status ) {
      result := _message_box(nls("Could not create path '%s'\n\nWould you like to save '%s' to another directory?",path,filename),"",MB_YESNO);
      if ( result!=IDYES ) return;

      // Default dest path to current directory
      initPath := getcwd();

      // If there is a current project, default to it's working directory
      if ( _project_name!="" ) {
         int project_handle=_ProjectHandle(_project_name);
         initPath = absolute(_ProjectGet_WorkingDir(project_handle),_file_path(_project_name));
      }

      destFilename = _OpenDialog('-new -modal',
                              'Save As',
                              '',     // Initial wildcards
                              def_file_types,  // file types
                              OFN_SAVEAS,
                              '',      // Default extensions
                              justName, // Initial filename
                              initPath,      // Initial directory
                              '',      // Reserved
                              "Save As dialog box"
                              );
      if ( destFilename=='' ) return;

      status = _make_path(_file_path(destFilename));
      if ( !status ) break;
   }

   p_window_id = ctltree1;
   dateIndex := _TreeCurIndex();
   while (_TreeGetDepth(dateIndex)<2) {
      dateIndex = _TreeGetPrevIndex(dateIndex);
   }
   datestr := _TreeGetUserInfo(dateIndex);
   p_window_id = origWID;
   version := getVersionOfFile(filename,datestr,auto oldestVersion);
   if ( version<0 ) return;

   STRARRAY captions;
   captions[0] = nls("Restore most recent version of %s",filename);
   if (version>-1) {
      captions[1] = nls("Restore version %s of %s",version,filename);
   } else {
      captions[1] = nls("Restore version %s of %s (oldest available version)",oldestVersion,filename);
      version = oldestVersion;
   }
   button := RadioButtons("",captions);

   newWID := 0;
   status = 0;
   if ( button == 1 ) {
      newWID = DSExtractMostRecentVersion(filename,status);
   } else if ( button == 2 ) {
      newWID = DSExtractVersion(filename,version,status);
   } else if ( button < 0 ) {
      return;
   }
   if (status) {
      _message_box(nls(get_message(status)));
      return;
   }
   status = newWID._save_file('+o '_maybe_quote_filename(destFilename));
   if (status) {
      _message_box(nls(get_message(status)));
      return;
   }

   // Check to see if the file is open
   bufInfo := buf_match(destFilename,1,'xv');
   if (bufInfo!="") {
      parse bufInfo with auto bufID auto bufFlags auto bufName;
      windowID := window_match(destFilename,1,'x');

      bfiledate := _file_date(destFilename,'B');
      if ( windowID!=0 ) {
         // If it is open and in a window, reload it in that window
         windowID._ReloadCurFile(windowID,bfiledate,false,false);
      } else {
         // If it is open but not in a window, create a temp view and reload it
         // there
         status = _open_temp_view('', auto temp_wid, auto preOpenWID, "+bi "bufID);
         temp_wid.save_pos(auto p);
         if (!status) _ReloadCurFile(temp_wid, bfiledate, false, true, null, false);
         temp_wid.restore_pos(p);
         p_window_id = preOpenWID;
      }
   }

   _delete_temp_view(newWID);


   p_window_id = ctltree2;
   if ( !status ) {
      // Set the picture to show the file exists
      _TreeGetInfo(index,state, bm1);
      _TreeSetInfo(index, state, _pic_file);
      index = _TreeGetParentIndex(index);
      // Set all the parent pictures to reflect that the directories exist now
      for (;;) {
         if (index<=TREE_ROOT_INDEX) break;
         _TreeGetInfo(index, state, bm1);
         if ( bm1!=_pic_fldopen ) {
            _TreeSetInfo(index, state, _pic_fldopen);
         }
         index = _TreeGetParentIndex(index);
      }
   }
   p_window_id = origWID;
}

void ctlrestore.lbutton_up()
{
   ctltree2.getCheckedIndexList(auto indexList);
   len := indexList._length();

   numWarnings := ctltree2.accumRestoreWarnings(indexList);
   if ( numWarnings ) {
      result := _message_box(nls("%s of these files already exist.  Restoring them will replace the contents.\n\nContinue?",numWarnings),"",MB_YESNO);
      if ( result!=IDYES ) {
         return;
      }
   }

   for (i:=0;i<len;++i) {
      restoreOneFile(indexList[i]);
   }
}

static int accumRestoreWarnings(INTARRAY &indexList)
{
   numWarnings := 0;
   len := indexList._length();
   for (i:=0;i<len;++i) {
      _TreeGetInfo(indexList[i],auto state,auto bm1);
      if ( bm1 != _pic_cvs_filem ) ++numWarnings;
   }
   return numWarnings;
}

static void viewOneFile(int index)
{
   origWID := p_window_id;
   p_window_id = ctltree2;
   _TreeGetInfo(index, auto state, auto bm1);
   if ( bm1!=_pic_file && bm1!=_pic_cvs_filem ) {
      p_window_id = origWID;
      return;
   }
   filename := _TreeGetCaption(_TreeGetParentIndex(index)):+_TreeGetCaption(index);
   p_window_id = origWID;

   p_window_id = ctltree1;
   dateIndex := _TreeCurIndex();
   while (_TreeGetDepth(dateIndex)<2) {
      dateIndex = _TreeGetPrevIndex(dateIndex);
   }
   datestr := _TreeGetUserInfo(dateIndex);
   p_window_id = origWID;

   version := getVersionOfFile(filename,datestr,auto oldestVersion);
   newWID := DSExtractVersion(filename,version,auto status);
   _showbuf(newWID.p_buf_id,true,'-new -modal',filename' (Version 'version')','S',true);
   _delete_temp_view(newWID);
}

void ctlview.lbutton_up()
{
   ctltree2.getCheckedIndexList(auto indexList);
   len := indexList._length();
   for (i:=0;i<len;++i) {
      viewOneFile(indexList[i]);
   }
}

static int getVersionOfFile(_str filename,_str datestr,int &oldestVersion)
{
//   say('getVersionOfFile datestr='datestr);
   status := DSListVersionDates(filename,auto list=null);
   if ( status ) {
      _message_box(nls("Could not get version list for '%s'",filename));
      return status;
   }
   len := list._length();
   se.datetime.DateTime selectedDate;
   getDateFromDateStr(datestr,selectedDate);
//   say('getVersionOfFile selectedDate.toString()='selectedDate.toString());
   found := false;
   foundGreater := false;
   version := "";
   lastVersion := "";
   oldestVersion = -1;
   for (i:=0;i<len;++i) {
      parse list[i] with version "\t" auto curDateStr "\t" auto comment;
//      say('getVersionOfFile version='version);
      se.datetime.DateTime curDate;
      getDateFromDateStr(curDateStr,curDate);
      if ( curDate == selectedDate ) {
         found = true;
         break;
      } else if ( selectedDate < curDate ) {
//         say('getVersionOfFile curDate<selectedDate foundGreater='foundGreater);
//         say('getVersionOfFile selectedDate.toString()='selectedDate.toString());
//         say('getVersionOfFile curDate.toString()='curDate.toString());
         if ( foundGreater ) {
            found = true;
            version = lastVersion;
            break;
         }
      } else {
//         say('getVersionOfFile found greater');
//         say('getVersionOfFile selectedDate.toString()='selectedDate.toString());
//         say('getVersionOfFile curDate.toString()='curDate.toString());
         foundGreater = true;
      }
      lastVersion = version;
      if ( oldestVersion < 0 ) {
         oldestVersion = (int)version;
      }
   }
   if ( !found ) {
      return -1;
   } else {
      return (int)version;
   }
}

static void getDateFromDateStr(_str datestr,se.datetime.DateTime &selectedDate)
{
   parse datestr with auto yyyy'/'auto mm'/'auto dd auto hh':' auto mins':' auto ss;
   se.datetime.DateTime dateTime((int)yyyy,(int)mm,(int)dd,(int)hh,(int)mins,(int)ss);
   selectedDate = dateTime;
}

_command void backup_history_browser() name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveBackupHistory()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Backup History");
      return;
   }
   show('-xy _backup_history_browser_form');
}

int _cbsave_BackupHistoryBrowser()
{
   wid := _find_formobj('_backup_history_browser_form','N');
   if (wid) {
      filename := p_buf_name;
      date := _file_date(filename,'B');
      todayFolderIndex := wid.ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if ( todayFolderIndex>=0 ) {
         lastDate := wid.ctltree1._TreeGetFirstChildIndex(todayFolderIndex);
         addFlags := TREE_ADD_BEFORE;

         // This could be the first entry under "Today"
         if ( lastDate<0 ) {
            addFlags = TREE_ADD_AS_CHILD;
            lastDate = todayFolderIndex;
         }
         newIndex := wid.ctltree1._TreeAddItem(lastDate,"\t"filename,addFlags,0,0,-1);
         if ( newIndex>=0 ) {
            se.datetime.DateTime dateTime;
            dateTime.fromTimeB(date);
            dateTime.toParts(auto year,auto month,auto day,
                             auto hour,auto minute,auto second,
                             auto milliseconds,se.datetime.DT_LOCALTIME);
            
            wid.ctltree1._TreeSetDateTime(newIndex,0,
                                          year,month,day,
                                          hour,minute,second,
                                          milliseconds);


            userInfoDate := year'/'month'/'day' 'hour':'minute':'second:+milliseconds;
            wid.ctltree1._TreeSetUserInfo(newIndex,userInfoDate);
         }
      }
   }
   return 0;
}
