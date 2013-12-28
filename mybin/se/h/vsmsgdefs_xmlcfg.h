#ifndef VSMSGDEFS_XMLCFG_H
#define VSMSGDEFS_XMLCFG_H

enum VSMSGDEFS_XMLCFG {
    VSRC_XMLCFG_EXPECTING_ROOT_ELEMENT_NAME = -5400,
    VSRC_XMLCFG_EXPECTING_QUOTED_SYSTEM_ID = -5401,
    VSRC_XMLCFG_STRING_NOT_TERMINATED = -5402,
    VSRC_XMLCFG_NOT_USED1 = -5403,
    VSRC_XMLCFG_START_TAG_NOT_TERMINATED = -5404,
    VSRC_XMLCFG_COMMENT_NOT_TERMINATED = -5405,
    VSRC_XMLCFG_INVALID_CHARACTERS_IN_COMMENT = -5406,
    VSRC_XMLCFG_EXPECTING_AN_ELEMENT_NAME = -5407,
    VSRC_XMLCFG_EXPECTING_ATTRIBUTE_NAME = -5408,
    VSRC_XMLCFG_EXPECTING_EQUAL_AFTER_ATTRIBUTE_NAME = -5409,
    VSRC_XMLCFG_ATTRIBUTE_VALUE_MUST_BE_QUOTED = -5410,
    VSRC_XMLCFG_PROCESSING_INSTRUCTION_NOT_TERMINATED = -5411,
    VSRC_XMLCFG_INPUT_ENDED_BEFORE_ALL_TAGS_WERE_TERMINATED = -5412,
    VSRC_XMLCFG_EXPECTING_QUOTED_PUBLIC_ID = -5413,
    VSRC_XMLCFG_DOCTYPE_INTERNAL_SUBSET_NOT_TERMINATED = -5414,
    VSRC_XMLCFG_INVALID_DOCUMENT_STRUCTURE = -5414,
    VSRC_XMLCFG_EXPECTING_SYSTEM_OR_PUBLIC_ID = -5416,
    VSRC_XMLCFG_EXPECTING_PROCESSOR_NAME = -5417,
    VSRC_XMLCFG_FILE_ALREADY_OPEN = -5418,
    VSRC_XMLCFG_XML_DECLARATION_NOT_TERMIANTED = -5419,
    VSRC_XMLCFG_EXPECTING_COMMENT_OR_CDATA = -5420,
    VSRC_XMLCFG_CDATA_NOT_TERMINATED = -5421,
    VSRC_XMLCFG_ATTRIBUTE_NOT_FOUND = -5422,
    VSRC_XMLCFG_NAME_NOT_FOUND = -5423,
    VSRC_XMLCFG_CANT_ADD_CHILD_NODE_TO_ATTRIBUTE_NODE = -5424,
    VSRC_XMLCFG_ATTRIBUTES_MUST_BE_THE_FIRST_CHILDREN = -5425,
    VSRC_XMLCFG_CANT_ADD_SIBLING_TO_ROOT_NODE = -5426,
    VSRC_XML_SYSTEM_FAILED_TO_INITIALIZE = -5427,
    VSRC_XML_UNEXPECTED_PARSING_ERROR1 = -5428,
    VSRC_XML_GENERAL_PARSING_ERROR = -5429,
    VSRC_XML_UNEXPECTED_PARSING_ERROR = -5430,
    VSRC_XML_INTERNAL_ERROR_PROC_INDEX_NOT_FOUND = -5431,
    VSRC_XMLCFG_NO_CHILDREN_COPIED = -5432,
    VSRC_XMLCFG_INVALID_HANDLE = -5433,
    VSRC_XMLCFG_INVALID_NODE_INDEX = -5434,
    VSRC_XMLCFG_TOO_MANY_END_TAGS = -5435,
};

#endif