



# Identify which folder to store the results in. Assuming runPre was just
# executed (it should have been!), identify the results folder that was
# most recently created.
resNames <- grep(pattern = 'results_', # look for files containing this
                 x = list.files(full.names=TRUE),    # all files in the working directory
                 value = TRUE)        # pring out the actual folder names

ResultDirectory <- tail(sort(resNames), 1) # ID the most recent folder

