defmodule Aplyid.Client.Verifications do
  @moduledoc """
  Verification operations for the APLYiD identity verification API.

  ## Creating a verification

  Use `create/2` to create a new identity verification. If a `contact_phone`
  is provided, an SMS will be sent to the user. Otherwise, a `start_process_url`
  is returned for manual delivery.

  ## Resending SMS

  Use `resend_sms/2` or `resend_sms/3` to resend the verification SMS to
  the same or a different phone number.
  """

  alias Aplyid.Client
  alias Aplyid.Client.Request

  @doc """
  Creates a new identity verification, optionally sending an SMS.

  Sends POST to /api/v2/send_text.

  ## Required params

    * `"reference"` - Your unique reference for this verification

  ## Optional params

    * `"email"` - Applicant's email address
    * `"contact_phone"` - Phone number for SMS delivery (international format, no "+")
    * `"firstname"` - Applicant's first name
    * `"lastname"` - Applicant's last name
    * `"external_id"` - Your external identifier
    * `"notifications"` - Email addresses for completion notifications
    * `"flow_type"` - Verification flow type ("SIMPLE2" or "VOI2")
    * `"biometric_only"` - Whether to skip identity data searches
    * `"redirect_success_url"` - HTTPS URL to redirect to on success
    * `"redirect_cancel_url"` - HTTPS URL to redirect to on cancellation
    * `"communication_method"` - "sms" (default) or "link"

  ## Examples

      {:ok, result} = Aplyid.Client.Verifications.create(client, %{
        "reference" => "my-ref-123",
        "contact_phone" => "61400000000"
      })
  """
  @spec create(Client.t(), map()) :: Request.response()
  def create(client, params) when is_map(params) do
    Request.post(client, "/api/v2/send_text", json: params)
  end

  @doc """
  Resends the verification SMS for an existing transaction.

  Sends PUT to /api/v2/resend_text/:transaction_id.

  Note: The original verification is archived and a new transaction ID is issued.

  ## Options

    * `"contact_phone"` - Optional new phone number to send to

  ## Examples

      # Resend to same number
      {:ok, result} = Aplyid.Client.Verifications.resend_sms(client, "txn-abc-123")

      # Resend to different number
      {:ok, result} = Aplyid.Client.Verifications.resend_sms(client, "txn-abc-123", %{
        "contact_phone" => "61400111222"
      })
  """
  @spec resend_sms(Client.t(), String.t(), map()) :: Request.response()
  def resend_sms(client, transaction_id, params \\ %{}) do
    Request.put(client, "/api/v2/resend_text/#{transaction_id}", json: params)
  end
end
