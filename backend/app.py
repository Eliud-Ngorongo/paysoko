from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
from datetime import datetime
import pytz
from timezonefinder import TimezoneFinder
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderUnavailable

app = Flask(__name__)
CORS(app)

client = MongoClient('mongodb://mongodb:27017/')
db = client.timezones

# Initialize the geocoder and timezone finder
geolocator = Nominatim(user_agent="time_checker_app")
tf = TimezoneFinder()

def get_city_name(location):
    """Extract just the city name from the location address"""
    if location and location.raw.get('address'):
        address = location.raw['address']
        # Try to get the city name from different possible fields
        city = (address.get('city') or 
                address.get('town') or 
                address.get('village') or 
                address.get('suburb') or 
                address.get('municipality'))
        return city
    return None

def get_timezone_for_location(city_name):
    try:
        # Append ", city" to the search to prioritize city results
        location = geolocator.geocode(f"{city_name}, city", exactly_one=True)
        if location is None:
            return None
        
        # Extract just the city name
        city = get_city_name(location) or city_name
        
        # Find the timezone for these coordinates
        timezone_str = tf.timezone_at(lat=location.latitude, lng=location.longitude)
        return {
            'timezone': timezone_str,
            'name': city,
            'lat': location.latitude,
            'lng': location.longitude
        }
    except (GeocoderTimedOut, GeocoderUnavailable):
        return None

@app.route('/api/time', methods=['GET'])
def get_time():
    city = request.args.get('city', '').strip()
    if not city:
        return jsonify({'error': 'Please provide a city name'}), 400
    
    # Get location and timezone information
    location_info = get_timezone_for_location(city)
    
    if not location_info:
        return jsonify({'error': f'Could not find city: {city}'}), 400
    
    try:
        timezone = pytz.timezone(location_info['timezone'])
        current_time = datetime.now(timezone)
        
        # Store query in MongoDB
        db.queries.insert_one({
            'city': location_info['name'],
            'timezone': location_info['timezone'],
            'timestamp': datetime.utcnow(),
            'result': current_time.strftime('%Y-%m-%d %H:%M:%S %Z')
        })
        
        return jsonify({
            'city': location_info['name'],
            'time': current_time.strftime('%I:%M %p'),
            'timezone': location_info['timezone'],
            'full_time': current_time.strftime('%Y-%m-%d %H:%M:%S %Z')
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)