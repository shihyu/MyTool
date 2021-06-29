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
#import "html.e"
#import "main.e"
#import "math.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "unittest.e"
#import "upcheck.e"
#import "hotfix.e"
#import "util.e"
#endregion

static const  CONTACTSUPPORT_MACRO_VERSION= "1.0";
static const  CONTACTSUPPORT_DEBUG ="OFF";

static const SUPPORT_BASEURL= "http://www.slickedit.com/support/";
static const DEF_SUPPORT_NOTICE = 'Click "Submit" to initiate a problem report with Product Support.  This will submit information essential in diagnosing this problem.  To view the information that will be submitted, click "View Info."';

/**
 * This code is for the privacy notice form that is displayed before the user
 * is taken to the webform
 */
_form _contact_support_priv_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='Privacy Notice';
   p_forecolor=0x80000008;
   p_height=2548;
   p_width=5265;
   p_x=4200;
   p_y=2562;
   _label ctllabel1 {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Click "Submit" to initiate a problem report with Product Support.  This will submit information essential in diagnosing this problem.  To view the information that will be submitted, click "View Info."';
      p_forecolor=0x80000008;
      p_height=1736;
      p_tab_index=1;
      p_width=5068;
      p_word_wrap=true;
      p_x=126;
      p_y=126;
   }
   _command_button buttonYes {
      p_auto_size=false;
      p_cancel=false;
      p_caption='Submit';
      p_default=false;
      p_height=350;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=1120;
      p_x=1680;
      p_y=2100;
   }
   _command_button buttonViewInfo {
      p_auto_size=false;
      p_cancel=false;
      p_caption='View Info';
      p_default=false;
      p_height=350;
      p_tab_index=3;
      p_tab_stop=true;
      p_width=1120;
      p_x=2884;
      p_y=2100;
   }
   _command_button buttonNo {
      p_auto_size=false;
      p_cancel=true;
      p_caption='Cancel';
      p_default=false;
      p_height=350;
      p_tab_index=4;
      p_tab_stop=true;
      p_width=1120;
      p_x=4074;
      p_y=2100;
   }
}

defeventtab _contact_support_priv_form;
void buttonYes.lbutton_up()
{
   p_active_form._delete_window(1);
   webmail_support();
}

void buttonViewInfo.lbutton_up()
{
   p_active_form._delete_window();
   vsversion();
}

void buttonNo.on_create()
{
   if (arg(1) == "parented") {
      ctllabel1.p_caption = DEF_SUPPORT_NOTICE;
      buttonViewInfo.p_visible = false;
   }
}

/**
 * Gathers relevant information necessary for technical support,
 * and then automatically populates a web form with this information.
 * This requires that a web browser be configured on the
 * user's computer.
 * 
 */
void webmail_support()
{
   URL := "";
   _str tupleHash:[];
   get_support_tuples(tupleHash);
   URL = SUPPORT_BASEURL;
   _maybe_append(URL, "/");
   _maybe_prepend(URL, "http://");
   URL :+= "mailto/?";
   URL :+= join_tuples(tupleHash, "&");
   goto_url(URL, false, 0);
}

/**
 * Displays the privacy legal notice form. Any arguments are passed to the on_create()
 * function of the form. If the argument is "parented", then it means this was
 * called from the about dialog, and we should not display the View Info button
 */
_command do_webmail_support() name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (arg(1) == "") {
      int windowID = show("-modal _contact_support_priv_form");
   } else {
      int windowID = show("-modal _contact_support_priv_form", arg(1));
   }
}

/**
 * Goes to a web page that will display information about this license's maintenace
 * and support agreement.
 */
_command check_maintenance() name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   URL := "";
   _str tupleHash:[];
   get_maintenance_tuples(tupleHash);
   URL = SUPPORT_BASEURL;
   _maybe_append(URL, "/");
   _maybe_prepend(URL, "http://");
   URL :+= "maint_check/?";
   URL :+= join_tuples(tupleHash, "&");
   goto_url(URL, false, 0);
}

static void get_maintenance_tuples(_str (&tupleHash):[])
{
   _str serial = _getSerial();

   _str time = _time('G');

   tupleHash._makeempty();
   tupleHash:["Serial"] = serial;
   tupleHash:["CustomerTime"] = time;
}

/**
 * Retrieves relevant system and product information via calls to
 * Slick-C&reg; macros, and then packages them up in a hash.
 * 
 * @param tupleHash The output string hash where the tuples will be stored
 */
static void get_support_tuples(_str (&tupleHash):[])
{
   productID := "";
   version := "";
   _upcheckGetProductInfo(productID, version);
   _str line = get_message(SLICK_EDITOR_VERSION_RC);
   if (pos("beta", line, 1, "I") > 0) {
      version :+= " BETA";
   }

   _str serial = _getSerial();

   _str installPath = _getSlickEditInstallPath();
   _str configPath = _ConfigPath();
   _str spillPath = _SpillFilename();

   tupleHash._makeempty();
   tupleHash:["ProductID"] = productID;
   tupleHash:["Version"] = version;
   tupleHash:["MVersion"] = CONTACTSUPPORT_MACRO_VERSION;
   tupleHash:["Serial"] = serial;
   tupleHash:["Packages"] = getLicensedPackages();
   //tupleHash:["NofUsers"] = aboutLicensedNofusers("");
   //tupleHash:["Expiration"] = _LicenseExpiration();
   //tupleHash:["LicenseFile"] = _LicenseFile();
   //tupleHash:["LicensedTo"] = _LicenseToInfo();
   tupleHash:["BuildDate"] = _getProductBuildDate();
   tupleHash:["Emulation"] = _getEmulation();
   tupleHash:["OS"] = _getOsName();
   tupleHash:["OSVersion"] = getOSVersion();
   tupleHash:["InstallPath"] = installPath:+getDiskInfo(installPath);
   tupleHash:["ConfigPath"] = configPath:+getDiskInfo(configPath);
   tupleHash:["SpillPath"] = spillPath:+getDiskInfo(spillPath);
   tupleHash:["MemLoad"] = aboutMemoryInfo("");
   if (_isUnix() && !_isMac()) {
      tupleHash:["XServer"] = _XServerVendor();
   }
   if (CONTACTSUPPORT_DEBUG :!= "OFF") {
      tupleHash:["DEBUG"] = "ON";
   }
   tupleHash:["TimeStamp"] = _time('B');
   tupleHash:["HotFixes"] = getHotfixesList(); 
}

/**
 * @return A string with all key/value pairs in the support hash
 * joined together with the specified join string.
 * 
 * @param tupleHash Hash of strings representing tuples to join
 * @param joinChar string to use as the 'glue' to join key/value pairs
 * @param tupleJoinChar string to use as the 'glue' to join tuples
 * @param encode If true, the resulting string is URL-encoded. This is the default
 * behavior
 * 
 * @see get_support_tuples
 */
_str join_tuples(_str (&tupleHash):[], _str joinChar="&", _str tupleJoinChar="=", 
                 bool encode=true)
{
   urlParams := "";
   int numElements = _utCountHashElements(tupleHash);
   j := 0;

   typeless i;
   for (i._makeempty(); ; ) {
      tupleHash._nextel(i);
      if (i._isempty()) {
         break;
      }
      j++;
      if (encode) {
         urlParams :+= i :+ tupleJoinChar :+ urlencode(tupleHash._el(i));
      }
      else {
         urlParams :+= i :+ tupleJoinChar :+ tupleHash._el(i);
      }
      if (j < numElements) {
         urlParams :+= joinChar;
      }
   }
   return urlParams;
}

/**
 * @return Volume information for the specified input path.
 * Only works on Windows; returns empty string on Unix
 *
 * @param path Directory path for which to obtain volume information
 */
static _str getPathInfo(_str path)
{
   _str diskinfo = path;
   typeless machinename, sharename, status, FSName, FSFlags, dt;
   if (_isWindows()) {
      FSInfo := "";
      if (substr(path,1,2)=='\\') {
         parse path with '\\'machinename'\'sharename'\';
         status=ntGetVolumeInformation('\\'machinename'\'sharename'\',FSName,FSFlags);
         if (!status) {
            FSInfo=','FSName;
         }
         diskinfo :+= ' (remote'FSInfo')';
      } else {
         status=ntGetVolumeInformation(substr(path,1,3),FSName,FSFlags);
         if (!status) {
            FSInfo=','FSName;
         }
         dt=_drive_type(substr(path,1,2));
         if (dt==DRIVE_NOROOTDIR) {
            diskinfo :+= ' (invalid drive)';
         } else if (dt==DRIVE_FIXED) {
            diskinfo :+= ' (non-removable drive'FSInfo')';
         } else if (dt==DRIVE_CDROM){
            diskinfo :+= ' (CD-ROM'FSInfo')';
         } else if (dt==DRIVE_REMOTE){
            diskinfo :+= ' (remote'FSInfo')';
         } else {
            diskinfo :+= ' (removable drive'FSInfo')';
         }
      }
   }
   return diskinfo;
}

/**
 * @return Detailed information about the OS version, which for Windows
 * includes major and minor versions, build#, and service pack info.
 * On Unix, this includes X Server information and kernel info
 */
static _str getOSVersion()
{
   osinfo := "";
   if (_isWindows()) {
      // OS: Windows XP
      // Version: 5.01.2600  Service Pack 1
      typeless MajorVersion="",MinorVersion="",BuildNumber="",PlatformId="",ProductType="";
      CSDVersion := "";
      ntGetVersionEx(MajorVersion,MinorVersion,BuildNumber,PlatformId,CSDVersion,ProductType);
      if( length(MinorVersion)<1 ) {
         MinorVersion='0';
      }
      // Pretty-up the minor version number for display
      if( length(MinorVersion)<2 ) {
         MinorVersion='0'MinorVersion;
      }
      osinfo=MajorVersion'.'MinorVersion'.'BuildNumber' 'CSDVersion;
      return osinfo;
   }
   // OS: SunOS
   // Kernel Level: 5.7
   // Build Version: Generic_106541-31
   // X Server Vendor: Hummingbird Communications Ltd.
   UNAME info;
   _uname(info);
   osinfo=info.release" "info.version;

   return osinfo;
}

/**
 * @return Gets information about the licensed packages, one package per
 * line
 */
static _str getLicensedPackages()
{
   return('');
}

