# A simple but effective method for identifying incubation in real time for waterfowl with backpack transmitters

Dataset DOI: [10.5281/zenodo.22091040](https://doi.org/10.5281/zenodo.22091040)

## Description of the data and file structure

Model code and associated data files to identify incubation in real time for two species of dabbling duck, American black duck (Anas rubripes; hereafter, black ducks) and mallard (Anas platyrhynchos), using GPS and ACC data collected by backpack transmitters.

### Data files and variables

#### File: abdu_data_manuscript_demo.csv

**Description:** Raw Ornitela transmitter data (GPS and ACC) from black ducks for a two-week period (1 to 15 May 2024) to use to demonstrate the code. 

##### Variables

* device_id: serial number of transmitter
* UTC_datetime: date and timestamp of data collection
* UTC_date: date of data collection
* UTC_time: timestamp of data collection
* datatype: type of data collected (GPS or SENSORS)
* satcount: number of satelites used when acquiring GPS location
* U_bat_mV: current voltage level of the internal battery in mV
* bat_soc_pct:
* solar_I_mA: solar panel output current feeding the battery in mA
* hdop: Horizontal Dilution of PRecision (indicator of GPS fix horizontal accuracy quality
* Latitude: Geographic coordinates (latitude) of GPS position 
* Longitude: Geographic coordinates (longitude) of GPS position
* Altitude_m: Estimate altitude in meters
* speed_km_h: ground speed calculated by the GPS module (km/hr)
* direction_deg: direction of movement in degrees (heading)
* temperature_C: external ambient temperature recorded by tag's sensor in degrees C
* mag_x: geomagnetic readings (x-axis)
* mag_y: geomagnetic readings (y-axis)
* mag_z: geomagnetic readings (z-axis
* acc_x: raw acceleration values (x-axis)
* acc_y: raw acceleration values (y-axis)
* acc_z: raw acceleration values (z-axis)

#### File: currently_brood_rearing_manuscript_demo.csv

**Description:** List of birds that were thought to be currently brood rearing just prior to May 1, 2024 (the checking period used for the demo). 

##### Variables

* x: row number
* Transmitter Number: serial number of transmitter

#### File: currently_incubating_manuscript_demo.csv

**Description:** List of birds that were thought to be currently incubating just prior to May 1, 2024 (the checking period used for the demo). 

##### Variables

* x: row number
* Transmitter Number: serial number of transmitter

#### File: deploy_file_manuscript_demo.csv

**Description:** A file listing all transmitter deployments and the current status (alive vs. dead) of each bird. 

##### Variables

* x: row number
* Species: duck species that the transmitter was attached to (MALL = mallard, ABDU = American black duck)
* Status: current status of bird (alive or dead)
* Transmitter Number: serial number of transmitter

#### File: mall_data_manuscript_demo.csv

**Description:** Raw Ornitela transmitter data (GPS and ACC) from mallards for a two-week period (1 to 15 May 2024) to use to demonstrate the code. 

##### Variables

* device_id: serial number of transmitter
* UTC_datetime: date and timestamp of data collection
* UTC_date: date of data collection
* UTC_time: timestamp of data collection
* datatype: type of data collected (GPS or SENSORS)
* satcount: number of satelites used when acquiring GPS location
* U_bat_mV: current voltage level of the internal battery in mV
* bat_soc_pct:
* solar_I_mA: solar panel output current feeding the battery in mA
* hdop: Horizontal Dilution of PRecision (indicator of GPS fix horizontal accuracy quality
* Latitude: Geographic coordinates (latitude) of GPS position 
* Longitude: Geographic coordinates (longitude) of GPS position
* Altitude_m: Estimate altitude in meters
* speed_km_h: ground speed calculated by the GPS module (km/hr)
* direction_deg: direction of movement in degrees (heading)
* temperature_C: external ambient temperature recorded by tag's sensor in degrees C
* mag_x: geomagnetic readings (x-axis)
* mag_y: geomagnetic readings (y-axis)
* mag_z: geomagnetic readings (z-axis
* acc_x: raw acceleration values (x-axis)
* acc_y: raw acceleration values (y-axis)
* acc_z: raw acceleration values (z-axis)

## Code/software

All analyses were completed using R. See manuscript for details about analyses.

### R Code Files 

#### File: 00_ACCfunctions_for_realtime_incubation_manuscript.R

**Description:** Includes a function necesssary for processing the ACC data that adds an indexing column for each burst of ACC fixes. 

#### File: monitoring-incubation_ForManuscript_15Jun2026.R

**Description:** Includes all code for loading raw ACC and GPS data, calculating daily metrics (mean absolute X (ABSX) and median displacement distance (DDIST)), and generating plots for identifying incubation behaviour in real time.   

## Access information

This repository contains the data and code used in the following manuscript/publication:

Griebel, I. G., A. Butler, C. L. Waldrep, J. M. COluccy, N. R. Huck, J. N. Straub, M. D. Weegman, J. C. Stiller. (submitted). A simple but effective method for identifying incubation in real time for waterfowl with backpack transmitters. 

Data and Code DOI: [10.5281/zenodo.22091040](https://doi.org/10.5281/zenodo.22091040)

Please contact the corresponding author with questions about this data package or to seek potential collaborations using these data.
