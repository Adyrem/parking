defmodule Parking.Services.PaymentService.FailingStub do
  @behaviour Parking.Services.PaymentService
  def process(_service, _amount), do: {:error, :payment_failed}
end
