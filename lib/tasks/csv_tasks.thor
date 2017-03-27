require 'thor/rails'
require 'csv_seed'

class Csv < Thor
  include Thor::Rails
  desc "seed", "copy records from "
  method_options :only => :array
  method_options :except => :array
  method_options :use => :string
  def seed
    CsvSeed::Import.new(options[:use]).run options[:only], options[:except]
  end
end
