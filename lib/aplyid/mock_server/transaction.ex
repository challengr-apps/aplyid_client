defmodule Aplyid.MockServer.Transaction do
  @moduledoc """
  Transaction struct and lifecycle management for the mock server.

  Represents a verification transaction with all fields needed to generate
  realistic APLYiD API responses.
  """

  @type status :: :created | :completed | :updated | :archived | :error | :pending

  @type t :: %__MODULE__{
          id: String.t(),
          status: status(),
          reference: String.t(),
          email: String.t() | nil,
          contact_phone: String.t() | nil,
          firstname: String.t() | nil,
          lastname: String.t() | nil,
          external_id: String.t() | nil,
          notifications: map() | nil,
          flow_type: String.t() | nil,
          biometric_only: boolean() | nil,
          redirect_success_url: String.t() | nil,
          redirect_cancel_url: String.t() | nil,
          communication_method: String.t() | nil,
          start_process_url: String.t(),
          verification: map() | nil,
          message: String.t() | nil,
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          completed_at: DateTime.t() | nil
        }

  defstruct [
    :id,
    :status,
    :reference,
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
    :start_process_url,
    :verification,
    :message,
    :created_at,
    :updated_at,
    :completed_at
  ]

  @doc """
  Creates a new transaction from the given parameters.
  """
  @spec new(map()) :: t()
  def new(params) when is_map(params) do
    id = generate_id()
    now = DateTime.utc_now()

    %__MODULE__{
      id: id,
      status: :created,
      reference: params["reference"],
      email: params["email"],
      contact_phone: params["contact_phone"],
      firstname: params["firstname"],
      lastname: params["lastname"],
      external_id: params["external_id"],
      notifications: params["notifications"],
      flow_type: params["flow_type"],
      biometric_only: params["biometric_only"],
      redirect_success_url: params["redirect_success_url"],
      redirect_cancel_url: params["redirect_cancel_url"],
      communication_method: params["communication_method"],
      start_process_url: generate_start_process_url(id),
      verification: nil,
      message: nil,
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Generates a unique transaction ID.
  """
  @spec generate_id() :: String.t()
  def generate_id do
    :crypto.strong_rand_bytes(12) |> Base.url_encode64(padding: false)
  end

  @doc """
  Generates the start process URL for the transaction.
  """
  @spec generate_start_process_url(String.t()) :: String.t()
  def generate_start_process_url(id) do
    base = Aplyid.MockServer.base_url()
    "#{base}/l/#{id}"
  end

  @doc """
  Checks if a transaction can be completed.
  """
  @spec can_complete?(t()) :: boolean()
  def can_complete?(%__MODULE__{status: status}) do
    status == :created
  end

  @doc """
  Generates realistic mock verification result data matching APLYiD format.
  """
  @spec generate_verification_result() :: map()
  def generate_verification_result do
    %{
      "overall_result" => "PASS",
      "document_result" => "PASS",
      "facematch_result" => "PASS",
      "liveness_result" => "PASS",
      "data_result" => "PASS",
      "device_info" => %{
        "browser" => "Mobile Safari 17.0",
        "os" => "iOS 17.1",
        "ip" => "203.45.67.89",
        "country" => "AU"
      },
      "user_details" => %{
        "first_name" => "John",
        "middle_name" => "William",
        "last_name" => "Smith",
        "date_of_birth" => "1990-05-15",
        "document_type" => "DRIVERS_LICENCE",
        "document_number" => "DL123456789",
        "document_country" => "AU",
        "document_state" => "NSW"
      },
      "likeness_score" => "0.95"
    }
  end
end
