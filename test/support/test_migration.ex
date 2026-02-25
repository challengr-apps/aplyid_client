defmodule Aplyid.TestMigration do
  use Ecto.Migration

  def up, do: Aplyid.MockServer.Migrations.up(version: 1)
  def down, do: Aplyid.MockServer.Migrations.down(version: 1)
end
