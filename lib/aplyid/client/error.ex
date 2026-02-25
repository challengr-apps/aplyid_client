defmodule Aplyid.Client.Error do
  @moduledoc """
  Error handling for the APLYiD API client.

  This module defines error types and provides helper functions for
  working with API errors.
  """

  defstruct [:type, :message, :status, :details]

  @type t :: %__MODULE__{
          type: atom(),
          message: String.t(),
          status: integer() | nil,
          details: map() | nil
        }

  @doc """
  Creates a new error struct from various error formats.

  ## Examples

      Aplyid.Client.Error.new(:unauthorized)
      #=> %Aplyid.Client.Error{type: :unauthorized, message: "Unauthorized - invalid or missing API key", status: 401}

      Aplyid.Client.Error.new({:validation_error, %{"message" => "Invalid request"}})
      #=> %Aplyid.Client.Error{type: :validation_error, message: "Validation failed", status: 422, details: ...}
  """
  @spec new(atom() | tuple()) :: t()
  def new(:unauthorized) do
    %__MODULE__{
      type: :unauthorized,
      message: "Unauthorized - invalid or missing API key",
      status: 401
    }
  end

  def new(:forbidden) do
    %__MODULE__{
      type: :forbidden,
      message: "Forbidden - API key does not have permission for this resource",
      status: 403
    }
  end

  def new(:not_found) do
    %__MODULE__{
      type: :not_found,
      message: "Resource not found",
      status: 404
    }
  end

  def new({:validation_error, details}) do
    %__MODULE__{
      type: :validation_error,
      message: "Validation failed",
      status: 422,
      details: details
    }
  end

  def new({:client_error, status, body}) do
    %__MODULE__{
      type: :client_error,
      message: "Client error: #{extract_message(body)}",
      status: status,
      details: body
    }
  end

  def new({:server_error, status, body}) do
    %__MODULE__{
      type: :server_error,
      message: "Server error: #{extract_message(body)}",
      status: status,
      details: body
    }
  end

  def new({:request_failed, reason}) do
    %__MODULE__{
      type: :request_failed,
      message: "Request failed: #{inspect(reason)}",
      details: %{reason: reason}
    }
  end

  def new(error) when is_atom(error) do
    %__MODULE__{
      type: error,
      message: error |> Kernel.to_string() |> String.replace("_", " ") |> String.capitalize()
    }
  end

  @doc """
  Converts an error to a human-readable string.
  """
  @spec message(t()) :: String.t()
  def message(%__MODULE__{message: msg}), do: msg

  @doc """
  Returns true if the error is a validation error.
  """
  @spec validation_error?(t()) :: boolean()
  def validation_error?(%__MODULE__{type: :validation_error}), do: true
  def validation_error?(_), do: false

  @doc """
  Returns true if the error is an authentication error.
  """
  @spec auth_error?(t()) :: boolean()
  def auth_error?(%__MODULE__{type: :unauthorized}), do: true
  def auth_error?(_), do: false

  defp extract_message(body) when is_map(body) do
    body["message"] || body["error"] || "Unknown error"
  end

  defp extract_message(body) when is_binary(body), do: body
  defp extract_message(_), do: "Unknown error"
end
