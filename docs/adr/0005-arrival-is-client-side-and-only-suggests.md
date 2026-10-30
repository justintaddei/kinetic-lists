# Arrival is judged in the browser, and arrival UI only suggests

> **Amended by [ADR-0013](0013-a-store-has-locations-and-its-coordinates-come-from-a-position.md):** the client judges Inside against a Household's **Locations**, and an Arrival records (Member, **Location**, time). Nothing else here changes — the Position stays unpersisted, and arrival UI never sets the Active Store.

Web geofencing does not exist: the W3C Geolocation Sensor spec is a discontinued draft ("no implementers appear to be interested in developing an API for background geolocation or geofencing"), Periodic Background Sync is Chrome/Edge/Opera-only and installed-app-gated with no Safari support, Push only wakes a service worker when the server already has a message, and Chromium requires a visible page for geolocation. So v1 reads a Position with `watchPosition` only while the tab is visible, judges Inside against the user's own Stores client-side, and **suggests** the Kinetic View with a banner — it never sets the Active Store, which is always picked by hand.

Consequences we accepted: arrival never works with the app closed (no notification can fire us), an iOS user must have the app open, and the app stores Arrivals (Store, time) only — device Positions are never persisted, and the app never asks a geocoder about a Position.

_Avoid in future designs_: "auto-detect that you're at Walmart", background arrival, server-side geofence RPC, web push (VAPID) as the arrival delivery mechanism.
