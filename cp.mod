/*********************************************
 * OPL 20.1.0.0 Data
 * Author: Mouhamed
 * Creation Date:  gen 2021 at 19:16:22
 *********************************************/

using CP;


tuple paramsT{
  int nbJobs;
  int nbMchs;
};
paramsT Params = ...; 
int nbJobs = Params.nbJobs;
int nbMchs = Params.nbMchs;
int jCapacity = ...;

range Jobs = 1..nbJobs;
range Mchs = 1..nbMchs; 

tuple Operation {
  int id;    // Operation id
  int jobId; // Job id
  int pos;   // Position in job
};

tuple Mode {
  int opId; // Operation id
  int mch;  // Machine
  int pt;   // Processing time
};

{Operation} Ops   = ...;
{Mode}      Modes = ...;

// Position of last operation of job j
int jlast[j in Jobs] = max(o in Ops: o.jobId==j) o.pos;

dvar interval ops [Ops] ; 
dvar interval modes[md in Modes] optional size md.pt;
dvar sequence mchs[m in Mchs] in all(md in Modes: md.mch == m) modes[md];

execute {
      cp.param.FailLimit = 10000;
}

cumulFunction nbJobsexec = 
  sum (md in Modes) pulse(modes[md], 1);


minimize max(j in Jobs, o in Ops: o.pos==jlast[j]) endOf(ops[o]);
subject to {
  nbJobs <= jCapacity;
  forall (j in Jobs, o1 in Ops, o2 in Ops: o1.jobId==j && o2.jobId==j && o2.pos==1+o1.pos)
    endBeforeStart(ops[o1],ops[o2]);
  forall (o in Ops)
    alternative(ops[o], all(md in Modes: md.opId==o.id) modes[md]);
  forall (m in Mchs)
    noOverlap(mchs[m]);
}

execute {
  for (var m in Modes) {
    if (modes[m].present)
      writeln("Operation " + m.opId + " on machine " + m.mch + " starting at " + modes[m].start);
  }
  writeln(nbJobsexec)
}

tuple solutionT{
  int operation;
  int machine;
  int start;
};
{solutionT} solution = {<m.opId, m.mch, startOf(modes[m])> | m in Modes : startOf(modes[m]) != 0};
