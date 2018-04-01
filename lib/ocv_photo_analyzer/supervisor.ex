defmodule OcvPhotoAnalyzer.Supervisor do
  use Supervisor

  @moduledoc false

  alias OcvPhotoAnalyzer.Analyzer

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      supervisor(Analyzer, [%{}])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
