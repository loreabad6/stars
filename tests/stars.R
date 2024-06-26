Sys.setenv(TZ="UTC")
suppressPackageStartupMessages(library(stars))
set.seed(13521) # runif
tif = system.file("tif/L7_ETMs.tif", package = "stars")
(x_ = read_stars(c(tif,tif))) # FIXME: not what you'd expect
(x = read_stars(tif))
# image(x)
gdal_crs(tif)
plot(x)
plot(x, join_zlim = FALSE)
x %>% st_set_dimensions(names = c('a', 'b', 'c'))
st_get_dimension_values(x, 3)

(x1 = st_set_dimensions(x, "band", values = c(1,2,3,4,5,7), names = "band_number", point = TRUE))
rbind(c(0.45,0.515), c(0.525,0.605), c(0.63,0.69), c(0.775,0.90), c(1.55,1.75), c(2.08,2.35)) %>%
	units::set_units(um) -> bw # units::set_units(µm) -> bw
# set bandwidth midpoint:
(x2 = st_set_dimensions(x, "band", values = 0.5 * (bw[,1]+bw[,2]), 
   names = "bandwidth_midpoint", point = TRUE))
# set bandwidth intervals:
(x3 = st_set_dimensions(x, "band", values = make_intervals(bw), names = "bandwidth"))

x + x
x * x
x[,,,1:3]
x[,1:100,100:200,]
sqrt(x)
st_apply(x, 3, min)
st_apply(x, 1:2, max)
st_apply(x, 1:2, range)

geomatrix = system.file("tif/geomatrix.tif", package = "stars")
x = read_stars(geomatrix)
y = st_transform(x, st_crs(4326))
st_coordinates(x)[1:2,]

nc = system.file("nc/tos_O1_2001-2002.nc", package = "stars")
if (nc != "" && require(PCICt, quietly = TRUE)) {
  print(x <- read_stars(nc))
  print(st_bbox(x))
  s = st_as_stars(st_bbox(x)) # inside = NA
  print(st_bbox(s))
  s = st_as_stars(st_bbox(x), inside = TRUE)
  print(st_bbox(s))
  s = st_as_stars(st_bbox(x), inside = FALSE)
  print(st_bbox(s))
  (s = st_as_stars(st_bbox(x), dy = 1))
  print(st_bbox(s))
  print(identical(st_as_stars(st_bbox(x), dx = 1), st_as_stars(st_bbox(x), dy = 1)))
  s = st_as_stars(st_bbox(x), dx = 10)
  print(st_bbox(s))
  s = st_as_stars(st_bbox(x), dx = 20)
  print(st_bbox(s))
  x1 = x
  st_crs(x1) = "OGC:CRS84"
  print(identical(st_as_stars(st_bbox(x1), dx = 1), st_as_stars(st_bbox(x1), dx = units::set_units(1, degree))))

  df = as.data.frame(x)
  if (require(units, quietly = TRUE))
    print(units::drop_units(x))

  print(dimnames(x))
  dimnames(x) <- letters[1:3]
  print(dimnames(x))
} # PCICt

st_as_stars()

# multiple sub-datasets:
nc_red = system.file("nc/reduced.nc", package = "stars")
red = read_stars(nc_red)
red
plot(red)

x = st_xy2sfc(read_stars(tif)[,1:10,1:10,], as_points = FALSE)
st_bbox(x)
x = read_stars(tif)
merge(split(x, "band"))

read_stars(c(tif,tif)) # merges as attributes
read_stars(c(tif,tif), along = "sensor")
read_stars(c(tif,tif), along = 4)
read_stars(c(tif,tif), along = "band")
read_stars(c(tif,tif), along = 3)

# cut:
tif = system.file("tif/L7_ETMs.tif", package = "stars")
x = read_stars(tif)
cut(x, c(0, 50, 100, 255))
cut(x[,,,1,drop=TRUE], c(0, 50, 100, 255))
plot(cut(x[,,,1,drop=TRUE], c(0, 50, 100, 255)))

st_bbox(st_dimensions(x))
x[x < 0] = NA
x[is.na(x)] = 0

# c:
f = system.file("netcdf/avhrr-only-v2.19810902.nc", package = "starsdata")
if (FALSE && f != "") {
  files = c("avhrr-only-v2.19810901.nc",
  "avhrr-only-v2.19810902.nc",
  "avhrr-only-v2.19810903.nc",
  "avhrr-only-v2.19810904.nc",
  "avhrr-only-v2.19810905.nc",
  "avhrr-only-v2.19810906.nc",
  "avhrr-only-v2.19810907.nc",
  "avhrr-only-v2.19810908.nc",
  "avhrr-only-v2.19810909.nc")
  l = list()
  for (f in files) {
	from = system.file(paste0("netcdf/", f), package = "starsdata")
  	l[[f]] = read_stars(from, sub = c("sst", "anom"))
  }
  ret = do.call(c, l)
  print(ret)
  ret = adrop(c(l[[1]], l[[2]], l[[3]], along = list(times = as.Date("1981-09-01") + 0:2)))
  print(ret)
  #ret = adrop(adrop(c(l[[1]], l[[2]], l[[3]], along = "times")))
  #print(ret)
}

st_dimensions(list(matrix(1, 4, 4))) # st_dimensions.default

if (FALSE && require("starsdata", quietly = TRUE)) {
  # curvilinear:
  s5p = system.file(
      "sentinel5p/S5P_NRTI_L2__NO2____20180717T120113_20180717T120613_03932_01_010002_20180717T125231.nc",
      package = "starsdata")
  print(s5p)
  lat_ds = paste0("HDF5:\"", s5p, "\"://PRODUCT/latitude")
  lon_ds = paste0("HDF5:\"", s5p, "\"://PRODUCT/longitude")
  nit_ds = paste0("HDF5:\"", s5p, "\"://PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/nitrogendioxide_summed_total_column")
  lat = read_stars(lat_ds)
  lon = read_stars(lon_ds)
  nit = read_stars(nit_ds)
  nit[[1]][nit[[1]] > 9e+36] = NA
  
  ll = setNames(c(lon, lat), c("x", "y"))
  nit.c = st_as_stars(nit, curvilinear = ll)
  print(nit.c)

  s5p = system.file(
      "sentinel5p/S5P_NRTI_L2__NO2____20180717T120113_20180717T120613_03932_01_010002_20180717T125231.nc",
      package = "starsdata")
  nit.c2 = read_stars(s5p, 
  	sub = "//PRODUCT/SUPPORT_DATA/DETAILED_RESULTS/nitrogendioxide_summed_total_column",
    curvilinear = c("//PRODUCT/latitude", "//PRODUCT/longitude"))
  print(all.equal(nit.c, nit.c2))
}
