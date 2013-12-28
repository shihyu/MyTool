char const* state_string(State c) {
   switch (c) {
   case INITIALIZING:
	return "INITIALIZING";
   case RUNNING:
        return "RUNNING";
   case QUIESCING:
        return "QUIESCING";
   default:
        return "UNKNOWN_STATE";
}
}
     
