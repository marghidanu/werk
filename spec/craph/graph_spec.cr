require "../spec_helper"

describe Craph::Graph do
  it "should create an empty graph" do
    graph = Craph::Graph(String).new

    graph.empty?.should be_true
    graph.size.should eq 0
    graph.nodes.should be_empty
  end

  it "should add nodes" do
    graph = Craph::Graph(String).new
    graph.add_node("a")
    graph.add_node("b")

    graph.size.should eq 2
    graph.has_node?("a").should be_true
    graph.has_node?("b").should be_true
    graph.has_node?("c").should be_false
  end

  it "should add edges and auto-create nodes" do
    graph = Craph::Graph(String).new
    graph.add_edge("a", "b")

    graph.has_node?("a").should be_true
    graph.has_node?("b").should be_true
    graph.has_edge?("a", "b").should be_true
    graph.has_edge?("b", "a").should be_false
  end

  it "should return neighbors" do
    graph = Craph::Graph(String).new
    graph.add_edge("a", "b")
    graph.add_edge("a", "c")

    graph.neighbors("a").should eq Set{"b", "c"}
    graph.neighbors("b").should be_empty
  end

  it "should not duplicate nodes" do
    graph = Craph::Graph(String).new
    graph.add_node("a")
    graph.add_node("a")

    graph.size.should eq 1
  end

  it "should work with integer nodes" do
    graph = Craph::Graph(Int32).new
    graph.add_edge(1, 2)
    graph.add_edge(2, 3)

    graph.size.should eq 3
    graph.has_edge?(1, 2).should be_true
    graph.neighbors(1).should eq Set{2}
  end
end
