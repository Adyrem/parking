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

import Ecto.Query

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

# Create levels with parking spots
Enum.each(1..3, fn level_number ->
  level =
    Repo.insert!(%Level{
      number: level_number,
      garage_id: garage.id
    })

  # Create 10 parking spots per level
  Enum.each(1..10, fn spot_number ->
    Repo.insert!(%ParkingSpot{
      is_occupied: false,
      level_id: level.id
    })
  end)
end)

# Create levels for second garage (different configuration)
Enum.each(1..2, fn level_number ->
  level =
    Repo.insert!(%Level{
      number: level_number,
      garage_id: garage2.id
    })

  # Create 8 parking spots per level for second garage
  Enum.each(1..8, fn spot_number ->
    Repo.insert!(%ParkingSpot{
      is_occupied: false,
      level_id: level.id
    })
  end)
end)

# Create pricing strategies for the Central garage (rates per spec appendix)
time_based_pricing =
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

flat_rate_pricing =
  Repo.insert!(%Pricing{
    type: "flat_rate",
    config: %{"daily_rate" => 35.0},
    garage_id: garage.id
  })

# Create pricing strategies for the North garage (same tariff structure per spec appendix)
time_based_pricing2 =
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
    garage_id: garage2.id
  })

flat_rate_pricing2 =
  Repo.insert!(%Pricing{
    type: "flat_rate",
    config: %{"daily_rate" => 35.0},
    garage_id: garage2.id
  })

# Create several permanent users with reserved spots and sample access cards (Central garage)
perm_access_codes = [Ecto.UUID.generate(), Ecto.UUID.generate(), Ecto.UUID.generate()]

[spot1, spot2, spot3] =
  Repo.all(
    from s in ParkingSpot,
      join: l in Level,
      on: s.level_id == l.id,
      where: l.garage_id == ^garage.id,
      order_by: [asc: s.id],
      limit: 3
  )

perm_users = [
  %{
    access_code: Enum.at(perm_access_codes, 0),
    spot: spot1,
    blocked: false,
    name: "Jace Beleren"
  },
  %{
    access_code: Enum.at(perm_access_codes, 1),
    spot: spot2,
    blocked: false,
    name: "Liliana of the Veil"
  },
  %{access_code: Enum.at(perm_access_codes, 2), spot: spot3, blocked: true, name: "Nicol Bolas"}
]

Enum.each(perm_users, fn %{access_code: access_code, spot: spot, blocked: blocked, name: name} ->
  user = Repo.insert!(%User{type: "permanent"})

  Repo.insert!(%PermanentUser{
    id: user.id,
    access_code: access_code,
    spot_id: spot.id,
    is_blocked: blocked,
    name: name
  })
end)

# Create permanent users for the North garage
north_access_codes = [Ecto.UUID.generate(), Ecto.UUID.generate()]

[north_spot1, north_spot2] =
  Repo.all(
    from s in ParkingSpot,
      join: l in Level,
      on: s.level_id == l.id,
      where: l.garage_id == ^garage2.id,
      order_by: [asc: s.id],
      limit: 2
  )

north_perm_users = [
  %{
    access_code: Enum.at(north_access_codes, 0),
    spot: north_spot1,
    blocked: false,
    name: "Chandra Nalaar"
  },
  %{
    access_code: Enum.at(north_access_codes, 1),
    spot: north_spot2,
    blocked: false,
    name: "Teferi, Hero of Dominaria"
  }
]

Enum.each(north_perm_users, fn %{
                                 access_code: access_code,
                                 spot: spot,
                                 blocked: blocked,
                                 name: name
                               } ->
  user = Repo.insert!(%User{type: "permanent"})

  Repo.insert!(%PermanentUser{
    id: user.id,
    access_code: access_code,
    spot_id: spot.id,
    is_blocked: blocked,
    name: name
  })
end)

# Create settings
Repo.insert!(%Settings{key: "admin_password", value: "admin123"})

IO.puts("""
✓ Database seeded successfully!

Created:
- Parking Garage: #{garage.name}
  - 3 Levels with 10 parking spots each (30 total spots)
  - Time-based pricing: CHF 2.50–3.60/hour (weekday), CHF 2.40–3.20/hour (weekend/holiday)
  - Flat-rate pricing: CHF 35.00/day
  - Permanent users:
      • #{Enum.at(perm_access_codes, 0)} — #{spot1.id} (Jace Beleren)
      • #{Enum.at(perm_access_codes, 1)} — #{spot2.id} (Liliana of the Veil)
      • #{Enum.at(perm_access_codes, 2)} — #{spot3.id} (Nicol Bolas, blocked)

- Parking Garage: #{garage2.name}
  - 2 Levels with 8 parking spots each (16 total spots)
  - Time-based pricing: CHF 2.50–3.60/hour (weekday), CHF 2.40–3.20/hour (weekend/holiday)
  - Flat-rate pricing: CHF 35.00/day
  - Permanent users:
      • #{Enum.at(north_access_codes, 0)} — #{north_spot1.id} (Chandra Nalaar)
      • #{Enum.at(north_access_codes, 1)} — #{north_spot2.id} (Teferi, Hero of Dominaria)
""")
