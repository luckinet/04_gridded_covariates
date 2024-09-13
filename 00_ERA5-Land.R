# ----
# title       : prepare gridded layers - ERA5-Land climate
# description : This script downloads, aggregates (temporally) and interpolates (spatially) ERA5-Land data into several raster files.
# license     : https://creativecommons.org/licenses/by-sa/4.0/
# authors     : Erik Kusch
# date        : 2024-10-13
# version     : 1.0.0
# status      : done
# comment     : Requires the presence of a "API-Credentials.R" file, whcih holds ECMWF CDS API credentials
# ----
# doi/url     : reanalysis-era5-land data (DOI:10.24381/cds.e2161bac) obtained with KrigR (DOI:10.1088/1748-9326/ac48b3)
# license     : https://cds.climate.copernicus.eu/api/v2/terms/static/licence-to-use-copernicus-products.pdf
# resolution  : 9x9km native before interpolation; 1x1km after interpolation
# years       : 2000-2022
# variables   : 2m_temperature, volumetric_soil_water_layer_1, volumetric_soil_water_layer_2, volumetric_soil_water_layer_3, volumetric_soil_water_layer_4
# ----

thisDataset <- "ERA5-Land Climate"
message("\n---- ", thisDataset, " ----")

# thisDir <- .get_path(module = "grid", data = thisDataset)

message(" --> handling metadata")
# regDataseries(name = thisDataset,
# 							description = "ERA5-Land is a reanalysis dataset providing a consistent view of the evolution of land variables over several decades at an enhanced resolution compared to ERA5. ERA5-Land has been produced by replaying the land component of the ECMWF ERA5 climate reanalysis. Reanalysis combines model data with observations from across the world into a globally complete and consistent dataset using the laws of physics. Reanalysis produces data that goes several decades back in time, providing an accurate description of the climate of the past.",
# 							homepage = "https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-land?tab=overview",
# 							version = _INSERT,
# 							licence_link = "https://cds.climate.copernicus.eu/api/v2/terms/static/licence-to-use-copernicus-products.pdf",
# 							reference = read.bib(paste0(thisDir, "_INSERT.bib")))

message(" --> handling data")

# PACKAGES =====================================================================
## KrigR ---------------4--------------------------------------------------------
if("KrigR" %in% rownames(installed.packages()) == FALSE){ # KrigR check
	Sys.setenv(R_REMOTES_NO_ERRORS_FROM_WARNINGS="true")
	devtools::install_github("https://github.com/ErikKusch/KrigR", force = TRUE)
}
if(packageVersion("KrigR") < "0.3.5"){
	devtools::install_github("https://github.com/ErikKusch/KrigR", ref = "Development")
}
library(KrigR)

## CRAN ------------------------------------------------------------------------
install.load.package <- function(x) {
	if (!require(x, character.only = TRUE))
		install.packages(x, repos='http://cran.us.r-project.org')
	require(x, character.only = TRUE)
}
package_vec <- c(
	"rnaturalearth", # for shapefiles
	"terra", # for terra functionality
	"pbapply", # for lapply with progress bar
	"parallel" # for parallel code execution
)
sapply(package_vec, install.load.package)

# API CREDENTIALS ==============================================================
try(source("API-Credentials.R"))
# CDS API (needed for ERA5-Land downloads)
if(!exists("API_Key") | !exists("API_User")){ # CS API check: if CDS API credentials have not been specified elsewhere
	API_User <- readline(prompt = "Please enter your Climate Data Store API user number and hit ENTER.")
	API_Key <- readline(prompt = "Please enter your Climate Data Store API key number and hit ENTER.")
} # end of CDS API check

# DIRECTORIES ==================================================================
Dir.Base <- getwd()
Dir.Raw <- file.path(Dir.Base, "Data_Raw")
Dir.Summarised <- file.path(Dir.Base, "Data_Summarised")
Dir.Krig <- file.path(Dir.Base, "Data_Krig")
Dir.Covariates <- file.path(Dir.Base, "Covariates")

CreateDir <- sapply(sapply(ls(pattern = "Dir"), get), 
										function(x) if(!dir.exists(x)) dir.create(x))
rm(list = c("CreateDir"))


# REGIONS OF INTEREST ==========================================================
DK_sf <- ne_countries(country = "Denmark", scale = 10)
BR_sf <- ne_countries(country = "Brazil", scale = 10)

Regions_ls <- lapply(ls(pattern = "_sf"), get)
names(Regions_ls) <- unlist(lapply(Regions_ls, FUN = function(x){x$name}))

# DATA OBTAINING ===============================================================
## Variables -------------------------------------------------------------------
Vars <- c("2m_temperature", 
					"volumetric_soil_water_layer_1", # 0-7cm
					"volumetric_soil_water_layer_2", # 7-28cm
					"volumetric_soil_water_layer_3", # 28-100 cm
					"volumetric_soil_water_layer_4" # 100-Inf cm
					# ,
					# "surface_net_solar_radiation",
					# "surface_solar_radiation_downwards",
					# "total_evaporation",
					# "total_precipitation"
)

Data_ls <- lapply(Regions_ls, FUN = function(RegionIter){
	RegionName <- RegionIter$name
	message("############### ", toupper(RegionName), " ###############")
	
	## Download ------------------------------------------------------------------
	message("-------- DOWNLOADING RAW DATA")
	Data_ls <- lapply(Vars, FUN = function(Var_iter){
		message(Var_iter)
		CDownloadS(
			Variable = Var_iter,
			DataSet = "reanalysis-era5-land",
			Type = NA,
			CumulVar = startsWith(Var_iter, "total_"),
			# time-window, default set to range of dataset-type
			DateStart = "2000-01-01 00:00",
			DateStop = "2022-12-31 23:00",
			TZone = "CET",
			# temporal aggregation
			TResolution = "hour",
			TStep = 1,
			# spatial
			Extent = RegionIter,
			# file storing
			Dir = Dir.Raw,
			FileName = paste(RegionName, Var_iter, sep = "_"),
			# API credentials
			API_User = API_User,
			API_Key = API_Key
		)
		closeAllConnections()
	})
	names(Data_ls) <- Vars
	
	## Summarising ---------------------------------------------------------------
	message("-------- SUMMARISING RAW DATA")
	MonthlySummaries <- lapply(Vars, FUN = function(Var_iter){
		message(Var_iter)
		if(sum(
			file.exists(
				file.path(Dir.Summarised, paste0(paste(RegionName, Var_iter, sep = "_"), 
																				 "_", c("Mean", "Max", "Min"), ".nc"))
				)
			) != 3){
			Raw_iter <- terra::rast(file.path(Dir.Raw, paste0(paste(RegionName, Var_iter, sep = "_"), ".nc")))
			time(Raw_iter) <- as.POSIXct(terra::time(Raw_iter), tz = "CET")
			
			# Identify Mean for days
			Mean_days <- terra::tapp(Raw_iter, index = as.numeric(factor(substr(terra::time(Raw_iter), 1, 10))),
															 fun = mean, cores = parallel::detectCores())
			Max_days <- terra::tapp(Raw_iter, index = as.numeric(factor(substr(terra::time(Raw_iter), 1, 10))),
															fun = max, cores = parallel::detectCores())
			Min_days <- terra::tapp(Raw_iter, index = as.numeric(factor(substr(terra::time(Raw_iter), 1, 10))),
															fun = min, cores = parallel::detectCores())
			terra::time(Mean_days) <- terra::time(Max_days) <- terra::time(Min_days) <-
				as.POSIXct(unique(substr(terra::time(Raw_iter), 1, 10)), tz = "CET")
			Mean_iter <- terra::tapp(Mean_days, index = as.numeric(factor(substr(terra::time(Mean_days), 1, 7))),
															 fun = mean, cores = parallel::detectCores())
			# Identify which day per month holds the minimum and maximum mean
			WhichMax_days <- terra::tapp(Mean_days, index = as.numeric(factor(substr(terra::time(Mean_days), 1, 7))),
																	 fun = terra::which.max)
			WhichMin_days <- terra::tapp(Mean_days, index = as.numeric(factor(substr(terra::time(Mean_days), 1, 7))),
																	 fun = terra::which.min)
			# fixing times
			terra::time(Mean_iter) <- terra::time(WhichMax_days) <- terra::time(WhichMin_days) <-
				as.POSIXct(paste0(unique(substr(terra::time(Mean_days), 1, 7)), "-01"), tz = "CET")
			
			# Extracting minimum and maximum hourly values according to lowest and highest mean per month
			Extremes_ls <- pblapply(terra::time(Mean_iter), FUN = function(Month_iter){
				## Minimum
				ToSubset <- terra::as.data.frame(
					Min_days[[which(as.POSIXct(paste0(substr(terra::time(Min_days), 1, 7), "-01"), tz = "CET") == Month_iter)]],
					na.rm = FALSE)
				
				SubsetWith <- terra::as.data.frame(
					WhichMin_days[[which(terra::time(WhichMin_days) == Month_iter)]],
					na.rm = FALSE)
				
				ExtractedVals <- sapply(1:nrow(SubsetWith), FUN = function(Row){
					Col <- SubsetWith[Row, 1]
					ifelse(is.na(Col), NA, ToSubset[Row, Col])
				})
				
				MinHour <- rast(WhichMin_days[[which(terra::time(WhichMin_days) == Month_iter)]])
				values(MinHour) <- ExtractedVals
				
				## Minimum
				ToSubset <- terra::as.data.frame(
					Max_days[[which(as.POSIXct(paste0(substr(terra::time(Max_days), 1, 7), "-01"), tz = "CET") == Month_iter)]],
					na.rm = FALSE)
				
				SubsetWith <- terra::as.data.frame(
					WhichMax_days[[which(terra::time(WhichMax_days) == Month_iter)]],
					na.rm = FALSE)
				
				ExtractedVals <- sapply(1:nrow(SubsetWith), FUN = function(Row){
					Col <- SubsetWith[Row, 1]
					ifelse(is.na(Col), NA, ToSubset[Row, Col])
				})
				
				MaxHour <- rast(WhichMax_days[[which(terra::time(WhichMax_days) == Month_iter)]])
				values(MaxHour) <- ExtractedVals
				
				## Reporting Back
				list(Max = MaxHour,
						 Min = MinHour)
			})
			Max_iter <- do.call(c, lapply(Extremes_ls, "[[", 1))
			Min_iter <- do.call(c, lapply(Extremes_ls, "[[", 2))
			time(Max_iter) <- time(Min_iter) <- time(Mean_iter)
			
			# Save files
			Save_ls <- list(Mean = Mean_iter,
											Max = Max_iter,
											Min = Min_iter)
			
			sapply(names(Save_ls), FUN = function(x){
				writeCDF(Save_ls[[x]], filename = file.path(Dir.Summarised, paste0(paste(RegionName, Var_iter, sep = "_"), "_", x, ".nc")))
			})
			
		}
		
		## Return Summaries
		Ret_ls <- lapply(c("Mean", "Max", "Min"), FUN = function(x){
			Load_rast <- rast(file.path(Dir.Summarised, paste0(paste(RegionName, Var_iter, sep = "_"), "_", x, ".nc")))
			time(Load_rast) <- as.POSIXct(time(Load_rast), tz = "CET")
			Load_rast
		})
		Ret_ls
	})
	names(MonthlySummaries) <- c(Vars)
	
	## Interpolation -------------------------------------------------------------
	message("-------- INTERPOLATING SUMMARISED DATA")
	### Covariates ++++++++++++++++++++++++++
	if(file.exists(file.path(Dir.Covariates, paste(RegionName, "Covariates_Train.nc", sep = "_"))) &
		 file.exists(file.path(Dir.Covariates, paste(RegionName, "Covariates_Target.nc", sep ="_")))
		 ){
		Covariates_ls <- list(
			Training = rast(file.path(Dir.Covariates, paste(RegionName, "Covariates_Train.nc", sep = "_"))),
			Target = rast(file.path(Dir.Covariates, paste(RegionName, "Covariates_Target.nc", sep = "_")))
		)
		names(Covariates_ls$Training) <- names(Covariates_ls$Target) <- c("GMTED2010", "tkdry", "tksat", "csol", "k_s", "lambda", "psi", "theta_s")
	}else{
		Covariates_ls <- CovariateSetup(Training = MonthlySummaries$`2m_temperature`[[1]],
																		Target = 0.01,
																		FilePrefix = paste0(RegionName, "_"),
																		Covariates = c("GMTED2010", "tkdry", "tksat", "csol", "k_s", "lambda", "psi", "theta_s"),
																		Source = "Drive",
																		Dir = Dir.Covariates,
																		Extent = RegionIter,
																		Keep_Global = TRUE)
	}
	
	### Elevation-Informed Kriging ++++++++++++++++++++++++++
	ElevKrig_ls <- c(unlist(MonthlySummaries$`2m_temperature`))
	ElevKriged_ls <- lapply(ElevKrig_ls, FUN = function(Krig_Iter){
		Name <- basename(tools::file_path_sans_ext(terra::sources(Krig_Iter)))
		print(Name)
		### kriging itself
		Kriged_rast <- Kriging(
			Data = Krig_Iter,
			Covariates_training = Covariates_ls[[1]],
			Covariates_target = Covariates_ls[[2]],
			Equation = "GMTED2010",
			Cores = parallel::detectCores(),
			Dir = Dir.Krig,
			FileExtension = ".nc",
			FileName = Name,
			Keep_Temporary = FALSE,
			nmax = 40,
			verbose = TRUE
		)
		Kriged_rast
	})
	
	### Soil-Property-Informed Kriging ++++++++++++++++++++++++++
	SoilKrig_ls <- c(unlist(MonthlySummaries[which(startsWith(names(MonthlySummaries), "volumetric"))]))
	SoilKriged_ls <- lapply(SoilKrig_ls, FUN = function(Krig_Iter){
		Name <- basename(tools::file_path_sans_ext(terra::sources(Krig_Iter)))
		print(Name)
		### kriging itself
		Kriged_rast <- Kriging(
			Data = Krig_Iter,
			Covariates_training = Covariates_ls[[1]],
			Covariates_target = Covariates_ls[[2]],
			Equation = "tkdry + tksat + csol + k_s + lambda + psi + theta_s",
			Cores = parallel::detectCores(),
			Dir = Dir.Krig,
			FileExtension = ".nc",
			FileName = Name,
			Keep_Temporary = FALSE,
			nmax = 40,
			verbose = TRUE
		)
		Kriged_rast
	})
	
})
		