-- Real BLE pairing (#7.1): remember the Bluetooth remote id captured during a
-- real scan so ActiveWorkout can reconnect the BleHeartRateSource. Null keeps
-- the existing simulated-wearable behaviour (mock pairing, demo path).
alter table public.connected_devices
  add column if not exists ble_remote_id text;
