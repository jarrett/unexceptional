require 'bundler'
Bundler.setup
require 'minitest'
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new(color: true)
$:.unshift(File.join(File.expand_path(File.dirname(__FILE__)), '../lib'))
require 'unexceptional'