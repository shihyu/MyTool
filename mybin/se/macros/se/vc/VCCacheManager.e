////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#import "stdprocs.e"
#import "fileman.e"
#require "sc/lang/IComparable.e"
#require "se/vc/VCRepositoryCache.e"
#include "VCCache.sh"
#endregion Imports

namespace se.vc.vccache;
using se.vc.vccache.VCRepositoryCache;

/**
 * This class manages the set of repository caches if the user has more than one 
 * repository. 
 * 
 * @author shackett (9/15/2009)
 */
class VCCacheManager {
   private se.vc.vccache.VCRepositoryCache m_svnRepositoryCache:[];
   private _str m_rootFolder = "";

   /**
    * Constructor implementation
    */
   public VCCacheManager()
   {
      m_rootFolder = _ConfigPath():+"versioncache":+FILESEP;
      // create the directory if it doesn't exist
      if (path_exists(m_rootFolder) == false) {
         make_path(m_rootFolder);
      }
   }

   /**
    * Destructor implementation
    */
   public ~VCCacheManager()
   {
      m_svnRepositoryCache = null;
   }

   /**
    * Returns the SvnRepositoryCache object that represents the cache given the 
    * URL of the SVN repository.  SvnRepositoryCache objects must be created 
    * this way, not by declaring instances of them 
    * 
    * @author shackett (9/24/2009)
    * 
    * @param repositoryUrl : the URL of the SVN repository to get a cache for.
    */
   public VCRepositoryCache getSvnCache(_str repositoryUrl)
   {
      // uppercase the URL, which we key by
      _str key = upcase(repositoryUrl);
      // see if we store this repository
      se.vc.vccache.VCRepositoryCache* requestedCache = m_svnRepositoryCache._indexin(key);
      if (!requestedCache) {
         // if not, make a new one and initialize it
         VCRepositoryCache newCache();
         newCache.init(m_rootFolder, repositoryUrl);
         // add it to the hashtable
         m_svnRepositoryCache:[key] = newCache;
         requestedCache = m_svnRepositoryCache._indexin(key);
      }
      // return the svn cache
      return *requestedCache;
   }

};
