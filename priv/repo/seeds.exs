# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Parking.Repo.insert!(%Parking.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Parking.Repo
alias Parking.ParkingGarage
alias Parking.Level
alias Parking.ParkingSpot
alias Parking.Pricing
alias Parking.Pricing.TimeBasedConfig
alias Parking.Pricing.TimeSlot
alias Parking.Pricing.Holiday
alias Parking.Pricing.DailyRateConfig
alias Parking.Pricing.MonthlyRentConfig
alias Parking.Payment
alias Parking.Ticket
alias Parking.Users.User
alias Parking.Users.PermanentUser
alias Parking.Users.OccasionalUser
alias Parking.Settings
alias Parking.ParkingSystem

# Clear existing data
Repo.delete_all(PermanentUser)
Repo.delete_all(OccasionalUser)
Repo.delete_all(User)
Repo.delete_all(Payment)
Repo.delete_all(Ticket)
Repo.delete_all(Pricing)
Repo.delete_all(ParkingSpot)
Repo.delete_all(Level)
Repo.delete_all(ParkingGarage)
Repo.delete_all(Settings)

# Create settings
Repo.insert!(%Settings{key: "admin_password", value: "admin123"})

# Create garages
garage = Repo.insert!(%ParkingGarage{name: "Central Parking Garage"})
garage2 = Repo.insert!(%ParkingGarage{name: "North Parking Garage"})

# Create levels with parking spots for Central garage
# Spot number format: level * 100 + spot (e.g. level 1, spot 3 → 103)
Enum.each(1..3, fn level_number ->
  level = Repo.insert!(%Level{number: level_number, garage_id: garage.id})

  Enum.each(1..10, fn spot_number ->
    Repo.insert!(%ParkingSpot{
      number: level_number * 100 + spot_number,
      is_occupied: false,
      level_id: level.id
    })
  end)
end)

# Create levels with parking spots for North garage
Enum.each(1..2, fn level_number ->
  level = Repo.insert!(%Level{number: level_number, garage_id: garage2.id})

  Enum.each(1..8, fn spot_number ->
    Repo.insert!(%ParkingSpot{
      number: level_number * 100 + spot_number,
      is_occupied: false,
      level_id: level.id
    })
  end)
end)

# ── Central garage pricing ──────────────────────────────────────────────────

central_pricing = Repo.insert!(%Pricing{type: "time_based", garage_id: garage.id})

Repo.insert!(%TimeBasedConfig{pricing_id: central_pricing.id, rate_per_hour: 3.0})

for {from, to, rate} <- [
      {"00:00", "06:00", 2.50},
      {"06:00", "09:00", 2.80},
      {"09:00", "18:00", 3.60},
      {"18:00", "21:00", 2.80},
      {"21:00", "24:00", 2.40}
    ] do
  Repo.insert!(%TimeSlot{
    pricing_id: central_pricing.id,
    from_time: from,
    to_time: to,
    rate_per_hour: rate,
    slot_type: "weekday"
  })
end

for {from, to, rate} <- [
      {"00:00", "09:00", 2.40},
      {"09:00", "18:00", 3.20},
      {"18:00", "24:00", 2.40}
    ] do
  Repo.insert!(%TimeSlot{
    pricing_id: central_pricing.id,
    from_time: from,
    to_time: to,
    rate_per_hour: rate,
    slot_type: "weekend"
  })

  Repo.insert!(%TimeSlot{
    pricing_id: central_pricing.id,
    from_time: from,
    to_time: to,
    rate_per_hour: rate,
    slot_type: "holiday"
  })
end

for date <- [~D[2026-01-01], ~D[2026-12-25]] do
  Repo.insert!(%Holiday{pricing_id: central_pricing.id, date: date})
end

central_daily = Repo.insert!(%Pricing{type: "daily_rate", garage_id: garage.id})
Repo.insert!(%DailyRateConfig{pricing_id: central_daily.id, daily_rate: 35.0})

central_rent = Repo.insert!(%Pricing{type: "monthly_rent", garage_id: garage.id})
Repo.insert!(%MonthlyRentConfig{pricing_id: central_rent.id, monthly_rent: 150.0})

# ── North garage pricing ────────────────────────────────────────────────────

garage2_pricing = Repo.insert!(%Pricing{type: "time_based", garage_id: garage2.id})

Repo.insert!(%TimeBasedConfig{pricing_id: garage2_pricing.id, rate_per_hour: 2.0})

for {from, to, rate} <- [
      {"00:00", "08:00", 1.50},
      {"08:00", "20:00", 2.20},
      {"20:00", "24:00", 1.50}
    ] do
  Repo.insert!(%TimeSlot{
    pricing_id: garage2_pricing.id,
    from_time: from,
    to_time: to,
    rate_per_hour: rate,
    slot_type: "weekday"
  })
end

for slot_type <- ["weekend", "holiday"] do
  Repo.insert!(%TimeSlot{
    pricing_id: garage2_pricing.id,
    from_time: "00:00",
    to_time: "24:00",
    rate_per_hour: 1.80,
    slot_type: slot_type
  })
end

for date <- [~D[2026-01-01], ~D[2026-12-25]] do
  Repo.insert!(%Holiday{pricing_id: garage2_pricing.id, date: date})
end

north_daily = Repo.insert!(%Pricing{type: "daily_rate", garage_id: garage2.id})
Repo.insert!(%DailyRateConfig{pricing_id: north_daily.id, daily_rate: 22.0})

north_rent = Repo.insert!(%Pricing{type: "monthly_rent", garage_id: garage2.id})
Repo.insert!(%MonthlyRentConfig{pricing_id: north_rent.id, monthly_rent: 120.0})

# ── Users ───────────────────────────────────────────────────────────────────

{:ok, jace} = ParkingSystem.create_permanent_user(garage.id, "Jace Beleren")
{:ok, liliana} = ParkingSystem.create_permanent_user(garage.id, "Liliana of the Veil")
{:ok, nicol} = ParkingSystem.create_permanent_user(garage.id, "Nicol Bolas")

Repo.update!(PermanentUser.changeset(nicol, %{is_blocked: true}))

# Garruk has not paid for 2 months — blocked immediately when he tries to enter
{:ok, garruk} = ParkingSystem.create_permanent_user(garage.id, "Garruk Wildspeaker")
Repo.update!(PermanentUser.changeset(garruk, %{rent_paid_until: ~D[2026-03-31]}))

{:ok, chandra} = ParkingSystem.create_permanent_user(garage2.id, "Chandra Nalaar")
{:ok, teferi} = ParkingSystem.create_permanent_user(garage2.id, "Teferi, Hero of Dominaria")

# Nissa is one month behind — within grace period until the 15th
{:ok, nissa} = ParkingSystem.create_permanent_user(garage2.id, "Nissa Revane")
Repo.update!(PermanentUser.changeset(nissa, %{rent_paid_until: ~D[2026-04-30]}))

{:ok, _} = ParkingSystem.enter_permanent_user(chandra)

# Fill remaining unreserved spots in North garage with guest tickets
# North garage has 16 spots total; 3 are reserved for permanent users, leaving 13 for guests
Enum.each(1..13, fn _ ->
  {:ok, _} = ParkingSystem.create_ticket(garage2.id, garage2_pricing.id)
end)

IO.puts("""
Database seeded successfully!

Created:
- Parking Garage: #{garage.name}
  - 3 Levels with 10 parking spots each (spots 101-110, 201-210, 301-310)
  - Time-based pricing: CHF 2.50-3.60/hour (weekday), CHF 2.40-3.20/hour (weekend/holiday)
  - Daily rate: CHF 35.00/day
  - Permanent users (monthly rent CHF 150.00/month):
      • #{jace.access_code} (Jace Beleren)
      • #{liliana.access_code} (Liliana of the Veil)
      • #{nicol.access_code} (Nicol Bolas, blocked)
      • #{garruk.access_code} (Garruk Wildspeaker, 2 months overdue — blocked on entry)

- Parking Garage: #{garage2.name}
  - 2 Levels with 8 parking spots each (spots 101-108, 201-208)
  - Time-based pricing: CHF 1.50-2.20/hour (weekday), CHF 1.80/hour flat (weekend/holiday)
  - Daily rate: CHF 22.00/day
  - Permanent users (monthly rent CHF 120.00/month):
      • #{chandra.access_code} (Chandra Nalaar, currently parked)
      • #{teferi.access_code} (Teferi, Hero of Dominaria)
      • #{nissa.access_code} (Nissa Revane, 1 month overdue — grace period until 15th)
  - 13 guest tickets active (all unreserved spots occupied)
""")
