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
#pragma option(metadata,"optionsxml.e")
#include "xml.sh"

/**
 * 
 * Retrieves XML profile settings for specified profile. 
 *  
 * <p>Xml contains all (merged) settings for this 
 * profile. 
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                       display unescaped)
 * @param optionLevel   optionLevel=0 specifies the user level 
 *                      settings. There may be project and
 *                      workspace levels in the future.
 * 
 * @return If successful, returns xml cfg handle to XML 
 *         profile property settings. Otherwise, a negative
 *         error code is returned. Use _xmlcfg_close to free the
 *         xml.
 */
extern int _plugin_get_profile(_str escapedProfilePackage,_str profileName, int optionLevel=0);
/**
 * 
 * Retrieves XML user (diff) profile settings for specified 
 * profile. 
 *  
 * <p>Xml contains user diff of settings for this profile.
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                       display unescaped)
 * @param create_inside_options_node 
 *                      When true, profile is returned inside an
 *                      "options" element. This is typically
 *                      what you want when importing/exporting
 *                      single profiles in .cfg.xml files.
 * @param optionLevel   optionLevel=0 specifies the user level 
 *                      settings. There may be project and
 *                      workspace levels in the future.
 * 
 * @return If successful, returns xml cfg handle to XML 
 *         profile property settings. Otherwise, a negative
 *         error code is returned. Use _xmlcfg_close to free the
 *         xml.
 *  
 * @see _plugin_get_profile 
 */
extern int _plugin_get_user_profile(_str escapedProfilePackage,_str profileName, bool create_inside_options_node=true, int optionLevel=0);
/**
 * Sets XML profile settings for specified profile. 
 *  
 * <p>Only modified settings are stored in the user options 
 * xml.
 * 
 * @param iHandle  handle to XML returned any function that 
 *                 creates valid xml cfg XML
 *                 (_plugin_get_profile, _xmlcfrg_create, etc.)
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 */
extern void _plugin_set_profile(int handle, int optionLevel=0);
/**
 * sets user (diff) profile settings for specified profile. 
 *  
 * <p>Xml contains user diff of settings for this profile.
 * 
 * @param iHandle  handle to XML returned any function that 
 *                 creates or opens valid xml cfg XML. This
 *                 handle is typically from XML which was
 *                 created by calling _plugin_get_user_profile()
 *                 to export the XML.
 *                 
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 */
extern void _plugin_set_user_profile(int handle, int optionLevel=0);
/**
 * Deletes the specified profile. 
 *  
 * <p>Only use level profiles can be deleted. 
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                    display unescaped)
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 */
extern void _plugin_delete_profile(_str escapedProfilePackage,_str profileName,int optionLevel=0);
/**
 * Retrieves property setting for profile specified.
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package this
 *               profile (profileName) is
 *               contained in.
 * @param profileName
 *               Name of the profile to retrieve (for
 *               display unescaped)
 * @param name    Name of property ('n' attribute)
 * @param defaultValue Returned value if property or profile not
 *                     found.
 * @param apply   Set to 'apply' atribute setting.
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 * 
 * @return Returns property setting if found. Otherwise returns
 *         defaultValue specified.
 */
extern _str _plugin_get_property(_str escapedProfilePackage,_str profileName,_str name, _str defaultValue='',bool &apply=null,int optionLevel=0);
/**
 * Retrieves property attributes for attr element
 * 
 * @param escapedProfilePackage
 *                The escaped profile package.
 *                Specifies the package this
 *                profile (profileName) is
 *                contained in.
 * @param profileName
 *                Name of the profile to retrieve (for
 *                display unescaped)
 * @param name    Name of property ('n' attribute)
 * @param hashtab (Output only) Set to attributes of first 
 *                &lt;attr&gt; element beneath the &lt;p&gt;
 *                element.
 * @param apply   Set to 'apply' atribute setting.
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 */
extern void _plugin_get_property_attrs(_str escapedProfilePackage,_str profileName,_str name, _str (&hashtab):[],bool &apply=null,int optionLevel=0);
/**
 * Retrieves property attributes for attr element and puts them 
 * in class where class members match the attribute names. 
 * 
 * @param escapedProfilePackage
 *                The escaped profile package.
 *                Specifies the package this
 *                profile (profileName) is
 *                contained in.
 * @param profileName
 *                Name of the profile to retrieve (for
 *                display unescaped)
 * @param name    Name of property ('n' attribute)
 * @param className Class name. Used to construct new instance.
 * @param classInst (Output only) Results for attributes 
 *                of first &lt;attr&gt; element beneath the
 *                &lt;p&gt; element.
 * @param apply   Set to 'apply' atribute setting.
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 */
extern void _plugin_get_property_class(_str escapedProfilePackage,_str profileName,_str name, _str className, typeless &classInst,bool &apply=null,int optionLevel=0);
/**
 * Retrieves property setting for profile specified which has 
 * xml value. 
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package this
 *               profile (profileName) is
 *               contained in.
 * @param profileName
 *               Name of the profile to retrieve (for
 *               display unescaped)
 * @param name    Name of property ('n' attribute)
 * @param apply   Set to 'apply' atribute setting.
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 * 
 * @return Returns handle>=0 to xml if found. 
 *         Otherwise returns negative number
 */
extern int _plugin_get_property_xml(_str escapedProfilePackage,_str profileName,_str name,bool &apply=null,int optionLevel=0);


/**
 * Retreives property info for longest prefix or suffix 
 * match.
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package this
 *               profile (profileName) is
 *               contained in.
 * @param profileName
 *               Name of the profile to retrieve (for
 *               display unescaped)
 * @param string  property name found match is a prefix or 
 *                suffix match of this string.
 * @param setValueAndApply   True if value and apply 
 *                               arguments need to be set.
 * @param value   Set to value of property found.
 * @param apply   Set to 'apply' atribute setting.
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 * 
 * @return If found, returns name of property, otherwie a null 
 *         string is returned (name._isempty()).
 */
extern _str _plugin_find_longest_property(_str escapedProfilePackage,_str profileName,_str string,bool doPrefixMatch=true, bool setValueAndApply=false, _str &value=null, bool &apply=null, int optionLevel=0);

/**
 * Deletes property for profile specified. 
 *  
 * Note: This adds a "d" element to the user profile if the 
 * property exists in a built-in/system profile. 
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package this
 *               profile (profileName) is
 *               contained in.
 * @param profileName
 *               Name of the profile to retrieve (for
 *               display unescaped)
 * @param name   Name of property ('n' attribute)
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 */
extern void _plugin_delete_property(_str escapedProfilePackage,_str profileName, _str name,int optionLevel=0);
/**
 * sets property for profile specified.
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package this
 *               profile (profileName) is
 *               contained in.
 * @param profileName
 *               Name of the profile to retrieve (for
 *               display unescaped)
 * @param profileVersion Version of profile. Only used if new 
 *                       profile is created.
 * @param name   Name of property ('n' attribute)
 * @param value
 * @param apply  If specified (non-null), sets 'apply'
 *               attribute.
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 */
extern void _plugin_set_property(_str escapedProfilePackage,_str profileName,_str profileVersion, _str name,_str value,bool apply=null,int optionLevel=0);
/**
 * sets property attrs for profile specified.
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package this
 *               profile (profileName) is
 *               contained in.
 * @param profileName
 *               Name of the profile to retrieve (for
 *               display unescaped)
 * @param profileVersion Version of profile. Only used if new 
 *                       profile is created.
 * @param name   Name of property ('n' attribute)
 * @param hashtab Attribute name and value pairs. Put in 
 *                &lt;attr&gt; element beneath the &lt;p&gt;
 *                element.
 * @param apply  If specified (non-null), sets 'apply'
 *               attribute.
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 */
extern void _plugin_set_property_attrs(_str escapedProfilePackage,_str profileName,_str profileVersion, _str name,_str (&hashtab):[],bool apply=null,int optionLevel=0);
/**
 * sets property attrs for profile specified.
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package this
 *               profile (profileName) is
 *               contained in.
 * @param profileName
 *               Name of the profile to retrieve (for
 *               display unescaped)
 * @param profileVersion Version of profile. Only used if new 
 *                       profile is created.
 * @param name   Name of property ('n' attribute)
 * @param classInst Attribute name and value pairs. Put in 
 *                &lt;attr&gt; element beneath the &lt;p&gt;
 *                element.
 * @param apply  If specified (non-null), sets 'apply'
 *               attribute.
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 */
extern void _plugin_set_property_class(_str escapedProfilePackage,_str profileName,_str profileVersion, _str name,typeless &classInst,bool apply=null,int optionLevel=0);
/** 
 * sets property for profile specified which has XML setting.
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                    display unescaped)
 * @param handle    Handle to xml
 * @param profileVersion Version of profile. Only used if new 
 *                       profile is created.
 * @param apply   If not null, sets 'apply' attribute.
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 *  
 */
extern void _plugin_set_property_xml(_str escapedProfilePackage,_str profileName,_str profileVersion,_str name,int handle,bool apply=null,int optionLevel=0);

/**
 * Retrieves profile names contained in package specified.
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package to list
 *               profiles for.
 * @param profileNames
 *               Set to unescaped (for display) profile
 *               names.
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 */
extern void _plugin_list_packages(_str escapedProfilePackage,_str (&profileNames)[], int optionLevel=0);
/**
 * Retrieves profile names contained in package specified.
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package to list
 *               profiles for.
 * @param profileNames
 *               Set to unescaped (for display) profile
 *               names.
 * @param matchNamePrefix
 *               Profile name prefix to
 *               match. Specify "" to match all profile names.
 * @param matchNameSearchOptions
 *               When !=null, this specifies search() style
 *               search options and a contains match (not prefix
 *               match) is performed. Typically used to match a
 *               regular expressions. (Ex.
 *               matchNameSearchOptions="L" where
 *               matchNamePrefix="^[^;]+;something$")
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 */
extern void _plugin_list_profiles(_str escapedProfilePackage,_str (&profileNames)[],_str matchNamePrefix='', _str matchNameSearchOptions=null, int optionLevel=0);
/**
 * Retrieves user profile names 
 *  
 * Note: escapedProfilePackage can be ''. 
 * 
 * @param escapedProfilePackage
 *               The escaped profile package.
 *               Specifies the package to list
 *               profiles for.
 * @param profileNames
 *               Set to unescaped (for display) profile
 *               names.
 * @param matchNamePrefix
 *               Profile name prefix to
 *               match. Specify "" to match all profile names.
 * @param matchNameSearchOptions
 *               When !=null, this specifies search() style
 *               search options and a contains match (not prefix
 *               match) is performed. Typically used to match a
 *               regular expressions. (Ex.
 *               matchNameSearchOptions="L" where
 *               matchNamePrefix="^[^;]+;something$")
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 */
extern void _plugin_list_user_profiles(_str escapedProfilePackage,_str (&profileNames)[],_str matchNamePrefix='', _str matchNameSearchOptions=null, int optionLevel=0);
/** 
 * Indicates if profile has non-user (builtin) settings. 
 *  
 * <p>If a profile has non-user (builtin) settings, user 
 * settings can be cleared (reset) with _plugin_delete_profile 
 * but the (builtin) profile can't be deleted. 
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                    display unescaped)
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 *  
 * @return Returns non-zero value if profile has non-user 
 *         (builtin) settings.
 */
extern bool _plugin_has_builtin_profile(_str escapedProfilePackage, _str  profileName, int optionLevel=0);


/** 
 * Indicates if a profile exists in the current config
 *  
 * <p>Unlike the _plugin_has_profile_ex() function, this 
 * function does not need to fetch the profile XML and is 
 * cheaper to call. 
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                    display unescaped)
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 *  
 * @return Returns true if the specified profile exists in the 
 *         current config.
 */
extern bool _plugin_has_profile(_str escapedProfilePackage, _str  profileName, int optionLevel=0);


/** 
 * Indicates if a profile exists in the current config
 *  
 * <p>If a profile has non-user (builtin) settings, user 
 * settings can be cleared (reset) with _plugin_delete_profile 
 * but the (builtin) profile can't be deleted. 
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                    display unescaped)
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 *  
 * @return Returns 0x1 bit set if a built-in profile exists. 
 *         Returns 0x2 bit set if a user level profile exists.
 *         Both flags may be set. 0 is returned if the profile
 *         does not exist.
 */
extern int _plugin_has_profile_ex(_str escapedProfilePackage, _str  profileName, int optionLevel=0);
/** 
 * Indicates if property has non-user (builtin) setting. 
 *  
 * <p>non-user properties can be removed (a 'd' element is added
 * automatically).
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                    display unescaped)
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 *  
 * @return Returns non-zero value if property has non-user 
 *         (builtin) setting.
 */
extern bool _plugin_has_builtin_property(_str escapedProfilePackage, _str profileName, _str propertName, int optionLevel=0);
/** 
 * Indicates if this property exists
 *  
 * <p>non-user properties can be removed (a 'd' element is added
 * automatically). Returns false for deleted properties.
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                    display unescaped)
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 *  
 * @return Returns non-zero value if this property exists
 */
extern bool _plugin_has_property(_str escapedProfilePackage, _str profileName, _str propertName, int optionLevel=0);
/** 
 * Indicates if this property exists
 *  
 * <p>If a property has non-user (builtin) setting, user 
 * settings can be cleared (reset) with 
 * _plugin_delete_property but the (builtin) property can't 
 * be deleted. 
 *  
 *  
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                    display unescaped)
 * @param optionLevel
 *                optionLevel=0 specifies the user level
 *                settings. There may be project and
 *                workspace levels in the future.
 *  
 * @return Returns 0x1 bit set if a built-in property 
 *         exists. Returns 0x2 bit set if a user level
 *         property exists. Both flags may be set. 0 is
 *         returned if the property does not exist.
 */
extern int _plugin_has_property_ex(_str escapedProfilePackage, _str profileName, _str propertName, int optionLevel=0);
/**
 * Retrieves current user XML settings
 *  
 * @param optionLevel   optionLevel=0 specifies the user level 
 *                      settings. There may be project and
 *                      workspace levels in the future.
 * 
 * @return Returns xml cfg handle to user.cfg.xml. Use 
 *         _xmlcfg_close to free the xml.
 */
extern int _plugin_get_user_options(int optionLevel=0);
/**
 * Retrieves current modify setting for user options 
 *  
 * <p>The _plugin_set_profile and _plugin_set_property calls 
 * modify the user options and set modify=true. 
 *  
 * @param optionLevel   optionLevel=0 specifies the user level 
 *                      settings. There may be project and
 *                      workspace levels in the future.
 * 
 * @return Returns modify setting for user options.
 */
extern bool _plugin_get_user_options_modify(int optionLevel=0);
/**
 * Sets current modify setting for user options
 * 
 * @param modify  New setting for user options modify.
 * @param optionLevel
 *               optionLevel=0 specifies the user level
 *               settings. There may be project and
 *               workspace levels in the future.
 */
extern void _plugin_set_user_options_modify(bool modify,int optionLevel=0);
/**
 * Returns length of package for fully qualified profile
 * 
 * @param escapedPackage
 *               The escaped profile package. Specifies
 *               the package this profile (profileName)
 *               is contained in.
 * @param includeTrailingSep Optionally return length including 
 *                           trailing '.'.
 * 
 * @return Returns length of escaped package for fully qualified
 *         profile name
 */
extern int  _plugin_get_profile_package_len(_str escapedPackage, bool includeTrailingSep=false);
/**
 * Returns package for fully qualified profile
 * 
 * @param escapedPackage
 *               The escaped profile package. Specifies
 *               the package this profile (profileName)
 *               is contained in.
 * 
 * @return Returns escaped package for fully qualified profile 
 *         name
 */
extern _str _plugin_get_profile_package(_str escapedPackage);
/**
 * Returns profile name for fully qualified profile
 * 
 * @param escapedPackage
 *               The escaped profile package. Specifies
 *               the package this profile (profileName)
 *               is contained in.
 * 
 * @return Returns unescaped profile name for fully qualified 
 *         profile.
 */
extern _str _plugin_get_profile_name(_str escapedPackage);
/**
 * Returns profile name in correct case
 * 
 * @param escapedPackage
 *               The escaped profile package. Specifies
 *               the package this profile (profileName)
 *               is contained in.
 * @param profileName  profile name in possibly a different case
 *                     than the this profile
 * @param optionLevel   optionLevel=0 specifies the user level 
 *                      settings. There may be project and
 *                      workspace levels in the future.
 *  
 * @return Returns profile name in the case it was defined in. 
 *         If the profile is not defined, profileName is
 *         returned unchanged.
 */
extern _str _plugin_get_profile_name_case(_str escapedPackage,_str profileName,int optionLevel=0);
/**
 * Returns escaped fully qualified profile name
 * 
 * @param escapedPackage
 *               The escaped profile package. Specifies
 *               the package this profile (profileName)
 *               is contained in.
 * @param profileName Unescaped profile name
 * 
 * @return Returns escaped fully qualified profile name
 */
extern _str _plugin_append_profile_name(_str escapedPackage,_str profileName);
/**
 * Returns escaped package name
 * 
 * @param packageName
 *               The unescaped package name.
 * 
 * @return Returns escaped package name
 */
extern _str _plugin_escape_profile(_str packageName);
/**
 * Returns unescaped package name
 * 
 * @param escapedPackageName
 *               The escaped package name.
 * 
 * @return Returns escaped package name
 */
extern _str _plugin_unescape_profile(_str escapedPackageName);

/**
 * Returns escaped package name
 * 
 * @param escapedPackageName
 *               Full package name with profile which is all
 *               escaped.
 * 
 * @return Returns encoded filename which can be used as the 
 *         name part (no path) of a file.
 */
extern _str _plugin_encode_filename(_str escapedPackageName);
/**
 * Returns unescaped package name
 * 
 * @param encodedFilename
 *               Encoded filename returned from
 *               _plugin_encode_filename.
 * 
 * @return Returns escaped package name
 */
extern _str _plugin_decode_filename(_str encodedFilename);

/**
 * Applies bindings specified by a profile to an event table.
 *  
 * @param escapedPackage
 *               The escaped profile package. Specifies
 *               the package this profile (profileName)
 *               is contained in.
 * @param profileName    Name of the profile to retrieve (for 
 *                       display unescaped)
 * @param kt_index   names table index of event table to apply 
 *                   the binding changes to.
 * 
 * @return  Returns 0 if successful. Otherwise a negative return 
 *          code is returned.
 */
extern int _plugin_eventtab_apply_bindings(_str escapedPackage,_str profileName,int kt_index,int optionLevel=0,bool reserved=true);


/**
 * Creates or profile instance 
 *  
 * <p>When modifying a plugin profile, it's easier to and often 
 * more effecient to use this interface instead of getting and 
 * setting properties individually or with an XMLCFG handle. 
 *  
 * <p>Using a profile instance also has the advantage of sorting
 * the properties by property name (always case sensitive).
 *  
 * @return Returns profile instance handle if successful. 
 *         Otherwise a negative return code defined in "rc.sh"
 *         is returned
 */
extern int _profile_create();
/**
 * Creates or profile instance and loads properties from profile
 * specified. 
 *  
 * <p>When modifying a plugin profile, it's easier to and often
 * more effecient to use this interface instead of getting and
 * setting properties individually or with an XMLCFG handle.
 * <p>Using a profile instance also has the advantage of sorting
 * the properties by property name (always case sensitive).
 * 
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                       display unescaped)
 *  
 * @param optionLevel   optionLevel=0 specifies the user level 
 *                      settings. There may be project and
 *                      workspace levels in the future.
 * 
 * @return Returns profile instance handle if successful. 
 *         Otherwise a negative return code defined in "rc.sh"
 *         is returned
 */
extern int _profile_open(_str escapedProfilePackage,_str profileName,int optionLevel=0);
/**
 * Frees the profile instance allocated by 
 * _profile_create() or _profile_open()
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 */
extern void _profile_close(int iprofile);
/**
 * Clears existing property settings
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 */
extern void _profile_clear(int iprofile);

/**
 * Saves properties to the plugin profile specified. 
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                       display unescaped)
 * @param version        Version for the profile.
 * @param mustExistInProfile  When specified, only properties 
 *                            which exist in this profile will
 *                            be added to the destination
 *                            profile (profileName).
 * @param optionLevel   optionLevel=0 specifies the user level 
 *                      settings. There may be project and
 *                      workspace levels in the future.
 * 
 * @return Returns 0 if successful.
 */
extern int _profile_save(int iprofile, _str escapedProfilePackage, _str profileName,_str version,_str mustExistInProfile="",int optionLevel=0);

/**
 * Add property settings from the profile specified
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param escapedProfilePackage  The escaped profile package. 
 *                               Specifies the package this
 *                               profile (profileName) is
 *                               contained in.
 * @param profileName Name of the profile to retrieve (for 
 *                       display unescaped)
 * @param clear         When true, existing properties are 
 *                      cleared before added properties from the
 *                      profile specified.
 * @param optionLevel   optionLevel=0 specifies the user level 
 *                      settings. There may be project and
 *                      workspace levels in the future.
 * 
 * @return Returns 0 if successful.
 */
extern int _profile_set_properties(int iprofile,_str escapedProfilePackage,_str profileName,bool clear=true,int optionLevel=0);

/**
 * Deletes properties 
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param name       Property name to set.
 * @param matchPrefix  When true, all properties which start 
 *                     with the prefix specified by the name
 *                     argument are deleted.
 * 
 * @return Returns 0 if successful.
 */
extern int _profile_delete_property(int iprofile,_str name,bool matchPrefix=false);

/**
 * Retrieves property settings.
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param name       Property name to retrieve settings for.
 * @param defaultValue Value returned if the property does not 
 *                     exist.
 * @param apply      Set to true if the "apply" attribute is not 
 *                   present, set to 1, or the property does not
 *                   exist.
 * 
 * @return Returns the value for the property or defaultValue is 
 *         the property does not exist.
 */
extern _str _profile_get_property(int iprofile,_str name, _str defaultValue='', bool &apply=null);
/**
 * Retrieves property attributes for attr element
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param name       Property name to retrieve settings for.
 * @param hashtab (Output only) Set to attributes of first 
 *                &lt;attr&gt; element beneath the &lt;p&gt;
 *                element.
 * @param apply      Set to true if the "apply" attribute is not 
 *                   present, set to 1, or the property does not
 *                   exist.
 * 
 * @return Returns the value for the property or defaultValue is 
 *         the property does not exist.
 */
extern void _profile_get_property_attrs(int iprofile,_str name, _str (&hashtab):[], bool &apply=null);
/**
 * Retrieves property attributes for attr element and puts them 
 * in class where class members match the attribute names. 
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param name       Property name to retrieve settings for.
 * @param className Class name. Used to construct new instance.
 * @param classInst (Output only) Results for attributes 
 *                of first &lt;attr&gt; element beneath the
 *                &lt;p&gt; element.
 * @param apply      Set to true if the "apply" attribute is not 
 *                   present, set to 1, or the property does not
 *                   exist.
 * 
 * @return Returns the value for the property or defaultValue is 
 *         the property does not exist.
 */
extern void _profile_get_property_class(int iprofile,_str name, _str className, typeless &classInst, bool &apply=null);

/**
 * Sets property 
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param name       Property name to retrieve settings for.
 * @param value      Value of property
 * @param apply      If not null, sets the apply attribute to 
 *                   this value.
 */
extern void _profile_set_property(int iprofile,_str name,_str value,bool apply=null);

/**
 * sets property attrs for profile specified.
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param name       Property name to retrieve settings for.
 * @param hashtab Attribute name and value pairs. Put in 
 *                &lt;attr&gt; element beneath the &lt;p&gt;
 *                element.
 * @param apply      If not null, sets the apply attribute to 
 *                   this value.
 */
extern void _profile_set_property_attrs(int iprofile,_str name,_str (&hashtab):[],bool apply=null);

/**
 * sets property attrs for profile specified.
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param name       Property name to retrieve settings for.
 * @param classInst Attribute name and value pairs. Put in 
 *                &lt;attr&gt; element beneath the &lt;p&gt;
 *                element.
 * @param apply      If not null, sets the apply attribute to 
 *                   this value.
 */
extern void _profile_set_property_class(int iprofile,_str name,typeless &classInst,bool apply=null);
/**
 * Retrieves property XML and apply attribute setting.
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param name       Property name to retrieve settings for.
 * @param apply      Set to true if the "apply" attribute is not 
 *                   present, set to 1, or the property does not
 *                   exist.
 * 
 * @return Returns handle>=0 to xml if found. 
 *         Otherwise returns negative number
 */
extern int _profile_get_property_xml(int iprofile,_str name, bool &apply=null);

/**
 * sets property for profile specified which has XML setting.
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param name
 * @param handle    Handle to xml
 * @param apply   If not null, sets 'apply' attribute.
 */
extern void _profile_set_property_xml(int iprofile,_str name,int handle,bool apply=null);

/**
 * Retrieves property info based on search criteria
 *  
 * @param iprofile   handle to profile created by 
 *                   _profile_create()
 * @param array   (Output only) Set to array with property info.
 * @param matchNamePrefix
 *               Property name prefix to
 *               match. Specify "" to match all
 *               property names.
 * @param matchNameSearchOptions
 *               When !=null, this specifies search() style
 *               search options and a contains match (not prefix
 *               match) is performed. Typically used to match a
 *               regular expressions. (Ex.
 *               matchNameSearchOptions="L" where
 *               matchNamePrefix="^[^;]+;something$")
 * @param matchValue
 *               Value to match. Specify null to
 *               match all values.
 * @param matchValueSearchOptions
 *               When !=null, this specifies search() style
 *               search options and a contains match (not match
 *               of entire value) is performed. Typically used
 *               to match a regular expressions. (Ex.
 *               matchValuwSearchOptions="L" where
 *               matchValue="^[^;]+;something$")
 */
extern void _profile_list_properties(int iprofile,XmlCfgPropertyInfo (&array)[], _str matchNamePrefix='',_str matchNameSearchOptions=null,_str matchValue=null,_str matchValueSearchOptions=null);

/**
 * Indicates whether there is a user options file.
 *  
 * <p>This function is useful for determining whether you want 
 * to display a quick start dialog if the user doesn't have a 
 * user.cfg.xml file (first time invocation with clean config). 
 *  
 * 
 * @return Returns true if there is a user.cfg.xml file.
 */
extern bool _plugin_have_user_options();
/**
 * Returns path relative to plugin:// if possible in a format that can be inserted 
 * into the names table in a multi-platform way. 
 * 
 * @param filename  Input filename
 * 
 * @return Returns path relative to plugin:// if possible and uses forward slash 
 *         instead of platform specific FILESEP.
 *         Returns null if no relative path found.
 * @example 
 *     plugin://user_clark.macros/macro.e
 *     returns --> user_clark.macros.ver.1.0/macro.e
 */
extern _str _plugin_relative_path(_str filename);
/**
 * @return Return absolute path of user's local
 * plugins directory with a trailing file separator.
 */
extern _str _plugin_get_user_plugins_path();

/** 
 * Sets "def_vars" profile to state of def_XXX Slick-C 
 * variables. 
 *  
 */
extern void _def_vars_update_profile();
/** 
 * Assigns all Slick-C variables in the "def_vars" profile
 *  
 */
extern void _def_vars_apply_profile();
/** 
 * Assigns all Slick-C variables in the "def_vars" profile
 *  
 */
const VSPROFILE_STYLE_UNKNOWN= 0;
const VSPROFILE_STYLE_NORMALIZED= 1;
const VSPROFILE_STYLE_PACKAGE_ELEMENT= 2;
const VSPROFILE_STYLE_FULL_QUALIFIED_PROFILE_ELEMENT= 3;
const VSPROPERTY_STYLE_UNKNOWN= 0;
const VSPROPERTY_STYLE_NORMALIZED= 1;
const VSPROPERTY_STYLE_ELEMENT= 2;
extern void _xmlcfg_apply_profile_style(int handle,int profile_or_options_node,int profile_style=VSPROFILE_STYLE_UNKNOWN,int property_style=VSPROPERTY_STYLE_UNKNOWN,_str requiredPropertyNamePrefix='',int option_level=0);

extern void _plugin_reload_option_levels(int new_NofOptionsLevels, int reserved=0, _str (&array1)[]=null,_str (&array2)[]=null,_str (&array3)[]=null);
