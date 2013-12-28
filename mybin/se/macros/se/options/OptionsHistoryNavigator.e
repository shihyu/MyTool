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
#endregion Imports

namespace se.options;

/**
 * Keeps up with history information about where the user has
 * clicked in the options tree
 * 
 */
struct HistoryNode {
   _str Caption;        // path of a node clicked
   int Index;           // XML index of node clicked
};

/**
 * The OptionsHistoryNavigator allows the user to use
 * browser-like navigation buttons to go back and forth to
 * previously visited nodes in the options tree.  This became
 * necessary as we added buttons and links between nodes in the
 * tree.
 * 
 */
class OptionsHistoryNavigator {
   private HistoryNode m_history[];       // our history
   private int m_current = -1;            // the index of node where the user currently sits
   private int m_top = -1;                // the index of the top of the history

   /**
    * Constructor.
    * 
    */
   OptionsHistoryNavigator()
   {
      m_history._makeempty();
   }

   /**
    * Adjusts the navigator accordingly for when a language is
    * renamed.  If any nodes have paths that contain a renamed
    * language name, the paths are changed to reflect the new
    * language name.
    * 
    * @param renamedLangs        hashtable of renamed languages,
    *                            keyed by the old language name
    */
   public void mapRenamedLanguages(_str renamedLangs:[])
   {
      int i;
      for (i = 0; i <= m_top; i++) {
         caption := m_history[i].Caption;

         // this may have a renamed language in it
         langPos := lastpos('Languages', caption);
         if (langPos) {

            // grab the part of the path after languages
            brackPos1 := pos('>', caption,  langPos);
            brackPos2 := pos('>', caption,  brackPos1 + 1);
            lang := '';
            if (brackPos2) {
               lang = substr(caption, brackPos1 + 1, brackPos2 - (brackPos1 + 1)); 
            } else {
               lang = substr(caption, brackPos1 + 1);
            }
            lang = strip(lang);

            // check if it was renamed
            if (renamedLangs._indexin(lang)) {
               caption = stranslate(caption, ' 'renamedLangs:[lang]' ', ' 'lang' ');
               m_history[i].Caption = caption;
            }
         }
      }
   }

   /**
    * Adjusts the navigator accordingly for when a version control 
    * provider is renamed. If any nodes have paths that contain a 
    * renamed name, the paths are changed to reflect the new name. 
    * 
    * @param renamedLangs        hashtable of renamed languages,
    *                            keyed by the old language name
    */
   public void mapRenamedVersionControlProviders(_str oldVCName, _str newVCName)
   {
      int i;
      for (i = 0; i <= m_top; i++) {
         caption := m_history[i].Caption;

         // this may have a renamed language in it
         vcPos := lastpos('Version Control Providers', caption);
         if (vcPos) {

            // grab the part of the path after languages
            brackPos1 := pos('>', caption,  vcPos);
            brackPos2 := pos('>', caption,  brackPos1 + 1);
            vcName := '';
            if (brackPos2) {
               vcName = substr(caption, brackPos1 + 1, brackPos2 - (brackPos1 + 1)); 
            } else {
               vcName = substr(caption, brackPos1 + 1);
            }
            vcName = strip(vcName);

            // check if it was renamed
            if (vcName == oldVCName) {
               caption = stranslate(caption, ' 'newVCName' ', ' 'oldVCName' ');
               m_history[i].Caption = caption;
            }
         }
      }
   }

   /**
    * If a part of the options tree is removed (usually by deleting
    * a language), we want to remove any references to nodes
    * starting with that path in the navigator.
    * 
    * @param path   the path that was removed
    */
   public void removePath(_str path)
   {
      int i;
      removedSoFar := 0;
      for (i = 0; i + removedSoFar <= m_top; i++) {
         value := m_history[i + removedSoFar];

         // while this matches the deleted path, we look for one that doesn't and continue to shift
         while (pos(path, value.Caption) == 1 && i + removedSoFar <= m_top) {
            removedSoFar++;
            if (i + removedSoFar <= m_top) {
               value = m_history[i + removedSoFar];
            }
         }
         // save this value
         if (pos(path, value.Caption) != 1) {
            m_history[i] = value;
         }
      }

      // adjust our top and current indices
      diff := m_top - (i - 1);
      m_top -= diff;
      m_current -= diff;
   }

   /**
    * Clears the navigation history.
    * 
    */
   public void clearHistory()
   {
      m_history._makeempty();
      m_current = m_top = -1;
   }

   /**
    * "Goes to" a specific node by saving it in the navigation
    * history.
    * 
    * @param location new node's location (index)
    * @param caption  new node's caption path
    */
   public void goTo(int location, _str caption)
   {
      // see if this location was the last one sent - do nothing
      if (!m_history._isempty() && 
          m_history[m_current] != null && 
          m_history[m_current].Caption == caption && 
          m_history[m_current].Index == location) return;


      // see if this location is already stored - we move it up to our position
      found := false;
      int i;
      for (i = 0; i <= m_current && !found; i++) {
         if (m_history[i].Index == location) {
            found = true;
            break;
         }
      }

      // we found it...
      if (found) {
         // remove the old entry
         for (; i < m_current; i++) {
            m_history[i] = m_history[i + 1];
         }
      } else {
         // increment the current index
         m_current++;
      }

      // set the top to be our current index
      m_top = m_current;

      // add our new location
      HistoryNode hn;
      hn.Caption = caption;
      hn.Index = location;
      m_history[m_current] = hn;
   }

   /**
    * Goes back to a previously visited node.  This function can
    * either go back one location, or can go back to a specified
    * caption.  Returns the HistoryNode associated with our new
    * location.
    * 
    * @param caption    optional caption path of where we want to go.
    *                   If not specified, go back one location
    * 
    * @return           HistoryNode of our new place
    */
   public HistoryNode goBack(_str caption = '')
   {
      // go back one
      if (caption == '') {
         // decrement our current index
         if (m_current > 0) {
            m_current--;
         }
      } else {

         // go back to wherever this caption was specified
         int i;
         for (i = 0; i < m_current; i++) {
            if (m_history[i].Caption == caption) {
               m_current = i;
               break;
            }
         }
      }

      // return the value at our new current index
      return m_history[m_current];
   }

   /**
    * Builds a 'menu' or list of the nodes that are 'behind' us in
    * the navigation history.
    * 
    * @return        array of captions
    */
   public STRARRAY buildBackMenu()
   {
      _str a[];

      int i;
      for (i = m_current - 1; i >= 0; i--) {
         a[a._length()] = m_history[i].Caption;
      }

      return a;
   }

   /**
    * Builds a 'menu' or list of the nodes that are 'in front of' 
    * us in the navigation history. 
    * 
    * @return        array of captions
    */
   public STRARRAY buildForwardMenu()
   {
      _str a[];

      int i;
      for (i = m_current + 1; i <= m_top; i++) {
         a[a._length()] = m_history[i].Caption;
      }

      return a;
   }

   /**
    * Goes forward in the navigation history.  To go forward, you 
    * must go back first. This function can either go forward one 
    * location, or can go forward to a specified caption. Returns 
    * the HistoryNode associated with our new location. 
    * 
    * @param caption    optional caption path of where we want to go.
    *                   If not specified, go forward one location
    * 
    * @return           HistoryNode of our new place
    */
   public HistoryNode goForward(_str caption = '')
   {
      // no caption - go forward once
      if (caption == '') {
         // increment our current index
         if (m_current < m_top) {
            m_current++;
         }
      } else {
         // find the caption that we're referring to between the current and top
         if (m_current < m_top) {
            int i;
            for (i = m_current; i <= m_top; i++) {
               if (m_history[i].Caption == caption) {
                  m_current = i;
                  break;
               }
            }
         }
      }

      // return the value at our current index
      return m_history[m_current];
   }

   /**
    * Determines whether we can go back in the history or whether
    * we are already at the beginning.
    * 
    * @return        true if we can go back, false if we are 
    *                already at the beginning
    */
   public boolean canGoBack()
   {
      // are we at the very beginning?
      return (m_current > 0);
   }

   /**
    * Determines whether we can go forward in the history or 
    * whether we are already at the end. 
    * 
    * @return        true if we can go forward, false if we are 
    *                already at the end
    */
   public boolean canGoForward()
   {
      // are we at the end?
      return (m_current < m_top);
   }
};
