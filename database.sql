-- ============================================================
-- Smart Traffic Violation and Fine Management System
-- Complete Database Setup Script
-- Database: smarttrafficdb
-- ============================================================

USE smarttrafficdb;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS fines;
DROP TABLE IF EXISTS violations;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS traffic_officers;
DROP TABLE IF EXISTS drivers;
DROP TABLE IF EXISTS users;

-- ============================================================
-- TABLE CREATION (Chapter 2: Relational Schema)
-- ============================================================

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'officer') DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE drivers (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    license_number VARCHAR(20) UNIQUE NOT NULL,
    contact VARCHAR(15),
    email VARCHAR(100),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(50) NOT NULL,
    make VARCHAR(50) NOT NULL,
    color VARCHAR(30),
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    driver_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE CASCADE
);

CREATE TABLE traffic_officers (
    officer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    badge_number VARCHAR(20) UNIQUE NOT NULL,
    department VARCHAR(50),
    contact VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE violations (
    violation_id INT AUTO_INCREMENT PRIMARY KEY,
    violation_type VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(200),
    date_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    vehicle_id INT NOT NULL,
    officer_id INT NOT NULL,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    FOREIGN KEY (officer_id) REFERENCES traffic_officers(officer_id) ON DELETE CASCADE
);

CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(10, 2) NOT NULL,
    status ENUM('Unpaid', 'Paid', 'Overdue') DEFAULT 'Unpaid',
    due_date DATE,
    violation_id INT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (violation_id) REFERENCES violations(violation_id) ON DELETE CASCADE
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    amount_paid DECIMAL(10, 2) NOT NULL,
    payment_method ENUM('Cash', 'Card', 'Online') DEFAULT 'Cash',
    transaction_id VARCHAR(50) UNIQUE,
    date_paid TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fine_id INT NOT NULL,
    FOREIGN KEY (fine_id) REFERENCES fines(fine_id) ON DELETE CASCADE
);

-- ============================================================
-- INDEXES for Performance
-- ============================================================
CREATE INDEX idx_driver_license ON drivers(license_number);
CREATE INDEX idx_vehicle_plate ON vehicles(license_plate);
CREATE INDEX idx_violation_date ON violations(date_time);
CREATE INDEX idx_fine_status ON fines(status);

-- ============================================================
-- VIEWS (Advanced SQL Features)
-- ============================================================

CREATE OR REPLACE VIEW violation_summary_view AS
SELECT 
    v.violation_id, v.violation_type, v.location, v.date_time,
    d.name AS driver_name, d.license_number,
    veh.license_plate, veh.model AS vehicle_model,
    o.name AS officer_name, o.badge_number,
    f.amount AS fine_amount, f.status AS fine_status
FROM violations v
JOIN vehicles veh ON v.vehicle_id = veh.vehicle_id
JOIN drivers d ON veh.driver_id = d.driver_id
JOIN traffic_officers o ON v.officer_id = o.officer_id
LEFT JOIN fines f ON v.violation_id = f.violation_id;

CREATE OR REPLACE VIEW unpaid_fines_view AS
SELECT 
    f.fine_id, f.amount, f.due_date,
    d.name AS driver_name, d.contact,
    veh.license_plate, v.violation_type
FROM fines f
JOIN violations v ON f.violation_id = v.violation_id
JOIN vehicles veh ON v.vehicle_id = veh.vehicle_id
JOIN drivers d ON veh.driver_id = d.driver_id
WHERE f.status = 'Unpaid';

-- ============================================================
-- TRIGGER: Auto-update fine status on payment
-- ============================================================

DROP TRIGGER IF EXISTS after_payment_insert;
DELIMITER //
CREATE TRIGGER after_payment_insert
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    UPDATE fines SET status = 'Paid' WHERE fine_id = NEW.fine_id;
END //
DELIMITER ;

-- ============================================================
-- STORED PROCEDURE: Process Payment (Demonstrates Transactions)
-- ============================================================

DROP PROCEDURE IF EXISTS process_payment;
DELIMITER //
CREATE PROCEDURE process_payment(
    IN p_fine_id INT,
    IN p_method ENUM('Cash', 'Card', 'Online'),
    IN p_txn_id VARCHAR(50)
)
BEGIN
    DECLARE v_amount DECIMAL(10,2);
    DECLARE v_status VARCHAR(20);
    
    START TRANSACTION;
    
    SELECT amount, status INTO v_amount, v_status 
    FROM fines WHERE fine_id = p_fine_id FOR UPDATE;
    
    IF v_status = 'Paid' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fine already paid';
    END IF;
    
    INSERT INTO payments (amount_paid, payment_method, transaction_id, fine_id)
    VALUES (v_amount, p_method, p_txn_id, p_fine_id);
    
    COMMIT;
END //
DELIMITER ;

-- ============================================================
-- SEED DATA
-- ============================================================

-- Admin user (password: admin123)
INSERT INTO users (username, password_hash, role) VALUES
('admin', 'scrypt:32768:8:1$salt$hash_placeholder', 'admin');

-- Drivers
INSERT INTO drivers (name, license_number, contact, email, address) VALUES
('Ravi Kumar', 'DL0120230001', '9876543210', 'ravi@email.com', 'MG Road, Delhi'),
('Priya Sharma', 'MH0420230002', '9876543211', 'priya@email.com', 'Andheri, Mumbai'),
('Amit Patel', 'GJ0120230003', '9876543212', 'amit@email.com', 'SG Highway, Ahmedabad'),
('Sneha Reddy', 'KA0120230004', '9876543213', 'sneha@email.com', 'MG Road, Bangalore'),
('Vikram Singh', 'UP3220230005', '9876543214', 'vikram@email.com', 'Hazratganj, Lucknow'),
('Neha Gupta', 'RJ1420230006', '9876543215', 'neha@email.com', 'MI Road, Jaipur'),
('Arjun Deshmukh', 'MH0120230007', '9876543216', 'arjun@email.com', 'FC Road, Pune'),
('Kavya Nair', 'KL0120230008', '9876543217', 'kavya@email.com', 'MG Road, Kochi');

-- Vehicles
INSERT INTO vehicles (model, make, color, license_plate, driver_id) VALUES
('Swift', 'Maruti', 'White', 'MH 01 AB 1234', 1),
('Creta', 'Hyundai', 'Black', 'DL 02 CD 5678', 2),
('Nexon', 'Tata', 'Blue', 'GJ 01 EF 9012', 3),
('City', 'Honda', 'Silver', 'KA 01 GH 3456', 4),
('XUV700', 'Mahindra', 'Red', 'UP 32 IJ 7890', 5),
('Seltos', 'Kia', 'White', 'RJ 14 KL 2345', 6),
('Fortuner', 'Toyota', 'Black', 'MH 01 MN 6789', 7),
('Baleno', 'Maruti', 'Grey', 'KL 01 OP 0123', 8),
('Venue', 'Hyundai', 'Orange', 'DL 01 QR 4567', 1),
('Harrier', 'Tata', 'White', 'MH 04 ST 8901', 2);

-- Traffic Officers
INSERT INTO traffic_officers (name, badge_number, department, contact) VALUES
('Inspector Rajesh', 'BADGE001', 'Traffic Division A', '9988776601'),
('Sub-Inspector Meera', 'BADGE002', 'Traffic Division B', '9988776602'),
('Constable Suresh', 'BADGE003', 'Traffic Division A', '9988776603'),
('Inspector Divya', 'BADGE004', 'Traffic Division C', '9988776604'),
('Sub-Inspector Karan', 'BADGE005', 'Traffic Division B', '9988776605');

-- Violations (spread over last 30 days)
INSERT INTO violations (violation_type, description, location, date_time, vehicle_id, officer_id) VALUES
('Speeding', 'Exceeding limit by 30km/h', 'Ring Road, Delhi', DATE_SUB(NOW(), INTERVAL 1 DAY), 1, 1),
('Red Light', 'Ran red light at signal', 'MG Road, Bangalore', DATE_SUB(NOW(), INTERVAL 1 DAY), 4, 4),
('No Helmet', 'Riding without helmet', 'FC Road, Pune', DATE_SUB(NOW(), INTERVAL 2 DAY), 7, 2),
('Speeding', 'Exceeding limit by 20km/h', 'SG Highway, Ahmedabad', DATE_SUB(NOW(), INTERVAL 3 DAY), 3, 3),
('Illegal Parking', 'Parked in no-parking zone', 'Connaught Place, Delhi', DATE_SUB(NOW(), INTERVAL 3 DAY), 2, 1),
('DUI', 'Driving under influence', 'Marine Drive, Mumbai', DATE_SUB(NOW(), INTERVAL 4 DAY), 10, 2),
('Using Phone', 'Using phone while driving', 'Outer Ring Road, Bangalore', DATE_SUB(NOW(), INTERVAL 5 DAY), 5, 4),
('Speeding', 'Exceeding limit by 40km/h', 'NH48, Pune', DATE_SUB(NOW(), INTERVAL 6 DAY), 7, 3),
('Red Light', 'Ran red light', 'MI Road, Jaipur', DATE_SUB(NOW(), INTERVAL 7 DAY), 6, 5),
('No Helmet', 'Riding without helmet', 'MG Road, Kochi', DATE_SUB(NOW(), INTERVAL 8 DAY), 8, 4),
('Speeding', 'Exceeding limit by 25km/h', 'Yamuna Expressway', DATE_SUB(NOW(), INTERVAL 10 DAY), 9, 1),
('Illegal Parking', 'Double parking', 'Brigade Road, Bangalore', DATE_SUB(NOW(), INTERVAL 12 DAY), 4, 4),
('Wrong Way', 'Driving on wrong side', 'Ring Road, Lucknow', DATE_SUB(NOW(), INTERVAL 14 DAY), 5, 5),
('Red Light', 'Ran red light at crossing', 'Hinjewadi, Pune', DATE_SUB(NOW(), INTERVAL 16 DAY), 7, 2),
('Speeding', 'Exceeding limit by 35km/h', 'Mumbai-Pune Expressway', DATE_SUB(NOW(), INTERVAL 18 DAY), 10, 3),
('No Helmet', 'Pillion without helmet', 'Koramangala, Bangalore', DATE_SUB(NOW(), INTERVAL 20 DAY), 4, 4),
('DUI', 'Failed breathalyzer test', 'Jubilee Hills, Hyderabad', DATE_SUB(NOW(), INTERVAL 22 DAY), 1, 1),
('Speeding', 'Exceeding limit by 50km/h', 'Delhi-Jaipur Highway', DATE_SUB(NOW(), INTERVAL 25 DAY), 6, 5),
('Illegal Parking', 'Blocking emergency lane', 'AIIMS, Delhi', DATE_SUB(NOW(), INTERVAL 27 DAY), 2, 1),
('Red Light', 'Ran red light', 'Silk Board, Bangalore', DATE_SUB(NOW(), INTERVAL 29 DAY), 4, 4);

-- Fines
INSERT INTO fines (amount, status, due_date, violation_id) VALUES
(2000.00, 'Unpaid', DATE_ADD(NOW(), INTERVAL 15 DAY), 1),
(5000.00, 'Unpaid', DATE_ADD(NOW(), INTERVAL 14 DAY), 2),
(1500.00, 'Unpaid', DATE_ADD(NOW(), INTERVAL 13 DAY), 3),
(2000.00, 'Paid', DATE_ADD(NOW(), INTERVAL 12 DAY), 4),
(1000.00, 'Unpaid', DATE_ADD(NOW(), INTERVAL 12 DAY), 5),
(10000.00, 'Paid', DATE_ADD(NOW(), INTERVAL 11 DAY), 6),
(2000.00, 'Paid', DATE_ADD(NOW(), INTERVAL 10 DAY), 7),
(2000.00, 'Unpaid', DATE_ADD(NOW(), INTERVAL 9 DAY), 8),
(5000.00, 'Paid', DATE_ADD(NOW(), INTERVAL 8 DAY), 9),
(1500.00, 'Unpaid', DATE_ADD(NOW(), INTERVAL 7 DAY), 10),
(2000.00, 'Paid', DATE_ADD(NOW(), INTERVAL 5 DAY), 11),
(1000.00, 'Paid', DATE_ADD(NOW(), INTERVAL 3 DAY), 12),
(5000.00, 'Unpaid', DATE_ADD(NOW(), INTERVAL 1 DAY), 13),
(5000.00, 'Paid', DATE_SUB(NOW(), INTERVAL 1 DAY), 14),
(2000.00, 'Paid', DATE_SUB(NOW(), INTERVAL 3 DAY), 15),
(1500.00, 'Unpaid', DATE_SUB(NOW(), INTERVAL 5 DAY), 16),
(10000.00, 'Paid', DATE_SUB(NOW(), INTERVAL 7 DAY), 17),
(2000.00, 'Unpaid', DATE_SUB(NOW(), INTERVAL 10 DAY), 18),
(1000.00, 'Paid', DATE_SUB(NOW(), INTERVAL 12 DAY), 19),
(5000.00, 'Paid', DATE_SUB(NOW(), INTERVAL 14 DAY), 20);

-- Payments (for fines marked as 'Paid')
INSERT INTO payments (amount_paid, payment_method, transaction_id, fine_id) VALUES
(2000.00, 'Online', 'TXN20260401001', 4),
(10000.00, 'Card', 'TXN20260402001', 6),
(2000.00, 'Cash', 'TXN20260403001', 7),
(5000.00, 'Online', 'TXN20260404001', 9),
(2000.00, 'Card', 'TXN20260405001', 11),
(1000.00, 'Cash', 'TXN20260406001', 12),
(5000.00, 'Online', 'TXN20260407001', 14),
(2000.00, 'Card', 'TXN20260408001', 15),
(10000.00, 'Online', 'TXN20260409001', 17),
(1000.00, 'Cash', 'TXN20260410001', 19),
(5000.00, 'Online', 'TXN20260411001', 20);

SELECT 'Database setup complete!' AS Status;
