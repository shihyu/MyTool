////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48162 $
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
#include "markers.sh"
#include "xml.sh"
#require "se/datetime/DateTime.e"
#import "se/datetime/DateTimeInterval.e"
#import "se/datetime/DateTimeFilters.e"
#import "cbrowser.e"
#import "context.e"
#import "files.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "mouse.e"
#import "mprompt.e"
#import "picture.e"
#import "project.e"
#import "recmacro.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tagwin.e"
#import "treeview.e"
#import "toolbar.e"
#import "wkspace.e"
#import "guidgen.e"
#import "calendar.e"
#endregion



using namespace se.datetime;



#define ANNOTATION_MAX_FIELD_SIZE_DISPLAYED 64
#define ANNOTATION_DATETIME_FILTERS "Code Annotations"
#define RELOC_MARKER_WINDOW_SIZE 5

// these are used with _SetDialogInfoHt
// retrieves the currently selected note.  This index corresponds to the note's index in the annotions table
#define CURRENT_NOTE_INDEX             'CurrentNoteIDX'
#define ANNOTATION_TREE_SORT_COLUMN    'SortColumn'
#define ANNOTATION_TREE_CHANGE_NOTE    'ChangeNote'
#define SHOW_TYPE                      'Show Type'
#define SCA_FILE                       'SCAFile'
#define ANNOTATION_TYPES               'Types'
#define ANNOTATIONS                    'Annotations'
#define SOURCE_FILE_NAME               'fileName'
#define NEW_NOTE                       'newNote'
#define NOTE_INDEX                     'noteIndex'
#define SKIP_DATE_TIME_FILTER_REFRESH  'SkipRefreshingDateTimeFilter'
#define FILTER_KEY_TIMER               'filterKeyTimer'

#define TEXT_CONTROL_TYPE              'Text Control'
#define DATE_CONTROL_TYPE              'Date Control'
#define MULTILINE_TEXT_CONTROL_TYPE    'Multiline Text Control'
#define DROPDOWN_CONTROL_TYPE          'Dropdown Control'
#define LIST_CONTROL_TYPE              'List Control'
#define CHECKBOX_CONTROL_TYPE          'Checkbox Control'

#define AUTHOR_FILTER                  'Author'
#define DATE_FILTER                    'Date'
#define VERSION_FILTER                 'Version'
#define SOURCE_FILE_FILTER             'Source File'
#define ANNOTATION_FILE_FILTER         'Annotation File'

enum AnnotationFilterType {
   AFT_GENERIC=0,
   AFT_DATETIME,
   AFT_OTHER
};



//Relocatable Code Marker info.
static double INSTANT_MATCH = 0.95;
static double CANDIDATE_MATCH = 0.8;
static double APPROVED_MATCH = 0.5;
static double LINE_WEIGHT = 0.6;
static double WINDOW_WEIGHT = 0.4;

/**
 * Number of milliseconds to attempt to relocate a single relocatable code 
 * marker. 
 *  
 * @default 1000 
 * @categories Configuration_Variables 
 */
int def_max_RELOC_MARKER_time=1000;

static int noteMarkerType = 0;
static int orphanedNoteMarkerType = 0;
static int annotationPic = 0;
static int orphanedAnnotationPic = 0;

struct RELOC_MARKER {
   int origLineNumber;
   int n;
   int aboveCount;
   int belowCount;
   int totalCount;
   _str sourceFile;
   _str origText[];
   _str textAbove[][];
   _str textBelow[][];
};

struct AnnotationFieldInfo {
   _str name;
   _str fieldType;
   _str text;
   _str editor[];
   _str list[];
   _str dropdown[];
   _str checkbox;
   _str defaultDate;
   int defaultIndices[];
   int dateOffset;
   int dateRadioSelection;
};

struct AnnotationTypeInfo {
   AnnotationFieldInfo fields[];
   int fieldsUsed[];
   _str id;
   _str author;
   _str creationDate;
   _str lastModifiedUser;
   _str lastModifiedDate;
   _str name;
   _str noteFiles:[];
   _str version;
};
static _str fieldTypes:[]:[]; //the field types for :[annotation type]:[field name]
static AnnotationTypeInfo annotationDefs[];
static int annotationTypes:[]; //Hash of type names to indices in annotationDefs.

static _str freshestType = ''; //The most recent type used.
static _str freshestFile = ''; //The more recent SCA file used.
static _str defTypes[]; //A list of the type names.
static _str defFiles[]; //A list of SCA file names.

struct Annotation {
   _str type;
   _str author;
   _str creationDate;
   _str lastModUser;
   _str lastModDate;
   _str noteDefVersion;
   _str version;
   _str noteFile;
   RELOC_MARKER marker;
   int lineMarker;
   AnnotationFieldInfo fields[];
   _str preview;
};
static Annotation annotations[];
static int annotationIndices:[][];

static int defC; //definition count

//Annotation indices.
static int allAnnotations[];
static int lastAnnotations[];
static int authors:[][];
static int dates:[][];
static int noteFiles:[][];
static int sourceFiles:[][];
static int shortNoteFiles:[][];
static int shortSourceFiles:[][];
static int types:[][];
static int versions:[][];
static int customFields:[][];
static int activeAnnotations:[];
static int lineMarkers:[];
static AnnotationTypeInfo activeType;

static boolean freshSourceFiles:[];

struct AnnotationDynamicControl {
   int labelH;
   int controlH;
};
static AnnotationDynamicControl dynControls[];
static int currentNote;



static _str workspaceSCA = '';
static _str projectSCA = '';
static _str personalSCA = '';
static _str SCAFiles:[]; //A hash of SCA file names.

static int bitmaps:[];

struct typeFieldIndices {
   int type;
   int field;
};


static _str previousType;
static _str currentType;
static _str currentField;

definit ()
{
   fieldTypes._makeempty();
   annotationDefs._makeempty();
   annotationTypes._makeempty();
   freshestType = '';
   freshestFile = '';
   defTypes._makeempty();
   defFiles._makeempty();
   annotations._makeempty();
   annotationIndices._makeempty();
   allAnnotations._makeempty();
   lastAnnotations._makeempty();
   authors._makeempty();
   dates._makeempty();
   noteFiles._makeempty();
   sourceFiles._makeempty();
   shortNoteFiles._makeempty();
   shortSourceFiles._makeempty();
   types._makeempty();
   versions._makeempty();
   customFields._makeempty();
   activeAnnotations._makeempty();
   lineMarkers._makeempty();
   activeType._makeempty();
   freshSourceFiles._makeempty();
   dynControls._makeempty();
   workspaceSCA = '';
   projectSCA = '';
   personalSCA = '';
   SCAFiles._makeempty();
   previousType = '';
   currentType = '';
   currentField = '';

   currentNote = -1;
   defC = 0;
   noteMarkerType = 0;
   orphanedNoteMarkerType = 0;

   if (upcase(arg(1)) == 'L') {
      //Module loaded with load command or loaded due to building state file.
      //if _annotation_tree is visible, delete everything in it.
      int wid = _find_formobj('_tbannotations_browser_form', 'n');
      if ((wid > 0) && _iswindow_valid(wid)) {
         wid.showFields(null);
      }
      reset_annotations();
      importAllAnnotations();
      _MarkerTypeSetCallbackMouseEvent(noteMarkerType, LBUTTON_DOWN,
                                       mouseClickAnnotation);

      // Take care of orphaned timer handles
      int fkID = _find_object('_tbannotations_browser_form._filter_key');
      if (fkID != 0) {
         int filterKeyTimer = -1;
         filterKeyTimer = fkID._GetDialogInfoHt(FILTER_KEY_TIMER, fkID);
         if ((filterKeyTimer != null) &&
             (filterKeyTimer > -1) &&
             _timer_is_valid(filterKeyTimer)) {
            _kill_timer(filterKeyTimer);
         }
         filterKeyTimer = _set_timer(60000, checkDateTimeFiltersFreshness);
         fkID._SetDialogInfoHt(FILTER_KEY_TIMER, filterKeyTimer, fkID);
      }
   } else {
      //Editor initialization case.
   }

}



/**
 * Handles safe_exit() callback.
 */
void _before_write_state_annotations ()
{
   fieldTypes = null;
   annotationDefs = null;
   annotationTypes = null;
   freshestType = '';
   freshestFile = '';
   defTypes = null;
   defFiles = null;
   annotations = null;
   annotationIndices = null;
   allAnnotations = null;
   lastAnnotations = null;
   authors = null;
   dates = null;
   noteFiles = null;
   sourceFiles = null;
   shortNoteFiles = null;
   shortSourceFiles = null;
   types = null;
   versions = null;
   customFields = null;
   activeAnnotations = null;
   lineMarkers = null;
   activeType = null;
   freshSourceFiles = null;
   dynControls = null;
   workspaceSCA = '';
   projectSCA = '';
   personalSCA = '';
   SCAFiles = null;
   previousType = '';
   currentType = '';
   currentField = '';
}

static int lastLineMarker = -1;
/**
 * Timer callback for updating annotation browser to possibly select the
 * annotation on the active buffer's current line.
 */
void _UpdateAnnotations ()
{
   /* 
      IF SlickEdit has not computed the line number, there can't be any annoations since
      the annotations require line numbers.
   */
   if (_mdi.p_child.point('L')<0) {
      return;
   }
   int lMarkers[]; //All line markers
   _LineMarkerFindList(lMarkers, _mdi.p_child, _mdi.p_child.p_RLine, 0, 0);

   //Find annotations among all line markers. 
   int noteMarker = -1;
   int i = 0;
   for (; i < lMarkers._length(); ++i) {
      if (lineMarkers._indexin(lMarkers[i])) {
         //If there is is more than one annotation on a line, bail: We won't be
         //able to determine which one should be selected in the annotation
         //browser.
         if (noteMarker != -1) {
            return;
         }
         noteMarker = lineMarkers:[lMarkers[i]];
      }
   }

   //If no annotations were found on the current line, reset lastLineMarker
   if (noteMarker == -1) {
      lastLineMarker = -1;
      return;
   }

   //If we're still on the same line, bail.
   if (noteMarker == lastLineMarker) {
      return;
   }

   //Update the annotation browser to select the annotation that corresponds
   //to the line marker on the current line.
   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      //Updating the browser will steal focus, so get the current focus.
      //int focusWid = _get_focus();
      wid.selectAnnotation(noteMarker,false);
      //focusWid._set_focus(); //Restore the focus.
   }

   lastLineMarker = noteMarker;
}

struct AnnotationSaveInfo {
   int index;
   int origLineNumber;
   RELOC_MARKER relocationInfo;
};

/**
 * Save the annotations in the current file, optionally restricting 
 * to a range of lines, and saving relocation information.
 * <p> 
 * This function is used to save annotation information before we do 
 * something that heavily  modifies a buffer, such as refactoring, 
 * beautification, or auto-reload.  It uses the relocatable marker 
 * information to attempt to restore the annotations back to their 
 * original line, even if the actual line number has changed because 
 * lines were inserted or deleted. 
 * 
 * @param annoSaves       Saved annotations           
 * @param startRLine    First line in region to save
 * @param endRLine      Last line in region to save
 * @param relocatable   Save relocation marker information? 
 *  
 * @see _RestoreAnnotationsInFile 
 *  
 * @categories Annotation_Functions 
 */
void _SaveAnnotationsInFile(AnnotationSaveInfo (&annoSaves)[],
                            int startRLine=0, int endRLine=0,
                            boolean relocatable=true)
{
   // For each annotation, save the ones that are in the current
   // file and within the specified region
   annoSaves._makeempty();
   _str bufName = maybe_quote_filename(p_buf_name);
   if (!sourceFiles._indexin(bufName)) return;
   int noteCount = sourceFiles:[bufName]._length();
   for ( i:=0; i < noteCount; ++i ) {

      // get the annotation index for this item
      j := sourceFiles:[bufName][i];

      // If the specified file does not match
      if ( !file_eq(annotations[j].marker.sourceFile, p_buf_name) ) {
         continue;
      }

      // get the annotation's actual line number
      int annotationLineNumber = annotations[j].marker.origLineNumber;
      _LineMarkerGet(annotations[j].lineMarker, auto lmInfo);
      if (annotationLineNumber != lmInfo.LineNum) {
         save_pos(auto p);
         p_RLine = lmInfo.LineNum;
         _BuildRelocatableMarker(annotations[j].marker);
         restore_pos(p);
         annotationLineNumber = lmInfo.LineNum;
      }

      // If the annotation is before the start of the line region
      if (startRLine > 0 && annotationLineNumber < startRLine) {
         continue;
      }

      // If the annotation is after the end of the line region
      if (endRLine > 0 && annotationLineNumber > endRLine) {
         continue;
      }

      // Save the relocation information for the annotation
      k := annoSaves._length();
      annoSaves[k].index = j;
      annoSaves[k].origLineNumber = annotationLineNumber; 
      annoSaves[k].relocationInfo = relocatable? annotations[j].marker : null;
   }
}

/**
 * Restore saved annotations from the current file and relocate them
 * if the annotation information includes relocation information. 
 * 
 * @param annoSaves        Saved annotations           
 * @param adjustLinesBy    Number of lines to adjust start line by
 *  
 * @see _SaveAnnotationsInFile 
 *  
 * @categories Annotation_Functions 
 */
void _RestoreAnnotationsInFile(AnnotationSaveInfo (&annoSaves)[], int adjustLinesBy=0)
{
   boolean resetTokens = true;
   save_pos(auto p);
   int noteIndices[];
   for (i := 0; i < annoSaves._length(); ++i) {

      // save the line marker indexes to update
      j := annoSaves[i].index;
      noteIndices[noteIndices._length()] = j;

      // adjust the start line if we were asked to
      if (adjustLinesBy && annoSaves[i].origLineNumber + adjustLinesBy > 0) {
         annoSaves[i].origLineNumber += adjustLinesBy;
         if (annoSaves[i].relocationInfo != null) {
            annoSaves[i].relocationInfo.origLineNumber += adjustLinesBy;
         }
      }

      // relocate the marker, presuming the file has changed
      int  origRLine   = annoSaves[i].origLineNumber;
      if (annoSaves[i].relocationInfo != null) {
         origRLine = _RelocateMarker(annoSaves[i].relocationInfo, resetTokens);
         resetTokens = false;
         if (origRLine < 0) {
            origRLine = annoSaves[i].relocationInfo.origLineNumber;
         }
      }

      //Move the line marker to the cursor's line.
      _LineMarkerRemove(annotations[j].lineMarker);
      _str noteMessage = '';
      int typeLength = length(annotations[j].type);
      strappend(noteMessage, '<code>'annotations[j].type'</code><br>');
      strappend(noteMessage, center('', typeLength, '-')'<br>');
      strappend(noteMessage, annotations[j].preview);
      int k = _LineMarkerAdd(p_window_id, origRLine, 0, 0,
                             annotationPic, noteMarkerType,
                             noteMessage);
      annotations[j].lineMarker = k;
      lineMarkers:[k] = j;

      //Rebuild the relocatable code marker
      p_RLine = origRLine;
      _BuildRelocatableMarker(annotations[j].marker, RELOC_MARKER_WINDOW_SIZE);

      //Save, with the new relocatable code marker information.
      exportAnnotations(annotations[j].noteFile);
   }

   //Update the annotation browser
   if (noteIndices._length() > 0) {
      updateAnnotationsBrowser(noteIndices);
   }

   restore_pos(p);
}

int _OnUpdate_new_annotation (CMDUI &cmdui,int target_wid,_str command)
{
   return MF_ENABLED;
}
/**
 * Called when a workspace is closed.
 */
void _wkspace_close_annotations ()
{
   //Close the previous workspace.sca file and remove all the appropriate
   //annotations and types.
   if ((workspaceSCA != null) && (workspaceSCA != '')) {
      removeSCAFile(workspaceSCA);
      cleanDefFiles();
   }
   workspaceSCA = '';
}



/**
 * Called when a workspace is opened.
 */
void _workspace_opened_annotations ()
{
   if (_workspace_filename != '') {
      _str wfn = _strip_filename(_workspace_filename, 'E')'_workspace.sca';
      wfn = maybe_quote_filename(wfn);
      workspaceSCA = wfn;
      importAnnotations(wfn);
   }
}



/**
 * Called when a project is closed. 
 */
void _prjclose_annotations ()
{
   //Close the previous project.sca file and remove all the appropriate
   //annotations and types.
   if ((projectSCA != null) && (projectSCA != '')) {
      removeSCAFile(projectSCA);
      cleanDefFiles();
   }
   projectSCA = '';
}



/**
 * Called when a project is opened. 
 */
void _prjopen_annotations ()
{
   if (_project_name != '') {
      _str pfn = _strip_filename(_project_name, 'E')'_project.sca';
      pfn = maybe_quote_filename(pfn);
      projectSCA = pfn;
      importAnnotations(pfn);
   }
}

/**
 * Callback function to support dragging around an annotation's gutter glyph. 
 * Registered in _srg_annotations(). 
 *  
 * Limitation: It is possible to have multiple annotations on the same line. 
 * Only one line marker is dragged at a time. Only the first line marker listed
 * will be passed to mouseClickAnnotation(). (The first line marker listed has 
 * its message at the top of the hover over preview, so users will know which 
 * annotation will be moved). 
 *  
 * @param MarkerIndex  The index to the line marker to be moved
 * 
 * @return int
 */
static int mouseClickAnnotation (int MarkerIndex)
{
   int origLine = p_line;

   //Drag the gutter glyph around.
   int status = mouse_drag(null, '_edannotation.ico');
   if (status < 0) {
      return status;
   }

   //Find the annotation corresponding to the line marker
   int i;
   if (!lineMarkers._indexin(MarkerIndex)) {
      return -1;
   }
   i = lineMarkers:[MarkerIndex];

   //Update the annotation browser to select the annotation that corresponds
   //to the line marker the user is clicking on/dragging.
   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.selectAnnotation(i);
   }

   //Move the line marker
   _LineMarkerRemove(annotations[i].lineMarker);
   int lMarkers[];
   _LineMarkerFindList(lMarkers, _mdi.p_child, _mdi.p_child.p_RLine, 0, 0);
   _str noteMessage = '';
   if (lMarkers._length() > 0) {
      noteMessage = '<br>';
   }
   int typeLength = length(annotations[i].type);
   strappend(noteMessage, '<code>'annotations[i].type'</code><br>');
   strappend(noteMessage, center('', typeLength, '-')'<br>');
   strappend(noteMessage, annotations[i].preview);
   int j = _LineMarkerAdd(_mdi.p_child, _mdi.p_child.p_RLine, 0, 0,
                          annotationPic, noteMarkerType,
                          noteMessage);
   annotations[i].lineMarker = j;
   lineMarkers:[j] = i;

   //Rebuild the relocatable code marker
   _mdi.p_child._BuildRelocatableMarker(annotations[i].marker,
                                        RELOC_MARKER_WINDOW_SIZE);

   //Update the annotation browser
   int abf = _find_formobj('_tbannotations_browser_form', 'n');
   if (abf > 0) {
      abf.showFields(lastAnnotations);
   }

   //Save, with the new relocatable code marker information.
   exportAnnotations(annotations[i].noteFile);

   return 0;
}



/**
 * Restore on a global (non per-project) basis.
 */
int _srg_annotations (_str option='', _str info='')
{
   typeless SCAFileCount;
   int i;
   _str SCAFile;
   _str SCAName;
   if ((option == 'R') || (option == 'N')) {
      //reset_annotations();
      parse info with SCAFileCount .;

      //Gather the previous freshest Type and File.
      _str fType;
      down();
      get_line(fType);
      _str fFile;
      down();
      get_line(fFile);
      SCAFileCount = SCAFileCount - 2;

      for (i = 0; i < SCAFileCount;) {
         down();
         get_line(SCAFile);
         // use environment variables, in case we upgrade, we don't 
         // want to save the path to our old config
         SCAFile = _replace_envvars(SCAFile);
         SCAFile = maybe_quote_filename(SCAFile);
         ++i;
         down();
         get_line(SCAName);
         ++i;

         //If specially named SCA files were in use, restore the actual names.
         //We need to remember these so we can close them automatically when
         //changing projects or workspaces.
         switch (SCAName) {
         case '(Workspace Annotations)':
            workspaceSCA = SCAFile;
            break;
         case '(Project Annotations)':
            projectSCA = SCAFile;
            break;
         case '(Personal Annotations)':
            personalSCA = SCAFile;
            break;
         }
         maybeAddSCAFile(SCAFile);
      }
      if (noteMarkerType) {
         _LineMarkerRemoveAllType(noteMarkerType);
      }
      importAllAnnotations();
      //If there are any annotations on startup, allow the browser to delete/
      //copy/relocate, etc.
      if (annotations._length()) {
         allowNoteOps();
      }

      //Restore the freshest Type and File.
      //Check to see if fType is still in annotationTypes:[], only sort the
      //most recently used types if fType is still available.
      if (annotationTypes._indexin(lowcase(fType))) {
         freshestType = fType;
         sortTypes();
      }

      freshestFile = fFile;
      if (freshestFile == '') {
         freshestFile = '(Personal Annotations)';
      }
      sortSCAFiles();

      //importAllAnnotations calls setupMarkers, so noteMarkerType should be
      //ready now.
      _MarkerTypeSetCallbackMouseEvent(noteMarkerType, LBUTTON_DOWN,
                                       mouseClickAnnotation);
   } else {
      insert_line("");
      int origLine1 = p_line;

      if (!freshestType._isempty()) {
         insert_line(freshestType);
      } else {
         insert_line('');
      }
      if (!freshestFile._isempty()) {
         insert_line(_encode_vslickconfig(freshestFile, true, false));
      } else {
         insert_line('');
      }

      SCAFileCount = 0;
      if ((!defFiles._isempty()) && (defFiles._length() > 0)) {
         for (i = 0; i < defFiles._length(); ++i) {
            if (SCAFiles._indexin(defFiles[i])) {
               ++SCAFileCount;
               file := defFiles[i];
               // use environment variables, in case we upgrade, we don't 
               // want to save the path to our old config
               insert_line(_encode_vslickconfig(file, true, false));
               insert_line(SCAFiles:[file]);
            }
         }
      }

      int origLine2 = p_line;
      p_line = origLine1;
      replace_line("ANNOTATIONS: "SCAFileCount*2+2);
      p_line = origLine2;
   }

   return(0);
}



/**
 * Disable 'New Annotation' button on Annotation Browser dialog
 * if there are no buffers open.
 */
void _cbquit_annotations (int buffid, _str name, _str docname= '', int flags = 0)
{
   name = maybe_quote_filename(name);
   if (sourceFiles._indexin(name)) {
      VSLINEMARKERINFO info;
      int noteCount = sourceFiles:[name]._length();
      int i;
      int j;
      boolean changedSCAFiles:[];

      //For each annotation in the file that is closing ...
      for (i = 0; i < noteCount; ++i) {
         j = sourceFiles:[name][i];
         if (annotations[j].marker.sourceFile == name) {
            //... that we can find the _LineMarker for, re-build the
            //annotation's marker.
            if (!_LineMarkerGet(annotations[j].lineMarker, info)) {
               p_RLine = info.LineNum;
               _BuildRelocatableMarker(annotations[j].marker,
                                       RELOC_MARKER_WINDOW_SIZE);
               changedSCAFiles:[annotations[j].noteFile] = true;
            }
         }
      }

      //Save every SCA file that has changed
      typeless k;
      for (k._makeempty(); ; ) {
         SCAFiles._nextel(k);
         if (k._isempty()) {
            break;
         }
         exportAnnotations(k);
      }
   }

   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.maybeDisableNewAnnotations();
   }
}



/**
 * Disable 'New Annotation' button on Annotation Browser dialog
 * if there are no buffers open.
 */
void _switchbuf_annotations (_str oldbuffname, _str flag)
{
   _str newbuffname = maybe_quote_filename(_mdi.p_child.p_buf_name);

   if (freshSourceFiles._indexin(newbuffname)) {
      relocateMarkers(_mdi.p_child.p_buf_id);
   }
   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.maybeDisableNewAnnotations();
   }
}

void _buffer_renamedAfter_annotations (int buf_id, _str old_bufname,
                                       _str new_bufname, int buf_flags)
{
   if (!sourceFiles._indexin(old_bufname)) {
      return;
   }

   //new_bufname now has new contents. If there were annotations in the file, it
   //was based on the old contents, so get rid of them.
   int noteCount = sourceFiles:[new_bufname]._length();
   for (; noteCount > 0; --noteCount) {
      annotations._deleteel(sourceFiles:[new_bufname][noteCount - 1]);
   }

   //We've potentially lost annotations, rehashNoteIDs here and
   //save and restore the filter settings.
   rehashNoteIDs();
   int _type_list = _find_object('_tbannotations_browser_form._type_list', 'n');
   int _filter = _find_object('_tbannotations_browser_form._filter', 'n');
   int _filter_key = _find_object('_tbannotations_browser_form._filter_key',
                                  'n');
   if (_filter && _filter_key) {
      _str filter = _filter.p_text;
      _str filterKey = _filter_key.p_text;

      _type_list.call_event(CHANGE_OTHER, _type_list, ON_CHANGE, 'w');

      //restore the filter settings.
      if (!_filter._lbfind_and_select_item(filter)) {
         _filter_key._lbfind_and_select_item(filterKey);
      }
   }


   int doCopy = 0;
   //Copy annotations to the renamed file?
   doCopy = _message_box("Copy annotations from "old_bufname" to ":+
                         new_bufname"?", '', MB_YESNO);

   int wid = window_match(new_bufname, 1, 'x');
   if (doCopy == IDYES) {
      //Yes: copy all the annotations in the old file to the new file.
      noteCount = sourceFiles:[old_bufname]._length();

      _str shortNoteFile;
      _str shortSourceFile;
      _str qNoteFile;
      _str qSourceFile;
      _str date;
      int i;
      int oldIdx;
      int newIdx;

      for (i = 0; i < noteCount; ++i) {
         //Copy annotation.
         oldIdx = sourceFiles:[old_bufname][i];
         newIdx = annotations._length();
         _LineMarkerRemove(annotations[oldIdx].lineMarker);
         annotations[oldIdx].lineMarker = -1;
         annotations[newIdx] = annotations[oldIdx];
         annotations[newIdx].marker.sourceFile = absolute(new_bufname);

         //Assign line markers.
         if (wid != 0) {
            int lmIndex;
            _str noteMessage = '';
            int typeLength = length(annotations[newIdx].type);
            strappend(noteMessage, '<code>':+
                      annotations[newIdx].type'</code><br>');
            strappend(noteMessage, center('', typeLength, '-')'<br>');
            strappend(noteMessage, annotations[newIdx].preview);
            lmIndex = _LineMarkerAdd(wid,
                                     annotations[newIdx].marker.origLineNumber,
                                     0, 0, annotationPic, noteMarkerType,
                                     noteMessage);
            annotations[newIdx].lineMarker = lmIndex;
            lineMarkers:[lmIndex] = newIdx;
         }

         if (annotations[newIdx].noteFile == workspaceSCA) {
            shortNoteFile = '(Workspace Annotations)';
         } else if (annotations[newIdx].noteFile == projectSCA) {
            shortNoteFile = '(Project Annotations)';
         } else if (annotations[newIdx].noteFile == personalSCA) {
            shortNoteFile = '(Personal Annotations)';
         } else {
            shortNoteFile = _strip_filename(annotations[newIdx].noteFile, "P");
         }

         shortNoteFile = maybe_quote_filename(shortNoteFile);
         shortSourceFile = maybe_quote_filename(_strip_filename(annotations[newIdx].marker.sourceFile, "P"));
         qNoteFile = maybe_quote_filename(annotations[newIdx].noteFile); 
         qSourceFile = maybe_quote_filename(new_bufname);
         parse annotations[newIdx].lastModDate with date " " . ;

         //Put the new annotation into the hashtables.
         allAnnotations[newIdx] = newIdx;
         activeAnnotations:[newIdx] = newIdx;
         authors:[annotations[newIdx].lastModUser][authors:[annotations[newIdx].lastModUser]._length()] = newIdx;
         dates:[date][dates:[date]._length()] = newIdx;
         noteFiles:[qNoteFile][noteFiles:[qNoteFile]._length()] = newIdx;
         sourceFiles:[qSourceFile][sourceFiles:[qSourceFile]._length()] = newIdx;
         shortNoteFiles:[shortNoteFile][shortNoteFiles:[shortNoteFile]._length()] = newIdx;
         shortSourceFiles:[shortSourceFile][shortSourceFiles:[shortSourceFile]._length()] = newIdx;
         types:[lowcase(annotations[newIdx].type)][types:[annotations[newIdx].type]._length()] = newIdx;
         versions:[annotations[newIdx].version][versions:[annotations[newIdx].version]._length()] = newIdx;
         annotationIndices:[maybe_quote_filename(_mdi.p_child.p_buf_name)][_mdi.p_child.p_RLine] = newIdx;

         updateAnnotationsBrowser(allAnnotations);
      }
   } else if (doCopy == IDNO) {
      int newWid = window_match(new_bufname, 1, 'x');
      _LineMarkerRemoveType(newWid, noteMarkerType);
   }
}



void _buffer_add_annotation_markers (int newBuffID, _str name, int flags = 0)
{
   if (freshSourceFiles._indexin(maybe_quote_filename(name))) {
      relocateMarkers(newBuffID, true);
   }
}


/**
 * Retrieves the current username for use with tracking
 * annotation changes.
 *
 * @return _str
 */
static _str annotation_username()
{
   _str userName = '';
   _userName(userName);

   return userName;
}

/**
 * Originally from HS2 in community forums.
 *
 * Modified for v17, when we began using a Qt tree, which allows
 * for better date handling.  We used to need this to allow for
 * date sorting in the tree, but that is no longer necessary.
 * 
 */
_str def_annotation_date_hook = '';

/**
 * Retrieves the current date and time for marking an
 * annotation.
 *
 * If you wish to modify the format of the annotation, you can
 * write a function to do so.  The function must take no
 * parameters (or have default arguments) and must return a
 * string to represent the current date and time.  Then set
 * def_annotation_date_hook to the name of the function.
 *
 * To just use the default functionality, set
 * def_annotation_date_hook to an empty string (use set_var
 * command or Macro > Set Macro Variable).
 *
 * @return _str
 */
static _str annotation_date ()
{
   if ( def_annotation_date_hook != '' ) {
      static int date_hook_index;
      if (date_hook_index == 0) {
         date_hook_index = find_index(def_annotation_date_hook, PROC_TYPE|COMMAND_TYPE);
      }
      if (date_hook_index)  return call_index(date_hook_index);
   }

   // no date hook set, just do this
   return _date()" "_time();
}

_str annotation_date_hook ()
{
   return getcdate( '/', true, true)" "substr ( _time( 'M'), 1, 5 );
}

static _str getcdate ( _str delim = '', boolean yyyy = false,
                       boolean lzero = true )
{
   _str month, day, year;
   parse _date() with month'/'day'/'year;
   if (lzero && length(month)<2) month='0'month;
   if (lzero && length(day)<2)   day='0'day;
   if (length(year)>2 && !yyyy)  year=substr(year,3);
   return( year delim month delim day );
}

static boolean annotation_date_parse(_str string, int &y, int &m, int &d, int &h, int &min)
{
   y = m = d = h = min = 0;

   if (def_annotation_date_hook != '' && def_annotation_date_hook != 'annotation_date_hook' ) return false;

   // first, split up date and time
   parse string with auto date auto time;

   // date breaks up into months, days, years
   typeless first, second, third;
   parse date with first '/' second '/' third;
   if (!isinteger(first) || !isinteger(second) || !isinteger(third)) return false;

   // this handles the case where it was y/m/d
   if (length(first) > 2) {
      y = (int) first;
      m = (int) second;
      d = (int) third;
   } else {
      m = (int) first;
      d = (int) second;
      y = (int) third;
   }

   // time into hrs, mins, am/pm
   parse time with auto hour ':' auto minute;

   // the 12s always do the opposite of the other numbers
   ampm := substr(minute, 3, 1);
   pm := false;
   if (ampm != '') {
      pm = strieq('p', ampm);
      if (hour == '12') pm = !pm;
   }

   minute = substr(minute, 1, 2);

   if (!isinteger(hour) || !isinteger(minute)) return false;

   h = (int) hour;
   if (pm) {
      // 24-hour clock
      h += 12;
      h = h % 24;
   }
   min = (int)minute;

   return true;
}

//Update the annotation browser with any possible new annotations, or
//changes to existing annotations.
static void updateAnnotationsBrowser (int (&noteIndices)[])
{
   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.setupTypeList();
      wid.setupFilters();
      wid.showFields(noteIndices);
   }
}



//Allow the annotation browser to copy, modify, and delete annotations.
static void allowNoteOps ()
{
   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.enableNoteOps();
   }
}



static void removeSCAFile (_str SCAFile)
{
   SCAFiles._deleteel(SCAFile);

   //Remove the annotations.
   int i;
   int k;
   int noteCount = noteFiles:[SCAFile]._length();
   for (i = (noteCount - 1); i >= 0; --i) {
      k = noteFiles:[SCAFile][i];
      if (annotations[k].lineMarker >= 0) {
         _LineMarkerRemove(annotations[k].lineMarker);
      }
      annotations._deleteel(k);
   }

   //Remove this SCA file from the annotation definitions' list of files.
   for (i = (annotationDefs._length() - 1); i >= 0; --i) {
      annotationDefs[i].noteFiles._deleteel(SCAFile);
   }

   rehashNoteIDs();
   cleanDefTypes();

   updateAnnotationsBrowser(allAnnotations);
}



static void cleanDefFiles ()
{
   //Remove the file from the defFiles array, used to keep track of the
   //most recently used SCA file.
   int i;
   for (i = 0; i < defFiles._length(); ) {
      if (!SCAFiles._indexin(defFiles[i])) {
         defFiles._deleteel(i);
      } else {
         ++i;
      }
   }
}


static void cleanDefTypes ()
{
   //Clean any dead annotation types out of defTypes.
   int i;
   for (i = 0; i < defTypes._length(); ) {
      if (!annotationTypes._indexin(lowcase(defTypes[i]))) {
         defTypes._deleteel(i);
      } else {
         ++i;
      }
   }
}



static void rebuildAnnotationTypes ()
{
   annotationTypes._makeempty();
   int i;
   for (i = 0; i < annotationDefs._length(); ++i) {
      annotationTypes:[lowcase(annotationDefs[i].name)] = i;
   }
}



static void maybeAddSCAFile (_str SCAFile)
{
   // do we already have this file?
   if (!SCAFiles._indexin(SCAFile)) {

      // nope!
      _str SCAName;

      // we need a nice display name for the file
      if (SCAFile == workspaceSCA) {
         SCAName = '(Workspace Annotations)';
      } else if (SCAFile == projectSCA) {
         SCAName = '(Project Annotations)';
      } else if (SCAFile == personalSCA) {
         SCAName = '(Personal Annotations)';
      } else {
         // just use the file name
         SCAName = SCAFile;
      }

      // save the name
      SCAFiles:[SCAFile] = SCAName;

      // if it is not already in our defFiles list, add it
      int i;
      for (i = 0; i < defFiles._length(); ++i) {
         if (defFiles[i] == SCAFile) {
            return;
         }
      }
      defFiles[defFiles._length()] = SCAFile;
   }
}

static void makeAnnotationCaption (Annotation& note)
{
   _str preview = '';// = '<code><'note.type'></code><br>';
   int i;
   int j;
   int k;
   int fIDX;
   int defIdx = annotationTypes:[lowcase(note.type)];
   nFields := annotationDefs[defIdx].fieldsUsed._length();
   for (i = 0; i < nFields; ++i) {
      fIDX = annotationDefs[defIdx].fieldsUsed[i];
      preview = preview:+'<code>'note.fields[fIDX].name':</code><br>';
      switch (note.fields[fIDX].fieldType) {
      case TEXT_CONTROL_TYPE:
         if (!note.fields[fIDX].text._isempty()) {
            preview = preview:+note.fields[fIDX].text'<br>';
         }
         break;
      case DATE_CONTROL_TYPE:
         if (!note.fields[fIDX].defaultDate._isempty()) {
            preview = preview:+note.fields[fIDX].defaultDate'<br>';
         }
         break;
      case MULTILINE_TEXT_CONTROL_TYPE:
         for (j = 0; j < note.fields[fIDX].editor._length(); ++j) {
            preview = preview:+note.fields[fIDX].editor[j]'<br>';
         }
         break;
      case DROPDOWN_CONTROL_TYPE:
         if (!note.fields[fIDX].dropdown._isempty() &&
             !note.fields[fIDX].defaultIndices._isempty() &&
             (note.fields[fIDX].defaultIndices[0] > -1)) {
            preview = preview:+
                      note.fields[fIDX].dropdown[note.fields[fIDX].defaultIndices[0]]'<br>';
         } else if (!note.fields[fIDX].dropdown._isempty()) {
            preview = preview:+note.fields[fIDX].dropdown[0]'<br>';
         }
         break;
      case LIST_CONTROL_TYPE:
         if (!note.fields[fIDX].list._isempty() &&
             !note.fields[fIDX].defaultIndices._isempty() &&
             (note.fields[fIDX].defaultIndices[0] > -1)) {
            for (j = 0;
                j < note.fields[fIDX].defaultIndices._length();
                ++j) {
               k = note.fields[fIDX].defaultIndices[j];
               if (k < note.fields[fIDX].list._length()) {
                  preview = preview:+note.fields[fIDX].list[k]'<br>';
               }
            }
         }
         break;
      case CHECKBOX_CONTROL_TYPE:
         preview = preview:+note.fields[fIDX].checkbox'<br>';
         break;
      default:
         break;
      }
      preview = preview:+'<br>';
   }
   note.preview = substr(preview, 1, (length(preview)-8));
   //note.preview = preview;
}



static void prepFieldInfo (AnnotationFieldInfo& field1)
{
   field1.name._makeempty();
   field1.fieldType._makeempty();
   field1.text._makeempty();
   field1.editor._makeempty();
   field1.list._makeempty();
   field1.dropdown._makeempty();
   field1.checkbox._makeempty();
   field1.defaultDate._makeempty();
   field1.defaultIndices._makeempty();
   field1.dateOffset = 0;
   field1.dateRadioSelection = 0;
}



static void prepTypeInfo (AnnotationTypeInfo& type1)
{
   type1.fields._makeempty();
   type1.fieldsUsed._makeempty();
   type1.id._makeempty();
   type1.author._makeempty();
   type1.creationDate._makeempty();
   type1.lastModifiedDate._makeempty();
   type1.lastModifiedUser._makeempty();
   type1.name._makeempty();
   type1.noteFiles._makeempty();
   type1.version._makeempty();
}



/** 
 * compareTypes assumes it is called because an existing type 
 * and a new type share the same name, so it doesn't compare 
 * names. 
 *  
 * Only compare the fields and fieldsUsed, other changes don't make a difference 
 * in how an annotation acts. 
 *  
 * @param type1
 * @param type2
 * 
 * @return boolean
 */
static boolean compareTypes (AnnotationTypeInfo& type1, AnnotationTypeInfo& type2)
{
   //If the types have a different number of fields, the types don't match.
   if (type1.fieldsUsed != type2.fieldsUsed) {
      return false;
   }

   int type1Fields:[];
   int type2Fields:[];
   int i;
   int j;
   for (i = 0; i < type1.fieldsUsed._length(); ++i) {
      j = type1.fieldsUsed[i];
      type1Fields:[type1.fields[j].name] = j;
      type2Fields:[type2.fields[j].name] = j;
   }

   //Check that the same fields (by name) are in both types.
   typeless iter;
   for (iter._makeempty(); ; ) {
      type1Fields._nextel(iter);
      if (iter._isempty()) {
         break;
      }
      if (!type2Fields._indexin(iter)) {
         return false;
      }
   }
   for (iter._makeempty(); ; ) {
      type2Fields._nextel(iter);
      if (iter._isempty()) {
         break;
      }
      if (!type1Fields._indexin(iter)) {
         return false;
      }
   }

   //Check that all the fields that are named the same are actually the same.
   int type1IDX;
   int type2IDX;
   for (iter._makeempty(); ; ) {
      type1Fields._nextel(iter);
      if (iter._isempty()) {
         break;
      }
      type1IDX = type1Fields:[iter];
      type2IDX = type2Fields:[iter];
      if (type1.fields[type1IDX] != type2.fields[type2IDX]) {
         return false;
      }
   }

   return true;
}



static void importAllAnnotations ()
{
   // start with the personal annotation file
   _str personalfn = _ConfigPath():+'personal.sca';
   personalfn = maybe_quote_filename(personalfn);

   // if we haven't added this file, add it now
   if (!SCAFiles._indexin(personalfn)) {
      personalSCA = personalfn;
      maybeAddSCAFile(personalfn);
   }

   if (file_match('-P +HRS 'personalfn, 1) == '') {
      copy_file(maybe_quote_filename(get_env('VSROOT')'sysconfig'FILESEP'personal.sca'),
                personalfn);
   }

   if (_workspace_filename != '') {
      _str wfn = _strip_filename(_workspace_filename, 'E')'_workspace.sca';
      wfn = maybe_quote_filename(wfn);
      workspaceSCA = wfn;
      maybeAddSCAFile(wfn);
   } else {
      workspaceSCA = '';
   }

   if (_project_name != '') {
      _str pfn = _strip_filename(_project_name, 'E')'_project.sca';
      pfn = maybe_quote_filename(pfn);
      projectSCA = pfn;
      maybeAddSCAFile(pfn);
   } else {
      projectSCA = '';
   }

   //Load all the .sca files.
   _str tempSCAFiles:[];
   tempSCAFiles = SCAFiles;
   typeless i;
   for (i._makeempty(); ; ) {
      tempSCAFiles._nextel(i);
      if (i._isempty()) {
         break;
      }
      i = maybe_quote_filename(i);
      importAnnotations(i);
   }

   setupMarkers();
}

static void exportAllAnnotations ()
{
   typeless i;
   for (i._makeempty(); ; ) {
      SCAFiles._nextel(i);
      if (i._isempty()) {
         break;
      }
      exportAnnotations(i);
   }
}



static _str getFileName(_str caption='Open')
{
   _str fileName = '';
   _str initDir = get_env("HOME");
   _str format_list = 'Code Annotation Files (*.sca),All Files ('ALLFILES_RE')';
   int unixflags = 0;
#if __UNIX__
   _str attrs = file_list_field(fileName, DIR_ATTR_COL, DIR_ATTR_WIDTH);
   _str w = pos('w', attrs, '', 'i');
   if (!w && (attrs != '')) {
      unixflags = OFN_READONLY;
   }
#endif
   _str outFileName = _OpenDialog('-modal',
                                  caption,
                                  "*.sca",
                                  format_list,
                                  unixflags,
                                  'sca',//def_ext,      // Default extensions
                                  '', // Initial filename
                                  initDir,      // Initial directory
                                  '',      // Reserved
                                  "Open dialog box"
                                 );
   return outFileName;
}



static void reset_annotations ()
{
   personalSCA = '';
   workspaceSCA = '';
   projectSCA = '';
   annotationDefs._makeempty();
   annotationTypes._makeempty();
   annotations._makeempty();
   defC = 0;
   allAnnotations._makeempty();
   lastAnnotations._makeempty();
   activeAnnotations._makeempty();
   authors._makeempty();
   dates._makeempty();
   noteFiles._makeempty();
   sourceFiles._makeempty();
   types._makeempty();
   versions._makeempty();
   activeType._makeempty();
   dynControls._makeempty();
   currentNote = -1;
   if (noteMarkerType) {
      _LineMarkerRemoveAllType(noteMarkerType);
   }
   noteMarkerType = 0;
   if (orphanedNoteMarkerType) {
      _LineMarkerRemoveAllType(orphanedNoteMarkerType);
   }
   orphanedNoteMarkerType = 0;
   freshSourceFiles._makeempty();
   SCAFiles._makeempty();
   defFiles._makeempty();
}



_command int new_annotation (_str fileName='') name_info(',')
{
   _macro_delete_line();
   if (_no_child_windows()) {
      return 0;
   }

   //Don't allow users to annotate unsaved files, it just causes problems later.
   if (_mdi.p_child.p_buf_name == '') {
      _message_box('Please save the buffer before adding annotations', 'Warning');
      return COMMAND_CANCELLED_RC;
   }

   typeless result = _mdi.show('-xy -modal _new_annotation_form');
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }

   allowNoteOps();
   return(0);
}
_command void copy_annotation () name_info(',')
{
   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.copyAnnotation();
   }
}
_command void delete_annotation () name_info(',')
{
   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.deleteAnnotation();
   }
}
_command void edit_annotation () name_info(',')
{
   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.editAnnotation();
   }
}
_command void show_annotation_source () name_info(',')
{
   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.goToAnnotation();
   }
}
_command int annotation_files () name_info(',')
{
   _macro_delete_line();

   typeless result = _mdi.show('-xy -modal _annotation_files_form');
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }

   return(0);
}
_command int annotations_definitions () name_info(',')
{
   _macro_delete_line();

   typeless result = _mdi.show('-xy -modal _annotations_definitions_form');
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }

   return(0);
}
_command int annotations_browser () name_info(COMMAND_ARG',')
{
   _macro_delete_line();

   return activate_toolbar('_tbannotations_browser_form', '_annotation_tree');
}



static void setupMarkers ()
{
   annotationPic = find_index('_edannotation.ico', PICTURE_TYPE);
   if (noteMarkerType < 0) {
      noteMarkerType = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(noteMarkerType, 0);
   } else {
      _PicSetOrder(orphanedAnnotationPic, VSPIC_ORDER_ANNOTATION, 0);
   }

   orphanedAnnotationPic = find_index('_edannotationgray.ico', PICTURE_TYPE);
   if (orphanedNoteMarkerType < 0) {
      orphanedNoteMarkerType = _MarkerTypeAlloc();
      _MarkerTypeSetFlags(orphanedNoteMarkerType, 0);
   } else {
      _PicSetOrder(orphanedAnnotationPic, VSPIC_ORDER_ANNOTATION_GRAY, 0);
   }
}



static void rehashNoteIDs ()
{
   allAnnotations._makeempty();
   lastAnnotations._makeempty();
   activeAnnotations._makeempty();
   authors._makeempty();
   dates._makeempty();
   noteFiles._makeempty();
   shortNoteFiles._makeempty();
   sourceFiles._makeempty();
   shortSourceFiles._makeempty();
   types._makeempty();
   versions._makeempty();
   activeType = null;

   _str shortNoteFile;
   _str shortSourceFile;
   _str date;
   int i;
   int noteCount = annotations._length();
   for (i = 0; i < noteCount; ++i) {
      allAnnotations[i] = i;
      activeAnnotations:[i] = i;
      authors:[annotations[i].lastModUser][authors:[annotations[i].lastModUser]._length()] = i;
      parse annotations[i].lastModDate with date " " . ;
      dates:[date][dates:[date]._length()] = i;
      noteFiles:[maybe_quote_filename(annotations[i].noteFile)][noteFiles:[maybe_quote_filename(annotations[i].noteFile)]._length()] = i;
      sourceFiles:[maybe_quote_filename(annotations[i].marker.sourceFile)][sourceFiles:[maybe_quote_filename(annotations[i].marker.sourceFile)]._length()] = i;

      if (annotations[i].noteFile == workspaceSCA) {
         shortNoteFile = '(Workspace Annotations)';
      } else if (annotations[i].noteFile == projectSCA) {
         shortNoteFile = '(Project Annotations)';
      } else if (annotations[i].noteFile == personalSCA) {
         shortNoteFile = '(Personal Annotations)';
      } else {
         shortNoteFile = _strip_filename(annotations[i].noteFile, "P");
      }
      shortNoteFile = maybe_quote_filename(shortNoteFile);
      shortNoteFiles:[shortNoteFile][shortNoteFiles:[shortNoteFile]._length()] = i;

      shortSourceFile = maybe_quote_filename(stranslate(_strip_filename(annotations[i].marker.sourceFile, "P"), '', '"'));
      shortSourceFiles:[shortSourceFile][shortSourceFiles:[shortSourceFile]._length()] = i;

      types:[lowcase(annotations[i].type)][types:[lowcase(annotations[i].type)]._length()] = i;
      versions:[annotations[i].version][versions:[annotations[i].version]._length()] = i;
   }
}



static void importAnnotations (_str fileName='')
{
   fileName = maybe_quote_filename(fileName);
   if ((fileName != null) && (SCAFiles._indexin(fileName))) {
      removeSCAFile(fileName);
   }

   if (fileName == '') {
      fileName = personalSCA;
      if (file_match('-P +HRS 'fileName, 1) == '') {
         copy_file(get_env('VSROOT')'sysconfig'FILESEP'personal.sca',
                   fileName);
      }
   }

   int treeHandle = -1;
   int status = 0;
   treeHandle = _xmlcfg_open(fileName, status, 0, VSENCODING_UTF8);
   if (treeHandle < 0) { //It's a bad XML file ...
      if (file_match('-P +HRS 'fileName, 1) == '') {
         // ... because it doesn't exist, so make a new SCA file.
         maybeAddSCAFile(fileName);
         cleanDefFiles();
         updateAnnotationsBrowser(allAnnotations);
      }
      return;
   }

   int cadNode = 0;
   cadNode = _xmlcfg_find_child_with_name(treeHandle, TREE_ROOT_INDEX,
                                          'CodeAnnotationData',
                                          VSXMLCFG_NODE_ELEMENT_START);
   if (cadNode < 0) {
      cleanDefFiles();
      _message_box(get_message(cadNode));
      updateAnnotationsBrowser(allAnnotations);
      return;
   }

   _str inFieldTypes:[];
   _str dateInfo = '';
   _str defaultDate = '';
   _str dateFields = '';
   _str dateOffset = '';
   _str dateRadioSelection = '';
   _str name = '';
   _str line = '';
   _str editor = '';
   _str nodeName = '';
   _str conflictNames:[];
   int cDataIdx;
   int selIndex;
   int i;
   int j;
   int k;
   int adNode = 0;
   int fNode = 0;
   int vNode = 0;
   boolean collision = false;

   /*
   Import definitions.
   */
   adNode = _xmlcfg_find_child_with_name(treeHandle, cadNode,
                                         'AnnotationDef',
                                         VSXMLCFG_NODE_ELEMENT_START);
   while (adNode > 0) {
      nodeName = _xmlcfg_get_name(treeHandle, adNode);
      if (nodeName != 'AnnotationDef') {
         adNode = _xmlcfg_get_next_sibling(treeHandle, adNode,
                                           VSXMLCFG_NODE_ELEMENT_START);
         continue;
      }
      defC = annotationDefs._length();
      prepTypeInfo(annotationDefs[defC]);//'initialize' the type's struct.

      name = _xmlcfg_get_attribute(treeHandle, adNode,
                                   'name', '');
      annotationDefs[defC].name = name;
      annotationDefs[defC].id = _xmlcfg_get_attribute(treeHandle, adNode, 'id', '');
      if (annotationDefs[defC].id == '') {
         annotationDefs[defC].id = guid_create_string('G');
      }
      annotationDefs[defC].author = _xmlcfg_get_attribute(treeHandle, adNode,
                                                          'author', '');
      annotationDefs[defC].creationDate = _xmlcfg_get_attribute(treeHandle,
                                                                adNode,
                                                                'creationDate',
                                                                '');
      annotationDefs[defC].lastModifiedDate = _xmlcfg_get_attribute(treeHandle,
                                                                    adNode,
                                                                    'lastModifiedDate',
                                                                    '');
      annotationDefs[defC].lastModifiedUser = _xmlcfg_get_attribute(treeHandle,
                                                                    adNode,
                                                                    'lastModifiedUser',
                                                                    '');
      annotationDefs[defC].version = _xmlcfg_get_attribute(treeHandle, adNode,
                                                           'version', '');

      fNode = _xmlcfg_find_child_with_name(treeHandle, adNode, 'FieldDef',
                                           VSXMLCFG_NODE_ELEMENT_START);
      int l = 0;
      while (fNode > 0) {
         j = (int)_xmlcfg_get_attribute(treeHandle, fNode, 'index', '');
         annotationDefs[defC].fieldsUsed[l++] = j;

         prepFieldInfo(annotationDefs[defC].fields[j]);//'initialize' each field's struct.

         annotationDefs[defC].fields[j].name =
         _xmlcfg_get_attribute(treeHandle, fNode, 'name', '');
         annotationDefs[defC].fields[j].fieldType =
         _xmlcfg_get_attribute(treeHandle, fNode, 'type', '');

         inFieldTypes:[annotationDefs[defC].fields[j].name] =
         annotationDefs[defC].fields[j].fieldType;

         switch (annotationDefs[defC].fields[j].fieldType) {
         case TEXT_CONTROL_TYPE:
            vNode = _xmlcfg_find_child_with_name(treeHandle, fNode,
                                                 'DefaultValue',
                                                 VSXMLCFG_NODE_ELEMENT_START);
            if (vNode > -1) {
               cDataIdx = _xmlcfg_get_first_child(treeHandle, vNode,
                                                  VSXMLCFG_NODE_CDATA|
                                                  VSXMLCFG_NODE_PCDATA);
               if (cDataIdx > -1) {
                  annotationDefs[defC].fields[j].text =
                  _xmlcfg_get_value(treeHandle, cDataIdx);
               }
            }
            break;
         case DATE_CONTROL_TYPE:
            vNode = _xmlcfg_find_child_with_name(treeHandle, fNode,
                                                 'DefaultValue',
                                                 VSXMLCFG_NODE_ELEMENT_START);
            if (vNode > -1) {
               cDataIdx = _xmlcfg_get_first_child(treeHandle, vNode,
                                                  VSXMLCFG_NODE_CDATA|
                                                  VSXMLCFG_NODE_PCDATA);
               if (cDataIdx > -1) {
                  dateInfo = _xmlcfg_get_value(treeHandle, cDataIdx);
                  annotationDefs[defC].fields[j].defaultDate = dateInfo;
               }
            }
            break;
         case MULTILINE_TEXT_CONTROL_TYPE:
            vNode = _xmlcfg_find_child_with_name(treeHandle, fNode,
                                                 'DefaultValue',
                                                 VSXMLCFG_NODE_ELEMENT_START);
            if (vNode > -1) {
               cDataIdx = _xmlcfg_get_first_child(treeHandle, vNode,
                                                  VSXMLCFG_NODE_CDATA|
                                                  VSXMLCFG_NODE_PCDATA);
               if (cDataIdx > -1) {
                  line = '';
                  editor = _xmlcfg_get_value(treeHandle, cDataIdx);
                  k = 0;
                  annotationDefs[defC].fields[j].editor[k] = '';
                  while (editor != '') {
                     parse editor with line "\n" editor;
                     annotationDefs[defC].fields[j].editor[k++] = line;
                  }
               }
            }
            break;
         case DROPDOWN_CONTROL_TYPE:
            vNode = _xmlcfg_find_child_with_name(treeHandle, fNode,
                                                 'PredefinedValue',
                                                 VSXMLCFG_NODE_ELEMENT_START_END);
            k = 0;
            while (vNode > 0) {
               k = _xmlcfg_get_attribute(treeHandle, vNode, 'index', '');
               annotationDefs[defC].fields[j].dropdown[k] =
               _xmlcfg_get_attribute(treeHandle, vNode, 'name', '');
               vNode = _xmlcfg_get_next_sibling(treeHandle, vNode,
                                                VSXMLCFG_NODE_ELEMENT_START_END);
            }

            annotationDefs[defC].fields[j].defaultIndices._makeempty();
            vNode = _xmlcfg_find_child_with_name(treeHandle, fNode,
                                                 'DefaultValue',
                                                 VSXMLCFG_NODE_ELEMENT_START);
            if (vNode > -1) {
               cDataIdx = _xmlcfg_get_first_child(treeHandle, vNode,
                                                  VSXMLCFG_NODE_CDATA|
                                                  VSXMLCFG_NODE_PCDATA);
               if (cDataIdx > -1) {
                  annotationDefs[defC].fields[j].defaultIndices[0] =
                  _xmlcfg_get_value(treeHandle, cDataIdx);
               }
            }
            break;
         case LIST_CONTROL_TYPE:
            vNode = _xmlcfg_find_child_with_name(treeHandle, fNode,
                                                 'PredefinedValue',
                                                 VSXMLCFG_NODE_ELEMENT_START_END);
            k = 0;
            while (vNode > 0) {
               k = _xmlcfg_get_attribute(treeHandle, vNode, 'index');
               annotationDefs[defC].fields[j].list[k] =
               _xmlcfg_get_attribute(treeHandle, vNode, 'name', '');
               vNode = _xmlcfg_get_next_sibling(treeHandle, vNode,
                                                VSXMLCFG_NODE_ELEMENT_START_END);
            }

            annotationDefs[defC].fields[j].defaultIndices._makeempty();
            vNode = _xmlcfg_find_child_with_name(treeHandle, fNode,
                                                 'DefaultValue',
                                                 VSXMLCFG_NODE_ELEMENT_START);
            while (vNode > 0) {
               cDataIdx = _xmlcfg_get_first_child(treeHandle, vNode,
                                                  VSXMLCFG_NODE_CDATA|
                                                  VSXMLCFG_NODE_PCDATA);
               if (cDataIdx > -1) {
                  selIndex = annotationDefs[defC].fields[j].defaultIndices._length();
                  annotationDefs[defC].fields[j].defaultIndices[selIndex] =
                  _xmlcfg_get_value(treeHandle, cDataIdx);
               }
               vNode = _xmlcfg_get_next_sibling(treeHandle, vNode,
                                                VSXMLCFG_NODE_ELEMENT_START);
            }
            break;
         case CHECKBOX_CONTROL_TYPE:
            vNode = _xmlcfg_find_child_with_name(treeHandle, fNode,
                                                 'DefaultValue',
                                                 VSXMLCFG_NODE_ELEMENT_START);
            if (vNode > -1) {
               cDataIdx = _xmlcfg_get_first_child(treeHandle, vNode,
                                                  VSXMLCFG_NODE_CDATA|
                                                  VSXMLCFG_NODE_PCDATA);
               if (cDataIdx > -1) {
                  annotationDefs[defC].fields[j].checkbox =
                  _xmlcfg_get_value(treeHandle, cDataIdx);
               } else {
                  annotationDefs[defC].fields[j].checkbox = 'false';
               }
            }
            break;
         }
         fNode = _xmlcfg_get_next_sibling(treeHandle, fNode,
                                          VSXMLCFG_NODE_ELEMENT_START);
      }

      //Now that we have the name and all the field info, check for a type
      //collision:
      if (annotationTypes._indexin(lowcase(name))) {
         int oldDefC = annotationTypes:[lowcase(name)];
         if (!compareTypes(annotationDefs[defC], annotationDefs[oldDefC])) {
            //There is a type collision, allow the user to choose the one they
            //want to use.
            _str newName = show('-modal _annotation_rename_type_form',
                                name, fileName);
            //Keep track of the relationship between the old name and the new
            //name so the incoming annotations can change to the new type.
            conflictNames:[name] = newName;

            annotationDefs[defC].noteFiles:[fileName] = fileName;
            annotationDefs[oldDefC].noteFiles._deleteel(fileName);
            annotationDefs[defC].name = newName;
            annotationTypes:[lowcase(newName)] = defC;
            collision = true;
         } else {
            //A type of this name has already been loaded and they are the same.
            //Add the current filename to the list and delete the new
            //annotationDef that we had been filling out:
            annotationDefs[oldDefC].noteFiles:[fileName] = fileName;
            annotationDefs._deleteel(defC);
            defC = oldDefC;
            //(There should be no need to call rebuildAnnotationTypes()
            //because defC == annotationDefs._length())
         }
      } else {
         //No collision.
         //Note that this new type is in the 'filename' SCA file:
         annotationDefs[defC].noteFiles:[fileName] = fileName;
         //Make an entry for the index:
         annotationTypes:[lowcase(annotationDefs[defC].name)] = defC;
         //Make an entry for the name:
         int temp = defTypes._length();
         defTypes[defTypes._length()] = annotationDefs[defC].name;
         if (freshestType == '') {
            freshestType = annotationDefs[defC].name;
         }
         if (freshestFile == '') {
            freshestFile = defFiles[0];
         }
      }

      //We didn't know if we'd have to rename the type in case of a type
      //conflict when reading in the fields. Now we know the right name, so
      //populate fieldTypes:[]:[]
      typeless fieldType;
      for (fieldType._makeempty(); ; ) {
         inFieldTypes._nextel(fieldType);
         if (fieldType._isempty()) {
            break;
         }

         fieldTypes:[lowcase(annotationDefs[defC].name)]:[fieldType] =
         inFieldTypes:[fieldType];
      }

      adNode = _xmlcfg_get_next_sibling(treeHandle, adNode,
                                        VSXMLCFG_NODE_ELEMENT_START);
   }

   /*
   Import annotations.
   */
   _str basePath = '';
   int caNode = 0;
   caNode = _xmlcfg_find_child_with_name(treeHandle, cadNode,
                                         'CodeAnnotation',
                                         VSXMLCFG_NODE_ELEMENT_START);
   fNode = 0;
   _str type = '';
   int typeIndex = 0;
   int wid;
   int miNode = 0;
   int lineNode = 0;
   int cDataNode = 0;
   int noteC = 0;
   while (caNode > 0) {
      nodeName = _xmlcfg_get_name(treeHandle, caNode);
      if (nodeName != 'CodeAnnotation') {
         caNode = _xmlcfg_get_next_sibling(treeHandle, caNode,
                                           VSXMLCFG_NODE_ELEMENT_START);
         continue;
      }
      //Get header information.
      noteC = annotations._length();
      type = _xmlcfg_get_attribute(treeHandle, caNode, 'annotationDefId', '');
      if (conflictNames._indexin(type)) {
         annotations[noteC].type = lowcase(conflictNames:[type]);
      } else {
         annotations[noteC].type = lowcase(type);
      }
      annotations[noteC].author = _xmlcfg_get_attribute(treeHandle, caNode,
                                                        'author', '');
      annotations[noteC].creationDate = _xmlcfg_get_attribute(treeHandle,
                                                              caNode,
                                                              'creationDate',
                                                              '');
      annotations[noteC].lastModUser = _xmlcfg_get_attribute(treeHandle, caNode,
                                                             'lastModifiedUser',
                                                             '');
      annotations[noteC].lastModDate = _xmlcfg_get_attribute(treeHandle, caNode,
                                                             'lastModifiedDate',
                                                             '');
      annotations[noteC].noteDefVersion = _xmlcfg_get_attribute(treeHandle,
                                                                caNode,
                                                                'annotationDefVersion',
                                                                '');
      annotations[noteC].version = _xmlcfg_get_attribute(treeHandle, caNode,
                                                         'version', '');
      //Start off every note with the defaults for the type. Overwrite the
      //fields if they've been filled out.
      type = lowcase(annotations[noteC].type);
      if (annotationTypes._indexin(type)) {
         typeIndex = annotationTypes:[type];
         annotations[noteC].fields = annotationDefs[typeIndex].fields;
      } else {
         annotations._deleteel(noteC);
         caNode = _xmlcfg_get_next_sibling(treeHandle, caNode,
                                           VSXMLCFG_NODE_ELEMENT_START);
         continue;
      }

      //Get marker info.
      miNode = _xmlcfg_find_child_with_name(treeHandle, caNode, 'MarkerInfo',
                                            VSXMLCFG_NODE_ELEMENT_START);
      if (miNode > 0) {
         annotations[noteC].marker.origLineNumber = _xmlcfg_get_attribute(treeHandle,
                                                                          miNode,
                                                                          'lineNumber',
                                                                          '');
         annotations[noteC].marker.totalCount = _xmlcfg_get_attribute(treeHandle,
                                                                      miNode,
                                                                      'lineCount',
                                                                      '');
         annotations[noteC].marker.n = annotations[noteC].marker.totalCount/2;
         annotations[noteC].marker.aboveCount = annotations[noteC].marker.n;
         annotations[noteC].marker.belowCount = annotations[noteC].marker.n;

         basePath = _xmlcfg_get_attribute(treeHandle, miNode,
                                          'fileName', '');
         if (fileName == workspaceSCA) {
            _str workspaceRootFolder = _GetWorkspaceDir();
            basePath = absolute(basePath, workspaceRootFolder);
         } else if (fileName == projectSCA) {
            _str projectRootFolder = _strip_filename(_project_name,'N');
            basePath = absolute(basePath, projectRootFolder);
         }

         annotations[noteC].marker.sourceFile =
         maybe_quote_filename(absolute(stranslate(basePath, FILESEP, FILESEP2)));

         cDataNode = _xmlcfg_find_child_with_name(treeHandle, miNode, 'LineText',
                                                  VSXMLCFG_NODE_ELEMENT_START);
         if (cDataNode > 0) {
            cDataIdx = _xmlcfg_get_first_child(treeHandle, cDataNode,
                                               VSXMLCFG_NODE_CDATA|
                                               VSXMLCFG_NODE_PCDATA);
            line = _xmlcfg_get_value(treeHandle, cDataIdx);
            annotations[noteC].marker.origText._makeempty();
            tokenizeLine(line, annotations[noteC].marker.origText);
         }

         lineNode = _xmlcfg_find_child_with_name(treeHandle, miNode,
                                                 'LinesBefore',
                                                 VSXMLCFG_NODE_ELEMENT_START);
         cDataNode = _xmlcfg_find_child_with_name(treeHandle, lineNode,
                                                  'LineText',
                                                  VSXMLCFG_NODE_ELEMENT_START);
         while (cDataNode > 0) {
            cDataIdx = _xmlcfg_get_first_child(treeHandle, cDataNode,
                                               VSXMLCFG_NODE_CDATA|
                                               VSXMLCFG_NODE_PCDATA);
            line = '';
            k = 0;
            annotations[noteC].marker.textAbove._makeempty();
            while (cDataIdx > -1) {
               editor = _xmlcfg_get_value(treeHandle, cDataIdx);
               while (editor != '') {
                  parse editor with line "\n" editor;
                  tokenizeLine(line, annotations[noteC].marker.textAbove[k]);
                  ++k;
               }
               cDataIdx = _xmlcfg_get_next_sibling(treeHandle, cDataIdx,
                                                   VSXMLCFG_NODE_CDATA|
                                                   VSXMLCFG_NODE_PCDATA);
            }
            cDataNode = _xmlcfg_get_next_sibling(treeHandle, cDataNode,
                                                 VSXMLCFG_NODE_ELEMENT_START);
         }

         lineNode = _xmlcfg_find_child_with_name(treeHandle, miNode,
                                                 'LinesAfter',
                                                 VSXMLCFG_NODE_ELEMENT_START);
         cDataNode = _xmlcfg_find_child_with_name(treeHandle, lineNode,
                                                  'LineText',
                                                  VSXMLCFG_NODE_ELEMENT_START);
         while (cDataNode > 0) {
            cDataIdx = _xmlcfg_get_first_child(treeHandle, cDataNode,
                                               VSXMLCFG_NODE_CDATA|
                                               VSXMLCFG_NODE_PCDATA);
            line = '';
            k = 0;
            annotations[noteC].marker.textBelow._makeempty();
            while (cDataIdx > -1) {
               editor = _xmlcfg_get_value(treeHandle, cDataIdx);
               while (editor != '') {
                  parse editor with line "\n" editor;
                  tokenizeLine(line, annotations[noteC].marker.textBelow[k]);
                  ++k;
               }
               cDataIdx = _xmlcfg_get_next_sibling(treeHandle, cDataIdx,
                                                   VSXMLCFG_NODE_CDATA|
                                                   VSXMLCFG_NODE_PCDATA);
            }
            cDataNode = _xmlcfg_get_next_sibling(treeHandle, cDataNode,
                                                 VSXMLCFG_NODE_ELEMENT_START);
         }
      } else {
         annotations[noteC].marker.origLineNumber = 0;
         annotations[noteC].marker.n = 0;
         annotations[noteC].marker.aboveCount = 0;
         annotations[noteC].marker.belowCount = 0;
         annotations[noteC].marker.totalCount = 0;
         annotations[noteC].marker.sourceFile = "";
         //annotations[noteC].marker.origText[];
         //annotations[noteC].marker.textAbove[][];
         //annotations[noteC].marker.textBelow[][];
      }
      freshSourceFiles:[maybe_quote_filename(annotations[noteC].marker.sourceFile)] =
      false;
      annotations[noteC].noteFile = maybe_quote_filename(fileName);

      //Get field information.
      fNode = _xmlcfg_find_child_with_name(treeHandle, caNode, 'Field',
                                           VSXMLCFG_NODE_ELEMENT_START);
      _str fName = '';
      _str fType = '';
      int fIdx = 0;
      while (fNode > 0) {
         fName = _xmlcfg_get_attribute(treeHandle, fNode, 'name', '');
         annotations[noteC].fields[fIdx].name = fName;

         fType = fieldTypes:[lowcase(annotations[noteC].type)]:[fName];
         annotations[noteC].fields[fIdx].fieldType = fType;

         vNode = _xmlcfg_find_child_with_name(treeHandle, fNode, 'Value',
                                              VSXMLCFG_NODE_ELEMENT_START);
         cDataIdx = _xmlcfg_get_first_child(treeHandle, vNode,
                                            VSXMLCFG_NODE_CDATA|
                                            VSXMLCFG_NODE_PCDATA);
         if (cDataIdx > -1) {
            switch (fType) {
            case TEXT_CONTROL_TYPE:
               annotations[noteC].fields[fIdx].text = '';
               annotations[noteC].fields[fIdx].text =
               _xmlcfg_get_value(treeHandle, cDataIdx);
               break;
            case MULTILINE_TEXT_CONTROL_TYPE:
               annotations[noteC].fields[fIdx].editor._makeempty();
               line = '';
               editor = _xmlcfg_get_value(treeHandle, cDataIdx);
               k = 0;
               while (editor != '') {
                  parse editor with line "\n" editor;
                  annotations[noteC].fields[fIdx].editor[k++] = line;
               }
               break;
            case DROPDOWN_CONTROL_TYPE:
               annotations[noteC].fields[fIdx].defaultIndices._makeempty();
               k = 0;
               while (vNode > 0) {
                  cDataIdx = _xmlcfg_get_first_child(treeHandle, vNode,
                                                     VSXMLCFG_NODE_CDATA|
                                                     VSXMLCFG_NODE_PCDATA);
                  if (cDataIdx > -1) {
                     annotations[noteC].fields[fIdx].defaultIndices[k++] =
                     _xmlcfg_get_value(treeHandle, cDataIdx);
                  }
                  vNode = _xmlcfg_get_next_sibling(treeHandle, vNode,
                                                   VSXMLCFG_NODE_ELEMENT_START);
               }
               break;
            case LIST_CONTROL_TYPE:
               annotations[noteC].fields[fIdx].defaultIndices._makeempty();
               k = 0;
               while (vNode > 0) {
                  cDataIdx = _xmlcfg_get_first_child(treeHandle, vNode,
                                                     VSXMLCFG_NODE_CDATA|
                                                     VSXMLCFG_NODE_PCDATA);
                  if (cDataIdx > -1) {
                     annotations[noteC].fields[fIdx].defaultIndices[k++] =
                     _xmlcfg_get_value(treeHandle, cDataIdx);
                  }
                  vNode = _xmlcfg_get_next_sibling(treeHandle, vNode,
                                                   VSXMLCFG_NODE_ELEMENT_START);
               }
               break;
            case CHECKBOX_CONTROL_TYPE:
               annotations[noteC].fields[fIdx].checkbox =
               _xmlcfg_get_value(treeHandle, cDataIdx);
               break;
            case DATE_CONTROL_TYPE:
               annotations[noteC].fields[fIdx].defaultDate = '';
               annotations[noteC].fields[fIdx].defaultDate =
               _xmlcfg_get_value(treeHandle, cDataIdx);
               break;
            }
         }
         ++fIdx;
         fNode = _xmlcfg_get_next_sibling(treeHandle, fNode,
                                          VSXMLCFG_NODE_ELEMENT_START);
      }

      makeAnnotationCaption(annotations[noteC]);

      //Assign line markers if source file is open.
      wid = window_match(annotations[noteC].marker.sourceFile, 1, 'x');
      if (wid == 0) {
         annotations[noteC].lineMarker = -1;
      } else {
         int lmIndex;
         _str noteMessage = '';
         int typeLength = length(annotations[noteC].type);
         strappend(noteMessage, '<code>'annotations[noteC].type'</code><br>');
         strappend(noteMessage, center('', typeLength, '-')'<br>');
         strappend(noteMessage, annotations[noteC].preview);
         lmIndex = _LineMarkerAdd(wid, annotations[noteC].marker.origLineNumber,
                                  0, 0, annotationPic, noteMarkerType,
                                  noteMessage);
         annotations[noteC].lineMarker = lmIndex;
         lineMarkers:[lmIndex] = noteC;
      }

      ++noteC;
      caNode = _xmlcfg_get_next_sibling(treeHandle, caNode,
                                        VSXMLCFG_NODE_ELEMENT_START);
   }

   //If there were type collisions, we need to saved out the changed types names.
   if (collision) {
      exportAnnotations(fileName);
   }

   if (!annotations._isempty()) {
      rehashNoteIDs();
   }

   cleanDefTypes();

   _xmlcfg_close(treeHandle);
   maybeAddSCAFile(fileName);
   cleanDefFiles();

   //Setup up the LineMarker info.
   setupMarkers();

   updateAnnotationsBrowser(allAnnotations);
}



static int startAnnotationFile (_str fileName='', int& treeHandle=0,
                                 int& cadNode=0)
{
   fileName = maybe_quote_filename(fileName);
   //Create the tree.
   treeHandle = -1;
   treeHandle = _xmlcfg_create(fileName, VSENCODING_UTF8);
   if (treeHandle < 0) {
      return treeHandle;
   }

   int status = 0;
 
   do {
      //Create the XML declaration.
      int xmldecl_index = _xmlcfg_add(treeHandle, TREE_ROOT_INDEX, 'xml',
                                      VSXMLCFG_NODE_XML_DECLARATION,
                                      VSXMLCFG_ADD_AS_CHILD);
      if (xmldecl_index < 0) {
         status = xmldecl_index;
         break;
      }
   
      status = _xmlcfg_set_attribute(treeHandle, xmldecl_index, 'version', '1.0');
      if (status < 0) break;

      status = _xmlcfg_set_attribute(treeHandle, xmldecl_index, 'encoding',
                                     'UTF-8');
      if (status < 0) break;
   
      //Create the DOCTYPE declaration.
      //
      // 
   
      //Add the main tree.
      cadNode = TREE_ROOT_INDEX;
      cadNode = _xmlcfg_add(treeHandle, TREE_ROOT_INDEX, 'CodeAnnotationData',
                            VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      if (cadNode < 0) {
         status = cadNode;
         break;
      }
   
      status = _xmlcfg_add_attribute(treeHandle, cadNode, 'version', '1.0');
      if (status < 0) break;
   
      status = _xmlcfg_add_attribute(treeHandle, cadNode, 'productName',
                                     _getApplicationName());
      if (status < 0) break;
   
      status = _xmlcfg_add_attribute(treeHandle, cadNode, 'productVersion',
                                     _getVersion());
   } while (false);

   return status;
}


static int writeAnnotationDefinitionsToXML(int treeHandle, int cadNode, _str fileName)
{
   status := 0;

   // go through our list of definitions
   for (i := 0; i < annotationDefs._length(); ++i) {

      // make sure we have this filename?
      if (!annotationDefs[i].noteFiles._indexin(fileName)) {
         continue;
      }

      // the main node for this definition
      defNode := _xmlcfg_add(treeHandle, cadNode, 'AnnotationDef',
                            VSXMLCFG_NODE_ELEMENT_START,
                            VSXMLCFG_ADD_AS_CHILD);
      if (defNode < 0) {
         status = defNode;
         break;
      }
      status = _xmlcfg_add_attribute(treeHandle, defNode, 'name',
                                     annotationDefs[i].name);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, defNode, 'id',
                                     annotationDefs[i].id);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, defNode, 'author',
                                     annotationDefs[i].author);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, defNode, 'creationDate',
                                     annotationDefs[i].creationDate);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, defNode, 'lastModifiedDate',
                                     annotationDefs[i].lastModifiedDate);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, defNode, 'lastModifiedUser',
                                     annotationDefs[i].lastModifiedUser);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, defNode, 'version',
                                     annotationDefs[i].version);
      if (status < 0) break;

      for (field := 0; field < annotationDefs[i].fieldsUsed._length(); ++field) {
         fieldNode := _xmlcfg_add(treeHandle, defNode, 'FieldDef',
                                 VSXMLCFG_NODE_ELEMENT_START,
                                 VSXMLCFG_ADD_AS_CHILD);

         j := annotationDefs[i].fieldsUsed[field];

         status = _xmlcfg_add_attribute(treeHandle, fieldNode, 'name',
                                        annotationDefs[i].fields[j].name);
         if (status < 0) break;

         status = _xmlcfg_add_attribute(treeHandle, fieldNode, 'type',
                                        annotationDefs[i].fields[j].fieldType);
         if (status < 0) break;

         status = _xmlcfg_add_attribute(treeHandle, fieldNode, 'index', j);
         if (status < 0) break;

         int valueNode;
         switch (annotationDefs[i].fields[j].fieldType) {
         case TEXT_CONTROL_TYPE:
            if (!annotationDefs[i].fields[j].text._isempty()) {
               valueNode = _xmlcfg_add(treeHandle, fieldNode, 'DefaultValue',
                                       VSXMLCFG_NODE_ELEMENT_START_END,
                                       VSXMLCFG_ADD_AS_CHILD);
               status = _xmlcfg_add(treeHandle, valueNode,
                                    annotationDefs[i].fields[j].text,
                                    VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            }
            break;
         case DATE_CONTROL_TYPE:
            valueNode = _xmlcfg_add(treeHandle, fieldNode, 'DefaultValue',
                                    VSXMLCFG_NODE_ELEMENT_START_END,
                                    VSXMLCFG_ADD_AS_CHILD);

            dateInfo := '';
            if (!annotationDefs[i].fields[j].defaultDate._isempty()) { // &&
               dateInfo = annotationDefs[i].fields[j].defaultDate;
            } 
            status = _xmlcfg_add(treeHandle, valueNode,
                                 dateInfo, VSXMLCFG_NODE_CDATA,
                                 VSXMLCFG_ADD_AS_CHILD);
            break;
         case DROPDOWN_CONTROL_TYPE:
            for (k := 0; k < annotationDefs[i].fields[j].dropdown._length(); ++k) {
               valueNode = _xmlcfg_add(treeHandle, fieldNode, 'PredefinedValue',
                                       VSXMLCFG_NODE_ELEMENT_START_END,
                                       VSXMLCFG_ADD_AS_CHILD);
               status = _xmlcfg_add_attribute(treeHandle, valueNode,
                                              'name',
                                              annotationDefs[i].fields[j].dropdown[k]);
               if (status < 0) break;

               status = _xmlcfg_add_attribute(treeHandle, valueNode, 'index', k);
               if (status < 0) break;
            }

            if (annotationDefs[i].fields[j].defaultIndices._length() > 0) {
               valueNode = _xmlcfg_add(treeHandle, fieldNode, 'DefaultValue',
                                       VSXMLCFG_NODE_ELEMENT_START_END,
                                       VSXMLCFG_ADD_AS_CHILD);
               status = _xmlcfg_add(treeHandle, valueNode,
                                    annotationDefs[i].fields[j].defaultIndices[0],
                                    VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            }
            break;
         case LIST_CONTROL_TYPE:
            for (k = 0; k < annotationDefs[i].fields[j].list._length(); ++k) {
               valueNode = _xmlcfg_add(treeHandle, fieldNode, 'PredefinedValue',
                                       VSXMLCFG_NODE_ELEMENT_START_END,
                                       VSXMLCFG_ADD_AS_CHILD);
               status = _xmlcfg_add_attribute(treeHandle, valueNode,
                                              'name',
                                              annotationDefs[i].fields[j].list[k]);
               if (status < 0) break;

               status = _xmlcfg_add_attribute(treeHandle, valueNode, 'index', k);
               if (status < 0) break;
            }

            selCount := annotationDefs[i].fields[j].defaultIndices._length();
            for (selIndex := 0; selIndex < selCount; ++selIndex) {
               valueNode = _xmlcfg_add(treeHandle, fieldNode, 'DefaultValue',
                                       VSXMLCFG_NODE_ELEMENT_START_END,
                                       VSXMLCFG_ADD_AS_CHILD);
               status = _xmlcfg_add(treeHandle, valueNode,
                                    annotationDefs[i].fields[j].defaultIndices[selIndex],
                                    VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            }
            break;
         case MULTILINE_TEXT_CONTROL_TYPE:
            _str editorBuffer = '';
            for (k = 0; k < annotationDefs[i].fields[j].editor._length()-1; ++k) {
               editorBuffer = editorBuffer:+
                              annotationDefs[i].fields[j].editor[k]:+"\n";
            }
            if (k < annotationDefs[i].fields[j].editor._length()) {
               editorBuffer = editorBuffer:+
                              annotationDefs[i].fields[j].editor[k];
            }

            valueNode = _xmlcfg_add(treeHandle, fieldNode, 'DefaultValue',
                                    VSXMLCFG_NODE_ELEMENT_START_END,
                                    VSXMLCFG_ADD_AS_CHILD);
            status = _xmlcfg_add(treeHandle, valueNode,
                                 editorBuffer,
                                 VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            break;
         case CHECKBOX_CONTROL_TYPE:
            valueNode = _xmlcfg_add(treeHandle, fieldNode, 'DefaultValue',
                                    VSXMLCFG_NODE_ELEMENT_START_END,
                                    VSXMLCFG_ADD_AS_CHILD);
            status = _xmlcfg_add(treeHandle, valueNode,
                                 annotationDefs[i].fields[j].checkbox,
                                 VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            break;
         default:
            break;
         }
      }

      // if we got a negative status, then we might as well quit
      if (status < 0) break;
         
   }

   return status;
}

static int writeAnnotationsToXML(int treeHandle, int cadNode, _str fileName)
{
   status := 0;

   for (i := 0; i < annotations._length(); ++i) {
      // make sure this is for the right file
      if (fileName != annotations[i].noteFile) {
         continue;
      }

      noteNode := _xmlcfg_add(treeHandle, cadNode, 'CodeAnnotation',
                             VSXMLCFG_NODE_ELEMENT_START,
                             VSXMLCFG_ADD_AS_CHILD);
      if (noteNode < 0) {
         status = noteNode;
         break;
      }

      status = _xmlcfg_add_attribute(treeHandle, noteNode, 'annotationDefId',
                                     annotations[i].type);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, noteNode, 'author',
                                     annotations[i].author);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, noteNode, 'creationDate',
                                     annotations[i].creationDate);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, noteNode, 'lastModifiedUser',
                                     annotations[i].lastModUser);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, noteNode, 'lastModifiedDate',
                                     annotations[i].lastModDate);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, noteNode,
                                     'annotationDefVersion',
                                     annotations[i].noteDefVersion);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, noteNode, 'version',
                                     annotations[i].version);
      if (status < 0) break;

      //Add code markers.
      markerNode := _xmlcfg_add(treeHandle, noteNode, 'MarkerInfo',
                               VSXMLCFG_NODE_ELEMENT_START,
                               VSXMLCFG_ADD_AS_CHILD);
      if (fileName == workspaceSCA) {
         status = _xmlcfg_add_attribute(treeHandle, markerNode, 'fileName',
                                        stranslate(_RelativeToWorkspace(annotations[i].marker.sourceFile), '', '"'));
         if (status < 0) break;

         status = _xmlcfg_add_attribute(treeHandle, markerNode, 'basePath',
                                        _GetWorkspaceDir());
         if (status < 0) break;

      } else if (fileName == projectSCA) {
         status = _xmlcfg_add_attribute(treeHandle, markerNode, 'fileName',
                                        stranslate(_RelativeToProject(annotations[i].marker.sourceFile), '', '"'));
         if (status < 0) break;

         status = _xmlcfg_add_attribute(treeHandle, markerNode, 'basePath',
                                        _strip_filename(_project_name,'N'));
         if (status < 0) break;
      } else {
         status = _xmlcfg_add_attribute(treeHandle, markerNode, 'fileName',
                                        stranslate(annotations[i].marker.sourceFile, '', '"'));
         if (status < 0) break;
      }
      status = _xmlcfg_add_attribute(treeHandle, markerNode, 'lineNumber',
                                     annotations[i].marker.origLineNumber);
      if (status < 0) break;

      status = _xmlcfg_add_attribute(treeHandle, markerNode, 'lineCount',
                                     annotations[i].marker.totalCount);
      if (status < 0) break;

      lineNode := _xmlcfg_add(treeHandle, markerNode, 'LineText',
                             VSXMLCFG_NODE_ELEMENT_START_END,
                             VSXMLCFG_ADD_AS_CHILD);
      //The original line.
      lines := '';
      for (j := 0; j < annotations[i].marker.origText._length(); ++j) {
         lines = lines' 'annotations[i].marker.origText[j];
      }
      status = _xmlcfg_add(treeHandle, lineNode,
                           lines, VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
      //The preceding lines.
      fieldNode := _xmlcfg_add(treeHandle, markerNode, 'LinesBefore',
                              VSXMLCFG_NODE_ELEMENT_START,
                              VSXMLCFG_ADD_AS_CHILD);
      for (j = 0; j < annotations[i].marker.textAbove._length(); ++j) {
         lineNode = _xmlcfg_add(treeHandle, fieldNode, 'LineText',
                                VSXMLCFG_NODE_ELEMENT_START_END,
                                VSXMLCFG_ADD_AS_CHILD);
         lines = '';
         for (k := 0; k < annotations[i].marker.textAbove[j]._length(); ++k) {
            lines = lines' 'annotations[i].marker.textAbove[j][k];
         }
         status = _xmlcfg_add(treeHandle, lineNode, lines, VSXMLCFG_NODE_CDATA,
                              VSXMLCFG_ADD_AS_CHILD);
      }

      //The following lines.
      fieldNode = _xmlcfg_add(treeHandle, markerNode, 'LinesAfter',
                              VSXMLCFG_NODE_ELEMENT_START,
                              VSXMLCFG_ADD_AS_CHILD);
      for (j = 0; j < annotations[i].marker.textBelow._length(); ++j) {
         lineNode = _xmlcfg_add(treeHandle, fieldNode, 'LineText',
                                VSXMLCFG_NODE_ELEMENT_START_END,
                                VSXMLCFG_ADD_AS_CHILD);
         lines = '';
         for (k := 0; k < annotations[i].marker.textBelow[j]._length(); ++k) {
            lines = lines' 'annotations[i].marker.textBelow[j][k];
         }
         status = _xmlcfg_add(treeHandle, lineNode, lines, VSXMLCFG_NODE_CDATA,
                              VSXMLCFG_ADD_AS_CHILD);
      }

      //Add other fields.
      for (j = 0; j < annotations[i].fields._length(); ++j) {
         fieldNode = _xmlcfg_add(treeHandle, noteNode, 'Field',
                                 VSXMLCFG_NODE_ELEMENT_START,
                                 VSXMLCFG_ADD_AS_CHILD);

         status = _xmlcfg_add_attribute(treeHandle, fieldNode, 'name',
                                        annotations[i].fields[j].name);

         valueNode := _xmlcfg_add(treeHandle, fieldNode, 'Value',
                                 VSXMLCFG_NODE_ELEMENT_START,
                                 VSXMLCFG_ADD_AS_CHILD);

         switch (annotations[i].fields[j].fieldType) {
         case TEXT_CONTROL_TYPE:
            status = _xmlcfg_add(treeHandle, valueNode,
                                 annotations[i].fields[j].text,
                                 VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            break;
         case MULTILINE_TEXT_CONTROL_TYPE:
            lines = '';
            for (k := 0; k < annotations[i].fields[j].editor._length()-1; ++k) {
               lines = lines:+annotations[i].fields[j].editor[k]:+"\n";
            }
            if (k < annotations[i].fields[j].editor._length()) {
               lines = lines:+annotations[i].fields[j].editor[k];
            }
            status = _xmlcfg_add(treeHandle, valueNode,
                                 lines,
                                 VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            break;
         case DROPDOWN_CONTROL_TYPE:
            if (annotations[i].fields[j].defaultIndices._length() > 0) {
               status = _xmlcfg_add(treeHandle, valueNode,
                                    annotations[i].fields[j].defaultIndices[0],
                                    VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            }
            break;
         case LIST_CONTROL_TYPE:
            for (k = 0;
                k < annotations[i].fields[j].defaultIndices._length()-1;
                ++k) {
               status = _xmlcfg_add(treeHandle, valueNode,
                                    annotations[i].fields[j].defaultIndices[k],
                                    VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
               valueNode = _xmlcfg_add(treeHandle, fieldNode, 'Value',
                                       VSXMLCFG_NODE_ELEMENT_START,
                                       VSXMLCFG_ADD_AS_CHILD);
               if (status < 0) break;
            }
            status = _xmlcfg_add(treeHandle, valueNode,
                                 annotations[i].fields[j].defaultIndices[k],
                                 VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            break;
         case CHECKBOX_CONTROL_TYPE:
            status = _xmlcfg_add(treeHandle, valueNode,
                                 annotations[i].fields[j].checkbox,
                                 VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            break;
         case DATE_CONTROL_TYPE:
            status = _xmlcfg_add(treeHandle, valueNode,
                                 annotations[i].fields[j].defaultDate,
                                 VSXMLCFG_NODE_CDATA, VSXMLCFG_ADD_AS_CHILD);
            break;
         }
      }

      // if we got an error, then quit
      if (status < 0) break;
   }

   return status;
}

static int exportAnnotations (_str fileName='')
{
   int treeHandle;
   int cadNode;
   status := startAnnotationFile(fileName, treeHandle, cadNode);
   if (status < 0) {
      _message_box("Error creating annotations file "fileName".  Error : "get_message(status));
      return status;
   }

   //Add definitions.
   status = writeAnnotationDefinitionsToXML(treeHandle, cadNode, fileName);
   if (status < 0) {
      _message_box("Error writing annotation defintions to "fileName".  Error : "get_message(status));
      return status;
   }

   //Add annotations.
   status = writeAnnotationsToXML(treeHandle, cadNode, fileName);
   if (status < 0) {
      _message_box("Error writing annotations to "fileName".  Error : "get_message(status));
      return status;
   }

   // finally, save the file
   status = _xmlcfg_save(treeHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE|
                VSXMLCFG_SAVE_UNIX_EOL);
   if (status < 0) {
      _message_box("Error saving annotation information to "fileName".  Error : "get_message(status));
      return status;
   }
   _xmlcfg_close(treeHandle);

   return 0;
}



defeventtab _annotations_definitions_form;
void _annotations_definitions_form.on_create ()
{
   bitmaps:[TEXT_CONTROL_TYPE] = _update_picture(-1, '_textbox16.ico');
   bitmaps:[MULTILINE_TEXT_CONTROL_TYPE] = _update_picture(-1, '_editwin16.ico');
   bitmaps:[DROPDOWN_CONTROL_TYPE] = _update_picture(-1, '_combobx16.ico');
   bitmaps:[LIST_CONTROL_TYPE] = _update_picture(-1, '_listbox16.ico');
   bitmaps:[CHECKBOX_CONTROL_TYPE] = _update_picture(-1, '_checkbx16.ico');
   bitmaps:[DATE_CONTROL_TYPE] = _update_picture(-1, '_calendar16.ico');

   _singlelinetext_box.p_visible = false;
   _multilinetext_box.p_visible = false;
   _sselect_box.p_visible = false;
   _mselect_box.p_visible = false;
   _checkbox_box.p_visible = false;
   _date_box.p_visible = false;
   p_width = 9299;
   p_height = 4206;

   //Restore the positions of the divider bars.
   typeless xpos;
   xpos = _retrieve_value("_annotations_definitions_form._left_sizebar_x.p_x");
   if (isuinteger(xpos)) {
      _left_sizebar_x.p_x = xpos;
   }
   xpos = _retrieve_value("_annotations_definitions_form._right_sizebar_x.p_x");
   if (isuinteger(xpos)) {
      _right_sizebar_x.p_x = xpos;
   }

   _annotations_definitions_form_initial_alignment();

   previousType = '';
   currentType = '';
   currentField = '';

   //Insert all the types for the current SCA file.
   for (i := 0; i < annotationDefs._length(); ++i) {
      _type_list._TreeAddItem(TREE_ROOT_INDEX, annotationDefs[i].name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   }

   _field_list._TreeTop();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _annotations_definitions_form_initial_alignment()
{
   // set up all the alignment - do this once so that the resizing code will work properly
   padding := _file_box.p_x;
   _file_box.p_width = p_active_form.p_width - (2 * padding);

   _types_frame.p_width = _left_sizebar_x.p_x - _types_frame.p_x;
   _left_sizebar_x.p_y = _types_frame.p_y + padding;
   _fields_frame.p_x = _types_frame.p_x + _types_frame.p_width + padding;
   _fields_frame.p_width = _right_sizebar_x.p_x - _fields_frame.p_x;
   _right_sizebar_x.p_y = _fields_frame.p_y + padding;

   _field_frame.p_x = _fields_frame.p_x + _fields_frame.p_width + padding;
   _field_frame.p_y = _types_frame.p_y;
   _field_frame.p_width = p_active_form.p_width - (_field_frame.p_x + padding);

   _okay.p_x = p_width - (_okay.p_width + padding);
   _okay.p_y = _field_frame.p_y + _field_frame.p_height + padding;

   rightAlign := _types_frame.p_width - _type_list.p_x;
   alignUpDownListButtons(_type_list, rightAlign, _add_type.p_window_id, _delete_type.p_window_id);

   resizeTypesFrame();

   rightAlign = _fields_frame.p_width - _field_list.p_x;
   alignUpDownListButtons(_field_list, rightAlign, _add_field.p_window_id, _raise_field.p_window_id,
                          _lower_field.p_window_id, _delete_field.p_window_id);
   resizeFieldsFrame();

   _singlelinetext_box.p_x = _multilinetext_box.p_x = _date_box.p_x = _checkbox_box.p_x = _mselect_box.p_x = _sselect_box.p_x = _type_list.p_x;
   _singlelinetext_box.p_y = _multilinetext_box.p_y = _date_box.p_y = _checkbox_box.p_y = _mselect_box.p_y = _sselect_box.p_y = _type_list.p_y;

   resizeFieldFrame();

   rightAlign = _mselect_box.p_width;
   alignUpDownListButtons(_list_items.p_window_id, rightAlign, _add_listitem.p_window_id, _raise_listitem.p_window_id,
                          _lower_listitem.p_window_id, _delete_listitem.p_window_id);

   rightAlign = _sselect_box.p_width;
   alignUpDownListButtons(_dropdown_items.p_window_id, rightAlign, _add_dropdownitem.p_window_id, _raise_dropdownitem.p_window_id,
                          _lower_dropdownitem.p_window_id, _delete_dropdownitem.p_window_id);

}

static void addFields (int typeIndex)
{
   _field_list._TreeDelete(TREE_ROOT_INDEX, 'C');

   int nOfFields = annotationDefs[typeIndex].fieldsUsed._length();
   for (i := 0; i < nOfFields; ++i) {
      j := annotationDefs[typeIndex].fieldsUsed[i];
      addField(typeIndex, j);
   }

   // select the top one
   _field_list._TreeTop();
   _field_list.call_event(CHANGE_SELECTED, _field_list._TreeCurIndex(), _field_list, ON_CHANGE, 'W');
}



static void addField (int typeIndex, int fieldIndex)
{
   _str name = annotationDefs[typeIndex].fields[fieldIndex].name;
   _str control = annotationDefs[typeIndex].fields[fieldIndex].fieldType;
   treeIndex := _field_list._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, bitmaps:[control], bitmaps:[control], TREE_NODE_LEAF);

   // set the control type as the user info
   _field_list._TreeSetUserInfo(treeIndex, control);

   typeFieldIndices i;
   i.type = typeIndex;
   i.field = fieldIndex;

   _SetDialogInfoHt(name, i, _field_list);
}

static void commitType ()
{
   typeFieldIndices i;
   _str itemName = '';
   int fieldIndex = 0;

   index := _field_list._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index < 0) return;

   itemName = _field_list._TreeGetCaption(index);
   if (itemName == '') {
      return;
   }
   i = _GetDialogInfoHt(itemName, _field_list);
   annotationDefs[i.type].fieldsUsed._makeempty();
   annotationDefs[i.type].lastModifiedUser = annotation_username();
   annotationDefs[i.type].lastModifiedDate = annotation_date();
   annotationDefs[i.type].version++;

   _mod_date.p_caption = annotationDefs[i.type].lastModifiedDate;
   _mod_user.p_caption = annotationDefs[i.type].lastModifiedUser;
   ctl_version.p_caption = annotationDefs[i.type].version;

   while (true) {
      annotationDefs[i.type].fieldsUsed[fieldIndex++] = i.field;
      index = _field_list._TreeGetNextSiblingIndex(index);
      if (index < 0) {
         break;
      }
      itemName = _field_list._TreeGetCaption(index);
      i = _GetDialogInfoHt(itemName, _field_list);
   }

   clearFieldFrame();

   int j;
   for (j = 0; j < annotations._length(); ++j) {
      if (annotations[j].type == lowcase(currentType)) {
         makeAnnotationCaption(annotations[j]);
      }
   }
}

void _add_type.lbutton_up ()
{
   status := textBoxDialog("Enter New Type Name",         // form caption
                          0,                             // flags
                          0,                             // text box width
                          "",                            // help item
                          "",                            // button/caption list
                          "",                            // retrieve name
                          "Type name:");        // prompt

   // user cancelled
   if (status < 0) return;

   name = _param1;
   if (isNewType(name)) {
      index := _type_list._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      addNewType(name);
      _type_list._TreeSetCurIndex(index);
   } else {
      // can't use this name, already have it
      _message_box("There is already a type with this name.");
   }
}

void _delete_type.lbutton_up ()
{
   _str typeName = '';
   int index = -1;

   typeName = _type_list._TreeGetCurCaption();

   if (types._indexin(lowcase(typeName))) {
      int deleteResult = 0;
      deleteResult = _message_box("The '"typeName"' type is in use by ":+
                                  "existing annotations. Deleting '"typeName:+
                                  "' will also delete the annotations. ":+
                                  "Proceed?", '', MB_YESNO);
      if (deleteResult == IDNO) {
         return;
      }
   }

   index = annotationTypes:[lowcase(typeName)];
   _str noteFiles:[] = annotationDefs[index].noteFiles;

   //Delete the type definition.
   annotationDefs._deleteel(index);

   //Delete the annotations of that type.
   int i;
   int el;
   for (i = (types:[lowcase(typeName)]._length()-1); i >=0 ; --i) {
      el = types:[lowcase(typeName)][i];
      _LineMarkerRemove(annotations[el].lineMarker);
      annotations._deleteel(el);
   }

   rehashNoteIDs();
   annotationTypes._deleteel(lowcase(typeName));
   rebuildAnnotationTypes();

   for (i = 0; i < defTypes._length(); ) {
      if (!annotationTypes._indexin(lowcase(defTypes[i]))) {
         defTypes._deleteel(i);
      } else {
         ++i;
      }
   }

   _type_list._TreeDelete(_type_list._TreeCurIndex());

   typeName = _type_list._TreeGetCurCaption();
   if (typeName == '') {
      _field_list._TreeDelete(TREE_ROOT_INDEX, 'C');
      return;
   }

   index = annotationTypes:[lowcase(typeName)];
   addFields(index);

   typeless each;
   for (each._makeempty(); ; ) {
      noteFiles._nextel(each);
      if (each._isempty()) {
         break; 
      }
      exportAnnotations(each);
   }

   updateAnnotationsBrowser(allAnnotations);
}



static _str showWarning (_str typeName)
{
   return _message_box("The '"typeName"' type is in use by ":+
                       "existing annotations. Modifying '"typeName:+
                       "' may cause data loss in the annotations. ":+
                       "Proceed?", '', MB_YESNO);
}

void _add_field.lbutton_up ()
{
   status := textBoxDialog("Enter New Field` Name",         // form caption
                          0,                             // flags
                          0,                             // text box width
                          "",                            // help item
                          "",                            // button/caption list
                          "",                            // retrieve name
                          "Type name:");        // prompt

   // user cancelled
   if (status < 0) return;

   name = _param1;
   if (isNewField(name)) {
      _str controlType = addNewField(name);
      if (controlType != '') {
         // add our new field to the tree
         treeIndex := _field_list._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, bitmaps:[controlType], bitmaps:[controlType], TREE_NODE_LEAF);

         // set the control type as the user info
         _field_list._TreeSetUserInfo(treeIndex, controlType);

         typeFieldIndices i;
         i.type = annotationTypes:[lowcase(currentType)];
         i.field = annotationDefs[i.type].fields._length()-1;
         _SetDialogInfoHt(currentType'.'name, i, _field_list);

         int j;
         //If any annotations exist for the type we're modifying, add fields
         //to it.
         for (j = 0; j < annotations._length(); ++j) {
            if (annotations[j].type == lowcase(currentType)) {
               if (annotations[j].fields[i.field]._isempty()) {
                  annotations[j].fields[i.field] =
                  annotationDefs[i.type].fields[i.field];
               }
            }
         }
         commitType();

         currentField = name;
         _field_list.call_event(CHANGE_OTHER, _field_list, ON_CHANGE, 'w');
      }
   }
}

void _raise_field.lbutton_up ()
{
   _field_list._TreeMoveUp(_field_list._TreeCurIndex());
   commitType();
}

void _lower_field.lbutton_up ()
{
   _field_list._TreeMoveDown(_field_list._TreeCurIndex());
   commitType();
}

void _delete_field.lbutton_up ()
{
   fieldName1 := _field_list._TreeGetCurCaption();
   _field_list._TreeDelete(_field_list._TreeCurIndex());

   if (_field_list._TreeGetNumChildren(TREE_ROOT_INDEX) == 0) {
      typeFieldIndices j;
      j = _GetDialogInfoHt(fieldName1, _field_list);
      annotationDefs[j.type].fieldsUsed._makeempty();
   }

   typeFieldIndices i;
   i.field = -1;
   i.type = -1;
   _SetDialogInfoHt(fieldName1, i, _field_list);
   currentField = '';

   commitType();
}

void _add_listitem.lbutton_up ()
{
   status := textBoxDialog("Enter New List Item",         // form caption
                          0,                             // flags
                          0,                             // text box width
                          "",                            // help item
                          "",                            // button/caption list
                          "",                            // retrieve name
                          "List item:");        // prompt

   // user cancelled
   if (status < 0) return;

   name = _param1;
   if (isNewListItem(name)) {
      _list_items._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   } else {
      // can't use this name, already have it
      _message_box("There is already an item with this name.");
   }
}

// Moves the current item in the list up one
void _raise_listitem.lbutton_up ()
{
   _list_items._TreeMoveUp(_list_items._TreeCurIndex());

   // update our field list
   updateFieldDefinition();
}

void _lower_listitem.lbutton_up ()
{
   _list_items._TreeMoveDown(_list_items._TreeCurIndex());
   updateFieldDefinition();
}

void _delete_listitem.lbutton_up ()
{
   _list_items._TreeDelete(_list_items._TreeCurIndex());

   // update our definition
   updateFieldDefinition();
}

void _add_dropdownitem.lbutton_up ()
{
   status := textBoxDialog("Enter New Item",         // form caption
                          0,                             // flags
                          0,                             // text box width
                          "",                            // help item
                          "",                            // button/caption list
                          "",                            // retrieve name
                          "Dropdown item:");        // prompt

   // user cancelled
   if (status < 0) return;

   name = _param1;
   if (isNewDropdownItem(name)) {
      index := _dropdown_items._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   } else {
      // can't use this name, already have it
      _message_box("There is already a type with this name.");
   }
}

void _raise_dropdownitem.lbutton_up ()
{
   _dropdown_items._TreeMoveUp(_dropdown_items._TreeCurIndex());
}

void _lower_dropdownitem.lbutton_up ()
{
   _dropdown_items._TreeMoveDown(_dropdown_items._TreeCurIndex());
}

void _delete_dropdownitem.lbutton_up ()
{
   _dropdown_items._TreeDelete(_dropdown_items._TreeCurIndex());
}

void _annotations_definitions_form.esc ()
{
   p_active_form._delete_window();
}

void _annotations_definitions_form.on_destroy ()
{
   updateFieldDefinition();

   exportAllAnnotations();

   //Save the position of the divider bars.
   _append_retrieve(0, _left_sizebar_x.p_x,
                    "_annotations_definitions_form._left_sizebar_x.p_x");
   _append_retrieve(0, _right_sizebar_x.p_x,
                    "_annotations_definitions_form._right_sizebar_x.p_x");
}

void _okay.lbutton_up ()
{
   p_active_form._delete_window(1);
}

void _annotations_definitions_form.on_resize()
{
   padding := _file_box.p_x;
   widthDiff := p_width - (_file_box.p_x + _file_box.p_width + padding);
   heightDiff := p_height - (_okay.p_y + _okay.p_height + padding);

   _file_box.p_width += widthDiff;

   _types_frame.p_height += heightDiff;
   resizeTypesFrame();

   _fields_frame.p_height = _types_frame.p_height;
   resizeFieldsFrame();

   _left_sizebar_x.p_height += heightDiff;
   _right_sizebar_x.p_height += heightDiff;

   _field_frame.p_width += widthDiff;
   _field_frame.p_height = _fields_frame.p_height;
   resizeFieldFrame();

   _okay.p_x += widthDiff;
   _okay.p_y += heightDiff;

   adjustFileBox();
}

void _left_sizebar_x.lbutton_down()
{
   _ul2_image_sizebar_handler(_types_frame.p_x + 80,
                              _fields_frame.p_x +
                              _fields_frame.p_width);
}



void _right_sizebar_x.lbutton_down()
{
   _ul2_image_sizebar_handler(_fields_frame.p_x + 80,
                              _field_frame.p_x +
                              _field_frame.p_width);
}



static void adjustFileBox ()
{
   int widestDate = 0;
   int widestUser = 0;
   int width1 = 0;
   int width2 = 0;

   width1 = _date_created.p_width;
   width2 = _mod_date.p_width;
   if (width1 > width2) {
      widestDate = width1;
   } else {
      widestDate = width2;
   }
   width1 = _author_name.p_width;
   width2 = _mod_user.p_width;
   if (width1 > width2) {
      widestUser = width1;
   } else {
      widestUser = width2;
   }

   //X positions
   _mod_date.p_x = _mod_date_label.p_x + _mod_date_label.p_width + 60;
   _date_created.p_x = _mod_date.p_x;
   _date_created_label.p_x = _date_created.p_x -
                             _date_created_label.p_width - 60;

   _mod_user_label.p_x = _mod_date.p_x + widestDate + 300;
   _mod_user.p_x = _mod_user_label.p_x + _mod_user_label.p_width + 60;
   _author_name.p_x = _mod_user.p_x;
   _author_label.p_x = _author_name.p_x - _author_label.p_width - 60;
   _version_label.p_x = _author_label.p_x + _author_label.p_width + widestUser +
                        360;
   ctl_version.p_x = _version_label.p_x + _version_label.p_width + 60;

   //Y positions
   _mod_date_label.p_y = _date_created.p_y + _date_created.p_height + 60;
   _mod_date.p_y = _mod_date_label.p_y;
   _mod_user_label.p_y = _mod_date_label.p_y;
   _mod_user.p_y = _mod_date_label.p_y;
}

static void resizeTypesFrame()
{
   padding := _type_list.p_x;
   heightDiff := _types_frame.p_height - (_type_list.p_y + _type_list.p_height + padding);
   widthDiff := _types_frame.p_width - (_add_type.p_x + _add_type.p_width + padding);

   _add_type.p_x += widthDiff;
   _delete_type.p_x = _add_type.p_x;

   _type_list.p_height += heightDiff;
   _type_list.p_width += widthDiff;
}

static void resizeFieldsFrame()
{
   padding := _field_list.p_x;
   heightDiff := _fields_frame.p_height - (_field_list.p_y + _field_list.p_height + padding);
   widthDiff := _fields_frame.p_width - (_add_field.p_x + _add_field.p_width + padding);

   _field_list.p_height += heightDiff;
   _field_list.p_width += widthDiff;

   _add_field.p_x += widthDiff;
   _raise_field.p_x = _add_field.p_x;
   _lower_field.p_x =  _raise_field.p_x;
   _delete_field.p_x = _lower_field.p_x;
}

static void resizeFieldFrame()
{
   padding := _singlelinetext_box.p_x;
   frameWidth := _field_frame.p_width - (_singlelinetext_box.p_x + padding);
   frameHeight := _field_frame.p_height - (_singlelinetext_box.p_y + padding);

   resize_singlelinetext_box(frameWidth, frameHeight);
   resize_multilinetext_box(frameWidth, frameHeight);
   resize_sselect_box(frameWidth, frameHeight);
   resize_mselect_box(frameWidth, frameHeight);
   resize_checkbox_box(frameWidth, frameHeight);
   resize_date_box(frameWidth, frameHeight);
}

static void resize_singlelinetext_box(int frameWidth, int frameHeight)
{
   _singlelinetext_box.p_width = frameWidth;
   _singlelinetext_box.p_height = frameHeight;

   _dtext.p_x = _dtext_label.p_width + 60;
   _dtext.p_width = frameWidth - (_dtext.p_x + _dtext_label.p_x);
}

static void resize_multilinetext_box(int frameWidth, int frameHeight)
{
   _multilinetext_box.p_width = frameWidth;
   _multilinetext_box.p_height = frameHeight;

   _deditor.p_width = _multilinetext_box.p_width;
   _deditor.p_height = _multilinetext_box.p_height - _deditor.p_y;
}

static void resize_sselect_box(int frameWidth, int frameHeight)
{
   widthDiff := frameWidth - _sselect_box.p_width;

   _sselect_box.p_width = frameWidth;
   _sselect_box.p_height = frameHeight;

   _add_listitem.p_x += widthDiff;
   _delete_listitem.p_x = _lower_listitem.p_x = _raise_listitem.p_x = _add_listitem.p_x;

   _list_items.p_width += widthDiff;
   _list_items.p_height = _sselect_box.p_height;
}

static void resize_mselect_box(int frameWidth, int frameHeight)
{
   widthDiff := frameWidth - _mselect_box.p_width;

   _mselect_box.p_width = frameWidth;
   _mselect_box.p_height = frameHeight;

   _add_dropdownitem.p_x += widthDiff;
   _delete_dropdownitem.p_x = _lower_dropdownitem.p_x = _raise_dropdownitem.p_x = _add_dropdownitem.p_x;

   _dropdown_items.p_width += widthDiff;
   _dropdown_items.p_height = _mselect_box.p_height;
}

static void resize_checkbox_box(int frameWidth, int frameHeight)
{
   _checkbox_box.p_width = frameWidth;
   _checkbox_box.p_height = frameHeight;
}

static void resize_date_box(int frameWidth, int frameHeight)
{
   _date_box.p_width = frameWidth;
   _date_box.p_height = frameHeight;

   _ddate_label.p_x = _ddate.p_width + 60;
   _ddate_label.p_y = _ddate.p_y + (_ddate.p_height - _ddate_label.p_height)/2;
}

_ddate.lbutton_up()
{
   _str yyyy = '';
   _str mm = '';
   _str dd = '';
   _str label = '';
   parse _ddate_label.p_caption with label ': ' yyyy '-' mm '-' dd;
   DateTime today;
   if ((yyyy != '') && (mm != '') && (dd != '')) {
      DateTime anotherDay((int)yyyy, (int)mm, (int)dd);
      today = anotherDay;
   }

   DateTime result;
   calendar(today, 0, null, &result);

   _str date = '';
   if (result != null) {
      parse result.toString() with date 'T' .;
   } else {
      parse today.toString() with date 'T' .;
   }
   _ddate_label.p_caption = label': 'date;
}


/** 
 * Determines if a string is valid name for a new type, i.e. it doesn't yet 
 * appear in the annotationType hash. 
 *  
 * @param newType    Name of the potential new type.
 * 
 * @return boolean
 */
boolean isNewType (_str newTypeName)
{
   if (annotationTypes._indexin(lowcase(newTypeName))) {
      return false;
   }
   return true;
}



void addNewType (_str newTypeName)
{
   if (newTypeName == '') return;

   previousType = currentType;
   currentType = newTypeName;

   AnnotationTypeInfo ati;
   ati.id = guid_create_string('G');
   ati.lastModifiedUser = ati.author = annotation_username();
   ati.lastModifiedDate = ati.creationDate = annotation_date();
   ati.name = newTypeName;

   ati.noteFiles:[personalSCA] = personalSCA;
   ati.version = "1";
   ati.fields._makeempty();
   ati.fieldsUsed._makeempty();

   // finally, add it to the annotation definition lists
   index := annotationDefs._length();
   annotationDefs[index] = ati;
   annotationTypes:[lowcase(ati.name)] = index;
   defTypes[index] = ati.name;
}

void _type_list.on_change (int reason)
{
   previousType = currentType;
   currentType = _TreeGetCurCaption();
   if (currentType == '') return;

   i := annotationTypes:[lowcase(currentType)];

   currentField = '';

   _singlelinetext_box.p_visible = false;
   _multilinetext_box.p_visible = false;
   _sselect_box.p_visible = false;
   _mselect_box.p_visible = false;
   _checkbox_box.p_visible = false;
   _date_box.p_visible = false;

   if (!annotationDefs._length()) {
      return;
   }

   _author_name.p_caption = annotationDefs[i].author;
   _date_created.p_caption = annotationDefs[i].creationDate;
   _mod_date.p_caption = annotationDefs[i].lastModifiedDate;
   _mod_user.p_caption = annotationDefs[i].lastModifiedUser;
   ctl_version.p_caption = annotationDefs[i].version;

   adjustFileBox();

   addFields(i);
}



/** 
 * Determines if a string is valid name for a new field in the current type, 
 * i.e. the name isn't already taken.. 
 *  
 * @param newType    Name of the potential new type.
 * 
 * @return boolean
 */
boolean isNewField (_str newFieldName)
{
   typeFieldIndices i;
   i = _GetDialogInfoHt(currentType'.'newFieldName, _field_list);
   if (i._isempty()) {
      return true;
   }
   if ((i.field == -1) && (i.type == -1)) {
      return true;
   }
   return false;
}




_str addNewField (_str newFieldName)
{
   _str type = '';
   type = currentType;

   //Let users know that modifying a type (by adding a field) may be dangerous.
   if (types._indexin(type)) {
      _str modResult = showWarning(type);
      if (modResult == IDNO) {
         return '';
      }
   }

   int i = annotationTypes:[lowcase(type)];

   _str newFieldType = '';
   while (newFieldType == '') {
      newFieldType = show('-modal _new_annotation_field_form');
      if (newFieldType < 1) {
         return '';
      }
   }

   int fieldPos = annotationDefs[i].fields._length();
   prepFieldInfo(annotationDefs[i].fields[fieldPos]);
   annotationDefs[i].fields[fieldPos].name = newFieldName;
   annotationDefs[i].fields[fieldPos].fieldType = newFieldType;
   //Initialize the new field type.
   switch (newFieldType) {
   case TEXT_CONTROL_TYPE:
   case MULTILINE_TEXT_CONTROL_TYPE:
   case LIST_CONTROL_TYPE:
   case DROPDOWN_CONTROL_TYPE:
   case DATE_CONTROL_TYPE:
      break;
   case CHECKBOX_CONTROL_TYPE:
      annotationDefs[i].fields[fieldPos].checkbox = 'false';
      break;
   }
   annotationDefs[i].fieldsUsed[annotationDefs[i].fieldsUsed._length()] =
   fieldPos;

   _str name = annotationDefs[i].fields[fieldPos].name;
   typeFieldIndices j;
   j.type = i;
   j.field = fieldPos;

   _SetDialogInfoHt(name, j, _field_list);

   return newFieldType;
}

void _field_list.on_change ()
{
   // before we update the gui for the new field, make sure we are up to 
   // date on the old field
   updateFieldDefinition();

   treeIndex := _TreeCurIndex();

   currentField = _TreeGetCaption(treeIndex);
   if (currentField == '') {
      return;
   }

   // make all the control types invisible
   _singlelinetext_box.p_visible = false;
   _multilinetext_box.p_visible = false;
   _sselect_box.p_visible = false;
   _mselect_box.p_visible = false;
   _checkbox_box.p_visible = false;
   _date_box.p_visible = false;

   // retrieve the control type from the tree's user info
   controlType := _TreeGetUserInfo(treeIndex);

   // if the control type hasn't been set yet, then we are probably not ready to do anything
   if (controlType == '') return;

   _field_frame.p_caption = controlType;

   // now make the one we want visible
   fieldChange(controlType);

   typeFieldIndices i = _GetDialogInfoHt(currentField, _field_list);
   if (i != null) {
      annotationDefs[i.type].fields[i.field].fieldType = controlType;
      updateFieldFrame(annotationDefs[i.type].fields[i.field]);
   }
}



//Save any changes to definition fields when the fields lose focus.
void _dtext.on_lost_focus()
{
   updateFieldDefinition();
}
void _deditor.on_lost_focus()
{
   updateFieldDefinition();
}
void _checkbox_state.on_lost_focus()
{
   updateFieldDefinition();
}
void _ddate.on_lost_focus()
{
   updateFieldDefinition();
}


boolean isNewListItem (_str newListItemName)
{
   if (newListItemName == '') {
      return false;
   }

   _str fieldName = _field_list._TreeGetCurCaption();
   int i;
   int j;
   int k;

   i = annotationTypes:[lowcase(currentType)];
   for (j = 0; j < annotationDefs[i].fields._length(); ++j ) {
      if (fieldName == annotationDefs[i].fields[j].name) {
         break;
      }
   }

   for (k = 0; k < annotationDefs[i].fields[j].list._length(); ++k) {
      if (newListItemName == annotationDefs[i].fields[j].list[k]) {
         return false;
      }
   }
   annotationDefs[i].fields[j].list[k] = newListItemName;
   return true;
}

//If an entry is selected, make it a default selection. Default selections
//are recorded in the field's defaultIndices array.
void _list_items.on_change ()
{
   //Find the proper annotation and field.
   fieldName := _field_list._TreeGetCurCaption();
   if (fieldName == '') return;

   typeFieldIndices i = _GetDialogInfoHt(fieldName, _field_list);
   if (i == null) return;

   annotationDefs[i.type].fields[i.field].defaultIndices._makeempty();

   int selIndex[];
   _list_items._TreeGetSelectionIndices(selIndex);
   for (j := 0; j < selIndex._length(); j++) {
      index := annotationDefs[i.type].fields[i.field].defaultIndices._length();
      annotationDefs[i.type].fields[i.field].defaultIndices[index] = _list_items._TreeGetLineNumber(selIndex[j]);
   }
}

boolean isNewDropdownItem (_str newListItemName)
{
   if (newListItemName == '') {
      return false;
   }

   _str fieldName = _field_list._TreeGetCurCaption();
   int i;
   int j;
   int k;

   i = annotationTypes:[lowcase(currentType)];
   for (j = 0; j < annotationDefs[i].fields._length(); ++j ) {
      if (fieldName == annotationDefs[i].fields[j].name) {
         break;
      }
   }

   for (k = 0; k < annotationDefs[i].fields[j].dropdown._length(); ++k) {
      if (newListItemName == annotationDefs[i].fields[j].dropdown[k]) {
         return false;
      }
   }
   annotationDefs[i].fields[j].dropdown[k] = newListItemName;
   return true;
}

void _dropdown_items.on_change ()
{
   item := _dropdown_items._TreeGetCurCaption();
   if (item != '') {
      typeFieldIndices i = _GetDialogInfoHt(item, _field_list);

      if (i != null) {
         annotationDefs[i.type].fields[i.field].defaultIndices._makeempty();
         annotationDefs[i.type].fields[i.field].defaultIndices[0] = _dropdown_items._TreeCurLineNumber() - 1;
      }
   }
}



static void fieldChange (_str newKey)
{
   switch (newKey) {
   case TEXT_CONTROL_TYPE:
      _singlelinetext_box.p_visible = true;
      break;
   case MULTILINE_TEXT_CONTROL_TYPE:
      _multilinetext_box.p_visible = true;
      break;
   case LIST_CONTROL_TYPE:
      _mselect_box.p_visible = true;
      break;
   case DROPDOWN_CONTROL_TYPE:
      _sselect_box.p_visible = true;
      break;
   case CHECKBOX_CONTROL_TYPE:
      _checkbox_box.p_visible = true;
      break;
   case DATE_CONTROL_TYPE:
      _date_box.p_visible = true;
      break;
   }
}


static void updateFieldDefinition()
{
   // no current item?  well, get it!
   if (currentField == '') {
      currentField = _field_list._TreeGetCurCaption();
   }

   // we can't do anything without a current field
   if (currentField == '') return;

   // get the index of this field
   typeFieldIndices i = _GetDialogInfoHt(currentField, _field_list);
   if (i == null) return;

   if (_singlelinetext_box.p_visible) {
      // Text Control
      annotationDefs[i.type].fields[i.field].text = _dtext.p_text;
   } else if (_multilinetext_box.p_visible) {
      // Multiline Text Control
      _str line = '';
      annotationDefs[i.type].fields[i.field].editor._makeempty();
      _deditor.top();
      _deditor.up();
      j := 0;
      while (!_deditor.down()) {
         _deditor.get_line(annotationDefs[i.type].fields[i.field].editor[j++]);
      }
   } else if (_mselect_box.p_visible) {
      // List Control
      index := _list_items._TreeGetFirstChildIndex(TREE_ROOT_INDEX);

      j := 0;
      annotationDefs[i.type].fields[i.field].list._makeempty();
      _str listEntry = _list_items._TreeGetCaption(index);
      if (listEntry != '') {
         annotationDefs[i.type].fields[i.field].list[j++] = listEntry;
      }
      while (true) {
         index = _list_items._TreeGetNextSiblingIndex(index);
         if (index < 0) break;

         listEntry = _list_items._TreeGetCaption(index);
         if (listEntry != '') {
            annotationDefs[i.type].fields[i.field].list[j++] = listEntry;
         }
      }
   } else if (_sselect_box.p_visible) {
      // Dropdown Control
      // start at the top of the list
      index := _dropdown_items._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      j := 0;

      // make our current array empty
      annotationDefs[i.type].fields[i.field].dropdown._makeempty();

      // get the top one
      _str ddEntry = _dropdown_items._TreeGetCaption(index);
      if (ddEntry != '') {
         annotationDefs[i.type].fields[i.field].defaultIndices[0] = j;
         annotationDefs[i.type].fields[i.field].dropdown[j++] = ddEntry;
      }

      // now go through the rest of the list
      while (true) {
         index = _dropdown_items._TreeGetNextSiblingIndex(index);
         if (index < 0) break;

         ddEntry = _dropdown_items._TreeGetCaption(index);
         if (ddEntry != '') {
            annotationDefs[i.type].fields[i.field].dropdown[j++] = ddEntry;
         }
      }
   } else if (_checkbox_box.p_visible) { //Checkbox Control
      if (_checkbox_state.p_value) {
         annotationDefs[i.type].fields[i.field].checkbox = 'true';
      } else {
         annotationDefs[i.type].fields[i.field].checkbox = 'false';
      }
   } else if (_date_box.p_visible) { //Date Control
      _str date;
      parse _ddate_label.p_caption with . ': ' date;
      annotationDefs[i.type].fields[i.field].defaultDate = date;
   }
}

void _add_days.on_change ()
{
   if (!isinteger(p_text)) {
      p_text = '0';
      end_line();
   }
}



static void clearFieldFrame ()
{
   _dtext.p_text = '';
   _deditor._lbclear();
   _list_items._TreeDelete(TREE_ROOT_INDEX, 'C');
   _dropdown_items._TreeDelete(TREE_ROOT_INDEX, 'C');
   _checkbox_state.p_value = 0;
   _ddate_label.p_caption = 'Default Date: ';
   _add_days.p_text = '0';
}



/**
 *Put stuff from annotationDefs into the controls
 *
 */
static void updateFieldFrame (AnnotationFieldInfo& field)
{
   int startLine;
   int i;

   switch (field.fieldType) {
   case TEXT_CONTROL_TYPE:
      if (!field.text._isempty()) {
         _dtext.p_text = field.text;
      }
      break;
   case MULTILINE_TEXT_CONTROL_TYPE:
      _deditor._lbclear();
      _deditor.top();
      for (i = 0; i < field.editor._length(); ++i) {
         _deditor.insert_line(field.editor[i]);
      }
      break;
   case LIST_CONTROL_TYPE:
      _list_items._TreeDelete(TREE_ROOT_INDEX, 'C');
      for (i = 0; i < field.list._length(); ++i) {
         _list_items._TreeAddItem(TREE_ROOT_INDEX, field.list[i], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      }
      for (i = 0; i < field.defaultIndices._length(); ++i) {
         index := _list_items._TreeGetIndexFromLineNumber(field.defaultIndices[i] + 1);
         _list_items._TreeSelectLine(index);
      }
      break;
   case DROPDOWN_CONTROL_TYPE:
      _dropdown_items._TreeDelete(TREE_ROOT_INDEX, 'C');
      for (i = 0; i < field.dropdown._length(); ++i) {
         _dropdown_items._TreeAddItem(TREE_ROOT_INDEX, field.dropdown[i], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      }
      if (field.defaultIndices._length() > 0) {
         _dropdown_items._TreeCurLineNumber(field.defaultIndices[0] + 1);
      }
      break;
   case CHECKBOX_CONTROL_TYPE:
      if (field.checkbox == 'true') {
         _checkbox_state.p_value = 1;
      } else {
         _checkbox_state.p_value = 0;
      }
      break;
   case DATE_CONTROL_TYPE:
      if (!field.defaultDate._isempty()) {
         _ddate_label.p_caption = 'Default Date: 'field.defaultDate;
      }
      break;
   }
}



defeventtab _tbannotations_browser_form;
void _tbannotations_browser_form.on_create ()
{
   maybeDisableNewAnnotations();
   _SetDialogInfoHt(SHOW_TYPE, '');
   _annotation_tree._SetDialogInfoHt(ANNOTATION_TREE_SORT_COLUMN, 0, _annotation_tree);
   _annotation_tree._SetDialogInfoHt(ANNOTATION_TREE_CHANGE_NOTE, 1, _annotation_tree);
   _filter_key._SetDialogInfoHt(SKIP_DATE_TIME_FILTER_REFRESH, '', _filter_key);

   // Make a timer that goes off once a minute, and checks to see if the current
   // DateTime filter is out of date.
   int filterKeyTimer = _set_timer(60000, checkDateTimeFiltersFreshness);
   _filter_key._SetDialogInfoHt(FILTER_KEY_TIMER, filterKeyTimer, _filter_key);

   setupTypeList();
   setupFilters();
   showFields(allAnnotations);

   //Restore the positions of the divider bars.
   typeless xpos;
   xpos = _retrieve_value("_tbannotations_browser_form._left_sizebar_x.p_x");
   if (isuinteger(xpos)) {
      _left_sizebar_x.p_x = xpos;
   } else {
      _left_sizebar_x.p_x = 2640;
   }
   xpos = _retrieve_value("_tbannotations_browser_form._right_sizebar_x.p_x");
   if (isuinteger(xpos)) {
      _right_sizebar_x.p_x = xpos;
   } else {
      _right_sizebar_x.p_x = 5880;
   }

   if (annotations._length() > 0) {
      enableNoteOps();
   } else {
      disableNoteOps();
   }
}



boolean AnnotationsHaveFocus ()
{
   if (_get_focus() == _find_formobj('_tbannotations_browser_form', 'n')) {
      return true;
   }
   return false;
}

void _tbannotations_browser_form.on_got_focus()
{
   // update the preview window

   i := _GetDialogInfoHt(CURRENT_NOTE_INDEX, _annotation_tree);
   if (!i._isempty() && isinteger(i) && annotations._length() > i) {
      VS_TAG_BROWSE_INFO cm;
      tag_browse_info_init(cm);
      cm.file_name = annotations[i].marker.sourceFile;
      cm.line_no = annotations[i].marker.origLineNumber;
      cm.type_name = 'annotation';
      cm.member_name = 'annotation 'i+1;
      cb_refresh_output_tab(cm, true, true, false, APF_ANNOTATIONS);
   }
}


static void setupTypeList ()
{
   _type_list._lbclear();
   _type_list._lbadd_item('(Show All)');
   typeless i;
   for (i._makeempty(); ; ) {
      types._nextel(i);
      if (i._isempty()) {
         break;
      }
      _type_list._lbadd_item(i);
   }
   _type_list._lbtop();
   _type_list._lbselect_line();
}



/**
 * Set up the combo box of filters on the annotations tool
 * window.
 */
static void setupFilters()
{
   _filter._lbclear();

   // always have a show all
   _filter._lbadd_item('(Show All)');

   // Type specific fields.
   int nOfFields = activeType.fieldsUsed._length();
   for (i := 0; i < nOfFields; ++i) {
      j := activeType.fieldsUsed[i];
      _filter._lbadd_item(activeType.fields[j].name);
      if (activeType.fields[j].fieldType == DATE_CONTROL_TYPE) {
         _filter._SetDialogInfo(_filter.p_line, AFT_DATETIME);
      } else {
         _filter._SetDialogInfo(_filter.p_line, AFT_OTHER);
      }
   }

   // Generic fields.
   _filter._lbadd_item(AUTHOR_FILTER);
   _filter._SetDialogInfo(_filter.p_line, AFT_GENERIC);

   _filter._lbadd_item(DATE_FILTER);
   _filter._SetDialogInfo(_filter.p_line,AFT_GENERIC);

   _filter._lbadd_item(VERSION_FILTER);
   _filter._SetDialogInfo(_filter.p_line,AFT_GENERIC);

   _filter._lbadd_item(SOURCE_FILE_FILTER);
   _filter._SetDialogInfo(_filter.p_line,AFT_GENERIC);

   _filter._lbadd_item(ANNOTATION_FILE_FILTER);
   _filter._SetDialogInfo(_filter.p_line,AFT_GENERIC);
}



static int getNoteIDX (int treeIDX)
{
   if (treeIDX < 0) return -1;

   _str userInfo = '0';
   _str _strNoteIDX = '0';
   int result = -1;

   userInfo = _annotation_tree._TreeGetUserInfo(treeIDX);
   parse userInfo with .  _strNoteIDX;

   if (isinteger(_strNoteIDX)) {
      result = (int)_strNoteIDX;
   }

   return result;
}



static void showFields (int (&noteIndices)[])
{
   // try and stay on the same annotation
   int saveIDX = _annotation_tree._TreeCurIndex();
   int noteIDX = -1;
   if (saveIDX >= 0) {
      noteIDX = getNoteIDX(saveIDX);
   }
   saveIDX = -1;

   _annotation_tree._SetDialogInfoHt(ANNOTATION_TREE_CHANGE_NOTE, 0, _annotation_tree);
   _annotation_tree._TreeBeginUpdate(TREE_ROOT_INDEX);

   lastAnnotations = noteIndices;
   _annotation_tree._TreeDelete(TREE_ROOT_INDEX, "C");
   int nOfCols = _annotation_tree._TreeGetNumColButtons();
   int i = 0;
   for (i = 0; i < nOfCols; ++i) {
      _annotation_tree._TreeDeleteColButton(0);
   }

// _annotation_tree._TreeSetColButtonInfo(0, 1, TREE_BUTTON_PUSHBUTTON|
//                                        TREE_BUTTON_SORT, 0, 'Status');
   int j = 0;
   int l;
   int nOfFields = activeType.fieldsUsed._length();
   for (i = 0; i < nOfFields; ++i) {
      j = activeType.fieldsUsed[i];
      _annotation_tree._TreeSetColButtonInfo(i, 1, TREE_BUTTON_PUSHBUTTON|
                                             TREE_BUTTON_SORT|TREE_BUTTON_SORT_COLUMN_ONLY, 
                                             0, activeType.fields[j].name);
   }
   _annotation_tree._TreeSetColButtonInfo(i++, 1, TREE_BUTTON_PUSHBUTTON|
                                          TREE_BUTTON_SORT|TREE_BUTTON_SORT_COLUMN_ONLY, 
                                          0, 'Author');
   _annotation_tree._TreeSetColButtonInfo(i++, 1, TREE_BUTTON_PUSHBUTTON|
                                          TREE_BUTTON_SORT_DATE|TREE_BUTTON_SORT_TIME|TREE_BUTTON_SORT_COLUMN_ONLY,
                                          0, 'Date');
   _annotation_tree._TreeSetColButtonInfo(i++, 1, TREE_BUTTON_PUSHBUTTON|
                                          TREE_BUTTON_SORT|TREE_BUTTON_SORT_COLUMN_ONLY, 
                                          0, 'Type');
   _annotation_tree._TreeSetColButtonInfo(i++, 1, TREE_BUTTON_PUSHBUTTON|
                                          TREE_BUTTON_SORT|TREE_BUTTON_SORT_COLUMN_ONLY|
                                          TREE_BUTTON_SORT_NUMBERS, 
                                          0, 'Version');
   _annotation_tree._TreeSetColButtonInfo(i++, 1, TREE_BUTTON_PUSHBUTTON|
                                          TREE_BUTTON_SORT|TREE_BUTTON_SORT_COLUMN_ONLY, 
                                          0, 'Source File');
   _annotation_tree._TreeSetColButtonInfo(i++, 1, TREE_BUTTON_PUSHBUTTON|
                                          TREE_BUTTON_SORT|TREE_BUTTON_SORT_COLUMN_ONLY|
                                          TREE_BUTTON_SORT_NUMBERS, 0,
                                          'Line Number');
   _annotation_tree._TreeSetColButtonInfo(i++, 1, TREE_BUTTON_PUSHBUTTON|
                                          TREE_BUTTON_SORT|TREE_BUTTON_SORT_COLUMN_ONLY, 
                                          0, 'Annotation File');

   _str fieldEntry = '';
   _str row = '';
   int index;
   int itemIndex = 0;
   int k;
   int fieldsCounter;
   int defIdx;
   for (i = 0; i < noteIndices._length(); ++i) {
      j = noteIndices[i];
      if (activeAnnotations._indexin(j)) {
         //row = "\t";
         row = "";
         defIdx = annotationTypes:[lowcase(annotations[j].type)];
         for (fieldsCounter = 0; fieldsCounter < nOfFields; ++fieldsCounter) {
            k = annotationDefs[defIdx].fieldsUsed[fieldsCounter];
            fieldEntry = '';
            switch (annotations[j].fields[k].fieldType) {
            case TEXT_CONTROL_TYPE:
               if (!annotations[j].fields[k].text._isempty()) {
                  fieldEntry = annotations[j].fields[k].text;
               }
               break;
            case DATE_CONTROL_TYPE:
               if (!annotations[j].fields[k].defaultDate._isempty()) {
                  fieldEntry = annotations[j].fields[k].defaultDate;
               }
               break;
            case MULTILINE_TEXT_CONTROL_TYPE:
               if (!annotations[j].fields[k].editor._isempty()) {
                  fieldEntry = '';
                  fieldEntry = annotations[j].fields[k].editor[0];
               }
               break;
            case DROPDOWN_CONTROL_TYPE:
               if (annotations[j].fields[k].defaultIndices._length() > 0) {
                  index = annotations[j].fields[k].defaultIndices[0];
                  fieldEntry = annotations[j].fields[k].dropdown[index];
               }
               break;
            case LIST_CONTROL_TYPE:
               for (l = 0;
                   l < annotations[j].fields[k].defaultIndices._length();
                   ++l) {
                  index = annotations[j].fields[k].defaultIndices[l];
                  fieldEntry =
                  fieldEntry:+annotations[j].fields[k].list[index]", ";
               }
               fieldEntry = substr(fieldEntry, 1, (length(fieldEntry) - 2));
               break;
            case CHECKBOX_CONTROL_TYPE:
               if (annotations[j].fields[k].checkbox == 'true') {
                  fieldEntry = 'true';
               } else {
                  fieldEntry = 'false';
               }
               break;
            }
            row = row:+strip(substr(fieldEntry, 1, ANNOTATION_MAX_FIELD_SIZE_DISPLAYED))"\t";
         }
         row = row:+annotations[j].lastModUser"\t":+
               annotations[j].lastModDate"\t":+
               annotations[j].type"\t":+
               annotations[j].version"\t":+
               stranslate(_strip_filename(annotations[j].marker.sourceFile, "P"),
                          '', '"')"\t":+
               annotations[j].marker.origLineNumber"\t";
         if (annotations[j].noteFile == workspaceSCA) {
            row = row'(Workspace Annotations)';
         } else if (annotations[j].noteFile == projectSCA) {
            row = row'(Project Annotations)';
         } else if (annotations[j].noteFile == personalSCA) {
            row = row'(Personal Annotations)';
         } else {
            row = row:+_strip_filename(annotations[j].noteFile, "P");
         }
         //Note that _TreeAddItem also sets the user info now.
         itemIndex = _annotation_tree._TreeAddItem(TREE_ROOT_INDEX, row,
                                                   TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF,
                                                   0, '0 'j
                                                  );

         if (annotations[j].lastModDate != '') {
            int y, m, d, h, min, s, ms;
            if (annotation_date_parse(annotations[j].lastModDate, y, m, d, h, min)) {
               _annotation_tree._TreeSetDateTime(itemIndex, 1, y, m, d, h, min);
            }
         }

         if (j == noteIDX) {
            
            _annotation_tree._SetDialogInfoHt(CURRENT_NOTE_INDEX, j,
                                              _annotation_tree);
            saveIDX = itemIndex;
         }
      }
   }

   int sortCol = _GetDialogInfoHt(ANNOTATION_TREE_SORT_COLUMN);
   if ( sortCol!=null ) {
      _annotation_tree._TreeSortCol(sortCol);
   }
   _annotation_tree._TreeAdjustColumnWidths(-1);
   _annotation_tree._TreeRefresh();

   _annotation_tree._TreeEndUpdate(TREE_ROOT_INDEX);

   //Set up the default preview.
   int treeIDX = _annotation_tree._TreeCurIndex();
   if (treeIDX >= 0) {
      noteIDX = getNoteIDX(treeIDX);
      if ((noteIDX >= 0) && (annotations._length())) {
         _note_preview.p_text = annotations[noteIDX].preview;
      }
   }

   _annotation_tree._SetDialogInfoHt(ANNOTATION_TREE_CHANGE_NOTE, 1, _annotation_tree);
   if (saveIDX >= 0) {
      _annotation_tree._TreeSetCurIndex(saveIDX);
   }
}



static void enableNoteOps ()
{
   _copy_note.p_enabled = true;
   _modify_note.p_enabled = true;
   _delete_note.p_enabled = true;
   _relocate_note.p_enabled = true;
}



static void disableNoteOps ()
{
   _copy_note.p_enabled = false;
   _modify_note.p_enabled = false;
   _delete_note.p_enabled = false;
   _relocate_note.p_enabled = false;
}



static void maybeDisableNewAnnotations ()
{
   if (_no_child_windows()) {
      _add_note.p_enabled = false;
   } else {
      _add_note.p_enabled = true;
   }
}



static void selectAnnotation (int noteIndex,boolean doSetFocus=true)
{
   int wid = p_window_id;
   p_window_id = _annotation_tree;

   int treeIndex;
   _TreeTop();
   treeIndex = _TreeCurIndex();
   while (getNoteIDX(treeIndex) != noteIndex) {
      if (_TreeDown() != 0) {

         p_window_id = wid;
         return;
      }
      treeIndex = _TreeCurIndex();
   }
   p_window_id = wid;

   if (treeIndex > 0) {
      if (doSetFocus) {
         _annotation_tree._set_focus();
      }
      _annotation_tree._TreeSelectLine(treeIndex);
      _annotation_tree._TreeSetCurIndex(treeIndex);
   }
}



void _tbannotations_browser_form.on_resize ()
{
   int width = _dx2lx(p_active_form.p_xyscale_mode,
                      p_active_form.p_client_width);
   int height = _dy2ly(p_active_form.p_xyscale_mode,
                       p_active_form.p_client_height);

   _type_label.p_x = 60;
   _type_list.p_x = _type_label.p_x;
   _type_list.p_width = _left_sizebar_x.p_x - _type_list.p_x;

   _manage_notes.p_x = width - _manage_notes.p_width - 60;
   _manage_notes.p_y = 60;
   _def_note.p_x = _manage_notes.p_x - _def_note.p_width - 60;
   _def_note.p_y = _manage_notes.p_y;
   _relocate_note.p_x = _def_note.p_x - _relocate_note.p_width - 60;
   _relocate_note.p_y = _manage_notes.p_y;
   _copy_note.p_x = _relocate_note.p_x - _copy_note.p_width - 60;
   _copy_note.p_y = _manage_notes.p_y;
   _modify_note.p_x = _copy_note.p_x - _modify_note.p_width - 60;
   _modify_note.p_y = _manage_notes.p_y;
   _delete_note.p_x = _modify_note.p_x - _delete_note.p_width - 60;
   _delete_note.p_y = _manage_notes.p_y;
   _add_note.p_x = _delete_note.p_x - _add_note.p_width - 60;
   _add_note.p_y = _manage_notes.p_y;
   _manage_filters.p_x = _add_note.p_x - _manage_filters.p_width - 60;
   _manage_filters.p_y = _manage_notes.p_y;

   int essentialWidths = _type_list.p_width + _manage_notes.p_width*7 +
                         _filter_label.p_width + _filter_key_label.p_width + 1500;

   if (width < essentialWidths) {
      _filter_label.p_visible = false;
      _filter.p_visible = false;
      _filter_key_label.p_visible = false;
      _filter_key.p_visible = false;
   } else {
      _filter_label.p_visible = true;
      _filter.p_visible = true;
      _filter_key_label.p_visible = true;
      _filter_key.p_visible = true;

      _filter_label.p_x = _type_list.p_x + _type_list.p_width + 40;
      int fWidth = _manage_filters.p_x - _filter_label.p_x -
                   _filter_label.p_width - _filter_key_label.p_width - 160;

      _filter.p_width = fWidth / 2;
      _filter_key.p_width = _filter.p_width;

      _filter.p_x = _filter_label.p_x + _filter_label.p_width + 40;
      _filter.p_y = 60;
      _filter_label.p_y = _filter.p_y +
                          (_filter.p_height - _filter_label.p_height)/2;
      _filter_key_label.p_x = _filter.p_x + _filter.p_width + 40;
      _filter_key.p_x = _filter_key_label.p_x + _filter_key_label.p_width + 40;
      _filter_key.p_y = 60;
      _filter_key_label.p_y = _filter.p_y +
                              (_filter.p_height - _filter_label.p_height)/2;
   }

   _type_label.p_y = _filter_label.p_y;

   int filtersHeight = _filter.p_y + _filter.p_height + 40;
   int buttonsHeight = _manage_filters.p_y + _manage_filters.p_height + 40;
   if (filtersHeight >= buttonsHeight) {
      _type_list.p_y = filtersHeight;
   } else {
      _type_list.p_y = buttonsHeight;
   }

   _type_list.p_height = height - 180 - _filter.p_height;
   _left_sizebar_x.p_y = _type_list.p_y;
   _left_sizebar_x.p_height = _type_list.p_height;

   _annotation_tree.p_x = _filter_label.p_x;
   _annotation_tree.p_y = _type_list.p_y;
   _annotation_tree.p_width = _right_sizebar_x.p_x - _annotation_tree.p_x;
   _annotation_tree.p_height = _type_list.p_height;

   _right_sizebar_x.p_y = _type_list.p_y;
   _right_sizebar_x.p_height = _type_list.p_height;

   _note_preview.p_x = _annotation_tree.p_x + _annotation_tree.p_width + 40;
   _note_preview.p_width = width - _note_preview.p_x - 40;
   _note_preview.p_y = _annotation_tree.p_y;
   _note_preview.p_height = _annotation_tree.p_height;
}



void _tbannotations_browser_form.on_destroy ()
{
   int filterKeyTimer;
   filterKeyTimer = _filter_key._GetDialogInfoHt(FILTER_KEY_TIMER, _filter_key);
   if ((filterKeyTimer != null) &&
       (filterKeyTimer > -1) &&
       _timer_is_valid(filterKeyTimer)) {
      _kill_timer(filterKeyTimer);
   }
   //Save the position of the divider bars.
   _append_retrieve(0, _left_sizebar_x.p_x,
                    "_tbannotations_browser_form._left_sizebar_x.p_x");
   _append_retrieve(0, _right_sizebar_x.p_x,
                    "_tbannotations_browser_form._right_sizebar_x.p_x");

   //Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id, ON_DESTROY, '2');
}



void _left_sizebar_x.lbutton_down()
{
   _ul2_image_sizebar_handler(_type_list.p_x + 80,
                              _annotation_tree.p_x +
                              _annotation_tree.p_width);
}



void _right_sizebar_x.lbutton_down()
{
   _ul2_image_sizebar_handler(_annotation_tree.p_x + 80,
                              _note_preview.p_x +
                              _note_preview.p_width);
}



void _tbannotations_browser_form.esc ()
{
   exportAllAnnotations();
   // Call default tool window ESC handler in order to do the right thing
   _tbDismiss(p_active_form);
}



static void updateFilterKey (int (&keys):[][])
{
   _filter_key._lbclear();
   typeless i;
   int j;
   int nOfEntries;
   for (i._makeempty(); ; ) {
      keys._nextel(i);
      if (i._isempty()) {
         break;
      }
      nOfEntries = keys:[i]._length();
      for (j = 0; j < nOfEntries; ++j) {
         if (activeAnnotations._indexin(keys:[i][j])) {
            _filter_key._lbadd_item(i);
            break;
         }
      }
   }
   _filter_key._lbtop();
   if (_filter.p_text == '(Show All)') {
      _filter_key.p_text = '(No Column Selected)';
   } else {
      _filter_key.p_text = _filter_key._lbget_text();
   }
}



/**
 * Special case updateFilterKey() to handle special annotation 
 * file names and shorten all other filenames.
 */
static void updateAnnotationFileFilterKey ()
{
   _filter_key._lbclear();
   typeless i;
   int j;
   int nOfEntries;
   for (i._makeempty(); ; ) {
      shortNoteFiles._nextel(i);
      if (i._isempty()) {
         break;
      }
      nOfEntries = shortNoteFiles:[i]._length();
      for (j = 0; j < nOfEntries; ++j) {
         if (activeAnnotations._indexin(shortNoteFiles:[i][j])) {
            _filter_key._lbadd_item(i);
            break;
         }
      }
   }
   _filter_key._lbtop();
   _filter_key.p_text = _filter_key._lbget_text();
}



/**
 * Special case updateFilterKey() to shorten file names.
 */
static void updateSourceFileFilterKey ()
{
   _filter_key._lbclear();
   typeless i;
   int j;
   int nOfEntries;
   for (i._makeempty(); ; ) {
      shortSourceFiles._nextel(i);
      if (i._isempty()) {
         break;
      }
      nOfEntries = shortSourceFiles:[i]._length();
      for (j = 0; j < nOfEntries; ++j) {
         if (activeAnnotations._indexin(shortSourceFiles:[i][j])) {
            _filter_key._lbadd_item(i);
            break;
         }
      }
   }
   _filter_key._lbtop();
   _filter_key.p_text = _filter_key._lbget_text();
}



static boolean getDateTimeFilters (_str previousFilter='')
{
   se.datetime.DateTimeInterval (*dtFilters):[];
   se.datetime.get_DateTimeFilters(dtFilters);

   boolean prevFilterInActiveList = false;

   _filter_key._lbclear();

   int i = 0;
   foreach (auto o in (*dtFilters)) {
      if (o.m_activeFilterLists._indexin(ANNOTATION_DATETIME_FILTERS) &&
          o.m_activeFilterLists:[ANNOTATION_DATETIME_FILTERS]) {
         _str filterName = o.getHashKey();
         _filter_key._lbadd_item(filterName);
         if (previousFilter == filterName) {
            prevFilterInActiveList = true;
         }
      }
   }
   _filter_key._lbsort('i');
   _filter_key._lbtop();
   _filter_key.p_text = _filter_key._lbget_text();

   return prevFilterInActiveList;
}



static void buildCustomFields (_str fieldName)
{
   customFields._makeempty();

   _str type = '';
   type = _GetDialogInfoHt(SHOW_TYPE);
   if (type._isempty() || (type == '')) {
      return;
   }
   _str content;
   int i;
   int j;
   int k;
   int noteCount = types:[lowcase(type)]._length();
   int fieldCount;

   for (i = 0; i < noteCount; ++i) {
      j = types:[lowcase(type)][i];
      fieldCount = annotations[j].fields._length();
      for (k = 0; k < fieldCount; ++k) {
         if (annotations[j].fields[k].name == fieldName) {
            switch (annotations[j].fields[k].fieldType) {
            case TEXT_CONTROL_TYPE:
               content = annotations[j].fields[k].text;
               break;
            case DATE_CONTROL_TYPE:
               content = annotations[j].fields[k].defaultDate;
               break;
            case MULTILINE_TEXT_CONTROL_TYPE:
               content = annotations[j].fields[k].editor[0];
               break;
            case DROPDOWN_CONTROL_TYPE:
               content = annotations[j].fields[k].dropdown[0];
               break;
            case LIST_CONTROL_TYPE:
               content = annotations[j].fields[k].list[0];
               break;
            case CHECKBOX_CONTROL_TYPE:
               content = annotations[j].fields[k].checkbox;
               break;
            }
            customFields:[content][customFields:[content]._length()] = j;
         }
      }
   }
}


void filterAnnotations (int (&filteredAnnotations)[])
{
   _str type = _GetDialogInfoHt(SHOW_TYPE);
   if (type._isempty() || (type == '')) {
      return;
   }

   DateTimeInterval (*dtFilters):[];
   get_DateTimeFilters(dtFilters);
   if (!(*dtFilters)._indexin(_filter_key.p_text)) {
      return;
   }
   (*dtFilters):[_filter_key.p_text].update();
   DateTimeInterval currentFilter = (*dtFilters):[_filter_key.p_text];

   _str fieldName = _filter.p_text;

   _str yyyy, mm, dd;
   int i;
   int j;
   int k;
   int noteCount = types:[lowcase(type)]._length();
   int fieldCount;
   for (i = 0; i < noteCount; ++i) {
      j = types:[lowcase(type)][i];
      fieldCount = annotations[j].fields._length();
      for (k = 0; k < fieldCount; ++k) {
         if (annotations[j].fields[k].name == fieldName) {
            parse annotations[j].fields[k].defaultDate with yyyy '-' mm '-' dd;
            DateTime tmpDate((int)yyyy, (int)mm, (int)dd);
            if (currentFilter.filter(tmpDate)) {
               filteredAnnotations[filteredAnnotations._length()] = j;
            }
         }
      }
   }
}



void _filter.on_change (int reason)
{
   switch (p_text) {
   case '(Show All)':
      updateFilterKey(null);
      _str type = _GetDialogInfoHt(SHOW_TYPE);
      if (type._isempty() || (type == '')) {
         showFields(allAnnotations);
      } else {
         showFields(types:[type]);
      }
      break;
   case ANNOTATION_FILE_FILTER:
      updateAnnotationFileFilterKey();
      break;
   case SOURCE_FILE_FILTER:
      updateSourceFileFilterKey();
      break;
   case AUTHOR_FILTER:
      updateFilterKey(authors);
      break;
   case DATE_FILTER:
      updateFilterKey(dates);
      break;
   case VERSION_FILTER:
      updateFilterKey(versions);
      break;
   default:
      if ((_filter.p_line != null) &&
          (_filter._GetDialogInfo(_filter.p_line) == AFT_DATETIME)) {
         getDateTimeFilters();
      } else {
         buildCustomFields(p_text);
         updateFilterKey(customFields);
      }
      break;
   }
}



void _filter_key.on_change (int reason)
{
   switch (_filter.p_text) {
   case ANNOTATION_FILE_FILTER:
      showFields(shortNoteFiles:[p_text]);
      break;
   case SOURCE_FILE_FILTER:
      showFields(shortSourceFiles:[p_text]);
      break;
   case AUTHOR_FILTER:
      showFields(authors:[p_text]);
      break;
   case DATE_FILTER:
      showFields(dates:[p_text]);
      break;
   case VERSION_FILTER:
      showFields(versions:[p_text]);
      break;
   default:
      if ((_filter.p_line != null) &&
          (_filter._GetDialogInfo(_filter.p_line) == AFT_DATETIME)) {
         _str sRDTF = _filter_key._GetDialogInfoHt(SKIP_DATE_TIME_FILTER_REFRESH,
                                                   _filter_key);
         if (sRDTF != 'Yes') {
            int filteredAnnotations[];
            filterAnnotations(filteredAnnotations);
            showFields(filteredAnnotations);
         } else {
            _filter_key._SetDialogInfoHt(SKIP_DATE_TIME_FILTER_REFRESH, '',
                                         _filter_key);
         }
      } else {
         showFields(customFields:[p_text]);
      }
      break;
   }
}


static void checkDateTimeFiltersFreshness ()
{
   // Find the _filter control, so we can determine if we're even filtering
   // DateTimes.
   int fWID = _find_object('_tbannotations_browser_form._filter', 'n');
   if ((fWID > 0) &&
       _iswindow_valid(fWID) &&
       (fWID._GetDialogInfo(fWID.p_line) == AFT_DATETIME)) {

      // Find the _filter_key control so we can find the proper filter to check.
      int fkWID = _find_object('_tbannotations_browser_form._filter_key', 'n');
      if ((fWID > 0) &&
          _iswindow_valid(fWID)) {
         _str sRDTF = fkWID._GetDialogInfoHt(SKIP_DATE_TIME_FILTER_REFRESH,
                                             fkWID);
         if (sRDTF != 'Yes') {
            _str newText;
            parse fkWID.p_text with newText ' (out of date)';            
            if ((newText :== fkWID.p_text) &&
                (g_autoDateTimeIntervals._indexin(newText))) {
               DateTimeInterval (*dtFilters):[];
               get_DateTimeFilters(dtFilters);
               DateTime now;
               DateTimeInterval currentFilter = (*dtFilters):[newText];
               if (!currentFilter.filter(now)) {
                  fkWID._SetDialogInfoHt(SKIP_DATE_TIME_FILTER_REFRESH, 'Yes',
                                         fkWID);
                  fkWID.p_text = newText' (Out of date. Reapply to refresh.)';
               }
            }
         }
      }
   }
}



/**
 * Selects an entry in _annotation_tree. The entry to select is in 
 * CurrentNoteIDX.  If that entry is not found, then we select the top item. 
 */
void selectNote ()
{
   CurrentNoteIDX := _GetDialogInfoHt(CURRENT_NOTE_INDEX, _annotation_tree);

   if (!CurrentNoteIDX._isempty() && isinteger(CurrentNoteIDX)) {
      treeIDX := _annotation_tree._TreeSearch(TREE_ROOT_INDEX, '', '', "0 "CurrentNoteIDX);

      if (treeIDX >= 0) {
         _annotation_tree._TreeSetCurIndex(treeIDX);
         _annotation_tree._TreeSelectLine(treeIDX);
         _annotation_tree.call_event(CHANGE_SELECTED, treeIDX, _annotation_tree, ON_CHANGE, 'W');
         return;
      }
   }

   // just select the top thing if we didn't come up with anything better
   _annotation_tree._TreeTop();
   _annotation_tree.call_event(CHANGE_SELECTED, _annotation_tree._TreeCurIndex(), _annotation_tree, ON_CHANGE, 'W');
}



void _type_list.on_change (int reason)
{
   _str type;
   int startLine = p_line;
   int i;
   rehashNoteIDs();
   activeAnnotations._makeempty();

   _SetDialogInfoHt(SHOW_TYPE, '');

   _lbtop();
   _lbup();
   while (!_lbdown()) {
      if (_lbisline_selected()) {
         type = _lbget_text();
         if (type == '(Show All)') { //Show everything, abort.
            for (i = 0; i < allAnnotations._length(); ++i) {
               activeAnnotations:[allAnnotations[i]] = allAnnotations[i];
            }
            p_line = startLine;
            _SetDialogInfoHt(SHOW_TYPE, '');
            showFields(allAnnotations);
            setupFilters();
            selectNote();
            return;
         }
         for (i = 0; i < types:[lowcase(type)]._length(); ++i) {
            activeAnnotations:[types:[lowcase(type)][i]] =
            types:[lowcase(type)][i];
         }
      }
   }
   p_line = startLine;

   //Nothing is selected, show everything.
   if (p_Nofselected == 0) {
      _SetDialogInfoHt(SHOW_TYPE, '');
      showFields(allAnnotations);
      setupFilters();
      selectNote();
      for (i = 0; i < allAnnotations._length(); ++i) {
         activeAnnotations:[allAnnotations[i]] = allAnnotations[i];
      }
      return;
   }

   //Show one type, add its fields to filters.
   if (p_Nofselected == 1) {
      _SetDialogInfoHt(SHOW_TYPE, lowcase(type));
      activeType = annotationDefs[annotationTypes:[lowcase(type)]];
      showFields(types:[lowcase(type)]);
      setupFilters();
      selectNote();
      return;
   }

   //Show more than one type, have to keep filters and fields generic.
   //setupGeneralFilters();
   showFields(allAnnotations);
   selectNote();
}



void _annotation_tree.rbutton_down ()
{
   int x = mou_last_x();
   int y = mou_last_y();
   int idx = _TreeGetIndexFromPoint(x, y, 'P');

   if (idx >= 0) {
      _TreeSetCurIndex(idx);
   }
}



void _annotation_tree.rbutton_up ()
{
   _str menuName = '_annotation_tree_menu';
   int idx = find_index(menuName, oi2type(OI_MENU));
   if (!idx) {
      return;
   }

   int mh = p_active_form._menu_load(idx, 'P');
   if (mh < 0) {
      _message_box('Unable to load menu: "':+menuName:+'"',"",
                   MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   int x = VSDEFAULT_INITIAL_MENU_OFFSET_X;
   int y = VSDEFAULT_INITIAL_MENU_OFFSET_Y;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   int status = _menu_show(mh,flags,x,y);
   _menu_destroy(mh);
}



void _annotation_tree.on_change (int reason, int index, int col=-1)
{
   int i;

   switch (reason) {
   case CHANGE_BUTTON_PRESS:
      _SetDialogInfoHt(ANNOTATION_TREE_SORT_COLUMN, col);
      break;
   case CHANGE_SELECTED:
      i = getNoteIDX(index);
      if (i < 0) {
         break;
      }

      if (i >= 0) {
         _annotation_tree._SetDialogInfoHt(CURRENT_NOTE_INDEX, i,
                                           _annotation_tree);
         if (annotations[i].marker.sourceFile != maybe_quote_filename(_mdi.p_child.p_buf_name)) {
            _relocate_note.p_enabled = false;
            _relocate_note.p_message = '';
         } else {
            _relocate_note.p_enabled = true;
            _relocate_note.p_message = 'Relocate Annotation to Cursor';
         }
         _note_preview.p_text = annotations[i].preview;

         //Show code location in Preview window.
         VS_TAG_BROWSE_INFO cm;
         tag_browse_info_init(cm);
         cm.file_name = annotations[i].marker.sourceFile;
         cm.line_no = annotations[i].marker.origLineNumber;
         cm.type_name = 'annotation';
         cm.member_name = 'annotation 'i+1;
         cb_refresh_output_tab(cm, true, true, false, APF_ANNOTATIONS);
      }
      break;
   case CHANGE_LEAF_ENTER:
      i = getNoteIDX(index);
      if (i < 0) {
         break;
      }

      _str sourceFile = maybe_quote_filename(annotations[i].marker.sourceFile);

      if (file_match('-P +HRS 'sourceFile, 1) == '') {
         //File doesn't exist. Pop up a notification to let the user know.
         _message_box('Could not find 'sourceFile, 'Warning');
         break;
      }

      int twid;
      get_window_id(twid);
      edit(sourceFile, EDIT_DEFAULT_FLAGS);
      activate_window(twid);

      VSLINEMARKERINFO info;
      if (!_LineMarkerGet(annotations[i].lineMarker, info)) {
         _mdi.p_child.p_RLine = info.LineNum;
         //Update to new line info, if needed.
         if (annotations[i].marker.origLineNumber != _mdi.p_child.p_RLine) {
            _mdi.p_child._BuildRelocatableMarker(annotations[i].marker,
                                                 RELOC_MARKER_WINDOW_SIZE);
            int wid = _find_formobj('_tbannotations_browser_form', 'n');
            if ((wid > 0) && _iswindow_valid(wid)) {
               wid.showFields(lastAnnotations);
            }
         }
      } else {
         _mdi.p_child.p_RLine = annotations[i].marker.origLineNumber;
         _TreeSetCurIndex(index);
      }

      break;
   }
}



static void goToAnnotation ()
{
   _annotation_tree.call_event(CHANGE_LEAF_ENTER,
                               _annotation_tree._TreeCurIndex(), 0,
                               _annotation_tree, ON_CHANGE, 'w');
}
static void copyAnnotation ()
{
   _copy_note.call_event(_copy_note, LBUTTON_UP, 'w');
}
static void deleteAnnotation ()
{
   _delete_note.call_event(_delete_note, LBUTTON_UP, 'w');
}
static void editAnnotation ()
{
   _modify_note.call_event(_modify_note, LBUTTON_UP, 'w');
}



void _manage_filters.lbutton_up ()
{
   _mdi.show('-xy -modal _DateTimeFilters_manager_form', 'Code Annotations', false);
   if ((_filter.p_line != null) &&
       (_filter._GetDialogInfo(_filter.p_line) == AFT_DATETIME)) {
      _str prevFilter = _filter_key.p_text;
      if (getDateTimeFilters(prevFilter)) {
         _filter_key.p_text = prevFilter;
      }
   }
}



void _manage_notes.lbutton_up ()
{
   _mdi.show('-xy -modal _annotation_files_form');
}



void _def_note.lbutton_up ()
{
   _mdi.show('-xy -modal _annotations_definitions_form');
}



void _relocate_note.lbutton_up ()
{
   //Find the proper annotation.
   int index = _annotation_tree._TreeCurIndex();
   if (index <= 0) {
      return;
   }
   int i = getNoteIDX(index);
   if (i < 0) {
      return;
   }

   //Move the line marker to the cursor's line.
   _LineMarkerRemove(annotations[i].lineMarker);
   _str noteMessage = '';
   int typeLength = length(annotations[i].type);
   strappend(noteMessage, '<code>'annotations[i].type'</code><br>');
   strappend(noteMessage, center('', typeLength, '-')'<br>');
   strappend(noteMessage, annotations[i].preview);
   int j = _LineMarkerAdd(_mdi.p_child, _mdi.p_child.p_RLine, 0, 0,
                          annotationPic, noteMarkerType,
                          noteMessage);
   annotations[i].lineMarker = j;
   lineMarkers:[j] = i;

   //Rebuild the relocatable code marker
   _mdi.p_child._BuildRelocatableMarker(annotations[i].marker,
                                        RELOC_MARKER_WINDOW_SIZE);

   //Update the annotation browser
   updateAnnotationsBrowser(lastAnnotations);

   //Save, with the new relocatable code marker information.
   exportAnnotations(annotations[i].noteFile);
}



void _add_note.lbutton_up ()
{
   //Don't allow users to annotate unsaved files, it just causes problems later.
   if (_mdi.p_child.p_buf_name == '') {
      _message_box('Please save the buffer before adding annotations', 'Warning');
      return;
   }

   _str _note_preview_save = _note_preview.p_text;
   typeless result = _mdi.show('-xy -modal _new_annotation_form');
   if (result == -1) {
      _note_preview.p_text = _note_preview_save;
   }
}



void _copy_note.lbutton_up ()
{
   int index = _annotation_tree._TreeCurIndex();
   if (index <= 0) {
      return;
   }
   int j = getNoteIDX(index);
   if (j < 0) {
      return;
   }

   int i = 0;
   if (!annotations._isempty()) {
      i = annotations._length();
   }

   annotations[i].type = annotations[j].type;
   annotations[i].author = annotation_username();
   annotations[i].creationDate = annotation_date();
   annotations[i].lastModUser = annotations[i].author;
   annotations[i].lastModDate = annotations[i].creationDate;
   annotations[i].noteDefVersion = "";
   annotations[i].version = "1";
   annotations[i].noteFile = annotations[j].noteFile;
   annotations[i].marker = annotations[j].marker;
   annotations[i].fields = annotations[j].fields;
   annotations[i].preview = annotations[j].preview;
   int wid = window_match(stranslate(annotations[i].marker.sourceFile, '', '"'), 1, 'x');
   if (wid == 0) {
      annotations[i].lineMarker = -1;
   } else {
      int lmIndex;
      _str noteMessage = '';
      int typeLength = length(annotations[i].type);
      strappend(noteMessage, '<code>'annotations[i].type'</code><br>');
      strappend(noteMessage, center('', typeLength, '-')'<br>');
      strappend(noteMessage, annotations[i].preview);
      lmIndex = _LineMarkerAdd(wid, annotations[i].marker.origLineNumber, 0, 0,
                               annotationPic, noteMarkerType,
                               noteMessage);
      annotations[i].lineMarker = lmIndex;
      lineMarkers:[lmIndex] = i;
   }

   //Save new copy.
   _str noteFile = annotations[i].noteFile;
   int typeIndex = annotationTypes:[lowcase(annotations[i].type)];
   annotationDefs[typeIndex].noteFiles:[noteFile] = noteFile;
   exportAnnotations(noteFile);

   //Add the new annotation index to all the cross-referencing info.
   _str shortNoteFile;
   _str shortSourceFile;
   _str date;
   allAnnotations[i] = i;
   activeAnnotations:[i] = i;
   authors:[annotations[i].lastModUser][authors:[annotations[i].lastModUser]._length()] = i;
   parse annotations[i].lastModDate with date " " . ;
   dates:[date][dates:[date]._length()] = i;
   noteFiles:[maybe_quote_filename(annotations[i].noteFile)][noteFiles:[maybe_quote_filename(annotations[i].noteFile)]._length()] = i;
   sourceFiles:[maybe_quote_filename(annotations[i].marker.sourceFile)][sourceFiles:[maybe_quote_filename(annotations[i].marker.sourceFile)]._length()] = i;

   if (annotations[i].noteFile == workspaceSCA) {
      shortNoteFile = '(Workspace Annotations)';
   } else if (annotations[i].noteFile == projectSCA) {
      shortNoteFile = '(Project Annotations)';
   } else if (annotations[i].noteFile == personalSCA) {
      shortNoteFile = '(Personal Annotations)';
   } else {
      shortNoteFile = _strip_filename(annotations[i].noteFile, "P");
   }
   shortNoteFile = maybe_quote_filename(shortNoteFile);
   shortNoteFiles:[shortNoteFile][shortNoteFiles:[shortNoteFile]._length()] = i;

   shortSourceFile = maybe_quote_filename(_strip_filename(annotations[i].marker.sourceFile, "P"));
   shortSourceFiles:[shortSourceFile][shortSourceFiles:[shortSourceFile]._length()] = i;

   types:[lowcase(annotations[i].type)][types:[annotations[i].type]._length()] = i;
   versions:[annotations[i].version][versions:[annotations[i].version]._length()] = i;

   updateAnnotationsBrowser(allAnnotations);
}



void _modify_note.lbutton_up ()
{
   int index = _annotation_tree._TreeCurIndex();
   if (index <= 0) {
      return;
   }
   int i = getNoteIDX(index);
   if ((i >= 0) && (annotations._length())) {
      _mdi.show('-xy -modal _annotation_editor_form', annotations[i].type,
                annotations[i].noteFile, i);
   }
}



void _delete_note.lbutton_up ()
{
   _note_preview.p_text = '';

   int index = _annotation_tree._TreeCurIndex();
   if (index <= 0) {
      return;
   }

   int i = getNoteIDX(index);
   if (i < 0) {
      return;
   }
   _annotation_tree._TreeUp();
   _annotation_tree._TreeDelete(index);
   _annotation_tree._SetDialogInfoHt(CURRENT_NOTE_INDEX, i,
                                     _annotation_tree);

   if (annotations[i].lineMarker >= 0) {
      _LineMarkerRemove(annotations[i].lineMarker);
   }
   _str noteFile = annotations[i].noteFile;
   _str noteType = annotations[i].type;
   annotations._deleteel(i);
   //After deleting an element we need to rebuild a list of the currently
   //filtered annotations to show, which is what _type_list.on_change() does.

   //save the filter settings.
   _str filter = _filter.p_text;
   _str filterKey = _filter_key.p_text;

   _type_list.call_event(CHANGE_OTHER, _type_list, ON_CHANGE, 'w');

   //restore the filter settings.
   if (!_filter._lbfind_and_select_item(filter)) {
      _filter_key._lbfind_and_select_item(filterKey);
   }

   //If the last note of a type is removed, rebuild the type list.
   if (!types._indexin(lowcase(noteType))) {
      setupTypeList();
   }
   exportAnnotations(noteFile);

   if (annotations._length() == 0) {
      disableNoteOps();
   }
}



static void clear_annotation ()
{
   int annotationID = _find_control("_annotation");

   while (annotationID.p_child) {
      annotationID.p_child._delete_window();
   }
}



defeventtab _new_annotation_form;
void _new_annotation_form.on_create ()
{
   int widestEntry = 0;
   int entryWidth = 0;
   int i;
   boolean freshestExists = false;


   //If this is the first invocation of SE ever, there was no ANNOTATIONS
   //entry in vrestore.slk to trigger _srg_annotations. We need to import all
   //the annotations in that case.
   if (annotationDefs._isempty()) {
      importAllAnnotations();
   }

   //Populate the Annotation Type list box.
   if (!annotationDefs._isempty()) {
      //for (i = 0; i < annotationDefs._length(); ++i) {
      for (i = 0; i < defTypes._length(); ++i) {
         _type_combo._lbadd_item(defTypes[i]);
         entryWidth = _text_width(defTypes[i]);
         if (entryWidth > widestEntry) {
            widestEntry = entryWidth;
         }
      }
   }
   _type_combo._lbtop();
   _type_combo.p_text = _type_combo._lbget_text();

   //Disallow storing annotations in the project/workspace .SCA file if the
   //file being annotated isn't in the project/workspace.
   _str currentBuffer = _mdi.p_child.p_buf_name;
   //Populate the Annotation File list box.
   _str SCAFileName = '';
   if (!annotationDefs._isempty()) {
      for (i = 0; i < defFiles._length(); ++i) {
         SCAFileName = SCAFiles:[defFiles[i]];
         if ((SCAFileName == '(Workspace Annotations)') &&
             !_FileExistsInCurrentWorkspace(currentBuffer)) {
            continue;
         } else if ((SCAFileName == '(Project Annotations)') &&
                    !_FileExistsInCurrentProject(currentBuffer)) {
            continue;
         }

         if (!SCAFileName._isempty()) {
            _file_combo._lbadd_item(SCAFileName);
            entryWidth = _text_width(defFiles[i]);
            if (entryWidth > widestEntry) {
               widestEntry = entryWidth;
            }
         }
      }
   }
   _file_combo._lbtop();
   _file_combo.p_text = _file_combo._lbget_text();

   //widestEntry = widestEntry + 500;
   if (widestEntry < 1400) {
      widestEntry = 1400;
   }

   int width = _dx2lx(p_active_form.p_xyscale_mode, p_active_form.p_client_width);
   int height = _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);

   _type_label.p_x = 60;
   _type_combo.p_x = _type_label.p_x + _type_label.p_width;
   _type_combo.p_y = 60;
   _type_label.p_y = 60 + (_type_combo.p_height - _type_label.p_height)/2;
   _type_combo.p_width = widestEntry + 500;

   _file_label.p_x = 60;
   _file_combo.p_x = _type_combo.p_x;
   _file_combo.p_y = _type_combo.p_y + _type_combo.p_height + 60;
   _file_label.p_y = _file_combo.p_y + (_file_combo.p_height -
                                        _file_label.p_height)/2;
   _file_combo.p_width = widestEntry + 500;

   _cancel.p_x = _file_combo.p_x + _file_combo.p_width - _cancel.p_width;
   _cancel.p_y = _file_combo.p_y + _file_combo.p_height + 60;
   _okay.p_x = _cancel.p_x - 60 - _cancel.p_width;
   _okay.p_y = _cancel.p_y;

   p_width = _file_combo.p_x + _file_combo.p_width + 120;
}



void _new_annotation_form.esc ()
{
   p_active_form._delete_window(-1);
}



static void sortTypes ()
{
   if (freshestType == '') {
      return;
   }
   int i;
   //Find the entry of the last chosen type ...
   for (i = (defTypes._length() - 1); i >=0; --i) {
      if (defTypes[i] == freshestType) {
         break;
      }
   }
   //... bubble it up to the top.
   for (; i > 0; --i) {
      defTypes[i] = defTypes[i-1];
   }
   defTypes[0] = freshestType;
}



static void sortSCAFiles ()
{
   _str actualFreshestFile = '';
   switch (freshestFile) {
   case '(Workspace Annotations)':
      actualFreshestFile = workspaceSCA;
      break;
   case '(Project Annotations)':
      actualFreshestFile = projectSCA;
      break;
   case '(Personal Annotations)':
      actualFreshestFile = personalSCA;
      break;
   case '':
      actualFreshestFile = defFiles[0];
      break;
   default:
      actualFreshestFile = freshestFile;
      break;
   }

   int i;
   //Find the entry of the last chosen SCA file ...
   for (i = (defFiles._length() - 1); i >=0; --i) {
      if (defFiles[i] == actualFreshestFile) {
         break;
      }
   }
   //... bubble it up to the top.
   for (; i > 0; --i) {
      defFiles[i] = defFiles[i-1];
   }

   defFiles[0] = actualFreshestFile;
}



int _okay.lbutton_up ()
{
   freshestType = _type_combo.p_text;
   _str fType = freshestType;
   //sortTypes();
   freshestFile = _file_combo.p_text;
   _str fFile = freshestFile;
   //sortSCAFiles();


   //Get the actual annotation file's name
   _str newNoteFile;
   if (_file_combo.p_text == '(Workspace Annotations)') {
      newNoteFile = workspaceSCA;
   } else if (_file_combo.p_text == '(Project Annotations)') {
      newNoteFile = projectSCA;
   } else if (_file_combo.p_text == '(Personal Annotations)') {
      newNoteFile = personalSCA;
   } else {
      newNoteFile = _file_combo.p_text;
   }

   p_active_form._delete_window(1);

   int i = 0;
   if (!annotations._isempty()) {
      i = annotations._length();
   }
   annotations[i].type = lowcase(freshestType);
   annotations[i].author = annotation_username();
   annotations[i].creationDate = annotation_date();
   annotations[i].lastModUser = annotations[i].author;
   annotations[i].lastModDate = annotations[i].creationDate;
   annotations[i].noteDefVersion = "";
   annotations[i].version = "0";
   _mdi.p_child._BuildRelocatableMarker(annotations[i].marker,
                                        RELOC_MARKER_WINDOW_SIZE);
   annotations[i].noteFile = maybe_quote_filename(newNoteFile);
   annotations[i].fields = 
   annotationDefs[annotationTypes:[lowcase(freshestType)]].fields;

   //Mark the new annotation with the annotation gutter icon.
   makeAnnotationCaption(annotations[i]);
   int lmIndex;
   _str noteMessage = '';
   int typeLength = length(annotations[i].type);
   strappend(noteMessage, '<code>'annotations[i].type'</code><br>');
   strappend(noteMessage, center('', typeLength, '-')'<br>');
   strappend(noteMessage, annotations[i].preview);
   lmIndex = _LineMarkerAdd(_mdi.p_child, _mdi.p_child.p_RLine, 0, 0,
                            annotationPic, noteMarkerType,
                            noteMessage);
   annotations[i].lineMarker = lmIndex;
   lineMarkers:[lmIndex] = i;

   //Add the new annotation index to all the cross-referencing info.
   _str shortNoteFile;
   _str shortSourceFile;
   _str date;
   allAnnotations[i] = i;
   activeAnnotations:[i] = i;
   authors:[annotations[i].lastModUser][authors:[annotations[i].lastModUser]._length()] = i;
   parse annotations[i].lastModDate with date " " . ;
   dates:[date][dates:[date]._length()] = i;
   noteFiles:[maybe_quote_filename(annotations[i].noteFile)][noteFiles:[maybe_quote_filename(annotations[i].noteFile)]._length()] = i;
   sourceFiles:[maybe_quote_filename(annotations[i].marker.sourceFile)][sourceFiles:[maybe_quote_filename(annotations[i].marker.sourceFile)]._length()] = i;

   if (annotations[i].noteFile == workspaceSCA) {
      shortNoteFile = '(Workspace Annotations)';
   } else if (annotations[i].noteFile == projectSCA) {
      shortNoteFile = '(Project Annotations)';
   } else if (annotations[i].noteFile == personalSCA) {
      shortNoteFile = '(Personal Annotations)';
   } else {
      shortNoteFile = _strip_filename(annotations[i].noteFile, "P");
   }
   shortNoteFile = maybe_quote_filename(shortNoteFile);
   shortNoteFiles:[shortNoteFile][shortNoteFiles:[shortNoteFile]._length()] = i;

   shortSourceFile = maybe_quote_filename(_strip_filename(annotations[i].marker.sourceFile, "P"));
   shortSourceFiles:[shortSourceFile][shortSourceFiles:[shortSourceFile]._length()] = i;

   types:[lowcase(annotations[i].type)][types:[annotations[i].type]._length()] = i;
   versions:[annotations[i].version][versions:[annotations[i].version]._length()] = i;

   annotationIndices:[maybe_quote_filename(_mdi.p_child.p_buf_name)][_mdi.p_child.p_RLine] = i;

   updateAnnotationsBrowser(allAnnotations);

   typeless result = _mdi.show('-xy -modal _annotation_editor_form', freshestType,
                               newNoteFile, i, true);
   if (result == -1) {
      return(-1);
   }

   freshestType = fType;
   sortTypes();
   freshestFile = fFile;
   sortSCAFiles();

   return 1;
}



void _cancel.lbutton_up ()
{
   p_active_form._delete_window(-1);
}



defeventtab _new_annotation_field_form;
void _new_annotation_field_form.on_create ()
{
   _type_name.p_pic_indent_x = 60;
   _type_name._lbclear();
   _type_name.p_picture = bitmaps:[TEXT_CONTROL_TYPE];
   _type_name._lbadd_item(TEXT_CONTROL_TYPE, 60,
                                        bitmaps:[TEXT_CONTROL_TYPE]);
   _type_name._lbadd_item(MULTILINE_TEXT_CONTROL_TYPE, 60,
                                        bitmaps:[MULTILINE_TEXT_CONTROL_TYPE]);
   _type_name._lbadd_item(DROPDOWN_CONTROL_TYPE, 60,
                                        bitmaps:[DROPDOWN_CONTROL_TYPE]);
   _type_name._lbadd_item(LIST_CONTROL_TYPE, 60,
                                        bitmaps:[LIST_CONTROL_TYPE]);
   _type_name._lbadd_item(CHECKBOX_CONTROL_TYPE, 60,
                                        bitmaps:[CHECKBOX_CONTROL_TYPE]);
   _type_name._lbadd_item(DATE_CONTROL_TYPE, 60,
                                        bitmaps:[DATE_CONTROL_TYPE]);

   _type_name.p_picture = bitmaps:[TEXT_CONTROL_TYPE];
   _type_name.p_text = TEXT_CONTROL_TYPE;
}



void _new_annotation_field_form.esc ()
{
   p_active_form._delete_window(-1);
}



void _new_annotation_field_form.on_resize ()
{
   p_width = 4000;
   p_height = 1600;

   _type_label.p_x = 60;
   _type_name.p_x = _type_name.p_x;
   _type_name.p_y = 60;
   _type_name.p_width = p_width - _type_name.p_x - 120;
   _type_label.p_y = _type_name.p_y +
                     (_type_name.p_height - _type_label.p_height)/2;

   _cancel.p_x = p_width - _okay.p_width - 120;
   _cancel.p_y = _type_name.p_y + _type_name.p_height + 60;
   _okay.p_x = _cancel.p_x - 60 - _okay.p_width;
   _okay.p_y = _cancel.p_y;

   _field_warning.p_x = 60;
   _field_warning.p_y = _cancel.p_y + _cancel.p_height + 60;
}



void _type_name.on_change (int reason)
{
   switch ( reason ) {
   case CHANGE_CLINE:
   case CHANGE_CLINE_NOTVIS:
   case CHANGE_CLINE_NOTVIS2:
      // 6/29/2007 - rb
      // Temporarily suspend redraw and make visible listbox invisible.
      // This is in order to prevent the listbox from getting moved/resized
      // relative to the screen origin.
      // TODO: Figure out why that happens.
      p_redraw = false;
      boolean old_visible = p_visible;
      p_visible = false;

      p_picture = bitmaps:[p_text];

      p_visible = old_visible;
      p_redraw = true;
   }
}



void _type_name.enter ()
{
   p_active_form._delete_window(_type_name.p_text);
}



void _okay.lbutton_up ()
{
//    _str result = length(_field_name.p_text)':'_field_name.p_text;
//    if (_type_name.p_cb_text_box.p_text != '') {
//       result = result:+_type_name.p_cb_text_box.p_text;
//    }
//    p_active_form._delete_window(result);
   p_active_form._delete_window(_type_name.p_text);
}



void _cancel.lbutton_up ()
{
   p_active_form._delete_window(-1);
}



defeventtab _annotation_editor_form;
void _annotation_editor_form.on_create (_str type='', _str file='',
                                        int noteIndex=-1, boolean newNote=false)
{
   if ((type == null) || (type == '') || (file == null) || (file == '') || 
       !annotationTypes._indexin(lowcase(type)) || (noteIndex == -1)) {
      p_active_form._delete_window(1);
   }

   _SetDialogInfoHt(NEW_NOTE, newNote);
   _SetDialogInfoHt(NOTE_INDEX, noteIndex);

   p_caption = type;
   _file_name.p_caption = annotations[noteIndex].marker.sourceFile;
   _SetDialogInfoHt(SOURCE_FILE_NAME, annotations[noteIndex].marker.sourceFile);
   _author_name.p_caption = annotations[noteIndex].lastModUser;
   _date_modded.p_caption = annotations[noteIndex].lastModDate;
   if (annotations[noteIndex].noteFile == workspaceSCA) {
      _def_name.p_caption = '(Workspace Annotations)';
   } else if (annotations[noteIndex].noteFile == projectSCA) {
      _def_name.p_caption = '(Project Annotations)';
   } else if (annotations[noteIndex].noteFile == personalSCA) {
      _def_name.p_caption = '(Personal Annotations)';
   } else {
      _def_name.p_caption = annotations[noteIndex].noteFile;
   }
   currentNote = noteIndex;

   // align the labels, please

   _file_name.p_x = _author_name.p_x = _date_modded.p_x = _def_name.p_x = (_def_label.p_x + _def_label.p_width + 90);

   buildAnnotation();
}

void _annotation_editor_form.on_load ()
{
   //_ul2_editwin.on_create2 calls _SetEditorLanguage, which blows away any
   //custom settings for an editor. Because we're using a dynamically 
   //created editor window, we don't have our own on_create to override the 
   //default. Therefore, we'll have to set options here. 
   int i;
   int defIdx = annotationTypes:[lowcase(annotations[currentNote].type)];
   for (i = 0; i < annotationDefs[defIdx].fieldsUsed._length(); ++i) {
      if (dynControls[i].controlH.p_object == OI_EDITOR) {
         dynControls[i].controlH.p_eventtab2 = defeventtab _ul2_editwin;
         dynControls[i].controlH.p_scroll_bars = SB_VERTICAL;
         dynControls[i].controlH._SetEditorLanguage(FUNDAMENTAL_LANG_ID);
         dynControls[i].controlH.p_SoftWrap = true;
         dynControls[i].controlH.p_SoftWrapOnWord = true;
      }
   }
}

#define TEXT_CONTROL_HEIGHT                  260
#define DATE_CONTROL_HEIGHT                  351
#define MULTI_LINE_CONTROL_HEIGHT            1500
#define DROP_DOWN_CONTROL_HEIGHT             312
#define LIST_BOX_CONTROL_HEIGHT              1500
#define CHECKBOX_CONTROL_HEIGHT              260

//Make all the dynamic controls needed to edit an annotation's fields.
static void buildAnnotation ()
{
   if (currentNote < 0) {
      return;
   }

   int annotationID = _find_control("_annotation");

   dynControls._makeempty();

   int origWid;
   int i;
   int j;
   int fieldIDX;
   int defIdx = annotationTypes:[lowcase(annotations[currentNote].type)];
   for (i = 0; i < annotationDefs[defIdx].fieldsUsed._length(); ++i) {
      //Grab the indices in the order they appear in, in the definitions.
      fieldIDX = annotationDefs[defIdx].fieldsUsed[i];
      //Make the label.
      dynControls[i].labelH = _create_window(OI_LABEL, annotationID, '',
                                             0, 0, 0, 0, CW_CHILD);
      if (dynControls[i].labelH < 0) {
         _message_box("Could not build annotation dynamically");
         return;
      }
      dynControls[i].labelH.p_caption = annotations[currentNote].fields[fieldIDX].name":";
      dynControls[i].labelH.p_auto_size = true;
      dynControls[i].labelH.p_x = 60;

      //Make the control.
      dynControls[i].controlH = 0;
      switch (annotations[currentNote].fields[fieldIDX].fieldType) {
      case TEXT_CONTROL_TYPE:
         dynControls[i].controlH = _create_window(OI_TEXT_BOX, annotationID,
                                                  '', 0, 0, 0, TEXT_CONTROL_HEIGHT, CW_CHILD);
         dynControls[i].controlH.p_eventtab2 = defeventtab _ul2_textbox;
         break;
      case DATE_CONTROL_TYPE:
         dynControls[i].controlH = _create_window(OI_IMAGE, annotationID,
                                                  '', 0, 0, 0, DATE_CONTROL_HEIGHT, CW_CHILD);
         dynControls[i].controlH.p_eventtab = defeventtab _calendar_button;
         dynControls[i].controlH.p_eventtab2 = defeventtab _ul2_imageb;
         dynControls[i].controlH.p_picture = _update_picture(-1, 'bbcalendar.ico');
         dynControls[i].controlH.p_border_style = BDS_NONE;
         dynControls[i].controlH.p_max_click = MC_SINGLE;
         dynControls[i].controlH.p_style = PSPIC_BUTTON;
         dynControls[i].controlH.p_x = 60;
         break;
      case MULTILINE_TEXT_CONTROL_TYPE:
         dynControls[i].controlH = _create_window(OI_EDITOR, annotationID,
                                                  '', 60, 0, 1500, MULTI_LINE_CONTROL_HEIGHT,
                                                  CW_CHILD);
         break;
      case DROPDOWN_CONTROL_TYPE:
         dynControls[i].controlH = _create_window(OI_COMBO_BOX, annotationID,
                                                  '', 0, 0, 0, DROP_DOWN_CONTROL_HEIGHT, CW_CHILD);
         dynControls[i].controlH.p_eventtab2 = defeventtab _ul2_combobx;
         dynControls[i].controlH.p_style = PSCBO_NOEDIT;
         break;
      case LIST_CONTROL_TYPE:
         dynControls[i].controlH = _create_window(OI_LIST_BOX, annotationID,
                                                  '', 60, 0, 0, LIST_BOX_CONTROL_HEIGHT, CW_CHILD);
         dynControls[i].controlH.p_eventtab2 = defeventtab _ul2_listbox;
         dynControls[i].controlH.p_multi_select = MS_EXTENDED;
         break;
      case CHECKBOX_CONTROL_TYPE:
         dynControls[i].controlH = _create_window(OI_CHECK_BOX, annotationID,
                                                  '', 0, 0, 0, CHECKBOX_CONTROL_HEIGHT, CW_CHILD);
         if (dynControls[i].controlH < 0) {
            _message_box("Could not build dynamic controls");
            return;
         }
         //Checkboxes have their own inherent labels ...
         dynControls[i].controlH.p_caption =
         annotations[currentNote].fields[fieldIDX].name;
         dynControls[i].controlH.p_x = 60;
         //... 'turn off' the label.
         dynControls[i].labelH.p_visible = false;
         dynControls[i].labelH.p_enabled = false;
         dynControls[i].labelH.p_auto_size = false;
         dynControls[i].labelH.p_width = 0;
         break;
      default:
         break;
      }

      if (dynControls[i].controlH <= 0) {
         _message_box("Could not build dynamic controls");
         return;
      }

      //activeType = annotationDefs[annotationTypes:[lowcase(annotations[currentNote].type)]];

      //Populate the control.
      switch (annotations[currentNote].fields[fieldIDX].fieldType) {
      case TEXT_CONTROL_TYPE:
         if (!annotations[currentNote].fields[fieldIDX].text._isempty()) {
            dynControls[i].controlH.p_text =
            annotations[currentNote].fields[fieldIDX].text;
         }
         break;
      case DATE_CONTROL_TYPE:
         if (!annotations[currentNote].fields[fieldIDX].defaultDate._isempty()) {
            dynControls[i].labelH.p_caption = dynControls[i].labelH.p_caption:+
                                              ' 'annotations[currentNote].fields[fieldIDX].defaultDate;
         }
         break;
      case MULTILINE_TEXT_CONTROL_TYPE:
         dynControls[i].controlH._lbclear();
         dynControls[i].controlH.top();
         for (j = 0;
             j < annotations[currentNote].fields[fieldIDX].editor._length();
             ++j) {
            dynControls[i].controlH.insert_line(
                                               annotations[currentNote].fields[fieldIDX].editor[j]);
         }
         break;
         dynControls[i].controlH.top();
//          dynControls[i].controlH.p_col = 1;
//          origWid = p_window_id;
//          p_window_id = dynControls[i].controlH;
//          set_scroll_pos(p_left_edge, p_cursor_y);
//          p_window_id = origWid;
      case DROPDOWN_CONTROL_TYPE:
         dynControls[i].controlH._lbclear();
         for (j = 0;
             j < annotations[currentNote].fields[fieldIDX].dropdown._length();
             ++j) {
            dynControls[i].controlH._lbadd_item(annotations[currentNote].fields[fieldIDX].dropdown[j]);
         }
         if (!annotations[currentNote].fields[fieldIDX].dropdown._isempty() &&
             !annotations[currentNote].fields[fieldIDX].defaultIndices._isempty() &&
             (annotations[currentNote].fields[fieldIDX].defaultIndices[0] > -1)) {
            dynControls[i].controlH.p_text =
            annotations[currentNote].fields[fieldIDX].dropdown[annotations[currentNote].fields[fieldIDX].defaultIndices[0]];
         } else if (!annotations[currentNote].fields[fieldIDX].dropdown._isempty()) {
            dynControls[i].controlH.p_text = annotations[currentNote].fields[fieldIDX].dropdown[0];
         }
         break;
      case LIST_CONTROL_TYPE:
         dynControls[i].controlH._lbclear();
         dynControls[i].controlH._lbtop();
         for (j = 0; 
             j < annotations[currentNote].fields[fieldIDX].list._length();
             ++j) {
            dynControls[i].controlH._lbadd_item(annotations[currentNote].fields[fieldIDX].list[j]);
         }
         for (j = 0;
             j < annotations[currentNote].fields[fieldIDX].defaultIndices._length();
             ++j) {
            dynControls[i].controlH.p_line =
            annotations[currentNote].fields[fieldIDX].defaultIndices[j] + 1;
            dynControls[i].controlH._lbselect_line();
         }
         break;
      case CHECKBOX_CONTROL_TYPE:
         if (annotations[currentNote].fields[fieldIDX].checkbox == 'true') {
            dynControls[i].controlH.p_value = 1;
         } else {
            dynControls[i].controlH.p_value = 0;
         }
         break;
      default:
         break;
      }

      dynControls[i].controlH.p_tab_index = i + 1;
      dynControls[i].controlH.p_tab_stop = true;
   }

   _okay.p_tab_index = i + 1;
   _cancel.p_tab_index = i + 2;
}



void _annotation_editor_form.on_resize ()
{
   int width = _dx2lx(p_active_form.p_xyscale_mode, p_active_form.p_client_width);
   int height = _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);

   _file_box.p_x = 60;
   _file_box.p_y = 60;
   _file_box.p_width = width - 120;

   _str fileName = _GetDialogInfoHt(SOURCE_FILE_NAME);
   _file_name.p_width = _file_box.p_width - _file_name.p_x - 60;
   if (fileName) {
      _str preview = _file_name._ShrinkFilename(fileName, _file_name.p_width);
      _file_name.p_caption = preview;
   }

   _annotation_container.p_x = 60;
   _annotation_container.p_y = _file_box.p_y + _file_box.p_height + 60;
   _annotation_container.p_width = width - 120;
   //_annotation_container.p_height = height - 1669;
   _annotation_container.p_height = height - 1853;
   _annotation_scroller.p_x = _annotation_container.p_width - 234;
   _annotation_scroller.p_y = 0;
   _annotation_scroller.p_height = _annotation_container.p_height;

   _annotation_scroller.p_max = 30;
   _annotation_scroller.p_small_change = 1; //value of arrow button
   _annotation_scroller.p_large_change = 10; //value of channel

   _cancel.p_x = _annotation_container.p_x + _annotation_container.p_width -
                 _okay.p_width;
   _cancel.p_y = _annotation_container.p_y + _annotation_container.p_height + 60;
   _okay.p_x = _cancel.p_x - _okay.p_width - 60;
   _okay.p_y = _cancel.p_y;

   resizeDynamicContent();
}



static void resizeDynamicContent ()
{
   if (currentNote < 0) return;

   int y = 60;

   int i = 0;
   int fieldIDX;
   int defIdx = annotationTypes:[lowcase(annotations[currentNote].type)];

   // go through all the controls in this annotation type
   for (i = 0; i < annotationDefs[defIdx].fieldsUsed._length(); ++i) {

      //Grab the indices in the order they appear in, in the definitions.
      fieldIDX = annotationDefs[defIdx].fieldsUsed[i];

      // what kind of control is it?
      switch (annotations[currentNote].fields[fieldIDX].fieldType) {
      case TEXT_CONTROL_TYPE:
      case DROPDOWN_CONTROL_TYPE:
         dynControls[i].controlH.p_y = y;
         dynControls[i].controlH.p_x = dynControls[i].labelH.p_x +
                                       dynControls[i].labelH.p_width + 60;
         y = y + (dynControls[i].controlH.p_height -
                  dynControls[i].labelH.p_height)/2;
         dynControls[i].labelH.p_y = y;
         break;
      case DATE_CONTROL_TYPE:
         dynControls[i].controlH.p_y = y;
         dynControls[i].labelH.p_y = dynControls[i].controlH.p_y +
                                     (dynControls[i].controlH.p_height -
                                      dynControls[i].labelH.p_height)/2;
         dynControls[i].labelH.p_x = dynControls[i].controlH.p_x +
                                     dynControls[i].controlH.p_width + 60;
         break;
      case MULTILINE_TEXT_CONTROL_TYPE:
      case LIST_CONTROL_TYPE:
         dynControls[i].labelH.p_y = y;
         y = dynControls[i].labelH.p_y + dynControls[i].labelH.p_height + 20;
         dynControls[i].controlH.p_y = y;
         break;
      case CHECKBOX_CONTROL_TYPE:
         dynControls[i].controlH.p_y = y;
         break;
      default:
         break;
      }
      y = y + dynControls[i].controlH.p_height + 60;
   }

   int numberOfControls = dynControls._length();

   //Decide if a scroll bar is necessary.
   if (y > _annotation_container.p_height) {
      _annotation.p_width = _annotation_container.p_width - 240;
      _annotation_scroller.p_visible = true;
      _annotation_scroller.p_enabled = true;
      _annotation_scroller.p_tab_stop = true;
      int scrollerHeight = _ly2dy(p_xyscale_mode,
                                  (_annotation.p_height -
                                   _annotation_container.p_height));
      _annotation_scroller.p_max = scrollerHeight;
   } else {
      _annotation.p_width = _annotation_container.p_width;
      _annotation_scroller.p_visible = false;
      _annotation_scroller.p_enabled = false;
      _annotation_scroller.p_tab_stop = false;
   }

   //The dynamic controls always need to be resized.
   _annotation.p_height = y + 60;
   for (i = 0; i < numberOfControls; ++i) {
      dynControls[i].controlH.p_width = _annotation.p_width - 
                                        dynControls[i].controlH.p_x - 60;
   }
}



//ESC should do whatever the cancel button does.
void _annotation_editor_form.esc ()
{
   _cancel.call_event(0, _cancel, LBUTTON_UP, 'w');
}



void _okay.lbutton_up ()
{
   if (currentNote >= 0) {
      saveNote();
   }

   //Because the annotation was opened for editing, and the user "OK'd" things,
   //modify the annotation's modification and version information.
   annotations[currentNote].lastModDate = annotation_date();
   annotations[currentNote].lastModUser = annotation_username();
   annotations[currentNote].version++;
   _str noteFile = annotations[currentNote].noteFile;
   int typeIdx = annotationTypes:[lowcase(annotations[currentNote].type)]; 
   annotationDefs[typeIdx].noteFiles:[noteFile] = noteFile;
   exportAnnotations(noteFile);

   int wid = _find_formobj('_tbannotations_browser_form', 'n');
   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.showFields(lastAnnotations);
      wid.enableNoteOps();
   }

   p_active_form._delete_window(1);
}



void _cancel.lbutton_up ()
{
   int noteIndex = _GetDialogInfoHt(NOTE_INDEX);
   _str noteFile = annotations[noteIndex].noteFile;

   int wid = _find_formobj('_tbannotations_browser_form', 'n');

   if (_GetDialogInfoHt(NEW_NOTE) == true) {
      if (annotations[noteIndex].lineMarker >= 0) {
         _LineMarkerRemove(annotations[noteIndex].lineMarker);
      }
      annotations._deleteel(noteIndex);
      rehashNoteIDs();
      if ((wid > 0) && _iswindow_valid(wid)) {
         wid.setupTypeList();
         wid.setupFilters();
      }
   }

   if ((wid > 0) && _iswindow_valid(wid)) {
      wid.showFields(allAnnotations);
   }

   p_active_form._delete_window(-1);
}



static void saveNote ()
{
   int i;
   int j;
   int fieldIDX;
   int defIdx = annotationTypes:[lowcase(annotations[currentNote].type)];
   for (i = 0; i < dynControls._length(); ++i) {
      //Grab the indices in the order they appear in, in the definitions.
      fieldIDX = annotationDefs[defIdx].fieldsUsed[i];
      switch (annotations[currentNote].fields[fieldIDX].fieldType) {
      case TEXT_CONTROL_TYPE:
         annotations[currentNote].fields[fieldIDX].text =
         dynControls[i].controlH.p_text;
         break;
      case MULTILINE_TEXT_CONTROL_TYPE:
         annotations[currentNote].fields[fieldIDX].editor._makeempty();
         dynControls[i].controlH.top();
         dynControls[i].controlH.up();
         j = 0;
         while (!dynControls[i].controlH.down()) {
            dynControls[i].controlH.get_line(annotations[currentNote].fields[fieldIDX].editor[j++]);
         }
         break;
      case LIST_CONTROL_TYPE:
         annotations[currentNote].fields[fieldIDX].defaultIndices._makeempty();
         dynControls[i].controlH.top();
         dynControls[i].controlH.up();
         j = 0;
         while (!dynControls[i].controlH.down()) {
            if (dynControls[i].controlH._lbisline_selected()) {
               annotations[currentNote].fields[fieldIDX].defaultIndices[j] =
               dynControls[i].controlH.p_line - 1;
               ++j;
            }
         }
         break;
      case DROPDOWN_CONTROL_TYPE:
         annotations[currentNote].fields[fieldIDX].defaultIndices._makeempty();
         annotations[currentNote].fields[fieldIDX].defaultIndices[0] =
         dynControls[i].controlH.p_line - 1;
         break;
      case CHECKBOX_CONTROL_TYPE:
         if (dynControls[i].controlH.p_value == 1) {
            annotations[currentNote].fields[fieldIDX].checkbox = 'true';
         } else {
            annotations[currentNote].fields[fieldIDX].checkbox = 'false';
         }
         break;
      case DATE_CONTROL_TYPE:
         _str date = '';
         parse dynControls[i].labelH.p_caption with . ': ' date;
         annotations[currentNote].fields[fieldIDX].defaultDate = date;
         break;
      }
      dynControls[i].controlH;
   }

   makeAnnotationCaption(annotations[currentNote]);

   int wid = window_match(annotations[currentNote].marker.sourceFile, 1, 'x');
   if (wid == 0) {
      return;
   }

   //Update the line marker's message.
   _LineMarkerRemove(annotations[currentNote].lineMarker);
   int lmIndex;
   _str noteMessage = '';
   int typeLength = length(annotations[currentNote].type);
   strappend(noteMessage, '<code>'annotations[currentNote].type'</code><br>');
   strappend(noteMessage, center('', typeLength, '-')'<br>');
   strappend(noteMessage, annotations[currentNote].preview);
   lmIndex = _LineMarkerAdd(wid, annotations[currentNote].marker.origLineNumber,
                            0, 0, annotationPic, noteMarkerType,
                            noteMessage);
   annotations[currentNote].lineMarker = lmIndex;
   lineMarkers:[lmIndex] = currentNote;
}



void _annotation_scroller.on_change,on_scroll ()
{
   _annotation.p_y=-_dy2ly(p_active_form.p_xyscale_mode, p_value);
}



defeventtab _annotation_rename_type_form;
void _annotation_rename_type_form.on_create (_str name, _str fileName)
{
   _str msg = "The '"name"' annotation type in "fileName" conflicts with ":+
              "the existing '"name"' annotation type. Some data may be ":+
              "lost.\n\nPlease select a new name for the type:";

   _message_label.p_caption = msg;

   // set minimum size
   int minHeight = _message_label.p_height + _new_type_name.p_height +
                   _rename_type.p_height + 300;
   minWidth := _rename_type.p_width * 4;
   _set_minimum_size(minWidth, minHeight);

}



void _annotation_rename_type_form.on_resize ()
{
   int width = p_width;
   int height = p_height;

   _message.p_x = 60;
   _message.p_width = width - 120;
   _message_label.p_x = 30;
   _message_label.p_width = _message.p_width - 60;
   _message_label.p_y = 30;
   _message.p_height = height - 240 - _new_type_name.p_height -
                       _rename_type.p_height;

   _new_type_name.p_x = _message.p_x;
   _new_type_name.p_y = _message.p_y + _message.p_height + 40;
   _new_type_name.p_width = _message.p_width;
   _rename_type.p_x = width - 60 - _rename_type.p_width;
   _rename_type.p_y = _new_type_name.p_y + _new_type_name.p_height + 40;
}



void _new_type_name.ENTER ()
{
   _rename_type.call_event(0, _rename_type, LBUTTON_UP, 'w');
}


void _rename_type.lbutton_up ()
{
   if (_new_type_name.p_text == '') {
      return;
   }
   if (annotationTypes._indexin(lowcase(_new_type_name.p_text))) {
      return;
   }
   p_active_form._delete_window(_new_type_name.p_text);
}



defeventtab _annotation_files_form;
void _annotation_files_form.on_create ()
{
   setup_annotation_files_form();
   setup_info_tree('Empty', 0);
}



void _annotation_files_form.on_resize ()
{
   int width = _dx2lx(p_active_form.p_xyscale_mode, p_active_form.p_client_width);
   int height = _dy2ly(p_active_form.p_xyscale_mode, p_active_form.p_client_height);

   _OK.p_x = width - _OK.p_width - 60;
   _OK.p_y = height - _OK.p_height - 60;

   _annotation_files.p_y = _annotation_files_label.p_y +
                           _annotation_files_label.p_height + 60;
   _annotation_files.p_width = width - 120;
   _annotation_files.p_height = _sizebar_y.p_y - _annotation_files.p_y;
   _sizebar_y.p_width = _annotation_files.p_width;

   _close_SCA.p_x = width - _close_SCA.p_width - 60;
   _close_SCA.p_y = _sizebar_y.p_y + _sizebar_y.p_height + 60;
   _open_SCA.p_x = _close_SCA.p_x - _open_SCA.p_width - 60;
   _open_SCA.p_y = _close_SCA.p_y;
   _new_SCA.p_x = _open_SCA.p_x - _new_SCA.p_width - 60;
   _new_SCA.p_y = _close_SCA.p_y;

   _annotation_file_contents.p_width = _sizebar_x.p_x -
                                       _annotation_file_contents.p_x;
   _annotation_file_contents.p_y = _close_SCA.p_y +
                                   _close_SCA.p_height + 60;
   _annotation_file_contents.p_height = _OK.p_y -
                                        _annotation_file_contents.p_y - 60;
   _annotation_file_contents_label.p_y = _annotation_file_contents.p_y -
                                         _annotation_file_contents_label.p_height - 60;
   _sizebar_x.p_y = _annotation_file_contents.p_y;
   _sizebar_x.p_height = _annotation_file_contents.p_height;

   _dual_info_frame.p_x = _sizebar_x.p_x + _sizebar_x.p_width;
   _dual_info_frame.p_y = _annotation_file_contents.p_y - 80;
   _dual_info_frame.p_width = width - 60 - _dual_info_frame.p_x;
   _dual_info_frame.p_height = _version_info_frame.p_y -
                               _dual_info_frame.p_y - 60;

   _info_tree.p_y = _name_label.p_y + _name_label.p_height + 60;
   _info_tree.p_width = _dual_info_frame.p_width - 120;
   _info_tree.p_height = _dual_info_frame.p_height - _info_tree.p_y - 120;

   _version_info_frame.p_x = _dual_info_frame.p_x;
   _version_info_frame.p_y = _OK.p_y - _version_info_frame.p_height - 60;
   _version_info_frame.p_width = _dual_info_frame.p_width;
}


void _annotation_files_form.esc ()
{
   p_active_form._delete_window();
}



void _sizebar_x.lbutton_down()
{
   _ul2_image_sizebar_handler(_annotation_file_contents.p_x + 80,
                              _dual_info_frame.p_x +
                              _dual_info_frame.p_width);
}



void _sizebar_y.lbutton_down()
{
   _ul2_image_sizebar_handler(_annotation_files.p_y + 80,
                              _version_info_frame.p_y - _close_SCA.p_height - 180);
}



static void setup_annotation_files_form ()
{
   int tIndex;
   int aIndex;

   _annotation_file_contents._TreeDelete(TREE_ROOT_INDEX, "C");
   tIndex = _annotation_file_contents._TreeAddItem(TREE_ROOT_INDEX, 'Types',
                                                   TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED, 
                                                   0, "Root 0");
   aIndex = _annotation_file_contents._TreeAddItem(TREE_ROOT_INDEX,
                                                   'Annotations',
                                                   TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED,
                                                   0, "Root 0");
   _SetDialogInfoHt(ANNOTATION_TYPES, tIndex);
   _SetDialogInfoHt(ANNOTATIONS, aIndex);


   _annotation_files._TreeDelete(TREE_ROOT_INDEX, 'c');
   _annotation_files._TreeSetColButtonInfo(0, 1, TREE_BUTTON_PUSHBUTTON|
                                           TREE_BUTTON_SORT_EXACT, 0, 'Alias');
   _annotation_files._TreeSetColButtonInfo(1, 1, TREE_BUTTON_PUSHBUTTON|
                                           TREE_BUTTON_SORT_EXACT, 0,
                                           'File Name');
   _annotation_files._TreeSetColButtonInfo(2, 1, TREE_BUTTON_PUSHBUTTON|
                                           TREE_BUTTON_SORT_EXACT, 0, 'Path');

   _str treeEntry = '';
   int i = 0;
   for (; i < defFiles._length(); ++i) {
      if (SCAFiles._indexin(defFiles[i])) {
         treeEntry = SCAFiles:[defFiles[i]];
      } else {
         treeEntry = '';
      }
      treeEntry = treeEntry"\t"stranslate(_strip_filename(defFiles[i], "P"), '', '"')"\t"maybe_quote_filename(defFiles[i]);
      _annotation_files._TreeAddItem(TREE_ROOT_INDEX, treeEntry,
                                     TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
   }

   _annotation_files._TreeAdjustColumnWidths();
   _annotation_files._TreeRefresh();
}



/**
 * The _info_tree can show either type information or annotation information. 
 *  
 */
static void setup_info_tree (_str infoType, int index)
{
   _info_tree._TreeDelete(TREE_ROOT_INDEX, "C");

   int i;
   int n;
   _str row;
   if (infoType == 'Type') {
      _dual_info_frame.p_caption = 'Annotation Type Info';
      _info_tree._TreeSetColButtonInfo(0, 1, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT_EXACT, 0, 'Field');
      _info_tree._TreeSetColButtonInfo(1, 1, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT_EXACT, 0, 'Type');

      n = annotationDefs[index].fieldsUsed._length();
      int fIdx;
      for (i = 0; i < n; ++i) {
         fIdx = annotationDefs[index].fieldsUsed[i];
         row = annotationDefs[index].fields[fIdx].name"\t":+
               annotationDefs[index].fields[fIdx].fieldType;
         _info_tree._TreeAddItem(TREE_ROOT_INDEX, row, TREE_ADD_AS_CHILD, 0, 0,
                                 TREE_NODE_LEAF);
      }

      _name.p_caption = annotationDefs[index].name;
      _author.p_caption = annotationDefs[index].author;
      _created.p_caption = annotationDefs[index].creationDate;
      ctl_version.p_caption = annotationDefs[index].version;
      _edited_by.p_caption = annotationDefs[index].lastModifiedUser;
      _edited.p_caption = annotationDefs[index].lastModifiedDate;
   } else if (infoType == 'Note') {
      _dual_info_frame.p_caption = 'Annotation Info';
      _info_tree._TreeSetColButtonInfo(0, 1, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT_EXACT, 0, 'Field');
      _info_tree._TreeSetColButtonInfo(1, 1, TREE_BUTTON_PUSHBUTTON|
                                       TREE_BUTTON_SORT_EXACT, 0, 'Contents');

      int idx;
      int l;
      n = annotations[index].fields._length();
      for (i = 0; i < n; ++i) {
         row = annotations[index].fields[i].name"\t";
         switch (annotations[index].fields[i].fieldType) {
         case TEXT_CONTROL_TYPE:
            if (!annotations[index].fields[i].text._isempty()) {
               row = row:+annotations[index].fields[i].text;
            }
            break;
         case DATE_CONTROL_TYPE:
            if (!annotations[index].fields[i].defaultDate._isempty()) {
               row = row:+annotations[index].fields[i].defaultDate;
            }
            break;
         case MULTILINE_TEXT_CONTROL_TYPE:
            if (!annotations[index].fields[i].editor._isempty()) {
               row = row:+annotations[index].fields[i].editor[0];
            }
            break;
         case DROPDOWN_CONTROL_TYPE:
            if (annotations[index].fields[i].defaultIndices._length() > 0) {
               l = annotations[index].fields[i].defaultIndices[0];
               row = row:+annotations[index].fields[i].dropdown[l];
            }
            break;
         case LIST_CONTROL_TYPE:
            for (l = 0;
                l < annotations[index].fields[i].defaultIndices._length();
                ++l) {
               idx = annotations[index].fields[i].defaultIndices[l];
               row = row:+annotations[index].fields[i].list[idx]", ";
            }
            row = substr(row, 1, (length(row) - 2));
            break;
         case CHECKBOX_CONTROL_TYPE:
            if (annotations[index].fields[i].checkbox == 'true') {
               row = row:+'true';
            } else {
               row = row:+'false';
            }
            break;
         }
         _info_tree._TreeAddItem(TREE_ROOT_INDEX, row,
                                 TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      }
      _name.p_caption = annotations[index].type;
      _author.p_caption = annotations[index].author;
      _created.p_caption = annotations[index].creationDate;
      ctl_version.p_caption = annotations[index].version;
      _edited_by.p_caption = annotations[index].lastModUser;
      _edited.p_caption = annotations[index].lastModDate;
   } else {
      n = _info_tree._TreeGetNumColButtons();
      for (i = 0; i < n; ++i) {
         _info_tree._TreeDeleteColButton(0);
      }
      _name.p_caption = '';
      _author.p_caption = '';
      _created.p_caption = '';
      ctl_version.p_caption = '';
      _edited_by.p_caption = '';
      _edited_by.p_caption = '';
   }

   _info_tree._TreeAdjustColumnWidths();
   _info_tree._TreeRefresh();
}



static void setup_annotation_file_contents (_str fileName)
{
   int i;
   int j = 0;
   int nOfNotes;
   int nOfTypes;
   int leafIndex;
   _str tIndex;
   _str aIndex;
   _str content;
   _str types:[];

   tIndex = _GetDialogInfoHt(ANNOTATION_TYPES);
   if (tIndex._isempty()) {
      return;
   }
   aIndex = _GetDialogInfoHt(ANNOTATIONS);
   if (aIndex._isempty()) {
      return;
   }
   _annotation_file_contents._TreeDelete((int)tIndex, "C");
   _annotation_file_contents._TreeDelete((int)aIndex, "C");

   //Set up the type information.
   nOfTypes = annotationDefs._length();
   for (j = 0; j < nOfTypes; ++j) {
      if (annotationDefs[j].noteFiles._indexin(fileName)) {
         leafIndex = _annotation_file_contents._TreeAddItem((int)tIndex,
                                                            annotationDefs[j].name,
                                                            TREE_ADD_AS_CHILD, 0,
                                                            0, TREE_NODE_LEAF, 0,
                                                            "Type ":+annotationTypes:[lowcase(annotationDefs[j].name)]
                                                           );
      }
   }

   //Set up the annotation information.
   _str sourceName;
   nOfNotes = noteFiles:[fileName]._length();
   for (j = 0; j < nOfNotes; ++j) {
      i = noteFiles:[fileName][j];
      sourceName = _strip_filename(annotations[i].marker.sourceFile, "P");
      content = annotations[i].type" : "maybe_quote_filename(sourceName):+
                ", line "annotations[i].marker.origLineNumber;
      leafIndex = _annotation_file_contents._TreeAddItem((int)aIndex, content,
                                                         TREE_ADD_AS_CHILD, 0,
                                                         0, TREE_NODE_LEAF, 0, "Note "i );
   }
}



void _annotation_files.on_change (int reason, int index)
{
   _str fileName = '';

   switch (reason) {
   case CHANGE_SELECTED:
      parse _TreeGetCaption(index) with . "\t" . "\t" fileName;
      if ((fileName == workspaceSCA) ||
          (fileName == projectSCA) ||
          (fileName == personalSCA)) {
         _close_SCA.p_enabled = false;
      } else {
         _close_SCA.p_enabled = true;
         _SetDialogInfoHt(SCA_FILE, fileName, _annotation_files);
      }
      setup_annotation_file_contents(fileName);
      break;
   }
}



void _annotation_file_contents.on_change (int reason, int index)
{
   _str infoType;
   _str infoIndex;
   _str userInfo;

   switch (reason) {
   case CHANGE_SELECTED:
      userInfo = _TreeGetUserInfo(index);
      if (userInfo != '') {
         parse userInfo with infoType " " infoIndex;
         setup_info_tree(infoType, (int)infoIndex);
      }
      break;
   }
}



void _new_SCA.lbutton_up ()
{
   _str newSCAFile = p_active_form.getFileName('New');
   if (newSCAFile == '') {
      return;
   }

   _str extension = _get_extension(newSCAFile);
   if (extension != 'sca') {
      _message_box('Code annotation files must use .sca extensions', 'Warning');
      return;
   }

   newSCAFile = maybe_quote_filename(newSCAFile);

   if (!file_exists(newSCAFile)) {
      int treeHandle;
      startAnnotationFile(newSCAFile, treeHandle);
      _xmlcfg_save(treeHandle, -1, VSXMLCFG_SAVE_ALL_ON_ONE_LINE|
                   VSXMLCFG_SAVE_UNIX_EOL);
      _xmlcfg_close(treeHandle);
   }
   importAnnotations(newSCAFile);

   setup_annotation_files_form();
   updateAnnotationsBrowser(allAnnotations);
}



void _open_SCA.lbutton_up ()
{
   _str SCAFileName = p_active_form.getFileName();
   if (SCAFileName == '') {
      return;
   }
   SCAFileName = maybe_quote_filename(SCAFileName);
   importAnnotations(SCAFileName);
   setup_annotation_files_form();

   updateAnnotationsBrowser(allAnnotations);
}



void _close_SCA.lbutton_up ()
{
   _str closeFile = '';
   closeFile = _GetDialogInfoHt(SCA_FILE, _annotation_files);
   if (closeFile == '') {
      return;
   }
   removeSCAFile(closeFile);
   cleanDefFiles();

   setup_annotation_files_form();

   updateAnnotationsBrowser(allAnnotations);
}



void _OK.lbutton_up ()
{
   p_active_form._delete_window();
}



defeventtab _calendar_button;
void _calendar_button.lbutton_up()
{
   _str yyyy = '';
   _str mm = '';
   _str dd = '';
   _str label = '';
   parse p_prev.p_caption with label ': ' yyyy '-' mm '-' dd;
   DateTime today;
   if ((yyyy != '') && (mm != '') && (dd != '')) {
      DateTime anotherDay((int)yyyy, (int)mm, (int)dd);
      today = anotherDay;
   }

   DateTime result;
   calendar(today, 0, null, &result);

   _str date = '';
   if (result != null) {
      parse result.toString() with date 'T' .;
   } else {
      parse today.toString() with date 'T' .;
   }
   p_prev.p_caption = label': 'date;
}



/*
relocatable marker code:
*/
static void clearMarker (RELOC_MARKER& lm)
{
   lm.origLineNumber = 0;
   lm.n = 0;
   lm.aboveCount = 0;
   lm.belowCount = 0;
   lm.totalCount = 0;
   lm.origText._makeempty();
   lm.textAbove._makeempty();
   lm.textBelow._makeempty();
}

/**
 * Save the information needed for a relocatable line marker. 
 * 
 * @param lm            Relocatable line marker information 
 * @param line_window   Number of lines above and below to scan. 
 *  
 * @see _RelocateMarker 
 */
void _BuildRelocatableMarker(RELOC_MARKER& lm,
                             int line_window=RELOC_MARKER_WINDOW_SIZE)
{
   lm.aboveCount = 0;
   lm.belowCount = 0;
   lm.sourceFile = maybe_quote_filename(p_buf_name);
   lm.origLineNumber = p_RLine;
   lm.origText._makeempty();
   lm.textAbove._makeempty();
   lm.textBelow._makeempty();
   lm.n = line_window;

   save_pos(auto p);
   get_line(auto line);
   tokenizeLine(line, lm.origText);
   _str upLines[][];
   int i;
   for (i=0; i<lm.n; ++i) {
      if ((p_RLine == 1) || up()) {
         break;
      }
      get_line(line);
      tokenizeLine(line, upLines[i]);
   }
   // Compact lm.textAbove[]
   for (i = 0; i < upLines._length(); ++i) {
      lm.textAbove[i] = upLines[upLines._length()-i-1];
      ++lm.aboveCount;
   }
   p_RLine = lm.origLineNumber;
   for (i=0; i<lm.n; ++i) {
      if (down()) {
         break;
      }
      get_line(line);
      tokenizeLine(line, lm.textBelow[i]);
      ++lm.belowCount;
   }
   lm.totalCount = lm.aboveCount + lm.belowCount;
   p_RLine = lm.origLineNumber;
   restore_pos(p);
}



static int relocateMarkers (_str wid=_mdi.p_child.p_buf_id,
                            boolean newBuffer=false)
{
   //Setup the linemarkers' type and picture.
   setupMarkers();

   int origID = p_window_id;
   int tempID;

   int status = _open_temp_view('', tempID, origID, '+bi ':+wid);
   p_window_id = tempID;
   _str bufName = maybe_quote_filename(p_buf_name);

   //for each relocatable code marker in the given buffer, relocate it 
   //if possible and reset the matching line marker.
   int noteCount = sourceFiles:[bufName]._length();
   int i;
   int j;
   int lmIndex = -1;
   int newLineNumber;

   for (i = 0; i < noteCount; ++i) {
      j = sourceFiles:[bufName][i];
      newLineNumber = strCompRelocate(annotations[j].marker);
      p_RLine = newLineNumber;

      _str noteMessage = '';
      int typeLength = length(annotations[j].type);
      strappend(noteMessage, '<code>'annotations[j].type'</code><br>');
      strappend(noteMessage, center('', typeLength, '-')'<br>');
      strappend(noteMessage, annotations[j].preview);
      if ((newLineNumber <= 0) && newBuffer) {
         lmIndex =
         _LineMarkerAdd(p_window_id, annotations[j].marker.origLineNumber, 0,
                        0, annotationPic, noteMarkerType, noteMessage);
         annotations[j].lineMarker = lmIndex;
         lineMarkers:[lmIndex] = j;
      } else if (newLineNumber > 0) {
         if ((newLineNumber != annotations[j].marker.origLineNumber) ||
             newBuffer) {
            _LineMarkerRemove(annotations[j].lineMarker);
            lmIndex = _LineMarkerAdd(p_window_id, newLineNumber, 0, 0,
                                     annotationPic, noteMarkerType,
                                     noteMessage);
            annotations[j].lineMarker = lmIndex;
            lineMarkers:[lmIndex] = j;
         }
      }
      //Rebuild the marker with the current line and neighborhood.
      tempID._BuildRelocatableMarker(annotations[j].marker,
                                     RELOC_MARKER_WINDOW_SIZE);
   }
   p_window_id = origID;
   _delete_temp_view(tempID);

   int abf = _find_formobj('_tbannotations_browser_form', 'n');
   if (abf > 0) {
      abf.showFields(lastAnnotations);
   }

   freshSourceFiles:[maybe_quote_filename(bufName)] = true;
   return 1;
}

/** 
 * @return 
 *    Using the given relocatable marker information,
 *    return the line number that the adjusted line marker
 *    should be placed on.
 * 
 * @param lm           Relocatable line marker information 
 * @param resetTokens  If true, empty the file token cache. You 
 *                     should empty the cache the first time
 *                     a loop starts relocating markers in a
 *                     file.
 * @param compare      Comparison technique, default is the 
 *                     quicker token based string compare.
 *  
 * @see _BuildRelocatableMarker 
 */
int _RelocateMarker(RELOC_MARKER& lm,
                    boolean resetTokens=false,
                    typeless compare=tokenStringCompare)
{
   // a little extra error checking
   if (lm == null || lm.origLineNumber == null) {
      return -1;
   }

   _str line = '';
   double lineScore = 0.0;
   double windowScore = 0.0;
   double totalScores:[];
   int origLineNumber;
   int upDown = 1;
   int linesMoved = 1;
   int windowsChecked = 0;
   int relocLine = -1;
   _str tokenizedFile[][];

   origLineNumber = p_window_id.p_RLine;

   //for each set of file line tokens from the file
   // if the original line number is within bounds, 
   // then start there, otherwise, start in the middle
   if ((lm.origLineNumber >= 0) && (lm.origLineNumber < p_window_id.p_Noflines)) {
      // start at the original line number
      p_window_id.p_RLine = lm.origLineNumber;
   } else {
      // the original was out of bounds, so start in the middle
      p_window_id.p_RLine = (int)(p_window_id.p_Noflines / 2);
   }
   int old_array_size = _default_option(VSOPTION_WARNING_ARRAY_SIZE);
   _default_option(VSOPTION_WARNING_ARRAY_SIZE, MAXINT);
   double origTime = (double)_time('F');
   int iterationCount = 1;
   boolean bofReached = false;
   boolean eofReached = false;
   int retVal = 0;
   totalScores._makeempty();
   // kee looping until we've hit the BOF and EOF
   while ((bofReached == false) || (eofReached == false)) {
      double totalScore = 0.0;
      int curLine = p_window_id.p_RLine;
      // determine if we already have a score for this line, if not then compute it
      if (!(totalScores._indexin(curLine))) {
         // compute the score for this line
         if (tokenizedFile[curLine]._isempty()) {
            get_line(line);
            tokenizeLine(line, tokenizedFile[curLine]);
         }
         //compute the similarity between the line and the marker's line
         lineScore = (*compare)(tokenizedFile[curLine], lm.origText);
         if (lineScore >= CANDIDATE_MATCH) {
            ++windowsChecked;
            windowScore = getWindowScore(lm, curLine, compare, tokenizedFile);
            totalScore = lineScore*0.6 + windowScore*0.4;
            if (totalScore >= INSTANT_MATCH) {
               relocLine = curLine;
               p_window_id.p_RLine = origLineNumber;
               return relocLine;
            }
         }
         totalScores:[curLine] = totalScore;
      }

      // the strategy here is to oscillate up one from the original line number and then
      // down one line from that line number, then up two from that line number and then
      // down two.  So, if the original line number was 10, then we would try 9, 11, 8, 12,
      // 7, 13 and so on, going up a line, then down a line.
      p_window_id.p_RLine = lm.origLineNumber;
      // determine which side of the original line to test
      if (upDown > 0) {
         // determine if we've reached the BOF
         if (bofReached == false) {
            // if not, then test up one line
            retVal = up(linesMoved);
            if (retVal == TOP_OF_FILE_RC) {
               // if we've reached that, then flag that we've hit the top of the file and continue
               bofReached = true;
            }
         }
      } else {
         // determine if we've reached the EOF
         if (eofReached == false) {
            // if not, then test down one line
            retVal = down(linesMoved);
            if (retVal == BOTTOM_OF_FILE_RC) {
               // if we've reached that, then flag that we've hit the end of the file and continue
               eofReached = true;
            }
         }
         // increment the number of lines away from the original that we are testing
         ++linesMoved;
      }
      upDown = -upDown;

      // if we've been looking for more than 1 second (def_max_RELOC_MARKER_time) then just quit
      double nowTime = (double)_time('F');
      if ((nowTime - origTime) > def_max_RELOC_MARKER_time) {
         break;
      }
      iterationCount++;
   }

   // now find the highest score in the hashtable of line scores
   double highestScore = -1.0;
   foreach (auto curLine => auto score in totalScores) {
      if (score > highestScore) {
         highestScore = score;
         relocLine = curLine;
      }
   }

   p_window_id.p_RLine = origLineNumber;
   _default_option(VSOPTION_WARNING_ARRAY_SIZE, old_array_size);
   if (highestScore < APPROVED_MATCH) {
      return -1;
   }

   return relocLine;
}

void tokenizeLine (_str& inLine, _str (&outLine)[])
{
   spos := 1;
   ss := "{[\\[\\]\"(){}\'.,\\-=\\*/&\\^%;:\\+<>]}";
   spos = pos(ss, inLine, spos, 'R');
   while (spos > 0) {
      before := substr(inLine, 1, spos - 1);
      middle := substr(inLine, spos, 1);
      after := substr(inLine, spos + 1);

      inLine = before' 'middle' 'after;
      spos += 2;
      spos = pos(ss, inLine, spos, 'R');
   }

   while (inLine != '') {
      inLine = strip(inLine); //Not using split, because we need to use strip()
      parse inLine with ss ' ' inLine;
      outLine[outLine._length()] = ss;
   }
}

static void minMax (double& min, double& max)
{
   if (max < min) {
      double temp;
      temp = max;
      max = min;
      min = temp;
   }
}



static double tokenStringCompare (_str (&a)[], _str (&b)[])
{
   double min = a._length();
   double max = b._length();
   minMax(min, max);
   if (!max) { //If we're matching two empty lines, they match.
      return 1.0;
   }

   double match = 0;
   int i;
   for (i = 0; i < min; ++i) {
      if (a[i] == b[i]) {
         ++match;
      }
   }

   return match/max;
}



/**
 * Levenshtein distance is also known as 'edit distance' and is
 * the measure of the minimum number of operations needed to
 * change one string into another.
 * 
 * See http://en.wikipedia.org/wiki/Levenshtein_distance for a
 * full discussion and a list of implemenations.
 */
static double levenshteinDistance (_str &a, _str &b)
{
   int d[][];
   int i, j, cost;
   int lenA = length(a);
   int lenB = length(b);

   for (i = 0; i <= lenA; ++i) {
      d[i][0] = i;
   }
   for (j = 1; j <= lenB; ++j) {
      d[0][j] = j;
   }

   for (i = 1; i <= lenA; ++i) {
      for (j = 1; j <= lenB; ++j) {
         if (substr(a,i,1) == substr(b,j,1)) {
            cost = 0;
         } else {
            cost = 1;
         }
         d[i][j] = min(min(d[i-1][j]+1, d[i][j-1]+1), d[i-1][j-1]+cost);
      }
   }

   return(double)d[lenA][lenB];
}



static double tokenLevenshteinCompare (_str (&a)[], _str (&b)[])
{
   double min = a._length();
   double max = b._length();
   minMax(min, max);
   if (!max) { //If we're matching two empty lines, they match.
      return 1.0;
   }

   double match = 0;
   int i;
   for (i = 0; i < min; ++i) {
      int maxLength = length(a[i]);
      int temp = length(b[i]);
      if (temp > maxLength) {
         maxLength = temp;
      }
      if (maxLength != 0) {
         match = match + (1 - levenshteinDistance(a[i], b[i])/maxLength);
      }
   }

   return match/max;
}



static double getWindowScore (RELOC_MARKER& lm, int lineNumber,
                              typeless compare,
                              _str (&tokenizedFile)[][])
{
   if (!lm.totalCount) {
      return 1.0;
   }
   _str line = '';
   double totalWindowScore = 0.0;
   int i;

   p_window_id.p_RLine = lineNumber;
   for (i = lm.aboveCount-1; i >= 0; --i) {
      if (up()) {
         break;
      }
      if (tokenizedFile[p_window_id.p_RLine]._isempty()) {
         get_line(line);
         tokenizeLine(line, tokenizedFile[p_window_id.p_RLine]);
      }
      totalWindowScore = totalWindowScore +
                         (*compare)(tokenizedFile[p_window_id.p_RLine], lm.textAbove[i]);
   }

   p_window_id.p_RLine = lineNumber;

   for (i = 0; i < lm.belowCount; ++i) {
      if (down()) {
         break;
      }
      if (tokenizedFile[p_window_id.p_RLine]._isempty()) {
         get_line(line);
         tokenizeLine(line, tokenizedFile[p_window_id.p_RLine]);
      }
      totalWindowScore = totalWindowScore +
                         (*compare)(tokenizedFile[p_window_id.p_RLine], lm.textBelow[i]);
   }

   p_window_id.p_RLine = lineNumber;

   return totalWindowScore/lm.totalCount;
}



static int strCompRelocate (RELOC_MARKER& lm, boolean resetTokens=false)
{
   return _RelocateMarker(lm, resetTokens, tokenStringCompare);
}



static int editDstRelocate (RELOC_MARKER& lm, boolean resetTokens=false)
{
   return _RelocateMarker(lm, resetTokens, tokenLevenshteinCompare);
}
