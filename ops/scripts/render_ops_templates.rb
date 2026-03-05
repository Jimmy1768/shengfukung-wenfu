#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "optparse"
require "pathname"
require "uri"
require "yaml"

ROOT_DIR = File.expand_path("../..", __dir__)

unless defined?(Rails)
  module Rails
    def self.root
      @root ||= Pathname.new(File.join(ROOT_DIR, "rails"))
    end
  end
end

PROJECT_CONSTANTS = File.join(
  ROOT_DIR,
  "rails",
  "app",
  "lib",
  "app_constants",
  "project.rb"
)

raise "AppConstants::Project not found" unless File.exist?(PROJECT_CONSTANTS)

require PROJECT_CONSTANTS

def render_placeholders(content, slug, human_name, public_domain: nil)
  rendered = content
    .gsub("{{project_slug}}", slug)
    .gsub("{{project_name}}", human_name)
    .gsub("Golden Template", human_name)
    .gsub("Golden-Template", human_name)
    .gsub("golden-template", slug)

  return rendered if public_domain.to_s.strip.empty?

  rendered
    .gsub("{{public_domain}}", public_domain)
    .gsub("project.com", public_domain)
end

def manifest_public_domain_for(slug)
  manifest_path = File.join(ROOT_DIR, "rails", "app", "lib", "temples", "manifest.yml")
  return nil unless File.exist?(manifest_path)

  data = YAML.safe_load_file(manifest_path)
  temples = data.is_a?(Hash) ? data["temples"] : nil
  return nil unless temples.is_a?(Array)

  entry = temples.find { |row| row.is_a?(Hash) && row["slug"].to_s == slug.to_s }
  return nil unless entry

  domains = entry["domains"]
  primary = domains.first if domains.is_a?(Array) && !domains.empty?
  return primary.to_s.strip unless primary.to_s.strip.empty?

  public_url = entry["public_url"].to_s.strip
  return nil if public_url.empty?

  URI.parse(public_url).host
rescue StandardError
  nil
end

def uncomment(line)
  line.sub(/\A#\s?/, "")
end

def extract_upstream_block(lines)
  output = []
  in_block = false
  depth = 0

  lines.each do |line|
    if !in_block
      next unless line.match?(/^\s*#\s*upstream\s+rails_puma\s*\{/)

      candidate = uncomment(line)
      output << candidate
      in_block = true
      depth = candidate.count("{") - candidate.count("}")
      next
    end

    candidate = uncomment(line)
    output << candidate
    depth += candidate.count("{") - candidate.count("}")
    break if depth <= 0
  end

  output
end

def extract_public_server_block(lines)
  output = []
  in_public_section = false
  in_server = false
  depth = 0

  lines.each do |line|
    unless in_public_section
      in_public_section = true if line.include?("Public site + marketing showcase")
      next
    end

    if !in_server
      next unless line.match?(/^\s*#\s*server\s*\{/)

      candidate = uncomment(line)
      output << candidate
      in_server = true
      depth = candidate.count("{") - candidate.count("}")
      next
    end

    candidate = uncomment(line)
    output << candidate
    depth += candidate.count("{") - candidate.count("}")
    break if depth <= 0
  end

  output
end

options = {
  slug: nil,
  output: nil
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: render_ops_templates.rb [options]"

  opts.on("-s", "--slug SLUG", "Project slug (defaults to AppConstants::Project::SLUG)") do |value|
    options[:slug] = value
  end

  opts.on("-o", "--output DIR", "Base output directory (defaults to ops/)") do |value|
    options[:output] = value
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end

parser.parse!

slug = options[:slug] || ARGV.shift || AppConstants::Project::SLUG
human_name = AppConstants::Project::NAME
public_domain = manifest_public_domain_for(slug)
output_root =
  if options[:output]
    File.expand_path(options[:output])
  else
    File.join(ROOT_DIR, "ops")
  end
systemd_output_dir = File.join(output_root, "systemd")
nginx_output_dir = File.join(output_root, "nginx")

templates = {
  File.join(ROOT_DIR, "ops", "systemd", "template", "golden-template-puma.service") => File.join(systemd_output_dir, "#{slug}-puma.service"),
  File.join(ROOT_DIR, "ops", "systemd", "template", "golden-template-sidekiq.service") => File.join(systemd_output_dir, "#{slug}-sidekiq.service")
}

templates.each do |source, destination|
  next unless File.exist?(source)

  content = File.read(source)
  rendered = render_placeholders(content, slug, human_name, public_domain: public_domain)

  FileUtils.mkdir_p(File.dirname(destination))
  File.write(destination, rendered)
  puts "Rendered #{source} → #{destination}"
end

nginx_template = File.join(ROOT_DIR, "ops", "nginx", "template", "golden-template.conf")
nginx_destination = File.join(nginx_output_dir, "#{slug}.conf")
if File.exist?(nginx_template)
  nginx_content = File.read(nginx_template)
  rendered = render_placeholders(nginx_content, slug, human_name, public_domain: public_domain)
  lines = rendered.lines
  upstream_block = extract_upstream_block(lines)
  public_server_block = extract_public_server_block(lines)

  if upstream_block.empty? || public_server_block.empty?
    raise "Failed to extract required nginx blocks from #{nginx_template}"
  end

  activated = (upstream_block + ["\n"] + public_server_block).join

  FileUtils.mkdir_p(File.dirname(nginx_destination))
  File.write(nginx_destination, activated)
  puts "Rendered #{nginx_template} → #{nginx_destination}"
else
  warn "Nginx template missing at #{nginx_template}. Skipping client config render."
end

puts <<~INSTRUCTIONS
  Systemd unit files rendered to:
    #{systemd_output_dir}

  Client nginx config is available at:
    #{nginx_destination}

  Copy them to the droplet (e.g. `/etc/systemd/system` and `/etc/nginx/sites-available/`) and reload the services:
    sudo cp #{systemd_output_dir}/#{slug}-puma.service /etc/systemd/system/#{slug}-puma.service
    sudo cp #{systemd_output_dir}/#{slug}-sidekiq.service /etc/systemd/system/#{slug}-sidekiq.service
    sudo cp #{nginx_destination} /etc/nginx/sites-available/#{slug}.conf
    sudo ln -sf /etc/nginx/sites-available/#{slug}.conf /etc/nginx/sites-enabled/#{slug}.conf
    sudo systemctl daemon-reload
    sudo systemctl restart #{slug}-puma
    sudo systemctl restart #{slug}-sidekiq
    sudo nginx -s reload
INSTRUCTIONS
