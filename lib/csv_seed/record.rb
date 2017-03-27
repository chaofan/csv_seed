module CsvSeed
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
