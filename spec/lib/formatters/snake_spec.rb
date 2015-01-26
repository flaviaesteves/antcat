# coding: UTF-8
require 'spec_helper'

require 'snake'

describe "array snaking" do
  it "should handle []" do
    expect([].snake(1)).to eq([])
  end
  it "should handle [1]" do
    expect([1].snake(1)).to eq([[1]])
  end

  it "should handle [1,2,3,4]" do
    expect([1,2,3,4].snake(2)).to eq([[1,3], [2,4]])
  end

  it "should handle empty cells" do
    expect([1,2,3,4,5].snake(2)).to eq([[1,4], [2,5], [3,nil]])
  end
end
