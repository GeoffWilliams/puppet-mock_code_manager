require "spec_helper"
require 'mock_code_manager'
require "excon"
require "thread"
require "json"
require "time"

# Example curl request for manual testing
#   curl -k -X POST -H 'Content-Type: application/json' \
#       -H "X-Authentication: PUPPET_DEPLOY_OK" \
#       "https://computer:8170/code-manager/v1/deploys" \
#       -d '{"environments": ["production"], "wait": true}'
RSpec.describe MockCodeManager do

  BASE_URL = "https://localhost:8170"
  TOKEN_URL = "#{BASE_URL}/token"
  DEPLOYS_URL = "#{BASE_URL}/code-manager/v1/deploys"

  before(:all) do
    thread = Thread.start{MockCodeManager::WEBrick.run!}
    thread.abort_on_exception = true
    Excon.defaults[:ssl_verify_peer] = false

    # wait for server to boot before testing
    sleep(5)


  end

  after(:all) do
    # the server will exit on its own as the system comes down
  end

  it "info site works" do
    resp = Excon.get(BASE_URL)
    expect(resp.status).to eq(200)
  end

  it "deploys selected environments - no wait" do
    payload = {
      "environments" => ["production", "development"],
    }
    headers = {
        "accept"            => "application/json",
        "X-Authentication"  => MockCodeManager::TOKEN_OK
    }
    resp = Excon.post(DEPLOYS_URL, :body => payload.to_json, :headers => headers)
    expect(resp.status).to eq(200)
    json = JSON.parse(resp.body)

    expect(json[0]["environment"]).to eq("production"), JSON.pretty_generate(json)
    expect(json[0]["status"]).to eq(MockCodeManager::STATUS_QUEUED), JSON.pretty_generate(json)
    expect(json[1]["environment"]).to eq("development"), JSON.pretty_generate(json)
    expect(json[1]["status"]).to eq(MockCodeManager::STATUS_QUEUED), JSON.pretty_generate(json)
  end

  it "deploys selected environments - wait" do
    payload = {
        "environments"  => ["production", "development"],
        "wait"          => true,
    }
    headers = {
        "accept"            => "application/json",
        "X-Authentication"  => MockCodeManager::TOKEN_OK
    }

    resp = Excon.post(
        DEPLOYS_URL,
        :body => payload.to_json,
        :headers => headers
    )
    expect(resp.status).to eq(200)
    json = JSON.parse(resp.body)
    expect(json[0]["environment"]).to eq("production"), JSON.pretty_generate(json)
    expect(json[0]["status"]).to eq(MockCodeManager::STATUS_COMPLETE), JSON.pretty_generate(json)
    expect(json[1]["environment"]).to eq("development"), JSON.pretty_generate(json)
    expect(json[1]["status"]).to eq(MockCodeManager::STATUS_COMPLETE), JSON.pretty_generate(json)
  end


  it "deploys all environments - no wait" do
    payload = {
        "deploy-all" => true
    }
    headers = {
        "accept"            => "application/json",
        "X-Authentication"  => MockCodeManager::TOKEN_OK
    }
    resp = Excon.post(
        DEPLOYS_URL,
        :body => payload.to_json,
        :headers => headers
    )
    expect(resp.status).to eq(200)
    json = JSON.parse(resp.body)

    # just check we got at least one environment back
    expect(json[0]["status"]).to eq(MockCodeManager::STATUS_QUEUED), JSON.pretty_generate(json)
  end

  it "deploys all environments" do
    payload = {
        "deploy-all"  => true,
        "wait"        => true
    }
    headers = {
        "accept"            => "application/json",
        "X-Authentication"  => MockCodeManager::TOKEN_OK
    }
    resp = Excon.post(
        DEPLOYS_URL,
        :body => payload.to_json,
        :headers => headers
    )
    expect(resp.status).to eq(200)
    json = JSON.parse(resp.body)

    # just check we got at least one environment back
    expect(json[0]["status"]).to eq(MockCodeManager::STATUS_COMPLETE), JSON.pretty_generate(json)
  end

  it "errors on deploy missing environment - wait" do
    payload = {
        "environments"  => ["nothere"],
        "wait"          => true
    }
    headers = {
        "accept"            => "application/json",
        "X-Authentication"  => MockCodeManager::TOKEN_OK
    }
    resp = Excon.post(
        DEPLOYS_URL,
        :body => payload.to_json,
        :headers => headers
    )
    expect(resp.status).to eq(200)
    json = JSON.parse(resp.body)
    expect(json[0]["environment"]).to eq("nothere"), JSON.pretty_generate(json)
    expect(json[0]["status"]).to eq(MockCodeManager::STATUS_FAILED), JSON.pretty_generate(json)

  end

  it "errors on bad token" do
    payload = {}
    headers = {
        "accept"            => "application/json",
        "X-Authentication"  => "bad_token"
    }
    resp = Excon.post(
        DEPLOYS_URL,
        :body => payload.to_json,
        :headers => headers
    )
    expect(resp.status).to eq(200)
    json = JSON.parse(resp.body)

    expect(json["kind"]).to eq(MockCodeManager::JSON_BAD_TOKEN["kind"]), JSON.pretty_generate(json)
  end

  it "errors on missing token" do
    headers = {
        "accept" => "application/json",
    }
    payload = {}
    resp = Excon.post(
        DEPLOYS_URL,
        :body => payload.to_json,
        :headers => headers
    )
    expect(resp.status).to eq(200)
    json = JSON.parse(resp.body)

    expect(json["kind"]).to eq(MockCodeManager::JSON_MISSING_TOKEN["kind"]), JSON.pretty_generate(json)
  end
end
