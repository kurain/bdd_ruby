require "bdd_ruby/BDD_WRAP"
require "bdd_ruby/node_list"

require "tempfile"
require "Launchy"

class ZDD
  class Node
    attr_reader :node, :manager
    def initialize(node, manager)
      @node = node
      @manager = manager
    end

    # operators
    {
      intersection: ['and', :&],
      union: ['plus', :+],
      product: ['times', :*],
      minus:   ['minus', :|],
    }.each do |name, arg|
      define_method(name) do |other|
        Node.new(BDD_WRAP.send(arg[0] + '_zbdd', self.node, other.node), self.manager)
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
        Node.new(self.node.send(arg[0]), self.manager)
      end
    end

    def family
      ret = []
      @manager._family(self.node, [], ret)
      ret
    end

    def save(filename)
      temp = Tempfile.new(['zdd-', '.zdd'])
      fp = BDD_WRAP.fopen(temp.path,'w')
      self.node.Export(fp)
      BDD_WRAP.fclose(fp)

      symbols = self.manager.id_table[1..self.node.Top].map{|s| s.to_s}

      open(filename,'w') do |wio|
        wio.write(symbols.join(' ') + "\n")
        wio.write(temp.read)
      end
      temp.close
    end

    def show(filename=nil)
      zdd_file = filename || Tempfile.new(['zdd-', '.zdd'])
      self.save(zdd_file.path)

      dot = NodeList.new(zdd_file).to_dot
      dot.save(zdd_file.path, :svg)
      Launchy.open(zdd_file.path + '.svg')
      zdd_file.path + '.svg'
    end

  end
end

class ZDD
  class Literal < Node
    attr_reader :name
    def initialize(var_id, name, manager)
      @name = name
      @node = BDD_WRAP::ZBDD.new(1).Change(var_id)
      @manager = manager
    end
  end
end

class ZDD
  attr_accessor :id_table
  def initialize(init_size = 256, max_size = 2 ** 32 - 1)
    BDD_WRAP.BDD_Init(init_size, max_size)
    @name_table = {}
    @id_table = [nil]
  end

  def literals(*names)
    names.map do |name|
      @name_table[name] ||= Proc.new{
        var_id = BDD_WRAP.BDD_NewVar
        @id_table.push name
        Literal.new(var_id,name,self)
      }.call
    end
  end

  def _family(node, set, ret)
    id = node.GetID
    if id == BDD_WRAP::Bddsingle
      ret << set
      return
    elsif id == BDD_WRAP::Bddempty
      return
    end

    var_id = node.Top
    _family(node.OnSet0(var_id), set.dup.push(@id_table[var_id]), ret)
    _family(node.OffSet(var_id), set.dup, ret)
  end
end
