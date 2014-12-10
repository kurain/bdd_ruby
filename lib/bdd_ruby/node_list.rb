# -*- coding: utf-8 -*-
require 'Gviz'

class NodeList
  class Node
    attr_accessor :addr, :level, :ze, :oe
    def initialize(addr, level, ze, oe)
      self.addr = addr
      self.level = level
      self.ze = ze
      self.oe = oe
    end

    def is_sink?
      self.level == 0
    end
  end

  attr_accessor :nodes, :toplevel, :level2nodes, :max_nodes, :addr2node,
                :used_count, :level2symbols

  def initialize(vsopexportfile=nil)
    self.base_setup
    self.add_sink_nodes
    if vsopexportfile != nil
      self.read_vsop_export(vsopexportfile.readlines)
      self.expand_negative_edges
      vsopexportfile.close
    end
  end

  def base_setup
    self.nodes         = []
    self.level2nodes   = {}
    self.toplevel      = nil
    self.addr2node     = {}
    self.used_count    = {}
    self.level2symbols = []
  end

  def add_sink_nodes
    self.add_node('T', 0, 'T', 'T')
    self.add_node('F', 0, 'F', 'F')
    self.inc_used_count('T')
    self.inc_used_count('F')
  end

  def inc_used_count(addr)
    self.used_count[addr] ||= 1
    self.used_count[addr] += 1
  end

  def dec_used_count(addr)
    self.used_count[addr] -= 1
  end

  def add_node(addr, level, ze, oe)
    node = Node.new(addr, level, ze, oe)
    self.nodes.push(node)
    self.addr2node[addr] = node

    self.level2nodes[level] ||= []
    self.level2nodes[level].push(node)
    return node
  end

  def expand_negative_edges
    (0..self.toplevel).reverse_each do |lv|
      next unless self.level2nodes[lv]
      self.level2nodes[lv].each do |node|
        if self.used_count[node.addr].nil? or self.used_count[node.addr] <= 0
          self.dec_used_count(node.ze)
          self.dec_used_count(node.oe)
          next
        end

        # in case the node is inversion node
        if !node.is_sink? and (node.addr.to_i % 2 == 1)
          if node.ze == 'F'
            # zero-edges of inversion nodes point the 1-sink
            node.ze = 'T'
          elsif node.ze == 'T'
            # pass
          elsif node.ze.to_i % 2 == 0
            # descendants of an inversion node are also inversion nodes
            olddstaddr, newdstaddr = node.ze, (node.ze.to_i + 1).to_s
            node.ze = newdstaddr
            self.dec_used_count(olddstaddr)
            self.inc_used_count(newdstaddr)
          end
        end

        [node.oe, node.ze].each do |dstaddr|
          if self.addr2node[dstaddr].nil?
            if dstaddr != 'T' and dstaddr != 'F' and dstaddr.to_i >= 0
              cnode   = self.addr2node[(dstaddr.to_i - 1).to_s]
              newnode = self.add_node(dstaddr, cnode.level, cnode.ze, cnode.oe)
              self.inc_used_count(newnode.ze)
              self.inc_used_count(newnode.oe)
            end
          end
        end
      end
    end
    self.gc
  end

  def gc
    garbages = []
    (1..self.toplevel).each do |lv|
      next if self.level2nodes[lv].nil?

      self.level2nodes[lv].each do |node|
        garbages.push(node) if (self.used_count[node.addr] || 0) <= 0
      end

      garbages.each do |node|
        self.nodes.delete(node)
        self.level2nodes[node.level].delete(node)
        self.used_count.delete(node.addr)
        self.addr2node.delete(node.addr)
      end
    end
  end

  def read_vsop_export(lines)
    symbols = []
    idx = 0
    while lines[idx].index('_i') != 0
      symbols += lines[idx].rstrip.split
      idx += 1
    end
    # _i
    raise "Should be start with _i #{lines[idx]}" if lines[idx].index('_i') != 0
    self.toplevel = lines[idx].rstrip.split[1].to_i + 1
    idx += 1

    unless symbols.empty?
      raise "Too many simbols" unless symbols.size == self.toplevel - 1
      symbols.reverse!
      self.level2symbols = [0] + symbols
    end

    # _o
    idx += 1
    # _n
    raise "Should be start with _n #{lines[idx]}" if lines[idx].index('_n') != 0
    self.max_nodes = lines[idx].rstrip.split[1].to_i
    idx += 1

    numtops = 0
    lines[idx..-1].each do |line|
      columns = line.rstrip.split
      if columns.size == 1
        myaddr = -2 * (numtops + 2)
        if columns[0].to_i != 0
          oedest = columns[0].to_i
          if oedest % 2 != 0
            myaddr += 1
          end
        else
          oedest = columns[0]
        end
        numtops += 1
        self.add_node(myaddr.to_s, self.toplevel, -1.to_s, oedest.to_s)
        self.inc_used_count(myaddr.to_s)
        self.inc_used_count(oedest.to_s)

      elsif columns.size == 4
        addr  = columns[0].to_i
        level = columns[1].to_i
        ze = columns[2]
        oe = columns[3]

        self.add_node(addr.to_s, level, ze, oe)
        self.inc_used_count(ze)
        self.inc_used_count(oe)
      end
    end
  end

  def to_dot(args={})
    gv = Gviz.new
    nodelist = self
    gv.graph do
      label = args[:label] || ""
      global(label: label, labelloc: 't', ranksep: (args[:ranksep] || 0.4))

      value = 1
      tops = nodelist.level2nodes[nodelist.toplevel]
      tops.each do |t|
        node t.addr.to_sym, label: value, style: 'filled'
        value *= -2
        # 1-edges (note: tops do not have 0-edges)
        edge "#{t.addr}_#{t.oe}".to_sym
      end

      # rank = same for tops
      rank :same, *(tops.map{|x| x.addr.to_sym}) if tops.size > 1

      ### usual nodes
      (1..nodelist.toplevel - 1).reverse_each do |lv|
        next if nodelist.level2nodes[lv].nil?
        drawn = []
        nodelist.level2nodes[lv].each do |n|
          name = nodelist.level2symbols.empty? ? n.level : nodelist.level2symbols[n.level]
          nodelabel = args[:address] ? "#{name}:#{n.addr}" : name
          node n.addr.to_sym, label: nodelabel
          drawn.push n.addr.to_sym

          # edge
          if args[:omittosink] and n.ze == 'F'
            node "z#{n.addr}".to_sym, shape: 'none', label: ""
            edge "#{n.addr}_z#{n.addr}".to_sym, label: "", style: 'dashed', arrowhead: 'onormal'
          else
            edge "#{n.addr}_#{n.ze}".to_sym, label: "", style: 'dashed', arrowhead: 'onormal'
          end
          if args[:omittosink] and node.oe == 'T'
            node "t#{n.addr}".to_sym, shape: 'none', label: ''
            edge "#{n.addr}_t#{n.addr}", label: ''
          else
            edge "#{n.addr}_#{n.oe}"
          end
        end

        rank :same, *drawn if drawn.size >= 1
      end

      ### sinks
      # sink nodes labels
      node :T, label: 'T', fontsize: 20, shape: 'box', style: 'filled'
      node :F, label: 'F', fontsize: 20, shape: 'box', style: 'filled'
      rank :same, :T, :F
    end
    gv
  end
end
