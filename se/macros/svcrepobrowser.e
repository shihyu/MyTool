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
#import 'diff.e'
#import 'dir.e'
#import 'listbox.e'
#import 'main.e'
#import "picture.e"
#import 'stdprocs.e'
#import 'svc.e'
#import 'treeview.e'
#require "se/vc/IVersionControl.e"
#endregion Imports

using se.vc.IVersionControl;

using se.datetime.DateTime;

const DATE_ENDING_TODAY= "Today";
const DATE_ENDING_PAST_WEEK= "Past week";
const DATE_ENDING_PAST_MONTH= "Past month";
const DATE_ENDING_PAST_3_MONTHS= "Past 3 months";
const DATE_ENDING_PAST_6_MONTHS= "Past 6 months";
const DATE_ENDING_PAST_9_MONTHS= "Past 9 months";
const DATE_ENDING_PAST_YEAR= "Past year";
const DATE_ENDING_PAST_2_YEARS= "Past 2 years";
const DATE_ENDING_PAST_5_YEARS= "Past 5 years";
const DATE_ENDING_FOREVER= "Forever";

enum_flags DateThru {
   DC_TODAY,
   DC_YESTERDAY,
   DC_WITHIN_LAST_WEEK,
   DC_WITHIN_LAST_MONTH,
   DC_WITHIN_LAST_3_MONTHS,
   DC_WITHIN_LAST_6_MONTHS,
   DC_WITHIN_LAST_9_MONTHS,
   DC_WITHIN_LAST_YEAR,
   DC_WITHIN_LAST_2_YEARS,
   DC_WITHIN_LAST_5_YEARS,
   DC_WITHIN_FOREVER,
};

const REVISIONS_LESS_CAPTION = "Revisions<<";
const REVISIONS_MORE_CAPTION = "Revisions>>";

STRARRAY def_svc_browser_url_list;

defeventtab _svc_repository_browser;

////////////////////////////////////////////////////////
// svcURL.xml is still used for auto restore information
//
static const TREE_INFO_FILENAME= 'svcURL.xml';

static void loadTree()
{
   _nocheck _control ctlURLTree;
   origWID := p_window_id;
   p_window_id = ctlURLTree;

   // Open svcURL.xml - we still use it for auto restore information
   filename := _ConfigPath():+TREE_INFO_FILENAME;
   xmlhandle := _xmlcfg_open(filename,auto status=0);
   len := def_svc_browser_url_list._length();
   for (i:=0;i<len;++i) {
      // Fill in the top level tree itms from def_svc_browser_url_list
      newIndex := _TreeAddItem(TREE_ROOT_INDEX,def_svc_browser_url_list[i],TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,TREE_NODE_COLLAPSED);

      if ( xmlhandle>=0 ) {
         // If we can find this entry in svcURL.xml...
         xmlindex := _xmlcfg_find_simple(xmlhandle,"/Tree/TreeNode[@Cap='"def_svc_browser_url_list[i]"']");
         if ( xmlindex>=0 ) {
            // .. load the rest of the "child data" from the xml file.
            status = ctlURLTree._TreeLoadDataXML(xmlhandle,xmlindex,newIndex);
            state := _xmlcfg_get_attribute(xmlhandle,xmlindex,"State",-1);
            _TreeSetInfo(newIndex,state);
         }
      }
   }
   p_window_id = origWID;
   if ( xmlhandle>=0 )_xmlcfg_close(xmlhandle);
}

static void saveTree()
{
   // First clear def variable.
   def_svc_browser_url_list = null;
   childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if ( childIndex<0 ) break;
      // Collect top level URLs in def variable.  
      ARRAY_APPEND(def_svc_browser_url_list,_TreeGetCaption(childIndex));
      childIndex = _TreeGetNextSiblingIndex(childIndex);
   }

   // Still save all the tree items.  This is how we will restore the tree's 
   // state
   filename := _ConfigPath():+TREE_INFO_FILENAME;
   xmlhandle := _xmlcfg_create(filename,VSENCODING_UTF8,VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
   if ( xmlhandle>=0 ) {
      ctlURLTree._TreeSaveDataXML(xmlhandle);
   }
   _xmlcfg_close(xmlhandle);
}

void ctlclose.on_destroy()
{
   ctlURLTree.saveTree();
}

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

static _str getRepository()
{
   origWID := p_window_id;
   p_window_id = ctlURLTree;
   index := _TreeCurIndex();
   cap := "";
   for (;;) {
      if (index<=0) break;
      cap = _TreeGetCaption(index):+'/':+cap;
      index = _TreeGetParentIndex(index);
   }
   p_window_id = origWID;
   return cap;
}

static void refreshTree()
{
   DateTime dateBack;
   _getDateFromNameInTextbox(dateBack);
   URL := getRepository();
   existingURL := _GetDialogInfoHt("existingURL");
   refillTree(URL,dateBack);
   _SetDialogInfoHt("existingURL",URL);
   filterTree(ctlsearch_text.p_text);
}

void _getDateFromNameInTextbox(DateTime &dateBack)
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
   case DATE_ENDING_PAST_2_YEARS:
      dateBack = startToday.add(-2, se.datetime.DT_YEAR);
      break;
   case DATE_ENDING_PAST_5_YEARS:
      dateBack = startToday.add(-5, se.datetime.DT_YEAR);
      break;
   case DATE_ENDING_FOREVER:
      dateBack = startToday.add(-100, se.datetime.DT_YEAR);
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
   vcSystem := _GetDialogInfoHt("vcSystem");
   if ( vcSystem==null || vcSystem=="" ) {
      // For the time being, this code only applies to Subversion
      vcSystem = "subversion";
   }
   IVersionControl *pInterface = svcGetInterface(vcSystem);
   if ( pInterface==null ) {
      return;
   }
   historyInfo = _GetDialogInfoHt(URL:+dateBack.toString());
   if ( historyInfo==null ) {
      mou_hour_glass(true);

      status := pInterface->getRepositoryInformation(URL,historyInfo,dateBack);
      if ( status ) {
         _message_box("Could not get information for repository %s",URL);
      }
      _SetDialogInfoHt(URL:+dateBack.toString(),historyInfo);
   }
   ctltree1._TreeDelete(TREE_ROOT_INDEX,'C');
   fillInTree(historyInfo);
   mou_hour_glass(false);
}

static void filterTree(_str filterText)
{
   noteTable := _GetDialogInfoHt("noteTable");
   sstring := filterText;
   if ( sstring=="" ) {
      showAll();
      return;
   }
   mou_hour_glass(true);
   hideAll();
   getSerachArray(sstring,auto searchArray,auto joinArray);

   int results[][];

   STRHASHTAB tableCopies[];
   makeNewCopy := true;
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
   mou_hour_glass(false);
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

static void getWidthsAndHeights(int &clientWidth, int &clientHeight, 
                                int &bufferX, int &bufferY)
{
   clientHeight = _dy2ly(SM_TWIP,p_active_form.p_client_height);
   clientWidth = _dx2lx(SM_TWIP,p_active_form.p_client_width);
   topLabelWID := ctlURLTree.p_prev;
   bufferY = topLabelWID.p_y;
   bufferX = topLabelWID.p_x;
}

void _svc_repository_browser.on_load()
{
   ctlsearch_text._set_focus();
   getWidthsAndHeights(auto clientWidth,auto clientHeight,auto bufferX,auto bufferY);
   _set_minimum_size(ctlrevisions.p_x_extent+bufferX, -1);
   p_active_form.p_width=ctlrevisions.p_x_extent+bufferX;
}

void ctlclose.on_create(_str repositoryURL="",_str vcSystem="")
{
   _SetDialogInfoHt("vcSystem",vcSystem);
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
   _lbadd_item(DATE_ENDING_PAST_2_YEARS);
   _lbadd_item(DATE_ENDING_PAST_5_YEARS);
   _lbadd_item(DATE_ENDING_FOREVER);

   p_text = DATE_ENDING_PAST_WEEK;

   p_window_id = origWID;
   loadTree();
}


void ctladd_url.lbutton_up()
{
   URL := "";
   for (;;) {
      _param1='';
      _str result = show('-modal _textbox_form',
                         'Add Version Control URL', // Form caption
                         0,  //flags
                         '', //use default textbox width
                         '', //Help item.
                         '', //Buttons and captions
                         'svn add repository', //Retrieve Name
                         'URL:'
                        );

      if ( result=='' ) {
         return;
      }
      URL = strip(_param1);
      if ( (_isWindows() && pos(':',URL)==2) ||
           (_isUnix() && pos(':',URL)==0) ) {
         _message_box(nls("This must be a URL, not a local path"));
         continue;
      }
      if ( URL=="" ) {
         continue;
      }
      break;
   }
   origWID := p_window_id;
   _control ctlURLTree;
   p_window_id = ctlURLTree;
   int index=_TreeSearch(TREE_ROOT_INDEX,URL);
   if ( index>=0 ) {
      _message_box(nls("'%s' is already in the browser"));
      _TreeSetCurIndex(index);
      p_window_id = origWID;
      return;
   }
   int new_node_index=_TreeAddItem(TREE_ROOT_INDEX,URL,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,TREE_NODE_COLLAPSED);
   p_window_id = origWID;
   return;
}

static _str getRevisionsButtonCaption()
{
   return stranslate(ctlrevisions.p_caption,"",'&');
}

void ctlURLTree.on_change(int reason,int index)
{
   if ( index<=0 && reason!=CHANGE_SCROLL ) {
      ctlrevisions.p_enabled = false;
      ctlcheckout.p_enabled = false;
      ctlremove.p_enabled = false;
      if ( getRevisionsButtonCaption()==REVISIONS_LESS_CAPTION ) {
         ctlrevisions.call_event(ctlrevisions,LBUTTON_UP);
      }
      return;
   } else {
      ctlrevisions.p_enabled = true;
      ctlcheckout.p_enabled = true;
      ctlremove.p_enabled = true;
   }
   // For the time being, this code only applies to Subversion
   IVersionControl *pInterface = svcGetInterface("subversion");
   if ( pInterface==null ) return;
   switch ( reason ) {
   case CHANGE_EXPANDED:
      {
         if (_TreeGetFirstChildIndex(index)>=0) _TreeDelete(index,'C');
         url := parentURL(index);
         pInterface->getURLChildDirectories(url,auto paths);
         len := paths._length();
         for ( i:=0;i<len;++i ) {
            _TreeAddItem(index,paths[i],TREE_ADD_AS_CHILD,_pic_fldaop,_pic_fldaop,0);
         }
         _TreeSortCaption(index,_fpos_case'F');
      }
   case CHANGE_SELECTED:
      {
         if ( _TreeGetDepth(index)==1 ) {
            ctlremove.p_enabled = true;
         } else {
            ctlremove.p_enabled = false;
         }
         if ( getRevisionsButtonCaption()==REVISIONS_LESS_CAPTION ) {
            refreshTree();
         }
      }
   }
}

void ctlrevisions.lbutton_up()
{
   if (getRevisionsButtonCaption()==REVISIONS_MORE_CAPTION) {
      p_caption = "&"REVISIONS_LESS_CAPTION;
   }else{
      p_caption = "&"REVISIONS_MORE_CAPTION;
   }
   resizeDialog(true);
   if ( getRevisionsButtonCaption() == REVISIONS_LESS_CAPTION ) {
      ctldate.call_event(ctldate,ENTER);
   }
}

void ctlremove.lbutton_up()
{
   removeCurItem();
}

void ctlcheckout.lbutton_up()
{
   checkoutCurItem();
}

static void checkoutCurItem()
{
   wid := p_window_id;
   p_window_id = ctlURLTree;
   index := _TreeCurIndex();
   URL := parentURL(index);
   IVersionControl *pInterface = svcGetInterface("subversion");
   if ( pInterface==null ) return;

   SVC_CHECKOUT_INFO coInfo;
   coInfo.localPath='';
   coInfo.URL='';
   coInfo.createdPath='';
   coInfo.revision='';

   version := "";
   if ( getRevisionsButtonCaption()==REVISIONS_LESS_CAPTION ) {
      versionIndex := ctltree1._TreeCurIndex();
      if (versionIndex>0) {
         version = ctltree1._TreeGetCaption(versionIndex);
      }
   }

   if ( index<0 ) {
      return;
   }
   status := show('-modal _svc_checkout_form',URL,version,&coInfo);

   if ( status ) return;

   // switch to the proper local path
   local := coInfo.localPath;
   if ( coInfo.createdPath!="" ) {
      local = coInfo.createdPath;
   }
   pushd(local);

   // Now that we have switched to the path, set the local path to "" so that 
   // the URL is preserved
   if ( coInfo.preserveURL ) local = "";

   status = pInterface->checkout(URL,local,0,coInfo.revision);
   popd();

   p_window_id = wid;

   p_active_form._delete_window();
}

static void removeCurItem()
{
   wid := p_window_id;
   p_window_id = ctlURLTree;
   index := _TreeCurIndex();
   if ( index>=0 ) {
      _TreeDelete(index);
      ctlURLTree.call_event(CHANGE_SELECTED,_TreeCurIndex(),ctlURLTree,ON_CHANGE,'W');
   }
   p_window_id = wid;
}

static _str parentURL(int index)
{
   URL := "";
   for (;;) {
      if ( index<=TREE_ROOT_INDEX ) break;
      cap := _TreeGetCaption(index);
      URL = cap'/'URL;
      index = _TreeGetParentIndex(index);
   }
   return URL;
}

static void resizeDialog(bool setDialogWidth=false)
{
   inResize := _GetDialogInfoHt('inResizeDialog');
   if (inResize==1) {
      return;
   }
   if ( p_active_form.p_window_state=='M' ) {
      setDialogWidth = false;
   }
   _SetDialogInfoHt('inResizeDialog',1);
   hadFirstSize := _GetDialogInfoHt('hadFirstSize');
   if ( hadFirstSize==null ) {
      setDialogWidth = true;
      _SetDialogInfoHt('hadFirstSize',1);
   }

   // Note - width will be change depending on buton caption
   getWidthsAndHeights(auto clientWidth,auto clientHeight,auto bufferX,auto bufferY);

   topLabelWID := ctlURLTree.p_prev;
   labelWID := ctlURLTree.p_prev;

   ctlURLTree.p_x = labelWID.p_x;
   ctlURLTree.p_y = labelWID.p_y_extent;
   ctlURLTree.p_width = ctlrevisions.p_x_extent - (bufferX);
   buttonRowHeight := ctlclose.p_height+(2*bufferY);
   ctlURLTree.p_height = ((clientHeight - ctlURLTree.p_prev.p_height) -(2*bufferY)) - buttonRowHeight;

   if (getRevisionsButtonCaption()==REVISIONS_LESS_CAPTION) {
      if ( setDialogWidth ) {
         p_active_form.p_width = ctlminihtml1.p_x_extent + bufferX;
      }
      clientWidth = _dx2lx(SM_TWIP,p_active_form.p_client_width);
      ctlsearch_text.p_x = ctlsearch_text.p_prev.p_x_extent + bufferX;

      ctltree1.p_x = ctlsearch_text.p_prev.p_x = ctldate.p_prev.p_x = ctlURLTree.p_x_extent + (4*bufferX);
      ctlsearch_text.p_x = ctldate.p_x = ctldate.p_prev.p_x_extent;

      ctltree1.p_height = clientHeight-(ctltree1.p_y)-buttonRowHeight;
      ctltree1.p_y = ctlsearch_text.p_y_extent + bufferY;

      ctlminihtml1.p_x=ctltree1.p_x_extent+bufferX;
      ctlminihtml1.p_y=ctltree1.p_y;
      ctlminihtml1.p_height=ctltree1.p_height;

      ctlminihtml1.p_width=(clientWidth - ctltree1.p_x_extent) - (4*bufferX);

      fullSizeWidth := _GetDialogInfoHt("fullSizeWidth");
      if ( fullSizeWidth==null ) {
         fullSizeWidth = p_active_form.p_width;
         _SetDialogInfoHt("fullSizeWidth",fullSizeWidth);
      }
      p_active_form._set_minimum_size(fullSizeWidth, -1);
      setControlsVisible(true);
   } else {
      // First set min size to 0, so we can shrink dialog
      p_active_form._set_minimum_size(0, -1);
      setControlsVisible(false);
      if ( setDialogWidth ) {
         p_active_form.p_width = ctlrevisions.p_x_extent + bufferX;
         clientWidth = _dx2lx(SM_TWIP,p_active_form.p_client_width);
      }
      lastSize := _GetDialogInfoHt("lastSize");
      if ( lastSize!=null && lastSize<p_active_form.p_width ) {
         diff := p_active_form.p_width - lastSize;
         ctldate.p_x+=diff;
         ctldate.p_prev.p_x+=diff;
      }
      ctlURLTree.p_width = clientWidth - (2*bufferX);
      p_active_form._set_minimum_size(ctlrevisions.p_x_extent+bufferX, -1);



   }
   ctlclose.p_y = ctladd_url.p_y = ctlremove.p_y = ctlcheckout.p_y = ctlrevisions.p_y = ctlURLTree.p_y_extent+bufferY;

   sizeBrowseButtonToTextBox(ctlsearch_text.p_window_id, ctlsearch_clear.p_window_id, ctlsearch.p_window_id, ctltree1.p_x_extent);
   ctldate.p_width = ctlsearch_text.p_width;

   _SetDialogInfoHt('inResizeDialog',0);
}


static void setControlsVisible(bool visible)
{
   ctldate.p_visible = ctldate.p_prev.p_visible = ctlsearch_text.p_visible =
      ctlsearch_text.p_prev.p_visible = ctlsearch_clear.p_visible = 
      ctlsearch.p_visible = ctltree1.p_visible = ctlminihtml1.p_visible = 
      visible;
}

void _svc_repository_browser.on_resize()
{
   resizeDialog();
}

void ctlminihtml1.on_change(int reason,_str href="")
{
   switch ( reason ) {
   case CHANGE_CLICKED_ON_HTML_LINK:
      {
         if ( substr(href,1,7)=="slickc:" ) return;

         parse href with auto command ',' auto revision ',' auto remoteFilename;

         repostitoryURLFromTree := getRepository();
         URLRoot := getURLRoot(repostitoryURLFromTree);

         URL := URLRoot:+remoteFilename;
         switch ( command ) {
         case "history":
            svc_history(URL,SVC_HISTORY_NONE,revision,true);
            break;
         case "historydiff":
            svc_history_diff(URL,"",revision);
            break;
         }
      }
      break;
   }
}

static _str getURLRoot(_str URL) {
   IVersionControl *pInterface = svcGetInterface("subversion");
   if ( pInterface==null ) {
      return("");
   }
   pInterface->getRepositoryRoot(URL,auto URLRoot);
   return URLRoot;
}

static const CLICK_CAPTION= "Double click to get "DEFAULT_NUM_VERSIONS_IN_REP_BROWSER" more versions";

static void getVersionInfo(SVCHistoryInfo &historyInfo,STRARRAY &lineArray)
{
   if ( historyInfo.author!="" ) lineArray[lineArray._length()]='<B>Author:</B>&nbsp;'historyInfo.author'<br>';
   if ( historyInfo.date!="" && historyInfo.date!=0 ) lineArray[lineArray._length()]='<B>Date:</B>&nbsp;':+strftime("%c",historyInfo.date):+'<br>';
   // Replace comment string line endings with <br> to preserve formatting
   commentBR := stranslate(historyInfo.comment, '<br>', '\n', 'l');
   if ( commentBR!="" ) {
      lineArray[lineArray._length()]='<B>Comment:</B>&nbsp;'commentBR;
   }
   if( historyInfo.affectedFilesDetails :!= '' ) {
      curLine := '<br><B>Changed paths:</B><font face="Menlo, Monaco, Consolas, Courier New, Monospace">';
      for (;;) {
         parse historyInfo.affectedFilesDetails with '<br>','i' auto curFile '<br>','i' +0 historyInfo.affectedFilesDetails;
         if ( curFile=="" ) break;

         curLine :+= '<BR>';
         curLine :+= curFile"<BR> <A href=\"history,"historyInfo.revision","curFile\"">History</A>";
         curLine :+= '<BR>';
         curLine :+= " <A href=\"historydiff,"historyInfo.revision","curFile\"">History Diff</A>";
         curLine :+= '<BR>';
      }
      curLine :+= '</font>';
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
      line :+= ' 'curLine;
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
   // For the time being, this code only applies to Subversion
   IVersionControl *pInterface = svcGetInterface("subversion");
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
            infoStr :+= "\n":+info[i];
         }
         static int callbackIndex;
         if ( callbackIndex==0 ) {
           callbackIndex = find_index('_svc_format_html',PROC_TYPE);
         }
         if ( callbackIndex && index_callable(callbackIndex) ) {
            call_index(infoStr,callbackIndex);
         }
         _TextBrowserSetHtml(ctlminihtml1,infoStr);
      }
   }
}
