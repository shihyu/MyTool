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
#import "adaptiveformatting.e"
#import "beautifier.e"
#import "ispflc.e"
#import "main.e"
#import "listbox.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "taggui.e"
#import "stdcmds.e"
#require "se/options/AllLanguagesTable.e"
#require "se/lang/api/LanguageSettings.e"
#endregion Imports

// use these values to tell the user that the languages have different values
static const LANGS_DONT_MATCH_TB='';
static const LANGS_DONT_MATCH_CB='Languages Differ';

static const RADIO_SET_KEY='RadioSet';
static const NEUTRAL_RADIO_SET='NeutralRadioSet';

using se.options.AllLanguagesTable;
using se.lang.api.LanguageSettings;
using se.options.PropertyGetterSetter;
using se.options.SettingInfo;

AllLanguagesTable all_langs_mgr;

struct AllLanguagesSetting {
   _str Value;
   _str Exclusions;
};

defload()
{
   AllLanguagesTable alt;
   all_langs_mgr = alt;
}

/**
 * Retrieves the form name for a language form.  Need a unified form name so 
 * that each form can be tied to the all languages form with the same options. 
 * 
 * @return _str         form name, as used by the all langauges table
 */
static _str getLanguageFormName()
{
   formName := p_active_form.p_name;
   if (!pos('_language_', formName)) {
      formName = '_language_formatting_form';
   }

   return formName;
}

/**
 * Retrieves a list of languages which are excluded from this control. In All 
 * Languages, these languages' values are not considered when determining the 
 * current state of the All Languages control.  When an All Language value is 
 * set, these languages are not set. 
 *  
 * This list should have been saved earlier by a call to 
 * setControlExclusions.  If the list has not yet been saved, then null is 
 * returned. 
 * 
 * @param controlName            name of control
 * 
 * @return                       list of languages excluded from this control, 
 *                               comma delimited
 */
static _str getControlExclusions(_str controlName)
{
   return _GetDialogInfoHt(controlName'Exclusions');
}

/**
 * Saves a list of languages which are excluded from this control.  In All 
 * Languages, these languages' values are not considered when determining the 
 * current state of the All Languages control.  When an All Language value is 
 * set, these languages are not set. 
 * 
 * @param controlName            name of control
 * @param exclusions             list of languages excluded from this 
 *                               control, comma delimited
 */
static void setControlExclusions(_str controlName, _str exclusions)
{
   _SetDialogInfoHt(controlName'Exclusions', exclusions);
}

/**
 * A generic method that initializes a language form.  With the use of 
 * callbacks, sets the initial values of the controls on the forms. 
 * This should be called by <_form_name>_init_for_options. 
 * 
 * @param langId                    language id
 * @param pfnGetValue               callback to get the value of a 
 *                                  control
 * @param pfnIsControlIncluded      callback to determine if a 
 *                                  language is included for a control
 */
void _language_form_init_for_options(_str langId, typeless pfnGetValue, typeless pfnIsLangIncluded)
{
   // save our primary extension and language name
   _set_language_form_mode_name(_LangGetModeName(langId));
   _set_language_form_lang_id(langId);

   firstChild := p_active_form.p_child;
   formName := getLanguageFormName();

   // create an empty settings table and save it for later
   _create_language_form_settings();

   // disable any controls which do not apply to this language
   if (langId != ALL_LANGUAGES_ID) {
      _language_form_disable_controls(firstChild, langId, pfnIsLangIncluded, true);
   }

   _language_form_set_controls(firstChild, formName, pfnGetValue, pfnIsLangIncluded, langId, true);
}

/**
 * Generic method to disable controls on a language form.  Goes through and 
 * determines if the current language is included in settings for each control. 
 * Disables any controls which are not valid for this language. 
 * 
 * @param firstWid                     window id of first control (function is 
 *                                     called recursively, so this is later
 *                                     called with the first child of any group
 *                                     controls).
 * @param langId                       language id
 * @param pfnIsLangIncluded            callback to determine if a language is 
 *                                     included in a control's setting
 * @param parentEnabled                if the parent control of this group is 
 *                                     enabled
 */
void _language_form_disable_controls(int firstWid, _str langId, typeless pfnIsLangIncluded, bool parentEnabled)
{
   if (!firstWid) return;

   wid := firstWid;
   for(;;) {

      if (wid.p_visible || wid.p_object == OI_SSTAB_CONTAINER) {
         if (!parentEnabled) {
            wid.p_enabled = false;
         } else {
            controlName := wid.p_name;
            if (controlName != '') {
               if (!(*pfnIsLangIncluded)(controlName, langId, false)) {
                  wid.p_enabled = false;
               } 
            }
         }

         // recurse to examine children
         if (wid.p_child) {
            _language_form_disable_controls(wid.p_child, langId, pfnIsLangIncluded, wid.p_enabled);
         }
      }

      // get the next one
      wid = wid.p_next;
      if (wid == firstWid) break;
   }
}

/**
 * Generic method that refreshes a language form.  Goes through and determines 
 * if any control values need to be recalculated based on any changes to the 
 * other languages.  This should be called by <_form_name>_restore_state. 
 * 
 * @param pfnGetValue                  callback to get the value of a control
 * @param pfnIsControlIncluded         callback to determine if a language is 
 */
void _language_form_restore_state(typeless pfnGetValue, typeless pfnIsControlIncluded)
{
   // retrieve information from the form
   firstChild := p_active_form.p_child;
   formName := getLanguageFormName();
   langId := _get_language_form_lang_id();

   _language_form_set_controls(firstChild, formName, pfnGetValue, pfnIsControlIncluded, langId, false);
}

/**
 * Goes through all the controls on a form and sets them.  This method is called 
 * in two scenarios:  once, when the form is first initialized (set setAll to 
 * true), and then all controls are set.  second, when the form is shown again 
 * after having been hidden.  Some controls will need to be refreshed to account 
 * for changes that may have occurred on other language forms. 
 * 
 * @param firstWid                  window id of first control
 * @param pfnCallback               callback to get the value of the control
 * @param langId                    language id
 * @param setAll                    whether to set all controls
 */
void _language_form_set_controls(int firstWid, _str formName, typeless pfnGetValue, 
                                 typeless pfnIsLangIncluded, _str langId, bool setAll)
{
   if (!firstWid) return;

   // save our first control so we know when we have looped back around
   wid := firstWid;

   // check our parent for exclusions that might apply to us
   parentExclusions := '';
   if (setAll && langId == ALL_LANGUAGES_ID) {
      // see if we have already saved some parent exclusions
      parentId := firstWid.p_parent;
      parentExclusions = getControlExclusions(parentId.p_name);
      if (parentExclusions == null) {
         parentExclusions = getControlExclusionsForAllLanguages(parentId.p_name, pfnIsLangIncluded);

         // now save them, please
         setControlExclusions(parentId.p_name, parentExclusions);
      }
   }

   // save this information for any radio buttons that might be in this group
   firstRadio := '';
   radioToSet := '';

   for (;;) {

      if (wid.p_visible || wid.p_object == OI_SSTAB_CONTAINER) {

         controlName := wid.p_name;
         if (canSetControl(wid)) {
            _str value = null;
            key := controlName;
            isRadio := (wid.p_object == OI_RADIO_BUTTON);
            isCombo := (wid.p_object == OI_COMBO_BOX);
            if (isRadio) {
               key = getRadioButtonKey(wid);
            }
      
            // are we setting this for all languages or just one?
            if (langId == ALL_LANGUAGES_ID) {               
               // are we setting them all or only the ones that need it?
               if (setAll || all_langs_mgr.doesAnyLanguageOverrideAllLanguages(formName, key)) {
                  // first, we neutralize the control
                  if (!isCombo) {
                     // we don't neutralize the combo unless the value is neutral - 
                     // we don't want the neutral value to show up in the list otherwise
                     neutralizeAllLanguageControl(wid, (firstRadio == ''));
                  }
      
                  // determine if this control has any exclusions (languages where we don't include their value in ALL LANGUAGES)
                  exclusions := getControlExclusions(controlName);
                  if (exclusions == null) {
                     // get exclusions for this control
                     if (isRadio && firstRadio != '') {
                        // we've already called the callback for this set of radio buttons
                        exclusions = getControlExclusions(firstRadio);
                     } else {
                        // get them from the callback
                        exclusions = getControlExclusionsForAllLanguages(controlName, pfnIsLangIncluded);
                        if (exclusions != '') {
                           exclusions :+= ','parentExclusions;
                        } else if (parentExclusions != '') {
                           exclusions = parentExclusions;
                        }
                     }
   
                     // now save them, please
                     setControlExclusions(controlName, exclusions);
                  }
   
                  // get the control's value - if value is non-null, then all values match and 
                  // we can set it.  otherwise, we leave it as the neutral value
                  if (!isRadio || firstRadio == '') {
                     value = getControlValueForAllLanguages(formName, controlName, pfnGetValue, exclusions);
                  } 
               }
            } else {

               // see if we have an override in place that we must address
               if (all_langs_mgr.doesAllLanguagesOverride(formName, key, langId)) {
                  value = all_langs_mgr.getLanguageValue(formName, key, ALL_LANGUAGES_ID);
               } else if (setAll) {
   
                  // if this is a radio button, it may already be set by one of its brethren
                  if (!isRadio || firstRadio == '') {
                     // we're just setting all the values here
                     value = (*pfnGetValue)(controlName, langId);
                  } 
               } // else we don't really care about this control right now
            }

            // if this is a radio button, then the value returned is the name of the radio button 
            // in this set which has the set value
            if (isRadio) {
               if (firstRadio == '') {
                  firstRadio = controlName;
                  radioToSet = value;
               }

               // now we set the value for each and every radio button
               if (radioToSet == null) {
                  value = null;
               } else {
                  // check to see if this is the radio button we want turned on
                  value = (radioToSet == controlName) ? 1 : 0;
               }
            }

            if (value != null) {
               // set it with our magic
               setControlValue(wid, value);
            } else if (langId == ALL_LANGUAGES_ID && isCombo) {
               // we know this is a combo, and that the lang values differ, so add the neutral value
               neutralizeAllLanguageControl(wid, false);
            }
         }
   
         // recurse to examine children
         if (wid.p_child) {

            if (setAll && langId == ALL_LANGUAGES_ID) {
               // we want to see if this control has exclusions that might apply to its children
               exclusions := getControlExclusionsForAllLanguages(controlName, pfnIsLangIncluded);
               if (exclusions != '') {
                  exclusions :+= ','parentExclusions;
               } else if (parentExclusions != '') {
                  exclusions = parentExclusions;
               }
   
               // now save them, please
               setControlExclusions(controlName, exclusions);
            }

            _language_form_set_controls(wid.p_child, formName, pfnGetValue, pfnIsLangIncluded, langId, setAll);
         }
      } 

      // get the next one
      wid = wid.p_next;
      if (wid == firstWid) break;
   }
}

/**
 * Retrieves a list of languages which are excluded for this control. 
 * Determines this list by calling a callback for each language.
 * 
 * @param controlName               name of relevant control
 * @param pfnIsLangIncluded         callback to determine if a language is 
 *                                  included for this control
 * 
 * @return                          comma-delimited list of langauge ids of the 
 *                                  language for which this control does not
 *                                  apply
 */
static _str getControlExclusionsForAllLanguages(_str controlName, typeless pfnIsLangIncluded)
{
   exclusions := '';

   // go through all the languages
   _GetAllLangIds(auto langs);
   for (i := 0; i < langs._length(); i++) {
      langId := langs[i];

      if ((!_haveBuild() && langId == 'process') || !(*pfnIsLangIncluded)(controlName, langId, true)) {
         exclusions :+= langId',';
      }
   }

   exclusions = strip(exclusions, 'T', ',');

   return exclusions;
}

/**
 * Determines whether all languages have the same value for a specific option. 
 * Uses a callback to get the value of the control for each included language. 
 * If all languages have the same value, then that value is returned. 
 *  
 * This method also checks for any values that might have been updated in the 
 * current session of the options dialog. 
 * 
 * @param formName                  name of the form we are looking at
 * @param controlName               name of the specific control we want the 
 *                                  value for
 * @param pfnGetValue               callback function to get the value for a 
 *                                  control
 * @param exclusions                comma-delimited list of languages which 
 *                                  should not be consulted
 * 
 * @return                          option's value if all languages agree, null 
 *                                  otherwise
 */
_str getControlValueForAllLanguages(_str formName, _str controlName, typeless pfnGetValue, _str exclusions = '')
{
   allLangsValue := all_langs_mgr.getLanguageValue(formName, controlName, ALL_LANGUAGES_ID);
   _str value = null;

   // go through all the languages
   _GetAllLangIds(auto langs);
   for (i := 0; i < langs._length(); i++) {
      langId := langs[i];

      // first determine if we exclude this language
      if (!pos(','langId',', ','exclusions',')) {

         // check if the value has been saved in the all languages table
         langValue := all_langs_mgr.getLanguageValue(formName, controlName, langId);
         if (langValue == null) {
            if (allLangsValue != null) {
               langValue = allLangsValue;
            } else {
               langValue = (*pfnGetValue)(controlName, langId);
            }
         }

         // now that we have our value, we can compare it to all the other values!
         if (value == null) {
            value = langValue;
         } else if (value != langValue) {
            value = null;
            break;
         } 
      } 
   }

   return value;
}

/**
 * Sets a control with the given value.  Saves the set value in the table of 
 * original settings for this form. 
 * 
 * @param wid              window id of control to set
 * @param value            new value to set
 * 
 * @return                 true if the control was successfully set, false 
 *                         otherwise
 */
bool setControlValue(int wid, _str value)
{
   set := false;
   if (wid.p_visible) {
      switch (wid.p_object) {
      // checkbox, radio button - p_value
      case OI_CHECK_BOX: 
         if (wid.p_name=='ctlUseContOnParameters' && wid.p_active_form.p_name=='_clojure_extform') {
            if (isinteger(value)) {
               if (value==2) {
                  value=0;
               }
               wid.p_value = (int)value;
               set = true;
            }
            break;
         }
      case OI_RADIO_BUTTON: 
      case OI_FRAME:
         if (isinteger(value)) {
            wid.p_value = (int)value;
            set = true;
         }
         break;
      // combo box, text box - p_text
      case OI_COMBO_BOX: 
         cb_line_no := wid._lbfind_item(value);
         if (cb_line_no > 0) wid.p_line = cb_line_no;
         wid._lbselect_line();
         wid._cbset_text(value);
         set = true;
         break;
      case OI_TEXT_BOX: 
         wid.p_text = value;
         set = true;
         break;
      // listbox - _lbget_text()
      case OI_LIST_BOX: 
         lb_line_no := wid._lbfind_item(value);
         if (lb_line_no > 0) wid.p_line = lb_line_no;
         wid._lbselect_line();
         set = true;
         break;
      // image - we just want the background color
      case OI_IMAGE:
         if (isinteger(value)) {
            wid.p_backcolor = (int)value;
         }
         break;
      case OI_LABEL:
         if (wid.p_name=='ctlspellwt_elements') {
            wid.p_user=value;
            set=true;
         }
         break;
      case OI_TREE_VIEW:
         if (wid.p_name=='ctlUseContOnParametersTree') {
            wid._TreeDelete(TREE_ROOT_INDEX,'C');
            value=translate(value,'  ',"\r\n");
            for (;;) {
               parse value with auto fun_name auto option value;
               if (value=='') {
                  break;
               }
               index:=wid._TreeAddItem(TREE_ROOT_INDEX,fun_name"\t"option,TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0);
               wid._TreeSetSwitchState(index,1,option==1?true:false);
            }
            wid._TreeSortCol(0,'I');
            set=true;
         }
         break;
      }
   }

   if (set) {
      // get the settings table
      STRHASHPTR settings = _get_language_form_settings();

      // save the value in the settings so we can tell if it changes later
      getKeyValuePair(wid, auto key, value);
      if (key != '') {
         (*settings):[key] = value;
      }

   }

   return set;
}

/**
 * Applies all the modified options on this form.
 * 
 * @param pfnApplyControlCallback            callback to apply each individual 
 *                                           control
 */
void _language_form_apply(typeless pfnApplyControlCallback)
{
   // retrieve information from the form
   firstChild := p_active_form.p_child;
   formName := getLanguageFormName();
   langId := _get_language_form_lang_id();

   AllLanguagesSetting alsTable:[];

   _language_form_apply_controls(firstChild, formName, pfnApplyControlCallback, langId, alsTable);

   // now we see about updating the open buffers with our new stuff
   if (langId == ALL_LANGUAGES_ID) {
      // use a special new method
      _update_buffers_for_all_languages(alsTable);

   } else {
      // make a regular old hash table out of this one
      AllLanguagesSetting als;
      _str updateTable:[];
      foreach (auto key => als in alsTable) {
         updateTable:[key] = als.Value;
      }

      if (updateTable._length() != 0) {
         _update_buffers(langId, updateTable);
      }
   }
}

/**
 * Determines if the given control needs to have its current setting validated. 
 * This only needs to happen when the value has been changed. 
 * 
 * @param wid              window id of control to check
 * 
 * @return                 true if the control needs validation
 */
bool _language_form_control_needs_validation(int wid, _str &value)
{
   formName := getLanguageFormName();
   langId := _get_language_form_lang_id();

   // initialize this to nothingness
   value = null;

   if (wid.p_visible && wid.p_enabled) {

      if (canSetControl(wid)) {
         controlName := wid.p_name;
         key := controlName;
         isRadio := (wid.p_object == OI_RADIO_BUTTON);
         if (isRadio) {
            key = getRadioButtonKey(wid);
         }

         // see if there is a value to set - we only set radio buttons if their value is on
         savedValue := all_langs_mgr.getLanguageValue(formName, key, langId);

         if (savedValue != null) {
            value = savedValue;
         } else {
            getKeyValuePair(wid, key, value);
         }

         return (savedValue != null);
      }
   }

   return false;
}

/**
 * Applies each individual control in this form/group.
 * 
 * @param firstWid                           first child control
 * @param formName                           name of form we're dealing with
 * @param pfnApplyControlCallback            callback to apply control values
 * @param langId                             language id
 * @param alsTable                           table of settings that have been 
 *                                           applied, so that we can update the
 *                                           open buffers.
 */
void _language_form_apply_controls(int firstWid, _str formName, typeless pfnApplyControlCallback, _str langId, AllLanguagesSetting (&alsTable):[])
{
   if (!firstWid) return;

   STRHASHPTR settings = _get_language_form_settings();

   wid := firstWid;
   for(;;) {

      if (wid.p_visible || wid.p_object == OI_SSTAB_CONTAINER) {
   
         if (canSetControl(wid)) {
            controlName := wid.p_name;
            key := controlName;
            isRadio := (wid.p_object == OI_RADIO_BUTTON);
            if (isRadio) {
               key = getRadioButtonKey(wid);
            }
      
            // see if there is a value to set - we only set radio buttons if their value is on
            value := all_langs_mgr.getLanguageValue(formName, key, langId);
            if (isRadio) value = (value == controlName);
            if (value != null && (!isRadio || (int)value)) {
      
               // our language determines our behavior
               if (langId == ALL_LANGUAGES_ID) {
                  exclusions := getControlExclusions(controlName);

                  // this will call the apply callback for each applicable language
                  setControlValueForAllLanguages(controlName, pfnApplyControlCallback, value, alsTable, exclusions);
                  AllLanguagesSetting als;
                  als.Exclusions = exclusions;
               } else {
                  // just call the callback directly, i suppose
                  updateString := (*pfnApplyControlCallback)(controlName, langId, value);
                  parse updateString with auto updateKey auto updateValue;
                  if (updateKey != '') {
                     AllLanguagesSetting als;
                     als.Value = updateValue;
                     als.Exclusions = '';

                     alsTable:[updateKey] = als;
                  }
               }
            }

            // update the key/value pair info...
            getKeyValuePair(wid, auto updateKey, value);
            if (updateKey != '') {
               (*settings):[updateKey] = value;
            }
         }

         // recurse to examine children
         if (wid.p_child) {
            _language_form_apply_controls(wid.p_child, formName, pfnApplyControlCallback, langId, alsTable);
         }
      }

      // get the next one
      wid = wid.p_next;
      if (wid == firstWid) break;
   }
}

/**
 * Sets an option for all languages.
 * 
 * 
 * @param controlName                        name of control we wish to set
 * @param pfnApplyControlCallback            callback that sets options based on 
 *                                           control names
 * @param value                              value we want to set
 * @param alsTable                           table of applied settings (used to 
 *                                           update open buffers of new
 *                                           settings)
 * @param exclusions                         languages to be excluded from this 
 *                                           option being set
 */
void setControlValueForAllLanguages(_str controlName, typeless pfnApplyControlCallback, _str value, 
                                       AllLanguagesSetting (&alsTable):[], _str exclusions = '')
{
   updateString := '';

   result:=(*pfnApplyControlCallback)(controlName, ALL_LANGUAGES_ID, value, true);
   if (updateString == '') {
      updateString = result;
   }
   // go through all the languages
   _GetAllLangIds(auto langs);
   for (i := 0; i < langs._length(); i++) {
      langId := langs[i];

      // first determine if we exclude this language
      if (!pos(','langId',', ','exclusions',')) {

         // set this value for this language using the callback
         result = (*pfnApplyControlCallback)(controlName, langId, value, true);
         if (updateString == '') {
            updateString = result;
         }
      } 
   }

   // we might need to update our buffers with this information - parse it out
   parse updateString with auto updateKey auto updateValue;
   if (updateKey != '') {
      AllLanguagesSetting als;
      als.Value = updateValue;
      als.Exclusions = exclusions;

      alsTable:[updateKey] = als;
   }
}

void _language_form_save_state()
{
   // retrieve the language
   langId := _get_language_form_lang_id();
   formName := getLanguageFormName();

   // get our original settings
   STRHASHPTR origSettings = _get_language_form_settings();
   if (origSettings == null) return;

   // now get our current settings
   _str curSettings:[];
   compileCurrentSettings(p_active_form.p_child, curSettings, false);

   // check for differences
   foreach (auto controlName => auto origValue in (*origSettings)) {
      curValue := null;
      if (curSettings._indexin(controlName)) {
         curValue = curSettings:[controlName];
      }

      if (curValue != null && origValue :!= curValue) {
         // save our difference in the all langs table
         all_langs_mgr.setLanguageValue(formName, controlName, langId, curValue);
      } else {

         // so we changed this value before, but now we are back to our original value
         // OR the setting is disabled, so we don't want to count this as modified
         doBacktrack := true;
         if (langId == ALL_LANGUAGES_ID) {

            // if the current value is null, then we definitely backtrack, 
            // because the control is no longer of interest
            if (curValue != null) {
                // see if we have previously saved a modified value for this control
                value := all_langs_mgr.getLanguageValue(formName, controlName, langId);
    
                // if original value was neutral, do not backtrack
                if (value != null) {
                   if (isRadioButtonKey(controlName)) {
                      doBacktrack = (curValue != NEUTRAL_RADIO_SET);
                   } else {
                      controlWid := p_active_form._find_control(controlName);
                      doBacktrack = (controlWid > 0 && (!controlWid.p_enabled || !isControlNeutralized(controlWid)));
                   }
                } else {
                   // we have nothing to backtrack, so let's not bother
                   doBacktrack = false;
                }
            }
         }

         if (doBacktrack) {
            // it's not a neutral value, so we can backtrack on it
            all_langs_mgr.removeLanguageValue(formName, controlName, langId);
         }
      }
   }

}

/**
 * Determines if the current language form has been modified from its original 
 * configuration.  Later, we will use these results to determine which specific 
 * options need to be set. 
 * 
 * @return                 true if any of the options have been modified, false 
 *                         otherwise
 */
bool _language_form_is_modified()
{
   // retrieve the language
   langId := _get_language_form_lang_id();
   formName := getLanguageFormName();

   return all_langs_mgr.isLangFormModified(formName, langId);
}

/**
 * Once a language form is no longer being used, we must purge the data we saved 
 * while it was open. 
 */
void _language_form_on_destroy()
{
   // retrieve the language and form
   langID := _get_language_form_lang_id();
   if (langID != null) {
      formName := getLanguageFormName();

      all_langs_mgr.removeFormListings(formName, langID);
   }
}

/**
 * Determines if the given control can be set with an option value.
 * 
 * @param wid              window id of control in question
 *    
 * @return                 true if control can be set, false otherwise
 */
bool canSetControl(int wid)
{
   // we don't bother setting any controls that don't have names
   if (wid.p_name == '') return false;

   canSet := false;

   switch (wid.p_object) {
   // checkbox, radio button - p_value
   case OI_CHECK_BOX: 
   case OI_RADIO_BUTTON: 
   case OI_COMBO_BOX: 
   case OI_TEXT_BOX: 
   case OI_LIST_BOX: 
   case OI_IMAGE:
      canSet = true;
      break;
   case OI_FRAME:
      // we can only set frames which have checkboxes
      canSet = wid.p_checkable;
      break;
   case OI_LABEL:
      if (wid.p_name=='ctlspellwt_elements') {
         canSet = true;
      }
      break;
   case OI_TREE_VIEW:
      if (wid.p_name=='ctlUseContOnParametersTree') {
         canSet = true;
      }
      break;
   }

   return canSet;
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
void compileCurrentSettings(int firstWid, _str (&settings):[], bool includeDisabled)
{
   if (!firstWid) return;

   foundRadio := false;
   wid := firstWid;
   for(;;) {

      if (wid.p_visible && (wid.p_enabled || includeDisabled)) {
         // this is a bit goofy - we set radio buttons together, as a set
         if (wid.p_object == OI_RADIO_BUTTON && !foundRadio) {
            // we know that there are radio buttons in this group, so mark the key as blank
            // the value will become the name of the radio button with p_value = 1
            // if none of them have p_value = 1, then we will know that by the neutral key
            foundRadio = true;
            key := getRadioButtonKey(wid);
            settings:[key] = NEUTRAL_RADIO_SET;   
         }
   
         // get and save the pair of the control name and its value
         key := value := "";
         getKeyValuePair(wid, key, value);
         if (key != '') {
            settings:[key] = value;
         }
      }

      // recurse to examine children
      if (wid.p_child) {
         compileCurrentSettings(wid.p_child, settings, includeDisabled);
      }

      // get the next one
      wid = wid.p_next;
      if (wid == firstWid) break;
   }
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
void getKeyValuePair(int wid, _str &key, _str &value)
{
   key = '';
   value = '';
   if (wid.p_visible && wid.p_name != '') {
      key = wid.p_name;

      switch (wid.p_object) {
      // checkbox, radio button - p_value
      case OI_CHECK_BOX: 
         if (wid.p_name=='ctlUseContOnParameters' && wid.p_active_form.p_name=='_clojure_extform') {
            value = wid.p_value;
            if (value==0) {
               value=2;
            }
            break;
         }
         value = wid.p_value;
         break;
      case OI_RADIO_BUTTON: 
         // we only mark the radio button that has p_value = 1
         if (wid.p_value) {
            // radio buttons key off the name of the parent and an added string
            key = getRadioButtonKey(wid);
            // the value is the name of the radio button with p_value = 1
            value = wid.p_name;
         } else key = '';
         break;
      // combo box, text box - p_text
      case OI_COMBO_BOX: 
      case OI_TEXT_BOX: 
         value = wid.p_text;
         break;
      // listbox - _lbget_text()
      case OI_LIST_BOX: 
         value = wid._lbget_text();
         break;
      // editor - compile text into a string
      case OI_EDITOR: 
         line := "";
         wid.top();
         wid.up();
         // should we set a limit on how many lines we parse?
         while( !wid.down() ) {
            wid.get_line(line);
            value :+= ' ' strip(line);
         }
         break;
      case OI_IMAGE:
         value = wid.p_backcolor;
         break;
      case OI_FRAME:
         // we only can get/set if p_checkable is true
         if (wid.p_checkable) {
            value = wid.p_value;
         } else key = value = '';
         break;
      case OI_LABEL:
         if (wid.p_name=='ctlspellwt_elements') {
            value=wid.p_user;
         }
         break;
      case OI_TREE_VIEW:
         if (wid.p_name=='ctlUseContOnParametersTree') {
            value='';
            index:=wid._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            while (index>=0) {
               fun_name:=wid._TreeGetCaption(index,0);
               option:=wid._TreeGetSwitchState(index,1);
               if (fun_name!='' && isinteger(option)) {
                  if (value) {
                     value:+="\n";
                  }
                  if (option==0) option=2;  // Auto
                  value:+=fun_name' 'option;
               }
               index=wid._TreeGetNextSiblingIndex(index);
            }
         }
         break;
      default:
         key = value = '';
         break;
      }
   }
}

/**
 * Retrieves the key used to access a radio button set in the all languages 
 * manager. 
 * 
 * @param wid              window id of a radio button in the set
 * 
 * @return                 radio button set key
 */
static _str getRadioButtonKey(int wid)
{
   return wid.p_parent.p_name :+ RADIO_SET_KEY;
}

/**
 * Determines if the given key is a radio button set key.
 * 
 * @param key              string to check
 * 
 * @return                 true if the string is a radio button set key, false 
 *                         otherwise
 */
static bool isRadioButtonKey(_str key)
{
   return endsWith(key, RADIO_SET_KEY);
}

/**
 * Gives the control a "neutral" value.  When we load All Languages, we check to 
 * see if all the languages have the same value for each option.  When the 
 * languages have different values, we set the control as "neutral" so that the 
 * user knows that all languages do not agree. 
 * 
 * @param wid                    window id of control to set
 */
void neutralizeAllLanguageControl(int wid, bool saveRadioSetting)
{
   if (wid.p_visible && wid.p_name != '') {
      set := false;
      switch (wid.p_object) {
      // checkbox, radio button - p_value
      case OI_CHECK_BOX: 
         // make sure it is tri-state and set it to the third state
         wid.p_style = PSCH_AUTO3STATEA;
         wid.p_value = 2;
         wid.p_style = PSCH_AUTO2STATE;
         set = true;
         break;
      case OI_FRAME:
         if (wid.p_checkable) {
            // make sure it is tri-state and set it to the third state
            wid.p_style = PSCH_AUTO3STATEA;
            wid.p_value = 2;
            wid.p_style = PSCH_AUTO2STATE;
            set = true;
         }
         break;
      case OI_RADIO_BUTTON:
         // just set the value to 0
         wid.p_value = 0; 
         set = true;
         break;
      // combo box, text box - p_text
      case OI_COMBO_BOX: 
         // set it to the languages not matching
         wid._lbadd_item_no_dupe(LANGS_DONT_MATCH_CB, '', LBADD_TOP, true);
         set = true;
         break;
      case OI_TEXT_BOX: 
         // set it to the languages not matching
         wid.p_text = LANGS_DONT_MATCH_TB;
         set = true;
         break;
      case OI_IMAGE:
         wid.p_backcolor = 0x80000005;
         break;
      case OI_LIST_BOX: 
         break;
      case OI_EDITOR: 
         break;
      }

      if (set) {
         // get the settings table
         STRHASHPTR settings = _get_language_form_settings();

         // save the value in the settings so we can tell if it changes later
         key := value := "";
         if (wid.p_object == OI_RADIO_BUTTON) {
            if (saveRadioSetting) {
               key = getRadioButtonKey(wid);
            }
            value = NEUTRAL_RADIO_SET;
         } else {
            getKeyValuePair(wid, key, value);
         }

         if (key != '') {
            (*settings):[key] = value;
         }
      }
   }
}

/**
 * Determines if the given control is "neutralized," meaning it has a neutral 
 * All Languages value (indicating that languages have different values). 
 * 
 * @param wid              window id of control to check
 * 
 * @return                 true if control is neutralized, false otherwise
 */
bool isControlNeutralized(int wid)
{
   neutral := false;

   if (wid.p_visible && wid.p_name != '') {
      switch (wid.p_object) {
      // checkbox, radio button - p_value
      case OI_CHECK_BOX: 
         neutral = (wid.p_value == 2);
         break;
      case OI_RADIO_BUTTON:
         // this is tricky - we need to check all the radio buttons in the group to make sure they are all set to 0
         if (wid.p_value == 0) {
            nextWid := getNextRadioButton(wid);
            while (nextWid != wid && nextWid.p_value == 0) {
               nextWid = getNextRadioButton(nextWid);
            }

            neutral = (nextWid == wid);
         }
         break;
      // combo box, text box - p_text
      case OI_COMBO_BOX: 
         // set it to the languages not matching
         neutral = (wid.p_text == LANGS_DONT_MATCH_CB);
         break;
      case OI_TEXT_BOX: 
         // set it to the languages not matching
         neutral = (wid.p_text == LANGS_DONT_MATCH_TB);
         break;
      case OI_IMAGE:
         neutral = (wid.p_backcolor == 0x80000005);
         break;
      }
   }

   return neutral;
}

/**
 * Retrieves the next radio button in this group of controls.  If the current 
 * radio button is the last, then it loops back around to the beginning. 
 * 
 * @param wid                 current window id, must be a radio button
 * 
 * @return                    window id of next radio button.  Returns the 
 *                            window id of the argument if none is found.
 */
static int getNextRadioButton(int firstWid)
{
   nextWid := firstWid.p_next;
   while (nextWid.p_object != OI_RADIO_BUTTON) {
      nextWid = nextWid.p_next;

      if (nextWid == firstWid) break;
   }

   return nextWid;
}

/**
 * Determines if we need to set a value in a buffer.  This is used after some 
 * language options have been set to set the updated values for all languages. 
 * 
 * @param settings               list of AllLanguagesSettings to be set 
 * @param langValues             table of language settings, keyed by language 
 *                               and update key.  This is used in case we need
 *                               to get the language setting instead of
 *                               relying on what AllLanguages sent us
 * @param key                    key of current value
 * @param langId                 language id of current buffer
 * @param value                  value to set for buffer
 * 
 * @return bool                  true if we are to set this value for the 
 *                               buffer, false otherwise
 */
bool doSetValue(AllLanguagesSetting (&settings):[], typeless (&langValues):[], _str key, _str langId, _str &value, bool force = false)
{
   do {
      // first look for our key in the list of settings
      if (settings._indexin(key)) {
      
         AllLanguagesSetting als = settings:[key];
   
         // now see if our language is excluded
         if (pos(','langId',', ','als.Exclusions',')) break;

         // set the value then   
         if (doUpdateWithLangValue(key)) {
            // get this from our langValues table
            value = getLangUpdateBuffersValue(langValues, key, langId);
         } else {
            value = als.Value;
         }
      } else if (force) {
         // we are forcing the language value
         value = getLangUpdateBuffersValue(langValues, key, langId);
      } else break;
      
      // maybe we didn't get anything out of this      
      if (value == null) break;

      return true;

   } while (false);

   return false;
}

/**
 * Determines if we can update this setting in the buffers with the new language 
 * value or if we must individually get the setting for each language.   
 * 
 * @param key                                update key setting
 * 
 * @return                                   true if we must get the language 
 *                                           value
 */
static bool doUpdateWithLangValue(_str key)
{
   updateWithLang := false;

   switch (key) {
   case ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY:
   case BOUNDS_UPDATE_KEY:
   case COLOR_FLAGS_UPDATE_KEY:
   case LINE_NUMBERS_LEN_UPDATE_KEY:
   case MARGINS_UPDATE_KEY:
   case SHOW_SPECIAL_CHARS_UPDATE_KEY:
   case SYNTAX_INDENT_UPDATE_KEY:
      updateWithLang = true;
      break;
   }

   return updateWithLang;
}

/**
 * Retrieves a language-specific value from the actual language settings.  Saves 
 * the value for that language in the langValues table so we don't have to 
 * consult the options again. 
 * 
 * @param langValues                table of language settings, keyed by 
 *                                  language and update key
 * @param updateKey                 update key associated with setting that we 
 *                                  are updating
 * @param langId                    language of interest
 * 
 * @return typeless                 language value
 */
static typeless getLangUpdateBuffersValue(typeless (&langValues):[], _str updateKey, _str langId)
{
   value := null;

   // get the key for this value
   key := langId :+ updateKey;

   if (langValues._indexin(key)) {
      // just return the value and don't worry about it
      value = langValues:[key];
   } else {
      // we need to retrieve this value because we haven't come across it before
      switch (updateKey) {
      case ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY:
         value = adaptive_format_get_buffer_flags(langId);
         break;
      case BOUNDS_UPDATE_KEY:
         value = LanguageSettings.getBounds(langId);
         break;
      case COLOR_FLAGS_UPDATE_KEY:
         value = LanguageSettings.getColorFlags(langId);
         break;
      case LINE_NUMBERS_LEN_UPDATE_KEY:
         value = LanguageSettings.getLineNumbersLength(langId);
         break;
      case MARGINS_UPDATE_KEY:
         value = LanguageSettings.getMargins(langId);
         break;
      case SHOW_SPECIAL_CHARS_UPDATE_KEY:
         value = LanguageSettings.getShowTabs(langId);
         break;
      case SYNTAX_INDENT_UPDATE_KEY:
         value = LanguageSettings.getSyntaxIndent(langId);
         break;
      case CUDDLE_ELSE_UPDATE_KEY:
         value = LanguageSettings.getCuddleElse(langId);
         break;
      }

      langValues:[key] = value;
   }

   return value;
}

/**
 * Updates open buffers with new language settings.
 * 
 * @param settings               hash table of new settings
 */
void _update_buffers_for_all_languages(AllLanguagesSetting (&settings):[])
{
   /**
    * We need to figure out whether to update the adaptive 
    * formatting indent settings right now.  We do this when any of 
    * the indent (syntax indent, indent with tabs, and tabs) change 
    * or when the adaptive formatting setting for any of those 
    * changes. 
    */

   update_ad_form_flags := settings._indexin(TABS_UPDATE_KEY) ||
                           settings._indexin(INDENT_WITH_TABS_UPDATE_KEY) ||
                           settings._indexin(BEGIN_END_STYLE_UPDATE_KEY) ||
                           settings._indexin(NO_SPACE_BEFORE_PAREN_UPDATE_KEY) ||
                           settings._indexin(INDENT_CASE_FROM_SWITCH_UPDATE_KEY) ||
                           settings._indexin(PAD_PARENS_UPDATE_KEY) ||
                           settings._indexin(KEYWORD_CASING_UPDATE_KEY) ||
                           settings._indexin(TAG_CASING_UPDATE_KEY) ||
                           settings._indexin(ATTRIBUTE_CASING_UPDATE_KEY) ||
                           settings._indexin(VALUE_CASING_UPDATE_KEY) ||
                           settings._indexin(HEX_VALUE_CASING_UPDATE_KEY) ||
                           settings._indexin(ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY) ||
                           settings._indexin(SYNTAX_INDENT_UPDATE_KEY);

   setAdaptive := settings._indexin(ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY);

   // we need to make sure these settings are appropriate for ISPF emulation
   if (settings._indexin(LINE_NUMBERS_LEN_UPDATE_KEY)) {
      lnl := (int)settings:[LINE_NUMBERS_LEN_UPDATE_KEY].Value;
      checkLineNumbersLengthForISPF(0, lnl);
      settings:[LINE_NUMBERS_LEN_UPDATE_KEY].Value = lnl;
   }
   if (settings._indexin(LINE_NUMBERS_FLAGS_UPDATE_KEY)) {
      lnf := (int)settings:[LINE_NUMBERS_FLAGS_UPDATE_KEY].Value;
      checkLineNumbersLengthForISPF(lnf, 0);
      settings:[LINE_NUMBERS_FLAGS_UPDATE_KEY].Value = lnf;
   }
   
   _safe_hidden_window();
   view_id := 0;
   save_view(view_id);
   int first_buf_id=p_buf_id;
   
   displayProgressCount := 0;
   progressWid := 0;
   
   int adaptiveFlags:[];

   // sometimes a single buffer property is used to hold multiple options (e.g. p_color_flags 
   // holds modified line AND current line), so we can't just use a single value for all 
   // languages - we might have set half the value, but need to leave the rest of the value 
   // alone.  SO!  We keep track of the language values for each language.
   typeless langValues:[];

   for (;;) {

      // get the language for this buffer
      currentLang := p_LangId;

      // clear the embedded settings if we are changing anything that might affect adaptive formatting
      if (update_ad_form_flags) {
         adaptive_format_remove_buffer(p_buf_id);
      }
      EDITOR_CONFIG_PROPERITIES ecprops;
      ecprops.m_property_set_flags=0;
      if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
         _EditorConfigGetProperties(p_buf_name,ecprops,p_LangId,_default_option(VSOPTION_EDITORCONFIG_FLAGS));
         // If this is a beautifier profile override
         if (ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) {
             // IF the override profile is the same as the default profile
             if(strieq(_LangGetBeautifierDefault(p_LangId),ecprops.m_beautifier_default_profile)) {
                 // Pretend there is no override profile so these settings are updated.
                 ecprops.m_property_set_flags&= ~ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE;
             }
         }
      }

      typeless value;
      if (doSetValue(settings, langValues, COLOR_FLAGS_UPDATE_KEY, currentLang, value)) p_color_flags = value|(p_color_flags &LANGUAGE_COLOR_FLAG);
      if (doSetValue(settings, langValues, TRUNCATE_LENGTH_UPDATE_KEY, currentLang, value)) {
         if (!isinteger(value)) value = 0;
         if (value >= 0) {
            p_TruncateLength = value;
         } else {
            len := p_MaxLineLength - 8;
            if (len >= 2) {
               p_TruncateLength = len;
            }
         }
      }
      if (doSetValue(settings, langValues, BOUNDS_UPDATE_KEY, currentLang, value)) {
         parse value with auto BoundsStart auto BoundsEnd .;
         if (!isinteger(BoundsStart) || !isinteger(BoundsEnd) || BoundsStart<=0)  {
            if (p_TruncateLength) {
               p_BoundsStart=1;
               p_BoundsEnd=p_TruncateLength;
            } else {
               p_BoundsStart=0;
               p_BoundsEnd=0;
            }
         } else {
            p_BoundsStart=(int)BoundsStart;
            p_BoundsEnd=(int)BoundsEnd;
         }
         if (index_callable(find_index('ispf_adjust_lc_bounds',PROC_TYPE))) {
            ispf_adjust_lc_bounds();
         }
      }
      if (doSetValue(settings, langValues, CAPS_UPDATE_KEY, currentLang, value)) {
         if (value == CM_CAPS_AUTO) {
            p_caps = _GetCaps() != 0;
         } else {
            if (!isinteger(value)) {
               p_caps = CM_CAPS_OFF!=0;
            } else {
               p_caps = value;
            }
         }
      }
      if (doSetValue(settings, langValues, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING, currentLang, value)) {
         if (p_buf_size>def_use_fundamental_mode_ksize*1024) {
            value=false;
         }
         p_spell_check_while_typing = value;
      }
      if (doSetValue(settings, langValues, VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS, currentLang, value)) p_spell_check_while_typing_elements = value;
      if (doSetValue(settings, langValues, SHOW_MINIMAP_UPDATE_KEY, currentLang, value)) p_show_minimap = value;
      if (doSetValue(settings, langValues, HEX_NOFCOLS_UPDATE_KEY, currentLang, value)) p_hex_Nofcols = value;
      if (doSetValue(settings, langValues, HEX_BYTES_PER_COL_UPDATE_KEY, currentLang, value)) p_hex_bytes_per_col = value;
      if (doSetValue(settings, langValues, SOFT_WRAP_UPDATE_KEY, currentLang, value)) p_SoftWrap = value;
      if (doSetValue(settings, langValues, SOFT_WRAP_ON_WORD_UPDATE_KEY, currentLang, value)) p_SoftWrapOnWord = value;
      if (doSetValue(settings, langValues, HEX_MODE_UPDATE_KEY, currentLang, value)) p_hex_mode = value;
      if (doSetValue(settings, langValues, SHOW_SPECIAL_CHARS_UPDATE_KEY, currentLang, value)) p_ShowSpecialChars = value;

      if ( ! read_format_line() ) {
         if (!(ecprops.m_property_set_flags & (ECPROPSETFLAG_TAB_SIZE|ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) && doSetValue(settings, langValues, TABS_UPDATE_KEY, currentLang, value)) {
            p_tabs = value;
         }
         if (doSetValue(settings, langValues, MARGINS_UPDATE_KEY, currentLang, value)) p_margins = value;
         if (doSetValue(settings, langValues, WORD_WRAP_UPDATE_KEY, currentLang, value)) p_word_wrap_style = value;
         if (!(ecprops.m_property_set_flags & (ECPROPSETFLAG_INDENT_WITH_TABS|ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) && doSetValue(settings, langValues, INDENT_WITH_TABS_UPDATE_KEY, currentLang, value)) p_indent_with_tabs = value;
         //if (doSetValue(settings, langValues, SHOW_TABS_UPDATE_KEY, currentLang, value)) p_show_tabs = value;
         if (doSetValue(settings, langValues, INDENT_STYLE_UPDATE_KEY, currentLang, value)) p_indent_style = value;
         if (doSetValue(settings, langValues, WORD_CHARS_UPDATE_KEY, currentLang, value)) p_word_chars = value;
      }

      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, BEGIN_END_STYLE_UPDATE_KEY, currentLang, value)) p_begin_end_style = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, NO_SPACE_BEFORE_PAREN_UPDATE_KEY, currentLang, value)) p_no_space_before_paren = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, INDENT_CASE_FROM_SWITCH_UPDATE_KEY, currentLang, value)) p_indent_case_from_switch = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, PAD_PARENS_UPDATE_KEY, currentLang, value)) p_pad_parens = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, POINTER_STYLE_UPDATE_KEY, currentLang, value)) p_pointer_style = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, FUNCTION_BRACE_ON_NEW_LINE_UPDATE_KEY, currentLang, value)) p_function_brace_on_new_line = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, KEYWORD_CASING_UPDATE_KEY, currentLang, value)) p_keyword_casing = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, TAG_CASING_UPDATE_KEY, currentLang, value)) p_tag_casing = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, ATTRIBUTE_CASING_UPDATE_KEY, currentLang, value)) p_attribute_casing = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, VALUE_CASING_UPDATE_KEY, currentLang, value)) p_value_casing = value;
      if (!(ecprops.m_property_set_flags & ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE) && doSetValue(settings, langValues, HEX_VALUE_CASING_UPDATE_KEY, currentLang, value)) p_hex_value_casing = value;

      typeless lnf, lnl;
      setLNL := doSetValue(settings, langValues, LINE_NUMBERS_LEN_UPDATE_KEY, currentLang, lnl);
      setLNF := doSetValue(settings, langValues, LINE_NUMBERS_FLAGS_UPDATE_KEY, currentLang, lnf);
      if (setLNF && !setLNL) {
         // if we are not also currently turning on the line numbers length,
         // we need to get that info
         lnl = getLangUpdateBuffersValue(langValues, LINE_NUMBERS_LEN_UPDATE_KEY, currentLang);
         checkLineNumbersLengthForISPF(lnf, lnl);
      }

      if (setLNL) p_line_numbers_len = lnl;
      if (setLNF) {
         if (lnf & LNF_ON) {

            p_line_numbers_len = lnl;
            // we are turning them on
            if (lnf & LNF_AUTOMATIC) {
               // we want automatic mode...
               p_LCBufFlags&=~VSLCBUFFLAG_LINENUMBERS;
               p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS_AUTO;
            } else {
               p_LCBufFlags&=~VSLCBUFFLAG_LINENUMBERS_AUTO;
               p_LCBufFlags|=VSLCBUFFLAG_LINENUMBERS;
            }
         } else {
            // we're turning line numbers off
            p_LCBufFlags&=~(VSLCBUFFLAG_LINENUMBERS|VSLCBUFFLAG_LINENUMBERS_AUTO);
         }
      }

      if (!(ecprops.m_property_set_flags & (ECPROPSETFLAG_SYNTAX_INDENT|ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE)) && doSetValue(settings, langValues, SYNTAX_INDENT_UPDATE_KEY, currentLang, value, true)) {
         p_SyntaxIndent = value;
      } 

      // we update this if the flags changed
      // we also reset it when any of the values have changed
      if (setAdaptive || update_ad_form_flags) {

         typeless langAdaptiveFlags = 0;
         if (doSetValue(settings, langValues, ADAPTIVE_FORMATTING_FLAGS_UPDATE_KEY, currentLang, langAdaptiveFlags, true)) {
            p_adaptive_formatting_flags = langAdaptiveFlags; 
         }

         // do we update the indent settings in each buffer right now? - only if tabs are on and
         // we have cleared the settings that we found
         // we want to update tabs NOW, otherwise, they will be typing along and suddenly the file
         // change appearance, and that is bad.
         if (update_ad_form_flags && (langAdaptiveFlags & AFF_TABS) == 0) {
            // we have to call this so that the form gets painted
            // we don't want to do anything with it because we don't even have a cancel button
            cancel_form_cancelled();

            updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_TABS | AFF_INDENT_WITH_TABS, false);

            ++displayProgressCount;
            if (!progressWid && displayProgressCount>=30) {
               progressWid = show_cancel_form("Updating settings", null, false);
            }

            if (progressWid) {
               cancel_form_set_labels(progressWid, "Updating "p_buf_name" with new settings...");
            }
         }
      }

      // go to our next buffer
      _next_buffer('HN');
      if ( p_buf_id==first_buf_id ) {
         break;
      }
   }
   if (/*update_ad_form_now && */progressWid) {
      close_cancel_form(progressWid);
   }
   activate_window(view_id);
}

bool isLangExcludedFromAllLangsBraceStyle(_str langId)
{
   return (_LanguageInheritsFrom('pas', langId) || _LanguageInheritsFrom('pl1', langId) || _LanguageInheritsFrom('ruby', langId));
}

bool isLangExcludedFromLangTabs(_str langId)
{
   return (_LanguageInheritsFrom('cob', langId) ||
           _LanguageInheritsFrom('mak', langId) ||
           _LanguageInheritsFrom('imakefile', langId) ||
           _LanguageInheritsFrom('py', langId) ||
           _LanguageInheritsFrom('asm390', langId));
}
bool isLangExcludedFromAllLangsTabs(_str langId)
{
   return gExcludeLangIdsTabs._indexin(langId);
}
bool isLangExcludedFromAllLangsIndentWithTabs(_str langId)
{
   return gExcludeLangIdsIndentWithTabs._indexin(langId);
}
/*
  I think it's useful for p_syntax_indent for alias expansion.
  That's why some of these languages have a "syntax_indent"
  property.
 
  We could change this though.
*/
bool isLangExcludedFromAllLangsSyntaxIndent(_str langId)
{
   return !_is_syntax_indent_supported(langId) ||
              (_LanguageInheritsFrom('asm390', langId) ||
                //_LanguageInheritsFrom('cmake', langId)||
                _LanguageInheritsFrom('e', langId) ||
                _LanguageInheritsFrom('mak', langId) ||
               _LanguageInheritsFrom('masm', langId) ||
               _LanguageInheritsFrom('unixasm', langId) ||
               _LanguageInheritsFrom('npasm', langId) ||
               //_LanguageInheritsFrom('protocolbuf', langId)
               //_LanguageInheritsFrom('yaml', langId)
               // _LanguageInheritsFrom('scala', langId) ||
               _LanguageInheritsFrom('tagdoc', langId)
             );
}
