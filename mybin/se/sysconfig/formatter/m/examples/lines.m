void boid(int x) {
    @try {
        do {
            switch (x) {
            case 1: case 2: case 3: do_something(&x); break;
            }
        } while (x > 0);
    } @catch (Bad& ex) {
		log(ex);
    } @finally {
		fnord();
	}
    while (x < 0) do_more(&x);
}
