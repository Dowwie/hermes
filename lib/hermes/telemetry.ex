defmodule Hermes.Telemetry do
  @moduledoc false

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_arg) do
    children = [
      {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    application_metrics = [
      counter("hermes.messages.saved.provider_sms.count",
        description: "Total number of SMS messages saved"
      ),
      counter("hermes.messages.saved.provider_mms.count",
        description: "Total number of MMS messages saved"
      ),
      counter("hermes.messages.saved.provider_email.count",
        description: "Total number of Email messages saved"
      ),
      counter("hermes.attachments.saved.count",
        description: "Total number of attachments saved"
      )
    ]

    phoenix_metrics = [
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond})
    ]

    broadway_metrics = [
      summary("broadway.batcher.stop.duration", unit: {:native, :millisecond})
    ]

    vm_metrics = [
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]

    Enum.concat([
      application_metrics,
      phoenix_metrics,
      broadway_metrics,
      vm_metrics
    ])
  end
end
