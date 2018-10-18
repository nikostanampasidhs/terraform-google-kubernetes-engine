# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'kubeclient'
require 'rest-client'

require 'base64'

kubernetes_endpoint = attribute('kubernetes_endpoint')
client_token = attribute('client_token')

control "kubectl" do
  title "Kubernetes configuration"

  describe "kubernetes" do
    let(:kubernetes_http_endpoint) { "https://#{kubernetes_endpoint}/api" }
    let(:client) do
      Kubeclient::Client.new(
        kubernetes_http_endpoint,
        "v1",
        ssl_options: {
          verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        },
        auth_options: {
          bearer_token: Base64.decode64(client_token),
        },
      )
    end

    describe "services" do
      describe "nginx" do
        let(:service) { client.get_service("terraform-example", "default") }
        let(:service_load_balancer_ip) { service.status.loadBalancer.ingress.first.ip }
        let(:service_load_balancer_address) { "http://#{service_load_balancer_ip}:8080" }

        it "exists" do
          expect(service).not_to be_nil
        end

        it "has an IP address" do
          expect(service_load_balancer_ip).not_to be_nil
        end

        it "is reachable" do
          expect {
            RestClient.get(service_load_balancer_address)
          }.to_not raise_exception
        end
      end
    end
  end
end
