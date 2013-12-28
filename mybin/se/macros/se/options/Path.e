////////////////////////////////////////////////////////////////////////////////////
// $Revision: 40558 $
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
#require "Property.e"
#endregion Imports

namespace se.options;

#define DEFAULT_PATH '<default>'

/**
 * Keeps track of the type of path - a path to a file or a path 
 * to a directory. 
 */
enum PATH_TYPE {
   FILEPATH,
   DIRECTORYPATH
};

/** 
 * This class keeps track of a property with a value that is
 * path, either to a specific file or to a whole directory.
 * 
 */
class Path : Property {
   // the type of path this is - either a file (FILEPATH) or a directory (DIRECTORYPATH)
   private PATH_TYPE m_type;
   // the string that separates one path from another - only used with paths 
   // which accept multiple values
   private _str m_delimiter = '';
   // whether to encode any environment variables within the path(s)
   private boolean m_encodeEnvVars = false;

   /**
    * Constructor.
    */
   Path(_str caption = '', int index = 0, PATH_TYPE type = FILEPATH, _str delimiter = '', boolean encode = false)
   {
      Property(caption, index);
      m_type = type;
      m_delimiter = delimiter;
      m_encodeEnvVars = encode;
   }

   /* Updates the current value.  If the new value
    * is equal to the old value, does nothing. 
    * 
    * @param newValue      new value to be set
    * 
    * @return _str         current value (which may be newly 
    *                      updated)
    */
   public _str updateValue(_str newValue)
   {
      newValue = maybeEncodeEnvVars(newValue);
      return Property.updateValue(newValue);
   }
   
   /** 
    * Sets the initial value.  This function differs from 
    * updateValue because it sets the original value as well.
    * 
    * @param newValue      new value
    */
   public void setValue(_str newValue)
   {
      newValue = maybeEncodeEnvVars(newValue);
      Property.setValue(newValue);
   }
   
   /**
    * Possibly encodes any environment variables in the property value, if 
    * m_encodeEnvVars is set to true. 
    * 
    * @param value          path value             
    * 
    * @return _str          path value, possibly with environment vars encoded
    */
   private _str maybeEncodeEnvVars(_str value)
   {
      if (m_encodeEnvVars) {
         // we might need to split up the paths
         _str paths[];
         valueToPathArray(value, paths);

         for (i := 0; i < paths._length(); i++) {
            path := paths[i];
   
            // take the quotes off - it can screw up the environment variables
            path = strip(path, 'B', '"');
            path = _encode_vsenvvars(path, (m_type == FILEPATH), false);
            path = maybe_quote_filename(path);

            paths[i] = path;
         }
      }
   
      return value;
   }

   /**
    * Creates an array of path values.  If this property allows 
    * multiple path settings, then each array item is one path.  If 
    * it does not, then the array will only have one item. 
    * 
    * @param value 
    * @param paths 
    */
   private void valueToPathArray(_str value, _str (&paths)[])
   {
      if (allowMultiplePaths()) {
         split(value, m_delimiter, paths);
      } else {
         paths[0] = value;
      }
   }

   /**
    * Given an array of paths, combines it into one string using 
    * the appropriate delimiter. 
    * 
    * @param paths 
    * 
    * @return _str 
    */
   private _str pathArrayToValue(_str (&paths)[])
   {
      value := '';
      for (i := 0; i < paths._length(); i++) {
         if (paths[i] != '') {
            // maybe add the delimiter
            if (value != '') value :+= m_delimiter;

            // add this path
            value :+= paths[i];
         }
      }

      return value;
   }

   /**
    * Returns the path type of this property.
    * 
    * @return path type
    */
   public PATH_TYPE getPathType()
   {
      return m_type;
   }

   /**
    * Returns the current property type (one of the PropertyType enum).  Should 
    * be overwritten by child classes. 
    * 
    * @return           property type of this object
    */
   public int getPropertyType()
   {
      if (m_type == FILEPATH) return FILE_PATH_PROPERTY;
      else return DIRECTORY_PATH_PROPERTY;
   }

   /**
    * Returns whether this setting allows multiple paths.
    * 
    * @return           true if this Property allows multiple paths
    */
   public boolean allowMultiplePaths()
   {
      return (m_delimiter :!= '');
   }

   /**
    * Retrieves the delimiter which separates multiple paths in this property. 
    * If multiple paths are not allowed for this property, this method returns 
    * ''. 
    * 
    * @return           delimiter
    */
   public _str getDelimiter()
   {
      return m_delimiter;
   }
};
