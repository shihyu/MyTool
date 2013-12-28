////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50084 $
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
#ifndef DIFF_SH
#define DIFF_SH

struct DIFF_UPDATE_INFO {
   int timer_handle;
   struct {
      int wid;
      boolean isdiff;
      boolean NeedToSetupHScroll;
   }list[];
};

struct MERGE_CONFLICT_INFO {
   _str ConflictArray[];
   int LastConflictNumber;
   int ResolvedArray[];
   int NumResolved;
};

typedef int (* VSPFN)();

struct DIFF_MISC_INFO {
   int DiffParentWID;
   _str Buf1StartTime;
   _str Buf2StartTime;
   int IntraLineIsOff;
   boolean DontDeleteMergeOutput;
   typeless Bookmarks;
   _str PreserveInfo;
   boolean AutoClose;
   int WholeFileBufId1;
   int MarkId1;
   int WholeFileBufId2;
   int MarkId2;
   int OrigEncoding1;
   int OrigEncoding2;
   boolean RefreshTagsOnClose;
   int TagParentIndex1;
   int TagParentIndex2;
   int SymbolViewId1;
   int SymbolViewId2;
   _str File1Date;
   _str File2Date;
   _str Comment;
   VSPFN OkPtr;
   boolean ShowNoEditorOptions;
   boolean SoftWrap1;
   boolean SoftWrap2;
};


#define    DIFF_FIRST_FILE  1
#define    DIFF_SECOND_FILE  2
#define    DIFF_UP  1
#define    DIFF_DOWN  2
#define    DIFF_GOTO_BOTTOM   -1
#define    DIFF_GOTO_TOP      -2
#define    DIFF_PAGE_UP       -3
#define    DIFF_PAGE_DOWN     -4
#define    DIFF_SET_CURSOR_Y  -5
#define    DIFF_RETURN_LINENUM  -6

#define    DIFF_DLLNAME'vsdiff.dll'

#define MATCHING_LINE 0x0
#define INSERTED_LINE 0x1
#define CHANGED_LINE  0x2
#define DELETED_LINE  0x4

#define DEFAULT_IMAGINARY_TEXT "Imaginary Buffer Line"
#define DIFFMAP_FILENAME 'diffmap.ini'

#define ASCII1            ""

#define FORCE_PROCESS_OPTIONS (DIFF_EXPAND_TABS|DIFF_IGNORE_LSPACES|DIFF_IGNORE_TSPACES|DIFF_IGNORE_SPACES|DIFF_IGNORE_CASE)
/*
#define ENCODE_STATUS_DO_NOTHING   0
#define ENCODE_STATUS_RELOAD_FILE1 1
#define ENCODE_STATUS_RELOAD_FILE2 2*/

#define DIFF_TAG_TABLE_STORE            0x1
#define DIFF_TAG_TABLE_GET_SYMBOL_START 0x2
#define DIFF_TAG_TABLE_DELETE           0x4
#define DIFF_TAG_TABLE_GET_ALL_INFO     0x8

struct MFDIFF_SETUP_INFO {
   _str FileTable1:[];
   _str FileTable2:[];
   _str Path1;
   _str Path2;
   _str OutputTable[];
   _str BasePath1;
   _str BasePath2;
   boolean recursive;
   _str Filespecs;
   _str ExcludeFilespecs;
   boolean modalOption;
   _str fileListInfo;
   _str DiffStateFilename;
   boolean ExpandFirst;
   boolean ShowNoEditorOptions;
   boolean RestoreFromINI;
};

enum DIFF_READONLY_TYPE {
   DIFF_READONLY_OFF,
   DIFF_READONLY_SET_BY_USER,
   DIFF_READONLY_SOURCEDIFF,
};

struct DIFF_SETUP_DATA {
   DIFF_READONLY_TYPE ReadOnly1;
   DIFF_READONLY_TYPE ReadOnly2;
   boolean Quiet;
   boolean Interleaved;
   boolean Modal;
   boolean File1IsBuffer;
   boolean File2IsBuffer;
   boolean NoMap;
   boolean Preserve1;
   boolean Preserve2;
   int BufferIndex1;
   int BufferIndex2;
   int ViewId1;
   int ViewId2;
   boolean ViewOnly;
   _str Comment;
   _str CommentButtonCaption;
   _str File1Title;
   _str File2Title;
   _str DialogTitle;
   _str File1Name;
   _str File2Name;
   _str FileSpec;
   _str ExcludeFileSpec;
   boolean Recursive;
   _str ImaginaryLineCaption;
   boolean AutoClose;
   int File1FirstLine;
   int File1LastLine;
   int File2FirstLine;
   int File2LastLine;
   int RecordFileWidth;
   boolean ShowAlways;
   int ParentWIDToRegister;
   typeless OkPtr;
   boolean DiffTags;
   _str FileListInfo;
   _str DiffStateFile;
   boolean CompareOnly;
   _str SaveButton1Caption;
   _str SaveButton2Caption;
   _str Symbol1Name;
   _str Symbol2Name;
   boolean SetOptionsOnly;
   _str sessionDate;
   _str sessionName;
   int compareOptions;
   int sessionID;
   boolean balanceBuffersFirst;
   boolean noSourceDiff;
}gDiffSetupData;

#define USING_MAP_DEBUG_FILE 0

_str def_max_diffhist='10 10 10 10';

struct MERGE_DIALOG_INFO {
   _str DialogTitle;
   _str BaseDocname;
   _str Rev1Docname;
   _str Rev2Docname;
   _str OutputDocName;
};

struct MERGE_PIC_INFO {
   int Rev1;
   int Rev2;
   int Output;
};

#define DIFFEDIT_CONST_FILES_MATCH            1
#define DIFFEDIT_CONST_BUFFER_INFO1           2
#define DIFFEDIT_CONST_BUFFER_INFO2           3
#define DIFFEDIT_CONST_BUFFER_INFO2           3
#define DIFFEDIT_CONST_FILE_TITLES            4
#define DIFFEDIT_CONST_LAST_VSCROLL           5
#define DIFFEDIT_CONST_LAST_HSCROLL           6
#define DIFFEDIT_CONST_NEED_REFRESH           7
#define DIFFEDIT_CONST_MISC_INFO              8
#define DIFFEDIT_CONST_FILE_LABELS_MISSING    9
#define DIFFEDIT_CONST_LINENUM_LABELS_MISSING 10
#define DIFFEDIT_CONST_READONLY_CB_MISSING    11
#define DIFFEDIT_CONST_LINE_NEXT_DIFF_MISSING 12
#define DIFFEDIT_CONST_CLOSE_MISSING          13
#define DIFFEDIT_CONST_COPY_MISSING           14
#define DIFFEDIT_CONST_READONLY_SET1          15
#define DIFFEDIT_CONST_READONLY_SET2          16
#define DIFFEDIT_CONST_HAS_MODIFY             17
#define DIFFEDIT_CONST_FILE1_MODIFY           18
#define DIFFEDIT_CONST_FILE2_MODIFY           19
#define DIFFEDIT_CONST_FORM_SIZE              20
#define DIFFEDIT_VC_DIFF_TYPE                 21
#define DIFFEDIT_CODE_DIFF                    22
#define DIFFEDIT_READONLY1_VALUE              23
#define DIFFEDIT_READONLY2_VALUE              24
#define DIFFEDIT_CONST_COPY_LEFT_MISSING      25



struct MERGE_SETUP_DATA {
   _str BaseFilename;
   boolean BaseIsBuffer;
   int BaseBufferId;
   int BaseViewId;

   _str Rev1Filename;
   boolean Rev1IsBuffer;
   int Rev1BufferId;
   int Rev1ViewId;

   _str Rev2Filename;
   boolean Rev2IsBuffer;
   int Rev2BufferId;
   int Rev2ViewId;

   _str OutputFilename;
   boolean OutputIsBuffer;
   int OutputBufferId;
   int OutputViewId;

   boolean Smart;
   boolean Interleaved;
   boolean Quiet;
   boolean CallerSaves;
   boolean ForceConflict;
   boolean ShowChanges;
   _str Copy1Caption;
   _str Copy2Caption;
   boolean IndividualConflictUndo;
   _str Copy1AllCaption;
   _str Copy2AllCaption;
   boolean IgnoreSpaces;
   _str ImaginaryLineCaption;
}gMergeSetupData;


/**
 * Diff two buffers and mark/balance them so that they can be displayed,
 * or output an interleaved buffer ( there is also a boolean option )
 *
 * @param iViewId1  First window to diff
 * @param iViewId2  Second window to diff
 * @param iOptions  Combination of DIFF_* flags
 * @param iNumDiffOutputs
 *                  Number of interleaved outputs there already are for this diff
 * @param Reserved1
 * @param Reserved2
 * @param LoadOptions
 *                  Load options.  Used when creating interleaved output
 * @param iGaugeWid Window id of gauge control.  Use 0 if you do not have a gauge control
 * @param OutputBufId
 *                  Gets set to the output buffer if this is an interleaved diff
 * @param MaxFastFileSize
 *                  Maximum file size (in K) to do a fast diff on.  This keeps more information in memory while performing the diff
 * @param pszLineRange1
 *                  Line range for the first file.  Use format "Firstline-Lastline".  This is used to skip comments at the top of files
 * @param pszLineRange2
 *                  Line range for the second file.  Use format "Firstline-Lastline".  This is used to skip comments at the top of files
 * @param iSmartDiffLimit
 *                  Maximum number of lines to attempt to re-sync over
 * @param pszImaginaryText
 *                  Text to use for imaginary buffer lines.  Use null for default
 *
 * @return 0 if successful. This does not reflect whether or not the files matched, call DiffLastFilesMatched() to check that
 */
extern int Diff(int iViewId1,int iViewId2,int iOptions,
         int iNumDiffOutputs,int Reserved1,int Reserved2,
         _str LoadOptions,int iGaugeWid,int &OutputBufId,
         int MaxFastFileSize,
         _str pszLineRange1,_str pszLineRange2,
         int iSmartDiffLimit,
         _str pszImaginaryText);

struct DiffToken {
   long seek;
   int linenum;
   int len;
   int color;
};

extern int DiffFilesMatched();
extern int DiffTokensMatched();
extern void DiffInsertImaginaryBufferLine();
extern void DiffSetImaginaryBufferLineText(_str);
extern int MergeNumConflicts();
extern int MergeNumShowChanges();
extern int MergeFiles(int,int,int,int,int,typeless&,typeless&,_str,typeless&,typeless&);
extern void DiffFreeAllColorInfo(int buf_id);
extern void DiffTextChangeCallback(int,int);
extern void DiffClearAllColorInfo(int);
extern int  FastCompare(int,long,int,long,...);
extern int  DiffUpdateColorInfo(int WID1,int iLineNum1,int WID2,int iLineNum2,int iSplitBadMatches,int iSetLineFlags,boolean bLineIsModified,boolean bNoScrollMarkerUpdate);
extern void DiffIntraLineColoring(int,int);
extern int DiffGetNextDifference(int,int);
extern int _DiffTagInitKey(_str,boolean);
extern int _DiffTagStoreInfo(_str,_str,int,int,int,...);
extern int _DiffTagGetTagName(_str,int,typeless&);
extern int _DiffTagGetTagNameFromLineNumber(_str,int,typeless&);
extern int _DiffTagTagExists(_str,_str,typeless&);
extern int _DiffTagGetLineInfo(_str,_str,typeless&,typeless&);
extern void _DiffTagDeleteInfo(_str);
extern int _DiffTagGetInitDestLine(_str,_str,_str,typeless&);
extern void _DiffGetMatchVector(typeless&);
extern _command void vsvcs_version();
extern int _DiffGetFileTable(_str,_str &filespecList,_str &excludeFilespecList,int recursive,_str (&table):[],int ProgressGageWID);
extern int _DiffTokens(int WID1,int WID2);
extern int _DiffGetTokenInfo(int,DiffToken (&tokenList)[]);
extern int _DiffClearFileTokens(int WID);
extern int _DiffGetTokenMatches(int (&tokenMatches)[]);
/**
 * @param file1_wid WID for first file being diffed/balanced
 * @param file2_wid WID for second file being diffed/balanced
 * @param balancedCode set to true if any balancing action was 
 *                     performed
 * 
 * @return int 0 if sucessful
 */
int _DiffBalanceCode(int file1_wid,int file2_wid,boolean &balancedFiles);
extern int _DiffBalanceFiles(int file1_wid,int file2_wid,boolean &balancedFiles,int gaugeWID);
#define DIFF_SCROLLMARKER_MODIFIED 1
#define DIFF_SCROLLMARKER_INSERTED 2
#define DIFF_SCROLLMARKER_DELETED  3
extern int _DiffScrollMarkerType(int type);

struct DIFF_DELETE_ITEM{
   int item;
   boolean isView;
   boolean isSuspended;
};

#endif
