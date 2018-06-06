a10_client = A10Client::client_factory(host, port, protocol, username, password)

a10_router_ipv6_ospf_area 'exampleName' do
    area_ipv4 "10.0.0.1"

    client a10_client
    action :create
end

a10_router_ipv6_ospf_area 'exampleName' do
    area_ipv4 "10.0.0.1"

    client a10_client
    action :update
end

a10_router_ipv6_ospf_area 'exampleName' do
    area_ipv4 "10.0.0.1"

    client a10_client
    action :delete
end