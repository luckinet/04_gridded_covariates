# ----
# title       : prepare gridded layers - global basis
# description : This is the script for preparing template files that are used throughout the modelling pipeline
# license     : https://creativecommons.org/licenses/by-sa/4.0/
# authors     : Steffen Ehrmann
# date        : 2024-03-27
# version     : 1.0.0
# status      : done
# comment     : file.edit(paste0(dir_docs, "/documentation/03_prepare_gridded_layers.md"))
# ----
# doi/url     : _INSERT
# license     : _INSERT
# resolution  : _INSERT
# years       : _INSERT
# variables   : _INSERT
# ----

message("\n---- construct basic gridded layers ----")
# source(paste0(.get_path("grid"), "preprocess_gadm.R"))

# data processing ----
#
## derive template raster ----
message(" --> pixel template")
rst_worldTemplate <- rast(res = model_info$parameters$pixel_size[1], vals = 0)

writeRaster(x = rst_worldTemplate,
            filename = path_template,
            overwrite = TRUE,
            filetype = "GTiff",
            datatype = "INT1U",
            gdal = c("COMPRESS=DEFLATE", "ZLEVEL=9", "PREDICTOR=2"))


# write output ----
#

# beep(sound = 10)
message("\n     ... done")
