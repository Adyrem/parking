defmodule Parking.Users.PermanentUserTest do
  use Parking.DataCase

  alias Parking.Users.PermanentUser

  describe "rent_due?/2" do
    test "rent is due when no payment has been made" do
      perm_user = %PermanentUser{
        rent_paid_until: nil,
        last_rent_payment_at: nil
      }

      today = ~D[2026-04-15]
      assert PermanentUser.rent_due?(perm_user, today)
    end

    test "rent is due when payment expired and it's after 15th" do
      perm_user = %PermanentUser{
        rent_paid_until: ~D[2026-03-31],
        last_rent_payment_at: ~D[2026-03-01]
      }

      # After 15th
      today = ~D[2026-04-16]
      assert PermanentUser.rent_due?(perm_user, today)
    end

    test "rent is not due when payment is current" do
      perm_user = %PermanentUser{
        rent_paid_until: ~D[2026-04-30],
        last_rent_payment_at: ~D[2026-04-01]
      }

      # Before 15th
      today = ~D[2026-04-10]
      refute PermanentUser.rent_due?(perm_user, today)
    end

    test "rent is not due before 15th even if payment expired" do
      perm_user = %PermanentUser{
        rent_paid_until: ~D[2026-03-31],
        last_rent_payment_at: ~D[2026-03-01]
      }

      # Before 15th
      today = ~D[2026-04-10]
      refute PermanentUser.rent_due?(perm_user, today)
    end

    test "rent is due on 15th if payment expired" do
      perm_user = %PermanentUser{
        rent_paid_until: ~D[2026-03-31],
        last_rent_payment_at: ~D[2026-03-01]
      }

      # Exactly 15th
      today = ~D[2026-04-15]
      assert PermanentUser.rent_due?(perm_user, today)
    end
  end

  describe "validate_code/2" do
    test "validates correct code for unblocked user" do
      perm_user = %PermanentUser{
        access_code: "123456",
        is_blocked: false
      }

      assert PermanentUser.validate_code(perm_user, "123456")
    end

    test "rejects incorrect code" do
      perm_user = %PermanentUser{
        access_code: "123456",
        is_blocked: false
      }

      refute PermanentUser.validate_code(perm_user, "wrong_code")
    end

    test "rejects correct code for blocked user" do
      perm_user = %PermanentUser{
        access_code: "123456",
        is_blocked: true
      }

      refute PermanentUser.validate_code(perm_user, "123456")
    end
  end

  describe "changeset/2" do
    test "validates required fields" do
      changeset = PermanentUser.changeset(%PermanentUser{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on_changeset(changeset).access_code
    end

    test "validates access code is required" do
      changeset =
        PermanentUser.changeset(%PermanentUser{}, %{id: "550e8400-e29b-41d4-a716-446655440000"})

      refute changeset.valid?
    end
  end

  defp errors_on_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
