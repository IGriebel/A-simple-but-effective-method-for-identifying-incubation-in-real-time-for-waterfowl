# A simple but effective method for identifying incubation in real time for waterfowl with backpack transmitters

Dataset DOI: [10.5281/zenodo.22091040](https://doi.org/10.5281/zenodo.22091040)

## Description of the data and file structure

Model code and associated data files to identify incubation in real time for two species of dabbling duck, American black duck (Anas rubripes; hereafter, black ducks) and mallard (Anas platyrhynchos), using GPS and ACC data collected by backpack transmitters.

### Data files and variables

#### File: abdu_data_manuscript_demo.csv

**Description:** Ornitela transmitter data (GPS and ACC) from black ducks for a two-week period (1 to 15 May 2024) to demonstrate the code. 

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
* 
* 
