
## Tutorial on using the GHPCC (Green High Performance Computing Cluster)

### Author: Vanessa Trijoulet

#### This material was written by Vanessa (with minor adaptations by Sam Truesdell). It was transferred from Gavin Fay's Git-Hub page


***

## Notes

This tutorial was written practicing on a Windows machine and the methods may differ on other platforms.  
You can find more information at http://wiki.umassrc.org/wiki/index.php/Main_Page


## Preliminary set up

You will need to be on the UMass network to access the server. 

## Request access to the Cluster

Fill the form at https://www.umassrc.org/hpc/index.php to request an account. You will need your PI authorization.  
By default you have a limit of __50 Gb__ on the cluster.


## Transfer the data onto the cluster
There exist different ways of transferring data into the network. I like to be able to see the files and directories and easily transfer the data from my computer to the cluster in a user-friendly mode. For this I use __WinSCP__ that you can download at https://winscp.net/eng/download.php.


## Connect to the cluster
There exist also different ways to access the cluster depending on your device (see http://wiki.umassrc.org/wiki/index.php/Connecting_to_the_Cluster). I personally use __PuTTy__.  
When opening PuTTy, use the hostname __"ghpcc06.umassrc.org"__ and the __"SSH"__ connection.


## Some general information on the cluster

When obtaining your username and password to connect to the cluster, you'll also receive general information by email. Some useful information is as follows:

You can login to the LSF submit host __ghpcc06.umassrc.org__ using an SSH client, either from your local UMass campus network or the internet.
When copying data from your desktop, and or job(s) submission (including all cp, mv, or other IO), please use the submit host __ghpcc06__.  All jobs should be run from your project space area or $HOME directory, and it is generally best to organize these jobs by the job id LSF generates.   

MGHPCC Software Using Modules:  
We are using modules to load software users may need.  To list currently available modules, run __"module avail"__  

To load a module for your jobs simply add the module load line as part of your scripts:
```
#!/bin/bash
module load R/3.4.0
```

To unload a single module:
```
module unload R
```

Most common LSF commands:

Command| Description
------ | ------------
bsub   | Submit a job to the LSF system
bkill  | Kill a job
bjobs  | View the current status of jobs
bpeek  | View the output and error files of a job
bhist  | View job history
bqueues| Display available queues

Example resource requests used with LSF and BSUB scripts:
```
BSUB -R rusage[mem=2048] # to specify the amount of memory required per slot, default is 1G
BSUB -W 4:30 # how much Wall Clock (time) this job needs in Hours:Minutes, default is 60 minutes
BSUB -q short # Which queue to use {short, long, parallel, GPU, interactive}
BSUB -n X # Where X is the number of cores to used
```


## Some useful steps

After connecting to the cluster, choose your directory using the function __"cd"__:
```
## example
cd UMass/models
```

Load the module(s) that you need:
```
## example if using R
module load R/3.4.0
## example if using TMB
module load gcc/5.1.0
```
Or load the module directly in your R script:
```
## example if using R
#!/bin/bash module load R/3.4.0
```

Submit a __batch__ job mentioning the __RAM memory__ you need, the __time__ the simulation is going to take, the __number of nodes__ needed and the __queue__:
```
## example if using a R script, requested memory of 10 Gb and time of 1 hour 30 minutes, 1 core and short queue
bsub -R rusage[mem=10000] -W 01:30 -n 1 -q short Rscript Name_script.R
```
If memory, time, node number and queue are not given, the default will be used (1 GB, 1 hour, 1 node and long queue). The queue __short__ should be used for simulations of less than 4 hours otherwise the queue __long__ should be used. There is now also a new __large__ queue. Be careful, if you underestimate time or memory, your job will be killed when reaching the specified time and memory usage.  
For more options (queues, run an interactive job, etc.) see the wiki page.

## Nice tricks!

* If you want to submit several jobs at once, use __"&"__ between the commands:
```
## example if using a R script, requested memory of 10 Gb and time of 1 hour 30 minutes
bsub -R rusage[mem=10000] -W 01:30 Rscript Name_script1.R &
bsub -R rusage[mem=10000] -W 01:30 Rscript Name_script2.R &
bsub -R rusage[mem=10000] -W 01:30 Rscript Name_script3.R
```
* If you want to pass __arguments__ to your R script (e.g. you run different scenarios at the same time without changing the code):

    1. Add the following commands at the beginning of your R script:
```
## example with numeric arguments
args = commandArgs(trailingOnly=TRUE)
arg1 <- as.numeric(args[1]) # the argument 1 is converted to a numeric
arg2 <- as.numeric(args[2]) # the argument 2 is converted to a numeric
```
    2. Add your arguments in your command line
```
## here, arg1=1 and arg2=2
bsub -R rusage[mem=10000] -W 01:30 Rscript Name_script.R 1 2
```

* If you want to submit jobs by reading a file instead, here is an example of a file (you need to set the directory first):

  ```
  #!/bin/bash

  #BSUB -W 00:15
  #BSUB -q short
  #BSUB -R rusage[mem=1000]

  module load R/3.4.0
  module load gcc/5.1.0

  Rscript script_name.R  
  ```

* You then run the file as follows:  

  ```
  bsub file_name.sh
  ```

* Kill all jobs at once:
```
bkill -u username 0
```

[Return to Wiki Home](https://github.com/thefaylab/groundfish-MSE/wiki)
