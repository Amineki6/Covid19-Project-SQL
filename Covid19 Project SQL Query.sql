SELECT * 
FROM PortfolioProjectCovid..CovidDeaths 
ORDER BY 3, 4 ;

SELECT * 
FROM PortfolioProjectCovid..CovidVaxx
WHERE location = N'Morocco'
ORDER BY 3, 4 ;


-- Data to be used

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProjectCovid..CovidDeaths 
ORDER BY 1,2 ;

-- Total Deaths vs Total Cases (Case Fatality Rate):

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as CaseFatalityRate 
FROM PortfolioProjectCovid..CovidDeaths 
ORDER BY 1,2 ;

-- Get the latest CaseFatalityRate from each country:

SELECT location, (MAX(total_deaths)/MAX(total_cases))*100 as CaseFatalityRate
FROM PortfolioProjectCovid..CovidDeaths 
GROUP BY location, population 
ORDER BY 2 DESC ;

 -- Total Cases vs Population:

SELECT location, population, (MAX(total_cases)/population)*100 as CasesPopulationPercentage
FROM PortfolioProjectCovid..CovidDeaths 
--WHERE location = N'Germany'
GROUP BY location, population
ORDER BY 3 DESC;

-- Total Deaths vs Population

SELECT location, population , (MAX(total_deaths)/population)*100 as DeathsPopulationPercentage
FROM PortfolioProjectCovid..CovidDeaths 
--WHERE location = N'Germany'
--WHERE continent = N'Africa'
GROUP BY location, population
ORDER BY 3 DESC;

--------- Data by Continent -------------------


-- Total Cases by Continent

SELECT q.continent, SUM(q.population) as population , SUM(q.TotalCases) as total_cases, (SUM(q.TotalCases)/SUM(q.population))*100 as CasesPopulationPercentage
FROM (
	SELECT continent ,location, population , MAX(total_cases) as TotalCases
	FROM PortfolioProjectCovid..CovidDeaths 
	--WHERE location = N'Germany'
	WHERE continent IS NOT NULL
	GROUP BY location, population , continent
)q
GROUP BY q.continent
ORDER BY 4 DESC

-- Total Deaths by Continent

SELECT q.continent, SUM(q.population) as population , SUM(q.TotalDeaths) as total_deaths, (SUM(q.TotalDeaths)/SUM(q.population))*100 as DeathsPopulationPercentage
FROM (
	SELECT continent ,location, population , MAX(total_deaths) as TotalDeaths
	FROM PortfolioProjectCovid..CovidDeaths 
	--WHERE location = N'Germany'
	WHERE continent IS NOT NULL
	GROUP BY location, population , continent
)q
GROUP BY q.continent
ORDER BY 4 DESC


--------- Global Numbers -------------------

 -- Total Cases vs Population:

SELECT location, population, MAX(total_cases) as Total_cases  , (MAX(total_cases)/population)*100 as CasesPopulationPercentage
FROM PortfolioProjectCovid..CovidDeaths 
--WHERE location = N'Germany'
WHERE location = N'World'
GROUP BY location, population



-- Total Deaths vs Population:

SELECT location, population, MAX(total_deaths) as Total_deaths , (MAX(total_deaths)/population)*100 as DeathsPopulationPercentage
FROM PortfolioProjectCovid..CovidDeaths 
--WHERE location = N'Germany'
WHERE location = N'World'
GROUP BY location, population;

-- Total Deaths vs Total Cases (Case Fatality Rate):
SELECT location, population, MAX(total_cases) as Total_cases, MAX(total_deaths) as Total_deaths , (MAX(total_deaths)/MAX(total_cases))*100 as CaseFatalityRate
FROM PortfolioProjectCovid..CovidDeaths 
--WHERE location = N'Germany'
WHERE location = N'World'
GROUP BY location, population
ORDER BY 3 DESC;

--Join Both Tables
SELECT *
FROM PortfolioProjectCovid..CovidDeaths dea
JOIN PortfolioProjectCovid..CovidVaxx vax
	ON dea.location = vax.location and 
		dea.date = vax.date
WHERE dea.continent is not null
ORDER BY 3,4

-- People fully vaccinated vs Country Population:

SELECT vax.location, MAX(cast(vax.people_fully_vaccinated as bigint)) as NumFullVaxx, (MAX(cast(vax.people_fully_vaccinated as bigint))/dea.population)*100 as FullVaxxPercentage
FROM PortfolioProjectCovid..CovidDeaths dea
JOIN PortfolioProjectCovid..CovidVaxx vax
	ON dea.location = vax.location and 
		dea.date = vax.date
WHERE dea.continent is not null
GROUP BY vax.location, dea.population
ORDER BY 2 DESC

--Average reproductive_rate per Country:

SELECT vax.location, AVG(dea.reproduction_rate) as avg_reproduction_rate
FROM PortfolioProjectCovid..CovidDeaths dea
JOIN PortfolioProjectCovid..CovidVaxx vax
	ON dea.location = vax.location and 
		dea.date = vax.date
WHERE dea.continent is not null
GROUP BY vax.location
ORDER BY 2 DESC

--Average reproductive_rate per Continent:

SELECT q.continent, AVG(q.avg_reproduction_rate) as avg_reproduction_rate
FROM(
	SELECT vax.location, vax.continent, AVG(dea.reproduction_rate) as avg_reproduction_rate
	FROM PortfolioProjectCovid..CovidDeaths dea
	JOIN PortfolioProjectCovid..CovidVaxx vax
	ON dea.location = vax.location and 
	dea.date = vax.date
	WHERE dea.continent is not null
	GROUP BY vax.location, vax.continent)q
GROUP BY q.continent
ORDER BY 2 DESC

-- Total Tests (ROLLING METHOD):

SELECT dea.continent, dea.location, dea.date, vax.new_tests,
		SUM(cast(vax.new_tests as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as Total_tests
FROM PortfolioProjectCovid..CovidDeaths dea
JOIN PortfolioProjectCovid..CovidVaxx vax
	ON dea.location = vax.location and 
		dea.date = vax.date
WHERE dea.continent is not null


-- Positve Cases / TotalTests (CTE):

WITH PosTest (Continent, Location, Date, Total_cases, New_tests, Total_tests)
as 
(
	SELECT dea.continent, dea.location, dea.date, dea.total_cases, vax.new_tests,
		SUM(cast(vax.new_tests as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as Total_tests
	FROM PortfolioProjectCovid..CovidDeaths dea
	JOIN PortfolioProjectCovid..CovidVaxx vax
		ON dea.location = vax.location and 
			dea.date = vax.date
	WHERE dea.continent is not null
)
SELECT * , (Total_cases/Total_tests)*100 as PercenatgeOfPositve
FROM PosTest
WHERE Location = N'Canada'

-- Positve Cases / TotalTests (Temp Table):

DROP TABLE IF EXISTS #TempTable
CREATE TABLE #TempTable
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
total_cases numeric,
Total_tests numeric
)
INSERT INTO #TempTable
SELECT dea.continent, dea.location, dea.date, dea.total_cases,
		SUM(cast(vax.new_tests as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as Total_tests
FROM PortfolioProjectCovid..CovidDeaths dea
JOIN PortfolioProjectCovid..CovidVaxx vax
		ON dea.location = vax.location and	
			dea.date = vax.date
WHERE dea.continent is not null

SELECT * , (Total_cases/Total_tests)*100 as PercenatgeOfPositve
FROM #TempTable
WHERE Location = N'Canada'




----------------------------------------- Creating Views ------------------------------------------------------------------:



CREATE VIEW CaseFatalityRate as
	SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as CaseFatalityRate 
	FROM PortfolioProjectCovid..CovidDeaths 

CREATE VIEW LatestCaseFatalityRate as
	SELECT location, (MAX(total_deaths)/MAX(total_cases))*100 as CaseFatalityRate
	FROM PortfolioProjectCovid..CovidDeaths 
	GROUP BY location, population 

CREATE VIEW CasesPercentagePopulation as
	SELECT location, population, (MAX(total_cases)/population)*100 as CasesPopulationPercentage
	FROM PortfolioProjectCovid..CovidDeaths 
	--WHERE location = N'Germany'
	GROUP BY location, population

CREATE VIEW DeathsPercentagePopulation as
	SELECT location, population , (MAX(total_deaths)/population)*100 as DeathsPopulationPercentage
	FROM PortfolioProjectCovid..CovidDeaths 
	--WHERE location = N'Germany'
	--WHERE continent = N'Africa'
	GROUP BY location, population

CREATE VIEW CasesPercentagePerContinent as
	SELECT q.continent, SUM(q.population) as population , SUM(q.TotalCases) as total_cases, (SUM(q.TotalCases)/SUM(q.population))*100 as CasesPopulationPercentage
	FROM (
		SELECT continent ,location, population , MAX(total_cases) as TotalCases
		FROM PortfolioProjectCovid..CovidDeaths 
		--WHERE location = N'Germany'
		WHERE continent IS NOT NULL
		GROUP BY location, population , continent
	)q
	GROUP BY q.continent

CREATE VIEW DeathsPercentagePerContinent as
	SELECT q.continent, SUM(q.population) as population , SUM(q.TotalDeaths) as total_deaths, (SUM(q.TotalDeaths)/SUM(q.population))*100 as DeathsPopulationPercentage
	FROM (
		SELECT continent ,location, population , MAX(total_deaths) as TotalDeaths
		FROM PortfolioProjectCovid..CovidDeaths 
		--WHERE location = N'Germany'
		WHERE continent IS NOT NULL
		GROUP BY location, population , continent
	)q
	GROUP BY q.continent

CREATE VIEW WorldCasesPercentage as
	SELECT location, population, MAX(total_cases) as Total_cases  , (MAX(total_cases)/population)*100 as CasesPopulationPercentage
	FROM PortfolioProjectCovid..CovidDeaths 
	--WHERE location = N'Germany'
	WHERE location = N'World'
	GROUP BY location, population

CREATE VIEW WorldDeathsPercentage as
	SELECT location, population, MAX(total_deaths) as Total_deaths , (MAX(total_deaths)/population)*100 as DeathsPopulationPercentage
	FROM PortfolioProjectCovid..CovidDeaths 
	--WHERE location = N'Germany'
	WHERE location = N'World'
	GROUP BY location, population;

CREATE VIEW WorldCaseFatalityRate as
	SELECT location, population, MAX(total_cases) as Total_cases, MAX(total_deaths) as Total_deaths , (MAX(total_deaths)/MAX(total_cases))*100 as CaseFatalityRate
	FROM PortfolioProjectCovid..CovidDeaths 
	--WHERE location = N'Germany'
	WHERE location = N'World'
	GROUP BY location, population

CREATE VIEW FullyVaxxedPercenatge as
	SELECT vax.location, MAX(cast(vax.people_fully_vaccinated as bigint)) as NumFullVaxx, (MAX(cast(vax.people_fully_vaccinated as bigint))/dea.population)*100 as FullVaxxPercentage
	FROM PortfolioProjectCovid..CovidDeaths dea
	JOIN PortfolioProjectCovid..CovidVaxx vax
		ON dea.location = vax.location and 
			dea.date = vax.date
	WHERE dea.continent is not null
	GROUP BY vax.location, dea.population

CREATE VIEW ReproductiveRatePerCountry as
	SELECT vax.location, AVG(dea.reproduction_rate) as avg_reproduction_rate
	FROM PortfolioProjectCovid..CovidDeaths dea
	JOIN PortfolioProjectCovid..CovidVaxx vax
		ON dea.location = vax.location and 
			dea.date = vax.date
	WHERE dea.continent is not null
	GROUP BY vax.location
	
CREATE VIEW ReproductiveRatePerContinent as
	SELECT q.continent, AVG(q.avg_reproduction_rate) as avg_reproduction_rate
	FROM(
		SELECT vax.location, vax.continent, AVG(dea.reproduction_rate) as avg_reproduction_rate
		FROM PortfolioProjectCovid..CovidDeaths dea
		JOIN PortfolioProjectCovid..CovidVaxx vax
		ON dea.location = vax.location and 
		dea.date = vax.date
		WHERE dea.continent is not null
		GROUP BY vax.location, vax.continent)q
	GROUP BY q.continent


CREATE VIEW NewTestsPerCountry as
	SELECT dea.continent, dea.location, dea.date, vax.new_tests,
			SUM(cast(vax.new_tests as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as Total_tests
	FROM PortfolioProjectCovid..CovidDeaths dea
	JOIN PortfolioProjectCovid..CovidVaxx vax
		ON dea.location = vax.location and 
			dea.date = vax.date
	WHERE dea.continent is not null


CREATE VIEW PercentageOfPositvePerCountry as
	WITH PosTest (Continent, Location, Date, Total_cases, New_tests, Total_tests)
	as 
	(
		SELECT dea.continent, dea.location, dea.date, dea.total_cases, vax.new_tests,
			SUM(cast(vax.new_tests as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as Total_tests
		FROM PortfolioProjectCovid..CovidDeaths dea
		JOIN PortfolioProjectCovid..CovidVaxx vax
			ON dea.location = vax.location and 
				dea.date = vax.date
		WHERE dea.continent is not null
	)
	SELECT * , (Total_cases/Total_tests)*100 as PercenatgeOfPositve
	FROM PosTest
