////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#include "xml.sh"
#import "main.e"
#import "se/datetime/DateTime.e"
#import "stdprocs.e"
#import "varedit.e"
#endregion


/**
 * The "se.diff" namespace contains interfaces and classes that 
 * are necessary for managing diff information within SlickEdit.
 */
namespace se.diff;

using namespace se.datetime;
#define PROPERTY_NAME "Property"

class DiffSessionColletction :
   sc.lang.IAssignTo
{
   private DIFF_SETUP_DATA m_sessionData[];
   private _str m_dataFilename = "";
   private int m_xmlhandle = -1;
   private int m_numUnnamedSessions = 0;
   private boolean m_needToSave = false;

   DiffSessionColletction(int numUnnamedSessions=def_diff_num_sessions){
      m_numUnnamedSessions = numUnnamedSessions;
   }

   // Only protos that are necessary because of ordering
   void enumerateSessionIDs(INTARRAY &sessionsIDs);
   DIFF_SETUP_DATA getSession(int sessionID);

   ~DiffSessionColletction() {
      closeDiffSessionFile();
   }

   static _str getDefaultSessionName() {return "[unnamed]";}

   private _str getSessionsName() {return "Sessions";}
   
   private _str getSingleSessionName() {return "OneSession";}

   private _str getNameAttrName() {return "Name";}

   private _str getValueAttrName() {return "Value";}

   private _str getSessionIDAttrName() {return "SessionId";}

   private _str getPropertyName() {return "Property";}

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
   private int openDiffSessionFile(_str filename="",boolean &opened=false) {
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
      getDiffSetupStruct(curIndex,diffSetupData);
   }

   /**
    * Get all properties under <B>sessionIndex</B>
    * 
    * @param sessionIndex session index in xml file
    * @param diffSessionData sessionData to be filled in
    */
   private void getDiffSetupStruct(int curIndex,DIFF_SETUP_DATA &diffSessionData) {
      getProperty(curIndex,"ReadOnly1",diffSessionData.ReadOnly1);
      getProperty(curIndex,"ReadOnly2",diffSessionData.ReadOnly2);
      getProperty(curIndex,"Quiet",diffSessionData.Quiet);
      getProperty(curIndex,"Interleaved",diffSessionData.Interleaved);
      getProperty(curIndex,"Modal",diffSessionData.Modal);
      getProperty(curIndex,"File1IsBuffer",diffSessionData.File1IsBuffer);
      getProperty(curIndex,"File2IsBuffer",diffSessionData.File2IsBuffer);
      getProperty(curIndex,"NoMap",diffSessionData.NoMap);
      getProperty(curIndex,"Preserve1",diffSessionData.Preserve1);
      getProperty(curIndex,"Preserve2",diffSessionData.Preserve2);
      getProperty(curIndex,"BufferIndex1",diffSessionData.BufferIndex1);
      getProperty(curIndex,"BufferIndex2",diffSessionData.BufferIndex2);
      getProperty(curIndex,"ViewId1",diffSessionData.ViewId1);
      getProperty(curIndex,"ViewId2",diffSessionData.ViewId2);
      getProperty(curIndex,"ViewOnly",diffSessionData.ViewOnly);
      getProperty(curIndex,"Comment",diffSessionData.Comment);
      getProperty(curIndex,"CommentButtonCaption",diffSessionData.CommentButtonCaption);
      getProperty(curIndex,"File1Title",diffSessionData.File1Title);
      getProperty(curIndex,"File2Title",diffSessionData.File2Title);
      getProperty(curIndex,"DialogTitle",diffSessionData.DialogTitle);
      getProperty(curIndex,"File1Name",diffSessionData.File1Name);
      getProperty(curIndex,"File2Name",diffSessionData.File2Name);
      getProperty(curIndex,"FileSpec",diffSessionData.FileSpec);
      getProperty(curIndex,"ExcludeFileSpec",diffSessionData.ExcludeFileSpec);
      getProperty(curIndex,"Recursive",diffSessionData.Recursive);
      getProperty(curIndex,"ImaginaryLineCaption",diffSessionData.ImaginaryLineCaption);
      getProperty(curIndex,"AutoClose",diffSessionData.AutoClose);
      getProperty(curIndex,"File1FirstLine",diffSessionData.File1FirstLine);
      getProperty(curIndex,"File1LastLine",diffSessionData.File1LastLine);
      getProperty(curIndex,"File2FirstLine",diffSessionData.File2FirstLine);
      getProperty(curIndex,"File2LastLine",diffSessionData.File2LastLine);
      getProperty(curIndex,"RecordFileWidth",diffSessionData.RecordFileWidth);
      getProperty(curIndex,"ShowAlways",diffSessionData.ShowAlways);
      getProperty(curIndex,"ParentWIDToRegister",diffSessionData.ParentWIDToRegister);
      getProperty(curIndex,"OkPtr",diffSessionData.OkPtr);
      getProperty(curIndex,"DiffTags",diffSessionData.DiffTags);
      getProperty(curIndex,"FileListInfo",diffSessionData.FileListInfo);
      getProperty(curIndex,"DiffStateFile",diffSessionData.DiffStateFile);
      getProperty(curIndex,"CompareOnly",diffSessionData.CompareOnly);
      getProperty(curIndex,"SaveButton1Caption",diffSessionData.SaveButton1Caption);
      getProperty(curIndex,"SaveButton2Caption",diffSessionData.SaveButton2Caption);
      getProperty(curIndex,"Symbol1Name",diffSessionData.Symbol1Name);
      getProperty(curIndex,"Symbol2Name",diffSessionData.Symbol2Name);
      getProperty(curIndex,"SetOptionsOnly",diffSessionData.SetOptionsOnly);
      getProperty(curIndex,"sessionDate",diffSessionData.sessionDate);
      getProperty(curIndex,"sessionName",diffSessionData.sessionName);
      diffSessionData.sessionID = _xmlcfg_get_attribute(m_xmlhandle,curIndex,getSessionIDAttrName());
      getProperty(curIndex,"compareOptions",diffSessionData.compareOptions);
   }

   /**
    * Set all properties under <B>sessionIndex</B>
    * 
    * @param sessionIndex session index in xml file
    * @param diffSessionData sessionData to be written
    */
   private void setAllProperties(int sessionIndex,DIFF_SETUP_DATA &diffSessionData) {
      setProperty(sessionIndex,"ReadOnly1",diffSessionData.ReadOnly1);
      setProperty(sessionIndex,"ReadOnly2",diffSessionData.ReadOnly2);
      setProperty(sessionIndex,"Quiet",diffSessionData.Quiet);
      setProperty(sessionIndex,"Interleaved",diffSessionData.Interleaved);
      setProperty(sessionIndex,"Modal",diffSessionData.Modal);
      setProperty(sessionIndex,"File1IsBuffer",diffSessionData.File1IsBuffer);
      setProperty(sessionIndex,"File2IsBuffer",diffSessionData.File2IsBuffer);
      setProperty(sessionIndex,"NoMap",diffSessionData.NoMap);
      setProperty(sessionIndex,"Preserve1",diffSessionData.Preserve1);
      setProperty(sessionIndex,"Preserve2",diffSessionData.Preserve2);
      setProperty(sessionIndex,"BufferIndex1",diffSessionData.BufferIndex1);
      setProperty(sessionIndex,"BufferIndex2",diffSessionData.BufferIndex2);
      setProperty(sessionIndex,"ViewId1",diffSessionData.ViewId1);
      setProperty(sessionIndex,"ViewId2",diffSessionData.ViewId2);
      setProperty(sessionIndex,"ViewOnly",diffSessionData.ViewOnly);
      setProperty(sessionIndex,"Comment",diffSessionData.Comment);
      setProperty(sessionIndex,"CommentButtonCaption",diffSessionData.CommentButtonCaption);
      setProperty(sessionIndex,"File1Title",diffSessionData.File1Title);
      setProperty(sessionIndex,"File2Title",diffSessionData.File2Title);
      setProperty(sessionIndex,"DialogTitle",diffSessionData.DialogTitle);
      setProperty(sessionIndex,"File1Name",diffSessionData.File1Name);
      setProperty(sessionIndex,"File2Name",diffSessionData.File2Name);
      setProperty(sessionIndex,"FileSpec",diffSessionData.FileSpec);
      setProperty(sessionIndex,"ExcludeFileSpec",diffSessionData.ExcludeFileSpec);
      setProperty(sessionIndex,"Recursive",diffSessionData.Recursive);
      setProperty(sessionIndex,"ImaginaryLineCaption",diffSessionData.ImaginaryLineCaption);
      setProperty(sessionIndex,"AutoClose",diffSessionData.AutoClose);
      setProperty(sessionIndex,"File1FirstLine",diffSessionData.File1FirstLine);
      setProperty(sessionIndex,"File1LastLine",diffSessionData.File1LastLine);
      setProperty(sessionIndex,"File2FirstLine",diffSessionData.File2FirstLine);
      setProperty(sessionIndex,"File2LastLine",diffSessionData.File2LastLine);
      setProperty(sessionIndex,"RecordFileWidth",diffSessionData.RecordFileWidth);
      setProperty(sessionIndex,"ShowAlways",diffSessionData.ShowAlways);
      setProperty(sessionIndex,"ParentWIDToRegister",diffSessionData.ParentWIDToRegister);
      setProperty(sessionIndex,"OkPtr",diffSessionData.OkPtr);
      setProperty(sessionIndex,"DiffTags",diffSessionData.DiffTags);
      setProperty(sessionIndex,"FileListInfo",diffSessionData.FileListInfo);
      setProperty(sessionIndex,"DiffStateFile",diffSessionData.DiffStateFile);
      setProperty(sessionIndex,"CompareOnly",diffSessionData.CompareOnly);
      setProperty(sessionIndex,"SaveButton1Caption",diffSessionData.SaveButton1Caption);
      setProperty(sessionIndex,"SaveButton2Caption",diffSessionData.SaveButton2Caption);
      setProperty(sessionIndex,"Symbol1Name",diffSessionData.Symbol1Name);
      setProperty(sessionIndex,"Symbol2Name",diffSessionData.Symbol2Name);
      setProperty(sessionIndex,"SetOptionsOnly",diffSessionData.SetOptionsOnly);
      setProperty(sessionIndex,"sessionName",diffSessionData.sessionName);
      setProperty(sessionIndex,"sessionDate",diffSessionData.sessionDate);
      setProperty(sessionIndex,"compareOptions",diffSessionData.compareOptions);
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
      ((DiffSessionColletction)dest).m_dataFilename = this.m_dataFilename;
      ((DiffSessionColletction)dest).m_sessionData  = this.m_sessionData;
      ((DiffSessionColletction)dest).m_xmlhandle    = -1;
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
      }else if ( m_dataFilename=="" ) {
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
   
   /**
    * @param diffSetupData struct to initialize
    */
   static void initSessionData(DIFF_SETUP_DATA &diffSetupData) {
      diffSetupData=null;
      diffSetupData.ReadOnly1=DIFF_READONLY_OFF;
      diffSetupData.ReadOnly2=DIFF_READONLY_OFF;
      diffSetupData.Quiet=false;
      diffSetupData.Interleaved=false;
      diffSetupData.Modal=false;
      diffSetupData.File1IsBuffer=false;
      diffSetupData.File2IsBuffer=false;
      diffSetupData.NoMap=false;
      diffSetupData.Preserve1=false;
      diffSetupData.Preserve2=false;
      diffSetupData.BufferIndex1=-1;
      diffSetupData.BufferIndex2=-1;
      diffSetupData.ViewId1=0;
      diffSetupData.ViewId2=0;
      diffSetupData.ViewOnly=false;
      diffSetupData.Comment='';
      diffSetupData.CommentButtonCaption='';
      diffSetupData.File1Title='';
      diffSetupData.File2Title='';
      diffSetupData.DialogTitle='';
      diffSetupData.File1Name='';
      diffSetupData.File2Name='';
      diffSetupData.FileSpec='';
      diffSetupData.ExcludeFileSpec='';
      diffSetupData.Recursive=false;
      diffSetupData.ImaginaryLineCaption='Imaginary Buffer Line';
      diffSetupData.AutoClose=false;
      diffSetupData.File1FirstLine=0;
      diffSetupData.File1LastLine=0;
      diffSetupData.File2FirstLine=0;
      diffSetupData.File2LastLine=0;
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
      diffSetupData.Symbol1Name='';
      diffSetupData.Symbol2Name='';
      diffSetupData.SetOptionsOnly=false;
      diffSetupData.sessionDate="";
      diffSetupData.sessionName="";
      diffSetupData.sessionID=-1;
      diffSetupData.compareOptions=0;
      diffSetupData.balanceBuffersFirst=false;
      diffSetupData.noSourceDiff=false;
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
   private void setProperty(int curSessionNode,_str name,typeless value) {
      propertyNode := _xmlcfg_add(m_xmlhandle,curSessionNode,getPropertyName(),VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(m_xmlhandle,propertyNode,getNameAttrName(),name,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(m_xmlhandle,propertyNode,getValueAttrName(),value,VSXMLCFG_ADD_AS_CHILD);
      m_needToSave = true;
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
   private void getProperty(int curSessionNode,_str name,typeless &value) {
      value = "";
      index := _xmlcfg_find_simple(m_xmlhandle,"Property[@Name='":+name:+"']",curSessionNode);
      if ( index>-1 ) {
         value = _xmlcfg_get_attribute(m_xmlhandle,index,getValueAttrName());
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
              && file_eq(curSession.File1Name,diffSession.File1Name)
              && file_eq(curSession.File2Name,diffSession.File2Name)
              && curSession.Symbol1Name == diffSession.Symbol1Name
              && curSession.Symbol2Name == diffSession.Symbol2Name
              && curSession.FileSpec ==  diffSession.FileSpec
              && curSession.ExcludeFileSpec  ==  diffSession.ExcludeFileSpec
              && curSession.Recursive ==  diffSession.Recursive
              && curSession.Interleaved  ==  diffSession.Interleaved
              && curSession.DiffTags  ==  diffSession.DiffTags
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
   int saveSessions(_str filenname="") {
      status := 0;
      do {
         if ( !m_needToSave ) break;
         xmlhandle := openDiffSessionFile();
         if ( xmlhandle>-1 ) {
             sessionsIndex := _xmlcfg_get_first_child(xmlhandle,TREE_ROOT_INDEX);
             if ( sessionsIndex<0 ) {
                 sessionsIndex = _xmlcfg_add(xmlhandle,TREE_ROOT_INDEX,getSessionsName(),VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
             }
             _xmlcfg_delete(xmlhandle,sessionsIndex,true);
             pruneUnnamedSessions();
             addFlags := VSXMLCFG_ADD_AS_CHILD;
             relativeIndex := sessionsIndex;
             foreach ( auto curIndex => auto curDiffSetupData in m_sessionData ) {
                 curSessionIndex := _xmlcfg_add(xmlhandle,relativeIndex,getSingleSessionName(),VSXMLCFG_NODE_ELEMENT_START_END,addFlags);
                 curDiffSetupData.sessionName = getSessionName(curDiffSetupData.sessionName);
                 _xmlcfg_set_attribute(xmlhandle,curSessionIndex,getNameAttrName(),curDiffSetupData.sessionName);
                 _xmlcfg_set_attribute(xmlhandle,curSessionIndex,getSessionIDAttrName(),curIndex+1);
                 setAllProperties(curSessionIndex,curDiffSetupData);
                 addFlags = VSXMLCFG_ADD_AFTER;
                 relativeIndex = curSessionIndex;
             }
             status = _xmlcfg_save(xmlhandle,-1,VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
         }else{
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
   DIFF_SETUP_DATA getSession(int sessionID) {
      returnSessionData := null;
      foreach ( auto curSessionData in m_sessionData ) {
         if ( curSessionData.sessionID==sessionID ) {
            returnSessionData = curSessionData;
            break;
         }
      }
      return returnSessionData;
   }

   /**
    * @param sessionsIDs filled in with all valid session IDs
    */
   void enumerateSessionIDs(INTARRAY &sessionsIDs) {
      sessionsIDs = null;
      foreach ( auto curSessionData in m_sessionData ) {
         sessionsIDs[sessionsIDs._length()] = curSessionData.sessionID;
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
      if ( unnamedSessionIndex>-1 ) {
         m_sessionData._deleteel(unnamedSessionIndex);
      }
      diffSessionData.sessionName = sessionName;
      diffSessionData.sessionID = getNextSessionID();
      m_sessionData._insertel(diffSessionData,0);
      m_needToSave = true;
      return diffSessionData.sessionID;
   }

   void replaceSession(DIFF_SETUP_DATA &diffSessionData,int sessionID) {
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
    * @return boolean true if session <B>sessionName</B> exists
    */
   boolean sessionExists(_str sessionName,int &sessionID=-1) {
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
   int deleteSession(int sessionID) {
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
            if ( curSession.sessionID==sessionID ) {
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
