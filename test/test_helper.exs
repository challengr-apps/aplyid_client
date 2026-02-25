ExUnit.start()

# Start the test repo
{:ok, _} = Aplyid.TestRepo.start_link()

# Run migrations for the mock server (before enabling sandbox mode)
Ecto.Migrator.up(Aplyid.TestRepo, 1, Aplyid.TestMigration, log: false)

# Enable sandbox mode for test isolation
Ecto.Adapters.SQL.Sandbox.mode(Aplyid.TestRepo, :manual)
