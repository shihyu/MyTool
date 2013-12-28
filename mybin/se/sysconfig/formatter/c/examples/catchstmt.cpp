bool safe_foo(float dv) {
    try {
        foo(dv);
        return true;
    } catch (fpexcn& e) {
        return false;
    }
    // Bork?
}
