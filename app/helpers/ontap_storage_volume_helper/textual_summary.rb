module OntapStorageVolumeHelper::TextualSummary
  #
  # Groups
  #

  def textual_group_properties
    TextualGroup.new(
      _("Properties"),
      %i(
        name element_name caption zone_name description operational_status_str
        health_state_str enabled_state data_redundancy system_name number_of_blocks block_size consumable_blocks
        device_id extent_status delta_reservation no_single_point_of_failure? is_based_on_underlying_redundancy?
        primordial? last_update_status_str
      )
    )
  end

  def textual_group_relationships
    TextualGroup.new(_("Relationships"), %i(storage_system base_storage_extents))
  end

  def textual_group_infrastructure_relationships
    TextualGroup.new(_("Infrastructure Relationships"), %i(vms hosts datastores))
  end

  def textual_group_smart_management
    TextualGroup.new(_("Smart Management"), %i(tags))
  end

  #
  # Items
  #

  def textual_name
    {:label => _("Name"), :value => @record.evm_display_name}
  end

  def textual_element_name
    {:label => _("Element Name"), :value => @record.element_name}
  end

  def textual_caption
    {:label => _("Caption"), :value => @record.caption}
  end

  def textual_zone_name
    {:label => _("Zone Name"), :value => @record.zone_name}
  end

  def textual_description
    {:label => _("Description"), :value => @record.description}
  end

  def textual_operational_status_str
    {:label => _("Operational Status"), :value => @record.operational_status_str}
  end

  def textual_health_state_str
    {:label => _("Health State"), :value => @record.health_state_str}
  end

  def textual_enabled_state
    {:label => _("Enabled State"), :value => @record.enabled_state}
  end

  def textual_data_redundancy
    {:label => _("Data Redundancy"), :value => @record.data_redundancy}
  end

  def textual_system_name
    {:label => _("System Name"), :value => @record.system_name}
  end

  def textual_number_of_blocks
    {:label => _("Number of Blocks"), :value => number_with_delimiter(@record.number_of_blocks, :delimiter => ',')}
  end

  def textual_block_size
    {:label => _("Block Size"), :value => @record.block_size}
  end

  def textual_consumable_blocks
    {:label => _("Consumable Blocks"), :value => number_with_delimiter(@record.consumable_blocks, :delimiter => ',')}
  end

  def textual_device_id
    {:label => _("Device ID"), :value => @record.device_id}
  end

  def textual_extent_status
    # TODO: extent_status is being returned as array, without .to_s it shows 0 0 in two lines with a link.
    {:label => _("Extent Status"), :value => @record.extent_status.to_s}
  end

  def textual_delta_reservation
    {:label => _("Delta Reservation"), :value => @record.delta_reservation}
  end

  def textual_no_single_point_of_failure?
    {:label => _("No Single Point Of Failure"), :value => @record.no_single_point_of_failure?}
  end

  def textual_is_based_on_underlying_redundancy?
    {:label => _("Based On Underlying Redundancy"), :value => @record.is_based_on_underlying_redundancy?}
  end

  def textual_primordial?
    {:label => _("Primordial"), :value => @record.primordial?}
  end

  def textual_last_update_status_str
    {:label => _("Last Update Status"), :value => @record.last_update_status_str}
  end

  def textual_storage_system
    label = ui_lookup(:table => "ontap_storage_system")
    ss    = @record.storage_system
    h     = {:label => label, :icon => "pficon pficon-volume", :value => ss.evm_display_name}
    if role_allows?(:feature => "ontap_storage_system_show")
      h[:title] = _("Show all %{label} '%{name}'") % {:label => label, :name => ss.evm_display_name}
      h[:link]  = url_for(:controller => 'ontap_storage_system', :action => 'show', :id => ss.id)
    end
    h
  end

  def textual_base_storage_extents
    label = ui_lookup(:tables => "cim_base_storage_extent")
    num   = @record.base_storage_extents_size
    h     = {:label => label, :icon => "pficon pficon-volume", :value => num}
    if num > 0 && role_allows?(:feature => "cim_base_storage_extent_show")
      h[:title] = _("Show all %{label}") % {:label => label}
      h[:link]  = url_for(:action => 'cim_base_storage_extents', :id => @record, :db => controller.controller_name)
    end
    h
  end

  def textual_hosts
    label = title_for_hosts
    num   = @record.hosts_size
    h     = {:label => label, :icon => "pficon pficon-screen", :value => num}
    if num > 0 && role_allows?(:feature => "host_show_list")
      h[:title] = _("Show all %{label}") % {:label => label}
      h[:link]  = url_for(:action => 'show', :id => @record, :display => 'hosts')
    end
    h
  end

  def textual_datastores
    textual_link(@record.storages,
                 :as   => Storage,
                 :link => url_for(:action => 'show', :id => @record, :display => 'storages'))
  end

  def textual_vms
    textual_link(@record.vms,
                 :as   => Vm,
                 :link => url_for(:action => 'show', :id => @record, :display => 'vms'))
  end
end
