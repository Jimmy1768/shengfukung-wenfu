# Ensure dotenv also loads the repo-level .env files, not just ones inside /rails.
if defined?(Dotenv)
  project_root = Rails.root.join("..")
  Dotenv.load(project_root.join(".env")) if File.exist?(project_root.join(".env"))
  env_file = project_root.join(".env.#{Rails.env}")
  Dotenv.load(env_file) if File.exist?(env_file)
end
