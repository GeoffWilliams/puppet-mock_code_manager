require "spec_helper"

RSpec.describe MockCodeManager do
  it "has a version number" do
    expect(MockCodeManager::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
