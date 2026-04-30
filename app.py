import urllib.parse
from datetime import datetime, timedelta
from flask import Flask, render_template, redirect, url_for, request, flash, jsonify
from flask_login import LoginManager, login_user, login_required, logout_user, current_user
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import func
from models import db, User, Driver, Vehicle, TrafficOfficer, Violation, Fine, Payment

# ============================================================
# APP CONFIGURATION
# ============================================================
app = Flask(__name__)
app.config['SECRET_KEY'] = 'smart-traffic-secret-2026'

# PythonAnywhere Free Tier Fallback to SQLite
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///smarttraffic.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# ============================================================
# INITIALIZATION
# ============================================================
def init_db():
    with app.app_context():
        db.create_all()
        if not User.query.filter_by(username='admin').first():
            admin = User(username='admin',
                         password_hash=generate_password_hash('admin123'),
                         role='admin')
            db.session.add(admin)
            db.session.commit()
        else:
            user = User.query.filter_by(username='admin').first()
            if not check_password_hash(user.password_hash, 'admin123'):
                user.password_hash = generate_password_hash('admin123')
                db.session.commit()

# ============================================================
# AUTH ROUTES
# ============================================================
@app.route('/')
def index():
    return redirect(url_for('dashboard')) if current_user.is_authenticated else redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        user = User.query.filter_by(username=request.form.get('username')).first()
        if user and check_password_hash(user.password_hash, request.form.get('password')):
            login_user(user)
            return redirect(url_for('dashboard'))
        flash('Invalid username or password.', 'danger')
    return render_template('login.html')

@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if User.query.filter_by(username=username).first():
            flash('Username already exists. Please choose a different one.', 'danger')
            return redirect(url_for('register'))
            
        new_user = User(
            username=username,
            password_hash=generate_password_hash(password),
            role='user'
        )
        db.session.add(new_user)
        db.session.commit()
        flash('Account created successfully! You can now log in.', 'success')
        return redirect(url_for('login'))
        
    return render_template('register.html')

# ============================================================
# DASHBOARD
# ============================================================
@app.route('/dashboard')
@login_required
def dashboard():
    total_drivers = Driver.query.count()
    total_vehicles = Vehicle.query.count()
    total_violations = Violation.query.count()
    total_revenue = db.session.query(func.coalesce(func.sum(Payment.amount_paid), 0)).scalar()
    unpaid_count = Fine.query.filter_by(status='Unpaid').count()

    # AI Prediction
    recent_count = Violation.query.filter(Violation.date_time >= datetime.utcnow() - timedelta(days=7)).count()
    prev_count = Violation.query.filter(
        Violation.date_time >= datetime.utcnow() - timedelta(days=14),
        Violation.date_time < datetime.utcnow() - timedelta(days=7)
    ).count()

    if recent_count > prev_count * 1.5 and recent_count > 3:
        risk = 'HIGH'
        prediction = 'Violation rate surging. Deploy additional officers to hotspot areas immediately.'
    elif recent_count > prev_count:
        risk = 'MODERATE'
        prediction = 'Slight increase in violations detected. Monitor key intersections.'
    else:
        risk = 'LOW'
        prediction = 'Traffic compliance is stable. Continue routine patrols.'

    recent_violations = Violation.query.order_by(Violation.date_time.desc()).limit(5).all()
    return render_template('dashboard.html',
                           total_drivers=total_drivers, total_vehicles=total_vehicles,
                           total_violations=total_violations, total_revenue=float(total_revenue),
                           unpaid_count=unpaid_count, risk=risk, prediction=prediction,
                           recent_violations=recent_violations)

@app.route('/api/chart-data')
@login_required
def chart_data():
    today = datetime.utcnow()
    trend_labels, trend_data = [], []
    for i in range(29, -1, -1):
        day = today - timedelta(days=i)
        count = Violation.query.filter(func.date(Violation.date_time) == day.date()).count()
        trend_labels.append(day.strftime('%d %b'))
        trend_data.append(count)

    type_rows = db.session.query(Violation.violation_type, func.count(Violation.violation_id)).group_by(Violation.violation_type).all()
    officer_rows = db.session.query(TrafficOfficer.name, func.count(Violation.violation_id)).join(Violation).group_by(TrafficOfficer.name).order_by(func.count(Violation.violation_id).desc()).limit(5).all()

    return jsonify({
        'trend_labels': trend_labels, 'trend_data': trend_data,
        'type_labels': [r[0] for r in type_rows], 'type_data': [r[1] for r in type_rows],
        'officer_labels': [r[0] for r in officer_rows], 'officer_data': [r[1] for r in officer_rows],
    })

# ============================================================
# DRIVERS CRUD
# ============================================================
@app.route('/drivers', methods=['GET', 'POST'])
@login_required
def drivers():
    if request.method == 'POST':
        d = Driver(name=request.form['name'], license_number=request.form['license_number'],
                   contact=request.form.get('contact'), email=request.form.get('email'),
                   address=request.form.get('address'))
        db.session.add(d)
        db.session.commit()
        flash('Driver registered successfully!', 'success')
        return redirect(url_for('drivers'))
    search = request.args.get('search', '')
    query = Driver.query
    if search:
        query = query.filter(Driver.name.ilike(f'%{search}%') | Driver.license_number.ilike(f'%{search}%'))
    all_drivers = query.order_by(Driver.created_at.desc()).all()
    return render_template('drivers.html', drivers=all_drivers, search=search)

@app.route('/drivers/<int:id>/delete')
@login_required
def delete_driver(id):
    d = Driver.query.get_or_404(id)
    db.session.delete(d)
    db.session.commit()
    flash('Driver deleted.', 'success')
    return redirect(url_for('drivers'))

# ============================================================
# VEHICLES CRUD
# ============================================================
@app.route('/vehicles', methods=['GET', 'POST'])
@login_required
def vehicles():
    if request.method == 'POST':
        v = Vehicle(model=request.form['model'], make=request.form['make'],
                    color=request.form.get('color'), license_plate=request.form['license_plate'],
                    driver_id=request.form['driver_id'])
        db.session.add(v)
        db.session.commit()
        flash('Vehicle registered successfully!', 'success')
        return redirect(url_for('vehicles'))
    all_vehicles = Vehicle.query.order_by(Vehicle.created_at.desc()).all()
    all_drivers = Driver.query.all()
    return render_template('vehicles.html', vehicles=all_vehicles, drivers=all_drivers)

@app.route('/vehicles/<int:id>/delete')
@login_required
def delete_vehicle(id):
    v = Vehicle.query.get_or_404(id)
    db.session.delete(v)
    db.session.commit()
    flash('Vehicle deleted.', 'success')
    return redirect(url_for('vehicles'))

# ============================================================
# OFFICERS CRUD
# ============================================================
@app.route('/officers', methods=['GET', 'POST'])
@login_required
def officers():
    if request.method == 'POST':
        o = TrafficOfficer(name=request.form['name'], badge_number=request.form['badge_number'],
                           department=request.form.get('department'), contact=request.form.get('contact'))
        db.session.add(o)
        db.session.commit()
        flash('Officer registered successfully!', 'success')
        return redirect(url_for('officers'))
    all_officers = TrafficOfficer.query.order_by(TrafficOfficer.created_at.desc()).all()
    return render_template('officers.html', officers=all_officers)

@app.route('/officers/<int:id>/delete')
@login_required
def delete_officer(id):
    o = TrafficOfficer.query.get_or_404(id)
    db.session.delete(o)
    db.session.commit()
    flash('Officer deleted.', 'success')
    return redirect(url_for('officers'))

# ============================================================
# VIOLATIONS & FINES
# ============================================================
FINE_AMOUNTS = {'Speeding': 2000, 'Red Light': 5000, 'No Helmet': 1500,
                'Illegal Parking': 1000, 'DUI': 10000, 'Wrong Way': 5000, 'Using Phone': 2000}

@app.route('/violations', methods=['GET', 'POST'])
@login_required
def violations():
    if request.method == 'POST':
        vtype = request.form['violation_type']
        v = Violation(violation_type=vtype, description=request.form.get('description'),
                      location=request.form.get('location'),
                      vehicle_id=request.form['vehicle_id'], officer_id=request.form['officer_id'])
        db.session.add(v)
        db.session.flush()
        fine_amt = float(request.form.get('fine_amount') or FINE_AMOUNTS.get(vtype, 1000))
        f = Fine(amount=fine_amt, violation_id=v.violation_id,
                 due_date=datetime.utcnow().date() + timedelta(days=30))
        db.session.add(f)
        db.session.commit()
        flash('Violation & fine recorded!', 'success')
        return redirect(url_for('violations'))
    all_violations = Violation.query.order_by(Violation.date_time.desc()).all()
    return render_template('violations.html', violations=all_violations,
                           vehicles=Vehicle.query.all(), officers=TrafficOfficer.query.all(),
                           fine_amounts=FINE_AMOUNTS)

# ============================================================
# PAYMENTS (Demonstrates ACID Transactions)
# ============================================================
@app.route('/payments', methods=['GET', 'POST'])
@login_required
def payments():
    if request.method == 'POST':
        fine_id = request.form['fine_id']
        method = request.form['payment_method']
        try:
            fine = Fine.query.get(fine_id)
            if fine and fine.status != 'Paid':
                txn_id = f"TXN{datetime.now().strftime('%Y%m%d%H%M%S')}{fine.fine_id}"
                p = Payment(amount_paid=fine.amount, payment_method=method,
                            transaction_id=txn_id, fine_id=fine.fine_id)
                fine.status = 'Paid'
                db.session.add(p)
                db.session.commit()
                flash(f'Payment of ₹{fine.amount} processed! TXN: {txn_id}', 'success')
            else:
                db.session.rollback()
                flash('Fine already paid or not found.', 'danger')
        except Exception as e:
            db.session.rollback()
            flash(f'Transaction failed: {str(e)}', 'danger')
        return redirect(url_for('payments'))

    unpaid = Fine.query.filter(Fine.status != 'Paid').all()
    all_payments = Payment.query.order_by(Payment.date_paid.desc()).all()
    return render_template('payments.html', unpaid_fines=unpaid, payments=all_payments)

# ============================================================
# RUN
# ============================================================
if __name__ == '__main__':
    init_db()
    app.run(debug=True, port=5000)
