# -*- encoding: us-ascii -*-

module FFI

  ##
  # Pointer is Rubinius's "fat" pointer class. It represents an actual
  # pointer, in C language terms, to an address in memory. They're called
  # fat pointers because the Pointer object is an wrapper around
  # the actual pointer, the Rubinius runtime doesn't have direct access
  # to the raw address.
  #
  # This class is used extensively in FFI usage to interface with various
  # parts of the underlying system. It provides a number of operations
  # for operating on the memory that is pointed to. These operations effectively
  # give Rubinius the cast/read capabilities available in C, but using
  # high level methods.
  #
  # MemoryPointer objects can be put in autorelease mode. In this mode,
  # when the GC cleans up a MemoryPointer object, the memory it points
  # to is passed to free(3), releasing the memory back to the OS.
  #
  # NOTE: MemoryPointer exposes direct, unmanaged operations on any
  # memory. It therefore MUST be used carefully. Reading or writing to
  # invalid address will cause bus errors and segmentation faults.
  #
  class Pointer
    include PointerAccessors

    def initialize(a1, a2=undefined)
      if a2.equal? undefined
        self.address = a1
      else
        @type = a1
        self.address = a2
      end
    end

    def inspect
      # Don't have this print the data at the location. It can crash everything.
      addr = address()

      if addr < 0
        sign = "-"
        addr = -addr
      else
        sign = ""
      end

      "#<#{self.class.name} address=#{sign}0x#{addr.to_s(16)}>"
    end

    # Return the address pointed to as an Integer
    def address
      Rubinius.primitive :pointer_address
      raise PrimitiveFailure, "Unable to find address"
    end

    alias_method :to_i, :address

    # Set the address pointed to from an Integer
    def address=(address)
      Rubinius.primitive :pointer_set_address
      raise PrimitiveFailure, "MemoryPointer#address= primitive failed"
    end

    def null?
      address == 0x0
    end

    # Add +value+ to the address pointed to and return a new Pointer
    def +(value)
      Rubinius.primitive :pointer_add
      raise PrimitiveFailure, "Unable to add"
    end

    # Indicates if +self+ and +other+ point to the same address
    def ==(other)
      return false unless other.kind_of? Pointer
      return address == other.address
    end

    def network_order(start, size)
      Rubinius.primitive :pointer_network_order
      raise PrimitiveFailure, "Unable to convert to network order"
    end

    # Read +len+ bytes from the memory pointed to and return them as
    # a String
    def read_string_length(len)
      Rubinius.primitive :pointer_read_string
      raise PrimitiveFailure, "Unable to read string"
    end

    # Read bytes from the memory pointed to until a NULL is seen, return
    # the bytes as a String
    def read_string_to_null
      Rubinius.primitive :pointer_read_string_to_null
      raise PrimitiveFailure, "Unable to read string to null"
    end

    # Read bytes as a String from the memory pointed to
    def read_string(len=nil)
      if len
        read_string_length(len)
      else
        read_string_to_null
      end
    end

    # FFI compat methods
    def get_bytes(offset, length)
      (self + offset).read_string_length(length)
    end

    # Write String +str+ as bytes into the memory pointed to. Only
    # write up to +len+ bytes.
    def write_string_length(str, len)
      Rubinius.primitive :pointer_write_string
      raise PrimitiveFailure, "Unable to write string"
    end

    # Write a String +str+ as bytes to the memory pointed to.
    def write_string(str, len=nil)
      len = str.size unless len

      write_string_length(str, len);
    end

    # Read a sequence of types +type+, length +length+, using method +reader+
    def read_array_of_type(type, reader, length, signed=nil)
      # If signed is not nil and is actually a boolean,
      # then use that as an argument to the reader, which
      # is then assumed to support signed reading.
      args = []
      args = [signed] if !signed.nil?

      # Build up the array
      ary = []
      size = FFI.type_size(FFI.find_type type)
      tmp = self
      length.times {
        ary << tmp.send(reader, *args)
        tmp += size
      }
      ary
    end

    # Write a sequence of types +type+  using method +reader+ from +ary+
    def write_array_of_type(type, writer, ary)
      size = FFI.type_size(FFI.find_type type)
      tmp = self
      ary.each do |i|
        tmp.send(writer, i)
        tmp += size
      end
      self
    end

    # Read bytes from +offset+ from the memory pointed to as type +type+
    def get_at_offset(offset, type)
      Rubinius.primitive :pointer_get_at_offset
      raise PrimitiveFailure, "get_field failed"
    end

    # Write +val+ as type +type+ to bytes from +offset+
    def set_at_offset(offset, type, val)
      Rubinius.primitive :pointer_set_at_offset
      raise PrimitiveFailure, "set_field failed"
    end

    # Number of bytes taken up by a pointer.
    def self.size
      Rubinius::WORDSIZE / 8
    end

    # Primitive methods
    def primitive_read_char(signed=true)
      Rubinius.primitive :pointer_read_char
      raise PrimitiveFailure, "Unable to read char"
    end

    def primitive_write_char(obj)
      Rubinius.primitive :pointer_write_char
      raise PrimitiveFailure, "Unable to write char"
    end

    def primitive_read_short(signed=true)
      Rubinius.primitive :pointer_read_short
      raise PrimitiveFailure, "Unable to read short"
    end

    def primitive_write_short(obj)
      Rubinius.primitive :pointer_write_short
      raise PrimitiveFailure, "Unable to write short"
    end

    def primitive_read_int(signed=true)
      Rubinius.primitive :pointer_read_int
      raise PrimitiveFailure, "Unable to read int"
    end

    def primitive_write_int(obj)
      Rubinius.primitive :pointer_write_int
      raise PrimitiveFailure, "Unable to write int"
    end

    def primitive_read_long(signed=true)
      Rubinius.primitive :pointer_read_long
      raise PrimitiveFailure, "Unable to read long"
    end

    def primitive_write_long(obj)
      Rubinius.primitive :pointer_write_long
      raise PrimitiveFailure, "Unable to write long"
    end

    def primitive_read_long_long(signed=true)
      Rubinius.primitive :pointer_read_long_long
      raise PrimitiveFailure, "Unable to read long"
    end

    def primitive_write_long_long(obj)
      Rubinius.primitive :pointer_write_long_long
      raise PrimitiveFailure, "Unable to write long_long"
    end

    def primitive_read_float
      Rubinius.primitive :pointer_read_float
      raise PrimitiveFailure, "Unable to read float"
    end

    def primitive_write_float(obj)
      Rubinius.primitive :pointer_write_float
      raise PrimitiveFailure, "Unable to write float"
    end

    def primitive_read_double
      Rubinius.primitive :pointer_read_double
      raise PrimitiveFailure, "Unable to read double"
    end

    def primitive_write_double(obj)
      Rubinius.primitive :pointer_write_double
      raise PrimitiveFailure, "Unable to write double"
    end

    def primitive_read_pointer
      Rubinius.primitive :pointer_read_pointer
      raise PrimitiveFailure, "Unable to read pointer"
    end
  end

  class MemoryPointer < Pointer

    # call-seq:
    #   MemoryPointer.new(num) => MemoryPointer instance of <i>num</i> bytes
    #   MemoryPointer.new(sym) => MemoryPointer instance with number
    #                             of bytes need by FFI type <i>sym</i>
    #   MemoryPointer.new(obj) => MemoryPointer instance with number
    #                             of <i>obj.size</i> bytes
    #   MemoryPointer.new(sym, count) => MemoryPointer instance with number
    #                             of bytes need by length-<i>count</i> array
    #                             of FFI type <i>sym</i>
    #   MemoryPointer.new(obj, count) => MemoryPointer instance with number
    #                             of bytes need by length-<i>count</i> array
    #                             of <i>obj.size</i> bytes
    #   MemoryPointer.new(arg) { |p| ... }
    #
    # Both forms create a MemoryPointer instance. The number of bytes to
    # allocate is either specified directly or by passing an FFI type, which
    # specifies the number of bytes needed for that type.
    #
    # The form without a block returns the MemoryPointer instance. The form
    # with a block yields the MemoryPointer instance and frees the memory
    # when the block returns. The value returned is the value of the block.
    #
    def self.new(type, count=nil, clear=true)
      if type.kind_of? Fixnum
        size = type
      elsif type.kind_of? Symbol
        type = FFI.find_type type
        size = FFI.type_size(type)
      else
        size = type.size
      end

      if count
        total = size * count
      else
        total = size
      end

      ptr = malloc total
      ptr.total = total
      ptr.type_size = size
      FFI::Platform::POSIX.memset ptr, 0, total if clear

      if block_given?
        begin
          value = yield ptr
        ensure
          ptr.free
        end

        return value
      else
        ptr.autorelease = true
        ptr
      end
    end

    def self.malloc(total)
      Rubinius.primitive :pointer_malloc
      raise PrimitiveFailure, "Pointer.malloc failed"
    end

    def self.from_string(str)
      ptr = new str.bytesize + 1
      ptr.write_string str + "\0"

      ptr
    end

    def copy
      other = malloc total
      other.total = total
      other.type_size = type_size
      FFI::Platform::POSIX.memcpy other, self, total

      Rubinius.privately do
        other.initialize_copy self
      end

      other
    end

    # Indicates how many bytes the chunk of memory that is pointed to takes up.
    attr_accessor :total

    # Indicates how many bytes the type that the pointer is cast as uses.
    attr_accessor :type_size

    # Access the MemoryPointer like a C array, accessing the +which+ number
    # element in memory. The position of the element is calculate from
    # +@type_size+ and +which+. A new MemoryPointer object is returned, which
    # points to the address of the element.
    #
    # Example:
    #   ptr = MemoryPointer.new(:int, 20)
    #   new_ptr = ptr[9]
    #
    # c-equiv:
    #   int *ptr = (int*)malloc(sizeof(int) * 20);
    #   int *new_ptr;
    #   new_ptr = &ptr[9];
    #
    def [](which)
      raise ArgumentError, "unknown type size" unless @type_size
      self + (which * @type_size)
    end

    # Release the memory pointed to back to the OS.
    def free
      self.autorelease = false
      FFI::Platform::POSIX.free(self) unless null?
    end

    ##
    # If +val+ is true, this MemoryPointer object will call
    # free() on it's address when it is garbage collected.
    def autorelease=(val)
      Rubinius.primitive :pointer_set_autorelease
      raise PrimitiveFailure, "Unable to change autorelease"
    end

  end

  class DynamicLibrary::Symbol < Pointer
    def initialize(library, ptr, name)
      @library = library
      @name = name
      self.address = ptr.address
    end

    def inspect
      "#<FFI::Library::Symbol name=#{@name} address=#{address.to_s(16)}>"
    end
  end

  class Function < Pointer
    def initialize(ret_type, arg_types, val=nil, options=nil, &block)
      if block
        if val or options
          raise ArgumentError, "specify a block or a proc/address, not both"
        end

        val = block
      end

      args = arg_types.map { |x| FFI.find_type(x) }
      ret =  FFI.find_type(ret_type)

      if val.kind_of? Pointer
        @function = FFI.generate_function(val, :func, args, ret)
        self.address = val.address
      elsif val.respond_to? :call
        @function, ptr = FFI.generate_trampoline(val, :func, args, ret)
        self.address = ptr.address
      else
        raise ArgumentError, "value wasn't a FFI::Pointer and didn't respond to call"
      end

      # Hook the created function into the method_table so that #call goes
      # straight to it.
      sc = Rubinius::Type.object_singleton_class(self)
      sc.method_table.store :call, @function, :public
    end

    attr_reader :function

    # Hook this Function up to be an instance/class method +name+ on +mod+
    def attach(mod, name)
      unless mod.kind_of?(Module)
        raise TypeError, "mod must be a Module"
      end

      name = name.to_sym

      # Make it available as a method callable directly..
      sc = Rubinius::Type.object_singleton_class(mod)
      sc.method_table.store name, @function, :public

      # and expose it as a private method for people who
      # want to include this module.
      mod.method_table.store name, @function, :public
    end
  end
end

