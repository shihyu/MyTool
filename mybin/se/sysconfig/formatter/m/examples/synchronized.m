void xfn(id obj) {
	@synchronized(obj) {
		do_something();
	}
}
