SELECT *
FROM CovidDeaths /* OR you can call the table by FROM Portfolio Project..CovidDeaths*/
ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations /* OR you can call the table by FROM Portfolio Project..CovidDeaths*/
--ORDER BY 3,4

--DATA I will be using 
SELECT location, date, total_cases,new_cases, total_deaths, population
FROM CovidDeaths 
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--I want to know the percentage of people dying in South Africa
ALTER TABLE CovidDeaths ALTER COLUMN total_cases float; /* changed the datatype of the column from nvarchar to float*/
--You can also change it using: cast(total_cases as float)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths 
WHERE location LIKE 'South Africa%'
ORDER BY 1,2


--Looking at Total Cases vs Population
--I want to know the percentage of people getting infected in South Africa
SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
FROM CovidDeaths 
WHERE location LIKE 'South Africa%'
ORDER BY 1,2


--Looking at Countries with highest infection rate compared to their population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectionPercentage
FROM CovidDeaths 
--WHERE location LIKE 'South Africa'
GROUP BY location, population
ORDER BY InfectionPercentage DESC

--Looking at Countries with highest Death rate compared to their population
SELECT location, population, MAX(total_deaths) as HighestDeathCount, MAX((total_deaths/population))*100 as DeathPercentage
FROM CovidDeaths 
--WHERE location LIKE 'South Africa%'
WHERE continent IS  NULL
GROUP BY location, population
ORDER BY DeathPercentage DESC

/**** WE HAVE BEEN LOOKING OR QUERING THE DATA BY LOCATIONS, NOW LET'S LOOK AT THINGS BY CONTINENT****/
--Looking at CONTINENTS with highest Death rate compared to their population
SELECT continent, MAX(total_deaths) as HighestDeathCount, MAX((total_deaths/population))*100 as DeathPercentage
FROM CovidDeaths 
--WHERE location LIKE 'South Africa%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathPercentage DESC

--Looking at continent with highest infection rate compared to their population
SELECT continent, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectionPercentage
FROM CovidDeaths 
--WHERE location LIKE 'South Africa'
GROUP BY continent
ORDER BY InfectionPercentage DESC


/**** LOOKING AT THE GLOBAL NUMBERS ****/
--Looking at the total or sum of new cases per day GLOBALLY, percentage to death per day
ALTER TABLE CovidDeaths ALTER COLUMN new_deaths float
--use the function NULLIF(COLUMN_NAME,0) if you are dividing with a column that might have 0
SELECT  date, SUM(new_cases) as Total_cases, SUM(new_deaths) as Total_deaths, (SUM(new_deaths)/NULLIF(SUM(new_cases),0))*100 as DeathPercentage
FROM CovidDeaths 
--WHERE location LIKE 'South Africa%' 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--Looking at the total or sum of new cases GLOBALLY and the percentage of death
SELECT SUM(new_cases) as Total_cases, SUM(new_deaths) as Total_deaths, (SUM(new_deaths)/NULLIF(SUM(new_cases),0))*100 as DeathPercentage
FROM CovidDeaths 
--WHERE location LIKE 'South Africa%' 
WHERE continent IS NOT NULL
ORDER BY 1,2

/**** NOW WE ARE WORKING ON BOTH TABLES ****/
--Looking at the Population vs Vaccinations, the total number of people in then world that have been vaccinated

ALTER TABLE CovidVaccinations ALTER COLUMN new_vaccinations float --CONVERT(FLOAT, new.vaccination)
SELECT CD.continent, CD.location, CD.date,CD.population, CV.new_vaccinations,
SUM(CV.new_vaccinations)  OVER (PARTITION BY CD.location ORDER BY CD.date) as Total_vaccinations -- I  want to ORDER BY CD.location, CD.date but it shows an error
FROM CovidDeaths CD
JOIN CovidVaccinations CV
ON CD.location = CV.location 
AND CD.date = CV.date 
WHERE CD.continent is not null
--AND CD.location LIKE 'South Africa%'
ORDER BY 2,3

--Using a CTE or a Tem_Table to get the number of vaccinated people/vaccination in a population
--Bcoz you can't do a calculation with an object/column that you have just created
/**** CTE ****/
With Vaccinated_P (continent, location, date, population, new_vaccinations, Total_vaccinations) as 
(
SELECT CD.continent, CD.location, CD.date,CD.population, CV.new_vaccinations,
SUM(CV.new_vaccinations)  OVER (PARTITION BY CD.location ORDER BY CD.date) as Total_vaccinations 
FROM CovidDeaths CD
JOIN CovidVaccinations CV
ON CD.location = CV.location 
AND CD.date = CV.date 
WHERE CD.continent is not null
--AND CD.location LIKE 'South Africa%'
--ORDER BY 2,3
)
SELECT *, (Total_vaccinations/population)*100 as Vaccinated_Population 
FROM Vaccinated_P --this select statement runs with it CTE

/**** TEMP TABLE ***/
DROP TABLE IF EXISTS #Vaccinated_Population
CREATE TABLE #Vaccinated_Population
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Total_vaccinations numeric
)
INSERT INTO #Vaccinated_Population
SELECT CD.continent, CD.location, CD.date,CD.population, CV.new_vaccinations,
SUM(CV.new_vaccinations)  OVER (PARTITION BY CD.location ORDER BY CD.date) as Total_vaccinations 
FROM CovidDeaths CD
JOIN CovidVaccinations CV
ON CD.location = CV.location 
AND CD.date = CV.date 
WHERE CD.continent is not null
--AND CD.location LIKE 'South Africa%'
ORDER BY 2,3

SELECT *, (Total_vaccinations/population)*100 as Vaccinated_Population 
FROM #Vaccinated_Population

/**** CREATING A VIEW TO STORE DATA FOR VISUALAZATION ****/

CREATE VIEW Vaccinated_Population as 
SELECT CD.continent, CD.location, CD.date,CD.population, CV.new_vaccinations,
SUM(CV.new_vaccinations)  OVER (PARTITION BY CD.location ORDER BY CD.date) as Total_vaccinations 
FROM CovidDeaths CD
JOIN CovidVaccinations CV
ON CD.location = CV.location 
AND CD.date = CV.date 
WHERE CD.continent is not null
--AND CD.location LIKE 'South Africa%'
--ORDER BY 2,3