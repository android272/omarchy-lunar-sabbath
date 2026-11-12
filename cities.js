.pragma library

// A small offline gazetteer so city search does not need a network lookup.
// Coordinates are city-center values, close enough for rise and set.

var cities = [
  { name: "Jerusalem", region: "Israel", latitude: 31.7683, longitude: 35.2137, timeZone: "Asia/Jerusalem" },
  { name: "Tel Aviv", region: "Israel", latitude: 32.0853, longitude: 34.7818, timeZone: "Asia/Jerusalem" },
  { name: "Bethlehem", region: "West Bank", latitude: 31.7054, longitude: 35.2024, timeZone: "Asia/Jerusalem" },
  { name: "Nazareth", region: "Israel", latitude: 32.6996, longitude: 35.3035, timeZone: "Asia/Jerusalem" },
  { name: "Hebron", region: "West Bank", latitude: 31.5326, longitude: 35.0998, timeZone: "Asia/Jerusalem" },
  { name: "Amman", region: "Jordan", latitude: 31.9539, longitude: 35.9106, timeZone: "Asia/Amman" },
  { name: "Beirut", region: "Lebanon", latitude: 33.8938, longitude: 35.5018, timeZone: "Asia/Beirut" },
  { name: "Damascus", region: "Syria", latitude: 33.5138, longitude: 36.2765, timeZone: "Asia/Damascus" },
  { name: "Cairo", region: "Egypt", latitude: 30.0444, longitude: 31.2357, timeZone: "Africa/Cairo" },
  { name: "Alexandria", region: "Egypt", latitude: 31.2001, longitude: 29.9187, timeZone: "Africa/Cairo" },
  { name: "Baghdad", region: "Iraq", latitude: 33.3152, longitude: 44.3661, timeZone: "Asia/Baghdad" },
  { name: "Tehran", region: "Iran", latitude: 35.6892, longitude: 51.3890, timeZone: "Asia/Tehran" },
  { name: "Mecca", region: "Saudi Arabia", latitude: 21.3891, longitude: 39.8579, timeZone: "Asia/Riyadh" },
  { name: "Riyadh", region: "Saudi Arabia", latitude: 24.7136, longitude: 46.6753, timeZone: "Asia/Riyadh" },
  { name: "Dubai", region: "United Arab Emirates", latitude: 25.2048, longitude: 55.2708, timeZone: "Asia/Dubai" },
  { name: "Doha", region: "Qatar", latitude: 25.2854, longitude: 51.5310, timeZone: "Asia/Qatar" },
  { name: "Kuwait City", region: "Kuwait", latitude: 29.3759, longitude: 47.9774, timeZone: "Asia/Kuwait" },
  { name: "Muscat", region: "Oman", latitude: 23.5880, longitude: 58.3829, timeZone: "Asia/Muscat" },
  { name: "Istanbul", region: "Turkey", latitude: 41.0082, longitude: 28.9784, timeZone: "Europe/Istanbul" },
  { name: "Athens", region: "Greece", latitude: 37.9838, longitude: 23.7275, timeZone: "Europe/Athens" },
  { name: "Rome", region: "Italy", latitude: 41.9028, longitude: 12.4964, timeZone: "Europe/Rome" },
  { name: "London", region: "United Kingdom", latitude: 51.5074, longitude: -0.1278, timeZone: "Europe/London" },
  { name: "Edinburgh", region: "United Kingdom", latitude: 55.9533, longitude: -3.1883, timeZone: "Europe/London" },
  { name: "Dublin", region: "Ireland", latitude: 53.3498, longitude: -6.2603, timeZone: "Europe/Dublin" },
  { name: "Paris", region: "France", latitude: 48.8566, longitude: 2.3522, timeZone: "Europe/Paris" },
  { name: "Madrid", region: "Spain", latitude: 40.4168, longitude: -3.7038, timeZone: "Europe/Madrid" },
  { name: "Lisbon", region: "Portugal", latitude: 38.7223, longitude: -9.1393, timeZone: "Europe/Lisbon" },
  { name: "Berlin", region: "Germany", latitude: 52.5200, longitude: 13.4050, timeZone: "Europe/Berlin" },
  { name: "Amsterdam", region: "Netherlands", latitude: 52.3676, longitude: 4.9041, timeZone: "Europe/Amsterdam" },
  { name: "Brussels", region: "Belgium", latitude: 50.8503, longitude: 4.3517, timeZone: "Europe/Brussels" },
  { name: "Zurich", region: "Switzerland", latitude: 47.3769, longitude: 8.5417, timeZone: "Europe/Zurich" },
  { name: "Vienna", region: "Austria", latitude: 48.2082, longitude: 16.3738, timeZone: "Europe/Vienna" },
  { name: "Prague", region: "Czechia", latitude: 50.0755, longitude: 14.4378, timeZone: "Europe/Prague" },
  { name: "Warsaw", region: "Poland", latitude: 52.2297, longitude: 21.0122, timeZone: "Europe/Warsaw" },
  { name: "Budapest", region: "Hungary", latitude: 47.4979, longitude: 19.0402, timeZone: "Europe/Budapest" },
  { name: "Stockholm", region: "Sweden", latitude: 59.3293, longitude: 18.0686, timeZone: "Europe/Stockholm" },
  { name: "Oslo", region: "Norway", latitude: 59.9139, longitude: 10.7522, timeZone: "Europe/Oslo" },
  { name: "Copenhagen", region: "Denmark", latitude: 55.6761, longitude: 12.5683, timeZone: "Europe/Copenhagen" },
  { name: "Helsinki", region: "Finland", latitude: 60.1699, longitude: 24.9384, timeZone: "Europe/Helsinki" },
  { name: "Reykjavik", region: "Iceland", latitude: 64.1466, longitude: -21.9426, timeZone: "Atlantic/Reykjavik" },
  { name: "Moscow", region: "Russia", latitude: 55.7558, longitude: 37.6173, timeZone: "Europe/Moscow" },
  { name: "Kyiv", region: "Ukraine", latitude: 50.4501, longitude: 30.5234, timeZone: "Europe/Kyiv" },
  { name: "Nairobi", region: "Kenya", latitude: -1.2921, longitude: 36.8219, timeZone: "Africa/Nairobi" },
  { name: "Addis Ababa", region: "Ethiopia", latitude: 9.0320, longitude: 38.7469, timeZone: "Africa/Addis_Ababa" },
  { name: "Lagos", region: "Nigeria", latitude: 6.5244, longitude: 3.3792, timeZone: "Africa/Lagos" },
  { name: "Accra", region: "Ghana", latitude: 5.6037, longitude: -0.1870, timeZone: "Africa/Accra" },
  { name: "Casablanca", region: "Morocco", latitude: 33.5731, longitude: -7.5898, timeZone: "Africa/Casablanca" },
  { name: "Johannesburg", region: "South Africa", latitude: -26.2041, longitude: 28.0473, timeZone: "Africa/Johannesburg" },
  { name: "Cape Town", region: "South Africa", latitude: -33.9249, longitude: 18.4241, timeZone: "Africa/Johannesburg" },
  { name: "Delhi", region: "India", latitude: 28.6139, longitude: 77.2090, timeZone: "Asia/Kolkata" },
  { name: "Mumbai", region: "India", latitude: 19.0760, longitude: 72.8777, timeZone: "Asia/Kolkata" },
  { name: "Kathmandu", region: "Nepal", latitude: 27.7172, longitude: 85.3240, timeZone: "Asia/Kathmandu" },
  { name: "Dhaka", region: "Bangladesh", latitude: 23.8103, longitude: 90.4125, timeZone: "Asia/Dhaka" },
  { name: "Karachi", region: "Pakistan", latitude: 24.8607, longitude: 67.0011, timeZone: "Asia/Karachi" },
  { name: "Bangkok", region: "Thailand", latitude: 13.7563, longitude: 100.5018, timeZone: "Asia/Bangkok" },
  { name: "Singapore", region: "Singapore", latitude: 1.3521, longitude: 103.8198, timeZone: "Asia/Singapore" },
  { name: "Jakarta", region: "Indonesia", latitude: -6.2088, longitude: 106.8456, timeZone: "Asia/Jakarta" },
  { name: "Manila", region: "Philippines", latitude: 14.5995, longitude: 120.9842, timeZone: "Asia/Manila" },
  { name: "Hong Kong", region: "China", latitude: 22.3193, longitude: 114.1694, timeZone: "Asia/Hong_Kong" },
  { name: "Taipei", region: "Taiwan", latitude: 25.0330, longitude: 121.5654, timeZone: "Asia/Taipei" },
  { name: "Beijing", region: "China", latitude: 39.9042, longitude: 116.4074, timeZone: "Asia/Shanghai" },
  { name: "Shanghai", region: "China", latitude: 31.2304, longitude: 121.4737, timeZone: "Asia/Shanghai" },
  { name: "Seoul", region: "South Korea", latitude: 37.5665, longitude: 126.9780, timeZone: "Asia/Seoul" },
  { name: "Tokyo", region: "Japan", latitude: 35.6762, longitude: 139.6503, timeZone: "Asia/Tokyo" },
  { name: "Perth", region: "Australia", latitude: -31.9523, longitude: 115.8613, timeZone: "Australia/Perth" },
  { name: "Sydney", region: "Australia", latitude: -33.8688, longitude: 151.2093, timeZone: "Australia/Sydney" },
  { name: "Melbourne", region: "Australia", latitude: -37.8136, longitude: 144.9631, timeZone: "Australia/Melbourne" },
  { name: "Auckland", region: "New Zealand", latitude: -36.8509, longitude: 174.7645, timeZone: "Pacific/Auckland" },
  { name: "Honolulu", region: "United States", latitude: 21.3069, longitude: -157.8583, timeZone: "Pacific/Honolulu" },
  { name: "Anchorage", region: "United States", latitude: 61.2181, longitude: -149.9003, timeZone: "America/Anchorage" },
  { name: "Los Angeles", region: "United States", latitude: 34.0522, longitude: -118.2437, timeZone: "America/Los_Angeles" },
  { name: "Seattle", region: "United States", latitude: 47.6062, longitude: -122.3321, timeZone: "America/Los_Angeles" },
  { name: "Phoenix", region: "United States", latitude: 33.4484, longitude: -112.0740, timeZone: "America/Phoenix" },
  { name: "Denver", region: "United States", latitude: 39.7392, longitude: -104.9903, timeZone: "America/Denver" },
  { name: "Chicago", region: "United States", latitude: 41.8781, longitude: -87.6298, timeZone: "America/Chicago" },
  { name: "Houston", region: "United States", latitude: 29.7604, longitude: -95.3698, timeZone: "America/Chicago" },
  { name: "Minneapolis", region: "United States", latitude: 44.9778, longitude: -93.2650, timeZone: "America/Chicago" },
  { name: "New York", region: "United States", latitude: 40.7128, longitude: -74.0060, timeZone: "America/New_York" },
  { name: "Washington", region: "United States", latitude: 38.9072, longitude: -77.0369, timeZone: "America/New_York" },
  { name: "Boston", region: "United States", latitude: 42.3601, longitude: -71.0589, timeZone: "America/New_York" },
  { name: "Atlanta", region: "United States", latitude: 33.7490, longitude: -84.3880, timeZone: "America/New_York" },
  { name: "Miami", region: "United States", latitude: 25.7617, longitude: -80.1918, timeZone: "America/New_York" },
  { name: "Toronto", region: "Canada", latitude: 43.6532, longitude: -79.3832, timeZone: "America/Toronto" },
  { name: "Montreal", region: "Canada", latitude: 45.5017, longitude: -73.5673, timeZone: "America/Toronto" },
  { name: "Vancouver", region: "Canada", latitude: 49.2827, longitude: -123.1207, timeZone: "America/Vancouver" },
  { name: "Mexico City", region: "Mexico", latitude: 19.4326, longitude: -99.1332, timeZone: "America/Mexico_City" },
  { name: "Bogota", region: "Colombia", latitude: 4.7110, longitude: -74.0721, timeZone: "America/Bogota" },
  { name: "Lima", region: "Peru", latitude: -12.0464, longitude: -77.0428, timeZone: "America/Lima" },
  { name: "Santiago", region: "Chile", latitude: -33.4489, longitude: -70.6693, timeZone: "America/Santiago" },
  { name: "Sao Paulo", region: "Brazil", latitude: -23.5558, longitude: -46.6396, timeZone: "America/Sao_Paulo" },
  { name: "Buenos Aires", region: "Argentina", latitude: -34.6037, longitude: -58.3816, timeZone: "America/Argentina/Buenos_Aires" }
]

function search(query) {
  var q = String(query || "").toLowerCase().replace(/^\s+|\s+$/g, "")
  if (!q) return []
  var matches = []
  var i
  for (i = 0; i < cities.length; i++) {
    var city = cities[i]
    var hay = (city.name + " " + city.region).toLowerCase()
    if (hay.indexOf(q) === -1) continue
    matches.push(city)
  }
  matches.sort(function (a, b) {
    var an = a.name.toLowerCase().indexOf(q) === 0 ? 0 : 1
    var bn = b.name.toLowerCase().indexOf(q) === 0 ? 0 : 1
    if (an !== bn) return an - bn
    if (a.name < b.name) return -1
    if (a.name > b.name) return 1
    return 0
  })
  return matches.slice(0, 8)
}
