-- Create Table   
USE world_layoffs;

CREATE TABLE layoffs (
    company VARCHAR(100),
    location VARCHAR(100),
    industry VARCHAR(100),
    total_laid_off INT,
    percentage_laid_off VARCHAR(20),
    `date` VARCHAR(20),
    stage VARCHAR(50),
    country VARCHAR(100),
    funds_raised_millions INT
);

-- Verify the total number of records
SELECT COUNT(*) 
FROM layoffs;

-- View the original dataset
SELECT *
FROM layoffs;

-- Create a staging table   
CREATE TABLE layoffs_staging
LIKE layoffs;

-- View the staging table
SELECT *
FROM layoffs_staging;

-- Insert data from original table to staging table
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- Verify the total number of records
SELECT *
FROM layoffs_staging;

-- Identify duplicate records using ROW_NUMBER() to assign a unique row number
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

-- Create a CTE to identify duplicate records across all relevant columns
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- Cross-check a sample company to manually verify potential duplicate records
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Remove duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE 
FROM duplicate_cte
WHERE row_num > 1;

-- Create a second staging table with an additional row_num column
CREATE TABLE `layoffs_staging2` (
  `company` varchar(100) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `industry` varchar(100) DEFAULT NULL,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` varchar(20) DEFAULT NULL,
  `date` varchar(20) DEFAULT NULL,
  `stage` varchar(50) DEFAULT NULL,
  `country` varchar(100) DEFAULT NULL,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Verify that the second staging table has been created
SELECT *
FROM layoffs_staging2;

-- INSERT data from first staging table to second staging table and assign row numbers
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Identify duplicates
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Delete duplicates while retaining the first occurrence
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Verify that all identified duplicate records have been removed
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- View the cleaned second staging table
SELECT *
FROM layoffs_staging2;

-- Standardizing data

-- Identify leading and trailing spaces in company names using TRIM()
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Remove leading and trailing spaces from company names permanently
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Retrieve unique industry values to identify inconsistencies
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Identify industry values beginning with 'Crypto'
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Standardise all industry values beginning with 'Crypto' to 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Verify that the industry values have been successfully standardised
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- View all unique industry values after standardisation
SELECT DISTINCT industry
FROM layoffs_staging2;

-- View the updated dataset
SELECT *
FROM layoffs_staging2;

-- Retrieve unique location values to identify inconsistencies
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- Review all records sorted by the first column (company)
SELECT *
FROM layoffs_staging2
ORDER BY 1;

-- Retrieve unique country values to identify inconsistencies
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- Identify country values beginning with 'United States'
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

-- Compare original country values with trimmed values
SELECT DISTINCT country, TRIM(country)
FROM layoffs_staging2
ORDER BY 1;

-- Remove trailing full stops from country names for comparison
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Remove trailing full stops from United States country names
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Verify the country values after removing trailing full stops
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- View the dataset after standardising country names
SELECT *
FROM layoffs_staging2;

-- Retrieve the date column to inspect the existing date format
SELECT `date`
FROM layoffs_staging2;

-- Convert date values from VARCHAR format (MM/DD/YYYY) into DATE format
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Update the date column with the converted date values
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Verify that the date values have been successfully converted
SELECT `date`
FROM layoffs_staging2;

-- Change the date column data type from VARCHAR to DATE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- View the final dataset to verify the date conversion
SELECT *
FROM layoffs_staging2;

-- Identify records where the total_laid_off column contains NULL values
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

-- Identify records where both total_laid_off and percentage_laid_off are NULL
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Retrieve unique industry values to review the available categories
SELECT DISTINCT industry
FROM layoffs_staging2;

-- Identify records where the industry column contains NULL or blank values
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Investigate Airbnb records to check for missing or inconsistent industry values
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Identify companies with missing industry values
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Populate missing industry values using existing industry information
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Verify whether any NULL or blank industry values remain
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Investigate Bally records to manually check company information
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- View the dataset after handling missing industry values
SELECT *
FROM layoffs_staging2;

-- Identify records where both total_laid_off and percentage_laid_off are NULL
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete records where both total_laid_off and percentage_laid_off are NULL
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Verify that records with both layoff fields missing have been removed
SELECT *
FROM layoffs_staging2;

-- Remove the temporary row_num column used during duplicate identification and removal
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- View the final cleaned dataset after removing the temporary column
SELECT *
FROM layoffs_staging2;




























