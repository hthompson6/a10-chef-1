resource_name :a10_cgnv6_ds_lite_alg_rtsp

property :a10_name, String, name_property: true
property :uuid, String
property :rtsp_enable, ['enable']

property :client, [Class, A10Client::ACOSClient]


action :create do
    client = new_resource.client
    a10_name = new_resource.a10_name
    post_url = "/axapi/v3/cgnv6/ds-lite/alg/"
    get_url = "/axapi/v3/cgnv6/ds-lite/alg/rtsp"
    uuid = new_resource.uuid
    rtsp_enable = new_resource.rtsp_enable

    params = { "rtsp": {"uuid": uuid,
        "rtsp-enable": rtsp_enable,} }

    params[:"rtsp"].each do |k, v|
        if not v 
            params[:"rtsp"].delete(k)
        end
    end

    get_url = get_url % {name: a10_name}

    begin
        client.get(get_url)
    rescue RuntimeError => e
        converge_by('Creating rtsp') do
            client.post(post_url, params: params)
        end
    end
end

action :update do
    client = new_resource.client
    a10_name = new_resource.a10_name
    url = "/axapi/v3/cgnv6/ds-lite/alg/rtsp"
    uuid = new_resource.uuid
    rtsp_enable = new_resource.rtsp_enable

    params = { "rtsp": {"uuid": uuid,
        "rtsp-enable": rtsp_enable,} }

    params[:"rtsp"].each do |k, v|
        if not v
            params[:"rtsp"].delete(k)
        end
    end

    get_url = url % {name: a10_name}
    result = client.get(get_url)

    found_diff = false 
    result["rtsp"].each do |k, v|
        if v != params[:"rtsp"][k] 
            found_diff = true
        end
    end

    if found_diff
        converge_by('Updating rtsp') do
            client.put(url, params: params)
        end
    end
end

action :delete do
    client = new_resource.client
    a10_name = new_resource.a10_name
    url = "/axapi/v3/cgnv6/ds-lite/alg/rtsp"

    url = url % {name: a10_name} 

    result = client.get(url)
    if result
        converge_by('Deleting rtsp') do
            client.delete(url)
        end
    end
end