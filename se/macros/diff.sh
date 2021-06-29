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
#pragma option(metadata,"diff.e")

struct DIFF_UPDATE_INFO {
   int timer_handle;
   struct {
      int wid;
      bool isdiff;
      bool NeedToSetupHScroll;
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
   bool DontDeleteMergeOutput;
   typeless Bookmarks;
   _str PreserveInfo;
   bool AutoClose;
   int WholeFileBufId1;
   bool origReadOnly1;
   int MarkId1;
   int WholeFileBufId2;
   bool origReadOnly2;
   int MarkId2;
   int OrigEncoding1;
   int OrigEncoding2;
   bool RefreshTagsOnClose;
   int TagParentIndex1;
   int TagParentIndex2;
   int SymbolViewId1;
   int SymbolViewId2;
   _str File1Date;
   _str File2Date;
   _str Comment;
   VSPFN OkPtr;
   bool ShowNoEditorOptions;
   bool SoftWrap1;
   bool SoftWrap2;
   bool closeBuffer2;
   _str deleteBufferList;
};

const DIFFMAP_FILENAME= 'diffmap.ini';

const ASCII1=            "";

struct MFDIFF_SETUP_INFO {
   _str FileTable1:[];
   _str FileTable2:[];
   _str Path1;
   _str Path2;
   _str OutputTable[];
   _str BasePath1;
   _str BasePath2;
   bool recursive;
   _str Filespecs;
   _str ExcludeFilespecs;
   bool modalOption;
   _str fileListInfo;
   _str DiffStateFilename;
   bool ExpandFirst;
   bool ShowNoEditorOptions;
   bool RestoreFromINI;
};

enum DIFF_READONLY_TYPE {
   DIFF_READONLY_OFF,
   DIFF_READONLY_SET_BY_USER,
   DIFF_READONLY_SOURCEDIFF,
};

struct DIFF_SETUP_FILE_DATA {
   DIFF_READONLY_TYPE readOnly;
   bool isBuffer;
   bool preserve;
   int bufferIndex;
   int viewID;
   _str fileTitle;
   _str fileName;
   int firstLine;
   int lastLine;
   _str symbolName;
   bool rangeSpecified;
   // get bufferIndex from the filename
   bool getBufferIndex;    
   bool isViewID;
   int tryDisk;
   int bufferState;
   bool useDisk;
   bool isCopiedBuffer;
};

struct DIFF_SETUP_DATA {
   DIFF_SETUP_FILE_DATA file1;
   DIFF_SETUP_FILE_DATA file2;
   bool Quiet;
   bool Interleaved;
   bool Modal;
   bool NoMap;
   bool ViewOnly;
   _str Comment;
   _str CommentButtonCaption;
   _str DialogTitle;
   _str FileSpec;
   _str ExcludeFileSpec;
   bool Recursive;
   _str ImaginaryLineCaption;
   bool AutoClose;
   int RecordFileWidth;
   bool ShowAlways;
   int ParentWIDToRegister;
   typeless OkPtr;
   bool DiffTags;
   _str FileListInfo;
   _str DiffStateFile;
   bool CompareOnly;
   _str SaveButton1Caption;
   _str SaveButton2Caption;
   bool SetOptionsOnly;
   _str sessionDate;
   _str sessionName;
   int compareOptions;
   int sessionID;
   bool balanceBuffersFirst;
   bool noSourceDiff;
   int VerifyMFDInput;
   int dialogWidth;
   int dialogHeight;
   int dialogX;
   int dialogY;
   _str windowState;
   bool specifiedSourceDiffOnCommandLine;
   int posMarkerID;
   _str vcType;
   _str matchMode2;
   bool gotDataFromFile;
   bool usedGlobalData;
   _str fileListFile;
   bool compareFilenamesOnly;
   bool isvsdiff;
   typeless pointToGoto;
   bool runInForeground;
};

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

const DIFFEDIT_CONST_FILES_MATCH=            1;
const DIFFEDIT_CONST_BUFFER_INFO1=           2;
const DIFFEDIT_CONST_BUFFER_INFO2=           3;
const DIFFEDIT_CONST_FILE_TITLES=            4;
const DIFFEDIT_CONST_LAST_VSCROLL=           5;
const DIFFEDIT_CONST_LAST_HSCROLL=           6;
const DIFFEDIT_CONST_NEED_REFRESH=           7;
const DIFFEDIT_CONST_MISC_INFO=              8;
const DIFFEDIT_CONST_FILE_LABELS_MISSING=    9;
const DIFFEDIT_CONST_LINENUM_LABELS_MISSING= 10;
const DIFFEDIT_CONST_READONLY_CB_MISSING=    11;
const DIFFEDIT_CONST_LINE_NEXT_DIFF_MISSING= 12;
const DIFFEDIT_CONST_CLOSE_MISSING=          13;
const DIFFEDIT_CONST_COPY_MISSING=           14;
const DIFFEDIT_CONST_READONLY_SET1=          15;
const DIFFEDIT_CONST_READONLY_SET2=          16;
const DIFFEDIT_CONST_HAS_MODIFY=             17;
const DIFFEDIT_CONST_FILE1_MODIFY=           18;
const DIFFEDIT_CONST_FILE2_MODIFY=           19;
const DIFFEDIT_CONST_FORM_SIZE=              20;
const DIFFEDIT_VC_DIFF_TYPE=                 21;
const DIFFEDIT_CODE_DIFF=                    22;
const DIFFEDIT_READONLY1_VALUE=              23;
const DIFFEDIT_READONLY2_VALUE=              24;
const DIFFEDIT_CONST_COPY_LEFT_MISSING=      25;

const DIFFEDIT_CONST_BUFFER_IS_DIFFED= "IsDiffed";

struct MERGE_SETUP_DATA {
   _str BaseFilename;
   bool BaseIsBuffer;
   int BaseBufferId;
   int BaseViewId;

   _str Rev1Filename;
   bool Rev1IsBuffer;
   int Rev1BufferId;
   int Rev1ViewId;

   _str Rev2Filename;
   bool Rev2IsBuffer;
   int Rev2BufferId;
   int Rev2ViewId;

   _str OutputFilename;
   bool OutputIsBuffer;
   int OutputBufferId;
   int OutputViewId;

   bool Smart;
   bool Interleaved;
   bool Quiet;
   bool CallerSaves;
   bool ForceConflict;
   bool ShowChanges;
   _str Copy1Caption;
   _str Copy2Caption;
   bool IndividualConflictUndo;
   _str Copy1AllCaption;
   _str Copy2AllCaption;
   bool IgnoreSpaces;
   _str ImaginaryLineCaption;
}gMergeSetupData;

struct DIFF_ALIGN {
   long pos1;
   long pos2;
   long lineNum1;
   long lineNum2;
   int markid1;   // May not be set if we don't have this information yet
   int markid2;   // May not be set if we don't have this information yet
};

struct DIFF_INFO {
    /**
     * First window to diff
     */
    int iViewID1;
    /**
     * Second window to diff
     */
    int iViewID2;
    /**
     * Combination of DIFF_* flags
     */
    int iOptions;
    /**
     * Number of interleaved outputs there already are for this diff
     */
    int iNumDiffOutputs;
    /**
     * Is this source diff (aka token diff)?
     */
    bool iIsSourceDiff;
    /**
     * Load options.  Used when creating interleaved output. 
     * @see def_load_options
     */
    _str loadOptions;
    /**
     * Window id of gauge control.  Use 0 if you do not have a gauge control
     */
    int iGaugeWID;
    /**
     * Maximum file size (in K) to do a fast diff on. 
     * This keeps more information in memory while performing the diff. 
     * @see def_max_fast_diff_size 
     */
    int iMaxFastFileSize;
    /**
     * Line range for the first file.  Use format "Firstline-Lastline". 
     * This is used to skip comments at the top of files
     */
    _str lineRange1;
    /**
     * Line range for the second file.  Use format "Firstline-Lastline". 
     * This is used to skip comments at the top of files
     */
    _str lineRange2;
    /**
     * Maximum number of lines to attempt to re-sync over. 
     * @see def_smart_diff_limit 
     */
    int iSmartDiffLimit;
    /**
     * Text to use for imaginary buffer lines.  Use null for default.
     */
    _str imaginaryText;
    /**
     * 
     */
    DIFF_ALIGN alignments[];
    /**
     * When using source diff, this array specifies a list of token 
     * exclusion mappings to indicate that certain token differences can be 
     * treated as if they were merely whitespace.  This is helpful when a large 
     * number of symbols have been renamed and you are trying to compare files 
     * to find more significant changes. 
     *  
     * Each item in the array is of the form: 
     * <pre>
     *    left_token_text;right_token_text
     * </pre> 
     * Duplicate entries are allowed.
     *  
     * This option is ignored when 'iIsSourceDiff' is false.
     */
    _str tokenExclusionMappings[];
    bool balanceBuffers;
    _str langID2;
};

/**
 * Diff two buffers and mark/balance them so that they can be displayed,
 * or output an interleaved buffer ( there is also a boolean option )
 *  
 * @param info          instance of DIFF_INFO struct, populated with options 
 * @param OutputBufId   Gets set to the output buffer if this is an interleaved diff
 *
 * @return 0 if successful. 
 *         This does not reflect whether or not the files matched;
 *         call DiffLastFilesMatched() to check that.  Unless
 *         DIFF_OUTPUT_BOOLEAN is specified, then a 0 means the
 *         files do not match and 1 means that they did. Error
 *         codes will be negative.
 */
extern int Diff(DIFF_INFO info,int &OutputBufId=0);
extern void SEDiffFreeInfo(int diffHandle);
extern int SEDiffFilesMatch(int diffHandle);
extern void SEDiffSetMarkersForFlags(int sourceWID, int destWID, int modifiedMarkerType,int insertedMarkerType);
extern void SEDiffSetFlagsFromMarkers(int sourceWID, int destWID, int modifiedMarkerType,int insertedMarkerType);
extern int SEDiffGetChecksum(int iWID,int &checksum);

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
/** 
 * Compares two views. Will try to look up columns (can be 
 * expensive).  If there are no options or columns set, will use 
 * <B>FastBinaryCompare</B>.  If you know there are no columns 
 * set, use <B>FastBinaryCompare</B>. 
 * 
 * @param int WID1 First window ID to compare
 * @param long seekPos1 Seeek position to start comparing from 
 *             in <B>WID1</B>
 * @param int WID2 First window ID to compare
 * @param long seekPos2 Seeek position to start comparing from 
 *             in <B>WID2</B>
 * @param int options combination of the following flags: 
 * <ul> 
 * <LI>DIFF_EXPAND_TABS</LI>
 * <LI>DIFF_IGNORE_LSPACES</LI>
 * <LI>DIFF_IGNORE_TSPACES</LI>
 * <LI>DIFF_IGNORE_SPACES</LI>
 * <LI>DIFF_IGNORE_CASE</LI>
 * <LI>DIFF_OUTPUT_INTERLEAVED</LI>
 * <LI>DIFF_DONT_COMPARE_EOL_CHARS</LI>
 * <LI>DIFF_OUTPUT_BOOLEAN</LI>
 * <LI>DIFF_LEADING_SKIP_COMMENTS</LI>
 * </ul>
 * 
 * @return int 0 if text in windows match
 */
extern int FastCompare(int WID1,long seekPos1,int WID2,long seekPos2,int options);

/** 
 * Compares two views.  Uses no options or columns.
 * 
 * @param int WID1 First window ID to compare
 * @param long seekPos1 Seeek position to start comparing from 
 *             in <B>WID1</B>
 * @param int WID2 First window ID to compare
 * @param long seekPos2 Seeek position to start comparing from 
 *             in <B>WID2</B>
 * 
 * @return int 0 if text in windows match
 */
extern int  FastBinaryCompare(int WID1,long seekPos1,int WID2,long seekPos2);
extern int  FastRawFileCompare(_str filename1,_str filename2);
extern int  DiffUpdateColorInfo(int WID1,int iLineNum1,int WID2,int iLineNum2,int iSplitBadMatches,int iSetLineFlags,bool bLineIsModified,bool bNoScrollMarkerUpdate);
extern void DiffIntraLineColoring(int,int);
extern int DiffGetNextDifference(int fileNumber,int findFirst,int diffHandle);
extern int _DiffTagInitKey(_str,bool);
extern int _DiffTagStoreInfo(_str,_str,int,int,int,...);
extern int _DiffTagGetTagName(_str key,int tagNumber,typeless &tagName);
extern int _DiffTagGetTagNameFromLineNumber(_str key,int lineNumber,typeless &tagName);
extern int _DiffTagTagExists(_str,_str,typeless&);
extern int _DiffTagGetLineInfo(_str key,_str tagName,typeless &startLine,typeless &endLine);
extern void _DiffTagDeleteInfo(_str);
extern int _DiffTagGetInitDestLine(_str,_str,_str,typeless&);
extern void _DiffGetMatchVector(typeless&);
extern _command void vsvcs_version();
extern int _DiffGetFileTable(_str,_str &filespecList,_str &excludeFilespecList,int recursive,_str (&table):[],int ProgressGageWID);
extern int _DiffGetTokenInfo(int,DiffToken (&tokenList)[]);
extern int _DiffClearFileTokens(int WID);
extern int _DiffGetTokenMatches(int (&tokenMatches)[]);
extern int _DiffClearLineFlags();
/**
 * @param file1_wid WID for first file being diffed/balanced
 * @param file2_wid WID for second file being diffed/balanced
 * @param balancedCode set to true if any balancing action was performed
 * 
 * @return int 0 if sucessful
 */
int _DiffBalanceCode(int file1_wid,int file2_wid,bool &balancedFiles);
/** 
 *  
 * @param file1_wid WID for first file being diffed/balanced
 * @param file2_wid WID for second file being diffed/balanced
 * @param balancedCode set to true if any balancing action was performed
 * @param gaugeWID progress guage window ID
 * @param comment_flags diff flags for whether to skip comments or not
 * @param tokenExclusionMapping array of strings for token mapping
 * 
 * @return int 0 if sucessful
 */
extern int _DiffBalanceFiles(int file1_wid,int file2_wid,bool &balancedFiles,int gaugeWID,...);
const DIFF_SCROLLMARKER_MODIFIED= 1;
const DIFF_SCROLLMARKER_INSERTED= 2;
const DIFF_SCROLLMARKER_DELETED=  3;

struct DiffMarkup{
   int markupType;
   long seekpos;
   long len;
};

extern int _DiffScrollMarkerType(int type);
extern void SEDiffGetSourceMarkup(int diffhandle,DiffMarkup (&markup)[]);
extern void SEDiffFreeBalanceInfo(int);

struct DIFF_DELETE_ITEM{
   int item;
   bool isView;
   bool isSuspended;
};

const DIFF_LEVEL_MODIFIED=1;
const DIFF_LEVEL_INSERTED=2;
const DIFF_LEVEL_DELETED =3;

const LOCAL_FILE_CAPTION = "Local File";

enum MFDiffThreadStatus {
   MFDIFF_STATUS_FILES_MATCH        = 0,
   MFDIFF_STATUS_FILES_DIFFERENT    = 1,
   MFDIFF_STATUS_FILE_ONLY_IN_PATH1 = 2,
   MFDIFF_STATUS_FILE_ONLY_IN_PATH2 = 3,
};

struct FileComparePair {
   _str filename1;
   _str fileDate1;
   _str filename2;
   _str fileDate2;
   int status;
};


extern int _DiffThreadedMFDiff(_str path1,_str path2,_str filespecs,_str excludeFilespecs,int options, bool recursive,_str fileListFilename);
extern int _DiffThreadedIsRunning();
extern int _DiffThreadedGetOutput(FileComparePair (&fileCompareTable)[], int maxItems=5000);
extern void _DiffThreadedCancel();
extern int _DiffThreadedIsListingFiles();
extern int _DiffThreadedIsDiffingFiles();
extern int _DiffThreadedGetNumFiles();
extern int _DiffThreadedClose();
extern int _DiffThreadedNoFilesFound();
extern int _DiffThreadedGetMissingPaths(STRARRAY &missingPaths,int which);

struct DIFF_SETUP_INFO {
   _str path1;             //Just a path if using MFDiff
   _str path2;
   _str filespec;          //'' if not using mutlti-file diff
   _str excludeFilespec;   //'' if not using mutlti-file diff
   bool recursive;      //Only matters if using mutlti-file diff
   bool smartDiff;      //Only matters if NOT USING mutlti-file diff...Probably won't matter at all
   bool interleaved;    //Only matters if NOT USING mutlti-file diff
   int recordWidth;        //Only matters if NOT USING mutlti-file diff
   bool file1IsFile;    //Only matters if NOT USING mutlti-file diff
   bool file2IsFile;    //Only matters if NOT USING mutlti-file diff
   int firstline1;
   int firstline2;
   int lastline1;
   int lastline2;
   bool buf1;           //Only matters if NOT USING mutlti-file diff
   bool buf2;           //Only matters if NOT USING mutlti-file diff
   _str fileListInfo;      //If not blank, this information is for the "-listonly" option
                           //format: -listonly output_filename path1filelist|path2filelist [differentfiles|vieweddifferentfiles|matchingfiles|filesnotinpath1|filesnotinpath2][,nextoption]
   bool compareAllSymbols;
   bool compareOnly;
   bool restoreFromINI;
   bool Range2Specified;
   _str fileListFilename;  // Filename of a list file.  List file is relative paths
                           // that will be appended to each path to get filenames.
   bool compareFilenamesOnly;
   bool runInForeground;
   bool balanceBuffers;
};
static const FILE_TABLE_DELIM=      "\t";
