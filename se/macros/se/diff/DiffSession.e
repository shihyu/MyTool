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
#include "diff.sh"
#include "plugin.sh"
#include "xml.sh"
#require "se/datetime/DateTime.e"
#import "cfg.e"
#import "main.e"
#import "stdprocs.e"
#import "varedit.e"
#import "xmldoc.e"
#endregion


/**
 * The "se.diff" namespace contains interfaces and classes that 
 * are necessary for managing diff information within SlickEdit.
 */
namespace se.diff;

using namespace se.datetime;

class DiffSessionCollection :
sc.lang.IAssignTo {
   private DIFF_SETUP_DATA m_sessionData[];
   private _str m_dataFilename = "";
   private int m_xmlhandle = -1;
   private int m_numUnnamedSessions = 0;
   private bool m_needToSave = false;

   DiffSessionCollection(int numUnnamedSessions=def_diff_num_sessions){
      m_numUnnamedSessions = numUnnamedSessions;
   }

   // Only protos that are necessary because of ordering
   void enumerateSessionIDs(STRARRAY &sessionsIDs);
   DIFF_SETUP_DATA getSession(_str sessionID);

   ~DiffSessionCollection() {
      closeDiffSessionFile();
   }

   static _str getDefaultSessionName() {return "[unnamed]";}

   private _str getSessionsName() {return "Sessions";}

   private _str getSingleSessionName() {return "OneSession";}

   private _str getNameAttrName() {return "n";}

   private _str getValueAttrName() {return "v";}

   private _str getSessionIDAttrName() {return "SessionId";}

   private _str getPropertyName() {return "p";}

   /**
    * @param sessionName current session name
    * 
    * @return _str <B>sessionName</B> if it is not blank, default 
    *         session name otherwise
    */
   private _str getSessionName(_str sessionName) {
      if ( sessionName=="" ) {
         sessionName = getDefaultSessionName();
      }
      return sessionName;
   }

   /**
    * @return _str default session filename
    */
   private _str findDataFilename() {
      path := _ConfigPath();
      path :+= "diffsession.xml";
      return path;
   }

   /**
    * Append a session in memory 
    *  
    * @param curSession Session to append
    */
   private void appendSession(DIFF_SETUP_DATA &curSession) {
      m_sessionData[m_sessionData._length()] = curSession;
      m_needToSave = true;
   }

   /** 
    * Get handle to open session file
    * 
    * @param filename default 
    *                 will be (<config>/<version>/diffsession.xml)
    * @param opened set to true if the file was opened and not just 
    *               the handle returned
    * 
    * @return int handle of file
    */
   private int openDiffSessionFile(_str filename="",bool &opened=false) {
      opened=false;
      do {
         origHandle := m_xmlhandle;
         if ( m_xmlhandle<0 ) {
            filename = getDataFilename(filename);
            if ( filename=="" ) break;
            m_xmlhandle = _xmlcfg_open(filename,auto status);
            if ( status==FILE_NOT_FOUND_RC ) {
               m_xmlhandle = _xmlcfg_create(filename,VSENCODING_UTF8);
            }
         }
         opened = m_xmlhandle!=origHandle;
      } while (false);
      return m_xmlhandle;
   }

   /**
    * Load a session from disk into <B>diffSetupData</B>
    * 
    * @param xmlhandle handle of file
    * @param curIndex index to load session from
    * @param diffSetupData struct to load session into
    */
   private void loadOneSession(int xmlhandle,int curIndex,DIFF_SETUP_DATA &diffSetupData) {
      initSessionData(diffSetupData);
      getDiffSetupStruct(curIndex,diffSetupData,xmlhandle);
   }

   /**
    * Get all properties under <B>sessionIndex</B>
    * 
    * @param sessionIndex session index in xml file
    * @param diffSessionData sessionData to be filled in
    */
   private void getDiffSetupStruct(int curIndex,DIFF_SETUP_DATA &diffSessionData,int xmlhandle=-1) {
      getProperty(curIndex,"ReadOnly1",diffSessionData.file1.readOnly,0,xmlhandle);
      getProperty(curIndex,"ReadOnly2",diffSessionData.file2.readOnly,0,xmlhandle);
      getProperty(curIndex,"Quiet",diffSessionData.Quiet,0,xmlhandle);
      getProperty(curIndex,"Interleaved",diffSessionData.Interleaved,0,xmlhandle);
      getProperty(curIndex,"Modal",diffSessionData.Modal,0,xmlhandle);
      getProperty(curIndex,"File1IsBuffer",diffSessionData.file1.isBuffer,0,xmlhandle);
      getProperty(curIndex,"File2IsBuffer",diffSessionData.file2.isBuffer,0,xmlhandle);
      getProperty(curIndex,"File1UseDisk",diffSessionData.file1.useDisk,0,xmlhandle);
      if ( diffSessionData.file1.useDisk=="" ) diffSessionData.file1.useDisk = false;
      getProperty(curIndex,"File2UseDisk",diffSessionData.file2.useDisk,0,xmlhandle);
      if ( diffSessionData.file2.useDisk=="" ) diffSessionData.file2.useDisk = false;
      getProperty(curIndex,"NoMap",diffSessionData.NoMap,0,xmlhandle);
      getProperty(curIndex,"Preserve1",diffSessionData.file1.preserve,0,xmlhandle);
      getProperty(curIndex,"Preserve2",diffSessionData.file2.preserve,0,xmlhandle);
      getProperty(curIndex,"BufferIndex1",diffSessionData.file1.bufferIndex,-1,xmlhandle);
      getProperty(curIndex,"BufferIndex2",diffSessionData.file2.bufferIndex,-1,xmlhandle);
      getProperty(curIndex,"ViewId1",diffSessionData.file1.viewID,0,xmlhandle);
      getProperty(curIndex,"ViewId2",diffSessionData.file2.viewID,0,xmlhandle);
      getProperty(curIndex,"ViewOnly",diffSessionData.ViewOnly,0,xmlhandle);
      getProperty(curIndex,"Comment",diffSessionData.Comment,"",xmlhandle);
      getProperty(curIndex,"CommentButtonCaption",diffSessionData.CommentButtonCaption,"",xmlhandle);
      getProperty(curIndex,"File1Title",diffSessionData.file1.fileTitle,"",xmlhandle);
      getProperty(curIndex,"File2Title",diffSessionData.file2.fileTitle,"",xmlhandle);
      getProperty(curIndex,"DialogTitle",diffSessionData.DialogTitle,"DIFFzilla® Pro",xmlhandle);
      getProperty(curIndex,"File1Name",diffSessionData.file1.fileName,"",xmlhandle);
      getProperty(curIndex,"File2Name",diffSessionData.file2.fileName,"",xmlhandle);
      getProperty(curIndex,"FileSpec",diffSessionData.FileSpec,"",xmlhandle);
      getProperty(curIndex,"ExcludeFileSpec",diffSessionData.ExcludeFileSpec,"",xmlhandle);
      getProperty(curIndex,"Recursive",diffSessionData.Recursive,0,xmlhandle);
      getProperty(curIndex,"ImaginaryLineCaption",diffSessionData.ImaginaryLineCaption,"Imaginary Buffer Line",xmlhandle);
      getProperty(curIndex,"AutoClose",diffSessionData.AutoClose,0,xmlhandle);
      getProperty(curIndex,"File1FirstLine",diffSessionData.file1.firstLine,0,xmlhandle);
      getProperty(curIndex,"File1LastLine",diffSessionData.file1.lastLine,0,xmlhandle);
      getProperty(curIndex,"File2FirstLine",diffSessionData.file2.firstLine,0,xmlhandle);
      getProperty(curIndex,"File2LastLine",diffSessionData.file2.lastLine,0,xmlhandle);
      getProperty(curIndex,"RecordFileWidth",diffSessionData.RecordFileWidth,0,xmlhandle);
      getProperty(curIndex,"ShowAlways",diffSessionData.ShowAlways,0,xmlhandle);
      getProperty(curIndex,"ParentWIDToRegister",diffSessionData.ParentWIDToRegister,0,xmlhandle);
      getProperty(curIndex,"OkPtr",diffSessionData.OkPtr,"",xmlhandle);
      getProperty(curIndex,"DiffTags",diffSessionData.DiffTags,0,xmlhandle);
      getProperty(curIndex,"FileListInfo",diffSessionData.FileListInfo,"",xmlhandle);
      getProperty(curIndex,"DiffStateFile",diffSessionData.DiffStateFile,"",xmlhandle);
      getProperty(curIndex,"CompareOnly",diffSessionData.CompareOnly,0,xmlhandle);
      getProperty(curIndex,"SaveButton1Caption",diffSessionData.SaveButton1Caption,"",xmlhandle);
      getProperty(curIndex,"SaveButton2Caption",diffSessionData.SaveButton2Caption,"",xmlhandle);
      getProperty(curIndex,"Symbol1Name",diffSessionData.file1.symbolName,"",xmlhandle);
      getProperty(curIndex,"Symbol2Name",diffSessionData.file2.symbolName,"",xmlhandle);
      getProperty(curIndex,"SetOptionsOnly",diffSessionData.SetOptionsOnly,0,xmlhandle);
      getProperty(curIndex,"sessionDate",diffSessionData.sessionDate,"",xmlhandle);
      getProperty(curIndex,"sessionName",diffSessionData.sessionName,"[unnamed]",xmlhandle);
      diffSessionData.sessionID = _xmlcfg_get_attribute(m_xmlhandle,curIndex,getSessionIDAttrName());
      getProperty(curIndex,"compareOptions",diffSessionData.compareOptions,655360,xmlhandle);
      getProperty(curIndex,"fileListFile",diffSessionData.fileListFile,"",xmlhandle);
      getProperty(curIndex,"runInForeground",diffSessionData.runInForeground,0,xmlhandle);
   }

   /**
    * Set all properties under <B>sessionIndex</B>
    * 
    * @param sessionIndex session index in xml file
    * @param diffSessionData sessionData to be written
    */
   private void setAllProperties(int sessionIndex,DIFF_SETUP_DATA &diffSessionData,int xmlhandle=-1) {
      setProperty(sessionIndex,"ReadOnly1",diffSessionData.file1.readOnly,xmlhandle,"0");
      setProperty(sessionIndex,"ReadOnly2",diffSessionData.file2.readOnly,xmlhandle,"0");
      setProperty(sessionIndex,"Quiet",diffSessionData.Quiet,xmlhandle,"0");
      setProperty(sessionIndex,"Interleaved",diffSessionData.Interleaved,xmlhandle,"0");
      setProperty(sessionIndex,"Modal",diffSessionData.Modal,xmlhandle,"0");
      setProperty(sessionIndex,"File1IsBuffer",diffSessionData.file1.isBuffer,xmlhandle,"0");
      setProperty(sessionIndex,"File2IsBuffer",diffSessionData.file2.isBuffer,xmlhandle,"0");
      setProperty(sessionIndex,"File1UseDisk",diffSessionData.file1.useDisk,xmlhandle,"0");
      setProperty(sessionIndex,"File2UseDisk",diffSessionData.file2.useDisk,xmlhandle,"0");
      setProperty(sessionIndex,"NoMap",diffSessionData.NoMap,xmlhandle,"0");
      setProperty(sessionIndex,"Preserve1",diffSessionData.file1.preserve,xmlhandle,"0");
      setProperty(sessionIndex,"Preserve2",diffSessionData.file2.preserve,xmlhandle,"0");
      setProperty(sessionIndex,"BufferIndex1",diffSessionData.file1.bufferIndex,xmlhandle,"-1");
      setProperty(sessionIndex,"BufferIndex2",diffSessionData.file2.bufferIndex,xmlhandle,"-1");
      setProperty(sessionIndex,"ViewId1",diffSessionData.file1.viewID,xmlhandle,"0");
      setProperty(sessionIndex,"ViewId2",diffSessionData.file2.viewID,xmlhandle,"0");
      setProperty(sessionIndex,"ViewOnly",diffSessionData.ViewOnly,xmlhandle,"0");
      setProperty(sessionIndex,"Comment",diffSessionData.Comment,xmlhandle,"");
      setProperty(sessionIndex,"CommentButtonCaption",diffSessionData.CommentButtonCaption,xmlhandle,"");
      setProperty(sessionIndex,"File1Title",diffSessionData.file1.fileTitle,xmlhandle,"");
      setProperty(sessionIndex,"File2Title",diffSessionData.file2.fileTitle,xmlhandle,"");
      setProperty(sessionIndex,"DialogTitle",diffSessionData.DialogTitle,xmlhandle,"DIFFzilla® Pro");
      setProperty(sessionIndex,"File1Name",diffSessionData.file1.fileName,xmlhandle,"");
      setProperty(sessionIndex,"File2Name",diffSessionData.file2.fileName,xmlhandle,"");
      setProperty(sessionIndex,"FileSpec",diffSessionData.FileSpec,xmlhandle,"");
      setProperty(sessionIndex,"ExcludeFileSpec",diffSessionData.ExcludeFileSpec,xmlhandle,"");
      setProperty(sessionIndex,"Recursive",diffSessionData.Recursive,xmlhandle,"0");
      setProperty(sessionIndex,"ImaginaryLineCaption",diffSessionData.ImaginaryLineCaption,xmlhandle,"Imaginary Buffer Line");
      setProperty(sessionIndex,"AutoClose",diffSessionData.AutoClose,xmlhandle,"0");
      setProperty(sessionIndex,"File1FirstLine",diffSessionData.file1.firstLine,xmlhandle,"0");
      setProperty(sessionIndex,"File1LastLine",diffSessionData.file1.lastLine,xmlhandle,"0");
      setProperty(sessionIndex,"File2FirstLine",diffSessionData.file2.firstLine,xmlhandle,"0");
      setProperty(sessionIndex,"File2LastLine",diffSessionData.file2.lastLine,xmlhandle,"0");
      setProperty(sessionIndex,"RecordFileWidth",diffSessionData.RecordFileWidth,xmlhandle,"0");
      setProperty(sessionIndex,"ShowAlways",diffSessionData.ShowAlways,xmlhandle,"0");
      setProperty(sessionIndex,"ParentWIDToRegister",diffSessionData.ParentWIDToRegister,xmlhandle,"0");
      setProperty(sessionIndex,"OkPtr",diffSessionData.OkPtr,xmlhandle,"");
      setProperty(sessionIndex,"DiffTags",diffSessionData.DiffTags,xmlhandle,"0");
      setProperty(sessionIndex,"FileListInfo",diffSessionData.FileListInfo,xmlhandle,"");
      setProperty(sessionIndex,"DiffStateFile",diffSessionData.DiffStateFile,xmlhandle,"");
      setProperty(sessionIndex,"CompareOnly",diffSessionData.CompareOnly,xmlhandle,"0");
      setProperty(sessionIndex,"SaveButton1Caption",diffSessionData.SaveButton1Caption,xmlhandle,"");
      setProperty(sessionIndex,"SaveButton2Caption",diffSessionData.SaveButton2Caption,xmlhandle,"");
      setProperty(sessionIndex,"Symbol1Name",diffSessionData.file1.symbolName,xmlhandle,"");
      setProperty(sessionIndex,"Symbol2Name",diffSessionData.file2.symbolName,xmlhandle,"");
      setProperty(sessionIndex,"SetOptionsOnly",diffSessionData.SetOptionsOnly,xmlhandle,"0");
      setProperty(sessionIndex,"sessionName",diffSessionData.sessionName,xmlhandle,"[unnamed]");
      setProperty(sessionIndex,"sessionDate",diffSessionData.sessionDate,xmlhandle,"");
      setProperty(sessionIndex,"compareOptions",diffSessionData.compareOptions,xmlhandle,"0");
      setProperty(sessionIndex,"fileListFile",diffSessionData.fileListFile,xmlhandle,"");
      setProperty(sessionIndex,"runInForeground",diffSessionData.runInForeground,xmlhandle,"0");
   }

   /**
    * Limit the number of unnamed sessions.  Remove the oldest
    * N-m_numUnnamedSessions sessions
    */
   private void pruneUnnamedSessions() {
      mod := false;
      xmlhandle := openDiffSessionFile();
      int sessionIDsToDelete[];
      do {
         this.enumerateSessionIDs(auto sessionIDs);
         if ( sessionIDs._length()>m_numUnnamedSessions ) {
            numDefaultSessions := 0;
            foreach ( auto curSessionIndex => auto curSessionID in sessionIDs ) {
               curSession := this.getSession(curSessionID);
               if ( curSession.sessionName==getDefaultSessionName() ) {
                  ++numDefaultSessions;
                  if ( numDefaultSessions>=m_numUnnamedSessions ) {
                     sessionIDsToDelete[sessionIDsToDelete._length()] = curSessionIndex;
                  }
               }
            }
            // Have to sort indexes decending so that we delete from the bottom of
            // the array and indexes don't change
            sessionIDsToDelete._sort('DN');
            foreach ( auto curIDToDelete in sessionIDsToDelete ) {
               m_sessionData._deleteel(curIDToDelete);
            }
         }
      } while ( false );
      m_needToSave = true;
   }

   public void copy (sc.lang.IAssignTo& dest)/*IAssignTo*/ {
      ((DiffSessionCollection)dest).m_dataFilename = this.m_dataFilename;
      ((DiffSessionCollection)dest).m_sessionData  = this.m_sessionData;
      ((DiffSessionCollection)dest).m_xmlhandle    = -1;
   }

   /**
    * @param filename filename that would be used
    * 
    * @return _str <b>filename</b> if it is not "", otherwise 
    *         default filename
    */
   private _str getDataFilename(_str filename="") {
      if ( filename!="" ) {
         m_dataFilename = filename;
      } else if ( m_dataFilename=="" ) {
         m_dataFilename = findDataFilename();
      }
      return m_dataFilename;
   }

   /**
    * Close the xml file
    *  
    * @return int 0 if successful
    */
   int closeDiffSessionFile() {
      status := 0;
      if ( m_xmlhandle>-1 ) {
         status = _xmlcfg_close(m_xmlhandle);
         m_xmlhandle = -1;
      }
      return status;
   }

   /**
    * Load sessions from disk from default filename
    * (<config>/<version>/diffsession.xml) 
    *  
    * @param filename alternate filename to load from
    * 
    * @return int 0 if successful
    */
   int loadSessions(_str filename="") {
      status := 0;
      xmlhandle := openDiffSessionFile(filename);

      do {
         if ( xmlhandle<0 ) {
            status = xmlhandle;
            break;
         }
         // First load from diffsession.xml
         _xmlcfg_find_simple_array(xmlhandle,'/':+getSessionsName():+'/':+getSingleSessionName(),auto indexArray);

         foreach ( auto curIndex in indexArray ) {
            curName := _xmlcfg_get_attribute(xmlhandle,(int)curIndex,getNameAttrName());
            loadOneSession(xmlhandle,(int)curIndex,auto curDiffSetupData);
            curDiffSetupData.sessionName = curName;
            appendSession(curDiffSetupData);
         }
      } while (false);


      return status;
   }

   static void initFileData(DIFF_SETUP_FILE_DATA &file) {
      file.readOnly=DIFF_READONLY_OFF;
      file.isBuffer=false;
      file.preserve=false;
      file.bufferIndex=-1;
      file.viewID=0;
      file.fileTitle='';
      file.fileName='';
      file.firstLine=0;
      file.lastLine=0;
      file.symbolName='';
      file.rangeSpecified=false;
      file.getBufferIndex=false;
      file.isViewID=false;
      file.tryDisk=0;
      file.bufferState=-1;
      file.useDisk=false;
      file.isCopiedBuffer=false;
   }

   /**
    * @param diffSetupData struct to initialize
    */
   static void initSessionData(DIFF_SETUP_DATA &diffSetupData) {
      diffSetupData=null;
      initFileData(diffSetupData.file1);
      initFileData(diffSetupData.file2);
      diffSetupData.Quiet=false;
      diffSetupData.Interleaved=false;
      diffSetupData.Modal=false;
      diffSetupData.NoMap=false;
      diffSetupData.ViewOnly=false;
      diffSetupData.Comment='';
      diffSetupData.CommentButtonCaption='';
      if ( _haveProDiff() ) {
         diffSetupData.DialogTitle="DIFFzilla"VSREGISTEREDTM" Pro";
      } else {
         diffSetupData.DialogTitle="DIFFzilla"VSREGISTEREDTM" Standard";
      }
      diffSetupData.FileSpec='';
      diffSetupData.ExcludeFileSpec='';
      diffSetupData.Recursive=false;
      diffSetupData.ImaginaryLineCaption='Imaginary Buffer Line';
      diffSetupData.AutoClose=false;
      diffSetupData.RecordFileWidth=0;
      diffSetupData.ShowAlways=false;
      diffSetupData.ParentWIDToRegister=0;
      diffSetupData.OkPtr='';
      diffSetupData.DiffTags=false;
      diffSetupData.FileListInfo='';
      diffSetupData.DiffStateFile='';
      diffSetupData.CompareOnly=false;
      diffSetupData.SaveButton1Caption='';
      diffSetupData.SaveButton2Caption='';
      diffSetupData.SetOptionsOnly=false;
      diffSetupData.sessionDate="";
      diffSetupData.sessionName="";
      diffSetupData.sessionID=-1;
      diffSetupData.compareOptions=0;
      diffSetupData.balanceBuffersFirst=false;
      diffSetupData.noSourceDiff=false;
      diffSetupData.VerifyMFDInput=0;
      diffSetupData.dialogWidth = MAXINT;
      diffSetupData.dialogHeight = MAXINT;
      diffSetupData.dialogX = MAXINT;
      diffSetupData.dialogY = MAXINT;
      diffSetupData.windowState = "";
      diffSetupData.specifiedSourceDiffOnCommandLine = false;
      diffSetupData.posMarkerID = -1;
      diffSetupData.vcType = "";
      diffSetupData.matchMode2 = false;
      diffSetupData.gotDataFromFile = false;
      diffSetupData.usedGlobalData = false;
      diffSetupData.fileListFile = "";
      diffSetupData.compareFilenamesOnly = false;
      diffSetupData.isvsdiff = false;
      diffSetupData.pointToGoto = -1;
      diffSetupData.runInForeground = false;
   }

   /**
    * Set a property <B>name</B> from the currently open xmlfile 
    * under index 
    * <B>curSessionNode</B>.  Store value in <B>value</B>
    * 
    * @param curSessionNode node to look for property under
    * @param name name of property to set
    * @param value value of property
    */
   private void setProperty(int curSessionNode,_str name,typeless value,int xmlhandle=-1,_str defaultValue="") {
      if ( xmlhandle==-1 ) xmlhandle = m_xmlhandle;
      if ( value!=defaultValue ) {
         propertyNode := _xmlcfg_add(xmlhandle,curSessionNode,getPropertyName(),VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(xmlhandle,propertyNode,getNameAttrName(),name,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(xmlhandle,propertyNode,getValueAttrName(),value,VSXMLCFG_ADD_AS_CHILD);
         m_needToSave = true;
      }
   }

   /**
    * Get a property <B>name</B> from the currently open xmlfile 
    * under index 
    * <B>curSessionNode</B>.  Store value in <B>value</B>
    * 
    * @param curSessionNode index to look for property under
    * @param name name of property
    * @param value variable that value of property gets stored in
    */
   private void getProperty(int curSessionNode,_str name,typeless &value,typeless defaultVal,int xmlhandle=-1) {
      if ( xmlhandle==-1 ) xmlhandle = m_xmlhandle;
      value = defaultVal;
      index := _xmlcfg_find_simple(xmlhandle,'p[@n="':+name:+'"]',curSessionNode);
      if ( index>-1 ) {
         value = _xmlcfg_get_attribute(xmlhandle,index,getValueAttrName());
      }
   }

   /**
    * Find an unnamed session that is the same as diffSession
    * 
    * @return int index into m_sessionData if found, -1 if not 
    *         found
    */
   private int findUnnamedSession(DIFF_SETUP_DATA &diffSession) {
      existingSessionIndex := -1;

      foreach ( auto curIndex => auto curSession in m_sessionData ) {
         if ( curSession.sessionName == getDefaultSessionName()
              && getSessionName(diffSession.sessionName) == getDefaultSessionName()
              && _file_eq(curSession.file1.fileName,diffSession.file1.fileName)
              && _file_eq(curSession.file2.fileName,diffSession.file2.fileName)
              && curSession.file1.symbolName == diffSession.file1.symbolName
              && curSession.file2.symbolName == diffSession.file2.symbolName
              && curSession.FileSpec ==  diffSession.FileSpec
              && curSession.ExcludeFileSpec  ==  diffSession.ExcludeFileSpec
              && curSession.Recursive ==  diffSession.Recursive
              && curSession.Interleaved  ==  diffSession.Interleaved
              && curSession.DiffTags  ==  diffSession.DiffTags
              && curSession.runInForeground  ==  diffSession.runInForeground
            ) {
            existingSessionIndex = (int)curIndex;
            break;
         }
      }
      return existingSessionIndex;
   }

   /** 
    * Save sessions to default filename 
    * (<config>/<version>/diffsession.xml) 
    * 
    * @param filename optional filename to save.
    * 
    * @return int 0 if successful
    */
   int saveSessions(_str filename="") {
      status := 0;
      do {
         if ( !m_needToSave ) break;
         xmlhandle := openDiffSessionFile();
         if ( xmlhandle>-1 ) {
            sessionsIndex := _xmlcfg_get_first_child(xmlhandle,TREE_ROOT_INDEX);
            if ( sessionsIndex<0 ) {
               sessionsIndex = _xmlcfg_add(xmlhandle,TREE_ROOT_INDEX,getSessionsName(),VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
            }
            // First save unnamed sessions to diffsession.xml
            _xmlcfg_delete(xmlhandle,sessionsIndex,true);
            pruneUnnamedSessions();
            addFlags := VSXMLCFG_ADD_AS_CHILD;
            relativeIndex := sessionsIndex;
            foreach ( auto curIndex => auto curDiffSetupData in m_sessionData ) {
               curDiffSetupData.sessionName = getSessionName(curDiffSetupData.sessionName);
               curSessionIndex := _xmlcfg_add(xmlhandle,relativeIndex,getSingleSessionName(),VSXMLCFG_NODE_ELEMENT_START_END,addFlags);
               _xmlcfg_set_attribute(xmlhandle,curSessionIndex,getNameAttrName(),curDiffSetupData.sessionName);
               _xmlcfg_set_attribute(xmlhandle,curSessionIndex,getSessionIDAttrName(),curIndex+1);
               setAllProperties(curSessionIndex,curDiffSetupData);
               addFlags = VSXMLCFG_ADD_AFTER;
               relativeIndex = curSessionIndex;
            }
            status = _xmlcfg_save(xmlhandle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
         } else {
            status = xmlhandle;
         }
         m_needToSave = false;
      } while ( false );
      return status;
   }

   /**
    * @param sessionID ID of session to get
    * 
    * @return DIFF_SETUP_DATA Session specified by <B>sessionID</B> 
    *         , null if <B>sessionID</B> does not exist
    */
   DIFF_SETUP_DATA getSession(_str sessionID) {
      returnSessionData := null;
      foreach ( auto curSessionData in m_sessionData ) {
         if ( curSessionData.sessionID=="" ) {
            if ( curSessionData.sessionName==sessionID ) {
               returnSessionData = curSessionData;
               break;
            }
         } else if ( curSessionData.sessionID==sessionID ) {
            returnSessionData = curSessionData;
            break;
         }
      }
      return returnSessionData;
   }

   /**
    * @param sessionsIDs filled in with all valid session IDs
    */
   void enumerateSessionIDs(STRARRAY &sessionsIDs) {
      sessionsIDs = null;
      foreach ( auto curSessionData in m_sessionData ) {
         if ( curSessionData.sessionID!="" ) {
            sessionsIDs[sessionsIDs._length()] = curSessionData.sessionID;
         } else {
            sessionsIDs[sessionsIDs._length()] = curSessionData.sessionName;
         }
      }
   }

   /**
    * Add a session in memory
    * 
    * @param diffSetupData session to add
    * @param sessionName Name of session to add
    *  
    * @return new session ID 
    */
   int addSession(DIFF_SETUP_DATA &diffSessionData,_str sessionName="") {
      if ( diffSessionData.sessionDate=="" ) {
         se.datetime.DateTime currentDateTime;
         diffSessionData.sessionDate = currentDateTime.toString();
      }
      unnamedSessionIndex := findUnnamedSession(diffSessionData);
#if 0
      /** Not safe to delete sessions here. Could be deleting 
          the lastSessionID tracked by the tree. This code is
          really bad because it pretty much ALWAYS delets the
          lastSessionID which causes a Slick-C stack
          when you press the "Save..." button to save session.
      */
       
      unnamedSessionIndex := findUnnamedSession(diffSessionData);
      if ( unnamedSessionIndex>-1 ) {
         m_sessionData._deleteel(unnamedSessionIndex);
      }
#endif
      diffSessionData.sessionName = sessionName;
      diffSessionData.sessionID = getNextSessionID();
      m_sessionData._insertel(diffSessionData,0);
      m_needToSave = true;
      return diffSessionData.sessionID;
   }

   void replaceSession(DIFF_SETUP_DATA &diffSessionData,_str sessionID) {
      foreach ( auto curDiffSessionIndex => auto curDiffSession in m_sessionData ) {
         if ( curDiffSession.sessionID == sessionID ) {
            // Reinsert at top
            m_sessionData._deleteel(curDiffSessionIndex);

            diffSessionData.sessionID = curDiffSession.sessionID;
            se.datetime.DateTime currentDateTime;
            diffSessionData.sessionDate = currentDateTime.toString();

            m_sessionData._insertel(diffSessionData,0);
         }
      }
      m_needToSave = true;
   }

   private int getNextSessionID() {
      nextSessionID := -1;
      foreach ( auto curDiffSession in m_sessionData ) {
         if ( curDiffSession.sessionID > nextSessionID ) {
            nextSessionID = curDiffSession.sessionID;
         }
      }
      return nextSessionID+1;
   }

   /**
    * @return bool true if session <B>sessionName</B> exists
    */
   bool sessionExists(_str sessionName,_str &sessionID=-1) {
      sessionExists := false;
      xmlhandle := openDiffSessionFile();

      this.enumerateSessionIDs(auto sessionIDs);
      foreach ( auto curSessionID in sessionIDs ) {
         curSession := this.getSession(curSessionID);
         if ( curSession.sessionName == sessionName ) {
            sessionID = curSessionID;
            sessionExists = true;
            break;
         }
      }
      return sessionExists;
   }

   /**
    * Delete session <B>sessionID</B> from memory 
    *  
    * @param sessionID session to delete
    * 
    * @return int 0 if successful, STRING_NOT_FOUND_RC if no 
    *         matching session is found
    */
   int deleteSession(_str sessionID) {
      status := STRING_NOT_FOUND_RC;
      xmlhandle := openDiffSessionFile("",auto opened=false);
      do {
         if ( xmlhandle<0 ) {
            status = xmlhandle;
            break;
         }
         if ( opened ) {
            this.loadSessions();
         }
         foreach ( auto curIndex => auto curSession in m_sessionData ) {
            if ( (curSession.sessionID=="" && curSession.sessionName==sessionID) || 
                 curSession.sessionID==sessionID ) {
               m_sessionData._deleteel(curIndex);
               status = 0;
               break;
            }
         }
         if ( !status ) {
            //this.saveSessions();
         }
         m_needToSave = true;
      } while ( false );
      return status;
   }
};
