////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48969 $
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
#import 'listbox.e'
#import 'main.e'
#import 'stdprocs.e'
#import 'svc.e'
#import 'se/datetime/DateTime.e'
#require "se/vc/IVersionControl.e"
#endregion Imports

using se.vc.IVersionControl;
//using se.vc.Perforce;
//using se.vc.Subversion;

using se.datetime.DateTime;

#define DATE_ENDING_TODAY "Today"
#define DATE_ENDING_PAST_WEEK "Past week"
#define DATE_ENDING_PAST_MONTH "Past month"
#define DATE_ENDING_PAST_3_MONTHS "Past 3 months"
#define DATE_ENDING_PAST_6_MONTHS "Past 6 months"
#define DATE_ENDING_PAST_9_MONTHS "Past 9 months"
#define DATE_ENDING_PAST_YEAR "Past year"

enum_flags DateThru {
   DC_TODAY,
   DC_YESTERDAY,
   DC_WITHIN_LAST_WEEK,
   DC_WITHIN_LAST_MONTH,
   DC_WITHIN_LAST_3_MONTHS,
   DC_WITHIN_LAST_6_MONTHS,
   DC_WITHIN_LAST_9_MONTHS,
   DC_WITHIN_LAST_YEAR,
};

defeventtab _svc_repository_browser;
void ctlsearch.lbutton_up()
{
   filterTree(ctlsearch_text.p_text);
}

void ctlsearch_clear.lbutton_up()
{
   ctlsearch_text.p_text = "";
   ctlsearch_text._begin_line();
   filterTree("");
}

void ctlsearch_text.enter()
{
   filterTree(p_text);
}

void ctlsearch_text.down()
{
   ctltree1._set_focus();
}

void ctlrepository.enter()
{
   refreshTree();
}

void ctldate.enter()
{
   refreshTree();
}

void ctldate.on_change(int reason)
{
   if ( reason==CHANGE_CLINE ) {
      refreshTree();
   }
}

static void refreshTree()
{
   DateTime dateBack;
   getDateFromCombobox(dateBack);
   URL := ctlrepository.p_text;
   refillTree(URL,dateBack);
   filterTree(ctlsearch_text.p_text);
}

static void getDateFromCombobox(DateTime &dateBack)
{
   DateTime temp();
   DateTime startToday(temp.year(), temp.month(), temp.day(), 0, 0, 0, 0);
   switch ( ctldate.p_text ) {
   case DATE_ENDING_TODAY:
      dateBack = startToday.add(-1, se.datetime.DT_DAY);
      break;
   case DATE_ENDING_PAST_WEEK:
      dateBack = startToday.add(-7, se.datetime.DT_DAY);
      break;
   case DATE_ENDING_PAST_MONTH:
      dateBack = startToday.add(-1, se.datetime.DT_MONTH);
      break;
   case DATE_ENDING_PAST_3_MONTHS:
      dateBack = startToday.add(-3, se.datetime.DT_MONTH);
      break;
   case DATE_ENDING_PAST_6_MONTHS:
      dateBack = startToday.add(-6, se.datetime.DT_MONTH);
      break;
   case DATE_ENDING_PAST_9_MONTHS:
      dateBack = startToday.add(-9, se.datetime.DT_MONTH);
      break;
   case DATE_ENDING_PAST_YEAR:
      dateBack = startToday.add(-1, se.datetime.DT_YEAR);
      break;
   default:
      parse p_text with auto yearStr '/' auto monthStr '/' auto dayStr;
      if ( !( isinteger(yearStr) && isinteger(monthStr) && isinteger(dayStr) ) ) {
         parse p_text with yearStr '-' monthStr '-' dayStr;
         if ( !( isinteger(yearStr) && isinteger(monthStr) && isinteger(dayStr) )  ) {
            _text_box_error(nls("Date must be formatted YYYY/MM/DD"));
            return;
         }
      }
      DateTime userDate((int) yearStr,(int)monthStr,(int) dayStr);
      dateBack = userDate;
   }
}

static void refillTree(_str URL,DateTime dateBack)
{
   SVCHistoryInfo historyInfo[];
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      return;
   }
   mou_hour_glass(1);

   status := pInterface->getRepositoryInformation(URL,historyInfo,dateBack);
   if ( status ) {
      _message_box("Could not get information for repository %s",URL);
   }
   ctltree1._TreeDelete(TREE_ROOT_INDEX,'C');
   fillInTree(historyInfo);
   mou_hour_glass(0);
}

static void filterTree(_str filterText)
{
   noteTable := _GetDialogInfoHt("noteTable");
   sstring := filterText;
   if ( sstring=="" ) {
      showAll();
      return;
   }
   mou_hour_glass(1);
   hideAll();
   getSerachArray(sstring,auto searchArray,auto joinArray);

   int results[][];

   STRHASHTAB tableCopies[];
   boolean makeNewCopy = true;
   len := searchArray._length();
   for (i:=0;i<len;++i) {
      if ( makeNewCopy ) {
         curTable := tableCopies[tableCopies._length()] = noteTable;
         makeNewCopy = false;
      }
      STRARRAY toDel;
      foreach (auto curIndex => auto curData in tableCopies[tableCopies._length()-1] ) {
         p := pos(searchArray[i],curData,1,'i');
         if ( !p ) {
            ARRAY_APPEND(toDel,curIndex);
         }
      }
      for (j:=0;j<toDel._length();++j) {
         tableCopies[tableCopies._length()-1]._deleteel(toDel[j]);
      }
      if ( joinArray[i]==' ' ) {
         makeNewCopy = true;
      }
   }

   origWID := p_window_id;
   _nocheck _control ctltree1;
   p_window_id = ctltree1;
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;index>=0;) {
      len = tableCopies._length();
      keepCur := false;
//      say('ctlsearch_text.on_change numTableCopies='len);
      for (i=0;i<len;++i) {
         if ( tableCopies[i]._indexin(index) ) {
            keepCur = true;break;
         }
      }
      _TreeGetInfo(index,auto state,auto bm1,auto bm2,auto flags);
      if ( keepCur ) {
         _TreeSetInfo(index,state,bm1,bm2,flags&~TREENODE_HIDDEN);
      } else {
         _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_HIDDEN);
      }

      index = _TreeGetNextSiblingIndex(index);
   }
   p_window_id = origWID;

   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   mou_hour_glass(0);
}

static STRARRAY getSerachArray(_str sstring,STRARRAY &searchArray,STRARRAY &joinArray)
{
   for (;;) {
      parse sstring with auto cur ' | or ','r' +0 sstring;
      if (cur:=="") break;
      if ( substr(sstring,1,4)==' or ' ) {
         ARRAY_APPEND(joinArray,' ');
         sstring = substr(sstring,5);
      } else {
         ARRAY_APPEND(joinArray,'+');
         sstring = substr(sstring,2);
      }
      ARRAY_APPEND(searchArray,cur);
   }
   return searchArray;
}

static void showIndex(int index)
{
   showOrHide(index,1);
}

static void hideIndex(int index)
{
   showOrHide(index,0);
}

static void showOrHide(int index,int showOrHide)
{
   origWID := p_window_id;
   _nocheck _control ctltree1;
   p_window_id = ctltree1;
   if ( showOrHide ) {
      ctltree1._TreeGetInfo(index,auto state,auto bm1,auto bm2,auto nodeFlags);
      ctltree1._TreeSetInfo(index,state,bm1,bm2,nodeFlags&~TREENODE_HIDDEN);
   } else {
      ctltree1._TreeGetInfo(index,auto state,auto bm1,auto bm2,auto nodeFlags);
      ctltree1._TreeSetInfo(index,state,bm1,bm2,nodeFlags|TREENODE_HIDDEN);
   }
   p_window_id = origWID;
}

static void showAll()
{
   origWID := p_window_id;
   _nocheck _control ctltree1;
   p_window_id = ctltree1;
   childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if (childIndex<0) break;
      ctltree1._TreeGetInfo(childIndex,auto state,auto bm1,auto bm2,auto nodeFlags);
      ctltree1._TreeSetInfo(childIndex,state,bm1,bm2,nodeFlags&~TREENODE_HIDDEN);
      childIndex = _TreeGetNextSiblingIndex(childIndex);
   }
   p_window_id = origWID;
}

static void hideAll()
{
   origWID := p_window_id;
   _nocheck _control ctltree1;
   p_window_id = ctltree1;
   childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if (childIndex<0) break;
      ctltree1._TreeGetInfo(childIndex,auto state,auto bm1,auto bm2,auto nodeFlags);
      ctltree1._TreeSetInfo(childIndex,state,bm1,bm2,nodeFlags|TREENODE_HIDDEN);
      childIndex = _TreeGetNextSiblingIndex(childIndex);
   }
   p_window_id = origWID;
}

#define controlXExtent(a) (a.p_x+a.p_width)
#define controlYExtent(a) (a.p_y+a.p_height)

void _svc_repository_browser.on_load()
{
   ctlsearch_text._set_focus();
}

void ctlclose.on_create(_str repositoryURL="")
{
   ctlrepository.p_text=repositoryURL;
   p_active_form.p_caption = "Repository Browser";

   origWID := p_window_id;
   p_window_id = ctldate;

   _lbadd_item(DATE_ENDING_TODAY);
   _lbadd_item(DATE_ENDING_PAST_WEEK);
   _lbadd_item(DATE_ENDING_PAST_MONTH);
   _lbadd_item(DATE_ENDING_PAST_3_MONTHS);
   _lbadd_item(DATE_ENDING_PAST_6_MONTHS);
   _lbadd_item(DATE_ENDING_PAST_9_MONTHS);
   _lbadd_item(DATE_ENDING_PAST_YEAR);

   p_text = DATE_ENDING_PAST_WEEK;

   p_window_id = origWID;
   ctldate.call_event(ctldate,ENTER);
}

void _svc_repository_browser.on_resize()
{
   clientHeight := _dy2ly(SM_TWIP,p_client_height);
   clientWidth := _dy2ly(SM_TWIP,p_client_width);
   topLabelWID := ctlrepository.p_prev;
   labelWID := ctlsearch_text.p_prev;
   bufferY := topLabelWID.p_y;
   bufferX := topLabelWID.p_x;
   ctldate.p_x = ctlrepository.p_x = controlXExtent(ctlrepository.p_prev) + bufferX;

   ctlsearch_text.p_x = controlXExtent(ctlsearch_text.p_prev) + bufferX;

   ctltree1.p_x = labelWID.p_x;
   ctltree1.p_y = controlYExtent(ctlsearch_text) + bufferY;

   buttonRowHeight := ctlclose.p_height+(2*bufferY);

   ctltree1.p_height = clientHeight-(ctltree1.p_y)-buttonRowHeight;
   ctltree1.p_width = ((clientWidth-(3*bufferX)) intdiv 3);

   ctlminihtml1.p_x=controlXExtent(ctltree1)+bufferX;
   ctlminihtml1.p_y=ctlrepository.p_y;
   ctlminihtml1.p_height=controlYExtent(ctltree1);

   ctlminihtml1.p_width=ctltree1.p_width*2;

   ctlrepository.p_width = ctldate.p_width = ctltree1.p_width - controlXExtent(ctlrepository.p_prev);

   ctlsearch_text.p_width = ((ctltree1.p_width - ctlsearch_text.p_prev.p_width) - bufferX) - (ctlsearch.p_width+ctlsearch_clear.p_width);
   ctlsearch.p_x = controlXExtent(ctlsearch_text);
   ctlsearch_clear.p_x = controlXExtent(ctlsearch);

   ctlclose.p_y = controlYExtent(ctltree1)+bufferY;
}

void ctlminihtml1.on_change(int reason,_str href="")
{
   switch ( reason ) {
   case CHANGE_CLICKED_ON_HTML_LINK:
      {
         parse href with auto revision ',' auto remoteFilename;
         URL := getURLFromDialogPieces(remoteFilename);
         svc_history(URL,0,revision,true);
      }
      break;
   }
}

static _str getURLFromDialogPieces(_str remoteFilename)
{
   URL := ctlrepository.p_text;
   if ( last_char(URL)=='/' ) URL = substr(URL,1,length(URL)-1);
   p := lastpos('/',URL);
   if ( p>1 ) {
      URL = substr(URL,1,p-1);
   }
   return URL:+remoteFilename;
}

#define CLICK_CAPTION "Double click to get "DEFAULT_NUM_VERSIONS_IN_REP_BROWSER" more versions"

static void getVersionInfo(SVCHistoryInfo &historyInfo,STRARRAY &lineArray)
{
   if ( historyInfo.author!="" ) lineArray[lineArray._length()]='<B>Author:</B>&nbsp;'historyInfo.author'<br>';
   if ( historyInfo.date!="" ) lineArray[lineArray._length()]='<B>Date:</B>&nbsp;'historyInfo.date'<br>';
   // Replace comment string line endings with <br> to preserve formatting
   _str commentBR = stranslate(historyInfo.comment, '<br>', '\n', 'l');
   if ( commentBR!="" ) {
      lineArray[lineArray._length()]='<B>Comment:</B>&nbsp;'commentBR;
   }
   if( historyInfo.affectedFilesDetails :!= '' ) {
      curLine := '<br><B>Changed paths:</B><font face="Menlo, Monaco, Consolas, Courier New, Monospace">';
      for (;;) {
         parse historyInfo.affectedFilesDetails with '<br>','i' auto curFile '<br>','i' +0 historyInfo.affectedFilesDetails;
         if ( curFile=="" ) break;

         curFile = "<A href="historyInfo.revision","curFile">"curFile"</A>";
         curLine = curLine'<BR>'curFile;

      }
      curLine = curLine'</font>';
      lineArray[lineArray._length()]=curLine;
   }
}

static void fillInTree(SVCHistoryInfo (&historyInfo)[])
{
   noteTable := _GetDialogInfoHt("noteTable");

   len := historyInfo._length();
   wid := p_window_id;
   p_window_id = ctltree1;

   // > 0, skip the root entry"
   for (i:=len-1;i>0;--i) {
      getVersionInfo(historyInfo[i],auto lineArray);
      index := _TreeAddItem(TREE_ROOT_INDEX,historyInfo[i].revision,TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
      addDataToNoteTable(noteTable,index,lineArray);
      _TreeSetUserInfo(index,lineArray);
   }
//   _TreeAddItem(TREE_ROOT_INDEX,CLICK_CAPTION,TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF,TREENODE_BOLD);
   _SetDialogInfoHt("noteTable",noteTable);
   p_window_id=wid;
   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
}

static void addDataToNoteTable(STRHASHTAB &noteTable,int treeIndex,STRARRAY &lineArray)
{
   line := "";
   len := lineArray._length();
   for (i:=0;i<len;++i) {
      parse lineArray[i] with ":</B>&nbsp;",'i' auto curLine;
      if ( curLine=="" ) {
         parse lineArray[i] with '<br>' curLine ;
      }
      curLine = stranslate(curLine,"","<br>","i");
      line = line' 'curLine;
   }
   noteTable:[treeIndex] = line;
}

#if 0 //10:36am 4/17/2013
static void appendToTree(SVCHistoryInfo (&historyInfo)[])
{
   len := historyInfo._length();
   wid := p_window_id;
   p_window_id = ctltree1;
   index := _TreeSearch(TREE_ROOT_INDEX,CLICK_CAPTION,'T');
   if ( index ) {
      lastIndex := index;
      for (i:=len-1;i>=0;--i) {
         if ( historyInfo[i].revision!="root" ) {
            getVersionInfo(historyInfo[i],auto lineArray);
            lastIndex = _TreeAddItem(lastIndex,historyInfo[i].revision,TREE_ADD_AFTER,_pic_file,_pic_file,TREE_NODE_LEAF);
            _TreeSetUserInfo(index,lineArray);
         }
      }
      if ( lastIndex>=0 ) {
//         _TreeAddItem(lastIndex,CLICK_CAPTION,TREE_ADD_AFTER,_pic_file,_pic_file,TREE_NODE_LEAF,TREENODE_BOLD);
      }
      _TreeDelete(index);
   }
   p_window_id=wid;
}
#endif
void ctltree1.on_change(int reason,int index)
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;
   parse p_active_form.p_child.p_caption with "Repository:" auto URL;
   switch (reason) {
#if 0 //10:36am 4/17/2013
   case CHANGE_LEAF_ENTER:
      {
         cap := _TreeGetCaption(_TreeGetPrevIndex(index));
         pInterface->getVersionNumberFromVersionCaption(cap,auto versionNumber);
         //firstRevision := (int)versionNumber-1;
         se.datetime.DateTime temp;
         pInterface->getRepositoryInformation(URL,auto historyInfo,temp);
         appendToTree(historyInfo);
      }
      break;
#endif
   case CHANGE_SELECTED:
      {
         _TextBrowserSetHtml(ctlminihtml1,"");
         info := _TreeGetUserInfo(index);
         len := info._length();
         infoStr := "";
         for ( i:=0;i<len;++i ) {
            infoStr = infoStr:+"\n":+info[i];
         }
         _TextBrowserSetHtml(ctlminihtml1,infoStr);
      }
   }
}
