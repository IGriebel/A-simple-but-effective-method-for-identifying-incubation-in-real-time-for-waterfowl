#********************************************************************************
#********************************************************************************

# Project: Monitoring Incubation 
# Description: Using GPS and ACC data to identify individuals that are incubating 
#               in real time during the breeding season.
# Date: June 2026
# Author: Anonymous

#********************************************************************************
#********************************************************************************

start_time <- Sys.time()

# load libraries
library(readxl)
library(dplyr)
library(geosphere)
library(lubridate)
library(ggpubr)
library(grid)
library(readr)

# set working directory
setwd("insert/working/directory/here")
library(tidyverse)
source("00_ACCfunctions_for_realtime_incubation_manuscript.R") 

# load GPS & ACC data (downloaded for last two to four weeks from Ornitela user interface) 
# multiple data files when more than one species
data_spp1 <- read_csv("mall_data_manuscript_demo.csv") # MALL GPS and ACC data
data_spp2 <- read_csv("abdu_data_manuscript_demo.csv") # ABDU GPS and ACC data

# or just a single data file for a single species
#data <- read_csv("Multiselect_20240403_161100.csv") 

# add species column to each data file when you have multiple species
data_spp1 <- data_spp1 %>% mutate(species="MALL")
data_spp2 <- data_spp2 %>% mutate(species="ABDU")

# combine dataframes for species 1 and species 2
data <- rbind(data_spp1, data_spp2)

rm(data_spp1, data_spp2)

# load deployment files with current status of each individual (dead vs. alive) 
deploy <- read_csv("deploy_file_manuscript_demo.csv")

# load list of birds currently incubating if you have previously monitored for 
# incubating birds this year
incubating <- read_csv("currently_incubating_manuscript_demo.csv")

# load list of birds with hatched nests if you have previously monitored for 
# incubating birds this year and  some have broods
brooding <- read_csv("currently_brood_rearing_manuscript_demo.csv")

## filter out transmitters with batteries at less than 25% because they will 
## show up weird on the graph
# creating a list of devices with batteries greater than 25%
devices_25 <- data %>% filter(bat_soc_pct > 25) 
device_list <- unique(devices_25$device_id) 

# filtering GPS and ACC data to only transmitters with batteries > 25%
data <- data %>% filter(device_id %in% device_list)

# filter data to only include alive birds
deploy_alive <- deploy %>% filter(Status == "alive")
data <- data %>% filter(device_id %in% deploy_alive$`Transmitter Number`)

# separate acc and gps data
acc <- data %>% 
        filter(datatype == "SENSORS") 

gps <- data %>% 
       filter(datatype == "GPS")

rm(data)

## ACC data processing and calculation of mean ABSX 
# convert datetime to proper format
acc$UTC_datetime <- as.POSIXct(acc$UTC_datetime, 
                               format="%Y-%m-%d %H:%M:%S", 
                               tz="UTC")

# rename timestamp column
names(acc)[2] <- "timestamp"

# get rid of unnecessary columns (this keeps device_id, timestamp, UTC_date, 
# UTC_time, acc_x, _y and _z, species)
acc <- acc[c(1:4, 20:22, 24)]

# add burst and index columns
acc <- addBurst(acc)

# average ACC data by burst
acc_sum <- acc %>% group_by(device_id, burst) %>% 
  summarise(timestamp = min(timestamp), 
            acc_x = mean(acc_x), 
            acc_y = mean(acc_y), 
            acc_z = mean(acc_z))

# add date to acc_sum
acc_sum <- acc_sum %>% 
  mutate(date=as.Date(timestamp))

# calculate daily mean absolute x
acc_sum_daily <- acc_sum %>% group_by(device_id, date) %>%
  summarise(mean_abs_x=mean(abs(acc_x)))

rm(acc)

## GPS data processing and calculation of distance between successive median 
## daily locations (DDIST; i.e., among-day movement) 
# rename timestamp column
names(gps)[2] <- "timestamp" 

# convert datetime to proper format and remove any locations with 0 lat, long
gps <- gps %>%
  mutate(timestamp = as.POSIXct(timestamp, 
                                tz = "UTC", 
                                format = "%Y-%m-%d %H:%M:%S")) %>% 
  filter(Latitude != 0) %>%
  filter(Longitude != 0) 

# calculate DDIST for each individual, day
gps_sum_daily <- gps %>% mutate(date = date(timestamp)) %>%  
  group_by(species, device_id, date) %>%
  # calculate median daily location as median lat/long for each day
  summarise(median.location.lat = median(Latitude), 
            median.location.long = median(Longitude)) %>% 
  
  # add column for median daily location of one day lag
  mutate(median.location.lat.lag = lag(median.location.lat), 
         median.location.long.lag = lag(median.location.long),
         
  # calculate DDIST using the Vincenty Ellipsoid method
  median_ddist = distVincentyEllipsoid(matrix(c(median.location.long, 
                                                median.location.lat), 
                                              ncol = 2), 
                                              matrix(c(median.location.long.lag, 
                                                       median.location.lat.lag), 
                                                     ncol = 2)))

#  select only the columns you need from the gps_sum_daily dataframe
gps_sum_daily <- gps_sum_daily %>% 
  select(species, device_id, date, median_ddist)

rm(gps)

# combine absolute x and ddist metrics 
daily_metrics <- merge(acc_sum_daily, gps_sum_daily, by = c("device_id", "date"))

rm(acc_sum_daily, gps_sum_daily)

# check min and max of absolute x and median ddist for plots and adjust axis limits below if necessary
min(daily_metrics$mean_abs_x, na.rm = TRUE)
max(daily_metrics$mean_abs_x, na.rm = TRUE)

min(daily_metrics$median_ddist, na.rm = TRUE)
max(daily_metrics$median_ddist, na.rm = TRUE)

#### create a PDF of any potentially new incubating birds ####

# filter out birds that you have already identified as currently incubating
daily_metrics.new_birds <- daily_metrics %>% filter(!device_id %in% incubating$`Transmitter Number`)

# removes birds that don't have at least one daily mean ABSX value above 270 
daily_metrics.new_birds <- daily_metrics.new_birds %>%
  group_by(device_id) %>%
  filter(any(mean_abs_x > 270))

# sort data by species and device id
daily_metrics.new_birds <- daily_metrics.new_birds %>%
  arrange(desc(species), device_id)

# define a scaling coefficient so ABSX and DDIST can be plotted on the same graph (a fixed value that makes the lines visually align well)
coeff <- 1000

# create a list of device id's
un.id <- unique(daily_metrics.new_birds$device_id)

# pdf where plots will be saved
pdf("monitoring_plots_15Jun2026_potential_new_incubating_birds.pdf", 
    paper = "a4r", width = 9, height = 6) 

# loop through each individual 
for (i in 1:length(un.id)) {
  # get data for one device
  temp <- subset(daily_metrics.new_birds, device_id==un.id[i])
  # save device id and species for individual
  id <- unique(temp$device_id)
  sp <- unique(temp$species)
  
  # plot of daily mean ABSX and median DDIST
  a <- 
    ggplot(temp, aes(x = date)) +
    # Line and points for the first variable (primary y-axis)
    geom_line(aes(y = mean_abs_x, color = "ABSX")) +
    geom_point(aes(y = mean_abs_x), color = "#0072B2", size = 3, shape = 16)+ 
    # Line and points for the second variable, SCALED to the range of the first variable
    geom_line(aes(y = (median_ddist/1000) * coeff, color = "DDIST")) +
    geom_point(aes(y = (median_ddist/1000) * coeff), color = "#009E73", size = 3, shape = 15) +
    
    # Define the primary y-axis and the secondary y-axis
    scale_y_continuous(
      name = "Daily Mean Absolute X",
      #limits = c(0, 1000),
      sec.axis = sec_axis(~ . / coeff, name = "Median DDIST (km)"),
      labels = scales::comma # Optional: format labels for readability
    ) +
    
    # set min and max of y axis
    coord_cartesian(ylim=c(0, 1000)) +
    
    # Define the x-axis for dates
    scale_x_date(
      date_labels = "%b %d", # Customize date format
      date_breaks = "1 day"     # Customize date breaks
    ) +
    
    # Customize colors and labels for the legend
    scale_color_manual(values = c("ABSX" = "#0072B2", "DDIST" = "#009E73")) +
    
    geom_hline(yintercept = 270, linetype = "dashed", color = "#0072B2") +
    
    geom_hline(yintercept = 100, linetype = "dashed", color = "#009E73") +
    
    # Add labels and theme
    labs(
      title = paste0(id, " - ", sp),
      x = "Date",
      color = "Daily Metric" # Change the legend title
    ) +
    theme_minimal() +
    theme(
      axis.title.y.left = element_text(color = "#0072B2"), # make ABSX axis title blue
      axis.title.y.right = element_text(color = "#009E73", angle = 90), # make DDIST axis title green and rotate so reads from bottom to top
      axis.ticks.x = element_line(color = "black", size = 0.5), # Show x-axis ticks
      axis.ticks.y = element_line(color = "black", size = 0.5), # Show y-axis ticks
      axis.line = element_line(), # show axis lines
      panel.grid = element_blank(), # no grid lines
      plot.title = element_text(hjust = 0.5), # centre device id and species above plot
    )
  
  # get data for one bird for the raw data ACC plot
  temp <- subset(acc_sum, device_id==un.id[i])

  # convert to long format
  temp_long <- temp %>% 
    pivot_longer(cols = starts_with("acc"), # Selects columns starting with "acc"
                                     names_to = "axis", # Name for the new column holding the original column names
                                     values_to = "acc"  # Name for the new column holding the values)
  )
  
  # make raw data ACC plot 
  b <- ggplot(data = temp_long, aes(x = timestamp, y = acc, color = axis)) + # Map 'color' to 'axis' for multiple lines
    geom_line() + # Plot the lines
    scale_x_datetime(date_labels = "%b %d", date_breaks = "1 day") + # Format x-axis to display only date
    # Add labels and a legend title
    labs(
      x = "Date",
      y = "Axis Value",
      color = "Axis"
    ) + 
    # Customize colors and labels for the legend
    scale_color_manual(values = c("acc_x" = "#0072B2", "acc_y" = "#CC79A7", "acc_z" = "#D55E00")) +
    theme_minimal() + # Use a clean theme
    theme(
      axis.ticks.x = element_line(color = "black", size = 0.5), # Show x-axis ticks
      axis.ticks.y = element_line(color = "black", size = 0.5), # Show y-axis ticks
      axis.line = element_line(), # show axis lines
      panel.grid = element_blank() # no grid lines
    )
  
  # arrange two plots on one page
  c <- ggarrange(a,b, ncol=1, nrow=2
            )
  
  # print so it will appear in PDF
  print(c)
  
}
dev.off()
  
#### create a PDF of all currently incubating birds flagged from previous runs ####

# filter out birds that you have already identified as currently incubating
daily_metrics.incubating <- daily_metrics %>% 
  filter(device_id %in% incubating$`Transmitter Number`)

# sort data by species and device id
daily_metrics.incubating <- daily_metrics.incubating %>%
  arrange(desc(species), device_id)

# create a list of device id's
un.id <- unique(daily_metrics.incubating$device_id)

# pdf where plots will be saved
pdf("monitoring_plots_15Jun2026_currently_incubating.pdf", paper = "a4r", 
    width = 9, height = 6) 

# loop through each individual 
for (i in 1:length(un.id)) {
  # get data for one device
  temp <- subset(daily_metrics.new_birds, device_id==un.id[i])
  # save device id and species for individual
  id <- unique(temp$device_id)
  sp <- unique(temp$species)
  
  # plot of daily mean ABSX and median DDIST
  a <- 
    ggplot(temp, aes(x = date)) +
    # Line and points for the first variable (primary y-axis)
    geom_line(aes(y = mean_abs_x, color = "ABSX")) +
    geom_point(aes(y = mean_abs_x), color = "#0072B2", size = 3, shape = 16)+ 
    # Line and points for the second variable, SCALED to the range of the first variable
    geom_line(aes(y = (median_ddist/1000) * coeff, color = "DDIST")) +
    geom_point(aes(y = (median_ddist/1000) * coeff), color = "#009E73", size = 3, shape = 15) +
    
    # Define the primary y-axis and the secondary y-axis
    scale_y_continuous(
      name = "Daily Mean Absolute X",
      #limits = c(0, 1000),
      sec.axis = sec_axis(~ . / coeff, name = "Median DDIST (km)"),
      labels = scales::comma # Optional: format labels for readability
    ) +
    
    # set min and max of y axis
    coord_cartesian(ylim=c(0, 1000)) +
    
    # Define the x-axis for dates
    scale_x_date(
      date_labels = "%b %d", # Customize date format
      date_breaks = "1 day"     # Customize date breaks
    ) +
    
    # Customize colors and labels for the legend
    scale_color_manual(values = c("ABSX" = "#0072B2", "DDIST" = "#009E73")) +
    
    geom_hline(yintercept = 270, linetype = "dashed", color = "#0072B2") +
    
    geom_hline(yintercept = 100, linetype = "dashed", color = "#009E73") +
    
    # Add labels and theme
    labs(
      title = paste0(id, " - ", sp),
      x = "Date",
      color = "Daily Metric" # Change the legend title
    ) +
    theme_minimal() +
    theme(
      axis.title.y.left = element_text(color = "#0072B2"), # make ABSX axis title blue
      axis.title.y.right = element_text(color = "#009E73", angle = 90), # make DDIST axis title green and rotate so reads from bottom to top
      axis.ticks.x = element_line(color = "black", size = 0.5), # Show x-axis ticks
      axis.ticks.y = element_line(color = "black", size = 0.5), # Show y-axis ticks
      axis.line = element_line(), # show axis lines
      panel.grid = element_blank(), # no grid lines
      plot.title = element_text(hjust = 0.5), # centre device id and species above plot
    )
  
  # get data for one bird for the raw data ACC plot
  temp <- subset(acc_sum, device_id==un.id[i])
  
  # convert to long format
  temp_long <- temp %>% 
    pivot_longer(cols = starts_with("acc"), # Selects columns starting with "acc"
                 names_to = "axis",      # Name for the new column holding the original column names
                 values_to = "acc"         # Name for the new column holding the values)
    )
  
  # make raw data ACC plot 
  b <- ggplot(data = temp_long, aes(x = timestamp, y = acc, color = axis)) + # Map 'color' to 'axis' for multiple lines
    geom_line() + # Plot the lines
    scale_x_datetime(date_labels = "%b %d", date_breaks = "1 day") + # Format x-axis to display only date
    # Add labels and a legend title
    labs(
      x = "Date",
      y = "Axis Value",
      color = "Axis"
    ) + 
    # Customize colors and labels for the legend
    scale_color_manual(values = c("acc_x" = "#0072B2", "acc_y" = "#CC79A7", "acc_z" = "#D55E00")) +
    theme_minimal() + # Use a clean theme
    theme(
      axis.ticks.x = element_line(color = "black", size = 0.5), # Show x-axis ticks
      axis.ticks.y = element_line(color = "black", size = 0.5), # Show y-axis ticks
      axis.line = element_line(), # show axis lines
      panel.grid = element_blank() # no grid lines
    )
  
  # arrange two plots on one page
  c <- ggarrange(a,b, ncol=1, nrow=2
  )
  
  # print so it will appear in PDF
  print(c)
  
}
dev.off()

#### create a PDF of all currently brood rearing birds ####

# filter out birds that you have already identified as currently incubating
daily_metrics.brooding <- daily_metrics %>% 
  filter(device_id %in% brooding$`Transmitter Number`)

# sort data by species and device id
daily_metrics.brooding <- daily_metrics.brooding %>%
  arrange(desc(species), device_id)

# create a list of device id's
un.id <- unique(daily_metrics.brooding$device_id)

# pdf where plots will be saved
pdf("monitoring_plots_15Jun2026_currently_brood_rearing.pdf", paper = "a4r", 
    width = 9, height = 6) 

# loop through each individual 
for (i in 1:length(un.id)) {
  # get data for one device
  temp <- subset(daily_metrics.new_birds, device_id==un.id[i])
  # save device id and species for individual
  id <- unique(temp$device_id)
  sp <- unique(temp$species)
  
  # plot of daily mean ABSX and median DDIST
  a <- 
    ggplot(temp, aes(x = date)) +
    # Line and points for the first variable (primary y-axis)
    geom_line(aes(y = mean_abs_x, color = "ABSX")) +
    geom_point(aes(y = mean_abs_x), color = "#0072B2", size = 3, shape = 16)+ 
    # Line and points for the second variable, SCALED to the range of the first variable
    geom_line(aes(y = (median_ddist/1000) * coeff, color = "DDIST")) +
    geom_point(aes(y = (median_ddist/1000) * coeff), color = "#009E73", size = 3, shape = 15) +
    
    # Define the primary y-axis and the secondary y-axis
    scale_y_continuous(
      name = "Daily Mean Absolute X",
      #limits = c(0, 1000),
      sec.axis = sec_axis(~ . / coeff, name = "Median DDIST (km)"),
      labels = scales::comma # Optional: format labels for readability
    ) +
    
    # set min and max of y axis
    coord_cartesian(ylim=c(0, 1000)) +
    
    # Define the x-axis for dates
    scale_x_date(
      date_labels = "%b %d", # Customize date format
      date_breaks = "1 day"     # Customize date breaks
    ) +
    
    # Customize colors and labels for the legend
    scale_color_manual(values = c("ABSX" = "#0072B2", "DDIST" = "#009E73")) +
    
    geom_hline(yintercept = 270, linetype = "dashed", color = "#0072B2") +
    
    geom_hline(yintercept = 100, linetype = "dashed", color = "#009E73") +
    
    # Add labels and theme
    labs(
      title = paste0(id, " - ", sp),
      x = "Date",
      color = "Daily Metric" # Change the legend title
    ) +
    theme_minimal() +
    theme(
      axis.title.y.left = element_text(color = "#0072B2"), # make ABSX axis title blue
      axis.title.y.right = element_text(color = "#009E73", angle = 90), # make DDIST axis title green and rotate so reads from bottom to top
      axis.ticks.x = element_line(color = "black", size = 0.5), # Show x-axis ticks
      axis.ticks.y = element_line(color = "black", size = 0.5), # Show y-axis ticks
      axis.line = element_line(), # show axis lines
      panel.grid = element_blank(), # no grid lines
      plot.title = element_text(hjust = 0.5), # centre device id and species above plot
    )
  
  # get data for one bird for the raw data ACC plot
  temp <- subset(acc_sum, device_id==un.id[i])
  
  # convert to long format
  temp_long <- temp %>% 
    pivot_longer(cols = starts_with("acc"), # Selects columns starting with "acc"
                 names_to = "axis",      # Name for the new column holding the original column names
                 values_to = "acc"         # Name for the new column holding the values)
    )
  
  # make raw data ACC plot 
  b <- ggplot(data = temp_long, aes(x = timestamp, y = acc, color = axis)) + # Map 'color' to 'axis' for multiple lines
    geom_line() + # Plot the lines
    scale_x_datetime(date_labels = "%b %d", date_breaks = "1 day") + # Format x-axis to display only date
    # Add labels and a legend title
    labs(
      x = "Date",
      y = "Axis Value",
      color = "Axis"
    ) + 
    # Customize colors and labels for the legend
    scale_color_manual(values = c("acc_x" = "#0072B2", "acc_y" = "#CC79A7", "acc_z" = "#D55E00")) +
    theme_minimal() + # Use a clean theme
    theme(
      axis.ticks.x = element_line(color = "black", size = 0.5), # Show x-axis ticks
      axis.ticks.y = element_line(color = "black", size = 0.5), # Show y-axis ticks
      axis.line = element_line(), # show axis lines
      panel.grid = element_blank() # no grid lines
    )
  
  # arrange two plots on one page
  c <- ggarrange(a,b, ncol=1, nrow=2
  )
  
  # print so it will appear in PDF
  print(c)
  
}
dev.off()

# check total run time
end_time <- Sys.time()
run_time <- end_time - start_time
print(run_time)
