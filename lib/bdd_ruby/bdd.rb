require "bdd_ruby/BDD_WRAP"
class BDD
  class Node
    attr_reader :node, :manager
    def initialize(node, manager)
      @node = node
      @manager = manager
    end

    # operators
    {
      conjoin: ['and', :&],
      disjoin: ['bar', :|],
      xor:     ['hat', :^],
    }.each do |name, arg|
      define_method(name) do |other|
        Node.new(BDD_WRAP.send(arg[0] + '_bdd', self.node, other.node), self.manager)
      end
      alias_method arg[1], name
    end

    def negate
      Node.new(~(self.node), self.manager)
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
        Node.new(self.node.At0(varID), self.manager)
      else
        Node.new(self.node.At1(varID), self.manager)
      end
    end

    def dnf
      ret = []
      @manager._dnf(self.node, [], ret)
      ret
    end

    def true?
      self.node.GetID == BDD_WRAP::Bddtrue
    end

    def false?
      self.node.GetID == BDD_WRAP::Bddfalse
    end
  end
end

class BDD
  class Literal < Node
    attr_reader :name, :id
    def initialize(varID, name, manager)
      @id    = varID
      @name  = name
      @node  = BDD_WRAP.BDDvar(varID)
      @manager = manager
    end
  end
end

class BDD
  def initialize(init_size = 256, max_size = 2 ** 32 - 1)
    BDD_WRAP.BDD_Init(init_size, max_size)
    @name_table = {}
    @id_table = {}
  end

  def literals(*names)
    names.map do |name|
      @name_table[name] ||= Proc.new{
        varID = BDD_WRAP.BDD_NewVar()
        @id_table[varID] = name
        Literal.new(varID,name, self)
      }.call
    end
  end

  def _dnf(node, conjs, ret)
    id = node.GetID
    if id == BDD_WRAP::Bddtrue
      ret << conjs
      return
    elsif id == BDD_WRAP::Bddfalse
      return
    end

    var_id = node.Top
    _dnf(node.At1(var_id), conjs.dup.push(@id_table[var_id]), ret)
    negate = ('!' + @id_table[var_id].to_s).to_sym
    _dnf(node.At0(var_id), conjs.dup.push(negate), ret)
  end
end
