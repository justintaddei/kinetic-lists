# Geoapify is the geocoder, and coordinates are captured once at creation

A Store's coordinates come from a keyed Geoapify forward-geocode (free tier: 3,000 credits/day, 5 req/s, "1 credit = 1 geocoding request", production use allowed with attribution), stored on the Store row and never re-requested. We chose it over key-free Photon/Nominatim because those forbid autocomplete and throttle systematic queries — and a type-ahead store picker *is* systematic querying — and over Google/Mapbox because both need a billing account.

Consequence: attribution ("Powered by Geoapify", OSM data) ships in the Store picker UI, and the key is a deploy secret, not a public value.
