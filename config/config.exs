import Config

if config_env() == :dev do
  config :mix_test_interactive,
    clear: true
end
