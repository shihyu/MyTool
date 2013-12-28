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
#require "se/debug/dbgp/DBGpOptions.e"
#import "se/debug/dbgp/dbgp.e"
#include "blob.sh"
#include "vsockapi.sh"
#include "xml.sh"
#import "stdprocs.e"
#endregion

namespace se.debug.dbgp;

/**
 * Quick and dirty way of peeking the next packet from a DBGp 
 * connection. Typically used to peek the &lt;init&gt; packet in 
 * order to parse info for a remote debug session. 
 * 
 * @param socket  Connected socket to peek.
 * 
 * @return >=0 XMLCFG handle to packet on success, <0 on error.
 */
int dbgp_peek_packet(int socket)
{
   int hblob = _BlobAlloc(0);
   int temp_wid;
   int orig_wid = _create_temp_view(temp_wid);

   int status = 0;
   int handle = -1;

   do {

      // Expecting: [NUMBER] [NULL] XML(data) [NULL]

      // Peek data from socket
      status = vssSocketRecvToBlob(socket,hblob,100,1);
      if( status != 0 ) {
         break;
      }

      // Length of packet : [NUMBER] [NULL]
      _BlobSetOffset(hblob,0,0);
      int nbytes = 0;
      int ch;
      status = _BlobGetChar(hblob,ch);
      while( status == 0 && ch != 0 ) {
         ++nbytes;
         status = _BlobGetChar(hblob,ch);
      }
      if( status != 0 ) {
         break;
      }
      _str len_s;
      int len;
      _BlobSetOffset(hblob,0,0);
      _BlobGetString(hblob,len_s,nbytes);
      if( !isinteger(len_s) ) {
         status = INVALID_ARGUMENT_RC;
         break;
      }
      len = (int)len_s;

      // Move past [NULL]
      _BlobSetOffset(hblob,1,1);

      // XML(data)
      // Note: Trailing [NULL] is left off.
      _str data = "";
      status = _BlobGetString(hblob,data,len);
      if( status != 0 ) {
         break;
      }

      // Stuff data into temp view
      _insert_text(data,true);

      // Parse data into an XMLCFG object
      handle = _xmlcfg_open_from_buffer(temp_wid,status);
      if( handle < 0 ) {
         status = handle;
      }

   } while( false );

   _delete_temp_view(temp_wid);
   p_window_id = orig_wid;
   _BlobFree(hblob);

   if( status != 0 ) {
      return status;
   }

   // Success
   return handle;
}

/**
 * Are we in the middle of starting a DBGp-type (Xdebug, pydbgp,
 * etc.) debug session? 
 * 
 * @param new_value  Set to 1 (true) to indicate that a 
 *                   DBGp-type debug session is starting. Set to
 *                   0 (false) to indicate a debug session is
 *                   not starting. Set to -1 to retrieve the
 *                   current state. Defaults to -1.
 * 
 * @return Current state of DBGp debug session start.
 */
boolean dbgp_almost_active(int new_value=-1)
{
   typeless cur_value = false;
   if( new_value != -1 ) {
      _SetDialogInfoHt("dbgp_almost_active",(new_value!=0),_mdi);
      cur_value = ( new_value!=0 );
   } else {
      typeless value = _GetDialogInfoHt("dbgp_almost_active",_mdi);
      cur_value = value != null && value != 0;
   }
   return ( cur_value != 0 );
}


/**
 * Create arguments to use when calling debug_begin() to start a 
 * DBGp-protocol debugger. 
 * 
 * @param dbgp_features  DBGp features to translate into 
 *                       arguments.
 * 
 * @return A string of debugger arguments of the form 
 *         '-feature-set=feature-name=feature-value ...'
 */
_str dbgp_make_debugger_args(DBGpFeatures& dbgp_features)
{
   _str args = '';
   // The members of DBGpFeatures are named *exactly* as the DBGp
   // protocol specifies, so we can just use the member name to
   // construct the arguments.
   int i, n=dbgp_features._length();
   for( i=0; i < n; ++i ) {
      args = args' -feature-set='translate(dbgp_features._fieldname(i),'_','-')'='dbgp_features._getfield(i);
   }
   return args;
}


// DEBUG
_command void test1()
{
   DBGpFeatures dbgp_features;
   dbgp_make_default_features(dbgp_features);
   _str args = dbgp_make_debugger_args(dbgp_features);
   message('args='args);
}
