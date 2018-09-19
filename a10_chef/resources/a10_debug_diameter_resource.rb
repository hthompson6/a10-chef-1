resource_name :a10_debug_diameter

property :a10_name, String, name_property: true
property :uuid, String

property :client, [Class, A10Client::ACOSClient]


action :create do
    client = new_resource.client
    a10_name = new_resource.a10_name
    post_url = "/axapi/v3/debug/"
    get_url = "/axapi/v3/debug/diameter"
    uuid = new_resource.uuid

    params = { "diameter": {"uuid": uuid,} }

    params[:"diameter"].each do |k, v|
        if not v 
            params[:"diameter"].delete(k)
        end
    end

    get_url = get_url % {name: a10_name}

    begin
        client.get(get_url)
    rescue RuntimeError => e
        converge_by('Creating diameter') do
            client.post(post_url, params: params)
        end
    end
end

action :update do
    client = new_resource.client
    a10_name = new_resource.a10_name
    url = "/axapi/v3/debug/diameter"
    uuid = new_resource.uuid

    params = { "diameter": {"uuid": uuid,} }

    params[:"diameter"].each do |k, v|
        if not v
            params[:"diameter"].delete(k)
        end
    end

    get_url = url % {name: a10_name}
    result = client.get(get_url)

    found_diff = false 
    result["diameter"].each do |k, v|
        if v != params[:"diameter"][k] 
            found_diff = true
        end
    end

    if found_diff
        converge_by('Updating diameter') do
            client.put(url, params: params)
        end
    end
end

action :delete do
    client = new_resource.client
    a10_name = new_resource.a10_name
    url = "/axapi/v3/debug/diameter"

    url = url % {name: a10_name} 

    result = client.get(url)
    if result
        converge_by('Deleting diameter') do
            client.delete(url)
        end
    end
end