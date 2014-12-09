require "bdd_ruby/BDD_WRAP"

class ZDD
  class Node
    attr_reader :node
    def initialize(node)
      @node = node
    end

    # operators
    {
      conjoin: ['and', :&],
      disjoin: ['bar', :|],
      xor:     ['hat', :^],
    }.each do |name, arg|
      define_method(name) do |other|
        Node.new(BDD_WRAP.send(arg[0] + '_zbdd', self.node, other.node))
      end
      alias_method arg[1], name
    end

    def negate
      Node.new(~(self.node))
    end
    alias ! negate

    # attributes
    {size: ['Size'], print: ['Print'] }.each do |name, arg|
      define_method(name) do
        Node.new(self.node.send(arg[0]))
      end
    end

  end
end

class ZDD
  class Literal < Node
    attr_reader :name
    def initialize(varID, name)
      @name = name
      @node = BDD_WRAP::ZBDD.new(1).Change(varID)
    end
  end
end

class ZDD
  def initialize(init_size = 256, max_size = 2 ** 32 - 1)
    BDD_WRAP.BDD_Init(init_size, max_size)
    @name_table = {}
  end

  def literals(*names)
    names.map do |name|
      @name_table[name] ||= Proc.new{
        varID = BDD_WRAP.BDD_NewVar
        Literal.new(varID,name)
      }.call
    end
  end
end
