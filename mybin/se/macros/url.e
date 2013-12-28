////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "fileman.e"
#import "listbox.e"
#import "main.e"
#import "reflow.e"
#endregion

definit()
{
   _InitProxySettings();

   rc=0;
}

#if __UNIX__
_str def_url_proxy="";
_str def_url_proxy_bypass="";
#else
_str def_url_proxy="IE;";
_str def_url_proxy_bypass="";
#endif

static void _InitProxySettings()
{
   _UrlClearAllProxies();
   _str browser='';
   _str proxy=def_url_proxy;
   if( pos(';',proxy) ) parse proxy with browser ';' proxy;
#if __UNIX__
   // IE settings are for Windows only, so fix this right now
   if( browser!="" ) {
      def_url_proxy=proxy;
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   browser="";
#endif
   if( upcase(browser)=='IE' ) {
      // Using Internet Explorer (IE) settings
      //
      // The port will be ignored when host="IE;"
      _UrlSetProxy("http","IE;",0);
   } else {
      _str line='';
      _str proto='';
      _str host='';
      typeless port='';
      while( proxy!="" ) {
         parse proxy with line proxy;
         parse line with proto'='host':'port;
         _UrlSetProxy(proto,host,port);
      }
   }
   _UrlSetProxyBypass(def_url_proxy_bypass);
}

/**
 * Convert a URL into a SlickEdit form URL that can be passed to edit().
 * <P>
 * An equivalency table:
 * <PRE>
 * SlickEdit form (non-UNIX)                    RFC 1738 URL form
 * ------------------------------------------------------------------------------------------------
 * 0:/http/host.com/index.html                         http://host.com/index.html
 * 0:/http/host.com!80/index.html                      http://host.com:80/index.html
 * 0:/http/host.com/index.html#ref                     http://host.com/index.html#ref
 * 0:/http/user!pass@host.com/index.html               http://user:pass@host.com/index.html
 * 0:/javascript/./jsMethod()                          javascript:jsMethod()
 * 0:/http/host.com/script.cgi$$arg1@@val1&arg2@@val2  http://host.com/script.cgi?arg1=val1&arg2=val2
 *
 * SlickEdit form (UNIX)                          RFC 1738 URL form
 * ------------------------------------------------------------------------------------------------
 * /%%0/http/host.com/index.html                         http://host.com/index.html
 * /%%0/http/host.com!80/index.html                      http://host.com:80/index.html
 * /%%0/http/host.com/index.html#ref                     http://host.com/index.html#ref
 * /%%0/http/user!pass@host.com/index.html               http://user:pass@host.com/index.html
 * /%%0/javascript/./jsMethod()                          javascript:jsMethod()
 * /%%0/http/host.com/script.cgi$$arg1@@val1&arg2@@val2  http://host.com/script.cgi?arg1=val1&arg2=val2
 * </PRE>
 */
_str _UrlToSlickEdit(_str url)
{
   if( url=="" ) return(url);

   _str proto='';
   _str host='';
   _str path='';
   _str rest='';
   _str seurl='';
   parse url with proto ':' rest;
   if( proto=="" ) return("");
   host=".";
   if( substr(rest,1,2)=="//" ) {
      parse substr(rest,3) with host "/" rest;
      host=stranslate(host,'!',':');
   }
   path=rest;
   path=stranslate(path,'$$','?');
   path=stranslate(path,'@@','=');

#if __UNIX__
   seurl='/%%0/'proto'/'host'/'path;
#else
   path=translate(path,FILESEP,FILESEP2);
   seurl='0:\'proto'\'host'\'path;
#endif
   return(seurl);
}

/**
 * Convert a SlickEdit form URL into a standard RFC 1738 URL.
 * <P>
 * An equivalency table:
 * <PRE>
 * SlickEdit form (non-UNIX)                    RFC 1738 URL form
 * ------------------------------------------------------------------------------------------------
 * 0:/http/host.com/index.html                         http://host.com/index.html
 * 0:/http/host.com!80/index.html                      http://host.com:80/index.html
 * 0:/http/host.com/index.html#ref                     http://host.com/index.html#ref
 * 0:/http/user!pass@host.com/index.html               http://user:pass@host.com/index.html
 * 0:/javascript/./jsMethod()                          javascript:jsMethod()
 * 0:/http/host.com/script.cgi$$arg1@@val1&arg2@@val2  http://host.com/script.cgi?arg1=val1&arg2=val2
 *
 * SlickEdit form (UNIX)                          RFC 1738 URL form
 * ------------------------------------------------------------------------------------------------
 * /%%0/http/host.com/index.html                         http://host.com/index.html
 * /%%0/http/host.com!80/index.html                      http://host.com:80/index.html
 * /%%0/http/host.com/index.html#ref                     http://host.com/index.html#ref
 * /%%0/http/user!pass@host.com/index.html               http://user:pass@host.com/index.html
 * /%%0/javascript/./jsMethod()                          javascript:jsMethod()
 * /%%0/http/host.com/script.cgi$$arg1@@val1&arg2@@val2  http://host.com/script.cgi?arg1=val1&arg2=val2
 * </PRE>
 */
_str _SlickEditToUrl(_str se_url)
{
   if( se_url=="" ) return("");

   _str proto='';
   _str host='';
   _str path='';
#if __UNIX__
   if( substr(se_url,1,5)!='/%%0/' ) return(se_url);
   parse se_url with '/%%0/' proto '/' host '/' path;
#else
   if( substr(se_url,1,3)!='0:\' ) return(se_url);
   parse se_url with '0:\' proto '\' host '\' path;
   path=translate(path,'/','\');
#endif
   if( host=="." ) host="";
   host=stranslate(host,':','!');
   path=stranslate(path,'?','$$');
   path=stranslate(path,'=','@@');

   _str url=proto':';
   if( host!="" ) url=url'//'host;
   if( path!="" ) url=url'/'path;
   return(url);
}

defeventtab _url_proxy_form;

#region Options Dialog Helper Functions

void _url_proxy_form_init_for_options()
{
   ctl_ok.p_visible = false;
   ctl_cancel.p_visible = false;
}

boolean _url_proxy_form_apply()
{
   _str msg="";
   _str proxy="";
   _str bypass="";
   if( ctl_use_ie.p_value ) {
      proxy='IE;';
      bypass='';
   } else if( ctl_use_proxy.p_value ) {
      _str host=ctl_http_host.p_text;
      if( host=="" ) {
         msg="Invalid proxy address.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctl_http_host;
         _set_sel(1,length(p_text)+1);_set_focus();
         return false;
      }
      typeless port=ctl_http_port.p_text;
      if( !isinteger(port) || port<1 || port>65535 ) {
         msg="Invalid port.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctl_http_port;
         _set_sel(1,length(p_text)+1);_set_focus();
         return false;
      }
      proxy='http=':+host:+':':+port;
      // Reconstitute the list into a single line, compress multiple
      // contiguous spaces.
      _str list="";
      _str line="";
      ctl_bypass.top();ctl_bypass.up();
      while( !ctl_bypass.down() ) {
         ctl_bypass.get_line(line);
         list=list' 'strip(line);
      }
      list=stranslate(list,' ',';');
      bypass="";
      _str temp="";
      while( list!="" ) {
         parse list with temp list;
         bypass=bypass' 'temp;
      }
      bypass=strip(bypass);
   }
   def_url_proxy=proxy;
   def_url_proxy_bypass=bypass;
   _config_modify_flags(CFGMODIFY_DEFDATA);
   _InitProxySettings();

   return true;
}

#endregion Options Dialog Helper Functions

void ctl_ok.on_create()
{
   _str browser='';
   ctl_http_host.p_text="";
   ctl_http_port.p_text="";
   ctl_bypass._lbclear();
   ctl_bypass.p_margins="1 "ctl_bypass.p_char_width" 1";
   parse def_url_proxy with browser ';' .;
#if __UNIX__
   // IE settings are for Windows only
   ctl_use_ie.p_value=0;
   diff := ctl_use_proxy.p_y - ctl_use_ie.p_y;
   ctl_use_proxy.p_y = ctl_use_ie.p_y;
   ctl_use_proxy_frame.p_y -= diff;
#else
   ctl_use_ie.p_value= (int)(upcase(browser)=='IE');
#endif
   ctl_use_ie.call_event(true,ctl_use_ie,LBUTTON_UP,'W');

   return;
}

void ctl_ok.lbutton_up()
{
   if (_url_proxy_form_apply()) {
      p_active_form._delete_window(0);
   } else {
      return;
   }
}

// Assumes the parent is the active window.
// Enables/disables all children.
static void _enable_controls(boolean enabledisable)
{
   int firstwid=p_child;
   if( !firstwid ) return;
   int wid=firstwid;
   for(;;) {
      wid.p_enabled=enabledisable;
      if( wid.p_object==OI_FRAME ) wid._enable_controls(enabledisable);
      wid=wid.p_next;
      if( wid==firstwid ) break;
   }

   return;
}
static void _populate_proxy_settings(_str proxy,_str bypass)
{
   _str line="";
   _str proto='';
   _str host='';
   _str port='';
   ctl_http_host.p_text="";
   ctl_http_port.p_text="";
   while( proxy!="" ) {
      parse proxy with line proxy;
      parse line with proto'='host':'port;
      switch( lowcase(proto) ) {
      case "http":
         ctl_http_host.p_text=host;
         ctl_http_port.p_text=port;
         break;
      }
   }
   _str list="";
   while( bypass!="" ) {
      parse bypass with host bypass;
      list=list:+host'; ';
   }
   bypass=strip(list);
   bypass=strip(bypass,'T',';');
   ctl_bypass._lbclear();
   if( bypass!="" ) {
      ctl_bypass._insert_text(bypass);
      ctl_bypass.select_all();
      ctl_bypass.reflow_selection();
      ctl_bypass.deselect();
      ctl_bypass.top();
   }

   return;
}
void ctl_use_ie.lbutton_up(boolean init=false)
{
   boolean enabled= p_value==0;
   ctl_use_proxy_frame.p_enabled=enabled;
   ctl_use_proxy_frame._enable_controls(enabled);
   if( p_value ) {
      // Using IE settings
      ctl_use_proxy.p_value=0;
      _populate_proxy_settings("","");
   } else {
      // Using manual settings or no proxy
      if( !init ) {
         // User actually clicked on checkbox
         _UrlClearAllProxies();
         _populate_proxy_settings("","");
         ctl_use_proxy.p_value=0;
      } else {
         // Initialization
         if( _UrlGetAllProxies()!="" ) ctl_use_proxy.p_value=1;
      }
      ctl_use_proxy.call_event(ctl_use_proxy,LBUTTON_UP,'W');
   }

   return;
}
void ctl_use_proxy.lbutton_up()
{
   boolean enabled= p_value!=0;
   ctl_use_proxy_frame.p_enabled=enabled;
   ctl_use_proxy_frame._enable_controls(enabled);
   ctl_servers_frame.p_enabled=enabled;
   ctl_servers_frame._enable_controls(enabled);
   ctl_exceptions_frame.p_enabled=enabled;
   ctl_exceptions_frame._enable_controls(enabled);

   if( p_value ) {
      _str proxy=_UrlGetAllProxies();
      _str bypass=_UrlGetProxyBypass();
      _populate_proxy_settings(proxy,bypass);
   }

   return;
}

void ctl_none.lbutton_up()
{
   ctl_use_proxy.call_event(ctl_use_proxy,LBUTTON_UP,'W');
}
