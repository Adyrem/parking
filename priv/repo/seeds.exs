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

# Create settings first — required by create_permanent_user/2
Repo.insert!(%Settings{key: "admin_password", value: "admin123"})
Repo.insert!(%Settings{key: "monthly_rent", value: "150.00"})

# Create a parking garage
garage =
  Repo.insert!(%ParkingGarage{
    name: "Central Parking Garage"
  })

# Create a second garage for multi-garage support
garage2 =
  Repo.insert!(%ParkingGarage{
    name: "North Parking Garage"
  })

# Create levels with parking spots for Central garage
# Spot number format: level * 100 + spot (e.g. level 1, spot 3 → 103)
Enum.each(1..3, fn level_number ->
  level =
    Repo.insert!(%Level{
      number: level_number,
      garage_id: garage.id
    })

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
  level =
    Repo.insert!(%Level{
      number: level_number,
      garage_id: garage2.id
    })

  Enum.each(1..8, fn spot_number ->
    Repo.insert!(%ParkingSpot{
      number: level_number * 100 + spot_number,
      is_occupied: false,
      level_id: level.id
    })
  end)
end)

# Central garage pricing — peak/off-peak weekday, reduced weekend/holiday
Repo.insert!(%Pricing{
  type: "time_based",
  config: %{
    "time_slots" => [
      %{"from" => "00:00", "to" => "06:00", "rate_per_hour" => 2.50},
      %{"from" => "06:00", "to" => "09:00", "rate_per_hour" => 2.80},
      %{"from" => "09:00", "to" => "18:00", "rate_per_hour" => 3.60},
      %{"from" => "18:00", "to" => "21:00", "rate_per_hour" => 2.80},
      %{"from" => "21:00", "to" => "24:00", "rate_per_hour" => 2.40}
    ],
    "weekend_time_slots" => [
      %{"from" => "00:00", "to" => "09:00", "rate_per_hour" => 2.40},
      %{"from" => "09:00", "to" => "18:00", "rate_per_hour" => 3.20},
      %{"from" => "18:00", "to" => "24:00", "rate_per_hour" => 2.40}
    ],
    "holiday_time_slots" => [
      %{"from" => "00:00", "to" => "09:00", "rate_per_hour" => 2.40},
      %{"from" => "09:00", "to" => "18:00", "rate_per_hour" => 3.20},
      %{"from" => "18:00", "to" => "24:00", "rate_per_hour" => 2.40}
    ],
    "holidays" => [
      "2026-01-01",
      "2026-12-25"
    ],
    "daily_rate" => 35.0,
    "rate_per_hour" => 3.0
  },
  garage_id: garage.id
})

# North garage pricing — simpler flat rates, lower overall
garage2_pricing =
  Repo.insert!(%Pricing{
    type: "time_based",
    config: %{
      "time_slots" => [
        %{"from" => "00:00", "to" => "08:00", "rate_per_hour" => 1.50},
        %{"from" => "08:00", "to" => "20:00", "rate_per_hour" => 2.20},
        %{"from" => "20:00", "to" => "24:00", "rate_per_hour" => 1.50}
      ],
      "weekend_time_slots" => [
        %{"from" => "00:00", "to" => "24:00", "rate_per_hour" => 1.80}
      ],
      "holiday_time_slots" => [
        %{"from" => "00:00", "to" => "24:00", "rate_per_hour" => 1.80}
      ],
      "holidays" => [
        "2026-01-01",
        "2026-12-25"
      ],
      "daily_rate" => 22.0,
      "rate_per_hour" => 2.0
    },
    garage_id: garage2.id
  })

# Create permanent users via ParkingSystem so ticket + payment records are created correctly
{:ok, jace} = ParkingSystem.create_permanent_user(garage.id, "Jace Beleren")
{:ok, liliana} = ParkingSystem.create_permanent_user(garage.id, "Liliana of the Veil")
{:ok, nicol} = ParkingSystem.create_permanent_user(garage.id, "Nicol Bolas")

# Block Nicol Bolas
Repo.update!(PermanentUser.changeset(nicol, %{is_blocked: true}))

{:ok, chandra} = ParkingSystem.create_permanent_user(garage2.id, "Chandra Nalaar")
{:ok, teferi} = ParkingSystem.create_permanent_user(garage2.id, "Teferi, Hero of Dominaria")

# Park Chandra in her reserved spot
{:ok, _} = ParkingSystem.enter_permanent_user(chandra)

# Fill remaining unreserved spots in North garage with guest tickets
# North garage has 16 spots total; 2 are reserved for permanent users, leaving 14 for guests
Enum.each(1..14, fn _ ->
  {:ok, _} = ParkingSystem.create_ticket(garage2.id, garage2_pricing.id)
end)

IO.puts("""
Database seeded successfully!

Created:
- Parking Garage: #{garage.name}
  - 3 Levels with 10 parking spots each (spots 101-110, 201-210, 301-310)
  - Time-based pricing: CHF 2.50-3.60/hour (weekday), CHF 2.40-3.20/hour (weekend/holiday)
  - Daily rate: CHF 35.00/day
  - Permanent users (monthly rent CHF 150.00 paid):
      • #{jace.access_code} (Jace Beleren)
      • #{liliana.access_code} (Liliana of the Veil)
      • #{nicol.access_code} (Nicol Bolas, blocked)

- Parking Garage: #{garage2.name}
  - 2 Levels with 8 parking spots each (spots 101-108, 201-208)
  - Time-based pricing: CHF 1.50-2.20/hour (weekday), CHF 1.80/hour flat (weekend/holiday)
  - Daily rate: CHF 22.00/day
  - Permanent users (monthly rent CHF 150.00 paid):
      • #{chandra.access_code} (Chandra Nalaar, currently parked)
      • #{teferi.access_code} (Teferi, Hero of Dominaria)
  - 14 guest tickets active (all unreserved spots occupied)
""")
