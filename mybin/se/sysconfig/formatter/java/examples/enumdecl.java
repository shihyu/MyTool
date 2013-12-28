public class Context {
    enum State
    {
        OFF=1, INITIALIZING, RUNNING,
        QUIESCING(12) {
           public int getNum() {
              return num*RFLAG;
           }
        }
    }
}

