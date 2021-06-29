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
#include "ftp.sh"
#import "ftp.e"
#import "stdprocs.e"
#endregion



/**
 * <p> 
 * Note that doc_name, if not "", is favored over buf_name. FTP 
 * paths are supported by this function. 
 * <p> 
 * Note that special buffers like ".process" and Fileman lists 
 * are not modified. 
 *  
 * @param buf_name Buffer name (p_buf_name).
 * @param doc_name Document name (p_DocumentName). 
 *  
 * @return Filename-only part of full path. 
 */
static _str createFilename(_str buf_name, _str doc_name)
{
   if( buf_name == "" && doc_name == "" ) {
      return "";
   }

   // Favor doc_name over buf_name
   _str filename = doc_name;
   if( filename == "" ) {
      filename == buf_name;
   }

   if( beginsWith(filename,".process") ||
       substr(filename,1,length("List of")) == "List of" ||
       substr(filename,1,length("Directory of")) == "Directory of") {
      // Special case.
      // The old %F behavior was to NOT attempt to strip the document name,
      // so we keep it that way.
      return filename;
   }

   if( ftpIsFTPDocname(filename) ) {
      // Find the matching connection profile so we can intelligently
      // strip the path based on the server type.
      FtpConnProfile* fcp_p = null;
      _str host, port, path;
      _ftpParseAddress(filename,host,port,path);
      _str list[];
      if( 0 == _ftpHostNameToCurrentConnection(host,list) ) {
         // We have to be lazy and use the first match in the list since
         // we do not currently map specific buffers to specific connections.
         fcp_p = _ftpIsCurrentConnProfile(list[0]);
      }
      if( !fcp_p ) {
         // Probably printing an ftp file without a current connection,
         // so guess at the server type (UNIX). This will work out in most
         // cases even if the server type is not UNIX.
         FtpConnProfile fcp;
         _ftpInitConnProfile(fcp);
         fcp.system = FTPSYST_UNIX;
         filename = _ftpStripFilename(&fcp,path,'p');
      } else {
         filename = _ftpStripFilename(fcp_p,path,'p');
      }
   } else {
      filename = _strip_filename(filename,'p');
   }
   return filename;
}

/** 
 * Process string of escape codes for printing.
 * 
 * Escape codes processed by this function are:
 * <pre>
 * %f, %fn - filename (no path)
 * %fp - filename with path
 * %fd - file date (local format)
 * %fde - file date (European format)
 * %ft - file time (local format)
 * %fte - file time (European/military format)
 * %de - current date (European/military format)
 * %te - current time (European/military format)
 *  
 * <p>
 * Note that _print, not this function, processes the following
 * escape codes:
 * <pre>
 * %d - current date (local format)
 * %t - current time (local format)
 * %p - page number
 * %n - total number of pages
 * </pre>
 * 
 * @param string   String to process
 * @param buf_name Current buffer name (p_buf_name).
 * @param doc_name Current document name (p_DocumentName). 
 *  
 * @return Processed string. 
 */
_str _insert_print_options(_str string, _str buf_name, _str doc_name)
{
   result := "";
   mm := "";
   dd := "";
   yyyy := "";

   int i;
   for( i=1; ; ) {
      j := pos('%',string,i);
      if( j == 0 ) {
         // All done
         result :+= substr(string,i);
         return result;
      }
      result :+= substr(string,i,j-i);

      // Process for %F*
      if( upcase(substr(string,j+1,1)) :== 'F' ) {

         switch( upcase(substr(string,j+1,2)) ) {
         case "FD":
            // FDE=European format
            if( upcase(substr(string,j+3,1)) :== 'E' ) {
               parse _file_date(buf_name) with mm'/'dd'/'yyyy;
               result :+= dd'/'mm'/'yyyy :+ substr(result,2);
               i = j+4;
            } else {
               result :+= _file_date(buf_name,'L');
               i = j+3;
            }
            break;
         case "FT":
            // FTE=European format
            if( upcase(substr(string,j+3,1)) :== 'E' ) {
               result :+= _file_time(buf_name,'M');
               i = j+4;
            } else {
               result :+= _file_time(buf_name,'L');
               i = j+3;
            }
            break;
         case "FP":
            // Full path to the file
            if( doc_name != "" ) {
               result :+= doc_name;
            } else {
               result :+= buf_name;
            }
            i = j+3;
            break;
         case "FN":
            // Name-only part of file
            if( doc_name != "" ) {
               result :+= createFilename(buf_name,doc_name);
            } else {
               result :+= _strip_filename(buf_name,'P');
            }
            i = j+3;
            break;
         default:
            // If we got here, then the code is %F
            if( doc_name != "" ) {
               result :+= createFilename(buf_name,doc_name);
            } else {
               // No special processing, so let _print() handle it
               result :+= substr(string,j,2);
            }
            i = j+2;
         }

         // Next code
         continue;
      }

      // All other cases
      switch( upcase(substr(string,j+1,2)) ) {
      case "TE":
         // European time
         result :+= _time('M');
         i = j+3;
         break;
      case "DE":
         // European date
         parse _date() with mm'/'dd'/'yyyy;
         result :+= dd'/'mm'/'yyyy;
         i = j+3;
         break;
      default:
         // No special processing, so let _print() handle it
         result :+= substr(string,j,2);
         i = j+2;
      }
   }
}
