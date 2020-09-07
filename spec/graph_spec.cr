require "./spec_helper"

describe Werk::Utils do
  it "should create an empty graph" do
    graph = Werk::Utils::Graph.new

    graph.get_vertices.size.should eq 0
  end

  it "should add vertices via edges" do
    g = Werk::Utils::Graph.new
    g.add_edge("a", "b")

    vertices = g.get_vertices
    vertices.should eq(["a", "b"])
  end

  it "should perform a topological sort" do
    graph = Werk::Utils::Graph.new
    graph.add_edge("a", "c")
    graph.add_edge("b", "c")
    graph.add_edge("c", "d")

    plan = graph.topological_sort
    plan.should eq([["a", "b"], ["c"], ["d"]])
  end

  it "should have empty topology" do
    g = Werk::Utils::Graph.new

    plan = g.topological_sort
    plan.empty?.should be_true
  end

  it "should fail on circular dependencies" do
    g = Werk::Utils::Graph.new
    g.add_edge("a", "b")
    g.add_edge("b", "a")

    expect_raises(Exception, "Graph has a cycle!") do
      g.topological_sort
    end
  end
end
