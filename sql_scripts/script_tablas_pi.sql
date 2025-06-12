-- 1. Crear la base de datos
DROP DATABASE IF EXISTS sales_company;
CREATE DATABASE IF NOT EXISTS sales_company;
USE sales_company;

-- 2. Crear las tablas

DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
  CategoryID INT PRIMARY KEY,
  CategoryName VARCHAR(45)
);

DROP TABLE IF EXISTS countries;
CREATE TABLE countries (
  CountryID INT PRIMARY KEY,
  CountryName VARCHAR(100),
  CountryCode VARCHAR(10)
);

DROP TABLE IF EXISTS cities;
CREATE TABLE cities (
  CityID INT PRIMARY KEY,
  CityName VARCHAR(45),
  Zipcode VARCHAR(10),
  CountryID INT
);

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
  CustomerID INT PRIMARY KEY,
  FirstName VARCHAR(100),
  MiddleInitial CHAR(5),
  LastName VARCHAR(100),
  CityID INT,
  Address VARCHAR(255)
);

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
  EmployeeID INT PRIMARY KEY,
  FirstName VARCHAR(100),
  MiddleInitial CHAR(1),
  LastName VARCHAR(100),
  BirthDate DATETIME,
  Gender CHAR(1),
  CityID INT,
  HireDate DATETIME
);

DROP TABLE IF EXISTS products;
CREATE TABLE products (
  ProductID INT PRIMARY KEY,
  ProductName VARCHAR(255),
  Price DECIMAL(10,4),
  CategoryID INT,
  Class VARCHAR(50),
  ModifyDate TIME,
  Resistant VARCHAR(50),
  IsAllergic VARCHAR(10),
  VitalityDays INT
);

DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
  SalesID INT PRIMARY KEY,
  SalesPersonID INT,
  CustomerID INT,
  ProductID INT,
  Quantity INT,
  Discount DECIMAL(4,2),
  TotalPrice DECIMAL(10,2),
  SalesDate DATETIME,
  TransactionNumber VARCHAR(50)
);