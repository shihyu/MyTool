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
#include "vsockapi.sh"
#require "OptionsXMLParser.e"
#require "OptionsData.e"
#require "OptionsHistoryNavigator.e"
#require "PropertyGetterSetter.e"
#require "RelationTable.e"
#require "se/messages/Message.e"
#require "se/messages/MessageCollection.e"
#import "box.e"
#import "context.e"
#import "listbox.e"
#import "main.e"
#import "options.e"
#import "stdprocs.e"
#import "tbcmds.e"
#import "treeview.e"
#import "se/ui/toolwindow.e"
#endregion Imports


static const MIN_DIALOG_WIDTH= 4500;
static const DEFAULT_DIALOG_HEIGHT= 5500;
static const DEFAULT_DIALOG_WIDTH= 7000;

namespace se.options;

enum IndexSelectionErrorBehavior {
   ISEB_RETURN,
   ISEB_SELECT_TOP,
   ISEB_SELECT_PARENT,
};

class OptionsTree {
   const FRAME_PADDING= 180;
   /**
    * Determines what the purpose of this options dialog is - one of the 
    * OptionsPurpose enum. 
    */
   const PURPOSE=         "optionsPurpose";
   /**
    * Whether this run of the options export was performed with the administrator 
    * command to enable protections. 
    */
   const PROTECT=         "protectOptions";

   // handles to some GUI elements
   protected int m_treeHandle = 0;
   protected int m_frameHandle = 0;
   protected int m_helpHandle = 0;

   // keeps track of the current status of the tree
   protected int m_currentPanelWid = 0;
   protected _str m_currentCaption = "";
   protected int m_currentTreeIndex = 0;

   // keeps track of the relationship between the tree and the XML DOM
   protected RelationTable m_relations;

   // parses the XML DOM
   protected OptionsXMLParser m_parser;

   // holds our precious data
   protected OptionsData m_data;

   // navigates through the history
   protected OptionsHistoryNavigator m_navigator;

   // argument sent to embedded dialogs
   protected _str m_dialogArg = "";

   // whether we want to use a delay to show the right panel
   protected bool m_optionsChangeDelay = true;

   // whether we display dialogs as summaries (property sheets) when possible
   protected bool m_dialogsAsSummaries = true;

   // the purpose of this options tree...
   protected int m_optionsTreePurpose = -1;

   // true if we grow frames to fit the panel,
   // false if the panel must conform to the frame
   private bool m_growFrame = true;

   OptionsTree()
   { }

   /** 
    * Clears the options tree and the saved info.
    * 
    */
   protected void clearTree()
   {
      m_relations.clearTable();
      
      if (m_treeHandle) {
         m_treeHandle._TreeDelete(TREE_ROOT_INDEX, 'C');
      }
   }

   /**
    * Returns whether the options tree change event should be 
    * delayed. 
    * 
    * @return true if it's delayed, false otherwise
    */
   public bool isOptionsChangeDelayed()
   {
      return m_optionsChangeDelay;
   }

   /**
    * Resets the tree change delay value to true.
    */
   public void resetOptionsChangeDelay()
   {
      m_optionsChangeDelay = true;
   }

   /**
    * Reloads an options node by deleting any information we have about it. 
    * 
    * @param caption             caption of node we want to purge
    */
   public void reloadOptionsNode(_str caption)
   {
      // find this node in the XML
      index := m_parser.findNodeByPath(caption);

      // delete the panel
      m_data.clearPanelInfoForIndex(index);

   }

   /**
    * Reloads the entire options tree, including the tree structure
    * and all the data saved for the individual nodes.
    */
   public void reloadOptionsTree()
   {
      // reloads the tree, clears out the data, and brings us right back to this node
      showNode(m_currentCaption, true);
   }

   /**
    * Reloads the whole set of options so that info can be freshly read from the 
    * XML, dialogs can be newly loaded, and property sheet values can be retrieved 
    * anew. 
    */
   public void reloadOptions()
   {
      m_currentCaption = "";
      m_currentTreeIndex = 0;
      m_currentPanelWid = 0;

      // remove all the data
      m_data.clear();
   }

   /**
    * Apply all the changes that have been made in the tree since
    * it was opened or last applied.
    *
    */
   public bool apply(bool restoreCurrent = true, bool applyCurrent = true)
   {
      return true;
   }

   /**
    * Checks to see if applying these options caused any events to fire.  Calls the 
    * appropriate events. 
    * 
    * @param changeEvents              events that need to be fired (flags)
    * @param commentLangs              Write Comment Block event - writes comment 
    *                                  block info for these langs
    */
   protected void handleChangeEvents(int changeEvents, _str (&commentLangs):[])
   {
      // do we need to update our menu bindings?
      if (changeEvents & OCEF_MENU_BIND) menu_mdi_bind_all();

      // Reinitialize socket layer
      if (changeEvents & OCEF_REINIT_SOCKET) vssInit();

      // load the user lexer file
      //if (changeEvents & OCEF_LOAD_USER_LEXER_FILE) cload(_ConfigPath() :+ USER_LEXER_FILENAME);

      // remove already used flags
      changeEvents &= ~(OCEF_MENU_BIND | OCEF_REINIT_SOCKET | OCEF_LOAD_USER_LEXER_FILE);

      // check for specific restart reasons
      if (changeEvents == OCEF_TAGGING_RESTART) {
         _message_box(get_message(VSRC_FC_MUST_EXIT_AND_RESTART_TAGGING));
      } else if (changeEvents == OCEF_THREAD_RESTART) {
         finish_background_tagging();
         //tag_restart_async_tagging();
         _message_box(get_message(VSRC_FC_MUST_EXIT_AND_RESTART_THREADS));
      } else if (changeEvents == OCEF_DIALOG_FONT_RESTART) {
         _message_box(get_message(VSRC_FC_MUST_EXIT_AND_RESTART_DIALOG_FONT));
      } else if (changeEvents == OCEF_RESTART) {
         _message_box(get_message(VSRC_FC_MUST_EXIT_AND_RESTART));
      } else if (changeEvents & (OCEF_RESTART | OCEF_DIALOG_FONT_RESTART | OCEF_THREAD_RESTART | OCEF_TAGGING_RESTART)) {
         // just use the general message
         _message_box(get_message(VSRC_FC_MUST_EXIT_AND_RESTART));
      }

      // write changes to the comment block stuff
      foreach (auto langId in commentLangs) {
         saveCommentSettingsForLang(langId);
      }
   }

   /** 
    * Given an XML DOM index, selects the corresponding index in 
    * the main options tree. 
    * 
    * @param index      index to be selected
    */
   protected bool selectXMLIndexInTree(int index, bool selectParentIfUnavailable = false, bool turnOffDelay = false)
   {
      treeIndex := m_relations.getTreeIndex(index);

      if (treeIndex < 0 && selectParentIfUnavailable) {
         do {
            index = m_parser.getParent(index);
            treeIndex = m_relations.getTreeIndex(index);
         } while (index >= 0 && treeIndex < 0);
      }

      if (treeIndex >= 0) {
         selectTreeIndex(treeIndex, turnOffDelay);
      } 

      return (treeIndex >= 0);
   }

   /**
    * Selects an index in the options tree.
    * 
    * @param index      the index to select
    */
   private void selectTreeIndex(int index, bool turnOffDelay = false)
   {
      if (index >= 0) {
         p_window_id = m_treeHandle;

         // make this node get shown instantly
         if (turnOffDelay) {
            m_optionsChangeDelay = false;
         }

         curIndex := m_treeHandle._TreeCurIndex();
         m_treeHandle._TreeSetCurIndex(index);
         if (curIndex == index || index == m_currentTreeIndex || index == TREE_ROOT_INDEX) {
            m_treeHandle.call_event(CHANGE_SELECTED, index, m_treeHandle, ON_CHANGE, 'W');
         }
         m_treeHandle._TreeRefresh();
      }
   }

   /**
    * Selects the topmost index in the tree.
    */
   protected void selectTopTreeIndex()
   {
      selectTreeIndex(TREE_ROOT_INDEX, true);
   }

   /** 
    * Builds the next layer in the options tree.  Has several 
    * different parameters that can change the display.  Note that 
    * whether m_searching is true also affects this display.
    * 
    * @param xmlIndex   parent index of layer to build (add this 
    *                   node's children).  This corresponds to the
    *                   XML index, not the tree index.
    * @param treeIndex  where to start building in the tree
    * @param recurse    whether to recurse down and build children 
    *                   as well (ignored if startNode !=
    *                   -1)
    * @param startNode  the node we are looking to display (as an
    *                   XML index). If this is specified, then the
    *                   top layer will be built, and then only
    *                   nodes which are part of the special node's
    *                   path.
    */
   protected void buildNextLayer(int treeIndex = TREE_ROOT_INDEX, bool recurse = false, int startNode = -1)
   {
      xmlIndex := m_relations.getXMLIndex(treeIndex);
      if (xmlIndex <= 0) {
         xmlIndex = m_parser.getTopOfTree();
         m_relations.setNodeRelation(0, TREE_ROOT_INDEX);
         m_relations.setNodeRelation(xmlIndex, TREE_ROOT_INDEX);
      }

      // if this is a property sheet, then we don't want to see its children in the tree
      if (m_parser.isAPropertySheet(xmlIndex) || m_parser.isADialog(xmlIndex)) return;

      m_treeHandle._TreeBeginUpdate(treeIndex);

      // loop through children
      xmlIndex = m_parser.getFirstChild(xmlIndex);
      while (xmlIndex > 0) {
         recurseThis := recurse;

         sibIndex := m_parser.getNextSibling(xmlIndex);

         // do we have a starting node?  that is, a node which we want to be 
         // already navigated to.  if so, we make sure to expand the entire path 
         // to this node
         if (startNode > 0) {
            if (startNode == xmlIndex) {        // we found our node, stop recursing
               recurse = recurseThis = false;
            } else if (m_parser.isChildOf(xmlIndex, startNode)) {     // we have an ancestor, continue recursing
               recurseThis = true;
            } else {          // this node is of no relation, do not expand it
               recurseThis = false;
            }
         } 

         caption := "";
         children := picIndex := flags := 0;
         if (!getNodeInfo(xmlIndex, caption, picIndex, children, flags, startNode, recurseThis)) {
            xmlIndex = sibIndex;
            continue;
         }

         // finally!  Add the node, already!
         int treeNodeIndex = m_treeHandle._TreeAddItem(treeIndex, caption, TREE_ADD_AS_CHILD, picIndex, picIndex, children, flags);
         m_relations.setNodeRelation(xmlIndex, treeNodeIndex);
         handleNewNode(treeNodeIndex);

         // go to next layer
         if (recurseThis) {
            buildNextLayer(treeNodeIndex, recurse, startNode);
         }

         // do the same routine with our sibling node
         xmlIndex = sibIndex;
      }

      // and we're done
      m_treeHandle._TreeEndUpdate(treeIndex);
   }

   /** 
    * This method determines if a node should be displayed and how it should be 
    * displayed in the options tree.  Any modifications to captions and icons 
    * should be done in this function. 
    *  
    * This method is meant to be overwritten by child classes in case display of 
    * nodes changes in those classes. 
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
   private bool getNodeInfo(int xmlIndex, _str &caption, int &picIndex, int &children, int &flags, int startNode, bool &recurseThis)
   {
      caption = m_parser.getCaption(xmlIndex);
      flags = 0;
      picIndex = 0;

      // whether to insert this node as a parent or a leaf - this value will 
      // be used as an argument when we insert into tree
      children = m_parser.getFirstChild(xmlIndex);

      // if it has no children or is a property sheet, then it's a leaf
      if (children < 0 || m_parser.isAPropertySheet(xmlIndex) || m_parser.isADialog(xmlIndex)) {
         children = TREE_NODE_LEAF;                   // leaf value
         recurseThis = false;
      } else {
         // and we expand the entire path to the starting node
         if (startNode > 0 && recurseThis) {
            children = TREE_NODE_EXPANDED;                 // expanded parent
         } else {
            children = TREE_NODE_COLLAPSED;                 // non-expanded parent
         }
      }

      return true;
   }

   /**
    * Does some voodoo to a new tree node.  Meant to be overwritten by child 
    * classes. 
    * 
    * @param treeIndex           the newly added node to the options tree
    */
   protected void handleNewNode(int treeIndex)
   {
   }

   /**
    * Can be used to show a particular form (i.e. a dialog that has 
    * been transported directly into the options tree rather than 
    * transformed into a property sheet). 
    * 
    * @param form       name of form to be shown
    * 
    * @return           whether we were able to find it
    */
   public bool showDialogNode(_str form, _str arguments, int errorBehavior = ISEB_RETURN)
   {
      index := m_parser.findDialogNode(form);

      if (index > 0) {
         m_dialogArg = arguments;
         return showXMLIndex(index, errorBehavior);
      } 

      if (errorBehavior == ISEB_SELECT_TOP) {
         selectTopTreeIndex();
      }

      return false;
   }

   /**
    * Shows a 'language' node in the tree.  Can optionally specify
    * a subnode of a language category to show in the tree.
    * 
    * @param modeName      language node we want to see
    * @param options       subnode of language we want to see
    * @param arguments     any arguments to send to the subnode
    * 
    * @return              whether we were able to show the node specified
    */
   public bool showLanguageNode(_str modeName, _str options = "", _str arguments = "", int errorBehavior = ISEB_RETURN)
   {
      // find the node
      index := m_parser.findLanguageNode(modeName, options);

      // set the arguments and show it
      if (index > 0) {
         m_dialogArg = arguments;
         return showXMLIndex(index, errorBehavior);
      }

      if (errorBehavior == ISEB_SELECT_TOP) {
         selectTopTreeIndex();
      }

      return false;
   }

   /**
    * Shows a 'version control' node in the tree.  Can optionally 
    * specify a subnode of a version control category to show in 
    * the tree. 
    * 
    * @param vcName        version control node we want to see
    * @param options       subnode of version control category we 
    *                      want to see
    * @param arguments     any arguments to send to the subnode
    * 
    * @return              whether we were able to show the node specified
    */
   public bool showVersionControlNode(_str vcName, _str options = "", _str arguments = "", int errorBehavior = ISEB_RETURN)
   {
      // find the node
      index := m_parser.findVersionControlNode(vcName, options);

      // set the arguments and show it
      if (index > 0) {
         m_dialogArg = arguments;
         return showXMLIndex(index, errorBehavior);
      }

      if (errorBehavior == ISEB_SELECT_TOP) {
         selectTopTreeIndex();
      }

      return false;
   }

   /**
    * Searches for the node, then expands the path to the node and
    * selects it in the tree.
    *
    * Used to restore a particular node.
    *
    * @param caption       caption to search for, can be a full or partial path 
    * @param reload        whether to reload the tree before showing the node 
    * @param errorToTop    whether to select the top node if we can't find the one 
    *                      we are looking for
    * @param arguments     any arguments we might want to send to the node 
    */
   public bool showNode(_str caption, bool doReload = false, 
                           int errorBehavior = ISEB_RETURN, _str arguments = "")
   {
      // first find the node we are looking for
      index := m_parser.findNodeByPath(caption);
      if (index < 0 && caption == "root") index = TREE_ROOT_INDEX;
      if (index >= 0) {

         // reload the tree because we said so
         if (doReload) {
            clearTree();
            buildNextLayer(TREE_ROOT_INDEX, true, index);
         }

         // set these to our arguments so they can be sent to whatever node
         m_dialogArg = arguments;

         // now see if we can select it
         if (showXMLIndex(index, errorBehavior)) return true;
      }

      // if we couldn't find it, sometimes we just want to hop on the top node
      if (errorBehavior == ISEB_SELECT_TOP) selectTopTreeIndex();

      return false;
   }

   /**
    * Shows a node in the tree without completely reloading the
    * tree.  Useful when navigating to search result nodes or
    * history nodes.
    * 
    * @param index    index of node that we want
    * 
    * @return           true if we were able to load node, false if 
    *                   there was an error
    */
   private bool showXMLIndex(int index, int errorBehavior = ISEB_RETURN)
   {
      // is the next node already in the tree?  if not, put it there!
      xmlIndex := index;
      treeIndex := m_relations.getTreeIndex(xmlIndex);
      while (treeIndex < 0 && xmlIndex > 0) {
         xmlIndex = m_parser.getParent(xmlIndex);
         treeIndex = m_relations.getTreeIndex(xmlIndex);
      }

      if (treeIndex > 0) {
         m_treeHandle._TreeGetInfo(treeIndex, auto children);
         if (children != TREE_NODE_EXPANDED) {
            buildNextLayer(treeIndex, true, index);
         }
      }

      if (!selectXMLIndexInTree(index, (errorBehavior == ISEB_SELECT_PARENT), true)) {
         if (errorBehavior == ISEB_SELECT_TOP) {
            selectTopTreeIndex();
         }
         return false;
      }

      return true;
   }

   /** 
    * Initializes the options tree.
    * 
    * @param treeID        window ID of main tree
    * @param frameID       window ID of right frame on form
    */
   public bool init(int treeID = 0, int frameID = 0, int helpID = 0, _str file = "")
   {
      m_treeHandle = treeID;
      m_frameHandle = frameID;
      m_helpHandle = helpID;
      m_currentPanelWid = 0;

      m_relations.clearTable();

      m_data.clear();
      m_parser.clear();
      m_navigator.clearHistory();

      if (m_frameHandle) {
         m_growFrame = (m_frameHandle.p_parent.p_border_style == BDS_SIZABLE);
      } else {
         m_growFrame = false;
      }

      if (m_parser.initParser(m_optionsTreePurpose, file)) {

         // we might have a starting size for the tree...check for it now
         checkDialogDefaultSize();

      } else {
         close();
         return false;
      }

      return true;
   }

   /**
    * Checks to see if the XML file containing options has specified a default size 
    * for the right hand panel.  If so, sets the panel to that size.
    */
   private void checkDialogDefaultSize()
   {
      // no point in doing this if we don't have a frame handle
      if (!m_frameHandle) return;
      parentForm := m_frameHandle.p_parent;

      width := 0;
      height := 0;

      m_parser.getDefaultOptionsDialogSize(height, width);
      if (width > 0) parentForm.p_width = width;
      if (height > 0) parentForm.p_height = height;

      // call on_resize event manually - trust me
      parentForm.call_event(parentForm, ON_RESIZE);
   }

   /** 
    * Expands a node in the tree by either building the next layer 
    * of children or displaying the right panel (either dialog or 
    * property sheet) that corresponds to the selected node. 
    * 
    * @param treeIndex        node in the tree that was expanded
    */
   public void expandTreeNode(int treeIndex)
   {
      nodeIndex := m_relations.getXMLIndex(treeIndex);
      if (nodeIndex > 0) {
         buildNextLayer(treeIndex);
      } 
   }

   /** 
    * Clears the right panel to make room for something else to
    * appear. 
    *  
    * @param oldIndex         index corresponding to the panel about to be 
    *                         hidden
    */
   private void clearRightPanel(int oldIndex)
   {
      // we don't actually clear it, only hide it so that we can use it again later
      if (m_currentPanelWid) {
         if (_iswindow_valid(m_currentPanelWid)) {
            m_currentPanelWid._ShowWindow(SW_HIDE);
         } else {
            // something bad and crazy happened.  hopefully, not often.
            m_currentPanelWid = 0;
         }
      } 
   }

   /**
    * Does any processing to a PropertySheet before it is loaded.  This can 
    * included getting values of individual properties.  This method is meant to 
    * overloaded by child classes. 
    * 
    * @param ps      pointer to PropertySheet to process
    */
   private void processPropertySheet(PropertySheet * ps)
   { }

   /**
    * Does any necessary initialization to a property sheet the first time it is 
    * displayed. 
    * 
    * @param index         xml index of new property sheet
    */
   private void initializePropertySheet(int index)
   { }

   /**
    * Refreshes the view of a property sheet.  Updates the
    * highlight colors if we are searching.  This method is meant to be 
    * overwritten by child classes. 
    * 
    * @param index   index of property sheet to refresh
    */
   private void refreshPropertySheet(int index)
   { }


   /**
    * Load a form template into the frame on the right side of the
    * options dialog.
    * 
    * @param form      name of form to load
    * @param arguments any arguments to send to form's on_create events
    * 
    * @return window id of newly loaded form
    */
   private int loadDialogTemplate(_str form, _str arguments = null, bool sizeToFrame = false)
   {
      formWid := -1;

      // extract the dialog name
      formIndex := find_index(form, oi2type(OI_FORM));
      if (formIndex) {
         if (arguments == null) {
            formWid = _load_template(formIndex, m_frameHandle, 'HPN');
         } else {
            formWid = _load_template(formIndex, m_frameHandle, 'HPN', arguments);
         }

         etab := find_index("_options_etab2", EVENTTAB_TYPE);
         formWid.p_eventtab2 = etab;

         if (sizeToFrame) {
            targetWidth := m_frameHandle.p_width - (FRAME_PADDING * 2);
            targetHeight := m_frameHandle.p_height - (FRAME_PADDING * 2);
            if (!m_growFrame || formWid.p_width < targetWidth) {
               formWid.p_width = targetWidth;
            }
            if (!m_growFrame || formWid.p_height < targetHeight) {
               formWid.p_height = targetHeight;
            }
         }

         formWid.p_y = FRAME_PADDING;
         formWid.p_x = FRAME_PADDING;

      }
      return formWid;
   }

   /** 
    * Builds the right panel of a node which contains reference to 
    * a dialog.  Finds the form referenced and loads the template 
    * into the right panel of the options form. 
    * 
    * @param index      index of node in XML DOM
    * 
    * @return int       window id of loaded template
    */
   private int buildDialog(int index, DialogEmbedder &dt)
   {
      langId := dt.getLanguage();
      needsLangId := ( langId != null && langId != "" && 0 != find_index(dt.getFormName():+"_create_needs_lang_argument", PROC_TYPE));
      formWid := loadDialogTemplate(dt.getFormName(), (needsLangId? langId:null));

      if (formWid) {

         dt.setWID(formWid);
         initializeDialog(dt);

         // if it's sizable, let's make it taller, if possible
         if (formWid.p_border_style == BDS_SIZABLE && dt.getHeight() < m_frameHandle.p_height - (FRAME_PADDING * 2)) {
            formWid.p_height = m_frameHandle.p_height - (FRAME_PADDING * 2);
         } else {
            formWid.p_height = dt.getHeight();
         }

         // if it's sizable, let's make it wider, if possible
         if (formWid.p_border_style == BDS_SIZABLE && dt.getWidth() < m_frameHandle.p_width - (FRAME_PADDING * 2)) {
            formWid.p_width = m_frameHandle.p_width - (FRAME_PADDING * 2);
         } else {
            if (dt.getWidth() < MIN_DIALOG_WIDTH) {
               formWid.p_width = MIN_DIALOG_WIDTH;
            } else {
               formWid.p_width = dt.getWidth();
            }
         }

         formWid._ShowWindow(SW_SHOW);
      }

      return formWid;
   }

   /**
    * Initializes a dialog after it is loaded.  This method is meant to possibly be 
    * overloaded by child classes. 
    * 
    * @param de         DialogEmbedder containing info about dialog
    */
   protected void initializeDialog(DialogEmbedder &de)
   {
      de.initialize(m_dialogArg);
      m_dialogArg = "";
   }

   /**
    * Loads a property sheet into the right panel of the options
    * dialog.  Does not populate the sheet with properties.
    * 
    * @return window id of property sheet
    */
   private int loadPropertySheetTemplate()
   {
      newWid := loadDialogTemplate("_property_sheet_form", m_optionsTreePurpose, true);

      if (newWid) {

         newWid.p_tab_stop = true;
         newWid.p_tab_index = 4;

         newWid._ShowWindow(SW_SHOW);
      }

      return newWid;
   }

   /**
    * Finds the minimum size allowed by the currently displayed
    * panel.
    *
    * @param height minimum height
    * @param width  minimum width
    */
   public void getMinimumPanelDimensions(int &height, int &width)
   {
      width = DEFAULT_DIALOG_WIDTH;
      height = DEFAULT_DIALOG_HEIGHT;

      index := getCurrentXMLIndex();
      if (m_data.getPanelType(index) == OPT_DIALOG_EMBEDDER) {
         DialogEmbedder *dt = m_data.getDialogEmbedder(index);
         height = dt -> getHeight();

         width = dt -> getWidth();
         if (width < MIN_DIALOG_WIDTH) width = MIN_DIALOG_WIDTH;
      }
   }

   /**
    * Finds the minimum frame size allowed by the currently displayed
    * panel.
    * 
    * @param height minimum height
    * @param width  minimum width
    */
   public void getMinimumFrameDimensions(int &height, int &width)
   {
      getMinimumPanelDimensions(height, width);
      width += (FRAME_PADDING * 2);
      height += (FRAME_PADDING * 2);
   }

   /**
    * Since the options dialog grows as bigger forms are shown, the
    * property sheets and category help panels are resized to 
    * utilize the space provided. This function resizes the 
    * panels to fit in the space allowed. 
    * 
    * @param pWid   window id of panel to be resized
    */
   private void resizePanel()
   {
      // get the minimum allowed dimensions for this form
      int minWidth, minHeight;
      getMinimumPanelDimensions(minHeight, minWidth);

      // now figure out the current frame dimensions
      width := m_frameHandle.p_width - (FRAME_PADDING * 2);
      height := m_frameHandle.p_height - (FRAME_PADDING * 2);

      // see if anything needs to get bigger or smaller
      changed := false;
      if (width > m_currentPanelWid.p_width ||
          width < m_currentPanelWid.p_width && width > minWidth) {
         m_currentPanelWid.p_width = width;
         changed = true;
      } else if (width < minWidth) {
         m_currentPanelWid.p_width = minWidth;
      }

      if (height > m_currentPanelWid.p_height ||
          height < m_currentPanelWid.p_height && height > minHeight) {
         m_currentPanelWid.p_height = height;
         changed = true;
      } else if (height < minHeight) {
         m_currentPanelWid.p_height = minHeight;
      }

      if (!changed) {
         m_currentPanelWid.call_event(m_currentPanelWid, ON_RESIZE);
      }
   }

   /**
    * Gets the path of captions from the top node in the tree to
    * the given node.
    * 
    * @param index  node whose path to retrieve
    * 
    * @return caption path
    */
   public _str getTreeNodePath(int index)
   {
      if (index < 0) return "";

      path := m_treeHandle._TreeGetCaption(index);

      index = m_treeHandle._TreeGetParentIndex(index);

      // keep getting parents until we ain't got no more
      while (index > 0) {
         path = m_treeHandle._TreeGetCaption(index) :+ NODE_PATH_SEP :+ path;

         index = m_treeHandle._TreeGetParentIndex(index);
      }

      // remove any * from the path that indicate modification
      path = stranslate(path,  "",  "*");
      path = strip(path);

      return path;
   }

   /**
    * Resizes a resizable form to use the space allowed in the
    * options dialog.  Dialog may have grown to fit a larger
    * dialog.
    */
   private void resizeFormForPanel()
   {
      if (m_currentPanelWid != 0) {

         parentForm := m_frameHandle.p_parent;
         if (m_growFrame) {

            // disable the minimum size constraint - we'll set it again in a minute
            parentForm._set_minimum_size(0, 0);

            // get the width and height of the rest of the form so we can add it to the
            // min frame size to get the min form size
            extraFormWidth := parentForm.p_width - m_frameHandle.p_width;
            extraFormHeight := parentForm.p_height - m_frameHandle.p_height;

            // make sure the parent form conforms to the size of the new panel
            width := m_currentPanelWid.p_width + (FRAME_PADDING * 2);
            widthDiff := 0;
            if (m_frameHandle.p_width < width) {
               widthDiff = width - m_frameHandle.p_width;
            }

            height := m_currentPanelWid.p_height + (FRAME_PADDING * 2);
            heightDiff := 0;
            if (m_frameHandle.p_height < height) {
               heightDiff = height - m_frameHandle.p_height;
            }

            parentForm.p_height += heightDiff;
            parentForm.p_width += widthDiff;

            // now set a minimum width/height so the user cannot resize them to be smaller
            int minHeight, minWidth;
            getMinimumFrameDimensions(minHeight, minWidth);

            minWidth += extraFormWidth;
            minHeight += extraFormHeight;
            parentForm._set_minimum_size(minWidth, minHeight);

         } else {
            // we are not moving the form a bit, so make sure the panel fits
            m_currentPanelWid.p_width = m_frameHandle.p_width - (FRAME_PADDING * 2);
            m_currentPanelWid.p_height = m_frameHandle.p_height - (FRAME_PADDING * 2);
         }
      }
   }

   /**
    * Selects a tree node specified by the options history
    * navigator.  Can either go to the next node in the history or
    * a node specified by caption.
    * 
    * @param caption optional caption of node to go to
    */
   public void goForward(_str caption = "")
   {
      if (m_navigator.canGoForward()) {
         goToHistoryNodeLocation(m_navigator.goForward(caption));
      }
   }

   /**
    * Selects a tree node specified by the options history
    * navigator.  Can either go to the last node in the history or
    * a node specified by caption.
    * 
    * @param caption optional caption of node to go to
    */
   public void goBack(_str caption = "")
   {
      if (m_navigator.canGoBack()) {
         goToHistoryNodeLocation(m_navigator.goBack(caption));
      }
   }

   /**
    * Selects a tree node specified by the HistoryNode sent.
    * 
    * @param hn     specifies where to go
    */
   private void goToHistoryNodeLocation(HistoryNode hn)
   {
      index := m_relations.getTreeIndex(hn.Index);
      if (index >= 0) {
         selectTreeIndex(index, true);
      } else {
         showNode(hn.Caption);
      }
   }

   /**
    * Determines whether the user can go Back in the options
    * history navigator.
    * 
    * @return true if user can go back, false otherwise
    */
   public bool canGoBack()
   {
      return m_navigator.canGoBack();
   }

   /**
    * Determines whether the user can go Forward in the options
    * history navigator.
    * 
    * @return true if user can go forward, false otherwise
    */
   public bool canGoForward()
   {
      return m_navigator.canGoForward();
   }


   /**
    * Retrieves the list of previously visited nodes by their 
    * caption paths. 
    * 
    * @return array of node caption paths
    */
   public STRARRAY getBackList()
   {
      return m_navigator.buildBackMenu();
   }

   /**
    * Retrieves the list of previously visited nodes by their 
    * caption paths. 
    * 
    * @return array of node caption paths
    */
   public STRARRAY getForwardList()
   {
      return m_navigator.buildForwardMenu();
   }

   /**
    * Goes to a tree node by displaying the associated information
    * in the right side panel.
    * 
    * @param index  node to be visited
    */
   public int goToTreeNode(int treeIndex)
   {
      // these are the same, so don't change!
      newCap := getTreeNodePath(treeIndex);
      if (m_currentTreeIndex == treeIndex && m_currentCaption == newCap) {
         return 1;
      }

      // grab the xml index before we do anything
      // the tree relations might be reloaded during the call to processCurrentPanel, so 
      // we want to save the xml index, which will not change
      xmlIndex := m_relations.getXMLIndex(treeIndex);

      // see if we need to do any cleanup operations
      if (!processCurrentPanelBeforeSwitching(m_currentTreeIndex)){
         // the old panel says we can't switch away...
         selectTreeIndex(m_currentTreeIndex);
      } else {
         oldIndex := m_currentTreeIndex;

         // retrieve this again - it's probably the same as it was before, but it 
         // might have changed if the tree got reloaded
         curTreeIndex := m_treeHandle._TreeCurIndex();
         newTreeIndex := m_relations.getTreeIndex(xmlIndex);
         if (treeIndex != newTreeIndex || treeIndex != curTreeIndex) {
            // okay, we had a reload of the tree here, so we have to make sure we have the 
            // right index in the tree selected
            showXMLIndex(xmlIndex);
         } else {
            // the tree was not reloaded, so we can assume that the tree index was right
            m_currentTreeIndex = newTreeIndex;

            // set the current caption so that if user closes form, we'll know where we were
            m_currentCaption = newCap;
     
            m_navigator.goTo(xmlIndex, m_currentCaption);
      
            // this HAS to go before we show the right panel - some dialogs depend on it!
            m_frameHandle.p_caption = m_parser.getFrameCaption(xmlIndex);
            
            showRightPanel(xmlIndex, oldIndex);
         }
      }

      return 0;
   }

   /**
    * This method is meant to be overwritten by a child class.  This method will 
    * be called right before we hide a panel to switch to another one.  Any 
    * processing that needs to be done to a panel before hiding it needs to be 
    * done in this function. 
    * 
    * @param treeIndex           tree index corresponding to the current panel 
    *                            (the one about to be changed)
    *  
    * @return                    true if everything is cool, false if we should 
    *                            not switch
    */
   private bool processCurrentPanelBeforeSwitching(int treeIndex = -1, int action = OPTIONS_SWITCHING)
   {
      return true;
   }

   /**
    * Displays the right side panel information associated with the
    * current node.
    * 
    * @param newXMLIndex
    *               XML index associated with our new current node
    * @param oldTreeIndex
    *               tree index that we were previously on
    */
   private void showRightPanel(int newXMLIndex, int oldTreeIndex)
   {
      panelWid := 0;

      if (newXMLIndex > 0) {
         // we have to clear the existing options in the right panel
         clearRightPanel(oldTreeIndex);
         clearPanelHelp();

         // has this already been opened?
         panelWid = m_data.getWID(newXMLIndex);

         // we've opened this before - just show what was saved and we are done
         if (panelWid != null && _iswindow_valid(panelWid)) {
            panelWid._ShowWindow(SW_SHOW);
            m_currentPanelWid = panelWid;

            switch (m_data.getPanelType(newXMLIndex)) {
            case OPT_PROPERTY_SHEET:
               refreshPropertySheet(newXMLIndex);
               break;
            case OPT_DIALOG_EMBEDDER:
               restoreDialog(newXMLIndex);
               break;
            }
         } else {
            panelWid = buildRightPanel(newXMLIndex);

            // save our new panel so we can reuse it
            if (panelWid > 0) {
               m_data.setWID(newXMLIndex, panelWid);
               m_currentPanelWid = panelWid;
            }

            // mark initial attributes on property sheet
            panelType := m_data.getPanelType(newXMLIndex);
            if (panelType == OPT_PROPERTY_SHEET || panelType == OPT_DIALOG_SUMMARY_EXPORTER) {
               initializePropertySheet(newXMLIndex);
            }
         }

         resizeFormForPanel();
         resizePanel();
         panelType := m_data.getPanelType(newXMLIndex);
         if (panelType == OPT_DIALOG_EMBEDDER || panelType == OPT_DIALOG_FORM_EXPORTER) {
            updatePanelHelp();
         }
      }
   }

   /**
    * Restores a dialog to the display.  This dialog must have been previously 
    * displayed, then navigated back to.  This method can be overloaded by child 
    * classes. 
    * 
    * @param xmlIndex            index in xml pointing to dialog
    */
   protected void restoreDialog(int xmlIndex)
   {
      m_data.getDialogEmbedder(xmlIndex) -> restoreState(m_dialogArg);
      m_dialogArg = "";
   }

   /** 
    * Builds the right panel of the options dialog, which is an 
    * empty frame.  Fills it with either a sub-dialog, or a 
    * property sheet. 
    * 
    * @param index         index of selected node in tree - this 
    *                      will relate to a node in the XML DOM
    *                      where we will gather info to build the
    *                      panel
    */
   private int buildRightPanel(int index)
   {
      panelWid := 0;

      // build the appropriate data according to the type of node we're on
      info := null;
      if (m_parser.buildRightPanelData(index, info, m_dialogsAsSummaries)) {
         switch (info._typename()) {
         case "se.options.PropertySheet":
            // build and populate a property sheet
            PropertySheet ps = (PropertySheet)info;
            processPropertySheet(&ps);
            panelWid = loadPropertySheetTemplate();
            PropertySheetEmbedder pse;
            pse.initialize(panelWid, ps, m_helpHandle);
            m_data.setPanelInfo(index, pse);
            panelWid.p_help = ps.getSystemHelp();
            break;
         case "se.options.DialogEmbedder":
            // build a DialogTransformer, use it to load a dialog template
            DialogEmbedder dt = (DialogEmbedder)info;

            if (m_parser.isDialogShared(index)) {
               form := dt.getFormName();
               if (m_data.isAlreadyShared(form)) {
                  panelWid = m_data.getSharedWID(form);
                  dt.setWID(panelWid);
                  panelWid._ShowWindow(SW_SHOW);
                  dt.restoreState();
               } else {
                  panelWid = buildDialog(index, dt);
                  m_data.addSharedWID(form, panelWid);
               }
            } else {
               panelWid = buildDialog(index, dt);
            }
            m_data.setPanelInfo(index, dt);
            panelWid.p_help = dt.getSystemHelp();
            break;
         case "se.options.DialogExporter":
            DialogExporter de = (DialogExporter)info;
            if (de.getPanelType() == OPT_DIALOG_FORM_EXPORTER) {
               panelWid = buildCategoryHelpPanel(de.getCaption());
            } else {
               // build a property sheet for this one...but with dialog info
               if (!de.isSummaryBuilt()) {
                  de.buildSummary();
               }
               panelWid = loadPropertySheetTemplate();
               de.initializeSummary(panelWid, m_helpHandle);
            }

            m_data.setPanelInfo(index, de);
            panelWid.p_help = de.getSystemHelp();
            break;
         case "se.options.CategoryHelpPanel":
            // we're on a category, display something helpful
            CategoryHelpPanel chp = (CategoryHelpPanel)info;
            panelWid = buildCategoryHelpPanel(chp.getPanelHelp());
            m_data.setPanelInfo(index, chp);
            if (chp.getSystemHelp() != null) {
               panelWid.p_help = chp.getSystemHelp();
            } else {
               panelWid.p_help = "";
            }
            break;
         }

      }

      return panelWid;
   }

   /**
    * Builds a CategoryHelpPanel - an informational panel displayed 
    * whenever a category is selected in the options tree.
    * 
    * @param chp     object containing information used to build panel
    * 
    * @return        window id of new panel
    */
   private int buildCategoryHelpPanel(_str panelHelp)
   {
      formWid := loadDialogTemplate("_options_category_help_form", panelHelp);
      if (formWid) {

         formWid.p_y = FRAME_PADDING;
         formWid.p_x = FRAME_PADDING;
         formWid.p_tab_stop = true;
         formWid.p_tab_index = 4;

         // if it's sizable, let's make it taller, if possible
         if (!m_growFrame || DEFAULT_DIALOG_HEIGHT < m_frameHandle.p_height - (FRAME_PADDING * 2)) {
            formWid.p_height = m_frameHandle.p_height - (FRAME_PADDING * 2);
         } else {
            formWid.p_height = DEFAULT_DIALOG_HEIGHT;
         }

         // if it's sizable, let's make it wider, if possible
         if (!m_growFrame || DEFAULT_DIALOG_WIDTH < m_frameHandle.p_width - (FRAME_PADDING * 2)) {
            formWid.p_width = m_frameHandle.p_width - (FRAME_PADDING * 2);
         } else {
            formWid.p_width = DEFAULT_DIALOG_WIDTH;
         }

         formWid._ShowWindow(SW_SHOW);
      }
      return formWid;
   }

   /**
    * Returns the currently selected index in the options tree.
    * 
    * @return        currently selected index in options tree
    */
   protected int getCurrentTreeIndex()
   {
      return m_treeHandle._TreeCurIndex();
   }

   /**
    * Returns the index in the XML DOM which corresponds to the 
    * currently selected index in the options tree. 
    * 
    * @return        current XML DOM index
    */
   protected int getCurrentXMLIndex()
   {
      index := getCurrentTreeIndex();
      return m_relations.getXMLIndex(index);
   }

   /**
    * Called when the user cancels out of the options dialog.
    * Checks for any changes made to the settings and prompts to
    * apply them. 
    *  
    * Meant to be overwritten. 
    * 
    */
   public void cancel()
   { }

   /**
    * Determines if the options dialog is currently open by
    * checking to see if the XML DOM is open.
    * 
    * @return true if the XML DOM is open, false otherwise
    */
   public bool isOpen()
   {
      return m_parser.isOpen();
   }

   /** 
    * Closes the options tree by saving and closing the XML DOM and
    * deleting all the created child windows.
    * 
    */
   public void close()
   {
      if (m_parser.isOpen()) {

         // clear the tree
         clearTree();

         m_data.clear();
         m_navigator.clearHistory();
         m_parser.closeOptionsDOM();
         m_parser.clear();
      }
   }

   #region Options Help Related Methods

   /**
    * Returns the current p_help tag for the panel that is
    * currently being displayed on the right side of the options
    * dialog.
    * 
    * @return        p_help tag for the current right panel
    */
   public _str getCurrentSystemHelp()
   {
      return m_currentPanelWid.p_help;
   }

   /**
    * Updates the text in the help label for the current panel.
    */
   public void updatePanelHelp()
   {
      helpIdx := getCurrentXMLIndex();
      if(helpIdx) {
          m_helpHandle.p_text = m_data.getHelp(helpIdx);
      } else {
          m_helpHandle.p_text = "";
      }
   }

   /**
    * Clears the text in the help label.
    */
   public void clearPanelHelp()
   {
      m_helpHandle.p_text = "";
   }

   /**
    * Updates the text in the help label for the current property 
    * (only used when a property sheet is visible). 
    */
   public void updatePropertyHelp(_str helpInfo)
   {
      m_helpHandle.p_text = helpInfo;
   }

   #endregion Options Help Related Methods

   /**
    * Sets up an error log to log any errors found.
    */
   protected se.messages.MessageCollection * setupErrorLog(_str errMsgSrc, _str errMsgType)
   {
      // add this to vs.log
      dsay("Begin "errMsgType" log:");

      if (_haveBuild()) {
         se.messages.MessageCollection* mCollection = get_messageCollection();
         mCollection -> removeMessages(errMsgSrc);

         // create a message type
         se.messages.Message newMsgType;
         newMsgType.m_creator = errMsgSrc;
         newMsgType.m_type = errMsgType;
         newMsgType.m_sourceFile = "";
         newMsgType.m_date = "";
         newMsgType.m_autoClear = se.messages.Message.MSGCLEAR_EDITOR;
         mCollection -> newMessageType(newMsgType);

         return mCollection;
      } else {
         // message list is not available in standard edition
         sendMessageToOutputWindow(errMsgSrc" Output:", true);

         return null;
      }
   }

   /**
    * Finishes up our export/import log.  If there are errors, lets
    * the user know where to find them.
    *
    * @param errors
    * @param msgSrc
    */
   protected void endErrorLog(bool errors, _str msgSrc)
   {
      // no errors?  Just end the log
      if (!errors) {

         text := msgSrc" ended with no errors.";

         // we only put out a message to close off the output log
         if (!_haveBuild()) {
            sendMessageToOutputWindow(text);
         }

         // add this to vs.log
         dsay(text);

      } else {
         if (_haveBuild()) {
            _message_box("There were errors performing "lowcase(msgSrc)".  Please see the Message List for detailed information.", msgSrc);
            activate_messages();
         } else {
            sendMessageToOutputWindow("End "msgSrc".");
            _message_box("There were errors performing "lowcase(msgSrc)".  Please see the Output Window for detailed information.", msgSrc);
            activate_output();
         }

         dsay("End "msgSrc" error log.");
      }

   }

   /**
    * Logs errors.
    *
    * @param mCollection            pointer to the message collection which
    *                               collects the error messages
    * @param caption                caption of new error messages
    * @param log                    list of errors
    */
   protected void logErrors(se.messages.MessageCollection * mCollection, 
                            _str caption,
                            _str log, 
                            _str errMsgSrc, 
                            _str errMsgType,
                            _str errFileName="")
   {
      // each error is one sentence long
      _str errors[];
      split(log, OPTIONS_ERROR_DELIMITER, errors);

      foreach (auto errorMsg in errors) {

         if (strip(errorMsg)) {

            desc := caption":  "errorMsg;

            if (_haveBuild()) {
               // send this stuff to the logger
               se.messages.Message newMsg;
               newMsg.m_creator = errMsgSrc;
               newMsg.m_type = errMsgType;
               newMsg.m_description = desc;
               newMsg.m_sourceFile = errFileName;
               newMsg.m_lineNumber = 1;
               newMsg.m_colNumber = 1;
               newMsg.m_date = "";
               mCollection->newMessage(newMsg);
            } else {
               // message list is not available in standard edition
               sendMessageToOutputWindow("   "desc);
            }

				// add this to vs.log
				dsay("   "desc);
         }
      }
   }

   /**
    * Adds some text to the output window.
    *
    * @param text
    */
   private void sendMessageToOutputWindow(_str text, bool clearBefore = false)
   {
      formwid := activate_tool_window("_tboutputwin_form", false, "", false);
      if (formwid) {

         _nocheck _control ctloutput;
         formwid.ctloutput.bottom();

         if (clearBefore) formwid.ctloutput._lbclear();
         formwid.ctloutput.insert_line(text);
      }
   }
};

