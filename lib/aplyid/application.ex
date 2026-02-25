defmodule Aplyid.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = maybe_mock_server()
    opts = [strategy: :one_for_one, name: Aplyid.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_mock_server do
    mock_config = Application.get_env(:aplyid, :mock_server, [])

    if Keyword.get(mock_config, :enabled, false) do
      [{Aplyid.MockServer, mock_config}]
    else
      []
    end
  end
end
