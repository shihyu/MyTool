////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once

#include "vsdecl.h"


EXTERN_C int VSAPI tag_get_async_tagging_job(VSPSZ fileName, 
                                             int taggingFlags,
                                             int bufferId,
                                             VSPSZ fileDate,
                                             int lastModify,
                                             VSPSZ tagDatabase,
                                             int startLine,
                                             int startSeekPos,
                                             int stopSeekPos);

EXTERN_C int VSAPI tag_get_async_tagging_result(VSHREFVAR fileName, 
                                                VSHREFVAR taggingFlags, 
                                                VSHREFVAR bufferId,
                                                VSHREFVAR lastModified,
                                                VSHREFVAR updateFinished,
                                                VSHREFVAR tagDatabase,
                                                int waitForFinishedJob=0,
                                                int postponeSlowerJobs=0);

EXTERN_C int VSAPI tag_get_async_locals_bounds(VSHREFVAR startSeekpos, VSHREFVAR endSeekpos);

EXTERN_C int VSAPI tag_get_async_tag_database(VSHREFVAR tagDatabase);

EXTERN_C int VSAPI tag_insert_async_tagging_result(VSPSZ fileName, int taggingFlags, int bufferId);

EXTERN_C int VSAPI tag_dispose_async_tagging_result(VSPSZ fileName, int bufferId);

EXTERN_C void VSAPI vsTagStopAsyncTagging();

EXTERN_C void VSAPI tag_stop_async_tagging();

EXTERN_C void VSAPI tag_restart_async_tagging();

EXTERN_C int VSAPI tag_get_num_async_tagging_jobs(VSPSZ jobKind);

EXTERN_C int VSAPI tag_queue_async_database_job(VSPSZ filename_p,
                                                int tagging_flags,
                                                int buffer_id,
                                                VSPSZ language_p,
                                                VSPSZ tag_database,
                                                VSPSZ file_date,
                                                int last_modified,
                                                int modify_flags,
                                                VSHREFVAR taglist,
                                                VSHREFVAR linelist,
                                                VSHREFVAR wordlist);


