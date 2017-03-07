class HawkularProxyService
  include UiServiceMixin

  def initialize(provider_id, controller)
    @provider_id = provider_id
    @controller = controller

    @params = controller.params
    @ems = ManageIQ::Providers::ContainerManager.find(@provider_id) unless @provider_id.blank?
    @tenant = @params['tenant'] || '_system'

    @cli = ManageIQ::Providers::Kubernetes::ContainerManager::MetricsCapture::HawkularClient.new(@ems, @tenant)
  end

  def client
    if @params['type'] == "counter"
      @cli.hawkular_client.counters
    else
      @cli.hawkular_client.gauges
    end
  end

  def data(query)
    metric_id = @params['metric_id']
    type = @params['type'] || nil
    tags = @params['tags'].blank? ? nil : JSON.parse(@params['tags'])
    tags = nil if tags == {}

    ends = @params['ends'] || (DateTime.now.to_i * 1000)
    starts = @params['starts'] || (ends - 8 * 60 * 60 * 1000)
    bucket_duration = @params['bucket_duration'] || nil

    limit = @params['limit'] || 10_000
    order = @params['order'] || 'ASC'

    case query
    when 'metric_definitions'
      {
        :tags               => tags,
        :limit              => limit.to_i,
        :type               => type,
        :metric_definitions => metric_definitions(tags, limit.to_i, type)
      }
    when 'metric_tags'
      {
        :tags        => tags,
        :limit       => limit.to_i,
        :type        => type,
        :metric_tags => metric_tags(tags, limit.to_i, type)
      }
    when 'get_data'
      params = {
        :limit          => limit.to_i,
        :starts         => starts.to_i,
        :ends           => ends.to_i,
        :bucketDuration => bucket_duration,
        :order          => order
      }

      {
        :id             => metric_id,
        :limit          => limit.to_i,
        :starts         => starts.to_i,
        :ends           => ends.to_i,
        :bucketDuration => bucket_duration,
        :order          => order,
        :data           => get_data(metric_id, params).compact
      }
    when 'get_tenants'
      {
        :limit   => limit.to_i,
        :tenants => tenants(limit.to_i)
      }
    else
      {
        :query => query,
        :error => "Bad query"
      }
    end
  rescue StandardError => e
    {
      :id    => metric_id,
      :tags  => tags,
      :limit => limit.to_i,
      :type  => type,
      :error => e
    }
  end

  def _metric_definitions(tags, type)
    if type.blank?
      @cli.hawkular_client.counters.query(tags).compact +
        @cli.hawkular_client.gauges.query(tags).compact
    else
      client.query(tags).compact
    end
  end

  def metric_definitions(tags, limit, type)
    list = _metric_definitions(tags, type).map { |m| m.json if m.json }

    list.sort { |a, b| a["id"].downcase <=> b["id"].downcase }[0..limit]
  end

  def metric_tags(tags, limit, type)
    tags = metric_definitions(tags, limit, type).map do |x|
      x["tags"].keys if x["tags"]
    end

    tags.compact.flatten.uniq.sort
  end

  def get_data(id, params)
    data = client.get_data(id, params)

    data[0..params[:limit]]
  end

  def tenants(limit)
    tenants = @cli.hawkular_client.http_get('/tenants')

    if @params['include'].blank?
      tenants.map! { |x| x["id"] }
    else
      tenants.map! { |x| x["id"] if x["id"].include?(@params['include']) }
    end

    tenants.compact[0..limit]
  end
end
