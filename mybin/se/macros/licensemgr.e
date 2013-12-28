////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47140 $
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
//#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "license.sh"
//#import "stdprocs.e"
//#import "treeview.e"
//#import "wizard.e"
#endregion

#ifdef USE_FLEX_LICENSING
   #define LMW_LICENSE_NAME 'slickedit.lic'
   #define LWM_LICENSE_EXT '.lic'
   #define LICENSE_FILE_TYPE '*.lic'
   #define LICENSE_SERVER_PORT '27000'
#endif

#ifdef USE_SEAL_LICENSING
   #define LMW_LICENSE_NAME 'slickedit.lic'
   #define LWM_LICENSE_EXT '.lic'
   #define LICENSE_FILE_TYPE '*.lic;*.html;*.txt'
   #define LICENSE_SERVER_PORT '27100'
#endif

boolean def_prompt_renew_sub = true;

#define VSREG_URL "http://register.slickedit.com/vsreg/v3/"

#define FLX_MIN_STATUS 4
#define FLX_MAX_STATUS 11 

#define VSACTIVATE_URL "http://www.slickedit.com/php/rdir/"
_form _license_wizard_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='SlickEdit License Wizard';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=12024;
   p_width=13965;
   p_x=18746;
   p_y=-84;
   _picture_box ctlslide0 {
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_clip_controls=false;
      p_forecolor=0x80000008;
      p_height=4080;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=1;
      p_value=0;
      p_width=6900;
      p_x=60;
      p_y=60;
      p_eventtab2=_ul2_picture;
      _label ctls0_title {
         p_alignment=AL_LEFT;
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='No License Found';
         p_font_bold=true;
         p_forecolor=0x80000008;
         p_height=192;
         p_tab_index=1;
         p_width=1482;
         p_word_wrap=false;
         p_x=120;
         p_y=120;
      }
      _label ctls0_info {
         p_alignment=AL_LEFT;
         p_auto_size=false;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='If you do not have a license, you can request a Trial License or purchase a license.  To install a Full or Trial License, select "Install a license file".  If you have already purchased a license and do not have a license file, select "Request a license file for a purchased product".';
         p_forecolor=0x80000008;
         p_height=800;
         p_tab_index=2;
         p_width=6180;
         p_word_wrap=true;
         p_x=480;
         p_y=600;
      }
      _radio_button ctls0_request_trial {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='Request a &Trial License';
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=2;
         p_tab_stop=true;
         p_value=1;
         p_width=3000;
         p_x=720;
         p_y=1770;
      }
      _radio_button ctls0_purchase_lic {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='&Purchase a license';
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=3;
         p_tab_stop=true;
         p_value=0;
         p_width=3000;
         p_x=720;
         p_y=2250;
      }
      _radio_button ctls0_install_license_file {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='&Install a license file';
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=4;
         p_tab_stop=true;
         p_value=0;
         p_width=3000;
         p_x=715;
         p_y=3240;
      }
      _radio_button ctls0_request_license_file {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='Request a license file for a purchased product';
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=4;
         p_tab_stop=true;
         p_value=0;
         p_width=4558;
         p_x=720;
         p_y=2940;
      }
      _check_box ctls0_nag {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='Do not remind me again.';
         p_forecolor=0x80000008;
         p_height=300;
         p_style=PSCH_AUTO2STATE;
         p_tab_index=9;
         p_tab_stop=true;
         p_value=0;
         p_width=2700;
         p_x=720;
         p_y=3600;
      }
      _radio_button ctls0_renew {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='&Renew your subscription';
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=10;
         p_tab_stop=true;
         p_value=0;
         p_width=3000;
         p_x=720;
         p_y=1410;
      }
      _radio_button ctls0_continue {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='&Continue current subscription';
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=10;
         p_tab_stop=true;
         p_value=0;
         p_width=3000;
         p_x=720;
         p_y=1080;
      }
      _radio_button ctls0_use_license_server {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='&Use a license server (concurrent licenses)';
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=11;
         p_tab_stop=true;
         p_value=0;
         p_width=5161;
         p_x=715;
         p_y=2616;
         p_eventtab=_license_wizard_form.ctls0_purchase_lic;
      }
   }
   _picture_box ctlslide2 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_clip_controls=false;
      p_forecolor=0x80000008;
      p_height=4740;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=2;
      p_value=0;
      p_width=6895;
      p_x=60;
      p_y=7080;
      p_eventtab2=_ul2_picture;
      _label ctls2_title {
         p_alignment=AL_LEFT;
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='Enter a Trial License File';
         p_font_bold=true;
         p_forecolor=0x80000008;
         p_height=192;
         p_tab_index=1;
         p_width=2067;
         p_word_wrap=false;
         p_x=120;
         p_y=120;
      }
      _label ctls2_info_1 {
         p_alignment=AL_LEFT;
         p_auto_size=false;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='After registering on the SlickEdit.com site, a Trial License File will be e-mailed to you.';
         p_forecolor=0x80000008;
         p_height=480;
         p_tab_index=2;
         p_width=6180;
         p_word_wrap=true;
         p_x=420;
         p_y=600;
      }
      _text_box ctls2_license_file {
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_FIXED_SINGLE;
         p_completion=FILENOQUOTES_ARG;
         p_forecolor=0x80000008;
         p_height=252;
         p_tab_index=6;
         p_tab_stop=true;
         p_width=6305;
         p_x=420;
         p_y=2100;
         p_eventtab2=_ul2_textbox;
      }
      _command_button ctls2_browse {
         p_cancel=false;
         p_caption='&Browse for license file...';
         p_default=false;
         p_height=360;
         p_tab_index=7;
         p_tab_stop=true;
         p_width=2392;
         p_x=420;
         p_y=4140;
      }
   }
   _picture_box ctlslide1 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_clip_controls=false;
      p_forecolor=0x80000008;
      p_height=2820;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=3;
      p_value=0;
      p_width=6900;
      p_x=60;
      p_y=4200;
      p_eventtab2=_ul2_picture;
      _label ctls1_info {
         p_alignment=AL_LEFT;
         p_auto_size=false;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption="You can open the default web browser or copy the URL to the clipboard for use in another browser.";
         p_forecolor=0x80000008;
         p_height=540;
         p_tab_index=1;
         p_width=6180;
         p_word_wrap=true;
         p_x=420;
         p_y=600;
      }
      _radio_button ctls1_launch {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='&Launch default web browser';
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=2;
         p_tab_stop=true;
         p_value=1;
         p_width=3000;
         p_x=720;
         p_y=1200;
      }
      _radio_button ctls1_copy {
         p_alignment=AL_LEFT;
         p_backcolor=0x80000005;
         p_caption='&Copy URL to clipboard';
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=3;
         p_tab_stop=true;
         p_value=0;
         p_width=3000;
         p_x=720;
         p_y=1680;
      }
      _text_box ctls1_url {
         p_auto_size=false;
         p_backcolor=0x80000005;
         p_border_style=BDS_FIXED_SINGLE;
         p_completion=NONE_ARG;
         p_forecolor=0x80000008;
         p_height=360;
         p_tab_index=4;
         p_tab_stop=true;
         p_width=5580;
         p_x=960;
         p_y=2040;
         p_eventtab2=_ul2_textbox;
      }
      _label ctls1_title {
         p_alignment=AL_LEFT;
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='Request a Trial License';
         p_font_bold=true;
         p_forecolor=0x80000008;
         p_height=192;
         p_tab_index=6;
         p_width=1937;
         p_word_wrap=false;
         p_x=120;
         p_y=120;
      }
   }
   _picture_box ctlslide5 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_clip_controls=false;
      p_forecolor=0x80000008;
      p_height=4260;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=8;
      p_value=0;
      p_width=6900;
      p_x=7020;
      p_y=5460;
      p_eventtab2=_ul2_picture;
      _label ctls5_info_1 {
         p_alignment=AL_LEFT;
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='Licensing operations successful.';
         p_forecolor=0x80000008;
         p_height=192;
         p_tab_index=4;
         p_width=2457;
         p_word_wrap=false;
         p_x=420;
         p_y=600;
      }
      _label ctls5_title {
         p_alignment=AL_LEFT;
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='License Authentication Status';
         p_font_bold=true;
         p_forecolor=0x80000008;
         p_height=192;
         p_tab_index=7;
         p_width=2444;
         p_word_wrap=false;
         p_x=120;
         p_y=120;
      }
      _minihtml ctls5_info_2 {
         p_backcolor=0x80000022;
         p_border_style=BDS_NONE;
         p_height=3000;
         p_PaddingX=0;
         p_PaddingY=0;
         p_tab_index=10;
         p_tab_stop=true;
         p_width=6180;
         p_word_wrap=true;
         p_x=420;
         p_y=1040;
         p_eventtab2=_ul2_minihtm;
      }
   }
   _picture_box ctlslide6 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_clip_controls=false;
      p_forecolor=0x80000008;
      p_height=10;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=8;
      p_value=0;
      p_width=10;
      p_x=60;
      p_y=60;
      p_eventtab2=_ul2_picture;
   }
   _picture_box ctlslide3 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_clip_controls=false;
      p_forecolor=0x80000008;
      p_height=3960;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=10;
      p_value=0;
      p_width=6900;
      p_x=7020;
      p_y=60;
      p_eventtab2=_ul2_picture;
      _label ctllabel35 {
         p_alignment=AL_LEFT;
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='License Authentication Status';
         p_font_bold=true;
         p_forecolor=0x80000008;
         p_height=192;
         p_tab_index=7;
         p_width=2444;
         p_word_wrap=false;
         p_x=120;
         p_y=120;
      }
      _minihtml ctls3_error {
         p_backcolor=0x80000022;
         p_border_style=BDS_FIXED_SINGLE;
         p_height=1080;
         p_PaddingX=100;
         p_PaddingY=0;
         p_tab_index=10;
         p_tab_stop=true;
         p_width=6180;
         p_word_wrap=true;
         p_x=420;
         p_y=600;
         p_eventtab2=_ul2_minihtm;
      }
   }
   _picture_box ctlslide4 {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_clip_controls=false;
      p_forecolor=0x80000008;
      p_height=1320;
      p_max_click=MC_SINGLE;
      p_Nofstates=1;
      p_picture='';
      p_stretch=false;
      p_style=PSPIC_DEFAULT;
      p_tab_index=11;
      p_value=0;
      p_width=6900;
      p_x=7020;
      p_y=4080;
      p_eventtab2=_ul2_picture;
      _label ctls4_info_1 {
         p_alignment=AL_LEFT;
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='Licensing failed.  Please contact SlickEdit Product Support for assistance.';
         p_forecolor=0x80000008;
         p_font_bold = true;
         p_height=384;
         p_tab_index=4;
         p_width=4680;
         p_word_wrap=true;
         p_x=420;
         p_y=528;
      }
      _label ctllabel39 {
         p_alignment=AL_LEFT;
         p_auto_size=true;
         p_backcolor=0x80000005;
         p_border_style=BDS_NONE;
         p_caption='License Authentication Status';
         p_font_bold=true;
         p_forecolor=0x80000008;
         p_height=192;
         p_tab_index=7;
         p_width=2444;
         p_word_wrap=false;
         p_x=120;
         p_y=120;
      }
   }
}

#define ACTPATH_TRIAL         1
#define ACTPATH_PURCHASE      2
#define ACTPATH_INSTALL_LICENSE_FILE     3
#define ACTPATH_REPAIR        4
#define ACTPATH_DEACTIVATE    5
#define ACTPATH_RENEW         6
#define ACTPATH_REQUEST_LICENSE_FILE      7
#define ACTPATH_USE_LICENSE_SERVER     8

#define VSTRIAL_MACRO_VERSION "1.3"

static int activationPath = 0;
static _str errorCode = '';
static _str errorString = '';
static boolean gInvokedFromMenu = false;
static typeless gOldCallbackTable:[];

static typeless ght:[];
static _str gArrHostid[];

static _str ginstall_license_file_src;
static boolean ginstall_license_file_src_is_temp_file;

_command void lmw(_str menu='') name_info(','VSARG2_EDITORCTL)
{
   boolean invokedFromMenu=menu!='';
   LicenseWizard(invokedFromMenu);
   if (invokedFromMenu) {
      fnpCheckoutLicense();
   }
   if (ginstall_license_file_src_is_temp_file) {
      delete_file(ginstall_license_file_src);
   }
}

static _str urlencode(_str s)
{
   _str ts='';
   int i;
   for( i=1;i<=length(s);++i ) {
      _str ch=substr(s,i,1);
      if( !isalnum(ch) ) {
         _str n,x=dec2hex(_asc(ch));
         parse x with '0x'n;
         if( length(n)==1 ) n='0'n;
         ts=ts:+'%'n;
      } else {
         ts=ts:+ch;
      }
   }
   return(ts);
}

static int getIniData(typeless (&ht):[])
{
   _str path = get_env("VSLICKBIN1");
   if( path == "" ) {
      return PATH_NOT_FOUND_RC;
   }
   _maybe_append_filesep(path);
   path=path:+"vstrial.ini";
   if( !file_exists(path) ) {
      src='slickedit.com';
   } else {
      _str src = "";
      int status = _ini_get_value(path,"Trial","src",src);
      if( status != 0 ) {
         return status;
      }
   }
   ht:["src"]=src;
   return 0;
}

static _str _getOsVersion()
{
   _str osversion="";
#if __NT__
   typeless MajorVersion="", MinorVersion="", BuildNumber="", PlatformId="", CSDVersion="", ProductType="";
   ntGetVersionEx(MajorVersion,MinorVersion,BuildNumber,PlatformId,CSDVersion,ProductType);
   if( length(MinorVersion)<1 ) {
      MinorVersion='0';
   }
   osversion = MajorVersion'.'MinorVersion'.'BuildNumber'  'CSDVersion;
#elif __UNIX__
   UNAME info;
   _uname(info);
   osversion = info.release' 'info.version;
#endif
   return osversion;
}

static _str _GetOsInfo(_str& osname, _str& osversion)
{
   _str osinfo = "";
   osname = _getOsName();
   osversion = _getOsVersion();
   osinfo = osinfo:+" ":+osversion;
   return(osinfo);
}

static void _InitializeUrlInfo()
{
   ght._makeempty();
   gArrHostid._makeempty();

   // Initialization
   _str line=get_message(SLICK_EDITOR_VERSION_RC);
   _str product="", version="";
   parse line with product 'Version' version .;

   ght:["ver"]=version;
   ght:["src"]="";

   ght:["hn"]=_gethostname();

   _str os_line=_GetOsInfo(osnm,osver);
   ght:["osnm"]=urlencode(osnm);
   ght:["osver"]=urlencode(osver);

   ght:["pv"]=_getVersion(false);

   ght:["mv"]=VSTRIAL_MACRO_VERSION;
   _str machindId = "";
   _fnpGetMachineIdentifier(machindId); 
   ght:["umn"]=machindId;
   _str productCode = "";
   _fnpGetProductCode(productCode);
   ght:["pc"]=productCode;
   ght:["id"]=_fnpGetId();
   ght:["hid"]=_fnpGetHostIds();
   ght:["aid"]=_fnpGetAltId();

   // Read vstrial.ini for additional options
   typeless status=getIniData(ght);
   if( status != 0 ) {
      _str msg = "Unable to read trial data. "get_message(status);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }
}
/**
 * <dl compact=1>
 * <dt>do</dt><dd> Action to take,  "trial", "buy", "license"   trial buy</dd>
 * <dt>src</dt><dd>   Download source (passed at runtime from a .ini file)  slickedit.com  wrox</dd>
 * <dt>hn</dt><dd> Host Computername (hostname)  jmacko2  foomanchu</dd>
 * <dt>hid</dt><dd>   Host Id's from flex</dd>
 * <dt>aid</dt><dd>   Alt Id, on linux hostname, on windows VSN</dd>
 * <dt>id</dt><dd> MD5 hash of  concatonated hid and aid variables</dd>
 * <dt>pc</dt><dd> Product Code identifier (corresponds to dowload file) wbec  vlxep</dd>
 * <dt>mv</dt><dd> Product Macro_version   1.3</dd>
 * <dt>pv</dt><dd> Product Version Name 3.3   2007</dd>
 * <dt>ver</dt><dd> No longer needed. Product version of 
 * vsapi.dll. The version of slickedit 12.0.3.0</dd> 
 * <dt>cu</dt><dd> Was the url entered by using the copy url button.  For statistical use. 1  0</dd> 
 * </dl>
 * 
 * @param action
 * 
 * @return 
 */
static _str _GenerateUrl(_str action = "",int cpurl=1)
{
   _str u = VSACTIVATE_URL;
   u = u'?mv='ght:["mv"]'&pc='ght:["pc"];
   //u = u'&hn='ght:["hn"]'&pv='ght:["pv"]'&ver='ght:["ver"]'&src='ght:["src"];
   u = u'&hn='ght:["hn"]'&pv='ght:["pv"]'&src='ght:["src"];
   u = u'&do='action'&id='ght:["id"];
   u = u'&hid='ght:["hid"]'&aid='ght:["aid"]'&cu='cpurl;
   // hid, aid, work on id hash
   return(u);
}

static void disable_all_wizard_buttons(int slideNumber)
{
   int highestSlide = 6;

   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();

   // save the old callback table
   gOldCallbackTable = pWizardInfo -> callbackTable;

   // disable next and back by setting everything to skip
   for (i = 0; i <= highestSlide; i++) {
      pWizardInfo -> callbackTable:['ctlslide'i'.skip'] = 1;
   }

   // disable cancel
   pWizardInfo -> callbackTable:['ctlslide'slideNumber'.canceloff'] = 1;

   // disable finish
   pWizardInfo -> callbackTable:['ctlslide'slideNumber'.finishon'] = 0;

   // now call the wizard to check on these buttons
   _WizardMaybeEnableButtons();
}

static void restore_callback_table(boolean enableButtons = true)
{
   // restore old callback table
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   pWizardInfo -> callbackTable = gOldCallbackTable;

   // now call the wizard to check on these buttons
   if (enableButtons) {
      _WizardMaybeEnableButtons();
   }
}


// Wizard Callbacks

static int lmw_finish()
{
   // TODO : does anything go here?
   return 0;
}

static int lmw_destroy()
{
   // see if the nag checkbox is visible (in case of cancel on first page) and note its value
   if (ctlslide0.p_visible && ctls0_nag.p_visible) {
      def_prompt_renew_sub = (ctls0_nag.p_value == 0);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   // TODO : does anything go here?
   return 0;
}

static int lmw_return_to_beginning()
{
   // set everything to skip except for the beginning slide
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   pWizardInfo->callbackTable:['ctlslide0.skip'] = 0;
   pWizardInfo->callbackTable:['ctlslide1.skip'] = 1;
   pWizardInfo->callbackTable:['ctlslide2.skip'] = 1;
   pWizardInfo->callbackTable:['ctlslide3.skip'] = 1;
   pWizardInfo->callbackTable:['ctlslide4.skip'] = 1;
   pWizardInfo->callbackTable:['ctlslide5.skip'] = 1;

   return 0;
}

void lmw_finish_with_error()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();

   // slide 4 is the success screen, 3 is the error screen
   pWizardInfo->callbackTable:['ctlslide3.skip'] = 0;
   pWizardInfo->callbackTable:['ctlslide4.skip'] = 1;
   pWizardInfo->callbackTable:['ctlslide5.skip'] = 1;
}

void lmw_finish_successfully()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();

   // slide 4 is the success screen, 3 is the error screen
   pWizardInfo->callbackTable:['ctlslide3.skip'] = 1;
   pWizardInfo->callbackTable:['ctlslide5.skip'] = 0;
   pWizardInfo->callbackTable:['ctlslide5.finishon'] = 1;

   // set everything else to skip, so the back button will be disabled
   pWizardInfo->callbackTable:['ctlslide0.skip'] = 1;
   pWizardInfo->callbackTable:['ctlslide1.skip'] = 1;
   pWizardInfo->callbackTable:['ctlslide2.skip'] = 1;
   pWizardInfo->callbackTable:['ctlslide4.skip'] = 1;
}

// end Wizard Callbacks

// Slide 0 - Wizard Menu

static int lmw_menu_shown()
{
   int lic_type = _LicenseType();

   int tab_index=4;
   if (lic_type == LICENSE_TYPE_NONE) {
      // figure out what is visible
      ctls0_install_license_file.p_value = 1;
      ctls0_request_trial.p_visible = true;
      ctls0_purchase_lic.p_visible = true;
      ctls0_request_license_file.p_visible = true;
      ctls0_renew.p_visible = false;
      ctls0_install_license_file.p_visible = true;
      ctls0_nag.p_visible = false;
      ctls0_continue.p_visible = false;

      // what text do we display?
      ctls0_title.p_caption = 'No License Found';
      ctls0_info.p_caption = 'If you do not have a license, you can request a Trial License or purchase a license.  To install a Full or Trial License, select "Install a license file".  If you have already purchased a license and do not have a license file, select "Request a license file for a purchased product".';

      // shift radio buttons appropriately
      y := ctls0_info.p_y + ctls0_info.p_height + 120;


      ctls0_install_license_file.p_y = y;
      y += ctls0_install_license_file.p_height + 120;
      ctls0_install_license_file.p_tab_index=tab_index++;


      ctls0_request_trial.p_y = y;
      y += ctls0_request_trial.p_height + 120;
      ctls0_request_trial.p_tab_index=tab_index++;

      ctls0_request_license_file.p_y=y;
      y += ctls0_request_license_file.p_height + 120;
      ctls0_request_license_file.p_tab_index=tab_index++;

      if (ctls0_use_license_server.p_visible) {
         ctls0_use_license_server.p_y = y;
         y += ctls0_use_license_server.p_height + 120;
         ctls0_use_license_server.p_tab_index=tab_index++;
      }


      ctls0_purchase_lic.p_y = y;
      y += ctls0_purchase_lic.p_height + 120;
      ctls0_purchase_lic.p_tab_index=tab_index++;


#if 0
      ctls0_request_trial.p_y = y;
      y += ctls0_request_trial.p_height + 120;
      ctls0_request_trial.p_tab_index=tab_index++;

      ctls0_purchase_lic.p_y = y;
      y += ctls0_purchase_lic.p_height + 120;
      ctls0_purchase_lic.p_tab_index=tab_index++;

      if (ctls0_use_license_server.p_visible) {
         ctls0_use_license_server.p_y = y;
         y += ctls0_use_license_server.p_height + 120;
         ctls0_use_license_server.p_tab_index=tab_index++;
      }

      ctls0_request_license_file.p_y=y;
      y += ctls0_request_license_file.p_height + 120;
      ctls0_request_license_file.p_tab_index=tab_index++;

      ctls0_install_license_file.p_y = y;
      ctls0_install_license_file.p_tab_index=tab_index++;
#endif

   } else if (lic_type == LICENSE_TYPE_TRIAL) {
      long days_left = _fnpLastLicenseExpiresInDays();
      // figure out what is visible
      ctls0_request_trial.p_visible = false;
      ctls0_purchase_lic.p_value = 1;
      ctls0_purchase_lic.p_visible = true;
      ctls0_renew.p_visible = false;
      ctls0_install_license_file.p_visible = true;
      ctls0_nag.p_visible = false;
      ctls0_request_license_file.p_visible = true;

      if (!gInvokedFromMenu) {
         ctls0_continue.p_visible = true;
         ctls0_continue.p_caption = '&Continue current trial';
         ctls0_continue.p_value = 1;
      } else {
         ctls0_continue.p_visible = false;
      }

      // what text do we display?
      ctls0_title.p_caption = 'Trial License Found';
      ctls0_info.p_caption = 'Your trial expires in 'days_left' days ('_fnpLastLicenseExpiresDate()').  ':+
                             'You can purchase a license or ':+
                             'enter a file if you already have one.';

      ctls0_info.p_auto_size=false;
      ctls0_info.p_width= ctls0_info.p_parent.p_width-ctls0_info.p_x*2;
      ctls0_info.p_auto_size=true;

      // shift radio buttons appropriately
      y := ctls0_info.p_y + ctls0_info.p_height + 120+60;
      if (ctls0_continue.p_visible) {
         ctls0_continue.p_y = y;
         y += ctls0_continue.p_height + 120;
         ctls0_continue.p_tab_index=tab_index++;
      }
      ctls0_install_license_file.p_y = y;
      y += ctls0_install_license_file.p_height + 120;
      ctls0_install_license_file.p_tab_index=tab_index++;

      ctls0_request_license_file.p_y = y;
      y += ctls0_request_license_file.p_height + 120;
      ctls0_request_license_file.p_tab_index=tab_index++;

      if (ctls0_use_license_server.p_visible) {
         ctls0_use_license_server.p_y = y;
         y += ctls0_use_license_server.p_height + 120;
         ctls0_use_license_server.p_tab_index=tab_index++;
      }

      ctls0_purchase_lic.p_y = y;
      y += ctls0_purchase_lic.p_height + 120;
      ctls0_purchase_lic.p_tab_index=tab_index++;

#if 0
      ctls0_request_license_file.p_y = y;
      y += ctls0_request_license_file.p_height + 120;
      ctls0_request_license_file.p_tab_index=tab_index++;

      ctls0_install_license_file.p_y = y;
      y += ctls0_install_license_file.p_height + 120;
      ctls0_install_license_file.p_tab_index=tab_index++;
#endif
      if (ctls0_continue.p_value) enable_continue_buttons();
   } else if (lic_type == LICENSE_TYPE_SUBSCRIPTION) {
      long days_left = _fnpLastLicenseExpiresInDays();
      // figure out what is visible
      ctls0_request_trial.p_visible = false;
      ctls0_purchase_lic.p_visible = false;
      ctls0_renew.p_visible = true;
      ctls0_renew.p_value = 1;
      ctls0_install_license_file.p_visible = true;
      ctls0_request_license_file.p_visible = false;
      if (!gInvokedFromMenu) {
         ctls0_nag.p_visible = true;
         ctls0_continue.p_visible = true;
         ctls0_continue.p_caption = '&Continue current subscription';
         ctls0_continue.p_value = 1;
      } else {
         ctls0_nag.p_visible = false;
         ctls0_continue.p_visible = false;
      }

      // what text do we display?
      ctls0_title.p_caption = 'License Found';
      ctls0_info.p_caption = 'Your subscription expires in 'days_left' days ('_fnpLastLicenseExpiresDate()').  ':+
                             'Use this wizard to install a license or ':+ 'renew your subscription.  ':+
                             'Hit Cancel to close.';

      ctls0_info.p_auto_size=false;
      ctls0_info.p_width= ctls0_info.p_parent.p_width-ctls0_info.p_x*2;
      ctls0_info.p_auto_size=true;

      ctls0_info.p_auto_size=false;
      ctls0_info.p_width= ctls0_info.p_parent.p_width-ctls0_info.p_x*2;
      ctls0_info.p_auto_size=true;

      // shift radio buttons appropriately
      y := ctls0_info.p_y + ctls0_info.p_height + 120+60;
      if (ctls0_continue.p_visible) {
         ctls0_continue.p_y = y;
         y += ctls0_continue.p_height + 120;
         ctls0_continue.p_tab_index=tab_index++;
      }
      ctls0_install_license_file.p_y = y;
      y += ctls0_install_license_file.p_height + 120;
      ctls0_install_license_file.p_tab_index=tab_index++;

      ctls0_renew.p_y = y;
      y += ctls0_renew.p_height + 120;
      ctls0_renew.p_tab_index=tab_index++;

      if (ctls0_use_license_server.p_visible) {
         ctls0_use_license_server.p_y = y;
         y += ctls0_use_license_server.p_height + 120;
         ctls0_use_license_server.p_tab_index=tab_index++;
      }

      if (ctls0_continue.p_value) {
         enable_continue_buttons();
      }
   } else {                                                 // everything else
      // figure out what is visible
      ctls0_request_trial.p_visible = false;
      ctls0_purchase_lic.p_visible = false;
      ctls0_renew.p_visible = false;
      ctls0_install_license_file.p_value = 1;
      ctls0_install_license_file.p_visible = true;

      ctls0_request_license_file.p_visible = true;
      ctls0_nag.p_visible = false;
      ctls0_continue.p_visible = false;

      // what text do we display?
      ctls0_title.p_caption = 'License Found';
      ctls0_info.p_caption = 'This product is already licensed.';

      // shift checkboxes appropriately
      y := ctls0_info.p_y + ctls0_info.p_height + 120;

      ctls0_install_license_file.p_y = y;
      y += ctls0_install_license_file.p_height + 120;
      ctls0_install_license_file.p_tab_index=tab_index++;

      ctls0_request_license_file.p_y = y;
      y += ctls0_request_license_file.p_height + 120;
      ctls0_request_license_file.p_tab_index=tab_index++;

      if (ctls0_use_license_server.p_visible) {
         ctls0_use_license_server.p_y = y;
         y += ctls0_use_license_server.p_height + 120;
         ctls0_use_license_server.p_tab_index=tab_index++;
      }

   }

   return 0;
}
static _str getLicenseFilePath(_str &licenseFilename=null,boolean &usingAppDataPath=false,_str lm_license_name=LMW_LICENSE_NAME) {
   usingAppDataPath=false;
   _str path;
   path=editor_name('p');
   licenseFilename=path:+lm_license_name;
#if __UNIX__ && !__MACOSX__
   return(path);
#else
   /*
      Check if there is a license file in the win directory.  If there
      is, we must overwrite that one. Otherwise, we will find the wrong
      license file.
   */
   if (file_exists(licenseFilename)) {
      return(path);
   }
   usingAppDataPath=true;
   path=_LicenseAppDataPath(true);
   licenseFilename=path:+lm_license_name;
   return(path);
#endif
}
static _str mktemp_license_file(int start=1,_str Extension='')
{
   _str path=_temp_path();
   int i,pid=getpid();
   int buf_id;
   for (i=start; i<=1000 ; ++i) {
      buf_id=0;
      if (p_HasBuffer) {
         buf_id=p_buf_id;
      }
      _str name=path:+'slickedit':+i:+LWM_LICENSE_EXT;
      if ( file_match('-p 'name,1)=='' ) {
         return(name);
      }
   }
   return('');
}
static int writeTempLicenseFile(_str &temp_filename,_str licenseFileText) {
   int temp_fh= -1;
   int i;
   for (i=0;i<100;++i) {
      temp_filename=mktemp_license_file();
      temp_fh=_file_open(temp_filename,1);
      if (temp_fh>=0) {
         break;
      }
   }
   if (temp_fh<0) return(temp_fh);
   if (length(licenseFileText)) {
      int len=_file_write(temp_fh,licenseFileText);
      if (len!=length(licenseFileText)) {
         len=INSUFFICIENT_DISK_SPACE_RC;
      }
      if (len<0) {
         _file_close(temp_fh);
         _file_delete(temp_filename);
         return(len);
      }
      status=_file_close(temp_fh);
      if (status<0) {
         _file_delete(temp_filename);
         return(status);
      }
   }
   return(0);
}
static int elevatedWriteLicenseFile(boolean &elevationSupport,_str srcLicenseFilename,_str dest_filename) {
   int status=1;
   elevationSupport=false;
   //say('elevationSupport=true');
   if(!__UNIX__ && NTGetElevationType() != 0 && !NTIsElevated()) {
      elevationSupport=true;
      // Use vsFileMgr.exe to elevate and copy the temp file to the license path
      _str exe = editor_name('p');
      _maybe_append_filesep(exe);
      exe = exe:+"vsFileMgr.exe";
      _str params = "/C "maybe_quote_filename(srcLicenseFilename)" "maybe_quote_filename(dest_filename);
      int exitCode;
      int shell_status = NTShellExecuteEx("runas",exe,params,"",exitCode);
      //_message_box('shell_status='shell_status' exitCode='exitCode);
      status = ( shell_status != 0 ) ? shell_status : exitCode;
   }
   return(status);
}
#if 0
static boolean canWriteLicenseFile() {
   // create a temp file in All Users\Application Data\...
   _str path=getLicenseFilePath();
   _str filename=path:+TEMP_LIC_FILENAME;
   delete_file(filename);
#if __PCDOS__
   make_path(path);
#endif
   int fh=_file_open(filename,1);
   if (fh>=0) _file_close(fh);
   delete_file(filename);
   boolean can= fh>=0;

   boolean elevationSupport=false;
   if (!can) {
      // Try again with elevated priveledges
      
      // Copy temp file to destination license path
      int status=elevatedWriteLicenseFile(elevationSupport,"",filename);
      if (elevationSupport && !status) {
         can=true;
      }
#if !__UNIX__
      // Try writing to  
#endif

   }

   if (!can) {
      _str programName=editor_name('p'):+'vslicenseproduct';

      boolean cant_write_config_files=_default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
      if (cant_write_config_files) {
      } else {
         _message_box(
   #if __UNIX__
            "You do not have write permissions to the directory:\n\n"path"\n\n":+
            "Start an xterm and run '"programName"' with root permissions. To ":+
            "do this type 'sudo "maybe_quote_filename(programName)"' or type 'su<enter>' and enter your root password.\n\n":+
            "After successfully completing this, cancel the license manager dialog"
   #else
            nls("Failed to write file '%s1'. Check that you can manually write to this file with any contents.", filename):+
            " Correct this problem and try again."
   
   #endif
            );
      }
   }
   return(can);
}
#endif
static int lmw_menu_next()
{
   // see if the nag checkbox is visible and note its value
   if (ctls0_nag.p_visible) {
      def_prompt_renew_sub = (ctls0_nag.p_value == 0);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // we choose our path based on the selection of this first radio button
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   if (ctls0_request_trial.p_value) {
      // path = slide0 -> slide1 -> slide2 -> finish (no registration)
      activationPath = ACTPATH_TRIAL;

      pWizardInfo->callbackTable:['ctlslide1.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide2.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide4.skip'] = 0;

      pWizardInfo->callbackTable:['ctlslide3.skip'] = 1;
      pWizardInfo->callbackTable:['ctlslide5.skip'] = 1;
   } else if (ctls0_purchase_lic.p_value) {
      // path = slide0 -> slide1 -> slide2 -> finish (no registration)
      activationPath = ACTPATH_PURCHASE;

      pWizardInfo->callbackTable:['ctlslide1.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide2.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide4.skip'] = 0;

      pWizardInfo->callbackTable:['ctlslide3.skip'] = 1;
      pWizardInfo->callbackTable:['ctlslide5.skip'] = 1;
   } else if (ctls0_renew.p_value) {
      // path = slide0 -> slide1 -> slide2 -> finish (no registration)
      activationPath = ACTPATH_RENEW;

      pWizardInfo->callbackTable:['ctlslide1.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide2.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide4.skip'] = 0;

      pWizardInfo->callbackTable:['ctlslide3.skip'] = 1;
      pWizardInfo->callbackTable:['ctlslide5.skip'] = 1;
   } else if (ctls0_install_license_file.p_value) {
      // path = slide0 -> slide2 -> finish (with possible registration)
      activationPath = ACTPATH_INSTALL_LICENSE_FILE;

      pWizardInfo->callbackTable:['ctlslide2.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide4.skip'] = 0;

      pWizardInfo->callbackTable:['ctlslide1.skip'] = 1;
      pWizardInfo->callbackTable:['ctlslide3.skip'] = 1;
      pWizardInfo->callbackTable:['ctlslide5.skip'] = 1;
   } else if (ctls0_request_license_file.p_value) {
      // path = slide0 -> slide1 -> slide2 -> finish (no registration)
      activationPath = ACTPATH_REQUEST_LICENSE_FILE;
      pWizardInfo->callbackTable:['ctlslide1.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide2.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide4.skip'] = 0;

      pWizardInfo->callbackTable:['ctlslide3.skip'] = 1;
      pWizardInfo->callbackTable:['ctlslide5.skip'] = 1;
   } else if (ctls0_use_license_server.p_value) {
      // path = slide0 -> slide2 -> slide4 -> finish
      activationPath = ACTPATH_USE_LICENSE_SERVER;

      pWizardInfo->callbackTable:['ctlslide2.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide4.skip'] = 0;

      pWizardInfo->callbackTable:['ctlslide1.skip'] = 1;
      pWizardInfo->callbackTable:['ctlslide3.skip'] = 1;
      pWizardInfo->callbackTable:['ctlslide5.skip'] = 1;
   } else if (!ctls0_continue.p_value) {
      // This should never happen
      _message_box("You must select an activity.");
      return 1;
   }

   return 0;
}

// end Slide 0 - Wizard Menu

// Slide 1 - Launch Browser and Request License

static int lmw_launch_browser_shown()
{
   // use our activation path to determine our text
   if (activationPath == ACTPATH_TRIAL) {
      ctls1_title.p_caption = 'Request a Trial License';
      ctls1_url.p_text= _GenerateUrl("trial");
      ctls1_url.p_user= _GenerateUrl("trial",0);
   } else if (activationPath == ACTPATH_PURCHASE) {
      ctls1_title.p_caption = 'Purchase a License';
      ctls1_url.p_text= _GenerateUrl("buy");
      ctls1_url.p_user= _GenerateUrl("buy",0);
   } else if (activationPath == ACTPATH_RENEW) {
      ctls1_title.p_caption = 'Renew a Subscription';
      ctls1_url.p_text= _GenerateUrl("renew");
      ctls1_url.p_user= _GenerateUrl("renew",0);
   } else if (activationPath == ACTPATH_REQUEST_LICENSE_FILE) {
      ctls1_title.p_caption = 'Request a License File for a purchased product';
      ctls1_url.p_text= _GenerateUrl("license");
      ctls1_url.p_user= _GenerateUrl("license",0);
   } else {
      // something is bad and wrong...
   }

   return 0;
}
static int lmw_launch_browser_next()
{
   if (ctls1_launch.p_value) {            // launch default web browser
      _str url = ctls1_url.p_user;
      int status=p_window_id.goto_url(url);
      if (status) {
         ctls1_url._set_sel(1,length(ctls1_url.p_text));
         ctls1_url.copy_to_clipboard();
         _message_box('Automatically running your Web Browser failed.  The URL below has been copied to the clipboard.  Paste it into your Web Browser');
         return(0);
      }
   } else if (ctls1_copy.p_value) {       // copy url to clipboard
      ctls1_url._set_sel(1,length(ctls1_url.p_text));
      ctls1_url.copy_to_clipboard();
   } else {
      // This should never happen
      _message_box("You must select a method to continue.");
      return 1;
   }

   return 0;
}

// end Slide 1 - Launch Browser and Request License

// Slide 2 - Enter License

static int lmw_install_file_shown()
{
   ctls2_info_1.p_visible=true;
   ctls2_browse.p_visible=true;
   extraMsg := "\n\n":+'If your browser did not launch, click "Back" to manually copy the ':+
               'URL into your browser.':+"\n\n":+
               'Browse for the license file and click "Next".';
   // use the path to determine how this form should look
   exampleMsg := "License file:";
               ctls2_info_1.p_caption = "Follow the instructions on the web page to obtain a license file ":+
                                        "."extraMsg;
   if (activationPath == ACTPATH_TRIAL) {
      ctls2_title.p_caption = 'Enter a Trial License File';
   } else if (activationPath == ACTPATH_REQUEST_LICENSE_FILE) {
      ctls2_title.p_caption = 'Install a License File';
   } else if (activationPath == ACTPATH_PURCHASE || activationPath == ACTPATH_RENEW) {
      ctls2_title.p_caption = 'Install a License File';
   } else if (activationPath == ACTPATH_INSTALL_LICENSE_FILE) {
      ctls2_title.p_caption = 'Install License File';
   } else if (activationPath == ACTPATH_USE_LICENSE_SERVER) {
      ctls2_title.p_caption = 'Use License Server';
      ctls2_info_1.p_caption="Before continuing, make sure your server is up and running.  If you have ":+
                             "a problem, verify your server and port with your administrator.";
      exampleMsg="License server (Example: ":+LICENSE_SERVER_PORT:+"@myserver):";
      ctls2_browse.p_visible=false;

      _str server_name = _retrieve_value("_license_wizard_form.servername");
      if (server_name != '') {
         ctls2_license_file.p_text = server_name;
      }

   } else {
      // should never happen...
   }

   ctls2_info_1.p_caption=ctls2_info_1.p_caption:+"\n\n":+exampleMsg;

   ctls2_info_1.p_auto_size=false;
   ctls2_info_1.p_width= ctls2_info_1.p_parent.p_width-ctls2_info_1.p_x*2;
   ctls2_info_1.p_auto_size=true;
   y := ctls2_info_1.p_y + ctls2_info_1.p_height + 60;
   ctls2_license_file.p_y = y;
   y += ctls2_license_file.p_height + 60;

   ctls2_browse.p_y=y;

   return 0;
}

static int lmw_install_file_back()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();

   // use the path to determine how this form should look
   if (activationPath == ACTPATH_TRIAL || activationPath == ACTPATH_PURCHASE) {
      // we want to go back to the browser launch screen
      pWizardInfo->callbackTable:['ctlslide0.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide1.skip'] = 0;
//    pWizardInfo->callbackTable:['ctlslide2.skip'] = 0;
   } else {
      // set everything to skip except for the beginning slide
      pWizardInfo->callbackTable:['ctlslide0.skip'] = 0;
      pWizardInfo->callbackTable:['ctlslide1.skip'] = 1;
//    pWizardInfo->callbackTable:['ctlslide2.skip'] = 1;
   }

   return 0;
}
static boolean ginstall_license_file_failed;
static _str ginstall_license_file_dest;
static boolean ginstall_license_file_probably_need_root_access;

enum NT_ACCESS_MODE
{
    NT_NOT_USED_ACCESS = 0,
    NT_GRANT_ACCESS,
    NT_SET_ACCESS,
    NT_DENY_ACCESS,
    NT_REVOKE_ACCESS,
    NT_SET_AUDIT_SUCCESS,
    NT_SET_AUDIT_FAILURE
};
enum NT_SE_OBJECT_TYPE
{
    NT_SE_UNKNOWN_OBJECT_TYPE = 0,
    NT_SE_FILE_OBJECT,
    NT_SE_SERVICE,
    NT_SE_PRINTER,
    NT_SE_REGISTRY_KEY,
    NT_SE_LMSHARE,
    NT_SE_KERNEL_OBJECT,
    NT_SE_WINDOW_OBJECT,
    NT_SE_DS_OBJECT,
    NT_SE_DS_OBJECT_ALL,
    NT_SE_PROVIDER_DEFINED_OBJECT,
    NT_SE_WMIGUID_OBJECT,
    NT_SE_REGISTRY_WOW64_32KEY
};
#define NT_DELETE                           (0x00010000)
#define NT_READ_CONTROL                     (0x00020000)
#define NT_WRITE_DAC                        (0x00040000)
#define NT_WRITE_OWNER                      (0x00080000)
#define NT_SYNCHRONIZE                      (0x00100000)

#define NT_STANDARD_RIGHTS_REQUIRED         (0x000F0000)

#define NT_STANDARD_RIGHTS_READ             (NT_READ_CONTROL)
#define NT_STANDARD_RIGHTS_WRITE            (NT_READ_CONTROL)
#define NT_STANDARD_RIGHTS_EXECUTE          (NT_READ_CONTROL)

#define NT_STANDARD_RIGHTS_ALL              (0x001F0000)

#define NT_SPECIFIC_RIGHTS_ALL              (0x0000FFFF)

// AccessSystemAcl access type

#define NT_ACCESS_SYSTEM_SECURITY           (0x01000000)

// MaximumAllowed access type

#define NT_MAXIMUM_ALLOWED                  (0x02000000)

#define NT_GENERIC_READ                     (0x80000000)
#define NT_GENERIC_WRITE                    (0x40000000)
#define NT_GENERIC_EXECUTE                  (0x20000000)
#define NT_GENERIC_ALL                      (0x10000000)

static int lmw_install_file_next()
{
   // save our current license type and pip id
   getPipLicenseInfo(auto oldLicenseType, auto nOfUsers);
   oldPipId := getPipUserId();

   ginstall_license_file_failed=true;
   ginstall_license_file_probably_need_root_access=false;
   _str srcLicenseFilename = ctls2_license_file.p_text;
   _str licenseFilename;
   boolean usingAppDataPath;
   _str path=getLicenseFilePath(licenseFilename,usingAppDataPath);
   ginstall_license_file_dest=licenseFilename;
   if (ginstall_license_file_src_is_temp_file) {
      delete_file(ginstall_license_file_src);
      ginstall_license_file_src_is_temp_file=false;
   }
   boolean source_and_dest_same=false;
   boolean borrowed=(_LicenseType() == LICENSE_TYPE_BORROW);
   int lic_type;
   if (activationPath==ACTPATH_USE_LICENSE_SERVER) {
      parse srcLicenseFilename with port '@' server;
      if (server=='') {
         _message_box("Prefix server with '@' (example "LICENSE_SERVER_PORT"@myserver)");
         return(1);
      }
      #ifdef USE_FLEX_LICENSING
         _str licenseFileText="SERVER "server" ANY "port"\nVENDOR vsflex\nUSE_SERVER\n";
      #else
         _str licenseFileText="<Servers>\n    <Server name=\""srcLicenseFilename"\" />\n</Servers>\n";
      #endif
      mou_set_pointer(MP_HOUR_GLASS);
      disable_all_wizard_buttons(2);

      lic_type=fnpGetLicenseFileType(srcLicenseFilename);
      restore_callback_table(true);
      mou_set_pointer(MP_DEFAULT);
      if (lic_type==LICENSE_TYPE_NONE) {
         _message_box("Unable to checkout license from license server\n\n"_fnpLastErrorString());
         return(1);
      }

      // SUCCESS, remember this for next time
      _append_retrieve(0, srcLicenseFilename, "_license_wizard_form.servername");
      /*
         Not worth to support this code path. Just use license file.

      boolean cant_write_config_files=_default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
      if (!file_exists(ginstall_license_file_dest) &&
          (_LicenseType()==LICENSE_TYPE_NONE || _LicenseType()==LICENSE_TYPE_CONCURRENT)
          && __UNIX__ && !cant_write_config_files) {
         _message_box("NOT going to use license file case");
         set_env("VSFLEX_LICENSE_FILE",ginstall_license_file_src);
      }
      */
      _str temp_filename;
      status=writeTempLicenseFile(temp_filename,licenseFileText);
      if (status) {
         _message_box("Unable to create temp license file");
         return(1);
      }
      ginstall_license_file_src_is_temp_file=true;
      srcLicenseFilename=ginstall_license_file_src=temp_filename;
   } else {
      srcLicenseFilename = _unquote_filename(srcLicenseFilename);
      if (file_eq(absolute(srcLicenseFilename),absolute(ginstall_license_file_dest))) {
         source_and_dest_same=true;
      //   _message_box("Source and destination are the same file.  The license file you have chosen is already installed at the destination location.");
      //   return(1);
      }
      ginstall_license_file_src_is_temp_file=false;
      ginstall_license_file_src=srcLicenseFilename;

      if (licenseFileInvalid(srcLicenseFilename)) {
         return(1);
      }
      lic_type=fnpGetLicenseFileType(srcLicenseFilename);
      if (lic_type==LICENSE_TYPE_NONE) {
         _message_box("This license file is not valid.  Make sure this license is for the correct product and is not a license that has expired.");
         return(1);
      }
      if (lic_type==LICENSE_TYPE_CONCURRENT) {
#ifdef USE_FLEX_LICENSING
         _message_box("This license file is for a concurrent license. You need to set the VSFLEX_LICENSE_FILE environment variable to your license server.");
         return(1);
#endif
      }
   }

   status=0;
   _str bak='';
   if (!source_and_dest_same) {
      if (file_exists(licenseFilename)) {
         // Try to make a back
         int i;
         for (i=1;;++i) {
            if (i>=100) {
               bak='';
               break;
            }
            bak=licenseFilename'.bak'i;
            if (!file_exists(bak)) {
               // Use move to preserve and permission changes
               int status=_file_move(bak,licenseFilename);
               if (status) {
                  // Blow off the error here.  User has got emails with license files.
                  // It's pretty rare that the backup will fail but the the write below
                  // success (i.e. the file will never be overwritten).
                  copy_file(licenseFilename,bak);
               }
               break;
            }
         }
      }

      if (!path_exists(path)) {
         status = make_path(path);//say('no make path');//
#if __MACOSX__
         if (!status) {
            // set permissions on app data path
            status = _chmod("u+rw,g+rw,o+rw " maybe_quote_filename(path));

            // may need to fix parent path too
            if (!status && (pos('/Library/Application Support/SlickEdit/', path, 1) == 1)) {
               _str parent = _parent_path(path);
               status = _chmod("u+rw,g+rw,o+rw " maybe_quote_filename(parent));
            }
         }
#endif
      }

      status = copy_file(srcLicenseFilename,licenseFilename);
#if __UNIX__
      if (!status) {
          #if __MACOSX__
          _chmod("u+rw,g+rw,o+rw " maybe_quote_filename(licenseFilename));
          #else
          _chmod("u+rw,g+r,o+r " maybe_quote_filename(licenseFilename));
          #endif
      }
#endif
   }
   if (status<0) {
      // Vista: Try writing a temp file and copying it with elevated priveledges
      boolean elevationSupport;
      int status=elevatedWriteLicenseFile(elevationSupport,srcLicenseFilename,licenseFilename);
      //elevationSupport=false;status=ACCESS_DENIED_RC;
      if (!elevationSupport || status) {
         boolean cant_write_config_files=_default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
         //_str manualCopyMsg='';
         //manualCopyMsg=nls("You need to manually copy the file:\n\n%s1\n\nto\n\n%s2",srcLicenseFilename,licenseFilename);
         if (cant_write_config_files || elevationSupport || !__UNIX__) {
            //_message_box(manualCopyMsg);
         } else {
            ginstall_license_file_probably_need_root_access=true;

            /*_message_box(
               "You do not have write permissions to the directory:\n\n"path"\n\n":+
               "Start an xterm and run '"programName"' with root permissions. To ":+
               "do this type 'sudo "maybe_quote_filename(programName)"' or type 'su<enter>' and enter your root password.\n\n":+
               "After successfully completing this, cancel the license manager dialog"
               );*/
         }
         WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
         pWizardInfo->callbackTable:['ctlslide3.skip']=0;
         pWizardInfo->callbackTable:['ctlslide4.skip']=0;
         /*
            Since it is unlikely that we ran out of diskspace,
            delete the backup because it most likely couldn't
            be replace due to permissions.
         */
         if (bak!='') {
            delete_file(bak);
         }
         return(0);
      }
   }
#if __PCDOS__
   if (usingAppDataPath) {
      int dwRes=NTAddAceToObjectsSecurityDescriptor(
         licenseFilename,NT_SE_FILE_OBJECT,
         "Users",NT_GENERIC_ALL,
         NT_SET_ACCESS,
         0);
   }
#endif
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   pWizardInfo->callbackTable:['ctlslide3.skip']=1;
   if (lic_type == LICENSE_TYPE_BETA || lic_type == LICENSE_TYPE_TRIAL) {
      // beta or trial - enable finish button
      pWizardInfo -> callbackTable:['ctlslide4.skip']= 0;
      pWizardInfo -> callbackTable:['ctlslide5.skip']= 1;
   } else {
      // full or nfr or subscription
      pWizardInfo -> callbackTable:['ctlslide4.skip']= 1;
      pWizardInfo -> callbackTable:['ctlslide5.skip']= 0;
   }
   ginstall_license_file_failed=false;

   // prompt to return borrowed license 
   if (borrowed) {
      if (_fnpIsLicenseValid()) {
         result=_message_box("Currently using a borrowed license from license server.  Return license now?", '', MB_YESNO|MB_ICONQUESTION);
      } else {
         result=IDYES;
      }
      
      if (result==IDYES) {
         _str license_server_name = _LicenseServerName();
         if (license_server_name == '') {
            license_server_name = _retrieve_value("_license_wizard_form.servername");
         }
         if (license_server_name != '') {
            int result = _LicenseReturn(license_server_name);
         }
      }
   }

   // we made a change to our license - log it!
   _pip_log_license_event(oldLicenseType, oldPipId);

   return 0;
}

// end Slide 2 - Enter License Key

struct FNP_LICENSE_RECORD {
   _str m_productID;
   _str m_entitlementID;
   _str m_fulfillmentID;
   _str m_expDate;
}

// Slide 3 - Error installing License File

static int lmw_error_shown()
{
   int total_y=ctlslide3.p_height;
   ctls3_error.p_height=ctlslide3.p_height-ctls3_error.p_y-
      ctlslide3._top_height()-ctlslide3._bottom_height();
   ctls3_error.p_visible = true;
#if __UNIX__
   ctls3_error.p_border_style=BDS_FIXED_SINGLE;
#else
   ctls3_error.p_border_style=BDS_NONE;
#endif
   ctls3_error._minihtml_UseDialogFont();
   if(ginstall_license_file_probably_need_root_access || __UNIX__) {
      _str more_msg;more_msg='';
      if (activationPath==ACTPATH_USE_LICENSE_SERVER && !file_exists(ginstall_license_file_dest)) {
#ifdef USE_FLEX_LICENSING
         more_msg="<br><br>If you cannot get root access, exit and set the ":+
            "VSFLEX_LICENSE_FILE environment variable to 'port@hostname' and restart<br></br>";
#endif 
      }

      ctls3_error.p_text= "<br><b>File copy failed</b>. Start a terminal with root permissions (<b>su</b> or <b>sudo</b>) and execute the file copy command below:<br><br>":+
         "cp "maybe_quote_filename(ginstall_license_file_src)"<br>":+
         maybe_quote_filename(ginstall_license_file_dest)"<br><a href='cp'>copy command to clipboard</a><br><br>":+
         more_msg:+
         "For assistance, contact SlickEdit product support.<br><br>":+
         "1.919.473.0100<br>":+
         "www.slickedit.com/support<br>";

#if 0
      ctls3_error.p_text = "<b>File copy failed</b>. Start an terminal with root permissions and manually copy the file:<br><br>":+
         ginstall_license_file_src"<br><a href='src'>copy filename to clipboard</a><br><br>to<br><br>":+
         ginstall_license_file_dest"<br><a href='dest'>copy filename to clipboard</a><br><br>":+
         "For assistance, contact SlickEdit product support.<br><br>":+
         "1.919.473.0100<br>":+
         "www.slickedit.com/support<br>";
#endif
   } else {
      ctls3_error.p_text = "<b>File copy failed</b>. You need to manually copy the file:<br><br>":+
         ginstall_license_file_src"<br><a href='src'>copy filename to clipboard</a><br><br>to<br><br>":+
         ginstall_license_file_dest"<br><a href='dest'>copy filename to clipboard</a><br><br>":+
         "For assistance, contact SlickEdit product support.<br><br>":+
         "1.919.473.0100<br>":+
         "www.slickedit.com/support<br>";
   }

   return 0;
}
static _str get_file_text(_str filename) {
   int temp_wid,orig_wid;
   int status=_open_temp_view(filename,temp_wid,orig_wid);
   if (status) return("");
   _str result=get_text(p_buf_size,0);
   _delete_temp_view(temp_wid);
   p_window_id=orig_wid;
   return(result);
}
static int lmw_error_next() {
   /* 
      Verify that the user replaced the license file.
      Either, the src license file must be deleted or the
      dest license file contents much match the src license
      file contents.
   */ 
   if (file_exists(ginstall_license_file_src)) {
      _str text1=get_file_text(ginstall_license_file_src);
      _str text2=get_file_text(ginstall_license_file_dest);
      if (text1!=text2) {
         _message_box("Please perform the file copy operation");
         return(1);
      }
   }


   // the registration screen is last - we only show it when we have 
   // FULL or NFR versions
   fnpCheckoutLicense();  // Recheckout the license.
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   int lic_type = _LicenseType();
   if (lic_type==LICENSE_TYPE_NONE) {
      _message_box("Licensing failed");
      return(1);
   }
   if (lic_type == LICENSE_TYPE_BETA || lic_type == LICENSE_TYPE_TRIAL) {
      // beta or trial - enable finish button
      pWizardInfo -> callbackTable:['ctlslide2.skip'] = 1;
      pWizardInfo -> callbackTable:['ctlslide4.finishon'] = 1;
   } else {
      // full or nfr or subscription or none
      lmw_finish_successfully();
   }

   return(0);
}

// end Slide 3 - Error installing License File

// Slide 4 - Success Installing License File

static int lmw_success_shown()
{
   //ctls4_info_1.p_visible=false;
   ctls4_info_1.p_visible = true;
   ctls4_info_1.p_font_bold = false;
   ctls4_info_1.p_caption = 'License validated';

   // the registration screen is last - we only show it when we have 
   // FULL or NFR versions
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   fnpCheckoutLicense();  // Recheckout the license.  
   int lic_type = _LicenseType();
   if (lic_type == LICENSE_TYPE_BETA || lic_type == LICENSE_TYPE_TRIAL) {
      // beta or trial - enable finish button
      pWizardInfo -> callbackTable:['ctlslide2.skip'] = 1;
      pWizardInfo -> callbackTable:['ctlslide4.finishon'] = 1;
   } else {
      // full or nfr or subscription
      lmw_finish_successfully();
   }

   // now call the wizard to check on these buttons
   _WizardMaybeEnableButtons();

   return 0;
}

// end Slide 4 - Activation

// Slide 5 - Registration 

static int lmw_registration_shown()
{
   // text is based on which path we used to get here
   switch (activationPath) {
   case ACTPATH_TRIAL:
      ctls5_info_2.p_visible = false;
      ctls5_info_1.p_caption = 'License validated.';
      break;
   case ACTPATH_PURCHASE:
   case ACTPATH_INSTALL_LICENSE_FILE:
   case ACTPATH_REQUEST_LICENSE_FILE:
      // let's set up the registration mess
      ctls5_info_2.p_visible = true;
      ctls5_info_1.p_caption = 'License validated.';
      _WizardRenameNextButton('Register');

      ctls5_info_2._minihtml_UseDialogFont();

      text = "<p style=\"color:black\">\nRegister your product and...\n</p>\n";
      if (isEclipsePlugin()) {
         //text :+= "<li><div>Manage your product activations</div></li>\n";
         text :+= "<li><div>Renew your subscription</div></li>\n";
         text :+= "<li><div>Receive priority notification of updates and upgrades</div></li>\n";
         text :+= "<li><div>Manage your account information online</div></li>\n";
         text :+= "<li><div>View your web order history</div></li>\n";
         text :+= "<li><div>Download license files and installers</div></li>\n";
      } else {
         //text :+= "<li><div>Manage your product activations</div></li>\n";
         text :+= "<li><div>Receive priority notification of updates and upgrades</div></li>\n";
         text :+= "<li><div>Manage your account information online</div></li>\n";
         text :+= "<li><div>View your web order history</div></li>\n\n\n";
         text :+= "<li><div>Download license files and installers</div></li>\n";
         text :+= "<p style=\"color:green\">\n<b>Please note: Customers who have purchased Maintenance and Support service for their licensed products must register in order to obtain access to their upgrade.</b>\n</p>\n<p style=\"color:black\"></p>";
      }
      ctls5_info_2.p_text = text;

      break;
   case ACTPATH_REPAIR:
      ctls5_info_2.p_visible = false;
      ctls5_info_1.p_caption = 'Reactivation complete.';
      break;
   case ACTPATH_DEACTIVATE:
      ctls5_info_2.p_visible = false;
      ctls5_info_1.p_caption = 'Deactivation complete.';
      break;
   /*case ACTPATH_REQUEST_LICENSE_FILE:
      ctls5_title.p_caption = 'Install Full License File';
      ctls5_info_2.p_visible = false;
      ctls5_info_1.p_caption = 'After you have installed your license file, click "Finish".';
      break;*/
   }

   return 0;
}

static int lmw_registration_register()
{
   // oh man, what a hack - check if this is the next button or the finish button
   if (p_window_id == _find_control('ctlnext')) {
      wid := p_window_id;
      //say(wid.p_name);
   
      _str serial = _SerialNumber();
      _str version = _getVersion(false);
      _str trial = _trial();
      _str url = VSREG_URL;
      url = url'?serial='serial'&version='version;
      url = url'&trial='trial;
   
      if (url != null) {
         goto_url(url, true);
      }
   
      p_window_id = wid;
   
      return 1;
   }

   return 0;
}

// end Slide 5 - Registration 

void setupHashTable(typeless (&callback_table):[])
{
   callback_table:['finish']=lmw_finish;
   callback_table:['destroy']=lmw_destroy;

   // slide 0 - the menu screen
   callback_table:['ctlslide0.shown'] = lmw_menu_shown;
   callback_table:['ctlslide0.next'] = lmw_menu_next;
   callback_table:['ctlslide0.finishon'] = 0;
   callback_table:['ctlslide0.skip'] = 0;

   // slide 1 - launch browser 
   callback_table:['ctlslide1.next'] = lmw_launch_browser_next;
   callback_table:['ctlslide1.shown'] = lmw_launch_browser_shown;
   callback_table:['ctlslide1.back'] = lmw_return_to_beginning;
   callback_table:['ctlslide1.finishon'] = 0;
   callback_table:['ctlslide1.skip'] = 0;

   // slide 2 - enter license file
   callback_table:['ctlslide2.next'] = lmw_install_file_next;
   callback_table:['ctlslide2.shown'] = lmw_install_file_shown;
   callback_table:['ctlslide2.shownback'] = lmw_install_file_shown;
   callback_table:['ctlslide2.back'] = lmw_install_file_back;
   callback_table:['ctlslide2.finishon'] = 0;
   callback_table:['ctlslide2.skip'] = 0;

   // slide 3 - error
   callback_table:['ctlslide3.shown'] = lmw_error_shown;
   callback_table:['ctlslide3.next'] = lmw_error_next;
   callback_table:['ctlslide3.canceloff'] = 0;
   callback_table:['ctlslide3.finishon'] = 0;
   callback_table:['ctlslide3.skip'] = 0;

   // slide 4 - finish success
   callback_table:['ctlslide4.shown'] = lmw_success_shown;
   callback_table:['ctlslide4.canceloff'] = 1;
   callback_table:['ctlslide4.finishon'] = 1;
   callback_table:['ctlslide4.skip'] = 0;

   // slide 5 - registration
   callback_table:['ctlslide5.shown'] = lmw_registration_shown;
   callback_table:['ctlslide5.back'] = lmw_return_to_beginning;
   callback_table:['ctlslide5.next'] = lmw_registration_register;
   callback_table:['ctlslide5.canceloff'] = 1;
   callback_table:['ctlslide5.finishon'] = 1;
   callback_table:['ctlslide5.skip'] = 0;

   // slide 6 - bogus hidden screen to make the next button appear as Register
   callback_table:['ctlslide6.skip'] = 1;
}

static int LicenseWizard(boolean invokedFromMenu)
{
   _InitializeUrlInfo();

   gInvokedFromMenu = invokedFromMenu;
   ginstall_license_file_src_is_temp_file=false;

   WIZARD_INFO info;
   info.dialogCaption = 'SlickEdit License Manager';
   info.parentFormName = '_license_wizard_form';

   typeless callback_table:[];
   setupHashTable(callback_table);

   info.callbackTable = callback_table;

   status := _Wizard(&info);

   return status;
}

defeventtab _license_wizard_form;

void ctls0_renew.lbutton_up()
{
   if (ctls0_continue.p_visible && ctls0_renew.p_value) disable_continue_buttons();
}

void ctls0_purchase_lic.lbutton_up()
{
   if (ctls0_continue.p_visible && ctls0_purchase_lic.p_value) disable_continue_buttons();
}

void ctls0_continue.lbutton_up()
{
   // enable the finish button and disable the cancel button
   if (ctls0_continue.p_value) enable_continue_buttons();
}

void ctls0_install_license_file.lbutton_up()
{
   if (ctls0_continue.p_visible && ctls0_install_license_file.p_value) disable_continue_buttons();
}

void ctls0_request_license_file.lbutton_up()
{
   if (ctls0_continue.p_visible && ctls0_request_license_file.p_value) disable_continue_buttons();
}

enable_continue_buttons()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   // disable cancel
   pWizardInfo -> callbackTable:['ctlslide0.canceloff'] = 1;

   // enable finish
   pWizardInfo -> callbackTable:['ctlslide0.finishon'] = 1;

   // disable next
   pWizardInfo -> callbackTable:['ctlslide1.skip'] = 1;
   pWizardInfo -> callbackTable:['ctlslide2.skip'] = 1;
   pWizardInfo -> callbackTable:['ctlslide3.skip'] = 1;
   pWizardInfo -> callbackTable:['ctlslide4.skip'] = 1;
   pWizardInfo -> callbackTable:['ctlslide5.skip'] = 1;

   // now call the wizard to check on these buttons
   _WizardMaybeEnableButtons();
}

disable_continue_buttons()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   // enable cancel
   pWizardInfo -> callbackTable:['ctlslide0.canceloff'] = 0;

   // disable finish
   pWizardInfo -> callbackTable:['ctlslide0.finishon'] = 0;

   // disable next
   pWizardInfo -> callbackTable:['ctlslide4.skip'] = 0;

   // now call the wizard to check on these buttons
   _WizardMaybeEnableButtons();
}
static void cleanupLicenseFile() {
   top();
   int status=search('^-------','@r');
   if (!status) {
      deselect();select_line();top();select_line();delete_selection();
      top();
   }
}
static boolean licenseFileInvalid(_str licenseFilename) {
   if (!file_exists(licenseFilename)) {
      _message_box(nls("File '%s1' not found",licenseFilename));
      return(true);
   }
#ifdef USE_FLEX_LICENSING
   int temp_wid,orig_wid;
   status=_open_temp_view(licenseFilename,temp_wid,orig_wid);
   if (status) {
      _message_box(nls("Unable to read license file '%s1'",licenseFilename))
      return(true);
   }
   int lic_type = _LicenseType();
   bottom();
   status=search('SERIAL:','@-e');
   _str line;
   get_line(line);

   top();
   int status2=search('vsflex +{:i}.{:i}','@re');
   _str major='';
   if (!status2) {
      major=get_match_text(0);
   }
   _delete_temp_view(temp_wid);
   p_window_id= orig_wid;

   if (status) {
      _message_box("This is not a valid license file");
      return(true);
   }
   // For now, allow going from BETA to switch to trial license.
   if (lic_type == LICENSE_TYPE_STANDARD || lic_type==LICENSE_TYPE_SUBSCRIPTION || lic_type==LICENSE_TYPE_CONCURRENT) {
      parse line with "SN=" auto word .;
      parse word with "SERIAL:"serialnum"|";
      //_message_box('serialnum='serialnum);
      if (serialnum=="") {
         _message_box("This is not a valid license file");
         return(true);
      }
      // This may need to be changed for the Core!!
      if (pos("trial",serialnum,1,'i')) {
         _message_box("You may not install a trial license file because you already have a better license");
         return(true);
      }
   }
   // This will need to be changed for the Core!!
   _str thisVer=_getVersion();
   parse thisVer with auto thisMajor '.' auto rest;
   if (thisMajor>major) {
      _message_box("This license file is for an older version of this product.");
      return(true);
   }
#endif 
   return(false);
}
void ctls2_browse.lbutton_up()
{
   _str result=_OpenDialog('-modal',
                           '',                   // Dialog Box Title
                           LICENSE_FILE_TYPE,    // Initial Wild Cards
                           def_file_types",License Files ("LICENSE_FILE_TYPE")",       // File Type List
                           OFN_FILEMUSTEXIST     // Flags
                           );
   if (result=='') return;
   int wid=ctls2_browse;
   result=strip(result);
   ctls2_license_file.p_text=strip(result,'B',"\"'");
   p_window_id=wid;
}
void ctls3_error.on_change(int reason,_str hrefText)
{
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      _str text=ginstall_license_file_src;
      if (hrefText=='cp') {
         text='cp 'maybe_quote_filename(ginstall_license_file_src)' 'maybe_quote_filename(ginstall_license_file_dest);
      } else if (hrefText=='dest') {
         text=ginstall_license_file_dest;
      }

      int orig_wid=_create_temp_view(temp_wid);
      _insert_text(text);
      deselect();top();_select_char();_end_line();_select_char();

      _copy_to_clipboard('',false);
#if __UNIX__
      _copy_to_clipboard('',true);
#endif

      _delete_temp_view();
      activate_window(orig_wid);
      return;
   }
}

#ifdef USE_SEAL_LICENSING
int _OnUpdate_lm_borrow(CMDUI &cmdui,int target_wid,_str command)
{
   int lic_type = _LicenseType();
   if (lic_type != LICENSE_TYPE_CONCURRENT) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}

_command void lm_borrow() name_info(',')
{
   int lic_type = _LicenseType();
   if (lic_type != LICENSE_TYPE_CONCURRENT) {
      _message_box("You must have a concurrent license checked out from a license server in order to borrow.", "SlickEdit");
      return;
   }

   _str server_name = _LicenseServerName();
   int status = 0;
   for (;;) {
      _str curDate = _date('I');
      int status = textBoxDialog("Borrow License",
                                 0, 0, "", "\t-html Enter date (and time, optional) that license will be returned.":+
                                           "<p>YYYY-MM-DD HH:MM (time optional, 24-hour local time)</p>":+
                                           "If successful, you will be disconnected from license server and borrowed license will be checked out.  ":+
                                           "Borrow will expire at date and time specified.  If no time is specified, borrow will expire at end of expiration date (local time).", "",
                                 "Borrow Expiration:"curDate);
      if (status < 0) {
         return;
      }
      if (_param1 == '') {
         _message_box("Must enter a date");
         continue;
      }
      break;
   }

   _str expires = strip(_param1);
   status = _LicenseBorrow(expires);
   if (!status && (_LicenseType() == LICENSE_TYPE_BORROW)) {
      _str borrowExpires = _fnpLastLicenseExpiresDate();                                                                             
      _message_box("Success.  Borrow license file checked out.  License will expire ":+borrowExpires:+" (local time).", "SlickEdit");

      _str last_server_name = _retrieve_value("_license_wizard_form.servername");
      if (last_server_name == '') {
         _append_retrieve(0, server_name, "_license_wizard_form.servername");
      }
   }
}

int _OnUpdate_lm_return(CMDUI &cmdui,int target_wid,_str command)
{
   int lic_type = _LicenseType();
   if (lic_type != LICENSE_TYPE_BORROW) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}

_command void lm_return() name_info(',')
{
   int lic_type = _LicenseType();
   if (lic_type != LICENSE_TYPE_BORROW) {
      _message_box("Not a returnable license.", "SlickEdit");
      return;
   }
   _str last_server_name = _LicenseServerName();
   if (last_server_name == '') {
      last_server_name = _retrieve_value("_license_wizard_form.servername");
   }

   int status = textBoxDialog("Return Borrowed License",
                              0, 0, "", "\t-html Returned borrow to license server (Example: ":+LICENSE_SERVER_PORT:+"@myserver).  Make sure your server is up and running.  If you have ":+
                              "a problem, verify your server and port with your administrator.  If successfully returned, license will revert to concurrent checkout on license server.", "",
                              "License Server:":+last_server_name);
   if (status < 0 || _param1 == '') {
      return;
   }

   _str license_server = _param1;
   status = _LicenseReturn(license_server);
   if (!status) {
      _append_retrieve(0, license_server, "_license_wizard_form.servername");
   }
}

#else
int _OnUpdate_lm_borrow(CMDUI &cmdui,int target_wid,_str command)
{
   return MF_GRAYED;
}

int _OnUpdate_lm_return(CMDUI &cmdui,int target_wid,_str command)
{
   return MF_GRAYED;
}

_command void lm_borrow() name_info(',')
{
   _message_box("Feature not supported.");
}

_command void lm_return() name_info(',')
{
   _message_box("Feature not supported.");
}

#endif

