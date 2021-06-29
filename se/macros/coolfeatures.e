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
#include "xml.sh"
#include "license.sh"
#import "help.e"
#import "html.e"
#import "main.e"
#import "optionsxml.e"
#import "seltree.e"
#import "stdprocs.e"
#import "tagform.e"
#endregion

///////////////////////////////////////////////////////////////////////////////
// This module implements support for a SlickEdit "tips and tricks" system.
// The "cool_features" command will launch the tips dialog, which
// will allow the user to navigate sequentially through the list of
// tips and feature descriptions, with links to the configuration
// information, help topics, and optionally online demonstration links.
//

/**
 * Show cool features dialog on startup?
 * 
 * @default  true
 * @category Configuration_Variables
 */
bool def_show_tips_on_startup = true;


///////////////////////////////////////////////////////////////////////////////
// Describes a feature, it's help topic, configuration, etc.
//
struct COOL_FEATURE_INFO {
   _str title;
   _str text;
   _str helpTopic;
   _str configCommand;
   _str demoURL;
   bool isNew;
};

///////////////////////////////////////////////////////////////////////////////
// State data for cool feature form, saved and restored in
// ctl_cool_html.p_user.
// 
struct COOL_FEATURE_STATE {
   int tagline;                     // index of next tag line to show (persistent)
   int topic;                       // index of current topic (persistent)
   int numTopics;                   // number of topics in config file
   COOL_FEATURE_INFO feature_info;  // current feature information
};

static COOL_FEATURE_STATE CURRENT_STATE(...) {
   if (arg()) ctl_cool_html.p_user=arg(1);
   return ctl_cool_html.p_user;
}

// Timer used to delay showing cool features dialog until there are
// no modal forms showing. There will never be more than 1 of these.
static int cool_features_timer_handle = -2;

definit()
{
   if( arg(1) == 'L' ) {
      if( cool_features_timer_handle >=0 ) {
         _kill_timer(cool_features_timer_handle);
      }
   }
   cool_features_timer_handle= -2;
}

///////////////////////////////////////////////////////////////////////////////
// Event handlers for the cool features dialog
// 
defeventtab _coolfeatures_form;

/**
 * Display the cool features dialog to display 
 * SlickEdit "tips and tricks" and key features.
 */
_command void cool_features(_str autoshow="")
{
   // Never, never allow more than a single timer handle for cool features.
   // It is possible for cool_features() to be called twice when we get
   // a new state file (once from main.e, once from postinstall.e).
   if( cool_features_timer_handle >= 0 ) {
      _kill_timer(cool_features_timer_handle);
      cool_features_timer_handle= -2;
   }

   if (autoshow == "startup") {
      if (def_show_tips_on_startup) {
         cool_features_timer_handle=_set_timer(1000,cool_features,"timer");
      }
      return;
   } else if( autoshow == "timer" ) {
      if( !_mdi.p_enabled ||
          find_index("vstrial.ex",MODULE_TYPE) > 0 ||
          find_index("vsreg.ex",MODULE_TYPE) > 0 ||
          (_trial() && _FlexlmNofusers() < 0) ) {

         // Delay showing cool features until there are no modal forms up.
         // Modal forms include: autotag, emulation, trial, registration.
         cool_features_timer_handle=_set_timer(1000,cool_features,"timer");
         return;
      }
      // Fall through to show the dialog
      autoshow="";
   }
   show("-xy -app _coolfeatures_form ", autoshow);
}

/**
 * Show the i'th cool feature in the feature database.
 * 
 * @param i    index of feature to look up
 * 
 * @return 0 on success, <0 on error.
 */
static void showCoolFeature(int i)
{
   COOL_FEATURE_INFO cfi[];
   int status = getCoolFeaturesInfo(cfi);
   if (status < 0) {
      _message_box("Error reading: "getCoolFeaturesPath()"\n"get_message(status));
      return;
   }
   if (i < 0 || i >= cfi._length()) {
      _message_box("Invalid feature ID");
      return;
   }

   newFeature := "";
   if (cfi[i].isNew) {
      newFeature = " (New!)";
   }

   text :=  "<h3>"cfi[i].title:+newFeature"</h3>":+"<p>"cfi[i].text;
   ctl_feature_html.p_text=text;
   ctl_configure_btn.p_enabled = (cfi[i].configCommand != '');
   ctl_help_btn.p_enabled      = (cfi[i].helpTopic != '');
   ctl_demo_btn.p_enabled      = (cfi[i].demoURL != '');

   // update current feature information
   COOL_FEATURE_STATE state = CURRENT_STATE();
   state.feature_info      = cfi[i];
   state.numTopics         = cfi._length();
   state.topic             = i;
   CURRENT_STATE(state);
   if (isEclipsePlugin()) {
      ctl_help_btn.p_enabled = false;
   }
}

/**
 * Initial setup of the cool features form.
 */
void ctl_feature_html.on_create(_str autoshow="")
{
   // RGH - 5/9/2006
   // Using a different color SE logo for the Eclipse cool features
   if (isEclipsePlugin()) {
      _nocheck _control ctl_slickedit_pic;
      p_active_form.ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_eclipse.ico@128");
   } else if (_isStandardEdition()) {
      _nocheck _control ctl_slickedit_pic;
      p_active_form.ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_standard.ico@128");
   } else if (_isCommunityEdition()) {
      _nocheck _control ctl_slickedit_pic;
      p_active_form.ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_community.ico@128");
   } else {
      _nocheck _control ctl_slickedit_pic;
      p_active_form.ctl_slickedit_pic.p_picture = _find_or_add_picture("vse_profile.ico@128");
   }

   // dialog state (stored in ctl_cool_html.p_user)
   COOL_FEATURE_STATE state;
   state.feature_info=null;
   state.numTopics=0;
   state.topic=0;
   state.tagline=0;

   // restore the last selected feature
   typeless i = _retrieve_value("_cool_features_form.ctl_feature_html.p_user");
   if (isuinteger(i)) {
      state.topic=i;
   }

   // restore the last selected tag line
   i = _retrieve_value("_cool_features_form.ctl_cool_html.p_user");
   if (isuinteger(i)) {
      state.tagline=i;
   }

   // show the the next tag line
   _str taglines[];
   int status = getCoolFeaturesTagLines(taglines);
   if (!status) {
      if (state.tagline < 0 || state.tagline >= taglines._length()) {
         state.tagline = 0;
      }
      ctl_cool_html.p_text = taglines[state.tagline];
      state.tagline++;
   }

   // restore the last feature they were viewing
   CURRENT_STATE(state);
   showCoolFeature(state.topic);

   // were we invoked from first init?
   //ctl_close_btn.p_user = (autoshow==1);

   // show on startup?
   ctl_startup_btn.p_value = def_show_tips_on_startup? 1:0;
   ctl_startup_btn.p_visible = false;     // we started using Quick Start at startup instead in v14
}

/**
 * Close the cool features dialog and tell them how to get back to it.
 */
void ctl_feature_html.on_destroy()
{
   // save current topic and tagline
   COOL_FEATURE_STATE state = CURRENT_STATE();
   _append_retrieve(0, state.topic,   "_cool_features_form.ctl_feature_html.p_user");
   _append_retrieve(0, state.tagline, "_cool_features_form.ctl_cool_html.p_user");

   // update def-var for show tips on startup
   show_tips := (ctl_startup_btn.p_value != 0);
   if (show_tips != def_show_tips_on_startup) {
      def_show_tips_on_startup = show_tips;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   //if (ctl_close_btn.p_user != 0) {
   //   _message_box("This dialog will not come up again automatically.\n\n":+
   //                "To see the Cool Features dialog again, go to \"Help\" -> \"Cool Features...\"");
   //}
}

/**
 * Resize the cool features form.
 */
void _coolfeatures_form.on_resize()
{
   // collect positioning details
   int border_x = ctl_slickedit_pic.p_x;
   int border_y = ctl_slickedit_pic.p_y;
   int logo_width  = ctl_slickedit_pic.p_width;
   int logo_height = ctl_slickedit_pic.p_height;
   int button_height = ctl_close_btn.p_height;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      min_width := 5*border_x +
                      ctl_configure_btn.p_width +
                      ctl_help_btn.p_width +
                      ctl_demo_btn.p_width;
      min_height := 6*border_y + button_height*2 + 2*logo_height;
      _set_minimum_size(min_width, min_height);
   }

   // available space and border usage
   avail_x := p_width;
   avail_y := p_height;

   // set the widths for the HTML controls
   ctl_cool_html.p_x = logo_width + 2*border_x;
   ctl_cool_html.p_width = avail_x - logo_width - 3*border_x;
   ctl_cool_html.p_height = logo_height;
   ctl_feature_html.p_width = avail_x - 2*border_x;
   ctl_feature_html.p_y = logo_height + 3*border_y;

   // set the divider bar's y position
   int divider_y = avail_y - button_height - border_y*2 - ctldivider.p_height;
   ctldivider.p_width = avail_x - 2*border_x;
   ctldivider.p_y = divider_y;

   // set the button's y positions
   ctl_close_btn.p_y   = avail_y - button_height - border_y;
   ctl_prev_btn.p_y    = avail_y - button_height - border_y;
   ctl_next_btn.p_y    = avail_y - button_height - border_y;
   ctl_topics_btn.p_y  = avail_y - button_height - border_y;
   ctl_topics_btn.p_y  = avail_y - button_height - border_y;
   ctl_startup_btn.p_y = avail_y - button_height - border_y + ctldivider.p_height;

   // set the first row's y positions
   ctl_configure_btn.p_y = divider_y - button_height - border_y;
   ctl_help_btn.p_y      = divider_y - button_height - border_y;
   ctl_demo_btn.p_y      = divider_y - button_height - border_y;

   // set first row of button's x positions
   ctl_help_btn.p_x = ctl_configure_btn.p_x_extent + border_x;
   ctl_demo_btn.p_x = ctl_help_btn.p_x_extent + border_x;

   // set second row of button's x positions
   ctl_topics_btn.p_x = ctl_close_btn.p_x_extent + border_x;
   ctl_prev_btn.p_x = ctl_topics_btn.p_x_extent + border_x;
   ctl_next_btn.p_x = ctl_prev_btn.p_x_extent + border_x;

   // set the height of the lower HTML control
   ctl_feature_html.p_height = avail_y - logo_height - 7*border_y - button_height*2;
}

/**
 * Launch help to display more information about the current feature.
 */
void ctl_help_btn.lbutton_up()
{
   COOL_FEATURE_STATE state = CURRENT_STATE();
   COOL_FEATURE_INFO cfi = state.feature_info;
   if (cfi.helpTopic != '') {
      help(cfi.helpTopic);
   } else {
      _message_box("No help available for "cfi.title);
   }
}

/**
 * Launch web browser with the specified Demo code URL.
 */
void ctl_demo_btn.lbutton_up()
{
   COOL_FEATURE_STATE state = CURRENT_STATE();
   COOL_FEATURE_INFO cfi = state.feature_info;
   if (cfi.demoURL != '') {
      _str url=cfi.demoURL;
      if (_screen_height() <= 800 && !isEclipsePlugin()) {
         url = stranslate(url, "/low/", "/high/");
      }
      goto_url(url);
   } else {
      _message_box("No demo available for "cfi.title);
   }
   
}
/**
 * Launch the designated command to configure options related to the
 * current feature.
 */
void ctl_configure_btn.lbutton_up()
{
   COOL_FEATURE_STATE state = CURRENT_STATE();
   COOL_FEATURE_INFO cfi = state.feature_info;
   if (cfi.configCommand != '') {
      execute(cfi.configCommand);
   } else {
      _message_box("No configuration options available for "cfi.title);
   }

}

/**
 * Jump to the previous cool feature.
 */
void ctl_prev_btn.lbutton_up()
{
   COOL_FEATURE_STATE state = CURRENT_STATE();
   if (state.topic <= 0) {
      state.topic = state.numTopics;
   }
   showCoolFeature(--state.topic);
}

/**
 * Jump to the next cool feature.
 */
void ctl_next_btn.lbutton_up()
{
   COOL_FEATURE_STATE state = CURRENT_STATE();
   if (state.topic >= state.numTopics-1) {
      state.topic = -1;
   }
   showCoolFeature(++state.topic);
}

/**
 * Select a topic among the cool feature topics.
 */
static void selectCoolFeatureTopic()
{
   COOL_FEATURE_INFO cfi[];
   _str keys[];
   _str topics[];
   getCoolFeaturesInfo(cfi);
   int i,n = cfi._length();
   for (i=0; i<n; ++i) {
      newFeature := "";
      if (cfi[i].isNew) {
         newFeature = " (New!)";
      }
      topics[i] = cfi[i].title:+newFeature;
      topics[i] = stranslate(topics[i], "(TM)", "&trade;");
      topics[i] = stranslate(topics[i], VSREGISTEREDTM, "&reg;");
      keys[i] = i;
   }
   typeless result = select_tree(topics,keys);
   if (result==COMMAND_CANCELLED_RC) {
      return;
   }
   if (result >= 0 && result<topics._length()) {
      showCoolFeature(result);
   }
}

/**
 * Show list of topics
 */
void ctl_topics_btn.lbutton_up()
{
   coolFeaturesForm := p_active_form;
   selectCoolFeatureTopic();
   coolFeaturesForm._set_focus();
}

/**
 * Show the topics list if they click on the "cool features" link
 */
void ctl_cool_html.on_change(int reason,_str hrefText)
{
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      if (hrefText=='<<topics') {
         selectCoolFeatureTopic();
         return;
      }
   }
}

///////////////////////////////////////////////////////////////////////////////
// Configuration file loading.
// 

/**
 * Return the path to the configuration file for cool features.
 */
static _str getCoolFeaturesPath()
{
   return _getSysconfigMaybeFixPath("coolfeatures":+FILESEP:+"coolfeatures.xml");
}

_command void showCoolFeaturesOptions(_str node = '') name_info(',')
{
   origWid := p_active_form;

   optionsWid := config(node, 'N');
   optionsWid._set_foreground_window();
   _modal_wait(optionsWid);

   origWid._set_foreground_window();
}

/**
 * Load all the cool features topics into the 'cfi' array.
 * 
 * @param cfi     (output) array of cool features.
 * 
 * @return 0 on success, <0 on error.
 */
static int getCoolFeaturesInfo(COOL_FEATURE_INFO (&cfi)[])
{
   cfi._makeempty();

   status := 0;
   int xmlfd = _xmlcfg_open(getCoolFeaturesPath(), status, VSXMLCFG_OPEN_ADD_PCDATA);
   if (status < 0) {
      return status;
   }

   _str features_array[];
   features_array._makeempty();
   status = _xmlcfg_find_simple_array(xmlfd, "//Feature", features_array);
   if (status < 0) {
      _xmlcfg_close(xmlfd);
      return status;
   }

   int i,n = features_array._length();
   c := 0;
   for (i=0; i<n; ++i) {
      int feature = (int) features_array[i];
      // RGH - 6/7/06
      // Here we check the current feature to see if it's applicable to our product
      // Currently this only supports the eclipse plugin and main product
      add_feature := true;
      _str product_list = _xmlcfg_get_attribute(xmlfd, feature, "Products");
      if (product_list != '') {
         if (isEclipsePlugin() && !pos("Core", product_list)) {
            add_feature = false;
         } else if (!isEclipsePlugin() && !pos("SlickEdit", product_list)){
            add_feature = false;
         }
      }

      if (add_feature) {
         // check if this requires a feature that may not be available in this edition
         _str req_feat = _xmlcfg_get_attribute(xmlfd, feature, "RequiresFeatures");
         if (req_feat != '') {
            if (!_haveContextTagging() && pos("ContextTagging", req_feat)) {
               add_feature = false;
            } else if (!_haveProDiff() && pos("Diffzilla", req_feat)) {
               add_feature = false;
            } else if (!_haveProMacros() && pos("ProMacros", req_feat)) {
               add_feature = false;
            }
         }
      }

      if (feature >= 0 && add_feature) {
         cfi[c].title         = _xmlcfg_get_attribute(xmlfd, feature, "Name");
         cfi[c].configCommand = _xmlcfg_get_attribute(xmlfd, feature, "Configure");
         cfi[c].helpTopic     = _xmlcfg_get_attribute(xmlfd, feature, "HelpTopic");
         if (!isEclipsePlugin()) {
            cfi[c].demoURL       = _xmlcfg_get_attribute(xmlfd, feature, "DemoURL");
         } else {
            cfi[c].demoURL       = _xmlcfg_get_attribute(xmlfd, feature, "PDemoURL");
         }
         cfi[c].isNew         = _xmlcfg_get_attribute(xmlfd, feature, "New") != '';
         cfi[c].text='';
         int text_index    = _xmlcfg_get_first_child(xmlfd, feature, VSXMLCFG_NODE_PCDATA);
         if (text_index > 0) {
            cfi[c].text =_xmlcfg_get_value(xmlfd, text_index);
         }
         c++;
      }
   }

   _xmlcfg_close(xmlfd);
   return 0;
}

/**
 * Get the marketting tag lines for SlickEdit.
 * 
 * @param taglines   array of tag lines
 * 
 * @return 0 on success, <0 on error.
 */
static int getCoolFeaturesTagLines(_str (&taglines)[])
{
   taglines._makeempty();
   status := 0;
   int xmlfd = _xmlcfg_open(getCoolFeaturesPath(), status, VSXMLCFG_OPEN_ADD_PCDATA);
   if (status < 0) {
      return status;
   }

   status = _xmlcfg_find_simple_array(xmlfd, "//TagLine", taglines);
   if (status < 0) {
      _xmlcfg_close(xmlfd);
      return status;
   }

   int i, n = taglines._length();
   for (i=0; i<n; ++i) {
      int feature = (int) taglines[i];
      int text_index    = _xmlcfg_get_first_child(xmlfd, feature, VSXMLCFG_NODE_PCDATA);
      if (text_index > 0) {
         taglines[i] =_xmlcfg_get_value(xmlfd, text_index);
      }
   }

   _xmlcfg_close(xmlfd);
   return 0;
}
