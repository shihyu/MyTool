////////////////////////////////////////////////////////////////////////////////////
// $Revision: $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2012 SlickEdit Inc. 
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
#import "slickc.e"
#import "stdprocs.e"
#import "xmlcfg.e"
#endregion

_str maven_get_pom_xml_text_value(_str pomXmlFilePath, _str xpathQuery)
{
    _str valueString = "";
    int xmlStatus;
    int xmlHandle = _xmlcfg_open(pomXmlFilePath, xmlStatus, VSXMLCFG_OPEN_ADD_PCDATA);
    if(xmlHandle > 0) {
        // Look for the node and get the text value
        int foundNode = _xmlcfg_find_simple(xmlHandle, xpathQuery);
        if(foundNode > 0) {
            int textNode = _xmlcfg_get_first_child(xmlHandle, foundNode);
            if(textNode > 0) {
                valueString = _xmlcfg_get_value(xmlHandle, textNode);
            }
        }
        _xmlcfg_close(xmlHandle);
    }

    return valueString;
}

_str maven_get_artifact_name(_str pomXmlFilePath)
{
    return maven_get_pom_xml_text_value(pomXmlFilePath,'project/artifactId');
}

_str maven_get_artifact_version(_str pomXmlFilePath)
{
    return maven_get_pom_xml_text_value(pomXmlFilePath,'project/version');
}

_str maven_get_artifact_packaging(_str pomXmlFilePath)
{
    return maven_get_pom_xml_text_value(pomXmlFilePath,'project/packaging');
}

_str maven_get_project_name(_str pomXmlFilePath)
{
    return maven_get_pom_xml_text_value(pomXmlFilePath,'project/name');
}

