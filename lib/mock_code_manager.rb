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


module MockCodeManager
  RES_DIR = File.join(File.dirname(File.expand_path(__FILE__)), "..", "res")
  JSON_DIR = File.join(RES_DIR, "json")
  SSL_DIR = File.join(RES_DIR, "ssl")

  TOKEN_OK = "PUPPET_DEPLOY_OK"
  TOKEN_ALWAYS_FAIL = "PUPPET_DEPLOY_FAIL"
  JSON_OK=[{"environment"=>"production", "id"=>66, "status"=>"queued"}]
  JSON_BAD_TOKEN={"kind"=>"puppetlabs.rbac/token-revoked", "msg"=>"Authentication token has been revoked."}
  JSON_MISSING_TOKEN={"kind"=>"puppetlabs.rbac/user-unauthenticated", "msg"=>"Route requires authentication"}
  JSON_NO_ENVIRONMENTS_SPECIFIED=[]


  class MockCodeManager < Sinatra::Base
    post '/code-manager/v1/deploys' do
      json = JSON.parse(request.body.read)

      if json.has_key?("token")

        if json["token"] == TOKEN_OK

          # environments must be a non-empty array for code manager to do anything.
          # If missing it returns an empty array []
          if json["deploy-all"] == true
            resp = JSON_OK
          elsif json["environments"].empty?
            resp = JSON_NO_ENVIRONMENTS_SPECIFIED
          else
            resp = []
            i=66
            json["environments"].each { |environment|
              resp.push({"environment"=>environment, "id"=>i, "status"=>"queued"})
              i += 1
            }
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
      webrick_options = {
          :Port                 => 8170,
          :Logger               => ::WEBrick::Log::new($stdout, ::WEBrick::Log::DEBUG),
          :SSLEnable            => true,
          :force_ssl            => true,
          :SSLVerifyClient      => OpenSSL::SSL::VERIFY_PEER,
          :SSLCACertificateFile => "#{SSL_DIR}/certs/ca.pem",
          :SSLCertificate       => OpenSSL::X509::Certificate.new(  File.open("#{SSL_DIR}/certs/localhost.pem").read),
          :SSLPrivateKey        => OpenSSL::PKey::RSA.new(          File.open("#{SSL_DIR}/private_keys/localhost.pem").read),
          :SSLCertName          => [ [ "CN",'localhost' ] ]
      }

      Rack::Handler::WEBrick.run MockCodeManager, webrick_options
    end
  end
end
