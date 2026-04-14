# lib/parking/services/payment_service.ex
defmodule Parking.Services.PaymentService do
  @callback process(any(), float()) :: {:ok, any()} | {:error, atom()}

  @doc "Dispatches to the configured implementation (default: Stub)."
  def process(service, amount) do
    impl().process(service, amount)
  end

  defp impl do
    Application.get_env(:parking, :payment_service, __MODULE__.Stub)
  end

  defmodule Stub do
    @behaviour Parking.Services.PaymentService
    def process(_service, _amount), do: {:ok, :paid}
  end
end
