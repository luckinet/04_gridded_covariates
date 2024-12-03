# ----
# title       : prepare gridded layers - _INESRT
# description : This is the script for hamonizing _INSERT
# license     : https://creativecommons.org/licenses/by-sa/4.0/
# authors     : Luise Quoß, Steffen Ehrmann
# date        : 2024-10-21
# version     : 0.0.0
# status      : find data, update, inventarize, validate, normalize, done
# comment     : file.edit(paste0(dir_docs, "/documentation/mdl_prepare_gridded_layers.md"))
# ----
# doi/url     : _INSERT
# license     : _INSERT
# resolution  : _INSERT
# years       : _INSERT
# variables   : _INSERT
# ----

thisDataset <- "wdpa"
message("\n---- ", thisDataset, " ----")

thisDir <- paste0(.get_path("grid", "_data"), thisDataset, "/")
# source(paste0(.get_path("grid", "_data"), "preprocess_", thisDataset, ".R"))

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



## develop layer ----

# Selection of subset for creation of rasterized dataset
# a. PADDD Dataset
# - selection: "EnactedPro" = 'Enacted'
# - explanation: exclude proposed
# b. IUCN Protected Areas (WDPA)
# - selection: "STATUS" != 'Not Reported' and "STATUS" != 'Proposed'
# - explanation: only include protected area or OECM definitions(see pages 39/40 in pdf: I:\MAS\01_projects\LUCKINet\01_data\WDPA_WDOECM\Resources_in_English\WDPA_WDOECM_Manual_1_6.pdf)




# input
wdpa_root = r'I:\MAS\01_projects\LUCKINet\01_data\WDPA_WDOECM\WDPA_WDOECM_merged_shps'
paddd_root = r'I:\MAS\01_projects\LUCKINet\01_data\PADDDtracker_DataReleaseV2_May2019'
wdpa = os.path.join(wdpa_root,'IUCN_Protected_Areas_merged.shp')
paddd = os.path.join(paddd_root,'PADDDtracker_DataReleaseV2_May2019_Poly.shp')
out_root = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\WDPA_PADDD_preprocessing\preprocessing_01'

#output shps
paddd_select = os.path.join(out_root, 'PADDD_preprocessing_01.shp')
wdpa_select = os.path.join(out_root, 'WDPA_preprocessing_01.shp')

if not os.path.exists(paddd_select):
  filter = """"SELECT * FROM PADDDtracker_DataReleaseV2_May2019_Poly where "EnactedPro"='Enacted'" """
  cmd = 'ogr2ogr -sql {} {} {}'.format(filter, paddd_select, paddd)
  os.system(cmd)

if not os.path.exists(wdpa_select):
  filter = """ "SELECT * FROM IUCN_Protected_Areas_merged where "STATUS" != 'Not Reported' and "STATUS" != 'Proposed'" """
  cmd = 'ogr2ogr -sql {} {} {}'.format(filter, wdpa_select, wdpa)
  os.system(cmd)






  # WDPA&PADDD: creating several csv lists with the missing values (regarding IUCN category and different year values)
  # find tables here: I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\TablesMissingValues
  # all tables with ending '_filled' some added values and corresponding sources

  tables_root = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\TablesMissingValues'
  out_root = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\WDPA_PADDD_preprocessing\preprocessing_01'
  paddd_select = os.path.join(out_root, 'PADDD_preprocessing_01.shp')
  wdpa_select = os.path.join(out_root, 'WDPA_preprocessing_01.shp')

  if not os.path.exists(tables_root):
    os.mkdir(tables_root)

  # load data ----
  #
  # PADDD
  driver = ogr.GetDriverByName("ESRI Shapefile")
  dataSource = driver.Open(paddd_select, 0)
  layer = dataSource.GetLayer()

  # data processing ----
  # write output ----
  #
  # PADDD

  #YearPADDD
  layer.SetAttributeFilter("YearPADDD = 'unk'")
  result = {'PADDD_ID': ['Country', 'allnames', 'EventType', 'Areaaffect', 'YearPADDD']}
  for feat in layer:
    id = feat.GetField("PADDD_ID")
  country= feat.GetField("Country")
  names = feat.GetField("allnames")
  type = feat.GetField("EventType")
  area = feat.GetField("Areaaffect")
  result[id] = [country, names, type, area, '']

  outpath = os.path.join(tables_root, 'PADDD_YearPADDD.csv')
  pd.DataFrame.from_dict(data=result, orient='index').to_csv(outpath, header=False)


  #reversed with unknown year
  layer.SetAttributeFilter("Reversal = 'Y' and YR_Reverse = 'unk'")
  result = {'PADDD_ID': ['Country', 'allnames', 'EventType', 'Areaaffect', 'YR_Reverse']}
  for feat in layer:
    id = feat.GetField("PADDD_ID")
  country= feat.GetField("Country")
  names = feat.GetField("allnames")
  type = feat.GetField("EventType")
  area = feat.GetField("Areaaffect")
  result[id] = [country, names, type, area, '']

  outpath = os.path.join(tables_root, 'PADDD_YR_Reverse.csv')
  pd.DataFrame.from_dict(data=result, orient='index').to_csv(outpath, header=False)


  #unknown year of gazette
  layer.SetAttributeFilter("YearPAGaze = 'unk'")
  result = {'PADDD_ID': ['Country', 'primarynam','allnames','EventType', 'Areaaffect', 'YearPAGaze']}
  for feat in layer:
    id = feat.GetField("PADDD_ID")
  country= feat.GetField("ISO3166")
  primary = feat.GetField('primarynam')
  names = feat.GetField("allnames")
  type = feat.GetField("EventType")
  area = feat.GetField("Areaaffect")
  result[id] = [country, primary, names, type, area, '']

  outpath = os.path.join(tables_root, 'PADDD_YearPAGaze.csv')
  pd.DataFrame.from_dict(data=result, orient='index').to_csv(outpath, header=False)


  #is there downgrade with unknown IUCN_pre and/or IUCN_post?
  layer.SetAttributeFilter("(IUCN_post = 'unk' or IUCN_pre = 'unk') and EventType = 'Downgrade'")
  print(layer.GetFeatureCount())
  result = {'PADDD_ID': ['Country', 'allnames', 'EventType', 'Areaaffect', 'YearPAGaze', 'IUCN_post', 'IUCN_pre']}
  i = 0
  for feat in layer:
    id = feat.GetField("PADDD_ID")
  country= feat.GetField("Country")
  names = feat.GetField("allnames")
  type = feat.GetField("EventType")
  area = feat.GetField("Areaaffect")
  year = feat.GetField("YearPAGaze")
  post = feat.GetField("IUCN_post")
  pre = feat.GetField("IUCN_pre")
  result[id] = [country, names, type, area, year, post, pre]
  i += 1

  outpath = os.path.join(tables_root, 'PADDD_downgrade_missing_IUCN.csv')
  pd.DataFrame.from_dict(data=result, orient='index').to_csv(outpath, header=False)

  #close file
  dataSource = None
  layer = None

  # load data ----
  #
  # WDPA
  dataSource = driver.Open(wdpa_select, 0)
  layer = dataSource.GetLayer()

  # data processing ----
  # write output ----
  #
  # WDPA

  #STATUS_YR
  layer.SetAttributeFilter("STATUS_YR = '0'")
  result = {'WDPA_PID': ['name', 'iso3', 'desig_eng', 'iucn_cat', 'gis_area', 'Status_yr']}
  for feat in layer:
    id = feat.GetField("WDPA_PID")
  name = feat.GetField("NAME")
  iso3 = feat.GetField("ISO3")
  desig_eng = feat.GetField("DESIG_ENG")
  iucn_cat = feat.GetField("IUCN_CAT")
  gis_area = feat.GetField("GIS_AREA")
  result[id] = [name, iso3, desig_eng, iucn_cat, gis_area, '']

  outpath = os.path.join(tables_root, 'WDPA_status_yr.csv')
  pd.DataFrame.from_dict(data=result, orient='index').to_csv(outpath, header=False)

  #STATUS_YR
  layer.SetAttributeFilter("IUCN_CAT = 'Not Assigned'")
  result = {'WDPA_PID': ['name', 'iso3', 'desig_eng', 'iucn_cat', 'gis_area']}
  for feat in layer:
    id = feat.GetField("WDPA_PID")
  name = feat.GetField("NAME")
  iso3 = feat.GetField("ISO3")
  desig_eng = feat.GetField("DESIG_ENG")
  iucn_cat = feat.GetField("IUCN_CAT")
  gis_area = feat.GetField("GIS_AREA")
  result[id] = [name, iso3, desig_eng, iucn_cat, gis_area]

  outpath = os.path.join(tables_root, 'WDPA_not_assigned.csv')
  pd.DataFrame.from_dict(data=result, orient='index').to_csv(outpath, header=False)


  #close file
  dataSource = None
  layer = None


  # PADDD: match 188 features with missinge gazette year to the IUCN dataset by name matching (using the status_yr column of IUCN to fill missing Gazette Year)
  # after this script: added a column exclude: check manually if some matches should be excluded


  out_root = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\WDPA_PADDD_preprocessing\preprocessing_01'
  wdpa_select = os.path.join(out_root, 'WDPA_preprocessing_01.shp')
  table_root = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\TablesMissingValues'
  table = os.path.join(table_root, 'PADDD_YearPAGaze_filled.csv')

  # load data ----
  #
  driver = ogr.GetDriverByName("ESRI Shapefile")
  ds = driver.Open(wdpa_select, 0)
  wdpa = ds.GetLayer()

  # data processing ----
  #
  names = []
  ids = []
  for feat in wdpa:
    names.append(feat.GetField("NAME"))
  ids.append(feat.GetField('WDPA_PID'))

  result = {'WDPA_PID': ['PADDD_ID', 'Country', 'primaryname_PADDD', 'name_WDPA', 'STATUS_YR']}

  with open(table, 'r') as paddd:
    csv = reader(paddd)
  for row in csv:
    input = row[2].lower()
  #remove: national, park, state, protected, area
  for r in ['national', 'park', 'state', 'protected', 'area', 'nature', 'reserve', 'conservation', 'hunting']:
    input = input.replace(r, '')
  input = input.strip(' ')
  i = 0
  for name_iucn in names:
    name = name_iucn.lower()
  for r in ['national', 'park', 'state', 'protected', 'area', 'nature', 'reserve', 'conservation', 'hunting']:
    name = name.replace(r, '')
  name = name.strip(' ')
  #https://www.datacamp.com/community/tutorials/fuzzy-string-python
  ratio = fuzz.token_set_ratio(input,name)
  if ratio > 90:
    #print(input, '\t', name)
    filter = "WDPA_PID = '{}'".format(ids[i])
  wdpa.SetAttributeFilter(filter)
  for feat in wdpa:
    year = feat.GetField('STATUS_YR')
  cnt = feat.GetField('ISO3')
  if row[1] == cnt:
    #print(input, '\t', name, year)
    result[ids[i]] = [row[0], cnt, row[2], name_iucn, year]
  i += 1

  # write output ----
  #
  outpath = os.path.join(table_root, 'PADDD_YearPAGaze_deteced.csv')
  pd.DataFrame.from_dict(data=result, orient='index').to_csv(outpath, header=False)



  # PADDD & WDPA: rasterize all single features 10x10 meters
  # already spatially adjust them to the 100x100 raster with ul corner -180,90
  # change values in dictionary 'cats' to change the value the pixel get assigned (in case the definition of the categories changes)
  # the PADDD year is always accounted in the following year. a degazetted protected area with PADDD_YR=1990 will still be included in 1990 and removed beginning in 1991
  # all features with missing years are removed - should be no problem anymore after missing values treatment (lines 70-72)
  # outputname: DATASET_preprocessing_02_YEAR_CATEGORY_ID.tif


  input_root = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\WDPA_PADDD_preprocessing\preprocessing_01'
  paddd_path = os.path.join(input_root, 'PADDD_preprocessing_01.shp')
  wdpa_path = os.path.join(input_root, 'WDPA_preprocessing_01.shp')
  out_path = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\WDPA_PADDD_preprocessing\preprocessing_02'

  # load data ----
  #
  # global variables
  cats = {'Ia': 1, 'Ib': 2, 'I': 2, 'II': 2, 'III': 2,'IV': 2, 'V': 5, 'VI':3, 'Not Applicable':6, 'Not Assigned':6, 'Not Reported':6}
  res_y = round((10/111319.5), 10)
  res_x = round((10/111319.5), 10)
  #log file
  log = {'ID': ['Year', 'type', 'yearPADD', 'yearRV', 'REV', 'IUCN_cat']}

  #open shp files
  inDriver = ogr.GetDriverByName("ESRI Shapefile")
  wdpa_datasource = inDriver.Open(wdpa_path, 1)
  wdpa = wdpa_datasource.GetLayer()

  driver = ogr.GetDriverByName("ESRI Shapefile")
  paddd_datasource = driver.Open(paddd_path, 1)
  paddd = paddd_datasource.GetLayer()

  # data processing ----
  #
  # write output ----
  #

  #get years of all polygons
  years = []
  for feature in wdpa:
    y = feature.GetField("STATUS_YR")
  if y not in years:
    years.append(y)

  for feature in paddd:
    y1 = feature.GetField("YearPAGaze")
  y2 = feature.GetField("YearPADDD")
  y3 = feature.GetField("YR_Reverse")
  if y1 not in years:
    years.append(y1)
  if y2 not in years:
    years.append(y2)
  if y3 not in years:
    years.append(y3)

  years.sort()
  years.remove('na') #no reverse
  years.remove('0') #unknown WDPA
  years.remove('unk') #unknown PADDD
  years.remove('n/a')

  remove = []
  for year in years:
    #print(int(year))
    if int(year) < 1970:
    remove.append(year)

  for r in remove:
    years.remove(r)


  #loop through years:
  for year in tqdm(years[0:7]): #CHANGE
    print(year)
  year = int(year)+1 #to avoid <= symbol
  #select features from wdpa
  filter_wdpa = "STATUS_YR < '{}'".format(year)
  #print(filter_wdpa)
  t = wdpa.SetAttributeFilter(filter_wdpa)
  #select features from paddd
  filter_paddd = "YearPAGaze < '{}'".format(year)
  t = paddd.SetAttributeFilter(filter_paddd)
  #loop through features WDPA
  #print('wdpa', wdpa.GetFeatureCount())
  for feature in wdpa:
    id = feature.GetField("WDPA_PID")
  iucn_cat = feature.GetField("IUCN_CAT")
  cat = cats[iucn_cat]
  #output = os.path.join(out_path, str(year-1) + '_'+ str(cat) + '_' + id +  '_wdpa_10m.tif')
  output = os.path.join(out_path, 'WDPA_preprocessing_02_' + str(year-1) + '_'+ str(cat) + '_' + id + '.tif')
  if not (os.path.exists(output)):
    #filter for the one shape with the corresponding ID
    filter_gdal = """ "SELECT * FROM WDPA_preprocessing_01 where "WDPA_PID" = '{}'" """.format(id)
  #get extent of that shape
  geom=feature.GetGeometryRef()
  #extent = geom.GetEnvelope()
  x_min, x_max, y_min, y_max = geom.GetEnvelope()
  #align extent of output as if it started at -180, 90 ul corner
  geotrans = [-180, (res_x*10), 0, 90, 0, (-res_y*10)]
  xmin_factor = int((x_min- geotrans[0])/ geotrans[1])
  xmax_factor = int((x_max- geotrans[0])/ geotrans[1])
  ymax_factor = int((y_max - geotrans[3])/ geotrans[-1])
  ymin_factor = int((y_min - geotrans[3])/ geotrans[-1])
  new_x_min =  geotrans[0]+xmin_factor * geotrans[1]
  new_y_max = geotrans[3]+ymax_factor * geotrans[-1]
  new_x_max =  geotrans[0]+xmax_factor * geotrans[1]
  new_y_min = geotrans[3]+ymin_factor * geotrans[-1]
  #make sure the whole area is still covered
  while new_x_max < x_max:
    new_x_max = new_x_max + (res_x*10)
  while new_y_min > y_min:
    new_y_min = new_y_min - (res_x*10)
  te = str(new_x_min) + ' ' + str(new_y_min) + ' ' + str(new_x_max) + ' ' + str(new_y_max)
  cmd = 'gdal_rasterize -burn {} -at -sql {} -tr {} {} -ot Byte -te {} -co compress=deflate {} {}'.format(cat, filter_gdal, res_x, res_y, te, wdpa_path, output)
  #print(cmd)
  os.system(cmd)
  #loop through features PADDD
  print('paddd', paddd.GetFeatureCount())
  for feature in paddd:
    id = feature.GetField("PADDD_ID")
  paddd_type = feature.GetField("EventType")
  rev = feature.GetField("Reversal")
  try:
    rev_year = int(feature.GetField("YR_Reverse"))
  except:
    rev_year = 2020 #highest year so no reverse is set
  paddd_year = int(feature.GetField("YearPADDD"))
  #get cat based on EventType and Reversal
  #degazatted in a later year: IUCN_pre is valid
  if paddd_type == 'Degazette' and paddd_year >= (year-1):
    iucn_cat = feature.GetField("IUCN_pre")
  cat = cats[iucn_cat]
  #reversed degazatte
  elif paddd_type == 'Degazatte' and rev == 'Y' and rev_year < (year-1):
    iucn_cat = feature.GetField("IUCN_pre")
  cat = cats[iucn_cat]
  #downsize does not change the IUCN cat
  elif paddd_type == 'Downsize':
    iucn_cat = feature.GetField("IUCN_pre")
  cat = cats[iucn_cat]
  #downgrade is not yet reversed
  elif paddd_type == 'Downgrade' and paddd_year < (year-1) and rev_year >= (year-1) and rev == 'Y':
    iucn_cat = feature.GetField("IUCN_post")
  cat = cats[iucn_cat]
  #downsized and not reversed
  elif paddd_type == 'Downgrade' and paddd_year < (year-1) and rev == 'N':
    iucn_cat = feature.GetField("IUCN_post")
  cat = cats[iucn_cat]
  #not yer downgegraded
  elif paddd_type == 'Downgrade' and paddd_year >= (year-1):
    iucn_cat = feature.GetField("IUCN_pre")
  cat = cats[iucn_cat]
  #erversed downgrade
  elif paddd_type == 'Downgrade' and rev_year < (year-1) and rev == 'Y':
    iucn_cat = feature.GetField("IUCN_pre")
  cat = cats[iucn_cat]
  #PAs that are degazatted during that year
  elif (paddd_type == 'Degazette' and paddd_year < (year-1) and rev == 'N') or (paddd_type == 'Degazette' and paddd_year < (year-1) and rev_year > (year-1) and rev == 'Y'):
    print('degazatted', id, paddd_year, rev_year)
  continue #jumps the feature in this for loop - no feature should be created
  else:
    log[id] = [year-1,paddd_type, paddd_year,  rev_year, rev, iucn_cat]
  #output = os.path.join(out_path, str(year-1) + '_'+ str(cat) + '_' + id +  '_paddd_10m.tif')
  output = os.path.join(out_path, 'WDPA_preprocessing_02_' + str(year-1) + '_'+ str(cat) + '_' + id + '.tif')
  if not (os.path.exists(output)):
    #filter for the one shape with the corresponding ID
    filter_gdal = """ "SELECT * FROM PADDD_preprocessing_01 where "PADDD_ID" = '{}'" """.format(id)
  #get extent of that shape
  geom=feature.GetGeometryRef()
  x_min, x_max, y_min, y_max = geom.GetEnvelope()
  #align extent of output as if it started at -180, 90 ul corner
  geotrans = [-180, (res_x*10), 0, 90, 0, (-res_y*10)]
  xmin_factor = int((x_min- geotrans[0])/ geotrans[1])
  xmax_factor = int((x_max- geotrans[0])/ geotrans[1])
  ymax_factor = int((y_max - geotrans[3])/ geotrans[-1])
  ymin_factor = int((y_min - geotrans[3])/ geotrans[-1])
  new_x_min =  geotrans[0]+xmin_factor * geotrans[1]
  new_y_max = geotrans[3]+ymax_factor * geotrans[-1]
  new_x_max =  geotrans[0]+xmax_factor * geotrans[1]
  new_y_min = geotrans[3]+ymin_factor * geotrans[-1]
  #make sure the whole area is still covered
  while new_x_max < x_max:
    new_x_max = new_x_max + (res_x*10)
  while new_y_min > y_min:
    new_y_min = new_y_min - (res_x*10)
  te = str(new_x_min) + ' ' + str(new_y_min) + ' ' + str(new_x_max) + ' ' + str(new_y_max)
  cmd = 'gdal_rasterize -burn {} -at -sql {} -tr {} {} -ot Byte -te {} -co compress=deflate {} {}'.format(cat, filter_gdal, res_x, res_y, te, paddd_path, output)
  os.system(cmd)

  #write log
  date = str(date.today()).replace('-', '_')
  outpath = os.path.join(out_path, 'log_'+ date +'.csv')
  pd.DataFrame.from_dict(data=log, orient='index').to_csv(outpath, header=False)

  #close shps
  wdpa = None
  wdpa_datasource = None
  paddd = None
  paddd_datasource = None


  # PADDD & WDPA: upsample all single features 100x100 meters
  # 1 tif per feature with 2 bands
  # 1. band including the category
  # 2. band including the percentage of the 100x100 pixel covered by the 10x10 pixels of the feature
  # outputname: DATASET_preprocessing_03_YEAR_CATEGORY_ID.tif

  def _read_data(inTif, band_nr, verbose):
    '''
    internale function to read the data from raster
    '''
  try:
    band = inTif.GetRasterBand(band_nr)
  data = _gdalnum.BandReadAsArray(band)
  if type(data)==None.__class__:
    raise Exception('no data to read')
  else:
    noda = band.GetNoDataValue()
  if verbose:
    if noda == None:
    print('\n\n   WARNING: There is no "NODATA" value inside the raster specified \n \
       --> continue without\n\n')
  return data, noda
  except Exception:
    print('can not read input as array')
  finally:
    inTif = None
  def read(tif, band='all', nodata=False, verbose=True):
    '''
    reads in a tif, and returns a numpy array;

    to read a tif into numpy array

    tif -- full path to tif to read in
    band -- number of band to read, default read all bands
    nodata -- return nodata value default False

    >>> data = mp.tif.read(fullPath) # or e.g. (fullpath, band=2, nodata=True)

    fullPath --> full path plus the filename
    bandNr   --> the number of the band you want to read

    if band is set to a certain value it will read just this band;
    default is to read the first band; to read in all bands set band to zero;
    band can also be a list e.g.: [1,4,5] will be readin in the same order as passed
    (if band is a list start counting by 1);
    creates a 2d or 3d stack;

    shape is (rows, columns for 2d) (band, rows, columns for 3d)
    '''
  #default band is 1 and default for return nodata value is False ~ 0 ;1 ~ True
  inTif = _gdalnum.gdal.Open(tif, _gdalcon.GA_ReadOnly)
  if inTif == None:
    raise IOError ('input is not a file or file is broken: {}'.format(tif))
  _sys.exit(1)
  if inTif.GetGeoTransform() == (0.0, 1.0, 0.0, 0.0, 0.0, 1.0):
    if verbose:
    print('\n\n   WARNING: Missing Geo Information \n\
    --> origin, resolution and tilt not specified\n\
    --> continue without\n')
  availeble_bands = inTif.RasterCount # number of available bands in tif
  if band == 'all':
    #get number of available bands and create list from it with range
    if availeble_bands != 1:
    nr_of_bands = [x for x in range(1, availeble_bands+1)]
  else:
    nr_of_bands = 1
  elif type(band)== int and band <= availeble_bands and band>0:
    nr_of_bands = 1
  elif type(band)==list and \
  all(type(item) == int for item in band) and \
  all(item > 0 for item in band) and len(band)>0:
    nr_of_bands = band
  #test if max passed value is in the range of possible bands
  if _np.array(nr_of_bands).max() <= availeble_bands:
    pass
  else:
    raise ValueError('Error: in passed band value(s): {}; type of: {}; number of available bands: {}'.format(
      band, type(band), availeble_bands))
  _sys.exit(1)
  array_to_return = []
  if nr_of_bands == 1:
    if type(band)==str:
    band = 1
  array_to_return, nodata_val =  _read_data(inTif, band, verbose)
  elif type(nr_of_bands) == list and len(nr_of_bands) > 1:
    for b in nr_of_bands:
    #initialize and create the stack
    if b == 1 :
    stack, nodata_val = _read_data(inTif, b, verbose)
  stack = stack.reshape(1, stack.shape[0], stack.shape[1])
  else:
    #read in all other bands
    stack = _np.vstack((stack, _read_data(inTif, b, verbose=None)[0].reshape((1, stack.shape[1], stack.shape[2]))))
  array_to_return =  stack
  if nodata:
    return array_to_return, nodata_val
  else:
    return array_to_return

  # set paths ----
  #
  src_path = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\WDPA_PADDD_preprocessing\preprocessing_02'
  out_path = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\WDPA_PADDD_preprocessing\preprocessing_03'
  #check outputpath
  if not os.path.exists(out_path):
    os.mkdir(out_path)

  # load data ----
  #
  #global variables
  old_res = round((10/111319.5), 10)
  res_y = old_res * 10
  res_x =  old_res * 10

  #list files
  files = os.listdir(src_path)

  # data processing ----
  # write output ----
  #

  #loop through files
  for file in tqdm(files):
    if file.endswith('.tif'):
    #basic variables
    name = file.replace('_02_', '_03_')
  file = os.path.join(src_path, file)
  outfile = os.path.join(out_path, name)
  if not os.path.exists(outfile):
    #open file to numpy array
    array = read(file, 1, verbose=False)
  #empty array with 100x100 m resolution
  result = _np.empty([int(array.shape[0]/10),int(array.shape[1]/10)], dtype=int)
  percentage = _np.empty([int(array.shape[0]/10),int(array.shape[1]/10)], dtype=int)
  #moving window to decide for new value
  i=0
  for row in range(0, array.shape[0], 10): #range(1, array.shape[0], 10)
    j = 0
  for col in range(0, array.shape[1], 10): #range(1, array.shape[1], 10):
    end_row = row+10
  end_col = col+10
  #read subpart 10x10
  part = array[row:end_row, col:end_col]
  #count all non-zero pixels
  count = _np.count_nonzero(part)
  #check if more than 50% of the area are covered by a PA
  result[i,j] = len(_np.bincount(_np.reshape(part, part.size)))-1
  percentage[i,j] = count
  j += 1
  i += 1
  #write data
  inTiff = _gdalnum.gdal.Open(file, _gdalcon.GA_ReadOnly)
  inRows, inCols = result.shape[0], result.shape[1]
  geotrans = inTiff.GetGeoTransform()
  #get ul corner
  ul_x = geotrans[0]
  ul_y = geotrans[3]
  #create empty file
  driver = _gdalnum.gdal.GetDriverByName('GTiff')
  dataOut = driver.Create(outfile,inCols,inRows,2, _gdalcon.GDT_Int16)
  #set projection
  prj = inTiff.GetProjectionRef()
  l= dataOut.SetProjection(prj)
  #set extent/resolution
  l= dataOut.SetGeoTransform((ul_x, res_x, 0, ul_y, 0, -res_y))
  #write data - band 1
  bandOut = dataOut.GetRasterBand(1)
  l= bandOut.SetNoDataValue(0)
  _gdalnum.BandWriteArray(bandOut,result)
  #write data - band 2
  bandOut = dataOut.GetRasterBand(2)
  l = bandOut.SetNoDataValue(0)
  l = _gdalnum.BandWriteArray(bandOut,percentage)
  #close file
  bandOut = None
  dataOut = None
  inTiff = None


  # merge all 100x100 rasterized features (WDPA and PADDD together)
  # all files are sorted so the last feature has the highest category --> will overwrite the other value --> result: layer that always includes the highest category
  # outputnames: WDPA_PADDD_preprocessing_04_YEAR.tif

  root_path = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\WDPA_PADDD_preprocessing\preprocessing_03'
  out_path = r'I:\MAS\01_projects\LUCKINet\01_data\gridded_data\PA_gridded\WDPA_PADDD_preprocessing\preprocessing_04'
  #check output path
  if not os.path.exists(out_path):
    os.mkdir(out_path)

  # load data ----
  #
  #global variables
  old_res = round((10/111319.5), 10)
  res_y = old_res * 10
  res_x =  old_res * 10

  #list all files
  files = os.listdir(root_path)

  # data processing ----
  # write output ----
  #
  #get all years
  years = []
  for file in files:
    if file.endswith('.tif'):
    y = file.split('_')[3]
  if y not in years:
    years.append(y)
  years.sort()
  print(years)

  #loop through years
  for year in tqdm(years):
    print(year)
  file_list = []
  for file in files:
    #get all files of the specific year
    if file.split('_')[3]==year:
    #only use the tif files
    if file.endswith('.tif'):
    #add filename to list
    file_list.append(file)
  if len(file_list) > 0 :
    #when files overlap: gdalwarp writes last file, therefore sort, to write highest IUCN cat (lowest value)
    #sort list from biggest do lowest category
    file_list.sort(reverse=True, key= lambda x: x.split('_')[4])
  i=0
  j=1
  year_list = []
  while i <= (len(file_list)-1):
    file_list_joined = ''
  while len(file_list_joined) < (8178-422-46) and i < len(file_list): #max-length cmd 8191 - length base cmd command - length new filename+1
    #print(i)
    file_list_joined = file_list_joined + file_list[i] + ' '
  i += 1
  name = 'WDPA_PADDD_preprocessing_04_{}_{}.tif'.format(year, j)
  #join output path and name
  out = os.path.join(out_path, name)
  year_list.append(out)
  if not os.path.exists(out):
    cmd = 'cd /D {} && gdalwarp -of GTiff -ot Byte -co BIGTIFF=YES -r near -tr {} {} -co COMPRESS=DEFLATE -overwrite --config GDAL_CACHEMAX 8000 -wm 8000 -te -180 -90 180 90 {} {}'.format(root_path, res_x, res_y, file_list_joined, out)
  #print(cmd)
  print(len(cmd))
  #run command
  os.system(cmd)
  j += 1
  #merge all files of one year
  final = os.path.join(out_path, 'WDPA_PADDD_preprocessing_04_{}.tif'.format(year))
  if not os.path.exists(final):
    if len(year_list) > 1:
    year_list = ' '.join(year_list)
  #define output name according to year
  name = 'WDPA_PADDD_preprocessing_04_{}_.tif'.format(year)
  #join output path and name
  result = os.path.join(out_path, name)
  print(result)
  cmd = 'gdalwarp -of GTiff -ot Byte -co BIGTIFF=YES -r near -tr {} {} -co COMPRESS=DEFLATE -overwrite --config GDAL_CACHEMAX 8000 -wm 8000 -te -180 -90 180 90 {} {}'.format(res_x, res_y, year_list, result)
  #run command
  os.system(cmd)
  #remove old files
  for old_file in year_list:
    os.rm(old_file)
  #if only one file: rename
  else:
    cmd = 'rename {} {}'.format(year_list[0], final)
  os.system(cmd)
