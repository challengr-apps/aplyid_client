defmodule Aplyid.MockServer.Views do
  @moduledoc """
  HTML view templates for the mock verification flow.
  """

  alias Aplyid.MockServer.Transaction

  @doc """
  Screen 1: Privacy Consent
  """
  def consent(%Transaction{} = txn, prefix \\ "") do
    layout(
      "Privacy Consent",
      txn,
      ~s"""
      <div class="screen-content">
        <h2>Privacy Consent</h2>
        <p class="description">
          To verify your identity without the requirement for you to go to a physical
          location, we will use the camera on your phone to capture images of your face
          and your ID documents.
        </p>
        <p class="description">
          As such we will be needing your consent to access your camera to receive the
          images and to receive your location data for security purposes.
        </p>
        <p class="description muted">
          Without your acceptance of this declaration, you will need to verify your
          identity through another way.
        </p>

        <form method="POST" action="#{prefix}/l/#{txn.id}/consent">
          <label class="checkbox-label">
            <input type="checkbox" name="consent" required>
            <span>I confirm that I have read and accept the privacy consent.</span>
          </label>

          <div class="buttons">
            <button type="submit" class="btn btn-primary">Continue</button>
          </div>
        </form>
      </div>
      """
    )
  end

  @doc """
  Screen 2: Capture Photo ID
  """
  def capture(%Transaction{} = txn, prefix \\ "") do
    layout(
      "Capture your Photo ID",
      txn,
      ~s"""
      <div class="screen-content">
        <h2>Capture your Photo ID</h2>
        <p class="description">
          Take a photo of your ID Card, Driver Licence or Passport.
        </p>

        <div class="mock-camera">
          <div class="camera-frame">
            <div class="camera-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <rect x="2" y="6" width="20" height="14" rx="2"/>
                <rect x="6" y="2" width="12" height="4" rx="1"/>
                <circle cx="12" cy="13" r="4"/>
              </svg>
            </div>
            <p>Position your ID within the frame</p>
          </div>
        </div>

        <p class="hint">
          <em>Mock Mode: Click the button below to simulate capturing your ID.</em>
        </p>

        <form method="POST" action="#{prefix}/l/#{txn.id}/capture">
          <div class="buttons">
            <a href="#{prefix}/l/#{txn.id}/consent" class="btn btn-secondary">Back</a>
            <button type="submit" class="btn btn-primary btn-capture">Capture my ID</button>
          </div>
        </form>
      </div>
      """
    )
  end

  @doc """
  Screen 3: Reviewing ID Data (loading)
  """
  def reviewing(%Transaction{} = txn, prefix \\ "") do
    layout(
      "Reviewing your ID Data",
      txn,
      ~s"""
      <div class="screen-content loading-screen">
        <h2>Reviewing your ID Data</h2>
        <p class="description">
          On the next screen, please check carefully that all the data shown matches
          your card exactly and edit it if needed.
        </p>

        <div class="loading-indicator">
          <div class="spinner"></div>
          <p>Processing...</p>
        </div>
      </div>

      <script>
        // Auto-redirect after a brief delay to simulate processing
        setTimeout(function() {
          window.location.href = '#{prefix}/l/#{txn.id}/details';
        }, 1500);
      </script>
      """
    )
  end

  @doc """
  Screen 4: Check ID Details
  """
  def details(%Transaction{} = txn, prefix \\ "") do
    mock_data = mock_extracted_data(txn)

    layout(
      "Check your ID details",
      txn,
      ~s"""
      <div class="screen-content">
        <h2>Check your ID details</h2>
        <p class="description">
          Please verify that the information below matches your ID document.
        </p>

        <div class="id-details">
          <div class="detail-row">
            <span class="label">First name</span>
            <span class="value">#{mock_data.first_name}</span>
          </div>
          <div class="detail-row">
            <span class="label">Middle name</span>
            <span class="value">#{mock_data.middle_name}</span>
          </div>
          <div class="detail-row">
            <span class="label">Surname</span>
            <span class="value">#{mock_data.surname}</span>
          </div>
          <div class="detail-row">
            <span class="label">Date of birth</span>
            <span class="value">#{mock_data.date_of_birth}</span>
          </div>
          <div class="detail-row">
            <span class="label">ID number</span>
            <span class="value">#{mock_data.id_number}</span>
          </div>
          <div class="detail-row">
            <span class="label">Date of expiry</span>
            <span class="value">#{mock_data.date_of_expiry}</span>
          </div>
        </div>

        <form method="POST" action="#{prefix}/l/#{txn.id}/details">
          <label class="checkbox-label">
            <input type="checkbox" name="consent" required>
            <span>I consent to my information being checked with the document issuer or official record holder.</span>
          </label>

          <div class="buttons">
            <a href="#{prefix}/l/#{txn.id}/capture" class="btn btn-secondary">Back</a>
            <button type="submit" class="btn btn-primary">My details are correct</button>
          </div>
        </form>
      </div>
      """
    )
  end

  @doc """
  Screen 5: Face Verification
  """
  def face(%Transaction{} = txn, prefix \\ "") do
    layout(
      "Face Verification",
      txn,
      ~s"""
      <div class="screen-content">
        <h2>Face Verification</h2>
        <p class="description">
          We need a short selfie video to help us match you to your ID.
          It's completely private and will only take a few seconds.
        </p>

        <div class="mock-camera face-camera">
          <div class="camera-frame round">
            <div class="face-icon">
              <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1">
                <circle cx="12" cy="12" r="10"/>
                <circle cx="9" cy="10" r="1" fill="currentColor"/>
                <circle cx="15" cy="10" r="1" fill="currentColor"/>
                <path d="M8 14s1.5 2 4 2 4-2 4-2"/>
              </svg>
            </div>
          </div>
        </div>

        <p class="hint">
          <em>Mock Mode: Click Continue to simulate face verification.</em>
        </p>

        <form method="POST" action="#{prefix}/l/#{txn.id}/face">
          <div class="buttons">
            <a href="#{prefix}/l/#{txn.id}/details" class="btn btn-secondary">Back</a>
            <button type="submit" class="btn btn-primary">Continue</button>
          </div>
        </form>
      </div>
      """
    )
  end

  @doc """
  Screen 6: Verification Complete
  """
  def complete(%Transaction{} = txn, _prefix \\ "") do
    layout(
      "Verification Complete",
      txn,
      ~s"""
      <div class="screen-content complete-screen">
        <div class="success-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2">
            <circle cx="12" cy="12" r="10"/>
            <path d="M8 12l3 3 5-5"/>
          </svg>
        </div>

        <h2>Verification complete</h2>
        <p class="description">
          Your identity has been verified successfully.
        </p>
        <p class="muted">You can close this window.</p>

        #{redirect_link(txn)}
      </div>
      """
    )
  end

  @doc """
  Already completed screen
  """
  def already_completed(%Transaction{} = txn, _prefix \\ "") do
    layout(
      "Already Verified",
      txn,
      ~s"""
      <div class="screen-content complete-screen">
        <div class="success-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2">
            <circle cx="12" cy="12" r="10"/>
            <path d="M8 12l3 3 5-5"/>
          </svg>
        </div>

        <h2>Already Verified</h2>
        <p class="description">
          This verification has already been completed.
        </p>

        #{redirect_link(txn)}
      </div>
      """
    )
  end

  @doc """
  Error screen
  """
  def error(message) do
    layout(
      "Error",
      nil,
      ~s"""
      <div class="screen-content error-screen">
        <div class="error-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2">
            <circle cx="12" cy="12" r="10"/>
            <path d="M12 8v4M12 16h.01"/>
          </svg>
        </div>

        <h2>Error</h2>
        <p class="description">#{message}</p>
      </div>
      """
    )
  end

  # Private helpers

  defp redirect_link(%Transaction{redirect_success_url: url})
       when is_binary(url) and url != "" do
    ~s"""
    <div class="redirect-link">
      <a href="#{url}" class="btn btn-primary">Return to application</a>
    </div>
    """
  end

  defp redirect_link(_), do: ""

  defp mock_extracted_data(%Transaction{firstname: firstname, lastname: lastname}) do
    first = (firstname || "John") |> String.upcase()
    last = (lastname || "Smith") |> String.upcase()

    %{
      first_name: first,
      middle_name: "",
      surname: last,
      date_of_birth: "15/05/1990",
      id_number: "DL#{:rand.uniform(999_999_999)}",
      date_of_expiry: "15/05/2028"
    }
  end

  defp layout(title, txn, content) do
    name =
      if txn do
        [txn.firstname, txn.lastname]
        |> Enum.filter(& &1)
        |> Enum.join(" ")
      else
        ""
      end

    ~s"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{title} - APLYiD Mock</title>
      <style>
        #{css()}
      </style>
    </head>
    <body>
      <div class="container">
        <header>
          <div class="logo">
            <span class="logo-aply">APLY</span><span class="logo-id">iD</span>
            <span class="mock-badge">MOCK</span>
          </div>
          #{if name != "", do: ~s(<div class="user-name">#{name}</div>), else: ""}
        </header>

        <main>
          #{content}
        </main>

        <footer>
          <p class="mock-notice">This is a mock verification flow for development purposes.</p>
        </footer>
      </div>
    </body>
    </html>
    """
  end

  defp css do
    ~s"""
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      background: linear-gradient(135deg, #0d9488 0%, #0f766e 100%);
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 20px;
    }

    .container {
      background: white;
      border-radius: 16px;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
      width: 100%;
      max-width: 420px;
      min-height: 600px;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    header {
      background: #0d9488;
      color: white;
      padding: 16px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .logo {
      font-size: 24px;
      font-weight: bold;
      display: flex;
      align-items: center;
      gap: 2px;
    }

    .logo-aply {
      color: white;
    }

    .logo-id {
      color: #ccfbf1;
    }

    .mock-badge {
      background: rgba(255,255,255,0.2);
      font-size: 10px;
      padding: 2px 6px;
      border-radius: 4px;
      font-weight: normal;
      margin-left: 8px;
    }

    .user-name {
      font-size: 14px;
      opacity: 0.9;
    }

    main {
      flex: 1;
      padding: 24px;
      display: flex;
      flex-direction: column;
    }

    .screen-content {
      flex: 1;
      display: flex;
      flex-direction: column;
    }

    h2 {
      color: #1f2937;
      font-size: 22px;
      margin-bottom: 16px;
    }

    .description {
      color: #4b5563;
      font-size: 14px;
      line-height: 1.6;
      margin-bottom: 12px;
    }

    .muted {
      color: #9ca3af;
      font-size: 13px;
    }

    .hint {
      color: #6b7280;
      font-size: 13px;
      text-align: center;
      margin: 16px 0;
      padding: 12px;
      background: #f3f4f6;
      border-radius: 8px;
    }

    form {
      margin-top: auto;
    }

    .checkbox-label {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      margin: 20px 0;
      cursor: pointer;
    }

    .checkbox-label input {
      margin-top: 3px;
      width: 18px;
      height: 18px;
      accent-color: #0d9488;
    }

    .checkbox-label span {
      font-size: 14px;
      color: #374151;
      line-height: 1.5;
    }

    .buttons {
      display: flex;
      gap: 12px;
      margin-top: 20px;
    }

    .btn {
      flex: 1;
      padding: 14px 20px;
      border-radius: 8px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      text-decoration: none;
      text-align: center;
      border: none;
      transition: all 0.2s;
    }

    .btn-primary {
      background: #0d9488;
      color: white;
    }

    .btn-primary:hover {
      background: #0f766e;
    }

    .btn-secondary {
      background: #f3f4f6;
      color: #374151;
    }

    .btn-secondary:hover {
      background: #e5e7eb;
    }

    .btn-capture {
      background: #0d9488;
    }

    .mock-camera {
      margin: 24px 0;
      display: flex;
      justify-content: center;
    }

    .camera-frame {
      width: 280px;
      height: 180px;
      border: 3px dashed #d1d5db;
      border-radius: 12px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      background: #f9fafb;
      color: #6b7280;
    }

    .camera-frame.round {
      width: 200px;
      height: 200px;
      border-radius: 50%;
    }

    .camera-icon, .face-icon {
      margin-bottom: 12px;
      color: #9ca3af;
    }

    .camera-frame p {
      font-size: 13px;
    }

    .loading-screen {
      text-align: center;
    }

    .loading-indicator {
      margin: 40px 0;
    }

    .spinner {
      width: 50px;
      height: 50px;
      border: 4px solid #f3f4f6;
      border-top-color: #0d9488;
      border-radius: 50%;
      margin: 0 auto 16px;
      animation: spin 1s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    .id-details {
      background: #f9fafb;
      border-radius: 12px;
      padding: 16px;
      margin: 16px 0;
    }

    .detail-row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #e5e7eb;
    }

    .detail-row:last-child {
      border-bottom: none;
    }

    .detail-row .label {
      color: #6b7280;
      font-size: 13px;
    }

    .detail-row .value {
      color: #1f2937;
      font-size: 14px;
      font-weight: 500;
    }

    .complete-screen, .error-screen {
      text-align: center;
      justify-content: center;
      align-items: center;
    }

    .success-icon, .error-icon {
      margin-bottom: 24px;
    }

    .redirect-link {
      margin-top: 24px;
    }

    footer {
      padding: 16px;
      text-align: center;
      border-top: 1px solid #e5e7eb;
    }

    .mock-notice {
      font-size: 11px;
      color: #9ca3af;
    }
    """
  end
end
