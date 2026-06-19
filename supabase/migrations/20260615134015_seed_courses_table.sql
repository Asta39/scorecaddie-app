-- Ensure the courses table exists with at minimum id and name
CREATE TABLE IF NOT EXISTS "courses" (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT,
  total_holes INTEGER DEFAULT 18,
  par_18 INTEGER DEFAULT 72,
  caddie_fee NUMERIC DEFAULT 1000,
  latitude NUMERIC,
  longitude NUMERIC,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed all 19 Kenyan golf courses used by the app
INSERT INTO "courses" (name, location, total_holes, par_18, caddie_fee, latitude, longitude)
VALUES
  ('Royal Nairobi Golf Club',            'Nairobi',      18, 72, 1000, -1.2989, 36.7914),
  ('Karen Country Club',                 'Nairobi',      18, 72, 1200, -1.3533, 36.7117),
  ('Muthaiga Golf Club',                 'Nairobi',      18, 71, 1200, -1.2483, 36.8333),
  ('Windsor Golf Hotel & Country Club',  'Nairobi',      18, 72, 1500, -1.2104, 36.8770),
  ('Sigona Golf Club',                   'Kikuyu',       18, 72, 1000, -1.2333, 36.6500),
  ('Vet Lab Sports Club',                'Kabete',       18, 72, 1000, -1.2667, 36.7333),
  ('Thika Greens Golf Resort',           'Thika',        18, 72, 1200, -1.0167, 37.0833),
  ('Limuru Country Club',                'Limuru',       18, 72, 1000, -1.1167, 36.6333),
  ('Nyeri Golf Club',                    'Nyeri',        18, 72, 1000, -0.4245, 36.9423),
  ('Nyali Golf & Country Club',          'Mombasa',      18, 71, 1000, -4.0333, 39.7167),
  ('Mombasa Golf Club',                  'Mombasa',       9, 71,  800, -4.0667, 39.6667),
  ('Vipingo Ridge',                      'Kilifi',       18, 72, 1500, -3.8242, 39.7997),
  ('Nakuru Golf Club',                   'Nakuru',       18, 73,  800, -0.2833, 36.0683),
  ('Eldoret Golf Club',                  'Eldoret',      18, 71, 1000,  0.5143, 35.2697),
  ('Nyanza Golf Club',                   'Kisumu',        9, 70,  800, -0.1022, 34.7500),
  ('Kericho Golf Club',                  'Kericho',      18, 70,  800, -0.3667, 35.2833),
  ('Nandi Bears Club',                   'Nandi Hills',  18, 70,  800,  0.1000, 35.2000),
  ('Machakos Golf Club',                 'Machakos',     18, 70,  800, -1.5167, 37.2667),
  ('Ruiru Sports Club',                  'Ruiru',        18, 70, 1000, -1.1500, 36.9667)
ON CONFLICT DO NOTHING;
