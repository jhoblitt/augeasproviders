# Alternative Augeas-based provider for cron type (Puppet builtin)

require File.dirname(__FILE__) + '/../../../augeasproviders/provider'

Puppet::Type.type(:cron).provide(:augeas) do
  desc "Uses Augeas API to edit crontab(5) format files"

  include AugeasProviders::Provider

  default_file do
    "/dev/null"
  end

  lens { 'Cron.lns' }

  # cron properties => augeas entries
  TIME_MAPPING =  {
    :minute   => :minute,
    :hour     => :hour,
    :monthday => :dayofmonth,
    :month    => :month,
    :weekday  => :dayofweek,
  }

  resource_path do |resource|
    "$target/*[entry = '#{resource[:name]}']"
  end

  confine :feature => :augeas
  #confine :exists => target
  defaultfor :feature => :augeas

  def self.get_resource(aug, epath, target)
    cron = {
      :ensure => :present,
      :target => target
    }
    return nil unless cron[:name] = aug.get("#{epath}/entry")

    TIME_MAPPING.each_pair do |type, augeas|
      cron[type] = aug.get("#{epath}/entry/time/#{agueas.to_s}")
    end

    cron[:user] = aug.get("#{epath}/entry/user")

    cron
  end

  def self.get_resources(resource=nil)
    augopen(resource) do |aug|
      resources = aug.match('$target/*').map { |p|
        get_resource(aug, p, target(resource))
      }.compact.map { |r| new(r) }
      resources
    end
  end

  def self.instances
    get_resources
  end

  def self.prefetch(resources)
    targets = []
    resources.each do |name, resource|
      targets << target(resource) unless targets.include? target(resource)
    end
    jobs = targets.inject([]) { |cron, target| cron += get_resources({:target => target}) }
    resources.each do |name, resource|
      if provider = jobs.find { |cron| (cron.name == name and cron.target == target(resource)) }
        resources[name].provider = provider
      end
    end
    resources
  end

  def exists? 
    @property_hash[:ensure] == :present && @property_hash[:target] == target
  end

  def create 
    augopen! do |aug|
      aug.set('$target/entry[1]', resource[:name])

      TIME_MAPPING.each_pair do |type, augeas|
        aug.set("$target/entry[1]/time/#{augeas.to_s}", resource[type])
      end

      aug.set("$target/entry[1]/user", resource[:user])
    end

    @property_hash = {
      :ensure  => :present,
      :name    => resource.name,
      :target  => resource[:target],
      :minute  => resource[:minute],
      :hour    => resource[:hour],
      :weekday => resource[:weekday],
      :month   => resource[:month],
      :montday => resource[:monthday],
      :user    => resource[:user],
    }
  end

  def destroy
    augopen! do |aug|
      aug.rm('$resource')
    end
    @property_hash[:ensure] = :absent
  end

  def target
    @property_hash[:target]
  end

  def minute
    @property_hash[:minute]
  end

  def minute=(value)
    augopen! do |aug|
      aug.set('$resource/time/minute', value)
    end
    @property_hash[:minute] = value
  end

  def hour
    @property_hash[:hour]
  end

  def hour=(value)
    augopen! do |aug|
      aug.set('$resource/time/hour', value)
    end
    @property_hash[:hour] = value
  end

  def month
    @property_hash[:month]
  end

  def month=(value)
    augopen! do |aug|
      aug.set('$resource/time/month', value)
    end
    @property_hash[:month] = value
  end

  def monthday
    @property_hash[:monthday]
  end

  def monthday=(value)
    augopen! do |aug|
      aug.set('$resource/time/dayofmonth', value)
    end
    @property_hash[:monthday] = value
  end

  def weekday
    @property_hash[:weekday]
  end

  def weekday=(value)
    augopen! do |aug|
      aug.set('$resource/time/dayofweek', value)
    end
    @property_hash[:weekday] = value
  end

  def user
    @property_hash[:user]
  end

  def user=(value)
    augopen! do |aug|
      aug.set('$resource/user', value)
    end
    @property_hash[:user] = value
  end

end
