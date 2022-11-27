# frozen_string_literal: true

require_relative "lib/active_record/translated/version"

Gem::Specification.new do |spec|
  spec.name        = "active_record-translated"
  spec.version     = ActiveRecord::Translated::VERSION
  spec.authors     = ["Rasmus Kjellberg"]
  spec.homepage    = "https://github.com/kjellberg/active_record-translated"
  spec.summary     = "Separate database records for each language, grouped together with an ID"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 2.7"

  spec.files = Dir["{app,lib,config}/**/*", "LICENSE.md", "README.md"]

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/kjellberg/active_record-translated/issues",
    "documentation_uri" => "https://github.com/kjellberg/active_record-translated/issues",
    "source_code_uri" => "https://github.com/kjellberg/active_record-translated"
  }

  spec.add_dependency "dry-configurable", "~> 1.0.1"
  spec.add_dependency "net-smtp", "~> 0.3.3"
  spec.add_dependency "request_store", "~> 1.2.0"
end
