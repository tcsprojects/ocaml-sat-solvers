/****************************************************************************
Copyright (c) 2006 - 2007, Armin Biere, Johannes Kepler University.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
****************************************************************************/

#ifndef picosat_h_INCLUDED
#define picosat_h_INCLUDED

/*------------------------------------------------------------------------*/

#include <stdlib.h>
#include <stdio.h>

/*------------------------------------------------------------------------*/
/* These are the return values for 'picosat_sat' as for instance
 * standardized by the output format of the SAT competition.
 */
#define PICOSAT_UNKNOWN		0
#define PICOSAT_SATISFIABLE	10
#define PICOSAT_UNSATISFIABLE	20

/*------------------------------------------------------------------------*/

const char *picosat_id (void);
const char *picosat_version (void);
const char *picosat_config (void);
const char *picosat_copyright (void);

/*------------------------------------------------------------------------*/

extern "C" void picosat_init (void);		/* constructor */
extern "C" void picosat_reset (void);		/* destructor */

/*------------------------------------------------------------------------*/
/* The following five functions are essentially parameters to 'init', and
 * thus should be called right after 'picosat_init' before doing anything
 * else.  You should not call any of them after adding a literal.
 */

/* Set output file, default is 'stdout'.
 */
extern "C" void picosat_set_output (FILE *);

/* The function 'picosat_set_incremental_rup_file' produces
 * a proof trace in RUP format on the fly.  The resulting RUP file may
 * contain learned clauses that are not actual in the clausal core.
 */

/* Increase verbosity and report progress on the output file.  Verbose
 * messages are prefixed with the comment letter 'c'.
 */
extern "C" void picosat_enable_verbosity (void);

/* Set a seed for the random number generator.  The random number generator
 * is currently just used for generating random decisions.  In our
 * experiments having random decisions did not really help on industrial
 * examples, but was rather helpful to randomize the solver in order to
 * do proper benchmarking of different internal parameter sets.
 */
extern "C" void picosat_set_seed (unsigned random_number_generator_seed);

/* If you ever want to extract cores or proof traces with the current
 * instance of PicoSAT initialized with 'picosat_init', then make sure to
 * call 'picosat_enable_trace_generation' right after 'picosat_init'.   This
 * is not necessary if you only use 'picosat_usedlit', or
 * 'picosat_set_incremental_rup_file'.
 *
 * NOTE, trace generation code is not necessarily included, e.g. if you
 * configure picosat with full optimzation as './configure -O' or with
 * './configure --no-trace'.  This speeds up the solver slightly.  Then you
 * you do not get any results by trying to generate traces.
 */
extern "C" void picosat_enable_trace_generation (void);

/* You can dump proof traces in RUP format incrementally even without
 * keeping the proof trace in memory.  The advantage is a reduction of
 * memory usage, but the dumped clauses do not necessarily belong to the
 * clausal core.  Beside the file the additional parameters denotes the
 * maximal number of variables and the number of original clauses.
 */
extern "C" void picosat_set_incremental_rup_file (FILE * file, int m, int n);

/*------------------------------------------------------------------------*/
/* If you know a good estimate on how many variables you are going to use
 * then calling this function before adding literals will result in less
 * resizing of the variable table.  But this is just a minor optimization.
 */
extern "C" void picosat_adjust (int max_idx);

/*------------------------------------------------------------------------*/
/* Statistics.
 */
extern "C" unsigned picosat_variables (void);			/* p cnf <m> n */
extern "C" unsigned picosat_added_original_clauses (void);		/* p cnf m <n> */
extern "C" size_t picosat_max_bytes_allocated (void);
extern "C" double picosat_time_stamp (void);			/* ... in process */
extern "C" double picosat_seconds (void);				/* ... in library */
extern "C" void picosat_stats (void);				/* > output file */

/*------------------------------------------------------------------------*/
/* Add a literal of the next clause.  A zero terminates the clause.  The
 * solver is incremental.  Adding a new literal will reset the previous
 * assignment.
 */
extern "C" void picosat_add (int lit);

/* Print the CNF to the given file in DIMACS format.
 */
extern "C" void picosat_print (FILE *);

/* You can add arbitrary many assertions before the next 'picosat_sat'.
 * An assumption is only valid for the next 'picosat_sat' and will be taken
 * back afterwards.  Adding a new assumption will reset the previous
 * assignment.
 */
extern "C" void picosat_assume (int lit);

/*------------------------------------------------------------------------*/
/* Call the main SAT routine.  A negative decision limits sets no limit on
 * the number of decisions.  The return values are as above, e.g.
 * 'PICOSAT_UNSATISFIABLE', 'PICOSAT_SATISFIABLE', or 'PICOSAT_UNKNOWN'.
 */
extern "C" int picosat_sat (int decision_limit);

/* After 'picosat_sat' was called and returned 'PICOSAT_SATISFIABLE', then
 * the satisfying assignment can be obtained by 'dereferencing' literals.
 * The value of the literal is return as '1' for 'true',  '-1' for 'false'
 * and '0' for an unknown value.
 */
extern "C" int picosat_deref (int lit);

/* A cheap way of determining an over-approximation of a variable core is to
 * mark those variable that were resolved in deriving learned clauses.  This
 * can be done without keeping the proof trace in memory and thus does
 * not require to call 'picosat_enable_trace_generation' after
 * 'picosat_init'.
 */
extern "C" int picosat_usedlit (int lit);

/*------------------------------------------------------------------------*/
/* The following five functions internally extract the variable and clausal
 * core and thus require trace generation to be enabled with
 * 'picosat_enable_trace_generation' right after calling 'picosat_init'.
 *
 * TODO: most likely none of them works for failed assumptions.  Therefore
 * trace generation currently makes only sense for non incremental usage.
 */

/* This function gives access to the variable core, which is made up of the
 * variables that were resolved in deriving the empty clauses.
 */
extern "C" int picosat_corelit (int lit);

/* Write the clauses that were used in deriving the empty clause to a file
 * in DIMACS format.
 */
extern "C" void picosat_write_clausal_core (FILE * core_file);

/* Write a proof trace in TraceCheck format to a file.
 */
extern "C" void picosat_write_compact_trace (FILE * trace_file);
extern "C" void picosat_write_extended_trace (FILE * trace_file);

/* Write a RUP trace to a file.  This trace file contains only the learned
 * core clauses while this is not necessarily the case for the RUP file
 * obtained with 'picosat_set_incremental_rup_file'.
 */
extern "C" void picosat_write_rup_trace (FILE * trace_file);

/*------------------------------------------------------------------------*/
#endif
