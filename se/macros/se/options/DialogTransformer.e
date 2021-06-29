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
#require "OptionsPanelInfo.e"
#endregion Imports

namespace se.options;

/**
 * How to Add a Dialog to the Options Dialog 
 *  
 * 1.  Create callbacks for the dialog.  See the comment above the FormFunctions
 * struct for more info.  Can also examine callbacks written for other options 
 * forms. 
 *  
 * 2.  Make sure the dialog has an on_resize event if it needs one.  Dialogs 
 * will be resized as the options dialog is resized, and you don't want your 
 * dialog to look silly when this happens.  Whatever the default size of your 
 * dialog will be the minimum size when embedded in the options.  If you want to
 * specify a different minimum size, this can be done in the options.xml. 
 *  
 * 3.  Create an XML node in the options.xml file for your dialog.  See another 
 * Dialog element for guidance.  Special attributes: 
 * SystemHelp - the p_help entry for this options node (ask the doc expert) 
 * DialogHelp - help blurb to be displayed on the bottom of the options dialog 
 * when this dialog is displayed. 
 * Tags - a list of the search terms that should lead to this dialog.  Usually 
 * taken from labels and whatnot on the form. 
 *  
 */

/**
 * This class is used to embed an existing, freestanding dialog
 * in the options dialog.
 * 
 */
class DialogTransformer : OptionsPanelInfo
{
   private _str m_form;                      // name of the form
   protected int m_wid = 0;                    // wid of the form
   private int m_xmlIndex;                   // index in the XML DOM of this form
   protected _str m_langID = '';               // language associated with this dialog (may be blank)
   protected _str m_inheritsFromForm = '';     // form from which this form inherits callbacks (may be blank)
   protected _str m_vcProviderID = '';

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
   DialogTransformer(_str caption = '', _str panelHelp = '', _str systemHelp = '', 
                     _str form = '', int index = 0, _str inheritsFromForm = '') 
   {
      OptionsPanelInfo(caption, panelHelp, systemHelp);

      m_form = form;
      m_xmlIndex = index;
      m_inheritsFromForm = inheritsFromForm;

      if (m_form != '') {
         findFormFunctions();
      }

   }

   /**
    * Sets the indices from the names table of our callback
    * functions.  Functions which are not found are set at 0.
    * 
    */
   private void findFormFunctions()
   {
   }

   /**
    * Searches for a callback method using the form's name and possibly the 
    * inheritsFromForm's name.   
    *  
    * @param callback      the string used to determine a callback
    * 
    * @return              index of callback in names table
    */
   protected int findFormCallback(_str callback)
   {
      index := find_index(m_form :+ callback, PROC_TYPE);
      if (index <= 0 && m_inheritsFromForm != '') {
         // this might have a list of forms inside
         _str ancestors[];
         split(m_inheritsFromForm, ',', ancestors);

         // try each one until we find it...or we run out
         foreach (auto formName in ancestors) {
            index = find_index(formName :+ callback, PROC_TYPE);
            if (index > 0) break;
         }
      }

      return index;
   }

   /**
    * Calls a callback function for this dialog.  Optionally sends
    * an argument.
    * 
    * @param index         Index in names table of function to call
    * @param thingToSend   optional argument to send to function
    * 
    * @return              return value of the function called,
    *                      false if no function could be called
    */
   protected typeless callFunction(int index, 
                                   typeless &thingToSend1 = -1, 
                                   typeless &thingToSend2 = -1, 
                                   typeless &thingToSend3 = -1)
   {
      if (index > 0) {
         oldWid := p_window_id;
         if (m_wid) {
            p_window_id = m_wid;
         }

         typeless result;
         if (thingToSend1 == -1) {
            result = call_index(index);
         } else if (thingToSend2 == -1) {
            result = call_index(thingToSend1, index);
         } else if (thingToSend3 == -1) {
            result = call_index(thingToSend1, thingToSend2, index);
         } else {
            result = call_index(thingToSend1, thingToSend2, thingToSend3, index);
         }

         p_window_id = oldWid;
         return result;
      }
      return false;
   }
   
   /**
    * Sets the form name for this dialog transformer and possibly the form the 
    * current form inherits from as well
    * 
    * @param value         new form name 
    * @param parentForm    form from which this form inherits callbacks 
    */
   public void setFormName(_str form, _str parentForm = "")
   {
      m_form = form;
      m_inheritsFromForm = parentForm;
      if (m_form != "") {
         findFormFunctions();
      }
   }

   public _str getFormName()
   {
      return m_form;
   }

   /**
    * Returns the form's XML DOM index
    * 
    * @return     index
    */
   public int getIndex()
   {
      return m_xmlIndex;
   }

   /**
    * Sets the XML DOM index for this dialog transformer
    * 
    * @param value      index
    */
   public void setIndex(int value)
   {
      m_xmlIndex = value;
   }

   /**
    * Gets the language for this dialog transformer.  Only applies to 
    * language-specific forms. 
    * 
    * @param value      language (mode name)
    */
   public _str getLanguage()
   {
      return m_langID;
   }

   /**
    * Sets the language for this dialog transformer.  Only applies 
    * to language-specific forms. 
    * 
    * @param value      language (mode name)
    */
   public void setLanguage(_str lang)
   {
      m_langID = lang;
   }

   /**
    * Sets the version control provider for this dialog 
    * transformer. Only applies to version control forms. 
    * 
    * @param value      language (mode name)
    */
   public void setVersionControlProvider(_str vcProv)
   {
      m_vcProviderID = vcProv;
   }

   public int getWindowId()
   {
      return m_wid;
   }
};
