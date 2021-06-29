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
#pragma option(pedantic, on)
#region Imports
#include "slick.sh"
#import "calendar.e"
#import "listbox.e"
#import "stdprocs.e"
#import "stdcmds.e"
#import "treeview.e"
#import "DateTime.e"
#require "DateTimeInterval.e"
#import "guiopen.e"
#import "cfg.e"
#import "se/datetime/DateTimeFilters.e"
#endregion


using namespace se.datetime;


void get_DateTimeFilters(DateTimeInterval (*&DTFEntries):[],bool reinit=false) {
   DateTimeInterval (*dtFilters):[];
   dtFilters = _GetDialogInfoHtPtr('DateTimeFilters', _mdi);
   // IF importing from file or plugin XML
   if (reinit) {
      dtFilters=null;
   } else if (!dtFilters) {
      // Haven't fetched the plugin XML data. Fetch it now
      handle:=_plugin_get_property_xml(VSCFGPACKAGE_MISC,VSCFGPROFILE_DATE_TIME_FILTERS,'content');
      if (handle>=0) {
         node:=_xmlcfg_get_first_child(handle,0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
         importdateTimeFilters_from_xml(handle,node);
         _xmlcfg_close(handle);
      }
      dtFilters = _GetDialogInfoHtPtr('DateTimeFilters', _mdi);
      DTFEntries = dtFilters;
      return;
   }
   if (dtFilters) {
      DTFEntries = dtFilters;
      return;
   }

   DateTimeInterval dtFilterEntries:[];
   // Populate with our "automatic" intervals
   typeless iter;
   for (iter._makeempty();;) {
      g_autoDateTimeIntervals._nextel(iter);
      if (iter._isempty()) {
         break;
      }
      DateTimeInterval tmpDTI(g_autoDateTimeIntervals:[iter], iter);
      dtFilterEntries:[tmpDTI.getHashKey()] = tmpDTI;
   }
   // Note: if you don't want to start "This Week" on a Sunday, uncomment the
   // two thisWeek lines. Replace x with 0 for Sunday ... replace x with 6
   // for Saturday.
   //
   //DateTimeInterval thisWeek(DTI_AUTO_THIS_WEEK, "This Week", x);
   //dtFilterEntries:[thisWeek.getHashKey()] = thisWeek;

   _SetDialogInfoHt('DateTimeFilters', dtFilterEntries, _mdi);
   dtFilters = _GetDialogInfoHtPtr('DateTimeFilters', _mdi);
   DTFEntries = dtFilters;
}



/**
 * Load the DateTimeFilters that were saved on exit.
 */
definit() {
   init_auto_datetimeintervals();
}
static void updateDateTimeFilters() {
   handle:=_xmlcfg_create('',VSENCODING_UTF8);
   property_node:=_xmlcfg_add_property(handle,0,'content');
   if(!writeFiltersToXml(handle,property_node)){
      _plugin_set_property_xml(VSCFGPACKAGE_MISC,VSCFGPROFILE_DATE_TIME_FILTERS,VSCFGPROFILE_DATE_TIME_FILTERS_VERSION,'content',handle);
   }
   _xmlcfg_close(handle);
}

_command void datetimefilter_manager (_str filterListName='All',
                                      bool useTime=false) name_info(',')
{
   _macro_delete_line();

   _str result = _mdi.show('-xy -modal _DateTimeFilters_manager_form',
                           filterListName, useTime);

   return;
}



defeventtab _DateTimeFilters_manager_form;
void _DateTimeFilters_manager_form.on_create (_str filterListName,
                                              bool useTime)
{
   _SetDialogInfoHt('filterListName', filterListName);
   _SetDialogInfoHt('useTime', useTime);

   caption := "";
   if (useTime) {
      p_caption = 'Active Date and Time Filters for 'filterListName;
   } else {
      p_caption = 'Active Date Filters for 'filterListName;
   }
   if (caption != '') {
      p_caption = caption;
   } else {
      p_caption = 'Active Date and Time Filters';
   }

   _DateTimeFilters_tree._TreeSetColButtonInfo(0, 1000, TREE_BUTTON_PUSHBUTTON, 0, 'Active');
   _DateTimeFilters_tree._TreeSetColButtonInfo(1, 1000, TREE_BUTTON_PUSHBUTTON, 0, 'Name');
   _DateTimeFilters_tree._TreeSetColButtonInfo(2, 10000, TREE_BUTTON_PUSHBUTTON, 0, 'Filter');
   populateDateTimeFiltersTree();
}


static void populateDateTimeFiltersTree ()
{
   _str filterListName = _GetDialogInfoHt('filterListName');
   useTime := _GetDialogInfoHt('useTime');

   _DateTimeFilters_tree._TreeBeginUpdate(TREE_ROOT_INDEX);
   _DateTimeFilters_tree._TreeDelete(TREE_ROOT_INDEX, "C");
   

   DateTimeInterval (*dtFilters):[];
   get_DateTimeFilters(dtFilters);

   checked := TCB_UNCHECKED;
   index := 0;
   foreach (auto o in (*dtFilters)) {
      if (o.m_activeFilterLists._indexin(filterListName)) {
         if (o.m_activeFilterLists:[filterListName]) {
            checked = TCB_CHECKED;
         } else {
            checked = TCB_UNCHECKED;
         }
      } else {
         o.m_activeFilterLists:[filterListName] = false;
         checked = TCB_UNCHECKED;
      }

      o.setStringFormat(DTIS_PLAIN_LOCAL);
      if (useTime) {
         o.setDateTimeParts(DT_DATE_TIME);
      } else {
         o.setDateTimeParts(DT_DATE);
      }

      index = _DateTimeFilters_tree._TreeAddItem(TREE_ROOT_INDEX," \t"o.getHashKey():+
                                                 "\t"o.toString(),TREE_ADD_AS_CHILD,
                                                 0, 0, TREE_NODE_LEAF, 0);
      _DateTimeFilters_tree._TreeSetCheckable(index, 1, 0);
      _DateTimeFilters_tree._TreeSetCheckState(index, checked);

   }
   _DateTimeFilters_tree._TreeEndUpdate(TREE_ROOT_INDEX);
   _DateTimeFilters_tree._TreeSortCol(1);

   // Make sure that the "auto" filters can't be removed.
   index = _DateTimeFilters_tree._TreeCurIndex();
   filterName := '';
   if (index > 0) {
      caption := _DateTimeFilters_tree._TreeGetCaption(index);
      parse caption with " \t" filterName "\t" .;
   }
   if (g_autoDateTimeIntervals._indexin(filterName)) {
      _remove_button.p_enabled = false;
   } else {
      _remove_button.p_enabled = true;
   }
}


void _DateTimeFilters_manager_form.on_resize ()
{
   // minimum widths/heights - any smaller than this and the dialog looks stupid
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(6500, 3100);
   }

   // use this to pad between controls
   padding := _DateTimeFilters_tree.p_y;

   // move the buttons left or right
   _add_button.p_x = _remove_button.p_x = _import_button.p_x = 
      _export_button.p_x = _ok_button.p_x = p_width - padding - _add_button.p_width;

   _DateTimeFilters_tree.p_height = p_height - 2 * padding;
   _DateTimeFilters_tree.p_x_extent = _add_button.p_x - padding;

   _DateTimeFilters_tree._TreeRetrieveColButtonInfo();

   _ok_button.p_y = _DateTimeFilters_tree.p_y +
                    _DateTimeFilters_tree.p_height - _ok_button.p_height;

}
void _DateTimeFilters_manager_form.on_destroy ()
{
   _DateTimeFilters_tree._TreeAppendColButtonInfo();
}

void _DateTimeFilters_manager_form.esc ()
{
   updateDateTimeFilters();
   p_active_form._delete_window(COMMAND_CANCELLED_RC);
}

void _ok_button.lbutton_up ()
{
   updateDateTimeFilters();
   p_active_form._delete_window(0);
}

void _export_button.lbutton_up ()
{
   updateDateTimeFilters();
   fileName := getFileName('Export');
   exportDateTimeFilters(fileName);
}

void _import_button.lbutton_up ()
{
   fileName := getFileName('Import');
   _importDateTimeFilters(fileName);
   populateDateTimeFiltersTree();
}



void _add_button.lbutton_up ()
{
   useTime := _GetDialogInfoHt('useTime');
   DateTimeInterval (*dtFilters):[];
   get_DateTimeFilters(dtFilters);
   
   suggestedName := "";
   i := 1;
   do {
      suggestedName = "Filter ":+ i;
      ++i;
   } while ((*dtFilters)._indexin(suggestedName));

   DateTimeInterval DTIResult;
   _str result = show('-modal _DateTimeFilter_form', &DTIResult, suggestedName, useTime);
   if (DTIResult != null) {
      _str filterListName = _GetDialogInfoHt('filterListName');
      if (filterListName) {
         DTIResult.m_activeFilterLists:[filterListName] = true;
      }
      (*dtFilters):[DTIResult.getHashKey()] = DTIResult;

      DTIResult.setStringFormat(DTIS_PLAIN_LOCAL);
      if (useTime) {
         DTIResult.setDateTimeParts(DT_DATE_TIME);
      } else {
         DTIResult.setDateTimeParts(DT_DATE);
      }

      index := _DateTimeFilters_tree._TreeAddItem(TREE_ROOT_INDEX,
                                                  " \t"DTIResult.getHashKey()"\t":+
                                                  DTIResult.toString(),
                                                  TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      _DateTimeFilters_tree._TreeSetCheckable(index, 1, 0);
      _DateTimeFilters_tree._TreeSetCheckState(index, TCB_CHECKED);
   }
}

void _remove_button.lbutton_up ()
{
   index := _DateTimeFilters_tree._TreeCurIndex();
   if (index > 0) {
      hashKey := "";
      parse _DateTimeFilters_tree._TreeGetCaption(index) with " \t" hashKey "\t".;
      DateTimeInterval (*dtFilters):[];
      get_DateTimeFilters(dtFilters);
      (*dtFilters)._deleteel(hashKey);

      _DateTimeFilters_tree._TreeDelete(index);
   }
}


void _DateTimeFilters_tree.on_change (int reason, int index, int col=-1)
{
   switch (reason) {
   case CHANGE_SELECTED:
      caption := _DateTimeFilters_tree._TreeGetCaption(index);
      filterName := '';
      parse caption with " \t" filterName "\t" .;
      if (g_autoDateTimeIntervals._indexin(filterName)) {
         _remove_button.p_enabled = false;
      } else {
         _remove_button.p_enabled = true;
      }
      break;

   case CHANGE_CHECK_TOGGLED:
      filterListName := _GetDialogInfoHt('filterListName');
      DateTimeInterval (*dtFilters):[];
      get_DateTimeFilters(dtFilters);
      hashIndex := '';
      parse _TreeGetCaption(index) with " \t" hashIndex "\t" .;

      checked := _TreeGetCheckState(index);
      ((*dtFilters):[hashIndex]).m_activeFilterLists:[filterListName] = (checked == TCB_CHECKED);
      break;
   }
}

static int writeXmlDeclaration(int treeHandle)
{
   status := 0;

   //Create the XML declaration.
   do {
      int xmldecl_index = _xmlcfg_add(treeHandle, TREE_ROOT_INDEX, 'xml',
                                      VSXMLCFG_NODE_XML_DECLARATION,
                                      VSXMLCFG_ADD_AS_CHILD);
      if (xmldecl_index < 0) {
         status = xmldecl_index;
         break;
      }

      status = _xmlcfg_set_attribute(treeHandle, xmldecl_index, 'version', '1.0');
      if (status < 0) break;

      status = _xmlcfg_set_attribute(treeHandle, xmldecl_index, 'encoding', 'UTF-8');
      if (status < 0) break;

      // if we got here, then everything is fine!
      status = 0;

   } while (false);

   return status;
}

static int writeXmlTree(int treeHandle)
{
   status := 0;

   //Add the main tree.
   do {
      dtfsNode := _xmlcfg_add(treeHandle, TREE_ROOT_INDEX, 'DateTimeFilters',
                            VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      if (dtfsNode < 0) {
         status = dtfsNode;
         break;
      }

      status = _xmlcfg_add_attribute(treeHandle, dtfsNode, 'version', '1.0');
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, dtfsNode, 'productName',
                                     _getApplicationName());
      if (status < 0) break;


      status = _xmlcfg_add_attribute(treeHandle, dtfsNode, 'productVersion',
                                     _getVersion());
      if (status < 0) break;

      // finally, write the filters
      status = writeFiltersToXml(treeHandle, dtfsNode);

   } while (false);

   return status;
}

static int writeFiltersToXml(int treeHandle, int dtfsNode)
{
   status := 0;

   //Add filters.
   DateTimeInterval (*dtFilters):[];
   get_DateTimeFilters(dtFilters);
   filterNode := 0;
   aolNode := 0;
   typeless iter;

   foreach (auto o in (*dtFilters)) {
      filterNode = _xmlcfg_add(treeHandle, dtfsNode, 'Filter',
                               VSXMLCFG_NODE_ELEMENT_START_END,
                               VSXMLCFG_ADD_AS_CHILD);
      if (filterNode < 0) {
         status = filterNode;
         break;
      }

      status = _xmlcfg_add_attribute(treeHandle, filterNode, 'name',
                                     o.getHashKey());
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, filterNode, 'interval',
                                     o.toString());
      if (status < 0) break;

      // go through the active lists
      for (iter._makeempty();;) {
         o.m_activeFilterLists._nextel(iter);
         if (iter._isempty()) {
            break;
         }

         aolNode = _xmlcfg_add(treeHandle, filterNode, 'ActiveOnList',
                               VSXMLCFG_NODE_ELEMENT_START_END,
                               VSXMLCFG_ADD_AS_CHILD);
         status = _xmlcfg_add_attribute(treeHandle, aolNode, 'name', iter);
         if (status < 0) break;

         status = _xmlcfg_add_attribute(treeHandle, aolNode, 'value',
                                        o.m_activeFilterLists:[iter]);
         if (status < 0) break;
      }
   }

   // positive values are okay
   if (status > 0) {
      status = 0;
   }

   return status;
}

static void exportDateTimeFilters (_str fileName='')
{
   if (fileName == '') return;
   _plugin_export_profile_to_file(fileName,VSCFGPACKAGE_MISC,VSCFGPROFILE_DATE_TIME_FILTERS,false);
}

static void importdateTimeFilters_from_xml(int treeHandle,int dtfsNode) {
   DateTimeInterval (*dtFilters):[];
   get_DateTimeFilters(dtFilters,true);

   _str filterName;
   _str interval;
   _str aolName;
   _str value;
   filterNode := 0;
   aolNode := 0;

   _str intervalLeft;
   _str intervalRight;

   DateTimeInterval inDTI;

   filterNode = _xmlcfg_find_child_with_name(treeHandle, dtfsNode, 'Filter',
                                             VSXMLCFG_NODE_ELEMENT_START);
   while (filterNode > 0) {
      inDTI = null;

      filterName = _xmlcfg_get_attribute(treeHandle, filterNode, 'name', '');

      // If the filter is an automatic filter, it should already be in
      // (*dtFilters) and we only want to import which filter lists it is
      // active on.
      if (g_autoDateTimeIntervals._indexin(filterName) && 
          (*dtFilters)._indexin(filterName)) {
         inDTI = (*dtFilters):[filterName];
      } else if (filterName != "" ) {
         interval = _xmlcfg_get_attribute(treeHandle, filterNode, 'interval', '');

         inDTI = DateTimeInterval.fromString(filterName, interval);
      } 

      if (inDTI != null) {
         // now go through the active lists
         aolNode = _xmlcfg_find_child_with_name(treeHandle, filterNode,
                                                'ActiveOnList',
                                                VSXMLCFG_NODE_ELEMENT_START_END);

         while (aolNode > 0) {

            aolName = _xmlcfg_get_attribute(treeHandle, aolNode, 'name', '');
            value = _xmlcfg_get_attribute(treeHandle, aolNode, 'value', '');

            if (aolName != '' && value != '') {
               if (value == 0) {
                  inDTI.m_activeFilterLists:[aolName] = false;
               } else {
                  inDTI.m_activeFilterLists:[aolName] = true;
               }
            }
            aolNode = _xmlcfg_get_next_sibling(treeHandle, aolNode,
                                                  VSXMLCFG_NODE_ELEMENT_START_END);
         }

         (*dtFilters):[inDTI.getHashKey()] = inDTI;
      }

      filterNode = _xmlcfg_get_next_sibling(treeHandle, filterNode,VSXMLCFG_NODE_ELEMENT_START);
   }
}

void _importDateTimeFilters (_str filename='') {
   if (filename == '') {
      return;
   }
   status := 0;
   int treeHandle = _xmlcfg_open(filename, status, 0, VSENCODING_UTF8);
   if (treeHandle < 0) {
      _message_box("Could not import DateTime filters from "filename);
      return;
   }

   int dtfsNode;
   if (endsWith(filename,VSCFGFILEEXT_CFGXML,false,_fpos_case)) {
      // Get options node;
      dtfsNode = _xmlcfg_get_first_child(treeHandle, 0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      if (dtfsNode < 0) {
         _message_box(get_message(dtfsNode));
         return;
      }
      // get profile node
      dtfsNode = _xmlcfg_get_first_child(treeHandle, dtfsNode,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      if (dtfsNode < 0) {
         _message_box(get_message(dtfsNode));
         return;
      }

   } else {
      dtfsNode = _xmlcfg_get_first_child(treeHandle, 0,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      if (dtfsNode < 0) {
         _message_box(get_message(dtfsNode));
         return;
      }
   }
   importdateTimeFilters_from_xml(treeHandle,dtfsNode);

   _xmlcfg_close(treeHandle);
}




static _str getFileName(_str caption)
{
   fileName := "";
   initDir := get_env("HOME");
   format_list :=  'XML Config Files (*.cfg.xml),All Files ('ALLFILES_RE')';
   unixflags := 0;
   if (_isUnix()) {
      _str attrs = file_list_field(fileName, DIR_ATTR_COL, DIR_ATTR_WIDTH);
      _str w = pos('w', attrs, '', 'i');
      if (!w && (attrs != '')) {
         unixflags = OFN_READONLY;
      }
   }
   _str outFileName = _OpenDialog('-modal',
                                  caption,
                                  "*.xml",
                                  format_list,
                                  unixflags,
                                  '',//def_ext,      // Default extensions
                                  'DateTimeFilters.cfg.xml', // Initial filename
                                  initDir,      // Initial directory
                                  '',      // Reserved
                                  "Open dialog box"
                                 );
   return outFileName;
}


static const COMPARISON_GREATER_THAN=        '>';
static const COMPARISON_LESS_THAN=           '<';
static const COMPARISON_EQUAL=               '=';

defeventtab _DateTimeFilter_form;
void _DateTimeFilter_form.on_create (DateTimeInterval* returnDTI=null,
                                     _str suggestedName='',
                                     bool showTime=false)
{
   // do some initial adjustment for auto-sized controls
   _DateTimeFilter_form_initial_alignment(showTime);

   _SetDialogInfoHt('returnDTI', returnDTI);

   // set the form caption
   if (showTime) {
      p_caption = 'Date and Time Filter';
   } else {
      p_caption = 'Date Filter';
   }

   // suggest a name for them, in case they're not the creative type
   _name.p_text = suggestedName;

   if (showTime) {
      // fill in some combo boxes!
      _upper_range_hours._lbclear();
      _lower_range_hours._lbclear();
      _comparison_hours._lbclear();
      for (i := 0; i < 24; ++i) {
         _upper_range_hours._lbadd_item(i);
         _lower_range_hours._lbadd_item(i);
         _comparison_hours._lbadd_item(i);
      }

      _upper_range_minutes._lbclear();
      _lower_range_minutes._lbclear();
      _comparison_minutes._lbclear();
      for (i = 0; i < 60; ++i) {
         _upper_range_minutes._lbadd_item(i);
         _lower_range_minutes._lbadd_item(i);
         _comparison_minutes._lbadd_item(i);
      }
   }

   _comparison_relation._lbclear();
   _comparison_relation._lbadd_item(COMPARISON_GREATER_THAN);
   _comparison_relation._lbadd_item(COMPARISON_LESS_THAN);
   _comparison_relation._lbadd_item(COMPARISON_EQUAL);
   _comparison_relation.p_text = COMPARISON_GREATER_THAN;

   // get the current date and time, to fill in
   DateTime nowDT;
   _str nowDate = nowDT.toStringParts(DT_LOCALTIME, DT_DATE);

   _upper_range_date.p_ReadOnly = false;
   _lower_range_date.p_ReadOnly = false;
   _comparison_date.p_ReadOnly = false;
   _upper_range_date.p_text = nowDate;
   _lower_range_date.p_text = nowDate;
   _comparison_date.p_text = nowDate;
   _upper_range_date.p_ReadOnly = true;
   _lower_range_date.p_ReadOnly = true;
   _comparison_date.p_ReadOnly = true;

   hour := nowDT.hour();
   minute := nowDT.minute();

   _upper_range_hours._cbset_text(hour);
   _lower_range_hours._cbset_text(hour);
   _comparison_hours._cbset_text(hour);

   _upper_range_minutes._cbset_text(minute);
   _lower_range_minutes._cbset_text(minute);
   _comparison_minutes._cbset_text(minute);


   // this will enable/disable the right frames
   _comparison.call_event(_comparison, LBUTTON_UP, 'W');
}

static void _DateTimeFilter_form_initial_alignment(bool showTime)
{
   _name.p_x = _name_label.p_x_extent + 20;
   _name.p_width = p_active_form.p_width - _name_label.p_x - _name.p_x;

   if (!showTime) {
      // we do not need the hour and minute controls
      _upper_range_hours.p_visible = false;
      _lower_range_hours.p_visible = false;
      _comparison_hours.p_visible = false;
      _upper_range_minutes.p_visible = false;
      _lower_range_minutes.p_visible = false;
      _comparison_minutes.p_visible = false;
      _upper_range_hours_label.p_visible = false;
      _lower_range_hours_label.p_visible = false;
      _comparison_hours_label.p_visible = false;
      _upper_range_minutes_label.p_visible = false;
      _lower_range_minutes_label.p_visible = false;
      _comparison_minutes_label.p_visible = false;

      // since we disappeared some things, adjust everything else
      shift := _lower_range_hours.p_height;

      _comparison_frame.p_height -= shift;

      _range.p_y -= shift;
      _range_frame.p_y -= shift;

      _upper_range_date_label.p_y -= shift;
      _upper_range_relation_label.p_y -= shift;
      _upper_range_date.p_y -= shift;
      _upper_range_calendar.p_y -= shift;
      _upper_range_hours_label.p_y -= shift;
      _upper_range_hours.p_y -= shift;
      _upper_range_minutes_label.p_y -= shift;
      _upper_range_minutes.p_y -= shift;

      _range_frame.p_height -= (2 * shift);

      _ok_button.p_y -= (3 * shift);
      _cancel_button.p_y = _ok_button.p_y;

      p_active_form.p_height -= (3 * shift);
   }
}

void _comparison.lbutton_up()
{
   _comparison_frame.p_enabled = (_comparison.p_value != 0);
   _range_frame.p_enabled = (_range.p_value != 0);
}

void _upper_range_calendar.lbutton_up ()
{
   _nocheck _control _upper_range_date;
   int date = _upper_range_date;
   populateDateFieldFromCalendar(date);
}
void _lower_range_calendar.lbutton_up ()
{
   _nocheck _control _lower_range_date;
   int date = _lower_range_date;
   populateDateFieldFromCalendar(date);
}
void _comparison_calendar.lbutton_up ()
{
   _nocheck _control _comparison_date;
   int date = _comparison_date;
   populateDateFieldFromCalendar(date);
}
static void populateDateFieldFromCalendar (int& tbIn)
{
   _str yyyy = -1;
   _str mm = 0;
   _str dd = 0;
   if (tbIn.p_text != '') {
      parse tbIn.p_text with yyyy '-' mm '-' dd;
   }
   DateTime previousDate((int)yyyy, (int)mm, (int)dd);

   DateTime returnDate;
   show('-modal _calendar_form', previousDate, 0, null, &returnDate);
   if (returnDate != null) {
      newDate := "";
      parse returnDate.toString() with newDate 'T' .;
      tbIn.p_ReadOnly = false;
      tbIn.p_text = newDate;
      tbIn.p_ReadOnly = true;
   }
}

void _ok_button.lbutton_up ()
{
   // first, validate the name
   filterName := _name.p_text;
   if (filterName == '') {
      // no filter name?
      _message_box("Please enter a filter name.");
      _name._set_focus();
      return;
   } else {
      // make sure this name hasn't already been taken
      DateTimeInterval (*dtFilters):[];
      get_DateTimeFilters(dtFilters);

      if ((*dtFilters)._indexin(filterName)) {
         _message_box("The filter name you entered is already in use.  Please enter a unique filter name.");
         _name._set_focus();
         return;
      }
   }

   DateTimeInterval* returnDTI = _GetDialogInfoHt('returnDTI');
   typeless yyyy = '', mm = '', dd = '', hours = '', mins = '';

   showTime := _comparison_hours.p_visible;

   // If _upper_range_date, _lower_range_date, and _comparison_hours are
   // visible then they should be used. Otherwise the DateTimeInterval should be
   // made starting/ending at midnight, because the DateTimeFilters manager is
   // currently only aware of dates.
   if (_comparison.p_value) {

      // make sure we have a date in here
      if (_comparison_date.p_text == '') {
         _message_box("Please enter a date.");
         _comparison_date._set_focus();
         return;
      }

      parse _comparison_date.p_text with yyyy '-' mm '-' dd;

      // are we showing the hours and minutes?
      if (showTime) {
         // verify them
         if (!isinteger(_comparison_hours.p_text)) {
            _message_box("Please enter a valid number of hours.");
            _comparison_hours._set_focus();
            return;
         }
         if (!isinteger(_comparison_minutes.p_text)) {
            _message_box("Please enter a valid number of minutes.");
            _comparison_minutes._set_focus();
            return;
         }
         hours = _comparison_hours.p_text;
         mins = _comparison_minutes.p_text;
      } else {
         hours = 24;
         mins = 0;
      }

      DateTimeInterval dateComparisonDTI();
      switch (_comparison_relation.p_text) {
      case COMPARISON_GREATER_THAN:
         DateTime gtDT(yyyy, mm, dd, hours, mins, 0, 0.0);
         DateTimeInterval gtDTI(DTI_START_DURATION, filterName, gtDT, null);
         dateComparisonDTI = gtDTI;
         break;
      case COMPARISON_EQUAL:
         if (showTime) {
            DateTime comparisonDT(yyyy, mm, dd, hours, mins, 0, 0.0);
            DateTimeInterval eqDTI(DTI_START_END, filterName, comparisonDT,
                                   comparisonDT);
            dateComparisonDTI = eqDTI;
         } else {
            DateTime dateLtDT(yyyy, mm, dd, 24, 0, 0, 0.0);
            DateTime dateGtDT(yyyy, mm, dd, 0, 0, 0, 0.0);
            DateTimeInterval dateEqDTI(DTI_START_END, filterName, dateGtDT,
                                       dateLtDT);
            dateComparisonDTI = dateEqDTI;
         }
         break;
      case COMPARISON_LESS_THAN:
         DateTime ltDT(yyyy, mm, dd, hours, mins, 0, 0.0);
         DateTimeInterval ltDTI(DTI_DURATION_END, filterName, null, ltDT);
         dateComparisonDTI = ltDTI;
         break;
      }
      if (returnDTI) {
         *returnDTI = dateComparisonDTI;
      }
   } else {
      // I guess it's a range, then
      if (_upper_range_date.p_text == '') {
         _message_box("Please enter a date.");
         _upper_range_date._set_focus();
         return;
      }
      if (_lower_range_date.p_text == '') {
         _message_box("Please enter a date.");
         _lower_range_date._set_focus();
         return;
      }

      // get our hour and minute values
      parse _upper_range_date.p_text with yyyy '-' mm '-' dd;
      if (showTime) {
         // verify them first
         if (!isinteger(_upper_range_hours.p_text)) {
            _message_box("Please enter a valid number of hours.");
            _upper_range_hours._set_focus();
            return;
         }
         if (!isinteger(_upper_range_minutes.p_text)) {
            _message_box("Please enter a valid number of minutes.");
            _upper_range_minutes._set_focus();
            return;
         }
         hours = _upper_range_hours.p_text;
         mins = _upper_range_minutes.p_text;
      } else {
         hours = 24;
         mins = 0;
      }

      // put it all together
      DateTime upperDT(yyyy, mm, dd, hours, mins, 0, 0.0);

      if (_lower_range_date.p_text == '') {
         _message_box("Please enter a date.");
         _lower_range_date._set_focus();
         return;
      }

      parse _lower_range_date.p_text with yyyy '-' mm '-' dd;

      if (showTime) {
         // verify them first
         if (!isinteger(_lower_range_hours.p_text)) {
            _message_box("Please enter a valid number of hours.");
            _lower_range_hours._set_focus();
            return;
         }
         if (!isinteger(_lower_range_minutes.p_text)) {
            _message_box("Please enter a valid number of minutes.");
            _lower_range_minutes._set_focus();
            return;
         }
         hours = _lower_range_hours.p_text;
         mins = _lower_range_minutes.p_text;
      } else {
         hours = 0;
         mins = 0;
      }

      DateTime lowerDT(yyyy, mm, dd, hours, mins, 0, 0.0);

      DateTimeInterval dateRangeDTI(DTI_START_END, filterName, lowerDT,
                                    upperDT);
      if (returnDTI) {
         *returnDTI = dateRangeDTI;
      }
   }
   p_active_form._delete_window(0);
}

void _cancel_button.lbutton_up ()
{
   DateTimeInterval* returnDTI = _GetDialogInfoHt('returnDTI');
   if (returnDTI) {
      *returnDTI = null;
   }

   p_active_form._delete_window(COMMAND_CANCELLED_RC);
}
