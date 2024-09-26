# ----
# title       : prepare gridded layers
# description : This is the main script for preparing the gridded layers for modelling LUTS
# license     : https://creativecommons.org/licenses/by-sa/4.0/
# authors     : Steffen Ehrmann, Ruben Remelgado, Luise
# date        : 2024-03-27
# version     : 0.3.0
# status      : working
# comment     : file.edit(paste0(dir_docs, "/documentation/mdl_prepare_gridded_layers.md"))
# ----

# set module-specific paths ----
#
path_onto <- paste0(.get_path("onto", "_data"), "lucki_onto.rds")
path_gadm <- paste0(.get_path("onto", "_data"), "gadm36_levels.gpkg") # paste0(.get_path("onto", "_data"), "gadm_410-levels.gpkg")
path_template <- paste0(.get_path("grid", "_data"), "template_", model_info$tag, ".tif")
path_modelregion <- paste0(.get_path("grid", "_data"), "modelregion_", model_info$tag, ".tif")
path_cellSize <- paste0(.get_path("grid", "_data"), "cellSize_", model_info$tag, ".tif")

# start database and set some meta information ----
#
adb_init(root = .get_path("grid", "_data"), version = model_info$tag,
         staged = FALSE,
         licence = "https://creativecommons.org/licenses/by-sa/4.0/",
         ontology = list("use" = path_onto, "cover" = path_onto),
         author = list(cre = model_info$authors$cre,
                       aut = model_info$authors$aut$grid,
                       ctb = model_info$authors$ctb$grid))

# sub-modules that pre-process data ----
#
# (run these only once, when the respective data need to be processed)
source(paste0(.get_path("grid"), "01_global_basis.R"))


# sub-modules that build model-run specific gridded layers ----
#
# (run these for every separate model-run)
source(paste0(.get_path("grid"), "01_model_basis.R"))

.run_submodules(model = model_info, module = "grid")

