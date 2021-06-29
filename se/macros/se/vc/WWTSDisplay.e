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
#include "markers.sh"
#require "sc/lang/Timer.e"
#import "sc/editor/TempEditor.e"
#require "IWWTSIdentifier.e"
#import "WWTSLine.e"
#import "WWTSFile.e"
#import "stdprocs.e"
#import "WWTSUserIdentifier.e"
#import "VersionMap.e"
#import "WWTSCVSTagIdentifier.e"
#import "WWTSModel.e"
#import "varedit.e"
#import "diffedit.e"
#import "slickc.e"
#import "math.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class WWTSDisplay {
   private IWWTSIdentifier m_identifiers:[/*schemeName*/]=null;
   private int m_lineDisplayInfo:[/*filename*/][/*indexList*/]=null;
   private _str m_bufferSchemeTable:[/*filename*/]=null;
   private WWTS_VERSION_LIST_INFO m_versionListInfo:[/*filename*/]:[/*caption*/]=null;
   private int m_markerTypes:[]=null;

   WWTSDisplay() {
   }
   ~WWTSDisplay() {
      foreach ( auto htindex => auto markerType in m_markerTypes ) {
         _MarkerTypeFree(markerType);
      }
      m_markerTypes = null;
   }

   private int getMarkerType(_str filename) {
      type := m_markerTypes:[_file_case(filename)];
      if ( type==null ) {
         type = m_markerTypes:[_file_case(filename)] = _MarkerTypeAlloc();
         _MarkerTypeSetFlags(type,VSMARKERTYPEFLAG_DRAW_BOX);
      }
      return type;
   }

   void addIdentifier(IWWTSIdentifier identifier,_str schemeName) {
      m_identifiers:[schemeName] = identifier;
   }

   IWWTSIdentifier getIdentifier(_str schemeName) {
      return m_identifiers:[schemeName];
   }

   void setIdentifier(_str schemeName,IWWTSIdentifier curID) {
      m_identifiers:[schemeName] = curID;
   }

   public void removeIdentifier(_str schemeName) {
      m_identifiers._deleteel(schemeName);
   }

   STRARRAY getDisplayIdentifierList() {
      STRARRAY IDList;
      foreach ( auto curSchemeName => auto curValue in m_identifiers ) {
         IDList[IDList._length()] = curSchemeName;
      }
      return IDList;
   }

   /**
    * Remove all identfiers
    */
   public void clearIdentifiers() {
      m_identifiers = null;
      m_lineDisplayInfo = null;
   }

   private void clearMarkers(_str filename) {
      casedFilename := _file_case(filename);
      if ( m_lineDisplayInfo:[casedFilename]!=null ) {
         foreach ( auto markerID in m_lineDisplayInfo:[casedFilename] ) {
            if ( markerID>=0 ) {
               _StreamMarkerRemove(markerID);
            }
         }
         m_lineDisplayInfo._deleteel(casedFilename);
      }
   }

   int displayAllLineInfo(_str filename,_str schemeName) {
      status := 0;
      //#define PROFILEWWTS                                                        
#ifdef PROFILEWWTS
      profile("on");
#endif 
      displayedOneLine := false;
      mou_hour_glass(true);
      do {
         specifiedID := getIdentifier(schemeName);

         clearMarkers(filename);

         WWTSFile curFile = WWTSModel.getFile(filename);
         if ( curFile == null ) {
            status = -1;
            break;
         }

         sc.editor.TempEditor tempEditor(filename);
         if ( tempEditor.getStatus() ) break;
         //p_window_id=tempEditor.getWindowID();

         noflines := tempEditor.getWindowID().p_Noflines;
         //say('displayAllLineInfo noflines='noflines);
         numIDs := m_identifiers._length();
         markerType := getMarkerType(filename);
         for ( i:=1;i<=noflines;++i ) {
            //message('displayAllLineInfo i='i);
            status = curFile.getLineInfo(i,auto pLineInfo);
            if ( pLineInfo  ) {
               match := specifiedID.isMatch(&curFile,pLineInfo,auto lineData=null);
               //message('displayAllLineInfo i='i' match='match);
               if ( match ) {
                  displayedOneLine = true;
                  status = specifiedID.displayLine(&curFile,i,tempEditor.getWindowID(),markerType,lineData);

                  curVersion := pLineInfo->getVersion();

                  if ( status>=0 ) {
                     m_lineDisplayInfo:[_file_case(filename)][i] = status;
                     status = 0;
                  }
               }
            }
         }
         WWTSModel.setFile(filename,curFile);

         casedFilename := _file_case(filename);
         m_bufferSchemeTable:[casedFilename] = schemeName;
         if ( displayedOneLine ) {
            refresh('A');
         }
         status = 0;
         //p_window_id=tempEditor.getOrigWindowID();
      } while ( false );
      mou_hour_glass(false);

#ifdef PROFILEWWTS
      profile("off");
#endif
      return status;
   }

   /**
    * Removes all information currently displayed for
    * <B>filename</B>
    */
   int removeAllLineInfo(_str filename) {
      clearMarkers(filename);
      return 0;
   }

   /**
    * 
    * @return scheme displayed for <B>filename</B>
    */
   _str getBufferScheme(_str filename) {
      schemeName := "";
      casedFilename := _file_case(filename);
      if ( m_bufferSchemeTable:[casedFilename]!=null ) {
         schemeName = m_bufferSchemeTable:[casedFilename];
      }
      return schemeName;
   }
   void setBufferScheme(_str filename,_str schemeName) {
      casedFilename := _file_case(filename);
      m_bufferSchemeTable:[casedFilename]= schemeName;
      m_versionListInfo:[casedFilename]=null;
   }

   void getVersionListinfo(_str filename,WWTS_VERSION_LIST_INFO (&versionListInfo):[]) {
      do {
         if ( m_versionListInfo:[_file_case(filename)]!=null ) {
            versionListInfo = m_versionListInfo:[_file_case(filename)];
            break;
         }
         indexList := m_lineDisplayInfo:[_file_case(filename)];
         len := indexList._length();
         for ( i:=0;i<len;++i ) {
            _StreamMarkerGet(indexList[i],auto streamMarkerInfo);
            if ( streamMarkerInfo != null ) {
               parse streamMarkerInfo.msg with auto curCaption ',' auto curDescription;
               if ( versionListInfo:[curCaption]==null ) {
                  WWTS_VERSION_LIST_INFO temp;
                  temp.bgcolor = streamMarkerInfo.RGBBoxColor;
                  temp.fgcolor = 0;
                  temp.caption = curCaption;
                  temp.description = curDescription;
                  temp.indexList[0] = indexList[i];
                  versionListInfo:[curCaption] = temp;
               }else{
                  curLen := versionListInfo:[curCaption].indexList._length();
                  versionListInfo:[curCaption].indexList[curLen] = indexList[i];
               }
            }
         }
         m_versionListInfo:[_file_case(filename)] = versionListInfo;
      } while ( false );
   }
};
