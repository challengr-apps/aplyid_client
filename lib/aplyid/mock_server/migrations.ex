if Code.ensure_loaded?(Ecto.Migration) do
  defmodule Aplyid.MockServer.Migrations do
    @moduledoc """
    Migrations for the mock server PostgreSQL tables.

    This module provides migration functions that can be called from your
    application's migrations.

    ## Usage

    Generate a migration in your application:

        mix ecto.gen.migration add_aplyid_mock_server

    Then call the migration functions:

        defmodule MyApp.Repo.Migrations.AddAplyidMockServer do
          use Ecto.Migration

          def up, do: Aplyid.MockServer.Migrations.up(version: 1)
          def down, do: Aplyid.MockServer.Migrations.down(version: 1)
        end

    ## Options

    - `:version` - The migration version to run (default: 1)
    - `:prefix` - The database schema/prefix to use (default: "public")
    """

    use Ecto.Migration

    @current_version 1

    @doc """
    Returns the current migration version.
    """
    def current_version, do: @current_version

    @doc """
    Runs the up migrations up to the specified version.
    """
    def up(opts \\ []) do
      version = Keyword.get(opts, :version, @current_version)
      prefix = Keyword.get(opts, :prefix, "public")

      if version >= 1 do
        create_transactions_table(prefix)
      end
    end

    @doc """
    Runs the down migrations from the specified version.
    """
    def down(opts \\ []) do
      version = Keyword.get(opts, :version, @current_version)
      prefix = Keyword.get(opts, :prefix, "public")

      if version >= 1 do
        drop_transactions_table(prefix)
      end
    end

    defp create_transactions_table(prefix) do
      create table(:aplyid_mock_transactions, prefix: prefix, primary_key: false) do
        add(:id, :string, primary_key: true)
        add(:status, :string, null: false, default: "created")
        add(:reference, :string, null: false)
        add(:email, :string)
        add(:contact_phone, :string)
        add(:firstname, :string)
        add(:lastname, :string)
        add(:external_id, :string)
        add(:notifications, :map)
        add(:flow_type, :string)
        add(:biometric_only, :boolean)
        add(:redirect_success_url, :text)
        add(:redirect_cancel_url, :text)
        add(:communication_method, :string)
        add(:start_process_url, :string, null: false)
        add(:verification, :map)
        add(:message, :string)
        add(:completed_at, :utc_datetime_usec)

        timestamps(type: :utc_datetime_usec)
      end

      create(index(:aplyid_mock_transactions, [:status], prefix: prefix))
      create(index(:aplyid_mock_transactions, [:inserted_at], prefix: prefix))
    end

    defp drop_transactions_table(prefix) do
      drop_if_exists(index(:aplyid_mock_transactions, [:status], prefix: prefix))
      drop_if_exists(index(:aplyid_mock_transactions, [:inserted_at], prefix: prefix))
      drop_if_exists(table(:aplyid_mock_transactions, prefix: prefix))
    end
  end
end
