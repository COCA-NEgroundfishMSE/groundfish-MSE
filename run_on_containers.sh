#!/bin/bash

# runPre.R basically sets up a new results folder. If I am just running more replicates of the same models, I can skip doing runPre.
Rscript ./processes/runPre.R --vanilla > runPrelog.log

nice -7 Rscript ./processes/runSim.R --vanilla > runSim3A.log  & sleep 70s
nice -8 Rscript ./processes/runSim.R --vanilla > runSim4A.log  & sleep 70s
#nice -9 Rscript ./processes/runSim.R --vanilla > runSim5A.log & sleep 70s
#nice -10 Rscript ./processes/runSim.R --vanilla > runSim6A.log & sleep 70s
#nice -11 Rscript ./processes/runSim.R --vanilla > runSim7A.log  

wait
echo "run complete"

# Rscript ./processes/runPost.R --vanilla > runPostlog.log  
# echo "run post complete"
