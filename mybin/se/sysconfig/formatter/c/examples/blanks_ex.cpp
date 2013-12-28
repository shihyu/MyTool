#ifndef _XGMOD
#define _XGMOD
#include <cstring>
#include <iostream>
#ifdef UNIX
#undef WINDOWS
#endif

struct XGDat {
    int x;
    char *bytes;
};

struct XGContext {
    float f;
    char  vx[12];
};

class XGExecutor
{
public:

    enum ExecState {STOPPED, BUSY, READY, CONFIGURING};

    XGExecutor();
    ~XGExecutor();

    ExecState Query();
    void Stop() {
        switch (Query()) {
        case BUSY:
        case READY:
            break;

        case CONFIGURING:
            break;

        default:
            break;
        }
    }

private:
    int x;
    int y;
    float er;
    float ex;
};

// 10 blank lines after this comment











#endif
