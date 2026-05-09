defmodule Parking.GarageStats do
  import Ecto.Query
  alias Parking.Repo
  alias Parking.ParkingGarage
  alias Parking.ParkingSpot
  alias Parking.Level

  @doc "Get garage with all preloaded data"
  def get_garage(garage_id) do
    from(g in ParkingGarage,
      where: g.id == ^garage_id,
      preload: [levels: [spots: :tickets]]
    )
    |> Repo.one()
  end

  @doc "Get comprehensive garage statistics with all levels and spots"
  def get_garage_stats(garage_id) do
    spots_query =
      from(s in ParkingSpot,
        order_by: [asc: s.id],
        preload: [tickets: :pricing, permanent_user: []]
      )

    levels_query =
      from(l in Level,
        order_by: [asc: l.number],
        preload: [spots: ^spots_query]
      )

    garage =
      from(g in ParkingGarage,
        where: g.id == ^garage_id,
        preload: [levels: ^levels_query]
      )
      |> Repo.one()

    case garage do
      nil ->
        nil

      garage ->
        levels_with_stats =
          Enum.map(garage.levels, fn level ->
            spots_with_type =
              Enum.map(level.spots, fn spot ->
                active_ticket = Enum.find(spot.tickets, &is_nil(&1.exit_time))

                type =
                  cond do
                    spot.permanent_user != nil -> :permanent
                    active_ticket != nil -> :guest_occupied
                    true -> :guest_available
                  end

                Map.put(spot, :spot_type, type)
              end)

            permanent_spots = Enum.count(spots_with_type, &(&1.spot_type == :permanent))
            guest_occupied = Enum.count(spots_with_type, &(&1.spot_type == :guest_occupied))
            guest_available = Enum.count(spots_with_type, &(&1.spot_type == :guest_available))
            total_spots = Enum.count(spots_with_type)

            %{
              level: level,
              spots: spots_with_type,
              total_spots: total_spots,
              permanent_spots: permanent_spots,
              guest_occupied: guest_occupied,
              guest_available: guest_available,
              occupied_spots: permanent_spots + guest_occupied,
              available_spots: guest_available,
              occupancy_rate:
                if(total_spots > 0,
                  do: Float.round((permanent_spots + guest_occupied) / total_spots * 100, 1),
                  else: 0.0
                )
            }
          end)

        all_spots = Enum.flat_map(levels_with_stats, & &1.spots)
        permanent_spots = Enum.count(all_spots, &(&1.spot_type == :permanent))
        guest_occupied = Enum.count(all_spots, &(&1.spot_type == :guest_occupied))
        guest_available = Enum.count(all_spots, &(&1.spot_type == :guest_available))
        total_spots = Enum.count(all_spots)

        %{
          garage: garage,
          levels: levels_with_stats,
          total_spots: total_spots,
          permanent_spots: permanent_spots,
          guest_occupied: guest_occupied,
          guest_available: guest_available,
          occupied_spots: permanent_spots + guest_occupied,
          available_spots: guest_available,
          occupancy_rate:
            if(total_spots > 0,
              do: Float.round((permanent_spots + guest_occupied) / total_spots * 100, 1),
              else: 0.0
            )
        }
    end
  end
end
