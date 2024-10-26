// frontend/src/App.jsx
import React, { useState } from 'react';

export default function App() {
  const [city, setCity] = useState('');
  const [timeData, setTimeData] = useState(null);
  const [recentSearches, setRecentSearches] = useState([]);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await fetch(`${process.env.REACT_APP_API_URL}/api/time?city=${city}`);
      const data = await response.json();
      
      if (response.ok) {
        setTimeData(data);
        setError('');
        // Add to recent searches
        setRecentSearches(prev => [
          { city: data.city, time: data.time },
          ...prev.slice(0, 4)
        ]);
      } else {
        setError(data.error || 'City not found');
        setTimeData(null);
      }
    } catch (err) {
      setError('Failed to fetch time data');
      setTimeData(null);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
        <h1 className="text-2xl font-bold text-center mb-6">City Time Checker</h1>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="city" className="block text-sm font-medium text-gray-700 mb-1">
              Enter City Name
            </label>
            <input
              id="city"
              type="text"
              value={city}
              onChange={(e) => setCity(e.target.value)}
              placeholder="e.g., Nairobi, London, Tokyo"
              className="w-full p-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              required
            />
          </div>
          
          <button
            type="submit"
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            Get Time
          </button>
        </form>

        {error && (
          <div className="mt-4 p-3 bg-red-100 text-red-700 rounded-md">
            {error}
          </div>
        )}

        {timeData && (
          <div className="mt-6 p-4 bg-gray-50 rounded-lg">
            <h2 className="text-xl font-semibold">{timeData.city}</h2>
            <p className="text-3xl font-bold text-blue-600 mt-2">{timeData.time}</p>
            <p className="text-sm text-gray-500 mt-1">{timeData.timezone}</p>
          </div>
        )}

        {recentSearches.length > 0 && (
          <div className="mt-6">
            <h3 className="text-lg font-semibold mb-2">Recent Searches</h3>
            <div className="space-y-2">
              {recentSearches.map((search, index) => (
                <div key={index} className="p-2 bg-gray-50 rounded-md">
                  <p className="text-sm">
                    <span className="font-medium">{search.city}:</span> {search.time}
                  </p>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}