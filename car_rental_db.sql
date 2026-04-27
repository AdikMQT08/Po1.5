CREATE SCHEMA IF NOT EXISTS car_rental;

SET search_path TO car_rental;

CREATE TABLE IF NOT EXISTS rental_location (
    location_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(20) UNIQUE
);

CREATE TABLE IF NOT EXISTS customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    license_number VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS service (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE IF NOT EXISTS vehicle (
    vehicle_id SERIAL PRIMARY KEY,
    location_id INT REFERENCES rental_location(location_id) ON DELETE SET NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT CHECK (year > 1900),
    vin_code VARCHAR(17) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'available'
        CHECK (status IN ('available','rented','maintenance')),
    daily_rate DECIMAL(10,2) NOT NULL CHECK (daily_rate >= 0)
);

CREATE TABLE IF NOT EXISTS staff (
    staff_id SERIAL PRIMARY KEY,
    location_id INT REFERENCES rental_location(location_id),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS condition_report (
    report_id SERIAL PRIMARY KEY,
    vehicle_id INT REFERENCES vehicle(vehicle_id) ON DELETE CASCADE,
    report_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        CHECK (report_date > '2026-01-01'),
    condition_status VARCHAR(50) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS maintenance (
    maintenance_id SERIAL PRIMARY KEY,
    vehicle_id INT REFERENCES vehicle(vehicle_id) ON DELETE CASCADE,
    maintenance_type VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL CHECK (start_date > '2026-01-01'),
    end_date DATE,
    cost DECIMAL(10,2) CHECK (cost >= 0)
);

CREATE TABLE IF NOT EXISTS reservation (
    reservation_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customer(customer_id),
    vehicle_id INT REFERENCES vehicle(vehicle_id),
    staff_id INT REFERENCES staff(staff_id),
    start_date TIMESTAMP NOT NULL CHECK (start_date > '2026-01-01'),
    end_date TIMESTAMP NOT NULL CHECK (end_date > start_date),
    total_days INT GENERATED ALWAYS AS (
        EXTRACT(DAY FROM (end_date - start_date))
    ) STORED,
    total_price DECIMAL(10,2) CHECK (total_price >= 0),
    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN ('pending','confirmed','cancelled'))
);

CREATE TABLE IF NOT EXISTS payment (
    payment_id SERIAL PRIMARY KEY,
    reservation_id INT REFERENCES reservation(reservation_id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (payment_date > '2026-01-01'),
    payment_method VARCHAR(50) NOT NULL
        CHECK (payment_method IN ('Cash','Credit Card','Online'))
);

CREATE TABLE IF NOT EXISTS return_log (
    return_id SERIAL PRIMARY KEY,
    reservation_id INT REFERENCES reservation(reservation_id),
    return_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP CHECK (return_date > '2026-01-01'),
    fuel_level VARCHAR(20) DEFAULT 'Full'
        CHECK (fuel_level IN ('Empty','Half','Full')),
    notes TEXT
);

CREATE TABLE IF NOT EXISTS reservation_service (
    reservation_id INT REFERENCES reservation(reservation_id) ON DELETE CASCADE,
    service_id INT REFERENCES service(service_id) ON DELETE CASCADE,
    quantity INT DEFAULT 1 CHECK (quantity > 0),
    PRIMARY KEY (reservation_id, service_id)
);

INSERT INTO rental_location (name, address, phone)
SELECT 'Main Airport Terminal', '123 Sky Way, Atyrau', '+77122001122'
WHERE NOT EXISTS (SELECT 1 FROM rental_location WHERE phone = '+77122001122');

INSERT INTO customer (first_name, last_name, phone, email, license_number)
SELECT 'Ivan','Ivanov','+77011112233','ivan@example.kz','AB123456'
WHERE NOT EXISTS (SELECT 1 FROM customer WHERE phone = '+77011112233');

INSERT INTO service (service_name, price)
SELECT 'GPS Navigation', 15.00
WHERE NOT EXISTS (SELECT 1 FROM service WHERE service_name = 'GPS Navigation');
