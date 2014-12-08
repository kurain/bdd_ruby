require "bdd_ruby/version"
require "bdd_ruby/BDD_WRAP"

class BDD
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
        Node.new(BDD_WRAP.send(arg[0] + '_bdd', self.node, other.node))
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
        self.node.send(arg[0])
      end
    end

    def count
      BDD_WRAP.Count(self.node, BDD_WRAP.BDD_VarUsed);
    end

    def if(literal)
      negated = (literal.node.GetID[0] == 1 ? true : false)
      varID = literal.node.Top
      if negated
        Node.new(self.node.At0(varID))
      else
        Node.new(self.node.At1(varID))
      end
    end

  end
end

class BDD
  class Literal < Node
    attr_reader :name, :id
    def initialize(varID, name)
      @id    = varID
      @name  = name
      @node  = BDD_WRAP.BDDvar(varID)
    end
  end
end

class BDD
  def initialize(init_size = 256, max_size = 2 ** 32 - 1)
    BDD_WRAP.BDD_Init(init_size, max_size)
    @name_table = {}
  end

  def literals(*names)
    names.map do |name|
      @name_table[name] ||= Proc.new{
        varID = BDD_WRAP.BDD_NewVar()
        Literal.new(varID,name)
      }.call
    end
  end
end
