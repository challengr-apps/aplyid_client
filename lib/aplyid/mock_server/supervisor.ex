defmodule Aplyid.MockServer.Supervisor do
  @moduledoc """
  Supervisor for the mock APLYiD server.

  Supervises:
  - Task.Supervisor for async webhook delivery
  """

  use Supervisor

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    children = [
      {Task.Supervisor, name: Aplyid.MockServer.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
