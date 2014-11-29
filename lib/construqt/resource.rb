module Construqt
  class Resources
    module Rights
      ROOT_0600 = OpenStruct.new :right => "0600", :owner => 'root'
      ROOT_0644 = OpenStruct.new :right => "0644", :owner => 'root'
      ROOT_0755 = OpenStruct.new :right => "0755", :owner => 'root'
    end

    class Resource
      attr_accessor :path
      attr_accessor :right
      attr_accessor :data
    end

    def initialize(region)
      @region = region
      @files = {}
    end

    def add_from_file(src_fname, right, key, *path)
      add_file(IO.read(src_fname), right, key, *path)
    end

    def add_file(data, right, key, *path)
      throw "need a key" unless key
      throw "need a path #{key}" if path.empty?
      throw "resource exists with key #{key}" if @files[key]
      resource = Resource.new
      resource.path = *path
      resource.right = right
      resource.data = data
      @files[key] = resource
      resource
    end

    def find(key)
      ret = @files[key]
      throw "resource with key #{key} not found" unless ret
      ret
    end
  end
end
