
# Code to compile TMB code before running the operating model. Doing this
# because it's probably a little better to compile once and then access the
# executable only -- certainly for when this is running on the HPCC as an
# array so you aren't trying to compile the same cpp file with multiple
# programs at once. Could include in the assessment R file, but if it's
# separate here it is easier for the HPCC to deal with.


# Get the run info so the functions work appropriately whether they are
# on Windows or Linux and whether this is an HPCC run or not.
source('processes/get_runinfo.R')

# Ensure that TMB will use the Rtools compiler (only windows ... and 
# not necessary on all machines)
if(platform != 'Linux'){
  path_current <- Sys.getenv('PATH')
  path_new <- paste0('c:\\Rtools\\bin;c:\\Rtools\\mingw_32\\bin;',
                     path_current)
  Sys.setenv(PATH=path_new)
}



# Remove all files (as long as not running runSetup later within the plotting
# function to gather information for diagnostic plots). Ran through the 
# available environments before and after the simulation is run and found
# one variable that was only available after (active_idx) ... used that to
# determine whether or not to delete all the files in the results directory.

# Create new results directory tagged with date/time
# get and format the system time
time <- Sys.time()
timeString <- format(x = time, 
                     format = "%Y-%m-%d-%H-%M-%S")
# define a directory name
ResultDirectory <- paste('results', timeString, sep='_')
dir.create(ResultDirectory, showWarnings = FALSE, recursive=TRUE)

# Reults folders for economic models. Create them if necessary
dir.create(file.path(ResultDirectory,"econ", "raw"), showWarnings = FALSE, recursive=TRUE)
dir.create(file.path(ResultDirectory,"econ", "sim"), showWarnings = FALSE, recursive=TRUE)
dir.create(file.path(ResultDirectory,"econ", "fig"), showWarnings = FALSE, recursive=TRUE)

dir.create(file.path(ResultDirectory,"sim"), showWarnings = FALSE, recursive=TRUE)
dir.create(file.path(ResultDirectory,"fig"), showWarnings = FALSE, recursive=TRUE)

# load the required libraries
source('processes/loadLibs.R')

# compile the c++ file and make available to R
TMB::compile("assessment/caa.cpp")


# need to get the mprocfile from set_om_parameters_global.R
source('modelParameters/set_om_parameters_global.R')

# Copy set_om_parameters_global.R and mprocfile into the results folder

file.copy(file.path("modelParameters",mprocfile), file.path(ResultDirectory,"fig",mprocfile))
file.copy(file.path("modelParameters","set_om_parameters_global.R"), file.path(ResultDirectory,"set_om_parameters_global.R"))

