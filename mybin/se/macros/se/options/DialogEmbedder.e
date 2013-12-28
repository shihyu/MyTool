////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47142 $
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
#import "listbox.e"
#require "DialogTransformer.e"
#endregion Imports

#define DEFAULT_DIALOG_HEIGHT 5500         // default height of a dialog
#define DEFAULT_DIALOG_WIDTH 7000          // default width of a dialog
#define DEFAULT_DIALOG_BORDER 120          // default space between border of form and controls

namespace se.options;

/** 
 * FormFunctions Struct 
 *  
 * Keeps track of the callbacks used to embed a dialog within the options 
 * dialog. Callbacks have a uniform name structure, starting with the 
 * _form_name_. 
 * 
 * None of these callbacks are *required* by the DialogTransformer; if one is 
 * not there, we move merrily on our way.  If both IsModified and SaveFunction 
 * are not there, then the Dialog Transformer will implement its own (see 
 * compileCurrentSettings and compareCurrentSettings). 
 *  
 * If a callback cannot be found for the form and an inheritsFromForm is 
 * specified for this dialog, then we will search for a callback for the parent 
 * form. 
 */
struct FormFunctions {
   int ApplyFunction;            // apply the settings on this dialog
   int CancelFunction;           // cancel any changes made on this dialog
   int Initialize;               // initialize this dialog for use in the options
   int IsModifiedFunction;       // determine whether any changes have been made
   int SaveFunction;             // set a baseline for this dialog so that we determine what changes have been made later
   int RestoreState;             // restore the state of a dialog after it has been hidden
   int SaveState;                // save the state of a dialog before it is hidden
   int Validate;                 // validate changes made to a form
};

struct Control {
   _str Caption;
   _str DialogControl;
   boolean Modified;
   boolean Protected;
   int Index;
   boolean PreserveSpaces;
};

/**
 * This class is used to embed an existing, freestanding dialog
 * in the options dialog.
 * 
 */
class DialogEmbedder : DialogTransformer
{
   private int m_width = 0;                  // base width of this form (may be resized to bigger)
   private int m_height = 0;                 // base height of this form (may be resized to bigger)
   private _str m_options:[];                // saved options for checking for modifications
   private FormFunctions m_functions;        // callback functions for this dialog
   private _str m_state = '';                // state saved and restored in SaveState and RestoreState functions
   private Control m_controls:[];

   /**
    * DialogTransformer Constructor.  Initializes callback
    * functions based on the form name.
    * 
    * @param caption    caption associated with this dialog in the options tree
    * @param panelHelp  help info to be displayed when the form is displayed
    * @param systemHelp p_help entry for this dialog in the help system
    * @param form       the form name of this form
    * @param index      index in the XML DOM for the options
    * 
    */
   DialogEmbedder(_str caption = '', _str panelHelp = '', _str systemHelp = '', 
                     _str form = '', int index = 0, _str inheritsFromForm = '') 
   {
      DialogTransformer(caption, panelHelp, systemHelp, form, index, inheritsFromForm);

      m_width = 0;
      m_height = 0;

      m_options._makeempty();
      m_controls._makeempty();
   }

   public void addControl(Control c)
   {
//    if (m_controls._indexin(c.DialogControl)) {
//       _message_box(c.DialogControl' WAS ALREADY ADDED AND NOW IT IS HAPPENING AGAIN!!!!');       
//    } 
      m_controls:[c.DialogControl] = c;
   }

   /**
    * This function is used to make all dialogs in the options look
    * uniform by ensuring they all have the same amount of space
    * between the form edge and the topmost and leftmost controls. 
    *  
    * This function also calculates the width and height needed for 
    * this form based on the visible controls.  To override the 
    * values found by this function, use the width and height 
    * attributes in the options.xml file. 
    */
   private void shiftControls()
   {
      // find the leftmost control and the topmost control
      leftmost := m_wid.p_width;
      topmost := m_wid.p_height;
      wid := firstWid := m_wid.p_child;
      for(;;) {

         if (wid.p_visible) {
            if (wid.p_x < leftmost) {
               leftmost = wid.p_x;
            }
            if (wid.p_y < topmost) {
               topmost = wid.p_y;
            }
         }

         wid = wid.p_next;
         if (wid == firstWid) break;
      }

      // we now have the leftmost and topmost position - we want everything to have the default border
      xShift := DEFAULT_DIALOG_BORDER - leftmost;
      yShift := DEFAULT_DIALOG_BORDER - topmost;

      // go through the controls again and shift them - also determine the rightmost and bottommost
      // so we can determine the size of this form
      rightmost := 0;
      bottommost := 0;
      wid = firstWid = m_wid.p_child;
      for(;;) {

         if (wid.p_visible) {
            wid.p_x += xShift;
            wid.p_y += yShift;

            if (wid.p_x + wid.p_width > rightmost) {
               rightmost = wid.p_x + wid.p_width;
            }
            if (wid.p_y + wid.p_height > bottommost) {
               bottommost = wid.p_y + wid.p_height;
            }

            // 11426 - Refresh list always combo boxes.  Sometimes their scroll bars 
            // do not appear right away
            if (wid.p_object == OI_COMBO_BOX && wid.p_style == PSCBO_LIST_ALWAYS) {
               wid.refresh();
            }

         } 

         wid = wid.p_next;
         if (wid == firstWid) break;
      }

      // now make the change in the width and height of the dialog
      if (m_width == 0) {
         m_width = rightmost + DEFAULT_DIALOG_BORDER;
         m_height = bottommost + DEFAULT_DIALOG_BORDER;
      } else {
         m_width += xShift;
         m_height += yShift;
      }
   }

   /**
    * Sets the indices from the names table of our callback
    * functions.  Functions which are not found are set at 0.
    * 
    */
   private void findFormFunctions()
   {
      m_functions.ApplyFunction = findFormCallback('_apply');
      m_functions.CancelFunction = findFormCallback('_cancel');
      m_functions.SaveFunction = findFormCallback('_save_settings');
      m_functions.IsModifiedFunction = findFormCallback('_is_modified');
      m_functions.Initialize = findFormCallback('_init_for_options');
      m_functions.RestoreState = findFormCallback('_restore_state');
      m_functions.SaveState = findFormCallback('_save_state');
      m_functions.Validate = findFormCallback('_validate');
   }

   /**
    * Saves the current state of the dialog before it is hidden.
    *  
    */
   public void saveState()
   {
      callFunction(m_functions.SaveState, m_state);
   }

   /**
    * Restores the state of the dialog as it is about to be shown
    * again.  This method can take an argument to send to the
    * _form_name_restore_state function.
    * 
    * @param args   argument to send to restore state callback
    */
   public void restoreState(_str args = '')
   {
      if (args != '') {
         m_state = args;
      }
      if (m_state == '') {
         m_state = m_langID;
      } 

      callFunction(m_functions.RestoreState, m_state);
   }

   /**
    * Saves the current values of the settings on this form.  If a
    * form has its own save function, then that function is called.
    * If the form has no save function and has no is_modified
    * function, then the default compileCurrentSettings function is
    * called.
    * 
    */
   public void save()
   {
      resetControls();
      if (m_functions.SaveFunction > 0) {             // we have a save function, call it
         callFunction(m_functions.SaveFunction, m_options);
      } else if (m_functions.IsModifiedFunction <= 0) {        // call the default
         compileCurrentSettings(m_wid.p_child, m_options);
      }
   }

   /**
    * Applies the current settings on the dialog to be set. 
    * 
    */
   public boolean apply()
   {
      status := callFunction(m_functions.ApplyFunction);
      if (status) save();

      return status;
   }
   
   /**
    * Cancels any changes that have been made to this dialog.
    * 
    */
   public void cancel()
   {
      callFunction(m_functions.CancelFunction);
   }

   /**
    * Determines whether the settings on the form have been
    * modified by calling the modified callback for the form or the
    * default compareCurrentSettings function.
    * 
    * @return whether this form has been modified
    */
   public boolean isModified()
   {
      if (m_functions.IsModifiedFunction) {
         return callFunction(m_functions.IsModifiedFunction, m_options);
      } else {
         return compareCurrentSettings(m_wid.p_child);
      }
   }

   /**
    * Initializes a form to be displayed inside the options dialog.
    * For the most part, this consists of hiding OK, Cancel, and
    * Help buttons already in the form.
    * 
    * @param options             any command line arguments that need
    *                            to be sent to the dialog during initialization
    */
   public void initialize(_str options = '')
   {
      // arguments for a language dialog are always the language
      if (m_langID != '') {
         options = strip(m_langID' 'options);
      } else if (m_vcProviderID != '') {
         options = strip(m_vcProviderID' 'options);
      }

      // call the initialization function
      if (options != '') {
         callFunction(m_functions.Initialize, options);
      } else {
         callFunction(m_functions.Initialize);
      }

      // shift our controls to be evenly spaced and pretty
      shiftControls();
      save();

      tempCheckControls();
      protectControls();
   }

   /**
    * Validates the settings on a form by calling its validate
    * callback.  Sends along the current options action, so the
    * form can decide whether it wants to validate when switching
    * or only when applying.
    * 
    * @param action              current options action
    * 
    * @return                    true if the form validated everything okay and is 
    *                            good to switch away, false otherwise.
    */
   public boolean validate(int action)
   {
      if (m_functions.Validate) {
         return callFunction(m_functions.Validate, action);
      } 

      return true;
   }

   /**
    * Retrieves the name and 'value' of a control.  The name is the
    * p_name property, while the value depends on the type of
    * control.  If the p_name property is blank, the value is not 
    * retrieved. 
    * 
    * @param wid    p_window_id of the control we want
    * @param key    p_name of control
    * @param value  value of control, as determined by its type
    */
   private void getKeyValuePair(int wid, _str &key, _str &value)
   {
      key = '';
      value = '';
      if (wid.p_visible && wid.p_name != '') {

         switch (wid.p_object) {
         // frame may have checkbox - p_value
         case OI_FRAME:
            if (wid.p_checkable) {
               key = wid.p_name :+ '.p_value';
               value = wid.p_value;
            }
            break;
         // checkbox, radio button - p_value
         case OI_CHECK_BOX: 
         case OI_RADIO_BUTTON: 
            key = wid.p_name :+ '.p_value';
            value = wid.p_value;
            break;
         // combo box, text box - p_text
         case OI_COMBO_BOX: 
         case OI_TEXT_BOX: 
            key = wid.p_name :+ '.p_text';
            value = wid.p_text;
            break;
         // listbox - _lbget_text()
         case OI_LIST_BOX: 
            key = wid.p_name :+ '._lbget_text()';
            value = wid._lbget_text();
            break;
         // editor - compile text into a string
         case OI_EDITOR: 
            key = wid.p_name :+ '.p_text';
            _str line="";
            wid.top();
            wid.up();
            // should we set a limit on how many lines we parse?
            while( !wid.down() ) {
               wid.get_line(line);
               value = value ' ' strip(line);
            }
            break;
         case OI_IMAGE:
            key = wid.p_name :+ '.p_backcolor';
            value = wid.p_backcolor;
            break;
         case OI_SWITCH:
            key = wid.p_name :+ '.p_value';
            value = wid.p_value;
            break;
         }
      }
   }

   /**
    * Compiles the current settings for all relevant controls on the form.
    * Relevant controls have p_name properties that are not empty
    * strings and have some other valid property that could be
    * counted as a current value.  Recurses through each control
    * and its children.
    * 
    * @param         firstWid window id of first control to retrieve.
    * @param         settings the hashtable containing settings for all controls
    */
   private void compileCurrentSettings(int firstWid, _str (&settings):[])
   {
      if (!firstWid) return;

      wid := firstWid;
      for(;;) {

         // get and save the pair of the control name and its value
         _str key = '', value = '';
         getKeyValuePair(wid, key, value);
         if (key != '') {
            settings:[key] = value;
         }

         // recurse to examine children
         if (wid.p_child) {
            compileCurrentSettings(wid.p_child, settings);
         }

         // get the next one
         wid = wid.p_next;
         if (wid == firstWid) break;
      }
   }

   /**
    * Checks to see if this form has been modified by going through
    * the controls and checking their current values again their
    * saved ones.
    * 
    * @param         firstWid first control to check
    * 
    * @return        true if any controls were found to have been
    *                changed, false otherwise
    */
   private boolean compareCurrentSettings(int firstWid, boolean setModifiedControls = false)
   {
      if (!firstWid) return true;

      modified := false;
      
      wid := firstWid;
      for(;;) {

         // retrieve current key, value pair
         _str key = '', value = '';
         getKeyValuePair(wid, key, value);

         // compare the value to the saved value for this key
         if (key != '') {
            
            match := false;
            if (doPreserveSpacesForControl(wid)) match = (m_options:[key] :== value);
            else match = (m_options:[key] == value);
            
            if (!match) {
               modified = true;            // they do not match!  return true, meaning modified
               if (!setModifiedControls) break;
               else {
                  // set this control as having been modified
                  setControlModified(wid);
               }
            }
         }

         // check out the children
         if (wid.p_child) {
            if (compareCurrentSettings(wid.p_child, setModifiedControls)) {
               modified = true;
               if (!setModifiedControls) break;
            }
         }

         // go on to the next one
         wid = wid.p_next;
         if (wid == firstWid) break;
      }

      return modified;
   }
   
   private boolean doPreserveSpacesForControl(int wid)
   {
      if (m_controls._indexin(wid.p_name)) {
         return m_controls:[wid.p_name].PreserveSpaces;
      } 
      
      return false;
   }
   
   private void setControlModified(int wid)
   {
      if (m_controls._indexin(wid.p_name)) {
         m_controls:[wid.p_name].Modified = true;
      } 
   }
   
   public void getModifiedControlCaptions(_str (&list)[])
   {
      if (m_functions.IsModifiedFunction <= 0) {
         compareCurrentSettings(m_wid.p_child, true);
      }
      
      Control c;
      foreach (c in m_controls) {
         if (c.Modified) {
            list[list._length()] = c.Caption;
         }
      }
   }

   public void getModifiedControlKeysWithValues(_str (&list):[])
   {
      oldWid := p_window_id;
      if (m_wid) p_window_id = m_wid;

      if (m_functions.IsModifiedFunction <= 0) {
         compareCurrentSettings(m_wid.p_child, true);
      }
      
      Control c;
      foreach (c in m_controls) {
         if (c.Modified) {
            _str key = '', value = '';
            cWid := _find_control(c.DialogControl);
            if (cWid > 0) {
               getKeyValuePair(cWid, key, value);
               if (key != '') list:[key] = value;
            }
         }
      }

      p_window_id = oldWid;
   }
   
   public boolean canControlsBeListed()
   {
      // for this to be true, we have to have a list of controls AND we 
      // have to use the default isModified function
      return (m_functions.IsModifiedFunction == 0 && !m_controls._isempty());
   }
   
   private void resetControls()
   {
      typeless i;
      for (i._makeempty();;) {
         m_controls._nextel(i);
         if (i._isempty()) break;

         m_controls:[i].Modified = false;
      }
   }
      
   /**
    * Sets the window id for this dialog transformer
    * 
    * @param value      window id
    */
   public void setWID(int value)
   {
      m_wid = value;
   }

   private void tempCheckControls()
   {
      typeless i;
      for (i._makeempty();;) {
         m_controls._nextel(i);
         if (i._isempty()) break;

         if (!m_wid._find_control(i)) {
            _message_box('I CANNOT FIND 'i', AND IT IS UPSETTING TO ME.');
         }
      }
   }
   
   /**
    * Sets the dimensions for this form
    * 
    * @param height height of form
    * @param width  width of form
    */
   public void setDimensions(int height, int width)
   {
      m_width = width;
      m_height = height;
   }

   /**
    * Returns the form's base width
    * 
    * @return     width
    */
   public int getWidth()
   {
      return m_width;
   }

   /**
    * Returns the form's base height
    * 
    * @return     height
    */
   public int getHeight()
   {
      return m_height;
   }

   /**
    * Returns the type of panel for this object.
    * 
    * @return        the OPTIONS_PANEL_TYPE of this object
    */
   public int getPanelType()
   {
      return OPT_DIALOG_EMBEDDER;
   }

   private void protectControls()
   {
      Control c;
      foreach (c in m_controls) {
         if (c.Protected) {
            wid := m_wid._find_control(c.DialogControl);
            if (wid > 0) {
//             wid.p_backcolor = 0xD8D8D8;
               wid.p_enabled = false;
               wid.p_font_bold = true;
            } 
         }
      }
   }
   
};
