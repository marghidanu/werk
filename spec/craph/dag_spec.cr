require "../spec_helper"

describe Craph::DAG do
  it "should detect acyclic graph" do
    dag = Craph::DAG(String).new
    dag.add_edge("a", "b")
    dag.add_edge("b", "c")

    dag.acyclic?.should be_true
  end

  it "should detect cyclic graph" do
    dag = Craph::DAG(String).new
    dag.add_edge("a", "b")
    dag.add_edge("b", "a")

    dag.acyclic?.should be_false
  end

  it "should detect cycle in larger graph" do
    dag = Craph::DAG(String).new
    dag.add_edge("a", "b")
    dag.add_edge("b", "c")
    dag.add_edge("c", "a")

    dag.acyclic?.should be_false
  end

  it "should perform a topological sort" do
    dag = Craph::DAG(String).new
    dag.add_edge("a", "c")
    dag.add_edge("b", "c")
    dag.add_edge("c", "d")

    plan = dag.topological_sort
    plan.should eq([Set{"a", "b"}, Set{"c"}, Set{"d"}])
  end

  it "should have empty topology" do
    dag = Craph::DAG(String).new

    plan = dag.topological_sort
    plan.empty?.should be_true
  end

  it "should fail on circular dependencies" do
    dag = Craph::DAG(String).new
    dag.add_edge("a", "b")
    dag.add_edge("b", "a")

    expect_raises(Exception, "Graph has a cycle!") do
      dag.topological_sort
    end
  end

  it "should treat empty graph as acyclic" do
    dag = Craph::DAG(String).new

    dag.acyclic?.should be_true
  end
end
