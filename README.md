# Area selection app
Shiny app for selecting SA2 areas

## Explanation
This is a simple R shiny app that displays a map of New Zealand overlaid by the SA2 boundaries. Users can click on boundaries to create a custom region as a combination of SA2 boundaries. Once the desired custom region has been created, this can be exported.

![example of app in use](example.png)

The exported CSV file will have SA2 codes consistent with other Stats NZ data sources, like the IDI. This means that selected areas can be used as an input to analyse custom regions.

## Files
There are three key R files:
1. `SA2_map_data_prep.R` does the data preparation, converting the publicly available shape file into a format suitable for loading into the app.
2. `SA2_higher_geographies_2025.Rds` is an R data file containin the prepared data for ease of loading into the app.
3. `app_area_selection.R` is the file to execute to run the app.

## Getting Help
Enquiries can be sent to info@sia.govt.nz
