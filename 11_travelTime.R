# ----
# title       : prepare gridded layers - travel time to markets
# description : This is the script for building layers on the travel time to (major) markets
# license     : https://creativecommons.org/licenses/by-sa/4.0/
# authors     : Steffen Ehrmann, Carsten Meyer
# date        : 2024-12-14
# version     : 0.0.1
# status      : find data, update, inventarize, validate, normalize, done
# comment     : file.edit(paste0(dir_docs, "/documentation/03_prepare_gridded_layers.md"))
# ----
# doi/url     : _INSERT
# license     : _INSERT
# resolution  : _INSERT
# years       : _INSERT
# variables   : _INSERT
# ----

# https://www.nature.com/articles/nature25181 -> method
# https://www.nature.com/articles/s41591-020-1059-1 -> one application for healthcare
# https://www.nature.com/articles/s41597-019-0265-5 -> several different maps


# https://forobs.jrc.ec.europa.eu/gam/sources
# https://gisgeography.com/best-free-gis-data-sources-raster-vector/
# https://blog.geofabrik.de/index.php/2024/11/13/historic-openstreetmap-data/
# https://webhelp.esri.com/arcgisdesktop/9.2/index.cfm?TopicName=Cost_Distance_algorithm
# Populated places https://human-settlement.emergency.copernicus.eu/, https://human-settlement.emergency.copernicus.eu/download.php
# Additional cities
# Road network https://worldroadstatistics.org/data/, https://gisgeography.com/openstreetmap-download-osm-data/, https://data.europa.eu/data/datasets/major-road-network?locale=en, https://www.globio.info/download-grip-dataset, https://www.nature.com/articles/s41586-024-07303-5, https://www.sciencedirect.com/science/article/pii/S0034425724004061, https://www.mdpi.com/2072-4292/14/15/3625
# Railway network https://wiki.openstreetmap.org/wiki/OpenRailwayMap, https://www.openrailwaymap.org/
# Navigable rivers
# Major waterbodies https://global-surface-water.appspot.com/
# Shipping lanes
# National borders
# Land cover esa cci lc (cf Ruben)
# Urban areas
# Elevation https://medium.com/nerd-for-tech/an-ensemble-digital-terrain-model-of-the-world-at-30-m-spatial-resolution-edtm30-b4fcff38164c
# Slope https://medium.com/nerd-for-tech/an-ensemble-digital-terrain-model-of-the-world-at-30-m-spatial-resolution-edtm30-b4fcff38164c


# does it make sense to include GDP? https://www.researchsquare.com/article/rs-4321741/v1

# also see https://www.nature.com/articles/s43856-022-00179-4?fromPaywallRec=false, https://github.com/fleurhierink/Population_Access











thisDataset <- "travelTime"
message("\n---- ", thisDataset, " ----")

thisDir <- paste0(.get_path("grid", "_data"), thisDataset, "/")

message(" --> handling metadata")
regDataseries(name = thisDataset,
              description = _INSERT,
              homepage = _INSERT,
              version = _INSERT,
              licence_link = _INSERT,
              reference = read.bib(paste0(thisDir, "_INSERT.bib")))

message(" --> handling data")
theseFiles <- list.files(path = thisDir, pattern = "_30as.tif")

for(i in seq_along(theseFiles)){

        thisFile <- paste0(thisDir, theseFiles[i])

        # crop to model extent
        thisDir_mdl <- str_replace(thisFile, ".tif", paste0("_", model_info$tag, ".tif"))
        if(!testFileExists(x = thisDir_mdl, access = "rw")){

                message(" ---- layer ", theseFiles[i], " ----")
                crop(x = rast(thisFile), y = rast(x = path_modelregion),
                     snap = "out",
                     filename = thisDir_mdl,
                     overwrite = TRUE,
                     filetype = "GTiff",
                     datatype = datatype(rast(thisFile)),
                     gdal = c("COMPRESS=DEFLATE", "ZLEVEL=9", "PREDICTOR=2"))

        }

}

beep(sound = 10)
message("\n     ... done")
