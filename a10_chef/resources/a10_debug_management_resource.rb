resource_name :a10_debug_management

property :a10_name, String, name_property: true
property :all, [true, false]
property :system, [true, false]
property :uuid, String

property :client, [Class, A10Client::ACOSClient]


action :create do
    client = new_resource.client
    a10_name = new_resource.a10_name
    post_url = "/axapi/v3/debug/"
    get_url = "/axapi/v3/debug/management"
    all = new_resource.all
    system = new_resource.system
    uuid = new_resource.uuid

    params = { "management": {"all": all,
        "system": system,
        "uuid": uuid,} }

    params[:"management"].each do |k, v|
        if not v 
            params[:"management"].delete(k)
        end
    end

    get_url = get_url % {name: a10_name}

    begin
        client.get(get_url)
    rescue RuntimeError => e
        converge_by('Creating management') do
            client.post(post_url, params: params)
        end
    end
end

action :update do
    client = new_resource.client
    a10_name = new_resource.a10_name
    url = "/axapi/v3/debug/management"
    all = new_resource.all
    system = new_resource.system
    uuid = new_resource.uuid

    params = { "management": {"all": all,
        "system": system,
        "uuid": uuid,} }

    params[:"management"].each do |k, v|
        if not v
            params[:"management"].delete(k)
        end
    end

    get_url = url % {name: a10_name}
    result = client.get(get_url)

    found_diff = false 
    result["management"].each do |k, v|
        if v != params[:"management"][k] 
            found_diff = true
        end
    end

    if found_diff
        converge_by('Updating management') do
            client.put(url, params: params)
        end
    end
end

action :delete do
    client = new_resource.client
    a10_name = new_resource.a10_name
    url = "/axapi/v3/debug/management"

    url = url % {name: a10_name} 

    result = client.get(url)
    if result
        converge_by('Deleting management') do
            client.delete(url)
        end
    end
end