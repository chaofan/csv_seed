require 'csv'
require 'csv_seed/importer'
require 'csv_seed/record'
require 'csv_seed/table'
require 'csv_seed/uploader'
require 'csv_seed/version'

module CsvSeed
  def self.load_tasks
    Dir[File.expand_path('../tasks/*.thor', __FILE__)].each { |ext| load ext }
  end
end
