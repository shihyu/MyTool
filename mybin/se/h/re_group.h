#ifndef REGROUP_H
#define REGROUP_H

#define MAX_RE_GROUPS  10

struct re_group_t {
   int begin; // Offset from beginning of match
   int end; // Past end. Offset from beginning of match
};


#endif // REGROUP_H
