if Code.ensure_loaded?(Ecto) do
  defmodule Aplyid.MockServer.Schema.Transaction do
    @moduledoc """
    Ecto schema for mock server transactions.

    This schema is used for PostgreSQL persistence of mock server state.
    """

    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :string, autogenerate: false}
    @timestamps_opts [type: :utc_datetime_usec]

    schema "aplyid_mock_transactions" do
      field(:status, :string, default: "created")
      field(:reference, :string)
      field(:email, :string)
      field(:contact_phone, :string)
      field(:firstname, :string)
      field(:lastname, :string)
      field(:external_id, :string)
      field(:notifications, :map)
      field(:flow_type, :string)
      field(:biometric_only, :boolean)
      field(:redirect_success_url, :string)
      field(:redirect_cancel_url, :string)
      field(:communication_method, :string)
      field(:start_process_url, :string)
      field(:verification, :map)
      field(:message, :string)
      field(:completed_at, :utc_datetime_usec)

      timestamps()
    end

    @required_fields [:id, :reference, :start_process_url]
    @optional_fields [
      :status,
      :email,
      :contact_phone,
      :firstname,
      :lastname,
      :external_id,
      :notifications,
      :flow_type,
      :biometric_only,
      :redirect_success_url,
      :redirect_cancel_url,
      :communication_method,
      :verification,
      :message,
      :completed_at
    ]

    @doc """
    Creates a changeset for inserting a new transaction.
    """
    def create_changeset(transaction \\ %__MODULE__{}, attrs) do
      transaction
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> validate_inclusion(:status, ~w(created completed updated archived error pending))
    end

    @doc """
    Creates a changeset for updating an existing transaction.
    """
    def update_changeset(transaction, attrs) do
      transaction
      |> cast(attrs, @optional_fields)
      |> validate_inclusion(:status, ~w(created completed updated archived error pending))
    end

    @doc """
    Converts an Ecto schema struct to the internal Transaction struct.
    """
    def to_transaction(%__MODULE__{} = schema) do
      %Aplyid.MockServer.Transaction{
        id: schema.id,
        status: String.to_existing_atom(schema.status),
        reference: schema.reference,
        email: schema.email,
        contact_phone: schema.contact_phone,
        firstname: schema.firstname,
        lastname: schema.lastname,
        external_id: schema.external_id,
        notifications: schema.notifications,
        flow_type: schema.flow_type,
        biometric_only: schema.biometric_only,
        redirect_success_url: schema.redirect_success_url,
        redirect_cancel_url: schema.redirect_cancel_url,
        communication_method: schema.communication_method,
        start_process_url: schema.start_process_url,
        verification: schema.verification,
        message: schema.message,
        completed_at: schema.completed_at,
        created_at: schema.inserted_at,
        updated_at: schema.updated_at
      }
    end

    @doc """
    Converts an internal Transaction struct to attributes for Ecto operations.
    """
    def from_transaction(%Aplyid.MockServer.Transaction{} = txn) do
      %{
        id: txn.id,
        status: to_string(txn.status),
        reference: txn.reference,
        email: txn.email,
        contact_phone: txn.contact_phone,
        firstname: txn.firstname,
        lastname: txn.lastname,
        external_id: txn.external_id,
        notifications: txn.notifications,
        flow_type: txn.flow_type,
        biometric_only: txn.biometric_only,
        redirect_success_url: txn.redirect_success_url,
        redirect_cancel_url: txn.redirect_cancel_url,
        communication_method: txn.communication_method,
        start_process_url: txn.start_process_url,
        verification: txn.verification,
        message: txn.message,
        completed_at: txn.completed_at
      }
    end
  end
end
