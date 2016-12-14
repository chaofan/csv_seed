# desc "Explaining what the task does"
require 'thor/rails'
require './lib/csv_seed'

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
