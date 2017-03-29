require 'thor'
require 'thor/rails'
require 'csv_seed'

module CsvSeed
  class RunSeed < Thor
    include Thor::Rails
    desc "import", "import records from csv files"
    method_options :only => :array
    method_options :except => :array
    method_options :from => :string
    def import
      CsvSeed::Import.new(options[:from]).run options[:only], options[:except]
    end
  end
end
