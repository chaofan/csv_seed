module CsvSeed
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
end
