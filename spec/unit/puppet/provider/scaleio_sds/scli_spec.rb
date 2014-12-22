require 'spec_helper'

provider_class = Puppet::Type.type(:scaleio_sds).provider(:scaleio_sds)
all_properties = [
  :ips,
  :port,
  :pool_devices,
]

describe provider_class do

  # load sample cli outputs
  let(:fixtures_cli)    { File.expand_path(File.join(File.dirname(__FILE__),"../../../../fixtures/cli"))}
  let(:noSDS)           { File.read(File.join(fixtures_cli,"sds_query_all_no_sds.cli")) }
  let(:twoSDS)          { File.read(File.join(fixtures_cli,"sds_query_all_two_sds.cli")) }
  let(:mySDS1)          { File.read(File.join(fixtures_cli,"sds_query_sds_mySDS-1.cli")) }
  let(:mySDS2)          { File.read(File.join(fixtures_cli,"sds_query_sds_mySDS-2.cli")) }

  let(:resource) {
    Puppet::Type.type(:scaleio_sds).new({
      :ensure            => :present,
      :name              => 'mySDS',
      :protection_domain => 'myPDomain',
      :ips               => ['172.17.121.10'],
      :port              => 3454,
      :pool_devices      => {'myPool' => ['/dev/sda', '/dev/sdb']},
      :provider          => described_class.name,
    })
  }

  let(:provider) { resource.provider }

  describe 'basics' do
    before :each do
      # Create a mock resource
      @resource          = stub 'resource'
      @name              = 'myNewSDS'
      @protection_domain = 'myPDomain'
      @ips               = ['172.17.121.11']
      @pool_devices      = {'myPool' => ['/dev/sda', '/dev/sdb']},
      # A catch all; no parameters set
      @resource.stubs(:[]).returns(nil)
      # But set name, ensure
      @resource.stubs(:[]).with(:name).returns @name
      @resource.stubs(:[]).with(:protection_domain).returns @protection_domain
      @resource.stubs(:[]).with(:ips).returns @ips
      @resource.stubs(:[]).with(:pool_devices).returns @pool_devices
      @resource.stubs(:[]).with(:ensure).returns :present
      @resource.stubs(:ref).returns "Scaleio_sds[#{@name}]"
      @provider = provider_class.new(@resource)
    end
    it("should have a create method")   { @provider.should respond_to(:create)  }
    it("should have a destroy method")  { @provider.should respond_to(:destroy) }
    it("should have an exists? method") { @provider.should respond_to(:exists?) }
    all_properties.each do |prop|
      it "should have a #{prop.to_s} method" do
        @provider.should respond_to(prop.to_s)
      end
      it "should have a #{prop.to_s}= method" do
        @provider.should respond_to(prop.to_s + "=")
      end
    end
  end

  describe 'self.instances' do
    it 'returns an array w/ no sds' do
      provider.class.stubs(:scli).with('--query_all_sds').returns(noSDS)
      instances = provider.class.instances
      names     = instances.collect {|x| x.name }
      expect([]).to match_array(names)
    end
    it 'returns an array w/ two sds' do
      provider.class.stubs(:scli).with('--query_all_sds').returns(twoSDS)
      provider.class.stubs(:scli).with('--query_sds', '--sds_name', 'mySDS-1').returns(mySDS1)
      provider.class.stubs(:scli).with('--query_sds', '--sds_name', 'mySDS-2').returns(mySDS2)
      instances = provider.class.instances
      names     = instances.collect {|x| x.name }
      expect(['mySDS-1', 'mySDS-2']).to match_array(names)
    end
    it 'has discoverd the correct property values' do
      provider.class.stubs(:scli).with('--query_all_sds').returns(twoSDS)
      provider.class.stubs(:scli).with('--query_sds', '--sds_name', 'mySDS-1').returns(mySDS1)
      provider.class.stubs(:scli).with('--query_sds', '--sds_name', 'mySDS-2').returns(mySDS2)
      instances = provider.class.instances
      names     = instances.collect {|x| x.name }
      expect(instances[0].ips).to match(['192.168.56.111'])
      expect(instances[0].port).to match(/^7072$/)
      expect(instances[0].pool_devices).to match({'myPool' => ['/tmp/ac', '/tmp/aa']})
    end
  end

  describe 'create' do
    it 'creates a sds' do
      provider.expects(:scli).with('--add_sds', '--sds_name', 'mySDS', '--protection_domain_name', 'myPDomain', '--device_path', '/dev/sda', '--sds_ip', '172.17.121.10', '--storage_pool_name', 'myPool', '--sds_port', '3454').returns([])
      provider.expects(:scli).with('--add_sds_device', '--sds_name', 'mySDS', '--device_path', '/dev/sdb', '--storage_pool_name', 'myPool').returns([])
      provider.create
    end
  end

  describe 'destroy' do
    it 'removes a sds' do
      provider.expects(:scli).with('--remove_sds', '--sds_name', 'mySDS').returns([])
      provider.destroy
    end
  end

  describe 'update port' do
    it 'updates the port' do
      provider.expects(:scli).with('--modify_sds_port', '--sds_name', 'mySDS', '--new_sds_port', 453).returns([])
      provider.port = 453
    end
  end

  describe 'update pool_devices' do
    it 'removes obsolte pool devices' do
      provider.instance_variable_get(:@property_hash)[:pool_devices] = {'myPool' => ['/dev/sda', '/dev/sdb', '/dev/sdc']}
      provider.expects(:scli).with('--remove_sds_device', '--sds_name', 'mySDS', '--device_path', '/dev/sdc').returns([])
      provider.pool_devices = {'myPool' => ['/dev/sda', '/dev/sdb']}
    end

    it 'adds new pool devices' do
      provider.instance_variable_get(:@property_hash)[:pool_devices] = {'myPool' => ['/dev/sda', '/dev/sdb']}
      provider.expects(:scli).with('--add_sds_device', '--sds_name', 'mySDS', '--storage_pool_name', 'myPool', '--device_path', '/dev/sdd').returns([])
      provider.pool_devices = {'myPool' => ['/dev/sda', '/dev/sdb', '/dev/sdd']}
    end

    it 'does nothing' do
      provider.instance_variable_get(:@property_hash)[:pool_devices] = {'myPool' => ['/dev/sda', '/dev/sdb']}
      provider.pool_devices = {'myPool' => ['/dev/sda', '/dev/sdb']}
    end

    it 'requires at least one device' do
      expect {
        provider.pool_devices = {'myPool' => []}
      }.to raise_error Puppet::Error, /Cannot remove all SDS devices from SDS/
    end
  end

  describe 'update IPs' do
    it 'removes obsolte IPs' do
      provider.instance_variable_get(:@property_hash)[:ips] = ['172.17.121.10', '172.17.121.11']
      provider.expects(:scli).with('--remove_sds_ip', '--sds_name', 'mySDS', '--sds_ip_to_remove', '172.17.121.11').returns([])
      provider.ips = ['172.17.121.10']
    end

    it 'adds new IPs' do
      provider.instance_variable_get(:@property_hash)[:ips] = ['172.17.121.10']
      provider.expects(:scli).with('--add_sds_ip', '--sds_name', 'mySDS', '--new_sds_ip', '172.17.121.11').returns([])
      provider.ips = ['172.17.121.10', '172.17.121.11']
    end

    it 'does nothing' do
      provider.instance_variable_get(:@property_hash)[:ips] = ['172.17.121.10']
      provider.ips = ['172.17.121.10']
    end

    it 'requires at least one IP' do
      expect {
        provider.ips = []
      }.to raise_error Puppet::Error, /SDS must have at least one IP address/
    end
  end
end