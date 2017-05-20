#include <caml/mlvalues.h>
#include <caml/memory.h>

#include <sys/types.h>
#include <dirent.h>
#include <iostream>
#include <fstream>
#include <streambuf>



using namespace std;


extern "C" void* SAT_InitManager (void);
extern "C" void SAT_SetTimeLimit (void* mng, float time);
extern "C" void SAT_ReleaseManager (void* mng);
extern "C" void SAT_Reset (void* mng);
extern "C" void SAT_DeleteClauseGroup (void* mng, int gid);
extern "C" int SAT_Solve (void* mng);
extern "C" int SAT_AllocClauseGroupID (void* mng);
extern "C" int SAT_GetVarAsgnment (void* mng, int v_idx);
extern "C" int SAT_AddVariable (void* mng);
extern "C" void SAT_AddClause (void* mng, int * clause_lits, int num_lits, int gid);


extern "C" value zchaff_InitManager(void) {
	void* manager = SAT_InitManager();
	return (value) manager;
}

extern "C" value zchaff_SetTimeLimit(value mng, value runtime) {
	SAT_SetTimeLimit((void*)mng, Double_val(runtime));
	return Val_unit;
}

extern "C" value zchaff_ReleaseManager(value mng) {
	SAT_ReleaseManager((void*) mng);
	return Val_unit;
}

extern "C" value zchaff_Reset(value mng) {
	SAT_Reset((void*) mng);
	return Val_unit;
}

extern "C" value zchaff_DeleteClauseGroup(value mng, value gid) {
	SAT_DeleteClauseGroup((void*) mng, Int_val(gid));
	return Val_unit;
}

extern "C" value zchaff_Solve(value mng) {
	cout.setstate(std::ios_base::badbit);
    int retval = SAT_Solve((void*) mng);
    return Val_int(retval);
}

extern "C" value zchaff_AllocClauseGroupID(value mng) {
    int retval = SAT_AllocClauseGroupID((void*) mng);
    return Val_int(retval);
}

extern "C" value zchaff_GetVarAsgnment(value mng, value v_idx) {
    int retval = SAT_GetVarAsgnment((void*) mng, Int_val(v_idx));
    return Val_int(retval);
}

extern "C" value zchaff_AddVariable(value mng) {
    int retval = SAT_AddVariable((void*) mng);
    return Val_int(retval);
}


extern "C" value zchaff_AddClause(value mng, value clause_lits, value gid) {
  int size = Wosize_val(clause_lits);
  int * arr = new int[size];
  for (int i = 0; i < size; i++) {
    int temp = Int_val( Field(clause_lits, i) );
    if (temp > 0)
      arr[i] = temp << 1;
    else
      arr[i] = temp * (-2) + 1;
  }
  SAT_AddClause((void*) mng, arr, size, Int_val(gid) );
  return Val_unit;
}



