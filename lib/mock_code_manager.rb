#!/usr/bin/env ruby
#
# Copyright 2017 Geoff Williams for Declarative Systems PTY LTD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "mock_code_manager/version"
require 'sinatra/base'
require 'webrick'
require 'webrick/log'
require "webrick/https"
require 'rack'
require "json"
require "rugged"

module MockCodeManager
  RES_DIR = File.join(File.dirname(File.expand_path(__FILE__)), "..", "res")
  SSL_DIR = "/tmp/mock_code_manager_ssl"

  TOKEN_OK = "PUPPET_DEPLOY_OK"

  JSON_BAD_TOKEN={"kind"=>"puppetlabs.rbac/token-revoked", "msg"=>"Authentication token has been revoked."}
  JSON_MISSING_TOKEN={"kind"=>"puppetlabs.rbac/user-unauthenticated", "msg"=>"Route requires authentication"}
  JSON_NO_ENVIRONMENTS_SPECIFIED=[]
  TEST_REPO="https://github.com/geoffwilliams/puppet-control-test"
  JUNK_ID="deadbeefdeadbeef"
  IDOK=66
  STATUS_QUEUED = "queued"
  STATUS_COMPLETE = "complete"
  STATUS_FAILED = "failed"

  class MockCodeManager < Sinatra::Base
    def get_all_branches
      branches = {}
      output = %x(git ls-remote #{TEST_REPO})
      output.split("\n").each do |line|
        line_split = line.split(/\t/)
        if line_split.length == 2
          environment = line_split[1].split(/\//)[-1]
          revision = line_split[0]
          branches[environment] = revision
        else
          puts "skipped invalid input: #{line}"
        end
      end

      return branches
    end

    def get_deploy_all_json(wait)
      get_deploy_json(get_all_branches.keys.sort, wait)
    end

    def get_deploy_json(requested_branches, wait)
      json = []
      branches = get_all_branches
      id = IDOK
      requested_branches.each { |requested_branch|
        if branches.has_key? requested_branch
          if wait
            # in wait mode, sleep for a while to simulate a slow-ish server
            sleep(1 + rand(10))
            json << {
              "environment"=>requested_branch,
              "id"=>id,
              "status"=>STATUS_COMPLETE,
              "file-sync"=> {
                "environment-commit"=>JUNK_ID,
                "code-commit"=>JUNK_ID
              },
              "deploy-signature"=>branches[requested_branch]
            }
          else
            json << {
                "environment"=>requested_branch,
                "id"=>id,
                "status"=>STATUS_QUEUED
            }
          end
        else
          json << {
            "environment"=>requested_branch,
            "id"=>id,
            "status"=>STATUS_FAILED,
            "error"=>{
            "kind"=>"puppetlabs.code-manager/deploy-failure",
            "details"=>{
              "corrected-env-name"=>requested_branch},
              "msg"=>"Errors while deploying environment '#{requested_branch}' (exit code: 1):\nERROR\t -> Environment(s) '#{requested_branch}' cannot be found in any source and will not be deployed.\n"
            }
          }
        end
        id += 1
      }

      json
    end

    get '/' do
      <<~"END"
        <h1>Mock Code Manager</h1>
        <p>
        Mock control repository in use: <a href="#{TEST_REPO}">#{TEST_REPO}</a>
        </p>
        <pre>
        token: #{TOKEN_OK}
        environments: #{JSON.pretty_generate(get_all_branches)}
        </pre>
      END
    end

    post '/code-manager/v1/deploys' do
      json = JSON.parse(request.body.read)
      token = request.env['HTTP_X_AUTHENTICATION']
      wait = json.has_key?("wait") && json["wait"]
      environments = json["environments"]
      if token
        if token == TOKEN_OK

          # environments must be a non-empty array for code manager to do anything.
          # If missing it returns an empty array []
          if json["deploy-all"] == true
            resp = self.get_deploy_all_json(wait)
          elsif environments.empty?
            resp = JSON_NO_ENVIRONMENTS_SPECIFIED
          else
            resp = self.get_deploy_json(environments, wait)
          end
        else
          resp = JSON_BAD_TOKEN
        end
      else
        resp = JSON_MISSING_TOKEN
      end

      resp.to_json
    end
  end

  module WEBrick
    def self.run!
      system("#{RES_DIR}/setup_ssl.sh")

      # note - we obtain the fqdn by shelling out rather then doing tricks in ruby
      # this is for consistency with the openssl calls we already made to generate
      fqdn = %x(hostname -f).strip

      webrick_options = {
          :Host                 => "0.0.0.0",
          :Port                 => 8170,
          :Logger               => ::WEBrick::Log::new($stdout, ::WEBrick::Log::DEBUG),
          :SSLEnable            => true,
          :force_ssl            => true,
          :SSLCACertificateFile => "#{SSL_DIR}/certs/ca.pem",
          :SSLCertificate       => OpenSSL::X509::Certificate.new(  File.open("#{SSL_DIR}/certs/server.pem").read),
          :SSLPrivateKey        => OpenSSL::PKey::RSA.new(          File.open("#{SSL_DIR}/private_keys/server.pem").read),
          :SSLCertName          => [ [ "CN", fqdn] ]
      }

      Rack::Handler::WEBrick.run MockCodeManager, webrick_options
    end
  end
end
