create database project;

use project;
select * from hr_data;

-- DATA CLEANING
-- 1. changing the name of id column into emp_id

alter table hr_data change column ï»¿id emp_id varchar(20) null;

-- 2. checking the data type of the each column of dataset

describe hr_data;

-- 3. updating the birthdate text into date formate

select birthdate from hr_data;

set sql_safe_updates = 0;

update hr_data
set birthdate = case
when birthdate like '%/%' then date_format(str_to_date(birthdate,'%m/%d/%Y'),'%Y-%m-%d')
when birthdate like '%-%' then date_format(str_to_date(birthdate,'%m-%d-%Y'),'%Y-%m-%d')
else null
end;

alter table hr_data
modify column birthdate date;

select birthdate from hr_data;

-- 4. updating the hiredate text into date formate

select hire_date from hr_data;

update hr_data
set hire_date = case
when hire_date like '%/%' then date_format(str_to_date(hire_date,'%m/%d/%Y'),'%Y-%m-%d')
when hire_date like '%-%' then date_format(str_to_date(hire_date,'%m-%d-%Y'),'%Y-%m-%d')
else null
end;

alter table hr_data
modify column hire_date date;

select hire_date from hr_data; 

-- 5. updating the termdate text into date

update hr_data 
set termdate = date(str_to_date(termdate,'%Y-%m-%d %H:%i:%s UTC'))
where termdate is not null and termdate != ' ';

alter table hr_data
modify column termdate date;

select termdate from hr_data;

-- 6. adding the age column to our dataset

alter table hr_data add column age int;

update hr_data
set age = timestampdiff(year,birthdate,curdate());

select
min(age) as youngest,
max(age) as oldest
from hr_data;

select count(*) from hr_data  where  age < 18;

select birthdate,age from hr_data;

-- KPI QUESTION

-- 1. what is the gender breakdown of employee in the company?

select gender, count(*) as count
from hr_data
where age >= 18 and termdate = '0000-00-00'
group by gender;

-- 2. what is the race/ethnicity breakdown of employees in the company?

SELECT race, COUNT(*) AS count
FROM hr_data
WHERE age >= 18 and termdate = '0000-00-00'
GROUP BY race
ORDER BY count DESC;

-- 3. what is the age distribution of employees in the company?

SELECT 
  MIN(age) AS youngest,
  MAX(age) AS oldest
FROM hr_data
WHERE age >= 18 and termdate = '0000-00-00';

SELECT FLOOR(age/10)*10 AS age_group, COUNT(*) AS count
FROM hr_data
WHERE age >= 18 and termdate = '0000-00-00'
GROUP BY FLOOR(age/10)*10;

SELECT 
  CASE 
    WHEN age >= 18 AND age <= 24 THEN '18-24'
    WHEN age >= 25 AND age <= 34 THEN '25-34'
    WHEN age >= 35 AND age <= 44 THEN '35-44'
    WHEN age >= 45 AND age <= 54 THEN '45-54'
    WHEN age >= 55 AND age <= 64 THEN '55-64'
    ELSE '65+' 
  END AS age_group, 
  COUNT(*) AS count
FROM 
  hr_data
WHERE 
  age >= 18 and termdate = '0000-00-00'
GROUP BY age_group
ORDER BY age_group;

SELECT 
  CASE 
    WHEN age >= 18 AND age <= 24 THEN '18-24'
    WHEN age >= 25 AND age <= 34 THEN '25-34'
    WHEN age >= 35 AND age <= 44 THEN '35-44'
    WHEN age >= 45 AND age <= 54 THEN '45-54'
    WHEN age >= 55 AND age <= 64 THEN '55-64'
    ELSE '65+' 
  END AS age_group, gender,
  COUNT(*) AS count
FROM 
  hr_data
WHERE 
  age >= 18 and termdate = '0000-00-00'
GROUP BY age_group, gender
ORDER BY age_group, gender; 

-- 4. How many employees work at headquarters versus remote locations?

SELECT location, COUNT(*) as count
FROM hr_data
WHERE age >= 18 and termdate = '0000-00-00'
GROUP BY location;

-- 5. What is the average length of employment for employees who have been terminated?

SELECT ROUND(AVG(DATEDIFF(termdate, hire_date))/365,0) AS avg_length_of_employment
FROM hr_data
WHERE termdate <> '0000-00-00' AND termdate <= CURDATE() AND age >= 18;

SELECT ROUND(AVG(DATEDIFF(termdate, hire_date)),0)/365 AS avg_length_of_employment
FROM hr_data
WHERE termdate <= CURDATE() AND age >= 18;

-- 6. How does the gender distribution vary across departments?

SELECT department, gender, COUNT(*) as count
FROM hr_data
WHERE age >= 18 and termdate = '0000-00-00'
GROUP BY department, gender
ORDER BY department;

-- 7. What is the distribution of job titles across the company?

SELECT jobtitle, COUNT(*) as count
FROM hr_data
WHERE age >= 18
GROUP BY jobtitle
ORDER BY jobtitle DESC;

-- 8. Which department has the highest turnover rate?

SELECT department, COUNT(*) as total_count, 
    SUM(CASE WHEN termdate <= CURDATE() AND termdate <> '0000-00-00' THEN 1 ELSE 0 END) as terminated_count, 
    SUM(CASE WHEN termdate = '0000-00-00' THEN 1 ELSE 0 END) as active_count,
    (SUM(CASE WHEN termdate <= CURDATE() THEN 1 ELSE 0 END) / COUNT(*)) as termination_rate
FROM hr_data
WHERE age >= 18
GROUP BY department
ORDER BY termination_rate DESC;

-- 9. What is the distribution of employees across locations by state?

SELECT location_state, COUNT(*) as count
FROM hr_data
WHERE age >= 18 and termdate = '0000-00-00'
GROUP BY location_state
ORDER BY count DESC;

-- 10. How has the company's employee count changed over time based on hire and term dates?

SELECT 
    YEAR(hire_date) AS year, 
    COUNT(*) AS hires, 
    SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations, 
    COUNT(*) - SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS net_change,
    ROUND(((COUNT(*) - SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END)) / COUNT(*) * 100),2) AS net_change_percent
FROM 
    hr_data
WHERE age >= 18
GROUP BY 
    YEAR(hire_date)
ORDER BY 
    YEAR(hire_date) ASC;
    
SELECT 
    year, 
    hires, 
    terminations, 
    (hires - terminations) AS net_change,
    ROUND(((hires - terminations) / hires * 100), 2) AS net_change_percent
FROM (
    SELECT 
        YEAR(hire_date) AS year, 
        COUNT(*) AS hires, 
        SUM(CASE WHEN termdate <> '0000-00-00' AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
    FROM 
        hr_data
    WHERE age >= 18
    GROUP BY 
        YEAR(hire_date)
) subquery
ORDER BY 
    year ASC;
    
-- 11. What is the tenure distribution for each department?

SELECT department, ROUND(AVG(DATEDIFF(CURDATE(), termdate)/365),0) as avg_tenure
FROM hr_data
WHERE termdate <= CURDATE() AND termdate <> '0000-00-00' AND age >= 18
GROUP BY department
 
