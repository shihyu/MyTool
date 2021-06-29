#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "minihtml.sh"
#import "xml.sh"
#import "stdprocs.e"
#import "guiopen.e"
#import "cfg.e"
#import "html.e"
#import "main.e"
#import "files.e"
#import "picture.e"
#import "stdcmds.e"
#import "listbox.e"
#import "treeview.e"
#import "xml.e"
#import "xmldoc.e"
#import "se/messages/MessageCollection.e"
#import "tbcmds.e"
#import "context.e"
#import "help.e"

struct PLGMAN_PLUGIN_INFO {
   _str m_ver;
   _str m_upgrade_ver;
   _str m_plugin_name;
};
static PLGMAN_PLUGIN_INFO gplgman_installed_info:[];
static const PLUGIN_ATTR_TITLE=  'title';
static const PLUGIN_ATTR_FORUM_URL=  'forum_url';
static const PLUGIN_ATTR_VER=  'ver';
static const PLUGIN_ATTR_MIN_VER=  'min_ver';
static const PLUGIN_ATTR_MAX_VER=  'max_ver';
static const PLUGIN_ELEMENT_CAT=  'cat';
static const PLUGIN_ELEMENT_SHORT=  'short';
static const PLUGIN_ELEMENT_LONG= 'long';


static const PLUGINS_INDEX_ATTR_NAME=  'n';
static const PLUGINS_INDEX_ATTR_MACRO=  'm';

static int gplgman_timer;
static int gplgman_xml_timer;
static int gplgman_job_handle;
static int gplgman_job_xml_handle;
static _str gplgman_temp_path;
static _str gplgman_last_download_path;
struct PLGMAN_DOWNLOAD_INFO {
   //boolean m_already_downloading;
   _str m_plugin_name;
   _str m_download_name;
   _str m_dest_filename;
   bool m_install_after_download;
};
static PLGMAN_DOWNLOAD_INFO gplgman_download_info[];
static _str gplgman_categories[];

defeventtab _plugin_manager_form;
//_GetDialogInfoHt  _SetDialogInfoHt
static const PLUGIN_INFO_FILE= 'plugin.xml';
static const PLUGINS_INDEX_FILE='plugins.xml';

static _str PUSER_LAST_FILTER_ARGS(...) { 
   if (arg()) ctlfilter.p_user=arg(1);
   return ctlfilter.p_user; 
}
static int PUSER_PLUGINS_HANDLE(...) {
   if (arg()) ctlminihtml1.p_user=arg(1);
   return ctlminihtml1.p_user; 
}
static int PUSER_PLUGINS_INSTALLED_HANDLE(...) { 
   if (arg()) ctlminihtml2.p_user=arg(1);
   return ctlminihtml2.p_user; 
}
static int PUSER_FETCH_ALL_INSTALLED_INFO_DONE(...) { 
   if (arg()) ctlclose.p_user=arg(1);
   return ctlclose.p_user; 
}

static void plgman_xml_timer(int form_wid) {
   if (!_iswindow_valid(form_wid)) {
      // Something bad happened.
      gplgman_download_info._makeempty();
      _kill_timer(gplgman_xml_timer);gplgman_xml_timer=-1;
      if (gplgman_job_xml_handle>=0) {
         status:=_job_close(gplgman_job_xml_handle,2000);gplgman_job_xml_handle=-1;
      }
      return;
   }
   if (_job_is_running(gplgman_job_xml_handle)) {
      return;
   }
   _job_close(gplgman_job_xml_handle);gplgman_job_xml_handle=-1;
   _kill_timer(gplgman_xml_timer);gplgman_xml_timer=-1;
   orig_wid:=p_window_id;
   p_window_id=form_wid;
   PUSER_PLUGINS_HANDLE(_xmlcfg_open(gplgman_temp_path:+PLUGINS_INDEX_FILE,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA));
   if (PUSER_PLUGINS_HANDLE()>=0) {
      //_plgman_get_installed_plugins_info(gplgman_installed_info);
      //_plgman_fetch_all_installed_info(gplgman_installed_info);
      //filter_plugins('','');

      ctlcategory.p_enabled=ctlfilter.p_enabled=true;
      _plgman_get_installed_plugins_info(gplgman_installed_info);
      _plgman_fetch_all_installed_info(gplgman_installed_info);
      PUSER_LAST_FILTER_ARGS('');
      ctlfilter.call_event(ctlfilter,ON_CHANGE,'W');
   }
   p_window_id=orig_wid;
}
static void plgman_timer(int form_wid) {
   len:=gplgman_download_info._length();
   if (!len || !_iswindow_valid(form_wid)) {
      // Something bad happened.
      gplgman_download_info._makeempty();
      _kill_timer(gplgman_timer);gplgman_timer=-1;
      if (gplgman_job_handle>=0) {
         status:=_job_close(gplgman_job_handle,2000);gplgman_job_handle=-1;
      }
      return;
   }
   if (_job_is_running(gplgman_job_handle)) {
      return;
   }
   orig_wid:=p_window_id;

   p_window_id=form_wid;
   _job_close(gplgman_job_handle);gplgman_job_handle=-1;
   
   if (gplgman_download_info[0].m_install_after_download) {
      install_file:=gplgman_download_info[0].m_dest_filename;
      gplgman_download_info._deleteel(0);
#if 0
      _str title=_plgman_install_get_title(handle,node);
      if (verified==0 || !isinteger(verified)) {
         result=_message_box("This plugin contains code that has not yet been verified by SlickEdit. While this extra verification process doesn't gaureentee that this plugin isn't malicious, you might consider waiting until SlickEdit checks it over.\n\nInstall "title"?",'Install 'title,MB_YESNOCANCEL);
      } else if (verified==2) {
         result=_message_box("The namespaces used by this plugin have not yet been verified by SlickEdit. While namespace collisions are unlikely, you might consider waiting util SlickEdit checks it over.\n\nInstall "title"?",'Install 'title,MB_YESNOCANCEL);
      }
#endif
#if 1
      p_window_id._plugin_install(install_file);
#else
      say('install_file='install_file);
      say('skip install');
#endif
      _plgman_get_installed_plugins_info(gplgman_installed_info);
      _plgman_fetch_all_installed_info(gplgman_installed_info);
      PUSER_LAST_FILTER_ARGS('');
      ctlfilter.call_event(ctlfilter,ON_CHANGE,'W');
   } else {
      gplgman_download_info._deleteel(0);
      PUSER_LAST_FILTER_ARGS('');
      ctlfilter.call_event(ctlfilter,ON_CHANGE,'W');
   }
   if (gplgman_download_info._length()) {
      PLGMAN_DOWNLOAD_INFO *pdownload=&gplgman_download_info[gplgman_download_info._length()-1];
      _str array[];
      array[0]=pdownload->m_dest_filename;
      array[1]=pdownload->m_download_name;
      gplgman_job_handle=_job_start('plgman_downloader','plgman_downloader',array);
   } else {
      _kill_timer(gplgman_timer);gplgman_timer=-1;
   }
   p_window_id=orig_wid;
}

static bool checking_for_updates() {
   handle:=PUSER_PLUGINS_HANDLE();
   if (isinteger(handle) && handle>=0) {
      return false;
   }
   return true;
}
void ctlminihtml1.on_create() {
   gplgman_categories._makeempty();
   gplgman_timer=-1;gplgman_xml_timer=-1;
   gplgman_job_handle=-1;gplgman_job_xml_handle=-1;
   gplgman_temp_path='';
   gplgman_last_download_path='';
   gplgman_download_info._makeempty();gplgman_installed_info._makeempty();
   ctlcategory.p_enabled=ctlfilter.p_enabled=false;

   if (gplgman_temp_path=='') {
      gplgman_temp_path=mktempdir(1,'$slk.slickedit.plgman',true);
      status:=_make_path(gplgman_temp_path);
      //say('status='status' temp_path='gplgman_temp_path);
   }

   _plgman_get_installed_plugins_info(gplgman_installed_info);
   _plgman_fetch_all_installed_info(gplgman_installed_info);
   filter_plugins('','');

   _str array[];
   array[0]=gplgman_temp_path:+PLUGINS_INDEX_FILE;
   array[1]=PLUGINS_INDEX_FILE;
   gplgman_job_xml_handle=_job_start('plgman_downloader','plgman_downloader',array);
   gplgman_xml_timer=_set_timer(250,plgman_xml_timer,p_active_form);
}
void _cb_exitbefore_save_config_plgman() {
   form_wid:=_find_formobj('_plugin_manager_form');
   if (form_wid>0) {
      form_wid._delete_window();
   }
}
void ctlclose.lbutton_up() {
   // Are there any pending downloads/installs?
   if (gplgman_download_info._length()) {
      result:=_message_box("There are pending installs/downloads.\n\nWait for completions?",'',MB_YESNO);
      if (result==IDYES) {
         return;
      }
   }
   p_active_form._delete_window();
}
void ctlminihtml1.on_destroy() {
   handle:=PUSER_PLUGINS_HANDLE();
   if (isinteger(handle) && handle>=0) {
      _xmlcfg_close(handle);
   }
   handle=PUSER_PLUGINS_INSTALLED_HANDLE();
   if (isinteger(handle) && handle>=0) {
      _xmlcfg_close(handle);
   }
   if (gplgman_timer>=0) {
      _kill_timer(gplgman_timer);gplgman_timer=-1;
   }
   if (gplgman_xml_timer>=0) {
      _kill_timer(gplgman_xml_timer);gplgman_xml_timer=-1;
   }
   if (gplgman_job_handle>=0) {
      status:=_job_close(gplgman_job_handle,2000);gplgman_job_handle=-1;
      //say('status='status);
   }
   if (gplgman_job_xml_handle>=0) {
      status:=_job_close(gplgman_job_xml_handle,2000);gplgman_job_xml_handle=-1;
      //say('status='status);
   }
   if (gplgman_temp_path!='') {
      _DelTree(gplgman_temp_path,true);
   }
}
  

void _plugin_manager_form.on_resize() {
   //say(ctlsstab1.p_height' '_dy2ly(SM_TWIP,ctlsstab1.p_client_height));
   //say(ctlsstab1.p_child.p_object);
   {
      tab_container:=ctlsstab1.p_child;
       ctlsstab1.p_width= _dx2lx(SM_TWIP,p_active_form.p_client_width)-ctlsstab1.p_x*2;
       int height;
       height=_dy2ly(SM_TWIP,p_active_form.p_client_height)-ctlsstab1.p_y*2-ctlclose.p_height-120;
       ctlsstab1.p_height= height;
       ctlhelp.p_y=ctlclose.p_y=ctlsstab1.p_y+height+120;
       //ctlminihtml1.p_width=_dx2lx(SM_TWIP,ctlsstab1.p_client_width)-ctlminihtml1.p_x*2-100;
       ctlminihtml1.p_width=tab_container.p_width-ctlminihtml1.p_x*2;
       height=tab_container.p_height-(ctlminihtml1.p_y+ctlfilter.p_y) - ctlinstallzip.p_height-100;
       ctlminihtml1.p_height=height;
       ctlinstallzip.p_y=ctlminihtml1.p_y+height+100;
   }
    {
       tab_container:=ctlsstab1.p_child;
       ctlminihtml2.p_width=tab_container.p_width-ctlminihtml2.p_x*2;
        int height;
        height=tab_container.p_height-ctlminihtml2.p_y*2 ;
        ctlminihtml2.p_height= height;
    }

    sizeBrowseButtonToTextBox(ctlfilter.p_window_id, ctlToolDelete.p_window_id);
}
static _str _plgman_install_get_title(int handle,int node,_str plugin_name='') {
   title:=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_TITLE);
   if (title=='') {
      if (plugin_name=='') {
         plugin_name=_xmlcfg_get_attribute(handle,node,PLUGINS_INDEX_ATTR_NAME);
      }
      parse plugin_name with auto v1 '.' auto v2;
      if (v2!='') {
         title=v2;
      } else {
         title=v1;
      }
      if (title=='') {
         title=".";
      }
   }
   return title;
}
static _str _plgman_manager_get_html(int handle,int node,_str ver='',_str plugin_name='',_str upgrade_ver='',_str option='') {
   _str orig_ver=ver;
   int temp;
   title:=_plgman_install_get_title(handle,node,plugin_name);
   ver=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_VER);
   if (ver=='') {
      ver='1.0';
   }
   temp=_xmlcfg_find_child_with_name(handle,node,PLUGIN_ELEMENT_SHORT);
   short_desc := "";
   if (temp>=0) {
      short_desc=_xmlcfg_get_text(handle,temp);
   }
   temp=_xmlcfg_find_child_with_name(handle,node,PLUGIN_ELEMENT_LONG);
   long_desc := "";
   if (temp>=0) {
      long_desc=_xmlcfg_get_text(handle,temp);
   }
   //p_text='<p><b>XRetrace 1.0</b></p><p>This is the description for the xretrace macro which does nifty stuff<p><a href="install">Install</a><hr><p><b>Another macro 1.0</b></p><p>This is the description of another macro macro which does nifty stuff<p><a href="install">Install</a><hr><p><b>XRetrace 1.0</b></p><p>This is the description for the xretrace macro which does nifty stuff<p><a href="install">Install</a><hr><p><b>Another macro 1.0</b></p><p>This is the description of another macro macro which does nifty stuff<p><a href="install">Install</a><hr>';
   if (long_desc!='') {
      short_desc2:=strip(translate(short_desc,' ',"\r\n"));
      prefix:='&nbsp;';
      if (_last_char(short_desc2)!='.') {
         strappend(prefix,'...');
      }
      strappend(short_desc,prefix:+'<a href="<<m 'node'">more info</a>');
   }
   forum_url := "";
   forum_url=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_FORUM_URL);
   if (forum_url!='') {
      forum_url='&nbsp;&nbsp;&nbsp; <a href="<<f 'forum_url'">Forum</a>';
   }
   len:=gplgman_download_info._length();
   downloading := false;
   for (i:=0;i<len;++i) {
      if (lowcase(gplgman_download_info[i].m_plugin_name):==lowcase(plugin_name)) {
         downloading=true;
         break;
      }
   }
   if (option=='ua') {
      if (downloading || upgrade_ver=='') {
         return '';
      }

      ctlminihtml2.call_event(CHANGE_CLICKED_ON_HTML_LINK,'<<x 'node,ctlminihtml2,ON_CHANGE,'W');
      return '';
   }
   _str html;
   if (option!='') {
      update_str := "";
      if (option!='b') {
         if (upgrade_ver!='') {
            if (option!='u') return '';
            update_str='&nbsp;&nbsp;&nbsp; <a href="<<i 'node'">Update</a>';
         } else {
            if (option=='u') return '';
         }
      }
      if (!downloading) {
         html='<b>':+title:+' ':+ver:+'</b><br><p>'short_desc'</p></br><a href="<<u 'node'">Uninstall</a>':+update_str :+forum_url :+'<hr>';
      }
   } else {
      if (!downloading) {
         uninstall_str := "";
         _str install_str='<a href="<<i 'node'">Install</a>&nbsp;&nbsp;&nbsp;';
         if (upgrade_ver!='') {
            install_str='<a href="<<i 'node'">Update</a>&nbsp;&nbsp;&nbsp;':+'<a href="<<u 'node'">Uninstall</a>&nbsp;&nbsp;&nbsp;';
         } else if (orig_ver!='') {
            install_str='<a href="<<u 'node'">Uninstall</a>&nbsp;&nbsp;&nbsp;';
         }
         html='<b>':+title:+' ':+ver:+'</b><br><p>'short_desc'</p></br>'install_str'<a href="<<d 'node'">Download</a>':+forum_url :+'<hr>';
      }
   }
   if (downloading) {
      html='<b>':+title:+' ':+ver:+'</b><br><p>'short_desc'</p></br>Downloading...':+forum_url :+'<hr>';
      return html;
   }
   return html;
}
static void _plgman_get_categories(int handle,_str (&plgman_categories)[]) {
   _str array[];
   _xmlcfg_find_simple_array(handle,'/plugins/p/':+PLUGIN_ELEMENT_CAT,array);
   len := array._length();
   _str hashtab:[];
   for (j:=0;j<len;++j) {
      int node=(typeless)array[j];
      categories:=_xmlcfg_get_text(handle,node);
      for (;;) {
         if (categories=='') break;
         parse categories with auto category "\n" categories;
         if (category!='') {
            hashtab:[lowcase(category)]=category;
         }
      }
   }
   plgman_categories._makeempty();
   plgman_categories[plgman_categories._length()]='All Categories';
   foreach (auto k=>auto v in hashtab) {
      plgman_categories[plgman_categories._length()]=v;
   }
   plgman_categories._sort('i');
}
static void filter_plugins(_str filter_text, _str filter_category) {
   if (!isinteger(PUSER_PLUGINS_HANDLE()) || PUSER_PLUGINS_HANDLE()<0) {
      ctlminihtml1.p_text='<font size="+2"><b>Downloading index...</b></font>';
      return;
   }
   if (strieq(filter_category,'All Categories')) {
      filter_category='';
   }
   filter_args:=filter_text"\t"filter_category;
   if (filter_args:==PUSER_LAST_FILTER_ARGS()) {
      return;
   }
   PUSER_LAST_FILTER_ARGS(filter_args);
   int handle=PUSER_PLUGINS_HANDLE();
   /*
      Search title,short, and long description
   */
   predicate := "";
   for (;;) {
      parse filter_text with auto word filter_text;
      if (word=='') {
         break;
      }
      word=_escape_re_chars(word);
      word=stranslate(word,'\x22','"');
      word='"'word'"';

      strappend(predicate,'[contains('PLUGIN_ELEMENT_LONG','word',"ri") or contains('PLUGIN_ELEMENT_SHORT','word',"ri") or contains(@'PLUGIN_ATTR_TITLE','word',"ri")]');
   }
   _str search_string;
   if (predicate=='') {
      search_string='/plugins/p';
   } else {
      search_string='/plugins/p'predicate;
   }

   if (!gplgman_categories._length()) {
      _plgman_get_categories(handle,gplgman_categories);
      ctlcategory.p_enabled=true;
      ctlcategory._lbclear();
      len:=gplgman_categories._length();
      orig_wid:=p_window_id;
      p_window_id=ctlcategory;
      for (i:=0;i<len;++i) {
         _lbadd_item(gplgman_categories[i]);
      }
      p_text='All Categories';
      p_window_id=orig_wid;
   }


   _str array[];
   //typeless start=_time('b');
   _xmlcfg_find_simple_array(handle,search_string,array);
   //say('len='array._length()' t='(((typeless)_time('b') - start)));
   //_xmlcfg_find_simple_array(handle,'/options/pn/*[contains(@categories,'filter_category','ri')]',array);
   _default_option(VSOPTION_WARNING_STRING_LENGTH,MAXINT);
   //_str font_name=VSDEFAULT_DIALOG_FONT_NAME;
   //int font_size=100;
   //_xlat_font(font_name,font_size);
   //_minihtml_SetDefaultProportionalFont(font_name,0);
   //_minihtml_SetDefaultProportionalFontSize(4,font_size);
   //_str result='<font face="'font_name'" size="+2">';
   //_str result='<font face="' 'courier new' '">';
   //_str result='<font face="' font_name '"><font size="-1">';
   result := "";
   upgrade_change := false;

   _str edver=_version();

   int i;
   len:=array._length();
   for (i=0;i<len;++i) {
      int node=(typeless)array[i];
      plugin_name:=lowcase(_xmlcfg_get_attribute(handle,node,PLUGINS_INDEX_ATTR_NAME));
      PLGMAN_PLUGIN_INFO *pinfo=gplgman_installed_info._indexin(plugin_name);
      if (pinfo) {
         ver:=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_VER);
         if (ver=='') {
            ver='1.0';
         }
         if(_version_compare(pinfo->m_ver,ver)<0) {
            if (pinfo->m_upgrade_ver!=ver) {
               pinfo->m_upgrade_ver=ver;
               upgrade_change=true;
            }
         } else {
            if (pinfo->m_upgrade_ver!= '') {
               pinfo->m_upgrade_ver= '';
               upgrade_change=true;
            }
         }
#if 0
         continue;
#endif
      }

      if (!_haveProMacros()) {
         temp:=_xmlcfg_get_attribute(handle,node,PLUGINS_INDEX_ATTR_MACRO);
         if (temp=='' || temp) {
            continue;
         }
      }
      min_ver:=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_MIN_VER);
      if (min_ver!='' && _version_compare(min_ver,edver)>0) {
         continue;
      }
      max_ver:=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_MAX_VER);
      if (max_ver!='' && _version_compare(max_ver,edver)<0) {
         continue;
      }

      if (filter_category!='') {
         temp:=_xmlcfg_find_child_with_name(handle,node,PLUGIN_ELEMENT_CAT);
         if (temp>=0) {
            categories:=_xmlcfg_get_text(handle,temp);
            if (!pos(filter_category,"\n"categories" n",1,'i')) {
               continue;
            }
         }
      }

      _str html;
      if (pinfo) {
         html=_plgman_manager_get_html(handle,node,pinfo->m_ver,pinfo->m_plugin_name,pinfo->m_upgrade_ver);
      } else {
         html=_plgman_manager_get_html(handle,node,'',plugin_name);
      }
      //if(i==0) say(html);
      strappend(result,html);
   }
   ctlminihtml1.p_text=result;
   if (upgrade_change) {
      _plgman_fetch_all_installed_info(gplgman_installed_info);
   }
}
void ctlfilter.on_change() {
   filter_plugins(ctlfilter.p_text,ctlcategory.p_text);
}
void ctlcategory.on_change() {
   filter_plugins(ctlfilter.p_text,ctlcategory.p_text);
}
static void process_link(int handle,_str hrefText) {
   letter:=substr(hrefText,3,1);
   if (substr(hrefText,1,2)!='<<') {
      return ;
   }
   if (letter=='i' || letter=='x' || letter=='d' || letter=='u') {
      typeless node;
      parse hrefText with . node;
      ver := "";
      int temp;
      plugin_name:=_xmlcfg_get_attribute(handle,node,PLUGINS_INDEX_ATTR_NAME);
      plugin_file:=plugin_name;
      ver=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_VER);
      if (letter=='i' || letter=='x' || letter=='d') {
         PLGMAN_PLUGIN_INFO *pinfo=gplgman_installed_info._indexin(lowcase(plugin_name));
         if (pinfo && pinfo->m_upgrade_ver!='') {
            ver=pinfo->m_upgrade_ver;
         }
      }
      if (ver!='') {
         strappend(plugin_file,'.ver.'ver);
      }
      //_str verified='0';
      //verified=_xmlcfg_get_attribute(handle,node,'e');
      if (letter=='u') {
         p_window_id._plugin_uninstall(plugin_name);
         _plgman_get_installed_plugins_info(gplgman_installed_info);
         _plgman_fetch_all_installed_info(gplgman_installed_info);
         PUSER_LAST_FILTER_ARGS('');
         ctlfilter.call_event(ctlfilter,ON_CHANGE,'W');
         return;
      }

      int result=IDYES;
      if (result==IDYES) {
         strappend(plugin_file,'.zip');
         //say(plugin_file);
         if (gplgman_temp_path=='') {
            gplgman_temp_path=mktempdir(1,'$slk.slickedit.plgman',true);
            status:=_make_path(gplgman_temp_path);
            //say('status='status' temp_path='gplgman_temp_path);
         }
         PLGMAN_DOWNLOAD_INFO new_download_info;
         new_download_info.m_install_after_download=(letter=='i' || letter=='x');
         new_download_info.m_plugin_name=plugin_name;
         new_download_info.m_download_name=plugin_file;
         new_download_info.m_dest_filename=gplgman_temp_path:+plugin_file;
         if (letter=='d') {
            _str result2=p_active_form._OpenDialog('-new -modal',
                 'Save As',
                 '',     // Initial wildcards
                 "Plugin Files (*.zip)",
                 OFN_SAVEAS,
                 '',      // Default extensions
                 plugin_file, // Initial filename
                 (gplgman_last_download_path!='')?gplgman_last_download_path:_DownloadsPath(),      // Initial directory
                 '',      // Reserved
                 "Save As dialog box"
                 );
            if (result2=='') return;
            result2=strip(result2,'B','"');
            result2=absolute(result2);
            new_download_info.m_dest_filename=result2;
            gplgman_last_download_path=_strip_filename(result2,'N');
         }
         // Add download item to global queue
         PLGMAN_DOWNLOAD_INFO *pdownload=&gplgman_download_info[gplgman_download_info._length()];
         *pdownload= new_download_info;
         // Make sure we are downloading the first item in the queue
         if (gplgman_job_handle<0) {
            _str array[];
            array[0]=pdownload->m_dest_filename;
            array[1]=pdownload->m_download_name;
            gplgman_job_handle=_job_start('plgman_downloaderr','plgman_downloader',array);
            //say('gplgman_job_handle='gplgman_job_handle);
            if (gplgman_job_handle>=0) {
               gplgman_timer=_set_timer(250,plgman_timer,p_active_form);
               //say('gplgman_timer='gplgman_timer);
            }
            if (handle==PUSER_PLUGINS_HANDLE()) {
               PUSER_LAST_FILTER_ARGS('');
               ctlfilter.call_event(ctlfilter,ON_CHANGE,'W');
            } else {
               if (letter!='x') {
                  _plgman_fetch_all_installed_info(gplgman_installed_info);
               }
            }

         }
#if 0
         install_file:='f:\f\vmacros\':+plugin_file;
         p_window_id._plugin_install(install_file);
         _plgman_get_installed_plugins_info(gplgman_installed_info);
         _plgman_fetch_all_installed_info(gplgman_installed_info);
         PUSER_LAST_FILTER_ARGS='';
         ctlfilter.call_event(ctlfilter,ON_CHANGE,'W');
#endif
      }
      return;
   } else if (letter=='a') {
      p_window_id.update_all(gplgman_installed_info);
      p_window_id._plgman_fetch_all_installed_info(gplgman_installed_info);
      return;
   } else if (letter=='f') {
      _str url;
      parse hrefText with . url;
      goto_url(url);
      return;
   } else if (letter=='m') {
      typeless node;
      parse hrefText with . node;
      temp:=_xmlcfg_find_child_with_name(handle,node,PLUGIN_ELEMENT_LONG);
      if (temp>=0) {
         title:=_plgman_install_get_title(handle,node);
         long_desc:=_xmlcfg_get_text(handle,temp);
         show('-wh -modal _plugin_info_form',title,long_desc);
      }
      return;
   }
}
void ctlminihtml1.on_change(int reason,_str hrefText) {
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      process_link(PUSER_PLUGINS_HANDLE(),hrefText);
      return;
   }
}
void ctlminihtml2.on_change(int reason,_str hrefText) {
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      process_link(PUSER_PLUGINS_INSTALLED_HANDLE(),hrefText);
      return;
   }
}
void _plgman_get_installed_plugins(_str (&plugins)[]) {
   file:=file_match(VSCFGPLUGIN_DIR:+'*',1);
   while (file!='') {
      parse file with (FILESEP:+FILESEP) auto plugin_name (FILESEP);
      if (plugin_name!='com_slickedit.base') {

         path:=absolute(file,null,true);
         if (path=='' || _isPluginFileSpec(path)) {
            // Bad argument? Plugin not registered?
            continue;
         }
         path=substr(path,1,length(path)-1);
         path2:=_strip_filename(path,'N');
         if (path2!='') path2=substr(path2,1,length(path2)-1);
         int status;
         if (_file_eq(get_extension(path2),'zip')) {
            path=substr(path2,1,length(path2)-4);
            plugins[plugins._length()]=path2;
         } else {
            plugins[plugins._length()]=path;
         }
      }
      file=file_match(VSCFGPLUGIN_DIR:+'*',0);
   }
}
static void _plgman_get_installed_plugins_info(PLGMAN_PLUGIN_INFO (&plugin_installed_info):[]) {
   gplgman_installed_info._makeempty();
   file:=file_match(VSCFGPLUGIN_DIR:+'*',1);
   while (file!='') {
      parse file with (FILESEP:+FILESEP) auto plugin_name (FILESEP);
      if (plugin_name!='com_slickedit.base') {

         path:=absolute(file,null,true);
         if (path=='' || _isPluginFileSpec(path)) {
            // Bad argument? Plugin not registered?
            continue;
         }
         path=substr(path,1,length(path)-1);
         path2:=_strip_filename(path,'N');
         if (path2!='') path2=substr(path2,1,length(path2)-1);
         int status;
         if (_file_eq(get_extension(path2),'zip')) {
            path=substr(path2,1,length(path2)-4);
         }

         vername:=_strip_filename(path,'P');
         //vername=substr(vername,1,length(vername)-1);
         parse vername with '.ver.' auto ver;
         ext:=get_extension(ver,true);
         if (_file_eq(ext,'.zip')) {
            ver=substr(ver,1,length(ver)-length(ext));
         }
         if (ver=='') {
            ver='1.0';
         }
         //say(ver);
         PLGMAN_PLUGIN_INFO *pinfo= &plugin_installed_info:[lowcase(plugin_name)];
         pinfo->m_ver=ver;
         pinfo->m_upgrade_ver='';
         pinfo->m_plugin_name=plugin_name;
         //say(plugin_name);
      }
      file=file_match(VSCFGPLUGIN_DIR:+'*',0);
   }
}
static void add_installed_html(_str option,_str &result,PLGMAN_PLUGIN_INFO (&plugin_installed_info):[],int plugin_installed_handle,int options_node) {
   foreach (auto k => auto v in plugin_installed_info) {
      plugin_name:=v.m_plugin_name;
      f:=VSCFGPLUGIN_DIR:+v.m_plugin_name:+FILESEP:+PLUGIN_INFO_FILE;
      handle:=_xmlcfg_open(f,auto state,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
      found_pn := false;
      if (handle>0) {
         node:=_xmlcfg_find_simple(handle,"/options/plugins/p");
         if (node>=0) {
            found_pn=true;
             dest_node:=_xmlcfg_copy(plugin_installed_handle,options_node,handle,node,VSXMLCFG_COPY_AS_CHILD);
             _xmlcfg_set_attribute(plugin_installed_handle,dest_node,PLUGINS_INDEX_ATTR_NAME,v.m_plugin_name);
             _xmlcfg_set_attribute(plugin_installed_handle,dest_node,PLUGIN_ATTR_VER,v.m_ver);

             html:=_plgman_manager_get_html(plugin_installed_handle,dest_node,v.m_ver,v.m_plugin_name,v.m_upgrade_ver,option);
             if (html!='') {
                strappend(result,html);
             }
         } else {
            // plugins file not found
         }
         _xmlcfg_close(handle);
      }
      if (!found_pn) {
         dest_node:=_xmlcfg_add(plugin_installed_handle,options_node,'p',VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(plugin_installed_handle,dest_node,PLUGINS_INDEX_ATTR_NAME,v.m_plugin_name);
         _xmlcfg_set_attribute(plugin_installed_handle,dest_node,PLUGIN_ATTR_VER,v.m_ver);

         html:=_plgman_manager_get_html(plugin_installed_handle,dest_node,v.m_ver,v.m_plugin_name,v.m_upgrade_ver,option);
         if (html!='') {
            strappend(result,html);
         }
      }
   }
}
static void update_all(PLGMAN_PLUGIN_INFO (&plugin_installed_info):[]) {
   _plgman_fetch_all_installed_info(plugin_installed_info,'ua');
}
static void _plgman_fetch_all_installed_info(PLGMAN_PLUGIN_INFO (&plugin_installed_info):[],_str option='') {
   if (isinteger(PUSER_PLUGINS_INSTALLED_HANDLE())) {
      _xmlcfg_close(PUSER_PLUGINS_INSTALLED_HANDLE());
   }
   int plugin_installed_handle=_xmlcfg_create('',VSENCODING_UTF8);
   options_node:=_xmlcfg_set_path(plugin_installed_handle,"/plugins");
   result := "";
   if (option!='') {
      add_installed_html(option,result,plugin_installed_info,plugin_installed_handle,options_node);
      return;
   }
   bool checking=checking_for_updates();
   //checking=true;
   if (checking) {
      result='<font size="+2"><b>Checking for updates...</b></font><hr>';
      add_installed_html('b',result,plugin_installed_info,plugin_installed_handle,options_node);
   } else {
      add_installed_html('u',result,plugin_installed_info,plugin_installed_handle,options_node);
      if (result!='') {
         result='<font size="+2"><b>Updates available</b></font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="<<a">Update All</a><hr>':+result;
      }
      result2 := "";
      add_installed_html('i',result2,plugin_installed_info,plugin_installed_handle,options_node);
      if (result2!='') {
         result2='<font size="+2"><b>Up-to-date</b></font><hr>':+result2;
      }
      if (result!='' && result2!='') {
         strappend(result,'<br>');
      }
      strappend(result,result2);
   }
   //result='<font face="Courier new">':+result;
   PUSER_PLUGINS_INSTALLED_HANDLE(plugin_installed_handle);
   ctlminihtml2.p_text=result;
   PUSER_FETCH_ALL_INSTALLED_INFO_DONE(1);

   //_mdi.edit('+t');
   //wid:=_mdi.p_child;
   //wid._insert_text(result);
}
void ctlsstab1.on_change(int reason,int tabnum) {
   if (reason==CHANGE_TABACTIVATED) {
      if (PUSER_FETCH_ALL_INSTALLED_INFO_DONE()!=1) {
         _plgman_fetch_all_installed_info(gplgman_installed_info);
      }
   }
}
void ctlinstallzip.lbutton_up() {
   p_window_id._plgman_choose_plugin_to_install();
   _plgman_get_installed_plugins_info(gplgman_installed_info);
   _plgman_fetch_all_installed_info(gplgman_installed_info);
   PUSER_LAST_FILTER_ARGS('');
   ctlfilter.call_event(ctlfilter,ON_CHANGE,'W');
}
static _str _plgman_choose_plugin_to_install() {
   typeless result=_OpenDialog(
      '-modal',
      'Install Plugin Zip File', '*.cfg.xml',
      "Plugin Files (*.zip)",
      OFN_FILEMUSTEXIST,
      '',
      '',
      '',
      'install_plugin_zip_file', // Retrieve name
      "Open dialog box"
      );
   if (result=='') {
      return '';
   }
   result=strip(result,'B','"');
   return result;
}

defeventtab _plugin_info_form;
void ctlminihtml1.on_create(_str caption='',_str long_desc='') {
   if (caption!='') {
      p_active_form.p_caption=caption;
   }
   p_text=long_desc;
}
void _plugin_info_form.on_resize() {
   tab_container:=ctlminihtml1.p_child;
    ctlminihtml1.p_width= _dx2lx(SM_TWIP,p_active_form.p_client_width)-ctlminihtml1.p_x*2;
    int height;
    height=_dy2ly(SM_TWIP,p_active_form.p_client_height)-ctlminihtml1.p_y*2-ctlcancel.p_height-70*2;
    ctlminihtml1.p_height= height;
    ctlcancel.p_y=ctlminihtml1.p_y+height+70;
}

_command void plugin_manager() name_info(',') {
   _message_box('plugin_manager not supported yet.');
   return;
   show('-xy _plugin_manager_form');
}

_form _plugin_manager_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_SIZABLE;
   p_caption="Plugin Manager";
   p_forecolor=0x80000008;
   p_height=8070;
   p_width=7260;
   p_x=31350;
   p_y=1695;
   p_eventtab=_plugin_manager_form;
   _sstab ctlsstab1 {
      p_FirstActiveTab=0;
      p_backcolor=0x80000005;
      p_DropDownList=false;
      p_forecolor=0x80000008;
      p_height=7335;
      p_NofTabs=2;
      p_Orientation=SSTAB_OTOP;
      p_PictureOnly=false;
      p_tab_index=5;
      p_tab_stop=true;
      p_width=7260;
      p_x=150;
      p_y=105;
      p_eventtab2=_ul2_sstabb;
      _sstab_container  {
         p_ActiveCaption="Search";
         p_ActiveEnabled=true;
         p_ActiveOrder=0;
         p_ActiveColor=0x80000008;
         p_ActiveToolTip='';
         _text_box ctlfilter {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_forecolor=0x80000008;
            p_height=300;
            p_tab_index=1;
            p_tab_stop=true;
            p_width=2520;
            p_x=75;
            p_y=120;
            p_eventtab2=_ul2_textbox;
         }
         _image ctlToolDelete {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_forecolor=0x80000008;
            p_height=330;
            p_max_click=MC_SINGLE;
            p_Nofstates=1;
            p_picture="bbdelete.svg";
            p_stretch=false;
            p_style=PSPIC_BUTTON;
            p_tab_index=2;
            p_tab_stop=false;
            p_value=0;
            p_width=345;
            p_x=2640;
            p_y=105;
            p_eventtab=_project_form.ctlToolDelete;
            p_eventtab2=_ul2_imageb;
         }
         _minihtml ctlminihtml1 {
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_height=6000;
            p_PaddingX=100;
            p_PaddingY=200;
            p_tab_index=4;
            p_tab_stop=true;
            p_width=7080;
            p_word_wrap=true;
            p_x=60;
            p_y=480;
            p_eventtab2=_ul2_minihtm;
         }
         _command_button ctlinstallzip {
            p_auto_size=true;
            p_cancel=false;
            p_caption="Install Plugin Zip File...";
            p_default=false;
            p_height=360;
            p_tab_index=5;
            p_tab_stop=true;
            p_width=2160;
            p_x=60;
            p_y=6540;
         }
         _combo_box ctlcategory {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_case_sensitive=false;
            p_completion=NONE_ARG;
            p_forecolor=0x80000008;
            p_height=300;
            p_style=PSCBO_EDIT;
            p_tab_index=6;
            p_tab_stop=true;
            p_width=3780;
            p_x=3060;
            p_y=120;
            p_eventtab2=_ul2_combobx;
         }
      }
      _sstab_container  {
         p_ActiveCaption="Installed";
         p_ActiveEnabled=true;
         p_ActiveOrder=1;
         p_ActiveColor=0x80000008;
         p_ActiveToolTip='';
         _minihtml ctlminihtml2 {
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_height=6840;
            p_PaddingX=100;
            p_PaddingY=200;
            p_tab_index=1;
            p_tab_stop=true;
            p_width=6945;
            p_word_wrap=true;
            p_x=45;
            p_y=60;
            p_eventtab2=_ul2_minihtm;
         }
      }
   }
   _command_button ctlclose {
      p_auto_size=false;
      p_cancel=true;
      p_caption="Close";
      p_default=false;
      p_height=360;
      p_tab_index=6;
      p_tab_stop=true;
      p_width=1080;
      p_x=150;
      p_y=7590;
   }
   _command_button ctlhelp {
      p_auto_size=false;
      p_cancel=false;
      p_caption="Help";
      p_default=false;
      p_height=360;
      p_tab_index=7;
      p_tab_stop=true;
      p_width=1080;
      p_x=1410;
      p_y=7590;
   }
}
_form _plugin_info_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption="More info";
   p_forecolor=0x80000008;
   p_height=5940;
   p_width=6000;
   p_x=25800;
   p_y=12900;
   _minihtml ctlminihtml1 {
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_height=5355;
      p_PaddingX=100;
      p_PaddingY=200;
      p_tab_index=1;
      p_tab_stop=true;
      p_width=6000;
      p_word_wrap=true;
      p_x=0;
      p_y=15;
      p_eventtab2=_ul2_minihtm;
   }
   _command_button ctlcancel {
      p_auto_size=false;
      p_cancel=true;
      p_caption="Close";
      p_default=false;
      p_height=420;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=1260;
      p_x=180;
      p_y=5460;
   }
}
_form _create_plugin_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_SIZABLE;
   p_caption="Create Plugin";
   p_forecolor=0x80000008;
   p_height=7485;
   p_width=7050;
   p_x=46185;
   p_y=13725;
   p_eventtab=_create_plugin_form;
   _label ctlpluginnamelabel {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption="Plugin Name:";
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=1;
      p_width=930;
      p_word_wrap=false;
      p_x=120;
      p_y=143;
   }
   _text_box ctlpluginname {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=300;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=3420;
      p_x=1200;
      p_y=90;
      p_eventtab2=_ul2_textbox;
   }
   _label ctlversionlabel {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption="Version:";
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=3;
      p_width=585;
      p_word_wrap=false;
      p_x=4815;
      p_y=128;
   }
   _text_box ctlversion {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=300;
      p_tab_index=4;
      p_tab_stop=true;
      p_width=870;
      p_x=5535;
      p_y=75;
      p_eventtab2=_ul2_textbox;
   }
   _sstab ctlsstab1 {
      p_FirstActiveTab=0;
      p_backcolor=0x80000005;
      p_DropDownList=false;
      p_forecolor=0x80000008;
      p_height=6465;
      p_NofTabs=3;
      p_Orientation=SSTAB_OTOP;
      p_PictureOnly=false;
      p_tab_index=5;
      p_tab_stop=true;
      p_width=6900;
      p_x=120;
      p_y=465;
      p_eventtab2=_ul2_sstabb;
      _sstab_container  {
         p_ActiveCaption="General";
         p_ActiveEnabled=true;
         p_ActiveOrder=0;
         p_ActiveColor=0x80000008;
         p_ActiveToolTip='';
         _label ctltitlelabel {
            p_alignment=AL_LEFT;
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption="Title:";
            p_forecolor=0x80000008;
            p_height=195;
            p_tab_index=1;
            p_width=360;
            p_word_wrap=false;
            p_x=45;
            p_y=158;
         }
         _text_box ctltitle {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_forecolor=0x80000008;
            p_height=300;
            p_tab_index=2;
            p_tab_stop=true;
            p_width=3420;
            p_x=2205;
            p_y=105;
            p_eventtab2=_ul2_textbox;
         }
         _label ctlforum_urllabel {
            p_alignment=AL_LEFT;
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption="Forum topic URL:";
            p_forecolor=0x80000008;
            p_height=195;
            p_tab_index=3;
            p_width=1230;
            p_word_wrap=false;
            p_x=45;
            p_y=548;
         }
         _text_box ctlforum_url {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_forecolor=0x80000008;
            p_height=300;
            p_tab_index=4;
            p_tab_stop=true;
            p_width=3420;
            p_x=2205;
            p_y=495;
            p_eventtab2=_ul2_textbox;
         }
         _label ctlmin_verlabel {
            p_alignment=AL_LEFT;
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption="Minimum supported version:";
            p_forecolor=0x80000008;
            p_height=195;
            p_tab_index=5;
            p_width=2010;
            p_word_wrap=false;
            p_x=45;
            p_y=998;
         }
         _text_box ctlmin_ver {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_forecolor=0x80000008;
            p_height=300;
            p_tab_index=6;
            p_tab_stop=true;
            p_width=945;
            p_x=2205;
            p_y=945;
            p_eventtab2=_ul2_textbox;
         }
         _label ctlmax_verlabel {
            p_alignment=AL_LEFT;
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption="Maximum supported version:";
            p_forecolor=0x80000008;
            p_height=195;
            p_tab_index=7;
            p_width=2070;
            p_word_wrap=false;
            p_x=45;
            p_y=1358;
         }
         _text_box ctlmax_ver {
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_completion=NONE_ARG;
            p_forecolor=0x80000008;
            p_height=300;
            p_tab_index=8;
            p_tab_stop=true;
            p_width=945;
            p_x=2205;
            p_y=1305;
            p_eventtab2=_ul2_textbox;
         }
         _label ctllabel5 {
            p_alignment=AL_LEFT;
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption="Categories:";
            p_forecolor=0x80000008;
            p_height=195;
            p_tab_index=9;
            p_width=840;
            p_word_wrap=false;
            p_x=45;
            p_y=1830;
         }
         _editor ctlcategories {
            p_border_style=BDS_FIXED_SINGLE;
            p_height=825;
            p_scroll_bars=SB_BOTH;
            p_tab_index=10;
            p_tab_stop=true;
            p_width=5385;
            p_x=1365;
            p_y=1770;
            p_eventtab2=_ul2_editwin;
         }
         _label ctlshortlabel {
            p_alignment=AL_LEFT;
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption="Short description:";
            p_forecolor=0x80000008;
            p_height=195;
            p_tab_index=11;
            p_width=1275;
            p_word_wrap=false;
            p_x=45;
            p_y=2895;
         }
         _editor ctlshort {
            p_border_style=BDS_FIXED_SINGLE;
            p_height=945;
            p_scroll_bars=SB_BOTH;
            p_tab_index=12;
            p_tab_stop=true;
            p_width=5385;
            p_x=1365;
            p_y=2835;
            p_eventtab2=_ul2_editwin;
         }
         _label ctllonglabel {
            p_alignment=AL_LEFT;
            p_auto_size=true;
            p_backcolor=0x80000005;
            p_border_style=BDS_NONE;
            p_caption="Long description:";
            p_forecolor=0x80000008;
            p_height=195;
            p_tab_index=13;
            p_width=1230;
            p_word_wrap=false;
            p_x=45;
            p_y=4065;
         }
         _editor ctllong {
            p_border_style=BDS_FIXED_SINGLE;
            p_height=1905;
            p_scroll_bars=SB_BOTH;
            p_tab_index=14;
            p_tab_stop=true;
            p_width=5385;
            p_x=1365;
            p_y=4005;
            p_eventtab2=_ul2_editwin;
         }
      }
      _sstab_container  {
         p_ActiveCaption="Files";
         p_ActiveEnabled=true;
         p_ActiveOrder=1;
         p_ActiveColor=0x80000008;
         p_ActiveToolTip='';
         _tree_view ctlfiles {
            p_after_pic_indent_x=50;
            p_backcolor=0x80000005;
            p_border_style=BDS_FIXED_SINGLE;
            p_CheckListBox=false;
            p_ColorEntireLine=false;
            p_EditInPlace=false;
            p_delay=0;
            p_forecolor=0x80000008;
            p_Gridlines=TREE_GRID_NONE;
            p_height=5100;
            p_LevelIndent=300;
            p_LineStyle=TREE_DOTTED_LINES;
            p_multi_select=MS_SIMPLE_LIST;
            p_NeverColorCurrent=false;
            p_ShowRoot=false;
            p_AlwaysColorCurrent=false;
            p_SpaceY=50;
            p_scroll_bars=SB_VERTICAL;
            p_UseFileInfoOverlays=FILE_OVERLAYS_NONE;
            p_tab_index=1;
            p_tab_stop=true;
            p_width=6615;
            p_x=90;
            p_y=120;
            p_eventtab2=_ul2_tree;
         }
         _command_button ctladd_files {
            p_auto_size=false;
            p_cancel=false;
            p_caption="Add Files...";
            p_default=false;
            p_height=345;
            p_tab_index=2;
            p_tab_stop=true;
            p_width=1530;
            p_x=60;
            p_y=5295;
         }
         _command_button ctladd_profiles {
            p_auto_size=false;
            p_cancel=false;
            p_caption="Add Profiles...";
            p_default=false;
            p_height=345;
            p_tab_index=3;
            p_tab_stop=true;
            p_width=1530;
            p_x=60;
            p_y=5700;
         }
         _command_button ctlmove_up {
            p_auto_size=false;
            p_cancel=false;
            p_caption="Move Up";
            p_default=false;
            p_height=345;
            p_tab_index=4;
            p_tab_stop=true;
            p_width=1530;
            p_x=1770;
            p_y=5295;
         }
         _command_button ctlmove_down {
            p_auto_size=false;
            p_cancel=false;
            p_caption="Move Down";
            p_default=false;
            p_height=345;
            p_tab_index=5;
            p_tab_stop=true;
            p_width=1530;
            p_x=1770;
            p_y=5700;
         }
         _command_button ctladd_folder {
            p_auto_size=false;
            p_cancel=false;
            p_caption="Add Folder...";
            p_default=false;
            p_height=345;
            p_tab_index=6;
            p_tab_stop=true;
            p_width=1530;
            p_x=3465;
            p_y=5295;
         }
         _command_button ctldelete {
            p_auto_size=false;
            p_cancel=false;
            p_caption="Delete";
            p_default=false;
            p_height=345;
            p_tab_index=7;
            p_tab_stop=true;
            p_width=1530;
            p_x=3465;
            p_y=5700;
         }
      }
      _sstab_container  {
         p_ActiveCaption="Properties";
         p_ActiveEnabled=true;
         p_ActiveOrder=2;
         p_ActiveColor=0x80000008;
         p_ActiveToolTip='';
         _editor ctlproperties {
            p_border_style=BDS_FIXED_SINGLE;
            p_height=5445;
            p_scroll_bars=SB_BOTH;
            p_tab_index=1;
            p_tab_stop=true;
            p_width=6630;
            p_x=90;
            p_y=90;
            p_eventtab2=_ul2_editwin;
         }
         _command_button ctladd_properties {
            p_auto_size=false;
            p_cancel=false;
            p_caption="Add Properties...";
            p_default=false;
            p_height=345;
            p_tab_index=2;
            p_tab_stop=true;
            p_width=1530;
            p_x=105;
            p_y=5655;
         }
      }
   }
   _command_button ctlsave {
      p_auto_size=false;
      p_cancel=false;
      p_caption="Save";
      p_default=false;
      p_height=345;
      p_tab_index=6;
      p_tab_stop=true;
      p_width=1125;
      p_x=180;
      p_y=7050;
   }
   _command_button ctlsaveas {
      p_auto_size=false;
      p_cancel=false;
      p_caption="Save As...";
      p_default=false;
      p_height=345;
      p_tab_index=7;
      p_tab_stop=true;
      p_width=1125;
      p_x=1440;
      p_y=7050;
   }
   _command_button ctlcancel {
      p_auto_size=false;
      p_cancel=true;
      p_caption="Cancel";
      p_default=false;
      p_height=345;
      p_tab_index=8;
      p_tab_stop=true;
      p_width=1125;
      p_x=3360;
      p_y=7035;
   }
}

_command void plugin_new() name_info(','VSARG2_REQUIRES_PRO_EDITION) {
   show('-xy _create_plugin_form');
}

_command void plugin_open(_str filename='') name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION) {
   if (filename=='') {
      _str result2=p_active_form._OpenDialog('-new -modal',
           'Open Plugin Zip',
           '',     // Initial wildcards
           "Plugin Files (*.zip)",
           0,
           '',      // Default extensions
           '', // Initial filename
           '',      // Initial directory
           '',      // Reserved
           "Open dialog box"
           );
      if (result2=='') return;
      result2=strip(result2,'B','"');
      filename=absolute(result2);
   } else {
      filename=parse_file(filename);
   }
   if (!file_exists(filename)) {
      _message_box(nls("File '%s' not found",filename));
      return;
   }
   show('-xy _create_plugin_form',filename);
}

defeventtab _create_plugin_form;

void ctlversion.on_change() {
   PUSER_PLUGIN_MODIFIED(true);
}
void ctlpluginname.on_change() {
   PUSER_PLUGIN_MODIFIED(true);
}
static bool PUSER_PLUGIN_MODIFIED(...) {
   if (arg()) ctlcancel.p_user=arg(1);
   return ctlcancel.p_user;
}

static typeless PUSER_IN_ON_CHANGE(...) {
   if (arg()) ctldelete.p_user=arg(1);
   return ctldelete.p_user;
}
static int PUSER_ORIG_PLUGIN_XML(...) { 
   if (arg()) ctlsaveas.p_user=arg(1);
   if (!isinteger(ctlsaveas.p_user)) {
      return -1;
   }
   return ctlsaveas.p_user; 
}

static int PUSER_ORIG_PLUGIN_ZIP_FILENAME(...) { 
   if (arg()) ctlsave.p_user=arg(1);
   return ctlsave.p_user; 
}

void ctlsave.on_create(_str zip_or_plugin_xml='') {
   ctlcategories.p_newline="\n";// Unix EOL character
   ctlcategories._delete_line();
   ctlcategories.insert_line('');
   ctlshort.p_newline="\n";// Unix EOL character
   ctlshort._delete_line();
   ctlshort.insert_line('');
   ctllong.p_newline="\n";// Unix EOL character
   ctllong._delete_line();
   ctllong.insert_line('');

   //zip_or_plugin_xml='f:\f\vmacros\user_clark.macros.ver.1.0.zip\user_clark.macros.ver.1.0\plugin.xml';
   //zip_or_plugin_xml='f:\f\vmacros\user_clark.macros.ver.1.0.zip';
   if (zip_or_plugin_xml!='') {
      zip_or_plugin_xml=absolute(zip_or_plugin_xml);
   }
   pluginName := "";
   _str zip_or_dir=zip_or_plugin_xml;
   plugin_xml_filename := "";
   if (zip_or_plugin_xml!='') {
      plugin_xml_filename=zip_or_plugin_xml;
      bool is_zip=pos('zip':+FILESEP,zip_or_dir,1,_fpos_case) || pos('jar':+FILESEP,zip_or_dir,1,_fpos_case);
      if (_file_eq(_strip_filename(zip_or_dir,'p'),PLUGIN_INFO_FILE)) {
         zip_or_dir=_strip_filename(zip_or_dir,'n');
         if (_last_char(zip_or_dir)==FILESEP) {
            zip_or_dir= substr(zip_or_dir,1,length(zip_or_dir)-1);
            if (is_zip) {
               zip_or_dir=_strip_filename(zip_or_dir,'n');
               if (_last_char(zip_or_dir)==FILESEP) {
                  zip_or_dir= substr(zip_or_dir,1,length(zip_or_dir)-1);
                  //zip_or_dir=_strip_filename(zip_or_dir,'n');
               } else {
                  _message_box(nls("Plugin zip file '%s1' has incorrect plugin structure. Not enough directories",plugin_xml_filename));
                  return;
               }
            }
         } else {
            _message_box(nls("Plugin zip file '%s1' has incorrect plugin structure. Not enough directories",plugin_xml_filename));
            return;
         }
      }
      ext:=get_extension(zip_or_dir);
      if (_file_eq(ext,'zip') || _file_eq(ext,'jar')) {
         pluginName=_strip_filename(zip_or_dir,'pe');
         i:=pos('.ver.',pluginName,1,_fpos_case);
         if (i>0) {
             if (!file_exists(zip_or_dir:+FILESEP:+pluginName)) {
                // Assume this has an unversioned interior directory
                pluginName=substr(pluginName,1,i-1);
             }
         }
         plugin_xml_filename=zip_or_dir:+FILESEP:+pluginName:+FILESEP:+PLUGIN_INFO_FILE;
         PUSER_ORIG_PLUGIN_ZIP_FILENAME(absolute(zip_or_dir,true));
      } else {
         // Must be a directory
         pluginName=_strip_filename(zip_or_dir,'p');
         plugin_xml_filename=zip_or_dir:+FILESEP:+PLUGIN_INFO_FILE;
      }
      if (!file_exists(plugin_xml_filename)) {
         _message_box(nls("Plugin zip file '%s1' has incorrect plugin structure. plugin.xml is missing",plugin_xml_filename));
         return;
      }
      handle:=_xmlcfg_open(plugin_xml_filename,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
      if (handle>=0) {
         PUSER_ORIG_PLUGIN_XML(handle);
         node:=_xmlcfg_find_simple(handle,"/options/plugin");
         if (node>=0) {
            ctltitle.p_text=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_TITLE);
            ctlforum_url.p_text=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_FORUM_URL);
            ctlmin_ver.p_text=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_MIN_VER);
            ctlmax_ver.p_text=_xmlcfg_get_attribute(handle,node,PLUGIN_ATTR_MAX_VER);
            //_xmlcfg_add_child_text
            int temp;
            temp=_xmlcfg_find_simple(handle,"/options/plugin/":+PLUGIN_ELEMENT_CAT);
            if (temp>=0) {
               ctlcategories._insert_text(_xmlcfg_get_text(handle,temp));
            }
            temp=_xmlcfg_find_simple(handle,"/options/plugin/":+PLUGIN_ELEMENT_SHORT);
            if (temp>=0) {
               ctlshort._insert_text(_xmlcfg_get_text(handle,temp));
            }
            temp=_xmlcfg_find_simple(handle,"/options/plugin/":+PLUGIN_ELEMENT_LONG);
            if (temp>=0) {
               ctllong._insert_text(_xmlcfg_get_text(handle,temp));
            }
            _xmlcfg_delete(handle,node);
         }
      }
   }
   ctlcategories.p_spell_check_while_typing=true;
   ctlshort.p_spell_check_while_typing=true;
   ctlshort.p_SoftWrap=true;ctlshort.p_SoftWrapOnWord=true;
   ctllong.p_spell_check_while_typing=true;
   ctllong.p_SoftWrap=true;ctllong.p_SoftWrapOnWord=true;

   if ( pluginName!='') {
      parse  pluginName with auto name '.ver.' auto ver;
      ctlversion.p_text=ver;
      ctlpluginname.p_text=name;
   }
   if (ctlversion.p_text=='') {
      ctlversion.p_text='1.0';
   }
   ctlproperties.p_newline="\n";// Unix EOL character
   ctlproperties._delete_line();
   handle:=PUSER_ORIG_PLUGIN_XML();
   if (handle>=0) {
      _xmlcfg_save_to_buffer(ctlproperties,handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
      //ctlproperties._insert_text(result);
   } else {
      ctlproperties._insert_text("<options>\n</options>");
   }
   ctlproperties._SetEditorLanguage('xml');
   initFilesTab(plugin_xml_filename);
   /*if (PUSER_ORIG_PLUGIN_ZIP_FILENAME()=='') {
      ctlsave.p_enabled=false;
   } */
   PUSER_PLUGIN_MODIFIED(false);ctlcategories.p_modify=false;ctlshort.p_modify=false;ctllong.p_modify=false;
}
static void replace_plugin_text(int handle,int node,_str element_name,int editorctl_wid) {
   int temp;
   temp=_xmlcfg_find_simple(handle,"/options/plugin/"element_name);
   if (temp>=0) {
      _xmlcfg_delete(handle,temp);
   }
   text := editorctl_wid.get_text(editorctl_wid.p_buf_size,0);
   text=strip(text);
   text=strip(text,'B',"\n");
   text=strip(text);
   text=strip(text,'B',"\n");
   if (text=='') {
      return;
   }
   node=_xmlcfg_set_path(handle,"/options/plugin/"element_name);
   _xmlcfg_add_child_text(handle,node,text);
}
static int recurse_tree_files(int index, _str (&files)[], _str (&archive_files)[], _str (&temp_files)[],_str relPath,int plugin_handle,int files_node) {
   index=_TreeGetFirstChildIndex(index);
   while (index>=0) {
      if (isFolder(index)) {
         _str newRelPath=relPath;
         if (newRelPath!='') {
            newRelPath :+= _TreeGetCaption(index):+FILESEP;
         } else {
            newRelPath=_TreeGetCaption(index):+FILESEP;
         }
         reldir_node:=_xmlcfg_add(plugin_handle,files_node,'dir',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(plugin_handle,reldir_node,'n',_TreeGetCaption(index));
         if(recurse_tree_files(index,files,archive_files,temp_files,newRelPath,plugin_handle,reldir_node)) {
            return 1;
         }
      } else {
         _GetFileUserData(index,auto from, auto file);
         _str newFile='';
         if (from==FROM_FILE) {
            if (!_file_eq(_strip_filename(file,'p'),PLUGIN_INFO_FILE)) {
               files[files._length()]=file;
               newFile=_TreeGetCaption(index);
               archive_files[archive_files._length()]= relPath:+newFile;
            }
         } else {
            // Must be a profile
            epath:=_plugin_get_profile_package(file);
            profileName:=_plugin_get_profile_name(file);
            int handle=_plugin_get_profile(epath,profileName);
            if (handle<0) {
               _message_box(nls("Unable to fetch profile '%s'",file));
               return 1;
            }
            int handle2=_xmlcfg_create('',VSENCODING_UTF8);
            int options_node=_xmlcfg_add(handle2,0,'options',VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
            int profile_node=_xmlcfg_copy(handle2,options_node,handle,_xmlcfg_get_document_element(handle),VSXMLCFG_COPY_AS_CHILD);
            _xmlcfg_apply_profile_style(handle2,options_node);

            _str temp=mktemp();
            temp_files[temp_files._length()]=temp;
            status:=_xmlcfg_save(handle2,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE,temp);
            _xmlcfg_close(handle2);
            _xmlcfg_close(handle);
            if (status) {
               _message_box(nls("Unable to save xml file to '%s'",temp));
               return 1;
            }
            files[files._length()]=temp;
            newFile=_TreeGetCaption(index);
            archive_files[archive_files._length()]= relPath:+newFile;
         }
         if (newFile!='') {
            f_node:=_xmlcfg_add(plugin_handle,files_node,'f',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_set_attribute(plugin_handle,f_node,'n',newFile);
         }
      }
      index=ctlfiles._TreeGetNextSiblingIndex(index);
   }
   return 0;

}
static int create_plugin_zip_file(_str filename) {
   relPath := _strip_filename(filename,'pe'):+FILESEP;
   int plugin_handle;
   plugin_handle=_xmlcfg_open_from_buffer(ctlproperties,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
   if (plugin_handle<0) {
      _message_box('Properites XML is invalid. Please fix');
      ctlproperties.xml_wellformedness();
      return 1;
   }
   int node;
   node=_xmlcfg_set_path(plugin_handle,"/options/plugin");
   _xmlcfg_delete(plugin_handle,node);
   node=_xmlcfg_set_path(plugin_handle,"/options");
   int orig_handle=PUSER_ORIG_PLUGIN_XML();
   plugin_node := -1;
   if (orig_handle>=0) {
      plugin_node=_xmlcfg_find_simple(plugin_handle,"/options/plugin");
      if (plugin_node>=0) {
         _xmlcfg_copy(plugin_handle,node,orig_handle,plugin_node,VSXMLCFG_COPY_AS_FIRST_CHILD);
      }
   }
   if (plugin_node<0) {
      node=_xmlcfg_set_path(plugin_handle,"/options/plugin");
   }

   if (ctltitle.p_text!='') {
      _xmlcfg_set_attribute(plugin_handle,node,PLUGIN_ATTR_TITLE,ctltitle.p_text);
   } else {
      _xmlcfg_delete_attribute(plugin_handle,node,PLUGIN_ATTR_TITLE);
   }
   if (ctlforum_url.p_text!='') {
      _xmlcfg_set_attribute(plugin_handle,node,PLUGIN_ATTR_FORUM_URL,ctlforum_url.p_text);
   } else {
      _xmlcfg_delete_attribute(plugin_handle,node,PLUGIN_ATTR_FORUM_URL);
   }
   if (ctlmin_ver.p_text!='') {
      _xmlcfg_set_attribute(plugin_handle,node,PLUGIN_ATTR_MIN_VER,ctlmin_ver.p_text);
   } else {
      _xmlcfg_delete_attribute(plugin_handle,node,PLUGIN_ATTR_MIN_VER);
   }
   if (ctlmax_ver.p_text!='') {
      _xmlcfg_set_attribute(plugin_handle,node,PLUGIN_ATTR_MAX_VER,ctlmax_ver.p_text);
   } else {
      _xmlcfg_delete_attribute(plugin_handle,node,PLUGIN_ATTR_MAX_VER);
   }
   replace_plugin_text(plugin_handle,node,PLUGIN_ELEMENT_CAT,ctlcategories);
   replace_plugin_text(plugin_handle,node,PLUGIN_ELEMENT_SHORT,ctlshort);
   replace_plugin_text(plugin_handle,node,PLUGIN_ELEMENT_LONG,ctllong);
   
   _str temp_files[];
   orig_filename := "";
   _xmlcfg_apply_profile_style(plugin_handle,_xmlcfg_get_document_element(plugin_handle));
   if (_file_eq(absolute(filename,true),PUSER_ORIG_PLUGIN_ZIP_FILENAME())) {
      // Need to write to a temp file
      orig_filename=filename;
      filename=mktemp(1,'.zip');
      temp_files[temp_files._length()]=filename;
   }
   _str files[];
   _str archive_files[];

   
   files_node:=_xmlcfg_set_path(plugin_handle,"/options/plugin/files");
   /*{
      foreach (auto i=>auto v in files) {
         say('i='i' f='files[i]' a='archive_files[i]);
      }
      say(filename);
   }*/

   ctlfiles.recurse_tree_files(ctlfiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX),files,archive_files,temp_files,relPath,plugin_handle,files_node);

   _str temp=mktemp();
   temp_files[temp_files._length()]=temp;
   files[files._length()]=temp;
   newFile:=relPath:+PLUGIN_INFO_FILE;
   archive_files[archive_files._length()]=newFile;

   // Add plugin.xml as last file
   f_node:=_xmlcfg_add(plugin_handle,files_node,'f',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(plugin_handle,f_node,'n',PLUGIN_INFO_FILE);

   status=_xmlcfg_save(plugin_handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE,temp);
   _xmlcfg_close(plugin_handle);
   if (status) {
      _message_box(nls("Unable to save xml file to '%s'",temp));
      status=1;
   } else {
      int zipStatus[];
      _ZipClose(filename);
      status=_ZipCreate(filename,files,zipStatus,archive_files);
      if (status) {
         _message_box(nls("Unable to create zip file '%s'",filename));
         status=1;
      } else {
         status=-1;
         foreach (auto i=>auto v in zipStatus) {
            if (v) {
               status=i;
               break;
            }
         }
         if (status>=0) {
            _message_box(nls("Unable to add file %s to zip file",files[status]));
         } else {
            if (orig_filename!='') {
               _ZipClose(orig_filename);
               status=copy_file(filename,orig_filename);
               if (status) {
                  _message_box(nls("Unable to create zip file '%s'",orig_filename));
                  status=1;
               } else {
                  status=-1;
               }
            }
         }
      }
      PUSER_PLUGIN_MODIFIED(false);ctlcategories.p_modify=false;ctlshort.p_modify=false;ctllong.p_modify=false;
   }

   foreach (auto i=>auto v in temp_files) {
      delete_file(v);
   }
   if (status>=0) {
      return 1;
   }
   return 0;
}
void ctlcancel.lbutton_up() {
   if (PUSER_PLUGIN_MODIFIED() || ctlcategories.p_modify || ctlshort.p_modify || ctllong.p_modify) {
      result:=_message_box('Throw away changes?','',MB_YESNOCANCEL);
      if (result!=IDYES) {
         return;
      }
   }
   p_active_form._delete_window('');
}
static bool validate_prefix_id(_str prefix_id) {
   if (substr(prefix_id,1,5)!='user_') {
      return false;
   }
   rest:=substr(prefix_id,6);
   if (!pos('[a-zA-Z][a-zA-Z0-9]#',rest,1,'r')) {
      return false;
   }
   return pos('')==length(rest);
}
static int _plgman_get_prefix_id(_str &prefix_id) {
   errorMsg:="Plugin name must be in the form \"<b>user_&lt;forum-login-userid&gt;.&lt;plugin-name&gt;</b>\". \"<b>user_&lt;forum-login-userid&gt;</b>\" is your plugin prefix id used to avoid name collisions. <b>forum-login-userid</b> must start with a letter and and contain letters and digits (i.e. [a-zA-Z][a-zA-Z0-9]+). <br><br>If you plan on making your plugin available to everyone, create a forum login user id containing letters and digits. Otherwise, just make up a <b>forum-login-userid</b>.<br><br>For example, if your forum user id is \"<b>clark</b>\", a valid plugin name would be \"<b>user_clark.Color Profile Foo</b>\".<br><br>Use the plugin prefix id as a namespace (i.e <b>prefixid.id</b> when possible) to prefix global identifiers in your plugin to avoid name collisions with other plugins. Commands, and global functions can be put in a Slick-C namespace. Profile names should be prefixed like a namespace (i.e \"<b>prefixid.ProfileName</b>\"). If you modify a built-in profile that supports being copied (i.e color profile, beautifier profile, etc.), make a copy and give it a unique name. You will need to use \"<b>prefixid_&lt;name&gt;</b>\" for forms, menus, and event tables for now since they don't support namespaces yet.<br><br>You can create a forum topic for a plugin so users can add posts about your plugin and know more about you.";
   if (ctlpluginname.p_text=='') {
      show('-xy _plugin_name_help_form',"No plugin name specified<br><br>":+errorMsg);
      return 1;
   }
   parse ctlpluginname.p_text with prefix_id '.' auto name;
   if (!validate_prefix_id(prefix_id) || prefix_id=='' || name=='' ) {
      show('-xy _plugin_name_help_form',errorMsg);
      return 1;
   }
   return 0;
}
static bool do_save_as() {
   if(_plgman_get_prefix_id(auto prefix_id)) {
      return true;
   }
   plugin_file := ctlpluginname.p_text;
   version := ctlversion.p_text;
   if (version=='') version="1.0";
   strappend(plugin_file,".ver.":+version".zip");

   _str result=p_active_form._OpenDialog('-new -modal',
        'Save Plugin As',
        '',     // Initial wildcards
        "Plugin Files (*.zip)",
        OFN_SAVEAS,
        '',      // Default extensions
        plugin_file, // Initial filename
        '',  // Initial directory
        '',      // Reserved
        "Save As dialog box"
        );
   if (result=='') return true;
   result=absolute(result);
   if(!_file_eq(get_extension(result),'zip')) {
      strappend(result,'.zip');
   }
   if(create_plugin_zip_file(result)) {
      return true;
   }
   return false;
}
void ctlsave.lbutton_up() {
   if (PUSER_ORIG_PLUGIN_ZIP_FILENAME()=='') {
      if(do_save_as()) {
         return;
      }
      p_active_form._delete_window(1);
      return;
   }
   if(_plgman_get_prefix_id(auto prefix_id)) {
      return;
   }
   if(create_plugin_zip_file(PUSER_ORIG_PLUGIN_ZIP_FILENAME())) {
      return;
   }
   p_active_form._delete_window(1);
}
void ctlsaveas.lbutton_up() {
   if(do_save_as()) {
      return;
   }
   p_active_form._delete_window(1);
}
void ctlsave.on_destroy() {
   handle:=PUSER_ORIG_PLUGIN_XML();
   if (handle>=0) {
      _xmlcfg_close(handle);
   }
}
const FROM_FILE='f';
const FROM_PROFILE='p';
static void _SetFileUserData(int child_index,_str from_type,_str file) {
   ctlfiles._TreeSetUserInfo(child_index,from_type"\t"file);
}
static void _GetFileUserData(int child_index,_str &from_type,_str &file) {
   parse _TreeGetUserInfo(child_index) with from_type "\t" file;
}
static void initFilesTabChildren(_str path,int parent_index,_str parent_reldir,int plugin_xml_handle,int plugin_xml_parent_node) {
   _str files:[];
   name:=file_match(path:+'*',1);
   while (name!='') {
      ext:=get_extension(name);
      if (!_file_eq(ext,'ex') /*&& !file_eq(_strip_filename(name,'p'),PLUGIN_INFO_FILE)*/) {
         name=substr(name,length(path)+1);
         files:[_file_case(name)]=name;
      }
      name=file_match(path,0);
   }

   if (plugin_xml_handle>=0 && plugin_xml_parent_node>=0) {
      node:=_xmlcfg_get_first_child(plugin_xml_handle,plugin_xml_parent_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      while (node>=0) {
         name=_xmlcfg_get_attribute(plugin_xml_handle,node,'n');
         if (_xmlcfg_get_name(plugin_xml_handle,node)=='dir') {
            files._deleteel(_file_case(name):+FILESEP);
            child_index:=ctlfiles._TreeAddItem(parent_index,name,TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_EXPANDED);
            new_parent_reldir:=parent_reldir:+name:+'/';
            initFilesTabChildren(path:+name:+FILESEP,child_index,new_parent_reldir,plugin_xml_handle,node);
         } else {
            files._deleteel(_file_case(name));
            child_index:=ctlfiles._TreeAddItem(parent_index,_strip_filename(name,'p'),TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
            _SetFileUserData(child_index,FROM_FILE,path:+name);
         }
         node=_xmlcfg_get_next_sibling(plugin_xml_handle,node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      }
   }
   foreach (auto i=>name in files) {
      if (_last_char(name)==FILESEP) {
         name=substr(name,1,length(name)-1);
         name=_strip_filename(name,'p');
         if (name!='.'  && name!='..') {
            child_index:=ctlfiles._TreeAddItem(parent_index,name,TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_EXPANDED);
            new_parent_reldir:=parent_reldir:+name:+'/';
            initFilesTabChildren(path:+name:+FILESEP,child_index,new_parent_reldir,-1,-1);
         }
      } else {
         child_index:=ctlfiles._TreeAddItem(parent_index,_strip_filename(name,'p'),TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
         _SetFileUserData(child_index,FROM_FILE,path:+name);
      }
   }
}
static void initFilesTab(_str plugin_xml_filename) {
   parent_index:=ctlfiles._TreeAddItem(TREE_ROOT_INDEX,'<Plugin>',TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_EXPANDED);
   if (plugin_xml_filename=='') {
      return;
   }
   _str ordered_array[];
   plugin_xml_handle:=_xmlcfg_open(plugin_xml_filename,auto status);
   int plugin_xml_parent_node=-1;
   if (plugin_xml_handle>=0) {
      plugin_xml_parent_node=_xmlcfg_find_simple(plugin_xml_handle,"/options/plugin/files");
   }
   path:=_strip_filename(plugin_xml_filename,'n');
   initFilesTabChildren(path,parent_index,'',plugin_xml_handle,plugin_xml_parent_node);
   if (plugin_xml_handle>=0) {
      _xmlcfg_close(plugin_xml_handle);
   }
}

void _create_plugin_form.on_resize() {

   tab_container:=ctlsstab1.p_child;
   int width=_dx2lx(SM_TWIP,p_active_form.p_client_width)-ctlsstab1.p_x*2;
   if (width<200) width=200;
   ctlsstab1.p_width= width;
   int height;
   height=_dy2ly(SM_TWIP,p_active_form.p_client_height)-ctlsstab1.p_y-100-ctlsave.p_height-100;
   if (height<200) height=200;
   ctlsstab1.p_height=height;

   ctlsave.p_y=ctlsaveas.p_y=ctlcancel.p_y=ctlsstab1.p_y+height+100;

   width=tab_container.p_width;
   int editorctl_width= width-ctlcategories.p_x-60;
   if (editorctl_width<200) editorctl_width=200;
   ctlcategories.p_width=ctlshort.p_width=ctllong.p_width=editorctl_width;
   ctllong.p_y_extent = tab_container.p_height-60;
   int forum_url_width= width-ctlforum_url.p_x-60;
   if (forum_url_width<200) forum_url_width=200;
   ctlforum_url.p_width=ctltitle.p_width=forum_url_width;

   int properties_width=width-ctlproperties.p_x*2;
   if (properties_width<200) properties_width=200;
   ctlproperties.p_width=properties_width;
   int properties_height=tab_container.p_height-ctlproperties.p_y-100-ctladd_properties.p_height-100;
   if (properties_height<200) properties_height=200;
   ctlproperties.p_height=properties_height;
   ctladd_properties.p_y=ctlproperties.p_y+properties_height+100;

   int files_width=width-ctlfiles.p_x*2;
   if (files_width<200) files_width=200;
   ctlfiles.p_width=files_width;

   int files_height=tab_container.p_height-ctlfiles.p_y-100-ctladd_files.p_height*2-100*2;
   if (files_height<200) files_height=200;
   ctlfiles.p_height=files_height;
   ctladd_files.p_y=ctlmove_up.p_y=ctladd_folder.p_y=ctlfiles.p_y+files_height+100;
   ctladd_profiles.p_y=ctlmove_down.p_y=ctldelete.p_y=ctladd_files.p_y_extent+100;
}

void ctladd_files.lbutton_up() {
   prefix_id := "";
   if (_plgman_get_prefix_id(prefix_id)) {
      return;
   }

   _str result;
   result=_OpenDialog('-new -mdi -modal',
                                 'Add Files',
                                 '*.e;*.sh',     // Initial wildcards
                                 'All Files (*.*), Slick-C (*.e;*.sh),XML Config Files (*.cfg.xml)',  // file types
                                 OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,
                                 // Specifying a default extension on Windows does nothing here.
                                 // Specifying a default extension on Unix causes a bug where can't
                                 // press Enter on a directory name to change directory. These problems 
                                 // maybe because  this is an Open dialog and not a Save as dialog.
                                 // OFN_FILEMUSTEXIST) has been specified.
                                 '', //WORKSPACE_FILE_EXT,    // Default extensions
                                 '',      // Initial filename
                                 '',      // Initial directory
                                 '',      // Reserved
                                 "Open dialog box"
                                );
   if (result=='') return;


   index := ctlfiles._TreeCurIndex();
   //int depth=_TreeGetDepth(index);
   ParentState := bm1 := bm2 := 0;
   ctlfiles._TreeGetInfo(index,ParentState,bm1,bm2);
   ParentIndex := -1;
   Flags := 0;
   RelationIndex := -1;
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      ParentIndex=index;
      Flags=TREE_ADD_AS_CHILD;
      RelationIndex=ParentIndex;
   }else{
      ParentIndex=ctlfiles._TreeGetParentIndex(index);
      RelationIndex=index;
      //No Flags, add after "RelationIndex"
   }

   for (;;) {
      if (result=='') break;
      file:=parse_file(result,false);
      if (file=='') continue;
      file=absolute(file);
      _plgman_validate_file(prefix_id,file);
      name:=_strip_filename(file,'p');
      // check to see if this file is already in there
      NewIndex:=ctlfiles._TreeSearch(TREE_ROOT_INDEX,name);
      if (NewIndex < 0) {
         // not already there, add it
         NewIndex=ctlfiles._TreeAddItem(RelationIndex,name,Flags,_pic_file,_pic_file,TREE_NODE_LEAF);
         _SetFileUserData(NewIndex,FROM_FILE,file);
      } else {
         ParentIndex=ctlfiles._TreeGetParentIndex(NewIndex);
         ctlfiles._TreeGetInfo(NewIndex,ParentState,bm1,bm2);
      }
      PUSER_PLUGIN_MODIFIED(true);

      if (ParentState!=TREE_NODE_EXPANDED) {
         ctlfiles._TreeSetInfo(ParentIndex,TREE_NODE_EXPANDED);
      }
      ctlfiles._TreeSetCurIndex(NewIndex);
   }
   ctlfiles.call_event(CHANGE_SELECTED,ctlfiles._TreeCurIndex(),ctlfiles,ON_CHANGE,'W');
}
static bool gProfileMustBeIdentifier:[]= {
   'language'=>true,
};
void ctladd_profiles.lbutton_up() {
   prefix_id := "";
   if (_plgman_get_prefix_id(prefix_id)) {
      return;
   }
   result:=p_active_form.show('-modal -wh _plugin_add_profiles',false);
   if (result=='') return;


   index := ctlfiles._TreeCurIndex();
   //int depth=_TreeGetDepth(index);
   ParentState := bm1 := bm2 := 0;
   ctlfiles._TreeGetInfo(index,ParentState,bm1,bm2);
   ParentIndex := -1;
   Flags := 0;
   RelationIndex := -1;
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      ParentIndex=index;
      Flags=TREE_ADD_AS_CHILD;
      RelationIndex=ParentIndex;
   }else{
      ParentIndex=ctlfiles._TreeGetParentIndex(index);
      RelationIndex=index;
      //No Flags, add after "RelationIndex"
   }

   se.messages.MessageCollection* mCollection = get_messageCollection();
   mCollection->removeMessages(PLUGIN_VALIDATION_MESSAGE_TYPE);
   mCollection->startBatch();
   errors_found := false;
   foreach (auto i=>auto epath in _param1) {
      epackage:=_plugin_get_profile_package(epath);
      profileName:=_plugin_get_profile_name(epath);
      // IF this is a new profile
      if (!_plugin_has_builtin_profile(epackage,profileName)) {
         last_ch:='.';
         if (gProfileMustBeIdentifier._indexin(lowcase(epackage))) {
            last_ch='_';
         }
         if (substr(profileName,1,length(prefix_id)+1):!=prefix_id:+last_ch) {
            errors_found=true;
            se.messages.Message tmpMsg;
            tmpMsg.m_creator = PLUGIN_VALIDATION_MESSAGE_TYPE;
            tmpMsg.m_type = "Warning";
            tmpMsg.m_description = nls("Profile name '%s1' in package '%s2' should start with prefix id '%s3'",profileName,epackage,prefix_id:+last_ch);
            tmpMsg.m_sourceFile = '';
            tmpMsg.m_lineNumber = 1;
            tmpMsg.m_colNumber = 1;
            tmpMsg.m_date = "";
            mCollection->newMessage(tmpMsg);
         }

      }
      name:=_plugin_encode_filename(epath):+VSCFGFILEEXT_CFGXML;
      // check to see if this file is already in there
      NewIndex:=ctlfiles._TreeSearch(TREE_ROOT_INDEX,name);
      if (NewIndex < 0) {
         // not already there, add it
         NewIndex=ctlfiles._TreeAddItem(RelationIndex,name,Flags,_pic_file,_pic_file,TREE_NODE_LEAF);
         _SetFileUserData(NewIndex,FROM_PROFILE,epath);
      } else {
         ParentIndex=ctlfiles._TreeGetParentIndex(NewIndex);
         ctlfiles._TreeGetInfo(NewIndex,ParentState,bm1,bm2);
      }
      PUSER_PLUGIN_MODIFIED(true);

      if (ParentState!=TREE_NODE_EXPANDED) {
         ctlfiles._TreeSetInfo(ParentIndex,TREE_NODE_EXPANDED);
      }
      ctlfiles._TreeSetCurIndex(NewIndex);
   }
   mCollection->endBatch();
   mCollection->notifyObservers();
   if (errors_found) {
      activate_messages();
   }
   ctlfiles.call_event(CHANGE_SELECTED,ctlfiles._TreeCurIndex(),ctlfiles,ON_CHANGE,'W');
}

void ctladd_properties.lbutton_up() {
   int handle;
   handle=_xmlcfg_open_from_buffer(ctlproperties,auto status,VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA);
   if (handle<0) {
      _message_box('Properites XML is invalid. Please fix');
      ctlproperties.xml_wellformedness();
      return;
   }
   result:=p_active_form.show('-modal -wh _plugin_add_profiles',true);
   if (result=='') {
      _xmlcfg_close(handle);
      return;
   }
   last_profile_node := -1;
   last_epath := "";
   int doc_node=_xmlcfg_get_document_element(handle);


   foreach (auto i=>auto epath in _param1) {
      PUSER_PLUGIN_MODIFIED(true);
      property_name:=_plugin_get_profile_name(epath);
      epath=_plugin_get_profile_package(epath);
      if (last_epath:!=epath) {
         last_profile_node=_xmlcfg_find_profile(handle,epath);
      }
      epackage:=_plugin_get_profile_package(epath);
      profileName:=_plugin_get_profile_name(epath);
      if (last_profile_node<0) {
         last_profile_node=_xmlcfg_add(handle,doc_node,VSXMLCFG_PROFILE,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(handle,last_profile_node,VSXMLCFG_PROFILE_NAME,epath);
      }
      int property_node=_xmlcfg_find_property(handle,last_profile_node,property_name);
      if (property_node>=0) {
         _xmlcfg_delete(handle,property_node);
      }
      bool apply;
      property_xml:=_plugin_get_property_xml(epackage,profileName,property_name, apply);
      if (property_xml>=0) {
         _xmlcfg_copy(handle,last_profile_node,property_xml,_xmlcfg_get_document_element(property_xml),VSXMLCFG_COPY_AS_CHILD);
         _xmlcfg_close(property_xml);
      } else {
         // Must be a deleted property
         property_node=_xmlcfg_add(handle,last_profile_node,VSXMLCFG_DELETE, VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(handle,property_node,VSXMLCFG_PROPERTY_NAME,property_name);
      }
      //_xmlcfg_add_property(handle,node);
      //profile_name:=_plugin_get_profile_name(epath);
      //epath=_plugin_get_profile_package(epath);
   }
   ctlproperties._lbclear();

   _xmlcfg_save_to_buffer(ctlproperties,handle,-1,VSXMLCFG_SAVE_UNIX_EOL|VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
   _xmlcfg_close(handle);
}
void ctlmove_up.lbutton_up()
{
   /*if (!check_all_workspaces_sort_option()) {
      return;
   } */
   wid := p_window_id;
   p_window_id=ctlfiles;

   CurIndex := _TreeCurIndex();
   int ToIndex;
   int AddFlags;
   if(!_TreeFindMoveUp(_TreeCurIndex(),_TreeGetFirstChildIndex(TREE_ROOT_INDEX),ToIndex,AddFlags)) {
      return;
   }
   _TreeMoveItem(CurIndex,ToIndex,AddFlags);
   _set_focus();
   PUSER_PLUGIN_MODIFIED(true);
   EnableMoveButtons();
   p_window_id=wid;
}

void ctlmove_down.lbutton_up()
{
   /*if (!check_all_workspaces_sort_option()) {
      return;
   } */
   wid := p_window_id;
   p_window_id=ctlfiles;
   CurIndex := _TreeCurIndex();
   int ToIndex;
   int AddFlags;
   if(!_TreeFindMoveDown(_TreeCurIndex(),_TreeGetFirstChildIndex(TREE_ROOT_INDEX),ToIndex,AddFlags)) {
      return;
   }
   /*say('To Caption='_TreeGetCaption(ToIndex));
   if (AddFlags==TREE_ADD_BEFORE) {
      say('   TREE_ADD_BEFORE');
   } else if (AddFlags==TREE_ADD_AFTER) {
      say('   TREE_ADD_AFTER');
   } else if (AddFlags==TREE_ADD_AS_CHILD) {
      say('   TREE_ADD_AS_CHILD');
   } else if (AddFlags==TREE_ADD_AS_FIRST_CHILD) {
      say('   TREE_ADD_AS_FIRST_CHILD');
   } */
   //PUSER_IN_ON_CHANGE(1);
   _TreeMoveItem(CurIndex,ToIndex,AddFlags);
   //PUSER_IN_ON_CHANGE(0);
   _set_focus();
   PUSER_PLUGIN_MODIFIED(true);
   EnableMoveButtons();
   p_window_id=wid;
}
static bool isLeaf(int index)
{
   state := bm1 := bm2 := flags := 0;
   _TreeGetInfo(index, state, bm1, bm2);

   return (bm1 == _pic_file);
}
static int countLeafs(int index,_str &filename)
{
   count := 0;

   // go through the children
   child := _TreeGetFirstChildIndex(index);
   while (child > 0) {

      // see if it's a folder or a workspace
      if (isLeaf(child)) {
         count++;
         filename=GetCaptionName(child);
      } else {
         count += countLeafs(child,filename);
      }

      child = _TreeGetNextSiblingIndex(child);
   }

   return count;
}

static _str GetCaptionName(int index) {
   return _TreeGetCaption(index);
}

static void DeleteButton() {
   if (!ctldelete.p_enabled) {
      _beep();
      return;
   }
   //LAST_TREE_INDEX('');
   wid := p_window_id;
   p_window_id=ctlfiles;

   // get what's selected
   int selected[];
   _TreeGetSelectionIndices(selected);
   selected._sort("N");

   // how many workspaces?  maybe overkill, but we are fancy
   remainingFiles := 0;
   int status, index;
   filename := "";
   for (i := 0; i < selected._length(); i++) {
      index = selected[i];

      if (isLeaf(index)) {
         remainingFiles++;
         filename=GetCaptionName(index);
      } else {
         remainingFiles += countLeafs(index,filename);
      }
   }
   int result;
   if (remainingFiles==0) {
      result=IDYES;
   } else if (remainingFiles<=1) {
      result=_message_box("Remove "filename"?",'',MB_YESNOCANCEL);
   } else {
      result=_message_box(nls("Remove %s1 files",remainingFiles),'',MB_YESNOCANCEL);
   }
   if (result==IDYES) {
      for (i = 0; i < selected._length(); i++) {
         index = selected[i];

         // find out if it's a folder or a workspace file
         _TreeDelete(index);
         PUSER_PLUGIN_MODIFIED(true);
      }

      p_window_id=wid;
      ctlfiles._set_focus();
   }
   index=ctlfiles._TreeCurIndex();
   if (index<=0) {
      index=ctlfiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (index>=0) {
         ctlfiles._TreeSetCurIndex(index);
      }
   }

}

void ctlfiles.del()
{
   DeleteButton();
}

void ctldelete.lbutton_up()
{
   DeleteButton();
}

static void AddFolderButton()
{
   index := _TreeCurIndex();
   //int depth=_TreeGetDepth(index);
   ParentState := bm1 := bm2 := 0;
   _TreeGetInfo(index,ParentState,bm1,bm2);
   ParentCaption := "";
   ParentIndex := -1;
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      ParentCaption=_TreeGetCaption(index);
      ParentIndex=index;
   }else{
      ParentIndex=_TreeGetParentIndex(index);
      ParentCaption=_TreeGetCaption(ParentIndex);
   }
   typeless result=show('-modal _textbox_form',
               'New Folder Name',
               0,   // flags
               '',                           // width ('' or 0 uses default)
               'New Folder Name dialog',     // Optional help item
               '',                           // Buttons and captions
               '',                           // Retrieve name
               'New Folder Name:'
               );
   if (result=='') return;
   if (_param1=='') return;
   _str NewFolderName=_param1;

   if (pos('[\[\]\:\\/<>|;,\t"'']',NewFolderName,1,'r')) {
      _message_box('Invalid characters if folder name');
      return;
   }

   // add folder after the last folder index
   LastFolderIndex := 0;
   index = _TreeGetFirstChildIndex(ParentIndex);
   while (index >= 0) {
      if (isFolder(index)) LastFolderIndex=index;
      index = _TreeGetNextSiblingIndex(index);
   }
   NewFolderIndex := 0;
   if (LastFolderIndex > 0) {
      NewFolderIndex = _TreeAddItem(LastFolderIndex,NewFolderName,TREE_ADD_AFTER,_pic_fldclos,_pic_fldopen,TREE_NODE_EXPANDED);
   } else {
      NewFolderIndex = _TreeAddItem(ParentIndex,NewFolderName,TREE_ADD_AS_FIRST_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_EXPANDED);
   }
   if (ParentState!=TREE_NODE_EXPANDED) {
      _TreeSetInfo(ParentIndex,TREE_NODE_EXPANDED);
   }
   _TreeSetCurIndex(NewFolderIndex);
   PUSER_PLUGIN_MODIFIED(true);
   _set_focus();
}
void ctladd_folder.lbutton_up()
{
   ctlfiles.AddFolderButton();
   //ctlfiles.maybe_make_column_width_bigger(0);
}
static bool isFolder(int index) {
   if (index==TREE_ROOT_INDEX) return true;
   /*int child_index=_TreeGetFirstChildIndex(index);
   if (child_index>=0) {
      return true;
   } */
   state := bm1 := bm2 := flags := 0;
   _TreeGetInfo(index,state,bm1,bm2);
   if (bm1==_pic_fldclos || bm1==_pic_fldopen) {
      return true;
   }
   return false;
}
/*static void EnableMoveToFolderButton() {
   // get what's selected
   common_parent := -1;
   int selected[];
   _TreeGetSelectionIndices(selected);

   for (i := 0; i < selected._length(); i++) {
      if ( isFolder(selected[i]) ) {
         ctlmove.p_enabled=false;
         return;
      }
      if (common_parent >= 0 && _TreeGetParentIndex(selected[i]) != common_parent) {
         ctlmove.p_enabled=false;
         return;
      }
      common_parent = _TreeGetParentIndex(selected[i]);
   }

   ctlmove.p_enabled=true;
} */

static bool areMultipleItemsSelected()
{
   index := _TreeGetNextSelectedIndex(1, auto info);
   if (index < 0) return false;

   // see if there is a second selection
   index = _TreeGetNextSelectedIndex(0, info);
   return index > 0;
}
static void EnableMoveButtons()
{
   if (areMultipleItemsSelected()) {
      //ctlmove.p_enabled=false;
      ctlmove_up.p_enabled=false;
      ctlmove_down.p_enabled=false;
      //ctlfiles.EnableMoveToFolderButton();
   } else {
      ctlmove_down.p_enabled=ctlfiles._TreeFindMoveDown(ctlfiles._TreeCurIndex(),ctlfiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX),auto ToIndex,auto AddFlags);
      ctlmove_up.p_enabled=ctlfiles._TreeFindMoveUp(ctlfiles._TreeCurIndex(),ctlfiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX),ToIndex,AddFlags);

      //ctlmove.p_enabled = (ctlfiles._TreeCurIndex() != ctlfiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX));
   }
}
static void EnableDeleteButton()
{
   // get what's selected
   common_parent := -1;
   int selected[];
   _TreeGetSelectionIndices(selected);

   for (i := 0; i < selected._length(); i++) {
      if (selected[i] == _TreeGetFirstChildIndex(TREE_ROOT_INDEX) /*||
          FindWorkspaceInTree(selected[i],_workspace_filename) > 0 */) {
         ctldelete.p_enabled=false;
         return;
      }
      if (common_parent >= 0 && _TreeGetParentIndex(selected[i]) != common_parent) {
         ctldelete.p_enabled=false;
         return;
      }
      common_parent = _TreeGetParentIndex(selected[i]);
   }

   ctldelete.p_enabled=true;
}


void ctlfiles.on_change(int reason,int index)
{
   if (PUSER_IN_ON_CHANGE()==1) return;
   PUSER_IN_ON_CHANGE(1);
   switch (reason) {
   case CHANGE_SELECTED:
      //EnabledOpenButton();
      EnableMoveButtons();
      EnableDeleteButton();
      break;
   case CHANGE_LEAF_ENTER:
      //ctlopen.call_event(ctlopen,LBUTTON_UP);
      return;//Have to return here because dialog is deleted
   }
   PUSER_IN_ON_CHANGE(0);
}


_form _plugin_add_profiles {
   p_backcolor=0x80000005;
   p_border_style=BDS_SIZABLE;
   p_caption="Add Profiles";
   p_forecolor=0x80000008;
   p_height=5580;
   p_width=6000;
   p_x=30585;
   p_y=5235;
   p_eventtab=_plugin_add_profiles;
   _combo_box ctlfilter {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_case_sensitive=false;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=300;
      p_style=PSCBO_NOEDIT;
      p_tab_index=1;
      p_tab_stop=true;
      p_width=2850;
      p_x=45;
      p_y=105;
      p_eventtab2=_ul2_combobx;
   }
   _tree_view ctltree1 {
      p_after_pic_indent_x=50;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_CheckListBox=false;
      p_ColorEntireLine=false;
      p_EditInPlace=false;
      p_delay=0;
      p_forecolor=0x80000008;
      p_Gridlines=TREE_GRID_NONE;
      p_height=4560;
      p_LevelIndent=300;
      p_LineStyle=TREE_DOTTED_LINES;
      p_multi_select=MS_NONE;
      p_NeverColorCurrent=false;
      p_ShowRoot=false;
      p_AlwaysColorCurrent=false;
      p_SpaceY=50;
      p_scroll_bars=SB_VERTICAL;
      p_UseFileInfoOverlays=FILE_OVERLAYS_NONE;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=5895;
      p_x=45;
      p_y=495;
      p_eventtab2=_ul2_tree;
   }
   _command_button ctladd {
      p_auto_size=false;
      p_cancel=false;
      p_caption="Add";
      p_default=false;
      p_height=345;
      p_tab_index=3;
      p_tab_stop=true;
      p_width=1125;
      p_x=75;
      p_y=5130;
   }
   _command_button ctlcancel {
      p_auto_size=false;
      p_cancel=true;
      p_caption="Cancel";
      p_default=false;
      p_height=345;
      p_tab_index=4;
      p_tab_stop=true;
      p_width=1125;
      p_x=1380;
      p_y=5130;
   }
}

static const SHOW_MODIFIED_PROFILES="Show modified";
static const SHOW_ALL_PROFILES="Show all";
defeventtab _plugin_add_profiles;

static bool PUSER_SELECT_PROPERTIES(...) { 
   if (arg()) ctlcancel.p_user=arg(1);
   return ctlcancel.p_user!=0;
}
static bool PUSER_IGNORE_ON_CHANGE(...) { 
   if (arg()) ctlfilter.p_user=arg(1);
   return ctlfilter.p_user!=0;
}
/*static void PUSER_SET_PROFILE_HAS_USER_MODS(bool (&profile_has_user_mods):[]) { 
   ctladd.p_user=profile_has_user_mods;
} */
static typeless PUSER_PROFILE_HAS_USER_MODS(...) {
   if (arg()) ctladd.p_user=arg(1);
   return ctladd.p_user;
}
void ctladd.on_create(bool select_properties=false) {
   if (select_properties) {
      p_active_form.p_caption="Add Properties";
   }
   PUSER_SELECT_PROPERTIES(select_properties);
   PUSER_IGNORE_ON_CHANGE(true);
   ctlfilter._lbadd_item(SHOW_ALL_PROFILES);
   ctlfilter._lbadd_item(SHOW_MODIFIED_PROFILES);
   ctlfilter.p_text=SHOW_MODIFIED_PROFILES;
   PUSER_IGNORE_ON_CHANGE(false);
   bool profile_has_user_mods:[];
   recurse_has_user_mods(profile_has_user_mods,'');
   PUSER_PROFILE_HAS_USER_MODS(profile_has_user_mods);

   bool show_modified=ctlfilter.p_text==SHOW_MODIFIED_PROFILES;
   ctltree1.fill_in_tree(PUSER_SELECT_PROPERTIES(),profile_has_user_mods,TREE_ROOT_INDEX,show_modified,'');
}
/*static bool PUSER_PROFILE_HAS_USER_MODS(_str profileName) {
   result:=ctladd.p_user:[lowcase(profileName)];
   if (isinteger(result)) return result;
   return false;
} */
static bool recurse_has_user_mods(bool (&profile_has_user_mods):[],_str escapedProfilePackage) {
   _str profileNames[];
   _plugin_list_packages(escapedProfilePackage,profileNames);
   len := profileNames._length();
   has_user_mods := false;
   for (i:=0;i<len;++i) {
      qname := _plugin_append_profile_name(escapedProfilePackage,profileNames[i]);
      int mods=_plugin_has_profile_ex(escapedProfilePackage,profileNames[i]);
      bool mods2=recurse_has_user_mods(profile_has_user_mods,qname) ||  (mods&2);
      profile_has_user_mods:[lowcase(qname)]=mods2;
      has_user_mods=mods2 || has_user_mods;
   }
   //profile_has_user_mods:[lowcase(escapedProfilePackage)]=has_user_mods;
   return has_user_mods;
}
static void maybe_add_properties(int index,bool select_properties,int tcb_check_state) {
   bool show_modified=ctlfilter.p_text==SHOW_MODIFIED_PROFILES;
   GetAddProfileTreeInfo(index,auto letter,auto qname,auto properties_added);
   if (letter=='p' && !properties_added) {
      SetAddProfileTreeInfo(index,'p',qname,true);
      epath:=_plugin_get_profile_package(qname);
      name:=_plugin_get_profile_name(qname);
      //parent_state:=_TreeGetCheckState(index);
      if (epath!='') {
         int parent_index=index;
         int handle;
         if (show_modified) {
            handle=_plugin_get_user_profile(epath,name,false);
         } else {
            handle=_plugin_get_profile(epath,name);
         }
         if (handle>=0) {
            node:=_xmlcfg_get_document_element(handle);
            node=_xmlcfg_get_first_child_element(handle,node);
            while (node>=0) {
               name=_xmlcfg_get_name(handle,node);
               if (name:==VSXMLCFG_PROPERTY || name:==VSXMLCFG_DELETE) {
                  pname:=_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME);
                  if (name:==VSXMLCFG_DELETE) {
                     pname='(delete) 'pname;
                  }
                  property_index:=_TreeAddItem(parent_index,pname,TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
                  SetAddProfileTreeInfo(property_index,'y',_plugin_append_profile_name(qname,_xmlcfg_get_attribute(handle,node,VSXMLCFG_PROPERTY_NAME)),true);
                  if (select_properties) {
                     _TreeSetCheckable(property_index,1,0,tcb_check_state);
                  } else {
                     _TreeSetCheckable(property_index,1,0,tcb_check_state);
                     //_TreeSetCheckable(property_index,1,0,parent_state);
                  }
               }
               node=_xmlcfg_get_next_sibling_element(handle,node);
            }
         }
         _xmlcfg_close(handle);
      }
   }
}
void ctltree1.on_change(int reason,int index)
{
   //say('ctltree1.on_change reason='reason);
   switch ( reason ) {
   case CHANGE_EXPANDED:
      {
         bool select_properties=PUSER_SELECT_PROPERTIES();
         if (!select_properties) {
            return;
         }
         maybe_add_properties(index,select_properties,TCB_UNCHECKED);
      }
      break;

   case CHANGE_CHECK_TOGGLED:
      bool select_properties=PUSER_SELECT_PROPERTIES();
      if (!select_properties) {
         return;
      }
      maybe_add_properties(index,select_properties,TCB_CHECKED);
      break;
   }
}
static void SetAddProfileTreeInfo(int index,_str letter,_str qname='',bool properties_added=false) {
   _TreeSetUserInfo(index,letter:+"\t":+qname:+"\t":+properties_added);
}
static void GetAddProfileTreeInfo(int index,_str &letter,_str &qname='',bool &properties_added=false) {
   parse _TreeGetUserInfo(index) with letter "\t" qname "\t" auto sproperties_added;
   if (sproperties_added==0) {
      properties_added=false;
   } else {
      properties_added=true;
   }
}
static void fill_in_tree2(bool select_properties,bool (&profile_has_user_mods):[],int parent_index,bool show_modified,_str escapedProfilePackage,_str emore) {
   _str profileNames[];
   _plugin_list_packages(escapedProfilePackage,profileNames);
   len := profileNames._length();
   has_user_mods := false;
   for (i:=0;i<len;++i) {
      _str name=profileNames[i];
      bool has_profile=_plugin_has_profile(escapedProfilePackage,name);
      qname := _plugin_append_profile_name(escapedProfilePackage,name);

      emore2 := _plugin_append_profile_name(emore,name);
      doAdd := true;
      if (show_modified) {
         if (!profile_has_user_mods:[lowcase(qname)]) {
            doAdd=false;
         }
      }
      if (doAdd) {
         //child_index:=ctlfiles._TreeAddItem(parent_index,_strip_filename(name,'p'),TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
         if (has_profile) {
            int child_index;
            if (select_properties) {
               child_index=_TreeAddItem(parent_index,emore2,TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_COLLAPSED);
            } else {
               child_index=_TreeAddItem(parent_index,emore2,TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
            }
            SetAddProfileTreeInfo(child_index,'p',qname);
            _TreeSetCheckable(child_index,1,0,TCB_UNCHECKED);
         }
         fill_in_tree2(select_properties,profile_has_user_mods,parent_index,show_modified,qname,emore2);

      }
   }
   //dsay('escapedProfilePackage='escapedProfilePackage);
   index:=_TreeGetFirstChildIndex(parent_index);
   // Are there any child profiles?
   if (index<0) {
      if (select_properties) {
         //_TreeSetCheckable(parent_index,1,1,TCB_UNCHECKED);

         /*if (escapedProfilePackage!='') {
            _TreeDelete(parent_index);
         } */
      } else {
         //_TreeSetCheckable(parent_index,1,0,TCB_UNCHECKED);
         //_TreeGetInfo(parent_index,auto ShowChildren,auto junk,auto junk2,auto junk3,auto junk4);
         //_TreeSetInfo(parent_index,TREE_NODE_LEAF,_pic_file,_pic_file);
         //_TreeSetInfo(parent_index,TREE_NODE_COLLAPSED);
      }
   } else {
      /*if (select_properties) {
      } else {
         _TreeSetCheckable(parent_index,1,1,TCB_UNCHECKED);
      }*/
      //_TreeSetCheckable(parent_index,1,1,TCB_UNCHECKED);
   }
}


static void fill_in_tree(bool select_properties,bool (&profile_has_user_mods):[],int parent_index,bool show_modified,_str escapedProfilePackage) {
   _str profileNames[];
   _plugin_list_packages(escapedProfilePackage,profileNames);
   len := profileNames._length();
   has_user_mods := false;
   for (i:=0;i<len;++i) {
      _str name=profileNames[i];
      qname := _plugin_append_profile_name(escapedProfilePackage,name);
      doAdd := true;
      if (show_modified) {
         if (!profile_has_user_mods:[lowcase(qname)]) {
            doAdd=false;
         }
      }
      if (doAdd) {
         //child_index:=ctlfiles._TreeAddItem(parent_index,_strip_filename(name,'p'),TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
         int child_index;
         if (escapedProfilePackage=='' || select_properties) {
            child_index=_TreeAddItem(parent_index,name,TREE_ADD_AS_CHILD,_pic_fldclos,_pic_fldopen,TREE_NODE_COLLAPSED);
            _TreeSetCheckable(child_index,1,1,TCB_UNCHECKED);
         } else {
            child_index=_TreeAddItem(parent_index,name,TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
            _TreeSetCheckable(child_index,1,0,TCB_UNCHECKED);
         }
         SetAddProfileTreeInfo(child_index,'p',qname);
         if (escapedProfilePackage=='') {
            fill_in_tree(select_properties,profile_has_user_mods,child_index,show_modified,qname);
         } else {
            fill_in_tree2(select_properties,profile_has_user_mods,parent_index,show_modified,qname,name);
         }

      }
   }
   //dsay('escapedProfilePackage='escapedProfilePackage);
   index:=_TreeGetFirstChildIndex(parent_index);
   // Are there any child profiles?
   if (index<0) {
      if (select_properties) {
         //_TreeSetCheckable(parent_index,1,1,TCB_UNCHECKED);

         /*if (escapedProfilePackage!='') {
            _TreeDelete(parent_index);
         } */
      } else {
         //_TreeSetCheckable(parent_index,1,0,TCB_UNCHECKED);
         //_TreeGetInfo(parent_index,auto ShowChildren,auto junk,auto junk2,auto junk3,auto junk4);
         _TreeSetInfo(parent_index,TREE_NODE_LEAF,_pic_file,_pic_file);
         //_TreeSetInfo(parent_index,TREE_NODE_COLLAPSED);
      }
   } else {
      /*if (select_properties) {
      } else {
         _TreeSetCheckable(parent_index,1,1,TCB_UNCHECKED);
      }*/
      //_TreeSetCheckable(parent_index,1,1,TCB_UNCHECKED);
   }
}


void ctlfilter.on_change() {
   if (PUSER_IGNORE_ON_CHANGE()) {
      return;
   }
   bool show_modified=ctlfilter.p_text==SHOW_MODIFIED_PROFILES;
   bool profile_has_user_mods:[];
   profile_has_user_mods=PUSER_PROFILE_HAS_USER_MODS();

   ctltree1._TreeDelete(TREE_ROOT_INDEX,'C');
   ctltree1.fill_in_tree(PUSER_SELECT_PROPERTIES(),profile_has_user_mods,TREE_ROOT_INDEX,show_modified,'');
}

void _plugin_add_profiles.on_resize() {
   int width=_dx2lx(SM_TWIP,p_active_form.p_client_width)-ctltree1.p_x*2;
   if (width<200) width=200;
   ctltree1.p_width= width;
   int height;
   height=_dy2ly(SM_TWIP,p_active_form.p_client_height)-ctltree1.p_y-100-ctladd.p_height-100;
   if (height<200) height=200;
   ctltree1.p_height=height;
   ctlcancel.p_y=ctladd.p_y=ctltree1.p_y_extent+100;
}

void ctladd.lbutton_up() {
   bool select_properties=PUSER_SELECT_PROPERTIES();
   int info;
   _param1._makeempty();
   _str letter,qname;
   bool properties_added;
   for (ff:=1;;ff=0) {
      index := ctltree1._TreeGetNextCheckedIndex(ff,info);
      if ( index<0 ) break;
      ctltree1.GetAddProfileTreeInfo(index,letter,qname,properties_added);
      if (select_properties) {
         //say(ctltree1._TreeGetCaption(index));
         // If this is a property
         if (letter=='y') {
            _param1[_param1._length()]=qname;
         }
      } else {
         epath:=_plugin_get_profile_package(qname);
         name:=_plugin_get_profile_name(qname);
         bool has_profile=_plugin_has_profile(epath,name);
         if (has_profile) {
            _param1[_param1._length()]=qname;
         }
      }
      //_TreeGetInfo(index,auto state, auto bm1);
      //if ( state== ) {
         //ARRAY_APPEND(indexList,index);
      //}
   }
   p_active_form._delete_window(1);
}
struct PLGMAN_ERROR_INFO {
   _str m_filename;
   int m_linenum;
   _str m_errorMsg;
};
static const PLUGIN_VALIDATION_MESSAGE_TYPE="Plugin Validation Warnings";
static void _plgman_validate_file(_str prefix_id,_str filename) {
   if (!_file_eq(get_extension(filename),"e")) {
      return;
   }
   PLGMAN_ERROR_INFO errors[];
   _plgman_validate_macro_file(prefix_id,filename,errors);
   PLGMAN_ERROR_INFO v;

   se.messages.MessageCollection* mCollection = get_messageCollection();
   mCollection->removeMessages(PLUGIN_VALIDATION_MESSAGE_TYPE);
   mCollection->startBatch();
   foreach (auto i=>v in errors) {
      se.messages.Message tmpMsg;
      tmpMsg.m_creator = PLUGIN_VALIDATION_MESSAGE_TYPE;
      tmpMsg.m_type = "Warning";
      tmpMsg.m_description = v.m_errorMsg;
      tmpMsg.m_sourceFile = v.m_filename;
      tmpMsg.m_lineNumber = v.m_linenum;
      tmpMsg.m_colNumber = 1;
      tmpMsg.m_date = "";
      mCollection->newMessage(tmpMsg);
      //say(v.m_filename' 'v.m_linenum': 'v.m_errorMsg);
   }
   mCollection->endBatch();
   mCollection->notifyObservers();
   if (errors._length()) {
      activate_messages();
   }
}
static void _plgman_validate_macro_file(_str prefix_id,_str filename,PLGMAN_ERROR_INFO (&errors)[]) {
   status:=_open_temp_view(filename,auto temp_wid,auto orig_wid);
   if (status) {
      return;
   }
   _SetEditorLanguage();
   _UpdateContext(true,true,VS_UPDATEFLAG_context/*|VS_UPDATEFLAG_statement*/);
   //say('num='tag_get_num_of_context());
   int i;
   for (i=1;i<=tag_get_num_of_context();++i) {
      _str tag_name;
      tag_get_detail2(VS_TAGDETAIL_context_name,i,tag_name);

      tag_get_detail2(VS_TAGDETAIL_context_type,i,auto type);
      int start_linenum;
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum,i,start_linenum);
      int flags;
      tag_get_detail2(VS_TAGDETAIL_context_flags,i,flags);
      _str className;
      tag_get_detail2(VS_TAGDETAIL_context_class,i,className);
      // These types don't support namespaces yet.
      if (type=='menu' || type=='form' || type=='eventtab') {
         if (substr(tag_name,1,length(prefix_id)+1)!=(prefix_id:+'_')) {
            PLGMAN_ERROR_INFO info;
            info.m_filename=filename;
            info.m_linenum=start_linenum;
            info.m_errorMsg=nls("menu/form/eventtab identifier should start with '%s'",prefix_id:+'_');
            errors[errors._length()]=info;
         }
         continue;
      }
      if (type!='func' && type!='struct' && type!='class' && type!='const') {
         continue;
      }
      if (flags&SE_TAG_FLAG_STATIC) {
         continue;
      }
      // Is this an event function?
      if (pos('.',tag_name)) {
         continue;
      }
      // Is this declared in a class or namespace?
      if (className!='') {
         // This symbol is in a class or namespace. No problem here.
         //say('className='className' tg='tag_name);
         continue;
      }
      if (substr(tag_name,1,length(prefix_id)+1)!=(prefix_id:+'_')) {
         PLGMAN_ERROR_INFO info;
         info.m_filename=filename;
         info.m_linenum=start_linenum;
         info.m_errorMsg=nls("function/struct/class/const identifier should be declared in namespace '%s'",prefix_id);
         errors[errors._length()]=info;
      }
   }
   _delete_temp_view(temp_wid);
   p_window_id=orig_wid;

}
_form _plugin_name_help_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_SIZABLE;
   p_caption="Plugin Name Help";
   p_forecolor=0x80000008;
   p_height=5715;
   p_width=6000;
   p_x=18120;
   p_y=5295;
   p_eventtab=_plugin_name_help_form;
   _minihtml ctlminihtml1 {
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_height=5100;
      p_PaddingX=100;
      p_PaddingY=200;
      p_tab_index=1;
      p_tab_stop=true;
      p_width=5805;
      p_word_wrap=true;
      p_x=75;
      p_y=75;
      p_eventtab2=_ul2_minihtm;
   }
   _command_button ctlclose {
      p_auto_size=false;
      p_cancel=true;
      p_caption="Close";
      p_default=true;
      p_height=345;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=1125;
      p_x=120;
      p_y=5280;
   }
   _command_button ctlhelp {
      p_auto_size=false;
      p_cancel=false;
      p_caption="Help";
      p_default=false;
      p_height=345;
      p_tab_index=3;
      p_tab_stop=true;
      p_width=1125;
      p_x=1395;
      p_y=5280;
   }
}
defeventtab _plugin_name_help_form;

void ctlminihtml1.on_create(_str msg='') {
   p_text=msg;
}
void _plugin_name_help_form.on_resize() {
   int width=_dx2lx(SM_TWIP,p_active_form.p_client_width)-ctlminihtml1.p_x*2;
   if (width<200) width=200;
   ctlminihtml1.p_width= width;
   int height;
   height=_dy2ly(SM_TWIP,p_active_form.p_client_height)-ctlminihtml1.p_y-100-ctlclose.p_height-100;
   if (height<200) height=200;
   ctlminihtml1.p_height=height;
   ctlclose.p_y=ctlhelp.p_y=ctlminihtml1.p_y_extent+100;
}
/**
 * Installs or reinstalls local plugins (.zip plugin files) created by plugin_new or plugin_open.
 * 
 * @param filename Optional filename of .zip plugin to install. Needs to be surrounded with double quotes if it contains a space. 
 *  
 * @categories Miscellaneous_Functions
 */
_command void plugin_install(_str filename='') name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION) {
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG);
      return;
   }
   if (filename=='') {
      filename=_plgman_choose_plugin_to_install();
      if (filename=='') return;
   } else {
      filename=absolute(parse_file(filename,false));
   }
   if (!file_exists(filename)) {
      _message_box(nls("Plugin file '%s' not found",filename));
      return;
   }
   _plugin_install(filename);
}
static _str _plgman_choose_plugin_to_uninstall() {
    _str plugin_list[];
   plugin_list._makeempty();
   file:=file_match(VSCFGPLUGIN_DIR:+'*',1);
   while (file!='') {
      if (FILESEP=='\') {
         file=translate(file,'\','/');
      }
      parse file with (FILESEP:+FILESEP) auto plugin_name (FILESEP);
      if (plugin_name!='com_slickedit.base') {
         //say(plugin_name);
         plugin_list[plugin_list._length()]=plugin_name;
      }
      file=file_match(VSCFGPLUGIN_DIR:+'*',0);
   }
   if (plugin_list._length()==0) {
      _message_box('There are no plugins installed');
      return '';
   }
   typeless result=show('-modal _sellist_form',
               'Select a plugin to uninstall',
               SL_ALLOWMULTISELECT|SL_SIZABLE|SL_DEFAULTCALLBACK,
               plugin_list,
               '',//buttons
               '',//help
               ''//font
               );
   result=strip(result);
   
   return result;
}
/**
 * Uninstalls a currently installed plugin.
 *  
 * @param Optional name of plugin to uninstall.
 *  
 * @categories Miscellaneous_Functions
 */
_command void plugin_uninstall(_str plugin_names='') name_info(PLUGIN_ARG','VSARG2_REQUIRES_PRO_EDITION) {
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG);
      return;
   }
   if (plugin_names=='') {
      plugin_names=_plgman_choose_plugin_to_uninstall();
      if (plugin_names=='') return;
      plugin_names=_maybe_quote_filename(plugin_names);
   }
   for (;;) {
      if (plugin_names=='') break;
      plugin_name:=parse_file(plugin_names,false);
      file:=VSCFGPLUGIN_DIR:+plugin_name'/';
      path:=absolute(file,null,true);
      path=_plugin_relative_path(path);
      if (path!=null) {
         plugin_name=path;
         if (last_char(plugin_name)==FILESEP || last_char(plugin_name)=='/') {
            plugin_name=substr(plugin_name,1,length(plugin_name)-1);
         }
         status:=_plugin_uninstall(plugin_name,true,true);
         if (status) break;
      } else {
         _message_box(nls("Plugin '%s' not found",plugin_name));
      }
   }
}

