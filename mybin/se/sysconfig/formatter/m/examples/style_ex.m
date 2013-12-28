void here();
const char* there() { return "narf"; }

int stylefn(bool cond, bool err)
{
    // If on one line.
    if (cond) here();

    // if-else on one line.
    if (cond) here(); else there();

    if (cond) {
        here();
    } else if (!cond) {
        there();
    }

    if (err) throw SomeException;

    return 123;
}
