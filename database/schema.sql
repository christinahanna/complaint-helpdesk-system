-- Create Database
CREATE DATABASE IF NOT EXISTS complaint_helpdesk;
USE complaint_helpdesk;

-- Users Table
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('complainant', 'support_staff', 'admin') DEFAULT 'complainant',
  phone VARCHAR(20),
  department VARCHAR(100),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX (email),
  INDEX (role)
);

-- Complaint Categories Table
CREATE TABLE categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (name)
);

-- Complaints Table
CREATE TABLE complaints (
  id INT AUTO_INCREMENT PRIMARY KEY,
  complaint_id VARCHAR(50) UNIQUE NOT NULL,
  user_id INT NOT NULL,
  category_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description LONGTEXT NOT NULL,
  priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
  status ENUM('open', 'in_progress', 'resolved', 'closed', 'reopened') DEFAULT 'open',
  assigned_to INT,
  attachment_path VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
  FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
  INDEX (status),
  INDEX (priority),
  INDEX (created_at),
  INDEX (complaint_id),
  FULLTEXT INDEX (title, description)
);

-- Responses/Updates Table
CREATE TABLE responses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  complaint_id INT NOT NULL,
  responder_id INT NOT NULL,
  response_text LONGTEXT NOT NULL,
  attachment_path VARCHAR(255),
  is_internal BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE,
  FOREIGN KEY (responder_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX (complaint_id),
  INDEX (created_at)
);

-- Audit Log Table (for tracking all changes)
CREATE TABLE audit_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  action VARCHAR(255) NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_id INT NOT NULL,
  old_value JSON,
  new_value JSON,
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX (entity_type),
  INDEX (created_at)
);

-- Insert Sample Categories
INSERT INTO categories (name, description) VALUES
('Technical Issue', 'Issues related to software or hardware'),
('Billing', 'Issues related to billing and payments'),
('Service Quality', 'Complaints about service quality'),
('Account', 'Issues related to account management'),
('Other', 'Other complaints');

-- Create views for reporting
CREATE VIEW complaint_statistics AS
SELECT 
  DATE(created_at) as date,
  status,
  priority,
  COUNT(*) as count
FROM complaints
GROUP BY DATE(created_at), status, priority;

CREATE VIEW user_complaint_count AS
SELECT 
  u.id,
  u.name,
  u.email,
  COUNT(c.id) as total_complaints,
  SUM(CASE WHEN c.status = 'resolved' THEN 1 ELSE 0 END) as resolved_complaints,
  SUM(CASE WHEN c.status = 'open' THEN 1 ELSE 0 END) as open_complaints
FROM users u
LEFT JOIN complaints c ON u.id = c.user_id
WHERE u.role = 'complainant'
GROUP BY u.id, u.name, u.email;
