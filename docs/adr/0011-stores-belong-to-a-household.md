# Stores belong to a Household

A Store row was per-user, which left a shared List holding Stores only their creators could see, and a Kinetic View that could not name the place a household is shopping in. v1 puts a Store — its name, coordinates and Geofence — in the Household: created by capture with Geoapify (ADR-0007), read and edited by any Member, and tagged onto Household Items. Rejected: global shared chain rows (the moderation and product-vocabulary cost ADR-0002 already rejected for the catalogue) and per-user rows whose visibility is routed through List membership.

Consequences: every Household has its own Walmart, a Kinetic View is one Household's view of it, and a Geofence is a shared judgement any Member may edit — 30 m for a curbside pickup is one number for the Household, not one per Member.
