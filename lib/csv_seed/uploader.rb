# TODO 没有 2 个外键情况的处理，如：id, code
module CsvSeed
  module Uploader
    def self.file_path(path)
      "#{Rails.root}/db/seeds/#{path}"
    end
  end
end
