#
# This is a Plumber API. You can run the API by clicking
# the 'Run API' button above.
#
# Find out more about building APIs with Plumber here:
#
#    https://www.rplumber.io/
#

# countries_backup.json will be saved automatically and used
# if API fetch fails. This ensures the API can still work offline
# or if the remote server is down.

# Load required libraries
pacman::p_load(
  plumber,
  httr,
  jsonlite,
  dplyr
)

# Global variable to store the fetched country data
countries_data <- NULL

#* @apiTitle REST Countries Statistics API
#* @apiDescription An API that returns statistics about countries using data from restcountries.com

# ------------------------------------------------------------------------------
# Load data from API
# ------------------------------------------------------------------------------

#* Load data from the REST Countries API (or local backup) when the API starts
#* @plumber
function(pr) {
  url <- "https://restcountries.com/v3.1/all?fields=name,languages,region,population,borders"
  
  # Try to fetch data from the API using HTTP/1.1 (more stable)
  res <- try(httr::GET(url, httr::config(http_version = 1)), silent = TRUE)
  
  if (inherits(res, "try-error") || httr::status_code(res) != 200) {
    # If API request fails, load from local backup
    message("⚠️ Could not fetch online data. Loading local backup...")
    countries_data <<- jsonlite::fromJSON("countries_backup.json", flatten = TRUE)
  } else {
    # If successful, parse and save data
    countries_data <<- jsonlite::fromJSON(rawToChar(res$content), flatten = TRUE)
    jsonlite::write_json(countries_data, "countries_backup.json", pretty = TRUE)
  }
  
  # Set JSON output formatting
  pr %>% pr_set_serializer(serializer_unboxed_json())
}

# ------------------------------------------------------------------------------
# Language count
# ------------------------------------------------------------------------------

#* @get /language-count-many
#* Count how many countries speak multiple languages
#* @param langs Comma-separated list of language names (e.g. english,french,spanish)
function(langs = "english,french,spanish") {
  lang_list <- strsplit(tolower(langs), ",")[[1]] %>% trimws()
  result <- list()
  
  for (lang in lang_list) {
    url <- paste0("https://restcountries.com/v3.1/lang/", lang)
    res <- try(httr::GET(url, httr::config(http_version = 1)), silent = TRUE)
    
    if (inherits(res, "try-error") || httr::status_code(res) != 200) {
      result[[lang]] <- "language not found"  # ✅ forbedret fallback
    } else {
      countries <- jsonlite::fromJSON(rawToChar(res$content), flatten = TRUE)
      result[[lang]] <- length(countries)
    }
  }
  
  return(result)
}

# ------------------------------------------------------------------------------
# Top regions
# ------------------------------------------------------------------------------

#* @get /top-regions
#* Return all regions sorted by number of countries
function() {
  if (is.null(countries_data)) {
    return(list(error = "Data not loaded"))
  }
  
  countries_data %>%
    count(region, name = "country_count") %>%
    filter(!is.na(region)) %>%
    arrange(desc(country_count))
}

# ------------------------------------------------------------------------------
# Countries population
# ------------------------------------------------------------------------------

#* @get /population-rank
#* Return top and bottom N countries by population
#* @param n Number of countries to include from top and bottom (default: 10)
function(n = 10) {
  if (is.null(countries_data)) {
    return(list(error = "Data not loaded"))
  }
  
  n <- as.numeric(n)
  
  pop_data <- countries_data %>%
    select(name.common, population) %>%
    filter(!is.na(population)) %>%
    arrange(population)
  
  list(
    least_populated = head(pop_data, n),
    most_populated = tail(pop_data, n) %>% arrange(desc(population))
  )
}

# ------------------------------------------------------------------------------
# Most borders
# ------------------------------------------------------------------------------

#* @get /most-borders
#* Return the 5 countries with the most borders
function() {
  if (is.null(countries_data)) {
    return(list(error = "Data not loaded"))
  }
  
  countries_data %>%
    mutate(border_count = sapply(borders, length)) %>%
    select(name.common, border_count) %>%
    arrange(desc(border_count)) %>%
    head(5)
}



# ------------------------------------------------------------------------------
# Plot top regions
# ------------------------------------------------------------------------------

#* @get /plot-top-regions
#* @serializer png
#* Generate a stylish barplot of number of countries per region
function() {
  if (is.null(countries_data)) {
    plot.new()
    text(0.5, 0.5, "Data not loaded")
    return()
  }
  
  data <- countries_data %>%
    count(region, name = "country_count") %>%
    filter(!is.na(region)) %>%
    arrange(country_count)
  
  par(mar = c(6, 6, 4, 2))  # margins: bottom, left, top, right
  
  barplot(
    height = data$country_count,
    names.arg = data$region,
    horiz = TRUE,
    col = terrain.colors(nrow(data)),
    las = 1,
    main = "🌍 Number of Countries per Region",
    xlab = "Number of Countries",
    border = NA
  )
}



# ------------------------------------------------------------------------------
# Plot most borders
# ------------------------------------------------------------------------------

#* @get /plot-most-borders
#* @serializer png
#* Stylish plot of the 5 countries with the most borders
function() {
  if (is.null(countries_data)) {
    plot.new()
    text(0.5, 0.5, "Data not loaded")
    return()
  }
  
  data <- countries_data %>%
    mutate(border_count = sapply(borders, length)) %>%
    select(name.common, border_count) %>%
    arrange(desc(border_count)) %>%
    head(5)
  
  par(mar = c(6, 6, 4, 2))  # tilpas margen
  
  barplot(
    height = data$border_count,
    names.arg = data$name.common,
    col = heat.colors(5),
    ylim = c(0, max(data$border_count) + 2),
    las = 2,
    main = "🗺️ Top 5 Countries with Most Borders",
    ylab = "Number of Borders",
    border = NA
  )
}


#* @get /map-most-borders
#* @serializer png
#* Show a world map with the 5 countries with the most borders, each with unique color
function() {
  if (is.null(countries_data)) {
    plot.new()
    text(0.5, 0.5, "Data not loaded")
    return()
  }
  
  library(maps)
  
  # Top 5 countries with most borders
  top_borders <- countries_data %>%
    mutate(border_count = sapply(borders, length)) %>%
    select(name.common, border_count) %>%
    arrange(desc(border_count)) %>%
    head(5)
  
  country_names <- tolower(top_borders$name.common)
  colors <- heat.colors(length(country_names))
  
  # Base map
  map("world", fill = TRUE, col = "gray90", bg = "lightblue", lwd = 0.2)
  title("🌍 Countries with Most Land Borders")
  
  # Draw each country individually with unique color
  for (i in seq_along(country_names)) {
    try({
      map("world", regions = country_names[i], fill = TRUE, col = colors[i], add = TRUE)
    }, silent = TRUE)
  }
}