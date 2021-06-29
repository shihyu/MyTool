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
#require "OptionsTree.e"
#import "guicd.e"
#import "guiopen.e"
#import "main.e"
#import "math.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion Imports

static const NO_SEARCH= 0;
static const SEARCHING= 1;
static const FAVORITES= 2;

// kludgy special cases
static const EMULATION_FORM_NAME=   "_emulation_form";
static const QS_TAGGING_PATH=       "Context Tagging";

namespace se.options;

struct ModifiedNode {
   _str Path;
   bool Modified;
};

class OptionsConfigTree : OptionsTree {
   const OPTIONS="options";

   // contains XML indexes of property sheets and dialogs that have been modified
   // null or 0 means not modified, 1 means modified
   private ModifiedNode m_modified:[];    

   // current search state
   private int m_searching = 0;
   private _str m_searchTerm = "";
   private _str m_searchOptions = "";

   // a hash of languages that are to be renamed upon the next 'apply'
   private _str m_renamedLanguages:[];

   private bool m_doProcessPanels = true;
   
   OptionsConfigTree()
   { }

   /** 
    * Clears the search parameters.
    * 
    */
   public void clearSearch()
   {
      m_searching = NO_SEARCH;
      m_parser.clearSearch();
   }

   /** 
    * Determines whether any options have been changed without 
    * having been applied to the application. 
    * 
    * 
    * @return bool   whether options have been modified
    */
   public bool areOptionsModified(bool checkCurrent = true, bool cancelling = false)
   {
      // check the current dialog
      if (checkCurrent) {
         processCurrentPanelBeforeSwitching(-1, cancelling ? OPTIONS_CANCELLING : OPTIONS_SWITCHING);
      }

      // this is a pain, but go through and check for modified nodes
      int index;
      foreach (index => . in m_modified) {
         // kludgy - if we are cancelling, we do not want to throw up a dialog 
         // based on the tagging dialog (quick start), since it comes up modified by default
         if (cancelling && m_modified:[index].Path == QS_TAGGING_PATH) {
            continue;
         }

         if (isNodeModified(index)) return true;
      }

      return false;
   }

   #region Modify/Apply Functions

   /**
    * Sets a property as having been applied.  Removes the asterisk
    * next to the caption in the property sheet.
    * 
    * @param psWid      Property sheet containing property to be applied.
    * @param nodeIndex  which node to be applied
    */
   private void setPropertyNodeApplied(int psWid, int nodeIndex)
   {
      // update the caption - remove the *
      caption := psWid.p_child._TreeGetCaption(nodeIndex);
      caption = translate(caption, "", "*");
      psWid.p_child._TreeSetCaption(nodeIndex, caption);

   }

   /** 
    * Sets a tree node in the main options tree as having been 
    * applied.  Removes the asterisk next to the caption in the 
    * tree. 
    * 
    * @param index      tree node to be applied
    */
   private void setTreeNodeNotModified(int index)
   {
      if (index < 0) return;

      // update the caption, remove the *
      caption := m_treeHandle._TreeGetCaption(index);
      caption = strip(caption, 'T', "*");
      caption = strip(caption);
      m_treeHandle._TreeSetCaption(index, caption);

      // set as not modified 
      index = m_relations.getXMLIndex(index);
      setNodeAsNotModified(index);
   }

   /** 
    * Sets an option node as having been modified by placing an * 
    * next to the caption. 
    * 
    * @param index      tree index of mode that has been modified
    */
   private void setTreeNodeModified(int index)
   {
      if (index < 0) return;

      // add a star to the caption
      caption := m_treeHandle._TreeGetCaption(index);
      if (!pos("*", caption)) {
         caption :+= " *";
         m_treeHandle._TreeSetCaption(index, caption);
      }

      // set as modified 
      index = m_relations.getXMLIndex(index);
      setNodeAsModified(index);
   }

   /**
    * Checks the current dialog for any modifications.  Also saves
    * the state of the dialog so that we can restore it later.
    * 
    * @param treeIndex Index in tree where Dialog node is found
    */
   private bool processCurrentPanelBeforeSwitching(int treeIndex = -1, int action = OPTIONS_SWITCHING)
   {
      if (!m_doProcessPanels) return true;

      modified := false;

      if (treeIndex < 0) {
         treeIndex = m_currentTreeIndex;
         if (treeIndex < 0) treeIndex = TREE_ROOT_INDEX;
      }

      index := m_relations.getXMLIndex(treeIndex);
      if (index < 0) return true;

      switch (m_data.getPanelType(index)) {
      case OPT_DIALOG_EMBEDDER:
         // we make a copy because sometimes the save state function reloads the options
         DialogEmbedder * temp = m_data.getDialogEmbedder(index);
         DialogEmbedder df = *temp;

         // did we change anything on this form?
         if (df != null) {

            // save the state
            df.saveState();

            // don't need to validate if we are just cancelling anyway
            // also don't need to do it if we are applying, because that is automatic
            if (action == OPTIONS_SWITCHING) {
               if (!df.validate(action)) return false;
            }

            // this is a bit goofy
            if (df.getFormName() == EMULATION_FORM_NAME) {
               if (!m_data.hasBeenLoaded(index)) return true;
            }

            if (df.isModified()) {
               // we set this node as having been modified and move along
               setTreeNodeModified(treeIndex);
               modified = true;
            } else if (isNodeModified(index)) {
               setTreeNodeNotModified(treeIndex);
            }

         } 
         break;
      case OPT_PROPERTY_SHEET:
         PropertySheetEmbedder *pse = m_data.getPropertySheet(index);
         if (pse -> isModified()) {
            // we set this node as having been modified and move along
            setTreeNodeModified(treeIndex);
            modified = true;
         } else if (isNodeModified(index)) {
            setTreeNodeNotModified(treeIndex);
         }

         // see if the column sizes have changed - we want the other property
         // sheets to reflect this new sizing
         pse -> saveColumnSizes();
         break;
      }

      return true;
   }

   /** 
    * Apply all the changes that have been made in the tree since
    * it was opened or last applied.
    * 
    */
   public bool apply(bool restoreCurrent = true, bool applyCurrent = true)
   {
      int i, j;
      Property pList[];

      changeEvents := 0;
      applySuccess := true;

      // save what we're currently viewing
      curCaption := m_currentCaption;

      // first things first, we got to check the current panel - 
      // if it's a form, we might not know yet that it was modified
      if (applyCurrent) {
         if (!processCurrentPanelBeforeSwitching()) {
            // okay, something didn't validate, so we better not switch over
            return false;
         }
      }

      // keep track of all that we are applying
      _str appliedPaths[];

      // don't process any more panels
      m_doProcessPanels = false;

      // iterate through the list of modified XML indices
      int index;
      ModifiedNode modNode;
      foreach (index => modNode in m_modified) {

         if (isNodeModified(index)) {
            if (!m_parser.isIndexPathPairValid(modNode.Path, index)) continue;

            // get the property sheet or dialog transformer associated with this xml index
            switch (m_data.getPanelType(index)) {
            case OPT_PROPERTY_SHEET:
               PropertySheetEmbedder * pse = m_data.getPropertySheet(index);

               _str appliedProperties[];
               applySuccess = pse -> apply(changeEvents, appliedProperties);

               foreach (auto prop in appliedProperties) {
                  appliedPaths[appliedPaths._length()] = modNode.Path " > " prop;
               }
               break;
            case OPT_DIALOG_EMBEDDER:
               // switch to viewing this node in case we have any message boxes coming up
               selectXMLIndexInTree(index, false, true);
               
               // call the apply function for the dialog
               DialogEmbedder *dt = m_data.getDialogEmbedder(index);
               if (dt != null) {
                  // apply date changed to XML DOM
                  if (dt -> canControlsBeListed()) {
                     _str list[];
                     dt -> getModifiedControlCaptions(list);
                     foreach (auto control in list) {
                        appliedPaths[appliedPaths._length()] = modNode.Path " > " control;
                     }
                  } else {
                     appliedPaths[appliedPaths._length()] = modNode.Path;
                  }
                  
                  applySuccess = false;
                  // validate first, then apply
                  if (dt -> validate(OPTIONS_APPLYING)) {
                     applySuccess = dt -> apply();
                  }
               }
   
               break;
            }

            if (applySuccess) {
               setTreeNodeNotModified(m_relations.getTreeIndex(index));
            } else {
               break;
            }
         }
      }

      m_doProcessPanels = true;

      // some things we only do when we actually apply something
      if (appliedPaths._length()) {
   
         // set our date as changed
         m_parser.setDateChanged(appliedPaths);
   
         // note that we need to write the config file
         _config_modify_flags(CFGMODIFY_DEFVAR);
   
         if (changeEvents) handleChangeEvents(changeEvents, null);
      }

      // we ONLY do these things if everything was hunky dory
      if (applySuccess) {
         // empty modified list 
         m_modified._makeempty();

         // rename our languages, if necessary
         renameLanguages(curCaption);
   
         // restore whatever node we were viewing
         if (restoreCurrent) { 
            showNode(curCaption, false, ISEB_SELECT_TOP);
         }
      }

      return applySuccess;
   }

   /**
    * Adds the Emulation node to our options history to mark it as
    * modified.  This is specifically for the Emulations node,
    * which is applied through a different path than most nodes.
    */
   public void markEmulationNodeInOptionsHistory()
   {
      // find the emulation form
      index := m_parser.findDialogNode(EMULATION_FORM_NAME);
      if (index > 0) {
         // get the path for the node
         _str nodes[];
         nodes[0] = m_parser.getXMLNodeCaptionPath(index);

         // set our date as changed
         m_parser.setDateChanged(nodes);
      }
   }

   #region Modify/Apply Functions

   /**
    * Determines whether an XML index has been modified.
    * 
    * @param index      XML node to check
    * 
    * @return           true if it has been modified, false 
    *                   otherwise
    */
   private bool isNodeModified(int index)
   {
      return (m_modified._indexin(index) && ((ModifiedNode)m_modified:[index]).Modified);
   }

   /**
    * Sets an XML node as having been modified.
    * 
    * @param index   xml index to set as modified
    */
   private void setNodeAsModified(int index)
   {
      ModifiedNode mn;
      mn.Modified = true;
      mn.Path = m_parser.getXMLNodeCaptionPath(index);
      m_modified:[index] = mn;
   }

   /**
    * Sets an XML node as having been not modified (same as 
    * applied). 
    * 
    * @param index   xml index to set as modified
    */
   private void setNodeAsNotModified(int index)
   {
      ModifiedNode mn;
      mn.Modified = false;
      mn.Path = m_parser.getXMLNodeCaptionPath(index);
      m_modified:[index] = mn;
   }

   /** 
    * This method determines if a node should be displayed and how it should be 
    * displayed in the options tree.  Any modifications to captions and icons 
    * should be done in this function. 
    *  
    * 
    * @param xmlIndex                  xml index of node that we are considering
    * @param caption                   caption to display for this node
    * @param picIndex                  index of icon to display for this node
    * @param children                  TREE_NODE_LEAF if node is a leaf, 
    *                                  TREE_NODE_COLLAPSED if the node is a
    *                                  non-expanded parent, TREE_NODE_EXPANDED
    *                                  if the node is an expanded parent
    * @param flags                     any flags to send to _TreeAddItem
    * @param startNode                 the index of the node we want to select in 
    *                                  the tree
    * @param recurseThis               whether to continue to recurse through this 
    *                                  node's children
    * 
    * @return                          true if this node should be added to the 
    *                                  tree, false if it should be skipped.
    */
   private bool getNodeInfo(int xmlIndex, _str &caption, int &picIndex, int &children, 
                               int &flags, int startNode, bool &recurseThis)
   {
      // We only show the nodes which either contain the search term or have
      // children which do.
      // special case - we always show the options helper nodes (Options History,
      // Search Results)
      selfFound := false;
      childrenFound := false;
      parentFound := false;
      if (m_searching) {

         // check to see if this node or its children were part of search results
         selfFound = m_parser.wasNodeFoundInSearch(xmlIndex);
         childrenFound = m_parser.wasChildOfNodeFoundInSearch(xmlIndex);
         parentFound = m_parser.wasParentOfNodeFoundInSearch(xmlIndex);

         // this node is not found, skip it
         if (!selfFound &&                // not found
             !childrenFound &&            // no children found
             !parentFound &&
             !(m_searching == SEARCHING && m_parser.isSearchResultsNode(xmlIndex) && m_parser.wereAnyNodesFound())) {
            return false;
         }
      } else if (m_parser.isSearchResultsNode(xmlIndex)) {
         return false;
      }

      // whether to insert this node as a parent or a leaf - this value will
      // be used as an argument when we insert into tree
      children = m_parser.getFirstChild(xmlIndex);

      // if it has no children or is a property sheet, then it's a leaf
      if (children < 0 || m_parser.isAPropertySheet(xmlIndex) || m_parser.isADialog(xmlIndex)) {
         children = TREE_NODE_LEAF;                   // leaf value
         recurseThis = false;
      } else {
         // we expand all nodes when searching
         // and we expand the entire path to the starting node
         if ((m_searching && childrenFound) || (startNode > 0 && recurseThis)) {
            children = TREE_NODE_EXPANDED;                 // expanded parent
         } else {
            children = TREE_NODE_COLLAPSED;                 // non-expanded parent
         }
      }

      // get the caption, if this node has been modified, we add a ' *'
      caption = m_parser.getCaption(xmlIndex);
      if (isNodeModified(xmlIndex)) {
         caption :+= " *";
      }

      // does this node match the search?  if so, we make it BOLD
      flags = 0;
      if (m_searching) {
         // search for xml node within list of nodes to be made bold
         // if the node is a leaf, then we know it's a property sheet
         // with a property containing the search text
         if (!m_parser.isSearchResultsNode(xmlIndex) && (m_parser.wasNodeCaptionMatchedInSearch(xmlIndex))) {
            flags = TREENODE_BOLD;
         }
      }

      picIndex = 0;

      return true;
   }

   /**
    * Shows a node that was found in the search in its position in
    * the tree.  May be a node in the tree or a property, in which
    * case it shows the parent property sheet.
    * 
    * @param path    path of node to find
    * @param node    node to find
    * 
    * @return        true if we were able to display node, false otherwise
    */
   public bool showSearchNode(_str path, _str node)
   {
      // show the first part
      if (path == "") {
         path = node;
      } else {
         path :+= " > "node;
      }
      if (showNode(path, false, ISEB_SELECT_PARENT)) {
         // then we'll determine if this is a property that we want or a dialog
         if (m_data.getPanelType(getCurrentXMLIndex()) == OPT_PROPERTY_SHEET) {
            // we need to select this node
//          PropertySheet *ps = m_data.getPropertySheet(getCurrentXMLIndex());
//
//          // select our property
//          psIndex := ps -> getIndexByCaption(node);
//          if (psIndex >= 0) {
//             m_currentPanelWid.p_child._TreeSelectLine(psIndex + 1, true);
//          }
         } 
         return true;
      }

      return false;
   }

   /** 
    * Initializes the options tree.
    * 
    * @param treeID        window ID of main tree
    * @param frameID       window ID of right frame on form 
    * @param helpID        window ID of help html control 
    * @param file          xml file containing options 
    */
   public bool init(int treeID = 0, int frameID = 0, int helpID = 0, _str file = "")
   {
      m_searching = NO_SEARCH;
      m_modified._makeempty();
      m_renamedLanguages._makeempty();

      m_optionsTreePurpose = OP_CONFIG;

      if (OptionsTree.init(treeID, frameID, helpID, file)) {
         m_dialogsAsSummaries = false;

         // put in first layer of options
         if (treeID) {
            buildNextLayer();
         }

         return true;
      } 

      _message_box("There is a problem with the options XML file.  Please contact Product Support.");
      return false;
   }

   private void initializePropertySheet(int index)
   {
      refreshPropertySheet(index);
   }

   /**
    * Refreshes the view of a property sheet.  Updates the
    * highlight colors if we are searching.
    * 
    * @param index   index of property sheet to refresh
    */
   private void refreshPropertySheet(int index)
   {
      // temporary hack to make the tree show up - trees are a bit finicky
      tempWid := m_currentPanelWid.p_child;
      if (!tempWid._TreeUp()) {
         tempWid._TreeDown();
      } else {
         tempWid._TreeDown();
         tempWid._TreeUp();
      }

      // use the xmlindex to get our property sheet data
      PropertySheetEmbedder *pse = m_data.getPropertySheet(index);

      // let's get a list of the nodes found in the search
      int foundProperties[];
      m_parser.getFoundPropertiesInSheet(foundProperties, index);

      int protectedProperties[];
      m_parser.getProtectedPropertiesInSheet(protectedProperties, index);

      pse -> markSpecialProperties(foundProperties, protectedProperties, null);
      pse -> reloadProperties();

      pse -> sizeColumns();
   }

   /** 
    * Searches the options by searching captions of all nodes and 
    * properties.  Recreates the options tree by showing on nodes 
    * which contain search term or who have children that do. 
    * 
    * @param term       search term 
    * @param options    search options 
    *                   D - search the help descriptions as well
    *                       as the captions
    */
   public void searchOptions(_str term = "", _str options = "")
   {
      term = strip(term);
      options = strip(options);

      if (term == m_searchTerm && options == m_searchOptions) return;
      m_searchTerm = term;
      m_searchOptions = options;

      m_parser.clearSearch();

      // we search through XML DOM
      if (term != "") {
         m_searching = SEARCHING;
         m_parser.searchOptions(m_searchTerm, m_searchOptions);
      } else {
         m_searching = NO_SEARCH;
      }

      // save current node in case we can stay there
      curCaption := m_currentCaption;

      // load search results into tree
      clearTree();
      buildNextLayer(TREE_ROOT_INDEX, true);
      selectTopTreeIndex();

      // attempt to restore last node
      showNode(curCaption, false, ISEB_RETURN);

      // if we are currently looking at the search results
      // node, then we need to reload it - it may not get reloaded otherwise
      xmlIndex := getCurrentXMLIndex();
      if (m_parser.isSearchResultsNode(xmlIndex)) {
         restoreDialog(xmlIndex);
      }

      m_searching = NO_SEARCH;
   }

   /**
    * Builds the list to go in the Search Results node - a list of
    * nodes which were found in the most recent search.
    * 
    * @return        array of strings to be put into search results
    */
   public void buildSearchNodeList(_str (&list)[])
   {
      m_parser.buildSearchNodeList(list);
   }

   /**
    * Builds the list to go in the Options History node - a list of
    * nodes which were changed in the time period specified.
    * 
    * @param changeFlags   flags specifying time range in which 
    *                      results were changed
    * 
    * @return              array of strings to be put into options history
    */
   public void buildRecentlyChangedList(int changeFlags, _str (&history)[])
   {
      m_parser.buildOptionsHistory(changeFlags, history);
   }

   #region Favorites

   /**
    * Specifies that the current node is to be designated as a
    * Favorite.
    */
   public void addFavoriteNode()
   {
      // get the current index
      index := getCurrentXMLIndex();

      if (index > 0) {
         // make the change in the XML parser
         m_parser.addFavorite(index);
      }
   }

   /**
    * Specifies that the current node is no longer to be designated
    * as a Favorite. 
    */
   public void removeFavoriteNode()
   {
      // get the current index
      index := getCurrentXMLIndex();

      if (index > 0) {
         // make the change in the XML parser
         m_parser.removeFavorite(index);
      }
   }

   /**
    * Finds out if the node specified is a Favorite or not.
    * 
    * @param treeIndex index (in the tree) of the node to check
    * 
    * @return true if the node is a Favorite, false otherwise
    */
   public bool isNodeFavorited(int treeIndex)
   {
      xmlIndex := m_relations.getXMLIndex(treeIndex);
      return m_parser.isNodeFavorited(xmlIndex);
   }

   /**
    * Rebuilds the tree with only Favorite nodes showing.  Favorite
    * nodes are bolded.
    * 
    */
   public void showOnlyFavorites()
   {
      m_parser.clearSearch();

      // we search through XML DOM
      m_searching = FAVORITES;
      m_parser.findFavorites();

      // save current node in case we can stay there
      curCaption := m_currentCaption;

      // load search results into tree
      clearTree();
      buildNextLayer(TREE_ROOT_INDEX, true);

      // attempt to restore last node
      showNode(curCaption, false, ISEB_SELECT_TOP);

      m_searching = NO_SEARCH;
   }

   /**
    * Rebuilds the tree, showing all nodes.
    * 
    */
   public void showAll()
   {
      m_searching = NO_SEARCH;

      // save current node in case we can stay there
      curCaption := m_currentCaption;

      clearTree();
      buildNextLayer();

      // attempt to restore last node
      showNode(curCaption, false, ISEB_SELECT_TOP);
   }

   /**
    * Determines whether any nodes have been favorited.
    * 
    * @return true if we have any favorite nodes, false otherwise
    */
   public bool doWeHaveAnyFavorites()
   {
      return m_parser.doWeHaveAnyFavorites();
   }

   #endregion Favorites

   /**
    * Called when the user cancels out of the options dialog.
    * Checks for any changes made to the settings and prompts to
    * apply them.
    * 
    */
   public void cancel()
   {
      // first things first, we got to check the current panel -
      // if it's a form, we might not know yet that it was modified
      processCurrentPanelBeforeSwitching(-1, OPTIONS_CANCELLING);

      // save the current caption
      curCaption := m_currentCaption;

      // don't do any more panel processing
      m_doProcessPanels = false;

      // iterate through the list of modified XML indices
      typeless index;
      for (index._makeempty();;) {

         m_modified._nextel(index);
         if (index._isempty()) break;
         if (isNodeModified(index) && m_data.getPanelType(index) == OPT_DIALOG_EMBEDDER) {

            // switch to viewing this node in case we have any message boxes coming up
            selectXMLIndexInTree(index, false, true);

            DialogEmbedder *df = m_data.getDialogEmbedder(index);
   
            // we know this is a dialog, we want to cancel it
            if (df != null) {
               df -> cancel();
            }
         }
         setTreeNodeNotModified(m_relations.getTreeIndex(index));
      }

      m_doProcessPanels = true;

      m_modified._makeempty();
   }

   public void getLangIdsWithOptionProtected(_str optionPath, _str (&langIDs)[])
   {
      m_parser.getLanguagesWithOptionProtected(optionPath, langIDs);
   }

   #region Adding/Removing/Renaming Languages, Version Control Providers & XML Reload

   /**
    * Adds a new language to the tree.
    * 
    * @param modeName      language id of language to be added
    */
   public void addNewLanguage(_str langId)
   {
      m_parser.addNewLanguageToXML(langId);

      // show our new provider's setup section after reloading the tree
      showNode(m_currentCaption, true);
   }

   /**
    * Removes a language to the tree.
    * 
    * @param modeName      mode name (language) to be added
    */
   public void removeLanguage(_str modeName)
   {
      // grab the topmost path that was deleted, update the navigator
      int removedIndices[];
      path := m_parser.removeLanguageFromXML(modeName, removedIndices);
      m_data.clearPanelInfoForIndices(removedIndices);
      m_navigator.removePath(path);

      // show our new provider's setup section after reloading the tree
      showNode(m_currentCaption, true);
   }

   /**
    * Adds a language to the hashtable of languages to be renamed
    * later.  Languages are added to this table during the apply
    * routine.  At the end of it, renameLanguages() is called and
    * these changes are applied to the underlying XML DOM of the
    * options dialog.
    * 
    * @param modeName         old language name
    * @param newModeName      new language name
    */
   public void addLanguageToRename(_str modeName, _str newModeName)
   {
      m_renamedLanguages:[modeName] = newModeName;
   }

   /**
    * Takes the languages specified in m_renamedLanguages() and
    * renames them accordingly in the XML DOM and options history
    * navigator.
    * 
    */
   private void renameLanguages(_str &savedCaption)
   {
      if (m_renamedLanguages._length() <= 0) return;

      // now rename each language
      _str oldName, newName;
      foreach (oldName => newName in m_renamedLanguages) {
         index := m_parser.renameLanguage(oldName, newName);

         m_data.clearPanelInfoForIndex(index);

         if (pos(" "oldName" ", m_currentCaption)) {
            m_currentCaption = stranslate(m_currentCaption, " "newName" ", " "oldName" ");
         } 
         if (pos(" "oldName" ", savedCaption)) {
            savedCaption = stranslate(savedCaption, " "newName" ", " "oldName" ");
         } 

         // rename the language in the tree
         index = m_relations.getTreeIndex(index);
         m_treeHandle._TreeSetCaption(index, newName);
      }

      // make sure the navigator has the updated paths
      m_navigator.mapRenamedLanguages(m_renamedLanguages);
      m_renamedLanguages._makeempty();
   }


   /**
    * Adds a new version control provider to the tree.
    * 
    * @param modeName      version control provider name to be 
    *                      added
    */
   public void addNewVersionControlProvider(_str vcName)
   {
      m_parser.addNewVersionControlProviderToXML(vcName);

      // show our new provider's setup section after reloading the tree
      showNode(m_currentCaption, true);
   }

   /**
    * Removes a version control provider from the tree.
    * 
    * @param modeName      version control provider name to be 
    *                      added
    */
   public void removeVersionControlProvider(_str vcName)
   {
      // grab the topmost path that was deleted, update the navigator
      int removedIndices[];
      path := m_parser.removeVersionControlProviderFromXML(vcName, removedIndices);
      m_data.clearPanelInfoForIndices(removedIndices);
      m_navigator.removePath(path);

      // show our new provider's setup section after reloading the tree
      showNode(m_currentCaption, true);
   }

   /**
    * Takes the languages specified in m_renamedLanguages() and
    * renames them accordingly in the XML DOM and options history
    * navigator.
    * 
    */
   public void renameVersionControlProvider(_str oldVCName, _str newVCName)
   {
      if (m_renamedLanguages._length() <= 0) return;

      // now rename each language
      index := m_parser.renameVersionControlProvider(oldVCName, newVCName);

      m_data.clearPanelInfoForIndex(index);

      if (pos(" "oldVCName" ", m_currentCaption)) {
         m_currentCaption = stranslate(m_currentCaption, " "newVCName" ", " "oldVCName" ");
      } 

      // rename the language in the tree
      index = m_relations.getTreeIndex(index);
      m_treeHandle._TreeSetCaption(index, newVCName);

      // make sure the navigator has the updated paths
      m_navigator.mapRenamedVersionControlProviders(oldVCName, newVCName);
      m_renamedLanguages._makeempty();
   }

   #endregion Adding/Removing Languages & Version Control Providers

};

