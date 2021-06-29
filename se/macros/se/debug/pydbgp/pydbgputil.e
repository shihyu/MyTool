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
#require "se/debug/dbgp/dbgputil.e"
#endregion

namespace se.debug.pydbgp;

/**
 * Quick and dirty way of peeking the next packet from a pydbgp 
 * connection. Typically used to peek the &lt;init&gt; packet in 
 * order to parse info for a remote debug session. 
 * 
 * @param socket  Connected socket to peek.
 * 
 * @return >=0 XMLCFG handle to packet on success, <0 on error.
 */
int pydbgp_peek_packet(int socket)
{
   // For now this is just a pass-thru to dbgp_peek_packet()
   // since there is nothing pydbgp-specific we need to know.
   // That could change later, hence this function.
   return se.debug.dbgp.dbgp_peek_packet(socket);
}

/**
 * Are we in the middle of starting a pydbgp debug session?
 * 
 * @param new_value  Set to 1 (true) to indicate that a pydbgp 
 *                   debug session is starting. Set to 0 (false)
 *                   to indicate a debug session is not
 *                   starting. Set to -1 to retrieve the current
 *                   state. Defaults to -1.
 * 
 * @return Current state of pydbgp debug session start.
 */
bool pydbgp_almost_active(int new_value=-1)
{
   // For now this is just a pass-thru to dbgp_almost_active()
   // since there is nothing pydbgp-specific we need to know.
   // That could change later, hence this function.
   return se.debug.dbgp.dbgp_almost_active(new_value);
}
