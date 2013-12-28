private void boid(int x) {
    try {
        do {
            switch (x) {
            case 1: case 2: case 3: x = do_something(x); break;
            }
        } while (x > 0);
    } catch (Bad ex) {
    }
    while (x < 0) x = do_more(x);
}
