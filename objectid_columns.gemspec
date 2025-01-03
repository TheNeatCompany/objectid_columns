# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'objectid_columns/version'

Gem::Specification.new do |spec|
  spec.name          = "objectid_columns"
  spec.version       = ObjectidColumns::VERSION
  spec.authors       = ["Andrew Geweke"]
  spec.email         = ["ageweke@swiftype.com"]
  spec.summary       = %q{Transparently store MongoDB ObjectId values in ActiveRecord.}
  spec.homepage      = "https://www.github.com/swiftype/objectid_columns"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version     = '~> 3.3.2'
  spec.required_rubygems_version = '~> 3.5.9'

  ar_version = ENV['OBJECTID_COLUMNS_AR_TEST_VERSION']
  ar_version = ar_version.strip if ar_version

  version_spec = case ar_version
  when nil then '~> 7.1'
  when 'master' then nil
  else [ '=#{ar_version}' ]
  end

  if version_spec
    spec.add_dependency('activerecord', *version_spec)
    spec.add_dependency('activesupport', *version_spec)
  end

  spec.add_development_dependency 'bundler', '~> 2.5.15'
  spec.add_development_dependency 'rake', '~> 13.2.1'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'moped', '~> 2.0.7'
  spec.add_development_dependency 'bson', '~> 5.0.2'
  spec.add_development_dependency 'composite_primary_keys', '~> 14.0.9'

  require File.expand_path(File.join(File.dirname(__FILE__), 'spec', 'objectid_columns', 'helpers', 'database_helper'))
  database_gem_name = ObjectidColumns::Helpers::DatabaseHelper.maybe_database_gem_name

  # Ugh. Later versions of the 'mysql2' gem are incompatible with AR 3.0.x; so, here, we explicitly trap that case
  # and use an earlier version of that Gem.
  if database_gem_name && database_gem_name == 'mysql2' && ar_version && ar_version =~ /^3\.0\./
    spec.add_development_dependency('mysql2', '~> 0.2.0')
  else
    spec.add_development_dependency(database_gem_name)
  end

  # Double ugh. Basically, composite_primary_keys -- as useful as it is! -- is also incredibly incompatible with so
  # much stuff:
  #
  # * Under Ruby 1.9+ with Postgres, it causes binary strings sent to or from the database to get truncated
  #   at the first null byte (!), which completely breaks binary-column support;
  # * Under JRuby with ActiveRecord 3.0, it's completely broken;
  # * Under JRuby with ActiveRecord 3.1 and PostgreSQL, it's also broken;
  # * Under JRuby with ActiveRecord 4.1 and SQLite, it's also broken.
  #
  # In these cases, we simply don't load or test against composite_primary_keys; our code is good, but the interactions
  # between CPK and the rest of the system make it impossible to run those tests. There is corresponding code in our
  # +basic_system_spec+ to exclude those combinations.
  cpk_allowed = true
  cpk_allowed = false if database_gem_name =~ /(pg|postgres)/i && RUBY_VERSION =~ /^(1\.9)|(2\.)/ && ar_version && ar_version =~ /^4\.(0|1)\./
  cpk_allowed = false if defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'jruby') && ar_version && ar_version =~ /^3\.0\./
  cpk_allowed = false if defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'jruby') && ar_version && ar_version =~ /^3\.1\./ && database_gem_name =~ /(pg|postgres)/
  cpk_allowed = false if defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'jruby') && ar_version && ar_version =~ /^4\.1\./ && database_gem_name =~ /(sqlite)/

  if cpk_allowed
    spec.add_development_dependency "composite_primary_keys"
  end
end
