# ver: 0.0.3
require 'csv'
# TODO 没有 2 个外键情况的处理，如：id, code
module CsvSeed
  module Uploader
    def self.file_path(path)
      "#{Rails.root}/db/seed/#{path}"
    end
  end
  class Import
    attr_accessor :name, :tables

    def initialize(name)
      @name = (name || '')
    end

    # thor csv:seed --use points --except Activity ActivityForm
    def run(only, except)
      # TODO 检查参数
      @tables = read_csv
      say_end = []
      models = only.present? ? only : (@tables.keys - (except or []))
      run_tables = @tables.values.select {|t| models.include? t.model}
      # @tables.keep_if {|k| models.include? k}
      puts "\n\n*** run_tables: #{run_tables.map(&:model).join(', ')}\n\n\n"
      ActiveRecord::Base.transaction do
        run_tables.each do |table|
          say_end += table.execute_commands("destroy_all")
        end
        run_tables.each do |table|
          say_end += table.execute_commands
        end
      end

      puts "\n"*3
      say_end.each {|say| puts say}
    end

    def read_csv()
      tables = {}
      current_model = ""
      Dir.glob(Rails.root.join("db","seed", @name, "*.csv")).each do |csv|
        lines = CSV.read(csv)
        lines.each do |line|
          next if line[0].nil?

          if line[0][0] == "#"
            cmd, *args = *line[0][1..-1].split('#')
            case cmd
            when "model"
              current_model = args.first
              tables[current_model] = Table.new(current_model, tables)
            when "command"
              tables[current_model].commands << {cmd: args.first, args: args[1..-1]}
            when "key"
              tables[current_model].key = args.first
            when "uploader"
              tables[current_model].upload_field_names = args
            end
            next
          end

          # Imported tables should have the 'id' attribute.
          if line[0] == 'id'
            tables[current_model].field_names = line.compact[1..-1]
            next
          end
          # 根据字段表长来截，compact会吞掉内容为空的字段。注意这儿有id。
          tables[current_model].add_record line[0..tables[current_model].field_names.size]
        end
      end
      tables
    end
  end

  class Table
    attr_accessor :model, :field_names, :foreign_keys, :primary_keys, :records, :count, :commands, :tables, :key, :upload_field_names

    def initialize(model, tables)
      @model = model
      @count = 0
      keys = table_class.reflect_on_all_associations(:belongs_to)
      @foreign_keys = Hash[keys.map {|k| [k.foreign_key, k.class_name]}]
      # polymorphic 的时候 association_primary_key 会出错。
      @primary_keys = Hash[keys.map {|k| [k.foreign_key, k.polymorphic? ? 'polymorphic' : k.association_primary_key]}]
      @tables = tables
      @commands = []
      @field_names = []
      @upload_field_names = []
      @key = 'id'
      @key_h = {}
    end

    def table_class
      # puts "*** table_class's model: #{@model}"
      @model.constantize
    end

    def add_record(attributes_line)
      @records ||= {}
      r = Record.new(self, attributes_line)
      pk = r.id
      # 如果有key的时候，这张表一般是用作指示的
      if @key != 'id'
        r.real_id = table_class.where(get_params_from_key(r)).first.try(:id)
        puts "*** [Table#add_record] Model: #{@model}, key: #{@key} -- id: #{r.id}, real_id: #{r.real_id}"
        puts "*** [Table#add_record] sql: #{table_class.where(get_params_from_key(r)).to_sql}"
        pk = r.content[@key]
      end
      @records[r.id] = r
      @key_h[pk] = r
    end

    # 根据 id 或 key 来找
    def find(k)
      puts "*** [Table#find] Model: #{@model}, k: #{k}"
      @records[k] || @key_h[k]
    end

    def get_params_from_key(record)
      return {id: 0} if @key == 'id'
      @key.split(',').each_with_object({}) do |attr_name, h|
        # 如果外键里有 id 的话，按这个找是找不到记录的。除非是 code 才能找到。
        h[attr_name.to_sym] = record.content[attr_name]
      end
    end

    def execute_commands(only_command = nil)
      say_later = []
      done = []
      @commands.each do |item|
        cmd, args = *item.values
        next if only_command.present? and only_command != cmd
        log_args = args.present? ? " args: #{args}" : ''
        puts "*** #{self.model}.#{cmd}#{log_args}\n"
        if cmd == 'destroy_all'
          say_later << "*** #{self.table_class.count} records have been deleted from #{self.model}\n"
          self.table_class.destroy_all
          @records.values.each {|r| r.real_id = nil}
          done << item
          next
        elsif cmd == 'create_all'
          self.records.values.each {|r| r.insert}
          done << item
          say_later << "*** #{self.count} records have been imported into model #{self.model}. \n"
          next
        end

        if %w(append delete update).include? cmd
          # keys 是查询条件包含的字段表列表，以逗号分隔。当cmd为append的时候没有
          ibegin, iend, keys, excepts = args[0].to_i, args[1].to_i, args[2], args[3]
          if (ibegin > iend || ibegin * iend <= 0)
            puts "*** #{cmd} args error: #{args}\n"
            raise "*** Import Error."
          end

          # #command#append#5#5
          if cmd == 'append'
            # byebug
            (ibegin..iend).each {|k| self.records[k.to_s].insert}
            done << item
            say_later << "*** #{iend - ibegin + 1} records have been imported into model #{self.model}. \n"
          end

          # #command#update#4#4#code
          if cmd == 'update'
            count = 0
            (ibegin..iend).each do |k|
              count += 1 if self.records[k.to_s].update(k, keys, excepts)
            end
            done << item
            say_later << "*** #{count} records of model #{self.model} have been updated.\n"
          end
          next
        end

        puts "*** cmd:#{cmd} not supported\n"
      end
      @commands -= done
      puts "*** #{self.model}.commands left: #{@commands}\n"
      say_later
    end
  end

  class Record
    attr_accessor :table, :id, :real_id, :content

    def initialize(table, attributes_line)
      @table    = table
      @id       = attributes_line[0]
      @content  = Hash[@table.field_names.zip attributes_line[1..-1]]
    end

    def insert
      return if @real_id.present?

      # 先去掉外键和上传字段，外键后面统一处理
      # @table.foreign_keys.keys +
      params = @content.except *(@table.upload_field_names)
      # 如果有enum字段，事先要先转为integer
      params = do_type_cast(params) if @table.table_class.defined_enums.present?
      r = @table.table_class.new params
      @table.upload_field_names.each do |field|
        File.open(Uploader.file_path(@content[field])) do |f|
          # r[field] = f
          # 上面这句无论如何不行，没有错也没上传。这是直接赋值，但是 carrierwave 应该改了这个赋值方法。
          r.send field+'=', f
        end
      end
      print "*** insert model: #{@table.model}, params: #{params}"
      r.save!
      # byebug if @table.model == 'Gift'
      @real_id = r.id
      @table.count += 1
      puts ", *** real_id: #{@real_id}\n"

      @table.foreign_keys.each do |k, m|
        pk = @table.primary_keys[k]
        puts "              model: #{@table.model}, foreign_key: #{k} -> #{m}, fk_content: #{@content[k]}, pk: #{pk}"
        next if @content[k].nil? # 外键为空
        next if pk != 'id' && pk != 'polymorphic' # 关系表主键不是 'id' 并且不是 polymorphic
        # byebug if k == 'activity_form_id'
        m = @content[k.gsub('_id', '_type')] if pk == 'polymorphic'
        f_record = @table.tables[m].find(@content[k])
        f_record.insert if !f_record.real_id
        puts "*** linked #{k}: #{f_record.real_id}"
        r[k] = f_record.real_id
      end
      r.save!
    end

    # #command#update#2#2#code
    def update(k, keys, excepts)
      puts "*** [Record#update] params: #{k}, #{keys}, #{excepts}"
      condition = @content.select {|k,v| keys.split(',').include? k}
      obj = @table.table_class.where(condition).first
      if obj
        content = excepts.present? ? @content.reject {|k,v| excepts.split(',').include? k} : @content
        obj.update! content
        puts "*** id: #{k}, obj_id:#{obj.id}, condition: #{condition}, a record of #{@table.model} has been updated.\n"
        true
      else
        false
      end
    end

    private
    def do_type_cast(params)
      result = params.clone
      @table.table_class.defined_enums.keys.each do |field|
        # nil表示缺省，缺省并不一定是0。nil.to_i == 0
        result[field] = params[field].to_i if params[field]
      end
      result
    end
  end

end
