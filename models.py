from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from datetime import datetime

db = SQLAlchemy()

class User(UserMixin, db.Model):
    __tablename__ = 'users'
    user_id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=True)
    phone = db.Column(db.String(20), unique=True, nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(10), default='user')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def get_id(self):
        return str(self.user_id)

class Driver(db.Model):
    __tablename__ = 'drivers'
    driver_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    license_number = db.Column(db.String(20), unique=True, nullable=False)
    contact = db.Column(db.String(15))
    email = db.Column(db.String(100))
    address = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    vehicles = db.relationship('Vehicle', backref='driver', lazy=True, cascade='all, delete-orphan')

class Vehicle(db.Model):
    __tablename__ = 'vehicles'
    vehicle_id = db.Column(db.Integer, primary_key=True)
    model = db.Column(db.String(50), nullable=False)
    make = db.Column(db.String(50), nullable=False)
    color = db.Column(db.String(30))
    license_plate = db.Column(db.String(20), unique=True, nullable=False)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.driver_id', ondelete='CASCADE'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    violations = db.relationship('Violation', backref='vehicle', lazy=True, cascade='all, delete-orphan')

class TrafficOfficer(db.Model):
    __tablename__ = 'traffic_officers'
    officer_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    badge_number = db.Column(db.String(20), unique=True, nullable=False)
    department = db.Column(db.String(50))
    contact = db.Column(db.String(15))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    violations_issued = db.relationship('Violation', backref='officer', lazy=True)

class Violation(db.Model):
    __tablename__ = 'violations'
    violation_id = db.Column(db.Integer, primary_key=True)
    violation_type = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    location = db.Column(db.String(200))
    date_time = db.Column(db.DateTime, default=datetime.utcnow)
    vehicle_id = db.Column(db.Integer, db.ForeignKey('vehicles.vehicle_id', ondelete='CASCADE'), nullable=False)
    officer_id = db.Column(db.Integer, db.ForeignKey('traffic_officers.officer_id', ondelete='CASCADE'), nullable=False)
    fine = db.relationship('Fine', backref='violation', uselist=False, lazy=True, cascade='all, delete-orphan')

class Fine(db.Model):
    __tablename__ = 'fines'
    fine_id = db.Column(db.Integer, primary_key=True)
    amount = db.Column(db.Numeric(10, 2), nullable=False)
    status = db.Column(db.String(20), default='Unpaid')
    due_date = db.Column(db.Date)
    violation_id = db.Column(db.Integer, db.ForeignKey('violations.violation_id', ondelete='CASCADE'), nullable=False, unique=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    payment = db.relationship('Payment', backref='fine', uselist=False, lazy=True, cascade='all, delete-orphan')

class Payment(db.Model):
    __tablename__ = 'payments'
    payment_id = db.Column(db.Integer, primary_key=True)
    amount_paid = db.Column(db.Numeric(10, 2), nullable=False)
    payment_method = db.Column(db.String(10), default='Cash')
    transaction_id = db.Column(db.String(50), unique=True)
    date_paid = db.Column(db.DateTime, default=datetime.utcnow)
    fine_id = db.Column(db.Integer, db.ForeignKey('fines.fine_id', ondelete='CASCADE'), nullable=False)
