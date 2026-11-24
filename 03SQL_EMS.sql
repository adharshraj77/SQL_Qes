-- ==============================================================================
-- 1. DATABASE INITIALIZATION
-- ==============================================================================
CREATE DATABASE IF NOT EXISTS enterprise_ems
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE enterprise_ems;

-- ==============================================================================
-- 2. TABLE CREATION (Schema Definition)
-- ==============================================================================

-- Table 1: Locations (Independent Entity)
CREATE TABLE Locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    office_capacity INT CHECK (office_capacity > 0)
);

-- Table 2: Departments (One-to-Many with Locations)
CREATE TABLE Departments (
    dept_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    location_id INT,
    annual_budget DECIMAL(15,2) DEFAULT 0.00,
    
    CONSTRAINT fk_dept_location 
        FOREIGN KEY (location_id) 
        REFERENCES Locations(location_id) 
        ON DELETE SET NULL
);

-- Table 3: Roles (Independent Entity for Job Titles and Salary Bands)
CREATE TABLE Roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    job_title VARCHAR(100) NOT NULL UNIQUE,
    base_salary DECIMAL(10,2) NOT NULL,
    equity_grant_pct DECIMAL(4,2) DEFAULT 0.00 CHECK (equity_grant_pct BETWEEN 0.00 AND 10.00)
);

-- Table 4: Employees (Core Entity with Self-Referencing Foreign Key)
CREATE TABLE Employees (
    emp_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    hire_date DATE NOT NULL,
    status ENUM('Active', 'On Leave', 'Terminated') DEFAULT 'Active',
    
    -- Foreign Keys for relationships
    dept_id INT,
    role_id INT,
    manager_id INT, -- Self-referencing column for reporting hierarchy
    
    CONSTRAINT fk_emp_dept 
        FOREIGN KEY (dept_id) REFERENCES Departments(dept_id) ON DELETE RESTRICT,
    CONSTRAINT fk_emp_role 
        FOREIGN KEY (role_id) REFERENCES Roles(role_id) ON DELETE RESTRICT,
    CONSTRAINT fk_emp_manager 
        FOREIGN KEY (manager_id) REFERENCES Employees(emp_id) ON DELETE SET NULL,
        
    -- Indexing for frequent HR lookups
    INDEX idx_emp_email (email),
    INDEX idx_emp_names (last_name, first_name)
);

-- Table 5: Projects (Independent Entity)
CREATE TABLE Projects (
    project_id CHAR(36) PRIMARY KEY, -- Using UUIDs for enterprise scale
    project_name VARCHAR(150) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    project_status ENUM('Planning', 'In Progress', 'Completed', 'On Hold') DEFAULT 'Planning',
    
    CONSTRAINT chk_project_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Table 6: Employee_Projects (Many-to-Many Junction Table)
CREATE TABLE Employee_Projects (
    emp_id INT NOT NULL,
    project_id CHAR(36) NOT NULL,
    hours_allocated INT DEFAULT 40 CHECK (hours_allocated > 0 AND hours_allocated <= 160),
    assignment_role VARCHAR(50),
    
    PRIMARY KEY (emp_id, project_id), -- Composite Key
    
    CONSTRAINT fk_ep_emp 
        FOREIGN KEY (emp_id) REFERENCES Employees(emp_id) ON DELETE CASCADE,
    CONSTRAINT fk_ep_project 
        FOREIGN KEY (project_id) REFERENCES Projects(project_id) ON DELETE CASCADE
);

-- ==============================================================================
-- 3. DATA INSERTION (Populating the Tables)
-- ==============================================================================

-- Insert Locations
INSERT INTO Locations (city, state, country, office_capacity) VALUES
('Hyderabad', 'Telangana', 'India', 500),
('Bangalore', 'Karnataka', 'India', 800),
('Pune', 'Maharashtra', 'India', 350);

-- Insert Departments
INSERT INTO Departments (dept_name, location_id, annual_budget) VALUES
('AI & Data Science', 1, 1500000.00), -- Hyderabad
('Frontend Engineering', 1, 950000.00), -- Hyderabad
('Backend Architecture', 2, 1200000.00), -- Bangalore
('Human Resources', 3, 300000.00); -- Pune

-- Insert Roles
INSERT INTO Roles (job_title, base_salary, equity_grant_pct) VALUES
('Director of AI', 3500000.00, 5.00),
('Senior Data Scientist', 2200000.00, 2.50),
('Machine Learning Engineer', 1800000.00, 1.00),
('Full Stack React Developer', 1600000.00, 1.00),
('Database Administrator', 1400000.00, 0.50),
('HR Business Partner', 900000.00, 0.25);

-- Insert Employees (Inserting Managers first to satisfy Foreign Key constraints)
-- Manager 1 (emp_id 1)
INSERT INTO Employees (first_name, last_name, email, hire_date, dept_id, role_id, manager_id) VALUES
('Vikram', 'Sharma', 'v.sharma@enterprise.com', '2023-01-15', 1, 1, NULL); 

-- Manager 2 (emp_id 2)
INSERT INTO Employees (first_name, last_name, email, hire_date, dept_id, role_id, manager_id) VALUES
('Priya', 'Reddy', 'p.reddy@enterprise.com', '2023-03-01', 2, 4, NULL);

-- Regular Employees
INSERT INTO Employees (first_name, last_name, email, hire_date, dept_id, role_id, manager_id) VALUES
('Arjun', 'Nair', 'a.nair@enterprise.com', '2024-06-10', 1, 2, 1),
('Neha', 'Gupta', 'n.gupta@enterprise.com', '2024-08-22', 1, 3, 1),
('Rahul', 'Verma', 'r.verma@enterprise.com', '2025-02-14', 2, 4, 2),
('Sneha', 'Iyer', 's.iyer@enterprise.com', '2025-05-30', 2, 4, 2),
('Karan', 'Singh', 'k.singh@enterprise.com', '2023-11-05', 3, 5, NULL),
('Anjali', 'Menon', 'a.menon@enterprise.com', '2024-01-20', 4, 6, NULL);

-- Insert Projects (Using UUIDs)
INSERT INTO Projects (project_id, project_name, start_date, end_date, project_status) VALUES
('p-uuid-001', 'SciBERT Document Classifier', '2025-10-01', '2026-03-15', 'Completed'),
('p-uuid-002', 'Vite Real-Time Dashboard', '2026-01-10', NULL, 'In Progress'),
('p-uuid-003', 'Enterprise Data Warehouse Migration', '2026-05-01', '2026-12-31', 'Planning');

-- Insert Employee_Projects (Assigning resources to projects)
INSERT INTO Employee_Projects (emp_id, project_id, hours_allocated, assignment_role) VALUES
(1, 'p-uuid-001', 20, 'Project Sponsor'),
(3, 'p-uuid-001', 120, 'Lead NLP Modeler'),
(4, 'p-uuid-001', 80, 'Data Pipeline Engineer'),
(2, 'p-uuid-002', 40, 'Frontend Lead'),
(5, 'p-uuid-002', 100, 'UI/UX Developer'),
(6, 'p-uuid-002', 100, 'State Management Specialist'),
(7, 'p-uuid-003', 160, 'Lead DBA');


USE enterprise_ems;

-- ==============================================================================
-- 1. EXPANDING THE EMPLOYEE ROSTER (25 New Records)
-- ==============================================================================

-- Adding new Department Leads (Managers)
INSERT INTO Employees (first_name, last_name, email, hire_date, status, dept_id, role_id, manager_id) VALUES
('Amit', 'Desai', 'a.desai@enterprise.com', '2022-11-01', 'Active', 3, 5, NULL), -- Backend Lead (emp_id 8)
('Sunita', 'Rao', 's.rao@enterprise.com', '2021-05-15', 'Active', 4, 6, NULL);  -- HR Lead (emp_id 9)

-- Adding bulk AI & Data Science Team (Reporting to Vikram, emp_id 1)
INSERT INTO Employees (first_name, last_name, email, hire_date, status, dept_id, role_id, manager_id) VALUES
('Ravi', 'Kumar', 'r.kumar@enterprise.com', '2024-09-01', 'Active', 1, 3, 1),
('Sita', 'Patel', 's.patel@enterprise.com', '2025-01-10', 'Active', 1, 2, 1),
('Tariq', 'Khan', 't.khan@enterprise.com', '2025-03-22', 'Active', 1, 3, 1),
('Meera', 'Joshi', 'm.joshi@enterprise.com', '2024-11-30', 'On Leave', 1, 3, 1),
('Gaurav', 'Chopra', 'g.chopra@enterprise.com', '2026-02-01', 'Active', 1, 2, 1),
('Pooja', 'Bhat', 'p.bhat@enterprise.com', '2026-04-15', 'Active', 1, 3, 1);

-- Adding bulk Frontend Engineering Team (Reporting to Priya, emp_id 2)
INSERT INTO Employees (first_name, last_name, email, hire_date, status, dept_id, role_id, manager_id) VALUES
('Aditya', 'Sen', 'a.sen@enterprise.com', '2024-07-14', 'Active', 2, 4, 2),
('Kavita', 'Das', 'k.das@enterprise.com', '2025-08-05', 'Active', 2, 4, 2),
('Rohan', 'Mishra', 'r.mishra@enterprise.com', '2023-12-12', 'Terminated', 2, 4, 2),
('Ananya', 'Ghosh', 'a.ghosh@enterprise.com', '2026-01-20', 'Active', 2, 4, 2),
('Varun', 'Teja', 'v.teja@enterprise.com', '2025-10-10', 'Active', 2, 4, 2);

-- Adding bulk Backend Architecture Team (Reporting to Amit, emp_id 8)
INSERT INTO Employees (first_name, last_name, email, hire_date, status, dept_id, role_id, manager_id) VALUES
('Siddharth', 'Bose', 's.bose@enterprise.com', '2023-04-18', 'Active', 3, 5, 8),
('Nandini', 'Mukherjee', 'n.mukherjee@enterprise.com', '2024-02-28', 'Active', 3, 5, 8),
('Ishan', 'Kaur', 'i.kaur@enterprise.com', '2025-06-15', 'On Leave', 3, 5, 8),
('Divya', 'Prakash', 'd.prakash@enterprise.com', '2026-03-01', 'Active', 3, 5, 8),
('Omar', 'Syed', 'o.syed@enterprise.com', '2024-09-09', 'Active', 3, 5, 8),
('Riya', 'Singh', 'r.singh@enterprise.com', '2025-11-20', 'Active', 3, 5, 8),
('Dev', 'Kapoor', 'd.kapoor@enterprise.com', '2026-05-10', 'Active', 3, 5, 8);

-- Adding bulk HR Team (Reporting to Sunita, emp_id 9)
INSERT INTO Employees (first_name, last_name, email, hire_date, status, dept_id, role_id, manager_id) VALUES
('Manoj', 'Tiwari', 'm.tiwari@enterprise.com', '2022-08-08', 'Active', 4, 6, 9),
('Kriti', 'Sanon', 'k.sanon@enterprise.com', '2024-10-12', 'Active', 4, 6, 9),
('Farhan', 'Akhtar', 'f.akhtar@enterprise.com', '2025-04-18', 'Active', 4, 6, 9),
('Deepika', 'Padukone', 'd.padukone@enterprise.com', '2026-02-25', 'Terminated', 4, 6, 9),
('Yash', 'Raj', 'y.raj@enterprise.com', '2026-06-05', 'Active', 4, 6, 9);

-- ==============================================================================
-- 2. EXPANDING THE PROJECTS PIPELINE (10 New Projects)
-- ==============================================================================

INSERT INTO Projects (project_id, project_name, start_date, end_date, project_status) VALUES
('p-uuid-004', 'LLM Fine-Tuning Pipeline', '2026-02-01', '2026-08-30', 'In Progress'),
('p-uuid-005', 'HR Intranet Portal v2.0', '2025-11-15', '2026-04-10', 'Completed'),
('p-uuid-006', 'Cloud Infrastructure Optimization', '2026-06-15', '2026-11-30', 'Planning'),
('p-uuid-007', 'Customer Churn Predictive Model', '2025-09-01', '2026-02-28', 'Completed'),
('p-uuid-008', 'React Native Mobile App', '2026-03-10', NULL, 'In Progress'),
('p-uuid-009', 'Legacy Database Decommissioning', '2026-07-01', '2026-10-15', 'Planning'),
('p-uuid-010', 'Automated Payroll System', '2025-12-01', '2026-05-20', 'Completed'),
('p-uuid-011', 'Real-time Analytics Engine', '2026-04-01', NULL, 'In Progress'),
('p-uuid-012', 'Employee Wellness Tracker', '2026-08-01', '2026-12-01', 'Planning'),
('p-uuid-013', 'Computer Vision QA Automation', '2026-01-15', '2026-09-15', 'On Hold');

-- ==============================================================================
-- 3. ASSIGNING RESOURCES TO PROJECTS (40 New Matrix Allocations)
-- ==============================================================================

INSERT INTO Employee_Projects (emp_id, project_id, hours_allocated, assignment_role) VALUES
-- LLM Fine-Tuning Pipeline (p-uuid-004) - Heavy AI involvement
(1, 'p-uuid-004', 30, 'Project Sponsor'),
(10, 'p-uuid-004', 160, 'Lead Machine Learning Engineer'),
(11, 'p-uuid-004', 120, 'Data Scientist'),
(12, 'p-uuid-004', 160, 'NLP Specialist'),
(14, 'p-uuid-004', 80, 'Model Validator'),

-- HR Intranet Portal v2.0 (p-uuid-005) - Frontend & HR involvement
(2, 'p-uuid-005', 40, 'UI/UX Lead'),
(16, 'p-uuid-005', 160, 'Frontend Developer'),
(17, 'p-uuid-005', 120, 'React Specialist'),
(9, 'p-uuid-005', 40, 'HR Stakeholder'),
(25, 'p-uuid-005', 60, 'Requirements Analyst'),

-- Cloud Infrastructure Optimization (p-uuid-006) - Backend focus
(8, 'p-uuid-006', 80, 'Architecture Lead'),
(21, 'p-uuid-006', 160, 'Cloud Database Admin'),
(22, 'p-uuid-006', 160, 'Systems Engineer'),
(26, 'p-uuid-006', 120, 'Performance Tuner'),

-- Customer Churn Predictive Model (p-uuid-007) - AI focus
(15, 'p-uuid-007', 160, 'Lead Modeler'),
(11, 'p-uuid-007', 80, 'Data Analyst'),
(24, 'p-uuid-007', 100, 'Backend Integration Developer'),

-- React Native Mobile App (p-uuid-008) - Frontend focus
(19, 'p-uuid-008', 160, 'Mobile Tech Lead'),
(20, 'p-uuid-008', 160, 'App Developer'),
(16, 'p-uuid-008', 80, 'UI Integrator'),

-- Legacy Database Decommissioning (p-uuid-009) - Backend focus
(8, 'p-uuid-009', 60, 'Oversight Director'),
(21, 'p-uuid-009', 160, 'Migration Specialist'),
(25, 'p-uuid-009', 160, 'Data Integrity Analyst'),
(27, 'p-uuid-009', 120, 'Backup Coordinator'),

-- Automated Payroll System (p-uuid-010) - Cross-functional
(9, 'p-uuid-010', 80, 'HR Compliance Officer'),
(26, 'p-uuid-010', 60, 'Payroll Specialist'),
(22, 'p-uuid-010', 160, 'Backend Logic Developer'),
(17, 'p-uuid-010', 120, 'Dashboard Developer'),

-- Real-time Analytics Engine (p-uuid-011) - Heavy tech crossover
(10, 'p-uuid-011', 120, 'Streaming Data Engineer'),
(14, 'p-uuid-011', 160, 'Analytics Modeler'),
(19, 'p-uuid-011', 100, 'Frontend Visualization'),
(24, 'p-uuid-011', 160, 'Database Optimizer'),

-- Employee Wellness Tracker (p-uuid-012) - HR & Frontend
(27, 'p-uuid-012', 120, 'Program Manager'),
(28, 'p-uuid-012', 40, 'Content Contributor'),
(20, 'p-uuid-012', 120, 'App Developer'),

-- Computer Vision QA Automation (p-uuid-013) - AI niche
(1, 'p-uuid-013', 20, 'Advisory Board'),
(12, 'p-uuid-013', 160, 'Computer Vision Engineer'),
(15, 'p-uuid-013', 100, 'Quality Assurance Lead'),
(25, 'p-uuid-013', 80, 'Backend Pipeline Setup');





