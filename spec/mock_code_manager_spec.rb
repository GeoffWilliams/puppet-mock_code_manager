require "spec_helper"

RSpec.describe MockCodeManager do
  it "has a version number" do

        curl -k -X POST -H 'Content-Type: application/json' \
        -H "X-Authentication: PUPPET_DEPLOY_OK" \
        "https://computer:8170/code-manager/v1/deploys" \
        -d '{"environments": ["production"], "wait": true}'

    expect(MockCodeManager::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
