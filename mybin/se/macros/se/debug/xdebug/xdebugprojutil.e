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
#include "se/debug/dbgp/DBGpOptions.e"
#import "se/debug/dbgp/dbgp.e"
#include "se/debug/xdebug/XdebugOptions.e"
#import "projconv.e"
#import "wkspace.e"
#import "project.e"
#import "mprompt.e"
#endregion

namespace se.debug.xdebug;

using se.debug.dbgp.dbgp_make_default_features;

XdebugOptions xdebug_make_default_options(XdebugOptions& xdebug_opts=null)
{
   xdebug_opts.serverHost = "127.0.0.1";
   xdebug_opts.serverPort = "9000";
   xdebug_opts.listenInBackground = true;
   xdebug_opts.stayInDebugger = false;
   xdebug_opts.acceptConnections = "prompt";
   xdebug_opts.breakInSession = "step-into";
   xdebug_opts.remoteFileMap = null;
   se.debug.dbgp.dbgp_make_default_features(xdebug_opts.dbgp_features);
   return xdebug_opts;
}

/**
 * Retrieve Xdebug options for project and config.
 * 
 * @param projectHandle        Handle of project.
 * @param config               Configuration to retrieve options 
 *                             for.
 * @param xdebug_opts          (out) Set to project Xdebug 
 *                             options.
 * @param default_xdebug_opts  Default options to use in case no 
 *                             options present for config.
 */
void xdebug_project_get_options_for_config(int projectHandle, _str config, XdebugOptions& xdebug_opts, XdebugOptions& default_xdebug_opts=null)
{
   if( default_xdebug_opts == null ) {
      xdebug_make_default_options(default_xdebug_opts);
   }
   _str serverHost = default_xdebug_opts.serverHost;
   _str serverPort = default_xdebug_opts.serverPort;
   boolean listenInBackground = default_xdebug_opts.listenInBackground;
   boolean stayInDebugger = default_xdebug_opts.stayInDebugger;
   _str acceptConnections = default_xdebug_opts.acceptConnections;
   _str breakInSession = default_xdebug_opts.breakInSession;
   XdebugRemoteFileMapping remoteFileMap[] = default_xdebug_opts.remoteFileMap;
   se.debug.dbgp.DBGpFeatures dbgp_features = default_xdebug_opts.dbgp_features;

   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node >= 0 ) {
      int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='Xdebug Options']",node);
      if( opt_node >= 0 ) {

         // ServerHost
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ServerHost']",opt_node);
         if( node >=0  ) {
            serverHost = _xmlcfg_get_attribute(projectHandle,node,"Value",serverHost);
         }

         // ServerPort
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ServerPort']",opt_node);
         if( node >=0  ) {
            serverPort = _xmlcfg_get_attribute(projectHandle,node,"Value",serverPort);
         }

         // ListenInBackground
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ListenInBackground']",opt_node);
         if( node >=0  ) {
            listenInBackground = ( 0 != _xmlcfg_get_attribute(projectHandle,node,"Value",(int)listenInBackground) );
         }

         // StayInDebugger
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='StayInDebugger']",opt_node);
         if( node >=0  ) {
            stayInDebugger = ( 0 != _xmlcfg_get_attribute(projectHandle,node,"Value",(int)stayInDebugger) );
         }

         // AcceptConnections
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='AcceptConnections']",opt_node);
         if( node >=0  ) {
            acceptConnections = _xmlcfg_get_attribute(projectHandle,node,"Value",acceptConnections);
         }

         // BreakInSession
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='BreakInSession']",opt_node);
         if( node >=0  ) {
            breakInSession = _xmlcfg_get_attribute(projectHandle,node,"Value",breakInSession);
         }

         // Remote file mappings
         _str nodes[];
         if( 0 == _xmlcfg_find_simple_array(projectHandle,"List[@Name='Map']",nodes,opt_node,0) ) {
            _str remoteRoot, localRoot;
            foreach( auto map_node in nodes ) {
               remoteRoot = "";
               localRoot = "";
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='RemoteRoot']",(int)map_node);
               if( node >=0  ) {
                  remoteRoot = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='LocalRoot']",(int)map_node);
               if( node >=0  ) {
                  localRoot = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               int i = remoteFileMap._length();
               remoteFileMap[i].remoteRoot = remoteRoot;
               remoteFileMap[i].localRoot = localRoot;
            }
         }

         // DBGp features
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='show_hidden']",opt_node);
         if( node >=0  ) {
            dbgp_features.show_hidden = ( 0 != _xmlcfg_get_attribute(projectHandle,node,"Value",(int)dbgp_features.show_hidden) );
         }
      }
   }
   xdebug_opts.serverHost = serverHost;
   xdebug_opts.serverPort = serverPort;
   xdebug_opts.listenInBackground = listenInBackground;
   xdebug_opts.stayInDebugger = stayInDebugger;
   xdebug_opts.acceptConnections = acceptConnections;
   xdebug_opts.breakInSession = breakInSession;
   xdebug_opts.remoteFileMap   = remoteFileMap;
   // DBGp features
   xdebug_opts.dbgp_features = dbgp_features;
}

/**
 * Retrieve Xdebug options for all project configs.
 * 
 * @param projectHandle        Handle of project.
 * @param config               List of configurations to 
 *                             retrieve options for.
 * @param xdebug_opts_list     (out) Hash table of project
 *                             Xdebug options indexed by config
 *                             name.
 * @param default_xdebug_opts  Default options to use in case no 
 *                             options present for config.
 */
void xdebug_project_get_options(int projectHandle, _str (&configList)[], XdebugOptions (&xdebug_opts_list):[], XdebugOptions& default_xdebug_opts=null)
{
   foreach( auto config in configList ) {
      XdebugOptions opts;
      xdebug_project_get_options_for_config(projectHandle,config,opts,default_xdebug_opts);
      xdebug_opts_list:[config] = opts;
   }
}

/**
 * Get the Xdebug Options option value for the current project 
 * and active config. This function can only retrieve simple 
 * name/value pairs. Use xdebug_project_get_options_for_config()
 * to retrieve XdebugOptions object which contains all options.
 *
 * @param name           Name of option to retrieve value for.
 * @param default_value  Default value to use if option is not 
 *                       found.
 * 
 * @return Value for option name specified. If option does not 
 *         exist, then default_value is returned.
 */
_str xdebug_project_get_option(_str name, _str default_value)
{
   if( _project_name == "" ) {
      return default_value;
   }

   _str value = default_value;

   int projectHandle = _ProjectHandle(_project_name);
   _str config = GetCurrentConfigName(_project_name);
   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node >= 0 ) {
      int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='Xdebug Options']",node);
      if( opt_node >= 0 ) {
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='"name"']",opt_node);
         if( node >=0  ) {
            value = _xmlcfg_get_attribute(projectHandle,node,"Value",default_value);
         }
      }
   }

   return value;
}

/**
 * Set the Xdebug Options option value for name specified for 
 * current project and active config. 
 * 
 * @param name   Name of option to set.
 * @param value  Value of option to set.
 * 
 * @return 0 on success, <0 on error.
 */
int xdebug_project_set_option(_str name, _str value)
{
   if( _project_name == "" ) {
      return FILE_NOT_FOUND_RC;
   }

   // Sanity please
   if( value == null ) {
      value = "";
   }

   int projectHandle = _ProjectHandle(_project_name);
   _str config = GetCurrentConfigName(_project_name);
   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node < 0 ) {
      // Not found
      return node;
   }
   int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='Xdebug Options']",node);
   if( opt_node < 0 ) {
      // Not found
      return opt_node;
   }
   node = _xmlcfg_find_simple(projectHandle,"Item[@Name='"name"']",opt_node);
   if( node < 0 ) {
      // Create it
      node = _xmlcfg_add(projectHandle,opt_node,VPJTAG_ITEM,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      if( node < 0 ) {
         // Error
         return node;
      }
   }
   _xmlcfg_set_attribute(projectHandle,node,"Name",name);
   _xmlcfg_set_attribute(projectHandle,node,"Value",value);

   int status = _ProjectSave(projectHandle);
   return status;
}
