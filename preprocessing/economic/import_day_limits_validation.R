#importing trip limits data and index fishing year and day of fishing year 
#includes pre-processing code to add a dl_primary to the targetting dataset 

day_limits = read.dta13("data/data_raw/econ/trip_limits_forsim.dta")

spstock2s<-c("americanlobster","americanplaiceflounder","codGB","codGOM","haddockGB","haddockGOM","monkfish", "other","pollock","redsilveroffshorehake","redfish","seascallop","skates","spinydogfish","squidmackerelbutterfishherring","summerflounder","whitehake","winterflounderGB","winterflounderGOM","witchflounder","yellowtailflounderCCGOM", "yellowtailflounderGB","yellowtailflounderSNEMA")

daylimits <-paste0("dl_",spstock2s)
#https://stackoverflow.com/questions/37376398/how-to-create-an-empty-datatable-with-columns-names-and-then-append-datatables-t
dl <- setNames(data.table(matrix(nrow = 0, ncol = length(daylimits))), c(daylimits))

#dl = data.table ()
#dl [,(daylimits):=NA]

fishing_yr <- function(dates, start_month=5) {
  # Convert dates into POSIXlt
  dates.posix = as.POSIXlt(dates)
  # Year offset
  offset = ifelse(dates.posix$mon >= start_month - 1, 0, 1)
  # fishing year
  f.year = dates.posix$year + 1900 - offset
  # Return the fishing year
  f.year
}

day_limits$gffishingyear = fishing_yr(day_limits$date)

day_limits = day_limits %>%
  group_by(gffishingyear)%>%
  mutate(doffy = ifelse(gffishingyear==2003, 306:366, 1:n()))
 
day_limits = day_limits[, !(colnames(day_limits) %in% c("date"))]
mer = names(day_limits [1:13])
day_limits = merge(day_limits, dl, by=mer, all=T)

# creating a dl_primary variable 
primary = gather (day_limits, key = "spstock2", value="dl_primary", -c("gffishingyear", "doffy"))
primary$spstock2 = gsub("dl_", "", primary$spstock2)

day_limits = merge(primary, day_limits)

day_limits = as.data.table(day_limits)
