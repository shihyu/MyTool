#pragma once

enum CMERROR_TLEXER {
    CMRC_TLEXER_EXPECTING_PROCESSING_INSTRUCTION_NAME = -103499,
    CMRC_TLEXER_EXPECTING_CDATA_BRACKET = -103498,
    CMRC_TLEXER_EXPECTING_A_MARKUP_DECLARATION = -103497,
    CMRC_TLEXER_EXPECTING_LTMINUSMINUS_LTEXBRACKET_CDATA_BRACKET = -103496,
    CMRC_TLEXER_EXPECTING_ELEMENT_NAME = -103495,
    CMRC_TLEXER_EXPECTING_ENTITY_NAME = -103494,
    CMRC_TLEXER_EXPECTING_ATTRIBUTE_NAME = -103493,
    CMRC_TLEXER_EXPECTING_ATTRIBUTE_VALUE = -103492,
    CMRC_TLEXER_ENTITY_REFERENCE_MUST_BE_TERMINATED_WITH_SEMICOLON = -103491,
    CMRC_TLEXER_ENTITY_REFERENCE_MUST_BE_FOLLOWED_BY_ENTITY_NAME = -103490,
    CMRC_TLEXER_ENTITY_NOT_FOUND = -103489,
    CMRC_TLEXER_STRING_NOT_TERMINATED = -103488,
    CMRC_TLEXER_COMMENT_NOT_TERMINATED = -103487,
    CMRC_TLEXER_ELEMENT_NOT_TERMINATED = -103486,
    CMRC_TLEXER_UNKNOWN_TAG_MUST_BE_DEFINED = -103485,
    CMRC_TLEXER_FILE_ALREADY_INCLUDED_1ARG = -103484,
    CMRC_TLEXER_COMMENT_DELIMITER_EXPECTED = -103483,
    CMRC_TLEXER_REGEX_KEYWORD_MUST_EVALUATE_TO_CHARACTER_SET_1ARG = -103482,
    CMRC_TLEXER_INVALID_SUFFIX_ON_NUMBERIC_CONSTANT = -103481,
    CMRCEND_TLEXER = -103500,
};