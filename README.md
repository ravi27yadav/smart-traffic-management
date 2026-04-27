# 🚦 Smart Traffic Violation and Fine Management System

A modern, full-stack web application for managing traffic violations, drivers, vehicles, fines, and payments — built with **Flask** and **MySQL**.

> **DBMS Project** — Demonstrates ER Modeling, Relational Schema Design, Complex SQL Queries, Normalization, Views, Triggers, Stored Procedures, ACID Transactions, and Full-Stack Application Development.

---

## ✨ Features

- 📊 **Interactive Dashboard** with real-time charts (Chart.js) and AI predictive analysis
- 👤 **Driver Management** — Register, search, and manage driver records
- 🚗 **Vehicle Registry** — Link vehicles to registered drivers
- 🛡️ **Officer Management** — Track traffic enforcement officers
- ⚠️ **Violation Tracking** — Record violations with auto-calculated fines
- 💳 **Payment Processing** — ACID-compliant transaction processing
- 🔐 **Authentication** — Secure login with hashed passwords
- 🌙 **Premium Dark UI** — Glassmorphic design with animations

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Flask (Python) |
| Database | MySQL 8.0 |
| ORM | SQLAlchemy |
| Frontend | HTML5, CSS3, JavaScript |
| Charts | Chart.js |
| Auth | Flask-Login + Werkzeug |

---

## 🚀 Setup Instructions

### Prerequisites
- Python 3.10+
- MySQL 8.0+

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/smart-traffic-management.git
cd smart-traffic-management
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Setup MySQL Database
```bash
mysql -u root -p
```
```sql
CREATE DATABASE smarttrafficdb;
exit;
```
Then run the setup script:
```bash
mysql -u root -p smarttrafficdb < database.sql
```

### 4. Configure Database Connection
Edit `app.py` and update the MySQL password on line 15 if needed.

### 5. Run the Application
```bash
python app.py
```

### 6. Open in Browser
Navigate to: **http://localhost:5000**

**Login:** `admin` / `admin123`

---

## 📁 Project Structure

```
smart-traffic-management/
├── app.py              # Flask application & routes
├── models.py           # SQLAlchemy ORM models
├── database.sql        # MySQL schema, views, triggers, seed data
├── requirements.txt    # Python dependencies
├── static/
│   └── css/
│       └── style.css   # Premium dark-mode stylesheet
└── templates/
    ├── base.html       # Master layout with sidebar
    ├── login.html      # Authentication page
    ├── dashboard.html  # Dashboard with charts
    ├── drivers.html    # Driver management
    ├── vehicles.html   # Vehicle registry
    ├── officers.html   # Officer management
    ├── violations.html # Violation & fine recording
    └── payments.html   # Payment processing
```

---

## 📄 License

This project is for educational purposes as part of a DBMS course project.
