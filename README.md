# test_exam_april_2025
2 hours test exam in Data Engineering - Tuesday the 8. of April 2025

🌍 REST Countries Statistics API

This is a Plumber API built in R that uses data from restcountries.com to serve country-level statistics and visualizations.

🚀 How to Run the API
	1.	Open RStudio and open the plumber.R file.
	2.	Run this command in the console:
plumber::plumb("plumber.R")$run(port = 8000)
	3.	Open Swagger documentation in your browser:
http://127.0.0.1:8000/docs

📊 Endpoints Overview

Only selected fields are fetched from the API (name, languages, region, population, borders) to optimize performance and focus on the exam requirements.

✅ Data Endpoints

	•	/language-count-many – Count how many countries speak each of the given languages (comma-separated)
	•	/top-regions – Return all regions sorted by number of countries
	•	/population-rank?n=10 – Return top and bottom n countries by population (default is 10)
	•	/most-borders – Return the 5 countries with the most land borders

🖼️ Visualization Endpoints

	•	/plot-top-regions – Horizontal barplot of countries per region (PNG)
	•	/plot-most-borders – Barplot of the 5 countries with the most borders (PNG)
	•	/map-most-borders – World map showing the top 5 countries with most land borders, highlighted in color (PNG)

💾 Data Handling

When the API starts, it attempts to fetch live data from the REST Countries API.
If the request fails (e.g. due to no internet), it loads data from a local file: countries_backup.json.
If the online fetch works, the backup file will automatically be updated.

🧠 Example Usage

Count how many countries speak English, French, and Spanish:
GET /language-count-many?langs=english,french,spanish

View a map of the top 5 border-heavy countries:
GET /map-most-borders

🛠 Required R Packages

Make sure the following packages are installed:
plumber, httr, jsonlite, dplyr, maps, pacman

Install them like this:
install.packages(c("plumber", "httr", "jsonlite", "dplyr", "maps", "pacman"))

📁 Included Files
	•	plumber.R – Main API script
	•	countries_backup.json – Local backup used if API fetch fails
	•	README.md – This file

👨‍🎓 Author

Created for the Data Engineering Test Exam – April 2025
Student: 55530 Martin Eckberg Bindner
Program: PBA Data Analytics – Data Engineering - EA Dania
