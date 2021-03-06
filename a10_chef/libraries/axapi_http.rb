# Copyright 2018,  A10 Networks.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

require 'http'

require_relative 'errors'
require_relative 'responses'

module A10Client

    class HttpClient
        @@HEADERS = {
            "Content-Type"  => "application/json",
            "User-Agent" => "a10-chef"
        }

        attr_reader :url_base   
 
        def initialize(host, protocol="https", port=nil, timeout=nil,
                       retry_errno_list=nil)
            @host = host
            @timeout = timeout
            if port == nil
                if protocol == "https"
                    p = 443
                else
                    p  = 80
                end
            else
                p = port
            end
            @url_base = "#{protocol}://#{@host}:#{p}"
            @rety_errno_list = retry_errno_list
        end
    
        def request(method, api_url, params: {}, headers: nil, filename: nil,
                    file_content: nil, axapi_args: nil, **kwargs)
    
            if axapi_args != nil
                formatted_axapi_args = (axapi_args.map.each {|pair| pair.map{|x| x.gsub("-", "_")}}).to_h
                params.merge!(formatted_axapi_args)
            end
    
            if (filename != nil || file_content != nil) && !(filename != nil && file_content != nil)
                raise 'file_name and file_content must both be populated if one is'
            end
    
            hdrs = @@HEADERS.dup
            if headers != nil
                hdrs.merge!(headers)
            end
   
            if params
                params_copy = params.dup
                params_copy.merge!(kwargs)
                payload=params_copy
            else
                payload = nil
            end

            if filename != nil
               # files = {
                    # "file" => ,
                    # "json" => , 
               # }
               # hdrs.delete("Content-type")
               # hdrs.delete("Content-Type")
            end


            begin
                last_e = nil
                if filename != nil
                    z = nil
                else
                    case method
                    when "GET"
                        hdrs.delete("Content-Type")
                        hdrs[:accept] = "application/json"
                        z = HTTP.headers(hdrs).get(@url_base + api_url)
                    when "POST"
                        z = HTTP.headers(hdrs).post(@url_base + api_url,
                                                    :json => payload)
                    when "PUT"
                        z = HTTP.headers(hdrs).put(@url_base + api_url,
                                                   :json => payload)
                    when "DELETE"
                        z = HTTP.headers(hdrs).delete(@url_base + api_url)
                    end
                end
            rescue SocketError => e
               raise e
            end

            if z.code == 204
                return nil
            end

            # (TODO)  Missing logic here. Re-implement later
            r = z.parse 
            if r['response'] && r['response']['status'] == 'fail'
                ErrorResp::raise_axapi_ex(r, method, api_url)
            end
    
            if r['authorizationschema']
                ErrorResp::raise_axapi_auth_error(r, method, api_url, headers)
            end
    
            return r
         end

        def get(url, params: {}, **kwargs)
            return request("GET", url, params: params, **kwargs)
        end

        def post(url, params: {}, **kwargs)
            return request("POST", url, params: params, **kwargs)
        end

        def put(url, params: {}, **kwargs)
            return request("PUT", url, params: params, **kwargs)
        end

        def delete(url, params: {}, **kwargs)
            return request("DELETE", url, params: params, **kwargs)
        end

    end
    

    class Session
    
        attr_reader :http
    
        def initialize(http, username, password)
            @http = http
            @username = username
            @password = password
            @session_id = nil
        end

        def close()
            if @session_id == nil
                return nil
            end

           begin
               h = {"Authorization" => "A10 #{@session_id}"}
               r = HTTP.headers(h).post(@http.url_base + "/axapi/v3/logoff")
           ensure
               @session_id = nil
           end
        end

        def authenticate(username, password)
            url = "/axapi/v3/auth"
            payload = {
                :credentials => {
                    :username => username,
                    :password => password
                }
            }
    
            if @session_id != nil
                close()
            end
  
            response = @http.post(url, params: payload)
            if response['authresponse'] && response['authresponse']['signature']
                @session_id = response['authresponse']['signature']
            else
                @session_id = nil
            end
    
            return response
        end
    
        def get_auth_header
            authenticate(@username, @password)
            return {"Authorization" =>  "A10 #{@session_id}"}
        end
    end

    class ACOSClient
        def initialize(session)
            @session = session
        end
    
        def _request(method, url, params: {}, **kwargs)
            return @session.http.request(method, url, params: params,
                                         headers: @session.get_auth_header(),
                                         **kwargs)
        rescue AE::InvalidSessionID => e
            raise e
        end
    
        def get(url, params: {}, **kwargs)
            return _request("GET", url, params: params, **kwargs)
        end
    
        def post(url, params: {}, **kwargs)
            if params != {}
                return _request("POST", url % params[params.keys[0]], params: params, **kwargs)
            end
            return _request("POST", url, params: params, **kwargs)
        end
    
        def put(url, params: {}, **kwargs)
            if params != {}
                return _request("PUT", url % params[params.keys[0]], params: params, **kwargs)
            end
            return _request("PUT", url, params: params, **kwargs)
        end
    
        def delete(url, params: {}, **kwargs)
            return _request("DELETE", url, params: params, **kwargs)
        end
    end
    
    def self.http_factory(host, port, protocol)
        return HttpClient.new(host, port, protocol)
    end
    
    def self.session_factory(http, username, password)
        return Session.new(http, username, password)
    end
    
    def self.client_factory(host, port, protocol, username, password)
        http_cli = http_factory(host, port, protocol)
        session = session_factory(http_cli, username, password)
        return ACOSClient.new(session)
    end
end
