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


module MockCodeManager
  RES_DIR = File.join(File.dirname(File.expand_path(__FILE__)), "..", "res")
  SSL_DIR = "/tmp/mock_code_manager_ssl"

  TOKEN_OK = "PUPPET_DEPLOY_OK"
  TOKEN_ALWAYS_FAIL = "PUPPET_DEPLOY_FAIL"
  JSON_OK=[{"environment"=>"production", "id"=>66, "status"=>"queued"}]
  JSON_BAD_TOKEN={"kind"=>"puppetlabs.rbac/token-revoked", "msg"=>"Authentication token has been revoked."}
  JSON_MISSING_TOKEN={"kind"=>"puppetlabs.rbac/user-unauthenticated", "msg"=>"Route requires authentication"}
  JSON_NO_ENVIRONMENTS_SPECIFIED=[]

  class MockCodeManager < Sinatra::Base
    post '/code-manager/v1/deploys' do
      json = JSON.parse(request.body.read)
      token = request.env['HTTP_X_AUTHENTICATION']
      if token
        if token == TOKEN_OK

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
