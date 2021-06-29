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
#include "treeview.sh"
#require "sc/lang/IControlID.e"
#import "treeview.e"
#import "varedit.e"
#import "stdprocs.e"
#endregion

/**
 * The "sc.controls" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language's
 * form editor system and editor control.  It also contains
 * class wrappers for composite controls.
 */
namespace sc.controls;

enum COLUMN_ALIGNMENT_STYLE {
   COLUMN_ALIGNMENT_LEFT,
   COLUMN_ALIGNMENT_RIGHT,
   COLUMN_ALIGNMENT_CENTER,
};

//enum TREENODE_STATE {
//   TREENODE_COLLAPSED  =  0,
//   TREENODE_EXPANDED   =  1,
//   TREENODE_NOCHILDREN = -1,
//};

class Table : sc.lang.IControlID {
   private int m_treeWID;    

   /** 
    * Constructor
    * 
    * @param WID Window ID of tree control for this instance to be 
    *            coupled with
    */
   public Table(int WID=0) {
      m_treeWID  = WID;

      _SetDialogInfoHt("TableThis",this,m_treeWID,true);
   }

   /** 
    * @return Window id of the tree control
    */
   public int getWindowID() {
      return m_treeWID;
   }

   /** 
    * Use a derived class to override this method if you want to 
    * catch combo drop events for combo boxes in the tale 
    *  
    * Called when a combo box is dropped down
    * 
    * @param reason one of the following:<BR>
    * <UL>
    *    <LI>DROP_UP</LI>
    *    <LI>DROP_DOWN</LI>
    *    <LI>DROP_INIT</LI>
    *    <LI>DROP_UP_SELECTED</LI>
    * </UL>
    * @param rowY Row index (0..N-1) the event is occuring on
    * @param col Column the event is occuring on 
    */
   public int onComboDropEvent(int reason,int rowY,int col) {
      return 0;
   }

   /** 
    * Adjust all columns based on their specified width (or whether they have 
    * auto size set) and the amount of space available
    */
   public void resize() {
      wid := p_window_id;
      p_window_id = m_treeWID;

      // Start with the client width
      int adjustableWidth = _dx2lx(SM_TWIP,m_treeWID.p_client_width);

      numCols := _TreeGetNumColButtons();

      // Loop through cols, calculate the number of auto size columns
      // Start with the client width, and subtract the column width of any 
      // non-auto sized column.  This will give us the total adjustable width
      int numColsSizing=numCols;
      for ( i:=0;i<numCols;++i ) {
         _TreeGetColButtonInfo(i,auto colWidth,auto colFlags,auto buttonState,auto buttonCaption);
         if ( !(colFlags&TREE_BUTTON_AUTOSIZE) ) {
            adjustableWidth-=colWidth;
            --numColsSizing;
         }
      }   

      if ( numColsSizing ) {
         // Calculate the width for all auto sized columns
         int autoAdjustColWidth = adjustableWidth intdiv numColsSizing;
         for ( i=0;i<numCols;++i ) {
            _TreeGetColButtonInfo(i,auto colWidth,auto colFlags,auto buttonState,auto buttonCaption);
            if ( colFlags&TREE_BUTTON_AUTOSIZE ) {
               _TreeSetColButtonInfo(i,autoAdjustColWidth);
               p_scroll_bars = SB_BOTH;
            }
         }
      }
      p_window_id = wid;
   }

   /** 
    * @param caption Caption for top of column
    * @param flags Flags for this column, combination of 
    *              TREE_BUTTON_* flags
    * @param width width of this column in twips.   -1 means 
    *              autosize - autosize means all the autosized
    *              columns will equally share the available space
    */
   public void addColumn(_str caption,int flags,int width) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      numCols := _TreeGetNumColButtons();

      newCol := numCols;

      if ( width<0 ) {
         flags|=TREE_BUTTON_AUTOSIZE;
         int clientWidth = _dx2lx(SM_TWIP,m_treeWID.p_client_width);
         if ( numCols ) {
            width = clientWidth intdiv numCols;
         }else{
            width = clientWidth;
         }
      }

      m_treeWID._TreeSetColButtonInfo(newCol,width,flags,TREE_BUTTON_PUSHBUTTON,caption);
      m_treeWID.p_scroll_bars = SB_BOTH;
      resize();

      p_window_id=wid;
   }

   /** 
    * Get all the cells for <B>rowID</B>
    * 
    * @param rowID Row (tree node) to get all the cells for
    * @param cellInfo Array of text cells
    */
   private void getRowFromID(int rowID,STRARRAY &cellInfo) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      numCols := _TreeGetNumColButtons();
      wholeCaption := _TreeGetCaption(rowID);
      for ( ;; ) {
         parse wholeCaption with auto curCap "\t" wholeCaption;
         if ( curCap=="" && wholeCaption=="" ) break;
         cellInfo[cellInfo._length()] = curCap;
      }

      while ( numCols-cellInfo._length()>0 ) {
         cellInfo[cellInfo._length()]="";
      }

      p_window_id=wid;
   }

   /** 
    * Set all the cells for <B>rowID</B>
    * 
    * @param rowID Row ID (tree node) to set all the cells for
    * @param cellInfo Array of text cells
    */
   private void setRowFromID(int rowID,STRARRAY &cellInfo) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      caption := "";
      len := cellInfo._length();
      for ( i:=0;i<len;++i ) {
         caption :+= "\t":+cellInfo[i];
      }
      caption=substr(caption,2);

      _TreeSetCaption(rowID,caption);

      p_window_id=wid;
   }

   /** 
    * 
    * 
    * @param colX Column to delete
    * 
    * @return int 0 if successful, <0 if error
    */
   public int deleteColumn(int colX) {
      status := 0;

      wid := p_window_id;
      p_window_id=m_treeWID;

      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1 > numCols ) {
            status = INVALID_ARGUMENT_RC;break;
         }
         _TreeDeleteColButton(colX);
         _TreeRefresh();

         childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         for (;;) {
            if ( childIndex<0 ) break;
            getRowFromID(childIndex,auto cellInfo);
            cellInfo._deleteel(colX);
            setRowFromID(childIndex,cellInfo);
            childIndex = _TreeGetNextSiblingIndex(childIndex);
         }
      } while (false);

      p_window_id=wid;

      return status;
   }

   /** 
    * 
    * 
    * @param caption Caption for top of column
    * @param width width of this column in twips.   -1 means 
    *              autosize - autosize means all the autosized
    *              columns will equally share the available space
    * @param alStyle Alignment style for this column.  One of the 
    *                following:
    *                <UL>
    *    <LI>COL_AL_LEFT</LI>
    *    <LI>COL_AL_RIGHT</LI>
    *    <LI>COL_AL_CENTER</LI>
    * </UL>
    * @param isPushButton set to false if this column is not a 
    *                     button
    */
   public void addNumericColumn(_str caption
                                ,int width=-1
                                ,COLUMN_ALIGNMENT_STYLE alStyle=COLUMN_ALIGNMENT_RIGHT
                                ,bool isPushButton = true
                                ) {
      extraFlags := 0;
      if ( isPushButton ) extraFlags|=TREE_BUTTON_PUSHBUTTON;

      if ( alStyle==COLUMN_ALIGNMENT_RIGHT ) {
         extraFlags|=TREE_BUTTON_AL_RIGHT;
      }else if ( alStyle==COLUMN_ALIGNMENT_LEFT ) {
         // This is the default
         //extraFlags|=TREE_BUTTON_AL_LEFT;
      }else if ( alStyle==COLUMN_ALIGNMENT_CENTER ) {
         extraFlags|=TREE_BUTTON_AL_CENTER;
      }

      addColumn(caption,TREE_BUTTON_SORT_NUMBERS|extraFlags,width);
   }

   /** 
    * 
    * 
    * @param caption Caption for top of column
    * @param width width of this column in twips.   -1 means 
    *              autosize - autosize means all the autosized
    *              columns will equally share the available space
    * @param alStyle Alignment style for this column.  One of the 
    *                following:
    *                <UL>
    *    <LI>COL_AL_LEFT</LI>
    *    <LI>COL_AL_RIGHT</LI>
    *    <LI>COL_AL_CENTER</LI>
    * </UL>
    * @param sortCaseInsensitive set to false if this column should
    *                            sort items case sensitive
    * @param isPushButton set to false if this column is not a 
    *                     button
    */
   public void addFilenameColumn(_str caption
                                 ,int width=-1
                                 ,COLUMN_ALIGNMENT_STYLE alStyle=COLUMN_ALIGNMENT_LEFT
                                 ,bool sortCaseInsensitive = true
                                 ,bool isPushButton = true
                                 ) {
      extraFlags := 0;
      if ( isPushButton ) extraFlags|=TREE_BUTTON_PUSHBUTTON;
      if ( !sortCaseInsensitive ) extraFlags|=TREE_BUTTON_SORT_EXACT;

      if ( alStyle==COLUMN_ALIGNMENT_RIGHT ) {
         extraFlags|=TREE_BUTTON_AL_RIGHT;
      }else if ( alStyle==COLUMN_ALIGNMENT_LEFT ) {
         // This is the default
         //extraFlags|=TREE_BUTTON_AL_LEFT;
      }else if ( alStyle==COLUMN_ALIGNMENT_CENTER ) {
         extraFlags|=TREE_BUTTON_AL_CENTER;
      }

      addColumn(caption,TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_IS_FILENAME|extraFlags,width);
   }

   /** 
    * 
    * 
    * @param caption Caption for top of column
    * @param width width of this column in twips.   -1 means 
    *              autosize - autosize means all the autosized
    *              columns will equally share the available space
    * @param alStyle Alignment style for this column.  One of the 
    *                following:
    *                <UL>
    *    <LI>COL_AL_LEFT</LI>
    *    <LI>COL_AL_RIGHT</LI>
    *    <LI>COL_AL_CENTER</LI>
    * </UL>
    * @param sortCaseInsensitive set to false if this column should
    *                            sort items case sensitive
    * @param isPushButton set to false if this column is not a 
    *                     button
    */
   public void addNameColumn(_str caption
                             ,int width=-1
                             ,COLUMN_ALIGNMENT_STYLE alStyle=COLUMN_ALIGNMENT_LEFT
                             ,bool sortCaseInsensitive = true
                             ,bool isPushButton = true
                             ) {
      extraFlags := 0;
      if ( isPushButton ) extraFlags|=TREE_BUTTON_PUSHBUTTON;
      if ( !sortCaseInsensitive ) extraFlags|=TREE_BUTTON_SORT_EXACT;

      if ( alStyle==COLUMN_ALIGNMENT_RIGHT ) {
         extraFlags|=TREE_BUTTON_AL_RIGHT;
      }else if ( alStyle==COLUMN_ALIGNMENT_LEFT ) {
         // This is the default
         //extraFlags|=TREE_BUTTON_AL_LEFT;
      }else if ( alStyle==COLUMN_ALIGNMENT_CENTER ) {
         extraFlags|=TREE_BUTTON_AL_CENTER;
      }

      addColumn(caption,TREE_BUTTON_SORT|extraFlags,width);
   }

   // 8:40:21 AM 10/16/2007 - DWH
   // GOING TO LEAVE THIS OUT UNTIL WE ARE CERTAIN IT IS NECESSARY
   ///** 
   // * Set the tree control's expand bitmap
   // * 
   // * @param bmIndex index from load_picture
   // */
   //public void setExpandBitmap(int bmIndex) {
   //   m_treeWID.p_ExpandPicture = bmIndex;
   //}

   // 8:40:21 AM 10/16/2007 - DWH
   // GOING TO LEAVE THIS OUT UNTIL WE ARE CERTAIN IT IS NECESSARY
   ///** 
   // * Set the tree control's collapse bitmap
   // * 
   // * @param bmIndex index from load_picture
   // */
   //public void setCollapseBitmap(int bmIndex) {
   //   m_treeWID.p_CollapsePicture = bmIndex;
   //}

   /** 
    * Get the row ID (treenode index) for <B>rowY</B>.  Can create rows 
    * if the row does not exist 
    * 
    * @param rowY Y Index [0...N-1] of the row to get the index for
    * @param addRowsIfNecessary If true, and <B>rowY</B>>N-1, 
    *                           enough rows will be added to the
    *                           bottom of the tree for rowY to
    *                           exist
    * 
    * @return int row ID (treenode index) of <B>rowY</B>, or -1 if 
    *         it does not exist and <B>addRowsIfNecessary</B> is
    *         false
    */
   public int getNodeIndexFromRow(int rowY,bool addRowsIfNecessary=true) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      addFlags := 0;
      lastIndex := childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);

      numRowsCounted := 0;

      for ( i:=1;i<=rowY;++i ) {
         if ( childIndex<0 ) break;
         ++numRowsCounted;
         lastIndex = childIndex;
         childIndex = _TreeGetNextSiblingIndex(childIndex);
      }

      if ( addRowsIfNecessary ) {
         if ( lastIndex<0 ) {
            addFlags = TREE_ADD_AS_CHILD;
            lastIndex = TREE_ROOT_INDEX;
         }
   
         numRowsToAdd := rowY - numRowsCounted;
         if ( numRowsToAdd ) {
            for ( i=0;i<numRowsToAdd;++i ) {
               lastIndex = _TreeAddItem(lastIndex,"",addFlags,0,0,-1);
               addFlags=0;
            }
         }else{
            lastIndex = childIndex;
         }
      }else{
         lastIndex = childIndex;
      }

      p_window_id=wid;
      return lastIndex;
   }

   // 8:40:21 AM 10/16/2007 - DWH
   // GOING TO LEAVE THIS OUT UNTIL WE ARE CERTAIN IT IS NECESSARY
   ///** 
   // * Sets the expansion state of this row (tree node).  Even 
   // * though there are probably not child nodes, this is very 
   // * convenient for showing the expand/collapse bitmap 
   // * 
   // * @param rowY Y Index [0...N-1] of the row to set the expand 
   // *             state for
   // * @param state
   // * <UL>
   // *    <LI> 0 collapsed (expand bitmap is shown, no children shown)</LI>
   // *    <LI> 1 expanded  (collapse bitmap is shown, children shown)</LI>
   // *    <LI>-1 collapsed (no bitmap is shown, no children shown)</LI>
   // * </UL>
   // */
   //public int setState(int rowY,TREENODE_STATE state) {
   //   status := 0;
   //   int rowID = getNodeIndexFromRow(rowY,false);
   //   do {
   //      if ( rowID<0 ) {
   //         status = rowID;break;
   //      }
   //      m_treeWID._TreeSetInfo(rowID,state);
   //   } while ( false );
   //   return status;
   //}

   /** 
    * Add a new row to the table
    * 
    * @param rowYAfter Y Index [0...N-1] of the row to add the row 
    *                  after.  If row number <B>rowYAfter</B> does
    *                  not exist, it will be added after the
    *                  current row.
    * @param wholeRowCaption Caption for the entire row, with 
    *                        columns divided by tab characters
    * @param curBitmapIndex Index of bitmap for this row when it is 
    *                       the current row (tree node)
    * @param nonCurBitmapIndex Index of bitmap for this row when it
    *                          is not the current row (tree node)
    * @param expandState Uses the expand state for the tree node. 
    *                    This is mostly used for displaying the
    *                    tree's expand/collapse bitmap on this row.
    * 
    * @return int Row index 0..N-1 for the new row, <0 on error
    */
   public int addRow(int rowYAfter=-1
                     ,_str wholeRowCaption=""
                     ,int curBitmapIndex=-1
                     ,int nonCurBitmapIndex=-1
                     //,TREENODE_STATE expandState=-TREENODE_NOCHILDREN
                     ) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      addFlags := 0;

      rowIDAfter := -1;

      if ( rowYAfter>-1 ) {
         rowIDAfter = getNodeIndexFromRow(rowYAfter,false);
      }

      if ( rowIDAfter<0 ) {
         rowIDAfter = m_treeWID._TreeCurIndex();
         if ( rowIDAfter<0 ) rowIDAfter=m_treeWID._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      }
      if ( rowIDAfter<0 ) {
         addFlags = TREE_ADD_AS_CHILD;
         rowIDAfter = TREE_ROOT_INDEX;
      }

      rowY := -1;
      do {
         rowID := _TreeAddItem(rowIDAfter,wholeRowCaption,addFlags,nonCurBitmapIndex,curBitmapIndex,-1);
         if ( rowID<0 ) {
            rowY = rowID;
            break;
         }
   
         // Convert tree node index into a line number.  Teporarily set the current 
         // index to the newly added index, call _TreeCurLineNumber(), then 
         // restore the original index.  Return the line number.
         origIndex := _TreeCurIndex();
         _TreeSetCurIndex(rowID);
         rowY = _TreeCurLineNumber();
         _TreeSetCurIndex(origIndex);
      } while ( false );

      p_window_id=wid;

      return rowY;
   }

   /** 
    * Delete a row
    * 
    * @param rowY Y index (0...N-1) of row to delete
    * 
    * @return int 0 if successful, error <0 if row Y does not exist
    */
   public int deleteRow(int rowY) {
      status := 0;

      do {
         rowID := getNodeIndexFromRow(rowY,false);
         if ( rowID<0 ) {
            status = rowID;break;
         }
         wid := p_window_id;
         p_window_id=m_treeWID;

         _TreeDelete(rowID);

         p_window_id=wid;
      } while ( false );

      return status;
   }

   /** 
    * Get an array containing all the row IDs.  If <B>countOnly</B> 
    * is true, it will traverse the tree and count, but not save 
    * <B>rowIDs</B> (tree node)
    * 
    * @param rowIDs array to put row IDs (tree nodes) in
    * @param lastRowID gets the last row ID (tree node index) in 
    *                  the table
    * @param countOnly if true, only count but do not add data to 
    *                  rowIDs
    * 
    * @return int The number of rows in the table
    */
   private int getRowIDs(INTARRAY &rowIDs,int &lastRowID,bool countOnly=false) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      lastRowID = -1;
      numRows := 0;
      childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);

      for ( ;; ) {
         if ( childIndex<0 ) break;
         if ( !countOnly ) rowIDs[rowIDs._length()]=childIndex;
         ++numRows;
         lastRowID = childIndex;
         childIndex = _TreeGetNextSiblingIndex(childIndex);
      }

      p_window_id=wid;
      return numRows;
   }

   /** 
    * @return int the last Row ID (tree node index)
    */
   private int getLastRowID() {
      getRowIDs(null,auto lastRowID,true);
      return lastRowID;
   }

   /** 
    * @return int The number of rows in the table
    */
   public int getNumRows() {
      return getRowIDs(null,auto lastRowID,true);
   }

   /** 
    * Delete <B>numRows</B> rows from the bottom of the table
    * 
    * @param numRows number of rows deleted
    */
   private void deleteRowsAtEnd(int numRows) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      INTARRAY rowIDs;
      getRowIDs(rowIDs,auto lastRowID);
      for ( i:=0;i<numRows;++i ) {
         if ( !rowIDs._length() ) break;
         lastIndex := rowIDs._length()-1;
         _TreeDelete(rowIDs[lastIndex]);
         rowIDs._deleteel(lastIndex);
      }

      p_window_id=wid;
   }

   /** 
    * Add <B>numRows</B> empty rows to the bottom of the table
    * 
    * @param numRows number of rows added
    */
   private void addRowsAtEnd(int numRows) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      flags := 0;
      int lastRowID = getLastRowID();
      if ( lastRowID<0 ) {
         flags|=TREE_ADD_AS_CHILD;
         lastRowID = TREE_ROOT_INDEX;
      }
      for ( i:=0;i<numRows;++i ) {
         lastRowID = _TreeAddItem(lastRowID,"",flags,0,0,-1);
         flags = 0;
      }

      p_window_id=wid;
   }

   /** 
    * Set the number of rows to <B>numRows</B>.  Rows will either 
    * be deleted from or added to the bottom 
    * 
    * @param numRows Number of rows in table
    */
   public void setNumRows(int numRows) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      curNumRows := getNumRows();

      if ( numRows<curNumRows ) {
         deleteRowsAtEnd(curNumRows-numRows);
      }else{
         addRowsAtEnd(numRows-curNumRows);
      }

      p_window_id=wid;
   }

   /** 
    * Get the text from a row 
    * 
    * @param rowY Y index of row to get
    * @param cellInfo Array 0..N-1 containing the text from each 
    *                 column
    * 
    * @return int 0 if successful, <0 if error
    */
   public int getRow(int rowY,STRARRAY &cellInfo) {
      status := 0;
      wid := p_window_id;
      p_window_id=m_treeWID;

      do {
         int rowID = getNodeIndexFromRow(rowY);
         if ( rowID<0 ) {
            status = rowID;break;
         }
         getRowFromID(rowID,cellInfo);
      } while ( false );

      p_window_id=wid;
      return status;
   }

   /** 
    * Set the text for a row 
    * 
    * @param rowY Y index of row to set
    * @param cellInfo Array 0..N-1 containing the text for each 
    *                 column
    * 
    * @return int 0 if successful, <0 if error
    */
   public int setRow(int rowY,STRARRAY &cellInfo) {
      status := 0;
      wid := p_window_id;
      p_window_id=m_treeWID;

      do {
         int rowID = getNodeIndexFromRow(rowY);
         if ( rowID<0 ) {
            status = rowID;break;
         }
         setRowFromID(rowID,cellInfo);
      } while ( false );

      p_window_id=wid;
      return status;
   }

   /** 
    * Get all the text for a column
    * 
    * @param colX Column to get text from
    * @param cellInfo Array to store text in, each array element 
    *                 gets one "row" of date from column
    *                 <B>colX</B>
    * 
    * @return int 0 if successful, <0 error if not.
    */
   public int getColumn(int colX,STRARRAY &cellInfo) {
      status := 0;
      cellInfo = null;
      wid := p_window_id;
      p_window_id=m_treeWID;

      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1 > numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }
         childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         for ( ;; ) {
            if ( childIndex<0 ) break;
            getRowFromID(childIndex,auto curCellInfo);
            cellInfo[cellInfo._length()] = curCellInfo[colX];
            childIndex = _TreeGetNextSiblingIndex(childIndex);
         }
      } while ( false );

      p_window_id=wid;
      return status;
   }

   /** 
    * Get all the text for a column
    * 
    * @param colX Column to get text from
    * @param cellInfo Array to store text in, each array element 
    *                 gets one "row" of date from column
    *                 <B>colX</B>
    * 
    * @return int 0 if successful, <0 error if not.
    */
   public int setColumn(int colX,STRARRAY &cellInfo) {
      status := 0;
      wid := p_window_id;
      p_window_id=m_treeWID;

      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1 > numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }
         lastIndex := childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
         len := cellInfo._length();
         for ( i:=0;i<len;++i ) {
            if ( childIndex<0 ) {
               childIndex = _TreeAddItem(lastIndex,"",0,0,0,-1);
               if ( childIndex<0 ) break;
            }
            getRowFromID(childIndex,auto curCellInfo);
            curCellInfo[colX] = cellInfo[i];
            setRowFromID(childIndex,curCellInfo);
            lastIndex = childIndex;
            childIndex = _TreeGetNextSiblingIndex(childIndex);
         }
      } while ( false );

      p_window_id=wid;
      return 0;
   }

   /** 
    * Set the text for a cell
    * 
    * @param colX Column number 0..N-1.  Will not create new 
    *             columns, these have to be created using
    * <UL> 
    *    <LI>addNumericColumn</LI>
    *    <LI>addFilenameColumn</LI>
    *    <LI>addNameColumn</LI>
    * </UL>
    * @param rowY Row to set cell's text for.  Row's will be 
    *             created if <rowY row's exist
    * @param cellData Text to set for row
    * 
    * @return int
    */
   public int setCell(int colX,int rowY,_str cellData) {
      wid := p_window_id;
      p_window_id=m_treeWID;
      status := 0;

      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1>numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }
         rowID := getNodeIndexFromRow(rowY);
         if ( rowID<0 ) {
            status = rowID;
            break;
         }
   
         getRowFromID(rowID,auto cellinfo);
         cellinfo[colX] = cellData;
         setRowFromID(rowID,cellinfo);
      } while ( false );

      p_window_id=wid;
      return status;
   }

   /** 
    * @param colX X position (column 0..N-1) to get data for
    * @param rowY Y position (row 0...N-1) to get data for 
    * @param status 0 if successful.
    * 
    * @return _str Data from cell
    */
   public _str getCell(int colX,int rowY,int &status=0) {
      status = 0;
      cellData := "";

      wid := p_window_id;
      p_window_id=m_treeWID;

      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1>numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }
         rowID := getNodeIndexFromRow(rowY,false);
         if ( rowID<0 ) {
            status = rowID;
            break;
         }
   
         getRowFromID(rowID,auto cellinfo);
         cellData = cellinfo[colX];
         setRowFromID(rowID,cellinfo);
      } while ( false );

      p_window_id=wid;
      return cellData;
   }

   /** 
    * Set all combo items for one column in one row
    * 
    * @param colX X position (column 0..N-1) to set combo box data 
    *             for
    * @param rowY Y Index (0...N-1) of the row to set combo 
    *               box data for. If row number <B>rowY</B> does
    *               not exist, no row will be added
    * @param items items to set
    */
   public int setCellComboItems(int colX,int rowY,STRARRAY items) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      status := 0;
      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1>numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }
         rowID := getNodeIndexFromRow(rowY,false);
         if ( rowID<0 ) {
            status=rowID;break;
         }
         _TreeSetComboDataNodeCol(rowID,colX,items);
      } while ( false );

      p_window_id=wid;
      return status;
   }

   /** 
    * Get all combo items for one column in one row
    * 
    * @param colX X position (column 0..N-1) to set combo box data 
    *             for
    * @param rowY Y Index (0...N-1) of the row to set combo 
    *               box data for. If row number <B>rowY</B> does
    *               not exist, no row will be added
    * @param items items to get
    */
   public int getCellComboItems(int colX,int rowY,STRARRAY &items) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      status := 0;
      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1>numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }
         rowID := getNodeIndexFromRow(rowY,false);
         if ( rowID<0 ) {
            status=rowID;break;
         }
         _TreeGetComboDataNodeCol(rowID,colX,items);
      } while ( false );

      p_window_id=wid;
      return status;
   }

   /** 
    * Add one combo item for one column in one row
    * 
    * @param colX X position (column 0..N-1) to set combo box data 
    *             for
    * @param rowY Y Index (0...N-1) of the row to set combo 
    *               box data for. If row number <B>rowY</B> does
    *               not exist, no row will be added
    * @param item combo box item to add
    */
   public int addCellComboItem(int colX,int rowY,_str item) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      status := 0;
      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1>numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }
         rowID := getNodeIndexFromRow(rowY,false);
         if ( rowID<0 ) {
            status=rowID;break;
         }
         STRARRAY items;
         _TreeGetComboDataNodeCol(rowID,colX,items);
         items[items._length()] = item;
         _TreeSetComboDataNodeCol(rowID,colX,items);
      } while ( false );

      p_window_id=wid;
      return status;
   }

   /** 
    * Set all combo items for column <B>colX</B> of this table 
    * (affects all rows)
    * 
    * @param colX Column to set the items for (0...N-1)
    * @param items Array of text items for combo box
    */
   public int setColComboItems(int colX,STRARRAY &items) {
      status := 0;

      wid := p_window_id;
      p_window_id=m_treeWID;

      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1>numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }

         flags := _TreeGetColEditStyle(colX);
         if ( items._length() ) {
            flags|=TREE_EDIT_COMBOBOX;
         }else{
            flags&=~TREE_EDIT_COMBOBOX;
         }

         _TreeSetComboDataCol(colX,items);
      } while ( false );

      m_treeWID=p_window_id;
      return status;
   }

   /** 
    * Get all combo items for column <B>colX</B> of this table 
    * (affects all rows)
    * 
    * @param colX Column to set the items for (0...N-1)
    * @param items Array of text items for combo box 
    *  
    * @return 0 if successful, <0 error code otherwise 
    */
#if 0 //2:26pm 9/9/2011
   public int getColComboItems(int colX,STRARRAY &items) {
      status := 0;

      wid := p_window_id;
      p_window_id=m_treeWID;

      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1>numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }

         _TreeGetComboDataColumn(colX,items);
      } while ( false );

      m_treeWID=p_window_id;
      return status;
   }
#endif

   /** 
    * Add one combo item for column <B>colX</B> of this table 
    * (affects all rows)
    * 
    * @param colX Column to add the item to (0...N-1)
    * @param item text item to add to the combo boxes
    *  
    * @return 0 if successful, <0 error code otherwise 
    */
   public int addColComboItem(int colX,_str item) {
      status := 0;

      wid := p_window_id;
      p_window_id=m_treeWID;

      do {
         numCols := _TreeGetNumColButtons();
         if ( colX+1>numCols ) {
            status = INVALID_ARGUMENT_RC;
            break;
         }

#if 0 //2:26pm 9/9/2011
         _TreeGetColButtonInfo(colX,auto width,auto flags,auto state,auto caption);
         _TreeSetColButtonInfo(colX,width,flags|TREE_BUTTON_COMBO,state,caption);
#else
         _TreeSetColEditStyle(colX,TREE_EDIT_COMBOBOX);
#endif

         STRARRAY items;
         _TreeGetComboDataCol(colX,items);
         items[items._length()] = item;
         _TreeSetComboDataCol(colX,items);
      } while ( false );

      m_treeWID=p_window_id;
      return status;
   }

   /** 
    * Set the color for column <B>colX</B>.  Can be overriden by 
    * setCellColor 
    * 
    * @param colX Column to set color for
    * @param FGRGB RGB color of text
    * @param BGRGB RGB color of background
    * @param flags Font flags (F_*), currently only 
    *              F_INHERIT_FG_COLOR and F_INHERIT_BG_COLOR are
    *              supported
    *  
    * @return 0 if successful, <0 error code otherwise 
    */
   public void setColColor(int colX,int FGRGB,int BGRGB,int flags) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      _TreeSetColColor(colX,FGRGB,BGRGB,flags);

      m_treeWID=p_window_id;
   }

   /** 
    * Get the color for column <B>colX</B>.
    * 
    * @param colX Column to get color for
    * @param FGRGB RGB Gets color of text
    * @param BGRGB RGB Gets color of background
    * @param flags Gets Font flags (F_*), currently only 
    *              F_INHERIT_FG_COLOR and F_INHERIT_BG_COLOR are
    *              supported
    *  
    * @return 0 if successful, <0 error code otherwise 
    */
   public void getColColor(int colX,int &FGRGB=0,int &BGRGB=0,int &flags=0) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      _TreeGetColColor(colX,FGRGB,BGRGB,flags);

      m_treeWID=p_window_id;
   }

   /** 
    * Set the color for column <B>RowY</B>.  Actually sets color 
    * for all of the cells 
    * 
    * @param rowY Row to set color for
    * @param FGRGB RGB color of text
    * @param BGRGB RGB color of background
    * @param flags Font flags (F_*), currently only 
    *              F_INHERIT_FG_COLOR and F_INHERIT_BG_COLOR are
    *              supported
    *  
    * @return 0 if successful, <0 error code otherwise 
    */
   public void setRowColor(int rowY,int FGRGB,int BGRGB,int flags) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      rowID := getNodeIndexFromRow(rowY);
      _TreeSetRowColor(rowID,FGRGB,BGRGB,flags);

      m_treeWID=p_window_id;
   }

   /** 
    * Set the color for cell <B>colX</B>,<B>rowY</B>.
    * 
    * @param colX Column to set color for
    * @param rowY Row to set color for
    * @param FGRGB RGB color of text
    * @param BGRGB RGB color of background
    * @param flags Font flags (F_*), currently only 
    *              F_INHERIT_FG_COLOR and F_INHERIT_BG_COLOR are
    *              supported
    *  
    * @return 0 if successful, <0 error code otherwise 
    */
   public void setCellColor(int colX,int rowY,int FGRGB,int BGRGB,int flags) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      rowID := getNodeIndexFromRow(rowY);
      _TreeSetColor(rowID,colX,FGRGB,BGRGB,flags);

      m_treeWID=p_window_id;
   }

   /** 
    * Get the color for column <B>colX</B>,<B>rowY</B>.
    * 
    * @param colX Column to set color for
    * @param rowY Row to set color for
    * @param FGRGB RGB Gets color of text
    * @param BGRGB RGB Gets color of background
    * @param flags Gets Font flags (F_*), currently only 
    *              F_INHERIT_FG_COLOR and F_INHERIT_BG_COLOR are
    *              supported
    *  
    * @return 0 if successful, <0 error code otherwise 
    */
   public void getCellColor(int colX,int rowY,int &FGRGB=0,int &BGRGB=0,int &flags=0) {
      wid := p_window_id;
      p_window_id=m_treeWID;

      rowID := getNodeIndexFromRow(rowY,false);
      _TreeGetColor(rowID,colX,FGRGB,BGRGB,flags);

      m_treeWID=p_window_id;
   }
};
