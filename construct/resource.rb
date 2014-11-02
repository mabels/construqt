module Construct
  module Resource
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
    def self.add_from_file(src_fname, right, *path)
      self.add_file(IO.read(src_fname), right, *path)
    end
    def self.add_file(data, right, *path)
      resource = Resource.new 
      resource.path = *path
      resource.right = right
      resource.data = data
      resource
    end
  end
end
