# Ensure dotenv also loads the repo-level .env files, not just ones inside /rails.
if defined?(Dotenv)
  require Rails.root.join("lib/multi_temple_env_loader")
  MultiTempleEnvLoader.load!(dotenv: Dotenv, env: ENV, rails_env: Rails.env, root: Rails.root.join(".."))
end
