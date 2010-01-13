class Host
  attr_reader :host, :ip

  def initialize(host, ip)
    @host = host
    @ip = ip
  end
  
  def ==(other)
    @host == other.host && @ip = other.ip
  end
  
  alias :to_s :host
  alias :name :host
  alias :hostname :host
  
  @@hosts_file = '/etc/hosts'
  @@permanent_hosts = [Host.new("localhost",      "127.0.0.1"),
                       Host.new(`hostname`.chomp, "127.0.0.1")]
  class << self
    protected :new
    
    def list
      entries = []
      File.open(@@hosts_file).each do |line|
        next if line =~ /^#/
        if line =~ /^(\d+\.\d+\.\d+\.\d+) (.*)/
          ip = $1
          hosts = $2.split(' ')
          hosts.each {|host| entries << Host.new(host, ip) }
        end
      end
      entries.delete_if {|host| @@permanent_hosts.include? host }
      entries
    end

    def add(host, ip = "127.0.0.1", force = false)
      if find_by_host(host).nil? || force
        delete(host)
        new_host = Host.new(host, ip)
        
        hosts = list
        hosts << new_host
        write_out!(hosts)
        
        new_host
      else
        raise "Can not overwrite existing record"
      end      
    end
    
    def find_by_host(hostname)
      list.find{|host| host.hostname == hostname }
    end
    
    def find_by_ip(ip)
      list.find_all{|host| host.ip == ip }
    end
    
    def empty!
      write_out!([])
    end
    
    def delete(name)
      hosts = list
      hosts = hosts.delete_if {|host| host.name == name }
      write_out!(hosts)
    end
    
    def delete_matching(pattern)
      pattern = Regexp.escape(pattern)
      hosts = list.select { |h| h.to_s.match(/#{pattern}/) }
      hosts.each do |h|
        delete(h)
      end
      hosts
    end

    protected

    def write_out!(hosts)
      hosts += @@permanent_hosts
      # Har har! inject!
      output = hosts.inject("") {|s, h| s + "#{h.ip} #{h.hostname}\n" }
      File.open(@@hosts_file, 'w') {|f| f.print output }
    end
  end
end
